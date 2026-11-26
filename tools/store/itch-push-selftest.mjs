// Self-test of tools/store/itch-push.mjs: every refusal with made-up approval files, archives and records, the one clean dry run, and a guard that the script cannot send anything. Nothing contacts itch.
//   node tools/store/itch-push-selftest.mjs
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { APPROVALS, ARCHIVES, approvalProblems, ciProblem, judge, readTarget, versionProblems } from './itch-push.mjs';

let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };
const NL = String.fromCharCode(10);
const lines = (...l) => l.join(NL) + NL;
const has = (list, re) => list.some((m) => re.test(m));

const pageYes = lines('date: 2026-12-10', 'scope: the restricted, key-only itch.io page under the working title, for named adult outside testers, free, no promotion', 'recorded-by: Executive Producer, on Orb\'s word', 'ends: 30 days after', 'conditions: RL-261');
const buildsYes = lines('date: 2026-12-08', 'scope: desktop test builds (Windows and Linux) for named outside testers, through a private download page only', 'recorded-by: Executive Producer, on Orb\'s word');
const today = '2026-12-12';
check('an approval in Legal\'s form passes: the page\'s own scope line and the builds\'', approvalProblems('page', pageYes, '2026-12-10', today).length === 0 && approvalProblems('builds', buildsYes, '2026-12-08', today).length === 0, JSON.stringify(approvalProblems('page', pageYes, '2026-12-10', today)));
check('the page scope may also read as RL-272 names it', approvalProblems('page', pageYes.replace('restricted, key-only itch.io page', 'restricted itch.io page'), '2026-12-10', today).length === 0);
check('a file that is not committed is not a yes', has(approvalProblems('page', null, '2026-12-10', today), /no committed docs\/ep\/approvals\/restricted-itch-page\.txt/));
check('neither file approves the other', has(approvalProblems('page', buildsYes, '2026-12-08', today), /does not name the restricted itch\.io page/) && has(approvalProblems('builds', pageYes, '2026-12-10', today), /does not name desktop test builds/));
check('a typed date that is not the recorded one, or no typed date, is refused', has(approvalProblems('builds', buildsYes, '2026-12-09', today), /is not the one typed/) && has(approvalProblems('builds', buildsYes, undefined, today), /--builds-yes must be the date/));
check('a yes 31 days old or dated tomorrow is refused; 30 days old passes', has(approvalProblems('builds', buildsYes, '2026-12-08', '2027-01-08'), /31 days old/) && has(approvalProblems('builds', buildsYes, '2026-12-08', '2026-12-07'), /-1 days old/) && approvalProblems('builds', buildsYes, '2026-12-08', '2027-01-07').length === 0);
check('no recorded-by line, or an empty one, is refused', has(approvalProblems('page', pageYes.replace(/recorded-by:.*/, 'recorded-by:'), '2026-12-10', today), /no recorded-by/));
check('CI is refused, either variable', /CI/.test(ciProblem({ GITHUB_ACTIONS: 'true' })) && /CI/.test(ciProblem({ CI: '1' })) && ciProblem({}) === null);
check('the page name: one line account/page', readTarget('some-one/orb-page' + NL).target === 'some-one/orb-page' && /not named/.test(readTarget(null).problem) && ['a/b:windows', 'https://x.itch.io/y', 'a/b' + NL + 'c/d', 'justone', ''].every((x) => !!readTarget(x).problem));

const log = lines('# Changelog', '', '## 0.1.8 (2026-12-09, abcdef12)', '', 'For players', 'A faster start.', '', 'For the team', '- x', '', '## 0.1.7 (2026-12-01, 1234abcd)', '', 'For players', 'First test build.', '', 'For the team', '- y');
const info = (v = '0.1.8', commit = 'abcdef1') => ({ commit, version: v });
const both = (a, b = a) => ({ windows: a, linux: b });
check('versions: the top entry with its players\' line passes', versionProblems(both(info()), log).length === 0, JSON.stringify(versionProblems(both(info()), log)));
check('versions: two commits, two versions, an older version, no players\' line and no entry are refused', has(versionProblems(both(info(), info('0.1.8', 'fffffff')), log), /different commits/) && has(versionProblems(both(info(), info('0.1.7')), log), /same version/) && has(versionProblems(both(info('0.1.7')), log), /top entry is 0\.1\.8/) && has(versionProblems(both(info()), log.replace('A faster start.', '(to be written: plain words, what a player sees that is new)')), /no line for players/) && has(versionProblems(both(info()), '# Changelog'), /no entry/));
check('versions: --rollback takes an earlier entry and refuses the newest and an unknown one', versionProblems(both(info('0.1.7')), log, { rollback: true }).length === 0 && has(versionProblems(both(info()), log, { rollback: true }), /newest version/) && has(versionProblems(both(info('0.0.9')), log, { rollback: true }), /no entry for version 0\.0\.9/));

// the whole judgement, with every way out replaced
const bytes = { windows: Buffer.from('a zip'), linux: Buffer.from('a tar') };
const sha = (b) => createHash('sha256').update(b).digest('hex');
const world = (over = {}) => ({
  env: {}, today,
  committed: (p) => ({ [APPROVALS.page.file]: pageYes, [APPROVALS.builds.file]: buildsYes })[p] ?? null,
  targetText: 'some-one/orb-page', changelog: log,
  archive: (f) => (f.endsWith('.zip') ? bytes.windows : bytes.linux),
  recorded: (s, c) => c === 'abcdef1' && (s === sha(bytes.windows) || s === sha(bytes.linux)),
  unpack: (c) => ({ dir: c, info: info() }),
  verify: () => [],
  ...over,
});
const opts = (over = {}) => ({ dir: 'x', pageYes: '2026-12-10', buildsYes: '2026-12-08', ...over });
const J = (o = {}, w = {}) => judge(opts(o), world(w));
const clean = J();
check('all holding: no problem, and the plan names both channels, the sums and the version', clean.problems.length === 0 && clean.plan.length === 2 && clean.plan[0].includes('some-one/orb-page:windows as version 0.1.8') && clean.plan[1].includes(sha(bytes.linux)) && clean.plan[1].includes(':linux'), JSON.stringify(clean));
check('in CI: the one refusal, and nothing else is read', (() => { const r = J({}, { env: { GITHUB_ACTIONS: 'true' }, committed: () => { throw new Error('read'); } }); return r.problems.length === 1 && /CI/.test(r.problems[0]) && r.plan.length === 0; })());
check('--push is refused even with everything else holding, and plans nothing', (() => { const r = J({ push: true }); return r.problems.length === 1 && /not written/.test(r.problems[0]) && r.plan.length === 0; })());
check('without either approval file: each is named', (() => { const r = J({}, { committed: () => null }); return has(r.problems, /restricted-itch-page\.txt/) && has(r.problems, /desktop-test-builds\.txt/) && r.plan.length === 0; })());
check('with one approval only, the other still refuses (RL-272)', (() => { const only = (k) => J({}, { committed: (p) => (p === APPROVALS[k].file ? (k === 'page' ? pageYes : buildsYes) : null) }); return only('page').problems.length === 1 && has(only('page').problems, /desktop-test-builds/) && only('builds').problems.length === 1 && has(only('builds').problems, /restricted-itch-page/); })());
check('an archive that is missing, does not unpack, is not recorded or fails the package check is refused', has(J({}, { archive: (f) => (f.endsWith('.zip') ? null : bytes.linux) }).problems, /windows-x86_64\.zip is not in the folder/) && has(J({}, { unpack: () => ({ problem: 'does not unpack' }) }).problems, /does not unpack/) && has(J({}, { recorded: () => false }).problems, /in no committed record/) && has(J({}, { verify: () => ['desktop package FAILED (windows): README.txt still holds the report-channel placeholder'] }).problems, /report-channel placeholder/));
check('no --dir and no page name are refused', has(J({ dir: null }).problems, /no --dir/) && has(J({}, { targetText: null }).problems, /not named/));
check('the two archive names are the workflow\'s', (() => { const wf = readFileSync(join(import.meta.dirname, '..', '..', '.github', 'workflows', 'desktop-builds.yml'), 'utf8'); return Object.values(ARCHIVES).every((n) => wf.includes(n)); })());

// it cannot send anything: no network module, no upload tool, and the only programs it starts are git, tar, unzip and node
{
  const src = readFileSync(join(import.meta.dirname, 'itch-push.mjs'), 'utf8');
  const code = src.split(NL).filter((l) => !l.trim().startsWith('//')).join(NL);
  const modules = [...code.matchAll(/from '([^']+)'/g)].map((m) => m[1]);
  check('the script imports no network module', modules.every((m) => !/^(node:)?(http|https|http2|net|tls|dgram|dns)$/.test(m)) && !/\bfetch\s*\(|\bimport\s*\(|\brequire\s*\(|WebSocket/.test(code), modules.join());
  const started = [...code.matchAll(/(?<![.A-Za-z])(?:spawnSync|execFileSync|spawn|exec|execFile|execSync)\(([^,()]+(?:\([^()]*\))?)/g)].map((m) => m[1].trim());
  check('it starts only git, tar, unzip and node, and never the upload tool', started.length > 0 && started.every((x) => ["'git'", 'winTar', "'unzip'", "'tar'", 'process.execPath'].includes(x)) && !/butler/i.test(code), started.join(' | '));
}
// the command itself, in this repository: refused (the approvals are not recorded), and refused in CI
{
  const cli = join(import.meta.dirname, 'itch-push.mjs');
  const env = { ...process.env }; delete env.CI; delete env.GITHUB_ACTIONS;
  const r = spawnSync(process.execPath, [cli, '--dir', join(import.meta.dirname, 'no-such-folder'), '--builds-yes', '2026-12-08', '--page-yes', '2026-12-10'], { encoding: 'utf8', env });
  check('the command exits 1 on a missing folder and says nothing was sent', r.status === 1 && /Nothing was sent/.test(r.stderr) && /is not in the folder/.test(r.stderr), r.stderr);
  const c = spawnSync(process.execPath, [cli, '--dir', '.'], { encoding: 'utf8', env: { ...env, GITHUB_ACTIONS: 'true' } });
  check('the command exits 1 in CI', c.status === 1 && /running in CI/.test(c.stderr), c.stderr);
  check('an unknown word is a usage error', spawnSync(process.execPath, [cli, '--yes-really'], { encoding: 'utf8', env }).status === 2 && spawnSync(process.execPath, [cli], { encoding: 'utf8', env }).status === 2);
}
console.log(failed ? `itch-push self-test FAILED: ${failed} of ${ran}` : `itch-push self-test ok: ${ran} checks`);
process.exit(failed ? 1 : 0);
