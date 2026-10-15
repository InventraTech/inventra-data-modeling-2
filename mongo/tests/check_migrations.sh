#!/usr/bin/env bash
# Valida a esteira do MongoDB: aplica as migrations (V*.js) duas vezes (idempotência),
# confere validadores e índices, reverte com drop_everything.js e reaplica do zero.
# Uso: MONGO_URI=mongodb://localhost:27017 MONGO_DB=dbIAI_ci ./check_migrations.sh
# Nunca apontar para o banco real: o passo 4 apaga as coleções.
set -euo pipefail

cd "$(dirname "$0")/.."
export MONGO_DB="${MONGO_DB:-dbIAI_ci}"
MONGOSH=(mongosh "${MONGO_URI:-mongodb://localhost:27017}" --quiet --file)

apply() {
  for f in migrations/V*.js; do
    echo "  -> $f"
    "${MONGOSH[@]}" "$f"
  done
}

echo "1/6 aplicando migrations (banco limpo)"; "${MONGOSH[@]}" migrations/rollback/drop_everything.js; apply
echo "2/6 reaplicando (idempotência)";        apply
echo "3/6 validadores e índices";             "${MONGOSH[@]}" tests/check_validators.js
echo "4/6 dicionário × migrations"
MONGO_DB="${MONGO_DB}_dict" "${MONGOSH[@]}" indexes/create_indexes.js
MONGO_REPO_DIR="$PWD" "${MONGOSH[@]}" tests/check_dictionary_sync.js
echo "5/6 rollback completo";                 "${MONGOSH[@]}" migrations/rollback/drop_everything.js
echo "6/6 reaplicando após rollback";         apply
echo "OK"
