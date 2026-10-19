// fh2.cjs: the forms, round 2 (Game Design's rulings of 2026-10-18, 1d; docs/architecture/forms-core.md section 7's
// Trial extras), on main with the forms holds (1a5dac67). Behind Simulation's forms switch (data/fight/forms.json
// enabled, off): with forms off, play is the same to the bit.
//   node fh2.cjs <checkout root> [--check]
//   1d Hard holds a ready step while its rival is above it, until its coil reaches 60, 75 s pass, or a region of its own
//      is battered, whichever comes first, then releases at the next break. Medium keeps its 10 s while its rival is
//      above. The level's forms conditions now all have to hold (whenAbove, coilUnder, untilBattered).
//   Trial: SimForms.blockWiden widens the perfect-block window (DirInterrupt._windowBeat), and SimForms.followBonus adds
//      brawl lights to a perfect follow-up (the riposte, DirBrawl._throw). Both are 0 with forms off or another branch.
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node fh2.cjs <checkout root> [--check]');
const check = opts.includes('--check');
function edit(rel, fn) {
  const p = path.join(root, rel);
  let t = fs.readFileSync(p, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  const rep = (a, b) => {
    const n = t.split(a).length - 1;
    if (n !== 1) throw new Error(rel + ': expected 1 match, got ' + n + ' for: ' + a.slice(0, 90));
    t = t.replace(a, () => b);
  };
  fn(rep, t);
  if (rel.endsWith('.json')) JSON.parse(t);
  if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + (check ? ': anchors ok' : ': ok'));
}
{
  const a = fs.readFileSync(path.join(root, 'sim/director/ai.gd'), 'utf8');
  if (!a.includes('static func _formHold')) throw new Error('the forms holds first (1a5dac67)');
  if (a.includes('untilBattered')) throw new Error('round 2 is in already');
  const f = fs.readFileSync(path.join(root, 'sim/core/forms.gd'), 'utf8');
  if (!f.includes('static func blockWiden') || !f.includes('static func followBonus')) throw new Error("Simulation's forms branches first (SimForms.blockWiden, followBonus)");
}

edit('sim/director/ai.gd', rep => {
  rep('## The AI\'s holds of a ready step (hero-forms.md section 4b): with forms on and steps of its own, it takes a ready step\n## at its first break unless it holds on purpose, for its level\'s forms.holdS seconds at most of the step held: while\n## its rival\'s tier is above its own (forms.whenAbove), or while its coil is under forms.coilUnder. Then it releases at\n## the next break. Off with forms off, and for a fighter without steps.\n',
      '## The AI\'s holds of a ready step (hero-forms.md section 4b, re-ruled 2026-10-18): with forms on and steps of its own,\n## it takes a ready step at its first break unless it holds on purpose, for its level\'s forms.holdS seconds at most of\n## the step held, and only while each of its level\'s conditions holds: its rival\'s tier above its own (forms.whenAbove),\n## its coil under forms.coilUnder, and no region of its own battered (forms.untilBattered). Then it releases at the next\n## break. Off with forms off, and for a fighter without steps.\n');
  rep('\tif bool(fh.get("whenAbove", false)) and o.tier > f.tier:\n\t\treturn true\n\treturn fh.has("coilUnder") and f.form.coil < float(fh.coilUnder)\n',
      '\tif bool(fh.get("whenAbove", false)) and not (o.tier > f.tier):\n\t\treturn false   # it holds only while its rival is above it\n' +
      '\tif fh.has("coilUnder") and f.form.coil >= float(fh.coilUnder):\n\t\treturn false   # ... until its coil reaches this\n' +
      '\tif bool(fh.get("untilBattered", false)):\n\t\tfor r in [SimWounds.HEAD, SimWounds.CORE, SimWounds.ARMS, SimWounds.LEGS]:\n\t\t\tif SimWounds.battered(f, r):\n\t\t\t\treturn false   # ... or a region of its own is battered\n' +
      '\treturn true\n');
});

edit('data/director/ai.json', rep => {
  rep('"forms": {"holdS": 30, "coilUnder": 60}', '"forms": {"holdS": 75, "whenAbove": true, "coilUnder": 60, "untilBattered": true}');
});

edit('sim/director/interrupt.gd', rep => {
  rep('\t\tw += float(_staleWindow(ex.A if b.args.a == "A" else ex.D))\n',
      '\t\tw += float(_staleWindow(ex.A if b.args.a == "A" else ex.D))\n\t\tw += float(SimForms.blockWiden(S, f))   # forms: a Trial form\'s wider perfect-block window (0 otherwise)\n');
});

edit('sim/director/brawl.gd', rep => {
  rep('\tif rip > 0 and not wound:\n\t\tdmg = _unit() * float(c.skillMul)\n',
      '\tif rip > 0 and not wound:\n\t\tdmg = _unit() * float(c.skillMul)\n' +
      '\tif rip > 0:\n\t\tdmg += _unit() * float(SimForms.followBonus(S, f))   # forms: a Trial form\'s perfect follow-up is worth more (0 otherwise)\n');
});

{
  const sp = path.join(root, 'tools/schemas/director-ai.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  for (const k of ['easy', 'medium', 'hard']) {
    const fm = s.properties.levels.properties[k].properties.forms;
    if (!fm || !fm.properties) throw new Error('director-ai schema: no forms for ' + k);
    fm.properties.untilBattered = { type: 'boolean', description: '... and none of its own regions battered.' };
  }
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-ai.schema.json: forms.untilBattered' + (check ? ' (checked)' : ''));
}
