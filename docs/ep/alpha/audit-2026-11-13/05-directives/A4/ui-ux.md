# A4: UI & UX

Leads: none
Supports: A-MODES-02, A-MODES-03, A-AI-08, A-WORLD-02, A-ANIM-02, A-MODES-09

Goal: With a pad alone, a player can pick Horde, couch 2v2, 2v2 with a computer partner or a custom planet from the menu, play to a result screen, and rematch or leave.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A4; decision 16); `docs/ep/alpha/audit-2026-11-13/02-areas/MODES.md` (the mode table at lines 20-27; F-MODES-02, F-MODES-03, F-MODES-07); Game Design's horde and line-ups pages and World's dial list (the EP gives the paths); `docs/ui/fighter-select.md`; `docs/design/minimal-hud.md`; `ui/data/features.json`; `docs/rendering/2v2-drawn-plan.md` (UI's row); `docs/decisions/0010-look-gate.md`; `docs/ep/taste.md`.
- A-MODES-02 (Game Design leads): the horde mode does not exist; it needs a menu entry, a timer or wave count, and a result screen. Evidence: `docs/combat/henchmen-grades.md:3`; `sim/core/roster.gd:36-40`.
- A-MODES-03 (Rendering leads): couch 2v2 cannot be started; the menu's Start passes only p1 and p2. Evidence: `render/core/main.gd:1337-1362`.
- A-AI-08 (Encounter leads): no menu can start a match with a computer on a human's side. Evidence: `net/lan.gd:34-35`.
- A-WORLD-02 (World leads): the menu has no planet choice. Evidence: `render/core/main.gd:441-449` ("the menu has no such choice yet").
- A-ANIM-02 (Art leads): the mirror match is off until Art has a second colour. Evidence: `docs/ui/fighter-select.md:26`.
- A-MODES-09 (Rendering leads): the plan gives UI the desktop switch for the other fight's effects.

You own: `ui/`, `docs/ui/`.
- ask under NEEDS FROM EP for a grant: `render/core/main.gd` (only the lines where the menu's choices become the match setup; Rendering owns it, and may prefer to make the change)
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (if a menu data file's shape changes)

Acceptance criteria:
1. (A-MODES-02, X-05, X-10) The mode list has a Horde row for one or two players. In a run the HUD shows the timer or wave count the horde page asks for, placed with the HUD and never over a fighter. A result screen shows what the page lists, with Rematch and Leave. All reachable with a pad alone.
2. (A-MODES-03, A-AI-08, X-09) The mode list has couch 2v2 (two people against two computer fighters) and 2v2 with a computer partner; the fighter pick works for two people, and the device rows show which pad is which player. Only the line-ups on Game Design's page can be chosen.
3. (A-WORLD-02, X-11) A planet row: a seed the player can read, type or re-roll, and three dials (city count, climate, water) with World's named steps; the choices are shown again on the result screen and saved in the report, so a second PC can be given the same ones.
4. (A-ANIM-02) The fighter pick allows the same fighter twice once Art's second colour is in, and shows each copy in its team's colour.
5. (A-MODES-09) The switch for the other fight's effects is off by default and shown only where the plan allows it, with Reduce flashing locked on while it is on.
6. (X-05) Every new row's wording and its pad path match what the mode smoke suite presses; a change to a row is reported to the EP for Tools the same day, so the suite does not click the wrong place.
7. (X-22, first applied here to the new screens) Stills of every new or changed screen at 1280 by 800 show no clipped or overlapping text and no text under 9 px (12 px is the aim).
8. Look gate (ADR 0010): each new or changed screen ships with a side-by-side against the reference build in `docs/ep/taste.md` before it is committed. No fades or dissolves between screens.
9. Evidence: HUD and menu check results and the stills are saved under `docs/ui/runs/<sha>/`.

Constraints:
- Tokens: supporting work, counted under the lead rows; plan for about an M (1.2M) as an estimate across the four screens.
- No change to the sim's state hash: the UI reads the sim and never writes it (a sim "getter" that resizes a hashed field counts as a write). The menu's choices reach the sim only as setup keys Simulation defines.
- Machine: no Chrome of your own; stills only through Tools' launcher (`tools/machine/capture.mjs`), one at a time; Godot headless only, at most 3 processes for a short gate.
- Determinism: nothing in the UI feeds the sim outside the setup and the recorded input.
- Originality: mode names and screen words are our own.
- Orb's rules: no health bar; nothing drawn on, over or between the fighters; no dissolves or fades; plain words on every row (say what the player presses and sees); every word a player reads is listed for Orb to see before use; no in-progress character art on any public page.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: the mode list and the Rail (the left-panel menu) as the default, from A1; Game Design's horde and line-ups pages; World's dial names; Controls' slot map. Rows can be built ahead behind a switch and turned on as each mode lands. Waiting on this: the mode smoke suite's runs for the four new entries (X-05), and Orb's play of the A4 build.
