# A3: Camera & Cinematography

Leads: A-CAMERA-05
Supports: A-WORLD-03, A-COMBAT-01

Milestone A3 is "The fight's new rules, and LAN inside the game" (docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md). This brief is ready to send once Orb approves the plan; nothing in it is decided until then.

Goal: In a LAN 1v1 each PC's screen is framed for the player sitting at it, the way a match against the computer is, instead of an even split.

Context:
- Read first: render/camera/split_rig.gd lines 636-637 and 895-908; net/lan.gd lines 7-12; docs/camera/split-vision.md line 95 (uncommitted); docs/ep/vision.md lines 1662-1663; docs/ep/taste.md.
- A-CAMERA-05 (major, M): the rig has no input naming this PC's player: the large pane goes to the one fighter of slots 0 and 1 with no computer driver, so the picture each PC shows in a LAN 1v1 is not evidenced by any saved record, and in LAN 2v2 each PC shows only its own fight until its player is out. Evidence: render/camera/split_rig.gd:895-908, :636-637; net/lan.gd:7-12.
- Orb's question on this row: on two PCs in a 1v1, should each screen favour its own player or stay an even split? Recommendation: favour the local player. Orb called the even split uncomfortable at speed.
- Supporting rows: A-WORLD-03 (World's terrain step 2 is held because your chase check failed 4 of 130 rows with it: records docs/ep/runs/6a30b4c9/chase-rush-fail-with-globe.log and docs/camera/runs/b34e32e1/sunday-energy/chase_rush_rows.txt lines 2-6; render/camera/tests/chase_rush_check.gd line 5), A-COMBAT-01 (the beam becomes a thing that travels through space; led by Encounter Systems).

You own: render/camera/, docs/camera/
- ask under NEEDS FROM EP for a grant: net/lan.gd (Netcode's path) only if the rig cannot be told which slot is local any other way; otherwise ask the EP to have Netcode pass it
- ask under NEEDS FROM EP for a grant: data/camera/ (no director owns it) for any new number

Acceptance criteria:
1. Closes A-CAMERA-05. The rig takes "this PC's player" as an input, and in a LAN 1v1 each PC gives its own player the framing Orb answered for (recommended: the local player favoured, as against the computer). Checked by one still from each PC at the same tick of the same LAN match, saved under docs/camera/runs/<sha>/, and by Orb and Orb 2 in play.
2. Closes A-CAMERA-05. A written line says what LAN 2v2 will show on each PC with this input, so A4 starts from a decision; nothing for 2v2 is built here.
3. Closes A-CAMERA-05. The camera tests still pass with the input unset (solo and two players on one PC are unchanged, shown by an identical-picture check or the side-by-side).
4. Supports A-WORLD-03: with World's step 2 on, the chase check passes all 130 rows, and you write one paragraph on what caused the jolt in the 4 failing rows (your side of it), saved beside the run.
5. Supports A-COMBAT-01: a travelling beam and the defender dodging it stay in frame at near, middle and far range; stills from QA's beam escape probe at the three ranges are saved.
6. All of this changes the picture: each change passes the look gate (ADR 0010, docs/decisions/0010-look-gate.md): a side-by-side against the reference build named in docs/ep/taste.md (node tools/flash/side-by-side.mjs), seen by the EP before it is committed. Camera and split-screen changes are compared against that reference until Orb names a newer one.

Constraints:
- Tokens: about 1.2M as an estimate (1 M at the register's size class); supporting work is not counted.
- State fingerprint: not changed. The camera reads sim state and never writes it; the check on your work is that the fingerprint is identical with and without it. The supporting work is verified on the commit after golden window GW2, "The fight's rules" (a golden window is one landing that changes the sim's state fingerprint, after which the saved reference matches are re-recorded once).
- Orb's rules: every camera move is eased; the split screen is clean and readable; no dissolves, fades, slow wipes or full-screen blur; nothing drawn on, over or between the fighters; nothing that costs frame rate for presentation.
- Machine rules: Godot runs headless only; at most 3 Godot processes for a short gate (never more than 6 in one session); a run longer than about ten minutes starts at below-normal priority, and a reading taken while the machine was saturated is marked invalid, not reported; pictures and clips come only through Tools' launcher (tools/machine/capture.mjs), one capture at a time; stop only your own processes, by PID; check nothing you started is still running before you end a turn.
- Originality: every name, move, look and line is our own; nothing from an existing franchise.
- A director never briefs or messages another director: anything you need from one goes under NEEDS FROM EP and the EP routes it.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT). Keep it short. Report, then freeze the files you reported until the EP confirms the commit.

Order: Before this starts: Orb's answer on favouring the local player; LAN inside the game (A-MODES-04, Netcode) far enough that a LAN 1v1 starts from the menu; the camera Orb played as main's default (A-CAMERA-01, A1). Waiting on this: exit X-08's two-PC play session; LAN 2v2's picture in A4. World's step 2 waits on your chase-check paragraph.
