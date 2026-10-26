extends SceneTree
# An equirectangular map of a planet's biomes (and a hillshade of its heights), for looking at a generation:
#   godot --headless --path . --script res://sim/world/tools/planet_map.gd -- --seeds=7,3,11,25 --gens=1,2 --w=720 --out=<folder>
# --places marks the places on the fine and height pictures (a city a red square, a town a yellow one).
# --b turns land.json's b switch on for the run (Research's B plates, window 12; the files are planet-<seed>-gen2b-*.png).
# --edges draws the plates' edges on the height picture (red closing, blue parting, yellow neither); --height=0 leaves the height picture out.
# Writes <out>/planet-<seed>-gen<g>-height.png (heights by colour, sea to snow), <out>/planet-<seed>-gen<g>-stored.png (the stored biomes: what the renderer sees) and, for gen 2, -fine.png (the fine biomes) and prints the share of each biome and the cost a sample.
const LEGACY: Array = ["#2f5f9e", "#9bbf5a", "#3f7a3a", "#d9c27a", "#8b8479", "#eef3f7", "#c9dcea"]


func _init() -> void:
	var seeds: Array = [7, 3, 11, 25]
	var gens: Array = [1, 2]
	var w: int = 720
	var out: String = "."
	var edges: bool = false
	var places: bool = false
	var useB: bool = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(v): return int(v))
		if a.begins_with("--gens="):
			gens = Array(a.substr(7).split(",")).map(func(v): return int(v))
		if a.begins_with("--w="):
			w = int(a.substr(4))
		if a.begins_with("--out="):
			out = a.substr(6)
		if a == "--edges":
			edges = true
		if a == "--places":
			places = true
		if a == "--b":
			useB = true
	if useB:
		WorldLand.setB(true)   # Research's B plates for this run (window 12)
	var tag: String = "b" if useB else ""
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
			var imgH := Image.create(w, h, false, Image.FORMAT_RGB8)
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
					var hc: Color = _hcolor(P.outH)
					if edges and g >= 2:
						WorldLand._edge(P, c * SimDetMath.cos(lon), y, c * SimDetMath.sin(lon))
						if absf(WorldLand._eEdge) < 0.004:
							hc = Color(1.0, 0.15, 0.15) if WorldLand._eConv > 0.05 else (Color(0.2, 0.4, 1.0) if WorldLand._eConv < -0.05 else Color(0.95, 0.9, 0.2))
					imgH.set_pixel(k, r, hc)
					cntL[b] += 1
					if g >= 2:
						cntF[f] += 1
			var tMap: float = float(Time.get_ticks_usec() - t1)
			if places:
				for pi in range(P.n):
					var pxl: int = int(fposmod(atan2(P.pz[pi], P.px[pi]), SimMathx.TAU) / SimMathx.TAU * float(w)) % w
					var pyl: int = clampi(int((0.5 - asin(P.py[pi]) / SimMathx.PI) * float(h)), 0, h - 1)
					var big: int = 2 if int(P.kind[pi]) == WorldPlanet.KIND_CITY else 1
					var mc: Color = Color(0.95, 0.1, 0.1) if big == 2 else Color(1.0, 0.9, 0.1)
					for dy in range(-big, big + 1):
						for dx in range(-big, big + 1):
							var qx: int = (pxl + dx + w) % w
							var qy: int = clampi(pyl + dy, 0, h - 1)
							imgF.set_pixel(qx, qy, mc)
							imgH.set_pixel(qx, qy, mc)
			imgL.save_png("%s/planet-%d-gen%d%s-stored.png" % [out, sd, g, tag if g >= 2 else ""])
			imgH.save_png("%s/planet-%d-gen%d%s-height.png" % [out, sd, g, tag if g >= 2 else ""])
			if g >= 2:
				imgF.save_png("%s/planet-%d-gen%d%s-fine.png" % [out, sd, g, tag if g >= 2 else ""])
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


## Height as a colour: the sea blue to deep, the land green, tan, brown, white by 6,000 units.
func _hcolor(hh: float) -> Color:
	if hh < 0.0:
		return Color(0.12, 0.27, 0.52).lerp(Color(0.28, 0.5, 0.78), clampf(1.0 + hh / 3500.0, 0.0, 1.0))
	var t: float = clampf(hh / 6000.0, 0.0, 1.0)
	if t < 0.12:
		return Color(0.3, 0.6, 0.25).lerp(Color(0.62, 0.72, 0.38), t / 0.12)
	if t < 0.4:
		return Color(0.62, 0.72, 0.38).lerp(Color(0.62, 0.5, 0.33), (t - 0.12) / 0.28)
	if t < 0.7:
		return Color(0.62, 0.5, 0.33).lerp(Color(0.42, 0.34, 0.3), (t - 0.4) / 0.3)
	return Color(0.42, 0.34, 0.3).lerp(Color(1.0, 1.0, 1.0), (t - 0.7) / 0.3)
