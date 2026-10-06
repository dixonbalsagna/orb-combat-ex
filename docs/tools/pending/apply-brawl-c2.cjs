// Schema keys for Encounter's chain (C2a + C2t + the heavy's hold): the medium blow, the charged heavy, the burst, giving ground, the launcher, the energy reach, a zip heavy's
// damage, the AI's shares and digInBy. NOT run by CI, the validator or the sim. Run once from the repo root, in the commit that lands Encounter's data (after apply-brawl-c1.cjs,
// which is applied), with apply-input-c2a.cjs and, if Combat's files land then, apply-brawl-recipes.cjs and apply-movegen.cjs (the order is in docs/tools/pending/README.md):
//     node docs/tools/pending/apply-brawl-c2.cjs
// It does NOT edit data/. The shapes are Encounter's and final; the ranges are generous, because the values will move in tuning. Where the request named a key without its type,
// the type below is a reading of the name (listed in the README entry for the person who owns the key to confirm): a name ending in Ticks is an integer 0 or more; a name ending
// in Bh, a share or a cost is a number 0 or more (shares 0 to 1 where the request said so); `bySpeed` is a boolean; `gap` and `worth` pairs are arrays of two; `lands` an array of seven.
//
// data/director/interrupts.json, under `brawl` (all required, closed objects):
//   nudge.stagger; plannedHeavyDamage; woundLandTicks; hitstop.medium;
//   medium {windupTicks, worth, ki, gap[2], rate, reelTicks, recover, recoverWhiff, guardChipMul, reachBh};
//   heavy gains worth, gap[2], reachBh, armour {lightMul, mediumUntilTicks, shotMediumPower, shotHeavyPower} and
//     charge {fromTicks, fullTicks, landTicks, maxTicks, worth[2], ki, reachBh, aiReleaseTicks};
//   burst {lands[7], second, rate, reelTicks, runHalves, openTicks}; give {bhPerSec, bySpeed, speedRef, guard, follow, leashBh, closeTicksPerBh, closeMaxTicks, closeMaxBh,
//     closeSlackBh, lightReachBh, edgeBh}; launcher {minStagger, windupTicks, worth, ki, restS (seconds, 0 or more), flightMul (above 0, at most 1)}; energy.reach {bolt {contactTicks, worth, ki, reelTicks, runHalves, shot},
//     blast {windupTicks, worth, ki, knockBh, shot}, flashEveryTicks}.
//   under `zip`: heavy.damage.   REMOVED from brawl.heavy: damage, landTicks, heldFullTicks, heldMaxTicks, heldLandTicks; REMOVED from brawl: enderAfter, heldMul, stepInTicks
//   (naming one is an unknown key). Only values change: brawl.heavyMul, heavy.windupTicks, heavy.ki, heavy.recover, heavy.recoverWhiff.
// data/director/ai.json: a top-level digInBy (an object keyed by a fighter id, a number 0 or more each; ids checked against the roster: rule ai-digin-fighter) and, in each level's
//   brawl, the shares mixMedium, mixHeavy, heavyIntoFlurry, mediumIntoHeavy, burst, digIn, giveGround, follow, launcher, charge, energy, breakGuard (0 to 1, required);
//   REMOVED from each level's brawl: enderShare, rashHeavy, heavyAfterClose.
// Cross-references (rule brawl-order, in the existing check's place; the old heldFullTicks <= heldMaxTicks check goes with its keys): heavy.charge.fromTicks < fullTicks <
//   maxTicks; medium.windupTicks < heavy.windupTicks; give.closeMaxBh <= give.leashBh; burst.lands never falls (equal neighbours are allowed).
// Tested against a hand-made copy of the data (Encounter's files are in its scratch, not the tree). The fixtures and every earlier case that sets a whole brawl block, a whole zip, a
// level's brawl or the levels follow (the cases about a removed key go); the new cases set their own whole blocks. Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const clone = (o) => JSON.parse(JSON.stringify(o));
const closed = { additionalProperties: false, patternProperties: { '^_': true } };

// ---- the spec: a leaf is { k: kind, v: a valid value, d: its description }; an object is a plain object of leaves and objects
const L = (k, v, d) => ({ __leaf: true, k, v, d });
const isLeaf = (x) => x && x.__leaf === true;
const I = (v, d) => L('int0', v, d);        // integer, 0 or more
const N = (v, d) => L('num0', v, d);        // number, 0 or more
const SH = (v, d) => L('share', v, d);      // number, 0 to 1
const B = (v, d) => L('bool', v, d);
const A2I = (v, d) => L('arr2int', v, d);   // two integers, 0 or more
const A2N = (v, d) => L('arr2num', v, d);   // two numbers, 0 or more
const A7N = (v, d) => L('arr7num', v, d);   // seven numbers, 0 or more
const P01 = (v, d) => L('pos01', v, d);     // number above 0, at most 1
const SHOT = (v, d) => L('shot', v, d);     // a shot kind's name

const NUDGE_ADD = { stagger: N(0.5, 'The nudge\'s share while the rival is staggered.') };
const BRAWL_ADD = {
  plannedHeavyDamage: N(66, 'The damage a planned heavy is worth in the planner.'),
  woundLandTicks: I(6, 'Ticks a blow that wounds takes to land.'),
  medium: {
    windupTicks: I(14, 'The medium blow\'s wind-up (below the heavy\'s: rule brawl-order).'), worth: N(1.5, 'What a medium blow is worth.'), ki: N(2, 'The ki it costs.'),
    gap: A2I([4, 10], 'The gap, in ticks, between mediums: [lo, hi].'), rate: N(1, 'Its rate.'), reelTicks: I(6, 'Ticks the rival reels.'), recover: I(8, 'Recovery after a medium that lands.'),
    recoverWhiff: I(20, 'Recovery after a medium that misses.'), guardChipMul: N(0.3, 'The share of its damage a guard takes.'), reachBh: N(1, 'Its reach, in body heights.'),
  },
  burst: {
    lands: A7N([2, 4, 6, 8, 10, 12, 14], 'The ticks at which the burst\'s seven blows land (never falling: rule brawl-order).'), second: N(0.5, 'The second blow\'s share.'),
    rate: N(1, 'Its rate.'), reelTicks: I(6, 'Ticks the rival reels.'), runHalves: N(2, 'Run halves.'), openTicks: I(20, 'Ticks the burst stays open.'),
  },
  give: {
    bhPerSec: N(1, 'Body heights a second given.'), bySpeed: B(true, 'Whether the speed sets the give.'), speedRef: N(1, 'The reference speed.'), guard: N(0.5, 'The give while guarding.'),
    follow: N(0.5, 'How far the other follows.'), leashBh: N(6, 'The leash, in body heights.'), closeTicksPerBh: N(4, 'Ticks a body height of closing takes.'), closeMaxTicks: I(30, 'The most ticks a close takes.'),
    closeMaxBh: N(4, 'The farthest a close goes, in body heights (at most the leash: rule brawl-order).'), closeSlackBh: N(0.5, 'The close\'s slack.'), lightReachBh: N(1, 'A light\'s reach.'), edgeBh: N(2, 'The edge distance.'),
  },
  launcher: {
    minStagger: N(10, 'The shortest stagger a launcher needs.'), windupTicks: I(12, 'Its wind-up.'), worth: N(4, 'What it is worth.'), ki: N(8, 'The ki it costs.'),
    restS: N(40, 'Seconds the launcher rests between uses (Game Design re-ruling, tuned between 25 and 60).'), flightMul: P01(1, 'The flight multiplier of the launched fighter: above 0, at most 1 (tuned down to 0.6).'),
  },
  energy: {
    reach: {
      bolt: { contactTicks: I(6, 'Ticks of contact.'), worth: N(2, 'What it is worth.'), ki: N(4, 'The ki it costs.'), reelTicks: I(6, 'Ticks the rival reels.'), runHalves: N(2, 'Run halves.'), shot: SHOT('bolt', 'The shot kind it fires (data/fight/shots.json).') },
      blast: { windupTicks: I(16, 'Its wind-up.'), worth: N(4, 'What it is worth.'), ki: N(10, 'The ki it costs.'), knockBh: N(3, 'How far it knocks, in body heights.'), shot: SHOT('charged', 'The shot kind it fires.') },
      flashEveryTicks: I(20, 'Ticks between the energy\'s flashes.'),
    },
  },
};
const HEAVY_ADD = {
  worth: N(3, 'What a heavy is worth.'), gap: A2I([8, 16], 'The gap, in ticks, between heavies: [lo, hi].'), reachBh: N(1.4, 'Its reach, in body heights.'),
  armour: { lightMul: N(0.5, 'The multiplier on a light that hits an armoured heavy.'), mediumUntilTicks: I(10, 'Ticks a medium is still armoured against.'), shotMediumPower: N(2, 'The shot power a medium armours.'), shotHeavyPower: N(3, 'The shot power a heavy armours.') },
  charge: {
    fromTicks: I(12, 'Ticks held before the charge begins (below fullTicks: rule brawl-order).'), fullTicks: I(40, 'Ticks held to a full charge (below maxTicks).'), landTicks: I(8, 'Ticks the charged blow takes to land.'),
    maxTicks: I(120, 'The most it can be held.'), worth: A2N([3, 6], 'What a charged heavy is worth: [uncharged, full].'), ki: N(6, 'The ki it costs.'), reachBh: N(1.4, 'Its reach, in body heights.'), aiReleaseTicks: I(60, 'Ticks after which the AI releases it.'),
  },
};
const HITSTOP_ADD = { medium: I(4, 'Hit-stop of a medium blow.') };
const ZIPHEAVY_ADD = { damage: N(40, 'The damage a zip heavy deals.') };
const REMOVED_BRAWL = ['enderAfter', 'heldMul', 'stepInTicks'];
const REMOVED_HEAVY = ['damage', 'landTicks', 'heldFullTicks', 'heldMaxTicks', 'heldLandTicks'];
const AI_BRAWL_ADD = Object.fromEntries(['mixMedium', 'mixHeavy', 'heavyIntoFlurry', 'mediumIntoHeavy', 'burst', 'digIn', 'giveGround', 'follow', 'launcher', 'charge', 'energy', 'breakGuard'].map((k, i) => [k, SH(0.1 + 0.05 * (i % 6), `The AI\'s share for ${k}.`)]));
const REMOVED_AI = ['enderShare', 'rashHeavy', 'heavyAfterClose'];
const AI_BY_LEVEL = { easy: 0.5, medium: 1, hard: 1.4 };   // scales the sample shares, kept inside 0 to 1 below
const DIGIN_SAMPLE = 0.5;

// ---- builders from the spec
const leafSchema = (x) => {
  switch (x.k) {
    case 'int0': return { type: 'integer', minimum: 0, description: x.d };
    case 'num0': return { type: 'number', minimum: 0, description: x.d };
    case 'share': return { type: 'number', minimum: 0, maximum: 1, description: x.d };
    case 'pos01': return { type: 'number', exclusiveMinimum: 0, maximum: 1, description: x.d };
    case 'bool': return { type: 'boolean', description: x.d };
    case 'arr2int': return { type: 'array', minItems: 2, maxItems: 2, items: { type: 'integer', minimum: 0 }, description: x.d };
    case 'arr2num': return { type: 'array', minItems: 2, maxItems: 2, items: { type: 'number', minimum: 0 }, description: x.d };
    case 'arr7num': return { type: 'array', minItems: 7, maxItems: 7, items: { type: 'number', minimum: 0 }, description: x.d };
    case 'shot': return { type: 'string', pattern: '^[a-z][a-z0-9_]*$', description: x.d };
    default: throw new Error('kind ' + x.k);
  }
};
const nodeSchema = (n) => (isLeaf(n) ? leafSchema(n) : Object.assign({ type: 'object', required: Object.keys(n), properties: Object.fromEntries(Object.entries(n).map(([k, v]) => [k, nodeSchema(v)])) }, closed));
const nodeValue = (n) => (isLeaf(n) ? clone(n.v) : Object.fromEntries(Object.entries(n).map(([k, v]) => [k, nodeValue(v)])));
/** Adds the spec's properties to a closed object schema (and to its required list). Returns whether anything changed. */
const addTo = (sch, spec) => {
  let ch = false;
  for (const [k, n] of Object.entries(spec)) {
    if (!sch.properties[k]) { sch.properties[k] = nodeSchema(n); ch = true; }
    if (!sch.required.includes(k)) { sch.required.push(k); ch = true; }
  }
  return ch;
};
const dropFrom = (sch, keys) => {
  let ch = false;
  for (const k of keys) { if (sch.properties[k]) { delete sch.properties[k]; ch = true; } }
  const r = sch.required.filter((k) => !keys.includes(k));
  if (r.length !== sch.required.length) { sch.required = r; ch = true; }
  return ch;
};
/** Fills an existing value object with the spec's values where missing (deep), and removes keys. Returns the number of changes. */
const fill = (o, spec) => {
  let n = 0;
  for (const [k, node] of Object.entries(spec)) {
    if (isLeaf(node)) { if (o[k] === undefined) { o[k] = clone(node.v); n++; } } else if (o[k] === undefined) { o[k] = nodeValue(node); n++; } else if (o[k] && typeof o[k] === 'object') n += fill(o[k], node);
  }
  return n;
};
const strip = (o, keys) => { let n = 0; for (const k of keys) if (o[k] !== undefined) { delete o[k]; n++; } return n; };
/** One brawl block (interrupts.json) brought to the new shape. */
const fixBrawl = (b) => {
  if (!b || typeof b !== 'object') return 0;
  let n = strip(b, REMOVED_BRAWL);
  n += fill(b, BRAWL_ADD);
  if (b.nudge && typeof b.nudge === 'object') n += fill(b.nudge, NUDGE_ADD);
  if (b.heavy && typeof b.heavy === 'object') { n += strip(b.heavy, REMOVED_HEAVY); n += fill(b.heavy, HEAVY_ADD); }
  if (b.hitstop && typeof b.hitstop === 'object') n += fill(b.hitstop, HITSTOP_ADD);
  return n;
};
const fixZip = (z) => (z && typeof z === 'object' && z.heavy && typeof z.heavy === 'object' ? fill(z.heavy, ZIPHEAVY_ADD) : 0);
const aiSample = (level) => Object.fromEntries(Object.entries(AI_BRAWL_ADD).map(([k, x]) => [k, Math.min(1, Math.round(x.v * AI_BY_LEVEL[level] * 100) / 100)]));
const fixAiBrawl = (b, level) => {
  if (!b || typeof b !== 'object') return 0;
  let n = strip(b, REMOVED_AI);
  for (const [k, v] of Object.entries(aiSample(level))) if (b[k] === undefined) { b[k] = v; n++; }
  return n;
};

// =============================== interrupts schema ===============================
{
  const f = 'tools/schemas/director-interrupts.schema.json';
  const s = rj(f);
  const b = s.properties.brawl;
  let ch = false;
  if (b.properties.nudge) ch = addTo(b.properties.nudge, NUDGE_ADD) || ch;
  ch = addTo(b, BRAWL_ADD) || ch;
  ch = addTo(b.properties.heavy, HEAVY_ADD) || ch;
  ch = dropFrom(b.properties.heavy, REMOVED_HEAVY) || ch;
  ch = dropFrom(b, REMOVED_BRAWL) || ch;
  ch = addTo(b.properties.hitstop, HITSTOP_ADD) || ch;
  ch = addTo(s.properties.zip.properties.heavy, ZIPHEAVY_ADD) || ch;
  if (ch) wj(f, s);
}
// =============================== ai schema ===============================
{
  const f = 'tools/schemas/director-ai.schema.json';
  const s = rj(f);
  let ch = false;
  for (const name of ['easy', 'medium', 'hard']) {
    const b = s.properties.levels.properties[name].properties.brawl;
    ch = addTo(b, AI_BRAWL_ADD) || ch;
    ch = dropFrom(b, REMOVED_AI) || ch;
  }
  if (!s.properties.digInBy) {
    s.properties.digInBy = Object.assign({
      type: 'object',
      description: 'Per fighter, how far the AI digs in against that fighter (a number 0 or more). Every key is a fighter of data/fighters/roster.json (rule ai-digin-fighter).',
      propertyNames: { pattern: '^(_.*|[A-Z][A-Z0-9_]*)$' },
      additionalProperties: { type: 'number', minimum: 0 },
    }, { patternProperties: { '^_': true } });
    ch = true;
  }
  if (!s.required.includes('digInBy')) { s.required.push('digInBy'); ch = true; }
  if (ch) wj(f, s);
}

// =============================== xref ===============================
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes('/brawl/heavy/charge/fromTicks')) {
    const i = t.indexOf("      if (isObj(brl.heavy) && typeof brl.heavy.heldFullTicks === 'number'");
    if (i < 0) throw new Error('brawl-order held-ticks anchor');
    const j = t.indexOf('\n', i);
    const block = [
      "      const hv = isObj(brl.heavy) ? brl.heavy : {};",
      "      const chg = isObj(hv.charge) ? hv.charge : {};",
      "      if (typeof chg.fromTicks === 'number' && typeof chg.fullTicks === 'number' && chg.fromTicks >= chg.fullTicks) err(IT, '/brawl/heavy/charge/fromTicks', 'brawl-order', `charge fromTicks ${chg.fromTicks} must be below fullTicks ${chg.fullTicks}`);",
      "      if (typeof chg.fullTicks === 'number' && typeof chg.maxTicks === 'number' && chg.fullTicks >= chg.maxTicks) err(IT, '/brawl/heavy/charge/fullTicks', 'brawl-order', `charge fullTicks ${chg.fullTicks} must be below maxTicks ${chg.maxTicks}`);",
      "      if (isObj(brl.medium) && typeof brl.medium.windupTicks === 'number' && typeof hv.windupTicks === 'number' && brl.medium.windupTicks >= hv.windupTicks) err(IT, '/brawl/medium/windupTicks', 'brawl-order', `medium windupTicks ${brl.medium.windupTicks} must be below heavy windupTicks ${hv.windupTicks}`);",
      "      if (isObj(brl.give) && typeof brl.give.closeMaxBh === 'number' && typeof brl.give.leashBh === 'number' && brl.give.closeMaxBh > brl.give.leashBh) err(IT, '/brawl/give/closeMaxBh', 'brawl-order', `give closeMaxBh ${brl.give.closeMaxBh} must be at most leashBh ${brl.give.leashBh}`);",
      "      if (isObj(brl.burst) && Array.isArray(brl.burst.lands)) for (let li = 1; li < brl.burst.lands.length; li++) if (typeof brl.burst.lands[li] === 'number' && typeof brl.burst.lands[li - 1] === 'number' && brl.burst.lands[li] < brl.burst.lands[li - 1]) err(IT, `/brawl/burst/lands/${li}`, 'brawl-order', `burst lands ${brl.burst.lands[li]} falls below the one before (${brl.burst.lands[li - 1]})`);",
    ].join('\n');
    t = t.slice(0, i) + block + t.slice(j);
  }
  if (!t.includes("'ai-digin-fighter'")) {
    const a = "    if (isObj(brl)) {\n      if (isObj(brl.flurry)) {";
    // the digInBy check sits at the start of the fight-level section: it needs the ai.json document and the roster
    const anchor = "  // ---- combat styles ----\n";
    if (!t.includes(anchor)) throw new Error('digInBy anchor');
    t = t.replace(anchor, () => [
      "  // ---- the AI's digInBy (data/director/ai.json) ----",
      "  const aiDoc = get('data/director/ai.json');",
      "  const rosterDoc = get('data/fighters/roster.json');",
      "  if (isObj(aiDoc) && isObj(aiDoc.digInBy) && Array.isArray(rosterDoc)) {",
      "    for (const k of Object.keys(aiDoc.digInBy)) if (!k.startsWith('_') && !rosterDoc.includes(k)) err('data/director/ai.json', `/digInBy/${esc(k)}`, 'ai-digin-fighter', `\"${k}\" is not a fighter of data/fighters/roster.json (${rosterDoc.join(', ')})`);",
      "  }",
      "",
      anchor,
    ].join('\n'));
    void a;
  }
  fs.writeFileSync(f, t);
}

// =============================== fixtures ===============================
{
  const dir = 'tools/fixtures/virtual/data/director/';
  {
    const f = dir + 'interrupts.json';
    const o = rj(f);
    const before = JSON.stringify(o);
    fixBrawl(o.brawl);
    fixZip(o.zip);
    if (JSON.stringify(o) !== before) wj(f, o);
  }
  {
    const f = dir + 'ai.json';
    const o = rj(f);
    const before = JSON.stringify(o);
    for (const name of ['easy', 'medium', 'hard']) fixAiBrawl(o.levels && o.levels[name] && o.levels[name].brawl, name);
    if (o.digInBy === undefined) {
      const roster = rj('tools/fixtures/virtual/data/fighters/roster.json');
      const ids = Array.isArray(roster) ? roster : Object.keys(roster);
      o.digInBy = { [ids[ids.length - 1]]: DIGIN_SAMPLE };
    }
    if (JSON.stringify(o) !== before) wj(f, o);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const IT = 'data/director/interrupts.json';
  const AI = 'data/director/ai.json';
  const OWN = /^director-(interrupts|ai)-brawlc2-/;
  // 1. cases that name a removed key go
  const removedPaths = [...REMOVED_HEAVY.map((k) => '/brawl/heavy/' + k), ...REMOVED_BRAWL.map((k) => '/brawl/' + k), ...['easy', 'medium', 'hard'].flatMap((l) => REMOVED_AI.map((k) => `/levels/${l}/brawl/${k}`))];
  const names = (k) => (k.mutate || []).flatMap((m) => [...Object.keys(m.set || {}), ...(m.del || [])]).concat(k.expect && k.expect.pointer ? [k.expect.pointer] : []);
  const before = c.cases.length;
  // (and the "required" and "ok" cases of a removed key that only set a whole block without it: they test nothing now)
  const retiredId = /^director-(interrupts|ai)-brawl[a-z0-9]*-(.*-)?(held-mul|held-full|ender-after|step-in|ender-share|rash-heavy|heavy-after-close)/;
  c.cases = c.cases.filter((k) => OWN.test(k.id) || !(retiredId.test(k.id) || names(k).some((p) => removedPaths.includes(p))));
  const dropped = before - c.cases.length;
  // 2. every other case that sets a whole block follows the new shape
  let moved = 0;
  for (const k of c.cases) {
    if (OWN.test(k.id)) continue;
    for (const m of k.mutate || []) {
      if (!m.set) continue;
      if (m.file === IT) {
        if (m.set['/brawl']) moved += fixBrawl(m.set['/brawl']);
        if (m.set['/zip']) moved += fixZip(m.set['/zip']);
        if (m.set['/zip/heavy'] && typeof m.set['/zip/heavy'] === 'object') moved += fill(m.set['/zip/heavy'], ZIPHEAVY_ADD);
        if (m.set['/brawl/heavy'] && typeof m.set['/brawl/heavy'] === 'object') { moved += strip(m.set['/brawl/heavy'], REMOVED_HEAVY); moved += fill(m.set['/brawl/heavy'], HEAVY_ADD); }
        if (m.set['/brawl/nudge'] && typeof m.set['/brawl/nudge'] === 'object') moved += fill(m.set['/brawl/nudge'], NUDGE_ADD);
        if (m.set['/brawl/hitstop'] && typeof m.set['/brawl/hitstop'] === 'object') moved += fill(m.set['/brawl/hitstop'], HITSTOP_ADD);
      }
      if (m.file === AI) {
        for (const key of Object.keys(m.set)) {
          const mm = /^\/levels\/(easy|medium|hard)\/brawl$/.exec(key);
          if (mm) moved += fixAiBrawl(m.set[key], mm[1]);
          if (key === '/levels' && m.set[key] && typeof m.set[key] === 'object') for (const lv of ['easy', 'medium', 'hard']) if (m.set[key][lv] && m.set[key][lv].brawl) moved += fixAiBrawl(m.set[key][lv].brawl, lv);
        }
      }
    }
  }
  // 3. the new cases, from the spec
  const fx = rj('tools/fixtures/virtual/data/director/interrupts.json');
  const fa = rj('tools/fixtures/virtual/data/director/ai.json');
  const VALID = clone(fx.brawl);
  const VALID_AI = clone(fa.levels.medium.brawl);
  const it = (n, tweak, expect) => { const o = clone(VALID); tweak(o); return { id: 'director-interrupts-brawlc2-' + n, schema: 'director-interrupts.schema.json', mutate: [{ file: IT, set: { '/brawl': o } }], expect }; };
  const ai = (n, tweak, expect) => { const o = clone(VALID_AI); tweak(o); return { id: 'director-ai-brawlc2-' + n, schema: 'director-ai.schema.json', mutate: [{ file: AI, set: { '/levels/medium/brawl': o } }], expect }; };
  const get = (o, path) => path.reduce((a, k) => a[k], o);
  const put = (o, path, v) => { get(o, path.slice(0, -1))[path[path.length - 1]] = v; };
  const ptr = (base, path) => base + path.map((p) => '/' + p).join('');
  const slug = (path) => path.join('-').replace(/([A-Z])/g, (m) => m.toLowerCase()).toLowerCase();
  const out = [];
  /** the cases of one leaf; mk builds a case for a path tweak, base is the pointer of the block, req the pointer of the parent for `required`. */
  // leaves a cross-reference orders against another: their zero and large edge cases would break the order, so only the order cases cover them
  const ordered = new Set(['give/leashBh', 'give/closeMaxBh', 'heavy/charge/fromTicks', 'heavy/charge/fullTicks', 'heavy/charge/maxTicks', 'medium/windupTicks', 'heavy/windupTicks', 'burst/lands']);
  const leafCases = (mk, base, path, leaf) => {
    const s = slug(path);
    const skipEdge = ordered.has(path.join('/'));
    const P = ptr(base, path);
    const parent = ptr(base, path.slice(0, -1)) || base;
    out.push(mk(s + '-required', (o) => { delete get(o, path.slice(0, -1))[path[path.length - 1]]; }, { rule: 'required', pointer: parent }));
    switch (leaf.k) {
      case 'int0':
        out.push(mk(s + '-negative', (o) => put(o, path, -1), { rule: 'minimum', pointer: P }), mk(s + '-integer', (o) => put(o, path, leaf.v + 0.5), { rule: 'type', pointer: P }), mk(s + '-type', (o) => put(o, path, 'long'), { rule: 'type', pointer: P }));
        if (!skipEdge) out.push(mk(s + '-zero-ok', (o) => put(o, path, 0), null));
        break;
      case 'num0':
        out.push(mk(s + '-negative', (o) => put(o, path, -0.1), { rule: 'minimum', pointer: P }), mk(s + '-type', (o) => put(o, path, 'some'), { rule: 'type', pointer: P }));
        if (!skipEdge) out.push(mk(s + '-zero-ok', (o) => put(o, path, 0), null), mk(s + '-large-ok', (o) => put(o, path, 500), null));
        break;
      case 'share':
        out.push(mk(s + '-negative', (o) => put(o, path, -0.1), { rule: 'minimum', pointer: P }), mk(s + '-above-one', (o) => put(o, path, 1.1), { rule: 'maximum', pointer: P }), mk(s + '-type', (o) => put(o, path, 'often'), { rule: 'type', pointer: P }), mk(s + '-edges-ok', (o) => put(o, path, 0), null), mk(s + '-one-ok', (o) => put(o, path, 1), null));
        break;
      case 'pos01':
        out.push(mk(s + '-zero', (o) => put(o, path, 0), { rule: 'exclusiveMinimum', pointer: P }), mk(s + '-negative', (o) => put(o, path, -0.5), { rule: 'exclusiveMinimum', pointer: P }), mk(s + '-above-one', (o) => put(o, path, 1.1), { rule: 'maximum', pointer: P }), mk(s + '-type', (o) => put(o, path, 'half'), { rule: 'type', pointer: P }), mk(s + '-one-ok', (o) => put(o, path, 1), null), mk(s + '-small-ok', (o) => put(o, path, 0.05), null));
        break;
      case 'bool':
        out.push(mk(s + '-type', (o) => put(o, path, 1), { rule: 'type', pointer: P }), mk(s + '-false-ok', (o) => put(o, path, false), null));
        break;
      case 'arr2int': case 'arr2num': case 'arr7num': {
        const n = leaf.k === 'arr7num' ? 7 : 2;
        const item = leaf.k === 'arr2int' ? 4 : 1.5;
        out.push(mk(s + '-too-short', (o) => put(o, path, leaf.v.slice(0, n - 1)), { rule: 'minItems', pointer: P }), mk(s + '-too-long', (o) => put(o, path, leaf.v.concat([5])), { rule: 'maxItems', pointer: P }), mk(s + '-negative-item', (o) => put(o, path, leaf.v.map((x, i) => (i === 0 ? -1 : x))), { rule: 'minimum', pointer: P + '/0' }), mk(s + '-item-type', (o) => put(o, path, leaf.v.map((x, i) => (i === 0 ? 'x' : x))), { rule: 'type', pointer: P + '/0' }), mk(s + '-type', (o) => put(o, path, item), { rule: 'type', pointer: P }));
        if (leaf.k === 'arr2int') out.push(mk(s + '-item-integer', (o) => put(o, path, leaf.v.map((x, i) => (i === 0 ? 4.5 : x))), { rule: 'type', pointer: P + '/0' }));
        break;
      }
      case 'shot':
        out.push(mk(s + '-type', (o) => put(o, path, 5), { rule: 'type', pointer: P }), mk(s + '-shape', (o) => put(o, path, 'Big Bolt'), { rule: 'pattern', pointer: P }));
        break;
      default: throw new Error(leaf.k);
    }
  };
  /** the cases of one spec node under a path: leaf cases, and for an object its type, unknown key and note. */
  const walk = (mk, base, path, node) => {
    if (isLeaf(node)) { leafCases(mk, base, path, node); return; }
    const s = slug(path);
    const P = ptr(base, path);
    out.push(mk(s + '-required', (o) => { delete get(o, path.slice(0, -1))[path[path.length - 1]]; }, { rule: 'required', pointer: ptr(base, path.slice(0, -1)) || base }));
    out.push(mk(s + '-type', (o) => put(o, path, 5), { rule: 'type', pointer: P }), mk(s + '-unknown-key', (o) => { get(o, path).mood = 1; }, { rule: 'additionalProperties', pointer: P + '/mood' }), mk(s + '-note-ok', (o) => { get(o, path)._why = 'a note'; }, null));
    for (const [k, v] of Object.entries(node)) walk(mk, base, path.concat(k), v);
  };
  out.push(it('valid', () => {}, null));
  for (const [k, v] of Object.entries(BRAWL_ADD)) walk(it, '/brawl', [k], v);
  for (const [k, v] of Object.entries(NUDGE_ADD)) leafCases(it, '/brawl', ['nudge', k], v);
  for (const [k, v] of Object.entries(HEAVY_ADD)) walk(it, '/brawl', ['heavy', k], v);
  for (const [k, v] of Object.entries(HITSTOP_ADD)) leafCases(it, '/brawl', ['hitstop', k], v);
  out.push(...REMOVED_HEAVY.map((k) => it('heavy-' + k.toLowerCase() + '-retired', (o) => { o.heavy[k] = 1; }, { rule: 'additionalProperties', pointer: '/brawl/heavy/' + k })));
  out.push(...REMOVED_BRAWL.map((k) => it(k.toLowerCase() + '-retired', (o) => { o[k] = 1; }, { rule: 'additionalProperties', pointer: '/brawl/' + k })));
  // the values-only keys stay valid at other values
  out.push(it('values-move-ok', (o) => { o.heavyMul = 3; o.heavy.windupTicks = 30; o.heavy.ki = 9; o.heavy.recover = 14; o.heavy.recoverWhiff = 40; }, null));
  // cross-references (rule brawl-order)
  out.push(
    it('charge-from-equals-full', (o) => { o.heavy.charge.fromTicks = 40; o.heavy.charge.fullTicks = 40; }, { rule: 'xref:brawl-order', pointer: '/brawl/heavy/charge/fromTicks' }),
    it('charge-from-above-full', (o) => { o.heavy.charge.fromTicks = 50; }, { rule: 'xref:brawl-order', pointer: '/brawl/heavy/charge/fromTicks' }),
    it('charge-from-just-below-full-ok', (o) => { o.heavy.charge.fromTicks = 39; }, null),
    it('charge-full-equals-max', (o) => { o.heavy.charge.fullTicks = 120; o.heavy.charge.maxTicks = 120; }, { rule: 'xref:brawl-order', pointer: '/brawl/heavy/charge/fullTicks' }),
    it('charge-full-above-max', (o) => { o.heavy.charge.fullTicks = 130; }, { rule: 'xref:brawl-order', pointer: '/brawl/heavy/charge/fullTicks' }),
    it('charge-full-just-below-max-ok', (o) => { o.heavy.charge.fullTicks = 119; }, null),
    it('medium-windup-equals-heavy', (o) => { o.medium.windupTicks = o.heavy.windupTicks; }, { rule: 'xref:brawl-order', pointer: '/brawl/medium/windupTicks' }),
    it('medium-windup-above-heavy', (o) => { o.medium.windupTicks = o.heavy.windupTicks + 5; }, { rule: 'xref:brawl-order', pointer: '/brawl/medium/windupTicks' }),
    it('medium-windup-just-below-heavy-ok', (o) => { o.medium.windupTicks = o.heavy.windupTicks - 1; }, null),
    it('give-close-above-leash', (o) => { o.give.closeMaxBh = o.give.leashBh + 1; }, { rule: 'xref:brawl-order', pointer: '/brawl/give/closeMaxBh' }),
    it('give-close-equals-leash-ok', (o) => { o.give.closeMaxBh = o.give.leashBh; }, null),
    it('burst-lands-falls', (o) => { o.burst.lands = [2, 4, 6, 5, 10, 12, 14]; }, { rule: 'xref:brawl-order', pointer: '/brawl/burst/lands/3' }),
    it('burst-lands-equal-neighbours-ok', (o) => { o.burst.lands = [2, 4, 4, 8, 10, 12, 14]; }, null),
  );
  // a zip heavy's damage
  const VALID_ZIP = clone(fx.zip);
  const zp = (n, tweak, expect) => { const o = clone(VALID_ZIP); tweak(o); return { id: 'director-interrupts-brawlc2-zip-heavy-damage-' + n, schema: 'director-interrupts.schema.json', mutate: [{ file: IT, set: { '/zip': o } }], expect }; };
  out.push(
    zp('valid', () => {}, null),
    zp('required', (o) => { delete o.heavy.damage; }, { rule: 'required', pointer: '/zip/heavy' }),
    zp('negative', (o) => { o.heavy.damage = -1; }, { rule: 'minimum', pointer: '/zip/heavy/damage' }),
    zp('type', (o) => { o.heavy.damage = 'big'; }, { rule: 'type', pointer: '/zip/heavy/damage' }),
    zp('zero-ok', (o) => { o.heavy.damage = 0; }, null),
    zp('large-ok', (o) => { o.heavy.damage = 500; }, null),
  );
  // the AI: the shares, the removed keys, digInBy
  out.push(ai('valid', () => {}, null));
  for (const k of Object.keys(AI_BRAWL_ADD)) leafCases(ai, '/levels/medium/brawl', [k], AI_BRAWL_ADD[k]);
  out.push(...REMOVED_AI.map((k) => ai(k.toLowerCase() + '-retired', (o) => { o[k] = 0.4; }, { rule: 'additionalProperties', pointer: '/levels/medium/brawl/' + k })));
  const roster = rj('tools/fixtures/virtual/data/fighters/roster.json');
  const rid = (Array.isArray(roster) ? roster : Object.keys(roster))[0];
  const dg = (n, v, expect) => ({ id: 'director-ai-brawlc2-diginby-' + n, schema: 'director-ai.schema.json', mutate: [{ file: AI, set: { '/digInBy': v } }], expect });
  out.push(
    dg('valid', { [rid]: 0.5 }, null),
    dg('empty-ok', {}, null),
    dg('zero-ok', { [rid]: 0 }, null),
    dg('large-ok', { [rid]: 3 }, null),
    dg('note-ok', { _why: 'a note', [rid]: 0.5 }, null),
    dg('negative', { [rid]: -0.1 }, { rule: 'minimum', pointer: '/digInBy/' + rid }),
    dg('type', { [rid]: 'deep' }, { rule: 'type', pointer: '/digInBy/' + rid }),
    dg('not-an-object', [rid], { rule: 'type', pointer: '/digInBy' }),
    dg('key-shape', { 'No Body': 0.5 }, { rule: 'propertyNames', pointer: '/digInBy/No Body' }),
    dg('unknown-fighter', { NOBODY: 0.5 }, { rule: 'xref:ai-digin-fighter', pointer: '/digInBy/NOBODY' }),
    { id: 'director-ai-brawlc2-diginby-required', schema: 'director-ai.schema.json', mutate: [{ file: AI, del: ['/digInBy'] }], expect: { rule: 'required', pointer: '' } },
  );
  let n = 0;
  for (const k of out) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`brawl C2 schema applied (${n} new cases, ${dropped} retired cases dropped, ${moved} earlier values changed)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  let t = fs.readFileSync(f, 'utf8');
  const old = 'and heavy.heldFullTicks is at most heldMaxTicks';
  if (t.includes(old)) t = t.replace(old, "heavy.charge.fromTicks < fullTicks < maxTicks, medium.windupTicks < heavy.windupTicks, give.closeMaxBh <= give.leashBh and burst.lands never falls");
  if (!t.includes('`ai-digin-fighter`')) {
    const lines = t.split('\n');
    const i = lines.findIndex((l) => l.includes('`brawl-order`'));
    if (i < 0) throw new Error('C2 README anchor');
    lines.splice(i + 1, 0, "| `ai-digin-fighter` | data/director/ai.json: every key of `digInBy` is a fighter of data/fighters/roster.json |");
    t = lines.join('\n');
  }
  fs.writeFileSync(f, t);
}
