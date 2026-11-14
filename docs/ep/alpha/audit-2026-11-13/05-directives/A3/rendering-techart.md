# A3: Rendering & Technical Art

Leads: none
Supports: A-WORLD-04, A-WORLD-03, A-WORLD-07

Milestone A3 is "The fight's new rules, and LAN inside the game" (docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md). This brief is ready to send once Orb approves the plan; nothing in it is decided until then.

Goal: What the player sees on the ground matches what the game knows: a hole inland is drawn dry, a hole fed by the sea is drawn wet, and a wider trench is drawn wider.

Context:
- Read first: docs/world/pending/globe-step2/README.md (World's parked terrain step 2; line 61 notes that whether a view reads the pool from the same value has not been looked at); sim/core/field.gd lines 455-457; docs/ep/proposals/terrain-globe-plan.md; docs/ep/taste.md.
- A-WORLD-04 (major, S; led by World & Environment): any ground dug below the shore line reads as sea at once, because the sea is derived from ground height with no source test; the fix (the flood switch) ships off in the park. Evidence: sim/core/field.gd:455-457; docs/world/pending/globe-step2/README.md:21, :45.
- A-WORLD-03 (major, M; led by World & Environment): step 2 (no shafts, settling, the record list) is parked, not on main. Evidence: sim/world/crater.gd:300-303; record docs/ep/runs/6a30b4c9/README.md.
- A-WORLD-07 (major, L; led by World & Environment): a skid trench is cut at one fixed half width of 32 units at every power. Evidence: sim/world/crater.gd:624; sim/core/constants.gd:20.

You own: render/core/, render/shaders/, docs/rendering/

Acceptance criteria:
1. Supports A-WORLD-04. With the flood switch on, the water the view draws comes from the same value the sim uses: a still of an inland crater below the shore line shows it dry, and a still of a coastal trench shows it filled along its length. The stills and the line of code that reads the value are saved under docs/rendering/runs/<sha>/.
2. Supports A-WORLD-03 and A-WORLD-07. With step 2 on, craters, settled ground and trenches of different widths are drawn without holes, black fills or steps the sim does not have; your render checks pass on the commit, and a still per tier of the same slide is saved.
3. Everything here changes the picture: each passes the look gate (ADR 0010, docs/decisions/0010-look-gate.md): a side-by-side against the reference build named in docs/ep/taste.md (node tools/flash/side-by-side.mjs), seen by the EP before it is committed, and both modes of the flashing clip check are run before you report a look.

Constraints:
- Tokens: no lead rows in A3; supporting work is not sized in the register.
- State fingerprint: rendering reads sim state and never writes it. The ground rules themselves change the fingerprint and land in golden window GW2, "The fight's rules" (a golden window is one landing that changes the sim's state fingerprint, after which the saved reference matches are re-recorded once); your checks run on that commit.
- Orb's rules: destruction is big and lasting; no full-screen blur or haze; no effect that drops the frame rate (anything that reads back from the GPU or adds a full-screen pass needs Performance's timing first). The Compatibility renderer is the baseline.
- Posed stills of depth need the held-depth pin; a relative --out path lands in the repository, so give an absolute scratch path.
- Machine rules: Godot runs headless only; at most 3 Godot processes for a short gate (never more than 6 in one session); a run longer than about ten minutes starts at below-normal priority, and a reading taken while the machine was saturated is marked invalid, not reported; pictures and clips come only through Tools' launcher (tools/machine/capture.mjs), one capture at a time; stop only your own processes, by PID; check nothing you started is still running before you end a turn.
- Originality: every name, move, look and line is our own; nothing from an existing franchise.
- A director never briefs or messages another director: anything you need from one goes under NEEDS FROM EP and the EP routes it.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT). Keep it short. Report, then freeze the files you reported until the EP confirms the commit.

Order: Before this starts: World's step 2 re-cut on main and applied in a scratch copy. Waiting on this: World's report on A-WORLD-04, and exit X-14's first reading. Working ahead for A4: nothing in this brief; the EP sends A4's work separately.
