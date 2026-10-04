# The melee press styles on screen (2026-10-04)

Orb's approved reference is `docs/ep/prototypes/melee-trade-v2.html`; his words are in `docs/ep/vision.md` (the last two sections): timed blows land instant with an after-image, mashed blows are fast with a fluid blur, held blows are the most fluid with warping and smears; a blocker is never knocked back. This is a **first build**, behind a flag, driven by what exists today. Code: `render/vfx/press.gd` (state and triggers) and `_press()` with its helpers `_figure` and `_line` in `render/vfx/shots_view.gd` (the shots view's one draw); one new shader shape (5, a diamond) in `render/vfx/shaders/transform.gdshader`. Flag `hub.press_enabled` (`VfxLook.PRESS_DEFAULT`, on while we look at it; set it false to ship it off). Presentation only: it reads events and fighters, draws no random number, writes nothing in the sim. Numbers are in `VfxPress.DEFAULTS` (code, as the beam plays; an optional `data/vfx/press.json` is read if it exists, none is created so no schema is needed yet).

## The effect per style

| Style | What the prototype shows | What is drawn | Quads |
| :-- | :-- | :-- | :-- |
| **Speed** (mashed) | A soft, filled, overlapping blur along the fist's path; a small round contact ring | Five layered soft discs along the fist's path (guard to contact, the fist alternates height blow to blow), one wide soft streak under them, one small round ring at the contact. Fades in 8 ticks; the ring in 6. | 7 |
| **Tech** (timed) | Three sharp wireframe echoes of the body between the old pose and the strike, popping off one at a time from back to front; a thin straight speed line; a hard diamond contact mark | Three thin wire figures (head ring, torso, two legs, striking arm with the fist at 1/4, 2/4 and 3/4 of the way to the contact) behind the final body by up to 24 units; they pop off at 2.5, 5 and 7.5 ticks, back first. One thin straight line guard to contact (7 ticks) and a hard diamond (shape 5) at the contact (5 ticks). | 17 down to 1 |
| **Heavy** (held) | A shrinking charge ring on the wind-up; on the release a filled crescent smear and stacked body ghosts, and a double contact ring; the target stretching with ghosts as it flies when the heavy ends a string | Wind-up: one ring that shrinks 34 to 9 units around the fist and brightens (cue `tell_heavy`, 26 ticks at most). Release: four filled body ghosts stacked behind him (alpha rising toward the body), a five-segment filled crescent from the back-swing over the top to the contact, and two contact rings (two ticks after the blow). Fly (the sim's `knockback`): three filled ghosts along the target's last 12 ticks of path, for the knockback's duration (40 ticks at most). | 1 (wind-up), 27 (release), 15 (fly) |
| **Block** | A shield line and a block flash; never a knock-back | A thin vertical line in front of the defender (12 ticks, bright then dim) and two flash rings in his lane colour. Nothing here moves anyone. | 3 |

Contact is on the victim's front, at the height of the region hit (head, core or arms, legs). Colours are the attacker's lane colour (the block's the defender's), darkened a little so they read against sand and sky; none is white, gold or red.

## Cost against the budget

Quads only, in the shots view's one draw (cap 380; the busiest test tick before this work was 41). One blow: 1 to 27 quads. The busiest test tick, both fighters landing a heavy and a timed blow with both wind-ups showing and a fly: 84 of 380. Debris pool: none. Not measured: the web build under load and an old laptop (the stills were taken in the web build). `effects_check.gd` `_press()` asserts each count above.

## What drives it today (what exists)

- **The blow:** the sim's `damage` event (attacker, victim, region, kind light, heavy or guard). A beam's, impact's or landing's damage is ignored.
- **The style of a light blow:** the beat's own `style` field when the director sends one (accepted now: speed, tech, heavy, or the press log's words mash, timed or rhythm, held or hold); else the attacker's press log, **read only** (`DirAlchemy.read`, never its resizing: it is skipped if the log is not sized yet): rhythm is tech, hold is heavy, mash, taps and none are speed. A `heavy` blow is heavy; a `guard` is a block.
- **The wind-up:** the cue `tell_heavy`.
- **The ender:** the sim's `knockback` (it is sent when an exchange ends in a knockback; a blocker never gets one).
- **The old pose (estimate):** the fighter's position some ticks ago (a 24-tick history kept here), at least 24 units back for the echoes.
- **The limb path (estimate):** the fist runs from a guard in front of the chest to the contact point.

## What I need

**From Animation** (docs/animation/press-styles.md, not yet written when this was built; `data/anim/press_styles.json` is data only so far and `RenderAnim.press_styles` is off):
1. The previous pose: the strike's start pose's joint positions in world units (or a `fighter_pose_at(i, ticks_ago)`), so the tech echoes can sit on the body's real earlier poses and the heavy's ghosts on the real wind-up, not on an estimate.
2. The limb path: the striking hand's world position per tick (`hand_r` or `hand_l`, with the hand named), so the speed blur, the speed line and the crescent follow the real fist, and the contact point is where the fist ends.
3. `press.ghosts` (3 tech, 2 speed, 3 heavy in the data) as the echo count I am asked for; today I draw 3, 4 and 3 and will read it when it is exposed.
4. The head and chest world positions (`fighter_head(i, a)` is already asked for by the glare), so the figures' head rings sit on the real heads.

**From the director (Encounter):** the style on each strike beat, as a `style` field on the `damage` event (or the beat's cue): `speed`, `tech` or `heavy` (the words mash, timed, held work too). Also a `hand` (0 or 1) so a mash alternates fists as the animation does, and an `ender: true` on the heavy that ends a string (today the flight is read from `knockback`, which arrives with or after the blow).

## Reduced motion

The same looks in their short forms, with nothing that strobes: speed has no disc layers (one soft streak and its ring, half the length); tech shows only the last echo, the line and the diamond (0.6 of the length); heavy has no body ghosts and a three-segment crescent, and a target's flight shows no ghosts; the wind-up ring and the block's flash are as they are (one steady shrink; a single flash). `effects_check.gd` checks the reduced counts.

## Pictures

Web build, a scratch staging hook that sends the events as the director will (`damage` with a `style`, `tell_heavy`, `knockback`), zoomed on the pair. Both fighters land each blow in turn (the Protagonist's slot, the rival's slot).

| Speed (mash) | Tech (timed) | Heavy (held) |
| :---: | :---: | :---: |
| ![](img/ps-speed-protagonist.jpg) | ![](img/ps-tech-protagonist.jpg) | ![](img/ps-heavy-protagonist.jpg) |
| ![](img/ps-speed-rival.jpg) | ![](img/ps-tech-rival.jpg) | ![](img/ps-heavy-rival.jpg) |

Block (the rival blocks the Protagonist's blow; the Protagonist blocks the rival's) and a heavy ender's target flying with ghosts:

![](img/ps-block-protagonist-hits.jpg) ![](img/ps-block-protagonist-blocks.jpg) ![](img/ps-fly-rival-flies.jpg)

## Known weak spots

- The staged fighters do not lunge, so the tech echoes sit behind a standing body; with Animation's real previous pose they will follow the strike.
- The fist path is a straight guard-to-contact estimate and the contact is on the victim's front at a region height, not where the real fist ends.
- The fly's ghosts are the weakest read: flat filled figures at the target's earlier positions; the prototype's stretch (the body itself elongating) is not possible from a draw layer and wants Animation's squash and stretch on the target.
- Rendering's own contact sparks and rings still fire on a hit; this adds to them. Whether it should replace them is the EP's and Orb's call.
