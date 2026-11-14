# Parked: the one view aims for its human when the drawn zoom lags (gw1b-keep-human)

Camera, 2026-11-15, the EP's GW1b list: the signature scene's own-pane losses.

**Apply after gw1b-scape-side and gw1a-pins** (cut on main 5cef4af7 + own-pane + gw1a-pins + gw1b-scape-side's `split_rig.gd`): `git -c core.autocrlf=false apply gw1b-keep-human.patch` (sha1 1cef7de7). Three files, mine.

| File | What |
| :--- | :--- |
| `render/camera/split_rig.gd` | `keep_human`: in the one view, when the comfort limit holds the drawn zoom back from the view's own (2% to 15% mismatch), the view re-aims so the one human's chest stays `KEEP_HUMAN_IN` inside the frame. His position is projected with his depth and the pitch. With no human or two, nothing changes |
| `render/camera/camera_params.gd` | `KEEP_HUMAN_IN` 0.05 |
| `render/camera/tests/own_pane_check.gd` | `signature/0`'s ceiling (26) goes |

## What it was

With the 9 November data, the player's beam sends the computer flying. The one view could hold both at its target zoom, so the split didn't open. But the drawn zoom comes out at the comfort rate, so for 26 ticks both fighters slid past opposite edges, the player 36 px past the right one. The split panes already aimed for the drawn zoom; the one view didn't.

## Proof (`docs/camera/runs/5cef4af7/gw1b/runs.txt`)

- The signature scene: the player out of his picture **26 → 0 ticks** (normal); reduced reads 8, at the scene's first ticks.
- Every camera gate passes on the stack with this and gw1b-scape-side (14 checks, split_sweep and own_pane included).
- clip_digest in the default view: only rushcity changes (132 of 1,500 ticks, between 480 and 1231).

## Not this park

`signature/1` (48 ticks): the player is launched and the camera goes with him (the launch follow), and the computer leaves the one view about 25 ticks before the launch shot formally starts. Its ceiling stays.

**Stopped at quiet time.** Next step: the look gate. In a capture window, rushcity and the signature scene in the default view, before and after, both flash modes (with gw1b-scape-side's ai:106).
