// City step one read (EP brief 2026-11-06; docs/design/playable-build.md section 4; docs/ep/proposals/controller-vision.md section 4): the civilian band and match length with the town-visit and wall-push levers on.
//   node qa/godot/city-read.js name=records.json [name=records.json ...] > table.md
// One column a records file (an arm). Records come from qa/godot/records.gd on a whole-ring planet (QA_PLANET gen=3, cols=4800; farPeople on, World's places-reached park), the levers through QA_FORCE (walk=, visit=)
// and, for the wall push, a scripted human on slot 0 (QA_HUMAN=mash|push|pushx; push ends a string in B so the slam is delivered, pushx is the X-only lean), because DirWalk.landed returns for an AI slot. Targets: length median 360 to 480 s, p10 at least 300 s, p90 at most 660 s;
// civilians lost 12 to 30% of the people in the places the fight reached (RL-245); QA never tunes toward a share, and RL-247 keeps the toll a design guard, not a public figure.
const fs = require('fs');
const sum = a => a.reduce((x, y) => x + y, 0);
const mean = a => (a.length ? sum(a) / a.length : NaN);
const q = (a, p) => { if (!a.length) return NaN; const b = [...a].sort((x, y) => x - y); const i = (b.length - 1) * p, lo = Math.floor(i), hi = Math.ceil(i); return b[lo] + (b[hi] - b[lo]) * (i - lo); };
let seed = 12345;
const rnd = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };
function boot(a, f, n = 2000) {
  if (a.length < 2) return [NaN, NaN];
  const v = [];
  for (let i = 0; i < n; i++) { const s = []; for (let j = 0; j < a.length; j++) s.push(a[Math.floor(rnd() * a.length)]); v.push(f(s)); }
  return [q(v, 0.025), q(v, 0.975)];
}
const ci = (a, f, d = 1) => { const [lo, hi] = boot(a, f); return `${f(a).toFixed(d)} (${lo.toFixed(d)} to ${hi.toFixed(d)})`; };
const cols = process.argv.slice(2).map(s => { const k = s.indexOf('='); return { name: s.slice(0, k), recs: JSON.parse(fs.readFileSync(s.slice(k + 1), 'utf8')) }; });
const rows = [];
const row = (label, f, band) => rows.push([label, ...cols.map(c => { try { return f(c.recs); } catch (e) { return 'n/a'; } }), band]);
const len = R => R.map(r => (r.koAt >= 0 ? r.koAt : 900));
row('matches', R => String(R.length), '');
row('human slot / levers', R => `${R[0].human || 'AI v AI'} / ${R[0].force || 'data'}`, '');
row('length median, s (95% interval)', R => ci(len(R), a => q(a, 0.5), 0), '360 to 480');
row('length p10, s', R => ci(len(R), a => q(a, 0.1), 0), 'at least 300');
row('length p90, s', R => ci(len(R), a => q(a, 0.9), 0), 'at most 660');
row('matches ending by KO (rest hit the 900 s cap)', R => `${R.filter(r => r.koAt >= 0).length} of ${R.length}`, '');
row('civilians lost, places reached, mean % (95% interval)', R => { const w = R.filter(r => Number.isFinite(r.reachedPct)); return ci(w.map(r => r.reachedPct), mean, 1); }, '12 to 30');
row('  median / p90 of a match, %', R => { const w = R.filter(r => Number.isFinite(r.reachedPct)).map(r => r.reachedPct); return `${q(w, 0.5).toFixed(1)} / ${q(w, 0.9).toFixed(1)}`; }, '');
row('  matches over 30%', R => { const w = R.filter(r => Number.isFinite(r.reachedPct)); return `${w.filter(r => r.reachedPct > 30).length} of ${w.length}`; }, '');
row('  whole-planet total, mean % (information)', R => { const w = R.filter(r => Number.isFinite(r.wholePop)); return mean(w.map(r => 100 * r.wholeLost / Math.max(1, r.wholePop))).toFixed(2); }, 'information');
row('  the old figure (first ring), mean %', R => mean(R.filter(r => Number.isFinite(r.civPct)).map(r => r.civPct)).toFixed(1), 'information');
row('  places reached a match (far ones)', R => { const w = R.filter(r => Number.isFinite(r.nReachedPlaces)); return `${mean(w.map(r => r.nReachedPlaces)).toFixed(1)} (${mean(w.map(r => r.nReachedPlaces - (r.nPlaces - r.nFarPlaces))).toFixed(1)})`; }, '');
row('structures lost a match', R => ci(R.map(r => r.structs), mean, 1), '');
row('sends into a building a match (landings that end on one)', R => ci(R.map(r => (r.landingsAll || {}).brunt || 0), mean, 2), '4 to 8 (GD)');
// A wall slam is World's building_hit with outcome "wall" (the face held him): records.gd `wallSlams` (and `bh.wall.n`). landingsAll.wall is the terrain-wall journey end and files a building slam as "brunt" (Encounter's city diagnosis, EP 2026-11-07).
row('wall slams a match (building_hit, outcome wall)', R => ci(R.map(r => (r.wallSlams != null ? r.wallSlams : ((r.bh || {}).wall || {}).n || 0)), mean, 2), '1 to 3');
row('  ... slot 0\'s body hit (the human thrown) / slot 1\'s body hit (the AI thrown: the human\'s slams), a match', R => { const w = R.map(r => r.wallSlamsBy || [0, 0]); return `${mean(w.map(a => a[0])).toFixed(2)} / ${mean(w.map(a => a[1])).toFixed(2)}`; }, '');
row('knock-backs a match (exchange_end)', R => mean(R.map(r => (r.exEndEvents || {}).knockback || 0)).toFixed(2), 'information');
row('B holds of the scripted human a match', R => mean(R.map(r => r.humanB || 0)).toFixed(2), 'information');
row('time near a building, % of samples', R => { const w = R.filter(r => r.nearN > 0); return (100 * sum(w.map(r => r.nearHit || 0)) / Math.max(1, sum(w.map(r => r.nearN)))).toFixed(1); }, '20 to 35 (GD)');
row('craters a minute (craters + impact)', R => (sum(R.map(r => (r.craters || 0) + (r.impactCraters || 0))) / Math.max(1e-9, sum(R.map(r => r.koAt >= 0 ? r.koAt : 900)) / 60)).toFixed(2), '');
row('swings a match (big)', R => mean(R.map(r => (r.swings || []).filter(e => e.type === 'swing_start' && Math.abs(Number(e.amount) || 0) >= 30).length)).toFixed(1), '6 to 12');
row('winner slot 0', R => `${R.filter(r => r.winner === 0).length} of ${R.filter(r => r.winner >= 0).length}`, '');
const L = ['| Measure | ' + cols.map(c => c.name).join(' | ') + ' | Target |', '| :--- |' + cols.map(() => ' :--- |').join('') + ' :--- |'];
for (const r of rows) L.push('| ' + r.join(' | ') + ' |');
console.log(L.join('\n'));
