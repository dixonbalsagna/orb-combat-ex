# The wall slam without ping-pong (World, 2026-11-06)

Orb's third play, in the controller vision (`docs/ep/proposals/controller-vision.md` section 4, city step one): "The fighter that collided with a building bounced back into the plane we were fighting on like a ping pong ball. I was hoping I'd see the camera angle change and then be able to press the fight into the city." This is the World half of step one: what a face that holds him does. The turn on impact is Encounter's (below).

## What a wall does today (`sim/world/brunt.gd`, `hit`)

A building that holds a tower-struck body (a tier-1 send at a tower, or any send at a face that does not break) is a wall:
1. **The whole fight freezes**: the hit-stop (0.35 s, `STOP_FIRST`) and then the lodge's seconds (`lodgeSeconds`, 0.5 s at tier 1 to 0.9 s) as a world hold (`lodgeHold` "world"): **0.50 s measured**, frozen right after the hit.
2. **He is thrown back at a quarter of his speed** (`f.vx = -dir x |vx| x 0.25`, hard-coded): 1,154 units off the face on average within 90 ticks, in 16 of 16 slams.
3. **His depth snaps home in a third of a second** (`stepZ`: `z *= 0.001^dt`; DirPlane's ease after he lands): home in 53 ticks.
`lodgeHold` "body" is built (only the struck fighter is stunned; the fight goes on) but alone it makes the ping-pong worse: the body flies off while the fight runs (1,154 units, same), and the 0.35 s hit-stop still freezes everything (0.3 s).

## The switch and the data (all in `data/biomes/brunt.json`; defaults are today)

| Key | Today | Set | What it does |
| :--- | :--- | :--- | :--- |
| `lodgeHold` | `"world"` | `"body"` | only he is held (stunned for the lodge's seconds); the fight goes on. Existing. |
| `wallRebound` | 0.25 | **0** | the share of his speed that comes back off a face that holds him. New. 0: he stays at the face (he slides down it under gravity). |
| `wallStop` | 1.0 | **0** | the share of the building hit-stop a wall freezes the whole fight for. New. 0: nothing freezes (the hit-stop of a through-hit or a chain is unchanged). |
| `wallDepthHold` | 0 | **1** | with `lodgeHold` "body": his depth stays at the face for the hold (`Fighter.wallZ`), then eases home as today. New. |
| `repeatMarks` | 0 | **2** | the building's memory (existing, built, off): each send that struck it is one tier higher for the next, at most two, so repeated slams break it. |

Everything else is untouched: `wallSlamMul` 2, `wallStaggerTicks` 24, the ladder, the lodge, the wall kick.

## Before and after, on a seeded set (`WALLHOLD`: seeds 1 to 8 x tiers 1 to 3, a send at a 9 to 15 floor tower on the front street; 16 of them hold him)

| | Today | Set as above |
| :--- | ---: | ---: |
| Whole fight frozen at the hit | 0.50 s | **0.00 s** |
| Pushed off the face while he is stunned (mean; more than 150 units in) | 1,154 units (16 of 16) | **18 units (0 of 16)** |
| Depth back on the line | 53 ticks | 41 ticks (held about 30, then the ease) |
| Three sends at one tower, 24 towers, towers brought down | 0 | **24** (repeatMarks 2) |

The ladder of settings, for choosing: `lodgeHold` "body" alone (0.3 s frozen, still thrown 1,154 units); plus `wallRebound` 0 (0.3 s frozen, 18 units, stays); plus `wallStop` 0 (nothing frozen); plus `wallDepthHold` 1 (depth held). Every row is in `WALLHOLD` and the neighbouring checks (`wall`, `brunt`, `repeat`, `switchon`, `through`, `interior`, `wrecks`).

## What it takes

- **World's** (`wall-hold.diff`): `brunt.gd` (the three keys' defaults, the rebound, the hit-stop share, the hold, `stepZ`), `brunt.json` and its schema, the new check `wall_hold_check.gd` (`WALLHOLD`) and its line in `tools/world-checks.json`.
- **Grants** (`grant-core.patch`, 7 lines, none changes a hash while `wallDepthHold` is 0): `sim/core/state.gd` (`Fighter.wallZ`, one line); `sim/core/hash.gd` (one value, hashed only while non-zero); `sim/core/wounds.gd` (the counter runs down with the stun, two lines); `sim/director/plane.gd` (`_held`: one condition, so DirPlane does not ease him off the face).
- **Golden: unchanged** (parity on the tree with these two files: "golden check passed"); with every key at its default nothing moves. With the keys set, a match that holds a body at a wall hashes differently.

## Not done, and for whom

- **The turn on impact** is Encounter's (`DirSwing` atImpact). What World can give it: the lots carry the street's along-axis `t` and across-axis `s` (`S.fieldRecs`, `k` "lot", the building's lot by place and row); the fight's line is the frame's great circle; **at the start every front-street building lies on the line (the angle of its street to the line is 0 to the sine's third decimal, 80 of 80)**, so the turn toward "the street behind the building" is the lot's across-axis `s` at the struck building, in the frame's terms. I can build it as a pure read, `WorldStructures.streetAxis(S, bi)` (the sine of the lot's along-street axis to the line at the building, signed, and the same for the across-axis), about 25 lines and a check, once Encounter says the form it wants (a signed sine, as `lineSin`, or an angle).
- **Bystanders:** nothing changes while RL-247 holds (a held body does no more damage than today's: the wall slam is `wallSlamMul` as before).
- **Which hold is felt best** (Game Design's "brief" and "pinned" holds) is a playtest; `lodgeSeconds` is data.
