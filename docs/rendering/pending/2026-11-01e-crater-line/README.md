# The foreground drops for a fight in a crater

Parked by Rendering, 2026-11-01. `crater.diff` stacks on `2026-11-01d-building-band/band.diff`. Only with the tile ground's switch on.

**The fault.** A fight down in a crater showed only the fighters' heads over a grey foreground (planet 7, seed 12345, ticks 2401 and 2461).

**The cause.** The foreground rule's sight lines end on the line's ground (`_profile`), and that read the tile's height. The sim's ground there was 395 and the tile's 544. On gen 3 a crater isn't in `S.deform`, so reading `S.deform` changed nothing, which I tried first.

**The change.** The sight line ends on the lower of the tile and `WorldTerrain.groundY`, and on 0 over the sea as before. The view only reads the sim.

**Gates:** as the band diff's, run on both together.

**Cost not measured:** 64 ground reads a frame. The frame bench waits for a quiet window.
