# Review: a building remembers under the energy model (World's `memory-under-model` park)

- **Who:** Orb's stand-in, the landing reviewer of sprint A1.
- **When:** 2026-11-20, about 20:25.
- **What:** `docs/world/pending/memory-under-model/` (README, `memory-under-model.diff`) as committed in 883027af, its run records in `docs/world/runs/memory-under-model/`, the re-cut rows of `docs/world/pending/checks-gw1a/pins-gw1a.diff` in the same commit, and Game Design's ruling of the same evening (`docs/design/buildings.md:331-345`, commit bf9182dd). Read against main at e42b4609 and the EP's GW1a tree.
- **How:** read-only, by one reviewer, with arithmetic in a small scratch model. Nothing was run in Godot. Patches were tried with `git apply --check` on main and on a scratch copy of the GW1a tree's files.
- **Background:** the stand-in's design page for the same fault, `docs/ep/proposals/memory-under-the-model.md`, was written before World's park landed and without sight of it. It is kept as this review's reasoning: the code chain (its section 3), the arithmetic for first, second and third hits (5.4), and the readings (11).

Words used here: the **energy model** is the power rule Orb's builds play with (a body's energy against a building's mass). A **mark** is the count of sends that have struck a building. A **held hit** is one the building stops. The **golden** is the recorded reference matches. A **pin** is a change to a check so that it passes on the new tree.

## Verdict

**The rule is right and it is deterministic. The park can land as it is, because it changes nothing while `repeatMarks` is 0.** It is not yet enough to meet Game Design's ruling of the same evening: the ruling's numbers rest on a second code change that is not in the park (M-01), and the new `heldMul` value moves the golden on its own, with no marks at all (M-02). Three things are owed before the ruling can be called built: M-01, M-02 and M-03.

## Is the rule right against Game Design's page?

Yes.

| Question | Answer | Evidence |
| :--- | :--- | :--- |
| Is a mark "one tier higher", in the model's own terms? | Yes. A tier at equal power is `tierShare / 3` of a level, and energy grows by `energyTop` to the level, so one tier is an energy factor of 12.25 ^ (0.8 / 3) = 1.951. The park divides the building's mass by that: 0.513 for one mark, 0.263 for two | `sim/core/power.gd:182-187`; `data/fight/power.json:5` (`tierShare` 0.8); `power.gd:17` (`energyTop` 12.25); the diff's `_memory`; `buildings.md:133` "one tier higher for each mark on it, up to two" |
| Is lowering the mass the same as raising the send a tier? | Yes, everywhere the model's ladder reads it. `_outcomePower` uses the mass only as energy over mass: through when `E >= m`, the speed kept `sqrt((E - m) / E)`, a held hit's share `E / m`. The one difference is deliberate and good: the body never leaves faster than it arrived | `sim/world/brunt.gd:399-423` |
| Capped at two marks? | Yes: `mini(b.marks, repeatMarks)` | the diff's `_memory` |
| Houses need no rule of their own? | Yes, as ruled (`buildings.md:291`): the same factor applies, and a house is gone through either way | `brunt.gd:405-408`; `memory_model_check` row "a house is gone through unmarked and marked" |
| Does a mark make any hold longer? | No. The seconds a wall or a lodge holds a fighter read the sender's level and ignore the raised tier. A mark changes which outcome a landed blow gets, and nothing else touches the fighter. That is right for Orb's rule on player agency | `brunt.gd:610-613`, `:1040`, `:1052` |
| Did an independent design reach the same rule? | Yes. The stand-in's page reached "a mark is one model tier, mass divided by 1.951 and 3.805" from Game Design's page alone | `docs/ep/proposals/memory-under-the-model.md`, section 5.1 |
| Game Design's ruling on the park | "A mark stays one model tier, and a tower's mass stays 15" | `buildings.md:333` |

## Is it deterministic?

Yes.

| Point | Finding | Evidence |
| :--- | :--- | :--- |
| Nothing moves with the shipped data | With `repeatMarks` 0 the factor is exactly 1.0, and a mass times 1.0 is the same number bit for bit, so no outcome can change. Marks are also not written then | the diff: `if n <= 0 or _memoryOff: return 1.0`; `brunt.gd:970-971`, `:1111-1112`; `data/biomes/brunt.json:69` |
| A hurled wreck's flag | A wreck that has been thrown stores -1000 in the same field. `mini(-1000, 2)` is below zero, so the factor is 1.0 | `sim/world/wrecks.gd:12`, `:214` |
| The maths helper | `SimDetMath.pow`, the sim's own power function | `sim/core/detmath.gd:127` |
| Inputs are in the data hash | `energyTop` and `tierShare` come from `power.json`, `repeatMarks` from `brunt.json`; both files are in the replay's data key | `power.gd:61-64`; `brunt.gd:362` |
| New hashed state | None. Marks already exist, are hashed when `repeatMarks` is above 0, and are in the snapshot | `sim/core/hash.gd:265-267`; `sim/core/state.gd:148-158`, `:602-606` |
| The plan matches the outcome | The planner calls the same function with the same marks, and `hit` decides the outcome before it adds the mark | `brunt.gd:554`, `:968-971` |
| It applies | On main and on the GW1a tree's `brunt.gd` and `tools/world-checks.json`, clean | `git apply --check`, both |

## MAJOR

### M-01. Game Design's numbers need a second change that is not in the park

- **What is wrong.** With the energy model on, the damage a tower's floors have already taken cancels itself out. The floors' strength is read already weakened, and a held hit's damage is then set as a share of that same weakened strength. So the number that decides dent, crack or break is always exactly energy over mass, whatever the floors have taken before. Game Design's ruling counts on that memory: "a floor breaks when one hit's damage reaches its strength, less 25% of what it has taken" (`buildings.md:338`). On the code as it stands, with `heldMul` 2.0 simply multiplied in, neither of the two check rows the ruling names would pass.
- **Evidence.**
  - `brunt.gd:409` `var probe: Dictionary = outcomeDmg(S, b, y, 1.0)`; `:416` `outcomeDmg(S, b, y, (2.0 if through else E / m) * probe.sumS)`; `:488` the strength summed into `sumS` is "st - float(cm.wallMemory) * b.fdmg[j]"; `:490` `var ratio: float = dmg / sumS`. The weakened strength is on both sides, so the ratio is `E / m`.
  - The park does not touch these lines (its diff changes line 400 only).
  - `memory_model_check` cannot see this: its rows call `outcomeOf` on a tower whose floors are untouched each time (`_hit` sets the marks by hand and nothing is applied).
  - Arithmetic, a tall tower (mass 15, then 7.69, then 3.94), a held hit worth twice its share:

| The send's energy | As the code stands (the share alone decides) | If the damage is counted on the floors' own strength (what the ruling's sentence describes) |
| :--- | :--- | :--- |
| 1.7, three times | 0.23, 0.44, 0.86: dent, crack, crack. **Nothing falls** | 0.23, 0.44, then 0.86 against 0.83 left: **falls on the third** |
| 3.4, twice | 0.45, 0.88: crack, crack. **Nothing falls** | where two floors are covered: falls on the second. Where one is covered: 0.884 against 0.887 left, **short by 0.3%** |
| 7.5, once | 1.00: falls on the first | 1.00: falls on the first |
| Falls on the 1st, 2nd, 3rd send from | 7.5, 3.85, 1.97 | 7.5, 3.41, 1.65 (one floor covered) |

- **Fix.** World's re-cut for `heldMul` also counts a held hit's damage on the covered floors' own strength (`floorStr`), not the weakened sum, and says so in the README. The two rows Game Design names ("three sends of 1.7 bring a mass-15 tower down, and two sends of 3.4 do", `buildings.md:345`) run as real hits in a row on one tower, so the floors' damage builds up as it does in play. The second row uses 3.5, or stages the hit across two floors, because 3.4 on a single floor is under the line.
- **Owner:** World. Game Design confirms which basis its arithmetic used.
- **Limit:** arithmetic and reading. Nothing was run, and World's re-cut is not parked yet, so it may already do this.

### M-02. `heldMul` 2.0 moves the golden by itself, marks or no marks

- **What is wrong.** The park's README says "the golden is unchanged", and that is true of the park. It stops being true the moment `heldMul` 2.0 is in data: the ruling makes it a rule of the model's path for every held hit, not only for marked buildings. After GW1a the model is main's default, so every reference match in which a tower holds a body would change. That is a hash change and a visible one (floors crack or break sooner).
- **Evidence.** `buildings.md:333` "a held hit does 2 × E/m (`brunt.json` `heldMul` 2.0, model path only)", with no condition on `repeatMarks`. `brunt.gd:416` is reached by every held hit on a tower with floors. The README: "With `repeatMarks` 0 ... nothing moves: the golden is unchanged" and "it is inert until `repeatMarks` is above 0 ... so it can land first".
- **Fix.** One of two, written in the README before the re-cut is stacked. (a) `heldMul` ships at 1.0 and flips to 2.0 with the wall-hold data row in that row's window, so the code stays inert. (b) `heldMul` 2.0 is named as a hash row of GW1b, with a run of the golden with it in and out, and a side-by-side of a held tower hit in the default look. The new key also needs its line in `tools/schemas/biomes-brunt.schema.json` and Tools' cases in the same stack.
- **Owner:** World; Simulation for the window; Tools for the schema.

### M-03. A held hit that breaks floors can turn into a pass the body did not pay for

- **What is wrong.** Today a held hit's share is under 1, so it can only dent or crack. With `heldMul` 2.0 a held hit can reach 1 or more while the body's energy is still under the building's mass. The floors' outcome is then "punch": the covered floors are cleared, the stack above may drop, and if that drop or the core's wear brings the building down, `hit` lets the body through with `keepHi` of its speed. The model's own rule is that a body goes through only what it has the energy for, and the ruling says such a hit is "still held".
- **Evidence.** `brunt.gd:416-422`: when not through, only `pass`, `keep` and `held` are overwritten; `outcome` stays whatever `outcomeDmg` returned, "punch" at a ratio of 1 or more (`:491-493`). `:1204-1213` clears the floors on "punch"; `:1234-1237` runs the stack's drop. `:991` `var passes: bool = oc.pass or hitText == "collapse" or hitText == "pancake"`; `:999` gives `keepHi` when it passes without `oc.pass`. `:398` "a send can only go through what it can pay for". `buildings.md:341` "a send of 7.5 or more cracks them on the first, still held".
- **Fix.** World states the rule in the re-cut and adds a check row for it: a held hit that brings floors or the whole tower down leaves the body held at the face (or, if Game Design prefers, lets it through at a stated speed). Either way the planner's lookahead must predict the same thing (`brunt.gd:554-579`).
- **Owner:** World, with Game Design for the choice.
- **Limit:** by reading. This path cannot be reached in the park as committed.

### M-04. The re-cut GW1a pin describes a fix that GW1a does not contain

- **What is wrong.** The same commit re-cut two rows of `pins-gw1a.diff`. Before, both were labelled KNOWN FAULT with a ceiling and the owed park's name. Now `repeat_check`'s row is an unasserted OFF-PATH line, and `wall_hold_check`'s row says "with the energy model on a mark is one model tier of the building's mass (memory_model_check)". But the README places the park in GW1b. If GW1a lands with these pins and without the park, the check prints a rule the tree does not have: in GW1a's code a mark still does nothing with the model on, and `memory_model_check` does not exist there. The known fault would go from labelled to unlabelled for the length of GW1a.
- **Evidence.** `pins-gw1a.diff:379` (the OFF-PATH print, no `ok(...)`), `:523` (the new words; the assertion is only `d2 >= d0`). `memory-under-model/README.md:28` "Land with the model's other World work in GW1b". `docs/world/pins-and-the-model.md` rows for `repeat_check` and `wall_hold_check`, same commit.
- **Fix.** Either land `memory-under-model.diff` with GW1a (it is inert there, it applies on the GW1a tree, and the golden cannot move), or keep the KNOWN FAULT wording in GW1a's pins and change the words in the GW1b stack with the park. The first is simpler.
- **Owner:** World; the EP picks.

## MINOR

| # | What | Evidence | Fix | Owner |
| :--- | :--- | :--- | :--- | :--- |
| m-05 | "The golden is unchanged" is shown by argument, not by a record. The argument is sound, but the park's run folder has no parity or golden run, no lint, load-split or two-fighter count record | `docs/world/runs/memory-under-model/` holds seven files, all World checks | Add the parity run and the three gate records before it is stacked | World |
| m-06 | The lodge's last hit does not read the mark. With the model on it reads the sender's level, so a body that goes through a marked tower and stops inside does the same last hit as on an unmarked one. On the tier ladder the mark raised that hit too | `brunt.gd:602-606`, `:1035-1038` | Game Design says whether the mark should reach it. The stand-in's page found it mattered for bringing a holed tower down (its section 5.4), before `heldMul` existed | Game Design, World |
| m-07 | The chain inside a tower still reads the mark-raised tier and has no model branch. It is off in data everywhere. If it is switched on, a mark would count twice: once in the mass, once in the slabs it breaks | `brunt.gd:1031`; `sim/world/interior.gd:147-151`; `brunt.json:51` (`interiorChain` 0) | A line in the README's risks, so whoever switches it on decides its rule first | World |
| m-08 | The check's real-sequence cover is thin. No row plays three sends in a row through `hit` with the model on, none covers the meteor's pass (`through` also marks), and none compares the planner's lookahead with the outcome on a marked tower | `memory_model_check.gd` in the diff; `brunt.gd:1101-1112` | Add the rows with M-01's | World |
| m-09 | `_memoryOff` is a test switch kept as a static in shipped sim code. It is not hashed and a new match does not reset it. Other World test switches work the same way, and the check sets it back | the diff; `memory_model_check.gd` ends with `WorldBrunt._memoryOff = false` | None needed; a note in the README | World |
| m-10 | The "bit for bit" row compares the two results as text. The claim still holds, by the exact factor of 1.0 | the check's first two rows | Compare the fields, or keep the words to "the same" | World |
| m-11 | A stale line: `docs/world/pending/checks-gw1a/README.md:51` still lists owed parks by their old names | that line | Bring it up to date with the next re-cut | World |

## Confirmed fine

- The fault is real and is exactly as World wrote it: with the model on, `outcomeOf` returns from `_outcomePower` before any tier is read (`brunt.gd:436-437`), so the mark-raised tier was dropped.
- The wrecks finding was the check's staging, not a fault. With the model on, a thrown wreck's damage reads the thrower's level, and the old check left the thrower at tier 1. With the tier staged, the record grows 134.6, 269.3, 437.6, 644.1 (`docs/world/runs/checks-gw1a/with-the-model-on-after/`).
- `massOf` itself is untouched, so the collateral and terror readers that use it see no change (`brunt.gd:378-389`, `:583-588`).
- The negative control is real: with the memory forced off, five memory rows fail and the run reports it (`memory_model_check.negative-control.txt`).
- Nothing in the park switches on the lodge hold or any of the wall-hold values. Orb's answer on a fighter lodged in a building is "Wait until I play it" (`docs/ep/vision.md:1862`), and the park leaves that alone.
- Nothing is drawn differently by the park while `repeatMarks` is 0. When memory is on, what changes is which existing picture plays (dent, crack, hole, fall). Nothing new appears on or over a fighter.

## Where the stand-in's page and World's park differ

| Point | World's park | The stand-in's page | Now |
| :--- | :--- | :--- | :--- |
| A mark's worth | one model tier, from `power.json`'s own numbers | the same, with a data key (`powerMarkTiers` 1.0) so Game Design can turn it | Game Design ruled that a mark stays one tier, so no key is needed |
| A held hit's damage basis | unchanged (the weakened strength) | the floors' own strength (its rule 4) | needed for Game Design's numbers: M-01 |
| Tall towers falling by the third send | not reached; raised as a finding | a bigger mark (1.25 tiers) offered as the lever | Game Design chose `heldMul` 2.0 instead: M-02, M-03 |
| The lodge's last hit | unchanged | reads the mark (its rule 5) | open: m-06 |

## How this was done

One reviewer read the park, the code it touches, Game Design's page and the run records, and checked the arithmetic in a scratch model. No agents were used. The page under "Background" cost about 2.4M tokens in two attempts (the first stopped on the weekly limit); this review itself cost under 0.2M.

## Re-check of the re-parked version (commit fe7dbc8a, 2026-11-20, about 20:35)

World re-parked the fix with Game Design's held-hit rule. Read the same way: by one reviewer, by hand, nothing run. Both diffs were tried with `git apply --check` on main and on a scratch copy of the GW1a tree's files; they apply on both, the data row after the code.

**Verdict: the code can land. It is still inert as shipped (`heldMul` 1.0, `repeatMarks` 0). Two things are owed before the 2.0 row is switched on: R-1 and R-2.**

### What happened to the first review's findings

| Finding | Now | Evidence |
| :--- | :--- | :--- |
| M-01, the damage basis | **Fixed.** A held hit with `heldMul` above 1 counts on the covered floors' undamaged strength (`sumS0`), so earlier damage now builds up. The two rows Game Design named run as real hits in a row and pass: 1.7 three times leaves 20, 20, 18 floors of 20; 3.4 twice leaves 20, 18; 7.5 once leaves 18. With `heldMul` 1 the old expression is kept, in the same order of operations, so nothing moves | the diff's `_outcomePower` line and `outcomeDmg`; `memory_model_check` rows `_sends(...)`; `docs/world/runs/memory-under-model/memory_model_check.txt` |
| M-02, `heldMul` moves the golden by itself | **Fixed in the data, not yet in the words.** It ships at 1.0 and the 2.0 row is its own diff. See R-2 | `memory-under-model-data.diff`; the schema line in the same code diff |
| M-03, a held hit that breaks floors turning into a pass | **Still open.** See R-1 | |
| M-04, GW1a's pin words | **Settled by the EP:** the park lands with GW1a. The re-cut pin now sets `heldMul` itself, so it needs the park in the same stack. See R-3 | `docs/world/pending/checks-gw1a/pins-gw1a.diff:508`, `:533`, `:567` |
| m-05, no golden or gate record | **Half done.** The README now says the golden is unchanged; no parity, lint, load-split or two-fighter count record is in the run folder | `docs/world/runs/memory-under-model/` (nine files, all World checks) |
| m-08, real-sequence rows | **Done for the held hit** (three rows through `hit`). Still none for the meteor's pass or for the planner against the outcome on a marked tower | the check |
| m-06, m-07, m-09 to m-11 | unchanged | |

### Still owed

**R-1 (MAJOR, before the 2.0 row goes on). What happens to the fighter when a held hit breaks floors is not stated or checked.** With `heldMul` 2 a held hit now does reach the "punch" outcome, as the new rows show. The floors are cleared, but the three rows only count standing floors; none asserts where the fighter ends up. Two paths lead to a pass the fighter did not have the energy for:
- a second held hit beside floors already cleared makes a gap of more than two floors (`TUNNEL_MAX` 2, `brunt.gd:83`), the stack above drops (`:1234-1237`), and `hit` then treats the hit as passing with `keepHi` of the speed (`:991`, `:999`);
- each held hit also wears the core by a quarter of its damage (`:1229`); with twice the damage on the undamaged strength that comes sooner, and a collapse passes the same way.

The README's own words are "a hold breaks floors, and the core goes by its own rule". Game Design's are "still held" (`docs/design/buildings.md:341`). Fix: World states the rule (held at the face when the tower gives way under a held hit, or through at a named speed), adds a row that asserts the fighter's state after such a hit, and checks the planner's lookahead predicts the same. Owner: World, with Game Design.

**R-2 (MAJOR, a wording fix). The README places the 2.0 row in GW1b; the EP places it in the wall-hold window.** The README's file table calls `memory-under-model-data.diff` "the GW1b data row", and its last section says "the data row with GW1b" and "it flips in the GW1b window with the other data rows". The EP's note to the stand-in says the row goes in the wall-hold window. The EP's placement is the sound one: without `repeatMarks` 2 the row would change every held hit in the reference matches while giving only part of what Game Design ruled (three sends of 1.7 would still break nothing, because no mark lowers the mass). Fix: the README names the wall-hold window, and says the row and `repeatMarks` 2 flip together. Owner: World.

### Smaller points

| # | What | Evidence | Fix | Owner |
| :--- | :--- | :--- | :--- | :--- |
| R-3 | The current GW1a pins set `WorldBrunt.cfg().heldMul` and assert that floors break, so `pins-gw1a.diff` now depends on this park. Applied without it, `wall_hold_check`'s row would fail | `pins-gw1a.diff:508`, `:567` | Stack `memory-under-model.diff` before or with the pins, and say so in both READMEs | World, EP |
| R-4 | The README says "No grant", but the diff adds a line to `tools/schemas/biomes-brunt.schema.json`, which is Tools' file. That schema is closed and already has cases in `tools/fixtures/cases.json` | the diff's schema hunk; `biomes-brunt.schema.json:335` | Tools reviews the line and adds cases for the new key (under 1, over 8, wrong type), as it did for the wall cone | Tools |
| R-5 | The basis changes with the number: at exactly 1.0 a held hit counts on the weakened strength, and at anything above 1.0 on the undamaged strength. So 1.01 is not "one percent more" | the diff: `if hm > 1.0 else` | Say so in the schema's description, or give the basis its own key | World |
| R-6 | When a held hit breaks floors, the bystanders of those floors are all sent running. The cap for a held hit (`heldDeathShare` 0.6) applies only to a crack. Nobody dies: `bystanders_check` reports "81.0 people ran in the scatter runs, none died" | `brunt.gd:1204-1213`, `:1217-1219`; `docs/world/runs/memory-under-model/bystanders_check.txt` | Game Design says whether the cap should cover a held break too | Game Design |
| R-7 | A tower too short to have floors (under five) keeps the old held damage; `heldMul` is not read there | `brunt.gd:410-413`, unchanged by the diff | A line in the README | World |
| R-8 | The 3.4 row is staged at mid-height, where a fighter covers two floors. On a single covered floor (the top or bottom floor, or beside a gap) 3.4 is 0.3% under the line on the second send, by arithmetic | the first review's M-01 table | Note it, or stage one row there | World |

Cost of this re-check: under 0.2M tokens of the reviewer's own reading; no agents.
