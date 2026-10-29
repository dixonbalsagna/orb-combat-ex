// The claw against one thumb, swept (Controls' right-hand-attacks.md section 6: K1 to K3, gate rows J, K and M). Every
// pitch and layer: a stick move (a strike each way; with RB a beam; with RT in 4c the signature) linked to a face press (X,
// Y, B, A; with RB the bolt, the lob, the heavy blast; with RT, B), in both orders, the claw at every gap from 0 to 12 ticks,
// and a held stick (a charge) with the claw pressing at every tick of the hold. One thumb plays the same inputs with 6 ticks
// at least between the two devices: its first input on the claw's tick and the other 6 later, or, for a hold, the press 6
// after letting go. The bar is zero claw gain: some one-thumb play starts the stick move and the press no later than the
// claw does (a move that never starts counts as never).
//   node research/right-stick-proto/v3/claw-sweep.mjs      (prints each pitch's count and any breach; exits 1 on a breach)
import { readFileSync } from 'node:fs';

const HTML = 'docs/ep/prototypes/right-hand-v3.html';
const src = readFileSync(HTML, 'utf8');
const a = src.indexOf('// ==== HAND SIM (no DOM) ===='), b = src.indexOf('// ==== PAGE (DOM) ====');
if (a < 0 || b < 0) throw new Error('markers not found in ' + HTML);
const S = new Function(src.slice(a, b) + '\nreturn S;')();
const THUMB = 6, T0 = 30, LEN = 200;
const START = /^(X: (LIGHT|BOLT)|Y: (MEDIUM|LOB)|B: (HEAVY|HEAVY BLAST)|A: GRAB|RT\+B: SIGNATURE)/;

// one take: the stick out at screen angle ang from sAt for len ticks, the button tapped at pAt for 3, the shoulders held
function run(pitch, pos, ang, slen, btn, sh, sAt, pAt) {
  const take = {
    len: LEN, pitch, setup: (w) => { w.P.x = pos[0]; w.P.y = pos[1]; w.V.x = pos[2]; w.V.y = pos[3]; },
    input: (w) => {
      const P = Object.assign({}, sh), t = w.t, r = ang * Math.PI / 180;
      if (t >= sAt && t < sAt + slen) { P.rx = Math.cos(r); P.ry = -Math.sin(r); } else { P.rx = 0; P.ry = 0; }
      P.lx = 0; P.ly = 0; if (t >= pAt && t < pAt + 3) P[btn] = true;
      return { P, V: {} };
    },
  };
  S.CLIPS.push({ n: 'SW', name: 'sweep', takes: [take], steps: [[0, '']] }); const r = S.newRun(S.CLIPS.length - 1, 'demo'); S.CLIPS.pop();
  const said = [], seen = new Set();
  for (let t = 0; t < LEN - 1; t++) { S.stepRun(r, {}); for (const e of r.w.rd.log) if (!seen.has(e)) { seen.add(e); said.push(e); } }
  const F = r.w.P.tl.find((e) => e.k === 'F'), P = said.find((n) => START.test(n.text));
  return { F: F ? F.t : null, P: P ? P.t : null, notes: said.map((n) => n.t + ' ' + n.text).join(' | ') };
}
const late = (x) => (x == null ? Infinity : x);
const fair = (cl, thumbs) => thumbs.some((th) => late(th.F) <= late(cl.F) && late(th.P) <= late(cl.P));

const CLOSE = [330, 0, 375, 0], RANGE = [200, 40, 480, 40];
function cases(pitch) {
  const c = [];
  for (const ang of [0, 90, 180, 270]) for (const btn of ['X', 'Y', 'B', 'A']) c.push({ name: `strike ${ang} + ${btn}`, pos: CLOSE, ang, btn, sh: {} });
  for (const btn of ['X', 'Y', 'B']) c.push({ name: `beam + RB ${btn}`, pos: RANGE, ang: 0, btn, sh: { RB: true } });
  if (S.PITCH[pitch].sig === 'stick') c.push({ name: 'signature + RT B', pos: RANGE, ang: 0, btn: 'B', sh: { RT: true } });
  return c;
}
let n = 0, breach = 0;
const report = (what, cl, thumbs) => { breach++; if (breach <= 12) console.log(`BREACH ${what}: claw F${cl.F} P${cl.P}\n  claw:  ${cl.notes}` + thumbs.map((th) => `\n  thumb: F${th.F} P${th.P} ${th.notes}`).join('')); };
for (const pitch of S.PITCHES) {
  const b0 = breach; let pn = 0;
  for (const c of cases(pitch)) {
    const go = (slen, sa, pa) => run(pitch, c.pos, c.ang, slen, c.btn, c.sh, sa, pa);
    // quick: a 3-tick flick, linked both ways at gaps 0..12
    for (const order of ['stick-press', 'press-stick']) for (let g = 0; g <= 12; g++) {
      const sAt = order === 'stick-press' ? T0 : T0 + g, pAt = order === 'stick-press' ? T0 + g : T0;
      const cl = go(3, sAt, pAt), thumbs = Math.abs(sAt - pAt) >= THUMB ? [cl] : [go(3, sAt, Math.max(pAt, sAt + 3 + THUMB)), go(3, pAt + THUMB, pAt)];
      n++; pn++; if (!fair(cl, thumbs)) report(`${pitch} ${c.name} quick ${order} gap ${g}`, cl, thumbs);
    }
    // the hold (K3): the stick out 40 ticks, the claw pressing at every tick of it; one thumb presses 6 after letting go,
    // or presses first and moves to the stick 6 later
    const H = 40;
    for (let g = 0; g <= H; g += 2) {
      const cl = go(H, T0, T0 + g), thumbs = [go(H, T0, T0 + H + THUMB), go(H, T0 + g + THUMB, T0 + g)];
      n++; pn++; if (!fair(cl, thumbs)) report(`${pitch} ${c.name} hold, claw press at +${g}`, cl, thumbs);
    }
  }
  console.log(`${pitch}: ${pn} links, ${breach - b0} with a claw gain`);
}
console.log(`${n} links, ${breach} breaches`);
process.exit(breach ? 1 : 0);
