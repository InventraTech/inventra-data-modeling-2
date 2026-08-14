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
│       └── V1/                      # Versão 1 do modelo lógico
│
├── 02_ddl/                          # Data Definition Language
│   ├── tables/                      # Criação de tabelas
│   ├── indexes/                     # Índices de performance
│   ├── constraints/                 # Constraints (PK, FK, CHECK)
│   └── rollback/                    # Scripts de reversão
│
├── 09_migrations/                   # Migrations versionadas (Flyway)
│   ├── V001__init_database.sql      # Estrutura inicial
│   ├── V002__insert_seeds.sql       # Dados iniciais
│   ├── V003__create_indexes.sql     # Índices
│   ├── V004__create_views.sql       # Views
│   ├── V005__create_functions.sql   # Functions
│   ├── V006__create_procedures.sql  # Stored Procedures
│   └── V007__create_triggers.sql    # Triggers
│
└── inventra_erp_fluxo.html          # Diagrama de fluxo ERP
```

---

## 🏗️ Tecnologias Utilizadas

| Tecnologia | Descrição |
|------------|-----------|
| **PostgreSQL** | SGBD principal do projeto |
| **Flyway** | Versionamento e migrations (padrão) |
| **draw.io** | Modelagem conceitual/lógica |
| **Git** | Controle de versão |

---

## 🚀 Como Executar

### 1. Clone o repositório

```bash
git clone https://github.com/InventraTech/inventra-database.git
cd inventra-database/postgre
```

### 2. Execute as migrations na ordem

```bash
psql -U usuario -d inventra_db -f 09_migrations/V001__init_database.sql
psql -U usuario -d inventra_db -f 09_migrations/V002__insert_seeds.sql
psql -U usuario -d inventra_db -f 09_migrations/V003__create_indexes.sql
# ... e assim por diante
```

### 3. Rollback (se necessário)

```bash
psql -U usuario -d inventra_db -f 02_ddl/tables/rollback/drop_tables.sql
```

---

## 📊 Modelagem do Banco

O banco de dados possui **18 tabelas** principais, organizadas em:

- **Cadastros Base:** `tb_usuario`, `tb_perfil`, `tb_cozinha`, `tb_produto`, `tb_fornecedor`
- **Movimentações:** `tb_estoque_lote`, `tb_requisicao`, `tb_inventario`
- **Relacionamentos:** `tb_produto_fornecedor`, `tb_produto_parametro_cozinha`
- **Eventos:** `tb_alerta`, `tb_inventario_contagem`

---

## 🔧 Scripts Disponíveis

| Diretório | Conteúdo |
|-----------|----------|
| `02_ddl/tables/` | CREATE TABLE de todas as entidades |
| `02_ddl/indexes/` | Índices para otimização de consultas |
| `02_ddl/constraints/` | FK, CHECK e regras de negócio |
| `02_ddl/*/rollback/` | Scripts de reversão para cada objeto |
| `09_migrations/` | Histórico versionado do banco |

---

## 🗺️ Próximos Passos

- [ ] Adicionar scripts de `views`, `functions`, `procedures` e `triggers`
- [ ] Criar testes de integridade e performance
- [ ] Documentar dicionário de dados
- [ ] Configurar ambiente de desenvolvimento/homologação
- [ ] Integrar com aplicação principal

---

## 👥 Contribuidores

| Nome | Papel |
|------|-------|
| **@dvarakaki** | Desenvolvedor de Banco de Dados |

---

## 📄 Licença

Este projeto está sob a licença **MIT**. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 📞 Contato

- **GitHub:** [InventraTech](https://github.com/InventraTech)
- **Projeto:** Sistema Inventra - Gestão de Estoque e Cozinhas

---

**Status:** 🟢 Em desenvolvimento ativo