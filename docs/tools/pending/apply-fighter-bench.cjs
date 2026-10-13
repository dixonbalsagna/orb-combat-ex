// The bench (Simulation's window 2, 1c6774b0; docs/architecture/fighters-as-data.md section 3): data/fighters/bench.json lists fighters that load and can be named in a match's
// slots but are not in the roster (the reference fighter). The loader reads an array of ids and refuses an id that is not a string or that the roster already has.
//   tools/schemas/fighter-bench.schema.json (new): an array of ids, each an upper-case id as the roster's, no duplicates, empty allowed.
//   tools/schemas/map.json: the file's rule.
//   tools/lib/xref.js: rule `bench-id`: every bench id has data/fighters/<id>/fighter.json, and none is in the roster.
//   tools/fixtures/virtual/data/fighters/bench.json: an empty bench, so a case can set one; cases in tools/fixtures/cases.json; a README row.
// NOT run by CI, the validator or the sim:  node docs/tools/pending/apply-fighter-bench.cjs   Re-runnable (a second run changes nothing). It does NOT edit data/.
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);

// ---- the schema
{
  const f = 'tools/schemas/fighter-bench.schema.json';
  const s = {
    $schema: 'https://json-schema.org/draft/2020-12/schema',
    $id: 'meridian/fighter-bench',
    title: 'the bench (fighters as data, window 2)',
    description: 'data/fighters/bench.json: fighters that load as the roster\'s do and can be named in a match\'s slots, but are not on the select screen and not in the roster (the reference fighter). A bare array of ids, as the loader reads it (sim/core/fighter_data.gd: anything else is refused). Each id has data/fighters/<id>/fighter.json and is not in the roster (checked by tools/lib/xref.js, rule bench-id). May be empty. Policy: a bare array, so there are no object keys to close; each item is an id string only.',
    type: 'array',
    uniqueItems: true,
    items: { type: 'string', pattern: '^[A-Z][A-Z0-9_]*$' },
  };
  if (!fs.existsSync(f) || !same(rj(f), s)) wj(f, s);
}

// ---- map.json
{
  const f = 'tools/schemas/map.json';
  const m = rj(f);
  if (!m.rules.some((r) => r.match === 'data/fighters/bench.json')) {
    const i = m.rules.findIndex((r) => r.match === 'data/fighters/roster.json');
    m.rules.splice(i < 0 ? m.rules.length : i + 1, 0, { match: 'data/fighters/bench.json', schema: 'fighter-bench.schema.json' });
    wj(f, m);
  }
}

// ---- the cross-reference
{
  const f = 'tools/lib/xref.js';
  let t = fs.readFileSync(f, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  if (!t.includes("'bench-id'")) {
    const a = "  // A fighter's voice bible is a real file.\n";
    if (!t.includes(a)) throw new Error('xref anchor');
    const b = [
      "  // The bench (data/fighters/bench.json): fighters that load but are not in the roster. Each has a fighter.json, and none is on the roster.",
      "  const bench = get('data/fighters/bench.json');",
      "  if (Array.isArray(bench)) {",
      "    bench.forEach((id, i) => {",
      "      if (typeof id !== 'string') return;",
      "      if (Array.isArray(rosterIds) && rosterIds.includes(id)) err('data/fighters/bench.json', `/${i}`, 'bench-id', `bench lists \"${id}\", who is in the roster already (a fighter is on the roster or on the bench, not both)`);",
      "      else if (fighterFiles.length && !seenIds.has(id)) err('data/fighters/bench.json', `/${i}`, 'bench-id', `bench lists \"${id}\", but no data/fighters/${id}/fighter.json defines it`);",
      "    });",
      "  }",
      "",
      ""].join('\n');
    t = t.replace(a, () => b + a);
    fs.writeFileSync(f, crlf ? t.replace(/\n/g, '\r\n') : t);
  }
}

// ---- the fixture and the cases
{
  const fx = 'tools/fixtures/virtual/data/fighters/bench.json';
  // a third fixture fighter, on the bench and in no roster (the real tree has REFERENCE the same way)
  const fd = 'tools/fixtures/virtual/data/fighters/FIXTURE_BENCH';
  if (!fs.existsSync(fd + '/fighter.json')) {
    fs.mkdirSync(fd, { recursive: true });
    const v = rj('tools/fixtures/virtual/data/fighters/FIXTURE_VILLAIN/fighter.json');
    v.id = 'FIXTURE_BENCH';
    v._about = 'Validator fixture, not game data: a fighter on the bench (data/fighters/bench.json), in no roster.';
    wj(fd + '/fighter.json', v);
  }
  if (!fs.existsSync(fx) || !same(rj(fx), ['FIXTURE_BENCH'])) wj(fx, ['FIXTURE_BENCH']);
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const B = 'data/fighters/bench.json';
  const out = [];
  const cs = (id, mutate, expect) => out.push({ id: 'bench-' + id, schema: 'fighter-bench.schema.json', mutate, expect });
  cs('empty-ok', [{ file: B, root: [] }], null);
  cs('one-ok', [{ file: B, root: ['FIXTURE_BENCH'] }], null);
  cs('not-an-array', [{ file: B, root: {} }], { rule: 'type', pointer: '' });
  cs('bad-id', [{ file: B, root: ['fixture-bench'] }], { rule: 'pattern', pointer: '/0' });
  cs('not-a-string', [{ file: B, root: [7] }], { rule: 'type', pointer: '/0' });
  cs('duplicate', [{ file: B, root: ['FIXTURE_BENCH', 'FIXTURE_BENCH'] }], { rule: 'uniqueItems', pointer: '/1' });
  cs('in-the-roster', [{ file: B, root: ['FIXTURE_HERO'] }], { rule: 'xref:bench-id', pointer: '/0' });
  cs('no-folder', [{ file: B, root: ['GHOST'] }], { rule: 'xref:bench-id', pointer: '/0' });
  let n = 0;
  for (const k of out) {
    const i = c.cases.findIndex((y) => y.id === k.id);
    if (i < 0) { c.cases.push(k); n++; } else if (!same(c.cases[i], k)) { c.cases[i] = k; n++; }
  }
  if (n) wj(cf, c);
  console.log(`bench: schema, map line, rule bench-id, fixture, ${n} new or changed cases`);
}

// ---- docs
{
  const f = 'docs/tools/README.md';
  const t = fs.readFileSync(f, 'utf8');
  if (!t.includes('`bench-id`')) {
    const lines = t.split('\n');
    const i = lines.findIndex((l) => l.includes('`stages-order`'));
    if (i < 0) throw new Error('README anchor');
    lines.splice(i + 1, 0, '| `bench-id` | data/fighters/bench.json (the bench, fighters as data): every id has data/fighters/<id>/fighter.json and is not in the roster; the file is a bare array of ids, no duplicates, empty allowed |');
    fs.writeFileSync(f, lines.join('\n'));
  }
}
