// One command: a PRIVATE, LOCAL, playable web build of main with the new planet's switches on, for Orb's own browser (docs/tools/preview.md). Never published, uploaded or dispatched.
//
//   node tools/preview/preview.mjs [--off water,floor] [--planet 7] [--port 8765] [--rev main] [--no-smoke] [--no-serve] [--rebuild] [--bisect]
//   node tools/preview/preview.mjs --list      the switches and what each does
//   node tools/preview/preview.mjs --check     do the switch table and the scratch patch still fit this tree? (no Godot, no browser, writes nothing)
//
// What it does: unpacks the committed tree of --rev (default main) into a scratch folder under the temp folder, turns the switches on there by editing the data files' text (the tree and tools/site.json are
// never touched), patches the SCRATCH copy's render/core/main.gd with a ?planet=N entry and a state probe (switches.mjs says why), imports and exports the Web build with the STANDARD template
// at below-normal priority (the live pin and the custom template are not involved), runs the boot-and-play smoke check through Tools' guarded browser launcher, and serves the build on 127.0.0.1 only.
// --off takes switch ids (comma-separated or repeated; "all" is the plain build); a switch that needs another is turned off with it and the report says so. --bisect, after a failed smoke check, builds
// and checks each switch alone to name the one that fails. A build is cached by commit, switches and patch, so the same command again serves at once (--rebuild to build again).
import { spawn, spawnSync } from 'node:child_process';
import { createReadStream, existsSync, mkdirSync, openSync, closeSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { constants as osConstants, setPriority, tmpdir } from 'node:os';
import { extname, join, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { exportRevision } from '../flash/head-export.mjs';
import { scriptErrors } from '../gate.mjs';
import { IDS, SWITCHES, EDITS_FINGERPRINT, flip, patchMain, resolve as resolveSwitches } from './switches.mjs';

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

/** Builds (or finds) the preview for a revision with these switches. Returns { web, dir, key, sha, subject, active, cascaded, flips, cached, seconds, meta }. Writes only under the output folder. */
export async function buildPreview(o) {
  const repo = resolve(o.repo || REPO);
  const log = o.log || (() => {});
  const r = resolveSwitches(o.off || []);
  if (r.unknown.length) throw new Error(`unknown switch ${r.unknown.join(', ')}: the switches are ${IDS.join(', ')} (or all)`);
  const sha = git(repo, ['rev-parse', '--verify', `${o.rev || 'main'}^{commit}`]);
  const subject = git(repo, ['log', '-1', '--format=%s', sha]).slice(0, 110);
  const date = git(repo, ['log', '-1', '--format=%cs', sha]);
  const key = buildKey(sha, r.active);
  const base = resolve(o.out || join(tmpdir(), 'meridian-preview'));
  const dir = join(base, key), web = join(dir, 'web'), tree = join(dir, 'tree'), metaFile = join(dir, 'preview.json');
  const out = { web, dir, key, sha, subject, active: r.active, cascaded: r.cascaded, cached: false, seconds: 0, flips: [], meta: null };
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
  writeFileSync(join(tree, 'build_info.json'), `${JSON.stringify({ commit: sha.slice(0, 7), date })}\n`);
  for (const sw of SWITCHES) {
    if (!r.active.includes(sw.id)) continue;
    const f = join(tree, ...sw.file.split('/'));
    const res = flip(readFileSync(f, 'utf8'), sw);
    if (res.text !== readFileSync(f, 'utf8')) writeFileSync(f, res.text);
    out.flips.push({ id: sw.id, file: sw.file, key: sw.path.join('.'), was: res.was, now: JSON.stringify(sw.to), alreadyOn: res.was === JSON.stringify(sw.to) });
  }
  const mainFile = join(tree, 'render', 'core', 'main.gd');
  writeFileSync(mainFile, patchMain(readFileSync(mainFile, 'utf8')));
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
  out.meta = { commit: sha, subject, active: r.active, flips: out.flips, planet: o.planet, builtAt: new Date().toISOString().slice(0, 16), seconds: out.seconds, smoke: null };
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

function listSwitches() {
  for (const sw of SWITCHES) console.log(`  ${sw.id.padEnd(11)} ${sw.file} ${sw.path.join('.')}: ${JSON.stringify(sw.from)} -> ${JSON.stringify(sw.to)}${sw.needs.length ? `   (needs ${sw.needs.join(' + ')})` : ''}\n              ${sw.what}`);
}

/** --check: does every switch's key sit where the table says, and does the scratch patch fit main.gd, in the committed tree of `rev`? Returns the problems. */
export function checkTree(repo, rev) {
  const problems = [];
  const show = (path) => spawnSync('git', ['show', `${rev}:${path}`], { cwd: repo, encoding: 'utf8', maxBuffer: 1 << 28 });
  for (const sw of SWITCHES) {
    const s = show(sw.file);
    if (s.status !== 0) { problems.push(`${sw.file}: not in ${rev}`); continue; }
    try { flip(s.stdout, sw); } catch (e) { problems.push(e.message); }
  }
  const m = show('render/core/main.gd');
  if (m.status !== 0) problems.push('render/core/main.gd: not in the revision');
  else { try { patchMain(m.stdout); } catch (e) { problems.push(e.message); } }
  return problems;
}

async function main() {
  const a = process.argv.slice(2);
  const known = new Set(['--off', '--planet', '--port', '--rev', '--no-smoke', '--no-serve', '--rebuild', '--bisect', '--list', '--check', '--godot', '--out', '--keep-tree', '--repo', '--godot-node', '--browser-path', '--help']);
  for (const x of a) if (x.startsWith('--') && !known.has(x)) { console.error(`unknown option ${x}; node tools/preview/preview.mjs --help`); process.exit(2); }
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  const all = (n) => a.flatMap((x, i) => (x === n && i + 1 < a.length ? [a[i + 1]] : []));
  const has = (n) => a.includes(n);
  if (has('--help')) { console.log(readFileSync(fileURLToPath(import.meta.url), 'utf8').split('\n').filter((l) => l.startsWith('//')).slice(0, 14).map((l) => l.slice(3)).join('\n')); return; }
  if (has('--list')) { console.log('The switches (all on by default; --off <id> turns one off):'); listSwitches(); return; }
  const repo = resolve(opt('--repo', REPO));
  if (has('--check')) {
    const problems = checkTree(repo, opt('--rev', 'main'));
    if (problems.length) { for (const p of problems) console.error(`  ${p}`); process.exit(1); }
    console.log(`preview check ok: ${SWITCHES.length} switches found where the table says, and the scratch patch fits render/core/main.gd of ${opt('--rev', 'main')}`);
    return;
  }
  const planet = Number(opt('--planet', 7));
  if (!Number.isInteger(planet) || planet < 1) { console.error('--planet is a positive whole number (the planet\'s seed)'); process.exit(2); }
  const o = { repo, rev: opt('--rev', 'main'), off: all('--off'), planet, out: opt('--out'), godot: opt('--godot'), godotNode: opt('--godot-node'), rebuild: has('--rebuild'), keepTree: has('--keep-tree'), log: (m) => console.log(`[preview] ${m}`) };
  let b;
  try { b = await buildPreview(o); } catch (e) { console.error(`preview: ${e.message}`); process.exit(1); }
  console.log(`\nOrb Combat EX private preview of ${b.sha.slice(0, 8)}: ${b.subject}`);
  console.log(`  switches ON : ${b.active.length ? b.active.join(', ') : '(none: the plain build)'}`);
  console.log(`  switches OFF: ${IDS.filter((i) => !b.active.includes(i)).join(', ') || '(none)'}`);
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
    const on = id === 'none' ? [] : [id, ...SWITCHES.find((s) => s.id === id).needs];
    const off = IDS.filter((i) => !on.includes(i));
    const nb = await buildPreview({ ...o, off: [off.join(',')] });
    const r = await smoke({ dir: nb.web, on: nb.active, planet: o.planet, exe: o.browserPath, log: () => {} });
    saveSmoke(nb, r);
    console.log(`    ${id === 'none' ? 'no switch (the plain build)' : id}: ${r.ok ? 'passes' : `FAILS — ${r.problems.slice(0, 2).map((p) => p.text.slice(0, 160)).join(' | ')}`}`);
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await main();
