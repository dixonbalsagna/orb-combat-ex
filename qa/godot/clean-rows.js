// "If globe fights feel too clean" (Game Design 2026-11-02, docs/world/ring-any-angle/game-design.md, the collateral addendum): structures and ground on the whole ring, never the people.
// Rows: time near a building (20 to 35%), sends into a building a match (4 to 8), places visited (2 to 4), felled against swings off (at least two thirds), the open sea's share (at most 25%),
// buildings broken and craters made a minute (reported; the in-frame read is Camera's and is not in the records, so these are the whole fight's).
// bands.js calls rows(R, D, A, tools) once. Whole-ring records only (a slice has no far places and no frame): every row is PENDING otherwise.
const sum = a => a.reduce((x, y) => x + y, 0);
const mean = a => (a.length ? sum(a) / a.length : NaN);

function rows(R, D, A, { fmt }) {
  const whole = D.length > 0 && D.every(r => r.ring && (r.ring.gen >= 3 || r.ring.cols >= 4800));
  const defs = [
    ['clean.near', 'Time near a building: the pair midpoint with a standing structure within 1,500 units, sampled twice a second (20 to 35%; QA\'s definition of "near")'],
    ['clean.sends', 'Sends into a building a match (landings that end on a building; 4 to 8 from a start in town, QA does not restrict the start)'],
    ['clean.visited', 'Places visited a match (first ring and far alike; a fighter within 1,500 units of one of its buildings as it fell; 2 to 4)'],
    ['clean.felled', 'Buildings felled with swings on, against swings off (at least two thirds); needs an arm "swingsoff"'],
    ['clean.sea', 'The open sea\'s share of fight time (at most 25%)'],
    ['clean.broken', 'Buildings broken a minute (reported, whole fight; the in-frame read is Camera\'s)'],
    ['clean.craters', 'Craters made a minute (reported, whole fight; the in-frame read is Camera\'s)'],
  ];
  if (!whole) { for (const [id, what] of defs) R.pending(id, '§clean', what, 'whole-ring records only (QA_PLANET gen=3, cols=4800)'); return; }
  const mins = sum(D.map(r => r.koAt)) / 60;
  const near2 = D.filter(r => r.nearN2 > 0), near = D.filter(r => r.nearN > 0);
  if (near2.length) {
    const v = 100 * sum(near2.map(r => r.nearHit2 || 0)) / sum(near2.map(r => r.nearN2));
    const old = near.length ? (100 * sum(near.map(r => r.nearHit || 0)) / sum(near.map(r => r.nearN))).toFixed(1) : 'n/a';
    R.point('clean.near', '§clean', defs[0][1], { v, lo: 20, hi: 35, unit: 'num', note: `% of ${sum(near2.map(r => r.nearN2))} samples, Game Design's 2026-11-06 definition (the pair midpoint within 1,500 units of a standing footprint by true ground distance, no more than 1,500 above its top); the older along-the-line sample reads ${old}%` });
  } else if (near.length) {
    const v = 100 * sum(near.map(r => r.nearHit || 0)) / sum(near.map(r => r.nearN));
    R.point('clean.near', '§clean', defs[0][1], { v, lo: 20, hi: 35, unit: 'num', note: `% of ${sum(near.map(r => r.nearN))} samples, the older along-the-line sample (any depth and height)` });
  } else R.pending('clean.near', '§clean', defs[0][1], 'records carry no nearN (an older records.gd)');
  const town = D.every(r => r.start === 'town');   // Game Design 2026-11-06: 4 to 8 from a start in town (--start=town), 3 to 6 from any start; the crossing start does nothing on a planet ring
  R.point('clean.sends', '§clean', defs[1][1], { v: mean(D.map(r => (r.landingsAll || {}).brunt || 0)), lo: town ? 4 : 3, hi: town ? 8 : 6, unit: 'num', note: town ? 'from a start in town (--start=town): 4 to 8' : 'from any start: 3 to 6 (the town band, 4 to 8, needs --start=town)' });
  const vis2 = D.filter(r => Number.isFinite(r.visited));
  const vis = D.filter(r => Number.isFinite(r.nReachedPlaces) && Number.isFinite(r.nPlaces) && Number.isFinite(r.nFarPlaces));
  if (vis2.length) R.point('clean.visited', '§clean', defs[2][1], { v: mean(vis2.map(r => r.visited)), lo: 2, hi: 4, unit: 'num', note: `places visited a match, first ring and far alike: a place counts once a fighter within 1,500 units (true ground distance over the footprint) of one of its buildings was there as it fell (Game Design 2026-11-06); a fall with no fighter that close is not a visit (${mean(vis2.map(r => r.fallsFar || 0)).toFixed(1)} a match). Under 2 is the fault; over 4 is information unless time near is over too` });
  else if (vis.length) R.point('clean.visited', '§clean', defs[2][1], { v: mean(vis.map(r => r.nReachedPlaces - (r.nPlaces - r.nFarPlaces))), lo: 2, hi: 4, unit: 'num', note: 'reached far places = reached places less the first ring (needs the places-reached park and farPeople on)' });
  else R.pending('clean.visited', '§clean', defs[2][1], 'needs the places-reached records (World\'s park)');
  const off = A.swingsoff;
  if (off && off.length) {
    const a = mean(D.map(r => r.structs)), b = mean(off.map(r => r.structs));
    R.add({ id: 'clean.felled', ref: '§clean', what: defs[3][1], status: b > 0 && a / b >= 2 / 3 ? 'PASS' : 'FAIL', value: `${a.toFixed(1)} on against ${b.toFixed(1)} off (${(100 * a / Math.max(1e-9, b)).toFixed(0)}%)`, band: 'at least 67%', note: `${D.length} against ${off.length} matches` });
  } else R.pending('clean.felled', '§clean', defs[3][1], 'needs an arm "swingsoff" (setup swing=off) on the same seeds');
  const secs = sum(D.map(r => sum(Object.values(r.fightSec || {}))));
  const sea = sum(D.map(r => (r.fightSec || {}).ocean || 0));
  R.point('clean.sea', '§clean', defs[4][1], { v: 100 * sea / Math.max(1e-9, secs), hi: 25, unit: 'num', note: '% of fight time with a fighter over open ocean (both fighters\' seconds)' });
  R.info('clean.broken', '§clean', defs[5][1], (sum(D.map(r => r.structs)) / mins).toFixed(2), `${mins.toFixed(0)} minutes, ${D.length} matches`);
  R.info('clean.craters', '§clean', defs[6][1], (sum(D.map(r => (r.craters || 0) + (r.impactCraters || 0))) / mins).toFixed(2), 'craters plus impact craters');
}

module.exports = { rows };
