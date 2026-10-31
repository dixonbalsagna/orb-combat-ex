# Right-hand attacks: the interface for everyone else (Controls, 2026-10-31)

What Controls has built, exactly as the other directors use it. Everything is behind `data/input/timing.json` `switches.rightStick` (**false**); with it off nothing here exists to the sim (gate row T proves the intents are bit-identical). Spec and reasons: `right-hand-attacks.md`. Landing notes and the two patches: `pending/right-hand/README.md`.

## 1. What the sim receives: the intent's second word

`SimIntent` (sim/input/intent.gd) carries 11 more fields, packed by `SimIntent.pack2()` / `unpack2()` into **26 bits**. `pack()` (the first word) is unchanged, so every old replay and hash is unchanged. `canon()` and `applyIntent()` copy the second word. `clear2()` zeroes it.

| Field | Kind | Meaning |
| :--- | :--- | :--- |
| `rsHeld` | held | a strike is in the sim's hands: from `rsStart` until it is thrown or cancelled |
| `rsStart` | edge | the request began (the stick crossed `on`, `settle` = 2 ticks ago). Wind-up starts here |
| `rsRelease` | edge | the strike was thrown, at `rsLevel` (the quick strike is level 0) |
| `rsCancel` | edge | guard or dodge ended the charge; nothing is thrown |
| `rsDir` | 0 to 4 | the locked direction, in **screen** terms: 1 up, 2 down, 3 left, 4 right; 0 none (a strike key with no direction: "toward him"). Turn left and right into toward and away with `SimStrikeRead.relative(dir, facing)` |
| `rsLevel` | 0 to 3 | 0 the quick strike; 1 to 3 the charge ladder reached while held (live ticks 12/30/50; beams and the signature 12/30/54). On the release tick it is the level thrown |
| `rsMask` | 4 bits | the stance mask of the build the stick crossed in: the layer (martial, energy, power, a hybrid). `SimStrikeRead.is_beam_layer(mask)` says which rungs apply |
| `rsAim` | 0 to 31 | the stick's sector now, 11.25 degrees each, 0 right, counter-clockwise (the beam's sweep) |
| `rsLag` | 0 to 15 | ticks the oldest edge waited because the sim was frozen (hit-stop). Edges persist until consumed, so none is lost |
| `brace` | edge | LB and a left-stick flick (or the brace button) set a read |
| `braceDir` | 0 to 4 | which read: 1 up (his heavy), 2 down (his flurry), 3 and 4 the two sides (his grab / his shot, by facing; screen sides like `rsDir`) |

The **vanish** is not a new field: LB and LT within 6 ticks sends the existing `escape` edge, with the stick vector (`moveX`, `moveY`) as the direction; a neutral stick means away.

**Edges** (`rsStart`, `rsRelease`, `rsCancel`, `brace`) persist in the layout until `SimLayout.consumed()` calls `clear_edges()`, so a fixed-step sim that skips builds still sees each edge once. The host builds, then the sim steps, then `consumed()`.

## 2. Simulation (and Tools for replay): the first thing a strike needs

Nothing in the sim reads the second word yet. The replay (`sim/core/replay.gd`) and the net record only `pack()`. Under `switches.rightStick`:

1. **Hash and replay.** Store `pack2()` beside `pack()` per changed intent (a third column, written only while the switch is on, so off records are byte-identical); `unpack2()` restores it. Add it to `canon()` consumers (the state hash's input digest). `rsLag` is part of it.
2. **Rollback.** Edges are one-tick facts in a record; a record that has `rsRelease` must replay it. Nothing is carried in the layout that the sim cannot rebuild from the records.
3. **The struggle flag.** Call `hub.set_struggle(slot, on)` each tick (like `set_sent`), `on` while that fighter is in a beam clash or a finisher contest. The layout then cancels a started strike, ignores the stick until it rests and frees the faces at once. Without it, a held stick during a struggle queues a surge (K3). Simulation or Encounter names the flag; the host line is one call.

## 3. Director and Combat: using the fields

Under `rsStart` the director opens a stick-strike wind-up for that fighter. A good first reading:

- `rsStart`: begin the wind-up atom for `(rsMask layer, rsDir)`; `rsHeld` stays true while it charges, and `rsLevel` climbs.
- `rsRelease`: throw `(rsMask layer, rsDir, rsLevel)`. Level 0 is the quick strike (a stick back at rest before `dwell` = 12 live ticks). The beam layers use `rsAim` for the sweep.
- `rsCancel`: drop the wind-up, no recovery cost beyond the guard or dodge that did it.
- `brace` with `braceDir`: set the read (the old v2 read, on the left thumb).
- Faces and the stick never overlap in one fighter (the no-claw law, `right-hand-attacks.md` section 6): while a strike is active, the face-button fields are stripped (queued 3 deep for 36 ticks), so a director never sees a face press and a strike request in the same exchange from the same hand.

Combat's content is the move table: one move per `(layer, direction)` for the quick strike, and the ladder per layer. 4 directions x 3 layers (martial, energy, power) x 4 levels, with the lay (mask 3) and the kite (mask 10) as hybrids that the stick does not use in pure 4a (`strike.inertMasks` [3, 4]). The numbers are Game Design's, as data.

## 4. Host and UI

- **Host** (`render/core/main.gd`, patch `right-hand-host.patch`): the pad's right stick goes to `hub.pad_stick_right(dev, x, y)` while `SimInputData.right_stick_on()`.
- **Hub settings** (all per slot; the slot argument is optional, -1 is all):
  `set_hand_layout("standard"|"swapped", slot)` / `hand_layout_of(slot)`;
  `set_mirror("auto"|"on"|"off", slot)` / `mirror_on(slot)` (the D-pad mirror of the stick);
  `set_strike_style("hold"|"toggle", slot)` / `strike_style_of(slot)` (hold: the return to rest throws; toggle: the next push throws);
  `set_brace_style("flick"|"press", slot)` / `brace_style_of(slot)`;
  `set_pad_has_right_stick(dev, bool)` (the host's word that a pad has no second stick, such as a handheld's half pad: the D-pad mirror then comes on under "auto");
  `set_struggle(slot, bool)`.
- **The pad brace button** (2026-10-31): Arena ships `brace_key` on L3 (R3 swapped), so `brace_style` "press" (Button only) never leaves a pad player without a control; UI's help for that choice can say "L3 on Arena; change it in Remap". Simple has no brace button.
- **UI rows** (`ui/data/settings.json`, via UI): hand layout, D-pad mirror, strike style, brace style; names for the presets `kb-solo-swapped`, `arena-swapped`, `simple-pad-swapped`; action labels for `strike`, `strike_key`, `brace_key`; the legend and the how-to-play. Remap rows for the strike stick, strike button, brace button and Escape are already in `sim/input/remap.gd` (`AXIS_ACTIONS`, `OPTIONAL`).

## 5. What a player needs before they feel a stick strike on a pad, in order

1. Land Controls' files and the two patches (the switch stays false).
2. Simulation: pack2 into replay, hash and net records (section 2.1); the struggle flag.
3. Director and Combat: consume `rsStart`/`rsRelease`/`rsDir`/`rsLevel`/`rsMask` and play a move (section 3). Even one placeholder move per direction makes it playable.
4. A preview with the switch on: set `switches.rightStick` to true in `data/input/timing.json` (a scratch copy for a preview; `SimInputData.right_stick_on()` reads it at load). Controls has no URL or command-line override; Tools can add one.
5. UI: the settings rows, names, legend. Not needed to feel it; needed to ship it.
