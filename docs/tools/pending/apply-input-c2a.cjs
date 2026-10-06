// Schema keys for Controls' C2a (docs/controls/windup-read.md section 5; Controls' own patches are docs/controls/c2a-schema.patch and
// c2a-tools.patch). NOT run by CI, the validator or the sim. Run once from the repo root, in Controls' commit (after Encounter's C2a):
//     node docs/tools/pending/apply-input-c2a.cjs
// It does NOT edit data/. In data/input/timing.json the `read` block:
//   gains burstStart (integer, at least 1; a range left generous, Game Design is ruling between 4, 8 and more), windupMedium, windupHeavy and
//   windupContext (integers, at least 1), windupGrace (integer, 0 to 20), pairWindow (integer, 0 to 6), pairFresh (integer, 0 or more),
//   flurryGapX, flurryGapY and flurryGapB (integers, at least 1), flurryNeedSlow (integer, at least 2), mixupSwitches (integer, at least 1),
//   simpleMediumStart and simpleHeavyStart (integers, at least 1);
//   loses holdLight, holdHeavy, holdSig, holdSigCharging and holdContext (naming one is an unknown key).
// Cross-references (xref-input.js, rule timing-read): simpleMediumStart at most simpleHeavyStart (this replaces the retired holdSig check);
// windupMedium below windupHeavy; pairWindow at most pairFresh; a wind-up plus the grace (the decision point) at most staleTicks, for the medium,
// the heavy and the context action; each flurry gap at most staleTicks (a longer gap could not continue a flurry the log has forgotten);
// flurryNeedSlow at most logSize; mixupSwitches below logSize (a chain of switches must fit in the log).
// The virtual timing.json fixture and the earlier hold* cases follow; the new cases set their own values. Re-runnable.
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const RETIRED = ['holdLight', 'holdHeavy', 'holdSig', 'holdSigCharging', 'holdContext'];
const VALUES = { burstStart: 8, windupMedium: 12, windupHeavy: 28, windupContext: 12, windupGrace: 4, pairWindow: 3, pairFresh: 8, flurryGapX: 12, flurryGapY: 16, flurryGapB: 34, flurryNeedSlow: 2, mixupSwitches: 2, simpleMediumStart: 12, simpleHeavyStart: 28 };
const int = (min, max, d) => Object.assign({ type: 'integer', minimum: min }, max !== undefined ? { maximum: max } : {}, { description: d });
const NEW = {
  burstStart: int(1, undefined, 'A light (X) held this many LIVE ticks starts the burst; the classifier\'s hold for X (8; Game Design is ruling between 4, 8 and more). Replaces holdLight.'),
  windupMedium: int(1, undefined, 'Y, the medium: a tap lands when this wind-up ends (12 live ticks); still down at wind-up plus grace it is the charged medium.'),
  windupHeavy: int(1, undefined, 'B, the heavy, in the martial stance: its wind-up (28).'),
  windupContext: int(1, undefined, 'A: the shove\'s wind-up (12); held to wind-up plus grace it is the tackle\'s coil.'),
  windupGrace: int(0, 20, 'A release in this many ticks after the wind-up\'s end is still a tap, on every device (4).'),
  pairWindow: int(0, 6, 'Two adjacent face buttons within this many ticks are one pair (3; doubled by the assist setting).'),
  pairFresh: int(0, undefined, '... and neither button was pressed in this many ticks before (8).'),
  flurryGapX: int(1, undefined, 'The pace of the X flurry: a press of the same button within this many ticks continues it (12).'),
  flurryGapY: int(1, undefined, 'The pace of the Y flurry (16).'),
  flurryGapB: int(1, undefined, 'The pace of the B flurry (34).'),
  flurryNeedSlow: int(2, undefined, 'Presses that make a Y or B flurry (2); X uses mashPresses.'),
  mixupSwitches: int(1, undefined, 'Changes of button in one chain of X, Y and B presses that make a mix-up (2).'),
  simpleMediumStart: int(1, undefined, 'The Simple layout\'s attack: held this many live ticks, the release is the medium (12).'),
  simpleHeavyStart: int(1, undefined, '... and held this many, the release is the heavy (28).'),
};

// =============================== schema ===============================
{
  const f = 'tools/schemas/input-timing.schema.json';
  const s = rj(f);
  const rd = s.properties.read;
  let changed = false;
  if (!rd.properties.burstStart) {
    const props = {};
    for (const [k, v] of Object.entries(rd.properties)) {
      if (RETIRED.includes(k)) { if (k === RETIRED[0]) Object.assign(props, NEW); continue; }
      props[k] = v;
    }
    if (!props.burstStart) Object.assign(props, NEW);
    rd.properties = props;
    changed = true;
  }
  for (const k of RETIRED) if (rd.properties[k]) { delete rd.properties[k]; changed = true; }
  if (rd.required) { rd.required = rd.required.filter((k) => !RETIRED.includes(k)); }
  if (changed) wj(f, s);
}

// =============================== fixture ===============================
{
  const f = 'tools/fixtures/virtual/data/input/timing.json';
  const o = rj(f);
  let changed = false;
  const read = {};
  for (const [k, v] of Object.entries(o.read)) {
    if (RETIRED.includes(k)) { changed = true; if (k === RETIRED[0]) for (const [nk, nv] of Object.entries(VALUES)) read[nk] = nv; continue; }
    read[k] = v;
  }
  for (const [nk, nv] of Object.entries(VALUES)) if (read[nk] === undefined) { read[nk] = nv; changed = true; }
  if (changed) { o.read = read; wj(f, o); }
}

// =============================== xref ===============================
{
  const f = 'tools/lib/xref-input.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes("'windupMedium'")) {
    const a = "    lt2('holdSig', 'holdSigCharging', '/read/holdSig',";
    const i = t.indexOf(a);
    if (i < 0) throw new Error('xref-input holdSig anchor');
    const j = t.indexOf('\n', i);
    const lines = [
      "    lt2('simpleMediumStart', 'simpleHeavyStart', '/read/simpleMediumStart', `simpleMediumStart ${rd.simpleMediumStart} is above simpleHeavyStart ${rd.simpleHeavyStart}: on the Simple layout the medium's hold cannot be longer than the heavy's`);",
      "    if (Number.isInteger(rd.windupMedium) && Number.isInteger(rd.windupHeavy) && rd.windupMedium >= rd.windupHeavy) err(TIMING, '/read/windupMedium', 'timing-read', `windupMedium ${rd.windupMedium} is not below windupHeavy ${rd.windupHeavy}: the heavy's wind-up is the longer`);",
      "    lt2('pairWindow', 'pairFresh', '/read/pairWindow', `pairWindow ${rd.pairWindow} is above pairFresh ${rd.pairFresh}: a pair would be wider than the freshness it asks of its two buttons`);",
      "    const grace = Number.isInteger(rd.windupGrace) ? rd.windupGrace : 0;",
      "    for (const k of ['windupMedium', 'windupHeavy', 'windupContext']) if (Number.isInteger(rd[k]) && Number.isInteger(rd.staleTicks) && rd[k] + grace > rd.staleTicks) err(TIMING, `/read/${k}`, 'timing-read', `${k} ${rd[k]} plus the grace ${grace} is the decision point, and it is later than staleTicks ${rd.staleTicks}: the log would have forgotten the press`);",
      "    for (const k of ['flurryGapX', 'flurryGapY', 'flurryGapB']) lt2(k, 'staleTicks', `/read/${k}`, `${k} ${rd[k]} is longer than staleTicks ${rd.staleTicks}: a flurry could not be continued after the log has forgotten it`);",
      "    lt2('flurryNeedSlow', 'logSize', '/read/flurryNeedSlow', `a flurry of ${rd.flurryNeedSlow} presses cannot be seen in a log of ${rd.logSize}`);",
      "    if (Number.isInteger(rd.mixupSwitches) && Number.isInteger(rd.logSize) && rd.mixupSwitches >= rd.logSize) err(TIMING, '/read/mixupSwitches', 'timing-read', `${rd.mixupSwitches} switches need more than ${rd.logSize} presses, and the log keeps ${rd.logSize}`);",
    ];
    t = t.slice(0, i) + lines.join('\n') + t.slice(j);
    fs.writeFileSync(f, t);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const T = 'data/input/timing.json';
  // the cases on the retired keys go; the new ones follow
  const gone = new Set(['input-timing-read-hold-light-zero', 'input-timing-read-hold-heavy-zero', 'input-timing-read-hold-sig-zero', 'input-timing-read-hold-sig-charging-zero', 'input-timing-read-hold-context-type', 'input-timing-read-hold-sig-above-charging', 'input-timing-read-hold-sig-equals-charging-ok']);
  c.cases = c.cases.filter((k) => !gone.has(k.id));
  const x = (n, set, expect) => ({ id: 'input-timing-read-' + n, schema: 'input-timing.schema.json', mutate: [{ file: T, set }], expect });
  const R = '/read/';
  const kebab = (k) => k.replace(/[A-Z]/g, (m) => '-' + m.toLowerCase());
  const add = [];
  for (const k of ['holdLight', 'holdHeavy', 'holdSig', 'holdSigCharging', 'holdContext']) add.push(x(kebab(k) + '-is-retired', { [R + k]: 8 }, { rule: 'additionalProperties', pointer: R + k }));
  add.push(x('new-values-ok', Object.fromEntries(Object.entries(VALUES).map(([k, v]) => [R + k, v])), null));
  // ranges, key by key
  for (const k of ['burstStart', 'windupMedium', 'windupHeavy', 'windupContext', 'flurryGapX', 'flurryGapY', 'flurryGapB', 'mixupSwitches', 'simpleMediumStart', 'simpleHeavyStart']) {
    add.push(
      x(kebab(k) + '-zero', { [R + k]: 0 }, { rule: 'minimum', pointer: R + k }),
      x(kebab(k) + '-integer', { [R + k]: 8.5 }, { rule: 'type', pointer: R + k }),
      x(kebab(k) + '-type', { [R + k]: 'long' }, { rule: 'type', pointer: R + k }),
      x(kebab(k) + '-one-ok', k === 'windupHeavy' ? { [R + 'windupMedium']: 1, [R + k]: 2 } : k === 'simpleHeavyStart' ? { [R + 'simpleMediumStart']: 1, [R + k]: 1 } : { [R + k]: 1 }, null),
    );
  }
  add.push(
    x('burst-start-four-ok', { [R + 'burstStart']: 4 }, null),
    x('burst-start-large-ok', { [R + 'burstStart']: 20 }, null),
    x('windup-grace-negative', { [R + 'windupGrace']: -1 }, { rule: 'minimum', pointer: R + 'windupGrace' }),
    x('windup-grace-above-twenty', { [R + 'windupGrace']: 21 }, { rule: 'maximum', pointer: R + 'windupGrace' }),
    x('windup-grace-integer', { [R + 'windupGrace']: 4.5 }, { rule: 'type', pointer: R + 'windupGrace' }),
    x('windup-grace-zero-ok', { [R + 'windupGrace']: 0 }, null),
    x('windup-grace-twenty-ok', { [R + 'windupGrace']: 20 }, null),
    x('pair-window-negative', { [R + 'pairWindow']: -1 }, { rule: 'minimum', pointer: R + 'pairWindow' }),
    x('pair-window-above-six', { [R + 'pairWindow']: 7 }, { rule: 'maximum', pointer: R + 'pairWindow' }),
    x('pair-window-type', { [R + 'pairWindow']: 'long' }, { rule: 'type', pointer: R + 'pairWindow' }),
    x('pair-window-zero-ok', { [R + 'pairWindow']: 0, [R + 'pairFresh']: 0 }, null),
    x('pair-fresh-negative', { [R + 'pairFresh']: -1 }, { rule: 'minimum', pointer: R + 'pairFresh' }),
    x('pair-fresh-type', { [R + 'pairFresh']: 'long' }, { rule: 'type', pointer: R + 'pairFresh' }),
    x('flurry-need-slow-one', { [R + 'flurryNeedSlow']: 1 }, { rule: 'minimum', pointer: R + 'flurryNeedSlow' }),
    x('flurry-need-slow-integer', { [R + 'flurryNeedSlow']: 2.5 }, { rule: 'type', pointer: R + 'flurryNeedSlow' }),
    x('flurry-need-slow-two-ok', { [R + 'flurryNeedSlow']: 2 }, null),
    // the cross-references
    x('simple-start-order', { [R + 'simpleMediumStart']: 30, [R + 'simpleHeavyStart']: 28 }, { rule: 'xref:timing-read', pointer: R + 'simpleMediumStart' }),
    x('simple-start-equal-ok', { [R + 'simpleMediumStart']: 28, [R + 'simpleHeavyStart']: 28 }, null),
    x('windup-medium-above-heavy', { [R + 'windupMedium']: 30, [R + 'windupHeavy']: 28 }, { rule: 'xref:timing-read', pointer: R + 'windupMedium' }),
    x('windup-medium-equals-heavy', { [R + 'windupMedium']: 28, [R + 'windupHeavy']: 28 }, { rule: 'xref:timing-read', pointer: R + 'windupMedium' }),
    x('windup-medium-just-below-heavy-ok', { [R + 'windupMedium']: 27, [R + 'windupHeavy']: 28 }, null),
    x('pair-window-above-fresh', { [R + 'pairWindow']: 6, [R + 'pairFresh']: 4 }, { rule: 'xref:timing-read', pointer: R + 'pairWindow' }),
    x('pair-window-equals-fresh-ok', { [R + 'pairWindow']: 4, [R + 'pairFresh']: 4 }, null),
    x('heavy-decision-point-after-stale', { [R + 'windupHeavy']: 58, [R + 'windupGrace']: 4, [R + 'staleTicks']: 60 }, { rule: 'xref:timing-read', pointer: R + 'windupHeavy' }),
    x('heavy-decision-point-at-stale-ok', { [R + 'windupHeavy']: 56, [R + 'windupGrace']: 4, [R + 'staleTicks']: 60 }, null),
    x('medium-decision-point-after-stale', { [R + 'windupMedium']: 20, [R + 'windupHeavy']: 24, [R + 'windupGrace']: 4, [R + 'staleTicks']: 22 }, { rule: 'xref:timing-read', pointer: R + 'windupMedium' }),
    x('context-decision-point-after-stale', { [R + 'windupContext']: 58, [R + 'windupGrace']: 4, [R + 'staleTicks']: 60 }, { rule: 'xref:timing-read', pointer: R + 'windupContext' }),
    x('flurry-gap-x-above-stale', { [R + 'flurryGapX']: 61, [R + 'staleTicks']: 60 }, { rule: 'xref:timing-read', pointer: R + 'flurryGapX' }),
    x('flurry-gap-y-above-stale', { [R + 'flurryGapY']: 61, [R + 'staleTicks']: 60 }, { rule: 'xref:timing-read', pointer: R + 'flurryGapY' }),
    x('flurry-gap-b-above-stale', { [R + 'flurryGapB']: 61, [R + 'staleTicks']: 60 }, { rule: 'xref:timing-read', pointer: R + 'flurryGapB' }),
    x('flurry-gap-b-at-stale-ok', { [R + 'flurryGapB']: 60, [R + 'staleTicks']: 60 }, null),
    x('flurry-need-slow-above-log', { [R + 'flurryNeedSlow']: 6, [R + 'logSize']: 5 }, { rule: 'xref:timing-read', pointer: R + 'flurryNeedSlow' }),
    x('flurry-need-slow-equals-log-ok', { [R + 'flurryNeedSlow']: 5, [R + 'logSize']: 5 }, null),
    x('mixup-switches-equals-log', { [R + 'mixupSwitches']: 5, [R + 'logSize']: 5 }, { rule: 'xref:timing-read', pointer: R + 'mixupSwitches' }),
    x('mixup-switches-below-log-ok', { [R + 'mixupSwitches']: 4, [R + 'logSize']: 5 }, null),
  );
  let n = 0;
  for (const k of add) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`input C2a schema applied (${n} new cases)`);
}
