# Validação Redis

Execute a partir de `redis/`, com Java 21. A suíte padrão usa H2 e mocks e ignora integrações externas:

```powershell
.\mvnw.cmd -B -ntp test
```

Para conexão, fila e ranking reais, use apenas os serviços descartáveis deste projeto:

```powershell
docker compose -f compose.test.yaml up -d --wait
$env:REDIS_INTEGRATION_TESTS='true'
$env:REDIS_RANKING_TESTS='true'
$env:POSTGRES_REDIS_RANKING_TESTS='true'
$env:REDIS_HOST='127.0.0.1'
$env:REDIS_PORT='16379'
$env:REDIS_DATABASE='0'
$env:REDIS_SSL='false'
$env:REDIS_USERNAME=''
$env:REDIS_PASSWORD=''
try {
    .\mvnw.cmd -B -ntp test
    if ($LASTEXITCODE -ne 0) { throw 'Falha nos testes' }
} finally {
    docker compose -f compose.test.yaml down
    Remove-Item Env:REDIS_INTEGRATION_TESTS, Env:REDIS_RANKING_TESTS, Env:POSTGRES_REDIS_RANKING_TESTS
}
```

Use um terminal dedicado aos testes para não substituir variáveis de outro ambiente. Em Linux, exporte as mesmas variáveis e use `bash mvnw -B -ntp test`. A suíte PostgreSQL recria o schema `inventra_ranking_test` em 127.0.0.1:15432; não reutilize essas portas para dados reais.

Se Java NIO no Windows falhar ao criar loopback, o fallback já documentado na origem é acrescentar `"-DargLine=-Djdk.net.unixdomain.tmpdir=target/java-nio-tcp"` ao comando Maven, com esse diretório inexistente. Isso afeta somente o processo de testes.

Relatórios em `target/surefire-reports`. O CI da migração executa a suíte completa com Redis e PostgreSQL reais; a conexão, FIFO/DLQ, recuperação, concorrência, ranking e rollback permanecem cobertos pelos testes importados.

## Evidência da migração

Em 15/10/2026, no diretório `inventra-database-2/redis`, Java 21 e Redis 7/PostgreSQL 16 descartáveis: `mvnw.cmd -B -ntp "-DargLine=-Djdk.net.unixdomain.tmpdir=target/java-nio-tcp" verify` terminou com **BUILD SUCCESS: 468 testes, 0 falhas, 0 erros e 0 ignorados**, gerando o JAR executável. As três flags de integração estavam habilitadas.

Comparação de hashes confirmou a cópia idêntica do código Java de produção e dos scripts Lua. As migrations importadas mantiveram seu conteúdo, inclusive whitespace histórico para preservar checksums; apenas o nome da migration de timestamp mudou de V010 para V011. `postgre/` e o repositório da API não foram modificados. O workflow novo ainda depende do primeiro push/PR para executar no GitHub.
