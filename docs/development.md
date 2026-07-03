# Development

## Requirements
- Ruby 4.0.5 (see `.ruby-version`)
- Rails 8.0
- PostgreSQL
- Node + Yarn (for the CSS build)

## Setup

```bash
bundle install
yarn install
bin/rails db:prepare      # create + migrate + seed the dev database
```

### Credentials

Secrets live in Rails' encrypted **development** credentials (not `.env`):

```bash
bin/rails credentials:edit --environment development
```

```yaml
user:                 # seeded local login (db/seeds/users.seeds.rb)
  email:
  password:
paprika:              # Paprika cloud sync account (used by paprika:pull + write-back)
  email:
  password:
google:
  gemini:
    api_key:          # required for Gemini AI features
openai:
  chat_gpt:
    api_key:          # optional
```

This writes `config/credentials/development.yml.enc` + `development.key` (the
`.key` is git-ignored — share it out-of-band).

### Non-secret toggles (env vars)
- `GEMINI_MODEL` — preferred model, tried before the fallback chain.
- `NUTRITION_WRITEBACK` — `read_write` (default) or `read_only`.

## Seed the recipe mirror (dev)

Two options to populate `Paprika::Recipe` etc. locally:

```bash
bin/rails paprika:pull            # pull from the Paprika cloud (needs paprika creds)
# or, one-time, from the local Paprika desktop SQLite DB (preserves Z_PK):
bin/rails paprika:seed_from_sqlite
```

`paprika:seed_from_sqlite` reads the desktop DB at `PAPRIKA_DATABASE_PATH`
(defaults to the macOS Paprika container path).

## Run

```bash
bin/dev                   # Rails + CSS watch (foreman)
# or
bin/rails server
```

Visit http://localhost:3000.

## Seeds

Seeds are organized with seedbank:
- `db/seeds/*.seeds.rb` run in **all** environments — e.g. `users.seeds.rb` (idempotent user + goals). This is what production's `db:seed` runs.
- `db/seeds/development/*.seeds.rb` run in **development only** — e.g. `nutrition_entries.seeds.rb` (demo data).

```bash
bin/rails db:seed                      # common + current-env seeds
bin/rails db:seed:users                # a single group
```

## Production console

See [Infrastructure → Production console](infrastructure.md#production-console)
(`bin/prod-console`).
