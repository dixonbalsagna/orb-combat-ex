// A PRIVATE, LOCAL, playable web build of the STACK (the EP, 2026-10-31): HEAD plus every ready park of tools/preview/stack.json, every switch on, for Orb's own browser. Never published, uploaded or dispatched.
//
//   node tools/preview/stack-preview.mjs [--planet 7] [--port 8765] [--off tiles,meteor] [--skip park,park] [--only park,park] [--rebuild] [--no-smoke] [--no-serve] [--open] [--repo <dir>] [--manifest <file>] [--godot <exe>]
//
// What it does: tools/preview/stack.mjs unpacks HEAD into a scratch tree, applies the parks in order and turns their switches on (the tree it keeps is the stack's, not the repository's); then, as preview.mjs does for a
// commit, the scratch copy's render/core/main.gd gets a ?planet=N entry and a state probe (and Controls' host patch when the tree has not got the pad's right stick), the project is imported and the Web build exported
// with the STANDARD template at below-normal priority, the boot-and-play smoke check runs through Tools' guarded browser launcher, and the build is served on 127.0.0.1 only. A park that does not apply is left out and
// named; the build is made without it. A build is cached by the stack's key (the commit and the bytes of every park file and manifest entry) and the switches.
import { spawn } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { scriptErrors } from '../gate.mjs';
import { HOST_PATCH, applyPatchText, godotExe, plan, readPending, runGodot, saveSmoke, serveLocal } from './preview.mjs';
import { describeReport, runStack } from './stack.mjs';
import { patchMain } from './switches.mjs';

const HERE = fileURLToPath(new URL('.', import.meta.url));
const REPO = resolve(HERE, '..', '..');

const tail = (f, n = 1500) => { try { return readFileSync(f, 'utf8').slice(-n); } catch { return ''; } };

export async function buildStackPreview(o) {
  const repo = resolve(o.repo || REPO);
  const log = o.log || (() => {});
  const pend = readPending();
  if (pend.problems.length) throw new Error(`tools/preview/switches-pending.json: ${pend.problems.join('; ')}`);
  const base = resolve(o.out || join(tmpdir(), 'meridian-stack-preview'));
  // the stack: applied and switched, no Godot; its tree kept
  const s = await runStack({ repo, manifest: o.manifest, rev: o.rev || 'main', only: o.only, skip: o.skip, noGodot: true, keepTree: true, force: true, out: join(base, 'stack'), state: join(base, 'stack-last.json'), log });
  const r = s.report;
  const tree = join(base, 'stack', `${r.commit.slice(0, 8)}-${r.key}`, 'tree');
  if (!existsSync(join(tree, 'render', 'core', 'main.gd'))) throw new Error(`the stack tree is not where it should be: ${tree}`);
  const read = (p) => {
    const f = join(tree, ...p.split('/'));
    if (existsSync(f)) return readFileSync(f, 'utf8');
    if (p === HOST_PATCH && existsSync(join(repo, ...p.split('/')))) return readFileSync(join(repo, ...p.split('/')), 'utf8');   // an owner's pending file, in the working tree and not in the commit
    return null;
  };
  const pl = plan(repo, r.commit, { off: o.off || [], pending: pend.rows, read });
  const out = { sha: r.commit, subject: r.subject, report: r, stackLines: describeReport(r), active: pl.active, waiting: pl.waiting, cascaded: pl.cascaded, urlWords: pl.urlWords, table: pl.table, unknown: pl.unknown, hostPatched: !!pl.hostPatch, cached: false, seconds: 0, dir: null, web: null, meta: null, scriptErrors: [] };
  if (pl.unknown.length) throw new Error(`unknown switch ${pl.unknown.join(', ')}`);
  const parksIn = r.parks.filter((p) => p.status === 'applied').map((p) => p.id);
  const key = `${r.key}-${pl.active.join('+')}${pl.hostPatch ? '-host' : ''}`.replace(/[^A-Za-z0-9+._-]/g, '_').slice(0, 120);
  const dir = join(base, 'build', key), web = join(dir, 'web'), metaFile = join(dir, 'preview.json');
  Object.assign(out, { dir, web });
  if (!o.rebuild && existsSync(join(web, 'index.html')) && existsSync(metaFile)) {
    out.cached = true; out.meta = JSON.parse(readFileSync(metaFile, 'utf8'));
    rmSync(join(base, 'stack', `${r.commit.slice(0, 8)}-${r.key}`), { recursive: true, force: true });
    return out;
  }
  const t0 = Date.now();
  mkdirSync(dir, { recursive: true });
  rmSync(web, { recursive: true, force: true });
  mkdirSync(web, { recursive: true });
  writeFileSync(join(tree, 'build_info.json'), `${JSON.stringify({ commit: r.commit.slice(0, 7), stack: parksIn.length })}\n`);
  const mainFile = join(tree, 'render', 'core', 'main.gd');
  if (pl.hostPatch) { applyPatchText(tree, pl.hostPatch); log('applied the right-hand host patch to the scratch main.gd (the pad\'s right stick)'); }
  writeFileSync(mainFile, patchMain(readFileSync(mainFile, 'utf8'), pl.probes, pl.setup));
  const godot = o.godotNode ? null : godotExe(o.godot);
  const g = { godot, godotNode: o.godotNode };
  const importLog = join(dir, 'import.log'), exportLog = join(dir, 'export.log');
  log('importing the project (Godot, below-normal priority)');
  let code = await runGodot(g, ['--headless', '--path', tree, '--import'], importLog, 25 * 60 * 1000);
  if (code !== 0) throw new Error(`Godot --import exited ${code}; the end of ${importLog}:\n${tail(importLog)}`);
  log('exporting Web (standard template, single-threaded)');
  code = await runGodot(g, ['--headless', '--path', tree, '--export-release', 'Web', join(web, 'index.html')], exportLog, 25 * 60 * 1000);
  if (code !== 0 || !existsSync(join(web, 'index.html'))) throw new Error(`Godot --export-release Web exited ${code}; the end of ${exportLog}:\n${tail(exportLog)}`);
  out.scriptErrors = scriptErrors(`${tail(importLog, 4000)}\n${tail(exportLog, 4000)}`).slice(0, 6);
  if (!o.keepTree) rmSync(join(base, 'stack', `${r.commit.slice(0, 8)}-${r.key}`), { recursive: true, force: true });
  out.seconds = Math.round((Date.now() - t0) / 1000);
  out.meta = { commit: r.commit, subject: r.subject, stack: parksIn, active: pl.active, waiting: pl.waiting, planet: o.planet, builtAt: new Date().toISOString().slice(0, 16), seconds: out.seconds, smoke: null };
  writeFileSync(metaFile, `${JSON.stringify(out.meta, null, 2)}\n`);
  return out;
}

async function main() {
  const a = process.argv.slice(2);
  const known = new Set(['--planet', '--port', '--off', '--skip', '--only', '--rebuild', '--no-smoke', '--no-serve', '--open', '--repo', '--manifest', '--godot', '--godot-node', '--browser-path', '--out', '--keep-tree', '--help']);
  for (const x of a) if (x.startsWith('--') && !known.has(x)) { console.error(`unknown option ${x}; node tools/preview/stack-preview.mjs --help`); process.exit(2); }
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  const has = (n) => a.includes(n);
  const list = (n) => opt(n, '').split(',').filter(Boolean);
  if (has('--help')) { console.log(readFileSync(fileURLToPath(import.meta.url), 'utf8').split('\n').filter((l) => l.startsWith('//')).slice(0, 10).map((l) => l.slice(3)).join('\n')); return; }
  const planet = Number(opt('--planet', 7));
  if (!Number.isInteger(planet) || planet < 1) { console.error('--planet is a positive whole number (the planet\'s seed)'); process.exit(2); }
  const o = { repo: opt('--repo'), manifest: opt('--manifest'), planet, off: list('--off'), skip: list('--skip'), only: list('--only'), out: opt('--out'), godot: opt('--godot'), godotNode: opt('--godot-node'), rebuild: has('--rebuild'), keepTree: has('--keep-tree'), log: (m) => console.error(`[stack-preview] ${m}`) };
  let b;
  try { b = await buildStackPreview(o); } catch (e) { console.error(`stack-preview: ${e.message}`); process.exit(1); }
  console.log(`\nOrb Combat EX private preview of the STACK on ${b.sha.slice(0, 8)}: ${b.subject}`);
  const rep = b.report;
  console.log(`  parks in the build : ${rep.parks.filter((p) => p.status === 'applied').map((p) => p.id).join(', ')}`);
  for (const p of rep.parks.filter((x) => x.status !== 'applied')) console.log(`  LEFT OUT           : ${p.id} (${p.owner}) ${p.status}`);
  if (rep.firstConflict) console.log(`  FIRST CONFLICT     : park ${rep.firstConflict.park}, ${rep.firstConflict.file}`);
  console.log(`  switches ON        : ${b.active.join(', ')}`);
  console.log(`  switches OFF       : ${b.table.map((s) => s.id).filter((i) => !b.active.includes(i) && !b.waiting.some((w) => w.id === i)).join(', ') || '(none)'}`);
  for (const w of b.waiting) console.log(`  WAITING, not in this build: ${w.id} (${w.why})`);
  if (b.hostPatched) console.log('  host patch: the pad\'s right stick is read through Controls\' right-hand-host.patch, applied to the scratch main.gd');
  console.log(`  build: ${b.cached ? 'cached' : `built in ${Math.floor(b.seconds / 60)} m ${b.seconds % 60} s`}, ${b.web}`);
  if (b.scriptErrors && b.scriptErrors.length) { console.log(`  WARNING: the Godot logs hold ${b.scriptErrors.length}+ script errors, the first:`); for (const l of b.scriptErrors.slice(0, 3)) console.log(`    ${l.trim().slice(0, 200)}`); }
  let failed = false;
  if (has('--no-smoke')) console.log('  smoke check: skipped (--no-smoke)');
  else if (b.cached && b.meta.smoke && b.meta.smoke.ok) console.log(`  smoke check: passed when this build was made (${b.meta.smoke.at})`);
  else {
    const { smoke, describe } = await import('./smoke.mjs');
    console.log('  smoke check: booting the build in the guarded browser and playing it ...');
    try {
      const r = await smoke({ dir: b.web, on: b.active, planet, extraQuery: (b.urlWords || []).join('&'), shot: join(b.dir, 'smoke.png'), exe: opt('--browser-path'), log: () => {} });
      saveSmoke(b, r);
      for (const l of describe(r)) console.log(l);
      failed = !r.ok;
    } catch (e) { console.log(`  smoke check could not run: ${e.message}`); failed = true; }
  }
  if (failed && !has('--no-serve')) console.log('  NOTE: the smoke check failed (above); the build is served anyway so it can be looked at.');
  if (has('--no-serve')) process.exit(failed ? 1 : 0);
  const want = opt('--port');
  const server = await serveLocal(b.web, want ? Number(want) : 8765, { strict: !!want });
  const url = `http://127.0.0.1:${server.address().port}/index.html?planet=${planet}${b.urlWords && b.urlWords.length ? `&${b.urlWords.join('&')}` : ''}`;
  console.log(`\nOpen this in Opera:\n\n    ${url}\n`);
  if (has('--open')) { try { spawn(process.platform === 'win32' ? 'cmd' : process.platform === 'darwin' ? 'open' : 'xdg-open', process.platform === 'win32' ? ['/c', 'start', '', url] : [url], { stdio: 'ignore', detached: true, windowsHide: true }).unref(); console.log('  (opened in the default browser)'); } catch { /* not worth failing for */ } }
  console.log('  localhost only (127.0.0.1); nothing is published, uploaded or dispatched. Ctrl-C stops it.');
  process.on('SIGINT', () => { server.close(); process.exit(0); });
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await main();
