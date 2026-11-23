// The report scan (Tools, 2026-11-23; path to Alpha 1, job 14: a size limit on the report, and a scan of it for names and folder paths; X-21; Legal G13).
//   node tools/report-scan.mjs <report folder or files>... [--names <file>] [--no-machine-names] [--json]
// Reads what the game made for a tester to send (the folder under user://reports, and the logs the report folder will copy) and fails when:
//   size   a file is over perFileBytes, or the whole is over totalBytes (tools/report-scan.json; Discord's free upload limit is 20 MB, the limits sit well under it);
//   paths  a text file holds a user's folder, a drive path, a network share (tools/report-scan.json patterns);
//   names  it holds the name of the account or the PC that ran this scan (os.userInfo and os.hostname; --no-machine-names skips them), a line of --names (a file of names, one a line; the private tester list is
//          .private/testers/names.txt and is read when it exists), an email address, an IPv4 address (not 127.0.0.1) or a network card's address.
// A binary file (not a text extension) is checked for size only, and says so. Exit 0 clean, 1 findings, 2 a usage error. The findings are printed WITHOUT the matched text (a name found in a report is not
// repeated in a log): the file, the line, the rule. Node built-ins only.
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { hostname, userInfo } from 'node:os';
import { dirname, extname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
export const CONFIG = JSON.parse(readFileSync(join(HERE, 'report-scan.json'), 'utf8'));
const RULES = Object.entries(CONFIG.patterns).map(([id, p]) => ({ id, rx: new RegExp(p.rx, 'g'), why: p.why }));
const ALLOW = CONFIG.allowLines.rx.map((r) => new RegExp(r));

/** The findings in one text: [{ line, rule, why }] (never the matched text). `names` are words to find (case-insensitive, whole). Pure. */
export function scanText(text, names = []) {
  const out = [];
  const nameRx = names.filter((n) => n && n.length >= 3).map((n) => ({ n, rx: new RegExp(`(?<![A-Za-z0-9])${n.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}(?![A-Za-z0-9])`, 'i') }));
  String(text).split(/\r?\n/).forEach((l, i) => {
    if (ALLOW.some((a) => a.test(l))) return;
    for (const r of RULES) { r.rx.lastIndex = 0; if (r.rx.test(l)) out.push({ line: i + 1, rule: r.id, why: r.why }); }
    for (const { rx } of nameRx) if (rx.test(l)) out.push({ line: i + 1, rule: 'name', why: 'the name of an account, a PC or a tester' });
  });
  return out;
}

/** The size findings of [{ file, size }]. Pure. */
export function scanSizes(files, cfg = CONFIG) {
  const out = [];
  let total = 0;
  for (const f of files) { total += f.size; if (f.size > cfg.perFileBytes) out.push({ file: f.file, rule: 'size', why: `${f.size} bytes is over the ${cfg.perFileBytes} a file may have` }); }
  if (total > cfg.totalBytes) out.push({ file: '(all)', rule: 'size', why: `${total} bytes in all is over the ${cfg.totalBytes} the report may have` });
  return out;
}

function* walk(p) {
  const s = statSync(p);
  if (!s.isDirectory()) { yield p; return; }
  for (const n of readdirSync(p).sort()) yield* walk(join(p, n));
}

/** Scans paths (folders or files). Returns { files, findings: [{ file, line?, rule, why }], binary: [names] }. */
export function scanPaths(paths, { names = [] } = {}) {
  const files = [], findings = [], binary = [];
  for (const p of paths) for (const f of walk(resolve(p))) files.push({ file: f, size: statSync(f).size });
  for (const x of scanSizes(files)) findings.push(x);
  for (const f of files) {
    if (!CONFIG.textExtensions.includes(extname(f.file).toLowerCase())) { binary.push(f.file); continue; }
    for (const h of scanText(readFileSync(f.file, 'utf8'), names)) findings.push({ file: f.file, ...h });
  }
  return { files, findings, binary };
}

/** The names of this machine: the account and the PC. */
export function machineNames() {
  const out = [];
  try { out.push(userInfo().username); } catch { /* none */ }
  try { out.push(hostname()); } catch { /* none */ }
  return out.filter(Boolean);
}

function readNames(file) {
  return existsSync(file) ? readFileSync(file, 'utf8').split(/\r?\n/).map((x) => x.trim()).filter((x) => x && !x.startsWith('#')) : [];
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const a = process.argv.slice(2);
  const opt = (n) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : null; };
  const skip = new Set(['--names', opt('--names'), '--no-machine-names', '--json']);
  const paths = a.filter((x) => !skip.has(x));
  if (!paths.length) { console.error('usage: node tools/report-scan.mjs <report folder or files>... [--names <file>] [--no-machine-names] [--json]'); process.exit(2); }
  try {
    const names = [...(a.includes('--no-machine-names') ? [] : machineNames()), ...readNames(opt('--names') || ''), ...readNames(join(HERE, '..', '.private', 'testers', 'names.txt'))];
    const r = scanPaths(paths, { names });
    if (a.includes('--json')) console.log(JSON.stringify({ files: r.files.length, bytes: r.files.reduce((s, f) => s + f.size, 0), findings: r.findings.map((f) => ({ ...f, file: f.file.split(/[\\/]/).pop() })), binary: r.binary.length }));
    else {
      for (const f of r.findings) console.log(`${f.file.split(/[\\/]/).pop()}${f.line ? ':' + f.line : ''}: ${f.rule}: ${f.why}`);
      console.log(`report-scan: ${r.files.length} file(s), ${r.files.reduce((s, f) => s + f.size, 0)} bytes, ${r.binary.length} not text (size only), ${r.findings.length} finding(s)`);
    }
    process.exit(r.findings.length ? 1 : 0);
  } catch (e) { console.error(`report-scan: ${e.message}`); process.exit(2); }
}
