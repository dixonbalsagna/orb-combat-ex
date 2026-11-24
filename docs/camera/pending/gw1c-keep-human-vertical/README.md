# Parked: the one view keeps the human in frame up and down too (gw1c-keep-human-vertical)

Camera, 2026-11-23, the EP's go: the GW1c full gate's red `own_pane_check` (launchai, both modes). It joins GW1c, since GW1c's fight exposes it. Cut on main db200187. Records: `docs/camera/runs/db200187/gw1c-keep-human-vertical/proof.txt` and `docs/camera/runs/8e7d81d9/gw1c-own-pane/trace.txt` (the cause).

**Apply on main or the GW1c stack** (the stack touches no camera file): `git -c core.autocrlf=false apply gw1c-keep-human-vertical.patch` (sha1 5bf38d00, 62 lines). Two files, mine: `render/camera/split_rig.gd`, `render/camera/camera_params.gd`. It applies before or after `../gw1c-door-holds/`.

## The cause: a camera gap, not staging

In launchai on the GW1c stack, a lock breaks at 2993 with the one view close in (zoom 1.55). Fighter 1 flies up and player one drops.

- **The drawn zoom lags.** It eases out at the comfort rate, so it stays tighter than the aimed zoom (at 3003, drawn 1.35 against aimed 1.27). Player one's chest is 6 to 15 px under the bottom of the 720-px frame for 16 ticks, against a limit of 15. The aimed picture held him.
- **The rule that should catch this only pushes sideways.** For exactly this lag, the one view aims for its one human (`keep_human`, `KEEP_HUMAN_IN` of the width inside the frame), but only across. He left through the bottom.
- **Why only GW1c shows it.** The stack's new fight timeline (craters and grooves on the planet) reaches this vertical split; main's doesn't. World's bury fix may move the moment again, but not the gap.

## The change

The same push, up and down: his chest is kept `KEEP_HUMAN_IN_Y` (0.05) of the height inside the top and bottom of the frame at the drawn zoom. It is taken in as the zoom mismatch grows (2% to 15%), as the push across is, so nothing pops. It applies only in the one view, only with one human, and only while the drawn zoom lags. The switch is `keep_human_v` (on).

## Proof (on the GW1c stack, against the same tree without it)

- `own_pane_check`: **12 checks passed**. Launchai's player one is out of frame for at most 2 ticks (3003 to 3004), down from 16; every other row reads as before.
- Every camera check and split_sweep pass; the golden is unchanged (same hash).
- The medium collapse clip, worst of 4: reduced PASS 2 / 2 / 1.5, normal PASS 1 / 1 / 1, the same as without it.
- The launchai moment, captured (ticks 2951 to 3050, 1280x720): reads PASS 0.5 both ways.
  - Side-by-side `launchai-keep-human` in `docs/camera/img/default-view-stack/gw1c-keep-human/` (ignored: fighters). Frame N is tick 2950 + N.
  - At frame 58 the base has player one cut off at the bottom edge, only his marker and head showing; the fix shows him whole, the camera eased down a little. No cut, no fade.
