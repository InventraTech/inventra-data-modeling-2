# Backup e Recuperação

Procedimentos de backup e de recuperação de falhas do banco do Inventra. Cada tipo de falha tem uma camada própria, porque nenhuma ferramenta sozinha cobre todas. Objetos de banco criados em `migrations/V011__backup_and_recovery.sql`; scripts em `backup/`.

## Política

| Camada | Cobre | Frequência | Retenção | RPO (perda máxima) | Como restaurar |
|--------|-------|------------|----------|--------------------|----------------|
| **1. Backup gerenciado do Aiven** | Perda do servidor, corrupção física, desastre na nuvem | Automática (Aiven) | Conforme o plano contratado | Conforme o plano: minutos com PITR, até 1 dia sem | Console do Aiven |
| **2. Backup lógico (`pg_dump`)** | Migration errada, dados corrompidos em massa, tabela apagada, troca de provedor | Diária e antes de toda migration | 7 últimos arquivos | 1 dia | `backup/restore.sh` |
| **3. Trilha de auditoria** | `UPDATE`/`DELETE`/`INSERT` errado em uma linha | Contínua (triggers) | Indefinida | Zero, nas 7 tabelas auditadas | `CALL sp_restore_from_audit(id_log)` |

**RTO (tempo para voltar):** minutos nas camadas 2 e 3, porque o banco é pequeno e o restore é um comando. Na camada 1, depende do tempo de provisionamento do Aiven.

**Regra:** backup que nunca foi restaurado não conta. O CI restaura um dump a cada push, e o procedimento mensal (abaixo) restaura um dump real.

## Camada 1: backup gerenciado do Aiven

O Aiven faz backup automático do serviço PostgreSQL, sem ação nossa. O que fazer:

1. No console do Aiven, abrir o serviço e a aba **Backups**. Conferir a retenção e se o plano tem recuperação para um ponto no tempo (PITR). Registrar esses valores na tabela de política acima.
2. Para restaurar, criar um novo serviço a partir do backup (*fork*), escolhendo o horário quando houver PITR. O serviço original continua intacto até a troca.
3. Apontar o `.env` e a API para o novo serviço, validar e só então desligar o antigo.

Essa camada não protege contra erro lógico percebido tarde: se um dado foi apagado há mais tempo do que a retenção, só a camada 2 tem a cópia.

## Camada 2: backup lógico

### Requisitos

- `bash` (no Windows, o Git Bash);
- `pg_dump`, `pg_restore` e `psql` instalados **ou** o Docker rodando. Sem os clientes, os scripts usam a imagem `postgres:<versão do servidor>` (versão detectada na hora, porque um `pg_dump` mais novo gera comandos que um servidor mais antigo recusa);
- conexão: o `.env` da raiz (`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_SSLMODE`) ou, se `PGHOST` estiver definido, só as variáveis `PG*`. As duas fontes nunca se misturam, para o host de um banco não ser usado com a senha de outro.

### Fazer backup

```bash
bash postgre/backup/backup.sh
```

1. `pg_dump -Fc` (formato custom: comprimido e permite restaurar uma tabela só) em `postgre/backup/dumps/<banco>_<AAAAMMDD_HHMMSS>.dump`;
2. confere se o arquivo é legível (`pg_restore --list`);
3. grava o SHA-256 em `<arquivo>.dump.sha256`;
4. apaga os mais antigos, mantendo os 7 últimos (`BACKUP_KEEP` muda isso);
5. registra a execução em `tb_backup_history`, com sucesso ou com o erro.

### Restaurar

```bash
bash postgre/backup/restore.sh postgre/backup/dumps/inventra_db_20261014_120000.dump
```

1. confere o SHA-256: arquivo corrompido não é restaurado;
2. cria um banco **novo**, `<DB_NAME>_restore`, e o banco de origem não é tocado;
3. `pg_restore` em transação única: se falhar no meio, nada fica aplicado;
4. mostra a contagem de linhas por tabela (`fn_table_row_counts()`) e registra em `tb_backup_history`.

| Situação | Comportamento |
|----------|---------------|
| Destino já existe | Erro. `RESTORE_REPLACE=yes` apaga e recria |
| Destino é o banco de origem | Erro. `CONFIRM_OVERWRITE=yes` substitui os objetos no lugar |
| Outro nome de destino | `restore.sh <arquivo> <banco>` |

## Camada 3: recuperação pela auditoria

As triggers de auditoria guardam em `tb_log_*` a linha antes (`previous_data`) e depois (`new_data`) de cada operação. `sp_restore_from_audit(id_log)` usa isso para desfazer uma operação:

| Operação no log | O que a procedure faz |
|-----------------|-----------------------|
| `DELETE` | Reinsere a linha com os dados de antes, com o mesmo id |
| `UPDATE` | Volta a linha para os valores de antes |
| `INSERT` | Apaga a linha inserida |

A recuperação também passa pelas triggers, então fica auditada. Ela recusa casos sem sentido: reinserir uma linha que já existe, voltar um `UPDATE` de uma linha que foi apagada, ou id de log inexistente.

**Limites:** vale só para as 7 tabelas auditadas (`tb_user`, `tb_product`, `tb_supplier`, `tb_stock_batch`, `tb_requisition`, `tb_inventory`, `tb_alert`). Restaura uma linha por chamada e não traz junto as linhas filhas de tabelas não auditadas (ex.: `tb_requisition_item`). Para esses casos, use a camada 2.

## Runbook: o que fazer em cada falha

### 1. Uma linha foi alterada ou apagada por engano

```sql
-- achar a operação (troque a tabela e o id)
SELECT id_log, operation, db_user, operation_date, previous_data
FROM tb_log_product
WHERE id_product = 42
ORDER BY id_log DESC;

-- desfazer
CALL sp_restore_from_audit(1234);
```

Para desfazer várias operações na mesma linha, desfaça da mais recente para a mais antiga. Se apagou um pai e os filhos auditados (ex.: requisição), restaure o pai primeiro.

### 2. Muitas linhas de uma tabela foram apagadas ou corrompidas

1. Restaure o último dump bom num banco à parte:
   ```bash
   bash postgre/backup/restore.sh postgre/backup/dumps/<arquivo>.dump
   ```
2. Confira os dados em `<DB_NAME>_restore`.
3. Exporte a tabela do banco restaurado (exemplo com `tb_supplier`):
   ```bash
   psql -d inventra_db_restore -c "\copy tb_supplier TO 'tb_supplier.csv' CSV HEADER"
   ```
4. No banco principal, carregue numa tabela temporária e devolva as linhas, numa transação só:
   ```sql
   BEGIN;
   CREATE TEMP TABLE stg_supplier (LIKE tb_supplier) ON COMMIT DROP;
   \copy stg_supplier FROM 'tb_supplier.csv' CSV HEADER

   -- linhas apagadas: voltam com o mesmo id
   INSERT INTO tb_supplier
   SELECT * FROM stg_supplier
   ON CONFLICT (id_supplier) DO NOTHING;

   -- linhas corrompidas: em vez de DO NOTHING, use
   -- ON CONFLICT (id_supplier) DO UPDATE SET legal_name = EXCLUDED.legal_name, email = EXCLUDED.email, ...
   COMMIT;
   ```
5. Apague o `.csv` (tem os dados da tabela) e o banco `_restore`.

Não use `TRUNCATE ... CASCADE` para "limpar e recarregar": ele apaga também as tabelas que referenciam a corrompida (ex.: os lotes de cada fornecedor). As linhas devolvidas passam pelas triggers e ficam auditadas.

Se a tabela foi **removida** (`DROP TABLE`), o caminho é o cenário 3: restaurar o banco inteiro.

### 3. Uma migration estragou dados ou uma tabela foi removida

- Se a migration **falhou**, nada foi aplicado: as migrations rodam com `--single-transaction`.
- Se ela **rodou** e o resultado está errado: por isso o backup é obrigatório antes de toda migration em ambiente compartilhado. Restaure o dump de antes:
  ```bash
  CONFIRM_OVERWRITE=yes bash postgre/backup/restore.sh postgre/backup/dumps/<arquivo_antes_da_migration>.dump inventra_db
  ```
  Depois, corrija a migration numa **nova** versão (migration aplicada não se edita).

### 4. O serviço do banco foi perdido

1. Tente a camada 1: restaurar ou criar *fork* pelo console do Aiven.
2. Se não der: crie um PostgreSQL novo, aponte o `.env` para ele e rode o `restore.sh` com o último dump. O dump traz schema, dados, functions, triggers e views. Não é preciso reaplicar as migrations.
3. Aponte a API para o novo banco e confira `vw_data_catalog_table` e `fn_table_row_counts()`.

### 5. O dump mais recente está corrompido

O `restore.sh` recusa o arquivo quando o SHA-256 não confere. Use o anterior: há 7 versões.

## Rotina

| Quando | O quê |
|--------|-------|
| Todo dia | `backup.sh`. Para agendar: Agendador de Tarefas do Windows chamando o Git Bash, ou `cron` (`0 3 * * * bash /caminho/postgre/backup/backup.sh`) |
| Antes de toda migration em ambiente compartilhado | `backup.sh` |
| Todo mês | Teste de restauração: `restore.sh` do último dump em `<DB_NAME>_restore`, conferir as contagens e apagar o banco de teste. Fica registrado em `tb_backup_history` |
| Todo push | CI: `tests/check_backup_restore.sh` (abaixo) |

## Monitoramento

```sql
SELECT backup_status, last_backup_at, hours_since_last_backup,
       last_restore_at, failures_last_7_days
FROM vw_backup_status;

SELECT operation, status, database_name, file_name, finished_at, error_message
FROM tb_backup_history
ORDER BY finished_at DESC
LIMIT 20;
```

| `backup_status` | Significado |
|-----------------|-------------|
| `OK` | Último backup com sucesso há menos de 26 h |
| `OVERDUE` | Mais de 26 h sem backup com sucesso (rotina diária + 2 h de folga) |
| `NEVER` | Nenhum backup registrado |

Depois de um restore que substitui o banco de origem, `tb_backup_history` volta ao estado do dump: as execuções registradas depois dele saem, e o restore em si é registrado em seguida.

## Teste automático (CI)

`tests/check_backup_restore.sh` roda no GitHub Actions depois de `check_migrations.sh`:

1. `tests/check_audit_restore.sql`: desfaz `UPDATE`, `DELETE` e `INSERT` pela auditoria e confere os casos de erro;
2. `backup.sh`;
3. `restore.sh` num banco novo;
4. compara a contagem de linhas de todas as tabelas entre a origem e o restaurado;
5. confere `vw_backup_status` (`OK` e restore registrado).

## Segurança dos dumps

- O dump tem dados pessoais (nome e e-mail em `tb_user`) e hashes de senha. Trate o arquivo com o nível `CONFIDENTIAL` do [catálogo de dados](DATA_CATALOG.md).
- `postgre/backup/dumps/`, `*.dump` e `*.dump.sha256` estão no `.gitignore`. Nunca versione um dump.
- Guarde cópias fora da máquina num local com acesso restrito e criptografia (ex.: drive corporativo), não em repositório nem em artifact público.
- Os scripts lêem do `.env` só as 6 chaves de conexão, sem `source`, e não imprimem a senha.

## Objetos no banco

| Objeto | Tipo | Papel |
|--------|------|-------|
| `tb_backup_history` | Tabela | Histórico de backups e restores (sucesso ou falha, tamanho, SHA-256, quem rodou) |
| `sp_register_backup` | Procedure | Grava uma execução; chamada pelos scripts |
| `sp_restore_from_audit` | Procedure | Desfaz uma operação auditada |
| `fn_table_row_counts` | Function | Contagem exata por tabela, para comparar origem e restaurado |
| `vw_backup_status` | View | Situação do backup em uma linha |

| Arquivo | Conteúdo |
|---------|----------|
| `backup/backup.sh`, `backup/restore.sh`, `backup/lib.sh` | Scripts de backup e restore |
| `ddl/backup/create_backup_tables.sql` | Tabela, checks e índice |
| `functions/create_recovery_functions.sql` | `fn_table_row_counts` |
| `procedures/create_recovery_procedures.sql` | `sp_register_backup`, `sp_restore_from_audit` |
| `views/backup/create_backup_views.sql` | `vw_backup_status` |
| `tests/check_backup_restore.sh`, `tests/check_audit_restore.sql` | Teste automático |
