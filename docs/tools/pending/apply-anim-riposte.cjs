// Schema keys for Animation's riposte (docs/animation/press-styles.md section 12): data/anim/press_styles.json gains a top-level optional closed
// `riposte` block beside `guard`. NOT run by CI, the validator or the sim. Run once from the repo root, in the commit that lands the data:
//     node docs/tools/pending/apply-anim-riposte.cjs
// It does NOT edit data/. The block:
//   "riposte": { "windup": { "light": 2, "heavy": 3 }, "fade": 4, "style": { "light": "tech", "heavy": "heavy" }, "grade": "perfect" }
//   windup  required, closed; light and heavy both required; integers 1 to 8
//   fade    required; integer 1 to 12
//   style   optional, closed; light and heavy each optional, and each one of speed, tech, heavy, push (rule pressstyles-riposte: it is a key of `styles`)
//   grade   optional; one of perfect, good, off, none
// Every case sets its own whole block. Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const obj = (props, opts = {}) => Object.assign({ type: 'object', required: opts.required === undefined ? Object.keys(props) : opts.required, properties: props }, opts.description ? { description: opts.description } : {}, closed);
const clone = (o) => JSON.parse(JSON.stringify(o));
const STYLES = ['speed', 'tech', 'heavy', 'push'];

// =============================== schema ===============================
{
  const f = 'tools/schemas/anim-press-styles.schema.json';
  const s = rj(f);
  if (!s.properties.riposte) {
    const props = {};
    for (const [k, v] of Object.entries(s.properties)) {
      props[k] = v;
      if (k === 'guard') {
        props.riposte = obj({
          windup: obj({
            light: { type: 'integer', minimum: 1, maximum: 8, description: 'Ticks of wind-up (from the block pose) before a light riposte.' },
            heavy: { type: 'integer', minimum: 1, maximum: 8, description: 'Ticks of wind-up before a heavy riposte.' },
          }, { description: 'The riposte\'s wind-up, in ticks, by weight.' }),
          fade: { type: 'integer', minimum: 1, maximum: 12, description: 'Ticks the block pose fades into the riposte.' },
          style: obj({
            light: { enum: STYLES, description: 'The press style a light riposte plays in (a key of styles).' },
            heavy: { enum: STYLES, description: 'The press style a heavy riposte plays in (a key of styles).' },
          }, { required: [], description: 'Optional. The press style of the riposte, by weight; each weight is optional.' }),
          grade: { enum: ['perfect', 'good', 'off', 'none'], description: 'Optional. The grade of block a riposte follows.' },
        }, { required: ['windup', 'fade'], description: 'Optional. The brawl\'s riposte: the blocker\'s counter blow leaves from his block pose (docs/animation/press-styles.md section 12).' });
      }
    }
    if (!props.riposte) throw new Error('press styles schema has no guard property to put riposte beside');
    s.properties = props;
    if (!/pressstyles-riposte/.test(s.description)) s.description = s.description.replace(/\. Cross-references \(/, () => '. Cross-references (a riposte style names a key of styles (pressstyles-riposte); ');
    wj(f, s);
  }
}

// =============================== xref ===============================
{
  const f = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes("'pressstyles-riposte'")) {
    const a = "    for (const [sid, st] of Object.entries(isObj(pst.styles) ? pst.styles : {})) {\n      if (sid.startsWith('_') || !isObj(st)) continue;\n      if (st.carry === true";
    if (!t.includes(a)) throw new Error('riposte xref anchor');
    t = t.replace(a, () => [
      "    if (isObj(pst.riposte) && isObj(pst.riposte.style) && isObj(pst.styles)) {",
      "      for (const w of ['light', 'heavy']) {",
      "        const sty = pst.riposte.style[w];",
      "        if (typeof sty === 'string' && !(sty in pst.styles)) err(PS, `/riposte/style/${w}`, 'pressstyles-riposte', `riposte style \"${sty}\" is not a key of styles (${Object.keys(pst.styles).filter((k) => !k.startsWith('_')).join(', ')})`);",
      "      }",
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
  const P = 'data/anim/press_styles.json';
  const BASE = { windup: { light: 2, heavy: 3 }, fade: 4, style: { light: 'tech', heavy: 'heavy' }, grade: 'perfect' };
  const x = (n, tweak, expect, extra) => {
    const b = clone(BASE);
    tweak(b);
    return { id: 'anim-press-styles-riposte-' + n, schema: 'anim-press-styles.schema.json', mutate: [Object.assign({ file: P, set: { '/riposte': b } }, extra || {})], expect };
  };
  const R = '/riposte/';
  const add = [
    x('valid', () => {}, null),
    x('minimal-ok', (b) => { delete b.style; delete b.grade; }, null),
    x('unknown-key', (b) => { b.extra = 1; }, { rule: 'additionalProperties', pointer: R + 'extra' }),
    x('underscore-key-ok', (b) => { b._why = 'a note'; }, null),
    x('empty-block', (b) => { for (const k of Object.keys(b)) delete b[k]; }, { rule: 'required', pointer: '/riposte' }),
    x('windup-required', (b) => { delete b.windup; }, { rule: 'required', pointer: '/riposte' }),
    x('fade-required', (b) => { delete b.fade; }, { rule: 'required', pointer: '/riposte' }),
    x('windup-light-required', (b) => { delete b.windup.light; }, { rule: 'required', pointer: R + 'windup' }),
    x('windup-heavy-required', (b) => { delete b.windup.heavy; }, { rule: 'required', pointer: R + 'windup' }),
    x('windup-unknown-key', (b) => { b.windup.signature = 4; }, { rule: 'additionalProperties', pointer: R + 'windup/signature' }),
    x('windup-light-zero', (b) => { b.windup.light = 0; }, { rule: 'minimum', pointer: R + 'windup/light' }),
    x('windup-light-nine', (b) => { b.windup.light = 9; }, { rule: 'maximum', pointer: R + 'windup/light' }),
    x('windup-light-integer', (b) => { b.windup.light = 2.5; }, { rule: 'type', pointer: R + 'windup/light' }),
    x('windup-heavy-zero', (b) => { b.windup.heavy = 0; }, { rule: 'minimum', pointer: R + 'windup/heavy' }),
    x('windup-heavy-nine', (b) => { b.windup.heavy = 9; }, { rule: 'maximum', pointer: R + 'windup/heavy' }),
    x('windup-heavy-type', (b) => { b.windup.heavy = 'slow'; }, { rule: 'type', pointer: R + 'windup/heavy' }),
    x('windup-edges-ok', (b) => { b.windup.light = 1; b.windup.heavy = 8; }, null),
    x('fade-zero', (b) => { b.fade = 0; }, { rule: 'minimum', pointer: R + 'fade' }),
    x('fade-thirteen', (b) => { b.fade = 13; }, { rule: 'maximum', pointer: R + 'fade' }),
    x('fade-integer', (b) => { b.fade = 4.5; }, { rule: 'type', pointer: R + 'fade' }),
    x('fade-edges-ok', (b) => { b.fade = 12; }, null),
    x('fade-one-ok', (b) => { b.fade = 1; }, null),
    x('style-unknown-key', (b) => { b.style.signature = 'tech'; }, { rule: 'additionalProperties', pointer: R + 'style/signature' }),
    x('style-light-enum', (b) => { b.style.light = 'wild'; }, { rule: 'enum', pointer: R + 'style/light' }),
    x('style-heavy-enum', (b) => { b.style.heavy = 'wild'; }, { rule: 'enum', pointer: R + 'style/heavy' }),
    x('style-only-light-ok', (b) => { delete b.style.heavy; }, null),
    x('style-every-name-ok', (b) => { b.style.light = 'speed'; b.style.heavy = 'tech'; }, null),
    x('style-names-a-style-that-is-gone', (b) => { b.style.light = 'push'; }, { rule: 'xref:pressstyles-riposte', pointer: R + 'style/light' }, { del: ['/styles/push'] }),
    x('style-heavy-names-a-style-that-is-gone', (b) => { b.style.heavy = 'speed'; }, { rule: 'xref:pressstyles-riposte', pointer: R + 'style/heavy' }, { del: ['/styles/speed'] }),
    x('grade-perfect-ok', (b) => { b.grade = 'perfect'; }, null),
    x('grade-good-ok', (b) => { b.grade = 'good'; }, null),
    x('grade-off-ok', (b) => { b.grade = 'off'; }, null),
    x('grade-none-ok', (b) => { b.grade = 'none'; }, null),
    x('grade-enum', (b) => { b.grade = 'excellent'; }, { rule: 'enum', pointer: R + 'grade' }),
    x('grade-type', (b) => { b.grade = 1; }, { rule: 'enum', pointer: R + 'grade' }),
    { id: 'anim-press-styles-riposte-absent-ok', schema: 'anim-press-styles.schema.json', mutate: [{ file: P, del: ['/riposte'] }], expect: null },
  ];
  let n = 0;
  for (const k of add) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`press styles riposte applied (${n} new cases)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes('`pressstyles-riposte`')) {
    const lines = t.split('\n');
    const i = lines.findIndex((l) => l.includes('`pressstyles-pose`'));
    if (i < 0) throw new Error('riposte README anchor');
    lines.splice(i + 1, 0, '| `pressstyles-riposte` | data/anim/press_styles.json: a riposte style (light, heavy) is a key of `styles` |');
    fs.writeFileSync(f, lines.join('\n'));
  }
}
