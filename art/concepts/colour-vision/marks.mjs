// Origin: the non-colour marks (one per fighter) and the biome patterns, as data (deterministic, no randomness, no external code or data).
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-07. Human direction: Orb, via the EP; UI asked for a non-colour mark per fighter body and a pattern per biome
// (my own rule: never colour alone). Both are shapes, so they work with the colour turned off.

import { toOklab, fromOklab } from '../sky/colour.mjs';

// the lane glyphs: a ring for the Protagonist (his round masses, the belt knot), a slash for the rival (his blades, the cheek slash). The same glyph is used on the body, the aura, the HUD chip and the planet strip marker.
export const MARKS = {
  protagonist: { glyph: 'ring', body_decal: { where: 'the near shoulder plate', shape: 'a ring: outer radius 3.9 body units, stroke 1.6, hollow', ink: 'the gear light colour (#c4ece6) on the dark plate' }, aura_pattern: 'solid ring', hud_chip: 'a circle', strip_marker: 'a circle' },
  rival: { glyph: 'slash', body_decal: { where: 'across the near upper arm', shape: 'one diagonal bar from low-left to high-right: 9 body units long, 2.4 wide', ink: 'the accent light colour (#d9c4f8) on the dark sleeve' }, aura_pattern: 'broken ring: dashes 6 px long with 4 px gaps along the outline (a diagonal stripe mask)', hud_chip: 'a diamond', strip_marker: 'a diamond' },
  rule: 'A new fighter gets a glyph from a different family to every existing one (a ring, a slash, then for example a chevron, a bar, a cross of dots), used in the same five places; never a letter or a number.',
};

// the planet strip: seven biomes, each a base colour (render/core/look.gd BIOME) and a pattern on a 12 by 12 tile. The ink is the base colour moved 0.2 in OKLab lightness away from the middle, so the pattern reads on the colour and in grey.
export const BIOME_COLOURS = { ocean: '#2a6b98', plains: '#5f9140', city: '#6c7079', village: '#7c8e4b', forest: '#2e6a35', desert: '#cfa85c', mountains: '#7e766a' };
export const PATTERNS = {
  ocean: { name: 'waves', tile: 12, d: 'M0 4 Q3 1 6 4 T12 4 M0 10 Q3 7 6 10 T12 10', mode: 'stroke', stroke: 1.4 },
  plains: { name: 'grass ticks', tile: 12, d: 'M2 10 V6 M6 8 V4 M10 11 V7', mode: 'stroke', stroke: 1.4 },
  city: { name: 'grid of squares', tile: 12, d: 'M1.5 1.5 h4 v4 h-4 z M7.5 1.5 h4 v4 h-4 z M1.5 7.5 h4 v4 h-4 z M7.5 7.5 h4 v4 h-4 z', mode: 'stroke', stroke: 1.2 },
  village: { name: 'roofs', tile: 12, d: 'M0 12 L3 6 L6 12 Z M6 6 L9 0 L12 6 Z', mode: 'fill' },
  forest: { name: 'round crowns', tile: 12, circles: [[3, 3, 1.9], [9, 3, 1.9], [6, 9, 1.9]], mode: 'fill' },
  desert: { name: 'stipple', tile: 12, circles: [[2, 2, 0.8], [7, 4, 0.8], [11, 1, 0.8], [4, 8, 0.8], [9, 10, 0.8]], mode: 'fill' },
  mountains: { name: 'peaks', tile: 12, d: 'M0 11 L3 4 L6 11 L9 4 L12 11', mode: 'stroke', stroke: 1.4 },
};
export function inkOf(hex) { const [L, a, b] = toOklab(hex); return fromOklab([L + (L > 0.55 ? -0.2 : 0.2), a, b]); }
export const STRIP_ORDER = [['ocean', 0.12], ['village', 0.06], ['plains', 0.10], ['city', 0.14], ['village', 0.05], ['forest', 0.12], ['desert', 0.12], ['mountains', 0.10], ['village', 0.05], ['plains', 0.08], ['ocean', 0.06]];
export const patternData = () => Object.fromEntries(Object.entries(PATTERNS).map(([k, p]) => [k, { pattern: p.name, tile_px: p.tile, mode: p.mode, stroke_px: p.stroke ?? null, path: p.d ?? null, circles: p.circles ?? null, base: BIOME_COLOURS[k], ink: inkOf(BIOME_COLOURS[k]) }]));
