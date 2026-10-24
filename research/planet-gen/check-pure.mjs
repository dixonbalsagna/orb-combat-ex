// Every approach is a pure function of the seed and the point: 300 points read cold (memos emptied before each),
// warm (in reverse order) and from a fresh planet must agree to the bit.
//   node research/planet-gen/check-pure.mjs [A,B,C,Cb]
import { APPROACHES } from './gen/index.mjs';
import { randUnit } from './lib/det.mjs';

const keys = (process.argv[2] || 'A,B,C,Cb').split(',');
const f64 = new Float64Array(1), u32 = new Uint32Array(f64.buffer);
const bits = (r) => r.map((v) => { f64[0] = v; return u32[0].toString(16) + u32[1].toString(16); }).join(',');
let bad = 0, n = 0;
for (const k of keys) {
  const A = APPROACHES[k], st = A.init(23), pts = Array.from({ length: 300 }, (_, i) => randUnit(99, 5, i));
  const forget = () => { if (st.clim && st.clim.forget) st.clim.forget(); };
  const cold = pts.map((p) => { forget(); return bits(A.sample(st, p[0], p[1], p[2])); });
  const warm = [...pts].reverse().map((p) => bits(A.sample(st, p[0], p[1], p[2]))).reverse();
  const st2 = A.init(23), fresh = pts.map((p) => bits(A.sample(st2, p[0], p[1], p[2])));
  let b = 0;
  for (let i = 0; i < pts.length; i++) { n++; if (cold[i] !== warm[i] || cold[i] !== fresh[i]) { bad++; b++; } }
  console.log(`${k}: ${pts.length - b} of ${pts.length} points identical cold, warm and fresh`);
}
process.exit(bad ? 1 : 0);
