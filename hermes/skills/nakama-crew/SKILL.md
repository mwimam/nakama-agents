---
name: nakama-crew
description: Orkestrasi kru Nakama oleh Nami. Delegasikan task ke Franky, Zoro, Robin, Usopp, Sanji, Jinbe via delegate_task memakai Task Card, persona kru, dan output_schema, lalu verifikasi hasilnya di disk. Gunakan setiap kali Luffy memanggil Nami untuk task engineering, kreatif, riset, QA, compliance, atau intake modul baru.
version: 1.1.0
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
   - Project ada di `~/Projects/<project>/` (bukan `~/Documents/`). Repo legacy
     boleh di-symlink ke `engineering/`. Baca `context.md`, `progress.md`, dan
     `AGENTS.md` repo engineering.
   - Catat bagian **"Aturan Proyek"** di `context.md`. Aturan itu wajib ikut ke
     setiap Task Card project ini (langkah 4).
   - Project baru → buat struktur folder sesuai README (bagian 4), salin
     `${HERMES_SKILL_DIR}/templates/context.md` dan
     `${HERMES_SKILL_DIR}/templates/progress.md` ke root project.
   - Permintaan ad-hoc → pakai `~/Projects/_scratch/` (buat jika belum ada).

2. **Pecah jadi Task Card.**
   - Pakai format `${HERMES_SKILL_DIR}/templates/task-card.md`. Satu card = satu kru = satu hasil.
   - Task yang butuh output task lain dikirim **setelah** task itu selesai dan lolos verifikasi.
   - Task yang tidak saling bergantung boleh dikirim paralel dalam satu `tasks=[...]`.

3. **Pilih kru** (tabel Routing) dan baca personanya:
   `${HERMES_SKILL_DIR}/references/crew/<kru>.md`.

4. **Panggil `delegate_task`** untuk setiap card:
   - `goal`: baris PROBLEM / OBJECTIVE dari Task Card.
   - `context`, susun dengan urutan ini:
     1. Isi lengkap file persona kru.
     2. Task Card lengkap.
     3. Bagian "Aturan Proyek" dari `context.md` (utuh) + ringkasan bagian lain yang relevan.
     4. Untuk Franky/Zoro: isi `AGENTS.md` dari folder `engineering/` project.
     5. Path absolut root project dan path file input yang perlu dibaca.
   - `output_schema`: isi `${HERMES_SKILL_DIR}/templates/output-schema.json`.

5. **Verification Gate** (lihat bagian di bawah). Jangan lewati.

6. **Tutup task.**
   - Lolos → update `progress.md` **dengan patch** (jangan overwrite; Luffy/agent lain
     juga menulis di sana, dan `write_file` ke file yang sudah ada akan ditolak
     kalau belum di-read), salin hasil final ke `deliverables/` jika
     memang deliverable untuk Luffy, lalu lapor dengan format di SOUL.md.
   - Gagal → kirim ulang ke kru yang sama dengan feedback spesifik
     (apa yang salah + bukti). Maksimal 3x per task, lalu eskalasi ke Luffy.

## Aturan Tetap Luffy

Berlaku di semua project, kecuali "Aturan Proyek" di `context.md` menyatakan lain.

- **Flowchart = kebenaran proses bisnis.** Jika flowchart dan Figma/mockup
  bertentangan: flowchart menang untuk logika bisnis (approval, transisi status,
  aktor), Figma menang untuk tampilan UI (kolom, tombol, layout). Catat perbedaan
  di spec dengan label jelas, bukan sebagai pertanyaan terbuka.
- **Modul baru FE+BE:** ikuti `${HERMES_SKILL_DIR}/references/workflows/module-intake.md`.
  FE = slicing pakai komponen yang sudah ada; komponen yang belum ada dibuat
  **plan dulu**. BE = riset + spec + technical design dulu, belum koding.
  Eksekusi kode baru setelah Luffy menyetujui.
- **Aturan khusus project** (berlaku hanya di satu project) ditulis ke `context.md`
  atau `AGENTS.md` project itu, **bukan** ke skill ini dan bukan sebagai skill global baru.

## Routing

| Jenis task                                           | Kru    |
|------------------------------------------------------|--------|
| Tulis/ubah kode, bugfix, refactor, unit test         | Franky |
| Review diff, security, QA, cek acceptance criteria   | Zoro   |
| Naskah video, artikel, copywriting, strategi brand   | Robin  |
| Gambar, logo, poster, aset iklan, potong video       | Usopp  |
| Riset pasar, kompetitor, harga, berita, scraping     | Sanji  |
| Lisensi, Terms of Service, regulasi, risiko bisnis   | Jinbe  |
| Intake modul baru FE+BE dari dokumen SA              | Lihat `references/workflows/module-intake.md` |

Alur standar perubahan kode: **Franky → Zoro**. Kode belum dianggap selesai
sebelum Zoro memberi verdict `APPROVE` (status `SUCCESS`). Verdict
`REQUEST CHANGES` → kirim temuan Zoro ke Franky sebagai Task Card perbaikan.

## Verification Gate

Untuk setiap hasil yang kembali:

1. `schema_valid` harus `true`. Jika `false`, ambil info dari `summary` mentah,
   lalu anggap sebagai gagal dan kirim ulang.
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

## Pitfalls
- **Subagent tidak tahu apa-apa** selain `goal` + `context`. Jangan menulis
  "file tadi" atau "seperti yang dibahas". Tulis path dan isi yang dibutuhkan.
- **Semua kru mewarisi toolset Nami.** Batasan tool hanya dari persona, jadi
  selalu audit hasil (langkah 3–5 verifikasi).
- **Semua kru memakai model yang sama** (`delegation.model`). Untuk task yang
  butuh model lebih kuat, beri tahu Luffy daripada memaksakan.
- Jangan kirim dua Franky paralel ke repo yang sama tanpa
  `delegation.worktree_isolation: true`.
- Jangan masukkan seluruh isi file besar ke `context`. Beri path-nya, kru bisa membacanya sendiri.
- Kru tidak bisa bertanya ke Luffy (`clarify` diblokir). Kalau Task Card ambigu,
  perjelas dulu sebelum delegasi. Kru yang butuh input Luffy (mis. Sanji kena
  CAPTCHA) akan kembali dengan `BLOCKED` — Nami yang meneruskan pertanyaannya.
- Subagent yang riset terlalu lama tanpa menulis file (>15 menit) → steer dengan
  deadline eksplisit. Cek dulu subagent masih hidup sebelum steer.
