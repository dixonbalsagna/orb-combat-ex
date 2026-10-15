// s7.cjs <checkout root>: Game Design's seventh round, the held Y (brawl-second-pass.md section 14, "The seventh
// round"), on top of the nine cells' pass 2 (r2.cjs and schema10.cjs, docs/director/pending/nine-cells-pass2/).
//  1. While he holds a charge (his wound blow past its wind-up with the button down), a light that lands on him adds
//     nothing to the run of the fighter who landed it. It still does its full damage and still takes his own run
//     down as before. A medium or anything heavier still ends the charge, and a close from anything else still does.
//  2. A charged medium's reach grows as it fills, from medium.reachBh to medium.charge.reachBh (1 bh at full), as a
//     charged heavy's does; a medium let go from a charge steps through that reach.
//  3. A missed medium, tapped or charged, leaves him open for 12 ticks (medium.recoverWhiff); a heavy stays at 20.
//  4. The AI's giving ground against a wound medium has its own share, giveVsMediumCharge (0.05, 0.25, 0.4 by
//     level), under its share against a heavy (giveGround). A medium only reaches the AI's reaction time when it is
//     held, so this is its share against a charge. The keyed draw is the same one: against a heavy nothing changes.
//  5. The full charged medium's worth is 4 (pass 2 has it so).
// The schema keys (medium.charge.reachBh; each level's brawl.giveVsMediumCharge) for Tools, as before.
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
function edit(rel, fn) {
  const p = path.join(root, rel);
  let t = fs.readFileSync(p, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  const rep = (a, b) => {
    const n = t.split(a).length - 1;
    if (n !== 1) throw new Error(rel + ': expected 1 match, got ' + n + ' for: ' + a.slice(0, 80));
    t = t.replace(a, () => b);
  };
  fn(rep, () => t, v => { t = v; });
  if (rel.endsWith('.json')) JSON.parse(t);
  fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + ': ok');
}
edit('sim/director/brawl.gd', rep => {
  // 1. lights into a held charge add nothing to the run
  rep('\tif o.stunTicks <= 0 or bool(c.flurry.staggeredAddsRun):\n\t\t_s(f, RUN, _g(f, RUN) + (int(c.burst.runHalves)',
      '\t# While o holds a charge (CHG 1 or 2: past its wind-up, the button down), a light of f\'s adds nothing to f\'s run (the\n' +
      '\t# seventh round): lights don\'t stop a charge, and what they add up to doesn\'t either. Its damage and o\'s own run are\n' +
      '\t# as for any light.\n' +
      '\tvar intoCharge: bool = (kind == LIGHT or kind == FLURRY) and (_g(o, CHG) == 1 or _g(o, CHG) == 2)\n' +
      '\tif (o.stunTicks <= 0 or bool(c.flurry.staggeredAddsRun)) and not intoCharge:\n\t\t_s(f, RUN, _g(f, RUN) + (int(c.burst.runHalves)');
  // 2. the charged medium's reach
  rep('\tif kind == MEDIUM:\n\t\treturn float(c.medium.reachBh)\n\treturn float(c.give.lightReachBh)\n',
      '\tif kind == MEDIUM:\n' +
      '\t\tif bool(a.get("charged", false)) and c.medium.has("charge") and c.medium.charge.has("reachBh"):\n' +
      '\t\t\treturn lerpf(float(c.medium.reachBh), float(c.medium.charge.reachBh), clampf(float(a.get("charge", 0.0)), 0.0, 1.0))   # it grows as it fills (the seventh round)\n' +
      '\t\treturn float(c.medium.reachBh)\n\treturn float(c.give.lightReachBh)\n');
  rep('## give.closeMaxBh, less its slack, to cover the reach of its strength. A heavy let go from a charge has the charge\'s.\n',
      '## give.closeMaxBh, less its slack, to cover the reach of its strength. A heavy or a medium let go from a charge has\n## the charge\'s.\n');
  rep('\tvar reach: float = float(c.heavy.charge.reachBh) if (kind == BIG and _g(f, CHG) == 3) else float(_wcfg(kind).reachBh)\n',
      '\tvar reach: float = float(_wcfg(kind).reachBh)\n' +
      '\tif kind == BIG and _g(f, CHG) == 3:\n\t\treach = float(c.heavy.charge.reachBh)\n' +
      '\telif kind == MEDIUM and _g(f, CHG) == 3 and c.medium.has("charge"):\n\t\treach = float(c.medium.charge.get("reachBh", c.medium.reachBh))\n');
  // 4. the AI's own share against a medium's charge
  rep('\t\t\t_s(f, AI_GSAW, oh | ((1 << 30) if SimRng.keyed(seed, "brawl.give", oh * 2 + slot) < float(bl.get("giveGround", 0.0)) else 0))\n',
      '\t\t\t# Against a medium its own share (the seventh round): a medium reaches the reaction time only when it is held.\n' +
      '\t\t\tvar gs: float = float(bl.get("giveVsMediumCharge", bl.get("giveGround", 0.0))) if _g(o, KIND) == MEDIUM else float(bl.get("giveGround", 0.0))\n' +
      '\t\t\t_s(f, AI_GSAW, oh | ((1 << 30) if SimRng.keyed(seed, "brawl.give", oh * 2 + slot) < gs else 0))\n');
});
edit('data/director/interrupts.json', rep => {
  rep('      "reelTicks": 6,\n      "recover": 0,\n      "recoverWhiff": 20,\n', '      "reelTicks": 6,\n      "recover": 0,\n      "recoverWhiff": 12,\n');
  rep('        "reelTicks": 10,\n        "staggerTicks": 12\n      }\n', '        "reelTicks": 10,\n        "staggerTicks": 12,\n        "reachBh": 1.0\n      }\n');
});
edit('data/director/ai.json', (rep, get, set) => {
  const lines = get().split('\n');
  const idx = lines.map((l, n) => (l.includes('"brawl": {"tapGap"') ? n : -1)).filter(n => n >= 0);
  if (idx.length !== 3) throw new Error('expected three brawl lines');
  const v = [0.05, 0.25, 0.4];
  idx.forEach((li, k) => {
    if (lines[li].includes('"giveVsMediumCharge"')) throw new Error('already there');
    const at = lines[li].indexOf('"giveGround": ');
    if (at < 0) throw new Error('no giveGround on a brawl line');
    const end = lines[li].indexOf(',', at);
    lines[li] = lines[li].slice(0, end + 1) + ' "giveVsMediumCharge": ' + v[k] + ',' + lines[li].slice(end + 1);
  });
  set(lines.join('\n'));
});
// the schema keys (the two schemas round-trip with two spaces)
const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
const ch = s.properties.brawl.properties.medium.properties.charge;
if (!ch) throw new Error('schema10 first: no medium.charge in the schema');
ch.properties.reachBh = { type: 'number', minimum: 0, description: 'Its reach past striking distance at full, in body heights: it grows from medium.reachBh as it fills (the seventh round).' };
fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
const ap = path.join(root, 'tools/schemas/director-ai.schema.json');
const a = JSON.parse(fs.readFileSync(ap, 'utf8'));
for (const l of ['easy', 'medium', 'hard']) {
  const b = a.properties.levels.properties[l].properties.brawl;
  b.properties.giveVsMediumCharge = { type: 'number', minimum: 0, maximum: 1, description: "The AI's share for giving ground against a held medium (the seventh round); giveGround is its share against a heavy." };
}
fs.writeFileSync(ap, JSON.stringify(a, null, 2) + '\n');
console.log('schemas: medium.charge.reachBh, brawl.giveVsMediumCharge');
