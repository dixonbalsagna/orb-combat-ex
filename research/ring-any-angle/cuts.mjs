// The cost cuts for the turntable, against 0.2 ms a tick of reads and the 8 ms spike. Paths come from archField's own fights (or
// a flat-out crossing with swings); every read is counted on a cube-sphere of nested grids, without running the noise except where
// an error is measured. Counts are deterministic; ms are counts x World's cost a read and my look-up figures, not timings.
//   node research/ring-any-angle/cuts.mjs [--seeds=3] [--ticks=7200]
import { readFileSync, writeFileSync } from 'node:fs';
import { performance } from 'node:perf_hooks';
import { surf } from '../planet-gen/gen/base.mjs';
import { sin, cos, atan2f, R } from '../planet-gen/lib/det.mjs';

const arg = (k, d) => { const a = process.argv.find((x) => x.startsWith('--' + k + '=')); return a ? +a.split('=')[1] : d; };
const code = readFileSync(new URL('./sim.js', import.meta.url), 'utf8');
const RAA = new Function('surf', 'sin', 'cos', 'atan2f', 'R', code + '\nreturn RAA;')(surf, sin, cos, atan2f, R);
const SEEDS = arg('seeds', 3), TICKS = arg('ticks', 7200), COL = RAA.COL, RP = R, SEED = 7;
// Ms a gen 2 read: 54 us native, 130 us web, 0.8 ms at the laptop's x4 (performance.md section 1). Budget 0.2 ms a tick at x1 and
// a spike of 8 ms at x1, so reads a tick and a spike's reads depend on the build.
const READ = { native: 0.054, web: 0.13, laptop: 0.8 }, BUDGET = 0.2, SPIKE = 8;
const out = { TICKS, SEEDS, READ, BUDGET, SPIKE };
const norm = (a) => { const l = Math.sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2]); return [a[0] / l, a[1] / l, a[2] / l]; };
const cross = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
const dot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
const pct = (a, q) => { if (!a.length) return 0; const s = Float64Array.from(a).sort(); return s[Math.min(s.length - 1, Math.floor(q * s.length))]; };
const mean = (a) => a.reduce((x, y) => x + y, 0) / (a.length || 1);

// ---- paths: per tick the pair's point, the line's tangent and whether the line turned ----
function pathOfFight(seed, scen) {   // the real archField fights, read off E2 (its path is the same at any node size)
  RAA.clearMemo();
  const run = RAA.mkRun('E2'), script = RAA.genFight(seed, scen, TICKS), P = [];
  for (let i = 0; i < script.length; i++) { const t0 = run.arch.t; run.tick(script[i]); P.push({ p: run.arch.p, t: run.arch.t, turned: run.arch.t !== t0 && dot(run.arch.t, t0) < 1 - 1e-14 }); }
  return P;
}
function pathOfFlight(speed, rateDeg, every, angleDeg, ticks) {   // flat out along the line; every `every` ticks a swing of angleDeg at rateDeg a second
  let p = norm([0.4, 0.1, 0.9]), t = norm(cross(p, [0, 1, 0])); const P = [], a = speed / RP, w = rateDeg * Math.PI / 180 / 60; let rem = 0, sg = 1;
  for (let i = 0; i < ticks; i++) {
    if (every && i % every === 0) { rem = angleDeg * Math.PI / 180; sg = -sg; }
    const c = Math.cos(a), s = Math.sin(a), np = [p[0] * c + t[0] * s, p[1] * c + t[1] * s, p[2] * c + t[2] * s], nt = [t[0] * c - p[0] * s, t[1] * c - p[1] * s, t[2] * c - p[2] * s];
    p = norm(np); t = norm(nt);
    let turned = false; if (rem > 0) { const d = Math.min(rem, w); rem -= d; const l = cross(p, t), cd = Math.cos(d * sg), sd = Math.sin(d * sg); t = norm([t[0] * cd + l[0] * sd, t[1] * cd + l[1] * sd, t[2] * cd + l[2] * sd]); turned = true; }
    P.push({ p, t, turned });
  }
  return P;
}

// ---- a nested cube-sphere: level m is every 2^m-th node of the finest grid (64 u), so a coarse node is a fine node and is read once ----
const N0 = Math.round(Math.PI / 2 * RP / 64 / 16) * 16, FINE = Math.PI / 2 * RP / N0;
function faceOf(q) {
  const ax = Math.abs(q[0]), ay = Math.abs(q[1]), az = Math.abs(q[2]); let f, u, w;
  if (ax >= ay && ax >= az) { f = q[0] > 0 ? 0 : 1; u = q[1] / ax; w = q[2] / ax; } else if (ay >= az) { f = q[1] > 0 ? 2 : 3; u = q[0] / ay; w = q[2] / ay; } else { f = q[2] > 0 ? 4 : 5; u = q[0] / az; w = q[1] / az; }
  return [f, (u + 1) / 2 * N0, (w + 1) / 2 * N0];
}
// One model: rings [{G, r}] (G a power-of-two multiple of the finest), half: only the far half of the disc (Camera), K: reads a tick
// a queue may spend (0 reads at once). Forced reads ignore K: nodes the sim's strip itself asks for this tick.
function model(path, o) {
  const seen = new Set(), rings = o.rings.map((x) => ({ G: x.G, r: x.r, step: 1 << Math.round(Math.log2(x.G / FINE)), moved: 0 }));
  const reads = new Float64Array(path.length); let queue = [], qHead = 0, backlogMax = 0, forcedN = 0, lateMax = 0, credit = 0;
  function want(q, ring, tick, forced) {
    const fx = faceOf(q), st = ring.step, i = Math.floor(fx[1] / st) * st, j = Math.floor(fx[2] / st) * st;
    for (let a = 0; a <= st; a += st) for (let b = 0; b <= st; b += st) {
      const key = fx[0] * 4294967296 + (i + a) * 65536 + (j + b);
      if (seen.has(key)) continue; seen.add(key);
      if (forced || !o.K) { reads[tick]++; if (forced) forcedN++; } else queue.push(tick);
    }
  }
  function ptAt(p, t, dx, dz) { const l = cross(p, t); return norm([p[0] + (t[0] * dx + l[0] * dz) / RP, p[1] + (t[1] * dx + l[1] * dz) / RP, p[2] + (t[2] * dx + l[2] * dz) / RP]); }
  // the fill at load: nothing counted, since it's a match-start cost, reported apart
  { const p = path[0].p, t = path[0].t; for (const g of rings) { const n = Math.ceil(g.r / g.G); for (let a = -n; a <= n; a++) for (let b = -n; b <= n; b++) { const dx = a * g.G, dz = b * g.G; if (dx * dx + dz * dz > g.r * g.r) continue; if (o.half && dz > 0) continue; const f = faceOf(ptAt(p, t, dx, dz)), st = g.step, i = Math.floor(f[1] / st) * st, j = Math.floor(f[2] / st) * st; for (let u = 0; u <= st; u += st) for (let v = 0; v <= st; v += st) seen.add(f[0] * 4294967296 + (i + u) * 65536 + (j + v)); } } }
  const load = seen.size;
  const stripCols = o.strip | 0;   // the sim's own window, in columns either side of the pair, read from the finest ring
  for (let k = 1; k < path.length; k++) {
    const A = path[k - 1], B = path[k], ca = dot(A.p, B.p), d = Math.acos(Math.min(1, ca)) * RP, lA = cross(A.p, A.t);
    for (const g of rings) {
      g.moved += d;
      while (g.moved >= g.G) {   // the arc the motion uncovered
        g.moved -= g.G; const sgn = dot(B.p, A.t) >= dot(A.p, A.t) ? 1 : -1, n = Math.ceil(2 * g.r / g.G);
        for (let i = -n / 2; i <= n / 2; i++) { const a = i * g.G / g.r, dx = Math.cos(a) * g.r * sgn, dz = Math.sin(a) * g.r; if (o.half && dz > 0) continue; want(ptAt(B.p, B.t, dx, dz), g, k, false); }
      }
    }
    if (o.half && B.turned) {   // a half disc does sweep: its far edge is a radius turning about the pair
      const dth = Math.acos(Math.min(1, dot(A.t, B.t)));
      for (const g of rings) { g.sw = (g.sw || 0) + dth * g.r; while (g.sw >= g.G) { g.sw -= g.G; const n = Math.ceil(g.r / g.G); for (const sg of [-1, 1]) for (let i = 1; i <= n; i++) { const rr = i * g.G; want(ptAt(B.p, B.t, rr * sg, 0), g, k, false); } } }
    }
    if (stripCols && (B.turned || d > 0)) for (let c = -stripCols; c <= stripCols; c += 4) want(ptAt(B.p, B.t, c * COL, 0), rings[0], k, true);
    if (o.K) {
      credit = Math.min(credit + o.K, o.K + 1) - reads[k];
      while (credit >= 1 && qHead < queue.length) { reads[k]++; lateMax = Math.max(lateMax, k - queue[qHead]); qHead++; credit--; }
      backlogMax = Math.max(backlogMax, queue.length - qHead);
    }
  }
  const arr = Array.from(reads);
  return { load, mean: mean(arr), p99: pct(arr, 0.99), max: Math.max(...arr), forced: forcedN / path.length, backlogMax, backlogEnd: queue.length - qHead, lateMax };
}
function row(name, path, o, into) {
  const r = model(path, o);
  into[name] = { ...r, nativeMeanMs: r.mean * READ.native, webMeanMs: r.mean * READ.web, laptopP99Ms: r.p99 * READ.laptop, laptopMaxMs: r.max * READ.laptop, loadNativeMs: r.load * READ.native, loadLaptopS: r.load * READ.laptop / 1000 };
}
const E = [{ G: 128, r: 12000 }], E2 = [{ G: 512, r: 12000 }];
const LOD3 = [{ G: 128, r: 1500 }, { G: 256, r: 4000 }, { G: 512, r: 12000 }], LOD2 = [{ G: 128, r: 3000 }, { G: 512, r: 12000 }];
const COARSE = [{ G: 512, r: 6000 }, { G: 1024, r: 12000 }], LOD1K = [{ G: 1024, r: 12000 }];
const B85 = 8300;   // Camera's bound at the back row, close quarters

const scens = {};
for (const s of ['any', 'hard']) { scens[s] = []; for (let seed = 1; seed <= SEEDS; seed++) scens[s].push(pathOfFight(seed, s)); }
scens.flat = [pathOfFlight(170, 60, 240, 60, 1800)];        // 30 s, so the memo of a revisit does not flatter it: flat out (10,200 u/s), a 60-degree swing at GD's launch rate every 4 s
scens.flat150 = [pathOfFlight(170, 150, 240, 90, 1800)];    // the same at Camera's look: 150 degrees a second
scens.spin = [pathOfFlight(0.0001, 150, 144, 360, 144)];    // standing, swinging only: nothing should be uncovered by a whole disc

const rowsFor = (key) => {
  const paths = scens[key], acc = {};
  const defs = [
    ['E 128 u, r 12,000 (at once)', { rings: E }], ['E2 512 u, r 12,000 (at once)', { rings: E2 }],
    ['E spread, K 4', { rings: E, K: 4 }], ['E2 spread, K 4', { rings: E2, K: 4 }], ['E2 spread, K 1.5 (web)', { rings: E2, K: 1.5 }],
    ['Rings 128 to 1,500, 256 to 4,000, 512 to 12,000', { rings: LOD3 }], ['Same, K 4', { rings: LOD3, K: 4 }],
    ['Rings 128 to 3,000, 512 to 12,000 (World)', { rings: LOD2 }], ['Same, K 4 ', { rings: LOD2, K: 4 }],
    ['512 to 6,000, 1,024 to 12,000', { rings: COARSE }], ['Same, K 4  ', { rings: COARSE, K: 4 }],
    ['1,024 only to 12,000', { rings: LOD1K }], ['Same, K 4   ', { rings: LOD1K, K: 4 }],
    ['E2 half disc, r 8,300 (Camera)', { rings: [{ G: 512, r: B85 }], half: true }], ['Same, K 4    ', { rings: [{ G: 512, r: B85 }], half: true, K: 4 }],
    ['E2 whole disc, r 8,300', { rings: [{ G: 512, r: B85 }] }] ];
  for (const [n, o] of defs) { const each = paths.map((p) => { const a = {}; row(n, p, o, a); return a[n]; }); const r = {}; for (const k of Object.keys(each[0])) r[k] = k === 'max' || k === 'backlogMax' || k === 'lateMax' || k === 'backlogEnd' ? Math.max(...each.map((x) => x[k])) : mean(each.map((x) => x[k])); acc[n] = r; }
  return acc;
};
out.fields = {}; for (const key of Object.keys(scens)) out.fields[key] = rowsFor(key);

// ---- how fine a whole-planet map holds, against the exact ground: error, memory and what its build costs ----
function octUV(q) { const s = Math.abs(q[0]) + Math.abs(q[1]) + Math.abs(q[2]); let a = q[0] / s, b = q[2] / s; if (q[1] < 0) { const ta = (1 - Math.abs(b)) * (a >= 0 ? 1 : -1), tb = (1 - Math.abs(a)) * (b >= 0 ? 1 : -1); a = ta; b = tb; } return [(a + 1) / 2, (b + 1) / 2]; }
function octDir(u, v) { let a = u * 2 - 1, b = v * 2 - 1; const y = 1 - Math.abs(a) - Math.abs(b); if (y < 0) { const ta = (1 - Math.abs(b)) * (a >= 0 ? 1 : -1), tb = (1 - Math.abs(a)) * (b >= 0 ? 1 : -1); a = ta; b = tb; } return norm([a, y, b]); }
const exact = (q) => surf(SEED, q[0], q[1], q[2])[0];
function mapLook(H, N) { const at = (i, j) => { if (i < 0) { i = -i - 1; j = N - 1 - j; } else if (i >= N) { i = 2 * N - 1 - i; j = N - 1 - j; } if (j < 0) { j = -j - 1; i = N - 1 - i; } else if (j >= N) { j = 2 * N - 1 - j; i = N - 1 - i; } return H[j * N + i]; };
  return (q) => { const uv = octUV(q), x = uv[0] * N - 0.5, y = uv[1] * N - 0.5, i = Math.floor(x), j = Math.floor(y), a = x - i, b = y - j; return (at(i, j) * (1 - a) + at(i + 1, j) * a) * (1 - b) + (at(i, j + 1) * (1 - a) + at(i + 1, j + 1) * a) * b; }; }
out.maps = {};
for (const N of [192, 256, 384, 512, 1024]) {
  const t0 = performance.now(), H = new Float64Array(N * N); for (let j = 0; j < N; j++) for (let i = 0; i < N; i++) { const d = octDir((i + 0.5) / N, (j + 0.5) / N); H[j * N + i] = exact(d); }
  const js = performance.now() - t0;
  const look = mapLook(H, N);
  let sq = 0, mx = 0, n = 0, mxAt = null; const errs = [];
  for (let g = 0; g < 40; g++) { const p = norm([Math.cos(g * 2.399) * Math.sin(1 + g * 0.05), Math.sin(g * 1.7) * 0.8, Math.sin(g * 2.399) * Math.cos(1 + g * 0.05)]), t = norm(cross(p, [0.3, 1, 0.1])); for (let s = 0; s < 1200; s++) { const a = s / 1200 * 2 * Math.PI, q = norm([p[0] * Math.cos(a) + t[0] * Math.sin(a), p[1] * Math.cos(a) + t[1] * Math.sin(a), p[2] * Math.cos(a) + t[2] * Math.sin(a)]), e = Math.abs(look(q) - exact(q)); sq += e * e; if (e > mx) { mx = e; mxAt = [q[1], exact(q), look(q)]; } n++; errs.push(e); } }
  out.maps[N] = { reads: N * N, spacingU: 3.54 * RP / N, rmsU: Math.sqrt(sq / n), p99U: pct(errs, 0.99), p999U: pct(errs, 0.999), maxU: mx, maxAt: mxAt, heightMB: N * N * 4 * 1.34 / 1048576, colourMB: N * N * 4 * 1.34 / 1048576, jsMs: js, buildNativeS: N * N * READ.native / 1000, buildWebS: N * N * READ.web / 1000, buildLaptopS: N * N * READ.laptop / 1000 };
}

// ---- how much of the re-lay a turning tick needs: refresh tiers against the height a stale column shows ----
// The strip is re-laid from a 256-square map (the same answer at any look-up source): tiers refresh columns by distance from the
// pivot. Stale error = the height the column holds minus what a full re-lay would give, read at a fighter's feet and across the window.
const LOOK = (() => { const N = 256, H = new Float64Array(N * N); for (let j = 0; j < N; j++) for (let i = 0; i < N; i++) { const d = octDir((i + 0.5) / N, (j + 0.5) / N); H[j * N + i] = exact(d); } return mapLook(H, N); })();
function ptLine(p, t, s) { const a = s / RP, c = Math.cos(a), n = Math.sin(a); return [p[0] * c + t[0] * n, p[1] * c + t[1] * n, p[2] * c + t[2] * n]; }
function relayBench(rateDeg, gap, tiers) {   // tiers: [{to: columns from the pivot, every: ticks}]; 40 swings of 60 degrees from spread places
  const w = rateDeg * Math.PI / 180 / 60, ang = 60 * Math.PI / 180, ticks = Math.ceil(ang / w), feet = Math.round(gap / 2 / COL), wid = Math.min(334, feet + tiers[tiers.length - 1].to); let cols = 0, tot = 0, feetMax = 0, feetSq = 0, feetN = 0, nearMax = 0, allMax = 0, allSq = 0, allN = 0;
  for (let g = 0; g < 40; g++) {
    const p = norm([Math.cos(g * 2.399) * Math.sin(1 + g * 0.05), Math.sin(g * 1.7) * 0.75, Math.sin(g * 2.399) * Math.cos(1 + g * 0.05)]); let t = norm(cross(p, [0.3, 1, 0.1]));
    const hold = new Float64Array(wid * 2 + 1), l = cross(p, t), l0 = l; for (let c = -wid; c <= wid; c++) hold[c + wid] = LOOK(ptLine(p, t, c * COL));
    const t0 = t;
    for (let k = 1; k <= ticks; k++) {
      const a = k * w; t = norm([t0[0] * Math.cos(a) + l0[0] * Math.sin(a), t0[1] * Math.cos(a) + l0[1] * Math.sin(a), t0[2] * Math.cos(a) + l0[2] * Math.sin(a)]); tot++;
      for (let c = -wid; c <= wid; c++) {
        const ad = Math.min(Math.abs(c - feet), Math.abs(c + feet)); let ev = 0; for (const x of tiers) if (ad <= x.to) { ev = x.every; break; } if (!ev) continue;
        if (ev === 1 || (k + c + wid) % ev === 0) { hold[c + wid] = LOOK(ptLine(p, t, c * COL)); cols++; }
      }
      for (let c = -wid; c <= wid; c += 8) { const e = Math.abs(hold[c + wid] - LOOK(ptLine(p, t, c * COL))); allMax = Math.max(allMax, e); allSq += e * e; allN++; }
      for (const c of [feet, -feet]) if (Math.abs(c) <= wid) { const e = Math.abs(hold[c + wid] - LOOK(ptLine(p, t, c * COL))); feetMax = Math.max(feetMax, e); feetSq += e * e; feetN++; }
      for (const c of [feet + 12, -feet - 12]) if (Math.abs(c) <= wid) nearMax = Math.max(nearMax, Math.abs(hold[c + wid] - LOOK(ptLine(p, t, c * COL))));
    }
  }
  return { colsTick: cols / tot, feetRmsU: Math.sqrt(feetSq / (feetN || 1)), feetMaxU: feetMax, reachMaxU: nearMax, allRmsU: Math.sqrt(allSq / allN), allMaxU: allMax };
}
const TIERS = {
  'Every column of the view, every tick (today\'s E)': [{ to: 668, every: 1 }],
  '+-75 round each fighter, every tick (Netcode\'s top)': [{ to: 75, every: 1 }],
  '+-40 round each, every tick (World\'s window)': [{ to: 40, every: 1 }],
  '+-18 round each, every tick': [{ to: 18, every: 1 }],
  '+-16 every tick, +-40 every 4, +-75 every 8': [{ to: 16, every: 1 }, { to: 40, every: 4 }, { to: 75, every: 8 }],
  '+-8 every tick, +-40 every 4': [{ to: 8, every: 1 }, { to: 40, every: 4 }],
  '+-8 every 2, +-40 every 8': [{ to: 8, every: 2 }, { to: 40, every: 8 }] };
out.relay = {};
for (const [rate, gap] of [[10, 300], [29, 300], [60, 300], [60, 2400], [60, 19200], [150, 300]]) { const key = rate + ' deg/s, gap ' + gap; out.relay[key] = {}; for (const [n, t] of Object.entries(TIERS)) out.relay[key][n] = relayBench(rate, gap, t); }

// a look-up, timed in JS, with the same steps the sim would run: one rotation step along the line, the map's encode, four fetches
{ const N = 512, H = new Float64Array(N * N).map((_, i) => (i * 7) % 113); const look = (q) => { const uv = octUV(q), x = uv[0] * N - 0.5, y = uv[1] * N - 0.5, i = Math.max(0, Math.min(N - 2, Math.floor(x))), j = Math.max(0, Math.min(N - 2, Math.floor(y))), a = x - i, b = y - j; return (H[j * N + i] * (1 - a) + H[j * N + i + 1] * a) * (1 - b) + (H[(j + 1) * N + i] * (1 - a) + H[(j + 1) * N + i + 1] * a) * b; };
  const p = norm([0.4, 0.1, 0.9]), t = norm(cross(p, [0, 1, 0])), ca = Math.cos(COL / RP), sa = Math.sin(COL / RP); let best = 1e9, sink = 0; for (let rep = 0; rep < 20; rep++) { const t0 = performance.now(); for (let k = 0; k < 3000; k++) { let x = p[0], y = p[1], z = p[2], u = t[0], v = t[1], w = t[2]; for (let c = 0; c < 669; c++) { sink += look([x, y, z]); const nx = x * ca + u * sa, ny = y * ca + v * sa, nz = z * ca + w * sa; u = u * ca - x * sa; v = v * ca - y * sa; w = w * ca - z * sa; x = nx; y = ny; z = nz; } } best = Math.min(best, (performance.now() - t0) / 3000 / 669 * 1000); }
  out.lookupUsJs = best; out.lookupSink = sink; }

writeFileSync(new URL('./cuts.json', import.meta.url), JSON.stringify(out, null, 1));

// ---- the table ----
const f = (x, d = 1) => (x === undefined ? '-' : x.toFixed(d)), L = [];
L.push('reads a tick. Budget: 0.2 ms = ' + f(BUDGET / READ.native) + ' native, ' + f(BUDGET / READ.web) + ' web. Spike 8 ms = ' + f(SPIKE / READ.native, 0) + ' native, ' + f(SPIKE / READ.web, 0) + ' web. Laptop ms = reads x 0.8.');
for (const key of Object.keys(out.fields)) { L.push('\n== ' + key + '\n' + 'field'.padEnd(52) + 'load   mean    p99   max  forced backlog late | native ms laptop p99'); for (const [n, r] of Object.entries(out.fields[key])) L.push(n.padEnd(52) + String(Math.round(r.load)).padStart(6) + f(r.mean, 2).padStart(7) + f(r.p99, 0).padStart(6) + f(r.max, 0).padStart(6) + f(r.forced, 2).padStart(7) + String(r.backlogEnd).padStart(7) + String(r.lateMax).padStart(6) + ' | ' + f(r.nativeMeanMs, 2).padStart(8) + f(r.laptopP99Ms, 1).padStart(9)); }
L.push('\n== a resident whole-planet map (gen 1 ground; gen 2 not measured)\nN      spacing   RMS    p99  p99.9    max  MB(h+c)  reads     build native / web / laptop s   JS ms');
for (const [N, m] of Object.entries(out.maps)) L.push(String(N).padEnd(7) + f(m.spacingU, 0).padStart(6) + f(m.rmsU, 1).padStart(7) + f(m.p99U, 1).padStart(7) + f(m.p999U, 1).padStart(7) + f(m.maxU, 0).padStart(6) + f(m.heightMB + m.colourMB, 1).padStart(7) + String(m.reads).padStart(9) + ('  ' + f(m.buildNativeS, 1) + ' / ' + f(m.buildWebS, 1) + ' / ' + f(m.buildLaptopS, 0)).padEnd(28) + f(m.jsMs, 0).padStart(6));
L.push('\n== re-lay on a turning tick (look-up ' + f(out.lookupUsJs, 3) + ' us in JS; ms below at 5.4 us (Godot far map) and 2.5 us (World\'s low figure))');
for (const key of Object.keys(out.relay)) { L.push('\n' + key + '\n' + 'tiers'.padEnd(56) + 'cols  ms@5.4 ms@2.5 | feet rms max  reach max  all rms max'); for (const [n, r] of Object.entries(out.relay[key])) L.push(n.padEnd(56) + f(r.colsTick, 0).padStart(4) + f(r.colsTick * 0.0054, 2).padStart(8) + f(r.colsTick * 0.0025, 2).padStart(7) + ' | ' + f(r.feetRmsU, 2).padStart(7) + f(r.feetMaxU, 1).padStart(6) + f(r.reachMaxU, 1).padStart(8) + f(r.allRmsU, 2).padStart(9) + f(r.allMaxU, 1).padStart(7)); }
const txt = L.join('\n') + '\n'; writeFileSync(new URL('./cuts.txt', import.meta.url), txt); process.stdout.write(txt);
