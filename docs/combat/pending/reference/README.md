# The training dummy's moveset (parked, 2026-10-15)

Owner: Combat and Choreography. For the window with Simulation's training dummy (`docs/architecture/pending/n-bodies/dummy_roster.py`). Game Design's rules for him are in `docs/design/fighter-pipeline.md` section 8: base stats and the common pool, frozen, and exempt from the gate on a fighter's own blows.

## To apply

```
python docs/architecture/pending/n-bodies/n_bodies.py .
python docs/architecture/pending/n-bodies/dummy_roster.py .
python docs/combat/pending/reference/reference_recipes.py .
```

Then regenerate the golden, once.

- **The file it changes is `data/combat/recipes.json`.** The dummy's entries go in under the key `reference`. The script only adds lines.
- **`data/director/alchemy.json` needs nothing.** A fighter it doesn't list uses his id in lower case.
- **Order matters.** The director's data hash covers the recipes file, so this goes in before the golden is regenerated. The hash moves, but no match does: his entries are read only when he is in a seat.
- **`--check`** says whether it applies cleanly, or is already in and the same. It writes nothing.
- **It refuses a recipes file whose cells name a pool he lacks.** That would happen if the split by path landed first. Combat then regenerates the fragment.

## What he has

Everything he throws is a common piece (one more than one fighter has posed) and already a row of the pieces table.

| Cell | Pieces |
| :--- | :--- |
| Lights | 17: every common light |
| Mediums | 16: every common medium |
| B | The 6 common pieces that stand in at B's wind-up, as both fighters' did before the heavy tier was posed. No heavy of the tier is common |
| Launcher | The 6 stand-ins on the trunk, plus the common uppercut and rising knee for an upward launch, since no stand-in rises |
| Bolt and blast in reach | None: no energy piece is common, so they go without a piece |

**Where it comes from.** His kit row is `reference` in `../roster/identity.candidates.json`, and it is locked in `../roster/lock.candidates.json`, so it stays as it is. Combat's pool builder turns that row into the fragment, `reference.recipes.json`.

## Proved

On a clean export of f9812d0b, with Simulation's two scripts and then this one applied:
- **The recipes diff is additions only.**
- **Tools' validator reads 3 errors:**
  - Art's colour row for him, already in Simulation's list.
  - `xref:recipes-brawl` twice: every fighter must have the brawl's bolt and blast pools. Empty pools are refused by the schema as well.
- **Six seeded matches,** the dummy against each fighter in both seats, 180 s each:
  - Every blow of his comes from his own pools.
  - His only blows without a piece are his bolts and blasts in reach (175 and 205).
  - The other fighter's blows are all as before.

## Needed in the same commit

- **Tools:** `xref:recipes-brawl` lets the training dummy go without `reach.bolt` and `reach.blast`. For example, it can skip those two for a fighter whose `fighter.json` has `identity.role` "reference". One line in `tools/lib/xref-fight.js`, and a fixture.
- **Art:** his row in `data/art/colour-vision.json`, already in Simulation's list.
