// Self-test of the right-stick capture page and its analysis (tools/capture/): lints the page (one file, no network, no library, the privacy promises), checks the protocol against the spec's
// counts, then builds synthetic captures in the page's file format (an ideal thumb at 60 and 144 Hz, a pad that clicks its stick on hard flicks, a phone, a keyboard) and runs the analysis on them.
//   node tools/capture/right-stick-selftest.mjs
import { mkdtempSync, readFileSync, rmSync, writeFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import vm from 'node:vm';
import { analyse, loadCaptures, percentiles, quant, rescale, trialTicks, traceStats, angleErr, guardSurvives, thumbTransfer } from './right-stick-analyse.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
let ran = 0, failed = 0;
const check = (name, ok, extra) => { ran++; if (!ok) { failed++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };

// ------------------------------------------------------------------ the page
const html = readFileSync(join(HERE, 'right-stick.html'), 'utf8');
const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => m[1]);
check('the page has exactly one script, inline', scripts.length === 1 && !/<script[^>]+src=/i.test(html));
let compiles = true; try { new vm.Script(scripts[0]); } catch (e) { compiles = false; console.log(e.message); }
check('the page script compiles', compiles);
const code = scripts[0] || '';
for (const [re, what] of [[/\bfetch\s*\(/, 'fetch'], [/XMLHttpRequest/, 'XMLHttpRequest'], [/WebSocket/, 'WebSocket'], [/sendBeacon/, 'sendBeacon'], [/EventSource/, 'EventSource'], [/\bimport\s*\(/, 'dynamic import'], [/importScripts/, 'importScripts'], [/localStorage|sessionStorage|indexedDB|document\.cookie/, 'storage'], [/new Image\b|new Worker\b|new SharedWorker\b|navigator\.serviceWorker/, 'image, worker or service worker']])
  check(`the page does not use ${what}`, !re.test(code));
check('the page loads nothing from outside (no http(s) URL in attributes or script)', !/(src|href|action|data-src)\s*=\s*["']?https?:/i.test(html) && !/https?:\/\//.test(code));
check('the page has no <link>, <img src>, <iframe>, <form> or external <script>', !/<link\b|<img\b|<iframe\b|<form\b|<embed\b|<object\b/i.test(html));
const csp = /<meta http-equiv="Content-Security-Policy" content="([^"]*)"/.exec(html);
check('the page carries a policy that forbids any request (default-src none, connect-src none)', !!csp && /default-src 'none'/.test(csp[1]) && /connect-src 'none'/.test(csp[1]) && !/https?:|\*/.test(csp[1]));
check('the page promises nothing is sent and says what is recorded', /Nothing is sent anywhere/.test(html) && /No name, no email/.test(html));
check('the page saves one JSON file through a blob link', /new Blob\(\[JSON\.stringify/.test(code) && /a\.download = name/.test(code));
check('the page asks how the pad is held (the grip) and saves it', /How do you hold the pad\?/.test(html) && /grip: S\.person\.grip/.test(code));
check('the page has the three variants', /'gamepad'/.test(code) && /'touch'/.test(code) && /'keyboard'/.test(code) && /getGamepads/.test(code) && /pointerdown/.test(code) && /keydown/.test(code));
check('the page can be stopped at any time and saves what it has', /Stop and save what I have/.test(code) && /finish\(false\)/.test(code));
check('the page keeps the Gamepad API timestamp, the frame time and the raw axes', /gp\.timestamp, f, /.test(code) && /gp\.axes\[S\.ax\]/.test(code));

// ------------------------------------------------------------------ the protocol
const proto = /\/\/ ==PROTOCOL-BEGIN==([\s\S]*?)\/\/ ==PROTOCOL-END==/.exec(code);
check('the protocol block is delimited (it can be run without a browser)', !!proto);
const ctx = {}; vm.createContext(ctx);
if (proto) vm.runInContext(proto[1] + ';this.bp = buildProtocol; this.es = estimateSeconds;', ctx);
let seed = 7; const rnd = () => { seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648; };
for (const mode of ['gamepad', 'touch', 'keyboard']) {
  const b = ctx.bp(mode, rnd), ids = b.map((x) => x.id), count = (id) => (b.find((x) => x.id === id) || { trials: [] }).trials.length;
  check(`${mode}: the blocks are in the spec's order (the thumb block, pad only, after the hard flicks)`, ids.join() === (mode === 'gamepad' ? 'rest,flick4,flick8,hold,pump,zigzag,circle,free,hard,thumb,idle,fight' : 'rest,flick4,flick8,hold,pump,zigzag,circle,free,hard,idle,fight'), ids.join());
  if (mode === 'gamepad') {
    const th = b.find((x) => x.id === 'thumb').trials;
    check('gamepad: the thumb block is 4 directions x (button-flick-button, button-flick, flick-button) x (comfortable, fast) = 24 timed trials', th.length === 24 && ['aba', 'b2s', 's2b'].every((q) => ['comfortable', 'fast'].every((p) => th.filter((x) => x.expect.seq === q && x.speed === p).length === 4 && ['up', 'right', 'down', 'left'].every((d) => th.filter((x) => x.expect.seq === q && x.speed === p && x.expect.dir === d).length === 1))));
    check('gamepad: a thumb trial says what to press and where to flick', th.every((x) => /bottom button/.test(x.say) && /flick/i.test(x.say) && Number.isInteger(x.expect.sector)));
  }
  check(`${mode}: four-way flicks are 6 a direction comfortable and 3 fast`, count('flick4') === 36 && b[1].trials.filter((t) => t.speed === 'fast').length === 12 && ['up', 'right', 'down', 'left'].every((d) => b[1].trials.filter((t) => t.id === `flick4.${d}.comfortable`).length === 6 && b[1].trials.filter((t) => t.id === `flick4.${d}.fast`).length === 3));
  check(`${mode}: eight-way flicks are 3 a direction`, count('flick8') === 24 && b[2].trials.every((t, _, a) => a.filter((u) => u.id === t.id).length === 3));
  check(`${mode}: holds are 3 a direction and 1.5 s`, count('hold') === 12 && b[3].trials.every((t) => t.expect.hold_ms === 1500));
  check(`${mode}: 6 double flicks, 8 zig-zags (horizontal and vertical, 3 and 4 strokes), 18 circles, 2 free sweeps of 20 s, 10 hard flicks, 10 s idle, 5 fight trials`,
    count('pump') === 6 && count('zigzag') === 8 && count('circle') === 18 && count('free') === 2 && b[7].trials.every((t) => t.win_ms === 20000) && count('hard') === 10 && b.find((x) => x.id === 'idle').trials[0].win_ms === 10000 && count('fight') === 5);
  check(`${mode}: every trial states what it expects, with a sector where there is a direction`, b.every((x) => x.trials.every((t) => t.expect && t.expect.kind && (t.expect.dir === undefined || Number.isInteger(t.expect.sector) || ['horizontal', 'vertical', 'cw', 'ccw'].includes(t.expect.dir) || t.expect.axis))));
  const s = ctx.es(b);
  check(`${mode}: the run takes about nine minutes of trials or less (${s} s of trials; the parts' screens add the rest)`, s >= 420 && s <= (mode === 'gamepad' ? 640 : 560), String(s));
}

// ------------------------------------------------------------------ helpers of the analysis
check('quantising goes to sixteenths', quant(0.5) === 0.5 && quant(0.53) === 0.5 && quant(0.57) === 0.5625);
check('percentiles interpolate', percentiles([1, 2, 3, 4, 5], [0, 50, 100]).join() === '1,3,5');
check('rescale takes out the dead zone', rescale(0.2) === 0 && Math.abs(rescale(1) - 1) < 1e-9 && Math.abs(rescale(0.625) - 0.5) < 1e-9);
{
  const rest = (n) => Array.from({ length: n }, () => [0, 0]), full = (n) => Array.from({ length: n }, () => [1, 0]);
  const tr = [...rest(10), ...full(5), ...rest(30)];
  check('the R3 guard ignores a click while the stick is past 0.9', !guardSurvives(tr, 12));
  check('the R3 guard ignores a click up to 6 ticks after the stick was past 0.9', !guardSurvives(tr, 20) && !guardSurvives(tr, 14 + 6));
  check('the R3 guard lets a click through 7 ticks after, or before the deflection', guardSurvives(tr, 14 + 7) && guardSurvives(tr, 5));
  check('the R3 guard\'s numbers can be changed', guardSurvives(tr, 12, 1.1, 6) && !guardSurvives(tr, 25, 0.9, 12));
}
check('angle error wraps', angleErr(350, 0) === 10 && angleErr(-170, 4) === 10 && angleErr(95, 2) === 5);

// ------------------------------------------------------------------ synthetic captures
const DIRS = [['right', 0], ['up-right', 1], ['up', 2], ['up-left', 3], ['left', 4], ['down-left', 5], ['down', 6], ['down-right', 7]];
const ang = (sector) => sector * Math.PI / 4;
// a stick path as a function of seconds since the window opened, returning [x, y] with y UP
function pathFor(kind, a, t) {
  const clamp01 = (v) => Math.max(0, Math.min(1, v));
  if (kind === 'flick' || kind === 'hard') { const up = clamp01(t / 0.04), down = clamp01((t - 0.16) / 0.06); const m = up * (1 - down); return [Math.cos(a) * m, Math.sin(a) * m]; }
  if (kind === 'hold') { const up = clamp01(t / 0.25), down = clamp01((t - 1.55) / 0.06); const m = 0.95 * up * (1 - down); return [Math.cos(a) * m, Math.sin(a) * m]; }
  if (kind === 'zigzag') { const stroke = 0.13, n = a.strokes; const k = Math.floor(t / stroke); if (t >= stroke * (n + 1)) return [0, 0]; const ph = (t - k * stroke) / stroke; const pos = (i) => (i % 2 === 0 ? 1 : -1) * 0.95; const from = k === 0 ? 0 : pos(k - 1), to = k < n ? pos(k) : 0; const v = from + (to - from) * ph; return a.axis === 'horizontal' ? [v, 0] : [0, v]; }
  if (kind === 'circle') { const dur = { quarter: 0.3, half: 0.5, full: 0.78 }[a.size]; if (t >= dur + 0.05) return [0, 0]; const u = clamp01(t / dur); const th = a.start + a.sign * (a.size === 'quarter' ? Math.PI / 2 : a.size === 'half' ? Math.PI : 2 * Math.PI) * u; const m = clamp01(t / 0.03) * 0.92; return [Math.cos(th) * m, Math.sin(th) * m]; }
  if (kind === 'free') return [0.8 * Math.cos(0.5 * t), 0.8 * Math.sin(0.5 * t)];
  return [0, 0];
}
function synth(opts) {
  const hz = opts.hz, dt = 1000 / hz, code = opts.code;
  const cap = { format: 'meridian.right-stick-capture/1', page: { version: 1 }, complete: true, person: { code, hand: 'right', thumb: 'right', rating: opts.rating, grip: opts.grip || 'thumbs', pad_model: opts.pad || '' }, env: { mode: opts.mode, frame_hz_estimate: hz, gamepad: opts.mode === 'gamepad' ? { mapping: 'standard', axes: 4, buttons: 17, axis_x: 2, axis_y: 3 } : null }, trials: [], events: [], samples: [], buttons: [], touch: [], keys: [] };
  let f = 1000, clickNext = null;
  const trials = [];
  const add = (block, prompt, speed, expect, win_ms, kind, a, extra = {}) => trials.push({ block, prompt, speed, expect, win_ms, kind, a, ...extra });
  add('rest', 'rest', null, { kind: 'rest' }, 2000, 'rest');
  for (const [name, s] of DIRS.filter((d) => d[1] % 2 === 0)) for (let r = 0; r < 3; r++) add('flick4', `flick4.${name}.comfortable`, 'comfortable', { kind: 'flick', dir: name, sector: s }, 1400, 'flick', ang(s));
  for (const [name, s] of DIRS) for (let r = 0; r < 2; r++) add('flick8', `flick8.${name}`, 'comfortable', { kind: 'flick', dir: name, sector: s }, 1400, 'flick', ang(s));
  for (const [name, s] of DIRS.filter((d) => d[1] % 2 === 0)) for (let r = 0; r < 2; r++) add('hold', `hold.${name}`, 'comfortable', { kind: 'hold', dir: name, sector: s, hold_ms: 1500 }, 2700, 'hold', ang(s));
  for (const axis of ['horizontal', 'vertical']) for (const strokes of [3, 4]) for (let r = 0; r < 2; r++) add('zigzag', `zigzag.${axis}.${strokes}`, 'comfortable', { kind: 'zigzag', axis, strokes }, 3000, 'zigzag', { axis, strokes });
  for (const size of ['quarter', 'half', 'full']) for (const sign of [1, -1]) for (let r = 0; r < 2; r++) add('circle', `circle.${size}.${sign > 0 ? 'ccw' : 'cw'}`, 'comfortable', { kind: size, dir: sign > 0 ? 'ccw' : 'cw' }, 3000, 'circle', { size, sign, start: r * Math.PI / 2 });
  add('free', 'free', null, { kind: 'free' }, 20000, 'free');
  for (const [name, s] of DIRS.filter((d) => d[1] % 2 === 0)) add('hard', `hard.${name}`, 'hardest', { kind: 'hard', dir: name, sector: s }, 1500, 'hard', ang(s), { click: opts.clicks });
  if (opts.mode === 'gamepad') {
    // the thumb block: the bottom button, the stick, the bottom button, with the gaps a person of this grip leaves (a claw overlaps them)
    for (const seq of ['aba', 'b2s', 's2b']) for (const pace of ['comfortable', 'fast']) for (const [name, s] of DIRS.filter((d) => d[1] % 2 === 0).slice(0, 2)) {
      const gapB = (opts.claw ? -60 : pace === 'fast' ? 60 : 150), gapS = (opts.claw ? -30 : pace === 'fast' ? 70 : 180);
      const events = []; let flickStart;
      if (seq === 'aba' || seq === 'b2s') { events.push([300, 1], [380, 0]); flickStart = 380 + gapB; } else flickStart = 400;
      const offAt = flickStart + 196;   // the stick is back under 0.2 (rescaled) 196 ms after a 40/120/60 ms flick starts
      if (seq === 'aba') events.push([offAt + gapS, 1], [offAt + gapS + 80, 0]); if (seq === 's2b') events.push([offAt + gapS, 1], [offAt + gapS + 80, 0]);
      add('thumb', `thumb.${seq}.${pace}`, pace, { kind: 'thumb', seq, dir: name, sector: s }, seq === 'aba' ? 3200 : 2400, 'thumb', ang(s), { thumb: { flickStart, events } });
    }
  }
  add('idle', 'idle', null, { kind: 'idle' }, 10000, 'idle');
  const drift = opts.drift || 0;
  const stickAt = (kind, a, tms) => {
    const [x, y] = pathFor(kind, a, tms / 1000);
    return [x + drift, -(y + drift)];   // the page records y DOWN positive
  };
  const frames = (ms, fn) => { const n = Math.round(ms / dt); for (let i = 0; i < n; i++) { fn(i * dt); f += dt; } };
  const pointers = [];
  for (const tr of trials) {
    const rec = { block: tr.block, prompt: tr.prompt, n: 1, speed: tr.speed, expect: tr.expect, win_ms: tr.win_ms, countdown_ms: 1000, start_f: null, end_f: null, i0: null, i1: null, b0: null, b1: null, interrupted: false, label: null };
    const rest = () => { if (opts.mode === 'gamepad') { cap.samples.push([f, f, drift, -drift]); } };
    if (tr.block !== 'rest') frames(1000, rest);
    rec.start_f = f;
    rec.i0 = opts.mode === 'gamepad' ? cap.samples.length : opts.mode === 'touch' ? cap.touch.length : cap.keys.length; rec.b0 = cap.buttons.length;
    let down = false, prevMag = 0;
    frames(tr.win_ms, (tms) => {
      if (opts.mode === 'gamepad') {
        const [x, y] = tr.kind === 'thumb' ? (tms >= tr.thumb.flickStart ? [pathFor('flick', tr.a, (tms - tr.thumb.flickStart) / 1000)[0] + drift, -(pathFor('flick', tr.a, (tms - tr.thumb.flickStart) / 1000)[1] + drift)] : [drift, -drift]) : stickAt(tr.kind, tr.a, tms);
        cap.samples.push([f, f, x, y]);
        if (tr.kind === 'thumb') { tr.thumb.sent = tr.thumb.sent || 0; while (tr.thumb.sent < tr.thumb.events.length && tr.thumb.events[tr.thumb.sent][0] <= tms) { const e = tr.thumb.events[tr.thumb.sent++]; cap.buttons.push([f, f, 0, e[1], e[1]]); } }
        if (tr.click && tr.kind === 'hard') { if (tms >= 40 && tms < 41 + dt && !down) { down = true; cap.buttons.push([f, f, 11, 1, 1]); } if (down && tms > 140 && down !== 'up') { cap.buttons.push([f, f, 11, 0, 0]); down = 'up'; } }
      } else if (opts.mode === 'touch') {
        const [x, y] = pathFor(tr.kind, tr.a, tms / 1000); const mag = Math.hypot(x, y);
        if (mag > 0.02 && prevMag <= 0.02) cap.touch.push([f, f, 0, 0, 0, 1]);
        else if (mag > 0.02) cap.touch.push([f, f, x * 60, -y * 60, 1, 1]);
        else if (prevMag > 0.02) cap.touch.push([f, f, 0, 0, 2, 1]);
        prevMag = mag;
      } else if (opts.mode === 'keyboard' && (tr.kind === 'flick' || tr.kind === 'hard')) {
        const k = tr.a === 0 ? 'ArrowRight' : tr.a === Math.PI ? 'ArrowLeft' : tr.a > 1 && tr.a < 2 ? 'ArrowUp' : 'ArrowDown';
        if (tms < dt && !down) { down = true; cap.keys.push([f, f, k, 1, 0]); } if (tms >= 100 && down === true) { down = 'up'; cap.keys.push([f, f, k, 0, 0]); }
      }
    });
    rec.end_f = f;
    rec.i1 = opts.mode === 'gamepad' ? cap.samples.length : opts.mode === 'touch' ? cap.touch.length : cap.keys.length; rec.b1 = cap.buttons.length;
    cap.trials.push(rec);
    frames(500, rest);
  }
  void pointers; void clickNext;
  return cap;
}

const tmp = mkdtempSync(join(tmpdir(), 'rs-selftest-'));
let pyOk = true;
try {
  const probe = spawnSync('python', ['--version'], { encoding: 'utf8' }); pyOk = probe.status === 0;
  const caps = [
    synth({ code: 'ALPHA', rating: 'fps_fighting', mode: 'gamepad', hz: 60, pad: 'Xbox 360 Controller (STANDARD GAMEPAD)', clicks: false }),
    synth({ code: 'BRAVO', rating: 'regular', mode: 'gamepad', hz: 144, pad: 'DualSense Wireless Controller (STANDARD GAMEPAD)', clicks: true }),
    synth({ code: 'CHARLIE', rating: 'new', mode: 'gamepad', hz: 60, pad: 'Pro Controller (STANDARD GAMEPAD)', clicks: false, drift: 0.02, grip: 'claw', claw: true }),
    synth({ code: 'DELTA', rating: 'regular', mode: 'touch', hz: 60 }),
    synth({ code: 'ECHO', rating: 'regular', mode: 'keyboard', hz: 60 })
  ];
  for (const c of caps) writeFileSync(join(tmp, `rsc-${c.person.code}.json`), JSON.stringify(c));
  writeFileSync(join(tmp, 'notes.json'), '{"hello":1}');
  const loaded = loadCaptures([tmp]);
  check('the loader reads the captures and skips a file that is not one', loaded.length === 5);
  // tick conversion: a 144 Hz flick and a 60 Hz one give the same ticks
  const a = loaded.find((c) => c.person.code === 'ALPHA'), b = loaded.find((c) => c.person.code === 'BRAVO');
  const ta = trialTicks(a, a.trials.find((t) => t.prompt === 'flick4.up.comfortable')), tb = trialTicks(b, b.trials.find((t) => t.prompt === 'flick4.up.comfortable'));
  check('a stick pushed up is +y after the page\'s y-down is flipped, and reaches full within a few ticks', ta.some((t) => t[1] > 0.9) && !ta.some((t) => t[1] < -0.2), JSON.stringify(ta.slice(0, 6)));
  check('60 Hz and 144 Hz give the same ticks (to within a tick of onset)', Math.abs(ta.findIndex((t) => t[1] > 0.5) - tb.findIndex((t) => t[1] > 0.5)) <= 1);
  const st = traceStats(ta);
  check('the trace statistics find a fast rise and an upward angle', st.rise != null && st.rise <= 3 && Math.abs(st.angle - 90) < 10 && st.peak > 0.9, JSON.stringify(st));

  if (!pyOk) console.log('  (no python on this machine: the engine part of the self-test is skipped)');
  else {
    const T = analyse(loaded.filter((c) => c.env.mode === 'gamepad'), { rises: [2, 3, 4, 5], rise: 3 }), TA = analyse(loaded, { rises: [3], rise: 3 });
    const dir = (set, g, r = 3) => T.tables.direction.find((x) => x.set === set && x.group === g && x.rise === r);
    check('the recogniser runs and the participation table counts people, bands and pads', T.tables.participation.people === 3 && T.tables.participation.bands.length === 3 && T.tables.participation.pads.length === 3 && TA.tables.participation.people === 5);
    check('ideal four-way flicks: every one read, in the right direction', ['fps_fighting', 'regular', 'new'].every((g) => { const r = dir('four-way comfortable', g); return !r || (r.flick === 100 && r.exact === 100); }), JSON.stringify(T.tables.direction.filter((x) => x.set === 'four-way comfortable' && x.rise === 3)));
    check('ideal eight-way flicks: every one read, and diagonals land within one sector', ['fps_fighting', 'regular', 'new'].every((g) => { const r = dir('eight-way', g); return !r || (r.flick === 100 && r.within1 === 100); }), JSON.stringify(T.tables.direction.filter((x) => x.set === 'eight-way' && x.rise === 3)));
    const holdsAt3 = T.tables.flickVsHold.find((x) => x.rise === 3);
    check('holds are read as holds and (by design) not as flicks', holdsAt3.holdRead === 100 && holdsAt3.holdAlsoFlick === 0, JSON.stringify(holdsAt3));
    check('ideal flicks are read as flicks at every rise from 3 up (a 40 ms onset is 2 to 3 ticks, so 2 is too strict)', T.tables.flickVsHold.filter((x) => x.rise >= 3).every((x) => x.flickRead === 100) && T.tables.flickVsHold.find((x) => x.rise === 2).flickRead < 100, JSON.stringify(T.tables.flickVsHold));
    const idle = T.tables.falsePatterns.find((x) => x.kind === 'idle' && x.group === 'all'), free = T.tables.falsePatterns.find((x) => x.kind === 'free' && x.group === 'all');
    check('no false pattern at idle (including a pad that drifts 0.02)', idle && idle.patterns === 0 && idle.minutes > 0.4, JSON.stringify(idle));
    check('no false pattern in a slow free sweep (a slow orbit)', free && free.patterns === 0 && free.minutes >= 0.99, JSON.stringify(free));
    check('the hard-flick click table finds the pad that clicks (4 clicks in 4 flicks) and the ones that do not', T.tables.hardClicks.trials === 12 && T.tables.hardClicks.clicks === 4 && T.tables.hardClicks.withClick === 4, JSON.stringify(T.tables.hardClicks));
    check('the R3 guard leaves none of those clicks (each came with the stick at the edge), and the bars table judges the guarded rate', T.tables.hardClicks.r3 === 4 && T.tables.hardClicks.r3Survive === 0 && T.tables.hardClicks.r3SurvivePer100 === 0 && T.tables.bars.some((b) => /guard lets through/.test(b.measure) && b.pass === true) && T.tables.bars.some((b) => /raw, before the guard/.test(b.measure) && b.pass === null), JSON.stringify(T.tables.bars.filter((b) => /click/i.test(b.measure))));
    const rec = T.tables.patternRecall;
    check('ideal circles and zig-zags are mostly recognised on a pad', Object.values(rec).some((r) => r.n > 0) && Object.values(rec).every((r) => r.pct >= 60), JSON.stringify(rec));
    check('the touch and keyboard captures are analysed too (the keyboard table and the spans are present)', !!TA.tables.keyboard && TA.tables.keyboard.trials > 0 && TA.tables.distributions['span half (ticks)'].n >= 5, JSON.stringify(TA.tables.keyboard));
    check('the bars table lists the spec\'s measures with a verdict', ['four-way flick recall and direction', 'hold read as a hold', 'false patterns at idle'].every((m) => T.tables.bars.some((x) => x.measure === m)) && T.tables.bars.every((x) => x.pass === true || x.pass === false || x.pass === null));
    const thumb = (pad, grip, pace, seq, move) => T.tables.thumb.find((r) => r.pad.startsWith(pad) && r.grip === grip && r.pace === pace && r.seq === seq && r.move === move);
    const near = (r, want, tol = 25) => r && r.n === r.trials && Math.abs(r.median - want) <= tol;
    check('thumb transfer: every thumb trial yields its times, per pad and grip', T.tables.thumb.length === 3 * 2 * 5 + 0 && T.tables.thumb.every((r) => r.n === r.trials && r.n > 0), JSON.stringify(T.tables.thumb.filter((r) => r.n !== r.trials)));
    check('thumb transfer (60 Hz pad, thumbs): button to stick 90 and 180 ms, stick to button 70 and 180 ms, as scripted (the stick takes 28 ms to reach 0.6)', near(thumb('Xbox', 'thumbs', 'comfortable', 'b2s', 'b2s'), 178) && near(thumb('Xbox', 'thumbs', 'fast', 'b2s', 'b2s'), 88) && near(thumb('Xbox', 'thumbs', 'comfortable', 's2b', 's2b'), 180) && near(thumb('Xbox', 'thumbs', 'fast', 's2b', 's2b'), 70), JSON.stringify(T.tables.thumb.filter((r) => r.pad.startsWith('Xbox')).map((r) => [r.pace, r.seq, r.move, r.median])));
    check('thumb transfer (144 Hz pad): the same times within a frame', near(thumb('DualSense', 'thumbs', 'comfortable', 'aba', 'b2s'), 178, 20) && near(thumb('DualSense', 'thumbs', 'comfortable', 'aba', 's2b'), 180, 20) && near(thumb('DualSense', 'thumbs', 'fast', 'aba', 'total'), 406, 20), JSON.stringify(T.tables.thumb.filter((r) => r.pad.startsWith('DualSense')).map((r) => [r.pace, r.seq, r.move, r.median])));
    check('thumb transfer: a claw grip overlaps (negative times, all of them) and is told apart by grip', (() => { const r = thumb('Pro Controller', 'claw', 'comfortable', 'b2s', 'b2s'), q = thumb('Pro Controller', 'claw', 'fast', 's2b', 's2b'); return r && q && r.median < 0 && r.overlap === 100 && q.median < 0 && q.overlap === 100 && T.tables.thumb.every((x) => x.pad.startsWith('Pro Controller') === (x.grip === 'claw')); })(), JSON.stringify(T.tables.thumb.filter((r) => r.pad.startsWith('Pro')).map((r) => [r.pace, r.seq, r.move, r.median, r.overlap])));
    check('thumb transfer: the p90 is never below the median', T.tables.thumb.every((r) => r.p90 >= r.median));
    // the command line, end to end
    const r = spawnSync(process.execPath, [join(HERE, 'right-stick-analyse.mjs'), tmp, '--export-traces', join(tmp, 'tr'), '--json', join(tmp, 'tables.json')], { encoding: 'utf8' });
    check('the command prints the twelve tables and writes the traces and the json', r.status === 0 && /1\. Who took part/.test(r.stdout) && /11\. Against the proposed bars/.test(r.stdout) && /12\. Thumb transfer/.test(r.stdout) && existsSync(join(tmp, 'tr', 'ALPHA.traces.json')) && existsSync(join(tmp, 'tables.json')), (r.stderr || r.stdout).slice(0, 300));
    const trs = JSON.parse(readFileSync(join(tmp, 'tr', 'ALPHA.traces.json'), 'utf8'));
    const circles = trs.trials.filter((x) => x.block === 'circle');
    check('the exported traces keep each circle trial\'s direction (clockwise or anticlockwise) and each flick\'s sector', circles.length > 0 && circles.every((x) => x.dir === 'cw' || x.dir === 'ccw') && new Set(circles.map((x) => x.dir)).size === 2 && trs.trials.filter((x) => x.block === 'flick4').every((x) => Number.isInteger(x.sector)));
    const bad = spawnSync(process.execPath, [join(HERE, 'right-stick-analyse.mjs'), tmp, '--engine', 'godot'], { encoding: 'utf8' });
    check('the GDScript engine says plainly that its runner does not exist yet', bad.status === 1 && /godot-script/.test(bad.stderr), bad.stderr.slice(0, 200));
  }
} finally { rmSync(tmp, { recursive: true, force: true }); }

if (failed) { console.error(`right-stick self-test FAILED: ${failed} of ${ran} checks`); process.exit(1); }
console.log(`right-stick self-test ok: ${ran} checks${pyOk ? '' : ' (engine checks skipped: no python)'}`);
