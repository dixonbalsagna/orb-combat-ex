# A2: UI & UX

Leads: A-ACCESS-02, A-LEGAL-13, A-SAVES-02, A-UI-07, A-UI-10, A-TEXT-01
Supports: A-CONTROLS-03, A-TOOLS-05, A-PERF-03, A-LEGAL-12, A-ACCESS-01

Goal: A tester holding only a pad can read the notice and the AI disclosure on the first screen, file a report from the panel, and find their settings and controls as they left them after a restart, with no setting on screen that does nothing.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A2), `02-areas/UI.md`, `02-areas/SAVES.md`, `02-areas/ACCESS.md`, `02-areas/LEGAL.md` (Q2, Q3), `docs/decisions/0010-look-gate.md`, `docs/ep/taste.md`.
- A-UI-07: the feedback panel cannot be worked with a pad: B or Start closes it and nothing else. Evidence: `ui/hud/ui_hud.gd:1402`, `:1406`; `ui/data/howto.json:102`.
- A-UI-10: settings and remapped controls have never been tested across a real restart on Windows or Linux, and a failed write is silent. Evidence: `ui/tools/hud_check.gd:7859`, `:5877` (round trips inside one process); `ui/core/ui_prefs.gd:36`.
- A-SAVES-02: on main the lock that keeps Reduce flashing on is off, so a saved Off is read back at start-up, and every build shares one settings folder. Evidence: `ui/data/features.json:12`; `ui/core/ui_data.gd:427-428`; `ui/hud/ui_hud.gd:2484-2495`. Verified detail: every desktop build path turns the lock on and refuses to build without it, and a locked build ignores a saved Off (`ui/hud/ui_hud.gd:2491-2492`), so this is a default on main, not a fault in a shipped build.
- A-ACCESS-02: the Hit pause slider is shown on the Accessibility page and has no reader outside the user interface (corrective item CD-14, open). Evidence: `ui/data/settings.json:56`; `ui/data/options.json:50`; `ui/hud/ui_hud.gd:72`.
- A-LEGAL-13 (nice to have, placed here because the notice is already open): in a desktop build the AI disclosure is not on the first screen. Evidence: `ui/widgets/ui_notice.gd:24`; `ui/data/howto.json:88`, `:105`; `tools/desktop-package.mjs:282`.

You own: `ui/`, `docs/ui/`.
- ask under NEEDS FROM EP for a grant: `.github/` (a Linux step for the restart test) or have Tools add it through the EP
- ask under NEEDS FROM EP for a grant: `sim/input/remap.gd` (only if the remap file's write needs the same failed-write notice; otherwise Controls does it through the EP)

Acceptance criteria:
1. (A-UI-07) With a pad alone, every tag, Copy and Save on the feedback panel can be reached and pressed, and the panel closes as before; the typed note stays optional. Check: a scripted-pad test in `ui/tools/hud_check.gd`, output saved under `docs/ui/runs/<sha>/`. On a Deck this is confirmed by the friends' sheets (a person's check, collected by the EP).
2. (A-UI-10) A test changes settings and a remapped control, ends the process, starts a second process and reads them back, on Windows and on Linux in CI. A write that fails shows one plain line and does not lose the session's choices. Record: both platforms' output under `docs/ui/runs/<sha>/`.
3. (A-SAVES-02) A locked build that finds a saved Off for Reduce flashing starts with it on (test), and the A2 package's own packed features data is read and shows the lock on. A written decision in `docs/ui/` on main's default (lock on by default, with developers switching it off, is the safer reading) goes to the EP under DECISIONS. Record: `docs/ui/runs/<sha>/`.
4. (A-ACCESS-02) Smaller version, pending Orb's answer: the Hit pause slider is hidden in every build until the hit freeze is switched on in the game, and CD-14's row says so. Check: a still of the Accessibility page and the hud check. Full version if Orb declines the proposal: the slider is wired to the sim's hit-stop, which changes the state hash and so moves out of A2 into GW2 (A3's window) under Simulation & Engine.
5. (A-LEGAL-13) The first screen of a desktop build carries the AI disclosure beside the existing notice, in Legal's words, and no route skips it. Orb sees the words before use. Check: a still of the first screen; the package's routes check, saved under `docs/ui/runs/<sha>/`.
6. Every change above that alters a screen ships with a side-by-side against the reference build recorded in `docs/ep/taste.md` (the look gate, ADR 0010; `node tools/flash/side-by-side.mjs`) before it is committed.
7. (supports) A-CONTROLS-03: build the plain pause notice for an unplugged pad that Controls triggers. A-TOOLS-05: the one Save report row that Tools' report code sits behind. A-PERF-03: one hidden or plainly named bench row that cannot open a route round the safety lock. A-LEGAL-12: put Legal's single privacy wording on the About page (`ui/data/howto.json:102`). A-ACCESS-01: answer Accessibility's checklist questions on text size, volume rows and captions with file lines.

Constraints:
- Tokens: about 1.25M as an estimate (five S rows at the size classes).
- State hash: no change. The interface must not write the sim (a sim "getter" has resized hashed fields before); A2 has no golden window.
- Machine: headless Godot only; at most 3 Godot processes for a short gate; stills only through Tools' guarded launcher, one capture at a time, checked before the turn ends.
- Determinism: nothing in `ui/` feeds the sim; settings numbers live in data, and a shape change to a data file updates its schema in the same commit.
- Originality: no layout, icon or wording lifted from an existing game.
- Orb's rules: nothing drawn on, over or between the fighters; no health bar on screen; no dissolves or fades in any panel; plain words (say what you press and what you see); every forward-facing line is seen by Orb before use; the AI disclosure is up front.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: A1's menu work (A-UI-01, A-UI-02, A-UI-09) and the desktop build (A-TOOLS-01) land first. Criteria 3 and 5 must land before the package goes to a tester (Legal's gate list reads them). Tools' report (A-TOOLS-05) and Performance's bench (A-PERF-03) wait on the rows in criterion 7. Criterion 4 waits on Orb's answer; hide is the default if none comes.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- A-TEXT-01 moves here from A5: cut the short list (about 150 lines a tester meets) after A1's menu changes land, and Orb marks it before a friend plays. A5 keeps only lines changed since. The flashing notice's safety sentences, the Reduce flashing row and the package's safety lines are marked "Legal's words, not for marking"; a rewrite of them is routed by the EP to Legal. (ORB-03, PC-11)
