# Park: wall-hold-on, the key split (World, 2026-11-14; EP order: "building memory on, and the old crater repeat stays off on the arena")

`repeatMarks` did two jobs: the building's memory (each send that struck a building is one tier higher for the next) and the old crater repeat on the strip world (gen 1 and 2). The cityHold row turned both on with one number. This splits them: `repeatCraters` is the crater repeat's own key, shipped 0, so wall-hold-on's `repeatMarks` 2 is the building's memory only. Runs: `docs/world/runs/wall-hold-split/`.

| File | What |
| :--- | :--- |
| `wall-hold-split.diff` | `sim/world/brunt.gd` (the key and its default), `sim/world/crater.gd` (the two reads: the gate and the cap in `_repeat`), `tools/schemas/biomes-brunt.schema.json`, `data/biomes/brunt.json` (`repeatCraters` 0), `repeat_check.gd` and `switchon_check.gd`. World's files only: no grant. **Stands after globe-step2 and after `wall-hold-on/wall-hold-pins.diff`** (globe-step2 rewrites the line the gate sits on; the pins edit `repeat_check.gd`'s first rows) |
| `wall-hold-data.diff` | Replaces `wall-hold-on/wall-hold-data.diff`: the same five numbers (`lodgeHold` "body", `wallRebound` 0, `wallStop` 0, `wallDepthHold` 1, `repeatMarks` 2) and **no** `repeatCraters`, so it applies on the split. This is the GW2 data row |

## Behaviour

- Shipped data: nothing moves (both keys 0). The planet's crater repeat is unaffected: it was already its own key (`craters.json globe.repeats`) and `_digRead` reads that on the globe; only the strip world reads `repeatCraters`.
- With the data row on and `repeatCraters` 0: buildings remember (three sends at one tower fell 24 of 24 as before), and a blow beside an old crater digs as it does today on the hand-made arena. Set `repeatCraters` 2 for the old repeat.
- `wall-hold-on` README's first RISK (the old crater repeat on gen 1 and 2 worlds) is closed by this.

## Checks

| Gate | Result |
| :--- | :--- |
| `REPEAT` with the shipped data and with the five numbers flipped | 0 failed both; two new rows: the key is its own (0 or 2), and `repeatMarks` 2 alone does not repeat a crater |
| Negative control (the old gate: `crater.gd` reading `repeatMarks`) | the new "alone" row fails (1 FAIL) |
| `SWITCHON` (now sets both keys: "every switch on"), `WALLHOLD`, `BRUNT`, `THROUGH`, `WALL`, `CRATERS` | 0 failed, shipped data and flipped |
| `node tools/validate.js` | 323 files, 0 errors |

## NEEDS FROM EP

- Land after globe-step2 and `wall-hold-pins.diff`; the data row stays with GW2's hash window.
- **Tools:** `tools/preview/switches.mjs` and `docs/tools/preview.md` carry the cityHold row (it flips `repeatMarks` 0 to 2 with the four walls): it now means the building's memory only, which is what the row was meant to do. Nothing to change unless Tools wants a second row for `repeatCraters`.

## RISKS

- A data file that sets `repeatMarks` above 0 and expected the crater repeat with it (none shipped: Orb's 9 November build carries 0) now gets the building's memory only.
