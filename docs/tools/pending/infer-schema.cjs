// Tools' helper for the data files that arrive without a schema: it reads the file that is in the tree and writes a CLOSED schema of its shape (every key present is required, a key outside is
// refused unless it starts with an underscore), the map.json rule and the cases (a valid one, each required key missing, an unknown key, the version wrong, a wrong type at each leaf up to a cap).
// It is a shape check, not a ruling on values: a number is bounded only where the file's own numbers say so (never negative where none is), a colour is a hex string, an id is a lower-case word.
// A person who knows the values (the owner of the file) tightens the schema afterwards.
//     node docs/tools/pending/infer-schema.cjs <data file> <schema name, e.g. art-polar> <version key: version|schema> [--maps a.b,c] [--match glob] [--case-file path] [--policy "text"] [--check]
// --maps: dotted paths whose objects are MAPS (any key, one shape: the shape is taken from the keys all their values share; the others are optional).
// Re-runnable: a second run changes nothing. Refuses a file that is not in the tree. Not run by CI or the validator.
const fs = require('fs');
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 ? argv[i + 1] : d; };
const pos = argv.filter((a, i) => !a.startsWith('--') && !(i > 0 && ['--maps', '--policy', '--match', '--case-file'].includes(argv[i - 1])));
const [FILE, NAME, VKEY] = pos;
if (!FILE || !NAME || !VKEY) { console.error('usage: node infer-schema.cjs <data file> <schema name> <version|schema> [--maps a.b,c] [--policy text] [--check]'); process.exit(2); }
if (!fs.existsSync(FILE)) { console.error(`${FILE} is not in the tree`); process.exit(1); }
const check = argv.includes('--check');
const MAPS = new Set((opt('--maps', '') || '').split(',').filter(Boolean));
const data = JSON.parse(fs.readFileSync(FILE, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const HEX = /^#[0-9a-f]{6}$/i;
const isObj = (x) => x && typeof x === 'object' && !Array.isArray(x);
const closed = { additionalProperties: false, patternProperties: { '^_': true } };
const KEYPAT = '^(_.*|[A-Za-z0-9].*)$';

function leafSchema(vals, key) {
  const t = new Set(vals.map((v) => (Array.isArray(v) ? 'array' : v === null ? 'null' : typeof v)));
  if (t.size === 1) {
    const k = [...t][0];
    if (k === 'boolean') return { type: 'boolean' };
    if (k === 'string') {
      if (vals.every((v) => HEX.test(v))) return { type: 'string', pattern: '^#[0-9a-fA-F]{6}$' };
      return { type: 'string' };
    }
    if (k === 'number') {
      const ints = vals.every((v) => Number.isInteger(v));
      const nonneg = vals.every((v) => v >= 0) && !/(db|gain|pitch|offset|st$|detune|lean|twist|bias|delta|dx|dy|sign)/i.test(key || '');
      return { type: ints && /(ticks|count|cap|priority|parts|triangles|rate|mass|tier|bits|pulses|variants|steps|n$)/i.test(key || '') ? 'integer' : 'number', ...(nonneg ? { minimum: 0 } : {}) };
    }
    if (k === 'array') return arrSchema(vals, key);
    if (k === 'null') return { type: 'null' };
  }
  return {};   // mixed: any
}
function arrSchema(arrs, key) {
  const all = arrs.flat();
  const lens = new Set(arrs.map((a) => a.length));
  const s = { type: 'array' };
  if (all.length) {
    if (all.every(isObj)) s.items = objSchema(all, '', false);
    else if (all.every((x) => !isObj(x) && !Array.isArray(x))) s.items = leafSchema(all, key);
    else if (all.every(Array.isArray)) s.items = arrSchema(all, key);
  }
  if (lens.size === 1 && [...lens][0] <= 4 && [...lens][0] > 0) { s.minItems = [...lens][0]; s.maxItems = [...lens][0]; }
  return s;
}
// the schema of a set of objects seen at one place (all must have each required key)
function objSchema(objs, path, isMap) {
  const keysets = objs.map((o) => Object.keys(o).filter((k) => !k.startsWith('_')));
  const allKeys = [...new Set(keysets.flat())];
  const common = allKeys.filter((k) => keysets.every((ks) => ks.includes(k)));
  const props = {};
  for (const k of allKeys) {
    const vals = objs.map((o) => o[k]).filter((v) => v !== undefined);
    props[k] = sub(vals, path ? `${path}.${k}` : k, k);
  }
  return { type: 'object', required: common, properties: props, ...closed };
}
function sub(vals, path, key) {
  if (vals.every(isObj)) {
    if (MAPS.has(path)) {
      const all = vals.flatMap((o) => Object.entries(o).filter(([k]) => !k.startsWith('_')).map(([, v]) => v));
      const allObj = all.length && all.every(isObj);
      const entry = allObj ? objSchema(all, path + '.*', false) : leafSchema(all, key);
      return { type: 'object', minProperties: 1, propertyNames: { pattern: KEYPAT }, additionalProperties: entry, patternProperties: { '^_': true } };
    }
    return objSchema(vals, path, false);
  }
  return leafSchema(vals, key);
}

const root = objSchema([data], '', false);
root.properties[VKEY] = VKEY === 'schema' && typeof data.schema === 'string' ? { const: data.schema } : { const: data[VKEY] };
root.required = [...new Set([VKEY, ...root.required])];
const out = Object.assign({
  $schema: 'https://json-schema.org/draft/2020-12/schema', $id: `meridian/${NAME}`, title: `${NAME} (${VKEY} ${JSON.stringify(data[VKEY])})`,
  description: `${FILE}: ${opt('--policy', 'the shape of the file as its owner wrote it')}. A shape check inferred from the file (docs/tools/pending/infer-schema.cjs): every key present is required, a key outside is refused unless it starts with an underscore, a number is bounded only below by zero where all its values are, a colour is a hex string; the owner tightens the values. Version field: ${VKEY}. Policy: closed except keys starting with an underscore.`,
}, root);

const sf = `tools/schemas/${NAME}.schema.json`;
const mf = 'tools/schemas/map.json';
const cf = 'tools/fixtures/cases.json';
const changed = [];
if (!(fs.existsSync(sf) && same(JSON.parse(fs.readFileSync(sf, 'utf8')), out))) { changed.push('schema'); if (!check) wj(sf, out); }
const m = JSON.parse(fs.readFileSync(mf, 'utf8'));
const CASEFILE = opt('--case-file', FILE);   // the file the cases change: for a fighter's file, a virtual fixture fighter's (tools/fixtures/virtual/data/fighters/FIXTURE_HERO/...)
const MATCH = opt('--match', FILE);   // a glob for a file that every fighter has (data/fighters/*/forms.json)
if (!m.rules.some((r) => r.match === MATCH)) { changed.push('map'); if (!check) { m.rules.push({ match: MATCH, schema: `${NAME}.schema.json` }); wj(mf, m); } }

// ---- cases
const cases = [];
const cs = (id, mutate, expect) => cases.push({ id: `${NAME}-${id}`, schema: `${NAME}.schema.json`, mutate: [{ file: CASEFILE, ...mutate }], expect });
const ptr = (p) => p.map((x) => '/' + String(x).replace(/~/g, '~0').replace(/\//g, '~1')).join('');
cs('valid', { set: { [`/${VKEY}`]: data[VKEY] } }, null);
for (const k of Object.keys(data).filter((k) => !k.startsWith('_'))) cs('key-required-' + k.toLowerCase().replace(/[^a-z0-9]+/g, '-'), { del: ['/' + k] }, { rule: 'required', pointer: '' });
cs('unknown-key', { set: { '/extra': 1 } }, { rule: 'additionalProperties', pointer: '/extra' });
cs('underscore-key-ok', { set: { '/_why': 'a note' } }, null);
cs('version-wrong', { set: { [`/${VKEY}`]: typeof data[VKEY] === 'number' ? data[VKEY] + 1 : 'x/99' } }, { rule: 'const', pointer: `/${VKEY}` });
// a wrong type at each leaf (first leaf of each object, to a cap), and an unknown key in each nested object
let leaves = 0;
const walk = (v, path, sch, depth) => {
  if (leaves > 60) return;
  if (isObj(v) && sch && sch.properties) {
    if (path.length) cs('unknown-key-' + path.join('-').toLowerCase().replace(/[^a-z0-9-]+/g, '-'), { set: { [ptr(path.concat('extra'))]: 1 } }, { rule: 'additionalProperties', pointer: ptr(path.concat('extra')) });
    for (const [k, c] of Object.entries(v)) { if (!k.startsWith('_') && sch.properties[k]) walk(c, path.concat(k), sch.properties[k], depth + 1); }
  } else if (isObj(v) && sch && sch.additionalProperties && typeof sch.additionalProperties === 'object') {
    const first = Object.keys(v).find((k) => !k.startsWith('_'));
    if (first !== undefined) walk(v[first], path.concat(first), sch.additionalProperties, depth + 1);
  } else if (!isObj(v) && !Array.isArray(v) && sch && sch.type) {
    leaves++;
    const wrong = sch.type === 'string' ? 5 : sch.type === 'boolean' ? 'yes' : 'x';
    cs('type-' + path.join('-').toLowerCase().replace(/[^a-z0-9-]+/g, '-'), { set: { [ptr(path)]: wrong } }, { rule: 'type', pointer: ptr(path) });
    if (sch.minimum === 0 && typeof v === 'number') cs('negative-' + path.join('-').toLowerCase().replace(/[^a-z0-9-]+/g, '-'), { set: { [ptr(path)]: -1 } }, { rule: 'minimum', pointer: ptr(path) });
  }
};
walk(data, [], out, 0);
const c = JSON.parse(fs.readFileSync(cf, 'utf8'));
const mine = (x) => x.id.startsWith(NAME + '-');
const before = c.cases.filter(mine);
if (before.length !== cases.length || cases.some((k, i) => !same(before[i], k))) {
  changed.push(`cases (${before.length} to ${cases.length})`);
  if (!check) {
    const at = c.cases.findIndex(mine);
    const keep = c.cases.filter((x) => !mine(x));
    // new cases go before the last case so the file's tail stays as other parks' diffs expect it
    const place = at >= 0 ? at : Math.max(0, keep.length - 1);
    c.cases = keep.slice(0, place).concat(cases, keep.slice(place));
    wj(cf, c);
  }
}
console.log(`${NAME}: ${changed.length ? changed.join(', ') + (check ? ' (would change)' : ' written') : 'already'}`);
