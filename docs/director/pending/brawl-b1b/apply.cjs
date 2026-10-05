// Brawl slice B1b: Game Design's rulings 3, 4 and 5 on the first brawl build (docs/design/melee-press-feel.md section 9d).
// node apply.cjs <repo root>. Idempotent. It goes on top of slice B1 (5a0d527).
//  3. The even mash. A blow landed on a staggered fighter adds nothing to the run. At the trade's limit a lead of more
//     than levelWithin takes the close; runs within it are a level trade, settled by a seeded draw in which the last
//     closer of this brawl has `momentum` (even odds when nobody has closed yet). The close counts 0.34 of a set-up.
//  4. The AI until B2: tap gaps 12, 8 and 6; its answer to a close that landed on it is a heavy as its stagger ends, at
//     its level's heavyAfterClose.
//  5. The shooter. A heavy shot is worth the kind's damage times the brawl's scale times shotHeavyMul; bolts keep their
//     value. Against a shooter (he fired lately and has landed no melee blow) the AI takes its level's vsShooter
//     numbers: it does not guard in the brawl, rarely throws the ender that would knock him away, and comes in with
//     the heavy lunge or the heavy charge.
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

function json(rel, fn) {
  const f = path.join(root, rel);
  const raw = fs.readFileSync(f, "utf8");
  const crlf = raw.includes("\r\n");
  const j = JSON.parse(raw);
  fn(j);
  let out = JSON.stringify(j, null, 2) + "\n";
  if (crlf) out = out.split("\n").join("\r\n");
  fs.writeFileSync(f, out);
  console.log(rel + ": written");
}

fs.copyFileSync(path.join(__dirname, "brawl_probe.gd"), path.join(root, "sim/director/tools/brawl_probe.gd"));
console.log("sim/director/tools/brawl_probe.gd: written");

// ---------------------------------------------------------------- the brawl
edit("sim/director/brawl.gd", [
  // the header
  ["##    run of runToClose his next landed light staggers the rival in place: decisive, at half a set-up. A trade (both\n" +
   "##    landing inside the lapse) cannot pass tradeMaxTicks: at the limit it breaks for the higher run, then the more\n" +
   "##    blows landed in it, then a seeded draw, and that fighter's next landed blow is the close.\n",
   "##    run of runToClose his next landed light staggers the rival in place: decisive, at half a set-up. A blow on a\n" +
   "##    staggered fighter adds nothing to the run. A trade (both landing inside the lapse) cannot pass tradeMaxTicks:\n" +
   "##    at the limit it breaks for a lead of more than levelWithin, and a level trade is a seeded draw in which the\n" +
   "##    last closer of this brawl has `momentum` (section 9d); that fighter's next landed blow is the close.\n"],
  // state
  ["const TRADE_N: int = BASE + 29  # light and flurry blows he has landed in the running trade\n",
   "const AI_AFTER: int = BASE + 29 # the AI: 1 when a close has landed on it and its answer, a heavy as its stagger ends, is still to weigh\n"],
  ["const END: int = BASE + 32\n",
   "const LAST_CLOSER: int = BASE + 32 # on the exchange's attacker, for both: who made the last close in this brawl, 1 the attacker, 2 the other; 0 nobody yet\n" +
   "const SAFE_UNTIL: int = BASE + 33 # S.tick until which he cannot be closed on again (closeGuardTicks after he recovers from a close); -1 while that close's stagger lasts\n" +
   "const END: int = BASE + 34\n"],
  // a close cannot repeat on a fighter for closeGuardTicks after he recovers from one
  ["## True when f's next light or flurry blow that lands is the close: his run is at runToClose, or a trade that reached\n" +
   "## its limit broke his way.\n" +
   "static func _closes(ex, f) -> bool:\n" +
   L(1, "return _g(f, RUN) >= int(cfg().flurry.runToClose) or _g(ex.A, TRADE_WIN) == (1 if f == ex.A else 2)"),
   "## True when f's next light or flurry blow that lands is the close: his run is at runToClose, or a trade that reached\n" +
   "## its limit broke his way. Never while the rival is still in a close's stagger, or inside closeGuardTicks of his\n" +
   "## recovery from it (section 9d): f's run still counts then, and a run of runToClose closes on his first blow after it.\n" +
   "static func _closes(S: SimState, ex, f) -> bool:\n" +
   L(1, "var o = ex.D if f == ex.A else ex.A") +
   L(1, "if _g(o, SAFE_UNTIL) < 0 or S.tick < _g(o, SAFE_UNTIL):") +
   L(2, "return false") +
   L(1, "return _g(f, RUN) >= int(cfg().flurry.runToClose) or _g(ex.A, TRADE_WIN) == (1 if f == ex.A else 2)")],
  ["\"closing\": kind != HEAVY and _closes(ex, f),", "\"closing\": kind != HEAVY and _closes(S, ex, f),"],
  [L(1, "var closing: bool = _closes(ex, f)"), L(1, "var closing: bool = _closes(S, ex, f)")],
  [L(2, "if not SimAct.peek(f).is_empty():") + L(3, "SimAct.clear(f)"),
   L(2, "if not SimAct.peek(f).is_empty():") + L(3, "SimAct.clear(f)") +
   L(2, "if _g(f, SAFE_UNTIL) < 0 and f.stunTicks <= 0:") +
   L(3, "_s(f, SAFE_UNTIL, S.tick + int(c.flurry.closeGuardTicks))   # he has recovered from a close: he cannot be closed on again for this long")],
  // the trade
  [L(1, "_s(ex.A, TRADE_WIN, 0)") + L(1, "_s(ex.A, TRADE_N, 0)") + L(1, "_s(ex.D, TRADE_N, 0)") + "\n\n## Once a live tick: a run lapses",
   L(1, "_s(ex.A, TRADE_WIN, 0)") + "\n\n## Once a live tick: a run lapses"],
  ["## light or a flurry blow inside that time; it cannot pass tradeMaxTicks without a close. At the limit it breaks for\n" +
   "## the fighter with the higher run, then the one who has landed more blows in this trade, then a seeded draw at even\n" +
   "## odds: his next landed blow is the close.\n",
   "## light or a flurry blow inside that time; it cannot pass tradeMaxTicks without a close. At the limit it breaks, on\n" +
   "## the first live tick at or after it (a hit-stop holds the sim, and so the break): a lead of more than levelWithin\n" +
   "## takes the close, and runs within it are a level trade, settled by a seeded draw in which the fighter who made the\n" +
   "## last close in this brawl has `momentum`; when nobody has closed yet the odds are even (melee-press-feel.md section\n" +
   "## 9d, ruling 3). His next landed blow is the close.\n"],
  [L(1, "var w: int = 0") +
   L(1, "if _g(ex.A, RUN) != _g(ex.D, RUN):") +
   L(2, "w = 1 if _g(ex.A, RUN) > _g(ex.D, RUN) else 2") +
   L(1, "elif _g(ex.A, TRADE_N) != _g(ex.D, TRADE_N):") +
   L(2, "w = 1 if _g(ex.A, TRADE_N) > _g(ex.D, TRADE_N) else 2") +
   L(1, "else:") +
   L(2, "w = 1 if SimRng.keyed(int(S.game.seed), \"brawl.trade\", S.dirS.exN * 4096 + (_g(ex.A, TRADE_T0) & 4095)) < 0.5 else 2"),
   L(1, "var w: int = 0") +
   L(1, "var last: int = _g(ex.A, LAST_CLOSER)") +
   L(1, "var how: String = \"lead\"") +
   L(1, "if absi(_g(ex.A, RUN) - _g(ex.D, RUN)) > int(fl.levelWithin):") +
   L(2, "w = 1 if _g(ex.A, RUN) > _g(ex.D, RUN) else 2") +
   L(1, "else:") +
   L(2, "how = \"draw\"") +
   L(2, "var pA: float = 0.5 if last == 0 else (float(fl.momentum) if last == 1 else 1.0 - float(fl.momentum))") +
   L(2, "w = 1 if SimRng.keyed(int(S.game.seed), \"brawl.trade\", S.dirS.exN * 4096 + (_g(ex.A, TRADE_T0) & 4095)) < pA else 2")],
  [L(1, "e.n = S.tick - _g(ex.A, TRADE_T0)") +
   "\tSimEvents.feed(S, \"THE TRADE BREAKS\",",
   L(1, "e.n = S.tick - _g(ex.A, TRADE_T0)") +
   L(1, "# For QA: the limit; the two runs at the break, his and the rival's; how it was settled (lead or draw); and who made") +
   L(1, "# the last close in this brawl (0 nobody yet, 1 he did, 2 the rival did: a draw with 2 is momentum changing hands).") +
   L(1, "e.amount = float(int(fl.tradeMaxTicks))") +
   L(1, "e.x = float(_g(who, RUN))") +
   L(1, "e.y = float(_g(ex.D if w == 1 else ex.A, RUN))") +
   L(1, "e.text = how") +
   L(1, "e.k = 0.0 if last == 0 else (1.0 if last == w else 2.0)") +
   "\tSimEvents.feed(S, \"THE TRADE BREAKS\","],
  // a blow lands
  [L(1, "_s(f, LL_AT, S.tick)") +
   L(1, "_s(f, TRADE_N, _g(f, TRADE_N) + 1)") +
   L(1, "if not closing:") +
   L(2, "_s(f, RUN, _g(f, RUN) + 1)"),
   L(1, "_s(f, LL_AT, S.tick)") +
   L(1, "if not closing:") +
   L(2, "if o.stunTicks <= 0 or bool(c.flurry.staggeredAddsRun):") +
   L(3, "_s(f, RUN, _g(f, RUN) + 1)   # a blow on a staggered fighter does its damage and adds nothing to the run: a close does not start the next lead")],
  [L(1, "_s(f, RUN, 0)") +
   L(1, "_s(o, RUN, 0)") +
   L(1, "_tradeReset(ex)") +
   L(1, "o.stunTicks = maxi(o.stunTicks, int(c.flurry.staggerTicks))"),
   L(1, "_s(f, RUN, 0)") +
   L(1, "_s(o, RUN, 0)") +
   L(1, "_tradeReset(ex)") +
   L(1, "_s(ex.A, LAST_CLOSER, 1 if f == ex.A else 2)   # the momentum of a level trade is his") +
   L(1, "_s(o, SAFE_UNTIL, -1)   # no second close on him until closeGuardTicks after he recovers from this one") +
   L(1, "if o.ai != null:") +
   L(2, "_s(o, AI_AFTER, 1)   # its answer to being closed on: a heavy as its stagger ends, at its level's rate") +
   L(1, "o.stunTicks = maxi(o.stunTicks, int(c.flurry.staggerTicks))")],
  // a shooter, and what a heavy shot is worth
  ["## The AI's reversal in a brawl (DirInterrupt.onBlock): it weighs one on a block at most once in aiReversalEveryTicks.\n",
   "## True when o is a shooter to f (melee-press-feel.md section 9d, ruling 5): he has fired in the last\n" +
   "## shooter.firedTicks and has landed no melee blow on f in the last shooter.noMeleeTicks.\n" +
   "static func shooter(S: SimState, f, o) -> bool:\n" +
   L(1, "var sh: Dictionary = cfg().get(\"shooter\", {})") +
   L(1, "if sh.is_empty() or not on() or not DirBlast.on():") +
   L(2, "return false") +
   L(1, "return S.tick - DirInterrupt.gi(o, DirInterrupt.BLAST_AT) <= int(sh.firedTicks) and S.tick - DirInterrupt.gi(f, DirInterrupt.HIT_AT) > int(sh.noMeleeTicks)") +
   "\n\n" +
   "## What a heavy shot is worth while the brawl is on (ruling 5): its kind's damage times the brawl's scale times\n" +
   "## shotHeavyMul, as a heavy blow is. DirBlast multiplies by this where it reads the kind's damage. Bolts keep their value.\n" +
   "static func shotScale() -> float:\n" +
   L(1, "return float(cfg().damageMul) * float(cfg().shotHeavyMul) if (on() and cfg().has(\"shotHeavyMul\")) else 1.0") +
   "\n\n" +
   "## The AI's reversal in a brawl (DirInterrupt.onBlock): it weighs one on a block at most once in aiReversalEveryTicks.\n"],
  // the AI
  ["## It writes real presses and holds, as a player does. It does not leave a brawl (B5).\n",
   "## A close that landed on it is answered with a heavy as its stagger ends, at heavyAfterClose. Against a shooter it\n" +
   "## takes its level's vsShooter numbers: no guard, and seldom the ender that would knock him back to his range.\n" +
   "## It writes real presses and holds, as a player does. It does not leave a brawl (B5).\n"],
  [L(1, "if _now(S) < _g(f, AI_HOLD):") +
   L(2, "i.heavyHeld = true"),
   L(1, "if _now(S) < _g(f, AI_HOLD):") +
   L(2, "i.heavyHeld = true") +
   L(1, "# Its answer to being closed on (section 9d, ruling 4): a heavy as its stagger ends, at its level's heavyAfterClose.") +
   L(1, "# The closer's blows on it while it staggered added nothing to his run, so his fresh run has to race the wind-up.") +
   L(1, "if _g(f, AI_AFTER) == 1:") +
   L(2, "_s(f, AI_AFTER, 0)") +
   L(2, "if _g(f, LINE) == 0 and S.rng.next() < float(bl.get(\"heavyAfterClose\", 0.0)):") +
   L(3, "_s(f, AI_GUARD, 0)") +
   L(3, "_s(f, AI_LEFT, 0)") +
   L(3, "_s(f, AI_CLOSE, 0)") +
   L(3, "_aiHeavy(S, f, lv, false)") +
   L(3, "return") +
   L(1, "# Against a shooter (ruling 5) its guard share and its ender share are its level's vsShooter numbers.") +
   L(1, "var vs: Dictionary = lv.get(\"vsShooter\", {}) if shooter(S, f, o) else {}")],
  ["and S.rng.next() < float(bl.get(\"enderShare\", 0.5)):\n" + L(3, "_aiHeavy(S, f, lv)"),
   "and S.rng.next() < float(vs.get(\"enderShare\", bl.get(\"enderShare\", 0.5))):\n" + L(3, "_aiHeavy(S, f, lv, true)")],
  [L(1, "if o.stance == 1.0 and S.rng.next() < float(lv.get(\"breakGuard\", 0.0)):") + L(2, "_aiHeavy(S, f, lv)"),
   L(1, "if o.stance == 1.0 and S.rng.next() < float(lv.get(\"breakGuard\", 0.0)):") + L(2, "_aiHeavy(S, f, lv, true)")],
  [L(1, "if left == 0 and S.rng.next() < float(bl.get(\"guardShare\", 0.3)):"),
   L(1, "if left == 0 and S.rng.next() < float(vs.get(\"guardShare\", bl.get(\"guardShare\", 0.3))):")],
  ["## Its heavy: tapped, or held to the full charge at its level's rate.\n" +
   "static func _aiHeavy(S: SimState, f, lv: Dictionary) -> void:\n",
   "## Its heavy: tapped, or (hold) held to the full charge at its level's rate.\n" +
   "static func _aiHeavy(S: SimState, f, lv: Dictionary, hold: bool) -> void:\n"],
  [L(1, "if S.rng.next() < float(lv.get(\"heldHeavy\", 0.0)) * float(lv.get(\"earnerUse\", 1.0)):") +
   L(2, "_s(f, AI_HOLD, _now(S) + int(c.heavy.heldFullTicks) + 1)"),
   L(1, "if hold and S.rng.next() < float(lv.get(\"heldHeavy\", 0.0)) * float(lv.get(\"earnerUse\", 1.0)):") +
   L(2, "_s(f, AI_HOLD, _now(S) + int(c.heavy.heldFullTicks) + 1)")],
]);

// ---------------------------------------------------------------- a heavy shot's worth
edit("sim/director/blast.gd", [
  ["o2[\"dmg\"] = float(SimShots.kinds[kind].dmg) * (float(w.tapShare) + (1.0 - float(w.tapShare)) * charge)",
   "o2[\"dmg\"] = float(SimShots.kinds[kind].dmg) * DirBrawl.shotScale() * (float(w.tapShare) + (1.0 - float(w.tapShare)) * charge)   # a heavy shot takes a heavy blow's worth (melee-press-feel.md 9d)"],
  ["sh.dmg <= float(SimShots.kinds[sh.kind].dmg) * float(data().heavy.tapShare) + 0.001",
   "sh.dmg <= float(SimShots.kinds[sh.kind].dmg) * DirBrawl.shotScale() * float(data().heavy.tapShare) + 0.001"],
  ["sh.dmg < float(SimShots.kinds[sh.kind].dmg) - 0.001:",
   "sh.dmg < float(SimShots.kinds[sh.kind].dmg) * DirBrawl.shotScale() - 0.001:"],
]);

// ---------------------------------------------------------------- the AI's approach to a shooter
edit("sim/director/ai.gd", [
  [L(4, "i.mode = 1   # it fires instead: a volley of bolts for a light, a charged shot for a heavy (DirBlast)") +
   "\t\t\tif (i.light or i.heavy) and DirBlast.minesOn()",
   L(4, "i.mode = 1   # it fires instead: a volley of bolts for a light, a charged shot for a heavy (DirBlast)") +
   L(3, "# Against a shooter (DirBrawl.shooter) it comes in with the approach a bolt does not stop, at its level's rate: the") +
   L(3, "# heavy lunge from the mid band, the heavy charge from the far band.") +
   L(3, "var vsHeavy: bool = (i.light or i.heavy) and DirBands.band(f, o) != DirBands.CLOSE and not DirBands.taunting(o) and DirBrawl.shooter(S, f, o) and S.rng.next() < float(lv().get(\"vsShooter\", {}).get(\"heavyApproachShare\", 0.0))") +
   L(3, "if vsHeavy:") +
   L(4, "i.heavy = true") +
   L(4, "i.light = false") +
   L(4, "i.mode = 0") +
   "\t\t\tif not vsHeavy and (i.light or i.heavy) and DirBlast.minesOn()"],
  [L(4, "var ft: float = float(lv().get(\"farTaunt\", 0.0)) if not DirBands.tauntSpent(f) else 0.0"),
   L(4, "var ft: float = float(lv().get(\"farTaunt\", 0.0)) if (not DirBands.tauntSpent(f) and not vsHeavy) else 0.0")],
  [L(5, "if i.heavy and S.rng.next() >= float(lv().get(\"farHeavy\", 1.0)) * float(lv().get(\"earnerUse\", 1.0)):   # a heavy charge is an earner too"),
   L(5, "if i.heavy and not vsHeavy and S.rng.next() >= float(lv().get(\"farHeavy\", 1.0)) * float(lv().get(\"earnerUse\", 1.0)):   # a heavy charge is an earner too")],
]);

// ---------------------------------------------------------------- data
json("data/director/interrupts.json", (j) => {
  const b = j.brawl, fl = b.flurry;
  delete fl.closeAfter;
  fl.staggeredAddsRun = false;
  fl.levelWithin = 1;
  fl.momentum = 0.9;
  fl.closeGuardTicks = 90;
  b.damageMul = 0.38;   // Game Design's lever for match length: at 0.30 main's median read 503 to 526 s once blocked lights wore the arms half; with the AI firing more often 0.36 read 474.6 s on the default arm, at the top of the band
  b.shotHeavyMul = 2;
  b.shooter = { firedTicks: 90, noMeleeTicks: 120 };
  const a = "at the limit it breaks for the higher run, then the more blows landed in the trade, then a seeded draw at even odds, and that fighter's next landed blow is the close. closeAfter is the first build's name for runToClose: it is not read, and stays only until the schema lets it go.";
  const z = "at the limit it breaks, and that fighter's next landed blow is the close. Who it breaks for (section 9d): a lead of more than levelWithin takes it, and runs within levelWithin are a level trade settled by a seeded draw in which the fighter who made the last close in this brawl has `momentum` (even odds when nobody has closed yet). staggeredAddsRun: whether a blow landed on a staggered fighter adds to the run (false: a close does not start the next lead). closeGuardTicks: a fighter cannot be closed on again for this long after he recovers from a close; the rival's run still counts, and a run of runToClose closes on his first blow after it.";
  if (!b._note.includes(z)) {
    if (!b._note.includes(a)) throw new Error("interrupts.json: the brawl note's trade sentence was not found");
    b._note = b._note.replace(a, () => z);
  }
  const s2 = " shotHeavyMul: a heavy shot is worth its kind's damage times damageMul times this, as a heavy blow is (bolts keep their value). shooter: to the AI a rival is a shooter when he has fired in the last firedTicks and has landed no melee blow on it in the last noMeleeTicks; it then takes its level's vsShooter numbers (ai.json).";
  if (!b._note.includes("shotHeavyMul:")) b._note += "." + s2.replace(/\.$/, "");
});
edit("data/director/launch.json", [
  ['"blurPlain": 0.25', '"blurPlain": 0.34'],
  ["a quarter of one, so a masher needs four (melee-press-feel.md section 3: the second lever for the lights-only brink, after brawl.flurry.tradeMaxTicks)",
   "about a third of one, so a masher needs three (melee-press-feel.md section 9d: it was a quarter while one fighter made nearly every close; with the momentum rule Game Design's range for it is 0.34 to 0.5, and it sits at the bottom of that because the lights-only mirror's brink to KO reads 26.9 s at 0.5 and 28.2 s at 0.34, against 30 to 55 s; brawl.flurry.momentum does not move that row)"],
]);
// ai.json keeps its own layout, so its edits are text. Each level's brawl block is replaced whole, and vsShooter follows it.
const AI = {
  easy: ['{"tapGap": 12, "string": [2, 4], "enderShare": 0.3, "rashHeavy": 1.0, "guardShare": 0.2, "guardTicks": [20, 60], "perfectMul": 0.3}',
         '{"tapGap": 12, "string": [2, 4], "enderShare": 0.3, "rashHeavy": 1.0, "guardShare": 0.2, "guardTicks": [20, 60], "perfectMul": 0.3, "heavyAfterClose": 0.2}',
         '{"guardShare": 0, "enderShare": 0.5, "heavyApproachShare": 0.05}'],
  medium: ['{"tapGap": 10, "string": [3, 5], "enderShare": 0.45, "rashHeavy": 0.58, "guardShare": 0.4, "guardTicks": [20, 60], "perfectMul": 0.15}',
           '{"tapGap": 8, "string": [3, 5], "enderShare": 0.45, "rashHeavy": 0.33, "guardShare": 0.4, "guardTicks": [20, 60], "perfectMul": 0.15, "heavyAfterClose": 0.6}',
           '{"guardShare": 0, "enderShare": 0.45, "heavyApproachShare": 0.1}'],
  hard: ['{"tapGap": 7, "string": [3, 5], "enderShare": 0.6, "rashHeavy": 0.1, "guardShare": 0.4, "guardTicks": [20, 60], "perfectMul": 0.5}',
         '{"tapGap": 6, "string": [3, 5], "enderShare": 0.6, "rashHeavy": 0.1, "guardShare": 0.4, "guardTicks": [20, 60], "perfectMul": 0.5, "heavyAfterClose": 0.9}',
         '{"guardShare": 0, "enderShare": 0.3, "heavyApproachShare": 0.3}'],
};
edit("data/director/ai.json", Object.keys(AI).map((k) => [
  '      "brawl": ' + AI[k][0] + ',\n',
  '      "brawl": ' + AI[k][1] + ',\n      "vsShooter": ' + AI[k][2] + ',\n',
]).concat([
  // The medium AI guards a barrage far less often: since blocked hits wear the arms only up to a cap (Simulation's
  // wear rule), a guard soaks bolts almost for free, and at 0.42 a shooter could not win.
  ['      "barrageGuard": 0.42,\n', '      "barrageGuard": 0.05,\n'],
  // The AI fires more often: heavy shots at a heavy blow's worth took the blasts' share of damage to 7.7%, under its floor
  // of 10%, and Game Design's lever for that is how often the AI fires, not what a shot is worth.
  ['      "blastShare": 0.2,\n', '      "blastShare": 0.3,\n'],
  ['      "blastShare": 0.4,\n', '      "blastShare": 0.55,\n'],
  ['      "blastShare": 0.5,\n', '      "blastShare": 0.65,\n'],
  ["held for guardTicks (drawn in the range), after which it must attack.",
   "held for guardTicks (drawn in the range), after which it must attack. heavyAfterClose (melee-press-feel.md section 9d): when a flurry's close has landed on it, the chance its next action, as its stagger ends, is a heavy. Each level's vsShooter block is what it does against a shooter (a rival who has fired lately and landed no melee blow: interrupts.json brawl.shooter): guardShare and enderShare replace the brawl block's in a brawl with him, so it does not guard and seldom throws the ender that would knock him back to his range; heavyApproachShare is the chance its attack from outside reach is the approach a bolt does not stop, the heavy lunge or the heavy charge."],
]));
