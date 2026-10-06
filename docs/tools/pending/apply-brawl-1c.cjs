// Schema keys for Encounter's perfect-block and reversal slice (Game Design: docs/design/melee-press-feel.md section 9f). NOT run by CI, the
// validator or the sim. Run once from the repo root, in the commit that lands the slice's data (after apply-brawl-9d.cjs, applied):
//     node docs/tools/pending/apply-brawl-1c.cjs
// It does NOT edit data/. Keys fixed by Encounter:
//   data/director/interrupts.json  the brawl block gains, all required: perfectBlock {staggerTicks (integer, at least 1; 20)} (closed; this one is
//                                  INSIDE brawl: the file's own top-level perfectBlock is another record), riposteTicks (integer, at least 1; 30),
//                                  riposteReelTicks (integer, 0 or more; 8) and reversal {contactTicks, staggerTicks} (integers, at least 1; 10 and
//                                  20; closed)
//   data/director/launch.json      setup.weight.riposte (a number, 0 to 1; 0.34), required; the launch-setup warning for an unknown weight kind
//                                  learns `riposte` (a decisive kind)
// No new key in ai.json. The ai-levels-order warning (medium barrageGuard below easy's) is left as it is: Encounter raises the value in this slice.
// The fixtures and the earlier cases that set a whole brawl block (or a whole setup.weight) follow; the new cases set their own whole blocks.
// Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const obj = (props, opts = {}) => Object.assign({ type: 'object', required: opts.required === undefined ? Object.keys(props) : opts.required, properties: props }, opts.description ? { description: opts.description } : {}, closed);
const clone = (o) => JSON.parse(JSON.stringify(o));
const BRAWL_NEW = { perfectBlock: { staggerTicks: 20 }, riposteTicks: 30, riposteReelTicks: 8, reversal: { contactTicks: 10, staggerTicks: 20 } };

// =============================== interrupts schema ===============================
{
  const f = 'tools/schemas/director-interrupts.schema.json';
  const s = rj(f);
  const b = s.properties.brawl;
  let changed = false;
  const add = (k, v) => { if (!b.properties[k]) { b.properties[k] = v; changed = true; } if (!b.required.includes(k)) { b.required.push(k); changed = true; } };
  add('perfectBlock', obj({ staggerTicks: { type: 'integer', minimum: 1, description: 'Ticks the attacker staggers in place after a perfect block in a brawl.' } }, { description: 'A perfect block inside a brawl (melee-press-feel.md section 9f); not the top-level perfectBlock.' }));
  add('riposteTicks', { type: 'integer', minimum: 1, description: 'The window, in ticks after a perfect block, in which the defender\'s next attack cannot be blocked or dodged.' });
  add('riposteReelTicks', { type: 'integer', minimum: 0, description: 'The reel, in ticks, a light riposte gives.' });
  add('reversal', obj({
    contactTicks: { type: 'integer', minimum: 1, description: 'Ticks from the press to the reversal heavy\'s contact.' },
    staggerTicks: { type: 'integer', minimum: 1, description: 'Ticks the attacker staggers in place after a reversal.' },
  }, { description: 'A reversal inside a brawl (melee-press-feel.md section 9f).' }));
  if (changed) wj(f, s);
}

// =============================== launch schema ===============================
{
  const f = 'tools/schemas/director-launch.schema.json';
  const s = rj(f);
  const w = s.properties.setup.properties.weight;
  let changed = false;
  if (!w.required.includes('riposte')) { w.required.push('riposte'); changed = true; }
  if (!/riposte/.test(w.description)) { w.description = w.description.replace('barrage: default)', 'barrage: default); riposte for a riposte after a perfect block (melee-press-feel.md section 9f)'); changed = true; }
  if (changed) wj(f, s);
}

// =============================== fixtures ===============================
{
  const dir = 'tools/fixtures/virtual/data/director/';
  {
    const f = dir + 'interrupts.json';
    const o = rj(f);
    let changed = false;
    if (o.brawl) for (const [k, v] of Object.entries(BRAWL_NEW)) if (o.brawl[k] === undefined) { o.brawl[k] = clone(v); changed = true; }
    if (changed) wj(f, o);
  }
  {
    const f = dir + 'launch.json';
    const o = rj(f);
    if (o.setup && o.setup.weight && o.setup.weight.riposte === undefined) { o.setup.weight.riposte = 0.34; wj(f, o); }
  }
}

// =============================== xref ===============================
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes("'barrage', 'riposte'].includes(k)")) {
    const a = "'blast', 'barrage'].includes(k)";
    if (!t.includes(a)) throw new Error('launch-setup anchor');
    t = t.replace(a, () => "'blast', 'barrage', 'riposte'].includes(k)");
    t = t.replace('beam_clash, blast, barrage), default, blurPlain or barragePlain', () => 'beam_clash, blast, barrage, riposte), default, blurPlain or barragePlain');
    fs.writeFileSync(f, t);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const IT = 'data/director/interrupts.json';
  const LA = 'data/director/launch.json';
  // the earlier cases that set a whole block follow the new keys
  let moved = 0;
  for (const k of c.cases) {
    for (const m of k.mutate || []) {
      if (!m.set) continue;
      if (m.file === IT && m.set['/brawl'] && typeof m.set['/brawl'] === 'object') {
        for (const [key, v] of Object.entries(BRAWL_NEW)) if (m.set['/brawl'][key] === undefined) { m.set['/brawl'][key] = clone(v); moved++; }
      }
      if (m.file === LA && m.set['/setup/weight'] && typeof m.set['/setup/weight'] === 'object' && m.set['/setup/weight'].riposte === undefined) { m.set['/setup/weight'].riposte = 0.34; moved++; }
    }
  }
  const VALID = {
    enabled: true, interrupts: ['hit', 'guard'], breakBh: 6, pullBhPerSec: 0.5, stepInTicks: 6, idleTicks: 90, heldPressTicks: 12, stringLapseTicks: 60, enderAfter: 5, recoil: 0.2, damageMul: 1, aiPerfectEveryTicks: 120, aiReversalEveryTicks: 180, tradeTicks: 8, heldMul: 1.2, skillMul: 1.2, setMul: 0.8, heavyMul: 1.5,
    light: { damage: 6, contactTicks: 6, blowTicks: 12, recover: 10 },
    flurry: { minGap: 4, maxGap: 20, mul: [[6, 0.6], [12, 1.2]], reelTicks: 10, staggerTicks: 8, runToClose: 4, replyTakes: 1, runLapseTicks: 24, tradeMaxTicks: 90, staggeredAddsRun: false, levelWithin: 1, momentum: 0.9, closeGuardTicks: 90 },
    heavy: { damage: 30, ki: 8, windupTicks: 20, landTicks: 6, recover: 20, recoverWhiff: 30, heldFullTicks: 40, heldMaxTicks: 60, heldLandTicks: 8, staggerTicks: 20, force: 1 },
    hitstop: { light: 2, heavy: 5 },
    shotHeavyMul: 2,
    shooter: { firedTicks: 90, noMeleeTicks: 120 },
  };
  Object.assign(VALID, clone(BRAWL_NEW));
  const it = (n, tweak, expect) => { const o = clone(VALID); tweak(o); return { id: 'director-interrupts-brawl1c-' + n, schema: 'director-interrupts.schema.json', mutate: [{ file: IT, set: { '/brawl': o } }], expect }; };
  const lw = (n, tweak, expect) => { const o = { default: 1, blurPlain: 0.34, barragePlain: 0.5, riposte: 0.34 }; tweak(o); return { id: 'director-launch-setup-riposte-' + n, schema: 'director-launch.schema.json', mutate: [{ file: LA, set: { '/setup/weight': o } }], expect }; };
  const B = '/brawl/';
  const add = [
    it('valid', () => {}, null),
    it('perfect-block-required', (o) => { delete o.perfectBlock; }, { rule: 'required', pointer: '/brawl' }),
    it('perfect-block-type', (o) => { o.perfectBlock = 20; }, { rule: 'type', pointer: B + 'perfectBlock' }),
    it('perfect-block-unknown-key', (o) => { o.perfectBlock.mood = 1; }, { rule: 'additionalProperties', pointer: B + 'perfectBlock/mood' }),
    it('perfect-block-underscore-key-ok', (o) => { o.perfectBlock._why = 'a note'; }, null),
    it('perfect-block-stagger-required', (o) => { delete o.perfectBlock.staggerTicks; }, { rule: 'required', pointer: B + 'perfectBlock' }),
    it('perfect-block-stagger-zero', (o) => { o.perfectBlock.staggerTicks = 0; }, { rule: 'minimum', pointer: B + 'perfectBlock/staggerTicks' }),
    it('perfect-block-stagger-integer', (o) => { o.perfectBlock.staggerTicks = 20.5; }, { rule: 'type', pointer: B + 'perfectBlock/staggerTicks' }),
    it('perfect-block-stagger-one-ok', (o) => { o.perfectBlock.staggerTicks = 1; }, null),
    it('riposte-ticks-required', (o) => { delete o.riposteTicks; }, { rule: 'required', pointer: '/brawl' }),
    it('riposte-ticks-zero', (o) => { o.riposteTicks = 0; }, { rule: 'minimum', pointer: B + 'riposteTicks' }),
    it('riposte-ticks-integer', (o) => { o.riposteTicks = 30.5; }, { rule: 'type', pointer: B + 'riposteTicks' }),
    it('riposte-ticks-type', (o) => { o.riposteTicks = 'long'; }, { rule: 'type', pointer: B + 'riposteTicks' }),
    it('riposte-ticks-one-ok', (o) => { o.riposteTicks = 1; }, null),
    it('riposte-reel-required', (o) => { delete o.riposteReelTicks; }, { rule: 'required', pointer: '/brawl' }),
    it('riposte-reel-negative', (o) => { o.riposteReelTicks = -1; }, { rule: 'minimum', pointer: B + 'riposteReelTicks' }),
    it('riposte-reel-integer', (o) => { o.riposteReelTicks = 8.5; }, { rule: 'type', pointer: B + 'riposteReelTicks' }),
    it('riposte-reel-zero-ok', (o) => { o.riposteReelTicks = 0; }, null),
    it('reversal-required', (o) => { delete o.reversal; }, { rule: 'required', pointer: '/brawl' }),
    it('reversal-type', (o) => { o.reversal = 10; }, { rule: 'type', pointer: B + 'reversal' }),
    it('reversal-unknown-key', (o) => { o.reversal.mood = 1; }, { rule: 'additionalProperties', pointer: B + 'reversal/mood' }),
    it('reversal-contact-required', (o) => { delete o.reversal.contactTicks; }, { rule: 'required', pointer: B + 'reversal' }),
    it('reversal-stagger-required', (o) => { delete o.reversal.staggerTicks; }, { rule: 'required', pointer: B + 'reversal' }),
    it('reversal-contact-zero', (o) => { o.reversal.contactTicks = 0; }, { rule: 'minimum', pointer: B + 'reversal/contactTicks' }),
    it('reversal-contact-integer', (o) => { o.reversal.contactTicks = 10.5; }, { rule: 'type', pointer: B + 'reversal/contactTicks' }),
    it('reversal-stagger-zero', (o) => { o.reversal.staggerTicks = 0; }, { rule: 'minimum', pointer: B + 'reversal/staggerTicks' }),
    it('reversal-stagger-integer', (o) => { o.reversal.staggerTicks = 20.5; }, { rule: 'type', pointer: B + 'reversal/staggerTicks' }),
    it('reversal-one-one-ok', (o) => { o.reversal.contactTicks = 1; o.reversal.staggerTicks = 1; }, null),
    it('top-level-perfect-block-is-another-record', (o) => { o.perfectBlock = { ki: 5 }; }, { rule: 'additionalProperties', pointer: B + 'perfectBlock/ki' }),
    lw('valid', () => {}, null),
    lw('required', (o) => { delete o.riposte; }, { rule: 'required', pointer: '/setup/weight' }),
    lw('negative', (o) => { o.riposte = -0.1; }, { rule: 'minimum', pointer: '/setup/weight/riposte' }),
    lw('above-one', (o) => { o.riposte = 1.1; }, { rule: 'maximum', pointer: '/setup/weight/riposte' }),
    lw('type', (o) => { o.riposte = 'a third'; }, { rule: 'type', pointer: '/setup/weight/riposte' }),
    lw('zero-ok', (o) => { o.riposte = 0; }, null),
    lw('one-ok', (o) => { o.riposte = 1; }, null),
    lw('is-a-known-kind', (o) => { o.riposte = 0.5; }, null),
    lw('other-unknown-kind-still-warns', (o) => { o.sneeze = 0.5; }, { rule: 'xref:launch-setup', pointer: '/setup/weight/sneeze' }),
  ];
  let n = 0;
  for (const k of add) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`brawl 1c schema applied (${n} new cases, ${moved} earlier values added)`);
}
