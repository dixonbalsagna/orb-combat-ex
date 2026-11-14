# A5: Narrative & Fighter Identity

Leads: none
Supports: A-TEXT-01, A-UI-08

Goal: Every line a tester reads in the menus, the notice and How to play sounds like one careful voice, says what is really on screen, and has been approved by Orb.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A5; decision 22); `docs/ep/vision.md` line 951 and lines 1191 to 1198; `docs/narrative/writing-quality.md`; `docs/ui/strings.md` (the head: the Mark column and the **N** flag for lines your page names); `ui/data/howto.json` lines 70 to 80, to read only; the short list of about 150 strings UI makes for this milestone, with Orb's marks, which the EP will send.
- A-TEXT-01 (UI leads): no record shows Orb has seen the menu, how-to, hint, notice or settings text. Evidence: `docs/ep/vision.md:951` (Orb found the forward-facing writing "rushed and bizarre"; it is to be written with care and seen by Orb before it is used); `docs/ui/strings.md:3` (1115 strings); `docs/ui/strings.md:11` (the Mark column is empty).
- A-UI-08 (UI leads): How to play's "Reading the fight" page describes things the minimal HUD no longer draws. Evidence: `ui/data/howto.json:73` (a ring flashes), `:77` (finishing-move rings), `:78` (the box at the top), `:79` (the planet strip).

You own: `docs/narrative/`, `data/fighters/`.
- The words live in UI's data (`ui/data/`). You draft in `docs/narrative/`; the EP shows Orb and passes approved lines to UI. You do not edit `ui/data/` and you do not message UI.

Acceptance criteria:
1. (supports A-TEXT-01) Before Orb reads the short list, you return it to the EP with a suggested line beside any string your own `writing-quality.md` rules would fail, so Orb marks once, not twice. Checked by: the annotated copy in `docs/narrative/`.
2. (supports A-TEXT-01) Every string Orb marks "rewrite" gets one drafted line (two only where the choice is real), the same length or shorter than the original so UI's layout at 1280 by 800 holds. Checked by: a table in `docs/narrative/`: key, old line, new line, Orb's mark on the new line. No line reaches UI without that last mark.
3. (supports A-UI-08) For each "Reading the fight" line that names a mark the screen no longer draws, a replacement says how the fight itself shows the same thing (the body's motion, the camera, the sound, the rumble), or recommends the line be cut. Each claim is checked against the A4 build with the EP, not written from an older design page. Checked by: the same table; Orb's mark.
4. (both) The drafts are read against Legal's never-use word list (`docs/legal/never-use-words.md`) and your own `docs/narrative/writing-quality.md`. Checked by: a short record of the read, line by line where a rule was close, saved under `docs/narrative/runs/<sha>/` (CD-22).

Constraints:
- Tokens: no row of its own; plan on about 0.25M of supporting work, an estimate.
- State hash: no change.
- Machine: no Godot or browser runs are needed for this brief.
- Determinism: words are data; you change no data shape.
- Originality: no catchphrase, name or turn of phrase from an existing franchise; Legal screens names, so any new name in a line goes to the EP first.
- Orb's rules: plain words, saying what you press and what you see, with no team nicknames; forward-facing text is seen by Orb before use; only Orb's mark approves a line; English only at Alpha.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Item 1 waits on UI's short list (UI's item 1). Items 2 and 3 wait on Orb's marks. UI's items 2 and 4 wait on your approved lines, and the tester guide's screenshots wait on those.
