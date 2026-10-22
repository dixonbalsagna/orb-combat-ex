# ricochet: the ricochet's glance (parked)

Owner: Simulation and Engine. 2026-10-22. Game Design's glance (`fight-feel.md` section 3; `rulings-2026-10-22.md` 2b), on the EP's brief of 2026-10-22, behind `data/fight/ricochet.json` (off). The page is `../../ricochet-core.md`.

## Apply

On a clean export of c847bf8f (main with the planet golden keys) or later, from the repo root, in one commit:

```
python docs/architecture/pending/ricochet/ricochet.py .
python docs/architecture/pending/ricochet/grant_world.py .
python docs/architecture/pending/ricochet/grant_tools.py .
```

- `grant_world.py` (World's `contact.gd` and `brunt.gd`):
  - a body's row count (`Body.rics`, read from `SimRicochet.inRow` in `toBody`);
  - the glance branch in `_land`, before the slam;
  - the tell in `_apply`;
  - `SimRicochet.offFace` before a building's hit, in `checkHit` and its swept form.

  Every line runs only with `S.ricOn`.
- `grant_tools.py` (Tools'): the schema for `data/fight/ricochet.json`, its map rule, its fixtures and its virtual copy.

Then `--import` (a new class).

## What it changes

- New: `sim/core/ricochet.gd` (`SimRicochet`), `data/fight/ricochet.json`.
- `sim/core/state.gd`: `S.ricOn`; `Fighter.rics`, `ricN`.
- `sim/core/sim.gd`: the switch at a new match.
- `sim/core/hash.gd`: the row, only while on; the `ricochet` event's fields.
- `sim/core/replay.gd`: the data, only while on.
- `sim/core/fx.gd`, `view/fx.gd`: the `ricochet` event.
- `sim/core/flight.gd`: `SimFlight.endLeg`, public.
- `sim/core/tools/parity.gd`: "the ricochet's glance".
- `docs/architecture/fx-events.md`: the event's row.

## Results (scratch)

**Re-cut to Game Design's 4, on c847bf8f** (main's sim to 03427822):
- Alone: import clean, parity on the committed golden 69 of 69 ("the ricochet's glance" re-cut, on the test world's 49-degree uphill), golden byte-identical.
- With `hitstop2/`: parity 69 of 69, golden byte-identical. The full gates pass: npm 5 of 5, determinism and its intro, seam, the flash count and its check-log, the validator 0 and 0, the self-test 8,590 of 8,590, QA's run-all, the loader and the flash self-test. All 15 of Rendering's checks pass.

**In play:** 6 AI matches of 7,200 ticks with the switch on gave 2 glances, none off a face. With the switch off, 7 of 58 ground contacts were on ground sloped 30 degrees or more (3 would glance, 1 is under the line, 3 are steeper). `../../ricochet-core.md` section 4 has the reading.
