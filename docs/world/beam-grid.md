# A beam that plays is sampled once at each point, not at its front every tick (World, 2026-11-02)

Camera's beamduel (seed 12345, the shooter 200 up, the rival 750 east): a building beside the shooter fell before the struggle began. Found in `docs/world/struggle-meeting-point.md`; this is the fix, **granted by the EP in Encounter's `sim/director/beam.gd`** (`beamStep`, three lines).

**The cause.** `beamStep` samples a beam from where it was last tick to where it is now, every 36 x WS (288) units, starting *at* its old front. A beam that plays (`DirBeamPlay`, `beamPlays.enabled` true in the shipped data) crawls to its target: 20 ticks in the data, 36 to 60 with the fronts on, so at 750 units it moves 18 to 37 units a tick. Each tick then sampled the ground at its front, and every sample is a `damageArea` disc of (26 + 8 P) x 8 = 272 units: the ground by the shooter's hand was hit about 15 times (the old 0.22 s beam, 320 units a tick, hit it once or twice), including a building behind him.

**The fix.** For a beam that plays (`tv > 0`), start the sampling at the next point of the fixed 288-unit grid (`ceil(s0 / 288) x 288`), so each point is sampled once, whatever the speed. A beam that does not play, a fork or a swatted beam (`tv` 0) is sampled as before. `DirBeam.gridOff` is a tests-only switch to the old behaviour.

**Before and after** (`BEAMGRID`: planet 7, seed 12345; 10 front-street buildings, the shooter 200 up beside each on both sides, 750 east, the beam crosses unanswered for 70 ticks):

| | Before | With the grid |
| :--- | ---: | ---: |
| hp lost by buildings within 900 units of the shooter | 21,482 | 11,281 (down 47%) |
| of them brought down (20 stagings) | 22 | 2 |
| hp lost along the whole path | 48,008 | 35,260 (down 27%) |

The beam still carves its whole path; the buildings by the shooter take about half what they did, and the ones that fell almost all stand.

**Proof.** `BEAMGRID` 0 failed: the grid takes at least a fifth less near the shooter and no more fall; the path is still carved; with `beamPlays` off one hash both ways; the same run twice one hash. `frame_check` 203 passed on the fixed tree. Stacks on `clash-end` (its beam.gd hunk and this one apply in either order).

**It moves hashes.** Every match with a signature beam: the shipped data plays beams, so **the golden's 9 matches and 1 of its 2 replays move** (parity on the fixed tree: "golden check FAILED" as it must; on HEAD it passes). The golden is Simulation's (`sim/core/test/golden.json`): regenerate it at landing with `sim/core/tools/golden.gd`, in the same commit (sim/README.md, "Golden hashes"). Replays recorded before it do not reproduce past a beam.
