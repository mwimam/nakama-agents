#!/usr/bin/env bash
# Pasang kru Nakama versi Claude Code ke satu workspace (per project, bukan global).
#
#   claude-code/install.sh [--dry-run] <workspace-dir> <project-root>
#
# <workspace-dir>  folder tempat kamu menjalankan `claude --agent nami`
#                  (mis. folder induk yang berisi repo BE dan FE)
# <project-root>   project root Nakama (mis. ~/Projects/<project>)
#
# Yang dilakukan:
# - Symlink setiap agent di claude-code/agents ke <workspace-dir>/.claude/agents/
#   (agent lain yang sudah ada tidak disentuh; file bernama sama dicadangkan)
# - Menulis <workspace-dir>/.claude/nakama-project berisi path project root
# - Menyalin templates/AGENTS.md ke <project-root>/engineering/AGENTS.md jika belum ada
# Aman dijalankan berulang kali.

set -euo pipefail

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then DRY_RUN=1; shift; fi
[ $# -eq 2 ] || { echo "Pakai: $0 [--dry-run] <workspace-dir> <project-root>" >&2; exit 1; }

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd "$1" && pwd)"
PROJECT_ROOT="$(cd "$2" && pwd)"
AGENTS_DST="$WORKSPACE/.claude/agents"

run() {
  echo "+ $*"
  [ "$DRY_RUN" -eq 1 ] || "$@"
}

echo "== 1/3 Agent → $AGENTS_DST"
run mkdir -p "$AGENTS_DST"
for src in "$SRC_DIR"/agents/*.md; do
  dst="$AGENTS_DST/$(basename "$src")"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "  sudah benar: $(basename "$src")"
    continue
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    run mv "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
  fi
  run ln -s "$src" "$dst"
done

echo "== 2/3 Penanda project → $WORKSPACE/.claude/nakama-project"
if [ "$DRY_RUN" -eq 1 ]; then
  echo "+ echo $PROJECT_ROOT > $WORKSPACE/.claude/nakama-project"
else
  echo "$PROJECT_ROOT" > "$WORKSPACE/.claude/nakama-project"
fi

echo "== 3/3 Guardrail → $PROJECT_ROOT/engineering/AGENTS.md"
if [ -e "$PROJECT_ROOT/engineering/AGENTS.md" ]; then
  echo "  sudah ada, tidak ditimpa"
else
  run mkdir -p "$PROJECT_ROOT/engineering"
  run cp "$SRC_DIR/templates/AGENTS.md" "$PROJECT_ROOT/engineering/AGENTS.md"
  echo "  isi placeholder <...> di file itu"
fi

cat <<EOF

Selesai. Jalankan:
  cd "$WORKSPACE" && claude --agent nami
Jika <workspace-dir> ada di dalam repo git, tambahkan .claude/agents dan .claude/nakama-project ke .git/info/exclude.
EOF
