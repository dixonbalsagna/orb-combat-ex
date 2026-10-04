// Agency slice 13: timing paid on every press, and flow paid in set-ups and contests (docs/design/agency-pass.md
// section 22). Applies on top of slice 12. node apply.cjs <repo root>. Idempotent.
//  1. An on-beat blur strike lands clean at once (blur.timedMul); off the beat it does launch.json blur.strikeMul.
//  2. Flow adds damage: flow.dmgPer for each point, on every melee strike of his.
//  3. The blur's ender is the full one when his flow is blur.fullEnderFlow or more as it plays. The lock is the look's cue.
//  4. A lone heavy launched at flow showcaseAt sends the showcase cue. (flow.launchWear is not in: no wear hook on a launch.)
//  5. Flow counts in contests: flow.contest for each point he held as the exchange or his finisher started, up to
//     flow.contestMax, on his beam clash score and off the rival's chance to survive his finisher.
//  6. The AI's timed share: 0.15, 0.45, 0.8.
//  7. A barrage that includes a tapped, uncharged heavy shot gets the weak ender (blast.barrage.tappedHeavyWeak).
//  8. The finisher's struggle (Combat's struggle-scoring.md, the EP's ruling): the press score is floored at
//     scoring.floor before the tilts; finishers.json perStray -0.15 and floor 0.08 (those two values, by the EP's grant).
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

// ---------------------------------------------------------------- the flow he held as the exchange started
edit("sim/director/alchemy.gd", [
  ["const BLUR_AT: int = READ + 11               # ... the live tick its last blow landed on\n" +
   "const SIZE: int = READ + 12\n",
   "const BLUR_AT: int = READ + 11               # ... the live tick its last blow landed on\n" +
   "const FLOW_EX: int = READ + 12               # his flow when the running exchange, or his finisher, started: it counts in contests\n" +
   "const SIZE: int = READ + 13\n"],
  ["## The freeze a press or a release that arrives now was made in: the frozen ticks since the last live tick.\n",
   "## Notes his flow as an exchange, or his finisher, starts (agency-pass.md section 22: flow counts in contests, and a\n" +
   "## contest can come after the flow has lapsed).\n" +
   "static func markFlow(f) -> void:\n" +
   L(1, "_size(f)") +
   L(1, "f.act.dirI[FLOW_EX] = f.act.flow") +
   "\n\n" +
   "## The flow he held then.\n" +
   "static func flowEx(f) -> int:\n" +
   L(1, "_size(f)") +
   L(1, "return f.act.dirI[FLOW_EX]") +
   "\n\n" +
   "## The freeze a press or a release that arrives now was made in: the frozen ticks since the last live tick.\n"],
]);

edit("sim/director/exchange.gd", [
  [L(1, "SimWounds.onExchangeStart(S, ex)   # pitch A: which limbs were already battered (only those can be crippled)"),
   L(1, "SimWounds.onExchangeStart(S, ex)   # pitch A: which limbs were already battered (only those can be crippled)") +
   L(1, "DirAlchemy.markFlow(A)   # section 22: the flow each held as it began counts in its contests") +
   L(1, "DirAlchemy.markFlow(D)")],
  ["static func startFinisher(S: SimState, ex, W, L) -> void:\n" +
   L(1, "for b in ex.beats:"),
   "static func startFinisher(S: SimState, ex, W, L) -> void:\n" +
   L(1, "DirAlchemy.markFlow(W)   # his flow as his finisher starts: it comes off the rival's chance to survive it") +
   L(1, "for b in ex.beats:")],
  ["## The contest roll (one S.rng draw): survive with CONTEST_BASE, less CONTEST_TILT per minute past CONTEST_TILT_AT.\n",
   "## Flow counts in contests (agency-pass.md section 22): flow.contest points for each point of the flow f held as the\n" +
   "## exchange, or his finisher, started, up to flow.contestMax. It is added to his beam clash score, and it comes off\n" +
   "## the rival's chance, in points of a hundred, to survive his finisher.\n" +
   "static func flowEdge(f) -> float:\n" +
   L(1, "var fl: Dictionary = DirRecipe.cfg().get(\"flow\", {})") +
   L(1, "if not DirInterrupt.on() or not fl.has(\"contest\"):") +
   L(2, "return 0.0") +
   L(1, "return minf(float(fl.get(\"contestMax\", 0.0)), float(fl.contest) * float(DirAlchemy.flowEx(f)))") +
   "\n\n" +
   "## The contest roll (one S.rng draw): survive with CONTEST_BASE, less CONTEST_TILT per minute past CONTEST_TILT_AT.\n"],
  [L(1, "var chance: float = SimMathx.jmax(0.0, CONTEST_BASE - CONTEST_TILT * late)"),
   L(1, "var chance: float = SimMathx.jmax(0.0, CONTEST_BASE - CONTEST_TILT * late - flowEdge(W) / 100.0)")],
  [L(2, "chance = float(sc.base) + float(sc.perHit) * float(a.sHits) + float(sc.perMiss) * misses + float(sc.perStray) * float(a.sStrays) - float(cs.tiltPerMinute) * late"),
   L(2, "# The press score is floored at scoring.floor, the score of a player who does not press, before the tilts come") +
   L(2, "# off (Combat's docs/combat/struggle-scoring.md): flooding the struggle never does worse than not pressing.") +
   L(2, "chance = maxf(float(sc.get(\"floor\", 0.0)), float(sc.base) + float(sc.perHit) * float(a.sHits) + float(sc.perMiss) * misses + float(sc.perStray) * float(a.sStrays)) - float(cs.tiltPerMinute) * late")],
  [L(1, "chance -= float(cs.get(\"rallyPenalty\", 0.0)) * float(L.rallies)"),
   L(1, "chance -= float(cs.get(\"rallyPenalty\", 0.0)) * float(L.rallies)") +
   L(1, "chance -= flowEdge(W) / 100.0   # section 22: the flow the winner held as his finisher started")],
]);

edit("sim/director/beam.gd", [
  ["(f.menace * f.md.menaceBeam if f.hasMenace else 0.0)   # D1b: meters.json beam_power\n",
   "(f.menace * f.md.menaceBeam if f.hasMenace else 0.0) + DirExchange.flowEdge(f)   # D1b: meters.json beam_power; section 22: his flow\n"],
]);

// ---------------------------------------------------------------- the blur's strikes and ender, flow's damage, the lone heavy's showcase
edit("sim/director/melee.gd", [
  [L(4, "# Section 20: a plain blur's strikes do strikeMul of a light each; a blur that is locked in lands clean.") +
   L(4, "if not DirBlur.perfect(S, a):") +
   L(5, "dmg *= float(bl.strikeMul)"),
   L(4, "# Section 22: an on-beat blur strike lands clean at once (timedMul); off the beat it does strikeMul.") +
   L(4, "dmg *= float(DirBlur.cfg().get(\"timedMul\", 1.0)) if (pp >= 0 and ((pp >> 8) & 3) == DirAlchemy.TIMED) else float(bl.strikeMul)")],
  [L(4, "dmg *= float(tm.comboMul)") +
   L(1, "SimDamage.hit(S, ex, a, d, dmg, o)"),
   L(4, "dmg *= float(tm.comboMul)") +
   L(3, "# Section 22: flow adds damage, dmgPer for each point, on every strike of his.") +
   L(3, "dmg *= 1.0 + float(DirRecipe.cfg().get(\"flow\", {}).get(\"dmgPer\", 0.0)) * float(a.act.flow)") +
   L(1, "SimDamage.hit(S, ex, a, d, dmg, o)")],
  [L(4, "# The perfect blur's ender (section 20): locked in, it goes the full distance and is a full set-up; a plain") +
   L(4, "# blur's goes enderDist and is half of one.") +
   L(4, "var perfect: bool = ender and DirBlur.perfect(S, att)"),
   L(4, "# The blur's full ender (section 22): at flow fullEnderFlow or more as it plays, it goes the full distance and is") +
   L(4, "# a full set-up; below that it goes enderDist and is half of one.") +
   L(4, "var perfect: bool = ender and att.act.flow >= int(DirBlur.cfg().get(\"fullEnderFlow\", 99))")],
  ["(\"locked in: the pattern's closing blow and the full knock-back\" if perfect else ",
   "(\"at flow \" + str(att.act.flow) + \": the pattern's closing blow and the full knock-back\" if perfect else "],
  ["   # a plain blur's ender is half a set-up (section 14.4); a locked-in blur's is a full one\n",
   "   # a plain blur's ender is half a set-up (section 14.4); at flow fullEnderFlow it is a full one\n"],
  [L(1, "if not longOnly and why.begins_with(\"the ender of a string\") and att.act.flow >= int(DirRecipe.cfg().get(\"flow\", {}).get(\"showcaseAt\", 99)):"),
   L(1, "if not longOnly and (why.begins_with(\"the ender of a string\") or why == \"a heavy with the stick, landing clean\") and att.act.flow >= int(DirRecipe.cfg().get(\"flow\", {}).get(\"showcaseAt\", 99)):")],
  ["SimEvents.feed(S, att.name + \" SHOWCASE ENDER\", \"a string's ender at flow \" + str(att.act.flow))",
   "SimEvents.feed(S, att.name + \" SHOWCASE ENDER\", (\"a string's ender\" if why.begins_with(\"the ender\") else \"a lone heavy\") + \" at flow \" + str(att.act.flow))"],
]);

edit("sim/director/blur.gd", [
  ["##  - The lock: Controls' steady read (SimPressRead: steadyPresses presses in a row, each within blurBeatHalf ticks of\n" +
   "##    a different blow's contact) locks the blur in for the rest of the string: each strike does a full light's damage\n" +
   "##    (a plain blur's does launch.json blur.strikeMul), and the ender is the full one.\n",
   "##  - On the beat (agency-pass.md section 22): a strike from a press on the beat does timedMul of a light at once;\n" +
   "##    off it, launch.json blur.strikeMul. The ender is the full one when his flow is fullEnderFlow or more as it plays.\n" +
   "##  - The lock: Controls' steady read (SimPressRead: steadyPresses presses in a row, each within blurBeatHalf ticks of\n" +
   "##    a different blow's contact). It is the cue for the look (blur_locked), and changes no number.\n"],
  ["## True once his blur is locked in.\n" +
   "static func perfect(S: SimState, f) -> bool:\n" +
   L(1, "return live(S, f) and f.act.dirI[DirAlchemy.BLUR_ON] >= _need()") +
   "\n\n" +
   "## The presses a lock takes (Controls' steadyPresses).\n",
   "## The presses a lock takes (Controls' steadyPresses). The lock is the look's cue.\n"],
  ["str(need) + \" presses on the beat: full contact, and the full ender\")", "str(need) + \" presses on the beat, each on its own blow\")"],
]);

// ---------------------------------------------------------------- a barrage with a tapped heavy gets the weak ender
edit("sim/director/blast.gd", [
  [L(1, "var flight: int = clampi(sh.total - sh.left, 0, 4095)") +
   L(1, "var fires: Array = [S.tick - flight]   # the fire ticks of the clean bolts inside the window, newest first"),
   L(1, "var flight: int = clampi(sh.total - sh.left, 0, 2047)") +
   L(1, "# A tapped heavy: a charged shot fired with no charge. Section 22: a barrage that includes one gets the weak ender.") +
   L(1, "var tap: bool = c.get(\"tappedHeavyWeak\", false) and sh.kind == String(data().heavy.kind) and sh.dmg <= float(SimShots.kinds[sh.kind].dmg) * float(data().heavy.tapShare) + 0.001") +
   L(1, "var tapped: bool = tap") +
   L(1, "var fires: Array = [S.tick - flight]   # the fire ticks of the clean shots inside the window, newest first")],
  [L(3, "fires.append((v >> 12) - (v & 4095))"),
   L(3, "fires.append((v >> 12) - (v & 2047))") +
   L(3, "tapped = tapped or ((v >> 11) & 1) == 1")],
  [L(2, "DirInterrupt.si(by, DirInterrupt.BAR_1, (S.tick << 12) | flight)"),
   L(2, "DirInterrupt.si(by, DirInterrupt.BAR_1, (S.tick << 12) | (2048 if tap else 0) | flight)")],
  [L(1, "var measured: bool = true") +
   L(1, "for k in range(int(c.enderAfter) - 1):"),
   L(1, "var measured: bool = not tapped") +
   L(1, "for k in range(int(c.enderAfter) - 1):")],
  ["(\"measured\" if measured else \"spammed (the weak one)\")", "(\"measured\" if measured else (\"with a tapped heavy (the weak one)\" if tapped else \"spammed (the weak one)\"))"],
]);

// ---------------------------------------------------------------- data
// The struggle's scoring (the EP's ruling on Combat's docs/combat/struggle-scoring.md; the EP's grant for these two values
// of Combat's file): a stray press costs as much as a hit and a half earns, and the floor is the no-press score.
edit("data/combat/finishers.json", [
  [`"perStray": -0.05, "floor": 0.0,`, `"perStray": -0.15, "floor": 0.08,`],
]);
edit("data/director/interrupts.json", [
  [`      "immune": 90,
`,
   `      "immune": 90,
      "tappedHeavyWeak": true,
`],
  [`immune: the count starts again and the rival cannot be knocked back by another barrage for this many ticks"`,
   `immune: the count starts again and the rival cannot be knocked back by another barrage for this many ticks. tappedHeavyWeak (section 22): a barrage that includes a tapped, uncharged heavy shot gets the weak ender, as a spammed one does"`],
]);
edit("data/director/ai.json", [
  [`      "timedPress": 0.4,
`, `      "timedPress": 0.15,
`],
  [`      "timedPress": 0.65,
`, `      "timedPress": 0.45,
`],
  [`      "timedPress": 0.85,
`, `      "timedPress": 0.8,
`],
  [`(agency-pass.md section 2: 40, 65 and 85%)`, `(agency-pass.md section 22, where it is ai.timedShare: 15, 45 and 80%)`],
]);
{
  const f = path.join(root, "data/director/alchemy.json");
  const txt = fs.readFileSync(f, "utf8");
  const j = JSON.parse(txt);
  const put = (o, k, v, before) => {   // a key before its _note, keeping the file's order
    const out = {};
    for (const key of Object.keys(o)) {
      if (key === before && !(k in o)) out[k] = v;
      out[key] = o[key];
    }
    if (!(k in out)) out[k] = v;
    out[k] = v;
    for (const key of Object.keys(o)) delete o[key];
    Object.assign(o, out);
  };
  put(j.flow, "dmgPer", 0.04, "_note");
  put(j.flow, "contest", 2, "_note");
  put(j.flow, "contestMax", 10, "_note");
  if (!String(j.flow._note).includes("dmgPer")) j.flow._note += ". Section 22: dmgPer, every melee strike of his does this much more for each point of flow. contest: each point of the flow he held as the exchange, or his finisher, started adds this much to his beam clash score and takes this many points off the rival's chance to survive his finisher, up to contestMax";
  put(j.blur, "timedMul", 1.0, "_note");
  put(j.blur, "fullEnderFlow", 3, "_note");
  j.blur._note = "The blur string (agency-pass.md sections 20 and 22; sim/director/blur.gd). A string that starts on a light press in the blur style draws its cadence from 'cadences' (ticks between its blows) and its pattern from the recipes' blurPatterns, by keyed draws. The chain window opens on the blow; a link whose press is waiting lands one cadence after the last blow, and a later press lands minLeadTicks after it. timedMul: a link's strike from a press on the beat (within Controls' blurBeatHalf of a blow's contact) does this much of a light; off the beat it does launch.json blur.strikeMul. fullEnderFlow: the blur's ender is the full one (launch.json blur.perfectDist, a full set-up) when his flow is this or more as it plays, and the weak one below it. The lock (Controls' steady read: steadyPresses presses in a row, each on a different blow's contact; for the AI, that many timed presses in a row) is the cue for the look, blur_locked, and changes no number. A heavy press ends the blur. enabled false: strings keep the template's timing";
  const eol = txt.includes("\r\n") ? "\r\n" : "\n";
  fs.writeFileSync(f, JSON.stringify(j, null, 2).split("\n").join(eol) + eol);
  console.log("data/director/alchemy.json: written");
}
console.log("done");
