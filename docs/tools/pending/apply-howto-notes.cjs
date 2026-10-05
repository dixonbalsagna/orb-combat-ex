// UI's four more how-to-play note names (docs/ui/hud-spec.md; ui/data/howto.json): `stances_table`, `stances_table_touch`, `stances_full` and
// `stances_simple`, beside the existing `kbd_p2` and `reopen` (six in all), so the stances lines can be notes instead of icon rows. NOT run by
// CI, the validator or the sim. Run once from the repo root, in the commit where UI moves the lines:
//     node docs/tools/pending/apply-howto-notes.cjs
// It does NOT edit ui/. It widens `note` in tools/schemas/ui-howto.schema.json to the six names and adds cases (each sets its own whole item).
// Re-runnable (a second run changes nothing).
const fs = require('fs');
const rj = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));
const wj = (f, o) => fs.writeFileSync(f, JSON.stringify(o, null, 2) + '\n');
const NOTES = ['kbd_p2', 'reopen', 'stances_table', 'stances_table_touch', 'stances_full', 'stances_simple'];

// =============================== schema ===============================
{
  const f = 'tools/schemas/ui-howto.schema.json';
  const s = rj(f);
  const note = s.$defs.item.properties.note;
  if (JSON.stringify(note.enum) !== JSON.stringify(NOTES)) {
    note.enum = NOTES;
    note.description = 'The name of a note the card fills in itself: a two-keyboard line, the line about reopening the card, or one of the four lines of the stances table (full table, its touch form, the full list and the simple list).';
    wj(f, s);
  }
}

// =============================== cases ===============================
{
  const cf = 'tools/fixtures/cases.json';
  const c = rj(cf);
  const H = 'ui/data/howto.json';
  const I = '/pages/0/items/0';
  const x = (n, item, expect) => ({ id: 'ui-howto-' + n, schema: 'ui-howto.schema.json', mutate: [{ file: H, set: { [I]: item } }], expect });
  const add = [
    ...NOTES.map((name) => x('note-' + name.replace(/_/g, '-') + '-ok', { note: name, col: 0, text: 'a line' }, null)),
    x('note-unknown-name', { note: 'stances_other', col: 0, text: 'a line' }, { rule: 'enum', pointer: I + '/note' }),
    x('note-old-name-with-a-suffix', { note: 'kbd_p2_touch', col: 0, text: 'a line' }, { rule: 'enum', pointer: I + '/note' }),
    x('note-type', { note: 5, col: 0, text: 'a line' }, { rule: 'enum', pointer: I + '/note' }),
    x('note-empty', { note: '', col: 1, text: 'a line' }, { rule: 'enum', pointer: I + '/note' }),
    x('note-in-the-other-column-ok', { note: 'stances_table', col: 1, text: '' }, null),
    x('note-with-an-unknown-key', { note: 'stances_full', col: 0, text: 'a line', extra: 1 }, { rule: 'additionalProperties', pointer: I + '/extra' }),
  ];
  let n = 0;
  for (const k of add) if (!c.cases.some((y) => y.id === k.id)) { c.cases.push(k); n++; }
  wj(cf, c);
  console.log(`howto notes applied (${n} new cases)`);
}
