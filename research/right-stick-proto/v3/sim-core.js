// ==== HAND SIM (no DOM) ====
// Right hand attacks, v3: "the left hand survives, the right hand hurts" (docs/ep/right-hand-attacks-pitch.md, Orb's
// direction of 2026-10-28), built to Controls' spec (docs/controls/right-hand-attacks.md: section 1 the strike reader,
// section 3 the shoulders, section 4 the maps, section 6 the no-claw law K1 to K7) and Game Design's rulings
// (docs/design/right-hand-attacks-rulings.md). The left stick moves; LT, LB or both with a left flick slip, brace or vanish;
// LB alone guards. The face buttons are the quick moves. The right stick is a fifth button with a direction: crossing is a
// request 2 ticks later; back before D is the quick strike (level 0), still out at D is a charge, thrown on release; with RB
// held it is the beam, with RT in 4c the signature. The pitch switch: 4c (GD's split by gesture, the default), pure 4a and
// 4b. Every number is data at the top. No DOM: the page drives it and gif.mjs runs it in node. 60 ticks a second, no
// randomness (a hash for every jitter), flat polygons only.
var S = (function () {
'use strict';
var W = 1020, H = 340, AW = 720, GY = 300, BH = 56, KEY = '#0a0d14';
var C = { bg: '#f3f1ea', ground: '#e8e6dc', line: '#888780', dirt: '#b3a991', scorch: '#6d6a62', shade: '#d6d4c9', grey: '#a9a79e',
  lake: '#7fb0cf', lakeLite: '#c9e2ef', ink: '#1f1f1c', hud: '#d3d1c7', panel: '#e6e3d9', ring: '#b9b6ab', dead: '#d3d0c4', dim: '#8a877d', after: '#9fb3ae' };
function lane(core, main, edge) { return { core: core, main: main, edge: edge }; }
var FIGHTERS = [
  { id: 'protagonist', name: 'Protagonist', body: '#1f4f4a',
    L: { bolt: lane('#f2fdff', '#10c2ea', '#0b7fb8'), lob: lane('#ecfaff', '#1eb0f4', '#0e6cc4'), beam: lane('#f4faff', '#2e90f2', '#0d58c4'), trap: lane('#e8f5ff', '#2a9cf4', '#0f62bc'), sig: lane('#fffbea', '#f2b632', '#b26a0c') }, sweep: 32, bw: 1.2 },
  { id: 'rival', name: 'Rival', body: '#33295a',
    L: { bolt: lane('#f0e6ff', '#4420c4', '#2e0c78'), lob: lane('#f6e6ff', '#5c1ca8', '#3c0c6c'), beam: lane('#ffe8fb', '#80127e', '#5a0c64'), trap: lane('#eee4ff', '#4c20ac', '#300c70'), sig: lane('#ffe8fb', '#80127e', '#5a0c64') }, sweep: 34, bw: 0.85 }];
var LAKE = { x0: 250, x1: 470 };

// ---- data: first values, each block names its source ----
// the strike reader (Controls section 1): the dead zone, on and off (rescaled), rest, the settle, D (quick or charge)
var RS = { deadZone: 0.25, on: 0.60, off: 0.35, rest: 0.2, settle: 2, D: 12 };
// the right thumb's law (Controls 6.1, K2): a press after a stick command waits L, a stick command after a press waits R,
// a waiting input lives W ticks, the face queue is 3 deep
var LAW = { L: 6, R: 8, W: 36, qMax: 3 };
// the left hand (Controls section 2, GD section 4): the 6-tick window (the common gather), the slip's lateral part, the third
// of one direction in 3 s loses its frames; the brace: a quick onset from 10 ticks at rest, set on the flick's return, 3 ki,
// 90 ticks; the vanish: LB and LT within 6, 20 ki (x1.5 for each further one in 3 s), 8 ticks invulnerable, about 3 bh;
// LT held past 12 is the sprint; a whiff leaves the striker open 20
var LEFT = { win: 6, chord: 6, slipT: 12, repeatN: 3, repeatT: 180, braceRest: 10, braceRise: 3, braceReturn: 12, braceT: 90,
  braceReturnKey: 8, braceKi: 3, vanishKi: 20, vanishMul: 1.5, vanishInv: 8, vanishBh: 3, sprintT: 12, open: 20, flightDead: 0.2 };
var MOVE = { flight: 2.6, sprint: 1.8, chargeMove: 0.5, guardMove: 0.6, strike: 58 / 75, reach: 0.6, rushBh: 0.9 };
// the face blows (brawl-second-pass.md section 2): wind-up (press to contact), commitment (press to his next blow: the mash
// cap), the recovery shown after contact, ki; B's wind-up is armoured (lights never stop it, mediums until 20)
var BTN = {
  X: { name: 'LIGHT', w: 'light', wind: 2, commit: 6, rec: 6, ki: 0, dmg: 3, reel: 4, kb: 0.3 },
  Y: { name: 'MEDIUM', w: 'medium', wind: 12, commit: 12, rec: 8, ki: 2, dmg: 8, reel: 6, kb: 1 },
  B: { name: 'HEAVY', w: 'heavy', wind: 28, commit: 28, rec: 10, ki: 5, dmg: 14, reel: 12, kb: 3, armour: true },
  A: { name: 'GRAB', w: 'grab', wind: 10, commit: 14, rec: 10, ki: 0, dmg: 10 } };
// the stick's quick strike (level 0) by pitch. 4c: GD's own class, wind-up 12 from the request, commitment 16, a medium's
// ki and worth, a 20-tick stun. 4a: Controls' placeholder commitment 14. 4b: B's request with a direction (B's numbers).
// The charge: 4c and 4b the charged heavy, 4a its own ladder. The signature: on RT + the stick in 4c, on RT + B in 4a, 4b
var PITCH = {
  '4c': { tag: '4C', name: "GD'S SPLIT BY GESTURE", quick: { wind: 12, commit: 16, ki: 2, dmg: 8, reel: 6, stun: 20 }, charge: 'heavy', chargeKi: 3, sig: 'stick' },
  '4a': { tag: '4A', name: 'PURE 4A: OWN CLASS', quick: { wind: 10, commit: 14, ki: 0, dmg: 8, reel: 6, stun: 20 }, charge: 'own', chargeKi: 0, sig: 'B' },
  '4b': { tag: '4B', name: 'POOLED WITH B', quick: { wind: 28, commit: 28, ki: 5, dmg: 14, reel: 12, stun: 0, heavy: true }, charge: 'heavy', chargeKi: 0, sig: 'B' } };
var PITCHES = ['4a', '4b', '4c'];     // keys 1, 2, 3; the page starts on 4c
// the stun (GD section 2): 20 ticks, never a daze; the third quick strike of one direction inside 3 s hits but doesn't stun
var STUN = { repeatN: 3, repeatT: 180, daze: 40 };
// the charges, counted from the crossing (a face B from its press minus the settle). heavy: GD's charged heavy (B held's
// numbers): levels at 12, 30, 50 (the flash), armoured against lights (half their damage), mediums interrupt until 22,
// thrown 2 ticks after the release, committed 24 after it; in 4c the stick pays the rest of B's ki at D (chargeKi).
// own: pure 4a's own ladder (Controls' 12, 30, 54), no armour, its own stun by level, committed 16 after the release
var CHARGE = {
  heavy: { lv: [12, 30, 50], armour: true, mediumUntil: 22, throwT: 2, after: 24, mul: [1, 1.3, 1.6, 2.0], stun: [0, 0, 0, 0] },
  own: { lv: [12, 30, 54], armour: false, mediumUntil: 0, throwT: 2, after: 16, mul: [1, 1.35, 1.7, 2.2], stun: [20, 26, 32, 40] } };
// energy (energy-input.md section 3, GD section 3): the bolt every 6; the lob after 12; the heavy blast after 16, every 24,
// held past 20 a bigger blast in two levels (in 4b, the beam at him); the snap-beam: the heavy blast's wind-up and ki, out
// 12 ticks; the charged beam: levels 12, 30, 54 from the crossing, ki by level, out longer by level; the signature 45 ki
var EN = { boltGap: 6, lobWind: 12, lobPace: 12, blastWind: 16, blastHold: 20, blastPace: 24, blastKi: 5, bigLv: [20, 40], snapWind: 16, snapKi: 5,
  snapT: 12, beamLv: [12, 30, 54], beamKi: [5, 8, 14, 20], beamT: [12, 36, 48, 60], sigKi: 45, sigT: 50, lobT: 36 };
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
function quant(x, y) {
  var m = Math.sqrt(x * x + y * y); if (m < RS.deadZone) return { x: 0, y: 0, m: 0 };
  var r = Math.round(Math.min(1, (m - RS.deadZone) / (1 - RS.deadZone)) * 16) / 16; return { x: x / m * r, y: y / m * r, m: r };
}
// four ways on the screen, a tie to the vertical; y is the screen's (down positive); angles 32 ways, 90 is up
function dir4(x, y) { return Math.abs(y) >= Math.abs(x) ? (y < 0 ? 'up' : 'down') : (x > 0 ? 'right' : 'left'); }
function angOf(x, y) { var a = Math.atan2(-y, x) * 180 / Math.PI; if (a < 0) a += 360; return Math.round(a / 11.25) % 32 * 11.25; }
// the stance mask (Controls section 3: LB 1, RB 2, RT 4, LT 8; RT dominates): the stick's layer, and the lane it is thrown from
function layerOf(m) { return m.RT ? 'power' : m.RB && m.LB ? 'lay' : m.RB ? 'energy' : 'martial'; }
function laneOf(m) { return m.LB ? 'guard' : m.LT ? 'move' : ''; }
function mkReader() { return { on: false, crossT: -99, gid: 0, layer: null, lane: '', rested: true, reqAt: null, peak: null, cur: null, trace: [], log: [],
  dpOn: false, dpGid: 0, dpReqAt: null, dpDir: null, dpLayer: null, dpLane: '', dpCur: null, dpVec: [0, 0], lastRest: -99, restFrom: 0, atRest: true }; }
// the right stick (section 1): crossing on is a request 2 ticks later, at any speed; the layer is the shoulders' mask on the
// crossing tick (they are sampled before the stick), locked until the stick rests; the direction is read four ways at the
// settle and locked there (a stick let go sooner keeps its peak); back under off is the release, at its true tick. The D-pad
// mirror (a setting, off by default) acts on the same ticks: a press is the crossing, the first direction wins, a tie goes
// to the vertical. One request a tick: the stick's first, the pad's a tick later
function readRight(rd, t, x, y, mask, dp, mirror) {
  var q = quant(x, y), out = { req: null, release: null, q: q };
  rd.trace.push([x, y]); if (rd.trace.length > 44) rd.trace.shift();
  if (q.m <= RS.rest) rd.rested = true;
  // a request due this tick is read first, so a re-crossing on its tick can't swallow it (the newer then waits, and the
  // newest wins with a flicker)
  if (rd.reqAt != null && t >= rd.reqAt) {
    var s = rd.on && q.m >= RS.off ? q : rd.peak;
    out.req = { d: dir4(s.x, s.y), ang: angOf(s.x, s.y), layer: rd.layer, lane: rd.lane, gid: rd.gid, src: 'stick', t0: rd.crossT };
    rd.reqAt = null;
  }
  if (!rd.on && q.m >= RS.on) {
    rd.on = true; rd.crossT = t; rd.gid++; rd.reqAt = t + RS.settle; rd.peak = q;
    if (rd.rested) { rd.layer = layerOf(mask); rd.lane = laneOf(mask); rd.rested = false; }
  } else if (rd.on && q.m < RS.off) { rd.on = false; rd.relT = t; out.release = { gid: rd.gid, src: 'stick' }; }
  if (rd.on) { if (q.m >= rd.peak.m) rd.peak = q; rd.cur = { x: q.x, y: q.y, ang: angOf(q.x, q.y) }; }
  var on = mirror && !!(dp.x || dp.y);
  if (rd.dpReqAt != null && t >= rd.dpReqAt && !rd.dpHeld) { rd.dpHeld = { d: rd.dpDir, ang: rd.dpAng, layer: rd.dpLayer, lane: rd.dpLane, gid: rd.dpGid, src: 'pad', t0: rd.dpT0 }; rd.dpReqAt = null; }
  if (on && !rd.dpOn) { rd.dpOn = true; rd.dpGid++; rd.dpDir = dir4(dp.x, dp.y); rd.dpAng = angOf(dp.x, dp.y); rd.dpLayer = layerOf(mask); rd.dpLane = laneOf(mask); rd.dpReqAt = t + RS.settle; rd.dpT0 = t; }
  if (on) rd.dpCur = { ang: angOf(dp.x, dp.y) };
  if (!on && rd.dpOn) { rd.dpOn = false; rd.dpRelT = t; if (!out.release) out.release = { gid: rd.dpGid, src: 'pad' }; else out.release2 = { gid: rd.dpGid, src: 'pad' }; }
  if (rd.dpReqAt != null && t >= rd.dpReqAt && !rd.dpHeld) { rd.dpHeld = { d: rd.dpDir, ang: rd.dpAng, layer: rd.dpLayer, lane: rd.dpLane, gid: rd.dpGid, src: 'pad', t0: rd.dpT0 }; rd.dpReqAt = null; }
  if (rd.dpHeld && !out.req) { out.req = rd.dpHeld; rd.dpHeld = null; }
  rd.dpVec = [dp.x, dp.y];
  return out;
}
// the left stick (section 2): the crossing, its direction at the settle, whether its onset was quick (from rest in 3 ticks
// or fewer) after 10 or more ticks at rest, and its return under off
function readLeft(rd, t, x, y) {
  var q = quant(x, y), out = { settle: null, ret: null, q: q };
  rd.trace.push([x, y]); if (rd.trace.length > 44) rd.trace.shift();
  if (q.m <= RS.rest) { if (!rd.atRest) { rd.atRest = true; rd.restFrom = t; } rd.lastRest = t; } else rd.atRest = false;
  if (!rd.on && q.m >= RS.on) { rd.on = true; rd.crossT = t; rd.gid++; rd.peak = q; rd.setAt = t + RS.settle; rd.quick = t - rd.lastRest <= LEFT.braceRise; rd.restLen = rd.lastRest - rd.restFrom + 1; }
  else if (rd.on && q.m < RS.off) { rd.on = false; out.ret = { gid: rd.gid, t: t, crossT: rd.crossT }; }
  if (rd.on) { if (q.m >= rd.peak.m) rd.peak = q; rd.cur = { x: q.x, y: q.y, d: dir4(q.x, q.y) }; }
  if (rd.setAt != null && t >= rd.setAt) { var s = rd.on ? q : rd.peak; out.settle = { d: dir4(s.x, s.y), gid: rd.gid, quick: rd.quick, restLen: rd.restLen, crossT: rd.crossT }; rd.setAt = null; }
  return out;
}

// ---- the world ----
function mkF(def, x, alt) { return { def: def, x: x, y: alt, dir: 1, ki: 100, hp: 100, vx: 0, vy: 0, mv: null, blow: null, beam: null, bchg: null, schg: null, shotW: null,
  lean: 0, reel: 0, stun: 0, down: 0, air: false, spiked: false, caught: 0, held: 0, open: 0, dodgeT: 0, dodge: null, sway: null, slipT: 0, slipD: null, slipK: null,
  guard: false, guardT: 0, brace: null, braceCand: null, commit: 0, q: [], pend: null, faceT: null, stickT: null, reqGid: null, reqSrc: null,
  pace: { lob: -99, blast: -99 }, lastBolt: -99, lbT: -99, ltT: -99, slipC: -99, beamT: null, sprint: false, planted: false, vanishes: [], slips: [], quicks: [],
  blinkT: 0, castCue: 0, flash: 0, tl: [], prev: {}, swayY: 0, flurry: null, grabLock: 0, settle: 0, home: [x, alt] }; }
function newWorld(clip, take, mode, lane2, pitch) {
  var T = clip ? clip.takes[take] : null;
  var w = { t: 0, mode: mode, clip: clip, pitch: pitch || '4c', mirror: false, P: mkF(FIGHTERS[0], 260, 0), V: mkF(FIGHTERS[1], 460, 0), shots: [], fx: [], grabs: [], marks: [],
    rd: mkReader(), rdL: mkReader(), seq: 0, sound: [], inp: {} };
  w.P.foe = w.V; w.V.foe = w.P;
  if (T) { if (T.pitch) w.pitch = T.pitch; if (T.mirror) w.mirror = true; var su = lane2 ? T.setup2 || T.setup : T.setup; if (su) su(w); }
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
var WORD = { toward: 'TOWARD', away: 'AWAY', up: 'UP', down: 'DOWN', neutral: 'NEUTRAL' };
// E3 (energy-overhaul.md) and ruling 14: an input that can't act flickers in his hand with the not-ready cue
function nack(w, f, text) { note(w, text, true); w.fx.push({ k: 'ack', f: f, t: 0, dur: 6 }); sound(w, 'nack'); return false; }
function recent(list, t, span) { return list.filter(function (x) { return t - x < span; }); }

// ---- blows: a wind-up from the start, the contact (after the rush, if he had to close), the recovery; the commitment
// says when his next blow may start. A charge holds the wind-up; the release throws it ----
function spotAt(f, g) { var s2 = f.x <= f.foe.x ? -1 : 1; return [f.foe.x + s2 * g * BH, f.foe.y]; }
function tween(f, k, x1, y1, dur) { f.mv = { k: k, x0: f.x, y0: f.y, x1: x1, y1: y1, t: 0, dur: dur }; f.settle = 0; }
// pillar 3: out of reach a blow is a lunge, closing as it winds; it lands at its wind-up's end or as he arrives
function startBlow(w, f, spec) {
  var b = { t: 0, start: w.t, done: false }; for (var k in spec) b[k] = spec[k];
  b.contactAt = w.t + b.wind; f.blow = b; f.tl.push({ t: w.t, k: 'P' });
  if (bhOf(f) > MOVE.strike + MOVE.reach) { var sp = spotAt(f, MOVE.strike); tween(f, 'rush', sp[0], sp[1], clamp(Math.ceil(dist(f, { x: sp[0], y: sp[1] }) / BH / MOVE.rushBh), 2, 16)); }
  return b;
}
function rushing(f) { return !!(f.mv && f.mv.k === 'rush'); }
function blowFree(w, f) { var b = f.blow; if (!b) return true; if (b.charging || !b.done) return false; return b.relT != null ? w.t >= b.relT + b.after : w.t - b.start >= b.commit; }
function chargingNow(w, f) {
  var b = f.blow, g = f.bchg, s = f.schg, B = !!(w.inp && w.inp.B) && f === w.P;
  // still out, or let go on this very tick (the left hand is read before the release), or held past D during a wait
  var held = function (o) { return (outOrJust(w, o.src, o.gid) && !o.released) || heldPastD(o); };
  return !!((b && (b.charging || (b.holdable && !b.decided && (b.kind === 'B' ? B : held(b))))) ||
    (g && (g.charging || (!g.decided && held(g)))) || (s && (s.held || held(s))) || (f.shotW && f.shotW.charging));
}
function outOrJust(w, src, gid) { return stillOut(w, src, gid) || (src === 'stick' ? w.rd.relT === w.t && w.rd.gid === gid : src === 'pad' ? w.rd.dpRelT === w.t && w.rd.dpGid === gid : false); }
function cancelOwn(w, f, why) {
  var lost = chargingNow(w, f);
  if (f.blow && !blowFree(w, f)) f.blow = null; f.bchg = null; f.schg = null; f.shotW = null; if (rushing(f)) f.mv = null;
  if (lost && why) note(w, why + ': CHARGE LOST', true);
  if (f.pend) nack(w, f, 'FLICK DROPPED'); f.pend = null;
}

// ---- the left hand (section 2): the dodge on LT's press tick, its direction from a left flick in the 6-tick window; LB
// and LT within 6 upgrade it to the vanish at tick 6; LB alone guards; LB and a quick left flick from rest set a brace on
// the flick's return. No right-hand input is part of any of it (K5) ----
var SLIP = { neutral: 'THE DODGE', away: 'A BACK-STEP', toward: 'A SLIP IN', up: 'A SWAY UP', down: 'A DUCK' };
function startDodge(w, f) {
  if (f.dodge || f.dodgeT > 0 || w.t < f.slipC) return nack(w, f, 'DODGE: NOT READY');
  if (f.beam && !f.beam.end && f.beam.root) return nack(w, f, 'BEAM: ROOTED');
  if (f.held > 0) return nack(w, f, 'HOLDING: NO DODGE');
  var rush = rushing(f);
  cancelOwn(w, f, 'DODGE');
  f.dodge = { t0: w.t, d: w.rdL.on ? w.rdL.cur.d : null, rush: rush }; f.dodgeT = LEFT.win + 1; f.sway = null; f.slipK = 'THE DODGE'; f.guard = false;
  f.tl.push({ t: w.t, k: 'D' });
}
function resolveDodge(w, f, inp) {
  var dg = f.dodge, d4 = dg.d || (w.rdL.on ? w.rdL.cur.d : null); f.dodge = null;
  // the chord: LB pressed within 6 of LT, either order, and still held; LB held longer before LT is the dodge out of guard
  if (inp.LB && Math.abs(f.lbT - dg.t0) <= LEFT.chord) { if (dg.rush) nack(w, f, 'VANISH: NOT IN A RUSH'); else if (vanish(w, f, d4)) return; }
  slip(w, f, d4);
}
function slip(w, f, d4) {
  var k = d4 ? rel(f, d4) : 'neutral', sx = f.foe.x >= f.x ? 1 : -1;
  f.slips = f.slips.filter(function (s) { return w.t - s.t < LEFT.repeatT; }); var n = f.slips.filter(function (s) { return s.k === k; }).length + 1; f.slips.push({ k: k, t: w.t });
  var frames = n < LEFT.repeatN;
  f.dodgeT = frames ? LEFT.slipT : 0; f.slipC = w.t + LEFT.slipT; f.slipK = SLIP[k]; f.slipD = k; f.slipT = 0; f.sway = null;
  if (k === 'neutral') tween(f, 'dodge', f.x - sx * 0.5 * BH, f.y, 10);
  else if (k === 'away') tween(f, 'dodge', f.x - sx * 1.1 * BH, f.y, 10);
  else if (k === 'toward') tween(f, 'dodge', f.x + sx * clamp(Math.abs(f.foe.x - f.x) - 0.5 * BH, 0, 1.1 * BH), f.y, 10);
  else { f.sway = k; f.vx = f.vy = 0; f.settle = 0; }
  note(w, (k === 'neutral' ? 'LT' : 'LT + ' + WORD[k]) + ': ' + SLIP[k]);
  if (!frames) note(w, 'NO FRAMES: 3RD IN 3 S', true);
}
var BRACEK = { up: 'heavy', down: 'flurry', toward: 'grab', away: 'shot' }, BRACEW = { heavy: 'HIS HEAVY', flurry: 'HIS FLURRY', grab: 'HIS GRAB', shot: 'HIS SHOT' };
function brace(w, f, d4) {
  if (f.ki < LEFT.braceKi) return nack(w, f, 'NO KI FOR A BRACE');
  var k = BRACEK[rel(f, d4)]; f.ki -= LEFT.braceKi; f.brace = { k: k, t0: w.t, until: w.t + LEFT.braceT };
  note(w, 'BRACE: ' + BRACEW[k] + ' (3 KI)'); sound(w, 'read'); return true;
}
// a brace that meets his move plays it out: the slip, and he is left open (v2's read, moved to the left thumb)
function fireBrace(w, f, foe) {
  var k = f.brace.k, sx = foe.x >= f.x ? 1 : -1; f.brace = null; f.dodgeT = 10; cancelOwn(w, f); f.vx = f.vy = 0;
  if (k === 'heavy') { f.sway = 'down'; f.slipT = 0; foe.blow = null; foe.open = LEFT.open; note(w, 'BRACE: UNDER HIS HEAVY'); note(w, 'HE IS OPEN', true); }
  else if (k === 'flurry') { f.sway = 'down'; f.slipT = 0; foe.flurry = null; foe.blow = null; foe.open = 10; note(w, 'BRACE: DUCKS HIS FLURRY'); note(w, 'HIS RUN IS BROKEN', true); }
  else if (k === 'grab') { f.vx = -sx * 6; f.settle = 8; foe.vx = sx * 6; foe.grabLock = 90; var cg = chest(f); burst(w, cg[0], cg[1], 14, 8, foe.def.L.trap, 6); note(w, 'BRACE: HIS GRAB BREAKS'); }
  else { tween(f, 'dodge', f.x, f.y + 0.9 * BH, 8); note(w, 'BRACE: SLIPS HIS SHOT'); }
  sound(w, 'read');
}
// the vanish (GD section 4): an upgrade of the dodge, the blink at tick 6: an instant cut with sharp after-images, never a
// fade; away is the escape (and neutral goes away), toward blinks through to his back, up and down go over and under him.
// 20 ki with the dodge's included, x1.5 for each further vanish inside 3 s; not while caught, open or in a rush
function vanish(w, f, d4) {
  var k = d4 ? rel(f, d4) : 'away', foe = f.foe, sx = foe.x >= f.x ? 1 : -1;
  if (f.caught > 0 || f.held > 0 || rushing(f)) { nack(w, f, 'VANISH: NOT NOW'); return false; }
  f.vanishes = recent(f.vanishes, w.t, LEFT.repeatT);
  var cost = Math.round(LEFT.vanishKi * Math.pow(LEFT.vanishMul, f.vanishes.length));
  if (f.ki < cost) { nack(w, f, 'VANISH: NO KI (' + cost + ')'); return false; }
  var tx = f.x, ty = f.y;
  if (k === 'away') tx = f.x - sx * LEFT.vanishBh * BH; else if (k === 'toward') tx = foe.x + sx * 0.9 * BH; else if (k === 'up') { tx = foe.x - sx * 0.2 * BH; ty = foe.y + 1.6 * BH; } else { tx = foe.x - sx * 0.2 * BH; ty = foe.y - 1.6 * BH; }
  tx = clamp(tx, 18, AW - 18); ty = clamp(ty, 0, 250);
  for (var i = 0; i < 3; i++) { var u = i / 3; w.fx.push({ k: 'after', x: lerp(f.x, tx, u), y: lerp(f.y, ty, u), dir: f.dir, t: 0, dur: 4 + 2 * i }); }
  f.ki -= cost; f.vanishes.push(w.t); f.x = tx; f.y = ty; f.vx = f.vy = 0; f.mv = null; f.sway = null;
  f.dodgeT = LEFT.vanishInv; f.slipK = 'THE VANISH'; f.slipD = null; f.blinkT = 6; f.dir = foe.x >= f.x ? 1 : -1;
  sound(w, 'vanish'); note(w, 'VANISH ' + WORD[k] + ' (' + cost + ' KI)'); f.tl.push({ t: w.t, k: 'V' });
  return true;
}
function leftHand(w, f, inp, evL) {
  var lt = !!inp.LT, lb = !!inp.LB, p = f.prev;
  if (lb && !p.LB) {
    f.lbT = w.t;
    // a guard press cancels a charge, and the charge is lost (GD Q4)
    if (chargingNow(w, f)) cancelOwn(w, f, 'GUARD');
  }
  if (lt && !p.LT) {
    f.ltT = w.t;
    if (f.open > 0) nack(w, f, 'OPEN: NO DODGE'); else startDodge(w, f);
  }
  if (f.dodge) {
    // the direction: the first left flick settled in the window, or the stick out at its end
    if (evL.settle && !f.dodge.d && evL.settle.crossT >= f.dodge.t0 - 1) f.dodge.d = evL.settle.d;
    if (w.t - f.dodge.t0 >= LEFT.win) resolveDodge(w, f, inp);
  }
  // the brace: LB down, LT not, a quick onset from 10 ticks at rest, set on the return (a held lean never sets one)
  if (evL.settle && lb && !lt && !f.dodge && evL.settle.quick && evL.settle.restLen >= LEFT.braceRest && evL.settle.crossT - f.ltT > LEFT.chord) f.braceCand = { gid: evL.settle.gid, d: evL.settle.d, crossT: evL.settle.crossT };
  if (evL.ret && f.braceCand && evL.ret.gid === f.braceCand.gid) {
    var bc = f.braceCand; f.braceCand = null;
    if (lb && !lt && !f.dodge && w.t - bc.crossT <= (inp.lkeys ? LEFT.braceReturnKey : LEFT.braceReturn)) { if (f.stun > 0 || f.air) nack(w, f, 'NO BRACE NOW'); else brace(w, f, bc.d); }
  }
  if (f.braceCand && w.t - f.braceCand.crossT > LEFT.braceReturn) f.braceCand = null;
  f.sprint = lt && !f.dodge && !f.planted && w.t - f.ltT >= LEFT.sprintT;
  if (!lt) f.planted = false;
  f.guard = lb && !f.dodge && f.dodgeT === 0 && blowFree(w, f) && !f.bchg && !f.schg && !f.shotW && !(f.beam && !f.beam.end) && !f.held && f.open === 0;
}

// ---- the right hand: the stick's requests wait out a press (K2's R) and anything still running; the face presses queue
// behind the stick's commitment (L) and are inert while the stick holds a request (K3) ----
var QN = { X: 'X', Y: 'Y', B: 'B', A: 'A', BOLT: 'X', LOB: 'Y', BLAST: 'B', SIG: 'RT+B', SP1: 'RT+X', SP2: 'RT+Y', SP3: 'RT+A' };
function busy(f, w) { return f.commit > 0 || !blowFree(w, f) || !!f.dodge || f.dodgeT > 0 || w.t < f.slipC || !!f.bchg || !!f.schg || !!(f.beam && !f.beam.end) || !!f.shotW || f.held > 0 || f.open > 0; }
function stickBusy(f, w) { return !blowFree(w, f) || !!f.dodge || f.dodgeT > 0 || w.t < f.slipC || !!f.bchg || !!f.schg || !!(f.beam && !f.beam.end) || !!f.shotW || f.held > 0 || f.open > 0; }
// the stick still out: the same gesture a move came from
function stillOut(w, src, gid) { return src === 'pad' ? w.rd.dpOn && w.rd.dpGid === gid : src === 'stick' ? w.rd.on && w.rd.gid === gid : false; }
function stickAng(w, src) { return src === 'pad' ? (w.rd.dpCur ? w.rd.dpCur.ang : null) : (w.rd.cur && w.rd.on ? w.rd.cur.ang : null); }
// K3: the stick holds a request (its gesture acted and is still out), so a face press is inert until the release + L
function k3(w, f) { return f.reqGid != null && stillOut(w, f.reqSrc, f.reqGid); }
// the tick a press's thumb counts from: its press, raised to the stick's release + L when the stick held a request then
function qEff(w, f, e) { return e.on ? (f.stickT != null && f.stickT >= e.t ? f.stickT + LAW.L : Infinity) : Math.max(e.t, e.st != null ? e.st + LAW.L : -99); }
function thumbT(w, f, inp) {
  var t = f.faceT == null ? -99 : f.faceT;
  if (inp.B && f.blow && f.blow.kind === 'B' && f.blow.charging) t = Math.max(t, w.t);     // the thumb is on B while it charges
  if (inp.B && f.shotW && f.shotW.k === 'blast') t = Math.max(t, w.t);
  f.q.forEach(function (e) { var q = qEff(w, f, e); if (q !== Infinity) t = Math.max(t, q); });
  return t;
}
function dropPend(w, f, t) { if (f.pend && f.pend.at < t) { f.pend = null; nack(w, f, 'FLICK DROPPED'); } }
function facePress(w, f, k, inp) {
  dropPend(w, f, w.t);
  var on = k3(w, f);
  if (on || busy(f, w) || f.q.length) { if (f.q.length < LAW.qMax) { f.q.push({ k: k, t: w.t, on: on, st: f.stickT }); note(w, QN[k] + (on ? ' INERT: STICK HELD' : ' QUEUED')); } else nack(w, f, 'QUEUE FULL'); return; }
  doPress(w, f, k, inp, null);
}
function doPress(w, f, k, inp, ent) {
  var did = startPress(w, f, k, inp);
  if (did) f.faceT = Math.max(f.faceT == null ? -99 : f.faceT, ent ? qEff(w, f, ent) : w.t);
  return did;
}
function startPress(w, f, k, inp) {
  var Bn = BTN[k];
  if (Bn) {
    if (f.ki < Bn.ki) return nack(w, f, k + ': NO KI');
    f.ki -= Bn.ki;
    var b = startBlow(w, f, { kind: k, wind: Bn.wind, commit: Bn.commit, rec: Bn.rec, w: Bn.w, armour: !!Bn.armour, holdable: k === 'B', t0: w.t - RS.settle, chg: 'heavy', chargeKi: 0 });
    note(w, k + ': ' + Bn.name); return !!b;
  }
  if (k === 'BOLT') { if (w.t - f.lastBolt < EN.boltGap) return nack(w, f, 'X: NOT READY'); f.lastBolt = w.t; fire(w, f, 'bolt', 0); f.tl.push({ t: w.t, k: 'P' }); return true; }
  if (k === 'LOB') { if (w.t - f.pace.lob < EN.lobPace) return nack(w, f, 'Y: NOT READY'); f.pace.lob = w.t; f.shotW = { k: 'lob', start: w.t, at: w.t + EN.lobWind }; note(w, 'Y: LOB'); f.tl.push({ t: w.t, k: 'P' }); return true; }
  if (k === 'BLAST') {
    if (w.t - f.pace.blast < EN.blastPace) return nack(w, f, 'B: NOT READY'); if (f.ki < EN.blastKi) return nack(w, f, 'B: NO KI');
    f.pace.blast = w.t; f.ki -= EN.blastKi; f.shotW = { k: 'blast', start: w.t, at: w.t + EN.blastWind, t0: w.t - RS.settle, lv: 0 }; note(w, 'B: HEAVY BLAST'); f.tl.push({ t: w.t, k: 'P' }); return true;
  }
  if (k === 'SIG') {
    if (f.ki < EN.sigKi) return nack(w, f, 'SIGNATURE: NO KI');
    f.ki -= EN.sigKi; startBeam(w, f, aimDeg(f), 3, true); note(w, PITCH[w.pitch].sig === 'stick' ? 'RT+B: SIGNATURE (SP 4)' : 'RT+B: SIGNATURE'); return true;
  }
  return nack(w, f, QN[k] + ': NOT IN PROTOTYPE');
}

// ---- the stick's moves: what a request makes, by its layer ----
var STRIKEW = { toward: 'BODY BLOW', up: 'RISING BLOW', down: 'SWEEP', away: 'TURNING BLOW' }, HEAVYW = { toward: 'DRIVES BACK', up: 'LIFTS', down: 'DRIVES UNDER', away: 'TURNS PAST' };
function strikeW(f, dir) { return dir === 'down' && f.foe.y > 8 ? 'SPIKE' : STRIKEW[dir]; }
function stickAct(w, f, pd) {
  var t0 = w.t - RS.settle, P = PITCH[w.pitch], released = !stillOut(w, pd.src, pd.gid), late = { crossT: pd.t0, relAt: pd.relT };
  var made = function () { f.stickT = w.t; f.commit = Math.max(f.commit, LAW.L); f.tl.push({ t: w.t, k: 'F' }); f.reqGid = pd.gid; f.reqSrc = pd.src; return true; };
  if (pd.layer === 'energy') { f.bchg = { t0: t0, start: w.t, gid: pd.gid, src: pd.src, ang: pd.aim, d: pd.rel, lv: 0, charging: false, released: released, crossT: late.crossT, relAt: late.relAt }; note(w, 'STICK ' + WORD[pd.rel] + ': BEAM'); return made(); }
  if (pd.layer === 'power') {
    if (P.sig !== 'stick') return nack(w, f, 'RT+STICK: NOTHING HERE');
    f.schg = { t0: t0, start: w.t, gid: pd.gid, src: pd.src, ang: pd.ang, held: false, released: released, crossT: late.crossT, relAt: late.relAt }; return made();
  }
  if (pd.layer === 'lay') return nack(w, f, 'LAY: NOT IN PROTOTYPE');
  var dir = pd.rel, Q = P.quick;
  if (f.ki < Q.ki) return nack(w, f, 'STRIKE: NO KI');
  f.ki -= Q.ki; made();
  startBlow(w, f, { kind: 'S', dir: dir, wind: Q.wind, commit: Q.commit, rec: 8, src: pd.src, gid: pd.gid, t0: t0, holdable: true, chg: P.charge, chargeKi: P.chargeKi, quickSpec: Q, armour: !!Q.heavy, w: Q.heavy ? 'heavy' : 'medium', lane: pd.lane, released: released, crossT: late.crossT, relAt: late.relAt });
  note(w, 'STICK ' + WORD[dir] + ': ' + (Q.heavy ? 'HEAVY' : strikeW(f, dir)));
  if (pd.lane) note(w, pd.lane === 'guard' ? 'A STRIKE FROM GUARD' : 'A STRIKE ON THE MOVE', true);
  return true;
}
// the beam's aim, latched at the settle (GD section 3): toward at him, up and down 45 degrees off it, away behind
function latchAim(f, d4) { var a = aimDeg(f), r = rel(f, d4), side = f.foe.x >= f.x ? 1 : -1; return r === 'toward' ? a : r === 'away' ? (a + 180) % 360 : r === 'up' ? a + 45 * side : a - 45 * side; }
function rightStick(w, f, inp, ev) {
  // while his beam is out the stick steers it (R25); it makes no requests then, and none while he is caught or open
  if (ev.req) {
    if ((f.beam && !f.beam.end) || (f.beamT != null && ev.req.t0 <= f.beamT)) { /* steering, not a request (R25) */ }
    else if (f.caught > 0) nack(w, f, 'CAUGHT: NOT READY');
    else { if (f.pend) nack(w, f, 'FLICK REPLACED'); f.pend = { d: ev.req.d, rel: rel(f, ev.req.d), aim: latchAim(f, ev.req.d), ang: ev.req.ang, layer: ev.req.layer, lane: ev.req.lane, src: ev.req.src, gid: ev.req.gid, t0: ev.req.t0, at: w.t }; }
  }
  [ev.release, ev.release2].forEach(function (rl) { if (rl) releaseStick(w, f, rl); });
}
function releaseStick(w, f, rl) {
  f.tl.push({ t: w.t, k: 'R' });
  var mine = function (o) { return o && o.src === rl.src && o.gid === rl.gid; };
  if (mine({ src: f.reqSrc, gid: f.reqGid })) f.stickT = Math.max(f.stickT == null ? -99 : f.stickT, w.t);
  var b = f.blow;
  if (b && b.kind === 'S' && mine(b)) { if (b.charging) throwCharge(w, f, b); else if (!b.released) { b.released = true; b.relAt = w.t; } }
  if (f.bchg && mine(f.bchg)) { if (f.bchg.charging) fireBeam(w, f); else if (!f.bchg.released) { f.bchg.released = true; f.bchg.relAt = w.t; } }
  if (f.schg && mine(f.schg)) {
    if (f.schg.held) { f.ki -= EN.sigKi; var a = f.schg.ang; f.schg = null; startBeam(w, f, a, 3, true); note(w, 'LET GO: SIGNATURE'); f.commit = Math.max(f.commit, LAW.L); }
    else { f.schg = null; f.castCue = 12; note(w, 'RT: HOLD TO CAST', true); }
  }
  if (f.pend && mine(f.pend) && !f.pend.released) { f.pend.released = true; f.pend.relT = w.t; }
}
function throwCharge(w, f, b) {
  b.charging = false; b.relT = w.t; b.after = CHARGE[b.chg].after; b.contactAt = Math.max(w.t + CHARGE[b.chg].throwT, b.start + b.wind);
  if (b.kind === 'S') { f.stickT = w.t; f.commit = Math.max(f.commit, LAW.L); }
  note(w, 'LET GO: LEVEL ' + b.lv);
}
// a request acts when the thumb's waits are over (R after a press), nothing of his is running, and no press made before it
// still waits (the older input starts first); a request kept past W lapses with a flicker
function stickActs(w, f, inp) {
  if (!f.pend) return;
  var lock = thumbT(w, f, inp) + LAW.R, older = f.q.some(function (e) { return e.t <= f.pend.at; });
  if (w.t >= lock && !stickBusy(f, w) && !older) { var pd = f.pend; f.pend = null; stickAct(w, f, pd); }
  else if (w.t - f.pend.at > LAW.W) { f.pend = null; nack(w, f, 'FLICK LAPSES'); }
}

// ---- a blow's tick: D decides quick or charge (the stick still out, or B still held); the charge climbs its ladder and
// waits for the release; the contact, then the recovery ----
// held past D from its crossing, though let go before its delayed act decided it
function heldPastD(o) { return o.crossT != null && o.relAt != null && o.relAt >= o.crossT + RS.D; }
function blowStep(w, f) {
  var b = f.blow; if (!b) return;
  b.t++;
  if (b.holdable && !b.decided && w.t - b.t0 >= RS.D) {
    b.decided = true;
    var out = b.kind === 'B' ? !!(w.inp && w.inp.B) && f === w.P : (stillOut(w, b.src, b.gid) && !b.released) || heldPastD(b);
    if (out) {
      var ck = b.chargeKi || 0;
      if (f.ki < ck) nack(w, f, 'CHARGE: NO KI');
      else { f.ki -= ck; b.charging = true; b.lv = 0; note(w, b.kind === 'B' ? 'B HELD: CHARGING' : 'HELD: CHARGING'); if (b.kind === 'S' && b.released) { b.lv = 1; throwCharge(w, f, b); return; } }
    }
  }
  if (b.charging) {
    var Ch = CHARGE[b.chg], c = w.t - b.t0, lv = 0; for (var i = 0; i < 3; i++) if (c >= Ch.lv[i]) lv = i + 1;
    if (lv !== b.lv) { b.lv = lv; sound(w, 'click'); if (lv === 3) { f.flash = 8; note(w, 'FULL: THE FLASH', true); } }
    if (b.kind === 'B' && f === w.P && !(w.inp && w.inp.B)) { f.faceT = Math.max(f.faceT == null ? -99 : f.faceT, w.t); throwCharge(w, f, b); }
    return;
  }
  if (!b.done && w.t >= b.contactAt && !rushing(f)) { b.done = true; b.hitT = w.t; contact(w, f, b); if (f.blow !== b) return; }
  var endT = b.relT != null ? Math.max(b.relT + b.after, b.hitT + b.rec) : Math.max(b.start + b.commit, (b.hitT || 0) + b.rec);
  if (b.done && w.t >= endT) f.blow = null;
}
// what lands: by kind, pitch, direction and level
function hitSpec(w, f, b) {
  var dir = b.dir, lv = b.lv || 0;
  if (b.kind === 'X' || b.kind === 'Y') { var B0 = BTN[b.kind]; return { dmg: B0.dmg, reel: B0.reel, kb: B0.kb, name: B0.name, w: B0.w }; }
  var heavyHit = b.kind === 'B' || (b.kind === 'S' && (b.chg === 'heavy' && (b.relT != null || b.armour)));
  if (heavyHit) {
    // the charged heavy (and B, and 4b's stick): no stun; the stick's direction weights the send, the level its power
    var m = CHARGE.heavy.mul[lv], full = lv >= 3, d = b.kind === 'B' ? 'toward' : dir;
    var s = { dmg: BTN.B.dmg * m, reel: BTN.B.reel, w: 'heavy', charged: b.relT != null, name: 'HEAVY' + (lv ? ' L' + lv : '') };
    if (d === 'toward') { s.kb = 2 + 2.2 * lv; s.drive = true; } else if (d === 'up') s.launch = full ? 9 : 3 + 1.5 * lv; else if (d === 'down') s.spike = true; else { s.past = 1 + 0.6 * lv; }
    s.downT = d === 'down' ? 16 + 6 * lv : 0; return s;
  }
  // the stick strike: quick (level 0), or pure 4a's own charge
  var Q = b.quickSpec, own = b.relT != null, st = own ? CHARGE.own.stun[lv] : Q.stun, mm = own ? CHARGE.own.mul[lv] : 1;
  var r = { dmg: Q.dmg * mm, reel: Q.reel, stun: st, w: 'medium', quick: !own, name: strikeW(f, dir) + (own ? ' L' + lv : '') };
  if (dir === 'toward') r.kb = 0.6 + (own && lv >= 3 ? 4 : 0); else if (dir === 'up') r.pop = own && lv >= 3 ? 8 : 0; else if (dir === 'down') r.spike = true; else r.kb = 1.6 + (own ? 0.8 * lv : 0);
  return r;
}
function contact(w, f, b) {
  var foe = f.foe, d = bhOf(f), reach = MOVE.strike + MOVE.reach + (b.w === 'medium' ? 0.5 : b.w === 'heavy' ? 1 : 0) + (b.relT != null ? 0.25 * (b.lv || 0) : 0);
  if (f === w.V) return rivalContact(w, f, b, d <= reach);
  if (d > reach) { f.open = LEFT.open; note(w, 'WHIFF: OPEN ' + LEFT.open, true); return; }
  if (b.kind === 'A') {     // the grab: caught, then thrown away from you
    if (foe.caught || foe.air) { note(w, 'GRAB: NOTHING TO HOLD', true); return; }
    foe.caught = 30; f.held = 30; foe.blow = null; foe.flurry = null; foe.guardT = 0; note(w, 'A: CAUGHT'); return;
  }
  applyHit(w, f, foe, hitSpec(w, f, b), b);
}
function applyHit(w, a, d, s, b) {
  var sx = d.x >= a.x ? 1 : -1, c0 = chest(a), c1 = chest(d), cl = dist({ x: c0[0], y: c0[1] }, { x: c1[0], y: c1[1] }) || 1;
  // his guard: a quick strike or a medium is blocked (no stun); a heavy breaks a set guard; a charged blow breaks it to a daze
  if (d.guardT > 0 && s.w !== 'grab') {
    if (s.w === 'heavy') { d.guardT = 0; d.stun = s.charged ? STUN.daze : 0; d.reel = Math.max(d.reel, 12); note(w, s.charged ? 'GUARD BROKEN: DAZED' : 'HIS GUARD BREAKS'); burst(w, c1[0] - sx * 10, c1[1], 14, 8, SPARK, 6); sound(w, 'blow'); return; }
    d.reel = Math.max(d.reel, 3); d.vx = sx * 0.8; note(w, 'GUARDED: ' + s.name.slice(0, 14)); sound(w, 'guard'); burst(w, c1[0] - sx * 10, c1[1], 7, 6, SPARK, 4); return;
  }
  // a trade: his blow lands on this same tick, so neither is stunned
  var trade = d === w.V && d.blow && !d.blow.done && d.blow.contactAt === w.t;
  d.hp = Math.max(0, d.hp - s.dmg); d.reel = Math.max(d.reel, s.reel || 0); if (!trade) { d.blow = null; d.flurry = null; } d.guardT = 0;
  var stun = s.stun || 0, how = '';
  if (s.quick && stun) {
    var dir = b && b.dir; a.quicks = a.quicks.filter(function (q) { return w.t - q.t < STUN.repeatT; });
    var n = a.quicks.filter(function (q) { return q.d === dir; }).length + 1; a.quicks.push({ d: dir, t: w.t });
    if (n >= STUN.repeatN) { stun = 0; how = ': NO STUN (3RD)'; }
  }
  if (trade) { stun = 0; how = ': A TRADE'; }
  if (stun) { d.stun = Math.max(d.stun, Math.round(stun)); how = how || ': STUNNED'; }
  if (s.kb) d.vx = sx * s.kb * BH * 0.12;
  if (s.past) { d.x = clamp(a.x - sx * s.past * BH * 0.6, 18, AW - 18); d.vx = -sx * 2; how = how || ': TURNED PAST'; }
  if (s.launch) { d.vy = s.launch; d.air = true; d.vx = sx * 1.4; how = ': LAUNCHED'; }
  if (s.pop) { d.vy = s.pop; d.air = true; d.vx = sx * 0.8; }
  if (s.spike) { if (d.y > 8) { d.vy = -11; d.air = true; d.spiked = true; how = how === ': STUNNED' ? ': SPIKED, STUNNED' : ': SPIKED'; } else if (s.downT) { d.down = s.downT; d.vx = sx * 1.2; how = ': DRIVEN UNDER'; } }
  if (s.drive) how = how || ': DRIVEN BACK'; else if (!how && s.kb >= 3) how = ': SENT BACK';
  burst(w, c1[0] - (c1[0] - c0[0]) / cl * 12, c1[1] - (c1[1] - c0[1]) / cl * 12, 8 + s.dmg * 0.5, 8, SPARK, 6); sound(w, 'blow');
  note(w, (s.name + how).length <= 24 ? s.name + how : (s.name + how).slice(0, 24));
  if (d.hp <= 0) { d.hp = 100; note(w, 'THE DUMMY RESETS', true); }
}
// his blows on you. Out of reach he whiffs and is open; a slip or the vanish slips it; a brace plays out; the guard holds
// (his heavy breaks it); your own move's armour (B's wind-up from its first tick, a charged heavy) takes a light at half
// damage, and a medium after tick 22; anything else ends your move, and the quick strike is bare to lights
function rivalContact(w, v, b, inReach) {
  var P = v.foe, sx = P.x >= v.x ? 1 : -1, nm = b.w === 'light' ? 'HIS LIGHT' : b.w === 'heavy' ? 'HIS HEAVY' : 'HIS BLOW';
  if (!inReach || (P.x - v.x) * (b.face || 1) < 0 || Math.abs(P.y - v.y) > 0.9 * BH) { v.open = LEFT.open; v.flurry = null; note(w, nm + ' WHIFFS: OPEN', true); return; }
  if (P.dodgeT > 0) { v.open = LEFT.open; v.flurry = null; note(w, 'HE MISSES: ' + (P.slipK || 'SLIPPED')); return; }
  if (P.brace && P.brace.k === (b.w === 'heavy' ? 'heavy' : b.fl ? 'flurry' : '') && b.start >= P.brace.t0) return fireBrace(w, P, v);
  if (P.guard) {
    if (b.w === 'heavy') { P.guard = false; P.reel = 14; P.vx = sx * 3; P.settle = 8; note(w, 'HIS HEAVY BREAKS GUARD'); sound(w, 'blow'); burst(w, P.x - sx * 8, P.y + 44, 12, 8, SPARK, 6); return; }
    P.reel = 4; P.vx = sx * 1.5; P.settle = 6; burst(w, P.x + -sx * 8, P.y + 44, 7, 6, SPARK, 4); note(w, 'GUARDED: ' + nm); sound(w, 'guard'); return;
  }
  var pb = P.blow;
  if (pb && !pb.done) {
    var armoured = (pb.charging || pb.relT != null) ? CHARGE[pb.chg].armour : pb.armour, ct = w.t - pb.t0;
    if (armoured && (b.w === 'light' || (b.w === 'medium' && ct >= CHARGE.heavy.mediumUntil))) { var c0 = chest(P); burst(w, c0[0] - sx * 8, c0[1], 7, 6, SPARK, 4); note(w, 'ARMOUR HOLDS: ' + nm.slice(4)); sound(w, 'guard'); return; }
    if (pb.kind === 'Y' && b.w === 'light') { note(w, 'HIS LIGHT: Y GOES ON', true); return; }
  }
  var lost = pb && !pb.done ? (pb.charging ? ': CHARGE ENDS' : pb.kind === 'S' ? ': STRIKE ENDS' : ': ' + (BTN[pb.kind] ? BTN[pb.kind].name : 'BLOW') + ' ENDS') : ' LANDS';
  cancelOwn(w, P); P.blow = null; P.reel = b.w === 'heavy' ? 18 : 10; P.vx = sx * (b.w === 'heavy' ? 5 : 2); P.settle = 8;
  var c1 = chest(P); burst(w, c1[0] - sx * 10, c1[1], 10, 7, SPARK, 5); sound(w, 'blow'); note(w, (nm + lost).slice(0, 24));
}

// ---- energy: blasts on the buttons (RB), beams on the stick (RB) and the signature (RT) ----
function aimDeg(f) { var h = hand(f), c = chest(f.foe); var a = Math.atan2(c[1] - h[1], c[0] - h[0]) * 180 / Math.PI; return a < 0 ? a + 360 : a; }
function fire(w, f, k, lv) {
  var a = deg(aimDeg(f)), h = hand(f);
  if (k === 'bolt') w.shots.push({ k: 'bolt', o: f, x: h[0], y: h[1], vx: Math.cos(a) * 11, vy: Math.sin(a) * 11, sp: 11, t: 0, s: 6, born: w.t });
  else if (k === 'blast') w.shots.push({ k: 'blast', o: f, x: h[0], y: h[1], vx: Math.cos(a) * 8, vy: Math.sin(a) * 8, sp: 8, t: 0, s: 14 + 6 * lv, lv: lv, born: w.t });
  else { var cf = chest(f.foe), tx = cf[0], ty = cf[1], T = EN.lobT, g = 0.4; w.shots.push({ k: 'lob', o: f, x: h[0], y: h[1], vx: (tx - h[0]) / T, vy: ((ty - h[1]) + 0.5 * g * T * T) / T, g: g, t: 0, s: 9, born: w.t }); }
  if (f === w.P) note(w, { bolt: 'X: BOLT', lob: 'LOB', blast: lv ? 'BIG BLAST L' + lv : 'HEAVY BLAST' }[k], k !== 'bolt'); f.lean = 8; sound(w, 'bolt');
}
// the face's energy wind-ups: the lob, the heavy blast (held past 20 a bigger blast, two levels; in 4b the beam at him)
function shotStep(w, f) {
  var s = f.shotW; if (!s) return;
  var held = f === w.P && !!(w.inp && w.inp.B);
  if (s.k === 'lob') { if (w.t >= s.at) { f.shotW = null; fire(w, f, 'lob', 0); } return; }
  if (s.charging) {
    var c = w.t - s.start, lv = 0, b4 = w.pitch === '4b', L = b4 ? EN.beamLv.map(function (x) { return x - RS.settle; }) : EN.bigLv;
    for (var i = 0; i < L.length; i++) if (c >= L[i] && (!b4 || f.ki >= EN.beamKi[i + 1])) lv = i + 1; if (lv > s.lv) { s.lv = lv; sound(w, 'click'); }
    if (!held) {
      f.shotW = null; f.faceT = Math.max(f.faceT == null ? -99 : f.faceT, w.t);
      if (!b4) fire(w, f, 'blast', Math.min(2, s.lv));
      else if (!s.lv) nack(w, f, 'BEAM: NO KI');
      else { var lvb = s.lv, pl = f.sprint; f.ki -= EN.beamKi[lvb]; if (pl) { f.planted = true; f.sprint = false; } startBeam(w, f, aimDeg(f), lvb, false); note(w, 'LET GO: BEAM L' + lvb + (pl ? ': PLANTED' : '')); }
    }
    return;
  }
  if (w.t >= s.start + EN.blastHold && held) { s.charging = true; s.lv = 0; note(w, w.pitch === '4b' ? 'B HELD: THE BEAM' : 'B HELD: BIGGER BLAST', true); return; }
  if (w.t >= s.at && !held) { f.shotW = null; fire(w, f, 'blast', 0); }
}
// the energy stick: a quick request is the snap-beam after the heavy blast's wind-up; still out at D it charges (12, 30,
// 54), ki by level, and the release fires along the aim latched at the settle; released while sprinting, it plants him
function bchgStep(w, f) {
  var g = f.bchg; if (!g) return;
  if (!g.decided && w.t - g.t0 >= RS.D) {
    g.decided = true;
    if ((stillOut(w, g.src, g.gid) && !g.released) || heldPastD(g)) { g.charging = true; note(w, 'HELD: BEAM CHARGES'); if (g.released) { if (f.ki >= EN.beamKi[1]) g.lv = 1; fireBeam(w, f); return; } }
  }
  if (g.charging) {
    var c = w.t - g.t0, lv = 0; for (var i = 0; i < 3; i++) if (c >= EN.beamLv[i] && f.ki >= EN.beamKi[i + 1]) lv = i + 1;
    if (lv !== g.lv) { if (lv < g.lv) lv = g.lv; else { g.lv = lv; sound(w, 'click'); note(w, 'BEAM LEVEL ' + lv, true); if (lv === 3) f.flash = 8; } }
    return;
  }
  if (g.decided && w.t >= g.start + EN.snapWind) {
    f.bchg = null; if (f.ki < EN.snapKi) return nack(w, f, 'SNAP-BEAM: NO KI');
    f.ki -= EN.snapKi; startBeam(w, f, g.ang, 0, false); note(w, 'SNAP-BEAM');
  }
}
function fireBeam(w, f) {
  var g = f.bchg, lv = g.lv; f.bchg = null;
  if (!lv) { if (f.ki < EN.snapKi) return nack(w, f, 'BEAM: NO KI'); f.ki -= EN.snapKi; startBeam(w, f, g.ang, 0, false); note(w, 'LET GO: SNAP-BEAM (NO KI)'.slice(0, 24)); return; }
  f.ki -= EN.beamKi[lv];
  var planted = f.sprint; if (planted) { f.planted = true; f.sprint = false; }
  startBeam(w, f, g.ang, lv, false); f.beam.root = true; f.commit = Math.max(f.commit, LAW.L);
  note(w, 'LET GO: BEAM L' + lv + (planted ? ': PLANTED' : ''));
}
// the signature on RT + the stick (4c): a stick back before D fires nothing and costs nothing; held, refused at once when he
// can't pay; the hold aims it, the release fires it
function schgStep(w, f) {
  var g = f.schg; if (!g || g.held) { if (g && g.held) { var a = stickAng(w, g.src); if (a != null) g.ang = a; } return; }
  if (w.t - g.t0 >= RS.D) {
    var past = heldPastD(g);
    if ((!stillOut(w, g.src, g.gid) || g.released) && !past) { f.schg = null; f.castCue = 12; note(w, 'RT: HOLD TO CAST', true); return; }
    if (f.ki < EN.sigKi) { f.schg = null; nack(w, f, 'SIGNATURE: NO KI'); return; }
    if (past && g.released) { f.schg = null; f.ki -= EN.sigKi; startBeam(w, f, g.ang, 3, true); note(w, 'LET GO: SIGNATURE'); f.commit = Math.max(f.commit, LAW.L); return; }
    g.held = true; note(w, 'RT HELD: AIMING');
  }
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
        burst(w, s.x, s.y, 10, 7, s.o.def.L.bolt, 6); foe.reel = 8; cancelOwn(w, foe); note(w, 'HIS SHOT LANDS'); w.shots.splice(i, 1); continue;
      }
      var hs = { bolt: { dmg: 3, reel: 6, name: 'BOLT', w: 'light' }, lob: { dmg: 8, reel: 14, kb: 1, name: 'LOB', w: 'medium' }, blast: { dmg: 12 + 6 * (s.lv || 0), reel: 16, kb: 2.5 + (s.lv || 0), name: s.lv ? 'BIG BLAST' : 'BLAST', w: 'heavy' } }[s.k];
      burst(w, s.x, s.y, s.k === 'blast' ? 26 + 8 * (s.lv || 0) : 11, s.k === 'blast' ? 12 : 7, s.k === 'bolt' ? s.o.def.L.bolt : s.o.def.L.lob, 6); applyHit(w, s.o, foe, hs, null); w.shots.splice(i, 1); continue;
    }
    if (s.y <= 1 && (s.k !== 'bolt' || s.vy < 0)) { burst(w, s.x, 2, s.k === 'bolt' ? 9 : 22, s.k === 'bolt' ? 6 : 12, s.k === 'bolt' ? s.o.def.L.bolt : s.o.def.L.lob, 7); if (s.k !== 'bolt' && !overLake(s.x)) w.marks.push({ k: 'crater', x: s.x, w: 26 }); w.shots.splice(i, 1); continue; }
    if (s.x < -60 || s.x > AW + 40 || s.y > H + 60 || s.t > 200) w.shots.splice(i, 1);
  }
}
// a beam: out for its time by level, steered by the stick at his sweep rate while out (R25)
function startBeam(w, f, aDeg, lv, sig) {
  f.beam = { a: deg(aDeg), len: 0, t: 0, dur: sig ? EN.sigT : EN.beamT[lv], end: 0, lv: lv, sig: sig, root: sig || lv > 0 };
  f.tl.push({ t: w.t, k: 'P' }); sound(w, 'beam'); return true;
}
function beamStep(w, f) {
  var b = f.beam; if (!b) return;
  if (b.end) { b.end++; if (b.end > 9) f.beam = null; return; }
  b.t++;
  f.beamT = w.t;
  var sa = stickAng(w, w.rd.dpOn ? 'pad' : 'stick'); if (sa != null && b.t > 2 && b.t < b.dur && w.t >= (f.faceT == null ? -99 : f.faceT) + LAW.R - RS.settle) { var da = angN(deg(sa) - b.a), mx = deg(f.def.sweep / 60) * (b.sig ? 0.6 : 1); b.a += clamp(da, -mx, mx); }
  var h = hand(f), dx = Math.cos(b.a), dy = Math.sin(b.a), foe = f.foe, reach = 900;
  var fx = foe.x - h[0], fy = foe.y + 30 - h[1], along = fx * dx + fy * dy, off = Math.abs(fx * dy - fy * dx), half = beamW(f, b) / 2;
  var inLine = along > 0 && off < half + 12;
  for (var s = 0; s < 900; s += 6) { var x = h[0] + dx * s, yy = h[1] + dy * s; if (yy <= 0 || x < 0 || x > AW || yy > 330) { reach = Math.min(reach, s); break; } }
  if (inLine) reach = Math.min(reach, along);
  b.len = Math.min(b.len + 40, reach);
  if (inLine && b.len >= along - 1) {
    if (foe.guardT > 0 && !b.sig && b.lv === 0) { if (b.t % 6 === 1) note(w, 'GUARDED: SNAP-BEAM', true); }
    else {
      foe.reel = Math.max(foe.reel, 6); if (b.t % 6 === 1) { foe.hp = Math.max(0, foe.hp - (b.sig ? 4 : 1 + b.lv)); if (foe.hp <= 0) { foe.hp = 100; note(w, 'THE DUMMY RESETS', true); } }
      if (b.sig || b.lv >= 2) { foe.x += dx * (b.sig ? 3 : 1.6); foe.y = Math.max(0, foe.y + dy * (b.sig ? 3 : 1.6)); bound(foe); }
    }
    if (w.t % 5 === 0) chips(w, h[0] + dx * b.len, h[1] + dy * b.len, 1, (b.sig ? f.def.L.sig : f.def.L.beam).core, 3);
  }
  var ex = h[0] + dx * b.len, ey = h[1] + dy * b.len;
  if (ey <= 4 && b.len < 880) { var key = Math.round(ex / 12); if (!overLake(ex) && !w.marks.some(function (m) { return m.k === 'trench' && m.key === key; })) w.marks.push({ k: 'trench', key: key, x: key * 12, d: 3 + 2 * Math.max(1, b.lv) }); if (w.t % 2 === 0) chips(w, ex, 2, 1, overLake(ex) ? C.lakeLite : C.dirt, 3, true); }
  if (b.t >= b.dur) { b.end = 1; f.commit = Math.max(f.commit, LAW.L); }
}
function beamW(f, b) { return (b.sig ? 34 : b.lv === 0 ? 7 : 10 + 6 * b.lv) * f.def.bw; }

// ---- the Protagonist's tick ----
function fighterStep(w, f, inp, ev, evL) {
  var p = f.prev, pr = function (k) { return inp[k] && !p[k]; };
  f.reel = Math.max(0, f.reel - 1); f.lean *= 0.8; if (f.commit > 0) f.commit--; f.dodgeT = Math.max(0, f.dodgeT - 1); f.open = Math.max(0, f.open - 1);
  f.blinkT = Math.max(0, f.blinkT - 1); f.castCue = Math.max(0, f.castCue - 1); f.flash = Math.max(0, f.flash - 1);
  var charging = (f.blow && f.blow.charging) || (f.bchg && f.bchg.charging) || (f.schg && f.schg.held) || (f.shotW && f.shotW.charging);
  if (!(f.beam && !f.beam.end) && !charging) f.ki = Math.min(100, f.ki + 6 / 60);
  if (f.sway) { f.slipT++; if (f.slipT >= LEFT.slipT + 2) { f.sway = null; f.slipT = 0; } }
  if (f.brace && w.t >= f.brace.until) { f.brace = null; note(w, 'THE BRACE LAPSES', true); }
  if (!f.mv && !f.blow && !f.held && !f.bchg && !f.schg && !(f.beam && !f.beam.end)) f.dir = f.foe.x >= f.x ? 1 : -1;
  // a waiting press lives W ticks; one no longer possible (its shoulder let go) is dropped; each flickers (E3)
  if (f.q.length) { var live = f.q.filter(function (e) { return w.t - e.t <= LAW.W && (/^(X|Y|B|A)$/.test(e.k) || (e.k === 'SIG' || /^SP/.test(e.k) ? inp.RT : inp.RB)); }); for (var lq = live.length; lq < f.q.length; lq++) nack(w, f, 'A WAITING PRESS LAPSES'); f.q = live; }
  if (f.caught > 0) { f.caught--; if (pr('LB')) f.lbT = w.t; if (pr('LT')) f.ltT = w.t; if (pr('X') || pr('Y') || pr('B') || pr('A') || pr('LT') || pr('LB') || ev.req) nack(w, f, 'CAUGHT: NOT READY'); f.prev = { RB: inp.RB, LB: inp.LB, LT: inp.LT, RT: inp.RT, X: inp.X, Y: inp.Y, B: inp.B, A: inp.A }; return; }
  if (pr('X') || pr('Y') || pr('B') || pr('A')) f.tl.push({ t: w.t, k: 'X' });
  leftHand(w, f, inp, evL);
  rightStick(w, f, inp, ev);
  // the face buttons (K1: on a tied tick the press goes first, so they come before the stick acts); RT holds the power
  // layer, RB the energy layer, else the martial moves
  if (inp.RT) { if (pr('B')) facePress(w, f, 'SIG', inp); if (pr('X')) facePress(w, f, 'SP1', inp); if (pr('Y')) facePress(w, f, 'SP2', inp); if (pr('A')) facePress(w, f, 'SP3', inp); }
  else if (inp.RB) { if (pr('X')) facePress(w, f, 'BOLT', inp); if (pr('Y')) facePress(w, f, 'LOB', inp); if (pr('B')) facePress(w, f, 'BLAST', inp); if (pr('A')) facePress(w, f, 'A', inp); }
  else { ['X', 'Y', 'B', 'A'].forEach(function (k) { if (pr(k)) facePress(w, f, k, inp); }); }
  var bd = f.blow; if (bd && !bd.charging && !bd.done && !(bd.holdable && !bd.decided) && w.t >= bd.contactAt && !rushing(f)) { bd.done = true; bd.hitT = w.t; contact(w, f, bd); }
  stickActs(w, f, inp);
  if (f.q.length && !busy(f, w) && !k3(w, f) && w.t >= qEff(w, f, f.q[0])) { var qq = f.q.shift(); if (doPress(w, f, qq.k, inp, qq)) note(w, 'QUEUED ' + QN[qq.k] + ' STARTS', true); else nack(w, f, 'QUEUED ' + QN[qq.k] + ' DROPPED'); }
  // motion: a tween (a rush, a slip), else flight on the left stick (rooted by a blow, a charged beam out, a dodge's gather)
  if (f.sway === 'up') { var sk = Math.sin(Math.PI * Math.min(1, f.slipT / LEFT.slipT)); f.swayY = sk * 0.9 * BH; } else f.swayY = 0;
  if (f.mv) { var m = f.mv; m.t++; var k = m.k === 'rush' ? clamp(m.t / m.dur, 0, 1) : easeIO(m.t / m.dur), ox = f.x, oy = f.y; f.x = lerp(m.x0, m.x1, k); f.y = lerp(m.y0, m.y1, k); f.vx = f.x - ox; f.vy = f.y - oy; f.lean = m.k === 'rush' ? 18 : 0; if (m.t >= m.dur) { f.mv = null; f.vx = f.vy = 0; } }
  else {
    var b0 = f.blow, rooted = (b0 && !b0.charging && !blowFree(w, f)) || (f.beam && !f.beam.end && f.beam.root) || f.held > 0 || !!f.dodge || (f.dodgeT > 0 && !f.sway) || f.open > 0;
    var sp = MOVE.flight * (f.sprint ? MOVE.sprint : 1) * (f.guard ? MOVE.guardMove : 1) * (charging ? MOVE.chargeMove : 1);
    if (!rooted && Math.sqrt((inp.lx || 0) * (inp.lx || 0) + (inp.ly || 0) * (inp.ly || 0)) > LEFT.flightDead) { f.vx = (inp.lx || 0) * sp; f.vy = -(inp.ly || 0) * sp; f.x += f.vx; f.y += f.vy; }
    else if (f.settle > 0) { f.settle--; f.vx *= 0.75; f.vy *= 0.75; f.x += f.vx; f.y += f.vy; }
    else { f.vx = 0; f.vy = 0; }
  }
  blowStep(w, f); bchgStep(w, f); schgStep(w, f); shotStep(w, f); beamStep(w, f);
  // holding him: then the throw, away from you
  if (f.held > 0) { f.held--; f.foe.x = f.x + f.dir * 34; f.foe.y = f.y; if (f.held === 0) { applyHit(w, f, f.foe, { dmg: BTN.A.dmg, reel: 14, kb: 3.5, name: 'THE THROW', w: 'grab' }, null); f.foe.caught = 0; } }
  bound(f);
  f.prev = { RB: inp.RB, LB: inp.LB, LT: inp.LT, RT: inp.RT, X: inp.X, Y: inp.Y, B: inp.B, A: inp.A };
}

// ---- the Rival: a training dummy with his own blows (a light, a medium at three heights, a heavy, a flurry, a grab, shots)
// and a guard; he reels, is stunned, launched and knocked down; a whiff leaves him open; in Play he closes in and throws
// them in turn ----
var RIVAL = { jab: { w: 'light', wind: 2, rec: 6 }, blow: { w: 'medium', wind: 12, rec: 10 }, heavy: { w: 'heavy', wind: 28, rec: 14 }, flurry: { w: 'light', wind: 4, rec: 4 } };
function rivalBlow(w, f, k, h) { var R0 = RIVAL[k]; f.blow = { t: 0, kind: 'V', w: R0.w, h: h || 'mid', wind: R0.wind, rec: R0.rec, commit: R0.wind + R0.rec, start: w.t, contactAt: w.t + R0.wind, done: false, fl: k === 'flurry', t0: w.t, face: f.dir }; if (k === 'heavy') note(w, 'HE WINDS A HEAVY', true); }
function rivalStep(w, f, o) {
  f.dir = f.foe.x >= f.x ? 1 : -1; f.grabLock = Math.max(0, f.grabLock - 1);
  if (f.reel > 0) f.reel--; if (f.stun > 0) f.stun--; if (f.down > 0) f.down--; if (f.open > 0) f.open--; if (f.guardT > 0) f.guardT--;
  if (f.caught > 0) { if (!f.foe.held) f.caught--; return; }
  // knocked: flying, then the ground; on the ground he slides
  if (f.air) { f.x += f.vx; f.y += f.vy; f.vy -= 0.5; if (f.y <= 0) { f.y = 0; if (f.spiked) { f.spiked = false; f.down = 22; f.vy = 0; f.vx *= 0.4; burst(w, f.x, 2, 16, 9, SPARK, 6); chips(w, f.x, 2, 5, overLake(f.x) ? C.lakeLite : C.dirt, 3, true); } else if (f.vy < -6) { f.vy = -f.vy * 0.3; } else { f.vy = 0; f.air = false; } } }
  else if (Math.abs(f.vx) > 0.05) { f.x += f.vx; f.vx *= 0.88; } else f.vx = 0;
  var out = f.reel > 0 || f.stun > 0 || f.down > 0 || f.air;
  if (out) { if (f.blow && !f.blow.done) f.blow = null; f.flurry = null; f.guardT = 0; }
  else {
    if (w.mode === 'play') {
      var d = bhOf(f), ph = w.t % 420;
      if (d > 1.6) { var g = spotAt(f, 1.2); f.x += clamp(g[0] - f.x, -1.4, 1.4); f.y += clamp(g[1] - f.y, -1.4, 1.4); if (ph === 360 && d > 5) o.fire = true; }
      else if (!f.blow && !f.flurry && f.open === 0) { if (ph === 40) o.jab = true; else if (ph === 80) o.blow = 'mid'; else if (ph === 130) o.heavy = true; else if (ph === 200) o.blow = 'low'; else if (ph === 240) o.guard = 50; else if (ph === 300) o.flurry = true; else if (ph === 350) o.blow = 'high'; else if (ph === 390) o.grab = true; }
    }
    var free = !f.blow && f.open === 0;
    if (o.jab && free) rivalBlow(w, f, 'jab');
    if (o.blow && free) rivalBlow(w, f, 'blow', o.blow === true ? 'mid' : o.blow);
    if (o.heavy && free) rivalBlow(w, f, 'heavy');
    if (o.guard && f.open === 0 && !f.blow) { f.guardT = o.guard === true ? 40 : o.guard; }
    if (o.flurry && !f.flurry) f.flurry = { n: 0, next: w.t, start: w.t };
    if (f.flurry && w.t >= f.flurry.next && !f.blow && f.open === 0) { rivalBlow(w, f, 'flurry'); f.blow.start = f.flurry.start; f.flurry.n++; f.flurry.next = w.t + 8; if (f.flurry.n >= 4) f.flurry = null; }
    if (o.grab && !f.grabLock && !w.grabs.length) { var hg = hand(f); w.grabs.push({ o: f, x: hg[0], y: hg[1], t: 0, T: 24, born: w.t }); f.grabLock = 90; note(w, 'HE THROWS A GRAB', true); }
    if (o.gx != null || o.gy != null) { var gx = o.gx == null ? f.x : o.gx, gy = o.gy == null ? f.y : o.gy, dx = gx - f.x, dy = gy - f.y, l = Math.sqrt(dx * dx + dy * dy), sp = o.gs || 2.5; if (l > 1) { f.x += dx / l * Math.min(sp, l); f.y += dy / l * Math.min(sp, l); } }
    if (o.fire) { var h = hand(f), c = chest(f.foe), a = Math.atan2(c[1] - h[1], c[0] - h[0]), sp2 = o.fireSp || 7; w.shots.push({ k: 'bolt', o: f, x: h[0], y: h[1], vx: Math.cos(a) * sp2, vy: Math.sin(a) * sp2, sp: sp2, t: 0, s: 6, born: w.t }); }
  }
  var b = f.blow;
  if (b) { b.t++; if (!b.done && w.t >= b.contactAt) { b.done = true; b.hitT = w.t; contact(w, f, b); } if (f.blow && f.blow.done && w.t >= f.blow.hitT + f.blow.rec) f.blow = null; }
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
  var mag = Math.sqrt((P.rx || 0) * (P.rx || 0) + (P.ry || 0) * (P.ry || 0)), inNow = mag > RS.deadZone || (w.mirror && (dp.x || dp.y));
  if (inNow && !w.inWas) w.P.tl.push({ t: w.t, k: 'I' }); w.inWas = inNow;
  var ev = readRight(w.rd, w.t, P.rx || 0, P.ry || 0, P, dp, w.mirror), evL = readLeft(w.rdL, w.t, P.lx || 0, P.ly || 0);
  fighterStep(w, w.P, P, ev, evL); rivalStep(w, w.V, ip.V || {});
  shotsStep(w); grabsStep(w); fxStep(w);
  [w.P, w.V].forEach(function (f) { if (f.tl.length > 64) f.tl.splice(0, f.tl.length - 64); }); if (w.marks.length > 60) w.marks.splice(0, w.marks.length - 60);
  w.t++;
}
