// Schema keys for Simulation's blocked-shots slice (Game Design: blocked shots wear the arms by their own share and cap, apart from blocked blows).
// NOT run by CI, the validator or the sim. Run once from the repo root, in the commit that lands the slice's data (after apply-wear-mood.cjs, applied):
//     node docs/tools/pending/apply-wear-shots.cjs
// It does NOT edit data/. The `block` record of data/fighters/<FIGHTER>/wounds.json gains two required keys:
//   shotArmShare    number, 0 to 1 (0.5): the share of a blocked shot's chip wear that goes to the arms
//   shotArmWearCap  integer, 0 or more (450000), in wear units like armWearCap: no blocked shot takes the arms' wear past this
// New rule block-shot-cap, beside block-cap: shotArmWearCap is below stageAt[2] (the broken threshold, 540000 today). armWearCap keeps its rule
// (below stageAt[1], battered). The fixtures' wounds files and the earlier block cases get the two keys; the new cases set their own values.
// Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');

// =============================== schema ===============================
{
  const f = 'tools/schemas/fighter-wounds.schema.json';
  const s = rj(f);
  const b = s.properties.block;
  let changed = false;
  if (!b.properties.shotArmShare) {
    b.properties.shotArmShare = { type: 'number', minimum: 0, maximum: 1, description: 'The share of a blocked shot\'s chip wear that goes to the arms (a blocked shot wears the arms by its own share and cap, apart from blocked blows).' };
    changed = true;
  }
  if (!b.properties.shotArmWearCap) {
    b.properties.shotArmWearCap = { type: 'integer', minimum: 0, description: 'No blocked shot takes the arms\' wear past this, in wear units; below broken (stageAt[2]; rule block-shot-cap).' };
    changed = true;
  }
  for (const k of ['shotArmShare', 'shotArmWearCap']) if (!b.required.includes(k)) { b.required.push(k); changed = true; }
  b.description = 'Blocked blows and shots, and the arms.';
  if (!/block-shot-cap/.test(s.description)) s.description = s.description.replace('a block\'s armWearCap below stageAt[1] (block-cap); ', () => 'a block\'s armWearCap below stageAt[1] (block-cap) and its shotArmWearCap below stageAt[2] (block-shot-cap); ');
  if (changed || JSON.stringify(rj(f)) !== JSON.stringify(s)) wj(f, s);
}

// =============================== fixtures ===============================
{
  for (const id of ['FIXTURE_HERO', 'FIXTURE_VILLAIN']) {
    const f = `tools/fixtures/virtual/data/fighters/${id}/wounds.json`;
    if (!fs.existsSync(f)) continue;
    const o = rj(f);
    if (o.block && (o.block.shotArmShare === undefined || o.block.shotArmWearCap === undefined)) {
      const at = Array.isArray(o.stageAt) && o.stageAt.length >= 3 ? o.stageAt[2] : 540000;
      if (o.block.shotArmShare === undefined) o.block.shotArmShare = 0.5;
      if (o.block.shotArmWearCap === undefined) o.block.shotArmWearCap = Math.floor(at * 0.8);
      wj(f, o);
    }
  }
}

// =============================== xref ===============================
{
  const f = 'tools/lib/xref.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes("'block-shot-cap'")) {
    const a = "    if (m[2] === 'wounds' && isObj(d.block) && Number.isInteger(d.block.armWearCap)";
    const i = t.indexOf(a);
    if (i < 0) throw new Error('block-cap anchor');
    const j = t.indexOf('\n', i);
    const line = "    if (m[2] === 'wounds' && isObj(d.block) && Number.isInteger(d.block.shotArmWearCap) && Array.isArray(d.stageAt) && d.stageAt.length >= 3 && typeof d.stageAt[2] === 'number' && d.block.shotArmWearCap >= d.stageAt[2]) err(file, '/block/shotArmWearCap', 'block-shot-cap', `shotArmWearCap ${d.block.shotArmWearCap} is not below broken (stageAt[2] ${d.stageAt[2]}), so blocked shots alone could break an arm`);";
    t = t.slice(0, j + 1) + line + '\n' + t.slice(j + 1);
    fs.writeFileSync(f, t);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const W = 'data/fighters/FIXTURE_HERO/wounds.json';
  // the earlier block cases that set a whole block get the two keys
  let moved = 0;
  for (const k of c.cases) {
    if (!/^wounds-block-/.test(k.id) || /^wounds-block-shot-/.test(k.id)) continue;
    for (const m of k.mutate) {
      const b = m.set && m.set['/block'];
      if (b && typeof b === 'object') {
        if (b.shotArmShare === undefined) { b.shotArmShare = 0.5; moved++; }
        if (b.shotArmWearCap === undefined) { b.shotArmWearCap = 450000; moved++; }
      }
    }
  }
  const STAGE = [180000, 360000, 540000];
  const base = () => ({ streamArmShare: 0.5, armWearCap: 270000, shotArmShare: 0.5, shotArmWearCap: 450000 });
  const wo = (n, tweak, expect, stage) => {
    const b = base();
    tweak(b);
    return { id: 'wounds-block-shot-' + n, schema: 'fighter-wounds.schema.json', mutate: [{ file: W, set: { '/stageAt': stage || STAGE, '/block': b } }], expect };
  };
  const B = '/block/';
  const add = [
    wo('valid', () => {}, null),
    wo('share-required', (b) => { delete b.shotArmShare; }, { rule: 'required', pointer: '/block' }),
    wo('share-negative', (b) => { b.shotArmShare = -0.1; }, { rule: 'minimum', pointer: B + 'shotArmShare' }),
    wo('share-above-one', (b) => { b.shotArmShare = 1.1; }, { rule: 'maximum', pointer: B + 'shotArmShare' }),
    wo('share-type', (b) => { b.shotArmShare = 'half'; }, { rule: 'type', pointer: B + 'shotArmShare' }),
    wo('share-zero-ok', (b) => { b.shotArmShare = 0; }, null),
    wo('share-one-ok', (b) => { b.shotArmShare = 1; }, null),
    wo('cap-required', (b) => { delete b.shotArmWearCap; }, { rule: 'required', pointer: '/block' }),
    wo('cap-negative', (b) => { b.shotArmWearCap = -1; }, { rule: 'minimum', pointer: B + 'shotArmWearCap' }),
    wo('cap-integer', (b) => { b.shotArmWearCap = 450000.5; }, { rule: 'type', pointer: B + 'shotArmWearCap' }),
    wo('cap-type', (b) => { b.shotArmWearCap = 'high'; }, { rule: 'type', pointer: B + 'shotArmWearCap' }),
    wo('cap-zero-ok', (b) => { b.shotArmWearCap = 0; }, null),
    wo('cap-at-broken', (b) => { b.shotArmWearCap = 540000; }, { rule: 'xref:block-shot-cap', pointer: B + 'shotArmWearCap' }),
    wo('cap-above-broken', (b) => { b.shotArmWearCap = 600000; }, { rule: 'xref:block-shot-cap', pointer: B + 'shotArmWearCap' }),
    wo('cap-just-below-broken-ok', (b) => { b.shotArmWearCap = 539999; }, null),
    wo('cap-may-pass-battered-ok', (b) => { b.shotArmWearCap = 400000; }, null),
    wo('cap-follows-the-fighters-own-broken', (b) => { b.armWearCap = 150; b.shotArmWearCap = 300; }, { rule: 'xref:block-shot-cap', pointer: B + 'shotArmWearCap' }, [100, 200, 300]),
    wo('blow-cap-keeps-its-rule', (b) => { b.armWearCap = 360000; }, { rule: 'xref:block-cap', pointer: B + 'armWearCap' }),
    wo('both-caps-over-ok-for-their-own-thresholds', (b) => { b.armWearCap = 359999; b.shotArmWearCap = 539999; }, null),
  ];
  let n = 0;
  for (const k of add) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`wear shots schema applied (${n} new cases, ${moved} earlier values added)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes('`block-shot-cap`')) {
    const lines = t.split('\n');
    const i = lines.findIndex((l) => l.includes('`block-cap`'));
    if (i < 0) throw new Error('block-shot-cap README anchor');
    lines.splice(i + 1, 0, '| `block-shot-cap` | data/fighters/<id>/wounds.json: block.shotArmWearCap is below stageAt[2] (broken), so blocked shots alone never break an arm |');
    fs.writeFileSync(f, lines.join('\n'));
  }
}
