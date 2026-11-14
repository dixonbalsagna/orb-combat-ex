# A1: Accessibility & Localization Director

Leads: none
Supports: A-UI-09

Draft for the Executive Producer (EP) to send once Orb approves the path to Alpha. Nothing here is decided until then.

Goal: The first set of stills of every menu at the Steam Deck's screen size comes with a plain list of where text is too small or cut off, so the fixes can be planned before a tester holds a Deck.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A1; the X-22 line in "Exit criteria this audit proposes to change"); `docs/ep/alpha/audit-2026-11-13/02-areas/ACCESS.md` and `UI.md`; `docs/ep/alpha/audit-2026-11-13/02-areas/web-checks.md` (the Deck text-size guidance the audit read); `docs/tools/steam-deck.md`.
- A-UI-09 (UI leads): X-22 cannot be measured today: there is no still of any screen at 1280 by 800 and no tool that sweeps every screen at that size. Evidence: `ui/tools/text_size_check.gd:7` (the only check that plans the screens at 1280 by 800; it is in no gate list); `ui/tools/hud_check.gd:10824` (the left-panel menus' size list has no 1280 by 800); `docs/ui/runs/397a7adf/menus/today-start-1280x720.png` (saved stills are 1280 by 720). The register's check note adds that `tools/l10n/overflow_check.gd` has no such case and that `docs/tools/steam-deck.md:19` says Deck text size is not checked.
- The proposed reading of X-22: 9 px is the floor that fails the sweep, 12 px is the aim.

You own: `docs/accessibility/`, `localization/`.
- The sweep tool is UI's (`ui/tools/`) and the overflow check is in Tools' path (`tools/l10n/`): ask under NEEDS FROM EP for a grant: `tools/l10n/overflow_check.gd` (only if you add the 1280 by 800 case yourself).

Acceptance criteria:
1. (A-UI-09, X-22) UI has from you, through the EP, the rule the sweep applies: the smallest text allowed on a 1280 by 800 screen (floor and aim), what counts as clipped and what counts as overlapping, and how the longest strings are chosen (the pseudo-language set under `localization/pseudo`, if it is current; say if it is not).
2. (A-UI-09, X-22, first reading) When UI's first full set of stills is saved under `docs/ui/runs/<sha>/`, you read every one and write one list in `docs/accessibility/`: screen, what is wrong, floor or aim. The list existing closes your part; problems are expected and are listed, not fixed, in A1.
3. The overflow check either gains a 1280 by 800 case or your report says in one line why the sweep makes it unnecessary.
4. Records: your list names the stills' folder and commit (corrective item CD-22). `docs/accessibility/` has no runs folder yet; a `runs/<sha>/` folder there is where A2's accessibility pass (A-ACCESS-01) will save its results.

Constraints:
- Tokens: no rows of your own in A1; allow about 0.25M as an estimate for the supporting work.
- State hash: nothing here changes the sim's state fingerprint.
- Machine: no browser of your own (stills come only through Tools' launcher, and UI asks for them); headless Godot only; at most 3 Godot processes for a short gate.
- Determinism and data: text sizes and strings live in data, not code.
- Originality: nothing from an existing franchise.
- Orb's rules: plain words; a minimalist UI with nothing drawn on, over or between the fighters; the fix for small text is never a blur, a fade or a panel over the fight; forward-facing text is seen by Orb before use; English only for Alpha is the recommendation on the table (decision 22), so no translation work starts here.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Item 1 is wanted on day one so UI's sweep is built to it. Item 2 waits on UI's sweep and its first stills, which wait on the left-panel menus being main's default (A-UI-04, A-MODES-15). Waiting on this: the text fixes in later milestones, and X-22, which must pass from the milestone after the first reading.
