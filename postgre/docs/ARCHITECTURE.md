# Arquitetura do Banco

Visão de como o repositório é organizado e por que, mais as decisões de design que não cabem no README.

## Dicionário vs. Esteira de Migrations

| Camada | Pastas | Papel |
|--------|--------|-------|
| **Dicionário** | `ddl/`, `functions/`, `procedures/`, `triggers/`, `views/` | Fonte para leitura e consulta de desenvolvedores. Código estrito (`CREATE TABLE`, `CREATE VIEW`), um arquivo por assunto. |
| **Rollback** | subpasta `rollback/` de cada pasta acima | Scripts isolados de destruição (`DROP ... CASCADE`), separados de propósito para não serem executados por engano. |
| **Esteira** | `migrations/` | O que realmente roda no banco. Consolida o dicionário com guardas de idempotência (`IF NOT EXISTS`, `OR REPLACE`). |

```mermaid
flowchart LR
    D["Dicionário<br/>ddl · functions · procedures · triggers · views"] -->|consolidado em| M["migrations<br/>V001 … V010"]
    M -->|psql / CI| DB[("PostgreSQL")]
    M -->|cópia byte a byte| API["ms-inventra-api<br/>Flyway"]
    R["rollback/<br/>drop_*.sql"] -.->|reverte| DB
```

## Migrations

| Versão | Conteúdo |
|--------|----------|
| `V001__init_database.sql` | Tabelas, FKs, índices e checks |
| `V002__business_rules.sql` | Functions, procedures e triggers de negócio |
| `V003__audit_logs.sql` | Tabelas, índices, functions e triggers de log |
| `V004__views.sql` | Views operacionais (`vw_*`) e Data Mart (`dim_*` / `fact_*`) |
| `V005__etl_analytics.sql` | Views analíticas com CTEs e Window Functions |
| `V006__google_login_and_kitchen_location.sql` | Login Google (`firebase_uid`, senha opcional) e localização da cozinha |
| `V007__stock_movements.sql` | Histórico de movimentações (`tb_stock_movement`) gravado pelas procedures de entrada e baixa |
| `V008__alert_recipients_and_reads.sql` | Destinatário do alerta, leitura por pessoa (`tb_alert_read`) e aviso antes de vencer |
| `V009__requisition_draft.sql` | Status `DRAFT` e estorno do estoque ao cancelar requisição aprovada |
| `V010__data_catalog.sql` | Catálogo de dados: tabelas `tb_catalog_*`, carga dos metadados, `sp_sync_data_catalog` e views `vw_data_catalog*` |
| `rollback/drop_everything.sql` | Reversão completa |

As pastas de dicionário não têm numeração porque não representam sequência; a ordem de execução é definida só por `migrations/`.

## Convenções

- **Fonte da verdade:** este repositório é o dono do schema. Toda mudança nasce aqui, na pasta de dicionário correspondente **e** em `migrations`.
- **Integração com a API:** `ms-inventra-api` apenas copia `V001` a `V010` byte a byte para `src/main/resources/db/migration` e o Flyway aplica. Nunca se edita migration direto na API.
- **Imutabilidade:** migrations são idempotentes e numeradas em sequência (`V006`, `V007`…). Uma migration já aplicada em algum banco não deve ser alterada; mudanças novas entram em uma nova versão.
- **Mensagens em português:** os `RAISE EXCEPTION` das functions e procedures estão em português de propósito, porque a API os repassa ao cliente no `detail` das respostas 409.
- **Job diário:** `sp_expire_batches()` marca lotes vencidos como `EXPIRED` e gera os alertas correspondentes. É chamada diariamente pelo `BatchExpirationJob` da API. `sp_alert_expiring_batches(p_days)` avisa **antes** de vencer e deve ser chamada pelo mesmo job.
- **Views não mudam de colunas:** o CI reaplica todas as migrations em sequência, e `CREATE OR REPLACE VIEW` não aceita remover coluna. Uma migration nova que recria uma view antiga precisa manter exatamente as mesmas colunas (só o corpo muda); coluna nova pede uma view nova.
- **Catálogo de dados:** migration que cria tabela ou coluna também grava os metadados dela no catálogo (`INSERT ... ON CONFLICT DO UPDATE`, como na `V010`). O que faltar é incluído sem descrição por `sp_sync_data_catalog()` e aparece com `is_documented = false` em `vw_data_catalog`. Veja [`DATA_CATALOG.md`](DATA_CATALOG.md).
- **Procedure com parâmetro novo:** o parâmetro entra com `DEFAULT` e a assinatura antiga é removida com `DROP PROCEDURE IF EXISTS` na mesma migration, para a chamada antiga continuar valendo sem ficar ambígua.

## Validação automática (CI)

`tests/check_migrations.sh` roda no GitHub Actions (`.github/workflows/migrations.yml`, PostgreSQL 16) e cobre quatro passos:

1. aplica `V001`…`V010` em banco limpo;
2. reaplica tudo (prova de idempotência);
3. executa `rollback/drop_everything.sql`;
4. reaplica do zero após o rollback.

## Herança de tabela nas tabelas de log

As 7 tabelas de log (`tb_log_user`, `tb_log_product`, `tb_log_supplier`, `tb_log_stock_batch`, `tb_log_requisition`, `tb_log_inventory`, `tb_log_alert`) usam **herança de tabela** (`INHERITS`) a partir de `tb_log_base`, que concentra as colunas comuns de auditoria (`id_log`, `operation`, `db_user`, `operation_date`, `previous_data`, `new_data`). Cada filha soma só a coluna que identifica a entidade auditada (ex: `id_product` em `tb_log_product`).

```mermaid
flowchart TB
    B["tb_log_base<br/>id_log · operation · db_user · operation_date · previous_data · new_data"]
    B --> U[tb_log_user]
    B --> P[tb_log_product]
    B --> S[tb_log_supplier]
    B --> SB[tb_log_stock_batch]
    B --> RQ[tb_log_requisition]
    B --> I[tb_log_inventory]
    B --> A[tb_log_alert]
```

**Por que herança e não CTE recursiva:** as duas técnicas resolvem problemas diferentes. CTE recursiva serve para navegar uma relação hierárquica *dentro da mesma tabela*, onde uma linha referencia outra linha da própria tabela (ex: categoria com subcategoria, organograma). As tabelas de log não são hierárquicas: são 7 entidades **irmãs**, sem relação de pai/filho entre si, que só compartilham o mesmo formato de colunas de auditoria. Isso é exatamente o que herança resolve: reaproveitar uma estrutura comum sem duplicar colunas, mantendo a consulta consolidada via `SELECT * FROM tb_log_base`, que já retorna as linhas de todas as filhas.

**Verificação:** `INSERT`/`UPDATE`/`DELETE` numa tabela principal (ex: `tb_product`) dispara a trigger de auditoria, que grava na filha correspondente (`tb_log_product`). A linha aparece tanto na consulta pela filha quanto pela base (`tb_log_base`), sem `UNION` manual.
