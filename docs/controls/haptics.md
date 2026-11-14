# Haptics: the rumble that carries the cues, one set of numbers, and what the host does

Controls, 2026-10-16, revised 2026-10-18 for the EP's brief (Orb's minimalist rule: nothing on, over or between the fighters, so rumble carries the cues; `docs/design/minimal-hud.md` section 4, `docs/research/readable-speed.md`). Rumble is output: it never touches the sim, the intent, the replay or the hash, and it is never the only cue (UI's edge hints, Audio's sound and the fighters' own bodies say the same).

## The eight kinds

Each is a few **steps** (a pulse and when it starts) with a floor under every length. **Distinct** (no two have the same steps; only the brake is the high motor alone; no two buzz a phone alike), **short** (all over within 160 ms) and **never constant** (each kind has its own least gap, `gapMs`, and the motor is on at most half the time even if one is asked for as fast as the gap allows). Tested.

| Kind | Cue (who feels it) | Pad (weak = high motor, strong = low) | Phone | Own gap |
| :--- | :--- | :--- | :--- | :--- |
| `launch_open` | `launcher_open`: the fighter who may launch (the actor) | Audio's thump (0.3 / 0.7, 80 ms) and a ring 90 ms later (0.2 / 0, 60 ms) | 25 ms, then 10 ms at 85 | 300 ms |
| `form_prompt` | `transform_ready`: the actor | two light taps, the second firmer: (0.25 / 0.25, 20 ms), then (0.4 / 0.4, 30 ms) at 70 | 10 ms, then 20 ms at 70 | 200 ms |
| `brake_ready` | the brake becomes available: the actor | one sharp tick, **high motor alone** (0.6 / 0, 20 ms) | 10 ms | 200 ms |
| `charge_full` | `charge_full`: the charger | one firm snap, both motors (0.5 / 0.6, 40 ms) | 35 ms | 200 ms |
| `clinch_pulse` | `grapple_pulse` (every 20 ticks): **both** in the clinch | a low creak (0 / 0.3, 30 ms) then a faint scrape (0.15 / 0, 20 ms) at 50; **scaled by the grip** | 15 ms, then 10 ms at 50 | 250 ms |
| `struggle_push` | `beam_surge`: the one who surged | a bright tick on the high motor (0.5 / 0.1, 25 ms); **scaled by his share of the point** | 20 ms | 100 ms |
| `struggle_pushed` | `beam_surge`: the other | a heavy low push (0 / 0.6, 40 ms); **scaled by the pusher's share** | 30 ms | 160 ms |
| `struggle_lose` | `beam_end` overwhelmed: the target | (0.4 / 0.8, 60 ms), once | 40 ms | 300 ms |

**The struggle is not on the beat** (Orb's pick). `struggle_pulse` and `struggle_surge` are retired; nothing rumbles at the 20-tick beat, a stray, the start or a detonation. It rumbles on a **surge**, and the strength follows who is pushing: the point runs 0 at the firer's hands to 1 at the other's, so a surge's scale is the pusher's **share** of it (`push_share`): a fighter with the point at his end, surging, hits hard and the other is pushed hard; a fighter fighting back from behind gives a light tick and a light push; a sharp surge (the window's first tick) adds `sharpBoost` (0.25). The pusher feels his own press as the bright tick, the other feels the same push as the heavy low one: two motors, so the two are never confused.

**Scale** (0 to 1): a pad's motors are multiplied by `scaleMin` + (1 - `scaleMin`) x scale (0.35 at 0, 1 at 1) and raised to `padMinStrength` (0.15: below that a pad motor is not felt), a motor that was off stays off, and the **length is kept**; a phone has no strength, so a smaller scale is a **shorter** buzz (never under `handheldMinMs`). The clinch's scale is the catcher's grip over `gripSteps` (5).

## Hardware limits, and who chose what

**Audio's ear for the feel, Controls' numbers for the hardware.** A pad motor needs about 20 to 40 ms to spin up, so no step is under `padMinMs` (20) and a phone's under `handheldMinMs` (10), lengthened, never dropped; Godot reads a duration of 0 as "for as long as it can", so 0 is never passed; two calls in a row replace each other; a phone's Vibration API has one duration per call and none at all on iOS Safari. The numbers are data (`haptics` in `data/input/timing.json`), so Audio and Orb can change them on a real pad without code. **What is not mine to judge is how they feel**: I have no pad here. A first test is to play each kind in turn on the pad Orb uses; if one is too soft raise `strong` or `weak`, not the length.

## What was built

- **`sim/input/haptics.gd` (`SimHaptics`), pure.**
  - `steps(kind, device, scale = 1.0)`: the cleaned, scaled steps (each `at` 0 to 1000 ms, motors 0 to 1, lengths at the floor, at most four).
  - `plan(kind, target, enabled, last_ms, now_ms, scale = 1.0, last_kind_ms)`: what to play, or `{}`: a pad `{via: "pad", id, steps: [{at, weak, strong, seconds}]}` for `Input.start_joy_vibration`; a phone `{via: "handheld", steps: [{at, ms}]}` for `Input.vibrate_handheld`; **nothing on a keyboard, an empty slot, an unknown kind, the haptics option off, a request inside the slot-wide `minGapMs` (80), or inside the kind's own `gapMs` since the slot last felt that kind.**
  - `requests(name, actor, target, text, amount, firer)`: who feels what for one sim cue, `[{slot, kind, scale}]`; the table above. `push_share`, `scale_factor`, `kind_gap_ms` are the pieces.
  - No clock, no state, no RNG: the host owns the millisecond clock and the timers.
- **Data:** `haptics` in `timing.json`: `minGapMs`, `padMinMs`, `handheldMinMs`, `scaleMin`, `padMinStrength`, `gripSteps`, `sharpBoost`, and for each kind `pad`, `handheld` and `gapMs`. Schema: `docs/controls/haptics-schema.patch` (a closed block: the eight kinds, at most four steps, motors 0 to 1, lengths 0 to 500 ms, gap 0 to 5000).
- **Touch devices and the option:** a touch slot gets the phone shapes through `hub.rumble_target`; iOS Safari has no vibration API and gets nothing (the cues are also seen and heard); the player's `haptics` option off silences everything.

## What the host needs (`docs/controls/haptics-host.patch`, render/core/main.gd, Rendering's)

1. **`_haptics_from_events(events)`** called from `_on_drained`: for each sim event it asks `SimHaptics.requests` and plays each result through `_on_haptic`. It keeps the firer (`beam_struggle` cue's actor) for the push shares. **`launcher_open` and `transform_ready` are skipped there** because UI raises them (`haptic_requested`, `form_prompt_shown`) with its marks setting.
2. **`_on_haptic(slot, kind, scale = 1.0)`** now carries the scale and the per-kind last time (`_haptic_last_kind`) for the kind gap.
3. **`_on_form_prompt`** now just calls `_on_haptic(slot, "form_prompt")`, so the ready form uses the two-tap shape and the same gating as every pulse, not its own 15 ms.
4. **UI still has to raise `launch_open`** (it does today, at ui_hud.gd, `haptic_requested`); that hookup is the one thing outside Controls.
5. **The brake tick is hooked (2026-10-22).** Simulation's brake2 (`sim/core/brake.gd`) tells `air_brake` with text `"ready"` (kind `window`, actor the sent fighter) once a send, on the first tick he could brake (the start window, 8 to 20 ticks by the send's power; never for a set piece's send; only with the brake switched on). The host loop already passes every event to `SimHaptics.requests`, so it plays `brake_ready` on the sent fighter's own device with no host change. It is the only cue for the moment the brake opens (Audio's carry plays no sound for "ready"). If the fighter is already holding the brake, the tick and the brake's `start` come on the same tick; the tick is kept (it says "now").
6. **The beam struggle's cues** (`beam_struggle`, `beam_surge` with `amount` the point after the surge, `beam_end` with actor the winner and target the loser) are Encounter's parked work (`docs/director/pending/beam-struggle`); the mapper reads those fields as the park writes them. The clinch pulse reads `grapple_pulse` (`amount` the catcher's grip, signed; its size is used).

## Proof

`haptics_test.gd` (80 checks): the eight kinds step for step; the floors (8 ms to 20, 4 ms to 10) and as data; steps left out, ordering, the four-step cap and clamping; a malformed list falling back; the scale (0, middle, 1; only strength on a pad; `padMinStrength` and `scaleMin` as data; shorter on a phone, never under its floor; a scaled plan is still a real pulse); distinct, short and duty-limited kinds; **a surge mashed every 40 ms for two seconds plays 15 to 20 times with the motor on under half the time**; the kind gap against its own last, not the slot's; the mapper for every cue (the launcher alone, both in the clinch scaled by grip, the pusher's share both ways, sharp, no firer known, strays and the beat silent, only an overwhelmed end); a mapped request playing on its own device scaled; a keyboard and an empty slot nothing; asking changes no intent. On a clean export of HEAD with these files and both patches: all 16 input tests, `npm test --prefix sim` (5 of 5), `tools/validate.js` (0 errors) and its self-test (8396 of 8396; the schema was also checked to reject a retired kind, a motor over 1, a gap over 5000, `scaleMin` over 1 and a fifth step), the patched `main.gd` loads, and render determinism plain and `-- --intro --seeds=2 --ticks=900` (each same as the sim alone).

`brake_ready_test.gd` (15 checks, on the sim's real event): a staged send through `SimCore` with the brake on tells ready once, on the tick the window opens; the host's own call turns it into one `brake_ready` request for the sent fighter (slot 1) at full scale and nothing else in the run rumbles; a brake held through the window tells ready once, then start and end, and only the ready rumbles; a set piece's send and a match with the brake off tell nothing; the plan lands on that fighter's own pad as the high-motor tick, a phone gets 10 ms, a keyboard, an AI-held body and the option off get nothing, and the kind's 200 ms gap holds between two sends.

## Five more for the strike stick (Controls, 2026-11-01, parked: `docs/controls/pending/stick-feel/`; behind `switches.hapticLadder` and `switches.hapticIncoming`, off)

Game Design ruled pitches 1 and 3 of `rule-of-cool-pitches.md` in (`rule-of-cool-map.md` section 5, row 6). They keep every rule above: distinct, short, never constant, never the only cue, nothing on a keyboard, the `haptics` option silences them, and none reads or writes the sim.

| Kind | Cue (who feels it) | Pad (weak = high motor, strong = low) | Phone | Own gap |
| :--- | :--- | :--- | :--- | :--- |
| `ladder_1` | the first rung of a held strike's charge (12 live ticks from its start): the charger | a tick (0.35 / 0.15, 20 ms) | 12 ms | 120 ms |
| `ladder_2` | the second rung (30): the charger | a knock (0.3 / 0.45, 25 ms) | 22 ms | 120 ms |
| `ladder_3` | the third rung (50; 54 for a beam): the charger | a thud (0.25 / 0.8, 45 ms) then a short ring at 70 (0.2 / 0.3, 25 ms) | 40 ms, then 15 ms at 70 | 160 ms |
| `release_thump` | the throw of a charged strike or beam (level 1 or more; a flick throws none): the thrower | a low push (0.10 / 0.65, 40 ms) and a roll-off (0 / 0.25, 30 ms), scaled by the charge (0.6, 0.8, 1.0) | 30 ms, then 14 ms at 55 | 160 ms |
| `blow_land` | a blow lands (damage light, medium, heavy, bolt, blast, guard): the attacker | a short firm knock (0.15 / 0.6, 30 ms), scaled 0.3, 0.6, 1.0 by strength, a guarded blow 0.2 | 23 ms | 90 ms |
| `hit_taken` | the same blow: the one it hit | lower and a little longer (0.1 / 0.7, 40 ms) | 29 ms | 90 ms |
| `close_surge` | a `rush` (an attack carrying the fighter across the gap): the one closing | one short surge (0.3 / 0.25, 40 ms) | 24 ms | 200 ms |
| `launch_felt` | a `launch`: the one sent (the launcher has `launch_open`) | a heavy push then a roll-off (0.2 / 0.8, 80 ms; 0 / 0.4, 60 ms at 100), scaled by speed | 42 ms, then 18 ms at 100 | 300 ms |
| `landing_thud` | a `land` (touchdown after a launch): the one landing | a thud and a tail (0.1 / 0.65, 50 ms; 0 / 0.25, 30 ms at 70), scaled by speed | 34 ms, then 16 ms at 70 | 200 ms |
| `building_break` | a `building_fall`: both pads | two low pushes (0.2 / 0.6, 70 ms; 0 / 0.4, 70 ms at 90), scaled by height | 45 ms, then 40 ms at 90 | 600 ms |
| `incoming_high` | a rival's stick strike starts (`stick_start`), toward or up: the defender | two light taps (0.55 / 0.12, 20 ms), then (0.3 / 0.1, 20 ms) at 45 | 14 ms, then 10 ms at 45 | 200 ms |
| `incoming_low` | the same, away or down: the defender | one low knock (0.1 / 0.55, 30 ms) | 18 ms | 200 ms |

The ladder's pulses are not sim cues: `SimInputHub.take_haptics()` finds them as it builds each slot's intent (the level rises while the stick is held) and the host plays them (`stick-feel-host.patch`, two lines). The incoming cue is Encounter's `stick_start` (actor = the striker, text = its direction as the defender faces it); `SimHaptics.requests` turns it into the other slot's pulse, and the host's existing loop plays it. `stick_feel_test.gd` (52 checks) covers the ladder's ticks, the cancel, the second charge, the defender and striker slots, both switches off and the intents unchanged.

**The sixth kind, for GD's row 40 (beams that travel; parked in the same folder, `switches.hapticIncomingBeam`, off):** `incoming_beam` — one firm pulse on both motors (0.4 / 0.5, 40 ms; a phone 26 ms), own gap 100 ms. It is played many times, not once: Encounter's `beam_window` cue (text `start` or `end`, actor = the shooter, target = the receiver, `n` = the ticks from the hand to the front's arrival, `k` = the level, optional `dodge_from`) gives the receiver's pad a crescendo: `SimHaptics.beam_window` returns the pulses (one per 200 ms of the window, 1 to 5, evenly inside it, scale rising 0.3 to 1.0, the last well before arrival), and the host plays them on its timers and drops the ones still waiting when a later window or the end cue comes (`stick-feel-host.patch`). The shooter feels nothing. Not a sim read: it needs only the cue. The cue's shape is UI's contract as the EP gave it (2026-11-01).
