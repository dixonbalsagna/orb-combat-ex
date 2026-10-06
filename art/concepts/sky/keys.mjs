// Origin: the dynamic sky's keys and blend rules as code and data (deterministic, no randomness, no external code or data).
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-06. Human direction: Orb, via the EP (docs/ep/vision.md, 2026-10-06).
// The sky stays inside the game's look: four bands, top to horizon, the way render/core/look.gd's SKY array has them. The current look
// ("#111a3e", "#4b4483", "#d9776b", "#f4b87a") is the key SUNSET and is the sky at the start of a match. The other keys extend it.

import { mixOklab, luminance, lchOf, labOf, lumFromLab, fromOklab } from './colour.mjs';

export const BANDS = ['horizon', 'lower', 'upper', 'top'];
// the keys, in order round the planet: where on a lap (0 to 1) each stands, and how long it holds before the blend begins
export const KEYS = [
  { id: 'noon', glow_reach: 0, phase: 0.00, hold: 0.04, note: 'high day: a deep blue sky with a warm cream haze at the horizon (not a pale blue, which would swallow the Protagonist\'s aura)', bands: { top: '#14307a', upper: '#005999', lower: '#0084c5', horizon: '#e8e2c8' }, stars: 0 },
  { id: 'golden', glow_reach: 0.5, phase: 0.18, hold: 0.03, note: 'late afternoon: the blue climbs, amber comes up from the horizon', bands: { top: '#1a2f6e', upper: '#0066a8', lower: '#e0a468', horizon: '#f8dba0' }, stars: 0 },
  { id: 'sunset', glow_reach: 1, phase: 0.32, hold: 0.03, note: 'THE CURRENT LOOK (render/core/look.gd SKY): indigo, violet, coral, peach. A match starts here', bands: { top: '#111a3e', upper: '#4b4483', lower: '#d9776b', horizon: '#f4b87a' }, stars: 0.15 },
  { id: 'night', glow_reach: 1, phase: 0.58, hold: 0.06, note: 'night: blue-black, a cold blue rim; no violet, so the rival\'s violet is never swallowed', bands: { top: '#05081a', upper: '#0a1636', lower: '#12294f', horizon: '#243e66' }, stars: 1 },
  { id: 'dawn', glow_reach: 1, phase: 0.84, hold: 0.03, note: 'dawn: teal into rose into apricot, cooler and greener than the sunset so the two are not mistaken', bands: { top: '#16264e', upper: '#00618b', lower: '#d98f86', horizon: '#f6c9a0' }, stars: 0.3 },
];
export const START = { key: 'sunset', phase: 0.32 };

const smooth = t => t * t * (3 - 2 * t);
// how a band blends from one key to the next: 'lab' (straight in OKLab) or round the hue wheel one way ('lch+') or the other ('lch-'), chosen per band and per transition
// so no blend passes through a grey or a violet that would sit on the lane colours (the Protagonist's pale blue and the rival's violet). Found by search in blend.mjs.
export const BLEND = [
  { horizon: 'lab', lower: 'lch-', upper: 'lab', top: 'lab' },   // noon -> golden
  { horizon: 'lab', lower: 'lab', upper: 'lab', top: 'lab' },   // golden -> sunset
  { horizon: 'lab', lower: 'lab', upper: 'lab', top: 'lab' },   // sunset -> night
  { horizon: 'lch-', lower: 'lch-', upper: 'lab', top: 'lab' },   // night -> dawn
  { horizon: 'lab', lower: 'lch+', upper: 'lab', top: 'lab' },   // dawn -> noon
];
export function pathLab(a, b, t, mode = 'lab') {
  const A = labOf(a), B = labOf(b);
  if (mode === 'lab') return A.map((v, i) => v + (B[i] - v) * t);
  const [L1, c1, h1] = lchOf(a), [L2, c2, h2] = lchOf(b); let d = h2 - h1;
  if (mode === 'lch+') { if (d < 0) d += 360; } else if (d > 0) d -= 360;
  const L = L1 + (L2 - L1) * t, c = c1 + (c2 - c1) * t, h = (h1 + d * t) * Math.PI / 180;
  return [L, c * Math.cos(h), c * Math.sin(h)];
}
// the sky of a given place on the lap (phase 0 to 1, wrapping): hold on a key, then blend to the next in OKLab, per band
export function skyAt(phase) {
  phase = ((phase % 1) + 1) % 1;
  const n = KEYS.length;
  for (let i = 0; i < n; i++) {
    const a = KEYS[i], b = KEYS[(i + 1) % n], pa = a.phase, pb = i === n - 1 ? 1 + b.phase : b.phase;
    const p = (i === n - 1 && phase < a.phase) ? phase + 1 : phase;
    if (p >= pa && p <= pb) {
      const hA = a.hold, hB = b.hold, lo = pa + hA, hi = pb - hB;
      const t = p <= lo ? 0 : p >= hi ? 1 : smooth((p - lo) / (hi - lo));
      const bands = {}; for (const k of BANDS) bands[k] = fromOklab(pathLab(a.bands[k], b.bands[k], t, BLEND[i][k]));
      return { bands, stars: a.stars + (b.stars - a.stars) * t, between: [a.id, b.id, t] };
    }
  }
  return { bands: KEYS[0].bands, stars: 0, between: ['noon', 'golden', 0] };
}
// the sky's mean relative luminance, weighted by how much of the screen each band fills above the horizon (horizon band narrow, top wide)
export const WEIGHTS = { horizon: 0.18, lower: 0.30, upper: 0.30, top: 0.22 };
export const meanLum = bands => BANDS.reduce((s, k) => s + WEIGHTS[k] * luminance(bands[k]), 0);
export { lchOf };

// ---------------------------------------------------------------------------------------------------------- the fight's mood and the world's damage
export const EMBER = '#d9603c', SMOKE = '#2e221c', ASH = '#2b2724', DEEP = '#05060f';
export const MOOD_COLOURS = { ember: EMBER, smoke: SMOKE, ash: ASH, deep: DEEP };
// every amount the mood uses, as data (data/art/sky.json mood._amounts is written from this, so Rendering reads numbers and nothing is kept in step by hand).
// Each entry mixes the band toward `to` (a mood colour, or 'top' for the top band after frenzy has deepened it) by amount times the driver (0 to 1).
// The glow is a town's: its horizon amount is the strongest, and the lower and upper amounts (how high it reaches) are scaled by the key's glow_reach, so at noon it stays low.
export const MOOD_AMOUNTS = {
  order: ['frenzy', 'ruin', 'glow'],
  frenzy: { top: { to: 'deep', amount: 0.18 }, upper: { to: 'top', amount: 0.25 }, lower: { to: 'deep', amount: 0.10 }, horizon: { to: 'ember', amount: 0.10 } },
  ruin: { horizon: { to: 'smoke', amount: 0.60 }, lower: { to: 'smoke', amount: 0.60 }, upper: { to: 'smoke', amount: 0.40 }, top: { to: 'ash', amount: 0.25 }, stars_at_full: 0.30 },
  glow: { horizon: { to: 'ember', amount: 0.45 }, lower: { to: 'ember', amount: 0.22, scaled_by_key_reach: true }, upper: { to: 'ember', amount: 0.08, scaled_by_key_reach: true } },
};
export const GLOW_REACH = { noon: 0, golden: 0.5, sunset: 1, night: 1, dawn: 1 };
const mixTo = (c, to, amount, out) => mixOklab(c, to === 'top' ? out.top : MOOD_COLOURS[to], amount);
// frenzy f, ruin r and glow g in 0 to 1 (already eased by the caller); reach is the key's glow_reach (0 to 1, from GLOW_REACH, blended with the place)
export function moodSky(bands, { frenzy = 0, ruin = 0, glow = 0, reach = 1 } = {}) {
  const out = { ...bands };
  for (const [band, { to, amount }] of Object.entries(MOOD_AMOUNTS.frenzy)) out[band] = mixTo(out[band], to, amount * frenzy, out);
  for (const [band, v] of Object.entries(MOOD_AMOUNTS.ruin)) if (band !== 'stars_at_full') out[band] = mixTo(out[band], v.to, v.amount * ruin, out);
  for (const [band, v] of Object.entries(MOOD_AMOUNTS.glow)) out[band] = mixTo(out[band], v.to, v.amount * glow * (v.scaled_by_key_reach ? reach : 1), out);
  return out;
}
export const starsAfterRuin = (stars, ruin) => stars * (1 - (1 - MOOD_AMOUNTS.ruin.stars_at_full) * ruin);

// ---------------------------------------------------------------------------------------------------------- the rate limit (nothing fast)
export const BUDGET = { place: { mean: 0.015, band: 0.035 }, mood: { mean: 0.005, band: 0.015 }, total: { mean: 0.02, band: 0.05 } };
// the luminance of each band at a phase, with no rounding (the limiter works on these)
export function lumsAt(phase) {
  phase = ((phase % 1) + 1) % 1; const n = KEYS.length;
  for (let i = 0; i < n; i++) {
    const a = KEYS[i], b = KEYS[(i + 1) % n], pa = a.phase, pb = i === n - 1 ? 1 + b.phase : b.phase, p = (i === n - 1 && phase < a.phase) ? phase + 1 : phase;
    if (p >= pa && p <= pb) {
      const lo = pa + a.hold, hi = pb - b.hold, t = p <= lo ? 0 : p >= hi ? 1 : smooth((p - lo) / (hi - lo)), out = {};
      for (const k of BANDS) out[k] = lumFromLab(pathLab(a.bands[k], b.bands[k], t, BLEND[i][k]));
      return out;
    }
  }
  return {};
}
const meanOf = l => BANDS.reduce((s, k) => s + WEIGHTS[k] * l[k], 0);
// how far (in phase) the shown sky may move in dt seconds from phase p towards a target, so no band's luminance changes faster than the place budget
export function slewStep(p, target, dt) {
  const d = ((target - p + 1.5) % 1) - 0.5;   // the short way round, -0.5 to 0.5
  if (Math.abs(d) < 1e-9) return p;
  const sign = Math.sign(d), base = lumsAt(p), baseM = meanOf(base);
  const okAt = s => { const b = lumsAt(p + sign * s); if (Math.abs(meanOf(b) - baseM) / dt > BUDGET.place.mean) return false; for (const k of BANDS) if (Math.abs(b[k] - base[k]) / dt > BUDGET.place.band) return false; return true; };
  let lo = 0, hi = Math.abs(d);
  if (okAt(hi)) return (p + sign * hi + 1) % 1;
  for (let i = 0; i < 30; i++) { const mid = (lo + hi) / 2; if (okAt(mid)) lo = mid; else hi = mid; }
  return (p + sign * lo + 1) % 1;
}
