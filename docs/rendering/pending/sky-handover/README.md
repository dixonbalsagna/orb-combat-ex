# Park: the sky goes with the camera when the split panes open and join (Rendering, 2026-11-26)

This is from Camera's split plan, Orb's "the panes join abruptly". The EP's word: it lands after GW1c, when ready.

## The file

| File | What |
|---|---|
| `sky_handover.diff` (sha1 b867f87a40d7, 61 lines) | Changes `render/core/pane_world.gd` and `render/core/main.gd`. It applies strict on main (checked on 15b6f275 and 312c323f). It also applies on the 29-piece GW1c tree, after tile-marks, and after UI's pad-recommended, howto-licence and menu-sounds and Camera's split-line park and its main.gd grant. |

## What it does

Each pane kept its own eased sky. In `PaneWorld._sky_st`, the sky's phase slews toward the target set by the pane's own camera x.

The second pane is drawn only in a split, so its sky state went stale between splits:
- **On the opening,** it snapped to its own target (`SkyDrive.pane`'s fresh path: more than 0.5 s since its last step).
- **On the join,** its half of the screen dropped from its own sky to the first pane's in one frame. With the sky's colours carried into every material's haze, the whole half changed tint. On medium's collapse clip, the houses went from teal to pink at tick 105.

Now the sky goes with the camera:
- **Seeded from the lead.** The second pane's `sky_lead` is the first pane. When the second pane's state is stale, it starts from the lead's state, then slews toward its own target as before.
- **Blended toward its own.** Its colours, stars and star turn are the lead's blended toward its own by `sky_own`. `main.gd` sets `sky_own` to the smootherstep of `SplitFrame.sep`, the panes' own blend. At `sep` 0 the second pane's sky is the lead's exactly. As the panes open it becomes the pane's own; as they close it comes back.
- **Untouched:** a pane with no lead (the first pane, the one view, the inset) works as before.

It only reads `SplitFrame.sep`, which Camera already provides; no Camera file changes. Nothing is written to the sim.

## Proof

**The collapse clip.** Worst of 4 readings (960x540 and 1024x768, scale 1 and 2), both modes, one run each (the reel repeats on the steady fill). All on the 29-piece final GW1c tree, without and with the park (`docs/rendering/runs/bc1e5558/sky-handover.txt`). Small and big are held on that tree, so they were reached through a scratch size word with World's test-only `heldOverride`.

| Case | Before (normal / reduced) | With the park |
|---|---|---|
| medium, collapse | 1 / 2 | 1 / 2 |
| medium, rushcity | 3.5 / 3.5 (areas 5, 4) | 3.5 / 3.5 (areas 4, 3.5) |
| small, collapse (Camera's merge case) | 2 / 3 (FAIL) | 2 / 2.5 (PASS) |
| big, collapse | 2 / 2 | 2 / 2 |

- No reading is worse.
- Small's reduced collapse passes the gate. The second pane's sky snapping back at the merge was part of the merge's flashing.
- Rushcity still fails as it does on main, an A2 item with Camera.

**Gates on the tree plus the park:**
- import 0, export clean;
- golden byte-identical to the tree without it;
- the five ground checks pass;
- the render gates: 20 of 20, flash, flashreg and splitsweep included.

**The look gate.** Side-by-sides, git-ignored, in `docs/rendering/img/sizes/sky-handover/`, from medium's collapse, reduced, every frame kept:
- **`join-1` (ticks 80 to 120).** Before, the right pane's lighter sky and teal haze give way to the dark sky and pink houses in one frame at the join, tick 105. After, the right pane carries the first pane's sky as the split closes, and nothing changes at the join.
- **`open-1` (ticks 20 to 60).** The opening looks nearly the same. The second pane's far haze starts in the first pane's tint and moves to its own.

The two runs differ only while the screen is split (ticks 1 to 9, 27 to 104 and 135 to 265 of that clip).

## Notes

- **A short split keeps one sky.** The second pane reaches its own sky only at the sky's slew rate, which is rate-limited so the sky never flashes. So in a short split both panes keep about the lead's sky, and the planet's day and night around it shows in long splits. That is the trade for a seamless join; the slew rate (`SkyDrive.slew`) is the knob if Art wants the panes to part faster.
- **Camera's merge itself is unchanged:** the panes' blend, the divider and the cut.
