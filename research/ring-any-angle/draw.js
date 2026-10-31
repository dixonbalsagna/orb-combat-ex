
// ==== drawing: flat polygons through R.poly / R.text / R.clear (the page's canvas, or sheets.mjs's rasteriser) ====
var RAD = (function () {
'use strict';
var W = 1020, H = 440, FW = 640, FH = 300, GX = 800, GY = 150, GR = 140, COLS = { 0: '#3f6f9e', 1: '#7fa35f', 2: '#4f7f4a', 3: '#cfb77d', 4: '#8a8378', 5: '#e9eef2', 6: '#c6d8e4' };
var mapT = null, N_LON = 180, N_LAT = 90;
function ensureMap() { if (mapT) return; mapT = new Uint8Array(N_LON * N_LAT); for (var j = 0; j < N_LAT; j++) for (var i = 0; i < N_LON; i++) { var la = (j + 0.5) / N_LAT * Math.PI - Math.PI / 2, lo = (i + 0.5) / N_LON * 2 * Math.PI, p = [Math.cos(la) * Math.cos(lo), Math.sin(la), Math.cos(la) * Math.sin(lo)]; mapT[j * N_LON + i] = surf(7, p[0], p[1], p[2])[1]; } }
function biomeAt(p) { var la = Math.asin(Math.max(-1, Math.min(1, p[1]))), lo = Math.atan2(p[2], p[0]); if (lo < 0) lo += 2 * Math.PI; var j = Math.min(N_LAT - 1, Math.floor((la + Math.PI / 2) / Math.PI * N_LAT)), i = Math.min(N_LON - 1, Math.floor(lo / (2 * Math.PI) * N_LON)); return mapT[j * N_LON + i]; }
// the places: keyed points on the planet, each a cluster of buildings with their own planet coordinates
var bld = null;
function ensureBld() {
  if (bld) return; bld = []; var x = 12345;
  function rnd() { x = (Math.imul(x, 1664525) + 1013904223) >>> 0; return x / 4294967296; }
  for (var c = 0; c < 160; c++) {
    var q = RAA.norm([rnd() - 0.5, rnd() - 0.5, rnd() - 0.5]); if (surf(7, q[0], q[1], q[2])[0] < 0) continue;
    var e = RAA.norm(RAA.cross(q, [0, 1, 0])), n = RAA.cross(q, e), rr = R;
    for (var b = 0; b < 26; b++) { var dx = (rnd() - 0.5) * 5200, dz = (rnd() - 0.5) * 5200, p = RAA.norm([q[0] + (e[0] * dx + n[0] * dz) / rr, q[1] + (e[1] * dx + n[1] * dz) / rr, q[2] + (e[2] * dx + n[2] * dz) / rr]); bld.push({ p: p, w: 90 + rnd() * 160, h: 120 + rnd() * 420 }); }
  }
}
function viewHalf(run) { var g = run.lastW ? Math.abs(run.lastW.b - run.lastW.a) * RAA.COL : 0; return Math.max(3600, Math.min(RAA.CFG.view * RAA.COL, g * 0.7 + 3000)); }
function fightView(run, R2) {
  var w = run.lastW; if (!w) return; var A = run.arch, s = A.s, m = Math.round(w.m), half = viewHalf(run), sc = FW / (2 * half), cols = Math.ceil(half / RAA.COL), mAx = A.axis(m), mh = A.height(m), y0 = FH * 0.72;
  var sky = '#dbe6ee'; R2.poly([0, 0, FW, 0, FW, FH, 0, FH], sky);
  // the far land: the planet's own ground beside the line, so it turns when the line does (Rendering's far field would read this)
  var l = RAA.cross(mAx.p, mAx.t), pts = [0, FH], far = 9000;
  for (var k = 0; k <= 32; k++) { var dx = (k / 32 - 0.5) * half * 2.6, p = RAA.norm([mAx.p[0] + (mAx.t[0] * dx - l[0] * far) / R, mAx.p[1] + (mAx.t[1] * dx - l[1] * far) / R, mAx.p[2] + (mAx.t[2] * dx - l[2] * far) / R]), h = surf(7, p[0], p[1], p[2])[0]; pts.push(k / 32 * FW, y0 - 46 - (h - mh) * sc * 0.35); }
  pts.push(FW, FH); R2.poly(pts, '#b8c6c9');
  // buildings at their planet coordinates, read in the frame at the pair: in the band, in front of the line or behind it
  ensureBld(); var felled = {};
  (A.store ? A.store.log : run.marks).forEach(function (mk) { felled[mk.id] = mk; });
  var ms = run.marks.filter(function (mk) { return felled[mk.id] && RAA.arcU(mk.p, mAx.p) < half * 1.6; });
  bld.forEach(function (b) {
    var d = [b.p[0] - mAx.p[0], b.p[1] - mAx.p[1], b.p[2] - mAx.p[2]], dx2 = RAA.dot(d, mAx.t) * R, dz = RAA.dot(d, l) * R;
    if (Math.abs(dx2) > half + 300 || dz > 400 || dz < -RAA.CFG.band) return;
    var down = false; for (var q = 0; q < ms.length; q++) if (RAA.arcU(ms[q].p, b.p) < ms[q].r) down = true;
    var sx = FW / 2 + dx2 * sc, g = A.height(m + Math.round(dx2 / RAA.COL)), by = y0 - (g - mh) * sc - dz * sc * -0.12, hh = (down ? b.h * 0.18 : b.h) * sc, ww = b.w * sc;
    R2.poly([sx - ww / 2, by, sx + ww / 2, by, sx + ww / 2, by - hh, sx - ww / 2, by - hh], down ? '#8d8878' : '#9aa0a6');
  });
  // the ground: the strip's own columns, unrolled straight, as the sim reads them
  var g2 = [0, FH]; for (var o = -cols; o <= cols; o += Math.max(1, Math.floor(cols / 90))) { g2.push(FW / 2 + o * RAA.COL * sc, y0 - (A.height(m + o) - mh) * sc); } g2.push(FW, FH);
  R2.poly(g2, '#7d8a5c');
  [[w.a, '#1f4f4a'], [w.b, '#33295a']].forEach(function (f) { var fx = FW / 2 + (f[0] - w.m) * RAA.COL * sc, fy = y0 - (A.height(Math.round(f[0])) - mh) * sc, bh = Math.max(14, 75 * sc); R2.poly([fx - bh * 0.16, fy, fx + bh * 0.16, fy, fx + bh * 0.16, fy - bh, fx - bh * 0.16, fy - bh], f[1]); });
}
function globe(run, R2) {
  ensureMap(); var w = run.lastW; if (!w) return; var A = run.arch, s = A.s, m = Math.round(w.m), ax = A.axis(m), c = ax.p, e = RAA.norm(RAA.cross([0, 1, 0], c)), n = RAA.cross(c, e), S = 6, r2 = GR * GR;
  for (var y = -GR; y < GR; y += S) for (var x = -GR; x < GR; x += S) {
    var d = (x + S / 2) * (x + S / 2) + (y + S / 2) * (y + S / 2); if (d > r2) continue; var z = Math.sqrt(r2 - d) / GR, u = (x + S / 2) / GR, v = -(y + S / 2) / GR;
    var p = [c[0] * z + e[0] * u + n[0] * v, c[1] * z + e[1] * u + n[1] * v, c[2] * z + e[2] * u + n[2] * v];
    R2.poly([GX + x, GY + y, GX + x + S, GY + y, GX + x + S, GY + y + S, GX + x, GY + y + S], COLS[biomeAt(p)] || '#555');
  }
  function pr(p) { return { x: GX + RAA.dot(p, e) * GR, y: GY - RAA.dot(p, n) * GR, z: RAA.dot(p, c) }; }
  function seg(a, b, wd, col) { var dx = b.x - a.x, dy = b.y - a.y, l = Math.sqrt(dx * dx + dy * dy) || 1, nx = -dy / l * wd / 2, ny = dx / l * wd / 2; R2.poly([a.x + nx, a.y + ny, b.x + nx, b.y + ny, b.x - nx, b.y - ny, a.x - nx, a.y - ny], col); }
  // the fight's line, as the columns stand: laid ground bright, what is not laid yet faint
  var last = null, lastI = -1; if (A.kind !== 'field') for (var o = -2400; o <= 2400; o += 24) {
    var cc = m + o, i = RAA.mod(cc), f = A.kind === 'ribbon' && (cc > A.hi || cc < A.lo) ? A.axis(cc) : null, pp = f ? f.p : RAA.getP(s, i), q = pr(pp), lit = !f && s.read[i];
    if (last && last.z > 0 && q.z > 0) seg(last, q, lit ? 2.4 : 1, lit ? '#ffffff' : '#2b2f33'); last = q;
  } else { var fq = A.axis(m - 1200), lq = pr(fq.p); for (var o2 = -1200; o2 <= 1200; o2 += 24) { var q2 = pr(A.axis(m + o2).p); if (lq.z > 0 && q2.z > 0) seg(lq, q2, 2.4, '#ffffff'); lq = q2; } }
  (A.store ? A.store.log : run.marks).forEach(function (mk) { var q3 = pr(mk.p); if (q3.z > 0) R2.poly([q3.x - 3, q3.y, q3.x, q3.y - 3, q3.x + 3, q3.y, q3.x, q3.y + 3], '#c0392b'); });
  var pq = pr(c); R2.poly([pq.x - 4, pq.y - 4, pq.x + 4, pq.y - 4, pq.x + 4, pq.y + 4, pq.x - 4, pq.y + 4], '#ffdd33');
}
// the strip as a bar: the whole ring, the pair in the middle: fine ground, coarse ground, not read; the seam; marks
function ringBar(run, R2) {
  var w = run.lastW; if (!w) return; var A = run.arch, s = A.s, m = Math.round(w.m), x0 = 8, wd = FW - 16, y = FH + 8, h = 16, NC = RAA.NC, st = NC / wd;
  for (var px = 0; px < wd; px += 2) {
    var c = m - NC / 2 + Math.floor(px * st), i = RAA.mod(c), col = s.read[i] ? '#5a6b4a' : s.base[i] !== 0 ? '#9fb08e' : '#d8d6cc'; if (s.tag[i]) col = '#c0392b';
    R2.poly([x0 + px, y, x0 + px + 2, y, x0 + px + 2, y + h, x0 + px, y + h], col);
  }
  var vh = RAA.CFG.view / st; R2.poly([x0 + wd / 2 - vh, y - 3, x0 + wd / 2 + vh, y - 3, x0 + wd / 2 + vh, y - 1, x0 + wd / 2 - vh, y - 1], '#1f1f1c');
  R2.text(x0, y + h + 4, 'THE RING, THE PAIR MID. DARK LAID, PALE COARSE, RED MARKS, BLACK LINE WIDEST VIEW', 7, '#5f5e5a');
  // reads a tick, the last 200 ticks, against K
  var gx = x0, gy = FH + 62, gw = FW - 16, gh = 44, n = Math.min(200, run.evHist.length), top = Math.max(24, run.evPeak); R2.poly([gx, gy - gh, gx + gw, gy - gh, gx + gw, gy, gx, gy], '#f1efe8');
  var ky = gy - gh * Math.min(1, RAA.CFG.K / top); R2.poly([gx, ky, gx + gw, ky, gx + gw, ky + 1, gx, ky + 1], '#b5651d');
  for (var t = 0; t < n; t++) { var v = run.evHist[run.evHist.length - n + t], bh = gh * Math.min(1, v / top), xx = gx + t / 200 * gw; if (v) R2.poly([xx, gy, xx + gw / 200, gy, xx + gw / 200, gy - bh, xx, gy - bh], v > RAA.CFG.K ? '#c0392b' : '#3f6f9e'); }
  R2.text(gx, gy + 4, 'NOISE READS A TICK (THE ORANGE LINE IS THE BUDGET, K ' + RAA.CFG.K + '; PEAK ' + run.evPeak + ')', 7, '#5f5e5a');
}
function panel(run, R2, note) {
  var x = FW + 14, y = 300, A = run.arch, mr = RAA.marksReport(run), ax0 = run.ax0, line = function (t, c) { R2.text(x, y, t, 7, c || '#1f1f1c'); y += 13; };
  R2.text(FW + 14, 6, RAA.ARCHS[run.key].name.toUpperCase().slice(0, 50), 7, '#0c447c');
  line('TICK ' + run.t + '   READS ' + run.evT + ' PEAK ' + run.evPeak); line('ASKS ' + run.asks.length + '  REFUSED ' + run.refused + '  TURNS ' + run.turns);
  var d = run.asks.filter(function (a) { return a.done != null; }); line('LAST TURN REACHED THE PAIR IN ' + (d.length ? d[d.length - 1].done + ' TICKS' : '-'));
  line('POP TICKS ' + run.viewPopTicks + '  LARGEST ' + Math.round(run.viewPopMax) + ' U', run.viewPopTicks ? '#c0392b' : '#1f1f1c'); line('CHANGED WHILE AWAY ' + run.reseen + ' COLUMNS', run.reseen ? '#b5651d' : '#1f1f1c');
  line('MARKS ' + mr.marks + '  ON THE STRIP ' + mr.right + '  WOULD BE FOUND ' + mr.revisit); if (note) line(note, '#5f5e5a');
}
function draw(run, R2, note) { R2.clear('#ffffff'); fightView(run, R2); globe(run, R2); ringBar(run, R2); panel(run, R2, note); }
return { W: W, H: H, draw: draw };
})();
