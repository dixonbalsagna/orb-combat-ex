// X-13: every design pillar of the game seen in one match (sprint A1, A-COMBAT-08). A checklist read from the match records of qa/godot/records.gd (the event feed of each match, kept as counts and lists): each pillar of CLAUDE.md is marked seen or not seen
// by a stated test, per match, and the batch reports the share of matches that saw it and the share that saw all seven.
//   node qa/godot/pillars.js label=records.json [label=records.json ...] [--first] > table.md
// The tests are written against today's game and are deliberately plain; a pillar "not seen" says the feed holds no sign of it, not that the design fails.
//   P1 The planet is the arena:       the fight crossed the world's seam (rec.seam above 0), or was fought in three or more biomes for at least 15 s each (rec.fightSec).
//   P2 Stances, not combos:           the director composed exchanges from at least four templates (rec.melee), and at least one of them was a defender's answer (a guard, a dodge or a riposte).
//   P3 Never out of range:            a move closed a gap on its own: a zip (rec.zips), a pursuit exchange (rec.melee) or an arc send (rec.cues.arc_send).
//   P4 Power has weight:              tier 3 or more was reached by a fighter (rec.maxTier), with at least 5 craters (rec.craters) and at least 10 structures lost (rec.structs).
//   P5 Characters are personalities:  both meters moved: the menace and the anguish of the fighters (rec.menace, rec.anguish, any above 0).
//   P6 Fights tell stories:           at least three of: a brink (rec.fxCounts.brink_enter), a chain of three or more (rec.chains), a beam struggle (rec.cues.beam_struggle), a set piece (a finisher_start event or a drop), the landscape answering (a hazard_telegraph event).
//   P7 Signatures adapt:              at least two different signature variants were thrown in the match (rec.beams, by variant), by biome or stance.
const fs = require('fs');
const sum = a => a.reduce((x, y) => x + y, 0);
const files = process.argv.slice(2).filter(a => !a.startsWith('--'));
const first = process.argv.includes('--first');
const cols = files.map(s => { const k = s.indexOf('='); const d = JSON.parse(fs.readFileSync(s.slice(k + 1), 'utf8')); return { name: s.slice(0, k), recs: Array.isArray(d) ? d : d.records }; });
const num = v => (Array.isArray(v) ? Math.max(0, ...v.map(Number)) : Number(v) || 0);
const evCount = (r, ty) => (r.events || []).filter(e => e.type === ty).length;
const P = [
  ['P1 The planet is the arena', r => (r.seam || 0) > 0 || Object.values(r.fightSec || {}).filter(v => v >= 15).length >= 3],
  ['P2 Stances, not combos', r => { const m = Object.keys(r.melee || {}); return m.length >= 4 && m.some(k => /GUARD|DODGE|RIPOSTE|COUNTER/i.test(k)); }],
  ['P3 Never out of range', r => (r.zips || []).length > 0 || Object.keys(r.melee || {}).some(k => /PURSUIT/i.test(k)) || ((r.cues || {}).arc_send || 0) > 0],
  ['P4 Power has weight', r => num(r.maxTier) >= 3 && (r.craters || 0) >= 5 && (r.structs || 0) >= 10],
  ['P5 Characters are personalities', r => num(r.menace) > 0 && num(r.anguish) > 0],
  ['P6 Fights tell stories', r => {
    const s = [((r.fxCounts || {}).brink_enter || 0) > 0, (r.chains || []).some(c => c >= 3), ((r.cues || {}).beam_struggle || 0) > 0, evCount(r, 'finisher_start') > 0 || ((r.drops || {}).start || 0) > 0 || Object.keys(r.drops || {}).length > 0, evCount(r, 'hazard_telegraph') > 0];
    return s.filter(Boolean).length >= 3; }],
  ['P7 Signatures adapt', r => new Set((r.beams || []).map(b => b.variant)).size >= 2],
];
const out = [];
for (const c of cols) {
  const R = c.recs;
  out.push(`### ${c.name}: ${R.length} matches`, '', '| Pillar | Matches that saw it | Share |', '| :--- | ---: | ---: |');
  const seen = R.map(r => P.map(([, f]) => { try { return !!f(r); } catch (e) { return false; } }));
  P.forEach(([n], i) => out.push(`| ${n} | ${seen.filter(s => s[i]).length} of ${R.length} | ${(100 * seen.filter(s => s[i]).length / Math.max(1, R.length)).toFixed(1)}% |`));
  out.push(`| **All seven in one match** | ${seen.filter(s => s.every(Boolean)).length} of ${R.length} | ${(100 * seen.filter(s => s.every(Boolean)).length / Math.max(1, R.length)).toFixed(1)}% |`, '');
  if (first && R.length) { out.push(`The first match (seed ${R[0].seed}): ` + P.map(([n], i) => `${n.split(' ')[0]} ${seen[0][i] ? 'seen' : 'NOT seen'}`).join(', '), ''); }
}
console.log(out.join('\n'));
