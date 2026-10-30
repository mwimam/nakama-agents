#!/usr/bin/env bash
# Cek setiap artifact ada dan tidak kosong.
# Pemakaian: verify-artifact.sh [--root <project-root>] <path> [<path> ...]
# Exit 0 jika semua lolos, 1 jika ada yang gagal, 2 jika argumen salah.

set -u

root=""
if [ "${1:-}" = "--root" ]; then
  root="${2:-}"
  shift 2 || { echo "usage: $0 [--root <dir>] <path>..." >&2; exit 2; }
  root="${root/#\~/$HOME}"
  root="${root%/}"
fi

if [ "$#" -eq 0 ]; then
  echo "usage: $0 [--root <dir>] <path>..." >&2
  exit 2
fi

fail=0
for raw in "$@"; do
  p="${raw/#\~/$HOME}"

  case "/$p/" in
    */../*) echo "FAIL  $raw  (path mengandung '..')"; fail=1; continue ;;
  esac

  if [ -n "$root" ]; then
    case "$p" in
      "$root"/*) ;;
      *) echo "FAIL  $raw  (di luar root $root)"; fail=1; continue ;;
    esac
  fi

  if [ -f "$p" ]; then
    if [ -s "$p" ]; then
      echo "OK    $raw  ($(wc -c < "$p" | tr -d ' ') bytes)"
    else
      echo "FAIL  $raw  (file kosong)"; fail=1
    fi
  elif [ -d "$p" ]; then
    if [ -n "$(ls -A "$p" 2>/dev/null)" ]; then
      echo "OK    $raw  (direktori berisi)"
    else
      echo "FAIL  $raw  (direktori kosong)"; fail=1
    fi
  else
    echo "FAIL  $raw  (tidak ditemukan)"; fail=1
  fi
done

exit "$fail"
