
// ==== drawing: flat polygons through R.poly / R.text / R.clear (the page's canvas, or gif.mjs's rasteriser) ====
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

// a fighter's pose, in his own frame (y up from the feet, x toward the way he faces)
function pose(w, f) {
  var d = 1, air = f.y > 4, lean = f.lean + (f.reel > 0 ? -10 : 0);
  var pts = { fa: air ? [6, 2] : [9, 0], fb: air ? [-5, 4] : [-7, 0], hip: [0, 22], ch: [lean * 0.6, 42], hd: [lean * 0.7, 51], h1: [16, 40], h2: [9, 32] };
  var b = f.blow;
  if (b && b.kind === 'S') {     // the stick strikes: the wind-up draws back by direction, then the blow lands that way
    var ph = b.charging ? 1 : clamp(b.t / Math.max(1, b.wind), 0, 1), hit = !b.charging && b.t >= b.wind, k = hit ? Math.sin(Math.PI * clamp((b.t - b.wind) / 8, 0, 1)) : 0, cr = b.charging ? 1 + 0.15 * b.lv : 1;
    if (b.dir === 'toward') { if (!hit) { pts.h1 = [-12 * ph * cr, 36]; pts.ch = [-4 * ph, 40]; pts.hip = [0, 20]; } else { pts.h1 = [18 + 16 * k, 34]; pts.ch = [6 * k, 41]; pts.fa = [14, 0]; } }
    else if (b.dir === 'up') { if (!hit) { pts.hip = [0, 22 - 6 * ph * cr]; pts.ch = [2, 40 - 6 * ph * cr]; pts.hd = [3, 49 - 6 * ph * cr]; pts.h1 = [6, 26]; } else { pts.h1 = [10 + 4 * k, 58 + 12 * k]; pts.fa = [10, 14 * k]; pts.ch = [2, 44]; pts.hd = [3, 54]; } }
    else if (b.dir === 'down') { if (!hit) { pts.fa = [6, 18 + 14 * ph * cr]; pts.h1 = [-8, 46]; } else { pts.fa = [16 + 14 * k, 4]; pts.h1 = [12, 30]; pts.ch = [6, 38]; } }
    else { if (!hit) { pts.ch = [-6 * ph, 41]; pts.hd = [-7 * ph, 50]; pts.h1 = [-18 * ph * cr, 46]; pts.h2 = [-4, 34]; } else { pts.h1 = [20 + 14 * k, 48 - 4 * k]; pts.ch = [4 * k, 42]; pts.fb = [-12, 2]; } }
  } else if (b && (b.kind === 'X' || b.kind === 'Y' || b.kind === 'B' || b.kind === 'A' || b.kind === 'V')) {
    var big = b.kind === 'B' || b.heavy, ph2 = b.charging ? 1 : clamp(b.t / Math.max(1, b.wind), 0, 1), hit2 = !b.charging && b.t >= b.wind;
    if (!hit2 && (big || b.kind === 'Y')) { pts.h1 = [-(big ? 14 : 8) * ph2, 44]; pts.ch = [-(big ? 5 : 2) * ph2, 42]; pts.hd = [-(big ? 6 : 2) * ph2, 51]; }
    if (b.h === 'low' && hit2) pts.fa = [9 + 20 * Math.sin(Math.PI * clamp((b.t - b.wind) / 6, 0, 1)), 6];
    if (b.kind === 'A' && hit2) { pts.h1 = [24, 40]; pts.h2 = [22, 32]; }
  }
  if (f.beam && !f.beam.end) { pts.h1 = [22, 40]; pts.h2 = [-6, 30]; }
  if (f.held > 0) { pts.h1 = [20, 42]; pts.h2 = [18, 36]; }
  if (f.guard) { pts.h1 = [11, 48]; pts.h2 = [13, 40]; pts.ch = [lean * 0.6 - 2, 41]; }
  // the brace shows in his stance: hands high for a heavy, low for a flurry, wide for a grab, side-on for a shot
  if (f.brace) { var rk = f.brace.k; if (rk === 'heavy') { pts.h1 = [9, 52]; pts.h2 = [5, 48]; } else if (rk === 'flurry') { pts.hip = [0, 18]; pts.ch = [pts.ch[0], 37]; pts.hd = [pts.hd[0], 46]; pts.h1 = [12, 26]; pts.h2 = [8, 22]; } else if (rk === 'grab') { pts.h1 = [22, 38]; pts.h2 = [20, 30]; } else { pts.h1 = [4, 40]; pts.h2 = [-8, 34]; pts.ch = [pts.ch[0] - 4, 42]; } }
  if (f.sway === 'down') { pts.hip = [0, 13]; pts.ch = [6, 28]; pts.hd = [9, 35]; pts.h1 = [12, 26]; pts.h2 = [8, 22]; pts.fa = [11, 0]; pts.fb = [-10, 0]; }
  if (f.sway === 'up') { pts.fa = [6, 10]; pts.fb = [-4, 12]; }
  if (f.mv && f.mv.k === 'dodge' && f.slipD === 'toward') { pts.hip = [0, 14]; pts.ch = [9, 28]; pts.hd = [10, 35]; pts.h1 = [14, 26]; pts.h2 = [9, 22]; }
  if (f.mv && f.mv.k === 'vanish') { pts.fa = [-8, 10]; pts.fb = [-14, 8]; pts.ch = [8, 40]; pts.hd = [10, 49]; }
  // the Rival's states: stunned (he sways, guard down), down (lying), caught
  if (f.stun > 0 && !f.down) { var sw = Math.sin(w.t * 0.35) * 8; pts.ch = [sw * 0.6, 40]; pts.hd = [sw, 48]; pts.h1 = [4, 24]; pts.h2 = [-4, 24]; }
  if (f.caught > 0) { pts.h1 = [5, 34]; pts.h2 = [-5, 34]; pts.ch = [pts.ch[0] - 3, 42]; }
  return pts;
}
function drawBody(R, w, f, pts, d, cx, base, tilt, col) {
  var tx = function (p) { var c = Math.cos(tilt), s = Math.sin(tilt), x = p[0] * d * c - p[1] * s, y = p[0] * d * s + p[1] * c; return [cx + x, base - y]; };
  var P2 = {}; for (var k in pts) P2[k] = tx(pts[k]);
  limb(R, P2.fb, P2.hip, 7, col); limb(R, P2.fa, P2.hip, 7, col); limb(R, P2.hip, P2.ch, 9, col); limb(R, P2.ch, P2.h2, 5, col);
  if (f.def.id === 'protagonist') R.poly(ngon(P2.hd[0], P2.hd[1], 9, 8, 0.39), col); else R.poly([P2.hd[0], P2.hd[1] - 12, P2.hd[0] + 7, P2.hd[1] - 2, P2.hd[0] + 5, P2.hd[1] + 9, P2.hd[0] - 5, P2.hd[1] + 9, P2.hd[0] - 7, P2.hd[1] - 2], col);
  limb(R, P2.ch, P2.h1, 5, col);
  return P2;
}
function drawFighter(R, w, f) {
  var d = f.dir, base = sy(f.y + (f.swayY || 0)), sh = Math.max(0.2, 1 - f.y / 220), tilt = 0;
  R.poly(ngon(f.x, sy(0) + 3, 15 * sh, 8, 0).map(function (v, i) { return i % 2 ? sy(0) + 3 + (v - sy(0) - 3) * 0.2 : v; }), C.shade);
  if (f.down > 0) tilt = -d * Math.PI / 2 * clamp((26 - f.down) / 4 + 0.5, 0.5, 1) * (f.down < 6 ? f.down / 6 : 1);
  else if (f.air) tilt = -d * clamp(f.vy * 0.06, -0.9, 0.9);
  var P2 = drawBody(R, w, f, pose(w, f), d, f.x, base - (f.down > 0 ? 4 : 0), tilt, f.def.body);
  // a charge shows at his hand: a ring a size larger each level (the move's own light, not a marker)
  var b = f.blow;
  if (b && b.charging) { var L = b.kind === 'B' ? SPARK : f.def.L.bolt, rr = 5 + 3 * b.lv; ring(R, P2.h1[0], P2.h1[1], rr, 2.6, KEY, 16); ring(R, P2.h1[0], P2.h1[1], rr, 1.2, b.lv >= 3 ? L.main : L.edge, 16); }
  if (f === w.P && w.inp && w.inp.RB && !(f.beam && !f.beam.end)) { R.poly(ngon(P2.h1[0], P2.h1[1], 4.4, 8, 0), KEY); R.poly(ngon(P2.h1[0], P2.h1[1], 3.2, 8, 0), f.def.L.bolt.main); }
  if (f === w.P && w.inp && w.inp.RT && !(f.beam && !f.beam.end)) { R.poly(ngon(P2.h1[0], P2.h1[1], 4.4, 8, 0), KEY); R.poly(ngon(P2.h1[0], P2.h1[1], 3.2, 8, 0), f.def.L.sig.main); }
}
// the vanish leaves his shape behind for 8 ticks, in a pale tone, then it is gone (no fade)
function drawAfter(R, w, e) {
  var pts = { fa: [9, 0], fb: [-7, 0], hip: [0, 22], ch: [-2, 42], hd: [-2, 51], h1: [12, 40], h2: [6, 32] }, f = { def: w.P.def };
  drawBody(R, w, f, pts, e.dir, e.x, sy(e.y), 0, C.after);
}
function drawBeam(R, w, f) {
  var b = f.beam, h = hand(f), L = b.sig ? f.def.L.sig : f.def.L.beam, k = b.end ? Math.max(0, 1 - b.end / 9) : 1, len = b.len; if (len < 2 || k <= 0) return;
  var wd = beamW(f, b) * k, ux = Math.cos(b.a), uy = -Math.sin(b.a), nx = -uy, ny = ux, x0 = h[0], y0 = sy(h[1]), hot = b.t < 5 || b.dur - b.t < 6 || b.end;
  function band(fr, col) { var n = Math.max(2, Math.ceil(len / 10)), top = [], bot = []; for (var i = 0; i <= n; i++) { var s = len * i / n, hw = wd / 2 * fr, jit = i % 2 ? 0.7 : -0.7, cx = x0 + ux * s + nx * jit, cy = y0 + uy * s + ny * jit; top.push(cx + nx * hw, cy + ny * hw); bot.push(cx - nx * hw, cy - ny * hw); } var poly = top.slice(); for (var q = bot.length - 2; q >= 0; q -= 2) poly.push(bot[q], bot[q + 1]); R.poly(poly, col); }
  band(1 + 4 / wd, KEY); band(1 + 2 / wd, L.edge); band(1, L.main); band(hot ? 0.7 : 0.38, hot ? '#ffffff' : L.core);
  var fx = x0 + ux * len, fy = y0 + uy * len; spr(R, function (l2, w2) { return xf([-0.1, -0.55, 0.3, -0.5, 0.36, 0, 0.3, 0.5, -0.1, 0.55], fx, fy, Math.atan2(uy, ux), l2, w2); }, wd * 0.9, wd * 1.05, L);
}
function drawShot(R, w, s) {
  var L = s.o.def.L, X = s.x, Y2 = sy(s.y), a = Math.atan2(-s.vy, s.vx);
  if (s.k === 'bolt') spr(R, function (l, wd) { return xf([1.4, 0, 0, -0.5, -1.6, 0, 0, 0.5], X, Y2, a, l, wd); }, s.s, s.s * 0.9, L.bolt);
  else if (s.k === 'lob') spr(R, function (l, wd) { return xf([-0.9, -0.6, 0.2, -0.95, 1, -0.2, 0.8, 0.6, -0.2, 0.9, -1, 0.3], X, Y2, s.t * 0.08, l, wd); }, s.s, s.s * 0.9, L.lob);
  else spr(R, function (l, wd) { return xf([1, 0, 0.5, -0.55, -0.4, -0.35, -2.4, 0, -0.4, 0.35, 0.5, 0.55], X, Y2, a, l, wd); }, s.s, s.s * 0.9, L.lob);
}
function drawFx(R, w, e) {
  if (e.k === 'ack') { if (e.t >= 1 && e.t <= 4) { var ah = hand(e.f); R.poly(star(ah[0], sy(ah[1] + (e.f.swayY || 0)), 5, 2, 4, 0.4), e.t % 2 ? C.grey : C.dim); } return; }
  if (e.k === 'after') { drawAfter(R, w, e); return; }
  if (e.k === 'burst') { var u = e.t / e.dur, r = u < 0.3 ? e.r * ease(u / 0.3) : e.r * (1 - (u - 0.3) / 0.7 * ((u - 0.3) / 0.7)); if (r < 1) return; R.poly(star(e.x, sy(e.y), r + 2.5, r * 0.5 + 2, e.n, e.rot), KEY); R.poly(star(e.x, sy(e.y), r, r * 0.5, e.n, e.rot), e.lc.main); R.poly(star(e.x, sy(e.y), r * 0.6, r * 0.28, e.n, e.rot + 0.3), e.lc.core); return; }
  if (e.k === 'chip') { var s = e.s * (1 - e.t / e.dur); if (s < 0.4) return; R.poly(xf([0, -1, 0.9, 0.6, -0.9, 0.6], e.x, sy(e.y), e.rot, s, s), e.col); }
}
function drawArena(w, R) {
  R.clear(C.bg);
  R.poly([0, GY, AW, GY, AW, H, 0, H], C.ground); R.poly([0, GY, AW, GY, AW, GY + 1.5, 0, GY + 1.5], C.line);
  R.poly([LAKE.x0 - 12, GY, LAKE.x0, GY - 1, LAKE.x1, GY - 1, LAKE.x1 + 12, GY, LAKE.x1 - 20, GY + 12, LAKE.x0 + 20, GY + 12], C.lake);
  w.marks.forEach(function (m) { if (m.k === 'crater') { var b = m.w / 2; R.poly([m.x - b, GY + 1, m.x - b * 0.6, GY + b * 0.3, m.x + b * 0.6, GY + b * 0.3, m.x + b, GY + 1], C.scorch); } else R.poly([m.x - 7, GY + 1, m.x - 6, GY + m.d, m.x + 6, GY + m.d, m.x + 7, GY + 1], C.scorch); });
  w.fx.forEach(function (e) { if (e.k === 'after') drawFx(R, w, e); });
  if (w.P.beam) drawBeam(R, w, w.P);
  drawFighter(R, w, w.V); drawFighter(R, w, w.P);
  w.shots.forEach(function (s) { drawShot(R, w, s); }); w.fx.forEach(function (e) { if (e.k !== 'after') drawFx(R, w, e); });
  w.grabs.forEach(function (g) { var L = g.o.def.L.trap; ring(R, g.x, sy(g.y), 10, 3.6, KEY, 14); ring(R, g.x, sy(g.y), 10, 2, L.main, 14); });
  if (w.P.caught > 0) { var cc = chest(w.P), L2 = w.V.def.L.trap; ring(R, cc[0], sy(cc[1]), 14, 3.6, KEY, 16); ring(R, cc[0], sy(cc[1]), 14, 2, L2.main, 16); }
  // at the screen's edges only: his ki (left), the Rival's health (right), never over the fighters
  var k = 120 * clamp(w.P.ki / 100, 0, 1); R.poly([14, 12, 134, 12, 134, 16, 14, 16], C.hud); R.poly([14, 12, 14 + k, 12, 14 + k, 16, 14, 16], w.P.def.L.beam.edge);
  var hp = 120 * clamp(w.V.hp / 100, 0, 1); R.poly([AW - 134, 12, AW - 14, 12, AW - 14, 16, AW - 134, 16], C.hud); R.poly([AW - 14 - hp, 12, AW - 14, 12, AW - 14, 16, AW - 14 - hp, 16], w.V.def.body);
}

// ---- the panel: the pitch, the mode, both sticks, the shoulders and the face buttons, the waits, and what was read ----
var PX = AW;
function chip(R, x, y, wd, label, on, col) { R.poly([x, y, x + wd, y, x + wd, y + 14, x, y + 14], on ? col : C.dead); R.text(x + 4, y + 4, label, 7, on ? '#ffffff' : C.dim); }
function stickDial(R, cx, cy, r, trace, lit, col, label) {
  R.poly(ngon(cx, cy, r, 32, 0), C.bg); ring(R, cx, cy, r, 1.6, C.ring, 32);
  var rOn = r * (RS.deadZone + RS.on * (1 - RS.deadZone)); for (var k = 0; k < 24; k += 2) { var a0 = k * Math.PI / 12, a1 = (k + 1) * Math.PI / 12; quad(R, cx + Math.cos(a0) * rOn, cy + Math.sin(a0) * rOn, cx + Math.cos(a1) * rOn, cy + Math.sin(a1) * rOn, 1.2, 1.2, C.ring); }
  R.poly(ngon(cx, cy, r * RS.deadZone, 16, 0), C.dead);
  for (var n = 1; n < trace.length; n++) { var t0 = trace[n - 1], t1 = trace[n], wd = 0.6 + 2.4 * n / trace.length; quad(R, cx + t0[0] * r, cy + t0[1] * r, cx + t1[0] * r, cy + t1[1] * r, wd, wd, C.ink); }
  var cur = trace.length ? trace[trace.length - 1] : [0, 0]; R.poly(ngon(cx + cur[0] * r, cy + cur[1] * r, 5.5, 10, 0), KEY); R.poly(ngon(cx + cur[0] * r, cy + cur[1] * r, 4, 10, 0), lit ? col : C.grey);
  R.text(cx - r, cy + r + 6, label, 7, C.dim);
}
function drawPanel(R, w) {
  var f = w.P, i = w.inp || {}, P = PITCH[w.pitch], mode = i.RT ? 'POWER (RT)' : i.RB ? 'ENERGY (RB)' : 'MARTIAL', mcol = i.RT ? f.def.L.sig.edge : i.RB ? f.def.L.bolt.edge : f.def.body;
  R.poly([PX, 0, W, 0, W, H, PX, H], C.panel); R.poly([PX, 0, PX + 2, 0, PX + 2, H, PX, H], C.ring);
  R.text(PX + 12, 8, P.tag, 14, C.ink); R.text(PX + 48, 12, P.name, 7, C.dim);
  R.text(PX + 12, 28, mode, 14, mcol);
  var lfam = i.LT && i.LB ? 'VANISH' : i.LT ? 'SLIP' : i.LB ? (f.guard ? 'GUARD, BRACE' : 'BRACE') : 'MOVE';
  stickDial(R, PX + 46, 92, 28, w.rdL.trace, !!(i.lx || i.ly), C.ink, 'LEFT: ' + lfam);
  var rlab = i.RT ? (w.pitch === '4c' ? 'RIGHT: SIGNATURE' : 'RIGHT: (NONE)') : i.RB ? 'RIGHT: BEAM' : 'RIGHT: STRIKE';
  stickDial(R, PX + 200, 96, 42, w.rd.trace, w.rd.on, mcol, rlab);
  chip(R, PX + 12, 156, 24, 'LT', !!i.LT, f.def.body); chip(R, PX + 40, 156, 24, 'LB', !!i.LB, '#7a5a18'); chip(R, PX + 228, 156, 24, 'RB', !!i.RB, f.def.L.bolt.edge); chip(R, PX + 256, 156, 24, 'RT', !!i.RT, f.def.L.sig.edge);
  [['X', i.X], ['Y', i.Y], ['B', i.B], ['A', i.A]].forEach(function (c, n) { chip(R, PX + 92 + n * 30, 156, 24, c[0], !!c[1], '#b5651d'); });
  // the right thumb's waits: the face buttons behind a stick move (L), the stick behind a press (R)
  var lock = thumbT(w, f, i) + LAW.R - w.t;
  R.text(PX + 12, 180, 'BUTTONS WAIT', 7, C.dim); for (var c2 = 0; c2 < LAW.L; c2++) R.poly([PX + 96 + c2 * 11, 179, PX + 105 + c2 * 11, 179, PX + 105 + c2 * 11, 187, PX + 96 + c2 * 11, 187], c2 < f.commit ? C.ink : C.dead);
  R.text(PX + 12, 192, 'STICK WAITS', 7, C.dim); for (var c3 = 0; c3 < LAW.R; c3++) R.poly([PX + 96 + c3 * 11, 191, PX + 105 + c3 * 11, 191, PX + 105 + c3 * 11, 199, PX + 96 + c3 * 11, 199], c3 < lock ? C.ink : C.dead);
  var info = f.brace ? 'BRACE: ' + BRACEW[f.brace.k] : f.q.length ? 'WAITING: ' + f.q.map(function (e) { return QN[e.k]; }).join(' ') : f.pend ? 'STICK WAITING' : '';
  if (info) R.text(PX + 190, 182, info.slice(0, 18), 7, f.brace ? '#7a5a18' : C.ink);
  w.rd.log.slice(0, 5).forEach(function (e, idx) { R.text(PX + 12, 210 + idx * 20, e.text, 14, idx === 0 && !e.dim ? C.ink : e.dim ? C.grey : C.dim); });
}
function draw(w, R) { drawArena(w, R); drawPanel(R, w); }

// ---- two lanes side by side on one clock (the claw against one thumb), with each lane's ticks ----
var LANE = { w: W / 2 - 4, h: 236, gy: 200, cells: 26, cw: 15 };
function laneR(R, ox, cx) {
  var x0 = clamp(cx - LANE.w / 2, 0, AW - LANE.w), y0 = GY - LANE.gy, X = function (x) { return ox + clamp(x, x0, x0 + LANE.w) - x0; }, Y = function (y) { return clamp(y, y0, y0 + LANE.h) - y0; };
  return { clear: function (col) { R.poly([ox, 0, ox + LANE.w, 0, ox + LANE.w, LANE.h, ox, LANE.h], col); },
    poly: function (pts, col) { var o = []; for (var k = 0; k < pts.length; k += 2) o.push(X(pts[k]), Y(pts[k + 1])); R.poly(o, col); },
    text: function (x, y, t2, size, col) { if (x >= x0 && x < x0 + LANE.w && y >= y0 && y < y0 + LANE.h) R.text(X(x), Y(y), t2, size, col); } };
}
function drawMini(R, lw, ox, y0) {
  var i = lw.inp || {}, f = lw.P, sx = ox + 424, cy = y0 + 20, tr = lw.rd.trace, cur = tr.length ? tr[tr.length - 1] : [0, 0];
  R.poly(ngon(sx, cy, 18, 20, 0), C.bg); ring(R, sx, cy, 18, 1.4, C.ring, 20); R.poly(ngon(sx + cur[0] * 14, cy + cur[1] * 14, 4, 8, 0), lw.rd.on ? C.ink : C.grey);
  chip(R, ox + 452, y0 + 12, 22, 'X', !!i.X, '#b5651d'); chip(R, ox + 478, y0 + 12, 22, 'RB', !!i.RB, f.def.L.bolt.edge);
  for (var c = 0; c < LAW.R; c++) { var lk = thumbT(lw, f, i) + LAW.R - lw.t; R.poly([ox + 404 + c * 11, y0 + 46, ox + 413 + c * 11, y0 + 46, ox + 413 + c * 11, y0 + 54, ox + 404 + c * 11, y0 + 54], c < lk ? C.ink : C.dead); }
  for (var c4 = 0; c4 < LAW.L; c4++) R.poly([ox + 404 + c4 * 11, y0 + 60, ox + 413 + c4 * 11, y0 + 60, ox + 413 + c4 * 11, y0 + 68, ox + 404 + c4 * 11, y0 + 68], c4 < f.commit ? C.ink : C.dead);
}
function drawSplit(run, R) {
  var T = run.clip.takes[run.take], lanes = [run.w, run.w2], top = LANE.h + 4;
  R.clear(C.panel);
  lanes.forEach(function (lw, j) {
    var ox = j * (W / 2 + 4); drawArena(lw, laneR(R, ox, T.cam || run.w.cam0));
    R.poly([ox, 0, ox + LANE.w, 0, ox + LANE.w, 22, ox, 22], C.panel); R.text(ox + 8, 5, T.labels[j], 14, C.ink);
    var nt = lw.rd.log[0]; if (nt) R.text(ox + 8, 28, nt.text, 14, nt.dim ? C.dim : C.ink);
    var marks = lw.P.tl, t0 = T.tl0 || 0, y = top + 4, cw = LANE.cw;
    for (var c3 = 0; c3 < LANE.cells; c3++) { var tt = t0 + c3, x = ox + 8 + c3 * cw, here = marks.filter(function (m) { return m.t === tt && tt < lw.t; }), has = function (k) { return here.some(function (m) { return m.k === k; }); },
      col = !here.length ? C.dead : has('P') ? lw.P.def.body : has('X') ? '#b5651d' : has('F') || has('R') ? lw.P.def.L.bolt.edge : C.grey;
      R.poly([x, y, x + cw - 2, y, x + cw - 2, y + 20, x, y + 20], col); if (here.length) R.text(x + 1, y + 6, here.map(function (m) { return m.k; }).join('').slice(0, 2), 7, '#ffffff'); if (c3 % 5 === 0) R.text(x, y + 24, '+' + c3, 7, C.dim); }
    var key = T.key || 'P', hit = marks.filter(function (m) { return m.k === key && m.t >= t0 && m.t < lw.t; })[T.nth || 0];
    if (hit) R.text(ox + 8, y + 38, (T.keyText || 'IT STARTS ON +') + (hit.t - t0), 14, C.ink);
    drawMini(R, lw, ox, top);
  });
  R.text(8, H - 12, 'I THE STICK MOVES   F THE STICK ACTS   R LET GO   X A FACE PRESS   P A MOVE STARTS', 7, C.dim);
}
