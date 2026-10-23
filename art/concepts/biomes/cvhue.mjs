// scratch: for the colour-vision failures that a lightness/chroma nudge cannot fix, search small hue shifts too
import { toOklab, fromOklab, dE00 } from '../sky/colour.mjs';
import { BIOMES } from './spec.mjs';
import { cvBiome, cvMeasure, passesCV } from './cv.mjs';
import { measureTone } from './measure.mjs';
function search(hex, layer, name) {
  const [L, a, b] = toOklab(hex), C = Math.hypot(a, b), h0 = Math.atan2(b, a); let best = null;
  for (let dh = -60; dh <= 60.1; dh += 6) for (let dL = -0.14; dL <= 0.141; dL += 0.02) for (let dC = -0.03; dC <= 0.041; dC += 0.01) {
    const h = h0 + dh * Math.PI / 180, C2 = Math.max(0, C + dC), L2 = L + dL; if (L2 < 0.05 || L2 > 0.97) continue;
    const c = fromOklab([L2, C2 * Math.cos(h), C2 * Math.sin(h)]), m = measureTone(c, layer);
    if (m.aura < 20.5) continue;
    if (!passesCV(cvMeasure(c, layer), name)) continue;
    const d = dE00(hex, c); if (!best || d < best.d) best = { hex: c, d };
  }
  return best;
}
const only = process.argv[2];
for (const [id, b] of Object.entries(BIOMES)) { if (only && only !== id) continue; for (const r of cvBiome(b).filter(r => !r.ok)) { const s = search(r.hex, r.layer, r.name); console.log(id.padEnd(9), r.name.padEnd(14), r.hex, '->', s ? s.hex + ' dE ' + s.d.toFixed(1) : 'none'); } }
