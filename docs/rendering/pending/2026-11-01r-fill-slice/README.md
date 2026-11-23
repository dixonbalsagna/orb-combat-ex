# The fill's slice follows the frame's room

Parked by Rendering, 2026-11-01. `slice.diff` stacks on `2026-11-01q-coarse-first/coarse.diff`. Only with the tile ground's switch on.

**The fault.** A tile costs about 45 to 65 frames at the fixed 1.5 ms slice: roughly 70 to 100 ms of CPU a tile on the web build, measured on this machine at below-normal priority. Play runs on coarse ground as a result.

**The change.** The slice is 1.5 ms plus half the room under a 16.67 ms frame, by the frame time smoothed over a few frames, at most 6 ms: `RenderLook.TILE_FILL_TARGET_US`, `TILE_FILL_ROOM`, `TILE_FILL_MAX_US`. At or over the target it's 1.5 ms, as it always was, so the old laptop pays nothing new. It only spends while tiles are arriving. The urgent case keeps at least its old 4.5 ms.

**Cost on Performance's numbers. Arithmetic, not measured.** Orb's frame averaged 7.5 ms (91,574 frames in 688 s). If 6 ms of that is everything else, the slice settles at about 4.5 ms, the frame at about 10.5 ms (95 fps) while tiles arrive, and the fill runs about three times as fast. 44 level-1 tiles would take about 5 to 7 s, not 15 to 20. Orb's slow-frame cases are at or past the target already, so there the slice stays 1.5 ms.

**Not measured.** On a capture the frame time is long, so the slice stays at its least: no run here has exercised the higher slice. A 60 Hz monitor with vsync reads as no room however fast the machine, so it stays at 1.5 ms. Performance's replay bench is the check.

**Gates:** as `2026-11-01p-tile-pool`'s.
