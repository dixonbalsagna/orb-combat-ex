# brake2: the air brake's second window (parked)

Owner: Simulation and Engine. 2026-10-19. Game Design's rulings of 2026-10-18 (`rulings-2026-10-18b.md` 1b) on launch anywhere (f4e8269c), and Controls' `brake_ready` (`docs/controls/haptics.md` item 5). Behind the brake switch (`data/fight/brake.json`, off). The page is `../../brake-core.md` section 5.

## Apply

On a clean export of f91ad3c9 or later, from the repo root, in one commit:

```
python docs/architecture/pending/brake2/brake2.py .
python docs/architecture/pending/brake2/grant_world.py .
python docs/architecture/pending/brake2/grant_encounter.py .
python docs/architecture/pending/brake2/grant_audio.py .
```

- `grant_world.py` (World's `contact.gd`): a journey's two ends (`_finish`, `brakeEnd`) clear the launcher's power.
- `grant_encounter.py` (Encounter's `melee.gd`): the send kind's marks set on him before the launch, with the brake on.
- `grant_audio.py` (Audio's `audio_carry.gd`): the new "ready" plays no brake sound (today any text but "end" starts it).

## What it changes

- `sim/core/brake.gd`: the window from the send's power (`SimBrake.power`: the launcher's, else the send's speed over a full launch's); the marks spent at the send; the launcher's power cleared at control back; the "ready" at the first tick he could brake, once a send.
- `sim/core/state.gd`: `BrakeState.told`.
- `sim/core/fighter.gd`: the water recovery clears the launcher's power.
- `data/fight/brake.json`: `airSense` 0.1.
- `sim/core/tools/parity.gd`: the brake check (the windows, the power, the marks, the ready).
- `docs/architecture/fx-events.md`: `air_brake`'s ready.

## Results (scratch, on f91ad3c9)

- Import clean. Parity on the committed golden: 63 of 63.
- The golden regenerates byte-identical.
