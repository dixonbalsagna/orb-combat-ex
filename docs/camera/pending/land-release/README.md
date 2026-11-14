# Parked: a hard landing counts as a release in the launch checks (land-release)

Camera, 2026-11-07, for the EP's `flight_shots_check` fail on main: close brawl, "a jolt of 0.237 of the width (tick 2048 pane 0: solo, launch follow, launched)".

**Apply on main** (cut on a8bc66e2; `git apply --check --cached` passes on 808a83ab): `git -c core.autocrlf=false apply land-release.patch` (sha1 e12e44b5).
- One file: `render/camera/tests/launch_shots_check.gd` (mine). A test only: no shipped code and no picture changes.
- It's independent of vkeep. With both applied: flight_shots_check 778, launch_shots_check 1,029, chase_rush_check 130, all pass.

## What happened

- `flight_shots_check` landed with the overnight batch (3c9005ac) and the close brawl has failed since then (3c9005ac fails the same way). It's an AI match, seed 12345, 3,600 ticks.
- At tick 2047 the launched fighter, flying at about 18,000 units a second, **hits the ground in a skid landing**: `land` (skid), with an impact, shake, ring and debris.
- He's held still for 4 ticks, then skids on. He stays `launched` throughout.
- The launch follow has the camera stepping 0.27 of the width a tick to keep him. It stops with him, and the step falls to 0.03: a jolt of 0.237.

## Why the fix is in the check

- **No eased stop can work.** Easing a camera moving 0.27 of the width a tick to rest within the jolt limit would carry it more than half a screen past him. The follow-through (on in Orb's build) adds its small overshoot, and the jolt is the same 0.237 with all of Orb's build switches on.
- **The check already has a rule for this.** A blow's release may start hard because the blow hides it (`RELEASE_TICKS`, limit 0.30). A hard landing is the same moment the other way round, hidden by its own shake and debris.
- The check finds a release only from a change of state (into or out of `launched`). A skid landing keeps him `launched`, so it was missed. Now a `land` event starts the release window too.

## Proof

| Run | Result |
| :--- | :--- |
| `flight_shots_check` | 778 passed (main: 1 of 521 fails). The close brawl's jolt is now 0.048. The landing reads as a release, under the 0.30 limit with the match's other releases (largest 0.277) |
| `launch_shots_check` | 1,029 passed. More checks than before (635): each release tick also checks its zoom jolt (0.03), and they all pass |
| With vkeep too | flight_shots_check 778, launch_shots_check 1,029, chase_rush_check 130: all pass |

## RISKS

- A `land` event from either body opens the window, for 10 ticks. A jolt that's really the camera's own fault inside those 10 ticks is held to 0.30 instead of 0.06 (and to 0.16 in the close brawl). The zoom's own jolt is still held to 0.03 there.
