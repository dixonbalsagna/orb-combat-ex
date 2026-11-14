# Spike S5: the Linux build starts under a virtual display and draws its start menu (Tools, 2026-11-14)

Workflow: `.github/workflows/linux-still.yml`, dispatched by the EP at 08:18 UTC on 14 November 2026; **run 43575230848, success, about 2 minutes** on a GitHub runner (ubuntu-24.04, software GL under Xvfb).

## What the run did

Locked "Reduce flashing" on (the same one-word edit the desktop builds make), refused to continue unless the lock holds and no flag reaches normal mode, imported the project, wrote `build_info.json`, exported Linux (release, Compatibility, x86_64, pck embedded), installed Xvfb and the software GL it needs, started the game and, after 25 seconds, saved one still of the virtual screen. The job passes only if the game was still running at 25 s, the still is not empty and it holds more than 8 colours.

## The reading

- The game was still running after 25 s: **yes**.
- The still: **1280x720, 792 colours** (mean brightness 0.09: a dark menu, not a flat colour). I looked at it: it is the start menu, with the flashing notice at the top, the Players, Player 1 and Computer rows, the four option boxes, the button "I understand, start" and the line that Reduce flashing is on and cannot be turned off in this version. The picture is drawn in full, text and rows included, by the Compatibility renderer on software GL.
- The game's first lines: one warning, "Could not set V-Sync mode ... not supported by the graphics driver" (expected under Xvfb; it does not stop the game).
- The still and the game's first lines are kept as the artifact `linux-still` (one day; the binary is not kept).

## What this proves, and what it does not

- Proven: an exported Linux release build starts and draws its first screen without a real display, on a stock runner. A Linux gate that needs a window can use the same recipe.
- Not proven: any match played in that window (the mode smoke does that headless, `docs/tools/mode-smoke.md`), frame rate (software GL says nothing about a player's machine), audio, a controller, or a real Steam Deck.
- Flash and photosensitivity readings are not part of this still and go to the EP only.

## The refusal run of the desktop builds (same day)

**Run 43575987514, failure, as designed:** `desktop-builds.yml` stopped at its step "Refuse without Orb's recorded yes (Legal RL-203)" because `docs/ep/approvals/desktop-test-builds.txt` is not committed in the commit that was built. No export was made and no binary was kept. The job runs again when the approval file is committed with its date, scope ("desktop test builds") and `recorded-by:` line, and `ORBS_YES` names the same date. This is the refusal record for A-LEGAL-02.
