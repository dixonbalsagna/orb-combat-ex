# The beam struggle's dig-in (Animation, 2026-10-23)

Owner: Animation. Parked as `docs/animation/pending/struggle-dig-in.patch` (render side only; apply after `shiver-by-weight.patch` and `press-ack.patch`). One of the six "readable poses" of the EP's taste brief (docs/ep/taste.md: nothing drawn on, over or between the fighters; the poses carry the information): the struggle's loser digging in, his feet carving the ground. It replaces the markers the UI is removing.

## What the player sees

While Encounter's beam struggle holds a meeting point (`S.game.clash.mid`, 0 at A's hands to 1 at D's), the fighter it is pushing back digs in, and the one winning leans in:

- **The loser sinks** into the squash pose's legs, pelvis and spine (`press_styles.json` `squash_pose`: the Protagonist's brace load, the Anti-hero's plant coil), by how far past the middle the point is on his side: 0 at the middle, up to 0.85 of the pose with the point at his hands.
- **His feet carve the ground:** the drawn body is dragged back along it, up to 9 units at 14 units a second, and comes back at 10 units a second when the struggle turns or ends. The sim's position is never moved: this is the drawn root (the same layer the lunge and the step use), so the beam's origin follows the body.
- **He trembles** from the strain (0.6 units, scaled by how hard he is pushed).
- **The winner leans in** by up to 2.5 units.
- A point at the middle shows nothing, and nobody digs in when no meeting point is written (an old clash with `mid` -1).
- All of it ramps over 10 ticks, never fewer than 6: the snappy profile solves on twos, so a shorter ramp reads as a snap (the lesson of the press-tick anticipation). Under reduced motion the drag and the tremble are 0.4.
- `RenderAnim.struggle_dig`, `--no-struggle-dig` (the study's `window.__nodig = 1`) is the before.

## Files

`data/anim/struggle.json` (new key set, schema `anim.struggle/1`: **Tools' closed schema needs an entry**, below), `render/anim/anim_data.gd`, `render_anim.gd`, `anim_fighter.gd` (`_struggle_layer`, after the beam layer), `tools/anim_check.gd` (`_test_struggle`), `tools/flurry_study.gd` (scenario `st_dig`: both fire, the point drifts to the right-hand fighter and back; with `window.__near = 1; window.__offset = 90` the bodies are drawn apart).

## Tests and gates

`_test_struggle`: the loser sinks 3 units or more and is dragged back 5 or more (both fighters, and with the point on either side), the winner leans 1 to 4 units forward and does not sink, an even point and no point change nothing, it all eases away within 60 ticks of the end with no tick moving the body by more than 3 units, no NaN, no limit past, and the sim's position never moves. Gates on a scratch export of main with the shake-by-weight and press-ack parks applied: `anim_check` with no arguments, the scans `--strict`, the 4-body scans, determinism plain and `--intro`.

## The schema request (Tools)

`data/anim/struggle.json`, schema `anim.struggle/1`, closed except `_` keys: `enter_ticks` (integer 6 to 30), `dig_w` (number 0 to 1), `slide_max` (number 0 to 30), `slide_rate` and `return_rate` (numbers above 0 to 60, units a second), `lead_dx` (number 0 to 10), `tremble` (number 0 to 3). All required.

## What it does not do

The ground furrows and the dust the feet throw are VFX's: the sim's clash gives them a point to throw from. This is the body's half only.
