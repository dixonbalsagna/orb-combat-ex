// SCRATCH HOOK (scratch export only): points window.__slicebench at MAIN's ring read instead of the old scratch planet library: World's ring_bench.gd in the page. Modes k1200, k2400,
// k4800 (the arena sizes): WorldPlanet.readSlice of seed 7's ring, best and first of reps, in microseconds a column. Apply after hook-slice.mjs; frame-bench.mjs --slice --slice-modes k1200,k4800.
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/tools/flash_capture.gd';
let s = readFileSync(p, 'utf8');
if (!s.includes('JavaScriptBridge.create_callback(_slice_bench)')) throw new Error('anchor: apply hook-slice.mjs first');
s = s.replace('JavaScriptBridge.create_callback(_slice_bench)', 'JavaScriptBridge.create_callback(_ring_bench)');
s += `

## SCRATCH: World's ring_bench.gd for one ring (seed 7): the read's time a column, in the page.
func _ring_bench(a: Array) -> void:
	var mode: String = str(a[0]) if a.size() > 0 else "k4800"
	var reps: int = int(a[1]) if a.size() > 1 else 3
	var cols: int = int(mode.trim_prefix("k"))
	var P := WorldPlanet.make(7)
	SimConst.setArena(cols)
	var T: Array = WorldPlanet.unitFromDraws(0.37, 0.62)
	var spec: Dictionary = WorldRingPick.roundSpec(T, cols, 0.9) if cols < 4800 else WorldRingPick.throughSpec(T, cols, 0.9)
	var ring: Dictionary = WorldRingPick.ringFrom(spec.c, cols, spec.t)
	var all: Array = []
	var best: float = 1.0e9
	var h: int = 0
	for rep in range(reps):
		var t0: int = Time.get_ticks_usec()
		var sl: WorldPlanet.Slice = WorldPlanet.readSlice(P, ring, ring.u)
		var ms: float = float(Time.get_ticks_usec() - t0) / 1000.0
		all.append(ms)
		best = minf(best, ms)
		h = WorldPlanet.sliceHash(sl)
	JavaScriptBridge.eval("window.__sliceResult = %s;" % JSON.stringify({"mode": mode, "best_ms": best, "all_ms": all, "us_col_best": best * 1000.0 / float(cols), "us_col_first": float(all[0]) * 1000.0 / float(cols), "hash": h}), true)
`;
writeFileSync(p, s); console.log('ring hook applied');
