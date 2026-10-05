// Schema keys for Combat's brawl recipes (docs/combat/pending/recipes.brawl.json, which becomes data/combat/recipes.json with Encounter's
// slice B2). NOT run by CI, the validator or the sim. Run once from the repo root, in the commit where that file lands as
// data/combat/recipes.json (drop _target and _changes); apply-recipes.cjs and apply-pieces.cjs are applied already:
//     node docs/tools/pending/apply-brawl-recipes.cjs
// It does NOT edit data/. It changes tools/schemas/combat-recipes.schema.json:
//   pieces[id].path (required: line, arc_in, arc_out, rise, drop or spin) and pieces[id].sends (optional list of across, up, down, turned)
//   beat (optional): {default, line, arc_in, arc_out, rise, drop, spin}, each an integer 20 to 28 (any of them)
//   brawl (optional): any of light, lightToward, flurry, skill, juggle, heavy, lift, break, ender, each a pool name
// and adds the rule recipes-brawl: every pool `brawl` names exists for every fighter; every piece of a fighter's power.last has `sends`;
// when `beat` is there, it has a value for every path a piece uses or a default. The validator fixture becomes the whole new file, and the
// cases are added (the earlier whole-row `pieces` cases are patched to carry a path). Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const PATHS = ['line', 'arc_in', 'arc_out', 'rise', 'drop', 'spin'];
const SENDS = ['across', 'up', 'down', 'turned'];
const KINDS = ['light', 'lightToward', 'flurry', 'skill', 'juggle', 'heavy', 'lift', 'break', 'ender'];
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
  ];
  if (last) {
    add.push(x('power-last-without-sends', { del: [`/pieces/${last}/sends`] }, { rule: 'xref:recipes-brawl', pointer: `/pieces/${last}` }));
  }
  let n = 0;
  for (const k of add) if (!c.cases.some((y) => y.id === k.id)) { c.cases.push(k); n++; }
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
