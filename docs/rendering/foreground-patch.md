# The foreground row's patch (2026-10-11)

Owner: Rendering and Technical Art. Built to Orb's ruling of 2026-10-11 on the foreground row (row 0): "try option 1, the larger see-through patch first, as the patch needs to become bigger to accomodate more missing action allow a hybrid approach where the building also shrinks, I'd need to see it in motion to appreciate though". Render only: it reads the sim and writes nothing to it. The gameplay hash is unchanged.

**Row 0 is still empty in the data** (World's flag), so the game as shipped draws none of this. It was built, checked and recorded with the flag switched on in a scratch copy of the data.

## To see it move

Open `docs/rendering/img/lanes/motion/index.html` in a browser (a local page, not committed: 671 frames beside it, 37 MB). It plays 11 seconds at the game's 60 ticks a second: a fight drifting east along a suburb street behind the foreground houses, then a launch at tick 420. Space pauses, the arrow keys step a tick, the slider scrubs, and there are half and quarter speeds.

## What is built

- **One patch for the whole action.** A dithered window through the foreground row, in each pane: both fighters at its ends, the street between them, and what is travelling (where each fighter will be 0.3 s ahead, so a rush, a launch and a zip are in it; a beam's stretch inside the view; a shot).
- **Its size round a fighter** is 2.2 of his heights, so the street under him and a height over his head show (`RenderLook.PATCH_BODY`). The old hole was 1.6.
- **A soft edge.** The dither thins out from 55% of the radius to its rim, where the old hole's edge is a narrow band (`PATCH_EDGE`). The dither is fixed to the screen: it does not crawl.
- **It follows the fight and does not breathe.** Each end follows its fighter. The reach past a fighter and the radius grow when asked, and shrink only when nothing has asked them to grow for 0.75 s (`PATCH_HOLD_S`, Camera's hold).
- **A patch left far behind is put on the fighters at once** (2026-10-12). When the whole patch as last drawn lies more than four half-widths of the view to one side of the camera (`PATCH_RESEAT`) and a fighter is in view, it is re-seated, as on a first frame. That is a pair moved under a camera that was already there: a seek, a tool's pose. Walked there by the area budget, the patch left the fight behind its buildings for seconds, and no tower opened. That far off none of the old patch is on the screen at any depth, so nothing seen is taken away. An end coming home across the screen (a fighter gone from view, a split's two panes joining) still walks.
- **It grows by area.** All of it together never turns more than 16,000 pixels in a tick at 1024 by 768 (`PATCH_AREA_TICK`), shared by what each part asks for. The frame analyser's area threshold is 21,824.
- **The hybrid.** A patch larger than 40 square fighter heights (about 9% of the screen at fight framing) lowers the buildings it covers; at 70 (about 15%) they are stubs (`PATCH_BIG`). A building counts as under the patch by the share of its face the patch covers (`PATCH_UNDER`). It sinks over 0.45 s and stands again over 0.8 s, and none stands again until 0.75 s after the last one sank.
- **So:** a small skirmish is a window (two fighters 180 units apart are 24 square heights); a fighter knocked ten body lengths away is a lowered building.
- **The rows behind are as they were:** each fighter's own hole, or stubs, by the pane's method. Camera's `cutaway` request still applies: `request` false switches the patch off with the rest, and `only` makes it one fighter's.

## What I see in the clip

- **The window reads.** A foreground house in front of the fight opens round both fighters with a soft stippled edge, and the street and the houses behind show through it.
- **A foreground house is low, so the window takes nearly all of it.** Suburb houses in row 0 are 154 to 270 units tall and the window is 330 tall on the plane. Inside the patch's width nothing of the house is left; what stands is its two sides. It reads less as "a building with a window" than as "a building parted round the fight". A smaller radius (1.4 heights) would leave the top of the wall and the roof line across the window; it is one constant.
- **After the launch** the window widens toward the launched fighter over about a fifth of a second, and the house it now covers sinks to a stub.
- **The foreground crowd stands in front of the patch.** Row 0's own figures are close to the camera and drawn large, in front of the fight. That is World's and Art's (the crowd is being thinned).
- **The foreground row itself costs flashes.** See the measurements.

## Measured

- **Growth, headless** (`patch_check`): a fighter moved 760 units off at once is reached in 13 ticks, the patch growing at most 9,358 pixels a tick.
- **Growth, web, the camera frozen at fight framing:** a fighter moved 420 units off; at most 2,316 pixels turn brighter, or darker, in a tick.
- **The street scene** (the clip, 780 ticks at 1024 by 768, Tools' frame analyser): 2.5 flashes in the worst second with the patch, and 2.5 with the plain hole on the same scene. It passes at the gate with nothing to spare, either way.
- **Why 2.5:** the foreground houses themselves. Each one sliding into view is a pale wall over half the screen, a counted change as it comes and as it goes, and the launch adds four changes in eleven ticks (the camera's pull-back, VFX's glass and debris). The patch adds and removes about as many as it changes: 14 counted changes in the clip against 13.

## What I need from Camera

Camera's paper (`docs/camera/city-in-depth.md`) says row 0 always opens by stubs. Orb's ruling replaces that: the patch is the method and stubs come only from the hybrid. From Camera:

1. **A cut flag a pane.** On a cut (a cut-in, a transformation's break, a safety cut) the patch and the stubs must jump to their targets, not ease across it. Today I snap only when a pane was not drawn for half a second, or when a tool asks. `frame.cut[i]` would do.
2. **The hold.** I use 0.75 s, the paper's number. Say if the camera will publish its own clock for it.
3. **How far ahead.** I reach 0.3 s ahead of a fighter, at most 900 units. The paper widens its band by speed times 0.5 s.
4. **The follow after a launch.** A fighter launched faster than the patch grows is hidden behind the row for a few ticks. A slower pull-back, or a cut to a wide frame, would hide that.
5. **The framing with a foreground row.** At fight framing the row covers the lower half of the screen, so every house that scrolls past is a large change. A slower scroll, or a frame that sits a little higher, would cost fewer.
6. **The close framing.** At the zoom cap a fighter is 86 pixels tall and the patch is nearly 380 across: most of the screen. Say whether row 0 should simply be lowered at that zoom.

## Checks

- `render/tools/patch_check.gd` (headless, 5 checks): no patch and nothing lowered with the data as it is; a small skirmish behind a foreground house has one patch holding both fighters, with the rule's radius, and the house stands whole; a fighter suddenly far away is reached within the area budget and the house under the big patch sinks no faster than allowed; a reach asked for and dropped is held before it shrinks; the fight small again, the house holds, then stands. The tool moves a house into the foreground in its own state.
- Passing on an export of 991bbb1d with this change: determinism (plain and `--intro`), seam sweep, pane, stage, lane, sky, flash register, hud words, after, shape, patch.
- **`ground_check` fails on HEAD without this change** (13 failures in two seeds since the brawl's last tune changed how the matches play: the ground field kept up to date differs from one rebuilt from state in its crater list). It is Rendering's own and is not from this work.

## Limits

- Seen with suburb houses only. The harbour's foreground has a crane 450 units tall; it has not been looked at.
- The patch is one capsule. An action with three far-apart parts (two fighters and a beam leaving at an angle) is covered by a wider capsule, not a second window.
- Trees, rubble heaps and props in front of a fighter are still not opened.
- Cost is not measured. It is a few dozen projections a frame while a big patch covers buildings, and nothing when there is no foreground row.
