#!/usr/bin/env node
// The match's props for Art's look before Combat's biome block turns on (docs/rendering/props.md): a scratch hook that lets
// a page switch the block on and stage a PROP SMASH. It edits a scratch copy of the game (git archive into a folder of
// your own), never the repo.
//
//   node docs/rendering/tools/props-hook.mjs <scratch tree>
//
// Page words it adds (main's URL_ARGS, in the scratch copy only: the shipped page takes neither):
//   ?biomeon=1     Combat's biome block on for the page (DirLaunch.forceBiome), so the props are laid and drawn
//   ?propsmash=1   the same, and 30 ticks into a gen 2 match the pair is set down at the ring's first spot where the
//                  planner offers PROP SMASH (render/tools/props_check.gd finds spots the same way); at tick 90 the
//                  launch is made with the planner's own plan. Once a match. The page sets window.__psLaunched = 1 at
//                  the launch and window.__psBroke = 1 on the first frame a prop is broken (capture.mjs --wait-js).
// A gen 2 match on the page: Performance's pb scene (docs/perf/tools/scratch-hooks/hook-perf.mjs, hook-slice.mjs,
// hook-pbiome.mjs: ?scene=pb&pgen=2&pplanet=7&pbiome=desert), or World's planet picker.
// Then stills through Tools' launcher: node tools/machine/capture.mjs still --dir <export> --path "/index.html?..." --out a.png --wait-ms 4000.
// Node 24 built-ins only. No Godot, no browser. Owner: Rendering and Technical Art.
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const root = process.argv[2];
if (!root || !existsSync(join(root, 'project.godot'))) { console.error('usage: node docs/rendering/tools/props-hook.mjs <scratch tree holding project.godot>'); process.exit(2); }
const f = join(root, 'render/core/main.gd');
let s = readFileSync(f, 'utf8');
const once = (a) => s.split(a).length === 2;
const edits = [
  ['const URL_ARGS: Array = ["', 'const URL_ARGS: Array = ["biomeon", "propsmash", "'],
  ['\tPlanetView.view_fast = not args.has("noviewfast")', '\tif args.has("biomeon") or args.has("propsmash"):\n\t\tDirLaunch.forceBiome = 1   # SCRATCH (props-hook.mjs)\n\tPlanetView.view_fast = not args.has("noviewfast")'],
  ['func render_view(a: float) -> void:\n', 'func render_view(a: float) -> void:\n\t_props_stage()   # SCRATCH (props-hook.mjs)\n'],
];
for (const [a, b] of edits) {
  if (!once(a)) { console.error(`props-hook: main.gd's anchor is missing or not once: ${a.slice(0, 60)}`); process.exit(1); }
  s = s.replace(a, () => b);
}
s += `

## SCRATCH (docs/rendering/tools/props-hook.mjs): ?propsmash=1 stages a PROP SMASH in a gen 2 match: at tick 30 the pair
## is set down at the ring's first spot where the planner offers it, and at tick 90 the launch is made.
var _ps_S: SimState = null
var _ps_spot: Array = []
var _ps_live: bool = false
func _props_stage() -> void:
	if not args.has("propsmash") or host.loading():
		return
	var S: SimState = host.S
	var PC = load("res://render/tools/props_check.gd")
	if _ps_live and SimDir.brokenProps(S).size() > 0:
		_ps_live = false
		if OS.has_feature("web"):
			JavaScriptBridge.eval("window.__psBroke = 1", true)
	if _ps_S != S and host.ticks >= 30:
		_ps_S = S
		_ps_spot = []
		for col in range(0, SimConst.NC, 4):
			var x: float = (float(col) + 0.5) * SimConst.COL
			for sg in [1.0, -1.0]:
				PC._pose(S, x, sg)
				if PC._offered(S).has("PROP SMASH"):
					_ps_spot = [x, sg]
					return
	elif _ps_S == S and not _ps_spot.is_empty() and host.ticks >= 90:
		PC._pose(S, float(_ps_spot[0]), float(_ps_spot[1]))
		_ps_spot = []
		var A = S.fighters[0]
		var D = S.fighters[1]
		var ex = DirExchange.newEx(A, D, "props-hook")
		S.dirS.ex = ex
		D.state = "locked"
		for k in DirLaunch.chooseLaunch(S, A, D, PC._force()).all:
			if String(k.name) == "PROP SMASH":
				DirLaunch.doLaunch(S, A, D, k, PC._force())
				_ps_live = true
				if OS.has_feature("web"):
					JavaScriptBridge.eval("window.__psLaunched = 1", true)
				return
`;
writeFileSync(f, s);
console.log(`props-hook applied to ${root}`);
