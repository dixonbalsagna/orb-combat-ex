# feel: the launch's curve and hit-stop by weight (parked)

Owner: Simulation and Engine. 2026-10-19. Game Design's launch flight and hit-stop table (`fight-feel.md` sections 1 and 6; `rulings-2026-10-19.md` 1, `rulings-2026-10-19b.md` section 4), from Research's recommendations 9 and 10, for the camera. Two switches, both off: `data/fight/flight.json` and `data/fight/hitstop.json`. The page is `../../feel-core.md`.

## Apply

On a clean export of f91ad3c9 or later, from the repo root:

```
python docs/architecture/pending/feel/feel.py .
python docs/architecture/pending/grant_tools_fight.py .
```

`grant_tools_fight.py` is Tools': the two files' schemas, map rules, fixtures and virtual copies (same commit, or the validator warns "no-schema").

## What it changes

- New: `sim/core/flight.gd` (`SimFlight`), `sim/core/hitstop.gd` (`SimHitstop`), `data/fight/flight.json`, `data/fight/hitstop.json`.
- `sim/core/state.gd`: `S.flightOn`, `S.hitstopOn`, `S.hs`; `FlightState`, `StopState`; `Fighter.flt`.
- `sim/core/sim.gd`: the switches and states at a new match; the budget counts frozen and live ticks.
- `sim/core/fighter.gd`: `stepLaunched` paced while the curve is on.
- `sim/core/damage.gd`: a hit's stop from its weight; a broken region's and the KO's.
- `sim/core/hash.gd`, `replay.gd`: each only while on; the `flight` event's fields.
- `sim/core/fx.gd`, `view/fx.gd`: the `flight` event (kick, glide, arrive, end) for the camera.
- `sim/core/tools/parity.gd`: "the launch's curve" and "hit-stop by weight".
- `docs/architecture/fx-events.md`: the event's row.

**For Encounter:** name each hit's weight in its options (`o.weight`), and hold the launch's stop at the send (`SimHitstop.hold(S, "launch")` or `"launch_full"`). **For Camera:** the `flight` cue.

## Results (scratch, on f91ad3c9)

- Import clean (two new classes). Parity on the committed golden: 65 of 65, with the two new checks.
- The golden regenerates byte-identical.
- A shallow send in the proof: the kick's ramp and the peak, the glide at 0.4, the arrival told about 10 ticks before the ground, and the landing where the same send lands with the curve off. A steep send lands at the same unit, 3 ticks sooner (the curve carries him through the slow apex).
- Hit-stop: every weight's ticks, the merge, the budget's floor and its return a minute later, the step's count, a broken region's 24 and the KO's 30.
- Validator: 0 errors, 0 warnings, and the self-test all passed, with `grant_tools_fight.py`.
