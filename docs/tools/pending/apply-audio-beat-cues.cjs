// The schema for Audio's audio/data/beat_cues.json (the beat: the perfect follow-up's tick, spark, notes, close, link shimmer and droop; the held X's settle; the mashed Y's grind; the Y's charge hum and
// full tick; the launcher's rest: docs/audio/brawl-beat.md, audio/audio_brawl.gd merges it with brawl_cues.json): tools/schemas/audio-beat-cues.schema.json, its map.json rule after
// brawl_cues.json, the cross-references (tools/lib/xref-beat-cues.js, from docs/tools/pending/xref-beat-cues.js) and the cases. NOT run by CI, the validator or the sim. Run once from the repo
// root, in the commit that lands the file:
//     node docs/tools/pending/apply-audio-beat-cues.cjs
// It does NOT edit audio/data/. It refuses until the file is in the tree. Policy: closed except keys starting with an underscore and the `note` string Audio keeps beside its numbers.
// Cross-references (README table): beat-cue-sound (every sound a cue names is synthesised in impacts.json), beat-cue-bus (every bus is a bus of mix.json), beat-cue-order (the chord ratios rise,
// the spark's clear ticks are at most its longest wait). Every case sets its own values. Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const F = 'audio/data/beat_cues.json';
if (!fs.existsSync(F)) { console.error(`${F} is not in the tree yet: run this in the commit that lands it`); process.exit(1); }
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const ID = '^[a-z][a-z0-9_]*([.][a-z0-9_]+)*$';
const KIND = {
  str: (d) => ({ type: 'string', minLength: 1, description: d }),
  strE: (d) => ({ type: 'string', description: d }),
  snd: (d) => ({ type: 'string', pattern: ID, description: d + ' (a sound synthesised in impacts.json: beat-cue-sound)' }),
  bus: (d) => ({ type: 'string', pattern: '^[A-Za-z][A-Za-z0-9]*$', description: d + ' (a bus of mix.json: beat-cue-bus)' }),
  i0: (d) => ({ type: 'integer', minimum: 0, description: d }),
  i1: (d) => ({ type: 'integer', minimum: 1, description: d }),
  db: (d) => ({ type: 'number', minimum: -60, maximum: 24, description: d }),
  pos: (d) => ({ type: 'number', exclusiveMinimum: 0, description: d }),
  n0: (d) => ({ type: 'number', minimum: 0, description: d }),
  num: (d) => ({ type: 'number', description: d }),
  strs: (d) => ({ type: 'array', minItems: 1, items: { type: 'string', minLength: 1 }, description: d }),
  poss: (d) => ({ type: 'array', minItems: 1, items: { type: 'number', exclusiveMinimum: 0 }, description: d }),
};
const L = (k, d) => ({ __leaf: true, k, d });
const isLeaf = (x) => x && x.__leaf === true;
const O = (props, o = {}) => ({ __obj: true, props, note: o.note !== false });
const sc = (n) => (isLeaf(n) ? (n.k === 'schema' ? { const: 1 } : KIND[n.k](n.d)) : objSchema(n));
function objSchema(n) {
  const props = Object.fromEntries(Object.entries(n.props).map(([k, v]) => [k, sc(v)]));
  if (n.note) props.note = { type: 'string', description: 'A note for the next person (Audio keeps one beside its numbers).' };
  return Object.assign({ type: 'object', required: Object.keys(n.props), properties: props }, closed);
}
const cueKeys = (m) => O(m, { note: false });
const SPEC = O({
  schema: { __leaf: true, k: 'schema', d: '' },
  perfect: O({
    bus: L('bus', 'The bus every perfect-chain sound plays on (Alert: the launcher ping\'s duck does not take it).'),
    land: cueKeys({ before: L('i0', 'Ticks before the follow-up\'s landing it is looked for.'), after: L('i0', 'Ticks after the landing it is looked for.') }),
    own: cueKeys({
      ratios: L('poss', 'The pitch ratios of the chain\'s notes, rising (beat-cue-order).'),
      by_strength: cueKeys({ light: L('snd', 'The note for a light follow-up.'), medium: L('snd', 'For a medium.'), heavy: L('snd', 'For a heavy.') }),
      close: L('snd', 'The closing note.'), spark: L('snd', 'The spark at the tap.'),
    }),
    foe: cueKeys({
      ratios: L('poss', 'The opponent\'s ratios, rising (beat-cue-order).'),
      note: L('snd', 'The opponent\'s note (a sound name: this key is the note, not a comment).'),
      close: L('snd', 'The opponent\'s closing note.'), spark: L('snd', 'The spark.'),
    }),
    link: cueKeys({ sound: L('snd', 'The link\'s shimmer.'), gain_db: L('db', 'Gain, dB.') }),
    gain_db: cueKeys({ spark: L('db', 'Gain.'), note: L('db', 'Gain.'), close: L('db', 'Gain.') }),
    priority: cueKeys({ spark: L('i0', 'Priority.'), note: L('i0', 'Priority.'), close: L('i0', 'Priority.'), tick: L('i0', 'Priority.'), break: L('i0', 'Priority.') }),
    cls: cueKeys({ spark: L('str', 'Class.'), note: L('str', 'Class.'), close: L('str', 'Class.'), link: L('str', 'Class.'), tick: L('str', 'Class.'), break: L('str', 'Class.') }),
    cap: cueKeys({ spark: L('i1', 'Cap.'), note: L('i1', 'Cap.'), close: L('i1', 'Cap.'), link: L('i1', 'Cap.'), tick: L('i1', 'Cap.'), break: L('i1', 'Cap.') }),
    tick: cueKeys({ sound: L('snd', 'The tick.'), gain_db: L('db', 'Gain.'), caption: L('strE', 'The caption ("" for none).') }),
    broken: cueKeys({ sound: L('snd', 'The droop.'), gain_db: L('db', 'Gain.'), texts: L('strs', 'The cue texts that break the chain.') }),
    spark_clear: cueKeys({ ticks: L('i0', 'Ticks the spark waits clear.'), look_ahead: L('i0', 'How far ahead it looks.'), max_wait: L('i0', 'The longest it waits (at least ticks: beat-cue-order).') }),
  }),
  held: O({
    after_gap_ticks: L('i0', 'Ticks.'), complete_blows: L('i1', 'Blows.'), lite_gap_max: L('i0', 'Ticks.'), pitch_from_gap: L('i0', 'Ticks.'),
    pitch_st_per_tick: L('num', 'Semitones a tick.'), pitch_min_st: L('num', 'Semitones.'), gain_db: L('db', 'Gain.'),
  }),
  grind: O({
    sound: L('snd', 'The grind.'), window_ticks: L('i1', 'Ticks.'), after: L('i0', 'Medium blows before it starts.'), step_db: L('db', 'Step, dB.'),
    drop_st_per_blow: L('n0', 'Semitones.'), max_drop_st: L('n0', 'Most semitones.'),
  }),
  rest: cueKeys({ sound: L('snd', 'The launcher\'s rest.'), gain_db: L('db', 'Gain.'), priority: L('i0', 'Priority.'), cls: L('str', 'Class.'), cap: L('i1', 'Cap.'), caption: L('strE', 'Caption.') }),
  charge_y: O({
    hum: cueKeys({ sound: L('snd', 'The hum.'), gain_db: L('db', 'Gain.'), priority: L('i0', 'Priority.'), cls: L('str', 'Class.'), cap: L('i1', 'Cap.'), stop_ms: L('i0', 'Fade, ms.') }),
    full: cueKeys({ sound: L('snd', 'The tick.'), gain_db: L('db', 'Gain.'), priority: L('i0', 'Priority.'), bus: L('bus', 'Bus.'), cls: L('str', 'Class.'), cap: L('i1', 'Cap.'), caption: L('strE', 'Caption.') }),
  }, { note: false }),
}, { note: true });

// =============================== schema, map, xref ===============================
{
  const f = 'tools/schemas/audio-beat-cues.schema.json';
  const s = objSchema(SPEC);
  s.properties.schema = { const: 1 };
  s.properties.note = { type: 'string', minLength: 1, description: 'The beat cues in one paragraph.' };
  s.required = [...s.required, 'note'];
  wj(f, Object.assign({
    $schema: 'https://json-schema.org/draft/2020-12/schema', $id: 'meridian/audio-beat-cues', title: 'audio beat cues (schema 1)',
    description: 'audio/data/beat_cues.json: the beat (docs/audio/brawl-beat.md): the perfect follow-up\'s tick, spark, notes, close, link shimmer and droop, the held X\'s settle, the mashed Y\'s grind, the Y\'s charge hum and full tick, the launcher\'s rest. Kept apart from brawl_cues.json so that file keeps its shape; audio/audio_brawl.gd merges the two. Cross-references in tools/lib/xref-beat-cues.js (beat-cue-sound, beat-cue-bus, beat-cue-order). Version field: schema. Policy: closed except keys starting with an underscore (and the `note` string beside the numbers).',
  }, s));
  const mf = 'tools/schemas/map.json';
  const m = rj(mf);
  if (!m.rules.some((r) => r.match === F)) {
    const i = m.rules.findIndex((r) => r.match === 'audio/data/brawl_cues.json');
    m.rules.splice(i < 0 ? m.rules.length : i + 1, 0, { match: F, schema: 'audio-beat-cues.schema.json' });
    wj(mf, m);
  }
  fs.copyFileSync('docs/tools/pending/xref-beat-cues.js', 'tools/lib/xref-beat-cues.js');
  const xf = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(xf, 'utf8');
  if (!t.includes("require('./xref-beat-cues')")) {
    const a = "  require('./xref-brawl-cues').xrefBrawlCues({ get, err, esc, isObj });\n";
    if (!t.includes(a)) throw new Error('beat cues xref anchor');
    t = t.replace(a, () => a + "  require('./xref-beat-cues').xrefBeatCues({ get, err, esc, isObj });\n");
    fs.writeFileSync(xf, t);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const data = rj(F);
  const mix = rj('audio/data/mix.json');
  const busName = mix.buses[0].name;
  const out = [];
  const cs = (id, mutate, expect) => out.push({ id: 'audio-beat-cues-' + id, schema: 'audio-beat-cues.schema.json', mutate: [{ file: F, ...mutate }], expect });
  const slug = (path) => path.join('-').replace(/_/g, '-').toLowerCase();
  const ptr = (path) => path.map((p) => '/' + p).join('');
  const val = (path) => path.reduce((a, k) => a[k], data);
  cs('valid', { set: { '/schema': 1 } }, null);
  for (const k of ['schema', 'note', 'perfect', 'held', 'grind', 'rest', 'charge_y']) cs('key-required-' + k.replace(/_/g, '-'), { del: ['/' + k] }, { rule: 'required', pointer: '' });
  cs('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' });
  cs('note-key-ok', { set: { '/_why': 'a note' } }, null);
  cs('schema-version', { set: { '/schema': 2 } }, { rule: 'const', pointer: '/schema' });
  const walk = (n, path) => {
    if (isLeaf(n)) {
      if (n.k === 'schema') return;
      let v;
      try { v = val(path); } catch { v = undefined; }
      if (v === undefined) return;
      const P = ptr(path), parent = ptr(path.slice(0, -1)), s = slug(path);
      cs(s + '-required', { del: [P] }, { rule: 'required', pointer: parent });
      const k = n.k;
      if (k === 'str' || k === 'snd' || k === 'bus') {
        cs(s + '-type', { set: { [P]: 5 } }, { rule: 'type', pointer: P });
        cs(s + '-empty', { set: { [P]: '' } }, { rule: k === 'str' ? 'minLength' : 'pattern', pointer: P });
        if (k === 'snd') cs(s + '-shape', { set: { [P]: 'Hit Light' } }, { rule: 'pattern', pointer: P });
        if (k === 'snd') cs(s + '-not-synthesised', { set: { [P]: 'impact.nowhere' } }, { rule: 'xref:beat-cue-sound', pointer: P });
        if (k === 'bus') cs(s + '-not-a-bus', { set: { [P]: 'NoSuchBus' } }, { rule: 'xref:beat-cue-bus', pointer: P });
      } else if (k === 'strE') {
        cs(s + '-type', { set: { [P]: 5 } }, { rule: 'type', pointer: P });
        cs(s + '-empty-ok', { set: { [P]: '' } }, null);
      } else if (k === 'i0' || k === 'i1') {
        cs(s + '-integer', { set: { [P]: 2.5 } }, { rule: 'type', pointer: P });
        cs(s + '-below-min', { set: { [P]: k === 'i0' ? -1 : 0 } }, { rule: 'minimum', pointer: P });
        cs(s + '-type', { set: { [P]: 'many' } }, { rule: 'type', pointer: P });
      } else if (k === 'db') {
        cs(s + '-below', { set: { [P]: -61 } }, { rule: 'minimum', pointer: P });
        cs(s + '-above', { set: { [P]: 25 } }, { rule: 'maximum', pointer: P });
        cs(s + '-type', { set: { [P]: 'loud' } }, { rule: 'type', pointer: P });
      } else if (k === 'pos') {
        cs(s + '-zero', { set: { [P]: 0 } }, { rule: 'exclusiveMinimum', pointer: P });
        cs(s + '-type', { set: { [P]: 'high' } }, { rule: 'type', pointer: P });
      } else if (k === 'n0') {
        cs(s + '-negative', { set: { [P]: -1 } }, { rule: 'minimum', pointer: P });
        cs(s + '-type', { set: { [P]: 'big' } }, { rule: 'type', pointer: P });
      } else if (k === 'num') {
        cs(s + '-type', { set: { [P]: 'x' } }, { rule: 'type', pointer: P });
      } else if (k === 'strs') {
        cs(s + '-type', { set: { [P]: 'a' } }, { rule: 'type', pointer: P });
        cs(s + '-empty', { set: { [P]: [] } }, { rule: 'minItems', pointer: P });
        cs(s + '-item-type', { set: { [P]: [1] } }, { rule: 'type', pointer: P + '/0' });
      } else if (k === 'poss') {
        cs(s + '-type', { set: { [P]: 1 } }, { rule: 'type', pointer: P });
        cs(s + '-empty', { set: { [P]: [] } }, { rule: 'minItems', pointer: P });
        cs(s + '-item-zero', { set: { [P]: [0, 1.2] } }, { rule: 'exclusiveMinimum', pointer: P + '/0' });
        cs(s + '-item-type', { set: { [P]: ['x'] } }, { rule: 'type', pointer: P + '/0' });
      }
      return;
    }
    const P = ptr(path);
    if (path.length) {
      cs(slug(path) + '-type', { set: { [P]: 5 } }, { rule: 'type', pointer: P });
      cs(slug(path) + '-unknown-key', { set: { [P + '/extra']: 1 } }, { rule: 'additionalProperties', pointer: P + '/extra' });
      cs(slug(path) + '-required', { del: [P] }, { rule: 'required', pointer: ptr(path.slice(0, -1)) });
    }
    for (const [k, v] of Object.entries(n.props)) walk(v, path.concat(k));
  };
  walk(SPEC, []);
  // the cross-references
  cs('own-ratios-fall', { set: { '/perfect/own/ratios': [1.0, 1.5, 1.2] } }, { rule: 'xref:beat-cue-order', pointer: '/perfect/own/ratios/2' });
  cs('own-ratios-equal', { set: { '/perfect/own/ratios': [1.0, 1.2, 1.2] } }, { rule: 'xref:beat-cue-order', pointer: '/perfect/own/ratios/2' });
  cs('foe-ratios-fall', { set: { '/perfect/foe/ratios': [1.5, 1.2] } }, { rule: 'xref:beat-cue-order', pointer: '/perfect/foe/ratios/1' });
  cs('ratios-rise-ok', { set: { '/perfect/own/ratios': [1.0, 1.1, 1.3, 1.5] } }, null);
  cs('spark-clear-order', { set: { '/perfect/spark_clear/ticks': 8, '/perfect/spark_clear/max_wait': 6 } }, { rule: 'xref:beat-cue-order', pointer: '/perfect/spark_clear/ticks' });
  cs('spark-clear-equal-ok', { set: { '/perfect/spark_clear/ticks': 6, '/perfect/spark_clear/max_wait': 6 } }, null);
  cs('bus-ok', { set: { '/charge_y/full/bus': busName } }, null);
  let n = 0;
  for (const k of out) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (!same(c.cases[i], k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`audio beat cues schema applied (${n} new or changed cases)`);
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  const t = fs.readFileSync(f, 'utf8');
  if (!t.includes('`beat-cue-sound`')) {
    const lines = t.split('\n');
    const i = lines.findIndex((l) => l.includes('`brawl-cue-sound`'));
    if (i < 0) throw new Error('beat cues README anchor');
    lines.splice(i + 1, 0, '| `beat-cue-sound`, `beat-cue-bus`, `beat-cue-order` | audio/data/beat_cues.json: every sound a cue names is synthesised in impacts.json; every bus is a bus of mix.json; the chord ratios of the perfect chain rise strictly and the spark\'s clear ticks are at most its longest wait |');
    fs.writeFileSync(f, lines.join('\n'));
  }
}
