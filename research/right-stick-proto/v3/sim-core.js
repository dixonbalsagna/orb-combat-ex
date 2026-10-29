// ==== HAND SIM (no DOM) ====
// Right hand attacks, v3: "the left hand survives, the right hand hurts" (docs/ep/right-hand-attacks-pitch.md, Orb's
// direction of 2026-10-28). The left stick moves; LT, LB or both plus a left flick slip, brace or vanish; LB alone guards.
// The face buttons are the quick moves (light, medium, heavy, grab; with RB held, blasts); the right stick is the big move
// (a strike, flicked or held to charge; with RB held, a beam). Pitches 4a, 4b and 4c switch how a stick strike is costed and
// where the signature lives. The right thumb keeps Controls' law (docs/controls/right-thumb.md: L = 6, R = 8, the flick's
// 2-tick settle), as Research's v2 did. Numbers are the pitch's until Controls and Game Design report. No DOM: the page drives
// it and gif.mjs runs it in node. 60 ticks a second, no randomness (a hash for every jitter), flat polygons only.
var S = (function () {
'use strict';
var W = 1020, H = 340, AW = 720, GY = 300, BH = 56, KEY = '#0a0d14';
var C = { bg: '#f3f1ea', ground: '#e8e6dc', line: '#888780', dirt: '#b3a991', scorch: '#6d6a62', shade: '#d6d4c9', grey: '#a9a79e',
  lake: '#7fb0cf', lakeLite: '#c9e2ef', ink: '#1f1f1c', hud: '#d3d1c7', panel: '#e6e3d9', ring: '#b9b6ab', dead: '#d3d0c4', dim: '#8a877d', after: '#c6cfcc' };
function lane(core, main, edge) { return { core: core, main: main, edge: edge }; }
var FIGHTERS = [
  { id: 'protagonist', name: 'Protagonist', body: '#1f4f4a',
    L: { bolt: lane('#f2fdff', '#10c2ea', '#0b7fb8'), lob: lane('#ecfaff', '#1eb0f4', '#0e6cc4'), beam: lane('#f4faff', '#2e90f2', '#0d58c4'), trap: lane('#e8f5ff', '#2a9cf4', '#0f62bc'), sig: lane('#fffbea', '#f2b632', '#b26a0c') }, sweep: 32, bw: 1.2 },
  { id: 'rival', name: 'Rival', body: '#33295a',
    L: { bolt: lane('#f0e6ff', '#4420c4', '#2e0c78'), lob: lane('#f6e6ff', '#5c1ca8', '#3c0c6c'), beam: lane('#ffe8fb', '#80127e', '#5a0c64'), trap: lane('#eee4ff', '#4c20ac', '#300c70'), sig: lane('#ffe8fb', '#80127e', '#5a0c64') }, sweep: 34, bw: 0.85 }];
var LAKE = { x0: 250, x1: 470 };

// ---- the readers (Controls' fixed thresholds, right-stick.md section 11) and the right thumb's law (right-thumb.md) ----
var RS = { deadZone: 0.25, on: 0.60, off: 0.35, rest: 0.2, flickRise: 3, flickSettle: 2, holdTicks: 10 };
// L: a stick move holds the face buttons back; R: a face press holds the stick back (the thumb's 6 plus the settle's 2);
// W: how long a waiting input is kept; the left hand's moves from v2 (the slip, the read now called the brace) and the vanish
var LAW = { L: 6, R: 8, W: 36, qMax: 3, slipT: 12, braceT: 90, braceKi: 3, vanishKi: 12, dodgeWin: 4 };
// the pitch's numbers (EP, 2026-10-28) until Game Design rules them. 1 bh = 56 px
var MOVE = { flight: 2.6, sprint: 1.8, chargeMove: 0.5, guardMove: 0.6, strike: 58 / 75, reach: 0.6, rushBh: 0.9 };
var BTN = { X: { name: 'LIGHT', wind: 3, rec: 8, dmg: 4, reel: 8, kb: 0.3 }, Y: { name: 'MEDIUM', wind: 8, rec: 12, dmg: 8, reel: 12, kb: 1 },
  B: { name: 'HEAVY', wind: 14, rec: 16, dmg: 14, reel: 18, kb: 3 }, A: { name: 'GRAB', wind: 6, rec: 14, dmg: 10 } };
// hold through the wind-up to charge: level 1 at once, 2 after 22 ticks, 3 after 44; let go to throw it (80 at most)
var CHG = { lv2: 22, lv3: 44, max: 80, mul: [1, 1.35, 1.7, 2.2] };
var HEAVY_PACE = 24;
// the three pitches: a stick strike's wind-up and recovery, its ki, which pace it shares (its own, or the heavy's), its stun,
// and where the signature lives (RT + B, or RT + the stick)
var PITCH = {
  '4a': { tag: '4A', name: 'STRIKES: OWN CLASS', wind: 6, rec: 12, ki: 0, pool: 'stick', pace: 12, stun: 18, sig: 'B' },
  '4b': { tag: '4B', name: 'STRIKES: THE HEAVY', wind: 14, rec: 16, ki: 0, pool: 'heavy', pace: HEAVY_PACE, stun: 0, sig: 'B' },
  '4c': { tag: '4C', name: 'THE BIG MOVE OF A MODE', wind: 6, rec: 16, ki: 6, pool: 'heavy', pace: HEAVY_PACE, stun: 14, sig: 'stick' } };
var EN = { boltGap: 6, lobPace: 12, blastPace: 24, snapT: 12, holdT: 8, chanKi: 0.25, beamLv: 24, sigKi: 45, sigT: 50, lobT: 36, sweep: 32 };
var SPARK = { core: '#ffffff', main: '#f4efe3', edge: '#8a857a' };

function hash(n) { n = (n ^ 61) ^ (n >>> 16); n = (n + (n << 3)) | 0; n ^= n >>> 4; n = Math.imul(n, 0x27d4eb2d); n ^= n >>> 15; return (n >>> 0) / 4294967296; }
function ease(x) { return x < 0 ? 0 : x > 1 ? 1 : 1 - (1 - x) * (1 - x); }
function easeIO(x) { return x < 0 ? 0 : x > 1 ? 1 : x < 0.5 ? 2 * x * x : 1 - 2 * (1 - x) * (1 - x); }
function lerp(a, b, k) { return a + (b - a) * k; }
function clamp(v, a, b) { return v < a ? a : v > b ? b : v; }
function angN(a) { while (a > Math.PI) a -= 2 * Math.PI; while (a < -Math.PI) a += 2 * Math.PI; return a; }
function deg(d) { return d * Math.PI / 180; }
function sy(alt) { return GY - alt; }

// ---- the readers: one quantised sample a tick ----
function mkReader() { return { on: false, lastRest: -99, crossT: -99, flickDone: true, peak: null, fam: null, gid: 0, trace: [], log: [], dpOn: false, dpGid: 0 }; }
function quant(x, y) {
  var m = Math.sqrt(x * x + y * y); if (m < RS.deadZone) return { x: 0, y: 0, m: 0 };
  var r = Math.round(Math.min(1, (m - RS.deadZone) / (1 - RS.deadZone)) * 16) / 16; return { x: x / m * r, y: y / m * r, m: r };
}
// four ways on the screen, a tie to the vertical; y is the screen's (down positive); angles 32 ways, 90 is up
function dir4(x, y) { return Math.abs(y) >= Math.abs(x) ? (y < 0 ? 'up' : 'down') : (x > 0 ? 'right' : 'left'); }
function angOf(x, y) { var a = Math.atan2(-y, x) * 180 / Math.PI; if (a < 0) a += 360; return Math.round(a / 11.25) % 32 * 11.25; }
// a stick: every gesture is read 2 ticks after it crosses (Controls' settle), quick or slow; one let go sooner still acts on
// that tick; a release ends it. The family (what the shoulders picked) is locked at its first deflection
function readOne(rd, t, x, y, famNow) {
  var q = quant(x, y), out = { flick: null, release: false, fam: null, ffam: null, q: q };
  rd.trace.push([x, y]); if (rd.trace.length > 44) rd.trace.shift();
  if (rd.stFl && t >= rd.stFl.at) { out.flick = rd.stFl.d; out.fang = rd.stFl.a; out.ffam = rd.stFl.fam; out.gid = rd.stFl.gid; rd.stFl = null; }
  if (q.m > RS.rest && rd.fam == null) rd.fam = famNow;
  out.fam = rd.fam;
  if (q.m <= RS.rest) rd.lastRest = t;
  if (!rd.on && q.m >= RS.on) { rd.on = true; rd.crossT = t; rd.gid++; rd.flickDone = false; rd.peak = q; rd.quick = t - rd.lastRest <= RS.flickRise; }
  else if (rd.on && q.m < RS.off) {
    if (!rd.flickDone) { var fl = { d: dir4(rd.peak.x, rd.peak.y), a: angOf(rd.peak.x, rd.peak.y), fam: rd.fam, at: rd.crossT + RS.flickSettle, gid: rd.gid }; if (t >= fl.at) { out.flick = fl.d; out.fang = fl.a; out.ffam = fl.fam; out.gid = fl.gid; } else rd.stFl = fl; rd.flickDone = true; }
    rd.on = false; out.release = true; out.rgid = rd.gid;
  }
  if (rd.on) {
    if (q.m >= rd.peak.m) rd.peak = q;
    if (!rd.flickDone && t - rd.crossT >= RS.flickSettle) { out.flick = dir4(q.x, q.y); out.fang = angOf(q.x, q.y); out.ffam = rd.fam; out.gid = rd.gid; rd.flickDone = true; }
    rd.cur = { x: q.x, y: q.y, ang: angOf(q.x, q.y) };
  }
  if (!rd.on && q.m <= RS.rest) rd.fam = null;
  return out;
}
// the right stick's D-pad mirror (right-thumb.md rule 4): a tap acts 2 ticks after its onset, on the stick's tick
function readPad(rd, t, dx, dy, famNow) {
  var out = { flick: null, release: false, fam: null, ffam: null }, on = !!(dx || dy);
  if (rd.dpFl && t >= rd.dpFl.at) { out.flick = rd.dpFl.d; out.fang = rd.dpFl.a; out.ffam = rd.dpFl.fam; out.gid = rd.dpFl.gid; rd.dpFl = null; }
  if (on && !rd.dpOn) { rd.dpOn = true; rd.dpT = t; rd.dpGid++; rd.dpFam = famNow; rd.dpFl = { d: dir4(dx, dy), a: angOf(dx, dy), fam: famNow, at: t + RS.flickSettle, gid: rd.dpGid }; }
  out.fam = rd.dpFam;
  if (on) rd.dpCur = { ang: angOf(dx, dy) };
  if (!on && rd.dpOn) { rd.dpOn = false; out.release = true; out.rgid = rd.dpGid; rd.dpFam = null; }
  rd.dpVec = [dx, dy]; return out;
}
// the right stick and its mirror side by side, one flick a tick (the stick's first); each event keeps its source
function readRight(rd, t, x, y, famNow, dp) {
  var r = readOne(rd, t, x, y, famNow), d = readPad(rd, t, dp ? dp.x : 0, dp ? dp.y : 0, famNow), out = { flick: null, release: false, q: r.q };
  if (r.flick) { out.flick = r.flick; out.fang = r.fang; out.ffam = r.ffam; out.gid = r.gid; out.src = 'stick'; if (d.flick) rd.dpFl = { d: d.flick, a: d.fang, fam: d.ffam, at: t + 1, gid: d.gid }; }
  else if (d.flick) { out.flick = d.flick; out.fang = d.fang; out.ffam = d.ffam; out.gid = d.gid; out.src = 'pad'; }
  if (r.release) { out.release = true; out.rsrc = 'stick'; out.rgid = r.rgid; } else if (d.release) { out.release = true; out.rsrc = 'pad'; out.rgid = d.rgid; }
  out.fam = r.fam || d.fam;
  return out;
}

// ---- the world ----
function mkF(def, x, alt) { return { def: def, x: x, y: alt, dir: 1, ki: 100, hp: 100, vx: 0, vy: 0, mv: null, seq: null, wait: 0, blow: null,
  beam: null, lean: 0, tilt: 0, reel: 0, stun: 0, down: 0, air: false, spiked: false, caught: 0, held: 0, dodgeT: 0, sway: null, slipT: 0, slipD: null, slipK: null,
  guard: false, brace: null, commit: 0, q: [], pend: null, faceT: null, stickT: null, pace: { heavy: -99, stick: -99, lob: -99, blast: -99 }, lastBolt: -99,
  dodgePend: null, tl: [], prev: {}, swayY: 0, flurry: null, grabLock: 0, settle: 0, home: [x, alt] }; }
function newWorld(clip, take, mode, lane2, pitch) {
  var T = clip ? clip.takes[take] : null;
  var w = { t: 0, mode: mode, clip: clip, pitch: pitch || '4c', P: mkF(FIGHTERS[0], 260, 0), V: mkF(FIGHTERS[1], 460, 0), shots: [], fx: [], grabs: [], marks: [],
    rd: mkReader(), rdL: mkReader(), seq: 0, sound: [], inp: {} };
  w.P.foe = w.V; w.V.foe = w.P;
  if (T) { if (T.pitch) w.pitch = T.pitch; var su = lane2 ? T.setup2 || T.setup : T.setup; if (su) su(w); }
  w.V.home = [w.V.x, w.V.y]; w.cam0 = (w.P.x + w.V.x) / 2;
  return w;
}
function note(w, text, dim) { w.rd.log.unshift({ t: w.t, text: text, dim: !!dim }); if (w.rd.log.length > 6) w.rd.log.pop(); }
function sound(w, k) { w.sound.push(k); }
function hand(f) { return [f.x + f.dir * 22, f.y + 40]; }
function chest(f) { return [f.x, f.y + 40]; }
function dist(a, b) { var dx = b.x - a.x, dy = b.y - a.y; return Math.sqrt(dx * dx + dy * dy); }
function bhOf(f) { return dist(f, f.foe) / BH; }
function burst(w, x, alt, r, dur, lc, n) { w.fx.push({ k: 'burst', x: x, y: alt, r: r, t: 0, dur: dur, lc: lc, n: n || 7, rot: hash(w.seq++) * 6.28 }); }
function chips(w, x, alt, n, col, sp, up) { for (var i = 0; i < n; i++) { var a = hash(w.seq++) * 6.283, v = (sp || 3) * (0.5 + hash(w.seq++)); w.fx.push({ k: 'chip', x: x, y: alt, vx: Math.cos(a) * v, vy: Math.abs(Math.sin(a)) * v * (up ? 1.4 : 0.6) + 1, s: 2 + hash(w.seq++) * 2.5, t: 0, dur: 14 + hash(w.seq++) * 12, col: col, rot: hash(w.seq++) * 6 }); } }
function overLake(x) { return x > LAKE.x0 && x < LAKE.x1; }
function bound(f) { f.y = clamp(f.y, 0, 250); var x0 = f.x; f.x = clamp(f.x, 18, AW - 18); if (f.x !== x0 && Math.abs(f.vx) > 2) f.vx = -f.vx * 0.3; }
// a direction on the screen, read relative to him
function rel(f, d4) { if (d4 === 'up' || d4 === 'down') return d4; return (d4 === 'right' ? 1 : -1) === (f.foe.x >= f.x ? 1 : -1) ? 'toward' : 'away'; }
var WORD = { toward: 'TOWARD', away: 'AWAY', up: 'UP', down: 'DOWN' };
// E3 (energy-overhaul.md) and ruling 14: an input that can't act flickers in his hand with the not-ready cue
function nack(w, f, text) { note(w, text, true); w.fx.push({ k: 'ack', f: f, t: 0, dur: 6 }); sound(w, 'nack'); return false; }

// ---- moves: tweens, and plans of moves then a blow ----
function spotAt(f, g) { var s2 = f.x <= f.foe.x ? -1 : 1; return [f.foe.x + s2 * g * BH, f.foe.y]; }
function tween(f, k, x1, y1, dur) { f.mv = { k: k, x0: f.x, y0: f.y, x1: x1, y1: y1, t: 0, dur: dur }; f.settle = 0; }
function plan(w, f, steps) { f.seq = steps; nextStep(w, f); }
function nextStep(w, f) {
  var st = f.seq && f.seq.shift(); if (!st) { f.seq = null; return; }
  if (st.k === 'move') { var to = st.to(); tween(f, st.kind, to[0], to[1], typeof st.dur === 'function' ? st.dur() : st.dur); f.mv.seq = true; }
  else if (st.k === 'blow') { f.blow = mkBlow(w, st.spec); if (!f.seq.length) f.seq = null; }
}
function mkBlow(w, spec) { var b = { t: 0, start: w.t }; for (var k in spec) b[k] = spec[k]; return b; }
// pillar 3: a move always closes the gap, a rush to striking distance and then the blow
function startBlow(w, f, spec) {
  f.tl.push({ t: w.t, k: 'P' });
  if (bhOf(f) > MOVE.strike + MOVE.reach) {
    plan(w, f, [{ k: 'move', kind: 'rush', to: function () { return spotAt(f, MOVE.strike); }, dur: function () { var sp = spotAt(f, MOVE.strike); return clamp(Math.ceil(dist(f, { x: sp[0], y: sp[1] }) / BH / MOVE.rushBh), 2, 16); } }, { k: 'blow', spec: spec }]);
  } else f.blow = mkBlow(w, spec);
}
function cancelOwn(w, f) { f.seq = null; f.wait = 0; f.blow = null; f.mv = null; if (f.pend) nack(w, f, 'FLICK DROPPED'); f.pend = null; }

// ---- the left hand: slips (LT), braces (LB) and the vanish (both), each LT/LB plus a left flick; LB alone guards ----
var SLIP = { neutral: 'THE DODGE', away: 'A BACK-STEP', toward: 'A SLIP IN', up: 'A SWAY UP', down: 'A DUCK' };
function slip(w, f, d4) {
  var k = d4 ? rel(f, d4) : 'neutral', sx = f.foe.x >= f.x ? 1 : -1;
  cancelOwn(w, f); f.dodgeT = LAW.slipT; f.slipK = SLIP[k]; f.slipD = k; f.slipT = 0; f.sway = null;
  if (k === 'neutral') tween(f, 'dodge', f.x - sx * 0.5 * BH, f.y, 10);
  else if (k === 'away') tween(f, 'dodge', f.x - sx * 1.1 * BH, f.y, 10);
  else if (k === 'toward') tween(f, 'dodge', f.x + sx * clamp(Math.abs(f.foe.x - f.x) - 0.5 * BH, 0, 1.1 * BH), f.y, 10);
  else { f.sway = k; f.vx = f.vy = 0; f.settle = 0; }
  note(w, 'LT' + (k === 'neutral' ? '' : ' + ' + WORD[k]) + ': ' + SLIP[k]);
}
var BRACEK = { up: 'heavy', down: 'flurry', toward: 'grab', away: 'shot' }, BRACEW = { heavy: 'HIS HEAVY', flurry: 'HIS FLURRY', grab: 'HIS GRAB', shot: 'HIS SHOT' };
function brace(w, f, d4) {
  if (f.ki < LAW.braceKi) return nack(w, f, 'NO KI FOR A BRACE');
  var k = BRACEK[rel(f, d4)]; f.ki -= LAW.braceKi; f.brace = { k: k, t0: w.t, until: w.t + LAW.braceT };
  note(w, 'BRACE: ' + BRACEW[k] + ' (3 KI)');
}
// a brace that meets his move plays it out: the slip, and he is left open (v2's read, moved to the left thumb)
function fireBrace(w, f, foe) {
  var k = f.brace.k, sx = foe.x >= f.x ? 1 : -1; f.brace = null; f.dodgeT = 10; cancelOwn(w, f); f.vx = f.vy = 0;
  if (k === 'heavy') { f.sway = 'down'; f.slipT = 0; foe.reel = 16; foe.blow = null; note(w, 'BRACE: UNDER HIS HEAVY'); note(w, 'HE IS OPEN', true); }
  else if (k === 'flurry') { f.sway = 'down'; f.slipT = 0; foe.flurry = null; foe.blow = null; foe.reel = 10; note(w, 'BRACE: DUCKS HIS FLURRY'); note(w, 'HIS RUN IS BROKEN', true); }
  else if (k === 'grab') { f.vx = -sx * 6; f.settle = 8; foe.vx = sx * 6; foe.grabLock = 90; var cg = chest(f); burst(w, cg[0], cg[1], 14, 8, foe.def.L.trap, 6); note(w, 'BRACE: HIS GRAB BREAKS'); }
  else { tween(f, 'dodge', f.x, f.y + 0.9 * BH, 8); note(w, 'BRACE: SLIPS HIS SHOT'); }
  sound(w, 'read');
}
// the vanish: a blink in the flick's way for ki, through to his back on a flick toward him
function vanish(w, f, d4) {
  if (f.ki < LAW.vanishKi) return nack(w, f, 'VANISH: NO KI');
  var k = rel(f, d4), foe = f.foe, sx = foe.x >= f.x ? 1 : -1, tx = f.x, ty = f.y;
  if (k === 'away') tx = f.x - sx * 3 * BH; else if (k === 'toward') tx = foe.x + sx * 0.9 * BH; else if (k === 'up') ty = f.y + 1.6 * BH; else ty = f.y - 1.6 * BH;
  w.fx.push({ k: 'after', x: f.x, y: f.y, dir: f.dir, t: 0, dur: 8 });
  cancelOwn(w, f); f.ki -= LAW.vanishKi; f.dodgeT = 10; f.slipK = 'THE VANISH'; f.slipD = null; f.sway = null;
  tween(f, 'vanish', clamp(tx, 18, AW - 18), clamp(ty, 0, 250), 3); sound(w, 'vanish');
  note(w, 'VANISH ' + WORD[k] + ' (' + LAW.vanishKi + ' KI)');
}
function leftHand(w, f, inp, evL) {
  var lt = !!inp.LT, lb = !!inp.LB, p = f.prev;
  // LT with the stick already out slips that way at once; with it at rest, a flick within 4 ticks picks the way, else the dodge
  if (lt && !p.LT && !lb) { var lm = Math.sqrt((inp.lx || 0) * (inp.lx || 0) + (inp.ly || 0) * (inp.ly || 0)); if (lm > 0.5 && !w.rdL.on) slip(w, f, dir4(inp.lx, inp.ly)); else if (lm <= 0.5) f.dodgePend = w.t + LAW.dodgeWin; }
  if (evL && evL.flick && (lt || lb)) {
    if (lt && lb) { f.dodgePend = null; vanish(w, f, evL.flick); }
    else if (lt) { f.dodgePend = null; slip(w, f, evL.flick); }
    else brace(w, f, evL.flick);
  } else if (f.dodgePend != null && w.t >= f.dodgePend) { f.dodgePend = null; slip(w, f, null); }
  f.guard = lb && !lt && !f.blow && !f.seq && !(f.beam && !f.beam.end) && f.dodgeT === 0;
}

// ---- the right hand: the face buttons queue behind the stick's commitment, the stick waits out a press's R ----
var QN = { X: 'X', Y: 'Y', B: 'B', A: 'A', BOLT: 'X', LOB: 'Y', BLAST: 'B', SIG: 'RT+B' };
function busy(f) { return f.commit > 0 || !!f.seq || !!f.blow || f.dodgeT > 0 || !!(f.beam && !f.beam.end) || f.held > 0; }
function stickBusy(f) { return !!f.seq || !!f.blow || f.dodgeT > 0 || !!(f.beam && !f.beam.end) || f.held > 0; }
// the tick a press's thumb counts from: its press, raised to the stick's release or act + L when the stick was out then
function qEff(w, f, e) { return Math.max(e.t, e.on ? (f.stickT != null && f.stickT >= e.t ? f.stickT + LAW.L : w.t) : (e.st != null ? e.st + LAW.L : -99)); }
function thumbT(w, f, inp) {
  var t = f.faceT == null ? -99 : f.faceT;
  if (inp.B && f.blow && f.blow.kind === 'B' && f.blow.armed !== false) t = Math.max(t, w.t);     // the thumb is on B while it charges
  f.q.forEach(function (e) { if (!e.on || (f.stickT != null && f.stickT >= e.t)) t = Math.max(t, qEff(w, f, e)); });
  return t;
}
function dropPend(w, f, t) { if (f.pend && f.pend.t < t) { f.pend = null; nack(w, f, 'FLICK DROPPED'); } }
function facePress(w, f, k, inp) {
  dropPend(w, f, w.t);
  if (busy(f) || f.q.length) { if (f.q.length < LAW.qMax) { f.q.push({ k: k, t: w.t, on: !!w.rd.on, st: f.stickT }); note(w, QN[k] + ' QUEUED'); } else nack(w, f, 'QUEUE FULL'); return; }
  doPress(w, f, k, inp, null);
}
function doPress(w, f, k, inp, ent) {
  var did = startPress(w, f, k, inp);
  if (did) f.faceT = Math.max(f.faceT == null ? -99 : f.faceT, ent ? qEff(w, f, ent) : w.t);
  return did;
}
function startPress(w, f, k, inp) {
  if (k === 'X' || k === 'Y' || k === 'A') { startBlow(w, f, { kind: k, wind: BTN[k].wind, rec: BTN[k].rec }); note(w, k + ': ' + BTN[k].name); return true; }
  if (k === 'B') {
    if (w.t - f.pace.heavy < HEAVY_PACE) return nack(w, f, 'HEAVY: NOT READY');
    f.pace.heavy = w.t; startBlow(w, f, { kind: 'B', wind: BTN.B.wind, rec: BTN.B.rec, armed: true }); note(w, 'B: HEAVY'); return true;
  }
  if (!inp.RB && k !== 'SIG') return false;
  if (k === 'BOLT') { if (w.t - f.lastBolt < EN.boltGap) return nack(w, f, 'X: NOT READY'); f.lastBolt = w.t; fire(w, f, 'bolt'); return true; }
  if (k === 'LOB') { if (w.t - f.pace.lob < EN.lobPace) return nack(w, f, 'Y: NOT READY'); f.pace.lob = w.t; fire(w, f, 'lob'); return true; }
  if (k === 'BLAST') { if (w.t - f.pace.blast < EN.blastPace) return nack(w, f, 'B: NOT READY'); f.pace.blast = w.t; fire(w, f, 'blast'); return true; }
  if (k === 'SIG') { if (!inp.RT) return false; if (f.ki < EN.sigKi) return nack(w, f, 'SIGNATURE: NO KI'); startBeam(w, f, { a: aimDeg(f), src: 'btn' }, true); return true; }
  return false;
}
// a stick move, by the family its gesture locked: martial a strike, energy (RB) a beam, power (RT) the signature in 4c
function famOf(inp) { return inp.RT ? 'power' : inp.RB ? 'energy' : 'martial'; }
var STRIKEW = { toward: 'BODY BLOW', up: 'RISING STRIKE', down: 'SWEEP', away: 'TURNING BLOW' };
// down is a spike on him in the air, a sweep on the ground
function strikeW(f, dir) { return dir === 'down' && f.foe.y > 8 ? 'SPIKE' : STRIKEW[dir]; }
function stickAct(w, f, pd) {
  f.stickT = w.t; f.commit = Math.max(f.commit, LAW.L); f.tl.push({ t: w.t, k: 'F' });
  if (pd.fam === 'energy') return startBeam(w, f, pd, false);
  if (pd.fam === 'power') { if (w.pitch === '4c') { if (f.ki < EN.sigKi) return nack(w, f, 'SIGNATURE: NO KI'); return startBeam(w, f, pd, true); } return nack(w, f, 'SIGNATURE IS RT + B'); }
  var P = PITCH[w.pitch], dir = rel(f, pd.d);
  if (w.t - f.pace[P.pool] < P.pace) return nack(w, f, P.pool === 'heavy' ? 'HEAVY: NOT READY' : 'STRIKE: NOT READY');
  if (f.ki < P.ki) return nack(w, f, 'STRIKE: NO KI');
  f.ki -= P.ki; f.pace[P.pool] = w.t;
  note(w, 'STICK ' + WORD[dir] + (w.pitch === '4b' ? ': HEAVY' : ': ' + strikeW(f, dir)).slice(0, 24 - 6 - WORD[dir].length));
  startBlow(w, f, { kind: 'S', dir: dir, wind: P.wind, rec: P.rec, gid: pd.gid, src: pd.src, armed: true });
  return true;
}
function rightStick(w, f, inp, ev) {
  var lock = thumbT(w, f, inp) + LAW.R;
  // a stick input waits out a press's R (rule 3) and a move still running; the newest wins, and a replaced one flickers
  if (ev.flick) { if (f.pend) nack(w, f, 'FLICK REPLACED'); f.pend = { d: ev.flick, a: ev.fang, fam: ev.ffam, src: ev.src, gid: ev.gid, t: w.t }; }
  // and a press still waiting from before the flick goes first: the older input starts first
  var older = f.pend && f.q.some(function (e) { return e.t < f.pend.t; });
  if (f.pend && w.t >= lock && !stickBusy(f) && !older) { var pd = f.pend; f.pend = null; stickAct(w, f, pd); }
  else if (f.pend && w.t - f.pend.t > LAW.W) { f.pend = null; nack(w, f, 'FLICK LAPSES'); }
  if (ev.release) {
    if (ev.rsrc === 'stick') f.stickT = Math.max(f.stickT == null ? -99 : f.stickT, w.t);
    f.tl.push({ t: w.t, k: 'R' });
    if (f.beam && f.beam.chan && f.beam.gid === ev.rgid && f.beam.src === ev.rsrc) { f.beam.chan = false; f.beam.dur = Math.min(f.beam.dur, f.beam.t + 6); f.commit = Math.max(f.commit, LAW.L); note(w, 'RELEASE: THE BEAM ENDS'); }
  }
}
// still out: the same gesture the strike or beam came from, still held
function stillOut(w, b) { return b.src === 'pad' ? w.rd.dpOn && w.rd.dpGid === b.gid : b.src === 'stick' ? w.rd.on && w.rd.gid === b.gid : false; }
function stickAng(w, b) { return b.src === 'pad' ? (w.rd.dpCur ? w.rd.dpCur.ang : null) : (w.rd.cur ? w.rd.cur.ang : null); }

// ---- blows: the wind-up, the contact, the recovery; held through the wind-up, a heavy or a stick strike charges ----
function blowStep(w, f) {
  var b = f.blow; if (!b) return;
  if (b.charging) {
    var still = b.kind === 'B' ? !!w.inp.B : stillOut(w, b); b.ct++;
    var lv = b.ct >= CHG.lv3 ? 3 : b.ct >= CHG.lv2 ? 2 : 1; if (lv !== b.lv) { b.lv = lv; sound(w, 'click'); }
    if (!still || b.ct >= CHG.max) { b.charging = false; b.armed = false; b.t = b.wind - 1; note(w, 'LET GO: LEVEL ' + b.lv); if (b.kind === 'S') { f.stickT = w.t; f.commit = Math.max(f.commit, LAW.L); } }
    return;
  }
  b.t++;
  if (b.t === b.wind) {
    if (b.armed && (b.kind === 'B' ? !!w.inp.B : stillOut(w, b))) { b.charging = true; b.ct = 0; b.lv = 1; b.t = b.wind - 1; note(w, 'HELD: CHARGING'); return; }
    contact(w, f, b);
  }
  if (b.t >= b.wind + b.rec) { f.blow = null; if (f.seq) nextStep(w, f); }
}
function hitSpec(w, b) {
  var m = CHG.mul[b.lv || 0], P = PITCH[w.pitch];
  if (b.kind === 'X' || b.kind === 'Y' || b.kind === 'B') { var B = BTN[b.kind]; return { dmg: B.dmg * m, reel: B.reel, kb: B.kb * m, name: B.name + (b.lv ? ' L' + b.lv : '') }; }
  // 4b: the stick is the heavy's own direction, with the heavy's numbers and no stun
  if (w.pitch === '4b') return { toward: { dmg: 14 * m, reel: 18, kb: 3 * m }, up: { dmg: 14 * m, reel: 18, launch: 5 + 2 * m }, down: { dmg: 14 * m, reel: 18, spike: true }, away: { dmg: 14 * m, reel: 18, kb: 3.5 * m } }[b.dir];
  var st = P.stun * m;
  return { toward: { dmg: 10 * m, reel: 10, stun: st, kb: 1.6 * m }, up: { dmg: 9 * m, reel: 8, stun: st / 2, launch: 5 + 2 * m }, down: { dmg: 9 * m, reel: 8, spike: true, stun: st / 2 }, away: { dmg: 11 * m, reel: 12, kb: 4.5 * m } }[b.dir];
}
function contact(w, f, b) {
  var foe = f.foe, d = bhOf(f), reach = MOVE.strike + MOVE.reach + (b.kind === 'S' || b.kind === 'B' || b.heavy ? 0.4 : 0);
  if (f === w.V) return rivalContact(w, f, b, d <= reach);
  if (d > reach) { note(w, 'WHIFF', true); return; }
  if (b.kind === 'A') {     // the grab: caught, then thrown away from him
    if (foe.caught || foe.air) { note(w, 'GRAB: NOTHING TO HOLD', true); return; }
    foe.caught = 30; f.held = 30; foe.blow = null; foe.flurry = null; note(w, 'A: CAUGHT'); return;
  }
  var s = hitSpec(w, b); s.name = s.name || (w.pitch === '4b' ? 'HEAVY ' + WORD[b.dir] : strikeW(f, b.dir)) + (b.lv ? ' L' + b.lv : '');
  applyHit(w, f, foe, s);
}
function applyHit(w, a, d, s) {
  var sx = d.x >= a.x ? 1 : -1, c0 = chest(a), c1 = chest(d), cl = dist({ x: c0[0], y: c0[1] }, { x: c1[0], y: c1[1] }) || 1;
  d.hp = Math.max(0, d.hp - s.dmg); d.reel = Math.max(d.reel, s.reel || 0); d.blow = null; d.flurry = null;
  if (s.stun) d.stun = Math.max(d.stun, Math.round(s.stun));
  if (s.kb) d.vx = sx * s.kb * BH * 0.12;
  if (s.launch) { d.vy = s.launch; d.air = true; d.vx = sx * 1.4; }
  if (s.spike) { if (d.y > 8) { d.vy = -11; d.air = true; d.spiked = true; } else { d.down = 26; d.vx = sx * 1.2; } }
  burst(w, c1[0] - (c1[0] - c0[0]) / cl * 12, c1[1] - (c1[1] - c0[1]) / cl * 12, 8 + s.dmg * 0.5, 8, SPARK, 6); sound(w, 'blow');
  var how = d.air && s.launch ? ': LAUNCHED' : d.spiked && s.spike ? ': SPIKED' : d.down && s.spike ? ': DOWN' : s.stun ? ': STUNNED' : s.kb >= 3 ? ': SENT BACK' : '';
  note(w, s.name + ((s.name + how).length <= 24 ? how : ''));
  if (d.hp <= 0) { d.hp = 100; note(w, 'THE DUMMY RESETS', true); }
}
// his blows on you: out of reach a whiff; a slip or the vanish slips it, a brace plays out, the guard holds
function rivalContact(w, v, b, inReach) {
  var P = v.foe; if (!inReach) { note(w, b.heavy ? 'HIS HEAVY WHIFFS' : 'HIS BLOW WHIFFS', true); return; }
  if (P.dodgeT > 0) { note(w, 'HE MISSES: ' + (P.slipK || 'SLIPPED')); return; }
  if (P.brace && P.brace.k === (b.heavy ? 'heavy' : b.fl ? 'flurry' : '') && b.start >= P.brace.t0) return fireBrace(w, P, v);
  var sx = P.x >= v.x ? 1 : -1;
  if (P.guard) { P.reel = 4; P.vx = sx * (b.heavy ? 3 : 1.5); P.settle = 6; burst(w, P.x + -sx * 8, P.y + 44, 7, 6, SPARK, 4); note(w, b.heavy ? 'GUARDED: HIS HEAVY' : 'GUARDED'); sound(w, 'guard'); return; }
  cancelOwn(w, P); P.reel = b.heavy ? 18 : 10; P.vx = sx * (b.heavy ? 5 : 2); P.settle = 8;
  var c1 = chest(P); burst(w, c1[0] - sx * 10, c1[1], 10, 7, SPARK, 5); sound(w, 'blow'); note(w, b.heavy ? 'HIS HEAVY LANDS' : 'HIS BLOW LANDS');
}

// ---- energy: blasts on the buttons (RB), beams on the stick (RB) and the signature (RT) ----
function aimDeg(f) { var h = hand(f), c = chest(f.foe); var a = Math.atan2(c[1] - h[1], c[0] - h[0]) * 180 / Math.PI; return a < 0 ? a + 360 : a; }
function fire(w, f, k) {
  var a = deg(aimDeg(f)), h = hand(f), L = f.def.L;
  if (k === 'bolt') w.shots.push({ k: 'bolt', o: f, x: h[0], y: h[1], vx: Math.cos(a) * 11, vy: Math.sin(a) * 11, sp: 11, t: 0, s: 6, born: w.t });
  else if (k === 'blast') w.shots.push({ k: 'blast', o: f, x: h[0], y: h[1], vx: Math.cos(a) * 8, vy: Math.sin(a) * 8, sp: 8, t: 0, s: 14, born: w.t });
  else { var d = dist(f, f.foe), tx = h[0] + Math.cos(a) * d, ty = Math.max(0, h[1] + Math.sin(a) * d), T = EN.lobT, g = 0.4; w.shots.push({ k: 'lob', o: f, x: h[0], y: h[1], vx: (tx - h[0]) / T, vy: ((ty - h[1]) + 0.5 * g * T * T) / T, g: g, t: 0, s: 9, born: w.t }); }
  note(w, { bolt: 'X: BOLT', lob: 'Y: LOB', blast: 'B: BLAST' }[k]); f.lean = 8; sound(w, 'bolt');
}
function inBody(f, x, alt, pad) { return Math.abs(x - f.x) < 12 + pad && alt > f.y - pad && alt < f.y + BH + pad; }
function shotsStep(w) {
  for (var i = w.shots.length - 1; i >= 0; i--) {
    var s = w.shots[i], foe = s.o.foe; s.t++;
    s.x += s.vx; s.y += s.vy; if (s.g) s.vy -= s.g;
    if (!s.slipped && inBody(foe, s.x, s.y, s.k === 'blast' ? 8 : 2)) {
      if (foe === w.P) {
        if (foe.brace && foe.brace.k === 'shot' && s.born >= foe.brace.t0) { fireBrace(w, foe, s.o); s.slipped = true; continue; }
        if (foe.dodgeT > 0) { s.slipped = true; note(w, 'SLIPPED A SHOT', true); continue; }
        if (foe.guard) { burst(w, s.x, s.y, 9, 6, s.o.def.L.bolt, 5); note(w, 'GUARDED: A SHOT'); w.shots.splice(i, 1); continue; }
        burst(w, s.x, s.y, 10, 7, s.o.def.L.bolt, 6); foe.reel = 8; note(w, 'HIS SHOT LANDS'); w.shots.splice(i, 1); continue;
      }
      var hs = { bolt: { dmg: 3, reel: 6, name: 'BOLT' }, lob: { dmg: 8, reel: 14, kb: 1, name: 'LOB' }, blast: { dmg: 12, reel: 16, kb: 2.5, name: 'BLAST' } }[s.k];
      burst(w, s.x, s.y, s.k === 'blast' ? 26 : 11, s.k === 'blast' ? 12 : 7, s.k === 'bolt' ? s.o.def.L.bolt : s.o.def.L.lob, 6); applyHit(w, s.o, foe, hs); w.shots.splice(i, 1); continue;
    }
    if (s.y <= 1 && (s.k !== 'bolt' || s.vy < 0)) { burst(w, s.x, 2, s.k === 'bolt' ? 9 : 22, s.k === 'bolt' ? 6 : 12, s.k === 'bolt' ? s.o.def.L.bolt : s.o.def.L.lob, 7); if (s.k !== 'bolt' && !overLake(s.x)) w.marks.push({ k: 'crater', x: s.x, w: 26 }); w.shots.splice(i, 1); continue; }
    if (s.x < -60 || s.x > AW + 40 || s.y > H + 60 || s.t > 200) w.shots.splice(i, 1);
  }
}
// every beam starts as a snap-beam; still held 8 ticks in, it channels (it stays out, turns toward the stick at his sweep
// rate and grows a level every 24 ticks, for ki). The gesture decides, not when the release falls against the act, so the
// claw and one thumb get the same beam. RT's signature is the widest, costs 45 ki, runs its length and is steered while held
function startBeam(w, f, pd, sig) {
  f.beam = { a: deg(pd.a), len: 0, t: 0, dur: sig ? EN.sigT : EN.snapT, end: 0, lv: sig ? 3 : 0, sig: sig, chan: false, src: pd.src, gid: pd.gid };
  if (sig) f.ki -= EN.sigKi;
  note(w, sig ? 'SIGNATURE (45 KI)' : 'STICK: SNAP-BEAM'); sound(w, 'beam'); return true;
}
function beamStep(w, f) {
  var b = f.beam; if (!b) return;
  if (b.end) { b.end++; if (b.end > 9) f.beam = null; return; }
  b.t++;
  if (!b.sig && b.t === EN.holdT && stillOut(w, b)) { b.chan = true; note(w, 'HELD: THE BEAM CHANNELS'); }
  if (b.sig && stillOut(w, b)) { var sa0 = stickAng(w, b); if (sa0 != null) b.a += clamp(angN(deg(sa0) - b.a), -deg(EN.sweep / 60) * 0.6, deg(EN.sweep / 60) * 0.6); }
  if (b.chan) {
    if (!b.sig) { if (b.t % EN.beamLv === 0 && b.lv < 3) { b.lv++; sound(w, 'click'); note(w, 'BEAM LEVEL ' + b.lv, true); } f.ki = Math.max(0, f.ki - EN.chanKi); if (f.ki <= 0) { b.chan = false; note(w, 'BEAM: OUT OF KI'); } }
    b.dur = Math.max(b.dur, b.t + 2);
    var sa = stickAng(w, b); if (sa != null) { var da = angN(deg(sa) - b.a), mx = deg(EN.sweep / 60) * (b.sig ? 0.6 : 1); b.a += clamp(da, -mx, mx); }
  }
  var h = hand(f), dx = Math.cos(b.a), dy = Math.sin(b.a), foe = f.foe, reach = 900;
  var fx = foe.x - h[0], fy = foe.y + 30 - h[1], along = fx * dx + fy * dy, off = Math.abs(fx * dy - fy * dx), half = beamW(f, b) / 2;
  var inLine = along > 0 && off < half + 12;
  for (var s = 0; s < 900; s += 6) { var x = h[0] + dx * s, yy = h[1] + dy * s; if (yy <= 0 || x < 0 || x > AW || yy > 330) { reach = Math.min(reach, s); break; } }
  if (inLine) reach = Math.min(reach, along);
  b.len = Math.min(b.len + 40, reach);
  if (inLine && b.len >= along - 1) {
    foe.reel = Math.max(foe.reel, 6); if (b.t % 6 === 1) { foe.hp = Math.max(0, foe.hp - (b.sig ? 4 : 1 + b.lv)); if (foe.hp <= 0) { foe.hp = 100; note(w, 'THE DUMMY RESETS', true); } }
    if (b.sig || b.lv >= 2) { foe.x += dx * (b.sig ? 3 : 1.6); foe.y = Math.max(0, foe.y + dy * (b.sig ? 3 : 1.6)); bound(foe); }
    if (w.t % 5 === 0) chips(w, h[0] + dx * b.len, h[1] + dy * b.len, 1, (b.sig ? f.def.L.sig : f.def.L.beam).core, 3);
  }
  var ex = h[0] + dx * b.len, ey = h[1] + dy * b.len;
  if (ey <= 4 && b.len < 880) { var key = Math.round(ex / 12); if (!overLake(ex) && !w.marks.some(function (m) { return m.k === 'trench' && m.key === key; })) w.marks.push({ k: 'trench', key: key, x: key * 12, d: 3 + 2 * Math.max(1, b.lv) }); if (w.t % 2 === 0) chips(w, ex, 2, 1, overLake(ex) ? C.lakeLite : C.dirt, 3, true); }
  if (b.t >= b.dur) { b.end = 1; f.commit = Math.max(f.commit, LAW.L); }
}
function beamW(f, b) { return (b.sig ? 34 : b.lv === 0 ? 8 : 10 + 6 * b.lv) * f.def.bw; }

// ---- the Protagonist's tick ----
function fighterStep(w, f, inp, ev, evL) {
  var p = f.prev, pr = function (k) { return inp[k] && !p[k]; };
  f.reel = Math.max(0, f.reel - 1); f.lean *= 0.8; if (f.commit > 0) f.commit--; f.dodgeT = Math.max(0, f.dodgeT - 1);
  if (!(f.beam && !f.beam.end) && !(f.blow && f.blow.charging)) f.ki = Math.min(100, f.ki + 6 / 60);
  if (f.sway) { f.slipT++; if (f.slipT >= LAW.slipT + 2) { f.sway = null; f.slipT = 0; } }
  if (f.brace && w.t >= f.brace.until) { f.brace = null; note(w, 'THE BRACE LAPSES', true); }
  if (!f.mv && !f.blow && !f.held) f.dir = f.foe.x >= f.x ? 1 : -1;
  // a waiting press is kept W ticks; one no longer possible (its shoulder let go) is dropped, each with a flicker
  if (f.q.length) { var live = f.q.filter(function (e) { return w.t - e.t <= LAW.W && (/^(X|Y|B|A)$/.test(e.k) || (e.k === 'SIG' ? inp.RT : inp.RB)); }); for (var lq = live.length; lq < f.q.length; lq++) nack(w, f, 'A WAITING PRESS LAPSES'); f.q = live; }
  if (f.caught > 0) { f.caught--; if (pr('X') || pr('Y') || pr('B') || pr('A') || (ev && ev.flick)) nack(w, f, 'CAUGHT: NOT READY'); f.prev = { RB: inp.RB, LB: inp.LB, LT: inp.LT, RT: inp.RT, X: inp.X, Y: inp.Y, B: inp.B, A: inp.A }; return; }
  if (inp.X && !p.X || inp.Y && !p.Y || inp.B && !p.B || inp.A && !p.A) f.tl.push({ t: w.t, k: 'X' });
  leftHand(w, f, inp, evL);
  rightStick(w, f, inp, ev);
  // the face buttons: RT holds the power layer, RB the energy layer, else the martial moves
  if (inp.RT) {
    if (pr('B')) { if (w.pitch === '4c') nack(w, f, 'RT+B: A 4TH SPECIAL'); else facePress(w, f, 'SIG', inp); }
    if (pr('X') || pr('Y') || pr('A')) nack(w, f, 'SPECIALS: NOT HERE');
  } else if (inp.RB) {
    if (pr('X')) facePress(w, f, 'BOLT', inp); if (pr('Y')) facePress(w, f, 'LOB', inp); if (pr('B')) facePress(w, f, 'BLAST', inp); if (pr('A')) nack(w, f, 'A: NOT IN ENERGY');
  } else { ['X', 'Y', 'B', 'A'].forEach(function (k) { if (pr(k)) facePress(w, f, k, inp); }); }
  if (f.q.length && !busy(f)) { var qq = f.q.shift(); if (doPress(w, f, qq.k, inp, qq)) note(w, 'QUEUED ' + QN[qq.k] + ' STARTS'); else nack(w, f, 'QUEUED ' + QN[qq.k] + ' DROPPED'); }
  // motion: a tween (a rush, a slip, the vanish), else flight on the left stick (rooted by a blow or a beam)
  if (f.sway === 'up') { var sk = Math.sin(Math.PI * Math.min(1, f.slipT / LAW.slipT)); f.swayY = sk * 0.9 * BH; } else f.swayY = 0;
  if (f.mv) { var m = f.mv; m.t++; var k = m.k === 'rush' ? clamp(m.t / m.dur, 0, 1) : easeIO(m.t / m.dur), ox = f.x, oy = f.y; f.x = lerp(m.x0, m.x1, k); f.y = lerp(m.y0, m.y1, k); f.vx = f.x - ox; f.vy = f.y - oy; f.lean = m.k === 'rush' ? 18 : 0; if (m.t >= m.dur) { f.mv = null; f.vx = f.vy = 0; if (m.seq) nextStep(w, f); } }
  else {
    var rooted = (f.blow && !f.blow.charging) || (f.beam && !f.beam.end) || f.held > 0 || f.dodgeT > 0;
    var sp = MOVE.flight * (inp.LT && !inp.LB ? MOVE.sprint : 1) * (f.guard ? MOVE.guardMove : 1) * (f.blow && f.blow.charging ? MOVE.chargeMove : 1);
    if (!rooted && (inp.lx || inp.ly)) { f.vx = (inp.lx || 0) * sp; f.vy = -(inp.ly || 0) * sp; f.x += f.vx; f.y += f.vy; }
    else if (f.settle > 0) { f.settle--; f.vx *= 0.75; f.vy *= 0.75; f.x += f.vx; f.y += f.vy; }
    else { f.vx = 0; f.vy = 0; }
  }
  blowStep(w, f); beamStep(w, f);
  // holding him: then the throw, away from you
  if (f.held > 0) { f.held--; var hx = f.dir; f.foe.x = f.x + hx * 34; f.foe.y = f.y; if (f.held === 0) { applyHit(w, f, f.foe, { dmg: BTN.A.dmg, reel: 14, kb: 3.5, name: 'THE THROW' }); f.foe.caught = 0; } }
  bound(f);
  f.prev = { RB: inp.RB, LB: inp.LB, LT: inp.LT, RT: inp.RT, X: inp.X, Y: inp.Y, B: inp.B, A: inp.A };
}

// ---- the Rival: a stand-in with his own blows, heavy, flurry, grab and shots, who reels, is stunned, launched and knocked
// down; in Play he closes in and throws them in turn ----
function rivalStep(w, f, o) {
  f.dir = f.foe.x >= f.x ? 1 : -1; f.grabLock = Math.max(0, f.grabLock - 1);
  if (f.reel > 0) f.reel--; if (f.stun > 0) f.stun--; if (f.down > 0) f.down--;
  if (f.caught > 0) { if (!f.foe.held) f.caught--; return; }
  // knocked: flying, then the ground; on the ground he slides
  if (f.air) { f.x += f.vx; f.y += f.vy; f.vy -= 0.5; if (f.y <= 0) { f.y = 0; if (f.spiked) { f.spiked = false; f.down = 22; f.vy = 0; f.vx *= 0.4; burst(w, f.x, 2, 16, 9, SPARK, 6); chips(w, f.x, 2, 5, overLake(f.x) ? C.lakeLite : C.dirt, 3, true); } else if (f.vy < -6) { f.vy = -f.vy * 0.3; } else { f.vy = 0; f.air = false; } } }
  else if (Math.abs(f.vx) > 0.05) { f.x += f.vx; f.vx *= 0.88; } else f.vx = 0;
  var out = f.reel > 0 || f.stun > 0 || f.down > 0 || f.air;
  if (out) { f.blow = null; f.flurry = null; }
  else {
    if (w.mode === 'play') {
      var d = bhOf(f), ph = w.t % 360;
      if (d > 1.6) { var g = spotAt(f, 1.2); f.x += clamp(g[0] - f.x, -1.4, 1.4); f.y += clamp(g[1] - f.y, -1.4, 1.4); if (ph === 300 && d > 5) o.fire = true; }
      else if (!f.blow && !f.flurry) { if (ph === 40) o.blow = 'mid'; else if (ph === 100) o.blow = 'high'; else if (ph === 150) o.heavy = true; else if (ph === 220) o.blow = 'low'; else if (ph === 270) o.flurry = true; else if (ph === 330) o.grab = true; }
    }
    if (o.blow && !f.blow) f.blow = { t: 0, kind: 'V', h: o.blow === true ? 'mid' : o.blow, wind: 12, rec: 10, start: w.t };
    if (o.heavy && !f.blow) { f.blow = { t: 0, kind: 'V', heavy: true, h: 'mid', wind: 28, rec: 14, start: w.t }; note(w, 'HE WINDS A HEAVY', true); }
    if (o.flurry && !f.flurry) f.flurry = { n: 0, next: w.t, start: w.t };
    if (f.flurry && w.t >= f.flurry.next && !f.blow) { f.blow = { t: 0, kind: 'V', fl: true, h: 'mid', wind: 4, rec: 4, start: f.flurry.start }; f.flurry.n++; f.flurry.next = w.t + 8; if (f.flurry.n >= 4) f.flurry = null; }
    if (o.grab && !f.grabLock && !w.grabs.length) { var hg = hand(f); w.grabs.push({ o: f, x: hg[0], y: hg[1], t: 0, T: 24, born: w.t }); f.grabLock = 90; note(w, 'HE THROWS A GRAB', true); }
    if (o.gx != null || o.gy != null) { var gx = o.gx == null ? f.x : o.gx, gy = o.gy == null ? f.y : o.gy, dx = gx - f.x, dy = gy - f.y, l = Math.sqrt(dx * dx + dy * dy), sp = o.gs || 2.5; if (l > 1) { f.x += dx / l * Math.min(sp, l); f.y += dy / l * Math.min(sp, l); } }
    if (o.fire) { var h = hand(f), c = chest(f.foe), a = Math.atan2(c[1] - h[1], c[0] - h[0]), sp2 = o.fireSp || 7; w.shots.push({ k: 'bolt', o: f, x: h[0], y: h[1], vx: Math.cos(a) * sp2, vy: Math.sin(a) * sp2, sp: sp2, t: 0, s: 6, born: w.t }); }
  }
  blowStep(w, f);
  bound(f);
}
// his energy grab: a loop that closes on you in 24 ticks; a brace toward him breaks it as it closes
function grabsStep(w) {
  for (var i = w.grabs.length - 1; i >= 0; i--) {
    var g = w.grabs[i], f = g.o, foe = f.foe, c = chest(foe); g.t++;
    g.x = lerp(g.x, c[0], Math.min(1, 1 / Math.max(1, g.T - g.t + 1))); g.y = lerp(g.y, c[1], Math.min(1, 1 / Math.max(1, g.T - g.t + 1)));
    if (g.t >= g.T) {
      w.grabs.splice(i, 1);
      if (foe.brace && foe.brace.k === 'grab' && g.born >= foe.brace.t0) fireBrace(w, foe, f);
      else if (foe.dodgeT > 0) note(w, 'GRAB MISSES: ' + (foe.slipK || 'SLIPPED'));
      else { cancelOwn(w, foe); foe.beam = null; foe.caught = 40; burst(w, c[0], c[1], 14, 8, f.def.L.trap, 6); note(w, 'CAUGHT IN HIS GRAB'); }
    }
  }
}
function fxStep(w) { for (var i = w.fx.length - 1; i >= 0; i--) { var e = w.fx[i]; e.t++; if (e.k === 'chip') { e.x += e.vx; e.y += e.vy; e.vy -= 0.3; if (e.y < 0) { e.y = 0; e.vy *= -0.3; e.vx *= 0.6; } e.rot += 0.2; } if (e.t >= e.dur) w.fx.splice(i, 1); } }

// one tick of the world: P's input { lx, ly, rx, ry, LT, LB, RB, RT, X, Y, B, A, du, dd, dl, dr }, the Rival's orders
function stepWorld(w, ip) {
  var P = ip.P; w.inp = P; w.sound.length = 0;
  var dp = { x: (P.dr ? 1 : 0) - (P.dl ? 1 : 0), y: (P.dd ? 1 : 0) - (P.du ? 1 : 0) };
  var mag = Math.sqrt((P.rx || 0) * (P.rx || 0) + (P.ry || 0) * (P.ry || 0)), inNow = mag > RS.deadZone || dp.x || dp.y;
  if (inNow && !w.inWas) w.P.tl.push({ t: w.t, k: 'I' }); w.inWas = inNow;
  var ev = readRight(w.rd, w.t, P.rx || 0, P.ry || 0, famOf(P), dp), evL = readOne(w.rdL, w.t, P.lx || 0, P.ly || 0, 'left');
  fighterStep(w, w.P, P, ev, evL); rivalStep(w, w.V, ip.V || {});
  shotsStep(w); grabsStep(w); fxStep(w);
  [w.P, w.V].forEach(function (f) { if (f.tl.length > 64) f.tl.splice(0, f.tl.length - 64); }); if (w.marks.length > 60) w.marks.splice(0, w.marks.length - 60);
  w.t++;
}
