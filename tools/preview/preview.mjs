// One command: a PRIVATE, LOCAL, playable web build of main with the new planet's switches on, for Orb's own browser (docs/tools/preview.md). Never published, uploaded or dispatched.
//
//   node tools/preview/preview.mjs [--off water,floor] [--planet 7] [--port 8765] [--rev main] [--overlay sim/input,data/input] [--open] [--no-smoke] [--no-serve] [--rebuild] [--bisect]
//   node tools/preview/preview.mjs --list      the switches and what each does
//   node tools/preview/preview.mjs --check     do the switch table and the scratch patch still fit this tree? (no Godot, no browser, writes nothing)
//
// What it does: unpacks the committed tree of --rev (default main) into a scratch folder under the temp folder, turns the switches on there by editing the data files' text (the tree and tools/site.json are
// never touched), patches the SCRATCH copy's render/core/main.gd with a ?planet=N entry and a state probe (switches.mjs says why), imports and exports the Web build with the STANDARD template
// at below-normal priority (the live pin and the custom template are not involved), runs the boot-and-play smoke check through Tools' guarded browser launcher, and serves the build on 127.0.0.1 only.
// --overlay copies those paths of the WORKING tree over the scratch copy (work not yet committed: Controls' right hand before it lands); the report says so and the cache key holds their contents.
// A switch whose key is not in the tree you build is WAITING, not on: it is listed, never counted as passed, and the build is made without it (rows of tools/preview/switches-pending.json name the ones to come).
// rightStick also applies Controls' host patch (docs/controls/pending/right-hand/right-hand-host.patch) to the scratch copy's main.gd when the tree has not got it yet. --open opens the page in the default browser.
// --off takes switch ids (comma-separated or repeated; "all" is the plain build); a switch that needs another is turned off with it and the report says so. --bisect, after a failed smoke check, builds
// and checks each switch alone to name the one that fails. A build is cached by commit, switches and patch, so the same command again serves at once (--rebuild to build again).
import { spawn, spawnSync } from 'node:child_process';
import { createReadStream, cpSync, existsSync, mkdirSync, mkdtempSync, openSync, closeSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { createServer } from 'node:http';
import { constants as osConstants, setPriority, tmpdir } from 'node:os';
import { extname, join, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { exportRevision } from '../flash/head-export.mjs';
import { scriptErrors } from '../gate.mjs';
import { IDS, SWITCHES, EDITS_FINGERPRINT, flip, locate, patchMain, resolve as resolveSwitches, tableWith, loadPending } from './switches.mjs';

const HERE = fileURLToPath(new URL('.', import.meta.url));
const REPO = resolve(HERE, '..', '..');
const MIME = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.mjs': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.png': 'image/png', '.jpg': 'image/jpeg', '.svg': 'image/svg+xml', '.json': 'application/json', '.css': 'text/css', '.webmanifest': 'application/manifest+json', '.ico': 'image/x-icon' };

const git = (repo, args) => {
  const r = spawnSync('git', args, { cwd: repo, encoding: 'utf8' });
  if (r.status !== 0) throw new Error(`git ${args.join(' ')} failed: ${String(r.stderr || r.error || '').trim().split('\n')[0]}`);
  return r.stdout.trim();
};

/** The Godot console executable: --godot, $GODOT, then the usual install of this PC. */
export function godotExe(given) {
  const local = process.env.LOCALAPPDATA ? join(process.env.LOCALAPPDATA, 'Programs', 'Godot', '4.7.2', 'Godot_v4.7.2-stable_win64_console.exe') : '';
  const found = [given, process.env.GODOT, local].find((p) => p && existsSync(p));
  if (!found) throw new Error('no Godot executable: pass --godot <exe> or set GODOT (4.7.2 console build, with the Web export templates installed)');
  return found;
}

/** Runs one Godot (or the self-test's node stub) to the end, output to a log file, at below-normal priority and under a time limit. Resolves the exit code. */
function runGodot(o, args, logFile, limitMs) {
  return new Promise((ok) => {
    const fd = openSync(logFile, 'w');
    const cmd = o.godotNode ? process.execPath : o.godot;
    const a = o.godotNode ? [o.godotNode, ...args] : args;
    const child = spawn(cmd, a, { stdio: ['ignore', fd, fd], windowsHide: true });
    try { setPriority(child.pid, osConstants.priority.PRIORITY_BELOW_NORMAL); } catch { /* the child may already be gone */ }
    const timer = setTimeout(() => { try { child.kill(); } catch { /* gone */ } }, limitMs);
    child.on('error', () => { clearTimeout(timer); closeSync(fd); ok(-1); });
    child.on('close', (code) => { clearTimeout(timer); closeSync(fd); ok(code === null ? -2 : code); });
  });
}

const tail = (file, n = 25) => { try { return readFileSync(file, 'utf8').split(/\r?\n/).filter(Boolean).slice(-n).join('\n'); } catch { return '(no log)'; } };

/** The cache key of a build: commit, switches on, the scratch patch's fingerprint, the planet entry. */
export function buildKey(sha, active) {
  return `${sha.slice(0, 8)}-${active.length ? active.join('+') : 'none'}-${EDITS_FINGERPRINT}`;
}

export const PENDING_FILE = join(HERE, 'switches-pending.json');
export const HOST_PATCH = 'docs/controls/pending/right-hand/right-hand-host.patch';

/** The rows of switches-pending.json ({ rows, problems }); a missing file is no rows. */
export function readPending(file = PENDING_FILE) {
  return existsSync(file) ? loadPending(readFileSync(file, 'utf8')) : { rows: [], problems: [] };
}

/** The working-tree paths of an overlay (files or folders, relative, inside the repo, existing); throws on anything else. */
export function overlayPaths(repo, list) {
  const out = [];
  for (const raw of list) {
    const p = String(raw).replace(/\\/g, '/').replace(/^\.\//, '').replace(/\/+$/, '');
    if (!p || p.startsWith('/') || /^[a-zA-Z]:/.test(p) || p.split('/').includes('..') || p.startsWith('.git')) throw new Error(`--overlay ${raw}: a path inside the repository, relative to its root`);
    if (!existsSync(join(repo, ...p.split('/')))) throw new Error(`--overlay ${p}: not in the working tree`);
    out.push(p);
  }
  return out;
}

const filesUnder = (dir, rel = '') => readdirSync(join(dir, rel), { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? filesUnder(dir, join(rel, e.name)) : [join(rel, e.name).split(sep).join('/')]));

/** The files an overlay brings, and a hash of their contents (the cache key and the report). */
export function overlayFiles(repo, paths) {
  const files = paths.flatMap((p) => { const full = join(repo, ...p.split('/')); return statSync(full).isDirectory() ? filesUnder(full).map((f) => `${p}/${f}`) : [p]; }).sort();
  const h = createHash('sha1');
  for (const f of files) { h.update(f); h.update(readFileSync(join(repo, ...f.split('/')))); }
  return { files, hash: files.length ? h.digest('hex').slice(0, 6) : '' };
}

/** A file as the build will have it: the working tree's when an overlay covers it, else the committed text of `sha`; null when it is not there. */
export function readAt(repo, sha, overlay, path) {
  if (overlay.some((p) => path === p || path.startsWith(`${p}/`))) { const f = join(repo, ...path.split('/')); return existsSync(f) && statSync(f).isFile() ? readFileSync(f, 'utf8') : null; }
  const r = spawnSync('git', ['show', `${sha}:${path}`], { cwd: repo, encoding: 'utf8', maxBuffer: 1 << 28 });
  return r.status === 0 ? r.stdout : null;
}

/**
 * What a build of `sha` (with `overlay`) will have: the switches that can be on, those that WAIT (their key is not in the tree, or what they need to be played is missing) and the extra probe fields.
 * `pending`: the rows of switches-pending.json. Returns { table, active, cascaded, waiting: [{ id, why }], stale: [problem], probes, hostPatch }.
 */
export function plan(repo, sha, { off = [], overlay = [], pending = [] } = {}) {
  const table = tableWith(pending);
  const r = resolveSwitches(off, table);
  const read = (p) => readAt(repo, sha, overlay, p);
  const waiting = [], stale = [];
  let active = [...r.active];
  const wait = (id, why) => { active = active.filter((x) => x !== id); waiting.push({ id, why }); };
  for (const sw of table) {
    if (!active.includes(sw.id) || !sw.optional) continue;
    const text = read(sw.file);
    if (text === null || !locate(text, sw.path)) wait(sw.id, `${sw.file} ${sw.path.join('.')} is not in this tree yet`);
    else { try { flip(text, sw); } catch (e) { stale.push(e.message); wait(sw.id, 'its key holds neither the old nor the new value'); } }
  }
  let hostPatch = null;
  if (active.includes('rightStick')) {
    const main = read('render/core/main.gd');
    if (main !== null && !main.includes('_pad_stick_right')) {
      hostPatch = read(HOST_PATCH);
      if (hostPatch === null) wait('rightStick', `the pad's right stick is not read by this tree's main.gd and ${HOST_PATCH} is not in it`);
    }
  }
  // what waits turns off what needs it, as an --off would
  for (let again = true; again;) {
    again = false;
    for (const sw of table) if (active.includes(sw.id) && sw.needs.some((n) => !active.includes(n))) { wait(sw.id, `it needs ${sw.needs.filter((n) => !active.includes(n)).join(' + ')}, which is not on`); again = true; }
  }
  const probes = table.filter((s) => active.includes(s.id) && s.probe && s.probeIf && read(s.probeIf.file) !== null && read(s.probeIf.file).includes(s.probeIf.text)).map((s) => s.probe);
  return { table, active: table.map((s) => s.id).filter((id) => active.includes(id)), cascaded: r.cascaded, waiting, stale, probes, hostPatch, unknown: r.unknown };
}

/** Applies a git patch to a scratch tree (git apply, whitespace-tolerant: a CRLF checkout must not refuse it). Throws with git's first line when it does not fit. */
export function applyPatchText(tree, text) {
  const file = join(tree, '.preview-host.patch');
  writeFileSync(file, text);
  try {
    const r = spawnSync('git', ['apply', '--ignore-whitespace', '.preview-host.patch'], { cwd: tree, encoding: 'utf8' });   // a relative name: a long scratch path (the cache key holds every switch) is past what git opens on Windows
    if (r.status !== 0) throw new Error(`the host patch does not fit this tree: ${String(r.stderr || r.error || '').trim().split('\n')[0]}`);
  } finally { rmSync(file, { force: true }); }
}

/** Builds (or finds) the preview for a revision with these switches. Returns { web, dir, key, sha, subject, active, cascaded, flips, cached, seconds, meta }. Writes only under the output folder. */
export async function buildPreview(o) {
  const repo = resolve(o.repo || REPO);
  const log = o.log || (() => {});
  const sha = git(repo, ['rev-parse', '--verify', `${o.rev || 'main'}^{commit}`]);
  const overlay = overlayPaths(repo, o.overlay || []);
  const ov = overlayFiles(repo, overlay);
  const pend = o.pending || readPending();
  if (pend.problems.length) throw new Error(`tools/preview/switches-pending.json: ${pend.problems.join('; ')}`);
  const pl = plan(repo, sha, { off: o.off || [], overlay, pending: pend.rows });
  const r = { active: pl.active, cascaded: pl.cascaded, unknown: pl.unknown };
  if (r.unknown.length) throw new Error(`unknown switch ${r.unknown.join(', ')}: the switches are ${pl.table.map((s) => s.id).join(', ')} (or all)`);
  const subject = git(repo, ['log', '-1', '--format=%s', sha]).slice(0, 110);
  const date = git(repo, ['log', '-1', '--format=%cs', sha]);
  const key = `${buildKey(sha, r.active)}${ov.hash ? `-ov${ov.hash}` : ''}${pl.hostPatch ? '-host' : ''}`;
  const base = resolve(o.out || join(tmpdir(), 'meridian-preview'));
  const dir = join(base, key), web = join(dir, 'web'), tree = join(dir, 'tree'), metaFile = join(dir, 'preview.json');
  const out = { web, dir, key, sha, subject, active: r.active, cascaded: r.cascaded, waiting: pl.waiting, table: pl.table, overlay: ov.files, hostPatched: !!pl.hostPatch, cached: false, seconds: 0, flips: [], meta: null };
  if (!o.rebuild && existsSync(join(web, 'index.html')) && existsSync(metaFile)) {
    out.cached = true; out.meta = JSON.parse(readFileSync(metaFile, 'utf8')); out.flips = out.meta.flips || [];
    return out;
  }
  const t0 = Date.now();
  mkdirSync(dir, { recursive: true });
  rmSync(web, { recursive: true, force: true });
  rmSync(tree, { recursive: true, force: true });
  mkdirSync(web, { recursive: true });
  log(`unpacking ${sha.slice(0, 8)} into ${tree}`);
  const ex = exportRevision(repo, tree, sha);
  if (!ex.ok) throw new Error(ex.message);
  if (ov.files.length) {
    for (const p of overlay) { const to = join(tree, ...p.split('/')); mkdirSync(resolve(to, '..'), { recursive: true }); rmSync(to, { recursive: true, force: true }); cpSync(join(repo, ...p.split('/')), to, { recursive: true }); }
    log(`overlaid ${ov.files.length} files of the working tree (uncommitted): ${overlay.join(', ')}`);
  }
  writeFileSync(join(tree, 'build_info.json'), `${JSON.stringify({ commit: sha.slice(0, 7), date, overlay: ov.files.length ? overlay : undefined })}\n`);
  for (const sw of pl.table) {
    if (!r.active.includes(sw.id)) continue;
    const f = join(tree, ...sw.file.split('/'));
    const res = flip(readFileSync(f, 'utf8'), sw);
    if (res.text !== readFileSync(f, 'utf8')) writeFileSync(f, res.text);
    out.flips.push({ id: sw.id, file: sw.file, key: sw.path.join('.'), was: res.was, now: JSON.stringify(sw.to), alreadyOn: res.was === JSON.stringify(sw.to) });
  }
  const mainFile = join(tree, 'render', 'core', 'main.gd');
  if (pl.hostPatch) { applyPatchText(tree, pl.hostPatch); log('applied the right-hand host patch to the scratch main.gd (the pad\'s right stick)'); }
  writeFileSync(mainFile, patchMain(readFileSync(mainFile, 'utf8'), pl.probes));
  const godot = o.godotNode ? null : godotExe(o.godot);
  const g = { godot, godotNode: o.godotNode };
  log('importing the project (Godot, below-normal priority)');
  const importLog = join(dir, 'import.log'), exportLog = join(dir, 'export.log');
  let code = await runGodot(g, ['--headless', '--path', tree, '--import'], importLog, 25 * 60 * 1000);
  if (code !== 0) throw new Error(`Godot --import exited ${code}; the end of ${importLog}:\n${tail(importLog)}`);
  log('exporting Web (standard template, single-threaded)');
  code = await runGodot(g, ['--headless', '--path', tree, '--export-release', 'Web', join(web, 'index.html')], exportLog, 25 * 60 * 1000);
  if (code !== 0 || !existsSync(join(web, 'index.html'))) throw new Error(`Godot --export-release Web exited ${code}; the end of ${exportLog}:\n${tail(exportLog)}`);
  out.scriptErrors = scriptErrors(`${tail(importLog, 4000)}\n${tail(exportLog, 4000)}`).slice(0, 6);
  if (!o.keepTree) rmSync(tree, { recursive: true, force: true });
  out.seconds = Math.round((Date.now() - t0) / 1000);
  out.meta = { commit: sha, subject, active: r.active, waiting: pl.waiting, overlay: ov.files, hostPatched: !!pl.hostPatch, flips: out.flips, planet: o.planet, builtAt: new Date().toISOString().slice(0, 16), seconds: out.seconds, smoke: null };
  writeFileSync(metaFile, `${JSON.stringify(out.meta, null, 2)}\n`);
  return out;
}

export function saveSmoke(b, result) {
  b.meta.smoke = { ok: result.ok, at: new Date().toISOString().slice(0, 16), problems: result.problems.map((p) => (p.sw ? `[${p.sw}] ` : '') + p.text) };
  writeFileSync(join(b.dir, 'preview.json'), `${JSON.stringify(b.meta, null, 2)}\n`);
}

/** Serves a built folder on 127.0.0.1 only. Resolves the listening server. `port` 0 picks one; a busy port that was not asked for explicitly falls on to the next. */
export function serveLocal(root, port, { strict = false, quiet = true } = {}) {
  const base = resolve(root);
  const server = createServer((req, res) => {
    let p;
    try { p = decodeURIComponent(new URL(req.url, 'http://x').pathname); } catch { res.writeHead(400); res.end(); return; }
    if (p.endsWith('/')) p += 'index.html';
    const file = resolve(join(base, p));
    if (!(file === base || file.startsWith(base + sep)) || !existsSync(file) || !statSync(file).isFile()) { res.writeHead(404); res.end('not found'); return; }
    res.writeHead(200, { 'content-type': MIME[extname(file)] || 'application/octet-stream', 'content-length': statSync(file).size, 'cache-control': 'no-store' });
    if (req.method === 'HEAD') { res.end(); return; }
    createReadStream(file).pipe(res);
  });
  return new Promise((ok, fail) => {
    let tries = 0, at = port;
    const go = () => server.listen(at, '127.0.0.1');
    server.on('listening', () => ok(server));
    server.on('error', (e) => {
      if (e.code === 'EADDRINUSE' && !strict && tries++ < 20) { at += 1; go(); return; }
      fail(e);
    });
    go();
  });
}

function listSwitches(table = SWITCHES) {
  for (const sw of table) console.log(`  ${sw.id.padEnd(11)} ${sw.file} ${sw.path.join('.')}: ${JSON.stringify(sw.from)} -> ${JSON.stringify(sw.to)}${sw.needs.length ? `   (needs ${sw.needs.join(' + ')})` : ''}\n              ${sw.what}`);
}

/** --check: does every switch's key sit where the table says, and does the scratch patch fit main.gd, in the committed tree of `rev`? Returns the problems. */
export function checkTree(repo, rev, { overlay = [], pending = readPending(), notes = [] } = {}) {
  const problems = [...pending.problems.map((p) => `tools/preview/switches-pending.json: ${p}`)];
  const sha = git(repo, ['rev-parse', '--verify', `${rev}^{commit}`]);
  const ov = overlayPaths(repo, overlay);
  const read = (p) => readAt(repo, sha, ov, p);
  const pl = plan(repo, sha, { overlay: ov, pending: pending.rows });
  for (const sw of pl.table) {
    const text = read(sw.file);
    if (text === null) { if (!sw.optional) problems.push(`${sw.file}: not in ${rev}`); continue; }
    if (sw.optional && !locate(text, sw.path)) continue;   // waiting (listed in the notes), not an error
    try { flip(text, sw); } catch (e) { problems.push(e.message); }
  }
  for (const w of pl.waiting) notes.push(`waiting, not on: ${w.id} (${w.why})`);
  for (const r of pending.rows.filter((x) => !x.file)) notes.push(`waiting, no key yet: ${r.id} (${r.owner}: ${r.what})`);
  if (pl.hostPatch) {
    const m = read('render/core/main.gd');
    try { const d = mkdtempSync(join(tmpdir(), 'preview-host-')); try { mkdirSync(join(d, 'render', 'core'), { recursive: true }); writeFileSync(join(d, 'render', 'core', 'main.gd'), m); applyPatchText(d, pl.hostPatch); notes.push('the right-hand host patch fits render/core/main.gd of this tree'); } finally { rmSync(d, { recursive: true, force: true }); } } catch (e) { problems.push(e.message); }
  }
  if (ov.length) notes.push(`overlay from the working tree (uncommitted): ${overlayFiles(repo, ov).files.length} files under ${ov.join(', ')}`);
  const show = (path) => ({ status: read(path) === null ? 1 : 0, stdout: read(path) });
  const m = show('render/core/main.gd');
  if (m.status !== 0) problems.push('render/core/main.gd: not in the revision');
  else { try { patchMain(m.stdout, pl.probes); } catch (e) { problems.push(e.message); } }
  return problems;
}

async function main() {
  const a = process.argv.slice(2);
  const known = new Set(['--off', '--planet', '--port', '--rev', '--no-smoke', '--no-serve', '--rebuild', '--bisect', '--list', '--check', '--godot', '--out', '--keep-tree', '--repo', '--godot-node', '--browser-path', '--overlay', '--open', '--help']);
  for (const x of a) if (x.startsWith('--') && !known.has(x)) { console.error(`unknown option ${x}; node tools/preview/preview.mjs --help`); process.exit(2); }
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  const all = (n) => a.flatMap((x, i) => (x === n && i + 1 < a.length ? [a[i + 1]] : []));
  const has = (n) => a.includes(n);
  if (has('--help')) { console.log(readFileSync(fileURLToPath(import.meta.url), 'utf8').split('\n').filter((l) => l.startsWith('//')).slice(0, 14).map((l) => l.slice(3)).join('\n')); return; }
  if (has('--list')) {
    const pend = readPending();
    console.log('The switches (all on by default; --off <id> turns one off; one whose key is not in the tree you build waits):');
    listSwitches(tableWith(pend.rows));
    for (const r of pend.rows.filter((x) => !x.file)) console.log(`  ${r.id.padEnd(11)} (waiting, no key yet) ${r.owner}: ${r.what}`);
    return;
  }
  const repo = resolve(opt('--repo', REPO));
  if (has('--check')) {
    const notes = [];
    const problems = checkTree(repo, opt('--rev', 'main'), { overlay: all('--overlay').flatMap((x) => x.split(',')), notes });
    if (problems.length) { for (const p of problems) console.error(`  ${p}`); process.exit(1); }
    for (const n of notes) console.log(`  ${n}`);
    console.log(`preview check ok for ${opt('--rev', 'main')}: every switch that is in the tree holds the value the table expects, the scratch patch fits render/core/main.gd${notes.some((n) => /^waiting/.test(n)) ? '; the switches that wait are listed above and are NOT checked (they are not in this tree)' : ''}`);
    return;
  }
  const planet = Number(opt('--planet', 7));
  if (!Number.isInteger(planet) || planet < 1) { console.error('--planet is a positive whole number (the planet\'s seed)'); process.exit(2); }
  const o = { repo, rev: opt('--rev', 'main'), off: all('--off'), planet, out: opt('--out'), godot: opt('--godot'), godotNode: opt('--godot-node'), rebuild: has('--rebuild'), keepTree: has('--keep-tree'), overlay: all('--overlay').flatMap((x) => x.split(',')).filter(Boolean), log: (m) => console.log(`[preview] ${m}`) };
  let b;
  try { b = await buildPreview(o); } catch (e) { console.error(`preview: ${e.message}`); process.exit(1); }
  console.log(`\nOrb Combat EX private preview of ${b.sha.slice(0, 8)}: ${b.subject}`);
  console.log(`  switches ON : ${b.active.length ? b.active.join(', ') : '(none: the plain build)'}`);
  console.log(`  switches OFF: ${b.table.map((s) => s.id).filter((i) => !b.active.includes(i) && !b.waiting.some((w) => w.id === i)).join(', ') || '(none)'}`);
  for (const w of b.waiting) console.log(`  WAITING, not in this build: ${w.id} (${w.why})`);
  if (b.overlay.length) console.log(`  OVERLAY: ${b.overlay.length} files of the working tree, uncommitted, over the commit (${(b.meta && b.meta.overlay ? b.meta.overlay : []).slice(0, 3).join(', ')}${b.overlay.length > 3 ? ', ...' : ''})`);
  if (b.hostPatched) console.log('  host patch: the pad\'s right stick is read through Controls\' right-hand-host.patch, applied to the scratch main.gd');
  for (const c of b.cascaded) console.log(`    (${c.id} is off too: it needs ${c.because.join(' + ')})`);
  for (const f of b.flips) console.log(`    flipped ${f.id.padEnd(10)} ${f.file} ${f.key}: ${f.alreadyOn ? `already ${f.now} in this commit` : `${f.was} -> ${f.now}`}`);
  console.log('  scratch code: a ?planet=N entry and a ?preview=1 state probe in render/core/main.gd of the scratch copy (the tree is not touched)');
  console.log(`  build: ${b.cached ? 'cached' : `built in ${Math.floor(b.seconds / 60)} m ${b.seconds % 60} s`}, ${b.web}`);
  if (b.scriptErrors && b.scriptErrors.length) { console.log(`  WARNING: the Godot logs hold ${b.scriptErrors.length}+ script errors, the first:`); for (const l of b.scriptErrors.slice(0, 3)) console.log(`    ${l.trim().slice(0, 200)}`); }
  let failed = false;
  if (has('--no-smoke')) console.log('  smoke check: skipped (--no-smoke)');
  else if (b.cached && b.meta.smoke && b.meta.smoke.ok) {   // a cached build that passed is not checked again; one that failed, or was never checked, is
    failed = !b.meta.smoke.ok;
    console.log(`  smoke check: ${b.meta.smoke.ok ? 'passed' : 'FAILED'} when this build was made (${b.meta.smoke.at})${b.meta.smoke.problems.map((p) => `\n    ${p}`).join('')}`);
  } else {
    const { smoke, describe } = await import('./smoke.mjs');
    console.log('  smoke check: booting the build in the guarded browser and playing it ...');
    try {
      const r = await smoke({ dir: b.web, on: b.active, planet, shot: join(b.dir, 'smoke.png'), exe: opt('--browser-path'), log: () => {} });
      saveSmoke(b, r);
      for (const l of describe(r)) console.log(l);
      failed = !r.ok;
      if (failed && has('--bisect')) await bisect(o, b);
    } catch (e) { console.log(`  smoke check could not run: ${e.message}`); failed = true; }
  }
  if (failed && !has('--no-serve')) console.log('  NOTE: the smoke check failed (above); the build is served anyway so it can be looked at.');
  if (has('--no-serve')) { process.exit(failed ? 1 : 0); }
  const want = opt('--port');
  const server = await serveLocal(b.web, want ? Number(want) : 8765, { strict: !!want });
  const url = `http://127.0.0.1:${server.address().port}/index.html?planet=${planet}`;
  console.log(`\nOpen this in Opera:\n\n    ${url}\n`);
  if (has('--open')) { try { spawn(process.platform === 'win32' ? 'cmd' : process.platform === 'darwin' ? 'open' : 'xdg-open', process.platform === 'win32' ? ['/c', 'start', '', url] : [url], { stdio: 'ignore', detached: true, windowsHide: true }).unref(); console.log('  (opened in your default browser)'); } catch { console.log('  (could not open it: open the address above)'); } }
  console.log('  localhost only (127.0.0.1); nothing is published, uploaded or dispatched. Ctrl-C stops it.');
  console.log(`  another planet: change planet=${planet} to another number; the hand-made world: leave ?planet out (no gen 2 switch shows there).`);
  console.log('  to compare, run the same command again with --off <switch> and a different --port, and open both.');
  process.on('SIGINT', () => { server.close(); process.exit(0); });
}

/** After a failed smoke check: builds and checks each switch alone (with what it needs), and the plain build, and says which fail. */
async function bisect(o, b) {
  const { smoke } = await import('./smoke.mjs');
  console.log('\n  bisect: each switch alone (a build and a check each; about as long as the first build)');
  for (const id of ['none', ...b.active]) {
    const on = id === 'none' ? [] : [id, ...b.table.find((s) => s.id === id).needs];
    const off = b.table.map((s) => s.id).filter((i) => !on.includes(i));
    const nb = await buildPreview({ ...o, off: [off.join(',')] });
    const r = await smoke({ dir: nb.web, on: nb.active, planet: o.planet, exe: o.browserPath, log: () => {} });
    saveSmoke(nb, r);
    console.log(`    ${id === 'none' ? 'no switch (the plain build)' : id}: ${r.ok ? 'passes' : `FAILS — ${r.problems.slice(0, 2).map((p) => p.text.slice(0, 160)).join(' | ')}`}`);
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await main();
