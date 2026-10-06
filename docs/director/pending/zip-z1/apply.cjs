// Zip slice Z1 (docs/design/melee-press-feel.md section 2c; docs/director/brawl-plan.md sections 7 and 7.10).
// node apply.cjs <repo root>. Idempotent. It goes on top of slice B1c (2b96fdc).
//  - sim/director/zip.gd (new, beside this script): the zip strike and the zip heavy from the mid band.
//  - exchange.gd: a zipper's press and his rival's answer (DirZip.takes), the zip's tick, the exchange its ticks in
//    reach run in (startZip), and no request against a fighter on his way out.
//  - brawl.gd: the brawl's lines with no brawl announced (beginQuiet, quiet, announce), a blow put on a line by rule
//    (blowAt), and the zip's hooks in a press, a blow's throw and a blow's contact.
//  - blast.gd: a shot against a zipper.
//  - data: the zip block.
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

fs.copyFileSync(path.join(__dirname, "zip.gd"), path.join(root, "sim/director/zip.gd"));
console.log("sim/director/zip.gd: written");
fs.copyFileSync(path.join(__dirname, "zip_probe.gd"), path.join(root, "sim/director/tools/zip_probe.gd"));
console.log("sim/director/tools/zip_probe.gd: written");

// ------------------------------------------------------------------ sim/director/exchange.gd
edit("sim/director/exchange.gd", [
  [T + "if DirBrawl.takes(S, A, kind):\n" + T + T + "return   # a brawl is on and he is in it: the press is a blow on his own line, never a request\n",
   T + "if DirBrawl.takes(S, A, kind):\n" + T + T + "return   # a brawl is on and he is in it: the press is a blow on his own line, never a request\n" +
   T + "if DirZip.takes(S, A, kind):\n" + T + T + "return   # a zip: its start with LT held in the mid band, a zipper's own press, or his rival's answer where he stands\n",
   "if DirZip.takes(S, A, kind):"],
  [T + "DirBands.tick(S)   # the approach before an exchange: it counts down, and the exchange starts at its end\n",
   T + "DirBands.tick(S)   # the approach before an exchange: it counts down, and the exchange starts at its end\n" +
   T + "DirZip.tick(S)   # a zip's phases: the tell, the way in, the ticks in reach, the way out\n"],
  [T + "if D.state == \"launched\" or D.state == \"locked\":\n" + T + T + "return WAIT\n",
   T + "if D.state == \"launched\" or D.state == \"locked\" or DirZip.untouchable(D):\n" + T + T + "return WAIT   # (no strike reaches a zipper on his way out)\n"],
  ["## Starts a queued request the director can take.",
   "## A zip's arrival (DirZip): the exchange its ticks in reach run in. It is made as _start makes one, with no approach,\n" +
   "## no cooldown and no template; the zip fills it (DirBrawl.beginQuiet). A zipper has no guard in reach.\n" +
   "static func startZip(S: SimState, A, D, kind: String):\n" +
   T + "var ex := newEx(A, D, kind)\n" +
   T + "A.exT = S.T\n" +
   T + "D.exT = S.T\n" +
   T + "ex.sA = 0.0\n" +
   T + "ex.sD = D.stance\n" +
   T + "A.face = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(A.x, D.x)), A.face)\n" +
   T + "D.face = -A.face\n" +
   T + "var dState: String = D.state\n" +
   T + "A.state = \"locked\"\n" +
   T + "D.state = \"locked\"\n" +
   T + "D.dPrev = dState\n" +
   T + "S.dirS.ex = ex\n" +
   T + "S.dirS.exN += 1; ex.n = S.dirS.exN\n" +
   T + "SimWounds.onExchangeStart(S, ex)\n" +
   T + "DirAlchemy.markFlow(A)\n" +
   T + "DirAlchemy.markFlow(D)\n" +
   T + "for s in range(S.fighters.size()):\n" +
   T + T + "if S.fighters[s].brink:\n" +
   T + T + T + "ex.startBrink |= 1 << s\n" +
   T + "DirInterrupt.onStart(S, ex, KIND.find(kind), A.act.mode, 0)\n" +
   T + "return ex\n" +
   "\n\n" +
   "## Starts a queued request the director can take.",
   "static func startZip("],
]);

// ------------------------------------------------------------------ sim/director/brawl.gd
edit("sim/director/brawl.gd", [
  // a zipper's press in reach is spent
  [T + "var ex = S.dirS.ex\n" + T + "if ex.branch != \"\" or ex.cancel or _setPiece(ex):\n" + T + T + "return true   # a set piece is playing: the press is spent\n",
   T + "var ex = S.dirS.ex\n" + T + "if ex.branch != \"\" or ex.cancel or _setPiece(ex):\n" + T + T + "return true   # a set piece is playing: the press is spent\n" +
   T + "if quiet(ex) and f == ex.A:\n" +
   T + T + "var za = _ev(S, f, \"press_ack\", \"zip\")   # a zipper in reach: his one blow is on its way, and a press is spent\n" +
   T + T + "za.n = S.tick\n" +
   T + T + "return true\n",
   "# a zipper in reach: his one blow is on its way"],
  // no brawl_end for a brawl that was never announced
  [T + "ex.branch = why\n" + T + "var e = _ev(S, ex.A, \"brawl_end\", why)\n" + T + "e.n = ex.n\n" + T + "e.amount = float(int(round(ex.t * DirData.TICKS_PER_SEC)))\n" + T + "e.x = float(_g(ex.A, BLOWS))\n" + T + "e.y = float(_g(ex.D, BLOWS))\n",
   T + "var said: bool = ex.tag != \"ZIP\"   # a zip's ticks in reach were never announced as a brawl: nothing ends\n" +
   T + "ex.branch = why\n" +
   T + "if said:\n" +
   T + T + "var e = _ev(S, ex.A, \"brawl_end\", why)\n" + T + T + "e.n = ex.n\n" + T + T + "e.amount = float(int(round(ex.t * DirData.TICKS_PER_SEC)))\n" + T + T + "e.x = float(_g(ex.A, BLOWS))\n" + T + T + "e.y = float(_g(ex.D, BLOWS))\n",
   "var said: bool = ex.tag != \"ZIP\""],
  [T + "SimEvents.feed(S, \"BRAWL ENDS\", why + \": \" + str(_g(ex.A, BLOWS)) + \" and \" + str(_g(ex.D, BLOWS)) + \" blows in \" + str(int(e.amount)) + \" ticks\")\n",
   T + "if said:\n" + T + T + "SimEvents.feed(S, \"BRAWL ENDS\", why + \": \" + str(_g(ex.A, BLOWS)) + \" and \" + str(_g(ex.D, BLOWS)) + \" blows in \" + str(int(round(ex.t * DirData.TICKS_PER_SEC))) + \" ticks\")\n",
   "str(int(round(ex.t * DirData.TICKS_PER_SEC))) + \" ticks\")"],
  // the quiet start, a blow by rule, the announcement
  ["## The brawl is over, and why:",
   "## True while ex is a zip's ticks in reach: the brawl's lines with no brawl announced (DirZip).\n" +
   "static func quiet(ex) -> bool:\n" +
   T + "return isBrawl(ex) and ex.tag == \"ZIP\" and ex.branch == \"\"\n" +
   "\n\n" +
   "## A zip's ticks in reach begin (DirZip._arrive, on the exchange DirExchange.startZip made): both fighters have a\n" +
   "## line, as in a brawl, and no brawl is announced. ex.tag is \"ZIP\" until the zipper is caught or countered.\n" +
   "static func beginQuiet(S: SimState, ex) -> void:\n" +
   T + "ex.tpl = TPL\n" +
   T + "ex.branch = \"\"\n" +
   T + "ex.tag = \"ZIP\"\n" +
   T + "ex.loser = -1\n" +
   T + "for f in [ex.A, ex.D]:\n" +
   T + T + "_size(f)\n" +
   T + T + "for k in range(BASE, END):\n" +
   T + T + T + "f.act.dirI[k] = 0\n" +
   T + T + "SimAct.clear(f)\n" +
   T + T + "f.vx = 0.0\n" +
   T + T + "f.vy = 0.0\n" +
   T + T + "_s(f, LAST_AT, S.tick)\n" +
   "\n\n" +
   "## The zipper was caught or countered (DirZip): the brawl is announced now, with `starter` as the fighter who began it.\n" +
   "static func announce(S: SimState, ex, starter, why: String) -> void:\n" +
   T + "ex.tag = \"BRAWL\"\n" +
   T + "var e = _ev(S, starter, \"brawl_start\", why)\n" +
   T + "e.target = float(S.fighters.find(ex.D if starter == ex.A else ex.A))\n" +
   T + "e.n = ex.n\n" +
   T + "e.amount = DirBands.dist(ex.A, ex.D)\n" +
   T + "SimEvents.feed(S, \"BRAWL\", ex.A.name + \" and \" + ex.D.name + \" in reach: every press is a blow\")\n" +
   "\n\n" +
   "## A blow put on f's line by rule and not by a press (a zip's blow; the heavy a rival pressed before the zipper\n" +
   "## arrived): it lands `lead` live ticks from now, worth dmg. extra's keys go on the beat (zip, style, counter, sure,\n" +
   "## ender). A sure blow can't be blocked.\n" +
   "static func blowAt(S: SimState, ex, f, kind: int, lead: int, dmg: float, extra: Dictionary) -> void:\n" +
   T + "var c: Dictionary = cfg()\n" +
   T + "var o = ex.D if f == ex.A else ex.A\n" +
   T + "var role: String = \"A\" if f == ex.A else \"D\"\n" +
   T + "var weight: int = SimAct.HEAVY if kind == HEAVY else SimAct.LIGHT\n" +
   T + "DirInterrupt.si(f, DirInterrupt.PHRASE_P, weight)\n" +
   T + "if _g(f, STR_ON) == 0:\n" +
   T + T + "_s(f, STR_ON, 1)\n" +
   T + T + "_s(f, STR_K, 0)\n" +
   T + T + "_s(f, STRING_N, 0)\n" +
   T + T + "DirInterrupt.si(f, DirInterrupt.LANDED, 0)\n" +
   T + "var k: int = _g(f, STR_K) + 1\n" +
   T + "_s(f, STR_K, k)\n" +
   T + "var o2 := {\"class\": \"heavy\" if kind == HEAVY else \"blow\", \"stop\": float(int(c.hitstop.heavy if kind == HEAVY else c.hitstop.light)) / DirData.TICKS_PER_SEC, \"big\": kind == HEAVY, \"kb\": float(c.recoil)}\n" +
   T + "if bool(extra.get(\"sure\", false)):\n" +
   T + T + "o2[\"ignoreStance\"] = true\n" +
   T + T + "o2[\"noParry\"] = true\n" +
   T + T + "o2[\"weighed\"] = true\n" +
   T + "var args := {\"a\": role, \"d\": \"D\" if role == \"A\" else \"A\", \"dmg\": dmg, \"o\": o2, \"brawl\": true, \"bk\": kind,\n" +
   T + T + "\"style\": \"heavy\" if kind == HEAVY else \"speed\", \"grade\": \"none\", \"k\": k, \"n\": k, \"closing\": false, \"charge\": 0.0,\n" +
   T + T + "\"hand\": \"r\" if (k % 2) == 1 else \"l\", \"ender\": false}\n" +
   T + "for key in extra:\n" +
   T + T + "args[key] = extra[key]\n" +
   T + "var piece: String = _piece(S, f, weight, false, bool(args.ender))\n" +
   T + "if piece != \"\":\n" +
   T + T + "args[\"piece\"] = piece\n" +
   T + "DirExchange.schedule(ex, ex.t + (float(lead + (0 if _inTick else 1)) - 0.25) / DirData.TICKS_PER_SEC, \"strike\", args)\n" +
   T + "_s(f, LINE, 1)\n" +
   T + "_s(f, KIND, kind)\n" +
   T + "_s(f, CONTACT, _now(S) + lead)\n" +
   T + "_s(f, HOLD_AT, 0)\n" +
   T + "_s(f, FREE_AT, S.tick + (1 << 20) if kind == HEAVY else S.tick + lead + 1)\n" +
   T + "_s(f, LAND_AT, S.tick)\n" +
   T + "_s(f, HELD_P, 0)\n" +
   T + "_s(f, BLOWS, _g(f, BLOWS) + 1)\n" +
   T + "var e = _ev(S, f, \"blow\", KINDS[kind])\n" +
   T + "e.target = float(S.fighters.find(o))\n" +
   T + "e.n = S.tick + lead\n" +
   T + "e.amount = float(S.tick)\n" +
   T + "e.dur = float(lead)\n" +
   "\n\n" +
   "## The brawl is over, and why:",
   "static func beginQuiet("],
  // a rival's press in a zip's ticks in reach may be the tech counter
  [T + "var piece: String = _piece(S, f, weight, ((pp >> 2) & 3) == 2, ender)\n",
   T + "if quiet(ex) and f == ex.D:\n" +
   T + T + "DirZip.markAnswer(S, ex, f, kind, p, args)\n" +
   T + "var piece: String = _piece(S, f, weight, ((pp >> 2) & 3) == 2, ender)\n",
   "DirZip.markAnswer(S, ex, f, kind, p, args)"],
  // contact: the tech reading by a second press is read as his blow lands
  [T + "var landed0: int = DirInterrupt.gi(f, DirInterrupt.LANDED)\n",
   T + "if bool(a.get(\"zip\", false)):\n" + T + T + "DirZip.beforeBlow(S, ex, f, a)\n" + T + "var landed0: int = DirInterrupt.gi(f, DirInterrupt.LANDED)\n",
   "DirZip.beforeBlow(S, ex, f, a)"],
  // contact: a zipper has no guard; his blow's outcome; a blow that lands on him
  [T + "ex.sA = ex.A.stance\n" + T + "ex.sD = ex.D.stance\n",
   T + "ex.sA = 0.0 if quiet(ex) else ex.A.stance   # a zipper has no guard in reach\n" + T + "ex.sD = ex.D.stance\n"],
  [T + "if bool(a.o.get(\"turned\", false)):\n" + T + T + "return   # a perfect block turned it (section 9f): he staggers in place and the brawl goes on\n",
   T + "if bool(a.o.get(\"turned\", false)):\n" +
   T + T + "if bool(a.get(\"zip\", false)):\n" +
   T + T + T + "DirZip.onBlow(S, ex, f, o, a, 2)   # a zip's blow turned: he is countered\n" +
   T + T + "return   # a perfect block turned it (section 9f): he staggers in place and the brawl goes on\n" +
   T + "if bool(a.get(\"zip\", false)):\n" +
   T + T + "# A zip's one blow: its reading's reel or stagger, and the exit is read (DirZip.onBlow). No run, no close.\n" +
   T + T + "var hit: bool = DirInterrupt.gi(f, DirInterrupt.LANDED) != landed0\n" +
   T + T + "if hit:\n" +
   T + T + T + "_s(f, STRING_N, _g(f, STRING_N) + 1)\n" +
   T + T + "if not _setPiece(ex):\n" +
   T + T + T + "DirZip.onBlow(S, ex, f, o, a, 1 if hit else 0)\n" +
   T + T + "else:\n" +
   T + T + T + "over(S, ex, \"break\")\n" +
   T + T + "return\n" +
   T + "if quiet(ex) and f == ex.D and DirInterrupt.gi(f, DirInterrupt.LANDED) != landed0:\n" +
   T + T + "DirZip.onHit(S, ex, o, f, a)   # a blow landed on a zipper in reach: he is caught, or countered\n",
   "# a zip's blow turned: he is countered"],
  // the AI: a zipper in reach does nothing more
  [T + "f.ai.st = 0.0\n" + T + "if ex.branch != \"\" or ex.cancel or f.stunTicks > 0:\n" + T + T + "return\n",
   T + "f.ai.st = 0.0\n" + T + "if ex.branch != \"\" or ex.cancel or f.stunTicks > 0:\n" + T + T + "return\n" +
   T + "if quiet(ex):\n" + T + T + "if f == ex.D:\n" + T + T + T + "DirZip.aiReach(S, ex, f, i)   # the rival of a zipper in reach: its guard, its answer, its punish\n" + T + T + "return   # a zipper in reach: his one blow is on its way\n",
   "return   # a zipper in reach: his one blow is on its way"],
]);

// ------------------------------------------------------------------ sim/director/ai.gd
edit("sim/director/ai.gd", [
  [T + T + "DirBrawl.aiInput(S, f)   # in a brawl it chooses at its beats, not on the stance timer\n" + T + T + "return\n",
   T + T + "DirBrawl.aiInput(S, f)   # in a brawl it chooses at its beats, not on the stance timer\n" + T + T + "return\n" +
   T + "if DirZip.zipping(f):\n" + T + T + "DirZip.aiZipping(S, f, i)   # its own zip: LT stays down, and the stick is its exit\n" + T + T + "return\n",
   "DirZip.aiZipping(S, f, i)"],
  [T + "elif ans == DirBands.R_HEAVY:\n" + T + T + "i.heavy = true\n",
   T + "elif ans == DirBands.R_HEAVY:\n" + T + T + "i.heavy = true\n" +
   T + "# A zip is coming (DirZip): the answer the AI drew when it saw the tell.\n" +
   T + "var za: int = DirZip.aiAnswer(S, f, o) if f.state == \"free\" else 0\n" +
   T + "if za == 1:\n" + T + T + "a.st = 1.0\n" +
   T + "elif za == 2:\n" + T + T + "a.st = 2.0\n" +
   T + "elif za == 3:\n" + T + T + "i.light = true\n" +
   T + "elif za == 4:\n" + T + T + "i.heavy = true\n",
   "var za: int = DirZip.aiAnswer(S, f, o)"],
  [T + T + T + "if vsHeavy:\n" + T + T + T + T + "i.heavy = true\n" + T + T + T + T + "i.light = false\n" + T + T + T + T + "i.mode = 0\n",
   T + T + T + "if vsHeavy:\n" + T + T + T + T + "i.heavy = true\n" + T + T + T + T + "i.light = false\n" + T + T + T + T + "i.mode = 0\n" +
   T + T + T + "# In the mid band it zips at its level's rate (DirZip.aiUse): LT with X or Y, as a player presses it.\n" +
   T + T + T + "if not vsHeavy and (i.light or i.heavy) and DirBands.band(f, o) == DirBands.MID and not DirBands.taunting(o):\n" +
   T + T + T + T + "DirZip.aiUse(S, f, o, i)\n",
   "DirZip.aiUse(S, f, o, i)"],
]);
edit("data/director/ai.json", [
  // the masher against medium read 51 of 100 on the retune base with the AI zipping (49 without); 0.3 reads 45
  ["\"enderShare\": 0.4, \"rashHeavy\": 0.33,", "\"enderShare\": 0.4, \"rashHeavy\": 0.3,"],
  ["\"vsShooter\": {\"guardShare\": 0, \"enderShare\": 0.5, \"heavyApproachShare\": 0.05},\n", "\"vsShooter\": {\"guardShare\": 0, \"enderShare\": 0.5, \"heavyApproachShare\": 0.05},\n      \"zipShare\": 0.08, \"zipHeavyShare\": 0.2, \"zipCounter\": 0, \"zipDodge\": 0, \"zipPunish\": 0.2, \"zipExit\": 0,\n"],
  ["\"vsShooter\": {\"guardShare\": 0, \"enderShare\": 0.45, \"heavyApproachShare\": 0.1},\n", "\"vsShooter\": {\"guardShare\": 0, \"enderShare\": 0.45, \"heavyApproachShare\": 0.1},\n      \"zipShare\": 0.25, \"zipHeavyShare\": 0.3, \"zipCounter\": 0.2, \"zipDodge\": 0.1, \"zipPunish\": 0.75, \"zipExit\": 0.3,\n"],
  ["\"vsShooter\": {\"guardShare\": 0, \"enderShare\": 0.3, \"heavyApproachShare\": 0.3},\n", "\"vsShooter\": {\"guardShare\": 0, \"enderShare\": 0.3, \"heavyApproachShare\": 0.3},\n      \"zipShare\": 0.4, \"zipHeavyShare\": 0.35, \"zipCounter\": 0.35, \"zipDodge\": 0.15, \"zipPunish\": 0.95, \"zipExit\": 0.6,\n"],
]);

// ------------------------------------------------------------------ sim/director/blast.gd
edit("sim/director/blast.gd", [
  [T + T + T + "outcome = \"stop\"\n" + T + "var brink0: bool = f.brink\n",
   T + T + T + "outcome = \"stop\"\n" +
   T + "# A zipper (DirZip.shot): on the way in a zip strike is stopped and a zip heavy shrugs off a weak shot; on the way\n" +
   T + "# out a shot drops him.\n" +
   T + "var zo: String = DirZip.shot(S, f, sh)\n" +
   T + "if zo == \"shrug\":\n" +
   T + T + "dmg *= float(c.charge.shrugMul)\n" +
   T + T + "outcome = \"shrug\"\n" +
   T + "elif zo == \"stop\":\n" +
   T + T + "outcome = \"stop\"\n" +
   T + "var brink0: bool = f.brink\n",
   "var zo: String = DirZip.shot(S, f, sh)"],
]);

// ------------------------------------------------------------------ sim/director/tools/brawl_probe.gd
edit("sim/director/tools/brawl_probe.gd", [
  [T + T + T + T + T + "elif ai.rush != null or me.rush != null:\n",
   T + T + T + T + T + "elif ai.rush != null or me.rush != null or DirZip.zipping(ai) or DirZip.zipping(me):   # a zip, from its tell, is an attack on its way\n"],
]);

// ------------------------------------------------------------------ data
{
  const p = path.join(root, "data/director/interrupts.json");
  const j = JSON.parse(fs.readFileSync(p, "utf8"));
  if (!j.zip) {
    j.zip = {
      enabled: true,
      band: { minBh: 3, maxBh: 12.5 },
      strike: { ki: 20, tellTicks: 6, inTicks: [6, 8], reachBefore: 4, reachAfter: 6, outTicks: 10, heldTicks: 12, heldReachBefore: 8 },
      heavy: { ki: 30, tellTicks: 10, inTicks: [8, 10], reachBefore: 12, reachAfter: 10, outTicks: 12, heldTicks: 20 },
      floor: { minTicks: 4, bhPerTick: 3 },
      out: { freeBh: 8, bhPerTick: 2, maxTicks: 20 },
      exit: { awayBh: 6, capBh: 12.5, slideDeg: 15, probes: 24, clearBh: 1 },
      towardDeg: 45, awayDeg: 45, bowBh: 2, exitSteps: 16, knockdownTicks: 24,
      mul: { speed: 1, tech: 1.25, held: 1.25 },
      reel: { speed: 4, tech: 8, held: 12 },
      stagger: { speed: 12, tech: 20 },
      counter: { techBefore: 4, heavyBefore: 6, staggerTicks: 12, mul: 1.25 },
      dodgeConvertTicks: 8,
      _note: "The zip, slice Z1 (sim/director/zip.gd; docs/design/melee-press-feel.md section 2c). LT with X (strike) or Y (heavy) in band: ki paid at the press; tellTicks of tell; inTicks (the range by distance) on the way in; reachBefore ticks in reach before his blow and reachAfter after it; outTicks on the way out, plus 1 for each out.bhPerTick body heights of path past out.freeBh, out.maxTicks at most. heldTicks: the button kept down this long past the tell is the held reading (a zip strike is then in reach heldReachBefore ticks before its blow). floor: no way in or out is under max(minTicks, the distance in bh over bhPerTick, rounded up) (Legal RL-076). exit: awayBh more with the stick straight away, capBh at most from the rival; a blocked point slides slideDeg at a time, probes at most, to a point clear by clearBh. bowBh: the bow of a way out that passes the rival (over him; under him with the stick down and room beneath) or clears the ground. towardDeg, awayDeg, exitSteps: Game Design's stick rules. mul, reel (a zip strike) and stagger (a zip heavy) by reading. counter: a tech strike pressed from techBefore ticks before the arrival, or a heavy landing from heavyBefore ticks before it, until his blow lands, cancels the blow; a tech counter staggers him staggerTicks and is worth a skill strike times mul. knockdownTicks: the drop when a shot hits him on the way out. dodgeConvertTicks: a face press this soon after LT's press takes the dodge back."
    };
  }
  fs.writeFileSync(p, JSON.stringify(j, null, 2) + "\n");
  console.log("data/director/interrupts.json: written");
}
