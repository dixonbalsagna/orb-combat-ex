// The upload to the restricted, key-only itch.io page: THE REFUSALS ONLY (Tools, 2026-11-25; A2 job 4; docs/tools/store-page-checklist.md section 5; Legal RL-261, RL-262, RL-272).
// This script sends nothing. It runs no upload tool and opens no connection: it answers "may these two files go up, and where would they go?", and with --write-cmd, once every check holds, it writes the
// upload as a file Orb runs by hand (UPLOAD.cmd, or ROLLBACK.cmd with --rollback), in the folder of the archives. That file first runs these checks again and stops if one fails, then calls itch.io's own
// tool (butler, installed and signed in by Orb). Nothing here ever starts it. The upload is Orb's, by hand, on Orb's PC; it never runs in CI.
//
//   node tools/store/itch-push.mjs --dir <folder> --builds-yes <date> --page-yes <date> [--target-file <file>] [--rollback] [--write-cmd]
// THE ONE-STEP ROLL-BACK: the same line with --rollback --write-cmd and --dir naming the PREVIOUS accepted build's folder, then run ROLLBACK.cmd there. itch.io has no "go back" command: an earlier build is
// pushed again, as "<version>-rollback".
// How each file goes up (butler's page says a .zip is unpacked on upload and says nothing of .tar.gz or of the executable bit from Windows): the Windows zip as it is; the Linux .tar.gz inside a folder of its
// own, so the file arrives as it is and keeps its executable bit. Both to be seen on the spare page before a friend gets a key.
//
// <folder> holds orb-combat-ex-windows-x86_64.zip and orb-combat-ex-linux-x86_64.tar.gz of one commit. It refuses unless ALL of:
//   - it is not running in CI;
//   - both approval files are COMMITTED (read from HEAD, so a file written on the day and not committed is not a yes): docs/ep/approvals/restricted-itch-page.txt (a scope line naming the restricted itch.io page)
//     and docs/ep/approvals/desktop-test-builds.txt (a scope line naming desktop test builds), each with the date typed here, 0 to 30 days old, and a recorded-by line. Neither approves the other (RL-272);
//   - each archive's SHA-256 is in a committed record under docs/tools/runs/<commit>/;
//   - each archive unpacks and passes `desktop-package.mjs verify --locked --testers` (the testers' words, a filled report channel, Reduce flashing locked, the testers' menu, no net/);
//   - both name the same commit and version, and the version is the changelog's top entry with its line for players written (--rollback: any earlier entry, pushed as "<version>-rollback");
//   - the page is named: one line "account/page" in the git-ignored .private/store/itch-target.txt. The account name stays off the repository. Two channels only: windows and linux.
// Exit 0: every check holds (a dry run; nothing was sent). 1: refused, every reason printed. 2: usage. Node built-ins, git, the system's tar or unzip.
import { createHash } from 'node:crypto';
import { execFileSync, spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { entriesOf, PLACEHOLDER } from '../version.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = resolve(HERE, '..', '..');
export const ARCHIVES = { windows: 'orb-combat-ex-windows-x86_64.zip', linux: 'orb-combat-ex-linux-x86_64.tar.gz' };
export const CHANNELS = ['windows', 'linux'];
export const TARGET_FILE = '.private/store/itch-target.txt';
export const APPROVALS = {
  page: { file: 'docs/ep/approvals/restricted-itch-page.txt', scope: /restricted(, key-only,?)? itch\.io page/i, what: 'the restricted itch.io page', option: '--page-yes' },   // RL-272 asks for "restricted itch.io page"; its own scope line says "restricted, key-only itch.io page": both read
  builds: { file: 'docs/ep/approvals/desktop-test-builds.txt', scope: /desktop test builds/i, what: 'desktop test builds', option: '--builds-yes' },
};
const MAX_AGE_DAYS = 30;

/** Why CI refuses, or null. Pure. */
export function ciProblem(env) {
  return env.GITHUB_ACTIONS || env.CI ? 'this is running in CI: no workflow pushes to itch.io (RL-262); the upload is Orb\'s, by hand' : null;
}

/** Problems with one approval file's committed text (null: the file is not committed). `typed` is the date given on the command line, `today` yyyy-mm-dd. Pure. */
export function approvalProblems(kind, text, typed, today) {
  const a = APPROVALS[kind];
  if (text === null || text === undefined) return [`there is no committed ${a.file}: Orb's recorded yes to ${a.what} is missing`];
  const out = [];
  const line = (k) => { const m = new RegExp(`^${k}:[ \\t]*(.*)$`, 'm').exec(String(text).split('\r').join('')); return m ? m[1].trim() : null; };
  const date = line('date');
  if (!typed || !/^\d{4}-\d{2}-\d{2}$/.test(typed)) out.push(`${a.option} must be the date (yyyy-mm-dd) of Orb's yes to ${a.what}`);
  else if (date !== typed) out.push(`${a.file}: its date (${date || 'none'}) is not the one typed with ${a.option} (${typed})`);
  if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date) || Number.isNaN(Date.parse(date))) out.push(`${a.file} has no "date: yyyy-mm-dd" line`);
  else {
    const age = Math.round((Date.parse(today) - Date.parse(date)) / 86400000);
    if (age < 0 || age > MAX_AGE_DAYS) out.push(`${a.file}: the yes of ${date} is ${age} days old (0 to ${MAX_AGE_DAYS} allowed): ask Orb again`);
  }
  if (!a.scope.test(line('scope') || '')) out.push(`${a.file} does not name ${a.what} in its scope: line`);
  if (!line('recorded-by')) out.push(`${a.file} has no recorded-by: line`);
  return out;
}

/** The page's name from the target file's text: { target } or { problem }. Pure. */
export function readTarget(text) {
  if (text === null || text === undefined) return { problem: `the page is not named: write one line "account/page" in ${TARGET_FILE} (git ignores it)` };
  const lines = String(text).replace(/^\uFEFF/, '').split('\n').map((l) => l.trim()).filter(Boolean);
  if (lines.length !== 1 || !/^[a-z0-9_-]+\/[a-z0-9_-]+$/.test(lines[0])) return { problem: `${TARGET_FILE} must hold exactly one line "account/page" in small letters, digits, - and _ (no address, no channel)` };
  return { target: lines[0] };
}

/** Problems with the two packages' build_info against the changelog. infos: { windows: {commit, version}, linux: {...} }. Pure. */
export function versionProblems(infos, logText, { rollback = false } = {}) {
  const out = [];
  const w = infos.windows, l = infos.linux;
  if (!w || !l) return ['a package has no readable build_info.json'];
  if (w.commit !== l.commit) out.push(`the two archives are of different commits (${w.commit} and ${l.commit})`);
  if (!w.version || w.version !== l.version) out.push(`the two archives do not name the same version (${w.version || 'none'} and ${l.version || 'none'})`);
  const es = entriesOf(logText);
  if (!es.length) { out.push('docs/tools/changelog.md has no entry: the build has not been numbered (node tools/version.mjs --next)'); return out; }
  const e = es.find((x) => x.version === w.version);
  if (!rollback && es[0].version !== w.version) out.push(`the archives are version ${w.version || 'none'}, the changelog's top entry is ${es[0].version}: not the build being released (to go back to an earlier one use --rollback)`);
  else if (rollback && !e) out.push(`--rollback: the changelog has no entry for version ${w.version || 'none'}`);
  else if (rollback && es[0].version === w.version) out.push('--rollback: these archives are the newest version, not an earlier one');
  if (e && (!e.players || e.players === PLACEHOLDER)) out.push(`the changelog entry for ${e.version} has no line for players yet (Orb reads it first)`);
  return out;
}

/** What a push would be, in words. Pure. */
export function plan(target, version, sums, { rollback = false } = {}) {
  return CHANNELS.map((c) => `WOULD PUSH ${ARCHIVES[c]} (sha256 ${sums[c]}) to ${target}:${c} as version ${version}${rollback ? '-rollback' : ''}`);
}

/** The upload (or roll-back) file Orb runs by hand, as text. It re-runs the checks first and stops when they fail. `dir`, `node` and `script` are paths on Orb\'s PC; `args` the checking arguments. Pure. */
export function cmdFile({ node, script, dir, args, target, version, rollback = false }) {
  for (const p of [node, script, dir]) if (/["%\r\n]/.test(p)) throw new Error(`a path with a quote, a percent sign or a line break cannot go in a command file: ${p}`);
  if (!/^[a-z0-9_-]+\/[a-z0-9_-]+$/.test(target)) throw new Error('the page name is not account/page');
  if (!/^\d+\.\d+\.\d+$/.test(version)) throw new Error('the version is not a.b.c');
  const v = `${version}${rollback ? '-rollback' : ''}`;
  const linux = join(dir, 'linux-channel');
  const q = (x) => `"${x}"`;
  const lines = [
    '@echo off',
    `rem ${rollback ? 'ROLL BACK' : 'UPLOAD'} of version ${v} to the restricted itch.io page. Written by tools/store/itch-push.mjs after every check held. Run it by hand; it checks again first.`,
    `echo ${rollback ? 'Rolling back' : 'Uploading'} version ${v} to ${target}. Close this window now to stop.`,
    'pause',
    [node, script, ...args].map(q).join(' '),
    'if errorlevel 1 ( echo. & echo A check failed: nothing was uploaded. & pause & exit /b 1 )',
    `if not exist ${q(linux)} mkdir ${q(linux)}`,
    `copy /y ${q(join(dir, ARCHIVES.linux))} ${q(linux)} >nul`,
    'if errorlevel 1 ( echo The Linux file could not be copied: nothing was uploaded. & pause & exit /b 1 )',
    `butler push ${q(join(dir, ARCHIVES.windows))} ${target}:windows --userversion ${v}`,
    'if errorlevel 1 ( echo The Windows upload FAILED. Nothing else was uploaded. & pause & exit /b 1 )',
    `butler push ${q(linux)} ${target}:linux --userversion ${v}`,
    'if errorlevel 1 ( echo The Linux upload FAILED: the Windows file IS up. Run this file again, or roll back. & pause & exit /b 1 )',
    `echo. & echo Both files were sent as version ${v}. Check the page.`,
    'pause',
  ];
  return lines.join('\r\n') + '\r\n';
}
/** Every refusal that holds, in one list, with the plan when there is none. `deps` are the only ways this reaches outside itself (the self-test replaces them). */
export function judge(opts, deps) {
  const ci = ciProblem(deps.env);
  if (ci) return { problems: [ci], plan: [] };
  const problems = [];
  if (opts.push) problems.push('--push: this script never uploads. With --write-cmd it writes the upload as a file you run by hand');
  problems.push(...approvalProblems('page', deps.committed(APPROVALS.page.file), opts.pageYes, deps.today));
  problems.push(...approvalProblems('builds', deps.committed(APPROVALS.builds.file), opts.buildsYes, deps.today));
  const t = readTarget(deps.targetText);
  if (t.problem) problems.push(t.problem);
  const sums = {}, infos = {};
  if (!opts.dir) problems.push('no --dir with the two archives');
  else {
    for (const c of CHANNELS) {
      const bytes = deps.archive(join(opts.dir, ARCHIVES[c]));
      if (!bytes) { problems.push(`${ARCHIVES[c]} is not in the folder`); continue; }
      sums[c] = createHash('sha256').update(bytes).digest('hex');
      const u = deps.unpack(c, join(opts.dir, ARCHIVES[c]));
      if (u.problem) { problems.push(`${ARCHIVES[c]}: ${u.problem}`); continue; }
      infos[c] = u.info;
      if (!u.info || !/^[0-9a-f]{7}$/.test(String(u.info.commit))) { problems.push(`${ARCHIVES[c]}: no commit in its build_info.json`); continue; }
      if (!deps.recorded(sums[c], u.info.commit)) problems.push(`${ARCHIVES[c]}: its SHA-256 ${sums[c]} is in no committed record under docs/tools/runs/${u.info.commit}*/: these are not the recorded files`);
      problems.push(...deps.verify(c, u.dir, u.info.commit).map((p) => `${ARCHIVES[c]}: ${p}`));
    }
    if (infos.windows && infos.linux) problems.push(...versionProblems(infos, deps.changelog, opts));
  }
  return { problems, plan: problems.length ? [] : plan(t.target, infos.windows.version, sums, opts), target: t.target, version: problems.length ? null : infos.windows.version };
}

// ---- the real world ----
function git(...a) { try { return execFileSync('git', ['-C', REPO, ...a], { encoding: 'utf8', maxBuffer: 32 * 1024 * 1024, stdio: ['ignore', 'pipe', 'ignore'] }); } catch { return null; } }

export function realDeps(opts, scratch) {
  const winTar = join(process.env.SystemRoot || 'C:/Windows', 'System32', 'tar.exe');
  const targetFile = opts.targetFile ? resolve(opts.targetFile) : join(REPO, TARGET_FILE);
  return {
    env: process.env,
    today: new Date().toISOString().slice(0, 10),
    committed: (path) => git('show', `HEAD:${path}`),
    targetText: existsSync(targetFile) ? readFileSync(targetFile, 'utf8') : null,
    changelog: existsSync(join(REPO, 'docs', 'tools', 'changelog.md')) ? readFileSync(join(REPO, 'docs', 'tools', 'changelog.md'), 'utf8') : '',
    archive: (f) => (existsSync(f) ? readFileSync(f) : null),
    recorded: (sum, commit) => !!git('grep', '-l', '-F', sum, 'HEAD', '--', `docs/tools/runs/${commit}*`),
    unpack: (channel, file) => {
      const to = join(scratch, channel);
      mkdirSync(to, { recursive: true });
      const r = process.platform === 'win32' ? spawnSync(winTar, ['-xf', file, '-C', to], { encoding: 'utf8' }) : channel === 'windows' ? spawnSync('unzip', ['-q', file, '-d', to], { encoding: 'utf8' }) : spawnSync('tar', ['-xzf', file, '-C', to], { encoding: 'utf8' });
      if (r.status !== 0) return { problem: 'does not unpack' };
      const dir = join(to, ARCHIVES[channel].replace(/\.(zip|tar\.gz)$/, ''));
      try { return { dir, info: JSON.parse(readFileSync(join(dir, 'build_info.json'), 'utf8')) }; } catch { return { problem: 'holds no folder with a build_info.json' }; }
    },
    verify: (channel, dir, commit) => {
      const r = spawnSync(process.execPath, [join(REPO, 'tools', 'desktop-package.mjs'), 'verify', '--platform', channel, '--dir', dir, '--commit', commit, '--locked', '--testers'], { encoding: 'utf8' });
      return r.status === 0 ? [] : String(r.stderr || 'the package check did not run').split('\n').map((l) => l.trim()).filter(Boolean);
    },
  };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const a = process.argv.slice(2);
  const opt = (n) => { const i = a.indexOf(n); return i >= 0 ? a[i + 1] : undefined; };
  const known = ['--dir', '--builds-yes', '--page-yes', '--target-file', '--rollback', '--push', '--write-cmd'];
  const odd = a.filter((x, i) => !known.includes(x) && !['--dir', '--builds-yes', '--page-yes', '--target-file'].includes(a[i - 1]));
  if (odd.length || !a.length) { console.error('usage: node tools/store/itch-push.mjs --dir <folder> --builds-yes <date> --page-yes <date> [--target-file <file>] [--rollback] [--write-cmd]   (it checks; it sends nothing)'); process.exit(2); }
  const opts = { dir: opt('--dir') ? resolve(opt('--dir')) : null, buildsYes: opt('--builds-yes'), pageYes: opt('--page-yes'), targetFile: opt('--target-file'), rollback: a.includes('--rollback'), push: a.includes('--push') };
  const scratch = mkdtempSync(join(tmpdir(), 'itch-check-'));
  let r;
  try { r = judge(opts, realDeps(opts, scratch)); } finally { rmSync(scratch, { recursive: true, force: true }); }
  if (r.problems.length) { for (const p of r.problems) console.error(`itch-push REFUSED: ${p}`); console.error('Nothing was sent.'); process.exit(1); }
  for (const l of r.plan) console.log(l);
  if (a.includes('--write-cmd')) {
    const name = opts.rollback ? 'ROLLBACK.cmd' : 'UPLOAD.cmd';
    // the same checks, run again by the file itself: the arguments as given, without --write-cmd
    const again = a.filter((x) => x !== '--write-cmd').map((x, i, all) => (all[i - 1] === '--dir' ? opts.dir : all[i - 1] === '--target-file' ? resolve(x) : x));
    writeFileSync(join(opts.dir, name), cmdFile({ node: process.execPath, script: fileURLToPath(import.meta.url), dir: opts.dir, args: again, target: r.target, version: r.version, rollback: opts.rollback }));
    console.log(`Wrote ${join(opts.dir, name)}: run it by hand when you mean to ${opts.rollback ? 'roll back' : 'upload'}.`);
  }
  console.log('Every check holds. This script sent nothing.');
}
