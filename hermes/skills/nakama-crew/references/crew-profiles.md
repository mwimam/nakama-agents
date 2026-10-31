# Profile kru (franky, zoro): buat, atur, hapus

Profile bernama ada di `~/.hermes/profiles/<nama>`; profile `default` (Nami) di `~/.hermes`.
Satu folder = satu SOUL.md/config.yaml/memories/auth, jadi kru tidak bisa berbagi folder dengan Nami.

## Buat
```bash
hermes profile create franky --clone --no-alias --description "..."   # salin config/.env/SOUL/skills, tanpa bot token
cp references/crew/franky.md ~/.hermes/profiles/franky/SOUL.md
hermes -p franky config set model.default coding        # model beda per profile
hermes -p zoro tools disable file image_gen tts delegation cronjob computer_use browser
hermes -p franky config set delegation.worktree_isolation true --force   # subagent Franky dapat git worktree sendiri
```
- Profile baru dilayani gateway `default` yang sudah jalan; tidak perlu gateway/bot sendiri.
- `--clone` menyalin MEMORY.md/USER.md Nami. Kosongkan kalau kru harus mulai bersih.
- Cek model tersedia: `curl -s localhost:20128/v1/models` (combo lokal `coding`, `chat`).
- Tes cepat non-interaktif: `hermes -p <nama> chat -Q -q "..."` (bukan `timeout`, tidak ada di macOS).

## Subagent milik profile (Franky)
- Tool `delegation` ikut tersalin lewat `--clone`, jadi Franky sudah bisa membuat subagent (bawaan: maks 10 bersamaan, kedalaman 1, folder kerja sama).
- Isolasi: `delegation.worktree_isolation: true` di config profile itu memberi tiap subagent git worktree sendiri; hasil harus digabung ke branch kerja. Jangan menulis `max_concurrent_children` kalau Luffy minta tetap bawaan.
- Config profile ada di `~/.hermes/profiles/<nama>/config.yaml` (bukan di repo nakama-agents); catat setelannya di file ini supaya profile bisa dibuat ulang.

## Pitfalls
- `delegation.worktree_isolation` valid (dibaca `tools/delegate_tool_config.py`) walau CLI memperingatkan "not a recognized config key"; pakai `--force`. `max_concurrent_children` dibiarkan bawaan (10). Ubah config SETELAH Franky selesai, bukan saat ia jalan.
- `run-crew.sh` memakai path absolut karena skrip `cd` ke repo; path relatif membuat snapshot `git status` gagal dan memicu `ZORO-VIOLATION` palsu. Output kru bisa JSON polos multi-baris atau dibungkus ```json: parse dengan `JSONDecoder().raw_decode` dari `{` pertama.
- **Mematikan tool `file` tidak membuat profile read-only**: `terminal` tetap bisa menulis (`>`, `sed -i`). Kunci Zoro = larangan eksplisit di persona (termasuk lewat terminal, laporan lewat `summary` JSON) + `git status/diff` sebelum-sesudah di `run-crew.sh`. Uji dengan menyuruh Zoro menulis file; harus menolak.
- Shell tool yang cwd-nya terhapus membuat semua perintah berikutnya gagal (`getcwd`); pindah ke direktori yang ada (atur `workdir`) sebelum menghapus folder uji.

## Hapus profile
1. Tampilkan apa yang hilang: cron (`cron/jobs.json`), memori, gateway yang jalan, alias.
2. Backup dulu ke `~/Documents/hermes-thing/backup-profiles/<tanggal>/<profile>/` (memories, cron, config.yaml, SOUL.md, .env, skills); `chmod -R go-rwx` karena `.env` berisi kunci. Riwayat sesi tidak ikut tersimpan.
3. Verifikasi byte per byte (`cmp`/`diff -rq`) dan `jobs.json` valid sebelum hapus.
4. Tunggu konfirmasi eksplisit Luffy, lalu `hermes profile delete -y <nama>` (gateway profile itu dihentikan otomatis).
5. `hermes profile list` harus hanya menampilkan profile yang tersisa.
