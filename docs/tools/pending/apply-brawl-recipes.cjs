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
//   fallback (optional): {steps, lower, onTheTier}: what a press throws when its pool has nothing it may throw; onTheTier (per fighter: heavies, heavy, mashedB, launcher, bySend) says how
//     often each step is reached with B on the heavy tier (it replaces heavyOnStandIns)
//   launcher (optional): {aim, noStick, bySend, bySendLower}: a tap of B in an opening, picked by where it sends
//   reach (optional): {rule, run, pieces, runs, after}: energy in reach, the point-blank bolt and blast and the runs a mash keeps to
//   (brought up to docs/combat/pending/nine-cells.md section 5 on 2026-10-12: the brawl kinds launcher, reversal, bolt, blast, burstFast, burstMid, burstSlow and burstFloor)
// and adds the rule recipes-brawl: every pool `brawl` names exists for every fighter; every piece of a fighter's power.last has `sends`;
// when `beat` is there, it has a value for every path a piece uses or a default; and the rules recipes-burst (the burst's pools exist for every
// fighter, its slots have pools, close and samples are fighters' with pieces that exist and a blow for every slot) and recipes-fallback (lower names
// brawl kinds and pools every fighter has; onTheTier names fighters that exist), recipes-launcher (a fighter is a key of pools; every id is a row of pieces whose `sends` has that send; a bySend id is
// in his brawl.launcher, a bySendLower id in his brawl.launcher.lower) and recipes-reach (a fighter is a key of pools; every id is a row of pieces with that target and path and is in his reach.bolt or
// reach.blast; a run's blows are of his reach.bolt and `arms` is as long as `blows`; `after` has a list for each run and names runs that exist). The validator fixture becomes the whole new file, and the
// cases are added (the earlier whole-row `pieces` cases are patched to carry a path). Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const PATHS = ['line', 'arc_in', 'arc_out', 'rise', 'drop', 'spin'];
const SENDS = ['across', 'up', 'down', 'turned'];
const KINDS = ['light', 'lightToward', 'flurry', 'skill', 'juggle', 'medium', 'mediumHeld', 'reversal', 'heavy', 'heavyHeld', 'launcher', 'bolt', 'blast', 'burstFast', 'burstMid', 'burstSlow', 'burstFloor', 'lift'];
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
    const fighterKeys = { pattern: '^(_.*|[a-z][a-z0-9_]*)$' };
    const fighterMap = (item, description) => ({ type: 'object', minProperties: 1, propertyNames: fighterKeys, additionalProperties: item, patternProperties: { '^_': true }, description });
    const fallback = obj({
      steps: { type: 'array', minItems: 1, items: obj({ step: { enum: STEPS }, what: why }), description: 'The steps, tried in order.' },
      lower: { type: 'object', minProperties: 1, propertyNames: { enum: KINDS }, additionalProperties: poolName, description: 'A brawl kind to the pool one strength down, for the step `lower`.' },
      onTheTier: Object.assign(fighterMap(obj({
        heavies: { type: 'integer', minimum: 0, description: 'How many heavies the tier has.' },
        heavy: counts,
        mashedB: counts,
        launcher: counts,
        bySend: { type: 'object', minProperties: 1, propertyNames: { enum: SENDS }, additionalProperties: counts, description: 'A send to how often each step is reached when the stick asks for it.' },
      }), 'How often each step is reached with B on the heavy tier\'s posed pieces, by fighter (the count is made on the pieces table): heavy (a tapped or mashed B), mashedB (two heavies running), launcher and bySend.'), {}),
    }, { required: ['steps', 'lower'], description: 'What a press throws when its pool has nothing it may throw. No press is silent.' });
    const sendOf = { enum: SENDS };
    const sendMap = { type: 'object', minProperties: 1, propertyNames: { enum: SENDS }, additionalProperties: { type: 'array', minItems: 1, items: strikeId }, description: 'A send to the strikes that send that way.' };
    const launcher = obj({
      aim: obj({ up: sendOf, down: sendOf, toward: sendOf, away: sendOf }, { description: 'The stick\'s quarter to the send wanted.' }),
      noStick: { enum: ['planner'], description: 'With no stick the launch planner\'s pick decides the send.' },
      bySend: fighterMap(sendMap, 'A fighter to his tier\'s launcher pieces by where each sends (each in his brawl.launcher pool and with that send in its row\'s sends).'),
      bySendLower: fighterMap(sendMap, 'A fighter to his posed mediums by send, for the fallback step lower (each in his brawl.launcher.lower pool).'),
    }, { description: 'A tap of B on a staggered rival: it always lands and launches (docs/design/brawl-second-pass.md section 3); this is the blow that starts it, picked by where it sends.' });
    const piece = obj({ id: strikeId, set: poolName, hand: name, release: name, target: name, path: { enum: PATHS } }, { description: 'A bolt or a blast: the piece, its set, the energy hand, how it is let go, the place it is set on and its path in a string.' });
    const pieceList = { type: 'array', minItems: 1, items: piece };
    const reach = obj({
      rule: obj({ id: name, same: { type: 'array', minItems: 1, uniqueItems: true, items: { enum: ['hand', 'release'] } }, max: { type: 'integer', minimum: 1 } }, { description: 'Legal\'s e06: a piece counts by its hand and release, and a mash never throws the same twice running.' }),
      run: obj({
        samePlacePathArm: { type: 'integer', minimum: 1, description: 'Never the same arm, path and place twice running (the most in a row).' },
        pathsIn: { type: 'array', minItems: 2, maxItems: 2, items: { type: 'integer', minimum: 1 }, description: 'At least this many different paths in any this many bolts running: [paths, bolts].' },
        freeArm: obj({ atMostOneIn: { type: 'integer', minimum: 1 }, atLeastOneIn: { type: 'integer', minimum: 1 }, gapsDiffer: { type: 'boolean' } }, { description: 'The free arm takes a bolt now and then: at most one in this many, at least one in this many, and on no regular count.' }),
        notPeriodic: { type: 'array', minItems: 1, items: { type: 'integer', minimum: 2 }, description: 'The order never repeats on a fixed count of these.' },
        proof: { type: 'integer', minimum: 1, description: 'A run of this many bolts must exist for each fighter.' },
      }, { description: 'Legal\'s e09 for a mashed run, as numbers the director can order by.' }),
      pieces: fighterMap(obj({ bolt: pieceList, blast: pieceList }), 'A fighter to his bolt and blast pieces (each a row of pieces with that target and path, and in his reach.bolt or reach.blast pool).'),
      runs: fighterMap({ type: 'array', minItems: 1, items: obj({ blows: { type: 'array', minItems: 1, items: strikeId }, arms: { type: 'array', minItems: 1, items: { enum: ['lead', 'free'] } } }) }, 'A fighter to sample runs of twenty, each a loop (the blows are his reach.bolt pieces; arms is as long as blows).'),
      after: fighterMap({ type: 'array', minItems: 1, items: { type: 'array', minItems: 1, items: { type: 'integer', minimum: 0 } } }, 'A fighter to, for each run, the runs that may follow it.'),
    }, { description: 'Energy in reach (docs/design/brawl-second-pass.md section 5b): with RB held in a brawl, X is the point-blank bolt and Y the blast.' });
    const ordered = {};
    for (const k of Object.keys(s.properties)) { ordered[k] = s.properties[k]; if (k === 'brawl') { ordered.burst = burst; ordered.fallback = fallback; ordered.launcher = launcher; ordered.reach = reach; } }
    if (!ordered.burst) { ordered.burst = burst; ordered.fallback = fallback; ordered.launcher = launcher; ordered.reach = reach; }
    s.properties = ordered;
    changed = true;
  }
  if (changed) wj(f, s);
}

// =============================== fixture ===============================
{
  const f = 'tools/fixtures/virtual/data/combat/recipes.json';
  const o = rj(f);
  if (!o.beat || !o.brawl || !o.launcher || !o.reach || !(o.fallback && o.fallback.onTheTier)) {
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
      "      void stepNames;",
      "      if (isObj(fb.onTheTier)) for (const fid of Object.keys(fb.onTheTier)) {",
      "        if (fid.startsWith('_')) continue;",
      "        if (!fighters.includes(fid)) err(RC, `/fallback/onTheTier/${esc(fid)}`, 'recipes-fallback', `onTheTier names fighter \"${fid}\", who is not a key of pools`);",
      "      }",
      "    }",
      "    // the launcher: a fighter's tier launchers, by send, are rows that send that way and are in his pools",
      "    if (isObj(rec.launcher)) {",
      "      const ln = rec.launcher;",
      "      for (const key of ['bySend', 'bySendLower']) {",
      "        if (!isObj(ln[key])) continue;",
      "        const poolKey = key === 'bySend' ? 'brawl.launcher' : 'brawl.launcher.lower';",
      "        for (const [fid, sends] of Object.entries(ln[key])) {",
      "          if (fid.startsWith('_') || !isObj(sends)) continue;",
      "          if (!fighters.includes(fid)) { err(RC, `/launcher/${key}/${esc(fid)}`, 'recipes-launcher', `${key} names fighter \"${fid}\", who is not a key of pools`); continue; }",
      "          const inPool = new Set((isObj(pools[fid]) && Array.isArray(pools[fid][poolKey]) ? pools[fid][poolKey] : []).filter(isObj).map((e) => e.id));",
      "          for (const [send, list] of Object.entries(sends)) {",
      "            if (!Array.isArray(list)) continue;",
      "            list.forEach((id, i) => {",
      "              if (typeof id !== 'string') return;",
      "              const at = `/launcher/${key}/${esc(fid)}/${esc(send)}/${i}`;",
      "              if (prow && !(id in prow)) err(RC, at, 'recipes-launcher', `piece \"${id}\" is not a row of pieces`);",
      "              else if (prow && isObj(prow[id]) && !(Array.isArray(prow[id].sends) && prow[id].sends.includes(send))) err(RC, at, 'recipes-launcher', `piece \"${id}\" does not send \"${send}\" (its sends: ${JSON.stringify(prow[id].sends || [])})`);",
      "              if (inPool.size && !inPool.has(id)) err(RC, at, 'recipes-launcher', `piece \"${id}\" is not in ${fid}'s pool ${poolKey}`);",
      "            });",
      "          }",
      "        }",
      "      }",
      "    }",
      "    // energy in reach: a fighter's bolts and blasts are rows with that target and path and are in his reach pools; his runs use his bolts; after has a list for each run",
      "    if (isObj(rec.reach)) {",
      "      const rc = rec.reach;",
      "      const bolts = {};",
      "      if (isObj(rc.pieces)) for (const [fid, row] of Object.entries(rc.pieces)) {",
      "        if (fid.startsWith('_') || !isObj(row)) continue;",
      "        if (!fighters.includes(fid)) { err(RC, `/reach/pieces/${esc(fid)}`, 'recipes-reach', `reach.pieces names fighter \"${fid}\", who is not a key of pools`); continue; }",
      "        for (const kind of ['bolt', 'blast']) {",
      "          const list = Array.isArray(row[kind]) ? row[kind] : [];",
      "          const poolKey = 'reach.' + kind;",
      "          const inPool = new Set((isObj(pools[fid]) && Array.isArray(pools[fid][poolKey]) ? pools[fid][poolKey] : []).filter(isObj).map((e) => e.id));",
      "          if (kind === 'bolt') bolts[fid] = new Set(list.filter(isObj).map((e) => e.id));",
      "          list.forEach((e, i) => {",
      "            if (!isObj(e) || typeof e.id !== 'string') return;",
      "            const at = `/reach/pieces/${esc(fid)}/${kind}/${i}`;",
      "            if (prow && !(e.id in prow)) err(RC, `${at}/id`, 'recipes-reach', `piece \"${e.id}\" is not a row of pieces`);",
      "            else if (prow && isObj(prow[e.id])) {",
      "              if (typeof e.target === 'string' && prow[e.id].target !== e.target) err(RC, `${at}/target`, 'recipes-reach', `target \"${e.target}\" is not the piece's own (${JSON.stringify(prow[e.id].target)})`);",
      "              if (typeof e.path === 'string' && prow[e.id].path !== e.path) err(RC, `${at}/path`, 'recipes-reach', `path \"${e.path}\" is not the piece's own (${JSON.stringify(prow[e.id].path)})`);",
      "            }",
      "            if (inPool.size && !inPool.has(e.id)) err(RC, `${at}/id`, 'recipes-reach', `piece \"${e.id}\" is not in ${fid}'s pool ${poolKey}`);",
      "          });",
      "        }",
      "      }",
      "      if (isObj(rc.runs)) for (const [fid, runs] of Object.entries(rc.runs)) {",
      "        if (fid.startsWith('_') || !Array.isArray(runs)) continue;",
      "        if (!fighters.includes(fid)) { err(RC, `/reach/runs/${esc(fid)}`, 'recipes-reach', `reach.runs names fighter \"${fid}\", who is not a key of pools`); continue; }",
      "        runs.forEach((r, i) => {",
      "          if (!isObj(r)) return;",
      "          if (Array.isArray(r.blows) && Array.isArray(r.arms) && r.blows.length !== r.arms.length) err(RC, `/reach/runs/${esc(fid)}/${i}/arms`, 'recipes-reach', `arms has ${r.arms.length} entries, but blows has ${r.blows.length}`);",
      "          if (Array.isArray(r.blows) && bolts[fid] && bolts[fid].size) r.blows.forEach((id, j) => { if (typeof id === 'string' && !bolts[fid].has(id)) err(RC, `/reach/runs/${esc(fid)}/${i}/blows/${j}`, 'recipes-reach', `\"${id}\" is not one of ${fid}'s reach.bolt pieces`); });",
      "        });",
      "      }",
      "      if (isObj(rc.after)) for (const [fid, lists] of Object.entries(rc.after)) {",
      "        if (fid.startsWith('_') || !Array.isArray(lists)) continue;",
      "        if (!fighters.includes(fid)) { err(RC, `/reach/after/${esc(fid)}`, 'recipes-reach', `reach.after names fighter \"${fid}\", who is not a key of pools`); continue; }",
      "        const n = isObj(rc.runs) && Array.isArray(rc.runs[fid]) ? rc.runs[fid].length : null;",
      "        if (n !== null && lists.length !== n) err(RC, `/reach/after/${esc(fid)}`, 'recipes-reach', `after has ${lists.length} lists, but ${fid} has ${n} runs`);",
      "        if (n !== null) lists.forEach((l, i) => { if (Array.isArray(l)) l.forEach((x, k) => { if (Number.isInteger(x) && x >= n) err(RC, `/reach/after/${esc(fid)}/${i}/${k}`, 'recipes-reach', `run ${x} does not exist (${fid} has ${n})`); }); });",
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
    fb('tier-fighter-unknown', (b) => { b.onTheTier.nobody = clone(b.onTheTier[f0]); }, { rule: 'xref:recipes-fallback', pointer: '/fallback/onTheTier/nobody' }),
    fb('tier-optional', (b) => { delete b.onTheTier; }, null),
    fb('tier-key-required-heavies', (b) => { delete b.onTheTier[f0].heavies; }, { rule: 'required', pointer: '/fallback/onTheTier/' + f0 }),
    fb('tier-key-required-bysend', (b) => { delete b.onTheTier[f0].bySend; }, { rule: 'required', pointer: '/fallback/onTheTier/' + f0 }),
    fb('tier-unknown-key', (b) => { b.onTheTier[f0].extra = 1; }, { rule: 'additionalProperties', pointer: '/fallback/onTheTier/' + f0 + '/extra' }),
    fb('tier-heavies-negative', (b) => { b.onTheTier[f0].heavies = -1; }, { rule: 'minimum', pointer: '/fallback/onTheTier/' + f0 + '/heavies' }),
    fb('tier-count-negative', (b) => { b.onTheTier[f0].heavy.pool = -1; }, { rule: 'minimum', pointer: '/fallback/onTheTier/' + f0 + '/heavy/pool' }),
    fb('tier-count-step-enum', (b) => { b.onTheTier[f0].mashedB.panic = 3; }, { rule: 'propertyNames', pointer: '/fallback/onTheTier/' + f0 + '/mashedB/panic' }),
    fb('tier-count-integer', (b) => { b.onTheTier[f0].launcher.pool = 1.5; }, { rule: 'type', pointer: '/fallback/onTheTier/' + f0 + '/launcher/pool' }),
    fb('tier-send-enum', (b) => { b.onTheTier[f0].bySend.sideways = { pool: 1 }; }, { rule: 'propertyNames', pointer: '/fallback/onTheTier/' + f0 + '/bySend/sideways' }),
    fb('tier-heavy-on-stand-ins-is-gone', (b) => { b.heavyOnStandIns = {}; }, { rule: 'additionalProperties', pointer: '/fallback/heavyOnStandIns' }),
  ];
  add.push(...burstCases);
  // the launcher block (each case sets its own whole block, taken from the fixture's today)
  const ln = (n, tweak, expect) => { const b = clone(fx.launcher); tweak(b); return { id: 'combat-recipes-launcher-' + n, schema: 'combat-recipes.schema.json', mutate: [{ file: R, set: { '/launcher': b } }], expect }; };
  const sendOf0 = Object.keys(fx.launcher.bySend[f0])[0];
  const lowerSend0 = Object.keys(fx.launcher.bySendLower[f0])[0];
  const poolOf = (fid, key) => new Set((fx.pools[fid][key] || []).map((e) => e.id));
  const notSending = Object.entries(fx.pieces).find(([id, row]) => id.startsWith('strike.') && row && !(Array.isArray(row.sends) && row.sends.includes(sendOf0)) && poolOf(f0, 'brawl.launcher').has(id));
  const notInPool = Object.keys(fx.pieces).find((id) => id.startsWith('strike.') && (fx.pieces[id].sends || []).includes(sendOf0) && !poolOf(f0, 'brawl.launcher').has(id));
  const launcherCases = [
    x('launcher-optional', { del: ['/launcher'] }, null),
    ln('valid', () => {}, null),
    ln('unknown-key', (b) => { b.extra = 1; }, { rule: 'additionalProperties', pointer: '/launcher/extra' }),
    ln('note-ok', (b) => { b._why = 'a note'; }, null),
    ln('key-required-aim', (b) => { delete b.aim; }, { rule: 'required', pointer: '/launcher' }),
    ln('key-required-nostick', (b) => { delete b.noStick; }, { rule: 'required', pointer: '/launcher' }),
    ln('key-required-bysend', (b) => { delete b.bySend; }, { rule: 'required', pointer: '/launcher' }),
    ln('key-required-bysendlower', (b) => { delete b.bySendLower; }, { rule: 'required', pointer: '/launcher' }),
    ln('aim-key-required', (b) => { delete b.aim.away; }, { rule: 'required', pointer: '/launcher/aim' }),
    ln('aim-unknown-key', (b) => { b.aim.sideways = 'up'; }, { rule: 'additionalProperties', pointer: '/launcher/aim/sideways' }),
    ln('aim-send-enum', (b) => { b.aim.up = 'sideways'; }, { rule: 'enum', pointer: '/launcher/aim/up' }),
    ln('nostick-enum', (b) => { b.noStick = 'random'; }, { rule: 'enum', pointer: '/launcher/noStick' }),
    ln('bysend-empty', (b) => { b.bySend = {}; }, { rule: 'minProperties', pointer: '/launcher/bySend' }),
    ln('bysend-fighter-unknown', (b) => { b.bySend.nobody = clone(b.bySend[f0]); }, { rule: 'xref:recipes-launcher', pointer: '/launcher/bySend/nobody' }),
    ln('bysend-send-enum', (b) => { b.bySend[f0].sideways = clone(b.bySend[f0][sendOf0]); }, { rule: 'propertyNames', pointer: '/launcher/bySend/' + f0 + '/sideways' }),
    ln('bysend-list-empty', (b) => { b.bySend[f0][sendOf0] = []; }, { rule: 'minItems', pointer: '/launcher/bySend/' + f0 + '/' + sendOf0 }),
    ln('bysend-id-shape', (b) => { b.bySend[f0][sendOf0][0] = 'ram'; }, { rule: 'pattern', pointer: '/launcher/bySend/' + f0 + '/' + sendOf0 + '/0' }),
    ln('bysend-piece-unknown', (b) => { b.bySend[f0][sendOf0][0] = 'strike.nowhere'; }, { rule: 'xref:recipes-launcher', pointer: '/launcher/bySend/' + f0 + '/' + sendOf0 + '/0' }),
    ln('bysendlower-piece-unknown', (b) => { b.bySendLower[f0][lowerSend0][0] = 'strike.nowhere'; }, { rule: 'xref:recipes-launcher', pointer: '/launcher/bySendLower/' + f0 + '/' + lowerSend0 + '/0' }),
  ];
  if (notSending) {
    launcherCases.push(ln('bysend-piece-does-not-send-that-way', (b) => { b.bySend[f0][sendOf0][0] = notSending[0]; }, { rule: 'xref:recipes-launcher', pointer: '/launcher/bySend/' + f0 + '/' + sendOf0 + '/0' }));
  }
  if (notInPool) {
    launcherCases.push(ln('bysend-piece-not-in-his-pool', (b) => { b.bySend[f0][sendOf0][0] = notInPool; }, { rule: 'xref:recipes-launcher', pointer: '/launcher/bySend/' + f0 + '/' + sendOf0 + '/0' }));
  }
  // the reach block
  const rh = (n, tweak, expect) => { const b = clone(fx.reach); tweak(b); return { id: 'combat-recipes-reach-' + n, schema: 'combat-recipes.schema.json', mutate: [{ file: R, set: { '/reach': b } }], expect }; };
  const rb0 = fx.reach.pieces[f0].bolt[0];
  const otherPath = PATHS.find((p2) => p2 !== rb0.path);
  const otherTarget = rb0.target === 'chest' ? 'gut' : 'chest';
  const boltIds = fx.reach.pieces[f0].bolt.map((e) => e.id);
  const reachCases = [
    x('reach-optional', { del: ['/reach'] }, null),
    rh('valid', () => {}, null),
    rh('unknown-key', (b) => { b.extra = 1; }, { rule: 'additionalProperties', pointer: '/reach/extra' }),
    rh('note-ok', (b) => { b._why = 'a note'; }, null),
    rh('key-required-rule', (b) => { delete b.rule; }, { rule: 'required', pointer: '/reach' }),
    rh('key-required-run', (b) => { delete b.run; }, { rule: 'required', pointer: '/reach' }),
    rh('key-required-pieces', (b) => { delete b.pieces; }, { rule: 'required', pointer: '/reach' }),
    rh('key-required-runs', (b) => { delete b.runs; }, { rule: 'required', pointer: '/reach' }),
    rh('key-required-after', (b) => { delete b.after; }, { rule: 'required', pointer: '/reach' }),
    rh('rule-id-shape', (b) => { b.rule.id = 'E 6'; }, { rule: 'pattern', pointer: '/reach/rule/id' }),
    rh('rule-same-enum', (b) => { b.rule.same = ['colour']; }, { rule: 'enum', pointer: '/reach/rule/same/0' }),
    rh('rule-same-empty', (b) => { b.rule.same = []; }, { rule: 'minItems', pointer: '/reach/rule/same' }),
    rh('rule-max-zero', (b) => { b.rule.max = 0; }, { rule: 'minimum', pointer: '/reach/rule/max' }),
    rh('run-key-required', (b) => { delete b.run.proof; }, { rule: 'required', pointer: '/reach/run' }),
    rh('run-same-place-zero', (b) => { b.run.samePlacePathArm = 0; }, { rule: 'minimum', pointer: '/reach/run/samePlacePathArm' }),
    rh('run-paths-in-length', (b) => { b.run.pathsIn = [3]; }, { rule: 'minItems', pointer: '/reach/run/pathsIn' }),
    rh('run-paths-in-item', (b) => { b.run.pathsIn = [0, 5]; }, { rule: 'minimum', pointer: '/reach/run/pathsIn/0' }),
    rh('run-free-arm-key-required', (b) => { delete b.run.freeArm.gapsDiffer; }, { rule: 'required', pointer: '/reach/run/freeArm' }),
    rh('run-gaps-differ-type', (b) => { b.run.freeArm.gapsDiffer = 'yes'; }, { rule: 'type', pointer: '/reach/run/freeArm/gapsDiffer' }),
    rh('run-not-periodic-empty', (b) => { b.run.notPeriodic = []; }, { rule: 'minItems', pointer: '/reach/run/notPeriodic' }),
    rh('run-proof-zero', (b) => { b.run.proof = 0; }, { rule: 'minimum', pointer: '/reach/run/proof' }),
    rh('pieces-fighter-unknown', (b) => { b.pieces.nobody = clone(b.pieces[f0]); }, { rule: 'xref:recipes-reach', pointer: '/reach/pieces/nobody' }),
    rh('pieces-bolt-empty', (b) => { b.pieces[f0].bolt = []; }, { rule: 'minItems', pointer: '/reach/pieces/' + f0 + '/bolt' }),
    rh('piece-key-required', (b) => { delete b.pieces[f0].bolt[0].hand; }, { rule: 'required', pointer: '/reach/pieces/' + f0 + '/bolt/0' }),
    rh('piece-path-enum', (b) => { b.pieces[f0].bolt[0].path = 'zigzag'; }, { rule: 'enum', pointer: '/reach/pieces/' + f0 + '/bolt/0/path' }),
    rh('piece-unknown', (b) => { b.pieces[f0].bolt[0].id = 'strike.nowhere'; }, { rule: 'xref:recipes-reach', pointer: '/reach/pieces/' + f0 + '/bolt/0/id' }),
    rh('piece-target-differs', (b) => { b.pieces[f0].bolt[0].target = otherTarget; }, { rule: 'xref:recipes-reach', pointer: '/reach/pieces/' + f0 + '/bolt/0/target' }),
    rh('piece-path-differs', (b) => { b.pieces[f0].bolt[0].path = otherPath; }, { rule: 'xref:recipes-reach', pointer: '/reach/pieces/' + f0 + '/bolt/0/path' }),
    rh('run-blows-not-his-bolts', (b) => { b.runs[f0][0].blows[0] = fx.reach.pieces[f0].blast[0].id; }, { rule: 'xref:recipes-reach', pointer: '/reach/runs/' + f0 + '/0/blows/0' }),
    rh('run-arms-too-short', (b) => { b.runs[f0][0].arms.pop(); }, { rule: 'xref:recipes-reach', pointer: '/reach/runs/' + f0 + '/0/arms' }),
    rh('run-arms-enum', (b) => { b.runs[f0][0].arms[0] = 'left'; }, { rule: 'enum', pointer: '/reach/runs/' + f0 + '/0/arms/0' }),
    rh('run-fighter-unknown', (b) => { b.runs.nobody = clone(b.runs[f0]); }, { rule: 'xref:recipes-reach', pointer: '/reach/runs/nobody' }),
    rh('after-names-a-run-that-does-not-exist', (b) => { b.after[f0][0] = [b.runs[f0].length]; }, { rule: 'xref:recipes-reach', pointer: '/reach/after/' + f0 + '/0/0' }),
    rh('after-too-short', (b) => { b.after[f0].pop(); }, { rule: 'xref:recipes-reach', pointer: '/reach/after/' + f0 }),
    rh('after-negative', (b) => { b.after[f0][0] = [-1]; }, { rule: 'minimum', pointer: '/reach/after/' + f0 + '/0/0' }),
  ];
  void boltIds;
  add.push(...launcherCases, ...reachCases);
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
    t = t.replace(a, () => '`recipes-pieces`, `recipes-brawl`, `recipes-launcher`, `recipes-reach`, `recipes-blur`, `recipes-showcase` |');
    const line = t.split('\n').find((l) => l.includes('`recipes-brawl`'));
    t = t.replace(line, () => line.replace(/ \|$/, () => '; the pools `brawl` names exist for every fighter, every piece of a fighter\'s power.last has `sends`, and `beat` (when there) has a value for every piece path in use or a default; `recipes-launcher`: a launcher piece is a row whose `sends` has that send and is in the fighter\'s brawl.launcher (or .lower) pool; `recipes-reach`: a bolt or blast is a row with that target and path in his reach pool, a run\'s blows are his bolts, `arms` is as long as `blows` and `after` has a list for each run |'));
    fs.writeFileSync(f, t);
  }
}
