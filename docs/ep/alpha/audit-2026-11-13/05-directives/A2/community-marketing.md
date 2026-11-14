# A2: Community & Marketing

Leads: none
Supports: A-MARKET-01, A-TOOLS-02, A-LEGAL-05

Goal: The same six shots are filmed from every milestone's build so later videos can show the game growing, and a friend opening the private test page or the guide reads plain, honest words with the AI disclosure first.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A2), `02-areas/MARKET.md`, `docs/ep/alpha/alpha-audit-specification.md` section 10 (from line 625), `docs/tools/clips.md`, `docs/legal/alpha-tester-note.md`, `docs/marketing/go-to-market-plan.md`.
- A-MARKET-01 (led by Tools): there is no fixed shot list: the recipe file covers three of the six named shots and has no recipe for a transformation, a lap of the globe or a LAN 2v2 moment. Evidence: `tools/clips/clips.json:57`, `:61`, `:66`. Risk named in the register: a staged scene is not a played match, so the list should say which shots are staged.
- A-TOOLS-02 (led by Tools): nothing for itch.io exists, including the page's words. Evidence: no file under tools, .github, net or docs/tools names the site; `02-areas/web-checks.md` (itch.io table).
- A-LEGAL-05 (led by Legal): the tester note is a draft and nothing records how a tester agrees. Evidence: `docs/legal/alpha-tester-note.md:3`, `:11`.

You own: `docs/marketing/`.
- ask under NEEDS FROM EP for a grant: none expected. The shot list's data file is Tools' (`tools/clips/`); the tester note is Legal's; the guide is drafted with QA through the EP.

Acceptance criteria:
1. (supports A-MARKET-01) A one-page shot brief in `docs/marketing/`: for each of the six shots, what a viewer should see in plain words, how long it runs, whether it is played or staged, and what must stay the same from milestone to milestone so the shots can sit side by side. Tools turns it into the data file. Check: the EP reads the page against Tools' file.
2. (supports A-TOOLS-02) Draft words for the restricted itch.io page: a title line with "(working title)", two or three plain sentences, the AI disclosure up front, "private test, please do not share, stream or clip", and no screenshot or character art. Legal reviews it and Orb sees it before it is used. Check: Legal's review row; Orb's yes.
3. (supports A-LEGAL-05) With QA through the EP: the full draft of the tester guide and the one-page sheet read as one voice with Legal's note, in plain words, AI disclosure first, English only said plainly. Orb sees both before a friend gets them.
4. Nothing here is posted, published or sent by you: every item is a draft handed to the EP. The archive of shots is private and is not shown anywhere in this milestone.

Constraints:
- Tokens: not counted in the path's totals (supporting work); about one S (0.25M) as an estimate.
- State hash: no change; this brief touches no game code.
- Machine: no Godot or browser runs.
- Determinism: not touched; shots are built from seeded recipes so they repeat.
- Originality: no wording, tagline or framing borrowed from an existing game's page; no comparison to any existing franchise by name.
- Orb's rules: plain words; every forward-facing line is seen by Orb before use; the AI disclosure everywhere the game is shown or handed out; in-progress character art is never public, and a restricted page counts as a place other people can see; nothing is promoted or linked while the title search is open.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: criterion 1 can start today and Tools' shot-list file waits on it. Criterion 2 waits on Legal's ruling on a page under the working title (A-LEGAL-09, A1) and feeds Tools' checklist for Orb's one sitting. Criterion 3 feeds the two friends' session.
