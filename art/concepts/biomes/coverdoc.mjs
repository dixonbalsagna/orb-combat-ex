// Origin: writes docs/art/biomes-cover.md from the cover table (deterministic). Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-24.
import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { coverSheet } from './covers.mjs';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
export function writeCoverDoc() {
  const t = coverSheet().table;
  let md = "# Biome cover: the 33 silhouettes with triangle counts\n\nOwner: Art Director. 2026-10-24. **Generated** by `art/concepts/biomes/covers.mjs` (`node art/concepts/biomes/gen.mjs cover`). The sheet is `art/concepts/biomes/cover-sheet.svg` and `cover-sheet.png` (the PNG is 1:1: 1 unit = 1.147 px, so a fighter of 75 units is 86 px, the game's fight size). Counts are of the flat mesh the drawing needs: every polygon fanned (n minus 2), every thin line a quad (2 per segment); the keyline is a stroke (Rendering's outline), not geometry. Charred is the burned state: a black trunk with bare branches for a tree, stubs and ash for grass, a darkening for rock (the same mesh).\n\n| Shape | Biomes | Height (units) | Height (px at fight size) | Triangles, clean | Triangles, charred |\n|---|---|---|---|---|---|\n";
  for (const r of t) md += `| ${r.kind} | ${r.biomes.join(', ')} | ${r.height_range_u[0]} to ${r.height_range_u[1]} | ${r.height_range_px[0]} to ${r.height_range_px[1]} | ${r.tris_clean} | ${r.tris_charred} |\n`;
  const tc = t.reduce((s, r) => s + r.tris_clean, 0), tx = t.reduce((s, r) => s + r.tris_charred, 0), top = [...t].sort((a, b) => b.tris_clean - a.tris_clean).slice(0, 4);
  md += `\n**Totals:** all ${t.length} clean shapes ${tc} triangles, charred ${tx}. A strip of 1,200 units carries about 30 shapes (the cover densities in the data), so about ${Math.round(tc / t.length * 30)} triangles of cover per strip on average, before the ground. The heaviest: ${top.map(r => `${r.kind} (${r.tris_clean})`).join(', ')}.\n\n**What Rendering builds:** each shape as one flat mesh of a few facets with three face colours (lit, mid, shade) from the biome palette; the charred version as a second small mesh swapped in by the burn state; a tree's canopy is 8 fan triangles.\n`;
  writeFileSync(join(ROOT, 'docs', 'art', 'biomes-cover.md'), md);
}
