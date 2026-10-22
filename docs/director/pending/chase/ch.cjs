// ch.cjs: the AI's chase of a launch it threw (Game Design's rulings-2026-10-22.md 5d), behind data/director/ai.json
// chase.enabled (false). With it off nothing runs, so play and the golden don't move. Applies after the wall kick
// (wk2.cjs): its slots follow the wall kick's.
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
if (!fs.existsSync(path.join(root, 'sim/director/wallkick.gd')) && !check) throw new Error('the wall kick (wk2.cjs) first');
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
      '\tif st == 3.0 or not DirChase.steer(S, f, o, i):   # 5d: the chase of a launch it threw (not in Escape), and the cap lifts for it\n' +
      '\t\t_capApproach(S, f, o, i)   # 4d: at a human, its free-flight approach is held near Camera\'s whip limit\n');
});
const NOTE = 'Rulings-2026-10-22 5d (sim/director/chase.gd; fight-feel.md section 1, the glide): the AI chases a launch it threw on its level\'s chaseShare of its sends (one keyed draw a send), times skyMul when the send goes up into open sky (rising faster than it travels, no building over him), only with the zip\'s ki (not paid: the chase is free flight), no sooner than its reactTicks after the send: dashed free flight straight at the sent body while he is launched, at most maxTicks, with the approach cap (approachCap, 4d) lifted. Not in the Escape stance. enabled false: nothing runs.';
edit('data/director/ai.json', rep => {
  rep('\n  "approachCap": {', '\n  "chase": {"_note": ' + JSON.stringify(NOTE) + ', "enabled": false, "skyMul": 1.5, "maxTicks": 90},\n  "approachCap": {');
  rep('\n      "approachReact": [0.1, 0.05, 0.1]\n', '\n      "approachReact": [0.1, 0.05, 0.1],\n      "chaseShare": 0.1\n');
  rep('\n      "approachReact": [0.2, 0.1, 0.15]\n', '\n      "approachReact": [0.2, 0.1, 0.15],\n      "chaseShare": 0.25\n');
  rep('\n      "approachReact": [0.3, 0.2, 0.2]\n', '\n      "approachReact": [0.3, 0.2, 0.2],\n      "chaseShare": 0.4\n');
});
{
  const sp = path.join(root, 'tools/schemas/director-ai.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  if (s.properties.chase) throw new Error('director-ai schema: chase exists already');
  s.properties.chase = { type: 'object', description: 'The AI\'s chase of a launch it threw (rulings-2026-10-22 5d).',
    properties: { _note: { type: 'string' }, enabled: { type: 'boolean', description: 'False: nothing runs.' },
      skyMul: { type: 'number', minimum: 0, description: 'The level\'s chaseShare is multiplied by this when the send goes up into open sky.' },
      maxTicks: { type: 'integer', minimum: 1, description: 'The longest chase, in live ticks.' } },
    required: ['enabled', 'skyMul', 'maxTicks'], additionalProperties: false };
  let k = 0;
  const walk = o => {
    if (!o || typeof o !== 'object') return;
    if (o.properties && o.properties.beamAnswer && o.properties.brawl && o.properties.zipShare) {
      if (o.properties.chaseShare) throw new Error('director-ai schema: chaseShare exists already');
      o.properties.chaseShare = { type: 'number', minimum: 0, maximum: 1, description: 'The share of its sends it chases (rulings-2026-10-22 5d: 10, 25, 40%).' };
      k++;
      return;
    }
    for (const v of Object.values(o)) walk(v);
  };
  walk(s);
  if (k !== 3) throw new Error('director-ai schema: expected 3 levels, found ' + k);
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-ai.schema.json: chase, chaseShare x' + k + (check ? ' (checked)' : ''));
}
