// Schema keys for Simulation's wear-and-mood slice (docs/architecture/brawl-wear-and-mood.md; melee-press-feel.md section 9d). NOT run by CI, the
// validator or the sim. Run once from the repo root, in the commit that lands the slice's data:
//     node docs/tools/pending/apply-wear-mood.cjs
// It does NOT edit data/. It adds:
//   data/fighters/<FIGHTER>/wounds.json  a required closed `block` {streamArmShare (a number, 0 to 1), armWearCap (an integer, 0 or more)}, and
//                                        the rule block-cap: armWearCap below stageAt[1] (battered), as Simulation's loader requires (the
//                                        battered threshold is in the same file, in wear units, so it is a cross-check here)
//   data/fight/mood.json                 seven more required impulses (integers, 0 or more): brawlLight, blocked, skillStrike, brawlHeavy,
//                                        flurryClose, guardBreak, knockback
// The values may change; the keys are what is checked. The fixtures (the two FIXTURE_ fighters' wounds.json and the virtual mood.json) get the
// keys, and the cases set their own values. Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const obj = (props, opts = {}) => Object.assign({ type: 'object', required: opts.required === undefined ? Object.keys(props) : opts.required, properties: props }, opts.description ? { description: opts.description } : {}, closed);
const IMPULSES = ['brawlLight', 'blocked', 'skillStrike', 'brawlHeavy', 'flurryClose', 'guardBreak', 'knockback'];
const MOOD_VALUES = { brawlLight: 20, blocked: 0, skillStrike: 90, brawlHeavy: 120, flurryClose: 180, guardBreak: 240, knockback: 180 };

// =============================== wounds schema ===============================
{
  const f = 'tools/schemas/fighter-wounds.schema.json';
  const s = rj(f);
  if (!s.properties.block) {
    s.properties.block = obj({
      streamArmShare: { type: 'number', minimum: 0, maximum: 1, description: 'The share of a blocked light or flurry blow\'s chip wear that goes to the arms; the rest is soaked (melee-press-feel.md section 9d, ruling 1).' },
      armWearCap: { type: 'integer', minimum: 0, description: 'No blocked blow takes the arms\' wear past this, in wear units; below battered (stageAt[1]), so blocking alone never batters an arm (rule block-cap).' },
    }, { description: 'Blocked blows and the arms.' });
    s.required.push('block');
    if (!/block-cap/.test(s.description)) s.description = s.description.replace(/\. Cross-references \(/, () => '. Cross-references (a block\'s armWearCap below stageAt[1] (block-cap); ');
    wj(f, s);
  }
}

// =============================== mood schema ===============================
{
  const f = 'tools/schemas/fight-mood.schema.json';
  const s = rj(f);
  const imp = s.properties.impulses;
  let changed = false;
  for (const k of IMPULSES) {
    if (!imp.properties[k]) { imp.properties[k] = { type: 'integer', minimum: 0 }; changed = true; }
    if (!imp.required.includes(k)) { imp.required.push(k); changed = true; }
  }
  if (changed) wj(f, s);
}

// =============================== fixtures ===============================
{
  for (const id of ['FIXTURE_HERO', 'FIXTURE_VILLAIN']) {
    const f = `tools/fixtures/virtual/data/fighters/${id}/wounds.json`;
    if (!fs.existsSync(f)) continue;
    const o = rj(f);
    if (o.block === undefined) {
      const at = Array.isArray(o.stageAt) && o.stageAt.length >= 2 ? o.stageAt[1] : 360000;
      const out = {};
      for (const k of Object.keys(o)) { out[k] = o[k]; if (k === 'guardWearSplit') out.block = { streamArmShare: 0.5, armWearCap: Math.floor(at * 0.75) }; }
      if (out.block === undefined) out.block = { streamArmShare: 0.5, armWearCap: Math.floor(at * 0.75) };
      wj(f, out);
    }
  }
  const f = 'tools/fixtures/virtual/data/fight/mood.json';
  const o = rj(f);
  let changed = false;
  for (const k of IMPULSES) if (o.impulses[k] === undefined) { o.impulses[k] = MOOD_VALUES[k]; changed = true; }
  if (changed) wj(f, o);
}

// =============================== xref ===============================
{
  const f = 'tools/lib/xref.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes("'block-cap'")) {
    const a = "    if (m[2] === 'wounds' && isObj(d.regions) && isObj(d.family)) {";
    if (!t.includes(a)) throw new Error('wounds xref anchor');
    t = t.replace(a, () => [
      "    if (m[2] === 'wounds' && isObj(d.block) && Number.isInteger(d.block.armWearCap) && Array.isArray(d.stageAt) && d.stageAt.length >= 2 && typeof d.stageAt[1] === 'number' && d.block.armWearCap >= d.stageAt[1]) err(file, '/block/armWearCap', 'block-cap', `armWearCap ${d.block.armWearCap} is not below battered (stageAt[1] ${d.stageAt[1]}), so blocking alone could batter an arm`);",
      a,
    ].join('\n'));
    fs.writeFileSync(f, t);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const W = 'data/fighters/FIXTURE_HERO/wounds.json';
  const M = 'data/fight/mood.json';
  const STAGE = [180000, 360000, 540000];
  const wo = (n, set, expect, del) => ({ id: 'wounds-block-' + n, schema: 'fighter-wounds.schema.json', mutate: [{ file: W, set: Object.assign({ '/stageAt': STAGE }, set), ...(del ? { del } : {}) }], expect });
  const B = '/block/';
  const OK = { streamArmShare: 0.5, armWearCap: 270000 };
  const mo = (n, mut, expect) => ({ id: 'mood-' + n, schema: 'fight-mood.schema.json', mutate: [{ file: M, ...mut }], expect });
  const add = [
    wo('valid', { '/block': OK }, null),
    wo('required', {}, { rule: 'required', pointer: '' }, ['/block']),
    wo('unknown-key', { '/block': Object.assign({ extra: 1 }, OK) }, { rule: 'additionalProperties', pointer: B + 'extra' }),
    wo('underscore-key-ok', { '/block': Object.assign({ _note: 'a note' }, OK) }, null),
    wo('share-required', { '/block': { armWearCap: 270000 } }, { rule: 'required', pointer: '/block' }),
    wo('share-negative', { '/block': { streamArmShare: -0.1, armWearCap: 270000 } }, { rule: 'minimum', pointer: B + 'streamArmShare' }),
    wo('share-above-one', { '/block': { streamArmShare: 1.1, armWearCap: 270000 } }, { rule: 'maximum', pointer: B + 'streamArmShare' }),
    wo('share-type', { '/block': { streamArmShare: 'half', armWearCap: 270000 } }, { rule: 'type', pointer: B + 'streamArmShare' }),
    wo('share-zero-ok', { '/block': { streamArmShare: 0, armWearCap: 270000 } }, null),
    wo('share-one-ok', { '/block': { streamArmShare: 1, armWearCap: 270000 } }, null),
    wo('cap-required', { '/block': { streamArmShare: 0.5 } }, { rule: 'required', pointer: '/block' }),
    wo('cap-negative', { '/block': { streamArmShare: 0.5, armWearCap: -1 } }, { rule: 'minimum', pointer: B + 'armWearCap' }),
    wo('cap-integer', { '/block': { streamArmShare: 0.5, armWearCap: 270000.5 } }, { rule: 'type', pointer: B + 'armWearCap' }),
    wo('cap-type', { '/block': { streamArmShare: 0.5, armWearCap: 'high' } }, { rule: 'type', pointer: B + 'armWearCap' }),
    wo('cap-zero-ok', { '/block': { streamArmShare: 0.5, armWearCap: 0 } }, null),
    wo('cap-at-battered', { '/block': { streamArmShare: 0.5, armWearCap: 360000 } }, { rule: 'xref:block-cap', pointer: B + 'armWearCap' }),
    wo('cap-above-battered', { '/block': { streamArmShare: 0.5, armWearCap: 400000 } }, { rule: 'xref:block-cap', pointer: B + 'armWearCap' }),
    wo('cap-just-below-battered-ok', { '/block': { streamArmShare: 0.5, armWearCap: 359999 } }, null),
    wo('cap-follows-the-fighters-own-battered', { '/stageAt': [100, 200, 300], '/block': { streamArmShare: 0.5, armWearCap: 250 } }, { rule: 'xref:block-cap', pointer: B + 'armWearCap' }),
  ];
  // the stageAt of the last case above is overridden by its own set
  for (const k of IMPULSES) {
    const P = '/impulses/' + k;
    add.push(
      mo('impulse-' + k + '-required', { del: [P] }, { rule: 'required', pointer: '/impulses' }),
      mo('impulse-' + k + '-negative', { set: { [P]: -1 } }, { rule: 'minimum', pointer: P }),
      mo('impulse-' + k + '-integer', { set: { [P]: 1.5 } }, { rule: 'type', pointer: P }),
      mo('impulse-' + k + '-zero-ok', { set: { [P]: 0 } }, null),
    );
  }
  let n = 0;
  for (const k of add) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`wear and mood schema applied (${n} new cases)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes('`block-cap`')) {
    const lines = t.split('\n');
    const i = lines.findIndex((l) => l.includes('`stages-order`')) >= 0 ? lines.findIndex((l) => l.includes('`stages-order`')) : lines.findIndex((l) => l.includes('`increasing`'));
    if (i < 0) throw new Error('wear-mood README anchor');
    lines.splice(i + 1, 0, '| `block-cap` | data/fighters/<id>/wounds.json: block.armWearCap is below stageAt[1] (battered), so blocking alone never batters an arm (the loader\'s rule) |');
    fs.writeFileSync(f, lines.join('\n'));
  }
}
