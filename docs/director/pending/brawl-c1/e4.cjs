// e4.cjs <copy root>: C1's rows in sim/director/tools/brawl_probe.gd. Every edit must match exactly once.
const fs = require('fs');
const path = require('path');
const p = path.join(process.argv[2], 'sim/director/tools/brawl_probe.gd');
let t = fs.readFileSync(p, 'utf8');
const crlf = t.includes('\r\n');
if (crlf) t = t.replace(/\r\n/g, '\n');
function rep(a, b) {
  const n = t.split(a).length - 1;
  if (n !== 1) throw new Error('probe: expected 1 match, got ' + n + ' for: ' + a.slice(0, 80));
  t = t.replace(a, () => b);
}
const L = (...lines) => lines.join('\n') + '\n';

rep("##   [--gap=8] [--clock=real|live] [--rival=ai|dummy] [--me=player|ai] [--max=900] [--forms=1] [--mix=1]\n",
    "##   [--gap=8] [--clock=real|live] [--rival=ai|dummy] [--me=player|ai] [--max=900] [--forms=1] [--mix=1]\n" +
    "##   [--stick=none|toward|away] (slice C1: the stick the scripted presser holds inside a brawl)\n");
rep(L(
  "\t\tif a.begins_with(\"--mix=\"):"),
L(
  "\t\tif a.begins_with(\"--stick=\"):",
  "\t\t\tstick = a.substr(8)",
  "\t\tif a.begins_with(\"--mix=\"):"));
rep("\tvar brawlCls = load(\"res://sim/director/brawl.gd\") if ResourceLoader.exists(\"res://sim/director/brawl.gd\") else null\n",
L(
  "\tvar brawlCls = load(\"res://sim/director/brawl.gd\") if ResourceLoader.exists(\"res://sim/director/brawl.gd\") else null",
  "\t# Slice C1: the centre, the walk-out and the double hit.",
  "\tvar dbl := 0             # double hits",
  "\tvar dblPer: Array = []   # ... by match",
  "\tvar cenTicks := 0        # live ticks of an announced brawl",
  "\tvar cenMoved := 0        # ... on which its centre moved",
  "\tvar cenInside := 0       # ... on which the pair's middle was inside a building's box (it moves freely there)",
  "\tvar stepMax := 0.0       # the largest step of the pair's middle in a tick, in units, with neither on a rush",
  "\tvar overCap := 0         # ... and the ticks on which it was over 0.3 bh",
  "\tvar driftMax := 0.0      # the largest step the director gave the pair in a tick, in units (the cap is brawl.maxStepBh)",
  "\tvar drift: Array = []    # for each brawl, how far its centre travelled, in tenths of a body height",
  "\tvar tradeMax := 0        # the oldest level trade seen with no double hit on its way, in ticks",
  "\tvar stickTicks := [0, 0] # live brawl ticks on which each slot held a stick",
  "\tvar LEVEL_AT := [120, 150, 180, 210]",
  "\tvar levelAt := [0, 0, 0, 0]   # trades with no lead that reached each of those ages; one that reaches flurry.doubleTicks is a double hit"));
rep(L(
  "\t\tvar mute := 0          # ticks he doesn't tap after pressing his ender, so the heavy isn't replaced by a held light"),
L(
  "\t\tvar mute := 0          # ticks he doesn't tap after pressing his ender, so the heavy isn't replaced by a held light",
  "\t\tvar dblM := 0",
  "\t\tvar cenAge := 0",
  "\t\tvar cpx := 0.0",
  "\t\tvar cpy := 0.0",
  "\t\tvar driftNow := 0.0",
  "\t\tvar tradeAge := 0"));
rep(L(
  "\t\t\tit.dash = absf(dx) > 700.0"),
L(
  "\t\t\tit.dash = absf(dx) > 700.0",
  "\t\t\tif stick != \"none\" and brawlCls != null and S.dirS.ex != null and S.dirS.ex.tpl == \"brawl\":",
  "\t\t\t\tit.mx = signf(dx) if stick == \"toward\" else -signf(dx)"));
rep(L(
  "\t\t\t\tif e.kind == \"trade\":",
  "\t\t\t\t\ttrades += 1"),
L(
  "\t\t\t\tif e.kind == \"double_hit\":",
  "\t\t\t\t\tdbl += 1",
  "\t\t\t\t\tdblM += 1",
  "\t\t\t\tif e.kind == \"trade\":",
  "\t\t\t\t\ttrades += 1"));
rep(L(
  "\t\t\tif inB:",
  "\t\t\t\tbrawlLive += 1"),
L(
  "\t\t\tif inB:",
  "\t\t\t\tbrawlLive += 1",
  "\t\t\tvar cen: Dictionary = brawlCls.centre(S, S.dirS.ex) if (brawlCls != null and S.dirS.ex != null and brawlCls.has_method(\"centre\")) else {}",
  "\t\t\tif not cen.is_empty() and not brawlCls.quiet(S.dirS.ex):",
  "\t\t\t\tcenTicks += 1",
  "\t\t\t\tcenAge += 1",
  "\t\t\t\tif cenAge > 4 and me.rush == null and ai.rush == null:   # a rush is one fighter's own move (a step in, a crossing), not the pair's drift",
  "\t\t\t\t\tvar stp: float = sqrt(pow(SimWrap.sdx(cpx, float(cen.x)), 2.0) + pow(float(cen.y) - cpy, 2.0))",
  "\t\t\t\t\tstepMax = maxf(stepMax, stp)",
  "\t\t\t\t\tif stp > 22.6:",
  "\t\t\t\t\t\toverCap += 1   # the pair's middle moved more than 0.3 bh: a strike placed its attacker (the drift itself is capped)",
  "\t\t\t\t\tdriftNow += stp",
  "\t\t\t\t\tif stp > 0.05:",
  "\t\t\t\t\t\tcenMoved += 1",
  "\t\t\t\tdriftMax = maxf(driftMax, sqrt(pow(float(cen.vx), 2.0) + pow(float(cen.vy), 2.0)) / 60.0)",
  "\t\t\t\tcpx = float(cen.x)",
  "\t\t\t\tcpy = float(cen.y)",
  "\t\t\t\tif brawlCls._walled(S, cpx, cpy):",
  "\t\t\t\t\tcenInside += 1",
  "\t\t\t\tfor k in range(2):",
  "\t\t\t\t\tvar stk: PackedFloat64Array = brawlCls.stick(S.dirS.ex, S.fighters[k])   # a player's own stick; the AI's nudge",
  "\t\t\t\t\tif absf(stk[0]) + absf(stk[1]) > 0.3:",
  "\t\t\t\t\t\tstickTicks[k] += 1",
  "\t\t\t\tvar xa = S.dirS.ex.A",
  "\t\t\t\tif xa.act.dirI[brawlCls.TRADE_T0] > 0 and xa.act.dirI[brawlCls.TRADE_WIN] == 0 and xa.act.dirI[brawlCls.DBL_AT] == 0:",
  "\t\t\t\t\tvar age: int = S.tick - xa.act.dirI[brawlCls.TRADE_T0]",
  "\t\t\t\t\ttradeMax = maxi(tradeMax, age)",
  "\t\t\t\t\tfor li in range(LEVEL_AT.size()):",
  "\t\t\t\t\t\tif tradeAge < int(LEVEL_AT[li]) and age >= int(LEVEL_AT[li]):",
  "\t\t\t\t\t\t\tlevelAt[li] += 1   # a trade with no lead reached this age (from tradeMaxTicks on, no close is pending)",
  "\t\t\t\t\ttradeAge = age",
  "\t\t\t\telse:",
  "\t\t\t\t\ttradeAge = 0",
  "\t\t\telif cenAge > 0:",
  "\t\t\t\tdrift.append(int(round(driftNow / 7.5)))",
  "\t\t\t\tcenAge = 0",
  "\t\t\t\tdriftNow = 0.0"));
rep(L(
  "\t\tlive += lt",
  "\t\tsecs += S.T"),
L(
  "\t\tlive += lt",
  "\t\tsecs += S.T",
  "\t\tdblPer.append(dblM)"));
rep(L(
  "\tlens.sort()",
  "\tperBrawl.sort()"),
L(
  "\tlens.sort()",
  "\tperBrawl.sort()",
  "\tdrift.sort()",
  "\tdblPer.sort()",
  "\tvar withDbl := 0",
  "\tfor v in dblPer:",
  "\t\tif int(v) > 0:",
  "\t\t\twithDbl += 1"));
rep("\t\t\"pressesThrownIn10Share\": snappedf(float(thrown10) / float(maxi(1, taps)), 0.001), \"pressStates\": states}))",
    "\t\t\"pressesThrownIn10Share\": snappedf(float(thrown10) / float(maxi(1, taps)), 0.001), \"pressStates\": states,\n" +
    "\t\t\"stick\": stick, \"doubleHits\": dbl, \"doubleHitsPerMatch\": snappedf(float(dbl) / float(n), 0.01), \"matchesWithDoubleShare\": snappedf(float(withDbl) / float(n), 0.001), \"doubleHitsMaxInMatch\": (int(dblPer[dblPer.size() - 1]) if not dblPer.is_empty() else 0),\n" +
    "\t\t\"walkOuts\": int(ends.get(\"walk\", 0)), \"levelTradeMaxTicks\": tradeMax, \"levelTradesReaching\": {\"ticks\": LEVEL_AT, \"trades\": levelAt},\n" +
    "\t\t\"centre\": {\"ticks\": cenTicks, \"movedShare\": snappedf(float(cenMoved) / float(maxi(1, cenTicks)), 0.001), \"insideBuildingShare\": snappedf(float(cenInside) / float(maxi(1, cenTicks)), 0.001), \"driftStepMaxBh\": snappedf(driftMax / 75.0, 0.001), \"stepMaxBh\": snappedf(stepMax / 75.0, 0.001), \"ticksOverCap\": overCap,\n" +
    "\t\t\t\"driftMedianBh\": float(_q(drift, 0.5)) / 10.0, \"driftP90Bh\": float(_q(drift, 0.9)) / 10.0, \"stickShare\": [snappedf(float(stickTicks[0]) / float(maxi(1, cenTicks)), 0.001), snappedf(float(stickTicks[1]) / float(maxi(1, cenTicks)), 0.001)]}}))");

// the option's variable, beside the others
{
  const m = t.match(/^\tvar mix[^\n]*\n/m);
  if (!m) throw new Error('probe: the mix variable was not found');
  t = t.replace(m[0], () => m[0] + "\tvar stick := \"none\"\n");
}
fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
console.log('sim/director/tools/brawl_probe.gd: ok');
