// Web parity (docs/architecture/web-parity.md): is the sim bit-identical between the native build and the web (wasm)
// build? One command, for a PC or CI:
//   node sim/core/tools/web_parity.mjs [--godot <exe>] [--work <dir>] [--time-limit 3000] [--session <name>] [--keep]
// 1. A copy of the project: `git archive HEAD` when run in a repository, else the folder (no .godot, build, .git).
// 2. In the copy, the main scene becomes res://sim/core/tools/web_parity.tscn (the probe: SimGolden.build()'s keys one
//    a frame, then extras for what ships switched off).
// 3. Import; the probe natively (headless) writes native.json; the web export (the project's own "Web" preset).
// 4. The export in headless Chrome through Tools' launcher (tools/machine/browser.mjs: a time limit, below-normal
//    priority, a CPU cap, a session-named profile), the probe's results read over the DevTools protocol: web.json.
// 5. Native and web against sim/core/test/golden.json key by key (the first checkpoint that differs, and which of its
//    state, view and camera hashes), and the extras native against web. Exit 1 on any difference or failure.
// Godot: --godot, else $GODOT, else Godot on the PATH. Node 24 built-ins only.
import { spawnSync } from 'node:child_process';
import { cpSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve, dirname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');
const arg = (k, d) => { const i = process.argv.indexOf(k); return i >= 0 ? process.argv[i + 1] : d; };
const GODOT = arg('--godot', process.env.GODOT || 'godot');
const WORK = resolve(arg('--work', join(tmpdir(), `meridian-webparity-${process.pid}`)));
const LIMIT_S = Number(arg('--time-limit', 3000));
const SESSION = arg('--session', process.env.MERIDIAN_SESSION || 'meridian-simulation');
const KEEP = process.argv.includes('--keep');
const SCENE = 'res://sim/core/tools/web_parity.tscn';
const ROOT = join(WORK, 'root');
const log = (m) => console.log(`[web-parity] ${m}`);

function run(cmd, args, opts = {}) {
  const t0 = Date.now();
  const r = spawnSync(cmd, args, { cwd: opts.cwd || ROOT, encoding: 'utf8', maxBuffer: 1 << 28, timeout: (opts.timeoutS || 1800) * 1000 });
  const out = (r.stdout || '') + (r.stderr || '');
  if (opts.logTo) writeFileSync(opts.logTo, out);
  const errs = out.split('\n').filter((l) => /SCRIPT ERROR|Parse Error/.test(l));
  if (r.status !== 0 || errs.length) throw new Error(`${opts.what || cmd} failed (exit ${r.status}${r.error ? ', ' + r.error.message : ''}${errs.length ? ', ' + errs[0] : ''})`);
  log(`${opts.what || cmd}: ${((Date.now() - t0) / 1000).toFixed(0)} s`);
  return out;
}

function copyProject() {
  rmSync(ROOT, { recursive: true, force: true });
  mkdirSync(ROOT, { recursive: true });
  if (existsSync(join(REPO, '.git'))) {
    const tar = join(WORK, 'head.tar');
    run('git', ['archive', '--format=tar', '-o', tar, 'HEAD'], { cwd: REPO, what: 'git archive HEAD' });
    run('tar', ['-xf', '../head.tar'], { cwd: ROOT, what: 'unpack' });   // relative: a GNU tar reads "C:\..." as a remote host
  } else {
    const skip = new Set(['.godot', 'build', '.git', 'node_modules'].map((d) => join(REPO, d)));
    cpSync(REPO, ROOT, { recursive: true, filter: (p) => !skip.has(p) });
    log('copied the folder (not a repository)');
  }
  const p = join(ROOT, 'project.godot');
  const s = readFileSync(p, 'utf8');
  const s2 = s.replace(/run\/main_scene="[^"]*"/, `run/main_scene="${SCENE}"`);
  if (s2 === s) throw new Error('project.godot has no run/main_scene to replace');
  writeFileSync(p, s2);
  // The export presets leave the in-game tools folders out of the pack (they are never run in the game), and the probe lives in sim/core/tools: this copy keeps that one folder.
  const ep = join(ROOT, 'export_presets.cfg');
  if (existsSync(ep)) writeFileSync(ep, readFileSync(ep, 'utf8').split(', sim/core/tools/*').join(''));
}

async function webRun(site) {
  const { launchBrowser, Cdp, serve } = await import(pathToFileURL(join(REPO, 'tools/machine/browser.mjs')).href);
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const server = await serve(site);
  let b, page;
  try {
    b = await launchBrowser({ session: SESSION, purpose: 'webparity', timeoutS: LIMIT_S, log,
      flags: ['--window-size=640,360', '--disable-background-timer-throttling', '--disable-renderer-backgrounding', '--disable-backgrounding-occluded-windows',
        // a CI runner has no GPU: the Compatibility renderer needs WebGL2, so Chrome falls back to its software renderer (it must be asked to since Chrome 137)
        ...(process.env.CI ? ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] : [])] });
    page = await Cdp.open(b.target.webSocketDebuggerUrl);
    await page.send('Page.enable');
    const t0 = Date.now();
    await page.send('Page.navigate', { url: `http://127.0.0.1:${server.address().port}/index.html` });
    let n = 0, i = -1, lastI = -1;
    while (Date.now() < b.deadlineMs - 30000) {
      await sleep(3000);
      const st = await page.eval('window.__wp ? [window.__wp.n, window.__wp.i] : null').catch(() => null);
      if (!st) { if (Date.now() - t0 > 600000) throw new Error('the probe never started on the web (no window.__wp in 10 minutes)'); continue; }
      [n, i] = st;
      if (i !== lastI && (i === n || i % 10 === 0)) log(`web: ${i} of ${n} keys after ${((Date.now() - t0) / 1000).toFixed(0)} s`);
      lastI = i;
      if (i >= n) break;
    }
    if (i < n) throw new Error(`the web run timed out at ${i} of ${n} keys`);
    const out = {};
    for (const k of await page.eval('window.__wp.keys')) out[k] = JSON.parse(await page.eval(`window.__wp.res[${JSON.stringify(k)}]`));
    log(`web: ${Object.keys(out).length} keys in ${((Date.now() - t0) / 1000).toFixed(0)} s (${await page.eval('navigator.userAgent')})`);
    return out;
  } finally {
    try { page && page.close(); } catch { /* gone */ }
    try { b && (await b.close()); } catch { /* gone */ }
    server.close();
  }
}

// key order is not a value: Godot's JSON.stringify sorts keys unless told not to, and golden.json is written unsorted
const canon = (v) => Array.isArray(v) ? v.map(canon) : (v && typeof v === 'object') ? Object.fromEntries(Object.keys(v).sort().map((k) => [k, canon(v[k])])) : v;
const same = (x, y) => JSON.stringify(canon(x)) === JSON.stringify(canon(y));

function runDiff(got, exp, every) {
  const out = [];
  for (const k of ['arm', 'seed', 'cap', 'ticks', 'light', 'final']) if (!same(got[k], exp[k])) out.push(`${k} ${JSON.stringify(got[k])} vs ${JSON.stringify(exp[k])}`);
  const n = Math.max(got.checkpoints.length, exp.checkpoints.length);
  for (let i = 0; i < n; i++) {
    if (got.checkpoints[i] !== exp.checkpoints[i]) {
      const a = String(got.checkpoints[i]).split(':'), b = String(exp.checkpoints[i]).split(':');
      out.push(`first checkpoint ${i} (tick ${i * every}) differs in ${['state', 'view', 'camera'].filter((_, j) => a[j] !== b[j]).join(', ') || 'length'}`);
      break;
    }
  }
  return out.join('; ');
}

function why(key, got, exp, every) {
  if (got === undefined) return 'missing';
  if (key.startsWith('matches.') || (got && got.checkpoints)) return runDiff(got, exp, every);
  if (key.startsWith('replays.')) return (same(got.replay, exp.replay) ? '' : 'the scripted replay differs; ') + runDiff(got.run, exp.run, every);
  if (key === 'planet') return ['slices', 'tick0'].filter((k) => !same(got[k], exp[k])).concat(same(got.match, exp.match) ? [] : ['match: ' + runDiff(got.match, exp.match, every)]).join('; ');
  if (Array.isArray(got) && Array.isArray(exp)) { const i = got.findIndex((v, j) => !same(v, exp[j])); return `first entry ${i} of ${got.length}`; }
  return `${JSON.stringify(got).slice(0, 100)} vs ${JSON.stringify(exp).slice(0, 100)}`;
}

function compare(g, nat, web) {
  const want = (key) => { const [a, b] = key.split('.'); return b === undefined ? g[a] : g[a] === undefined ? undefined : (a === 'matches' || a === 'replays') ? g[a][Number(b)] : g[a][b]; };
  const every = g.checkEvery;
  const lines = [];
  let golden = 0, extras = 0, bad = 0;
  for (const key of Object.keys(nat)) {
    const exp = key.startsWith('x.') ? undefined : want(key);
    if (exp !== undefined) {
      golden++;
      for (const [side, r] of [['native', nat], ['web', web]]) if (!same(r[key], exp)) { bad++; lines.push(`DIFF ${side} ${key} against golden.json: ${why(key, r[key], exp, every)}`); }
    } else if (key.startsWith('x.')) {
      extras++;
      if (!same(web[key], nat[key])) { bad++; lines.push(`DIFF web ${key} against native: ${why(key, web[key], nat[key], every)}`); }
    } else { bad++; lines.push(`DIFF ${key}: not in golden.json`); }
  }
  return { golden, extras, bad, lines };
}

let code = 0;
try {
  mkdirSync(WORK, { recursive: true });
  copyProject();
  run(GODOT, ['--headless', '--path', '.', '--import'], { what: 'import', logTo: join(WORK, 'import.log') });
  run(GODOT, ['--headless', '--path', '.', SCENE, '--', join(WORK, 'native.json')], { what: 'the probe, native', logTo: join(WORK, 'native.log') });
  mkdirSync(join(ROOT, 'build/web'), { recursive: true });
  run(GODOT, ['--headless', '--path', '.', '--export-release', 'Web', 'build/web/index.html'], { what: 'the web export', logTo: join(WORK, 'export.log') });
  const web = await webRun(join(ROOT, 'build/web'));
  writeFileSync(join(WORK, 'web.json'), JSON.stringify(web));
  const nat = JSON.parse(readFileSync(join(WORK, 'native.json'), 'utf8'));
  const g = JSON.parse(readFileSync(join(ROOT, 'sim/core/test/golden.json'), 'utf8'));
  const c = compare(g, nat, web);
  for (const l of c.lines) console.log(l);
  console.log(c.bad ? `web parity FAILED: ${c.bad} difference(s)` : `web parity passed: ${c.golden} golden keys identical to golden.json natively and on the web, ${c.extras} extras identical native and web`);
  code = c.bad ? 1 : 0;
} catch (e) {
  console.log(`web parity FAILED: ${e.message}`);
  code = 1;
} finally {
  if (!KEEP) rmSync(ROOT, { recursive: true, force: true });
}
process.exit(code);
