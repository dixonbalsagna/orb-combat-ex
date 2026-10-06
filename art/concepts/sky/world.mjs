// Origin: the world's light per sky key as code and data (deterministic, no randomness, no external code or data).
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-07. Human direction: Orb, via the EP (docs/ep/vision.md; Rendering's still docs/rendering/img/sky-keys.png).
// The sky's keys change only the sky's four bands, so at night a daylit ground stood under a black sky. This is the fix, inside the existing look (flat colours with a keyline,
// no new shading model): a multiply tint per layer (in linear light) and, for the night, a small additive lift, blended with the same phase, hold and ease as the sky.
// The fighters' bodies dim less than the ground; the auras, the lane colours and the lit windows do not dim at all.

import { toLin, fromLin, luminance, dE00, hex2rgb } from './colour.mjs';
import { KEYS } from './keys.mjs';

export const LAYERS = ['ground', 'buildings', 'trees', 'water', 'civilians', 'bodies'];
export const NEVER_DIMMED = ['aura rings', 'lane colours', 'lit windows', 'the HUD', 'flashes and particles', 'the keyline (#0a0d14)'];
// authored colours (render/core/look.gd): the base luminance of each layer, for the rate limit
export const BIOME = { ocean: '#2a6b98', plains: '#5f9140', city: '#6c7079', village: '#7c8e4b', forest: '#2e6a35', desert: '#cfa85c', mountains: '#7e766a' };
export const AUTHORED = { tower: '#565e70', house: '#a67c52', roof: '#7a3b2e', tree: '#1f4a26', tree_top: '#2f6b35', water: '#1e6eaf', sea_floor: '#5a5346', crater: '#4a4237' };
export const BODY = { protagonist: '#3d8fdc', rival: '#a52a2a' };   // data/fighters/*/fighter.json "col"
const mean = a => a.reduce((s, v) => s + v, 0) / a.length;
export const BASE_LUM = {
  ground: mean(['plains', 'village', 'forest', 'desert', 'mountains', 'city'].map(k => luminance(BIOME[k]))),
  buildings: mean([AUTHORED.tower, AUTHORED.house, AUTHORED.roof].map(luminance)),
  trees: mean([AUTHORED.tree, AUTHORED.tree_top].map(luminance)),
  water: luminance(AUTHORED.water),
  civilians: 0.3,
  bodies: mean(Object.values(BODY).map(luminance)),
};
// how much of the screen each part fills, for the screen's mean luminance (sky above the horizon about 45 percent)
export const SCREEN_W = { sky: 0.45, ground: 0.30, buildings: 0.10, trees: 0.02, water: 0.08, civilians: 0.01, bodies: 0.04 };

// the tint per layer at each key: mul is a multiplier in linear light (1 = unchanged), add a small lift in linear light (night only)
const T = (mul, add = [0, 0, 0]) => ({ mul, add });
export const WORLD = {
  noon: { ground: T([1, 1, 1]), buildings: T([1, 1, 1]), trees: T([1, 1, 1]), water: T([1, 1, 1]), civilians: T([1, 1, 1]), bodies: T([1, 1, 1]) },
  golden: { ground: T([1.0, 0.84, 0.62]), buildings: T([1.0, 0.86, 0.68]), trees: T([0.96, 0.9, 0.7]), water: T([0.86, 0.9, 0.96]), civilians: T([1.0, 0.9, 0.76]), bodies: T([1.0, 0.92, 0.8]) },
  sunset: { ground: T([0.95, 0.74, 0.58]), buildings: T([0.96, 0.78, 0.64]), trees: T([0.9, 0.78, 0.62]), water: T([0.78, 0.78, 0.88]), civilians: T([0.98, 0.84, 0.72]), bodies: T([0.98, 0.86, 0.76]) },
  night: { ground: T([0.07, 0.10, 0.22], [0.0, 0.006, 0.034]), buildings: T([0.09, 0.12, 0.24], [0.0, 0.006, 0.03]), trees: T([0.06, 0.09, 0.19], [0, 0.004, 0.022]), water: T([0.05, 0.10, 0.26], [0, 0.006, 0.034]), civilians: T([0.45, 0.52, 0.78], [0, 0.006, 0.03]), bodies: T([0.5, 0.58, 0.82], [0, 0.008, 0.03]) },
  dawn: { ground: T([0.58, 0.52, 0.62], [0, 0.002, 0.008]), buildings: T([0.62, 0.56, 0.66], [0, 0.002, 0.008]), trees: T([0.5, 0.52, 0.58]), water: T([0.5, 0.58, 0.72]), civilians: T([0.82, 0.78, 0.86]), bodies: T([0.84, 0.8, 0.88]) },
};
// the lit windows: the share lit by key (the game's is 0.3 all day), and the lit colour is never dimmed
export const WINDOWS = { lit_share: { noon: 0.1, golden: 0.18, sunset: 0.3, night: 0.62, dawn: 0.4 }, lit_colour: '#f3cf86', glass: '#2c3550', glass_night: '#1a2038', note: 'the share rises and falls with the same phase, so windows come on a few at a time (a window is a few pixels and the share changes over tens of seconds)' };
// the fight's mood and the world's damage on the same layers: a further multiply (bodies are not touched, so a fighter stays readable in a wrecked world)
export const WORLD_MOOD = {
  frenzy: { ground: [0.94, 0.9, 0.9], buildings: [0.94, 0.9, 0.9], trees: [0.94, 0.9, 0.9], water: [0.94, 0.94, 0.94], civilians: [1, 1, 1], bodies: [1, 1, 1] },
  ruin: { ground: [0.8, 0.74, 0.7], buildings: [0.82, 0.76, 0.72], trees: [0.76, 0.7, 0.66], water: [0.85, 0.82, 0.8], civilians: [1, 1, 1], bodies: [1, 1, 1] },
  // a burning town: firelight on the ground and buildings near it (within radius body units of the town's middle), falling off linearly; a warm multiply, strongest at glow 1
  firelight: { multiply: [1.0, 0.86, 0.68], strength: 0.35, radius: 1800, applies_to: ['ground', 'buildings', 'trees'] },
};
const smooth = t => t * t * (3 - 2 * t);
const lerp3 = (a, b, t) => a.map((v, i) => v + (b[i] - v) * t);
// the world at a phase: the same hold and smoothstep as skyAt, the multipliers mixed linearly
export function worldAt(phase) {
  phase = ((phase % 1) + 1) % 1; const n = KEYS.length;
  for (let i = 0; i < n; i++) {
    const a = KEYS[i], b = KEYS[(i + 1) % n], pa = a.phase, pb = i === n - 1 ? 1 + b.phase : b.phase, p = (i === n - 1 && phase < a.phase) ? phase + 1 : phase;
    if (p >= pa && p <= pb) {
      const lo = pa + a.hold, hi = pb - b.hold, t = p <= lo ? 0 : p >= hi ? 1 : smooth((p - lo) / (hi - lo)), out = {};
      for (const L of LAYERS) out[L] = { mul: lerp3(WORLD[a.id][L].mul, WORLD[b.id][L].mul, t), add: lerp3(WORLD[a.id][L].add, WORLD[b.id][L].add, t) };
      return { layers: out, lit: WINDOWS.lit_share[a.id] + (WINDOWS.lit_share[b.id] - WINDOWS.lit_share[a.id]) * t };
    }
  }
  return { layers: WORLD.noon, lit: 0.1 };
}
// apply a tint to a colour (hex in, hex out): multiply in linear light, then add
export function tinted(hex, tint, mood = null) {
  const v = toLin(hex), m = tint.mul, a = tint.add, mm = mood ?? [1, 1, 1];
  return fromLin(v.map((c, i) => c * m[i] * mm[i] + a[i]));
}
// the luminance factor a layer's tint gives an average colour of base luminance L0
export const layerLum = (layer, tint, mood = [1, 1, 1]) => BASE_LUM[layer] * (0.2126 * tint.mul[0] * mood[0] + 0.7152 * tint.mul[1] * mood[1] + 0.0722 * tint.mul[2] * mood[2]) + (0.2126 * tint.add[0] + 0.7152 * tint.add[1] + 0.0722 * tint.add[2]);
export { dE00, hex2rgb };

// ---------------------------------------------------------------------------------------------------------- the rate limit with the world in it
import { lumsAt, BANDS, WEIGHTS, BUDGET } from './keys.mjs';
const skyMean = l => BANDS.reduce((s, k) => s + WEIGHTS[k] * l[k], 0);
// the luminance of the four bands and of each world layer at a phase, and the screen's mean (the sky weighted as a whole, each layer by how much of the screen it fills)
export function lumsAll(phase) {
  const s = lumsAt(phase), w = worldAt(phase), out = { ...s };
  for (const L of LAYERS) out[L] = Math.max(0, layerLum(L, w.layers[L]));
  const mean = SCREEN_W.sky * skyMean(s) + LAYERS.reduce((a, L) => a + SCREEN_W[L] * out[L], 0);
  return { parts: out, mean };
}
// as slewStep in keys.mjs, but no band and no layer may change faster than the band budget, and the screen's mean no faster than the mean budget
export function slewAll(p, target, dt) {
  const d = ((target - p + 1.5) % 1) - 0.5;
  if (Math.abs(d) < 1e-9) return p;
  const sign = Math.sign(d), base = lumsAll(p);
  const okAt = s => { const b = lumsAll(p + sign * s); if (Math.abs(b.mean - base.mean) / dt > BUDGET.place.mean) return false; for (const k of Object.keys(base.parts)) if (Math.abs(b.parts[k] - base.parts[k]) / dt > BUDGET.place.band) return false; return true; };
  let lo = 0, hi = Math.abs(d);
  if (okAt(hi)) return (p + sign * hi + 1) % 1;
  for (let i = 0; i < 30; i++) { const mid = (lo + hi) / 2; if (okAt(mid)) lo = mid; else hi = mid; }
  return (p + sign * lo + 1) % 1;
}

// the readability checks: at every key and mood extreme, the fighters' bodies against the tinted ground, and the (undimmed) auras against the tinted ground
export function checks() {
  const AURA = { protagonist: '#8fd6ff', rival: '#9a80d8' }, out = {};
  let wb = [99], wa = [99];
  for (const k of KEYS) {
    const t = WORLD[k.id]; let b = [99], a = [99];
    for (const mood of [null, 'frenzy', 'ruin']) {
      const mm = l => (mood ? WORLD_MOOD[mood][l] : [1, 1, 1]);
      for (const [bn, bc] of Object.entries(BIOME)) {
        const g = tinted(bc, t.ground, mm('ground'));
        for (const [fn, fc] of Object.entries(BODY)) { const d = dE00(tinted(fc, t.bodies, mm('bodies')), g); if (d < b[0]) b = [d, fn, bn, mood ?? 'calm']; }
        for (const [an, ac] of Object.entries(AURA)) { const d = dE00(ac, g); if (d < a[0]) a = [d, an, bn, mood ?? 'calm']; }
      }
    }
    out[k.id] = { body_vs_ground: b, aura_vs_ground: a }; if (b[0] < wb[0]) wb = b; if (a[0] < wa[0]) wa = a;
  }
  return { by_key: out, worst_body_vs_ground: wb, worst_aura_vs_ground: wa };
}
