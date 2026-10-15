# Neo4j

**Status: não usado.** Nenhum serviço do Inventra conecta ao Neo4j hoje, então ainda não há modelo de grafo, constraints ou scripts Cypher para versionar aqui.

Levantamento feito em 14/10/2026, em todas as branches de:

| Repositório | Resultado |
|-------------|-----------|
| [`inventra-development-spring-redis-neo4j-2`](https://github.com/InventraTech/inventra-development-spring-redis-neo4j-2) (API) | O nome cita Neo4j, mas não há dependência (`pom.xml` sem `spring-boot-starter-data-neo4j`), configuração (`spring.neo4j.*`), variável de ambiente nem código. A única menção é o link do repositório em `docs/inv2-25-review.md` |
| [`inventra-artificial-intelligence-2`](https://github.com/InventraTech/inventra-artificial-intelligence-2) (IAI) | Nenhuma menção. A IA usa MongoDB (ver [`../mongo`](../mongo)) e consulta o estoque pela API |

Quando o Neo4j entrar, a pasta segue o mesmo desenho das outras:

```text
neo4j/
├── constraints/     # CREATE CONSTRAINT ... IF NOT EXISTS (unicidade e existência) + rollback/
├── indexes/         # CREATE INDEX ... IF NOT EXISTS + rollback/
├── migrations/      # V001__*.cypher idempotentes + rollback/drop_everything.cypher
├── seeds/           # seed.ipynb (driver neo4j + dotenv), com IDs vindos do PostgreSQL
├── tests/           # aplica 2x, rollback e reaplica num neo4j:5 descartável
└── docs/            # modelo de nós e relacionamentos e consultas atendidas
```

Os nós devem carregar o ID do PostgreSQL (`id_product`, `id_supplier`, `id_kitchen`...) como chave com constraint de unicidade, já que o PostgreSQL continua sendo a fonte da verdade do cadastro.
