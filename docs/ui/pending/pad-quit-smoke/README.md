# pad-quit-smoke: the mode smoke drives pause and Quit with the pad and the game really closes; the refused replay's sentence (UI & UX, 2026-11-23; path-to-alpha-1 item 7 and the A1 exit row "with a plain message"; park)

Built and checked on a scratch copy of main 65768887 (items 1 and 3), proof records to be taken again on the GW1c commit.

## 1. The smoke (a grant: tools/smoke is Tools'): `grant/mode-smoke-pad-quit.patch` (sha1 8fd14ebc4d04)

- **Was:** the pause menu was opened with the P key (mode_smoke.gd:278) and Quit was answered with Stay (:291), so "quit with the pad" was unproven.
- **Now:** after the second match the smoke presses one pad button (a headless run has no connected pad, and Start pauses only for a pad that drives a slot; the press makes the host claim it, as a player picking the pad up does) and **Start on the pad opens the pause menu**. Pause Quit asks "Close the game?" with Stay lit; B stays; the pause "menu" row goes to the list of modes; its Quit asks the same and B stays; B goes back to the match; then **Start, Quit, "Close the game" with the pad: the game closes.**
- **How "closes" is proved:** `quit_requested` fires (main.gd connects it to `get_tree().quit()` before the smoke's own listener), the result file is written at that moment, and the program must end by itself. Three seconds of frames later and still running adds a FAIL step; the runner also fails a run it had to stop at the time limit, and `readResult` fails a result with no "the game is told to close" step (selftest: one row added, 10 checks before and 11 with it, 0 failed).
- **Proved both ways:** with the quit hook cut out of main.gd (scratch copy) the smoke FAILs: "the program closes within three seconds of 'Close the game' (still running after 180 frames)". With the hook in: **solo 24 steps, 0 failed; two people 24 steps, 0 failed**, both records `checked: pass`, commit 65768887 (`runs/`).
- Two things I met: the pause card's focus does not wrap (Down on the last row stays), so the smoke walks Down then Up; and in solo the pad press makes the pad join as player two (the pause card then shows "Player two: hand back to the computer"), which is what a real pad-only player does too.
- New runner switch `--commit <id>` stamps a tree that is not a git checkout (a scratch copy), which is why the old records said "unknown". docs/tools/mode-smoke.md has the update.

## 2. The old records

The two results in the s04-report-where park's runs/ (commit "unknown") are moved to `docs/ui/runs/b0e20f9a/mode-smoke/` with commit b0e20f9a and a `tree` note (b0e20f9a with the s04 patch applied, landed as 0da7b774). The s04 park folder no longer has a runs/ folder.

## 3. "Saved by a different version" now has a reader: `replay-refusal-line.patch` (sha1 2685aa46ef73; UI files only)

- **Why it was unread:** no screen in the game plays a saved match. "Save this match" writes a file; replaying it is done by tools (the LAN save's replayState, the page's black box, replay_xproc_check). So there is no refusal to show *inside the HUD* today, and I did not invent a screen for it.
- **What it adds:** `UiFeedback.replay_refusal(reason, saved_build) -> String`, the one place the words are made, ready for the host that opens a saved match (Simulation or Netcode, through the EP): `UiFeedback.replay_refusal(SimReplay.refusal(rp), String(rp.get("build", "")))`. Only the "build" reason has UI's words; "format" and "data" give "" (the host's). Three sentences in terms.json (words for Orb to see):
  - with a build and its date: "This replay was saved by a different version of the game (build 1a93a305, 21 November 2026), so it can't be played in this one." (the sentence that was already there, now filled in words)
  - build, no date: "This replay was saved by a different version of the game (build 1a93a305), so it can't be played in this one." (new)
  - a file from a build with no stamp: "This replay was saved by a different version of the game, so it can't be played in this one." (new; never "unknown")
- hud_check: 4 new rows (`_replay_refusal_rules`), one against the sim's own refusal of another build's header (`SimReplay.refusal` answers "build"). strings.md and the pseudo locale regenerated.

## Gates (copy of main 65768887 with both patches)

- full hud_check: **8545 checks, 0 failed** (8540 on the earlier copy, b0e20f9a; four of the difference are the new rows, the rest is what main added since)
- mode smoke solo and two: 24 steps, 0 failed each; negative run FAILs as it should; runner selftest 11 checks, 0 failed
- Apply order: independent; `git apply` each on main 65768887 (both checked clean).
