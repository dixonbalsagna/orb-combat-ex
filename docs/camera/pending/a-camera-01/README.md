# Parked: the camera Orb played on 9 November, as main's data (A-CAMERA-01)

Camera, 2026-11-14, sprint A1 wave 2 (GW1a, fifth in its order: after the round planet, before the look).

**Apply on main** (cut on 51b840f5; `git apply --check --cached` passes on 781a82ac): `git -c core.autocrlf=false apply a-camera-01.patch` (sha1 b3e7cb5a).

| File | Owner | What |
| :--- | :--- | :--- |
| `render/camera/cam_places.gd` | Camera | `CamPlaces.piece(key)` and `flat_mode()`, read from the data |
| `data/camera/swing.json` | grant | splitShare 0.0 to 0.7; new `pieces` (the seven on/off pieces) and `flatMode` "wide" |
| `tools/schemas/camera-swing.schema.json` | grant | the two new keys (closed, as before) |
| `render/core/main.gd` | grant (Rendering's) | the block at 243-252 reads the data instead of the tile-ground start word |

- The two-fighter ratchet is unchanged (365).
- `node tools/validate.js`: 0 errors.
- The sim's state hash is unchanged: the camera reads the sim and never writes it.
- No new camera behaviour: this is the 9 November camera, made the default.

## The rows (acceptance 1)

The inventory's camera row, and the eight pieces that rode on `tiles`:

| Row | main before | 9 November builds (solo and LAN) | main with this park |
| :--- | :--- | :--- | :--- |
| splitShare (`data/camera/swing.json`; switches.mjs:60) | 0 | 0.7 | **0.7** |
| swing view | `tiles` only | on (`tiles=1` in both start lines) | **data on**, and needs the globe ground drawn |
| peak launch shot | `tiles` only | on | **data on**, and needs the globe ground drawn |
| launch director | `tiles` only | on | **on** |
| close brawl | `tiles` only | on | **on** |
| readable size | `tiles` only | on | **on** |
| follow-through | `tiles` only | on | **on** |
| flight reveal | `tiles` only | on | **on** |
| flat send's shot | "wide" with `tiles`, none without | "wide" (no `flat` word) | **"wide"** (`flat=` still chooses it) |

**Why the swing and the peak launch keep the globe condition:** the peak shot's widest view needs the globe ground (`docs/camera/swing-view.md`, point 2), and on the strip ground the swing has nothing to turn. With the globe ground drawn they're on from the data.
- Until Rendering's look (A-RENDER-01) makes the globe ground a plain start, a plain start runs six of the eight. After it, all eight.
- That's the one place acceptance 2 waits on another owner. It's written into the code comment and the data note.

## Proof (`docs/camera/runs/51b840f5/a-camera-01/`)

| Run | Result |
| :--- | :--- |
| **Every headless check under `render/camera/tests/`**, on main + the park | chase_rush 130, cross_ko 21, flight_shots 803, launch_shots 1,029, peak_retry 1, peak_shot 24, split_share 26, split_vision 11, swing_places 33, swing_real 48, swing_shot 164, swing_read 14,420, split_sweep: **all pass**. swing_fight skips ("DirSwing is off in this build": the director's swing row, not a camera one) |
| **The camera frame by frame** (clip_digest, the real main scene, 48,600 frames) | **A = B, byte-identical.** A is main as Orb's builds set it (`--tiles`, the 9 November `swing.json`). B is main + the park with the globe ground. Nothing moves differently. C (the park at a plain start, no globe ground) differs on every frame, because the ground and the globe framing differ, not only the camera |

**Checks on the old defaults, with their reasons:**
- **The rig's own code defaults stay off.** Every check that tests a piece sets it (chase_rush, flight_shots, launch_shots, peak_*, split_share, swing_*, cross_ko, "as main.gd sets the rig with tiles").
- **Three checks set none** (split_vision, swing_read, split_sweep). They test the base framing each piece is built on, one layer at a time.
- **Only main's start reads the data.** No check is pinned to main's old start.

## The look gate (acceptance 3): what's owed

- **The side-by-side against the 9 November build at the same ticks of one of Orb's saved play files can't run yet.** A save replays only on a build whose sim data matches (the replay's data hash, `sim/core/replay.gd:135`). Main's sim data differs from the 9 November build until GW1a's earlier groups land (pad, computer opponent, match-ending rules, round planet).
- **Once they have:** `tools/preview/blackbox-clip.mjs` on the 9 November kept build and on main + this park, the same save, the same ticks, stills and a short GIF, in a window the EP names. The file name goes in that report (A-RENDER-07).
- **Until then:** the frame-by-frame digest (A = B) is the proof that the camera is the 9 November one.

## For the EP: if Orb names the 9 November build the new reference (A-RENDER-11)

Camera faults in that build I'd list as "not part of the reference":
- **The flash safeguards:** the scroll limit under reduced motion or reduced flashing equalled the ordinary one (0.045), and most hard cuts asked the flash register nothing. Parked as A-CAMERA-02 (cd04).
- **An unflagged jump:** under the motion setting, a launch shot's landing snapped the picture up to 5.6 widths with no cut named. Fixed in the same park.
- **The single-view transformation shot:** it hides the other fighter for its 2.1 s, where a split's shot keeps him in a sliver. That's Orb's question through the stand-in, not a fault until Orb rules.
- **A 2v2 partner's fight:** it's never framed when near (the drawn case is off), and a KO'd player's PC cuts to his partner's fight without its own close-up (Netcode's switch timing; answered on 2026-11-07).
- **A check's blind spot, not a picture fault:** a fighter lost off the single view before the split opens (67 ticks in one real match before vkeep). launch_shots_check counted it only once the split was fully open. To close.

## A-RENDER-01: camera checks that never saw the globe ground

**None fails** on the park. The swing and peak checks run the globe through stand-ins (`CamPlaces.frame_source` and the others), not the drawn globe ground. Under the globe ground only clip_digest's main scene ran (A and B above).
- **One finding for Rendering**, not the camera's: with the tile ground on, `PlanetView._tile_foot_slice` (`render/core/planet_view.gd:1541`) logs "Out of bounds get index" (about 280 lines a digest run, on main too).

## NEEDS FROM EP

- **Grants:** `data/camera/swing.json`, `tools/schemas/camera-swing.schema.json`, and `render/core/main.gd` lines 243-252 (Rendering's).
- **Tools:** `tools/preview/switches.mjs`'s `splitShare` row (:60) has nothing left to switch once main's data is 0.7. Retire it, or keep it as a row that reads 0.7.
- **Netcode:** `net/tools/lan_kit.mjs:127,132`'s `--tiles=1` can go once the look (A-RENDER-01) makes the globe ground a plain start. Not before: it also turns that ground on.

## RISKS

- **A plain start before the look lands** runs the six pieces on the strip ground, a combination Orb didn't play. The checks run them that way (they use no drawn ground) and pass.
