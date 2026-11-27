# Park: the buildings' per-instance textures wrap, so software GL draws the city (Rendering, 2026-11-26)

The EP asked for this: the nightly runner's software rendering read collapse-reduced at 4 against the card's 1, because it drew no buildings (`docs/rendering/runs/d9bc2f07/flash-software.txt`).

## The file

| File | What |
|---|---|
| `building_swiftshader.diff` (sha1 af4facc3960d, 460 lines) | Changes `render/core/planet_view.gd`, `render/shaders/building.gdshader`, and the three checks that read the textures (`render/tools/open_check.gd`, `stage_check.gd`, `shape_check.gd`). It applies strict on main (checked on 6da8c6ec and the current working tree). It also applies with the whole queue: door-holds, cd04, sky-handover, feet-ground, marks-baked, rows-interp, fore-clamp, mats-tracked, and Simulation's size-host grant. |

## What was wrong

`building.gdshader` reads three float textures per building instance, made by `PlanetView`:
- `stub_tex`: the cut height and the open floors;
- `cut_tex`: the cleared floors;
- `win_tex`: windows, shape and damage, 13 rows.

Each was one texel per instance in a single row.
- **The count:** planet 7 (the nightly's world) has 3,835 buildings and 9,266 instances, so the textures were 9,266 texels wide.
- **The limits:** WebGL2 under SwiftShader allows 8,192. The PC's card allows 16,384.
- **The result:** under SwiftShader the textures failed and every read gave zero. A stub height of 0 cut every building to the ground, so nothing of the city was drawn and nothing showed in the page's console. The runner's flash readings of every clip with buildings were of that empty picture.
- **Who else:** a card or browser that caps a texture at 8,192 would have shown the same, and bigger planets have more instances.

## The change

- **`PlanetView.INST_W` is 4,096.** Instance k's texel of row r (of `rows` rows an instance) is at `inst_xy(k, r, rows)` = (k % 4096, (k / 4096) * rows + r).
- **Making the textures:** `inst_size()` gives each texture's size, and the window texture's row 2 is filled in every band.
- **Writing:** every write in `planet_view.gd` goes through `inst_xy`.
- **Reading in the shader:** the shader reads through `stub_at`, `cut_at` and `win_at`, which wrap the same way. Each clamps the instance to the texture's last whole one, as the old `min()` did.
- **Reading in the checks:** they read through `PlanetView.inst_get`.
- **Limit:** a texture is now at most 4,096 wide. Planet 7's window texture is 4,096 by 39.
- **The sim:** nothing is written to it.

## Proof

On main 6da8c6ec: iw0 = main, iw1 = main plus this park. Record: `docs/rendering/runs/6da8c6ec/building-swiftshader.txt`.

**Build and checks:**
- import 0, export clean;
- the page's console on iw1, on the card and under SwiftShader: no shader error;
- golden byte-identical to iw0;
- the render gates: 20 of 20 (open, shape and stage among them, which read the textures).

**Stills:** planet 7, collapse reduced, ticks 1 to 32, 960x540. The picture is git-ignored: `docs/rendering/img/sizes/building-swiftshader/stills-t30.png`.
- Under SwiftShader, main draws no building. With the park the city stands, as on the card.
- On the card, main and the park are pixel-identical: 0 of 32 frames differ.

**Medium's collapse on the card, worst of 4, both modes:** normal 1 and reduced 1.5, on both.

**The nightly's window under software rendering** (Tools' command, collapse-reduced, ticks 1 to 300) on iw1 reads PASS: primary 1, two-second memory 0.5. On main it read 4 and 3. The card reads 1, so the runner now measures the picture a player sees.

## After it lands

The runner's software readings of clips with buildings mean what they say again. The EP has told Tools they are invalid until then. Tools may want to read the earlier nightly baselines again.
