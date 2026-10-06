# The LT zip on screen (2026-10-05)

Orb's approved reference: `docs/ep/prototypes/lt-zip-v4.html` ("the zip prototype looks right, start building it"); the design is `docs/design/melee-press-feel.md` section 2c and Orb's notes in `docs/ep/vision.md` (the last two sections): the fighter zips to the rival, strikes and zips out again, to **any spot on a circle around him**, "in a stylistic blur, matching our visual cues we established for speed, tech and heavy". This is a first build behind the press styles' flag (`hub.press_enabled`, off by default, Shift+F7 with Animation's body). Code: `render/vfx/zip.gd` (state, cues) and `_zip()` in `render/vfx/shots_view.gd` (the shots view's one draw). Presentation only: it reads cues and fighters, draws no random number, writes nothing in the sim. Numbers are `VfxZip.DEFAULTS` (code; an optional `data/vfx/zip.json` is read if it exists, none is created, so no schema is needed yet).

## The looks

| Part | What is drawn |
| :-- | :-- |
| **The tell** (the wind-up ticks) | A thin line along the ground from where he stands toward the arrival point, brighter as the wind-up runs out, with a small tick where it ends. A heavy also gets its charge ring: hollow, thin, lane colour, shrinking onto the fist (40 to 12 units), only in the **last 10 ticks** of the wind-up (Legal m07). 2 quads, 3 for a heavy in its last 10 ticks. |
| **Speed, travel** | A smear of up to five soft filled ghosts on the path he really took (his recorded positions, `VfxPress.hist`), each **16 units behind the last** (two thirds of a 24-wide body, so each overlaps the next by a third), one flat lane-colour tint, 0.35 opacity at most for the nearest and fainter the older (0.35, 0.28, 0.21, 0.14, 0.07), and two streak bands (head and hip height). They are drawn behind him and only while he travels; a body that is not moving has none. About 27 quads. Picture: `zip-speed-in.jpg`. |
| **Tech, travel** | **The body travels** (the sim sets at least `max(4, ceil(distance in body heights / 3))` ticks each way; Legal RL-076); four wire echoes trail it, strung from where this leg began to the BODY, never ahead of him and never at the arrival point before he gets there, popping off one at a time from the back to the front (2, 4, 6, 8 ticks from the leg's start), and a thin line at head height fading over 10 ticks. About 21 quads falling to 6. The same on the way out, along the drawn path to the exit, which is its own leg after the strike hold. Pictures: `zip-tech-travel.jpg`, `zip-tech-out-over.jpg` (the body flying up over the rival, echoes trailing). |
| **Heavy, travel** | The same smear with heavier ghosts (one and a half times the stroke and head size, the same 0.35 cap) and one wide band. About 26 quads. A heavy goes out as a speed zip, as the prototype does. Picture: `zip-heavy-in.jpg`. |
| **The way out** | The same, along the path out, to the exit point. `zip-speed-out-up.jpg`: an exit straight up. |
| **The strike** | Nothing new: each blow is a `damage` event, so the press styles' marks per reading (the speed ring, the tech diamond, the heavy's double ring and crescent) draw as they do. |
| **Counter** (he is stopped on arrival) | A hard bar across his path where he is stopped (54 units, centred low on the body) and the counterer's mark (at most 26 units): a diamond for a tech counter, a double ring for a heavy one. 2 to 3 quads, 12 ticks. `zip-counter.jpg`. |
| **Caught** (a late counter catches him in reach) | A ring closing round his chest (26 to 14 units, under the face) and two brackets beside him. 3 quads, 22 ticks. `zip-caught.jpg`. |
| **Guard broken** | The shield line breaks into four fragments that fly out, with a small flash ring (22 units at most) low on the defender, in the lane colour. 5 quads, 14 ticks. `zip-guard-broken.jpg`. |
| **The grab lock** | No effect (UI's). |

**Any direction.** Every travel effect is drawn between two points, so a zip up, down, behind or round the rival draws along its own line: the ghosts sit on his recorded path (a curved path is a curved trail), the bands run from the oldest ghost to him, the tech echoes lie on the straight line between the start, the arrival and the exit point. `effects_check.gd` asserts a vertical and a diagonal zip each draw their band along the path.

## The cue (what I built against) and what I need extra

Built against Encounter's B0 cue (docs/camera/lunge-framing.md section 8): a `cue` event, kind `lunge_light` or `lunge_heavy`, `actor` (the zipper), `target`, `amount` = wind-up ticks, `n` = move ticks.

| Extra field | Meaning | If absent |
| :-- | :-- | :-- |
| `style` | `speed`, `tech` or `heavy` (the words mash, timed, held work too): the reading | `lunge_heavy` is heavy; a light lunge reads Animation's playing blow, else his press log (`VfxPress.read_style`), else speed |
| `hold` | ticks of striking (arrival to the start of the way out) | 14 |
| `out` | ticks of the way out | `n` |
| `ex`, `ey` | the exit point (world), anywhere around the rival | back where he started |
| `tx`, `ty` | the arrival point | the rival's place, 30 units short of him |

Outcome cues, `actor` = the other fighter and `target` = the zipper, each with an optional `style` (`tech` or `heavy`) for the counter's look: **`lunge_counter`** (he is stopped where he is: the strike and the exit are not drawn), **`lunge_caught`** (a late counter holds him in reach: same), **`lunge_guard_broken`** (`actor` = the defender whose guard broke). The grab lock needs none.

The ghosts and bands follow the fighter's real position, so they need nothing more from the sim than the zip actually moving him. When **Animation** exposes the body's path and previous poses (as for the press styles), the speed and heavy ghosts and the tech echoes become real earlier poses: the same hand-off as `press_pose` and `press_path`, and `_figure_j` already draws one.

## Cost against the budget

Quads only, in the shots view's one draw (cap 380): a tell 2 to 3, travel 21 to 27, an outcome mark 2 to 5, no debris. One zip draws at most about 27 (plus its strike marks, up to 27 for a heavy blow). Two zips at once and their marks stay under 110. Not measured: the web build under load and an old laptop.

## Reduced motion

Two ghosts and one band for speed and heavy (11 quads against 27), the last echo and the line only for tech; the tell, the outcome marks and the heavy's ring are as they are (single, steady). `effects_check.gd` checks the reduced count.

## Legal (docs/legal/zip-screen.md, RL-076 to RL-080; motion rules m01 to m08 in `movegen-banned.json`)

Applied 2026-10-05, the flag still off:

| Rule | What the code does |
| :-- | :-- |
| **m01** the body is drawn and opaque every tick | The body is the real fighter, drawn by Rendering; nothing here hides, fades or swaps it. The ghosts and echoes are drawn behind it (`zb`, 12 units behind the fighter plane). Not checkable in `effects_check` beyond that. |
| **m02** at least `max(4, ceil(distance_bh / 3))` ticks each way | The sim sets the ticks (Encounter). `VfxZip.min_ticks(distance_bh)` is the rule and every cue is checked against it: `hub.zip.violations` counts `short_in` and `short_out` for QA. The staging now sends 5 ticks for the tech zip. |
| **m03** the path is continuous, echoes trail the body, none at the arrival point before he gets there | The tech echoes are strung from the leg's start to the BODY's current place (`VfxZip.echo_points`), never to the arrival point; `effects_check` asserts each lies between the start and the body on every travel tick. |
| **m04** a far-side exit is its own drawn travel after the hold | The way out is its own leg (the echoes restart from the arrival at the end of the hold). Whether he appears behind the rival on the strike's tick is the sim's: the cue's `out` ticks and positions decide, and `violations` flags a short one. |
| **m05** ghosts: one lane tint, 0.35 or less and fainter the older, at most 5, on the real path, overlapping by a third, no ring or fan, gone within 8 ticks | `VfxZip.trail_points` places up to 5 on the body's recorded path 16 units apart; alpha 0.35 down to 0.07; one colour (the lane's, not darkened or tinted); drawn only in the two travel legs, so none outlives the zip. `effects_check` asserts the spacing, the count, the maximum alpha (0.30 with the bands) and nothing drawn the tick the zip ends. The press styles' heavy ghosts take the same cap and last 8 ticks (`ghost_life`), at most 5, fainter the older. |
| **m06** the body on top, no stationary copy | Ghosts are behind him; `trail_points` returns none for a body that is not moving. (The press styles' heavy ghosts stand where he was for their 8 ticks and then go.) |
| **m07** the heavy's ring: hollow, thin, lane colour, shrinking only, the wind-up only (10 ticks or fewer) | Drawn only in the last 10 ticks of a wind-up (the zip's and the press styles' alike), 2.2 units thick, shrinking onto the fist's place. `effects_check` asserts 2 quads early in a heavy zip's wind-up and 3 late. |
| **m08** outcome marks: no text, nothing on the face, no body-wide gold, white or red | No text anywhere. The counter bar, the caught ring and the guard-broken ring are centred 30 to 34 units above his feet and at most 26 units across (his face is above 62); `effects_check` asserts the marks sit within 40 units of his feet. The colours are the lane's (cyan, violet), never white, gold or red. |

**Legal's four effect flags for Combat's generator** (answered 2026-10-05, unchanged by the ruling): none of my effects is a piece, additive or a light; the nearest to `glow` are the speed reading's soft discs (a blur), to `energy_ball` the same discs (smeared along a path, never at rest in a hand), to `growing_orb` none (the heavy's ring shrinks, the contact rings are hollow), to `afterimage_hides_body` the tech zip's travel, now at least 4 drawn ticks with the echoes behind the body.

## Tested

`effects_check.gd` `_zip()` (and the press styles' wind-up case): off by default and behind the press flag; Legal's travel minimum and the count of cues that break it; echoes between the start and the body on every tick; ghost count, gap, alpha and lifetime; the heavy ring in its last 10 ticks; marks below the face; the cue's reading, wind-up, move, exit point, strike ticks and way-out ticks; the tell (2 and 3 quads); speed travel (27) and heavy travel (26); the vertical and the diagonal bands; a heavy leaving as a speed zip; tech with 5 ticks of travel, the echoes drawn during it and popping off after it, and the way out to an exit above and behind; a counter stopping the zip (2 and 3 quads), caught (3), guard broken (5) and the marks gone in their lives; reduced motion; off draws nothing.

## Known weak spots

- The ghosts are estimates of a body (a stand-in figure at his recorded positions); Animation's previous poses will replace them.
- The pictures are staged: the cue is sent as Encounter's will be and his position is scripted along the zip (the sim does not move him yet).
- At gameplay zoom the soft ghosts are faint against sand; the alphas are in `_zip`.
- The ground line is flat along the ground under him and under the arrival point; for an airborne arrival it does not rise.

## On the director's real cues (B0, 2026-10-05)

The real cue is `lunge_light`, `lunge_heavy`, `charge_light` or `charge_heavy` with `actor`, `target`, `text` (`lunge` or `charge`), `amount` (the wind-up's ticks, 0 for a charge) and `n` (the move's ticks). It carries no reading, hold, way-out ticks or exit point yet, so the defaults stand: a heavy cue is heavy, a light one reads the press log or Animation's blow, `hold` is 14, `out` is `n`, and he returns to where he started. A `charge_*` cue is a one-way flight: its tell and travel draw, with no strike hold and no way out. In three headless AI matches (seeds 4, 12345, 7; 5,400 ticks each) the director sent 20 lunge and 16 charge cues; each one's tell (the ground line and its tick) drew on the tick it started (`effects_check.gd` `_real()`).

Today's cue is the old mid-band lunge, not the LT zip, so its move is 3 to 20 ticks and `VfxZip.violations` counts the short ones (34 of the 36 cues): that is the count Legal's travel minimum (m02) will want at zero when the zip's cue replaces it.

## On the zip's own cues (Encounter's Z1, 2026-10-06)

The zip is live in the sim (docs/director/zip-z1.md), so the staged cue is replaced by the real ones and the zip's phases are **read**, not counted: `DirZip.read(S, f)` (read only: phase `tell`, `in`, `reach`, `out`, the ticks into it, the reading, the planned ticks; empty when the zip is over) sets each real zip's clock every tick, so what is drawn is the sim's truth even through a pause or a seek.

| Cue | What VFX does |
| :-- | :-- |
| `zip_light`, `zip_heavy` (`x`, `y` the ticks in reach) | Starts a real zip. The tell is a thin ground line to the arrival point (`DirData.contact()` offset, the same point the rush ends at), drawn along the terrain so a dune between never hides it, and a tick at its end; the heavy adds its hollow ring in the last 10 ticks of the tell. |
| (the way in) | The reading's own look: speed ghosts (two, behind the body, lane tint at 0.35 or less) and a band, tech wire echoes strung from the start to the body, heavy a wide band. At least 4 drawn ticks (RL-076, m02). |
| `zip_out` (text `home`, `far`, `point`; `x`, `y`; `n`; `amount`, `dur`, `k`) | The blow's mark at the contact, which differs for the two: a zip strike is one hard bar across the line of his approach, a zip heavy two bars side by side (the press look of the blow itself comes from the `damage` event as for any blow). The way out is drawn from `DirZip.read`'s out phase as its own leg: the echoes restart at the arrival and follow the bowed path, so a far-side exit reads as a drawn travel, not a vanish. |
| `zip_end` `countered` | The counter mark where he is stopped (the press diamond or double ring and a bar below the face). |
| `zip_end` `caught` | The caught ring closing and two brackets. |
| `zip_end` `shot`, `stopped` | A shot-down mark: four short hard spokes and a ring at the waist, the zip's travel cut that tick. |
| `zip_end` `down` | A flat ring on the ground under him, widening over 14 ticks (the dropped fall is Animation's). |
| `zip_end` `done`, `outrun` | Nothing: the zip simply ends. |

Legal f01 is now applied: `ghosts` is 2 (at most 2 ghosts of a limb, at most 4 drawn in all at any instant counting both fighters' zips), reduced motion draws 1. The press styles' tech echoes are still three per blow (the zip's own ghosts are 2), which is the one place f01's "2 ghosts of a limb" is a reading to confirm with Legal: the three tech echoes are one limb's after-image, each popping off in 2.5 ticks, never more than two alive at once on the zip.

Cost on top of the old zip: a real zip draws at most 24 quads (tell 13 on a long gap because the line follows the ground, way in 12, way out 19 to 20, a blow mark 1 to 2, an end mark 1 to 5), in the shots view's one draw. Headless, native, on a machine loaded by other sessions, `hub.consume` averaged 0.97 ms a tick while a zip and its blow played (it runs the whole hub, the blow's press look and debris among it; 0.08 idle) and `view.update` 35 us against 11 us idle. Not measured on the web build under throttle: the zip adds no draw call and no new pool, so the web cost is the 24 quads' fill plus that consume.

Stills (web build, headless Chrome, scratch stage hooks that start a real `DirZip`): `img/zr-strike-tell.jpg`, `zr-strike-in.jpg`, `zr-strike-blow.jpg`, `zr-strike-out.jpg`, `zr-heavy-blow.jpg`, `zr-counter.jpg`, `zr-caught.jpg`, `zr-shot.jpg`, `zr-down.jpg`. The tall pale oval round the zipper in several of them is the press look's limb ring, drawn since the press styles went on by default, not the zip's.

Known weak spots (Z1): the ghosts are still stand-in figures until Animation's previous poses replace them; the shot and down marks are drawn in the rival's lane colour, which is pale against sand; the `down` mark is faint on a ground the dune covers.
