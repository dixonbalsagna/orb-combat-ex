// e2.cjs <brawl.gd> <frag_control.gd>: C1's edits inside the brawl's existing functions, and the new functions.
// Every edit must match exactly once. Run after e1.cjs, on HEAD's brawl.gd.
const fs = require('fs');
const p = process.argv[2];
let t = fs.readFileSync(p, 'utf8');
const crlf = t.includes('\r\n');
if (crlf) t = t.replace(/\r\n/g, '\n');
function rep(a, b) {
  const n = t.split(a).length - 1;
  if (n !== 1) throw new Error('expected 1 match, got ' + n + ' for: ' + a.slice(0, 80));
  t = t.replace(a, () => b);
}
// Replace whole lines from the one holding `from` through the one holding `to`.
function span(from, to, b) {
  const i = t.indexOf(from);
  if (i < 0 || t.indexOf(from, i + 1) >= 0) throw new Error('span start not unique: ' + from.slice(0, 80));
  const j = t.indexOf(to, i);
  if (j < 0) throw new Error('span end not found: ' + to.slice(0, 80));
  const s = t.lastIndexOf('\n', i) + 1;
  const e = t.indexOf('\n', j) + 1;
  t = t.slice(0, s) + b + t.slice(e);
}
const L = (...lines) => lines.join('\n') + '\n';

// ---- begin(): the brawl keeps the speed it began with
rep(L(
  "\t# Both are held from now: the speed either had as it began is gone (a rival locked while flying would drift out of reach).",
  "\tfor f in [ex.A, ex.D]:",
  "\t\tf.vx = 0.0",
  "\t\tf.vy = 0.0",
  "\tvar e = _ev(S, ex.A, \"brawl_start\")"),
L(
  "\t# The brawl keeps the speed it began with (brawl-second-pass.md section 1): carryShare of the two velocities added,",
  "\t# which is half the closing speed when one of them stood, carries on as the centre's drift and fades over carryTicks.",
  "\t# An attacker who came in by a lunge was carried by the director, so his speed is his own flight speed along his line.",
  "\tvar cx: float = 0.0",
  "\tvar cy: float = 0.0",
  "\tfor f in [ex.A, ex.D]:",
  "\t\tvar fx: float = f.vx",
  "\t\tvar fy: float = f.vy",
  "\t\tif f == ex.A and (DirExchange.engaging or f.rush != null):",
  "\t\t\tvar lx: float = SimWrap.sdx(f.x, ex.D.x)",
  "\t\t\tvar ly: float = ex.D.y - f.y",
  "\t\t\tvar ll: float = SimDetMath.hypot(lx, ly)",
  "\t\t\tvar sp: float = _flySpeed(S, f)",
  "\t\t\tfx = lx / ll * sp if ll > 0.0 else 0.0",
  "\t\t\tfy = ly / ll * sp if ll > 0.0 else 0.0",
  "\t\tcx += fx",
  "\t\tcy += fy",
  "\t_s(ex.A, CARRY_X, int(round(cx * float(c.carryShare) * 16.0)))",
  "\t_s(ex.A, CARRY_Y, int(round(cy * float(c.carryShare) * 16.0)))",
  "\t_s(ex.A, CARRY_N, int(c.carryTicks))",
  "\t# Both are held from now, and the pair moves as its centre does (_move).",
  "\tfor f in [ex.A, ex.D]:",
  "\t\tf.vx = 0.0",
  "\t\tf.vy = 0.0",
  "\tvar e = _ev(S, ex.A, \"brawl_start\")"));

// ---- blowAt(): the double hit's blows stop the clock as a heavy does
rep(L(
  "\tif bool(extra.get(\"sure\", false)):",
  "\t\to2[\"ignoreStance\"] = true",
  "\t\to2[\"noParry\"] = true",
  "\t\to2[\"weighed\"] = true",
  "\tvar args := {\"a\": role, \"d\": \"D\" if role == \"A\" else \"A\", \"dmg\": dmg, \"o\": o2, \"brawl\": true, \"bk\": kind,"),
L(
  "\tif bool(extra.get(\"sure\", false)):",
  "\t\to2[\"ignoreStance\"] = true",
  "\t\to2[\"noParry\"] = true",
  "\t\to2[\"weighed\"] = true",
  "\tif bool(extra.get(\"double\", false)):",
  "\t\to2[\"stop\"] = float(int(c.hitstop.heavy)) / DirData.TICKS_PER_SEC   # the double hit's two blows hold the clock as a heavy does",
  "\tvar args := {\"a\": role, \"d\": \"D\" if role == \"A\" else \"A\", \"dmg\": dmg, \"o\": o2, \"brawl\": true, \"bk\": kind,"));

// ---- over(): the endings, and the drift ends with the brawl
rep("## The brawl is over, and why: knockback, launch, apart, idle, left, burst, perfect_block, reversal, break, finisher,\n## signature.",
    "## The brawl is over, and why: knockback, launch, apart, idle, left, burst, perfect_block, reversal, break, finisher,\n## signature, walk (both held away), double (the double hit).");
rep(L(
  "\tex.branch = why",
  "\tif said:",
  "\t\tvar e = _ev(S, ex.A, \"brawl_end\", why)"),
L(
  "\tex.branch = why",
  "\tif why != \"walk\":",
  "\t\tfor f in [ex.A, ex.D]:",
  "\t\t\tif f.state == \"locked\":",
  "\t\t\t\tf.vx = 0.0   # the pair's drift ends with the brawl; two who walk out keep theirs",
  "\t\t\t\tf.vy = 0.0",
  "\tif said:",
  "\t\tvar e = _ev(S, ex.A, \"brawl_end\", why)"));

// ---- end(): the double hit's two slides are kept
rep("\tif slide != null and slide.tgt == null and (why == \"knockback\" or why == \"launch\"):",
    "\tif slide != null and slide.tgt == null and (why == \"knockback\" or why == \"launch\" or why == \"double\"):");

// ---- takes(): a press while the double hit is on its way; the cells
rep(L(
  "\tif quiet(ex) and f == ex.A:",
  "\t\tvar za = _ev(S, f, \"press_ack\", \"zip\")   # a zipper in reach: his one blow is on its way, and a press is spent"),
L(
  "\tif _g(ex.A, DBL_AT) > 0:",
  "\t\tvar da = _ev(S, f, \"press_ack\", \"double\", _cell(kind))   # the double hit is on its way: a press is spent",
  "\t\tda.n = S.tick",
  "\t\treturn true",
  "\tif quiet(ex) and f == ex.A:",
  "\t\tvar za = _ev(S, f, \"press_ack\", \"zip\", _cell(kind))   # a zipper in reach: his one blow is on its way, and a press is spent"));
rep("\t\t\tvar a = _ev(S, f, \"press_ack\", \"refused\")", "\t\t\tvar a = _ev(S, f, \"press_ack\", \"refused\", \"b\")");
rep("\t\tvar en = _ev(S, f, \"press_ack\", \"energy\")", "\t\tvar en = _ev(S, f, \"press_ack\", \"energy\", _cell(kind))");

// ---- press(): the held ack says which button
rep("\t\tvar a = _ev(S, f, \"press_ack\", \"held\")", "\t\tvar a = _ev(S, f, \"press_ack\", \"held\", \"y\" if weight == SimAct.HEAVY else \"x\")");

// ---- tick(): the lapsed ack's cell
rep("\t\t\t\tvar a = _ev(S, f, \"press_ack\", \"lapsed\")", "\t\t\t\tvar a = _ev(S, f, \"press_ack\", \"lapsed\", \"y\" if hp - 1 == SimAct.HEAVY else \"x\")");

// ---- tick(): the double hit's safety, the walk-out, the centre's movement
rep(L(
  "\t_inTick = false",
  "\t_tradeTick(S, ex)",
  "\t# The magnet: they are held at striking distance, at one height. Past breakBh it lets go."),
L(
  "\t_inTick = false",
  "\t_tradeTick(S, ex)",
  "\tif S.dirS.ex != ex or ex.branch != \"\":",
  "\t\treturn",
  "\tif _g(ex.A, DBL_AT) > 0 and now > _g(ex.A, DBL_AT) + 2:",
  "\t\t_thrownApart(S, ex)   # one of the two blows was lost on its way: they are thrown apart all the same",
  "\t\treturn",
  "\t# The walk-out: both hold away for partTicks full ticks running, and the brawl lets go, free. It ends partTicks",
  "\t# after the tick the later stick was first read, never sooner.",
  "\tif not quiet(ex) and _g(ex.A, DBL_AT) == 0 and ex.t > SimConst.DT * 1.5 and _parting(S, ex):",
  "\t\t_s(ex.A, PART_N, _g(ex.A, PART_N) + 1)",
  "\t\tif _g(ex.A, PART_N) > int(c.partTicks):",
  "\t\t\tend(S, ex, \"walk\")",
  "\t\t\treturn",
  "\telse:",
  "\t\t_s(ex.A, PART_N, 0)",
  "\t_move(S, ex)",
  "\t# The attraction: the pair's gap is held at striking distance, at one height. Past breakBh it lets go."));
rep("## Before the exchange's beats (DirExchange.dirUpdate): what ends the brawl, held heavies, held presses, the magnet.",
    "## Before the exchange's beats (DirExchange.dirUpdate): what ends the brawl, held heavies, held presses, the trade,\n## the walk-out, the centre's movement and the attraction.");

// ---- _tradeTick(): no draw; a level trade goes on to the double hit
rep(L(
  "## the first live tick at or after it (a hit-stop holds the sim, and so the break): a lead of more than levelWithin",
  "## takes the close, and runs within it are a level trade, settled by a seeded draw in which the fighter who made the",
  "## last close in this brawl has `momentum`; when nobody has closed yet the odds are even (melee-press-feel.md section",
  "## 9d, ruling 3). His next landed blow is the close."),
L(
  "## the first live tick at or after it (a hit-stop holds the sim, and so the break): a lead of more than levelWithin",
  "## takes the close, at the limit or on the tick one appears after it, and his next landed blow is the close. Runs",
  "## within levelWithin are a level trade, and it goes on. Still level at doubleTicks, it is the double hit",
  "## (brawl-second-pass.md section 7). The seeded draw and its momentum are withdrawn."));
span("\tif _g(ex.A, TRADE_WIN) != 0 or S.tick - _g(ex.A, TRADE_T0) < int(fl.tradeMaxTicks):",
     "\tSimEvents.feed(S, \"THE TRADE BREAKS\"",
L(
  "\tvar t: int = S.tick - _g(ex.A, TRADE_T0)",
  "\tif _g(ex.A, TRADE_WIN) != 0 or _g(ex.A, DBL_AT) != 0 or t < int(fl.tradeMaxTicks):",
  "\t\treturn",
  "\tif absi(_g(ex.A, RUN) - _g(ex.D, RUN)) <= int(fl.levelWithin):",
  "\t\tif t >= int(fl.doubleTicks) and not quiet(ex) and ex.A.stunTicks <= 0 and ex.D.stunTicks <= 0 and ex.A.rush == null and ex.D.rush == null:",
  "\t\t\t_double(S, ex)",
  "\t\treturn",
  "\tvar w: int = 1 if _g(ex.A, RUN) > _g(ex.D, RUN) else 2",
  "\t_s(ex.A, TRADE_WIN, w)",
  "\tvar who = ex.A if w == 1 else ex.D",
  "\tvar e = _ev(S, who, \"trade_break\", \"lead\")",
  "\te.target = float(S.fighters.find(ex.D if w == 1 else ex.A))",
  "\te.n = t",
  "\t# For QA: the limit; and the two runs at the break, his and the rival's. A break is always for a lead now.",
  "\te.amount = float(int(fl.tradeMaxTicks))",
  "\te.x = float(_g(who, RUN))",
  "\te.y = float(_g(ex.D if w == 1 else ex.A, RUN))",
  "\tSimEvents.feed(S, \"THE TRADE BREAKS\", who.name + \"'s next blow that lands closes it, after \" + str(t) + \" ticks\")"));

// ---- contact(): a double hit's blow lands whatever happened to him on the way; its own outcome; no last closer
rep("\tif ex.branch != \"\" or f.stunTicks > 0 or f.state != \"locked\" or o.state != \"locked\":\n\t\tif kind == HEAVY:",
    "\tif ex.branch != \"\" or (f.stunTicks > 0 and not bool(a.get(\"double\", false))) or f.state != \"locked\" or o.state != \"locked\":\n\t\tif kind == HEAVY:");
rep(L(
  "\tif S.dirS.ex != ex or ex.cancel or ex.branch != \"\" or S.game.ko != null:",
  "\t\treturn   # a perfect block took the exchange over"),
L(
  "\tif S.dirS.ex != ex or ex.cancel or ex.branch != \"\" or S.game.ko != null:",
  "\t\treturn   # a perfect block took the exchange over",
  "\tif bool(a.get(\"double\", false)):",
  "\t\t# One of the double hit's two blows: no run, no reel, no close. When both have landed they are thrown apart.",
  "\t\t_s(ex.A, DBL_N, _g(ex.A, DBL_N) + 1)",
  "\t\tif _setPiece(ex):",
  "\t\t\tover(S, ex, \"break\")",
  "\t\telif _g(ex.A, DBL_N) >= 2:",
  "\t\t\t_thrownApart(S, ex)",
  "\t\treturn"));
rep("\t_s(ex.A, LAST_CLOSER, 1 if f == ex.A else 2)   # the momentum of a level trade is his\n", "");

// ---- aiInput(): nothing counts while the double hit is on its way; its stick; its nudge at each choice
rep(L(
  "\t\treturn   # a zipper in reach: his one blow is on its way",
  "\tif _now(S) < _g(f, AI_HOLD):",
  "\t\ti.heavyHeld = true"),
L(
  "\t\treturn   # a zipper in reach: his one blow is on its way",
  "\tif _g(ex.A, DBL_AT) > 0:",
  "\t\treturn   # the double hit is on its way: nothing it presses counts",
  "\tif _now(S) < _g(f, AI_HOLD):",
  "\t\ti.heavyHeld = true",
  "\tif _aiPart(S, ex, f, o, bl):",
  "\t\treturn   # it holds away with the rival, to walk out"));
rep(L(
  "\t\t_s(f, AI_GUARD, S.tick + int(bl.get(\"guardMaxTicks\", 28)))",
  "\t\t_s(f, AI_LEFT, -1)",
  "\t\t_s(f, AI_CLOSE, 0)"),
L(
  "\t\t_s(f, AI_GUARD, S.tick + int(bl.get(\"guardMaxTicks\", 28)))",
  "\t\t_s(f, AI_LEFT, -1)",
  "\t\t_s(f, AI_CLOSE, 0)",
  "\t\t_aiNudge(S, ex, f, false)"));
rep(L(
  "\t\t_s(f, AI_LEFT, -1)   # after a guard it must attack",
  "\t\ti.guard = true",
  "\t\tf.ai.st = 1.0",
  "\t\treturn"),
L(
  "\t\t_s(f, AI_LEFT, -1)   # after a guard it must attack",
  "\t\ti.guard = true",
  "\t\tf.ai.st = 1.0",
  "\t\t_aiNudge(S, ex, f, false)",
  "\t\treturn"));
rep(L(
  "\t_s(f, AI_CLOSE, 1)",
  "\t_s(f, AI_NEXT, S.tick + gap)",
  "\ti.light = true"),
L(
  "\t_s(f, AI_CLOSE, 1)",
  "\t_s(f, AI_NEXT, S.tick + gap)",
  "\ti.light = true",
  "\t_aiNudge(S, ex, f, true)"));

// ---- the new functions, before the once-a-tick section
let frag = fs.readFileSync(process.argv[3], 'utf8').replace(/\r\n/g, '\n');
frag = frag.split('\n').map(l => {
  const m = l.match(/^( +)/);
  if (!m) return l;
  const n = m[1].length;
  if (n % 4 !== 0) throw new Error('fragment indent not a multiple of 4: ' + l);
  return '\t'.repeat(n / 4) + l.slice(n);
}).join('\n');
rep("# ---------------------------------------------------------------- once a live tick\n",
    frag + "# ---------------------------------------------------------------- once a live tick\n");

// ---- tick(): the attraction's height when the higher one stands on the ground
rep(L(
  "		if absf(dy) > 1.0:",
  "			var py: float = minf(absf(dy) * 0.5, pull)",
  "			ex.A.y = maxf(WorldTerrain.groundY(S, ex.A.x), ex.A.y + SimMathx.jsign(dy) * py)",
  "			ex.D.y = maxf(WorldTerrain.groundY(S, ex.D.x), ex.D.y - SimMathx.jsign(dy) * py)"),
L(
  "		var hi = ex.D if dy > 0.0 else ex.A",
  "		if absf(dy) > 1.0 and hi.y <= WorldTerrain.groundY(S, hi.x) + 0.5:",
  "			# The higher one stands on the ground and can't come down (a slope the pair is on): the other comes up to him.",
  "			var lo = ex.A if dy > 0.0 else ex.D",
  "			lo.y = minf(hi.y, lo.y + float(c.maxStepBh) * DirInterrupt.BH)",
  "		elif absf(dy) > 1.0:",
  "			var py: float = minf(absf(dy) * 0.5, pull)",
  "			ex.A.y = maxf(WorldTerrain.groundY(S, ex.A.x), ex.A.y + SimMathx.jsign(dy) * py)",
  "			ex.D.y = maxf(WorldTerrain.groundY(S, ex.D.x), ex.D.y - SimMathx.jsign(dy) * py)"));

if (t.includes('LAST_CLOSER') || t.includes('fl.momentum')) throw new Error('a withdrawn name is still in the file');
fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
console.log('e2 ok');
