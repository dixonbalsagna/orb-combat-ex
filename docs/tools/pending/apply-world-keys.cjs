// World's keys added by grant (2026-10-12), with cases and bounds:
//   data/biomes/settlements.json: top-level `aspect_max` becomes required (a number from 1); a district's `row_pop` becomes required (four numbers 0 to 1); a kind's `aspect_max` stays optional (one
//   kind in the file carries its own, by design) and gets its cases.
//   data/biomes/lanes.json: `demo_start` stays optional (World's schema says the demo starts at START_X without it) and gets its cases and a cross-reference (rule `lanes-demo-start`: `lane` is a
//   street lane of this file, `look` is one of settlements.json's looks), in tools/lib/xref-lanes.js (copied from docs/tools/pending/xref-lanes.js, which this script rewrites).
// NOT run by CI, the validator or the sim. Run once from the repo root, in a commit that is not mid-way through another schema script:
//     node docs/tools/pending/apply-world-keys.cjs
// It does NOT edit data/. Re-runnable (a second run changes nothing). Every case sets its own values.
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);

// ---- settlements schema
{
  const f = 'tools/schemas/biomes-settlements.schema.json';
  const s = rj(f);
  if (!s.required.includes('aspect_max')) s.required.push('aspect_max');
  if (!s.$defs.district.required.includes('row_pop')) s.$defs.district.required.push('row_pop');
  wj(f, s);
}
// ---- xref (lanes.json demo_start)
{
  const f = 'docs/tools/pending/xref-lanes.js';
  let t = fs.readFileSync(f, 'utf8');
  if (!t.includes('lanes-demo-start')) {
    const hdr = "//     strip-overlap  the strips of one lane do not overlap\n";
    if (!t.includes(hdr)) throw new Error('xref-lanes header anchor');
    t = t.replace(hdr, () => hdr + "//     lanes-demo-start  demo_start.lane is a street lane of this file, and demo_start.look is one of settlements.json's `looks`\n");
    const a = "  const st = get(SF);\n  if (!isObj(st)) return;\n";
    if (!t.includes(a)) throw new Error('xref-lanes body anchor');
    t = t.replace(a, () => [
      "  if (isObj(d) && isObj(d.demo_start)) {",
      "    const ds = d.demo_start;",
      "    const lane = typeof ds.lane === 'string' ? lanes.find((l) => isObj(l) && l.name === ds.lane) : undefined;",
      "    if (typeof ds.lane === 'string' && !lane) err(LF, '/demo_start/lane', 'lanes-demo-start', `demo_start lane \"${ds.lane}\" is not a lane of this file`);",
      "    else if (lane && lane.kind !== 'street') err(LF, '/demo_start/lane', 'lanes-demo-start', `demo_start lane \"${ds.lane}\" is a ${lane.kind} lane: the demo starts at a crossing of a street`);",
      "    const sd = get(SF);",
      "    if (typeof ds.look === 'string' && isObj(sd) && Array.isArray(sd.looks) && !sd.looks.includes(ds.look)) err(LF, '/demo_start/look', 'lanes-demo-start', `demo_start look \"${ds.look}\" is not in settlements.json's looks ${JSON.stringify(sd.looks)}`);",
      "  }",
      "",
      a,
    ].join('\n'));
    fs.writeFileSync(f, t);
  }
  fs.copyFileSync(f, 'tools/lib/xref-lanes.js');
}
// ---- cases
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const out = [];
  const SS = 'biomes-settlements.schema.json', SF = 'data/biomes/settlements.json';
  const LS = 'biomes-lanes.schema.json', LF = 'data/biomes/lanes.json';
  const add = (schema, file, id, mutate, expect) => out.push({ id, schema, mutate: [Object.assign({ file }, mutate)], expect });
  const sc = (id, m, e) => add(SS, SF, 'settle-world-' + id, m, e);
  const D0 = '/settlements/0/districts/0';
  const K0 = D0 + '/kinds/0';
  sc('aspect-max-required', { del: ['/aspect_max'] }, { rule: 'required', pointer: '' });
  sc('aspect-max-type', { set: { '/aspect_max': 'tall' } }, { rule: 'type', pointer: '/aspect_max' });
  sc('aspect-max-below-one', { set: { '/aspect_max': 0.5 } }, { rule: 'minimum', pointer: '/aspect_max' });
  sc('aspect-max-one-ok', { set: { '/aspect_max': 1 } }, null);
  sc('aspect-max-large-ok', { set: { '/aspect_max': 12 } }, null);
  sc('kind-aspect-max-type', { set: { [K0 + '/aspect_max']: 'tall' } }, { rule: 'type', pointer: K0 + '/aspect_max' });
  sc('kind-aspect-max-below-one', { set: { [K0 + '/aspect_max']: 0.9 } }, { rule: 'minimum', pointer: K0 + '/aspect_max' });
  // the one kind that carries its own (the chimney: settlements/1/districts/1/kinds/1, 10): a kind without one is the norm, so removing it is allowed
  sc('kind-aspect-max-absent-ok', { del: ['/settlements/1/districts/1/kinds/1/aspect_max'] }, null);
  sc('kind-aspect-max-ten-ok', { set: { [K0 + '/aspect_max']: 10 } }, null);
  sc('row-pop-required', { del: [D0 + '/row_pop'] }, { rule: 'required', pointer: D0 });
  sc('row-pop-type', { set: { [D0 + '/row_pop']: 0.5 } }, { rule: 'type', pointer: D0 + '/row_pop' });
  sc('row-pop-too-short', { set: { [D0 + '/row_pop']: [1, 1, 1] } }, { rule: 'minItems', pointer: D0 + '/row_pop' });
  sc('row-pop-too-long', { set: { [D0 + '/row_pop']: [1, 1, 1, 1, 1] } }, { rule: 'maxItems', pointer: D0 + '/row_pop' });
  sc('row-pop-item-type', { set: { [D0 + '/row_pop/2']: 'many' } }, { rule: 'type', pointer: D0 + '/row_pop/2' });
  sc('row-pop-negative', { set: { [D0 + '/row_pop/1']: -0.1 } }, { rule: 'minimum', pointer: D0 + '/row_pop/1' });
  sc('row-pop-above-one', { set: { [D0 + '/row_pop/3']: 1.5 } }, { rule: 'maximum', pointer: D0 + '/row_pop/3' });
  sc('row-pop-edges-ok', { set: { [D0 + '/row_pop']: [0, 1, 0, 1] } }, null);
  const lc = (id, m, e) => add(LS, LF, 'lanes-demo-start-' + id, m, e);
  lc('type', { set: { '/demo_start': 'downtown' } }, { rule: 'type', pointer: '/demo_start' });
  lc('look-required', { del: ['/demo_start/look'] }, { rule: 'required', pointer: '/demo_start' });
  lc('lane-required', { del: ['/demo_start/lane'] }, { rule: 'required', pointer: '/demo_start' });
  lc('look-empty', { set: { '/demo_start/look': '' } }, { rule: 'minLength', pointer: '/demo_start/look' });
  lc('look-type', { set: { '/demo_start/look': 5 } }, { rule: 'type', pointer: '/demo_start/look' });
  lc('lane-shape', { set: { '/demo_start/lane': 'Front Street' } }, { rule: 'pattern', pointer: '/demo_start/lane' });
  lc('unknown-key', { set: { '/demo_start/offset': 3 } }, { rule: 'additionalProperties', pointer: '/demo_start/offset' });
  lc('underscore-key-ok', { set: { '/demo_start/_note': 'the demo start' } }, null);
  lc('absent-ok', { del: ['/demo_start'] }, null);
  lc('lane-not-a-lane', { set: { '/demo_start/lane': 'nowhere' } }, { rule: 'xref:lanes-demo-start', pointer: '/demo_start/lane' });
  lc('lane-not-a-street', { set: { '/demo_start/lane': 'block_1' } }, { rule: 'xref:lanes-demo-start', pointer: '/demo_start/lane' });
  lc('back-street-ok', { set: { '/demo_start/lane': 'back_street' } }, null);
  lc('look-not-in-looks', { set: { '/demo_start/look': 'slums' } }, { rule: 'xref:lanes-demo-start', pointer: '/demo_start/look' });
  let n = 0;
  for (const k of out) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (!same(c.cases[i], k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`world keys applied (${n} new or changed cases)`);
}
// ---- docs
{
  const f = 'docs/tools/README.md';
  const t = fs.readFileSync(f, 'utf8');
  const a = "every district row is the row of a lane that holds footprints |";
  if (t.includes(a) && !t.includes('`lanes-demo-start`')) {
    fs.writeFileSync(f, t.replace(a, "every district row is the row of a lane that holds footprints. `lanes-demo-start`: data/biomes/lanes.json demo_start.lane is a street lane of the file and demo_start.look is one of settlements.json's looks |"));
  }
}
