# A3: Encounter Systems

Leads: A-AI-07, A-COMBAT-01, A-COMBAT-02, A-CONTROLS-05
Supports: A-COMBAT-03, A-ENERGY-01, A-ENERGY-03, A-WORLD-10

Milestone A3 is "The fight's new rules, and LAN inside the game" (docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md). This brief is ready to send once Orb approves the plan; nothing in it is decided until then.

Goal: A player aims a beam with the right stick and the other fighter gets out of its way by flying off its line; both signatures fire from Orb's inputs (RT + RB + a flick of the right stick for the energy one, RT + a flick for the martial one) and from nothing else, for the player and for the computer; and fewer presses go unanswered.

Context:
- Read first: docs/design/beam-physics.md (lines 25-37 and 99); the page from spike S1 (the beam trial run in A1; the EP sends its path); sim/director/beamplay.gd; sim/director/beam_move.gd; sim/director/brawl.gd round line 3178; sim/director/ai.gd lines 260-278; docs/ep/vision.md lines 1654 and 1710; docs/ep/taste.md.
- A-COMBAT-01 (blocker, L, changes the fingerprint): "beam option A" (Orb's pick: a beam in space, aimed with the stick, escapable by moving off its line) is not built; a beam is still an exchange that always reaches its target and is decided by a timed press. Evidence: sim/director/beamplay.gd:2-4, :55-58, :398-420.
- A-COMBAT-02 (blocker, L, changes the fingerprint): signatures are not on Orb's inputs; the right stick is switched off in the input layer while RT is held, RT + B is the only signature input, and no martial signature exists for either fighter. Evidence: sim/director/brawl.gd:3178-3179; data/input/timing.json:49; data/combat/templates.json:964.
- A-AI-07 (major, S): no standing check proves the computer uses only inputs a player has; on main its signature is still the old B request that locks its rival. Evidence: sim/director/ai.gd:260-263, :275-278; sim/director/beam_move.gd:139-143; sim/director/tools/beam_ai_check.gd:2-6 (local only).
- A-CONTROLS-05 (major, M, changes the fingerprint): the latest count of unanswered presses is from an older build: 225 of 760 (30 percent), 97 of them with no word or buzz; none exists for the build Orb last played. Evidence: record docs/tools/runs/1931a0f8/b1-ledger-1229.txt; tools/feel/ledger.mjs; data/director/interrupts.json:611.
- Supporting rows: A-COMBAT-03 (the gravity well, led by Simulation & Engine), A-ENERGY-01 (the stamina, energy and body loop, led by Game Design), A-ENERGY-03 (energy's numbers into data, led by Simulation & Engine), A-WORLD-10 (a body that hits a building bounces back like a ping-pong ball, led by World & Environment).

You own: sim/director/, data/director/, docs/director/
- ask under NEEDS FROM EP for a grant: sim/input/layout.gd (lines 1050-1051 and 1263: the right stick with RT held), or have Controls & Game Feel make that change to your written need
- ask under NEEDS FROM EP for a grant: data/input/timing.json and data/input/layouts.json (the signature inputs)
- ask under NEEDS FROM EP for a grant: data/combat/templates.json (the signature rows; the martial signature's content comes from Combat & Choreography)
- ask under NEEDS FROM EP for a grant: sim/core/ (only if S1's page says the travelling beam needs new state there; list the lines)

Acceptance criteria:
1. Closes A-COMBAT-01. A beam is seen leaving the fighter, travels at a speed set in data, is aimed with the stick, and misses a defender who moves off its line: QA's beam escape probe (built in A1) shows a scripted defender's sidestep makes the beam miss at near, middle and far range (exit X-16, must pass). Saved under docs/director/runs/<sha>/.
2. Closes A-COMBAT-01. The beam struggle, the answers to a beam and the computer's beam play each still work or are named as changed, one line each, with the check that shows it. The beam lands behind its own switch with its own probe, and with the switch off the fingerprint is unchanged.
3. Closes A-COMBAT-02. A scripted pad fires the energy signature with RT + RB + a flick and the martial signature with RT + a flick, for each fighter; RT + B no longer fires a signature. A refusal count per input on scripted pads shows the flick does not collide with the stick's plain strikes or the transform chord (LT + RT). Saved under docs/director/runs/<sha>/.
4. Closes A-COMBAT-02 and A-AI-07. Exit X-17 (must pass): beams and signatures started by any input other than Orb's: 0, for the player and for the computer, counted by QA's beam trace over the scripted set and Orb's saved play files.
5. Closes A-AI-07. The computer's signature and beams go through the same inputs a player has; the hold-and-release check (sim/director/tools/beam_ai_check.gd) runs in CI (Tools adds it) and a record for this build is saved. The record covers Orb's complaint of 2026-11-06 (the computer charging beams at melee range).
6. Closes A-CONTROLS-05. The ledger's counting rule is fixed in writing before the count (it changed on 7 and 8 November, so older counts are not like for like); one count of unanswered presses on this build is saved, split into "with a word or buzz" and "silent". Exit X-03 here is a reading only: the number is recorded against the 30 percent, it does not have to pass.
7. Supports A-COMBAT-03: the close-fight rules read the well's zones where Simulation & Engine's brief says, instead of the three distance bands. Supports A-ENERGY-01 and A-ENERGY-03: stamina costs and energy numbers in sim/director/exchange.gd and sim/director/beam.gd are read from data, not literals. Supports A-WORLD-10: the launch settings at data/director/launch.json:94-95 change only as World & Environment's brief asks, through the EP.
8. Anything a player sees changing (the beam's flight, a signature's staging) passes the look gate (ADR 0010, docs/decisions/0010-look-gate.md): a side-by-side against the reference build named in docs/ep/taste.md (node tools/flash/side-by-side.mjs), seen by the EP before it is committed.

Constraints:
- Tokens: about 9.5M as an estimate (2 L, 1 M, 1 S at the register's size classes); supporting work is not counted. This queue sets the Alpha's date: say early if S1's size no longer holds.
- State fingerprint: A-COMBAT-01, A-COMBAT-02 and A-CONTROLS-05 change it. They land only in golden window GW2, "The fight's rules" (a golden window is one landing that changes the sim's state fingerprint, after which the saved reference matches are re-recorded once). A-AI-07 does not change it.
- Orb's rules: nothing drawn on, over or between the fighters (no aim marker, ring or line); no dissolves or fades; RT held stays the charge for Alpha unless Orb says otherwise; beam stages are built only if Orb picks them from S1's page and they fit inside this row.
- Machine rules: Godot runs headless only; at most 3 Godot processes for a short gate (never more than 6 in one session); a run longer than about ten minutes starts at below-normal priority, and a reading taken while the machine was saturated is marked invalid, not reported; pictures and clips come only through Tools' launcher (tools/machine/capture.mjs), one capture at a time; stop only your own processes, by PID; check nothing you started is still running before you end a turn.
- Determinism: seeded RNG, fixed step, no rendering state in the sim, shortest-arc wrap maths for every distance. Numbers live in data, not code; a change to a data file's shape updates its schema in tools/schemas/ in the same commit (ask under NEEDS FROM EP for a grant: tools/schemas/).
- Originality: every name, move, look and line is our own; nothing from an existing franchise.
- A director never briefs or messages another director: anything you need from one goes under NEEDS FROM EP and the EP routes it.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT). Keep it short. Report, then freeze the files you reported until the EP confirms the commit.

Order: Before this starts: golden window GW1 closed (main is the game Orb plays); spike S1's page read; Orb's decisions 11 to 14 confirmed; QA's probes for X-16 and X-17 exist. The signature inputs need Controls & Game Feel's stick change first. Waiting on this: Combat & Choreography's move table (A-COMBAT-04, in A4) starts the day the signature inputs are fixed; the energy loop's costs; the computer's play and every balance band after it.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- The close-fight part of the gravity well waits for Orb's answer from spike S2's clip; do not build the packet's default meanwhile. (ORB-04)
