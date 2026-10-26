// ws.cjs: a fighter dropped into water surfaces within 30 ticks, whatever he presses, and counts as landed there (Game
// Design's rulings-2026-10-26 row 6, on 23b item 7). Drops only (SimFighter.drop): a launched body is World's surfacing
// rule (docs/world/pending/surfacing). Behind data/director/interrupts.json water.enabled (false), so the golden doesn't
// move. After the chase (its slots follow DirChase's). The water is World's WorldWater.surfaceAt, less waded water.
//   node ws.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node ws.cjs <checkout root> [--check]');
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
if (!fs.existsSync(path.join(root, 'sim/director/chase.gd'))) throw new Error('the chase first (DirWater\'s slots follow DirChase\'s)');
if (fs.existsSync(path.join(root, 'sim/director/water.gd'))) throw new Error('sim/director/water.gd exists already');
for (const f of ['water.gd', 'water.gd.uid']) {
  const from = path.join(__dirname, 'files/sim/director', f);
  if (!fs.existsSync(from)) { if (f.endsWith('.uid')) continue; throw new Error('missing ' + from); }
  if (!check) fs.copyFileSync(from, path.join(root, 'sim/director', f));
  console.log('sim/director/' + f + (check ? ': present' : ': copied'));
}
edit('sim/director/exchange.gd', rep => {
  rep('\tDirBrawl.laTick(S)   # 10c: launch anywhere notes when each fighter came down from a launch\n',
      '\tDirBrawl.laTick(S)   # 10c: launch anywhere notes when each fighter came down from a launch\n' +
      '\tDirWater.tick(S)   # a drop into the water surfaces within water.surfaceTicks (rulings-2026-10-26 row 6)\n');
});
edit('data/director/interrupts.json', rep => {
  rep('takes the dodge back."\n  }\n}',
      'takes the dodge back."\n  },\n' +
      '  "water": {\n' +
      '    "enabled": false,\n' +
      '    "surfaceTicks": 30,\n' +
      '    "riseTicks": 10,\n' +
      '    "_note": "Game Design\'s rulings-2026-10-26 row 6 (on 23b item 7): a fighter whose drop (the zip\'s knock-down) takes him under the water surfaces within surfaceTicks live ticks of going under, whatever he presses, rising over the last riseTicks; he counts as landed when he surfaces (a rally\'s end). A launched body is World\'s surfacing rule (data/biomes/water.json surface). Waded water is not under. A fighter who dives by himself is never brought up (sim/director/water.gd, DirWater)."\n' +
      '  }\n}');
});
{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  if (s.properties.water) throw new Error('director-interrupts schema: water exists already');
  s.properties.water = { type: 'object', additionalProperties: false, required: ['enabled', 'surfaceTicks', 'riseTicks'],
    description: 'A fighter dropped into water surfaces (Game Design\'s rulings-2026-10-26 row 6): within surfaceTicks of going under, rising over riseTicks.',
    properties: { _note: { type: 'string' }, enabled: { type: 'boolean' }, surfaceTicks: { type: 'integer', minimum: 1 }, riseTicks: { type: 'integer', minimum: 1 } } };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: water' + (check ? ' (checked)' : ''));
}
