# A3: UI & UX

Leads: A-ENERGY-07, A-ENERGY-08
Supports: A-COMBAT-07, A-MODES-04, A-MODES-05, A-MODES-10, A-NET-04, A-CONTROLS-05

Milestone A3 is "The fight's new rules, and LAN inside the game" (docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md). This brief is ready to send once Orb approves the plan; nothing in it is decided until then.

Goal: A player can tell at speed, from the fighter and the screen's edge alone, how hurt they are, how much energy they have and when a transformation is ready; and a second PC joins from a Host or Join row in the menu.

Context:
- Read first: docs/design/minimal-hud.md lines 22 and 30; ui/widgets/ui_plate.gd lines 105, 377 and 473; ui/hud/ui_hud.gd line 771; ui/core/ui_sim_bridge.gd lines 86-87; data/fight/ladder.json line 10; docs/ep/taste.md; Game Design's model page for the stamina, energy and body loop (the EP sends its path).
- A-ENERGY-07 (major, S): no record shows that a player can read their own health, energy or readiness from the fighter at speed; the only energy readout found is the corner plate. Evidence: ui/widgets/ui_plate.gd:105, :473; ui/hud/ui_hud.gd:771. The row's early check: a blind read test on saved clips.
- A-ENERGY-08 (minor, S): the HUD's power pip is computed at 25 per tier while the data's thresholds are 35, 65 and 100, so it reads full before a transformation is ready. Evidence: ui/core/ui_sim_bridge.gd:86-87; data/fight/ladder.json:10; ui/widgets/ui_plate.gd:377.
- Supporting rows: A-COMBAT-07 (the transform chord has no hint: ui/data/features.json:3 and :40, ui/widgets/ui_howto.gd:198, ui/data/howto.json:36; led by Controls & Game Feel); A-MODES-04, A-MODES-05, A-MODES-10 and A-NET-04 (LAN inside the game: Host and Join rows, rematch and back to menu, the players' picks, every status on screen; led by Netcode & Online); A-CONTROLS-05 (97 unanswered presses gave no word or buzz; led by Encounter Systems).

You own: ui/, docs/ui/
- ask under NEEDS FROM EP for a grant: net/lan.gd (Netcode's path): do not edit it; ask the EP for the list of statuses and calls the menu may use
- ask under NEEDS FROM EP for a grant: render/core/main.gd (Rendering's path) if a LAN row must start a match there; list the lines

Acceptance criteria:
1. Closes A-ENERGY-07. A still set from this build shows health, energy and readiness can be read from the fighter at speed with no health bar (part of exit X-15, must pass). The check is a blind read: a person who has not seen the match is shown each saved clip once and says "hurt or fine, energy or empty, ready or not"; the clips, the answers and the score are saved under docs/ui/runs/<sha>/. Where a read fails, the report says which signal is missing and who would have to add it; you do not add a marker to fix it.
2. Closes A-ENERGY-08. The power pip reads the thresholds from data/fight/ladder.json and shows full only when a transformation is ready. Checked by the HUD check with a fighter at 34, 35, 64, 65, 99 and 100, and a HUD still at each.
3. Supports A-COMBAT-07: the how-to and the legend say how to transform and name the signature inputs, from Controls & Game Feel's wording, with forms on.
4. Supports A-MODES-04, A-MODES-05 and A-MODES-10: the mode list has Host and Join rows worked with a pad alone; Host shows the address, Join takes it typed with the pad; each player's fighter and the planet picked reach the LAN match; the result screen offers rematch and back to menu. Checked by the mode smoke suite for LAN 1v1 on Windows (exit X-05, partial).
5. Supports A-NET-04: waiting, could not connect, could not start, out of step, match over and "the other PC has gone" each show as a plain line at the screen's edge, never only in the window's title. One still of each is saved.
6. Supports A-CONTROLS-05: a press the game refuses gets a word at the screen's edge or a buzz, per Encounter Systems' list of silent refusals; if the stamina number is to be shown, it sits on the corner plate as Game Design's page says.
7. Every item here changes what a player sees: each passes the look gate (ADR 0010, docs/decisions/0010-look-gate.md): a side-by-side against the reference build named in docs/ep/taste.md (node tools/flash/side-by-side.mjs), seen by the EP before it is committed. The 1280 by 800 screen sweep (built in A1) is re-run for the new rows.

Constraints:
- Tokens: about 0.5M as an estimate (2 S at the register's size classes); the LAN screens are counted under Netcode's rows and are the larger piece of your time in A3.
- State fingerprint: not changed. The UI must not write the sim: a sim "getter" that resizes a hashed field counts as a write. The proof is an identical fingerprint with the HUD on and off.
- Orb's rules: a minimalist UI; nothing drawn on, over or between the fighters, ever (no rings, bars, tracks, diamonds, badges, markers, icons or labels); the HUD lives at the screen's edges, small and sparse; no health bar; no slow slide-style wipes or fades for panels; plain words; every line a player reads is seen by Orb before it is used; no debug or key-help text in the build.
- Stills only through Tools' launcher; no Chrome of your own.
- Machine rules: Godot runs headless only; at most 3 Godot processes for a short gate (never more than 6 in one session); a run longer than about ten minutes starts at below-normal priority, and a reading taken while the machine was saturated is marked invalid, not reported; pictures and clips come only through Tools' launcher (tools/machine/capture.mjs), one capture at a time; stop only your own processes, by PID; check nothing you started is still running before you end a turn.
- Originality: every name, move, look and line is our own; nothing from an existing franchise.
- A director never briefs or messages another director: anything you need from one goes under NEEDS FROM EP and the EP routes it.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT). Keep it short. Report, then freeze the files you reported until the EP confirms the commit.

Order: Before this starts: the mode list, fighter pick and Rail menus (the left-panel menus Orb picked) from A1; golden window GW1 closed. The blind read (A-ENERGY-07) is taken after the stamina, energy and body loop is on, so it reads the finished signals. The LAN rows wait on Netcode's list of calls. Waiting on this: exit X-08's play session, exit X-15, and the A3 PLAY THIS page.
