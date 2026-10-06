// Schema keys for Encounter's control slice C1 (the brawl's stick: the nudge, the step, the carry, the part and the double). NOT run by CI, the
// validator or the sim. Run once from the repo root, in the commit that lands the slice's data (after apply-brawl-1c.cjs, applied):
//     node docs/tools/pending/apply-brawl-c1.cjs
// It does NOT edit data/. Names and shapes are Encounter's and final; the ranges are generous, because the values will move in tuning.
//   data/director/interrupts.json  the brawl block gains, all required:
//     nudgeMul (number, 0 to 1; 0.4: a stick's share of his free-flight speed), nudgeRampTicks (integer, 0 or more; 8),
//     nudge {guard (number, 0 or more; 0.6), clearBh (number, 0 or more; 0.5)} (closed), maxStepBh (number, 0 or more; 0.3),
//     carryShare (number, 0 to 1; 0.5), carryTicks (integer, 0 or more; 20), partTicks (integer, 0 or more; 12), partDeg (number, above 0 and at
//     most 180; 45), double {windupTicks (integer, 0 or more; 8), throwBh (number, 0 or more; 6), throwTicks (integer, 0 or more; 24)} (closed),
//     and brawl.flurry gains doubleTicks (integer, 0 or more; 240).
//     REMOVED: brawl.flurry.momentum (naming it is an unknown key; the case that said it was required now says it is retired).
//   data/director/ai.json          each level's brawl gains nudgeShare and walkOut (numbers, 0 to 1), required.
// Not a key: brawl.nudgeDigital (Controls' aim.nudgeStart and aim.nudgeTicks in data/input/timing.json replace it).
// The fixtures and the earlier cases that set a whole brawl block (or a level's) follow; the new cases set their own whole blocks. Re-runnable.
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const obj = (props, opts = {}) => Object.assign({ type: 'object', required: opts.required === undefined ? Object.keys(props) : opts.required, properties: props }, opts.description ? { description: opts.description } : {}, closed);
const clone = (o) => JSON.parse(JSON.stringify(o));
const share = (d) => ({ type: 'number', minimum: 0, maximum: 1, description: d });
const num0 = (d) => ({ type: 'number', minimum: 0, description: d });
const ticks0 = (d) => ({ type: 'integer', minimum: 0, description: d });
const BRAWL_NEW = { nudgeMul: 0.4, nudgeRampTicks: 8, nudge: { guard: 0.6, clearBh: 0.5 }, maxStepBh: 0.3, carryShare: 0.5, carryTicks: 20, partTicks: 12, partDeg: 45, double: { windupTicks: 8, throwBh: 6, throwTicks: 24 } };
const DOUBLE_TICKS = 240;
const AI_NEW = { nudgeShare: 0.5, walkOut: 0.3 };
const AI_BY_LEVEL = { easy: { nudgeShare: 0.2, walkOut: 0.1 }, medium: { nudgeShare: 0.5, walkOut: 0.3 }, hard: { nudgeShare: 0.8, walkOut: 0.5 } };

// =============================== interrupts schema ===============================
{
  const f = 'tools/schemas/director-interrupts.schema.json';
  const s = rj(f);
  const b = s.properties.brawl;
  const fl = b.properties.flurry;
  let changed = false;
  const add = (k, v) => { if (!b.properties[k]) { b.properties[k] = v; changed = true; } if (!b.required.includes(k)) { b.required.push(k); changed = true; } };
  add('nudgeMul', share('A stick\'s share of his free-flight speed in a brawl.'));
  add('nudgeRampTicks', ticks0('Ticks the nudge takes to rise to full.'));
  add('nudge', obj({ guard: num0('The nudge\'s share while a guard is up.'), clearBh: num0('The clearance, in body heights, the nudge keeps from the rival.') }, { description: 'Limits on the nudge.' }));
  add('maxStepBh', num0('The most a step moves him, in body heights.'));
  add('carryShare', share('The share of a blow\'s motion that carries on after it.'));
  add('carryTicks', ticks0('Ticks the carry lasts.'));
  add('partTicks', ticks0('Ticks the fighters take to part.'));
  add('partDeg', { type: 'number', exclusiveMinimum: 0, maximum: 180, description: 'The angle, in degrees, at which they part.' });
  add('double', obj({ windupTicks: ticks0('The double\'s wind-up, in ticks.'), throwBh: num0('How far the double throws the rival, in body heights.'), throwTicks: ticks0('Ticks the throw takes.') }, { description: 'The double (a flurry\'s two-handed finish).' }));
  if (!fl.properties.doubleTicks) { fl.properties.doubleTicks = ticks0('Ticks within which a flurry may end in the double.'); changed = true; }
  if (!fl.required.includes('doubleTicks')) { fl.required.push('doubleTicks'); changed = true; }
  if (fl.properties.momentum) { delete fl.properties.momentum; changed = true; }
  fl.required = fl.required.filter((k) => k !== 'momentum');
  if (changed) wj(f, s);
}

// =============================== ai schema ===============================
{
  const f = 'tools/schemas/director-ai.schema.json';
  const s = rj(f);
  let changed = false;
  for (const name of ['easy', 'medium', 'hard']) {
    const b = s.properties.levels.properties[name].properties.brawl;
    for (const [k, d] of [['nudgeShare', 'The chance the AI nudges with the stick in a brawl.'], ['walkOut', 'The chance the AI walks out of a brawl.']]) {
      if (!b.properties[k]) { b.properties[k] = share(d); changed = true; }
      if (!b.required.includes(k)) { b.required.push(k); changed = true; }
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
    if (o.brawl) {
      let ch = false;
      for (const [k, v] of Object.entries(BRAWL_NEW)) if (o.brawl[k] === undefined) { o.brawl[k] = clone(v); ch = true; }
      if (o.brawl.flurry) {
        if (o.brawl.flurry.doubleTicks === undefined) { o.brawl.flurry.doubleTicks = DOUBLE_TICKS; ch = true; }
        if (o.brawl.flurry.momentum !== undefined) { delete o.brawl.flurry.momentum; ch = true; }
      }
      if (ch) wj(f, o);
    }
  }
  {
    const f = dir + 'ai.json';
    const o = rj(f);
    let ch = false;
    for (const name of ['easy', 'medium', 'hard']) {
      const b = o.levels && o.levels[name] && o.levels[name].brawl;
      if (!b) continue;
      for (const k of Object.keys(AI_NEW)) if (b[k] === undefined) { b[k] = AI_BY_LEVEL[name][k]; ch = true; }
    }
    if (ch) wj(f, o);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const IT = 'data/director/interrupts.json';
  const AI = 'data/director/ai.json';
  // the earlier cases that set a whole block follow the new keys, and the momentum cases go (the key is retired)
  let moved = 0;
  c.cases = c.cases.filter((k) => !/^director-interrupts-brawl9d-momentum-/.test(k.id));
  for (const k of c.cases) {
    if (/brawlc1-/.test(k.id)) continue; // this script's own cases set their own whole blocks
    for (const m of k.mutate || []) {
      if (!m.set) continue;
      const bl = m.file === IT ? m.set['/brawl'] : undefined;
      if (bl && typeof bl === 'object') {
        for (const [key, v] of Object.entries(BRAWL_NEW)) if (bl[key] === undefined) { bl[key] = clone(v); moved++; }
        if (bl.flurry && typeof bl.flurry === 'object') {
          if (bl.flurry.doubleTicks === undefined) { bl.flurry.doubleTicks = DOUBLE_TICKS; moved++; }
          if (bl.flurry.momentum !== undefined) { delete bl.flurry.momentum; moved++; }
        }
      }
      if (m.file === AI) {
        for (const key of Object.keys(m.set)) {
          const mm = /^\/levels\/(easy|medium|hard)\/brawl$/.exec(key);
          if (mm && m.set[key] && typeof m.set[key] === 'object') for (const [nk, nv] of Object.entries(AI_NEW)) if (m.set[key][nk] === undefined) { m.set[key][nk] = nv; moved++; }
        }
      }
    }
  }
  const VALID = {
    enabled: true, interrupts: ['hit', 'guard'], breakBh: 6, pullBhPerSec: 0.5, stepInTicks: 6, idleTicks: 90, heldPressTicks: 12, stringLapseTicks: 60, enderAfter: 5, recoil: 0.2, damageMul: 1, aiPerfectEveryTicks: 120, aiReversalEveryTicks: 180, tradeTicks: 8, heldMul: 1.2, skillMul: 1.2, setMul: 0.8, heavyMul: 1.5,
    light: { damage: 6, contactTicks: 6, blowTicks: 12, recover: 10 },
    flurry: { minGap: 4, maxGap: 20, mul: [[6, 0.6], [12, 1.2]], reelTicks: 10, staggerTicks: 8, runToClose: 4, replyTakes: 1, runLapseTicks: 24, tradeMaxTicks: 90, staggeredAddsRun: false, levelWithin: 1, closeGuardTicks: 90, doubleTicks: DOUBLE_TICKS },
    heavy: { damage: 30, ki: 8, windupTicks: 20, landTicks: 6, recover: 20, recoverWhiff: 30, heldFullTicks: 40, heldMaxTicks: 60, heldLandTicks: 8, staggerTicks: 20, force: 1 },
    hitstop: { light: 2, heavy: 5 },
    shotHeavyMul: 2,
    shooter: { firedTicks: 90, noMeleeTicks: 120 },
    perfectBlock: { staggerTicks: 20 }, riposteTicks: 30, riposteReelTicks: 8, reversal: { contactTicks: 10, staggerTicks: 20 },
  };
  Object.assign(VALID, clone(BRAWL_NEW));
  const VALID_AI = { tapGap: 8, string: [3, 6], enderShare: 0.4, rashHeavy: 0.1, guardShare: 0.3, guardTicks: [20, 60], perfectMul: 1, heavyAfterClose: 0.6, nudgeShare: 0.5, walkOut: 0.3 };
  const it = (n, tweak, expect) => { const o = clone(VALID); tweak(o); return { id: 'director-interrupts-brawlc1-' + n, schema: 'director-interrupts.schema.json', mutate: [{ file: IT, set: { '/brawl': o } }], expect }; };
  const ai = (n, tweak, expect) => { const o = clone(VALID_AI); tweak(o); return { id: 'director-ai-brawlc1-' + n, schema: 'director-ai.schema.json', mutate: [{ file: AI, set: { '/levels/medium/brawl': o } }], expect }; };
  const B = '/brawl/';
  const add = [
    it('valid', () => {}, null),
    it('momentum-retired', (o) => { o.flurry.momentum = 0.9; }, { rule: 'additionalProperties', pointer: B + 'flurry/momentum' }),
    it('nudge-digital-is-not-a-key', (o) => { o.nudgeDigital = 0.4; }, { rule: 'additionalProperties', pointer: B + 'nudgeDigital' }),
    // numbers and ticks of the block
    ...[['nudgeMul', 'share'], ['carryShare', 'share']].flatMap(([k]) => [
      it(k.toLowerCase() + '-required', (o) => { delete o[k]; }, { rule: 'required', pointer: '/brawl' }),
      it(k.toLowerCase() + '-negative', (o) => { o[k] = -0.1; }, { rule: 'minimum', pointer: B + k }),
      it(k.toLowerCase() + '-above-one', (o) => { o[k] = 1.1; }, { rule: 'maximum', pointer: B + k }),
      it(k.toLowerCase() + '-type', (o) => { o[k] = 'some'; }, { rule: 'type', pointer: B + k }),
      it(k.toLowerCase() + '-edges-ok', (o) => { o[k] = 0; }, null),
      it(k.toLowerCase() + '-one-ok', (o) => { o[k] = 1; }, null),
    ]),
    ...['nudgeRampTicks', 'carryTicks', 'partTicks'].flatMap((k) => [
      it(k.toLowerCase() + '-required', (o) => { delete o[k]; }, { rule: 'required', pointer: '/brawl' }),
      it(k.toLowerCase() + '-negative', (o) => { o[k] = -1; }, { rule: 'minimum', pointer: B + k }),
      it(k.toLowerCase() + '-integer', (o) => { o[k] = 8.5; }, { rule: 'type', pointer: B + k }),
      it(k.toLowerCase() + '-zero-ok', (o) => { o[k] = 0; }, null),
    ]),
    it('maxstepbh-required', (o) => { delete o.maxStepBh; }, { rule: 'required', pointer: '/brawl' }),
    it('maxstepbh-negative', (o) => { o.maxStepBh = -0.1; }, { rule: 'minimum', pointer: B + 'maxStepBh' }),
    it('maxstepbh-type', (o) => { o.maxStepBh = 'small'; }, { rule: 'type', pointer: B + 'maxStepBh' }),
    it('maxstepbh-large-ok', (o) => { o.maxStepBh = 5; }, null),
    it('partdeg-required', (o) => { delete o.partDeg; }, { rule: 'required', pointer: '/brawl' }),
    it('partdeg-zero', (o) => { o.partDeg = 0; }, { rule: 'exclusiveMinimum', pointer: B + 'partDeg' }),
    it('partdeg-above-180', (o) => { o.partDeg = 181; }, { rule: 'maximum', pointer: B + 'partDeg' }),
    it('partdeg-type', (o) => { o.partDeg = 'wide'; }, { rule: 'type', pointer: B + 'partDeg' }),
    it('partdeg-180-ok', (o) => { o.partDeg = 180; }, null),
    // the nudge block
    it('nudge-required', (o) => { delete o.nudge; }, { rule: 'required', pointer: '/brawl' }),
    it('nudge-type', (o) => { o.nudge = 0.6; }, { rule: 'type', pointer: B + 'nudge' }),
    it('nudge-unknown-key', (o) => { o.nudge.mood = 1; }, { rule: 'additionalProperties', pointer: B + 'nudge/mood' }),
    it('nudge-note-ok', (o) => { o.nudge._why = 'a note'; }, null),
    it('nudge-guard-required', (o) => { delete o.nudge.guard; }, { rule: 'required', pointer: B + 'nudge' }),
    it('nudge-clear-required', (o) => { delete o.nudge.clearBh; }, { rule: 'required', pointer: B + 'nudge' }),
    it('nudge-guard-negative', (o) => { o.nudge.guard = -0.1; }, { rule: 'minimum', pointer: B + 'nudge/guard' }),
    it('nudge-clear-negative', (o) => { o.nudge.clearBh = -0.1; }, { rule: 'minimum', pointer: B + 'nudge/clearBh' }),
    it('nudge-clear-type', (o) => { o.nudge.clearBh = 'near'; }, { rule: 'type', pointer: B + 'nudge/clearBh' }),
    it('nudge-zero-ok', (o) => { o.nudge.guard = 0; o.nudge.clearBh = 0; }, null),
    // the double
    it('double-required', (o) => { delete o.double; }, { rule: 'required', pointer: '/brawl' }),
    it('double-type', (o) => { o.double = 8; }, { rule: 'type', pointer: B + 'double' }),
    it('double-unknown-key', (o) => { o.double.mood = 1; }, { rule: 'additionalProperties', pointer: B + 'double/mood' }),
    it('double-windup-required', (o) => { delete o.double.windupTicks; }, { rule: 'required', pointer: B + 'double' }),
    it('double-throw-bh-required', (o) => { delete o.double.throwBh; }, { rule: 'required', pointer: B + 'double' }),
    it('double-throw-ticks-required', (o) => { delete o.double.throwTicks; }, { rule: 'required', pointer: B + 'double' }),
    it('double-windup-negative', (o) => { o.double.windupTicks = -1; }, { rule: 'minimum', pointer: B + 'double/windupTicks' }),
    it('double-windup-integer', (o) => { o.double.windupTicks = 8.5; }, { rule: 'type', pointer: B + 'double/windupTicks' }),
    it('double-throw-bh-negative', (o) => { o.double.throwBh = -1; }, { rule: 'minimum', pointer: B + 'double/throwBh' }),
    it('double-throw-bh-fraction-ok', (o) => { o.double.throwBh = 6.5; }, null),
    it('double-throw-ticks-negative', (o) => { o.double.throwTicks = -1; }, { rule: 'minimum', pointer: B + 'double/throwTicks' }),
    it('double-throw-ticks-integer', (o) => { o.double.throwTicks = 24.5; }, { rule: 'type', pointer: B + 'double/throwTicks' }),
    // the flurry's double window
    it('double-ticks-required', (o) => { delete o.flurry.doubleTicks; }, { rule: 'required', pointer: B + 'flurry' }),
    it('double-ticks-negative', (o) => { o.flurry.doubleTicks = -1; }, { rule: 'minimum', pointer: B + 'flurry/doubleTicks' }),
    it('double-ticks-integer', (o) => { o.flurry.doubleTicks = 240.5; }, { rule: 'type', pointer: B + 'flurry/doubleTicks' }),
    it('double-ticks-zero-ok', (o) => { o.flurry.doubleTicks = 0; }, null),
    // the AI
    ai('valid', () => {}, null),
    ...['nudgeShare', 'walkOut'].flatMap((k) => [
      ai(k.toLowerCase() + '-required', (o) => { delete o[k]; }, { rule: 'required', pointer: '/levels/medium/brawl' }),
      ai(k.toLowerCase() + '-negative', (o) => { o[k] = -0.1; }, { rule: 'minimum', pointer: '/levels/medium/brawl/' + k }),
      ai(k.toLowerCase() + '-above-one', (o) => { o[k] = 1.1; }, { rule: 'maximum', pointer: '/levels/medium/brawl/' + k }),
      ai(k.toLowerCase() + '-type', (o) => { o[k] = 'often'; }, { rule: 'type', pointer: '/levels/medium/brawl/' + k }),
      ai(k.toLowerCase() + '-edges-ok', (o) => { o[k] = 0; }, null),
      ai(k.toLowerCase() + '-one-ok', (o) => { o[k] = 1; }, null),
    ]),
  ];
  let n = 0;
  for (const k of add) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`brawl C1 schema applied (${n} new cases, ${moved} earlier values changed)`);
}
