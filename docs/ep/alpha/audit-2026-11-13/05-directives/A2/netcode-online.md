# A2: Netcode & Online

Leads: none
Supports: A-TOOLS-05, A-TOOLS-04, A-LEGAL-06, A-MARKET-03

Goal: A report or a crash file made on any PC holds the last moments of the match and the two-PC log without a personal path or account name in it, and needs no outside program to make.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A2), `02-areas/TOOLS.md` (F-TOOLS-04, F-TOOLS-05), `02-areas/LEGAL.md` (Q5), `docs/tools/lan-report.md`.
- A-TOOLS-05 (led by Tools): the one-press report folder works only on Orb's PC and has never been made from a real LAN save. Evidence: `tools/preview/lan-report.mjs:4`, `:83`; `net/tools/lan_kit.mjs:28` (the LAN program is a Windows .exe). The audit's open question AQ-01 (`questions.md:16`): the first real LAN save through the report tool is owed.
- A-TOOLS-04 (led by Tools): nothing captures a crash or a hang; match files are saved only on pause, match end and a pressed report. Evidence: `net/lan.gd:287`, `:389`, `:485`. Verified detail: a match file is also saved at `net/lan.gd:179`, and the LAN build appends a line every ten seconds to its log (`net/lan.gd:411-425`), which shows when a game stopped, not why.
- A-LEGAL-06 (led by Tools): no check that the saved files and logs offered for sending hold no account names or paths. Evidence: `docs/legal/alpha-discord-flags.md:6`; `net/lan.gd:520`. The audit's read found a saved match holds no account name, path or address (`net/lan.gd:507-518`).
- A-MARKET-03 (led by Tools): the LAN clip route has not yet read a real LAN save. Evidence: `tools/preview/lan-clip.mjs:1-6`.

You own: `net/`, `docs/net/`.
- ask under NEEDS FROM EP for a grant: none expected; Tools' work reaches `net/lan.gd` either by a grant to Tools or by your hands, as the EP rules.

Acceptance criteria:
1. (supports A-TOOLS-04) The saving code in `net/lan.gd` offers one call Tools' crash and hang capture can use to write the last moments of a match at any time, in solo as well as LAN builds, without changing what the sim computes. Check: your existing net checks pass; a replay made from such a file verifies. Outputs under `docs/net/runs/<sha>/`.
2. (supports A-TOOLS-05) The report save in a LAN build writes what the report needs (the saved match, the log) with no outside program and no path to this repository, and a real save from Orb's two-PC copy is passed through Tools' report tool once. Record: `docs/net/runs/<sha>/`.
3. (supports A-LEGAL-06) A written list, with file lines, of every field a saved match and a LAN log can hold, marking any that could carry an address, a machine name or a path, for Tools' scan and Legal's row.
4. (supports A-MARKET-03) Confirm in one line what the LAN clip route needs from a save, so Tools' self-test can use a real one.
5. Nothing in this brief changes the picture or the fight.

Constraints:
- Tokens: not counted in the path's totals (supporting work); about one S (0.25M) as an estimate. Your lead work this milestone is working ahead for A3 (LAN inside the game), behind a switch, under its own brief.
- State hash: no change, and A2 has no golden window: saving reads state and never writes it.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; the two-program socket check runs only in CI, never on Orb's PC (it raises a firewall prompt).
- Determinism: seeded RNG and fixed step untouched; a save is a pure read of sim state; numbers (how many ticks the last-moments file holds) live in data, with the schema updated in the same commit.
- Originality: nothing to add.
- Orb's rules: nothing is ever sent automatically; no address is baked into a file; plain words in anything a player reads; no personal path or account name in any packaged or saved file.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: criterion 1 and 3 land before Tools' crash capture and scan (A-TOOLS-04, A-LEGAL-06), which the soak and the friends' session wait on. Nothing here waits on Orb.
