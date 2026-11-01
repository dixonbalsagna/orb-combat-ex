// A PRIVATE, LOCAL, playable web build of the STACK (the EP, 2026-10-31): HEAD plus every ready park of tools/preview/stack.json, every switch on, for Orb's own browser. Never published, uploaded or dispatched.
//
//   node tools/preview/stack-preview.mjs [--planet 7] [--port 8765] [--off tiles,meteor] [--skip park,park] [--only park,park] [--rebuild] [--no-smoke] [--no-serve] [--open] [--template custom|standard|<zip>] [--watch [--every 120] [--min-gap 1800] [--max-load 90]] [--repo <dir>] [--manifest <file>] [--godot <exe>]
//
// What it does: tools/preview/stack.mjs unpacks HEAD into a scratch tree, applies the parks in order and turns their switches on (the tree it keeps is the stack's, not the repository's); then, as preview.mjs does for a
// commit, the scratch copy's render/core/main.gd gets a ?planet=N entry and a state probe (and Controls' host patch when the tree has not got the pad's right stick), the project is imported and the Web build exported
// with the STANDARD template at below-normal priority, the boot-and-play smoke check runs through Tools' guarded browser launcher, and the build is served on 127.0.0.1 only. A park that does not apply is left out and
// named; the build is made without it. A build is cached by the stack's key (the commit and the bytes of every park file and manifest entry) and the switches.
import { spawn } from 'node:child_process';
import { cpSync, createReadStream, existsSync, mkdirSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { cpus, tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { scriptErrors } from '../gate.mjs';
import { HOST_PATCH, applyPatchText, godotExe, plan, readPending, runGodot, saveSmoke, serveLocal } from './preview.mjs';
import { describeReport, loadManifest, runStack, stackKey } from './stack.mjs';
import { patchMain } from './switches.mjs';
import { setWebCustomTemplate } from '../flash/web-preset.mjs';
import { fetchTemplate } from '../site-template.mjs';

const HERE = fileURLToPath(new URL('.', import.meta.url));
const REPO = resolve(HERE, '..', '..');

/** The machine's CPU use over `ms` milliseconds, 0 to 100 (all cores, every process). */
export async function cpuLoad(ms = 1000) {
  const snap = () => cpus().reduce((a, c) => { const t = Object.values(c.times).reduce((x, y) => x + y, 0); return { idle: a.idle + c.times.idle, total: a.total + t }; }, { idle: 0, total: 0 });
  const a = snap();
  await new Promise((r) => setTimeout(r, ms));
  const b = snap();
  return b.total === a.total ? 0 : Math.round(100 * (1 - (b.idle - a.idle) / (b.total - a.total)));
}

/** The template zip for --template: null for the standard one; 'custom' is the pinned zip (a verified copy on disk, else downloaded and verified by tools/site-template.mjs); any other value is the path of a scratch zip, used as it is. */
export function templateZip(spec, repo) {
  if (!spec || spec === 'standard') return null;
  if (spec !== 'custom') { const p = resolve(spec); if (!existsSync(p)) throw new Error(`--template: ${p} is not there`); return p; }
  const rec = JSON.parse(readFileSync(join(repo, 'tools', 'web-template.json'), 'utf8'));
  const dir = join(tmpdir(), 'site-web-template'), file = join(dir, 'web_nothreads_release.zip');
  if (existsSync(file)) {
    const buf = readFileSync(file);
    if ((!Number.isInteger(rec.bytes) || buf.length === rec.bytes) && createHash('sha512').update(buf).digest('hex') === rec.sha512) return file;
  }
  return fetchTemplate(rec, dir);
}

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
  const out = { sha: r.commit, subject: r.subject, report: r, stackLines: describeReport(r), active: pl.active, waiting: pl.waiting, cascaded: pl.cascaded, urlWords: pl.urlWords, alts: pl.alts, table: pl.table, unknown: pl.unknown, hostPatched: !!pl.hostPatch, cached: false, seconds: 0, dir: null, web: null, meta: null, scriptErrors: [] };
  if (pl.unknown.length) throw new Error(`unknown switch ${pl.unknown.join(', ')}`);
  const parksIn = r.parks.filter((p) => p.status === 'applied').map((p) => p.id);
  const tz = templateZip(o.template, repo);
  const tzKey = tz ? `-t${createHash('sha1').update(readFileSync(tz)).digest('hex').slice(0, 8)}` : '';
  const key = `${r.key}-${pl.active.join('+')}${pl.hostPatch ? '-host' : ''}${tzKey}`.replace(/[^A-Za-z0-9+._-]/g, '_').slice(0, 120);
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
  writeFileSync(mainFile, patchMain(readFileSync(mainFile, 'utf8'), pl.probes, pl.setup, { swingsOff: pl.swingsOff, sticks: pl.sticksOk, struggleOff: pl.active.includes('struggle'), kickWord: pl.kickWord, tierWord: pl.tierWord }));
  if (tz) {   // the scratch tree's copy of the Web preset only: the engine template this page is exported with
    const pf = join(tree, 'export_presets.cfg');
    writeFileSync(pf, setWebCustomTemplate(readFileSync(pf, 'utf8'), tz.split('\\').join('/')));
    log(`exporting with the custom template ${tz}`);
  }
  const godot = o.godotNode ? null : godotExe(o.godot);
  const g = { godot, godotNode: o.godotNode };
  const importLog = join(dir, 'import.log'), exportLog = join(dir, 'export.log');
  log('importing the project (Godot, below-normal priority)');
  let code = await runGodot(g, ['--headless', '--path', tree, '--import'], importLog, 25 * 60 * 1000);
  if (code !== 0) throw new Error(`Godot --import exited ${code}; the end of ${importLog}:\n${tail(importLog)}`);
  log(`exporting Web (${tz ? 'custom' : 'standard'} template, single-threaded)`);
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
  const known = new Set(['--template', '--watch', '--every', '--min-gap', '--max-load', '--planet', '--port', '--off', '--skip', '--only', '--rebuild', '--no-smoke', '--no-serve', '--open', '--repo', '--manifest', '--godot', '--godot-node', '--browser-path', '--out', '--keep-tree', '--help']);
  for (const x of a) if (x.startsWith('--') && !known.has(x)) { console.error(`unknown option ${x}; node tools/preview/stack-preview.mjs --help`); process.exit(2); }
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  const has = (n) => a.includes(n);
  const list = (n) => opt(n, '').split(',').filter(Boolean);
  if (has('--help')) { console.log(readFileSync(fileURLToPath(import.meta.url), 'utf8').split('\n').filter((l) => l.startsWith('//')).slice(0, 10).map((l) => l.slice(3)).join('\n')); return; }
  const planet = Number(opt('--planet', 7));
  if (!Number.isInteger(planet) || planet < 1) { console.error('--planet is a positive whole number (the planet\'s seed)'); process.exit(2); }
  const o = { repo: opt('--repo'), manifest: opt('--manifest'), planet, off: list('--off'), skip: list('--skip'), only: list('--only'), out: opt('--out'), godot: opt('--godot'), godotNode: opt('--godot-node'), template: opt('--template', 'custom'), rebuild: has('--rebuild'), keepTree: has('--keep-tree'), log: (m) => console.error(`[stack-preview] ${m}`) };
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
  const watching = has('--watch');
  let live = b.web;
  if (watching) {   // the page is served from a stable folder, so a new build can be swapped in under the same address
    live = join(resolve(o.out || join(tmpdir(), 'meridian-stack-preview')), 'live');
    rmSync(live, { recursive: true, force: true }); cpSync(b.web, live, { recursive: true });
  }
  const server = await serveLocal(live, want ? Number(want) : 8765, { strict: !!want });
  const url = `http://127.0.0.1:${server.address().port}/index.html?planet=${planet}${b.urlWords && b.urlWords.length ? `&${b.urlWords.join('&')}` : ''}`;
  console.log(`\nOpen this in Opera:\n\n    ${url}\n`);
  for (const a of b.alts || []) console.log(`  ${a.label}: ${a.add ? `${url}&${a.add}` : url.replace(a.word, a.to)}\n`);
  if (has('--open')) { try { spawn(process.platform === 'win32' ? 'cmd' : process.platform === 'darwin' ? 'open' : 'xdg-open', process.platform === 'win32' ? ['/c', 'start', '', url] : [url], { stdio: 'ignore', detached: true, windowsHide: true }).unref(); console.log('  (opened in the default browser)'); } catch { /* not worth failing for */ } }
  console.log('  localhost only (127.0.0.1); nothing is published, uploaded or dispatched. Ctrl-C stops it.');
  if (watching) {
    const every = Math.max(30, Number(opt('--every', 120))) * 1000;
    const repo = resolve(o.repo || REPO), stamp = () => new Date().toISOString().slice(11, 19);
    const keyNow = () => {
      const sha = spawnSync('git', ['rev-parse', '--verify', 'main^{commit}'], { cwd: repo, encoding: 'utf8' }).stdout.trim();
      const man = loadManifest(readFileSync(resolve(o.manifest || join(HERE, 'stack.json')), 'utf8'));
      const only = new Set(o.only), skip = new Set(o.skip);
      return stackKey(repo, sha, man.parks.filter((p) => (!only.size || only.has(p.id)) && !skip.has(p.id) && p.ready !== false));
    };
    const minGap = Math.max(0, Number(opt('--min-gap', 1800))) * 1000, maxLoad = Number(opt('--max-load', 90));
    let last = keyNow(), busy = false, lastEnd = Date.now(), noted = '';
    const note = (key, why) => { if (noted !== key + why) { noted = key + why; console.log(`[${stamp()}] a change is waiting: ${why}`); } };
    console.log(`  WATCHING: every ${every / 1000} s the stack's key is read; a re-cut of any park file, the manifest or main rebuilds the page under this address, at most one rebuild per ${minGap / 60000} minutes and none while the CPU is above ${maxLoad}%.`);
    setInterval(async () => {
      if (busy) return;
      let now;
      try { now = keyNow(); } catch (e) { console.log(`[${stamp()}] watch: could not read the stack key: ${e.message}`); return; }
      if (now === last) return;
      if (Date.now() - lastEnd < minGap) { note(now, `the last build was ${Math.round((Date.now() - lastEnd) / 60000)} min ago (the gap is ${minGap / 60000})`); return; }
      const ld = await cpuLoad();
      if (ld > maxLoad) { note(now, `the machine is at ${ld}% CPU (the limit is ${maxLoad}%)`); return; }
      busy = true;
      console.log(`[${stamp()}] a park or main changed: rebuilding`);
      try {
        const nb = await buildStackPreview({ ...o, rebuild: true, log: () => {} });
        let ok = true, why = '';
        if (!has('--no-smoke')) {
          const { smoke } = await import('./smoke.mjs');
          const r = await smoke({ dir: nb.web, on: nb.active, planet, extraQuery: (nb.urlWords || []).join('&'), shot: join(nb.dir, 'smoke.png'), exe: opt('--browser-path'), log: () => {} });
          saveSmoke(nb, r); ok = r.ok; why = r.problems.map((p) => p.text).slice(0, 3).join(' | ');
        }
        if (nb.report.firstConflict) console.log(`[${stamp()}]   FIRST CONFLICT: park ${nb.report.firstConflict.park}, ${nb.report.firstConflict.file}`);
        if (ok) {
          rmSync(live + '.next', { recursive: true, force: true }); cpSync(nb.web, live + '.next', { recursive: true });
          cpSync(live + '.next', live, { recursive: true, force: true }); rmSync(live + '.next', { recursive: true, force: true });
          console.log(`[${stamp()}] swapped in: parks ${nb.report.parks.filter((p) => p.status === 'applied').length} applied, smoke check passed`);
        } else console.log(`[${stamp()}] the new build FAILED its smoke check (${why}); the page stays as it was`);
        last = now; lastEnd = Date.now();
      } catch (e) { console.log(`[${stamp()}] rebuild failed: ${e.message.split('\n')[0]}; the page stays as it was`); last = now; lastEnd = Date.now(); }
      busy = false;
    }, every);
  }
  process.on('SIGINT', () => { server.close(); process.exit(0); });
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await main();
