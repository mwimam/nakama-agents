---
name: nakama-conventions
description: Use when applying standing conventions for Nakama projects.
---

# Nakama Project Conventions & Engineering Standards

## 1. Lokasi Project Wajib
Semua project koding, pipeline, dan workspace baru WAJIB dibuat di `~/Projects/<project-name>/`, BUKAN di `~/Documents/`.

## 2. Standar Kerja Kru Engineering & QA
- **Franky (Software Engineer)**:
  - Terapkan TDD (`test-driven-development`): tulis unit test yang gagal terlebih dahulu sebelum kode implementasi.
  - Perubahan kecil dan terisolasi (`change-sizing`): target diff ~100 baris, maksimal ~300 baris per task.
  - Sederhana dan tanpa bloat (`code-simplification` / YAGNI): jangan buat abstraksi spekulatif atau boilerplate sebelum dibutuhkan.
  - UI/UX (`ui-ux-pro-max`): gunakan design tokens, palet kontras WCAG, dan spacing konsisten saat merancang antarmuka.

- **Zoro (QA & Inspector)**:
  - Audit setiap diff kerjaan Franky pada 5 sumbu (`code-review-and-quality`): Correctness, Readability, Architecture, Security, Performance.
  - Berikan verdict tegas: `APPROVE` atau `REQUEST CHANGES`. Franky dilarang merge tanpa persetujuan Zoro.

## 3. Protokol Content & Intel (Sanji & Robin)
- **E-Commerce Bot Wall Fallback**: Ketika scraping/parsing marketplace (Shopee, Tokopedia, dll.) terkena proteksi bot/login/CAPTCHA, jangan terus mengulang request; segera gunakan jalur fallback (minta input judul/data manual dari pengguna).
- **Fonetik TTS Bahasa Indonesia**: Tulis singkatan istilah asing/kapital dalam bentuk fonetik cara baca (contoh: "A-se" bukan "AC", "U-Es-Be" bukan "USB", "We-Ef-Ha" bukan "WFH") agar engine suara AI tidak salah melafalkan dalam bahasa Inggris.
