// Pure 4a (Orb's pick, 2026-10-30) with the left-right swap (left-handed players, docs/ep/vision.md), against Controls' bar:
// no grip starts anything earlier than the fast one-thumb player (docs/controls/right-hand-attacks.md section 6). The sim reads
// logical inputs, so a layout changes only which inputs share a thumb, which is a transfer time T between the attack stick and
// the face buttons:
//   standard, or the pad turned round, or a full mirror (attack stick and D-pad as the face buttons on the left thumb): one
//   thumb, T = 6 at its fastest, 8 at p50, 13 at p90. Sticks swapped (attack stick left, face buttons right, shoulders either
//   way): two thumbs, T = 0 for everyone, the same lane as a claw.
// Three checks of the T = 0 lane against T = 6, on the built v3 page:
//   links: strike or beam against every press, both orders, gaps 0 to 36 (gate J, M); holds around D and up the ladder with
//     the press at every tick (gate K); stick and D-pad (gate P), from no shoulder, guard, manoeuvre, energy and power.
//   chains: strike and press alternating for 600 ticks at the best gaps of each T, the model's own table (section 6.3). They
//     read the rate each T gets, not the law: a press queued during the strike hides R, so a fast thumb reaches the same rate
//     with the law off (the links and the fuzz are what catch that).
//   fuzz: every input at random; a face blow never starts during a held request or inside L of a stick act (K2, K3), a stick
//     act never inside R of a press that started on its own tick (K1, K2). K3 shows here and not in the links: a charge holds
//     his one blow anyway, so K3 bites after a cancelled charge with the stick still out.
//   node research/right-stick-proto/claw-4a-swap.mjs [--law-off | --k3-off]     (exits 1 on a claw gain or a broken floor)
import { readFileSync } from 'node:fs';

const HTML = 'docs/ep/prototypes/right-hand-v3.html', PITCH = '4a', FAST = 6, T0 = 30, LEN = 200;
const argv = process.argv.slice(2), src = readFileSync(HTML, 'utf8');
const a = src.indexOf('// ==== HAND SIM (no DOM) ===='), b = src.indexOf('// ==== PAGE (DOM) ====');
if (a < 0 || b < 0) throw new Error('markers not found in ' + HTML);
let code = src.slice(a, b);
if (argv.includes('--k3-off')) { const k = 'function k3(w, f) { return f.reqGid != null && stillOut(w, f.reqSrc, f.reqGid); }'; if (!code.includes(k)) throw new Error('k3 not found'); code = code.replace(k, 'function k3(w, f) { return false; }'); }
const S = new Function(code + '\nreturn S;')();
const { L, R } = S.LAW, D = S.RS.D;     // the floors are the law's numbers, read before a mutant turns them off
if (argv.includes('--law-off')) { S.LAW.R = 2; S.LAW.L = 0; }
const START = /^(X: (LIGHT|BOLT)|Y: (MEDIUM|LOB)|B: (HEAVY|HEAVY BLAST)|A: GRAB|RT\+B: SIGNATURE)/;
const PAD = { 0: 'dr', 90: 'du', 180: 'dl', 270: 'dd' };

function mkRun(take) { S.CLIPS.push({ n: 'SW', name: 'sweep', takes: [take], steps: [[0, '']] }); const r = S.newRun(S.CLIPS.length - 1, 'demo'); S.CLIPS.pop(); return r; }
// one take: the gesture out from sAt for slen ticks (the stick, or the D-pad under its mirror), the button tapped at pAt
const memo = new Map();
function one(c, usePad, slen, sAt, pAt) {
  const key = [c.name, usePad, slen, sAt, pAt].join(); if (memo.has(key)) return memo.get(key);
  const r = mkRun({ len: LEN, pitch: PITCH, mirror: usePad, setup: (w) => { w.P.x = c.pos[0]; w.P.y = c.pos[1]; w.V.x = c.pos[2]; w.V.y = c.pos[3]; },
    input: (w) => {
      const P = Object.assign({}, c.sh), t = w.t, on = t >= sAt && t < sAt + slen, ang = c.ang * Math.PI / 180;
      P.rx = on && !usePad ? Math.cos(ang) : 0; P.ry = on && !usePad ? -Math.sin(ang) : 0; P.lx = 0; P.ly = 0;
      if (on && usePad) P[PAD[c.ang]] = true;
      if (t >= pAt && t < pAt + 3) P[c.btn] = true;
      return { P, V: {} };
    } });
  const said = [], seen = new Set();
  for (let t = 0; t < LEN - 1; t++) { S.stepRun(r, {}); for (const e of r.w.rd.log) if (!seen.has(e)) { seen.add(e); said.push(e); } }
  const F = r.w.P.tl.find((e) => e.k === 'F'), P = said.find((n) => START.test(n.text)), T = said.find((n) => /^LET GO/.test(n.text));
  const o = { F: F ? F.t : null, P: P ? P.t : null, T: T ? T.t : null, notes: said.map((n) => n.t + ' ' + n.text).join(' | ') };
  memo.set(key, o); return o;
}
const late = (x) => (x == null ? Infinity : x);
const fair = (cl, thumbs) => thumbs.some((th) => late(th.F) <= late(cl.F) && late(th.P) <= late(cl.P) && late(th.T) <= late(cl.T));

// ---- links ----
const CLOSE = [330, 0, 375, 0], RANGE = [200, 40, 480, 40], cases = [];
for (const [lane, sh] of [['', {}], ['guard ', { LB: true }], ['manoeuvre ', { LT: true }]]) for (const ang of [0, 90, 180, 270]) for (const btn of ['X', 'Y', 'B', 'A']) cases.push({ name: `${lane}strike ${ang} + ${btn}`, pos: CLOSE, ang, btn, sh });
for (const ang of [0, 90]) for (const btn of ['X', 'Y', 'B']) cases.push({ name: `beam ${ang} + RB ${btn}`, pos: RANGE, ang, btn, sh: { RB: true } }, { name: `kite beam ${ang} + RB ${btn}`, pos: RANGE, ang, btn, sh: { RB: true, LT: true } });
cases.push({ name: 'inert RT stick + RT B', pos: RANGE, ang: 0, btn: 'B', sh: { RT: true } });
let links = 0, gains = 0; const shown = [];
function judge(what, cl, thumbs) { links++; if (!fair(cl, thumbs)) { gains++; if (shown.length < 8) shown.push(`GAIN ${what}: F${cl.F} P${cl.P} T${cl.T}\n  claw:  ${cl.notes}` + thumbs.map((th) => `\n  thumb: F${th.F} P${th.P} T${th.T} ${th.notes}`).join('')); } }
for (const c of cases) for (const usePad of [false, true]) {
  const claw = (l, sa, pa) => one(c, usePad, l, sa, pa), th = (l, sa, pa) => one(c, false, l, sa, pa);     // one thumb always on the stick
  for (const fl of [1, 3, 5, 8, 11]) for (const order of ['stick-press', 'press-stick']) for (let g = 0; g <= 36; g++) {
    const sAt = order === 'stick-press' ? T0 : T0 + g, pAt = order === 'stick-press' ? T0 + g : T0;
    // one thumb: the press 6 after the stick is back (a quick strike is the same from a 3-tick flick), or the stick 6 after the press
    judge(`${c.name}${usePad ? ' (pad)' : ''} flick ${fl} ${order} gap ${g}`, claw(fl, sAt, pAt), [th(fl, sAt, Math.max(pAt, sAt + fl + FAST)), th(3, sAt, Math.max(pAt, sAt + 3 + FAST)), th(fl, Math.max(sAt, pAt + FAST), pAt)]);
  }
  for (const h of [D, D + 1, 20, 32, 54, 60]) for (let g = 0; g <= h + 8; g++) {
    // one thumb: the press 6 after letting go; or the press first, the stick 6 later, let go on the claw's tick (or held to its own D)
    const pAt = T0 + g, rel = T0 + h, cr = pAt + FAST;
    judge(`${c.name}${usePad ? ' (pad)' : ''} hold ${h}, press at +${g}`, claw(h, T0, pAt), [th(h, T0, Math.max(pAt, rel + FAST)), th(Math.max(1, rel - cr), cr, pAt), th(Math.max(rel, cr + D) - cr, cr, pAt)]);
  }
}
console.log(`links: ${links} (claw and two-thumb lane against the fast thumb), ${gains} with a gain`); shown.forEach((s) => console.log(s));

// ---- chains: strike, press, strike, press for 600 ticks, the best gaps a transfer T allows; pinned close, ki topped up ----
function chain(btn, T, fl) {
  let best = 0, bestAt = null;
  for (let gsf = 0; gsf <= 30; gsf++) for (let gfs = 0; gfs <= 30; gfs++) {
    if (T > 0 && (gsf < fl + T || gfs < T)) continue;
    const cyc = gsf + gfs; if (!cyc) continue;
    const r = mkRun({ len: 660, pitch: PITCH, setup: (w) => { w.P.x = 330; w.V.x = 375; },
      input: (w) => { const t = w.t - T0, ph = t >= 0 ? t % cyc : -1; w.P.x = 330; w.V.x = 375; w.V.vx = 0; w.P.ki = 100;
        const P = { rx: ph >= 0 && ph < fl ? 1 : 0, ry: 0, lx: 0, ly: 0 }; if (ph >= gsf && ph < gsf + 1) P[btn] = true; return { P, V: {} }; } });
    // true alternation only: a stick held out while X mashes is a mash, which any thumb has; so twice the lesser of the two
    const seen = new Set(); let st = 0, pr = 0;
    for (let i = 0; i < 659; i++) { S.stepRun(r, {}); for (const e of r.w.rd.log) if (!seen.has(e)) { seen.add(e); if (e.t >= T0 && e.t < T0 + 600) { if (START.test(e.text)) pr++; else if (/^STICK /.test(e.text)) st++; } } }
    const n = 2 * Math.min(st, pr);
    if (n > best) { best = n; bestAt = [gsf, gfs]; }
  }
  return { best, bestAt };
}
let chainGain = 0;
for (const btn of ['X', 'Y', 'B']) {
  const row = [0, 6, 8, 13].map((T) => chain(btn, T, 3)); if (row[0].best > row[1].best) chainGain++;
  console.log(`chain strike + ${btn}, blows in 600: T0 (claw, sticks swapped) ${row[0].best} @${row[0].bestAt} | T6 (fast) ${row[1].best} @${row[1].bestAt} | T8 (p50) ${row[2].best} | T13 (p90) ${row[3].best}`);
}

// ---- fuzz: every input at random, all hands at once ----
function lcg(seed) { let x = seed >>> 0; return () => { x = (Math.imul(x, 1664525) + 1013904223) >>> 0; return x / 4294967296; }; }
let ticks = 0, floorL = 0, floorR = 0, k3Fail = 0; const fz = [];
for (let seed = 1; seed <= 300; seed++) {
  const rnd = lcg(seed * 7919), hold = {}, usePad = seed % 3 === 0;
  const flip = (k, on, off) => { hold[k] = hold[k] ? rnd() > off : rnd() < on; return hold[k]; };
  let sx = 0, sy = 0, lx = 0, ly = 0;
  const r = mkRun({ len: 3000, pitch: PITCH, mirror: usePad, setup: (w) => { w.P.x = 300; w.P.y = seed % 2 ? 0 : 40; w.V.x = 360; w.V.y = w.P.y; },
    input: (w) => {
      if (rnd() < 0.08) { const on = rnd() < 0.55, q = Math.floor(rnd() * 8) * Math.PI / 4; sx = on ? Math.cos(q) : 0; sy = on ? Math.sin(q) : 0; }
      if (rnd() < 0.04) { const on = rnd() < 0.6, q = Math.floor(rnd() * 8) * Math.PI / 4; lx = on ? Math.cos(q) : 0; ly = on ? Math.sin(q) : 0; }
      const P = { rx: usePad ? 0 : sx, ry: usePad ? 0 : sy, lx, ly, LT: flip('LT', 0.01, 0.2), LB: flip('LB', 0.01, 0.1), RB: flip('RB', 0.02, 0.06), RT: flip('RT', 0.004, 0.2), X: flip('X', 0.06, 0.5), Y: flip('Y', 0.03, 0.5), B: flip('B', 0.03, 0.3), A: flip('A', 0.01, 0.5) };
      if (usePad && (sx || sy)) { if (sx > 0.5) P.dr = true; if (sx < -0.5) P.dl = true; if (sy > 0.5) P.dd = true; if (sy < -0.5) P.du = true; }
      w.P.ki = rnd() < 0.002 ? 0 : Math.max(w.P.ki, 30);
      const V = {}, v = rnd(); if (v < 0.006) V.jab = true; else if (v < 0.012) V.blow = 'mid'; else if (v < 0.015) V.heavy = true; else if (v < 0.017) V.guard = 30;
      return { P, V };
    } });
  const seen = new Set(); let lastF = -999, lastStart = -999;
  for (let t = 0; t < 2998; t++) {
    const P0 = r.w.P, held = P0.reqGid != null && (P0.reqSrc === 'pad' ? r.w.rd.dpOn && r.w.rd.dpGid === P0.reqGid : r.w.rd.on && r.w.rd.gid === P0.reqGid);
    S.stepRun(r, {}); ticks++;
    const w = r.w, now = w.t - 1, marks = w.P.tl.filter((m) => m.t === now), act = marks.some((m) => m.k === 'F');
    // a press that started on its own tick: one from the queue has an earlier thumb tick, whatever else was pressed now
    const pressed = marks.some((m) => m.k === 'X') && !w.rd.log.some((e) => e.t === now && /^QUEUED .* STARTS/.test(e.text));
    for (const e of w.rd.log) if (!seen.has(e)) { seen.add(e);
      if (START.test(e.text) && e.t === now) {
        const stillHeld = held && w.P.reqGid === P0.reqGid && (w.P.reqSrc === 'pad' ? w.rd.dpOn : w.rd.on);
        if (stillHeld) { k3Fail++; if (fz.length < 6) fz.push(`K3 seed ${seed} t${now}: ${e.text}`); }
        if (now - lastF < L) { floorL++; if (fz.length < 6) fz.push(`L seed ${seed} t${now}: ${e.text} ${now - lastF} after a stick act`); }
        if (pressed) lastStart = now;
      } }
    if (act) { if (now - lastStart < R) { floorR++; if (fz.length < 6) fz.push(`R seed ${seed} t${now}: stick acts ${now - lastStart} after a press`); } lastF = now; }
  }
}
console.log(`fuzz: ${ticks} ticks, K3 ${k3Fail}, L floor ${floorL}, R floor ${floorR}`); fz.forEach((s) => console.log('  ' + s));
const bad = gains + chainGain + k3Fail + floorL + floorR;
console.log(bad ? `pure 4a: ${bad} breaches` : 'pure 4a: zero claw gain');
process.exit(bad ? 1 : 0);
