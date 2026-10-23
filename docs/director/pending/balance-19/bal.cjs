// bal.cjs: Game Design's balance rulings for Encounter's parks (rulings-2026-10-19.md 5a and 5d; rulings-2026-10-22.md 1b and 1c), each behind the
// switch it already sits behind (launch anywhere's, the grapple's), so the golden doesn't move.
//   5a  the one-light armour: the second light must land within anywhere.armourLightTicks (6) live ticks of the first
//       to stop an answerable launcher; a later one is the new first (brawl.gd, one new launch-anywhere slot)
//   5d  the clinch is grapple.clinch.max 60 ticks at most: three pulses, where it was 90
//   node bal.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node bal.cjs <checkout root> [--check]');
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
  fn(rep);
  if (rel.endsWith('.json')) JSON.parse(t);
  if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + (check ? ': anchors ok' : ': ok'));
}
edit('sim/director/brawl.gd', rep => {
  rep('const LA_LHIT: int = 27   # ... and the lights its armour has taken (an answerable one takes one)\nconst LA_N: int = 28\n',
      'const LA_LHIT: int = 27   # ... and the lights its armour has taken (an answerable one takes one)\n' +
      'const LA_LHIT_AT: int = 28   # ... and the live tick the newest of them landed (5a: a second must land within anywhere.armourLightTicks)\n' +
      'const LA_N: int = 29\n');
  rep('\t\t\t_ls(f, LA_LHIT, 0)\n',
      '\t\t\t_ls(f, LA_LHIT, 0)\n\t\t\t_ls(f, LA_LHIT_AT, 0)\n');
  rep('\t\tif not wound and _g(o, FLAV) == 2 and _lg(o, LA_SAFE) == 3 and _lg(o, LA_LHIT) >= 1:\n\t\t\tlaStop = true   # its armour has taken its one light\n',
      '\t\tif not wound and _g(o, FLAV) == 2 and _lg(o, LA_SAFE) == 3 and _lg(o, LA_LHIT) >= 1 and _flurried(S, o):\n' +
      '\t\t\tlaStop = true   # its armour has taken its one light, and this second one lands close behind it (5a)\n');
  rep('\t\t\tif _g(o, FLAV) == 2:\n\t\t\t\t_ls(o, LA_LHIT, _lg(o, LA_LHIT) + 1)\n',
      '\t\t\tif _g(o, FLAV) == 2:\n\t\t\t\t_ls(o, LA_LHIT, _lg(o, LA_LHIT) + 1)\n\t\t\t\t_ls(o, LA_LHIT_AT, _now(S))   # the newest light it took: the next must land within armourLightTicks of it\n');
  rep('## True when a B of f\'s pressed at p is in his string (docs/design/launch-anywhere.md section 2): within anywhere.link\n',
      '## Game Design\'s 5a (rulings-2026-10-19.md): only a real flurry stops an answerable launcher. True when a light landing now\n' +
      '## comes within anywhere.armourLightTicks live ticks of the last one its armour took (0 or missing: any second light).\n' +
      'static func _flurried(S: SimState, o) -> bool:\n' +
      '\tvar w: int = int(la().get("armourLightTicks", 0))\n' +
      '\treturn w <= 0 or _now(S) - _lg(o, LA_LHIT_AT) <= w\n\n\n' +
      '## True when a B of f\'s pressed at p is in his string (docs/design/launch-anywhere.md section 2): within anywhere.link\n');
  // 1b (rulings-2026-10-22): a string of hardFromRun points or more makes the launcher hard to answer, whatever its last blow
  rep('\tvar k: int = _lg(o, LA_HITK) - 1\n\tif _now(S) < _g(o, REEL_AT) and (k == MEDIUM or k == BIG):\n\t\treturn 2\n\treturn 3\n',
      '\tvar k: int = _lg(o, LA_HITK) - 1\n\tif _now(S) < _g(o, REEL_AT) and (k == MEDIUM or k == BIG):\n\t\treturn 2\n' +
      '\tvar hr: int = int(la().get("hardFromRun", 0))\n' +
      '\tif hr > 0 and _g(f, RUN) >= hr * RUN_U:\n\t\treturn 2   # Game Design\'s 1b (rulings-2026-10-22): a real string\'s launcher is hard to answer, whatever its last blow\n' +
      '\treturn 3\n');
});
edit('sim/director/grapple.gd', rep => {
  // 1c (rulings-2026-10-22): at the time, a fighter ahead on the grip throws; only an even grip parts
  rep('\t\telse:\n\t\t\t_timeLead(S, ex, ex.A if g > 0 else ex.D, ex.D if g > 0 else ex.A)\n',
      '\t\telif bool(c.get("timeThrows", false)):\n' +
      '\t\t\tvar ld = ex.A if g > 0 else ex.D\n' +
      '\t\t\t_throw(S, ex, ld, ex.D if g > 0 else ex.A, _g(ld, CLAIM_Q), "throw")   # Game Design\'s 1c (rulings-2026-10-22): the leader throws at the time\n' +
      '\t\telse:\n\t\t\t_timeLead(S, ex, ex.A if g > 0 else ex.D, ex.D if g > 0 else ex.A)\n');
});
edit('data/director/interrupts.json', rep => {
  rep('        "mashTicks": 9,\n', '        "mashTicks": 9,\n        "armourLightTicks": 6,\n        "hardFromRun": 2,\n');
  rep('The launcher is armoured against lights (an answerable one takes one light, and a second in its wind-up stops it: 2026-10-18)',
      'The launcher is armoured against lights (an answerable one takes one light, and a second in its wind-up stops it: 2026-10-18; armourLightTicks: only if it lands within this many live ticks of the first, and a later one is the new first, so only a real flurry stops it: 2026-10-19, 5a)');
  rep('"clinch": {"max": 90, "pulse": 20,', '"clinch": {"max": 60, "timeThrows": true, "pulse": 20,');
});
{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  const a = s.properties.brawl.properties.launcher.properties.anywhere;
  if (a.properties.armourLightTicks) throw new Error('director-interrupts schema: armourLightTicks exists already');
  const out = {};
  for (const [k, v] of Object.entries(a.properties)) {
    out[k] = v;
    if (k === 'mashTicks') {
      out.armourLightTicks = { type: 'integer', minimum: 0, description: 'A second light stops an answerable launcher only if it lands within this many live ticks of the first; 0: any second light.' };
      out.hardFromRun = { type: 'integer', minimum: 0, description: 'A launcher thrown at a run of this many points or more is hard to answer, whatever its last blow; 0: off.' };
    }
  }
  if (!out.armourLightTicks) throw new Error('director-interrupts schema: no mashTicks to follow');
  a.properties = out;
  const cl = s.properties.grapple.properties.clinch;
  if (cl.properties.timeThrows) throw new Error('director-interrupts schema: clinch.timeThrows exists already');
  cl.properties.timeThrows = { type: 'boolean', description: 'At the time, a fighter ahead on the grip throws (by his last claim\'s stick); only an even grip parts. False: the leader takes the first move and both part.' };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: anywhere.armourLightTicks, hardFromRun, clinch.timeThrows' + (check ? ' (checked)' : ''));
}
