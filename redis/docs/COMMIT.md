# Entrega para revisão

Branch: `refactor/migrar-redis-database`.

Mensagem de commit:

```text
refactor(redis): migra INV2-24 INV2-25 e INV2-26 para database
```

Título da PR:

```text
INV2-26: Migrar integração, fila e ranking Redis para inventra-database-2
```

Descrição: importa a aplicação executável e as entregas INV2-24, INV2-25 e INV2-26 em `redis/`, ao lado de `postgre/`. Preserva os contratos e fluxos existentes, adapta a execução do CI ao subdiretório e fornece serviços descartáveis para os testes. Corrige a colisão de versão Flyway da origem renomeando somente a migration de timestamp para V011.

Arquivos desta entrega: `redis/`, `.github/workflows/redis-tests.yml` e `README.md`. A pasta local `work/` já existia e não pertence à migração. Não usar `git add .` para incluí-la por acidente.

Os históricos de migrations de `postgre/` e `redis/` são independentes; consultar `MIGRATION.md` antes de planejar a consolidação ou o corte de produção.
