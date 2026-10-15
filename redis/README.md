# Redis Inventra

Entregas INV2-24 (conexão Redis), INV2-25 (fila de cadastro por código de barras) e INV2-26 (ranking de lotes por validade), importadas da API para `redis/` na raiz de `inventra-database-2`.

O projeto preserva a aplicação Spring Boot completa porque os fluxos usam autenticação, produtos, estoque, transações PostgreSQL e endpoints existentes. Não é um novo microsserviço Redis. A importação mantém os pacotes, contratos HTTP, scripts Lua, TTLs e regras de processamento.

## Executar

Requisitos: Java 21 e acesso aos serviços configurados. Execute os comandos a partir de `redis/`.

```powershell
Copy-Item .env.example .env
# Preencha .env com as configurações do seu ambiente.
.\mvnw.cmd spring-boot:run
```

Linux: `./mvnw spring-boot:run`. Para Docker, a partir da raiz do repositório: `docker build -t inventra-api-redis ./redis`.

O arquivo `.env` não é versionado. A importação não contém credenciais de produção. Redis gerenciado continua usando TLS conforme `.env.example`.

## Validar

```powershell
.\mvnw.cmd -B -ntp test
```

Integrações reais usam serviços descartáveis: `docker compose -f compose.test.yaml up -d --wait`. Configure as variáveis descritas em [TESTING.md](docs/TESTING.md) e execute os mesmos testes do CI. Finalize com `docker compose -f compose.test.yaml down`.

## Entregas

| Card | Implementação | Documentação |
| --- | --- | --- |
| INV2-24 | `RedisConfig`, configuração de conexão e `RedisConnectionTest` | `.env.example` e [API original](docs/api-original.md) |
| INV2-25 | Producer/consumer, FIFO, recuperação, retries e DLQ | [Fila](docs/redis-product-queue.md) |
| INV2-26 | Sorted Set por cozinha, sincronização após commit e TTL | [Ranking](docs/redis-expiration-ranking.md) |

Os workflows Redis ficam em `../.github/workflows/` e executam Maven dentro de `redis/`. Os workflows PostgreSQL existentes permanecem independentes. Detalhes de origem, compatibilidade e padrão DevOps: [MIGRATION.md](docs/MIGRATION.md).
