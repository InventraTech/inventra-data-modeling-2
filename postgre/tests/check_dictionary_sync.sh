#!/usr/bin/env bash
# Garante que o dicionário (ddl/, functions/, procedures/, triggers/, views/) gera o mesmo schema
# que as migrations. Monta dois bancos temporários, um só com migrations/V*.sql e outro só com o
# dicionário na ordem abaixo, e compara os dois com tests/schema_fingerprint.sql.
# Uso: PGHOST=... PGUSER=... PGPASSWORD=... PGDATABASE=... ./check_dictionary_sync.sh
set -euo pipefail

cd "$(dirname "$0")/.."

# Ordem de execução do dicionário: cada arquivo depende só dos anteriores.
# Arquivo novo no dicionário entra nesta lista (o passo 1 falha se ficar de fora).
DICTIONARY=(
  ddl/tables/create_tables.sql
  ddl/constraints/create_constraints.sql
  ddl/indexes/create_indexes.sql
  ddl/logs/create_log_tables.sql
  ddl/logs/create_log_indexes.sql
  functions/create_functions.sql
  functions/create_log_functions.sql
  procedures/create_procedures.sql
  triggers/create_trg.sql
  triggers/create_log_trg.sql
  views/create_views.sql
  views/datamart/create_datamart_views.sql
  views/analytics/create_etl_views.sql
  ddl/catalog/create_catalog_tables.sql
  procedures/create_catalog_procedures.sql
  views/catalog/create_catalog_views.sql
  ddl/backup/create_backup_tables.sql
  functions/create_recovery_functions.sql
  procedures/create_recovery_procedures.sql
  views/backup/create_backup_views.sql
  ddl/monitoring/create_monitoring_tables.sql
  functions/create_monitoring_functions.sql
  triggers/create_monitoring_trg.sql
  views/monitoring/create_monitoring_views.sql
  ddl/monitoring/load_ui_click_counter.sql
  ddl/catalog/load_catalog_metadata.sql
)

mig_db="${PGDATABASE}_sync_migrations"
dict_db="${PGDATABASE}_sync_dictionary"
work="$(mktemp -d)"
cleanup() {
  dropdb --if-exists "$mig_db" 2>/dev/null || true
  dropdb --if-exists "$dict_db" 2>/dev/null || true
  rm -rf "$work"
}
trap cleanup EXIT

apply() {
  local db="$1" f="$2"
  psql -X -q -v ON_ERROR_STOP=1 -d "$db" -f "$f" > /dev/null 2> "$work/err" \
    || { echo "ERRO ao aplicar $f em $db:" >&2; cat "$work/err" >&2; exit 1; }
}

echo "1/4 todo arquivo do dicionário está na lista"
missing="$(comm -23 \
  <(find ddl functions procedures triggers views -name '*.sql' -not -path '*/rollback/*' | sort) \
  <(printf '%s\n' "${DICTIONARY[@]}" | sort))"
[[ -z "$missing" ]] || { echo "fora da lista DICTIONARY em $0:" >&2; echo "$missing" >&2; exit 1; }

echo "2/4 montando $mig_db (migrations)"
dropdb --if-exists "$mig_db" 2> /dev/null; createdb "$mig_db"
for f in migrations/V*.sql; do apply "$mig_db" "$f"; done

echo "3/4 montando $dict_db (dicionário)"
dropdb --if-exists "$dict_db" 2> /dev/null; createdb "$dict_db"
for f in "${DICTIONARY[@]}"; do apply "$dict_db" "$f"; done

echo "4/4 comparando os schemas"
psql -X -tA -d "$mig_db" -f tests/schema_fingerprint.sql > "$work/migrations.txt"
psql -X -tA -d "$dict_db" -f tests/schema_fingerprint.sql > "$work/dictionary.txt"
if ! diff -u --label migrations --label dicionario "$work/migrations.txt" "$work/dictionary.txt"; then
  echo "dicionário e migrations divergem (linhas - só nas migrations, + só no dicionário)." >&2
  exit 1
fi

echo "OK ($(wc -l < "$work/migrations.txt") objetos iguais)"
