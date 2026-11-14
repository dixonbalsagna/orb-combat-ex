// read-only: for every switch row, what a tree holds against the row's from/to.   node rows-at-to.mjs <tree> [path to the old switches.mjs]   (the rows that print AT-TO go in retire-data.txt)
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
const { SWITCHES } = await import(pathToFileURL(resolve(process.argv[3] || 'tools/preview/switches.mjs')).href);   // the OLD table (before the retirement)
const tree = process.argv[2];
const cache = new Map();
const json = (f) => { if (!cache.has(f)) { let v = null; try { v = JSON.parse(readFileSync(join(tree, f), 'utf8').replace(/^\uFEFF/, '')); } catch { /* none */ } cache.set(f, v); } return cache.get(f); };
const at = (o, p) => { let v = o; for (const k of p) { if (v === null || typeof v !== 'object' || !(k in v)) return { found: false }; v = v[k]; } return { found: true, value: v }; };
const eq = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const out = [];
for (const r of SWITCHES) {
  if (r.file && Array.isArray(r.path)) {
    const j = json(r.file); const a = j ? at(j, r.path) : { found: false };
    const st = !j ? 'FILE ABSENT' : !a.found ? 'KEY ABSENT' : eq(a.value, r.to) ? 'AT-TO' : eq(a.value, r.from) ? 'AT-FROM' : 'OTHER=' + JSON.stringify(a.value);
    const more = (r.more || []).map((m) => { const jj = json(m.file || r.file); const aa = jj ? at(jj, m.path) : { found: false }; return !jj ? 'FILE ABSENT' : !aa.found ? 'KEY ABSENT' : eq(aa.value, m.to) ? 'AT-TO' : eq(aa.value, m.from) ? 'AT-FROM' : 'OTHER=' + JSON.stringify(aa.value); });
    out.push({ id: r.id, kind: 'data', st, more, to: r.to, file: r.file });
  } else out.push({ id: r.id, kind: r.url ? 'word:' + r.url : r.setup ? 'setup' : 'other', st: '' });
}
for (const o of out) console.log(o.id.padEnd(18), o.kind.padEnd(16), (o.st || '').padEnd(12), (o.more && o.more.length ? '+more[' + o.more.join(',') + ']' : ''), o.file || '');
const n = (s) => out.filter((o) => o.st === s).length;
console.log('AT-TO', n('AT-TO'), 'AT-FROM', n('AT-FROM'), 'KEY ABSENT', n('KEY ABSENT'), 'FILE ABSENT', n('FILE ABSENT'), 'OTHER', out.filter((o) => o.st.startsWith('OTHER')).length, 'non-data', out.filter((o) => o.kind !== 'data').length);
