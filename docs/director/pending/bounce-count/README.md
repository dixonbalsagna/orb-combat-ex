# Parked: Orb's ping-pong bug, counted (the GW1b review's B-19)

Encounter, 2026-11-21. Orb's ping-pong bug is the bounce off the building: a wall throws him back toward the strip and pulls his depth home through the air. `sim/director/tools/bounce_count.gd` counts it in ordinary play. It's the evidence for Orb's private build, which tries the lodge first.

## The counts

Computer against computer, 30 matches each, on Orb's 9 November data (main b0e20f9a, GW1a), on the page's planet (7, touch 3, generation 3). A wall slam is a `building_hit` whose building holds the body (the text "wall").

| | Wall slams | **Thrown back off the face** | Pulled home through the air | Slams more than 20° off the blow's line |
| :--- | ---: | ---: | ---: | ---: |
| **Today** | 23 (0.77 a match) | **22** (0.73 a match) | 21 | 14 |
| **The lodge** (`cityHold` + the hold-air grant) | 21 (0.70) | **0** | 0 | 15 |
| **The cones** (wall-cone + launch-cone, with gw1b-riders and index-stage under them) | 13 (0.43) | **13** (0.43) | 11 | 3 |
| **Both** | 14 (0.47) | **0** | 0 | 4 |

**What it says:**
- **Only the lodge stops the bounce.** With it, no slam in 35 throws anyone back or pulls him home through the air.
- **The cones make walls rarer and mostly in front.** Slams fall from 23 to 13, and off-line ones from 14 to 3. But every slam that's left still bounces: 13 of 13.
- **Together** there's no bounce, and slams come about once every two matches, mostly ahead of the blow.
- A few slams still count as off the line with the cones (3 and 4). The count measures from where the launch began, and a flight can meet a wall it wasn't aimed at.

## The check

- One row, with `--lodge`: "nobody thrown back off a wall". It passes with `cityHold`'s values alone.
- The air pull needs the hold-air grant too: `../wall-hold-air/`, World's `stepZ` line.
- Without `--lodge` it only counts. It's a new file, and it runs on main as it is.
- `godot --headless --path . --script res://sim/director/tools/bounce_count.gd -- [--matches=30] [--ticks=18000] [--lodge]`
- Records are in `docs/director/runs/b0e20f9a/b19-bounce/`, gated, no script error.

| Patch | Owner | sha1 |
| :--- | :--- | :--- |
| `bounce-count.diff` (the new `sim/director/tools/bounce_count.gd`) | Encounter | a7eb64f3395d193712c1b36d74038551bb559409 |

## NEEDS FROM EP

- **For Orb's private build:** the lodge (`cityHold`'s row and `../wall-hold-air/`) removes the bounce outright. The cones only make it rarer.
