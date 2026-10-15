# The nine cells: what the body does, how readable the three styles are, and what would make each its own

Owner: Animation. Date: 2026-10-14. Brief (the EP; Orb's direction of 2026-10-13: "the three face-button striking styles (mash, timed, hold) across each face button feeling responsive, useful, and visually engaging each in their own way"). Render only; nothing here changes the sim. Combat does the same from the move side (`docs/combat/`); this is the body's side. Every estimate is marked ~ and is in days of Animation's working time.

## 0. In short

- On main the **button** reads at fight size (its wind-up is 2, 12 or 28 ticks and the body is its own length), but **the three styles of one button mostly do not**: X tapped, mashed and held are the same light on the same row; Y tapped and mashed are the same medium; B tapped and mashed are the same heavy. What differs is rhythm, not the body.
- **Held B is the one cell with a look of its own** (the body sinks 9 units and coils, a shudder at full). Held Y is a tap until pass 2.
- At fight size (a body about 85 pixels tall at 800 by 450) a **tapped B is an arm drawn back and nothing else**: the tier's 28-tick tell is limb-only (the body drops 0.1 units), so the biggest, slowest blow of the game is the least visible one. That is the cheapest large gain in this paper (section 3, number 1).
- Seven cheap changes make the nine cells visibly different. The first three are about 2 days together.

## 1. How it was measured

- **The numbers:** the live brawl on main (3dda977f, a scratch export), a scripted pad on slot 0 against the medium AI, each cell pressed its way (tap 2 to 4 ticks, mash 3 on and 4 off, held to its long press), every blow read from the body's own record: style row, key set, the wind-up's length as the player sees it, the phases (load, release, contact, hold, follow, return), the reach of the hands and the drop of the pelvis. One match each (seeds 21 and 33); pieces differ by cell and by draw.
- **The stills:** the same rows on the study scenes (`flurry_study`: `xtap`, `xmash`, `xhold`, `ytap`, `ymash`, `yhold`, `btap`, `bmash`, `bhold`; the three taps are new) at the **fight-distance camera**, one tick a picture, through Tools' launcher (`node tools/machine/capture.mjs frames --session animation`, hardware, one at a time, nothing left running). The review sheet is `art/animation/review/nine-cells-look/cells-sheet-fight-size.png`: nine rows in the order of the table below, eight pictures each, from the wind-up to the return (uncommitted, this PC only).

## 2. The audit

| Cell | Style row and what the body does | Phases the player sees (ticks) | Reach / drop (of 75) | At fight size |
| :--- | :--- | :--- | :--- | :--- |
| **X tapped** | One light, `speed`; a different piece each tap (front kick, hook, snap round). Arm or leg out and back | load 2, release 3, contact 1, follow 2, **return 7**: about 15 | 2 to 14 / 0 | A crisp, clean return to guard. The return is its only signature |
| **X mashed** | The same row, a piece changing every blow (kick, knee, palm, elbow, hook, cross); the next blow cuts the return | load 2, release 3, contact 1, follow 1 to 2: a blow every 6 to 7, **no return** | 0 to 14 / 0 to 0.2 | Reads as "many small blows". The variety is good; the body is still |
| **X held** | One light as a tap, then `burst`: a set pose (drops 3 to 6 units for a beat), then more lights with gaps of 6 slowing | the same 2, 3, 1 each | 0 / 3 to 6 | **Same as a mash.** Only the pause (the set) and the even rhythm differ |
| **Y tapped** | `medium`, 12 ticks of wind-up in plain sight (the sim's own); a haymaker, a crescent kick, an uppercut | load 9 to 11, smear 1, release 3, contact 1, hold 2 to 3, follow 4 to 5, return 7 to 9: about 28 | 10 to 17 / 1 to 4 | One bigger blow. The wind-up is an arm back |
| **Y mashed** | The same row, wound in sight each time; consecutive mediums overlap | load 10 to 11, then contact, hold 1, follow 1: about 14 a blow | 0 to 17 / 1 to 4 | **Same as a tap, repeated.** No continuity from blow to blow |
| **Y held** | A tap that starts late: held 16 ticks it goes by itself (the charged medium is pass 2's) | = tap | = tap | **No look of its own yet.** The hold poses (`ch.y_*`) and the charge's tremble are built and waiting |
| **B tapped** | `super`, 28 ticks of tell (limb only), a piece from the tier (edge, blade hand, ...) | load 28, smear 2, release 1, contact 1, hold 7, follow 10, return 11: about 60 | 6 / **0.1** | A long stillness with one arm drawn back. Readable as a long wait, not as a heavy |
| **B mashed** | The same heavy again, one every about 90 ticks (the recovery, the tap rule, armour) | = tap, repeated | = tap | **Same as a tap.** No advance |
| **B held** | The coil: the chamber held, the body sinks and winds for 42 ticks, a shudder at full, then the release | load 28, hold 42, release 1 | 0 / **8.9**, coil 1.0 | **Its own.** The only cell where the whole body changes |

## 3. What would make each cell its own, ranked by value for cost

| # | Change | Cells | ~Cost | Value | Notes |
| ---: | :--- | :--- | ---: | :--- | :--- |
| 1 | **The heavy's tell sinks.** The tier's pieces take `squash_w` 0.3 to 0.4 and a hips drop of 6 to 9 over the 28 ticks (data, per piece), the lean back of the held coil at a third | B tapped, B mashed (and the head of B held) | 0.5 to 1 | **High**: every heavy reads as a heavy from the first tick, and the held coil then reads as the same move taken further | Legal's limb rules are unaffected (sinking is not a raise); check against the held lint (h05) |
| 2 | **The held X digs in.** While the burst's stream runs the legs keep the set pose (wide, low, planted) and only the arms and shoulders move; each blow is a smaller arm action | X held | 1 | **High**: separates held from mashed without a number changing | A layer keyed on the `burst` row |
| 3 | **The plain light's pin** (built, off: `RenderAnim.plain_pin` or Encounter's `plain: true`): the hand stays set on him 6 ticks, then lets go over 3 | X tapped | 0 (a switch) | **Medium to high**: the perfect follow-up's window opens as it lets go, and a tap reads as a deliberate single blow against a mash's rattle | `hook-ready.md` section 7; the rival's chin-and-flourish is +0.5 |
| 4 | **The mash presses.** A forward lean that grows by 2 degrees a blow to 10 and a shoulder pump that follows the rhythm; the guard hand stays up; cleared when the mash stops | X mashed | 1 | **Medium to high**: a mash looks like pressure, not like six taps | The same layer serves Y and B mashes at larger values |
| 5 | **The medium's windmill.** The follow-through of one medium becomes the wind-up of the next (the carry exists: `carry`, 4 ticks): a continuous turn, one hand then the other, so a mash is a drum roll of full blows | Y mashed | 1 to 2 | **Medium**: separates mash from tap, the "grind" Game Design asked for | The work is the pose join between consecutive pieces |
| 6 | **The held breath.** A 2-tick hold at the end of the medium's wind-up (the `hold_ticks` data, the tell's last pose) so a Y reads "ready" before it is thrown | Y tapped (and held) | 0.5 | **Medium** | The same trick as the heavy's chamber |
| 7 | **The march.** Each mashed heavy takes a footfall (the heave's half step) and a stomp; the dust is VFX's | B mashed | 1 (+ VFX) | **Medium**: B mashed is an advance, not a repeat | Needs the recovery short enough to show a chain |
| 8 | **The charged medium** (pass 2): the hold poses and tremble | Y held | 0 (built) | **High once pass 2 lands** | Waits on Encounter |
| 9 | **A tell colour per strength** (VFX): the wind-up's rim, a flash at full | B held, Y held | VFX's | Medium | Not mine; the held coil's tremble is the body's half |

**The first three together are about 2 days and change the look of five of the nine cells.** Each is data or a layer; none touches the sim, a strike's length or its contact tick.

## 4. Grappling on A: what it would need from the rig

A grab is two bodies in one pose, held for tens of ticks, then a throw. What the rig has: the contact solve puts either hand on any region of any body (and a second limb, `limb2`, which the clinch's strikes and the zip's lift and throw already use); a **held layer** (built for the wound blow) that keeps a pose through the sim's wait; the zip's grab poses (`zp.*`: tackle, lift, throw); the victim's reactions, ragdoll and fall.

What it lacks, by pitch (Combat's three, sketched from the rig's side):

| Way | Needs from the rig | ~Days |
| :--- | :--- | ---: |
| **A clinch ender** (the clinch's strikes, then a throw that ends it) | A throw out of the existing locked state: 3 to 4 poses for each fighter, the victim's fall from the hand; nothing new in the solve | 3 to 4 |
| **A grab you hold** (a hold the grabber keeps for 20 to 60 ticks, the victim struggling, strikes or a throw after) | **A hold layer on the contact solve**: both hands pinned on regions for as long as the sim says, with the target moving; a victim "held" pose set (the legs hanging, the free arm's struggle; 4 poses, **size-aware**, since a throw's carry assumes R1's proportions); the grabber's strain (a lean back, a wide stance); the joint scan's new classes for a body carried | 6 to 8 |
| **A set of throws** (several, by direction and state) | Everything above, plus a throw per direction (4 to 6), each with a carry curve and the victim's flight from the release point; Legal's screen per throw (no clasp, no held raise) | 12 to 20 |

In all three: **the sim carries the victim by position** (the animation only draws it); the camera and the keyline need to read two bodies at one point; and a **grab that fails** (a dodge, a block) needs its own whiff poses (the `miss` set has the shape). Cheapest and first: the clinch ender, which reuses a state that exists.

## 5. Two elite guards beside the Empress: a third and a fourth body in a brawl

**What a body costs.** On the rig R1 a body is one skeleton (27 bones) and one mesh (about 2,500 triangles) with a keyline pass. The solve measured **about 0.38 ms a fighter** on this PC headless under load (4,802 solves a run); two more bodies are about 0.8 ms a frame on a desktop and about 3 ms on the phone class, of a 16.7 ms frame. The bake: a fighter *type* bakes his waves at match start (about 250 ms for a type's packs, once; two guards of one type bake once). A guard of a shared type needs no new rig.

**What assumes two.** `AnimFighter._opponent(S, f)` returns the first other fighter in the list, which is right for two and wrong for four: the facing, the gap, the contact target and the exchange's pair must read "the one in my exchange, else the nearest" (~1 day: one function and its callers). The cue dispatch is by fighter index and works. The pair poses (the clinch, the zip's carry) are two-body and the Empress is in one at a time; the others need a waiting repertoire (circle, guard, a flinch when a body flies past): ~2 days of idles and a "waiting" stance, from poses that exist.

**What each guard needs for his look:** the same as any fighter (`fighter-onboarding.md`): a shape row, a pose profile, tier-1 pieces (~4 to 6 days a type, not a guard). **Two guards of one type are one fighter in the data**, which is the cheap case; two different types are two onboardings.

**What the scans do.** The joint scan, the lead scan and `anim_check` walk every fighter of the sim; the seeded matches for them would need a four-body scenario (QA's, the brawl's pairing rules) and their frame count doubles, so the scans' wall time does: `lead_scan` is about 8 minutes a run today. The per-frame cost and the scan time are the two budgets to watch; neither is a barrier.

**What does not exist yet:** collisions between bodies in the ragdoll (a thrown guard passes through a standing one), the layering of four bodies in a split view, and the clinch's pairing with a third body near: Rendering's and the sim's. From the animation side: **about 3 to 4 days** for the opponent pick, the waiting stances and the checks, plus the guards' own look as above.

## 6. Built (2026-10-14, the EP's go on the first three; render side only)

| # | What | Where | Read |
| ---: | :--- | :--- | :--- |
| 1 | **The heavy's tell sinks.** The `super` row sinks by the piece's drive (`styles.super.squash_by_drive`: step through 0.35, turn 0.4, unwind 0.4, full turn 0.3, heave 0.15, fall 0.0: a fall rises to come down) | `press_styles.json`, `_press_body` | The pelvis sinks **7.6 to 8.8 units** over the 28 ticks on the tier's step, turn and unwind pieces (before 0.1); pieces already drawn low (`su_ram` 16.4, `su_hook` 14.4) are unchanged; the falls (`su_heel`, `su_drive`) do not sink (0.1, 0.7) |
| 2 | **The held X digs in.** Through a burst's stream the legs and pelvis keep the set pose (`styles.burst.dig`: weight 0.8, in 3, out 6 ticks, a blow of the foot or the knee keeps its legs); the check of the contact pose and the contact solve are untouched | `press_styles.json`, `_dig_in`, `RenderAnim.dig_in` | Held X digs in at 0.90; a mashed X 0.00 (`_test_cells`). The sheet's fourth row |
| 3 | **The plain light's pin is ON by default** (`RenderAnim.plain_pin` true): a brawl light that is the first of its string, no burst, no flurry, pins its hand on him 6 ticks, then lets go over 3. **No sim data file needs a change**: the live beat's own fields (`strength`, `flurry`, `k`, `burst`) say it | `render_anim.gd`, `_press_prof` | On the live X tap the contact weight holds 1.00 for 6 ticks and is gone by 9 (before: gone by 5); a mashed X does not pin. The sheet's second row against the first |

**Gates** on a scratch export of main (1ea5f963) with these files: `anim_check`, `joint_scan --strict` (0 of 896 poses, 0 on screen), `lead_scan --strict` (0 feet first outside a tumble), `held_scan --strict` (0 fail), `determinism` plain and `-- --intro --seeds=2 --ticks=900`, the flash count (`flash_worst.gd` and `check-log.js`: passed in 56 runs; no source asks the register). The study clip: `art/animation/review/nine-cells-look/cells-sheet-after.png` (ten rows: X tap without the pin, X tap with it, X mashed, X held, Y tapped, Y mashed, Y held, B tapped on a turn and an unwind, B mashed, B held; the before sheet is `cells-sheet-fight-size.png`; this PC only).

**New keys for the schema (Tools):** `styles.<style>.squash_by_drive` (a map of drive to a number 0 to 1), `styles.<style>.dig` (`w`, `lead`, `in`, `out`, `bones`).
**Switches:** `RenderAnim.dig_in` and `RenderAnim.plain_pin`, both true; false is the before.
