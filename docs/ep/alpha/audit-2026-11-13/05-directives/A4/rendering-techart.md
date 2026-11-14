# A4: Rendering & Technical Art

Leads: A-MODES-03, A-MODES-09
Supports: A-ANIM-01, A-ANIM-02, A-WORLD-02, A-MODES-02, A-CODE-05

Goal: Two people on one PC can pick couch 2v2 from the menu and play it to a result on a two-way split, and in any 2v2 a player sees all four fighters together when the two fights are near each other.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A4; decision 16); `docs/ep/alpha/audit-2026-11-13/02-areas/MODES.md` (F-MODES-03 and its verify note, F-MODES-10) and `02-areas/RENDER.md` (F-RENDER-12); `docs/rendering/2v2-drawn-plan.md` (who does what, the order, Legal's conditions); `docs/rendering/pending/others-near/README.md` (your parked step A, cut against an older main); `docs/ep/proposals/co-op-2v2.md` (line 37: cleared to build and try privately under Legal's row RL-249); `docs/design/two-v-two.md`; `render/core/main.gd`; `render/core/sim_host.gd`; `docs/decisions/0010-look-gate.md`; `docs/ep/taste.md`.
- A-MODES-03 (L, blocker): couch 2v2 cannot be started: the game's host only ever starts a two-body match, the input hub has two player slots, and the only game code that asks the sim for two fights is the LAN program. Evidence: `render/core/main.gd:1337-1362` (the menu's Start passes only p1 and p2); `render/core/sim_host.gd:84-87`; `sim/input/hub.gd:26-28`. From the audit's verification: `SimHost.new_match` takes any setup and check tools already ask for two fights, so the limit is the menu path, not the host.
- A-MODES-09 (L, major): LAN 2v2 exists only as two humans, one on each PC, against two computer fighters, and each screen shows only its own fight; Orb reported never seeing all four fighters together. Evidence: `net/lan.gd:34-35`; `net/tools/lan_words.txt:26`; `render/core/main.gd:242` (`SimHost.draw_others` is on only with `--others`).
- Supporting rows: A-ANIM-01 and A-ANIM-02 (drawing each form's look and the second body colour through `render/core/fighter_view.gd` and the lane-colour remap at `render/core/look.gd:930-939`); A-WORLD-02 (`planet_part` at `render/core/main.gd:441-449` carries the dials into the setup); A-MODES-02 (drawing up to five bodies in a horde); A-CODE-05 (add no new table keyed by fighter id, such as the one at `render/core/look.gd:489`).

You own: `render/core/`, `render/shaders/`, `docs/rendering/`.
- ask under NEEDS FROM EP for a grant: `render/main.tscn` (only if the scene must change; no director owns it)
- The menu's mode rows are UI's, the slot map is Controls', the framing is Camera's, the per-screen flash register is VFX's, the LAN launchers are Netcode's and the clips are Tools': list what you need from each under NEEDS FROM EP.

Acceptance criteria:
1. (A-MODES-03) From the menu, with pads alone, couch 2v2 starts a two-fight match with two human slots on one team and two computer fighters on the other, on a two-way split; it plays to a result, rematches and leaves. Written for the smaller version the path proposes (two people against two computers). Full version if Orb declines the proposal: three- and four-pad line-ups on a four-way picture, which does not exist.
2. (A-MODES-03, X-05, X-09) The mode smoke suite runs couch 2v2, and 2v2 with a computer partner once A-AI-08 lands, on Windows and Linux; each supported line-up on the line-ups page is played from the menu once by a person. Records saved.
3. (A-MODES-03) A frame record of couch 2v2 on Orb's PC with both fights on screen, taken by Performance through the EP, is saved; any full-screen pass or frame copy you add gets Performance's timing before it is committed (ADR 0010, item 5).
4. (A-MODES-09) Step A of the plan is rebuilt on today's main (the parked diff is not applied by script at the repository root): with the word on, the other fight's bodies and shadows are drawn whenever they are within a pane's view, with none of its light; with it off, and in every 1v1, the picture is identical to before. Checked by the render gates and a still pair.
5. (A-MODES-09) Step B: once VFX's one-register-per-screen exists, the other fight's beams and the light from its changes to the shared world are drawn through that register, behind the effects switch, and only after Legal's clips pass. Until then the default is bodies only.
6. (A-MODES-09, X-08, X-09) In couch 2v2 and in LAN 2v2 together, a scripted match that brings the two fights within view shows all four fighters in one frame; a still of that frame is saved for each mode.
7. Look gate (ADR 0010): every step ships with a side-by-side against the reference build in `docs/ep/taste.md` (`node tools/flash/side-by-side.mjs`; stills and a short clip) before it is committed, and the collapse clip is run through the flash check in both modes before any look report. A 1v1 must look the same as the reference.
8. (support) Each form's look and each second colour reaches the screen from data through the existing palette and lane remap; the planet dials reach the match setup; five bodies draw in a horde without a new per-fighter table.
9. Evidence: gate results (the fifteen render checks, determinism), stills, side-by-sides and frame records are saved under `docs/rendering/runs/<sha>/`.

Constraints:
- Tokens: about 8M as an estimate (L 4M + L 4M); the comparable is about 4.5M for drawing the partner's fight (`docs/ep/proposals/co-op-2v2.md:37`).
- Neither row changes the sim's state hash: rendering reads sim state and never writes it. The two-fight setup keys already exist in the sim. If a change here would move the hash, stop and tell the EP; it would have to join golden window GW3.
- Machine: no Godot windows; Godot headless only, at most 3 processes for a short gate; pictures from the web build only through Tools' launcher, one software-rendered capture at a time, each with a time limit; a relative `--out` lands in the repository, so give captures an absolute scratch path; check nothing you started is still running before ending a turn.
- Determinism: nothing drawn may depend on which PC or which pane draws it in a way that feeds back into the sim; numbers in data, schema updated in the same commit as a shape change.
- Originality: nothing here adds content.
- Orb's rules: nothing drawn on, over or between the fighters (no marker for "your partner" or "the other fight"); no dissolves, fades, slow wipes or full-screen blur when panes split or merge; nothing that costs frame rate for presentation; drawing the other fight stays private to Orb and the trusted second player until Legal's clips pass; plain words.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: the mode list in the menu (A-MODES-01, A1); Controls' slot map (A-CONTROLS-01); Orb's answer to decision 16. Step A of A-MODES-09 can start at once, with Camera's framing beside it; step B waits on VFX's register, then UI's switch and Netcode's launchers, then Tools' clips and Legal's reading. Waiting on this: A-AI-08 (the computer partner needs a 2v2 that starts on one PC), A-QA-06's couch line-up, and A-NET-06's five-match sessions if they are to show all four fighters.
