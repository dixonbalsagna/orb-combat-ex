// ==== ANY-ANGLE SIM (no DOM) ====
// How can the angle of the fight along the planet change at any moment? (Orb, 2026-10-30; docs/world/ring-any-angle/research.md.)
// One seeded fight (positions along the fight's line, craters, steering asks) runs over five architectures of the world
// under it, on the planet's real noise (research/planet-gen, bit-exact with WorldPlanet, planet 7). Each counts what the paper
// compares: noise reads a tick, ground rewritten inside the camera's view, marks kept and where, how far a lap closes, a
// rollback's equality. Throwaway spike code (research/README.md). The host gives surf, sin, cos, atan2f and R.
var RAA = (function () {
'use strict';
var COL = 32, NC = 4800, W = NC * COL, SEED = 7, DA = COL / R, SA = sin(DA), CA = cos(DA);
// view: half the camera's widest view in columns (21,333 units across); margin: what is read beyond it; carry: World's zone;
// kappaCol: the sharpest bend a column may take, a radius of 2,400 units (the depth band's width, so the band's Fermi strip
// never folds on itself); K: noise reads a tick the sim may spend (Simulation's calm-turn-read.md); fieldG: the 2D field's
// node spacing; fieldHW: its radius round the pair; turnRate: the turntable's fastest turn
var CFG = { view: 334, margin: 128, carry: 375, kappaCol: COL / 2400, K: 6, fieldG: 128, fieldHW: 12000, turnRate: 30 * Math.PI / 180 / 60, moveMax: 450, band: 2400 };
function deg(d) { return d * Math.PI / 180; }
function mod(i) { i = Math.round(i) % NC; return i < 0 ? i + NC : i; }
function dot(a, b) { return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]; }
function cross(a, b) { return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]; }
function norm(a) { var l = Math.sqrt(dot(a, a)); return [a[0] / l, a[1] / l, a[2] / l]; }
function arcU(a, b) { var c = cross(a, b); return atan2f(Math.sqrt(dot(c, c)), dot(a, b)) * R; }
function rotT(p, t, r) { var c = cos(r), s = sin(r), l = cross(p, t); return [t[0] * c + l[0] * s, t[1] * c + l[1] * s, t[2] * c + l[2] * s]; }
// the frame k columns along the geodesic from (p, t); closed form, so the same bits however it is stepped
function along(p, t, k) { var a = k * DA, c = cos(a), s = sin(a); return { p: [p[0] * c + t[0] * s, p[1] * c + t[1] * s, p[2] * c + t[2] * s], t: [t[0] * c - p[0] * s, t[1] * c - p[1] * s, t[2] * c - p[2] * s] }; }
function bearingTo(p, t, q) { var d = dot(p, q), v = [q[0] - p[0] * d, q[1] - p[1] * d, q[2] - p[2] * d], l = cross(p, t); return atan2f(dot(v, l), dot(v, t)); }
function fnv(h, a) { for (var i = 0; i < a.length; i++) { var v = a[i]; h = Math.imul(h ^ (v * 1024 | 0), 16777619); } return h; }

// ---- the noise, memoised outside the state (a rollback's re-read costs a map hit, as World's kept jobs do) ----
var memo = new Map();
function clearMemo() { memo.clear(); }
function noise(run, p) {
  var k = p[0] + ',' + p[1] + ',' + p[2], v = memo.get(k);
  if (v === undefined) { v = surf(SEED, p[0], p[1], p[2])[0]; run.evals++; run.evT++; if (memo.size > 200000) memo.clear(); memo.set(k, v); } else run.hits++;
  return v;
}
// ---- marks: craters. Ring store: written into the strip's arrays and gone when those columns are. Planet store: an append-only
// log in planet coordinates (a rollback truncates it, a snapshot is its length), the strip's arrays derived from it ----
function mkStore() { return { log: [], cells: new Map() }; }
function cellOf(p) { return Math.floor(p[0] * 25) + ',' + Math.floor(p[1] * 25) + ',' + Math.floor(p[2] * 25); }
function storeAdd(s, m) { s.log.push(m); var k = cellOf(m.p), c = s.cells.get(k); if (c) c.push(m); else s.cells.set(k, [m]); }
function storeTrunc(s, n) { while (s.log.length > n) { var m = s.log.pop(), c = s.cells.get(cellOf(m.p)); c.pop(); } }
function storeNear(s, p) {
  var out = [], x = Math.floor(p[0] * 25), y = Math.floor(p[1] * 25), z = Math.floor(p[2] * 25);
  for (var i = -1; i <= 1; i++) for (var j = -1; j <= 1; j++) for (var k = -1; k <= 1; k++) { var c = s.cells.get((x + i) + ',' + (y + j) + ',' + (z + k)); if (c) for (var n = 0; n < c.length; n++) out.push(c[n]); }
  return out;
}
function craterAt(m, dU) { if (dU >= m.r) return 0; var u = dU / m.r; return -m.d * (1 - u * u) * (1 - u * u); }

// ---- the strip: the sim's columns, wrapped; every architecture but the field keeps it. The columns are the sim's 1D world ----
function mkStrip() { return { px: new Float64Array(NC), py: new Float64Array(NC), pz: new Float64Array(NC), tx: new Float64Array(NC), ty: new Float64Array(NC), tz: new Float64Array(NC),
  base: new Float32Array(NC), def: new Float32Array(NC), tag: new Int32Array(NC), read: new Uint8Array(NC) }; }
function setF(s, i, f) { s.px[i] = f.p[0]; s.py[i] = f.p[1]; s.pz[i] = f.p[2]; s.tx[i] = f.t[0]; s.ty[i] = f.t[1]; s.tz[i] = f.t[2]; }
function getP(s, i) { return [s.px[i], s.py[i], s.pz[i]]; }
function getT(s, i) { return [s.tx[i], s.ty[i], s.tz[i]]; }
function copyStrip(s) { var o = {}; for (var k in s) o[k] = s[k].slice(); return o; }
function pasteStrip(d, o) { for (var k in o) d[k].set(o[k]); }
function stripDig(run, s, c, m, store) {
  var rc = Math.ceil(m.r / COL);
  for (var o = -rc; o <= rc; o++) { var i = mod(c + o); if (!s.read[i]) continue; var v = craterAt(m, Math.abs(o) * COL); if (v < 0) { s.def[i] += v; s.tag[i] = m.id; run.dugT.add(i); } }
}
function stripFromStore(st, s, i) {   // a column laid from the planet store: the marks it crosses, measured on the planet
  if (!st) return; var p = getP(s, i), ms = storeNear(st, p), d = 0, tag = 0;
  for (var n = 0; n < ms.length; n++) { var v = craterAt(ms[n], arcU(p, ms[n].p)); if (v < 0) { d += v; tag = ms[n].id; } }
  s.def[i] = d; s.tag[i] = tag;
}

// ---- A. The plane swap (today's calm turn; K and caps are the knobs): the whole next ring is read first, then one swap at a
// calm tick: the carry zone keeps, everything else is the new ring ----
function archSwap(run, o) {
  var s = mkStrip(), A = { kind: 'swap', s: s, next: null, n: 0, lastT: -1e9, drift: 0, m: 0 }, K = o.K;
  function layRing(p, t, c, dst) { for (var k = -NC / 2; k < NC / 2; k++) { var f = along(p, t, k), i = mod(c + k); if (dst) { dst.f[i] = f; } else setF(s, i, f); } }
  A.init = function (p, t) { layRing(p, t, 0); for (var i = 0; i < NC; i++) { s.base[i] = noise(run, getP(s, i)); s.read[i] = 1; } run.evT = 0; };
  A.ask = function (rad) {
    if (A.next) { run.refused++; return; }
    if (o.caps && (A.n >= 4 || run.t - A.lastT < 3600 || Math.abs(A.drift + rad) > deg(40) || Math.abs(rad) > deg(10))) { run.refused++; return; }
    var c = Math.round(A.m), i = mod(c); A.next = { rad: rad, c: c, p: getP(s, i), t: rotT(getP(s, i), getT(s, i), rad), cols: 0, h: new Float32Array(NC), f: new Array(NC) };
    layRing(A.next.p, A.next.t, c, A.next);
  };
  A.step = function (w) {
    A.m = w.m; var N = A.next; if (!N) return;
    for (var n = 0; n < K && N.cols < NC; n++, N.cols++) { var i = mod(N.c + N.cols - NC / 2); N.h[i] = noise(run, N.f[i].p); }
    if (N.cols < NC || !w.calm) return;
    var far = Math.max(Math.abs(w.a - N.c), Math.abs(w.b - N.c)) * COL; if (far * Math.abs(sin(N.rad)) > CFG.moveMax) { return; }   // World's moveMax: wait
    // the swap: the carry zone keeps its ground, faded out over its outer three quarters
    for (var k = -NC / 2; k < NC / 2; k++) {
      var j = mod(N.c + k), a = Math.abs(k), wgt = a <= CFG.carry / 4 ? 1 : a >= CFG.carry ? 0 : 1 - (a - CFG.carry / 4) / (CFG.carry * 0.75); wgt = wgt * wgt * (3 - 2 * wgt);
      s.base[j] = s.base[j] * wgt + N.h[j] * (1 - wgt); s.def[j] *= wgt; if (wgt < 0.5) s.tag[j] = 0; setF(s, j, N.f[j]);
    }
    A.n++; A.lastT = run.t; A.drift += N.rad; A.next = null; run.turned(N.rad);
  };
  A.dig = function (c, m) { stripDig(run, s, c, m); };
  A.peek = function () {};
  A.axis = function (c) { var i = mod(c); return { p: getP(s, i), t: getT(s, i) }; };
  A.height = function (c) { var i = mod(c); return s.base[i] + s.def[i]; };
  A.snap = function () { return { s: copyStrip(s), n: A.n, lastT: A.lastT, drift: A.drift, m: A.m, next: A.next && Object.assign({}, A.next, { h: A.next.h.slice() }) }; };
  A.rest = function (o2) { pasteStrip(s, o2.s); A.n = o2.n; A.lastT = o2.lastT; A.drift = o2.drift; A.m = o2.m; A.next = o2.next && Object.assign({}, o2.next, { h: o2.next.h.slice() }); };
  A.hash = function () { return fnv(fnv(fnv(17, s.base), s.def), s.px) + A.n; };
  A.bytes = function () { return { state: NC * 4 * 5 + (A.next ? NC * 4 : 0), snapshot: NC * 4 * 5, derived: NC * 8 + NC * 48 }; };
  return A;
}
// ---- B. The lazy plane: a new plane through the pair at any tick; the patch round the pair keeps its columns, the rest of the
// ring is unread and comes in nearest first, K a tick. Still one closed plane; the patch is an inlay ----
function archLazyPlane(run, o) {
  var s = mkStrip(), st = o.store ? mkStore() : null, B = { kind: 'lazy', s: s, plane: null, store: st, m: 0, a: 0, b: 0 }, K = o.K;
  function readCol(c) {
    var i = mod(c); if (s.read[i]) return; var P = B.plane, f = along(P.p, P.t, c - P.c); setF(s, i, f); s.base[i] = noise(run, f.p); s.read[i] = 1; s.def[i] = 0; s.tag[i] = 0; stripFromStore(st, s, i);
    var e = P.edge ? (c > P.hi ? c - P.hi : P.lo - c) : -1;       // the edge of the patch: its last ground fades into the new ring's
    if (P.edge && e >= 0 && e < 64) { var u = e / 64; u = u * u * (3 - 2 * u); var h = c > P.hi ? P.edge[1] : P.edge[0]; s.base[i] = h * (1 - u) + s.base[i] * u; }
  }
  B.init = function (p, t) { B.plane = { p: p, t: t, c: 0 }; for (var c = -CFG.view - CFG.margin; c <= CFG.view + CFG.margin; c++) readCol(c); run.evT = 0; };
  B.ask = function (rad) {
    var c = Math.round(B.m), i = mod(c), p = getP(s, i), t = rotT(p, getT(s, i), rad), lo = Math.floor(Math.min(B.a, B.b)) - CFG.carry, hi = Math.ceil(Math.max(B.a, B.b)) + CFG.carry;
    B.plane = { p: p, t: t, c: c, edge: [s.base[mod(lo)], s.base[mod(hi)]], lo: lo, hi: hi };
    for (var k = -NC / 2; k < NC / 2; k++) { var cc = c + k; if (cc < lo || cc > hi) { var j = mod(cc); s.read[j] = 0; if (!st) { s.def[j] = 0; s.tag[j] = 0; } } }
    run.turned(rad);
  };
  B.step = function (w) {
    B.m = w.m; B.a = w.a; B.b = w.b; var n = 0, lo = Math.floor(Math.min(w.a, w.b)), hi = Math.ceil(Math.max(w.a, w.b));
    for (var d = 0; d <= CFG.view + CFG.margin; d++) {
      var cs = [hi + d, lo - d];
      for (var q = 0; q < 2; q++) if (!s.read[mod(cs[q])]) { if (d <= CFG.view) { var e0 = run.evT; readCol(cs[q]); run.forced += run.evT - e0; n++; } else if (n < K) { readCol(cs[q]); n++; } }
    }
  };
  B.dig = function (c, m) { if (st) storeAdd(st, m); stripDig(run, s, c, m); };
  B.peek = function (c) { var i = mod(c); if (!s.read[i]) readCol(c); };
  B.axis = function (c) { var i = mod(c); if (s.read[i]) return { p: getP(s, i), t: getT(s, i) }; return along(B.plane.p, B.plane.t, c - B.plane.c); };
  B.height = function (c) { var i = mod(c); if (!s.read[i]) readCol(c); return s.base[i] + s.def[i]; };
  B.snap = function () { return { s: copyStrip(s), plane: B.plane, n: st ? st.log.length : 0, m: B.m }; };
  B.rest = function (o2) { pasteStrip(s, o2.s); B.plane = o2.plane; B.m = o2.m; if (st) storeTrunc(st, o2.n); };
  B.hash = function () { return fnv(fnv(fnv(17, s.base), s.def), s.read) + (st ? st.log.length : 0); };
  B.bytes = function () { return { state: NC * 4 * 5 + 64 + (st ? st.log.length * 48 : 0), snapshot: NC * 4 * 5 + NC * 4 + NC, derived: NC * 48 }; };
  return B;
}
// ---- C. The ribbon: the fight's line is a curve with a heading the choreographer steers. The strip stays a wrapped conveyor of
// NC columns, so x still wraps and no reader changes; the two frontiers keep just beyond the camera's view, ground past them is
// nowhere yet, and a bend (at most the radius above) is laid there, never in view. D is the ribbon with the planet store ----
function archRibbon(run, o) {
  var s = mkStrip(), st = o.store ? mkStore() : null, C = { kind: 'ribbon', s: s, store: st, hi: 0, lo: 0, remA: 0, remB: 0, target: null, seam: 0, drop: 0, far: o.far ? { aC: 0, bC: 0, aRef: null, bRef: null, aLast: 0, bLast: 0 } : null }, K = o.K;
  // a far ring keeps a gap: with history a full ring long, the slot past a frontier holds ground from nearly a lap behind
  var FAR_STEP = 16, FAR_K = 4, MAX_LAID = o.far ? NC - 1200 : NC;
  // the line past a frontier once its remaining bend is spent, as a geodesic frame
  function farRef(hiEnd) {
    var c = hiEnd ? C.hi : C.lo, i = mod(c), p = getP(s, i), t = getT(s, i), rem = hiEnd ? C.remA : C.remB, sg = hiEnd ? 1 : -1, n = 0;
    while (Math.abs(rem) > 1e-9 && n < 400) { var f = along(p, t, sg), tr = turnOf(rem); p = f.p; t = rotT(f.p, f.t, tr); rem -= tr; n++; c += sg; }
    return { p: p, t: t, c: c };
  }
  function farStep(budget) {
    var F = C.far, n = 0;
    // a quarter of a ring flown since the last start: the far columns have been reused by now, so read them again
    if (F.mid0 != null && Math.abs((C.hi + C.lo) / 2 - F.mid0) > NC / 4) { F.aRef = null; F.bRef = null; }
    if (!F.aRef || !F.bRef) F.mid0 = (C.hi + C.lo) / 2;
    if (!F.aRef) { F.aRef = farRef(true); F.aC = 0; } if (!F.bRef) { F.bRef = farRef(false); F.bC = 0; }
    // the two ends share the strip, so they meet in the middle: each fills to half a ring from the pair's middle, and keeps
    // going as the pair moves
    var mid = (C.hi + C.lo) / 2, limA = mid + NC / 2, limB = mid - NC / 2, did = true;
    // a limit that retreats hands its slots to the other end, so the count comes back with it and they are read again when it returns
    if (F.aRef.c + F.aC * FAR_STEP > limA) F.aC = Math.max(0, Math.floor((limA - F.aRef.c) / FAR_STEP));
    if (F.bRef.c - F.bC * FAR_STEP < limB) F.bC = Math.max(0, Math.floor((F.bRef.c - limB) / FAR_STEP));
    while (n < budget && did) {
      did = false;
      var c = F.aRef.c + (F.aC + 1) * FAR_STEP;
      if (c <= limA) { F.aC++; if (c > C.hi) { fillFar(F.aRef, c, c - FAR_STEP, 1, c - FAR_STEP > C.hi); n++; } did = true; }
      if (n < budget) { var c2 = F.bRef.c - (F.bC + 1) * FAR_STEP; if (c2 >= limB) { F.bC++; if (c2 < C.lo) { fillFar(F.bRef, c2, c2 + FAR_STEP, -1, c2 + FAR_STEP < C.lo); n++; } did = true; } }
    }
    if (!did && F.t0 != null) { run.farFill.push(run.t - F.t0); F.t0 = null; }
  }
  function fillFar(ref, c, cPrev, sg, interp) {
    var fr = along(ref.p, ref.t, c - ref.c), h = noise(run, fr.p), i = mod(c), h0 = interp ? s.base[mod(cPrev)] : h;
    for (var k = 0; k <= FAR_STEP; k++) { var cc = cPrev + sg * k; if ((sg > 0 && cc <= C.hi) || (sg < 0 && cc >= C.lo)) continue; var j = mod(cc); s.base[j] = h0 + (h - h0) * k / FAR_STEP; s.read[j] = 0; s.def[j] = 0; s.tag[j] = 0; }
  }
  function turnOf(rem) { return rem > CFG.kappaCol ? CFG.kappaCol : rem < -CFG.kappaCol ? -CFG.kappaCol : rem; }
  function layCol(c, f) { var i = mod(c); setF(s, i, f); s.base[i] = noise(run, f.p); s.read[i] = 1; s.def[i] = 0; s.tag[i] = 0; stripFromStore(st, s, i); run.laid++; }
  function pushHi() {
    if (C.hi - C.lo + 1 >= MAX_LAID) dropEnd(0);
    var i = mod(C.hi), f = along(getP(s, i), getT(s, i), 1), tr = turnOf(C.remA);
    if (C.target) { var aim = bearingTo(f.p, f.t, C.target); tr = turnOf(aim); C.remA = 0; } else C.remA -= tr;
    if (tr) f.t = rotT(f.p, f.t, tr); C.hi++; layCol(C.hi, f); if (C.far && !tr) C.far.aLast = C.hi;
  }
  function pushLo() {
    if (C.hi - C.lo + 1 >= MAX_LAID) dropEnd(1);
    var i = mod(C.lo), f = along(getP(s, i), getT(s, i), -1), tr = turnOf(C.remB);
    if (C.target) { var b = [-f.t[0], -f.t[1], -f.t[2]], aim = -bearingTo(f.p, b, C.target); tr = turnOf(aim); C.remB = 0; } else C.remB -= tr;
    if (tr) f.t = rotT(f.p, f.t, tr); C.lo--; layCol(C.lo, f);
  }
  function dropEnd(hiSide) { if (hiSide) C.hi--; else C.lo++; C.drop++; }
  var LEAD = o.lead || 0, viewOf = function (gapCols) { return o.tight ? Math.ceil(Math.max(3600, gapCols * COL * 0.7 + 3000) / COL) : CFG.view; };
  C.pendAsk = [];
  C.init = function (p, t) { var i = mod(0), v0 = viewOf(3); setF(s, i, { p: p, t: t }); s.base[i] = noise(run, p); s.read[i] = 1; while (C.hi < v0 + CFG.margin) pushHi(); while (C.lo > -v0 - CFG.margin) pushLo(); run.evT = 0; };
  function applyAsk(rad) { C.remA = Math.max(-Math.PI, Math.min(Math.PI, C.remA + rad)); C.remB = Math.max(-Math.PI, Math.min(Math.PI, C.remB + rad)); if (C.far) { C.far.aRef = null; C.far.bRef = null; C.far.t0 = run.t; } }
  C.ask = function (rad) { if (LEAD) C.pendAsk.push({ at: run.t + LEAD, rad: rad }); else applyAsk(rad); run.turned(rad); };
  C.aimAt = function (q) { C.target = q; };
  C.step = function (w) {
    while (C.pendAsk.length && C.pendAsk[0].at <= run.t) applyAsk(C.pendAsk.shift().rad);
    var vh = viewOf(Math.abs(w.b - w.a)), n = 0, wantHi = o.tight ? Math.max(Math.ceil(w.m) + vh, Math.ceil(Math.max(w.a, w.b)) + 64) : Math.ceil(Math.max(w.a, w.b)) + CFG.view, wantLo = o.tight ? Math.min(Math.floor(w.m) - vh, Math.floor(Math.min(w.a, w.b)) - 64) : Math.floor(Math.min(w.a, w.b)) - CFG.view;
    while (C.hi < wantHi) { var e = run.evT; pushHi(); run.forced += run.evT - e; }          // the view's edge: must be there
    while (C.lo > wantLo) { var e2 = run.evT; pushLo(); run.forced += run.evT - e2; }
    while (n < K && C.hi < wantHi + CFG.margin) { pushHi(); n++; }                            // the margin: K a tick, both ends
    while (n < K && C.lo > wantLo - CFG.margin) { pushLo(); n++; }
    run.seamGap = Math.min(run.seamGap, Math.min(C.hi - wantHi, wantLo - C.lo));
    if (C.far) {
      farStep(Math.min(FAR_K, Math.max(0, K - n)));
      if (run.t % 30 === 7 && C.far.aRef && C.far.aC > 10) {     // how right is a far read? one sample against the real ground on the same line
        var cs = C.hi + 200; if (cs < C.far.aRef.c + (C.far.aC - 1) * FAR_STEP && cs > C.far.aRef.c + FAR_STEP) { var fq = along(C.far.aRef.p, C.far.aRef.t, cs - C.far.aRef.c), tr = surf(SEED, fq.p[0], fq.p[1], fq.p[2])[0], e = s.base[mod(cs)] - tr; run.farErrSq += e * e; run.farErrN++; }
      }
    }
  };
  C.dig = function (c, m) { if (st) storeAdd(st, m); stripDig(run, s, c, m); };
  C.peek = function (c) { if (c > C.hi) { var i = mod(C.hi); noise(run, along(getP(s, i), getT(s, i), c - C.hi).p); } else if (c < C.lo) { var j = mod(C.lo); noise(run, along(getP(s, j), getT(s, j), c - C.lo).p); } };
  C.axis = function (c) { var ci = c > C.hi ? C.hi : c < C.lo ? C.lo : c, i = mod(ci); return ci === c ? { p: getP(s, i), t: getT(s, i) } : along(getP(s, i), getT(s, i), c - ci); };
  C.height = function (c) { var i = mod(c); return s.base[i] + s.def[i]; };
  C.snap = function () { return { s: copyStrip(s), hi: C.hi, lo: C.lo, remA: C.remA, remB: C.remB, target: C.target, n: st ? st.log.length : 0, far: C.far && Object.assign({}, C.far), pendAsk: C.pendAsk.slice() }; };
  C.rest = function (o2) { pasteStrip(s, o2.s); C.hi = o2.hi; C.lo = o2.lo; C.remA = o2.remA; C.remB = o2.remB; C.target = o2.target; if (st) storeTrunc(st, o2.n); if (C.far) C.far = Object.assign({}, o2.far); C.pendAsk = o2.pendAsk.slice(); };
  C.hash = function () { return fnv(fnv(fnv(17, s.base), s.def), s.px) + C.hi * 7 + C.lo * 3 + (st ? st.log.length : 0); };
  C.bytes = function () { return { state: NC * 4 * 5 + 64 + (st ? st.log.length * 48 : 0), snapshot: NC * 4 * 5 + run.dirtyChunkBytes(), derived: NC * 48 }; };
  return C;
}
// ---- E. The field: the world round the pair is a 2D grid of nodes on the planet (a cube-sphere, so a node's value never
// depends on any bearing), with the planet store. The strip is a view re-laid from it; a turn rotates the view about the pair at
// any tick, in view. As a 2D sim the fighters would also leave the line; the read and the memory are this ----
function archField(run, o) {
  var G = o.G || CFG.fieldG, N = Math.round(Math.PI / 2 * R / G), nodes = new Map(), st = mkStore(), s = mkStrip();
  var E = { kind: 'field', s: s, store: st, p: null, t: null, m: 0, rem: 0, nodes: nodes, target: null, moved: 0 };
  function nodeAt(f, i, j) {
    var key = f * 1000000 + i * 1000 + j, v = nodes.get(key); if (v !== undefined) return v;
    var u = i / N * 2 - 1, w = j / N * 2 - 1, q = f === 0 ? [1, u, w] : f === 1 ? [-1, u, w] : f === 2 ? [u, 1, w] : f === 3 ? [u, -1, w] : f === 4 ? [u, w, 1] : [u, w, -1], p = norm(q);
    v = surf(SEED, p[0], p[1], p[2])[0]; run.evals++; run.evT++; nodes.set(key, v); return v;
  }
  function field(p) {
    var ax = Math.abs(p[0]), ay = Math.abs(p[1]), az = Math.abs(p[2]), f, u, w;
    if (ax >= ay && ax >= az) { f = p[0] > 0 ? 0 : 1; u = p[1] / ax; w = p[2] / ax; } else if (ay >= az) { f = p[1] > 0 ? 2 : 3; u = p[0] / ay; w = p[2] / ay; } else { f = p[2] > 0 ? 4 : 5; u = p[0] / az; w = p[1] / az; }
    var x = (u + 1) / 2 * N, y = (w + 1) / 2 * N, i = Math.min(N - 1, Math.floor(x)), j = Math.min(N - 1, Math.floor(y)), a = x - i, b = y - j; run.lookups++;
    return (nodeAt(f, i, j) * (1 - a) + nodeAt(f, i + 1, j) * a) * (1 - b) + (nodeAt(f, i, j + 1) * (1 - a) + nodeAt(f, i + 1, j + 1) * a) * b;
  }
  function relay(c0, c1) {
    var ms = storeNear(st, E.p).length || st.log.length ? st.log.filter(function (m) { return arcU(m.p, E.p) < CFG.view * COL * 1.3; }) : [];
    for (var c = c0; c <= c1; c++) {
      var i = mod(c), f = along(E.p, E.t, c - E.c), d = 0, tag = 0; setF(s, i, f); s.base[i] = field(f.p); s.read[i] = 1;
      for (var n = 0; n < ms.length; n++) { var v = craterAt(ms[n], arcU(f.p, ms[n].p)); if (v < 0) { d += v; tag = ms[n].id; } }
      s.def[i] = d; s.tag[i] = tag;
    }
  }
  function discEdge(fwd) {       // the part of the disc the pair's motion uncovered: an arc of nodes ahead
    var l = cross(E.p, E.t), sg = fwd ? 1 : -1, n = Math.ceil(2 * CFG.fieldHW / G);
    for (var k = -n / 2; k <= n / 2; k++) { var a = k * G / CFG.fieldHW, dx = Math.cos(a) * CFG.fieldHW * sg, dz = Math.sin(a) * CFG.fieldHW, q = norm([E.p[0] + (E.t[0] * dx + l[0] * dz) / R, E.p[1] + (E.t[1] * dx + l[1] * dz) / R, E.p[2] + (E.t[2] * dx + l[2] * dz) / R]); field(q); }
  }
  E.init = function (p, t) {
    E.p = p; E.t = t; E.c = 0; var l = cross(p, t), n = Math.ceil(CFG.fieldHW / G);
    for (var a = -n; a <= n; a++) for (var b = -n; b <= n; b++) { var dx = a * G, dz = b * G; if (dx * dx + dz * dz > CFG.fieldHW * CFG.fieldHW) continue; field(norm([p[0] + (t[0] * dx + l[0] * dz) / R, p[1] + (t[1] * dx + l[1] * dz) / R, p[2] + (t[2] * dx + l[2] * dz) / R])); }
    relay(-CFG.view, CFG.view); run.evT = 0;
  };
  E.ask = function (rad) { E.rem = Math.max(-Math.PI, Math.min(Math.PI, E.rem + rad)); run.turned(rad); };
  E.aimAt = function (q) { E.target = q; };
  E.step = function (w) {
    var c = Math.round(w.m), d = c - E.c;
    if (d) { var f = along(E.p, E.t, d); E.p = f.p; E.t = f.t; E.c = c; E.moved += Math.abs(d) * COL; while (E.moved >= G) { E.moved -= G; discEdge(d > 0); } }
    if (E.target) E.rem = bearingTo(E.p, E.t, E.target);
    var tr = E.rem > CFG.turnRate ? CFG.turnRate : E.rem < -CFG.turnRate ? -CFG.turnRate : E.rem;
    if (tr) { E.t = rotT(E.p, E.t, tr); E.rem -= tr; if (!E.target) { /* the ask's count is at the ask */ } relay(c - CFG.view, c + CFG.view); }
    else if (d) { var dn = d > 0; relay(dn ? c + CFG.view - d : c - CFG.view, dn ? c + CFG.view : c - CFG.view - d); }
  };
  E.dig = function (c, m) { storeAdd(st, m); stripDig(run, s, c, m); };
  E.peek = function (c) { field(along(E.p, E.t, c - E.c).p); };
  E.axis = function (c) { return along(E.p, E.t, c - E.c); };
  E.height = function (c) { var i = mod(c); return s.base[i] + s.def[i]; };
  E.snap = function () { return { s: copyStrip(s), p: E.p, t: E.t, c: E.c, rem: E.rem, target: E.target, moved: E.moved, n: st.log.length }; };
  E.rest = function (o2) { pasteStrip(s, o2.s); E.p = o2.p; E.t = o2.t; E.c = o2.c; E.rem = o2.rem; E.target = o2.target; E.moved = o2.moved; storeTrunc(st, o2.n); };
  E.hash = function () { return fnv(fnv(17, E.p), E.t) + E.c * 7 + st.log.length + fnv(17, s.def); };
  E.bytes = function () { return { state: 96 + st.log.length * 48, snapshot: 96 + (CFG.view * 2 + 1) * 8, derived: nodes.size * 12 + NC * 48 }; };
  return E;
}
var ARCHS = {
  'A-today': { name: 'A. Plane swap, today (K 12, caps on)', make: function (r) { return archSwap(r, { K: 12, caps: true }); } },
  'A-fast': { name: 'A2. Plane swap, fast (K 108, no caps)', make: function (r) { return archSwap(r, { K: 108, caps: false }); } },
  'B': { name: 'B. Lazy plane (patch and a lazy ring)', make: function (r) { return archLazyPlane(r, { K: CFG.K, store: false }); } },
  'B2': { name: 'B2. Lazy plane + planet store', make: function (r) { return archLazyPlane(r, { K: CFG.K, store: true }); } },
  'C': { name: 'C. Ribbon (steered curve, ring store)', make: function (r) { return archRibbon(r, { K: CFG.K, store: false }); } },
  'D': { name: 'D. Ribbon + planet store', make: function (r) { return archRibbon(r, { K: CFG.K, store: true }); } },
  'D2': { name: 'D2. Ribbon + planet store + coarse far ring', make: function (r) { return archRibbon(r, { K: CFG.K, store: true, far: true }); } },
  'D3': { name: 'D3. D2, frontier at the camera, 20-tick lead', make: function (r) { return archRibbon(r, { K: CFG.K, store: true, far: true, tight: true, lead: 20 }); } },
  'E': { name: 'E. 2D field, turntable (node 128 u)', make: function (r) { return archField(r, { G: 128 }); } },
  'E2': { name: 'E2. 2D field, turntable (node 512 u)', make: function (r) { return archField(r, { G: 512 }); } } };

// ---- a run: one architecture, ticked with the pair's columns ----
function mkRun(key, seedDir) {
  var run = { key: key, t: 0, evals: 0, evT: 0, hits: 0, forced: 0, lookups: 0, laid: 0, refused: 0, turns: 0, seamGap: 1e9, marks: [], nextId: 1, dugT: new Set(), evPeak: 0, evHist: [],
    farFill: [], farErrSq: 0, farErrN: 0, viewRewrites: 0, viewPopMax: 0, viewPopTicks: 0, reseen: 0, reseenMax: 0, asks: [], prev: new Float32Array(NC), prevC: new Float64Array(NC).fill(NaN), prevT: new Int32Array(NC).fill(-9), dirtyPeak: 0, laidWin: [] };
  run.turned = function (rad) { run.turns++; };
  run.dirtyChunkBytes = function () { return run.dirtyPeak * 64 * (4 + 48); };     // chunks of 64 columns of ground and frames rewritten in a 20-tick window
  var A = run.arch = ARCHS[key].make(run), p0 = norm(lonlat0()), t0 = norm(cross(p0, [0, 1, 0]));
  A.init(p0, t0);
  run.p0 = p0;
  run.tick = function (w) {
    run.evT = 0; run.dugT = new Set(); var laid0 = run.laid;
    var c0 = Math.round(w.a), c1 = Math.round(w.b); run.lastW = w;
    if (w.ask != null) { var ax = A.axis(Math.round(w.m)); run.asks.push({ t: run.t, rad: w.ask, t0: ax.t, p0: ax.p, done: null }); A.ask(w.ask); }
    if (w.aim && A.aimAt) A.aimAt(w.aim); else if (w.aim && !A.aimAt) { var ax2 = A.axis(Math.round(w.m)); if (run.t % 60 === 0) { var b = bearingTo(ax2.p, ax2.t, w.aim); if (Math.abs(b) > deg(1)) A.ask(b); } }
    A.step(w);
    if (w.dig) { var c = Math.round(w.dig.c), ax3 = A.axis(c), m = { id: run.nextId++, p: ax3.p, r: w.dig.r, d: w.dig.d, t: run.t }; run.marks.push(m); A.dig(c, m); }
    if (w.peek) for (var q = 0; q < w.peek.length; q++) A.peek(Math.round(w.peek[q]));
    // what the camera's widest view saw change this tick, apart from a crater dug now
    var m0 = Math.round(w.m), rewrites = 0, pop = 0, s = A.s;
    for (var o = -CFG.view; o <= CFG.view; o++) {
      var cc = m0 + o, i = mod(cc), h = s.base[i] + s.def[i]; if (A.kind === 'ribbon' && (cc > A.hi || cc < A.lo)) continue;
      if (run.prevC[i] === cc && !run.dugT.has(i)) {
        var dh = Math.abs(h - run.prev[i]);
        if (dh > 0.5) { if (run.prevT[i] === run.t - 1) { rewrites++; if (dh > pop) pop = dh; } else { run.reseen++; if (dh > run.reseenMax) run.reseenMax = dh; } }     // seen a tick ago: a pop; seen earlier: it changed while away
      }
      run.prev[i] = h; run.prevC[i] = cc; run.prevT[i] = run.t;
    }
    if (rewrites) { run.viewRewrites += rewrites; run.viewPopTicks++; if (pop > run.viewPopMax) run.viewPopMax = pop; }
    // the ground under a fighter, the same column a tick apart
    run.asks.forEach(function (as) { if (as.done == null) { var ax4 = A.axis(m0), ang = Math.abs(bearingBetween(ax4, as)); if (ang >= 0.5 * Math.abs(as.rad)) as.done = run.t - as.t; } });
    run.laidWin.push(run.laid - laid0); if (run.laidWin.length > 20) run.laidWin.shift(); var lw = 0; for (var q2 = 0; q2 < run.laidWin.length; q2++) lw += run.laidWin[q2]; var ch = Math.ceil(lw / 64) + 2; if (lw && ch > run.dirtyPeak) run.dirtyPeak = ch;
    run.evHist.push(run.evT); if (run.evT > run.evPeak) run.evPeak = run.evT;
    run.t++;
  };
  run.dirtyMark = function () {};
  return run;
}
function bearingBetween(ax, as) { var n = cross(ax.p, ax.t), n0 = cross(as.p0, as.t0), c = cross(n, n0); return atan2f(Math.sqrt(dot(c, c)), dot(n, n0)); }
function lonlat0() { return [cos(0.6) * cos(1.2), sin(0.6) * 0.2, cos(0.6) * sin(1.2)]; }

// ---- the fight: one seeded script of the pair along the line, whatever the world under it ----
function lcg(seed) { var x = seed >>> 0; return function () { x = (Math.imul(x, 1664525) + 1013904223) >>> 0; return x / 4294967296; }; }
function genFight(seed, scen, ticks) {
  var rnd = lcg(seed * 7919 + 13), out = [], m = 0, gap = 3, v = 0, ph = 'brawl', left = 200, dir = 1, nextAsk = 120, flew = 0;
  for (var t = 0; t < ticks; t++) {
    var w = { calm: false, dig: null, ask: null, peek: null };
    if (left-- <= 0) {
      var r = rnd();
      if (ph === 'brawl' || ph === 'settle') { if (r < 0.45) { ph = 'send'; left = 90; dir = rnd() < 0.5 ? -1 : 1; v = 3.1 * dir; w.peek = [m + dir * 200, m + dir * 240, m + dir * 280, m - dir * 200, m + dir * 120]; } else if (r < 0.8) { ph = 'dash'; left = 60 + rnd() * 360; dir = rnd() < 0.7 ? dir : -dir; v = 5.33 * dir; } else { ph = 'brawl'; left = 120 + rnd() * 240; v = (rnd() - 0.5) * 0.4; } }
      else if (ph === 'send') { ph = 'settle'; left = 30 + rnd() * 90; v = 0; w.dig = { c: m + dir * gap / 2, r: 300 + rnd() * 600, d: 120 + rnd() * 200 }; }
      else { ph = 'brawl'; left = 120 + rnd() * 300; v = (rnd() - 0.5) * 0.4; }
    }
    if (ph === 'send') { v *= 0.99; gap = Math.min(300, gap + 3); } else gap = Math.max(3, gap - 3);
    if (ph === 'brawl' && !w.dig && rnd() < 0.003) w.dig = { c: m, r: 150 + rnd() * 200, d: 60 };
    m += v; w.m = m; w.a = m - gap / 2; w.b = m + gap / 2;
    w.calm = ph === 'settle' || (ph === 'brawl' && Math.abs(v) < 0.1);
    if (scen === 'calm' && ph === 'settle' && left < 20 && t >= nextAsk) { w.ask = deg(10) * (rnd() < 0.5 ? -1 : 1); nextAsk = t + 3700; }
    if (scen === 'any' && t >= nextAsk) { w.ask = deg(10 + rnd() * 50) * (rnd() < 0.5 ? -1 : 1); nextAsk = t + 120 + rnd() * 180; }
    if (scen === 'hard' && t >= nextAsk) { w.ask = deg(60) * (rnd() < 0.5 ? -1 : 1); nextAsk = t + 30; }
    out.push(w);
  }
  return out;
}
// a straight flight: lap is one lap, unsteered or with a turn at half way; home flies away then aims at a place
function genLap(steer) { var out = [], m = 0; for (var t = 0; t < 1000; t++) { m += 5.33; var w = { m: m, a: m - 2, b: m + 2, calm: false, dig: t === 2 ? { c: m, r: 500, d: 150 } : null, ask: steer && t === 450 ? deg(90) : null, peek: null }; out.push(w); } return out; }
function genCross(q) { var out = [], m = 0; for (var t = 0; t < 1500; t++) { m += 5.33; out.push({ m: m, a: m - 2, b: m + 2, calm: false, dig: t === 1 ? { c: Math.round(m), r: 800, d: 300 } : null, ask: null, peek: null, aim: t >= 240 && q.q ? q.q : null }); } return out; }
function genLaunch(deg0) { var out = [], m = 0; for (var t = 0; t < 420; t++) { var fly = t >= 60; if (fly) m += 3.125; out.push({ m: m, a: fly ? m - 60 : m - 3, b: fly ? m + 2 : m + 3, calm: !fly, dig: null, ask: t === 60 ? deg(deg0) : null, peek: null }); } return out; }
function genHome(q) { var out = []; var m = 0; for (var t = 0; t < 1300; t++) { m += 5.33; out.push({ m: m, a: m - 2, b: m + 2, calm: false, dig: null, ask: null, peek: null, aim: t >= 60 ? q : null }); } return out; }

// marks at the end: right (a column shows it where it was dug), moved (it shows, more than its radius from where it was
// dug), gone (no column shows it: the ring forgot it). "Revisit" asks the store: a later pass over the place would find it
function marksReport(run) {
  var A = run.arch, s = A.s, seen = {}, right = 0, moved = 0, gone = 0;
  for (var i = 0; i < NC; i++) if (s.tag[i] && s.read[i]) { var m = run.marks[s.tag[i] - 1], d = arcU(getP(s, i), m.p); if (!seen[m.id] || d < seen[m.id]) seen[m.id] = d + 0.001; }
  run.marks.forEach(function (m) { var d = seen[m.id]; if (d == null) gone++; else if (d <= m.r) right++; else moved++; });
  return { marks: run.marks.length, right: right, moved: moved, gone: gone, store: A.store ? A.store.log.length : 0, revisit: A.store ? run.marks.length : right };
}
function summarize(run, jsMs) {
  var h = run.evHist.slice().sort(function (a, b) { return a - b; }), n = h.length, sum = 0; for (var i = 0; i < n; i++) sum += h[i];
  var dn = run.asks.filter(function (a) { return a.done != null; }).map(function (a) { return a.done; }).sort(function (a, b) { return a - b; });
  var ff = run.farFill.slice().sort(function (a, b) { return a - b; });
  return { farFillP50: ff.length ? ff[ff.length >> 1] : null, farFillN: ff.length, farErrRms: run.farErrN ? Math.sqrt(run.farErrSq / run.farErrN) : null, reseen: run.reseen, reseenMax: run.reseenMax, evalsTotal: run.evals, evalsMean: sum / n, evalsP99: h[Math.floor(n * 0.99)], evalsMax: h[n - 1], forced: run.forced, lookups: run.lookups, popTicks: run.viewPopTicks, popCols: run.viewRewrites, popMax: run.viewPopMax,
    asks: run.asks.length, refused: run.refused, realised: dn.length, latP50: dn.length ? dn[dn.length >> 1] : null, latP90: dn.length ? dn[Math.floor(dn.length * 0.9)] : null, seamGap: run.seamGap, bytes: run.arch.bytes(), jsMs: jsMs };
}
return { COL: COL, NC: NC, W: W, CFG: CFG, ARCHS: ARCHS, mkRun: mkRun, genFight: genFight, genLap: genLap, genHome: genHome, genCross: genCross, genLaunch: genLaunch, marksReport: marksReport, summarize: summarize, clearMemo: clearMemo, arcU: arcU, mod: mod, getP: getP, getT: getT, along: along, deg: deg, norm: norm, cross: cross, dot: dot, storeNear: storeNear };
})();
