// The claw-bot gate's named cases (docs/controls/claw-bot-gate.md section 2), each checked against the law's own tick:
// A  a press made inside a stick command's commitment starts at its end, the same at every gap (B: the same result)
// C  a press made during a hold starts at release + L
// G  a stick input inside a face press's commitment acts at max(onset + 2, press + R), R = 8 (items 13, 16; Controls' gate G)
// I  with no extra tick (item 16): the claw's stick and the one-thumb's D-pad tap get the same tick
// H  newest wins, nothing silent (item 14): flick, flick keeps the second; flick, press drops the flick; each with an ack
// F  mirror parity (item 15): the D-pad acts on the stick's tick, 2 after onset (the stick's flick reads 2 after crossing)
// M  the right stick and the D-pad a few ticks apart (two thumbs): both act
// plus the earlier gate's own cases (rs-gate, rs-gate2). Prints each breach, then the count. node gate.js [-v]
'use strict';
const H = require('./harness.js'), { L, R } = H.LAW;
const VERBOSE = process.argv.includes('-v');
const POS = { range: [230, 60, 430, 80], close: [300, 60, 360, 60], tight: [545, 0, 585, 0], far: [160, 60, 540, 80] };
const FAMS = { flight: {}, aim: { RB: 1 }, lay: { RB: 1, LB: 1 }, read: { LB: 1 } };
let S = null;
function go(pos, build, len) {
  const spec = { st: [], btn: {}, V: {} }; build(spec); const P = POS[pos];
  return H.run(S, len || 90, (w) => { w.P.x = P[0]; w.P.y = P[1]; w.V.x = P[2]; w.V.y = P[3]; }, H.inp(spec));
}
const firstStick = (r, from) => r.E.find((e) => e.t >= from && (e.k === 'S' || e.k === 'S-' || e.k === 'H'));
const firstPress = (r, from, kind) => r.E.find((e) => e.t >= from && e.k === 'P' && (!kind || e.kind === kind));
const out = { pass: 0, fail: [] };
function ok(cond, name, detail) { if (cond) out.pass++; else out.fail.push(name + ': ' + detail); if (VERBOSE && cond) console.log('  ok', name); }
const tag = (e) => (e ? e.t + ' ' + (e.what || e.kind || e.cmd || e.k) : 'nothing');

// the face presses that commit the stick, made at 20 (sh: the shoulders the press needs)
const PRESS = { X: { btn: 'X', sh: {}, kind: 'X' }, bolt: { btn: 'X', sh: { RB: 1 }, kind: 'BOLT' }, lob: { btn: 'Y', sh: { RB: 1 }, kind: 'LOB' }, Btap: { btn: 'B', sh: { RB: 1 }, kind: 'CHARGE' }, mine: { btn: 'X', sh: { RB: 1, LB: 1 }, kind: 'MINE' } };
const ROWS = [['flight', 0, 'close'], ['flight', 180, 'close'], ['flight', 90, 'close'], ['flight', 270, 'range'], ['flight', 0, 'far'], ['aim', 90, 'range'], ['aim', 180, 'range'], ['lay', 0, 'range'], ['read', 90, 'tight'], ['read', 0, 'tight']];

function caseG() {
  // G and I: press at 20, then a flick (2 ticks out) or a D-pad tap at onset 20 + g; the law's tick is max(onset + 2, 28),
  // the same for the claw's stick and the one-thumb's D-pad, with the same result. At g = -2 the flick reads on the press's
  // own tick: one of the two must wait for the other (a ranged X wins over a toward flick, section 12 row 1)
  for (const pk in PRESS) for (const [fam, dir, pos] of ROWS) for (const g of [-2, -1, 0, 2, 3, 5, 6, 7, 13]) {
    const p = PRESS[pk], name = `G ${pk} then ${fam} ${dir} ${pos} gap ${g}`, at = 20 + g, same = JSON.stringify(p.sh) === JSON.stringify(FAMS[fam]);
    if (g <= 0 && !same) continue;                                // the shoulders can't change between the press and the flick
    const sh = (s) => { for (const k in p.sh) H.hold(s, k, 0, same ? 80 : 21); for (const k in FAMS[fam]) H.hold(s, k, same ? 80 : 21, 80); };
    const mk = (pad) => go(pos, (s) => { sh(s); H.hold(s, p.btn, 20, 21); H.gesture(s, at, 'flick', dir, pad ? 1 : 2, pad); });
    const ctl = go(pos, (s) => { for (const k in FAMS[fam]) H.hold(s, k, 0, 80); H.gesture(s, at, 'flick', dir, 2); });
    const c = firstStick(ctl, at);
    if (!c) { ok(true, name, ''); continue; }                    // nothing to time: the flick does nothing here
    const rs = mk(false), rp = mk(true), a = firstStick(rs, at), b = firstStick(rp, at), pr = firstPress(rs, 20);
    if (c.t <= 20) {                                          // the same tick (or before): whichever acts first, the other waits
      for (const [x, r, nm] of [[a, rs, 'stick'], [b, rp, 'D-pad']]) {
        const q = firstPress(r, 20), stickFirst = x && x.t === c.t && x.k === 'S';
        ok(stickFirst ? !q || q.t >= c.t + L : (x && x.what === 'FLICK SPENT IN PRESS') || (q && q.t === 20 && (!x || x.t >= 20 + R)), name + ' (' + nm + ', same tick)', `flick ${tag(x)}, press ${tag(q)}`);
      }
      continue;
    }
    if (!pr || pr.t !== 20) { ok(true, name, ''); continue; }
    const want = Math.max(c.t, 20 + R);
    ok(a && a.t === want, name + ' (stick)', `acts ${tag(a)}, law ${want}, alone ${tag(c)}`);
    ok(b && b.t === want, name + ' (D-pad)', `acts ${tag(b)}, law ${want}, alone ${tag(c)}`);
    ok(a && b && a.what === b.what, name + ' (same result)', `stick ${tag(a)}, D-pad ${tag(b)}`);
  }
}
function caseA() {
  // A: a stick command (flick 2 out at 20, or a D-pad tap at 20), then a press at act + g; the law: max(press, act + L).
  // At g = 0 the press meets the act on one tick: a ranged X wins over a toward flick (spent in it), any other press waits
  for (const pk in PRESS) for (const [fam, dir, pos] of ROWS) for (const pad of [false, true]) for (const g of [0, 1, 3, 5, 6, 7, 13]) {
    const p = PRESS[pk], name = `A ${fam} ${dir} ${pos}${pad ? ' pad' : ''} then ${pk} gap ${g}`;
    if (g === 0 && JSON.stringify(p.sh) !== JSON.stringify(FAMS[fam])) continue;     // the shoulders can't change on the act's own tick
    const sh = (s, from) => { for (const k in FAMS[fam]) H.hold(s, k, 0, from); for (const k in p.sh) H.hold(s, k, from, 90); };
    const ctl = go(pos, (s) => { sh(s, 23); H.gesture(s, 20, 'flick', dir, pad ? 1 : 2, pad); }, 90);
    const act = firstStick(ctl, 20);
    if (!act || act.k !== 'S') { ok(true, name, ''); continue; }
    const at = act.t + g, r = go(pos, (s) => { sh(s, Math.max(at, act.t + 1)); H.gesture(s, 20, 'flick', dir, pad ? 1 : 2, pad); H.hold(s, p.btn, at, at + 1); }, 90);
    const commitEnd = commitEndOf(pos, fam, dir, pad, act.t), a = firstStick(r, 20);
    const st = firstPress(r, at), want = Math.max(at, commitEnd);
    if (!st) { ok(r.E.some((e) => e.t >= at && e.k === 'N'), name + ' (not silent)', 'the press neither started nor flickered'); continue; }
    if (g === 0 && st.t === at) { ok(a && a.what === 'FLICK SPENT IN PRESS', name + ' (same tick)', `the press starts ${tag(st)} and the ${pad ? 'D-pad' : 'stick'}'s ${act.what} becomes ${tag(a)}`); continue; }
    ok(st.t === want, name, `starts ${tag(st)}, law ${want} (commitment ends ${commitEnd})`);
  }
}
// the stick command's commitment end as the sim keeps it (a step L, a lunge its rush): the first tick he is free again
function commitEndOf(pos, fam, dir, pad, actT) {
  const P = POS[pos], spec = { st: [], btn: {} }; for (const k in FAMS[fam]) H.hold(spec, k, 0, 23); H.gesture(spec, 20, 'flick', dir, pad ? 1 : 2, pad);
  const r = H.run(S, 90, (w) => { w.P.x = P[0]; w.P.y = P[1]; w.V.x = P[2]; w.V.y = P[3]; }, H.inp(spec), { trace: true });
  const free = r.trace.find((x) => x.t > actT && x.commit === 0);
  return free ? free.t : 1e9;
}
function caseC() {
  // C: a press during a hold starts at release + L; one made r >= L after the release starts at once
  const holds = [['dash away', 'close', 180, {}], ['orbit up', 'close', 90, {}], ['aim sweep', 'range', 60, { RB: 1 }]];
  for (const [nm, pos, dir, sh] of holds) for (const pk of ['X', 'bolt']) for (const at of [34, 45, 50, 55, 56, 57, 62]) {
    const p = PRESS[pk], name = `C ${nm} 20..50 then ${pk} at ${at}`;
    const r = go(pos, (s) => { for (const k in Object.assign({}, sh, p.sh)) H.hold(s, k, 0, 90); H.gesture(s, 20, 'hold', dir, 30); H.hold(s, p.btn, at, at + 1); }, 100);
    const z = r.E.find((e) => e.k === 'Z'), st = firstPress(r, at);
    if (!z) { ok(false, name, 'the hold never released: ' + H.showE(r.E)); continue; }
    const want = Math.max(at, z.t + L);
    ok(st && st.t === want, name, `starts ${tag(st)}, law ${want} (release ${z.t})`);
  }
}
function caseH() {
  // H: newest wins, and every dropped command flickers in his hand on the tick it is dropped
  const rb = (s) => H.hold(s, 'RB', 0, 90);
  let r = go('range', (s) => { rb(s); H.hold(s, 'X', 20, 21); H.gesture(s, 21, 'flick', 90, 2); H.gesture(s, 24, 'flick', 270, 2); });
  let d = r.E.find((e) => e.k === 'D'), a = firstStick(r, 21);
  ok(d && d.what === 'FLICK REPLACED' && d.t === 26 && d.ack, 'H press, flick, flick: the first is replaced with an ack', tag(d) + ' ack ' + (d && d.ack));
  ok(a && a.t === 20 + R && /LATCH LOW/.test(a.what), 'H press, flick, flick: only the second acts, at press + R', tag(a));
  r = go('range', (s) => { rb(s); H.hold(s, 'X', 20, 21); H.gesture(s, 21, 'flick', 90, 2); H.hold(s, 'Y', 24, 25); });
  d = r.E.find((e) => e.k === 'D'); a = firstStick(r, 21);
  ok(d && d.what === 'FLICK DROPPED' && d.t === 24 && d.ack, 'H flick, press: dropped on the press tick with an ack', tag(d));
  ok(!a, 'H flick, press: the dropped flick never acts', tag(a));
  // a slip is a newer input too: the waiting flick it cancels must not be silent
  r = go('range', (s) => { H.hold(s, 'RB', 0, 23); H.hold(s, 'RB', 26, 90); H.hold(s, 'X', 20, 21); H.gesture(s, 21, 'flick', 90, 2); H.hold(s, 'LT', 24, 26); });
  let c = r.E.find((e) => e.t >= 21 && (e.k === 'D' || e.k === 'C'));
  ok(c && c.k === 'D' && c.ack, 'H flick, slip: the cancelled flick gets a lapsed ack', `slip at 24, the waiting flick: ${c ? c.k + ' at ' + c.t + (c.ack ? ' with an ack' : ' with no ack') : 'acted ' + tag(firstStick(r, 21))}`);
  // a press that queues (behind a press under way), made after a waiting flick: the flick is dropped and the press is not
  // held back by it (one thumb: X at 20, RB and the D-pad up at 21 with the left hand, RB + X at 24)
  for (const pad of [false, true]) {
    const mk = (flick) => go('tight', (s) => { H.hold(s, 'X', 20, 21); H.hold(s, 'RB', 21, 70); if (flick) H.gesture(s, 21, 'flick', 90, pad ? 1 : 2, pad); H.hold(s, 'X', 24, 25); }, 100);
    const with_ = mk(true), without = mk(false), b1 = firstPress(with_, 24), b0 = firstPress(without, 24);
    d = with_.E.find((e) => e.k === 'D'); a = firstStick(with_, 21);
    ok(d && d.ack && !a && b1 && b0 && b1.t === b0.t, `H flick (${pad ? 'D-pad' : 'stick'}), then a press that queues: the flick is dropped`, `the waiting flick ${a ? 'acts ' + tag(a) : d ? 'is ' + d.what : 'is cleared'}, the queued bolt starts ${tag(b1)} (${tag(b0)} with no flick)`);
  }
  // a waiting read or aim flick whose shoulder is let go before its wait ends: it acts, or it flickers (never silent)
  for (const [nm, sh, dir] of [['read', 'LB', 90], ['aim', 'RB', 90]]) for (const pad of [false, true]) {
    r = go('tight', (s) => { H.hold(s, 'X', 20, 21); H.hold(s, sh, 21, 24); H.gesture(s, 21, 'flick', dir, pad ? 1 : 2, pad); });
    const ctl = go('tight', (s) => { H.hold(s, sh, 21, 24); H.gesture(s, 21, 'flick', dir, pad ? 1 : 2, pad); });
    c = r.E.find((e) => e.t > 21 && (e.k === 'D' || e.k === 'C' || e.k === 'S' || e.k === 'S-'));
    ok(c && (c.k === 'S' || c.ack), `H X, then ${sh} and a ${pad ? 'D-pad tap' : 'flick'} (${sh} 21..23): the waiting ${nm} acts or flickers`, `alone it acts ${tag(firstStick(ctl, 21))}; after X the wait ends ${c ? c.t + ' ' + (c.what || c.k) + (c.ack ? ' with an ack' : ' with no ack') : 'with nothing'}`);
  }
}
function caseF() {
  // F: stick against D-pad at the same onset, alone and inside a press's commitment; holds after 10 either way
  for (const [fam, dir, pos] of ROWS) for (const n of [1, 2, 3]) {
    const name = `F ${fam} ${dir} ${pos} flick${n} vs D-pad`;
    const st = go(pos, (s) => { for (const k in FAMS[fam]) H.hold(s, k, 0, 80); H.gesture(s, 20, 'flick', dir, n); });
    const pd = go(pos, (s) => { for (const k in FAMS[fam]) H.hold(s, k, 0, 80); H.gesture(s, 20, 'flick', dir, 1, true); });
    const a = firstStick(st, 20), b = firstStick(pd, 20);
    ok(a && b && a.t === b.t && a.t === 22, name, `stick ${tag(a)}, D-pad ${tag(b)}, law 22 (onset 20, the stick crossing at 20)`);
  }
  for (const [nm, pos, dir, sh] of [['dash', 'close', 180, {}], ['orbit', 'close', 90, {}], ['sweep', 'range', 60, { RB: 1 }], ['climb', 'far', 90, {}]]) {
    const st = go(pos, (s) => { for (const k in sh) H.hold(s, k, 0, 80); H.gesture(s, 20, 'hold', dir, 30); });
    const pd = go(pos, (s) => { for (const k in sh) H.hold(s, k, 0, 80); H.gesture(s, 20, 'hold', dir === 60 ? 90 : dir, 30, true); });
    const a = st.E.find((e) => e.k === 'H'), b = pd.E.find((e) => e.k === 'H'), za = st.E.find((e) => e.k === 'Z'), zb = pd.E.find((e) => e.k === 'Z');
    ok(a && b && a.t === b.t && a.t === 30, `F ${nm} hold vs D-pad hold`, `stick ${tag(a)}, D-pad ${tag(b)}, law 30`);
    ok(za && zb && za.t === zb.t, `F ${nm} release vs D-pad release`, `stick ${tag(za)}, D-pad ${tag(zb)}`);
  }
}
function caseM() {
  // M: the right stick and the D-pad a tick or three apart (two thumbs, both legal): each input acts, or flickers
  const pairs = [['stick up 20, D-pad toward 21', (s) => { H.gesture(s, 20, 'flick', 90, 2); H.gesture(s, 21, 'flick', 0, 1, true); }, [22, 23]],
    ['D-pad toward 20, stick up 23', (s) => { H.gesture(s, 20, 'flick', 0, 1, true); H.gesture(s, 23, 'flick', 90, 2); }, [22, 25]],
    ['D-pad toward 20, stick up 26', (s) => { H.gesture(s, 20, 'flick', 0, 1, true); H.gesture(s, 26, 'flick', 90, 2); }, [22, 28]]];
  for (const [nm, b, want] of pairs) {
    const r = go('close', b), got = r.E.filter((e) => e.k === 'S' || e.k === 'S-' || e.k === 'D').map((e) => e.t);
    ok(want.every((t) => got.includes(t)), 'M ' + nm + ': both act', `acts at ${got.join(', ') || 'nothing'}, the law ${want.join(' and ')} | ${H.showE(r.E)}`);
  }
}
function caseOld() {
  // the earlier gate's cases, now with the law's ticks
  let r = go('range', (s) => { H.hold(s, 'RB', 0, 80); H.hold(s, 'X', 20, 21); H.gesture(s, 20, 'flick', 90, 3); });
  ok(firstStick(r, 20) && firstStick(r, 20).t === 20 + R, 'old RB X then flick (claw, same tick)', tag(firstStick(r, 20)));
  r = go('tight', (s) => { H.hold(s, 'X', 20, 21); H.hold(s, 'LB', 21, 40); H.gesture(s, 21, 'flick', 90, 3); });
  ok(firstStick(r, 21) && firstStick(r, 21).t === 20 + R, 'old X then read (claw)', tag(firstStick(r, 21)));
  // a held B: its commitment counts from its last tick down (B 20..39, it fires at 40, so the stick waits to 39 + R = 47)
  r = go('range', (s) => { H.hold(s, 'RB', 0, 90); H.hold(s, 'B', 20, 40); H.gesture(s, 40, 'flick', 90, 2); }, 80);
  ok(firstStick(r, 40) && firstStick(r, 40).t === 39 + R, 'old held B then flick (claw)', tag(firstStick(r, 40)));
  r = go('range', (s) => { H.hold(s, 'RB', 0, 90); H.hold(s, 'B', 20, 40); H.gesture(s, 40, 'flick', 90, 1, true); }, 80);
  ok(firstStick(r, 40) && firstStick(r, 40).t === 39 + R, 'old held B then D-pad tap', tag(firstStick(r, 40)));
  // the queued B behind an aim flick starts at the commitment's end, as one thumb's tap at that end does
  const qb = go('range', (s) => { H.hold(s, 'RB', 0, 80); H.gesture(s, 20, 'flick', 270, 2); H.hold(s, 'B', 22, 23); });
  const ob = go('range', (s) => { H.hold(s, 'RB', 0, 80); H.gesture(s, 20, 'flick', 270, 2); H.hold(s, 'B', 28, 29); });
  ok(firstPress(qb, 20) && firstPress(ob, 20) && firstPress(qb, 20).t === 28 && firstPress(ob, 20).t === 28, 'old B queued behind a flick = B at its end', `claw ${tag(firstPress(qb, 20))}, one thumb ${tag(firstPress(ob, 20))}`);
  // RT and a D-pad tap during a dash: the pad is read beside the stick, so the hold runs on; the queued X never starts before
  // the stick's release + L
  r = go('close', (s) => { H.gesture(s, 20, 'hold', 180, 50); H.hold(s, 'X', 35, 36); H.hold(s, 'RT', 44, 47); H.hold(s, 'du', 45, 46); }, 90);
  const k = r.E.find((e) => e.k === 'K' || e.k === 'Z'), x = firstPress(r, 35);
  ok(k && (!x || x.t >= k.t + L), 'old RT and a D-pad tap during a dash: X waits for release + L', `hold ends ${tag(k)}, X ${tag(x)}`);
  // a waiting flick, then a catch: nothing replays after it
  r = go('range', (s) => { H.hold(s, 'RB', 10, 30); H.hold(s, 'LB', 10, 30); H.hold(s, 'X', 20, 21); H.gesture(s, 22, 'flick', 90, 3); s.V.grab = [[3, 4]]; }, 90);
  const caught = r.notes.find((n) => /CAUGHT IN HIS GRAB/.test(n)), ct = caught ? +caught.split(' ')[0] : 1e9;
  ok(!r.E.some((e) => e.t > ct && e.k === 'S'), 'old a waiting flick, then a catch: nothing replays', caught + ' | ' + H.showE(r.E, 20));
}

function main() {
  S = H.load(); out.pass = 0; out.fail = [];
  caseG(); caseA(); caseC(); caseH(); caseF(); caseM(); caseOld();
  for (const f of out.fail) console.log('BREACH', f);
  console.log(`gate: ${out.pass} passed, ${out.fail.length} breaches`);
  return { breaches: out.fail.length };
}
if (require.main === module) { H.below(); process.exitCode = main().breaches ? 1 : 0; }
module.exports = { main };
