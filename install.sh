#!/usr/bin/env bash
# Instala esta configuracao do Claude Code em ~/.claude (Linux/macOS). Requer python3 ou jq.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
CLAUDE="$HOME/.claude"

# 1. Backup do ~/.claude existente
if [ -d "$CLAUDE" ]; then
  BACKUP="$HOME/.claude-backup-$(date +%Y%m%d-%H%M%S)"
  cp -a "$CLAUDE" "$BACKUP"
  echo "Backup criado em $BACKUP"
else
  mkdir -p "$CLAUDE"
fi

# 2. Juntar settings.json (as chaves existentes ficam; as deste repo sobrepoem-se em caso de conflito)
TARGET="$CLAUDE/settings.json"
[ -s "$TARGET" ] || echo '{}' > "$TARGET"
TMP="$(mktemp)"
if command -v python3 >/dev/null 2>&1; then
  python3 -I - "$TARGET" "$SRC/settings.json" > "$TMP" <<'PY'
import json, sys
def merge(a, b):
    for k, v in b.items():
        if isinstance(v, dict) and isinstance(a.get(k), dict):
            merge(a[k], v)
        else:
            a[k] = v
    return a
base = json.load(open(sys.argv[1], encoding="utf-8"))
extra = json.load(open(sys.argv[2], encoding="utf-8"))
print(json.dumps(merge(base, extra), indent=2, ensure_ascii=False))
PY
elif command -v jq >/dev/null 2>&1; then
  jq -s '.[0] * .[1]' "$TARGET" "$SRC/settings.json" > "$TMP"
else
  echo "Erro: preciso de python3 ou jq para juntar o settings.json" >&2
  rm -f "$TMP"; exit 1
fi
mv "$TMP" "$TARGET"
echo "settings.json atualizado"

# 3. CLAUDE.md e skills
cp "$SRC/CLAUDE.md" "$CLAUDE/CLAUDE.md"
mkdir -p "$CLAUDE/skills"
for d in "$SRC"/skills/*/; do
  cp -r "$d" "$CLAUDE/skills/"
  echo "Skill copiada: $(basename "$d")"
done

# 4. Comandos /plugin a correr dentro do Claude Code
echo
echo "Corre estes comandos dentro do Claude Code:"
echo "  /plugin marketplace add anthropics/claude-plugins-official"
grep -oE '"[^"]+@[^"]+": *true' "$SRC/settings.json" | sed -E 's/^"([^"]+)".*/  \/plugin install \1/'
