// The schema for data/combat/depth.json (Simulation's fighters-in-depth core: sim/core/depth.gd, docs/architecture/depth-core.md; the parked build docs/architecture/pending/depth-a/):
// tools/schemas/combat-depth.schema.json (schema string "combat.depth/1", optional: Simulation's file carries none, so the version-field rule of the self-test is waived for it, NO_VERSION in
// tools/lib/selftest.js), its map.json line and the cases. NOT run by CI, the validator or the sim, and it REFUSES until data/combat/depth.json is in the tree (a schema with no document fails the
// data job's coverage check). Run once from the repo root, in the commit that lands the file:
//     node docs/tools/pending/apply-combat-depth.cjs
// It does NOT edit data/. Re-runnable (a second run changes nothing). Policy: closed except keys starting with an underscore (Simulation keeps a `_note` beside every number).
// enabled: the one switch (boolean). maxBhPerSec: the cap, in body heights a second (above 0). faceMarginBh: how far a fighter keeps from a standing building's face (0 or more).
// capExempt: the causes of depth the cap does not hold, distinct, each one of push, carry, home, magnet, shove, sidestep, giveGround (SimDepth.CAUSES).
// director (optional: the director's own depth numbers, which Encounter's d1a.cjs adds in its window): lineSinMin and lineSinMax (the sines of the least and the most angle a brawl's line makes with
// the street, 0 to 1, the least at most the most: rule depth-line-order), arriveSin (0 to 1), homeAfterTicks (whole ticks), homeBhPerSec (above 0).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const F = 'data/combat/depth.json';
if (!fs.existsSync(F)) { console.error(`${F} is not in the tree yet: run this in the commit that lands it`); process.exit(1); }
const live = rj(F);
const CAUSES = ['push', 'carry', 'home', 'magnet', 'shove', 'sidestep', 'giveGround'];
const closed = { additionalProperties: false, patternProperties: { '^_': true } };

{
  const f = 'tools/schemas/combat-depth.schema.json';
  const s = Object.assign({
    $schema: 'https://json-schema.org/draft/2020-12/schema',
    $id: 'meridian/combat-depth',
    title: 'fighters in depth: the core\'s numbers (Simulation, sim/core/depth.gd)',
    description: 'data/combat/depth.json: the switch and the numbers of a fighter\'s depth outside a flight (docs/architecture/depth-core.md): `enabled` (false until the director\'s depth window; with it off nothing here is read by a match), `maxBhPerSec` (the cap on a drift in depth, in body heights a second), `faceMarginBh` (how far a fighter keeps from a standing building\'s face) and `capExempt` (the causes of depth the cap does not hold: push, carry, home, magnet, shove, sidestep, giveGround). An optional `schema` string, "combat.depth/1", is accepted (the file carries none today, so the version-field rule is waived for this schema in tools/lib/selftest.js). Policy: closed except keys starting with an underscore.',
    type: 'object',
    required: ['enabled', 'maxBhPerSec', 'faceMarginBh', 'capExempt'],
    properties: {
      schema: { const: 'combat.depth/1' },
      enabled: { type: 'boolean', description: 'The one switch: fighters in depth on or off (a setup may set its own "depth").' },
      maxBhPerSec: { type: 'number', exclusiveMinimum: 0, description: 'The cap: the most a drift in depth moves a fighter, in body heights a second, outside a flight or a rush.' },
      faceMarginBh: { type: 'number', minimum: 0, description: 'A fighter outside a flight keeps his centre this far from a standing building\'s face, in body heights.' },
      director: {
        type: 'object',
        required: ['lineSinMin', 'lineSinMax', 'arriveSin', 'homeAfterTicks', 'homeBhPerSec'],
        properties: {
          lineSinMin: { type: 'number', minimum: 0, maximum: 1, description: 'The sine of the least angle a brawl line makes with the street.' },
          lineSinMax: { type: 'number', minimum: 0, maximum: 1, description: 'The sine of the most angle (at least lineSinMin: depth-line-order).' },
          arriveSin: { type: 'number', minimum: 0, maximum: 1, description: 'An approach ends this share of its street offset to one side in depth, as a sine.' },
          homeAfterTicks: { type: 'integer', minimum: 0, description: 'Ticks a fighter waits before easing back to his home depth.' },
          homeBhPerSec: { type: 'number', exclusiveMinimum: 0, description: 'How fast he eases back, in body heights a second.' },
        },
        additionalProperties: false,
        patternProperties: { '^_': true },
        description: 'Optional. The directors own depth numbers (sim/director/brawl.gd; docs/director/depth-d1.md).',
      },
      capExempt: {
        type: 'array',
        uniqueItems: true,
        items: { enum: CAUSES },
        description: 'The causes of depth the cap does not hold (distinct): ' + CAUSES.join(', ') + '.',
      },
    },
  }, closed);
  wj(f, s);
  const mf = 'tools/schemas/map.json';
  const m = rj(mf);
  if (!m.rules.some((r) => r.match === F)) {
    const i = m.rules.findIndex((r) => r.match === 'data/combat/recipes.json');
    m.rules.splice(i < 0 ? m.rules.length : i + 1, 0, { match: F, schema: 'combat-depth.schema.json' });
    wj(mf, m);
  }
  const sf = 'tools/lib/selftest.js';
  let t = fs.readFileSync(sf, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  if (!t.includes("'combat-depth.schema.json'")) {
    const m2 = t.match(/const NO_VERSION = new Set\(\[([^\]]*)\]\)/);
    if (!m2) throw new Error('NO_VERSION anchor');
    const body = m2[1].trim();
    t = t.replace(m2[0], `const NO_VERSION = new Set([${body ? body + ', ' : ''}'combat-depth.schema.json'])`);
    fs.writeFileSync(sf, crlf ? t.replace(/\n/g, '\r\n') : t);
  }
}

{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const out = [];
  const cs = (id, mutate, expect) => out.push({ id: 'combat-depth-' + id, schema: 'combat-depth.schema.json', mutate: [Object.assign({ file: F }, mutate)], expect });
  cs('valid', { set: { '/enabled': false } }, null);
  for (const k of ['enabled', 'maxBhPerSec', 'faceMarginBh', 'capExempt']) cs('key-required-' + k.toLowerCase(), { del: ['/' + k] }, { rule: 'required', pointer: '' });
  cs('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' });
  cs('underscore-key-ok', { set: { '/_why': 'a note' } }, null);
  cs('schema-version-ok', { set: { '/schema': 'combat.depth/1' } }, null);
  cs('schema-version-wrong', { set: { '/schema': 'combat.depth/2' } }, { rule: 'const', pointer: '/schema' });
  cs('enabled-type', { set: { '/enabled': 'yes' } }, { rule: 'type', pointer: '/enabled' });
  cs('enabled-true-ok', { set: { '/enabled': true } }, null);
  cs('max-zero', { set: { '/maxBhPerSec': 0 } }, { rule: 'exclusiveMinimum', pointer: '/maxBhPerSec' });
  cs('max-negative', { set: { '/maxBhPerSec': -1 } }, { rule: 'exclusiveMinimum', pointer: '/maxBhPerSec' });
  cs('max-type', { set: { '/maxBhPerSec': 'fast' } }, { rule: 'type', pointer: '/maxBhPerSec' });
  cs('max-small-ok', { set: { '/maxBhPerSec': 0.01 } }, null);
  cs('margin-negative', { set: { '/faceMarginBh': -0.1 } }, { rule: 'minimum', pointer: '/faceMarginBh' });
  cs('margin-type', { set: { '/faceMarginBh': 'wide' } }, { rule: 'type', pointer: '/faceMarginBh' });
  cs('margin-zero-ok', { set: { '/faceMarginBh': 0 } }, null);
  cs('cap-exempt-type', { set: { '/capExempt': 'shove' } }, { rule: 'type', pointer: '/capExempt' });
  cs('cap-exempt-empty-ok', { set: { '/capExempt': [] } }, null);
  cs('cap-exempt-unknown', { set: { '/capExempt': ['shove', 'slide'] } }, { rule: 'enum', pointer: '/capExempt/1' });
  cs('cap-exempt-item-type', { set: { '/capExempt': [1] } }, { rule: 'enum', pointer: '/capExempt/0' });
  cs('cap-exempt-duplicate', { set: { '/capExempt': ['push', 'push'] } }, { rule: 'uniqueItems', pointer: '/capExempt/1' });
  cs('cap-exempt-all-ok', { set: { '/capExempt': CAUSES } }, null);
  const DIR = { lineSinMin: 0.1736, lineSinMax: 0.5, arriveSin: 0.342, homeAfterTicks: 30, homeBhPerSec: 0.5 };
  cs('director-ok', { set: { '/director': DIR } }, null);
  cs('director-required', { set: { '/director': { lineSinMin: 0.1, lineSinMax: 0.5 } } }, { rule: 'required', pointer: '/director' });
  cs('director-unknown-key', { set: { '/director': { ...DIR, extra: 1 } } }, { rule: 'additionalProperties', pointer: '/director/extra' });
  cs('director-sine-above-one', { set: { '/director': { ...DIR, lineSinMax: 1.5 } } }, { rule: 'maximum', pointer: '/director/lineSinMax' });
  cs('director-ticks-integer', { set: { '/director': { ...DIR, homeAfterTicks: 2.5 } } }, { rule: 'type', pointer: '/director/homeAfterTicks' });
  cs('director-home-zero', { set: { '/director': { ...DIR, homeBhPerSec: 0 } } }, { rule: 'exclusiveMinimum', pointer: '/director/homeBhPerSec' });
  cs('director-line-order', { set: { '/director': { ...DIR, lineSinMin: 0.6 } } }, { rule: 'xref:depth-line-order', pointer: '/director/lineSinMin' });
  cs('director-line-equal-ok', { set: { '/director': { ...DIR, lineSinMin: 0.5 } } }, null);
  let n = 0;
  for (const k of out) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (!same(c.cases[i], k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`combat depth schema applied (${n} new or changed cases; the file has ${Object.keys(live).filter((k) => !k.startsWith('_')).length} keys)`);
}

{
  const f = 'docs/tools/README.md';
  const t = fs.readFileSync(f, 'utf8');
  void t;
}

// ---- the cross-reference: the director's least line angle is at most its most
{
  const xf = 'tools/lib/xref-fight.js';
  let x = fs.readFileSync(xf, 'utf8');
  const CR = String.fromCharCode(13), LF = String.fromCharCode(10);
  const crlf = x.includes(CR + LF);
  if (crlf) x = x.split(CR + LF).join(LF);
  if (x.includes('depth-line-order')) console.log('xref: already');
  else {
    const a = "  // ---- fight shots: a lobbed kind has both its numbers";
    if (!x.includes(a)) throw new Error('depth xref anchor');
    const block = [
      "  // ---- combat depth: the directors least line angle is at most its most",
      "  const depthD = get('data/combat/depth.json');",
      "  if (isObj(depthD) && isObj(depthD.director) && typeof depthD.director.lineSinMin === 'number' && typeof depthD.director.lineSinMax === 'number' && depthD.director.lineSinMin > depthD.director.lineSinMax) err('data/combat/depth.json', '/director/lineSinMin', 'depth-line-order', `lineSinMin ${depthD.director.lineSinMin} is above lineSinMax ${depthD.director.lineSinMax}`);",
      "", ""].join(LF);
    x = x.replace(a, () => block + a);
    fs.writeFileSync(xf, crlf ? x.split(LF).join(CR + LF) : x);
    console.log('xref: depth-line-order added');
  }
}
