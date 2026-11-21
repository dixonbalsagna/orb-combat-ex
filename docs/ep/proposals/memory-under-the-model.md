# Buildings that remember, with the energy model on

By Orb's stand-in (design and review specialist, sprint A1), 2026-11-20, written for World to build from (World built it the same evening; see below). **Design only.** Nothing here is built or decided by this page. Every number is a first value kept in data, and Game Design rules on the numbers. Read against main at fe7dbc8a. I ran no Godot and no browser; numbers marked "arithmetic" come from small node models of the code's own formulas (`memory-model.mjs` and `mm-held.mjs`, scratch files, not in the repo), and numbers marked "record" are World's run files.

The fault this page answers is World's, written up in `docs/world/pins-and-the-model.md:19-20` and `:32` under the name **memory-under-model**.

**Three things landed on main while this page was in review, all on the evening of 2026-11-20, and the page is rebuilt on them:**

1. **World parked the first half of the fix** (883027af, `docs/world/pending/memory-under-model/`): a mark lowers what a building takes of a body's energy, by one tier of the model a mark. It is the same rule and the same number as this page's draft.
2. **Game Design ruled the second half** (bf9182dd, `docs/design/buildings.md:331-345`): with the model on, a hit that a building holds does twice its share to the floors it covers (`brunt.json` `heldMul` 2.0); a mark stays one tier of the model; a tower's mass stays 15.
3. **World built the second half into the same park** (fe7dbc8a), sized on the floors' undamaged strength, off in its data, with the 2.0 row parked beside it.

Both halves are parked, not landed. So this page is no longer a design for World to start from. It is the reasoning under what World built: why the fault happens (section 3), what the two halves do together by arithmetic (section 5), the one place where World's record and the ruling's own sentence part (section 6, row 1), the rows still to write (section 11), and the separation of what is Orb's to switch on (section 7).

**The landing review of World's park is a separate page,** `docs/ep/reviews/memory-under-model-review.md`, with a re-check of the re-parked version. This page does not repeat its findings; it points to them by their numbers (R-1 and so on).

## 1. In plain words

- **Today:** you knock a rival into a tower (B in an opening, or a fully charged heavy). If the tower is too strong to break, it takes a dent and holds. Knock them into the same tower again and it is no easier: each knock does a little less than the one before, and a tall tower would take forty knocks or more. On the build you play, a building does not remember being hit. That is the fault.
- **The fix has two halves. World built both on the evening of 20 November, the way Game Design ruled them, and neither is in the game yet.** The first: a building counts each knock and gets easier to go through. The second: a knock that the wall stops does twice the damage to the floors it lands on.
- **With both, by my sums, into a tall tower from close in:** the first knock cracks the wall where the rival lands. The second breaks those floors away, with the rival still stopped at the wall. The third, at the same spot, goes into the hole and the rival ends up inside. The tower comes down one to three knocks after that.
- **A weaker knock** (a lighter launch, or a rival who was knocked from far off and arrives slower): the floors break on the third knock, and the tower comes down somewhere between the fifth and the tenth. Today that is eighty knocks or more.
- **A small tower** (about five to seven floors): a full knock breaks its floors on the first, and it is down by the second or third.
- **A house** already breaks on the first knock. Nothing changes there.
- **When you are strong enough to go through a tower on the first knock, nothing changes either.**
- **Where this falls short of the ruling's words:** the ruling says tall towers fall on the second or third knock. World's first test run and my sums agree on something else: the floors that were hit fall then, and the tower is still standing. By my sums the whole tower takes a few knocks more. That is the first thing for Game Design to settle.
- **Where all of it falls short of Orb's own picture:** that picture is of one well-earned hit, early in the fight, sending the rival through the side of a skyscraper. With today's numbers a tall tower stops that first hit. This fix brings the going-in moment to the second or third knock. Having it on the first earned hit would be a different change (how strong a tower is), and that is Game Design's to price.
- **Nothing new is drawn.** You would see what the game already draws: broken floors on the tower's face, a hole, the tower falling. Nothing appears on, over or between the fighters.
- **This does not fix the bounce off a background building** that you asked to have squashed. That takes other pieces: which building a knock is allowed to aim at, and what the wall does with the fighter when it stops them. One setting in that second piece is the choice you answered "Wait until I play it" to (does the whole fight freeze, or only the fighter in the wall). I think Orb would want that set played before it goes in, so it would come as a private build.
- **Your knock, zip round, knock again chain in the air:** nothing on this page changes its code. A reading in section 11 watches that it does not move.

## 2. Where things stand

| Piece | State | Where |
| :--- | :--- | :--- |
| A count of the sends that struck a building ("marks"), hashed when not zero | Built, on main, switched off in data | `sim/core/state.gd:602-606`; `sim/core/hash.gd:265-267`, `:402`; `sim/world/brunt.gd:954-958`, `:970-971`, `:1111-1112`; `data/biomes/brunt.json:69` (`repeatMarks` 0) |
| The energy model's rule for buildings (a building takes 1, 5 or 15 of a body's energy) | Built, on main. Off in main's data (`data/fight/power.json:4`), on in Orb's builds by the page's setup word | `sim/world/brunt.gd:399-423`, `:436-437`; `data/fight/power.json:104` |
| The energy model as main's default | Parked for GW1a, not landed | `docs/architecture/pending/energy-on/` |
| **A mark's worth with the energy model on** | **Parked by World on 2026-11-20 (883027af, re-parked fe7dbc8a), not landed.** Read in 2.1 | `docs/world/pending/memory-under-model/` |
| **A held hit does twice its share to the floors it covers** | **Ruled by Game Design on 2026-11-20 (bf9182dd); built into the same park by World (fe7dbc8a), off in its data (`heldMul` 1.0), with the 2.0 row parked beside it. Not landed** | `docs/design/buildings.md:331-345`; `docs/world/pending/memory-under-model/` |
| The landing review of that park | Written by the stand-in, with a re-check of the re-parked version: the code can land; two items are owed before the 2.0 row goes on | `docs/ep/reviews/memory-under-model-review.md` |
| The older floor memory (a floor that has taken twice its strength gives way) | Built; read only with the energy model off | `sim/world/brunt.gd:445`, `:456-464`; `brunt.json:27-29` |
| The wall hold (the fighter stays at the face, the fight is not frozen) | Built, switched off in data | `sim/world/brunt.gd:1027`, `:1087-1088`, `:1143-1149`; `brunt.json:47-50` |
| The wall hold's data row and re-pinned checks | Parked | `docs/world/pending/wall-hold-on/` |
| The key split (the old crater repeat gets its own key, so `repeatMarks` means buildings only) | Parked; stands after terrain step 2 and the wall-hold pins | `docs/world/pending/wall-hold-split/` |
| World's check pins for GW1a | Parked, re-cut twice on 2026-11-20: `repeat_check`'s model-on row is now off-path, and `wall_hold_check`'s now sets `heldMul` 2.0 and asserts the broken floors, so the pins need the park under them (the review's R-3). It does not stack with the wall-hold pins in either order (the gate map's test on a scratch copy before the re-cut; not re-run by me) | `docs/world/pending/checks-gw1a/pins-gw1a.diff` |
| A check of repeat hits on one building with the energy model on | World's `memory_model_check`, in the park. Its held-hit rows apply real hits; its mark rows set marks by hand (2.1) | `docs/world/pending/memory-under-model/memory-under-model.diff` |
| The switch row for a private build (five values in one row) | Built, held "waiting on QA city read" | `tools/preview/switches.mjs:165-167` |
| QA's city read | Missing | `docs/ep/proposals/planet-a1-design.md:213` |
| Which building a send may aim at (the 20 degree cone) | Ruled; Encounter's parks, a GW1b rider | `docs/design/buildings.md:309-327`; `docs/director/pending/launch-cone/`, `wall-cone/` |
| Game Design's ruling that buildings remember | Exists | `docs/design/buildings.md:133`, `:288-292`, `:331-345` |
| Orb's answer on a fighter lodged in a building | Exists: "Wait until I play it" | `docs/ep/vision.md:1862` (Orb's words); `:1355` is the EP's summary of it |

Two facts that change how the fault should be read:

1. **Nobody has ever played building memory.** `repeatMarks` is 0 in main's data and was 0 in the build Orb played (`docs/tools/runs/6a30b4c9/pck-verify.txt:59`). No mark has ever been written in play, because a mark is written only when the key is above 0 (`brunt.gd:970-971`).
2. **The energy model was on in Orb's build and is off in main's data today** (`power.json:4`). So "the path Orb plays" is the model-on path, and every World check that starts a match without the `"power"` setup word tests the other one.

### 2.1 World's park, as read for this page

Read as re-parked at fe7dbc8a: `memory-under-model.diff` (the code, the key at its off value, the schema, the check) and `memory-under-model-data.diff` (the `heldMul` 2.0 row).

**What it builds.**

- **A mark's worth.** `_memory(b)`, used once: `_outcomePower` reads `massOf(b) * _memory(b)`, where the factor is `energyTop ^ (-(tierShare / 3) x marks)`, marks counted up to `repeatMarks`. That is 0.513 for one mark and 0.263 for two. No new number: it follows `power.json`. With `repeatMarks` 0 the factor is exactly 1.0 and the multiply is exact. **This is section 5's rule 2.**
- **The held hit.** `outcomeDmg` now also returns the covered floors' undamaged strength (`sumS0`). With `heldMul` above 1.0, a held hit is `E / m x heldMul x sumS0`, judged as always against what the floors have left. With `heldMul` 1.0 the line is the old expression (I read it: the same operands in the same order). The through case and the house are untouched. **This is section 5's rule 4, with the sizing this page's draft asked for and the stand-in's review asked for as its M-01:** World's first cut multiplied `heldMul` into the old line and "broke no floor in three sends of 1.7" (its README), which is the first row of 5.2's second table.
- **Data.** `"heldMul": 1.0` enters `data/biomes/brunt.json` with the code; the schema allows 1 to 8.

**What its records show** (`docs/world/runs/memory-under-model/`):

| Record | Reading |
| :--- | :--- |
| `memory_model_check.txt` | 0 failed. Three real sends of 1.7 at a mass-15 tower of 20 floors leave 20, 20, then **18** floors standing with `heldMul` 2, and 20, 20, 20 with 1. Two sends of 3.4: 20, then 18. One of 7.5: 18, held. The negative control fails 7 rows |
| `wall_hold_check.both-passes.txt`, model on | Three real launches at each of 24 towers: **the covered floors are broken in 24 of 24 with memory on and in 0 without. 0 towers fall either way** |
| `bystanders_check.txt` | 81 people ran, none died |
| The park's README | The golden is unchanged with the shipped data |

The floors agree with this page's arithmetic to the send. So does the tower standing, which is where the record and the ruling's own sentence part (section 6, row 1).

**The arrival energy matters for everything below.** World's README says the check's real launches, from 3,000 units off, reach the tower with 1.7 to 3.9 of energy. This page's draft staged its sends at 4.94 at the face (a full launch at base with no speed lost on the way). A send under 3.94 never goes through a tall tower by marks alone; it gets in only after a held hit has broken the floors.

**Where the park and this page differ, and what I make of it:**

| # | The park | This page's draft | Now |
| :--- | :--- | :--- | :--- |
| 1 | `heldMul` 1.0 is off (the old line), anything above is the new rule; the schema's floor is 1 | 0 as off | **World's stands; mine is withdrawn.** One thing to know: 1.0 and 1.01 are different rules, not close numbers, because the sizing changes at once |
| 2 | The `heldMul` 2.0 row is "the GW1b data row" | A hash row that needs QA's read and the look gate first | **The EP places the row in the wall-hold window, to flip together with `repeatMarks` 2** (the review's R-2; World's README still says GW1b). I agree. Alone, the row would change every held tower hit in every model-on match (a dent becomes a crack, and a base full launch breaks a low tower's floors on the first knock) while giving only part of the ruling. Wherever it flips, it is a change in what the player sees on first knocks (ADR 0010), so it needs its side-by-side |
| 3 | `pins-gw1a.diff` was re-cut in the same commit: `wall_hold_check`'s model-on row now sets `heldMul` 2.0 and asserts the broken floors | | The GW1a pins now need this park's code under them, or that row fails (the review's R-3, which records that the EP lands the park with GW1a). Not run by me |
| 4 | No lodge rule | The draft's rule 5 | An option only (5.5) |

**Notes that add to the landing review** (its own findings are not repeated here):

| # | Note | Evidence |
| :--- | :--- | :--- |
| 1 | With `heldMul` 1.0 and memory on, applied hits fade: arithmetic for a held light launch at a 13-floor tower, each hit over the first, **1.00, 1.79, 2.93, 2.02, 1.38, 1.02.** The check's "1.95 times, then 3.80 times" row does not see it, because it sets `b.marks` by hand on floors that have taken no hit. That only matters if memory ever ships without the held hit, which is one more reason the two rows flip together | `memory_model_check.gd` `_hit`; `brunt.gd:416`, `:487-488` |
| 2 | The check starts its match with `"power": true` only. Orb's build also has the dash, the slip, the kick and the travel word on. That does not change a staged outcome, but section 11 asks for the match to be started as Orb's build is | the diff, `_match()` |
| 3 | No row reads the state hash (the same sends twice give one hash; the shipped data gives the hash it gives today) | |
| 4 | `bystanders_check` passed (81 people ran, none died). Whether that run had `heldMul` 2.0 and `repeatMarks` 2 set is not stated in the record | `runs/memory-under-model/bystanders_check.txt` |
| 5 | `docs/world/pins-and-the-model.md:32` still says the Game Design finding "stays open", while its row `:20` and the park's README say it is answered | |

## 3. Why the fault happens

Source of the ruling: Orb, `docs/ep/vision.md:1462`: "it's expected that each time you launch an opponent against something, the more destroyed it will be. I don't necessarily think a handicap should be applied just for repetition, though I could be convinced either way." Game Design made it a rule: a send into a marked building meets it one tier higher for each mark, up to two (`docs/design/buildings.md:133`), and "The building remembers, so the second and third sends bring it down, tier for tier" (`:289`).

On main, with the energy model on, these reads go quiet, in order:

| # | Code | What happens |
| :--- | :--- | :--- |
| 0 | `brunt.json:69`; `brunt.gd:970-971`, `:1111-1112` | Before anything else: with `repeatMarks` 0 no mark is written. The rest is what happens once it is 2 |
| 1 | `brunt.gd:954-958` (`tierAt`), called at `:968` (`hit`), `:1107` (`through`), `:554` (`chainPlan`) | The mark raises the tier the building is met at. This still runs |
| 2 | `brunt.gd:436-437` | **The break.** `outcomeOf` returns `_outcomePower(S, b, y, spN)` first thing. The `tier`, `punched` and `special` arguments are dropped, and the raised tier with them |
| 3 | `brunt.gd:399-404` | Going through is the body's energy against the building's mass, and nothing else: `E = spN * spN / (u * u)`, `through = E >= m` |
| 4 | `brunt.gd:445`, `:456-464` | The floor memory (`_weak`, `giveWay` 2.0) and `towerPunches` sit after the early return. Never reached |
| 5 | `brunt.gd:409`, `:416`, `:487-488` | Floor damage cancels itself. The floors' strength is read already weakened (`:487-488`), and the damage is set as a share of that same weakened strength (`:416`), so the ratio that decides punch, crack or dent is always exactly energy over mass. Worse, the damage itself shrinks with every hit |
| 6 | `brunt.gd:602-606`, `:610-613` | The lodge's last hit and the hold's seconds read the sender's level (`SimPower.level(by)`), not the tier, so the raised tier at `:1035`, `:1040` and `:1052` is dropped too |
| 7 | `brunt.gd:509-511` | The chain's link cap is 99: energy is the budget |

What still reads a mark with the model on, on main: the state hash (`hash.gd:265-267`, `:402`), and the chain inside a tower (`brunt.gd:1031` passes the raised tier to `WorldInterior.begin`). That chain is off (`brunt.json:51`).

**So the correction to World's first wording: on main, memory is not merely inert, it runs backwards.** Core hit points and cleared floors still remember, but each held hit on the same floors does less than the one before. Arithmetic, a held light launch at a 13-floor tower, the damage of each send over the first: **1.00, 0.92, 0.84, 0.77, 0.71.** A base full launch needs 41 to 156 sends to bring a tall tower of 9 to 15 floors down, by its height and how high it is struck.

World's record says the same from outside: three sends at one tower fell 24 of 24 towers with the model off and 0 of 24 with it on (`docs/world/runs/checks-gw1a/with-the-model-on-after/wall_hold_check.txt`). `repeat_check`'s 1.00, 1.00, 1.00 is not evidence either way: that row sends into a house at speed 3,000 with its hit points reset each time (`sim/world/tools/repeat_check.gd:44`, `:82-83`), so the house collapses whole every time, memory or none. World re-classed that row as off-path on 2026-11-20 for the same reason (`pins-and-the-model.md:19`).

World's park mends row 2 for the mass and, once `heldMul` is 2.0, row 5. Row 6 is untouched (the review's m-06).

## 4. The second suspected fault: wrecks (not a fault)

World's correction of 2026-11-20 is right, and I confirm it from the files. Nothing to fix.

- `WorldWrecks.burst` takes its damage from `WorldBrunt.tierFactorOf(S, cause, tier, false)` (`sim/world/wrecks.gd:206-219`). With the model on, that function ignores the `tier` argument and reads the thrower's level (`brunt.gd:604-605`).
- Main's check passes the tier as the argument only and leaves the thrower at tier 1 (`sim/world/tools/wrecks_check.gd:137`), so with the model on all four bursts were the same. The one-line staging fix is in the parked pins (`pins-gw1a.diff:622`), not on main.
- With the thrower's tier set, the record is 134.6, 269.3, 437.6, 644.1 hit points (`with-the-model-on-after/wrecks_check.txt:43`). Arithmetic: the tier table read at the level gives 0.120, 0.240, 0.390, 0.574, which is 1 : 2.00 : 3.25 : 4.78, and 134.649 times those is the record to the digit. With the model off: 134.6, 303.0, 527.4, 819.1 (`:22`).
- Two things worth knowing, neither a fault: tier 4 at no power reads 4.78 times and not the ladder's 6.08, because the level includes power; and nothing in the shipped game calls `WorldWrecks.burst` (my search of `sim`, `render`, `ui`, `net` and `audio` found only the check).
- One stale line: `docs/world/pending/checks-gw1a/README.md:51` still names "memory-under-model, wrecks-power" as owed parks.

## 5. The design

### 5.1 Two ideas, both now on the record

1. **A mark is worth one tier of the model.** At equal power, one tier up is `tierShare / 3` of a level, and energy grows by `topOverBase` to the power of the level (`data/fight/power.json:5-6`: 0.8 and 12.25). So one tier is an energy factor of 12.25 ^ (0.8 / 3) = **1.951**, and two are **3.805** (arithmetic). A marked building takes that much less of a body's energy. No energy is made: the body never leaves faster than it arrived. World's park builds this, and Game Design's ruling confirms it ("A mark stays one model tier", `buildings.md:333`).
2. **A hit the building holds does twice its share to the floors it covers.** Game Design's reason: a held body stops in the building, so all of its energy goes into the few floors it covers (`buildings.md:335`). World built it the same evening (rule 4 below).

### 5.2 The rules

"Memory on" means `repeatMarks` above 0 with the energy model on. "The held hit on" means `heldMul` above 1.0 with the energy model on. They are two switches in the code, and each acts without the other; on main the EP means them to flip together (2.1).

| # | Rule | Number | Where the number lives | State |
| :--- | :--- | :--- | :--- | :--- |
| 1 | **What is remembered.** Every send that strikes a building leaves one mark, written after that send's own outcome is decided. A send that goes through leaves one too. Marks last the match (`buildings.md:30`). Floors also keep the damage they take | At most 2 marks count | `brunt.json` `repeatMarks` (0 today; 2 is Game Design's) | Built on main |
| 2 | **A mark's worth.** The building's mass is multiplied by `topOverBase ^ (-(tierShare / 3) x marks)` | 0.513 for one mark, 0.263 for two | `power.json` `energy.topOverBase` 12.25 and `level.tierShare` 0.8 (existing). **No new key** | World's park |
| 3 | **Through, and the speed kept.** The model's own two lines, on the lowered mass: through when the energy is at least the mass; the speed kept is the root of what is left over the energy | No new number | `brunt.gd:393-394`, `:403-404` | World's park |
| 4 | **A held hit** does `heldMul` times its share (energy over the lowered mass) of the covered floors' **own** strength, and is judged against the strength those floors **have left**. When it reaches what they have left, the covered floors break. The body is still held: it did not have the energy to go through. **One case is not settled:** if that hit also drops the floors above or spends the core, main's lines let the body through with 0.8 of its speed (`brunt.gd:991`, `:999`), which it had not the energy for (the review's R-1) | 2.0 | `brunt.json` `heldMul` (new key in World's park; 1.0 is off, 2.0 is the ruled number) | World's park |
| 5 | **A broken face is open.** The next send at that height meets no floor and goes in, keeping 0.95 of its speed. This is today's code (`brunt.gd:414-415`, `:481`) | 0.95 | `brunt.json` `keepFree` (existing) | Built on main |
| 6 | **A hold is never made longer by a mark.** The seconds a wall or a lodge holds a fighter stay by the sender's level | No change | `brunt.gd:610-613`; `brunt.json` `lodgeSeconds` | Built on main |
| 7 | **Houses, and towers too short to have floors,** follow rule 2 and not rule 4. The ruling says houses are unchanged (`buildings.md:343`); it does not name the short towers (`brunt.gd:410-413`), which the park leaves as they are (the review's R-7) | House mass 1, then 0.51, then 0.26 | as rule 2 | |
| 8 | **The planner predicts the same thing it gets.** `chainPlan` and the meteor's pass (`through`) call the same function, so a plan is still its own outcome | | `brunt.gd:554`, `:1108` | |

Rule 6 is the player-agency rule (Orb, 2026-11-13, `docs/ep/vision.md:1800`: "KEEP WORKSHOPPING, PLAYER AGENCY MUST BE RESPECTED"): memory changes **which** outcome a blow that landed gets. It adds no new or longer hold.

**Why rule 4 is worded "own strength, judged against what is left".** The ruling gives its arithmetic in one clause: "a floor breaks when one hit's damage reaches its strength, less 25% of what it has taken" (`buildings.md:338`). That only works if the hit is sized on something the earlier damage has not shrunk. Today's line sizes the hit on the weakened strength and judges it against the same weakened strength, so the two cancel (section 3, row 5). World found the same from the other side: its first cut, multiplied into the old line, broke no floor in three sends of 1.7, and its re-cut on the undamaged strength leaves 20, 20, then 18 floors standing (2.1). The difference, by arithmetic, for a tall tower with memory on:

| How `heldMul` 2 is built | Lowest energy whose hit breaks the covered floors on the first, second, third send | The ruling's rows (1.7 on the third, 3.4 on the second) |
| :--- | :--- | :--- |
| Multiplied into today's line (sized on the weakened strength; World's first cut) | 7.5, 3.85, 1.98 | **Both fail** |
| Sized on the floors' own strength (rule 4; World's park) | 7.5, 3.07, 1.43 when the body covers two floors; 7.5, 3.41, 1.65 when it covers one | Both hold |
| Rule 4 with memory off (`repeatMarks` 0) | 7.5, 5.0, 3.76 | |
| World's park alone (no `heldMul`): floors go only when the body goes through | 15, 7.69, 3.94 | |

The two-floor numbers are lower than the ruling's because the code adds the whole hit's damage to **each** covered floor (`brunt.gd:1215-1216`, `:1225-1226`), so two floors weaken twice as fast as the ruling's one-floor sum assumes. The ruling's 1.7 holds either way. Its 3.4 holds where two floors are covered and is a hair short (3.41) where one is, as the review's R-8 says.

### 5.3 The masses, and the speeds that go through

Arithmetic. A speed is in units a second at the face; 2,000 is a full launch by a fresh fighter at base, if it loses nothing on the way.

| Building | Mass with 0, 1, 2 marks | A body goes through at this speed or more |
| :--- | :--- | :--- |
| House (under five floors) | 1, 0.51, 0.26 | 900, 644, 461 |
| Low tower (under 1,200 tall: five to seven floors, and some of eight) | 5, 2.56, 1.31 | 2,012, 1,441, 1,032 |
| Tall tower | 15, 7.69, 3.94 | 3,486, 2,496, 1,787 |

### 5.4 What a first, second and third hit do

Arithmetic, with the limits of the model said plainly: one building alone with nothing behind it (so every send that gets in ends lodged in it), struck at the same height each time, full hit points (`maxhp = height / 8 x 6`, `sim/world/settlements.gd:454`), energy **at the face** as stated. "Today" is main with the model on. "Both" is World's park with `heldMul` 2.0 and `repeatMarks` 2. The number in brackets is the hit over the floors' own strength (twice energy over the lowered mass).

| The send (energy at the face) | Low tower (the knocks are for 6 floors at three tenths of its height; the counts run over 5 to 7 floors and five heights) | Tall tower (the knocks are for 13 floors; the counts run over 9 to 15 floors and five heights) |
| :--- | :--- | :--- |
| A slow arrival (1.7, the low end of World's record) | crack (0.68), **floors break at the 2nd,** in at the 3rd. Down at the 4th or 5th. Today: 33 to 121 | dent (0.23), crack (0.44), **floors break at the 3rd** (0.86 against what is left), in through the hole at the 4th. Down between the 6th and 10th. Today: 118 to 454 |
| A light launch at base (2.47) | crack (0.99), **floors break at the 2nd,** in and down at the 3rd (3rd to 5th by height). Today: 23 to 83 | dent (0.33), crack (0.64), **floors break at the 3rd,** in at the 4th. Down between the 5th and 8th. Today: 81 to 312 |
| A full launch at base, no power (4.94) | **floors break at the 1st** (1.98), held; in at the 2nd; down at the 2nd or 3rd. Today: 11 to 42 | crack (0.66), **floors break at the 2nd** (1.28), held; **in through the hole at the 3rd,** keeping 0.95 of the speed. Down between the 4th and 6th. Today: 41 to 156 |
| A full launch at base, full power bar (8.15) | through at the 1st, as today | **floors break at the 1st** (1.09), held; in at the 2nd; down at the 3rd. Today: 25 to 94 |
| A full launch at tier 2, no power (9.64) | through at the 1st, as today | floors break at the 1st (1.29), held; in at the 2nd; down at the 3rd. Today: 21 to 80 |
| Tier 3 and up | as today | as today: through at the 1st |

Across 35 staged tall towers (9 to 15 floors, five hit heights), for each energy:

| Energy at the face | Covered floors broken by the 3rd send | The body inside by the 3rd | The tower down by the 3rd | Down by the 4th | Sends to bring it down |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1.7 | 35 of 35 | 0 | 0 | 0 | 6 to 10 |
| 2.47 | 35 | 0 | 0 | 0 | 5 to 8 |
| 3.4 | 35 | 35 | 0 | 0 | 5 to 7 |
| 4.4 | 35 | 35 | 0 | 7 | 4 to 6 |
| 4.94 | 35 | 35 | 0 | 11 | 4 to 6 |
| 8.15 (full power bar) | 35 | 35 | 35 | 35 | 3 |

**So the ruling, as it is worded, has two readings** (`buildings.md:339` says three sends of 1.7 bring the covered floors down; `:345` says they bring the tower down). The first is true by this arithmetic and by World's record (20, 20, then 18 floors standing; the covered floors of 24 of 24 towers broken). The second is not: World's record has 0 of 24 towers down after three sends, and by arithmetic a 10-floor tower then stands with a two-floor hole and about two thirds of its core. The floors are a Godot record. The counts of sends to bring a tower down are arithmetic only. It is the first row of section 6.

One thing the model does not show: sends in a real fight strike at different heights. A cleared run of more than two floors drops every floor above it (`brunt.gd:1259`, `TUNNEL_MAX` 2), so two breaks next to each other bring down the top of a tower. That would make towers fall sooner than the table says. Not modelled.

### 5.5 Levers, if Game Design wants the tower itself down sooner

The same 35 tall towers. Arithmetic. The first row is the ruling as World built it, with both rows on. The next three are for comparison. The last is an option, not built and not proposed for the first landing.

| Variant | 1.7: sends to bring it down | 4.94: down by the 4th | 4.94: sends |
| :--- | :--- | :--- | :--- |
| **The ruling: park and `heldMul` 2 (rule 4)** | **6 to 10** | **11 of 35** | **4 to 6** |
| The same, with `heldMul` multiplied into today's line (World's first cut) | 17 to 61 | 7 of 35 | 4 to 6 |
| `heldMul` 2 with memory off | 19 to 61 | 0 | 5 to 7 |
| World's park alone | 32 to 120 | 3 of 35 | 4 to 7 |
| The ruling, plus the lodge's last hit reading the tier table 0.8 of a row further along for each mark (the draft's rule 5) | 5 | 35 of 35 | 4 |

The last row carries onto the model something the model-off code already does (the raised tier reaches the lodge's factor at `brunt.gd:1035`), and it is the only variant here that brings every tower down by the fourth send. It is an addition to the ruling, not part of it, so it is listed in section 6 and left out of section 8.

The draft of this page proposed a new key for what a mark is worth (`powerMarkTiers`) with 1.25 tiers as its lever. **That is withdrawn:** Game Design ruled the same evening that a mark stays one model tier, and why (`buildings.md:337`).

### 5.6 What memory does not do

- **It does not stop the rebound.** Orb, `vision.md:1881`: "the behavior where a fighter bounces off something in the background and then ricochets in an unrealistic and immersion-breaking trajectory is something I want squashed as we head to A1." That is other work: the 20 degree cone (which building a send may aim at; `buildings.md:309-327`, a GW1b rider), and the wall's own values (section 7). Memory changes neither. Section 11 keeps a reading on it so memory cannot make it worse unnoticed.
- **It does not touch the code of the feature in the same quote:** "scoring a knockback on the opponent, zipping around them at higher speed than they fly, then knocking them back in another direction". Not verified: whether a body coming off a wall is ever the start of a link in that chain, which a lodge would end (a wall leaves the body moving, `brunt.gd:1087-1089`; a lodge stops it dead, `:1042-1046`). Reading 28 in section 11 guards it.
- **It does not switch on the lodge hold.** Orb's recorded answer, "Wait until I play it" (`vision.md:1862`), is to one question: when a fighter is lodged in a building, does the whole fight freeze or is only that fighter held. Section 7 says, value by value, which of the wall's four values that answer covers.
- **It does not change the chain inside a tower,** which is off. With the model on, that chain's damage and hold already follow the sender's level (`sim/world/interior.gd:316`, `:363`, `:368`), but its reach and exit gates compare a tier (`interior.gd:101`, `:328`), and the mark-raised tier reaches them through `brunt.gd:1031`. Whoever switches it on must decide those gates' rule first.
- **It adds no cracked-core state.** `buildings.md:153` names a tower's fourth mark as a cause of a cracked core. No such state is built (I found none in `sim/world`), and this page does not design it.

### 5.7 What the player sees

- **Nothing new is drawn, and nothing on, over or between the fighters.** Every picture already exists: the marks on a tower's floors (Rendering draws them from the floors' damage, `render/core/planet_view.gd:757-778`), the punched floors, the lodge, the fall.
- **One new mix of two existing things:** a fighter stopped at a wall on the same hit that clears the floors they hit. Today a held hit only cracks or dents; a hit that clears floors always lets the body in. The events are the existing ones (`building_hit` with outcome `wall`, and `floor_hit` with `punch` and a count of floors), but no view has seen them together. Rendering, VFX and Audio should say what it looks and sounds like before it is judged.
- **First knocks change too, not only repeats.** With `heldMul` 2 a held first hit is twice as large: a dent becomes a crack, and a base full launch breaks a low tower's floors on the first knock while the fighter is held at the wall.
- **That is a look change, so it goes through the look gate** (ADR 0010): a side-by-side of four knocks at one tower, everything off against both on, on the same seed. The reduced mode is on by default, so it is the look that is judged. The safety reading of that clip is the EP's.
- **Bystanders:** floors clear sooner, so people are thrown clear or run sooner. Nobody dies, as now. One thing changes in kind: a held hit that only cracks scatters at most `heldDeathShare` (0.6) of the people on those floors (`brunt.gd:1217-1222`), and a held hit that clears them scatters all of them (`:1211-1212`). `bystanders_check` must pass with both switches on.

## 6. Departures, and gaps in the record

Every one is a proposal or a question for Game Design. Row 1 is the one to settle first.

| # | The record | This page | Why |
| :--- | :--- | :--- | :--- |
| 1 | `buildings.md:344-345`, and the commit's own summary: the second and third sends bring a tall tower down; three sends of 1.7 bring a mass-15 tower down | The **covered floors** come down on the second or third send (as `buildings.md:339` says). The **tower** comes down between the 4th and the 10th, by energy | World's record: after three real sends the covered floors of 24 of 24 towers are broken and 0 towers are down. Arithmetic for the rest (5.4): the core has about two thirds left. If the tower itself is meant, a lever is needed (5.5) |
| 2 | `buildings.md:333`: "a held hit does 2 x E/m" | Twice the share of the floors' **own** strength, judged against what they have left | **Settled the same evening, nothing to rule:** World built it this way (fe7dbc8a) after its first cut, multiplied into the old line, broke no floor. The ruling's own clause at `:338` reads this way |
| 3 | `buildings.md:333`: `heldMul` 2.0, with 1 implied as today | The draft proposed 0 as off. **Withdrawn:** World built 1.0 as the old line exactly and anything above it as the new rule | Either keeps the hash still until the data row. To know: 1.0 and 1.01 are different rules (the review's R-5) |
| 4 | `buildings.md:137` and `:185` (hard), `docs/design/power-scale.md:37`, `docs/design/playable-build.md:244`: a base power send ends inside the tower | With `buildings.md:289` and the code: held at the face on the first knock; inside on a later one | The later ruling and the code agree (`brunt.gd:419-422`). The hard row and `power-scale.md`'s wording are Game Design's to re-word or restore. Older than this page |
| 5 | `buildings.md:30`: three walls on one tower and the fourth launch goes through | One or two walls, then the floors break, then the next send goes in. By energy: in at the 2nd for a full power bar, the 3rd for a full launch, the 4th for a light one | Follows from the ruled numbers |
| 6 | `buildings.md:77`, `:288`: a tier-1 body through a tower, "Never (hard)" | With memory on, a base send goes into a tower whose floors it has broken, and through a marked one if it arrives with 3.94 or more. I propose the row read "through an unmarked, undamaged tower" | The row is already untrue with the model on for a base fighter with a full power bar against a low tower: 8.15 against 5 (`power-scale.md:60`). Older than this page |
| 7 | `playable-build.md:245`: repeated slams break it "by `giveWay` 2"; `docs/world/destruction-hook.md:148` | With the model on, `giveWay` is not read. Marks lower the mass, and `wallMemory` (the floors' damage) lowers what a held hit must reach | The ruling of 2026-11-20 |
| 8 | The code with the model off lengthens a hold at a marked building (the raised tier reaches `lodgeSeconds`, `brunt.gd:1040`, `:1052`) | With the model on, a mark never lengthens a hold (this is main's behaviour already) | Player agency. The ruling's text gives the hold by the attacker's tier (`buildings.md:24`, `playable-build.md:240`) |
| 9 | `playable-build.md:230-235`, `tools/preview/switches.mjs:165-167`, `A1-sprint.md:48`: the wall's values and memory are one group, switched on after QA's read | Four rows: the held hit, memory, the no-rebound value, and the three values of Orb's question (section 7) | Orb's "Wait until I play it" (`vision.md:1862`) answers the freeze question only. The no-rebound value is Game Design's ruled fix for the bug Orb asked to have squashed (`vision.md:1881`), gated on a QA read, not on Orb playing. Whether it may stand alone is Game Design's and the EP's call: no check has run it alone |
| 10 | `docs/world/pending/wall-hold-split/README.md:8`, `:27`: the five numbers are one data row, for GW2 | Memory's number and the held hit's flip together, in GW1c at the earliest if their readings pass; the wall's four values are split off (section 7) | The sprint puts "buildings breaking at every tier" in A1 (`docs/ep/sprints/A1-sprint.md:48`) |
| 11 | `buildings.md:153`: a tower's fourth mark cracks its core | Not built and not designed here. Marks past two are counted and do nothing | No cracked-core state exists |
| 12 | `buildings.md:38`, `:82`, `:154`: a collapse warns for at least 1.5 s, and longer than any hold a fighter there is in | The sim brings a building down at once (`sim/world/structures.gd:506-507`). With memory on, a base-tier tower can fall on the tick a fighter lodges in it | Older than this page; commoner with it. Whether Rendering plays a warning was not verified |
| 13 | `buildings.md:80`: 2 to 5 wall slams a match | Memory turns some wall slams into lodges; the held hit keeps the slam. Re-base after QA's read | |
| 14 | The ruling names no rule for the lodge's last hit | An option only (5.5, last row): the lodge reads the tier table further along for each mark | The only variant that brings every staged tower down by the fourth send |
| 15 | `buildings.md:341`: a held hit that breaks its floors is "still held"; `brunt.gd:398`: a send goes through only what it can pay for | Held, as built, except where the hit also drops the stack above or spends the core: then the body passes with 0.8 of its speed | The review's R-1, owed before the 2.0 row. Game Design chooses: held at the face, or through at a named speed |
| 16 | `planet-a1-design.md:221` (my own earlier page): "Nothing to add for A1" on buildings breaking at every tier | Superseded by this page | Written before World found the fault |

## 7. Data

**`data/biomes/brunt.json`** (World's file; the schema is Tools', and the review's R-4 asks Tools for cases). One new key, in World's park, at its off value:

```json
  "bruntMul": 1.8,
  "heldMul": 1.0,
```

`BRUNT_KEYS` carries the same 1.0 for a file that leaves it out, and `tools/schemas/biomes-brunt.schema.json` gains the entry (a number, 1 to 8) in the same diff. The schema refuses unknown keys (`:335`), so the three land together. The park does not add a sentence to the file's `_about`; I would add one ("heldMul: with the energy model on, what a hit the building holds does to the floors it covers, as a multiple of its share of their undamaged strength; 1: its share of the strength left, as before").

**What the key's arrival moves.** `brunt.json`'s whole text is in the replay's data key (`brunt.gd:149-152`, `sim/core/replay.gd:274`), so when the park lands every replay kept from before it is refused (`replay.gd:198`), as with any data change. The golden record's fight hash does not fold `brunt.json` (`sim/core/tools/golden_recipes.gd:104`), and World's record says the golden is unchanged.

**No new key for a mark's worth.** The draft's `powerMarkTiers` is withdrawn (5.5), and so is the draft's 0-as-off for `heldMul` (2.1).

**The data rows.** On main the first two flip together, in the wall-hold window (the EP's placement, the review's R-2). As switch rows for a private build they stay separate, so each can be seen alone:

| Row | Sets | Whose | Waits on |
| :--- | :--- | :--- | :--- |
| The held hit | `heldMul` 1.0 to 2.0 (World's `memory-under-model-data.diff`) | Game Design's ruling of 2026-11-20 | The code; the review's R-1; the look gate and QA's read, because it changes first knocks in every model-on match, memory or none; then it flips with the memory row |
| Memory | `repeatMarks` 2 | Game Design's rulings (`buildings.md:133`, `:291`) | The key split (so the old crater repeat stays off, `buildings.md:292`), QA's read, the look gate, a golden window |
| No rebound | `wallRebound` 0.25 to 0 | Game Design's ruled fix for the bounce (`playable-build.md:235`), gated on QA's read of the civilian band and match length (`:230`) | Game Design and the EP saying it may stand alone; a check that runs it alone; QA's read |
| Orb's question | `lodgeHold` "world" to "body", `wallStop` 1 to 0, `wallDepthHold` 0 to 1 | **Orb's, after playing** | A private build. The team does not switch these on |

Why the last row is those three. `lodgeHold` is the question itself: does a lodge hold the whole fight or only the body (`brunt.gd:57`). `wallStop` is the same choice at a wall: the share of the stop a wall freezes the whole fight for (`brunt.gd:39`). `wallDepthHold` acts only with `lodgeHold` "body" (`brunt.gd:40`, `:1144-1147`). `wallRebound` is a different thing, the speed that comes back off the face (`brunt.gd:1087-1088`), and its code does not depend on the other three.

What I could not verify about `wallRebound` 0 alone: what it looks like with the whole fight still frozen for half a second at the hit, and whether it is what removes the bounce Orb saw. World's record with the model on says the push off the face is already small today (91 units on average, none over 150) and the body's depth eases back to the fight line in 48 ticks (`docs/world/runs/memory-under-model/wall_hold_check.both-passes.txt`). So on Orb's path the visible part of the bounce may be the depth coming home, which `wallRebound` does not touch. The cone is the larger part of that fix.

**`tools/preview/switches.mjs`** (Tools' file), the one row at `:165-167` becomes four:

| Row | Sets | Held |
| :--- | :--- | :--- |
| `heldHit` (new) | `heldMul` 1 to 2 | "waiting on the look gate and QA's memory read" |
| `buildingMemory` (new) | `repeatMarks` 0 to 2 | "waiting on QA's memory read" |
| `wallNoRebound` (new) | `wallRebound` 0.25 to 0 | "waiting on Game Design and QA's city read" |
| `cityHold` | `lodgeHold` world to body, `wallStop` 1 to 0, `wallDepthHold` 0 to 1 (its `wallRebound` and `repeatMarks` entries removed) | "Orb plays it first: private build only" |

No number changes in `data/fight/power.json`. The masses stay 1, 5 and 15, as ruled.

## 8. The code, and the hash

World's park is the code. This section says what it is, where it sits, and what the lines around it then do. All of it is in `sim/world/brunt.gd`. No file in the sim's core is touched, so no grant is needed and the load-split rule is not in play. The park adds no two-fighter spelling to shipped code (`tools/ratchet-two-fighter.mjs` counts `S.dirS.ex`, `fighters[0]`, `fighters[1]` and `SimRoster.opp`, comments included, and does not count files ending `_check.gd` or folders named `tools`; the park's `fighters[0]` and `fighters[1]` are in its check).

The park's changes, against main's lines:

```gdscript
# BRUNT_KEYS (:32): the default for a file that leaves the key out
	"bruntMul": 1.8, "heldMul": 1.0, "tierFactor": [0.12, 0.27, 0.47, 0.73], "specialTier": 4,

# _outcomePower (:400): a marked building takes less of the body's energy
	var m: float = massOf(b) * _memory(b)

# _outcomePower (:416): a held hit by the floors' undamaged strength when heldMul is above 1.0, the old line otherwise
	var hm: float = float(cfg().heldMul)
	var oc: Dictionary = outcomeDmg(S, b, y, 2.0 * probe.sumS if through else (E / m * hm * probe.sumS0 if hm > 1.0 else E / m * probe.sumS))

# outcomeDmg (:482-496): sumS0, the covered floors' strength before any weakening, summed beside sumS and returned with it
```

What main's unchanged lines then do with a held hit that reaches what the floors have left: `outcomeDmg` returns `punch` (`:491-493`); `:420-422` set `pass` false, `keep` 0 and `held` true; `applyFloors` clears the covered floors and sends the floor event (`:1204-1213`), wears the core by a quarter of the hit, capped at half the building's hit points (`:1229`, `data/biomes/stages.json:11`), and runs the falling-stack test (`:1234-1237`); `hit` reads `passes` false and calls it a wall (`:991`, `:1012-1013`), unless the stack fell. World's record shows exactly this: floors gone, the body held, the tower standing.

**Nothing else changes.** `through` (`:1101`) and `chainPlan` (`:544`) call `outcomeOf`, which reaches `_outcomePower`. `lodgeSecondsOf` and `tierFactorOf` are untouched (rule 6; the lodge option is not built). `tierAt` is untouched (the model-off ladder still needs it). The house's held return (`:408`) and the tower without floors (`:410-413`) are untouched (rule 7).

A detail for World to weigh: a hit that only just fails to go through records up to twice the floors' undamaged strength, and a hit that goes through records twice their weakened strength (`:416`), which can be less. The floors are cleared either way; only the core's wear and the neighbours' share differ. Sizing the through hit the same way would remove the step and would change what a first-knock pass does today, so I would leave it.

### Hash discipline

- **No new state.** Marks exist, live in the packed array `bMarks` (`sim/core/state.gd:62`, `:186`, `:239`, `:272`), are hashed only when not zero (`hash.gd:265-267`) and are part of the untouched-building test (`hash.gd:402`). Floor damage exists and is hashed today (`hash.gd:261-264`), as is the rest of a building's record. `sumS0` is a value in a returned dictionary, not state. The new key is in `brunt.json`, which is in the replay's data key for every match (`replay.gd:274`).
- **A known gap, older than this page:** the network digest reads hit points, floors, people and wear for each building, not marks or floor damage (`net/desync.gd:78-84`). With memory on, two peers that differ only in a mark agree on the digest until the next send at that building changes its hit points. Whether to add marks to the digest is Netcode's call; I would not block on it.
- **The park moves no state hash with the shipped data:** with `repeatMarks` 0 no mark is written and `_memory` returns exactly 1.0; with `heldMul` 1.0 the old expression runs. With the model off `_outcomePower` is never called (`:436-437`). It does move the replay's data key, once, because the key enters the file (section 7).
- **What moves when `heldMul` goes to 2.0:** the data key again, and the state hash of every model-on match from the first tower hit that holds a body, with `repeatMarks` at 0 or 2. Model-off matches do not move.
- **What moves when `repeatMarks` goes to 2:** the state hash of every match in which a body strikes a building, from that tick on, model on or off. World measured the model-off case: the golden's matches differ from the first wall hit (`wall-hold-on/README.md:32`).

**Which golden window.** The brief asks GW1b or GW1c. The answer differs by piece:

| Piece | Window | Why |
| :--- | :--- | :--- |
| World's park (the code, the key at 1.0) | **With GW1a,** by the EP's call as the review records it (its re-check, M-04). World's README asks for GW1b | It moves no state hash. It moves the replay's data key. The GW1a pins need it under them |
| `heldMul` 2.0 | **With `repeatMarks` 2, in the wall-hold window** (the EP's placement, the review's R-2). World's README says GW1b | It is a state-hash row and a look change for every model-on match, and alone it gives only part of the ruling. It needs the review's R-1 settled, its side-by-side and QA's arm first |
| `repeatMarks` 2 (the wall-hold window's memory row) | **GW1c at the earliest, else GW2** (World's README says GW2) | It needs the key split, the split stands after terrain step 2 (`wall-hold-split/README.md:7`), and terrain step 2 is GW1c's own exit line (`A1-sprint.md:50`). Without the split, `repeatMarks` 2 also turns on the crater repeat Game Design ruled stays off (`sim/world/crater.gd:152`, `:184`; `buildings.md:292`) |
| `wallRebound` 0 | Whichever is open when Game Design, QA's read and its own check are in | A hash row for every match with a wall hit |
| `lodgeHold`, `wallStop`, `wallDepthHold` | **None until Orb has played them** | |

## 9. What breaks

**The pins over this fault** (`docs/world/pending/checks-gw1a/pins-gw1a.diff`, as re-cut at fe7dbc8a). World has already replaced both "known fault" ceilings, so nothing is left to un-pin; what is left is below:

| Check | The row today | What replaces it, and when |
| :--- | :--- | :--- |
| `wall_hold_check`, model on | Re-cut by World with the park (diff line 567): it sets `heldMul` 2.0 while the model is on and asserts that three sends break the covered floors of more towers with memory than without, and that no fewer fall. The record: 24 of 24 against 0; 0 towers down either way | The fault's ceiling is gone. Two things remain. The row sets `heldMul` 2.0 itself, so it passes whatever the data says. And `_repeats` still sends real launches at tiers 1 and 2 from 3,000 units off (`sim/world/tools/wall_hold_check.gd:84-123`), which arrive at 1.7 to 3.9, so it never reads a send that goes through. How many towers are down is printed, not asserted, until section 6's row 1 is settled |
| `repeat_check`, model on | Off-path, with its reason (diff line 379): the row measures a house | It stays off-path. Its planner row ("plan 0.0, outcome 0.0") passes for the wrong reason with the model on and should be re-staged on a standing tower at 0, 1 and 2 marks, here or in `memory_model_check` |
| `brunt_check` | The `giveWay` row prints OFF-PATH (diff line 71) | It stays off-path (departure 7); its reason line should name `memory_model_check` as the model's row |
| `docs/world/pins-and-the-model.md` | Rows `:19` and `:20` re-written by World on 2026-11-20; `:32` still says the Game Design finding "stays open" | Line `:32` is stale: the finding is ruled (`buildings.md:331-345`) and built |
| `docs/world/pending/checks-gw1a/README.md` | `:51` names memory-under-model and wrecks-power as owed | Stale now: one is parked, the other is not needed |

**Rows the data rows must re-pin.** The parked wall-hold re-pin accepts exactly two rows of data, all five values off or all five on, "and not a mixture" (`docs/world/pending/wall-hold-on/wall-hold-pins.diff:8-10`). This page splits the five, so that test has to be re-cut whichever park lands first:

| Row | Today | Needed |
| :--- | :--- | :--- |
| `wall_hold_check`'s defaults row (`sim/world/tools/wall_hold_check.gd:129` on main; the two-row test in the parked re-pin) | Asserts all five at today's values, or (parked) all five on | Each of section 7's rows accepted on its own |
| `repeat_check`'s switch row (`sim/world/tools/repeat_check.gd:63` on main) | Asserts `repeatMarks` 0 | 0 or 2, as the parked re-pin already has it (`wall-hold-pins.diff:32`) |
| Any check that pins `heldMul` | None: `memory_model_check` and `wall_hold_check` set their own value | A row that asserts the data's value is 1 or 2, so a third value is noticed |

A trap for whoever lands this: on main's data today `WorldPin.shipped(true)` leaves the model **off**, because it restores the data's own switch (`pins-gw1a.diff:654-679`), and that is false (`power.json:4`). The "model on" passes are real only on a tree where the energy-on park has landed. `memory_model_check` does not depend on it: it starts its match with the setup word.

**Other checks:**
- `through_check`'s mark row passes without testing anything while `repeatMarks` is 0 (`sim/world/tools/through_check.gd:46`); it becomes a real row with the data row.
- `switchon_check` sets `repeatMarks` 2 for AI matches. With the model on those matches now play differently; its rows are about determinism and should hold. It should set `heldMul` too ("every switch on").
- `power_world_check`'s row "E 14 is held by a tall tower (mass 15): crack" (record, `runs/memory-under-model/power_world_check.txt`) changes with `heldMul` 2 in the data: twice 14 over 15 is 1.87, so the floors break and the body is still held. The row should assert "held" and print the floor outcome.
- `bystanders_check`: must be run once with both switches on, model on. Nobody dies.
- Parity and the nightly seeds: unchanged by the code; they move with each data row, once.

**Events (nothing new, a different mix):** `building_hit` carries `ratio`, `amount` and the speed at the face (`sim/core/fx.gd:492-500`); held hits are twice as large. A `wall` can now come with a `floor_hit` of kind `punch`. On repeats there are fewer plain walls and more lodges and `building_fall`s.

**Readers:**

| Who | What changes for them |
| :--- | :--- |
| Rendering, VFX, Audio | A wall hit that clears its floors (5.7). Floor marks are twice as heavy on a held hit. The same cues, more often in base-tier fights: punches, lodges, falls |
| Camera | More lodges and falls to frame. The slam's turn of the fight line stays off |
| Combat, Game Design | **What a knock pays.** A wall slam hurts the sent fighter twice the hit, staggers them and gives the attacker the first move (`brunt.gd:1022`, `:1054-1056`, `:1093`). A send that goes in through a broken face and lodges hurts once plus the leftover speed, with no stagger (`:1039`): 1.95 times through a hole, and 1.45 times through a marked wall at 4.94. So the knock that finally gets in pays a little less than the knocks before it and loses the stagger. Orb's sentence leans against a handicap for repetition (`vision.md:1462`). I am not designing a remedy here |
| Combat, Game Design | **Neighbours.** Buildings beside a hit take a quarter of its damage (`brunt.gd:1016`, `:1167`). A held hit is twice as large, so they take twice as much |
| Encounter | Plan and outcome stay one. Two existing terms steer the director **away** from a repeat: 12 off the score for the same building twice running and 4 on for an undamaged one (`sim/director/launch.gd:53`, `:49`, `:894`, `:899`). So memory shows mostly when the player steers at the same tower. I am not proposing to change either |
| Encounter | **The wall kick** (off in data, `data/director/interrupts.json:623`) and the first move after a wall slam act only on a face that holds (`brunt.gd:1020`; `sim/director/wallkick.gd:5`). With memory on fewer faces hold, so a fighter who taps for the kick at a marked or broken face finds no wall and is lodged instead. That bears on player agency. Encounter says whether an armed kick should still take a face a mark would open |
| Encounter, World | The planner's collateral read counts only buildings a chain collapses outright (`brunt.gd:583-588`). A tower brought down by the lodge's last hit is not in it. That blind spot exists today for strong sends; memory makes it commoner |
| QA | Lodges rise. The band of 2 to 5 wall slams (`buildings.md:80`) needs a model-on base reading first |
| Netcode | The digest gap above |
| Performance | More falls a match. No reading asked unless the launch tick shows it |
| Shots | A body's held hit records twice the floor damage, and shots read that damage on both paths (`sim/world/blast.gd:186`, `:193` write it), so a shot punches a body-damaged floor sooner, and a body breaks a shot-damaged floor sooner. Small, and in the direction of Orb's words |

## 10. Build order and owners

| # | Step | Owner | Needs first | Hash | Window |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | Settle the order of the parks that edit the same checks (`memory-under-model` first, then `pins-gw1a` as re-cut, which needs it; `wall-hold-pins`; `wall-hold-split`) and re-cut whichever lands second | EP, World | | no | GW1a for the park and the pins; GW1c for the split |
| 2 | Game Design reads section 6, row 1 (is it the struck floors or the tower that comes down by the third send) and row 15 (the review's R-1, which is close kin to the question for Orb in section 13) | Game Design | step 7, if Game Design wants Orb's picture first | | before step 11 |
| 3 | World's park lands (the review's verdict: the code can land) through the EP's gate | World, EP | nothing (the review tried both diffs with `git apply --check`) | no state hash; the replay's data key moves | GW1a, by the EP's call |
| 4 | The rows section 11 marks as to add, in `memory_model_check`; the review's R-1 row (the fighter's state after a held hit that breaks floors); 2.1's notes | World | step 2 for R-1's rule | no | any |
| 5 | The review of step 4's rows, then the EP's gate: World's checks, the render gates, parity unchanged | Stand-in, EP | step 4 | | |
| 6 | The switch rows split in `tools/preview/switches.mjs` and `docs/tools/preview.md`; the schema's cases (the review's R-4) | Tools | step 3 | no | any time after step 3 |
| 7 | The EP asks Orb the question in section 13 | EP | | | before step 10; steps 3 to 6 do not wait on it |
| 8 | QA's memory read: 40 matches on planet 7, the same seeds, three arms (both off; the held hit on; both on), the model on, the cone rider on if it has landed | QA | the park on a scratch tree; a `dash=1` word in `qa/godot/qa_planet.gd` if the dash is not yet in main's data (its `power=1` sets no dash) | no | long run, below-normal priority |
| 9 | The look gate: the side-by-side of four knocks at one tower, default look; the EP's safety reading of the clip | World stages it; Tools' launcher captures; Rendering and VFX judge | the park on a scratch tree | no | |
| 10 | Game Design rules on the numbers and the rest of section 6, after Orb's answer | Game Design | steps 7, 8 and 9 | | |
| 11 | The data rows `heldMul` 2.0 and `repeatMarks` 2, together; Simulation re-records the golden once | EP, Simulation | steps 4, 8, 9 and 10; the key split; the energy model as main's default | **yes** | the wall-hold window: GW1c at the earliest, else GW2 |
| 12 | (folded into step 11) | | | | |
| 13 | `wallRebound` 0 as its own row, if Game Design and the EP say it may stand alone: a check that runs it alone, QA's city read, the re-pin | World, QA, EP | | yes | whichever window is open |
| 14 | Orb's private build: every row of section 7 on, with Encounter's `wall-hold-air`, and a side-by-side | Tools, World, Encounter | steps 3 and 6 | | not on main |
| 15 | `lodgeHold`, `wallStop` and `wallDepthHold` on main | EP | **Orb's word after playing step 14** | yes | whichever window is open then |

Step 15 is kept apart on purpose.

## 11. Readings

**The check:** World's `sim/world/tools/memory_model_check.gd` (verdict line `MEMORYMODEL`, already in the park's `tools/world-checks.json` line), extended. It already has the two ruled rows (3 and 4), the 7.5 part of row 5, row 10 and a house row, with real hits applied for the held rows (record: `docs/world/runs/memory-under-model/memory_model_check.txt`). The other rows are to add. It should start its match **as Orb's build does**, by the match's own setup words and not by the data or the pin:

```gdscript
SimCore.newMatch(S, seed, {}, {"intro": false, "power": true, "dash": true, "slip": true, "kick": true, "travel": 1.5})
# first row: ok(S.powerOn, "the energy model is on for this match")
```

The words are read at `sim/core/power.gd:118-122` and `sim/core/sim.gd:266`. New rows stage their sends **by their energy at the face** (`speed = SimPower.speedUnit * sqrt(E)`) and **apply them** through `WorldBrunt.hit`, as `repeat_check.gd`'s `send` does, so each send meets the floors the last one left. The two keys are set in memory and set back before the script ends. The staged energies are 1.7, 3.4, 4.4 and 4.94 for a tall tower (4.4 and 4.94 are both held by an unmarked tall tower and both above 3.94; any energy under 3.94 never goes through a tall tower by marks alone).

Every pass line below is arithmetic, a first value to be replaced by the first Godot record.

| # | Reading | First pass line | How |
| :--- | :--- | :--- | :--- |
| 1 | With the shipped data (`heldMul` 1.0, `repeatMarks` 0), the outcomes and the state hash are today's | Equal | the check |
| 2 | With `heldMul` fixed, a first hit on an untouched building is the same with `repeatMarks` 0 and 2 | Equal damage, ratio and speed kept | the check |
| 3 | **The ruled row:** three applied sends of 1.7 at a tall tower | wall, wall, wall; the covered floors cleared at the third and not before. Whether the tower is down: printed (arithmetic: standing, about two thirds of its core left) until section 6's row 1 is settled | World's row exists (record: 20, 20, 18 floors standing). To add: the three outcomes and the tower's state |
| 4 | **The ruled row:** two applied sends of 3.4 at a tall tower | wall, wall; the covered floors cleared at the second | World's row exists (record: 20, 18) |
| 5 | The lowest energy whose hit clears the covered floors on the first, second and third send, two floors covered | 7.5, 3.07, 1.43, within 3% | the check |
| 6 | A base full launch (4.94 and 4.4) at a tall tower, four sends | crack; floors cleared at the second, held; in through the hole at the third keeping 0.95; 24 of 24 | the check, 12 seeds, two energies |
| 7 | A light launch (2.47) at a tall tower | dent, crack, floors cleared at the third, in at the fourth | the check |
| 8 | A base full launch at a low tower | floors cleared at the first, held; in at the second | the check |
| 9 | A slow send (energy 0.62) at a house | held, then through at the second | the check |
| 10 | The mass at 0, 1, 2 and 5 marks | 1, 0.513, 0.263, 0.263 of it | World's row, kept |
| 11 | The body never leaves faster than it arrived, and keeps `sqrt((E - m) / E)` on the lowered mass | Every staged send that goes through a standing face | the check |
| 12 | The planner's first link against the outcome, at 0, 1 and 2 marks, on a standing tower and on one with its floors cleared | Same outcome, damage and speed kept | the check |
| 13 | The hold's seconds at 0 and 2 marks, level 0 | 0.5 s both | the check |
| 14 | The same staged sends twice | One state hash | the check |
| 15 | The model off, `repeatMarks` 2 | The ladder's 1.74 and 2.70, as today | `repeat_check`'s model-off pass, unchanged |
| 16 | Negative controls | `heldMul` 1.0: rows 3 to 8 fail. `repeatMarks` 0: rows 3 to 7, 9 and 10 fail | World's control (`_memoryOff`) fails 7 of its rows; these two are to add |
| 17 | Two light touches (energy 0.3 each), then a base full launch (4.94), at a tall tower | Recorded: by arithmetic the third goes through (ratio 1.25), though the first two did 2% and 4% of the floors' strength | the check. See the first risk in section 14 |
| 18 | The hurt the sent fighter takes on each of four knocks at one tower, both off and both on | Recorded: by arithmetic 2.0, 2.0, 1.95, 1.95 times the plain hit with both on at 4.94 | the check |
| 19 | The wall kick, switched on in memory: an armed kick at a tower with 0 and 2 marks, and at a broken face | Outcome recorded | the check; for Encounter |
| 20 | **The energy at the face of every send that strikes a tower,** by the sender's tier | Read, no band. The share at 3.94 or more at base tier says how often marks alone let a body through; World's staged launches read 1.7 to 3.9 | QA, from `building_hit`'s speed. **To be written** as a reader over `qa/godot/records.gd`'s events |
| 21 | **Rebounds off a building behind the fight line** | A rebound: a `building_hit` with outcome `wall` on a face more than 600 units (first value) behind the line, after which, before the hold's seconds are up, the body's depth has left the face by more than 150 units or the body is more than 150 units off the face along the line. **In the memory read: the same count with the switches on as with them off.** **0 only on a build with the cone and the wall's values on** (step 14) | QA, the same reader. **To be written.** The push alone cannot measure the bug: it reads 0 of 16 over 150 today with the model on (record), while the depth comes home in 48 ticks |
| 22 | Launches aimed more than 20 degrees off the blow's line | 0 (`buildings.md:322`) | Encounter's row, read in the same run |
| 23 | A fighter left stuck in a wall for more than a second | 0 | QA, the same reader |
| 24 | Sends that strike an already-marked building, a match | Read, no band yet. Under about 0.5 a match means memory is rarely seen unless a player steers for it, which is a question for Game Design | QA, from `building_hit` events by building index. To be written |
| 25 | Buildings struck three times or more by bodies: the share still standing at the end | The off arm is read first as the base; both on: under a half (first value) | QA, the same reader |
| 26 | Structures lost a match, and the collateral bands | Inside QA's existing bands (`buildings.md:88`); structures brought down by bodies up by no more than 2 a match (first value) | QA, existing records |
| 27 | Seconds a fighter spends held in buildings, a match; median match length | No more than 1.0 s over the off arm; within 10 s of it (first values) | QA, from `lodge` and `wall` events (to be written) and existing records |
| 28 | In-air chain links a match (knock, catch up, knock again) | Within noise of the off arm | QA, existing records if they count links; else to be written |
| 29 | Nobody dies | 0 | `bystanders_check`, run once with both switches on |
| 30 | The look | Passes the look gate on the side-by-side | step 9 |
| 31 | **The fighter's state after a held hit that breaks floors:** alone; with the stack above dropping; with the tower coming down | Whatever Game Design rules for the review's R-1 (held at the face, or through at a named speed); the planner's first link predicts the same | the check. Owed before the 2.0 row |

## 12. Size

Small in code, medium in everything around it.

- **World:** the code, the key, the schema entry and the first check rows are built and parked. Left: about fifteen more rows in `memory_model_check`, the rule and row for the review's R-1, one row in `power_world_check`, three stale lines corrected, and the re-cut of the clashing parks, which is the larger job and is owed whatever happens here.
- **QA:** one three-arm read of 40 matches, plus a small reader for rows 20, 21, 23, 24, 25, 27 and perhaps 28.
- **Tools:** the row split, a few lines.
- **Game Design:** one ruling pass on section 6 (rows 1 and 15 first, the rest after).
- **Simulation:** one golden re-record and its verify for the two rows together; another if the wall's values land later.
- **The look gate:** one staged clip, one capture, two or three judges.
- **The private build:** Tools, World and Encounter, with a side-by-side.
- **A rough token guess: 2 to 4 million for steps 3 to 8** (World's build is already spent), most of it World's check runs and QA's read. Steps 9 to 15 are not in it. It depends on whether QA's reader can be built on `qa/godot/city-read.js` or needs its own pass over the records, and on how many times the park stack has to be re-cut.

## 13. For Orb

One question, for the EP to ask.

**You knock a rival into a tall tower and the wall holds. You do it again, and this time the wall breaks. Where should the rival end up?**

- **A. Inside the tower.** They go in with the wall and get up inside.
- **B. Outside, stopped at the hole.** The wall comes away in front of them. Your next knock at that spot sends them in.
- **C. No preference.** The team picks.

*I think Orb would want A,* from Orb's own picture (`docs/ep/vision.md:1352`): "early in the fight a well-earned power hit could send an opponent through the side of a skyscraper and they recover inside". Two things should be said with it. That picture is of a single earned hit early in the fight, and with today's numbers a tall tower stops that first hit; this fix brings the going-in moment to the second or third knock, and having it on the first is a different change that Game Design would have to price. And the design above, as Game Design ruled it, is B.

What each answer changes:
- **A:** Game Design would write one new rule (a stopped knock that breaks the wall ends inside the tower), World would make one small change for it, and the answer to "what a knock pays" in section 9 changes.
- **B or C:** nothing; the page stands as written.

**A note for the EP, in place of a second question.** The draft asked Orb whether memory may go into the normal game before Orb has played it. I have taken that out: it is not an owner's decision. Orb's words already put destruction work in A1 on the team's recommendation (`vision.md:1804`: "I do want the planet, terrain, destruction, clipping all worked on heading towards the A1"), and memory is what Orb said to expect (`vision.md:1462`). I think Orb would want it landed on the team's gates (QA's read, the look gate, Game Design). The private build for the wall's hold carries both switches too, so Orb still sees everything together there. The EP may still choose to ask.

## 14. Risks, unknowns and what was not verified

**Risks**

- **A mark has no floor.** Any contact with a building leaves a full mark, however slow, aimed or not, by either fighter (`brunt.gd:970-971`; `:923-940`). Two light touches and then one full launch go through a tall tower at base, while the tower still looks nearly untouched. That follows `buildings.md:133` as written, but it is the cheapest route through a tower and it is not earned by power (`buildings.md:127`). Game Design should say whether it is wanted. A lever, as an option and not in the first build: a hit leaves a mark only when its energy over the mass is at least some share (a new key, first value 0, which is the ruling as written). Reading 17 measures it.
- **The knock that gets in pays a little less than the knocks before it** (section 9, Readers). A player who wants damage and the first move may prefer a fresh wall every time. With the director's own steer away from repeats, memory may be seen less than this page suggests.
- **Memory may rarely be seen.** If reading 24 comes back low, the fix is correct and mostly invisible unless the player aims for it. That would be Game Design's to weigh, not a reason to change this design.
- **Real knocks arrive slower than the staged ones.** World's launches from 3,000 units off reach the tower with 1.7 to 3.9, not 4.94. Section 1's "third knock goes in" is for a knock from close in. Reading 20 says how often that is.
- **The ruling's sentence and World's record part** on whether the tower or only its struck floors come down by the third send (section 6, row 1).
- **A held hit that breaks floors can become a pass the body did not pay for** (section 6, row 15; the review's R-1). Owed before the 2.0 row goes on.
- **World's README still asks for the 2.0 row in GW1b,** on its own. The EP's placement is with the memory row; the README should say so (the review's R-2).
- **Base-tier fights will bring down towers they did not before.** That is World's reading of the ruling (`wall-hold-on/README.md:23`); Game Design's words are `buildings.md:289` and `:344`. The audit's line is that no base-tier fight wrecks the planet. Readings 25 and 26 are the guard.
- **The held hit changes first knocks, not only repeats,** in every model-on match, with memory on or off. Its look and its numbers need their own arm in QA's read (step 8 has it).
- **The planner's collateral read misses towers that fall to the lodge's last hit.** Older than this page; commoner with it.
- **The bystander hold.** `playable-build.md:230` says nothing about bystanders changes while Legal's hold stands. Floors clear sooner and a held hit that clears floors scatters everyone on them, with the same harmless outcome. Whether that counts as a change under that hold is the EP's and Legal's reading, not mine.
- **Several parks edit the same checks.** Whoever lands second re-cuts, and World's park is now the bottom of that stack.
- **A base full launch against a low tower is 4.94 against 5,** by Game Design's design (`buildings.md:290`). A send that arrives a little faster than staged goes through on the first hit. With the held hit on, the one that does not go through breaks the floors anyway.

**Not verified**

- Every number in sections 2.1, 3, 5 and 11 that is not marked "record" is arithmetic on the code's formulas for one lone building. None is a Godot run. In a real match a send that gets in usually has another building or open ground behind it, and sends strike at different heights.
- Whether `bystanders_check`'s record in the park was run with `heldMul` 2.0 and `repeatMarks` 2 (2.1, note 4).
- Whether the GW1a pins fail without the park under them. I read the diff; I did not run it.
- The EP's two placements (the park with GW1a; the 2.0 row in the wall-hold window). I have them from the stand-in's review, not from the EP's own note.
- That the model was on in the build Orb played rests on `tools/preview/switches.mjs:70` and the brief; the code map found no row for it in the pack list, and I did not search the list myself beyond the `repeatMarks` line.
- Whether a mark is carried when a planet's ring turns or a place is laid again, the way hit points and floors are. A row for it belongs in the check once World says where that copy is made.
- Which window the energy model becomes main's default in: the energy-on park says GW1a (`docs/architecture/pending/energy-on/README.md:3`), `buildings.md:298` says GW1b.
- Whether any view plays a warning before a building falls (departure 12).
- Whether a body coming off a wall ever starts a link of the in-air chain (5.6).
- Whether the 2026-11-20 wrecks record was a fresh run (the park's README still asks for a quiet window for that check). The numbers match the formula to the digit either way.
- Whether `brunt_check`'s "a tier-1 flight never punches an unmarked tower" holds with the model on for a fast body. World's record of 2026-11-20 shows it passing in both passes (`runs/memory-under-model/brunt_check.txt`).
- The line numbers `planet-a1-design.md` cites for the rebound were not re-checked here. The lines this page cites were opened.
- Who owns `tools/world-checks.json` (World or Tools). World's park edits it.
- What the 6a30b4c9 page sent for flat-out flight. It does not bear on buildings.

## Checks

Two independent reviewers attacked the draft, one on the code and one on the design; neither raised a blocker, so no checker ran. The fixer checked each of their 22 findings against the files or by arithmetic before using it, and found three changes on main made during the review (World's park, Game Design's ruling, and World's re-park with the held hit built) that the page is now rebuilt on.

| Finding (plain words) | Verdict | What changed |
| :--- | :--- | :--- |
| Found by the fixer: World parked the first half of the fix while the page was in review (883027af) | Fixed | The page no longer says no park exists. Section 2.1 reviews the park; rule 2 and rule 3 are marked as World's; the draft's helpers for the same thing are gone |
| Found by the fixer: Game Design ruled the held hit (`heldMul` 2.0), that a mark stays one model tier and that the mass stays 15 (bf9182dd) | Fixed | Sections 1, 5, 6, 7, 8, 10 and 11 rebuilt on the ruling. The draft's new key for a mark's worth, its 1.25-tier lever and its own-strength rule are withdrawn or folded into rule 4. All tables re-run in a second model. The draft's lodge rule is now an option only |
| Found by the fixer: World then built the held hit into the same park (fe7dbc8a), sized on the floors' undamaged strength as this page's draft argued, with 1.0 as off; and the stand-in's landing review of the park was committed with a re-check | Fixed | Sections 2.1, 7 and 8 now describe what World built instead of proposing code, and point to the review's findings by number instead of repeating them. This page's 0-as-off is withdrawn. World's records replace arithmetic where they exist (the floors). The EP's two placements, as the review records them, are in section 8's window table and section 10 |
| Code, major: the data row split the five wall values, which the parked re-pin and two checks on main reject | Fixed | Section 9 has a table of the rows each data row must re-pin, with the lines |
| Code, major: the own-strength rule's gate also resized hits that go through and first hits on shot-damaged buildings; the neighbours' larger share was not listed | Fixed | The rule is now the ruled held hit, held hits only, with its own switch. Reading 2 is narrowed to an untouched building. The neighbours' share and shots are in the Readers table |
| Code, major: `wall_hold_check` cannot read "the third send goes through" as it stands | Fixed | Section 9 says what `_repeats` does, what it must record, and that the row will not fail by itself. World's record of what its launches carry (1.7 to 3.9) is now used throughout |
| Design, major: Orb's "Wait until I play it" was stretched over all four wall values, and the page told Orb they had said so | Fixed | Section 7 goes value by value. The no-rebound value has its own row, with what could not be verified about it. Section 1's line re-worded. Departure 9 re-written with the right lines |
| Design, major: the rebound reading could not measure the bug (it reads 0 today) | Fixed | Reading 21 is defined by depth as well as push, with two pass lines and the record cited |
| Design, major: an open conflict in the record (a base power send lodges inside, against a tower holds at tier 1) was missing | Fixed | Departure 4 |
| Design, major: Orb's skyscraper sentence was used for something it does not say | Fixed | Section 13's recommendation re-written; the shortfall is in section 1 where Orb reads it first |
| Design, major: a mark has no floor, so two light touches open a tower | Kept as a risk | First risk in section 14, reading 17, and a lever offered as an option only. It follows the ruling as written, so it is Game Design's to weigh |
| Design, major: the knock that gets in rewards the attacker less than the ones before it | Kept as a risk | A Readers row with the numbers (re-run for the ruling: 1.95 and 1.45 against 2.0), reading 18, a risk line. No remedy designed |
| Design, major: the build order had no step for Orb's questions and two deciders for one thing | Fixed | Step 7 and step 10 in section 10; what each answer changes is under the question. Game Design rules after Orb's answer |
| Code, minors (five): the staged energies were not named; the replay and golden facts were listed as not verified though the files settle them; the window claim rested on a choice of line; `repeat_check`'s 1.00 was offered as evidence; "interior.gd has no model branch" was wrong | Fixed, all five held | Energies named in section 11. Sections 7 and 8 state the replay and golden facts with lines. Section 8's window table says the code moves no state hash and gives each data row its own window. Section 3 drops `repeat_check` as evidence. 5.6 re-worded with the lines |
| Design, minors (seven): three more departures missing; the second question was not an owner's decision; a schema line claimed a ruling that did not exist; the wall kick was not in the Readers; the in-air chain claim had no reading; two citation slips; the size left out half the work | Fixed, all seven held | Departures 11 to 13. The second question is now a note for the EP. This page's own schema proposal is withdrawn; World's cites a ruling that exists. An Encounter row and reading 19 for the wall kick. Reading 28 and a not-verified line for the chain. `vision.md:1800` cited; World's sentence no longer called the ruling's. Section 12 lists every owner and says what the token guess covers |
