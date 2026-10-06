// Schema keys for Animation's strength map and the hold of a style: data/anim/press_styles.json gains (1) a top-level `strength`: a strength word to a style name, keys
// light, medium, heavy, bolt and blast (all five), each value a style of `styles`; and (2) an optional `hold` object on a style row (today only `super` has it): from, to
// (ticks), squash (0 to 1) and lean_back (0 to 0.5). NOT run by CI, the validator or the sim. Run once from the repo root, in the commit that lands Animation's data (the
// map and super's hold in press_styles.json, the parked waves launch1 (prefix lq.) and miss1 (prefix mi.), and the changed sockets.json, fighters.json `more` and pair_live.json
// `shared`, which validate under the schemas that exist and need nothing more):
//     node docs/tools/pending/apply-anim-strength-hold.cjs
// It also adds the schema for data/anim/reach.json (anim-reach.schema.json, its map.json rule, rule reach-keyset and 18 cases; EP, 2026-10-06). It does NOT edit data/. Rules: pressstyles-strength (every value is a key of `styles`), pressstyles-hold (from is below to). Every case sets its own values (the style names it
// reads from the data of the day). Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const clone = (o) => JSON.parse(JSON.stringify(o));
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const WORDS = ['light', 'medium', 'heavy', 'bolt', 'blast'];

// =============================== schema ===============================
{
  const f = 'tools/schemas/anim-press-styles.schema.json';
  const s = rj(f);
  let changed = false;
  if (!s.properties.strength) {
    const STRENGTH = Object.assign({
      type: 'object',
      required: WORDS,
      description: 'Which style each strength word plays (light, medium, heavy, bolt, blast). Every value is a key of `styles` (rule pressstyles-strength).',
      properties: Object.fromEntries(WORDS.map((w) => [w, { type: 'string', pattern: '^[a-z][a-z0-9_]*$', description: `The style the ${w} strength plays.` }])),
    }, closed);
    const props = {};
    for (const [k, v] of Object.entries(s.properties)) {
      props[k] = v;
      if (k === 'read') props.strength = STRENGTH;
    }
    if (!props.strength) throw new Error('the press styles schema has no `read` property to put `strength` after');
    s.properties = props;
    changed = true;
  }
  const HOLD = Object.assign({
    type: 'object',
    required: ['from', 'to', 'squash', 'lean_back'],
    description: 'Optional. A style held through a stretch of its blow: the ticks it is held from and to (from below to: rule pressstyles-hold), how much of the squash it takes and how far the body leans back.',
    properties: {
      from: { type: 'integer', minimum: 0, maximum: 120, description: 'Tick at which the hold begins.' },
      to: { type: 'integer', minimum: 0, maximum: 120, description: 'Tick at which the hold ends (above from).' },
      squash: { type: 'number', minimum: 0, maximum: 1, description: 'How much of the squash pose the hold takes.' },
      lean_back: { type: 'number', minimum: 0, maximum: 0.5, description: 'How far the body leans back in the hold.' },
    },
  }, closed);
  for (const row of Object.values(s.properties.styles.properties || {})) {
    if (row && row.properties && !row.properties.hold) { row.properties.hold = clone(HOLD); changed = true; }
  }
  if (!/pressstyles-strength/.test(s.description)) { s.description = s.description.replace(/\. Cross-references \(/, () => '. Cross-references (every value of `strength` is a key of `styles` (pressstyles-strength); a style\'s `hold.from` is below its `hold.to` (pressstyles-hold); '); changed = true; }
  if (changed) wj(f, s);
}

// =============================== xref ===============================
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes("'pressstyles-strength'")) {
    const a = '    if (isObj(pst.riposte) && isObj(pst.riposte.style) && isObj(pst.styles)) {';
    if (!t.includes(a)) throw new Error('strength xref anchor');
    t = t.replace(a, () => [
      '    if (isObj(pst.strength) && isObj(pst.styles)) {',
      '      for (const [w, sty] of Object.entries(pst.strength)) {',
      "        if (w.startsWith('_') || typeof sty !== 'string') continue;",
      "        if (!(sty in pst.styles) || sty.startsWith('_')) err(PS, `/strength/${w}`, 'pressstyles-strength', `strength \"${w}\" plays style \"${sty}\", which is not a key of styles (${Object.keys(pst.styles).filter((k) => !k.startsWith('_')).join(', ')})`);",
      '      }',
      '    }',
      '    for (const [sid, st] of Object.entries(isObj(pst.styles) ? pst.styles : {})) {',
      "      if (sid.startsWith('_') || !isObj(st) || !isObj(st.hold)) continue;",
      "      if (typeof st.hold.from === 'number' && typeof st.hold.to === 'number' && st.hold.from >= st.hold.to) err(PS, `/styles/${esc(sid)}/hold/from`, 'pressstyles-hold', `hold from ${st.hold.from} must be below to ${st.hold.to}`);",
      '    }',
      a,
    ].join('\n'));
    fs.writeFileSync(f, t);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const P = 'data/anim/press_styles.json';
  const names = Object.keys(rj(P).styles).filter((k) => !k.startsWith('_'));
  const s0 = names[0], s1 = names[1] || names[0];
  const hostStyle = names.find((k) => k !== 'super') || s0;
  // ---- strength
  const SB = Object.fromEntries(WORDS.map((w) => [w, s0]));
  const sx = (n, tweak, expect) => { const o = clone(SB); tweak(o); return { id: 'anim-press-styles-strength-' + n, schema: 'anim-press-styles.schema.json', mutate: [{ file: P, set: { '/strength': o } }], expect }; };
  const SP = '/strength/';
  const strength = [
    sx('valid', () => {}, null),
    sx('another-style-ok', (o) => { o.heavy = s1; }, null),
    ...WORDS.map((w) => sx('key-required-' + w, (o) => { delete o[w]; }, { rule: 'required', pointer: '/strength' })),
    sx('unknown-key', (o) => { o.extra = s0; }, { rule: 'additionalProperties', pointer: SP + 'extra' }),
    sx('note-ok', (o) => { o._why = 'a note'; }, null),
    sx('not-an-object', () => {}, { rule: 'type', pointer: '/strength' }),
    sx('value-type', (o) => { o.light = 5; }, { rule: 'type', pointer: SP + 'light' }),
    sx('value-shape', (o) => { o.light = 'Speed Style'; }, { rule: 'pattern', pointer: SP + 'light' }),
    sx('value-unknown-style', (o) => { o.bolt = 'nowhere'; }, { rule: 'xref:pressstyles-strength', pointer: SP + 'bolt' }),
    sx('value-a-note-key', (o) => { o.blast = '_about'; }, { rule: 'pattern', pointer: SP + 'blast' }),
  ];
  strength.find((k) => k.id.endsWith('not-an-object')).mutate = [{ file: P, set: { '/strength': 'speed' } }];
  // ---- hold
  const HB = { from: 28, to: 70, squash: 0.5, lean_back: 0.12 };
  const hx = (n, tweak, expect, style) => { const o = clone(HB); tweak(o); return { id: 'anim-press-styles-hold-' + n, schema: 'anim-press-styles.schema.json', mutate: [{ file: P, set: { ['/styles/' + (style || hostStyle) + '/hold']: o } }], expect }; };
  const HP = '/styles/' + hostStyle + '/hold/';
  const hold = [
    hx('valid', () => {}, null),
    hx('on-super-ok', () => {}, null, 'super'),
    ...['from', 'to', 'squash', 'lean_back'].map((k) => hx('key-required-' + k.replace(/_/g, '-'), (o) => { delete o[k]; }, { rule: 'required', pointer: '/styles/' + hostStyle + '/hold' })),
    hx('unknown-key', (o) => { o.extra = 1; }, { rule: 'additionalProperties', pointer: HP + 'extra' }),
    hx('note-ok', (o) => { o._why = 'a note'; }, null),
    ...['from', 'to'].flatMap((k) => [
      hx(k + '-negative', (o) => { o[k] = -1; }, { rule: 'minimum', pointer: HP + k }),
      hx(k + '-above-max', (o) => { o[k] = 121; }, { rule: 'maximum', pointer: HP + k }),
      hx(k + '-integer', (o) => { o[k] = 2.5; }, { rule: 'type', pointer: HP + k }),
    ]),
    hx('from-zero-ok', (o) => { o.from = 0; }, null),
    hx('to-max-ok', (o) => { o.to = 120; }, null),
    hx('from-equal-to', (o) => { o.from = 40; o.to = 40; }, { rule: 'xref:pressstyles-hold', pointer: HP + 'from' }),
    hx('from-above-to', (o) => { o.from = 50; o.to = 30; }, { rule: 'xref:pressstyles-hold', pointer: HP + 'from' }),
    hx('from-just-below-to-ok', (o) => { o.from = 39; o.to = 40; }, null),
    hx('squash-negative', (o) => { o.squash = -0.1; }, { rule: 'minimum', pointer: HP + 'squash' }),
    hx('squash-above-one', (o) => { o.squash = 1.1; }, { rule: 'maximum', pointer: HP + 'squash' }),
    hx('squash-type', (o) => { o.squash = 'half'; }, { rule: 'type', pointer: HP + 'squash' }),
    hx('squash-edges-ok', (o) => { o.squash = 0; }, null),
    hx('squash-one-ok', (o) => { o.squash = 1; }, null),
    hx('lean-back-negative', (o) => { o.lean_back = -0.01; }, { rule: 'minimum', pointer: HP + 'lean_back' }),
    hx('lean-back-above-half', (o) => { o.lean_back = 0.51; }, { rule: 'maximum', pointer: HP + 'lean_back' }),
    hx('lean-back-type', (o) => { o.lean_back = 'back'; }, { rule: 'type', pointer: HP + 'lean_back' }),
    hx('lean-back-half-ok', (o) => { o.lean_back = 0.5; }, null),
    hx('lean-back-zero-ok', (o) => { o.lean_back = 0; }, null),
    hx('not-an-object', () => {}, { rule: 'type', pointer: '/styles/' + hostStyle + '/hold' }),
  ];
  hold.find((k) => k.id.endsWith('hold-not-an-object')).mutate = [{ file: P, set: { ['/styles/' + hostStyle + '/hold']: 12 } }];
  let n = 0;
  // Companions in the cases that already exist (every case sets its own values): a case that deletes a style the strength map names also moves that word to another style,
  // and the sockets case that sets a lunge above the step names its own step (Animation raised every step_max to 22, above the case's lunge of 20).
  const map = rj(P).strength || {};
  for (const k of c.cases) {
    if (!k.id.startsWith('anim-press-styles-') || k.id.startsWith('anim-press-styles-strength-') || k.id.startsWith('anim-press-styles-hold-')) continue;
    for (const m of k.mutate || []) {
      if (m.file !== P || !Array.isArray(m.del)) continue;
      for (const d of m.del) {
        const mm = /^\/styles\/([A-Za-z0-9_]+)$/.exec(d);
        if (!mm) continue;
        for (const [w, sty] of Object.entries(map)) {
          if (sty !== mm[1]) continue;
          const other = names.find((x) => x !== mm[1]);
          m.set = m.set || {};
          if (m.set['/strength/' + w] !== other) { m.set['/strength/' + w] = other; n++; }
        }
      }
    }
  }
  const lunge = c.cases.find((k) => k.id === 'anim-sockets-limb-lunge-above-step');
  if (lunge && lunge.mutate[0].set && lunge.mutate[0].set['/limbs/hand/step_max'] === undefined) { lunge.mutate[0].set['/limbs/hand/step_max'] = 14; n++; }
  for (const k of [...strength, ...hold]) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`press styles strength and hold applied (${n} new cases)`);
}

// =============================== reach.json: schema, map entry, xref, cases ===============================
// data/anim/reach.json (Animation's: how many units beyond a strike key set's own striking distance the rival may stand and the blow still lands): `schema` (const
// anim.reach/1), `_about`, and `cover`, an object of key set id to integer (-200 to 200). Rule reach-keyset: every key of `cover` is a key set of keysets.json or of a wave's
// keysets (data/anim/waves/*.keysets.json).
{
  const f = 'tools/schemas/anim-reach.schema.json';
  if (!fs.existsSync(f)) {
    wj(f, {
      $schema: 'https://json-schema.org/draft/2020-12/schema',
      $id: 'meridian/anim-reach',
      title: 'anim.reach/1',
      description: 'data/anim/reach.json: how many units beyond a strike key set\'s own striking distance (the manifest row\'s range.offset) the rival may stand and the blow still lands (a negative number is how far it must be inside). Render only. `cover` is key set id to integer units, -200 to 200. Version field: schema. Policy: closed except keys starting with an underscore. Cross-reference: every key of `cover` is a key set of keysets.json or of a wave\'s keysets (reach-keyset).',
      type: 'object',
      required: ['schema', 'cover'],
      properties: {
        schema: { const: 'anim.reach/1' },
        cover: {
          type: 'object',
          description: 'Key set id to the units beyond its own striking distance at which the blow still lands.',
          propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*([.][a-z0-9_]+)+)$' },
          additionalProperties: { type: 'integer', minimum: -200, maximum: 200 },
          patternProperties: { '^_': true },
        },
      },
      additionalProperties: false,
      patternProperties: { '^_': true },
    });
  }
  const mf = 'tools/schemas/map.json';
  const m = rj(mf);
  if (!m.rules.some((r) => r.match === 'data/anim/reach.json')) {
    const i = m.rules.findIndex((r) => r.match === 'data/anim/keysets.json');
    if (i < 0) throw new Error('map.json has no keysets rule to put the reach rule after');
    m.rules.splice(i + 1, 0, { match: 'data/anim/reach.json', schema: 'anim-reach.schema.json' });
    wj(mf, m);
  }
  const xf = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(xf, 'utf8');
  if (!t.includes("'reach-keyset'")) {
    const a = 'function xrefFight({ get, err, esc, isObj, plainKeys, docsFor }) {\n';
    if (!t.includes(a)) throw new Error('reach xref anchor');
    t = t.replace(a, () => a + [
      '  // ---- reach (data/anim/reach.json) ----',
      "  const reachDoc = get('data/anim/reach.json');",
      '  if (isObj(reachDoc) && isObj(reachDoc.cover)) {',
      "    const ksAll = get('data/anim/keysets.json');",
      '    const setIds = new Set(isObj(ksAll) && isObj(ksAll.keysets) ? Object.keys(ksAll.keysets) : []);',
      '    for (const rel of docsFor(/^data\\/anim\\/waves\\/[^/]+\\.keysets\\.json$/)) {',
      '      const wd = get(rel);',
      '      if (isObj(wd) && isObj(wd.keysets)) for (const k of Object.keys(wd.keysets)) setIds.add(k);',
      '    }',
      '    if (setIds.size) {',
      '      for (const k of Object.keys(reachDoc.cover)) {',
      "        if (k.startsWith('_')) continue;",
      "        if (!setIds.has(k)) err('data/anim/reach.json', `/cover/${esc(k)}`, 'reach-keyset', `\"${k}\" is not a key set of keysets.json or of a wave's keysets`);",
      '      }',
      '    }',
      '  }',
      '',
    ].join('\n'));
    fs.writeFileSync(xf, t);
  }
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const R = 'data/anim/reach.json';
  const k0 = Object.keys(rj(R).cover).find((k) => !k.startsWith('_'));
  const rx = (id, mutate, expect) => ({ id: 'anim-reach-' + id, schema: 'anim-reach.schema.json', mutate: [{ file: R, ...mutate }], expect });
  const K = '/cover/' + k0;
  const add = [
    rx('valid', { set: { [K]: 40 } }, null),
    rx('zero-ok', { set: { [K]: 0 } }, null),
    rx('low-edge-ok', { set: { [K]: -200 } }, null),
    rx('high-edge-ok', { set: { [K]: 200 } }, null),
    rx('below-low-edge', { set: { [K]: -201 } }, { rule: 'minimum', pointer: K }),
    rx('above-high-edge', { set: { [K]: 201 } }, { rule: 'maximum', pointer: K }),
    rx('not-an-integer', { set: { [K]: 12.5 } }, { rule: 'type', pointer: K }),
    rx('value-type', { set: { [K]: 'far' } }, { rule: 'type', pointer: K }),
    rx('schema-required', { del: ['/schema'] }, { rule: 'required', pointer: '' }),
    rx('schema-version', { set: { '/schema': 'anim.reach/2' } }, { rule: 'const', pointer: '/schema' }),
    rx('cover-required', { del: ['/cover'] }, { rule: 'required', pointer: '' }),
    rx('cover-type', { set: { '/cover': [1, 2] } }, { rule: 'type', pointer: '/cover' }),
    rx('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' }),
    rx('note-ok', { set: { '/_why': 'a note' } }, null),
    rx('cover-note-ok', { set: { '/cover/_why': 'a note' } }, null),
    rx('key-shape', { set: { '/cover/Bad Key': 5 } }, { rule: 'propertyNames', pointer: '/cover/Bad Key' }),
    rx('key-without-a-prefix', { set: { '/cover/nodot': 5 } }, { rule: 'propertyNames', pointer: '/cover/nodot' }),
    rx('key-not-a-key-set', { set: { '/cover/zz.nowhere': 5 } }, { rule: 'xref:reach-keyset', pointer: '/cover/zz.nowhere' }),
  ];
  let n = 0;
  for (const k of add) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`reach.json applied (${n} new cases)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  const t = fs.readFileSync(f, 'utf8');
  const lines = t.split('\n');
  const i = lines.findIndex((l) => l.includes('`pressstyles-set`'));
  if (i < 0) throw new Error('strength README anchor');
  const rows = [
    ['`pressstyles-strength`', '| `pressstyles-strength` | data/anim/press_styles.json: every value of `strength` (light, medium, heavy, bolt, blast) is a key of `styles` |'],
    ['`pressstyles-hold`', "| `pressstyles-hold` | data/anim/press_styles.json: a style's `hold.from` is below its `hold.to` |"],
    ['`reach-keyset`', "| `reach-keyset` | data/anim/reach.json: every key of `cover` is a key set of keysets.json or of a wave's keysets |"],
  ].filter(([key]) => !t.includes(key)).map(([, row]) => row);
  if (rows.length) { lines.splice(i + 1, 0, ...rows); fs.writeFileSync(f, lines.join('\n')); }
}
