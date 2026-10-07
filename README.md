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
* **On-Demand Lifecycle**: Worker agent hanya di-spawn saat ada task aktif, lalu terminasi otomatis setelah artifact fisik dihasilkan.
* **Deterministic Delegation (Task Card)**: Nami dilarang memberi perintah bebas/abstrak. Seluruh delegasi wajib menggunakan struktur Task Card berpagar ketat.
* **Project-First Partitioning & Symlink Support**: Ruang kerja diisolasi per folder project di `~/Projects/`. Proyek legacy di direktori lain diintegrasikan via symlink aman tanpa memindahkan source code asli.
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
               |  - Telegram Gateway (Hermes)    |
               |  - Task Card Decomposition      |
               |  - Verification & Reporting     |
               +---------------------------------+
                                |
        +-----------------------+-----------------------+
        |                       |                       |
 (On-Demand Spawn)       (On-Demand Spawn)       (On-Demand Spawn)
        |                       |                       |
        v                       v                       v
+---------------+       +---------------+       +---------------+
|  ENGINEERING  |       |   CREATIVE    |       |   RESEARCH    |
|   DEPARTMENT  |       |  DEPARTMENT   |       |  DEPARTMENT   |
+---------------+       +---------------+       +---------------+
| FRANKY (Dev)  |       | ROBIN (Writer)|       | SANJI (Intel) |
| ZORO (QA/Sec) |       | USOPP (Visual)|       |               |
+---------------+       +---------------+       +---------------+
        |                       |                       |
        +-----------------------+-----------------------+
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

Setiap agen memiliki persona terisolasi, batasan alat (tool boundaries), dan format output yang ketat.

| Agen | Departemen | Karakteristik Peran | Tanggung Jawab Utama | Toolset Kunci |
| :--- | :--- | :--- | :--- | :--- |
| **Luffy** | Executive | Kapten & Visioner | Penentu arah bisnis/produk, pemilik prioritas, pengambil keputusan final. | Natural Language (User) |
| **Nami** | Executive / PM | Navigator & Koordinator | Breakdown task ke Task Card, delegasi subagent, monitor status, kirim deliverable. | `delegate_task`, `read_file`, `write_file`, Telegram API |
| **Franky** | Engineering | Builder / Software Engineer | Implementasi kode, bugfix, refactoring, unit test (*YAGNI, minimal diff*). Wajib patuhi `AGENTS.md`. | `terminal`, `patch`, `read_file`, `write_file`, Git |
| **Zoro** | Engineering / QA | Inspector & Security | Audit git diff, verifikasi acceptance criteria, security scan, review PR sebelum merge. | `read_file`, `search_files`, test runner |
| **Robin** | Creative | Researcher & Writer | Penulisan skrip video, naskah promosi, artikel teknis, strategi brand, value proposition. | Web extract, markdown formatter |
| **Usopp** | Creative | Visual Specialist | Prompt engineering aset visual, generate gambar via Cloud/External API, video clipping. | Image API, ComfyUI, CLI media |
| **Sanji** | Intelligence | Market Researcher | Web scraping, monitoring tren kompetitor, riset harga pasar mentah. | `web_search`, `web_extract`, browser automation |
| **Jinbe** *(Opsional)*| Compliance | Legal & Administrative | Review lisensi open-source, Terms of Service, kepatuhan regulasi bisnis. | Document analyzer |

---

## 4. Multi-Tenant Directory Structure

Struktur direktori menggunakan pola **Project-Centric**. Satu mesin dapat mengelola multi-project dan project legacy tanpa risiko kontaminasi data.

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
    ├── engineering -> /path/to/works/legacy-repo  # Symlink aman ke repo asli
    │   └── AGENTS.md                  # Guardrails khusus Laravel & DB tunnel
    ├── research/
    ├── scratch/
    └── deliverables/
```

---

## 5. Interaction Protocols & Workflows

### A. Lifecycle Task Execution
1. **Inbound**: Luffy mengirim instruksi via DM Telegram ke Nami (berupa chat langsung atau rujukan file markdown `tasks.md`).
2. **Decomposition**: Nami membaca `context.md` project aktif, lalu menyusun Dependency Graph (DAG) menggunakan format **Task Card**.
3. **Execution**: Nami memanggil subagent dengan konteks minimal dan batasan folder kerja.
4. **Verification Gate**:
   * Worker wajib menyertakan path fisik output dan bukti syntax check (`php -l`, existence file > 0 bytes).
   * Nami melakukan verifikasi eksistensi fisik di disk sebelum memperbarui board status.
5. **Merge & Delivery**: Nami memperbarui `progress.md`, memindahkan file final ke `deliverables/`, dan mengirim laporan ringkas ke Telegram Luffy.

### B. The Task Card Standard (Deterministic Delegation)
Nami wajib membungkus setiap sub-task ke dalam format ini:
```markdown
[TASK CARD]
- WORKER: Franky / Robin / Usopp / Sanji / Zoro
- TARGET PATH: ~/Projects/<project>/<dept>/<target>
- PROBLEM / OBJECTIVE: Penjelasan objektif dan terisolasi
- CONSTRAINTS: Batasan teknis, aturan AGENTS.md, YAGNI, diff minimal
- VERIFICATION CRITERIA: Perintah verifikasi (e.g., php -l, file exists > 0 bytes)
```

### C. Standard Output Contract (Worker Response)
Semua subagent wajib mengembalikan laporan dalam format terstruktur:
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
5. **Tahap 5 (Audit Kelayakan)**: Zoro membedah kelemahan rencana bisnis dan potensi risiko.

### B. Ad-Hoc / Scratch Missions
Untuk permintaan mendadak (misal: *"Nami, cari berita teknologi hari ini"*):
* Nami langsung merutekan ke Sanji tanpa membuat folder project baru.
* Pengolahan dilakukan di memori atau direktori temporary `scratch/`.
* Hasil ringkas dilaporkan langsung di DM Telegram.

---

## 7. Edge Case Mitigations

| Skenario Masalah | Dampak | Strategi Mitigasi Arsitektur |
| :--- | :--- | :--- |
| **Infinite Loop / Token Bleed** | Biaya API bengkak, terminal hang. | Batas delegasi retry maksimal 3x. Perintah darurat `/stop` di Nami. |
| **Cross-Project Leak** | Model memakai data Project A di Project B. | Isolasi direktori ketat. Subagent hanya menerima root path project aktif. |
| **Race Condition** | File tertimpa oleh dua worker simultan. | *Single-Writer Pattern*: Worker hanya menulis file miliknya. Nami bertindak sebagai agregator tunggal. |
| **False Completion** | Worker mengaku selesai tapi artifact kosong. | Verifikasi deterministik: Nami mengecek eksistensi dan ukuran file di disk sebelum melapor. |

---

## 8. Deployment Stack

* **Host Platform**: macOS / Linux (Local Dedicated Machine).
* **Terminal Multiplexer**: `tmux` (untuk audit background session).
* **Agent Framework**: Hermes Agent + Skill Orchestration Engine.
* **Messaging Interface**: Telegram Bot API (Single Gateway Bot).
* **Engine Integration**:
  * Code Generation: Local Subagent / Claude Code CLI via Franky.
  * Visual Generation: Cloud / External Image API via Usopp (hemat memori host 16 GB).
  * Research & Retrieval: Native Browser & Web Extract Tools via Sanji.
