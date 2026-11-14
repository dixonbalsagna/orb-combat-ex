# Parked: the player always sees himself, counted from the split's first tick and in the real scenes (own-pane)

Camera, 2026-11-14, the EP's brief: close launch_shots_check's off-picture gap, with a negative control that catches as played's 60-tick loss. A check fix only: no camera code changes.

**Apply** (cut on 3070ef10; nothing in render/camera, data/camera or the flash scenes has changed since the test trees' 69eb6f32): `git -c core.autocrlf=false apply own-pane.patch` (sha1 843c1401). **It lands with or after A-CAMERA-01 (GW1a)**: on main without it, the new check fails, and that failure is the negative control.

| File | What |
| :--- | :--- |
| `render/camera/tests/launch_shots_check.gd` (mine) | the "off his pane" rule now also counts in the one view and through the split's opening: before the split is fully open he must be in some drawn picture. It used to count nothing until the split was fully open. The fully open rule is unchanged |
| `render/camera/tests/own_pane_check.gd` (mine, new) | the same rule in the real scenes: clash, signature and launchai through the main scene (as clip_digest plays them), with Reduce flashing on (the default view) and off. It fails when a fighter is out of his pane for more than 15 ticks (launch_shots' limit) |
| `.github/workflows/ci.yml` (`grant-ci.patch`, sha1 63232e23; not mine) | one step after the launch shots check, which runs the new check |

## Why a new check, not only a new rule

The new rule leaves launch_shots green on as played and on the GW1a camera (1,029 checks each), because its rows are staged sends and none of them reproduces the scenes' launches. As played's loss is in a fully open split (clash, ticks 179 to 241: the old rule would have counted it if any row had played that launch). Also, launch_shots runs only with Reduce flashing off, so it could never see launch-hold-reduced. own_pane_check plays the scenes in both modes.

## Proof (`docs/camera/runs/69eb6f32/own-pane/`)

| Tree | own_pane_check |
| :--- | :--- |
| As played (main + Rendering's globe-default, crater-look-default, foot-slice + VFX's meteor-default) | **fails 4 (the negative control):** clash, P1 out of his pane for **63 ticks (179 to 241)**, both modes; signature, P2 27 ticks |
| The GW1a camera (+ a-camera-01 + cd04) | **passes, 12 checks**, the same numbers on a second run |
| + launch-hold-reduced | fails 2: clash reduced, P1 out 99 ticks (156 to 254); launchai reduced, P1 out 141 ticks (824 to 964) |
| The whole reduced stack | fails 4: the hold's two, and signature reduced P2 41 ticks, launchai reduced P2 44 ticks |
| The stack with the hold off (pull wide) | fails 3: clash reduced P1 36 ticks, signature reduced P2 41, launchai reduced P2 44 |

So in the default view, launch-wide, reduced-pace and reduced-floor make the second fighter's loss after a send worse (25 to 41 ticks, 35 to 44), on top of the hold. That's another reason to keep them held.

## Known losses, pinned as ceilings (`KNOWN` in the check)

The GW1a camera already has three losses over 15 ticks, in both modes. They're pinned at today's values, so they may only come down. A fix is owed for each, after GW1a:

| Scene, fighter | Ticks | What |
| :--- | :--- | :--- |
| clash, P2 | 52 | the beam lock's one view on P1, with P2 off screen while the split opens |
| signature, P2 | 25 | after the beam sends him, at the divider's edge of his pane |
| launchai, P2 | 35 | after a blow sends him, at the divider's edge of his pane |
