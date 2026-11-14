# A5: Community & Marketing

Leads: A-MARKET-08
Supports: A-QA-01, A-MARKET-05, A-MARKET-06

Goal: Anyone on the team who opens the marketing plan finds the Alpha Orb actually asked for (a private, key-only test for friends, with reports to a private Discord server) and a dated path from there to a Steam demo, and the tester guide reads like a friend wrote it.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A5; decisions 8, 9 and 10; "Can wait until after Alpha"); `docs/ep/alpha/alpha-audit-specification.md` lines 133 to 163 (Orb's Alpha definition: who plays, distribution, the freeze); `docs/marketing/go-to-market-plan.md`; `docs/marketing/steam-readiness.md`; `docs/marketing/store-copy-draft.md` lines 103 to 106; `docs/ep/vision.md` line 1741; `ui/data/fighter_names.json` lines 3 to 7; `docs/legal/alpha-tester-note.md`.
- A-MARKET-08: the marketing plan predates Orb's Alpha definition. Evidence: `docs/marketing/go-to-market-plan.md:20-22` (it stages a public browser build and a public itch.io page); `docs/marketing/go-to-market-plan.md:129` (it advises no Discord until 50 followers, where Orb has since named Discord for reports, `docs/ep/vision.md:1741`); `docs/marketing/go-to-market-plan.md:146-158` and `:229` (it still holds things back for placeholder names, where `ui/data/fighter_names.json:5-6` now carries Orb's names); `docs/marketing/steam-readiness.md:50-61` (an order of steps with no dates counting back from the demo).
- A-QA-01 (QA leads): no tester guide exists. A-MARKET-05 and A-MARKET-06 (Tools leads): footage is small, and the clips shared so far were staged on a private copy and are not the game as played.

You own: `docs/marketing/`.
- You publish nothing. No page, post, clip or picture leaves the repository in this milestone.

Acceptance criteria:
1. (A-MARKET-08) `docs/marketing/go-to-market-plan.md` is revised so its first stage is the Alpha as defined: a restricted itch.io page with private download keys, Windows and Steam Deck/Linux, named friends, reports to a private Discord server, nothing public, the browser build for private looks only. Every line that staged a public page or build before Beta is moved to a later stage or removed, and the placeholder-name hold is replaced by the names now in the game. Checked by: the EP reads the page against the Alpha definition; Legal's row (it reads the revision).
2. (A-MARKET-08) A timeline counts back from the Steam demo at Beta: each step in `steam-readiness.md` section 5 gets a "no later than" measured in weeks before the demo, the ones that are Orb's actions are marked, and the page says which steps cost money. No calendar date is promised. Checked by: the table.
3. (A-MARKET-08) The plan states what "Beta in sight" means, the point the Steam clock starts, as a recommendation for Orb (the register's: four fighters playable on the Windows and Linux builds, and the Alpha testers' reports folded in). The path lists this among the answers that can wait until after Alpha: it is written down, not chased. Checked by: the line, marked "Orb to confirm".
4. (supports A-QA-01) You return QA's tester guide to the EP with a tone pass: short, friendly, plain, no team nicknames, no promise the build does not keep, the AI disclosure up front. You change no step. Checked by: your marked copy; Orb sees the final text before it is used.
5. (supports A-MARKET-05, A-MARKET-06) You return Tools' shot list with, for each shot, what it would be used for later (a screenshot, a trailer moment, the archive only), and you confirm the rule that only "played" shots are candidates for anything public. Checked by: your note in `docs/marketing/`.
6. (all) Nothing in your pages names an existing franchise, uses in-progress character art, or drafts a public post for use now. Checked by: the EP's read; the site name scan where it applies.

Constraints:
- Tokens: about 0.25M (one S row), an estimate.
- State hash: no change.
- Machine: no Godot or browser runs are needed for this brief.
- Determinism: not touched.
- Originality: the pitch stands on the game's own ideas; comparisons to named games stay out of anything forward-facing.
- Orb's rules: forward-facing text is written with care and seen by Orb before use; the AI disclosure goes everywhere the game is shown or described; in-progress character art is never public; spending is Orb's decision and the budget is zero; plain words. Anything public stops and goes to Orb through the EP as one question.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Needs decisions 8, 9 and 10 (the report channel, the itch.io page, the licence line), answered by A2. Item 4 waits on QA's guide; item 5 on Tools' shot list. Legal's row on the revised plan waits on item 1. Nothing in A6 waits on this brief.
