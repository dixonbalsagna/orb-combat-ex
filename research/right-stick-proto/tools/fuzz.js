// Play-mode fuzzer (from fuzz6, rs-fuzz2 and the fuzz2/fuzz5 input mixes): seeded random pad input in Play, against the
// rival's Play script or a rival driven to grab, swing and fly about the cliff. Every tick is drawn through a checking stub
// and held to invariants: no throw, no NaN, inside the arena and out of the rock, no stranded plan or stuck state, bounded
// queues and lists, each step no longer than its own move's step (the cliff), and determinism (a fresh sim, and the same
// module again). The law's part: every refusal and every dropped or replaced flick flickers in his hand, a waiting flick is
// never cleared silently, and it waits no longer than W + 2L. Every clip is also played and drawn once.
// node fuzz.js [mix|all] [seeds] [ticks] [seed0]
'use strict';
const H = require('./harness.js');
const MIX = process.argv[2] || 'all', SEEDS = +(process.argv[3] || 50), TICKS = +(process.argv[4] || 4000), SEED0 = +(process.argv[5] || 1);
function mulberry32(a) { return function () { a |= 0; a = a + 0x6D2B79F5 | 0; let t = Math.imul(a ^ a >>> 15, 1 | a); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
// button toggle odds per tick, and the right stick's moods (rest, flick, hold up to holdMax ticks, noise); V: the rival's kind
const BASE = { LB: 0.015, RB: 0.015, LT: 0.06, X: 0.12, Y: 0.03, B: 0.03, du: 0.02, dd: 0.02, dl: 0.02, dr: 0.02, rest: 0.3, flick: 0.3, hold: 0.25, holdMax: 90, off: 0.25 };
const HOLD = { LB: 0.02, RB: 0.03, LT: 0.04, X: 0.1, Y: 0.03, B: 0.03, du: 0.005, dd: 0.005, dl: 0.005, dr: 0.005, rest: 0.15, flick: 0.1, hold: 0.7, holdMax: 300, off: 0.4 };
const MASH = { LB: 0.04, RB: 0.04, LT: 0.1, X: 0.9, Y: 0.5, B: 0.5, du: 0.03, dd: 0.03, dl: 0.03, dr: 0.03, rest: 0.3, flick: 0.4, hold: 0.2, holdMax: 60, off: 0.8 };
const LTHOLD = { LB: 0.01, RB: 0.01, LT: 0.03, X: 0.1, Y: 0.02, B: 0.02, du: 0.02, dd: 0.02, dl: 0.02, dr: 0.02, rest: 0.25, flick: 0.35, hold: 0.3, holdMax: 120, off: 0.02 };
const PEND = { LB: 0.05, RB: 0.06, LT: 0.02, X: 0.35, Y: 0.15, B: 0.1, du: 0.06, dd: 0.06, dl: 0.06, dr: 0.06, rest: 0.45, flick: 0.45, hold: 0.08, holdMax: 40, off: 0.5 };
const CHARGE = { LB: 0.01, RB: 0.1, LT: 0.02, X: 0.25, Y: 0.25, B: 0.12, du: 0.01, dd: 0.01, dl: 0.01, dr: 0.01, rest: 0.3, flick: 0.35, hold: 0.25, holdMax: 80, off: 0.06 };
const w_ = (m, V) => Object.assign({}, m, { V });
const MIXES = { base: BASE, hold: HOLD, mash: MASH, lthold: LTHOLD, pend: PEND, charge: CHARGE,
  shoulder: { LB: 0.06, RB: 0.08, LT: 0.03, X: 0.2, Y: 0.1, B: 0.1, du: 0.01, dd: 0.01, dl: 0.01, dr: 0.01, rest: 0.25, flick: 0.4, hold: 0.25, holdMax: 120, off: 0.03 },
  lt: { LB: 0.01, RB: 0.01, LT: 0.3, X: 0.15, Y: 0.02, B: 0.02, du: 0.01, dd: 0.01, dl: 0.01, dr: 0.01, rest: 0.3, flick: 0.35, hold: 0.25, holdMax: 80, off: 0.3 },
  dpad: { LB: 0.03, RB: 0.03, LT: 0.03, X: 0.12, Y: 0.04, B: 0.04, du: 0.08, dd: 0.08, dl: 0.08, dr: 0.08, rest: 0.4, flick: 0.3, hold: 0.2, holdMax: 60, off: 0.15 },
  catch: w_(BASE, 'catch'), catchpend: w_(PEND, 'catch'), catchcharge: w_(CHARGE, 'catch'),
  cliff: w_(BASE, 'cliff'), cliffhold: w_(HOLD, 'cliff'), cliffmash: w_(MASH, 'cliff'), cliffcatch: w_(LTHOLD, 'cliffcatch') };
function genInputs(seed, n, M) {
  const r = mulberry32(seed * 7919 + 13), out = [], btn = { LB: 0, RB: 0, LT: 0, X: 0, Y: 0, B: 0, du: 0, dd: 0, dl: 0, dr: 0 };
  const rs = { mode: 'rest', left: 0, a: 0, m: 0, spin: 0 }, ls = { left: 0, x: 0, y: 0 };
  for (let t = 0; t < n; t++) {
    if (rs.left-- <= 0) {
      const u = r(); rs.a = r() * 2 * Math.PI; rs.spin = r() < 0.5 ? 0 : (r() - 0.5) * 0.15;
      if (r() < 0.5) rs.a = Math.round(rs.a / (Math.PI / 2)) * Math.PI / 2;
      if (u < M.rest) { rs.mode = 'rest'; rs.left = 1 + (r() * 30 | 0); } else if (u < M.rest + M.flick) { rs.mode = 'flick'; rs.left = 1 + (r() * 7 | 0); rs.m = 0.65 + r() * 0.35; }
      else if (u < M.rest + M.flick + M.hold) { rs.mode = 'hold'; rs.left = 10 + (r() * M.holdMax | 0); rs.m = 0.4 + r() * 0.6; } else { rs.mode = 'noise'; rs.left = 3 + (r() * 30 | 0); }
    }
    let rx = 0, ry = 0;
    if (rs.mode === 'flick' || rs.mode === 'hold') { rs.a += rs.mode === 'hold' ? rs.spin : 0; rx = Math.cos(rs.a) * rs.m; ry = Math.sin(rs.a) * rs.m; } else if (rs.mode === 'noise') { rx = r() * 2 - 1; ry = r() * 2 - 1; }
    if (ls.left-- <= 0) { const u = r(); ls.left = 3 + (r() * 60 | 0); if (u < 0.4) { ls.x = 0; ls.y = 0; } else if (u < 0.8) { const a = (r() * 4 | 0) * Math.PI / 2; ls.x = Math.round(Math.cos(a)); ls.y = Math.round(Math.sin(a)); } else { ls.x = Math.round((r() * 2 - 1) * 4) / 4; ls.y = Math.round((r() * 2 - 1) * 4) / 4; } }
    for (const k in btn) if (r() < (btn[k] ? M.off : M[k])) btn[k] ^= 1;
    const o = { rx, ry, lx: ls.x, ly: ls.y }; for (const k in btn) o[k] = !!btn[k]; out.push(o);
  }
  return out;
}
// the rival's orders: 'catch' grabs often and swings; 'cliff' flies about the cliff's corner (P starts there too)
function genV(seed, n, kind) {
  if (!kind) return null;
  const r = mulberry32(seed * 104729 + 7), out = []; let gx = null, gy = null, left = 0, gs = 2;
  for (let t = 0; t < n; t++) {
    const o = {};
    if (kind === 'catch' || kind === 'cliffcatch') { if (r() < 1 / 40) o.grab = true; const u = r(); if (u < 0.01) o.blow = ['mid', 'high', 'low'][r() * 3 | 0]; else if (u < 0.016) o.heavy = true; else if (u < 0.02) o.flurry = true; else if (u < 0.024) o.fire = true; }
    if (kind === 'cliff' || kind === 'cliffcatch') {
      if (left-- <= 0) { left = 10 + (r() * 70 | 0); const u = r(); gs = 1 + r() * 4; if (u < 0.45) { gx = 560 + r() * 86; gy = r() * 199; } else if (u < 0.75) { gx = 660 + r() * 42; gy = 200 + r() * 70; } else if (u < 0.9) { gx = 600 + r() * 100; gy = 150 + r() * 120; } else { gx = null; gy = null; } }
      if (gx != null) { o.gx = gx; o.gy = gy; o.gs = gs; } if (r() < 0.01) o.fire = true;
    }
    out.push(o);
  }
  return out;
}
function setupFor(seed, kind) {
  if (!kind || kind === 'catch') return null;
  const r = mulberry32(seed * 31337 + 3);
  return (w) => { if (r() < 0.5) { w.P.x = 660 + r() * 42; w.P.y = 200 + r() * 70; } else { w.P.x = 560 + r() * 86; w.P.y = r() * 199; }
    if (r() < 0.5) { w.V.x = 560 + r() * 86; w.V.y = r() * 199; } else { w.V.x = 660 + r() * 42; w.V.y = 200 + r() * 70; } w.V.home = [w.V.x, w.V.y]; };
}
const num = (v) => (typeof v === 'number' ? (Number.isFinite(v) ? Math.round(v * 1e9) / 1e9 : 'BAD' + v) : v);
const snapF = (F) => [F.x, F.y, F.vx, F.vy, F.ki, F.cmd, F.commit, F.q.map((e) => e.k + e.t).join(','), F.dodgeT, F.sway, F.slipT, F.read && F.read.k + F.read.t0, F.caught, F.blow && F.blow.t, F.mv && F.mv.k + F.mv.t + '/' + F.mv.dur, F.cross && F.cross.t, F.reel, F.aimOff, F.beam && [F.beam.a, F.beam.len, F.beam.t, F.beam.end], F.bchg && [F.bchg.t, F.bchg.fresh], F.seq && F.seq.length, F.wait, F.spent, F.settle, F.layOff, F.latched, F.pend && JSON.stringify(F.pend), F.faceT, F.stickT, F.orbit && [F.orbit.a, F.orbit.done], F.tl.length, F.lag].map(num);
const snap = (w) => JSON.stringify([w.t, snapF(w.P), snapF(w.V), w.shots.map((s) => [s.x, s.y, s.vx, s.vy].map(num)), w.grabs.map((g) => [g.x, g.y, g.t].map(num)), w.mines.map((m) => [m.x, m.y, m.t].map(num)), w.fx.length, w.marks.length, !!w.brawl, w.rd.log.map((e) => e.t + e.text), w.sound.join()]);
const AW = 720, CX = 646, CY = 200, EPS = 0.5, BH = 56, L = H.LAW.L, W = H.LAW.W;
const T = H.tally(), MAX = {}, COUNT = {};
const mx = (k, v, where) => { if (!MAX[k] || v > MAX[k].v) MAX[k] = { v, where }; };
const cnt = (k) => { COUNT[k] = (COUNT[k] || 0) + 1; };
function mkRun(S, setup) { const w = S.newWorld(null, 0, 'play'); if (setup) setup(w); return { clip: null, w, t: 0, take: 0, off: 0 }; }
function runSeed(mix, seed, TICKS) {
  const M = MIXES[mix], S = H.load({ cliff: true }), ins = genInputs(seed, TICKS, M), vins = genV(seed, TICKS, M.V), errs = [];
  const run = mkRun(S, setupFor(seed, M.V)), seen = new Set(), snaps = [], age = {}, A = (k, c) => (age[k] = c ? (age[k] || 0) + 1 : 0);
  let tag = () => '', lastId = null, lastFree = null, pendObj = null, pendSince = 0, pendFam, head = null;
  const R = H.stubR(errs, () => tag()), bad = (k, t, d) => T.add(k, `${mix} seed ${seed} t ${t}: ${d}`);
  for (let t = 0; t < TICKS; t++) {
    const w = run.w, P = w.P, V = w.V, p0 = [P.x, P.y], caught0 = P.caught, mv0 = P.mv, fx0 = new Set(w.fx), k = ins[t];
    P._log = [];
    try { S.stepWorld(w, { P: Object.assign({}, k), V: vins ? Object.assign({}, vins[t]) : {} }); } catch (e) { bad('EXCEPTION step', t, e.stack.split('\n').slice(0, 3).join(' / ')); return; }
    const now = w.t - 1; tag = () => `${mix} seed ${seed} t ${now}`;
    try { S.draw(run, R); } catch (e) { bad('EXCEPTION draw', now, e.stack.split('\n').slice(0, 3).join(' / ')); return; }
    if (errs.length) { bad('DRAW', now, errs[0]); errs.length = 0; }
    snaps.push(snap(w));
    const notes = []; for (let i = w.rd.log.length - 1; i >= 0; i--) { const e = w.rd.log[i]; if (!seen.has(e)) { seen.add(e); notes.push(e.text); } }
    // the law: a refusal, a dropped or replaced flick each flicker in his hand; a waiting flick is never cleared silently
    const acks = w.fx.filter((e) => e.k === 'ack' && e.f === P && !fx0.has(e)).length, nacks = notes.filter((n) => /NOT READY|QUEUE FULL|A QUEUED PRESS LAPSES|QUEUED \w+ DROPPED|FLICK (DROPPED|REPLACED)/.test(n));
    for (const n of nacks) cnt(n.replace(/QUEUED \w+ DROPPED/, 'QUEUED * DROPPED'));
    if (nacks.length && !acks) bad('a refusal with no flicker in his hand (E3)', now, nacks.join(' | '));
    if (P.pend !== pendObj) {
      if (pendObj) { const waited = now - pendSince; mx('a flick waits (ticks)', waited, `${mix} ${seed} ${now}`); if (waited > W + 2 * L) bad(`a flick waits more than W + 2L (${W + 2 * L}) ticks`, now, `${waited} ticks, from ${pendSince}`);
        if (!P.pend && !nacks.some((n) => /^FLICK/.test(n)) && !notes.some((n) => /^(FLICK|LAY|READ|PRESS UNDER|MOVE UNDER|CHARGING|NOTHING|NO KI)/.test(n)) && !P.caught && !P.beam) {
          const why = notes.some((n) => /^LT/.test(n)) ? 'a slip' : pendFam == null ? 'its family never read' : (pendFam === 'aim' && !k.RB) || (pendFam === 'read' && !k.LB) ? 'its shoulder let go' : 'other';
          bad(`a waiting flick cleared with no ack (item 14): ${why}`, now, `waiting since ${pendSince}: ${notes.join(' | ') || 'no note'}`);
        } }
      pendObj = P.pend || null; pendSince = now; pendFam = P.pend && P.pend.fam;
    }
    if (P.pend && P.caught) bad('a flick still waits through a catch', now, JSON.stringify(P.pend));
    // state
    for (const [nm, F] of [['P', P], ['V', V]]) {
      for (const key of ['x', 'y', 'vx', 'vy', 'ki', 'commit', 'dodgeT', 'aimOff', 'reel', 'settle', 'lean']) if (!Number.isFinite(F[key])) bad('NaN ' + nm + '.' + key, now, F[key]);
      if (F.x < 18 - EPS || F.x > AW - 18 + EPS || F.y < -EPS || F.y > 270 + EPS) bad('out of the arena ' + nm, now, F.x.toFixed(1) + ',' + F.y.toFixed(1));
      if (F.y < CY - 1e-6 && F.x > CX + EPS) bad('inside the rock ' + nm, now, F.x.toFixed(2) + ',' + F.y.toFixed(2));
    }
    for (const s of w.shots) if (![s.x, s.y, s.vx, s.vy].every(Number.isFinite)) bad('NaN shot', now, s.k);
    if (P.ki < 0 || P.ki > 100 + 1e-9) bad('ki out of 0..100', now, P.ki.toFixed(2));
    if (P.q.length > H.LAW.qMax) bad('queue deeper than 3', now, P.q.length);
    if (P.q.some((e) => now - e.t > W)) bad('a queued press older than W', now, P.q.map((e) => e.k + '@' + e.t).join(','));
    if (P.read && now > P.read.until) bad('a read past its 90', now, JSON.stringify(P.read));
    if (P.caught > 40 || P.dodgeT > 12 || P.commit > 90) bad('a counter out of range', now, `caught ${P.caught} dodge ${P.dodgeT} commit ${P.commit}`);
    const idle = !w.rd.on && !w.rd.dpOn;
    if (A('spent', P.spent && idle) > 1) bad('spent stuck with the stick at rest', now, P.cmd);
    if (A('cmd', P.cmd && P.cmd !== 'sweepLeft' && idle && !P.caught) > 2) bad('a hold command stuck with the stick at rest', now, P.cmd);
    if (A('bchg', P.bchg && (!k.B || !k.RB)) > 1) bad('a charge stuck after B or RB let go', now, JSON.stringify(P.bchg));
    if (A('strand', P.seq && !P.mv && !P.wait && !P.blow && !P.cross && !P.caught) > 1) bad('a plan stranded: steps left with nothing running', now, JSON.stringify(P.seq.map((s) => s.k)));
    if (P.mv && P.cross) bad('a move and the arc both set', now, P.mv.k);
    if (P.q[0] !== head) { head = P.q[0]; age.stuckQ = age.stuckQB = 0; }     // the head moved on: not stuck
    if (A('stuckQ', P.q.length && !S.busy(P) && !P.caught && P.q[0].k !== 'BOLT') > 2) bad('the queue head never starts while he is free', now, P.q.map((e) => e.k + '@' + e.t).join(','));
    if (A('stuckQB', P.q.length && !S.busy(P) && !P.caught && P.q[0].k === 'BOLT') > 7) bad('a queued bolt never starts while he is free', now, P.q.map((e) => e.k + '@' + e.t).join(','));
    if (A('commit', P.commit > 0 && !P.caught) > 92) bad('a commitment stuck', now, P.commit);
    if (w.grabs.length > 1) bad('two grabs at once', now, w.grabs.length);
    if (w.brawl && S.bhOf(P) > 4.5 + 1e-9) bad('a brawl on while apart', now, S.bhOf(P).toFixed(2));
    if (P.layOff && !(k.LB && k.RB) && !caught0) bad('a lay kept without both shoulders', now, JSON.stringify(P.layOff));
    if (P.latched && !k.RB && !P.caught && !caught0) bad('the aim line latched without RB', now, '');
    // the cliff: each step against its own move's free step (from the rock() calls), and a tween that ends short of an end
    // he could reach (from below the top the face stops him, by the README's rule)
    if (!caught0) {
      const act = Math.hypot(P.x - p0[0], P.y - p0[1]); let free = null; const srcs = [];
      for (const e of P._log) if (e.k === 'rock') { const ref = e.id && e.id === lastId && lastFree ? lastFree : e.o; free = (free || 0) + Math.hypot(e.free[0] - ref[0], e.free[1] - ref[1]); srcs.push(e.src); if (e.id) { lastId = e.id; lastFree = e.free; } }
      if (!P._log.some((e) => e.k === 'rock' && e.id)) { lastId = null; lastFree = null; }
      const what = srcs.join('+') || P.cmd || 'none';
      if (free != null) { mx('a step over its own move\'s step (px)', act - free, `${mix} ${seed} ${now} ${what}`); if (act - free > 15 && act > 0.6 * BH) bad('a snap: a step 15 px or more past its own move\'s step', now, `${act.toFixed(1)} vs ${free.toFixed(1)} (${what})`); }
      else if (act > 12) bad('a step of more than 12 px with no rock() call', now, `${act.toFixed(1)} px (${what})`);
      if (mv0 && P.mv !== mv0 && mv0.t >= mv0.dur && !P.caught && !(P.mv && P.mv.fin && P.mv.x1 === mv0.x1 && P.mv.y1 === mv0.y1) && !(mv0.y1 < CY && mv0.x1 > CX) && !(mv0.y0 < CY && mv0.x1 > CX) && mv0.x1 >= 18 && mv0.x1 <= AW - 18 && mv0.y1 >= 0 && mv0.y1 <= 270 && Math.hypot(P.x - mv0.x1, P.y - mv0.y1) > 20) bad('a tween ends more than 20 px short of its end', now, `${mv0.k} at ${P.x.toFixed(1)},${P.y.toFixed(1)}, end ${mv0.x1.toFixed(1)},${mv0.y1.toFixed(1)}`);
    }
    mx('fx', w.fx.length, mix + ' ' + seed); mx('shots', w.shots.length, mix + ' ' + seed); mx('mines', w.mines.length, mix + ' ' + seed); mx('tl', P.tl.length, ''); mx('marks', w.marks.length, '');
  }
  // determinism: the same inputs through a fresh sim, and through this module again
  for (const [nm, S2] of [['a fresh sim', H.load({ cliff: true })], ['the same module', S]]) {
    const run2 = mkRun(S2, setupFor(seed, M.V));
    for (let t = 0; t < TICKS; t++) { S2.stepWorld(run2.w, { P: Object.assign({}, ins[t]), V: vins ? Object.assign({}, vins[t]) : {} }); if (snap(run2.w) !== snaps[t]) { bad('NONDETERMINISM, ' + nm, t, ''); break; } }
  }
}
function clips() {
  const S = H.load(), errs = [], R = H.stubR(errs, () => 'clip');
  S.CLIPS.forEach((c) => { try { const run = S.newRun(S.CLIPS.indexOf(c), 'demo'), n = S.clipLen(c); for (let t = 0; t < n; t++) { S.stepRun(run); S.draw(run, R); } } catch (e) { T.add('a clip throws', c.n + ' ' + e.message); } if (errs.length) { T.add('a clip draws badly', c.n + ' ' + errs[0]); errs.length = 0; } });
  return S.CLIPS.length;
}
function main(mix, seeds, ticks, seed0) {
  const mixes = mix === 'all' ? Object.keys(MIXES) : mix.split(','), t0 = Date.now();
  for (const m of mixes) for (let s = seed0; s < seed0 + seeds; s++) runSeed(m, s, ticks);
  const nc = clips();
  T.print(4);
  for (const k in MAX) console.log('  MAX', k, MAX[k].v.toFixed(2), MAX[k].where);
  console.log('  COUNT', JSON.stringify(COUNT));
  const n = Object.values(T.m).reduce((a, e) => a + e.n, 0);
  console.log(`fuzz: ${mixes.length} mixes x ${seeds} seeds x ${ticks} ticks, ${nc} clips drawn, ${n} breaches, ${((Date.now() - t0) / 1000).toFixed(0)} s`);
  return { breaches: n };
}
if (require.main === module) { H.below(); process.exitCode = main(MIX, SEEDS, TICKS, SEED0).breaches ? 1 : 0; }
module.exports = { main: (seeds, ticks) => main('all', seeds, ticks, 1) };
