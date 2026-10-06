// Schema keys for Encounter's zip slice (the zip as a move in the brawl's reach: docs/design/melee-press-feel.md; values may move on measurement,
// the keys are fixed). NOT run by CI, the validator or the sim. Run once from the repo root, in the commit that lands the slice's data:
//     node docs/tools/pending/apply-zip1.cjs
// It does NOT edit data/. A top-level `zip` block in data/director/interrupts.json (closed; required once the slice lands):
//   enabled (boolean); band {minBh, maxBh} (numbers above 0)
//   strike {ki, tellTicks, inTicks [lo, hi], reachBefore, reachAfter, outTicks, heldTicks, heldReachBefore}
//   heavy  {ki, tellTicks, inTicks [lo, hi], reachBefore, reachAfter, outTicks, heldTicks}
//   floor {minTicks, bhPerTick}; out {freeBh, bhPerTick, maxTicks}
//   exit {awayBh, capBh, slideDeg, probes, clearBh}
//   towardDeg, awayDeg, bowBh (the height of the way out's bow; Game Design's name, a number above 0; exit.arcBh is not a key), exitSteps, knockdownTicks
//   mul {speed, tech, held}; reel {speed, tech, held}; stagger {speed, tech}
//   counter {techBefore, heavyBefore, staggerTicks, mul}; dodgeConvertTicks
// Types: ticks (and tellTicks, outTicks, heldTicks, the reel and stagger lengths, techBefore, heavyBefore, exitSteps) are integers of at least 1;
// inTicks is a pair [lo, hi] of such integers; ki, Bh, reach and bhPerTick numbers are 0 or more (band.minBh and band.maxBh above 0); mul numbers
// are above 0; degrees are above 0 and at most 180; probes is an integer 1 to 64. The reachBefore, reachAfter and heldReachBefore values are ticks
// (the ticks in reach before and after the blow): integers of 0 or more.
// Rules (zip-order): band.minBh below maxBh; each inTicks lo at most hi; exit.capBh at most band.maxBh; towardDeg + awayDeg at most 180. Rule
// zip-floor: floor.minTicks at least 4 (Legal, RL-076: a zip's way in and out each last at least 4 ticks, no blink step).
// data/director/ai.json, each level: zipShare, zipHeavyShare, zipCounter, zipDodge, zipExit and zipPunish (shares 0 to 1; zipExit: the share of
// its zips that pick an exit other than back; zipPunish: the share at which the AI presses a light on a zipper in reach once his blow has resolved),
// required.
// The fixtures get the block and the keys; every case sets its own whole block. Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const obj = (props, opts = {}) => Object.assign({ type: 'object', required: opts.required === undefined ? Object.keys(props) : opts.required, properties: props }, opts.description ? { description: opts.description } : {}, closed);
const clone = (o) => JSON.parse(JSON.stringify(o));
const ticks = (d) => ({ type: 'integer', minimum: 1, description: d });
const ticks0 = (d) => ({ type: 'integer', minimum: 0, description: d });
const num0 = (d) => ({ type: 'number', minimum: 0, description: d });
const pos = (d) => ({ type: 'number', exclusiveMinimum: 0, description: d });
const deg = (d) => ({ type: 'number', exclusiveMinimum: 0, maximum: 180, description: d });
const share = (d) => ({ type: 'number', minimum: 0, maximum: 1, description: d });
const pair = (d) => ({ type: 'array', minItems: 2, maxItems: 2, items: { type: 'integer', minimum: 1 }, description: d });

const VALID = {
  enabled: true,
  band: { minBh: 3, maxBh: 12.5 },
  strike: { ki: 20, tellTicks: 6, inTicks: [6, 8], reachBefore: 4, reachAfter: 6, outTicks: 10, heldTicks: 12, heldReachBefore: 8 },
  heavy: { ki: 30, tellTicks: 10, inTicks: [8, 10], reachBefore: 12, reachAfter: 10, outTicks: 12, heldTicks: 20 },
  floor: { minTicks: 4, bhPerTick: 3 },
  out: { freeBh: 8, bhPerTick: 2, maxTicks: 20 },
  exit: { awayBh: 6, capBh: 12.5, slideDeg: 15, probes: 24, clearBh: 1 },
  towardDeg: 45,
  awayDeg: 45,
  bowBh: 2,
  exitSteps: 16,
  knockdownTicks: 24,
  mul: { speed: 1, tech: 1.25, held: 1.25 },
  reel: { speed: 4, tech: 8, held: 12 },
  stagger: { speed: 12, tech: 20 },
  counter: { techBefore: 4, heavyBefore: 6, staggerTicks: 12, mul: 1.25 },
  dodgeConvertTicks: 8,
};
const VALID_AI = { zipShare: 0.3, zipHeavyShare: 0.2, zipCounter: 0.5, zipDodge: 0.4, zipExit: 0.5, zipPunish: 0.5 };
const AI_KEYS = Object.keys(VALID_AI);
const AI_BY_LEVEL = { easy: { zipShare: 0.1, zipHeavyShare: 0.1, zipCounter: 0.2, zipDodge: 0.2, zipExit: 0.2, zipPunish: 0.2 }, medium: { zipShare: 0.3, zipHeavyShare: 0.2, zipCounter: 0.5, zipDodge: 0.4, zipExit: 0.5, zipPunish: 0.5 }, hard: { zipShare: 0.5, zipHeavyShare: 0.4, zipCounter: 0.8, zipDodge: 0.7, zipExit: 0.8, zipPunish: 0.8 } };

// =============================== interrupts schema ===============================
{
  const f = 'tools/schemas/director-interrupts.schema.json';
  const s = rj(f);
  if (!s.properties.zip) {
    s.properties.zip = obj({
      enabled: { type: 'boolean', description: 'false: no zip move.' },
      band: obj({ minBh: pos('The nearest separation, in body heights, a zip can start from.'), maxBh: pos('The farthest separation a zip can start from.') }, { description: 'The separations a zip works from; minBh below maxBh (zip-order).' }),
      strike: obj({
        ki: num0('The ki the zip strike costs.'),
        tellTicks: ticks('The tell before the dash.'),
        inTicks: pair('The way in, in ticks: [lo, hi], lo at most hi (zip-order).'),
        reachBefore: ticks0('Ticks in reach before the blow lands.'),
        reachAfter: ticks0('Ticks in reach after the blow lands.'),
        outTicks: ticks('The way out, in ticks.'),
        heldTicks: ticks('The longest the strike can be held.'),
        heldReachBefore: ticks0('Ticks in reach before a held strike lands.'),
      }, { description: 'The zip strike (the light blow at the end of a zip).' }),
      heavy: obj({
        ki: num0('The ki the zip heavy costs.'),
        tellTicks: ticks('The tell before the dash.'),
        inTicks: pair('The way in, in ticks: [lo, hi], lo at most hi (zip-order).'),
        reachBefore: ticks0('Ticks in reach before the blow lands.'),
        reachAfter: ticks0('Ticks in reach after the blow lands.'),
        outTicks: ticks('The way out, in ticks.'),
        heldTicks: ticks('The longest the heavy can be held.'),
      }, { description: 'The zip heavy.' }),
      floor: obj({ minTicks: ticks('The least ticks a zip\'s way in and way out each take (Legal, RL-076: at least 4; rule zip-floor).'), bhPerTick: num0('The most body heights a zip covers in one tick.') }, { description: 'The floor on a zip\'s travel ticks (no blink step).' }),
      out: obj({ freeBh: num0('The distance the way out covers at no cost.'), bhPerTick: num0('Body heights a tick on the way out.'), maxTicks: ticks('The longest the way out can take.') }, { description: 'The way out.' }),
      exit: obj({
        awayBh: num0('How far the exit goes away.'),
        capBh: num0('The farthest an exit may end (at most band.maxBh; zip-order).'),
        slideDeg: deg('The slide of an exit along a surface, in degrees.'),
        probes: { type: 'integer', minimum: 1, maximum: 64, description: 'How many places the exit probes for a clear one.' },
        clearBh: num0('The clear space an exit needs.'),
      }, { description: 'Where a zip leaves to.' }),
      towardDeg: deg('The angle of a zip toward the rival, in degrees.'),
      awayDeg: deg('The angle of a zip away, in degrees; towardDeg + awayDeg at most 180 (zip-order).'),
      bowBh: pos('The height, in body heights, of the bow a way out takes over or round the rival (Game Design: zip.bowBh).'),
      exitSteps: ticks('How many steps an exit is searched in.'),
      knockdownTicks: ticks('The ticks a zip knockdown lasts.'),
      mul: obj({ speed: pos('The damage multiplier of a speed zip.'), tech: pos('The multiplier of a tech zip.'), held: pos('The multiplier of a held zip.') }, { description: 'The worth of a zip blow by its form.' }),
      reel: obj({ speed: ticks('Ticks the rival reels from a speed zip.'), tech: ticks('Ticks from a tech zip.'), held: ticks('Ticks from a held zip.') }, { description: 'The reel a zip blow gives, by its form.' }),
      stagger: obj({ speed: ticks('Ticks of stagger a speed zip gives.'), tech: ticks('Ticks of stagger a tech zip gives.') }, { description: 'The stagger a zip close gives, by its form.' }),
      counter: obj({
        techBefore: ticks('How many ticks before the rival\'s blow a tech counter can be pressed.'),
        heavyBefore: ticks('How many ticks before the rival\'s blow a heavy counter can be pressed.'),
        staggerTicks: ticks('The stagger a counter gives.'),
        mul: pos('The multiplier of a counter.'),
      }, { description: 'A zip as a counter.' }),
      dodgeConvertTicks: ticks('How many ticks a dodge may turn into a zip.'),
    }, { description: 'The zip as a move in the brawl\'s reach (Encounter\'s zip slice).' });
    if (!s.required.includes('zip')) s.required.push('zip');
    s.description = s.description.replace('Orders (', () => 'Orders (a zip\'s band.minBh below maxBh, each inTicks lo at most hi, exit.capBh at most band.maxBh and towardDeg + awayDeg at most 180 (zip-order), and floor.minTicks at least 4 by Legal\'s RL-076 (zip-floor); ');
    wj(f, s);
  }
}

// ---- schema upgrade: a first version of this script took the reach values as any number of 0 or more ----
{
  const f = 'tools/schemas/director-interrupts.schema.json';
  const s = rj(f);
  let changed = false;
  for (const [w, keys] of [['strike', ['reachBefore', 'reachAfter', 'heldReachBefore']], ['heavy', ['reachBefore', 'reachAfter']]]) {
    const p = s.properties.zip && s.properties.zip.properties[w];
    if (!p) continue;
    for (const k of keys) if (p.properties[k] && p.properties[k].type === 'number') { p.properties[k] = ticks0(p.properties[k].description.replace(/^How near the blow reaches before it lands\.$/, 'Ticks in reach before the blow lands.').replace(/^How far past the rival the blow reaches after it lands\.$/, 'Ticks in reach after the blow lands.').replace(/^The reach before landing of a held strike\.$/, 'Ticks in reach before a held strike lands.')); changed = true; }
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
    for (const [k, d] of [['zipShare', 'The chance the AI zips in from the band.'], ['zipHeavyShare', 'The chance a zip it makes is the heavy.'], ['zipCounter', 'The chance it counters with a zip.'], ['zipDodge', 'The chance it turns a dodge into a zip.'], ['zipExit', 'The share of its zips that pick an exit other than back.'], ['zipPunish', 'The share at which it presses a light on a zipper in reach once his blow has resolved.']]) {
      if (!L.properties[k]) { L.properties[k] = share(d); changed = true; }
      if (!L.required.includes(k)) { L.required.push(k); changed = true; }
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
    if (o.zip === undefined) { o.zip = clone(VALID); wj(f, o); }
  }
  {
    const f = dir + 'ai.json';
    const o = rj(f);
    let changed = false;
    for (const name of ['easy', 'medium', 'hard']) {
      const L = o.levels && o.levels[name];
      if (!L) continue;
      for (const k of AI_KEYS) if (L[k] === undefined) { L[k] = AI_BY_LEVEL[name][k]; changed = true; }
    }
    if (changed) wj(f, o);
  }
}

// =============================== xref ===============================
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes("'zip-order'")) {
    const a = '    const brl = itr.brawl;';
    if (!t.includes(a)) throw new Error('zip anchor');
    t = t.replace(a, () => [
      "    const zp = itr.zip;",
      "    if (isObj(zp)) {",
      "      if (isObj(zp.band) && typeof zp.band.minBh === 'number' && typeof zp.band.maxBh === 'number' && zp.band.minBh >= zp.band.maxBh) err(IT, '/zip/band/minBh', 'zip-order', `band minBh ${zp.band.minBh} is not below maxBh ${zp.band.maxBh}`);",
      "      for (const w of ['strike', 'heavy']) if (isObj(zp[w]) && Array.isArray(zp[w].inTicks) && zp[w].inTicks.length === 2 && typeof zp[w].inTicks[0] === 'number' && typeof zp[w].inTicks[1] === 'number' && zp[w].inTicks[0] > zp[w].inTicks[1]) err(IT, `/zip/${w}/inTicks`, 'zip-order', `${w} inTicks [${zp[w].inTicks[0]}, ${zp[w].inTicks[1]}] runs high to low`);",
      "      if (isObj(zp.exit) && isObj(zp.band) && typeof zp.exit.capBh === 'number' && typeof zp.band.maxBh === 'number' && zp.exit.capBh > zp.band.maxBh) err(IT, '/zip/exit/capBh', 'zip-order', `exit capBh ${zp.exit.capBh} is above band maxBh ${zp.band.maxBh}`);",
      "      if (typeof zp.towardDeg === 'number' && typeof zp.awayDeg === 'number' && zp.towardDeg + zp.awayDeg > 180) err(IT, '/zip/awayDeg', 'zip-order', `towardDeg ${zp.towardDeg} + awayDeg ${zp.awayDeg} is above 180`);",
      "      if (isObj(zp.floor) && typeof zp.floor.minTicks === 'number' && zp.floor.minTicks < 4) err(IT, '/zip/floor/minTicks', 'zip-floor', `floor minTicks ${zp.floor.minTicks} is below 4: Legal's RL-076 requires a zip's way in and way out each to last at least 4 ticks (a shorter one is a blink step)`);",
      "    }",
      a,
    ].join('\n'));
    fs.writeFileSync(f, t);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const IT = 'data/director/interrupts.json';
  const AI = 'data/director/ai.json';
  const zp = (n, tweak, expect) => { const o = clone(VALID); tweak(o); return { id: 'director-interrupts-zip-' + n, schema: 'director-interrupts.schema.json', mutate: [{ file: IT, set: { '/zip': o } }], expect }; };
  const ai = (n, tweak, expect) => { const o = clone(VALID_AI); tweak(o); return { id: 'director-ai-zip-' + n, schema: 'director-ai.schema.json', mutate: [{ file: AI, set: Object.fromEntries(Object.entries(o).map(([k, v]) => ['/levels/medium/' + k, v])) }], expect }; };
  const Z = '/zip/';
  const add = [
    zp('valid', () => {}, null),
    { id: 'director-interrupts-zip-required', schema: 'director-interrupts.schema.json', mutate: [{ file: IT, del: ['/zip'] }], expect: { rule: 'required', pointer: '' } },
    zp('unknown-key', (o) => { o.extra = 1; }, { rule: 'additionalProperties', pointer: Z + 'extra' }),
    zp('underscore-key-ok', (o) => { o._note = 'a note'; }, null),
    zp('off-ok', (o) => { o.enabled = false; }, null),
    zp('enabled-required', (o) => { delete o.enabled; }, { rule: 'required', pointer: '/zip' }),
    zp('enabled-type', (o) => { o.enabled = 'yes'; }, { rule: 'type', pointer: Z + 'enabled' }),
    ...['band', 'strike', 'heavy', 'floor', 'out', 'exit', 'towardDeg', 'awayDeg', 'bowBh', 'exitSteps', 'knockdownTicks', 'mul', 'reel', 'stagger', 'counter', 'dodgeConvertTicks'].map((k) => zp(k.toLowerCase() + '-required', (o) => { delete o[k]; }, { rule: 'required', pointer: '/zip' })),
    // band
    zp('band-min-zero', (o) => { o.band.minBh = 0; }, { rule: 'exclusiveMinimum', pointer: Z + 'band/minBh' }),
    zp('band-max-zero', (o) => { o.band.maxBh = 0; o.band.minBh = 0.1; }, { rule: 'exclusiveMinimum', pointer: Z + 'band/maxBh' }),
    zp('band-min-type', (o) => { o.band.minBh = 'near'; }, { rule: 'type', pointer: Z + 'band/minBh' }),
    zp('band-key-required', (o) => { delete o.band.maxBh; }, { rule: 'required', pointer: Z + 'band' }),
    zp('band-unknown-key', (o) => { o.band.mid = 5; }, { rule: 'additionalProperties', pointer: Z + 'band/mid' }),
    zp('band-min-above-max', (o) => { o.band.minBh = 13; }, { rule: 'xref:zip-order', pointer: Z + 'band/minBh' }),
    zp('band-min-equals-max', (o) => { o.band.minBh = 12.5; }, { rule: 'xref:zip-order', pointer: Z + 'band/minBh' }),
    zp('band-just-apart-ok', (o) => { o.band.minBh = 12.4; }, null),
    // strike and heavy
    ...['strike', 'heavy'].flatMap((w) => [
      zp(w + '-unknown-key', (o) => { o[w].extra = 1; }, { rule: 'additionalProperties', pointer: Z + w + '/extra' }),
      zp(w + '-ki-required', (o) => { delete o[w].ki; }, { rule: 'required', pointer: Z + w }),
      zp(w + '-ki-negative', (o) => { o[w].ki = -1; }, { rule: 'minimum', pointer: Z + w + '/ki' }),
      zp(w + '-ki-zero-ok', (o) => { o[w].ki = 0; }, null),
      zp(w + '-tell-zero', (o) => { o[w].tellTicks = 0; }, { rule: 'minimum', pointer: Z + w + '/tellTicks' }),
      zp(w + '-tell-integer', (o) => { o[w].tellTicks = 6.5; }, { rule: 'type', pointer: Z + w + '/tellTicks' }),
      zp(w + '-in-ticks-type', (o) => { o[w].inTicks = 6; }, { rule: 'type', pointer: Z + w + '/inTicks' }),
      zp(w + '-in-ticks-one', (o) => { o[w].inTicks = [6]; }, { rule: 'minItems', pointer: Z + w + '/inTicks' }),
      zp(w + '-in-ticks-three', (o) => { o[w].inTicks = [6, 7, 8]; }, { rule: 'maxItems', pointer: Z + w + '/inTicks' }),
      zp(w + '-in-ticks-zero', (o) => { o[w].inTicks = [0, 8]; }, { rule: 'minimum', pointer: Z + w + '/inTicks/0' }),
      zp(w + '-in-ticks-integer', (o) => { o[w].inTicks = [6, 8.5]; }, { rule: 'type', pointer: Z + w + '/inTicks/1' }),
      zp(w + '-in-ticks-reversed', (o) => { o[w].inTicks = [9, 8]; }, { rule: 'xref:zip-order', pointer: Z + w + '/inTicks' }),
      zp(w + '-in-ticks-equal-ok', (o) => { o[w].inTicks = [8, 8]; }, null),
      zp(w + '-reach-before-negative', (o) => { o[w].reachBefore = -1; }, { rule: 'minimum', pointer: Z + w + '/reachBefore' }),
      zp(w + '-reach-after-negative', (o) => { o[w].reachAfter = -1; }, { rule: 'minimum', pointer: Z + w + '/reachAfter' }),
      zp(w + '-reach-before-integer', (o) => { o[w].reachBefore = 4.5; }, { rule: 'type', pointer: Z + w + '/reachBefore' }),
      zp(w + '-reach-after-integer', (o) => { o[w].reachAfter = 6.25; }, { rule: 'type', pointer: Z + w + '/reachAfter' }),
      zp(w + '-reach-zero-ok', (o) => { o[w].reachBefore = 0; o[w].reachAfter = 0; }, null),
      zp(w + '-out-zero', (o) => { o[w].outTicks = 0; }, { rule: 'minimum', pointer: Z + w + '/outTicks' }),
      zp(w + '-held-zero', (o) => { o[w].heldTicks = 0; }, { rule: 'minimum', pointer: Z + w + '/heldTicks' }),
    ]),
    zp('strike-held-reach-required', (o) => { delete o.strike.heldReachBefore; }, { rule: 'required', pointer: Z + 'strike' }),
    zp('strike-held-reach-negative', (o) => { o.strike.heldReachBefore = -1; }, { rule: 'minimum', pointer: Z + 'strike/heldReachBefore' }),
    zp('strike-held-reach-integer', (o) => { o.strike.heldReachBefore = 8.5; }, { rule: 'type', pointer: Z + 'strike/heldReachBefore' }),
    zp('strike-held-reach-zero-ok', (o) => { o.strike.heldReachBefore = 0; }, null),
    zp('heavy-has-no-held-reach', (o) => { o.heavy.heldReachBefore = 8; }, { rule: 'additionalProperties', pointer: Z + 'heavy/heldReachBefore' }),
    // floor, out, exit
    zp('floor-min-ticks-three', (o) => { o.floor.minTicks = 3; }, { rule: 'xref:zip-floor', pointer: Z + 'floor/minTicks' }),
    zp('floor-min-ticks-one', (o) => { o.floor.minTicks = 1; }, { rule: 'xref:zip-floor', pointer: Z + 'floor/minTicks' }),
    zp('floor-min-ticks-zero', (o) => { o.floor.minTicks = 0; }, { rule: 'minimum', pointer: Z + 'floor/minTicks' }),
    zp('floor-min-ticks-four-ok', (o) => { o.floor.minTicks = 4; }, null),
    zp('floor-min-ticks-more-ok', (o) => { o.floor.minTicks = 9; }, null),
    zp('floor-min-ticks-integer', (o) => { o.floor.minTicks = 4.5; }, { rule: 'type', pointer: Z + 'floor/minTicks' }),
    zp('floor-bh-negative', (o) => { o.floor.bhPerTick = -1; }, { rule: 'minimum', pointer: Z + 'floor/bhPerTick' }),
    zp('floor-key-required', (o) => { delete o.floor.bhPerTick; }, { rule: 'required', pointer: Z + 'floor' }),
    zp('out-free-negative', (o) => { o.out.freeBh = -1; }, { rule: 'minimum', pointer: Z + 'out/freeBh' }),
    zp('out-bh-negative', (o) => { o.out.bhPerTick = -1; }, { rule: 'minimum', pointer: Z + 'out/bhPerTick' }),
    zp('out-max-zero', (o) => { o.out.maxTicks = 0; }, { rule: 'minimum', pointer: Z + 'out/maxTicks' }),
    zp('out-unknown-key', (o) => { o.out.extra = 1; }, { rule: 'additionalProperties', pointer: Z + 'out/extra' }),
    zp('exit-key-required', (o) => { delete o.exit.clearBh; }, { rule: 'required', pointer: Z + 'exit' }),
    zp('exit-arc-is-not-a-key', (o) => { o.exit.arcBh = 2; }, { rule: 'additionalProperties', pointer: Z + 'exit/arcBh' }),
    zp('exit-away-negative', (o) => { o.exit.awayBh = -1; }, { rule: 'minimum', pointer: Z + 'exit/awayBh' }),
    zp('exit-cap-above-band-max', (o) => { o.exit.capBh = 13; }, { rule: 'xref:zip-order', pointer: Z + 'exit/capBh' }),
    zp('exit-cap-equals-band-max-ok', (o) => { o.exit.capBh = 12.5; }, null),
    zp('exit-cap-below-band-max-ok', (o) => { o.exit.capBh = 6; }, null),
    zp('exit-slide-zero', (o) => { o.exit.slideDeg = 0; }, { rule: 'exclusiveMinimum', pointer: Z + 'exit/slideDeg' }),
    zp('exit-slide-above-180', (o) => { o.exit.slideDeg = 181; }, { rule: 'maximum', pointer: Z + 'exit/slideDeg' }),
    zp('exit-probes-zero', (o) => { o.exit.probes = 0; }, { rule: 'minimum', pointer: Z + 'exit/probes' }),
    zp('exit-probes-sixty-five', (o) => { o.exit.probes = 65; }, { rule: 'maximum', pointer: Z + 'exit/probes' }),
    zp('exit-probes-integer', (o) => { o.exit.probes = 24.5; }, { rule: 'type', pointer: Z + 'exit/probes' }),
    zp('exit-probes-edges-ok', (o) => { o.exit.probes = 64; }, null),
    zp('exit-probes-one-ok', (o) => { o.exit.probes = 1; }, null),
    zp('exit-clear-negative', (o) => { o.exit.clearBh = -1; }, { rule: 'minimum', pointer: Z + 'exit/clearBh' }),
    zp('bow-zero', (o) => { o.bowBh = 0; }, { rule: 'exclusiveMinimum', pointer: Z + 'bowBh' }),
    zp('bow-negative', (o) => { o.bowBh = -1; }, { rule: 'exclusiveMinimum', pointer: Z + 'bowBh' }),
    zp('bow-type', (o) => { o.bowBh = 'high'; }, { rule: 'type', pointer: Z + 'bowBh' }),
    zp('bow-fraction-ok', (o) => { o.bowBh = 0.25; }, null),
    // angles and the rest
    zp('toward-zero', (o) => { o.towardDeg = 0; }, { rule: 'exclusiveMinimum', pointer: Z + 'towardDeg' }),
    zp('toward-above-180', (o) => { o.towardDeg = 181; }, { rule: 'maximum', pointer: Z + 'towardDeg' }),
    zp('away-zero', (o) => { o.awayDeg = 0; }, { rule: 'exclusiveMinimum', pointer: Z + 'awayDeg' }),
    zp('away-above-180', (o) => { o.awayDeg = 181; }, { rule: 'maximum', pointer: Z + 'awayDeg' }),
    zp('angles-sum-above-180', (o) => { o.towardDeg = 100; o.awayDeg = 81; }, { rule: 'xref:zip-order', pointer: Z + 'awayDeg' }),
    zp('angles-sum-180-ok', (o) => { o.towardDeg = 100; o.awayDeg = 80; }, null),
    zp('angles-type', (o) => { o.towardDeg = 'wide'; }, { rule: 'type', pointer: Z + 'towardDeg' }),
    zp('exit-steps-zero', (o) => { o.exitSteps = 0; }, { rule: 'minimum', pointer: Z + 'exitSteps' }),
    zp('exit-steps-integer', (o) => { o.exitSteps = 16.5; }, { rule: 'type', pointer: Z + 'exitSteps' }),
    zp('knockdown-zero', (o) => { o.knockdownTicks = 0; }, { rule: 'minimum', pointer: Z + 'knockdownTicks' }),
    zp('dodge-convert-zero', (o) => { o.dodgeConvertTicks = 0; }, { rule: 'minimum', pointer: Z + 'dodgeConvertTicks' }),
    zp('dodge-convert-integer', (o) => { o.dodgeConvertTicks = 8.5; }, { rule: 'type', pointer: Z + 'dodgeConvertTicks' }),
    // mul, reel, stagger, counter
    zp('mul-key-required', (o) => { delete o.mul.held; }, { rule: 'required', pointer: Z + 'mul' }),
    zp('mul-zero', (o) => { o.mul.tech = 0; }, { rule: 'exclusiveMinimum', pointer: Z + 'mul/tech' }),
    zp('mul-negative', (o) => { o.mul.speed = -1; }, { rule: 'exclusiveMinimum', pointer: Z + 'mul/speed' }),
    zp('mul-type', (o) => { o.mul.held = 'big'; }, { rule: 'type', pointer: Z + 'mul/held' }),
    zp('mul-above-one-ok', (o) => { o.mul.tech = 2.5; }, null),
    zp('mul-unknown-key', (o) => { o.mul.heavy = 1; }, { rule: 'additionalProperties', pointer: Z + 'mul/heavy' }),
    zp('reel-key-required', (o) => { delete o.reel.speed; }, { rule: 'required', pointer: Z + 'reel' }),
    zp('reel-zero', (o) => { o.reel.tech = 0; }, { rule: 'minimum', pointer: Z + 'reel/tech' }),
    zp('reel-integer', (o) => { o.reel.held = 12.5; }, { rule: 'type', pointer: Z + 'reel/held' }),
    zp('stagger-key-required', (o) => { delete o.stagger.tech; }, { rule: 'required', pointer: Z + 'stagger' }),
    zp('stagger-zero', (o) => { o.stagger.speed = 0; }, { rule: 'minimum', pointer: Z + 'stagger/speed' }),
    zp('stagger-unknown-key', (o) => { o.stagger.held = 12; }, { rule: 'additionalProperties', pointer: Z + 'stagger/held' }),
    zp('counter-key-required', (o) => { delete o.counter.mul; }, { rule: 'required', pointer: Z + 'counter' }),
    zp('counter-tech-before-zero', (o) => { o.counter.techBefore = 0; }, { rule: 'minimum', pointer: Z + 'counter/techBefore' }),
    zp('counter-heavy-before-integer', (o) => { o.counter.heavyBefore = 6.5; }, { rule: 'type', pointer: Z + 'counter/heavyBefore' }),
    zp('counter-stagger-zero', (o) => { o.counter.staggerTicks = 0; }, { rule: 'minimum', pointer: Z + 'counter/staggerTicks' }),
    zp('counter-mul-zero', (o) => { o.counter.mul = 0; }, { rule: 'exclusiveMinimum', pointer: Z + 'counter/mul' }),
    // ai
    ai('valid', () => {}, null),
    ...AI_KEYS.flatMap((k) => [
      { id: 'director-ai-zip-' + k.toLowerCase() + '-required', schema: 'director-ai.schema.json', mutate: [{ file: AI, del: ['/levels/medium/' + k] }], expect: { rule: 'required', pointer: '/levels/medium' } },
      ai(k.toLowerCase() + '-negative', (o) => { o[k] = -0.1; }, { rule: 'minimum', pointer: '/levels/medium/' + k }),
      ai(k.toLowerCase() + '-above-one', (o) => { o[k] = 1.1; }, { rule: 'maximum', pointer: '/levels/medium/' + k }),
      ai(k.toLowerCase() + '-type', (o) => { o[k] = 'often'; }, { rule: 'type', pointer: '/levels/medium/' + k }),
      ai(k.toLowerCase() + '-edges-ok', (o) => { o[k] = 0; }, null),
      ai(k.toLowerCase() + '-one-ok', (o) => { o[k] = 1; }, null),
    ]),
    { id: 'director-ai-zip-easy-and-hard-required', schema: 'director-ai.schema.json', mutate: [{ file: AI, del: ['/levels/easy/zipShare', '/levels/hard/zipDodge'] }], expect: { rule: 'required', pointer: '/levels/easy' } },
  ];
  // the cases of a first version of this script that took the reach values as any number
  c.cases = c.cases.filter((y) => !/^director-interrupts-zip-(strike|heavy)-reach-fraction-ok$/.test(y.id));
  let n = 0;
  for (const k of add) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`zip schema applied (${n} new cases)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes('`zip-order`')) {
    const lines = t.split('\n');
    const i = lines.findIndex((l) => l.includes('`brawl-order`'));
    if (i < 0) throw new Error('zip README anchor');
    lines.splice(i + 1, 0,
      '| `zip-order` | data/director/interrupts.json zip: band.minBh is below maxBh; each inTicks runs low to high; exit.capBh is at most band.maxBh; towardDeg + awayDeg is at most 180 |',
      '| `zip-floor` | data/director/interrupts.json zip: floor.minTicks is at least 4 (Legal RL-076: a zip\'s way in and way out each last at least 4 ticks, so it is never a blink step) |');
    fs.writeFileSync(f, lines.join('\n'));
  }
}
