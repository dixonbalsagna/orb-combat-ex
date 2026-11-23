# The bowls open by the render's clock (feet in the ground at the start)

Parked by Rendering on 2026-11-07, from Orb's morning look ("feet sinking into the ground at the start", homework/Files/orb-shots-1107/, shot 1), on World's measurement (`docs/world/orb-looks-1107.md`, look 1). `crater_clock.diff` (sha1 fe775383, 50 lines, cut on main e0d33c4d and the same on e1397e5c) touches `render/core/tile_ground.gd` only. Render only, and only on the tile ground. No sim change, no hash change. **Land it with `fore-profile`:** each alone leaves covered feet (see fore-profile's table).

## The fault (World's)

The opening is a first-meteor landing: one impact crater under each fighter, live store records, so the sim's ground under him is dug at once, 43 units down. But the match clock `S.T` stands at 0 through the whole opening, and the tile ground opened a bowl by `(cb_now - t) / TILE_BOWL_OPEN` with `cb_now = S.T`. So the bowl was never drawn while the fighters stood in it, and their legs were cut by flat ground.

## The change

- `RenderTileGround._clock` is the render's own clock: the host's ticks, in seconds, interpolated. It runs through the opening, and `cb_now` is set from it every frame.
- A bowl opens over `TILE_BOWL_OPEN` from when the render first saw it (`made`, in place of the record's sim time). If the sim's clock ran since the dig (a pane that came late), the record's own age is taken off. A record already there when the list starts (a new match, or a rollback that shortened the store) is open at once.
- The 0.25 s opening itself is unchanged. For those 15 frames after a landing, the ground drawn under a fighter standing in a new crater is above his feet, as it was by design (store-bowls). That's the "10 and 11 frames" below.

## Proof

**Orb's 12:29 play's start,** headless through the game's own main with the tile ground, 2000×1125, on a8bc66e2 with the kept build's sim and data (`tile_ground.gd` is the same on a8bc66e2 and main). For each fighter standing on the ground, I compared the ground drawn under his feet, with the bowls read from the tile material itself (`cb_n`, `cb_a`, `cb_b`, `cb_now`, `cb_open`, opening included), against his feet. Output: `docs/rendering/runs/a8bc66e2/crater-clock-probe.txt`.

| | main | this park |
|---|---|---|
| standing frames (F0, F1) | 294, 333 | 294, 333 |
| frames the drawn ground stood over 10 units above his feet | 208, 270 | 10, 11 (each landing's 0.25 s opening) |

**Gates on main e0d33c4d:** `docs/rendering/runs/e0d33c4d/crater-clock-gates.txt`. It imports clean, `golden.json` is byte-identical, the tile, lake water, cover water, sweep and ground checks pass, and the render gates pass 20 of 20. The stack's gates (with fore-profile and crater-store): `docs/rendering/runs/e1397e5c/sunday-stack.txt`.

**The look:** Orb's replay played by Tools' black box clip (`tools/preview/blackbox-clip.mjs`) on two builds of his tree (as built, and with this park). Uncommitted stills from Orb's private black box:
- `docs/rendering/img/lookgate/crater-clock-orb-tick220.png` and `-crop.png`: the landing's crater, flat on main, drawn with the park.
- `crater-clock-orb-opening.gif`: ticks 20 to 320.

The clip's camera is wider than Orb's (960×540, a tick a frame), so the fighters are small and the cut legs barely show on main in it.

## Stacking

`crater-store` (parked earlier) edits the line after `cb_now`. Re-cut it on top of this park: its `bowl_new` reads `cb_now` and the bowls' `made`, so it follows this clock as it is.
