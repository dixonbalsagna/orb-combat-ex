// SCRATCH HOOK (scratch export only): World's gen 2 readiness benches in the page, behind window.__slicebench(mode, reps) so frame-bench.mjs --slice --slice-modes ... runs them (best, first and every
// rep in ms in the result). Gen 2 is switched on per call (WorldClimate.useGen, or setup.planetGen), nothing in data changes. Modes:
//   make1, make2        a planet's make, cold each rep (WorldPlanet.forget first); gen 2 adds the climate grid and the plates (World's gen_cost.gd set-up)
//   match1, match2      a planet match start (SimCore.newMatch, planet 7, touch 1, Half arena, turn on), cold each rep; `warm_ms` is a second start on the same planet
//   turn1:K, turn2:K    World's turn_ticks.gd: ask, choose (k = K columns a tick; 100000 as World measured), then WorldEpoch.tick with no hold until every ring is warm: each tick's ms
//                       (first 10 in `ticks_ms`), the number of ticks, the worst, and the swap tick
//   flow                the gen 2 planet's flow field (WorldRivers.flowOf), cold
//   water               WorldWater.step with four fill windows open, eight flow windows, and with nothing open (fill_check.gd's cost block)
// and for each: `mem_static_mb` (the engine's static-memory counter before and after; it reads 0 in some web builds). Apply after hook-slice.mjs.
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/tools/flash_capture.gd';
let s = readFileSync(p, 'utf8');
if (!s.includes('JavaScriptBridge.create_callback(_slice_bench)')) throw new Error('anchor: apply hook-slice.mjs first');
s = s.replace('JavaScriptBridge.create_callback(_slice_bench)', 'JavaScriptBridge.create_callback(_gen2_bench)');
s += `

func _gen2_setup(g: int, turn: bool) -> Dictionary:
	var d: Dictionary = {"planet": 7, "touch": 1, "arena": {"cols": 2400, "turn": turn}, "intro": false}
	if g == 2:
		d["planetGen"] = 2
	return d


func _gen2_bench(a: Array) -> void:
	var parts: PackedStringArray = str(a[0]).split(":")
	var mode: String = parts[0]
	var reps: int = int(a[1]) if a.size() > 1 else 3
	var res := {"mode": str(a[0])}
	var all: Array = []
	var m0: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	match mode:
		"make1", "make2":
			var g: int = 1 if mode == "make1" else 2
			for r in range(reps):
				WorldClimate.useGen(g)
				WorldPlanet.forget()
				var t0: int = Time.get_ticks_usec()
				var P := WorldPlanet.make(7)
				if g >= 2:
					WorldClimate.gridOf(P)
					WorldLand.platesOf(P)
				all.append(float(Time.get_ticks_usec() - t0) / 1000.0)
		"match1", "match2":
			var g2: int = 1 if mode == "match1" else 2
			for r in range(reps):
				WorldPlanet.forget()
				var t0: int = Time.get_ticks_usec()
				var S := SimCore.createSim()
				SimCore.newMatch(S, 1, {}, _gen2_setup(g2, true))
				all.append(float(Time.get_ticks_usec() - t0) / 1000.0)
			var t1: int = Time.get_ticks_usec()
			var S2 := SimCore.createSim()
			SimCore.newMatch(S2, 2, {}, _gen2_setup(g2, true))
			res["warm_ms"] = float(Time.get_ticks_usec() - t1) / 1000.0
		"turn1", "turn2":
			var g3: int = 1 if mode == "turn1" else 2
			var k: int = int(parts[1]) if parts.size() > 1 else 100000
			for r in range(reps):
				var S3 := SimCore.createSim()
				SimCore.newMatch(S3, 1, {}, _gen2_setup(g3, true))
				for t in range(30):
					SimCore.step(S3)
				S3.T = 100.0
				var mid: float = 0.5 * (S3.fighters[0].x + S3.fighters[1].x)
				if WorldEpoch.ask(S3, "t", mid, 1, 0).is_empty():
					res["error"] = "no turn asked"
					break
				WorldEpoch.choose(S3, 3)
				S3.epoch.next.k = k
				var times: Array = []
				var n: int = 0
				while WorldEpoch.warmAngles(S3).size() < S3.epoch.warm.size() and n < 400:
					var t0: int = Time.get_ticks_usec()
					WorldEpoch.tick(S3, false)
					times.append(float(Time.get_ticks_usec() - t0) / 1000.0)
					n += 1
				var t1: int = Time.get_ticks_usec()
				WorldEpoch.tick(S3, true)
				var swap: float = float(Time.get_ticks_usec() - t1) / 1000.0
				var worst: float = 0.0
				for x in times:
					worst = maxf(worst, float(x))
				all.append(float(times[0]) if times.size() > 0 else -1.0)   # the first warm tick, the headline
				res["ticks_ms"] = times.slice(0, 10)
				res["ticks_n"] = n
				res["worst_ms"] = worst
				res["swap_ms"] = swap
		"flow":
			for r in range(reps):
				WorldClimate.useGen(2)
				WorldPlanet.forget()
				var P := WorldPlanet.make(7)
				WorldClimate.gridOf(P)
				var t0: int = Time.get_ticks_usec()
				WorldRivers.flowOf(P)
				all.append(float(Time.get_ticks_usec() - t0) / 1000.0)
		"water":
			WorldFill.K_ON = true
			var Sc := SimCore.createSim()
			SimCore.newMatch(Sc, 1, {}, {"intro": false})
			Sc.base.fill(30.0)
			Sc.deform.fill(0.0)
			Sc.rubble.fill(0.0)
			Sc.scorch.fill(0.0)
			Sc.buildings.clear()
			Sc.trees.clear()
			Sc.craters.clear()
			WorldWater.init(Sc)
			for k2 in range(4):
				var c0: int = 1000 + k2 * 300
				Sc.waterWin.append([c0, 120, 0, 0, 1, 0, c0, 0.0, 40.0, c0, 0])
				for i in range(c0 - 6, c0 + 7):
					Sc.deform[i] = -60.0
			Sc.waterTick = 1.0
			var nrep: int = 50
			var t0: int = Time.get_ticks_usec()
			for r in range(nrep):
				for w in Sc.waterWin:
					w[2] = 0
					w[3] = 0
				Sc.waterTick = 1.0
				WorldWater.step(Sc)
			all.append(float(Time.get_ticks_usec() - t0) / float(nrep))   # microseconds a step, four fills open
			var Sg := SimCore.createSim()
			SimCore.newMatch(Sg, 1, {}, {"intro": false})
			Sg.waterWin.clear()
			for k3 in range(8):
				Sg.waterWin.append([2000 + k3 * 600, 240, 0, 0])
			t0 = Time.get_ticks_usec()
			for r in range(nrep):
				for w in Sg.waterWin:
					w[2] = 0
					w[3] = 0
				Sg.waterTick = 1.0
				WorldWater.step(Sg)
			res["flow_windows_us"] = float(Time.get_ticks_usec() - t0) / float(nrep)
			var Sn := SimCore.createSim()
			SimCore.newMatch(Sn, 1, {}, {"intro": false})
			t0 = Time.get_ticks_usec()
			for r in range(20000):
				WorldWater.step(Sn)
			res["idle_us"] = float(Time.get_ticks_usec() - t0) / 20000.0
			WorldFill.K_ON = false
	WorldClimate.useGen(0)
	var best: float = 1.0e12
	for x in all:
		best = minf(best, float(x))
	res["best_ms"] = best
	res["all_ms"] = all
	res["mem_static_mb"] = [m0, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0]
	JavaScriptBridge.eval("window.__sliceResult = %s;" % JSON.stringify(res), true)
`;
writeFileSync(p, s); console.log('gen2 hook applied');
