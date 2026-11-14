# A2: Accessibility & Localization

Leads: A-ACCESS-01
Supports: A-ACCESS-02, A-ACCESS-04, A-SAVES-02, A-UI-07, A-LEGAL-03, A-LEGAL-08, A-MARKET-04

Goal: A tester who needs a comfort or access setting finds it in the build and it works, and the team has a dated checklist proving that on the build's own commit instead of a page from October.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A2), `02-areas/ACCESS.md`, `02-areas/LEGAL.md` (gate G20 on the list under Q1, and Q2 for what a tester gets by default), `docs/accessibility/audit-2026-10-28.md`, `docs/ep/corrective-plan-2026-11-07.md` (corrective item CD-14, line 22).
- A-ACCESS-01: there is no accessibility pass or record newer than 2026-10-31 and no runs folder for the area, so the accessibility items of the "before an outside tester plays" list do not exist as a list. Evidence: `docs/accessibility/audit-2026-10-28.md:1`, `:11`; `docs/ep/corrective-plan-2026-11-07.md:22`; `reads/RR-09.md:32`. Risk named in the register: the October summary still says there are no volume controls and no text size, which is no longer true.

You own: `docs/accessibility/`, `localization/`.
- ask under NEEDS FROM EP for a grant: none expected. The settings live in `ui/` (UI) and the pad layouts in `data/input/` (no owner): you read them and report; fixes go through the EP.

Acceptance criteria:
1. (A-ACCESS-01) A checklist page in `docs/accessibility/` lists the access and comfort items a tester's build must have (start from CD-14's four parts and the defaults read in `02-areas/LEGAL.md` Q2: Reduce flashing on and locked, reduced motion, captions, camera shake, rumble, colour-vision help, text size, volumes, mono, a brace button on pads, remapping), and for each: where it is in the build, how it is checked, and its state.
2. (A-ACCESS-01, exit line X-02) The checklist is run against the A2 commit by reading the build's own packed data and the code, not the plan, and saved under `docs/accessibility/runs/<sha>/` (corrective item CD-22). This is gate G20's record on Legal's list. Each failing item has an owner proposed to the EP.
3. (A-ACCESS-01) `docs/accessibility/audit-2026-10-28.md` is marked superseded at its top with a pointer to the new page, so nobody plans from it.
4. (A-ACCESS-01) The checklist says which items are confirmed only by a person (readable text on the Deck's screen, captions in time with the sound) and puts those questions on the friends' sheet through the EP.
5. (supports) A-ACCESS-04: tell the EP the true state of each of CD-14's four parts with file lines (the brace button is done on the Arena layout, `data/input/layouts.json:136-140`). A-ACCESS-02: confirm that hiding the Hit pause slider leaves no dead row behind. A-SAVES-02: read the tester package's packed lock setting. A-UI-07: check the feedback panel's pad route. A-LEGAL-03, A-LEGAL-08 and A-MARKET-04: review the gate list's safety rows, the repaired measuring chain's self-test and the clip-screening page for anything a player with a sensitivity would need that is missing.
6. Nothing in this brief changes the picture. If a finding leads to a visible change, its owner ships it with a side-by-side against the reference build (the look gate, ADR 0010); safety is met with warnings and settings, not by making the default look worse.

Constraints:
- Tokens: about 0.25M as an estimate (one S row at the size class); the supporting reads are small.
- State hash: no change; this brief touches no game code. A2 has no golden window.
- Machine: no Godot run is needed for the read; if you run a check, headless only, at most 3 Godot processes, stills only through Tools' launcher.
- Determinism: not touched. Any threshold you propose (a smallest text size, a volume range) is written so its owner can put it in data.
- Originality: nothing to add.
- Orb's rules: plain words; English only for Alpha is the recommendation and the guide says so; every line a tester reads is seen by Orb before use. The items on flashing are worked like any other but are not put in front of Orb as questions.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: starts once A1's settings and menu rows are on main (A-UI-01, A-UI-02, A-UI-09) so the pass reads the real build. Criterion 2 is run last, on the A2 commit. Waiting on this brief: Legal's gate list (A-LEGAL-03, gate G20) and the EP's CD-14 row (A-ACCESS-04).
