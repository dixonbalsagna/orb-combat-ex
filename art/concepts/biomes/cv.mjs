// Origin: the colour-vision pass over the biome palettes (deterministic). Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-24.
// The three common vision types (protan, deutan, tritan: Machado et al. 2009, severity 1.0, in linear RGB, as docs/art/colour-vision.md) over every ground, rock, vegetation, subsoil and water tone of the thirteen biomes, with the
// world-light tint of every sky key, against the fighters' PRESET lane colours (data/art/colour-vision.json: a viewer with that vision plays with the preset). The rule scales docs/art/colour-vision.md rule 3 (14 simulated against 20 normal):
// an aura stays 14 or more CIEDE2000 from the tone, and a body 10 or more from ground, rock and vegetation, under that vision. The normal-vision gates (20 and 15) stay too.
// Run: node art/concepts/biomes/cv.mjs        (prints the failures)   node art/concepts/biomes/cv.mjs --fix   (prints the nearest passing tone for each)
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { WORLD, tinted, dE00 } from '../sky/world.mjs';
import { KEYS } from '../sky/keys.mjs';
import { simulate, toOklab, fromOklab } from '../sky/colour.mjs';
import { BIOMES } from './spec.mjs';
import { tonesOf } from './measure.mjs';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const CV = JSON.parse(readFileSync(join(ROOT, 'data', 'art', 'colour-vision.json'), 'utf8'));
export const KINDS = ['protan', 'deutan', 'tritan'];
export const AURA_MIN = 14, BODY_MIN = 10;
const lanes = k => ({ aura: [CV.presets[k].protagonist.aura, CV.presets[k].rival.aura], body: [CV.presets[k].protagonist.col, CV.presets[k].rival.col] });
const LANES = Object.fromEntries(KINDS.map(k => [k, lanes(k)]));
const bodyGated = name => /ground|rock|vegetation|secondary/.test(name);

export function cvMeasure(hex, layer) {
  const worst = {};
  for (const kind of KINDS) {
    let a = [99, ''], b = [99, ''];
    for (const k of KEYS) {
      const g = simulate(tinted(hex, WORLD[k.id][layer]), kind);
      for (const c of LANES[kind].aura) { const d = dE00(simulate(c, kind), g); if (d < a[0]) a = [d, k.id]; }
      for (const c of LANES[kind].body) { const d = dE00(simulate(c, kind), g); if (d < b[0]) b = [d, k.id]; }
    }
    worst[kind] = { aura: +a[0].toFixed(1), auraAt: a[1], body: +b[0].toFixed(1), bodyAt: b[1] };
  }
  return worst;
}
export const passesCV = (w, name) => KINDS.every(k => w[k].aura >= AURA_MIN);
export function cvBiome(b) { return tonesOf(b).map(([name, hex, layer]) => { const w = cvMeasure(hex, layer); return { name, hex, layer, w, ok: passesCV(w, name) }; }); }

// the nearest tone (hue kept, lightness and chroma moved) that passes the colour-vision gates and the normal-vision gates
import { measureTone } from './measure.mjs';
export function nudge(hex, layer, name) {
  const [L, a, b] = toOklab(hex), C = Math.hypot(a, b), h = Math.atan2(b, a); let best = null;
  for (let dL = -0.2; dL <= 0.2001; dL += 0.01) for (let dC = -0.04; dC <= 0.041; dC += 0.01) {
    const C2 = Math.max(0, C + dC), L2 = L + dL; if (L2 < 0.05 || L2 > 0.97) continue;
    const c = fromOklab([L2, C2 * Math.cos(h), C2 * Math.sin(h)]), m = measureTone(c, layer);
    if (m.aura < 20.5 || (bodyGated(name) && m.bodyP < 15.5)) continue;
    if (!passesCV(cvMeasure(c, layer), name)) continue;
    const d = dE00(hex, c); if (!best || d < best.d) best = { hex: c, d };
  }
  return best;
}
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const fix = process.argv.includes('--fix'); let fails = 0;
  for (const [id, b] of Object.entries(BIOMES)) {
    const rows = cvBiome(b), bad = rows.filter(r => !r.ok); fails += bad.length;
    const worstA = Math.min(...rows.map(r => Math.min(...KINDS.map(k => r.w[k].aura)))), worstB = Math.min(...rows.filter(r => bodyGated(r.name)).map(r => Math.min(...KINDS.map(k => r.w[k].body))));
    console.log(id.padEnd(9), bad.length ? 'FAIL' : 'ok  ', `aura worst ${worstA.toFixed(1)}, body worst ${worstB.toFixed(1)}`, bad.map(r => `${r.name} ${r.hex} ${KINDS.map(k => `${k[0]}${r.w[k].aura}/${r.w[k].body}`).join(' ')}${fix ? ' -> ' + (nudge(r.hex, r.layer, r.name)?.hex ?? 'none') : ''}`).join(' | '));
  }
  console.log('failing tones:', fails);
}

// --apply: write the small nudges (CIEDE2000 6 or less from the authored tone) into spec.mjs; the larger ones are left and reported
if (process.argv[1] === fileURLToPath(import.meta.url) && process.argv.includes('--apply')) {
  const { readFileSync: rd, writeFileSync: wr } = await import('node:fs');
  const sp = join(ROOT, 'art', 'concepts', 'biomes', 'spec.mjs'); let txt = rd(sp, 'utf8'), n = 0;
  for (const [id, b] of Object.entries(BIOMES)) {
    const start = txt.indexOf(`  ${id}: {`), end = txt.indexOf('\n  },', start);
    let block = txt.slice(start, end);
    for (const r of cvBiome(b).filter(r => !r.ok && !/^water|^sea|^subsoil/.test(r.name))) { const m = nudge(r.hex, r.layer, r.name); if (m && m.d <= (process.env.CVMAX ? +process.env.CVMAX : 6) && block.includes(r.hex)) { block = block.split(r.hex).join(m.hex); n++; console.log(id, r.name, r.hex, '->', m.hex, m.d.toFixed(1)); } }
    txt = txt.slice(0, start) + block + txt.slice(end);
  }
  wr(sp, txt); console.log('applied', n);
}
