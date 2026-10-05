// Brawl slice B1, the first brawl (docs/director/brawl-plan.md section 4; docs/design/melee-press-feel.md sections 1 to 3, 5 to 7).
// node apply.cjs <repo root>. Idempotent. It goes on top of slice B0. brawl.gd beside this script becomes
// sim/director/brawl.gd, and brawl_probe.gd replaces sim/director/tools/brawl_probe.gd.
//  1. In the close band a light or a heavy against a rival who stands or guards starts a brawl (DirBrawl): an exchange
//     both fighters are in, each with his own strike line. Every attack press of either is a blow.
//  2. The exchange's hooks: a press goes to the brawl, a brawl's strike beat is its contact, the brawl's tick runs before
//     the beats, the exchange stays alive while the brawl holds, and there is no cooldown after it except after a launch.
//  3. The interrupts inside a brawl: the perfect block and the reversal for whoever is struck; the dodge-cancel leaves
//     only with the stick away; each tells the brawl why it ended.
//  4. A press inside a brawl neither earns nor loses flow (the beat point is B2).
//  5. The AI's brawl play (DirBrawl.aiInput) and its numbers per level.
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

fs.copyFileSync(path.join(__dirname, "brawl.gd"), path.join(root, "sim/director/brawl.gd"));
console.log("sim/director/brawl.gd: written");
fs.copyFileSync(path.join(__dirname, "brawl_probe.gd"), path.join(root, "sim/director/tools/brawl_probe.gd"));
console.log("sim/director/tools/brawl_probe.gd: written");

// ---------------------------------------------------------------- the exchange's hooks
edit("sim/director/exchange.gd", [
  [L(1, "DirAlchemy.log(S, A, KIND.find(kind), A.act.mode)   # the press log (read-only for now)") +
   L(1, "if not A.act.v2:"),
   L(1, "DirAlchemy.log(S, A, KIND.find(kind), A.act.mode)   # the press log (read-only for now)") +
   L(1, "if DirBrawl.takes(S, A, kind):") +
   L(2, "return   # a brawl is on and he is in it: the press is a blow on his own line, never a request") +
   L(1, "if not A.act.v2:")],
  ["static var planMeetEdge: float = 0.0   # ... and the edge of a rival met while he held a heavy charge (off the attacker's clash chance)\n",
   "static var planMeetEdge: float = 0.0   # ... and the edge of a rival met while he held a heavy charge (off the attacker's clash chance)\n" +
   "static var planCharge: bool = false   # ... and whether the approach was a held charge: it keeps its template (DirBrawl.starts)\n"],
  [L(2, "var up: int = f.input.upgrade") +
   "		if up > 0 and not SimAct.upgrade(",
   L(2, "var up: int = f.input.upgrade") +
   L(2, "if up > 0 and DirBrawl.takes(S, f, \"heavy\" if up == 1 else \"sig\"):") +
   L(3, "continue   # in a brawl the hold's edge is a heavy press of its own") +
   "		if up > 0 and not SimAct.upgrade("],
  [L(1, "if kind != \"sig\" and DirData.hasNeutral() and opn == 0 and not fu and planDefStance < 0:"),
   L(1, "# The brawl (DirBrawl): in the close band a light or a heavy against a rival who stands or guards is the first blow") +
   L(1, "# of a brawl, not a planned exchange. Both fighters then have a strike line, and every press is a blow.") +
   L(1, "if DirBrawl.starts(S, ex, kind, opn, fu, dState):") +
   L(2, "DirInterrupt.onStart(S, ex, KIND.find(kind), A.act.mode, planEntry)") +
   L(2, "DirBrawl.begin(S, ex, kind)") +
   L(2, "SimFx.attack(S, A, D, kind, STN[int(D.stance)], ex.tag, A.ambush)") +
   L(2, "if A.ambush:") +
   L(3, "SimFx.ambush(S, A, D)") +
   L(3, "SimFx.danger(S, D, \"ambush\", 0.0)") +
   L(2, "return STARTED") +
   L(1, "if kind != \"sig\" and DirData.hasNeutral() and opn == 0 and not fu and planDefStance < 0:")],
  [L(2, "\"strike\":") +
   L(3, "DirMelee.strike(S, ex, A if a.a == \"A\" else D, A if a.d == \"A\" else D, a.dmg, a.o)"),
   L(2, "\"strike\":") +
   L(3, "if a.get(\"brawl\", false):") +
   L(4, "DirBrawl.contact(S, ex, b)   # a brawl's blow: it lands, and its line, its string and its close follow") +
   L(3, "else:") +
   L(4, "DirMelee.strike(S, ex, A if a.a == \"A\" else D, A if a.d == \"A\" else D, DirBrawl.worth(S, ex, b, a.dmg), a.o)   # outside a brawl a blow is worth its form")],
  [L(3, "DirMelee.strike(S, ex, A, D, 52.0 + ex.combo * 7.0, {\"noParry\": true, \"ignoreStance\": true, \"big\": true, \"stop\": 0.08})"),
   L(3, "DirMelee.strike(S, ex, A, D, DirBrawl.worth(S, ex, b, 52.0 + ex.combo * 7.0), {\"noParry\": true, \"ignoreStance\": true, \"big\": true, \"stop\": 0.08})   # with the brawl on, a link's blow is one brawl light")],
  [L(1, "planContext = \"riposte\" if (opn == DirInterrupt.OPEN_RIPOSTE or opn == DirInterrupt.OPEN_RIPOSTE_LAUNCH) else \"\""),
   L(1, "planContext = \"riposte\" if (opn == DirInterrupt.OPEN_RIPOSTE or opn == DirInterrupt.OPEN_RIPOSTE_LAUNCH) else \"\"") +
   L(1, "if planCharge:") +
   L(2, "DirBrawl.noteCharge(A, ex)   # a far charge's arrival: its first blow is worth more (DirBrawl.worth)")],
  [L(1, "DirInterrupt.tick(S)   # step 3: this tick's inputs inside the exchange (perfect block, reversal, dodge-cancel, burst)") +
   L(1, "DirBeamPlay.lateTick(S, ex)   # a late answer to a beam on its way"),
   L(1, "DirInterrupt.tick(S)   # step 3: this tick's inputs inside the exchange (perfect block, reversal, dodge-cancel, burst)") +
   L(1, "DirBrawl.tick(S, ex)   # a brawl's lines: held presses and heavies, the magnet, and what ends it") +
   L(1, "if S.dirS.ex != ex:") +
   L(2, "return") +
   L(1, "DirBeamPlay.lateTick(S, ex)   # a late answer to a beam on its way")],
  [L(1, "if not pending and not (ex.ext != null and S.T < ex.ext.until):") +
   L(2, "endEx(S, ex)"),
   L(1, "if not pending and not (ex.ext != null and S.T < ex.ext.until) and not DirBrawl.holds(S, ex):   # a brawl has no set length") +
   L(2, "endEx(S, ex)")],
  [L(0, "static func endEx(S: SimState, ex) -> void:") + L(1, "if ex.A.state == \"locked\":"),
   L(0, "static func endEx(S: SimState, ex) -> void:") +
   L(1, "DirBrawl.over(S, ex, \"ko\" if S.game.ko != null else \"ended\")   # a brawl that was not closed yet says so (every brawl_start has its brawl_end)") +
   L(1, "if ex.A.state == \"locked\":")],
  [L(1, "S.dirS.cool = cooldownAfter(ex)"),
   L(1, "S.dirS.cool = DirBrawl.coolAfter(ex) if DirBrawl.isBrawl(ex) else cooldownAfter(ex)   # no pause after a brawl, except after a launch")],
]);

// ---------------------------------------------------------------- a charge's arrival keeps its template
edit("sim/director/bands.gd", [
  [L(1, "DirExchange.planMeetEdge = float(data().meet.get(\"chargerEdge\", 0.0)) / 100.0 if (req & CHARGED) != 0 else 0.0   # points off the attacker's chance") +
   L(1, "DirExchange.engaging = true"),
   L(1, "DirExchange.planMeetEdge = float(data().meet.get(\"chargerEdge\", 0.0)) / 100.0 if (req & CHARGED) != 0 else 0.0   # points off the attacker's chance") +
   L(1, "DirExchange.planCharge = (req & CHARGE) != 0") +
   L(1, "DirExchange.engaging = true")],
  [L(1, "DirExchange.planMeet = false") +
   L(1, "DirExchange.planMeetEdge = 0.0"),
   L(1, "DirExchange.planMeet = false") +
   L(1, "DirExchange.planCharge = false") +
   L(1, "DirExchange.planMeetEdge = 0.0")],
]);

// ---------------------------------------------------------------- the interrupts inside a brawl
edit("sim/director/data.gd", [
  ["static func allows(ex, name: String) -> bool:\n" + L(1, "_ensure()"),
   "static func allows(ex, name: String) -> bool:\n" + L(1, "_ensure()") +
   L(1, "if DirBrawl.isBrawl(ex):") +
   L(2, "return DirBrawl.allows(name)   # a brawl has no branch: its list is interrupts.json brawl.interrupts")],
]);
edit("sim/director/interrupt.gd", [
  [L(1, "_takeOver(ex)") +
   L(1, "ex.loser = S.fighters.find(a)"),
   L(1, "_takeOver(ex)") +
   L(1, "DirBrawl.over(S, ex, \"perfect_block\")") +
   L(1, "ex.loser = S.fighters.find(a)")],
  [L(1, "var launch: bool = cls == \"heavy\" or cls == \"ender\" or ex.kind == \"heavy\""),
   L(1, "var launch: bool = cls == \"heavy\" or cls == \"ender\" or (ex.kind == \"heavy\" and not DirBrawl.isBrawl(ex))   # in a brawl the blow's own class says it")],
  [L(2, "if p > 0.0 and (String(b.args.o.get(\"class\", \"\")) != \"opener\" or ex.kind == \"heavy\"):"),
   L(2, "var cls: String = String(b.args.o.get(\"class\", \"\"))") +
   L(2, "if p > 0.0 and ((cls == \"heavy\") if DirBrawl.isBrawl(ex) else (cls != \"opener\" or ex.kind == \"heavy\")):")],
  [L(1, "var c: Dictionary = data().dodgeCancel") +
   "	# The attacker's cancel is free until his first wind-up starts",
   L(1, "if DirBrawl.isBrawl(ex) and (ex.branch != \"\" or f.input.mx * SimMathx.jsign(SimWrap.sdx(f.x, (ex.D if f == ex.A else ex.A).x)) >= -SimAct.awayDead):") +
   L(2, "return false   # in a brawl a dodge leaves only with the stick away (melee-press-feel.md section 2)") +
   L(1, "var c: Dictionary = data().dodgeCancel") +
   "	# The attacker's cancel is free until his first wind-up starts"],
  [L(1, "if f == ex.D and S.tick - gi(f, HIT_AT) < int(c.gapTicks):"),
   L(1, "if (f == ex.D or DirBrawl.isBrawl(ex)) and S.tick - gi(f, HIT_AT) < int(c.gapTicks):")],
  [L(1, "_takeOver(ex)") +
   L(1, "ex.loser = -1") +
   L(1, "ex.A.rush = null") +
   L(1, "ex.D.rush = null") +
   L(1, "dash(f, ex.D if f == ex.A else ex.A, float(c.dash))"),
   L(1, "_takeOver(ex)") +
   L(1, "DirBrawl.over(S, ex, \"left\")") +
   L(1, "ex.loser = -1") +
   L(1, "ex.A.rush = null") +
   L(1, "ex.D.rush = null") +
   L(1, "dash(f, ex.D if f == ex.A else ex.A, float(c.dash))")],
  [L(2, "_takeOver(ex)") +
   L(2, "ex.loser = -1") +
   L(2, "ex.A.rush = null"),
   L(2, "_takeOver(ex)") +
   L(2, "DirBrawl.over(S, ex, \"burst\")") +
   L(2, "ex.loser = -1") +
   L(2, "ex.A.rush = null")],
  [L(1, "if not on() or d.ai == null or d != ex.D or gi(d, REV_TRIED) == ex.n:"),
   L(1, "if not on() or d.ai == null or (not DirBrawl.revDue(S, d) if DirBrawl.isBrawl(ex) else (d != ex.D or gi(d, REV_TRIED) == ex.n)):")],
  [L(2, "if p > 0.0 and S.rng.next() < p * float(lv.perfectBlockMul):"),
   L(2, "if p > 0.0 and S.rng.next() < p * float(lv.perfectBlockMul) * (float(lv.get(\"brawl\", {}).get(\"perfectMul\", 1.0)) if DirBrawl.isBrawl(ex) else 1.0):")],
  [L(1, "if ex == null or f != ex.D or not DirData.allows(ex, \"reversal\") or DirBury.diving(S, f):"),
   L(1, "if ex == null or (f != ex.D and not (DirBrawl.isBrawl(ex) and f == ex.A)) or not DirData.allows(ex, \"reversal\") or DirBury.diving(S, f):")],
  [L(1, "_takeOver(ex)") +
   L(1, "ex.loser = -1") +
   L(1, "SimAct.clear(ex.A)") +
   L(1, "ex.A.stunTicks = maxi(ex.A.stunTicks, int(c.delayTicks) + int(c.landTicks))"),
   L(1, "_takeOver(ex)") +
   L(1, "DirBrawl.over(S, ex, \"reversal\")") +
   L(1, "ex.loser = -1") +
   L(1, "var att = ex.D if f == ex.A else ex.A   # the fighter whose blow he blocked (in a brawl either may reverse)") +
   L(1, "SimAct.clear(att)") +
   L(1, "att.stunTicks = maxi(att.stunTicks, int(c.delayTicks) + int(c.landTicks))")],
]);

// ---------------------------------------------------------------- the press behind a brawl's blow; flow in a brawl
edit("sim/director/launch.gd", [
  [L(1, "return DirInterrupt.gi(att, DirInterrupt.PHRASE_P) if att == ex.A else DirAlchemy.last(S, att)"),
   L(1, "return DirInterrupt.gi(att, DirInterrupt.PHRASE_P) if (att == ex.A or DirBrawl.isBrawl(ex)) else DirAlchemy.last(S, att)   # in a brawl each blow notes its own press")],
]);
edit("sim/director/alchemy.gd", [
  [L(2, "keep = not inEx and (f.ai != null or beat == SimPressRead.NO_BEAT)") +
   L(2, "if f.ai != null:"),
   L(2, "var brawl: bool = DirBrawl.inBrawl(S, f)   # B1: a press in a brawl neither earns nor loses flow (its beat point is B2)") +
   L(2, "keep = brawl or (not inEx and (f.ai != null or beat == SimPressRead.NO_BEAT))") +
   L(2, "if brawl:") +
   L(3, "timed = false") +
   L(2, "elif f.ai != null:")],
]);

// ---------------------------------------------------------------- the AI in a brawl
edit("sim/director/ai.gd", [
  [L(1, "if f.act.formReady:") +
   L(2, "i.transform = true") +
   L(1, "var d: float = SimWrap.sdx(f.x, o.x)"),
   L(1, "if f.act.formReady:") +
   L(2, "i.transform = true") +
   L(1, "if DirBrawl.inBrawl(S, f):") +
   L(2, "DirBrawl.aiInput(S, f)   # in a brawl it chooses at its beats, not on the stance timer") +
   L(2, "return") +
   L(1, "var d: float = SimWrap.sdx(f.x, o.x)")],
]);

// ---------------------------------------------------------------- data
json("data/director/interrupts.json", (j) => {
  j.perfectBlock.windows.blow = 8;
  if (!j.perfectBlock._note.includes("blow:"))
    j.perfectBlock._note += ". blow: a brawl's light or flurry blow (it is announced only light.contactTicks ahead, so the press is a read of the flurry's rhythm)";
  j.brawl = {
    enabled: true,
    interrupts: ["perfect_block", "reversal"],
    breakBh: 4.5,
    pullBhPerSec: 0.5,
    stepInTicks: 2,
    idleTicks: 60,
    heldPressTicks: 10,
    stringLapseTicks: 30,
    enderAfter: 2,
    recoil: 1,
    tradeTicks: 2,
    damageMul: 0.3,
    heavyMul: 2,
    heldMul: 1.25,
    skillMul: 4,
    setMul: 1.5,
    aiPerfectEveryTicks: 30,
    aiReversalEveryTicks: 120,
    light: { damage: 26, contactTicks: 2, blowTicks: 12, recover: 4 },
    flurry: { minGap: 6, maxGap: 12, mul: [[6, 0.6], [12, 1.2]], reelTicks: 4, closeAfter: 4, staggerTicks: 12, runToClose: 4, replyTakes: 1, runLapseTicks: 24, tradeMaxTicks: 120 },
    heavy: { damage: 66, ki: 4, windupTicks: 26, landTicks: 8, recover: 10, recoverWhiff: 30, heldFullTicks: 46, heldMaxTicks: 180, heldLandTicks: 8, staggerTicks: 12, force: 1600 },
    hitstop: { light: 2, heavy: 6 },
    _note: "The brawl, slice B1 (sim/director/brawl.gd; docs/design/melee-press-feel.md sections 1 to 3, 5 to 7). enabled: in the close band a light or a heavy against a rival who stands or guards starts a brawl, where each fighter has his own strike line and every press is a blow; false, every exchange is planned from its template as before. interrupts: the takeovers a brawl allows (the dodge-cancel and the burst always apply). breakBh: past this many body heights apart the brawl lets go. pullBhPerSec: drift is pulled back to striking distance (templates.json contact.offset) and to one height at up to this speed. stepInTicks: the first blow's step in to striking distance takes at most this long. idleTicks: with no attack from either for this long it ends. heldPressTicks: a press he cannot throw at once is held this long (the latest only). stringLapseTicks: his string is over when no blow of his was thrown or landed for this long. enderAfter: a heavy thrown after this many landed blows of his string is its ender, the only blow that knocks back. recoil: the push of a blow, units a second (a blow leans him and does not move him). tradeTicks: two light blows that land within this of each other are a trade: both land, their beats carry trade and tradeWith (the other's piece), and a trade cue goes out. damageMul: what a brawl light is worth against the data's light (Game Design, melee-press-feel.md section 9b): the stream, lights and flurry blows, takes it in full; it is QA's lever for match length, and the ratios below are the rule. heavyMul: a heavy and an ender are worth the data's heavy times the scale times this. heldMul: a heavy held to full is worth this much more. skillMul and setMul: a skill strike and a set light, in brawl lights (B2 and later; skillMul also sets what an answering blow outside a brawl is worth). With the brawl on, a blow outside a brawl is worth its form too (DirBrawl.worth): a light-class blow the scale, a heavy-class blow the scale times heavyMul, a chain link's blow one brawl light, and the first damaging blow of a riposte with a light, of a dodge template and of a light charge's arrival a skill strike; a heavy charge's arrival is a heavy held to full; signatures, finishers and the blow on a buried rival keep their damage. aiPerfectEveryTicks: the AI weighs a perfect block against a light at most once in this long (a fresh guard press cannot be mashed), and against every heavy. aiReversalEveryTicks: it weighs a reversal on a block at most once in this long. light: damage, the ticks from press to contact, a lone light's length, and `recover`: after a light his line is free for a heavy this long after its contact. flurry: lights tapped minGap to maxGap ticks apart are a flurry; a blow lasts one tap gap and does mul of a light by its gap ([gap, share] points, straight lines between: the interval over 10, so damage a second is level from 5 to 10 taps); a landed blow reels the rival reelTicks. The run (melee-press-feel.md section 3): each fighter's run goes up one for each light or flurry blow he lands and down replyTakes, never below 0, for each that lands on him; a heavy on him clears it, and so do runLapseTicks without landing; a blocked blow changes nothing. At a run of runToClose his next landed light is the close: it staggers the rival staggerTicks in place, decisive at launch.json setup.weight.blurPlain of a set-up. A trade is on while both have landed a light inside runLapseTicks, and cannot pass tradeMaxTicks without a close: at the limit it breaks for the higher run, then the more blows landed in the trade, then a seeded draw at even odds, and that fighter's next landed blow is the close. closeAfter is the first build's name for runToClose: it is not read, and stays only until the schema lets it go. heavy: damage, its ki, windupTicks then landTicks to contact; his line is free `recover` ticks after a heavy that lands, breaks a guard or ends his string, and recoverWhiff after one that meets nothing (the 76 ticks of the spec are its animation, whose follow-through plays only when nothing follows); held past the wind-up it waits for the release, fully charged at heldFullTicks of hold and let go by itself at heldMaxTicks, and lands heldLandTicks after the release; staggerTicks: a lone heavy that lands, and any heavy on a guard, staggers him in place; force: the launch force of an ender whose launch is earned. hitstop: ticks, by the blow's weight. Clocks: taps, the line, the string and the idle count run on S.tick (through a hit-stop); wind-ups, reels and holds are live ticks"
  };
});
// The mash's close is a quarter of a set-up (Game Design's second lever for the lights-only brink, after the trade's limit).
edit("data/director/launch.json", [
  ['"blurPlain": 0.5', '"blurPlain": 0.25'],
  ["blurPlain for a plain blur's own ender, from untimed presses, and barragePlain for a barrage's ender when any of its bolts was spammed: half of one each, so a masher or a spammer needs twice as many",
   "blurPlain for the mash's close (the flurry's stagger in a brawl, and a plain blur's own ender in a planned exchange): a quarter of one, so a masher needs four (melee-press-feel.md section 3: the second lever for the lights-only brink, after brawl.flurry.tradeMaxTicks); and barragePlain for a barrage's ender when any of its bolts was spammed: half of one, so a spammer needs twice as many"],
]);
// ai.json keeps its own layout, so its edits are text. AI_BRAWL: each level's block (the values a tuning pass changes).
const AI_BRAWL = {
  easy: '{"tapGap": 12, "string": [2, 4], "enderShare": 0.3, "rashHeavy": 1.0, "guardShare": 0.2, "guardTicks": [20, 60], "perfectMul": 0.3}',
  medium: '{"tapGap": 10, "string": [3, 5], "enderShare": 0.45, "rashHeavy": 0.58, "guardShare": 0.4, "guardTicks": [20, 60], "perfectMul": 0.15}',
  hard: '{"tapGap": 7, "string": [3, 5], "enderShare": 0.6, "rashHeavy": 0.1, "guardShare": 0.4, "guardTicks": [20, 60], "perfectMul": 0.5}',
};
edit("data/director/ai.json", [
  ['  "stance": {\n',
   '  "_brawl": "Each level\'s brawl block (sim/director/brawl.gd aiInput; melee-press-feel.md section 2b). In a brawl the AI chooses when its last choice has played out, not on the stance timer. tapGap: the ticks between its lights (12 to 6 is 5 to 10 blows a second). string: it throws this many lights, drawn in the range, and then, if interrupts.json brawl.enderAfter of them landed, closes with a heavy at enderShare. rashHeavy: the chance it still throws that heavy into a rival\'s running flurry, whose close would stop it (1 always, 0 never): the masher\'s wins come from these. guardShare: the share of its choices that are a guard, held for guardTicks (drawn in the range), after which it must attack. perfectMul: its perfect-block rate inside a brawl, as a share of its rate outside (perfectBlock times the level\'s perfectBlockMul); it weighs one against a light at most once in interrupts.json brawl.aiPerfectEveryTicks. Three of Game Design\'s levers for its answers to a string (melee-press-feel.md section 9c) are built and read when a level sets them, and are not set yet: answerBy (it answers a rival\'s paced string, not a flurry, by this landed blow with a guard, after reactTicks), guardMaxTicks (how long that guard is held before it must attack) and attackIntoGap (while it guards, when the rival has thrown nothing for this many ticks its own string goes in). Without the parry the guard alone costs it, so they wait for B2. A heavy against a rival who is guarding comes at the level\'s breakGuard, a held heavy at heldHeavy times earnerUse, and the signature at sigPick",\n' +
   '  "stance": {\n'],
].concat(Object.keys(AI_BRAWL).map((k) => [
  '    "' + k + '": {\n      "beamAnswer":',
  '    "' + k + '": {\n      "brawl": ' + AI_BRAWL[k] + ',\n      "beamAnswer":',
])));
