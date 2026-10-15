// s2.cjs <checkout root>: one versus many, stage 2 (the partner and the ring), on a checkout with Simulation's stage 1
// applied (docs/architecture/pending/n-bodies/n_bodies.py). Every anchor is exact text; the script stops at the first
// one missing.
//   sim/director/ring.gd       new (DirRing)
//   sim/director/ai.gd         a ring guard's stick is the ring's (DirRing.aiInput)
//   sim/director/exchange.gd   a ring guard's press is refused and the one's press picks its guard (mayPress); the
//                              roles and the tags once a tick (DirRing.tick)
//   sim/director/*.gd          SimRoster.opp -> DirRing.partner (with two bodies it is SimRoster.opp, exactly)
//   data/director/interrupts.json  brawl.ring
//   tools/schemas/director-interrupts.schema.json  brawl.ring (an optional key, for Tools)
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const here = __dirname;
function edit(rel, fn) {
  const p = path.join(root, rel);
  let t = fs.readFileSync(p, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  const rep = (a, b, times) => {
    const n = t.split(a).length - 1;
    if (n !== (times || 1)) throw new Error(rel + ': expected ' + (times || 1) + ' match, got ' + n + ' for: ' + a.slice(0, 80));
    t = t.split(a).join(b);
  };
  fn(rep, () => t, v => { t = v; });
  if (rel.endsWith('.json')) JSON.parse(t);
  fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + ': ok');
}
if (!fs.readFileSync(path.join(root, 'sim/core/roster.gd'), 'utf8').includes('MAX_BODIES')) throw new Error('stage 1 is not applied (no SimRoster.MAX_BODIES)');
fs.copyFileSync(path.join(here, 'ring.gd'), path.join(root, 'sim/director/ring.gd'));
console.log('sim/director/ring.gd: new');

edit('sim/director/ai.gd', rep => {
  rep('\tif f.act.formReady:\n\t\ti.transform = true\n\tif DirBrawl.inBrawl(S, f):\n',
      '\tif f.act.formReady:\n\t\ti.transform = true\n' +
      '\tif DirRing.inRing(S, f):\n\t\tDirRing.aiInput(S, f)   # one versus many: in the ring he keeps his distance and threatens, and never presses\n\t\treturn\n' +
      '\tif DirBrawl.inBrawl(S, f):\n');
});
edit('sim/director/exchange.gd', rep => {
  rep('\tif DirBeam.inClash(S, A):\n\t\treturn\n\tvar big: bool = DirBrawl.isB(A, kind)',
      '\tif DirBeam.inClash(S, A):\n\t\treturn\n' +
      '\tif DirRing.on(S) and not DirRing.mayPress(S, A, kind):\n\t\treturn   # one versus many: a ring guard never asks for an exchange; the one\'s press picks its guard first\n' +
      '\tvar big: bool = DirBrawl.isB(A, kind)');
  rep('\tDirBands.tick(S)   # the approach before an exchange',
      '\tDirRing.tick(S)   # one versus many: the roles, and the tags the fight makes by itself\n\tDirBands.tick(S)   # the approach before an exchange');
});
// SimRoster.opp -> DirRing.partner, in the director only
let n = 0;
for (const f of fs.readdirSync(path.join(root, 'sim/director'))) {
  if (!f.endsWith('.gd') || f === 'ring.gd') continue;
  const rel = 'sim/director/' + f;
  const t = fs.readFileSync(path.join(root, rel), 'utf8');
  const k = t.split('SimRoster.opp(').length - 1;
  if (k === 0) continue;
  fs.writeFileSync(path.join(root, rel), t.split('SimRoster.opp(').join('DirRing.partner('));
  n += k;
  console.log(rel + ': ' + k + ' opp -> partner');
}
console.log('opp -> partner: ' + n);
edit('data/director/interrupts.json', rep => {
  rep('    "hitstop": {',
      '    "ring": {"enabled": true, "ringBh": [4.5, 6.5], "tagMinTicks": 30, "sliceS": 6.0, "threatEveryS": 3.0, "stepInTicks": 45, "pickBh": 1.5, "pickDeg": 45.0, ' +
      '"_note": "One versus many, stage 2 (sim/director/ring.gd; docs/director/pending/one-v-many-s2/DESIGN.md). Read only with more than two bodies. ringBh: the band round the one a ring guard keeps, in body heights. tagMinTicks: at most one tag in this many live ticks. sliceS: a partner who has held the one this long with no exchange running hands over. threatEveryS: a ring guard steps in to the band\'s inner edge at least this often, for at most stepInTicks. pickBh, pickDeg: the one\'s stick picks a guard within this far past striking distance and this many degrees of it."},\n' +
      '    "hitstop": {');
});
const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
const num = d => ({ type: 'number', minimum: 0, description: d });
s.properties.brawl.properties.ring = {
  type: 'object',
  properties: {
    enabled: { type: 'boolean', description: 'One versus many, stage 2: the partner and the ring (read only with more than two bodies).' },
    ringBh: { type: 'array', minItems: 2, maxItems: 2, items: { type: 'number', minimum: 0 }, description: 'The band round the one a ring guard keeps, in body heights.' },
    tagMinTicks: { type: 'integer', minimum: 0, description: 'At most one tag in this many live ticks.' },
    sliceS: num('A partner who has held the one this long with no exchange running hands over.'),
    threatEveryS: num('A ring guard threatens at least this often.'),
    pickBh: num("The one's stick picks a guard within this far past striking distance."),
    pickDeg: { type: 'number', minimum: 0, maximum: 180, description: "... and within this many degrees of the stick." },
    stepInTicks: { type: 'integer', minimum: 0, description: "A threat's step in lasts at most this many live ticks." }
  },
  additionalProperties: false,
  patternProperties: { '^_': true },
  description: 'One versus many, stage 2 (sim/director/ring.gd).'
};
fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
console.log('tools/schemas/director-interrupts.schema.json: brawl.ring');
