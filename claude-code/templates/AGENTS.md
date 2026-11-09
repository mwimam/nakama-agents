# AGENTS.md — <Nama Project>

Guardrail teknis untuk kru Nakama (Hermes maupun Claude Code). Simpan di `<project root>/engineering/AGENTS.md`.
Nami membaca file ini lalu menempel bagian yang relevan ke Task Card.

## Repo
| Nama | Path utama | Stack | Base branch |
|---|---|---|---|
| <be> | /abs/path/<be> | <mis. Laravel 11, PHP 8.2> | <development> |
| <fe> | /abs/path/<fe> | <mis. React, webpack> | <development> |

Ticket: <tracker + format id, mis. OpenProject `OP-<id>`>. Branch: `<feat|fix>/<ticket>-<slug>`.

## Worktree
Lokasi: `<project root>/worktree/<repo>-<slug>`.
```bash
git -C <REPO> fetch origin <base>
git -C <REPO> worktree add -b <branch> <WORKTREE> origin/<base>
git -C <WORKTREE> branch --unset-upstream
# BE (PHP): salin vendor, JANGAN symlink
cp -Rc <REPO>/vendor <WORKTREE>/vendor && cp <REPO>/.env <WORKTREE>/.env
# FE (Node)
cp -Rc <REPO>/node_modules <WORKTREE>/node_modules && cp <REPO>/.env <WORKTREE>/.env
```

## Verifikasi
- BE: `php -l <file>`, `php artisan route:list --path=<prefix>`
- FE: `npx eslint <file>`

## Testing
| Level | BE | FE |
|---|---|---|
| Unit | `tests/Unit/...`: `php artisan test tests/Unit/<File>Test.php` | `src/**/__tests__/*.test.js`: `npx jest <path>` |
| Integration | `tests/Feature/...` (HTTP → DB): `php artisan test --filter=<Test>` | <komponen + API mock, jika ada polanya> |
| E2E | lihat bagian E2E | lihat bagian E2E |

- DB untuk test: <mis. SQLite in-memory / DB test terpisah>, beserta contoh test yang bisa ditiru: <path>
- Hal yang di-fake: <Mail, Queue, Http, Storage, layanan eksternal>

## E2E
Franky dan Zoro menjalankan app dari worktree (bukan container atau checkout utama) di PORT yang diberikan Nami.
```bash
# BE (contoh Laravel): .env worktree diarahkan ke DB lokal yang bisa diakses dari host
php artisan serve --port=<BE_PORT>
# FE (contoh webpack): arahkan API ke BE worktree
REACT_APP_API_URL=http://localhost:<BE_PORT>/api/ npx webpack serve --mode development --port <FE_PORT>
```
- Login E2E: <endpoint login + cara mendapatkan token>, akun test: <di mana kredensialnya disimpan>
- Data test: prefix `E2E-`. Perintah DB destruktif dilarang.
- UI: Claude in Chrome, tab baru.

## Aturan commit dan MR
- Gaya pesan: `<type>(<scope>): <deskripsi> [<ticket>]`
- <mis. tanpa trailer Co-Authored-By; deskripsi MR tanpa baris "Generated with ...">
- Push dan MR hanya oleh Luffy (atau setelah izin eksplisit).

## Fakta lingkungan
- <mis. host/port layanan dev, nilai konfigurasi yang sering salah>

## File sensitif (jangan dibaca tanpa diminta)
- <daftar path kredensial / backup / token>
