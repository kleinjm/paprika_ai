# Architecture

## Paprika data: cloud → local mirror

The app **mirrors** Paprika data into its own Postgres database and reads from
that mirror. Recipes originate in the Paprika apps and sync to Paprika's cloud;
we pull them down via the [`paprika_client`](https://github.com/kleinjm/paprika_client)
gem (published to RubyGems). There is **no dependency on a local SQLite file** —
the app runs anywhere, including production.

```
Paprika apps ──sync──> Paprika cloud ──paprika:pull (paprika_client)──> Postgres mirror ──> app
                              ▲                                                              │
                              └──────────── nutrition write-back (PaprikaCloud) ─────────────┘
```

- **Source of truth for recipes**: the Paprika cloud (you still edit recipes in the Paprika apps).
- **Source of truth for app data** (nutrition logs, goals, staples): Postgres (Neon in production).
- The mirror is a synced snapshot, refreshed by `paprika:pull` (see below), not live.

### Mirror schema (Core Data names preserved)

Recipe/category tables keep Paprika's Core Data names and `Z_PK` primary key so
existing references (`recipe_id` columns, params, `find_by(Z_PK:)`) keep working
unchanged. Meals use a clean table.

- `ZRECIPE` (PK `Z_PK`, `ZUID`, `ZSYNCHASH`, `ZNAME`, `ZINGREDIENTS`, `ZDIRECTIONS`, `ZNUTRITIONALINFO`, `ZINTRASH`, …)
- `ZRECIPECATEGORY` (PK `Z_PK`, `ZUID`, `ZNAME`)
- `Z_12CATEGORIES` (join: `Z_12RECIPES` ↔ `Z_13CATEGORIES`)
- `paprika_meals` (`uid`, `scheduled_date`, `recipe_uid`, `meal_type`, `name`)

Models live in `app/models/paprika/` on the primary connection. Only the models
the app uses are kept: `Recipe`, `RecipeCategory`, `Category`, `Meal`.

### Sync tasks (`lib/tasks/paprika.rake`)

- **`paprika:pull`** — pulls categories, recipes (incremental by `ZSYNCHASH`), and meals from the cloud into the mirror. Trashed recipes are dropped from the mirror (unless referenced by a staple/nutrition entry). This is what the scheduled job and manual refreshes run.
- **`paprika:seed_from_sqlite`** — one-time **dev-only** seed that copies the local Paprika desktop SQLite DB into the mirror, preserving `Z_PK` (so existing dev references stay valid). Production starts empty and is populated by `paprika:pull`.

## AI services (`app/services/`)

- **`GeminiService`** (primary) tries a chain of free models (`gemini-2.5-flash-lite` → `gemini-2.5-flash` → `gemini-3.5-flash`), advancing only on transient errors (429/500/502/503/504). `ENV["GEMINI_MODEL"]` is prepended as the preferred model.
- **`ChatGptService`** — stubbed alternative (excluded from coverage).
- **`NutritionParser`** — turns free-text logs into structured per-item macros.
- **`VerifiedNutrition`** — detects hand-verified nutrition blocks and computes eaten portions deterministically from the label.
- **`NutritionSkill`** — formats the standardized, versioned nutrition block written back to recipes.
- **`PaprikaCloud`** — thin wrapper around `paprika_client`, configured from Rails credentials (`paprika.email` / `paprika.password`).

## Nutrition write-back

When a logged item matches a recipe, the app writes a validated, standardized
nutrition block back into that recipe's nutrition field. This now goes **to the
Paprika cloud** via `PaprikaCloud.push_nutritional_info` → `paprika_client`,
which fetches the recipe, updates `nutritional_info`, recomputes the sync hash,
uploads, and notifies the apps — so the change syncs to all your devices
(unlike the old direct-SQLite write, which the desktop app could overwrite).

The block is produced by `NutritionSkill` and looks like:

```
Meal Total (AI Generated - 7/1/26)
Calories: 2400 kcal
Protein: 180 g
Carbohydrates: 120 g
Fat: 80 g
```

- **Validated, not trusted.** The LLM sanity-checks existing nutrition text against ingredients and recomputes when it looks wrong.
- **Whole-batch totals** (not per serving) so the tracker scales by the eaten portion/fraction.
- **Versioned header for backfill.** The header date is `NutritionSkill::VERSION_DATE`. Bumping it makes older blocks differ from current output, so each recipe is rewritten the next time it's referenced. Bump it whenever you change `NutritionSkill.format` or the computed fields.
- **Read-only toggle.** `ENV["NUTRITION_WRITEBACK"]=read_only` reads existing nutrition without writing back. Default is `read_write`. Writes are skipped when the recipe already holds the exact current block.

## Front-end

Bootstrap 5.3 + SASS pipeline (cssbundling-rails, built with Node/Yarn),
Hotwire (Turbo Streams + Stimulus), importmap for JS, PWA scaffolding.
