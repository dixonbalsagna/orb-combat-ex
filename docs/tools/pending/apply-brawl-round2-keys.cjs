// Makes the keys Encounter's second round added by grant (2026-10-12) required, with cases:
//   data/director/ai.json (tools/schemas/director-ai.schema.json): levels.<easy|medium|hard>.brawl.mediumVsHeavies and perfectVsHeavy (numbers 0 to 1, as the schema already bounded them)
//   data/director/interrupts.json (tools/schemas/director-interrupts.schema.json): brawl.flurry.runBy (an object whose `medium` is 0 or more), runBy and its `medium` required
// NOT run by CI, the validator or the sim. Run once from the repo root, in a commit that is not mid-way through another schema script and after the commit that carries the data:
//     node docs/tools/pending/apply-brawl-round2-keys.cjs
// It does NOT edit data/. It edits the two director schemas, tools/fixtures/cases.json (the whole level blocks and whole /brawl blocks the cases embed gain the keys, from the live values; new
// cases) and tools/fixtures/virtual/data/director/ai.json and interrupts.json (the validator's own copies of the files). Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const LEVELS = ['easy', 'medium', 'hard'];
const KEYS = ['mediumVsHeavies', 'perfectVsHeavy'];
const liveAi = rj('data/director/ai.json');
const liveIt = rj('data/director/interrupts.json');
for (const l of LEVELS) for (const k of KEYS) if (typeof liveAi.levels[l].brawl[k] !== 'number') throw new Error(`data/director/ai.json carries no levels.${l}.brawl.${k} yet: run this after the commit that has it`);
const RUNBY = liveIt.brawl.flurry.runBy;
if (RUNBY === undefined) throw new Error('data/director/interrupts.json carries no brawl.flurry.runBy yet: run this after the commit that has it');

// =============================== schemas ===============================
{
  const a = 'tools/schemas/director-ai.schema.json';
  const s = rj(a);
  for (const l of LEVELS) {
    const br = s.properties.levels.properties[l].properties.brawl;
    for (const k of KEYS) if (!br.required.includes(k)) br.required.push(k);
  }
  wj(a, s);
  const f = 'tools/schemas/director-interrupts.schema.json';
  const t = rj(f);
  const fl = t.properties.brawl.properties.flurry;
  if (!fl.required.includes('runBy')) fl.required.push('runBy');
  const rb = fl.properties.runBy;
  if (rb.properties.medium && !(rb.required || []).includes('medium')) rb.required = ['medium'];
  if (!/patternProperties/.test(JSON.stringify(rb))) rb.patternProperties = { '^_': true };
  wj(f, t);
}

// =============================== fixtures (the validator's own copies) ===============================
{
  const f = 'tools/fixtures/virtual/data/director/ai.json';
  const v = rj(f);
  let ch = false;
  for (const l of LEVELS) {
    const b = v.levels && v.levels[l] && v.levels[l].brawl;
    if (!b) continue;
    for (const k of KEYS) if (b[k] === undefined) { b[k] = liveAi.levels[l].brawl[k]; ch = true; }
  }
  if (ch) wj(f, v);
  const g = 'tools/fixtures/virtual/data/director/interrupts.json';
  const w = rj(g);
  if (w.brawl && w.brawl.flurry && w.brawl.flurry.runBy === undefined) { w.brawl.flurry.runBy = RUNBY; wj(g, w); }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  let patched = 0;
  const isLevelBrawl = (o) => o && typeof o === 'object' && !Array.isArray(o) && 'tapGap' in o && 'string' in o && 'guardShare' in o;
  const fillLevel = (b, level) => {
    let ch = false;
    const src = liveAi.levels[LEVELS.includes(level) ? level : 'medium'].brawl;
    for (const k of KEYS) if (b[k] === undefined) { b[k] = src[k]; ch = true; }
    return ch;
  };
  const walkAi = (o, level) => {
    let ch = false;
    if (!o || typeof o !== 'object' || Array.isArray(o)) return false;
    if (isLevelBrawl(o)) return fillLevel(o, level);
    for (const [k, v] of Object.entries(o)) ch = walkAi(v, LEVELS.includes(k) ? k : level) || ch;
    return ch;
  };
  for (const cs of c.cases) {
    for (const m of cs.mutate || []) {
      if (!m.set) continue;
      if (m.file === 'data/director/ai.json') {
        for (const [p, v] of Object.entries(m.set)) {
          const lv = (/\/levels\/(easy|medium|hard)(\/|$)/.exec(p) || [])[1];
          if (walkAi(v, lv)) patched++;
        }
      } else if (m.file === 'data/director/interrupts.json') {
        for (const [p, v] of Object.entries(m.set)) {
          if (!v || typeof v !== 'object' || Array.isArray(v)) continue;
          if (p === '/brawl' && v.flurry && typeof v.flurry === 'object' && v.flurry.runBy === undefined) { v.flurry.runBy = RUNBY; patched++; }
          else if (p === '/brawl/flurry' && v.runBy === undefined) { v.runBy = RUNBY; patched++; }
        }
      }
    }
  }
  const out = [];
  const add = (schema, file, id, mutate, expect) => out.push({ id, schema, mutate: [Object.assign({ file }, mutate)], expect });
  const ac = (id, m, e) => add('director-ai.schema.json', 'data/director/ai.json', 'director-ai-brawlr2-' + id, m, e);
  for (const l of LEVELS) {
    const B = `/levels/${l}/brawl`;
    for (const [k, slug] of [['mediumVsHeavies', 'mediumvsheavies'], ['perfectVsHeavy', 'perfectvsheavy']]) {
      ac(`${l}-${slug}-required`, { del: [`${B}/${k}`] }, { rule: 'required', pointer: B });
      ac(`${l}-${slug}-type`, { set: { [`${B}/${k}`]: 'most' } }, { rule: 'type', pointer: `${B}/${k}` });
      ac(`${l}-${slug}-negative`, { set: { [`${B}/${k}`]: -0.1 } }, { rule: 'minimum', pointer: `${B}/${k}` });
      ac(`${l}-${slug}-above-one`, { set: { [`${B}/${k}`]: 1.1 } }, { rule: 'maximum', pointer: `${B}/${k}` });
      ac(`${l}-${slug}-edges-ok`, { set: { [`${B}/${k}`]: 0 } }, null);
      ac(`${l}-${slug}-one-ok`, { set: { [`${B}/${k}`]: 1 } }, null);
    }
  }
  const ic = (id, m, e) => add('director-interrupts.schema.json', 'data/director/interrupts.json', 'director-interrupts-brawlr2-' + id, m, e);
  const FL = '/brawl/flurry';
  ic('runby-required', { del: [`${FL}/runBy`] }, { rule: 'required', pointer: FL });
  ic('runby-type', { set: { [`${FL}/runBy`]: 2 } }, { rule: 'type', pointer: `${FL}/runBy` });
  ic('runby-medium-required', { del: [`${FL}/runBy/medium`] }, { rule: 'required', pointer: `${FL}/runBy` });
  ic('runby-medium-type', { set: { [`${FL}/runBy/medium`]: 'two' } }, { rule: 'type', pointer: `${FL}/runBy/medium` });
  ic('runby-medium-negative', { set: { [`${FL}/runBy/medium`]: -1 } }, { rule: 'minimum', pointer: `${FL}/runBy/medium` });
  ic('runby-medium-zero-ok', { set: { [`${FL}/runBy/medium`]: 0 } }, null);
  ic('runby-medium-fraction-ok', { set: { [`${FL}/runBy/medium`]: 1.5 } }, null);
  ic('runby-unknown-key', { set: { [`${FL}/runBy/heavy`]: 3 } }, { rule: 'additionalProperties', pointer: `${FL}/runBy/heavy` });
  ic('runby-underscore-key-ok', { set: { [`${FL}/runBy/_note`]: 'a note' } }, null);
  let n = 0;
  for (const k of out) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (!same(c.cases[i], k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`brawl round 2 keys applied (${patched} embedded copies patched, ${n} new or changed cases)`);
}
