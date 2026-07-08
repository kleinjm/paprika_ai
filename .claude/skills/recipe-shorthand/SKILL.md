---
name: recipe-shorthand
description: Convert a Paprika recipe's directions into James's terse cooking shorthand. Accepts a recipe name or id (the recipe you're viewing on its show page). Reads the current directions + ingredients from the DB, rewrites the directions per the shorthand syntax rules, shows the output for review, and only updates the recipe after approval.
user-invocable: true
arguments: "[recipe name or id]"
---

You're converting a recipe's directions from prose into James's cooking
shorthand notation.

## The syntax rules

**Read `references/shorthand-syntax.md` (in this skill's directory) first.** It
is the source of truth for the notation — line shape, the `+` add convention,
abbreviations, and worked examples. Follow it exactly.

## PHASE 0: Identify the recipe

The argument is a recipe name (e.g. `Instant Pot Mashed Sweet & Yukon Gold
Potatoes`) or a numeric `Z_PK` id. If no argument is given, ask which recipe.

Fetch it from the local mirror (Postgres columns are the quoted uppercase
`ZRECIPE` names; use the model's aliases). Run:

```bash
bin/rails runner '
r = ARGV[0] =~ /\A\d+\z/ ? Paprika::Recipe.find_by(Z_PK: ARGV[0])
                         : Paprika::Recipe.where(%(\"ZNAME\" LIKE ?), "%#{ARGV[0]}%").first
abort "not found" unless r
puts "ID: #{r.id}"
puts "NAME: #{r.name}"
puts "--INGREDIENTS--"; puts r.ingredients
puts "--DIRECTIONS--";  puts r.directions
' "RECIPE_NAME_OR_ID" 2>&1 | grep -v warning:
```

If more than one recipe could match, list the candidates and confirm before
continuing.

## PHASE 1: Rewrite

Rewrite the directions into shorthand:

- Use the **ingredient list** to spell out every ingredient by name — never
  "all veggies", "sauce ingredients", "herbs".
- Split prose sentences into many short steps (blank line between each).
- First step to use a vessel names its full contents; later steps that build on
  the same pan use `+`.
- Apply the abbreviations (`EVOO`, `S+P`, `BTABRTAS`, `QR`, `sm/md/lg`, `~`, …).
- Keep durations, pressures, and doneness cues from the source.

## PHASE 2: Show the output, then STOP

Print the rewritten directions in a fenced block. **Do not update the recipe
yet.** Ask James to review — he may tune the syntax rules. Wait for his
explicit go-ahead.

## PHASE 3: Update (only after approval)

Once approved, write the new directions through `Recipe#update_directions!`.
The local Paprika tables are a **read-only cache** — a raw `update!` on a
`Paprika::` record raises `Paprika::ReadOnlyMirrorError`. `update_directions!`
pushes to the Paprika cloud (the source of truth) and then refreshes the local
cache:

```bash
bin/rails runner '
r = Paprika::Recipe.find_by(Z_PK: ARGV[0])
r.update_directions!(ARGV[1])
puts "updated #{r.name} (pushed to Paprika cloud)"
' "RECIPE_ID" "$NEW_DIRECTIONS" 2>&1 | grep -v warning:
```
