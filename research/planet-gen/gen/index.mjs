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
import { buildErosion, readErosion, riverAt, PC } from './erosion.mjs';
import { withPoles, PP } from './poles.mjs';
import { floes } from './floes.mjs';

// The floes (gen/floes.mjs): on sea cold enough for ice, today's floes, leads and bergs over the climate's sea ice. Floes
// need the sea at -1 deg C or colder: the sea-level temperature is 28 - 30a^2 - 18a^4 plus at most 3 deg C of noise below,
// which stays above -1 while the belt's a < 0.7932, and a is at most |y| + beltAmp. So below FLOE_Y the test is skipped
// without changing a result (it assumes tNoise 6 and the floes' bergT -1).
const FLOE_Y = 0.79 - PA.beltAmp;
function iced(seed, clim, x, y, z, h) {
  if (h >= 0.0 || (y < 0.0 ? -y : y) < FLOE_Y) return null;
  return floes(seed, x, y, z, h, clim.seaLevelT(seed, x, y, z));
}

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
  const E = buildErosion((x, y, z) => g(seed, x, y, z), (x, y, z, h) => clim.precip(seed, x, y, z, h), PC, seed);
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
    if (h < 0.0 && (y < 0.0 ? -y : y) >= FLOE_Y) { const f = floes(seed, x, y, z, h, r[2]); if (f) return [f[0], f[1], 0]; }
    let b = r[1];
    // a river on an ice sheet or a snowcap is frozen: no channel, no water (the ice's own height, uncarved)
    if (river > 0 && (b === B.ICE_SHEET || b === B.SNOW)) { const hu = h0 + dh; return [h0 >= 0.0 && hu < 1.0 ? 1.0 : hu, b, 0]; }
    if (h > 0.0 && volc > PB.volcanic && notCold(b)) b = B.VOLCANIC;
    else if (h > 0.0 && r[3] < 500.0 && r[2] > 8.0 && dh < -110.0 && b !== B.BEACH) b = B.BADLANDS;
    return [h, b, river > 0 ? 1 : 0];
  };
  return st;
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
    sample: (st, x, y, z) => { const r = climA.sample(st.seed, x, y, z); const f = iced(st.seed, climA, x, y, z, r[0]); return f ? [f[0], f[1], 0] : [r[0], r[1], 0]; },
  },
  B: {
    title: 'B PLATES', params: { plates: PB, climate: PA, poles: PP },
    init: (seed) => ({ seed, ...plateState(seed) }),
    sample: (st, x, y, z) => {
      const h = st.g(st.seed, x, y, z), v = st.S.volc;   // read before the climate's march overwrites it
      const f = iced(st.seed, st.clim, x, y, z, h);
      if (f) return [f[0], f[1], 0];
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
