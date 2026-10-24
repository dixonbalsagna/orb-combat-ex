// Origin: the energy colour lanes' sheet, data and doc (deterministic, no randomness, no external images or fonts). Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-24.
// Human direction: Orb, via the EP (the energy overhaul: each fighter's lane for bolts, lobs, beams, grabs and traps). Shapes are neutral sketches of each kind, not final VFX art: the colours are the deliverable.
// Run from the repo root:  node art/concepts/energy/gen.mjs
//   -> art/concepts/energy/energy-lanes.svg, data/art/energy-lanes.json, docs/art/energy-lanes.md, docs/art/pending/art-energy-lanes.schema.json
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { simulate, dE00 } from '../sky/colour.mjs';
import { WORLD, tinted } from '../sky/world.mjs';
import { BIOMES } from '../biomes/spec.mjs';
import { LANES, KINDS, redReport, biomeReport, distinct } from './lanes.mjs';
import { worst } from './trial.mjs';

const OUT = dirname(fileURLToPath(import.meta.url)), ROOT = join(OUT, '..', '..', '..');
const F = n => (Math.round(n * 100) / 100).toString();
const INK = '#1b1428', BG = '#e8e5ee', KEY = '#0a0d14', VIS = ['default', 'protan', 'deutan', 'tritan'];
const esc = t => String(t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const FONT = "font-family=\"'Segoe UI', system-ui, -apple-system, Helvetica, Arial, sans-serif\"";
const text = (x, y, t, { size = 12, weight = 400, fill = INK, anchor = 'start' } = {}) => `<text x="${F(x)}" y="${F(y)}" ${FONT} font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}">${esc(t)}</text>`;
const rect = (x, y, w, h, fill, extra = '') => `<rect x="${F(x)}" y="${F(y)}" width="${F(w)}" height="${F(h)}" fill="${fill}" ${extra}/>`;
const wrap = (t, n) => { const w = t.split(' '), out = []; let line = ''; for (const x of w) { if ((line + ' ' + x).trim().length > n) { out.push(line.trim()); line = x; } else line += ' ' + x; } if (line.trim()) out.push(line.trim()); return out; };
const paras = (x, y, t, n, size = 12, gap = 15, o = {}) => wrap(t, n).map((l, i) => text(x, y + i * gap, l, { size, ...o })).join('');

// ---- shapes (centre origin, about 104 wide): [kind of drawing, points]
const SHAPES = {
  generic: {
    bolt: ['fill', [[-48, 0], [-14, -14], [40, -8], [50, 0], [40, 8], [-14, 14]]],
    lob: ['fill', [[-26, 0], [-13, -23], [13, -23], [26, 0], [13, 23], [-13, 23]]],
    beam: ['fill', [[-52, -6], [-46, -14], [46, -14], [52, -6], [52, 6], [46, 14], [-46, 14], [-52, 6]]],
    grab: ['ring', [[-24, 0], [-12, -21], [12, -21], [24, 0], [12, 21], [-12, 21]]],
    trap: ['ring', [[-40, 0], [0, -17], [40, 0], [0, 17]]],
  },
  cyborg: { // wreckage and metal: shard, slag lump, vent jet, crane hook, pit
    bolt: ['fill', [[-46, 3], [-20, -14], [4, -8], [18, -19], [44, -2], [18, 10], [0, 16], [-24, 12]]],
    lob: ['fill', [[-24, 4], [-18, -16], [-2, -24], [16, -18], [26, 0], [18, 18], [-4, 24], [-20, 17]]],
    beam: ['fill', [[-52, -8], [-20, -12], [20, -20], [52, -27], [52, 27], [20, 20], [-20, 12], [-52, 8]]],
    grab: ['ring', [[-4, -26], [10, -26], [10, 2], [24, 12], [14, 26], [-14, 24], [-24, 8], [-12, 8], [-8, 14], [0, 14], [-4, 4]]],
    trap: ['ring', [[-36, 2], [-18, -14], [-4, -8], [12, -16], [36, 0], [18, 14], [2, 10], [-16, 16]]],
  },
  empress: { // lines, not balls: a blade of light, a tumbling block, a thin line, a loop, two ropes
    bolt: ['fill', [[-50, 0], [-22, -4], [46, -2], [54, 0], [46, 2], [-22, 4]]],
    lob: ['fill', [[-6, -26], [24, -10], [8, 24], [-24, 8]]],
    beam: ['fill', [[-52, -5], [-48, -9], [48, -9], [52, -5], [52, 5], [48, 9], [-48, 9], [-52, 5]]],
    grab: ['ring', [[-26, 0], [-12, -17], [12, -17], [26, 0], [12, 17], [-12, 17]]],
    trap: ['ropes', [[-42, -9], [42, -9], [-42, 9], [42, 9]]],
  },
};
const shapesOf = id => SHAPES[id] || SHAPES.generic;
const pts = (a, cx, cy, sx, sy) => a.map(([x, y]) => F(cx + x * sx) + ',' + F(cy + y * sy)).join(' ');
export function sprite(id, kind, cx, cy, sc = 1) {
  const L = LANES[id][kind], [how, p] = shapesOf(id)[kind];
  if (how === 'fill') {
    const key = `<polygon points="${pts(p, cx, cy, sc, sc)}" fill="${L.edge}" stroke="${KEY}" stroke-width="${F(3 * sc)}" stroke-linejoin="round"/>`;
    return key + `<polygon points="${pts(p, cx, cy, 0.88 * sc, 0.62 * sc)}" fill="${L.main}"/>` + `<polygon points="${pts(p, cx, cy, 0.72 * sc, 0.3 * sc)}" fill="${L.core}"/>`;
  }
  if (how === 'ring') {
    const d = 'M ' + pts(p, cx, cy, sc, sc).split(' ').join(' L ') + ' Z', W = 15 * sc;
    return `<path d="${d}" fill="none" stroke="${KEY}" stroke-width="${F(W + 5 * sc)}" stroke-linejoin="round"/><path d="${d}" fill="none" stroke="${L.edge}" stroke-width="${F(W)}" stroke-linejoin="round"/><path d="${d}" fill="none" stroke="${L.main}" stroke-width="${F(W * 0.62)}" stroke-linejoin="round"/><path d="${d}" fill="none" stroke="${L.core}" stroke-width="${F(W * 0.24)}" stroke-linejoin="round"/>`;
  }
  const [a, b, c, d] = p, seg = (u, v) => `M ${F(cx + u[0] * sc)} ${F(cy + u[1] * sc)} L ${F(cx + v[0] * sc)} ${F(cy + v[1] * sc)}`, dd = seg(a, b) + ' ' + seg(c, d), W = 7 * sc;
  return [[W + 3 * sc, KEY], [W, L.edge], [W * 0.62, L.main], [W * 0.24, L.core]].map(([w, col]) => `<path d="${dd}" fill="none" stroke="${col}" stroke-width="${F(w)}" stroke-linecap="round"/>`).join('');
}

// ---- measurement
const measured = {};
for (const [id, lane] of Object.entries(LANES)) {
  const red = redReport(lane), m = { red_max_linear: +Math.max(...red.map(r => r.linear)).toFixed(3), red_max_stored: +Math.max(...red.map(r => r.stored)).toFixed(3), red_ok: red.every(r => r.ok), main_alone: {}, sprite: {}, sprite_with_keyline: {} };
  for (const v of VIS) {
    const rep = biomeReport(lane, v), e = Object.entries(rep).sort((a, b) => a[1].min - b[1].min);
    m.main_alone[v] = { worst: e[0][1].min, biome: e[0][0], at: e[0][1].at, kind: e[0][1].kind, below_need: e.filter(([, x]) => x.min < (v === 'default' ? 20 : 14)).map(([i]) => i) };
    const sp = KINDS.map(k => ({ k, ...worst([lane[k].core, lane[k].main, lane[k].edge], v) })).sort((a, b) => a.min - b.min)[0];
    m.sprite[v] = { worst: sp.min, biome: sp.id, at: sp.at, kind: sp.k };
    const sk = KINDS.map(k => ({ k, ...worst([lane[k].core, lane[k].main, lane[k].edge, KEY], v) })).sort((a, b) => a.min - b.min)[0];
    m.sprite_with_keyline[v] = { worst: sk.min };
  }
  measured[id] = m;
}
const ids = Object.keys(LANES), pairs = [];
for (let i = 0; i < ids.length; i++) for (let j = i + 1; j < ids.length; j++) pairs.push({ a: ids[i], b: ids[j], ...Object.fromEntries(VIS.map(v => [v, distinct(LANES[ids[i]], LANES[ids[j]], v).min])) });
const minPair = Object.fromEntries(VIS.map(v => [v, Math.min(...pairs.map(p => p[v]))]));

// ---- data
const lanesData = {};
for (const [id, l] of Object.entries(LANES)) {
  lanesData[id] = { name: l.name, family: l.family, light_colour: l.bolt.main, kinds: Object.fromEntries(KINDS.map(k => [k, l[k]])), ...(l.metal ? { metal: l.metal } : {}), _measure: measured[id] };
}
const data = {
  version: 1,
  note: 'Each fighter\'s energy colour lane for bolts, lobs, beams, grabs and traps (docs/art/energy-lanes.md, art/concepts/energy/energy-lanes.svg). Written by art/concepts/energy/gen.mjs; do not edit by hand. Proposal pending the EP, Combat, VFX and Legal; Tools adds the schema (docs/art/pending/art-energy-lanes.schema.json). Keys starting with an underscore are measurements and notes, not for the game to read.',
  rules: {
    parts: 'Each kind has three colours: core (the bright centre), main (the colour a player names it by) and edge (the darker rim); every sprite also carries the keyline (#0a0d14). Flat colours, no gradients, no blur, no fades. Energy is never dimmed by the world light.',
    saturated_red: 'No colour has R/(R+G+B) of 0.8 or more on stored OR linear values (Legal: red count 0, the flash check\'s strict reading). The data holds every colour under 0.78.',
    readability: 'The sprite (core, main, edge) is 20 or more CIEDE2000 from every ground, rock, vegetation, subsoil and water tone of the 15 biomes at every sky key with the world-light tint, and 14 or more under protan, deutan and tritan (Machado 2009, severity 1). The main colour alone does not meet it everywhere (see _measure.main_alone): the Protagonist\'s cyan misses on the open sea, beach shallows and the pale ices, the Rival\'s deep violet misses against dark water and dark ground on all 15 biomes, the Cyborg\'s orange misses on warm ground, the Empress\'s ivory on snow. The bright core and the dark edge carry the sprite (see _measure.sprite).',
    distinct: 'Mains of any two lanes are 25 or more apart by default and 20 or more under each simulation (docs/art/colour-vision.md rule 2).',
    cyborg: 'Wreckage and metal only (Legal): slag and scrap throw, never a person-shaped or body-part shape. The "metal" greys are for the scrap pieces that carry the glow.',
    empress: 'Lines, not balls (Legal): bolts and beams are thin blades and lines, the lob is a tumbling block, the trap is two ropes. Colour is ivory with a deep gold rim; no saturated red anywhere in the lane.',
  },
  lanes: lanesData,
  _distinct: pairs,
  _distinct_minimum: minPair,
};
writeFileSync(join(ROOT, 'data', 'art', 'energy-lanes.json'), JSON.stringify(data, null, 2) + '\n');

// ---- sheet
const W = 1500, LEFT = 40, LANEH = 400, TOP = 118;
let svg = '', y = 0;
svg += rect(0, 0, W, TOP + ids.length * LANEH + 330, BG);
svg += text(LEFT, 52, 'Energy colour lanes: bolts, lobs, beams, grabs and traps', { size: 30, weight: 700 });
svg += paras(LEFT, 80, 'Cyan to azure, violet to magenta, molten slag and scrap, ivory and deep gold. Each kind is a core (bright centre), a main (its name colour) and an edge (the dark rim), all inside the keyline. Flat colours only. Shapes are neutral sketches; the colours are the proposal. Red count 0 in every lane.', 190, 13, 17);
const NAMES = { bolt: 'Bolt', lob: 'Lob', beam: 'Beam', grab: 'Grab', trap: 'Trap' };
const BIOIDS = Object.values(BIOMES).sort((a, b) => a.order - b.order);
ids.forEach((id, li) => {
  const l = LANES[id], y0 = TOP + li * LANEH, m = measured[id];
  svg += rect(LEFT - 12, y0, W - 2 * LEFT + 24, LANEH - 14, '#f4f2f8', 'rx="6"');
  svg += text(LEFT, y0 + 28, l.name, { size: 21, weight: 700 }) + text(LEFT + 330, y0 + 28, l.family, { size: 13 });
  // the five kinds on a mid-grey ground, with hex
  KINDS.forEach((k, i) => {
    const x0 = LEFT + i * 280, cx = x0 + 120, cy = y0 + 92;
    svg += rect(x0, y0 + 42, 252, 100, '#6f7480') + sprite(id, k, cx, cy, 1.1);
    svg += text(x0, y0 + 156, NAMES[k], { size: 13, weight: 700 }) + text(x0 + 46, y0 + 156, 'core ' + l[k].core + '  main ' + l[k].main + '  edge ' + l[k].edge, { size: 10 });
  });
  // the fifteen biomes: ground and rock at noon with the beam and the bolt across
  svg += text(LEFT, y0 + 190, 'On the fifteen biomes at noon (ground above, rock below), beam and bolt', { size: 12, weight: 700 });
  BIOIDS.forEach((b, i) => {
    const bx = LEFT + i * 91.5, by = y0 + 198, bw = 86, bh = 62, gnd = tinted(b.pal.g[1], WORLD.noon.ground), rock = tinted(b.pal.r[1], WORLD.noon.ground);
    svg += rect(bx, by, bw, bh * 0.62, gnd) + rect(bx, by + bh * 0.62, bw, bh * 0.38, rock);
    svg += sprite(id, 'beam', bx + bw / 2, by + 16, 0.5) + sprite(id, 'bolt', bx + bw / 2, by + 44, 0.44);
    svg += text(bx + bw / 2, by + bh + 13, b.id, { size: 9.5, anchor: 'middle' });
  });
  // colour-vision: the mains, simulated
  svg += text(LEFT, y0 + 296, 'Mains under the colour-vision presets', { size: 12, weight: 700 });
  VIS.forEach((v, vi) => {
    const gx = LEFT + vi * 360;
    svg += text(gx, y0 + 314, v, { size: 11 });
    KINDS.forEach((k, i) => { svg += rect(gx + i * 42, y0 + 320, 38, 22, simulate(l[k].main, v), `stroke="${KEY}" stroke-width="1.5"`); });
  });
  const mm = m.main_alone, sp = m.sprite;
  svg += text(LEFT, y0 + 362, `Whole sprite vs every biome tone at every key: default ${sp.default.worst}, protan ${sp.protan.worst}, deutan ${sp.deutan.worst}, tritan ${sp.tritan.worst} (need 20 / 14 / 14 / 14).`, { size: 11 });
  svg += text(LEFT, y0 + 378, `Main alone, worst: default ${mm.default.worst} (${mm.default.biome}), protan ${mm.protan.worst}, deutan ${mm.deutan.worst}, tritan ${mm.tritan.worst}.   Red share, highest colour: linear ${m.red_max_linear}, stored ${m.red_max_stored} (limit 0.8).`, { size: 11 });
});
const fy = TOP + ids.length * LANEH + 6;
svg += text(LEFT, fy + 20, 'Lanes apart (smallest gap between any two mains, CIEDE2000; need 25 default, 20 simulated)', { size: 14, weight: 700 });
pairs.forEach((p, i) => { const cx = LEFT + (i % 3) * 470, cy = fy + 46 + Math.floor(i / 3) * 22; svg += text(cx, cy, `${p.a} / ${p.b}: ${VIS.map(v => v + ' ' + p[v]).join(', ')}`, { size: 11.5 }); });
svg += paras(LEFT, fy + 124, 'How to read the checks: warm hues cannot clear 20 against warm ground (desert, savanna, beach, the golden hours) with the main colour alone, and ivory cannot against snow, so every lane is judged as a whole sprite: the bright core and the dark edge (plus the keyline) each separate from a different kind of ground. The main colour alone misses 20 on some biomes in every lane (the numbers are above and in the doc). Flat colours only; Legal\'s notes (the Cyborg only throws wreckage and metal, the Empress only lines and blocks) are in the data.', 190, 12.5, 16);
svg += paras(LEFT, fy + 200, 'Originality: cyan and violet energy are generic genre colours; the Empress\'s ivory-and-gold lane and the Cyborg\'s slag-and-scrap are our own. No franchise colour scheme is copied.', 190, 12.5, 16);
const sheet = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${TOP + ids.length * LANEH + 330}" viewBox="0 0 ${W} ${TOP + ids.length * LANEH + 330}">\n${svg}\n</svg>\n`;
mkdirSync(OUT, { recursive: true });
writeFileSync(join(OUT, 'energy-lanes.svg'), sheet);

// ---- schema draft for Tools
const hex = { type: 'string', pattern: '^#[0-9a-fA-F]{6}$' };
const kindSchema = { type: 'object', required: ['core', 'main', 'edge'], additionalProperties: false, properties: { core: hex, main: hex, edge: hex } };
const schema = {
  $schema: 'http://json-schema.org/draft-07/schema#', title: 'art-energy-lanes', description: 'data/art/energy-lanes.json: each fighter\'s energy colour lane (Art Director). Keys starting with an underscore are free-form notes and measurements.',
  type: 'object', required: ['version', 'note', 'rules', 'lanes'], additionalProperties: false, patternProperties: { '^_': {} },
  properties: {
    version: { type: 'integer', const: 1 }, note: { type: 'string' }, rules: { type: 'object', additionalProperties: { type: 'string' } },
    lanes: { type: 'object', required: ids, additionalProperties: false, properties: Object.fromEntries(ids.map(id => [id, { type: 'object', required: ['name', 'family', 'light_colour', 'kinds'], additionalProperties: false, patternProperties: { '^_': {} }, properties: { name: { type: 'string' }, family: { type: 'string' }, light_colour: hex, kinds: { type: 'object', required: KINDS, additionalProperties: false, properties: Object.fromEntries(KINDS.map(k => [k, kindSchema])) }, metal: { type: 'object', required: ['light', 'mid', 'dark'], additionalProperties: false, properties: { light: hex, mid: hex, dark: hex } } } }])) },
  },
};
mkdirSync(join(ROOT, 'docs', 'art', 'pending'), { recursive: true });
writeFileSync(join(ROOT, 'docs', 'art', 'pending', 'art-energy-lanes.schema.json'), JSON.stringify(schema, null, 2) + '\n');

// ---- doc
let md = `# Energy colour lanes\n\nOwner: Art Director. 2026-10-24. **Generated** by \`art/concepts/energy/gen.mjs\` (\`node art/concepts/energy/gen.mjs\`); the data is \`data/art/energy-lanes.json\`, the one-sheet \`art/concepts/energy/energy-lanes.svg\`. The brief: each fighter's colour lane for bolts, lobs, beams, grabs and traps (the energy overhaul; Combat's kits are in \`docs/combat/pending/energy/\`). Proposal; the EP, Combat, VFX and Legal decide.\n\n`;
md += `## 1. The four lanes\n\nEach kind has a **core** (the bright centre), a **main** (the colour a player names it by) and an **edge** (the dark rim), inside the keyline (#0a0d14). Flat colours, no gradients, no blur, no fades. Energy is never dimmed by the world light.\n\n`;
for (const [id, l] of Object.entries(LANES)) {
  md += `### ${l.name}: ${l.family}\n\n| Kind | Core | Main | Edge |\n|---|---|---|---|\n` + KINDS.map(k => `| ${NAMES[k]} | ${l[k].core} | ${l[k].main} | ${l[k].edge} |`).join('\n') + '\n\n';
}
md += `- **Protagonist.** Cyan on the bolt, sliding to azure on the beam (the hue moves with the kind's size, so the family reads at a glance). The old placeholder (#22d3ee) is the cyan of the bolt, made slightly deeper (#10c2ea).\n- **Rival.** Deep violet on the bolt, magenta on the beam. Darker than the placeholder (#8a3cff) on purpose: against the Protagonist's pale cyan it is the lightness gap that survives deutan and protan sight.\n- **Demon Cyborg.** Molten slag oranges with a near-black iron edge and a hot pale core. Orange only, never a red: the placeholder #ff6a1a is 0.87 red share on linear values and would count as saturated red in the strict flash check; these are all 0.77 or less. The scrap-metal greys (\`metal\`) are for the wreckage the glow sits on. Wreckage and metal only (Legal).\n- **Empress.** **Ivory with a deep gold rim.** The crimson placeholder (#d81f3c) is out (saturated red, Legal's count is 0). Why ivory and not deep gold or dark rose: gold sits on the Cyborg's orange (13 apart, and 1.4 under protan), a dark rose sits on the Rival's magenta, and ivory is the one lane that is nearly colourless, so it is distinct from all three and regal by being the light itself, edged in gold. Lines, not balls (Legal): a thin blade, a tumbling block, a thin line, a loop, two ropes.\n\n`;
md += `## 2. The checks\n\n**Saturated red.** R/(R+G+B) under 0.78 on stored and linear values for every colour in every lane (the limit is 0.8). Maximums: ` + ids.map(id => `${id} linear ${measured[id].red_max_linear}, stored ${measured[id].red_max_stored}`).join('; ') + `.\n\n`;
md += `**Readability on the 15 biomes** (every ground, rock, vegetation, subsoil and water tone, at every sky key with the world-light tint; energy is not tinted). The aura rule is 20 CIEDE2000 and 14 under each colour-vision simulation. The whole sprite (core, main, edge) passes in every lane; the keyline adds margin. The main colour alone does not pass everywhere (below).\n\n| Lane | Sprite default | protan | deutan | tritan | Main alone default (worst biome) | protan | deutan | tritan |\n|---|---|---|---|---|---|---|---|---|\n`;
for (const id of ids) { const m = measured[id]; md += `| ${id} | ${m.sprite.default.worst} | ${m.sprite.protan.worst} | ${m.sprite.deutan.worst} | ${m.sprite.tritan.worst} | ${m.main_alone.default.worst} (${m.main_alone.default.biome}) | ${m.main_alone.protan.worst} | ${m.main_alone.deutan.worst} | ${m.main_alone.tritan.worst} |\n`; }
md += `\n**Why the main colour alone cannot always pass.** A search over every hue (\`art/concepts/energy/search.mjs\`) shows only light cyan to light violet (hues about 200 to 330, lightness 0.7 or more) clears 20 against all 15 biomes with one colour; oranges and golds top out at about 8 to 9 against the desert, savanna and beach ground at the golden hours, and ivory at about 6 against snow and ice. The Rival's deep violet (lightness about 0.4 to 0.5) misses against dark water and dark ground on purpose: a light violet sat 15.6 from the Protagonist's cyan under deutan sight (need 20), and the lightness gap is what keeps them apart. All four lanes are therefore judged as a whole: the hot pale core separates from dark ground, the dark edge from pale or warm ground. A small or fast sprite (a thin Empress line, a Cyborg slag shard) is the risk: VFX should keep the dark edge at least 2 px at fight size, and not drop the keyline.\n\n`;
md += `**Lanes apart** (smallest gap between any two mains over every kind pair; need 25 default and 20 simulated, docs/art/colour-vision.md rule 2):\n\n| Pair | default | protan | deutan | tritan |\n|---|---|---|---|---|\n` + pairs.map(p => `| ${p.a} / ${p.b} | ${p.default} | ${p.protan} | ${p.deutan} | ${p.tritan} |`).join('\n') + `\n\nSmallest: default ${minPair.default}, protan ${minPair.protan}, deutan ${minPair.deutan}, tritan ${minPair.tritan}.\n\n`;
md += `## 3. For other directors\n\n- **Combat:** the four \`light.colour\` values in \`energy.*.json\` become the \`light_colour\` of each lane (the bolt main): protagonist ${LANES.protagonist.bolt.main}, rival ${LANES.rival.bolt.main}, cyborg ${LANES.cyborg.bolt.main}, empress ${LANES.empress.bolt.main}. The Empress's \`/colour\` (#d81f3c) goes to the ivory main of her bolt. Per kind colours are in \`data/art/energy-lanes.json\` (\`lanes.<id>.kinds.<bolt|lob|beam|grab|trap>.{core,main,edge}\`).\n- **VFX:** flat fills in this order, edge then main then core, inside a keyline of at least 1 px; never dim by the world light; burst frames above 3 a second use the main and the edge only, peak frames use the core (Legal fx09: peak frames white-hot below the red ratio, which the cores are).\n- **Legal:** please check the lanes against fx09 and e15 and the saturated-red rule; the numbers are in the data.\n- **Tools:** a draft schema is in \`docs/art/pending/art-energy-lanes.schema.json\` (the file warns "no schema" until it is adopted). Underscore keys are free-form.\n- **Rendering:** nothing; the lanes are colours for VFX and Combat's light.\n`;
writeFileSync(join(ROOT, 'docs', 'art', 'energy-lanes.md'), md);
console.log('written; minimum lane gaps', JSON.stringify(minPair), 'red ok', ids.map(i => measured[i].red_ok).join());
