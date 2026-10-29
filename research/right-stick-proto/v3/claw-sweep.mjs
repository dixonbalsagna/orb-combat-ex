// The claw against one thumb, swept: every pitch, a stick move (a strike each way, or a beam with RB) linked to a face
// press (X, Y, B, A, or the blasts with RB) in both orders, the claw at every gap from 0 to 10 ticks. One thumb plays the
// same inputs with 6 ticks at least between them (the fastest a thumb crosses between the stick and the buttons), in
// either order: the claw's stick or its press on its own tick and the other 6 later. The bar is zero claw gain: some
// one-thumb play starts the stick move and the press no later than the claw does (a move that never starts counts as never).
//   node research/right-stick-proto/v3/claw-sweep.mjs      (prints each pitch's count and any breach; exits 1 on a breach)
import { readFileSync } from 'node:fs';

const HTML = 'docs/ep/prototypes/right-hand-v3.html';
const src = readFileSync(HTML, 'utf8');
const a = src.indexOf('// ==== HAND SIM (no DOM) ===='), b = src.indexOf('// ==== PAGE (DOM) ====');
if (a < 0 || b < 0) throw new Error('markers not found in ' + HTML);
const S = new Function(src.slice(a, b) + '\nreturn S;')();
const THUMB = 6, T0 = 30, LEN = 130;

// one take: the stick flicked at sAt for 3 ticks at screen angle ang, the button tapped at pAt for 3, the shoulders held
function run(pitch, pos, ang, btn, sh, sAt, pAt) {
  const take = {
    len: LEN, pitch, setup: (w) => { w.P.x = pos[0]; w.P.y = pos[1]; w.V.x = pos[2]; w.V.y = pos[3]; },
    input: (w) => {
      const P = Object.assign({}, sh), t = w.t, r = ang * Math.PI / 180;
      if (t >= sAt && t < sAt + 3) { P.rx = Math.cos(r); P.ry = -Math.sin(r); } else { P.rx = 0; P.ry = 0; }
      P.lx = 0; P.ly = 0; if (t >= pAt && t < pAt + 3) P[btn] = true;
      return { P, V: {} };
    },
  };
  const clip = { n: 'SW', name: 'sweep', takes: [take], steps: [[0, '']] };
  S.CLIPS.push(clip); const r = S.newRun(S.CLIPS.length - 1, 'demo', pitch); S.CLIPS.pop();
  const said = []; let top = null;
  for (let t = 0; t < LEN - 1; t++) {
    S.stepRun(r, {});
    const lg = r.w.rd.log; for (let k = lg.length - 1; k >= 0; k--) if (lg[k] !== top && !said.includes(lg[k]) && (top == null || lg[k].t >= top.t)) said.push(lg[k]);
    top = lg[0];
  }
  const F = r.w.P.tl.find((e) => e.k === 'F'), P = said.find((n) => /^(X|Y|B|A): /.test(n.text) && !/NOT|NO KI/.test(n.text));
  return { F: F ? F.t : null, P: P ? P.t : null, notes: said.map((n) => n.t + ' ' + n.text).join(' | ') };
}

const CASES = [];
const CLOSE = [330, 0, 375, 0], RANGE = [200, 40, 480, 40];
for (const ang of [0, 90, 180, 270]) for (const btn of ['X', 'Y', 'B', 'A']) CASES.push({ name: `strike ${ang} + ${btn}`, pos: CLOSE, ang, btn, sh: {} });
for (const btn of ['X', 'Y', 'B']) CASES.push({ name: `beam + ${btn}`, pos: RANGE, ang: 0, btn, sh: { RB: true } });

let n = 0, breach = 0;
for (const pitch of ['4a', '4b', '4c']) {
  let pn = 0, pb = 0;
  for (const c of CASES) for (const order of ['stick-press', 'press-stick']) for (let g = 0; g <= 10; g++) {
    const sAt = order === 'stick-press' ? T0 : T0 + g, pAt = order === 'stick-press' ? T0 + g : T0;
    const go = (sa, pa) => run(pitch, c.pos, c.ang, c.btn, c.sh, sa, pa);
    const cl = go(sAt, pAt), thumbs = Math.abs(sAt - pAt) >= THUMB ? [cl] : [go(sAt, sAt + THUMB), go(pAt + THUMB, pAt)];
    n++; pn++;
    const late = (x) => x == null ? Infinity : x, fair = thumbs.some((th) => late(th.F) <= late(cl.F) && late(th.P) <= late(cl.P));
    if (!fair) { breach++; pb++; if (pb <= 6) console.log(`BREACH ${pitch} ${c.name} ${order} gap ${g}: claw F${cl.F} P${cl.P}\n  claw:  ${cl.notes}` + thumbs.map((th) => `\n  thumb: ${th.notes}`).join('')); }
  }
  console.log(`${pitch}: ${pn} links, ${pb} with a claw gain`);
}
console.log(`${n} links, ${breach} breaches`);
process.exit(breach ? 1 : 0);
