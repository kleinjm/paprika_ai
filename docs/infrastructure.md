# Infrastructure

Production runs on free tiers: **Render** (web) + **Neon** (Postgres). Live at
https://paprika-ai.onrender.com.

## Topology

| Component | Role | Runs Rails? |
|---|---|---|
| **Render** | Web service (Docker container) serving the app | ✅ |
| **Neon** | Managed Postgres — the production database | ❌ (data only) |
| **GitHub Actions** | CI (tests) + gated deploy + scheduled recipe sync | ✅ (ephemeral) |
| **Paprika cloud** | Source of truth for recipes (via `paprika_client`) | — |

Neon is *only* Postgres — it never runs Rails. Any Rails process with the right
`DATABASE_URL` (Render's container, CI, or your laptop) can talk to it.

## Web service (Render)

- **Docker runtime** (not Render's native Ruby) — the app is on Ruby 4.0.5, pinned in the `Dockerfile`. The Dockerfile installs Node + Yarn so `assets:precompile` can build the Bootstrap CSS (cssbundling).
- The container entrypoint runs `db:prepare` on boot, so **migrations apply automatically on deploy**.
- `plan: free`, health check at `/up`. Config is documented in `render.yaml`.
- Host allowlist: `config.hosts` accepts `RENDER_EXTERNAL_HOSTNAME` (and optional `APP_HOST`); `/up` is excluded from host checks.

## Database (single Postgres)

Production uses **one** database (`config/database.yml` `production:` reads
`DATABASE_URL`). Rails' default multi-database Solid stack is consolidated into
that single DB:

- Solid Cache / Queue / Cable tables are created by the `InstallSolidLibraries` migration (Rails normally ships them as separate-database schema files, which don't fit one free-tier DB).
- **Do not** set `SOLID_QUEUE_IN_PUMA` unless there are background jobs — with no jobs, the in-Puma queue supervisor exits and takes Puma down (crash loop). Add a separate Render worker if/when jobs are needed.

## Secrets & environment

**Render env vars:**
- `RAILS_MASTER_KEY` — contents of `config/credentials/production.key` (decrypts `production.yml.enc`, which holds Gemini + Paprika creds). Must be the exact 32-char value.
- `DATABASE_URL` — Neon connection string.

**GitHub Actions secrets:**
- `RAILS_MASTER_KEY`, `DATABASE_URL` — for the scheduled `paprika:pull`.
- `RENDER_DEPLOY_HOOK` — the Render deploy hook URL (see below).

The DB connection string belongs in the environment (Render env var / GitHub
secret), **never** in the repo or Rails credentials.

## Deploy pipeline (CI-gated)

Render **auto-deploy is disabled**; deploys are triggered by CI only on green:

1. Push to `main` → GitHub Actions `ci.yml` runs `rspec`.
2. On success, the `deploy` job (`needs: rspec`, push-to-main only) `POST`s the `RENDER_DEPLOY_HOOK`.
3. Render builds the Docker image and deploys; boot runs `db:prepare`.

A red build never ships. (Every push to `main` therefore redeploys on green —
be deliberate.)

## Scheduled recipe sync

`.github/workflows/paprika_pull.yml` runs `paprika:pull` daily (08:17 UTC) and
on manual dispatch, against Neon in `RAILS_ENV=production`. Trigger manually:

```bash
gh workflow run paprika_pull.yml
```

## Production console

Render's SSH/Shell is paid-tier only, so use a **local console against Neon**:

```bash
export NEON_DATABASE_URL="postgresql://…neon.tech/neondb?sslmode=require"
bin/prod-console            # rails console on prod data
bin/prod-console dbconsole  # psql into Neon
```

This is Rails running on your machine (your local code) against the production
database — not a console inside the Render container.
