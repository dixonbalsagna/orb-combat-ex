// Game Design's row for Encounter's side-from-blow park (EP brief 2026-11-08; docs/director/pending/side-from-blow/, data/director/launch.json sideFromBlowOnly): with the stick at rest a curve (meteor or high arc) goes
// the way of the blow, so launches against the blow with the stick at rest should be 0 with the switch on.
//   node qa/godot/side-from-blow.js label=records.json [label=records.json ...] > table.md
// Records come from qa/godot/records.gd (rec.launchGeo: one row a launch, see _qa_tick). A CURVE is a launch asked of doLaunch at speed 1.0 (DirArc.send; `amt` 1.0); the sent body stands on `side` of the sender (signed, wrapped), the
// blow's way, and the curve goes toward sign(ux). AGAINST = the two signs differ. The stick is at rest in AI-v-AI (the computer's strike carries no stick aim), which is the row's condition. Ordinary launches (planner picks:
// uppercut, slam, drive down, smash across, building smash) are listed for information: their direction is the planner's and may legitimately run any way.
const fs = require('fs');
const sg = v => (v > 0 ? 1 : v < 0 ? -1 : 0);
const cols = process.argv.slice(2).map(s => { const k = s.indexOf('='); const d = JSON.parse(fs.readFileSync(s.slice(k + 1), 'utf8')); return { name: s.slice(0, k), recs: Array.isArray(d) ? d : d.records }; });
const out = ['| Arm | Matches | Launches | Curves | Curves against the blow | Share | Curves with the blow | Ordinary launches with a horizontal way (|ux| over 0.3) | ... against the blow |', '| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |'];
const detail = [];
for (const c of cols) {
  const L = []; for (const r of c.recs) for (const l of (r.launchGeo || [])) L.push({ ...l, seed: r.seed });
  const arcs = L.filter(l => l.amt === 1), plain = L.filter(l => l.amt !== 1 && Math.abs(l.ux) > 0.3 && l.side !== 0);
  const against = arcs.filter(l => sg(l.ux) !== sg(l.side) && l.side !== 0), withB = arcs.filter(l => sg(l.ux) === sg(l.side));
  const pa = plain.filter(l => sg(l.ux) !== sg(l.side));
  out.push(`| ${c.name} | ${c.recs.length} | ${L.length} | ${arcs.length} | **${against.length}** | ${arcs.length ? (100 * against.length / arcs.length).toFixed(1) + '%' : 'n/a'} | ${withB.length} | ${plain.length} | ${pa.length} |`);
  for (const l of against.slice(0, 12)) detail.push(`${c.name}: seed ${l.seed} tick ${l.t}: sender ${l.by}, sent ${l.sent}, side ${l.side}, ux ${l.ux}, plan "${l.plan}"`);
}
console.log(out.join('\n') + (detail.length ? '\n\nCurves against the blow (first 12 an arm):\n\n' + detail.map(d => '- ' + d).join('\n') : ''));
