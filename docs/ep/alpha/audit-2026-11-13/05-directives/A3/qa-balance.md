# A3: QA & Balance

Leads: none
Supports: A-COMBAT-01, A-COMBAT-02, A-AI-07, A-COMBAT-03, A-ENERGY-01, A-ENERGY-07, A-NET-01, A-WORLD-06, A-WORLD-10

Milestone A3 is "The fight's new rules, and LAN inside the game" (docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md). This brief is ready to send once Orb approves the plan; nothing in it is decided until then.

Goal: Every new rule in the A3 build has a saved measurement behind it, so "you can dodge a beam", "the loser can still come back" and "two PCs stayed in step" are records and not impressions.

Context:
- Read first: qa/godot/beam_trace.gd; tools/feel/gauntlet.gd (the scripted player on Orb's scheme); docs/qa/runs/6a30b4c9/README.md; docs/ep/alpha/alpha-audit-specification.md lines 133-201 (exit criteria X-13 to X-17); the A3 section of docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md.
- A-COMBAT-01 (led by Encounter Systems): beam option A is not built. Evidence: sim/director/beamplay.gd:2-4, :55-58, :398-420. Your part: the beam escape probe at three ranges (exit X-16).
- A-COMBAT-02 and A-AI-07 (led by Encounter Systems): signatures are not on Orb's inputs, and no standing check proves the computer uses only inputs a player has. Evidence: sim/director/brawl.gd:3178-3179; sim/director/ai.gd:260-263. Your part: the count for exit X-17.
- A-COMBAT-03 (led by Simulation & Engine): no gravity well exists in code. Your part: the match checklist probe sees the pull (exit X-13, partial).
- A-ENERGY-01 (led by Game Design): no stamina or body number exists. Your part: the comeback measurement the loop's switch waits on. A-ENERGY-07 (led by UI & UX): the blind read of health, energy and readiness.
- A-NET-01 (led by Netcode & Online): no LAN match on the played build has a record from two real PCs. Evidence: docs/net/runs/6a30b4c9/lan-folder/README.md:5, :9.
- A-WORLD-06 and A-WORLD-10 (led by World & Environment): no check asserts a crater ratio between tiers; the bounce settings wait on a QA read. Evidence: sim/world/tools/blastcheck.gd:17-25; record docs/tools/runs/6a30b4c9/switch-list.txt:60; data/biomes/brunt.json:47-50.

You own: qa/, prototype/tools/
- ask under NEEDS FROM EP for a grant: docs/qa/ (no director owns it) for run records
- ask under NEEDS FROM EP for a grant: tools/feel/gauntlet.gd (Tools' path) if the scripted player must learn the new inputs

Acceptance criteria:
1. Supports A-COMBAT-01. The beam escape probe (built in A1) is run on the A3 commit: a scripted defender sidesteps at near, middle and far range and the beam misses each time (exit X-16, must pass). The rows are saved under docs/qa/runs/<sha>/.
2. Supports A-COMBAT-02 and A-AI-07. The beam trace's count is updated to the new intended inputs (the right stick; RT + RB + a flick; RT + a flick) and run over the scripted set and Orb's saved play files: beams and signatures from any other input: 0, for the player and for the computer (exit X-17, must pass).
3. Supports A-COMBAT-03 and the rest of exit X-13, partial. The match checklist probe (built in A1) reads one normal match and must find: a lap of the globe, each stance, a beam aimed and dodged, both signatures, a launch, the gravity well's pull, a crater, a building damaged, bystanders scattering. The transformation line is recorded but first required at A4.
4. Supports A-ENERGY-01. The comeback measurement: over a batch of scripted matches on the build's own packed data, how often the fighter who falls behind first still wins, with the loop off and on. Saved before the loop is switched on; say how many matches were needed to tell the two apart.
5. Supports A-ENERGY-07. You run the blind read on UI & UX's saved clips with a reader who has not seen the matches, and save the answers.
6. Supports A-NET-01. You read the logs and report folders from Orb and Orb 2's five LAN matches and write one page: state mismatches (the aim is 0), deepest rollback, anything either player reported.
7. Supports A-WORLD-10. The read the bounce switch row waits on: bounces per hit against a building and an outcrop, settings off and on, in scripted launches, with the energy model on. Supports A-WORLD-06: you check World's tier-ratio reading against one hand-measured case.
8. Also on the A3 commit, as readings only: the unanswered-press count is checked against Encounter Systems' figure (exit X-03), and every problem Orb reports from the A3 play goes into the bug list with a severity.

Constraints:
- Tokens: no lead rows in A3; supporting work is not sized in the register. Say in your report what each measurement cost.
- State fingerprint: your tools do not change it. Every reading is taken on the commit after golden window GW2, "The fight's rules" (a golden window is one landing that changes the sim's state fingerprint, after which the saved reference matches are re-recorded once) closes, on the build's own packed data, never on a switch list; a reading taken before the window is marked as such.
- Batches run with --headless and --jobs=3 (one job is two Windows processes); the long ones at below-normal priority. A banner-only Godot job that looks hung is probably starved by another session: check before stopping it, and stop only your own PIDs.
- A switch list is the plan, not proof: read the build's own data before you report what was on.
- Machine rules: Godot runs headless only; at most 3 Godot processes for a short gate (never more than 6 in one session); a run longer than about ten minutes starts at below-normal priority, and a reading taken while the machine was saturated is marked invalid, not reported; pictures and clips come only through Tools' launcher (tools/machine/capture.mjs), one capture at a time; stop only your own processes, by PID; check nothing you started is still running before you end a turn.
- Originality: every name, move, look and line is our own; nothing from an existing franchise.
- A director never briefs or messages another director: anything you need from one goes under NEEDS FROM EP and the EP routes it.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT). Keep it short. Report, then freeze the files you reported until the EP confirms the commit.

Order: Before this starts: your A1 tools exist (the probes for X-13, X-16 and X-17; the scripted player on Orb's scheme). The bounce read and the comeback baseline can start at once on today's rules; the rest waits for each feature's switch. Waiting on this: the loop's switch-on (A-ENERGY-01), the bounce row (A-WORLD-10), and the EP's call that A3's exit is met.
