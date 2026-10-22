// ct.cjs: the calm-moment turn, the director's part (docs/director/calm-turn.md; DirCalm), on World's window 3
// (WorldEpoch; docs/world/calm-turn-world.md). Behind data/director/interrupts.json calmTurn.enabled (false) and World's
// own switch: with either off nothing runs, so the golden doesn't move. Simulation's grant (grant_sim.cjs) passes
// DirCalm.hold to WorldEpoch.tick.
//   node ct.cjs <checkout root> [--check]   (after World's window 3)
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node ct.cjs <checkout root> [--check]');
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
if (!fs.existsSync(path.join(root, 'sim/world/epoch.gd'))) throw new Error('World\'s window 3 first (sim/world/epoch.gd)');
for (const f of ['calm.gd', 'calm.gd.uid']) {
  const from = path.join(__dirname, 'files/sim/director', f);
  if (!fs.existsSync(from)) continue;
  const to = path.join(root, 'sim/director', f);
  if (fs.existsSync(to)) throw new Error('sim/director/' + f + ' exists already');
  if (!check) fs.copyFileSync(from, to);
  console.log('sim/director/' + f + (check ? ': new (checked)' : ': new'));
}
edit('sim/director/melee.gd', rep => {
  rep('\tDirBrawl.markKind(S, tgt, lkind)\n',
      '\tDirCalm.atSend(S, att, tgt, r.best)   # the calm-moment turn: the moment after this landing is coming, so World is asked now\n' +
      '\tDirBrawl.markKind(S, tgt, lkind)\n');
});
const NOTE = 'The calm-moment turn, the director\'s part (sim/director/calm.gd; docs/director/calm-turn.md; Game Design\'s rulings-2026-10-19b.md section 1 with 1e; World\'s WorldEpoch). At a launch\'s send the director asks World for the turns on the side it was sent, pivoting on its landing, and picks one by what it brings into view (score by kind: a rival\'s home, a landmark, a city, a town, his own home). The host is asked to warm the picked ring fast enough to have it by the landing (from warmCols to warmColsMax columns a frame; the calm_turn cue carries the rate) and the swap waits the ring\'s columns over that rate, in ticks, since the pick, with the sent fighter within pivotSlack of the pivot (his predicted rest) and the other within otherSlack (a new send cancels a pick still waiting and asks for its own landing), on the moment after a landing: a fighter at rest from a send within landedTicks, both down or set (under setSpeed units a second), no exchange, approach, taunt, flip, counter-rush, waiting attack or open finisher, and World\'s calm. enabled false (or World\'s turn off): nothing runs.';
edit('data/director/interrupts.json', rep => {
  rep('\n  "grapple": {\n',
      '\n  "calmTurn": {\n    "_note": ' + JSON.stringify(NOTE) + ',\n    "enabled": false,\n    "landedTicks": 30,\n    "setSpeed": 60,\n    "warmCols": 16,\n    "warmColsMax": 64,\n    "pivotSlack": 3000,\n    "otherSlack": 12000,\n    "score": {"rivalHome": 5, "landmark": 4, "city": 3, "ownHome": 2, "town": 1}\n  },\n  "grapple": {\n');
});
{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  if (s.properties.calmTurn) throw new Error('director-interrupts schema: calmTurn exists already');
  const num = d => ({ type: 'number', minimum: 0, description: d });
  s.properties.calmTurn = { type: 'object', description: 'The calm-moment turn, the director\'s part: the ask at a send, the pick, the hold.',
    properties: { _note: { type: 'string' }, enabled: { type: 'boolean', description: 'False: nothing runs.' },
      landedTicks: { type: 'integer', minimum: 0, description: 'Live ticks after he comes to rest in which the moment holds.' },
      setSpeed: num('Under this speed (units a second) a free fighter is set.'),
      warmCols: { type: 'integer', minimum: 1, description: 'The least the host is asked to warm a frame, in columns.' },
      warmColsMax: { type: 'integer', minimum: 1, description: 'The most: the rate asked is enough to have the ring read by the landing, between the two (the calm_turn cue carries it), and the swap waits the ring\'s columns over it, in ticks, since the pick.' },
      pivotSlack: num('The sent fighter must be within this of the pick\'s pivot (units) for the swap: World keeps that ground exactly.'),
      otherSlack: num('The other fighter must be within this (World\'s carry zone, where the ground fades).'),
      score: { type: 'object', description: 'What each place a turn brings into view is worth to the pick.',
        properties: { rivalHome: num('The rival\'s home.'), landmark: num('A landmark.'), city: num('A city.'), ownHome: num('His own home.'), town: num('A town.') },
        required: ['rivalHome', 'landmark', 'city', 'ownHome', 'town'], additionalProperties: false } },
    required: ['enabled', 'landedTicks', 'setSpeed', 'warmCols', 'warmColsMax', 'pivotSlack', 'otherSlack', 'score'], additionalProperties: false };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: calmTurn' + (check ? ' (checked)' : ''));
}
