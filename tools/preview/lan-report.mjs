// "Make my report folder": gathers a LAN play-test's replays, reports and logs, films a clip of each report, and zips the lot for homework (Tools, 2026-11-08; docs/tools/lan-report.md).
//
//   node tools/preview/lan-report.mjs [--from <folder> ...] [--out <folder>] [--builds <folder>] [--no-clips] [--clip-limit 1200] [--force] [--dry]
//   node tools/preview/lan-report.mjs --write-cmd <folder>      writes "Make my report folder.cmd" (CRLF) into that folder; the shortcut points at this repository's copy of the tool
//
// Looks (recursively, three folders deep) in each --from folder (default: the folder the shortcut sits in, then the user's Downloads) for what a LAN match leaves:
//   lan-<commit8>-<main|old>-<yyyymmdd-hhmmss>-<over|pause|quit|report>.json  (Netcode's saved\ files: the match's replay with its marks, frames and net), lan-log-*.txt (the exe's ping and step counts), orb-first-play-*.json (a web black box)
// The NEWEST saved file of each PC gets a clip of each "report this" mark's window (1800 ticks before to 120 after; marks whose windows overlap share one clip; a file with no report mark gets its last 30 s), at most six clips a file (the newest marks),
// from the kept web build of ITS commit in homework/Files/builds (tools/preview/lan-clip.mjs, the button strip under the picture); no kept build of that commit means no clip and a line in the README, not a failure. Every saved file is copied in.
// The result is homework/Files/reports/orb-lan-report-<yyyymmdd-hhmm>/ (saved, replays, logs, clips, README.txt) and a .zip of it beside. Nothing is sent anywhere; the folder stays on Orb's PC.
// It refuses to run while a match is open (orb-combat-lan.exe, or a game window) unless --force, and starts Chrome only through blackbox-clip's guarded launcher, one at a time, below-normal, with a time limit.
// Node built-ins only. Files are copied, never moved or deleted.
import { existsSync, mkdirSync, writeFileSync, readFileSync, readdirSync, statSync, copyFileSync } from 'node:fs';
import { join, resolve, basename, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync, spawn } from 'node:child_process';
import { homedir } from 'node:os';
import { reportMarks, commitOf, pcOf, groupMarks } from './lan-clip.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = resolve(HERE, '../..');
// Netcode's saved\ file (agreed 2026-11-08): lan-<commit8>-<main|old>-<yyyymmdd-hhmmss>-<over|pause|quit|report>.json, kind "orb-lan-match": a black-box-shaped replay with marks, frames and net.
// NetLan adds "-2", "-3" ... when two saves land in the same second (two quick presses), so an optional -<n> sits before .json; the later save has the larger n.
// A plain desktop build's own save (A-UI-02, 2026-11-14; render/core/match_recorder.gd) has the same shape under another prefix, solo-<commit>-main-<time>-<report|save>.json, kind "orb-solo-match", with the build's 7 or 8 character commit.
export const SAVED = /^(?:lan|solo)-([0-9a-f]{7,8}|unknown)-(main|old)-(\d{8}-\d{6})-(over|pause|quit|report|save)(?:-(\d+))?\.json$/i;
const savedKey = (name) => { const m = SAVED.exec(name); return m ? m[3] + '-' + String(Number(m[5] || 1)).padStart(6, '0') : ''; };   // the timestamp, then the suffix (none counts as 1, so "-2" is later)
const KINDS = [
  { dir: 'saved', re: SAVED },
  { dir: 'logs', re: /^lan-log-.+\.txt$/i },
  { dir: 'replays', re: /^orb-first-play-\d{8}-\d{4}\.json$/i },
];

/** Every file under `root` (at most `depth` folders down) that matches a kind, newest first. Skips node_modules, tree and web folders. */
export function findFiles(root, depth = 3) {
  const out = [];
  const walk = (d, n) => {
    let names; try { names = readdirSync(d, { withFileTypes: true }); } catch { return; }
    for (const e of names) {
      const p = join(d, e.name);
      if (e.isDirectory()) { if (n < depth && !/^(node_modules|tree|web|\.git)$/i.test(e.name)) walk(p, n + 1); continue; }
      const k = KINDS.find((x) => x.re.test(e.name));
      if (k) { let st; try { st = statSync(p); } catch { continue; } out.push({ path: p, kind: k.dir, name: e.name, mtime: st.mtimeMs, size: st.size }); }
    }
  };
  walk(resolve(root), 0);
  return out.sort((a, b) => b.mtime - a.mtime);
}

/** The newest kept web build of a commit: homework/Files/builds/orb-first-play-<commit8>-*\/web with an index.html, or null. */
export function keptBuildFor(buildsDir, commit) {
  if (!commit) return null;
  const c8 = String(commit).slice(0, 8);   // 8 characters (a LAN file), or 7 (a desktop save: the stamp's short commit), which still names one kept folder
  let names; try { names = readdirSync(buildsDir); } catch { return null; }
  const prefix = c8.length >= 8 ? `orb-first-play-${c8}-` : `orb-first-play-${c8}`;
  const hits = names.filter((n) => n.startsWith(prefix)).map((n) => join(buildsDir, n, 'web')).filter((p) => existsSync(join(p, 'index.html')));
  hits.sort((a, b) => statSync(b).mtimeMs - statSync(a).mtimeMs);
  return hits[0] || null;
}

export function readmeText({ stamp, files, clips, skipped }) {
  const L = [
    `Orb Combat EX: LAN report folder, made ${stamp}`,
    '',
    'This folder stays on Orb\'s PC. Nothing in it was sent anywhere. Give it to the EP by dropping the .zip beside this folder into the chat or the homework folder; do not post it.',
    'The clips are for your own screen only: don\'t share or post them.',
    '',
    'WHAT IS INSIDE',
    `  saved\\     ${files.saved.length} saved match file(s) from the PCs: each is the match's replay with its "report this" marks, the slow frames and the network numbers`,
    `  replays\\   ${files.replays.length} web black box file(s)`,
    `  logs\\      ${files.logs.length} lan-log file(s): ping, step counts, rollbacks, slow frames, one line every ten seconds`,
    `  clips\\     ${clips.length} clip(s): open index.html inside a clip folder in a browser (Space plays and pauses, the arrow keys step). About 30 seconds before each report, with the buttons the game was fed shown under the picture`,
    '',
  ];
  if (clips.length) { L.push('CLIPS'); for (const c of clips) L.push(`  clips\\${c.name}: ${c.made ? 'made' : 'NOT made: ' + c.reason}`); L.push(''); }
  if (skipped.length) { L.push('LEFT OUT'); for (const s of skipped) L.push('  ' + s); L.push(''); }
  L.push('FILES', ...[...files.saved, ...files.replays, ...files.logs].map((f) => `  ${f.kind}\\${f.name}  (${(f.size / 1024).toFixed(0)} KB, saved ${new Date(f.mtime).toISOString().slice(0, 16).replace('T', ' ')})`));
  return L.join('\r\n') + '\r\n';
}

export function cmdText(repo) {
  const tool = join(repo, 'tools', 'preview', 'lan-report.mjs').replace(/\//g, '\\');
  return [
    '@echo off',
    'title Orb Combat EX - make my report folder',
    'rem Run this on the MAIN PC, with the game closed on both PCs. Copy the old PC\'s saved folder and its lan-log file over first (a USB stick is fine): put them in this folder or in Downloads.',
    'rem It never changes or deletes your files: it copies them, films a clip of each report, and zips the lot into homework\\Files\\reports. Nothing is sent anywhere.',
    'echo.',
    'echo Make my report folder: close the game on BOTH PCs first.',
    'echo The clips are for your own screen only: do not share or post them.',
    'echo.',
    `node "${tool}" --from "%~dp0." --from "%USERPROFILE%\\Downloads"`,   // "%~dp0." not "%~dp0": a path ending in a backslash would swallow the closing quote
    'echo.',
    'pause',
    '',
  ].join('\r\n');
}

function matchOpen() {
  const r = spawnSync('tasklist', ['/FO', 'CSV', '/NH'], { encoding: 'utf8', timeout: 20000, windowsHide: true });
  if (r.status !== 0) return null;
  return /"orb-combat[^"]*\.exe"/i.test(r.stdout || '') ? 'orb-combat' : null;
}

/** The newest saved file of each PC (main, old), by the timestamp in its name. A later save holds the whole match up to its tick and all its marks, so one file per PC is the one to film. */
export function newestPerPc(saved) {
  const best = new Map();
  for (const f of saved) {
    const m = SAVED.exec(f.name); if (!m) continue;
    const pc = m[2].toLowerCase(), cur = best.get(pc);
    if (!cur || savedKey(f.name) > savedKey(cur.name)) best.set(pc, f);
  }
  return [...best.values()];
}

/** The clips of one file: one per group of report marks whose windows overlap (at most six, the newest), or one of the last 30 s when it has no report mark. */
export function clipJobs(doc, base, max = 6) {
  const marks = reportMarks(doc);
  if (!marks.length) return { jobs: [{ name: `${base}-last30s`, tick: Number((doc.replay || doc).ticks) || Number(doc.tick) || 0, before: 1800 }], left: null };
  const groups = groupMarks(marks.map((m) => m.tick));
  const keep = groups.slice(-max);
  return { jobs: keep.map((g) => ({ name: `${base}-r${g.at}`, tick: g.at, before: g.before })), left: groups.length > max ? `${groups.length - max} older report mark group(s) not filmed (the limit is ${max} clips a file); their marks are in the saved file` : null };
}

function runClip(file, dir, out, limitS, extra = []) {
  return new Promise((done) => {
    const c = spawn(process.execPath, [join(HERE, 'lan-clip.mjs'), '--file', file, '--dir', dir, '--out', out, '--limit', String(limitS), ...extra], { stdio: 'inherit', windowsHide: true, env: { ...process.env, MERIDIAN_SESSION: process.env.MERIDIAN_SESSION || 'tools-pipeline' } });
    const t = setTimeout(() => { try { c.kill(); } catch { /* gone */ } }, (limitS + 120) * 1000);
    c.on('close', (code) => { clearTimeout(t); done(code); });
  });
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const argv = process.argv.slice(2);
  const all = (n) => argv.reduce((a, v, i) => (v === n && i + 1 < argv.length ? [...a, argv[i + 1]] : a), []);
  const opt = (n, d) => { const v = all(n); return v.length ? v[v.length - 1] : d; };
  const wc = opt('--write-cmd', null);
  if (wc) {
    mkdirSync(resolve(wc), { recursive: true });
    writeFileSync(join(resolve(wc), 'Make my report folder.cmd'), cmdText(REPO));
    console.log(`wrote ${join(resolve(wc), 'Make my report folder.cmd')}`);
    process.exit(0);
  }
  const froms = (all('--from').length ? all('--from') : [process.cwd(), join(homedir(), 'Downloads')]).map((f) => resolve(f.replace(/[\\/]+$/, '')));
  const builds = resolve(opt('--builds', join(REPO, 'homework', 'Files', 'builds')));
  const outRoot = resolve(opt('--out', join(REPO, 'homework', 'Files', 'reports')));
  const limitS = Math.max(120, Number(opt('--clip-limit', 1200)));
  const noClips = argv.includes('--no-clips'), dry = argv.includes('--dry'), force = argv.includes('--force');
  if (!force && !dry && matchOpen()) { console.error('A match is open (orb-combat-lan.exe is running). Close the game on both PCs and run this again: it films clips and must not share the machine with a match.'); process.exit(4); }
  // gather: newest of each name wins; the same file found twice (a folder inside another) is kept once
  const seen = new Set(), found = [];
  for (const f of froms) for (const x of findFiles(f)) { const key = x.name + ':' + x.size; if (!seen.has(key)) { seen.add(key); found.push(x); } }
  const files = { saved: found.filter((f) => f.kind === 'saved'), replays: found.filter((f) => f.kind === 'replays'), logs: found.filter((f) => f.kind === 'logs') };
  // a LAN folder's old files: only this match's, the newest day's, so a folder that holds earlier tests does not pull them all in
  const newest = found.length ? Math.max(...found.map((f) => f.mtime)) : 0;
  const recent = (f) => newest - f.mtime < 12 * 3600 * 1000;
  const skipped = [];
  for (const k of Object.keys(files)) { const keep = files[k].filter(recent); for (const f of files[k]) if (!recent(f)) skipped.push(`${f.kind}\\${f.name}: older than 12 hours before the newest file, so not part of this test`); files[k] = keep; }
  console.log(`found ${files.saved.length} saved match file(s), ${files.replays.length} black box file(s), ${files.logs.length} log(s) in ${froms.join(', ')}`);
  if (dry) { for (const k of Object.keys(files)) for (const f of files[k]) console.log(`  ${k}\\${f.name}`); process.exit(0); }
  if (!files.saved.length && !files.replays.length && !files.logs.length) { console.error('Nothing to gather: no lan-...-over/pause/quit/report.json saved match file or lan-log file in the places looked at. Copy the old PC\'s saved folder and lan-log over and run this again.'); process.exit(3); }
  const d = new Date(), p2 = (n) => String(n).padStart(2, '0');
  const stamp = `${d.getFullYear()}${p2(d.getMonth() + 1)}${p2(d.getDate())}-${p2(d.getHours())}${p2(d.getMinutes())}`;
  const name = `orb-lan-report-${stamp}`, dir = join(outRoot, name);
  if (existsSync(dir)) { console.error(`${dir} already exists: wait a minute or move it, nothing was changed.`); process.exit(3); }
  for (const sub of ['saved', 'replays', 'logs', 'clips']) mkdirSync(join(dir, sub), { recursive: true });
  for (const k of Object.keys(files)) for (const f of files[k]) copyFileSync(f.path, join(dir, k, f.name));
  const clips = [];
  if (!noClips) {
    for (const f of [...newestPerPc(files.saved), ...files.replays.filter((r) => /^orb-first-play/.test(r.name))]) {
      const base = f.name.replace(/\.json$/i, '');
      let doc = null; try { doc = JSON.parse(readFileSync(f.path, 'utf8')); } catch { clips.push({ name: base, made: false, reason: 'the file could not be read as JSON' }); continue; }
      if (!(doc.replay || doc).inputs) { clips.push({ name: base, made: false, reason: 'the file holds no replay' }); continue; }
      const commit = commitOf(doc);
      const web = keptBuildFor(builds, commit);
      if (!web) { clips.push({ name: base, made: false, reason: `no kept web build of commit ${commit ? String(commit).slice(0, 8) : '(none named in the file)'} in ${basename(builds)}` }); continue; }
      const { jobs, left } = clipJobs(doc, base);
      if (left) clips.push({ name: base, made: false, reason: left });
      for (const j of jobs) {
        console.log(`clip ${j.name} (tick ${j.tick}) on ${basename(dirname(web))} ...`);
        const out = join(dir, 'clips', j.name);
        const code = await runClip(f.path, web, out, limitS, ['--tick', String(j.tick), '--before', String(j.before)]);
        let rec = null; try { rec = JSON.parse(readFileSync(join(out, 'lan-clip.json'), 'utf8')); } catch { /* none */ }
        clips.push({ name: j.name, made: code === 0 && !!(rec && rec.made), reason: rec && rec.reason ? rec.reason : code === 0 ? '' : `the clip tool ended with ${code}` });
      }
    }
  }
  writeFileSync(join(dir, 'README.txt'), readmeText({ stamp, files, clips, skipped }));
  const zip = join(outRoot, name + '.zip');
  const z = spawnSync('powershell.exe', ['-NoProfile', '-NonInteractive', '-Command', `Compress-Archive -LiteralPath '${dir.replace(/'/g, "''")}' -DestinationPath '${zip.replace(/'/g, "''")}' -CompressionLevel Optimal`], { encoding: 'utf8', timeout: 300000, windowsHide: true });
  const zipOk = z.status === 0 && existsSync(zip);
  console.log(`\nReport folder: ${dir}`);
  console.log(zipOk ? `Zip: ${zip} (${(statSync(zip).size / 1048576).toFixed(1)} MB)` : `The zip was not made (${(z.stderr || '').trim().split('\n')[0] || 'exit ' + z.status}); the folder above is complete.`);
  for (const c of clips) console.log(`  clip ${c.name}: ${c.made ? 'made' : 'not made: ' + c.reason}`);
  process.exitCode = 0;
}
