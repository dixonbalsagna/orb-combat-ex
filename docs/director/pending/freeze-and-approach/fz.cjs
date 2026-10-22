// fz.cjs: Game Design's rulings-2026-10-19b 4c and 4d, Encounter's part (docs/architecture/feel-core.md §5).
//   4c  no window gets shorter for a freeze: behind Simulation's hit-stop by weight (S.hitstopOn; data/fight/hitstop.json,
//       off), DirWindows keeps each open window's live ticks through a hit-stop, and at least freezeWindows.minLiveTicks
//       after it (sim/director/windows.gd)
//   4d  the AI's free-flight approach at a human is held near Camera's whip limit (docs/camera/whip-pan.md), behind
//       data/director/ai.json approachCap.enabled (false)
// With both switches off nothing runs, so play and the golden don't move.
//   node fz.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node fz.cjs <checkout root> [--check]');
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
if (!fs.existsSync(path.join(root, 'sim/core/hitstop.gd'))) throw new Error('Simulation\'s hit-stop by weight first');
for (const f of ['windows.gd', 'windows.gd.uid']) {
  const from = path.join(__dirname, 'files/sim/director', f);
  if (!fs.existsSync(from)) continue;
  const to = path.join(root, 'sim/director', f);
  if (fs.existsSync(to)) throw new Error('sim/director/' + f + ' exists already');
  if (!check) fs.copyFileSync(from, to);
  console.log('sim/director/' + f + (check ? ': new (checked)' : ': new'));
}
edit('sim/director/exchange.gd', rep => {
  rep('static func dirUpdate(S: SimState, dt: float) -> void:\n\tDirLocation.record(S, dt)   # location variety: the fight\'s time per biome\n',
      'static func dirUpdate(S: SimState, dt: float) -> void:\n' +
      '\t_update(S, dt)\n' +
      '\tDirWindows.afterTick(S)   # 4c: a freeze that starts now leaves every open window its live ticks (hit-stop by weight only)\n\n\n' +
      'static func _update(S: SimState, dt: float) -> void:\n\tDirLocation.record(S, dt)   # location variety: the fight\'s time per biome\n');
});
edit('sim/director/brawl.gd', rep => {
  rep('## The return\'s numbers (data/director/interrupts.json bands.return).\n',
      '## No window shorter for a freeze (DirWindows; rulings-2026-10-19b 4c): his windows that count every tick, the riposte\n' +
      '## and the launcher\'s late window, are put back by the freeze\'s ticks, and to at least `least` live ticks after it.\n' +
      'static func freezeWindows(S: SimState, f, frozen: int, least: int) -> void:\n' +
      '\tfor k in [RIP_UNTIL, LC_UNTIL]:\n' +
      '\t\tvar u: int = _g(f, k)\n' +
      '\t\tif u > 0 and u >= S.tick:\n' +
      '\t\t\t_s(f, k, maxi(u + frozen, S.tick + frozen + least))\n\n\n' +
      '## A freeze put his blow back d live ticks (DirWindows): its line\'s contact and its wind-up move with it.\n' +
      'static func holdBlow(S: SimState, f, d: int) -> void:\n' +
      '\tif _g(f, LINE) == 0:\n\t\treturn\n' +
      '\t_s(f, CONTACT, _g(f, CONTACT) + d)\n' +
      '\tif _g(f, HOLD_AT) > 0:\n\t\t_s(f, HOLD_AT, _g(f, HOLD_AT) + d)\n\n\n' +
      '## The return\'s numbers (data/director/interrupts.json bands.return).\n');
});
edit('sim/director/ai.gd', rep => {
  rep('\tif sea and f.y < 0.0 and i.my > 0.0:\n\t\ti.dash = true\n',
      '\tif sea and f.y < 0.0 and i.my > 0.0:\n\t\ti.dash = true\n' +
      '\t_capApproach(S, f, o, i)   # 4d: at a human, its free-flight approach is held near Camera\'s whip limit\n');
  rep('static var _skillText: String = ""\n',
      'static var _skillText: String = ""\n\n\n' +
      '## Rulings-2026-10-19b 4d, with Camera\'s limit (docs/camera/whip-pan.md): flying at a human rival, the AI\'s free-flight\n' +
      '## speed is held at approachCap.speed by its stick\'s reach, so his view never whips after it. The traversal dash\n' +
      '## still carries it most of the way. At another AI the demo\'s camera rides the flight, so nothing is held\n' +
      '## (approachCap.vsHumanOnly). Off: nothing changes.\n' +
      'static func _capApproach(S: SimState, f, o, i: SimIntent) -> void:\n' +
      '\tvar c: Dictionary = skill().get("approachCap", {})\n' +
      '\tif not bool(c.get("enabled", false)) or f.state != "free" or o == null:\n\t\treturn\n' +
      '\tif bool(c.get("vsHumanOnly", true)) and o.ai != null:\n\t\treturn\n' +
      '\tif i.mx * SimWrap.sdx(f.x, o.x) <= 0.0:\n\t\treturn   # not flying at him\n' +
      '\tvar sp: float = SimFighter.flightSpeed(S, f, i.dash) * SimDetMath.hypot(i.mx, i.my * 0.85)\n' +
      '\tvar cap: float = float(c.get("speed", 4000.0))\n' +
      '\tif sp > cap:\n' +
      '\t\ti.mx *= cap / sp\n' +
      '\t\ti.my *= cap / sp\n');
});
edit('data/director/interrupts.json', rep => {
  rep('\n  "grapple": {\n',
      '\n  "freezeWindows": {\n    "_note": "No window gets shorter for a freeze (Game Design\'s rulings-2026-10-19b.md 4c; sim/director/windows.gd), while Simulation\'s hit-stop by weight is on (data/fight/hitstop.json; off: nothing here runs). A window open as a hit-stop starts keeps its live ticks through it; one at least minLiveTicks long has at least that many live ticks after the freeze (a perfect block\'s on a pending strike, the chain window, the brawl\'s riposte and launcher windows). A brawl light\'s window is its own 2 ticks and is left as it is.",\n    "minLiveTicks": 5\n  },\n  "grapple": {\n');
});
edit('data/director/ai.json', rep => {
  rep('  "reactTicks": 14,\n',
      '  "approachCap": {"_note": "Rulings-2026-10-19b 4d with Camera\'s whip limit (docs/camera/whip-pan.md; sim/director/ai.gd _capApproach): in free flight at a human rival, the AI\'s speed is held at speed (units a second) by its stick\'s reach. vsHumanOnly: at another AI the demo\'s camera rides the flight and nothing is held. enabled false: nothing changes.", "enabled": false, "speed": 4000, "vsHumanOnly": true},\n  "reactTicks": 14,\n');
});
{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  if (s.properties.freezeWindows) throw new Error('director-interrupts schema: freezeWindows exists already');
  s.properties.freezeWindows = { type: 'object', description: 'No window gets shorter for a freeze (rulings-2026-10-19b 4c), with hit-stop by weight on.',
    properties: { _note: { type: 'string' }, minLiveTicks: { type: 'integer', minimum: 0, description: 'Live ticks a window at least this long keeps after a freeze.' } },
    required: ['minLiveTicks'], additionalProperties: false };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: freezeWindows' + (check ? ' (checked)' : ''));
}
{
  const sp = path.join(root, 'tools/schemas/director-ai.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  if (s.properties.approachCap) throw new Error('director-ai schema: approachCap exists already');
  s.properties.approachCap = { type: 'object', description: 'The AI\'s free-flight approach at a human, held near Camera\'s whip limit (rulings-2026-10-19b 4d).',
    properties: { _note: { type: 'string' }, enabled: { type: 'boolean', description: 'False: nothing changes.' },
      speed: { type: 'number', exclusiveMinimum: 0, description: 'The most it flies at him, units a second.' },
      vsHumanOnly: { type: 'boolean', description: 'True: only at a human rival.' } },
    required: ['enabled', 'speed', 'vsHumanOnly'], additionalProperties: false };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-ai.schema.json: approachCap' + (check ? ' (checked)' : ''));
}
