// Origin: the readability measure of the biome palettes (deterministic). Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-23.
// The rule (docs/art/dynamic-sky.md section 6, data/art/sky.json readability): an aura stays 20 or more CIEDE2000 from the ground it is drawn over, a body 15 or more, at every sky key with the world-light tint of that layer.
// The two fighters in the build are the Protagonist and the rival; the Empress's green and the Cyborg's mint are advisory (not in the build): they are reported and not gated.
import { WORLD, tinted, dE00 } from '../sky/world.mjs';
import { KEYS } from '../sky/keys.mjs';
import { BIOMES } from './spec.mjs';

export const AURA = { protagonist: '#8fd6ff', rival: '#9a80d8' };
export const BODYS = { protagonist: '#3d8fdc', rival: '#a52a2a', rival_coat: '#6f342c' };
export const ADVISORY = { empress: '#3c7d1c', cyborg: '#47d7a7' };
const LAYER = { g: 'ground', sub: 'ground', r: 'ground', v: 'trees', v2: 'trees', t: 'trees', w: 'water' };

export function tonesOf(b) {
  const p = b.pal, out = [];
  const gl = b.name === 'Open ocean' ? 'water' : 'ground';
  p.g.forEach((h, i) => out.push([`${gl === 'water' ? 'sea' : 'ground'} ${['lit', 'mid', 'shade'][i]}`, h, gl]));
  out.push(['subsoil', p.sub, 'ground']);
  out.push(['rock mid', p.r[1], 'ground'], ['rock lit', p.r[0], 'ground']);
  if (!b.pal.novegetation && !/ice/i.test(b.name)) out.push(['vegetation mid', p.v[1], 'trees'], ['vegetation lit', p.v[0], 'trees'], ['secondary mid', p.v2[1], 'trees']);
  out.push(['water shallow', p.w[0], 'water'], ['water deep', p.w[1], 'water']);
  const seen = new Set();
  return out.filter(([, h, l]) => { const k = h + l; if (seen.has(k)) return false; seen.add(k); return true; });
}
export function measureTone(hex, layer) {
  const worst = { aura: [99, '', ''], body: [99, '', ''], bodyP: [99, '', ''], adv: [99, '', ''] };
  for (const k of KEYS) {
    const g = tinted(hex, WORLD[k.id][layer]);
    for (const [n, c] of Object.entries(AURA)) { const d = dE00(c, g); if (d < worst.aura[0]) worst.aura = [d, n, k.id]; }
    for (const [n, c] of Object.entries(BODYS)) { const d = dE00(c, g); if (d < worst.body[0]) worst.body = [d, n, k.id]; if (n !== 'rival_coat' && d < worst.bodyP[0]) worst.bodyP = [d, n, k.id]; }
    for (const [n, c] of Object.entries(ADVISORY)) { const d = dE00(c, g); if (d < worst.adv[0]) worst.adv = [d, n, k.id]; }
  }
  return { aura: +worst.aura[0].toFixed(1), auraWho: worst.aura[1], auraAt: worst.aura[2], bodyP: +worst.bodyP[0].toFixed(1), body: +worst.body[0].toFixed(1), bodyWho: worst.body[1], bodyAt: worst.body[2], adv: +worst.adv[0].toFixed(1), advWho: worst.adv[1] };
}
export function measureBiome(b) { return tonesOf(b).map(([name, hex, layer]) => ({ name, hex, layer, ...measureTone(hex, layer) })); }
if (process.argv[1].endsWith('measure.mjs')) {
  for (const [id, b] of Object.entries(BIOMES)) {
    const rows = measureBiome(b), bad = rows.filter(r => r.aura < 20 || (/ground|rock|vegetation|secondary/.test(r.name) && r.bodyP < 15));
    console.log(id.padEnd(9), bad.length ? 'FAIL' : 'ok  ', bad.map(r => `${r.name} ${r.hex} aura ${r.aura} (${r.auraWho}@${r.auraAt}) body ${r.body} (${r.bodyWho}@${r.bodyAt})`).join(' | '));
  }
}
