# A1: Legal & IP Compliance

Leads: A-LEGAL-09
Supports: A-LEGAL-02, A-LEGAL-10, A-TOOLS-01

Goal: when Orb's first desktop build is ready, nobody is unsure whether it may be made, what paper goes inside a tester's folder, what a friend may do with the build, or whether a private download page may exist under the working title.

Context: read first `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A1 and decisions 7, 9 and 10), `02-areas/LEGAL.md`, `docs/legal/name-screening.md`, `docs/legal/review-log.md`, `docs/legal/steam-readiness.md`, `docs/legal/guide-licence-rundown.md`, `docs/legal/alpha-tester-note.md`, `.github/workflows/desktop-builds.yml` lines 50 to 62 (the step that refuses a build without Orb's recorded yes).
- A-LEGAL-09 (S, lead): whether a restricted, key-only itch.io page may go up before the title search is not confirmed anywhere; your own page and the audit directive both say the search comes first, and the plan row (CD-06) is empty. Evidence: `docs/legal/name-screening.md:186`; `audit/2026-11-07/corrective-directive.md:17`; `docs/ep/corrective-plan-2026-11-07.md:14`.
- A-LEGAL-02 (Tools' row, you support): no desktop package for an outside tester can be made today; the package text step reads a notice file still marked draft. Evidence: `.github/workflows/desktop-builds.yml:54`; `tools/desktop-package.mjs:31`, `:35`; `tools/site.json:5`.
- A-LEGAL-10 (Orb's row, you support): Orb's one-line licence choice is not on record, so the build says the licence is not chosen yet and no plain permission page exists. Evidence: `docs/legal/guide-licence-rundown.md:54`; `docs/legal/review-log.md:289`; `ui/data/howto.json:98`.
- A-TOOLS-01 (Tools' row, you support): the only desktop workflow refuses without `docs/ep/approvals/desktop-test-builds.txt`, which does not exist. Evidence: `.github/workflows/desktop-builds.yml:15`, `:52`.

You own: `docs/legal/`.
- Wording that must appear in the build or the package (`tools/site.json`, `ui/data/howto.json`) is not yours to edit: write the final text in `docs/legal/` and name the file it belongs in under NEEDS FROM EP.
- The approval file under `docs/ep/approvals/` is the EP's, written only on Orb's recorded word.

Acceptance criteria:
1. (A-LEGAL-09) A review-log row and a short ruling in `docs/legal/` answer one question: may a restricted, key-only itch.io page exist under the working title before the paid title search? The ruling states its conditions (for example: unlisted, unpromoted, marked as a working title, one key per named friend), what would end it, and what still waits for the search. `docs/legal/name-screening.md:186` and the CD-06 row no longer contradict it. Check: the EP reads the row; the question to Orb in orb.md matches the ruling's wording. The page itself is not created in A1.
2. (A-TOOLS-01, support) A ruling on the build Orb plays themselves: may the Windows and Linux builds of A1 be made for Orb and the trusted second player before the recorded yes for outside testers, and if so what the workflow must still refuse. One row, with the exact condition Tools should code. Check: Tools can quote it in the workflow's comment.
3. (A-LEGAL-02, support) The notice a tester folder carries is no longer draft: final plain wording for README.txt and NOTICES.txt (the AI disclosure up front, what leaves the PC, credits and third-party notices), written in `docs/legal/` for Tools to place. Orb sees the wording before it is used. Check: Orb's yes recorded by the EP; Tools' package step no longer reads a file marked draft.
4. (A-LEGAL-02, support) The exact text of the approval line Orb will be asked to record when the gates are green ("yes to desktop test builds for named outside testers"), matching what the workflow checks for (a date, a scope line, a recorded-by line, not older than 30 days). Check: the EP can paste it into the approval file unchanged on Orb's word.
5. (A-LEGAL-10, support) A short, friendly permission page in plain words for the choice recommended to Orb: everything all rights reserved through Alpha, what a tester may do (play, record, share clips or not, as you advise), what they may not, and that public code is decided at Beta. Written so the build's "licence not chosen yet" line can be replaced the day Orb answers. Check: the page exists; the replacement line is named under NEEDS FROM EP for UI.
6. Evidence: each ruling's row number and date listed in one file under `docs/legal/runs/<sha>/` (corrective item CD-22), where `<sha>` is the commit the ruling was written against.

Constraints: about 0.25M tokens for the lead row (1 S), an estimate; the three supports are small pages on top. Nothing here changes the sim's state hash, and no Godot or browser run is needed (if you want a still of the in-game licence line, ask the EP; captures go only through Tools' launcher). Your scope is names, likeness of whole characters, trademarks, copied assets and real player safety; pose, gesture and look rules are Orb's creative direction and never block a gate. Every Legal flag goes to Orb through the EP as one plain question with one recommendation. Forward-facing text is seen by Orb before use. The AI disclosure is stated up front wherever the game is shown or handed out. In-progress character art never goes on a public page, including a restricted one's cover image. Nothing personal about Orb or the testers in any page: testers are "a named friend", never named in the repository. No spend: the paid title search stays a later decision of Orb's. Originality: no names of existing franchises in any ruling.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: nothing must land first; start on day one. Criterion 2 is needed before Tools' first desktop build (step 6 of A1), and criteria 3 and 4 before A-LEGAL-02 can close. Criterion 1 is needed before the itch.io rehearsal in A2 (A-TOOLS-02). The path also briefs you on day one for work that closes in A2, as a separate brief in the A2 folder: the outside-tester safety gates (A-LEGAL-01, A-LEGAL-08, A-LEGAL-03) and the tester note. Waiting on you: Tools (A-TOOLS-01, A-LEGAL-02), Orb's answers to decisions 9 and 10, and UI's licence line.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- Criterion 2, added: the ruling says whether a CI run on the public repository may keep a game program as a run file, in what lock state and for how long, and how Orb's own A1 copy reaches Orb's PC. (PC-03)
- Criterion 1, added: if the ruling on a key-only page before the title search is no, say which follows: a neutral placeholder name that you screen in the same row, or the paid search brought forward as a spend question to Orb. (PC-10)
