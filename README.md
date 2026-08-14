# 📦 Inventra Database

> **Repo utilizado para produção dos bancos de dados que serão utilizados no projeto interdisciplinar "Inventra".**

---

## 📋 Sobre o Projeto

Este repositório contém a **estrutura completa do banco de dados** do sistema **Inventra** — um sistema de gestão de estoque e cozinhas industriais. O projeto segue **boas práticas de engenharia de dados**, com versionamento de migrations, scripts de rollback e documentação técnica.

---

## 🗂️ Estrutura do Projeto

```
postgre/
├── 01_modelagem/                    # Modelagem de dados
│   └── logico/
│       └── V1/                      # Versão 1 do modelo lógico (diagrama)
│
├── 02_ddl/                          # Data Definition Language
│   ├── tables/                      # Criação das tabelas de negócio
│   ├── logs/                        # Tabelas de auditoria/log
│   │   └── rollback_logs/
│   ├── indexes/                     # Índices de performance
│   │   └── rollback_indexes/
│   ├── constraints/                 # Constraints (FK, CHECK)
│   └── rollback/                    # Scripts de reversão das constraints
│
├── 03_dml/                          # Data Manipulation Language (reservado)
├── 04_views/                        # Views (reservado)
│
├── 05_triggers/                     # Triggers de validação e de log
│   ├── create_trg.sql
│   ├── create_log_trg.sql
│   └── rollback/
│
├── 06_procedures/                   # Stored Procedures
│   ├── create_procedures.sql
│   └── rollback/
│
├── 07_functions/                    # Functions de validação e de log
│   ├── create_functions.sql
│   ├── create_log_functions.sql
│   └── rollback/
│
├── 08_scripts_auxiliares/           # Scripts auxiliares (reservado)
│
├── 09_migrations/                   # Migrations versionadas (Flyway)
│   └── V001__init_database.sql      # Estrutura inicial (tabelas + FKs + constraints)
│
└── inventra_erp_fluxo.html          # Diagrama de fluxo ERP
```

> ⚠️ Por enquanto só existe a migration `V001`, que já consolida tabelas, chaves estrangeiras e constraints. Índices, tabelas de log, functions, procedures e triggers ainda são aplicados a partir dos scripts individuais em `02_ddl/`, `05_triggers/`, `06_procedures/` e `07_functions/` — a divisão em migrations `V002` a `V00N` está prevista nos [Próximos Passos](#️-próximos-passos).

---

## 🏗️ Tecnologias Utilizadas

| Tecnologia | Descrição |
|------------|-----------|
| **PostgreSQL** | SGBD principal do projeto |
| **Flyway** | Versionamento e migrations (padrão) |
| **drawdb** | Modelagem conceitual/lógica |
| **Git** | Controle de versão |
| **PL/pgSQL** | Functions, procedures e triggers |

---

## 🚀 Como Executar

### 1. Clone o repositório

```bash
git clone https://github.com/InventraTech/inventra-database.git
cd inventra-database/postgre
```

### 2. Execute a migration inicial

```bash
psql -U usuario -d inventra_db -f 09_migrations/V001__init_database.sql
```

### 3. Execute os demais scripts na ordem

Enquanto a divisão completa em migrations não é finalizada, os objetos adicionais são aplicados a partir dos scripts individuais, nesta ordem:

```bash
psql -U usuario -d inventra_db -f 02_ddl/logs/create_log_tables.sql
psql -U usuario -d inventra_db -f 02_ddl/indexes/create_indexes.sql
psql -U usuario -d inventra_db -f 07_functions/create_functions.sql
psql -U usuario -d inventra_db -f 07_functions/create_log_functions.sql
psql -U usuario -d inventra_db -f 05_triggers/create_trg.sql
psql -U usuario -d inventra_db -f 05_triggers/create_log_trg.sql
psql -U usuario -d inventra_db -f 06_procedures/create_procedures.sql
```

### 4. Rollback (se necessário)

```bash
psql -U usuario -d inventra_db -f 06_procedures/rollback/drop_procedures.sql
psql -U usuario -d inventra_db -f 05_triggers/rollback/drop_log_trg.sql
psql -U usuario -d inventra_db -f 05_triggers/rollback/drop_trg.sql
psql -U usuario -d inventra_db -f 07_functions/rollback/drop_log_functions.sql
psql -U usuario -d inventra_db -f 07_functions/rollback/drop_functions.sql
psql -U usuario -d inventra_db -f 02_ddl/indexes/rollback_indexes/drop_indexes.sql
psql -U usuario -d inventra_db -f 02_ddl/logs/rollback_logs/drop_log_tables.sql
psql -U usuario -d inventra_db -f 02_ddl/rollback/drop_constraints.sql
```

---

## 📊 Modelagem do Banco

O banco de dados possui **15 tabelas de negócio** + **7 tabelas de log** (auditoria), totalizando **22 tabelas**, organizadas em:

- **Cadastros Base:** `tb_usuario`, `tb_perfil`, `tb_cozinha`, `tb_produto`, `tb_fornecedor`, `tb_categoria`, `tb_unidade_medida`
- **Movimentações:** `tb_estoque_lote`, `tb_requisicao`, `tb_requisicao_item`, `tb_inventario`
- **Relacionamentos:** `tb_produto_fornecedor`, `tb_produto_parametro_cozinha`
- **Eventos:** `tb_alerta`, `tb_inventario_contagem`
- **Auditoria/Log:** `tb_log_usuario`, `tb_log_produto`, `tb_log_fornecedor`, `tb_log_estoque_lote`, `tb_log_requisicao`, `tb_log_inventario`, `tb_log_alerta`

Além das tabelas, o banco conta com:

- **13 functions** — 6 de validação/regra de negócio (`07_functions/create_functions.sql`) e 7 de log (`07_functions/create_log_functions.sql`)
- **13 triggers** — 6 de validação (`05_triggers/create_trg.sql`) e 7 de log (`05_triggers/create_log_trg.sql`)
- **6 stored procedures** de fluxo (aprovação/reprovação de requisição, entrada e baixa de estoque, fechamento de inventário) em `06_procedures/create_procedures.sql`

---

## 🔧 Scripts Disponíveis

| Diretório | Conteúdo |
|-----------|----------|
| `02_ddl/tables/` | CREATE TABLE das tabelas de negócio |
| `02_ddl/logs/` | CREATE TABLE das tabelas de auditoria/log |
| `02_ddl/indexes/` | Índices para otimização de consultas |
| `02_ddl/constraints/` | FK, CHECK e regras de negócio |
| `02_ddl/*/rollback*/` | Scripts de reversão para cada objeto |
| `05_triggers/` | Triggers de validação e de log |
| `06_procedures/` | Stored procedures de fluxo |
| `07_functions/` | Functions de validação e de log |
| `09_migrations/` | Histórico versionado do banco |

---

## 🗺️ Próximos Passos

- [ ] Dividir a criação de logs, índices, functions, procedures e triggers em migrations próprias (`V002` a `V00N`)
- [ ] Adicionar scripts de `views` e `DML` (seeds/dados iniciais)
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