# GB-011 look gate: where to put the camera (World, 2026-11-28)

For Rendering and World. Measured from the sim on `a82fdb64` (sim, data and render are unchanged at `d0d08177`). **Nothing below was rendered except the three pictures named at the end.**

## The match

- Planet 7, touch-down 3, generator 3, medium (the default match). Seed 12345; the lakes do not depend on the seed.
- Page: `/index.html?flashcap=1&planet=7&touch=3&nohud=1`, `--reduced`, 960x540.
- Compare main with the build that has **all four** GB-011 patches.
- x runs 0..153,600. z is depth, **positive toward the camera**; the fight line is z 0.

## Views on the line (water the sim holds at z 0)

| x | Main: sim water | Main: face over dry ground | With the park |
| ---: | :--- | ---: | :--- |
| 24,000 | to x 25,300, 796 deep at 24,000, surface 2,062 | **921** (left end) | dry |
| 27,800 | 453 deep, surface 2,062 | **508** (right end) | dry |
| 21,900 | 416 deep, surface 990 | **469** (left end) | dry |
| 54,600 | x 52,600..55,100, 359 deep, surface 689 | **263** (right end) | dry or under 60 deep |
| 95,800 | 193 deep, surface 1,899 | 219 (right end) | dry or under 60 deep |
| 89,400 | 322 deep, surface 2,749 | none here | **the lake kept**: x 88,700..90,200, 166 deep, surface 2,501, ground cut from 2,427 to 2,335 |

**Whether main draws each of these is not checked.** Main's tiles skip lake water inside a place's band (`render/core/tile_field.gd`, the wet gate the grant changes), so some faces the sim holds may not be on screen there. The look gate should find one main does show.

## QA's two sites (the water is off the line)

| Site | Drowned house (main) | Worst face QA found (main) | With the park |
| :--- | :--- | :--- | :--- |
| A, x 22,800 | x 22,406, z -894 (behind the line): 611 deep on ground 378 | x 24,300, z -1,050: 1,497 deep, surface 2,062 | no water in a box of ±3,000 round (22,800, -850) |
| B, x 50,800 | x 50,764, z **+5,400** (toward the camera): 456 deep on ground 233 | x 52,730, z 4,550: 493 deep, surface 689 | no water in a box of ±3,000 round (50,780, 5,200) |

A line camera does not frame B's houses at all: they are 5,400 toward the viewer. Site B needs the pair posed in depth or another bearing (Rendering's call).

## The scene I used

Added to `render/tools/flash_capture.gd` in a scratch tree only (names `lakea` x 22,800, `lakeb` x 50,500, `lakec` x 89,400):

```gdscript
func _lakeview(t: int, S: SimState, x: float) -> void:
	if t == 0:
		for i in range(2):
			var f = S.fighters[i]
			f.x = SimWrap.wrap(x + (-300.0 if i == 0 else 300.0))
			f.y = WorldTerrain.groundY(S, f.x) + 40.0
			f.vx = 0.0
			f.vy = 0.0
```

150 ticks (A, B, C) and 240 (C). Pictures in `img/` (git-ignored): at A and B main and the park show **no water on either side**; at C main shows bare ground and the park a flat lake.
