# Features

AI-powered assistant over your Paprika Recipe Manager library. All screens
require a signed-in user (Devise).

## AI Meal Planning
- Multi-select recipe categories from your Paprika library to constrain the candidate pool.
- Configurable recipe count (default 4) and a customizable prompt, with a detailed default covering leftovers, stove/oven contention, and cuisine pairing.
- Live prompt preview that updates as you tweak categories, count, or prompt text (Stimulus `meal-plan` controller backed by `home#meal_plan_prompt_preview`).
- Sends the candidate recipe pool as JSON to Gemini and returns a day-grouped meal plan with reasoning.

## AI Recipe Analysis
- Lists every recipe from the local Paprika mirror along with its categories.
- One-click "Analyze" per recipe sends name, ingredients, and directions to Gemini; results render in place via Turbo Streams.

## AI Ingredient Substitutions
- Free-text ingredient input returns Gemini-generated substitution suggestions, rendered via Turbo Stream.

## AI Nutrition Tracking
A chat-style daily food log (`/nutrition`) that turns plain English into tracked macros.

- **Describe what you ate** in one message (e.g. `small bowl bean salad, large plate chicken breast`). The LLM splits it into one entry per food and estimates calories, protein, carbs, fat, fiber, saturated fat, and sugar for the **portion eaten**.
- **Quick-pick pills + dropdown** below the reply build the message and choose which recipes are in scope:
  - **Portion pills** append sizing text only. The list lives in `app/models/portion_size.rb` (bowls, plates, plus handful/cup/slice/glass).
  - **Meal pills** — recipes scheduled 7 days back through 2 days ahead — append the title *and* register the recipe id.
  - **"Add another recipe…" dropdown** lists every other live recipe for anything not scheduled.
  - Clicking appends to the input and tracks the recipe id in hidden `recipe_ids[]` fields (Stimulus `meal-picker` controller).
- **Only the recipes you pick are sent to the LLM** — keyed by id, with their ingredients — instead of the whole library. The model returns a `recipe_id` per item for exact, in-memory matching (no fuzzy name matching).
- **Per-day totals and log**, each entry linked to its recipe(s) via the `nutrition_entries` ↔ `nutrition_entry_recipes` join. Delete a single entry or clear the whole day.
- The "day" is resolved in the **user's time zone** (see [per-user time zone](#per-user-time-zone)), so evening entries land on the correct local day.

## Verified Nutrition & Write-back
When a logged item matches one of your recipes, the app can write a validated,
standardized nutrition block back to that recipe — now **to the Paprika cloud**
so it syncs to all your devices. See
[Architecture → Nutrition write-back](architecture.md#nutrition-write-back).

## Profile & Settings
- **Staple recipes**: pin recipes so they surface as quick pills in the tracker.
- **Nutrition goals**: per-user calorie/protein/carbs/fat goals shown against daily totals.
- <a id="per-user-time-zone"></a>**Per-user time zone**: stored on `user_settings` (default `Pacific Time (US & Canada)`), selectable on the settings form. Each request runs in the user's zone so `Date.current` reflects their local day.
