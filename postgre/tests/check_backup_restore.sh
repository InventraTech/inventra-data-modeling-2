#!/usr/bin/env bash
# Valida a recuperação: desfaz operações pela auditoria, gera um backup, restaura em
# banco novo e compara a contagem de linhas de cada tabela entre origem e restaurado.
# Rodar depois de check_migrations.sh (o banco precisa estar com as migrations aplicadas).
# Uso: PGHOST=... PGUSER=... PGPASSWORD=... PGDATABASE=... ./check_backup_restore.sh
set -euo pipefail

cd "$(dirname "$0")/.."
export BACKUP_DIR="$(mktemp -d)"
restore_db="${PGDATABASE}_restore_check"
counts="SELECT table_name || '=' || row_count FROM fn_table_row_counts() WHERE table_name <> 'tb_backup_history';"

echo "1/5 recuperação pela auditoria";  psql -X -q -v ON_ERROR_STOP=1 -f tests/check_audit_restore.sql
echo "2/5 backup";                      bash backup/backup.sh
dump="$(ls -1t "$BACKUP_DIR"/*.dump | head -n 1)"
echo "3/5 restore em banco novo";       RESTORE_REPLACE=yes bash backup/restore.sh "$dump" "$restore_db" > /dev/null
echo "4/5 comparando contagens"
diff <(psql -X -tA -c "$counts") <(psql -X -tA -d "$restore_db" -c "$counts")
echo "5/5 histórico e situação do backup"
status="$(psql -X -tA -c "SELECT backup_status || ' ' || (last_restore_at IS NOT NULL) FROM vw_backup_status;")"
[[ "$status" == "OK true" ]] || { echo "vw_backup_status inesperado: $status" >&2; exit 1; }

dropdb "$restore_db"
echo "OK"
