// Fighters as data (docs/architecture/fighters-as-data.md, section 2; Simulation's window 1): the wounds model and the ladder become ONE shared file each, data/fight/wounds.json and
// data/fight/ladder.json, and a fighter's own file is optional and holds only his differences. The validator side:
//   tools/lib/shared.js (new) and tools/lib/core.js + tools/lib/selftest.js (a few lines each): each fighter's file is laid over the shared one before anything reads it: the shared file is
//   validated alone against the full schema, a fighter's file against the same schema with nothing required (and its unknown keys refused: rule `shared-unknown-key`), and the MERGED result
//   against the full schema and in every cross-reference. Inert until a shared file exists in the tree.
// This script is the data side, re-runnable (a second run changes nothing): map.json names the same two schemas for the shared files; the validator's fixtures split the same way
// (tools/fixtures/virtual/data/fight/wounds.json and ladder.json are the whole files, FIXTURE_HERO has none of his own, FIXTURE_VILLAIN has short difference files); the cases that
// mutated FIXTURE_HERO's whole files now mutate the shared ones; and new cases for the difference files. NOT run by CI, the validator or the sim:
//     node docs/tools/pending/apply-shared-fighter-files.cjs
// It does NOT edit data/. When Simulation's files land (data/fight/wounds.json, data/fight/ladder.json, the fighters' own files absent or short), nothing else needs changing: the rules
// above read them as they read the fixtures.
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);

// ---- map.json
{
  const f = 'tools/schemas/map.json';
  const m = rj(f);
  const add = (match, schema, before) => {
    if (m.rules.some((r) => r.match === match)) return;
    const i = m.rules.findIndex((r) => r.match === before);
    m.rules.splice(i < 0 ? m.rules.length : i, 0, { match, schema });
  };
  add('data/fight/wounds.json', 'fighter-wounds.schema.json', 'data/fighters/*/wounds.json');
  add('data/fight/ladder.json', 'fighter-ladder.schema.json', 'data/fighters/*/ladder.json');
  wj(f, m);
}

// ---- the validator's fixtures
const V = 'tools/fixtures/virtual/data';
const HW = `${V}/fighters/FIXTURE_HERO/wounds.json`, HL = `${V}/fighters/FIXTURE_HERO/ladder.json`;
const VW = `${V}/fighters/FIXTURE_VILLAIN/wounds.json`, VL = `${V}/fighters/FIXTURE_VILLAIN/ladder.json`;
const SW = `${V}/fight/wounds.json`, SL = `${V}/fight/ladder.json`;
{
  if (!fs.existsSync(SW) && fs.existsSync(HW)) {
    const w = rj(HW);
    w._about = 'Validator fixture, not game data: the shared wounds model (data/fight/wounds.json), a copy of the real Protagonist file in the pitch A shape.';
    wj(SW, w);
  }
  if (!fs.existsSync(SL) && fs.existsSync(HL)) {
    const l = rj(HL);
    l._about = 'Validator fixture, not game data: the shared ladder (data/fight/ladder.json). Field names are a guess from the D1 plan.';
    wj(SL, l);
  }
  if (fs.existsSync(HW)) fs.rmSync(HW);
  if (fs.existsSync(HL)) fs.rmSync(HL);
  const sw = rj(SW), sl = rj(SL);
  const vw = fs.existsSync(VW) ? rj(VW) : null;
  if (!vw || Object.keys(vw).some((k) => !k.startsWith('_') && k !== 'act1Damping')) {
    wj(VW, { _about: 'Validator fixture, not game data: a difference file (only what differs from data/fight/wounds.json).', act1Damping: Math.round((sw.act1Damping - 0.05) * 100) / 100 });
  }
  if (!fs.existsSync(VL)) wj(VL, { _about: 'Validator fixture, not game data: a difference file (only what differs from data/fight/ladder.json).', fillPerSec: Math.round((sl.fillPerSec + 0.05) * 100) / 100 });
}

// ---- cases
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const OWN = /^data\/fighters\/FIXTURE_HERO\/(wounds|ladder)\.json$/;
  let retargeted = 0;
  for (const k of c.cases) {
    for (const m of k.mutate || []) {
      const mm = OWN.exec(m.file);
      if (!mm) continue;
      const from = m.file;
      m.file = `data/fight/${mm[1]}.json`;
      if (k.expect && typeof k.expect.rule === 'string' && k.expect.rule.startsWith('xref:') && k.expect.file === undefined) k.expect.file = from;
      retargeted++;
    }
  }
  const sw = rj(SW);
  const WV = 'data/fighters/FIXTURE_VILLAIN/wounds.json', LV = 'data/fighters/FIXTURE_VILLAIN/ladder.json';
  const out = [];
  const cs = (id, schema, file, mutate, expect) => out.push({ id: 'shared-' + id, schema, mutate: [Object.assign({ file }, mutate)], expect });
  const wc = (id, mutate, expect) => cs('wounds-' + id, 'fighter-wounds.schema.json', WV, mutate, expect);
  const lc = (id, mutate, expect) => cs('ladder-' + id, 'fighter-ladder.schema.json', LV, mutate, expect);
  wc('own-leaf-ok', { set: { '/act1Damping': 0.8 } }, null);
  wc('own-empty-ok', { root: {} }, null);
  wc('own-note-ok', { set: { '/_why': 'a note' } }, null);
  wc('own-unknown-key', { set: { '/act1Dampning': 0.8 } }, { rule: 'shared-unknown-key', pointer: '/act1Dampning' });
  wc('own-unknown-nested-key', { set: { '/fade': { hiddn: 1 } } }, { rule: 'shared-unknown-key', pointer: '/fade/hiddn' });
  wc('own-wrong-type', { set: { '/act1Damping': 'half' } }, { rule: 'type', pointer: '/act1Damping' });
  wc('own-not-an-object', { root: [] }, { rule: 'type', pointer: '' });
  wc('own-list-replaces-whole', { set: { '/stageAt': [200000, 100000, 50000] } }, { rule: 'xref:increasing', pointer: '/stageAt' });
  wc('own-list-too-short', { set: { '/stageAt': [1, 2] } }, { rule: 'minItems', pointer: '/stageAt' });
  wc('own-dictionary-subset-ok', { set: { '/fade': { out: 30 } } }, null);
  wc('own-dictionary-wrong-leaf-type', { set: { '/fade': { out: 'slow' } } }, { rule: 'type', pointer: '/fade/out' });
  lc('own-leaf-ok', { set: { '/fillPerSec': 0.5 } }, null);
  lc('own-empty-ok', { root: {} }, null);
  lc('own-unknown-key', { set: { '/fillPerSecond': 0.5 } }, { rule: 'shared-unknown-key', pointer: '/fillPerSecond' });
  lc('own-unknown-nested-key', { set: { '/tiers': { speedPerTear: 0.1 } } }, { rule: 'shared-unknown-key', pointer: '/tiers/speedPerTear' });
  lc('own-wrong-type', { set: { '/fillPerSec': 'fast' } }, { rule: 'type', pointer: '/fillPerSec' });
  lc('own-list-replaces-whole', { set: { '/thresholds': [25, 50] } }, null);
  lc('own-dictionary-subset-ok', { set: { '/tiers': { speedPerTier: 0.2 } } }, null);
  // the shared file itself is the whole file: a missing key is required there
  cs('wounds-shared-key-required', 'fighter-wounds.schema.json', 'data/fight/wounds.json', { del: ['/rally'] }, { rule: 'required', pointer: '' });
  cs('wounds-shared-leaf-type', 'fighter-wounds.schema.json', 'data/fight/wounds.json', { set: { '/wearPerDamage': 'much' } }, { rule: 'type', pointer: '/wearPerDamage' });
  cs('ladder-shared-key-required', 'fighter-ladder.schema.json', 'data/fight/ladder.json', { del: ['/thresholds'] }, { rule: 'required', pointer: '' });
  void sw;
  let n = 0;
  for (const k of out) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (!same(c.cases[i], k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`shared fighter files applied (${retargeted} mutations now on the shared files, ${n} new or changed cases)`);
}

// ---- docs
{
  const f = 'docs/tools/README.md';
  const t = fs.readFileSync(f, 'utf8');
  if (!t.includes('`shared-unknown-key`')) {
    const lines = t.split('\n');
    const i = lines.findIndex((l) => l.includes('`stages-order`'));
    if (i < 0) throw new Error('README anchor');
    lines.splice(i + 1, 0, "| `shared-unknown-key` | data/fighters/<id>/wounds.json and ladder.json (fighters as data): a fighter's file is laid over data/fight/wounds.json or ladder.json key by key (dictionaries merge, numbers, words and lists replace whole) and holds only differences: a key the shared file does not have is refused; the merged result is what the full schema and every cross-reference read |");
    fs.writeFileSync(f, lines.join('\n'));
  }
}
