#!/usr/bin/env bash
# Funções comuns de backup.sh e restore.sh (carregado com source; não executar direto).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKUP_DIR="${BACKUP_DIR:-$SCRIPT_DIR/dumps}"
PG_CLIENT_IMAGE="${PG_CLIENT_IMAGE:-}"

# Conexão vem de UMA fonte só, para nunca misturar host de um banco com porta/senha de outro:
#   - PGHOST definido -> usa as variáveis PG* do ambiente (ex.: CI);
#   - senão           -> usa o .env da raiz (DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, DB_SSLMODE).
# O .env é lido linha a linha, sem source, para não carregar as outras chaves que ele guarda.
load_env() {
  local env_file="$REPO_ROOT/.env" key value
  if [[ -z "${PGHOST:-}" && -f "$env_file" ]]; then
    unset PGPORT PGDATABASE PGUSER PGPASSWORD PGSSLMODE
    while IFS='=' read -r key value || [[ -n "$key" ]]; do
      value="${value%$'\r'}"
      value="${value%\"}"; value="${value#\"}"
      case "$key" in
        DB_HOST|DB_PORT|DB_NAME|DB_USER|DB_PASSWORD|DB_SSLMODE) printf -v "$key" '%s' "$value" ;;
      esac
    done < "$env_file"
  fi
  export PGHOST="${PGHOST:-${DB_HOST:-localhost}}"
  export PGPORT="${PGPORT:-${DB_PORT:-5432}}"
  export PGDATABASE="${PGDATABASE:-${DB_NAME:-inventra_db}}"
  export PGUSER="${PGUSER:-${DB_USER:-postgres}}"
  export PGPASSWORD="${PGPASSWORD:-${DB_PASSWORD:-}}"
  export PGSSLMODE="${PGSSLMODE:-${DB_SSLMODE:-prefer}}"

  # Sem cliente instalado, usa a imagem postgres:<versão do servidor>: um pg_dump mais
  # novo que o servidor gera comandos (ex.: SET transaction_timeout) que ele não aceita.
  if ! command -v pg_dump >/dev/null 2>&1 && [[ -z "$PG_CLIENT_IMAGE" ]]; then
    local version_num
    version_num="$(docker_run postgres:17 psql -X -tA -d "$PGDATABASE" -c 'SHOW server_version_num')" \
      || { echo "ERRO: não foi possível conectar em $PGHOST:$PGPORT para descobrir a versão do servidor." >&2; exit 1; }
    PG_CLIENT_IMAGE="postgres:$(( ${version_num//[^0-9]/} / 10000 ))"
    echo "  pg_dump não instalado: usando a imagem Docker $PG_CLIENT_IMAGE" >&2
  fi
}

# Roda um cliente do PostgreSQL dentro da imagem indicada, com BACKUP_DIR montado em /backup.
docker_run() {
  local image="$1"; shift
  local host_dir="$BACKUP_DIR" pghost="$PGHOST"
  mkdir -p "$BACKUP_DIR"
  command -v cygpath >/dev/null 2>&1 && host_dir="$(cygpath -w "$BACKUP_DIR")"
  [[ "$pghost" == "localhost" || "$pghost" == "127.0.0.1" ]] && pghost="host.docker.internal"
  MSYS_NO_PATHCONV=1 docker run --rm -i \
    --add-host=host.docker.internal:host-gateway \
    -e PGHOST="$pghost" -e PGPORT -e PGUSER -e PGPASSWORD -e PGSSLMODE \
    -v "$host_dir:/backup" -w /backup \
    "$image" "$@"
}

# Roda pg_dump, pg_restore, psql, createdb ou dropdb a partir de BACKUP_DIR: o cliente
# instalado ou, se não houver, o da imagem Docker. Arquivos são passados pelo nome.
pg_run() {
  if command -v "$1" >/dev/null 2>&1; then
    (cd "$BACKUP_DIR" && "$@")
  else
    docker_run "$PG_CLIENT_IMAGE" "$@"
  fi
}

now_utc() {
  date -u '+%Y-%m-%d %H:%M:%S+00'
}

# Grava a execução em tb_backup_history via sp_register_backup. Não derruba o script
# se o registro falhar (ex.: o banco de controle está fora do ar no desastre).
# Uso: register_history <banco> <BACKUP|RESTORE> <SUCCESS|FAILED> <arquivo> <início> <fim> [tamanho] [sha256] [erro] [banco_alvo]
register_history() {
  local db="$1" op="$2" status="$3" file="$4" started="$5" finished="$6"
  local size="${7:-}" checksum="${8:-}" error="${9:-}" target="${10:-$1}"
  pg_run psql -X -q -v ON_ERROR_STOP=1 -d "$db" \
    -v op="$op" -v status="$status" -v file="$file" -v started="$started" -v finished="$finished" \
    -v size="$size" -v checksum="$checksum" -v err="$error" -v target="$target" <<'SQL' \
    || echo "aviso: não foi possível registrar a execução em tb_backup_history ($db)." >&2
CALL sp_register_backup(
    p_operation => :'op',
    p_status => :'status',
    p_file_name => :'file',
    p_started_at => :'started'::timestamptz,
    p_finished_at => :'finished'::timestamptz,
    p_file_size_bytes => NULLIF(:'size', '')::bigint,
    p_checksum_sha256 => NULLIF(:'checksum', ''),
    p_error_message => NULLIF(:'err', ''),
    p_database_name => :'target'
);
SQL
}
