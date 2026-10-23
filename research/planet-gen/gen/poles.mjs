// The polar design without straight edges: today's planet blends to sea level past |y| 0.72 (the north pack) and lays a
// dome past 0.91 (the south sheet), which cuts continents along lines of latitude. Here the same intent is a noisy bias on
// the ground: the far north is pulled under the sea, the far south lifted into a continent; the climate's temperature then
// makes the sea ice and the ice sheet. World's floes and bergs (planet-ice.md) can sit on the climate's sea ice unchanged.
import { fbm, ss } from '../lib/det.mjs';

export const PP = { northY: 0.68, northW: 0.2, northH: 3200.0, southY: 0.76, southW: 0.16, southLand: 600.0, southKeep: 0.5, warpScale: 9000.0, warpAmp: 0.16, s: 4100 };

// The change to the ground at p (add it to the ground): the north sinks, the south becomes low land (ocean lifted to
// southLand, land kept at southKeep of its height plus southLand), so the ice there comes from the cold, not the height.
export function polarBias(seed, px, py, pz, P = PP, h = 0.0) {
  const yy = py + (fbm(px, py, pz, P.warpScale, 2, seed + P.s) - 0.5) * 2.0 * P.warpAmp;
  const n = ss((yy - P.northY) / P.northW), s = ss((-yy - P.southY) / P.southW);
  return -P.northH * n + s * ((h > 0.0 ? h * P.southKeep : 0.0) + P.southLand - h);
}
export function withPoles(groundFn) {
  return (seed, px, py, pz) => { const h = groundFn(seed, px, py, pz); return h + polarBias(seed, px, py, pz, PP, h); };
}
