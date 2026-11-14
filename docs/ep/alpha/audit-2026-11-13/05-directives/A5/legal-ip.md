# A5: Legal & IP Compliance

Leads: A-TEXT-04
Supports: A-QA-01, A-SAVES-08, A-MARKET-08

Goal: Every paper and screen a tester meets says the same true things about who made the game, what is kept on their PC and where reports go, and the name on screen is marked as a working title until the title search is done.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A5, exit lines X-21 and X-32; decisions 9 and 10); `docs/ep/alpha/alpha-audit-specification.md` lines 188 and 199 (X-21, X-32); `docs/legal/name-screening.md` lines 184 to 188; `docs/legal/alpha-tester-note.md`; `docs/legal/alpha-discord-flags.md`; `docs/legal/review-log.md` (the newest rows); `ui/data/terms.json` line 92 and `ui/data/feedback.json` line 17, to read only; the gate list you wrote under A-LEGAL-03.
- A-TEXT-04 (nice to have): the title is shown and stamped as plain "Orb Combat EX" with no working-title mark, while your own page says the visible heading may keep "(working title)" until the search is done. Evidence: `project.godot:8`; `ui/data/terms.json:92` (the menu's heading); `export_presets.cfg:82` (the product name); `docs/legal/name-screening.md:186-187` (the formal search is owed before any itch.io page or promotion; the heading may keep "(working title)" until then).
- A-QA-01 (QA leads): no tester guide or checklist exists. Evidence: `docs/legal/alpha-tester-note.md:1-3` (your note is the only tester-facing page; it names a download key at line 12 but not how to use one).
- A-SAVES-08 (Tools leads): where the game keeps its files is written nowhere a tester would read. Evidence: `ui/core/ui_prefs.gd:7`; `sim/input/remap.gd:13`.
- A-MARKET-08 (Community & Marketing leads): the marketing plan predates Orb's Alpha definition. Evidence: `docs/marketing/go-to-market-plan.md:20-22`.

You own: `docs/legal/`.
- The words on screen are UI's data and the package text is Tools': you rule and word; the EP routes the change. You do not edit `ui/`, `tools/`, `project.godot` or `export_presets.cfg`.

Acceptance criteria:
1. (A-TEXT-04) A ruling in `docs/legal/`, with a new row in `review-log.md`, says exactly where "(working title)" must show for Alpha (recommendation on the register: the start menu and the tester note; not the program's stamped name), the exact words, and what lifts it (the formal search in `name-screening.md`). Checked by: the row; UI's still of the start menu; the tester note's first line. If Orb answers no, the row records that and the reason, and the gap closes as decided.
2. (supports A-QA-01; exit X-32) Each paper a tester meets has its own sign-off row: the tester note, the tester guide, the tester checklist, the package README, the in-game notice and About page, the credits and third-party notices inside the build. Each row names the file, the commit read, and "clear" or the condition left. Checked by: the rows; none open on the A5 commit.
3. (exit X-32) The privacy words are the same in the package, the game and the note: nothing leaves the PC unless the tester sends it; reports posted go to Orb's private Discord server, which is run by another company; reports are deleted on request. Checked by: a three-column table in `docs/legal/` quoting each, on the A5 commit (re-reading A-LEGAL-12).
4. (exit X-21) The report a tester makes in one press is read once more on the A5 build: nothing is sent automatically, the file is under 10 MB with clips separate, and the check for account names and file paths (A-LEGAL-06) ran on it. Checked by: a sign-off row pointing at Tools' saved report from a Deck.
5. (supports A-SAVES-08) The words that say where settings are kept, and that removing the game leaves them, are read and cleared or corrected; no path printed in a tester-facing text contains a person's account name. Checked by: a row.
6. (supports A-MARKET-08) The revised marketing plan is read: nothing in it stages anything public before the title search, the licence line and the AI disclosure are settled. Checked by: a row.
7. (all) What you read is saved as evidence: for each row, the file and commit, under `docs/legal/runs/<sha>/` (CD-22). A figure in a safety record points at its saved output or is labelled "unverified".

Constraints:
- Tokens: about 0.25M (one S row), an estimate; the sign-off rows are supporting work.
- State hash: no change.
- Machine: no Godot or browser runs are needed for this brief.
- Determinism: not touched.
- Originality: any new name or phrase in the papers is screened like any other; no existing franchise is named in a tester-facing text.
- Orb's rules: your scope is names, whole-character likeness, trademarks, copied assets and real player safety; pose, gesture and look rules are creative direction and never block a gate. The AI disclosure is up front everywhere the game is shown. Forward-facing text is seen by Orb before use. Any Legal flag goes to Orb through the EP as one plain question. Outside testers do not share the trusted second player's standing: every safety gate applies to them in full.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Needs A-LEGAL-03, A-LEGAL-05, A-LEGAL-06, A-LEGAL-12, A-LEGAL-13 and A-TOOLS-06 (A2), A-LEGAL-09 and A-LEGAL-10 (A1), and Orb's answer on the working-title mark. Items 2 to 5 wait on QA's guide, Tools' package and UI's approved text. The A5 upload to the itch.io page, the rehearsal and A6's X-02 and X-32 re-read wait on your rows.
