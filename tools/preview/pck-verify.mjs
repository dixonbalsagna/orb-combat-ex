// Proof from the BUILT pack (Tools, 2026-11-07, after the held rows were found on in two kept builds while the page's list said off): read each switch row's key out of the data files inside
// the exported index.pck itself, and compare it with what the build says it is. The list says what was meant; the pack says what shipped.
//   a row that is ON must hold its "to" value in the pack; a row that is not on (off, held, cascaded, waiting) must hold its "from" value, or its key must be absent.
//   node tools/preview/pck-verify.mjs --web <the build's web folder> [--active a,b,c]   (default: the ids named in the page's window.__build.switches)
// Exit 1 on any mismatch. Rows that are page words or constants in a script (not data) are not read here. Node built-ins only.
import { readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { packFiles } from '../site-name-scan.mjs';
import { SWITCHES, parts } from './switches.mjs';

/** The JSON of a pack file by its res:// path or its plain path, or null when the pack has no such file (or it is not JSON). */
export function packJson(buf, files, path) {
  const want = path.replace(/^res:\/\//, '');
  const f = files.find((x) => x.path.replace(/^res:\/\//, '') === want);
  if (!f) return null;
  let text = buf.toString('utf8', f.offset, f.offset + f.size);
  if (text.charCodeAt(0) === 0xfeff) text = text.slice(1);
  try { return JSON.parse(text); } catch { return null; }
}

const at = (obj, path) => { let v = obj; for (const k of path) { if (v === null || typeof v !== 'object' || !(k in v)) return { found: false }; v = v[k]; } return { found: true, value: v }; };
const same = (a, b) => (typeof a === 'number' && typeof b === 'number' ? a === b : JSON.stringify(a) === JSON.stringify(b));

/** Checks every data row of the table against the pack bytes. activeIds: the rows the build says are ON. Returns { ok, problems, lines, checked }. */
export function verifyPack(buf, table, activeIds) {
  const files = packFiles(buf);
  const on = new Set(activeIds);
  const cache = new Map();
  const getJson = (p) => { if (!cache.has(p)) cache.set(p, packJson(buf, files, p)); return cache.get(p); };
  const problems = [], lines = [];
  let checked = 0;
  // a key that two rows share (dodgeHeld is a row of its own and one key of flightStrikes) is on when ANY row that owns it is on
  const keyId = (file, path) => `${file} ${path.join('.')}`;
  const onKeys = new Map();
  for (const sw of table) {
    if (!on.has(sw.id) || sw.setup || sw.url || sw.replace || !sw.file) continue;
    for (const part of parts(sw)) for (const k of [{ path: part.sw.path, to: part.sw.to }, ...(part.sw.more || [])]) onKeys.set(keyId(part.file, k.path), k.to);
  }
  for (const sw of table) {
    if (sw.setup || sw.url || sw.replace || !sw.file) continue;   // a page word, a setup key or a constant in a script: not a data key in the pack
    const isOn = on.has(sw.id);
    for (const part of parts(sw)) {
      const json = getJson(part.file);
      const keys = [{ path: part.sw.path, from: part.sw.from, to: part.sw.to }, ...(part.sw.more || [])];
      if (json === null) {
        if (isOn) problems.push(`${sw.id}: ON, but ${part.file} is not readable in the pack`);
        continue;
      }
      for (const k of keys) {
        const got = at(json, k.path);
        const where = `${part.file} ${k.path.join('.')}`;
        if (!got.found) {
          if (isOn) problems.push(`${sw.id}: ON, but ${where} is not in the pack`);
          lines.push(`${sw.id.padEnd(16)} ${isOn ? 'ON ' : 'off'} ${where}: key not in the pack`);
          continue;
        }
        checked++;
        const shared = !isOn && onKeys.has(keyId(part.file, k.path));   // owned by a row that is on: expected on
        const wantOn = isOn || shared;
        const want = wantOn ? (shared ? onKeys.get(keyId(part.file, k.path)) : k.to) : k.from;
        const ok = same(got.value, want) || (typeof want === 'number' && Number(got.value) === want);
        lines.push(`${sw.id.padEnd(16)} ${isOn ? 'ON ' : 'off'} ${where} = ${JSON.stringify(got.value)}${shared ? ' (a key of a row that is on)' : ''}${ok ? '' : `   MISMATCH (expected ${JSON.stringify(want)})`}`);
        if (!ok) problems.push(`${sw.id}: ${isOn ? 'ON' : 'not on'} but ${where} holds ${JSON.stringify(got.value)}, expected ${JSON.stringify(want)}`);
      }
    }
  }
  return { ok: problems.length === 0, problems, lines, checked };
}

/** The ids the page says are on (window.__build.switches in index.html), or null. */
export function buildSwitches(webDir) {
  try {
    const html = readFileSync(join(webDir, 'index.html'), 'utf8');
    const m = html.match(/window\.__build = (\{.*?\});<\/script>/s);
    return m ? (JSON.parse(m[1]).switches || null) : null;
  } catch { return null; }
}

function main() {
  const a = process.argv.slice(2);
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  const web = opt('--web');
  if (!web) { console.error('usage: node tools/preview/pck-verify.mjs --web <web folder> [--active id,id]'); process.exit(2); }
  const dir = resolve(web);
  const active = opt('--active') ? opt('--active').split(',').filter(Boolean) : buildSwitches(dir);
  if (!active) { console.error('the page names no switches (no window.__build.switches): pass --active id,id'); process.exit(2); }
  const r = verifyPack(readFileSync(join(dir, 'index.pck')), SWITCHES, active);
  for (const l of r.lines) console.log(l);
  for (const p of r.problems) console.log(`PROBLEM ${p}`);
  console.log(`pck verify: ${r.checked} keys read from the pack, ${active.length} rows on, ${r.problems.length} problem(s)`);
  process.exitCode = r.ok ? 0 : 1;
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
