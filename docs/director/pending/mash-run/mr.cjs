// mr.cjs: a mash's later blows name light_flow (Game Design's rulings-2026-10-22.md 6 (b); Simulation's mash-flow park,
// docs/architecture/pending/mash-flow: light_flow holds no stop and the budget's floor never raises it). On top of
// hit-weights-5b (a burst's light names light_mash). Only while hit-stop by weight is on: off, nothing is written, so the
// golden doesn't move. Without Simulation's park an unknown weight falls back to the hit's own stop, so apply both.
//   node mr.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node mr.cjs <checkout root> [--check]');
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
for (const f of ['mash.gd', 'mash.gd.uid']) {
  const from = path.join(__dirname, 'files/sim/director', f);
  if (!fs.existsSync(from)) continue;
  const to = path.join(root, 'sim/director', f);
  if (fs.existsSync(to)) throw new Error('sim/director/' + f + ' exists already');
  if (!check) fs.copyFileSync(from, to);
  console.log('sim/director/' + f + (check ? ': new (checked)' : ': new'));
}
edit('sim/director/brawl.gd', rep => {
  rep('\t\tDirMelee.weigh(S, a.o, weightOf(a))   # hit-stop by weight: the blow names its weight\n',
      '\t\tDirMelee.weigh(S, a.o, DirMash.name(S, f, weightOf(a)))   # hit-stop by weight: the blow names its weight (a mash\'s later blows light_flow)\n');
});
const NOTE = 'A mash\'s later blows flow (sim/director/mash.gd; Game Design\'s rulings-2026-10-22.md 6 (b); Simulation\'s light_flow). A mash is a run of one fighter\'s mashed or burst blows (a brawl blow that names light_mash), each within flowGapTicks live ticks of his last; it starts again after that many without one. Its first blow keeps light_mash; each later one names light_flow, which holds no stop. Only while hit-stop by weight is on.';
edit('data/director/interrupts.json', rep => {
  rep('\n  "grapple": {\n',
      '\n  "mash": {\n    "_note": ' + JSON.stringify(NOTE) + ',\n    "flowGapTicks": 12\n  },\n  "grapple": {\n');
});
{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  if (s.properties.mash) throw new Error('director-interrupts schema: mash exists already');
  s.properties.mash = { type: 'object', description: 'A mash\'s later blows flow (light_flow): Game Design\'s 6 (b).',
    properties: { _note: { type: 'string' },
      flowGapTicks: { type: 'integer', minimum: 0, description: 'A mashed or burst blow within this many live ticks of the fighter\'s last one is a later blow of the run (light_flow).' } },
    required: ['flowGapTicks'], additionalProperties: false };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: mash' + (check ? ' (checked)' : ''));
}
