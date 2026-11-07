// A reel of a real AI match on the stack page (the EP, 2026-10-31: "I can't watch the page: my pane is hidden and its rAF stalls"): the page's build is stepped one tick a frame through Tools' guarded
// launcher (the flash capture hook, ?flashcap=1, as tools/flash/capture-web.mjs does it), a still every 30 ticks, and the page's own state probe (?preview=1&reel=1) is read after every step, so each still says
// what the swing is doing and why. Private: the output is a folder of contact sheets and a record, never published. Node 24 built-ins only.
//
//   node tools/preview/reel.mjs --dir <built web folder> --out <folder> [--seed 12345] [--every 30] [--swings 2] [--launches 1] [--cap 6000] [--margin 60] [--width 960 --height 540] [--planet 7] [--query "meteor=loud&tiles=1"] [--sticks | --sticks2 | --sticks3 (a player who moves)]
//
// It plays the hook's `ai` scenario (a real AI match) on the page's planet until it has seen --swings complete swings and --launches launch(es), then --margin more ticks, or --cap ticks. Stills are kept for the
// ticks within --margin of a swing or a launch. Output: <out>/sheet-1.png ... (contact sheets of 12, the corner of each still reading the tick, the swing's state, rate, degrees left and cause, and the fighters'
// states), <out>/reel.json (every swing and launch with its ticks, the picture list, the page's build), <out>/stills/ (the individual JPEGs).
import { mkdirSync, writeFileSync, rmSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { Cdp, launchBrowser, serve, browserExe } from '../machine/browser.mjs';
import { createRequire } from 'node:module';
const { decodePng } = createRequire(import.meta.url)('../flash/wcag.js');

/** The share of the frame (0 to 1) filled by the largest connected region of nearly one colour that is not blue-dominant. rgba: Uint8 of w*h*4. Colours are bucketed to 12 levels a channel and a region is a 4-connected flood of one bucket. */
export function flatFaceShare(w, h, rgba) {
  const n = w * h, key = new Int32Array(n);
  for (let i = 0; i < n; i++) { const p = i * 4; key[i] = ((rgba[p] / 21) | 0) * 144 + ((rgba[p + 1] / 21) | 0) * 12 + ((rgba[p + 2] / 21) | 0); }
  const seen = new Uint8Array(n), stack = new Int32Array(n);
  let best = 0;
  for (let s = 0; s < n; s++) {
    if (seen[s]) continue;
    let sp = 0, size = 0, r = 0, g = 0, b = 0;
    stack[sp++] = s; seen[s] = 1;
    const k = key[s];
    while (sp) {
      const i = stack[--sp]; size++; const p = i * 4; r += rgba[p]; g += rgba[p + 1]; b += rgba[p + 2];
      const x = i % w, y = (i / w) | 0;
      if (x > 0 && !seen[i - 1] && key[i - 1] === k) { seen[i - 1] = 1; stack[sp++] = i - 1; }
      if (x < w - 1 && !seen[i + 1] && key[i + 1] === k) { seen[i + 1] = 1; stack[sp++] = i + 1; }
      if (y > 0 && !seen[i - w] && key[i - w] === k) { seen[i - w] = 1; stack[sp++] = i - w; }
      if (y < h - 1 && !seen[i + w] && key[i + w] === k) { seen[i + w] = 1; stack[sp++] = i + w; }
    }
    if (size > best * n && (b / size) <= (r / size) + 8) best = size / n;   // not blue-dominant: the sky and the sea are left out
  }
  return best;
}


const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const DIR = opt('--dir'), OUT = opt('--out');
if (!DIR || !OUT) { console.error('usage: node tools/preview/reel.mjs --dir <built web folder> --out <folder> [--seed N] [--every 30] [--swings 2] [--launches 1] [--cap 6000] [--margin 60]'); process.exit(2); }
const SCEN = String(opt('--scenario', 'ai')).replace(/[^a-z]/g, '');   // the hook's scene: ai (a real AI match), collapse (AI against AI beside the tallest tower, a blast through a row of buildings every 150 ticks), launchai ...
const SEED = Number(opt('--seed', 12345)), EVERY = Number(opt('--every', 30)), NSWING = Number(opt('--swings', 2)), NLAUNCH = Number(opt('--launches', 1));
const HOLD = new Set(String(opt('--hold', '')).split(',').filter(Boolean).map(Number)), HOLD_FOR = Number(opt('--hold-for', 60)), HOLD_EVERY = Math.max(1, Number(opt('--hold-every', 6)));   // pause on a view: the sim is not stepped, a still every HOLD_EVERY s for HOLD_FOR s
let lastTeach = '';
const ALSO = new Set(String(opt('--also', '')).split(',').filter(Boolean).map(Number));   // extra ticks to take a still at (the EP names a tick)
const CAP = Number(opt('--cap', 6000)), MARGIN = Number(opt('--margin', 60));
const W = Number(opt('--width', 960)), H = Number(opt('--height', 540)), PLANET = Number(opt('--planet', 7));
const QUERY = `${opt('--query', 'meteor=loud&tiles=1')}${argv.includes('--sticks8') ? '&sticks=8' : argv.includes('--sticks7') ? '&sticks=7' : argv.includes('--sticks6') ? '&sticks=6' : argv.includes('--sticks5') ? '&sticks=5' : argv.includes('--sticks4') ? '&sticks=4' : argv.includes('--sticks3') ? '&sticks=3' : argv.includes('--sticks2') ? '&sticks=2' : argv.includes('--sticks') ? '&sticks=1' : ''}`;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const log = (m) => console.log(`[reel] ${m}`);
const exe = browserExe('chrome');
if (!exe) { console.error('no chrome found'); process.exit(2); }

mkdirSync(join(OUT, 'stills'), { recursive: true });
const server = await serve(resolve(DIR));
const url = `http://127.0.0.1:${server.address().port}/index.html?flashcap=1&preview=1&reel=1${argv.includes('--no-planet') ? '' : `&planet=${PLANET}`}&${QUERY}`;   // --no-planet: the hand-made world (the old default arena), where the hill chapel stands
let browser = null, page = null, code = 0;
const record = { url, seed: SEED, every: EVERY, swings: [], launches: [], pictures: [], ticks: 0, planetGen: null, note: '' };
try {
  browser = await launchBrowser({ exe, flags: [`--window-size=${W},${H}`], session: process.env.MERIDIAN_SESSION || 'tools-pipeline', purpose: 'reel', timeoutS: Number(opt('--limit', 1500)), cpuPercent: 25, log });
  page = await Cdp.open(browser.target.webSocketDebuggerUrl);
  await page.send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
  await page.send('Runtime.enable'); await page.send('Log.enable');
  record.errors = [];
  page.ws.addEventListener('message', (ev) => { try { const m = JSON.parse(ev.data); let line = null; if (m.method === 'Runtime.exceptionThrown') line = 'exception: ' + (m.params.exceptionDetails.exception?.description || m.params.exceptionDetails.text); else if (m.method === 'Runtime.consoleAPICalled' && m.params.type === 'error') line = 'console.error: ' + m.params.args.map((a) => a.value ?? a.description ?? '').join(' '); else if (m.method === 'Log.entryAdded' && m.params.entry.level === 'error') line = 'log.error: ' + m.params.entry.text; if (line && /Failed to load resource.*404|manifest.webmanifest|favicon/.test(line)) { record.benign = (record.benign || 0) + 1; line = null; }
      if (line && record.errors.length < 60 && !record.errors.some((e) => e.line === line.slice(0, 400))) record.errors.push({ at: new Date().toISOString().slice(11, 19), tick: record.curTick || 0, line: line.slice(0, 400) }); } catch { /* not ours */ } });
  await page.send('Page.navigate', { url });
  const deadline = Date.now() + 900 * 1000;
  let ready = false;
  while (Date.now() < deadline && !ready) { await sleep(500); ready = await page.eval('Boolean(window.__flashcap && window.__flashcap.ready)').catch(() => false); }
  if (!ready) throw new Error('the page offers no window.__flashcap that becomes ready (is it an export with the capture hook, and ?flashcap=1 allowed?)');
  await page.eval(`window.__flashcap.start("${SCEN}", { reduced: false, seed: ${SEED} })`, true);
  log(`${url}: the hook's ai scenario, seed ${SEED}, ${W}x${H}, until ${NSWING} swing(s) and ${NLAUNCH} launch(es) have been seen`);
  let last = -1, curSwing = null, lastLn = [0, 0], doneAt = -1;
  const KEEP_ALL = argv.includes('--keep-all'), REMATCH = argv.includes('--rematch');
  let base = 0, rawPrev = 0, matchNo = 0, koSince = -1, matchStart = 0, loopDeadline = Date.now() + Number(opt('--limit', 1500)) * 1000;
  record.matches = [];
  const wall = { run: [0, 0], max: [0, 0], total: [0, 0], maxAt: [0, 0] }, wallAll = { run: [0, 0], max: [0, 0], total: [0, 0], maxAt: [0, 0] };   // ticks a fighter has been behind a building (PaneWorld.occluded): the run now, the longest, the sum
  let prevLum = null;
  const AFTER_REF = Number(opt('--after-refused', 0)), AFTER_MAX = Number(opt('--after-max', 2));
  const AFTER_WORDS = new Set(String(opt('--after-words', '')).split(',').map((x) => x.trim()).filter(Boolean));
  let refSeen = 0, refUntil = -1, lastWord = '';
  const shots = new Map();   // tick -> { file, pv }
  for (let i = 1; i <= CAP; i++) {
    if (Date.now() > loopDeadline) throw new Error(`timed out after ${i - 1} ticks`);
    const got = await page.eval('window.__flashcap.step().then((t) => ({ tick: t, err: window.__flashcap.error || null, pv: window.__preview || null }))', true);
    if (got && got.err) throw new Error(`the page reported an error: ${got.err}`);
    const raw = got && got.tick;
    if (typeof raw !== 'number' || raw <= rawPrev) throw new Error(`step() returned ${raw} after ${rawPrev}`);
    rawPrev = raw;
    const tick = base + raw;
    last = tick;
    record.curTick = tick;
    const pv = got.pv;
    if (REMATCH && pv) {   // a match that is over (KO), or one that will not end in two minutes, is followed by the next: ten minutes of play are one run
      if (pv.ko && koSince < 0) koSince = tick;
      const endedKo = koSince >= 0 && tick - koSince >= 300, stuck = tick - matchStart >= 7200;
      if (endedKo || stuck) {
        const bbNow = await page.eval('JSON.stringify({ q: (window.__bb_q || []).map((e) => ({ over: e.over, ended: e.ended, ticks: e.ticks })), s: window.__bb_state || null })').catch(() => null);
        record.matches.push({ n: matchNo, seed: SEED + matchNo, from: matchStart, to: tick, ended: endedKo ? 'KO' : 'did not end in 7200 ticks', blackBox: bbNow ? JSON.parse(bbNow) : null });
        matchNo++; koSince = -1; matchStart = tick; base = tick; rawPrev = 0;
        await page.eval(`window.__flashcap.start("${SCEN}", { reduced: false, seed: ${SEED + matchNo} })`, true);
        curSwing = null; lastLn = [0, 0]; wall.run = [0, 0]; wallAll.run = [0, 0];
        continue;
      }
    }
    if (pv && record.planetGen === null) { record.planetGen = pv.planetGen; if (pv.swing === undefined) record.note = 'the page reports no swing state (not a field world, or the swing switch is off in this build)'; }
    // events, from the probe read after this tick
    if (pv && pv.swing) {
      if (pv.swing.on && !curSwing) { curSwing = { start: tick, end: null, cause: pv.swing.cause, kind: pv.swing.kind, maxRate: 0, n: pv.swings }; record.swings.push(curSwing); }
      if (pv.swing.on && curSwing) { curSwing.maxRate = Math.max(curSwing.maxRate, Math.abs(pv.swing.rate)); if (!curSwing.cause) curSwing.cause = pv.swing.cause; }
      if (!pv.swing.on && curSwing) { curSwing.end = tick; curSwing = null; }
    }
    if (pv && Array.isArray(pv.occAll) && pv.occAll.length >= 2) {   // every building in S.buildings at its drawn height
      for (let k = 0; k < 2; k++) {
        if (pv.occAll[k]) { wallAll.run[k]++; wallAll.total[k]++; if (wallAll.run[k] > wallAll.max[k]) { wallAll.max[k] = wallAll.run[k]; wallAll.maxAt[k] = tick; } } else wallAll.run[k] = 0;
      }
    }
    if (pv && Array.isArray(pv.occ) && pv.occ.length >= 2) {
      for (let k = 0; k < 2; k++) {
        if (pv.occ[k]) { wall.run[k]++; wall.total[k]++; if (wall.run[k] > wall.max[k]) { wall.max[k] = wall.run[k]; wall.maxAt[k] = tick; } } else wall.run[k] = 0;
      }
    }
    if (pv && Array.isArray(pv.fx) && tick % EVERY === 0) (record.positions = record.positions || []).push([tick, Math.round(pv.fx[0]), Math.round(pv.fx[1]), Math.round(pv.fx[2]), Math.round(pv.fx[3])]);   // where they stand (world x, height), a row per still: for naming a place to Rendering
    if (pv && Array.isArray(pv.fx)) (record.track = record.track || []).push([tick, Math.round(pv.fx[0] * 10) / 10, Math.round(pv.fx[1] * 10) / 10, Math.round(pv.fx[2] * 10) / 10, Math.round(pv.fx[3] * 10) / 10]);   // every tick: world x of both, then heights (speeds are read from it)
    if (pv && typeof pv.crn === 'number' && pv.crn !== (record.crn || 0)) { (record.craters = record.craters || []).push({ tick, n: pv.crn, last: pv.cr }); record.crn = pv.crn; }   // each change of the crater list: the count and the newest (x, radius, depth, sim time)
    if (pv && 'lm' in pv && !record.lmKeyAt) record.lmKeyAt = { tick, n: Array.isArray(pv.lm) ? pv.lm.length : -1 };   // the probe key seen: the first tick and what it held
    if (pv && Array.isArray(pv.lm) && pv.lm.length && !record.landmarks) record.landmarks = pv.lm;   // every barred landmark (c09: x, depth), read in the first ticks
    if (pv && Array.isArray(pv.ki)) record.kiMax = (record.kiMax || [0, 0]).map((m, k) => Math.max(m, Number(pv.ki[k]) || 0));
    if (pv && pv.bo) {
      record.beamOutcomes = pv.bo;   // CLASH, GUARD, DODGE, HIT ... counted so far
      const nClash = Number(pv.bo.CLASH || 0);
      if (nClash > (record.clashTicks || []).length) { (record.clashTicks = record.clashTicks || []).push(tick); if (argv.includes('--until-clash') && doneAt < 0) doneAt = tick; }
    }
    if (pv && pv.arcsends) { record.arcSends = pv.arcsends; if (Object.keys(pv.arcsends).length && !(record.arcTicks || []).length) (record.arcTicks = record.arcTicks || []).push(tick); }
    if (pv && Array.isArray(pv.noised)) record.thumbCueTimes = pv.noised;   // each stick cue: its kind and the ticks since the last flick of the synthetic thumb
    if (pv && Array.isArray(pv.noise)) record.thumbNoise = { flicksMade: pv.noise[0], stickCuesAfterAFlick: pv.noise[1], phantomCues: pv.noise[2], note: 'a phantom is a stick cue (start, charge, refused) with no flick of the synthetic thumb in the 45 ticks before it' };
    if (pv && pv.stkk) { for (const kk of Object.keys(pv.stkk)) if ((record.stickKinds || {})[kk] !== pv.stkk[kk]) (record.stickLog = record.stickLog || []).push({ tick, kind: kk, n: pv.stkk[kk] }); }   // each change of a stick cue's count: the tick and the kind
    if (pv && pv.stkk) record.stickKinds = pv.stkk;   // the cues by kind so far (the last probe read)
    if (AFTER_REF > 0 && AFTER_WORDS.size && pv && Array.isArray(pv.teach)) {   // --after-words "Too close,Hit": the same window when the HUD's teaching line of player 1 BECOMES one of these words (a refusal word the HUD holds)
      const w = String(pv.teach[0] || '');
      if (w !== lastWord && AFTER_WORDS.has(w) && (record.refusedAt || []).length < AFTER_MAX && tick > refUntil) { (record.refusedAt = record.refusedAt || []).push(tick); (record.wordAt = record.wordAt || []).push({ tick, word: w }); refUntil = tick + AFTER_REF; }
      lastWord = w;
    }
    if (AFTER_REF > 0 && !AFTER_WORDS.size && pv && pv.stkk && Number(pv.stkk.stick_refused || 0) > refSeen) {   // --after-refused N: a still EVERY tick for N ticks after each new stick_refused cue (the first --after-max of them), for the word at the edge
      refSeen = Number(pv.stkk.stick_refused);
      if ((record.refusedAt || []).length < AFTER_MAX) { (record.refusedAt = record.refusedAt || []).push(tick); refUntil = tick + AFTER_REF; }
    }
    if (pv && Array.isArray(pv.teach)) { const tk = JSON.stringify([pv.teach, pv.taught]); if (tk !== lastTeach) { (record.teachLog = record.teachLog || []).push({ tick, teach: pv.teach, taught: pv.taught, tnow: pv.tnow }); lastTeach = tk; } }   // the HUD's teaching lines: each change of what a model says, or of the taught flags
    if (pv && pv.ln) { for (let k = 0; k < 2; k++) if (pv.ln[k] > lastLn[k]) record.launches.push({ tick, fighter: k, n: pv.ln[k], states: pv.fst }); lastLn = pv.ln; }
    const sinceClash = (record.clashTicks || []).length ? tick - record.clashTicks[record.clashTicks.length - 1] : 1e9;
    if (tick % EVERY === 0) {   // the flat-face number: a small PNG of this frame, measured in node
      try {
        const sm = await page.send('Page.captureScreenshot', { format: 'png', fromSurface: true, clip: { x: 0, y: 0, width: W, height: H, scale: 0.25 } });
        const png = decodePng(Buffer.from(sm.data, 'base64'));
        (record.flatFaceSeries = record.flatFaceSeries || []).push([tick, Math.round(flatFaceShare(png.w, png.h, png.data) * 1000) / 1000]);
        // the cut finder: the mean absolute change of the picture's brightness since the still before it (a cut changes the whole frame at once; plain motion does not)
        { const lum = new Uint8Array(png.w * png.h); for (let i = 0; i < lum.length; i++) { const p = i * 4; lum[i] = (png.data[p] * 3 + png.data[p + 1] * 6 + png.data[p + 2]) / 10; } if (prevLum && prevLum.length === lum.length) { let s = 0; for (let i = 0; i < lum.length; i++) s += Math.abs(lum[i] - prevLum[i]); (record.diffSeries = record.diffSeries || []).push([tick, Math.round(s / lum.length * 10) / 10, pv && pv.fst ? pv.fst.join('/') : '']); } prevLum = lum; }
      } catch (e) { record.flatFaceError = String(e.message || e).slice(0, 120); }
    }
    if (tick % EVERY === 0 || ALSO.has(tick) || tick <= refUntil || (sinceClash >= 0 && sinceClash <= 150 && tick % 10 === 0)) {
      const shot = await page.send('Page.captureScreenshot', { format: 'jpeg', quality: 72, fromSurface: true });
      const file = `still-${String(tick).padStart(6, '0')}.jpg`;
      writeFileSync(join(OUT, 'stills', file), Buffer.from(shot.data, 'base64'));
      shots.set(tick, { file, pv: pv ? { padtxt: pv.padtxt || null, swing: pv.swing || null, swings: pv.swings, fst: pv.fst || null, ln: pv.ln || null, hp: pv.hp || null, pz: pv.pz || null, mv: pv.mv === undefined ? null : pv.mv, stk: pv.stk === undefined ? null : pv.stk, p1h: pv.p1human === undefined ? null : pv.p1human, on: { rs: pv.rightStick, stick: pv.stickOn, swing: pv.swingOn } } : null });
    }
    if (HOLD.has(tick) && !(record.holds || []).some((h) => h.tick === tick)) {   // a pause: not stepping, only looking
      const hold = { tick, fighters: pv && pv.fst || null, swing: pv && pv.swing || null, every: HOLD_EVERY, stills: [], changes: [] };
      (record.holds = record.holds || []).push(hold); mkdirSync(join(OUT, 'holds'), { recursive: true });
      let prev = null;
      for (let k = 0; k * HOLD_EVERY <= HOLD_FOR; k++) {
        await sleep(k === 0 ? 1500 : HOLD_EVERY * 1000);
        const sh = await page.send('Page.captureScreenshot', { format: 'jpeg', quality: 80, fromSurface: true });
        const hf = `hold-${String(tick).padStart(6, '0')}-${String(k).padStart(2, '0')}.jpg`;
        writeFileSync(join(OUT, 'holds', hf), Buffer.from(sh.data, 'base64')); hold.stills.push(hf);
        try {
          const sm = await page.send('Page.captureScreenshot', { format: 'png', fromSurface: true, clip: { x: 0, y: 0, width: W, height: H, scale: 0.25 } });
          const png = decodePng(Buffer.from(sm.data, 'base64')); const lum = new Uint8Array(png.w * png.h);
          for (let i = 0; i < lum.length; i++) { const p = i * 4; lum[i] = (png.data[p] * 3 + png.data[p + 1] * 6 + png.data[p + 2]) / 10; }
          if (prev && prev.length === lum.length) { let s = 0; for (let i = 0; i < lum.length; i++) s += Math.abs(lum[i] - prev[i]); hold.changes.push(Math.round(s / lum.length * 100) / 100); }
          prev = lum;
        } catch (e) { hold.error = String(e.message || e).slice(0, 100); }
      }
      log(`hold at tick ${tick}: ${hold.stills.length} stills over ${HOLD_FOR} s, the change from still to still ${JSON.stringify(hold.changes)}`);
    }
    const swingsDone = record.swings.filter((s) => s.end !== null).length;
    if (doneAt < 0 && swingsDone >= NSWING && record.launches.length >= NLAUNCH) doneAt = tick;
    if (doneAt >= 0 && tick >= doneAt + (argv.includes('--until-clash') ? 150 : MARGIN)) break;
    if (AFTER_REF > 0 && (record.refusedAt || []).length >= AFTER_MAX && tick > refUntil) break;   // the refusals asked for are caught, and their windows are over
  }
  record.ticks = last;
  if (record.flatFaceSeries && record.flatFaceSeries.length) {
    const s = record.flatFaceSeries;
    if (record.diffSeries && record.diffSeries.length) { const top = [...record.diffSeries].sort((x, y) => y[1] - x[1]).slice(0, 12); record.cutCandidates = { note: 'the stills with the biggest change from the still before them (mean brightness change, 0 to 255): a cut shows as a spike far above the rest; the states of both fighters are given at that still', median: record.diffSeries.map((x) => x[1]).sort((x, y) => x - y)[Math.floor(record.diffSeries.length / 2)], top }; log('CUT CANDIDATES (change vs the still before, median ' + record.cutCandidates.median + '): ' + top.slice(0, 8).map((x) => 'tick ' + x[0] + ' ' + x[1] + ' [' + x[2] + ']').join('; ')); }
    record.flatFace = { note: 'the share of the frame filled by ONE flat, non-blue face (a wall close up), measured on a quarter-size PNG of every still; reported, it does not fail a run', maxShare: Math.max(...s.map((x) => x[1])), atTick: s.reduce((a, x) => (x[1] > a[1] ? x : a), [0, 0])[0], stillsOver35pc: s.filter((x) => x[1] > 0.35).length, stills: s.length, ticksOver35pc: s.filter((x) => x[1] > 0.35).map((x) => x[0]) };
    log('FLAT FACE: the largest single flat face filled ' + Math.round(record.flatFace.maxShare * 100) + '% of the frame (tick ' + record.flatFace.atTick + '); ' + record.flatFace.stillsOver35pc + ' of ' + record.flatFace.stills + ' stills over 35%');
  }
  record.wall = { limitTicks: 180, longestRunTicks: wall.max, endedAtTick: wall.maxAt, totalTicks: wall.total, fail: Math.max(...wall.max) > 180 };
  record.wallDrawn = { note: 'every building in S.buildings at the height the view draws it (PlanetView.occluders over all of them)', limitTicks: 180, longestRunTicks: wallAll.max, endedAtTick: wallAll.maxAt, totalTicks: wallAll.total, fail: Math.max(...wallAll.max) > 180 };
  record.wall.failAny = record.wall.fail || record.wallDrawn.fail;
  log(`WALL CHECK (drawn): the longest stretch behind a building at its DRAWN height was ${wallAll.max[0]} ticks for fighter 1 (ending at tick ${wallAll.maxAt[0]}) and ${wallAll.max[1]} for fighter 2 (tick ${wallAll.maxAt[1]}); in all ${wallAll.total[0]} and ${wallAll.total[1]} of ${last} ticks: ${record.wallDrawn.fail ? 'FAIL' : 'ok'}`);
  log(`WALL CHECK: the longest stretch behind a building was ${wall.max[0]} ticks for fighter 1 (ending at tick ${wall.maxAt[0]}) and ${wall.max[1]} for fighter 2 (tick ${wall.maxAt[1]}); in all ${wall.total[0]} and ${wall.total[1]} of ${last} ticks; the limit is 180 (3 s): ${record.wall.fail ? 'FAIL' : 'ok'}`);
  if (REMATCH) record.matches.push({ n: matchNo, seed: SEED + matchNo, from: matchStart, to: last, ended: koSince >= 0 ? 'KO' : 'run ended' });
  if (record.errors.length) { log(`PAGE ERRORS: ${record.errors.length}; first: ${record.errors[0].line.slice(0, 200)}`); code = 4; } else log('PAGE ERRORS: none');
  if (argv.includes('--wall-check') && record.wall.failAny) code = 3;
  if (curSwing) curSwing.end = null;
  // the sound log (?audiolog=1 in --query): every cue the game handed to its voices, the output's level, the engine's own mixer and every vibration request, read once at the end
  try {
    const au = await page.eval('JSON.stringify(window.__audio_snap ? window.__audio_snap() : null)').catch(() => null);
    if (au) { writeFileSync(join(OUT, 'audio.json'), `${au}\n`); const a = JSON.parse(au); record.audio = a && { cues: a.cues, cuesTaken: a.cuesTaken, cuesDropped: a.cuesDropped, rumbleRequests: a.vibrationRequestsFromTheGame, browserVibrate: a.navigatorVibrateCalls, peak: a.peak, loudWindows: a.loudWindows, windows: a.windows, engineMixer: a.engineMixer, bySound: a.cuesBySound }; log(`sound: ${a.cues} cues (${a.cuesTaken} taken), rumble requests ${a.vibrationRequestsFromTheGame}, output peak ${a.peak}, engine mixer ${JSON.stringify(a.engineMixer && a.engineMixer.maxDb)}`); }
  } catch (e) { log(`sound log not read: ${e.message}`); }
  // which stills to keep: those within MARGIN of a swing (start to end) or a launch
  const keep = [];
  for (const [tick, s] of [...shots.entries()].sort((a, b) => a[0] - b[0])) {
    const near = KEEP_ALL || (record.clashTicks || []).some((c) => tick >= c - MARGIN && tick <= c + 150) || record.swings.some((w) => tick >= w.start - MARGIN && tick <= (w.end === null ? last : w.end) + MARGIN) || record.launches.some((l) => Math.abs(tick - l.tick) <= MARGIN);
    if (near) keep.push({ tick, ...s });
  }
  record.pictures = keep.map((k) => ({ tick: k.tick, file: `stills/${k.file}`, swing: k.pv && k.pv.swing, fighters: k.pv && k.pv.fst, launchN: k.pv && k.pv.ln, pause: k.pv && k.pv.pz, moving: k.pv && k.pv.mv, stickCues: k.pv && k.pv.stk }));
  record.stickCues = Math.max(0, ...keep.map((k) => (k.pv && typeof k.pv.stk === 'number' ? k.pv.stk : 0)));
  log(`${last} ticks played: ${record.swings.length} swing(s), ${record.launches.length} launch(es), ${keep.length} stills kept of ${shots.size}`);
  // the contact sheets: an HTML page of the stills, the caption in each still's corner, shot by the same browser
  const label = (k) => {
    const sw = k.pv && k.pv.swing;
    const on = sw && sw.on;
    const evL = record.launches.filter((l) => Math.abs(l.tick - k.tick) < EVERY / 2 + 15).map((l) => `LAUNCH #${l.n} (fighter ${l.fighter + 1})`);
    return [`tick ${k.tick}`,
      sw ? (on ? `SWING ON  ${sw.rate} deg/s  ${sw.left} left` : 'swing at rest') : 'no swing state',
      sw && on ? `cause: ${sw.cause || '?'}` : (k.pv && k.pv.swings >= 0 ? `swings so far ${k.pv.swings}` : ''),
      k.pv && k.pv.fst ? `A ${k.pv.fst[0]} / B ${k.pv.fst[1]}` : '',
      k.pv && k.pv.stk !== null && k.pv.stk !== undefined ? `stick cues so far ${k.pv.stk}   player 1 human: ${k.pv.p1h}   defaults: right hand ${k.pv.on && k.pv.on.rs}, DirStick ${k.pv.on && k.pv.on.stick}, DirSwing ${k.pv.on && k.pv.on.swing}` : '',
      k.pv && k.pv.padtxt ? `PAD: ${k.pv.padtxt}` : '',
      k.pv && k.pv.pz ? `pause.left ${k.pv.pz[0]}  dirS.stop ${k.pv.pz[1]}${k.pv.mv === null || k.pv.mv === undefined ? '' : `  moving ${k.pv.mv}`}` : '', ...evL].filter(Boolean);
  };
  const DENSE = argv.includes('--dense');
  const COLS = DENSE ? 6 : 4, TW = DENSE ? 320 : 480, TH = DENSE ? 180 : 270;
  const PER = DENSE ? 60 : 12;
  const sheets = [];
  const sheetKeep = !DENSE && keep.length > 96 ? keep.filter((_, i) => i % Math.ceil(keep.length / 96) === 0) : keep;   // a long reel's sheets are a sample; every still is in stills/
  for (let s = 0; s * PER < sheetKeep.length; s++) {
    const cells = sheetKeep.slice(s * PER, (s + 1) * PER).map((k) => `<figure><img src="stills/${k.file}"><figcaption>${(DENSE ? label(k).slice(0, 2) : label(k)).map((l, i) => (i === 0 ? `<b>${l}</b>` : l)).join('<br>')}</figcaption></figure>`).join('');
    const html = `<!doctype html><meta charset="utf-8"><style>body{margin:0;background:#10131a;font:12px/1.35 Consolas,monospace;color:#e8ecf4}.g{display:grid;grid-template-columns:repeat(${COLS},${TW}px);gap:4px;padding:4px}figure{margin:0;position:relative;width:${TW}px;height:${TH}px}img{width:${TW}px;height:${TH}px;display:block}figcaption{position:absolute;left:6px;bottom:6px;background:rgba(8,10,16,.78);padding:4px 7px;border-radius:3px}</style><div class="g">${cells}</div>`;
    writeFileSync(join(OUT, `sheet-${s + 1}.html`), html);
    sheets.push(`sheet-${s + 1}`);
  }
  const sheetServer = await serve(resolve(OUT));
  const rows = (n) => Math.ceil(n / COLS);
  for (let s = 0; s < sheets.length; s++) {
    const n = Math.min(PER, sheetKeep.length - s * PER);
    await page.send('Emulation.setDeviceMetricsOverride', { width: COLS * (TW + 4) + 4, height: rows(n) * (TH + 4) + 8, deviceScaleFactor: 1, mobile: false });
    await page.send('Page.navigate', { url: `http://127.0.0.1:${sheetServer.address().port}/${sheets[s]}.html` });
    await sleep(1200);
    const shot = await page.send('Page.captureScreenshot', { format: 'png', fromSurface: true });
    writeFileSync(join(OUT, `${sheets[s]}.png`), Buffer.from(shot.data, 'base64'));
    rmSync(join(OUT, `${sheets[s]}.html`), { force: true });
  }
  sheetServer.close();
  writeFileSync(join(OUT, 'reel.json'), `${JSON.stringify(record, null, 2)}\n`);
  log(`wrote ${sheets.length} contact sheet(s) and reel.json to ${OUT}`);
} catch (e) {
  console.error(`[reel] FAILED: ${e.message}`);
  code = 1;
} finally {
  if (page) page.close();
  if (browser) await browser.close();
  server.close();
}
process.exit(code);
