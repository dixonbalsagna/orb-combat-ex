// The short-match autopsy (GD 10-26 item 34; docs/qa/rally-read-fa6f727a.md, second addendum): reads the field "at" that qa/godot/records.gd writes when QA_AUTOPSY=1.
//   QA_AUTOPSY=1 node qa/godot/run-arm.js --count=200 --out=<records.json>   then   node qa/godot/autopsy.js <records.json> [N=20]
// The N shortest matches, all of them and the N longest: damage by source as a share of the loser's damage (and per match-second), launches taken and their spacing, KOs near an anywhere action, the HP at the first one.
const fs = require('fs');
const med = a => { const b = a.filter(Number.isFinite).sort((x, y) => x - y); return b.length ? (b.length % 2 ? b[(b.length - 1) / 2] : (b[b.length / 2 - 1] + b[b.length / 2]) / 2) : NaN; };
const mean = a => a.length ? a.reduce((x, y) => x + y, 0) / a.length : NaN;
const f1 = x => (Number.isFinite(x) ? +x.toFixed(1) : null), f2 = x => (Number.isFinite(x) ? +x.toFixed(2) : null);

function one(r) {
  const at = r.at; if (!at || r.winner < 0) return null;
  const loser = 1 - r.winner, o = { koAt: r.koAt, loser, src: {}, srcAll: {}, total: 0, totalAll: 0 };
  for (const [k, v] of Object.entries(at.dc)) {
    const [vic, c] = k.split('|');
    o.srcAll[c] = (o.srcAll[c] || 0) + v; o.totalAll += v;
    if (+vic === loser) { o.src[c] = (o.src[c] || 0) + v; o.total += v; }
  }
  // anywhere actions on the loser: a launcher thrown by the winner (lc [tick, launcher, reason, targetHp]) or a pop by the winner (pops [tick, launcher, kind, poppedHp]) that is not a land/tech/burst
  const lcOn = at.lc.filter(c => c[1] === r.winner), popOn = at.pops.filter(p => p[1] === r.winner && ['up', 'slam', 'spike'].includes(p[2]));
  const acts = [...lcOn.map(c => ({ t: c[0], kind: 'launcher:' + c[2], hp: c[3] })), ...popOn.map(p => ({ t: p[0], kind: 'pop:' + p[2], hp: p[3] }))].sort((a, b) => a.t - b.t);
  o.acts = acts.length;
  o.firstAct = acts[0] || null;
  const taken = at.lt.filter(l => l[1] === loser).map(l => l[0]);
  o.launchTicks = taken; o.gaps = taken.slice(1).map((t, i) => t - taken[i]);
  o.nTaken = taken.length;
  o.nLaunchesAll = at.lt.length;
  o.nActsBoth = at.lc.length; o.nPopsBoth = at.pops.filter(p => ['up', 'slam', 'spike'].includes(p[2])).length;
  // the KO and the last anywhere action / launch on the loser
  const lastAct = acts[acts.length - 1], lastL = taken[taken.length - 1];
  o.koSinceAct = lastAct && at.ko >= 0 ? (at.ko - lastAct.t) / 60 : NaN;
  o.koSinceLaunch = lastL !== undefined && at.ko >= 0 ? (at.ko - lastL) / 60 : NaN;
  o.koWithin2Act = o.koSinceAct <= 2; o.koWithin2Launch = o.koSinceLaunch <= 2;
  // where the first HP-zero (brink) came: the first moment a fighter had hp 0 at a launch/pop/launcher, a proxy; the loser's hp at the first action
  o.firstActHp = acts[0] ? acts[0].hp : NaN; o.firstActSec = acts[0] ? acts[0].t / 60 : NaN;
  o.firstActOnLoser = null;
  // all anywhere actions of the match, either side, for the first-landed hp (the first one of the match)
  const bothActs = [...at.lc.map(c => ({ t: c[0], hp: c[3], by: c[1] })), ...at.pops.filter(p => ['up', 'slam', 'spike'].includes(p[2])).map(p => ({ t: p[0], hp: p[3], by: p[1] }))].sort((a, b) => a.t - b.t);
  o.firstAnyHp = bothActs[0] ? bothActs[0].hp : NaN; o.firstAnySec = bothActs[0] ? bothActs[0].t / 60 : NaN;
  o.sec = r.koAt;
  return o;
}

function summarise(rows, label) {
  const R = rows.filter(Boolean), tot = {}; let T = 0, totA = {}, TA = 0;
  for (const o of R) { for (const [k, v] of Object.entries(o.src)) { tot[k] = (tot[k] || 0) + v; T += v; } for (const [k, v] of Object.entries(o.srcAll)) { totA[k] = (totA[k] || 0) + v; TA += v; } }
  const share = (t, T0) => Object.fromEntries(Object.entries(t).sort((a, b) => b[1] - a[1]).map(([k, v]) => [k, f1(100 * v / T0)]));
  const secs = R.reduce((a, o) => a + o.sec, 0);
  const rate = Object.fromEntries(Object.entries(tot).sort((a, b) => b[1] - a[1]).map(([k, v]) => [k, f2(v / secs)]));   // loser damage per match-second, summed over the group
  const gaps = R.flatMap(o => o.gaps);
  return {
    label, n: R.length, medianSec: f1(med(R.map(o => o.sec))),
    loserDamageShare: share(tot, T), loserDamagePerSec: rate, bothDamageShare: share(totA, TA),
    launchesOnLoserAMatch: f2(mean(R.map(o => o.nTaken))), launchesAllAMatch: f2(mean(R.map(o => o.nLaunchesAll))),
    launchersThrownAMatch: f2(mean(R.map(o => o.nActsBoth))), popsAMatch: f2(mean(R.map(o => o.nPopsBoth))), actsOnLoserAMatch: f2(mean(R.map(o => o.acts))),
    gapsN: gaps.length, gapMedianSec: f1(med(gaps) / 60), gapUnder2sPct: f1(100 * gaps.filter(g => g <= 120).length / Math.max(1, gaps.length)), gapUnder5sPct: f1(100 * gaps.filter(g => g <= 300).length / Math.max(1, gaps.length)),
    koWithin2sOfAnywhereAct: R.filter(o => o.koWithin2Act).length, koWithin2sOfAnyLaunch: R.filter(o => o.koWithin2Launch).length, medianSecKoAfterLastAct: f1(med(R.map(o => o.koSinceAct))), medianSecKoAfterLastLaunch: f1(med(R.map(o => o.koSinceLaunch))),
    firstAnywhereHpMedian: f2(med(R.map(o => o.firstAnyHp))), firstAnywhereSecMedian: f1(med(R.map(o => o.firstAnySec))), firstAnywhereHpUnder10pct: f1(100 * R.filter(o => Number.isFinite(o.firstAnyHp) && o.firstAnyHp < 0.1).length / R.length)
  };
}
function autopsy(recs, N = 20) {
  const rows = recs.map(one).filter(Boolean).sort((a, b) => a.sec - b.sec);
  return { short: summarise(rows.slice(0, N), 'shortest ' + N), all: summarise(rows, 'all ' + rows.length), long: summarise(rows.slice(-N), 'longest ' + N) };
}
module.exports = { autopsy };
if (require.main === module) {
  const recs = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  if (!recs.some(r => r.at)) { console.error('no field "at" in these records: run with QA_AUTOPSY=1'); process.exit(2); }
  console.log(JSON.stringify(autopsy(recs, parseInt(process.argv[3] || '20', 10)), null, 1));
}
