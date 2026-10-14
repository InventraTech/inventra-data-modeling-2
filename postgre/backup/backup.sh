#!/usr/bin/env bash
# Backup lógico do banco (pg_dump, formato custom) com checksum, verificação e rotação.
# Uso: bash postgre/backup/backup.sh
# Variáveis opcionais: BACKUP_DIR (padrão postgre/backup/dumps), BACKUP_KEEP (padrão 7),
# PG_CLIENT_IMAGE (sem pg_dump instalado, usa a imagem postgres:<versão do servidor>).
set -euo pipefail
source "$(dirname "$0")/lib.sh"

load_env
mkdir -p "$BACKUP_DIR"
keep="${BACKUP_KEEP:-7}"
file="${PGDATABASE}_$(date -u '+%Y%m%d_%H%M%S').dump"
started="$(now_utc)"

fail() {
  echo "ERRO: $1" >&2
  rm -f "$BACKUP_DIR/$file" "$BACKUP_DIR/$file.sha256"
  register_history "$PGDATABASE" BACKUP FAILED "$file" "$started" "$(now_utc)" "" "" "$1"
  exit 1
}

echo "1/4 pg_dump $PGDATABASE@$PGHOST -> $BACKUP_DIR/$file"
pg_run pg_dump -Fc --no-owner --no-privileges -d "$PGDATABASE" -f "$file" \
  || fail "pg_dump falhou"

echo "2/4 verificando se o arquivo é legível"
pg_run pg_restore --list "$file" > /dev/null \
  || fail "pg_restore --list não conseguiu ler $file"

echo "3/4 gerando checksum"
(cd "$BACKUP_DIR" && sha256sum "$file" > "$file.sha256")
checksum="$(cut -d ' ' -f 1 "$BACKUP_DIR/$file.sha256")"
size="$(wc -c < "$BACKUP_DIR/$file" | tr -d ' ')"

echo "4/4 rotação: mantendo os $keep backups mais recentes de $PGDATABASE"
ls -1t "$BACKUP_DIR/${PGDATABASE}_"*.dump | tail -n +"$((keep + 1))" | while IFS= read -r old; do
  echo "  removendo $(basename "$old")"
  rm -f "$old" "$old.sha256"
done

register_history "$PGDATABASE" BACKUP SUCCESS "$file" "$started" "$(now_utc)" "$size" "$checksum"
echo "OK $file ($size bytes, sha256 $checksum)"
