# Parked: the tile ground in the real game (`2026-10-31a-tile-ground`)

Rendering, 2026-10-31. Stage 4 of `docs/world/ring-any-angle/research.md` T6, behind a switch. **Off, nothing runs and nothing the game draws should change. On, with `?tiles=1` on a local page or `--tiles`, the fight is on planet-keyed tiles on a true globe, through Simulation's frame.**

**Applies on main** (field-frame and World's 01 to 07 landed). World's 08 to 15 are parked and stack above it: with 11 or 15 present, its pads or lots replace the place band's heights by themselves.

**Apply:** on a scratch export of main, never the repo root: `git -c core.autocrlf=false apply --ignore-whitespace tile.diff`. Then copy the changed files.

## Page words (local pages only: `LOCAL_ONLY_ARGS`)

| Word | What |
| :--- | :--- |
| `tiles=1` | The switch. A match with no planet named plays planet 7, gen 3, Whole ring |
| `nearmode=0` to `4` | A tower near the line: 0 Q, 1 W, 2 E, **3 Q+W, the default until Orb picks**, 4 W+E |
| `tilerate=60` | A test: the view alone turns the planet about the fight at that rate, in full turns. Add `tilequick=1` for small swings |
| `tileshare=95` | 95% globe at the closest zoom, to compare |
| `tilegen=2` | The gen 2 ring instead, to compare |
| `nofore=1` | Off: the one tone in front of the plane (Camera's flash fix, on by default; sea and marks keep their colours) |

## What's in it

| File | Owner | What |
| :--- | :--- | :--- |
| `render/core/tile_field.gd` (new) | Mine | The tiles' data, shared by panes. Reads World's nodes on demand, with the places' records. Level 0 is the bake. Also the lift's table |
| `render/core/tile_ground.gd` (new) | Mine | One a pane: the frame, the tile walk, the world's turn, the foreground profile, the sky's horizon |
| `render/shaders/tile_vertex.gdshaderinc`, `terrain_tile.gdshader` (new) | Mine | The tile's vertex stage. The fragment is the real terrain's, by `#ifdef` in `terrain.gdshaderinc` |
| `render/shaders/bend.gdshaderinc`, `ortho.gdshaderinc` | Mine | The one placement: `globe_place`, `globe_tower`, `globe_sag` |
| `building`, `cover`, `crowd`, `particle.gdshader`; `look`, `main`, `mats`, `pane_world`, `planet_view.gd` | Mine | The placement, the switch, the load step |
| `render/vfx/shaders/`: `beam_scar`, `cloud`, `cloud_core`, `dust`, `hole`, `shard`, `trail`, `transform` | **VFX's: a grant** | One include and one line each, inert while off |
| `render/tools/tile_check.gd` (new) | Mine | The field's heights against the sim's along the line. Headless, for CI |
| `render/tools/cover_water_check.gd`, `lake_water_check.gd` | Mine | Their gen 1 setups name `planetGen: 1` |
| `render/vfx/crack_view.gd` | **VFX's: a grant** | One guarded line: with the switch on, the crack webs go when a swing begins |
| `project.godot` | **The EP's: a grant** | One global shader value, `globe_r`, 0 while off |

## Decisions I made

1. **The lattice is World's.** 25 cells a tile; 3, 6, 12 tiles a face edge at 512, 256, 128 units; mesh levels below 128 keep the 128 triangles and only add vertices for craters.
2. **The view's frame is the camera's strip x on the sim's line.** The world's things stay at their plan pose in `S.frame0`, and one matrix carries the plan to the view, so a swing doesn't rewrite them. `b.g.x` replaces `b.x` in a building's transform with the switch on.
3. **Feet: the body offset, by a table of columns in the shared placement.** It's drawn ground less `SimField.heightOf`. Fighters read it on the CPU.
4. **A fighter keeps his shape.** His anchor lands on the globe and his parts follow the curve from there, so he doesn't lean with the planet at the screen's edge. Beams bend through their rings the same way.
5. **Whole ring only, as the frame requires.** The switch drops `arena` from the setup.
6. **See-through in a swing (the EP's ruling):** a building past `poseReach` of both fighters has a stale pose, so it gives no see-through until rest. The pane sweep defers the same way: a stale pose only refreshes a building late.
7. **The near rule does nothing at rest.** A tower or a small thing only goes as a swing brings it nearer than its own plan depth, so a street stands as laid until the world turns.
8. **Places' ground:** every building stands on the line's height, and the field at its own point can be far off, so inside a place's band the tile takes the plan's strip (`S.base`) and the place's palette (`WorldBiomes.biomeAt`, else city). World has the footprint order, and this goes when it lands.

## Known gaps

- **Water is colour by depth, not the water sheet yet.** The sea starts past World's shore (`WorldWater.SHORE_WET`). Lakes and rivers come from `WorldField.recordWater`, wherever World's records hold them; I have no separate river switch of my own, so what shows follows `rivers.json`.
- **Marks stay on the strip** (Simulation's limit until stage 7): a crater rides the line in a swing. Its depth and colours do show on the tiles, with the mesh's near vertices at about 32 u.
- **World's 32 u refined cells aren't read yet.** Feet are covered by the lift, but a shore or cliff near the pair can be up to a 128 cell from what the sim reads. Next piece.
- **Standard only.** The other four levels are data later.
- **Trees are flat silhouettes,** edge-on in a swing. **Biome borders are jagged** at node size.
- **The crowd has no lift.** The citizens fix (2026-10-30i) stays parked and needs re-cutting on this.
- **Camera doesn't frame the sag yet, and HUD markers have no CPU twin:** they drift from the body by the sag at wide zooms (46 units at x = 1,500).
- **Far towns are off** with the switch on, and so are the strip's ground meshes, which aren't built at all.
- **Effects don't take the lift yet:** only what's in `RenderMats` does. At Standard the gap is small.
- **The swing itself is Encounter's stage 6.** Until then a match on `tiles=1` has no sim swing, and `tilerate` is the only turn.
