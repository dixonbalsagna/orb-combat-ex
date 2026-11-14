# Parked: in normal play, a fast launch pulls wide to the readable size (launch-wide)

Camera, 2026-11-14, the EP's decision (c) on the clash reading: normal mode, lead wide on a fast send, eased. Option (b), following at 10 to 15 px, isn't built; it reverses director step 4a and would go to Orb only as a camera taste question.

**Apply after** launch-hold-reduced (it uses `_lh_on()`), on the GW1a look stack: `git -c core.autocrlf=false apply launch-wide.patch` (sha1 1ef4438b). It lands after GW1a.

| File | What |
| :--- | :--- |
| `render/camera/split_rig.gd` (mine) | `launch_wide`: a launched pane takes the launch governor with the readable floor (`READ_FAST`, 43 px at 720p), unless the launch rule holds it |
| `data/camera/swing.json` (mine, granted) | `pieces.launchWide`: true |
| `tools/schemas/camera-swing.schema.json` (Tools' grant) | the key |
| `render/core/main.gd` (Rendering's grant) | one line in the camera block |

## What it does

A launched fighter is chased at fight size (director step 4a). With this, when his flight would stream the scenery past faster than the governor's limit, his pane eases out (the governor's own ease, `GOV_TAU`). It goes no smaller than the readable size, so he stays readable. It's on in normal play; under Reduce flashing the launch rule's hold takes the fast flights first.

## Proof

| Run | Result |
| :--- | :--- |
| Clash, normal, the two flight stretches (native; `docs/camera/runs/611c1c2b/launch-parks/clash-steps.txt`) | ticks over 0.045: **93 to 80** and **57 to 39**. A partial fix, as expected: at about 20,000 units a second the readable floor binds |
| Every camera check, with this piece and launch-hold-reduced forced on (`gates.txt`) | all pass except split_sweep's two rally rows, which **tie**. A rally row checks that the rally framing beats the same run without it. This piece improves the run without it from 28 to 15 ticks of the chaser off the screen, the same 15 as with the rally framing. Not a regression; the rows' "beats" test would need "beats or ties" if both land |
| **The pixel reading** | **Owed:** in the EP's next quiet window, clash normal on the stack with both parks. If it can't get normal mode under the limit, (b) goes to Orb as a taste question with a side-by-side ("on a fast launch, follow close or pull wide"), never framed around flashing |
