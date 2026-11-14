# A3: VFX

Leads: A-RENDER-13
Supports: A-COMBAT-01

Milestone A3 is "The fight's new rules, and LAN inside the game" (docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md). This brief is ready to send once Orb approves the plan; nothing in it is decided until then.

Goal: Nothing is drawn on or round the fighters that Orb has not chosen to keep, and a beam is seen leaving the fighter and crossing the space between them.

Context:
- Read first: docs/ep/taste.md line 27; render/vfx/zip.gd lines 7 and 12-14; render/vfx/reach.gd lines 785-786; render/core/main.gd line 165; render/anim/render_anim.gd line 68; docs/decisions/0010-look-gate.md.
- A-RENDER-13 (minor, S): the zip and press effects draw marks on and round the fighters (a charge ring, a diamond, a double ring, a squeezing ring with brackets, a ring on the striking hand), which the taste page lists as never to ship, and they are live by default. Evidence: docs/ep/taste.md:27; render/vfx/zip.gd:7, :12-14; render/vfx/reach.gd:785-786. The audit did not verify this row independently: confirm each mark by reading the code first.
- The row's risk: Orb approved the zip's look on a prototype before the no-markers rule of 2026-10-18, and removing marks may cost readability, so it needs Orb's eye, not a rule lookup. Orb's question: keep or remove, decided per mark from one clip of each.
- Supporting row: A-COMBAT-01 (beam option A: a beam that leaves the fighter, travels at a speed and can be dodged; led by Encounter Systems).

You own: render/vfx/, art/vfx/, docs/vfx/
- ask under NEEDS FROM EP for a grant: render/core/main.gd line 165 (Rendering's path) and render/anim/render_anim.gd line 68 (no director owns render/anim) if a mark is switched on from there
- ask under NEEDS FROM EP for a grant: data/vfx/ (no director owns it) for any switch or number

Acceptance criteria:
1. Closes A-RENDER-13. A list of every mark the zip and press effects draw on or round a fighter, each with its file and line and one short clip from this build with the inputs shown at the screen's edge, saved under docs/vfx/img/ and docs/vfx/runs/<sha>/. The EP puts the clips to Orb as one question per mark.
2. Closes A-RENDER-13. Each mark Orb removes is off by default in data; each mark Orb keeps is written into docs/ep/taste.md by the EP as an exception in Orb's words. Where a mark goes, the same information is carried by the fight itself (pose, effect on the body, sound, rumble), not by another marker.
3. Supports A-COMBAT-01: the beam's picture follows the sim's travelling beam (its head, its length and its width as the sim reports them), is crisp and unmistakable per fighter, and a miss reads as a miss. Stills at near, middle and far range from QA's beam escape probe are saved.
4. Every change here alters the picture: each passes the look gate (ADR 0010, docs/decisions/0010-look-gate.md): a side-by-side against the reference build named in docs/ep/taste.md (node tools/flash/side-by-side.mjs), seen by the EP before it is committed. Any effect that reads back from the GPU, copies the frame or adds a full-screen pass needs Performance's timing first.
5. Because the new beam changes what is on screen, the gates on A2's "before an outside tester plays" list that measure the picture are re-run on the A3 commit by their owners; give the EP the list of your effects that changed.

Constraints:
- Tokens: about 0.25M as an estimate (1 S at the register's size class); the beam's picture is supporting work and not counted.
- State fingerprint: not changed. Effects read sim state and never write it. The beam's picture is verified on the commit after golden window GW2, "The fight's rules" (a golden window is one landing that changes the sim's state fingerprint, after which the saved reference matches are re-recorded once).
- Orb's rules: nothing drawn on, over or between the fighters; no dissolves, fades, slow wipes, full-screen blur or haze; no soft, blurry blocks where a crisp beam should be; nothing that drops the frame rate; pictures go in docs/vfx/img/, never in Orb's homework folder; clips Orb judges show the button and whether it was tapped, mashed or held.
- On the Compatibility renderer (the baseline), check each shader on the web build as well as the desktop build.
- Machine rules: Godot runs headless only; at most 3 Godot processes for a short gate (never more than 6 in one session); a run longer than about ten minutes starts at below-normal priority, and a reading taken while the machine was saturated is marked invalid, not reported; pictures and clips come only through Tools' launcher (tools/machine/capture.mjs), one capture at a time; stop only your own processes, by PID; check nothing you started is still running before you end a turn.
- Originality: every name, move, look and line is our own; nothing from an existing franchise.
- A director never briefs or messages another director: anything you need from one goes under NEEDS FROM EP and the EP routes it.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT). Keep it short. Report, then freeze the files you reported until the EP confirms the commit.

Order: Before this starts: the look defaults from A1 (A-RENDER-01, A-RENDER-04) on main, so the clips show the game Orb plays. The clips can be cut at once; removal waits for Orb's answer per mark. The beam's picture waits on Encounter Systems' travelling beam. Waiting on this: the re-run of A2's picture gates on the A3 commit, and the A3 PLAY THIS page.
