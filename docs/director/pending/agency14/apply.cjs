// Agency slice 14 (docs/design/agency-pass.md section 23). Applies on top of slice 13. node apply.cjs <repo root>.
// Idempotent.
//  1. A tapped charged shot does blast.heavy.tapShare 0.4 of the kind's damage (was 0.6); a full charge is unchanged.
//  2. The flow's cut on a finisher's survival chance never takes it below flow.contestFloor (the struggle's floor).
//  3. The comment above the contest's branch says the struggle's numbers as they are.
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

edit("sim/director/exchange.gd", [
  ["## The contest roll (one S.rng draw): survive with CONTEST_BASE, less CONTEST_TILT per minute past CONTEST_TILT_AT.\n",
   "## The flow's cut on a chance to survive a finisher (agency-pass.md sections 22 and 23): W's flowEdge points come off,\n" +
   "## and the cut never takes the chance below flow.contestFloor. A chance already below it is left as it is.\n" +
   "static func flowCut(chance: float, W) -> float:\n" +
   L(1, "var fl: Dictionary = DirRecipe.cfg().get(\"flow\", {})") +
   L(1, "return minf(chance, maxf(float(fl.get(\"contestFloor\", 0.0)), chance - flowEdge(W) / 100.0))") +
   "\n\n" +
   "## The contest roll (one S.rng draw): survive with CONTEST_BASE, less CONTEST_TILT per minute past CONTEST_TILT_AT.\n"],
  [L(1, "var chance: float = SimMathx.jmax(0.0, CONTEST_BASE - CONTEST_TILT * late - flowEdge(W) / 100.0)"),
   L(1, "var chance: float = flowCut(SimMathx.jmax(0.0, CONTEST_BASE - CONTEST_TILT * late), W)")],
  [L(1, "chance -= flowEdge(W) / 100.0   # section 22: the flow the winner held as his finisher started"),
   L(1, "chance = flowCut(chance, W)   # sections 22 and 23: the flow the winner held as his finisher started")],
  ["## The contest in \"branch\" mode: one S.rng draw, as today; the chance comes from the struggle when the finisher opened one\n" +
   "## (base 15, +10 per hit, -5 per missed beat or stray), otherwise from the contest's base; then the tilt past 8:00. The\n" +
   "## outcome's beats (landed or survived) are scheduled from here; the KO happens at finalBlow.\n",
   "## The contest in \"branch\" mode: one S.rng draw, as today; the chance comes from the struggle when the finisher opened one\n" +
   "## (base 23, +10 a hit, -5 a missed beat, -15 a stray press, floored at 8: finishers.json contest.struggle.scoring),\n" +
   "## otherwise from the contest's base; then the tilts: the time past 8:00, the Rallies used, and the winner's flow\n" +
   "## (flowCut). The outcome's beats (landed or survived) are scheduled from here; the KO happens at finalBlow.\n"],
]);

edit("data/director/interrupts.json", [
  [`      "tapShare": 0.6,
`, `      "tapShare": 0.4,
`],
]);
{
  const f = path.join(root, "data/director/alchemy.json");
  const txt = fs.readFileSync(f, "utf8");
  const j = JSON.parse(txt);
  if (!("contestFloor" in j.flow)) {
    const out = {};
    for (const k of Object.keys(j.flow)) {
      if (k === "_note") out.contestFloor = 0.08;
      out[k] = j.flow[k];
    }
    j.flow = out;
    j.flow._note += ". Section 23: contestFloor, the flow's cut never takes the rival's chance to survive below this (the struggle's floor)";
  }
  const eol = txt.includes("\r\n") ? "\r\n" : "\n";
  fs.writeFileSync(f, JSON.stringify(j, null, 2).split("\n").join(eol) + eol);
  console.log("data/director/alchemy.json: written");
}
console.log("done");
