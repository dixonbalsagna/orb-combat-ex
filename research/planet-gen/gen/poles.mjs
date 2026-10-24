// The polar design without straight edges: today's planet blends to sea level past |y| 0.72 (the north pack) and lays a
// dome past 0.91 (the south sheet), which cuts continents along lines of latitude. Here the same intent is a noisy bias on
// the ground: the far north is pulled under the sea, the far south lifted into a continent; the climate's temperature then
// makes the sea ice and the ice sheet. World's floes and bergs (planet-ice.md) can sit on the climate's sea ice unchanged.
import { fbm, ss } from '../lib/det.mjs';

export const PP = { northY: 0.68, northW: 0.2, northH: 3200.0, northFull: 0.55, northSea: -500.0, southY: 0.76, southW: 0.16, southLand: 600.0, southKeep: 0.5, warpScale: 9000.0, warpAmp: 0.16, s: 4100 };

// The change to the ground at p (add it to the ground): the north sinks, the south becomes low land (ocean lifted to
// southLand, land kept at southKeep of its height plus southLand), so the ice there comes from the cold, not the height.
// Between the two bands the warp (at most warpAmp either way) cannot reach either, so the noise is skipped: n and s are
// then exactly 0, the bias is +0 or -0, and h plus either is h to the bit, so 0 is returned (2 octaves saved).
export function polarBias(seed, px, py, pz, P = PP, h = 0.0) {
  if (py + P.warpAmp <= P.northY && py - P.warpAmp >= -P.southY) return 0.0;
  const yy = py + (fbm(px, py, pz, P.warpScale, 2, seed + P.s) - 0.5) * 2.0 * P.warpAmp;
  const n = ss((yy - P.northY) / P.northW), s = ss((-yy - P.southY) / P.southW);
  // the north sinks by northH; past northFull of the way in, the ground is eased to northSea, both what still stands
  // (a high range) and the deep floor, so the pole is a shallow pack sea like today's (-380): open sea, and floes that
  // stand on it without becoming pillars over deep water
  let hn = h - P.northH * n;
  if (n > P.northFull) { const t = ss((n - P.northFull) / (1.0 - P.northFull)); hn += (P.northSea - hn) * t; }
  return (hn - h) + s * ((h > 0.0 ? h * P.southKeep : 0.0) + P.southLand - h);
}
export function withPoles(groundFn) {
  return (seed, px, py, pz) => { const h = groundFn(seed, px, py, pz); return h + polarBias(seed, px, py, pz, PP, h); };
}
