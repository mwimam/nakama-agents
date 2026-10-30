# Intake Modul Baru (FE slicing + BE spec) dari Dokumen SA

Dipakai saat Luffy bilang "kita masuk project X, modul Y" dengan FE + BE, plus blueprint SA / link Figma.

**Aturan tetap:** belum ada kode yang ditulis di alur ini. Hasilnya plan FE, spec BE, dan
technical design. Koding baru dimulai setelah Luffy menyetujui plan.

## Layout project yang umum
`~/Projects/<project>/`: `context.md`, `progress.md`, `engineering/` (symlink ke repo asli, berisi repo `*-fe` dan `*-be`), `doc_from_sa/` (blueprint PDF), `dump_db/` (SQL dump), `env/` (be.env, fe.env — jangan cetak nilainya), `research/`, `scratch/`, `deliverables/`.
Cek cepat: `git -C <repo> branch --show-current` + `git log --oneline -3` + `git status --short` untuk tiap repo.

## Langkah
1. **Ambil sumber desain.**
   - Figma butuh login. Browser otomatis kena 403 CloudFront. Jangan coba ulang. Langsung minta Luffy pilih: export PNG manual, atau **Figma personal access token** (rekomendasi).
   - **Figma token workflow:** Luffy buat token di figma.com/settings → Personal access tokens, scope `file_content:read` saja. Simpan di `figma_access_token.md` di root project (chmod 600, bukan di repo git, jangan pernah dicetak ke chat/log). Verifikasi: `GET https://api.figma.com/v1/me` dengan header `X-FIGMA-TOKEN`. Lalu ambil node: `GET /v1/files/{key}/nodes?ids={node-ids}` → extract frame list → export PNG per frame via `GET /v1/images/{key}?ids={frame-id}&format=png&scale=2`. Simpan ke `research/figma/`. Buat `frames-text.md` (teks per frame dari node tree) sebagai konteks teks untuk subagent.
   - Sementara token belum ada, pakai mockup dari blueprint PDF. Setelah token ada, Figma jadi acuan utama UI.
2. **Ekstrak blueprint PDF** (sering >50MB, jadi read_file menolak):
   ```bash
   python3 -m venv scratch/.venv && scratch/.venv/bin/pip -q install pymupdf
   # dump teks semua halaman dengan marker '=== PAGE N ===' ke scratch/blueprint.txt, print get_toc()
   # render halaman modul jadi PNG: page.get_pixmap(dpi=110).save('research/mockup/pNNN.png')
   ```
   - Pakai TOC untuk cari rentang halaman modul (flowchart, tabel penjelasan, mockup). Nomor halaman TOC = nomor halaman PDF (1-based).
   - Judul tiap mockup ada di teks halaman (`awk '/=== PAGE N ===/,/=== PAGE N+1 ===/'`); pakai itu untuk peta screen → halaman sebelum vision.
   - Baca PNG mockup dengan vision_analyze (minta label persis: kolom, field, tombol, status). Mockup kecil → label badge sering tak terbaca; tandai (?) dan masukkan ke pertanyaan untuk SA.
   - Untuk flowchart: render dpi=220 (bukan 110) agar label di garis penghubung dan diamond terbaca. Flowchart swimlane sering punya garis tumpang tindih di area decision; minta vision_analyze sebutkan setiap lane, step bernomor, decision diamond dengan cabang Ya/Tidak, dan dokumen yang dihasilkan.
3. **Tulis catatan mockup** `research/<modul>-mockup-notes.md`: daftar screen bernomor (halaman PDF, kolom, field, tombol), alur status, format nomor surat, dan apa yang di luar scope. File ini jadi konteks bersama untuk semua subagent.
4. **Cek apa yang sudah ada di repo** sebelum delegasi: grep nama domain (Indonesia + Inggris, mis. `sampel|sample`) di FE `src/`, BE `app/ routes/ database/`, dan `grep -i "CREATE TABLE.*<kata>"` di dump DB. Hasilnya menentukan "dari nol" vs "extend".
5. **Delegasi paralel (read-only, tanpa ubah kode)** — satu Task Card per kru:
   - Franky (FE plan): `research/fe-<modul>-slicing-plan.md` — pola halaman existing yang mirip, mapping tiap screen → komponen existing (path), daftar komponen yang belum ada + rencana (path, props), struktur file + route + menu, strategi data mock, urutan slicing + perintah verifikasi.
   - Robin (BE spec): `research/be-<modul>-spec.md` — aktor, user story, state machine, validasi, notifikasi, pertanyaan terbuka.
   - Franky (BE technical design): `research/be-<modul>-technical-design.md` — temuan arsitektur dengan path, tabel/kolom/FK/index, endpoint method+path+request+response, reuse approval/notifikasi/upload/PDF/nomor dokumen existing, rencana test, risiko.
   - **Subagent steering:** subagent BE cenderung riset terlalu lama tanpa menulis. Kalau sudah >15 menit tanpa file output, steer dengan deadline eksplisit ("Mulai TULIS sekarang, target selesai ≤10 menit"). Steer ke subagent yang sudah selesai akan gagal ("No live subagent") — cek `action='list'` dulu.
6. **Cross-check flowchart vs Figma (WAJIB kalau blueprint punya flowchart):**
   - Render halaman flowchart ke PNG resolusi tinggi (dpi=220) dan baca dengan vision_analyze.
   - Baca tabel penjelasan flowchart dari `scratch/blueprint.txt`.
   - Tulis `research/flowchart-<modul>.md`: ringkasan per varian alur (asal data, tipe dokumen, dll), lalu tabel cek silang flowchart vs spec/Figma.
   - Hal yang biasa berbeda: ada/tidaknya approval, aktor (dept mana), otomatis vs manual, dokumen perantara. Kalau bertentangan: **flowchart menang untuk logika, Figma menang untuk UI**.
   - Update spec dan technical design langsung berdasarkan hasil cek silang, jangan biarkan sebagai pertanyaan terbuka kalau Luffy sudah bilang "flowchart yang benar".
7. **Gate:** jangan mulai menulis kode FE sampai Luffy menyetujui plan slicing. Komponen yang belum ada wajib direncanakan dulu. BE juga belum dikoding sampai spec + technical design disetujui.
