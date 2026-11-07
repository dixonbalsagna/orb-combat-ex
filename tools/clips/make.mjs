// The clip kit (Tools, 2026-11-06; docs/tools/clips.md): clips from a built page, with no picture read back into a session.
//
//   node tools/clips/make.mjs <name|all> [--build <kept folder or part of its name>] [--format gif|png|webm] [--out <folder>] [--limit seconds] [--keep-frames]
//   node tools/clips/make.mjs --from-match <saved match.json> [--build <kept folder>] [--format gif|png|webm]    every mark and bookmark of a saved match, through the replay
//   node tools/clips/make.mjs --list | --dry <name|all>
//
// A recipe (tools/clips/clips.json) names a scene of the capture hook (or a mockup script), a seed, page words, a tick window or an event window, a crop and the encoding. The page is served from a kept build
// (default: the newest folder of homework/Files/builds with a web/ folder), the browser is started through the guarded launcher (below-normal priority, a CPU cap, a time limit, this session's name in its profile),
// the hook steps the match one tick at a time and a picture is taken at the ticks the recipe wants. The pictures are cropped and encoded by encode.py (Pillow): GIF under a size limit with one palette, a PNG
// sequence, or WebM through the browser's own recorder (no encoder to install). Output: homework/Files/clips/<build folder>/, with index.txt: one line a clip. Event windows (launch, crater, building_fall, ko,
// catch, beam_clash_end ...) are found from the sim's own events, which the hook logs each tick; no picture is looked at.
import { mkdirSync, writeFileSync, readFileSync, readdirSync, existsSync, rmSync, appendFileSync, copyFileSync, statSync, mkdtempSync } from 'node:fs';
import { join, resolve, dirname, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { tmpdir } from 'node:os';
import { spawnSync } from 'node:child_process';
import { Cdp, launchBrowser, serve, browserExe } from '../machine/browser.mjs';
import { createRequire } from 'node:module';
import { analyseGif } from '../flash/analyse-gif.mjs';
const FLASH_V = createRequire(import.meta.url)('../flash/verdict.js');

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(HERE, '..', '..');
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const log = (m) => console.log(`[clips] ${m}`);

export function loadRecipes(file = join(HERE, 'clips.json')) {
  const j = JSON.parse(readFileSync(file, 'utf8'));
  const clips = {};
  for (const [name, r] of Object.entries(j.clips)) clips[name] = { name, ...j.defaults, ...r };
  return { defaults: j.defaults, events: j.events, bookmarks: j.bookmarks, clips };
}

/** The kept build to serve: an explicit path or part of a folder name, else the newest kept folder with a web/ page. */
export function resolveBuild(want, buildsDir = join(ROOT, 'homework', 'Files', 'builds')) {
  if (want && existsSync(want) && statSync(want).isDirectory()) {
    const web = existsSync(join(want, 'web', 'index.html')) ? join(want, 'web') : want;
    return { dir: resolve(want), web: resolve(web), name: basename(resolve(want)) };
  }
  const all = readdirSync(buildsDir, { withFileTypes: true }).filter((e) => e.isDirectory() && existsSync(join(buildsDir, e.name, 'web', 'index.html')) && !e.name.startsWith('orb-lan'));
  const pick = want ? all.filter((e) => e.name.includes(want)) : all.sort((a, b) => statSync(join(buildsDir, b.name)).mtimeMs - statSync(join(buildsDir, a.name)).mtimeMs);
  if (!pick.length) throw new Error(want ? `no kept build matches "${want}" in ${buildsDir}` : `no kept build in ${buildsDir}`);
  const e = pick[0];
  return { dir: join(buildsDir, e.name), web: join(buildsDir, e.name, 'web'), name: e.name };
}

function pythonCmd() {
  for (const c of [['python'], ['python3'], ['py', '-3']]) {
    const r = spawnSync(c[0], [...c.slice(1), '--version'], { encoding: 'utf8', timeout: 30000 });
    if (r.status === 0) return c;
  }
  throw new Error('no python on this PC (Pillow is the clip encoder): install nothing, ask Tools');
}

function encode(framesDir, out, r, format) {   // r.stripFile: the button strip's states (writeStrip), drawn under the picture by encode.py
  const py = pythonCmd();
  const args = [...py.slice(1), join(HERE, 'encode.py'), '--in', framesDir, '--out', out, '--format', format === 'webm' ? 'frames' : format, '--width', String(r.width), '--fps', String(r.fps), '--maxkb', String(r.maxkb), '--blur', String(r.blur || 0), '--tol', String(r.tol || 0)];
  if (r.crop && r.crop.join() !== '0,0,0,0') args.push('--crop', r.crop.join(','));
  if (r.stripFile) args.push('--strip', r.stripFile);
  let p = spawnSync(py[0], args, { encoding: 'utf8', timeout: 240000 });
  if (p.error) p = spawnSync(py[0], args, { encoding: 'utf8', timeout: 240000 });   // a child that did not answer in four minutes is asked once more
  if (p.status !== 0) throw new Error(`encode.py failed: ${(p.stdout || '') + (p.stderr || '')}`.slice(0, 400));
  return JSON.parse(p.stdout.trim().split('\n').pop());
}

// ---------------------------------------------------------------- the button strip
// The hook logs what each of the first two fighters was fed every tick: [tick, slot, stick x * 100, stick y * 100, flags, rsDir, rsLevel, stanceMask] (render/tools/flash_capture.gd _pad_rows). The strip turns that into one state per picture:
// which controls are lit (down at the picture, or pressed since the last one) and a word for each: tap, hold (12 ticks or more) or mash (three presses in 30 ticks). It is drawn by encode.py in a band under the picture, never over it.
const PAD_BIT = { light: 0, heavy: 1, sig: 2, dodge: 3, guardPress: 4, lightHeld: 5, heavyHeld: 6, sigHeld: 7, rsHeld: 8, rsStart: 9, guard: 10, sprint: 11, power: 12, context: 13, contextHeld: 14, special: 15, powerPress: 16, transform: 17 };
const pbit = (r, n) => ((r[4] >> PAD_BIT[n]) & 1) === 1;
const MASK = (r, m) => (r[7] & m) !== 0;
export const PAD_CONTROLS = {
  X: { down: (r) => pbit(r, 'lightHeld') || pbit(r, 'light'), edge: (r) => pbit(r, 'light') },
  Y: { down: (r) => pbit(r, 'heavyHeld') || pbit(r, 'heavy'), edge: (r) => pbit(r, 'heavy') },
  B: { down: (r) => pbit(r, 'sigHeld') || pbit(r, 'sig'), edge: (r) => pbit(r, 'sig') },
  A: { down: (r) => pbit(r, 'contextHeld') || pbit(r, 'context'), edge: (r) => pbit(r, 'context') },
  LT: { down: (r) => MASK(r, 8) || pbit(r, 'sprint'), edge: (r) => pbit(r, 'dodge') },
  LB: { down: (r) => MASK(r, 1) || pbit(r, 'guard'), edge: (r) => pbit(r, 'guardPress') },
  RB: { down: (r) => MASK(r, 2), edge: () => false },
  RT: { down: (r) => MASK(r, 4) || pbit(r, 'power'), edge: (r) => pbit(r, 'powerPress') },
  RS: { down: (r) => pbit(r, 'rsHeld'), edge: (r) => pbit(r, 'rsStart') },
};

/** One strip state per tick of `ticks` for the pad of `slot`, from the logged rows. */
export function stripStates(rows, ticks, slot, step) {
  const by = new Map();
  for (const r of rows || []) if (r[1] === slot) by.set(r[0], r);
  const upTo = (c, t) => { const r = by.get(t); return r ? c.down(r) : false; };
  const edgeAt = (c, t) => { const r = by.get(t); return !!r && (c.edge(r) || (c.down(r) && !upTo(c, t - 1))); };
  const word = (c, t) => {
    let lit = false;
    for (let u = t - step + 1; u <= t; u++) if (upTo(c, u) || edgeAt(c, u)) { lit = true; break; }
    if (!lit) return null;
    let presses = 0; for (let u = t - 29; u <= t; u++) if (edgeAt(c, u)) presses++;
    let hold = 0; for (let u = t; upTo(c, u); u--) hold++;
    return presses >= 3 ? 'mash' : hold >= 12 ? 'hold' : 'tap';
  };
  return ticks.map((t) => {
    const st = {}, r = by.get(t);
    st.LS = r ? [r[2] / 100, r[3] / 100] : [0, 0];
    for (const k of Object.keys(PAD_CONTROLS)) st[k] = word(PAD_CONTROLS[k], t);
    let dir = 0, level = 0;
    for (let u = t - step + 1; u <= t; u++) { const q = by.get(u); if (q) { if (q[5]) dir = q[5]; level = Math.max(level, q[6] || 0); } }
    st.RS = { dir, level, g: st.RS };
    return st;
  });
}

/** Writes <dir>/strip.json (one state per picture in the folder, in file order) and returns its path; null when the hook logged no pad rows (an older build). */
export function writeStrip(dir, rows, slot, step) {
  if (!rows || !rows.length) return null;
  const ticks = readdirSync(dir).filter((n) => /^t-\d+\.jpg$/.test(n)).sort().map((n) => Number(/^t-(\d+)/.exec(n)[1]));
  const file = join(dir, 'strip.json');
  writeFileSync(file, JSON.stringify({ frames: stripStates(rows, ticks, slot, step) }));
  return file;
}

const trace = (m) => { if (process.env.CLIPS_TRACE) console.error(`[trace ${new Date().toISOString().slice(11, 19)}] ${m}`); };

/** The flash check of a GIF, run in this process: a child `node tools/flash/analyse-gif.mjs` hung for good about three calls in four on this machine (2026-11-07: it is stuck before it runs anything, with half a second of CPU and no way to attach to it), and a hung child holds a synchronous call for ever. */
function flashVerdict(gif) {
  try {
    const a = analyseGif(gif);
    const m = /(PASS|OVER GATE|FAIL)/.exec(FLASH_V.columns(a.result));
    return m ? m[1] : (a.result.pass ? 'PASS' : 'FAIL');
  } catch { return 'CHECK'; }
}

/** Which of the hook's logged events [tick, type, kind, x] is the recipe's event: an alias of clips.json or `type` or `type:kind`. */
export function eventMatcher(name, aliases) {
  const a = aliases[name] || String(name).split(':');
  return (e) => e[1] === a[0] && (a.length < 2 || e[2] === a[1]);
}

/** One scene run on an open hook page: steps the match tick by tick, takes pictures where the requests ask, returns when every request is done. A request: { name, dir, from, frames, step } or { name, dir, event: { name, nth, before, after }, step }. */
async function runScene(page, { scene, seed, W, H, requests, aliases, maxTicks, onStep }) {
  await page.eval(`window.__flashcap.start(${JSON.stringify(scene)}, { reduced: false, seed: ${Number(seed)} })`, true);
  const seen = [];   // every logged event, [tick, type, kind, x]; seen.pad: the pad rows of the button strip
  const padRows = []; seen.pad = padRows;
  for (const q of requests) { mkdirSync(q.dir, { recursive: true }); q.done = false; q.taken = []; q.hits = 0; q.te = -1; if (q.event) q.match = eventMatcher(q.event.name, aliases); else q.last = q.from + (q.frames - 1) * q.step; }
  let first = true;
  for (let i = 1; i <= maxTicks; i++) {
    const got = await page.eval('window.__flashcap.step().then((t) => ({ tick: t, ev: (window.__flashcap.events || []).splice(0), pad: (window.__flashcap.pad || []).splice(0), noev: !window.__flashcap.events, err: window.__flashcap.error || null }))', true);
    if (first && got.noev && requests.some((q) => q.event)) throw new Error("this build's hook does not log the sim's events (an older hook: an event window needs a build made after 2026-11-06); use a tick window (from, frames) instead");
    if (first) { first = false; if (got.err && /no scenario/.test(got.err)) throw new Error(`this build's hook has no scene "${scene}" (${got.err.slice(0, 80)})`); }
    else if (got.err && !/no scenario/.test(got.err)) throw new Error(`the page reported an error: ${got.err}`);
    const t = got.tick;
    for (const r of got.pad || []) padRows.push(r);
    for (const e of got.ev || []) { seen.push(e); for (const q of requests) if (q.event && !q.done && q.te < 0 && q.match(e) && ++q.hits === (q.event.nth || 1)) q.te = e[0]; }
    let need = false;
    for (const q of requests) {
      if (q.done) continue;
      if (q.event) {
        if (t % q.step === 0 && (q.te < 0 || t <= q.te + q.event.after)) need = true;
        if (q.te >= 0 && t >= q.te + q.event.after) q.done = true;
      } else {
        if (t >= q.from && t <= q.last && (t - q.from) % q.step === 0) need = true;
        if (t >= q.last) q.done = true;
      }
    }
    if (need) {
      const shot = await page.send('Page.captureScreenshot', { format: 'jpeg', quality: 88, fromSurface: true, clip: { x: 0, y: 0, width: W, height: H, scale: 1 } });
      const buf = Buffer.from(shot.data, 'base64');
      for (const q of requests) {
        const wants = q.event ? (t % q.step === 0 && (q.te < 0 || t <= q.te + q.event.after)) : (t >= q.from && t <= q.last && (t - q.from) % q.step === 0);
        if (wants && !q.taken.includes(t)) { writeFileSync(join(q.dir, `t-${String(t).padStart(6, '0')}.jpg`), buf); q.taken.push(t); }
      }
    }
    if (onStep) onStep(t);
    if (requests.every((q) => q.done)) break;
  }
  for (const q of requests) {
    if (q.event) {   // the window around the event: the frames of the ring that lie inside it
      if (q.te < 0) { q.error = `the event "${q.event.name}" #${q.event.nth || 1} did not happen in ${maxTicks} ticks (the scene saw: ${[...new Set(seen.map((e) => e[1] + (e[2] ? ':' + e[2] : '')))].slice(0, 12).join(', ') || 'no events'})`; continue; }
      const lo = q.te - q.event.before, hi = q.te + q.event.after;
      for (const t of q.taken) if (t < lo || t > hi) rmSync(join(q.dir, `t-${String(t).padStart(6, '0')}.jpg`), { force: true });
      q.from = lo; q.upto = hi;
    } else if (!q.taken.length || q.taken[q.taken.length - 1] < q.last) q.error = `the match ended or stopped before tick ${q.last} (pictures up to ${q.taken[q.taken.length - 1] || 'none'})`;
  }
  return seen;
}

async function openPage(web, words, W, H, limitS, extra = {}) {
  const server = await serve(resolve(web));
  const exe = browserExe('chrome');
  if (!exe) throw new Error('no Chrome found for the guarded launcher');
  const browser = await launchBrowser({ exe, flags: [`--window-size=${W},${H}`, '--disable-renderer-backgrounding', '--disable-background-timer-throttling', '--disable-backgrounding-occluded-windows', '--disable-features=CalculateNativeWinOcclusion'], session: process.env.MERIDIAN_SESSION || 'tools-pipeline', purpose: 'clip kit', timeoutS: limitS, cpuPercent: 25, log });
  const page = await Cdp.open(browser.target.webSocketDebuggerUrl);
  await page.send('Page.enable'); await page.send('Runtime.enable');
  await page.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
  if (extra.script) await page.send('Page.addScriptToEvaluateOnNewDocument', { source: extra.script });
  const url = `http://127.0.0.1:${server.address().port}/index.html?flashcap=1${extra.replay ? '&replay=1&blackbox=off' : ''}${words ? '&' + words : ''}`;
  await page.send('Page.navigate', { url });
  const deadline = Date.now() + 900 * 1000;
  let ready = false;
  while (Date.now() < deadline && !ready) { await sleep(500); ready = await page.eval('Boolean(window.__flashcap && window.__flashcap.ready)').catch(() => false); }
  if (!ready) throw new Error('the page offers no window.__flashcap that becomes ready (is it an export with the capture hook?)');
  return { server, browser, page, url };
}

async function toWebm(page, preparedDir, r, out) {
  const names = readdirSync(preparedDir).filter((n) => n.endsWith('.jpg')).sort();
  writeFileSync(join(preparedDir, 'frames.json'), JSON.stringify({ fps: r.fps, frames: names }));
  copyFileSync(join(HERE, 'webm.html'), join(preparedDir, 'webm.html'));
  const server = await serve(resolve(preparedDir));
  try {
    await page.send('Page.navigate', { url: `http://127.0.0.1:${server.address().port}/webm.html` });
    const deadline = Date.now() + (names.length / r.fps + 60) * 1000;
    let done = false;
    while (Date.now() < deadline && !done) { await sleep(500); done = await page.eval('Boolean(window.__webmDone)').catch(() => false); }
    const err = await page.eval('window.__webmError || null').catch(() => null);
    if (!done || err) throw new Error(`the browser's recorder did not finish: ${err || 'timed out'}`);
    const b64 = await page.eval('window.__webm');
    writeFileSync(out, Buffer.from(b64, 'base64'));
  } finally { server.close(); }
  return { file: out, kb: Math.round(statSync(out).size / 1024), frames: names.length, seconds: Math.round((names.length / r.fps) * 10) / 10 };
}

function indexLine(outDir, name, info, r, extra = '') {
  const line = `${name} | ${basename(info.file)} | ${info.kb ?? '?'} KB | ${info.frames ?? '?'} frames | ${info.seconds ?? '?'} s | ${r.scene || r.mockup || 'match'} seed ${r.seed ?? '-'} ${r.from !== undefined ? 'ticks ' + r.from + '-' + (r.upto ?? '') : ''}${extra}`;
  appendFileSync(join(outDir, 'index.txt'), line + '\n');
  log(line);
}

/** make.mjs's work, callable by the self-test. opts: { names, build, format, out, limit, keepFrames, dry } */
export async function make(opts) {
  const R = loadRecipes();
  const names = opts.names.includes('all') ? Object.keys(R.clips).filter((n) => n !== 'selftest' && !R.clips[n].event && !R.clips[n].pending) : opts.names;
  for (const n of names) if (!R.clips[n]) throw new Error(`no recipe "${n}" in tools/clips/clips.json (node tools/clips/make.mjs --list)`);
  for (const n of names) if (R.clips[n].pending) throw new Error(`the slot "${n}" is not filled yet: ${R.clips[n].pending === true ? R.clips[n].needs || 'the move has not landed' : R.clips[n].pending} (when the move lands, give it a scene and words and remove pending)`);
  const b = resolveBuild(opts.build);
  const outDir = resolve(opts.out || join(ROOT, 'homework', 'Files', 'clips', b.name));
  log(`build ${b.name}; clips to ${outDir}`);
  if (opts.dry) { for (const n of names) log(`would make ${n}: ${JSON.stringify(R.clips[n])}`); return []; }
  mkdirSync(outDir, { recursive: true });
  const work = mkdtempSync(join(tmpdir(), 'meridian-clips-'));
  const results = [];
  const mockups = names.filter((n) => R.clips[n].mockup), scenes = names.filter((n) => !R.clips[n].mockup);
  for (const n of mockups) {
    const r = R.clips[n], fr = join(work, n);
    const py = pythonCmd();
    const p = spawnSync(py[0], [...py.slice(1), join(HERE, 'mockups', r.mockup), '--out', fr, ...(r.args || [])], { encoding: 'utf8' });
    if (p.status !== 0) { results.push({ name: n, error: (p.stderr || p.stdout).slice(0, 300) }); log(`${n}: FAILED ${(p.stderr || '').slice(-200)}`); continue; }
    const format = opts.format || r.format;
    if (format === 'webm') { results.push({ name: n, error: 'a mockup is made as a GIF or a PNG sequence (WebM needs the browser page; pass --format gif)' }); continue; }
    const file = join(outDir, format === 'gif' ? `${n}.gif` : n);
    const info = encode(fr, file, { ...r, crop: [0, 0, 0, 0] }, format);
    info.file = file; if (format === 'gif') info.flash = flashVerdict(file);
    indexLine(outDir, n, info, r, info.flash ? ` | flash ${info.flash}` : ''); results.push({ name: n, ...info });
  }
  if (scenes.length) {
    // one page for the recipes that share words and picture size; the scene of each is started on it
    const groups = new Map();
    for (const n of scenes) { const r = R.clips[n]; const k = `${r.words}|${r.size.join('x')}`; (groups.get(k) || groups.set(k, []).get(k)).push(n); }
    let lastPage = null;
    try {
      for (const [k, group] of groups) {
        const r0 = R.clips[group[0]], [W, H] = r0.size;
        const op = await openPage(b.web, r0.words, W, H, opts.limit || 1500);
        lastPage = op;
        const webmJobs = [];
        for (const n of group) {
          const r = R.clips[n], fr = join(work, n);
          const req = { name: n, dir: fr, from: r.from, frames: r.frames, step: r.step, event: r.event ? { ...r.event, nth: r.event.nth || 1 } : null };
          try {
            const seen = await runScene(op.page, { scene: r.scene, seed: r.seed, W, H, requests: [req], aliases: R.events, maxTicks: r.maxTicks || 4000 });
            if (req.error) throw new Error(req.error);
            if (opts.strip !== false && r.strip !== false) r.stripFile = writeStrip(fr, seen.pad, r.stripSlot || 0, r.step);
            r.from = req.from; r.upto = req.event ? req.upto : req.last;
            const format = opts.format || r.format;
            const file = join(outDir, format === 'gif' ? `${n}.gif` : n);
            let info;
            if (format === 'webm') { const prep = join(work, n + '-prep'); encode(fr, prep, r, 'webm'); webmJobs.push({ n, r, prep }); continue; }   // the recorder page replaces the hook page: all WebM jobs run after the last scene of the group
            info = encode(fr, file, r, format); info.file = file; info.strip = !!r.stripFile; if (format === 'gif') info.flash = flashVerdict(file);
            indexLine(outDir, n, info, r, info.flash ? ` | flash ${info.flash}` : ''); results.push({ name: n, ...info });
          } catch (e) { log(`${n}: FAILED ${e.message}`); results.push({ name: n, error: e.message }); appendFileSync(join(outDir, 'index.txt'), `${n} | FAILED | ${e.message}\n`); }
        }
        for (const j of webmJobs) {
          try { const info = await toWebm(op.page, j.prep, j.r, join(outDir, `${j.n}.webm`)); indexLine(outDir, j.n, info, j.r); results.push({ name: j.n, ...info }); }
          catch (e) { log(`${j.n}: FAILED ${e.message}`); results.push({ name: j.n, error: e.message }); appendFileSync(join(outDir, 'index.txt'), `${j.n} | FAILED | ${e.message}
`); }
        }
        trace('closing the page');
        try { op.page.close(); } catch { /* gone */ }
        try { await op.browser.close(); } catch { /* gone */ }
        trace('browser closed');
        op.server.close();
        lastPage = null;
      }
    } finally {
      if (lastPage) { try { lastPage.page.close(); } catch { /* gone */ } try { await lastPage.browser.close(); } catch { /* gone */ } lastPage.server.close(); }
    }
  }
  trace('removing the work folder');
  if (!opts.keepFrames) rmSync(work, { recursive: true, force: true });
  trace('done');
  return results;
}

/** Every mark and bookmark of a saved match, rendered through the replay in one pass: the match is played once and a window is cut for each. */
export async function fromMatch(opts) {
  const R = loadRecipes();
  const doc = JSON.parse(readFileSync(opts.fromMatch, 'utf8'));
  const rp = doc.replay || doc;
  const marks = Array.isArray(doc.marks) ? doc.marks : [];
  if (!marks.length) throw new Error('the match file has no marks or bookmarks (it was saved by a page without the clip button)');
  const key = doc.build && (doc.build.stackKey || doc.build.commit) ? String(doc.build.stackKey || doc.build.commit).slice(0, 8) : '';
  let build;
  if (opts.build) build = resolveBuild(opts.build);
  else { try { build = key ? resolveBuild(key) : resolveBuild(); } catch { build = resolveBuild(); log(`no kept build with the key ${key}: using ${build.name} (the replay needs the build it was played on: a different one will refuse it)`); } }
  const outDir = resolve(opts.out || join(ROOT, 'homework', 'Files', 'clips', build.name));
  mkdirSync(outDir, { recursive: true });
  const base = basename(opts.fromMatch).replace(/\.json$/, '');
  const [W, H] = R.defaults.size;
  const work = mkdtempSync(join(tmpdir(), 'meridian-clips-'));
  const requests = marks.map((m, i) => {
    const w = R.bookmarks[m.kind] || R.bookmarks.clip;
    const lo = Math.max(1, m.tick - (m.before || w.before)), hi = m.tick + (w.after || 0);
    const step = w.step || R.defaults.step;
    return { name: `${base}-${String(i + 1).padStart(2, '0')}-${m.kind}-t${m.tick}`, dir: join(work, String(i)), from: lo + ((step - (lo % step)) % step), frames: 0, step, last: hi, fmt: opts.format || w.format || 'gif' };
  });
  for (const q of requests) q.frames = Math.max(1, Math.floor((q.last - q.from) / q.step) + 1);
  const words = String(doc.pageSearch || '').replace(/^\?/, '').split('&').filter((w) => w && !/^(go|blackbox|script|replay|flashcap|preview|reel|sticks|peak|tier)=/.test(w)).concat(['nohud=1']).join('&');
  const op = await openPage(build.web, words, W, H, opts.limit || 3600, { replay: true, script: `window.__replay = ${JSON.stringify(JSON.stringify(rp))};` });
  const results = [];
  const padCount = {}; for (const i of rp.inputs || []) padCount[i[1]] = (padCount[i[1]] || 0) + 1;
  const padSlot = Number(Object.entries(padCount).sort((a, b) => b[1] - a[1])[0]?.[0] ?? 0);   // the pad is the slot with most recorded inputs
  try {
    const maxT = Math.min(Number(rp.ticks) || 20000, Math.max(...requests.map((q) => q.last)));
    const seen = await runScene(op.page, { scene: 'ai', seed: Number(rp.seed), W, H, requests, aliases: R.events, maxTicks: maxT, onStep: (t) => { if (t % 1200 === 0) log(`replay tick ${t} of ${maxT}`); } });
    const cp = JSON.parse(await op.page.eval('JSON.stringify(window.__pr_cp || [])') || '[]'), want = new Map((rp.checkpoints || []).map((c) => [Number(c[0]), String(c[1])]));
    let bad = -1, compared = 0; for (const [t, h] of cp) { if (!want.has(t)) continue; compared++; if (want.get(t) !== h && bad < 0) bad = t; }
    log(compared ? (bad < 0 ? `the replay is the match that was played (${compared} checkpoints equal)` : `THE REPLAY DIFFERS from tick ${bad}: the build is not the one the match was played on`) : 'no checkpoint to compare');
    const webmJobs = [];
    for (const q of requests) {
      if (q.error) { results.push({ name: q.name, error: q.error }); appendFileSync(join(outDir, 'index.txt'), `${q.name} | FAILED | ${q.error}\n`); continue; }
      const r = { ...R.defaults, fps: 12, step: q.step, width: 480, maxkb: 560, scene: 'match', seed: rp.seed, from: q.from, upto: q.last };
      if (opts.strip !== false) r.stripFile = writeStrip(q.dir, seen.pad, padSlot, q.step);
      if (q.fmt === 'webm') {
        const rr = { ...r, fps: Math.round(60 / q.step) }, prep = join(work, q.name + '-prep'); encode(q.dir, prep, rr, 'webm'); webmJobs.push({ name: q.name, rr, prep });
      } else {
        const file = join(outDir, q.fmt === 'gif' ? `${q.name}.gif` : q.name), info = encode(q.dir, file, r, q.fmt); info.file = file; if (q.fmt === 'gif') info.flash = flashVerdict(file);
        indexLine(outDir, q.name, info, r, info.flash ? ` | flash ${info.flash}` : ''); results.push({ name: q.name, ...info });
      }
    }
    for (const j of webmJobs) { const info = await toWebm(op.page, j.prep, j.rr, join(outDir, `${j.name}.webm`)); indexLine(outDir, j.name, info, j.rr); results.push({ name: j.name, ...info }); }
  } finally { try { op.page.close(); } catch { /* gone */ } try { await op.browser.close(); } catch { /* gone */ } op.server.close(); if (!opts.keepFrames) rmSync(work, { recursive: true, force: true }); }
  return results;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const argv = process.argv.slice(2);
  const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
  const flags = new Set(['--keep-frames', '--dry', '--list', '--no-strip']);
  const names = []; for (let i = 0; i < argv.length; i++) { if (argv[i].startsWith('--')) { if (!flags.has(argv[i])) i++; } else names.push(argv[i]); }
  try {
    if (argv.includes('--list')) { const R = loadRecipes(); for (const [n, r] of Object.entries(R.clips)) console.log(`${n.padEnd(36)} ${r.mockup ? 'mockup' : r.event ? 'event ' : 'window'}  ${r.desc || ''}${r.pending ? `  [SLOT, not filled: ${r.pending === true ? r.needs || '' : r.pending}]` : r.needs ? `  [needs ${r.needs}]` : ''}`); process.exit(0); }
    const common = { build: opt('--build'), format: opt('--format'), out: opt('--out'), limit: Number(opt('--limit', 0)) || 0, keepFrames: argv.includes('--keep-frames'), strip: argv.includes('--no-strip') ? false : undefined };
    let res;
    if (opt('--from-match')) res = await fromMatch({ ...common, fromMatch: opt('--from-match') });
    else if (names.length) res = await make({ ...common, names, dry: argv.includes('--dry') });
    else { console.error('usage: node tools/clips/make.mjs <name|all> [--build <kept folder>] [--format gif|png|webm]  |  --from-match <saved match.json>  |  --list'); process.exit(2); }
    const failed = res.filter((x) => x.error);
    log(`${res.length - failed.length} clip(s) made${failed.length ? `, ${failed.length} failed` : ''}`);
    process.exit(failed.length ? 1 : 0);
  } catch (e) { console.error(`[clips] FAILED: ${e.message}`); process.exit(1); }
}
