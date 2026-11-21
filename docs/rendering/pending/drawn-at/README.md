# drawn_at: what the tile mesh draws, for Camera's drawn-ground sampler (for GW1c)

Rendering, 2026-11-20, at the EP's word. Camera found the camera's eye "under the ground" on medium for 200 to 1,000 ticks a clip, while the stills look right (`docs/camera/runs/d55c612f/opening-clear/sampler-findings.txt`). Its sampler read `height_at`, the tile field's bake, but the mesh draws that bake under the foreground rule (`tile_fore`), which lowers the ground in front of the fighter plane to the sight line from the lens. So the eye is never under the drawn ground there. The one thing the rule never lowers is the fight line's own ground.

`drawn_at.diff` (sha1 984e12f9) applies on HEAD 6bb03b08 and is cut against main's `tile_fore`. **If `fore-clamp/` (v4) lands first, this is re-cut to match it.** Run record: `docs/rendering/runs/6bb03b08/drawn-at.txt`.

## The change

All of it is in `render/core/tile_ground.gd`, on each pane's tile ground (the rule follows its pane's camera):
- **`drawn_at(d, y = NAN)`:** the ground drawn at planet direction `d`, meaning the field's ground (`height_at`), or the caller's `y`, under the rule.
- **`chart(d)` and `fore_at(y, p)`:** CPU twins of `tile_chart` and `tile_fore` (`render/shaders/tile_read.gdshaderinc`). They read the values this pane last gave its material: its frame, `fore_cam`, `plane_span`, `fore_drop` and the 64-point profile. A uniform the material doesn't hold reads as the shader's default.
- **Read only:** they write nothing, want no tile and start no fill.
- **Not included:** the strip rows' dent and a bowl, which the vertex stage also adds. Both only lower the ground, and Camera asks what can block.

New: `render/tools/drawn_check.gd` (+ `.uid`).

## For Camera

- **Main thread, render step only.** The field is null on the strip ground (`--notiles`).
- **`height_at` returns 0.0 where no tile is loaded,** so `drawn_at` does too. Treat it as unknown, not sea level. A `has_ground(d)` can follow if wanted.
- **What can block the view** is the line's own ground: depth 0 and behind it, which the rule doesn't touch. Small's frame-1 ridge stands on the line itself.

## Proof (`drawn_check.gd`; a gen 3 match through the game's main with the tile ground, 35 points round the pane's camera)

| Row | Result |
|---|---|
| twin: `drawn_at` against `tile_chart` + `tile_fore` transcribed from the shader's text, on the material's own uniforms (the profile as the float32 image the texture was made from) | ok, worst 0.0000 units (0.05 allowed) |
| behind: behind the fighter plane the ground is the field's | ok, 0 off |
| under: never above the field's ground | ok, 0 above |
| lowered: the rule acts on some points | ok, 3 of 35 (eye 3,106 at depth 1,171) |
| `--negative-control` (the eye read 200 higher) | the twin row FAILS, 40.0 off, as it must |

- The tile, lake water, cover water, sweep and ground checks pass. No import errors.
- **Limit:** headless Godot doesn't run the GPU's vertex stage. So "what the mesh draws" is proven as the shader's formula on the exact values the GPU is given, not as a read-back of drawn vertices.
