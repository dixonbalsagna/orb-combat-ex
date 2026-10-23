// The approaches: init(seed) builds any per-planet state (timed as the planet's set-up), sample(state, x, y, z) gives
// [height, biome, river flag] at a unit vector (timed per column on the fight ring).
//   base  today's WorldPlanet (bit-identical port), its 7 biomes
//   A     today's ground + the polar bias; biomes from the climate table (wind, rain shadow, Whittaker)
//   B     plate-lite ground + the polar bias; the same climate; volcanic fields from arcs, rifts and hotspots
//   C     erosion-lite over B's ground: carved valleys, lakes, rivers, badlands
//   Cb    erosion-lite over A's ground (the cheaper route if plates wait)
import { surf, ground, groundCoarse } from './base.mjs';
import { B, FROM_BASE } from '../lib/biomes.mjs';
import { makeClimate, PA } from './climate.mjs';
import { makePlates, plateGround, PB } from './plates.mjs';
import { buildErosion, readErosion, PC } from './erosion.mjs';
import { withPoles, PP } from './poles.mjs';
import { R } from '../lib/det.mjs';

const groundA = withPoles(ground);
const marchA = withPoles(groundCoarse);
const climA = makeClimate(groundA, PA, marchA);

function plateState(seed) {
  const S = makePlates(seed);
  const g = withPoles((s, x, y, z) => plateGround(S, x, y, z));
  const gm = withPoles((s, x, y, z) => plateGround(S, x, y, z, true));
  return { S, g, gm, clim: makeClimate(g, PA, gm) };
}
const notCold = (b) => b !== B.ICE_SHEET && b !== B.SNOW && b !== B.BEACH && b !== B.TUNDRA;

// Approach C on an input ground: the grid, then the ground plus the carve, lakes and rivers.
function erosionState(seed, g, gm, volcRead) {
  const clim = makeClimate(g, PA, gm);
  const E = buildErosion((x, y, z) => g(seed, x, y, z), (x, y, z, h) => clim.precip(seed, x, y, z, h));
  const st = { seed, E, clim };
  st.sample = (x, y, z) => {
    const h0 = g(seed, x, y, z);
    const volc = volcRead ? volcRead() : 0;
    const [dh, lake, , c] = readErosion(E, x, y, z);
    let h = h0 + dh;
    if (h0 >= 0.0 && h < 1.0) h = 1.0;             // the carve never drowns land into sea
    if (h >= 0.0 && lake >= h) return [lake, B.LAKE, 0];
    const river = h >= 0.0 ? riverAt(E, c, x, y, z) : 0;
    if (river > 0) { h -= PC.carve0 + PC.carve1 * Math.sqrt(river / PC.riverFlow); if (h < 1.0) h = 1.0; }
    const r = clim.sample(seed, x, y, z, h);
    let b = r[1];
    if (h > 0.0 && volc > PB.volcanic && notCold(b)) b = B.VOLCANIC;
    else if (h > 0.0 && r[3] < 500.0 && r[2] > 8.0 && dh < -110.0 && b !== B.BEACH) b = B.BADLANDS;
    return [h, b, river > 0 ? 1 : 0];
  };
  return st;
}

// A river at p: within a channel's half-width of a river segment (a cell centre to its receiver's) of p's cell or a neighbour.
function riverAt(E, c, px, py, pz) {
  const P = E.P, N = E.N;
  let best = 0;
  const f = Math.floor(c / (N * N)), j = Math.floor((c % (N * N)) / N), i = c % N;
  for (let dj = -1; dj <= 1; dj++) for (let di = -1; di <= 1; di++) {
    const ii = i + di, jj = j + dj;
    if (ii < 0 || jj < 0 || ii >= N || jj >= N) continue;
    const m = (f * N + jj) * N + ii, r = E.recv[m];
    if (E.flow[m] < P.riverFlow || r < 0 || E.h[m] < 0) continue;
    const ax = E.dir[m * 3], ay = E.dir[m * 3 + 1], az = E.dir[m * 3 + 2];
    const bx = E.dir[r * 3] - ax, by = E.dir[r * 3 + 1] - ay, bz = E.dir[r * 3 + 2] - az;
    const qx = px - ax, qy = py - ay, qz = pz - az;
    const bb = bx * bx + by * by + bz * bz;
    let t = bb > 0 ? (qx * bx + qy * by + qz * bz) / bb : 0; if (t < 0) t = 0; if (t > 1) t = 1;
    const ex = qx - bx * t, ey = qy - by * t, ez = qz - bz * t, d = Math.sqrt(ex * ex + ey * ey + ez * ez) * R;
    const half = 14.0 + 9.0 * Math.sqrt(E.flow[m] / P.riverFlow);
    if (d < half && E.flow[m] > best) best = E.flow[m];
  }
  return best;
}

export const APPROACHES = {
  base: {
    title: 'TODAY (WORLDPLANET)', params: {},
    init: (seed) => ({ seed }),
    sample: (st, x, y, z) => { const r = surf(st.seed, x, y, z); return [r[0], FROM_BASE[r[1]], 0]; },
  },
  A: {
    title: 'A CLIMATE', params: { climate: PA, poles: PP },
    init: (seed) => ({ seed, clim: climA }),
    sample: (st, x, y, z) => { const r = climA.sample(st.seed, x, y, z); return [r[0], r[1], 0]; },
  },
  B: {
    title: 'B PLATES', params: { plates: PB, climate: PA, poles: PP },
    init: (seed) => ({ seed, ...plateState(seed) }),
    sample: (st, x, y, z) => {
      const h = st.g(st.seed, x, y, z), v = st.S.volc;   // read before the climate's march overwrites it
      const b = st.clim.biome(st.seed, x, y, z, h);
      return [h, h > 0.0 && v > PB.volcanic && notCold(b) ? B.VOLCANIC : b, 0];
    },
  },
  C: {
    title: 'C EROSION ON B', params: { erosion: PC, plates: PB, climate: PA, poles: PP },
    init: (seed) => { const p = plateState(seed); return erosionState(seed, p.g, p.gm, () => p.S.volc); },
    sample: (st, x, y, z) => st.sample(x, y, z),
    overlay: true,
  },
  Cb: {
    title: 'C EROSION ON A', params: { erosion: PC, climate: PA, poles: PP },
    init: (seed) => erosionState(seed, groundA, marchA, null),
    sample: (st, x, y, z) => st.sample(x, y, z),
    overlay: true,
  },
};
