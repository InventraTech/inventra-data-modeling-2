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
├── 05_triggers/                     # Dicionário de Gatilhos de Negócio e Auditoria
├── 06_procedures/                   # Dicionário de Rotinas de Negócio
├── 07_functions/                    # Dicionário de Funções do Sistema
│   └── (Todas as pastas acima possuem uma subpasta `/rollback` com scripts de reversão)
│
├── 09_migrations/                   # Scripts consolidados e idempotentes para execução direta
│   ├── V001__init_database.sql      # Criação estrutural (Tabelas, FKs, Indexes, Checks)
│   ├── V002__business_rules.sql     # Inteligência (Functions, Procedures e Triggers de negócio)
│   └── V003__audit_logs.sql         # Rastreabilidade (Tabelas, Funções e Gatilhos de log)
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

## 🔧 Compreendendo a Arquitetura

| Diretório | Propósito |
|-----------|-----------|
| **Dicionário (02 a 08)** | Fonte da verdade para consulta de desenvolvedores. Código estrito (`CREATE TABLE`). |
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
- [ ] Adicionar scripts de `views`
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
