#!/usr/bin/env bash
# Confere que o KEYSPACE.md e os comandos de redis/commands/ descrevem as mesmas chaves.
# Placeholders (<id>, {id}) viram {} para comparar só a forma da chave.
# Uso: bash redis/tests/check_keyspace_sync.sh   (não precisa de Redis)
set -euo pipefail

cd "$(dirname "$0")/.."
normalize() { sed -E 's/<[^>]*>/{}/g; s/\{[^}]*\}/{}/g'; }

# Chaves da tabela "Visão geral": primeira coluna, entre crases.
documented=$(tr -d '\r' < docs/KEYSPACE.md \
  | grep -E '^\| `(rt|kar|inventra):' \
  | sed -E 's/^\| `([^`]+)`.*/\1/' | normalize | sort -u)

# Chaves usadas nos comandos: só linhas que não são comentário.
used=$(cat commands/*/*.redis | tr -d '\r' | grep -vE '^\s*#' \
  | grep -oE '(rt|kar|inventra):[^ ]+' | normalize | sort -u)

[ -n "$documented" ] || { echo "ERRO: nenhuma chave encontrada em docs/KEYSPACE.md"; exit 1; }
[ -n "$used" ] || { echo "ERRO: nenhuma chave encontrada em commands/"; exit 1; }

status=0
only_cmd=$(comm -13 <(echo "$documented") <(echo "$used"))
only_doc=$(comm -23 <(echo "$documented") <(echo "$used"))
if [ -n "$only_cmd" ]; then
  echo "Usadas nos comandos e ausentes do KEYSPACE.md:"; echo "$only_cmd" | sed 's/^/  - /'; status=1
fi
if [ -n "$only_doc" ]; then
  echo "Documentadas no KEYSPACE.md e sem nenhum comando em redis/commands/:"; echo "$only_doc" | sed 's/^/  - /'; status=1
fi
[ "$status" -eq 0 ] && echo "OK: $(echo "$documented" | wc -l | tr -d ' ') chaves documentadas e usadas nos comandos"
exit "$status"
