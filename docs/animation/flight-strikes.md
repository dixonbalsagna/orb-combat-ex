# Flight strikes, built (Animation, 2026-11-07)

The plan is `flight-strikes-plan.md` (which key set covers which of the five paths by three blows). This is what was built, and what the build changed in the plan. Parks against main, inert until Encounter's flight strike sends a path (nothing sends one today).

## What the plan got wrong, and what that saved

- **The tells need no profile rows.** The body takes the blow's wind-up from the beat's own `windup` argument, so Encounter sending 6, 10 and 14 (and 4 for a chained one) is all it takes. Checked on the real solve, both fighters: an X piece, a medium and a super piece each reach their contact on the sim's tick at 6, 10 and 14, and a chained 4 does too (`_test_flight_blows`).
- **The loop is a hump, not a circle.** The sim's arc is a bowed rush (`Rush.arc`, a parabola), so the body never turns more than about 1.25 rad along it: no somersault layer is needed. What the arcs did need was the tilt itself: the zip's orient stops at 1.2 rad and is gated off under 700 units a second, which a close arc is.

## What was built

| Piece | What |
| :--- | :--- |
| The loop's tilt | **Only for a flight strike's arc** (the zip cue's text names the path, `over` or `under`: `AnimFighter.flight_loop`; nothing sends one on main, so it is inert today: the pop, the recoil flips, the stance circle and the zip's passes are bowed rushes too and keep orient's own numbers, a test holds that). `AnimZip.orient`: a rush bowed by `loop.bow_min` (20) or more tilts up to `loop.max` (1.45) at `loop.rate`, from `loop.speed` (150: a close loop is slow), and eases toward level (`loop.level` 0.8 within `loop.level_ticks` 3) round the blow's contact so the blow is not thrown mid-turn. Data: `zip.json` `loop`. A rush with no bow, or under the minimum, is unchanged |
| The arc under's heavy blow, one a fighter | `pl.skim_heel` (the Protagonist: the edge of the foot swung through at shin height from a low skim) and `rl.slide_knee` (the Anti-hero: the knee into the legs), heavy, tell 10 |
| The parting shot's light blow, one a fighter | `pl.trail_backhand` (the blade of the hand swung out over the shoulder as he goes) and `rl.trail_elbow` (the point of the elbow thrown back), light, tell 6 |

The four are named pieces (found by the beat's `piece`, in no pick list), in waves `protag14` (prefix `pl`) and `rival11` (prefix `rl`), listed in each fighter's `more`. pose_lint 0 issues on all of them. Legal's lines: hands open or clawed for him, fists for the Anti-hero, no leap (the body skims), no clasp, nothing held.

## Checks

- `_test_flight_loop`: both fighters, an arc over (up on the rise, level at the blow, down on the fall, peak past the old 1.2) and an arc under (down on the way under, level at the blow, up on the way out), nothing past a limit, a straight rush never tilts more than a loop.
- `_test_flight_blows`: the four named pieces resolve and play whole at their tell, and the tells 6, 10, 14 and a chained 4 reach their contacts.
- Clips (local, `art/animation/review/flight-strikes/`): A is main, B the new looks, LT, the stick's direction and X or Y drawn at the frame edge, **staged by hand on the idle dummy** (the sim's flight strike is not in the tree): an arc over with X, an arc under with Y (the new heavy blow against today's standing roundhouse), a parting shot with X. Stills for Legal of the arc over's rise and top, the arc under's blow and the parting shot's blow, both fighters, are in `legal/`.

## Not done

- A path word on the zip cue's `text` (Encounter's): `over` or `under` switches the loop's tilt on for that rush; until it is sent the loop is off. (The arc's centre is not needed: the tilt is read from the rush's own bow.)
- The line and the zip look as they do today (the zip's far-side pass and the fighter's own key sets); no new work was needed.
