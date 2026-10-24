extends SceneTree
# A side view of the ring a gen 1 and a gen 2 planet match play on, one under the other for each seed: the ground's height coloured by biome (stored biomes in the top strip of a pair, fine biomes in the
# bottom one), lakes in a lighter blue, trees as dark ticks, props as dots, a town's or a city's ground in brown and grey.
#   godot --headless --path . --script res://sim/world/tools/ground_strip.gd -- --seeds=7,3,11,25 --touch=0,0,0,0 --cols=2400 --out=<file.png>
const STORED: Array = ["#2f5f9e", "#9bbf5a", "#3f7a3a", "#d9c27a", "#8b8479", "#eef3f7", "#c9dcea", "#b58b5a", "#6b6f78"]
const SKY := Color("#d7e6f2")
const SEA := Color("#3d6fae")
const PER_PX: int = 2
const SH: int = 120


func _init() -> void:
	var seeds: Array = [7, 3, 11, 25]
	var touches: Array = [0, 0, 0, 0]
	var cols: int = 2400
	var out: String = "ground-strips.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(v): return int(v))
		if a.begins_with("--touch="):
			touches = Array(a.substr(8).split(",")).map(func(v): return int(v))
		if a.begins_with("--cols="):
			cols = int(a.substr(7))
		if a.begins_with("--out="):
			out = a.substr(6)
	var W: int = cols / PER_PX
	var rows: int = seeds.size() * 2
	var img := Image.create(W, rows * SH + (rows - 1) * 4, false, Image.FORMAT_RGB8)
	img.fill(Color.WHITE)
	var fine: Array = WorldClimate.data().fine
	var row: int = 0
	for si in range(seeds.size()):
		var arena: Dictionary = {"cols": cols}   # gen 1 chooses the ring; gen 2 plays on the same one (a pick scores biomes, so each generation would choose its own)
		for g in [1, 2]:
			var S := SimCore.createSim()
			SimCore.newMatch(S, 1, {}, {"planet": seeds[si], "touch": touches[si % touches.size()], "arena": arena, "planetGen": g, "intro": false})
			if g == 1:
				arena = {"cols": cols, "c": _hex3(S.planetRing.c), "t": _hex3(S.planetRing.t)}
			var NC: int = SimConst.NC
			var base: PackedFloat32Array = S.base
			var hmax: float = 1.0
			for i in range(NC):
				hmax = maxf(hmax, base[i])
			var y0: int = row * (SH + 4)
			var scale: float = float(SH - 8) / (hmax + 500.0)
			var fc: PackedByteArray = WorldBiomes.fineCols
			var pc: PackedByteArray = WorldBiomes.planetCols
			var treesBy := PackedInt32Array()
			treesBy.resize(W)
			for t in S.trees:
				treesBy[mini(W - 1, int(floor(SimWrap.wrap(t.x) / SimConst.COL)) / PER_PX)] += 1
			var tmax: Array = []
			tmax.resize(W)
			tmax.fill(0.0)
			for t in S.trees:
				var px: int = mini(W - 1, int(floor(SimWrap.wrap(t.x) / SimConst.COL)) / PER_PX)
				tmax[px] = maxf(float(tmax[px]), float(t.h))
			var propsAt: Dictionary = {}
			if g == 2:
				for p in WorldGround.propsIn(fc, pc, base, 99, 0, NC):
					propsAt[int(p.col) / PER_PX] = true
			for px in range(W):
				var i: int = px * PER_PX
				var h: float = base[i]
				var top: int = SH - 4 - int((h + 500.0) * scale)
				var sea: int = SH - 4 - int(500.0 * scale)
				var cl: Color
				if g == 2 and int(pc[i]) < 7:
					cl = Color.html(String(fine[int(fc[i])].color))
				else:
					cl = Color.html(STORED[int(pc[i])])
				var wtop: int = top   # a lake's surface: the water from there down to the ground
				if h >= 5.0 and S.water.size() > i and S.water[i] >= WorldWater.MIN_DEPTH:
					wtop = SH - 4 - int((h + S.water[i] + 500.0) * scale)
				for yy in range(SH):
					var c: Color = SKY
					if yy >= sea:
						c = SEA
					if yy >= wtop and yy < top:
						c = Color("#4f8fc9")
					if yy >= top:
						c = cl * (1.0 - 0.25 * float(yy - top) / float(SH)) if h >= 0.0 else SEA.darkened(0.15)
						c.a = 1.0
					img.set_pixel(px, y0 + yy, c)
				if g == 2 and tmax[px] > 0.0:
					var th: int = mini(18, 3 + int(float(tmax[px]) / 60.0))
					for yy in range(th):
						if top - 1 - yy >= 0:
							img.set_pixel(px, y0 + top - 1 - yy, Color("#1d3a1f"))
				if propsAt.has(px) and top - 1 >= 0 and tmax[px] == 0.0:
					img.set_pixel(px, y0 + top - 1, Color("#2a2a2a"))
			var nt: int = S.trees.size()
			print("seed %d touch %d gen %d: %d trees, hmax %.0f" % [seeds[si], touches[si % touches.size()], g, nt, hmax])
			row += 1
	img.save_png(out)
	quit()


## A float64 as the 16 hex digits SimMathx.f64 reads (high word first).
func _hex(v: float) -> String:
	var b := PackedByteArray()
	b.resize(8)
	b.encode_double(0, v)
	return "%08x%08x" % [b.decode_u32(4), b.decode_u32(0)]


func _hex3(a: Array) -> Array:
	return [_hex(a[0]), _hex(a[1]), _hex(a[2])]
