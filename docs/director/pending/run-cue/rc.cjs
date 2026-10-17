// rc.cjs <checkout root> [--check]: UI's run on the brawl's blow cue (docs/ui/brawl-teaching.md section 3; the twelfth
// round's launch marks: the run's pips, the full gauge and the first-time hint wait on it). Needs Simulation's FxEvent
// fields run and run_to (on main since 8cac4e1b); neither is hashed, so the golden doesn't move.
//   run:    the striker's run on the target as the blow is thrown, in whole points, 0 to runToClose; runToClose when his
//           next light that lands is the close (after a trade he won too)
//   run_to: the run at which his next light closes (runToClose, 4): UI's gauge is full when run reaches it
// On every brawl blow cue: a press's blow, a blow by rule (a zip's), the reversal's medium, and a wound blow's release
// (which also gains its target).
// Every anchor is exact text; the script stops at the first missing. --check reads every anchor and writes nothing.
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node rc.cjs <checkout root> [--check]');
const check = opts.includes('--check');
const st = fs.readFileSync(path.join(root, 'sim/core/state.gd'), 'utf8');
if (!/\n\tvar run_to: int = 0/.test(st.replace(/\r\n/g, '\n'))) throw new Error('FxEvent has no run_to: Simulation\'s slice first (8cac4e1b)');
function edit(rel, fn) {
  const p = path.join(root, rel);
  let t = fs.readFileSync(p, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  const rep = (a, b) => {
    const n = t.split(a).length - 1;
    if (n !== 1) throw new Error(rel + ': expected 1 match, got ' + n + ' for: ' + a.slice(0, 80));
    t = t.replace(a, () => b);
  };
  fn(rep);
  if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + (check ? ': anchors ok' : ': ok'));
}
edit('sim/director/brawl.gd', rep => {
  rep('\tvar e = _ev(S, f, "blow", STRENGTH[kind], "zip" if bool(extra.get("zip", false)) else "")   # source zip: a zipper\'s blow, announced as he arrives\n\te.target = float(S.fighters.find(o))\n',
      '\tvar e = _ev(S, f, "blow", STRENGTH[kind], "zip" if bool(extra.get("zip", false)) else "")   # source zip: a zipper\'s blow, announced as he arrives\n\te.target = float(S.fighters.find(o))\n\t_runCue(S, f, e)\n');
  rep('\tvar e = _ev(S, f, "blow", STRENGTH[MEDIUM])\n\te.target = float(S.fighters.find(att))\n',
      '\tvar e = _ev(S, f, "blow", STRENGTH[MEDIUM])\n\te.target = float(S.fighters.find(att))\n\t_runCue(S, f, e)\n');
  rep('\tvar e = _ev(S, f, "blow", called, "lunge" if arrived else "")   # source lunge: thrown on the tick he arrived by a lunge\n\te.target = float(S.fighters.find(o))\n',
      '\tvar e = _ev(S, f, "blow", called, "lunge" if arrived else "")   # source lunge: thrown on the tick he arrived by a lunge\n\te.target = float(S.fighters.find(o))\n\t_runCue(S, f, e)\n');
  rep('\t\tvar e = _ev(S, f, "blow", "release")\n',
      '\t\tvar e = _ev(S, f, "blow", "release")\n\t\te.target = float(S.fighters.find(o))\n\t\t_runCue(S, f, e)\n');
  rep('## True when f\'s next light or flurry blow that lands is the close:',
      '## UI\'s run on a blow cue of f\'s (docs/ui/brawl-teaching.md section 3): his run on the target as the blow is thrown, in\n' +
      '## whole points (runToClose when his next light that lands is the close, after a trade he won too), and run_to, the\n' +
      '## run at which it closes. Neither is hashed.\n' +
      'static func _runCue(S: SimState, f, e) -> void:\n' +
      '\tvar ex = S.dirS.ex\n' +
      '\tif not isBrawl(ex) or (f != ex.A and f != ex.D):\n' +
      '\t\treturn\n' +
      '\tvar to: int = int(cfg().flurry.runToClose)\n' +
      '\te.run = to if _closes(S, ex, f) else clampi(_g(f, RUN) / RUN_U, 0, to)\n' +
      '\te.run_to = to\n\n\n' +
      '## True when f\'s next light or flurry blow that lands is the close:');
});
