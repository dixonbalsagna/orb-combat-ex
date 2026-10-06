// e3.cjs <copy root> [nudgeShare e,m,h] [walkOut e,m,h]: C1's edits outside brawl.gd: interrupt.gd, zip.gd, the data.
// Every edit must match exactly once.
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const NS = (process.argv[3] || '0.35,0.5,0.65').split(',');
const WO = (process.argv[4] || '0.1,0.2,0.3').split(',');
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
  fn(rep, () => t, v => { t = v; });
  fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + ': ok');
}
const L = (...lines) => lines.join('\n') + '\n';

edit('sim/director/interrupt.gd', rep => {
  // nothing either fighter does counts while a double hit is on its way
  rep("\tif ex == null or (f != ex.D and not (DirBrawl.isBrawl(ex) and f == ex.A)) or not DirData.allows(ex, \"reversal\") or DirBury.diving(S, f):",
      "\tif ex == null or DirBrawl.doubling(ex) or (f != ex.D and not (DirBrawl.isBrawl(ex) and f == ex.A)) or not DirData.allows(ex, \"reversal\") or DirBury.diving(S, f):");
  rep("\treturn ex == null or (ex.kind != \"sig\" and not DirExchange.finisherPlanned(ex) and not DirBury.diving(S, f))",
      "\treturn ex == null or (ex.kind != \"sig\" and not DirExchange.finisherPlanned(ex) and not DirBury.diving(S, f) and not DirBrawl.doubling(ex))");
  // no press is silent: a cell with no move says so
  rep(L(
    "\t\t\tDirBlast.context(S, f)   # outside an exchange: a mine with the energy family held, the context deflect on a held guard",
    "\tif ex != null:",
    "\t\t_aiBlocks(S, ex)"),
  L(
    "\t\t\tDirBlast.context(S, f)   # outside an exchange: a mine with the energy family held, the context deflect on a held guard",
    "\t# No press is silent (the HUD marks the cell): a cell with no move yet says so. RT with X, Y or A reaches the intent",
    "\t# as `special`, which nothing reads. A with no guard held, outside the energy family, has no reading either.",
    "\tfor f in order:",
    "\t\tif not _human(f):",
    "\t\t\tcontinue",
    "\t\tvar cell: String = \"\"",
    "\t\tif f.input.special >= 1 and f.input.special <= 3:",
    "\t\t\tcell = EMPTY_CELLS[f.input.special - 1]",
    "\t\telif f.input.context and not f.input.guard and f.act.mode != 1:",
    "\t\t\tcell = \"a\"",
    "\t\tif cell != \"\":",
    "\t\t\tSimFx.cue(S, f, \"press_ack\", \"empty\", cell)",
    "\t\t\tS.out.fx[S.out.fx.size() - 1].n = S.tick",
    "\tif ex != null:",
    "\t\t_aiBlocks(S, ex)"));
  rep("static func _human(f) -> bool:",
      "const EMPTY_CELLS: Array = [\"x\", \"y\", \"a\"]   # the cells of `special` 1 to 3: RT with X, Y, A\n\n\nstatic func _human(f) -> bool:");
});

edit('sim/director/zip.gd', rep => {
  // the zip's press acks say which button (the HUD marks the cell)
  rep("static func _cue(S: SimState, f, name: String, text: String = \"\"):\n\tSimFx.cue(S, f, name, text, \"\")\n",
      "static func _cue(S: SimState, f, name: String, text: String = \"\", source: String = \"\"):\n\tSimFx.cue(S, f, name, text, source)\n");
  for (const k of ['zip', 'answer', 'zip_refused', 'zip_no_ki'])
    rep("\t\t_cue(S, A, \"press_ack\", \"" + k + "\").n = S.tick", "\t\t_cue(S, A, \"press_ack\", \"" + k + "\", DirBrawl._cell(kind)).n = S.tick");
  // a hole from Z1 (QA's hard test: no brawl is announced during a zip unless he is caught or countered): when the
  // rival ended the ticks in reach under the zipper (a dodge away), a press of his on the next tick started a brawl
  // before the zip could leave
  rep(L(
    "## The fighter whose zip is aimed at d and has not arrived yet, or null."),
  L(
    "## True from the tick the rival ended his ticks in reach under him (a dodge away, a burst) until the zip's next tick,",
    "## when he leaves by his exit: no strike reaches him in between, as none does on his way out (DirExchange._start).",
    "static func leaving(S: SimState, f) -> bool:",
    "\treturn _g(f, PH) == 3 and _g(f, STATE) != 2 and not _mine(S, f)",
    "",
    "",
    "## The fighter whose zip is aimed at d and has not arrived yet, or null."));
});

edit('sim/director/exchange.gd', rep => {
  rep("\tif D.state == \"launched\" or D.state == \"locked\" or DirZip.untouchable(D):\n\t\treturn WAIT   # (no strike reaches a zipper on his way out)",
      "\tif D.state == \"launched\" or D.state == \"locked\" or DirZip.untouchable(D) or DirZip.leaving(S, D):\n\t\treturn WAIT   # (no strike reaches a zipper on his way out, or about to leave)");
  rep(L("\t\t\t\tDirBrawl.contact(S, ex, b)   # a brawl's blow: it lands, and its line, its string and its close follow"),
      L("\t\t\t\tDirBrawl.contact(S, ex, b)   # a brawl's blow: it lands, and its line, its string and its close follow",
        "\t\t\t\tDirBrawl.carryOn(ex)   # the strike placed its attacker and stopped him: the pair's drift carries on"));
});

edit('data/director/interrupts.json', rep => {
  rep(L(
    "    \"breakBh\": 4.5,",
    "    \"pullBhPerSec\": 0.5,"),
  L(
    "    \"breakBh\": 4.5,",
    "    \"pullBhPerSec\": 0.5,",
    "    \"nudgeMul\": 0.4,",
    "    \"nudgeRampTicks\": 8,",
    "    \"nudge\": {",
    "      \"guard\": 0.6,",
    "      \"clearBh\": 0.5",
    "    },",
    "    \"maxStepBh\": 0.3,",
    "    \"carryShare\": 0.5,",
    "    \"carryTicks\": 20,",
    "    \"partTicks\": 12,",
    "    \"partDeg\": 45,",
    "    \"double\": {",
    "      \"windupTicks\": 8,",
    "      \"throwBh\": 6,",
    "      \"throwTicks\": 24",
    "    },"));
  rep(L(
    "      \"levelWithin\": 1,",
    "      \"momentum\": 0.9,"),
  L(
    "      \"levelWithin\": 1,",
    "      \"doubleTicks\": 240,"));
  // the block's note: the draw is gone, and the control slice's keys
  rep("a lead of more than levelWithin takes it, and runs within levelWithin are a level trade settled by a seeded draw in which the fighter who made the last close in this brawl has `momentum` (even odds when nobody has closed yet).",
      "a lead of more than levelWithin takes it, at the limit or on the tick one appears after it; runs within levelWithin are a level trade, which goes on, and one still level at doubleTicks is the double hit.");
  rep("on the brink both count launch.json setup.weight.riposte.\"",
      "on the brink both count launch.json setup.weight.riposte. Control (slice C1; docs/design/brawl-second-pass.md sections 1 and 7): each stick moves the pair's centre at nudgeMul of his free-flight speed (times nudge.guard while he guards), through Controls' ramp (data/input/timing.json aim.nudgeStart and aim.nudgeTicks); the centre's speed changes by at most a full nudge over nudgeRampTicks; carryShare of the two velocities added as they meet carries on and fades over carryTicks; the pair never moves more than maxStepBh in a tick; a step may not bring its middle within nudge.clearBh of a standing building's box. Both sticks held within partDeg of straight away for partTicks end the brawl, free. The double hit: each lands one blow worth skillMul brawl lights, double.windupTicks after the trade reaches doubleTicks level, and both are thrown double.throwBh from the centre over double.throwTicks.\"");
});

edit('data/director/ai.json', (rep, get, set) => {
  let t = get();
  let k = 0;
  t = t.replace(/("brawl": \{"tapGap": [^\n]*?"heavyAfterClose": [0-9.]+)\}/g, (m, a) => {
    const s = a + ', "nudgeShare": ' + NS[k] + ', "walkOut": ' + WO[k] + '}';
    k++;
    return s;
  });
  if (k !== 3) throw new Error('ai.json: expected 3 brawl blocks, got ' + k);
  set(t);
});
