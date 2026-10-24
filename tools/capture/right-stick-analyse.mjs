// Analysis of the right-stick captures (docs/controls/right-stick-capture.md, "The analysis"): reads the JSON files tools/capture/right-stick.html saves, turns every trial into the
// recognizer's input (one stick sample per 1/60 s tick), runs the recognizer (Controls' Python model today, the GDScript recognizer when it exists) and prints the tables the spec lists.
//
//   node tools/capture/right-stick-analyse.mjs <folder or files...> [--engine python|godot] [--rise 3] [--rises 2,3,4,5] [--by rating|pad|mode] [--pad-radius 60]
//        [--export-traces <dir>] [--json <file>] [--include-interrupted] [--no-quant] [--guard-mag 0.9] [--guard-ticks 6] [--python <exe>] [--model <right-stick-model.py>]
//        [--godot <exe> --godot-script res://<runner>.gd]
//
// Tables: who took part (against the spec's minimums); the confusion matrix per pattern and skill; direction accuracy four-way and eight-way (and the angle error); the span and rise-time
// distributions (to set the windows and the dial); the flick-versus-hold curve for rise times 2 to 5; false patterns a minute in free aim and at idle; R3 and L3 clicks per hard flick; rest and idle
// drift; the keyboard's timings; and a summary against the spec's proposed bars. --export-traces writes each person's per-trial ticks, so a threshold can be re-fitted.
//
// Conventions: the page records the stick as the browser reports it (y DOWN is positive); the recognizer wants y UP, so y is negated here. Sectors count from the right, anticlockwise: 0 right,
// 2 up, 4 left, 6 down. The recognizer runs at 60 ticks a second; a trace is resampled by holding the last sample at each tick (what the game would see). Every component is quantised to 1/16 before
// it goes in (the recognizer's own pipeline) unless --no-quant. A touch trace is the finger's offset from its first contact in dp divided by --pad-radius (60 dp = full deflection).
//
// The runner contract (so a GDScript runner can replace the Python one): in.json { traces: [{ id, ticks: [[x, y], ...] }], rises: [..] } -> out.json { results: [{ id, rise, events: [[name, detail, tick], ...] }] },
// name "flick" | "hold" (detail: sector) | "pattern" (detail: "pump" | "zigzag" | "quarter" | "half" | "full"). See right-stick-run.py.
import { existsSync, mkdirSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve, dirname, basename } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const TICK_MS = 1000 / 60;
const DZ = 0.25, ON = 0.6, LOW = 0.2;

// ------------------------------------------------------------------ pure helpers (exported for the self-test)
export const quant = (v) => Math.round(v * 16) / 16;
export function percentiles(a, ps = [5, 25, 50, 75, 95]) {
  if (!a.length) return ps.map(() => null);
  const s = a.slice().sort((x, y) => x - y);
  return ps.map((p) => { const i = (s.length - 1) * p / 100, lo = Math.floor(i), hi = Math.ceil(i); return s[lo] + (s[hi] - s[lo]) * (i - lo); });
}
export const pct = (n, d) => (d ? Math.round(1000 * n / d) / 10 : null);
export const rescale = (m) => (m < DZ ? 0 : (m - DZ) / (1 - DZ));

/** Resample a capture's trial to ticks of [x, y] (y up, -1..1). */
export function trialTicks(cap, tr, o = {}) {
  const quantise = o.quant !== false, radius = o.padRadius || 60;
  if (tr.i0 == null || tr.i1 == null || tr.start_f == null || tr.end_f == null) return null;
  const n = Math.max(1, Math.round((tr.end_f - tr.start_f) / TICK_MS));
  const out = [];
  const push = (x, y) => { const m = Math.hypot(x, y); if (m > 1) { x /= m; y /= m; } out.push(quantise ? [quant(x), quant(y)] : [x, y]); };
  if (cap.env.mode === 'gamepad') {
    const S = cap.samples; let j = tr.i0;
    for (let k = 0; k < n; k++) {
      const T = tr.start_f + k * TICK_MS;
      while (j + 1 < tr.i1 && S[j + 1][1] <= T) j++;
      const s = S[j]; if (!s || j >= tr.i1) { push(0, 0); continue; }
      push(s[2], -s[3]);
    }
  } else if (cap.env.mode === 'touch') {
    const E = cap.touch; let j = tr.i0, cur = null;
    for (let k = 0; k < n; k++) {
      const T = tr.start_f + k * TICK_MS;
      while (j < tr.i1 && E[j][1] <= T) { const e = E[j]; if (e[4] === 0 || e[4] === 1) cur = { id: e[5], x: e[2], y: e[3] }; else if (cur && cur.id === e[5]) cur = null; j++; }
      if (cur) push(cur.x / radius, -cur.y / radius); else push(0, 0);
    }
  } else {
    const K = cap.keys; let j = tr.i0; const down = {};
    // keys held when the window opened
    for (let q = 0; q < tr.i0; q++) { down[K[q][2]] = K[q][3] === 1; }
    for (let k = 0; k < n; k++) {
      const T = tr.start_f + k * TICK_MS;
      while (j < tr.i1 && K[j][1] <= T) { down[K[j][2]] = K[j][3] === 1; j++; }
      let x = 0, y = 0; if (down.ArrowRight) x += 1; if (down.ArrowLeft) x -= 1; if (down.ArrowUp) y += 1; if (down.ArrowDown) y -= 1;
      push(x, y);
    }
  }
  return out;
}

/** From a tick trace: the rise (ticks from last at-rest to first deflected), the onset angle and the active span. null when the stick never went on. */
export function traceStats(ticks) {
  let lastLow = -1, on = -1;
  for (let t = 0; t < ticks.length; t++) {
    const m = rescale(Math.hypot(ticks[t][0], ticks[t][1]));
    if (m <= LOW) lastLow = t;
    if (on < 0 && m >= ON) { on = t; break; }
  }
  let first = -1, last = -1, peak = 0;
  for (let t = 0; t < ticks.length; t++) {
    const m = rescale(Math.hypot(ticks[t][0], ticks[t][1]));
    if (m > peak) peak = m;
    if (m > 0.35) { if (first < 0) first = t; last = t; }
  }
  const out = { peak, span: first < 0 ? 0 : last - first + 1, rise: null, angle: null };
  if (on >= 0) {
    out.rise = on - lastLow;
    const q = ticks[Math.min(ticks.length - 1, on + 2)];
    out.angle = Math.atan2(q[1], q[0]) * 180 / Math.PI;
  }
  return out;
}
/** The R3 guard (docs/controls/right-stick.md, R10/R24): an R3 click is ignored while the stick is past `mag` (0.9, dead zone rescaled) or within `within` (6) ticks after it was. Returns true when the click SURVIVES (would act). Pure. */
export function guardSurvives(ticks, clickTick, mag = 0.9, within = 6) {
  for (let i = clickTick - within; i <= clickTick; i++) { if (i < 0 || i >= ticks.length) continue; if (rescale(Math.hypot(ticks[i][0], ticks[i][1])) > mag) return false; }
  return true;
}
export const angleErr = (a, sector) => { let d = (a - sector * 45) % 360; if (d > 180) d -= 360; if (d < -180) d += 360; return Math.abs(d); };

// ------------------------------------------------------------------ loading
export function loadCaptures(inputs) {
  const files = [];
  for (const p of inputs) {
    if (!existsSync(p)) { console.error(`right-stick-analyse: ${p} does not exist`); continue; }
    if (statSync(p).isDirectory()) for (const f of readdirSync(p).sort()) { if (/\.json$/i.test(f) && !/traces\.json$/i.test(f)) files.push(join(p, f)); } else files.push(p);
  }
  const caps = [];
  for (const f of files) {
    let j; try { j = JSON.parse(readFileSync(f, 'utf8')); } catch (e) { console.error(`right-stick-analyse: ${f}: not JSON (${e.message})`); continue; }
    if (!j || !/^meridian\.right-stick-capture\//.test(j.format || '')) { console.error(`right-stick-analyse: ${f}: not a right-stick capture, skipped`); continue; }
    j._file = basename(f); caps.push(j);
  }
  return caps;
}

// ------------------------------------------------------------------ the engines
function findPython(o) {
  const tries = o.python ? [[o.python, []]] : [['python', []], ['py', ['-3']], ['python3', []]];
  for (const [exe, pre] of tries) { const r = spawnSync(exe, [...pre, '--version'], { encoding: 'utf8' }); if (r.status === 0) return [exe, pre]; }
  return null;
}
export function runEngine(traces, rises, o = {}) {
  const dir = join(tmpdir(), `rsa-${process.pid}-${Date.now()}`); mkdirSync(dir, { recursive: true });
  const inp = join(dir, 'in.json'), out = join(dir, 'out.json');
  writeFileSync(inp, JSON.stringify({ traces, rises }));
  let r;
  if ((o.engine || 'python') === 'godot') {
    if (!o.godot || !o.godotScript) throw new Error('--engine godot needs --godot <exe> and --godot-script res://<runner>.gd (the GDScript recognizer’s runner; it does not exist yet)');
    r = spawnSync(o.godot, ['--headless', '--path', resolve(HERE, '..', '..'), '--script', o.godotScript, '--', `--in=${inp}`, `--out=${out}`], { encoding: 'utf8', maxBuffer: 1 << 28 });
  } else {
    const py = findPython(o); if (!py) throw new Error('no Python found (tried python, py -3, python3); give --python <exe>');
    const args = [...py[1], join(HERE, 'right-stick-run.py'), inp, out]; if (o.model) args.push('--model', o.model);
    r = spawnSync(py[0], args, { encoding: 'utf8', maxBuffer: 1 << 28 });
  }
  if (r.status !== 0 || !existsSync(out)) throw new Error(`the recognizer runner failed (exit ${r.status}): ${(r.stderr || r.stdout || '').slice(0, 400)}`);
  const res = JSON.parse(readFileSync(out, 'utf8'));
  const by = new Map(); for (const x of res.results) by.set(`${x.id}|${x.rise}`, x.events);
  return { model: res.model, events: (id, rise) => by.get(`${id}|${rise}`) || [] };
}

// ------------------------------------------------------------------ analysis
const BANDS = { new: 'new to sticks', regular: 'regular', fps_fighting: 'fighting/shooter' };
const PATTERN_LABELS = ['pump', 'zigzag', 'quarter', 'half', 'full'];
export function promptLabel(tr) {
  const e = tr.expect || {};
  if (e.kind === 'zigzag') return `zigzag-${e.axis === 'vertical' ? 'v' : 'h'}`;
  if (['quarter', 'half', 'full'].includes(e.kind)) return e.kind;
  return e.kind;
}
// what counts as the pattern being recognised (Controls to confirm: a vertical zig-zag is the model's "pump")
export const ACCEPT = { 'zigzag-h': ['zigzag'], 'zigzag-v': ['pump', 'zigzag'], quarter: ['quarter'], half: ['half'], full: ['full'] };

export function analyse(caps, o = {}) {
  const rises = o.rises || [2, 3, 4, 5], rise = o.rise || 3, groupBy = o.by || 'rating';
  const traces = [], meta = [];
  const people = [];
  for (const cap of caps) {
    const who = cap.person.code || cap._file;
    const p = { code: who, rating: cap.person.rating, mode: cap.env.mode, pad: cap.person.pad_model || '-', hz: cap.env.frame_hz_estimate, complete: cap.complete, trials: 0, interrupted: 0, file: cap._file };
    cap.trials.forEach((tr, ti) => {
      p.trials++; if (tr.interrupted) p.interrupted++;
      if (tr.interrupted && !o.includeInterrupted) return;
      const ticks = trialTicks(cap, tr, o); if (!ticks) return;
      const id = `${who}#${ti}`;
      traces.push({ id, ticks });
      meta.push({ id, cap, tr, who, ticks, band: cap.person.rating, pad: cap.person.pad_model || '-', mode: cap.env.mode, kind: tr.expect.kind, label: promptLabel(tr), stats: traceStats(ticks) });
    });
    people.push(p);
  }
  const eng = traces.length ? runEngine(traces, rises, o) : { model: null, events: () => [] };
  for (const m of meta) { m.ev = {}; for (const r of rises) m.ev[r] = eng.events(m.id, r); }
  const key = (m) => (groupBy === 'pad' ? m.pad : groupBy === 'mode' ? m.mode : m.band);
  const groups = [...new Set(meta.map(key))].sort();
  const T = { people, model: eng.model, rises, rise, groupBy, tables: {} };

  // ---- 1. who took part
  const bands = new Set(people.map((p) => p.rating)), pads = new Set(people.filter((p) => p.mode === 'gamepad').map((p) => p.pad));
  T.tables.participation = { people: people.length, bands: [...bands], pads: [...pads], minimums: { people: 8, bands: 3, pads: 4 }, meets: people.length >= 8 && bands.size >= 3 && pads.size >= 4 };

  // ---- 2. confusion per pattern and group
  const conf = {};
  for (const m of meta.filter((x) => ['zigzag', 'quarter', 'half', 'full'].includes(x.kind))) {
    const evs = m.ev[rise].filter((e) => e[0] === 'pattern'), got = evs.length ? evs[evs.length - 1][1] : 'none';
    const g = key(m); conf[g] = conf[g] || {}; const row = (conf[g][m.label] = conf[g][m.label] || { n: 0, got: {} });
    row.n++; row.got[got] = (row.got[got] || 0) + 1;
  }
  T.tables.confusion = conf;
  const recall = {};
  for (const [g, rows] of Object.entries(conf)) { let ok = 0, n = 0; for (const [lab, r] of Object.entries(rows)) { n += r.n; for (const a of ACCEPT[lab] || []) ok += r.got[a] || 0; } recall[g] = { n, ok, pct: pct(ok, n) }; }
  T.tables.patternRecall = recall;

  // ---- 3. double flicks
  const pump = meta.filter((m) => m.kind === 'pump');
  T.tables.doubleFlick = { n: pump.length, flicksPerTrial: {}, gapTicks: percentiles(pump.flatMap((m) => { const f = m.ev[rise].filter((e) => e[0] === 'flick'); return f.length >= 2 ? [f[1][2] - f[0][2]] : []; })) };
  for (const m of pump) { const c = m.ev[rise].filter((e) => e[0] === 'flick').length; T.tables.doubleFlick.flicksPerTrial[c] = (T.tables.doubleFlick.flicksPerTrial[c] || 0) + 1; }

  // ---- 4. direction accuracy (per rise)
  const dirRows = {};
  for (const r of rises) {
    for (const [name, sel] of [['four-way comfortable', (m) => m.tr.block === 'flick4' && m.tr.speed === 'comfortable'], ['four-way fast', (m) => m.tr.block === 'flick4' && m.tr.speed === 'fast'], ['eight-way', (m) => m.tr.block === 'flick8']]) {
      for (const g of groups) {
        const ms = meta.filter((m) => sel(m) && key(m) === g); if (!ms.length) continue;
        let seen = 0, exact = 0, near = 0; const errs = [];
        for (const m of ms) {
          const fl = m.ev[r].filter((e) => e[0] === 'flick'); if (fl.length) { seen++; const d = Math.min((fl[0][1] - m.tr.expect.sector + 8) % 8, (m.tr.expect.sector - fl[0][1] + 8) % 8); if (d === 0) exact++; if (d <= 1) near++; }
          if (r === rise && m.stats.angle != null) errs.push(angleErr(m.stats.angle, m.tr.expect.sector));
        }
        const row = (dirRows[`${name}|${g}|${r}`] = { set: name, group: g, rise: r, n: ms.length, flick: pct(seen, ms.length), exact: pct(exact, ms.length), within1: pct(near, ms.length) });
        if (r === rise) row.angleErr = percentiles(errs, [50, 95]);
      }
    }
  }
  T.tables.direction = Object.values(dirRows);

  // ---- 5. spans and rise times
  const spans = {};
  for (const m of meta) {
    if (['zigzag', 'quarter', 'half', 'full', 'pump'].includes(m.kind)) (spans[`span ${m.label} (ticks)`] = spans[`span ${m.label} (ticks)`] || []).push(m.stats.span);
    if (m.kind === 'flick' && m.stats.rise != null) (spans[`rise ${m.tr.block} ${m.tr.speed} (ticks)`] = spans[`rise ${m.tr.block} ${m.tr.speed} (ticks)`] || []).push(m.stats.rise);
    if (m.kind === 'hold' && m.stats.rise != null) (spans['rise hold (ticks)'] = spans['rise hold (ticks)'] || []).push(m.stats.rise);
  }
  T.tables.distributions = Object.fromEntries(Object.entries(spans).sort().map(([k, a]) => [k, { n: a.length, p: percentiles(a) }]));

  // ---- 6. flick versus hold, per rise
  const fh = [];
  for (const r of rises) {
    const f = meta.filter((m) => m.tr.block === 'flick4' || m.tr.block === 'flick8'), h = meta.filter((m) => m.kind === 'hold');
    fh.push({
      rise: r, flicks: f.length, flickRead: pct(f.filter((m) => m.ev[r].some((e) => e[0] === 'flick')).length, f.length),
      holds: h.length, holdRead: pct(h.filter((m) => m.ev[r].some((e) => e[0] === 'hold')).length, h.length), holdAlsoFlick: pct(h.filter((m) => m.ev[r].some((e) => e[0] === 'flick')).length, h.length)
    });
  }
  T.tables.flickVsHold = fh;

  // ---- 7. false patterns a minute
  const fp = {};
  for (const kind of ['free', 'idle']) {
    for (const g of groups.concat(['all'])) {
      const ms = meta.filter((m) => m.kind === kind && (g === 'all' || key(m) === g)); if (!ms.length) continue;
      const minutes = ms.reduce((s, m) => s + m.ticks.length * TICK_MS / 60000, 0);
      const count = ms.reduce((s, m) => s + m.ev[rise].filter((e) => e[0] === 'pattern').length, 0);
      fp[`${kind}|${g}`] = { kind, group: g, trials: ms.length, minutes: Math.round(minutes * 100) / 100, patterns: count, perMinute: minutes ? Math.round(100 * count / minutes) / 100 : null };
    }
  }
  T.tables.falsePatterns = Object.values(fp);

  // ---- 8. clicks on hard flicks
  const hard = meta.filter((m) => m.kind === 'hard' && m.mode === 'gamepad');
  const clicks = hard.map((m) => {
    const B = m.cap.buttons.slice(m.tr.b0 == null ? 0 : m.tr.b0, m.cap.buttons.length).filter((b) => b[1] >= m.tr.start_f && b[1] <= m.tr.end_f + 300 && b[3] === 1 && (b[2] === 10 || b[2] === 11));
    const r3 = B.filter((b) => b[2] === 11);
    const survive = r3.filter((b) => guardSurvives(m.ticks, Math.ceil((b[1] - m.tr.start_f) / TICK_MS), o.guardMag || 0.9, o.guardTicks || 6)).length;
    return { who: m.who, pad: m.pad, n: B.length, r3: r3.length, l3: B.filter((b) => b[2] === 10).length, r3Survive: survive, standard: m.cap.env.gamepad && m.cap.env.gamepad.mapping === 'standard' };
  });
  const clickBy = {};
  for (const c of clicks) { const r = (clickBy[c.pad] = clickBy[c.pad] || { pad: c.pad, trials: 0, clicks: 0, withClick: 0, r3: 0, l3: 0, r3Survive: 0, standard: c.standard }); r.trials++; r.clicks += c.n; r.withClick += c.n ? 1 : 0; r.r3 += c.r3; r.l3 += c.l3; r.r3Survive += c.r3Survive; }
  T.tables.hardClicks = { trials: clicks.length, clicks: clicks.reduce((s, c) => s + c.n, 0), withClick: clicks.filter((c) => c.n).length, perFlick: clicks.length ? Math.round(100 * clicks.reduce((s, c) => s + c.n, 0) / clicks.length) / 100 : null, r3: clicks.reduce((s, c) => s + c.r3, 0), r3Survive: clicks.reduce((s, c) => s + c.r3Survive, 0), r3SurvivePer100: clicks.length ? Math.round(1000 * clicks.reduce((s, c) => s + c.r3Survive, 0) / clicks.length) / 10 : null, guard: { mag: o.guardMag || 0.9, ticks: o.guardTicks || 6 }, byPad: Object.values(clickBy) };

  // ---- 9. rest and idle drift
  T.tables.drift = [];
  for (const kind of ['rest', 'idle']) {
    for (const p of [...new Set(meta.filter((m) => m.kind === kind).map((m) => m.who))]) {
      const ms = meta.filter((m) => m.kind === kind && m.who === p); const xs = ms.flatMap((m) => m.ticks.map((t) => t[0])), ys = ms.flatMap((m) => m.ticks.map((t) => t[1]));
      const mean = (a) => a.reduce((s, v) => s + v, 0) / (a.length || 1);
      T.tables.drift.push({ kind, who: p, meanX: Math.round(1000 * mean(xs)) / 1000, meanY: Math.round(1000 * mean(ys)) / 1000, maxMag: Math.round(1000 * Math.max(0, ...ms.flatMap((m) => m.ticks.map((t) => Math.hypot(t[0], t[1]))))) / 1000 });
    }
  }

  // ---- 10. the keyboard
  const kb = meta.filter((m) => m.mode === 'keyboard' && (m.tr.block === 'flick4' || m.tr.block === 'flick8'));
  if (kb.length) {
    const dwell = [];
    for (const m of kb) { const K = m.cap.keys.slice(m.tr.i0, m.tr.i1); const dn = {}; for (const k of K) { if (k[3] === 1 && !k[4]) dn[k[2]] = k[1]; else if (k[3] === 0 && dn[k[2]] != null) { dwell.push(k[1] - dn[k[2]]); delete dn[k[2]]; } } }
    T.tables.keyboard = { trials: kb.length, dwellMs: percentiles(dwell) };
  }

  // ---- 11. against the proposed bars (at `rise`)
  const bar = [];
  const all4 = meta.filter((m) => m.tr.block === 'flick4' && m.tr.speed === 'comfortable');
  if (all4.length) { const ok = all4.filter((m) => { const fl = m.ev[rise].filter((e) => e[0] === 'flick'); return fl.length && fl[0][1] === m.tr.expect.sector; }).length; bar.push({ measure: 'four-way flick recall and direction', bar: '>= 95%', value: pct(ok, all4.length), pass: pct(ok, all4.length) >= 95 }); }
  const holds = meta.filter((m) => m.kind === 'hold');
  if (holds.length) { const ok = holds.filter((m) => m.ev[rise].some((e) => e[0] === 'hold')).length; bar.push({ measure: 'hold read as a hold', bar: '>= 98%', value: pct(ok, holds.length), pass: pct(ok, holds.length) >= 98 }); }
  for (const [g, r] of Object.entries(recall)) {
    const need = g === 'fps_fighting' ? 95 : g === 'new' || g === 'regular' ? 85 : 85;
    bar.push({ measure: `pattern recall, ${g}`, bar: `>= ${need}%`, value: r.pct, pass: r.pct >= need, note: `n ${r.n}` });
  }
  const free = fp['free|all'], idle = fp['idle|all'];
  if (free) bar.push({ measure: 'false patterns a minute, free aim', bar: '<= 1 (none, with patterns off in Aim)', value: free.perMinute, pass: free.perMinute <= 1 });
  if (idle) bar.push({ measure: 'false patterns at idle', bar: '0', value: idle.patterns, pass: idle.patterns === 0 });
  if (T.tables.hardClicks.trials) {
    bar.push({ measure: 'stick clicks per hard flick (R3 or L3, raw, before the guard)', bar: 'information', value: T.tables.hardClicks.perFlick, pass: null, note: `${T.tables.hardClicks.withClick} of ${T.tables.hardClicks.trials} hard flicks clicked` });
    bar.push({ measure: 'R3 clicks the guard lets through, per 100 hard flicks', bar: '< 1 (accidental Escapes under 1 in 100)', value: T.tables.hardClicks.r3SurvivePer100, pass: T.tables.hardClicks.r3SurvivePer100 < 1, note: `guard: ignore past ${T.tables.hardClicks.guard.mag} or within ${T.tables.hardClicks.guard.ticks} ticks; ${T.tables.hardClicks.r3Survive} of ${T.tables.hardClicks.r3} R3 clicks survive` });
  }
  T.tables.bars = bar;
  T.meta = meta;
  return T;
}

// ------------------------------------------------------------------ printing
const f = (v, w = 6) => String(v == null ? '-' : v).padStart(w);
function show(T) {
  const L = [];
  const h = (s) => { L.push(''); L.push(s); L.push('-'.repeat(s.length)); };
  L.push(`right-stick analysis: ${T.people.length} capture(s); recognizer ${T.model ? JSON.stringify(T.model) : '(none ran)'}; tables at flick rise ${T.rise}, grouped by ${T.groupBy}`);
  h('1. Who took part');
  for (const p of T.people) L.push(`  ${p.code.padEnd(14)} ${String(BANDS[p.rating] || p.rating).padEnd(18)} ${p.mode.padEnd(9)} ${String(p.hz).padStart(5)} Hz  ${p.complete ? 'complete' : 'partial '}  trials ${p.trials}${p.interrupted ? ` (${p.interrupted} interrupted)` : ''}  ${p.pad}`);
  const pt = T.tables.participation;
  L.push(`  people ${pt.people} (spec: at least ${pt.minimums.people}), skill bands ${pt.bands.length} (${pt.minimums.bands}), pad models ${pt.pads.length} (${pt.minimums.pads}): ${pt.meets ? 'meets the spec' : 'below the spec'}`);
  h('2. Confusion matrix: prompted pattern (rows) against what was recognised (columns)');
  const cols = [...PATTERN_LABELS, 'none'];
  for (const [g, rows] of Object.entries(T.tables.confusion)) {
    L.push(`  ${g}   ${['n', ...cols].map((c) => c.padStart(8)).join('')}`);
    for (const [lab, r] of Object.entries(rows).sort()) L.push(`    ${lab.padEnd(10)} ${f(r.n, 8)}${cols.map((c) => f(pct(r.got[c] || 0, r.n), 8)).join('')}`);
    L.push(`    recall ${T.tables.patternRecall[g].pct}% of ${T.tables.patternRecall[g].n} (a vertical zig-zag counts as pump or zig-zag)`);
  }
  if (!Object.keys(T.tables.confusion).length) L.push('  (no pattern trials)');
  h('3. Double flicks (the pump prompt): flicks the recognizer saw, and the gap between them');
  const df = T.tables.doubleFlick; L.push(`  trials ${df.n}; flick events per trial ${JSON.stringify(df.flicksPerTrial)}; ticks between the first two flicks p5/25/50/75/95 ${df.gapTicks.map((v) => (v == null ? '-' : Math.round(v))).join(' / ')}`);
  h(`4. Direction accuracy (percent of trials; flick = a flick was read, exact = the right sector, within1 = right or next to it)`);
  L.push(`  ${'set'.padEnd(22)} ${'group'.padEnd(14)} rise  n  flick exact within1  angle error median/p95 (deg, at rise ${T.rise})`);
  for (const r of T.tables.direction) L.push(`  ${r.set.padEnd(22)} ${String(r.group).padEnd(14)} ${f(r.rise, 4)} ${f(r.n, 3)} ${f(r.flick, 6)} ${f(r.exact, 5)} ${f(r.within1, 7)}  ${r.angleErr ? r.angleErr.map((v) => (v == null ? '-' : v.toFixed(1))).join(' / ') : ''}`);
  h('5. Distributions, in ticks (60 a second): p5 / p25 / p50 / p75 / p95 (to set the windows and the dial)');
  for (const [k, v] of Object.entries(T.tables.distributions)) L.push(`  ${k.padEnd(40)} n ${f(v.n, 4)}   ${v.p.map((x) => f(x == null ? null : Math.round(x * 10) / 10, 6)).join('')}`);
  h('6. Flick versus hold, by rise time (the dial): percent of trials');
  L.push('  rise  flicks  read-as-flick  holds  read-as-hold  hold-also-flick');
  for (const r of T.tables.flickVsHold) L.push(`  ${f(r.rise, 4)} ${f(r.flicks, 7)} ${f(r.flickRead, 14)} ${f(r.holds, 6)} ${f(r.holdRead, 13)} ${f(r.holdAlsoFlick, 16)}`);
  h('7. False patterns a minute (the recognizer with patterns on)');
  for (const r of T.tables.falsePatterns) L.push(`  ${r.kind.padEnd(5)} ${String(r.group).padEnd(14)} trials ${f(r.trials, 3)}  ${f(r.minutes, 6)} min  ${f(r.patterns, 3)} patterns  ${f(r.perMinute, 6)} a minute`);
  h('8. R3 and L3 clicks on hard flicks (gamepad)');
  const hc = T.tables.hardClicks;
  if (!hc.trials) L.push('  (no hard-flick trials on a pad)'); else {
    L.push(`  raw: ${hc.trials} hard flicks, ${hc.clicks} clicks (${hc.perFlick} a flick), ${hc.withClick} flicks with a click`);
    L.push(`  with the R3 guard (ignore past ${hc.guard.mag} or within ${hc.guard.ticks} ticks of it): ${hc.r3Survive} of ${hc.r3} R3 clicks survive = ${hc.r3SurvivePer100} per 100 hard flicks (the bar is under 1)`);
    for (const r of hc.byPad) L.push(`  ${r.pad.slice(0, 50).padEnd(50)} flicks ${f(r.trials, 3)} clicks ${f(r.clicks, 3)} (R3 ${r.r3}, of which ${r.r3Survive} past the guard; L3 ${r.l3})${r.standard ? '' : '  [layout not standard: button numbers may differ]'}`);
  }
  h('9. Rest and idle drift (stick units after quantising)');
  for (const r of T.tables.drift) L.push(`  ${r.kind.padEnd(5)} ${r.who.padEnd(14)} mean x ${f(r.meanX, 7)} y ${f(r.meanY, 7)}  largest ${f(r.maxMag, 6)}`);
  if (!T.tables.drift.length) L.push('  (none)');
  if (T.tables.keyboard) { h('10. Keyboard'); L.push(`  ${T.tables.keyboard.trials} flick trials; key down time p5/25/50/75/95 (ms) ${T.tables.keyboard.dwellMs.map((v) => (v == null ? '-' : Math.round(v))).join(' / ')}`); }
  h(`11. Against the proposed bars (docs/controls/right-stick-capture.md), at flick rise ${T.rise}`);
  for (const b of T.tables.bars) L.push(`  ${b.pass === true ? 'PASS' : b.pass === false ? 'FAIL' : 'INFO'}  ${b.measure.padEnd(58)} bar ${b.bar.padEnd(34)} got ${b.value}${b.note ? `  (${b.note})` : ''}`);
  if (!T.tables.bars.length) L.push('  (not enough trials)');
  return L.join('\n');
}

// ------------------------------------------------------------------ main
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const opt = (n, d) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : d; };
  const flagsWithValue = new Set(['--guard-mag', '--guard-ticks', '--engine', '--rise', '--rises', '--by', '--pad-radius', '--export-traces', '--json', '--python', '--model', '--godot', '--godot-script']);
  const inputs = []; for (let i = 0; i < args.length; i++) { if (args[i].startsWith('--')) { if (flagsWithValue.has(args[i])) i++; } else inputs.push(args[i]); }
  if (!inputs.length) { console.error('usage: node tools/capture/right-stick-analyse.mjs <folder or files...> [--engine python|godot] [--rise 3] [--rises 2,3,4,5] [--by rating|pad|mode] [--pad-radius 60] [--export-traces <dir>] [--json <file>] [--include-interrupted] [--no-quant] [--guard-mag 0.9] [--guard-ticks 6]'); process.exit(2); }
  const caps = loadCaptures(inputs);
  if (!caps.length) { console.error('right-stick-analyse: no captures found'); process.exit(1); }
  const o = {
    engine: opt('--engine', 'python'), rise: Number(opt('--rise', 3)), rises: opt('--rises', '2,3,4,5').split(',').map(Number), by: opt('--by', 'rating'), padRadius: Number(opt('--pad-radius', 60)),
    includeInterrupted: args.includes('--include-interrupted'), quant: !args.includes('--no-quant'), guardMag: Number(opt('--guard-mag', 0.9)), guardTicks: Number(opt('--guard-ticks', 6)), python: opt('--python'), model: opt('--model'), godot: opt('--godot'), godotScript: opt('--godot-script')
  };
  if (!o.rises.includes(o.rise)) o.rises.push(o.rise);
  let T;
  try { T = analyse(caps, o); } catch (e) { console.error(`right-stick-analyse: ${e.message}`); process.exit(1); }
  console.log(show(T));
  const ex = opt('--export-traces');
  if (ex) {
    mkdirSync(ex, { recursive: true });
    const byWho = {};
    for (const m of T.meta) (byWho[m.who] = byWho[m.who] || []).push({ id: m.id, block: m.tr.block, prompt: m.tr.prompt, n: m.tr.n, speed: m.tr.speed, expect: m.tr.expect, dir: m.tr.expect.dir || null, sector: m.tr.expect.sector == null ? null : m.tr.expect.sector, label: m.tr.label || null, ticks: m.ticks });
    for (const [who, trials] of Object.entries(byWho)) writeFileSync(join(ex, `${who}.traces.json`), JSON.stringify({ format: 'meridian.right-stick-traces/1', person: who, tick_hz: 60, y_up: true, trials }));
    console.log(`\nper-person traces written to ${ex}`);
  }
  const js = opt('--json');
  if (js) { const { meta, ...rest } = T; writeFileSync(js, JSON.stringify(rest, null, 1)); console.log(`tables written to ${js}`); }
}
