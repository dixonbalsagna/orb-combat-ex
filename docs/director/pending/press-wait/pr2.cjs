// pr2.cjs: a player's press waits at most a beat after an exchange (Game Design's rulings-2026-10-22.md 7a): capTicks (6)
// after an exchange ends, setPieceCapTicks (12) after a set piece's end; kept and thrown at the cap, its press_ack "queued"
// due then. The AI keeps the director's cooldown. On top of press-tick (pr.cjs: the press block, the opening cooldown, the
// ack) and the mash run (mr.cjs: DirPress's slot follows DirMash's). Only a player's fighter is written, so the AI v AI
// golden doesn't move.
//   node pr2.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node pr2.cjs <checkout root> [--check]');
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
if (!check && !fs.existsSync(path.join(root, 'sim/director/mash.gd'))) throw new Error('the mash run (../mash-run/mr.cjs) first: DirPress\'s slot follows its slot');
for (const f of ['press.gd', 'press.gd.uid']) {
  const from = path.join(__dirname, 'files/sim/director', f);
  if (!fs.existsSync(from)) continue;
  const to = path.join(root, 'sim/director', f);
  if (fs.existsSync(to)) throw new Error('sim/director/' + f + ' exists already');
  if (!check) fs.copyFileSync(from, to);
  console.log('sim/director/' + f + (check ? ': new (checked)' : ': new'));
}
edit('sim/director/exchange.gd', rep => {
  rep('\tS.dirS.cool = DirBrawl.coolAfter(ex) if DirBrawl.isBrawl(ex) else cooldownAfter(ex)   # no pause after a brawl, except after a launch\n',
      '\tS.dirS.cool = DirBrawl.coolAfter(ex) if DirBrawl.isBrawl(ex) else cooldownAfter(ex)   # no pause after a brawl, except after a launch\n' +
      '\tDirPress.onEnd(S, ex)   # 7a: the cooldown holds a player at most a beat (the AI keeps all of it)\n');
  rep('\t\tS.dirS.cool = 0.5\n\t\tif A.ai == null:\n\t\t\tSimFx.banner(S, "LOCK LOST',
      '\t\tS.dirS.cool = 0.5\n\t\tDirPress.onCool(S)\n\t\tif A.ai == null:\n\t\t\tSimFx.banner(S, "LOCK LOST');
  rep('\t\t\tS.dirS.cool = SimMathx.jmax(S.dirS.cool, hold)\n',
      '\t\t\tS.dirS.cool = SimMathx.jmax(S.dirS.cool, hold)\n\t\t\tDirPress.onCool(S)   # (a live form step\'s hold holds a player too)\n');
  rep('\tif S.dirS.cool > 0.0 and opn == 0 and not fu and not (A.ai == null and S.dirS.exN == 0 and bool(pressCfg().get("skipOpenCool", false))):\n',
      '\tif opn == 0 and not fu and DirPress.held(S, A):   # the cooldown, as it holds him (DirPress: a player\'s cap, and the opening skip)\n');
  // The drain went back on any cooldown before a request reached _start, so neither the opening skip nor the cap could
  // act: it goes on when a queued request is free of the cooldown.
  rep('\tif S.dirS.cool > 0.0 and DirInterrupt.opening(S, S.fighters[0]) == 0 and DirInterrupt.opening(S, S.fighters[1]) == 0 and not DirBury.followUp(S, S.fighters[0], S.fighters[1]) and not DirBury.followUp(S, S.fighters[1], S.fighters[0]):\n\t\treturn\n',
      '\tif S.dirS.cool > 0.0 and DirInterrupt.opening(S, S.fighters[0]) == 0 and DirInterrupt.opening(S, S.fighters[1]) == 0 and not DirBury.followUp(S, S.fighters[0], S.fighters[1]) and not DirBury.followUp(S, S.fighters[1], S.fighters[0]) and not DirPress.anyFree(S):\n\t\treturn   # (a player\'s request free of the cooldown goes on: DirPress)\n');
  // The acknowledgement (Controls' tightened T1): every player's attack press that starts, or waits, is acknowledged on its
  // own tick. requestAttack becomes a wrapper: the request, then the ack.
  rep('static func requestAttack(S: SimState, A, kind: String) -> void:\n',
      '## An attack press (SimControl.control): the director\'s request, then a player\'s acknowledgement on its own tick\n' +
      '## (Controls\' T1: started, or queued with the tick it is due).\n' +
      'static func requestAttack(S: SimState, A, kind: String) -> void:\n' +
      '\tvar ex0 = S.dirS.ex\n' +
      '\tvar who0: int = DirBands.who(S)\n' +
      '\t_request(S, A, kind)\n' +
      '\t_ack(S, A, kind, ex0, who0)\n\n\n' +
      'static func _request(S: SimState, A, kind: String) -> void:\n');
  rep('\t_drain(S)\n\t_ackQueued(S, A, kind)   # a player\'s press that waits is acknowledged on its own tick (Controls\' T1)\n',
      '\t_drain(S)\n');
  rep('static func _ackQueued(S: SimState, A, kind: String) -> void:\n' +
      '\tif A.ai != null or not bool(pressCfg().get("ackQueued", false)):\n\t\treturn\n' +
      '\tvar q: Array = A.act.queue\n' +
      '\tif q.is_empty() or int(q[q.size() - 1][3]) != S.tick:\n\t\treturn   # it started, or it was not queued\n' +
      '\tvar e = DirBrawl._ev(S, A, "press_ack", "queued", DirBrawl._cell(kind))\n' +
      '\tvar wait: int = int(ceil(S.dirS.cool * DirData.TICKS_PER_SEC - 0.0001)) if (S.dirS.ex == null and S.dirS.cool > 0.0) else -1\n' +
      '\te.n = S.tick + wait if wait >= 0 else -1\n' +
      '\te.amount = float(wait)\n' +
      '\te.target = float(S.fighters.find(SimRoster.opp(S, A)))\n',
      '## A player\'s attack press, on its tick: press_ack "started" when it began an exchange or an approach (ex0 and who0: the\n' +
      '## exchange and the approach before it), "queued" when it waits (n the tick it is due when the wait is the cooldown, else\n' +
      '## -1; amount the ticks to it); nothing when the brawl, the zip or the chase acknowledged it already, or it was a blow on a\n' +
      '## brawl\'s line (its own events say so). The AI\'s presses are not acknowledged.\n' +
      'static func _ack(S: SimState, A, kind: String, ex0, who0: int) -> void:\n' +
      '\tif A.ai != null or not bool(pressCfg().get("ackQueued", false)):\n\t\treturn\n' +
      '\tvar slot: int = S.fighters.find(A)\n' +
      '\tfor e0 in S.out.fx:\n' +
      '\t\tif String(e0.type) == "cue" and String(e0.kind) == "press_ack" and int(e0.actor) == slot:\n\t\t\treturn\n' +
      '\tvar q: Array = A.act.queue\n' +
      '\tvar queued: bool = not q.is_empty() and int(q[q.size() - 1][3]) == S.tick\n' +
      '\tvar started: bool = (ex0 == null and S.dirS.ex != null and S.dirS.ex.A == A) or (who0 != slot and DirBands.who(S) == slot)\n' +
      '\tif not queued and not started:\n\t\treturn\n' +
      '\tvar e = DirBrawl._ev(S, A, "press_ack", "queued" if queued else "started", DirBrawl._cell(kind))\n' +
      '\te.target = float(S.fighters.find(SimRoster.opp(S, A)))\n' +
      '\tvar wait: int = 0 if started else (DirPress.waitTicks(S, A) if (S.dirS.ex == null and DirPress.held(S, A)) else -1)   # 7a: a player\'s capped wait\n' +
      '\te.n = S.tick + wait if wait >= 0 else -1\n' +
      '\te.amount = float(wait)\n');
});
edit('data/director/interrupts.json', rep => {
  rep('"skipOpenCool": true,\n    "ackQueued": true\n  },',
      '"skipOpenCool": true,\n    "ackQueued": true,\n    "capTicks": 6,\n    "setPieceCapTicks": 12,\n    "setPieceTags": ["CLASH"]\n  },');
  rep('amount the ticks to it.",\n    "skipOpenCool"',
      'amount the ticks to it. capTicks and setPieceCapTicks (Game Design\'s 7a): after an exchange ends the cooldown holds a player\'s request at most capTicks, after a set piece\'s end setPieceCapTicks (a signature\'s exchange, a finisher, a template tagged with one of setPieceTags, a throw); it is kept and thrown at the cap. The AI keeps the whole cooldown. capTicks -1: off.",\n    "skipOpenCool"');
});
{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  const p = s.properties.press;
  if (!p) throw new Error('director-interrupts schema: no press block (press-tick first)');
  if (p.properties.capTicks) throw new Error('director-interrupts schema: press.capTicks exists already');
  p.properties.capTicks = { type: 'integer', minimum: -1, description: 'After an exchange ends, the cooldown holds a player\'s request at most this many ticks (-1: off, the cooldown holds him as the AI).' };
  p.properties.setPieceCapTicks = { type: 'integer', minimum: 0, description: '... after a set piece\'s end (a signature\'s exchange, a finisher, a tagged template, a throw).' };
  p.properties.setPieceTags = { type: 'array', items: { type: 'string' }, description: 'A planned exchange whose tag holds one of these is a set piece.' };
  p.required = (p.required || []).concat(['capTicks', 'setPieceCapTicks', 'setPieceTags']);
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: press.capTicks, setPieceCapTicks, setPieceTags' + (check ? ' (checked)' : ''));
}
