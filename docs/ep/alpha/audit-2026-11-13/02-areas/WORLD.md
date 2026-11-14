# WORLD: the arena and world (Alpha audit, baseline 8901d351)

Read-only review. Game code is that of the last build Orb played, 6a30b4c9. "(uncommitted)" marks a path listed in `../baseline-status.txt`. "The line" below means the fight's line: the strip of ground the two fighters stand on, which the world turns under.

## Summary

- **Works:** nobody dies and nothing pays for a person (code, a CI check, three saved negative controls). The round planet exists in the sim (ground as nodes on a sphere, marks as records at planet points) and is what Orb's builds play. World's 85 checks pass in CI. Base-tier fights leave buildings almost untouched in the saved record.
- **Does not work:** on main the planet is not the game's world. A menu match plays the old hand-made arena; the globe comes from a preview patch and data switches main ships off. Custom planet setup has nothing under it: a seed only, one fixed size.
- **Held:** terrain step 2 (no shafts, settling, water only from a source) is built and parked; the played build has an "inland sea" in any deep hole and no shaft cap on planet marks.
- **Biggest gap:** X-11 cannot be met. No picker, no dials, no sizes, no cross-platform planet check, and LAN fixes one planet.
- X-14's "three times the width" is not met for the same blow and no check asserts a ratio.

## Questions and answers

**Q1. The globe, terrain deformation, buildings, bystanders, biomes: what's on the globe and what still assumes the old strip?**

On the globe:
- The ground: generation 3 is a lattice of nodes on a cube-sphere (`sim/world/field.gd:1-2`), read through `sim/core/field.gd` (the planet's radius at `:16`). Orb's builds set it (`net/lan.gd:30`, `planetGen: 3`; the solo build's `tree/data/biomes/field.json:8`).
- Marks: craters, trenches and scars are records at planet points in a store of up to 16,384 records of 16 numbers (`sim/world/store.gd:21-22`).
- The planet itself: a seeded pure function of a point (`sim/world/planet.gd:328`, `:532`), with climate, landforms, sites and lakes modules (I-03 inventory rows; not re-read in depth).

Still strip-shaped (each line spot-checked in code unless marked "plan's claim"):
- Without a `planet` key a match builds "today's world", the hand-made arena (`sim/core/sim.gd:183`). That is main's default (F-WORLD-01).
- A skid trench is cut at a fixed half width of one column, 32 units (`sim/world/crater.gd:624`, `sim/core/constants.gd:20`), at every power.
- The shaft cap reads the old strip's two columns (`sim/world/crater.gd:300-303`), which a globe match does not write; the step 2 park's README says so and measured it (`docs/world/pending/globe-step2/README.md:47` (uncommitted)).
- Sea is derived from the ground height alone (`sim/core/field.gd:455-457`), so a deep inland hole reads as sea.
- The tile ground draws the 16 nearest bowls only (`render/core/look.gd:596`).
- A launch's sideways reach is multiplied by 6 (`sim/core/constants.gd:17`).
- Plan's claims, not re-checked here: rubble heaps, trench banks, beam aftermath, fight water and trees slide with the line when the world turns; follow-ups find craters by strip position; buildings have no angle (`docs/ep/proposals/terrain-globe-plan.md:44-51` (uncommitted)).
- Fighter depth is off (`data/combat/depth.json:4`), so every body is on the line's centre; several of the plan's items only bite when depth comes on.

Biomes: 26 data files with schemas (I-03). Climate generation 2 is off on main (`data/biomes/climate.json:4`, `gen: 1`) and on in Orb's build (`tree/data/biomes/climate.json:4`, `gen: 2`).

**Q2. The terrain plan: step 1 landed; step 2 held; steps 3 to 9 remain. Which steps does Alpha need?**

- Step 1 (nobody gets hurt): landed, commit 6eec6a75; confirmed in code (F-WORLD-19).
- Step 2: built, parked, held. The gate with it applied failed Camera's chase check on 4 of 130 rows, a 0.14 to 0.15 jolt at a tick-96 split; the bisect put it on step 2 alone (`docs/ep/runs/6a30b4c9/README.md`; `chase-rush-fail-with-globe.log` last lines). Not on main: no `floodOn` or `floodLevelFor` anywhere under `sim/` (git grep, 0 files).
- Step 0 (measure first): partly evidenced. World's ocean probe is saved (`docs/world/runs/c7b0414b/step0-ocean-probe-tick-7380-7620.txt` (uncommitted)) and step 2 added a ported audit; QA's outcome counter and Rendering's drawn-versus-stood probe: not evidenced.

| Step | Alpha? | Why | Plan's cost (`terrain-globe-plan.md:325-334`, uncommitted) |
| --- | --- | --- | --- |
| 0 measure | required (finish) | every later measure needs today's number | ~2.5M |
| 2 no shafts, sourced water | **required** | the inland sea and uncapped digging are in the played build | ~3M, mostly spent |
| 3 trenches by force | required, trimmed to width and length | X-14: a slide's mark does not grow with tier | ~2.5M |
| 4 draw what's stood on | **required** | Orb's clipping, humps and brown-crater reports; an outside tester sees the same | ~2.5M |
| 5 nothing slides with the line | nice | visible only after a world turn; touches five directors | ~4M |
| 6 a cheap store | only if LAN's rollback measure fails | measure first (X-08) | ~2.5M |
| 7 slopes, walls, streets | nice (the building rebound part is the strongest case) | Orb's "ping pong" reports | ~4M |
| 8 the landscape answers back | after | about 12 switched-off features | ~7M |
| 9 tier 4 and planet scale | after | a design page first | ~1.5M |

Alpha's share is about 8M by the plan's own figures (steps 2 to 4, less what step 2 has already cost), against 31M for everything through step 8 (`terrain-globe-plan.md:336`).

**Q3. The tessellation engine: Alpha, or after?**

After. Reasons: (1) there is no design page, only Orb's ask (`docs/ep/vision.md:1695`); (2) the tile ground already has five mesh levels, 12,800 down to 800 units across (`render/core/tile_ground.gd:36`), and Research notes that the target renderer has no tessellation stage and denser tiles displaced in the vertex stage give the same result (`docs/world/ring-any-angle/quality-range.md:153`); (3) what a tester would notice is not mesh density but marks that are not drawn, which step 4 fixes. Cost of the Alpha part: L, about 2.5M (step 4). Cost of a real destructible-mesh system: L or more, estimate, no comparable. F-WORLD-17.

**Q4. The planet generator: what exists for X-11?**

- A generator that takes a seed (`sim/world/planet.gd:328`); a match names it with setup keys `planet`, `planetGen`, `touch`, `arena` (`render/core/main.gd:443-449`).
- No picker: the menu sets no planet (`render/core/main.gd:441-442`; RR-03 lines 84-87, 96).
- No dials: city count is one number in data (`data/biomes/planet.json:92`, `cities: 12`); climate and water are data files; none is a setup key (the setup keys read are listed by grep of `sim/core/sim.gd` and `planet_load.gd`: arena, planet, planetGen, touch and fight switches only).
- "Overhaul B" (plates: ranges, arcs, rifts) is built and off (`data/biomes/land.json`, `b.enabled` false in the build's copy at line 67); rivers are off (`rivers.json:4`). Rules for landmarks: sites and settlements modules exist (I-03); "recognisable but novel" rules as Orb asked (`vision.md:1718`) are a plan (`docs/world/planet-overhaul.md` section 2), not evidenced as built.
- Determinism: own trig and integer hashing (`planet.gd:6`), data hash folded into the replay (`planet.gd:51-57`), stored bit-exact vectors checked in CI (`sim/world/tools/planet_check.gd:2-4`).
- A fingerprint tool exists but has no verdict and is left out of CI (`sim/world/tools/planet_digest.gd:2-4`; `tools/world-checks.json:32`).

**Q5. World sizes: what exists, and what do they cost in frame rate?**

Nothing exists in code: the planet is 4,800 columns round by a constant (`sim/core/constants.gd:21`, "fixed"). The six sizes are a plan (`docs/world/planet-overhaul.md:86-142`): each doubles the loop, medium is today's. Its costs are arithmetic, by its own words (`:86`): whole-planet bake from 0.1 s (tiny) to 106 s (colossal) at today's spacing (`:121`). Frame rate by size: **not evidenced**; nobody has run a size other than today's.

**Q6. The default world: log the decision.**

No decision is recorded. Orb: no attachment to the current planet, likes random planets, "let's talk about deciding on a default" (`docs/ep/vision.md:1719`). Today: the solo copy opens on planet 7 by a page word in a shortcut (RR-03 line 86), LAN fixes planet 7 (`net/lan.gd:30`), main's menu plays the hand-made arena. Logged as F-WORLD-18 with a question for Orb.

**Q7. Bystanders: confirm nobody dies and nothing rewards it.**

Confirmed in code.
- The module's contract: nobody dies, nothing counts or pays for a person hit (`sim/world/collateral.gd:2-7`).
- Every damage path calls `scatter` (leave, or be flung and bounce): `structures.gd:472`, `:481`; `blast.gd:182`, `:189`; `brunt.gd:1212`, `:1222`, `:1291`. No `WorldCollateral.kill` call exists in code (one stale comment, `render/core/planet_view.gd:688`).
- No write to `casualties` anywhere under `sim/` (git grep); the field is marked retired (`sim/core/state.gd:494`).
- Meter gains read structure mass, a building's size class, crater width and fighter-on-fighter events (`collateral.gd:398-459`).
- Data says the same (`data/biomes/collateral.json`, `bystanders` block: "never hurt, removed or counted").
- Check `bystanders_check` is in CI (`tools/world-checks.json:17`); the landing record keeps three negative controls that fail as meant (`docs/world/runs/c7b0414b/README.md` (uncommitted)).
- Two leftovers: the launch planner still weighs lived-in buildings by a fighter's care number (F-WORLD-12), and the backburnered meters are still fed (F-WORLD-11). Neither hurts or counts a person.

**Q8. Water in dug ground, and the "flood" switch that's off.**

- Today any ground below the shore line reads as sea (`sim/core/field.gd:455-457`). Step 2's record: an inland crater 132 deep "reads as sea 46.8 deep, which is the inland sea in play today" (`docs/world/pending/globe-step2/README.md:21` (uncommitted)).
- The `flood` switch (`water.json flood.enabled`) is not on main at all: it is part of the held step 2 park and ships **off** there (`README.md:23`, `:45`). On, a hole 6 or more deep looks once for a source (sea, lake, water table) and an inland hole stays dry.
- Water v2 itself (`data/biomes/water.json:4`) is off on main and on in Orb's build (`tree/data/biomes/water.json:4`, with surfacing and the lake floor at `:61`, `:65`).
- Orb's "mysterious hump of ocean water" (`vision.md:1677`): cause not evidenced; the plan lists moving water as one candidate, unchecked (`terrain-globe-plan.md:49` (uncommitted)).

## Exit criteria

| Id | Status | Proof or gap | Measuring tool |
| --- | --- | --- | --- |
| X-11 | **Gap** | No picker, no size, city, climate or water setting (F-WORLD-01, -02, -08); LAN fixes one planet (F-WORLD-10). Same seed gives the same planet within one platform: vectors pass in CI run 43553420852 (Linux). Windows against Linux: not evidenced | Exists in part: `planet_check` (vectors, in CI) and `planet_digest` (fingerprints, no verdict, not in CI). Missing: a verdict and a run on Windows (F-WORLD-09) |
| X-14 | **Gap** | "No base-tier fight wrecks the planet": met for buildings in the saved record (at most 1.7% of structure mass lost at tier 1 over 22 matches, F-WORLD-21); for terrain, not measured. "3 times the width at top tier": not met for the same blow (1.32 times for an impact, 1.48 for a shot), met only by powering up (about 9 times) (F-WORLD-06, -22) | Exists in part: `blastcheck` prints craters by tier and asserts nothing; `power_world_check` asserts energies. Missing: one assert of the ratio, and a terrain measure for base-tier matches |

On the proposed number for X-14: "3 times the crater width" suits neither model in the code. With the energy model off, the tier term is +25% energy a tier (`crater.gd:55`), so 1.32 times the width. With it on (Orb's LAN and solo copies set it by a setup word, `net/lan.gd:27-30`), there is no tier term; a stronger fighter's send is simply faster. World records a top send of energy 60 digging a radius of 1,240 (`docs/world/power-world.md:13`, a file with uncommitted changes); a base send at 2,570 a second (`docs/world/planet-overhaul.md:118`) works out, by the rule at `crater.gd:87-89` and `:112-113`, to a radius of about 457 (my arithmetic, not a saved run), so about 2.7 times. **Recommend: restate as "a top-power send leaves a crater at least 2.5 times as wide as a base send, and at least 6 times the area", measured with the energy model on**, and keep "no base-tier match loses more than 3% of structure mass" from `data/biomes/collateral.json` (tier 1 ceiling 0.03).

## Findings

Gaps first, by severity; then what works. Evidence is abbreviated here; the full lists are in `WORLD.findings.json`.

| id | kind | statement | evidence | criterion | severity | alpha | owner | cost | hash |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F-WORLD-01 | gap | On main the round planet is not the game's world: no `planet` key means the hand-made arena, the menu never sets it, and Orb's globe comes from a preview patch plus switches main ships off | `sim/core/sim.gd:183`; `render/core/main.gd:441-449`, `:1644`; `tools/preview/stack-preview.mjs:6`; `data/biomes/water.json:4`, `climate.json:4` against the build's copies | X-11, X-13, X-05 | blocker | required | world-environment | M | yes |
| F-WORLD-02 | gap | Custom planet setup has nothing under it: seed only, size a constant, city count, climate and water fixed in data (as F-MODES-07) | `sim/world/planet.gd:328`; `sim/core/constants.gd:21`; `data/biomes/planet.json:92` | X-11 | blocker | required | world-environment | L | yes |
| F-WORLD-03 | gap | Terrain step 2 is built and parked, held on Camera's chase check (4 of 130 rows); planet marks in the played build are not held by the shaft cap | `docs/ep/runs/6a30b4c9/README.md`; `sim/world/crater.gd:300-303`; `docs/world/pending/globe-step2/README.md:18-19` (uncommitted) | X-14, X-13 | major | required | world-environment | M | yes |
| F-WORLD-04 | gap | Any ground dug below the shore line reads as sea wherever it is; the `flood` fix is only in the held park and off there | `sim/core/field.gd:455-457`; park README `:21`, `:45` (uncommitted) | X-13 | major | required | world-environment | S | yes |
| F-WORLD-05 | gap | Drawn ground is not stood-on ground: 16 nearest bowls drawn, planet trenches and scars not drawn (plan's claim), matching Orb's clipping and crater reports | `render/core/look.gd:596`; `terrain-globe-plan.md:54-58` (uncommitted); `vision.md:1690`, `:1695` | X-13 | major | required | rendering-techart | L | no |
| F-WORLD-06 | gap | X-14's 3 times width is not met for the same blow (1.32 and 1.48 times) and no check asserts any ratio; with the energy model on there is no tier term | `sim/world/crater.gd:55`, `:87-89`, `:112-113`; `data/biomes/blast.json` tierEnergy; `sim/world/tools/blastcheck.gd:17-25` | X-14 | major | required | world-environment | S | no |
| F-WORLD-07 | gap | A skid trench on the planet is one fixed width (64 across) at every power | `sim/world/crater.gd:624`; `sim/core/constants.gd:20`; `vision.md:1650` | X-14 | major | required | world-environment | L | yes |
| F-WORLD-08 | gap | World sizes are a plan only; frame-rate cost by size is unmeasured | `sim/core/constants.gd:21`; `docs/world/planet-overhaul.md:86`, `:101-109`, `:121` | X-11 | major | nice | world-environment | L | yes |
| F-WORLD-09 | gap | The planet hash comparison is not a check: no verdict, not in CI, Linux only (as F-MODES-12) | `sim/world/tools/planet_digest.gd:2-4`; `tools/world-checks.json:32`; `ci.yml:389` | X-11 | major | required | world-environment | S | no |
| F-WORLD-10 | gap | LAN fixes planet 7, touch-down 3, generation 3 as constants (as F-MODES-11) | `net/lan.gd:26`, `:30-32` | X-11, X-08 | major | required | netcode-online | M | no |
| F-WORLD-16 | gap | Outcrop bounces and the "ping pong" rebound off buildings, reported on three dates, are still open (plan step 7) | RR-08 lines 34, 48, 72; `vision.md:1687`; `terrain-globe-plan.md:50-51` (uncommitted) | X-13 | major | nice | world-environment | L | yes |
| F-WORLD-11 | gap | The backburnered meters are still fed by the world, and retired casualty fields are still in the state | `sim/world/collateral.gd:398-453`; `structures.gd:477`; `sim/core/state.gd:494`, `:508`; `sim/world/plan.gd:49` | X-15 | minor | nice | game-design | S | yes |
| F-WORLD-12 | gap | The launch planner still weighs lived-in buildings by care, and a comment says a roll "can read people"; Orb asked for these rows to be re-read | `sim/director/launch.gd:282`, `:326-327`, `:1283`; `collateral.gd:372-380`; `vision.md:1671` | none | minor | nice | encounter-systems | S | yes |
| F-WORLD-13 | gap | Many world features are built, off and never played; two modules are reached only by their own checks | `data/biomes/craters.json:4`, `fire.json:4`, `after.json:4`; the build's `rivers.json:4`, `land.json:67`; `sim/world/wrecks.gd`, `props.gd` | none | minor | after | world-environment | XL | yes |
| F-WORLD-14 | gap | The terrain plan and step 2's pages and records are uncommitted; several headers and comments are stale | `baseline-status.txt:750`, `:14645`; `sim/world/planet_world.gd:2`; `settlements.gd:4`; `ci.yml:384` | none | minor | nice | ep | S | no |
| F-WORLD-15 | gap | Orb's reported world problems have no bug rows and no owner | RR-08 lines 37, 52, 63-64, 73-76; `questions.md:16` | none | minor | required | qa-balance | S | no |
| F-WORLD-17 | gap | The tessellation ask has no design page; nearest work is the tile ground's five mesh levels | `vision.md:1695`; `render/core/tile_ground.gd:36`; `quality-range.md:153` | none | minor | after | rendering-techart | L | no |
| F-WORLD-18 | gap | No default world is decided | `vision.md:1719`; `net/lan.gd:30`; RR-03 lines 84-86 | X-11 | minor | required | orb | S | no |
| F-WORLD-19 | works | Nobody dies: only `scatter` and `fell` are called, the counter is never written, the check is in CI | `collateral.gd:2-7`; `structures.gd:472-482`; `blast.gd:182-189`; `brunt.gd:1212-1291`; commit 6eec6a75 | X-13, X-02 | none | n/a | world-environment | n/a | no |
| F-WORLD-20 | works | Nothing pays for a person: gains read mass, size class and crater width; negative controls saved | `collateral.gd:398-444`; `docs/world/runs/c7b0414b/` (uncommitted) | none | none | n/a | world-environment | n/a | no |
| F-WORLD-21 | works | Base-tier fights barely touch buildings: at most 1.7% of structure mass at tier 1 over 22 matches | `docs/world/runs/c7b0414b/structure-mass-by-tier-matches.txt` (uncommitted) | X-14 | none | n/a | world-environment | n/a | no |
| F-WORLD-22 | works | Powering up on the ground escalates: energy is tier to the 3.2, about 9 times the width at tier 4 | `crater.gd:56-57`, `:92-93`, `:112-113` | X-14 | none | n/a | world-environment | n/a | no |
| F-WORLD-23 | works | The planet is a seeded pure function with its own trig, hashed into the replay, with bit-exact vectors in CI | `planet.gd:6`, `:51-57`; `planet_check.gd:2-4`; CI run 43553420852 | X-11 | none | n/a | world-environment | n/a | no |
| F-WORLD-24 | works | 85 world checks run in CI with a guard against unlisted scripts; the job passed | `ci.yml:387-401`; `tools/world-checks.json:5-17`; CI run 43553420852 | X-02 | none | n/a | world-environment | n/a | no |
| F-WORLD-25 | works | The round-planet ground and its mark store exist and are what Orb's builds play | `sim/world/field.gd:1-2`; `store.gd:21-22`; `net/lan.gd:30-32` | X-13 | none | n/a | world-environment | n/a | no |

Cost bases: F-01, -02, -06, -08, -09, -10, -11, -12, -14, -15, -17 are "estimate, no comparable". F-03, -04 sit inside the plan's step 2 (~3M, mostly spent); F-05 is step 4 (~2.5M); F-07 step 3 (~2.5M); F-16 step 7 (~4M); F-13 step 8 (~7M) (`terrain-globe-plan.md:327-333` (uncommitted)).

Owner notes: F-WORLD-01 touches `render/core/main.gd` (Rendering's folder) and the menu (UI); World leads because the choice is which world data ships on. F-WORLD-12 sits in `sim/director/launch.gd`, Encounter's.

## Gaps the questions missed

1. **Main is not the played world (F-WORLD-01).** The specification asks what is on the globe; it does not ask whether a build made from main has a globe at all. It does not. This is the first thing to settle, because every world measurement for Alpha has to be taken on the data the candidate ships.
2. **X-14 has no assert (F-WORLD-06)** and its proposed number fits neither energy model.
3. **Trench width does not escalate (F-WORLD-07).** Craters grow with force; slides do not.
4. **Orb's world reports are untracked (F-WORLD-15).** Six reports, no bug rows, "no owner yet" in the EP's own answers.
5. **The plan the team works to is uncommitted (F-WORLD-14).**
6. **The energy model differs by build route.** LAN and the solo page turn it on by a setup word while the data ships it off (`net/lan.gd:27-30`; `data/fight/power.json:4`, the same in the build's copy). Crater sizing therefore differs between a plain match from main and Orb's copies (`sim/world/crater.gd:89`). Owner of that switch is Simulation and Game Design; noted here because X-14 must say which model it measures.

## Not evidenced

| What | One measurement that would settle it |
| --- | --- |
| The same seed gives the same planet on Windows and Linux | Run `planet_digest.gd` on both and compare the lines (generations 2 and 3, planet 7 and two random seeds) |
| Frame rate and load time by world size | Not possible until size is a variable; then the frame bench on small, medium and big |
| Whether a base-tier match wrecks the *terrain* (not buildings) | Step 2's ported audit (`globe_audit`, in the park) run on 40 base-tier-only matches: records, deepest relief, steps over a body height |
| The cause of the "hump of ocean water" and the "three humps in a crater" | A replay of Orb's saved play at those ticks with the store's records and the water columns printed (World's ocean probe is a start) |
| Whether the camera jolt that holds step 2 is step 2's fault or the check's | Camera's reading of the four failing rows with and without the park; not found on file |
| Whether the park still applies to the baseline | `git apply --check` of its three patches (not run here: read-only rules allow it, but the result would not change the finding) |
| Whether the 22-match structure record holds on the baseline's data | It was taken on a stack before landing (c7b0414b plus patches); a re-run on 6a30b4c9's packed data |
| Step 0's other tools (QA's outcome counter, Rendering's drawn-versus-stood probe) | A listing from QA and Rendering; none found by name under `sim/`, `qa/` or `tools/` |
| The plan's claims about heaps, banks, trees and water sliding with the line | A 15-turn round trip with a heap and a trench, positions printed before and after |

## Decisions for Orb

1. **What does "custom planet" mean for Alpha?** Recommended: a seed you can type or re-roll, plus three dials (number of cities, climate from cold to hot, water from dry to ocean), at today's one planet size. World sizes come after Alpha, once small and big have been measured for frame rate.
2. **What is the default world?** Recommended: a new random planet each quick match, with its seed shown on the result screen and saved in every report; the current planet stays as one named preset so reports and LAN tests can be repeated.
3. **Can the tessellation engine wait until after Alpha?** Recommended: yes. For Alpha, fix what you saw first: every crater and trench drawn exactly where fighters stand, no sea in inland holes, no bottomless digging.
4. **How big should the difference between a base-tier and a top-tier crater be?** Recommended: at least 2.5 times as wide (about 6 times the area) for a full-power send against a base send, with powering up on the ground staying at about 9 times. Game Design to confirm the number.
