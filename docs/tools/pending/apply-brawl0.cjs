// Schema keys for Encounter's slice B0, the brawl groundwork (docs/director/brawl-plan.md). NOT run by CI, the validator or the sim.
// Run once from the repo root, in the commit that lands the slice's data:
//     node docs/tools/pending/apply-brawl0.cjs
// It does NOT edit data/. It adds:
//   data/director/interrupts.json  bands.lunge.windupTicks {light, heavy} (integers, 0 or more) and the required top-level `pace`
//                                  {cooldown {min, perSec, max}} (numbers, 0 or more; min at most max) (closed; _note allowed)
//   data/director/ai.json          the required top-level `stance` {repick [first, second], press {fresh, hurt, hurtBelow},
//                                  guard {hurt, fresh, hurtBelow}, evade, escape {hurt, hurtBelow, lowKi, lowKiBelow, rest},
//                                  circle {r, x, y, rate}, swayRate, evadeBackoff} (closed; _note allowed). Ranges (Encounter): weights 0 or
//                                  more; the three hurtBelow keys shares 0 to 1; escape.lowKiBelow ki 0 to 100; repick two numbers of
//                                  seconds above 0; circle r, x, y, rate, swayRate and evadeBackoff 0 or more
// the two fixtures' keys, the rules pace-order (cooldown.min at most max) and stance-repick (repick's first at most its second), and the
// cases (the earlier whole-bands cases are patched). data/combat/finishers.json contest.struggle.scoring.perStray changes value only.
// Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const obj = (props, opts = {}) => Object.assign({ type: 'object', required: opts.required === undefined ? Object.keys(props) : opts.required, properties: props }, opts.description ? { description: opts.description } : {}, closed);
const n0 = (d) => ({ type: 'number', minimum: 0, description: d });
const share = (d) => ({ type: 'number', minimum: 0, maximum: 1, description: d });
const clone = (o) => JSON.parse(JSON.stringify(o));
const strip = (o) => Object.fromEntries(Object.entries(o).filter(([k]) => !k.startsWith('_')).map(([k, v]) => [k, v && typeof v === 'object' && !Array.isArray(v) ? strip(v) : v]));

// placeholders for the fixtures until the live data carries the keys
const FX = {
  windupTicks: { light: 6, heavy: 12 },
  pace: { cooldown: { min: 4, perSec: 2, max: 12 } },
  stance: {
    repick: [1, 3],
    press: { fresh: 0.6, hurt: 0.3, hurtBelow: 0.4 },
    guard: { hurt: 0.5, fresh: 0.2, hurtBelow: 0.4 },
    evade: 0.2,
    escape: { hurt: 0.4, hurtBelow: 0.25, lowKi: 0.3, lowKiBelow: 20, rest: 0.1 },
    circle: { r: 120, x: 40, y: 10, rate: 1 },
    swayRate: 1,
    evadeBackoff: 30,
  },
};
const live = (f) => (fs.existsSync(f) ? rj(f) : null);
const liveIt = live('data/director/interrupts.json');
const liveAi = live('data/director/ai.json');
const haveIt = liveIt && liveIt.pace && liveIt.bands && liveIt.bands.lunge && liveIt.bands.lunge.windupTicks;
const haveAi = liveAi && liveAi.stance;

// =============================== interrupts schema ===============================
{
  const f = 'tools/schemas/director-interrupts.schema.json';
  const s = rj(f);
  const lunge = s.properties.bands.properties.lunge;
  if (!lunge.properties.windupTicks) {
    lunge.properties.windupTicks = obj({
      light: { type: 'integer', minimum: 0, description: 'Ticks of wind-up before a light lunge.' },
      heavy: { type: 'integer', minimum: 0, description: 'Ticks of wind-up before a heavy lunge.' },
    }, { description: 'The lunge\'s wind-up by the blow\'s weight.' });
    if (!lunge.required.includes('windupTicks')) lunge.required.push('windupTicks');
    s.properties.pace = obj({
      cooldown: obj({
        min: n0('The least a blow\'s cooldown can be, in ticks.'),
        perSec: n0('How much the cooldown grows for each blow in the last second.'),
        max: n0('The most a blow\'s cooldown can be, in ticks.'),
      }, { description: 'The cooldown between blows of a brawl.' }),
    }, { description: 'The brawl\'s pace (docs/director/brawl-plan.md).' });
    if (!s.required.includes('pace')) s.required.push('pace');
    wj(f, s);
  }
}

// =============================== ai schema ===============================
{
  const f = 'tools/schemas/director-ai.schema.json';
  const s = rj(f);
  if (!s.properties.stance) {
    s.properties.stance = obj({
      repick: { type: 'array', minItems: 2, maxItems: 2, items: { type: 'number', exclusiveMinimum: 0 }, description: 'The AI re-picks its stance between these two numbers of seconds (the first is at most the second).' },
      press: obj({ fresh: n0('The weight of the press stance when fresh.'), hurt: n0('The weight of the press stance when hurt.'), hurtBelow: share('Hurt means health below this share.') }),
      guard: obj({ hurt: n0('The weight of the guard stance when hurt.'), fresh: n0('The weight of the guard stance when fresh.'), hurtBelow: share('Hurt means health below this share.') }),
      evade: n0('The weight of the evade stance.'),
      escape: obj({ hurt: n0('The weight of the escape stance when hurt.'), hurtBelow: share('Hurt means health below this share.'), lowKi: n0('The weight of the escape stance when low on ki.'), lowKiBelow: { type: 'number', minimum: 0, maximum: 100, description: 'Low on ki means ki below this (0 to 100).' }, rest: n0('The weight of the escape stance otherwise.') }),
      circle: obj({ r: n0('The circling radius.'), x: n0('The circle\'s horizontal extent, in units.'), y: n0('The circle\'s vertical extent, in units.'), rate: n0('How fast it circles, in radians a second.') }),
      swayRate: n0('How fast it sways, in radians a second.'),
      evadeBackoff: n0('How far an evade backs off, in units.'),
    }, { description: 'The AI\'s stance choice (docs/director/brawl-plan.md section 3).' });
    if (!s.required.includes('stance')) s.required.push('stance');
    wj(f, s);
  }
}

// =============================== fixtures ===============================
{
  const dir = 'tools/fixtures/virtual/data/director/';
  {
    const f = dir + 'interrupts.json';
    const o = rj(f);
    if (o.bands && o.bands.lunge && o.bands.lunge.windupTicks === undefined) {
      o.bands.lunge.windupTicks = haveIt ? strip(liveIt.bands.lunge.windupTicks) : clone(FX.windupTicks);
      wj(f, o);
    }
    if (o.pace === undefined) {
      const src = haveIt ? strip(liveIt.pace) : clone(FX.pace);
      const out = {};
      for (const k of Object.keys(o)) { out[k] = o[k]; if (k === 'bands') out.pace = src; }
      if (out.pace === undefined) out.pace = src;
      wj(f, out);
    }
  }
  {
    const f = dir + 'ai.json';
    const o = rj(f);
    if (o.stance === undefined) {
      o.stance = haveAi ? strip(liveAi.stance) : clone(FX.stance);
      wj(f, o);
    }
  }
}

// =============================== xref ===============================
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes("'pace-order'")) {
    const a = "    const bu = itr.buried;";
    if (!t.includes(a)) throw new Error('pace anchor');
    t = t.replace(a, () => [
      "    if (isObj(itr.pace) && isObj(itr.pace.cooldown) && typeof itr.pace.cooldown.min === 'number' && typeof itr.pace.cooldown.max === 'number' && itr.pace.cooldown.min > itr.pace.cooldown.max) err(IT, '/pace/cooldown/min', 'pace-order', `cooldown min ${itr.pace.cooldown.min} is above max ${itr.pace.cooldown.max}`);",
      a,
    ].join('\n'));
    const b = "    const med = isObj(lv.medium) ? lv.medium.beamAnswer : undefined;";
    if (!t.includes(b)) throw new Error('stance anchor');
    t = t.replace(b, () => [
      "    if (isObj(dai.stance) && Array.isArray(dai.stance.repick) && dai.stance.repick.length === 2 && typeof dai.stance.repick[0] === 'number' && typeof dai.stance.repick[1] === 'number' && dai.stance.repick[0] > dai.stance.repick[1]) err(AI, '/stance/repick/0', 'stance-repick', `repick runs from ${dai.stance.repick[0]} down to ${dai.stance.repick[1]}`);",
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
  // the earlier cases that build the whole bands block need the new lunge key
  for (const k of c.cases) {
    if (!/^director-interrupts-bands-/.test(k.id)) continue;
    for (const m of k.mutate || []) {
      const o = m.set && m.set['/bands'];
      if (o && typeof o === 'object' && o.lunge && typeof o.lunge === 'object' && o.lunge.windupTicks === undefined) o.lunge.windupTicks = { light: 6, heavy: 12 };
    }
  }
  const it = (n, mut, expect) => ({ id: 'director-interrupts-' + n, schema: 'director-interrupts.schema.json', mutate: [{ file: I, ...mut }], expect });
  const ai = (n, mut, expect) => ({ id: 'director-ai-' + n, schema: 'director-ai.schema.json', mutate: [{ file: A, ...mut }], expect });
  const W = '/bands/lunge/windupTicks';
  const C = '/pace/cooldown/';
  const S = '/stance/';
  const add = [
    it('bands-lunge-windup-required', { del: [W] }, { rule: 'required', pointer: '/bands/lunge' }),
    it('bands-lunge-windup-key-required', { del: [W + '/heavy'] }, { rule: 'required', pointer: W }),
    it('bands-lunge-windup-unknown-key', { set: { [W + '/medium']: 8 } }, { rule: 'additionalProperties', pointer: W + '/medium' }),
    it('bands-lunge-windup-negative', { set: { [W + '/light']: -1 } }, { rule: 'minimum', pointer: W + '/light' }),
    it('bands-lunge-windup-integer', { set: { [W + '/heavy']: 12.5 } }, { rule: 'type', pointer: W + '/heavy' }),
    it('bands-lunge-windup-zero-ok', { set: { [W + '/light']: 0, [W + '/heavy']: 0 } }, null),
    it('pace-required', { del: ['/pace'] }, { rule: 'required', pointer: '' }),
    it('pace-key-required', { set: { '/pace': {} } }, { rule: 'required', pointer: '/pace' }),
    it('pace-unknown-key', { set: { '/pace/extra': 1 } }, { rule: 'additionalProperties', pointer: '/pace/extra' }),
    it('pace-note-ok', { set: { '/pace/_note': 'comment' } }, null),
    it('pace-cooldown-key-required', { del: [C + 'perSec'] }, { rule: 'required', pointer: '/pace/cooldown' }),
    it('pace-cooldown-unknown-key', { set: { [C + 'extra']: 1 } }, { rule: 'additionalProperties', pointer: C + 'extra' }),
    it('pace-cooldown-min-negative', { set: { [C + 'min']: -1 } }, { rule: 'minimum', pointer: C + 'min' }),
    it('pace-cooldown-per-sec-negative', { set: { [C + 'perSec']: -1 } }, { rule: 'minimum', pointer: C + 'perSec' }),
    it('pace-cooldown-max-type', { set: { [C + 'max']: 'long' } }, { rule: 'type', pointer: C + 'max' }),
    it('pace-cooldown-min-above-max', { set: { [C + 'min']: 20, [C + 'max']: 10 } }, { rule: 'xref:pace-order', pointer: C + 'min' }),
    it('pace-cooldown-min-equals-max-ok', { set: { [C + 'min']: 8, [C + 'max']: 8 } }, null),
    it('pace-cooldown-fractions-ok', { set: { [C + 'min']: 0.25, [C + 'perSec']: 0.5, [C + 'max']: 0.75 } }, null),
    ai('stance-required', { del: ['/stance'] }, { rule: 'required', pointer: '' }),
    ai('stance-key-required', { del: [S + 'evade'] }, { rule: 'required', pointer: '/stance' }),
    ai('stance-unknown-key', { set: { [S + 'extra']: 1 } }, { rule: 'additionalProperties', pointer: S + 'extra' }),
    ai('stance-note-ok', { set: { [S + '_note']: 'comment' } }, null),
    ai('stance-repick-length', { set: { [S + 'repick']: [1] } }, { rule: 'minItems', pointer: S + 'repick' }),
    ai('stance-repick-too-long', { set: { [S + 'repick']: [1, 2, 3] } }, { rule: 'maxItems', pointer: S + 'repick' }),
    ai('stance-repick-zero', { set: { [S + 'repick']: [0, 3] } }, { rule: 'exclusiveMinimum', pointer: S + 'repick/0' }),
    ai('stance-repick-negative', { set: { [S + 'repick']: [-1, 3] } }, { rule: 'exclusiveMinimum', pointer: S + 'repick/0' }),
    ai('stance-repick-type', { set: { [S + 'repick']: [1, 'long'] } }, { rule: 'type', pointer: S + 'repick/1' }),
    ai('stance-repick-reversed', { set: { [S + 'repick']: [5, 2] } }, { rule: 'xref:stance-repick', pointer: S + 'repick/0' }),
    ai('stance-repick-equal-ok', { set: { [S + 'repick']: [2, 2] } }, null),
    ai('stance-press-key-required', { del: [S + 'press/hurtBelow'] }, { rule: 'required', pointer: S + 'press' }),
    ai('stance-press-unknown-key', { set: { [S + 'press/extra']: 1 } }, { rule: 'additionalProperties', pointer: S + 'press/extra' }),
    ai('stance-press-negative', { set: { [S + 'press/fresh']: -0.1 } }, { rule: 'minimum', pointer: S + 'press/fresh' }),
    ai('stance-press-weight-above-one-ok', { set: { [S + 'press/fresh']: 3 } }, null),
    ai('stance-press-hurt-below-range', { set: { [S + 'press/hurtBelow']: 1.5 } }, { rule: 'maximum', pointer: S + 'press/hurtBelow' }),
    ai('stance-press-hurt-below-negative', { set: { [S + 'press/hurtBelow']: -0.1 } }, { rule: 'minimum', pointer: S + 'press/hurtBelow' }),
    ai('stance-press-hurt-below-edges-ok', { set: { [S + 'press/hurtBelow']: 1 } }, null),
    ai('stance-guard-key-required', { del: [S + 'guard/fresh'] }, { rule: 'required', pointer: S + 'guard' }),
    ai('stance-guard-negative', { set: { [S + 'guard/hurt']: -0.1 } }, { rule: 'minimum', pointer: S + 'guard/hurt' }),
    ai('stance-guard-type', { set: { [S + 'guard/hurtBelow']: 'low' } }, { rule: 'type', pointer: S + 'guard/hurtBelow' }),
    ai('stance-guard-hurt-below-range', { set: { [S + 'guard/hurtBelow']: 1.5 } }, { rule: 'maximum', pointer: S + 'guard/hurtBelow' }),
    ai('stance-guard-weight-above-one-ok', { set: { [S + 'guard/fresh']: 2 } }, null),
    ai('stance-evade-negative', { set: { [S + 'evade']: -1 } }, { rule: 'minimum', pointer: S + 'evade' }),
    ai('stance-evade-type', { set: { [S + 'evade']: 'often' } }, { rule: 'type', pointer: S + 'evade' }),
    ai('stance-escape-key-required', { del: [S + 'escape/rest'] }, { rule: 'required', pointer: S + 'escape' }),
    ai('stance-escape-unknown-key', { set: { [S + 'escape/extra']: 1 } }, { rule: 'additionalProperties', pointer: S + 'escape/extra' }),
    ai('stance-escape-negative', { set: { [S + 'escape/lowKiBelow']: -5 } }, { rule: 'minimum', pointer: S + 'escape/lowKiBelow' }),
    ai('stance-escape-low-ki-below-range', { set: { [S + 'escape/lowKiBelow']: 150 } }, { rule: 'maximum', pointer: S + 'escape/lowKiBelow' }),
    ai('stance-escape-low-ki-below-edges-ok', { set: { [S + 'escape/lowKiBelow']: 100 } }, null),
    ai('stance-escape-hurt-below-range', { set: { [S + 'escape/hurtBelow']: 1.5 } }, { rule: 'maximum', pointer: S + 'escape/hurtBelow' }),
    ai('stance-escape-weight-negative', { set: { [S + 'escape/rest']: -0.1 } }, { rule: 'minimum', pointer: S + 'escape/rest' }),
    ai('stance-circle-key-required', { del: [S + 'circle/rate'] }, { rule: 'required', pointer: S + 'circle' }),
    ai('stance-circle-radius-negative', { set: { [S + 'circle/r']: -1 } }, { rule: 'minimum', pointer: S + 'circle/r' }),
    ai('stance-circle-x-negative', { set: { [S + 'circle/x']: -40 } }, { rule: 'minimum', pointer: S + 'circle/x' }),
    ai('stance-circle-y-negative', { set: { [S + 'circle/y']: -10 } }, { rule: 'minimum', pointer: S + 'circle/y' }),
    ai('stance-circle-rate-negative', { set: { [S + 'circle/rate']: -1 } }, { rule: 'minimum', pointer: S + 'circle/rate' }),
    ai('stance-circle-offset-type', { set: { [S + 'circle/y']: 'up' } }, { rule: 'type', pointer: S + 'circle/y' }),
    ai('stance-circle-zero-ok', { set: { [S + 'circle/x']: 0, [S + 'circle/y']: 0 } }, null),
    ai('stance-sway-negative', { set: { [S + 'swayRate']: -1 } }, { rule: 'minimum', pointer: S + 'swayRate' }),
    ai('stance-evade-backoff-negative', { set: { [S + 'evadeBackoff']: -1 } }, { rule: 'minimum', pointer: S + 'evadeBackoff' }),
    ai('stance-evade-backoff-type', { set: { [S + 'evadeBackoff']: 'far' } }, { rule: 'type', pointer: S + 'evadeBackoff' }),
  ];
  let n = 0;
  for (const k of add) if (!c.cases.some((y) => y.id === k.id)) { c.cases.push(k); n++; }
  wj(cf, c);
  console.log(`slice B0 schema applied (${n} new cases)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes('pace-order')) {
    const line = t.split('\n').find((l) => l.includes('`alchemy-flow`'));
    if (!line) throw new Error('B0 README anchor');
    t = t.replace(line, () => line + '\n| `pace-order`, `stance-repick` | data/director/interrupts.json pace: cooldown.min is at most max. data/director/ai.json stance: repick\'s first number is at most its second |');
    fs.writeFileSync(f, t);
  }
}
