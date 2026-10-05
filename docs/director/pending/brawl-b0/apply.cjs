// Brawl slice B0, the groundwork (docs/director/brawl-plan.md section 4; docs/design/melee-press-feel.md section 2b).
// node apply.cjs <repo root>. Idempotent. brawl_probe.gd beside this script becomes sim/director/tools/brawl_probe.gd.
//  1. The mid-band lunge winds up before it moves: bands.lunge.windupTicks (6 light, 10 heavy), with the cue
//     lunge_light or lunge_heavy at its start. The rush event carries the end of the whole approach.
//  2. The finisher struggle's stray press costs 0.10 (Combat's finishers.json, that value by the EP's grant).
//  3. Every strike and chainStrike beat carries style, grade, k, n, closing, charge, hand and ender; a chainStrike
//     carries a and d as a strike does.
//  4. The cooldown after an exchange and the AI's stance weights and distances are data, values unchanged.
//  5. Two blur patterns of the live recipes take Combat's fixed rows (Legal's sequence rule; the EP's grant for those two rows).
const fs = require("fs"), path = require("path");
const root = process.argv[2];
if (!root) throw new Error("usage: node apply.cjs <repo root>");
const L = (n, s) => "\t".repeat(n) + s + "\n";

function edit(rel, pairs) {
  const f = path.join(root, rel);
  let s = fs.readFileSync(f, "utf8");
  const crlf = s.includes("\r\n");
  if (crlf) s = s.split("\r\n").join("\n");
  let n = 0;
  for (const [a, b] of pairs) {
    if (s.includes(b)) continue;   // already applied (so a replacement must not be text the file already has)
    if (!s.includes(a)) throw new Error(rel + ": not found: " + a.slice(0, 80));
    if (s.split(a).length !== 2) throw new Error(rel + ": not unique: " + a.slice(0, 80));
    s = s.replace(a, () => b);
    n++;
  }
  if (crlf) s = s.split("\n").join("\r\n");
  fs.writeFileSync(f, s);
  console.log(rel + ": " + n + " edits");
}

fs.copyFileSync(path.join(__dirname, "brawl_probe.gd"), path.join(root, "sim/director/tools/brawl_probe.gd"));
console.log("sim/director/tools/brawl_probe.gd: written");

// ---------------------------------------------------------------- 1. the lunge's wind-up
edit("sim/director/interrupt.gd", [
  ["const N: int = 60\n",
   "const APPR_WIND: int = 60  # the ticks of wind-up his lunge still holds before it moves (bands.lunge.windupTicks)\n" +
   "const N: int = 61\n"],
]);
edit("sim/director/bands.gd", [
  [L(1, "var n: int = clampi(int(ceil(maxf(0.0, d - eng) / float(m.speed) * DirData.TICKS_PER_SEC)), int(m.minTicks), int(m.maxTicks))") +
   L(1, "A.state = \"free\"") +
   L(1, "A.hideT = 0.0") +
   L(1, "A.face = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(A.x, D.x)), A.face)") +
   L(1, "var r := SimState.Rush.new()") +
   L(1, "r.tgt = D") +
   L(1, "r.off = _endOff(S, D, SimMathx.jsign(DirMelee.sideOff(A, D, eng, \"own\")))") +
   L(1, "r.end = S.T + float(n) * SimConst.DT") +
   L(1, "A.rush = r") +
   L(1, "DirInterrupt.si(A, DirInterrupt.TAUNT_AGE, 0)") +
   L(1, "DirInterrupt.si(A, DirInterrupt.APPR_LEFT, n)"),
   L(1, "var n: int = clampi(int(ceil(maxf(0.0, d - eng) / float(m.speed) * DirData.TICKS_PER_SEC)), int(m.minTicks), int(m.maxTicks))") +
   L(1, "# The mid-band lunge winds up before it moves (melee-press-feel.md section 2b): a crouch the defender can read.") +
   L(1, "var wind: int = int(c.lunge.get(\"windupTicks\", {}).get(_weightName(weight), 0)) if (b == MID and not charge) else 0") +
   L(1, "A.state = \"free\"") +
   L(1, "A.hideT = 0.0") +
   L(1, "A.face = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(A.x, D.x)), A.face)") +
   L(1, "A.rush = null") +
   L(1, "if wind == 0:") +
   L(2, "_startRush(S, A, D, n)") +
   L(1, "DirInterrupt.si(A, DirInterrupt.TAUNT_AGE, 0)") +
   L(1, "DirInterrupt.si(A, DirInterrupt.APPR_WIND, wind)") +
   L(1, "DirInterrupt.si(A, DirInterrupt.APPR_LEFT, wind + n)")],
  [L(1, "SimFx.rush(S, A, D, S.tick + n)") +
   L(1, "var what: String = \": CHARGES\" if charge else (\": LUNGE\" if b == MID else \": FLIES IN\")"),
   L(1, "SimFx.rush(S, A, D, S.tick + wind + n)") +
   L(1, "if charge or b == MID:") +
   L(2, "_startCue(S, A, D, (\"charge_\" if charge else \"lunge_\") + _weightName(weight), \"charge\" if charge else \"lunge\", wind, n)") +
   L(1, "var what: String = \": CHARGES\" if charge else (\": LUNGE\" if b == MID else \": FLIES IN\")")],
  ["\" bh; the exchange starts at the wind-up, in \" + str(n) + \" ticks\")\n" + L(1, "_aiChoose(S, D, n)"),
   "\" bh; \" + (\"he winds up for \" + str(wind) + \" ticks; \" if wind > 0 else \"\") + \"the exchange starts at the wind-up, in \" + str(wind + n) + \" ticks\")\n" + L(1, "_aiChoose(S, D, wind + n)")],
  [L(2, "begin(S, f, o, w, ((req >> 2) & 3) - 1, DirInterrupt.gi(f, DirInterrupt.APPR_TICK), 0, true)") +
   L(2, "SimFx.cue(S, f, \"charge_\" + _weightName(w), \"\", \"\")"),
   L(2, "begin(S, f, o, w, ((req >> 2) & 3) - 1, DirInterrupt.gi(f, DirInterrupt.APPR_TICK), 0, true)   # it sends charge_light or charge_heavy (_startCue)")],
  ["## Where the approach ends, as an offset from D on the given side: engageBh away.",
   "## The start cue of a lunge or a charge, for Camera and VFX (docs/camera/lunge-framing.md). The cue's name gives the\n" +
   "## kind and the weight (lunge_light, lunge_heavy, charge_light, charge_heavy). On the same event: text is the kind\n" +
   "## (lunge or charge), target the rival's slot, amount the wind-up's ticks and n the ticks of the move after it.\n" +
   "static func _startCue(S: SimState, A, D, name: String, kind: String, wind: int, out: int) -> void:\n" +
   L(1, "SimFx.cue(S, A, name, kind, \"\")") +
   L(1, "var e = S.out.fx[S.out.fx.size() - 1]") +
   L(1, "e.target = float(S.fighters.find(D))") +
   L(1, "e.amount = float(wind)") +
   L(1, "e.n = out") +
   "\n\n" +
   "## The approach's move: A is carried to engageBh from D, on his own side, over n ticks.\n" +
   "static func _startRush(S: SimState, A, D, n: int) -> void:\n" +
   L(1, "var r := SimState.Rush.new()") +
   L(1, "r.tgt = D") +
   L(1, "r.off = _endOff(S, D, SimMathx.jsign(DirMelee.sideOff(A, D, float(data().engageBh) * BH, \"own\")))") +
   L(1, "r.end = S.T + float(n) * SimConst.DT") +
   L(1, "A.rush = r") +
   "\n\n" +
   "## Where the approach ends, as an offset from D on the given side: engageBh away."],
  [L(2, "if S.game.ko != null or S.dirS.ex != null or f.state != \"free\" or f.stunTicks > 0 or (f.rush == null and left > 2):"),
   L(2, "var wind: int = DirInterrupt.gi(f, DirInterrupt.APPR_WIND)") +
   L(2, "if S.game.ko != null or S.dirS.ex != null or f.state != \"free\" or f.stunTicks > 0 or (f.rush == null and left > 2 and wind == 0):")],
  [L(2, "left -= 1") +
   L(2, "DirInterrupt.si(f, DirInterrupt.APPR_LEFT, left)") +
   L(2, "if left == 0:"),
   L(2, "left -= 1") +
   L(2, "DirInterrupt.si(f, DirInterrupt.APPR_LEFT, left)") +
   L(2, "if wind > 0:") +
   L(3, "# The lunge's wind-up: he holds his crouch, and moves when it ends.") +
   L(3, "wind -= 1") +
   L(3, "DirInterrupt.si(f, DirInterrupt.APPR_WIND, wind)") +
   L(3, "f.vx = 0.0") +
   L(3, "f.vy = 0.0") +
   L(3, "if wind == 0:") +
   L(4, "_startRush(S, f, SimRoster.opp(S, f), left)") +
   L(3, "continue") +
   L(2, "if left == 0:")],
  [L(1, "DirInterrupt.si(f, DirInterrupt.APPR_LEFT, 0)") +
   L(1, "f.rush = null") +
   L(1, "SimEvents.feed(S, f.name + \" APPROACH ENDS\", why)"),
   L(1, "DirInterrupt.si(f, DirInterrupt.APPR_LEFT, 0)") +
   L(1, "DirInterrupt.si(f, DirInterrupt.APPR_WIND, 0)") +
   L(1, "f.rush = null") +
   L(1, "SimEvents.feed(S, f.name + \" APPROACH ENDS\", why)")],
]);

// ---------------------------------------------------------------- 3. the beat fields
edit("sim/director/recipe.gd", [
  [L(2, "if b.args != null and b.args.has(\"piece\"):") + L(3, "continue"),
   L(2, "if b.args != null and (b.args.has(\"piece\") or b.args.has(\"style\")):") + L(3, "continue")],
  [L(2, "salt += 1") +
   L(2, "if id == \"\":") +
   L(3, "continue") +
   L(2, "if b.args == null:") +
   L(3, "b.args = {}") +
   L(2, "b.args[\"piece\"] = id"),
   L(2, "salt += 1") +
   L(2, "if b.args == null:") +
   L(3, "b.args = {}") +
   L(2, "if b.op == \"chainStrike\":") +
   L(3, "b.args[\"a\"] = \"A\"   # a link's blow carries what a strike does") +
   L(3, "b.args[\"d\"] = \"D\"") +
   L(2, "_announce(S, ex, b, who, p, weight, closing or (blurEnder and b == lastA), b == lastA)") +
   L(2, "if id == \"\":") +
   L(3, "continue") +
   L(2, "b.args[\"piece\"] = id")],
  ["## Gives every strike the exchange has pending,",
   "## What a blow tells Animation and VFX (docs/director/brawl-plan.md section 2.7), on its beat's args: style (speed, a\n" +
   "## plain or mashed light; tech, a light from a timed press; heavy), grade (Controls' grade of the press's beat), k (its\n" +
   "## place among his strikes of the exchange) and n (how many of his there are so far), closing (the blur's own closing\n" +
   "## blow), charge (1 for a held press, else 0), hand (r, l, r, ... by k) and ender (a heavy that ends his string).\n" +
   "static func _announce(S: SimState, ex, b, who, p: int, weight: int, closing: bool, last: bool) -> void:\n" +
   L(1, "var rh: int = ((p >> 8) & 3) if p >= 0 else 0") +
   L(1, "var role: String = \"A\" if who == ex.A else \"D\"") +
   L(1, "var k: int = 1") +
   L(1, "var n: int = 0") +
   L(1, "for x in ex.beats:") +
   L(2, "if x.op == \"chainStrike\" or (x.op == \"strike\" and x.args != null):") +
   L(3, "if (\"A\" if (x.op == \"chainStrike\" or x.args == null) else String(x.args.get(\"a\", \"A\"))) == role:") +
   L(4, "n += 1") +
   L(4, "if x == b:") +
   L(5, "k = n") +
   L(1, "b.args[\"style\"] = \"heavy\" if weight == SimAct.HEAVY else (\"tech\" if rh == DirAlchemy.TIMED else \"speed\")") +
   L(1, "b.args[\"grade\"] = DirAlchemy.gradeOf(who)") +
   L(1, "b.args[\"k\"] = k") +
   L(1, "b.args[\"n\"] = n") +
   L(1, "b.args[\"closing\"] = closing") +
   L(1, "b.args[\"charge\"] = 1.0 if rh == DirAlchemy.HELD else 0.0") +
   L(1, "b.args[\"hand\"] = \"r\" if (k % 2) == 1 else \"l\"") +
   L(1, "b.args[\"ender\"] = who == ex.A and weight == SimAct.HEAVY and last and DirInterrupt.gi(who, DirInterrupt.LANDED) >= 1") +
   "\n\n" +
   "## Gives every strike the exchange has pending,"],
]);
edit("sim/director/alchemy.gd", [
  ["## His newest press as a packed integer, if it is still alive; else -1.\n",
   "## Controls' grade of his newest press against its beat (perfect, good or off); none when it had no blow to time against.\n" +
   "static func gradeOf(f) -> String:\n" +
   L(1, "_size(f)") +
   L(1, "var n: int = f.act.dirI[COUNT]") +
   L(1, "if n == 0:") +
   L(2, "return \"none\"") +
   L(1, "var beat: int = f.act.dirI[BEAT0 + (n - 1) % RING]") +
   L(1, "return \"none\" if beat == SimPressRead.NO_BEAT else SimPressRead.grade_of(beat)") +
   "\n\n" +
   "## His newest press as a packed integer, if it is still alive; else -1.\n"],
]);

// ---------------------------------------------------------------- 4. constants to data, values unchanged
edit("sim/director/exchange.gd", [
  ["static func cooldownAfter(ex) -> float:\n" +
   L(1, "return SimMathx.jclamp(COOL_MIN + COOL_PER_SEC * ex.t, COOL_MIN, COOL_MAX)"),
   "## The numbers are data (interrupts.json pace.cooldown); the constants above stand in when the block is missing.\n" +
   "static func cooldownAfter(ex) -> float:\n" +
   L(1, "var c: Dictionary = DirInterrupt.data().get(\"pace\", {}).get(\"cooldown\", {})") +
   L(1, "var lo: float = float(c.get(\"min\", COOL_MIN))") +
   L(1, "return SimMathx.jclamp(lo + float(c.get(\"perSec\", COOL_PER_SEC)) * ex.t, lo, float(c.get(\"max\", COOL_MAX)))")],
]);
{
  // ai.gd: the stance block. The circle's and the sway's constants become locals read from data.
  const rel = "sim/director/ai.gd";
  const f = path.join(root, rel);
  let s = fs.readFileSync(f, "utf8");
  const crlf = s.includes("\r\n");
  if (crlf) s = s.split("\r\n").join("\n");
  if (!s.includes("var stn: Dictionary = skill().get(\"stance\", {})")) {
    const rep = (a, b) => { if (s.split(a).length !== 2) throw new Error(rel + ": anchor " + a.slice(0, 60)); s = s.replace(a, () => b); };
    rep(L(1, "var a = f.ai") + "	# I2b: the AI writes the v2 record.",
        L(1, "var a = f.ai") +
        L(1, "# The stance numbers are data (ai.json stance); the constants below stand in when the block is missing.") +
        L(1, "var stn: Dictionary = skill().get(\"stance\", {})") +
        L(1, "var cir: Dictionary = stn.get(\"circle\", {})") +
        L(1, "var circleR: float = float(cir.get(\"r\", CIRCLE_R))") +
        L(1, "var circleX: float = float(cir.get(\"x\", CIRCLE_X))") +
        L(1, "var circleY: float = float(cir.get(\"y\", CIRCLE_Y))") +
        L(1, "var circleRate: float = float(cir.get(\"rate\", CIRCLE_RATE))") +
        L(1, "var swayRate: float = float(stn.get(\"swayRate\", SWAY_RATE))") +
        "	# I2b: the AI writes the v2 record.");
    rep(L(2, "a.t = S.rng.range_(0.7, 1.6)") +
        L(2, "var w: Array = [2.4 if hpF > 0.35 else 1.0, 1.6 if hpF < 0.55 else 0.7, 1.2, 3.2 if hpF < 0.3 else (1.2 if f.ki < 25.0 else 0.25)]"),
        L(2, "var rp: Array = stn.get(\"repick\", [0.7, 1.6])") +
        L(2, "a.t = S.rng.range_(float(rp[0]), float(rp[1]))") +
        L(2, "var wp: Dictionary = stn.get(\"press\", {})") +
        L(2, "var wg: Dictionary = stn.get(\"guard\", {})") +
        L(2, "var we: Dictionary = stn.get(\"escape\", {})") +
        L(2, "var w: Array = [float(wp.get(\"fresh\", 2.4)) if hpF > float(wp.get(\"hurtBelow\", 0.35)) else float(wp.get(\"hurt\", 1.0)), float(wg.get(\"hurt\", 1.6)) if hpF < float(wg.get(\"hurtBelow\", 0.55)) else float(wg.get(\"fresh\", 0.7)), float(stn.get(\"evade\", 1.2)), float(we.get(\"hurt\", 3.2)) if hpF < float(we.get(\"hurtBelow\", 0.3)) else (float(we.get(\"lowKi\", 1.2)) if f.ki < float(we.get(\"lowKiBelow\", 25.0)) else float(we.get(\"rest\", 0.25)))]"));
    rep(L(2, "i.mx = -SimMathx.jsign(d) if dist < 500.0 else SimMathx.jsign(d) * 0.5"),
        L(2, "i.mx = -SimMathx.jsign(d) if dist < float(stn.get(\"evadeBackoff\", 500.0)) else SimMathx.jsign(d) * 0.5"));
    // every use of the five constants inside aiInput (their definitions keep the names)
    // (from the line after the locals, so the locals' own defaults keep the constants' names)
    const body0 = s.indexOf("\t# I2b: the AI writes the v2 record.");
    const body1 = s.indexOf("\n## Called by the director as a melee attack starts against D", body0);
    if (body0 < 0 || body1 < 0) throw new Error(rel + ": aiInput bounds");
    let body = s.slice(body0, body1);
    for (const [c, v] of [["CIRCLE_RATE", "circleRate"], ["CIRCLE_R", "circleR"], ["CIRCLE_X", "circleX"], ["CIRCLE_Y", "circleY"], ["SWAY_RATE", "swayRate"]]) {
      if (!body.includes(c)) throw new Error(rel + ": no use of " + c);
      body = body.split(c).join(v);
    }
    s = s.slice(0, body0) + body + s.slice(body1);
    if (crlf) s = s.split("\n").join("\r\n");
    fs.writeFileSync(f, s);
    console.log(rel + ": the stance block applied");
  } else console.log(rel + ": 0 edits");
}

// ---------------------------------------------------------------- data
// Legal's sequence rule (docs/legal/movegen-screen.md: no two blows running to the gut, no more than three running to
// one target): two blur patterns of the live recipes are replaced by Combat's fixed rows, from its parked
// docs/combat/pending/recipes.brawl.json. Those two rows only (the EP's grant); nothing else of the parked file.
{
  const live = path.join(root, "data/combat/recipes.json");
  const txt = fs.readFileSync(live, "utf8");
  const eol = txt.includes("\r\n") ? "\r\n" : "\n";
  const plain = txt.split("\r\n").join("\n");
  const j = JSON.parse(plain);
  if (JSON.stringify(j, null, 1) + "\n" !== plain) throw new Error("recipes.json: not in the one-space layout this edit keeps");
  const parked = JSON.parse(fs.readFileSync(path.join(root, "docs/combat/pending/recipes.brawl.json"), "utf8"));
  let n = 0;
  for (const k of ["pendulum", "undercut"]) {
    const row = parked.blurPatterns[k];
    if (!Array.isArray(row) || !Array.isArray(j.blurPatterns[k])) throw new Error("recipes: no pattern " + k);
    if (JSON.stringify(j.blurPatterns[k]) !== JSON.stringify(row)) { j.blurPatterns[k] = row; n++; }
  }
  fs.writeFileSync(live, (JSON.stringify(j, null, 1) + "\n").split("\n").join(eol));
  console.log("data/combat/recipes.json: " + n + " pattern rows replaced");
}
edit("data/combat/finishers.json", [
  [`"perStray": -0.15, "floor": 0.08,`, `"perStray": -0.10, "floor": 0.08,`],
]);
edit("data/director/interrupts.json", [
  [`    "lunge": {
      "speed": 4000,
      "minTicks": 3,
      "maxTicks": 20
    },`,
   `    "lunge": {
      "speed": 4000,
      "minTicks": 3,
      "maxTicks": 20,
      "windupTicks": {
        "light": 6,
        "heavy": 10
      }
    },`],
  [`  "signature": {`,
   `  "pace": {
    "cooldown": {
      "min": 0.25,
      "perSec": 0.1,
      "max": 0.6
    },
    "_note": "Pacing between exchanges (sim/director/exchange.gd cooldownAfter). cooldown: the seconds after an exchange before the next may start: min, plus perSec for each second the exchange ran, at most max. bands.lunge.windupTicks (melee-press-feel.md section 2b): a mid-band lunge holds its crouch this many ticks before it moves, by the press's weight"
  },
  "signature": {`],
]);
edit("data/director/ai.json", [
  [`7.0 gave 35, and 6.5 is in"`,
   `7.0 gave 35, and 6.5 is in. On brawl slice B0 (the mid lunge winds up 6 or 10 ticks) 6.5 gives 42 of 100 with a masher script that carries the intent's waited field for a press a hit-stop held, as qa/godot/players.gd does; qa/godot/masher.gd did not carry it, and read 33 without the wind-up and 52 with it"`],
  [`  "level": "medium",
`,
   `  "stance": {
    "repick": [0.7, 1.6],
    "press": {"fresh": 2.4, "hurt": 1.0, "hurtBelow": 0.35},
    "guard": {"hurt": 1.6, "fresh": 0.7, "hurtBelow": 0.55},
    "evade": 1.2,
    "escape": {"hurt": 3.2, "hurtBelow": 0.3, "lowKi": 1.2, "lowKiBelow": 25, "rest": 0.25},
    "circle": {"r": 260, "x": 120, "y": 70, "rate": 2.4},
    "swayRate": 5.0,
    "evadeBackoff": 500,
    "_note": "The AI's stance pick between exchanges (sim/director/ai.gd aiInput). repick: it picks again after a time drawn in this range, seconds. The four weights: press (fresh while its vitality is above hurtBelow, else hurt), guard (hurt while its vitality is below hurtBelow, else fresh), evade, and escape (hurt below hurtBelow; else lowKi while its ki is below lowKiBelow; else rest). circle: in the press stance within r units it circles the rival on an ellipse of half-width x and half-height y, rate radians a second; in the guard stance within r it sways at swayRate. evadeBackoff: in the evade stance it backs off while nearer than this, in units"
  },
  "level": "medium",
`],
]);
console.log("done");
