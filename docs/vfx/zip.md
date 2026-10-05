# The LT zip on screen (2026-10-05)

Orb's approved reference: `docs/ep/prototypes/lt-zip-v4.html` ("the zip prototype looks right, start building it"); the design is `docs/design/melee-press-feel.md` section 2c and Orb's notes in `docs/ep/vision.md` (the last two sections): the fighter zips to the rival, strikes and zips out again, to **any spot on a circle around him**, "in a stylistic blur, matching our visual cues we established for speed, tech and heavy". This is a first build behind the press styles' flag (`hub.press_enabled`, off by default, Shift+F7 with Animation's body). Code: `render/vfx/zip.gd` (state, cues) and `_zip()` in `render/vfx/shots_view.gd` (the shots view's one draw). Presentation only: it reads cues and fighters, draws no random number, writes nothing in the sim. Numbers are `VfxZip.DEFAULTS` (code; an optional `data/vfx/zip.json` is read if it exists, none is created, so no schema is needed yet).

## The looks

| Part | What is drawn |
| :-- | :-- |
| **The tell** (the wind-up ticks) | A thin line along the ground from where he stands toward the arrival point, brighter as the wind-up runs out, with a small tick where it ends. A heavy also gets its charge ring shrinking on him (40 to 12 units, brightening). 2 quads, 3 for a heavy. |
| **Speed, travel** | Five stacked soft filled ghosts of him along the path he really took (his last positions, `VfxPress.hist`), fainter the older, and two streak bands (head height and hip height) from the oldest ghost to him. About 27 quads. Picture: `zip-speed-in.jpg`. |
| **Tech, travel** | No travel: four wire echoes of him along the straight line from where he began to where he arrived, popping off one at a time from the back to the front (2, 4, 6, 8 ticks), and a thin line at head height fading over 10 ticks. About 21 quads falling to 6. The same along the line out. Picture: `zip-tech-arrive.jpg`. |
| **Heavy, travel** | The same ghosts stretched wider (twice the stroke and head size, brighter) and one wide band. About 26 quads. A heavy goes out as a speed zip, as the prototype does. Picture: `zip-heavy-in.jpg`. |
| **The way out** | The same, along the path out, to the exit point. `zip-speed-out-up.jpg`: an exit straight up. |
| **The strike** | Nothing new: each blow is a `damage` event, so the press styles' marks per reading (the speed ring, the tech diamond, the heavy's double ring and crescent) draw as they do. |
| **Counter** (he is stopped on arrival) | A hard bar across his path where he is stopped, 96 units long, and the counterer's mark: a diamond for a tech counter, a double ring for a heavy one. 2 to 3 quads, 12 ticks. `zip-counter.jpg`. |
| **Caught** (a late counter catches him in reach) | A ring closing on him (38 to 16 units) and two brackets beside him. 3 quads, 22 ticks. `zip-caught.jpg`. |
| **Guard broken** | The shield line breaks into four fragments that fly out, with a flash ring, at the defender. 5 quads, 14 ticks. `zip-guard-broken.jpg`. |
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

## Legal

**Legal's four effect flags for Combat's generator** (`docs/legal/movegen-banned.json`, rows b09 and b13): the generator flags a piece, not a render effect, and my effects are drawn by the renderer from events, never by a piece. These are the effects that could be read as setting each flag, and what I would tell Legal:

- **`glow`** (a melee piece never carries light): none of mine is additive or a light source (the material is `blend_mix`, flat colour). The nearest are the **speed reading's soft discs** (a motion blur of layered soft discs along the fist, the press styles and the zip's speed ghosts have hard strokes) and the heavy's **filled crescent**. They are blur and smear, not light; if Combat's generator wants a flag, tag the speed reading as `blur`, not `glow`.
- **`energy_ball`**: none. The only round filled shapes are the speed blur's discs (smeared along a path, never at rest in a hand) and the wire head rings of the echoes. No effect forms a ball at the hand or in front of it.
- **`growing_orb`**: none. The heavy's charge ring **shrinks** onto the fist (40 to 12 units: the prototype's own), and the contact rings **expand** as hollow rings that fade, never filled and never held. If Legal reads the wind-up ring as a charging pose it is the one to look at; it never grows.
- **`afterimage_hides_body`**: the ghosts and echoes are drawn behind him (the speed and heavy ghosts) or as empty wire outlines (the tech echoes); the real body is drawn every frame. Two things Legal should see. (1) **The tech zip has no travel**: his body goes from the start to the arrival in the cue's `n` ticks (2 in the prototype), with only echoes marking the path. That is the nearest thing to a blink; b13 says "the fighter is drawn the whole way". I would make the tech's move at least 4 ticks, drawn, with the echoes along it. (2) **Filled ghosts**: Legal's dash afterimage rule (RL-052) says a thin outline, empty inside, half opacity at most, in the lane colour, no ring of copies, gone in 0.1 s. The speed and heavy ghosts are filled (Orb's "soft filled ghosts"), at most 0.35 opacity, in the lane colour, along the path and never in a ring, and last the length of the move (6 to 8 ticks). They need Legal's eye for the "filled" part; the wire (tech) ones meet the rule.

## Tested

`effects_check.gd` `_zip()`: off by default and behind the press flag; the cue's reading, wind-up, move, exit point, strike ticks and way-out ticks; the tell (2 and 3 quads); speed travel (27) and heavy travel (26); the vertical and the diagonal bands; a heavy leaving as a speed zip; tech with no travel, popping echoes along the line (21, 21, 16, 16, 11, 11, 6, 6) and the line out to an exit above and behind; a counter stopping the zip (2 and 3 quads), caught (3), guard broken (5) and the marks gone in their lives; reduced motion; off draws nothing.

## Known weak spots

- The ghosts are estimates of a body (a stand-in figure at his recorded positions); Animation's previous poses will replace them.
- The pictures are staged: the cue is sent as Encounter's will be and his position is scripted along the zip (the sim does not move him yet).
- At gameplay zoom the soft ghosts are faint against sand; the alphas are in `_zip`.
- The ground line is flat along the ground under him and under the arrival point; for an airborne arrival it does not rise.
