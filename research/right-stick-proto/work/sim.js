// ==== STICK SIM (no DOM) ====
// Right stick, step 1, v2: reworked for one thumb (docs/design/right-stick-pitches.md section 13, Controls' law in
// docs/controls/right-thumb.md) over section 11 and 12's commands (pitch C's family stick), read with Controls'
// fixed thresholds (docs/controls/right-stick.md section 11). The recognizer reads one sample a tick: the dead zone, the
// on/off hysteresis, the flick by its onset speed, the hold, and the family locked at the first deflection. Patterns are
// off in step 1: the panel only names the ones it sees, as "step 2". No DOM: the page drives it, and gif.mjs runs the same
// code in node for the homework clips. 60 ticks a second, no randomness (a hash for every jitter), flat polygons only.
var S = (function () {
'use strict';
var W = 1020, H = 340, AW = 720, GY = 300;
var BH = 56;                        // a body height, drawn and as the unit of distance (1 bh = 56 px)
var KEY = '#0a0d14';
var C = { bg: '#f3f1ea', ground: '#e8e6dc', line: '#888780', dirt: '#b3a991', scorch: '#6d6a62', shade: '#d6d4c9', grey: '#a9a79e',
  cliff: '#a39a8a', cliffDark: '#7d7466', lake: '#7fb0cf', lakeLite: '#c9e2ef', ink: '#1f1f1c', hud: '#d3d1c7',
  panel: '#e6e3d9', ring: '#b9b6ab', dead: '#d3d0c4', dim: '#8a877d' };
function lane(core, main, edge) { return { core: core, main: main, edge: edge }; }
var FIGHTERS = [
  { id: 'protagonist', name: 'Protagonist', body: '#1f4f4a',
    L: { bolt: lane('#f2fdff', '#10c2ea', '#0b7fb8'), lob: lane('#ecfaff', '#1eb0f4', '#0e6cc4'), beam: lane('#f4faff', '#2e90f2', '#0d58c4'), trap: lane('#e8f5ff', '#2a9cf4', '#0f62bc') }, sweep: 32, bw: 1.2 },
  { id: 'rival', name: 'Rival', body: '#33295a',
    L: { bolt: lane('#f0e6ff', '#4420c4', '#2e0c78'), lob: lane('#f6e6ff', '#5c1ca8', '#3c0c6c'), beam: lane('#ffe8fb', '#80127e', '#5a0c64'), trap: lane('#eee4ff', '#4c20ac', '#300c70') }, sweep: 34, bw: 0.85 }];

// ---- Controls' step-1 thresholds (right-stick.md section 11) and GD's step-1 moves (pitches section 11, first values) ----
var RS = { deadZone: 0.25, on: 0.60, off: 0.35, rest: 0.2, flickRise: 3, flickSettle: 2, holdTicks: 10, holdDirs: 32, flightHyst: 8 };
// a step and a hop take L ticks (section 13), so the commitment ends where they do
var MV = { lungeKi: 10, stepIn: 1, stepBack: 2, stepT: 6, hop: 2, hopT: 6, slip: 4, flight: 2.6,
  dash: 6, dashFree: 12, dashKi: 12, orbitRate: 4.5, wall: 4.5, skim: 5, skimAlt: 1, settle: 8, repeatWin: 180,
  latch: 45, seek: 30, layReach: 3 };
// The press's bands and the brawl, from data/director/interrupts.json (bands, brawl) and data/combat/templates.json (the
// striking distance, contact.offset 58 u), with 1 bh = 75 u. "In reach" is the close band.
var BD = { close: 3, mid: 12.5, engage: 2.5, rush: 4000 / 75 / 60, lungeMin: 3, lungeMax: 20, farMin: 6, farMax: 90, pressWind: 6 };
var BR = { closeMaxBh: 0.6, strike: 58 / 75, leash: 2.4, give: 5 / 60, pull: 0.5 / 60, breakBh: 4.5, idle: 60, closePerBh: 2, closeMax: 4, contact: 2, blowT: 12, reach: 0.6, crossT: 16, nudge: 0.4 };
var SPARK = { core: '#ffffff', main: '#f4efe3', edge: '#8a857a' };
// Section 13's law (R28 to R38): a stick command commits him for L ticks; a face press inside the commitment or a hold
// queues (3 deep, kept W ticks) and starts at its end; a read lasts until it fires or 90 ticks, for 3 ki
var LAW = { L: 6, W: 36, qMax: 3, readT: 90, readKi: 3, slipT: 12 };
var N = { boltGap: 6, beamLv: [30, 54, 84], beamLen: [20, 36, 54], pulseAdd: 4, lobT: 36 };

function hash(n) { n = (n ^ 61) ^ (n >>> 16); n = (n + (n << 3)) | 0; n ^= n >>> 4; n = Math.imul(n, 0x27d4eb2d); n ^= n >>> 15; return (n >>> 0) / 4294967296; }
function ease(x) { return x < 0 ? 0 : x > 1 ? 1 : 1 - (1 - x) * (1 - x); }
function easeIO(x) { return x < 0 ? 0 : x > 1 ? 1 : x < 0.5 ? 2 * x * x : 1 - 2 * (1 - x) * (1 - x); }
function lerp(a, b, k) { return a + (b - a) * k; }
function clamp(v, a, b) { return v < a ? a : v > b ? b : v; }
function angN(a) { while (a > Math.PI) a -= 2 * Math.PI; while (a < -Math.PI) a += 2 * Math.PI; return a; }
function deg(d) { return d * Math.PI / 180; }
function sy(alt) { return GY - alt; }

// ---- shapes ----
function ngon(cx, cy, r, n, rot) { var p = []; for (var i = 0; i < n; i++) { var a = rot + i * 2 * Math.PI / n; p.push(cx + Math.cos(a) * r, cy + Math.sin(a) * r); } return p; }
function star(cx, cy, r1, r2, n, rot) { var p = []; for (var i = 0; i < 2 * n; i++) { var a = rot + i * Math.PI / n, r = i % 2 ? r2 : r1; p.push(cx + Math.cos(a) * r, cy + Math.sin(a) * r); } return p; }
function xf(pts, cx, cy, rot, sx, sy2) { var c = Math.cos(rot), s = Math.sin(rot), o = []; for (var i = 0; i < pts.length; i += 2) { var x = pts[i] * sx, y = pts[i + 1] * sy2; o.push(cx + x * c - y * s, cy + x * s + y * c); } return o; }
function quad(R, ax, ay, bx, by, w0, w1, col) {
  var dx = bx - ax, dy = by - ay, l = Math.sqrt(dx * dx + dy * dy) || 1, nx = -dy / l, ny = dx / l;
  R.poly([ax + nx * w0 / 2, ay + ny * w0 / 2, bx + nx * w1 / 2, by + ny * w1 / 2, bx - nx * w1 / 2, by - ny * w1 / 2, ax - nx * w0 / 2, ay - ny * w0 / 2], col);
}
function limb(R, a, b, w, col) { quad(R, a[0], a[1], b[0], b[1], w, w, col); R.poly(ngon(a[0], a[1], w / 2, 8, 0.39), col); R.poly(ngon(b[0], b[1], w / 2, 8, 0.39), col); }
function ring(R, cx, cy, r, w, col, n) { n = n || 24; for (var i = 0; i < n; i++) { var a0 = i * 6.283 / n, a1 = (i + 1) * 6.283 / n; quad(R, cx + Math.cos(a0) * r, cy + Math.sin(a0) * r, cx + Math.cos(a1) * r, cy + Math.sin(a1) * r, w, w, col); } }
function spr(R, shp, l, wd, lc) { R.poly(shp(l + 3.5, wd + 3.5), KEY); R.poly(shp(l + 1.8, wd + 1.8), lc.edge); R.poly(shp(l, wd), lc.main); if (l > 3 && wd > 1.5) R.poly(shp(l * 0.45, wd * 0.45), lc.core); }

// ---- the recognizer: one quantised sample a tick, the family locked at the first deflection ----
function mkReader() { return { on: false, lastRest: -99, crossT: -99, isFlick: false, flickDone: true, peak: null, holdN: 0, d4: null, fam: null, famOut: false,
  trace: [], log: [], pat: { open: false, sum: 0, prevA: null, start: -99, restN: 0, axisSign: 0, axisV: null, strokes: 0, sec: -1, secT: 0, turn0: -1, turn1: -1, said: {}, flicks: [] } }; }
function quant(x, y) {
  var m = Math.sqrt(x * x + y * y); if (m < RS.deadZone) return { x: 0, y: 0, m: 0 };
  var r = Math.round(Math.min(1, (m - RS.deadZone) / (1 - RS.deadZone)) * 16) / 16; return { x: x / m * r, y: y / m * r, m: r };
}
// four ways on the screen, a tie to the vertical; y is the screen's (down positive)
function dir4(x, y) { return Math.abs(y) >= Math.abs(x) ? (y < 0 ? 'up' : 'down') : (x > 0 ? 'right' : 'left'); }
var D4A = { right: 0, up: 90, left: 180, down: 270 };
function famOf(mask) { return mask === 0 ? 'flight' : mask === 2 ? 'aim' : mask === 3 ? 'lay' : mask === 1 ? 'read' : 'none'; }
// returns this tick's events: a flick (screen direction), the hold level (four-way with hysteresis, a 32-way angle,
// a magnitude band) and the release
function readDpad(rd, t, dx, dy, mask) {
  var out = { flick: null, hold: null, release: false, fam: null, q: { x: 0, y: 0, m: 0 }, dpad: true }, on = !!(dx || dy);
  rd.trace.push([0, 0]); if (rd.trace.length > 44) rd.trace.shift();
  if (on && !rd.dpOn) { rd.dpOn = true; rd.dpT = t; rd.dpHeld = false; rd.fam = famOf(mask); out.flick = dir4(dx, dy); }
  else if (on && t - rd.dpT >= RS.holdTicks) { rd.dpHeld = true; var a = Math.atan2(-dy, dx) * 180 / Math.PI; if (a < 0) a += 360; a = Math.round(a / 45) % 8 * 45; out.hold = { d4: dir4(dx, dy), ang: a, band: 3 }; }
  out.fam = rd.fam;     // the release still reads in the family it held
  if (!on && rd.dpOn) { rd.dpOn = false; if (rd.dpHeld) out.release = true; rd.dpHeld = false; rd.fam = null; }
  rd.dpVec = [dx, dy]; return out;
}
function readStick(rd, t, x, y, mask, dp) {
  if (dp && (dp.x || dp.y) || rd.dpOn) return readDpad(rd, t, dp ? dp.x : 0, dp ? dp.y : 0, mask);
  rd.dpVec = [0, 0];
  var q = quant(x, y), out = { flick: null, hold: null, release: false, fam: null, q: q };
  rd.trace.push([x, y]); if (rd.trace.length > 44) rd.trace.shift();
  if (q.m <= RS.rest) { if (!rd.on) rd.fam = null; }     // the stick rests: the next gesture reads the new family (R23)
  else if (rd.fam == null) { rd.fam = famOf(mask); }
  out.fam = rd.fam;
  if (q.m <= RS.rest) rd.lastRest = t;
  if (!rd.on && q.m >= RS.on) { rd.on = true; rd.crossT = t; rd.isFlick = t - rd.lastRest <= RS.flickRise; rd.flickDone = !rd.isFlick; rd.holdN = 0; rd.held = false; rd.d4 = null; rd.peak = q; }
  else if (rd.on && q.m < RS.off) {
    if (!rd.flickDone) { out.flick = dir4(rd.peak.x, rd.peak.y); rd.flickDone = true; }     // a flick quicker than the settle still fires
    rd.on = false; if (rd.held) out.release = true; rd.holdN = 0; rd.held = false;
  }
  if (rd.on) {
    rd.holdN++; if (q.m >= rd.peak.m) rd.peak = q;
    if (!rd.flickDone && t - rd.crossT >= RS.flickSettle) { out.flick = dir4(q.x, q.y); rd.flickDone = true; }
    if (t - rd.crossT >= RS.holdTicks) {
      rd.held = true; var a = Math.atan2(-q.y, q.x) * 180 / Math.PI; if (a < 0) a += 360;
      var step = 360 / RS.holdDirs, a32 = Math.round(a / step) % RS.holdDirs * step;
      // Flight reads a hold four ways, with 8 degrees of hysteresis at the diagonals
      var nd = dir4(q.x, q.y);
      if (rd.d4) { var off = Math.abs(((a - D4A[rd.d4]) % 360 + 540) % 360 - 180); if (off <= 45 + RS.flightHyst) nd = rd.d4; }
      rd.d4 = nd;
      out.hold = { d4: nd, ang: a32, band: q.m < 0.5 ? 1 : q.m < 0.8 ? 2 : 3 };
    }
  }
  patterns(rd, t, q, out);
  return out;
}
// Patterns are step 2's. Here they only name themselves in the panel (R20): the flicks and holds inside them still act.
// They are off wherever the stick aims, under RB and the lay (R15). The collector opens at the first sample past rest and
// closes after 5 ticks at rest or 12 with no new sector (Controls section 3); R22's windows: a zig-zag's two reversals on
// one line inside 48 ticks, a half-circle of 140 to 250 degrees inside 36, a circle of 300 or more inside 48; a pump is two
// flicks the same way in a row within 18 ticks (R27).
function resetPat(P2) { P2.open = false; P2.sum = 0; P2.prevA = null; P2.strokes = 0; P2.axisSign = 0; P2.axisV = null; P2.sec = -1; P2.secT = 0; P2.restN = 0; P2.turn0 = -1; P2.turn1 = -1; P2.said = {}; }
function closePat(rd, t) { var P2 = rd.pat; if (Math.abs(P2.sum) >= 140 && Math.abs(P2.sum) <= 250 && P2.turn1 - P2.turn0 <= 36) say(rd, t, 'half-circle'); resetPat(P2); }
function patterns(rd, t, q, out) {
  var P2 = rd.pat;
  if (rd.fam === 'aim' || rd.fam === 'lay') { if (P2.open) resetPat(P2); P2.flicks = []; return; }
  if (q.m <= RS.rest) { if (P2.open && ++P2.restN >= 5) closePat(rd, t); }
  else {
    if (!P2.open) { resetPat(P2); P2.open = true; P2.start = t; P2.secT = t; }
    P2.restN = 0;
    var sec = Math.round(((Math.atan2(-q.y, q.x) * 180 / Math.PI) + 360) / 45) % 8;
    if (sec !== P2.sec) { P2.sec = sec; P2.secT = t; } else if (t - P2.secT > 12) closePat(rd, t);
  }
  if (P2.open) {
    if (q.m > RS.off) { var a = Math.atan2(-q.y, q.x) * 180 / Math.PI; if (P2.prevA != null) { var dA = ((a - P2.prevA) % 360 + 540) % 360 - 180; if (Math.abs(dA) < 90 && dA) { P2.sum += dA; if (P2.turn0 < 0) P2.turn0 = t; P2.turn1 = t; } } P2.prevA = a; } else P2.prevA = null;     // through the middle is a stroke, not a turn
    if (Math.abs(P2.sum) >= 300 && t - P2.start <= 48) say(rd, t, 'circle');
    var vert = Math.abs(q.y) >= Math.abs(q.x), ax = vert ? q.y : q.x;     // a stroke reverses along one line; a turn onto the other axis starts over
    if (Math.abs(ax) >= 0.6) { var sg = ax > 0 ? 1 : -1; if (P2.axisV !== vert) { P2.axisV = vert; P2.axisSign = 0; P2.strokes = 0; } if (P2.axisSign && sg !== P2.axisSign) { P2.strokes++; if (P2.strokes >= 2 && t - P2.start <= 48) say(rd, t, 'zig-zag'); } P2.axisSign = sg; }
  }
  if (out.flick) { var lf = P2.flicks[P2.flicks.length - 1]; if (lf && lf.d === out.flick && t - lf.t <= 18) say(rd, t, 'pump'); P2.flicks = [{ t: t, d: out.flick }]; }
}
function say(rd, t, k) { if (rd.pat.said[k]) return; rd.pat.said[k] = 1; note(rd, t, k.toUpperCase() + ': STEP 2', true); }
function note(rd, t, text, dim) { rd.log.unshift({ t: t, text: text, dim: !!dim }); if (rd.log.length > 6) rd.log.pop(); }

// ---- the world: the Protagonist (you), the Rival (a stand-in), a cliff to run up and a lake to skim ----
var CLIFF = { x: 660, top: 200 }, LAKE = { x0: 250, x1: 470 };
function mkF(def, x, alt) { return { def: def, x: x, y: alt, dir: 1, ki: 100, vx: 0, vy: 0, mv: null, cmd: null, slip: 0, settle: 0, aimOff: 0, latched: false,
  bchg: null, beam: null, lastBolt: -99, seq: null, wait: 0, blow: null, cross: null, giving: false, reps: { step: [], hop: [] }, reel: 0, orbit: null, tilt: 0, layOff: null, prev: {}, lean: 0, dashT: 0, skimDir: 0, home: [x, alt],
  commit: 0, q: [], dodgeT: 0, slipK: null, slipT: 0, read: null, caught: 0, flurry: null, grabLock: 0, tl: [] }; }
function newWorld(clip, take, mode, lane2) {
  var T = clip ? clip.takes[take] : null;
  var w = { t: 0, mode: mode, clip: clip, brawl: null, grabs: [], P: mkF(FIGHTERS[0], 160, 60), V: mkF(FIGHTERS[1], 540, 80), shots: [], fx: [], marks: [], mines: [], rd: mkReader(), seq: 0, sound: [], inp: {} };
  w.P.foe = w.V; w.V.foe = w.P;
  if (T && (lane2 ? T.setup2 || T.setup : T.setup)) (lane2 ? T.setup2 || T.setup : T.setup)(w);
  w.V.home = [w.V.x, w.V.y]; w.cam0 = (w.P.x + w.V.x) / 2;
  return w;
}
function hand(f) { return [f.x + f.dir * 22, f.y + 40]; }
function chest(f) { return [f.x, f.y + 40]; }
function dist(a, b) { var dx = b.x - a.x, dy = b.y - a.y; return Math.sqrt(dx * dx + dy * dy); }
function burst(w, x, alt, r, dur, lc, n) { w.fx.push({ k: 'burst', x: x, y: alt, r: r, t: 0, dur: dur, lc: lc, n: n || 7, rot: hash(w.seq++) * 6.28 }); }
function chips(w, x, alt, n, col, sp, up) { for (var i = 0; i < n; i++) { var a = hash(w.seq++) * 6.283, v = (sp || 3) * (0.5 + hash(w.seq++)); w.fx.push({ k: 'chip', x: x, y: alt, vx: Math.cos(a) * v, vy: Math.abs(Math.sin(a)) * v * (up ? 1.4 : 0.6) + 1, s: 2 + hash(w.seq++) * 2.5, t: 0, dur: 14 + hash(w.seq++) * 12, col: col, rot: hash(w.seq++) * 6 }); } }
function overLake(x) { return x > LAKE.x0 && x < LAKE.x1; }
function floor(x) { return x > CLIFF.x ? CLIFF.top : 0; }
// keep him out of the cliff: below its top he stays left of the face
function bound(f) { var x0 = f.x; f.y = clamp(f.y, 0, 270); if (f.y < CLIFF.top && f.x > CLIFF.x - 14) f.x = CLIFF.x - 14; f.x = clamp(f.x, 18, AW - 18); if (f.x !== x0) f.lag = true; if (f.x > CLIFF.x) f.y = Math.max(f.y, CLIFF.top); }

// ---- the brawl (a stand-in for sim/director/brawl.gd): blows at striking distance, the pull, the leash, the break ----
function bhOf(f) { return dist(f, f.foe) / BH; }
function rushTicks(d) { return clamp(Math.ceil(d / BD.rush), d > BD.mid ? BD.farMin : BD.lungeMin, d > BD.mid ? BD.farMax : BD.lungeMax); }
function closeTicks(gap) { return Math.max(clamp(Math.ceil(gap * BR.closePerBh), 1, BR.closeMax), Math.ceil(gap / BR.closeMaxBh)); }     // and no more than closeMaxBh a tick
// where he stands g bh from the rival, on his own side and at the rival's height
function spotAt(f, g) {
  var s2 = f.x <= f.foe.x ? -1 : 1, x = f.foe.x + s2 * g * BH, y = f.foe.y, fx = CLIFF.x - 14, r = g * BH;
  if (y < CLIFF.top && x > fx) {
    var dx = Math.max(0, fx - f.foe.x), dy = Math.sqrt(Math.max(0, r * r - dx * dx)); x = fx; y = f.foe.y + dy;
    if (y >= CLIFF.top) { var ty = CLIFF.top - f.foe.y; y = CLIFF.top; x = Math.max(fx, f.foe.x + Math.sqrt(Math.max(0, r * r - ty * ty))); }
  }
  return [x, y];
}
// a move never passes through the cliff: from below its top he stops at the face, from on top he keeps to the top
function cuts(x0, y0, x1, y1, cx, cy) {     // does the step enter the rock (right of the face, below the top)?
  var a0 = 0, a1 = 1, dx = x1 - x0, dy = y1 - y0;
  if (Math.abs(dx) < 1e-9) { if (x0 <= cx) return false; } else { var t = (cx - x0) / dx; if (dx > 0) a0 = Math.max(a0, t); else a1 = Math.min(a1, t); }
  if (Math.abs(dy) < 1e-9) { if (y0 >= cy) return false; } else { var u = (cy - y0) / dy; if (dy < 0) a0 = Math.max(a0, u); else a1 = Math.min(a1, u); }
  return a1 - a0 > 1e-6;
}
function rock(f, ox, oy, cap) {
  var cx = CLIFF.x - 14, cy = CLIFF.top, nx = f.x, ny = f.y, len = Math.sqrt((nx - ox) * (nx - ox) + (ny - oy) * (ny - oy));
  if (f.lag && cap && len > cap) { nx = ox + (nx - ox) * cap / len; ny = oy + (ny - oy) * cap / len; len = cap; }
  if (cuts(ox, oy, nx, ny, cx, cy)) {
    if (oy < cy && ny < cy) nx = Math.min(nx, cx);
    else { var dc = Math.sqrt((cx - ox) * (cx - ox) + (cy - oy) * (cy - oy));
      if (len <= dc) { nx = ox + (cx - ox) / (dc || 1) * len; ny = oy + (cy - oy) / (dc || 1) * len; }
      else { var dn = Math.sqrt((nx - cx) * (nx - cx) + (ny - cy) * (ny - cy)) || 1, k = Math.min(1, (len - dc) / dn); nx = cx + (nx - cx) * k; ny = cy + (ny - cy) * k; if (ny < cy && nx > cx) nx = cx; } }
  }
  f.lag = Math.abs(nx - f.x) > 0.01 || Math.abs(ny - f.y) > 0.01; f.x = nx; f.y = ny;
}
function plan(f, steps) { f.seq = steps; if (!/^crossed/.test(f.cmd || '')) f.cmd = null; f.orbit = null; nextStep(f); }
function nextStep(f) {
  var st = f.seq && f.seq.shift(); if (!st) { f.seq = null; return; }
  if (st.k === 'move') { var to = st.to(); tween(f, st.kind, to[0], to[1], typeof st.dur === 'function' ? st.dur() : st.dur); f.mv.seq = true; }
  else if (st.k === 'wait') f.wait = st.n;
  else if (st.k === 'blow') f.blow = { t: 0 };
}
function startBrawl(w) { if (w.brawl) return; w.brawl = { t: 0, idle: 0 }; note(w.rd, w.t, 'BRAWL ON'); }
function endBrawl(w, why) { w.brawl = null; w.P.giving = false; note(w.rd, w.t, 'BRAWL ENDS: ' + why); }
// X with no shoulder: a press. From the mid or far band it lunges in with its blow; in the close band or a brawl it closes
// to striking distance and strikes. A press under way takes no stick command (the press wins, section 12 row 1).
var SLIPNAME = { neutral: 'THE DODGE', away: 'A SLIP BACK', toward: 'A SLIP IN', up: 'A SWAY UP', down: 'A DUCK' };
// something other than the stick ends a hold (a slip, a read): it locks out L as a release would, and the stick he still holds
// is spent until he lets it go, so it can't re-arm the hold
// caught: the arc, a hold, a plan, a charge, a beam and a flick still waiting all end where he is
function caughtNow(f) { breakHold(f); f.read = null; f.cross = null; f.mv = null; f.seq = null; f.wait = 0; f.blow = null; f.cmd = null; f.orbit = null; f.pend = null; f.stepIn = null; f.bchg = null; f.beam = null; f.vx = f.vy = 0; f.giving = false; }
function breakHold(f) { if (holdOn(f) || /^crossed/.test(f.cmd || '')) { f.commit = Math.max(f.commit, LAW.L); f.spent = true; } }
function slipDodge(w, f, i) {
  if (f.cross) { note(w.rd, w.t, 'NO SLIP IN THE ARC', true); return; }     // section 12 row 5: the cross-up has no slip
  var lx = i.lx || 0, ly = i.ly || 0, k = Math.abs(lx) < 0.3 && Math.abs(ly) < 0.3 ? 'neutral' : rel(f, dir4(lx, ly)), sx = f.foe.x >= f.x ? 1 : -1;
  breakHold(f); f.pend = null; f.dodgeT = LAW.slipT; f.slipK = SLIPNAME[k]; f.slipD = k; f.slipT = 0; f.seq = null; f.wait = 0; f.blow = null; f.cmd = null; f.orbit = null; f.stepIn = null;
  if (k === 'neutral') tween(f, 'dodge', f.x - sx * 0.5 * BH, f.y, 10);
  else if (k === 'away') tween(f, 'dodge', f.x - sx * 1.1 * BH, f.y, 10);
  else if (k === 'toward') tween(f, 'dodge', f.x + sx * clamp(Math.abs(f.foe.x - f.x) - 0.5 * BH, 0, 1.1 * BH), f.y, 10);     // inside his arm, at most 1.1 bh: never a free lunge
  else { f.mv = null; f.sway = k; f.vx = f.vy = 0; f.settle = 0; }
  note(w.rd, w.t, 'LT' + (k === 'neutral' ? '' : ' + ' + WORD[k]) + ': ' + SLIPNAME[k]);
}
// a hold runs: the stick held through an orbit's cross-up still counts until he lets go; the brawl cross-up is a rush instead
function holdOn(f) { return !!(f.cmd && (/^(dash|climb|orbit|wall|skim|brawl|sweepL)/.test(f.cmd) || (/^crossed/.test(f.cmd) && f.crossedBy === 'orbit'))); }
function closeDur(f) { var sp = spotAt(f, BR.strike); return closeTicks(dist(f, { x: sp[0], y: sp[1] }) / BH); }
function busy(f) { return f.commit > 0 || holdOn(f) || !!f.seq || !!f.blow || !!f.cross || f.dodgeT > 0 || !!f.bchg || !!(f.beam && !f.beam.end); }
function rushing(f) { return !!(f.mv && /^(lunge|give|close|dodge)$/.test(f.mv.k)); }
// a face press: queued while a stick command commits him or a hold runs, else thrown now
var QN = { X: 'X', BOLT: 'BOLT', LOB: 'Y', CHARGE: 'B', MINE: 'MINE' };
function facePress(w, f, k, inp) {
  if (busy(f) || f.q.length) { if (f.q.length < LAW.qMax) { f.q.push({ k: k, t: w.t, on: !!(w.rd.on || w.rd.dpOn || holdOn(f)), st: f.stickT }); note(w.rd, w.t, QN[k] + ' QUEUED'); } else note(w.rd, w.t, 'QUEUE FULL', true); return; }
  doPress(w, f, k, inp);
}
// the energy presses still need their shoulders when they start; B starts the charge, and a tap that has ended is a blast
// the tick a press's thumb is counted from: its press, raised to the stick's release or act + L when the stick was out then
// (still out: now), or to the stick commitment it was pressed in; a B still held counts from now
function qEff(w, f, e, inp) { var b = e.k === 'CHARGE' && inp.B ? w.t : e.t; return Math.max(b, e.on ? (f.stickT != null && f.stickT >= e.t ? f.stickT + LAW.L : w.t) : (e.st != null ? e.st + LAW.L : -99)); }
function doPress(w, f, k, inp, pt, ent) {
  var did = false;
  if (k === 'X') did = press(w, f);
  else if (k === 'MINE') { if (inp.LB && inp.RB && !f.bchg && !f.beam) { layMine(w, f); did = true; } }
  else if (!inp.RB || f.bchg || f.beam) did = false;
  else if (k === 'BOLT') { f.lastBolt = w.t; fire(w, f, 'bolt'); did = true; }
  else if (k === 'LOB') { fire(w, f, 'lob'); did = true; }
  else if (k === 'CHARGE') { f.bchg = { t: 0, lv: 0, fresh: true }; did = true; }
  // R30 mirrored: the thumb that pressed reaches the stick no sooner than L later. A press queued while the stick was free
  // counts from its press; one made inside a stick commitment or a hold, from that commitment's end
  if (did) { var at = ent ? qEff(w, f, ent, inp) : w.t; f.faceT = Math.max(f.faceT == null ? -99 : f.faceT, at);
    if (f.pend && (pt == null ? w.t : pt) > f.pend.t) { f.pend = null; note(w.rd, w.t, 'FLICK DROPPED', true); } }
  return did;
}
function layMine(w, f) { var hh = hand(f), off = f.layOff || [f.dir * 20, 0]; w.mines.push({ o: f, x: clamp(hh[0] + off[0], 20, AW - 20), y: Math.max(floor(hh[0] + off[0]), hh[1] + off[1]), t: 0 }); f.layOff = null; note(w.rd, w.t, 'X: LAY A SPARK MINE'); }
function press(w, f) {
  if (f.seq || f.blow || f.cross) return false;
  var d = bhOf(f), gap = d - BR.strike, steps = [];
  // the step carries the blow (R31): a press within W of a step in (or a hop or a drop), measured from where the step ends,
  // is the step-strike, the blow at once, the same for every gap from 0 to W (R29); a step away never is
  var si = f.stepIn, end = f.mv && !f.mv.seq ? { x: f.mv.x1, y: f.mv.y1 } : f;
  if (si && w.t <= si.until && dist(end, f.foe) / BH <= BR.strike + BR.reach) { f.stepIn = null; f.blow = { t: 0, ss: true, start: w.t }; note(w.rd, w.t, 'THE STEP-STRIKE'); return true; }
  f.stepIn = null; f.tl.push({ t: w.t, k: 'P' });
  if (w.brawl || d <= BD.close) {
    if (gap > 0.05) steps.push({ k: 'move', kind: 'close', to: function () { return spotAt(f, BR.strike); }, dur: function () { return closeDur(f); } });
    steps.push({ k: 'blow' }); note(w.rd, w.t, 'X: BLOW');
  } else {
    steps.push({ k: 'move', kind: 'lunge', to: function () { return spotAt(f, BD.engage); }, dur: rushTicks(d - BD.engage) }, { k: 'wait', n: BD.pressWind },
      { k: 'move', kind: 'close', to: function () { return spotAt(f, BR.strike); }, dur: function () { return closeDur(f); } }, { k: 'blow' });
    note(w.rd, w.t, 'X: PRESS LUNGE, BLOW');
  }
  plan(f, steps); return true;
}
function blowStep(w, f) {
  var b = f.blow; if (!b) return; b.t++;
  if (b.t === 1) { f.tl.push({ t: w.t, k: 'B' }); if (w.brawl) w.brawl.idle = 0; }
  if (b.t === (b.land || BR.contact)) {
    var foe = f.foe, inReach = bhOf(f) <= BR.strike + BR.reach + (b.heavy ? 0.4 : 0);
    if (!inReach) { /* a whiff: nothing is spent on it */ }
    else if (foe.dodgeT > 0 && !foe.cross) { note(w.rd, w.t, 'HE MISSES: ' + (foe.slipK || 'SLIPPED')); }
    else if (!foe.cross && foe.read && foe.read.k === (b.heavy ? 'heavy' : b.fl ? 'flurry' : '') && b.start >= foe.read.t0) fireRead(w, foe, f, b);
    else {
      foe.reel = b.heavy ? 18 : 10; if (b.heavy) { foe.vx = (foe.x >= f.x ? 1 : -1) * 5; foe.settle = 8; note(w.rd, w.t, 'HIS HEAVY LANDS'); } var c0 = chest(f), c1 = chest(foe), cl = dist({ x: c0[0], y: c0[1] }, { x: c1[0], y: c1[1] }) || 1; burst(w, c1[0] - (c1[0] - c0[0]) / cl * 12, c1[1] - (c1[1] - c0[1]) / cl * 12, 10, 7, SPARK, 5); sound(w, 'blow');
      // the cross-up has no slip and no strike: a blow in the arc lands clean and leaves him where he was hit (row 5)
      if (foe.cross) { foe.commit = Math.max(foe.commit, LAW.L + 1 - foe.cross.t); foe.cross = null; foe.mv = null; foe.seq = null; foe.vx = foe.vy = 0; note(w.rd, w.t, 'HIT IN THE ARC: CLEAN'); }
      startBrawl(w);
    }
  }
  if (b.t >= (b.land || BR.contact) + BR.blowT - BR.contact) { f.blow = null; if (f.seq) nextStep(f); }
}
// the cross-up: a 16-tick rush in an arc over or under him, onto his other side at striking distance (row 5)
function startCross(w, f, up) {
  var foe = f.foe, a0 = Math.atan2(f.y - foe.y, f.x - foe.x), left = f.x < foe.x, a1 = left ? 0 : Math.PI;
  if (up) { if (left && a0 < 0) a0 += 2 * Math.PI; if (!left && a0 < -Math.PI / 2) a0 += 2 * Math.PI; }
  else { if (left && a0 > 0) a0 -= 2 * Math.PI; if (!left && a0 > Math.PI / 2) a0 -= 2 * Math.PI; a1 = left ? 0 : -Math.PI; }
  f.cross = { t: 0, a0: a0, a1: a1, r0: dist(f, foe), r1: BR.strike * BH, side0: f.x - foe.x >= 0 ? 1 : -1 }; f.mv = null; f.seq = null; f.giving = false;
  note(w.rd, w.t, up ? 'HOLD UP: CROSS-UP' : 'HOLD DOWN: CROSS-UNDER');
}
function crossStep(w, f) {
  var c = f.cross, foe = f.foe; c.t++; var k = easeIO(c.t / BR.crossT), a = lerp(c.a0, c.a1, k), r = lerp(c.r0, c.r1, k), ox = f.x, oy = f.y;
  var kp = easeIO((c.t - 1) / BR.crossT), ap = lerp(c.a0, c.a1, kp), rp = lerp(c.r0, c.r1, kp), fx0 = foe.x + Math.cos(ap) * rp, fy0 = Math.max(2, foe.y + Math.sin(ap) * rp);
  f.x = foe.x + Math.cos(a) * r; f.y = Math.max(2, foe.y + Math.sin(a) * r); rock(f, ox, oy, Math.sqrt((f.x - fx0) * (f.x - fx0) + (f.y - fy0) * (f.y - fy0)) + 3); f.vx = f.x - ox; f.vy = f.y - oy;
  if (c.t >= BR.crossT) { f.cross = null; f.vx = f.vy = 0; note(w.rd, w.t, (f.x - foe.x) * c.side0 < 0 ? 'SIDES SWAPPED' : 'THE CLIFF BLOCKS THE ARC'); }
}
function brawlStep(w) {
  var B = w.brawl, P = w.P, V = w.V; if (!B) return;
  B.t++; B.idle++;
  if (B.idle > BR.idle) { endBrawl(w, 'IDLE'); return; }
  if (bhOf(P) > BR.breakBh) { endBrawl(w, 'APART'); return; }
  // the pull: back to striking distance and one height, resting while he gives ground or a rush runs
  if (!P.mv && !P.cross && !P.giving && !P.seq && !P.wait && !P.caught) { var g = spotAt(P, BR.strike), px = BR.pull * BH; var px0 = P.x, py0 = P.y; P.x += clamp(g[0] - P.x, -px, px); P.y += clamp(g[1] - P.y, -px, px); rock(P, px0, py0, 0); bound(P); }
}

// ---- moves: tweens the director runs, then the hold's sustained commands ----
function tween(f, k, x1, y1, dur) { f.mv = { k: k, x0: f.x, y0: f.y, x1: x1, y1: y1, t: 0, dur: dur }; f.settle = 0; if (!/^crossed/.test(f.cmd || '')) f.cmd = null; f.orbit = null; }
function slipFor(w, f, kind) {    // R8: the third step or hop inside 3 s keeps its movement and loses its slip frames
  var r = f.reps[kind] = f.reps[kind].filter(function (t) { return w.t - t < MV.repeatWin; }); r.push(w.t);
  f.slip = r.length >= 3 ? 0 : MV.slip;
}
function rel(f, d4) { if (d4 === 'up' || d4 === 'down') return d4; return (d4 === 'right' ? 1 : -1) === (f.foe.x >= f.x ? 1 : -1) ? 'toward' : 'away'; }
var WORD = { toward: 'TOWARD', away: 'AWAY', up: 'UP', down: 'DOWN' };
function flightFlick(w, f, d4) {
  if (holdOn(f)) breakHold(f); f.stickT = w.t;     // a pad flick that ends a stick hold spends the held stick
  f.commit = LAW.L; f.tl.push({ t: w.t, k: 'F' }); f.stepIn = null;     // R30: a stick command commits him for L ticks
  var r = rel(f, d4), foe = f.foe, d = dist(f, foe), sx = foe.x >= f.x ? 1 : -1, bh = d / BH;
  if (w.brawl && (r === 'toward' || r === 'away')) {
    // inside a brawl a step is a director rush: away gives ground up to the leash in one rush, toward takes it back
    if (r === 'away') { var to = spotAt(f, Math.max(bh, BR.strike + BR.leash)); tween(f, 'give', to[0], to[1], MV.stepT); slipFor(w, f, 'step'); note(w.rd, w.t, 'FLICK AWAY: GIVE GROUND'); }
    else if (bh - BR.strike > 0.05) { var bk = spotAt(f, BR.strike); tween(f, 'close', bk[0], bk[1], closeTicks(dist(f, { x: bk[0], y: bk[1] }) / BH)); f.stepIn = { until: w.t + LAW.W }; note(w.rd, w.t, 'FLICK TOWARD: TAKE BACK'); }
    else note(w.rd, w.t, 'FLICK TOWARD: NONE GIVEN');
    return;
  }
  if (r === 'toward') {
    if (bh > BD.close) {
      // the stick's lunge is the press's rush with no blow at its end: he arrives in reach free and even (row 1)
      if (f.ki < MV.lungeKi) { note(w.rd, w.t, 'FLICK TOWARD: NO KI'); return; }
      f.ki -= MV.lungeKi; var at = spotAt(f, BD.engage); tween(f, 'lunge', at[0], at[1], rushTicks(bh - BD.engage)); f.commit = Math.max(LAW.L, f.mv.dur);
      note(w.rd, w.t, 'FLICK TOWARD: LUNGE'); return;
    }
    var nx = f.x + sx * clamp(Math.abs(foe.x - f.x) - BR.strike * BH, 0, MV.stepIn * BH);     // never past him, never back
    tween(f, 'step', nx, f.y, MV.stepT); f.stepIn = { until: w.t + LAW.W }; note(w.rd, w.t, 'FLICK TOWARD: STEP IN'); return;
  }
  if (r === 'away') { tween(f, 'step', f.x - sx * MV.stepBack * BH, f.y, MV.stepT); slipFor(w, f, 'step'); note(w.rd, w.t, 'FLICK AWAY: STEP BACK'); return; }
  var up = r === 'up'; tween(f, up ? 'hop' : 'drop', f.x, clamp(f.y + (up ? 1 : -1) * MV.hop * BH, overLake(f.x) ? 6 : 0, 250), MV.hopT); slipFor(w, f, 'hop'); f.stepIn = { until: w.t + LAW.W };
  note(w.rd, w.t, up ? 'FLICK UP: HOP' : 'FLICK DOWN: DROP');
}
// holds inside a brawl: away gives ground to the leash and holds it (movement only, never the escape, never parting it);
// toward takes it back; up or down is the cross-up (section 12 rows 4 and 5)
function brawlHold(w, f, r) {
  var key = 'brawl' + r, first = f.cmd !== key && f.cmd !== 'crossed' + r;
  if (r === 'away') {
    if (first) { f.cmd = key; note(w.rd, w.t, 'HOLD AWAY: TO THE LEASH'); }
    f.giving = true; var to = spotAt(f, Math.max(bhOf(f), BR.strike + BR.leash)), px = BR.give * BH, gx0 = f.x, gy0 = f.y; f.x += clamp(to[0] - f.x, -px, px); f.y += clamp(to[1] - f.y, -px, px); rock(f, gx0, gy0, 0);
  } else if (r === 'toward') {
    if (first) { f.cmd = key; f.giving = false; var bh = bhOf(f); if (bh - BR.strike > 0.05) { var bk = spotAt(f, BR.strike); tween(f, 'close', bk[0], bk[1], closeTicks(dist(f, { x: bk[0], y: bk[1] }) / BH)); f.cmd = key; note(w.rd, w.t, 'HOLD TOWARD: TAKE BACK'); } }
  } else if (first && !f.cross) { startCross(w, f, r === 'up'); f.cmd = 'crossed' + r; f.crossedBy = 'rush'; }
}
function atWall(f, d4) { return d4 === 'right' && f.x >= CLIFF.x - 30 && f.y < CLIFF.top; }
function flightHold(w, f, h) {
  var r = rel(f, h.d4), foe = f.foe, d = dist(f, foe), k;
  if (w.brawl) { brawlHold(w, f, r); return; }
  if (atWall(f, h.d4)) k = 'wall';
  else if (f.orbit && !f.orbit.done && f.cmd === 'orbit' + r) k = 'orbit';      // an orbit under way keeps going until it crosses or he lets go
  else if (r === 'down' && (f.flickAlt != null ? f.flickAlt : f.y) < MV.skimAlt * BH + 4) k = 'skim';
  else if (r === 'toward' || r === 'away') k = 'dash';
  else if (d <= BD.mid * BH) k = 'orbit';
  else k = 'climb';
  if (f.cmd !== k + r) {
    if (k === 'orbit' && f.cmd === 'crossed' + r) return;     // held through: the cross-up is done until he lets go
    f.cmd = k + r; f.dashT = 0; f.stepIn = null;
    if (k === 'orbit') { var a0 = Math.atan2(f.y - foe.y, f.x - foe.x), r1 = Math.max(0.9 * BH, Math.min(f.flickDist || d, r === 'down' ? foe.y - floor(foe.x) - 6 : 1e9)); f.orbit = { a: a0, a0: a0, r0: d, r1: r1, dirn: (r === 'up' ? 1 : -1) * (f.x < foe.x ? -1 : 1), done: false }; }
    if (k === 'skim') f.skimDir = f.vx ? (f.vx > 0 ? 1 : -1) : (foe.x >= f.x ? 1 : -1);
    note(w.rd, w.t, k === 'wall' ? 'HOLD INTO WALL: RUN' : k === 'skim' ? 'HOLD DOWN: SKIM' : k === 'dash' ? 'HOLD ' + WORD[r] + ': DASH' : k === 'orbit' ? 'HOLD ' + WORD[r] + ': ORBIT' : 'HOLD ' + WORD[r] + ': FLY');
  }
  var sx = foe.x >= f.x ? 1 : -1;
  if (k === 'dash') {
    f.dashT++; var sp = MV.dash;
    if (f.dashT > MV.dashFree) { if (f.ki > 0) f.ki = Math.max(0, f.ki - MV.dashKi / 60); else sp = MV.flight; }
    var dx = (r === 'toward' ? sx : -sx) * sp; if (r === 'toward' && Math.abs(foe.x - f.x) < 1.0 * BH) dx = 0;
    f.vx = dx; f.vy = 0; f.x += dx; rock(f, f.x - dx, f.y, 0); f.lean = r === 'toward' ? 14 : -10;
  } else if (k === 'climb') { f.vy = (r === 'up' ? 1 : -1) * 4; f.y += f.vy; f.vx = 0; rock(f, f.x, f.y - f.vy, 0); }
  else if (k === 'orbit') {
    var o = f.orbit; if (o.done) return;
    o.a += o.dirn * deg(MV.orbitRate); var sw = Math.abs(angN(o.a - o.a0)), orr = lerp(o.r0, o.r1, Math.min(1, sw / deg(60)));
    var nx = foe.x + Math.cos(o.a) * orr, ny = foe.y + Math.sin(o.a) * orr;
    var ox0 = f.x, oy0 = f.y; f.x = nx; f.y = Math.max(f.y < 2 ? 0 : 2, ny); rock(f, ox0, oy0, deg(MV.orbitRate) * orr + Math.abs(o.r1 - o.r0) / 12 + 3); f.vx = f.x - ox0; f.vy = f.y - oy0;     // the speed it really moved, so a release never flings him
    if ((Math.cos(o.a) * Math.cos(o.a0) < 0 && Math.abs(Math.sin(o.a)) < 0.08) || sw > deg(200)) { o.done = true; f.cmd = 'crossed' + r; f.crossedBy = 'orbit'; f.vx = f.vy = 0; note(w.rd, w.t, r === 'up' ? 'CROSS-UP: OTHER SIDE' : 'CROSS-UNDER: OTHER SIDE'); }
  } else if (k === 'wall') { f.x = CLIFF.x - 14; f.vy = MV.wall; f.y = Math.min(CLIFF.top - 2, f.y + MV.wall); f.vx = 0; f.tilt = Math.PI / 2; if (w.t % 3 === 0) chips(w, CLIFF.x - 2, f.y + 4, 1, C.cliffDark, 1.5); }
  else if (k === 'skim') {
    var sx0 = f.x, sy0 = f.y; f.y = Math.max(floor(f.x) + (overLake(f.x) ? 5 : 4), f.y - 3); f.vx = (w.inp.lx ? (w.inp.lx > 0 ? 1 : -1) : f.skimDir) * MV.skim; f.vy = 0; f.x += f.vx; rock(f, sx0, sy0, 0); f.lean = 16;
    if (w.t % 2 === 0) chips(w, f.x - f.vx * 2, 2, 2, overLake(f.x) ? C.lakeLite : C.dirt, 2.5, true);
  }
}
// RB: the aim line, an angle off the line to him; it latches, and a toward flick (or letting go of RB) clears it
function muzzle(f, a) { return [f.x + (Math.cos(a) >= 0 ? 1 : -1) * 22, f.y + 40]; }
function aimAbs(f) { var h = hand(f), c = chest(f.foe); return Math.atan2(c[1] - h[1], c[0] - h[0]) + f.aimOff; }
function aimFlick(w, f, d4) {
  if (holdOn(f)) breakHold(f); f.stickT = w.t; f.commit = LAW.L; f.tl.push({ t: w.t, k: 'F' });
  var r = rel(f, d4), s = f.foe.x >= f.x ? 1 : -1;
  if (r === 'toward') { f.aimOff = 0; f.latched = false; note(w.rd, w.t, 'FLICK TOWARD: CLEAR'); }
  else if (r === 'away') { f.aimOff = Math.PI; f.latched = true; note(w.rd, w.t, 'FLICK AWAY: BEHIND'); }
  else { f.aimOff = (r === 'up' ? 1 : -1) * s * deg(MV.latch); f.latched = true; note(w.rd, w.t, r === 'up' ? 'FLICK UP: LATCH HIGH' : 'FLICK DOWN: LATCH LOW'); }
}
function aimHold(w, f, h) {
  var want = deg(h.ang);
  if (f.beam && !f.beam.end) { var b = f.beam; b.a += clamp(angN(want - b.a), -deg(f.def.sweep / 60), deg(f.def.sweep / 60)); if (f.cmd !== 'sweepB') { f.cmd = 'sweepB'; note(w.rd, w.t, 'HOLD: SWEEP THE BEAM'); } return; }
  // R26: under a hold the line points where the stick points (32 ways, no turning rate); a beam turns at its fighter's rate
  f.aimOff = angN(want - (aimAbs(f) - f.aimOff)); f.latched = Math.abs(f.aimOff) > 0.02;
  if (f.cmd !== 'sweepL') { f.cmd = 'sweepL'; note(w.rd, w.t, 'HOLD: SWEEP THE LINE'); }
}
var READK = { up: 'heavy', down: 'flurry', toward: 'grab', away: 'shot' }, READWORD = { heavy: 'HIS HEAVY', flurry: 'HIS FLURRY', grab: 'HIS GRAB', shot: 'HIS SHOT' };
function readFlick(w, f, d4) {
  if (f.ki < LAW.readKi) { note(w.rd, w.t, 'NO KI FOR A READ'); return; }
  if (holdOn(f)) breakHold(f); f.stickT = w.t; f.tl.push({ t: w.t, k: 'F' }); var k = READK[rel(f, d4)]; f.ki -= LAW.readKi; f.read = { k: k, t0: w.t, until: w.t + LAW.readT }; f.commit = LAW.L;
  note(w.rd, w.t, 'READ ' + READWORD[k] + ' (3 KI)');
}
function fireRead(w, f, foe, b) {
  var k = f.read.k, sx = foe.x >= f.x ? 1 : -1; f.read = null; f.dodgeT = 10; f.slipD = null;
  breakHold(f); f.pend = null; f.seq = null; f.wait = 0; f.blow = null; f.cmd = null; f.orbit = null; f.mv = null; f.stepIn = null; f.vx = f.vy = 0; f.settle = 0;
  if (k === 'heavy') { f.sway = 'down'; f.slipT = 0; foe.reel = 16; foe.open = 16; note(w.rd, w.t, 'READ: SLIPS HIS HEAVY'); say2(w, 'HE IS OPEN'); }
  else if (k === 'flurry') { f.sway = 'down'; f.slipT = 0; foe.flurry = null; foe.blow = null; foe.reel = 10; note(w.rd, w.t, 'READ: DUCKS HIS FLURRY'); say2(w, 'HIS RUN IS BROKEN'); }
  else if (k === 'grab') { f.vx = -sx * 6; f.settle = 8; foe.vx = sx * 6; foe.settle = 8; foe.grabLock = 90; var cg = chest(f); burst(w, cg[0], cg[1], 14, 8, foe.def.L.trap, 6); note(w.rd, w.t, 'READ: BREAKS HIS GRAB'); say2(w, 'BOTH PUSHED APART'); }
  else { tween(f, 'dodge', f.x, f.y + 0.9 * BH, 8); note(w.rd, w.t, 'READ: SIDESTEPS HIS SHOT'); }
  sound(w, 'read');
}
function say2(w, text) { note(w.rd, w.t, text, true); }
function layFlick(w, f, d4) { if (holdOn(f)) breakHold(f); f.stickT = w.t; f.commit = LAW.L; var v = { right: [1, 0], left: [-1, 0], up: [0, 1], down: [0, -1] }[d4]; f.layOff = [v[0] * MV.layReach * BH, v[1] * MV.layReach * BH]; note(w.rd, w.t, 'LAY 3 BH ' + WORD[rel(f, d4)]); }

// ---- shots ----
function fire(w, f, k) {
  var a = aimAbs(f), h = muzzle(f, a), seek = Math.abs(f.aimOff) <= deg(MV.seek) ? 0.1 : 0, L = f.def.L;
  if (k === 'bolt') { w.shots.push({ k: 'bolt', o: f, x: h[0], y: h[1], vx: Math.cos(a) * 11, vy: Math.sin(a) * 11, sp: 11, seek: seek, t: 0, s: 6 }); note(w.rd, w.t, 'X: BOLT ALONG IT'); }
  else if (k === 'heavy') { w.shots.push({ k: 'heavy', o: f, x: h[0], y: h[1], vx: Math.cos(a) * 9, vy: Math.sin(a) * 9, sp: 9, seek: seek * 0.8, t: 0, s: 14 }); note(w.rd, w.t, 'B: BLAST ALONG IT'); }
  else if (k === 'lob') {
    var d = dist(f, f.foe), tx = h[0] + Math.cos(a) * d, ty = Math.max(floor(tx), h[1] + Math.sin(a) * d), T = N.lobT, g = 0.4;
    w.shots.push({ k: 'lob', o: f, x: h[0], y: h[1], vx: (tx - h[0]) / T, vy: ((ty - h[1]) + 0.5 * g * T * T) / T, g: g, t: 0, s: 9 }); note(w.rd, w.t, 'Y: LOB ALONG IT');
  }
  f.lean = 8; sound(w, 'bolt');
}
function sound(w, k) { w.sound.push(k); }
function inBody(f, x, alt, pad) { return Math.abs(x - f.x) < 12 + pad && alt > f.y - pad && alt < f.y + BH + pad; }
function shotsStep(w) {
  for (var i = w.shots.length - 1; i >= 0; i--) {
    var s = w.shots[i], foe = s.o.foe; s.t++;
    if (s.seek && !foe.slip) { var c = chest(foe), dx = c[0] - s.x, dy = c[1] - s.y, d = Math.sqrt(dx * dx + dy * dy) || 1; s.vx = lerp(s.vx, dx / d * s.sp, s.seek); s.vy = lerp(s.vy, dy / d * s.sp, s.seek); }
    s.x += s.vx; s.y += s.vy; if (s.g) s.vy -= s.g;
    var L = s.o.def.L;
    if (!s.slipped && inBody(foe, s.x, s.y, s.k === 'heavy' ? 8 : 2)) {
      if (!foe.cross && foe.read && foe.read.k === 'shot' && s.born >= foe.read.t0) { fireRead(w, foe, s.o, null); s.slipped = true; continue; }
      if (foe.slip > 0 || foe.dodgeT > 0) { s.slipped = true; note(w.rd, w.t, 'SLIPPED A SHOT', true); }      // the step's slip frames: the shot goes by him
      else { burst(w, s.x, s.y, s.k === 'heavy' ? 30 : 11, s.k === 'heavy' ? 14 : 7, s.k === 'bolt' ? L.bolt : L.lob, 6); foe.reel = s.k === 'bolt' ? 6 : 14; if (s.k !== 'bolt') { foe.vx = (s.vx > 0 ? 1 : -1) * 4; foe.settle = MV.settle; } w.shots.splice(i, 1); continue; }
    }
    var fl = floor(s.x);
    if (s.y <= fl + 1 && (s.k === 'lob' || s.k === 'heavy' || s.vy < 0)) { burst(w, s.x, fl + 2, s.k === 'bolt' ? 9 : 28, s.k === 'bolt' ? 6 : 14, s.k === 'bolt' ? L.bolt : L.lob, 7); if (s.k !== 'bolt') { chips(w, s.x, fl + 2, 6, overLake(s.x) ? C.lakeLite : C.dirt, 3.5, true); if (!overLake(s.x)) w.marks.push({ k: 'crater', x: s.x, w: 30 }); if (Math.abs(foe.x - s.x) < 40 && foe.y < 50) foe.reel = 12; } w.shots.splice(i, 1); continue; }
    if (s.x < -60 || s.x > AW + 40 || s.y > H + 60 || s.t > 200 || (s.x > CLIFF.x && s.y < CLIFF.top)) w.shots.splice(i, 1);
  }
}
// ---- the beam: RB + B held; while it is out he is rooted, and either stick sweeps it (R25) ----
function fireBeam(w, f, lv) { var cost = [12, 20, 32]; while (lv > 0 && f.ki < cost[lv - 1]) lv--; if (!lv) { fire(w, f, 'heavy'); return; }
  f.beam = { lv: lv, a: aimAbs(f), len: 0, t: 0, dur: N.beamLen[lv - 1], end: 0, pulses: [] }; f.ki = Math.max(0, f.ki - cost[lv - 1]); note(w.rd, w.t, 'B HELD: BEAM, LEVEL ' + lv); sound(w, 'beam'); }
function beamStep(w, f, inp, held) {
  var b = f.beam; if (!b) return;
  if (b.end) { b.end++; if (b.end > 9) f.beam = null; return; }
  b.t++;
  // the left stick sweeps it whenever the right is not holding (the right wins if both are out)
  if (!held && inp.ly) { b.a += clamp(-inp.ly, -1, 1) * (Math.cos(b.a) < 0 ? -1 : 1) * deg(f.def.sweep / 60); if (f.cmd !== 'sweepLeft') { f.cmd = 'sweepLeft'; note(w.rd, w.t, 'LEFT STICK: SWEEP'); } }
  for (var k = b.pulses.length - 1; k >= 0; k--) { b.pulses[k] += 18; if (b.pulses[k] > b.len) b.pulses.splice(k, 1); }
  var h = hand(f), dx = Math.cos(b.a), dy = Math.sin(b.a), foe = f.foe, reach = 900;
  var fx = foe.x - h[0], fy = foe.y + 30 - h[1], along = fx * dx + fy * dy, off = Math.abs(fx * dy - fy * dx), half = (12 + 6 * b.lv) * f.def.bw / 2;
  var inLine = along > 0 && off < half + 12;
  for (var s = 0; s < 900; s += 6) { var x = h[0] + dx * s, yy = h[1] + dy * s; if (yy <= floor(x) || x < 0 || x > AW || (x > CLIFF.x - 2 && yy < CLIFF.top)) { reach = Math.min(reach, s); break; } }
  if (inLine) reach = Math.min(reach, along);
  b.len = Math.min(b.len + 40, reach);
  if (inLine && b.len >= along - 1) { if (b.lv === 3) { foe.x += dx * 2.4; foe.y = Math.max(0, foe.y + dy * 2.4); } foe.reel = Math.max(foe.reel, 4); if (w.t % 5 === 0) chips(w, h[0] + dx * b.len, h[1] + dy * b.len, 1, f.def.L.beam.core, 3); }
  var ex = h[0] + dx * b.len, ey = h[1] + dy * b.len;
  if (ey <= floor(ex) + 4 && b.len < 880) { var key = Math.round(ex / 12); if (!overLake(ex) && !w.marks.some(function (m) { return m.k === 'trench' && m.key === key; })) w.marks.push({ k: 'trench', key: key, x: key * 12, d: 3 + 2 * b.lv }); if (w.t % 2 === 0) chips(w, ex, floor(ex) + 2, 1, overLake(ex) ? C.lakeLite : C.dirt, 3, true); }
  if (b.t >= b.dur) { b.end = 1; f.cmd = null; }
}

// ---- the tick ----
function fighterStep(w, f, inp, ev) {
  var p = f.prev, pr = function (k) { return inp[k] && !p[k]; };
  f.slip = Math.max(0, f.slip - 1); f.reel = Math.max(0, f.reel - 1); f.lean *= 0.8;
  if (!f.beam && !f.bchg && !f.cmd) f.ki = Math.min(100, f.ki + 5 / 60);
  if (!f.mv && !f.orbit) f.dir = f.foe.x >= f.x ? 1 : -1;
  if (f.orbit) f.dir = f.foe.x >= f.x ? 1 : -1;
  f.tilt = 0;
  if (f.commit > 0) f.commit--;
  f.dodgeT = Math.max(0, f.dodgeT - 1); f.grabLock = Math.max(0, f.grabLock - 1);
  if (f.sway) { f.slipT++; if (f.slipT >= LAW.slipT + 2) { f.sway = null; f.slipT = 0; } }
  if (f.read && w.t >= f.read.until) { f.read = null; note(w.rd, w.t, 'THE READ LAPSES', true); }
  // a queued press is kept W ticks: older ones are dropped before anything new is queued or started
  if (f.spent && !w.rd.on && !w.rd.dpOn) f.spent = false;
  // the skim reads where he was when the gesture began, not where the drop took him, and the orbit his distance then
  if (ev && ((w.rd.on && w.rd.crossT === w.t) || (w.rd.dpOn && w.rd.dpT === w.t))) { f.flickAlt = f.y - floor(f.x); f.flickDist = dist(f, f.foe); }
  if (f.q.length) { var live = f.q.filter(function (e) { return w.t - e.t <= LAW.W && (e.k === 'X' || (e.k === 'MINE' ? inp.LB && inp.RB : inp.RB)); }); if (live.length < f.q.length) note(w.rd, w.t, 'A QUEUED PRESS LAPSES', true); f.q = live; }
  if (f.caught > 0) { f.caught--; f.prev = { RB: inp.RB, LB: inp.LB, LT: inp.LT, X: inp.X, Y: inp.Y, B: inp.B }; return; }
  var rb = !!inp.RB, lb = !!inp.LB; if (inp.B) f.bLast = w.t;
  if (inp.X && !p.X) f.tl.push({ t: w.t, k: 'X' });
  // LT's tap is the one dodge against blows; the left stick picks how he slips (R34)
  if (inp.LT && !p.LT && !rb && !lb) slipDodge(w, f, inp);
  // section 12 row 1: a press from range wins the tick over a toward flick; any other press waits for the stick's commitment
  var xPress = !rb && !lb && pr('X'), lungeFirst = xPress && !w.brawl && bhOf(f) > BD.close && !busy(f);
  var pressed = lungeFirst && press(w, f); if (pressed) f.faceT = w.t;
  // the right stick's events, in the family locked at the first deflection
  if (ev) {
    var fam = ev.fam, flick = ev.flick, lock = Math.max(f.faceT == null ? -99 : f.faceT, f.bchg && !inp.B && f.bLast != null ? f.bLast : -99, f.q.reduce(function (m, e) { return e.on && !(f.stickT != null && f.stickT >= e.t) ? m : Math.max(m, qEff(w, f, e, inp)); }, -99)) + LAW.L;     // a press made with the stick out locks it once the stick lets go or acts
    // a stick command inside a face press's commitment (from its press, or the stick commitment it was made in, or a held B's
    // last tick; a press still queued counts too) is read as if the thumb had just arrived: a flick at lock + its read (the
    // pad's tap at lock), a hold 10 ticks after lock (13 if the gesture left rest inside it), unless a later press drops the
    // flick; the press's own toward flick is spent in it (section 12)
    if (flick) { f.pend = null; if (!(fam === 'flight' && pressed && rel(f, flick) === 'toward') && w.t < (ev.dpad ? lock : lock + RS.flickSettle)) { f.pend = { flick: flick, fam: fam, dpad: !!ev.dpad, t: w.t }; flick = null; } }
    else if (f.pend && w.t >= (f.pend.dpad ? lock : lock + RS.flickSettle)) { flick = f.pend.flick; fam = f.pend.fam; f.pend = null; }
    var chg = !!(f.bchg && inp.B), holdOk = w.t >= lock + RS.holdTicks + (w.rd.on && !w.rd.isFlick && w.rd.lastRest < lock ? RS.flickRise : 0);
    if (flick) { if (fam === 'flight' && pressed && rel(f, flick) === 'toward') note(w.rd, w.t, 'FLICK SPENT IN PRESS'); else if (fam === 'flight' && (f.seq || f.cross || f.blow || rushing(f) || chg || f.dodgeT > 0)) note(w.rd, w.t, f.seq ? 'PRESS UNDER WAY' : chg ? 'CHARGING: HE HOLDS' : 'MOVE UNDER WAY', true); else if (fam === 'flight' && !f.beam) flightFlick(w, f, flick); else if (fam === 'aim' && chg) note(w.rd, w.t, 'CHARGING: THE LINE HOLDS', true); else if (fam === 'aim' && rb && !(f.beam && !f.beam.end)) aimFlick(w, f, flick); else if (chg) note(w.rd, w.t, 'CHARGING: HE HOLDS', true); else if (fam === 'lay') layFlick(w, f, flick); else if (fam === 'read' && lb) readFlick(w, f, flick); else if (fam === 'none') note(w.rd, w.t, 'NOTHING IN STEP 1'); }
    if (ev.hold && !f.spent && holdOk) { if (fam === 'flight' && !f.mv && !f.beam && !f.seq && !f.cross && !f.blow && !chg && !f.dodgeT) flightHold(w, f, ev.hold); else if (fam === 'aim' && !chg && (rb || (f.beam && !f.beam.end))) aimHold(w, f, ev.hold); }
    // a hold's release locks out L (R30); the brawl cross-up's commitment is its rush, which the arc already holds
    if (ev.release) { f.stickT = w.t; f.tl.push({ t: w.t, k: 'R' }); f.giving = false; f.spent = false; var rushX = /^crossed/.test(f.cmd || '') && f.crossedBy === 'rush'; if ((fam === 'flight' || fam === 'aim') && f.cmd && !rushX && f.cmd !== 'sweepB') f.commit = Math.max(f.commit, LAW.L); if (fam === 'flight' && f.cmd) { note(w.rd, w.t, rushX ? 'RELEASE' : 'RELEASE: SETTLE ' + LAW.L); f.settle = /^crossed/.test(f.cmd) ? 0 : LAW.L; } else if (fam === 'aim' && f.cmd === 'sweepL') note(w.rd, w.t, f.latched ? 'RELEASE: LATCHED' : 'RELEASE: CLEAR'); else if (f.cmd === 'sweepB') note(w.rd, w.t, 'RELEASE: BEAM STAYS'); f.cmd = null; f.orbit = null; }
    if (!ev.hold && f.cmd && f.cmd !== 'sweepLeft' && !ev.release) { breakHold(f); f.cmd = null; f.orbit = null; f.giving = false; }
  }
  if (!rb && f.latched) { f.aimOff = 0; f.latched = false; if (p.RB) note(w.rd, w.t, 'RB LET GO: CLEARED'); }   // R16, R23: the line, not the gesture
  if (xPress && !lungeFirst) facePress(w, f, 'X', inp);
  // the queue's head starts when nothing holds him; a bolt still keeps its gap after the one before
  if (f.q.length && !busy(f) && !(f.q[0].k === 'BOLT' && w.t - f.lastBolt < N.boltGap)) { var qq = f.q.shift(); if (doPress(w, f, qq.k, inp, qq.t, qq)) note(w.rd, w.t, 'QUEUED ' + QN[qq.k] + ' STARTS'); else note(w.rd, w.t, 'QUEUED ' + QN[qq.k] + ' DROPPED', true); }
  // tweens: the lunge, the steps, the hop and the drop
  if (f.sway === 'up') { var sk = Math.sin(Math.PI * Math.min(1, f.slipT / LAW.slipT)); f.swayY = sk * 0.9 * BH; } else f.swayY = 0;
  if (f.cross) crossStep(w, f);
  else if (f.wait > 0) { if (--f.wait === 0) nextStep(f); }
  else if (f.mv) { var m = f.mv; m.t++; var k = m.k === 'close' ? clamp(m.t / m.dur, 0, 1) : easeIO(m.t / m.dur), ox = f.x, oy = f.y; var kq = m.k === 'close' ? clamp((m.t - 1) / m.dur, 0, 1) : easeIO((m.t - 1) / m.dur); f.x = lerp(m.x0, m.x1, k); f.y = lerp(m.y0, m.y1, k); rock(f, ox, oy, Math.sqrt((m.x1 - m.x0) * (m.x1 - m.x0) + (m.y1 - m.y0) * (m.y1 - m.y0)) * Math.abs(k - kq) + 3); f.vx = f.x - ox; f.vy = f.y - oy; f.lean = m.k === 'lunge' || m.k === 'close' ? 18 : m.k === 'step' || m.k === 'give' ? (m.x1 - m.x0) * f.dir > 0 ? 10 : -10 : 0; if (m.t >= m.dur) { f.mv = null; f.vx = f.vy = 0; f.settle = 0; if (m.seq) nextStep(f); } }     // a rush ends where it ends: no drift after it
  else if (!f.cmd || f.cmd === 'sweepL' || f.cmd === 'sweepB' || f.cmd === 'sweepLeft') {
    // free flight on the left stick (rooted while his beam is out), or the settle after a command
    if (!f.beam && !f.dodgeT && (inp.lx || inp.ly)) { var fs = MV.flight * (w.brawl ? BR.nudge : 1); f.vx = (inp.lx || 0) * fs; f.vy = -(inp.ly || 0) * fs; f.x += f.vx; f.y += f.vy; rock(f, f.x - f.vx, f.y - f.vy, 0); }
    else if (f.settle > 0) { f.settle--; f.vx *= 0.75; f.vy *= 0.75; f.x += f.vx; f.y += f.vy; rock(f, f.x - f.vx, f.y - f.vy, 0); }
    else { f.vx = 0; f.vy = 0; }
  }
  // energy on RB: X, Y and B along the aim line; under LB + RB, X lays a spark mine where the flick set it
  if (rb && lb) { if (pr('X') && !f.bchg && !f.beam) facePress(w, f, 'MINE', inp); }
  else if (rb) {
    if (pr('X') && (busy(f) || w.t - f.lastBolt >= N.boltGap) && !f.bchg && !f.beam) facePress(w, f, 'BOLT', inp);
    if (pr('Y') && !f.bchg && !f.beam) facePress(w, f, 'LOB', inp);
    if (f.beam && !f.beam.end && pr('B')) { f.beam.dur += N.pulseAdd; f.beam.pulses.push(0); note(w.rd, w.t, 'B: PULSE'); }
    else if (pr('B') && !f.beam && !f.bchg) facePress(w, f, 'CHARGE', inp);
  }
  if (f.layOff && (!rb || !lb)) f.layOff = null;     // the lay lasts until the lay, or a shoulder is let go
  if (f.bchg) { var c = f.bchg; c.t++; var lv = c.t >= N.beamLv[2] ? 3 : c.t >= N.beamLv[1] ? 2 : c.t >= N.beamLv[0] ? 1 : 0; if (lv !== c.lv) { c.lv = lv; sound(w, 'click'); }
    if (c.fresh) c.fresh = false; else if (!inp.B || !rb) { if (c.lv === 0) fire(w, f, 'heavy'); else fireBeam(w, f, c.lv); f.bchg = null; f.faceT = Math.max(f.faceT == null ? -99 : f.faceT, inp.B ? w.t : f.bLast); } }
  beamStep(w, f, inp, ev && ev.hold && ev.fam === 'aim');
  blowStep(w, f);
  bound(f);
  f.prev = { RB: inp.RB, LB: inp.LB, LT: inp.LT, X: inp.X, Y: inp.Y, B: inp.B };
}
// the Rival stand-in: flies to scripted spots, fires a bolt at you on cue; in Play it drifts and fires now and then
function rivalStep(w, f, o) {
  f.dir = f.foe.x >= f.x ? 1 : -1; f.grabLock = Math.max(0, f.grabLock - 1);
  if (w.mode === 'play') { var ph = w.t % 240; if (ph === 30) o.blow = 'mid'; else if (ph === 90) o.heavy = true; else if (ph === 150) o.flurry = true; else if (ph === 200) o.grab = true; else if (ph === 230 && w.t % 480 > 240) o.fire = true; }
  if (o.blow && !f.blow && !f.reel) f.blow = { t: 0, h: o.blow === true ? 'mid' : o.blow, start: w.t };
  if (o.heavy && !f.blow && !f.reel) { f.blow = { t: 0, heavy: true, land: 28, start: w.t, h: 'mid' }; note(w.rd, w.t, 'HE WINDS A HEAVY', true); }
  if (o.flurry && !f.flurry && !f.reel) { f.flurry = { n: 0, next: w.t, start: w.t }; }
  if (f.flurry && w.t >= f.flurry.next && !f.blow) { f.blow = { t: 0, fl: true, start: f.flurry.start, h: 'mid' }; f.flurry.n++; f.flurry.next = w.t + 8; if (f.flurry.n >= 4) f.flurry = null; }
  if (o.grab && !f.grabLock && !w.grabs.length) { var hg = hand(f); w.grabs.push({ o: f, x: hg[0], y: hg[1], t: 0, T: 24, born: w.t }); f.grabLock = 90; note(w.rd, w.t, 'HE THROWS A GRAB', true); }
  blowStep(w, f); f.reel = Math.max(0, f.reel - 1); f.slip = 0;
  if (f.settle > 0) { f.settle--; f.x += f.vx; f.vx *= 0.8; }
  if (o.gx != null || o.gy != null) { var gx = o.gx == null ? f.x : o.gx, gy = o.gy == null ? f.y : o.gy, dx = gx - f.x, dy = gy - f.y, l = Math.sqrt(dx * dx + dy * dy), sp = o.gs || 2.5; if (l > 1) { f.x += dx / l * Math.min(sp, l); f.y += dy / l * Math.min(sp, l); } }
  else if (w.mode === 'play' && !w.brawl) { var hx = f.home[0] + Math.sin(w.t * 0.011) * 60 - f.x, hy = f.home[1] + Math.sin(w.t * 0.017) * 40 - f.y; f.x += clamp(hx, -1.2, 1.2); f.y += clamp(hy, -1.2, 1.2); if (w.t % 200 === 120) o.fire = true; }
  if (o.fire) { var h = hand(f), c = chest(f.foe), a = Math.atan2(c[1] - h[1], c[0] - h[0]), sp2 = o.fireSp || 7; w.shots.push({ k: 'bolt', o: f, x: h[0], y: h[1], vx: Math.cos(a) * sp2, vy: Math.sin(a) * sp2, sp: sp2, seek: 0, t: 0, s: 6, born: w.t }); }
  bound(f);
}
// his energy grab: a loop that closes on you in 24 ticks; a read of his grab breaks it as it closes
function grabsStep(w) {
  for (var i = w.grabs.length - 1; i >= 0; i--) {
    var g = w.grabs[i], f = g.o, foe = f.foe, c = chest(foe); g.t++;
    var k = g.t / g.T; g.x = lerp(g.x, c[0], Math.min(1, 1 / Math.max(1, g.T - g.t + 1))); g.y = lerp(g.y, c[1], Math.min(1, 1 / Math.max(1, g.T - g.t + 1)));
    if (g.t >= g.T) {
      w.grabs.splice(i, 1);
      if (!foe.cross && foe.read && foe.read.k === 'grab' && g.born >= foe.read.t0) fireRead(w, foe, f, null);
      else if (foe.dodgeT > 0 && !foe.cross) note(w.rd, w.t, 'GRAB MISSES: ' + (foe.slipK || 'SLIPPED'));
      else { caughtNow(foe); foe.caught = 40; burst(w, c[0], c[1], 14, 8, f.def.L.trap, 6); note(w.rd, w.t, 'CAUGHT IN HIS GRAB'); }
    }
  }
}
function minesStep(w) { for (var i = w.mines.length - 1; i >= 0; i--) { var m = w.mines[i]; m.t++; if (m.t > 600) { w.mines.splice(i, 1); continue; } if (m.t > 12) { var f = m.o.foe; if (Math.abs(f.x - m.x) < 40 && Math.abs(f.y + 30 - m.y) < 60) { burst(w, m.x, m.y + 6, 20, 10, m.o.def.L.bolt, 7); f.reel = 6; w.mines.splice(i, 1); } } } }
function fxStep(w) { for (var i = w.fx.length - 1; i >= 0; i--) { var e = w.fx[i]; e.t++; if (e.k === 'chip') { e.x += e.vx; e.y += e.vy; e.vy -= 0.3; if (e.y < 0) { e.y = 0; e.vy *= -0.3; e.vx *= 0.6; } e.rot += 0.2; } if (e.t >= e.dur) w.fx.splice(i, 1); } }

// ---- clips: the GIFs for homework 49, each a list of takes ----
// P's script gives the right stick as [from, to, screen degrees, magnitude] gestures (ramped in and out over 2 ticks, with a
// little hash jitter), plus held buttons and the left stick; V's gives a spot to fly to and when to fire.
function stickAt(list, t, seed) {
  for (var i = 0; i < list.length; i++) {
    var e = list[i]; if (t < e[0] || t >= e[1] + 2) continue;
    var kin = Math.min(1, (t - e[0] + 1) / 2), kout = t >= e[1] ? Math.max(0, 1 - (t - e[1] + 1) / 2) : 1, m = (e[3] || 1) * Math.min(kin, kout);
    var a = e[2], span = e[4] || 0; if (span) a += span * clamp((t - e[0]) / Math.max(1, e[1] - e[0]), 0, 1);
    a = deg(a + (hash(t * 31 + seed) - 0.5) * 6); m = Math.min(1, m * (0.97 + hash(t * 17 + seed) * 0.06));
    return [Math.cos(a) * m, -Math.sin(a) * m];
  }
  return [0, 0];
}
function ev(list, side, t) { var o = {}; for (var i = 0; i < list.length; i++) { var e = list[i]; if (e[0] === side && t >= e[2] && t < e[3]) o[e[1]] = e.length > 4 ? e[4] : true; } return o; }
function taps(side, b, at) { return at.map(function (t) { return [side, b, t, t + 3]; }); }
function cat() { var o = []; for (var i = 0; i < arguments.length; i++) o = o.concat(arguments[i]); return o; }
// a split take: two lanes on one clock, each with its own setup, stick and buttons
function takeSplit(len, setup, stickA, buttonsA, stickB, buttonsB, setupB) {
  return { len: len, setup: setup, setup2: setupB, split: true,
    input: function (w) { var b = ev(buttonsA, 'P', w.t), s2 = stickAt(stickA, w.t, 7); b.rx = s2[0]; b.ry = s2[1]; return { P: b, V: ev(buttonsA, 'V', w.t) }; },
    input2: function (w) { var b = ev(buttonsB, 'P', w.t), s2 = stickAt(stickB, w.t, 11); b.rx = s2[0]; b.ry = s2[1]; return { P: b, V: ev(buttonsB, 'V', w.t) }; } };
}
function take(len, setup, stick, buttons) { return { len: len, setup: setup, input: function (w) { var b = ev(buttons, 'P', w.t), s = stickAt(stick, w.t, 7); b.rx = s[0]; b.ry = s[1]; return { P: b, V: ev(buttons, 'V', w.t) }; } }; }
var CLIPS = [
  { n: 'R1', name: 'The lunge and the steps', takes: [take(300, function (w) { w.P.x = 110; w.P.y = 70; w.V.x = 560; w.V.y = 70; },
      [[20, 24, 0], [84, 88, 0], [126, 130, 180], [190, 194, 90], [236, 240, 270]],
      cat([['V', 'gx', 96, 116, 620], ['V', 'gs', 96, 116, 3], ['V', 'fire', 127, 128], ['V', 'fireSp', 118, 140, 45], ['V', 'fireSp', 180, 200, 6], ['V', 'fire', 186, 187]]))],
    steps: [[0, 'Nothing held, so the right stick is Flight. A flick toward the rival from range is the lunge: the press\'s rush with no blow at its end. He arrives in reach for 10 ki, free and even.', 40],
      [78, 'In reach, a flick toward him is a step in, 1 bh, and free.', 94],
      [120, 'A flick away is a step back, 2 bh in 6 ticks. For its first 4 ticks shots slip past him, and the rival\'s bolt goes by.', 131],
      [184, 'A flick up hops him 2 bh, and a flick down drops him back. Each slips shots for its first 4 ticks.', 206]] },
  { n: 'R2', name: 'The dash, the orbit and the cross-up', takes: [take(360, function (w) { w.P.x = 330; w.P.y = 130; w.V.x = 470; w.V.y = 130; },
      [[20, 56, 180], [86, 112, 0], [150, 210, 90], [262, 330, 270]], [])],
    steps: [[0, 'A hold away is the dash: the step back, continued while he holds. It is free for 12 ticks, then costs ki like the boost.', 46],
      [80, 'A hold toward from range starts as its flick, the lunge, which brings him back to reach.', 104],
      [144, 'In reach, a hold up is the orbit: he arcs over the rival at the same distance, facing him.', 178],
      [196, 'Held through, the orbit is the cross-up, and he lands on the rival\'s other side.', 214],
      [256, 'A hold down orbits him under the rival and back.', 300]] },
  { n: 'R3', name: 'The wall run and the skim', takes: [take(300, function (w) { w.P.x = 590; w.P.y = 30; w.V.x = 300; w.V.y = 130; },
      [[20, 78, 0], [168, 250, 270]],
      [['P', 'lx', 96, 160, -0.6], ['P', 'ly', 96, 160, 1], ['P', 'lx', 168, 214, -1], ['P', 'lx', 214, 250, 1]])],
    steps: [[0, 'Next to the cliff, a hold into its face is the wall run: he runs up it.', 52],
      [80, 'Let go, and he settles. The left stick flies him as it always does.', 120],
      [162, 'Near the ground or the water, a hold down is the skim: he skims along the surface, and the left stick steers it.', 214]] },
  { n: 'R4', name: 'The aim line, latched: X, Y and B along it', takes: [take(440, function (w) { w.P.x = 230; w.P.y = 60; w.V.x = 430; w.V.y = 80; },
      [[56, 60, 90], [140, 144, 270], [210, 214, 180], [262, 266, 0], [318, 372, 60, 1, -90]],
      cat([['P', 'RB', 0, 440]], taps('P', 'X', [20, 72, 80]),
        taps('P', 'Y', [152]), taps('P', 'X', [224]), taps('P', 'B', [274]), taps('P', 'X', [384, 392])))],
    steps: [[0, 'Holding RB makes the right stick aim. With the line clear, X fires a bolt that seeks the rival.', 30],
      [50, 'A flick up latches the line 45 degrees above him, a lead for a rival who climbs. Outside 30 degrees shots don\'t seek, so the bolts fly straight along it.', 90],
      [134, 'A flick down latches it 45 degrees below: Y lobs onto the ground under him.', 186],
      [204, 'A flick away latches it behind him, and X fires that way.', 232],
      [256, 'A flick toward clears it: B fires the heavy blast straight at him.', 286],
      [312, 'A hold sweeps the line round, and it stays latched where the stick lets go.', 396]] },
  { n: 'R5', name: 'The beam sweep', takes: [
      take(210, function (w) { w.P.x = 180; w.P.y = 60; w.V.x = 500; w.V.y = 90; }, [[112, 146, 90]],
        cat([['P', 'RB', 0, 210], ['P', 'B', 18, 104]], [['V', 'gy', 100, 130, 170], ['V', 'gs', 100, 130, 4]])),
      take(190, function (w) { w.P.x = 180; w.P.y = 90; w.V.x = 500; w.V.y = 110; }, [],
        cat([['P', 'RB', 0, 190], ['P', 'B', 18, 74]], [['V', 'gy', 70, 140, 20], ['V', 'gs', 70, 140, 1.6]], [['P', 'ly', 82, 126, 1]], taps('P', 'B', [86, 94, 102, 110, 118])))],
    steps: [[0, 'RB and B held: a beam. While it is out he is rooted, and holding the right stick sweeps it, at his own rate.', 112],
      [118, 'The rival climbs out of it, and holding the stick up sweeps the beam after him. Let go, and it stays where the stick left it.', 142],
      [210, 'Either stick sweeps a beam. Here the left stick sweeps it down, so the right thumb is free to press B and pulse it.', 320]] },
  { n: 'R6', name: 'Patterns, coming later', takes: [take(230, function (w) { w.P.x = 200; w.P.y = 100; w.V.x = 560; w.V.y = 110; },
      [[30, 38, 90], [40, 48, 270], [50, 58, 90], [120, 128, 90], [130, 138, 270], [140, 148, 90]],
      cat([['P', 'RB', 100, 200]], taps('P', 'X', [164])))],
    steps: [[0, 'Patterns come in step 2, so for now the panel only names them. With nothing held, a zig-zag is just its flicks: a hop, a drop and a hop. In step 2 it will be the weave.', 56],
      [96, 'With RB held the stick aims, and patterns are off wherever it aims: the same zig-zag only latches the line up, down and up again, and X fires along it.', 166]] }];

CLIPS.push({ n: 'R7', name: 'Inside a brawl', takes: [take(440, function (w) { w.P.x = 150; w.P.y = 140; w.V.x = 520; w.V.y = 140; },
    [[18, 22, 0], [70, 74, 180], [110, 114, 0], [150, 214, 180], [262, 300, 90], [330, 372, 270]],
    cat(taps('P', 'X', [21, 236]), [50, 90, 130, 170, 210, 250, 296, 348, 386].map(function (t) { return ['V', 'blow', t, t + 1]; })))],
  steps: [[0, 'A press of X from the mid band lunges in with its blow, and the brawl starts. A stick flick toward in the same tick is spent into the press at no ki: the press wins.', 34],
    [60, 'Inside a brawl, a flick away gives ground in one rush, up to the leash, and a flick toward takes it back at once. Its slip is for shots only: never a dodge.', 82],
    [140, 'A hold away gives ground to the leash and holds it there while held. It is movement only, never the escape, and the brawl never parts.', 196],
    [230, 'A hold up is the cross-up: 16 ticks over him, onto his other side, and the brawl goes on with the sides swapped.', 284],
    [320, 'He can\'t strike or slip in the arc: a blow that lands on him there lands clean and leaves him where he was hit.', 352]] });
// S1: a claw press and a one-thumb press start the same blow on the same tick (R30, R31); half speed
CLIPS.push({ n: 'S1', name: 'The step-strike queue', takes: [
  Object.assign(takeSplit(150, function (w) { w.P.x = 500; w.P.y = 0; w.V.x = 620; w.V.y = 0; },
    [[70, 74, 0]], cat(taps('P', 'X', [73])), [[70, 74, 0]], cat(taps('P', 'X', [79]))), { labels: ['CLAW: X ON THE FLICK\'S OWN TICK', 'ONE THUMB: X 6 TICKS LATER'], tl0: 70, slow: 2 }),
  Object.assign(takeSplit(190, function (w) { w.P.x = 560; w.P.y = 60; w.V.x = 640; w.V.y = 60; },
    [[60, 90, 180]], cat(taps('P', 'X', [76])), [[60, 90, 180]], cat(taps('P', 'X', [96]))), { labels: ['X DURING THE DASH AWAY', 'X 6 TICKS AFTER LETTING GO'], tl0: 76, key: 'P', slow: 2 })],
  steps: [[0, 'A flick toward him in reach is a step in, and it commits him for 6 ticks. Left, a claw presses X on the flick\'s own tick: the press waits, and his arm draws back as he steps. Right, one thumb presses 6 ticks later.', 76],
    [79, 'Both blows start on the same tick: the claw gains nothing. The early press was staged with the step as one move, the step-strike, so the wait reads as intent, not lag.', 82],
    [150, 'A press made during a hold (here the dash away) waits for the release plus 6 ticks. A thumb that lets go and presses 6 ticks later starts the same press on the same tick.', 250]] });
// S2: LT's dodge picks its slip from the left stick (R34)
function slipTake(h, ly, lx) { return take(110, function (w) { w.P.x = 545; w.P.y = 0; w.V.x = 585; w.V.y = 0; }, [], cat([['V', 'blow', 60, 61, h]], [['P', 'LT', 58, 61], ['P', ly ? 'ly' : 'lx', 58, 61, ly || lx]])); }
CLIPS.push({ n: 'S2', name: 'The four left-hand slips', takes: [slipTake('mid', 0, -1), slipTake('mid', 0, 1), slipTake('low', -1), slipTake('high', 1)],
  steps: [[0, 'Quick defence is on the left hand: LT is the one dodge against blows, and the left stick picks the slip. Away: a slip back off the line.', 62],
    [110, 'Toward: a slip in, past his fist and inside his arm, where a counter is ready.', 172],
    [220, 'Up: a sway up, over a low blow.', 283],
    [330, 'Down: a duck under a high blow. No right-stick input is ever part of a reactive defence.', 392]] });
// S3: LB with a flick sets a read for 90 ticks at 3 ki; it fires on his next attack of that kind (R36, R37)
function readTake(len, px, vx, ang, his) { return take(len, function (w) { w.P.x = px; w.P.y = 0; w.V.x = vx; w.V.y = 0; }, [[30, 34, ang]], cat([['P', 'LB', 28, 36]], [['V', his, 50, 51]])); }
CLIPS.push({ n: 'S3', name: 'The four reads', takes: [readTake(130, 545, 585, 90, 'heavy'), readTake(110, 545, 585, 270, 'flurry'), readTake(110, 500, 600, 0, 'grab'), readTake(140, 180, 600, 180, 'fire'), readTake(130, 545, 585, 270, 'heavy')],
  steps: [[0, 'With LB held, a flick sets a read: a guess at his next move, for 90 ticks and 3 ki. Up reads his heavy, and his stance shifts: hands high. He winds a heavy, and the read ducks under it: he is open.', 82],
    [130, 'Down reads his flurry, crouched low: the first blow is ducked, and his run is broken.', 182],
    [240, 'Toward reads his grab, hands wide: the loop breaks as it closes, and both are pushed apart.', 316],
    [350, 'Away reads his shot, turned side-on: a sidestep, with slip frames for that shot.', 465],
    [490, 'A wrong guess: he read a flurry, and the heavy lands. The read costs its 3 ki and nothing more.', 572]] });
// S4: the D-pad mirrors every row, at the same cost and never slower (R32); half speed
CLIPS.push({ n: 'S4', name: 'The D-pad mirror', takes: [
  Object.assign(takeSplit(120, function (w) { w.P.x = 120; w.P.y = 40; w.V.x = 560; w.V.y = 40; },
    [[50, 54, 0]], [], [], [['P', 'dr', 50, 54]]), { labels: ['THE RIGHT STICK: FLICK TOWARD', 'THE D-PAD: TAP TOWARD'], tl0: 50, key: 'F', slow: 2, cam: 340 }),
  Object.assign(takeSplit(140, function (w) { w.P.x = 545; w.P.y = 0; w.V.x = 585; w.V.y = 0; },
    [[40, 44, 90]], cat([['P', 'LB', 38, 46]], [['V', 'heavy', 60, 61]]), [], cat([['P', 'LB', 38, 46], ['P', 'du', 40, 44]], [['V', 'heavy', 60, 61]])), { labels: ['LB AND THE STICK UP: A READ', 'LB AND THE D-PAD UP: THE SAME READ'], tl0: 40, key: 'F', slow: 2 }),
  Object.assign(takeSplit(130, function (w) { w.P.x = 300; w.P.y = 60; w.V.x = 470; w.V.y = 60; },
    [[50, 100, 180]], [], [], [['P', 'dl', 50, 100]]), { labels: ['THE STICK HELD AWAY: THE DASH', 'THE D-PAD HELD AWAY: THE DASH'], tl0: 50, key: 'F', slow: 2, cam: 253 })],
  steps: [[0, 'Every right-stick command has a D-pad form for the left thumb, at the same ki and commitment. A tap reads on the tick it is pressed; the stick\'s flick reads 2 ticks after it crosses, so the stick is never the faster form.', 58],
    [120, 'The read the same way: LB and the D-pad up sets it, and it fires on his heavy just the same.', 210],
    [260, 'A D-pad hold is the stick\'s hold: the dash, while held, and the same settle on letting go.', 340]] });
function clipLen(c) { return c.takes.reduce(function (a, t) { return a + t.len; }, 0); }
function newRun(ci, mode) {
  if (mode === 'play') return { clip: null, w: newWorld(null, 0, 'play'), t: 0, take: 0, off: 0 };
  var c = CLIPS[ci], T0 = c.takes[0]; return { clip: c, w: newWorld(c, 0, 'demo'), w2: T0.split ? newWorld(c, 0, 'demo', true) : null, t: 0, take: 0, off: 0 };
}
// keys (Play): { rx, ry, lx, ly, RB, LB, X, Y, B } from the pad or the keyboard
function stepRun(run, keys) {
  var c = run.clip, w = run.w, ip;
  if (c) {
    var T = c.takes[run.take];
    if (w.t >= T.len) { run.off += T.len; run.take++; if (run.take >= c.takes.length) { run.take = 0; run.off = 0; } run.w = w = newWorld(c, run.take, 'demo'); T = c.takes[run.take]; run.w2 = T.split ? newWorld(c, run.take, 'demo', true) : null; }
    ip = T.input(w);
    if (run.w2) stepWorld(run.w2, T.input2(run.w2));
  } else ip = { P: keys || {}, V: {} };
  stepWorld(w, ip);
  run.t = run.off + w.t;
}
function stepWorld(w, ip) {
  var P = ip.P; w.inp = P; w.sound.length = 0;
  var mask = (P.LB ? 1 : 0) + (P.RB ? 2 : 0) + (P.RT ? 4 : 0) + (P.LT ? 8 : 0);
  // the D-pad (R32): the mirror of the right stick on the left thumb
  var dp = { x: (P.dr ? 1 : 0) - (P.dl ? 1 : 0), y: (P.dd ? 1 : 0) - (P.du ? 1 : 0) };
  var mag = Math.sqrt((P.rx || 0) * (P.rx || 0) + (P.ry || 0) * (P.ry || 0)), inNow = mag > RS.deadZone || dp.x || dp.y;
  if (inNow && !w.inWas) w.P.tl.push({ t: w.t, k: 'I' }); w.inWas = inNow;
  var e = readStick(w.rd, w.t, P.rx || 0, P.ry || 0, mask, dp);
  fighterStep(w, w.P, P, e); rivalStep(w, w.V, ip.V); brawlStep(w);
  [w.P, w.V].forEach(function (f) { if (f.tl.length > 64) f.tl.splice(0, f.tl.length - 64); }); if (w.marks.length > 80) w.marks.splice(0, w.marks.length - 80);
  shotsStep(w); grabsStep(w); minesStep(w); fxStep(w);
  w.t++;
}
function stepOf(c, t) { var k = 0; for (var i = 0; i < c.steps.length; i++) if (t >= c.steps[i][0]) k = i; return k; }

// ---- drawing ----
function drawFighter(R, w, f) {
  var run = f.cmd && f.cmd.indexOf('wall') === 0, d = run ? 1 : f.dir, col = f.def.body, base = sy(f.y + (f.swayY || 0)), cx = f.x, lean = f.lean + (f.reel > 0 ? -10 : 0), tilt = f.tilt;
  var fl = floor(f.x), sh = Math.max(0.2, 1 - (f.y - fl) / 220);
  R.poly(ngon(f.x, sy(fl) + 3, 15 * sh, 8, 0).map(function (v, i) { return i % 2 ? sy(fl) + 3 + (v - sy(fl) - 3) * 0.2 : v; }), C.shade);
  // a body in his own frame (y up from the feet), turned by tilt for the wall run
  var air = f.y - fl > 4;
  var pts = { fa: air ? [d * 6, 2] : [d * 9, 0], fb: air ? [-d * 5, 4] : [-d * 7, 0], hip: [0, 22], ch: [d * lean * 0.6, 42], hd: [d * lean * 0.7, 51],
    h1: [d * 16, 40], h2: [d * 9, 32] };
  if (run) { pts.fa = [d * 10, 6]; pts.fb = [-d * 8, -2]; }
  if (f.mv && (f.mv.k === 'hop' || f.mv.k === 'drop')) { pts.fa = [d * 6, 8]; pts.fb = [-d * 4, 10]; }
  if (f.beam || f.bchg) { pts.h1 = [d * 22, 40]; pts.h2 = [-d * 6, 30]; }
  if (f.blow && f.blow.h !== 'low') { var bq = Math.sin(Math.PI * Math.min(1, f.blow.t / 6)); pts.h1 = [d * (16 + 16 * bq), 44]; }
  else if (!f.blow && f.foe.dodgeT > 0 && f.foe.slipD === 'toward') pts.h1 = [d * 14, 52];
  else if (!f.blow && dist(f, f.foe) < 37 && !f.foe.blow) { pts.h1 = [d * 9, 47]; pts.h2 = [d * 5, 40]; }
  else if (!f.blow && f.mv && !f.mv.seq && /^(step|hop|drop|close)$/.test(f.mv.k) && f.q.length && f.q[0].k === 'X') { var wq = clamp(f.mv.t / f.mv.dur, 0, 1); pts.h1 = [d * (16 - 26 * wq), 44 + 2 * wq]; pts.ch = [pts.ch[0] - d * 3 * wq, 42]; }
  if (f.cross) { pts.fa = [d * 6, 10]; pts.fb = [-d * 4, 14]; }
  // the read shows in his stance (R37): hands high for a heavy, low for a flurry, wide for a grab, side-on for a shot
  if (f.read) { var rk = f.read.k; if (rk === 'heavy') { pts.h1 = [d * 9, 52]; pts.h2 = [d * 5, 48]; } else if (rk === 'flurry') { pts.hip = [0, 18]; pts.ch = [pts.ch[0], 37]; pts.hd = [pts.hd[0], 46]; pts.h1 = [d * 12, 26]; pts.h2 = [d * 8, 22]; } else if (rk === 'grab') { pts.h1 = [d * 22, 38]; pts.h2 = [d * 20, 30]; } else { pts.h1 = [d * 4, 40]; pts.h2 = [-d * 8, 34]; pts.ch = [pts.ch[0] - d * 4, 42]; } }
  // the duck: folded under the blow
  if (f.sway === 'down') { pts.hip = [0, 13]; pts.ch = [d * 6, 28]; pts.hd = [d * 9, 35]; pts.h1 = [d * 12, 26]; pts.h2 = [d * 8, 22]; pts.fa = [d * 11, 0]; pts.fb = [-d * 10, 0]; }
  if (f.sway === 'up') { pts.fa = [d * 6, 10]; pts.fb = [-d * 4, 12]; }
  if (f.mv && f.mv.k === 'dodge' && f.slipD === 'toward') { pts.hip = [0, 14]; pts.ch = [d * 9, 28]; pts.hd = [d * 10, 35]; pts.h1 = [d * 14, 26]; pts.h2 = [d * 9, 22]; }
  // caught: braced against the loop, arms pinned
  if (f.caught > 0) { pts.h1 = [d * 5, 34]; pts.h2 = [-d * 5, 34]; pts.ch = [pts.ch[0] - d * 3, 42]; }
  // his heavy's wind-up: the arm drawn back, a lean back
  if (f.blow && f.blow.heavy && f.blow.t < f.blow.land - 2) { pts.h1 = [-d * 14, 44]; pts.ch = [pts.ch[0] - d * 5, 42]; pts.hd = [pts.hd[0] - d * 6, 51]; }
  if (f.blow && f.blow.h === 'low') { var lq = Math.sin(Math.PI * Math.min(1, f.blow.t / 6)); pts.fa = [d * (9 + 20 * lq), 6]; }
  if (run) cx += 12;     // feet on the cliff's face
  var tx = function (p) { var c = Math.cos(tilt), s = Math.sin(tilt), x = p[0] * c - p[1] * s * d, y = p[0] * s * d + p[1] * c; return [cx + x, base - y]; };
  var P2 = {}; for (var k in pts) P2[k] = tx(pts[k]);
  limb(R, P2.fb, P2.hip, 7, col); limb(R, P2.fa, P2.hip, 7, col); limb(R, P2.hip, P2.ch, 9, col);
  limb(R, P2.ch, P2.h2, 5, col);
  if (f.def.id === 'protagonist') R.poly(ngon(P2.hd[0], P2.hd[1], 9, 8, 0.39), col); else R.poly([P2.hd[0], P2.hd[1] - 12, P2.hd[0] + 7, P2.hd[1] - 2, P2.hd[0] + 5, P2.hd[1] + 9, P2.hd[0] - 5, P2.hd[1] + 9, P2.hd[0] - 7, P2.hd[1] - 2], col);
  if (f.blow && f.blow.h !== 'low' && !(f.blow.heavy && f.blow.t < f.blow.land - 2)) { var bt = f.blow.heavy ? f.blow.t - f.blow.land + 4 : f.blow.t, bq2 = Math.sin(Math.PI * clamp(bt / 6, 0, 1)), fc = chest(f.foe), ty = f.blow.h === 'high' || (f.foe.dodgeT > 0 && f.foe.slipD === 'toward') ? f.foe.y + 52 : fc[1], ba = Math.atan2(ty - f.y - 40, fc[0] - f.x), bl = 16 + (f.blow.heavy ? 24 : 18) * bq2; P2.h1 = [P2.ch[0] + Math.cos(ba) * bl, P2.ch[1] - Math.sin(ba) * bl]; }
  limb(R, P2.ch, P2.h1, 5, col);
  if (f.bchg && f.bchg.lv > 0) { var Lb = f.def.L.beam, rr = 6 + 3 * f.bchg.lv; ring(R, P2.h1[0], P2.h1[1], rr, 2.6, KEY, 16); ring(R, P2.h1[0], P2.h1[1], rr, 1.2, f.bchg.lv >= 3 ? Lb.main : Lb.edge, 16); }
  if (f.inp && f.inp.RB) { R.poly(ngon(P2.h1[0], P2.h1[1], 4.4, 8, 0), KEY); R.poly(ngon(P2.h1[0], P2.h1[1], 3.2, 8, 0), f.def.L.bolt.main); }
}
// the latched aim reads at his hand only: a short stub along the line, never a line to the rival (R7)
function drawAim(R, w, f) {
  if (!f.latched || !(f.inp && f.inp.RB) || f.beam) return;
  var a = aimAbs(f), h = muzzle(f, a), x0 = h[0] + Math.cos(a) * 8, y0 = sy(h[1] + Math.sin(a) * 8), x1 = h[0] + Math.cos(a) * 34, y1 = sy(h[1] + Math.sin(a) * 34), L = f.def.L.bolt;
  quad(R, x0, y0, x1, y1, 4.5, 4.5, KEY); quad(R, x0, y0, x1, y1, 2, 2, L.edge);
  R.poly(xf([0, -4.5, 7, 0, 0, 4.5], x1, y1, -a, 1, 1), KEY); R.poly(xf([0.8, -2.6, 5, 0, 0.8, 2.6], x1, y1, -a, 1, 1), L.main);
}
function drawBeam(R, w, f) {
  var b = f.beam, h = hand(f), L = f.def.L.beam, k = b.end ? Math.max(0, 1 - b.end / 9) : 1, len = b.len; if (len < 2 || k <= 0) return;
  var wd = (12 + 6 * b.lv) * f.def.bw * k, ux = Math.cos(b.a), uy = -Math.sin(b.a), nx = -uy, ny = ux, x0 = h[0], y0 = sy(h[1]), hot = b.t < 5 || b.dur - b.t < 6 || b.end;
  function band(fr, col) { var n = Math.max(2, Math.ceil(len / 10)), top = [], bot = []; for (var i = 0; i <= n; i++) { var s = len * i / n, m = 1; for (var j = 0; j < b.pulses.length; j++) { var dd = Math.abs(s - b.pulses[j]); if (dd < 18) m += 0.5 * (1 - dd / 18); } var hw = wd / 2 * m * fr + (fr > 1 ? 0 : 0), jit = i % 2 ? 0.7 : -0.7, cx = x0 + ux * s + nx * jit, cy = y0 + uy * s + ny * jit; top.push(cx + nx * hw, cy + ny * hw); bot.push(cx - nx * hw, cy - ny * hw); } var poly = top.slice(); for (var q = bot.length - 2; q >= 0; q -= 2) poly.push(bot[q], bot[q + 1]); R.poly(poly, col); }
  band(1 + 4 / wd, KEY); band(1 + 2 / wd, L.edge); band(1, L.main); band(hot ? 0.7 : 0.38, hot ? '#ffffff' : L.core);
  var fx = x0 + ux * len, fy = y0 + uy * len; spr(R, function (l2, w2) { return xf([-0.1, -0.55, 0.3, -0.5, 0.36, 0, 0.3, 0.5, -0.1, 0.55], fx, fy, Math.atan2(uy, ux), l2, w2); }, wd * 0.9, wd * 1.05, L);
}
function drawShot(R, w, s) {
  var L = s.o.def.L, X = s.x, Y2 = sy(s.y), a = Math.atan2(-s.vy, s.vx);
  if (s.k === 'bolt') spr(R, function (l, wd) { return xf([1.4, 0, 0, -0.5, -1.6, 0, 0, 0.5], X, Y2, a, l, wd); }, s.s, s.s * 0.9, L.bolt);
  else if (s.k === 'lob') spr(R, function (l, wd) { return xf([-0.9, -0.6, 0.2, -0.95, 1, -0.2, 0.8, 0.6, -0.2, 0.9, -1, 0.3], X, Y2, s.t * 0.08, l, wd); }, s.s, s.s * 0.9, L.lob);
  else spr(R, function (l, wd) { return xf([1, 0, 0.5, -0.55, -0.4, -0.35, -2.4, 0, -0.4, 0.35, 0.5, 0.55], X, Y2, a, l, wd); }, s.s, s.s * 0.9, L.lob);
}
function drawFx(R, e) {
  if (e.k === 'burst') { var u = e.t / e.dur, r = u < 0.3 ? e.r * ease(u / 0.3) : e.r * (1 - (u - 0.3) / 0.7 * ((u - 0.3) / 0.7)); if (r < 1) return; R.poly(star(e.x, sy(e.y), r + 2.5, r * 0.5 + 2, e.n, e.rot), KEY); R.poly(star(e.x, sy(e.y), r, r * 0.5, e.n, e.rot), e.lc.main); R.poly(star(e.x, sy(e.y), r * 0.6, r * 0.28, e.n, e.rot + 0.3), e.lc.core); return; }
  if (e.k === 'chip') { var s = e.s * (1 - e.t / e.dur); if (s < 0.4) return; R.poly(xf([0, -1, 0.9, 0.6, -0.9, 0.6], e.x, sy(e.y), e.rot, s, s), e.col); }
}
// the stick panel: the trace, the dead zone and the on and off rings, the hold's sector, and the recognizer's words
var PX = AW, PW = W - AW, PCX = AW + 196, PCY = 112, PR = 60;
function chip(R, x, y, wd, label, on, col) { R.poly([x, y, x + wd, y, x + wd, y + 14, x, y + 14], on ? col : C.dead); R.text(x + 4, y + 4, label, 7, on ? '#ffffff' : C.dim); }
function drawPanel(R, w) {
  var rd = w.rd, f = w.P, i = w.inp || {}, fam = rd.fam, famCol = fam === 'aim' || fam === 'lay' ? f.def.L.bolt.edge : fam === 'read' ? '#7a5a18' : fam === 'flight' ? f.def.body : C.dim;
  R.poly([PX, 0, W, 0, W, H, PX, H], C.panel); R.poly([PX, 0, PX + 2, 0, PX + 2, H, PX, H], C.ring);
  var famName = { flight: 'FLIGHT', aim: 'ENERGY AIM (RB)', lay: 'LAY AIM (LB+RB)', read: 'THE READ (LB)', none: 'NOTHING IN STEP 1' }[fam] || 'AT REST';
  R.text(PX + 12, 10, w.brawl ? 'RIGHT STICK, BRAWL' : 'RIGHT STICK', 14, C.dim); R.text(PX + 12, 28, famName, 14, fam ? famCol : C.dim);
  // the left thumb: its stick (the slip's direction) and the D-pad (the mirror)
  var lx0 = PX + 44, ly0 = 84; R.text(lx0 - 30, 52, 'LEFT', 7, C.dim);
  R.poly(ngon(lx0, ly0, 20, 20, 0), C.bg); ring(R, lx0, ly0, 20, 1.5, C.ring, 20); R.poly(ngon(lx0 + (i.lx || 0) * 16, ly0 + (i.ly || 0) * 16, 4, 8, 0), (i.lx || i.ly) ? C.ink : C.grey);
  var dx0 = PX + 44, dy0 = 140, dv = rd.dpVec || [0, 0]; R.text(dx0 - 30, 112, 'D-PAD', 7, C.dim);
  [[0, -1], [0, 1], [-1, 0], [1, 0]].forEach(function (a) { var x = dx0 + a[0] * 13, y = dy0 + a[1] * 13, on = (a[0] && a[0] === dv[0]) || (a[1] && a[1] === dv[1]); R.poly([x - 6, y - 6, x + 6, y - 6, x + 6, y + 6, x - 6, y + 6], on ? f.def.body : C.dead); });
  R.poly([dx0 - 6, dy0 - 6, dx0 + 6, dy0 - 6, dx0 + 6, dy0 + 6, dx0 - 6, dy0 + 6], C.dead);
  // the right stick
  R.poly(ngon(PCX, PCY, PR, 40, 0), C.bg); ring(R, PCX, PCY, PR, 2, C.ring, 40);
  var rOn = PR * (RS.deadZone + RS.on * (1 - RS.deadZone)), rOff = PR * (RS.deadZone + RS.off * (1 - RS.deadZone));
  for (var k = 0; k < 32; k += 2) { var a0 = k * Math.PI / 16, a1 = (k + 1) * Math.PI / 16; quad(R, PCX + Math.cos(a0) * rOn, PCY + Math.sin(a0) * rOn, PCX + Math.cos(a1) * rOn, PCY + Math.sin(a1) * rOn, 1.4, 1.4, C.ring); }
  ring(R, PCX, PCY, rOff, 1, C.dead, 32); R.poly(ngon(PCX, PCY, PR * RS.deadZone, 24, 0), C.dead);
  for (var j = 0; j < 4; j++) { var ad = Math.PI / 4 + j * Math.PI / 2; quad(R, PCX + Math.cos(ad) * PR * 0.3, PCY + Math.sin(ad) * PR * 0.3, PCX + Math.cos(ad) * PR, PCY + Math.sin(ad) * PR, 1, 1, C.dead); }
  if (rd.on && rd.held && fam !== 'none') { var q = quant(rd.trace[rd.trace.length - 1][0], rd.trace[rd.trace.length - 1][1]), aa0 = Math.atan2(q.y, q.x), half = fam === 'flight' ? Math.PI / 4 : Math.PI / 32; if (fam === 'flight' && rd.d4) aa0 = -deg(D4A[rd.d4]); var wedge = [PCX, PCY]; for (var m = 0; m <= 8; m++) { var aa = aa0 - half + 2 * half * m / 8; wedge.push(PCX + Math.cos(aa) * PR, PCY + Math.sin(aa) * PR); } R.poly(wedge, C.dead); }
  var tr = rd.trace;
  for (var n = 1; n < tr.length; n++) { var t0 = tr[n - 1], t1 = tr[n], wd = 0.6 + 2.6 * n / tr.length; quad(R, PCX + t0[0] * PR, PCY + t0[1] * PR, PCX + t1[0] * PR, PCY + t1[1] * PR, wd, wd, C.ink); }
  var cur = tr.length ? tr[tr.length - 1] : [0, 0]; R.poly(ngon(PCX + cur[0] * PR, PCY + cur[1] * PR, 6, 10, 0), KEY); R.poly(ngon(PCX + cur[0] * PR, PCY + cur[1] * PR, 4.5, 10, 0), rd.on ? famCol : C.grey);
  // the shoulders, the commitment (L = 6) and what waits
  chip(R, PX + 12, 182, 26, 'LB', !!i.LB, '#7a5a18'); chip(R, PX + 42, 182, 26, 'RB', !!i.RB, f.def.L.bolt.edge); chip(R, PX + 72, 182, 26, 'LT', !!i.LT, f.def.body);
  R.text(PX + 112, 182, 'COMMIT', 7, C.dim); for (var c2 = 0; c2 < LAW.L; c2++) R.poly([PX + 154 + c2 * 14, 181, PX + 165 + c2 * 14, 181, PX + 165 + c2 * 14, 195, PX + 154 + c2 * 14, 195], c2 < f.commit ? C.ink : C.dead);
  var info = f.read ? 'READ: ' + READWORD[f.read.k] + ' ' + (f.read.until - w.t) : f.q.length ? 'QUEUED: ' + f.q.map(function (e) { return e.k; }).join(' ') : '';
  if (info) R.text(PX + 12, 202, info, 14, f.read ? '#7a5a18' : C.ink);
  rd.log.slice(0, 5).forEach(function (e, idx) { R.text(PX + 12, 224 + idx * 20, e.text, 14, idx === 0 && !e.dim ? C.ink : e.dim ? C.grey : C.dim); });
}
// two lanes side by side on one clock (the claw against the one thumb, the stick against the D-pad), and their ticks
var LANE = { w: W / 2 - 4, h: 236, gy: 200, cells: 26, cw: 15 };
// a lane draws the arena through a fixed camera for the take (its centre x), the ground LANE.gy down, at full size
function laneR(R, ox, cx) {
  var x0 = clamp(cx - LANE.w / 2, 0, AW - LANE.w), y0 = GY - LANE.gy, X = function (x) { return ox + clamp(x, x0, x0 + LANE.w) - x0; }, Y = function (y) { return clamp(y, y0, y0 + LANE.h) - y0; };
  return { clear: function (col) { R.poly([ox, 0, ox + LANE.w, 0, ox + LANE.w, LANE.h, ox, LANE.h], col); },
    poly: function (pts, col) { var o = []; for (var k = 0; k < pts.length; k += 2) o.push(X(pts[k]), Y(pts[k + 1])); R.poly(o, col); },
    text: function (x, y, t2, size, col) { if (x >= x0 && x < x0 + LANE.w && y >= y0 && y < y0 + LANE.h) R.text(X(x), Y(y), t2, size, col); } };
}
// each lane's own input, small: the right stick, the D-pad, LB, LT and X, the commitment and what waits
function drawMini(R, lw, ox, y0) {
  var i = lw.inp || {}, f = lw.P, sx = ox + 424, dx = ox + 474, cy = y0 + 20, dv = lw.rd.dpVec || [0, 0];
  R.poly(ngon(sx, cy, 18, 20, 0), C.bg); ring(R, sx, cy, 18, 1.4, C.ring, 20); R.poly(ngon(sx + (i.rx || 0) * 14, cy + (i.ry || 0) * 14, 4, 8, 0), (i.rx || i.ry) ? C.ink : C.grey);
  [[0, -1], [0, 1], [-1, 0], [1, 0], [0, 0]].forEach(function (a) { var x = dx + a[0] * 11, y = cy + a[1] * 11, on = (a[0] && a[0] === dv[0]) || (a[1] && a[1] === dv[1]); R.poly([x - 5, y - 5, x + 5, y - 5, x + 5, y + 5, x - 5, y + 5], on ? f.def.body : C.dead); });
  chip(R, ox + 404, y0 + 44, 26, 'LB', !!i.LB, '#7a5a18'); chip(R, ox + 434, y0 + 44, 26, 'LT', !!i.LT, f.def.body); chip(R, ox + 464, y0 + 44, 26, 'X', !!i.X, '#b5651d');
  for (var c = 0; c < LAW.L; c++) R.poly([ox + 404 + c * 15, y0 + 64, ox + 416 + c * 15, y0 + 64, ox + 416 + c * 15, y0 + 72, ox + 404 + c * 15, y0 + 72], c < f.commit ? C.ink : C.dead);
}
// two lanes side by side on one clock (the claw against the one thumb, the stick against the D-pad), and their ticks
function drawSplit(run, R) {
  var T = run.clip.takes[run.take], lanes = [run.w, run.w2], top = LANE.h + 4;
  R.clear(C.panel);
  lanes.forEach(function (lw, j) {
    var ox = j * (W / 2 + 4); drawArena(lw, laneR(R, ox, T.cam || run.w.cam0));
    R.poly([ox, 0, ox + LANE.w, 0, ox + LANE.w, 22, ox, 22], C.panel); R.text(ox + 8, 5, T.labels[j], 14, C.ink);
    var nt = lw.rd.log[0]; if (nt) R.text(ox + 8, 28, nt.text, 14, nt.dim ? C.dim : C.ink);
    // the timeline: one cell a tick from the take's first input, with each mark: I input, F the command read, R the release,
    // X the press, B the blow
    var marks = lw.P.tl, t0 = T.tl0 || 0, y = top + 4, cw = LANE.cw;
    for (var c3 = 0; c3 < LANE.cells; c3++) { var tt = t0 + c3, x = ox + 8 + c3 * cw, here = marks.filter(function (m) { return m.t === tt && tt < lw.t; }), has = function (k) { return here.some(function (m) { return m.k === k; }); },
      col = !here.length ? C.dead : has('B') ? lw.P.def.body : has('P') ? '#7a5a18' : has('X') ? '#b5651d' : has('F') || has('R') ? lw.P.def.L.bolt.edge : C.grey;
      R.poly([x, y, x + cw - 2, y, x + cw - 2, y + 20, x, y + 20], col); if (here.length) R.text(x + 1, y + 6, here.map(function (m) { return m.k; }).join(''), 7, '#ffffff'); if (c3 % 5 === 0) R.text(x, y + 24, '+' + c3, 7, C.dim); }
    var key = T.key || 'B', hit = marks.filter(function (m) { return m.k === key && m.t >= t0 && m.t < lw.t; })[0];
    if (hit) R.text(ox + 8, y + 38, ({ F: 'THE COMMAND STARTS ON +', P: 'THE PRESS STARTS ON +', B: 'THE BLOW STARTS ON +' })[key] + (hit.t - t0), 14, C.ink);
    drawMini(R, lw, ox, top);
  });
  R.text(8, H - 12, 'I INPUT   F STICK OR PAD READ   R RELEASE   X FACE PRESS   P PRESS STARTS   B BLOW STARTS', 7, C.dim);
}
function draw(w, R) { drawArena(w, R); drawPanel(R, w); }
function drawArena(w, R) {
  R.clear(C.bg);
  R.poly([0, GY, AW, GY, AW, H, 0, H], C.ground); R.poly([0, GY, AW, GY, AW, GY + 1.5, 0, GY + 1.5], C.line);
  R.poly([LAKE.x0 - 12, GY, LAKE.x0, GY - 1, LAKE.x1, GY - 1, LAKE.x1 + 12, GY, LAKE.x1 - 20, GY + 12, LAKE.x0 + 20, GY + 12], C.lake);
  R.poly([CLIFF.x, GY + 1, CLIFF.x + 4, sy(CLIFF.top) + 6, CLIFF.x + 14, sy(CLIFF.top), AW, sy(CLIFF.top), AW, GY + 1], C.cliff);
  R.poly([CLIFF.x, GY + 1, CLIFF.x + 4, sy(CLIFF.top) + 6, CLIFF.x + 9, sy(CLIFF.top) + 4, CLIFF.x + 6, GY + 1], C.cliffDark);
  w.marks.forEach(function (m) { if (m.k === 'crater') { var b = m.w / 2; R.poly([m.x - b, GY + 1, m.x - b * 0.6, GY + b * 0.3, m.x + b * 0.6, GY + b * 0.3, m.x + b, GY + 1], C.scorch); } else R.poly([m.x - 7, GY + 1, m.x - 6, GY + m.d, m.x + 6, GY + m.d, m.x + 7, GY + 1], C.scorch); });
  w.mines.forEach(function (m) { var lc = m.t > 12 ? m.o.def.L.trap : { core: C.grey, main: C.grey, edge: m.o.def.L.trap.edge }; spr(R, function (l, wd) { return xf([1.4, 0, 0, -0.5, -1.6, 0, 0, 0.5], m.x, sy(m.y) - 6, -Math.PI / 2, l, wd); }, 5, 4.5, lc); });
  if (w.P.beam) drawBeam(R, w, w.P);
  w.P.inp = w.inp; drawFighter(R, w, w.V); drawFighter(R, w, w.P); drawAim(R, w, w.P);
  w.shots.forEach(function (s) { drawShot(R, w, s); }); w.fx.forEach(function (e) { drawFx(R, e); });
  w.grabs.forEach(function (g) { var L = g.o.def.L.trap; ring(R, g.x, sy(g.y), 10, 3.6, KEY, 14); ring(R, g.x, sy(g.y), 10, 2, L.main, 14); });
  if (w.P.caught > 0) { var cc = chest(w.P), L2 = w.V.def.L.trap; ring(R, cc[0], sy(cc[1] + (w.P.swayY || 0)), 14, 3.6, KEY, 16); ring(R, cc[0], sy(cc[1] + (w.P.swayY || 0)), 14, 2, L2.main, 16); }
  // ki at the screen's edge only
  var k = 120 * clamp(w.P.ki / 100, 0, 1); R.poly([14, 12, 134, 12, 134, 16, 14, 16], C.hud); R.poly([14, 12, 14 + k, 12, 14 + k, 16, 14, 16], w.P.def.L.beam.edge);
  if (w.P.bchg) for (var i = 0; i < 3; i++) R.poly([14 + i * 12, 21, 23 + i * 12, 21, 23 + i * 12, 26, 14 + i * 12, 26], i < w.P.bchg.lv ? w.P.def.L.beam.edge : C.hud);
}
return { W: W, H: H, CLIPS: CLIPS, RS: RS, MV: MV, LAW: LAW, newRun: newRun, stepRun: stepRun, draw: function (run, R) { if (run.w2) drawSplit(run, R); else draw(run.w, R); }, stepOf: stepOf, clipLen: clipLen, readStick: readStick, mkReader: mkReader };
})();
// ==== PAGE (DOM) ====
