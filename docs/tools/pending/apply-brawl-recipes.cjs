// Schema keys for Combat's brawl recipes (docs/combat/pending/recipes.brawl.json, which becomes data/combat/recipes.json with Encounter's
// slice B2). NOT run by CI, the validator or the sim. Run once from the repo root, in the commit where that file lands as
// data/combat/recipes.json (drop _target and _changes); apply-recipes.cjs and apply-pieces.cjs are applied already:
//     node docs/tools/pending/apply-brawl-recipes.cjs
// It does NOT edit data/. It changes tools/schemas/combat-recipes.schema.json:
//   pieces[id].path (required: line, arc_in, arc_out, rise, drop or spin) and pieces[id].sends (optional list of across, up, down, turned)
//   beat (optional): {default, line, arc_in, arc_out, rise, drop, spin}, each an integer 20 to 28 (any of them)
//   brawl (optional): any of light, lightToward, flurry, skill, juggle, medium, mediumHeld, heavy, heavyHeld, lift, each a pool name (a pool name
//     may have three parts: brawl.medium.held). THREE STRENGTHS (docs/design/brawl-second-pass.md; docs/combat/pending/movegen/three-strengths.md
//     sections 7 and 9): `ender` and `break` are gone (a key that names them is an unknown key).
//   burst (optional): {slots, pools {fast, mid, slow}, rules, close, samples}: a held X
//   fallback (optional): {steps, lower, heavyOnStandIns}: what a press throws when its pool has nothing it may throw
// and adds the rule recipes-brawl: every pool `brawl` names exists for every fighter; every piece of a fighter's power.last has `sends`;
// when `beat` is there, it has a value for every path a piece uses or a default; and the rules recipes-burst (the burst's pools exist for every
// fighter, its slots have pools, close and samples are fighters' with pieces that exist and a blow for every slot) and recipes-fallback (lower names
// brawl kinds and pools every fighter has; heavyOnStandIns names fighters, pieces and steps that exist). The validator fixture becomes the whole new file, and the
// cases are added (the earlier whole-row `pieces` cases are patched to carry a path). Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const PATHS = ['line', 'arc_in', 'arc_out', 'rise', 'drop', 'spin'];
const SENDS = ['across', 'up', 'down', 'turned'];
const KINDS = ['light', 'lightToward', 'flurry', 'skill', 'juggle', 'medium', 'mediumHeld', 'heavy', 'heavyHeld', 'lift'];
const STEPS = ['pool', 'repeat', 'lower'];
const LEANS = ['toward', 'away', 'none', 'down', 'up'];
const CLASSES = ['open', 'fast', 'mid', 'slow'];
const name = { type: 'string', pattern: '^[a-z][a-z0-9_]*$' };
const why = { type: 'string', minLength: 1 };
const strikeId = { type: 'string', pattern: '^strike\\.[a-z0-9_]+$' };
const obj = (props, opts = {}) => Object.assign({ type: 'object', required: opts.required === undefined ? Object.keys(props) : opts.required, properties: props }, opts.description ? { description: opts.description } : {}, closed);
const clone = (o) => JSON.parse(JSON.stringify(o));
const poolName = { type: 'string', pattern: '^[a-z][a-z0-9_]*([.][a-z0-9_]+)*$' };

// =============================== schema ===============================
{
  const f = 'tools/schemas/combat-recipes.schema.json';
  const s = rj(f);
  const row = s.properties.pieces.additionalProperties;
  if (!row.properties.path) {
    row.properties.path = { enum: PATHS, description: 'The strike\'s path: line, arc_in, arc_out, rise, drop or spin. It picks the beat point (the `beat` block).' };
    row.properties.sends = { type: 'array', minItems: 1, uniqueItems: true, items: { enum: SENDS }, description: 'Where the piece can send the rival (across, up, down or turned), for the heavies.' };
    if (!row.required.includes('path')) row.required.push('path');
    wj(f, s);
  }
}
{
  const f = 'tools/schemas/combat-recipes.schema.json';
  const s = rj(f);
  if (!s.properties.beat) {
    const props = {};
    for (const k of Object.keys(s.properties)) {
      props[k] = s.properties[k];
      if (k === 'pieces') {
        const beatInt = { type: 'integer', minimum: 20, maximum: 28 };
        props.beat = Object.assign({
          type: 'object',
          description: 'Optional. The beat point of a light or a skill strike: ticks after its contact at which the next press is on the beat, by the piece\'s path (20 to 28); `default` serves a piece with no path.',
          properties: Object.fromEntries(['default', ...PATHS].map((k2) => [k2, beatInt])),
        }, closed);
        props.brawl = Object.assign({
          type: 'object',
          description: 'Optional. Which pool each kind of press in the martial arts stance draws on (a pool name every fighter has).',
          properties: Object.fromEntries(KINDS.map((k2) => [k2, poolName])),
        }, closed);
      }
    }
    // keep beat and brawl before pieces, as the data has them
    const ordered = {};
    for (const k of Object.keys(props)) { if (k === 'pieces') { ordered.beat = props.beat; ordered.brawl = props.brawl; } if (k !== 'beat' && k !== 'brawl') ordered[k] = props[k]; }
    s.properties = ordered;
    wj(f, s);
  }
}

// ---- schema: the three strengths (burst and fallback; the brawl's kinds follow KINDS) ----
{
  const f = 'tools/schemas/combat-recipes.schema.json';
  const s = rj(f);
  let changed = false;
  if (s.properties.brawl) {
    const bp = s.properties.brawl.properties;
    for (const k of KINDS) if (!bp[k]) { bp[k] = poolName; changed = true; }
    for (const k of ['break', 'ender']) if (bp[k]) { delete bp[k]; changed = true; }
  }
  if (!s.properties.burst) {
    const burst = obj({
      slots: { type: 'array', minItems: 1, items: { enum: CLASSES }, description: 'The class of each blow of a burst, in order: open (the light the press threw), then fast, mid or slow by the gap before it.' },
      pools: obj({ fast: poolName, mid: poolName, slow: poolName }, { description: 'The pool each class of gap draws on (a pool every fighter has).' }),
      rules: {
        type: 'array',
        minItems: 1,
        description: 'What keeps a short gap from reading as a stutter: judged on the pieces table.',
        items: obj({
          id: name,
          rule: why,
          same: { type: 'array', minItems: 1, uniqueItems: true, items: { enum: ['limb', 'path', 'target', 'tip'] }, description: 'The parts a run must not share more than `max` times.' },
          max: { type: 'integer', minimum: 1, description: 'At most this many in a row sharing the parts.' },
          once: { type: 'boolean', description: 'No piece twice in one burst.' },
        }, { required: ['id', 'rule'] }),
      },
      close: { type: 'object', minProperties: 1, propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' }, additionalProperties: { type: 'array', minItems: 1, uniqueItems: true, items: { enum: PATHS } }, patternProperties: { '^_': true }, description: 'A fighter to the paths his last blow may take.' },
      samples: {
        type: 'object',
        minProperties: 1,
        propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' },
        additionalProperties: { type: 'object', propertyNames: { enum: LEANS }, additionalProperties: { type: 'array', minItems: 1, items: strikeId }, description: 'A lean of the stick to one whole burst (a piece for each slot).' },
        patternProperties: { '^_': true },
        description: 'A fighter to one whole burst for each lean of the stick.',
      },
    }, { required: ['slots', 'pools', 'rules', 'close', 'samples'], description: 'A held X (docs/design/brawl-second-pass.md section 3): lights that slow on a curve.' });
    const counts = { type: 'object', propertyNames: { enum: STEPS }, additionalProperties: { type: 'integer', minimum: 0 }, description: 'How many times each step is reached.' };
    const fallback = obj({
      steps: { type: 'array', minItems: 1, items: obj({ step: { enum: STEPS }, what: why }), description: 'The steps, tried in order.' },
      lower: { type: 'object', minProperties: 1, propertyNames: { enum: KINDS }, additionalProperties: poolName, description: 'A brawl kind to the pool one strength down, for the step `lower`.' },
      heavyOnStandIns: {
        type: 'object',
        propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' },
        additionalProperties: obj({
          standIns: { type: 'integer', minimum: 0 },
          all: counts,
          mashedB: counts,
          runsDry: { type: 'array', items: obj({ after: { type: 'array', minItems: 1, items: strikeId }, then: { enum: STEPS } }) },
        }),
        patternProperties: { '^_': true },
        description: 'Why the block exists today: how often each step is reached with B on stand-ins, by fighter. It goes when the heavy tier is posed.',
      },
    }, { required: ['steps', 'lower'], description: 'What a press throws when its pool has nothing it may throw. No press is silent.' });
    const ordered = {};
    for (const k of Object.keys(s.properties)) { ordered[k] = s.properties[k]; if (k === 'brawl') { ordered.burst = burst; ordered.fallback = fallback; } }
    if (!ordered.burst) { ordered.burst = burst; ordered.fallback = fallback; }
    s.properties = ordered;
    changed = true;
  }
  if (changed) wj(f, s);
}

// =============================== fixture ===============================
{
  const f = 'tools/fixtures/virtual/data/combat/recipes.json';
  const o = rj(f);
  if (!o.beat || !o.brawl) {
    const live = fs.existsSync('data/combat/recipes.json') ? rj('data/combat/recipes.json') : null;
    const full = live && live.beat ? live : rj('docs/combat/pending/recipes.brawl.json');
    const out = {};
    for (const k of Object.keys(full)) if (!['_target', '_changes', '_status', '_counts'].includes(k)) out[k] = full[k];
    out._about = o._about || 'Validator fixture, not game data: Combat\'s alchemist recipes (docs/combat/alchemist-recipes.md section 5).';
    wj(f, out);
  }
}

// =============================== xref ===============================
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes("'recipes-brawl'")) {
    const anchor = "    // a blur pattern's steps [limb, target] are filled from the fighter's blur.base";
    if (!t.includes(anchor)) throw new Error('brawl anchor');
    t = t.replace(anchor, () => [
      "    // the brawl: its pools exist for every fighter, a power.last piece has sends, the beat covers every path in use",
      "    if (isObj(rec.brawl)) for (const [kind, pn] of Object.entries(rec.brawl)) {",
      "      if (kind.startsWith('_') || typeof pn !== 'string') continue;",
      "      for (const fid of fighters) if (isObj(pools[fid]) && !(pn in pools[fid])) err(RC, `/brawl/${esc(kind)}`, 'recipes-brawl', `brawl ${kind} draws on pool \"${pn}\", which fighter \"${fid}\" does not have`);",
      "    }",
      "    if (prow) {",
      "      const noSends = new Set();",
      "      for (const fid of fighters) {",
      "        const last = isObj(pools[fid]) ? pools[fid]['power.last'] : null;",
      "        if (Array.isArray(last)) for (const e of last) if (isObj(e) && typeof e.id === 'string' && isObj(prow[e.id]) && !(Array.isArray(prow[e.id].sends) && prow[e.id].sends.length) && !noSends.has(e.id)) { noSends.add(e.id); err(RC, `/pieces/${esc(e.id)}`, 'recipes-brawl', `\"${e.id}\" is in ${fid}'s power.last but has no sends`); }",
      "      }",
      "      if (isObj(rec.beat) && typeof rec.beat.default !== 'number') {",
      "        const usedPaths = new Set();",
      "        for (const [id, row] of Object.entries(prow)) if (!id.startsWith('_') && isObj(row) && typeof row.path === 'string') usedPaths.add(row.path);",
      "        for (const p of usedPaths) if (!(p in rec.beat)) err(RC, '/beat', 'recipes-brawl', `a piece uses path \"${p}\", but beat has no value for it and no default`);",
      "      }",
      "    }",
      anchor,
    ].join('\n'));
    fs.writeFileSync(f, t);
  }
}

// ---- xref: the burst and the fallback ----
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes("'recipes-burst'")) {
    const anchor = "    // a blur pattern's steps [limb, target] are filled from the fighter's blur.base";
    if (!t.includes(anchor)) throw new Error('burst anchor');
    t = t.replace(anchor, () => [
      "    // the burst: its pools exist for every fighter, its slots have pools, close and samples are fighters' with pieces that exist",
      "    if (isObj(rec.burst)) {",
      "      const bu = rec.burst;",
      "      if (isObj(bu.pools)) for (const [cls, pn] of Object.entries(bu.pools)) {",
      "        if (cls.startsWith('_') || typeof pn !== 'string') continue;",
      "        for (const fid of fighters) if (isObj(pools[fid]) && !(pn in pools[fid])) err(RC, `/burst/pools/${esc(cls)}`, 'recipes-burst', `burst ${cls} draws on pool \"${pn}\", which fighter \"${fid}\" does not have`);",
      "      }",
      "      if (Array.isArray(bu.slots) && isObj(bu.pools)) bu.slots.forEach((c, i) => { if (c !== 'open' && !(c in bu.pools)) err(RC, `/burst/slots/${i}`, 'recipes-burst', `slot class \"${c}\" has no pool in burst.pools`); });",
      "      for (const key of ['close', 'samples']) if (isObj(bu[key])) for (const fid of Object.keys(bu[key])) if (!fid.startsWith('_') && !fighters.includes(fid)) err(RC, `/burst/${key}/${esc(fid)}`, 'recipes-burst', `burst ${key} names fighter \"${fid}\", who is not a key of pools`);",
      "      if (isObj(bu.samples)) for (const [fid, leans] of Object.entries(bu.samples)) {",
      "        if (fid.startsWith('_') || !isObj(leans)) continue;",
      "        for (const [lean, ids] of Object.entries(leans)) {",
      "          if (!Array.isArray(ids)) continue;",
      "          if (Array.isArray(bu.slots) && ids.length !== bu.slots.length) err(RC, `/burst/samples/${esc(fid)}/${esc(lean)}`, 'recipes-burst', `a sample has ${ids.length} blows, but burst.slots has ${bu.slots.length}`);",
      "          if (prow) ids.forEach((id, i) => { if (typeof id === 'string' && !(id in prow)) err(RC, `/burst/samples/${esc(fid)}/${esc(lean)}/${i}`, 'recipes-burst', `piece \"${id}\" is not a row of pieces`); });",
      "        }",
      "      }",
      "    }",
      "    // the fallback: lower names brawl kinds and pools every fighter has; the stand-in counts name fighters, pieces and steps that exist",
      "    if (isObj(rec.fallback)) {",
      "      const fb = rec.fallback;",
      "      const kinds = isObj(rec.brawl) ? Object.keys(rec.brawl).filter((k) => !k.startsWith('_')) : [];",
      "      if (isObj(fb.lower)) for (const [kind, pn] of Object.entries(fb.lower)) {",
      "        if (kind.startsWith('_')) continue;",
      "        if (kinds.length && !kinds.includes(kind)) err(RC, `/fallback/lower/${esc(kind)}`, 'recipes-fallback', `lower names kind \"${kind}\", which brawl does not have`);",
      "        if (typeof pn === 'string') for (const fid of fighters) if (isObj(pools[fid]) && !(pn in pools[fid])) err(RC, `/fallback/lower/${esc(kind)}`, 'recipes-fallback', `lower ${kind} draws on pool \"${pn}\", which fighter \"${fid}\" does not have`);",
      "      }",
      "      const stepNames = Array.isArray(fb.steps) ? fb.steps.filter(isObj).map((s) => s.step) : [];",
      "      if (isObj(fb.heavyOnStandIns)) for (const [fid, row] of Object.entries(fb.heavyOnStandIns)) {",
      "        if (fid.startsWith('_') || !isObj(row)) continue;",
      "        if (!fighters.includes(fid)) err(RC, `/fallback/heavyOnStandIns/${esc(fid)}`, 'recipes-fallback', `heavyOnStandIns names fighter \"${fid}\", who is not a key of pools`);",
      "        if (Array.isArray(row.runsDry)) row.runsDry.forEach((r, i) => {",
      "          if (!isObj(r)) return;",
      "          if (prow && Array.isArray(r.after)) r.after.forEach((id, j) => { if (typeof id === 'string' && !(id in prow)) err(RC, `/fallback/heavyOnStandIns/${esc(fid)}/runsDry/${i}/after/${j}`, 'recipes-fallback', `piece \"${id}\" is not a row of pieces`); });",
      "          if (stepNames.length && typeof r.then === 'string' && !stepNames.includes(r.then)) err(RC, `/fallback/heavyOnStandIns/${esc(fid)}/runsDry/${i}/then`, 'recipes-fallback', `\"${r.then}\" is not one of the steps (${stepNames.join(', ')})`);",
      "        });",
      "      }",
      "    }",
      anchor,
    ].join('\n'));
    fs.writeFileSync(f, t);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const R = 'data/combat/recipes.json';
  const fx = rj('tools/fixtures/virtual/data/combat/recipes.json');
  // the earlier cases that build a whole `pieces` row need the required path
  for (const k of c.cases) {
    if (!k.id.startsWith('combat-recipes-')) continue;
    for (const m of k.mutate || []) for (const [ptr, v] of Object.entries(m.set || {})) {
      if (/^\/pieces\/[^/]+$/.test(ptr) && v && typeof v === 'object' && !Array.isArray(v) && v.path === undefined) v.path = 'line';
    }
  }
  const x = (n, mut, expect) => ({ id: 'combat-recipes-' + n, schema: 'combat-recipes.schema.json', mutate: [{ file: R, ...mut }], expect });
  const P = '/pieces/strike.jab/';
  const lastIds = Object.values(fx.pools).flatMap((fp) => (fp['power.last'] || []).map((e) => e.id));
  const last = lastIds[0];
  const add = [
    x('pieces-path-required', { del: [P + 'path'] }, { rule: 'required', pointer: '/pieces/strike.jab' }),
    x('pieces-path-enum', { set: { [P + 'path']: 'zigzag' } }, { rule: 'enum', pointer: P + 'path' }),
    x('pieces-path-each-ok', { set: { [P + 'path']: 'spin' } }, null),
    x('pieces-sends-ok', { set: { [P + 'sends']: ['across', 'up'] } }, null),
    x('pieces-sends-enum', { set: { [P + 'sends']: ['sideways'] } }, { rule: 'enum', pointer: P + 'sends/0' }),
    x('pieces-sends-empty', { set: { [P + 'sends']: [] } }, { rule: 'minItems', pointer: P + 'sends' }),
    x('pieces-sends-duplicate', { set: { [P + 'sends']: ['across', 'across'] } }, { rule: 'uniqueItems', pointer: P + 'sends/1' }),
    x('pieces-sends-type', { set: { [P + 'sends']: 'across' } }, { rule: 'type', pointer: P + 'sends' }),
    x('beat-optional', { del: ['/beat'] }, null),
    x('beat-unknown-key', { set: { '/beat/zigzag': 24 } }, { rule: 'additionalProperties', pointer: '/beat/zigzag' }),
    x('beat-note-ok', { set: { '/beat/_note': 'comment' } }, null),
    x('beat-too-short', { set: { '/beat/line': 19 } }, { rule: 'minimum', pointer: '/beat/line' }),
    x('beat-too-long', { set: { '/beat/spin': 29 } }, { rule: 'maximum', pointer: '/beat/spin' }),
    x('beat-integer', { set: { '/beat/rise': 24.5 } }, { rule: 'type', pointer: '/beat/rise' }),
    x('beat-edges-ok', { set: { '/beat/line': 20, '/beat/spin': 28 } }, null),
    x('beat-default-range', { set: { '/beat/default': 40 } }, { rule: 'maximum', pointer: '/beat/default' }),
    x('beat-covers-without-default-ok', { del: ['/beat/default'] }, null),
    x('beat-path-missing-with-default-ok', { del: ['/beat/spin'] }, null),
    x('beat-path-uncovered', { del: ['/beat/default', '/beat/spin'] }, { rule: 'xref:recipes-brawl', pointer: '/beat' }),
    x('brawl-optional', { del: ['/brawl'] }, null),
    x('brawl-unknown-key', { set: { '/brawl/dance': 'combo.link' } }, { rule: 'additionalProperties', pointer: '/brawl/dance' }),
    x('brawl-note-ok', { set: { '/brawl/_note': 'comment' } }, null),
    x('brawl-pool-shape', { set: { '/brawl/flurry': 'Brawl Flurry' } }, { rule: 'pattern', pointer: '/brawl/flurry' }),
    x('brawl-pool-type', { set: { '/brawl/flurry': 3 } }, { rule: 'type', pointer: '/brawl/flurry' }),
    x('brawl-pool-missing', { set: { '/brawl/flurry': 'brawl.nowhere' } }, { rule: 'xref:recipes-brawl', pointer: '/brawl/flurry' }),
    x('brawl-pool-missing-for-one-fighter', { del: ['/pools/protagonist/brawl.lift'] }, { rule: 'xref:recipes-brawl', pointer: '/brawl/lift' }),
    x('brawl-live-pool-ok', { set: { '/brawl/light': 'blur.ender' } }, null),
    x('brawl-ender-is-gone', { set: { '/brawl/ender': 'blur.ender' } }, { rule: 'additionalProperties', pointer: '/brawl/ender' }),
    x('brawl-break-is-gone', { set: { '/brawl/break': 'blur.ender' } }, { rule: 'additionalProperties', pointer: '/brawl/break' }),
    x('brawl-medium-ok', { set: { '/brawl/medium': 'brawl.medium', '/brawl/mediumHeld': 'brawl.medium.held', '/brawl/heavyHeld': 'brawl.heavy' } }, null),
    x('brawl-three-part-pool-shape', { set: { '/brawl/mediumHeld': 'brawl.medium.Held' } }, { rule: 'pattern', pointer: '/brawl/mediumHeld' }),
    x('brawl-medium-pool-missing', { set: { '/brawl/medium': 'brawl.nowhere' } }, { rule: 'xref:recipes-brawl', pointer: '/brawl/medium' }),
  ];
  if (last) {
    add.push(x('power-last-without-sends', { del: [`/pieces/${last}/sends`] }, { rule: 'xref:recipes-brawl', pointer: `/pieces/${last}` }));
  }
  // the three strengths: the burst and the fallback (each case sets its own whole block, taken from the fixture's today)
  const fighters = Object.keys(fx.pools);
  const f0 = fighters[0];
  const bu = (n, tweak, expect) => { const b = clone(fx.burst); tweak(b); return { id: 'combat-recipes-burst-' + n, schema: 'combat-recipes.schema.json', mutate: [{ file: R, set: { '/burst': b } }], expect }; };
  const fb = (n, tweak, expect) => { const b = clone(fx.fallback); tweak(b); return { id: 'combat-recipes-fallback-' + n, schema: 'combat-recipes.schema.json', mutate: [{ file: R, set: { '/fallback': b } }], expect }; };
  const lean0 = Object.keys(fx.burst.samples[f0])[0];
  const standRow = Object.entries(fx.fallback.heavyOnStandIns || {}).find(([k, v]) => !k.startsWith('_') && v && Array.isArray(v.runsDry) && v.runsDry.length);
  const burstCases = [
    x('burst-optional', { del: ['/burst'] }, null),
    bu('valid', () => {}, null),
    bu('unknown-key', (b) => { b.extra = 1; }, { rule: 'additionalProperties', pointer: '/burst/extra' }),
    bu('note-ok', (b) => { b._why = 'a note'; }, null),
    bu('key-required-slots', (b) => { delete b.slots; }, { rule: 'required', pointer: '/burst' }),
    bu('key-required-pools', (b) => { delete b.pools; }, { rule: 'required', pointer: '/burst' }),
    bu('key-required-rules', (b) => { delete b.rules; }, { rule: 'required', pointer: '/burst' }),
    bu('key-required-close', (b) => { delete b.close; }, { rule: 'required', pointer: '/burst' }),
    bu('key-required-samples', (b) => { delete b.samples; }, { rule: 'required', pointer: '/burst' }),
    bu('slots-empty', (b) => { b.slots = []; }, { rule: 'minItems', pointer: '/burst/slots' }),
    bu('slot-class-enum', (b) => { b.slots[1] = 'quick'; }, { rule: 'enum', pointer: '/burst/slots/1' }),
    bu('slot-class-without-a-pool', (b) => { delete b.pools.mid; b.slots = b.slots.map((s) => s); }, { rule: 'xref:recipes-burst', pointer: '/burst/slots/' + fx.burst.slots.indexOf('mid') }),
    bu('pools-key-required', (b) => { delete b.pools.slow; }, { rule: 'required', pointer: '/burst/pools' }),
    bu('pools-unknown-class', (b) => { b.pools.quick = 'burst.fast'; }, { rule: 'additionalProperties', pointer: '/burst/pools/quick' }),
    bu('pool-shape', (b) => { b.pools.fast = 'Burst Fast'; }, { rule: 'pattern', pointer: '/burst/pools/fast' }),
    bu('pool-missing', (b) => { b.pools.fast = 'burst.nowhere'; }, { rule: 'xref:recipes-burst', pointer: '/burst/pools/fast' }),
    bu('rules-empty', (b) => { b.rules = []; }, { rule: 'minItems', pointer: '/burst/rules' }),
    bu('rule-key-required', (b) => { delete b.rules[0].rule; }, { rule: 'required', pointer: '/burst/rules/0' }),
    bu('rule-id-shape', (b) => { b.rules[0].id = 'U 1'; }, { rule: 'pattern', pointer: '/burst/rules/0/id' }),
    bu('rule-unknown-key', (b) => { b.rules[0].extra = 1; }, { rule: 'additionalProperties', pointer: '/burst/rules/0/extra' }),
    bu('rule-same-enum', (b) => { b.rules[0].same = ['colour']; }, { rule: 'enum', pointer: '/burst/rules/0/same/0' }),
    bu('rule-same-empty', (b) => { b.rules[0].same = []; }, { rule: 'minItems', pointer: '/burst/rules/0/same' }),
    bu('rule-max-zero', (b) => { b.rules[0].max = 0; }, { rule: 'minimum', pointer: '/burst/rules/0/max' }),
    bu('rule-max-integer', (b) => { b.rules[0].max = 1.5; }, { rule: 'type', pointer: '/burst/rules/0/max' }),
    bu('rule-once-type', (b) => { b.rules[0].once = 'yes'; }, { rule: 'type', pointer: '/burst/rules/0/once' }),
    bu('rule-once-ok', (b) => { b.rules.push({ id: 'u9', once: true, rule: 'no piece twice' }); }, null),
    bu('close-unknown-fighter', (b) => { b.close.nobody = ['line']; }, { rule: 'xref:recipes-burst', pointer: '/burst/close/nobody' }),
    bu('close-empty', (b) => { b.close[f0] = []; }, { rule: 'minItems', pointer: '/burst/close/' + f0 }),
    bu('close-path-enum', (b) => { b.close[f0] = ['zigzag']; }, { rule: 'enum', pointer: '/burst/close/' + f0 + '/0' }),
    bu('samples-unknown-fighter', (b) => { b.samples.nobody = clone(b.samples[f0]); }, { rule: 'xref:recipes-burst', pointer: '/burst/samples/nobody' }),
    bu('samples-lean-enum', (b) => { b.samples[f0].sideways = clone(b.samples[f0][lean0]); }, { rule: 'propertyNames', pointer: '/burst/samples/' + f0 + '/sideways' }),
    bu('sample-id-shape', (b) => { b.samples[f0][lean0][0] = 'jab'; }, { rule: 'pattern', pointer: '/burst/samples/' + f0 + '/' + lean0 + '/0' }),
    bu('sample-piece-unknown', (b) => { b.samples[f0][lean0][0] = 'strike.nowhere'; }, { rule: 'xref:recipes-burst', pointer: '/burst/samples/' + f0 + '/' + lean0 + '/0' }),
    bu('sample-too-short', (b) => { b.samples[f0][lean0].pop(); }, { rule: 'xref:recipes-burst', pointer: '/burst/samples/' + f0 + '/' + lean0 }),
    fb('valid', () => {}, null),
    x('fallback-optional', { del: ['/fallback'] }, null),
    fb('unknown-key', (b) => { b.extra = 1; }, { rule: 'additionalProperties', pointer: '/fallback/extra' }),
    fb('note-ok', (b) => { b._why = 'a note'; }, null),
    fb('key-required-steps', (b) => { delete b.steps; }, { rule: 'required', pointer: '/fallback' }),
    fb('key-required-lower', (b) => { delete b.lower; }, { rule: 'required', pointer: '/fallback' }),
    fb('steps-empty', (b) => { b.steps = []; }, { rule: 'minItems', pointer: '/fallback/steps' }),
    fb('step-enum', (b) => { b.steps[0].step = 'give_up'; }, { rule: 'enum', pointer: '/fallback/steps/0/step' }),
    fb('step-key-required', (b) => { delete b.steps[0].what; }, { rule: 'required', pointer: '/fallback/steps/0' }),
    fb('step-unknown-key', (b) => { b.steps[0].extra = 1; }, { rule: 'additionalProperties', pointer: '/fallback/steps/0/extra' }),
    fb('lower-empty', (b) => { b.lower = {}; }, { rule: 'minProperties', pointer: '/fallback/lower' }),
    fb('lower-kind-enum', (b) => { b.lower.dance = 'combo.link'; }, { rule: 'propertyNames', pointer: '/fallback/lower/dance' }),
    fb('lower-pool-shape', (b) => { b.lower.medium = 'Combo Link'; }, { rule: 'pattern', pointer: '/fallback/lower/medium' }),
    fb('lower-pool-missing', (b) => { b.lower.medium = 'combo.nowhere'; }, { rule: 'xref:recipes-fallback', pointer: '/fallback/lower/medium' }),
    fb('stand-in-fighter-unknown', (b) => { b.heavyOnStandIns.nobody = clone(b.heavyOnStandIns[f0]); }, { rule: 'xref:recipes-fallback', pointer: '/fallback/heavyOnStandIns/nobody' }),
    fb('stand-in-count-negative', (b) => { b.heavyOnStandIns[f0].standIns = -1; }, { rule: 'minimum', pointer: '/fallback/heavyOnStandIns/' + f0 + '/standIns' }),
    fb('stand-in-count-step-enum', (b) => { b.heavyOnStandIns[f0].all.panic = 3; }, { rule: 'propertyNames', pointer: '/fallback/heavyOnStandIns/' + f0 + '/all/panic' }),
    fb('stand-in-count-integer', (b) => { b.heavyOnStandIns[f0].all.pool = 1.5; }, { rule: 'type', pointer: '/fallback/heavyOnStandIns/' + f0 + '/all/pool' }),
  ];
  if (standRow) {
    const [sf] = standRow;
    burstCases.push(
      fb('runs-dry-piece-unknown', (b) => { b.heavyOnStandIns[sf].runsDry[0].after[0] = 'strike.nowhere'; }, { rule: 'xref:recipes-fallback', pointer: '/fallback/heavyOnStandIns/' + sf + '/runsDry/0/after/0' }),
      fb('runs-dry-then-not-a-step', (b) => { b.heavyOnStandIns[sf].runsDry[0].then = 'give_up'; }, { rule: 'enum', pointer: '/fallback/heavyOnStandIns/' + sf + '/runsDry/0/then' }),
      fb('runs-dry-then-a-step-the-list-lacks', (b) => { b.steps = b.steps.filter((s) => s.step !== 'lower'); b.heavyOnStandIns[sf].runsDry[0].then = 'lower'; }, { rule: 'xref:recipes-fallback', pointer: '/fallback/heavyOnStandIns/' + sf + '/runsDry/0/then' }),
    );
  }
  add.push(...burstCases);
  let n = 0;
  for (const k of add) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`brawl recipes schema applied (${n} new cases)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes('recipes-brawl')) {
    const a = '`recipes-pieces`, `recipes-blur`, `recipes-showcase` |';
    if (!t.includes(a)) throw new Error('brawl README anchor');
    t = t.replace(a, () => '`recipes-pieces`, `recipes-brawl`, `recipes-blur`, `recipes-showcase` |');
    const line = t.split('\n').find((l) => l.includes('`recipes-brawl`'));
    t = t.replace(line, () => line.replace(/ \|$/, () => '; the pools `brawl` names exist for every fighter, every piece of a fighter\'s power.last has `sends`, and `beat` (when there) has a value for every piece path in use or a default |'));
    fs.writeFileSync(f, t);
  }
}
