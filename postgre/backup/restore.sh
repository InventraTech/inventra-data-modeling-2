#!/usr/bin/env bash
# Restaura um backup gerado por backup.sh.
# Uso: bash postgre/backup/restore.sh <arquivo.dump> [banco_destino]
#
# Destino padrão: <DB_NAME>_restore, um banco NOVO (o de origem não é tocado).
#   - destino já existe       -> erro, a não ser com RESTORE_REPLACE=yes (apaga e recria)
#   - destino = banco de origem -> exige CONFIRM_OVERWRITE=yes (substitui os objetos no lugar)
# O restore roda em transação única: se falhar no meio, o destino não fica pela metade.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

dump="${1:?informe o arquivo .dump}"
[[ -f "$dump" ]] || { echo "ERRO: arquivo $dump não encontrado." >&2; exit 1; }

load_env
BACKUP_DIR="$(cd "$(dirname "$dump")" && pwd)"
file="$(basename "$dump")"
target="${2:-${PGDATABASE}_restore}"
started="$(now_utc)"

fail() {
  echo "ERRO: $1" >&2
  register_history "$PGDATABASE" RESTORE FAILED "$file" "$started" "$(now_utc)" "" "" "$1" "$target"
  exit 1
}

echo "1/4 conferindo checksum"
if [[ -f "$BACKUP_DIR/$file.sha256" ]]; then
  (cd "$BACKUP_DIR" && sha256sum -c --quiet "$file.sha256") || fail "checksum não confere: arquivo corrompido"
  checksum="$(cut -d ' ' -f 1 "$BACKUP_DIR/$file.sha256")"
else
  echo "  aviso: $file.sha256 não encontrado; seguindo sem conferir." >&2
  checksum=""
fi

echo "2/4 preparando o banco $target"
clean_args=()
if [[ "$target" == "$PGDATABASE" ]]; then
  [[ "${CONFIRM_OVERWRITE:-}" == "yes" ]] \
    || fail "destino é o próprio banco de origem; rode com CONFIRM_OVERWRITE=yes para substituir"
  clean_args=(--clean --if-exists)
else
  exists="$(pg_run psql -X -tA -d "$PGDATABASE" -v db="$target" <<'SQL'
SELECT 1 FROM pg_database WHERE datname = :'db';
SQL
)" || fail "não foi possível consultar os bancos existentes"
  if [[ -n "$exists" ]]; then
    [[ "${RESTORE_REPLACE:-}" == "yes" ]] \
      || fail "o banco $target já existe; rode com RESTORE_REPLACE=yes para apagar e recriar"
    pg_run dropdb --maintenance-db="$PGDATABASE" "$target" || fail "dropdb $target falhou"
  fi
  pg_run createdb --maintenance-db="$PGDATABASE" "$target" || fail "createdb $target falhou"
fi

echo "3/4 pg_restore $file -> $target"
pg_run pg_restore --no-owner --no-privileges --single-transaction "${clean_args[@]}" \
  -d "$target" "$file" \
  || fail "pg_restore falhou (nada foi aplicado: transação única)"

echo "4/4 contagem de linhas em $target"
pg_run psql -X -d "$target" -c "SELECT table_name, row_count FROM fn_table_row_counts();"

size="$(wc -c < "$BACKUP_DIR/$file" | tr -d ' ')"
register_history "$PGDATABASE" RESTORE SUCCESS "$file" "$started" "$(now_utc)" "$size" "$checksum" "" "$target"
echo "OK $file restaurado em $target"
