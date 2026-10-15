# The tenth round's moves, the moveset distinction, and the interjection's tell (Animation, 2026-10-15; parked)

Owner: Animation. Brief (the EP): (1) Game Design's tenth round (`docs/design/brawl-second-pass.md` section 14): the chase, the cash-in, the duel's riposte and amplified send, the light's held hit: what each needs as poses and layers, and build what can be built from existing pieces. (2) The moveset distinction (`fighter-pipeline.md` section 8): fluid arcs for one, snappy lines for the other, inside the fixed lengths; ease profiles per fighter and a before and after clip. (3) The interjection's tell: a pose for the ring guard while he winds up. **Built and gated in scratch, parked as one patch (`docs/animation/pending/tenth-round.patch`, README there); nothing in the tree.** Render side only. Every number is a first value.

## 1. The tenth round, move by move

| Move | What it needs | What exists | Built (parked) | Cue or field needed from the sim |
| :--- | :--- | :--- | :--- | :--- |
| **The held hit** (a light's hit holds: the fist stays planted, his flinch hangs, the hand shines while the window is open) | A held contact; a flinch that hangs and lets go; a shine on the hand | The plain light's pin (6 ticks, on) holds the hand on him | **The flinch hangs**: a light's reaction is kept at its peak for the length of the attacker's pin, then lets go (`hang`, read from the attacker's pin). **The hand shines**: `hand_shine` (0 to 1) and `hand_shine_limb` while the window is open, for VFX and Rendering to draw. Live: a tapped X's hand shines at 1.00 | None: it reads the hit event and the attacker's own pin |
| **The chase** (his own send; drawn travel; a beatdown in the air of up to six blows; the rival's tech) | Travel (the follow, drawn every tick); a body laid forward along it; air blows; the rival's answer | The zip's travel and view; the flight lead; the air stance; contact solve on a body in the air | **The dive**: `rt.chase.dive` mixed over the travel from the start cue to the end cue; **the air tech**: `rt.air_tech`, thrown open and then tucked, 14 ticks (a `fit` sequence). The blows are ordinary beats in the air | A cue **`chase`** with text `start`, `blow` (with `n`, the blow's number) and `end`; a cue **`tech`** to the rival |
| **The cash-in** (RT + B inside a perfect window: a heavy at once, 25 ki, can't be perfect-blocked, ends the chain) | A heavy with no tell, readable as instant | The `super` row's follow-through and ghosts | A beat that says **`cash_in: true`** plays the `super` row with a 2-tick load, no snap, no sink; `press.cash_in` is set for VFX's flash | The beat field `cash_in` |
| **The duel of perfects: the riposte and its amplified send** | The blocker's riposte (a blow in kind); the attacker's blocked recoil; a send that grows by level | The riposte layer (`_rip` beats), the stagger cue `perfect_block`; the hit reaction | **The amplified send**: a hit's `duel` level (absent today) raises the reaction's force ceiling by a fifth a level to level 8 (a quarter further, as Game Design has it, is the sim's; the body shows what it is given) | The damage event's field `duel` (an integer level) |

**What it does not do, and why:** the chase's travel is the sim's position, drawn by the zip's view (Z2) as today; I did not add a second travel. The riposte's own pose is today's riposte; a "perfect block of a perfect" is the same block with the same stagger. The mood's units and the camera's close-in are not mine.

## 2. The moveset distinction: ease per fighter, inside one clock

`fighters.json` gains an `ease` block per fighter: overrides of a press-style row (`prof` merged key by key, any other key replaced), read by `AnimFighter._style_row`. **The clock does not move**: the wind-up, the contact tick and the length of every row are the sim's and the cue's. Inside the length the ease changes how the blow arrives and leaves. Asserted (`_test_round10`): the hold, the follow and the return of each row sum to the global row's, for both fighters, in all four rows.

| Row | Global | The Protagonist (fluid) | The Anti-hero (snappy) |
| :--- | :--- | :--- | :--- |
| `speed` (X, a light) | hold 0, follow 4, return 7, overshoot 0.22, carry 5, twist 0.16 | follow 5, return 6, **overshoot 0.32**, carry 6, twist 0.22, lag 0.8 | **hold 1**, follow 3, return 7, **overshoot 0**, carry 2, twist 0.08, load ease 2.0 (a dead stop) |
| `burst` (held X) | hold 0, follow 4, return 7, overshoot 0.22 | **circling palms**: follow 5, return 6, overshoot 0.35, carry 6, twist 0.30 | **piston jabs**: hold 1, follow 2, return 8, overshoot 0, carry 1, twist 0.04 |
| `medium` (Y) | hold 3, follow 5, return 5, overshoot 0.08 | follow 6, return 4, overshoot 0.14, twist 0.1 | hold 4, follow 4, return 5, overshoot 0 |
| `super` (B) | hold 8, follow 8, return 8, overshoot 0.12 | **no ease**: the heavy's follow-through is where the last pass already pulls hardest (a longer follow on the Protagonist's knee read 57 degrees on one frame), and a heavy is thrown the same way by both | the same |

**Not eased:** energy in reach (a bolt or a blast keeps the global row: its tests and Legal's e09 read it) and the heavy (above).

**What this gives, and what it does not.** The same piece reads differently on the two bodies: the Protagonist's follow-through carries on and turns, the Anti-hero's stops dead. **What a fighter throws** (the palms against the jabs) is Combat's pool, not an ease; the burst's palms circle because the row twists more and carries further, the pistons stay in line because the row has no overshoot, a one-tick hold and a short follow. `RenderAnim.fighter_ease` (true) is the switch.

## 3. The interjection's tell

Encounter's windup cue `interject`, naming the guard, its landing tick (`n`) and its length (`dur`, in ticks); there is no blow cue. `on_windup` keeps it as `interject` and **`_waiting_layer` draws the tell**: the guard stops circling, plants, and shows `rt.interject.tell` (the weight forward on the front foot, the rear hand drawn back at the shoulder, the chin down on the one), in over the first 45% of the length, held to the landing tick, out over the 4 ticks after. It is a chamber, so the tell is a plain read at fight size: the one sees which guard is coming and when. `waiting_kind` is `interject` for the length. Tested on stand-in bodies (22 ticks shown on an 18-tick cue).

## 4. What the sim and Encounter must send (the whole list)

| Cue or field | Where | Text and fields |
| :--- | :--- | :--- |
| `cue` kind `windup`, text `interject` | the guard (the cue's actor) | `n` the landing tick, `dur` the ticks of the wind-up |
| `cue` kind `chase` | the chaser (actor) | text `start`, `blow` (with `n`: 1 to 6), `end` |
| `cue` kind `tech` | the rival who techs (actor) | none |
| the beat field `cash_in` | the strike beat of the cash-in | `true` |
| the damage event field `duel` | the duel's amplified send | an integer level (0 or absent: none) |

Nothing is read until it is sent: every one is inert today (the poses and the handlers are baked and unreached), and `hang` and `hand_shine` come from the hits and the pin that exist.

## 5. Gates and the clips

On a scratch export of main d5a2bd6f with Encounter's pass-2 park, the seventh round and both earlier patches plus this one: `anim_check` **passed** (seed 4, 2400 ticks; the new `_test_round10`: the ease keeps each row's clock, fluid against snappy, the cash-in's 2 ticks, the held hit's hang, the air tech, the interjection's tell for 22 ticks, the chase's dive and its clearing; and a tapped X's hand shines at 1.00), `joint_scan --strict` 0 of 900 poses and 0 on screen, `lead_scan --strict` 0 feet first and not a tumble, `held_scan --strict` 0 fail, determinism plain and `-- --intro --seeds=2 --ticks=900` passed, the flash count passed in 56 runs, `lead_scan` and `joint_scan --strict --bodies=4` clean (96,000 and 48,000 fighter-frames). Three things the gates caught on the way: the heavy's longer follow read 57 degrees of pull on one frame (the heavy has no ease), the bolt run's heads and forearm angles moved (energy keeps the global row), and the burst test's arm distance (that test runs with the ease off).

Clips (this PC only, Tools' launcher, `art/animation/review/nine-cells-look/`): `ease-xmash-protagonist-before-after.gif`, `ease-xmash-antihero-before-after.gif`, `ease-xhold-protagonist-before-after.gif`, `ease-xhold-antihero-before-after.gif` (a mashed and a held X, each fighter, before on the left and after on the right; fight distance, 3.0 to 3.9 MB), and the three cue scenes `cue-tech.gif`, `cue-chase.gif`, `cue-interject.gif` (1.1 MB each: the air tech, the chaser's dive from tick 10 to 50, a guard's 24-tick interjection tell; the guard is the left body).

## 6. For others

- **Tools (schema):** `fighters.json`: `ease` per fighter (a map of style to `{prof, carry_ticks, twist, ...}`); `pair_live.json` shared names `round10`; the wave `round10` (prefix `rt`).
- **VFX:** `AnimFighter.hand_shine` and `hand_shine_limb` (the held hit's glow), `press.cash_in`, `tech_cue`, `chase_state` and `chase_n`.
- **Encounter:** section 4's list.
- **Combat:** the burst's pool for each fighter (palms and jabs) is the part of "circling against pistons" that is a piece and not an ease.
