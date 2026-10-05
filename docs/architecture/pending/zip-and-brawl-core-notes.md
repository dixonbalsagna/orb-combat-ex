# Core notes for Encounter's zip slice and brawl B1

Owner: Simulation and Engine. Date: 2026-10-05, read against 7fdb70e. Short answers to the EP's questions on `docs/director/brawl-plan.md` section 7 and `docs/director/brawl-b0.md`. Nothing here is built.

## 1. Can a point rush carry the zip's way out?

**Yes, with two limits.**

- A point rush (`Rush` with no target: `px`, `py`, `pz`, `end`) takes a fighter to any point, at any bearing and any distance, and puts him there exactly on its end time. 3 to 12.5 bh is no problem.
- `end` is match time (`S.T`), so a hit-stop or a pause does not shorten it. For a way out of n ticks set `end = S.T + n * SimConst.DT`.
- While a fighter has a rush his step reads no stick and applies no gravity, whatever his state.

| Limit | What it means for the zip |
| :--- | :--- |
| **It is a straight line.** | An exit to the rival's far side passes through him, not round him. If the way out should bow round the rival, that is the backlog's `Rush.arc`: one hashed field and about four lines in `stepRush`, a sideways bow that is zero at both ends. Say if Z1 wants it |
| **It ignores the ground and buildings on the way.** Only the arrival is clamped to the ground. | The plan's obstacle rule (moving the exit point) is the director's, as section 7 already has it. A path over a ridge or through a tower is not stopped by the core |

## 2. "No strike reaches the fighter on it"

**The core has no strikes, so there is nothing in it to switch off.** A blow lands only where the director resolves one.

What in `sim/core` and `sim/world` can touch a fighter on a rush:

| Thing | Reaches him? |
| :--- | :--- |
| A shot in flight | Yes, through `SimShots.hitFighter`, which hands it to `DirBlast.hit`. That is the plan's "a shot that hits him there knocks him down" |
| A mine | Yes: his centre inside a rival's armed mine sets it off, and the blast goes through the same hook |
| The ground, buildings, water | No. Nothing collides with a rushing fighter |
| Wounds, ki, power, the mood | They tick as for anyone |

So the guarantee is the director's to keep in its own entry points: the attack request, a lunge's or a charge's arrival, and the beam's resolve, by a mark the zip sets on him. I did not find a rule there today that refuses a blow because the defender has a rush (the one test of `rush` in `DirMelee.contactTick` only skips pushing the pair apart), so this is new work in Z, not something to reuse.

## 3. A shot knocks him down on the way out: what exists

- **The `down` state exists,** but only as the end of a flight: `SimFighter.impact` and World's slide set it, and he gets up after 0.75 s (longer when embedded).
- **Setting `down` directly on a fighter in the air is wrong:** the down branch puts him on the ground at once, so he would snap to the ground from the height of the hit.
- **What works today with no core change:** a short launch. `DirLaunch.doLaunch` with a downward plan and a small force clears his rush, makes him `launched`, and the flight ends in `down` through the usual landing, with the usual landing damage and dust. `DirBlast.hit` can do that when the zip's mark is on him.
- If the plan wants a knock-down with no landing damage, that is a new small op (`SimFighter.drop`: a launch flagged so `impact` skips the hurt). About 8 lines. Say if it is wanted.

## 4. The zip tackle: what a grab needs in the core

Nothing exists. It is the backlog's `held` state, and it would be this:

| Piece | What |
| :--- | :--- |
| A fighter state `held` | He reads no stick, has no gravity and cannot act |
| Three hashed fields on the fighter | `heldBy` (the holder's slot, -1 for none) and `heldOx`, `heldOy` (where he hangs from the holder) |
| A follow pass | After both fighters have stepped, a held fighter is put at his holder's position plus the offset. It has to run after both steps, or the held one lags a tick when his slot steps first |
| Two calls | `SimFighter.grab(S, holder, victim, ox, oy)` and `SimFighter.letGo(S, victim, how)` with how `throw`, `drop` or `break` |
| Two events | `grab {actor, victim}` and `grab_end {actor, victim, kind}` |

- **A grab that carries** is then a rush on the holder: the held fighter follows.
- **A held grab that lifts and throws** is a rush upward on the holder, then `letGo` with `throw` and the director's `doLaunch`.
- Who can break it, what it costs and what it does to wounds are the director's and Game Design's.
- About 40 lines and a forced check. Neutral until the director grabs. It needs its own window: three hashed fields mean a regeneration.

## 5. Exhaustion at an empty ki bar: is a named thing needed?

**Yes. "Cannot pay" is not enough.**

- Game Design's rule (`melee-press-feel.md`) is a timed lockout: an empty bar is 2 s of exhaustion, with no zip and no guard. Ki regenerates from the next tick, so "cannot pay" lasts a fraction of a second for a cheap move and never stops a guard, which costs nothing to raise.
- What it needs: one hashed integer on the fighter, `exhaustTicks`, set to the data's length on the tick his ki is found at 0 and counted down on live ticks; two events, `exhausted {actor, dur}` and `exhaust_end {actor}`; a reader, `SimFighter.exhausted(f)`.
- Set in one place, the fighter's step, so every spender is covered without touching it: the director's prices, the guard's drain in `SimDamage.hit`, the boost.
- What exhaustion forbids is the director's and Controls' to read from that flag.
- **It changes today's matches** once it is on, because ki already reaches 0 (the guard's drain floors there). So it lands with its length at 0 in the data (off, neutral), and is switched on with QA's measuring. About 15 lines.
- For Game Design: whether ki regenerates during the 2 s, and whether being hit to 0 by a guard drain counts or only spending does.

## 6. For brawl B1 (to go in my report for the version 4 window)

**`DirS.brawlI`:** `var brawlI: PackedInt32Array` in `state.gd`'s `DirS`, and its size and values hashed beside `d.exN`, as a fighter's `act.dirI` is. One regeneration, no tick changes: it rides with intent version 4.

**Does anything but the director move or free a `locked` fighter while an exchange is held for many seconds? No, with these exact exceptions.** The locked state has no timer in the core.

| What | Effect on a locked fighter |
| :--- | :--- |
| The locked branch of his own step | He drifts by whatever velocity he has, damped to 3% a second, and is kept at or above the ground. So ground that rises under him lifts him; a crater dug under him does not drop him (no gravity while locked) |
| A rush set on him | It moves him. Only the director sets rushes |
| A KO | It frees the winner and calls the director's `endEx`. Only a finisher KOs today |
| Depth, when it is on | His z eases to the exchange's z |
| A transformation's break | It goes through the director's own `DirExchange.formBreak` |
| A shot or a mine blast | It reaches him only through `hitFighter`, the director's rule; the plain rule hurts and does not move him |
| Ki, power, wounds, the mood, hiding | They tick; none moves him or changes his state |

Nothing in `sim/world` writes a locked fighter's state or position: its contact and slide code act on launched fighters only.
