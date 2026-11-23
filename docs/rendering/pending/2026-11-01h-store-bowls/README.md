# Craters are drawn on the tile ground

Parked by Rendering, 2026-11-01. `bowls.diff` stacks on `2026-11-01g-citizens-feet/cit.diff`. Only with the tile ground's switch on. View only: it reads World's store and never writes it.

**The fault.** A crater's hole wasn't drawn. On flat ground the sim's ground fell from 281 to 20 while the tile stayed at about 280 and the view's offset was about -2, so a fighter in a crater was drawn under the drawn ground: only heads showed.

**The cause.** On gen 3 a crater is a record in `WorldStore`, by planet direction, and not in `S.deform`. The tile ground never read the store.

**The change.**
- The 16 bowls nearest the camera go to the vertex stage (`tile_bowls`), using `WorldCrater.profile`'s bowl, rim and apron. They open over `RenderLook.TILE_BOWL_OPEN`, 0.25 s, and aren't faded.
- `RenderTileGround._bowls` reads only new store records each frame and chooses the nearest again every `TILE_BOWL_FRAMES` frames. A rollback that shortens the store starts the list again.
- The crater's slope goes into the ground's light, `ground_at` adds `WorldStore.heightDelta`, and cover in a crater goes by the store too.
- The water sheet's floor takes the bowls, so a bowl below the water's top floods.

**Seen:** `docs/rendering/img/lookgate/crater-look-off-on.png`, a real crater on flat ground and at a sea's edge; `crater-scar-frames.png`, tick 2401, the fighters in a real crater.

**Not drawn yet:**
- Scorch and trench grooves in the store: they're in the sim's ground and not in this. `heightDelta` includes them, so `ground_at` is a little lower than what's drawn there.
- More than 16 bowls near the camera: the farthest drop out when the choice is made again, with no ease.
- Far from the camera's own reach (level 0's distance) bowls still draw, if among the nearest 16.

**Known:** at a sea's edge a bright vertical line remains where the flooded sheet ends at a tile's edge (`crater-scar-frames.png`, top left).

**Cost:** up to three evaluations of up to 16 bowls per vertex while any bowl is near. **Not measured:** the frame bench needs a quiet window, and the PC isn't one.
