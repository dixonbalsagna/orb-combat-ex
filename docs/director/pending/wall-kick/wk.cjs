// wk.cjs: the wall kick (Game Design's rulings-2026-10-22.md 2b, the part on the wall contact World has today, with 5c's
// after side: the push, control back, the first move void, the rush blow), behind data/director/interrupts.json
// wallKick.enabled (false). With it off nothing runs, so play and the golden don't move. Applies after
// the recoil flips (on main): its slots follow theirs. World's grant (grant_world.cjs, unchanged) lets the kick take a
// face that holds.
//   node wk.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node wk.cjs <checkout root> [--check]');
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
if (!fs.existsSync(path.join(root, 'sim/director/recoil.gd'))) throw new Error('the recoil flips (rc.cjs) first');
if (!check && !fs.readFileSync(path.join(root, 'sim/director/calm.gd'), 'utf8').includes('const CM_N: int')) throw new Error('the calm turn\'s 7b (../calm-7b/c7.cjs) first: the kick\'s slots follow its record');
for (const f of ['wallkick.gd', 'wallkick.gd.uid']) {
  const from = path.join(__dirname, 'files/sim/director', f);
  if (!fs.existsSync(from)) continue;
  const to = path.join(root, 'sim/director', f);
  if (fs.existsSync(to)) throw new Error('sim/director/' + f + ' exists already');
  if (!check) fs.copyFileSync(from, to);
  console.log('sim/director/' + f + (check ? ': new (checked)' : ': new'));
}
edit('sim/director/exchange.gd', rep => {
  rep('\tDirRecoil.tick(S)   # recoil flips: the window out of a knock-back, the flip, the landing and the counter-rush\n',
      '\tDirRecoil.tick(S)   # recoil flips: the window out of a knock-back, the flip, the landing and the counter-rush\n' +
      '\tDirWallKick.tick(S)   # the wall kick: a dodge tap just before a sent body meets a wall that holds arms it\n');
  rep('\tif DirRecoil.flipping(S, A):\n\t\treturn WAIT   # in the air of his recoil flip: the press waits for his landing\n',
      '\tif DirRecoil.flipping(S, A):\n\t\treturn WAIT   # in the air of his recoil flip: the press waits for his landing\n' +
      '\tif DirWallKick.pushing(S, A):\n\t\treturn WAIT   # in his wall kick\'s push: the press waits for its end (5c)\n');
});
edit('sim/director/bands.gd', rep => {
  rep('\tvar cr: bool = not charge and DirRecoil.counter(S, A)   # out of his recoil flip: the counter-rush, at its own speed\n',
      '\tvar cr: bool = not charge and (DirRecoil.counter(S, A) or DirWallKick.rushBlow(S, A))   # out of his recoil flip (or his wall kick\'s push toward the rival, 5c): the counter-rush, at its own speed\n');
  rep('or DirInterrupt.opening(S, A) != 0 or DirRecoil.flipping(S, A):\n',
      'or DirInterrupt.opening(S, A) != 0 or DirRecoil.flipping(S, A) or DirWallKick.pushing(S, A):\n');
  rep('\telif DirBrawl.pursues(S, A, D) or DirRecoil.due(S, A):\n',
      '\telif DirBrawl.pursues(S, A, D) or DirRecoil.due(S, A) or DirWallKick.due(S, A):\n');
});
edit('sim/director/ai.gd', rep => {
  rep('\tif f.state == "free" and DirRecoil.aiPress(S, f) == 1:\n\t\ti.light = true   # its counter-rush out of a recoil flip (DirRecoil)\n',
      '\tif f.state == "free" and (DirRecoil.aiPress(S, f) == 1 or DirWallKick.aiPress(S, f) == 1):\n\t\ti.light = true   # its counter-rush out of a recoil flip (DirRecoil), or its rush blow off a wall kick (DirWallKick)\n');
});
const NOTE = 'The wall kick (sim/director/wallkick.gd; Game Design\'s rulings-2026-10-22.md 2b and 5c; fight-feel.md section 3), on a face that holds (World\'s wall slam). A dodge tap in the last beforeTicks live ticks before he meets it arms the kick; at the contact, if he meets it at minIntoWall units a second or more into it (below that is Combat\'s plant, not built), the kick replaces the slam\'s stagger: he takes damageMul of the slam, with no hold, rebound or stagger, and the rival\'s first move after a wall slam (brawl.firstMove) is void. He kicks off toward his stick at keep of his arrival speed (neutral or into the face: straight off it; the AI: at the rival), a push of pushTicks live ticks in which his presses wait, then he has control again in free flight at the push\'s speed. A push toward the rival (within towardDot of the way to him) makes his first blow within rushBlowTicks of its start a rush blow, as the recoil flip\'s counter-rush is (recoilFlip.counterRush\'s speed, no crouch, no return, no first-move lock); into open air, plain free flight. The AI kicks on its level\'s wallKick share (ai.json), never sooner than its reaction time after the send, and presses the rush blow on its brawl.recoil.counter share. enabled false: nothing runs and no cue is sent.';
edit('data/director/interrupts.json', rep => {
  rep('\n  "grapple": {\n',
      '\n  "wallKick": {\n    "_note": ' + JSON.stringify(NOTE) + ',\n    "enabled": false,\n    "beforeTicks": 4,\n    "minIntoWall": 1500,\n    "keep": 0.6,\n    "damageMul": 0.5,\n    "pushTicks": 8,\n    "rushBlowTicks": 20,\n    "towardDot": 0.5\n  },\n  "grapple": {\n');
});
edit('data/director/ai.json', rep => {
  rep('\n      "beamAnswer": 0.15,\n', '\n      "beamAnswer": 0.15, "wallKick": 0.15,\n');
  rep('\n      "beamAnswer": 0.35,\n', '\n      "beamAnswer": 0.35, "wallKick": 0.35,\n');
  rep('\n      "beamAnswer": 0.6,\n', '\n      "beamAnswer": 0.6, "wallKick": 0.55,\n');
});
{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  if (s.properties.wallKick) throw new Error('director-interrupts schema: wallKick exists already');
  const i = (d, lo) => ({ type: 'integer', minimum: lo, description: d });
  s.properties.wallKick = { type: 'object', description: 'The wall kick: a dodge tap just before a sent body meets a wall that holds.',
    properties: {
      _note: { type: 'string' },
      enabled: { type: 'boolean', description: 'False: nothing runs and no cue is sent.' },
      beforeTicks: i('Live ticks before the contact in which a dodge tap arms the kick.', 0),
      minIntoWall: { type: 'number', minimum: 0, description: 'The least speed into the face (units a second) a kick takes; under it, Combat\'s plant.' },
      keep: { type: 'number', minimum: 0, maximum: 1, description: 'His kick-off speed, as a share of his arrival speed.' },
      damageMul: { type: 'number', minimum: 0, maximum: 1, description: 'The share of the slam\'s damage he takes.' },
      pushTicks: i('His push off the face, in live ticks: his presses wait, then he has control again.', 1),
      rushBlowTicks: i('A push toward the rival: his first blow within this many live ticks of its start is a rush blow.', 0),
      towardDot: { type: 'number', minimum: -1, maximum: 1, description: 'A push counts as toward the rival when its direction\'s dot with the way to him is at least this.' } },
    required: ['enabled', 'beforeTicks', 'minIntoWall', 'keep', 'damageMul', 'pushTicks', 'rushBlowTicks', 'towardDot'], additionalProperties: false };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: wallKick' + (check ? ' (checked)' : ''));
}
{
  const sp = path.join(root, 'tools/schemas/director-ai.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  let k = 0;
  const walk = o => {
    if (!o || typeof o !== 'object') return;
    if (o.properties && o.properties.beamAnswer && o.properties.brawl && o.properties.zipShare) {
      if (o.properties.wallKick) throw new Error('director-ai schema: wallKick exists already');
      o.properties.wallKick = { type: 'number', minimum: 0, maximum: 1, description: 'The share of its sends into a wall that holds it kicks off.' };
      k++;
      return;
    }
    for (const v of Object.values(o)) walk(v);
  };
  walk(s);
  if (k !== 3) throw new Error('director-ai schema: expected 3 levels, found ' + k);
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-ai.schema.json: wallKick x' + k + (check ? ' (checked)' : ''));
}
