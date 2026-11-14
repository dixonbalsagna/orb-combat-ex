# A1: Camera & Cinematography Director

Leads: A-CAMERA-01
Supports: A-RENDER-01, A-RENDER-07, A-RENDER-11

Draft for the Executive Producer (EP) to send once Orb approves the path to Alpha. Nothing here is decided until then.

Goal: A build made plainly from main, started with no special words, frames the fight with the camera Orb played on 9 November.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A1, decision 4); `docs/ep/alpha/audit-2026-11-13/02-areas/CAMERA.md`; `docs/decisions/0010-look-gate.md`; `docs/ep/taste.md`.
- A-CAMERA-01: the camera Orb played (swing, peak launch shot, launch director, close brawl, readable size, the 70/30 share, follow-through, flight reveal) switches on only when the game is started with the tile-ground word, and the share is 0.0 in main's data against 0.7 in both of Orb's builds. Evidence: `render/core/main.gd:243-252`; `data/camera/swing.json:4`; the packed `data/camera/swing.json:4` of the two kept builds; also `net/tools/lan_kit.mjs:127`, `tools/preview/switches.mjs:60-62`.
- A-RENDER-01 (Rendering leads): the look Orb plays is switched on only by launch words, and the swing camera rides with the globe ground. Evidence: `render/core/main.gd:243-251`; `render/core/tile_ground.gd:14`.
- A-RENDER-07 (EP leads): no record ties a visible landing to its side-by-side. Evidence: `docs/decisions/0010-look-gate.md:8`; `docs/ep/runs/6a30b4c9/README.md:1-8`.
- A-RENDER-11 (EP leads): the look gate's reference build is still d3f1ca0e of 2026-10-15, which predates the globe ground. Evidence: `docs/ep/taste.md:7`; `docs/decisions/0010-look-gate.md:9`; `tools/flash/side-by-side.mjs:17-22`.
- Started early for A2, in a separate brief sent the same day: the flashing measurements on the globe ground (A-LEGAL-01, your row) and the two parked camera safeguards (A-CAMERA-02; `docs/camera/pending/cd04/README.md`). "Parked" means finished work waiting outside main.

You own: `render/camera/`, `docs/camera/`.
- ask under NEEDS FROM EP for a grant: `data/camera/swing.json` (and any other file under `data/camera/` a switch row names)
- ask under NEEDS FROM EP for a grant: `render/core/main.gd` (Rendering's path: the block at lines 243-252 that turns the camera pieces on)
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (only if a data shape changes)
- The rows in `tools/preview/switches.mjs` and the word in `net/tools/lan_kit.mjs` are Tools' and Netcode's to remove once the defaults are in: name them under NEEDS FROM EP.

Acceptance criteria:
1. (A-CAMERA-01, X-13) Every camera switch row in the inventory table (`docs/ep/alpha/audit-2026-11-13/01-inventory/I-08-data-schemas-switches.md`) reads the same on main as in the played build's packed data, the share included, or has a written line saying why it stays as it is. Checked by the EP's row count and by reading the first desktop build's packed `swing.json` and its start line.
2. (A-CAMERA-01) A plain start with no launch word runs the eight camera pieces named above. Every test under `render/camera/tests/` passes on the new defaults, with none pinned to the old ones without a reason. Result saved under `docs/camera/runs/<sha>/`.
3. (Look gate, ADR 0010) The camera on main is compared with the 9 November build at the same ticks of one of Orb's saved play files: a side-by-side (`node tools/flash/side-by-side.mjs`; stills plus a short GIF) before the EP commits. Nothing is meant to move differently. The picture's file name goes in your report (A-RENDER-07).
4. (A-RENDER-11) One paragraph for the EP: which camera faults in the 9 November build you would list as "not part of the reference" if Orb names it as the new reference build (decision 4).
5. (A-RENDER-01) Your part of Rendering's scratch gate run: the camera tests that fail only because they never saw the globe ground are listed with a fix or a reason each.
6. Records: every gate result quoted is a saved file under `docs/camera/runs/<sha>/` (corrective item CD-22).

Constraints:
- Tokens: about 0.25M as an estimate (one row of size S).
- State hash: none of this changes the sim's state fingerprint. The camera reads sim state and never writes it.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; long runs at below-normal priority; no browser of your own (captures only through Tools' launcher, one at a time, each with a time limit); check nothing you started is still running before you end a turn.
- Determinism and data: camera numbers live in data; a data shape change updates its schema in the same commit.
- Originality: nothing from an existing franchise, shots included.
- Orb's rules: every camera move eases (a cut needs a reason); no dissolves, cross-fades, slow wipes or full-screen blur; nothing drawn on, over or between the fighters; no effect that costs frame rate for presentation; plain words. No new camera behaviour in A1: this is the 9 November camera, made the default. Nothing about flashing readings goes to Orb from you: it goes to the EP.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: Orb's yes to decision 1; the working tree committed or deliberately ignored (A-PROCESS-03); the round planet as main's default (A-WORLD-01), since the camera rides on the globe ground. In step 4 of A1's order the camera lands after the round planet and before the look (A-RENDER-01, A-RENDER-04). Waiting on this: A-CODE-01; the first desktop build's still comparison (A-TOOLS-01); the flashing measurements for A2, which must be read on the camera a tester will actually get.
