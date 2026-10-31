// The turntable's rows (docs/world/ring-any-angle/game-design.md sections 2, 10, 11 and 13, Legal's RL-213 to RL-217): swings, jolts, the nudge, their variety and their association with the toll.
// bands.js calls rows(R, D, A, tools) once. Every row is PENDING while the records carry no swing_ or nudge events, which is the case on a build without DirSwing.
// Reads rec.swings (qa/godot/records.gd): { t (tick), type, kind, src, text, amount, dur, actor }.
//   swing_start: kind or src the cause, amount the degrees, dur the ticks it runs; swing_rest: the end; "jolt" in kind, or a swing of 15 degrees or less, is the small class (section 10).
//   nudge_start: amount the degrees planned; nudge_line: a voice line played. The names follow simulation.md section 8 and encounter.md section 2; the rows are re-read when the code lands.
// First values QA picked where the page gives none are named in the row's note.
const S = require('../../prototype/tools/stats');

const sum = a => a.reduce((x, y) => x + y, 0);
const mean = a => (a.length ? sum(a) / a.length : NaN);
const BIG = 15;   // a swing of more than this many degrees is a big one; up to it, a jolt (section 10: the small class 2 to 15)

const starts = r => (r.swings || []).filter(e => e.type === 'swing_start');
const isJolt = e => /jolt/i.test(e.kind || '') || e.amount <= BIG;
const bigOf = r => starts(r).filter(e => !isJolt(e));
const joltOf = r => starts(r).filter(isJolt);
const causeOf = e => e.src || e.kind || '?';
const nudgesOf = r => (r.swings || []).filter(e => e.type === 'nudge_start');
const linesOf = r => (r.swings || []).filter(e => e.type === 'nudge_line');
const ticksOf = r => sum(starts(r).map(e => e.dur));

// Pearson r with a Fisher interval (95%); n under 4 has none.
function pearson(xs, ys) {
  const n = xs.length, mx = mean(xs), my = mean(ys);
  let sxy = 0, sxx = 0, syy = 0;
  for (let i = 0; i < n; i++) { sxy += (xs[i] - mx) * (ys[i] - my); sxx += (xs[i] - mx) ** 2; syy += (ys[i] - my) ** 2; }
  if (!(sxx > 0 && syy > 0) || n < 4) return { r: NaN, ci: [NaN, NaN], n };
  const r = sxy / Math.sqrt(sxx * syy), z = Math.atanh(Math.min(0.999999, Math.max(-0.999999, r))), se = 1 / Math.sqrt(n - 3);
  return { r, ci: [Math.tanh(z - 1.96 * se), Math.tanh(z + 1.96 * se)], n };
}

function rows(R, D, A, { fmt, wl }) {
  const anyEv = D.some(r => (r.swings || []).length);
  const NEED = 'needs swing_start events (DirSwing, Encounter; docs/world/ring-any-angle/encounter.md section 2)';
  const NEEDN = 'needs nudge_start events (the nudge, game-design.md section 13)';
  const defs = [
    ['swing.share', 'Swings: share of fight time spent swinging (10 to 15%, game-design.md section 11)'],
    ['swing.big', 'Big swings a match, mean (6 to 12)'],
    ['swing.jolts', 'Jolts a match, mean (20 to 40, section 10)'],
    ['swing.cause.max', 'Matches where no cause is over 50% of the big swings (matches with at least 6 big swings; first value at least 90%)'],
    ['swing.causes3', 'Matches with at least three causes among the big swings (matches with at least 6; "most", so over 50%)'],
    ['swing.size.bin', 'Matches where no 30 degree band of size holds over half of the big swings (matches with at least 6; first value at least 90%)'],
    ['swing.biomes', 'Biomes seen in a match, swings on against the same seeds with swings off (clearly above: at least +1 with the interval above 0)'],
    ['swing.gap.min', 'The shortest gap between two swings, a match (reported)'],
    ['swing.toll.assoc', 'No positive association between the civilian toll and a match\'s big swing count or swing time (RL-215)'],
    ['swing.civless', 'A run with the civilians removed swings the same number of times, within one (RL-215)'],
    ['nudge.turn.place', 'The nudge never turns over 6 degrees for one place (hard, section 13)'],
    ['nudge.turn.10s', 'The nudge never turns over 10 degrees in any 10 s (hard, section 13)'],
    ['nudge.rate', 'The nudge\'s rate is never over 3 degrees a second (hard, section 13)'],
    ['nudge.lines', 'Nudge voice lines a match (about 2 to 5, a soft count)'],
    ['nudge.toll.assoc', 'No positive association between the civilian toll and the nudge\'s strength or frequency (RL-216)'],
    ['hunger.toll.assoc', 'No association between the civilian toll and the Cyborg\'s Hunger (RL-217)'],
  ];
  // the arena's calm turn (data/biomes/rings.json turn, on today only behind its switch): at most maxTurns a match, gapSeconds apart. Not the swing, and read the same way with or without it.
  const turnsOf = r => (r.swings || []).filter(e => e.type === 'arena_turn');
  if (D.some(r => turnsOf(r).length)) {
    const tmax = Math.max(...D.map(r => turnsOf(r).length));
    R.add({ id: 'arena.turns.max', ref: '§swing', what: 'The arena calm turn: at most 4 a match (rings.json turn.maxTurns; hard)', status: tmax <= 4 ? 'PASS' : 'FAIL', value: `most ${tmax}; mean ${mean(D.map(r => turnsOf(r).length)).toFixed(2)} a match; ${D.filter(r => turnsOf(r).length).length} of ${D.length} matches turn`, band: 'at most 4', note: '' });
    const gaps = D.flatMap(r => { const t = turnsOf(r).map(e => e.t).sort((a, b) => a - b); return t.slice(1).map((x, i) => (x - t[i]) / 60); });
    if (gaps.length) R.add({ id: 'arena.turns.gap', ref: '§swing', what: 'The arena calm turns are at least 60 s apart (rings.json turn.gapSeconds; hard)', status: Math.min(...gaps) >= 60 ? 'PASS' : 'FAIL', value: `shortest ${Math.min(...gaps).toFixed(1)} s over ${gaps.length} gaps`, band: 'at least 60 s', note: '' });
  } else R.pending('arena.turns.max', '§swing', 'The arena calm turn: at most 4 a match, 60 s apart (hard)', 'the turn is off (data/biomes/rings.json turn.on 0) or no turn happened');
  // the right hand (pitch 4a, docs/design/right-hand-attacks-rulings.md, docs/combat/pending/stick): not thrown by the sim until Encounter's hook lands, so these wait; the claw gate itself is Controls' (sim/input/test/strike_gate_test.gd)
  const stickArm = A.stick && A.stick.length;
  if (stickArm && A.default && A.default.length) {
    const rate = recs => { const d = recs.filter(r => !r.timeout), k = d.filter(r => r.winner === 0).length; return { v: k / d.length, ci: wl(k, d.length), n: d.length }; };
    const a = rate(A.stick), b = rate(A.default), diff = a.v - b.v, se = Math.sqrt(a.v * (1 - a.v) / a.n + b.v * (1 - b.v) / b.n);
    R.add({ id: 'stick.balance', ref: '§stick', what: 'Hand-to-hand balance with stick strikes on: the Protagonist win rate within 3 points of the default arm, same seeds', status: Math.abs(diff) <= 0.03 ? 'PASS' : 'FAIL', value: `${(a.v * 100).toFixed(1)}% against ${(b.v * 100).toFixed(1)}% (${diff >= 0 ? '+' : ''}${(diff * 100).toFixed(1)} pts, se ${(se * 100).toFixed(1)})`, band: 'within 3 points', note: `${a.n} and ${b.n} decided matches` });
  } else R.pending('stick.balance', '§stick', 'Hand-to-hand balance with stick strikes on: the Protagonist win rate within 3 points of the default arm, same seeds', 'needs an arm "stick" (switches.rightStick on and the Encounter hook: stick strikes are not thrown yet)');
  R.pending('stick.claw', '§stick', 'Zero claw advantage with stick strikes on (the Controls claw-bot gate, strike_gate_test.gd: a hard test in the gate own run)', 'read the gate verdict line when it is on main; QA does not repeat it. The fight check (a scripted claw against the standard grip through the sim) needs the stick strikes thrown');
  if (!anyEv) {
    for (const [id, what] of defs) {
      const need = id.startsWith('nudge') ? NEEDN : id.startsWith('hunger') ? 'needs the Cyborg\'s Hunger stat (Combat, docs/combat/energy-movesets.md; not built)' : NEED;
      R.pending(id, '§swing', what, id === 'swing.civless' ? NEED + ' and an arm "nocivs" (the civilians removed)' : id === 'swing.biomes' ? NEED + ' and an arm "swingsoff" on the same seeds' : need);
    }
    return;
  }

  const n = D.length;
  const share = S.clusterShare(D, r => ticksOf(r), r => r.koAt * 60);
  R.rate('swing.share', '§swing', defs[0][1], { v: share.p, ci: share.ci, lo: 0.10, hi: 0.15 });
  R.point('swing.big', '§swing', defs[1][1], { v: mean(D.map(r => bigOf(r).length)), lo: 6, hi: 12 });
  R.point('swing.jolts', '§swing', defs[2][1], { v: mean(D.map(r => joltOf(r).length)), lo: 20, hi: 40 });

  const many = D.filter(r => bigOf(r).length >= 6);
  const whatNote = `${many.length} of ${n} matches have at least 6 big swings`;
  if (many.length >= 20) {
    const maxShare = r => { const c = {}; for (const e of bigOf(r)) c[causeOf(e)] = (c[causeOf(e)] || 0) + 1; return Math.max(...Object.values(c)) / bigOf(r).length; };
    const okC = many.filter(r => maxShare(r) <= 0.5).length;
    R.rate('swing.cause.max', '§swing', defs[3][1], { v: okC / many.length, ci: wl(okC, many.length), lo: 0.9, note: whatNote });
    const ok3 = many.filter(r => new Set(bigOf(r).map(causeOf)).size >= 3).length;
    R.rate('swing.causes3', '§swing', defs[4][1], { v: ok3 / many.length, ci: wl(ok3, many.length), lo: 0.5, note: whatNote });
    const binMax = r => { const c = {}; for (const e of bigOf(r)) { const b = Math.floor(e.amount / 30); c[b] = (c[b] || 0) + 1; } return Math.max(...Object.values(c)) / bigOf(r).length; };
    const okB = many.filter(r => binMax(r) <= 0.5).length;
    R.rate('swing.size.bin', '§swing', defs[5][1], { v: okB / many.length, ci: wl(okB, many.length), lo: 0.9, note: whatNote });
  } else for (const i of [3, 4, 5]) R.pending(defs[i][0], '§swing', defs[i][1], `under 20 matches with 6 big swings (${many.length} of ${n})`);

  // biomes seen against the same seeds with swings off: the arm "swingsoff" (QA_ARM or a second run with the switch off)
  const off = A.swingsoff;
  if (off && off.length) {
    const seen = r => Object.keys(r.fightSec || {}).filter(b => r.fightSec[b] > 0).length;
    const bySeed = new Map(off.map(r => [r.seed, r]));
    const pairs = D.filter(r => bySeed.has(r.seed)).map(r => seen(r) - seen(bySeed.get(r.seed)));
    if (pairs.length >= 20) {
      const m = mean(pairs), se = Math.sqrt(sum(pairs.map(x => (x - m) ** 2)) / (pairs.length - 1) / pairs.length);
      R.add({ id: 'swing.biomes', ref: '§swing', what: defs[6][1], status: m >= 1 && m - 1.96 * se > 0 ? 'PASS' : 'FAIL', value: `${m >= 0 ? '+' : ''}${m.toFixed(2)} [${(m - 1.96 * se).toFixed(2)}, ${(m + 1.96 * se).toFixed(2)}]`, band: 'at least +1, interval above 0', note: `${pairs.length} paired seeds` });
    } else R.pending('swing.biomes', '§swing', defs[6][1], 'under 20 seeds shared with the swings-off arm');
  } else R.pending('swing.biomes', '§swing', defs[6][1], 'needs an arm "swingsoff" on the same seeds');

  const gaps = D.map(r => { const t = starts(r).map(e => e.t).sort((a, b) => a - b); return t.length > 1 ? Math.min(...t.slice(1).map((x, i) => x - t[i])) / 60 : NaN; }).filter(Number.isFinite);
  R.info('swing.gap.min', '§swing', defs[7][1], gaps.length ? `median ${S.quantile(gaps.slice().sort((a, b) => a - b), 0.5).toFixed(1)} s, shortest ${Math.min(...gaps).toFixed(1)} s` : 'no match with two swings', `${gaps.length} matches with two swings or more`);

  // association with the toll: PASS unless the interval of r lies wholly above 0 (a positive association); the value is r with its interval
  const toll = D.map(r => r.civPct);
  const assoc = (id, what, xs) => {
    const p = pearson(toll, xs);
    if (!Number.isFinite(p.r)) return R.pending(id, '§swing', what, 'no spread in the toll or the count');
    return R.add({ id, ref: '§swing', what, status: p.ci[0] > 0 ? 'FAIL' : 'PASS', value: `r ${p.r.toFixed(2)} [${p.ci[0].toFixed(2)}, ${p.ci[1].toFixed(2)}]`, band: 'interval not wholly above 0', note: `${p.n} matches; QA's first rule for "no positive association"` });
  };
  const rb = pearson(toll, D.map(r => bigOf(r).length)), rt = pearson(toll, D.map(r => ticksOf(r) / 60));
  if (Number.isFinite(rb.r) && Number.isFinite(rt.r)) {
    const bad = rb.ci[0] > 0 || rt.ci[0] > 0;
    R.add({ id: 'swing.toll.assoc', ref: '§swing', what: defs[8][1], status: bad ? 'FAIL' : 'PASS', value: `count r ${rb.r.toFixed(2)} [${rb.ci[0].toFixed(2)}, ${rb.ci[1].toFixed(2)}]; time r ${rt.r.toFixed(2)} [${rt.ci[0].toFixed(2)}, ${rt.ci[1].toFixed(2)}]`, band: 'neither interval wholly above 0', note: `${rb.n} matches; a pass here is an association not found at this size, not proof of none` });
  } else R.pending('swing.toll.assoc', '§swing', defs[8][1], 'no spread in the toll or the swing counts');

  const noc = A.nocivs;
  if (noc && noc.length) {
    const d = mean(D.map(r => bigOf(r).length)) - mean(noc.map(r => bigOf(r).length));
    R.add({ id: 'swing.civless', ref: '§swing', what: defs[9][1], status: Math.abs(d) <= 1 ? 'PASS' : 'FAIL', value: `${d >= 0 ? '+' : ''}${d.toFixed(2)} big swings a match`, band: 'within 1', note: `${D.length} against ${noc.length} matches` });
  } else R.pending('swing.civless', '§swing', defs[9][1], 'needs an arm "nocivs" (the civilians removed, same seeds)');

  // the nudge
  const nud = D.flatMap(nudgesOf);
  if (!nud.length) { for (const i of [10, 11, 12, 13, 14]) R.pending(defs[i][0], '§swing', defs[i][1], NEEDN); } else {
    const over6 = nud.filter(e => e.amount > 6).length;
    R.add({ id: 'nudge.turn.place', ref: '§swing', what: defs[10][1], status: over6 ? 'FAIL' : 'PASS', value: `${over6} of ${nud.length} over 6; largest ${Math.max(...nud.map(e => e.amount)).toFixed(1)}`, band: 'none over 6', note: '' });
    let worst = 0;
    for (const r of D) { const t = nudgesOf(r).sort((a, b) => a.t - b.t); for (let i = 0; i < t.length; i++) { let tot = 0; for (let j = i; j < t.length && t[j].t - t[i].t < 600; j++) tot += t[j].amount; worst = Math.max(worst, tot); } }
    R.add({ id: 'nudge.turn.10s', ref: '§swing', what: defs[11][1], status: worst > 10 ? 'FAIL' : 'PASS', value: `${worst.toFixed(1)} degrees in the worst 10 s`, band: 'at most 10', note: 'planned degrees at each start' });
    const fast = nud.filter(e => e.dur > 0 && e.amount / (e.dur / 60) > 3.0001).length;
    R.add({ id: 'nudge.rate', ref: '§swing', what: defs[12][1], status: fast ? 'FAIL' : 'PASS', value: `${fast} of ${nud.length} planned above 3 degrees a second`, band: 'none', note: 'planned degrees over planned ticks; the eased peak is Simulation\'s own check' });
    R.point('nudge.lines', '§swing', defs[13][1], { v: mean(D.map(r => linesOf(r).length)), lo: 2, hi: 5 });
    const a1 = pearson(toll, D.map(r => sum(nudgesOf(r).map(e => e.amount)))), a2 = pearson(toll, D.map(r => nudgesOf(r).length));
    const okN = Number.isFinite(a1.r) && Number.isFinite(a2.r);
    if (okN) R.add({ id: 'nudge.toll.assoc', ref: '§swing', what: defs[14][1], status: a1.ci[0] > 0 || a2.ci[0] > 0 ? 'FAIL' : 'PASS', value: `strength r ${a1.r.toFixed(2)} [${a1.ci[0].toFixed(2)}, ${a1.ci[1].toFixed(2)}]; frequency r ${a2.r.toFixed(2)} [${a2.ci[0].toFixed(2)}, ${a2.ci[1].toFixed(2)}]`, band: 'neither interval wholly above 0', note: `${a1.n} matches` });
    else R.pending('nudge.toll.assoc', '§swing', defs[14][1], 'no spread in the toll or the nudge');
  }
  R.pending('hunger.toll.assoc', '§swing', defs[15][1], 'needs the Cyborg\'s Hunger stat (Combat, docs/combat/energy-movesets.md; not built)');
}

module.exports = { rows, pearson };
