# A2: Production Operations

Leads: none
Supports: A-TOOLS-03, A-MARKET-02, A-LEGAL-03

Goal: When a build goes out to a friend there is one written checklist that was followed, a known earlier build to go back to, and each milestone's shots and builds are kept somewhere that survives a lost disk.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A2, "Change control"), `02-areas/TOOLS.md` (F-TOOLS-03), `02-areas/MARKET.md` (F-MARKET-03), `02-areas/LEGAL.md` (the gate list under Q1), `docs/ep/playbook.md`, `docs/production/risk-register.md`.
- A-TOOLS-03 (led by Tools): no rollback procedure or release checklist exists, so nothing says how testers are returned to the previous build or which earlier build is the one to return to. Evidence: `docs/ep/playbook.md:19-21` (the landing rules cover evidence and build verification, not releases); every "rollback" hit in tools, .github and docs/tools is about something else.
- A-MARKET-02 (led by Tools): no job renders the shots at a milestone and no archive exists; clips land in a git-ignored folder with no milestone name, no line on what changed and no backup. Evidence: `tools/clips/make.mjs:10`; `.gitignore:28-29`; no changelog file is tracked.
- A-LEGAL-03 (led by Legal): the list of gates that must be green before an outside tester plays did not exist before the audit. Evidence: `docs/ep/alpha/alpha-audit-specification.md:169`; `docs/legal/review-log.md:289`.

You own: `docs/production/`.
- ask under NEEDS FROM EP for a grant: none expected. The checklist's steps that run a tool are Tools'; the gate list is Legal's; you write the people-and-order half and hand it to the EP.

Acceptance criteria:
1. (supports A-TOOLS-03) A release page in `docs/production/`: who says "go" (the EP, after Legal's gate page is green and Orb's one-line approval is recorded), the order of steps, what is written down at each release (commit, build id, date, which friends hold keys by a private label and never by name, the build to return to), and when a rollback is called and by whom. Tools' rehearsal follows it once on the dummy build and the page is corrected from what the rehearsal showed. Check: the rehearsal record under `docs/tools/runs/<sha>/` cites the page.
2. (supports A-MARKET-02) An archive rule on the same page: the folder's naming by milestone, the one-line "what changed" per entry, where the second copy lives (Orb's answer; a second disk or an existing private folder is recommended) and who checks at each milestone that the copy was made. Check: the first archive entry (A1 and A2 builds) has its line and the copy is confirmed in the EP's milestone note.
3. (supports A-LEGAL-03) Two rows added to `docs/production/risk-register.md`: a build reaching a tester with a red gate, and the only copy of the archive lost; each with its early sign and its guard as the path states them.
4. Nothing here changes the game or the picture.

Constraints:
- Tokens: not counted in the path's totals (supporting work); about one S (0.25M) as an estimate.
- State hash: no change; this brief touches no game code.
- Machine: no Godot or browser runs.
- Determinism: not touched.
- Originality: nothing to add.
- Orb's rules: plain words; no friend's name, account or address in the repository; in-progress character art never public, and the archive is private; anything that touches a safety gate, a Legal flag, spending or something public stops and goes to Orb through the EP as one plain question.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: the page's first draft lands before Tools' itch.io rehearsal (A-TOOLS-02, A-TOOLS-03) and is corrected after it. Criterion 2's second copy waits on Orb's answer and blocks nothing.
