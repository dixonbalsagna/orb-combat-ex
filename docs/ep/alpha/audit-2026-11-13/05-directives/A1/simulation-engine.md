# A1: Simulation & Engine Director

Leads: A-ENERGY-04, A-ENERGY-05, A-NET-05, A-CODE-02
Supports: A-CONTROLS-04, A-WORLD-01, A-COMBAT-08, A-CODE-01

Draft for the Executive Producer (EP) to send once Orb approves the path to Alpha. Nothing here is decided until then.

Goal: A build made plainly from main runs the same energy rules Orb played on 9 November, the old hero and villain meters no longer quietly change a fight, a replay from a different build is turned away with a plain sentence instead of failing halfway, and the game as shipped has its own saved reference matches.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A1, golden window GW1, decisions 5, 6 and 12); `docs/ep/alpha/audit-2026-11-13/02-areas/ENERGY.md`, `CODE.md`, `NET.md`; `docs/ep/alpha/audit-2026-11-13/01-inventory/I-08-data-schemas-switches.md`.
- A-ENERGY-04: the "one energy model" is off in data on main and in both played builds, and on in Orb's build only through a code patch the private page tool writes. Evidence: `data/fight/power.json:4`; `tools/preview/switches.mjs:918-919`; `sim/core/power.gd:118`.
- A-ENERGY-05: the backburnered hero and villain meters, hiding and ambush, and signature variants by biome still act in every match (damage, energy regain, beam contests, where the computer leads the fight), and the world feeds them on every building fall. Evidence: `sim/core/damage.gd:50-56`; `sim/core/fighter.gd:686-705`; `sim/director/beam.gd:208`, `:245`; also `sim/director/beamplay.gd:508-513`, `sim/director/location.gd:116-117`, `sim/world/collateral.gd:406-466`, `data/fighters/PROTAGONIST/meters.json:57-60`, `data/fighters/RIVAL/meters.json:5`.
- A-NET-05: a replay carries a hash of its data, its format and its input version but no build id, so a replay from a build with the same data and different code runs and fails at a checkpoint. Evidence: `sim/core/replay.gd:43`, `:116-136`; `net/lan.gd:506-512` (the LAN save keeps the build's commit beside the replay, `:511`); `docs/tools/lan-report.md`.
- A-CODE-02: the golden record (the saved reference matches) and five gates are valid only with the switches off, so the configuration Orb plays has none. Evidence: `tools/preview/bisect.mjs:38`, `:42`; `docs/tools/runs/6a30b4c9/build-and-smoke.txt:7-8`; `.github/workflows/ci.yml:191`.
- Spike S2 (a throwaway trial on a scratch copy; nothing lands): the gravity well (the pull that draws two fighters into a close fight) as a toy: size, zones and the snap. Read `docs/ep/proposals/gravity-well.html` (section 7 for its own plan and cost).
- Supports: A-CONTROLS-04 (3500 as the default flight speed; `sim/core/tools/power_check.gd:97-104` pins 3500 and 7000 as the range ends; `sim/core/hash.gd:106`). A-WORLD-01 (a match with no planet setup key plays the old arena: `sim/core/sim.gd:183`). A-COMBAT-08 (QA's probe for X-04, forms reached in a match).

You own: `sim/core/`, `docs/architecture/`.
- ask under NEEDS FROM EP for a grant: `data/fight/power.json` (the model's switch at line 4; the same file carries Game Design's flight-speed number, so the EP lands both in one edit)
- ask under NEEDS FROM EP for a grant: `data/fighters/PROTAGONIST/meters.json` and `data/fighters/RIVAL/meters.json` (Narrative's path)
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (only if a data shape changes)
- The lines in `sim/director/` and `sim/world/collateral.gd` are Encounter's and World's: list them under NEEDS FROM EP and the EP routes them. The same for the five gates named in `tools/preview/bisect.mjs`, for `.github/workflows/ci.yml`, for the build stamp Tools writes, and for the code patch in `tools/preview/switches.mjs` (Tools removes it once the data is on).

Acceptance criteria:
1. (A-NET-05, X-27) A saved replay carries the id of the build that made it. `SimReplay` refuses a replay from another build before the first tick and returns a reason a player can be shown; a test in `sim/core/tools/` loads a foreign replay and a home replay. Result saved under `docs/sim/runs/<sha>/`. This lands before GW1 so every replay made from then on is refused plainly by a later build. The sentence a player reads is forward-facing text: UI owns it and Orb sees it before use.
2. (A-ENERGY-04, X-15) The model is on in `data/fight/power.json` on main; no tool patches code to turn it on; `power_check` passes on main's own data. Checked again by reading the first desktop build's packed `power.json`.
3. (A-ENERGY-05, X-15) Written as Orb's decision 6 is recommended (keep the comeback as a rule for every fighter, set every other effect to zero in data, remove the code after Alpha); if Orb decides otherwise, the EP re-cuts this item. A check forces each meter to its two extremes and shows the same damage, energy regain, beam contest result and computer lead as with the meter at rest. The comeback rule is stated in data for both fighters. QA's win-rate batch before and after is saved (through the EP), because the Protagonist's only comeback rule hangs on his meter today.
4. (A-ENERGY-05) Hiding and ambush and signature variants by biome are each either zeroed in data or listed with the file and line that still acts and why. Nothing is deleted in A1.
5. (A-CODE-02, X-02, X-27) After A-CODE-01 closes, a golden record exists for the data as shipped; the five gates that only pass with the switches off are listed with their owners and pass on the shipped data; CI compares against the new record. A replay saved on that commit verifies to its last tick. Results saved under `docs/sim/runs/<sha>/`.
6. (Spike S2) One page under `docs/architecture/`: what was tried, what it cost, whether A-COMBAT-03 at "size, zones and the snap" is an extra-large or a large job, and the question for Orb ("up close, does your stick move only you?") with a clip to look at, asked for under NEEDS FROM EP.
7. (Supports) A-CONTROLS-04: `power_check` and the range ends agree with the new default, and the note says what else is keyed to absolute speeds. A-WORLD-01: the default for a match with no planet key is the round planet, in the same window. A-COMBAT-08: QA's form probe can read each form change from sim state; anything missing is listed.
8. Nothing here is meant to change the picture. If the trail or anything else on screen moves, it names the look gate (ADR 0010): a side-by-side against the reference build before the EP commits.

Constraints:
- Tokens: about 2.9M as an estimate (two rows of size M at 1.2M, two of size S at 0.25M), plus your share of the 4.5M set aside for the five spikes.
- State hash: A-ENERGY-04 and A-ENERGY-05 change the sim's state fingerprint and land only in golden window GW1, "Main is the game". A-NET-05 does not change it and lands before the window. A-CODE-02 re-records the reference matches once, when the window closes.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; a run over about ten minutes at below-normal priority; stop only your own processes by PID; no browser of your own.
- Determinism: seeded RNG, fixed step, float64, our own trig, no rendering state in the sim. Numbers live in data; a data shape change updates its schema in the same commit. Every sim window also runs Rendering's checks.
- Originality: nothing from an existing franchise.
- Orb's rules: plain words; forward-facing text is seen by Orb before use; no health bar on screen (a fighter's health reads from the fighter).

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: Orb's yes to decision 1; the working tree committed or deliberately ignored (A-PROCESS-03); A-CODE-03 (the played build's patches on main). A-NET-05 goes first. A-ENERGY-05 waits on decision 6; A-CODE-02 waits on A-CODE-01 (every owner's switch rows landed). Waiting on this: Game Design's flight speed (A-CONTROLS-04 reads the model you switch on); the first desktop build (A-TOOLS-01); QA's replay record (A-SAVES-01); in A3 the gravity well (A-COMBAT-03), which waits on spike S2's page and Orb's answer. The spike can start on day one on a scratch copy.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- GW1 is split (see `A1/ep.md`, Amendments): record the target golden first on the kept 9 November build's data; A-CODE-02's record for the game as shipped is that target, re-recorded once after GW1b's riders. A-ENERGY-05 lands in GW1b, not with the switch flip. (ORD-01, ORB-06)
