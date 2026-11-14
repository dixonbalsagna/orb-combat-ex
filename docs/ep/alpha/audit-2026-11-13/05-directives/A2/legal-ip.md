# A2: Legal & IP Compliance

Leads: A-LEGAL-03, A-LEGAL-05, A-LEGAL-12, A-TOOLS-06
Supports: A-LEGAL-01, A-LEGAL-06, A-LEGAL-07, A-LEGAL-08, A-LEGAL-13, A-MARKET-04, A-TOOLS-02, A-ACCESS-01

Goal: Before any friend outside the trusted two plays, there is one list of safety and paperwork gates with a saved record for each on the build's commit, and the tester reads the same plain privacy and safety words everywhere they appear.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A2), `02-areas/LEGAL.md` (Q1: the draft list of twenty gates, G1 to G20, with their state at the baseline), `docs/legal/review-log.md`, `docs/legal/alpha-tester-note.md`, `docs/legal/alpha-discord-flags.md`, `.github/workflows/desktop-builds.yml`, `tools/desktop-package.mjs`.
- A-LEGAL-03: the list of gates that must be green before an outside tester plays did not exist before the audit, and several gates have no saved record or no tool. Evidence: `docs/ep/alpha/alpha-audit-specification.md:169`; `docs/legal/review-log.md:289`; `audit/disclosure/3-gate-inventory.md:1`.
- A-LEGAL-05: the tester note is a draft for Orb to send, its review row is open on two conditions, and nothing records how a tester confirms being an adult or agrees to the terms. Evidence: `docs/legal/alpha-tester-note.md:3`, `:11`; `docs/legal/review-log.md:289`.
- A-LEGAL-12: the privacy words differ between the package README, the in-game About page and the tester note, and none of the words inside a build mention the two-PC link or the report channel. Evidence: `tools/desktop-package.mjs:43`; `ui/data/howto.json:102`; `docs/legal/alpha-tester-note.md:28`, `:29`.
- A-TOOLS-06: the desktop package rules were written for private test builds and conflict with an Alpha on itch.io (files kept one day, the run deleted after hand-over, no link or mention, an approval under 30 days old, network play absent). Evidence: `.github/workflows/desktop-builds.yml:3-9`, `:52`, `:163`; `tools/desktop-package.mjs:211`, `:219`, `:346-348`.

You own: `docs/legal/`.
- ask under NEEDS FROM EP for a grant: none expected. The package rules live in `.github/workflows/desktop-builds.yml` and `tools/desktop-package.mjs` (Tools), the About page in `ui/data/howto.json` (UI): you write the ruling and the exact words; the EP routes the change to the owner.

Acceptance criteria:
1. (A-LEGAL-03) One tracked page in `docs/legal/` holds the gate list: each gate, its source, who owns it, how it is checked and where its record is saved for a commit. Start from the audit's G1 to G20 and confirm or correct each. Check: the EP reads the page against `02-areas/LEGAL.md`.
2. (A-LEGAL-03, exit line X-02) For the A2 commit, `docs/legal/runs/<sha>/` holds one line per gate pointing at its saved record under `docs/*/runs/<sha>/` (corrective item CD-22), including the measurements on the globe ground that every played build uses. A gate with no record is red. The build is not handed to a tester while any gate that is a safety gate or a blocker is red.
3. (A-LEGAL-05) The tester note is final, in plain words, and its review row is closed with both conditions answered. The page says how a tester confirms being an adult and agrees: recommended, a dated list kept privately by Orb and never in the repository, one line per named friend before their key is issued. Orb sees the note before it is sent.
4. (A-LEGAL-12) One privacy wording, written once, used word for word in the package README, the About page and the tester note: nothing leaves the PC unless the tester sends it; reports the tester posts go to Orb's private report server, which a third party runs; and, for a build that holds the two-PC link, what that link does. Check: a review row per place; the package check fails on a build that holds network code and still says it makes no connection.
5. (A-TOOLS-06) A written ruling that re-cuts the package rules for an Alpha handed out on a restricted, key-only itch.io page: how long files are kept, what may be linked or mentioned and to whom, how fresh Orb's approval must be, and what a build with network code must say. The packer's refusals still mean something afterwards: each old rule is kept, changed or retired by name. Tools changes the workflow only after this row exists.
6. (supports) One review row each, with conditions if any: the flash reading on the globe ground and the repaired measuring chain (A-LEGAL-01, A-LEGAL-08); the scan of report files (A-LEGAL-06); the report server's set-up as Orb decides it (A-LEGAL-07); the AI disclosure words for the first screen (A-LEGAL-13); how a clip is screened before anyone outside sees it (A-MARKET-04); the itch.io page text and the AI field (A-TOOLS-02); Accessibility's checklist (A-ACCESS-01).
7. Evidence: every row above is in `docs/legal/review-log.md` with its date and the commit it read.

Constraints:
- Tokens: about 1.0M as an estimate (four S rows at the size classes); the supporting rows are extra and small.
- State hash: no change; this brief touches no game code. A2 has no golden window (a landing that re-records the reference matches).
- Machine: no Godot or browser runs are needed; if you run a check, headless only, at most 3 Godot processes, captures only through Tools' launcher.
- Determinism: not touched. If a ruling asks for a number (a size cap, an age, a retention time), it is written so its owner can put it in data.
- Originality: screen names and whole-character likeness only; pose, gesture and look rules are Orb's creative direction and never block a gate (Orb, 2026-11-07).
- Orb's rules: plain words in every line a tester reads, and Orb sees each before use; the AI disclosure is up front everywhere the game is shown or handed out; in-progress character art is never public; no tester's name, account or address in the repository. The gate list's rows on flashing are worked like any other but are not put in front of Orb as questions.
- A Legal flag stops and goes to Orb through the EP as one plain question.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: started early in A1 (the tester note; the three A1 rulings A-LEGAL-02, A-LEGAL-09, A-LEGAL-10 land there). Criterion 5 lands before Tools' itch.io rehearsal (A-TOOLS-02, A-TOOLS-03). Criterion 2 needs A-LEGAL-01 (Camera) and A-LEGAL-08 (Tools) finished, and is the last thing to close. Waiting on this brief: Orb's one-line approval of desktop test builds, and so the two friends' Steam Deck session (A-PERF-01).

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- A tester's raw report and speed-test files are never committed: they live in a git-ignored folder, and only the team's own reading of them (numbers, no quoted notes) is saved under `docs/*/runs/<sha>/`. A tester's request to delete is carried out on that folder and on the report server. (PC-02)
- A-TOOLS-06's ruling splits two acts: "build and check a tester package, hand to nobody" (no approval) and "hand out commit <sha>" (Orb's yes, checked at upload); say how long a yes stays fresh. (PC-04)
- Criterion 4's privacy wording also says: a free itch.io account is needed to download (if the rehearsal confirms it), and itch.io has its own rules; what a tester posts is read with AI tools on Orb's PC. You choose the words. (PC-09)
- Gate G4 records which build each flash reading was taken on, and is read on the Linux desktop build's own frames once Tools can capture them. Rule whether a locked package may go out while the ordinary look's reading is still red. (PC-05, ORB-02)
- The net/ exception Netcode's work-ahead waits on is ruled here, in A2. (ORD-08)
