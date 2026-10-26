// The review harness for right-stick v2: loads the sim, runs scripted takes, and reads each tick back as events.
// The sim is docs/ep/prototypes/right-stick-v2.html between its "STICK SIM" and "PAGE" markers. RS_SIM=<file> points at
// another copy (an .html with the markers, or a .js that defines S), for the Godot port's parity runs or a fix candidate.
// The timing checkers patch nothing: they read the debug feed (the notes), the timeline marks and the fighter's state, so
// a port that keeps the API (CLIPS, newRun, stepRun), the note texts and those fields can be checked unchanged.
'use strict';
const fs = require('fs'), path = require('path'), os = require('os');
const REPO = path.resolve(__dirname, '../../..');
const SIM = process.env.RS_SIM ? path.resolve(process.env.RS_SIM) : path.join(REPO, 'docs/ep/prototypes/right-stick-v2.html');
const MA = '// ==== STICK SIM (no DOM) ====', MB = '// ==== PAGE (DOM) ====';

// the law's numbers (docs/controls/right-thumb.md section 3, rulings-2026-10-26 items 13 to 16), not the sim's own
const LAW = { L: 6, W: 36, settle: 2, hold: 10, rise: 3, qMax: 3 };

function below() { try { os.setPriority(0, os.constants.priority.PRIORITY_BELOW_NORMAL); } catch (e) { /* not allowed: run as is */ } }
function simText() { const s = fs.readFileSync(SIM, 'utf8'), a = s.indexOf(MA), b = s.indexOf(MB); return s.slice(a < 0 ? 0 : a, b < 0 ? s.length : b); }
// each hook's anchor must occur exactly once, so a changed sim fails loudly instead of measuring the wrong thing
function patch(t, hooks) {
  for (const [from, to] of hooks) { const i = t.indexOf(from); if (i < 0 || t.indexOf(from, i + 1) >= 0) throw new Error((i < 0 ? 'hook not found: ' : 'hook not unique: ') + from.slice(0, 80)); t = t.slice(0, i) + to + t.slice(i + from.length); }
  return t;
}
// the cliff checkers' hooks (fuzz, cliff, settle): internals exposed, and each rock() and bound() call recorded on f._log
// with the move that made its free target. Recording only: no behaviour changes.
const CLIFF_HOOKS = [
  ['return { W: W, H: H,', 'return { newWorld: newWorld, stepWorld: stepWorld, busy: busy, holdOn: holdOn, bhOf: bhOf, BH: BH, CLIFF: CLIFF, W: W, H: H,'],
  ['function bound(f) {', 'function bound(f) { var _x = f.x, _y = f.y; bound0(f); if (f._log) f._log.push({ k: "bound", from: [_x, _y], to: [f.x, f.y] }); }\nfunction bound0(f) {'],
  ['function rock(f, ox, oy, cap) {', 'function rock(f, ox, oy, cap) { var _x = f.x, _y = f.y, _lag = f.lag; rock0(f, ox, oy, cap); if (f._log) f._log.push({ k: "rock", o: [ox, oy], free: [_x, _y], cap: cap, lag0: !!_lag, to: [f.x, f.y], id: f._mvid, src: f._src }); f._mvid = null; f._src = null; }\nfunction rock0(f, ox, oy, cap) {'],
  ['f.y = Math.max(2, foe.y + Math.sin(a) * r); rock(f, ox, oy,', 'f.y = Math.max(2, foe.y + Math.sin(a) * r); f._mvid = c; f._src = "cross"; rock(f, ox, oy,'],
  ['f.y = Math.max(f.y < 2 ? 0 : 2, ny); rock(f, ox0, oy0,', 'f.y = Math.max(f.y < 2 ? 0 : 2, ny); f._mvid = o; f._src = "orbit"; rock(f, ox0, oy0,'],
  ['f.y = lerp(m.y0, m.y1, k); rock(f, ox, oy,', 'f.y = lerp(m.y0, m.y1, k); f._mvid = m; f._src = "mv:" + m.k; rock(f, ox, oy,'],
  ['f.x += f.vx; f.y += f.vy; rock(f, f.x - f.vx, f.y - f.vy, 0); }\n    else if (f.settle > 0)', 'f.x += f.vx; f.y += f.vy; f._src = "flight"; rock(f, f.x - f.vx, f.y - f.vy, 0); }\n    else if (f.settle > 0)'],
  ['f.vy *= 0.75; f.x += f.vx; f.y += f.vy; rock(f,', 'f.vy *= 0.75; f.x += f.vx; f.y += f.vy; f._src = "settle"; rock(f,'],
  ['rock(P, px0, py0, 0); bound(P);', 'P._src = "pull"; rock(P, px0, py0, 0); bound(P);'],
];
function load(opts) { const t = simText(); return new Function((opts && opts.cliff ? patch(t, CLIFF_HOOKS) : t) + '\nreturn S;')(); }

// ---- reading a tick back: the notes it wrote, and events from the notes, the timeline marks and the state ----
const STICK = /^(FLICK (TOWARD|AWAY|UP|DOWN): |LAY 3 BH |READ HIS )/;                     // a flick that acted
const REFUSE = /^(PRESS UNDER WAY|MOVE UNDER WAY|CHARGING: |NOTHING IN STEP 1|FLICK SPENT IN PRESS|NO KI FOR A READ|FLICK: NOT READY|FLICK TOWARD: NO KI)/;  // a flick read and refused
const FACE = { 'X: BLOW': 'X', 'X: PRESS LUNGE, BLOW': 'X', 'THE STEP-STRIKE': 'X', 'X: BOLT ALONG IT': 'BOLT', 'Y: LOB ALONG IT': 'LOB', 'X: LAY A SPARK MINE': 'MINE' };
// events: S stick act (what: its note), S- a flick refused, H hold start (cmd), Z release, K hold ended otherwise, P press start
// (kind, q: from the queue), R the held B let go (it fires), Q a press queued, N an ack in his hand (why), W a flick waits,
// D a waiting flick dropped or replaced (with its ack), C a waiting flick cleared with no ack, LT a slip, U a beam pulse
function readTick(t, w, P, was, fresh, E) {
  const push = (k, x) => E.push(Object.assign({ t, k }, x || {}));
  const acks = w.fx.filter((e) => e.k === 'ack' && e.f === P && !was.fx.has(e)).length;
  const dim = fresh.filter((n) => /NOT READY|QUEUE FULL|A QUEUED PRESS LAPSES|QUEUED \w+ DROPPED|FLICK (DROPPED|REPLACED)/.test(n));
  const queued = fresh.includes('QUEUED B STARTS');
  for (let i = 0; i < fresh.length; i++) {
    const n = fresh[i], q = /^QUEUED \w+ STARTS$/.test(fresh[i + 1] || '');   // the queue's pop notes its press, then this
    if (REFUSE.test(n)) push('S-', { what: n, dpad: P.evSrc === 'pad', ack: acks > 0 });
    else if (STICK.test(n)) push('S', { what: n, dpad: P.evSrc === 'pad' });
    else if (FACE[n]) push('P', { kind: FACE[n], what: n, q });
    else if (/^(B: BLAST ALONG IT|B HELD: BEAM, LEVEL \d)$/.test(n)) push('R', { what: n });
    else if (/^(X|BOLT|Y|B|MINE) QUEUED$/.test(n)) push('Q', { what: n });
    else if (n === 'B: PULSE') push('U');
    else if (/^LT/.test(n)) push('LT', { what: n });
  }
  if (P.bchg && P.bchg !== was.bchg) push('P', { kind: 'CHARGE', q: queued });
  if (P.cmd && P.cmd !== was.cmd && P.cmd !== 'sweepLeft' && !(/^crossed/.test(P.cmd) && /^orbit/.test(was.cmd || ''))) push('H', { cmd: P.cmd, dpad: P.holdSrc === 'pad' });
  const rel = P.tl.some((m) => m.k === 'R' && !was.tl.has(m));
  if (rel && was.cmd) push('Z', { cmd: was.cmd, dpad: P.relSrc === 'pad' });
  else if (rel) push('Z-', { dpad: P.relSrc === 'pad' });                                      // a release with no command running (it still sets the stick's tick)
  else if (was.cmd && !P.cmd && was.cmd !== 'sweepLeft') push('K', { cmd: was.cmd });
  if (P.pend && P.pend !== was.pend) push('W', { dpad: !!P.pend.dpad, from: P.pend.t, fam: P.pend.fam });
  if (was.pend && P.pend !== was.pend) {
    const why = dim.find((n) => /^FLICK (DROPPED|REPLACED)$/.test(n));
    if (why) push('D', { what: why, ack: acks > 0, from: was.pend.t });
    else if (!P.pend && !E.some((e) => e.t === t && (e.k === 'S' || e.k === 'S-'))) push('C', { from: was.pend.t, fam: was.pend.fam, caught: !!P.caught });
    else if (!P.pend) { const s = E.filter((e) => e.t === t && (e.k === 'S' || e.k === 'S-')).pop(); s.waited = was.pend.t; s.dpad = !!was.pend.dpad; }
  }
  for (const n of dim) push('N', { what: n, ack: acks > 0 });
}

// one take: setup(w) places them, input(t, w) gives { P: keys, V: orders }; mode 'play' lets the rival run his Play script
function run(S, len, setup, input, opts) {
  opts = opts || {};
  S.CLIPS.push({ n: 'Z', name: 'review', takes: [{ len: len + 5, setup: setup || (() => {}), input: (w) => input(w.t, w) }], steps: [[0, '', 0]] });
  let r; try { r = S.newRun(S.CLIPS.length - 1, 'demo'); } finally { S.CLIPS.pop(); }
  if (opts.mode) r.w.mode = opts.mode;
  const w = r.w, P = w.P, notes = [], E = [], seen = new Set(), trace = [];
  let overflow = false;
  for (let i = 0; i < len; i++) {
    const t = w.t, was = { cmd: P.cmd, pend: P.pend, bchg: P.bchg, tl: new Set(P.tl), fx: new Set(w.fx) };
    S.stepRun(r);
    const fresh = [];
    for (let k = w.rd.log.length - 1; k >= 0; k--) { const e = w.rd.log[k]; if (!seen.has(e)) { seen.add(e); fresh.push(e.text); notes.push(t + ' ' + e.text); } }
    if (fresh.length >= 6) overflow = true;      // the feed keeps 6: a tick with more may have lost some
    readTick(t, w, P, was, fresh, E);
    if (opts.trace) trace.push({ t, commit: P.commit, cmd: P.cmd, q: P.q.length, pend: !!P.pend, beam: !!(P.beam && !P.beam.end), rooted: !!P.beam, out: !!w.rd.on, hsrc: P.holdSrc, seq: !!P.seq, blow: !!P.blow, cross: !!P.cross, bchg: !!P.bchg, dodge: P.dodgeT, caught: P.caught, brawl: !!w.brawl });
    if (opts.each) opts.each(w, t);
  }
  return { w, notes, E, trace, overflow };
}

// the stick commitments a run's own events set, as [from, to): a flick L from its act (the lunge, its rush), a hold to
// release + L (one ended otherwise, the same; the brawl cross-up, its arc; the beam sweep, nothing). Needs run(.., { trace })
function commitments(r) {
  const out = [], free = (a, k) => { const x = r.trace.find((y) => y.t > a && !y[k]); return x ? x.t : 1e9; };
  for (const e of r.E) {
    if (e.k === 'S') out.push([e.t, e.what === 'FLICK TOWARD: LUNGE' ? free(e.t, 'commit') : e.t + LAW.L]);
    else if (e.k === 'H' && e.cmd !== 'sweepB') {
      if (/^crossed/.test(e.cmd)) out.push([e.t, free(e.t, 'cross') + 1]);      // the arc's last step comes after the queue's turn
      else { const z = r.E.find((x) => x.t >= e.t && (x.k === 'Z' || x.k === 'K' || (x.k === 'H' && x !== e))); out.push([e.t, z ? (z.k === 'H' ? z.t : z.t + LAW.L) : 1e9]); }
    }
  }
  return out;
}
// the first tick at or after t outside every commitment
function freeAt(cs, t) { let moved = true; while (moved) { moved = false; for (const [a, b] of cs) if (a <= t && t < b) { t = b; moved = true; } } return t; }
const inside = (cs, t) => cs.find(([a, b]) => a <= t && t < b);

// the face commitments in a run, by the law as the README states it: for each accepted press (started or queued), the tick
// its stick commitment counts from: its press; a held B, its last tick down (or the tick it fires with B still down); a press
// queued inside a stick commitment, that commitment's end; one queued with the stick out or a hold running, the stick's
// next act or release + L, or its start if that comes first (until then the stick is free). Needs the input spec.
function faceRefs(r, spec) {
  const out = [], E = r.E, btn = spec.btn || {};
  const down = (k, t) => (btn[k] || []).some((s) => t >= s[0] && t < s[1]);
  // out: the stick's input or the recognizer's state (it holds the stick's last state while it reads the D-pad)
  // the right stick out (the right thumb on it); the D-pad is the left thumb's, so it never counts here
  const stickOut = (t) => (spec.st || []).some((g) => t >= g[0] && t < g[1] && (g[3] == null || g[3] >= 0.6)) || r.trace.some((x) => x.t === t && x.out);
  const holdAt = (t) => { const h = E.filter((e) => e.t <= t && e.k === 'H').pop(); return h && !h.dpad && !E.some((e) => e.t >= h.t && e.t < t && (e.k === 'Z' || e.k === 'K')); };
  for (const b of ['X', 'Y', 'B']) for (const [p] of btn[b] || []) {
    if (down(b, p - 1)) continue;
    let end = p; while (down(b, end)) end++;                          // spans that touch are one press
    const started = E.find((e) => e.t === p && e.k === 'P' && !e.q), queued = E.find((e) => e.t === p && e.k === 'Q');
    if (!started && !queued) continue;                                  // refused (it flickered) or unmapped: commits nothing
    let ref = p, free = p, until = 1e9;
    if (b === 'B' && (started ? started.kind === 'CHARGE' : queued.what === 'B QUEUED')) { const R = E.find((e) => e.t > p && e.k === 'R'); ref = Math.max(ref, R && R.t < end - 1 ? R.t : end - 1); }
    if (queued) {
      // it commits while it waits and after it starts; one that lapses or is dropped from the queue commits nothing more
      const kind = { 'X QUEUED': 'X', 'BOLT QUEUED': 'BOLT', 'Y QUEUED': 'LOB', 'B QUEUED': 'CHARGE', 'MINE QUEUED': 'MINE' }[queued.what];
      const fate = E.find((e) => e.t > p && ((e.k === 'P' && e.q && e.kind === kind) || (e.k === 'N' && /A QUEUED PRESS LAPSES|QUEUED \w+ DROPPED/.test(e.what))));
      if (fate && fate.k === 'N') until = fate.t;
      const start = fate && fate.k === 'P' ? fate.t : 1e9, stickT = (e) => (e.k === 'S' || e.k === 'Z' || e.k === 'Z-') && !e.dpad;
      if (stickOut(p) || holdAt(p)) {
        // made with the stick out: the stick runs on until its next act or release (all of that is free), and the press counts
        // from that + L, or from its own start if it starts first
        const nx = E.find((e) => e.t >= p && stickT(e));
        if (nx && nx.t <= start) { ref = Math.max(ref, nx.t + LAW.L); free = nx.t; } else { ref = Math.max(ref, start); free = start; }
      } else { const last = E.filter((e) => e.t <= p && stickT(e)).pop(); if (last) ref = Math.max(ref, last.t + LAW.L); }
    }
    out.push({ t: p, b, ref, free, queued: !!queued, until, hold: holdAt(p) });
  }
  return out;
}

// the law's checks over one run of any input (chains.js, one-thumb.js): returns [{ k, t, why }], each a breach
//   EARLY PRESS   a press starts inside a stick commitment (R30, gate A and C)
//   EARLY STICK   a stick or D-pad act inside a face press's commitment (items 13 and 16): a flick before ref + L, a hold
//                 before ref + L + 10
//   SILENT        a waiting flick cleared with no ack, a dropped one or a refused press with no flicker, or a press that
//                 did nothing at all (item 14, E3); a catch is his grab, not silence, and unmapped presses are skipped
function lawCheck(r, spec) {
  const out = [], E = r.E, cs = commitments(r), refs = faceRefs(r, spec), btn = spec.btn || {};
  const down = (k, t) => (btn[k] || []).some((s) => t >= s[0] && t < s[1]);
  const caughtAt = (t) => r.trace.some((x) => x.t >= t - 1 && x.t <= t && x.caught);
  for (const e of E) {
    if (e.k === 'P') { const c = inside(cs, e.t); if (c) out.push({ k: 'EARLY PRESS', t: e.t, why: `${e.kind} starts ${e.t} inside the stick's commitment ${c[0]}..${c[1] - 1}` }); }
    if (e.k === 'S' || e.k === 'H') for (const f of refs) {
      if (e.t <= f.free || e.t >= f.until) continue;
      if (e.k === 'H' && f.hold && !E.some((x) => x.t > f.t && x.t <= e.t && (x.k === 'Z' || x.k === 'K'))) continue;    // the hold he was already in
      const need = f.ref + LAW.L + (e.k === 'H' ? LAW.hold : 0);
      if (e.t < need) out.push({ k: 'EARLY STICK', t: e.t, why: `${e.what || e.cmd}${e.dpad ? ' (D-pad)' : ''} at ${e.t}, before ${need}: the ${f.b} at ${f.t} counts from ${f.ref}` });
    }
    if (e.k === 'C' && !e.caught && !caughtAt(e.t)) {
      const rooted = r.trace.some((x) => x.t === e.t && x.rooted);         // his beam roots him: the same flick unwaited does nothing too
      const slip = E.some((x) => x.t === e.t && x.k === 'LT'), shoulderGone = (e.fam === 'aim' && !down('RB', e.t)) || (e.fam === 'read' && !down('LB', e.t));
      const why = rooted ? 'his beam is out' : slip ? 'a slip cancels it' : e.fam == null ? 'its family was never read: the stick and the D-pad crossed' : shoulderGone ? 'its shoulder was let go while it waited' : 'cleared';
      out.push({ k: rooted ? 'ROOTED' : 'SILENT', t: e.t, info: rooted, why: `the ${e.fam || 'unread'} flick waiting since ${e.from} is cleared at ${e.t} with no ack (${why})` });
    }
    if ((e.k === 'D' || e.k === 'N') && !e.ack) out.push({ k: 'SILENT', t: e.t, why: `${e.what} at ${e.t} with no flicker` });
  }
  for (const b of ['X', 'Y', 'B']) for (const [p] of btn[b] || []) {
    if (down(b, p - 1) || caughtAt(p)) continue;
    const rb = down('RB', p), lb = down('LB', p);
    if ((b === 'X' && lb && !rb) || (b !== 'X' && (!rb || lb))) continue;                       // nothing is mapped there in step 1
    if (!E.some((e) => e.t === p && (e.k === 'P' || e.k === 'Q' || e.k === 'N' || e.k === 'U'))) out.push({ k: 'SILENT', t: p, why: `${b} at ${p} does nothing and nothing flickers` });
  }
  return out;
}

// inputs: { st: [[from, to(excl), screenDeg, mag]], btn: { X: [[a, b]], lx: [[a, b, v]], ... }, V: { blow: [[a, b, 'mid']] } }
function stick(list, t) { for (const e of list) if (t >= e[0] && t < e[1]) { const d = e[2] * Math.PI / 180, m = e[3] == null ? 1 : e[3]; return [Math.cos(d) * m, -Math.sin(d) * m]; } return [0, 0]; }
function inp(spec) {
  return function (t) {
    const s = stick(spec.st || [], t), P = { rx: s[0], ry: s[1] }, V = {};
    for (const k in spec.btn || {}) for (const sp of spec.btn[k]) if (t >= sp[0] && t < sp[1]) P[k] = sp.length > 2 ? sp[2] : true;
    for (const k in spec.V || {}) for (const sp of spec.V[k]) if (t >= sp[0] && t < sp[1]) V[k] = sp.length > 2 ? sp[2] : true;
    return { P, V };
  };
}
// a gesture on the stick or the D-pad, by kind: flick1..3 (ticks out), hold (n ticks), slow (a 3-tick 0.45 rise, then out)
const PADKEY = { 0: ['dr'], 45: ['du', 'dr'], 90: ['du'], 180: ['dl'], 200: ['dl'], 270: ['dd'] };
function gesture(spec, at, kind, dir, n, pad) {
  if (pad) { for (const k of PADKEY[dir]) (spec.btn[k] = spec.btn[k] || []).push([at, at + n]); return; }
  if (kind === 'slow') spec.st.push([at, at + 3, dir, 0.45], [at + 3, at + 3 + n, dir, 1]);
  else spec.st.push([at, at + n, dir, 1]);
}
function hold(spec, key, a, b, v) { (spec.btn[key] = spec.btn[key] || []).push(v === undefined ? [a, b] : [a, b, v]); }

// a renderer that checks every call (the fuzzer draws each tick through it)
function stubR(errs, tag) {
  const bad = (m) => { if (errs.length < 50) errs.push(tag() + ' ' + m); };
  return {
    clear(c) { if (typeof c !== 'string') bad('clear col ' + c); },
    poly(p, c) { if (typeof c !== 'string' || !/^#[0-9a-f]{6}$/i.test(c)) bad('poly col ' + c); if (!Array.isArray(p) || p.length % 2 || p.length < 6) bad('poly len ' + (p && p.length)); for (const v of p) if (!Number.isFinite(v)) { bad('poly NaN'); break; } },
    text(x, y, s, size, c) { if (!Number.isFinite(x) || !Number.isFinite(y)) bad('text NaN ' + s); if (typeof c !== 'string') bad('text col ' + c); if (s == null || /undefined|NaN|null|Infinity/.test(String(s))) bad('text "' + s + '"'); },
  };
}
function rng(seed) { let s = seed >>> 0 || 1; return () => { s ^= s << 13; s >>>= 0; s ^= s >>> 17; s ^= s << 5; s >>>= 0; return s / 4294967296; }; }
// a tally of findings by class, with the first few examples of each
function tally() {
  const m = {};
  return { add(k, ex) { const e = m[k] || (m[k] = { n: 0, ex: [] }); e.n++; if (e.ex.length < 2) e.ex.push(ex); }, m,
    print(pad) { for (const k of Object.keys(m).sort()) { console.log(String(m[k].n).padStart(pad || 5), k); for (const x of m[k].ex) console.log('         ', String(x).slice(0, 700)); } } };
}
const showE = (E, t0) => E.filter((e) => e.t >= (t0 || 0) && e.k !== 'N').map((e) => e.t + e.k + (e.kind ? ':' + e.kind : e.cmd ? ':' + e.cmd : e.what ? ':' + e.what.replace(/ /g, '_').slice(0, 22) : '') + (e.waited != null ? '(waited)' : '')).join(' ');

module.exports = { REPO, SIM, LAW, below, load, run, inp, gesture, hold, stubR, rng, tally, showE, commitments, freeAt, inside, faceRefs, lawCheck };
