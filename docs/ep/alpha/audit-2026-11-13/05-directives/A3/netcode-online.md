# A3: Netcode & Online

Leads: A-MODES-04, A-MODES-05, A-MODES-10, A-NET-01, A-NET-02, A-NET-03, A-NET-04, A-PERF-02
Supports: A-CAMERA-05, A-LEGAL-04

Milestone A3 is "The fight's new rules, and LAN inside the game" (docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md). This brief is ready to send once Orb approves the plan; nothing in it is decided until then.

Goal: On two PCs, one player picks Host and the other picks Join from the game's own menu, they play their chosen fighters on a chosen planet, rematch or go back to the menu without closing anything, and if the cable is pulled both screens say so in plain words.

Context:
- Read first: net/lan.gd; net/tools/lan_kit.mjs; net/tools/lan_words.txt; docs/net/lan-v1.md lines 120-125; docs/net/rollback.md line 214; net/desync.gd; net/tools/lan_check.gd; docs/net/runs/6a30b4c9/lan-folder/README.md; docs/legal/review-log.md line 259; docs/ep/vision.md line 1662.
- A-MODES-04 (blocker, L): LAN play is not part of the game: it reaches the game only through text patches the LAN kit makes to a scratch copy, and is started by Windows shortcut files written with the host PC's address. Evidence: net/lan.gd:3-4; net/tools/lan_kit.mjs:1-3, :11-14; export_presets.cfg:55 and :101.
- A-MODES-05 (blocker, M): a LAN match cannot be rematched or left to a menu; the program plays one match and tells both players to close both windows. Evidence: net/lan.gd:386; net/tools/lan_words.txt:38.
- A-MODES-10 (major, M): every LAN match is the same match: the seed, the planet and the fighters are constants. Evidence: net/lan.gd:26, :30-35.
- A-NET-01 (major, S): no LAN match on the played build (6a30b4c9) has a record from two real PCs. Evidence: docs/net/runs/6a30b4c9/lan-folder/README.md:5, :9; lan-loop-rows.txt beside it.
- A-NET-02 (major, L): an outside tester could not set up LAN without help: the host's address is written into shortcuts, there is an administrator firewall step, and the words allow only Orb and Orb 2 (the trusted second player). Evidence: net/tools/lan_kit.mjs:12-19, :127, :170-184; net/tools/lan_words.txt:5.
- A-NET-03 (major, S): a PC that falls silent is declared gone after 8 seconds, not the 5 that exit X-08 proposed, and no pulled-cable test on two real PCs is on record. Evidence: net/lan.gd:45, :459-466; net/tools/lan_check.gd:608-620.
- A-NET-04 (major, S): every LAN status except a dropped PC is shown only in the window's title bar, and a detected state mismatch writes no report of its own. Evidence: net/lan.gd:371-395, :402-408, :471-476; net/desync.gd:375.
- A-PERF-02 (blocker, M): LAN has no Linux build path. Evidence: net/tools/lan_kit.mjs:120; export_presets.cfg:101; net/tools/lan_kit.mjs:28.
- Supporting rows: A-CAMERA-05 (the camera does not know which player is this PC's; led by Camera), A-LEGAL-04 (the ruling on who plays LAN; led by Legal).

You own: net/, docs/net/
- ask under NEEDS FROM EP for a grant: export_presets.cfg (lines 55 and 101 exclude the network code; no director owns the file)
- ask under NEEDS FROM EP for a grant: ui/ (the Host and Join rows, the address entry, the status lines, rematch and back to menu are UI & UX's to build: write what each must show)
- ask under NEEDS FROM EP for a grant: tools/desktop-package.mjs lines 211 and 348 and .github/workflows/ci.yml lines 353-356 (Tools' paths: the package's refusal of network code, and the two-program check)
- ask under NEEDS FROM EP for a grant: render/core/main.gd if the match start must take LAN as a mode (Rendering's path; list the lines)

Acceptance criteria:
1. Closes A-MODES-04. A build made by the one-command desktop build contains LAN with no text patches and no shortcut files: a Host row and a Join row start a LAN 1v1 with a pad alone. Checked by the mode smoke suite for LAN 1v1 on Windows (exit X-05, partial, must pass). Legal's written exception to its rule keeping net/ out of desktop builds is on file first. Saved under docs/net/runs/<sha>/.
2. Closes A-MODES-05. After a result, both PCs can rematch or go back to the menu, and one PC leaving returns the other to the menu with a plain line. Checked by three matches in a row without closing the game, by the smoke suite and by Orb and Orb 2.
3. Closes A-MODES-10. The fighters each player picks and the planet's seed and choices reach the LAN match; no seed, planet or fighter is a constant in net/lan.gd. Checked by a two-peer test on at least three planets with the planet hash equal on both peers.
4. Closes A-NET-02 in the smaller version the path proposes: the host's address is shown on the Host screen and typed on the Join screen, no address is written into any file, and the firewall step is written in plain words for Orb's two PCs. Full version if Orb declines the proposal: one-step set-up a stranger can do (finding the other PC, a firewall step they can judge), with A-LEGAL-04 and A-PERF-02 at full size and a real-Deck LAN test, about 6M more.
5. Closes A-NET-03. A real cable is pulled on two Windows PCs and both show a plain notice inside the agreed time (proposed: within 10 seconds, keeping today's 8-second rule at net/lan.gd:45; Orb confirms). The check also drives the shipped limit, not only its 1-second test limit. The times from both PCs are saved.
6. Closes A-NET-04. Waiting, could not connect, could not start, out of step and match over each appear on screen at the screen's edge in plain words, none only in the window's title; a detected state mismatch writes its own report file that the report folder picks up. Checked by a still of each status and by net/tools/desync_check.gd.
7. Closes A-NET-01. Exit X-08 for LAN 1v1 (must pass): Orb and Orb 2 play five full matches on two Windows PCs on this build with no state mismatch; the logs and report folders from both PCs are saved under docs/net/runs/<sha>/ with the deepest rollback seen (the 2026-11-07 logs showed 20 and Orb reported stutter).
8. Closes A-PERF-02 in the smaller version: the Linux desktop build includes the network code and the two-program check passes on Linux in CI. Full version if Orb declines the proposal: a real two-Deck or Deck-and-PC session, with Performance & Platform.
9. Supports A-CAMERA-05: the game can tell the camera which fighter is this PC's player. Supports A-LEGAL-04: you give Legal the list of what a LAN build opens and writes on a PC.
10. The new screens and status lines change what a player sees: UI & UX's work on them passes the look gate (ADR 0010, docs/decisions/0010-look-gate.md): a side-by-side against the reference build named in docs/ep/taste.md (node tools/flash/side-by-side.mjs), seen by the EP before it is committed.

Constraints:
- Tokens: about 12.3M as an estimate (2 L, 3 M, 3 S at the register's size classes); about 8.6M if Orb accepts the smaller A-NET-02 and A-PERF-02. This is the heaviest single load in A3: the path has you start it in A2 behind a switch.
- State fingerprint: none of these rows changes it. LAN must stay in step across golden window GW2, "The fight's rules" (a golden window is one landing that changes the sim's state fingerprint, after which the saved reference matches are re-recorded once): re-run the two-peer checks on the commit after the window closes, and take the five-match record on that commit.
- The two-program network check runs in CI, not on Orb's PC, where it raises a firewall prompt Orb cannot judge. Never put a prompt in front of Orb.
- Orb's rules: LAN at Alpha is for Orb and Orb 2 only unless Orb decides otherwise (decision 13); nothing drawn on, over or between the fighters; plain words in every line a player reads, and Orb sees those lines before they are used; no player's address, account name or file path in any saved record.
- Machine rules: Godot runs headless only; at most 3 Godot processes for a short gate (never more than 6 in one session); a run longer than about ten minutes starts at below-normal priority, and a reading taken while the machine was saturated is marked invalid, not reported; pictures and clips come only through Tools' launcher (tools/machine/capture.mjs), one capture at a time; stop only your own processes, by PID; check nothing you started is still running before you end a turn.
- Determinism: seeded RNG, fixed step, no rendering state in the sim, shortest-arc wrap maths for every distance. Numbers live in data, not code; a change to a data file's shape updates its schema in tools/schemas/ in the same commit (ask under NEEDS FROM EP for a grant: tools/schemas/).
- Originality: every name, move, look and line is our own; nothing from an existing franchise.
- A director never briefs or messages another director: anything you need from one goes under NEEDS FROM EP and the EP routes it.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT). Keep it short. Report, then freeze the files you reported until the EP confirms the commit.

Order: Before this starts: the mode list (A-MODES-01) and the fighter pick (A-MODES-06) from A1; the one-command desktop build (A-TOOLS-01); Orb's decision 13; Legal's exception for net/ in the trusted-two build. Inside the brief: A-MODES-04 first, then A-MODES-05, A-MODES-10, A-NET-02 and A-NET-04; A-NET-03 and A-NET-01 are measured last, on the commit after GW2. Waiting on this: A-LEGAL-04's check, A-CAMERA-05's stills, and LAN 2v2 in A4.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- Decision 13 (who plays the two-PC modes) is asked on day one of A1 and Legal's net/ exception is ruled in A2, so this work can start behind a switch in A2 as the path intends. (ORD-08)
