// Schema key for Encounter's slice 14: data/director/alchemy.json flow.contestFloor (a number, 0 to 1, required).
// NOT run by CI, the validator or the sim. Run once from the repo root, in the commit that lands the slice's data:
//     node docs/tools/pending/apply-slice14.cjs
// It does NOT edit data/. It adds the key to tools/schemas/director-alchemy.schema.json, to the validator fixture and the cases.
// Re-runnable (a second run changes nothing). interrupts.json blast.heavy.tapShare changes value only.
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');

{
  const f = 'tools/schemas/director-alchemy.schema.json';
  const s = rj(f);
  const fl = s.properties.flow;
  if (!fl.properties.contestFloor) {
    fl.properties.contestFloor = { type: 'number', minimum: 0, maximum: 1, description: 'The share of the flow a lost contest leaves.' };
    if (!fl.required.includes('contestFloor')) fl.required.push('contestFloor');
    wj(f, s);
  }
}

{
  const f = 'tools/fixtures/virtual/data/director/alchemy.json';
  const o = rj(f);
  if (o.flow && o.flow.contestFloor === undefined) {
    const live = fs.existsSync('data/director/alchemy.json') ? rj('data/director/alchemy.json') : null;
    o.flow.contestFloor = live && live.flow && live.flow.contestFloor !== undefined ? live.flow.contestFloor : 0.5;
    wj(f, o);
  }
}

{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const A = 'data/director/alchemy.json';
  const al = (n, mut, expect) => ({ id: 'director-alchemy-' + n, schema: 'director-alchemy.schema.json', mutate: [{ file: A, ...mut }], expect });
  const K = '/flow/contestFloor';
  const add = [
    al('flow-contest-floor-required', { del: [K] }, { rule: 'required', pointer: '/flow' }),
    al('flow-contest-floor-negative', { set: { [K]: -0.1 } }, { rule: 'minimum', pointer: K }),
    al('flow-contest-floor-above-one', { set: { [K]: 1.5 } }, { rule: 'maximum', pointer: K }),
    al('flow-contest-floor-type', { set: { [K]: 'half' } }, { rule: 'type', pointer: K }),
    al('flow-contest-floor-edges-ok', { set: { [K]: 0 } }, null),
    al('flow-contest-floor-one-ok', { set: { [K]: 1 } }, null),
  ];
  let n = 0;
  for (const k of add) if (!c.cases.some((y) => y.id === k.id)) { c.cases.push(k); n++; }
  wj(cf, c);
  console.log(`slice 14 schema applied (${n} new cases)`);
}
