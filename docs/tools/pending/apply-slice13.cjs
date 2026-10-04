// Schema keys for Encounter's slice 13 (agency-pass.md section 22: timing paid on every press, flow paid in set-ups and contests, the
// tapped-heavy weak ender). NOT run by CI, the validator or the sim. Run once from the repo root, in the commit that lands the slice's data:
//     node docs/tools/pending/apply-slice13.cjs
// It does NOT edit data/. It adds:
//   data/director/alchemy.json     flow.dmgPer, flow.contest, flow.contestMax (numbers, 0 or more) and blur.timedMul (a number above 0),
//                                  blur.fullEnderFlow (an integer, 0 or more), all required
//   data/director/interrupts.json  blast.barrage.tappedHeavyWeak (a boolean, required)
// the fixtures' keys, the warning alchemy-flow when blur.fullEnderFlow is above flow.max, and the cases (the earlier whole-blast cases are
// patched to carry the new barrage key). ai.json's timedPress keeps its shape (values only). Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const n0 = (d) => ({ type: 'number', minimum: 0, description: d });

// placeholders for the fixtures until the live data carries the keys
const FX = { dmgPer: 0.05, contest: 1, contestMax: 3, timedMul: 1.2, fullEnderFlow: 5, tappedHeavyWeak: true };
const live = (f) => (fs.existsSync(f) ? rj(f) : null);
const liveAl = live('data/director/alchemy.json');
const liveIt = live('data/director/interrupts.json');
const haveAl = liveAl && liveAl.flow && liveAl.flow.dmgPer !== undefined && liveAl.blur && liveAl.blur.fullEnderFlow !== undefined;
const haveIt = liveIt && liveIt.blast && liveIt.blast.barrage && liveIt.blast.barrage.tappedHeavyWeak !== undefined;

// =============================== alchemy schema ===============================
{
  const f = 'tools/schemas/director-alchemy.schema.json';
  const s = rj(f);
  const fl = s.properties.flow;
  if (!fl.properties.dmgPer) {
    fl.properties.dmgPer = n0('The damage each flow adds to a blow of the string.');
    fl.properties.contest = n0('The flow a won contest pays.');
    fl.properties.contestMax = n0('The most flow contests can pay a string.');
    for (const k of ['dmgPer', 'contest', 'contestMax']) if (!fl.required.includes(k)) fl.required.push(k);
    const bl = s.properties.blur;
    bl.properties.timedMul = { type: 'number', exclusiveMinimum: 0, description: 'The multiplier of a timed press in a blur string.' };
    bl.properties.fullEnderFlow = { type: 'integer', minimum: 0, description: 'The flow at which the blur\'s ender is the full one (a warning if above flow.max).' };
    for (const k of ['timedMul', 'fullEnderFlow']) if (!bl.required.includes(k)) bl.required.push(k);
    wj(f, s);
  }
}

// =============================== interrupts schema ===============================
{
  const f = 'tools/schemas/director-interrupts.schema.json';
  const s = rj(f);
  const b = s.properties.blast.properties.barrage;
  if (!b.properties.tappedHeavyWeak) {
    b.properties.tappedHeavyWeak = { type: 'boolean', description: 'true: a tapped heavy blast ends a barrage with the weak ender.' };
    if (!b.required.includes('tappedHeavyWeak')) b.required.push('tappedHeavyWeak');
    wj(f, s);
  }
}

// =============================== fixtures ===============================
{
  const dir = 'tools/fixtures/virtual/data/director/';
  {
    const f = dir + 'alchemy.json';
    const o = rj(f);
    if (o.flow && o.flow.dmgPer === undefined) {
      for (const k of ['dmgPer', 'contest', 'contestMax']) o.flow[k] = haveAl ? liveAl.flow[k] : FX[k];
      for (const k of ['timedMul', 'fullEnderFlow']) o.blur[k] = haveAl ? liveAl.blur[k] : FX[k];
      wj(f, o);
    }
  }
  {
    const f = dir + 'interrupts.json';
    const o = rj(f);
    if (o.blast && o.blast.barrage && o.blast.barrage.tappedHeavyWeak === undefined) {
      o.blast.barrage.tappedHeavyWeak = haveIt ? liveIt.blast.barrage.tappedHeavyWeak : FX.tappedHeavyWeak;
      wj(f, o);
    }
  }
}

// =============================== xref ===============================
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes('fullEnderFlow')) {
    const a = "    for (const k of ['enderAfter', 'launchAt', 'showcaseAt']) if (typeof fl[k] === 'number' && typeof fl.max === 'number' && fl[k] > fl.max)";
    if (!t.includes(a)) throw new Error('alchemy flow anchor');
    t = t.replace(a, () => [
      "    if (isObj(alf.blur) && typeof alf.blur.fullEnderFlow === 'number' && typeof fl.max === 'number' && alf.blur.fullEnderFlow > fl.max) err(AF, '/blur/fullEnderFlow', 'alchemy-flow', `fullEnderFlow ${alf.blur.fullEnderFlow} is above flow.max ${fl.max}, so the blur's full ender never plays`, 'warning');",
      a,
    ].join('\n'));
    fs.writeFileSync(f, t);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const AL = 'data/director/alchemy.json';
  const IT = 'data/director/interrupts.json';
  // the earlier cases that build the whole blast block (or its barrage) need the new required key
  for (const k of c.cases) {
    if (!/^director-interrupts-/.test(k.id)) continue;
    for (const m of k.mutate || []) {
      const whole = m.set && m.set['/blast'];
      if (whole && typeof whole === 'object' && whole.barrage && typeof whole.barrage === 'object' && whole.barrage.tappedHeavyWeak === undefined) whole.barrage.tappedHeavyWeak = true;
      const bar = m.set && m.set['/blast/barrage'];
      if (bar && typeof bar === 'object' && bar.tappedHeavyWeak === undefined && !(k.expect && k.expect.rule === 'required' && k.expect.pointer === '/blast/barrage')) bar.tappedHeavyWeak = true;
    }
  }
  const al = (n, mut, expect) => ({ id: 'director-alchemy-' + n, schema: 'director-alchemy.schema.json', mutate: [{ file: AL, ...mut }], expect });
  const it = (n, mut, expect) => ({ id: 'director-interrupts-' + n, schema: 'director-interrupts.schema.json', mutate: [{ file: IT, ...mut }], expect });
  const F = '/flow/';
  const B = '/blur/';
  const add = [
    al('flow-dmg-per-required', { del: [F + 'dmgPer'] }, { rule: 'required', pointer: '/flow' }),
    al('flow-contest-required', { del: [F + 'contest'] }, { rule: 'required', pointer: '/flow' }),
    al('flow-contest-max-required', { del: [F + 'contestMax'] }, { rule: 'required', pointer: '/flow' }),
    al('flow-dmg-per-negative', { set: { [F + 'dmgPer']: -0.1 } }, { rule: 'minimum', pointer: F + 'dmgPer' }),
    al('flow-dmg-per-type', { set: { [F + 'dmgPer']: 'more' } }, { rule: 'type', pointer: F + 'dmgPer' }),
    al('flow-dmg-per-zero-ok', { set: { [F + 'dmgPer']: 0 } }, null),
    al('flow-contest-negative', { set: { [F + 'contest']: -1 } }, { rule: 'minimum', pointer: F + 'contest' }),
    al('flow-contest-fraction-ok', { set: { [F + 'contest']: 0.5 } }, null),
    al('flow-contest-max-negative', { set: { [F + 'contestMax']: -1 } }, { rule: 'minimum', pointer: F + 'contestMax' }),
    al('flow-contest-max-type', { set: { [F + 'contestMax']: 'lots' } }, { rule: 'type', pointer: F + 'contestMax' }),
    al('blur-timed-mul-required', { del: [B + 'timedMul'] }, { rule: 'required', pointer: '/blur' }),
    al('blur-timed-mul-zero', { set: { [B + 'timedMul']: 0 } }, { rule: 'exclusiveMinimum', pointer: B + 'timedMul' }),
    al('blur-timed-mul-type', { set: { [B + 'timedMul']: 'double' } }, { rule: 'type', pointer: B + 'timedMul' }),
    al('blur-timed-mul-below-one-ok', { set: { [B + 'timedMul']: 0.5 } }, null),
    al('blur-full-ender-flow-required', { del: [B + 'fullEnderFlow'] }, { rule: 'required', pointer: '/blur' }),
    al('blur-full-ender-flow-negative', { set: { [B + 'fullEnderFlow']: -1 } }, { rule: 'minimum', pointer: B + 'fullEnderFlow' }),
    al('blur-full-ender-flow-integer', { set: { [B + 'fullEnderFlow']: 3.5 } }, { rule: 'type', pointer: B + 'fullEnderFlow' }),
    al('blur-full-ender-flow-zero-ok', { set: { [B + 'fullEnderFlow']: 0 } }, null),
    al('blur-full-ender-flow-above-max-warns', { set: { [B + 'fullEnderFlow']: 99 } }, { rule: 'xref:alchemy-flow', pointer: B + 'fullEnderFlow' }),
    al('blur-full-ender-flow-at-max-ok', { set: { [B + 'fullEnderFlow']: 5, [F + 'max']: 5 } }, null),
    it('blast-barrage-tapped-heavy-weak-required', { del: ['/blast/barrage/tappedHeavyWeak'] }, { rule: 'required', pointer: '/blast/barrage' }),
    it('blast-barrage-tapped-heavy-weak-type', { set: { '/blast/barrage/tappedHeavyWeak': 'yes' } }, { rule: 'type', pointer: '/blast/barrage/tappedHeavyWeak' }),
    it('blast-barrage-tapped-heavy-weak-off-ok', { set: { '/blast/barrage/tappedHeavyWeak': false } }, null),
  ];
  let n = 0;
  for (const k of add) if (!c.cases.some((y) => y.id === k.id)) { c.cases.push(k); n++; }
  wj(cf, c);
  console.log(`slice 13 schema applied (${n} new cases)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes('fullEnderFlow')) {
    const a = 'enderAfter, launchAt or showcaseAt above max are warnings';
    if (t.includes(a)) t = t.replace(a, () => 'enderAfter, launchAt or showcaseAt above max, and blur.fullEnderFlow above max, are warnings');
    else {
      const line = t.split('\n').find((l) => l.includes('`alchemy-flow`'));
      if (!line) throw new Error('slice 13 README anchor');
      t = t.replace(line, () => line.replace(/ \|$/, () => '; blur.fullEnderFlow above flow.max is a warning |'));
    }
    fs.writeFileSync(f, t);
  }
}
