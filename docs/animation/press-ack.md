# The press-tick anticipation (Animation, 2026-10-23)

Owner: Animation. Parked as `docs/animation/pending/press-ack.patch` (render side only). Asked for by the EP after Performance's finding that a light press shows nothing for 5 ticks, and Encounter's press-tick (aa927bb5): a press that has to wait for a cooldown now sends `press_ack`, text `queued`, on its own tick.

## What the player sees

On the press tick the fighter commits: the first frames of the wind-up, mixed over the idle stand at a part weight, held while the wait runs, and handed over to the real wind-up when the exchange starts. Nothing is drawn on or between the fighters: the lean, the weight and the shoulder carry it.

| Cell (`source`) | Pose | Part weight | The read |
| :--- | :--- | ---: | :--- |
| `x` a light | `ak.x_p`, `ak.x_r` | 0.60 | a short lean in, the near hand set (the Protagonist forward, the Anti-hero sat back with his chin up) |
| `y` a heavy | `ak.y_p`, `ak.y_r` | 0.70 | the weight moving onto the front foot, one shoulder wound back |
| `b` a signature | `ak.b_p`, `ak.b_r` | 0.75 | sinking, the shoulders starting to wind, the head down on him |

The poses are shallower than the held blows' bodies (`ch.*`): this is a press being committed to, not a charge.

## How it plays

- **The cue.** `press_ack` text `queued`: actor the presser, `source` the cell, `n` the tick it is due to start when the wait is a cooldown (else -1), `amount` the ticks to it. `RenderAnim` calls `AnimFighter.on_press_ack(cell, n, wait, t_cue)`. A wait under `min_wait` (6) ticks shows nothing: the exchange starts before it could read.
- **The ramp.** In over `enter_ticks`, out over `exit_ticks`, 6 each, smoothstep. Not 3: the snappy profile solves on twos (30 Hz), so a 3-tick ramp was seen as two samples, one of them 0.74 of the whole pose, a snap. At 6 ticks the largest step is 0.48 of the pose. (Orb's rule of 2026-10-22: no snaps.)
- **The hold.** Until the wait runs out (`amount` ticks, else `max_ticks` 36).
- **The hand-over.** It lets go, over `exit_ticks`, the moment the exchange starts: the sim's wind-up cue arrives, a blow is taken, the fighter leaves his free stand (a state change) or an approach begins. In AI-free real play (two scripted humans) the acks ended on "rush" and "state locked": the approach and the lock-in are where the real wind-up takes over. The part weight keeps the overlap small.
- `RenderAnim.press_ack`, `--no-press-ack`. Under reduced motion the weight is scaled by 0.6. Render only, outside the sim's hash.

## Files

`render/anim/tools/waves/ack1.mjs` (wave `ack1`, prefix `ak`, 6 poses, held lint class `rest`), `data/anim/press_ack.json` (new key set: **Tools' closed schema needs an entry**, see below), `render/anim/anim_data.gd`, `render_anim.gd`, `anim_fighter.gd` (`on_press_ack`, `_ack_layer` after the grip layer), `tools/anim_check.gd` (`_test_press_ack`), `tools/flurry_study.gd` (scenarios `pa_light`, `pa_heavy`, `pa_sig`; `window.__noack = 1` is the before).

## Tests and gates

`_test_press_ack`: every cell and fighter shows (a few units of lean or sink by tick 4 of the ramp), is clean (no NaN, no limit), is exactly the idle stand again after the wait, never changes the body by more than 0.6 of its size in a tick, is let go within 8 ticks of a blow taken, and a 2-tick wait shows nothing. Gates on a scratch export of main: `anim_check` with no arguments, joint, lead, held and guard scans `--strict`, the 4-body lead and joint scans, and determinism plain and `--intro`.

## The schema request (Tools)

`data/anim/press_ack.json`, schema `anim.press_ack/1`, closed except `_` keys: `enter_ticks`, `exit_ticks` (integers 1 to 20), `max_ticks` (integer 1 to 120), `min_wait` (integer 0 to 60); `cells`: required `x`, `y`, `b`, each `{pose: string (a pose id, `ak.<seq>.<phase>`), w: number 0 to 1}`; `fighters`: a roster id (`^[A-Z][A-Z0-9_]*$`) to an object of cell keys (`x`, `y`, `b`) to pose ids. Cross-reference: every pose id named exists in a wave's poses (as `recoil.json`'s sequences do).

## One trap

`windup_cue.T` is -10 until the first wind-up cue; the hand-over compares the cue's time with the time the ack started, so an ack only lets go on a wind-up that arrives after it.
