# Migração Redis para inventra-database-2

## Origem e escopo

Origem: `InventraTech/inventra-development-spring-redis-neo4j-2`, branch `feat/ranking-validade-redis`, commit `a624a97d3806525d86f422152a656d98471acae2`.

Destino: `inventra-database-2/redis/`, ao lado de `postgre/`.

Foram importados os arquivos versionados da aplicação (src, testes, Maven Wrapper, pom, Dockerfile, exemplos de ambiente e documentação). O README original está em `docs/api-original.md`; seus links relativos continuam sendo referências à estrutura original. Os workflows foram adaptados para o novo diretório. `.git`, `.env`, target, IDE e arquivos locais não fazem parte da importação.

As entregas Redis dependem dos serviços e entidades da API. A aplicação completa foi mantida para preservar os fluxos sem criar fronteiras de rede, duplicar regras ou remover endpoints. O repositório de origem permanece intacto durante esta etapa da migração. O destino já compila e testa sem checkout do repositório anterior. O corte de deploy deve escolher uma única versão da API; esta mudança não publica imagem nem altera produção.

## Compatibilidade SQL

O snapshot original continha duas versões Flyway V010: origem do cadastro e default de timestamp de movimentação. No destino, a segunda foi renomeada para `V011__stock_movement_created_at_default.sql`, sem mudar seu SQL. A referência no teste integrado foi atualizada. O teste de versões únicas protege a inicialização contra nova duplicidade.

`redis/src/main/resources/db/migration` preserva o histórico da aplicação importada. `postgre/migrations` tem um histórico independente: suas V010–V013 já possuem outros significados. Não juntar esses diretórios nem configurar o Flyway para ler ambos. Uma consolidação futura exige conferir o histórico do banco alvo; não executar repair automaticamente. Nenhum SQL existente em `postgre/` foi alterado.

## DevOps

Padrões extraídos do documento DevOps fornecido:

- Branch: `<tipo>/objetivo-branch`; usada `refactor/migrar-redis-database`.
- Commit: `<tipo>(escopo): descrição-curta`; sugestão `refactor(redis): migra INV2-24 INV2-25 e INV2-26 para database`.
- PR: `INV2-<nºcard>: Título da PR`; sugestão `INV2-26: Migrar integração, fila e ranking Redis para inventra-database-2`, relacionando também INV2-24 e INV2-25.

Os workflows têm permissão somente de leitura, timeout e serviços descartáveis. O CD da API não foi ativado no repositório de banco: a migração termina pronta para commit, sem publicação ou alteração do GitOps. O build Docker usa `redis/` como contexto.

As documentações importadas preservam evidências e referências históricas. Para executar a versão migrada, prevalecem os caminhos deste guia e de `TESTING.md`.
