// Saves a desktop-builds.yml run as a record the repository can keep (Tools, 2026-11-23; path to Alpha 1, job 7: "the CI build run repeated and saved").
//   node tools/desktop-run-record.mjs <run id> [--out <file>] [--repo <owner/name>] [--note <one line>]
// It reads the run through the gh command (jobs and steps with their results and times, the bench hash lines, the packages' sizes and SHA-256 sums from the pack step, the artifact count) and writes one Markdown
// page: the run, a table of jobs, the failed steps (if any) with the last lines of their log, the hashes each job printed and whether they agree, the packages as they stood on the runner, and the artifact count
// (an owner-private run keeps none). The text is cleaned of folder paths (tools/record-paths.mjs). Default --out: docs/tools/runs/<commit8>/desktop-run-<run id>.md. Node built-ins and gh.
import { spawnSync } from 'node:child_process';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { cleanPaths } from './record-paths.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');

const mins = (a, b) => { const ms = Date.parse(b) - Date.parse(a); return Number.isFinite(ms) && ms >= 0 ? ms : null; };
const fmt = (ms) => ms === null ? '' : ms < 60000 ? `${Math.round(ms / 1000)} s` : `${Math.floor(ms / 60000)} min ${String(Math.round((ms % 60000) / 1000)).padStart(2, '0')} s`;

/** The log lines of `gh run view --log` as { job, step, text }. Pure. */
export function logLines(logText) {
  const out = [];
  for (const l of String(logText).split(/\r?\n/)) {
    const m = /^([^\t]+)\t([^\t]*)\t(?:\d{4}-\d{2}-\d{2}T[\d:.]+Z )?(.*)$/.exec(l);
    if (m) out.push({ job: m[1], step: m[2], text: m[3] });
  }
  return out;
}

/** Hash lines per job: [{ job, line }]. Pure. */
export function hashesOf(lines) {
  const seen = new Set(), out = [];
  for (const l of lines) {
    const m = /gameplay hash at tick \d+: [0-9a-f]+/.exec(l.text);
    if (m && !seen.has(l.job + m[0])) { seen.add(l.job + m[0]); out.push({ job: l.job, line: m[0] }); }
  }
  return out;
}

/** The packages the pack step listed: [{ name, size, sha256 }]. Pure. */
export function packagesOf(lines) {
  const sums = new Map(), sizes = new Map();
  for (const l of lines) {
    let m = /^([0-9a-f]{64})\s+\.\/(orb-combat-ex-[\w.-]+\.(?:zip|tar\.gz))\s*$/.exec(l.text.trim());
    if (m) sums.set(m[2], m[1]);
    m = /^[-rwx]{10}\s+\d+\s+\S+\s+\S+\s+(\d+)\s+\w{3}\s+\d+\s+[\d:]+\s+(orb-combat-ex-[\w.-]+\.(?:zip|tar\.gz))\s*$/.exec(l.text.trim());
    if (m) sizes.set(m[2], Number(m[1]));
  }
  return [...sums].map(([name, sha256]) => ({ name, sha256, size: sizes.get(name) ?? null }));
}

/** The page. `run` = gh's run json, `lines` = logLines(...), `artifacts` = a count, `note` = a line of the author's. Pure. */
export function recordText({ run, lines, artifacts, note = '' }) {
  const jobs = run.jobs || [];
  const sha = String(run.headSha || '');
  const wall = mins(run.createdAt, run.updatedAt);
  const L = [];
  L.push(`# Desktop builds run ${run.databaseId} (Tools, ${String(run.createdAt || '').slice(0, 10)})`, '');
  L.push(`GitHub run [${run.databaseId}](${run.url || ''}), workflow "${run.workflowName || run.name || 'Desktop builds'}", event ${run.event || '?'}, commit \`${sha}\`, branch ${run.headBranch || '?'}; started ${run.createdAt || '?'}; **${run.conclusion || run.status || '?'}**${wall !== null ? ', about ' + fmt(wall) : ''}.${note ? ' ' + note : ''}`, '');
  L.push('## Jobs', '', '| Job | Result | Time |', '| :--- | :--- | ---: |');
  for (const j of jobs) L.push(`| ${j.name} | ${j.conclusion || j.status} | ${fmt(mins(j.startedAt, j.completedAt))} |`);
  const bad = jobs.flatMap((j) => (j.steps || []).filter((s) => s.conclusion === 'failure').map((s) => ({ job: j.name, step: s.name })));
  if (bad.length) {
    L.push('', '## What failed', '');
    for (const b of bad) {
      L.push(`- **${b.job}**, step "${b.step}":`);
      const tail = lines.filter((l) => l.job === b.job && l.step === b.step).map((l) => l.text).filter((t) => t.trim()).slice(-8);
      for (const t of tail) L.push(`  - \`${t.trim().slice(0, 200).replace(/`/g, "'")}\``);
    }
  }
  const hashes = hashesOf(lines);
  L.push('', '## The gameplay hash each job printed', '');
  if (!hashes.length) L.push('None printed.');
  else {
    for (const h of hashes) L.push(`- ${h.job}: \`${h.line}\``);
    const values = new Set(hashes.map((h) => h.line.replace(/^.*?: /, '')));
    L.push('', values.size === 1 ? `All ${hashes.length} agree.` : `**They do not agree** (${values.size} different values).`);
  }
  const pk = packagesOf(lines);
  if (pk.length) {
    L.push('', '## The packages as they stood on the runner', '', '| Package | Size | SHA-256 |', '| :--- | ---: | :--- |');
    for (const p of pk) L.push(`| \`${p.name}\` | ${p.size === null ? '' : p.size.toLocaleString('en-US') + ' bytes'} | \`${p.sha256}\` |`);
  }
  L.push('', `**Artifacts: ${artifacts === null ? 'not read' : artifacts}**${artifacts === 0 ? ' (an owner-private run keeps nothing: the sums above are of files that were discarded with the runner)' : ''}.`, '');
  return cleanPaths(L.join('\n'));
}

function gh(args) {
  const r = spawnSync('gh', args, { encoding: 'utf8', maxBuffer: 256 * 1024 * 1024 });
  if (r.status !== 0) throw new Error(`gh ${args.slice(0, 3).join(' ')} failed: ${String(r.stderr).trim().split('\n')[0]}`);
  return r.stdout;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const a = process.argv.slice(2);
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  const id = a.find((x) => /^\d+$/.test(x));
  if (!id) { console.error('usage: node tools/desktop-run-record.mjs <run id> [--out <file>] [--repo <owner/name>] [--note <line>]'); process.exit(2); }
  try {
    const repoArgs = opt('--repo') ? ['--repo', opt('--repo')] : [];
    const run = JSON.parse(gh(['run', 'view', id, ...repoArgs, '--json', 'databaseId,url,workflowName,event,headSha,headBranch,createdAt,updatedAt,conclusion,status,jobs']));
    const lines = logLines(gh(['run', 'view', id, ...repoArgs, '--log']));
    let artifacts = null;
    try { artifacts = JSON.parse(gh(['api', `repos/${opt('--repo') || '{owner}/{repo}'}/actions/runs/${id}/artifacts`])).total_count; } catch { /* not read */ }
    const text = recordText({ run, lines, artifacts, note: opt('--note', '') });
    const out = resolve(opt('--out', join(ROOT, 'docs', 'tools', 'runs', String(run.headSha).slice(0, 8), `desktop-run-${id}.md`)));
    mkdirSync(dirname(out), { recursive: true });
    writeFileSync(out, text + '\n');
    console.log(`desktop-run-record: ${out} (${run.jobs.length} jobs, ${run.conclusion || run.status})`);
  } catch (e) { console.error(`desktop-run-record: ${e.message}`); process.exit(1); }
}
