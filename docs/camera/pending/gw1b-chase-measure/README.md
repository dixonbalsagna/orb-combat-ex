# Parked: chase_rush reads the chase as it's drawn (gw1b-chase-measure)

Camera, 2026-11-15, the EP's GW1b list, item 1. **The player wasn't lost for 96 ticks, and the view didn't flap.** Both were chase_rush_check's own reading. A check fix only: no camera code changes.

**Apply after gw1a-pins** (cut on main 6b7e0ca9 + own-pane + gw1a-pins): `git -c core.autocrlf=false apply gw1b-chase-measure.patch` (sha1 4d8ea6de). One file, mine: `render/camera/tests/chase_rush_check.gd`.

## What the trace showed (`docs/camera/runs/6b7e0ca9/gw1b-chase-measure/trace.txt`)

- **The 96-tick "loss".** With the 9 November data the chase goes into depth: the player is 2,300 to 2,800 units deep (`z`). The rig aims his pane through the perspective, so he's drawn at his anchor, about (410, 445), throughout. The check measured his screen position **without his depth** and put him 700 px off the left edge. Measured with his depth (`screen_pos(..., z)`, as own_pane_check reads it), the worst run is 6 ticks, inside the 15-tick limit.
- **The flaps.** The check's rule is "one picture for under 30 ticks *between two splits*", but it counted any opening within 30 ticks of the row's start, with no split before it. Orb's faster sends open the split sooner, so every "merged, opening, split" read as a flap. Now a flap needs a split before the short one view.
- **Negative control:** with World's biome data put back to main's, the chases really do flap (split, closing, merged, opening), and the new count still fails them (6 rows).

## What's left, and real

The ceilings come down to the steps:

| Rows | Ceiling | Limit | What |
| :--- | :--- | :--- | :--- |
| the meteor chases at top power (4 rows) | step 0.065, jolt 0.036 | 0.06, 0.03 | marginal |
| the ordinary sends at top power (3 rows) | step 0.289 and 0.263 | 0.25 | the urgent split opening (ticks 71 to 78) while the chaser rushes 150 to 340 units a tick: his pane blends from the shared view to his own anchor, and that sweeps him about 1,000 px across the screen in six ticks. **Real, and the next fix** |

## Proof (`runs.txt`)

| Run | Result |
| :--- | :--- |
| The stack (s422 + own-pane + gw1a-pins + this) | chase_rush 130 pass, 7 rows on the ceilings above (was 11, with "off 96" and 7 flaps) |
| The same tree with main's data | 130 pass |
