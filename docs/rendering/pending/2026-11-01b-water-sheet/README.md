# Parked: the gen 3 water sheet with water's A1 (`2026-11-01b-water-sheet`)

Rendering, 2026-11-01. Stacks on the tile, near-tower and far-tile diffs, in that order. On only with the tile ground's switch. Off, the plain water and terrain shaders' text is unchanged behind `#ifdef`s.

**What it does:**
- The tiles with water in them draw a second time with `water_tile.gdshader`: the water's own fragment (foam line, shallow band, depth bands) with a vertex stage of its own. The sea's top is 0; a lake's or a river's top comes from `WorldField.recordWater` at its node.
- The ground is now the real bed (`y = h`), under the sheet. This replaces colour by depth.
- `render/shaders/tile_read.gdshaderinc` (new) holds what the two vertex stages share.
- **A1 (`docs/world/low-impact-water.md`), view only, nothing hashed:** a hollow ring where a body crosses or skims the surface, up to 6 live, no faster than 2 Hz a body; a short V wake (two hard foam lines) behind one flying under 600 u at over 600 u/s. Numbers in `RenderLook.TILE_RING_*`, `TILE_WAKE_*`. The shader's `ww_a`, `ww_b` are 6 long on the tile ground, 2 on the plain sheet.

**Not in it:**
- VFX's spray. It reads fighters and events, and nothing here blocks it.
- A prop crossing the surface: fighters only for now.
- Holes that fill (`wf_*`) stay off on the tile sheet: B1 is Next.
- A2, the parted sea.

**Seen:** `docs/rendering/img/lookgate/tile-water-sheet.png`: the sea on gen 3 with its shallow band (bottom middle), a gen 2 harbour (top row). Rings and wakes aren't caught in a still yet. The shore is drawn on 128 u nodes, so it's blocky close up.

**Apply:** on a scratch export with the three parks under it: `git -c core.autocrlf=false apply --ignore-whitespace water.diff`.
