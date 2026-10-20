// rc.cjs: recoil flips (Game Design's rulings-2026-10-19.md 2a; docs/design/fight-feel.md section 2), behind
// data/director/interrupts.json recoilFlip.enabled (false). With it off nothing runs, no slot is written and no cue is
// sent, so play and the golden don't move.
//   node rc.cjs <checkout root> [--check]
// Copies files/sim/director/recoil.gd (DirRecoil) and its .uid when present, and hooks it in:
//   launch.gd     a knock-back opens the window (the skid, the upright slide, the drift)
//   exchange.gd   once a live tick: the windows, the flip, the landing; a press waits while he is in the air
//   bands.gd      the counter-rush: his approach with no crouch, no return and its own speed; from afar it flies in
//   brawl.gd      recoilFree: the flip clears the first-move lock and the return
//   ai.gd         the AI's counter press
//   interrupts.json recoilFlip and ai.json brawl.recoil (per level), and their schemas (Tools')
// World's grant (grant_world.cjs: WorldContact.recoilEnd) lets a skid be cut short; without it only the upright slide
// and the drift flip.
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node rc.cjs <checkout root> [--check]');
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
if (!fs.existsSync(path.join(root, 'sim/director/grapple.gd'))) throw new Error('the grapple G1 first');
if (!fs.readFileSync(path.join(root, 'sim/director/brawl.gd'), 'utf8').includes('const LA_N: int')) throw new Error('launch anywhere first');
for (const f of ['recoil.gd', 'recoil.gd.uid']) {
  const from = path.join(__dirname, 'files/sim/director', f);
  if (!fs.existsSync(from)) continue;
  const to = path.join(root, 'sim/director', f);
  if (fs.existsSync(to)) throw new Error('sim/director/' + f + ' exists already');
  if (!check) fs.copyFileSync(from, to);
  console.log('sim/director/' + f + (check ? ': new (checked)' : ': new'));
}

edit('sim/director/launch.gd', rep => {
  rep('\t\tSimFx.knockback(S, tgt, att, "slideLong", dist, S.tick + int(ceil(2.0 * dist / sp * DirData.TICKS_PER_SEC)))   # the end is an estimate (a steady brake); World\'s journey decides\n\t\treturn\n',
      '\t\tSimFx.knockback(S, tgt, att, "slideLong", dist, S.tick + int(ceil(2.0 * dist / sp * DirData.TICKS_PER_SEC)))   # the end is an estimate (a steady brake); World\'s journey decides\n' +
      '\t\tDirRecoil.knocked(S, att, tgt, dist, 1, S.tick + int(ceil(2.0 * dist / sp * DirData.TICKS_PER_SEC)))   # recoil flips: his window out of the skid\n\t\treturn\n');
  rep('\tSimFx.knockback(S, tgt, att, "bump" if bumpKind > 0 else ("slideShort" if slide else "drift"), dist, S.tick + int(ticks))\n',
      '\tSimFx.knockback(S, tgt, att, "bump" if bumpKind > 0 else ("slideShort" if slide else "drift"), dist, S.tick + int(ticks))\n' +
      '\tDirRecoil.knocked(S, att, tgt, dist, 2 if slide else 3, S.tick + int(ticks))   # recoil flips: his window out of the slide or the drift\n');
});
edit('sim/director/exchange.gd', rep => {
  rep('\tDirLaunch.tick(S)   # an upright slide that ends early against an obstacle: the bump\n',
      '\tDirLaunch.tick(S)   # an upright slide that ends early against an obstacle: the bump\n' +
      '\tDirRecoil.tick(S)   # recoil flips: the window out of a knock-back, the flip, the landing and the counter-rush\n');
  rep('\tif A.state != "free" and A.state != "charging":\n\t\treturn WAIT\n',
      '\tif A.state != "free" and A.state != "charging":\n\t\treturn WAIT\n' +
      '\tif DirRecoil.flipping(S, A):\n\t\treturn WAIT   # in the air of his recoil flip: the press waits for his landing\n');
});
edit('sim/director/bands.gd', rep => {
  rep('\tif (A.state != "free" and A.state != "charging") or A.stunTicks > 0 or DirInterrupt.opening(S, A) != 0:\n\t\treturn false\n\tvar D = SimRoster.opp(S, A)\n',
      '\tif (A.state != "free" and A.state != "charging") or A.stunTicks > 0 or DirInterrupt.opening(S, A) != 0 or DirRecoil.flipping(S, A):\n\t\treturn false\n\tvar D = SimRoster.opp(S, A)\n');
  rep('\telif DirBrawl.pursues(S, A, D):\n',
      '\telif DirBrawl.pursues(S, A, D) or DirRecoil.due(S, A):\n');
  rep('\tvar n: int = clampi(int(ceil(maxf(0.0, d - eng) / float(m.speed) * DirData.TICKS_PER_SEC)), int(m.minTicks), int(m.maxTicks))\n',
      '\tvar cr: bool = not charge and DirRecoil.counter(S, A)   # out of his recoil flip: the counter-rush, at its own speed\n' +
      '\tif cr:\n\t\tm = DirRecoil.cfg().counterRush\n' +
      '\tvar n: int = clampi(int(ceil(maxf(0.0, d - eng) / float(m.speed) * DirData.TICKS_PER_SEC)), int(m.minTicks), int(m.maxTicks))\n');
  rep('if (b == MID and not charge) else 0\n',
      'if (b == MID and not charge and not cr) else 0   # (the counter-rush has no crouch)\n');
  rep('\tvar ret: bool = DirBrawl.returning(S, A)\n',
      '\tvar ret: bool = DirBrawl.returning(S, A) and not cr\n');
});
edit('sim/director/brawl.gd', rep => {
  rep('## True while the first move is the rival\'s: f was sent, and is free for fewer than firstMove.lockTicks.\n',
      '## A recoil flip (DirRecoil): he is no longer sent, the first move is not the rival\'s, and he is not returning.\n' +
      'static func recoilFree(f) -> void:\n\t_s(f, SENT, 0)\n\t_s(f, MOVE_AT, 0)\n\t_s(f, RET_N, 0)\n\n\n' +
      '## True while the first move is the rival\'s: f was sent, and is free for fewer than firstMove.lockTicks.\n');
});
edit('sim/director/ai.gd', rep => {
  rep('\telif za == 4:\n\t\ti.heavy = true\n\tvar st: float = a.st\n',
      '\telif za == 4:\n\t\ti.heavy = true\n' +
      '\tif f.state == "free" and DirRecoil.aiPress(S, f) == 1:\n\t\ti.light = true   # its counter-rush out of a recoil flip (DirRecoil)\n' +
      '\tvar st: float = a.st\n');
});
const NOTE = 'Recoil flips (sim/director/recoil.gd; Game Design\'s rulings-2026-10-19.md 2a, fight-feel.md section 2). A dodge tap in the first windowTicks live ticks of a knock-back backflips him out of it: the slide ends where he is, and he is carried flipBh further back, bowed arcBh, over flipTicks, and lands set. His next blow within counterTicks of the landing is a counter-rush: an approach with no crouch, no return and no first-move lock, at counterRush\'s speed. Free: no ki, no cooldown. With no press, a knock-back on the ground over flourishOverBh ends in Animation\'s flourish (the recoil cue, text flourish). The AI flips on its level\'s brawl.recoil.flip share (ai.json), tapping aiTapTicks into the window, and follows with a counter-rush on brawl.recoil.counter of its flips, aiCounterTicks after the landing. enabled false: nothing runs and no cue is sent.';
edit('data/director/interrupts.json', rep => {
  rep('\n  "grapple": {\n',
      '\n  "recoilFlip": {\n    "_note": ' + JSON.stringify(NOTE) + ',\n    "enabled": false,\n    "windowTicks": 10,\n    "flipTicks": 12,\n    "flipBh": 1,\n    "arcBh": 0.8,\n    "counterTicks": 20,\n    "counterRush": {"speed": 6000, "minTicks": 3, "maxTicks": 12},\n    "flourishOverBh": 3,\n    "aiTapTicks": [3, 7],\n    "aiCounterTicks": [2, 8]\n  },\n  "grapple": {\n');
});
edit('data/director/ai.json', rep => {
  rep('"anywhere": {"launcher": 0.15, "inString": 0.08, "answer": 0.1}, ', '"anywhere": {"launcher": 0.15, "inString": 0.08, "answer": 0.1}, "recoil": {"flip": 0.2, "counter": 0.5}, ');
  rep('"anywhere": {"launcher": 0.35, "inString": 0.18, "answer": 0.25}, ', '"anywhere": {"launcher": 0.35, "inString": 0.18, "answer": 0.25}, "recoil": {"flip": 0.45, "counter": 0.7}, ');
  rep('"anywhere": {"launcher": 0.6, "inString": 0.28, "answer": 0.4}, ', '"anywhere": {"launcher": 0.6, "inString": 0.28, "answer": 0.4}, "recoil": {"flip": 0.7, "counter": 0.9}, ');
});
{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  if (s.properties.recoilFlip) throw new Error('director-interrupts schema: recoilFlip exists already');
  const n = (d, lo, hi) => Object.assign({ type: 'number', description: d }, lo !== undefined ? { minimum: lo } : {}, hi !== undefined ? { maximum: hi } : {});
  const i = (d, lo) => ({ type: 'integer', minimum: lo, description: d });
  const pair = d => ({ type: 'array', items: { type: 'integer', minimum: 0 }, minItems: 2, maxItems: 2, description: d });
  s.properties.recoilFlip = { type: 'object', description: 'Recoil flips: a dodge tap early in a knock-back backflips him out of it, and his next blow is a counter-rush.',
    properties: {
      _note: { type: 'string' },
      enabled: { type: 'boolean', description: 'False: nothing runs and no cue is sent.' },
      windowTicks: i('Live ticks after a knock-back in which a dodge tap flips him.', 1),
      flipTicks: i('Live ticks from the flip to his landing, set.', 1),
      flipBh: n('How much further back the flip carries him, in body heights.', 0),
      arcBh: n('How far the flip bows up at its middle, in body heights.', 0),
      counterTicks: i('Live ticks after the landing in which his next blow is a counter-rush.', 0),
      counterRush: { type: 'object', description: 'The counter-rush approach: its speed (units a second) and its ticks.',
        properties: { speed: n('Units a second.', 1), minTicks: i('At least.', 1), maxTicks: i('At most.', 1) }, required: ['speed', 'minTicks', 'maxTicks'], additionalProperties: false },
      flourishOverBh: n('With no press, a knock-back on the ground longer than this (body heights) ends in the flourish.', 0),
      aiTapTicks: pair('The AI taps this many live ticks into the window, from and to.'),
      aiCounterTicks: pair('The AI presses its counter-rush this many live ticks after the landing, from and to.'),
    },
    required: ['enabled', 'windowTicks', 'flipTicks', 'flipBh', 'arcBh', 'counterTicks', 'counterRush', 'flourishOverBh', 'aiTapTicks', 'aiCounterTicks'], additionalProperties: false };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: recoilFlip' + (check ? ' (checked)' : ''));
}
{
  const sp = path.join(root, 'tools/schemas/director-ai.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  let k = 0;
  const walk = o => {
    if (!o || typeof o !== 'object') return;
    if (o.properties && o.properties.anywhere && o.properties.grapple && o.properties.tapGap) {
      if (o.properties.recoil) throw new Error('director-ai schema: brawl.recoil exists already');
      o.properties.recoil = { type: 'object', description: 'The AI\'s recoil flips (interrupts.json recoilFlip).',
        properties: { flip: { type: 'number', minimum: 0, maximum: 1, description: 'The share of its knock-backs it flips out of.' },
          counter: { type: 'number', minimum: 0, maximum: 1, description: 'The share of its flips it follows with a counter-rush.' } },
        required: ['flip', 'counter'], additionalProperties: false };
      k++;
      return;
    }
    for (const v of Object.values(o)) walk(v);
  };
  walk(s);
  if (k !== 3) throw new Error('director-ai schema: expected 3 brawl blocks, found ' + k);
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-ai.schema.json: brawl.recoil x' + k + (check ? ' (checked)' : ''));
}
