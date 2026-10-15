#!/usr/bin/env bash
# Sobe um Redis descartável com redis/config/redis.conf e confere que cada diretiva foi aceita e aplicada.
# Requer docker. Uso: bash redis/tests/check_config.sh
set -euo pipefail

cd "$(dirname "$0")/../.."
NAME="inventra-redis-ci-$$"
trap 'docker rm -f "$NAME" >/dev/null 2>&1 || true' EXIT

docker run -d --name "$NAME" -v "$PWD/redis/config/redis.conf:/usr/local/etc/redis/redis.conf:ro" \
  redis:7 redis-server /usr/local/etc/redis/redis.conf >/dev/null
cli() { docker exec "$NAME" redis-cli "$@"; }

timeout 30 bash -c "until docker exec $NAME redis-cli ping 2>/dev/null | grep -q PONG; do sleep 1; done" \
  || { echo "ERRO: o Redis não subiu com o redis.conf"; docker logs "$NAME" | tail -20; exit 1; }

fail=0
expect() { # diretiva esperada
  local got; got=$(cli config get "$1" | sed -n 2p)
  if [ "$got" = "$2" ]; then echo "  ok  $1 = $got"; else echo "  ERRO $1: esperado '$2', veio '$got'"; fail=1; fi
}

echo "Diretivas do redis.conf aplicadas:"
expect maxmemory-policy noeviction
expect appendonly yes
expect appendfsync everysec
expect hz 10
expect save "3600 1 300 100 60 10000"

# Todo valor do arquivo precisa estar coberto acima: diretiva nova sem teste falha aqui.
declared=$(tr -d '\r' < redis/config/redis.conf | grep -vE '^\s*(#|$)' | awk '{print $1}' | sort -u | tr '\n' ' ')
[ "$declared" = "appendfsync appendonly hz maxmemory-policy save " ] \
  || { echo "ERRO: redis.conf mudou ($declared); atualize redis/tests/check_config.sh"; fail=1; }

echo "Comportamento:"
cli set ci:probe 1 >/dev/null && [ "$(cli get ci:probe)" = "1" ] && echo "  ok  SET/GET" || { echo "  ERRO SET/GET"; fail=1; }

exit "$fail"
