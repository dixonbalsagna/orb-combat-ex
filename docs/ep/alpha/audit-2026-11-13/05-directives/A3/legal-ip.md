# A3: Legal & IP Compliance

Leads: A-LEGAL-04
Supports: A-MODES-04, A-NET-02

Milestone A3 is "The fight's new rules, and LAN inside the game" (docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md). This brief is ready to send once Orb approves the plan; nothing in it is decided until then.

Goal: It is written down who may play over LAN at Alpha, and a friend who is handed the tester package cannot end up with network play, a firewall step or terms that were never meant for them.

Context:
- Read first: docs/legal/review-log.md line 259 (and the row for RL-204, the rule that keeps net/ out of public desktop builds, named at net/lan.gd line 4); tools/desktop-package.mjs lines 211 and 348; export_presets.cfg lines 55 and 101; net/tools/lan_kit.mjs line 195; net/tools/lan_words.txt lines 5, 18 and 42.
- A-LEGAL-04 (major, M): no ruling or package covers an outside tester playing the LAN modes: the locked package refuses any network code, and the LAN folder's terms name only the owner and the trusted second player. Evidence: tools/desktop-package.mjs:211, :348; export_presets.cfg:55, :101; docs/legal/review-log.md:259.
- The row's risk: a tester is handed the owner's LAN folder with terms that do not fit them and a firewall step they cannot judge. The early sign is any plan that sends the LAN folder to a friend.
- Orb's decision 13 (recommended: LAN inside the game behind a Host and Join row, played only by Orb and the trusted second player, Windows only; the outside testers' package has no LAN row).
- Supporting rows: A-MODES-04 (LAN moves inside the game, which needs a written exception to RL-204 for the trusted-two build; led by Netcode & Online), A-NET-02 (the words a LAN player reads; led by Netcode & Online).

You own: docs/legal/
- ask under NEEDS FROM EP for a grant: tools/desktop-package.mjs (Tools' path): you do not edit it; you state what the check must prove and the EP routes it to Tools

Acceptance criteria:
1. Closes A-LEGAL-04 in the smaller version the path proposes: a row in docs/legal/review-log.md rules that at Alpha LAN is played only by Orb and the trusted second player, that the outside testers' package has no LAN row and no network code a tester can reach, and what must be true before LAN is offered wider. Full version if Orb declines the proposal: a full ruling for outside testers on LAN (terms that fit them, the firewall step, what a LAN build opens on their PC), with A-NET-02 and A-PERF-02 at full size.
2. Closes A-LEGAL-04. The check that proves it exists and passes on the A3 commit: Tools' package step refuses an outside-tester package that contains a LAN row, and its result is saved under docs/legal/runs/<sha>/ beside your ruling. A person's check: you open the built tester package's file list and the menu still and confirm no Host or Join row.
3. Supports A-MODES-04: a written exception to RL-204 for the build the trusted two play, saying exactly which package may include net/ and which may not, on file before Netcode's work lands on main.
4. Supports A-NET-02: the lines a LAN player reads (who may play, the firewall step, the unsigned-program warning) are reviewed in plain words for Orb's two PCs, with no address, account name or file path of the owner in any of them.
5. Scope: names, likeness of whole characters, trademarks, copied assets and real player safety. Pose, gesture and look rules are not Legal's and never block a gate.

Constraints:
- Tokens: about 1.2M as an estimate (1 M at the register's size class); about 0.25M if Orb accepts the smaller version.
- State fingerprint: not changed; no golden window applies. No Godot or browser run is needed for this brief.
- Orb's rules: any Legal flag goes to Orb through the EP as one clear question; the trusted second player has Orb's standing on safety, outside testers do not; the AI disclosure is up front wherever the game is shown; forward-facing text is seen by Orb before use; plain words. The safety record frozen for the audit is pointed at, not edited.
- Machine rules: Godot runs headless only; at most 3 Godot processes for a short gate (never more than 6 in one session); a run longer than about ten minutes starts at below-normal priority, and a reading taken while the machine was saturated is marked invalid, not reported; pictures and clips come only through Tools' launcher (tools/machine/capture.mjs), one capture at a time; stop only your own processes, by PID; check nothing you started is still running before you end a turn.
- Originality: every name, move, look and line is our own; nothing from an existing franchise.
- A director never briefs or messages another director: anything you need from one goes under NEEDS FROM EP and the EP routes it.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT). Keep it short. Report, then freeze the files you reported until the EP confirms the commit.

Order: Before this starts: Orb's decision 13. The exception for the trusted-two build is written first, because Netcode's A-MODES-04 waits on it; the ruling's check waits on A-MODES-04 and on Tools' package step. Waiting on this: the A3 build going to the two friends as an update (it must be the package with no LAN row), and exit X-02 on later commits.
