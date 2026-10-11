// The schema for Audio's audio/data/brawl_cues.json (how the brawl's cues become sound: audio/audio_brawl.gd, docs/audio/brawl-cues.md): tools/schemas/audio-brawl-cues.schema.json,
// its map.json rule, the cross-references (tools/lib/xref-brawl-cues.js, from docs/tools/pending/xref-brawl-cues.js) and the cases. NOT run by CI, the validator or the sim. Run once
// from the repo root, in a commit that is not mid-way through another schema script (it edits tools/schemas/map.json, tools/lib/xref-fight.js, tools/fixtures/cases.json and
// docs/tools/README.md like the others do):
//     node docs/tools/pending/apply-audio-brawl-cues.cjs
// It does NOT edit audio/data/. Policy: closed except keys starting with an underscore, and the `note` string Audio keeps beside its numbers. Every cue object has the same
// shape (sound, cls, cap, priority, gain_db, caption where it has one); numbers are bounded generously (gain_db -60 to 24 and so on) because Audio tunes them.
// Cross-references (rules in the README table): brawl-cue-sound (every sound is synthesised in impacts.json), brawl-cue-bus (every bus is a bus of mix.json: Alert, Sfx and Music
// today; mix.json's own schema names no bus, only the shape of one, so it needs nothing), brawl-cue-order (the min below the max of each range, medium_from below heavy_from,
// the wind-up classes rising). Every case sets its own values. Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const clone = (o) => JSON.parse(JSON.stringify(o));
const closed = { additionalProperties: false, patternProperties: { '^_': true } };

// ---- leaves: { k, d } with k one of the kinds below
const ID = '^[a-z][a-z0-9_]*([.][a-z0-9_]+)*$';
const KIND = {
  str: (d) => ({ type: 'string', minLength: 1, description: d }),
  snd: (d) => ({ type: 'string', pattern: ID, description: d + ' (a sound synthesised in impacts.json: brawl-cue-sound)' }),
  bus: (d) => ({ type: 'string', pattern: '^[A-Za-z][A-Za-z0-9]*$', description: d + ' (a bus of mix.json: brawl-cue-bus)' }),
  i0: (d) => ({ type: 'integer', minimum: 0, description: d }),
  i1: (d) => ({ type: 'integer', minimum: 1, description: d }),
  db: (d) => ({ type: 'number', minimum: -60, maximum: 24, description: d }),
  pos: (d) => ({ type: 'number', exclusiveMinimum: 0, description: d }),
  n0: (d) => ({ type: 'number', minimum: 0, description: d }),
  num: (d) => ({ type: 'number', description: d }),
  bool: (d) => ({ type: 'boolean', description: d }),
  strs: (d) => ({ type: 'array', items: { type: 'string' }, description: d }),
  ints: (d) => ({ type: 'array', minItems: 1, items: { type: 'integer', minimum: 0 }, description: d }),
};
const L = (k, d) => ({ __leaf: true, k, d });
const isLeaf = (x) => x && x.__leaf === true;
const O = (props, o = {}) => ({ __obj: true, props, required: o.required, note: o.note !== false });
const sc = (n) => (isLeaf(n) ? (n.k === 'schema' ? { const: 1 } : KIND[n.k](n.d)) : n.__arr ? n.schema : n.__map ? FROM_BLOW : objSchema(n));
function objSchema(n) {
  const props = Object.fromEntries(Object.entries(n.props).map(([k, v]) => [k, sc(v)]));
  if (n.note) props.note = { type: 'string', description: 'A note for the next person (the generator of this file keeps one beside its numbers).' };
  return Object.assign({ type: 'object', required: n.required || Object.keys(n.props), properties: props }, closed);
}
const ARR = (schema) => ({ __arr: true, schema });

// a cue: the fields most cues have; `extra` adds the rest
const cue = (extra = {}, keys = ['sound', 'cls', 'cap', 'priority', 'gain_db', 'caption'], req) => O(Object.assign(Object.fromEntries(keys.map((k) => [k, { sound: L('snd', 'The sound.'), cls: L('str', 'The class (the voice-limit group).'), cap: L('i1', 'How many of its class may play at once.'), priority: L('i0', 'Its priority when voices run out.'), gain_db: L('db', 'Gain, dB.'), caption: L('str', 'The caption.') }[k]])), extra), { required: req });
const land = O({ gain_db: L('db', 'Gain, dB.'), pitch: L('pos', 'Pitch ratio.'), sound: Object.assign(L('snd', 'Its own sound.'), { _req: false }) }, { required: ['gain_db', 'pitch'], note: false });
const landAll = O({ hit: land, guard: land, armour: land, miss: land });
const SPEC = O({
  schema: { __leaf: true, k: 'schema', d: '' },
  strength: O({
    from_blow: { __map: true },
    blow_window_ticks: L('i0', 'Ticks a blow cue stays attributable.'),
    fallback_amounts: O({ medium_from: L('n0', 'Damage from which a hit reads medium.'), heavy_from: L('n0', 'Damage from which a hit reads heavy (above medium_from: brawl-cue-order).') }, { note: false }),
    kind_is_strength: L('bool', 'Whether the hit kind is itself the strength.'),
  }, { note: false }),
  hit: O({
    light: cue(), medium: cue(), heavy: cue(),
    guard: cue({ pitch: O({ light: L('pos', 'Pitch.'), medium: L('pos', 'Pitch.'), heavy: L('pos', 'Pitch.') }, { note: false }) }),
    size_ref: L('pos', 'The reference size.'), pitch_exp: L('num', 'Exponent.'), pitch_min: L('pos', 'Lowest pitch ratio (at most pitch_max).'), pitch_max: L('pos', 'Highest pitch ratio.'),
    gain_exp: L('num', 'Exponent.'), gain_db_min: L('db', 'Lowest gain (at most gain_db_max).'), gain_db_max: L('db', 'Highest gain.'),
  }),
  flurry: O({ window_ticks: L('i1', 'Window.'), after: L('i0', 'Blows before the climb starts.'), step_db: L('db', 'Step per blow, dB.'), climb_st_per_blow: L('n0', 'Semitones per blow.'), climb_max_st: L('n0', 'Most semitones.'), close_db: L('db', 'The close, dB.') }),
  launcher: O({
    sound: L('snd', 'The sound.'), gain_db: L('db', 'Gain, dB.'), priority: L('i0', 'Priority.'), cls: L('str', 'Class.'), cap: L('i1', 'Cap.'), caption: L('str', 'Caption.'),
    min_ticks: L('i0', 'The shortest it is heard.'),
    duck: ARR({ type: 'array', items: Object.assign({ type: 'object', required: ['bus', 'db', 'ms'], properties: { bus: KIND.bus('The bus ducked.'), db: KIND.db('By how much, dB.'), ms: KIND.i0('Over how long, ms.') } }, closed), description: 'What it ducks.' }),
    close: O({ stop_texts: L('strs', 'Cue texts that end it.'), stop_k: L('ints', 'Cue kinds that end it.'), stop_ms: L('i0', 'Fade out, ms.') }, { note: false }),
    bus: L('bus', 'The bus it plays on.'),
  }),
  windup: O({
    min_ticks: L('i0', 'The shortest wind-up that is heard.'),
    classes: ARR({ type: 'array', minItems: 1, items: Object.assign({ type: 'object', required: ['max_ticks', 'sound', 'nominal_ticks'], properties: { max_ticks: KIND.i1('Up to this many ticks (rising: brawl-cue-order).'), sound: KIND.snd('The sound.'), nominal_ticks: KIND.i1('The wind-up it is made for.') } }, closed), description: 'The classes of wind-up, by length.' }),
    gain_db: L('db', 'Gain.'), priority: L('i0', 'Priority.'), cls: L('str', 'Class.'), cap: L('i1', 'Cap.'), pitch_min: L('pos', 'Lowest pitch (at most pitch_max).'), pitch_max: L('pos', 'Highest pitch.'),
    end: O({ stop_k: L('ints', 'Cue kinds that end it.'), stop_ms: L('i0', 'Fade out, ms.') }, { note: false }),
  }),
  miss: O({
    sound: L('snd', 'The sound.'), priority: L('i0', 'Priority.'), cls: L('str', 'Class.'), cap: L('i1', 'Cap.'), caption: L('str', 'Caption.'),
    gave_ground: O({ gain_db: L('db', 'Gain.'), pitch: L('pos', 'Pitch.') }, { note: false }), reach: O({ gain_db: L('db', 'Gain.'), pitch: L('pos', 'Pitch.') }, { note: false }), dodge: O({ gain_db: L('db', 'Gain.'), pitch: L('pos', 'Pitch.') }, { note: false }),
  }),
  double: O({
    charge: O({ sound: L('snd', 'The sound.'), gain_db: L('db', 'Gain.'), nominal_ticks: L('i1', 'Nominal length.'), priority: L('i0', 'Priority.'), cls: L('str', 'Class.'), cap: L('i1', 'Cap.') }, { note: false }),
    hit: O({ sound: L('snd', 'The sound.'), gain_db: L('db', 'Gain.'), priority: L('i0', 'Priority.'), cls: L('str', 'Class.'), cap: L('i1', 'Cap.'), caption: L('str', 'Caption.'), landing_ticks: L('i0', 'Ticks.') }, { note: false }),
  }, { note: false }),
  energy: O({
    gather: O({ sound: L('snd', 'The sound.'), nominal_ticks: L('i1', 'Nominal length.'), gain_db: L('db', 'Gain.'), priority: L('i0', 'Priority.'), cls: L('str', 'Class.'), cap: L('i1', 'Cap.'), pitch_min: L('pos', 'Lowest pitch (at most pitch_max).'), pitch_max: L('pos', 'Highest pitch.') }, { note: false }),
    bolt: O({ sound: L('snd', 'The sound.'), lite: L('snd', 'The lighter sound.'), priority: L('i0', 'Priority.'), cls: L('str', 'Class.'), cap: L('i1', 'Cap.'), caption: L('str', 'Caption.'), window_ticks: L('i1', 'Window.'), after: L('i0', 'After.'), step_db: L('db', 'Step, dB.'), land: landAll }, { note: false }),
    blast: O({ sound: L('snd', 'The sound.'), priority: L('i0', 'Priority.'), cls: L('str', 'Class.'), cap: L('i1', 'Cap.'), caption: L('str', 'Caption.'), land: landAll }, { note: false }),
  }),
  charge: O({
    heavy_over_ticks: L('i1', 'A hold over this many ticks is a heavy.'),
    hum: O({ sound: L('snd', 'The sound.'), from_live: L('i0', 'From this live tick.'), gain_db: L('db', 'Gain.'), priority: L('i0', 'Priority.'), cls: L('str', 'Class.'), cap: L('i1', 'Cap.'), stop_ms: L('i0', 'Fade, ms.') }, { note: false }),
    full: O({ sound: L('snd', 'The sound.'), gain_db: L('db', 'Gain.'), priority: L('i0', 'Priority.'), bus: L('bus', 'The bus.'), cls: L('str', 'Class.'), cap: L('i1', 'Cap.'), texts: L('strs', 'Cue texts.'), caption: L('str', 'Caption.') }, { note: false }),
    armour: O({ sound: L('snd', 'The sound.'), gain_db: L('db', 'Gain.'), priority: L('i0', 'Priority.'), cls: L('str', 'Class.'), cap: L('i1', 'Cap.'), medium_after_live: L('i0', 'Ticks.'), medium_pitch: L('pos', 'Pitch.') }, { note: false }),
  }),
}, { note: true });

// from_blow: a blow cue text to a strength word (or "")
const FROM_BLOW = Object.assign({ type: 'object', minProperties: 1, propertyNames: { pattern: '^(_.*|[a-z][a-z0-9_]*)$' }, additionalProperties: { enum: ['light', 'medium', 'heavy', ''] }, patternProperties: { '^_': true }, description: 'A blow cue text to the strength it reads as (light, medium, heavy, or "" for none).' });
function build() {
  const s = objSchema(SPEC);
  s.properties.schema = { const: 1 };
  s.properties.note = { type: 'string', minLength: 1, description: 'How the brawl cues become sound.' };
  s.required = [...s.required, 'note'];
  return Object.assign({
    $schema: 'https://json-schema.org/draft/2020-12/schema', $id: 'meridian/audio-brawl-cues', title: 'audio brawl cues (schema 1)',
    description: 'audio/data/brawl_cues.json: how the brawl\'s cues become sound (audio/audio_brawl.gd, docs/audio/brawl-cues.md): strength from the blow cue, the hit sounds and their pitch and gain law, the flurry\'s climb, the launcher, the wind-up, the miss, the double, energy in reach and the charge. Version field: schema. Policy: closed except keys starting with an underscore (and the `note` string beside the numbers). Cross-references in tools/lib/xref-brawl-cues.js (brawl-cue-sound, brawl-cue-bus, brawl-cue-order).',
  }, s);
}

// =============================== schema, map, xref ===============================
{
  const f = 'tools/schemas/audio-brawl-cues.schema.json';
  if (!fs.existsSync(f)) wj(f, build());
  const mf = 'tools/schemas/map.json';
  const m = rj(mf);
  if (!m.rules.some((r) => r.match === 'audio/data/brawl_cues.json')) {
    const i = m.rules.findIndex((r) => r.match === 'audio/data/impacts.json');
    m.rules.splice(i < 0 ? m.rules.length : i + 1, 0, { match: 'audio/data/brawl_cues.json', schema: 'audio-brawl-cues.schema.json' });
    wj(mf, m);
  }
  fs.copyFileSync('docs/tools/pending/xref-brawl-cues.js', 'tools/lib/xref-brawl-cues.js');
  const xf = 'tools/lib/xref-fight.js';
  let t = fs.readFileSync(xf, 'utf8');
  if (!t.includes("require('./xref-brawl-cues')")) {
    const a = 'function xrefFight({ get, err, esc, isObj, plainKeys, docsFor }) {\n';
    if (!t.includes(a)) throw new Error('brawl cues xref anchor');
    t = t.replace(a, () => a + "  require('./xref-brawl-cues').xrefBrawlCues({ get, err, esc, isObj });\n");
    fs.writeFileSync(xf, t);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const F = 'audio/data/brawl_cues.json';
  const data = rj(F);
  const mix = rj('audio/data/mix.json');
  const busName = mix.buses[0].name;
  const out = [];
  const cs = (id, mutate, expect) => out.push({ id: 'audio-brawl-cues-' + id, schema: 'audio-brawl-cues.schema.json', mutate: [{ file: F, ...mutate }], expect });
  const slug = (path) => path.join('-').replace(/_/g, '-').toLowerCase();
  const ptr = (path) => path.map((p) => '/' + p).join('');
  const val = (path) => path.reduce((a, k) => a[k], data);
  cs('valid', { set: { '/schema': 1 } }, null);
  for (const k of ['schema', 'note', 'strength', 'hit', 'flurry', 'launcher', 'windup', 'miss', 'double', 'energy', 'charge']) cs('key-required-' + k, { del: ['/' + k] }, { rule: 'required', pointer: '' });
  cs('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' });
  cs('note-key-ok', { set: { '/_why': 'a note' } }, null);
  cs('schema-version', { set: { '/schema': 2 } }, { rule: 'const', pointer: '/schema' });
  // every leaf of the spec that the data has: required, type and the kind's bounds
  const walk = (n, path) => {
    if (isLeaf(n)) {
      const P = ptr(path), parent = ptr(path.slice(0, -1)), s = slug(path);
      let v;
      try { v = val(path); } catch { v = undefined; }
      if (v === undefined) return;
      const k = n.k;
      if (k === 'schema') return;
      const reqs = (n._req !== false);
      if (reqs) cs(s + '-required', { del: [P] }, { rule: 'required', pointer: parent });
      if (k === 'str' || k === 'snd' || k === 'bus') {
        cs(s + '-type', { set: { [P]: 5 } }, { rule: 'type', pointer: P });
        cs(s + '-empty', { set: { [P]: '' } }, { rule: k === 'str' ? 'minLength' : 'pattern', pointer: P });
        if (k === 'snd') cs(s + '-shape', { set: { [P]: 'Hit Light' } }, { rule: 'pattern', pointer: P });
        if (k === 'snd') cs(s + '-not-synthesised', { set: { [P]: 'impact.nowhere' } }, { rule: 'xref:brawl-cue-sound', pointer: P });
        if (k === 'bus') cs(s + '-not-a-bus', { set: { [P]: 'NoSuchBus' } }, { rule: 'xref:brawl-cue-bus', pointer: P });
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
      } else if (k === 'bool') {
        cs(s + '-type', { set: { [P]: 1 } }, { rule: 'type', pointer: P });
      } else if (k === 'strs') {
        cs(s + '-type', { set: { [P]: 'a' } }, { rule: 'type', pointer: P });
        cs(s + '-item-type', { set: { [P]: [1] } }, { rule: 'type', pointer: P + '/0' });
      } else if (k === 'ints') {
        cs(s + '-empty', { set: { [P]: [] } }, { rule: 'minItems', pointer: P });
        cs(s + '-item-negative', { set: { [P]: [-1] } }, { rule: 'minimum', pointer: P + '/0' });
      }
      return;
    }
    if (n.__arr || n.__map) return;
    const P = ptr(path);
    if (path.length) {
      cs(slug(path) + '-type', { set: { [P]: 5 } }, { rule: 'type', pointer: P });
      cs(slug(path) + '-unknown-key', { set: { [P + '/extra']: 1 } }, { rule: 'additionalProperties', pointer: P + '/extra' });
      cs(slug(path) + '-required', { del: [P] }, { rule: 'required', pointer: ptr(path.slice(0, -1)) });
    }
    for (const [k, v] of Object.entries(n.props)) walk(v, path.concat(k));
  };
  walk(SPEC, []);
  // the arrays and the map
  cs('from-blow-value', { set: { '/strength/from_blow/light': 'loud' } }, { rule: 'enum', pointer: '/strength/from_blow/light' });
  cs('from-blow-empty-ok', { set: { '/strength/from_blow/release': '' } }, null);
  cs('from-blow-empty-object', { set: { '/strength/from_blow': {} } }, { rule: 'minProperties', pointer: '/strength/from_blow' });
  cs('duck-bus-not-a-bus', { set: { '/launcher/duck/0/bus': 'NoSuchBus' } }, { rule: 'xref:brawl-cue-bus', pointer: '/launcher/duck/0/bus' });
  cs('duck-bus-ok', { set: { '/launcher/duck/0/bus': busName } }, null);
  cs('duck-entry-key-missing', { del: ['/launcher/duck/0/ms'] }, { rule: 'required', pointer: '/launcher/duck/0' });
  cs('duck-entry-unknown-key', { set: { '/launcher/duck/0/extra': 1 } }, { rule: 'additionalProperties', pointer: '/launcher/duck/0/extra' });
  cs('duck-db-above', { set: { '/launcher/duck/0/db': 30 } }, { rule: 'maximum', pointer: '/launcher/duck/0/db' });
  cs('classes-empty', { set: { '/windup/classes': [] } }, { rule: 'minItems', pointer: '/windup/classes' });
  cs('classes-sound-not-synthesised', { set: { '/windup/classes/0/sound': 'windup.nowhere' } }, { rule: 'xref:brawl-cue-sound', pointer: '/windup/classes/0/sound' });
  cs('classes-max-ticks-falls', { set: { '/windup/classes/0/max_ticks': 999, '/windup/classes/1/max_ticks': 20 } }, { rule: 'xref:brawl-cue-order', pointer: '/windup/classes/1/max_ticks' });
  cs('classes-max-ticks-zero', { set: { '/windup/classes/0/max_ticks': 0 } }, { rule: 'minimum', pointer: '/windup/classes/0/max_ticks' });
  // order rules
  cs('hit-pitch-order', { set: { '/hit/pitch_min': 1.3, '/hit/pitch_max': 1.0 } }, { rule: 'xref:brawl-cue-order', pointer: '/hit/pitch_min' });
  cs('hit-pitch-equal-ok', { set: { '/hit/pitch_min': 1.0, '/hit/pitch_max': 1.0 } }, null);
  cs('hit-gain-order', { set: { '/hit/gain_db_min': 3, '/hit/gain_db_max': 1 } }, { rule: 'xref:brawl-cue-order', pointer: '/hit/gain_db_min' });
  cs('windup-pitch-order', { set: { '/windup/pitch_min': 1.5, '/windup/pitch_max': 1.0 } }, { rule: 'xref:brawl-cue-order', pointer: '/windup/pitch_min' });
  cs('gather-pitch-order', { set: { '/energy/gather/pitch_min': 1.5, '/energy/gather/pitch_max': 1.0 } }, { rule: 'xref:brawl-cue-order', pointer: '/energy/gather/pitch_min' });
  cs('fallback-order', { set: { '/strength/fallback_amounts/medium_from': 70, '/strength/fallback_amounts/heavy_from': 60 } }, { rule: 'xref:brawl-cue-order', pointer: '/strength/fallback_amounts/medium_from' });
  cs('fallback-equal', { set: { '/strength/fallback_amounts/medium_from': 60, '/strength/fallback_amounts/heavy_from': 60 } }, { rule: 'xref:brawl-cue-order', pointer: '/strength/fallback_amounts/medium_from' });
  let n = 0;
  for (const k of out) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (JSON.stringify(c.cases[i]) !== JSON.stringify(k)) { c.cases[i] = k; n++; }
  }
  wj(cf, c);
  console.log(`audio brawl cues schema applied (${n} new cases)`);
  void clone;
}

// =============================== docs ===============================
{
  const f = 'docs/tools/README.md';
  const t = fs.readFileSync(f, 'utf8');
  if (!t.includes('`brawl-cue-sound`')) {
    const lines = t.split('\n');
    const i = ['`ui-colour-choices`', '`colour-vision-fighters`', '`reach-keyset`', '`brawl-order`'].map((k) => lines.findIndex((l) => l.includes(k))).find((x) => x >= 0);
    if (i === undefined) throw new Error('brawl cues README anchor');
    lines.splice(i + 1, 0, "| `brawl-cue-sound`, `brawl-cue-bus`, `brawl-cue-order` | audio/data/brawl_cues.json: every sound is synthesised in impacts.json; every bus is a bus of mix.json; each pitch and gain range has its min at most its max, `medium_from` is below `heavy_from` and the wind-up classes rise |");
    fs.writeFileSync(f, lines.join('\n'));
  }
}
