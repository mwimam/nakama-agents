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

## Pitfalls
- **Franky/Zoro = profile Hermes; Robin/Usopp/Sanji/Jinbe = subagent (file persona saja, tanpa memori/config).** Hasil bisa beda antar jalan, jadi aturan gaya & konvensi repo ditulis di `context.md`/`AGENTS.md` project, bukan diharap diingat kru. Pembuatan/ubah profile: `references/crew-profiles.md`.
- **`run-crew.sh` untuk review/kode besar lewat 10 menit**: jalan sebagai proses latar (batas foreground 600 dtk). Arahkan stdout/stderr ke file di `scratch/`, tunggu notifikasi selesai, lalu parse blok ```json terakhir. Exit 3 = repo berubah; cek `git status` repo asli dulu sebelum menuduh Zoro (alarm palsu muncul bila path relatif).
- **Output Franky/Zoro dari `run-crew.sh` tidak selalu satu blok ```json bersih** (bisa ada log diff/tool di depan). Ambil dari `rfind('{"agent"')` sampai sebelum `session_id:`, `json.loads`, lalu simpan `summary` Zoro ke `research/` (Zoro tidak menulis file). Task Card Franky/Zoro wajib menyebut batas severity dan larangan commit supaya scope tidak melebar.
- **Klaim `verification` kru bukan bukti**: jalankan ulang `php -l`/`route:list`/`git status` sendiri. Catatan kru soal hal yang tidak teruji (DB mati, eslint gagal) diteruskan jujur ke Luffy.
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
