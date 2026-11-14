# A3: World & Environment

Leads: A-WORLD-03, A-WORLD-04, A-WORLD-06, A-WORLD-07, A-WORLD-10
Supports: A-MODES-10

Milestone A3 is "The fight's new rules, and LAN inside the game" (docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md). This brief is ready to send once Orb approves the plan; nothing in it is decided until then.

Goal: The ground behaves the way a player expects: no bottomless shafts, a hole inland stays dry, a slide leaves a wider trench at higher power, and a fighter knocked into a building or a rock stops bouncing back like a ping-pong ball.

Context:
- Read first: docs/world/pending/globe-step2/README.md (your parked step 2, cut on 20713b02; uncommitted); docs/ep/proposals/terrain-globe-plan.md lines 42 and 50-51; docs/ep/runs/6a30b4c9/README.md and chase-rush-fail-with-globe.log beside it; sim/world/crater.gd; docs/ep/alpha/audit-2026-11-13/reads/RR-08.md lines 34, 48 and 72; docs/ep/vision.md lines 1650, 1656, 1677 and 1687.
- A-WORLD-03 (major, M, changes the fingerprint): terrain step 2 (no shafts, settling, the record list) is built and parked but not on main, held because the camera's chase check failed 4 of 130 rows with it; the jolt has no written cause. Evidence: record docs/ep/runs/6a30b4c9/README.md; sim/world/crater.gd:300-303; render/camera/tests/chase_rush_check.gd:5.
- A-WORLD-04 (major, S, changes the fingerprint): any ground dug below the shore line reads as sea at once, because the sea is derived from ground height with no source test; the fix (the flood switch) exists only in the parked step 2 and ships off there. Evidence: sim/core/field.gd:455-457; docs/world/pending/globe-step2/README.md:21 and :45.
- A-WORLD-06 (major, S): the "3 times the crater width at the top tier" of exit X-14 is not met for the same blow and no check asserts any ratio: an impact gains 25% energy a tier (1.32 times the width at tier 4), a shot 2.2 times the energy (1.48 times). Evidence: sim/world/crater.gd:55, :87-89, :112-113; data/biomes/blast.json (tierEnergy); sim/world/tools/blastcheck.gd:17-25.
- A-WORLD-07 (major, L, changes the fingerprint): a skid trench is cut at one fixed half width of 32 units at every power, so the mark a slide leaves does not grow with tier. Evidence: sim/world/crater.gd:624; sim/core/constants.gd:20; docs/ep/proposals/terrain-globe-plan.md:42.
- A-WORLD-10 (major, L, changes the fingerprint): a body that hits a building or an outcrop still bounces back, which Orb reported on three dates; the settings that would hold it are one switch row held off waiting on a QA read. Evidence: record docs/tools/runs/6a30b4c9/switch-list.txt:60; data/biomes/brunt.json:47-50; data/director/launch.json:94-95.
- Supporting row: A-MODES-10 (every LAN match is the same planet; led by Netcode & Online).

You own: sim/world/, data/biomes/, docs/world/
- ask under NEEDS FROM EP for a grant: sim/core/field.gd (the two hunks in your park's grant-simulation-field.patch; Simulation & Engine reviews)
- ask under NEEDS FROM EP for a grant: tools/lint-determinism.mjs and tools/world-checks.json (Tools' path; the park's lint patch and check lines)
- ask under NEEDS FROM EP for a grant: data/director/launch.json lines 94-95 (Encounter Systems' path; the launch half of the bounce settings)
- ask under NEEDS FROM EP for a grant: sim/core/constants.gd line 20 if the trench's width moves out of a constant into data

Acceptance criteria:
1. Closes A-WORLD-03. Step 2 is re-cut on the current main (the park may no longer apply), applied in the park's order (the lint first, then the world change, then the field grant), and the world checks pass with --run, not only --verify, each new check with a verdict line. The camera's chase check passes all 130 rows with step 2 on, and the cause of the old jolt is written down in one paragraph (Camera reads its side). Saved under docs/world/runs/<sha>/.
2. Closes A-WORLD-03. The report names what stops replaying: a replay or LAN save from a round planet with marks made before this window is refused plainly, not failed halfway.
3. Closes A-WORLD-04. With the flood switch on in data/biomes/water.json, an inland crater dug below the shore line stays dry and a trench cut from the coast fills along its length (the park's own check), and a still shows the picture agrees with the sim (Rendering confirms the view reads the pool from the same value). Saved under docs/world/runs/<sha>/.
4. Closes A-WORLD-06. A check exists that digs the same blow at the base tier and the top tier and reports the width ratio, for an impact and for a shot, with the energy model on; one reading is saved. This is exit X-14's first reading: the tool and the saved number are the criterion, not the 3 times (it must pass at A4). Do not tune energies to reach it without the EP's word: that would change the fingerprint.
5. Closes A-WORLD-07. A skid trench's width comes from data and grows with the slider's power tier; the same check reports trench width by tier and its reading is saved (X-14, first reading). A check shows a base-tier fight still does not wreck the planet. Wider trenches land only after step 2.
6. Closes A-WORLD-10. With the settings on, a scripted launch into a building and into an outcrop ends held or stopped, not returned: QA's read of the switch row is saved first (how many bounces per hit, off and on, and whether the energy model's one-bounce limit already cut the outcrop bounces), then the row goes on. Orb's check on the build: knock someone into a building and see.
7. Supports A-MODES-10: the planet hash check shows the same seed and choices give the same planet on both LAN PCs for more than one planet.
8. Everything here changes the picture (craters, trenches, water, how a body meets a wall): each passes the look gate (ADR 0010, docs/decisions/0010-look-gate.md): a side-by-side against the reference build named in docs/ep/taste.md (node tools/flash/side-by-side.mjs), seen by the EP before it is committed.

Constraints:
- Tokens: about 9.7M as an estimate (2 L, 1 M, 2 S at the register's size classes).
- State fingerprint: A-WORLD-03, A-WORLD-04, A-WORLD-07 and A-WORLD-10 change it; A-WORLD-06 does not as long as it only measures. They land only in golden window GW2, "The fight's rules" (a golden window is one landing that changes the sim's state fingerprint, after which the saved reference matches are re-recorded once).
- The world checks run one Godot at a time at below-normal priority, as your park's runs did. Never point an apply script at the repository root: check only, and hand the patch to the EP.
- Orb's rules: destruction is big and lasting; no bystander deaths (bystanders bounce or scatter); the terrain workshop of 2026-11-09 is after Alpha, so nothing from it is added here.
- Machine rules: Godot runs headless only; at most 3 Godot processes for a short gate (never more than 6 in one session); a run longer than about ten minutes starts at below-normal priority, and a reading taken while the machine was saturated is marked invalid, not reported; pictures and clips come only through Tools' launcher (tools/machine/capture.mjs), one capture at a time; stop only your own processes, by PID; check nothing you started is still running before you end a turn.
- Determinism: seeded RNG, fixed step, no rendering state in the sim, shortest-arc wrap maths for every distance. Numbers live in data, not code; a change to a data file's shape updates its schema in tools/schemas/ in the same commit (ask under NEEDS FROM EP for a grant: tools/schemas/).
- Originality: every name, move, look and line is our own; nothing from an existing franchise.
- A director never briefs or messages another director: anything you need from one goes under NEEDS FROM EP and the EP routes it.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT). Keep it short. Report, then freeze the files you reported until the EP confirms the commit.

Order: Before this starts: golden window GW1 closed, with the round planet as main's world (A-WORLD-01). Inside the brief: A-WORLD-03 first; A-WORLD-06 and A-WORLD-07 need it; A-WORLD-04 rides with it; A-WORLD-10 waits on QA's read. Waiting on this: X-14's pass at A4; the custom planet (A-WORLD-02) in A4; craters drawn where you stand (A-WORLD-05) in A5.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- A-WORLD-06 is the reading X-14 is decided on: say which two power levels are compared, with the energy model on. Keep, restate or tune is chosen before GW2 closes. (ORD-04)
