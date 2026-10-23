extends SceneTree
# An equirectangular map of a planet's biomes (and a hillshade of its heights), for looking at a generation:
#   godot --headless --path . --script res://sim/world/tools/planet_map.gd -- --seeds=7,3,11,25 --gens=1,2 --w=720 --out=<folder>
# Writes <out>/planet-<seed>-gen<g>-stored.png (the stored biomes: what the renderer sees) and, for gen 2, -fine.png (the fine biomes) and prints the share of each biome and the cost a sample.
const LEGACY: Array = ["#2f5f9e", "#9bbf5a", "#3f7a3a", "#d9c27a", "#8b8479", "#eef3f7", "#c9dcea"]


func _init() -> void:
	var seeds: Array = [7, 3, 11, 25]
	var gens: Array = [1, 2]
	var w: int = 720
	var out: String = "."
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(v): return int(v))
		if a.begins_with("--gens="):
			gens = Array(a.substr(7).split(",")).map(func(v): return int(v))
		if a.begins_with("--w="):
			w = int(a.substr(4))
		if a.begins_with("--out="):
			out = a.substr(6)
	var h: int = w / 2
	var fine: Array = WorldClimate.data().fine
	for sd in seeds:
		for g in gens:
			WorldClimate.useGen(g)
			var P := WorldPlanet.make(sd)
			var t0: int = Time.get_ticks_usec()
			if g >= 2:
				WorldClimate.gridOf(P)
			var tGrid: float = float(Time.get_ticks_usec() - t0)
			var imgL := Image.create(w, h, false, Image.FORMAT_RGB8)
			var imgF := Image.create(w, h, false, Image.FORMAT_RGB8)
			var cntL := PackedInt32Array()
			cntL.resize(7)
			var cntF := PackedInt32Array()
			cntF.resize(fine.size())
			var t1: int = Time.get_ticks_usec()
			for r in range(h):
				var lat: float = (0.5 - (float(r) + 0.5) / float(h)) * SimMathx.PI
				var y: float = SimDetMath.sin(lat)
				var c: float = SimDetMath.cos(lat)
				for k in range(w):
					var lon: float = (float(k) + 0.5) / float(w) * SimMathx.TAU
					WorldPlanet.surfAt(P, c * SimDetMath.cos(lon), y, c * SimDetMath.sin(lon))
					var b: int = P.outB
					var f: int = P.outF if P.outF >= 0 else b
					var shade: float = 0.82 + 0.18 * minf(1.0, maxf(0.0, P.outH) / 2500.0) if P.outH > 0.0 else 1.0 - 0.25 * minf(1.0, -P.outH / 3000.0)
					var cl: Color = Color.html(LEGACY[b]) * shade
					cl.a = 1.0
					imgL.set_pixel(k, r, cl)
					var cf: Color = Color.html(String(fine[f].color)) * shade if g >= 2 else cl
					cf.a = 1.0
					imgF.set_pixel(k, r, cf)
					cntL[b] += 1
					if g >= 2:
						cntF[f] += 1
			var tMap: float = float(Time.get_ticks_usec() - t1)
			imgL.save_png("%s/planet-%d-gen%d-stored.png" % [out, sd, g])
			if g >= 2:
				imgF.save_png("%s/planet-%d-gen%d-fine.png" % [out, sd, g])
			var tot: float = float(w * h)
			var sl: String = ""
			for b in range(7):
				sl += " %s %.0f%%" % [["ocean", "plains", "forest", "desert", "mtn", "ice", "seaice"][b], 100.0 * float(cntL[b]) / tot]
			print("seed %d gen %d: grid %.0f ms, %d samples at %.1f us; stored:%s" % [sd, g, tGrid / 1000.0, w * h, tMap / tot, sl])
			if g >= 2:
				var sf: String = ""
				for f in range(fine.size()):
					sf += " %s %.1f%%" % [fine[f].name, 100.0 * float(cntF[f]) / tot]
				print("   fine:" + sf)
	WorldClimate.useGen(0)
	quit()
