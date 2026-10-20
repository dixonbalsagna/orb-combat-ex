# The fight's feel in the director: recoil flips, ricochets, clashes (build notes, 2026-10-19)

Owner: Encounter Systems Director. This builds Game Design's `docs/design/fight-feel.md` and `rulings-2026-10-19.md` §2, one rule at a time, with QA's rows read between them. Combat's `docs/combat/choreography-feel.md` gives the pieces and the camera events.

| Rule | State | Park |
| :--- | :--- | :--- |
| 2a Recoil flips | built, behind `recoilFlip.enabled` (false) | `pending/recoil-flips/` |
| 2b Ricochets and wall kicks | next, after QA's flip row | |
| 2c Clashes and clash exchanges | after 2b | |

## 1. Recoil flips (2a)

**The rule as built:**
- **The window.** A knock-back opens it in `DirLaunch.knock`: the skid (4 bh and over on the ground, a journey), the upright slide, or the drift in the air. A dodge tap in its first 10 live ticks flips him out.
- **The flip.**
  - It ends the slide where he is.
    - A skid ends through World's `recoilEnd` (a grant). It pays and records the slide so far, and `journey_end` says `recoil`.
    - A slide or a drift ends by dropping its rush, and a bump it was heading for is cancelled.
  - He is carried 1 bh further back over 12 ticks, bowed 0.8 bh up, and lands set: on the ground, or steady at his height in the air. A wall behind him shortens the flip; the ricochet is 2b's.
- **The counter-rush.** His next blow within 20 live ticks of the landing is a counter-rush.
  - Its approach (`DirBands.begin`) has no crouch, no return and no first-move lock. It runs at 6,000 units a second, in 3 to 12 ticks, and lands as the lunge's arrival blow.
  - From the far band it flies in instead of taunting. In the close band there is no gap to rush: it is his blow.
  - While he is in the air his presses wait for the landing.
- **Free:** no ki and no cooldown. A press outside the window does nothing.
- **The flourish.** With no press, a knock-back on the ground over 3 bh ends in Animation's flourish. The cue says so at the knock, with the landing's estimate; a flip replaces it.
- **The AI** flips on 20, 45 or 70% of its knock-backs by level (Game Design's). It taps 3 to 7 ticks in, and follows a flip with a counter-rush on 50, 70 or 90% (mine, for Game Design), 2 to 8 ticks after landing. Its draws are keyed, so nothing else's draws move.

**The cue** (`cue` kind `recoil`, Combat's §6), sent at the knock (a flourish) or at the flip:

| Field | Says |
| :--- | :--- |
| `text` | `flip` or `flourish` |
| `source` | the exit: `backflip` on the ground, `tuck` in the air (a flourish is a `backflip`) |
| `actor`, `target` | who flips; the striker |
| `x`, `y` | where it starts |
| `amount` | where he lands (x) |
| `n`, `dur` | the landing tick; its ticks |
| `k` | 1 on the ground, 0 in the air |

`counter_rush` (a cue, `n` its tick, `target` the rival) marks the approach that spends it.

**For Game Design:**
- **Where knock-backs come from in the build.** A brawl's heavy charged short of full, the blast ender, a throw across, a planned exchange's knock-back (a guard break, a riposte, a blur's ender), a mine and a charged shot. A tapped heavy that lands clean staggers him in place: it doesn't knock him back 1.5 bh as §2 has it, so it opens no flip. Knock-backs run 3.5 to 8 bh by the striker's tier (`launch.json knockBack.distBh`), not a flat 3 bh.
- **The counter-rush's window** counts from the landing, so it runs 22 to 42 ticks after the knock-back.
- **The AI's counter shares** are mine.

## 2. Ricochets and wall kicks (2b): next

Simulation owns the glance (under 40°: 0.7 of the speed, reflected) and the wall kick's push. World owns the faces that hold. The director owns the wall kick's dodge window (4 ticks either side of a wall contact), the kick's rush blow, the AI's shares (15, 35, 55%), and the choreographer's taste for a send that ricochets into open air or back into the brawl.

## 3. Clashes (2c): after 2b

Blows of both fighters landing within 3 ticks of each other, of the same strength or one step apart, clash: no damage (a light gives chip), both recoil (0.5, 1.5 or 3 bh with a backflip), and the brawl's pull brings them back. Three in 3 s make a clash exchange of 4 to 8 meetings on the pulse. The even mash's double hit becomes a light clash.
