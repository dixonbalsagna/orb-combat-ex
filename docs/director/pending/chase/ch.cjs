// ch.cjs: the chase of a launch is the zip (Game Design's rulings-2026-10-22.md 7c; brawl-second-pass.md section 16), for
// the AI and a player. Behind data/director/interrupts.json chase.enabled (false): nothing runs, so play and the golden
// don't move. After the wall kick (wk.cjs): its slots follow the kick's.
//   node ch.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node ch.cjs <checkout root> [--check]');
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
if (!fs.existsSync(path.join(root, 'sim/director/wallkick.gd')) && !check) throw new Error('the wall kick (wk.cjs) first: the chase\'s slots follow its');
for (const f of ['chase.gd', 'chase.gd.uid']) {
  const from = path.join(__dirname, 'files/sim/director', f);
  if (!fs.existsSync(from)) continue;
  const to = path.join(root, 'sim/director', f);
  if (fs.existsSync(to)) throw new Error('sim/director/' + f + ' exists already');
  if (!check) fs.copyFileSync(from, to);
  console.log('sim/director/' + f + (check ? ': new (checked)' : ': new'));
}
edit('sim/director/ai.gd', rep => {
  rep('\t_capApproach(S, f, o, i)   # 4d: at a human, its free-flight approach is held near Camera\'s whip limit\n',
      '\tif st == 3.0 or not DirChase.steer(S, f, o, i):   # 7c: its chase of a launch it threw (not in Escape): the zip\'s rush, which the cap doesn\'t hold\n' +
      '\t\t_capApproach(S, f, o, i)   # 4d: at a human, its free-flight approach is held near Camera\'s whip limit\n');
});
edit('sim/director/exchange.gd', rep => {
  rep('\tif DirZip.takes(S, A, kind):\n',
      '\tif DirChase.takes(S, A, kind):\n\t\treturn   # 7c: LT with X or Y while his own launch flies: the chase, a zip at the body\n' +
      '\tif DirZip.takes(S, A, kind):\n');
  rep('\tDirWallKick.tick(S)   # the wall kick: a dodge tap just before a sent body meets a wall that holds arms it\n',
      '\tDirWallKick.tick(S)   # the wall kick: a dodge tap just before a sent body meets a wall that holds arms it\n' +
      '\tDirChase.tick(S)   # 7c: each chase is re-aimed, catches, or arrives at the landing\n');
});
const NOTE = 'The chase of a launch is the zip (sim/director/chase.gd; Game Design\'s rulings-2026-10-22.md 7c; brawl-second-pass.md section 16). A player presses X or Y with LT held while his own launch flies; the AI chases at a send of its own on its level\'s chaseShare (ai.json; times skyMul when the send goes up into open sky), no sooner than its reaction time. Either pays the zip\'s ki (the strike\'s or the heavy\'s); without it there is no chase. The chase is a rush at the body re-aimed each live tick at speedMul times his speed, never under minSpeed u/s. Within catchBh of him while he flies the zip\'s blow lands and sends him on (the launch planner from where he is, at sendForce, the chaser\'s stick its tilt); when his landing comes first it arrives at his landing, for the first move; at most maxTicks. enabled false: nothing runs.';
edit('data/director/interrupts.json', rep => {
  rep('\n  "grapple": {\n',
      '\n  "chase": {\n    "_note": ' + JSON.stringify(NOTE) + ',\n    "enabled": false,\n    "speedMul": 1.25,\n    "minSpeed": 1900,\n    "catchBh": 1.5,\n    "sendForce": 1600,\n    "skyMul": 1.5,\n    "maxTicks": 120\n  },\n  "grapple": {\n');
});
edit('data/director/ai.json', rep => {
  rep('\n      "approachReact": [0.1, 0.05, 0.1]\n', '\n      "approachReact": [0.1, 0.05, 0.1],\n      "chaseShare": 0.1\n');
  rep('\n      "approachReact": [0.2, 0.1, 0.15]\n', '\n      "approachReact": [0.2, 0.1, 0.15],\n      "chaseShare": 0.25\n');
  rep('\n      "approachReact": [0.3, 0.2, 0.2]\n', '\n      "approachReact": [0.3, 0.2, 0.2],\n      "chaseShare": 0.4\n');
});
{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  if (s.properties.chase) throw new Error('director-interrupts schema: chase exists already');
  const num = d => ({ type: 'number', minimum: 0, description: d });
  s.properties.chase = { type: 'object', description: 'The chase of a launch is the zip (Game Design\'s 7c).',
    properties: { _note: { type: 'string' }, enabled: { type: 'boolean', description: 'False: nothing runs.' },
      speedMul: num('The chase flies at this times the sent body\'s speed ...'), minSpeed: num('... and never under this (u/s).'),
      catchBh: num('Within this many body heights of him while he flies, the chase catches him.'),
      sendForce: num('The force the catch\'s blow sends him on with (the launch planner\'s).'),
      skyMul: num('The AI\'s chaseShare times this when the send goes up into open sky.'),
      maxTicks: { type: 'integer', minimum: 1, description: 'The longest chase, in live ticks.' } },
    required: ['enabled', 'speedMul', 'minSpeed', 'catchBh', 'sendForce', 'skyMul', 'maxTicks'], additionalProperties: false };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: chase' + (check ? ' (checked)' : ''));
}
{
  const sp = path.join(root, 'tools/schemas/director-ai.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  let k = 0;
  const walk = o => {
    if (!o || typeof o !== 'object') return;
    if (o.properties && o.properties.beamAnswer && o.properties.brawl && o.properties.zipShare) {
      if (o.properties.chaseShare) throw new Error('director-ai schema: chaseShare exists already');
      o.properties.chaseShare = { type: 'number', minimum: 0, maximum: 1, description: 'The share of its sends it chases (Game Design\'s 5d: 10, 25, 40%).' };
      k++;
      return;
    }
    for (const v of Object.values(o)) walk(v);
  };
  walk(s);
  if (k !== 3) throw new Error('director-ai schema: expected 3 levels, found ' + k);
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-ai.schema.json: chaseShare x' + k + (check ? ' (checked)' : ''));
}
