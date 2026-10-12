// Makes the keys Encounter added by grant (2026-10-11) required, with cases:
//   data/director/interrupts.json (tools/schemas/director-interrupts.schema.json): brawl.energy.reach.blast.enderRun, halfSetup and reelTicks, and brawl.nudge.floor
//   data/director/ai.json (tools/schemas/director-ai.schema.json): digInBoth, digInMax, digInRestS
// and the cross-reference `brawl-order` for enderRun (at most flurry.runToClose, or the blast is never an ender): tools/lib/xref-brawl-keys.js from docs/tools/pending/xref-brawl-keys.js.
// NOT run by CI, the validator or the sim. Run once from the repo root, in a commit that is not mid-way through another schema script and after the commit that carries the data:
//     node docs/tools/pending/apply-brawl-required-keys.cjs
// It does NOT edit data/. It edits tools/schemas/director-interrupts.schema.json, tools/schemas/director-ai.schema.json, tools/lib/xref-fight.js (one hook line), tools/lib/xref-brawl-keys.js,
// tools/fixtures/cases.json (the whole-/brawl copies the cases embed gain the keys; new cases), tools/fixtures/virtual/data/director/interrupts.json and ai.json (the validator's own copies
// of the files) and docs/tools/README.md. Re-runnable (a second run changes nothing). Every case sets its own values.
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const live = rj('data/director/interrupts.json');
const liveAi = rj('data/director/ai.json');
const LB = live.brawl.energy.reach.blast;
const BLAST_KEYS = { enderRun: LB.enderRun, halfSetup: LB.halfSetup, reelTicks: LB.reelTicks };
const FLOOR = live.brawl.nudge.floor;
const AI_KEYS = { digInBoth: liveAi.digInBoth, digInMax: liveAi.digInMax, digInRestS: liveAi.digInRestS };
for (const [k, v] of Object.entries({ ...BLAST_KEYS, floor: FLOOR, ...AI_KEYS })) if (v === undefined) throw new Error(`data does not carry ${k} yet: run this after the commit that has it`);

// =============================== schemas ===============================
{
  const f = 'tools/schemas/director-interrupts.schema.json';
  const s = rj(f);
  const brawl = s.properties.brawl;
  const blast = brawl.properties.energy.properties.reach.properties.blast;
  for (const k of Object.keys(BLAST_KEYS)) if (!blast.required.includes(k)) blast.required.push(k);
  blast.properties.enderRun.description = 'The blast knocks back only when his run is this or more as it lands (at most flurry.runToClose, or it is never an ender: rule brawl-order).';
  const nudge = brawl.properties.nudge;
  if (!nudge.required.includes('floor')) nudge.required.push('floor');
  wj(f, s);
  const g = 'tools/schemas/director-ai.schema.json';
  const a = rj(g);
  for (const k of Object.keys(AI_KEYS)) if (!a.required.includes(k)) a.required.push(k);
  wj(g, a);
}

// =============================== xref ===============================
{
  fs.copyFileSync('docs/tools/pending/xref-brawl-keys.js', 'tools/lib/xref-brawl-keys.js');
  const xf = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(xf, 'utf8');
  if (!t.includes("require('./xref-brawl-keys')")) {
    const a = "  require('./xref-lanes').xrefLanes({ get, err, esc, isObj });\n";
    if (!t.includes(a)) throw new Error('brawl keys xref anchor');
    t = t.replace(a, () => a + "  require('./xref-brawl-keys').xrefBrawlKeys({ get, err, esc, isObj });\n");
    fs.writeFileSync(xf, t);
  }
}

// =============================== fixtures (the validator's own copies) ===============================
{
  const f = 'tools/fixtures/virtual/data/director/interrupts.json';
  const v = rj(f);
  let ch = false;
  const bl = v.brawl.energy.reach.blast;
  for (const [k, x] of Object.entries(BLAST_KEYS)) if (bl[k] === undefined) { bl[k] = x; ch = true; }
  if (v.brawl.nudge.floor === undefined) { v.brawl.nudge.floor = FLOOR; ch = true; }
  if (ch) wj(f, v);
  const g = 'tools/fixtures/virtual/data/director/ai.json';
  const a = rj(g);
  ch = false;
  for (const [k, x] of Object.entries(AI_KEYS)) if (a[k] === undefined) { a[k] = x; ch = true; }
  if (ch) wj(g, a);
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  let patched = 0;
  // the whole-/brawl copies (and any whole energy, reach, blast or nudge object) the cases embed carry the keys
  const fixBrawl = (b) => {
    let ch = false;
    if (b && typeof b === 'object' && b.energy && b.energy.reach && b.energy.reach.blast) ch = fixBlast(b.energy.reach.blast) || ch;
    // a copy that closes a run sooner than the live enderRun keeps its blast an ender: the copy's own runToClose caps it (rule brawl-order)
    if (b && b.energy && b.energy.reach && b.energy.reach.blast && b.flurry && Number.isInteger(b.flurry.runToClose) && b.energy.reach.blast.enderRun > b.flurry.runToClose) { b.energy.reach.blast.enderRun = b.flurry.runToClose; ch = true; }
    if (b && typeof b === 'object' && b.nudge && typeof b.nudge === 'object' && b.nudge.floor === undefined) { b.nudge.floor = FLOOR; ch = true; }
    return ch;
  };
  const fixBlast = (bl) => {
    let ch = false;
    for (const [k, x] of Object.entries(BLAST_KEYS)) if (bl[k] === undefined) { bl[k] = x; ch = true; }
    return ch;
  };
  for (const cs of c.cases) {
    for (const m of cs.mutate || []) {
      if (m.file === 'data/director/interrupts.json' && m.set) {
        for (const [p, v] of Object.entries(m.set)) {
          if (!v || typeof v !== 'object') continue;
          let ch = false;
          if (p === '/brawl') ch = fixBrawl(v);
          else if (p === '/brawl/energy' && v.reach && v.reach.blast) ch = fixBlast(v.reach.blast);
          else if (p === '/brawl/energy/reach' && v.blast) ch = fixBlast(v.blast);
          else if (p === '/brawl/energy/reach/blast') ch = fixBlast(v);
          else if (p === '/brawl/nudge' && v.floor === undefined) { v.floor = FLOOR; ch = true; }
          if (ch) patched++;
        }
      }
    }
  }
  // a case that lowers runToClose under the live enderRun is made to lower the enderRun with it (rule brawl-order: a run never gets past the close)
  for (const cs of c.cases) {
    if (cs.id === 'director-interrupts-brawl-flurry-run-to-close-one-ok') {
      for (const m of cs.mutate) if (m.set && m.set['/brawl/flurry/runToClose'] === 1 && m.set['/brawl/energy/reach/blast/enderRun'] === undefined) m.set['/brawl/energy/reach/blast/enderRun'] = 1;
    }
  }
  const out = [];
  const IF = 'data/director/interrupts.json', AF = 'data/director/ai.json';
  const IS = 'director-interrupts.schema.json', AS = 'director-ai.schema.json';
  const add = (schema, file, id, mutate, expect) => out.push({ id, schema, mutate: [Object.assign({ file }, mutate)], expect });
  const B = '/brawl/energy/reach/blast';
  const ic = (id, m, e) => add(IS, IF, 'director-interrupts-brawlkeys-' + id, m, e);
  for (const k of ['enderRun', 'halfSetup', 'reelTicks']) ic('blast-' + k.toLowerCase() + '-required', { del: [`${B}/${k}`] }, { rule: 'required', pointer: B });
  ic('blast-enderrun-type', { set: { [`${B}/enderRun`]: 'two' } }, { rule: 'type', pointer: `${B}/enderRun` });
  ic('blast-enderrun-fraction', { set: { [`${B}/enderRun`]: 1.5 } }, { rule: 'type', pointer: `${B}/enderRun` });
  ic('blast-enderrun-negative', { set: { [`${B}/enderRun`]: -1 } }, { rule: 'minimum', pointer: `${B}/enderRun` });
  ic('blast-enderrun-zero-ok', { set: { [`${B}/enderRun`]: 0 } }, null);
  ic('blast-enderrun-at-run-to-close-ok', { set: { [`${B}/enderRun`]: 4, '/brawl/flurry/runToClose': 4 } }, null);
  ic('blast-enderrun-above-run-to-close', { set: { [`${B}/enderRun`]: 5, '/brawl/flurry/runToClose': 4 } }, { rule: 'xref:brawl-order', pointer: `${B}/enderRun` });
  ic('blast-halfsetup-type', { set: { [`${B}/halfSetup`]: 1 } }, { rule: 'type', pointer: `${B}/halfSetup` });
  ic('blast-halfsetup-false-ok', { set: { [`${B}/halfSetup`]: false } }, null);
  ic('blast-reelticks-type', { set: { [`${B}/reelTicks`]: 'long' } }, { rule: 'type', pointer: `${B}/reelTicks` });
  ic('blast-reelticks-fraction', { set: { [`${B}/reelTicks`]: 2.5 } }, { rule: 'type', pointer: `${B}/reelTicks` });
  ic('blast-reelticks-negative', { set: { [`${B}/reelTicks`]: -1 } }, { rule: 'minimum', pointer: `${B}/reelTicks` });
  ic('blast-reelticks-zero-ok', { set: { [`${B}/reelTicks`]: 0 } }, null);
  ic('nudge-floor-required', { del: ['/brawl/nudge/floor'] }, { rule: 'required', pointer: '/brawl/nudge' });
  ic('nudge-floor-type', { set: { '/brawl/nudge/floor': 'half' } }, { rule: 'type', pointer: '/brawl/nudge/floor' });
  ic('nudge-floor-negative', { set: { '/brawl/nudge/floor': -0.1 } }, { rule: 'minimum', pointer: '/brawl/nudge/floor' });
  ic('nudge-floor-above-one', { set: { '/brawl/nudge/floor': 1.1 } }, { rule: 'maximum', pointer: '/brawl/nudge/floor' });
  ic('nudge-floor-zero-ok', { set: { '/brawl/nudge/floor': 0 } }, null);
  ic('nudge-floor-one-ok', { set: { '/brawl/nudge/floor': 1 } }, null);
  const ac = (id, m, e) => add(AS, AF, 'director-ai-brawlkeys-' + id, m, e);
  for (const k of ['digInBoth', 'digInMax', 'digInRestS']) ac(k.toLowerCase() + '-required', { del: ['/' + k] }, { rule: 'required', pointer: '' });
  ac('diginboth-type', { set: { '/digInBoth': 1 } }, { rule: 'type', pointer: '/digInBoth' });
  ac('diginboth-true-ok', { set: { '/digInBoth': true } }, null);
  ac('diginmax-type', { set: { '/digInMax': 'two' } }, { rule: 'type', pointer: '/digInMax' });
  ac('diginmax-fraction', { set: { '/digInMax': 1.5 } }, { rule: 'type', pointer: '/digInMax' });
  ac('diginmax-below-limit', { set: { '/digInMax': -2 } }, { rule: 'minimum', pointer: '/digInMax' });
  ac('diginmax-off-ok', { set: { '/digInMax': -1 } }, null);
  ac('diginmax-zero-ok', { set: { '/digInMax': 0 } }, null);
  ac('diginrests-type', { set: { '/digInRestS': 'long' } }, { rule: 'type', pointer: '/digInRestS' });
  ac('diginrests-negative', { set: { '/digInRestS': -1 } }, { rule: 'minimum', pointer: '/digInRestS' });
  ac('diginrests-zero-ok', { set: { '/digInRestS': 0 } }, null);
  let n = 0;
  for (const k of out) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (!same(c.cases[i], k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`brawl required keys applied (${patched} embedded copies patched, ${n} new or changed cases)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  const t = fs.readFileSync(f, 'utf8');
  const a = "burst.lands never falls. data/director/ai.json brawl:";
  if (t.includes(a) && !t.includes('energy.reach.blast.enderRun is at most')) {
    fs.writeFileSync(f, t.replace(a, "burst.lands never falls, and energy.reach.blast.enderRun is at most flurry.runToClose (or the blast is never an ender). data/director/ai.json brawl:"));
  }
}
