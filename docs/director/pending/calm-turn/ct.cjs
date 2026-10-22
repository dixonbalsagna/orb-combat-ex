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
edit('sim/director/exchange.gd', rep => {
  rep('\t\t\tf.stunTicks = maxi(f.stunTicks, int(pz.ticks))\n\t\tSimEvents.feed(S, f.name + " TRANSFORMS", "tier " + SimMathx.jstr(f.tier))\n',
      '\t\t\tf.stunTicks = maxi(f.stunTicks, int(pz.ticks))\n' +
      '\t\tDirCalm.atPause(S, f, pz)   # the calm-moment turn\'s first moment (Game Design\'s 5a): a pausing step, the pivot fixed as it starts\n' +
      '\t\tSimEvents.feed(S, f.name + " TRANSFORMS", "tier " + SimMathx.jstr(f.tier))\n');
});
edit('sim/director/melee.gd', rep => {
  rep('\tDirBrawl.markKind(S, tgt, lkind)\n',
      '\tDirCalm.atSend(S, att, tgt, r.best)   # the calm-moment turn: the moment after this landing is coming, so World is asked now\n' +
      '\tDirBrawl.markKind(S, tgt, lkind)\n');
});
const NOTE = 'The calm-moment turn, the director\'s part (sim/director/calm.gd; docs/director/calm-turn.md; Game Design\'s rulings-2026-10-19b.md section 1 with 1e, and rulings-2026-10-22.md 5a; the EP\'s of 2026-10-22: no ring read on the swap tick, the warm rate at most 32; World\'s WorldEpoch). The ask: at a pausing form step (full or short; live is not one) the pivot is the pair\'s midpoint as the pause starts and one ring is warmed, only a bearing that keeps the ground rule there being taken; at a launch\'s send the pivot is predicted (between the rest and the launcher, on the side it was sent), a bearing preferred that keeps the rule at the predicted spread plus predictMargin (with none, the smallest), and World\'s smallest bearing\'s ring is warmed with it as the fallback. The pick is by what a turn brings into view (score by kind: a rival\'s home, a landmark, a city, a town, his own home). The host warms the columns over the ticks to the moment, warmCols to warmColsMax a frame (the calm_turn cue carries the rate); when that is not enough by the moment, the pick waits, warming, for a later one, and a new send or pause keeps a waiting pick whose pair keeps its ground rule (else cancels it and asks again). The hold: the warm read done; the ground under each fighter moved at most World\'s moveMax (his distance from the pivot times the sine of the angle) at the chosen angle or the fallback\'s, where they stand; no exchange, approach, beam clash, taunt, flip, counter-rush, waiting attack or open finisher; and a moment: the first formTicks live ticks after a pausing form step\'s pause, or a fighter at rest from a send within landedTicks with both down or set (under setSpeed units a second); and World\'s calm. enabled false (or World\'s turn off): nothing runs.';
edit('data/director/interrupts.json', rep => {
  rep('\n  "grapple": {\n',
      '\n  "calmTurn": {\n    "_note": ' + JSON.stringify(NOTE) + ',\n    "enabled": false,\n    "landedTicks": 45,\n    "setSpeed": 60,\n    "warmCols": 16,\n    "warmColsMax": 32,\n    "formTicks": 30,\n    "predictMargin": 1500,\n    "score": {"rivalHome": 5, "landmark": 4, "city": 3, "ownHome": 2, "town": 1}\n  },\n  "grapple": {\n');
});
{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  if (s.properties.calmTurn) throw new Error('director-interrupts schema: calmTurn exists already');
  const num = d => ({ type: 'number', minimum: 0, description: d });
  s.properties.calmTurn = { type: 'object', description: 'The calm-moment turn, the director\'s part: the ask at a send, the pick, the hold.',
    properties: { _note: { type: 'string' }, enabled: { type: 'boolean', description: 'False: nothing runs.' },
      landedTicks: { type: 'integer', minimum: 0, description: 'Live ticks after he comes to rest from a send in which the landing\'s moment holds.' },
      setSpeed: num('Under this speed (units a second) a free fighter is set.'),
      warmCols: { type: 'integer', minimum: 1, description: 'The least the host is asked to warm a frame, in columns.' },
      warmColsMax: { type: 'integer', minimum: 1, description: 'The most (the EP: 32): the rate asked is the columns over the ticks to the moment, between the two (the calm_turn cue carries it), and the swap waits the columns over it, in ticks, since the pick; a pausing form step whose new ring would need more is not a moment for one.' },
      formTicks: { type: 'integer', minimum: 0, description: 'Live ticks after a pausing form step\'s pause that are a moment.' },
      predictMargin: num('At a send, added to the predicted spread from the pivot (units) when choosing a bearing that keeps World\'s moveMax.'),
      score: { type: 'object', description: 'What each place a turn brings into view is worth to the pick.',
        properties: { rivalHome: num('The rival\'s home.'), landmark: num('A landmark.'), city: num('A city.'), ownHome: num('His own home.'), town: num('A town.') },
        required: ['rivalHome', 'landmark', 'city', 'ownHome', 'town'], additionalProperties: false } },
    required: ['enabled', 'landedTicks', 'setSpeed', 'warmCols', 'warmColsMax', 'formTicks', 'predictMargin', 'score'], additionalProperties: false };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: calmTurn' + (check ? ' (checked)' : ''));
}
