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
# BE (PHP): salin vendor, JANGAN symlink
cp -Rc <REPO>/vendor <WORKTREE>/vendor && cp <REPO>/.env <WORKTREE>/.env
# FE (Node)
cp -Rc <REPO>/node_modules <WORKTREE>/node_modules && cp <REPO>/.env <WORKTREE>/.env
```

## Verifikasi
- BE: `php -l <file>`, `php artisan route:list --path=<prefix>`, `php artisan test --filter=<Test>`
- FE: `npx eslint <file>`

## Aturan commit dan MR
- Gaya pesan: `<type>(<scope>): <deskripsi> [<ticket>]`
- <mis. tanpa trailer Co-Authored-By; deskripsi MR tanpa baris "Generated with ...">
- Push dan MR hanya oleh Luffy (atau setelah izin eksplisit).

## Fakta lingkungan
- <mis. host/port layanan dev, nilai konfigurasi yang sering salah>

## File sensitif (jangan dibaca tanpa diminta)
- <daftar path kredensial / backup / token>
