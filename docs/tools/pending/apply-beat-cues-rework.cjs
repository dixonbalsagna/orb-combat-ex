// Audio's rework of the perfect chain (docs/audio/brawl-rework.md, 2026-10-16): audio/data/beat_cues.json's /perfect now holds one chain sound for both sides (spark, hit), no own, foe or link.
// Land this in the same commit as Audio's files (audio/data/beat_cues.json and docs/audio/proposed/audio-beat-cues.schema.json):
//     node docs/tools/pending/apply-beat-cues-rework.cjs
// 1. tools/schemas/audio-beat-cues.schema.json is Audio's proposed schema, copied.
// 2. tools/lib/xref-beat-cues.js: beat-cue-order reads perfect.spark.ratios (rising) and no longer perfect.own and perfect.foe; the header says so.
// 3. tools/fixtures/cases.json: every audio-beat-cues-* case is regenerated from the new schema (a leaf's required, type, bounds and, for a sound or a bus, its cross-reference; an object's type,
//    unknown key and required), plus the order and bus cases. The old cases of the own, foe and link shapes go.
// Re-runnable (a second run changes nothing). Refuses until Audio's schema and data are in the tree. Not run by CI or the validator.
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const F = 'audio/data/beat_cues.json', PROPOSED = 'docs/audio/proposed/audio-beat-cues.schema.json', SCHEMA = 'tools/schemas/audio-beat-cues.schema.json';
for (const f of [F, PROPOSED]) if (!fs.existsSync(f)) { console.error(`${f} is not in the tree: run this in the commit that lands Audio's files`); process.exit(1); }

// ---- 1. the schema
{
  const a = fs.readFileSync(PROPOSED, 'utf8').replace(/\r\n/g, '\n');
  const b = fs.existsSync(SCHEMA) ? fs.readFileSync(SCHEMA, 'utf8').replace(/\r\n/g, '\n') : '';
  if (a === b) console.log('schema: already');
  else { fs.writeFileSync(SCHEMA, a); console.log('schema: Audio\'s proposed schema copied'); }
}

// ---- 2. the cross-reference
{
  const f = 'tools/lib/xref-beat-cues.js';
  let t = fs.readFileSync(f, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  if (t.includes("rise(d.perfect.spark.ratios")) console.log('xref: already');
  else {
    const rep = (a, b) => { if (!t.includes(a)) throw new Error('anchor: ' + a.slice(0, 70)); t = t.replace(a, () => b); };
    rep("//   beat-cue-order  the chord ratios of perfect.own and perfect.foe rise strictly; spark_clear.ticks is at most spark_clear.max_wait",
      "//   beat-cue-order  the chord ratios of perfect.spark (the one chain sound for both sides, reworked 2026-10-16) rise strictly; spark_clear.ticks is at most spark_clear.max_wait");
    rep("    if (isObj(d.perfect.own)) rise(d.perfect.own.ratios, '/perfect/own/ratios');\n    if (isObj(d.perfect.foe)) rise(d.perfect.foe.ratios, '/perfect/foe/ratios');\n",
      "    if (isObj(d.perfect.spark)) rise(d.perfect.spark.ratios, '/perfect/spark/ratios');\n");
    rep("      else if (k === 'note' && path.endsWith('/foe')) checkSound(v, here);   // the opponent's note: this key names a sound there\n", '');
    rep("//   beat-cue-sound  every sound a cue names (a `sound`, `close`, `spark` or `note` value of the chain's blocks, `by_strength.*`, `grind.sound`, `rest.sound`, `charge_y.*.sound`) is synthesised in",
      "//   beat-cue-sound  every sound a cue names (a `sound` value: `perfect.spark`, `tick`, `broken`, `grind`, `rest`, `charge_y.*`) is synthesised in");
    fs.writeFileSync(f, crlf ? t.replace(/\n/g, '\r\n') : t);
    console.log('xref: perfect.spark.ratios read; own, foe and link gone');
  }
}

// ---- 3. the cases, from the new schema
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const sch = rj(SCHEMA);
  const data = rj(F);
  const mix = rj('audio/data/mix.json');
  const busName = mix.buses[0].name;
  // a leaf's kind from its schema
  const kindOf = (n) => {
    if (n.type === 'string') {
      if (n.pattern === '^[A-Za-z][A-Za-z0-9]*$') return 'bus';
      if (n.pattern) return 'snd';
      return n.minLength ? 'str' : 'strE';
    }
    if (n.type === 'integer') return n.minimum === 1 ? 'i1' : 'i0';
    if (n.type === 'number') {
      if (n.minimum === -60) return 'db';
      if (n.exclusiveMinimum === 0) return 'pos';
      return n.minimum === 0 ? 'n0' : 'num';
    }
    if (n.type === 'array') return n.items.type === 'string' ? 'strs' : 'poss';
    throw new Error('beat cues: no kind for ' + JSON.stringify(n).slice(0, 80));
  };
  const out = [];
  const cs = (id, mutate, expect) => out.push({ id: 'audio-beat-cues-' + id, schema: 'audio-beat-cues.schema.json', mutate: [{ file: F, ...mutate }], expect });
  const slug = (path) => path.join('-').replace(/_/g, '-').toLowerCase();
  const ptr = (path) => path.map((p) => '/' + p).join('');
  const val = (path) => path.reduce((a, k) => a[k], data);
  cs('valid', { set: { '/schema': 1 } }, null);
  for (const k of sch.required.filter((k) => k !== 'schema')) cs('key-required-' + k.replace(/_/g, '-'), { del: ['/' + k] }, { rule: 'required', pointer: '' });
  cs('key-required-schema', { del: ['/schema'] }, { rule: 'required', pointer: '' });
  cs('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' });
  cs('note-key-ok', { set: { '/_why': 'a note' } }, null);
  cs('schema-version', { set: { '/schema': 2 } }, { rule: 'const', pointer: '/schema' });
  const leaf = (n, path) => {
    let v;
    try { v = val(path); } catch { v = undefined; }
    if (v === undefined) return;
    const k = kindOf(n), P = ptr(path), parent = ptr(path.slice(0, -1)), s = slug(path);
    cs(s + '-required', { del: [P] }, { rule: 'required', pointer: parent });
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
      if (n.minItems) cs(s + '-empty', { set: { [P]: [] } }, { rule: 'minItems', pointer: P });
      cs(s + '-item-type', { set: { [P]: [1] } }, { rule: 'type', pointer: P + '/0' });
    } else if (k === 'poss') {
      cs(s + '-type', { set: { [P]: 1 } }, { rule: 'type', pointer: P });
      cs(s + '-empty', { set: { [P]: [] } }, { rule: 'minItems', pointer: P });
      cs(s + '-item-zero', { set: { [P]: [0, 1.2] } }, { rule: 'exclusiveMinimum', pointer: P + '/0' });
      cs(s + '-item-type', { set: { [P]: ['x'] } }, { rule: 'type', pointer: P + '/0' });
    }
  };
  const walk = (n, path) => {
    if (n.type !== 'object' || !n.properties) { leaf(n, path); return; }
    const P = ptr(path);
    if (path.length) {
      cs(slug(path) + '-type', { set: { [P]: 5 } }, { rule: 'type', pointer: P });
      cs(slug(path) + '-unknown-key', { set: { [P + '/extra']: 1 } }, { rule: 'additionalProperties', pointer: P + '/extra' });
      cs(slug(path) + '-required', { del: [P] }, { rule: 'required', pointer: ptr(path.slice(0, -1)) });
    }
    for (const [k, v] of Object.entries(n.properties)) {
      if (k === 'schema' || (k === 'note' && path.length)) continue;   // the version, and the free note beside a block's numbers
      if (path.length === 0 && k === 'note') continue;
      walk(v, path.concat(k));
    }
  };
  walk(sch, []);
  // the cross-references
  cs('spark-ratios-fall', { set: { '/perfect/spark/ratios': [1.0, 1.5, 1.2] } }, { rule: 'xref:beat-cue-order', pointer: '/perfect/spark/ratios/2' });
  cs('spark-ratios-equal', { set: { '/perfect/spark/ratios': [1.0, 1.2, 1.2] } }, { rule: 'xref:beat-cue-order', pointer: '/perfect/spark/ratios/2' });
  cs('ratios-rise-ok', { set: { '/perfect/spark/ratios': [1.0, 1.1, 1.3, 1.5] } }, null);
  cs('spark-clear-order', { set: { '/perfect/spark_clear/ticks': 8, '/perfect/spark_clear/max_wait': 6 } }, { rule: 'xref:beat-cue-order', pointer: '/perfect/spark_clear/ticks' });
  cs('spark-clear-equal-ok', { set: { '/perfect/spark_clear/ticks': 6, '/perfect/spark_clear/max_wait': 6 } }, null);
  cs('bus-ok', { set: { '/charge_y/full/bus': busName } }, null);
  const mine = (x) => x.id.startsWith('audio-beat-cues-');
  const before = c.cases.filter(mine);
  const keep = c.cases.filter((x) => !mine(x));
  // keep the cases' place in the file: the first old one's position, else the end
  const at = c.cases.findIndex(mine);
  const next = at < 0 ? keep.concat(out) : keep.slice(0, at).concat(out, keep.slice(at));
  const changed = before.length !== out.length || out.some((k, i) => !same(before[i], k));
  if (changed) { c.cases = next; wj(cf, c); }
  console.log(`cases: ${changed ? `${before.length} old audio-beat-cues cases replaced by ${out.length}` : 'already'}`);
}
