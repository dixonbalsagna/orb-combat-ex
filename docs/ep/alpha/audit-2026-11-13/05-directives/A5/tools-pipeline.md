# A5: Tools & Pipeline

Leads: A-MARKET-05, A-MARKET-06, A-SAVES-08
Supports: A-QA-01

Goal: The build a newcomer downloads from the itch.io page with a key is the real A5 build, it can be updated and taken back in one step, and the pictures kept of each milestone are full-size shots of the game as it is really played.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A5, exit lines X-31 and X-34); `docs/ep/alpha/alpha-audit-specification.md` lines 196 to 201 (X-29 to X-34); `tools/clips/clips.json` lines 1 to 16; `tools/clips/make.mjs` lines 1 to 12; `docs/tools/clips.md`; `docs/tools/clip-capture-audit.md`; `docs/marketing/steam-readiness.md` lines 15 to 16; `docs/marketing/store-copy-draft.md` lines 103 to 106; `docs/tools/runs/mms-2026-11-10/takes-towers-and-clash.json`; `tools/desktop-package.mjs`; `docs/tools/desktop-builds.md`; `docs/ep/alpha/audit-2026-11-13/reads/RR-04.md` line 15.
- A-MARKET-05: footage is made at 960 by 540, shrunk to 480 wide at 12 pictures a second, as GIF or browser-recorded WebM, with no MP4. Evidence: `tools/clips/clips.json:7-14` (the defaults: size 960 by 540, 12 a second, width 480, GIF); `tools/clips/make.mjs:9-10`; `docs/tools/clip-capture-audit.md:16` (no video encoder installed). The verifier's note: size, width and rate are recipe values a recipe can raise without code, and the Steam sizes (`docs/marketing/steam-readiness.md:15-16`: screenshots at least 1920 by 1080) bind at Beta.
- A-MARKET-06: the clips shared so far were staged on a private test copy with behaviour the game does not have, so they cannot be remade from main. Evidence: `docs/tools/runs/mms-2026-11-10/takes-towers-and-clash.json`; `docs/tools/pending/mms-tweaks/` (the only place the scratch camera is named); `docs/marketing/store-copy-draft.md:103-106` (real captures only).
- A-SAVES-08 (nice to have): where the game keeps its files is written nowhere a tester would read, and the folder is the engine default named after the working title. Evidence: `project.godot:8` (the name; no custom user folder is set, RR-04 line 15); `ui/core/ui_prefs.gd:7` (`user://ui_prefs.json`); `sim/input/remap.gd:13` (`user://input.json`); `sim/world/field_cache.gd:37` (`user://field-cache/`).
- A-QA-01 (QA leads): no tester guide exists. Your part is the package that carries it.

You own: `tools/`, `build/`, `.github/`.
- ask under NEEDS FROM EP for a grant: `docs/tools/` (your pages and run records; the folder has no owner).
- ask under NEEDS FROM EP for a grant: `project.godot`, only if Orb agrees to a fixed settings folder (item 6).
- Uploading to itch.io uses Orb's account: you prepare the command and the record; Orb or the EP, on Orb's word, runs it.

Acceptance criteria:
1. (A-MARKET-05) Every recipe on the fixed shot list (A-MARKET-01) captures at 1920 by 1080 and is kept as a full-size picture sequence in the milestone archive, with the small GIF made from it for looking at; no video encoder is installed for Alpha. Checked by: the A5 set's index, listing each shot's size and frame count, and the flash check's verdict on each sequence (A-MARKET-04), saved under `docs/tools/runs/<sha>/`.
2. (A-MARKET-05) The time and CPU a full-size shot set takes through the guarded launcher is measured once and written down, so the A6 set can be scheduled. Checked by: the figure on your page, with the run's log.
3. (A-MARKET-06) The shot list carries a written rule and the kit enforces it: stock build, stock inputs, real speed, no scratch-only camera or page word that changes behaviour; each shot is labelled "played" or "staged", and a recipe whose page words change behaviour fails unless it is labelled staged. The staged clips of 2026-11-10 are marked in their index as not the game as played and not for public use. Checked by: the kit's self-test with a staged recipe that must fail, saved.
4. (exit X-34) The shot list has rendered from the A1, A2, A3, A4 and A5 builds and the five sets sit side by side in the archive, each with one line on what changed; where an old replay no longer plays, the rule from A-MARKET-07 was followed. Checked by: the archive's index.
5. (exit X-31) The A5 build is on the restricted itch.io page on the Windows and the Linux channel, was applied once as an update through itch's upload tool, and was rolled back once to the A4 build and forward again, by the release checklist from A-TOOLS-03. Checked by: the rehearsal record under `docs/tools/runs/<sha>/`, with the version number each step showed in the game. Must pass with the real build.
6. (A-SAVES-08) The package's README and QA's tester guide say in plain words where settings, remapped controls and the planet cache are kept on Windows and on a Steam Deck, how to clear them, and that removing the game leaves them. A recommendation goes to the EP on giving the folder a fixed name that does not follow the title; if Orb agrees, it is set once, with a grant, and the settings round-trip test (A-UI-10) passes after it. Checked by: the README text (seen by Orb before use) and the test output.
7. (supports A-QA-01) The package carries QA's guide and checklist and Legal's note unchanged, with the AI disclosure first; the Deck install path in the package needs no keyboard and no terminal. Checked by: the package's file list and `tools/desktop-package-selftest.mjs`, saved.
8. (all) The one-command build (A-TOOLS-01) made the A5 packages from a clean commit, with the version number the game shows and a changelog entry (X-29); the gate results behind each landing are saved under `docs/tools/runs/<sha>/` (CD-22); CI is read after every push.

Constraints:
- Tokens: about 0.75M (three S rows), an estimate; the exit lines X-31 and X-34 are runs, not new work.
- State hash: no change. A settings-folder name does not touch the sim.
- Machine: the browser is started only through the guarded launcher you built (`tools/machine/capture.mjs`): a time limit, below-normal priority, the session's name in the profile, one software-rendered capture at a time; a full-size shot set is a long run; check `tools/machine/captures.mjs` shows nothing of yours running before you end a turn. Headless Godot only, at most 3 processes for a short gate.
- Determinism: a recipe names its build, seed and tick window, so the same recipe gives the same shot on the same build.
- Originality: every frame is the game itself; no stock footage, no mock-up labelled as play.
- Orb's rules: in-progress character art is never public, and nothing in the archive is published without Orb's word; the AI disclosure goes wherever the game is shown; nothing is drawn on, over or between the fighters in a shot; plain words in the README, which Orb sees before use.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Needs A-TOOLS-01 and A-TOOLS-07 (A1), and A-TOOLS-02, A-TOOLS-03, A-MARKET-01 to A-MARKET-04 and A-MARKET-07 (A2). Item 5 waits on the A5 build passing its other exits and on Orb's upload action. Item 7 waits on QA's guide and Legal's sign-off. A6's candidate upload, its shot set and the two friends' install wait on items 4, 5 and 7.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- The update-and-roll-back rehearsal runs on a dummy channel no tester's key can see. Every upload to itch.io is Orb's own action, listed on Orb's page for this milestone; no session uses Orb's sign-in, so "or the EP" does not apply. (PC-08) (PC-01)
