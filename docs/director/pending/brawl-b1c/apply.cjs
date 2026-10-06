// Brawl slice B1c: Game Design's section 9e ruling 2 and section 9f (docs/design/melee-press-feel.md).
// node apply.cjs <repo root>. Idempotent. It goes on top of slice B1b (5651c59) and Simulation's blocked shots (f32a7a8).
//  1. A perfect block and a reversal resolve inside the brawl. Neither ends it. The attacker's blow is turned (or his
//     string is cut), his run is cleared and he staggers in place. The blocker has the riposte: his next attack pressed
//     within riposteTicks can't be blocked or dodged; a light is worth a skill strike, a heavy a brawl heavy, and a
//     heavy against a turned heavy or ender separates them as an ender does. The reversal's heavy lands for certain
//     reversal.contactTicks after the press, in place. Both count on the brink as a close does (setup.weight.riposte).
//  2. The AI closes fewer strings with an ender (brawl.enderShare 0.6, 0.4, 0.35), and its heavy at a guard takes
//     that share too when it would be its string's ender.
//  3. The numbers that follow from the measurement: brawl.damageMul, and the shooters' give-back in ai.json.
const fs = require("fs"), path = require("path");
const root = process.argv[2];
if (!root) throw new Error("usage: node apply.cjs <repo root>");
const T = "\t";
function edit(rel, pairs) {
  const p = path.join(root, rel);
  let t = fs.readFileSync(p, "utf8"), n = 0;
  for (const [a, b, mark] of pairs) {
    if (t.includes(mark || b)) continue;   // already applied
    if (!t.includes(a)) throw new Error(rel + ": not found: " + a.slice(0, 70));
    t = t.replace(a, () => b);
    n++;
  }
  fs.writeFileSync(p, t);
  console.log(rel + ": " + n + " edits");
}

// ------------------------------------------------------------------ the probe (it sits beside this script)
fs.copyFileSync(path.join(__dirname, "brawl_probe.gd"), path.join(root, "sim/director/tools/brawl_probe.gd"));
console.log("sim/director/tools/brawl_probe.gd: written");

// ------------------------------------------------------------------ sim/director/brawl.gd
edit("sim/director/brawl.gd", [
  // the state
  ["const END: int = BASE + 34\n",
   "const RIP_UNTIL: int = BASE + 34 # S.tick until which his next attack press is the riposte of his perfect block (section 9f); 0 none\n" +
   "const RIP_KIND: int = BASE + 35  # ... 1: the blow he turned was a light; 2: a heavy or an ender, so a heavy riposte separates them\n" +
   "const AI_RIP: int = BASE + 36    # the AI: 1 while it has its riposte to throw\n" +
   "const END: int = BASE + 37\n"],
  // the riposte: the blow of the press
  [T + "var kind: int = HEAVY if weight == SimAct.HEAVY else (FLURRY if _g(f, TAP_GAP) > 0 else LIGHT)\n",
   T + "var kind: int = HEAVY if weight == SimAct.HEAVY else (FLURRY if _g(f, TAP_GAP) > 0 else LIGHT)\n" +
   T + "# The riposte (section 9f): his next attack pressed within riposteTicks of his perfect block. It can't be blocked or\n" +
   T + "# dodged. A light is worth a skill strike; a heavy is a brawl heavy, and against a turned heavy or ender it separates.\n" +
   T + "var rip: int = _g(f, RIP_KIND) if (_g(f, RIP_UNTIL) > 0 and p <= _g(f, RIP_UNTIL)) else 0\n" +
   T + "_s(f, RIP_UNTIL, 0)\n" +
   T + "_s(f, RIP_KIND, 0)\n" +
   T + "if rip > 0 and kind == FLURRY:\n" +
   T + T + "kind = LIGHT\n"],
  [T + "var ender: bool = kind == HEAVY and _g(f, STRING_N) >= int(c.enderAfter)\n",
   T + "var ender: bool = kind == HEAVY and _g(f, STRING_N) >= int(c.enderAfter)\n" +
   T + "if rip > 0:\n" +
   T + T + "if kind == HEAVY:\n" +
   T + T + T + "ender = rip == 2\n" +
   T + T + "else:\n" +
   T + T + T + "dmg = float(c.light.damage) * float(c.damageMul) * float(c.skillMul)\n"],
  [T + "var piece: String = _piece(S, f, weight, ((pp >> 2) & 3) == 2, ender)\n",
   T + "if rip > 0:\n" +
   T + T + "args[\"riposte\"] = true\n" +
   T + T + "args[\"sure\"] = true\n" +
   T + T + "o2[\"ignoreStance\"] = true\n" +
   T + T + "o2[\"noParry\"] = true\n" +
   T + T + "o2[\"weighed\"] = true\n" +
   T + T + "var rp = _ev(S, f, \"riposte\", \"heavy\" if kind == HEAVY else \"light\")\n" +
   T + T + "rp.target = float(S.fighters.find(o))\n" +
   T + T + "rp.n = S.tick + lead\n" +
   T + "var piece: String = _piece(S, f, weight, ((pp >> 2) & 3) == 2, ender)\n",
   "args[\"riposte\"] = true"],
  // contact: a turned blow, the riposte's light
  [T + T + "return   # a perfect block took the exchange over\n",
   T + T + "return   # a perfect block took the exchange over\n" +
   T + "if bool(a.o.get(\"turned\", false)):\n" +
   T + T + "return   # a perfect block turned it (section 9f): he staggers in place and the brawl goes on\n"],
  [T + "var closing: bool = _closes(S, ex, f)\n" + T + "_s(f, LL_AT, S.tick)\n",
   T + "if bool(a.get(\"riposte\", false)):\n" +
   T + T + "# The riposte's light: a skill strike's reel, and on the brink it counts as a close does. The brawl goes on.\n" +
   T + T + "_s(f, LL_AT, S.tick)\n" +
   T + T + "_reel(S, o, int(c.riposteReelTicks))\n" +
   T + T + "DirExchange.decisive(S, ex, f, o, \"knockback\", \"riposte\")\n" +
   T + T + "if _setPiece(ex):\n" +
   T + T + T + "over(S, ex, \"finisher\")\n" +
   T + T + "return\n" +
   T + "var closing: bool = _closes(S, ex, f)\n" + T + "_s(f, LL_AT, S.tick)\n",
   "# The riposte's light: a skill strike's reel"],
  // a blow scheduled from inside a blow's own beat (the reversal's heavy) counts from this tick: the clock has stepped
  [T + "DirMelee.strike(S, ex, f, o, float(a.dmg), a.o)\n" + T + "f.ambush = false   # an ambush is its first blow\n",
   T + "var was: bool = _inTick\n" +
   T + "_inTick = true   # the exchange's clock has stepped this tick: a blow scheduled from inside this beat (a reversal's heavy) counts from here\n" +
   T + "DirMelee.strike(S, ex, f, o, float(a.dmg), a.o)\n" +
   T + "_inTick = was\n" +
   T + "f.ambush = false   # an ambush is its first blow\n",
   "a blow scheduled from inside this beat"],
  // a blocked heavy that was reversed doesn't break the guard
  [T + T + "# 40 ticks down are B3).\n" + T + T + "if kind == HEAVY:\n",
   T + T + "# 40 ticks down are B3).\n" +
   T + T + "if f.stunTicks > 0 and sureAgainst(ex, f):\n" +
   T + T + T + "return   # he reversed it (section 9f): the attacker staggers in place, and the guard is not broken\n" +
   T + T + "if kind == HEAVY:\n",
   "return   # he reversed it (section 9f)"],
  // a sure heavy that lands in place counts as a close does
  [T + "st.target = float(S.fighters.find(f))\n" + T + "st.n = int(c.heavy.staggerTicks)\n\n\n## f reels for `ticks`",
   T + "st.target = float(S.fighters.find(f))\n" + T + "st.n = int(c.heavy.staggerTicks)\n" +
   T + "if bool(a.get(\"sure\", false)):\n" +
   T + T + "# The reversal's heavy, or a riposte's heavy on a turned light: on the brink it counts as a close does.\n" +
   T + T + "DirExchange.decisive(S, ex, f, o, \"knockback\", \"riposte\")\n" +
   T + T + "if _setPiece(ex):\n" +
   T + T + T + "over(S, ex, \"finisher\")\n\n\n## f reels for `ticks`",
   "# The reversal's heavy, or a riposte's heavy on a turned light"],
  // the two resolutions
  ["## Which of the exchange's interrupts a brawl allows (DirData.allows).\n",
   "## A perfect block inside the brawl (DirInterrupt.perfectBlock; section 9f). a's blow is turned: his string is closed,\n" +
   "## his run is cleared and he staggers in place. d has the riposte: his next attack pressed within riposteTicks.\n" +
   "## launch: the turned blow was a heavy or an ender, so a heavy riposte separates them. The brawl goes on.\n" +
   "static func perfectBlocked(S: SimState, ex, a, d, o: Dictionary, launch: bool) -> void:\n" +
   T + "var c: Dictionary = cfg()\n" +
   T + "var n: int = int(c.perfectBlock.staggerTicks)\n" +
   T + "o[\"turned\"] = true\n" +
   T + "a.stunTicks = maxi(a.stunTicks, n)\n" +
   T + "_drop(S, ex, a)\n" +
   T + "_tradeReset(ex)\n" +
   T + "_s(d, RIP_UNTIL, S.tick + int(c.riposteTicks))\n" +
   T + "_s(d, RIP_KIND, 2 if launch else 1)\n" +
   T + "_s(ex.A, LAST_AT, S.tick)   # the idle clock starts again\n" +
   T + "_s(ex.D, LAST_AT, S.tick)\n" +
   T + "var st = _ev(S, a, \"stagger\", \"perfect_block\")\n" +
   T + "st.target = float(S.fighters.find(d))\n" +
   T + "st.n = n\n" +
   T + "if d.ai != null and S.rng.next() < float(DirAI.lv().riposte):\n" +
   T + T + "_s(d, AI_RIP, 1)\n" +
   "\n\n" +
   "## A reversal inside the brawl (DirInterrupt.reversal; section 9f). att's string is closed, his run is cleared and he\n" +
   "## staggers in place. f's heavy lands for certain reversal.contactTicks after the press, as a brawl heavy, in place:\n" +
   "## it doesn't knock back and it doesn't launch. The brawl goes on.\n" +
   "static func reversed(S: SimState, ex, f, att) -> void:\n" +
   T + "var c: Dictionary = cfg()\n" +
   T + "var rv: Dictionary = c.reversal\n" +
   T + "var n: int = int(rv.staggerTicks)\n" +
   T + "var lead: int = int(rv.contactTicks)\n" +
   T + "att.stunTicks = maxi(att.stunTicks, n)\n" +
   T + "_drop(S, ex, att)\n" +
   T + "_drop(S, ex, f)\n" +
   T + "_tradeReset(ex)\n" +
   T + "var st = _ev(S, att, \"stagger\", \"reversal\")\n" +
   T + "st.target = float(S.fighters.find(f))\n" +
   T + "st.n = n\n" +
   T + "var role: String = \"A\" if f == ex.A else \"D\"\n" +
   T + "DirInterrupt.si(f, DirInterrupt.PHRASE_P, SimAct.HEAVY)\n" +
   T + "_s(f, STR_ON, 1)\n" +
   T + "_s(f, STR_K, 1)\n" +
   T + "var args := {\"a\": role, \"d\": \"D\" if role == \"A\" else \"A\", \"dmg\": float(c.heavy.damage) * float(c.damageMul) * float(c.heavyMul),\n" +
   T + T + "\"o\": {\"class\": \"heavy\", \"stop\": float(int(c.hitstop.heavy)) / DirData.TICKS_PER_SEC, \"big\": true, \"kb\": float(c.recoil), \"ignoreStance\": true, \"noParry\": true, \"weighed\": true},\n" +
   T + T + "\"brawl\": true, \"bk\": HEAVY, \"style\": \"heavy\", \"grade\": \"none\", \"k\": 1, \"n\": 1, \"closing\": false, \"charge\": 0.0, \"hand\": \"r\", \"ender\": false,\n" +
   T + T + "\"sure\": true, \"reversal\": true}\n" +
   T + "var piece: String = _piece(S, f, SimAct.HEAVY, false, false)\n" +
   T + "if piece != \"\":\n" +
   T + T + "args[\"piece\"] = piece\n" +
   T + "DirExchange.schedule(ex, ex.t + (float(lead + (0 if _inTick else 1)) - 0.25) / DirData.TICKS_PER_SEC, \"strike\", args)\n" +
   T + "_s(f, LINE, 1)\n" +
   T + "_s(f, KIND, HEAVY)\n" +
   T + "_s(f, CONTACT, _now(S) + lead)\n" +
   T + "_s(f, HOLD_AT, 0)\n" +
   T + "_s(f, FREE_AT, S.tick + (1 << 20))\n" +
   T + "_s(f, LAND_AT, S.tick)\n" +
   T + "_s(f, BLOWS, _g(f, BLOWS) + 1)\n" +
   T + "_s(ex.A, LAST_AT, S.tick)   # the idle clock starts again\n" +
   T + "_s(ex.D, LAST_AT, S.tick)\n" +
   T + "if f.ai != null:\n" +
   T + T + "_s(f, AI_GUARD, 0)\n" +
   T + T + "_s(f, AI_LEFT, 0)\n" +
   T + T + "_s(f, AI_CLOSE, 0)\n" +
   T + T + "_s(f, AI_RIP, 0)\n" +
   T + T + "_s(f, AI_NEXT, S.tick + lead)\n" +
   T + "var e = _ev(S, f, \"blow\", KINDS[HEAVY])\n" +
   T + "e.target = float(S.fighters.find(att))\n" +
   T + "e.n = S.tick + lead\n" +
   T + "e.amount = float(S.tick)\n" +
   T + "e.dur = float(lead)\n" +
   "\n\n" +
   "## True when f's rival has a blow on its way that f can't block or dodge: a riposte, or a reversal's heavy.\n" +
   "static func sureAgainst(ex, f) -> bool:\n" +
   T + "var role: String = \"D\" if f == ex.A else \"A\"\n" +
   T + "for b in ex.beats:\n" +
   T + T + "if not b.done and b.op == \"strike\" and b.args != null and b.args.get(\"sure\", false) and String(b.args.a) == role:\n" +
   T + T + T + "return true\n" +
   T + "return false\n" +
   "\n\n" +
   "## Which of the exchange's interrupts a brawl allows (DirData.allows).\n",
   "static func perfectBlocked("],
  // a sure blow can't be left
  [T + T + "if ex.t > SimConst.DT * 1.5 and f.input.sprint and f.stunTicks <= 0 and f.input.mx",
   T + T + "if ex.t > SimConst.DT * 1.5 and f.input.sprint and f.stunTicks <= 0 and not sureAgainst(ex, f) and f.input.mx"],
  // the AI: its riposte
  [T + "# Its answer to being closed on (section 9d, ruling 4): a heavy as its stagger ends, at its level's heavyAfterClose.\n",
   T + "# Its riposte (section 9f): after its perfect block, its next press inside the window. Against a turned heavy or\n" +
   T + "# ender a heavy riposte is an ender, so it takes the ender's share; otherwise it is a light, and the brawl goes on.\n" +
   T + "if _g(f, AI_RIP) == 1:\n" +
   T + T + "if _g(f, RIP_UNTIL) == 0 or S.tick > _g(f, RIP_UNTIL):\n" +
   T + T + T + "_s(f, AI_RIP, 0)\n" +
   T + T + "elif _free(S, f):\n" +
   T + T + T + "_s(f, AI_RIP, 0)\n" +
   T + T + T + "_s(f, AI_GUARD, 0)\n" +
   T + T + T + "_s(f, AI_LEFT, 0)\n" +
   T + T + T + "_s(f, AI_CLOSE, 0)\n" +
   T + T + T + "if _g(f, RIP_KIND) == 2 and S.rng.next() < float(bl.get(\"enderShare\", 0.5)):\n" +
   T + T + T + T + "_aiHeavy(S, f, lv, false)\n" +
   T + T + T + "else:\n" +
   T + T + T + T + "i.light = true\n" +
   T + T + T + T + "_s(f, AI_NEXT, S.tick + int(bl.get(\"tapGap\", 10)))\n" +
   T + T + T + "return\n" +
   T + T + "else:\n" +
   T + T + T + "return   # its line is busy: the riposte waits\n" +
   T + "# Its answer to being closed on (section 9d, ruling 4): a heavy as its stagger ends, at its level's heavyAfterClose.\n",
   "# Its riposte (section 9f): after its perfect block"],
  // the AI: the heavy at a guard takes the ender's share when it would be the ender
  [T + "if o.stance == 1.0 and S.rng.next() < float(lv.get(\"breakGuard\", 0.0)):\n",
   T + "# A heavy thrown after enderAfter landed blows is the ender, whatever it was thrown for: so the heavy at a guard takes\n" +
   T + "# the ender's share as well (section 9f).\n" +
   T + "if o.stance == 1.0 and S.rng.next() < float(lv.get(\"breakGuard\", 0.0)) and (_g(f, STRING_N) < int(c.enderAfter) or S.rng.next() < float(vs.get(\"enderShare\", bl.get(\"enderShare\", 0.5)))):\n",
   "so the heavy at a guard takes"],
]);

// ------------------------------------------------------------------ sim/director/interrupt.gd
edit("sim/director/interrupt.gd", [
  [T + T + "if b.done or b.op != \"strike\" or b.args.d != role or b.args.o == null:\n" + T + T + T + "continue\n" + T + T + "var cls: String = String(b.args.o.get(\"class\", \"\"))\n" + T + T + "var w: float = _window(f, cls, ex.kind == \"heavy\")\n" + T + T + "if w < 0.0 or b.args.o.get(\"perfect\", false):\n",
   T + T + "if b.done or b.op != \"strike\" or b.args.d != role or b.args.o == null or b.args.get(\"sure\", false):\n" + T + T + T + "continue   # (a riposte and a reversal's heavy can't be blocked: melee-press-feel.md section 9f)\n" + T + T + "var cls: String = String(b.args.o.get(\"class\", \"\"))\n" + T + T + "var w: float = _window(f, cls, ex.kind == \"heavy\")\n" + T + T + "if w < 0.0 or b.args.o.get(\"perfect\", false):\n",
   "(a riposte and a reversal's heavy can't be blocked"],
  [T + "var c: Dictionary = data().perfectBlock\n" + T + "_takeOver(ex)\n" + T + "DirBrawl.over(S, ex, \"perfect_block\")\n",
   T + "var c: Dictionary = data().perfectBlock\n" +
   T + "if DirBrawl.isBrawl(ex) and DirBrawl.cfg().has(\"perfectBlock\"):\n" +
   T + T + "# Inside a brawl it resolves in place (melee-press-feel.md section 9f): he staggers where he is, the blocker has\n" +
   T + T + "# the riposte, and the brawl goes on.\n" +
   T + T + "var sep: bool = String(o.get(\"class\", \"\")) == \"heavy\"   # a turned heavy or ender: a heavy riposte separates them\n" +
   T + T + "d.ki = SimMathx.jmin(100.0, d.ki + float(c.ki))\n" +
   T + T + "S.dirS.stop = SimMathx.jmax(S.dirS.stop, float(c.stopTicks) / DirData.TICKS_PER_SEC)\n" +
   T + T + "SimFx.cue(S, d, \"perfect_block\", \"\", \"\")\n" +
   T + T + "SimFx.ring(S, a.x + a.face * 30.0, a.y + 34.0, 700.0, \"#9fe0ff\", 0.4, 10.0)\n" +
   T + T + "SimFx.banner(S, \"PERFECT BLOCK\", \"#9fe0ff\", 0.8)\n" +
   T + T + "SimEvents.feed(S, d.name + \" PERFECT BLOCK\", a.name + \" staggers in place; the next attack is a riposte\" + (\" (a heavy separates them)\" if sep else \"\"))\n" +
   T + T + "SimFx.parry(S, d, a)   # the mood and Pride read it as a parry\n" +
   T + T + "DirBrawl.perfectBlocked(S, ex, a, d, o, sep)\n" +
   T + T + "return\n" +
   T + "_takeOver(ex)\n" + T + "DirBrawl.over(S, ex, \"perfect_block\")\n",
   "DirBrawl.perfectBlocked("],
  [T + "si(f, REV_READY, S.tick + int(c.cooldownTicks))\n" + T + "_takeOver(ex)\n" + T + "DirBrawl.over(S, ex, \"reversal\")\n",
   T + "si(f, REV_READY, S.tick + int(c.cooldownTicks))\n" +
   T + "if DirBrawl.isBrawl(ex) and DirBrawl.cfg().has(\"reversal\"):\n" +
   T + T + "# Inside a brawl it resolves in place (melee-press-feel.md section 9f): his heavy lands as a brawl heavy, the\n" +
   T + T + "# attacker staggers where he is, and the brawl goes on.\n" +
   T + T + "var who = ex.D if f == ex.A else ex.A\n" +
   T + T + "DirBrawl.reversed(S, ex, f, who)\n" +
   T + T + "SimFx.cue(S, f, \"reversal\", \"\", \"\")\n" +
   T + T + "SimFx.banner(S, \"REVERSAL\", \"#ffd45a\", 0.8)\n" +
   T + T + "SimEvents.feed(S, f.name + \" REVERSAL\", \"guard-cancel: its heavy lands in place\")\n" +
   T + T + "SimFx.parry(S, f, who)   # the mood reads it as it reads the perfect block (section 9f)\n" +
   T + T + "return true\n" +
   T + "_takeOver(ex)\n" + T + "DirBrawl.over(S, ex, \"reversal\")\n",
   "DirBrawl.reversed("],
  [T + "if DirBrawl.isBrawl(ex) and (ex.branch != \"\" or f.input.mx",
   T + "if DirBrawl.isBrawl(ex) and (ex.branch != \"\" or DirBrawl.sureAgainst(ex, f) or f.input.mx"],
]);

// ------------------------------------------------------------------ data
{
  const p = path.join(root, "data/director/interrupts.json");
  const j = JSON.parse(fs.readFileSync(p, "utf8"));
  const b = j.brawl;
  b.damageMul = 0.31;   // match length with more of the fight in a brawl (section 9f): Game Design's start of 0.34 read a probe mean of 357 s, and 0.31 about 400 s
  b.perfectBlock = { staggerTicks: 20 };
  b.riposteTicks = 30;
  b.riposteReelTicks = 8;
  b.reversal = { contactTicks: 10, staggerTicks: 20 };
  const s = " perfectBlock.staggerTicks, riposteTicks, riposteReelTicks, reversal (section 9f): inside a brawl a perfect block turns the blow, closes the attacker's string, clears his run and staggers him in place for staggerTicks; the blocker's next attack pressed within riposteTicks is the riposte, which can't be blocked or dodged (a light is worth skillMul brawl lights and reels for riposteReelTicks; a heavy is a brawl heavy, and against a turned heavy or ender it separates them as an ender does). A reversal staggers the attacker for reversal.staggerTicks and its heavy lands for certain reversal.contactTicks after the press, in place. Neither ends the brawl; on the brink both count launch.json setup.weight.riposte.";
  if (typeof b._note === "string" && !b._note.includes("riposteTicks")) b._note += s;
  fs.writeFileSync(p, JSON.stringify(j, null, 2) + "\n");
  console.log("data/director/interrupts.json: written");
}
edit("data/director/launch.json", [
  ["\"blurPlain\": 0.34, \"barragePlain\": 0.5}", "\"blurPlain\": 0.34, \"barragePlain\": 0.5, \"riposte\": 0.34}"],
]);
edit("data/director/ai.json", [
  ["\"brawl\": {\"tapGap\": 12, \"string\": [2, 4], \"enderShare\": 0.3,", "\"brawl\": {\"tapGap\": 12, \"string\": [2, 4], \"enderShare\": 0.6,"],
  ["\"brawl\": {\"tapGap\": 8, \"string\": [3, 5], \"enderShare\": 0.45,", "\"brawl\": {\"tapGap\": 8, \"string\": [3, 5], \"enderShare\": 0.4,"],
  ["\"brawl\": {\"tapGap\": 6, \"string\": [3, 5], \"enderShare\": 0.6,", "\"brawl\": {\"tapGap\": 6, \"string\": [3, 5], \"enderShare\": 0.35,"],
  // the shooters' give-back (section 9e): a blocked shot reaches the core again, so medium guards a barrage more than easy does
  ["\"barrageGuard\": 0.05,", "\"barrageGuard\": 0.25,"],
]);
