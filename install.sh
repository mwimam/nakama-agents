#!/usr/bin/env bash
# Pasang Nakama Agent System ke Hermes Agent.
# - Menambahkan hermes/skills repo ini ke skills.external_dirs (tanpa menghapus entri lain)
# - Memasang hermes/SOUL.md sebagai identitas Nami (symlink, SOUL.md lama dicadangkan)
# Aman dijalankan berulang kali. Pakai --dry-run untuk melihat langkahnya saja.

set -euo pipefail

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_DIR/hermes/skills"
SOUL_SRC="$REPO_DIR/hermes/SOUL.md"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SOUL_DST="$HERMES_HOME/SOUL.md"

run() {
  echo "+ $*"
  [ "$DRY_RUN" -eq 1 ] || "$@"
}

command -v hermes >/dev/null || { echo "✗ Perintah 'hermes' tidak ditemukan. Install Hermes Agent dulu." >&2; exit 1; }
command -v python3 >/dev/null || { echo "✗ python3 tidak ditemukan." >&2; exit 1; }
[ -f "$SKILLS_DIR/nakama-crew/SKILL.md" ] || { echo "✗ Skill tidak ditemukan di $SKILLS_DIR" >&2; exit 1; }

echo "== 1/3 Skill: skills.external_dirs"
current="$(hermes config get skills.external_dirs --json 2>/dev/null || echo null)"
merged="$(CURRENT="$current" NEW_DIR="$SKILLS_DIR" python3 -I -c '
import json, os
try:
    cur = json.loads(os.environ["CURRENT"])
except ValueError:
    cur = None
cur = cur if isinstance(cur, list) else []
new = os.environ["NEW_DIR"]
norm = lambda p: os.path.realpath(os.path.expanduser(os.path.expandvars(str(p))))
if any(norm(p) == norm(new) for p in cur):
    print("")
else:
    print(json.dumps(cur + [new]))
')"
if [ -z "$merged" ]; then
  echo "  sudah terdaftar: $SKILLS_DIR"
else
  run hermes config set skills.external_dirs "$merged"
fi

echo "== 2/3 Identitas Nami: $SOUL_DST"
run mkdir -p "$HERMES_HOME"
if [ -L "$SOUL_DST" ] && [ "$(readlink "$SOUL_DST")" = "$SOUL_SRC" ]; then
  echo "  symlink sudah benar"
else
  if [ -e "$SOUL_DST" ] || [ -L "$SOUL_DST" ]; then
    backup="$SOUL_DST.bak.$(date +%Y%m%d%H%M%S)"
    run mv "$SOUL_DST" "$backup"
    echo "  SOUL.md lama dicadangkan ke $backup"
  fi
  run ln -s "$SOUL_SRC" "$SOUL_DST"
fi

echo "== 3/3 Cek"
if [ "$DRY_RUN" -eq 1 ]; then
  echo "  (dry-run, dilewati)"
elif hermes skills list 2>/dev/null | grep -q "nakama-crew"; then
  echo "  ✓ nakama-crew terdaftar"
else
  echo "  ⚠ nakama-crew belum muncul di 'hermes skills list'. Cek versi Hermes dan config skills.external_dirs." >&2
fi

cat <<EOF

Selesai. Langkah manual yang tersisa:
  - Atur model kru di ~/.hermes/config.yaml bagian 'delegation' (lihat README bagian 9).
  - Restart gateway/sesi Hermes supaya SOUL.md dan skill baru terbaca.
EOF
