// The director's accessor caches (docs/architecture/cloud-reports/2026-10-28-snapshot-tick.md, part 2), for Encounter Systems'
// files: the tick asks the same data blocks and per-fighter integers some 450 times, through chains of four or five
// calls. Every answer is the same object or value as before (a cache keyed by the data it was read from; a size check
// before the sizing call it skips), so the golden is byte-identical. Usage, from the repo root:
//   node docs/architecture/pending/tick-accessors/apply-tick-accessors.cjs .
const fs = require("fs"), path = require("path");
const root = process.argv[2];
if (!root) throw "usage: node apply-tick-accessors.cjs <root>";
const P = f => path.join(root, f);
function edit(file, pairs) {
  let s = fs.readFileSync(P(file), "utf8");
  const crlf = s.includes("\r\n");
  if (crlf) s = s.replace(/\r\n/g, "\n");
  for (const [a, b] of pairs) {
    if (s.includes(b)) continue;
    if (s.split(a).length !== 2) throw new Error(file + ": anchor not found once: " + a.slice(0, 90));
    s = s.replace(a, () => b);
  }
  fs.writeFileSync(P(file), crlf ? s.replace(/\n/g, "\r\n") : s);
}
edit("sim/director/alchemy.gd", [
 [
  "\n\nstatic func _size(f) -> void:\n\tDirInterrupt.gi(f, 0)   # DirInterrupt sizes and seeds its own part first\n\tif f.act.dirI.size() < SIZE:\n\t\tf.act.dirI.resize(SIZE)",
  "\n\nstatic func _size(f) -> void:\n\tif f.act.dirI.size() >= SIZE:   # sized (SIZE is past DirInterrupt.N)\n\t\treturn\n\tDirInterrupt.gi(f, 0)   # DirInterrupt sizes and seeds its own part first\n\tif f.act.dirI.size() < SIZE:\n\t\tf.act.dirI.resize(SIZE)"
 ]
]);
edit("sim/director/brawl.gd", [
 [
  "\n\nstatic func cfg() -> Dictionary:\n\treturn DirInterrupt.data().get(\"brawl\", {})\n\n\nstatic func on() -> bool:",
  "\n\nstatic func cfg() -> Dictionary:\n\tvar d: Dictionary = DirInterrupt.data()\n\tif not is_same(d, _cfgOf):\n\t\t_cfg = d.get(\"brawl\", {})   # the same block every time for the same data (tools edit it in place)\n\t\t_cfgOf = d\n\treturn _cfg\n\n\nstatic var _cfg: Dictionary = {}\nstatic var _cfgOf = null\n\n\nstatic func on() -> bool:"
 ],
 [
  "\n\nstatic func _size(f) -> void:\n\tDirAlchemy._size(f)\n\tif f.act.dirI.size() < END:\n\t\tf.act.dirI.resize(END)",
  "\n\nstatic func _size(f) -> void:\n\tif f.act.dirI.size() >= END:\n\t\treturn\n\tDirAlchemy._size(f)\n\tif f.act.dirI.size() < END:\n\t\tf.act.dirI.resize(END)"
 ],
 [
  "\n\nstatic func _s(f, k: int, v: int) -> void:\n\t_size(f)\n\tf.act.dirI[k] = v\n\n",
  "\n\nstatic func _s(f, k: int, v: int) -> void:\n\tif f.act.dirI.size() < END:   # sized: every part below END is (END is past DirAlchemy.SIZE and DirInterrupt.N)\n\t\t_size(f)\n\tf.act.dirI[k] = v\n\n"
 ]
]);
edit("sim/director/data.gd", [
 [
  "\n## Step 3: the active profile's perfect-block numbers (Combat's: staggerTicks, riposteTicks). Empty in the old profiles.\nstatic func perfectBlock() -> Dictionary:\n\t_ensure()\n\treturn _prof().get(\"perfectBlock\", {})\n\n\n## An interrupt's block (templates.json interrupts).",
  "\n## Step 3: the active profile's perfect-block numbers (Combat's: staggerTicks, riposteTicks). Empty in the old profiles.\nstatic func perfectBlock() -> Dictionary:\n\tif _tpl != null and is_same(_pbTpl, _tpl) and _pbProf == templatesProfile:\n\t\treturn _pb   # the tick asks some twenty times: the block of the same data and profile as last time\n\t_ensure()\n\t_pb = _prof().get(\"perfectBlock\", {})\n\t_pbTpl = _tpl\n\t_pbProf = templatesProfile\n\treturn _pb\n\n\nstatic var _pb: Dictionary = {}   # perfectBlock's last answer, for the data (_tpl) and the forced profile it was read from\nstatic var _pbTpl = null\nstatic var _pbProf: String = \"\"\n\n\n## An interrupt's block (templates.json interrupts)."
 ]
]);
edit("sim/director/grapple.gd", [
 [
  "\n\nstatic func cfg() -> Dictionary:\n\treturn DirInterrupt.data().get(\"grapple\", {})\n\n\nstatic func on() -> bool:",
  "\n\nstatic func cfg() -> Dictionary:\n\tvar d: Dictionary = DirInterrupt.data()\n\tif not is_same(d, _cfgOf):\n\t\t_cfg = d.get(\"grapple\", {})   # the same block every time for the same data (tools edit it in place)\n\t\t_cfgOf = d\n\treturn _cfg\n\n\nstatic var _cfg: Dictionary = {}\nstatic var _cfgOf = null\n\n\nstatic func on() -> bool:"
 ],
 [
  "\n\nstatic func _size(f) -> void:\n\tDirZip._size(f)\n\tif f.act.dirI.size() < END:\n\t\tf.act.dirI.resize(END)",
  "\n\nstatic func _size(f) -> void:\n\tif f.act.dirI.size() >= END:\n\t\treturn\n\tDirZip._size(f)\n\tif f.act.dirI.size() < END:\n\t\tf.act.dirI.resize(END)"
 ]
]);
edit("sim/director/interrupt.gd", [
 [
  "\n\nstatic func gi(f, k: int) -> int:\n\t_size(f)\n\treturn f.act.dirI[k]\n\n\nstatic func si(f, k: int, v: int) -> void:\n\t_size(f)\n\tf.act.dirI[k] = v\n\n",
  "\n\nstatic func gi(f, k: int) -> int:\n\tif f.act.dirI.size() < N:\n\t\t_size(f)\n\treturn f.act.dirI[k]\n\n\nstatic func si(f, k: int, v: int) -> void:\n\tif f.act.dirI.size() < N:\n\t\t_size(f)\n\tf.act.dirI[k] = v\n\n"
 ]
]);
edit("sim/director/rally.gd", [
 [
  "\n\nstatic func cfg() -> Dictionary:\n\treturn DirInterrupt.data().get(\"rally\", {})\n\n\nconst SCORING_PATH: String = \"res://data/director/rally.json\"",
  "\n\nstatic func cfg() -> Dictionary:\n\tvar d: Dictionary = DirInterrupt.data()\n\tif not is_same(d, _cfgOf):\n\t\t_cfg = d.get(\"rally\", {})   # the same block every time for the same data (tools edit it in place)\n\t\t_cfgOf = d\n\treturn _cfg\n\n\nstatic var _cfg: Dictionary = {}\nstatic var _cfgOf = null\n\n\nconst SCORING_PATH: String = \"res://data/director/rally.json\""
 ]
]);
edit("sim/director/zip.gd", [
 [
  "\n\nstatic func _size(f) -> void:\n\tDirBrawl._size(f)\n\tif f.act.dirI.size() < END:\n\t\tf.act.dirI.resize(END)",
  "\n\nstatic func _size(f) -> void:\n\tif f.act.dirI.size() >= END:\n\t\treturn\n\tDirBrawl._size(f)\n\tif f.act.dirI.size() < END:\n\t\tf.act.dirI.resize(END)"
 ]
]);
console.log("tick accessors applied");
