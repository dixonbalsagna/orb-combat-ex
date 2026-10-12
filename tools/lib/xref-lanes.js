'use strict';
// Cross-reference rules for World's lanes window, copied to tools/lib/xref-lanes.js by docs/tools/pending/apply-lanes-window.cjs and called from xref-fight.js:
//   data/biomes/lanes.json
//     lanes-name     lane names are unique
//     lanes-order    z_front is above z_back; each lane's top is above its bottom (z is positive toward the camera)
//     lanes-overlap  the lanes run front to back and do not overlap: each lane's top is at or below the bottom of the lane before it (a gap between lanes is allowed)
//     lanes-row      a street has row -1, a block row 1 or 2, scenery and ridge row 0 or 3, and no row 0 to 3 is used twice
//     lanes-band     the street and block lanes lie inside the band, z_back to z_front (scenery stands outside it)
//     strip-lane     a strip names a lane that exists and is a street
//     strip-order    a strip's top is above its bottom
//     strip-inside   a strip lies inside its lane
//     strip-overlap  the strips of one lane do not overlap
//     lanes-demo-start  demo_start.lane is a street lane of this file, and demo_start.look is one of settlements.json's `looks`
//   data/biomes/settlements.json with the two files above
//     settle-look      every district's look is one of the file's `looks` (the index S.lanes carries)
//     settle-lane-row  every row a district names is the row of a lane of lanes.json that holds footprints (not a street)

const LF = 'data/biomes/lanes.json';
const SF = 'data/biomes/settlements.json';
const EPS = 1e-9;

function xrefLanes({ get, err, esc, isObj }) {
  const d = get(LF);
  const lanes = isObj(d) && Array.isArray(d.lanes) ? d.lanes : [];
  const num = (x) => typeof x === 'number' && Number.isFinite(x);
  if (isObj(d)) {
    if (num(d.z_front) && num(d.z_back) && d.z_front <= d.z_back) err(LF, '/z_front', 'lanes-order', `z_front ${d.z_front} must be above z_back ${d.z_back} (z is positive toward the camera)`);
    const names = new Map();
    const rows = new Map();
    lanes.forEach((l, i) => {
      if (!isObj(l)) return;
      const at = `/lanes/${i}`;
      if (typeof l.name === 'string') {
        if (names.has(l.name)) err(LF, `${at}/name`, 'lanes-name', `lane name "${l.name}" is already used at /lanes/${names.get(l.name)}`);
        else names.set(l.name, i);
      }
      if (num(l.top) && num(l.bottom) && l.top <= l.bottom) err(LF, `${at}/top`, 'lanes-order', `top ${l.top} must be above bottom ${l.bottom} (z is positive toward the camera)`);
      const want = l.kind === 'street' ? [-1] : l.kind === 'block' ? [1, 2] : l.kind === 'scenery' || l.kind === 'ridge' ? [0, 3] : null;
      if (want && Number.isInteger(l.row) && !want.includes(l.row)) err(LF, `${at}/row`, 'lanes-row', `a ${l.kind} lane has row ${want.join(' or ')} (got ${l.row})`);
      if (Number.isInteger(l.row) && l.row >= 0) {
        if (rows.has(l.row)) err(LF, `${at}/row`, 'lanes-row', `row ${l.row} is already the row of /lanes/${rows.get(l.row)}`);
        else rows.set(l.row, i);
      }
      if ((l.kind === 'street' || l.kind === 'block') && num(d.z_front) && num(d.z_back) && num(l.top) && num(l.bottom) && (l.top > d.z_front + EPS || l.bottom < d.z_back - EPS)) {
        err(LF, at, 'lanes-band', `the ${l.kind} lane ${l.bottom}..${l.top} is outside the band ${d.z_back}..${d.z_front}`);
      }
      const p = lanes[i - 1];
      if (isObj(p) && num(p.bottom) && num(l.top) && l.top > p.bottom + EPS) err(LF, `${at}/top`, 'lanes-overlap', `top ${l.top} is above the bottom ${p.bottom} of the lane before it (/lanes/${i - 1}): lanes run front to back and may not overlap`);
    });
    const byName = new Map();
    lanes.forEach((l) => { if (isObj(l) && typeof l.name === 'string' && !byName.has(l.name)) byName.set(l.name, l); });
    const perLane = new Map();
    (Array.isArray(d.strips) ? d.strips : []).forEach((s, i) => {
      if (!isObj(s)) return;
      const at = `/strips/${i}`;
      const lane = byName.get(s.lane);
      if (typeof s.lane === 'string') {
        if (!lane) err(LF, `${at}/lane`, 'strip-lane', `strip lane "${s.lane}" is not a lane of this file`);
        else if (lane.kind !== 'street') err(LF, `${at}/lane`, 'strip-lane', `strip lane "${s.lane}" is a ${lane.kind} lane; strips belong to a street`);
      }
      if (num(s.top) && num(s.bottom) && s.top <= s.bottom) err(LF, `${at}/top`, 'strip-order', `top ${s.top} must be above bottom ${s.bottom}`);
      if (lane && num(s.top) && num(s.bottom) && num(lane.top) && num(lane.bottom) && (s.top > lane.top + EPS || s.bottom < lane.bottom - EPS)) {
        err(LF, `${at}/top`, 'strip-inside', `the strip ${s.bottom}..${s.top} is outside its lane "${s.lane}" (${lane.bottom}..${lane.top})`);
      }
      if (typeof s.lane === 'string' && num(s.top) && num(s.bottom)) {
        if (!perLane.has(s.lane)) perLane.set(s.lane, []);
        perLane.get(s.lane).push({ i, top: s.top, bottom: s.bottom });
      }
    });
    for (const list of perLane.values()) {
      list.sort((a, b) => b.top - a.top);
      for (let k = 1; k < list.length; k++) {
        if (list[k].top > list[k - 1].bottom + EPS) err(LF, `/strips/${list[k].i}/top`, 'strip-overlap', `the strip ${list[k].bottom}..${list[k].top} overlaps /strips/${list[k - 1].i} (${list[k - 1].bottom}..${list[k - 1].top}) in the same lane`);
      }
    }
  }

  if (isObj(d) && isObj(d.demo_start)) {
    const ds = d.demo_start;
    const lane = typeof ds.lane === 'string' ? lanes.find((l) => isObj(l) && l.name === ds.lane) : undefined;
    if (typeof ds.lane === 'string' && !lane) err(LF, '/demo_start/lane', 'lanes-demo-start', `demo_start lane "${ds.lane}" is not a lane of this file`);
    else if (lane && lane.kind !== 'street') err(LF, '/demo_start/lane', 'lanes-demo-start', `demo_start lane "${ds.lane}" is a ${lane.kind} lane: the demo starts at a crossing of a street`);
    const sd = get(SF);
    if (typeof ds.look === 'string' && isObj(sd) && Array.isArray(sd.looks) && !sd.looks.includes(ds.look)) err(LF, '/demo_start/look', 'lanes-demo-start', `demo_start look "${ds.look}" is not in settlements.json's looks ${JSON.stringify(sd.looks)}`);
  }

  const st = get(SF);
  if (!isObj(st)) return;
  const looks = Array.isArray(st.looks) ? new Set(st.looks) : null;
  const laneRows = isObj(d) ? new Set(lanes.filter((l) => isObj(l) && Number.isInteger(l.row) && l.row >= 0).map((l) => l.row)) : null;
  (Array.isArray(st.settlements) ? st.settlements : []).forEach((s, si) => {
    if (!isObj(s)) return;
    (Array.isArray(s.districts) ? s.districts : []).forEach((dd, di) => {
      if (!isObj(dd)) return;
      const at = `/settlements/${si}/districts/${di}`;
      if (looks && typeof dd.look === 'string' && !looks.has(dd.look)) err(SF, `${at}/look`, 'settle-look', `district look "${dd.look}" is not in the file's looks ${JSON.stringify([...looks])}`);
      if (laneRows && Array.isArray(dd.rows)) {
        const missing = dd.rows.filter((r) => Number.isInteger(r) && !laneRows.has(r));
        if (missing.length) err(SF, `${at}/rows`, 'settle-lane-row', `rows ${JSON.stringify(missing)} have no lane in data/biomes/lanes.json (it has rows ${JSON.stringify([...laneRows].sort())})`);
      }
    });
  });
  void esc;
}

module.exports = { xrefLanes };
