// The table of the project's check and test scripts (A-CODE-04, Tools, 2026-11-14): which run in CI, which in the landing gate, and which are deliberately not run, with the reason.
//
//   node tools/check-scripts-table.mjs [--write] [--check] [--json <file>]
//
// The scripts are every tracked *_check.gd, *check.gd and *_test.gd outside docs/ (262 on 2026-11-13, when CI named 116 of them). For each:
//   CI    a workflow file names the script (its path or its res:// path), or tools/world-checks.json lists it in its run list (the world job's loop)
//   GATE  the landing gate names it (docs/ep/gate/run-gate.sh or render-gates.sh): its file name without .gd as a whole word, or a folder glob such as sim/input/test/*_test.gd
//   NOT RUN  neither, and tools/check-scripts.json gives the reason (a script run by hand on purpose: a soak, a measurement, a tool for one owner's park)
//   UNREVIEWED  neither and no reason: the owner has not said yet. The count may only go DOWN: `unreviewedMax` in tools/check-scripts.json is the ratchet; a new script that is not in CI, not in the gate and
//   without a reason raises the count and fails --check. --write writes the table (docs/tools/check-scripts.md). Node built-ins and git only.
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { basename, dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const CFG = join(ROOT, 'tools', 'check-scripts.json');
const TABLE = join(ROOT, 'docs', 'tools', 'check-scripts.md');
export const PATTERN = /(_check|check|_test)\.gd$/;

/** The tracked scripts, sorted. */
export function listScripts(repo = ROOT) {
  const out = execFileSync('git', ['ls-files', '-z'], { cwd: repo, encoding: 'latin1', maxBuffer: 256 * 1024 * 1024 });
  return out.split('\0').filter((p) => p && PATTERN.test(p) && !p.startsWith('docs/')).map((p) => Buffer.from(p, 'latin1').toString('utf8')).sort();
}

/** The scripts a workflow's text names (paths, with or without res://). Pure. */
export function namedInWorkflows(texts, scripts) {
  const all = texts.join('\n');
  return new Set(scripts.filter((s) => all.includes(s)));
}

/** The scripts a workflow step runs by a folder glob (`dir/*_test.gd`): tools/check-scripts.json's ciGlobs lists { glob, except: [paths] }, and the glob must be written in a workflow (a dead entry names nothing). Pure. */
export function namedByCiGlobs(texts, scripts, ciGlobs) {
  const all = texts.join('\n');
  const out = new Set();
  for (const g of ciGlobs || []) {
    if (!all.includes(g.glob)) continue;
    const m = /^(.*)\/\*([A-Za-z0-9_]*)\.gd$/.exec(g.glob);
    if (!m) continue;
    for (const s of scripts) if (dirname(s) === m[1] && basename(s, '.gd').endsWith(m[2]) && !(g.except || []).includes(s)) out.add(s);
  }
  return out;
}

/** The scripts the world job runs: tools/world-checks.json's run list names them without folder or extension; they are in sim/world/tools. Pure. */
export function namedInWorldList(list, scripts) {
  const names = new Set((list && list.run) || []);
  return new Set(scripts.filter((s) => s.startsWith('sim/world/tools/') && names.has(basename(s, '.gd'))));
}

/** The scripts the landing gate names: the file name without .gd as a whole word in the gate's text, or a folder glob (`dir/*_test.gd`). Pure. */
export function namedInGate(gateText, scripts) {
  const globs = [...gateText.matchAll(/([A-Za-z0-9_./-]+)\/\*([A-Za-z0-9_]*)\.gd/g)].map((m) => ({ dir: m[1], suffix: m[2] }));
  const words = new Set(gateText.split(/[^A-Za-z0-9_]+/).filter(Boolean));
  const hit = (s) => words.has(basename(s, '.gd')) || globs.some((g) => dirname(s) === g.dir && basename(s, '.gd').endsWith(g.suffix));
  return new Set(scripts.filter(hit));
}

/** The table rows: { path, status: 'CI' | 'GATE' | 'NOT RUN' | 'UNREVIEWED', reason } and the counts. Pure. */
export function classify(scripts, { ci, gate, reasons }) {
  const rows = scripts.map((p) => {
    if (ci.has(p)) return { path: p, status: 'CI', reason: '', alsoGate: gate.has(p) };
    if (gate.has(p)) return { path: p, status: 'GATE', reason: '' };
    if (reasons[p]) return { path: p, status: 'NOT RUN', reason: reasons[p] };
    return { path: p, status: 'UNREVIEWED', reason: '' };
  });
  const count = (s) => rows.filter((r) => r.status === s).length;
  return { rows, ci: count('CI'), gate: count('GATE'), notRun: count('NOT RUN'), unreviewed: count('UNREVIEWED'), total: rows.length };
}

/** The problems of the ratchet and of the file. Pure. */
export function problems(t, cfg, reasons) {
  const out = [];
  const set = new Set(t.rows.map((r) => r.path));
  for (const p of Object.keys(reasons)) if (!set.has(p)) out.push(`tools/check-scripts.json gives a reason for ${p}, which is not a tracked check script`);
  for (const p of Object.keys(reasons)) { const r = t.rows.find((x) => x.path === p); if (r && (r.status === 'CI' || r.status === 'GATE')) out.push(`${p} has a reason for not being run but it IS run (${r.status}): delete the reason`); }
  if (typeof cfg.unreviewedMax !== 'number') out.push('tools/check-scripts.json has no unreviewedMax (the ratchet)');
  else if (t.unreviewed > cfg.unreviewedMax) out.push(`${t.unreviewed} scripts are neither in CI, nor in the gate, nor given a reason; the ratchet allows ${cfg.unreviewedMax}: wire the new script in CI, or give it a reason in tools/check-scripts.json`);
  else if (t.unreviewed < cfg.unreviewedMax) out.push(`${t.unreviewed} scripts are unreviewed and the ratchet says ${cfg.unreviewedMax}: lower unreviewedMax to ${t.unreviewed} (a ratchet only goes down)`);
  return out;
}

export function markdown(t, date = '') {
  const folder = (p) => dirname(p);
  const byFolder = new Map();
  for (const r of t.rows) { const f = folder(r.path); if (!byFolder.has(f)) byFolder.set(f, []); byFolder.get(f).push(r); }
  const L = [`# The check and test scripts (A-CODE-04; written by \`node tools/check-scripts-table.mjs --write\`${date ? ', ' + date : ''})`, '',
    `${t.total} scripts (\`*_check.gd\`, \`*check.gd\`, \`*_test.gd\` outside docs/). **${t.ci} run in CI**, ${t.gate} more run in the landing gate only, ${t.notRun} are deliberately not run (reason given), **${t.unreviewed} unreviewed** (their owners have not said yet; the number may only go down: \`unreviewedMax\` in tools/check-scripts.json).`, '',
    '| Folder | Scripts | CI | Gate only | Not run | Unreviewed |', '| :--- | ---: | ---: | ---: | ---: | ---: |'];
  for (const [f, rs] of [...byFolder].sort()) { const c = (s) => rs.filter((r) => r.status === s).length; L.push(`| ${f} | ${rs.length} | ${c('CI')} | ${c('GATE')} | ${c('NOT RUN')} | ${c('UNREVIEWED')} |`); }
  L.push('', '## Every script', '', '| Script | Status | Reason |', '| :--- | :--- | :--- |');
  for (const r of t.rows) L.push(`| ${r.path} | ${r.status}${r.alsoGate ? ' + gate' : ''} | ${r.reason.replace(/\|/g, '/')} |`);
  return L.join('\n') + '\n';
}

function build(repo = ROOT) {
  const scripts = listScripts(repo);
  const wf = join(repo, '.github', 'workflows');
  const texts = existsSync(wf) ? readdirSync(wf).filter((n) => /\.ya?ml$/.test(n)).map((n) => readFileSync(join(wf, n), 'utf8')) : [];
  let list = null; try { list = JSON.parse(readFileSync(join(repo, 'tools', 'world-checks.json'), 'utf8')); } catch { /* none */ }
  const gateText = ['run-gate.sh', 'render-gates.sh'].map((n) => { try { return readFileSync(join(repo, 'docs', 'ep', 'gate', n), 'utf8'); } catch { return ''; } }).join('\n');
  const cfg = JSON.parse(readFileSync(CFG, 'utf8'));
  const ci = new Set([...namedInWorkflows(texts, scripts), ...namedInWorldList(list, scripts), ...namedByCiGlobs(texts, scripts, cfg.ciGlobs)]);
  const t = classify(scripts, { ci, gate: namedInGate(gateText, scripts), reasons: cfg.reasons || {} });
  return { t, cfg };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const a = process.argv.slice(2);
  try {
    const { t, cfg } = build();
    const ps = problems(t, cfg, cfg.reasons || {});
    if (a.includes('--write')) writeFileSync(TABLE, markdown(t, new Date().toISOString().slice(0, 10)));
    const ji = a.indexOf('--json');
    if (ji >= 0) writeFileSync(resolve(a[ji + 1]), JSON.stringify({ total: t.total, ci: t.ci, gate: t.gate, notRun: t.notRun, unreviewed: t.unreviewed, rows: t.rows }, null, 1));
    console.log(`check scripts: ${t.total} in all; ${t.ci} in CI, ${t.gate} in the gate only, ${t.notRun} not run on purpose, ${t.unreviewed} unreviewed (ratchet ${cfg.unreviewedMax})`);
    if (a.includes('--check')) { for (const p of ps) console.log(`check-scripts: ${p}`); process.exitCode = ps.length ? 1 : 0; }
  } catch (e) { console.error(`check-scripts: ${e.message}`); process.exitCode = 2; }
}
