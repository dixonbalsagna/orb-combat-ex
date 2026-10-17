// Scratch: the planet-slice strip read (World's strip_time2.gd) callable from the page as window.__slicebench(mode, reps).
import { readFileSync, writeFileSync, mkdirSync, copyFileSync } from 'node:fs';
const root = process.argv[2], lib = process.argv[3];
mkdirSync(root + '/scratch', { recursive: true });
copyFileSync(lib, root + '/scratch/planet2_lib.gd');
const p = root + '/render/tools/flash_capture.gd';
let s = readFileSync(p, 'utf8');
s = s.replace("func _init(m: Node) -> void:\n\tmain = m\n", "func _init(m: Node) -> void:\n\tmain = m\n\t_slice_cb = JavaScriptBridge.create_callback(_slice_bench)\n\tJavaScriptBridge.get_interface(\"window\").__slicebench = _slice_cb\n");
if (!s.includes('_slice_cb = ')) throw new Error('init anchor missing');
s += `

var _slice_cb: JavaScriptObject = null
const SliceLib = preload("res://scratch/planet2_lib.gd")

## SCRATCH: World's 4,800-column strip read (planet-slice/strip_time2.gd), best of reps, mode "equator" or "poles".
func _slice_bench(a: Array) -> void:
	var mode: String = str(a[0]) if a.size() > 0 else "equator"
	var reps: int = int(a[1]) if a.size() > 1 else 3
	var P = SliceLib.new()
	var u := Vector3(1, 0, 0)
	var v := Vector3(0, 0, 1) if mode == "equator" else Vector3(0, 1, 0)
	var best: float = 1.0e9
	var all: Array = []
	for rep in range(reps):
		var t0: int = Time.get_ticks_usec()
		var hs := PackedFloat32Array()
		hs.resize(4800)
		for i in range(4800):
			var p: Vector3 = P.rot(u, v, float(i) * 32.0 / P.R)
			var sf: Array = P.surf(p)
			hs[i] = sf[0] + (P.fbm(p, 1500.0, 3, P.seed + 777) - 0.5) * 300.0
			P.biome(p, sf[0])
		var ms: float = float(Time.get_ticks_usec() - t0) / 1000.0
		all.append(ms)
		best = minf(best, ms)
	JavaScriptBridge.eval("window.__sliceResult = %s;" % JSON.stringify({"mode": mode, "best_ms": best, "all_ms": all}), true)
`;
writeFileSync(p, s);
console.log('slice hook applied to', root);
