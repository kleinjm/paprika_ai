# Recipe directions shorthand syntax

A terse, scannable cooking notation. The goal: while cooking you glance at one
short line, do it, glance at the next. Prefer **many short steps** over a few
long ones.

## Line shape

Most steps follow:

```
Action, <modifiers…>: ingredients
```

- **Action** comes first: `Saute`, `Cover`, `Blend`, `Add`, `Remove`, `Cook`,
  `Garnish`, `Drain`, `Mash`, `Stir in`, `Pour`, or an abbreviation like
  `BTABRTAS`.
- **Modifiers** are comma-separated and describe *how*: vessel size, heat level,
  duration, and/or a doneness condition. Include only the ones that apply, in
  roughly this order: vessel → heat → duration → condition.
  - vessel: `sm pot`, `md pot`, `lg pot`, `sm skillet`, `lg skillet`, `dutch oven`
  - heat: `med heat`, `low heat`, `high heat` (omit when obvious)
  - duration: `5 min`, `5-6 min`, `~3 min`, `7-10 min`
  - condition: `until tender`, `until softened`, `until wilted`,
    `until browned`, `covered`
- **`:` then the ingredients**, comma-separated, in the order they go in.

Not every step has ingredients (`Cook rice`, `Remove veggies from skillet`,
`Pour veggies back in`). Not every step has modifiers. Drop the colon when there
are no ingredients.

## Adding to what's already cooking

When a step adds ingredients to the pan/pot already in use, prefix the new
ingredients with `+`:

```
Saute, 5-6 min: + celery, garlic
Saute, 4 min: + zucchini, summer squash, paprika, turmeric
```

The first step that establishes a vessel names its full contents (no `+`);
later steps that build on it use `+`.

## Always list every ingredient by name

Never collapse ingredients into a group. Write them all out.

- ❌ `Saute: all veggies`  ✅ `Saute: broccoli, bok choy, zucchini, mushrooms`
- ❌ `+ sauce ingredients`  ✅ `+ soy sauce, rice vinegar, sesame oil`
- ❌ `+ herbs`  ✅ `+ thyme, parsley, chives`

Pull the names straight from the recipe's ingredient list, and always use the
**full ingredient name** — even when referring back to something already in the
pot. Don't shorten "sweet potatoes, Yukon gold potatoes" to just "potatoes" in a
later step; name them again.

## Prefer more, shorter steps

Split compound sentences into separate lines. A source step like "Lock the lid,
set to sealing, cook on high pressure 7 min, then quick release" becomes several
lines. More steps of shorter text beats fewer steps with more text.

## Formatting

- One step per line, a **blank line between steps**.
- Keep steps in cooking order.
- End with a `Garnish with …` line when the recipe garnishes.

## Abbreviations & shorthand

| Short | Meaning |
|-------|---------|
| `BTABRTAS` | bring to a boil, reduce to a simmer |
| `BTABTAS` | bring to a boil, then a simmer |
| `EVOO` | (extra virgin) olive oil |
| `GEVOO` | generous glug of olive oil |
| `S+P` | salt and pepper |
| `QR` | quick release (pressure cooker) |
| `IP` | Instant Pot |
| `HP` | high pressure |
| `sm` / `md` / `lg` | small / medium / large |
| `min` | minutes |
| `~` | approximately |

Use `EVOO` / `GEVOO` for the oil, `S+P` where the recipe seasons with salt and
pepper. Introduce a new abbreviation only if it's unambiguous; otherwise spell
it out.

## Worked examples

### Corn Chowder

```
Saute, med heat, lg pot, ~3 min: EVOO, leeks

Cover, 3-4 min, until tender: leeks

Saute, 5-6 min: + celery, garlic

BTABTAS, 8-10 min or until potatoes tender, covered: corn, potatoes, veggie broth, salt, pepper, bay leaves, thyme

Remove 4 cups (scaled) of soup from pot & set aside

Add coconut milk

Blend using immersion blender: soup

Pour veggies back in

Add vinegar for a hint of brightness, + turmeric

Garnish with scallions, fresh herbs, crusty bread etc.
```

### Light & Fresh Vegetable Detox Soup

```
Cook rice

Lg pot, saute, 7-10 min until starting to brown: GEVOO, tempeh, bell pepper, carrot, scallions

Saute, 4 min: + zucchini, summer squash, paprika, turmeric

BTABRTAS, 5 min: coconut cream, stock, S+P

Remove from heat & stir in: lime juice, cilantro

Immersion blender some of the soup, garnish with cilantro & serve
```

### Asian Ground Chicken Veggie Saute

```
Saute, until softened, lg skillet: EVOO, broccoli, S+P

Saute, until wilted: + bok choy, S+P

Saute, until softened: + zucchini, mushrooms, soy sauce

Remove veggies from skillet

Saute, until fully cooked through, lg skillet: EVOO, chicken, soy sauce
```
