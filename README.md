# 📦 Inventra Database

> **Repo utilizado para produção do banco de dados que sera utilizado no projeto interdisciplinar "Inventra".**

---

## 📋 Sobre o Projeto

Este repositório contém a **estrutura completa do banco de dados** do sistema **Inventra** — um sistema de gestão de estoque e cozinhas industriais. O projeto adota uma arquitetura de **Dicionário Estrito vs. Esteira de Migrations**, garantindo scripts idempotentes (seguros para múltiplas execuções), versionamento inteligente, auditoria embutida e excelente documentação técnica.

---

## 🗂️ Estrutura do Projeto

O projeto é dividido em **Dicionário de Dados** (Pastas 01 a 08) contendo os códigos estritos e isolados, e a **Esteira de Execução** (`09_migrations`), contendo os scripts consolidados e à prova de falhas.

```text
postgre/
├── 01_modeling/                      # Modelagem de dados (Conceitual e Lógico)
├── 02_ddl/                          # Dicionário de Criação (Tabelas, Constraints, Indexes e Logs)
├── 03_views/                        # Dicionário de Views de consulta/relatório (vw_*) + Data Mart (dim_*/fact_*)
├── 05_triggers/                     # Dicionário de Gatilhos de Negócio e Auditoria
├── 06_procedures/                   # Dicionário de Rotinas de Negócio
├── 07_functions/                    # Dicionário de Funções do Sistema
│   └── (Todas as pastas acima possuem uma subpasta `/rollback` com scripts de reversão)
│
├── 09_migrations/                   # Scripts consolidados e idempotentes para execução direta
│   ├── V001__init_database.sql      # Criação estrutural (Tabelas, FKs, Indexes, Checks)
│   ├── V002__business_rules.sql     # Inteligência (Functions, Procedures e Triggers de negócio)
│   ├── V003__audit_logs.sql         # Rastreabilidade (Tabelas, Funções e Gatilhos de log)
│   ├── V004__views.sql              # Views de consulta/relatório (vw_*)
│   └── V005__data_mart.sql          # Data Mart / Star Schema (dim_*/fact_*)
│
└── inventra_erp_flow.html           # Diagrama de fluxo ERP
```


## 🏗️ Tecnologias Utilizadas

| Tecnologia | Descrição |
|------------|-----------|
| **PostgreSQL** | SGBD principal do projeto |
| **Scripts Idempotentes** | Abordagem manual e segura (`IF NOT EXISTS` / `OR REPLACE`) dispensando ferramentas externas obrigatórias |
| **draw.io** | Modelagem conceitual/lógica |
| **Git** | Controle de versão |

---

## 🚀 Como Executar


A arquitetura do `09_migrations` foi desenhada para ser executada diretamente, sem gerar erros caso os objetos já existam no banco de dados.

### 1. Clone o repositório

```bash
git clone [https://github.com/InventraTech/inventra-database.git](https://github.com/InventraTech/inventra-database.git)
cd inventra-database/postgre
```

### 2. Execute as migrations na ordem (Criação/Atualização)

Você pode executar os arquivos diretamente na sua ferramenta SQL favorita (DBeaver, pgAdmin) ou via linha de comando:

```bash
psql -U usuario -d inventra_db -f 09_migrations/V001__init_database.sql
psql -U usuario -d inventra_db -f 09_migrations/V002__business_rules.sql
psql -U usuario -d inventra_db -f 09_migrations/V003__audit_logs.sql
psql -U usuario -d inventra_db -f 09_migrations/V004__views.sql
psql -U usuario -d inventra_db -f 09_migrations/V005__data_mart.sql
```

### 3. Rollback (Limpeza / Reversão)

Os scripts de destruição estão isolados por segurança nas pastas de dicionário. Para reverter algo, execute o arquivo da respectiva pasta. Exemplo:

```bash
# Apagar tabelas em cascata:
psql -U usuario -d inventra_db -f 02_ddl/tables/rollback/drop_tables.sql
```

---

## 📊 Modelagem do Banco

O banco de dados possui **18 tabelas principais** e um ecossistema de **7 tabelas de log** (Auditoria Automática), organizadas em:

- **Cadastros Base:** `tb_user`, `tb_profile`, `tb_kitchen`, `tb_product`, `tb_supplier`
- **Movimentações:** `tb_stock_batch`, `tb_requisition`, `tb_inventory`
- **Relacionamentos:** `tb_product_supplier`, `tb_product_kitchen_parameter`
- **Eventos & Logs:** `tb_alert`, `tb_inventory_count`, e esquema de rastreabilidade (ex: `tb_log_user`)

---

## ⚙️ Functions e Procedures

Functions de negócio (`07_functions/create_functions.sql`) — regra automática, disparada por trigger, não chamada diretamente:

| Function | Trigger que chama | O que faz |
|----------|--------------------|-----------|
| `fn_validate_stock` | `trg_validate_stock` | Impede `current_quantity` negativo em `tb_stock_batch` |
| `fn_update_batch_status` | `trg_update_batch_status` | Marca o lote como `WRITTEN_OFF` quando a quantidade chega a zero |
| `fn_calculate_divergence` | `trg_calculate_divergence` | Calcula `divergence` (física − registrada) em `tb_inventory_count` |
| `fn_requisition_approval` | `trg_requisition_approval` | Preenche `approved_at` quando o status muda pra `APPROVED` |
| `fn_stock_alert` | `trg_stock_alert` | Cria alerta quando o estoque fica ≤ mínimo cadastrado |
| `fn_expiration_alert` | `trg_expiration_alert` | Cria alerta quando um lote já passou da validade |

Functions de log (`07_functions/create_log_functions.sql`) — uma por tabela auditada, grava o antes/depois em JSON na tabela `tb_log_*` correspondente: `fn_log_user`, `fn_log_product`, `fn_log_supplier`, `fn_log_stock_batch`, `fn_log_requisition`, `fn_log_inventory`, `fn_log_alert`.

Procedures (`06_procedures/create_procedures.sql`) — rotinas de negócio chamadas explicitamente via `CALL`, não automáticas:

| Procedure | O que faz |
|-----------|-----------|
| `sp_approve_requisition` | Aprova uma requisição que está em análise |
| `sp_reject_requisition` | Rejeita uma requisição em análise, com motivo |
| `sp_cancel_requisition` | Cancela requisição em análise ou já aprovada |
| `sp_register_stock_entry` | Registra entrada de quantidade num lote |
| `sp_write_off_stock` | Dá baixa de quantidade num lote (valida se há saldo suficiente) |
| `sp_close_inventory` | Fecha um inventário que está aberto |

---

## 🔔 Triggers

Triggers de negócio (`05_triggers/create_trg.sql`):

| Trigger | Tabela | Quando dispara | Function |
|---------|--------|-----------------|----------|
| `trg_validate_stock` | `tb_stock_batch` | BEFORE INSERT/UPDATE de `current_quantity` | `fn_validate_stock` |
| `trg_update_batch_status` | `tb_stock_batch` | BEFORE INSERT/UPDATE de `current_quantity`, `status` | `fn_update_batch_status` |
| `trg_calculate_divergence` | `tb_inventory_count` | BEFORE INSERT/UPDATE de `registered_quantity`, `physical_quantity` | `fn_calculate_divergence` |
| `trg_requisition_approval` | `tb_requisition` | BEFORE UPDATE de `status` | `fn_requisition_approval` |
| `trg_stock_alert` | `tb_stock_batch` | AFTER INSERT/UPDATE de `current_quantity` | `fn_stock_alert` |
| `trg_expiration_alert` | `tb_stock_batch` | AFTER INSERT/UPDATE de `expiration_date` | `fn_expiration_alert` |

Triggers de auditoria (`05_triggers/create_log_trg.sql`) — `trg_log_user`, `trg_log_product`, `trg_log_supplier`, `trg_log_stock_batch`, `trg_log_requisition`, `trg_log_inventory`, `trg_log_alert`: todas disparam **AFTER INSERT OR UPDATE OR DELETE** na respectiva tabela, gravando o registro inteiro (antes e depois) na tabela `tb_log_*` correspondente, usando `NEW`/`OLD`/`TG_OP`/`CURRENT_USER`.

---

## 📈 Views e Data Mart

**Views operacionais** (`03_views/create_views.sql`, prefixo `vw_*`) — dão suporte às telas do app e a consultas prontas pra IAI, sem cruzar tabela por tabela:

| View | Pra que serve |
|------|----------------|
| `vw_stock_batch_detail` | Lote a lote, com dias até vencer e status (EXPIRED/CRITICAL/WARNING/OK) |
| `vw_product_stock_position` | Quantidade total por produto/cozinha vs. mínimo/máximo |
| `vw_daily_expiration_summary` | Vencimentos agrupados por dia (Dashboard) |
| `vw_active_alerts` | Alertas não lidos, ordenados por severidade |
| `vw_stock_value_by_category` | Estoque somado por categoria (Dashboard) |
| `vw_requisition_summary` / `vw_requisition_pending` | Requisições com totais, e as pendentes |
| `vw_stock_movement_log` | Entradas/saídas reconstruídas do log de auditoria |
| `vw_inventory_count_divergence` | Diferença entre contagem registrada e física |
| `vw_kitchen_daily_stock_movement` | Movimentação diária com total acumulado (gráfico de linha) |
| `vw_product_requisition_ranking` | Produtos mais requisitados, por cozinha |
| `vw_product_supplier_catalog` | Fornecedores por produto, ordenados por preço |
| `vw_kitchen_dashboard_kpi` | KPIs resumidos por cozinha, numa linha só |
| `vw_products_below_minimum` / `vw_batches_needing_attention` | Filtros prontos de "abaixo do mínimo" e "precisa de atenção" |
| `vw_supplier_profile` | Resumo por fornecedor (nº de produtos, preço médio, prazo médio) |
| `vw_monthly_waste_proxy_kpi` | Estimativa de desperdício — **proxy/hipótese**, não é fórmula aprovada: o banco ainda não registra o motivo de uma baixa de estoque (consumo normal vs. descarte) |

**Data Mart / Star Schema** (`03_views/datamart/create_datamart_views.sql`, prefixo `dim_*`/`fact_*`) — atende o requisito de Modelagem Dimensional pra BI. É um **star schema virtual**: as dimensões e fatos são views sobre as tabelas normalizadas, não tabelas físicas duplicadas.

| Tipo | View | Grão |
|------|------|------|
| Dimensão | `dim_product` | uma linha por produto |
| Dimensão | `dim_kitchen` | uma linha por cozinha |
| Dimensão | `dim_supplier` | uma linha por fornecedor |
| Dimensão | `dim_date` | uma linha por dia (2023–2030) |
| Fato | `fact_stock_movement` | uma linha por movimentação de estoque |
| Fato | `fact_requisition_item` | uma linha por item de requisição |
| Fato | `fact_inventory_count` | uma linha por contagem de inventário |

Uma ferramenta de BI (Power BI, Metabase, etc.) conectada nessas 7 views consegue montar o relacionamento fato↔dimensão sozinha, pelas colunas de chave (`id_product`, `id_kitchen`, `date_key`).

---


## 🔧 Compreendendo a Arquitetura

| Diretório | Propósito |
|-----------|-----------|
| **Dicionário (02 a 08)** | Fonte da verdade para consulta de desenvolvedores. Código estrito (`CREATE TABLE`, `CREATE VIEW`). |
| **Subpastas `rollback`** | Scripts isolados com comandos de destruição (ex: `DROP TABLE ... CASCADE`). |
| **`09_migrations/`** | O que realmente roda no banco. Agrupa as instruções do dicionário utilizando validações (`IF NOT EXISTS`) para atualizações seguras. |

---

## 🗺️ Próximos Passos

- [x] Adicionar scripts de `functions`, `procedures` e `triggers`
- [x] Configurar sistema base de logs e auditoria
- [ ] Criar testes de integridade e performance
- [ ] Documentar dicionário de dados (Data Dictionary .md)
- [x] Dividir a criação de logs, índices, functions, procedures e triggers em migrations próprias (`V002` a `V00N`)
- [x] Adicionar script de seed/dataload inicial — `postgre/08_seeds/seed.ipynb`
- [x] Adicionar scripts de `views`
- [ ] Criar testes de integridade e performance
- [ ] Documentar dicionário de dados
- [ ] Configurar ambiente de desenvolvimento/homologação
- [ ] Integrar com aplicação principal

---

## 👥 Contribuidores

| Nome | Papel |
|------|-------|
| **@dvarakaki** | Desenvolvedor de Banco de Dados |
| **@joohnyxxz** | Desenvolvedor de Banco de Dados |

---

## 📄 Licença

Este projeto está sob a licença **MIT**. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 📞 Contato

- **GitHub:** [InventraTech](https://github.com/InventraTech)
- **Projeto:** Sistema Inventra - Gestão de Estoque e Cozinhas

---

**Status:** 🟢 Em desenvolvimento ativo
