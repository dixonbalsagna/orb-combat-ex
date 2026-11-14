# A4: Camera & Cinematography

Leads: none
Supports: A-MODES-09, A-MODES-03, A-MODES-02

Goal: In a 2v2 the picture eases out to hold all four fighters when the two fights are near, and in a horde the player and every weak enemy near them stay readable, with no cut, marker or fade doing the work.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A4); `docs/rendering/2v2-drawn-plan.md` (Camera's row: ease the frame to hold all four, own pair first, no cuts, no markers; it reads `SimHost.other_x`, `other_z` and `other_pose`, already on main); `docs/ep/alpha/audit-2026-11-13/02-areas/MODES.md` (F-MODES-03, F-MODES-10); `docs/camera/split-vision.md`; `render/camera/split_rig.gd`; Game Design's horde page (the EP gives the path); `docs/decisions/0010-look-gate.md`; `docs/ep/taste.md`.
- A-MODES-09 (Rendering leads): each screen shows only its own fight; Orb reported never seeing all four fighters together. Evidence: `render/core/main.gd:242`; `docs/rendering/2v2-drawn-plan.md`, under "Why Orb saw two" ("The camera frames only your own pair, so the other pair shows up only when it happens to be in frame").
- A-MODES-03 (Rendering leads): couch 2v2 cannot be started; it will run on a two-way split with one fight per person. Evidence: `render/core/main.gd:1337-1362`; `sim/input/hub.gd:26-28`.
- A-MODES-02 (Game Design leads): the horde has up to five bodies in one match (`sim/core/roster.gd:36-40`), and for two players a split.
- Your parked "others-frame" work was paused; check it against today's main before reusing any of it (a pending folder is not proof that something is unlanded).

You own: `render/camera/`, `docs/camera/`.
- ask under NEEDS FROM EP for a grant: `data/camera/` (framing numbers; no director owns it)
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (any data shape you change)

Acceptance criteria:
1. (A-MODES-09) When the other pair is within a reach held in data, the frame eases to hold all four; the player's own pair stays first and readable; when they part, it eases back. No cut, no marker. A camera test with a verdict drives two fights together and apart and checks the own pair never leaves the frame and the move never exceeds the smooth-camera limits.
2. (A-MODES-09, X-08, X-09) In a scripted 2v2 that brings the fights near, a still shows all four fighters in one frame in LAN 2v2 together and in couch 2v2.
3. (A-MODES-03) The two-way split for couch 2v2 uses the existing split and merge with one fight per pane; a merge of two panes that hold different fights is either ruled out or written down and tested. A 1v1 on one PC is unchanged.
4. (A-MODES-02) In a horde of up to five bodies the player's fighter and every enemy within the horde page's stated distance are in frame; an enemy that comes back appears from off screen or at range, not by popping in at the centre. A camera test covers one and two players.
5. Look gate (ADR 0010): each change ships with a side-by-side against the reference build in `docs/ep/taste.md` (`node tools/flash/side-by-side.mjs`; stills and a short clip) before it is committed. With no second fight and no horde, a 1v1 looks the same as the reference.
6. No new place in `render/camera/split_rig.gd` names exactly two fighters (it already holds 41 of them, the largest count in the two-fighter ratchet): the count does not rise.
7. Evidence: camera test results, stills and side-by-sides are saved under `docs/camera/runs/<sha>/`.

Constraints:
- Tokens: supporting work, counted under the lead rows; plan for about an M (1.2M) as an estimate, and say so early if the horde's framing is bigger.
- No change to the sim's state hash: the camera reads sim state and never writes it.
- Machine: no Godot windows; Godot headless only, at most 3 processes for a short gate; clips and stills only through Tools' launcher, one capture at a time, with a time limit.
- Determinism: the camera follows the tick; numbers in data, schema updated in the same commit as a shape change.
- Originality: nothing here adds content.
- Orb's rules: every camera move is eased; nothing drawn on, over or between the fighters (no arrow to an off-screen partner or enemy); no dissolves, fades, slow wipes or full-screen blur; the scroll limit under reduced motion or reduced flashing, landed in A2, also holds for the four-fighter frame.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: the 2v2 framing can begin with Rendering's step A (bodies drawn with the word on). The horde framing waits on Game Design's horde page and Simulation's waves. Waiting on this: the four-fighter stills for X-08 and X-09, Tools' two-fights clips, and Orb's play of LAN 2v2.
