---
name: nakama-crew
description: Delegasikan task ke kru Nakama (Franky/Zoro via profile `hermes -p` + run-crew.sh; Robin, Usopp, Sanji, Jinbe via delegate_task) memakai Task Card, persona kru, dan output_schema, lalu verifikasi hasilnya di disk. Gunakan untuk setiap task engineering, kreatif, riset, QA, atau compliance.
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [orchestration, delegation, nakama]
    category: orchestration
    requires_toolsets: [delegation]
---

# Nakama Crew Delegation

## When to Use
Setiap permintaan Luffy yang butuh kerja nyata: kode, tulisan, visual, riset,
review/QA, atau cek legal. Jangan dipakai untuk balasan chat biasa.

Skill ini milik Hermes: bergantung pada `delegate_task` dan profile `hermes -p`.
Claude Code CLI tidak memuat skill Hermes. Padanannya ada di folder `claude-code/`
repo ini (agent nami, robin, franky, zoro; pasang per workspace dengan
`claude-code/install.sh`, lihat README bagian 11). Kedua sisi berbagi workspace
`~/Projects/<project>/` (`progress.md`, `research/`, `worktree/`) dan membaca aturan
teknis yang sama di `engineering/AGENTS.md`, jadi konvensi repo ditulis di sana.

## Procedure

1. **Tentukan project aktif.**
   - Project ada di `~/Projects/<project>/`. Baca `context.md` dan `progress.md`.
   - Project baru → buat struktur folder sesuai README (bagian 4), salin
     `${HERMES_SKILL_DIR}/templates/progress.md` ke root project.
   - Permintaan ad-hoc → pakai `~/Projects/_scratch/` (buat jika belum ada).

2. **Pecah jadi Task Card.**
   - Pakai format `${HERMES_SKILL_DIR}/templates/task-card.md`. Satu card = satu kru = satu hasil.
   - Task yang butuh output task lain dikirim **setelah** task itu selesai dan lolos verifikasi.
   - Task yang tidak saling bergantung boleh dikirim paralel dalam satu `tasks=[...]`.

3. **Pilih kru** (tabel Routing); persona di:
   `${HERMES_SKILL_DIR}/references/crew/<kru>.md`.

4. **Franky dan Zoro = profile Hermes** (bukan subagent). Panggil lewat skrip,
   bukan `delegate_task`:
   ```bash
   bash ${HERMES_SKILL_DIR}/scripts/run-crew.sh \
     <franky|zoro> <task-card.md> <repo-dir> [file-konteks...]
   ```
   - Persona sudah ada di `~/.hermes/profiles/<kru>/SOUL.md`; tidak perlu ditempel.
   - Simpan Task Card ke file dulu (mis. `~/Projects/<project>/scratch/<task>.md`) dan
     sertakan `AGENTS.md`/`context.md` relevan sebagai file-konteks.
   - Task kode: TARGET PATH = worktree terpisah dari base yang baru di-fetch
     (`git fetch origin <base>` lalu `git worktree add -b <branch> ~/Projects/<project>/worktree/<nama> origin/<base>`, lalu `git branch --unset-upstream`). Jangan branch dari `<base>` lokal dan jangan kerja langsung di repo utama: base lokal sering ketinggalan puluhan commit, dan Luffy menegur kalau worktree tidak dibuat.
   - Franky memakai model `coding`. Zoro tool `file` mati; skrip membandingkan
     `git status`/`git diff` sebelum-sesudah. Beda = exit 3 `ZORO-VIOLATION`: review
     ditolak, kembalikan perubahan, laporkan ke Luffy.
   - Zoro tidak menulis file: laporan ada di `summary` JSON; Nami yang menyimpan ke `research/` atau `engineering/reviews/`.
   - Output: ambil blok JSON terakhir dari stdout lalu validasi sendiri terhadap `templates/output-schema.json` (gantikan `schema_valid`).
   - **Robin, Usopp, Sanji, Jinbe** tetap `delegate_task` seperti semula: `goal` = PROBLEM/OBJECTIVE; `context` = isi persona
     `references/crew/<kru>.md` + Task Card + ringkasan `context.md` + path absolut; `output_schema` = `templates/output-schema.json`.

5. **Verification Gate** (lihat bagian di bawah). Jangan lewati.

6. **Tutup task.**
   - Lolos → update `progress.md`, salin hasil final ke `deliverables/` jika
     memang deliverable untuk Luffy, lalu lapor dengan format di SOUL.md.
   - Gagal → kirim ulang ke kru yang sama dengan feedback spesifik
     (apa yang salah + bukti). Maksimal 3x per task, lalu eskalasi ke Luffy.

## Routing

| Jenis task                                           | Kru    |
|------------------------------------------------------|--------|
| Tulis/ubah kode, bugfix, refactor, unit test         | Franky |
| Review diff, security, QA, cek acceptance criteria   | Zoro   |
| Naskah video, artikel, copywriting, strategi brand   | Robin  |
| Gambar, logo, poster, aset iklan, potong video       | Usopp  |
| Riset pasar, kompetitor, harga, berita, scraping     | Sanji  |
| Lisensi, Terms of Service, regulasi, risiko bisnis   | Jinbe  |

Alur standar perubahan kode: **Franky → Zoro**. Kode belum dianggap selesai
sebelum Zoro memberi status SUCCESS.

## Verification Gate

Untuk setiap hasil yang kembali:

1. Output harus JSON valid sesuai schema (`schema_valid` untuk delegate_task; cek manual untuk run-crew.sh). Tidak valid = gagal, kirim ulang.
2. `status` harus `SUCCESS`. `BLOCKED` → baca `blockers`; kalau butuh keputusan Luffy, tanya Luffy.
3. Cek semua artifact benar-benar ada dan tidak kosong:
   ```bash
   bash ${HERMES_SKILL_DIR}/scripts/verify-artifact.sh --root ~/Projects/<project> <path1> <path2> ...
   ```
4. Jalankan ulang perintah di VERIFICATION CRITERIA **sendiri**. Jangan hanya
   percaya teks `verification` dari kru.
5. Untuk task engineering, cek `git -C <repo> status --short` dan `git diff --stat`:
   - File yang berubah di luar TARGET PATH → gagal.
   - Zoro (read-only) ternyata mengubah kode → gagal, kembalikan perubahan dan laporkan.

Baru setelah semua lolos, task boleh ditandai selesai.

## Siklus fix-review (kode)
Untuk perbaikan hasil review: Franky fix (Task Card: baca laporan Zoro, hanya severity yang diminta, **jangan commit/push**) → Nami verifikasi sendiri (`git diff --stat`, `php -l`/lint, `route:list`, cek dampak ke sisi lain, mis. FE memakai field yang diubah BE) → Zoro review ulang diff **yang belum di-commit** (Task Card menyebut itu) → hanya PASS: Nami commit + push. Merge/MR request dibuat Luffy sendiri. FAIL: kirim balik ke Franky, maks 3x. Repo berbeda (BE vs FE) boleh jalan paralel; repo sama jangan.

Review branch lokal yang sudah di-commit tapi belum di-push: Zoro review `git diff origin/<base>...<branch>` di repo utama (read-only). FAIL → cocokkan tiap temuan high ke kode (`git show origin/<base>:<file>`) dulu, lalu worktree fix dari branch itu (`git worktree add -b <branch>-fix ~/Projects/<project>/worktree/<nama> <branch>`) supaya repo utama tetap bersih. PASS ulang → commit di worktree, `git merge --ff-only <branch>-fix` di branch asli, push, hapus worktree + branch fix. Simpan kedua laporan Zoro (awal + ulang) ke `research/`.

Task read-only paralel (inventaris/scan oleh Franky, review oleh Zoro) boleh jalan bersamaan di repo yang sama selama tidak ada yang menulis ke repo; simpan `git status --porcelain` baseline di `scratch/` sebelum launch.

Verifikasi deliverable berbentuk tabel besar (inventaris file:baris): parse baris tabel dengan Python, cocokkan total per kategori dengan ringkasan, dan buka setiap `file:baris` di repo untuk memastikan konstruksi yang disebut memang ada di baris itu. Regex baris harus menerima penanda tebal (`| **P1** ...`), kalau tidak baris prioritas tidak terhitung dan totalnya tampak tidak cocok.

## Pitfalls
- **Franky/Zoro = profile Hermes; Robin/Usopp/Sanji/Jinbe = subagent (file persona saja, tanpa memori/config).** Hasil bisa beda antar jalan, jadi aturan gaya & konvensi repo ditulis di `context.md`/`AGENTS.md` project, bukan diharap diingat kru. Pembuatan/ubah profile: `references/crew-profiles.md`.
- **`run-crew.sh` untuk review/kode besar lewat 10 menit**: jalan sebagai proses latar dengan `persist_on_release=true` (batas foreground 600 dtk). Tanpa persist, proses latar kena `SIGTERM` (exit -15) saat sesi di-interupsi/compact, sisakan log 0-byte dan `git status` bersih — seolah kru belum jalan padahal cuma ke-kill. Arahkan stdout/stderr ke file di `scratch/`, tunggu notifikasi selesai, lalu parse blok ```json terakhir. Exit 3 = repo berubah; cek `git status` repo asli dulu sebelum menuduh Zoro (alarm palsu muncul bila path relatif). Deteksi ke-kill: log kosong + `git status` bersih + exit -15 = proses mati sebelum menulis apa pun; re-run dengan `persist_on_release=true`, jangan mengira kru selesai.
- **Kru exit cepat (exit 1, tanpa JSON)**: grep log untuk `Provider said` / `HTTP 4xx/5xx` sebelum menyalahkan task-nya. Penyebab umumnya semua entri combo `coding` mati (token OAuth kedaluwarsa, kuota/saldo habis). Tes PONG tiap entri combo satu per satu (resep di skill `9router`; balasan streaming `data: {...chat.completion.chunk...}` = sukses, bukan error parse), laporkan tabel status per entri ke Luffy. Jangan ganti model profile atau mengalihkan kerja ke subagent sendiri: Luffy memilih tetap pakai combo `coding` dan memperbaiki akunnya. Setelah dia bilang beres, PONG ulang lalu re-run (log lama di-rename `*.failN.log`).
- **Kru exit 130 (SIGINT) dan tool terminal Nami sendiri ikut balas 130 / "orphan recovery"**: itu interupsi dari sesi/Luffy, bukan error perintah. Berhenti mencoba setelah 2x gagal, laporkan apa yang sudah terlihat + daftar sisa yang belum dicek (proses `serve` yang masih jalan, file token/kredensial yang ditulis kru, `git status` vs baseline, data uji yang tertinggal), lalu tanya Luffy mau lanjut atau tidak. Kalau lanjut: bereskan sisa itu dulu, baru re-run.
- **Luffy tanya "proses apa yang jalan / bisa lanjut?" saat kru masih jalan**: jawab dari disk, bukan tebakan. Cek `ps -p <pid> -o etime`, anak proses (`pgrep -P`), `ls -lt` output terbaru, diff file vs backup, dan hitungan di DB, lalu laporkan tabel tahap (selesai / sedang / belum). Kondisi sementara yang wajar (mis. view 0 setelah DROP DATABASE) dijelaskan supaya tidak dikira rusak. `run-crew.sh` di folder non-git mencetak bantuan `git diff` ke log; itu noise, bukan error.
- **Output Franky/Zoro dari `run-crew.sh` tidak selalu satu blok ```json bersih** (bisa ada log diff/tool di depan, dan JSON bisa pretty-printed `{\n  "agent"` sehingga `rfind('{"agent"')` meleset). Cari `i = s.rfind('"agent"')`, lalu `s.rfind('{', 0, i)` sampai sebelum `session_id:`, buang ``` sisa, `json.loads`, lalu simpan `summary` Zoro ke `research/` (Zoro tidak menulis file). Task Card Franky/Zoro wajib menyebut batas severity dan larangan commit supaya scope tidak melebar.
- **Verifikasi Nami mencakup seluruh sistem, bukan cuma scope kru**: kru melapor "semua cocok" hanya untuk bagian yang dia sentuh (mis. 8 dari 10 DB), padahal bagian lain bisa sudah rusak/kosong sejak sebelumnya. Cek ulang semua (mis. row count seluruh DB) sebelum menandai selesai.
- **Klaim `verification` kru bukan bukti**: jalankan ulang `php -l`/`route:list`/`git status` sendiri. Catatan kru soal hal yang tidak teruji (DB mati, eslint gagal) diteruskan jujur ke Luffy.
- **Baca temuan/asumsi di `summary` kru sebelum lanjut review**: SUCCESS bisa untuk target yang salah (mis. model yang dipakai ternyata memetakan tabel lain, atau mekanisme yang tak pernah terpanggil). Cek asumsi itu ke source (DB/kode) dulu; kalau scope ternyata berubah, bawa ke Luffy sebelum kirim ke Zoro.
- **Task data/DB di luar repo git** (mis. converter + import di `scratch/`): `run-crew.sh` tetap jalan untuk Franky (cek git jadi no-op). Sebelum launch, Nami simpan baseline sendiri (jumlah tabel/view, backup file yang akan diubah) di `scratch/`, supaya verifikasi punya pembanding sebelum-sesudah.
- **Luffy membatalkan task yang sudah/sedang dikerjakan kru**: hentikan prosesnya, hapus worktree + branch-nya (`git worktree remove --force` lalu `git branch -D`), simpan bahan sumber yang berguna sebagai referensi serah-terima, tandai di `progress.md` sebagai dilewati (alasan + siapa yang nanti mengerjakan). Jangan biarkan artefak setengah jadi tanpa status.
- **Edit persona kru = dua salinan**: ubah `references/crew/<kru>.md` lalu `cp` ke `~/.hermes/profiles/<kru>/SOUL.md` (untuk Franky/Zoro); cek `diff -q`. Kalau tidak, profile jalan dengan persona lama.
- **Pertanyaan "siapa yang mengerjakan X"**: tidak ada alat pencari riwayat sesi. Jawab dari `progress.md` (entri `[x] Kru: ...`) + header dokumen (`Penulis:`) di `research/` project, dan sebut bahwa itu inferensi dari file.
- **Subagent tidak tahu apa-apa** selain `goal` + `context`. Jangan menulis
  "file tadi" atau "seperti yang dibahas". Tulis path dan isi yang dibutuhkan.
- **Subagent (Robin/Usopp/Sanji/Jinbe) mewarisi toolset Nami.** Batasan hanya dari persona; audit hasil (langkah 3–5).
- **Franky/Zoro punya model/tool/memori sendiri** (profile). Zoro read-only hanya lewat persona + cek git; terminal masih bisa menulis secara teknis.
- Jangan kirim dua Franky paralel ke repo yang sama tanpa
  `delegation.worktree_isolation: true` di `~/.hermes/profiles/franky/config.yaml` (subagent Franky sendiri; `max_concurrent_children` dibiarkan bawaan 10 sesuai Luffy). Ubah config profile hanya saat tidak ada Franky yang sedang jalan.
- Jangan masukkan seluruh isi file besar ke `context`. Beri path-nya, kru bisa membacanya sendiri.
- Kru tidak bisa bertanya ke Luffy (`clarify` diblokir). Kalau Task Card ambigu,
  perjelas dulu sebelum delegasi.
