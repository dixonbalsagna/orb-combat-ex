// Schema keys for Encounter's follow-up to the first brawl (Game Design's rulings, docs/design/melee-press-feel.md section 9d). NOT run by CI,
// the validator or the sim. Run once from the repo root, in the commit that lands the slice's data (after apply-brawl1.cjs, which is applied):
//     node docs/tools/pending/apply-brawl-9d.cjs
// It does NOT edit data/. Keys fixed by Encounter:
//   data/director/interrupts.json  brawl.flurry gains staggeredAddsRun (boolean; false), levelWithin (integer, 0 or more; 1) and momentum
//                                  (a share, 0.5 to 1; 0.9), all required; brawl.flurry.closeAfter is REMOVED (no longer allowed);
//                                  brawl gains shotHeavyMul (a number above 0; 2), required
//   data/director/ai.json          each level's brawl gains heavyAfterClose (a share, 0 to 1; 0.2, 0.6, 0.9), required; each level gains
//                                  vsShooter {guardShare, enderShare, heavyApproachShare} (shares, 0 to 1; closed; all three required),
//                                  required (it is the level's own key, beside brawl: melee-press-feel.md section 9d says "each level's vsShooter")
// No new key in launch.json. The 9c keys (answerBy, guardMaxTicks, attackIntoGap) stay absent and unknown (the schemas are closed).
// The fixtures and the existing brawl cases follow: the cases of apply-brawl1 that set a whole brawl block (or a level's) get the new keys, and
// the closeAfter case becomes a case that the key is retired. Every new case sets its own whole block. Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const obj = (props, opts = {}) => Object.assign({ type: 'object', required: opts.required === undefined ? Object.keys(props) : opts.required, properties: props }, opts.description ? { description: opts.description } : {}, closed);
const clone = (o) => JSON.parse(JSON.stringify(o));
const share = (d) => ({ type: 'number', minimum: 0, maximum: 1, description: d });
const NEW_FLURRY = { staggeredAddsRun: false, levelWithin: 1, momentum: 0.9 };

// =============================== interrupts schema ===============================
{
  const f = 'tools/schemas/director-interrupts.schema.json';
  const s = rj(f);
  const b = s.properties.brawl;
  const fl = b.properties.flurry;
  let changed = false;
  if (fl.properties.closeAfter) {
    delete fl.properties.closeAfter;
    fl.required = fl.required.filter((k) => k !== 'closeAfter');
    changed = true;
  }
  if (!fl.properties.momentum) {
    fl.properties.staggeredAddsRun = { type: 'boolean', description: 'Whether a blow that lands on a staggered rival adds to the run (Game Design section 9d: it does not).' };
    fl.properties.levelWithin = { type: 'integer', minimum: 0, description: 'Runs within this many blows of each other are a level trade, settled by the momentum.' };
    fl.properties.momentum = { type: 'number', minimum: 0.5, maximum: 1, description: 'The chance, in a level trade, that the fighter who made the last close in this brawl makes this one (0.5 is even; 1 is always).' };
    for (const k of ['staggeredAddsRun', 'levelWithin', 'momentum']) if (!fl.required.includes(k)) fl.required.push(k);
    changed = true;
  }
  if (!b.properties.shotHeavyMul) {
    b.properties.shotHeavyMul = { type: 'number', exclusiveMinimum: 0, description: 'The worth of a heavy shot against the brawl\'s scale (Game Design section 9d).' };
    b.required.push('shotHeavyMul');
    changed = true;
  }
  if (changed) wj(f, s);
}

// =============================== ai schema ===============================
{
  const f = 'tools/schemas/director-ai.schema.json';
  const s = rj(f);
  let changed = false;
  for (const name of ['easy', 'medium', 'hard']) {
    const L = s.properties.levels.properties[name];
    const b = L.properties.brawl;
    if (!b.properties.heavyAfterClose) {
      b.properties.heavyAfterClose = share('The chance of a heavy right after a close.');
      b.required.push('heavyAfterClose');
      changed = true;
    }
    if (!L.properties.vsShooter) {
      L.properties.vsShooter = obj({
        guardShare: share('The chance it guards against a shooter in a brawl.'),
        enderShare: share('The chance it throws the ender (which would knock him away) against a shooter.'),
        heavyApproachShare: share('The chance it comes in with the heavy lunge or charge, the approach a bolt does not stop.'),
      }, { description: 'The AI against a shooter (a rival who has fired in the last 90 ticks and landed no melee blow in the last 120).' });
      L.required.push('vsShooter');
      changed = true;
    }
  }
  if (changed) wj(f, s);
}

// =============================== fixtures ===============================
{
  const dir = 'tools/fixtures/virtual/data/director/';
  {
    const f = dir + 'interrupts.json';
    const o = rj(f);
    if (o.brawl && o.brawl.flurry) {
      const fl = o.brawl.flurry;
      let changed = false;
      if (fl.closeAfter !== undefined) { delete fl.closeAfter; changed = true; }
      for (const [k, v] of Object.entries(NEW_FLURRY)) if (fl[k] === undefined) { fl[k] = v; changed = true; }
      if (o.brawl.shotHeavyMul === undefined) { o.brawl.shotHeavyMul = 2; changed = true; }
      if (changed) wj(f, o);
    }
  }
  {
    const f = dir + 'ai.json';
    const o = rj(f);
    let changed = false;
    const hac = { easy: 0.2, medium: 0.6, hard: 0.9 };
    const vs = { easy: 0.5, medium: 0.2, hard: 0.1 };
    for (const name of ['easy', 'medium', 'hard']) {
      const L = o.levels && o.levels[name];
      if (!L || !L.brawl) continue;
      if (L.brawl.heavyAfterClose === undefined) { L.brawl.heavyAfterClose = hac[name]; changed = true; }
      if (L.vsShooter === undefined) { L.vsShooter = { guardShare: 0, enderShare: vs[name], heavyApproachShare: hac[name] }; changed = true; }
    }
    if (changed) wj(f, o);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const IT = 'data/director/interrupts.json';
  const AI = 'data/director/ai.json';
  // the earlier brawl cases that set a whole block follow the new keys
  let moved = 0;
  const fixBrawl = (b) => {
    if (!b || typeof b !== 'object') return false;
    let ch = false;
    if (b.flurry && typeof b.flurry === 'object') {
      if (b.flurry.closeAfter !== undefined) { delete b.flurry.closeAfter; ch = true; }
      for (const [k, v] of Object.entries(NEW_FLURRY)) if (b.flurry[k] === undefined) { b.flurry[k] = v; ch = true; }
    }
    if (b.shotHeavyMul === undefined) { b.shotHeavyMul = 2; ch = true; }
    return ch;
  };
  for (const k of c.cases) {
    if (!/^director-(interrupts|ai)-brawl-/.test(k.id) || /brawl9d-/.test(k.id)) continue;
    for (const m of k.mutate) {
      if (!m.set) continue;
      if (m.file === IT && m.set['/brawl'] && fixBrawl(m.set['/brawl'])) moved++;
      if (m.file === AI) {
        for (const key of Object.keys(m.set)) {
          const mm = /^\/levels\/(easy|medium|hard)\/brawl$/.exec(key);
          if (mm && m.set[key] && typeof m.set[key] === 'object' && m.set[key].heavyAfterClose === undefined) { m.set[key].heavyAfterClose = 0.5; moved++; }
        }
      }
    }
  }
  // the closeAfter case: the key is retired
  const old = c.cases.findIndex((k) => k.id === 'director-interrupts-brawl-flurry-close-integer');
  if (old >= 0) c.cases.splice(old, 1);

  const VALID = {
    enabled: true, interrupts: ['hit', 'guard'], breakBh: 6, pullBhPerSec: 0.5, stepInTicks: 6, idleTicks: 90, heldPressTicks: 12, stringLapseTicks: 60, enderAfter: 5, recoil: 0.2, damageMul: 1, aiPerfectEveryTicks: 120, aiReversalEveryTicks: 180, tradeTicks: 8, heldMul: 1.2, skillMul: 1.2, setMul: 0.8, heavyMul: 1.5,
    light: { damage: 6, contactTicks: 6, blowTicks: 12, recover: 10 },
    flurry: { minGap: 4, maxGap: 20, mul: [[6, 0.6], [12, 1.2]], reelTicks: 10, staggerTicks: 8, runToClose: 4, replyTakes: 1, runLapseTicks: 24, tradeMaxTicks: 90, staggeredAddsRun: false, levelWithin: 1, momentum: 0.9 },
    heavy: { damage: 30, ki: 8, windupTicks: 20, landTicks: 6, recover: 20, recoverWhiff: 30, heldFullTicks: 40, heldMaxTicks: 60, heldLandTicks: 8, staggerTicks: 20, force: 1 },
    hitstop: { light: 2, heavy: 5 },
    shotHeavyMul: 2,
  };
  const VALID_AI = { tapGap: 8, string: [3, 6], enderShare: 0.4, rashHeavy: 0.1, guardShare: 0.3, guardTicks: [20, 60], perfectMul: 1, heavyAfterClose: 0.6 };
  const VS = { guardShare: 0, enderShare: 0.2, heavyApproachShare: 0.6 };
  const it = (n, tweak, expect) => { const o = clone(VALID); tweak(o); return { id: 'director-interrupts-brawl9d-' + n, schema: 'director-interrupts.schema.json', mutate: [{ file: IT, set: { '/brawl': o } }], expect }; };
  const ai = (n, tweak, expect) => { const o = clone(VALID_AI); tweak(o); return { id: 'director-ai-brawl9d-' + n, schema: 'director-ai.schema.json', mutate: [{ file: AI, set: { '/levels/medium/brawl': o } }], expect }; };
  const vs = (n, tweak, expect) => {
    const o = clone(VS);
    const del = tweak(o) === 'delete' ? ['/levels/medium/vsShooter'] : null;
    return { id: 'director-ai-brawl9d-vs-' + n, schema: 'director-ai.schema.json', mutate: [{ file: AI, ...(del ? { del } : { set: { '/levels/medium/vsShooter': o } }) }], expect };
  };
  const B = '/brawl/';
  const V = '/levels/medium/vsShooter';
  const add = [
    it('valid', () => {}, null),
    it('close-after-retired', (o) => { o.flurry.closeAfter = 30; }, { rule: 'additionalProperties', pointer: B + 'flurry/closeAfter' }),
    it('staggered-adds-run-required', (o) => { delete o.flurry.staggeredAddsRun; }, { rule: 'required', pointer: B + 'flurry' }),
    it('staggered-adds-run-type', (o) => { o.flurry.staggeredAddsRun = 'no'; }, { rule: 'type', pointer: B + 'flurry/staggeredAddsRun' }),
    it('staggered-adds-run-true-ok', (o) => { o.flurry.staggeredAddsRun = true; }, null),
    it('level-within-required', (o) => { delete o.flurry.levelWithin; }, { rule: 'required', pointer: B + 'flurry' }),
    it('level-within-negative', (o) => { o.flurry.levelWithin = -1; }, { rule: 'minimum', pointer: B + 'flurry/levelWithin' }),
    it('level-within-integer', (o) => { o.flurry.levelWithin = 1.5; }, { rule: 'type', pointer: B + 'flurry/levelWithin' }),
    it('level-within-zero-ok', (o) => { o.flurry.levelWithin = 0; }, null),
    it('momentum-required', (o) => { delete o.flurry.momentum; }, { rule: 'required', pointer: B + 'flurry' }),
    it('momentum-below-half', (o) => { o.flurry.momentum = 0.4; }, { rule: 'minimum', pointer: B + 'flurry/momentum' }),
    it('momentum-above-one', (o) => { o.flurry.momentum = 1.1; }, { rule: 'maximum', pointer: B + 'flurry/momentum' }),
    it('momentum-type', (o) => { o.flurry.momentum = 'high'; }, { rule: 'type', pointer: B + 'flurry/momentum' }),
    it('momentum-even-ok', (o) => { o.flurry.momentum = 0.5; }, null),
    it('momentum-always-ok', (o) => { o.flurry.momentum = 1; }, null),
    it('shot-heavy-mul-required', (o) => { delete o.shotHeavyMul; }, { rule: 'required', pointer: '/brawl' }),
    it('shot-heavy-mul-zero', (o) => { o.shotHeavyMul = 0; }, { rule: 'exclusiveMinimum', pointer: B + 'shotHeavyMul' }),
    it('shot-heavy-mul-negative', (o) => { o.shotHeavyMul = -1; }, { rule: 'exclusiveMinimum', pointer: B + 'shotHeavyMul' }),
    it('shot-heavy-mul-type', (o) => { o.shotHeavyMul = 'double'; }, { rule: 'type', pointer: B + 'shotHeavyMul' }),
    it('shot-heavy-mul-fraction-ok', (o) => { o.shotHeavyMul = 0.5; }, null),
    it('nine-c-key-answer-by-unknown', (o) => { o.answerBy = 10; }, { rule: 'additionalProperties', pointer: B + 'answerBy' }),
    it('nine-c-key-guard-max-unknown', (o) => { o.flurry.guardMaxTicks = 10; }, { rule: 'additionalProperties', pointer: B + 'flurry/guardMaxTicks' }),
    it('run-lapse-still-below-trade-max', (o) => { o.flurry.runLapseTicks = 90; o.flurry.tradeMaxTicks = 90; }, { rule: 'xref:brawl-order', pointer: B + 'flurry/runLapseTicks' }),
    ai('heavy-after-close-required', (o) => { delete o.heavyAfterClose; }, { rule: 'required', pointer: '/levels/medium/brawl' }),
    ai('heavy-after-close-negative', (o) => { o.heavyAfterClose = -0.1; }, { rule: 'minimum', pointer: '/levels/medium/brawl/heavyAfterClose' }),
    ai('heavy-after-close-above-one', (o) => { o.heavyAfterClose = 1.1; }, { rule: 'maximum', pointer: '/levels/medium/brawl/heavyAfterClose' }),
    ai('heavy-after-close-type', (o) => { o.heavyAfterClose = 'often'; }, { rule: 'type', pointer: '/levels/medium/brawl/heavyAfterClose' }),
    ai('heavy-after-close-zero-ok', (o) => { o.heavyAfterClose = 0; }, null),
    ai('heavy-after-close-one-ok', (o) => { o.heavyAfterClose = 1; }, null),
    ai('attack-into-gap-unknown', (o) => { o.attackIntoGap = 0.5; }, { rule: 'additionalProperties', pointer: '/levels/medium/brawl/attackIntoGap' }),
    vs('valid', () => {}, null),
    vs('required', () => 'delete', { rule: 'required', pointer: '/levels/medium' }),
    vs('unknown-key', (o) => { o.mood = 1; }, { rule: 'additionalProperties', pointer: V + '/mood' }),
    vs('underscore-key-ok', (o) => { o._why = 'a note'; }, null),
    vs('guard-required', (o) => { delete o.guardShare; }, { rule: 'required', pointer: V }),
    vs('ender-required', (o) => { delete o.enderShare; }, { rule: 'required', pointer: V }),
    vs('approach-required', (o) => { delete o.heavyApproachShare; }, { rule: 'required', pointer: V }),
    vs('guard-negative', (o) => { o.guardShare = -0.1; }, { rule: 'minimum', pointer: V + '/guardShare' }),
    vs('guard-above-one', (o) => { o.guardShare = 1.5; }, { rule: 'maximum', pointer: V + '/guardShare' }),
    vs('ender-negative', (o) => { o.enderShare = -0.1; }, { rule: 'minimum', pointer: V + '/enderShare' }),
    vs('ender-above-one', (o) => { o.enderShare = 1.5; }, { rule: 'maximum', pointer: V + '/enderShare' }),
    vs('approach-negative', (o) => { o.heavyApproachShare = -0.1; }, { rule: 'minimum', pointer: V + '/heavyApproachShare' }),
    vs('approach-above-one', (o) => { o.heavyApproachShare = 1.5; }, { rule: 'maximum', pointer: V + '/heavyApproachShare' }),
    vs('approach-type', (o) => { o.heavyApproachShare = 'often'; }, { rule: 'type', pointer: V + '/heavyApproachShare' }),
    vs('edges-ok', (o) => { o.guardShare = 0; o.enderShare = 1; o.heavyApproachShare = 1; }, null),
  ];
  let n = 0;
  for (const k of add) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`brawl 9d schema applied (${n} new cases, ${moved} earlier cases updated${old >= 0 ? ', the closeAfter case retired' : ''})`);
}
