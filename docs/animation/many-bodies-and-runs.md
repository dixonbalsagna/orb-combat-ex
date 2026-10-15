# Many bodies, the lead scan's five frames, and the runs' look (Animation, 2026-10-15; parked)

Owner: Animation. Brief (the EP; Orb, 2026-10-15: "the depth and breadth of animations and mechanics continually refined and enhanced in preparation for multi-fighting and improvements to the dynamic fight choreography"). **Built and gated in scratch; parked as two patches in `docs/animation/pending/` (README there), not in the tree** (main is frozen for the demo's flash run). Render side only: no sim file is touched and no hash moves. Every number is a first value.

## 1. The lead scan's five frames (Encounter's seventh round)

On the chain with the charged-medium park (`nine-cells-pass2`: `r2.cjs`, `schema10.cjs`, `s7.cjs`), `lead_scan --strict` read 5 feet-first frames of 8,002 fast. None was the charged medium's own blow: they were four real gaps in the lead layer that the new matches reached. In `many-bodies.patch`:

| Frames | What it was | Fix |
| :--- | :--- | :--- |
| seed 7 tick 2239: a quick get-up, 617 units a second, a charge's lean still on him | The agency charge hold faded out over 0.15 s after the knock-down, and the get-up ran inside it | A charge hold is ended in 3 ticks by a launch, a drop **or a knock-down** (`_ag_fast`) |
| seed 5 ticks 1157 to 1158: a lip launch at 1,800 units a second, the body laid the wrong way | The flight lead turns at 6 a second: a body flying at 1,800 needed 10 ticks to come round | The turn is faster in step with the speed (up to 4 times from 700 to 2,100 units a second): aligned in a few ticks |
| seed 5 tick 1732: a bounce at 1,300 with the heavy's charge pose still held | The same: the first frame of a fast flight | The same; and the charge hold now goes at once (above) |
| seed 9 tick 663: a knock-back drift at 829 on his feet, leaning back 52 degrees | The stand-up to a tilt of 35 degrees used a rate of 45 a second (half a turn in the first frame) | `flight.json` `tilt_rate` 45 to 150: one frame brings it under the line |

Read on the same park with these: `lead_scan --strict` **0 feet first and not a tumble** (137 in a tumble, allowed), `joint_scan --strict` 0 of 896 poses and 0 on screen.

## 2. N bodies (one versus many; nine-cells-look.md section 5, Camera's `one-v-many.md`)

What was built, from poses that exist, and what it was read against:

| Piece | What it does |
| :--- | :--- |
| **`AnimFighter._opponent`** | "the one in my exchange, else the nearest" (shortest arc, and depth when it is on). With two bodies it is the other one, always (asserted every tick of 120) |
| **The waiting repertoire** (`_waiting_layer`) | A body that is in the fight and not the partner (the match has more than two, an exchange is running and it is not his) goes round a 90-tick wheel: **circle** (a shuffle of small steps), **guard** (hands raised), **step in** (one pace toward the partner's rival and a lean), **settle**; **one interjection at most every 1.5 s**, by Encounter's model. A **flinch** when a blow lands on one of the two in the exchange within 400 units. Poses: `stance.defensive`, `stance.aggressive`, `move.step_f/b`, `react.flinch_b`. `waiting_kind` says which |
| **`AnimMany`** (new, `anim_many.gd`) | Stand-in bodies about the real pair (the third far off: the camera's marker case), made once, placed, ticked and solved with the pair, and **taken out of `S.fighters` before the sim next runs**. The sim is two long today; this is how a scene or a scan has three to five bodies without a sim change |
| **Scans** `--bodies=N` | `lead_scan` and `joint_scan` accept `--bodies=2..5` |

**Read:** `_test_many_bodies` in `anim_check` (two stand-ins for 300 ticks: each looks at the nearest, the exchange's two are still each other's rival, the repertoire shows 271 circle, 95 guard, 73 step-in and 103 settle ticks, no joint past a limit, no NaN); `lead_scan --strict --bodies=4`: **96,000 fighter-frames, 0 feet first and not a tumble**; `joint_scan --strict --bodies=4`: **48,000 live fighter-frames of 4 matches, 0 reach the screen past a limit**.

**What it does not do (and whose it is):** a real fourth body in the sim (Simulation: `S.fighters` is two long and the exchange is a pair); the guards' own look (a type's shape row and tier 1: `fighter-onboarding.md`, 4 to 6 days a type, not a guard); two bodies overlapping in the ragdoll (Rendering and the sim); the camera's marker for a far guard (Camera's paper). The cost a frame is still what `nine-cells-look.md` section 5 said: about 0.4 ms a body.

## 3. The runs' look (`runs-look.patch`; the nine cells' look audit, items 4 to 7)

| # | Cell | What | Data | Read |
| ---: | :--- | :--- | :--- | :--- |
| 4 | X mashed, Y mashed | **The mash presses**: a forward lean that grows with each blow of a run (gaps of 10 ticks or less for a light, 18 for a medium), 2 degrees a blow to 10 (3 to 14 for a medium), a dip of the head; gone 10 ticks after the last blow. **Not on energy pieces** (Legal e09: the heads stay a hand's width apart; the bolt run's heads read 20 and 22) | `styles.speed.press_run`, `styles.medium.press_run` | A mashed X leans in (at least 0.08 rad), a tapped X does not (0.00); a mashed Y leans (at least 0.1 rad) |
| 5 | Y mashed | **The windmill**: the medium's carry runs 8 ticks (was 4): the follow-through of one blow becomes the wind-up of the next, so consecutive mediums flow | `styles.medium.carry_ticks` 4 to 8 | Every contact solved (windups: 104 judged, 0 contact errors) |
| 6 | Y tapped, Y mashed | **The held breath**: the medium's chamber is reached 2 ticks early and held in plain sight before it is thrown | `styles.medium.breath_ticks` 2 | The same checks |
| 7 | B mashed | **The march**: a heavy that follows another within 140 ticks takes a footfall: 5 units forward and a dip of the legs (0.3 of the squash pose) at the contact; `press.march` is set for VFX's dust | `styles.super.march` | A second heavy marches (1.00); a lone one does not (0.00); both solved, 0 NaN, 0 on screen |

**Switches:** `RenderAnim.mash_press` and `RenderAnim.march` (true; false is the before). The held breath and the windmill are data (0 and 4 are the before).

## 4. Gates (scratch export of main d5a2bd6f with the pass-2 park, the seventh round and these two patches)

`anim_check` passed (one failure on the first run, the energy run's heads, fixed above; re-run in the batch below), `joint_scan --strict` 0 of 896 / 0 on screen, `lead_scan --strict` 0, `held_scan --strict` 0 fail, determinism plain and `-- --intro --seeds=2 --ticks=900` passed, **the flash count passed in 56 runs**, the four-body lead and joint scans clean.

## 5. For others

- **Tools (schema):** `styles.<style>.press_run` (`gap`, `deg_per_blow`, `max_deg`), `styles.<style>.march` (`gap`, `step`, `dip`, `dip_ticks`), `styles.<style>.breath_ticks` (integer ticks); a changed value only: `medium.carry_ticks` 8, `flight.json` `tilt_rate` 150.
- **VFX:** `press.march` on the contact of a marching heavy (a footfall's dust); `AnimFighter.waiting_kind` if a guard's circle wants a marker.
- **Simulation and Encounter:** nothing needed for the look; for real N bodies, `S.fighters` longer than two and an exchange that may name a non-partner. `AnimFighter._opponent` and `_waiting_layer` already read the exchange's A and D.
- **Camera:** a body that is a stand-in is solved like any other; the marker rule is yours.
