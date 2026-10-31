#!/usr/bin/env node
// A fighter's place in a lake for the look gate (docs/design/rulings-2026-10-30.md row 1): a scratch hook on Performance's
// pb scene. It edits a scratch copy of the game (git archive into a folder of your own), never the repo. Apply after
// docs/perf/tools/scratch-hooks/hook-perf.mjs, hook-slice.mjs and hook-pbiome.mjs.
//
//   node docs/rendering/tools/lake-hook.mjs <scratch tree> [--floor]
//
// --floor turns World's floor on in that copy's data: floor.enabled and surface.enabled in data/biomes/water.json and
// water.enabled in data/director/interrupts.json (the floor needs all three, docs/world/lake-floor.md). Run it again with
// --floor on a tree already hooked and only the switches move.
//
// Page words it adds (the pb scene's, in the scratch copy only):
//   pbiome=<fine biome>   the stretch search also takes World's fine biomes (tundra, highland, ...)
//   lakesea=<d>           the same on the sea
//   lakelaunch=<tick>     player two is slammed straight down at that tick (a real launch)
//   lakeunder=<d>        player two is held d under the water each tick (it writes the scratch sim: stills only)
//   lakedepth=<d>         the pair is set down on the ring's lake column nearest d deep, on WorldWater.floorAt: the floor
//                         with --floor, the bed without it
// Node 24 built-ins only. No Godot, no browser. Owner: Rendering and Technical Art.
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const root = process.argv[2];
if (!root || !existsSync(join(root, 'project.godot'))) { console.error('usage: node docs/rendering/tools/lake-hook.mjs <scratch tree holding project.godot> [--floor]'); process.exit(2); }
const f = join(root, 'render/tools/flash_capture.gd');
let s = readFileSync(f, 'utf8');
if (!s.includes('func _lake_place(')) {
  const edits = [
    ['for tgt in ["desert", "forest", "city", "coast"]:', 'for tgt in ["desert", "forest", "city", "coast", "tundra", "highland"]:'],
    ['ok = str(names[pc[i]]) == tgt', 'ok = (str(names[pc[i]]) == tgt) if tgt in ["desert", "forest", "city"] else WorldBiomes.fineNameAt((float(i) + 0.5) * SimConst.COL) == tgt'],
    ['\t\t"pb":\n\t\t\tif t == 0:\n\t\t\t\t_pb_place(S)\n', '\t\t"pb":\n\t\t\tif t == 0:\n\t\t\t\t_pb_place(S)\n\t\t\t\t_lake_place(S)\n\t\t\t_lake_launch(t, S)\n\t\t\t_lake_under(S)\n'],
  ];
  for (const [a, b] of edits) {
    if (s.split(a).length !== 2) { console.error(`lake-hook: the anchor is missing or not once (apply the pb hooks first): ${a.slice(0, 60)}`); process.exit(1); }
    s = s.replace(a, () => b);
  }
  s += `

## SCRATCH (docs/rendering/tools/lake-hook.mjs): lakelaunch=<tick> slams player two straight down at that tick.
func _lake_launch(t: int, S: SimState) -> void:
	if _page_kv("lakelaunch") != "" and t == int(_page_kv("lakelaunch")):
		DirLaunch.doLaunch(S, S.fighters[0], S.fighters[1], {"name": "SLAM DOWN", "ux": 0.0, "uy": -1.0}, 900.0)


## SCRATCH (docs/rendering/tools/lake-hook.mjs): lakeunder=<d> holds player two d under the water.
func _lake_under(S: SimState) -> void:
	if _page_kv("lakeunder") == "":
		return
	var f = S.fighters[1]
	var c: int = int(SimWrap.wrap(f.x) / SimConst.COL) % SimConst.NC
	f.y = S.base[c] + S.deform[c] + S.water[c] - float(_page_kv("lakeunder"))
	f.vx = 0.0
	f.vy = 0.0


## SCRATCH (docs/rendering/tools/lake-hook.mjs): lakedepth=<d> sets the pair down on the ring's lake column nearest d deep.
func _lake_place(S: SimState) -> void:
	var sea: bool = _page_kv("lakesea") != ""
	if _page_kv("lakedepth") == "" and not sea:
		return
	var want: float = float(_page_kv("lakesea") if sea else _page_kv("lakedepth"))
	var best: int = -1
	for i in range(SimConst.NC):
		if S.water[i] >= WorldWater.MIN_DEPTH and (absf(S.base[i] + S.deform[i] + S.water[i]) < 1.0) == sea and (best < 0 or absf(S.water[i] - want) < absf(S.water[best] - want)):
			best = i
	if best < 0:
		return
	for i in range(2):
		var f = S.fighters[i]
		f.x = SimWrap.wrap((float(best) + 0.5) * SimConst.COL + 60.0 * float(i))
		f.y = WorldWater.floorAt(S, f.x)
		f.vx = 0.0
		f.vy = 0.0
`;
  writeFileSync(f, s);
  console.log('lake hook applied');
}
if (process.argv.includes('--floor')) {
  const flip = (p, set) => {
    const j = JSON.parse(readFileSync(join(root, p), 'utf8'));
    set(j);
    writeFileSync(join(root, p), JSON.stringify(j, null, 2) + '\n');
  };
  flip('data/biomes/water.json', (j) => { j.floor.enabled = true; j.surface.enabled = true; });
  flip('data/director/interrupts.json', (j) => { j.water.enabled = true; });
  console.log('the floor is on in this copy');
}
