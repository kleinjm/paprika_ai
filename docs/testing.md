# Testing

The app uses **RSpec** with **SimpleCov** enforcing **100% line coverage**.

## Running

```bash
bin/rails db:test:prepare
bundle exec rspec
```

Coverage config lives in the root **`.simplecov`** file (auto-loaded by
SimpleCov on `require`). It filters `spec/`, `config/`, `db/`, the Paprika
mirror models (`app/models/paprika/`), and the stubbed `ChatGptService`, then
sets `minimum_coverage 100`.

## Eager-load gotcha

Rails' test env sets `config.eager_load = ENV["CI"].present?`. So **CI loads all
app files** (and counts them for coverage) while a plain local run only counts
loaded files. To reproduce CI's coverage numbers locally:

```bash
CI=true bundle exec rspec
```

If coverage passes locally but fails in CI, this is almost always why — a new
file has no spec and only surfaces under eager load.

## CI (`.github/workflows/ci.yml`)

- Spins up a Postgres service, prepares the test DB, runs `bundle exec rspec` (Ruby from `.ruby-version`).
- A `deploy` job (`needs: rspec`, pushes to `main` only) triggers the Render deploy hook — so **deploys are gated on green tests**. See [Infrastructure → Deploy pipeline](infrastructure.md#deploy-pipeline-ci-gated).

## The `paprika_client` gem

The Paprika cloud client is a separate gem
([kleinjm/paprika_client](https://github.com/kleinjm/paprika_client)) with its
own suite: 100% line **and branch** coverage (Minitest + WebMock), RuboCop, CI
across Ruby 3.3/3.4/4.0, and Trusted-Publishing releases on `v*` tags.
