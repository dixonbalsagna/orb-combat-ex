// Half 1 of the photosensitivity check: the count. Reads the run files the headless scenario tool writes (tools/flash/flash_worst.gd: one JSON per scenario and mode,
// with the flash register's whole log) and recounts every window from the rows themselves, independently of the register's own running figure.
//
//   node tools/flash/check-log.js <dir | file.json ...> [--sources tools/flash/sources.json] [--allow-missing]
//
// A run FAILS when any window of 60 clock ticks holds more than 3 granted flashes (more than 1 when the run was played under reduced flashing). The whole check
// FAILS when a scenario of the required set is missing, a scenario did not show the events it exists to show (so a run that played nothing proves nothing), a log
// is full (the register keeps its last 2,400 asks), or no flash was asked in any run.
// It also reports, plainly, which flash sources are not under the register today (tools/flash/sources.json) and the proxy counts for them. It never says "safe".
'use strict';
const fs = require('fs');
const path = require('path');

const WINDOW = 60, CAP = 3, CAP_REDUCED = 1, LOG_MAX = 2400;
const SOURCES = path.join(__dirname, 'sources.json');

function loadSources(file) { return JSON.parse(fs.readFileSync(file || SOURCES, 'utf8')); }

/** The most granted flashes in any window of WINDOW ticks, from rows [now, tick, source, granted, why, in_window]. */
function worstWindow(rows) {
  const ts = rows.filter((r) => r[3] === true).map((r) => r[0]).sort((a, b) => a - b);
  let worst = 0, at = -1;
  for (let i = 0, j = 0; i < ts.length; i++) {
    if (j < i) j = i;
    while (j < ts.length && ts[j] < ts[i] + WINDOW) j++;
    if (j - i > worst) { worst = j - i; at = ts[i]; }
  }
  return { worst, at };
}

/** One run object -> { pass, worst, cap, ... }. */
function checkRun(run, src) {
  const known = new Set(src ? [...src.counted, ...src.reserved] : [...loadSources().counted, ...loadSources().reserved]);
  const cap = run.reduced ? CAP_REDUCED : CAP;
  const rows = run.rows || [];
  const w = worstWindow(rows);
  const bySource = {};
  for (const r of rows) {
    const s = (bySource[r[2]] = bySource[r[2]] || { granted: 0, refused: 0, unregulated: 0 });
    if (r[3]) { s.granted++; if (r[4] === 'unregulated') s.unregulated++; } else s.refused++;
  }
  const unknownSources = Object.keys(bySource).filter((s) => !known.has(s));
  const truncated = rows.length >= LOG_MAX || (run.asked != null && run.asked > rows.length);
  // a grant of a red flash is a rule break on its own
  const red = rows.filter((r) => r[3] === true && r[4] === 'red').length;
  // the register's own figure, for comparison: it must agree with the recount
  const own = run.summary && typeof run.summary.worst_second === 'number' ? run.summary.worst_second : null;
  const agree = own === null || own === w.worst;
  return { scenario: run.scenario, reduced: !!run.reduced, worst: w.worst, at: w.at, cap, asks: rows.length, bySource, unknownSources, truncated, redGranted: red, ownWorst: own, agree, pass: w.worst <= cap && red === 0 && !truncated && agree };
}

function loadRuns(args) {
  const files = [];
  for (const a of args) {
    if (!fs.existsSync(a)) throw new Error(`no such file or folder: ${a}`);
    if (fs.statSync(a).isDirectory()) for (const f of fs.readdirSync(a).sort()) { if (/^flash-.*\.json$/.test(f)) files.push(path.join(a, f)); }
    else files.push(a);
  }
  return files.map((f) => Object.assign(JSON.parse(fs.readFileSync(f, 'utf8')), { _file: f }));
}

function main(argv) {
  const opt = (n) => { const i = argv.indexOf(n); return i >= 0 ? argv[i + 1] : null; };
  const allowMissing = argv.includes('--allow-missing');
  const srcFile = opt('--sources');
  const args = argv.filter((a, i) => !a.startsWith('--') && argv[i - 1] !== '--sources');
  if (!args.length) { console.error('usage: node tools/flash/check-log.js <dir | file.json ...> [--sources file] [--allow-missing]'); return 2; }
  const src = loadSources(srcFile);
  let runs;
  try { runs = loadRuns(args); } catch (e) { console.error(e.message); return 2; }
  if (!runs.length) { console.error('no flash-*.json run files found'); return 2; }

  let fail = 0;
  const problems = [];
  const results = runs.map((r) => ({ run: r, res: checkRun(r, src) }));
  console.log(`${'scenario'.padEnd(11)} ${'mode'.padEnd(8)} ${'seed'.padStart(6)} ${'ticks'.padStart(6)} ${'asks'.padStart(5)} ${'granted'.padStart(8)} ${'worst/60'.padStart(9)} ${'cap'.padStart(4)}  result`);
  for (const { run, res } of results) {
    const granted = Object.values(res.bySource).reduce((n, s) => n + s.granted, 0);
    const why = [];
    if (res.worst > res.cap) why.push(`${res.worst} in the 60 ticks from ${res.at}`);
    if (res.redGranted) why.push(`${res.redGranted} red flashes granted`);
    if (res.truncated) why.push('the log is full, so earlier asks are missing');
    if (!res.agree) why.push(`the register's own figure (${res.ownWorst}) disagrees with the recount (${res.worst})`);
    if (!res.pass) fail++;
    console.log(`${String(res.scenario).padEnd(11)} ${(res.reduced ? 'reduced' : 'normal').padEnd(8)} ${String(run.seed ?? '?').padStart(6)} ${String(run.ticks ?? '?').padStart(6)} ${String(res.asks).padStart(5)} ${String(granted).padStart(8)} ${String(res.worst).padStart(9)} ${String(res.cap).padStart(4)}  ${res.pass ? 'ok' : 'FAIL: ' + why.join('; ')}`);
    if (res.unknownSources.length) problems.push(`${run.scenario}: flash source(s) not in tools/flash/sources.json: ${res.unknownSources.join(', ')} (add them there, as counted or reserved, so the report states whether they are under the register)`);
  }

  // coverage: the required scenarios, in both modes, and the events each exists to show
  for (const sc of src.scenarios) {
    for (const mode of [false, true]) {
      const got = results.filter((x) => x.run.scenario === sc.id && !!x.run.reduced === mode);
      if (!got.length) { if (!allowMissing) problems.push(`scenario ${sc.id} (${mode ? 'reduced' : 'normal'}) is missing`); continue; }
      for (const g of got) {
        const ev = g.run.events || {};
        for (const [k, min] of Object.entries(sc.minEvents || {})) {
          if ((ev[k] || 0) < min) problems.push(`scenario ${sc.id} seed ${g.run.seed} (${mode ? 'reduced' : 'normal'}) did not show ${k} (${ev[k] || 0}, needs ${min}): a run that does not play the case proves nothing`);
        }
        if ((g.run.ticks || 0) < (sc.minTicks || 0)) problems.push(`scenario ${sc.id} seed ${g.run.seed} (${mode ? 'reduced' : 'normal'}) ran ${g.run.ticks} ticks, needs ${sc.minTicks}`);
      }
    }
  }
  for (const { run } of results) {
    if (run.reduced && run.reduced_seen === false) problems.push(`scenario ${run.scenario} seed ${run.seed}: asked for reduced flashing but the register never ran reduced (its cap stayed 3), so the 1-a-second check did not apply`);
  }
  // the AI-match set: every pairing at every seed in both modes, and across a pairing's seeds both fighters fire their signature
  for (const pr of src.pairings || []) {
    const mine = results.filter((x) => x.run.scenario === 'ai' && Array.isArray(x.run.slots) && x.run.slots[0] === pr.slots[0] && x.run.slots[1] === pr.slots[1]);
    for (const seed of pr.seeds) for (const mode of [false, true]) {
      if (!mine.some((x) => x.run.seed === seed && !!x.run.reduced === mode) && !allowMissing) problems.push(`AI match ${pr.slots.join(' v ')} seed ${seed} (${mode ? 'reduced' : 'normal'}) is missing from the runs`);
    }
    for (const id of pr.needSignatures) {
      const n = mine.filter((x) => !x.run.reduced).reduce((a, x) => a + ((x.run.events || {})['sig:' + id] || 0), 0);
      if (n < 1 && !allowMissing) problems.push(`the AI matches of ${pr.slots.join(' v ')} never show ${id} firing its signature: add a seed that does (tools/flash/seed_scan.gd lists them)`);
    }
  }
  const totalAsks = results.reduce((n, x) => n + x.res.asks, 0);
  if (!totalAsks) problems.push('no flash was asked in any run: the register was never exercised');

  // totals by source across every run
  const tot = {};
  for (const { res } of results) for (const [s, v] of Object.entries(res.bySource)) { const t = (tot[s] = tot[s] || { granted: 0, refused: 0 }); t.granted += v.granted; t.refused += v.refused; }
  console.log(`\nflashes asked in these runs, by source (granted, refused): ${Object.entries(tot).map(([s, v]) => `${s} ${v.granted}/${v.refused}`).join(', ') || 'none'}`);

  // proxies for the sources that are not under the register
  const seen = new Set(Object.keys(tot));
  const absent = src.reserved.filter((s) => !seen.has(s));
  console.log(`\nNOT COUNTED TODAY (no ask in any log; the register cannot see them): ${absent.length ? absent.join(', ') : 'none: every reserved source now asks'}`);
  for (const s of src.reserved) {
    const note = (src.reservedNotes || {})[s];
    console.log(`  ${seen.has(s) ? 'counted ' : 'UNCOUNTED'} ${s}${note ? ': ' + note : ''}`);
  }
  for (const [s, note] of Object.entries(src.outside || {})) console.log(`  OUTSIDE   ${s}: ${note}`);
  const prox = results.filter((x) => x.run.proxy && x.run.proxy.body_hit);
  if (prox.length) {
    const worstProxy = Math.max(...prox.map((x) => x.run.proxy.body_hit.worst_flashes_per_second));
    console.log(`\nbody hit flash (Rendering's, white whole body for ${prox[0].run.proxy.body_hit.seconds} s a hit), counted by proxy from the sim's hurt time, not from the register: worst ${worstProxy} flash starts on one body in any 60 ticks over these runs`);
    for (const x of prox) console.log(`  ${String(x.run.scenario).padEnd(11)} ${(x.run.reduced ? 'reduced' : 'normal').padEnd(8)} body flashes starting in 60 ticks: fighter 0 ${x.run.proxy.body_hit.worst_per_fighter[0]}, fighter 1 ${x.run.proxy.body_hit.worst_per_fighter[1]}`);
    console.log('  (advisory: a body is a small part of the frame, and whether a flash that size counts is what the pixel analyser, half 2, decides)');
  }

  for (const p of problems) console.log(`PROBLEM: ${p}`);
  const ok = fail === 0 && problems.length === 0;
  console.log(ok
    ? `\nflash count passed: no window of 60 ticks grants more than ${CAP} (${CAP_REDUCED} under reduced flashing) in ${results.length} runs. This is the register's count of the sources that ask it; it is not a luminance measurement and not a clearance.`
    : `\nflash count FAILED (${fail} run${fail === 1 ? '' : 's'} over the cap, ${problems.length} problem${problems.length === 1 ? '' : 's'})`);
  return ok ? 0 : 1;
}

module.exports = { checkRun, worstWindow, loadSources, WINDOW, CAP, CAP_REDUCED };
if (require.main === module) process.exit(main(process.argv.slice(2)));
