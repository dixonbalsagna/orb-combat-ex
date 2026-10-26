# The split's culling (Rendering, 2026-10-23)

Performance found the integrated GPU's remaining slow stretches in the city-beam scene are the split screen. Each split pane is a full-size SubViewport drawing the whole world, though only its side of the divider shows, so the ground was drawn about 1.6 times (205,000 to 211,000 triangles against 132,000 in one view).

## What it does

Each pane leaves out of its own draw the ground's and water's chunks that lie wholly on the hidden side of its divider (`render/core/planet_view.gd` `cull_to`, from `PaneWorld.render` each frame):
- **The visible region is Camera's.** `SplitFrame.visible_half_plane(i)` (Camera's `pane-visible-half-plane.patch`) gives a half-plane on the screen: a point p can show in pane i only if n.p >= d. Camera widens it by the divider's feather, half its line, the largest shake and a margin, and `split_sweep` checks it.
- **A line on the screen is a plane through the camera.** The pane builds that plane once a frame from two of its camera's rays (`_view_plane`). A point in front of the camera is on the plane's hidden side exactly when its picture is on the screen line's hidden side.
- **A chunk is left out only when all of it is on the hidden side.** The test is its box (the mesh's own, which the shaders' heights stay inside), widened downward by the most the planet's bend can lower anything in it (`_side`, with `RenderMats.bend_params`). A terrain chunk and the water chunk of the same mesh are tested as one box. A copy that is wholly on one side is settled by its own box first.
- **Left out means its render layers are cleared** (a pane's copies are its own nodes). `visible` stays the planet's own (the water's chunks show only where there is water), and nothing else changes.
- **On by default** (`RenderLook.SPLIT_CULL_ON`). Main's `--nocull` (`?nocull=1`) turns it off for an A/B. With one view, an inset or a pane that fills the screen, nothing is left out.
- **Props are not culled.** A copy's buildings, trees and crowd are each one MultiMesh over the copy's whole length, so they are hardly ever wholly on one side.

## Checked

- **Nothing that shows is lost:**
  - a native probe projects every corner of every left-out box (bent as the shader bends it) through the pane's camera every tenth frame; 0 of them land where the pane can show, over 600 frames of the city-beam scene;
  - web frames are pixel-identical with it on and off: the AI match at 30 ticks from 120 to 7,200, and the city-beam scene (split the whole time) at 67 ticks from 2 to 400.
- **What it saves** (the same probe): in the city-beam scene pane 0 leaves out 52% of the ground's and water's triangles it held, pane 1 44%.
- **What it costs:** 0.175 ms a pane a frame natively (a first version cost 0.54 ms; the boxes are now packed and the test inline).
- **Gates:** the 19 render gates and `split_sweep` pass.
- **Performance's Radeon numbers** on the city-beam scene: asked for, on this park.
