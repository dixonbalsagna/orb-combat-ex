// Schema keys for Encounter's slice B1, the first brawl (docs/director/brawl-plan.md). NOT run by CI, the validator or the sim.
// Run once from the repo root, in the commit that lands the slice's data:
//     node docs/tools/pending/apply-brawl1.cjs
// It does NOT edit data/. It adds:
//   data/director/interrupts.json  the required top-level `brawl` {enabled, interrupts[], breakBh, pullBhPerSec, stepInTicks, idleTicks,
//                                  heldPressTicks, stringLapseTicks, enderAfter, recoil, damageMul, aiPerfectEveryTicks,
//                                  aiReversalEveryTicks, light {damage, contactTicks, blowTicks}, flurry {minGap, maxGap, mul [[gap, share]],
//                                  reelTicks, closeAfter, staggerTicks, runToClose, replyTakes,
//                                  runLapseTicks, tradeMaxTicks}, heavy {damage, ki, windupTicks, landTicks, recoverTicks,
//                                  heldFullTicks, heldMaxTicks, heldLandTicks, staggerTicks, force}, hitstop {light, heavy}} (closed; _note
//                                  allowed) and the optional perfectBlock.windows.blow (a number, 0 or more)
//   data/director/ai.json          per level the required `brawl` {tapGap, string [lo, hi], enderShare, rashHeavy, guardShare,
//                                  guardTicks [lo, hi], perfectMul} (`_brawl` is a note and is allowed)
// Ranges (mine, from the brief; tell me if a type is unclear): ticks are integers of 0 or more; shares 0 to 1; lo at most hi; flurry.minGap
// at most maxGap; the mul table's gaps strictly increasing and its multipliers above 0 up to 2; heavy.heldFullTicks at most heldMaxTicks.
// Encounter's final names: heavy.recover and heavy.recoverWhiff (both required; recoverTicks is gone), light.recover, tradeTicks (ticks) and
// heldMul (above 0), and skillMul, setMul and heavyMul (above 0), all required. flurry.mul has at least two points. The new cue name `trade`
// is a sim render cue that nothing in tools checks. Rules: brawl-order and ai-brawl.
// The fixtures get the keys, and every case sets its own values (a whole `brawl` block or level block), so none depends on the real file.
// Follows docs/design/melee-press-feel.md section 3 as of 2026-10-05: flurry gains four required keys, runToClose (integer, at least 1; 4),
// replyTakes (integer, 0 or more; 1), runLapseTicks (ticks; 24) and tradeMaxTicks (integer, at least 1; 90), and the rule brawl-order
// gains: runLapseTicks below tradeMaxTicks. Encounter's final key list may differ slightly; tell me and I change them.
// Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const obj = (props, opts = {}) => Object.assign({ type: 'object', required: opts.required === undefined ? Object.keys(props) : opts.required, properties: props }, opts.description ? { description: opts.description } : {}, closed);
const clone = (o) => JSON.parse(JSON.stringify(o));
const strip = (o) => Array.isArray(o) ? o : (o && typeof o === 'object' ? Object.fromEntries(Object.entries(o).filter(([k]) => !k.startsWith('_')).map(([k, v]) => [k, strip(v)])) : o);
const ticks = (d) => ({ type: 'integer', minimum: 0, description: d });
const num0 = (d) => ({ type: 'number', minimum: 0, description: d });
const share = (d) => ({ type: 'number', minimum: 0, maximum: 1, description: d });
const pair = (item, d) => ({ type: 'array', minItems: 2, maxItems: 2, items: item, description: d });

// a valid block of each, for the fixtures and for the cases
const VALID = {
  enabled: true,
  interrupts: ['hit', 'guard'],
  breakBh: 6,
  pullBhPerSec: 0.5,
  stepInTicks: 6,
  idleTicks: 90,
  heldPressTicks: 12,
  stringLapseTicks: 60,
  enderAfter: 5,
  recoil: 0.2,
  damageMul: 1,
  aiPerfectEveryTicks: 120,
  aiReversalEveryTicks: 180,
  tradeTicks: 8,
  heldMul: 1.2,
  skillMul: 1.2,
  setMul: 0.8,
  heavyMul: 1.5,
  light: { damage: 6, contactTicks: 6, blowTicks: 12, recover: 10 },
  flurry: { minGap: 4, maxGap: 20, mul: [[6, 0.6], [12, 1.2]], reelTicks: 10, closeAfter: 30, staggerTicks: 8, runToClose: 4, replyTakes: 1, runLapseTicks: 24, tradeMaxTicks: 90 },
  heavy: { damage: 30, ki: 8, windupTicks: 20, landTicks: 6, recover: 20, recoverWhiff: 30, heldFullTicks: 40, heldMaxTicks: 60, heldLandTicks: 8, staggerTicks: 20, force: 1 },
  hitstop: { light: 2, heavy: 5 },
};
const VALID_AI = { tapGap: 8, string: [3, 6], enderShare: 0.4, rashHeavy: 0.1, guardShare: 0.3, guardTicks: [20, 60], perfectMul: 1 };
const isPlain = (o) => o !== null && typeof o === 'object' && !Array.isArray(o);
const live = (f) => (fs.existsSync(f) ? rj(f) : null);
const liveIt = live('data/director/interrupts.json');
const liveAi = live('data/director/ai.json');
const haveIt = liveIt && liveIt.brawl;
const haveAi = liveAi && liveAi.levels && liveAi.levels.medium && liveAi.levels.medium.brawl;

// =============================== interrupts schema ===============================
{
  const f = 'tools/schemas/director-interrupts.schema.json';
  const s = rj(f);
  if (!s.properties.brawl) {
    s.properties.perfectBlock.properties.windows.properties.blow = num0('The last ticks of a brawl blow\'s wind-up in which a fresh guard press is a perfect block against it.');
    s.properties.brawl = obj({
      enabled: { type: 'boolean', description: 'false: no brawl; exchanges plan as before.' },
      interrupts: { type: 'array', uniqueItems: true, items: { type: 'string', pattern: '^[a-z][a-zA-Z0-9_]*$' }, description: 'What can interrupt a brawl.' },
      breakBh: { type: 'number', exclusiveMinimum: 0, description: 'The separation, in body heights, at which a brawl breaks.' },
      pullBhPerSec: num0('How fast the fighters are pulled back toward striking distance, in body heights a second.'),
      stepInTicks: ticks('The step in before a blow, in ticks.'),
      idleTicks: ticks('Ticks without a press after which the brawl idles.'),
      heldPressTicks: ticks('Ticks a press must be held to count as held.'),
      stringLapseTicks: ticks('Ticks after which a string lapses.'),
      enderAfter: { type: 'integer', minimum: 1, description: 'The blow of a string that can be its ender.' },
      recoil: num0('How far a blow leans the rival back.'),
      damageMul: num0('The multiplier on a brawl blow\'s damage.'),
      aiPerfectEveryTicks: ticks('The AI aims a perfect block about this often, in ticks.'),
      aiReversalEveryTicks: ticks('The AI aims a reversal about this often, in ticks.'),
      light: obj({ damage: num0('Damage of a light blow.'), contactTicks: ticks('Ticks to contact.'), blowTicks: ticks('Ticks of the whole blow.'), recover: ticks('Recovery after a light blow.') }),
      flurry: obj({
        minGap: ticks('The shortest gap between blows of a flurry, in ticks.'),
        maxGap: ticks('The longest gap that still counts as a flurry.'),
        mul: { type: 'array', minItems: 2, items: { type: 'array', minItems: 2, maxItems: 2, prefixItems: [ticks('Gap in ticks.'), { type: 'number', exclusiveMinimum: 0, maximum: 2, description: 'The multiplier on a blow\'s damage at that gap (above 0, up to 2; Game Design: x1.1 at an 11-tick gap, x1.2 at 12).' }], items: false }, description: 'Gap to damage multiplier, the gaps strictly increasing.' },
        reelTicks: ticks('Ticks the rival reels.'),
        closeAfter: ticks('Ticks after which a flurry closes.'),
        staggerTicks: ticks('Ticks of stagger a flurry\'s end gives.'),
        runToClose: { type: 'integer', minimum: 1, description: 'The run of blows after which a mash against a mash closes for whoever is winning the trade (Game Design, melee-press-feel.md section 3).' },
        replyTakes: { type: 'integer', minimum: 0, description: 'How many blows a reply takes off the rival\'s run.' },
        runLapseTicks: ticks('Ticks without a blow after which a run lapses; below tradeMaxTicks.'),
        tradeMaxTicks: { type: 'integer', minimum: 1, description: 'The most ticks a trade can last before it closes.' },
      }),
      heavy: obj({
        damage: num0('Damage of a heavy blow.'),
        ki: num0('The ki it costs.'),
        windupTicks: ticks('Wind-up.'),
        landTicks: ticks('Ticks to land.'),
        recover: ticks('Recovery after a heavy that lands.'),
        recoverWhiff: ticks('Recovery after a heavy that misses.'),
        heldFullTicks: ticks('Ticks held to a full charge.'),
        heldMaxTicks: ticks('The most it can be held.'),
        heldLandTicks: ticks('Ticks to land a held heavy.'),
        staggerTicks: ticks('Ticks of stagger it gives.'),
        force: num0('The knock force.'),
      }, { required: ['damage', 'ki', 'windupTicks', 'landTicks', 'recover', 'recoverWhiff', 'heldFullTicks', 'heldMaxTicks', 'heldLandTicks', 'staggerTicks', 'force'] }),
      hitstop: obj({ light: ticks('Hit-stop of a light blow.'), heavy: ticks('Hit-stop of a heavy blow.') }),
      tradeTicks: ticks('The window, in ticks, in which two blows landing together are a trade.'),
      heldMul: { type: 'number', exclusiveMinimum: 0, description: 'The worth of a held blow.' },
      skillMul: { type: 'number', exclusiveMinimum: 0, description: 'The worth of a skill blow.' },
      setMul: { type: 'number', exclusiveMinimum: 0, description: 'The worth of a set-up blow.' },
      heavyMul: { type: 'number', exclusiveMinimum: 0, description: 'The worth of a heavy blow.' },
    }, { required: ['enabled', 'interrupts', 'breakBh', 'pullBhPerSec', 'stepInTicks', 'idleTicks', 'heldPressTicks', 'stringLapseTicks', 'enderAfter', 'recoil', 'damageMul', 'aiPerfectEveryTicks', 'aiReversalEveryTicks', 'tradeTicks', 'heldMul', 'skillMul', 'setMul', 'heavyMul', 'light', 'flurry', 'heavy', 'hitstop'], description: 'The brawl (docs/director/brawl-plan.md): a blow for each press in the close band.' });
    if (!s.required.includes('brawl')) s.required.push('brawl');
    s.description = s.description.replace('Orders (', () => 'Orders (a brawl flurry\'s minGap at most its maxGap its mul gaps strictly increasing, its runLapseTicks below its tradeMaxTicks, and a heavy\'s heldFullTicks at most its heldMaxTicks (brawl-order); ');
    wj(f, s);
  }
}

// =============================== ai schema ===============================
{
  const f = 'tools/schemas/director-ai.schema.json';
  const s = rj(f);
  if (!s.properties.levels.properties.easy.properties.brawl) {
    for (const name of ['easy', 'medium', 'hard']) {
      const L = s.properties.levels.properties[name];
      L.properties.brawl = obj({
        tapGap: num0('The gap between the AI\'s taps, in ticks.'),
        string: pair({ type: 'integer', minimum: 1 }, 'The length of the AI\'s string, in blows: [lo, hi].'),
        enderShare: share('The chance a string ends on its ender.'),
        rashHeavy: share('The chance of a rash heavy.'),
        guardShare: share('The chance it guards.'),
        guardTicks: pair({ type: 'integer', minimum: 0 }, 'How long it guards, in ticks: [lo, hi].'),
        perfectMul: num0('The multiplier on its perfect-block chance in a brawl.'),
      }, { description: 'The AI\'s brawl play at this level.' });
      if (!L.required.includes('brawl')) L.required.push('brawl');
    }
    wj(f, s);
  }
}

// =============================== fixtures ===============================
{
  const dir = 'tools/fixtures/virtual/data/director/';
  {
    const f = dir + 'interrupts.json';
    const o = rj(f);
    if (o.brawl === undefined) {
      if (o.perfectBlock && o.perfectBlock.windows) o.perfectBlock.windows.blow = haveIt && liveIt.perfectBlock.windows.blow !== undefined ? liveIt.perfectBlock.windows.blow : 8;
      const src = haveIt ? strip(liveIt.brawl) : clone(VALID);
      if (haveIt && isPlain(src.flurry)) for (const k of ['runToClose', 'replyTakes', 'runLapseTicks', 'tradeMaxTicks']) if (src.flurry[k] === undefined) src.flurry[k] = VALID.flurry[k]; // a live file written before section 3
      const out = {};
      for (const k of Object.keys(o)) { out[k] = o[k]; if (k === 'pace') out.brawl = src; }
      if (out.brawl === undefined) out.brawl = src;
      wj(f, out);
    }
  }
  {
    const f = dir + 'ai.json';
    const o = rj(f);
    if (o.levels && o.levels.easy && o.levels.easy.brawl === undefined) {
      for (const name of ['easy', 'medium', 'hard']) o.levels[name].brawl = haveAi ? strip(liveAi.levels[name].brawl) : clone(VALID_AI);
      wj(f, o);
    }
  }
}

// =============================== xref ===============================
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes("'brawl-order'")) {
    const a = "    const bu = itr.buried;";
    if (!t.includes(a)) throw new Error('brawl anchor');
    t = t.replace(a, () => [
      "    const brl = itr.brawl;",
      "    if (isObj(brl)) {",
      "      if (isObj(brl.flurry)) {",
      "        if (typeof brl.flurry.minGap === 'number' && typeof brl.flurry.maxGap === 'number' && brl.flurry.minGap > brl.flurry.maxGap) err(IT, '/brawl/flurry/minGap', 'brawl-order', `flurry minGap ${brl.flurry.minGap} is above maxGap ${brl.flurry.maxGap}`);",
      "        if (Array.isArray(brl.flurry.mul)) for (let i = 1; i < brl.flurry.mul.length; i++) { const p = brl.flurry.mul[i - 1]; const q = brl.flurry.mul[i]; if (Array.isArray(p) && Array.isArray(q) && typeof p[0] === 'number' && typeof q[0] === 'number' && q[0] <= p[0]) err(IT, `/brawl/flurry/mul/${i}/0`, 'brawl-order', `the mul table's gap ${q[0]} does not rise above the one before (${p[0]})`); }",
      "      }",
      "      if (isObj(brl.flurry) && typeof brl.flurry.runLapseTicks === 'number' && typeof brl.flurry.tradeMaxTicks === 'number' && brl.flurry.runLapseTicks >= brl.flurry.tradeMaxTicks) err(IT, '/brawl/flurry/runLapseTicks', 'brawl-order', `runLapseTicks ${brl.flurry.runLapseTicks} is not below tradeMaxTicks ${brl.flurry.tradeMaxTicks}, so a run could outlast the trade it belongs to`);",
      "      if (isObj(brl.heavy) && typeof brl.heavy.heldFullTicks === 'number' && typeof brl.heavy.heldMaxTicks === 'number' && brl.heavy.heldFullTicks > brl.heavy.heldMaxTicks) err(IT, '/brawl/heavy/heldFullTicks', 'brawl-order', `heldFullTicks ${brl.heavy.heldFullTicks} is above heldMaxTicks ${brl.heavy.heldMaxTicks}, so a held heavy could never be full`);",
      "    }",
      a,
    ].join('\n'));
    const b = "    const med = isObj(lv.medium) ? lv.medium.beamAnswer : undefined;";
    if (!t.includes(b)) throw new Error('ai brawl anchor');
    t = t.replace(b, () => [
      "    for (const name of order) {",
      "      const bw = isObj(lv[name]) ? lv[name].brawl : undefined;",
      "      if (!isObj(bw)) continue;",
      "      for (const k of ['string', 'guardTicks']) if (Array.isArray(bw[k]) && bw[k].length === 2 && typeof bw[k][0] === 'number' && typeof bw[k][1] === 'number' && bw[k][0] > bw[k][1]) err(AI, `/levels/${name}/brawl/${k}/0`, 'ai-brawl', `${k} runs from ${bw[k][0]} down to ${bw[k][1]}`);",
      "    }",
      b,
    ].join('\n'));
    fs.writeFileSync(f, t);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const I = 'data/director/interrupts.json';
  const A = 'data/director/ai.json';
  // a whole brawl block (or AI level block) with one change, so a case never depends on the real file's values
  const mod = (base, fn) => { const o = clone(base); fn(o); return o; };
  const it = (n, fn, expect) => ({ id: 'director-interrupts-brawl-' + n, schema: 'director-interrupts.schema.json', mutate: [{ file: I, set: { '/brawl': mod(VALID, fn) } }], expect });
  const itw = (n, v, expect) => ({ id: 'director-interrupts-brawl-' + n, schema: 'director-interrupts.schema.json', mutate: [{ file: I, set: { '/perfectBlock/windows/blow': v } }], expect });
  const ai = (n, fn, expect) => ({ id: 'director-ai-brawl-' + n, schema: 'director-ai.schema.json', mutate: [{ file: A, set: { '/levels/medium/brawl': mod(VALID_AI, fn) } }], expect });
  const B = '/brawl/';
  const AB = '/levels/medium/brawl/';
  const add = [
    // ---- brawl: the block ----
    it('valid', () => {}, null),
    it('key-required', (o) => { delete o.recoil; }, { rule: 'required', pointer: '/brawl' }),
    it('unknown-key', (o) => { o.extra = 1; }, { rule: 'additionalProperties', pointer: B + 'extra' }),
    it('note-ok', (o) => { o._note = 'comment'; }, null),
    it('enabled-type', (o) => { o.enabled = 'yes'; }, { rule: 'type', pointer: B + 'enabled' }),
    it('off-ok', (o) => { o.enabled = false; }, null),
    it('interrupts-type', (o) => { o.interrupts = 'hit'; }, { rule: 'type', pointer: B + 'interrupts' }),
    it('interrupts-duplicate', (o) => { o.interrupts = ['hit', 'hit']; }, { rule: 'uniqueItems', pointer: B + 'interrupts/1' }),
    it('interrupts-shape', (o) => { o.interrupts = ['Hit Back']; }, { rule: 'pattern', pointer: B + 'interrupts/0' }),
    it('interrupts-empty-ok', (o) => { o.interrupts = []; }, null),
    it('break-bh-zero', (o) => { o.breakBh = 0; }, { rule: 'exclusiveMinimum', pointer: B + 'breakBh' }),
    it('break-bh-type', (o) => { o.breakBh = 'far'; }, { rule: 'type', pointer: B + 'breakBh' }),
    it('pull-negative', (o) => { o.pullBhPerSec = -1; }, { rule: 'minimum', pointer: B + 'pullBhPerSec' }),
    it('pull-zero-ok', (o) => { o.pullBhPerSec = 0; }, null),
    it('step-in-negative', (o) => { o.stepInTicks = -1; }, { rule: 'minimum', pointer: B + 'stepInTicks' }),
    it('step-in-integer', (o) => { o.stepInTicks = 6.5; }, { rule: 'type', pointer: B + 'stepInTicks' }),
    it('idle-negative', (o) => { o.idleTicks = -1; }, { rule: 'minimum', pointer: B + 'idleTicks' }),
    it('held-press-integer', (o) => { o.heldPressTicks = 1.5; }, { rule: 'type', pointer: B + 'heldPressTicks' }),
    it('string-lapse-negative', (o) => { o.stringLapseTicks = -5; }, { rule: 'minimum', pointer: B + 'stringLapseTicks' }),
    it('ender-after-zero', (o) => { o.enderAfter = 0; }, { rule: 'minimum', pointer: B + 'enderAfter' }),
    it('ender-after-integer', (o) => { o.enderAfter = 2.5; }, { rule: 'type', pointer: B + 'enderAfter' }),
    it('recoil-negative', (o) => { o.recoil = -0.1; }, { rule: 'minimum', pointer: B + 'recoil' }),
    it('damage-mul-negative', (o) => { o.damageMul = -1; }, { rule: 'minimum', pointer: B + 'damageMul' }),
    it('damage-mul-above-one-ok', (o) => { o.damageMul = 1.5; }, null),
    it('ai-perfect-negative', (o) => { o.aiPerfectEveryTicks = -1; }, { rule: 'minimum', pointer: B + 'aiPerfectEveryTicks' }),
    it('ai-reversal-integer', (o) => { o.aiReversalEveryTicks = 90.5; }, { rule: 'type', pointer: B + 'aiReversalEveryTicks' }),
    // ---- light ----
    it('light-key-required', (o) => { delete o.light.blowTicks; }, { rule: 'required', pointer: B + 'light' }),
    it('light-unknown-key', (o) => { o.light.extra = 1; }, { rule: 'additionalProperties', pointer: B + 'light/extra' }),
    it('light-damage-negative', (o) => { o.light.damage = -1; }, { rule: 'minimum', pointer: B + 'light/damage' }),
    it('light-contact-integer', (o) => { o.light.contactTicks = 5.5; }, { rule: 'type', pointer: B + 'light/contactTicks' }),
    it('light-recover-required', (o) => { delete o.light.recover; }, { rule: 'required', pointer: B + 'light' }),
    it('light-recover-negative', (o) => { o.light.recover = -1; }, { rule: 'minimum', pointer: B + 'light/recover' }),
    it('light-recover-integer', (o) => { o.light.recover = 10.5; }, { rule: 'type', pointer: B + 'light/recover' }),
    it('light-blow-negative', (o) => { o.light.blowTicks = -1; }, { rule: 'minimum', pointer: B + 'light/blowTicks' }),
    // ---- flurry ----
    it('flurry-key-required', (o) => { delete o.flurry.mul; }, { rule: 'required', pointer: B + 'flurry' }),
    it('flurry-unknown-key', (o) => { o.flurry.extra = 1; }, { rule: 'additionalProperties', pointer: B + 'flurry/extra' }),
    it('flurry-min-gap-negative', (o) => { o.flurry.minGap = -1; }, { rule: 'minimum', pointer: B + 'flurry/minGap' }),
    it('flurry-gaps-reversed', (o) => { o.flurry.minGap = 30; o.flurry.maxGap = 10; }, { rule: 'xref:brawl-order', pointer: B + 'flurry/minGap' }),
    it('flurry-gaps-equal-ok', (o) => { o.flurry.minGap = 10; o.flurry.maxGap = 10; }, null),
    it('flurry-mul-empty', (o) => { o.flurry.mul = []; }, { rule: 'minItems', pointer: B + 'flurry/mul' }),
    it('flurry-mul-type', (o) => { o.flurry.mul = 'steep'; }, { rule: 'type', pointer: B + 'flurry/mul' }),
    it('flurry-mul-row-length', (o) => { o.flurry.mul = [[4]]; }, { rule: 'minItems', pointer: B + 'flurry/mul/0' }),
    it('flurry-mul-row-too-long', (o) => { o.flurry.mul = [[4, 0.5, 1]]; }, { rule: 'maxItems', pointer: B + 'flurry/mul/0' }),
    it('flurry-mul-gap-integer', (o) => { o.flurry.mul = [[4.5, 0.5]]; }, { rule: 'type', pointer: B + 'flurry/mul/0/0' }),
    it('flurry-mul-gap-negative', (o) => { o.flurry.mul = [[-1, 0.5]]; }, { rule: 'minimum', pointer: B + 'flurry/mul/0/0' }),
    it('flurry-mul-above-limit', (o) => { o.flurry.mul = [[4, 2.5]]; }, { rule: 'maximum', pointer: B + 'flurry/mul/0/1' }),
    it('flurry-mul-zero', (o) => { o.flurry.mul = [[4, 0]]; }, { rule: 'exclusiveMinimum', pointer: B + 'flurry/mul/0/1' }),
    it('flurry-mul-negative', (o) => { o.flurry.mul = [[4, -0.1]]; }, { rule: 'exclusiveMinimum', pointer: B + 'flurry/mul/0/1' }),
    it('flurry-mul-above-one-ok', (o) => { o.flurry.mul = [[11, 1.1], [12, 1.2]]; }, null),
    it('flurry-mul-gaps-equal', (o) => { o.flurry.mul = [[4, 0.5], [4, 0.75]]; }, { rule: 'xref:brawl-order', pointer: B + 'flurry/mul/1/0' }),
    it('flurry-mul-gaps-falling', (o) => { o.flurry.mul = [[8, 0.5], [4, 0.75]]; }, { rule: 'xref:brawl-order', pointer: B + 'flurry/mul/1/0' }),
    it('flurry-mul-one-point', (o) => { o.flurry.mul = [[10, 1]]; }, { rule: 'minItems', pointer: B + 'flurry/mul' }),
    it('flurry-mul-three-points-ok', (o) => { o.flurry.mul = [[4, 0.5], [8, 0.75], [12, 1]]; }, null),
    it('flurry-mul-edges-ok', (o) => { o.flurry.mul = [[1, 0.1], [2, 2]]; }, null),
    it('flurry-reel-negative', (o) => { o.flurry.reelTicks = -1; }, { rule: 'minimum', pointer: B + 'flurry/reelTicks' }),
    it('flurry-close-integer', (o) => { o.flurry.closeAfter = 30.5; }, { rule: 'type', pointer: B + 'flurry/closeAfter' }),
    it('flurry-run-to-close-required', (o) => { delete o.flurry.runToClose; }, { rule: 'required', pointer: B + 'flurry' }),
    it('flurry-run-to-close-zero', (o) => { o.flurry.runToClose = 0; }, { rule: 'minimum', pointer: B + 'flurry/runToClose' }),
    it('flurry-run-to-close-integer', (o) => { o.flurry.runToClose = 3.5; }, { rule: 'type', pointer: B + 'flurry/runToClose' }),
    it('flurry-run-to-close-one-ok', (o) => { o.flurry.runToClose = 1; }, null),
    it('flurry-reply-takes-required', (o) => { delete o.flurry.replyTakes; }, { rule: 'required', pointer: B + 'flurry' }),
    it('flurry-reply-takes-negative', (o) => { o.flurry.replyTakes = -1; }, { rule: 'minimum', pointer: B + 'flurry/replyTakes' }),
    it('flurry-reply-takes-integer', (o) => { o.flurry.replyTakes = 0.5; }, { rule: 'type', pointer: B + 'flurry/replyTakes' }),
    it('flurry-reply-takes-zero-ok', (o) => { o.flurry.replyTakes = 0; }, null),
    it('flurry-run-lapse-required', (o) => { delete o.flurry.runLapseTicks; }, { rule: 'required', pointer: B + 'flurry' }),
    it('flurry-run-lapse-negative', (o) => { o.flurry.runLapseTicks = -1; }, { rule: 'minimum', pointer: B + 'flurry/runLapseTicks' }),
    it('flurry-run-lapse-integer', (o) => { o.flurry.runLapseTicks = 24.5; }, { rule: 'type', pointer: B + 'flurry/runLapseTicks' }),
    it('flurry-trade-max-required', (o) => { delete o.flurry.tradeMaxTicks; }, { rule: 'required', pointer: B + 'flurry' }),
    it('flurry-trade-max-zero', (o) => { o.flurry.tradeMaxTicks = 0; }, { rule: 'minimum', pointer: B + 'flurry/tradeMaxTicks' }),
    it('flurry-trade-max-integer', (o) => { o.flurry.tradeMaxTicks = 90.5; }, { rule: 'type', pointer: B + 'flurry/tradeMaxTicks' }),
    it('flurry-run-lapse-above-trade-max', (o) => { o.flurry.runLapseTicks = 100; o.flurry.tradeMaxTicks = 90; }, { rule: 'xref:brawl-order', pointer: B + 'flurry/runLapseTicks' }),
    it('flurry-run-lapse-equal-trade-max', (o) => { o.flurry.runLapseTicks = 90; o.flurry.tradeMaxTicks = 90; }, { rule: 'xref:brawl-order', pointer: B + 'flurry/runLapseTicks' }),
    it('flurry-run-lapse-just-below-trade-max-ok', (o) => { o.flurry.runLapseTicks = 89; o.flurry.tradeMaxTicks = 90; }, null),
    it('flurry-run-lapse-zero-ok', (o) => { o.flurry.runLapseTicks = 0; o.flurry.tradeMaxTicks = 1; }, null),
    it('flurry-stagger-negative', (o) => { o.flurry.staggerTicks = -1; }, { rule: 'minimum', pointer: B + 'flurry/staggerTicks' }),
    // ---- heavy ----
    it('heavy-key-required', (o) => { delete o.heavy.force; }, { rule: 'required', pointer: B + 'heavy' }),
    it('heavy-unknown-key', (o) => { o.heavy.extra = 1; }, { rule: 'additionalProperties', pointer: B + 'heavy/extra' }),
    it('heavy-damage-negative', (o) => { o.heavy.damage = -1; }, { rule: 'minimum', pointer: B + 'heavy/damage' }),
    it('heavy-ki-negative', (o) => { o.heavy.ki = -1; }, { rule: 'minimum', pointer: B + 'heavy/ki' }),
    it('heavy-ki-fraction-ok', (o) => { o.heavy.ki = 7.5; }, null),
    it('heavy-windup-negative', (o) => { o.heavy.windupTicks = -1; }, { rule: 'minimum', pointer: B + 'heavy/windupTicks' }),
    it('heavy-land-integer', (o) => { o.heavy.landTicks = 6.5; }, { rule: 'type', pointer: B + 'heavy/landTicks' }),
    it('heavy-recover-ticks-retired', (o) => { o.heavy.recoverTicks = 20; }, { rule: 'additionalProperties', pointer: B + 'heavy/recoverTicks' }),
    it('heavy-recover-required', (o) => { delete o.heavy.recover; }, { rule: 'required', pointer: B + 'heavy' }),
    it('heavy-recover-whiff-required', (o) => { delete o.heavy.recoverWhiff; }, { rule: 'required', pointer: B + 'heavy' }),
    it('heavy-recover-negative-value', (o) => { o.heavy.recover = -1; }, { rule: 'minimum', pointer: B + 'heavy/recover' }),
    it('heavy-recover-whiff-negative', (o) => { o.heavy.recoverWhiff = -1; }, { rule: 'minimum', pointer: B + 'heavy/recoverWhiff' }),
    it('heavy-recover-whiff-integer', (o) => { o.heavy.recoverWhiff = 30.5; }, { rule: 'type', pointer: B + 'heavy/recoverWhiff' }),
    it('trade-ticks-required', (o) => { delete o.tradeTicks; }, { rule: 'required', pointer: '/brawl' }),
    it('trade-ticks-negative', (o) => { o.tradeTicks = -1; }, { rule: 'minimum', pointer: B + 'tradeTicks' }),
    it('trade-ticks-integer', (o) => { o.tradeTicks = 8.5; }, { rule: 'type', pointer: B + 'tradeTicks' }),
    it('trade-ticks-zero-ok', (o) => { o.tradeTicks = 0; }, null),
    it('held-mul-required', (o) => { delete o.heldMul; }, { rule: 'required', pointer: '/brawl' }),
    it('held-mul-zero', (o) => { o.heldMul = 0; }, { rule: 'exclusiveMinimum', pointer: B + 'heldMul' }),
    it('held-mul-type', (o) => { o.heldMul = 'big'; }, { rule: 'type', pointer: B + 'heldMul' }),
    it('held-mul-ok', (o) => { o.heldMul = 2; }, null),
    it('skill-mul-required', (o) => { delete o.skillMul; }, { rule: 'required', pointer: '/brawl' }),
    it('set-mul-required', (o) => { delete o.setMul; }, { rule: 'required', pointer: '/brawl' }),
    it('heavy-mul-required', (o) => { delete o.heavyMul; }, { rule: 'required', pointer: '/brawl' }),
    it('skill-mul-ok', (o) => { o.skillMul = 1.2; }, null),
    it('skill-mul-zero', (o) => { o.skillMul = 0; }, { rule: 'exclusiveMinimum', pointer: B + 'skillMul' }),
    it('set-mul-ok', (o) => { o.setMul = 0.8; }, null),
    it('set-mul-negative', (o) => { o.setMul = -1; }, { rule: 'exclusiveMinimum', pointer: B + 'setMul' }),
    it('heavy-mul-ok', (o) => { o.heavyMul = 1.5; }, null),
    it('heavy-mul-type', (o) => { o.heavyMul = 'big'; }, { rule: 'type', pointer: B + 'heavyMul' }),
    it('heavy-held-full-integer', (o) => { o.heavy.heldFullTicks = 40.5; }, { rule: 'type', pointer: B + 'heavy/heldFullTicks' }),
    it('heavy-held-max-negative', (o) => { o.heavy.heldMaxTicks = -1; }, { rule: 'minimum', pointer: B + 'heavy/heldMaxTicks' }),
    it('heavy-held-full-above-max', (o) => { o.heavy.heldFullTicks = 90; o.heavy.heldMaxTicks = 60; }, { rule: 'xref:brawl-order', pointer: B + 'heavy/heldFullTicks' }),
    it('heavy-held-full-equals-max-ok', (o) => { o.heavy.heldFullTicks = 60; o.heavy.heldMaxTicks = 60; }, null),
    it('heavy-held-land-negative', (o) => { o.heavy.heldLandTicks = -1; }, { rule: 'minimum', pointer: B + 'heavy/heldLandTicks' }),
    it('heavy-stagger-negative', (o) => { o.heavy.staggerTicks = -1; }, { rule: 'minimum', pointer: B + 'heavy/staggerTicks' }),
    it('heavy-force-negative', (o) => { o.heavy.force = -1; }, { rule: 'minimum', pointer: B + 'heavy/force' }),
    // ---- hit-stop and the perfect-block window ----
    it('hitstop-key-required', (o) => { delete o.hitstop.heavy; }, { rule: 'required', pointer: B + 'hitstop' }),
    it('hitstop-negative', (o) => { o.hitstop.light = -1; }, { rule: 'minimum', pointer: B + 'hitstop/light' }),
    it('hitstop-integer', (o) => { o.hitstop.heavy = 5.5; }, { rule: 'type', pointer: B + 'hitstop/heavy' }),
    it('hitstop-zero-ok', (o) => { o.hitstop.light = 0; o.hitstop.heavy = 0; }, null),
    itw('window-blow-ok', 8, null),
    itw('window-blow-negative', -1, { rule: 'minimum', pointer: '/perfectBlock/windows/blow' }),
    itw('window-blow-type', 'wide', { rule: 'type', pointer: '/perfectBlock/windows/blow' }),
    itw('window-blow-fraction-ok', 7.5, null),
    // ---- the AI's brawl play ----
    ai('valid', () => {}, null),
    ai('key-required', (o) => { delete o.perfectMul; }, { rule: 'required', pointer: '/levels/medium/brawl' }),
    ai('unknown-key', (o) => { o.extra = 1; }, { rule: 'additionalProperties', pointer: AB + 'extra' }),
    ai('tap-gap-negative', (o) => { o.tapGap = -1; }, { rule: 'minimum', pointer: AB + 'tapGap' }),
    ai('tap-gap-type', (o) => { o.tapGap = 'quick'; }, { rule: 'type', pointer: AB + 'tapGap' }),
    ai('string-length', (o) => { o.string = [3]; }, { rule: 'minItems', pointer: AB + 'string' }),
    ai('string-too-long', (o) => { o.string = [3, 4, 5]; }, { rule: 'maxItems', pointer: AB + 'string' }),
    ai('string-zero', (o) => { o.string = [0, 4]; }, { rule: 'minimum', pointer: AB + 'string/0' }),
    ai('string-integer', (o) => { o.string = [3, 4.5]; }, { rule: 'type', pointer: AB + 'string/1' }),
    ai('string-reversed', (o) => { o.string = [6, 3]; }, { rule: 'xref:ai-brawl', pointer: AB + 'string/0' }),
    ai('string-equal-ok', (o) => { o.string = [4, 4]; }, null),
    ai('ender-share-range', (o) => { o.enderShare = 1.5; }, { rule: 'maximum', pointer: AB + 'enderShare' }),
    ai('rash-heavy-negative', (o) => { o.rashHeavy = -0.1; }, { rule: 'minimum', pointer: AB + 'rashHeavy' }),
    ai('guard-share-range', (o) => { o.guardShare = 2; }, { rule: 'maximum', pointer: AB + 'guardShare' }),
    ai('guard-share-edges-ok', (o) => { o.guardShare = 1; o.rashHeavy = 0; }, null),
    ai('guard-ticks-length', (o) => { o.guardTicks = [20]; }, { rule: 'minItems', pointer: AB + 'guardTicks' }),
    ai('guard-ticks-negative', (o) => { o.guardTicks = [-1, 20]; }, { rule: 'minimum', pointer: AB + 'guardTicks/0' }),
    ai('guard-ticks-integer', (o) => { o.guardTicks = [20, 60.5]; }, { rule: 'type', pointer: AB + 'guardTicks/1' }),
    ai('guard-ticks-reversed', (o) => { o.guardTicks = [60, 20]; }, { rule: 'xref:ai-brawl', pointer: AB + 'guardTicks/0' }),
    ai('guard-ticks-zero-ok', (o) => { o.guardTicks = [0, 0]; }, null),
    ai('perfect-mul-negative', (o) => { o.perfectMul = -1; }, { rule: 'minimum', pointer: AB + 'perfectMul' }),
    ai('perfect-mul-above-one-ok', (o) => { o.perfectMul = 1.5; }, null),
    { id: 'director-ai-brawl-required-easy', schema: 'director-ai.schema.json', mutate: [{ file: A, del: ['/levels/easy/brawl'] }], expect: { rule: 'required', pointer: '/levels/easy' } },
    { id: 'director-ai-brawl-required-hard', schema: 'director-ai.schema.json', mutate: [{ file: A, del: ['/levels/hard/brawl'] }], expect: { rule: 'required', pointer: '/levels/hard' } },
    { id: 'director-ai-brawl-note-ok', schema: 'director-ai.schema.json', mutate: [{ file: A, set: { '/_brawl': 'comment' } }], expect: null },
    { id: 'director-interrupts-brawl-required', schema: 'director-interrupts.schema.json', mutate: [{ file: I, del: ['/brawl'] }], expect: { rule: 'required', pointer: '' } },
  ];
  let n = 0;
  for (const k of add) if (!c.cases.some((y) => y.id === k.id)) { c.cases.push(k); n++; }
  wj(cf, c);
  console.log(`slice B1 schema applied (${n} new cases)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes('brawl-order')) {
    const line = t.split('\n').find((l) => l.includes('`pace-order`'));
    if (!line) throw new Error('B1 README anchor');
    t = t.replace(line, () => line + '\n| `brawl-order`, `ai-brawl` | data/director/interrupts.json brawl: flurry.minGap is at most maxGap, the mul table\'s gaps strictly increase, and heavy.heldFullTicks is at most heldMaxTicks. data/director/ai.json brawl: string and guardTicks run low to high |');
    fs.writeFileSync(f, t);
  }
}
