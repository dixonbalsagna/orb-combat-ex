# Parked: the camera's slower pace under Reduce flashing (reduced-pace)

Camera, 2026-11-14, the EP's go: Reduce flashing is the tester-safety mode. Normal play stays exactly as Orb plays it: the normal-mode digest is identical on all 9 clips.

**Apply after** cd04, launch-hold-reduced and launch-wide, on the GW1a look stack: `git -c core.autocrlf=false apply reduced-pace.patch` (sha1 21591c0b). It lands after GW1a.

| File | What |
| :--- | :--- |
| `render/camera/split_rig.gd` (mine) | `_rpace(key)`: the three numbers, read only while Reduce flashing is on (and not under the motion setting, which has its own rules) |
| `render/camera/cam_places.gd` (mine) | `CamPlaces.reduced_pace(key)` |
| `data/camera/swing.json` (mine, granted) | `reducedPace`: enabled, openSec 0.9, catchUpMax 0.03, safeBox 0.3, zoomRate 0.6 |
| `tools/schemas/camera-swing.schema.json` (Tools' grant) | the object, closed, with each number's range |

## What it does (Reduce flashing only, all eased)

- **The split opening:** an ordinary opening takes `openSec` (0.9 s against 0.45). An urgent one keeps its speed, so nobody is lost: a fighter already off the view, or a chase.
- **A pane's catch-up:** while its fighter is within `safeBox` (0.3 of the width) of the pane's focus, the pane moves at most `catchUpMax` (0.03 of the width a tick). Past the box the allowance grows with the distance, so the hold gives way smoothly and never loses him.
- **The zoom coming in:** it changes at most `zoomRate` (0.6 e-folds a second; 2.4 otherwise). **Zooming out keeps its rate.** The first cut slowed both ways, and a slower pull-out lost an escaping fighter (split_sweep's escape 5000 reduced: the chaser outside the picture 79 of 180 ticks). The slam's door keeps its own rate.

## Proof (`docs/camera/runs/611c1c2b/reduced-pace/`)

| Run | Result |
| :--- | :--- |
| Every camera check on the full stack with this park | **all pass**, including split_sweep (escape rows) and cut_register_check 73 |
| Normal mode alone, clip_digest on all 9 clips, with and without | **identical** (24,300 frames) |
| The flagged seconds, reduced, natively (`native.txt`) | **little change.** Signature's right pane is a fighter flying freely at about 7,800 units a second, followed at his speed at the readable floor, so the hold rightly gives way. Collapse's last second is a pull-out keeping a parting pair in frame, which this park mustn't slow. Clash's first flight stretch: 31 to 26 ticks over 0.03 |

## What's left in those seconds

- **The camera's only remaining lever there** is under Reduce flashing: letting the governor take a fast free flier, or a pull-out, below the readable size (43 px), toward R_FLOOR's 23 px. That's a readability trade and the EP's call, so it isn't built.
- **Otherwise it's Rendering's:** the facade's brightness against the night sky and the tile ground's bands.
