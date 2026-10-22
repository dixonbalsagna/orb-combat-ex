// pr.cjs: a player's attack press shows its reaction on the press tick (Controls' T1, docs/controls/input-scheme.md; the
// EP's brief of 2026-10-22 after Performance's docs/perf/input-latency-2026-10-22.md). The 5 ticks were the match's opening
// cooldown (SimCore.newMatch sets the director's cool to 0.6 s): a light, heavy or signature pressed in a match's first
// 36 live ticks waited, silent, until it ran out. Behind data/director/interrupts.json press (on): only a player's
// presses (f.ai null), so the AI v AI golden doesn't move.
//  - skipOpenCool: a player's request is not held by the opening cooldown while no exchange has started this match (the
//    opening beat is the intro's). A cooldown after an exchange still holds it: that beat is the choreography's.
//  - ackQueued: a player's request still waiting after the drain, on its press tick, is acknowledged: the cue press_ack,
//    text "queued", source its cell (x, y, b), n the tick it is due to start when the wait is a cooldown (else -1),
//    amount the ticks to it. Animation shows the anticipation from it; the HUD marks the cell.
//   node pr.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node pr.cjs <checkout root> [--check]');
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
edit('sim/director/exchange.gd', rep => {
  rep('\tSimAct.push(A, KIND.find(kind), A.act.mode, entry, S.tick)\n\t_drain(S)\n',
      '\tSimAct.push(A, KIND.find(kind), A.act.mode, entry, S.tick)\n\t_drain(S)\n' +
      '\t_ackQueued(S, A, kind)   # a player\'s press that waits is acknowledged on its own tick (Controls\' T1)\n\n\n' +
      '## The press block (data/director/interrupts.json press): a player\'s attack press reacts on its own tick.\n' +
      'static func pressCfg() -> Dictionary:\n' +
      '\treturn DirInterrupt.data().get("press", {})\n\n\n' +
      '## A player\'s request still waiting after the drain, on its press tick: the cue press_ack "queued" (source its cell),\n' +
      '## n the tick it is due to start when the wait is the cooldown (else -1) and amount the ticks to it. Animation shows the\n' +
      '## anticipation from it, and the HUD marks the cell. The AI\'s presses are not acknowledged.\n' +
      'static func _ackQueued(S: SimState, A, kind: String) -> void:\n' +
      '\tif A.ai != null or not bool(pressCfg().get("ackQueued", false)):\n\t\treturn\n' +
      '\tvar q: Array = A.act.queue\n' +
      '\tif q.is_empty() or int(q[q.size() - 1][3]) != S.tick:\n\t\treturn   # it started, or it was not queued\n' +
      '\tvar e = DirBrawl._ev(S, A, "press_ack", "queued", DirBrawl._cell(kind))\n' +
      '\tvar wait: int = int(ceil(S.dirS.cool * DirData.TICKS_PER_SEC - 0.0001)) if (S.dirS.ex == null and S.dirS.cool > 0.0) else -1\n' +
      '\te.n = S.tick + wait if wait >= 0 else -1\n' +
      '\te.amount = float(wait)\n' +
      '\te.target = float(S.fighters.find(SimRoster.opp(S, A)))\n');
  rep('\tif S.dirS.cool > 0.0 and opn == 0 and not fu:\n\t\treturn WAIT\n',
      '\tif S.dirS.cool > 0.0 and opn == 0 and not fu and not (A.ai == null and S.dirS.exN == 0 and bool(pressCfg().get("skipOpenCool", false))):\n' +
      '\t\treturn WAIT   # (a player\'s press is not held by the match\'s opening cooldown: no exchange yet, the opening beat is the intro\'s)\n');
});
const NOTE = 'A player\'s attack press reacts on its own tick (Controls\' T1; the EP\'s brief of 2026-10-22 after Performance\'s input-latency-2026-10-22.md, where a light first reacted 5 ticks late: the opening cooldown). Only a player\'s presses (the AI\'s are as before). skipOpenCool: his request is not held by the match\'s opening cooldown (SimCore.newMatch\'s 0.6 s) while no exchange has started this match; a cooldown after an exchange still holds it. ackQueued: a request still waiting after the drain is acknowledged on its press tick, the cue press_ack, text queued, source its cell, n the tick it is due when the wait is a cooldown (else -1), amount the ticks to it.';
edit('data/director/interrupts.json', rep => {
  rep('\n  "grapple": {\n',
      '\n  "press": {\n    "_note": ' + JSON.stringify(NOTE) + ',\n    "skipOpenCool": true,\n    "ackQueued": true\n  },\n  "grapple": {\n');
});
{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  if (s.properties.press) throw new Error('director-interrupts schema: press exists already');
  s.properties.press = { type: 'object', description: 'A player\'s attack press reacts on its own tick (Controls\' T1).',
    properties: { _note: { type: 'string' },
      skipOpenCool: { type: 'boolean', description: 'A player\'s request is not held by the match\'s opening cooldown while no exchange has started.' },
      ackQueued: { type: 'boolean', description: 'A player\'s request still waiting after the drain is acknowledged on its press tick (press_ack, queued).' } },
    required: ['skipOpenCool', 'ackQueued'], additionalProperties: false };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: press' + (check ? ' (checked)' : ''));
}
