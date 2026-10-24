// Origin: the fighters' energy colour lanes and their checks (deterministic). Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-24. Human direction: Orb, via the EP (the energy overhaul: bolts, lobs, beams, grabs and traps).
// A lane is, per energy kind, three colours: core (the bright centre), main (the colour a player names it by) and edge (the darker rim). Every sprite also carries the dark keyline (#0a0d14), and energy is never dimmed by the world light (flashes and particles never are).
// The checks: (1) Legal's saturated-red rule: no colour in a lane has R/(R+G+B) of 0.8 or more, on stored OR linear values (the flash check's strict reading); we hold 0.78; (2) readability: the lane's main colour 20 or more CIEDE2000 from every ground, rock,
// vegetation, subsoil and water tone of the 15 biomes at every sky key (the aura rule), and 14 or more under protan, deutan and tritan; (3) the four lanes stay 25 or more apart by default and 20 under each simulation (docs/art/colour-vision.md rule 2).
import { toLin, dE00, simulate, hex2rgb, fromLin } from '../sky/colour.mjs';
import { WORLD, tinted } from '../sky/world.mjs';
import { KEYS } from '../sky/keys.mjs';
import { BIOMES } from '../biomes/spec.mjs';
import { tonesOf } from '../biomes/measure.mjs';

export const KINDS = ['bolt', 'lob', 'beam', 'grab', 'trap'];
const L = (core, main, edge) => ({ core, main, edge });
export const LANES = {
  protagonist: {
    name: 'The Protagonist', family: 'cyan to azure',
    bolt: L('#f2fdff', '#10c2ea', '#0b7fb8'), lob: L('#ecfaff', '#1eb0f4', '#0e6cc4'), beam: L('#f4faff', '#2e90f2', '#0d58c4'), grab: L('#ecfcff', '#1ca6f4', '#0c78c0'), trap: L('#e8f5ff', '#2a9cf4', '#0f62bc'),
  },
  rival: {
    name: 'The Rival', family: 'violet to magenta',
    bolt: L('#f0e6ff', '#4420c4', '#2e0c78'), lob: L('#f6e6ff', '#5c1ca8', '#3c0c6c'), beam: L('#ffe8fb', '#80127e', '#5a0c64'), grab: L('#f4e6ff', '#521ab4', '#340c78'), trap: L('#eee4ff', '#4c20ac', '#300c70'),
  },
  cyborg: {
    name: 'The Demon Cyborg', family: 'molten slag oranges, with scrap-metal grey (wreckage and metal only)',
    bolt: L('#ffe9b0', '#f58a22', '#4a2e20'), lob: L('#ffe0a0', '#e8821e', '#47291d'), beam: L('#fff4cc', '#fa9a2e', '#4a2e20'), grab: L('#ffe4a8', '#ec8a24', '#46291c'), trap: L('#ffdc98', '#e07c1e', '#40261a'),
    metal: { light: '#a6abb3', mid: '#767c86', dark: '#4a4f58' },
  },
  empress: {
    name: 'The Empress', family: 'ivory with a deep gold rim (lines, not balls)',
    bolt: L('#ffffff', '#fffefa', '#6b4c0e'), lob: L('#ffffff', '#fffbee', '#6b4c0e'), beam: L('#ffffff', '#ffffff', '#7a560e'), grab: L('#ffffff', '#fffaf0', '#5e420c'), trap: L('#ffffff', '#fff7e6', '#6b4c0e'),
  },
};

export const share = v => v[0] / Math.max(1e-9, v[0] + v[1] + v[2]);
export const redShare = hex => ({ linear: share(toLin(hex)), stored: share(hex2rgb(hex).map(v => v / 255)) });
const allColours = lane => KINDS.flatMap(k => ['core', 'main', 'edge'].map(p => [k + ' ' + p, lane[k][p]]));
export function redReport(lane) { return allColours(lane).map(([n, h]) => ({ n, h, ...redShare(h) })).map(r => ({ ...r, ok: r.linear < 0.78 && r.stored < 0.78 })); }

// biome tones: every tone of every biome at every key, tinted by that key's layer (the world is dimmed; the energy is not)
const TONES = []; for (const [id, b] of Object.entries(BIOMES)) for (const [name, hex, layer] of tonesOf(b)) for (const k of KEYS) TONES.push({ id, name, key: k.id, c: tinted(hex, WORLD[k.id][layer]) });
export function biomeReport(lane, vision = 'default') {
  const out = {};
  for (const id of Object.keys(BIOMES)) out[id] = { min: 99, at: '', kind: '' };
  for (const k of KINDS) { const m = simulate(lane[k].main, vision); for (const t of TONES) { const d = dE00(m, simulate(t.c, vision)); if (d < out[t.id].min) out[t.id] = { min: +d.toFixed(1), at: `${t.name} at ${t.key}`, kind: k }; } }
  return out;
}
export function distinct(a, b, vision = 'default') { let min = [99, '']; for (const k of KINDS) for (const k2 of KINDS) { const d = dE00(simulate(a[k].main, vision), simulate(b[k2].main, vision)); if (d < min[0]) min = [d, `${k} / ${k2}`]; } return { min: +min[0].toFixed(1), pair: min[1] }; }
if (process.argv[1].endsWith('lanes.mjs')) {
  for (const [id, lane] of Object.entries(LANES)) {
    const red = redReport(lane).filter(r => !r.ok);
    console.log(id.padEnd(12), 'red-test failures:', red.map(r => `${r.n} ${r.h} lin ${r.linear.toFixed(2)} sto ${r.stored.toFixed(2)}`).join('; ') || 'none');
    for (const v of ['default', 'protan', 'deutan', 'tritan']) { const r = biomeReport(lane, v), th = v === 'default' ? 20 : 14, bad = Object.entries(r).filter(([, x]) => x.min < th); console.log('  ', v.padEnd(8), 'worst', Math.min(...Object.values(r).map(x => x.min)).toFixed(1), 'below', th + ':', bad.map(([i, x]) => `${i} ${x.min} (${x.kind}, ${x.at})`).join('; ') || 'none'); }
  }
  const ids = Object.keys(LANES);
  for (let i = 0; i < ids.length; i++) for (let j = i + 1; j < ids.length; j++) console.log(ids[i], '/', ids[j], ['default', 'protan', 'deutan', 'tritan'].map(v => v + ' ' + distinct(LANES[ids[i]], LANES[ids[j]], v).min).join(', '));
}
