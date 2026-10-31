// The cost cuts for the turntable, against 0.2 ms a tick of reads and the 8 ms spike. Paths come from archField's own fights (or
// a flat-out crossing with swings); every read is counted on a cube-sphere of nested grids, without running the noise except where
// an error is measured. Counts are deterministic; ms are counts x World's cost a read and my look-up figures, not timings.
// Revised 2026-10-31 for Game Design's rates (launch 60, ceiling 98; chase 45, form 30, brawl 10), Camera's half disc of radius B, the 1.5 reads a tick of
// the web laptop target, and the question of what canonical spacing a narrow sim strip can read as it flies.
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
const E = [{ G: 128, r: 12000 }], E2 = [{ G: 512, r: 12000 }];
const FIELDS = [
  ['E: 128 u to 12,000', { rings: E }], ['E2: 512 u to 12,000', { rings: E2 }],
  ['Rings: 128 to 1,500, 256 to 4,000, 512 to 12,000', { rings: [{ G: 128, r: 1500 }, { G: 256, r: 4000 }, { G: 512, r: 12000 }] }],
  ['Rings (World): 128 to 3,000, 512 to 12,000', { rings: [{ G: 128, r: 3000 }, { G: 512, r: 12000 }] }],
  ['512 to 6,000, 1,024 to 12,000', { rings: [{ G: 512, r: 6000 }, { G: 1024, r: 12000 }] }],
  ['1,024 to 12,000', { rings: [{ G: 1024, r: 12000 }] }],
  ['E2, half disc, B 8,300 (Camera, 16:9, close)', { rings: [{ G: 512, r: 8300 }], half: true }],
  ['E2, half disc, B 10,800 (Camera, any setting)', { rings: [{ G: 512, r: 10800 }], half: true }],
  ['E2, whole disc, r 8,300', { rings: [{ G: 512, r: 8300 }] }],
  ['1,024, half disc, B 10,800', { rings: [{ G: 1024, r: 10800 }], half: true }] ];
const scens = {};
for (const sc of ['any', 'hard']) { scens[sc] = []; for (let seed = 1; seed <= SEEDS; seed++) scens[sc].push(pathOfFight(seed, sc)); }
// 30 s first crossings, so the memo of a revisit does not flatter them, with a swing of 60 degrees every 4 s
scens['flat out, 60 deg/s'] = [pathOfFlight(170, 60, 240, 60, 1800)];
scens['flat out, 98 deg/s (the ceiling)'] = [pathOfFlight(170, 98, 240, 60, 1800)];
scens['launch speed, 60 deg/s'] = [pathOfFlight(100, 60, 240, 60, 1800)];
scens['a walk (700 u/s), brawl 10 deg/s'] = [pathOfFlight(11.7, 10, 700, 60, 1800)];
// a whole turn in place, one way, once: what a swing itself reads
scens['in place, 60 deg/s'] = [pathOfFlight(0.0001, 60, 360, 360, 360)];
scens['in place, 98 deg/s'] = [pathOfFlight(0.0001, 98, 221, 360, 221)];
const avgBy = (each, k) => (k === 'max' || k === 'lateMax' || k === 'backlogEnd' ? Math.max(...each.map((x) => x[k])) : mean(each.map((x) => x[k])));
out.fields = {};
for (const key of Object.keys(scens)) {
  out.fields[key] = {};
  for (const [n, o] of FIELDS) {
    const run = (extra) => { const each = scens[key].map((p) => model(p, { ...o, ...extra })), r = {}; for (const k of Object.keys(each[0])) r[k] = avgBy(each, k); return r; };
    const at = run({}), k4 = run({ K: 3.7 }), k15 = run({ K: 1.5 });
    out.fields[key][n] = { load: at.load, mean: at.mean, p99: at.p99, max: at.max, laptopP99Ms: at.p99 * READ.laptop, webP99Ms: at.p99 * READ.web, backlog37: k4.backlogEnd, late37: k4.lateMax, backlog15: k15.backlogEnd, late15: k15.lateMax };
  }
}

// ---- the canonical field: what a narrow sim strip reads as it flies, if nothing's baked at that spacing ----
// Two bodies on one line, a launch: the sent body at 100 u/tick, the launcher holds 40 ticks then follows at 90; a swing about the launcher's point on
// a near-constant rate, its speed capped by the 10,000 u/s sweep limit. Reads are new nodes under the columns the sim asks for: the feet only, or a window round each.
function stripReads(G, kind, win) {
  const seen = new Set(), step = 1 << Math.round(Math.log2(G / FINE)), counts = [];
  const want = (q) => { const fx = faceOf(q), i = Math.floor(fx[1] / step) * step, j = Math.floor(fx[2] / step) * step; let n = 0; for (let a = 0; a <= step; a += step) for (let b = 0; b <= step; b += step) { const key = fx[0] * 4294967296 + (i + a) * 65536 + (j + b); if (!seen.has(key)) { seen.add(key); n++; } } return n; };
  const along = (p, t, x) => { const a = x / RP, c = Math.cos(a), n = Math.sin(a); return norm([p[0] * c + t[0] * n, p[1] * c + t[1] * n, p[2] * c + t[2] * n]); };
  const rot = (v, k, a) => { const c = Math.cos(a), n = Math.sin(a), x = cross(k, v), d = dot(k, v) * (1 - c); return [v[0] * c + x[0] * n + k[0] * d, v[1] * c + x[1] * n + k[1] * d, v[2] * c + x[2] * n + k[2] * d]; };
  for (let g = 0; g < 24; g++) {
    let p = norm([Math.cos(g * 2.399) * Math.sin(1 + g * 0.05), Math.sin(g * 1.7) * 0.75, Math.sin(g * 2.399) * Math.cos(1 + g * 0.05)]), t = norm(cross(p, [0.3, 1, 0.1])), xA = 0, xB = 150;
    const q = p, T = kind === 'launch' ? 216 : 600, sg = g % 2 ? 1 : -1, th = 60 * Math.PI / 180, rateCap = kind === 'launch' ? 60 : kind === 'chase' ? 45 : kind === 'brawl' ? 10 : 0; let u = 0, a = 0;
    for (let k = 0; k < T; k++) {
      let vA = 0, vB = 0;
      if (kind === 'launch') { vB = 100; vA = k < 40 ? 0 : 90; } else if (kind === 'chase') { vA = vB = 170; } else if (kind === 'chase apart') { vA = vB = 170; xB = 3000; } else if (kind === 'lone flier') { vB = 100; } else if (kind === 'brawl') { vA = vB = Math.sin(k * 0.05) * 11; }
      xA += vA; xB += vB;
      let n = 0;
      if (rateCap && u < 1) { const r = Math.max(1, Math.abs(xB)), lim = kind === 'brawl' ? 75 / 60 / Math.max(xB - xA, 1) * 2 : (10000 / 60) / r, cap = rateCap * Math.PI / 180 / 60, ds = 30 * u * u * (u - 1) * (u - 1), base = cap / (1.875 * th), du = Math.min(base, ds > 1e-4 ? Math.min(cap, lim) / (th * ds) : base); u = Math.min(1, u + du); const na = th * u * u * u * (u * (u * 6 - 15) + 10), w = (na - a) * sg; a = na; t = norm(rot(t, q, w)); p = norm(rot(p, q, w)); }
      for (const [x, moving] of [[xA, vA !== 0], [xB, vB !== 0 || kind === 'launch']]) { if (win === 0 && !moving && !rateCap) continue; for (let c = -win; c <= win; c += Math.max(1, Math.round(G / COL / 2))) n += want(along(p, t, x + c * COL)); }
      counts.push(n);
    }
  }
  return { mean: mean(counts), p99: pct(counts, 0.99), max: Math.max(...counts) };
}
out.strip = {};
for (const kind of ['lone flier', 'launch', 'chase', 'chase apart', 'brawl']) { out.strip[kind] = {}; for (const G of [64, 128, 256, 512, 1024]) { out.strip[kind][G] = { feet: stripReads(G, kind, 0), win18: stripReads(G, kind, 18) }; } }
// a bake of the whole planet at a spacing: the sphere's area over the spacing squared
out.bake = {}; for (const G of [128, 256, 384, 512, 1024]) { const n = 4 * Math.PI * RP * RP / (G * G); out.bake[G] = { nodes: n, native: n * READ.native / 1000, web: n * READ.web / 1000, laptop: n * READ.laptop / 1000, heightOnlyLaptop: n * READ.laptop / 2000 }; }
// sharpening a disc at rest, at the read budget
out.sharpen = {}; for (const [G, r] of [[128, 1500], [128, 3000], [128, 6000], [256, 3000], [256, 6000]]) { const n = Math.PI * r * r / (G * G); out.sharpen[G + ' to ' + r] = { nodes: n, s15: n / 1.5 / 60, s37: n / 3.7 / 60 }; }

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
for (const [rate, gap] of [[10, 300], [29, 300], [60, 300], [60, 2400], [60, 19200], [98, 300]]) { const key = rate + ' deg/s, gap ' + gap; out.relay[key] = {}; for (const [n, t] of Object.entries(TIERS)) out.relay[key][n] = relayBench(rate, gap, t); }

// a look-up, timed in JS, with the same steps the sim would run: one rotation step along the line, the map's encode, four fetches
{ const N = 512, H = new Float64Array(N * N).map((_, i) => (i * 7) % 113); const look = (q) => { const uv = octUV(q), x = uv[0] * N - 0.5, y = uv[1] * N - 0.5, i = Math.max(0, Math.min(N - 2, Math.floor(x))), j = Math.max(0, Math.min(N - 2, Math.floor(y))), a = x - i, b = y - j; return (H[j * N + i] * (1 - a) + H[j * N + i + 1] * a) * (1 - b) + (H[(j + 1) * N + i] * (1 - a) + H[(j + 1) * N + i + 1] * a) * b; };
  const p = norm([0.4, 0.1, 0.9]), t = norm(cross(p, [0, 1, 0])), ca = Math.cos(COL / RP), sa = Math.sin(COL / RP); let best = 1e9, sink = 0; for (let rep = 0; rep < 20; rep++) { const t0 = performance.now(); for (let k = 0; k < 3000; k++) { let x = p[0], y = p[1], z = p[2], u = t[0], v = t[1], w = t[2]; for (let c = 0; c < 669; c++) { sink += look([x, y, z]); const nx = x * ca + u * sa, ny = y * ca + v * sa, nz = z * ca + w * sa; u = u * ca - x * sa; v = v * ca - y * sa; w = w * ca - z * sa; x = nx; y = ny; z = nz; } } best = Math.min(best, (performance.now() - t0) / 3000 / 669 * 1000); }
  out.lookupUsJs = best; out.lookupSink = sink; }

writeFileSync(new URL('./cuts.json', import.meta.url), JSON.stringify(out, null, 1));

// ---- the tables ----
const f = (x, d = 1) => (x === undefined ? '-' : x.toFixed(d)), L = [];
L.push('reads a tick. Budget: 0.2 ms = ' + f(BUDGET / READ.native) + ' native, ' + f(BUDGET / READ.web) + ' web (the laptop target). Spike 8 ms = ' + f(SPIKE / READ.native, 0) + ' native, ' + f(SPIKE / READ.web, 0) + ' web. Laptop ms = reads x 0.8.');
for (const key of Object.keys(out.fields)) { L.push('\n== ' + key + '\n' + 'field'.padEnd(50) + 'load    mean    p99   max  laptop p99 | at 3.7: backlog late | at 1.5: backlog late'); for (const [n, r] of Object.entries(out.fields[key])) L.push(n.padEnd(50) + String(Math.round(r.load)).padStart(5) + f(r.mean, 2).padStart(8) + f(r.p99, 0).padStart(6) + f(r.max, 0).padStart(6) + f(r.laptopP99Ms, 1).padStart(10) + '   |' + String(r.backlog37).padStart(14) + String(r.late37).padStart(6) + '  |' + String(r.backlog15).padStart(14) + String(r.late15).padStart(6)); }
L.push('\n== the canonical field, read only under the sim strip as it flies: new nodes a tick, mean / p99 / max (budget 1.5 web, 3.7 native)\n' + 'moving'.padEnd(14) + 'spacing  feet only            +-18 columns round each');
for (const kind of Object.keys(out.strip)) for (const G of Object.keys(out.strip[kind])) { const a = out.strip[kind][G].feet, b = out.strip[kind][G].win18; L.push(kind.padEnd(14) + String(G).padStart(6) + '   ' + (f(a.mean, 2) + ' / ' + f(a.p99, 0) + ' / ' + f(a.max, 0)).padEnd(20) + f(b.mean, 2) + ' / ' + f(b.p99, 0) + ' / ' + f(b.max, 0)); }
L.push('\n== a whole-planet bake, at World\'s cost of a read\nspacing   nodes     native s   web s   laptop s   laptop s if height-only is half');
for (const [G, b] of Object.entries(out.bake)) L.push(String(G).padEnd(9) + String(Math.round(b.nodes)).padStart(7) + f(b.native, 1).padStart(10) + f(b.web, 1).padStart(9) + f(b.laptop, 0).padStart(10) + f(b.heightOnlyLaptop, 0).padStart(12));
L.push('\n== sharpening a disc at rest\ndisc            nodes    s at 1.5 a tick   s at 3.7');
for (const [k, b] of Object.entries(out.sharpen)) L.push(k.padEnd(14) + String(Math.round(b.nodes)).padStart(7) + f(b.s15, 1).padStart(14) + f(b.s37, 1).padStart(12));
L.push('\n== a map of the whole planet, gen 1 ground; gen 2 is 3 to 7 times these (world.md 11.1)\nN      spacing   RMS    p99  p99.9    max  MB(h+c)  reads');
for (const [N, m] of Object.entries(out.maps)) L.push(String(N).padEnd(7) + f(m.spacingU, 0).padStart(6) + f(m.rmsU, 1).padStart(7) + f(m.p99U, 1).padStart(7) + f(m.p999U, 1).padStart(7) + f(m.maxU, 0).padStart(6) + f(m.heightMB + m.colourMB, 1).padStart(7) + String(m.reads).padStart(9));
L.push('\n== a window of columns re-laid on a turning tick. ms at 3.6 us (Simulation, a re-laid column in GDScript, native) and 0.4 us (Performance, a bare sample on the web)');
for (const key of Object.keys(out.relay)) { L.push('\n' + key + '\n' + 'tiers'.padEnd(56) + 'cols  ms@3.6 ms@0.4 | feet rms max  reach max  all rms max'); for (const [n, r] of Object.entries(out.relay[key])) L.push(n.padEnd(56) + f(r.colsTick, 0).padStart(4) + f(r.colsTick * 0.0036, 2).padStart(8) + f(r.colsTick * 0.0004, 3).padStart(7) + ' | ' + f(r.feetRmsU, 2).padStart(7) + f(r.feetMaxU, 1).padStart(6) + f(r.reachMaxU, 1).padStart(8) + f(r.allRmsU, 2).padStart(9) + f(r.allMaxU, 1).padStart(7)); }
const txt = L.join('\n') + '\n'; writeFileSync(new URL('./cuts.txt', import.meta.url), txt); process.stdout.write(txt);
