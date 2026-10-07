# Autonomous Multi-Agent Workspace Architecture (Nakama Agent System)

Arsitektur orkestrasi multi-agent lokal berbasis peran (role-based) dengan antarmuka tunggal (Single-Gateway Interface) via Telegram. Dirancang untuk efisiensi komputasi, pemisahan dependensi (context isolation), keandalan deterministik via Task Card, dan pemeliharaan minimal (low-maintenance operations).

---

## 1. Executive Summary & Design Philosophy

Menggabungkan seluruh keahlian dalam satu model/agent monolitik menyebabkan 3 kendala utama:
1. **Context Bleed**: Instruksi dan aturan kerja antar-domain bercampur (misal: gaya penulisan konten bocor ke kode program).
2. **Token Bleed**: Window konteks terbebani ratusan instruksi yang tidak relevan dengan task aktif.
3. **Operational Overhead**: Menjalankan banyak bot gateway Telegram menyebabkan pemborosan RAM, bentrok port, dan kerumitan konfigurasi.

### Prinsip Utama Sistem:
* **The Captain & Navigator Model**: User adalah **Luffy (The Captain)** yang menentukan visi, prioritas, dan keputusan final. **Nami** bertindak sebagai Navigator / Executive Coordinator yang mengelola operasional kru, memecah task, dan memvalidasi hasil kerja fisik.
* **Single Gateway Interface**: User hanya berinteraksi dengan satu Lead Coordinator (Nami) via DM Telegram.
* **One Profile, Many Roles**: Hanya Nami yang berjalan sebagai profile Hermes. Kru lain (Franky, Zoro, Robin, Usopp, Sanji, Jinbe) **bukan profile**, melainkan subagent sementara yang di-spawn Nami via `delegate_task` dengan persona yang disisipkan ke `context`.
* **On-Demand Lifecycle**: Worker agent hanya di-spawn saat ada task aktif, lalu terminasi otomatis setelah artifact fisik dihasilkan.
* **Deterministic Delegation (Task Card)**: Nami dilarang memberi perintah bebas/abstrak. Seluruh delegasi wajib menggunakan struktur Task Card berpagar ketat.
* **Project-First Partitioning & Symlink Support**: Ruang kerja diisolasi per folder project di `~/Projects/`. Proyek legacy di direktori lain diintegrasikan via symlink tanpa memindahkan source code asli.
* **Physical Verification Gate**: Task hanya berstatus selesai jika file output terverifikasi secara nyata di disk (`size > 0 bytes`) atau lolos pengecekan syntax/test (`php -l`, test runner).

---

## 2. High-Level Architecture Diagram

```text
                      +-------------------+
                      |   LUFFY (User)    |
                      |    The Captain    |
                      +-------------------+
                                |
                        (Telegram DM)
                                |
                                v
               +---------------------------------+
               |   NAMI (Executive Coordinator)  |
               |  - Hermes Profile (satu-satunya)|
               |  - Telegram Gateway             |
               |  - Task Card Decomposition      |
               |  - Verification & Reporting     |
               +---------------------------------+
                                |
                 (delegate_task, on-demand spawn)
                                |
     +-------------------+------+------------+-------------------+
     |                   |                   |                   |
     v                   v                   v                   v
+-------------+   +-------------+   +-------------+   +---------------+
| ENGINEERING |   |  CREATIVE   |   |  RESEARCH   |   |  COMPLIANCE   |
|             |   |             |   |             |   |  (Opsional)   |
+-------------+   +-------------+   +-------------+   +---------------+
| FRANKY (Dev)|   | ROBIN       |   | SANJI       |   | JINBE (Legal) |
| ZORO (QA)   |   | USOPP       |   |             |   |               |
+-------------+   +-------------+   +-------------+   +---------------+
     |                   |                   |                   |
     +-------------------+---------+---------+-------------------+
                                   |
                                   v
                   +-------------------------------+
                   |   LOCAL PROJECT WORKSPACE     |
                   |   ~/Projects/<project-name>/  |
                   |   - AGENTS.md (Local Guards)  |
                   |   - progress.md (Live Status) |
                   |   - deliverables/ (Final Aset)|
                   +-------------------------------+
```

---

## 3. Team Roster & Role Definitions

Setiap agen memiliki persona terisolasi, batasan perilaku, dan format output yang ketat.

| Agen | Departemen | Karakteristik Peran | Tanggung Jawab Utama | Batasan Perilaku (prompt-level) |
| :--- | :--- | :--- | :--- | :--- |
| **Luffy** | Executive | Kapten & Visioner | Penentu arah bisnis/produk, pemilik prioritas, pengambil keputusan final. | Natural Language (User) |
| **Nami** | Executive / PM | Navigator & Koordinator | Breakdown task ke Task Card, delegasi subagent, monitor status, kirim deliverable. | Satu-satunya profile Hermes. Pemilik toolset & gateway Telegram. |
| **Franky** | Engineering | Builder / Software Engineer | Implementasi kode, bugfix, refactoring, unit test (*YAGNI, minimal diff*). Wajib patuhi `AGENTS.md`. | Hanya ubah file di TARGET PATH; pakai terminal, patch, Git. |
| **Zoro** | Engineering / QA | Inspector & Security | Audit git diff, verifikasi acceptance criteria, security scan, review PR sebelum merge. | Read-only: baca, cari, jalankan test. Dilarang mengubah kode. |
| **Robin** | Creative | Researcher & Writer | Penulisan skrip video, naskah promosi, artikel teknis, strategi brand, value proposition. | Hanya tulis `.md` di `creative/scripts/`. |
| **Usopp** | Creative | Visual Specialist | Prompt engineering aset visual, generate gambar via Cloud/External API, video clipping. | Hanya tulis ke `creative/exports/`. |
| **Sanji** | Intelligence | Market Researcher | Web scraping, monitoring tren kompetitor, riset harga pasar mentah. | Hanya tulis ke `research/`. |
| **Jinbe** *(Opsional)*| Compliance | Legal & Administrative | Review lisensi open-source, Terms of Service, kepatuhan regulasi bisnis, risiko rencana bisnis. | Read-only; output berupa laporan `.md`. |

> **Penting — batasan tool hanya di level prompt.** `delegate_task` di Hermes tidak menerima parameter `toolsets`. Setiap subagent **mewarisi seluruh toolset Nami** (dikurangi tool yang diblokir untuk subagent: `delegate_task`, `clarify`, `memory`, `send_message`, `cronjob`). Konsekuensinya:
> * Kolom "Batasan Perilaku" di atas ditegakkan lewat persona/Task Card, **bukan** oleh runtime.
> * Tool yang dibutuhkan kru mana pun (Image API/ComfyUI untuk Usopp, browser untuk Sanji, dll.) **harus aktif di profile Nami**.

---

## 4. Multi-Tenant Directory Structure

Struktur direktori menggunakan pola **Project-Centric**. Satu mesin dapat mengelola multi-project dan project legacy dengan risiko kontaminasi data yang minimal.

```text
~/Projects/
├── _shared_templates/                 # Global SOP & Template (Read-Only)
│   ├── sop-rules.md                   # Output contract & retry budget
│   └── brand-guidelines-base.md
│
├── project-alpha/                     # Standalone New Project
│   ├── context.md                     # Domain brief, target audience, technical scope
│   ├── progress.md                    # Single Source of Truth status pengerjaan
│   ├── engineering/                   # Workspace Franky & Zoro
│   │   ├── AGENTS.md                  # Local Guardrails teknis repo
│   │   └── src/
│   ├── creative/                      # Workspace Robin & Usopp
│   │   ├── scripts/                   # Naskah artikel & video (.md)
│   │   └── exports/                   # Aset render visual (.png, .mp4)
│   ├── research/                      # Workspace Sanji
│   │   ├── raw/                       # Data scraping mentah
│   │   └── reports/                   # Ringkasan insight
│   ├── scratch/                       # Folder sementara (auto-pruned)
│   └── deliverables/                  # HASIL AKHIR (Hanya boleh ditulis oleh Nami)
│
└── project-beta/                      # Integrated Legacy Project
    ├── context.md
    ├── progress.md
    ├── engineering -> /path/to/works/legacy-repo  # Symlink ke repo asli
    │   └── AGENTS.md                  # Guardrails khusus Laravel & DB tunnel
    ├── research/
    ├── scratch/
    └── deliverables/
```

> **Soft isolation.** Isolasi folder bersifat konvensi, bukan sandbox: subagent bekerja di direktori kerja Nami dan tool file dapat mengikuti symlink keluar dari `~/Projects/`. Aturan "hanya Nami yang menulis `deliverables/`" juga ditegakkan via prompt, lalu diperiksa Nami saat verifikasi.

---

## 5. Interaction Protocols & Workflows

### A. Lifecycle Task Execution
1. **Inbound**: Luffy mengirim instruksi via DM Telegram ke Nami (berupa chat langsung atau rujukan file markdown `tasks.md`).
2. **Decomposition**: Nami membaca `context.md` project aktif, lalu menyusun Dependency Graph (DAG) menggunakan format **Task Card**.
3. **Execution**: Nami memanggil `delegate_task` dengan:
   * `goal`: objective dari Task Card.
   * `context`: persona kru + Task Card lengkap + ringkasan `context.md` + isi `AGENTS.md` yang relevan + root path project.
   * `output_schema`: skema Standard Output Contract (lihat 5.C).

   Subagent memulai **percakapan kosong** — ia tidak tahu riwayat chat, memory, maupun `context.md` kecuali yang dikirim Nami. Hermes hanya otomatis menyisipkan `AGENTS.md`/`.hermes.md` dari *workspace Nami*, bukan dari folder project target.
4. **Verification Gate**:
   * Worker wajib menyertakan path fisik output dan bukti syntax check (`php -l`, existence file > 0 bytes).
   * Nami melakukan verifikasi eksistensi fisik di disk sebelum memperbarui board status.
5. **Merge & Delivery**: Nami memperbarui `progress.md`, memindahkan file final ke `deliverables/`, dan mengirim laporan ringkas ke Telegram Luffy.

### B. The Task Card Standard (Deterministic Delegation)
Nami wajib membungkus setiap sub-task ke dalam format ini:
```markdown
[TASK CARD]
- WORKER: Franky / Zoro / Robin / Usopp / Sanji / Jinbe
- TARGET PATH: ~/Projects/<project>/<dept>/<target>
- PROBLEM / OBJECTIVE: Penjelasan objektif dan terisolasi
- CONSTRAINTS: Batasan teknis, aturan AGENTS.md, YAGNI, diff minimal
- VERIFICATION CRITERIA: Perintah verifikasi (e.g., php -l, file exists > 0 bytes)
```

### C. Standard Output Contract (Worker Response)
Kontrak output ditegakkan secara native lewat parameter `output_schema` pada `delegate_task`. Hermes memvalidasi jawaban subagent terhadap skema; jika gagal, subagent mendapat satu kesempatan koreksi, dan hasilnya membawa `schema_valid` / `schema_errors`.

```python
delegate_task(tasks=[{
    "goal": "Fix race condition in auth middleware",
    "context": "<persona Franky>\n<TASK CARD>\n<ringkasan context.md & AGENTS.md>",
    "output_schema": {
        "type": "object",
        "properties": {
            "agent":        {"type": "string"},
            "status":       {"enum": ["SUCCESS", "FAILED", "BLOCKED"]},
            "task":         {"type": "string"},
            "artifacts":    {"type": "array", "items": {"type": "string"}},
            "verification": {"type": "string"},
            "summary":      {"type": "string"},
            "blockers":     {"type": ["string", "null"]}
        },
        "required": ["agent", "status", "artifacts", "verification"]
    }
}])
```

Contoh respons valid:
```json
{
  "agent": "Franky",
  "status": "SUCCESS",
  "task": "Fix race condition in auth middleware",
  "artifacts": [
    "~/Projects/project-beta/engineering/app/Http/Middleware/Authenticate.php"
  ],
  "verification": "php -l passed; unit tests green; git diff clean",
  "summary": "Handled token expiry edge cases with minimal diff. No breaking changes.",
  "blockers": null
}
```

---

## 6. Business Creation & Ad-Hoc Missions

Sistem ini tidak terbatas pada rekayasa perangkat lunak, melainkan berfungsi sebagai agensi end-to-end:

### A. New Business Incubation Workflow
1. **Tahap 1 (Riset Pasar)**: Sanji mengikis data pasar dan menganalisis celah kompetitor -> `research/reports/market-analysis.md`.
2. **Tahap 2 (Strategi & Branding)**: Robin menyusun Value Proposition, target persona, dan copywriting -> `creative/scripts/brand-pitch.md`.
3. **Tahap 3 (Aset Visual & Promosi)**: Usopp menembak Image Generation API untuk membuat logo, poster, dan materi iklan -> `creative/exports/banner.png`.
4. **Tahap 4 (Implementasi Teknis)**: Franky membangun landing page / bot katalog pembayaran -> `engineering/src/`.
5. **Tahap 5 (Audit Kelayakan)**:
   * Zoro mengaudit sisi teknis: kualitas kode, keamanan, dan acceptance criteria hasil Tahap 4.
   * Jinbe *(opsional)* membedah risiko rencana bisnis, lisensi, dan kepatuhan regulasi.

### B. Ad-Hoc / Scratch Missions
Untuk permintaan mendadak (misal: *"Nami, cari berita teknologi hari ini"*):
* Nami langsung merutekan ke Sanji tanpa membuat folder project baru.
* Pengolahan dilakukan di memori atau direktori temporary `scratch/`.
* Hasil ringkas dilaporkan langsung di DM Telegram.

---

## 7. Edge Case Mitigations

| Skenario Masalah | Dampak | Strategi Mitigasi Arsitektur |
| :--- | :--- | :--- |
| **Infinite Loop / Token Bleed** | Biaya API bengkak, terminal hang. | Aturan perilaku Nami: retry delegasi maksimal 3x (bukan fitur Hermes, ditulis di SOP/skill Nami). Batas teknis via `delegation.max_iterations`. Perintah bawaan `/stop` menghentikan Nami beserta seluruh subagent. |
| **Cross-Project Leak** | Model memakai data Project A di Project B. | Subagent hanya menerima root path project aktif lewat `context`. Isolasi bersifat konvensi (soft isolation), diperiksa saat verifikasi. |
| **Race Condition** | File tertimpa oleh dua worker simultan. | *Single-Writer Pattern*: Worker hanya menulis file miliknya, Nami agregator tunggal. Untuk beberapa Franky paralel di repo yang sama, aktifkan `delegation.worktree_isolation`. |
| **False Completion** | Worker mengaku selesai tapi artifact kosong. | `output_schema` memaksa format laporan; Nami lalu mengecek eksistensi dan ukuran file di disk sebelum melapor. |
| **Tool Overreach** | Kru memakai tool di luar perannya (mis. Zoro mengubah kode). | Subagent mewarisi seluruh toolset Nami, jadi batasan ditegakkan via persona + Task Card, lalu diaudit Nami lewat `git diff` saat verifikasi. |

---

## 8. Deployment Stack

* **Host Platform**: macOS / Linux (Local Dedicated Machine).
* **Terminal Multiplexer**: `tmux` (untuk audit background session).
* **Agent Framework**: Hermes Agent — satu profile (Nami) + `delegate_task` untuk kru.
* **Messaging Interface**: Telegram Bot API (Single Gateway Bot).
* **Engine Integration**:
  * Code Generation: Subagent Franky (opsional memanggil Claude Code CLI via terminal).
  * Visual Generation: Cloud / External Image API via Usopp (hemat memori host 16 GB).
  * Research & Retrieval: Native Browser & Web Extract Tools via Sanji.

---

## 9. Hermes Configuration

Konfigurasi delegasi di `~/.hermes/config.yaml` milik profile Nami:

```yaml
model:
  default: "<model-frontier>"        # Nami: perencanaan & verifikasi butuh model terbaik

delegation:
  model: "<model-hemat>"             # SEMUA kru memakai model ini (kosong = ikut model Nami)
  provider: "openrouter"             # opsional; atau pakai base_url + api_key untuk endpoint lokal
  max_iterations: 80                 # batas langkah per subagent (default 250)
  max_concurrent_children: 3         # paralel maksimal (default 10); sesuaikan RAM 16 GB
  worktree_isolation: true           # tiap subagent dapat git worktree sendiri
  # max_spawn_depth: 1               # default flat: kru tidak bisa mendelegasikan lagi
```

Catatan model:
* `delegate_task` **tidak punya parameter model**. `delegation.model` berlaku global untuk semua kru — Franky, Sanji, Robin, dll. memakai model yang sama.
* Pola yang disarankan: Nami di model frontier (dekomposisi & verifikasi), kru di model hemat (eksekusi task yang sudah terdefinisi jelas via Task Card).
* Jika ada task yang butuh model lebih kuat untuk kru tertentu, gunakan fitur **kanban** Hermes yang mendukung override model per task, atau kosongkan `delegation.model` untuk sesi tersebut.
* Versi Hermes lama memiliki bug `delegation.model` diabaikan ([NousResearch/hermes-agent#12440](https://github.com/NousResearch/hermes-agent/issues/12440)); pastikan memakai versi terbaru.

Referensi: [Hermes Agent — Subagent Delegation](https://hermes-agent.nousresearch.com/docs/user-guide/features/delegation).
