#!/usr/bin/env bash
# Jalankan kru berprofile (franky|zoro). Usage: run-crew.sh <franky|zoro> <task-card.md> <repo-dir> [context-file...]
# Zoro: snapshot git status sebelum/sesudah; beda = FAIL (exit 3). Output JSON kru ke stdout.
set -u
crew=$1; card=$(realpath "$2"); repo=$(realpath "$3"); shift 3
ctx=(); for f in "$@"; do ctx+=("$(realpath "$f")"); done
here=$(cd "$(dirname "$0")/.." && pwd)
before=$(git -C "$repo" status --porcelain 2>&1; git -C "$repo" diff | shasum)
prompt="$(cat "$card")
$(for f in ${ctx[@]+"${ctx[@]}"}; do printf '\n--- %s ---\n' "$f"; cat "$f"; done)

Kerja di: $repo
Kembalikan HANYA JSON sesuai schema ini:
$(cat "$here/templates/output-schema.json")"
cd "$repo" && out=$(hermes -p "$crew" chat -Q -q "$prompt" 2>&1); rc=$?
printf '%s\n' "$out"
after=$(git -C "$repo" status --porcelain 2>&1; git -C "$repo" diff | shasum)
if [ "$crew" = zoro ] && [ "$before" != "$after" ]; then echo "ZORO-VIOLATION: repo berubah saat review" >&2; exit 3; fi
exit $rc
