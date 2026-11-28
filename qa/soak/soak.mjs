// The two-hour soak of the built desktop program (QA; EP, path job 14). Windows and Linux.
//   node qa/soak/soak.mjs --package <zip | tar.gz | unpacked folder> [--seconds 7200] [--sample 10] [--seed 1] [--cap 600] [--max-fps 60] [--out <folder>] [--keep] [--census [--census-every 60]] [--same-seed]
// The package is the one tools/desktop-local-build.mjs makes. It is unpacked into a scratch folder, and the program runs exactly as shipped: the only addition is an override.cfg beside it naming
// soak_probe.gd (this folder) as an autoload, which starts computer-against-computer matches back to back, prints SOAK lines and quits after --seconds (qa/soak/soak_probe.gd).
// Headless (no window), below-normal priority, with its data folders moved into the scratch folder (never the real ones). The harness watches: the process's memory from outside (working set and
// private bytes on Windows, VmRSS on Linux; the release program reports no memory of its own), the probe's samples (ticks a second against 60, process frames, worst frame, object, node, resource
// and orphan counts), the exit code, the run marker (gone after a clean close), the engine's log (SCRIPT ERROR, ERROR and WARNING lines) and the report folder. A run past --seconds + 5 minutes is
// stopped by its process id and reported as a hang. Output: <out>/summary.md, summary.json, samples.csv, game.log, stdout.log (paths cleaned). Exit 0 when every check line passes, 1 when one fails, 2 usage.
// What headless cannot show: GPU memory, real frame rate on a screen, drivers. Node built-ins and PowerShell / tar only.
import { spawn, spawnSync } from 'node:child_process';
import { copyFileSync, createWriteStream, existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir, setPriority, constants as osConstants } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { cleanPaths } from '../../tools/record-paths.mjs';
import { splitter } from './split-lines.mjs';
import { userdataEnv, USERDATA_VARS } from '../../tools/lib/userdata.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const PROGRAMS = ['orb-combat-ex.exe', 'orb-combat-ex.x86_64'];

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const pkg = opt('--package', null);
if (!pkg || !existsSync(pkg)) { console.error('soak: --package <zip | tar.gz | folder> is needed (tools/desktop-local-build.mjs makes it)'); process.exit(2); }
const seconds = Number(opt('--seconds', 7200)), every = Number(opt('--sample', 10)), seed = Number(opt('--seed', 1)), cap = Number(opt('--cap', 600)), maxFps = Number(opt('--max-fps', 60));
const out = resolve(opt('--out', join(tmpdir(), 'orb-soak-' + new Date().toISOString().replace(/[:.]/g, '-'))));
const keep = argv.includes('--keep');

// ---------------------------------------------------------------- unpack
const scratch = mkdtempSync(join(tmpdir(), 'orb-soak-run-'));
const unpackDir = join(scratch, 'pkg');
mkdirSync(unpackDir, { recursive: true });
let root = resolve(pkg);
if (!statSync(root).isDirectory()) {
  let r;
  if (/\.zip$/i.test(root)) r = spawnSync('powershell', ['-NoProfile', '-NonInteractive', '-Command', `Expand-Archive -Path '${root}' -DestinationPath '${unpackDir}' -Force`], { encoding: 'utf8' });
  else r = spawnSync('tar', ['-xzf', root, '-C', unpackDir], { encoding: 'utf8' });
  if (r.status !== 0) { console.error('soak: could not unpack the package: ' + String(r.stderr).slice(0, 200)); process.exit(1); }
  root = unpackDir;
} else {
  const { cpSync } = await import('node:fs');
  cpSync(root, unpackDir, { recursive: true });
  root = unpackDir;
}
const findProgram = (d) => { for (const n of readdirSync(d)) { const f = join(d, n); if (statSync(f).isDirectory()) { const g = findProgram(f); if (g) return g; } else if (PROGRAMS.includes(n)) return f; } return null; };
const program = findProgram(root);
if (!program) { console.error('soak: no game program in the package'); process.exit(1); }
const gameDir = dirname(program);
let build = {};
try { build = JSON.parse(readFileSync(join(gameDir, 'build_info.json'), 'utf8')); } catch { /* none */ }

// ---------------------------------------------------------------- the probe, from outside
const probeDir = join(scratch, 'probe');
mkdirSync(probeDir, { recursive: true });
copyFileSync(join(HERE, 'soak_probe.gd'), join(probeDir, 'soak_probe.gd'));
// The store census (soak_census.gd): the names of the game's top-level static vars are read from the build's own commit (the exported program keeps no source to read them from).
const census = argv.includes('--census'), sameSeed = argv.includes('--same-seed');
let censusArg = [];
if (census) {
  copyFileSync(join(HERE, 'soak_census.gd'), join(probeDir, 'soak_census.gd'));
  const rev = build.commit || 'HEAD';
  const g = spawnSync('git', ['-C', join(HERE, '..', '..'), 'grep', '-E', '^static var [A-Za-z_0-9]+', rev, '--', 'sim', 'render', 'ui', 'audio'], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  const names = String(g.stdout || '').split('\n').map((l) => /^[^:]+:([^:]+):static var ([A-Za-z_0-9]+)/.exec(l)).filter((m) => m && !m[1].includes('/tools/')).map((m) => `res://${m[1]}|${m[2]}`);
  if (!names.length) { console.error('soak: --census needs the repository with the build commit (git grep found no static var)'); process.exit(1); }
  writeFileSync(join(probeDir, 'statics.txt'), names.join('\n') + '\n');
  censusArg = [`--soak-census=${join(probeDir, 'statics.txt').replace(/\\/g, '/')}`, `--soak-census-every=${Number(opt('--census-every', 0))}`];
}
writeFileSync(join(gameDir, 'override.cfg'), `[autoload]\n\nSoakProbe="*${join(probeDir, 'soak_probe.gd').replace(/\\/g, '/')}"\n`);
const data = join(scratch, 'data');
const env = userdataEnv(data);
for (const k of USERDATA_VARS) mkdirSync(env[k], { recursive: true });

// ---------------------------------------------------------------- run
mkdirSync(out, { recursive: true });
const gameLog = createWriteStream(join(scratch, 'stdout.log'));
const lines = [];
const memory = [];   // { t, workingMiB, privateMiB }
const t0 = Date.now();
// --frames=<huge> is main's own switch for a scripted run. Here it only skips the How to play card, which would hold the match. It does not skip the flashing notice: a locked build refuses the words that
// would (UiHud.bypass_allowed, RL-206), and a headless run never raises the notice at all (UiHud.notice_auto_allowed). Headless always (RL-279: a run with any display is not covered).
const args = ['--headless', '--max-fps', String(maxFps), '--', '--frames=2000000000', `--soak-seconds=${seconds}`, `--soak-sample=${every}`, `--soak-seed=${seed}`, `--soak-cap=${cap}`, ...(sameSeed ? ['--soak-same-seed'] : []), ...censusArg];
console.log(`soak: ${program.split(/[\\/]/).pop()} for ${seconds} s (sample ${every} s), build ${build.commit ? build.commit.slice(0, 8) : 'unknown'}; scratch ${scratch}`);
const child = spawn(program, args, { cwd: gameDir, env, stdio: ['ignore', 'pipe', 'pipe'], windowsHide: true });
try { setPriority(child.pid, osConstants.priority.PRIORITY_BELOW_NORMAL); } catch { /* gone */ }
const onLine = (l) => {
  lines.push(l);
  if (lines.length > 200000) lines.splice(0, 100000);
  if (l.startsWith('SOAK') && !l.startsWith('SOAK sample') && !l.startsWith('SOAK census t=')) console.log('  ' + l);
};
// One line buffer a stream (split-lines.mjs says why).
const streams = [child.stdout, child.stderr].map((stream) => {
  const cut = splitter(onLine);
  stream.setEncoding('utf8');
  stream.on('data', (d) => { gameLog.write(d); cut.take(d); });
  return cut;
});

// memory from outside
let sampler = null, linuxTimer = null;
if (process.platform === 'win32') {
  const ps = `while ($true) { $p = Get-Process -Id ${child.pid} -ErrorAction SilentlyContinue; if (-not $p) { break }; "{0} {1}" -f $p.WorkingSet64, $p.PrivateMemorySize64; Start-Sleep -Seconds ${every} }`;
  sampler = spawn('powershell', ['-NoProfile', '-NonInteractive', '-Command', ps], { stdio: ['ignore', 'pipe', 'ignore'], windowsHide: true });
  try { setPriority(sampler.pid, osConstants.priority.PRIORITY_BELOW_NORMAL); } catch { /* gone */ }
  let buf = '';
  sampler.stdout.on('data', (d) => {
    buf += d;
    const parts = buf.split(/\r?\n/); buf = parts.pop();
    for (const l of parts) { const [w, p] = l.trim().split(/\s+/).map(Number); if (w) memory.push({ t: (Date.now() - t0) / 1000, workingMiB: w / 1048576, privateMiB: p / 1048576 }); }
  });
} else {
  linuxTimer = setInterval(() => {
    try {
      const s = readFileSync(`/proc/${child.pid}/status`, 'utf8');
      const rss = Number((/VmRSS:\s+(\d+)/.exec(s) || [])[1] || 0), priv = Number((/VmData:\s+(\d+)/.exec(s) || [])[1] || 0);
      if (rss) memory.push({ t: (Date.now() - t0) / 1000, workingMiB: rss / 1024, privateMiB: priv / 1024 });
    } catch { /* gone */ }
  }, every * 1000);
}

let hung = false;
const killTree = () => { try { if (process.platform === 'win32') spawnSync('taskkill', ['/PID', String(child.pid), '/T', '/F'], { windowsHide: true }); else child.kill('SIGKILL'); } catch { /* gone */ } };
const limit = setTimeout(() => { hung = true; killTree(); }, (seconds + 300) * 1000);
for (const sig of ['SIGINT', 'SIGTERM']) process.on(sig, () => { killTree(); if (sampler) sampler.kill(); process.exit(1); });

const exit = await new Promise((done) => { child.on('close', (code, signal) => done({ code, signal })); child.on('error', (e) => done({ code: -1, signal: null, error: String(e) })); });
clearTimeout(limit);
if (linuxTimer) clearInterval(linuxTimer);
if (sampler) { try { sampler.kill(); } catch { /* gone */ } }
for (const s of streams) s.end();
await new Promise((r) => gameLog.end(r));
const wall = (Date.now() - t0) / 1000;

// ---------------------------------------------------------------- what it left
const walk = (d, acc = []) => { if (!existsSync(d)) return acc; for (const n of readdirSync(d)) { const f = join(d, n); if (statSync(f).isDirectory()) walk(f, acc); else acc.push(f); } return acc; };
const files = walk(data);
const markers = files.filter((f) => /run-marker-\d+\.txt$/.test(f));
const engineLog = files.find((f) => /[\\/]logs[\\/]godot\.log$/.test(f));
const reportLogs = files.filter((f) => /[\\/]reports[\\/]/.test(f)).map((f) => f.split(/[\\/]/).pop());
const logText = engineLog ? readFileSync(engineLog, 'utf8') : '';
// The tallies read what the program printed (stdout and stderr), not the engine log: the exit-time leak lines are printed after the log is closed.
const logLines = lines;
const mainFound = Number((/SOAK main found after (\d+) ms/.exec(lines.join('\n')) || [])[1]);
const tally = (re) => { const m = new Map(); for (const l of logLines) if (re.test(l)) { const k = l.trim().slice(0, 200); m.set(k, (m.get(k) || 0) + 1); } return [...m.entries()].sort((a, b) => b[1] - a[1]); };
const scriptErrors = tally(/SCRIPT ERROR/), errors = tally(/^\s*ERROR:/), warnings = tally(/^\s*WARNING:/);

const kv = (l) => Object.fromEntries([...l.matchAll(/(\w+)=([\w.\-]+)/g)].map((m) => [m[1], isNaN(Number(m[2])) ? m[2] : Number(m[2])]));
const samples = lines.filter((l) => l.startsWith('SOAK sample')).map(kv);
const ended = lines.filter((l) => /^SOAK match \d+ ended/.test(l)).map(kv);
const started = lines.filter((l) => /^SOAK match \d+ started/.test(l));
const quitLine = lines.find((l) => l.startsWith('SOAK quit'));
const aiBoth = lines.filter((l) => /computer plays both: /.test(l)).every((l) => /computer plays both: true/.test(l));

const med = (a) => { if (!a.length) return NaN; const b = [...a].sort((x, y) => x - y); return b[Math.floor((b.length - 1) / 2)]; };
const pct = (a, p) => { if (!a.length) return NaN; const b = [...a].sort((x, y) => x - y); return b[Math.min(b.length - 1, Math.floor((b.length - 1) * p))]; };
/** Least-squares slope in MiB an hour over the samples after the warm-up (the first 10% of the run, at least 120 s). */
const warm = Math.max(120, seconds * 0.1);
const slope = (key) => { const s = memory.filter((m) => m.t >= warm); if (s.length < 3) return NaN; const mx = s.reduce((a, m) => a + m.t, 0) / s.length, my = s.reduce((a, m) => a + m[key], 0) / s.length; let num = 0, den = 0; for (const m of s) { num += (m.t - mx) * (m[key] - my); den += (m.t - mx) ** 2; } return den ? (num / den) * 3600 : NaN; };
const first = (key) => { const s = memory.filter((m) => m.t >= warm); return s.length ? s[0][key] : (memory[0] || {})[key]; };
const last = (key) => (memory.length ? memory[memory.length - 1][key] : NaN);
const f1 = (x) => (Number.isFinite(x) ? x.toFixed(1) : 'n/a');

// the first two samples carry the boot and the first match's start
const steady = samples.slice(2);
const ticksMed = med(steady.map((s) => s.ticksPerSec).filter(Number.isFinite));
// A long run must change matches several times, or growth between matches is never read. A match is at most --cap sim seconds, about 1.5 times that on the clock (holds and cut-ins), plus a minute to spare.
const matchStarts = started.length + 1;
const startsWanted = Math.floor(seconds / (cap * 1.5 + 60));

const checks = [
  ['the program found the game and played the computer against itself', samples.length > 0 && aiBoth, `${samples.length} samples`],
  ['it ran the whole time and quit when asked (not a crash, a stall or a hang)', !hung && !!quitLine && /why=time/.test(quitLine), quitLine ? quitLine.replace('SOAK ', '') : hung ? 'stopped by the time limit (a hang)' : 'no quit line'],
  ['it exited cleanly (exit code 0, no signal)', exit.code === 0 && !exit.signal, `exit ${exit.code}${exit.signal ? ' signal ' + exit.signal : ''}${exit.error ? ' ' + exit.error : ''}`],
  ['the run marker is gone after the close', markers.length === 0, markers.length ? `${markers.length} left` : 'none left'],
  ['no SCRIPT ERROR line printed',scriptErrors.length === 0, scriptErrors.length ? `${scriptErrors.reduce((a, e) => a + e[1], 0)} lines, ${scriptErrors.length} kinds` : 'none'],
  ['the game kept up: median at least 58 ticks a second after the start', Number.isFinite(ticksMed) && ticksMed >= 58, `median ${f1(ticksMed)}`],
  ['the run changed matches often enough to read growth between them', startsWanted < 2 || matchStarts >= startsWanted, startsWanted < 2 ? `not asked of a run this short (${matchStarts} started)` : `${matchStarts} started, at least ${startsWanted} wanted`],
];

const matches = ended.length;
// Growth across matches against growth within one: the memory read 20 s after each later match began (its world built), with the engine's object count at its start.
const boundaries = started.map((l) => ({ ...kv(l), match: Number((/match (\d+) started/.exec(l) || [])[1]) })).filter((m) => Number.isFinite(m.t)).map((m) => { const at = memory.find((x) => x.t >= m.t + 20); return { match: m.match, t: m.t, objects: m.objects, workingMiB: at ? at.workingMiB : NaN, privateMiB: at ? at.privateMiB : NaN }; });
const sum = {
  program: program.split(/[\\/]/).pop(), build, platform: process.platform, seconds, wallSeconds: Math.round(wall), exit, hung,
  matches: { started: matchStarts, ended: matches, byHow: ended.reduce((a, e) => ((a[e.how] = (a[e.how] || 0) + 1), a), {}), medianSimSeconds: med(ended.map((e) => e.simSeconds)) },
  memory: { samples: memory.length, warmupSeconds: warm, workingMiB: { afterWarmup: first('workingMiB'), end: last('workingMiB'), max: Math.max(0, ...memory.map((m) => m.workingMiB)), slopeMiBPerHour: slope('workingMiB') }, privateMiB: { afterWarmup: first('privateMiB'), end: last('privateMiB'), max: Math.max(0, ...memory.map((m) => m.privateMiB)), slopeMiBPerHour: slope('privateMiB') } },
  frames: { fpsMedian: med(steady.map((s) => s.fps)), ticksPerSecMedian: ticksMed, ticksPerSecP5: pct(steady.map((s) => s.ticksPerSec), 0.05), worstFrameMsMedian: med(steady.map((s) => s.worstFrameMs)), worstFrameMsMax: Math.max(0, ...steady.map((s) => s.worstFrameMs).filter(Number.isFinite)), processMsMedian: med(steady.map((s) => s.processMs)) },
  objects: Object.fromEntries(['objects', 'nodes', 'resources', 'orphans'].map((k) => [k, { afterStart: steady.length ? steady[0][k] : null, end: samples.length ? samples[samples.length - 1][k] : null, max: Math.max(0, ...samples.map((s) => s[k] || 0)) }])),
  boundaries,
  log: { scriptErrors: scriptErrors.slice(0, 20), errors: errors.slice(0, 20), warnings: warnings.slice(0, 20), engineLogFound: !!engineLog, reportFolder: reportLogs },
  checks: checks.map(([name, ok, detail]) => ({ name, ok, detail })),
};

const md = [];
md.push(`# Soak: ${seconds} s asked, ${Math.round(wall)} s run (${process.platform}; build ${build.commit ? build.commit.slice(0, 8) : 'unknown'}, version ${build.version || 'unknown'})`, '');
md.push('| Check | Result | Detail |', '| :--- | :--- | :--- |', ...checks.map(([n, ok, d]) => `| ${n} | ${ok ? 'PASS' : 'FAIL'} | ${d} |`), '');
md.push(`The first match was up ${Number.isFinite(mainFound) ? (mainFound / 1000).toFixed(1) + ' s' : 'never'} after the program started.`, '');
md.push(`**Matches:** ${sum.matches.ended} ended (${Object.entries(sum.matches.byHow).map(([k, v]) => `${k} ${v}`).join(', ') || 'none'}), median ${f1(sum.matches.medianSimSeconds)} sim seconds.`, '');
md.push('| Memory (from outside), MiB | after warm-up | end | max | slope, MiB an hour |', '| :--- | ---: | ---: | ---: | ---: |');
for (const [label, k] of [['working set / resident', 'workingMiB'], ['private / data', 'privateMiB']]) { const m = sum.memory[k]; md.push(`| ${label} | ${f1(m.afterWarmup)} | ${f1(m.end)} | ${f1(m.max)} | ${f1(m.slopeMiBPerHour)} |`); }
md.push('', `Warm-up cut: ${Math.round(warm)} s; ${memory.length} memory samples. The slope on a short run is noise; read it on the two-hour run only.`, '');
if (boundaries.length) md.push('| Match | began at, s | objects at start | working set 20 s in, MiB | private, MiB |', '| ---: | ---: | ---: | ---: | ---: |', ...boundaries.map((b) => `| ${b.match} | ${b.t} | ${b.objects} | ${f1(b.workingMiB)} | ${f1(b.privateMiB)} |`), '');
md.push(`**Frames (headless, capped at ${maxFps}):** ${f1(sum.frames.ticksPerSecMedian)} ticks a second median (5th percentile ${f1(sum.frames.ticksPerSecP5)}), ${f1(sum.frames.fpsMedian)} process frames a second, worst frame in a window ${f1(sum.frames.worstFrameMsMedian)} ms median, ${f1(sum.frames.worstFrameMsMax)} ms at most, process time ${f1(sum.frames.processMsMedian)} ms.`, '');
md.push('| Counts | after start | end | max |', '| :--- | ---: | ---: | ---: |', ...Object.entries(sum.objects).map(([k, v]) => `| ${k} | ${v.afterStart} | ${v.end} | ${v.max} |`), '');
md.push(`**Log:** engine log ${engineLog ? 'found' : 'NOT found'}; SCRIPT ERROR kinds ${scriptErrors.length}, ERROR kinds ${errors.length}, WARNING kinds ${warnings.length}; report folder: ${reportLogs.length ? reportLogs.join(', ') : 'empty (a clean run copies nothing)'}.`);
for (const [title, list] of [['SCRIPT ERROR', scriptErrors], ['ERROR', errors], ['WARNING', warnings]]) if (list.length) md.push('', `${title} lines, most common first:`, ...list.slice(0, 8).map(([l, n]) => `- ${n}x \`${l.replace(/`/g, "'")}\``));

const clean = (s) => cleanPaths(s);
writeFileSync(join(out, 'summary.md'), clean(md.join('\n')) + '\n');
writeFileSync(join(out, 'summary.json'), clean(JSON.stringify(sum, null, 1)) + '\n');
writeFileSync(join(out, 'game.log'), clean(logText));
if (census) {
  const taken = lines.map((l) => /^SOAK census t=(\d+) match=(\d+) when=(\w+) ms=(\d+) data=(\{.*\})$/.exec(l)).filter(Boolean).map((m) => ({ t: Number(m[1]), match: Number(m[2]), when: m[3], ms: Number(m[4]), data: JSON.parse(m[5]) }));
  writeFileSync(join(out, 'census.json'), clean(JSON.stringify(taken)) + '\n');
}
writeFileSync(join(out, 'stdout.log'), clean(lines.join('\n')) + '\n');   // what the program printed (a crash may leave the engine log empty)
const cols = ['t', 'match', 'simT', 'fps', 'ticksPerSec', 'worstFrameMs', 'processMs', 'objects', 'nodes', 'resources', 'orphans'];
writeFileSync(join(out, 'samples.csv'), [cols.join(','), ...samples.map((s) => cols.map((c) => s[c]).join(','))].join('\n') + '\n\n' + ['t,workingMiB,privateMiB', ...memory.map((m) => `${m.t.toFixed(0)},${m.workingMiB.toFixed(1)},${m.privateMiB.toFixed(1)}`)].join('\n') + '\n');
console.log(clean(md.join('\n')));
console.log(`\nsoak: written to ${out}`);
const passed = checks.every((c) => c[1]);
// A failed run keeps its scratch folder (the game's data folder with the engine's logs and anything the next start would put in the report folder): a crash is read there (tools/crash/crash-check.mjs says what one leaves).
if (!keep && passed) { try { rmSync(scratch, { recursive: true, force: true }); } catch { /* left for the OS */ } }
else console.log(`soak: scratch kept at ${scratch}${passed ? '' : ' (a check failed)'}`);
process.exit(passed ? 0 : 1);
