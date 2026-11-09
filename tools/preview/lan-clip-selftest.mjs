// Self-test of the LAN report tools (Tools, 2026-11-08): the strip decode, the clip window, the file finder, the shortcut text, the refusals. No browser, no Godot; node built-ins only.
//   node tools/preview/lan-clip-selftest.mjs
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, existsSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { rowOf, rowsFromInputs, pictureTicks, stripFor } from './lan-strip.mjs';
import { planWindow, html, reportMarks, commitOf, groupMarks } from './lan-clip.mjs';
import { findFiles, keptBuildFor, readmeText, cmdText, newestPerPc, clipJobs, SAVED } from './lan-report.mjs';

const HERE = resolve(fileURLToPath(new URL('.', import.meta.url)));
let bad = 0, n = 0;
const ok = (cond, msg) => { n++; if (!cond) { bad++; console.log('FAIL ' + msg); } };
const eq = (a, b, msg) => ok(JSON.stringify(a) === JSON.stringify(b), `${msg}: got ${JSON.stringify(a)} want ${JSON.stringify(b)}`);

// pack as sim/input/intent.gd SimIntent.pack does: mx 0-7 (k+127), my 8-15, bits 23.. guard guardPress dodge sprint power powerPress powerTap light heavy sig context transform, stance 35, lightHeld 40, heavyHeld 41, stanceMask 47-50, contextHeld 51, sigHeld 52
const pack = (o = {}) => {
  let p = BigInt(Math.round((o.mx || 0) * 127) + 127) | (BigInt(Math.round((o.my || 0) * 127) + 127) << 8n);
  let b = 23n;
  for (const k of ['guard', 'guardPress', 'dodge', 'sprint', 'power', 'powerPress', 'powerTap', 'light', 'heavy', 'sig', 'context', 'transform']) { if (o[k]) p |= 1n << b; b++; }
  if (o.lightHeld) p |= 1n << 40n; if (o.heavyHeld) p |= 1n << 41n;
  p |= BigInt((o.stanceMask || 0) & 15) << 47n;
  if (o.contextHeld) p |= 1n << 51n; if (o.sigHeld) p |= 1n << 52n;
  return [Number(p & 0xFFFFFFFFn), Number(p >> 32n)];
};
const FLAG = { light: 0, heavy: 1, sig: 2, dodge: 3, guardPress: 4, lightHeld: 5, heavyHeld: 6, sigHeld: 7, rsHeld: 8, rsStart: 9, guard: 10, sprint: 11, power: 12, context: 13, contextHeld: 14, powerPress: 16, transform: 17 };

// 1. the decode: every named bit lands on the hook's flag
for (const k of Object.keys(FLAG)) {
  if (k === 'rsHeld' || k === 'rsStart') continue;
  const [lo, hi] = pack({ [k]: true });
  const r = rowOf(10, 0, lo, hi, 0);
  ok(((r[4] >> FLAG[k]) & 1) === 1, `${k} sets flag bit ${FLAG[k]}`);
  ok(r[4] === (1 << FLAG[k]), `${k} sets only its own flag (got ${r[4]})`);
}
eq(rowOf(1, 0, ...pack({ mx: 1, my: -1 }), 0).slice(2, 4), [100, -100], 'stick at the corners');
eq(rowOf(1, 0, ...pack({ mx: 0, my: 0 }), 0).slice(2, 4), [0, 0], 'stick at rest');
eq(rowOf(1, 0, ...pack({ stanceMask: 10 }), 0)[7], 10, 'stance mask');
eq(rowOf(1, 0, ...pack({}), (1 | 2 | (3 << 4) | (2 << 7)))[4] >> 8 & 3, 3, 'word two: rsHeld and rsStart');
eq(rowOf(1, 0, ...pack({}), (1 | (3 << 4) | (2 << 7))).slice(5, 7), [3, 2], 'word two: direction and level');
eq(rowOf(1, 0, null, null, 0).slice(2), [0, 0, 0, 0, 0, 0], 'a null entry is neutral');

// 2. holds between entries, a null entry ends them
const inputs = [[5, 0, ...pack({ sigHeld: true }), 0], [20, 0, null, null], [8, 1, ...pack({ lightHeld: true })]];
const rows = rowsFromInputs(inputs, 0, 0, 25);
ok(rows.length === 26, 'one row per tick');
ok(((rows[4][4] >> 7) & 1) === 0 && ((rows[5][4] >> 7) & 1) === 1 && ((rows[19][4] >> 7) & 1) === 1 && ((rows[20][4] >> 7) & 1) === 0, 'sigHeld from tick 5 through 19, gone at 20');
ok(rowsFromInputs(inputs, 1, 0, 25)[9][4] >> 5 & 1, "the other slot's own entry");
ok(((rowsFromInputs(inputs, 1, 0, 25)[3][4] >> 5) & 1) === 0, "the other slot's entry does not reach back");
// 3. the picture rule is blackbox-clip's own
eq(pictureTicks(10, 30, 6), [12, 18, 24, 30], 'picture ticks on a grid');
eq(pictureTicks(10, 31, 6), [12, 18, 24, 30, 31], 'the last tick is always a picture');
eq(pictureTicks(7, 7, 6), [7], 'a one-tick window');
// 4. the strip for those pictures reads hold for a long B
const st = stripFor([[0, 0, ...pack({ sigHeld: true }), 0]], 0, 100, 160, 6);
eq(st.ticks.length, st.frames.length, 'one strip state per picture');
ok(st.frames.every((f) => f.B === 'hold'), 'a B held for the whole window reads hold');
ok(st.frames.every((f) => f.X === null), 'X reads nothing');
// 5. the window
const w = planWindow({ replay: { ticks: 5000, inputs: [] }, marks: [{ tick: 1000, kind: 'report' }, { tick: 2000, kind: 'crater' }, { tick: 3000, kind: 'report', tag: 'beam' }], pc: 'old' });
eq([w.at, w.from, w.to, w.slot], [3000, 1200, 3120, 1], "window: Netcode's last report mark (crater marks are not reports), 30 s before, 2 s after, old PC is slot 1");
eq(w.reportTicks, [3000], 'only the marks inside the window are listed');
eq(planWindow({ replay: { ticks: 5000 }, marks: [{ tick: 3000, kind: 'report' }], pc: 'main', slot: 1 }).slot, 1, "an explicit slot field wins over the PC's name");
eq(planWindow({ replay: { ticks: 5000 }, reportTicks: [1000, 3000], side: 'old' }).slot, 1, 'the earlier reportTicks and side fields still read');
eq(reportMarks({ marks: [{ tick: 5, kind: 'launch' }, { tick: 9, kind: 'report', tag: 't', note: 'n' }] }), [{ tick: 9, tag: 't', note: 'n' }], 'report marks: kind report only');
eq([commitOf({ build: { commit: 'abc' }, commit: 'x' }), commitOf({ commit: 'x' }), commitOf({})], ['abc', 'x', null], 'commit: build.commit first');
eq(groupMarks([1000, 1500, 3000, 3100, 9000]).map((g) => [g.at, g.before, g.ticks.length]), [[3100, 3900, 4], [9000, 1800, 1]], 'marks each within one window of the one before chain into a group; it reaches back to its first mark');
eq(groupMarks([1000, 2900]).length, 1, '1900 ticks apart is one window (1800 + 120 = 1920)');
eq(groupMarks([1000, 3000]).length, 2, '2000 ticks apart is two windows');
{
  const j = clipJobs({ replay: { ticks: 9000 }, marks: [10, 20, 30, 40, 50, 60, 70, 80].map((k) => ({ tick: k * 1000, kind: 'report' })) }, 'f');
  eq([j.jobs.length, j.jobs[0].tick, j.jobs[5].tick, !!j.left], [6, 30000, 80000, true], 'six clips at most, the newest marks, and the rest said');
  eq(clipJobs({ replay: { ticks: 4321 } }, 'g').jobs, [{ name: 'g-last30s', tick: 4321, before: 1800 }], 'no report mark: the last 30 s');
  eq(clipJobs({ replay: { ticks: 9000 }, marks: [{ tick: 1000, kind: 'report' }, { tick: 1500, kind: 'report' }] }, 'h').jobs, [{ name: 'h-r1500', tick: 1500, before: 2300 }], 'two close marks, one clip');
}
eq(newestPerPc([{ name: 'lan-1931a0f8-main-20261108-220000-over.json' }, { name: 'lan-1931a0f8-main-20261108-221500-quit.json' }, { name: 'lan-1931a0f8-old-20261108-215900-report.json' }]).map((f) => f.name).sort(), ['lan-1931a0f8-main-20261108-221500-quit.json', 'lan-1931a0f8-old-20261108-215900-report.json'], 'the newest saved file of each PC');
ok(SAVED.test('lan-1931a0f8-old-20261108-215900-pause.json') && !SAVED.test('lan-1931a0f8-old-20261108-2159-pause.json') && !SAVED.test('lan-report-1931a0f8.json'), 'the saved file name pattern');
eq(planWindow({ replay: { ticks: 5000 } }).at, 5000, 'no report tick: the last tick');
eq(planWindow({ replay: { ticks: 1000 }, reportTicks: [900] }).to, 1000, 'the window ends with the match');
eq(planWindow({ replay: { ticks: 800 }, reportTicks: [100] }).from, 1, 'the window starts at 1 at the earliest');
eq(planWindow({ replay: { ticks: 5000 }, reportTicks: [100] }, { tick: 4000, slot: 0 }).at, 4000, '--tick wins');
{
  const pg = html(3, 10, 'x <b>', { ticks: [6, 12], frames: [{ B: 'hold' }, { B: null }] });
  ok(pg.includes('"B":"hold"') && !pg.includes('fetch(') && pg.includes('frames/f-'), 'the player page carries the strip inside it (no fetch: it is opened from disk) and loads the pictures');
  ok(html(3, 10, 'x', { a: '</script>' }).split('</script>').length === 2, 'strip data cannot close the script tag');
}
// 6. the shortcut: CRLF, quoted trailing dot, no bare "%~dp0" quote trap
const cmd = cmdText('C:/x/Breakers-Like');
ok(cmd.includes('\r\n') && !/[^\r]\n/.test(cmd), 'cmd is CRLF throughout');
ok(cmd.includes('"%~dp0."') && !cmd.includes('"%~dp0"'), 'the folder argument ends in a dot, not a backslash');
ok(cmd.includes('lan-report.mjs') && cmd.includes('pause'), 'cmd runs the tool and pauses');
// 7. finder, kept builds, readme
const tmp = mkdtempSync(join(tmpdir(), 'lan-selftest-'));
try {
  const lan = join(tmp, 'lan'); mkdirSync(join(lan, 'tree', 'deep'), { recursive: true });
  mkdirSync(join(lan, 'saved'));
  writeFileSync(join(lan, 'saved', 'lan-1931a0f8-main-20261108-220000-report.json'), '{}');
  writeFileSync(join(lan, 'lan-log-main.txt'), 'x');
  writeFileSync(join(lan, 'lan-log-old.txt'), 'x');
  writeFileSync(join(lan, 'tree', 'lan-1931a0f8-main-20261108-220000-over.json'), '{}');
  writeFileSync(join(lan, 'notes.txt'), 'x');
  const found = findFiles(lan);
  eq(found.map((f) => f.name).sort(), ['lan-1931a0f8-main-20261108-220000-report.json', 'lan-log-main.txt', 'lan-log-old.txt'], 'finder: saved files (in saved/) and logs, nothing in tree/, no other files');
  const builds = join(tmp, 'builds'); mkdirSync(join(builds, 'orb-first-play-1931a0f8-aaaa1111', 'web'), { recursive: true });
  writeFileSync(join(builds, 'orb-first-play-1931a0f8-aaaa1111', 'web', 'index.html'), '<html>');
  mkdirSync(join(builds, 'orb-first-play-091dfac9-bbbb2222', 'web'), { recursive: true });
  ok(!!keptBuildFor(builds, '1931a0f8ad3f378e282cada2c49909570c471871'), 'kept build found by the commit');
  ok(keptBuildFor(builds, '091dfac94faeeff0e8ea39451e71322615709afa') === null, 'a folder with no index.html is not a build');
  ok(keptBuildFor(builds, 'deadbeef00') === null && keptBuildFor(builds, null) === null, 'no build of another commit');
  const rd = readmeText({ stamp: 'S', files: { saved: found.filter((f) => f.kind === 'saved'), replays: [], logs: found.filter((f) => f.kind === 'logs') }, clips: [{ name: 'c', made: false, reason: 'no kept web build' }], skipped: [] });
  ok(rd.includes('stays on Orb') && rd.includes('NOT made: no kept web build') && rd.includes('\r\n'), 'readme: stays on the PC, says what was not made');
  // 8. the tools' own refusals, as child processes (no browser starts in any of them)
  const node = process.execPath;
  const rep = join(tmp, 'rep.json');
  writeFileSync(rep, JSON.stringify({ kind: 'orb-lan-match', pc: 'main', slot: 0, build: { commit: '1931a0f8ad3f378e', lan: 'x' }, marks: [{ tick: 900, kind: 'report', tag: 't', note: 'n' }], replay: { ticks: 1000, inputs: [[0, 0, ...pack({}), 0]] } }));
  let r = spawnSync(node, [join(HERE, 'lan-clip.mjs'), '--file', rep, '--dir', join(builds, 'orb-first-play-091dfac9-bbbb2222', 'web'), '--out', join(tmp, 'o1')], { encoding: 'utf8', timeout: 60000 });
  ok(r.status === 3 && /no kept build of that commit/.test(r.stderr), `a build of another commit is refused before any browser (exit ${r.status}: ${r.stderr.trim().slice(0, 100)})`);
  r = spawnSync(node, [join(HERE, 'lan-clip.mjs'), '--file', rep, '--dir', join(builds, 'orb-first-play-1931a0f8-aaaa1111', 'web'), '--out', join(tmp, 'o2'), '--dry'], { encoding: 'utf8', timeout: 60000 });
  const dry = JSON.parse(r.stdout || '{}');
  ok(r.status === 0 && dry.from === 1 && dry.to === 1000 && dry.at === 900, 'dry run prints the window');
  const norep = join(tmp, 'norep.json'); writeFileSync(norep, '{"hello":1}');
  r = spawnSync(node, [join(HERE, 'lan-clip.mjs'), '--file', norep, '--dir', builds, '--out', join(tmp, 'o3')], { encoding: 'utf8', timeout: 60000 });
  ok(r.status === 3 && /no replay/.test(r.stderr), 'a file with no replay is refused');
  r = spawnSync(node, [join(HERE, 'lan-clip.mjs')], { encoding: 'utf8', timeout: 60000 });
  ok(r.status === 2, 'no arguments: usage, exit 2');
  r = spawnSync(node, [join(HERE, 'lan-report.mjs'), '--from', lan, '--dry'], { encoding: 'utf8', timeout: 60000 });
  ok(r.status === 0 && /found 1 saved match file\(s\), 0 black box file\(s\), 2 log\(s\)/.test(r.stdout), `report --dry finds the files (${r.stdout.trim().slice(0, 120)})`);
  const empty = join(tmp, 'empty'); mkdirSync(empty);
  r = spawnSync(node, [join(HERE, 'lan-report.mjs'), '--from', empty, '--out', join(tmp, 'reports'), '--force'], { encoding: 'utf8', timeout: 60000 });
  ok(r.status === 3 && /Nothing to gather/.test(r.stderr), 'an empty folder says so and changes nothing');
  ok(!existsSync(join(tmp, 'reports')), 'and makes no folder');
  r = spawnSync(node, [join(HERE, 'lan-report.mjs'), '--write-cmd', join(tmp, 'cmd')], { encoding: 'utf8', timeout: 60000 });
  ok(r.status === 0 && existsSync(join(tmp, 'cmd', 'Make my report folder.cmd')) && readFileSync(join(tmp, 'cmd', 'Make my report folder.cmd'), 'utf8').includes('\r\n'), '--write-cmd writes the shortcut with CRLF');
  // a full run with --no-clips: folder, readme, zip, and the originals untouched
  r = spawnSync(node, [join(HERE, 'lan-report.mjs'), '--from', lan, '--out', join(tmp, 'reports2'), '--no-clips', '--force'], { encoding: 'utf8', timeout: 180000 });
  ok(r.status === 0 && /Report folder:/.test(r.stdout), `a run with no clips makes the folder (${r.stdout.trim().slice(-160)})`);
  ok(/Zip: .*\.zip/.test(r.stdout), 'and a zip');
  ok(existsSync(join(lan, 'lan-log-main.txt')), 'the original files are still where they were');
} finally {
  try { rmSync(tmp, { recursive: true, force: true }); } catch { /* left in the system temp folder */ }
}
console.log(bad ? `lan-clip selftest: ${bad} of ${n} FAILED` : `lan-clip selftest ok: ${n} checks`);
process.exitCode = bad ? 1 : 0;
