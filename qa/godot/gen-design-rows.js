#!/usr/bin/env node
// Game Design's list for QA (docs/design/qa-rows-2026-10-17.md) into qa/godot/design-rows.json: one record per row {id, group, section, kind (hard | band), what, bound}. The rows are data;
// masher.js (designRows) reads the file and says, for each, which row reads it or what it waits for. Run again when Game Design changes the list: node qa/godot/gen-design-rows.js
const fs = require('fs'), path = require('path');
const src = path.join(__dirname, '..', '..', 'docs', 'design', 'qa-rows-2026-10-17.md'), out = path.join(__dirname, 'design-rows.json');
const rows = [];
let sec = '', kind = '';
for (const l of fs.readFileSync(src, 'utf8').split(/\r?\n/)) {
  if (l.startsWith('## ')) { sec = l.slice(3).trim(); continue; }
  if (l.startsWith('**Hard tests**')) kind = 'hard';
  else if (l.startsWith('**Bands')) kind = 'band';
  if (!l.startsWith('|') || l.startsWith('| ---') || l.startsWith('| #')) continue;
  const p = l.trim().replace(/^\||\|$/g, '').split(' | ').map(x => x.trim());
  if (!/^[A-Z]+\d+b?$/.test(p[0])) continue;
  let k = kind, bound = '';
  if (p.length >= 3) { bound = p[2]; if (/hard|every time/i.test(bound)) k = 'hard'; else if (!k) k = 'band'; } else if (p.length === 2) k = 'hard';
  if (/^[45]\./.test(sec)) k = /\(hard\)|^Every/.test(bound) ? 'hard' : 'band';
  rows.push({ id: p[0], group: p[0].replace(/[0-9b]+$/, ''), section: sec, kind: k, what: p[1], bound });
}
fs.writeFileSync(out, JSON.stringify(rows, null, 1) + '\n');
console.log(`${rows.length} rows written to ${path.relative(process.cwd(), out)}`);
