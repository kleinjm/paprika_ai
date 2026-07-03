# Paprika AI Assistant

[![CI](https://github.com/kleinjm/paprika_ai/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/kleinjm/paprika_ai/actions/workflows/ci.yml)

An AI-powered assistant over your [Paprika Recipe Manager](https://www.paprikaapp.com/)
library — meal planning, recipe analysis, ingredient substitutions, and a
natural-language nutrition tracker, powered by Gemini. Rails 8, deployed on
Render + Neon.

**Live:** https://paprika-ai.onrender.com

## Documentation

- 📋 [Features](docs/features.md) — meal planning, recipe analysis, substitutions, nutrition tracking, settings
- 🏗️ [Architecture](docs/architecture.md) — Paprika cloud → Postgres mirror, the `paprika_client` gem, AI services, nutrition write-back
- ☁️ [Infrastructure](docs/infrastructure.md) — Render + Neon, single-DB Solid stack, secrets, CI-gated deploys, scheduled sync, prod console
- 💻 [Development](docs/development.md) — local setup, credentials, seeding the recipe mirror, running the app
- ✅ [Testing](docs/testing.md) — RSpec, 100% SimpleCov coverage, CI

## Quick start

```bash
bundle install
yarn install
bin/rails credentials:edit --environment development   # see Development docs
bin/rails db:prepare
bin/rails paprika:pull        # populate the recipe mirror from the Paprika cloud
bin/dev                       # http://localhost:3000
```

Full setup in [Development](docs/development.md).

## Stack

Ruby 4.0.5 · Rails 8.0 · PostgreSQL (Neon in prod) · Hotwire (Turbo + Stimulus)
· Bootstrap 5.3 · Gemini · [`paprika_client`](https://github.com/kleinjm/paprika_client)

## License

MIT
