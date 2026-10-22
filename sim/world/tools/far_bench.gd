extends SceneTree
# What a far read costs a sample, that the bulk read is farColumn's own, and how far the coarse read is from it:  godot --headless --path . --script res://sim/world/tools/far_bench.gd
func _init() -> void:
	var P := WorldPlanet.make(7)
	for cols in [2400, 4800]:
		SimConst.setArena(cols)
		var T: Array = WorldPlanet.unitFromDraws(0.37, 0.62)
		var spec: Dictionary = WorldRingPick.roundSpec(T, cols, 0.9) if cols < 4800 else WorldRingPick.throughSpec(T, cols, 0.9)
		var ring: Dictionary = WorldRingPick.ringFrom(spec.c, cols, spec.t)
		var depths := PackedFloat64Array([-40000.0, -20000.0, -9000.0, -4000.0, -2000.0, 2000.0, 3000.0, 4000.0, 6000.0, 9000.0, 15000.0, 26000.0, 40000.0])
		var c0: int = 1000 % cols
		var nc: int = 300
		var stride: int = cols / 300
		var n: int = nc * depths.size()
		var t0: int = Time.get_ticks_usec()
		var ref := PackedFloat64Array()
		ref.resize(n)
		var refb := PackedByteArray()
		refb.resize(n)
		for ci in range(nc):
			for di in range(depths.size()):
				var r: Array = WorldPlanet.farColumn(P, ring, c0 + ci * stride, depths[di])
				ref[di * nc + ci] = r[0]
				refb[di * nc + ci] = r[1]
		var tCol: float = float(Time.get_ticks_usec() - t0)
		t0 = Time.get_ticks_usec()
		var ex: Dictionary = WorldPlanet.farField(P, ring, c0, nc, stride, depths)
		var tEx: float = float(Time.get_ticks_usec() - t0)
		t0 = Time.get_ticks_usec()
		var co: Dictionary = WorldPlanet.farField(P, ring, c0, nc, stride, depths, 1500.0)
		var tCo: float = float(Time.get_ticks_usec() - t0)
		var same: bool = true
		for i in range(n):
			if ex.h[i] != ref[i] or ex.b[i] != refb[i]:
				same = false
		print("== arena %d columns, %d columns x %d depths = %d samples" % [cols, nc, depths.size(), n])
		print("farColumn, column by column: %6.1f us a sample (%.0f ms)" % [tCol / n, tCol / 1000.0])
		print("farField, exact:             %6.1f us a sample (%.0f ms)   identical to farColumn (heights and biomes): %s" % [tEx / n, tEx / 1000.0, str(same)])
		print("farField, coarse past 1,500: %6.1f us a sample (%.0f ms)" % [tCo / n, tCo / 1000.0])
		var mapsize: int = 360
		for ms in [160, 224, 288, 360]:
			if cols == 4800 and ms != 224:
				continue
			var tb: int = Time.get_ticks_usec()
			var fm := WorldFarMap.new(P, ms)
			fm.step(1000000)
			var tBuild: float = float(Time.get_ticks_usec() - tb)
			var tf: int = Time.get_ticks_usec()
			var mf: Dictionary = fm.field(ring, c0, nc, stride, depths)
			var tField: float = float(Time.get_ticks_usec() - tf)
			var sm2: float = 0.0
			var mx2: float = 0.0
			var bd2: int = 0
			var hi: int = 0
			for i in range(n):
				var d2: float = absf(mf.h[i] - ref[i])
				sm2 += d2
				mx2 = maxf(mx2, d2)
				if mf.b[i] != refb[i]:
					bd2 += 1
				if d2 > 100.0:
					hi += 1
			print("map %dx%d: build %.0f ms (%.1f us a texel); a far field from it %.2f us a sample (%.0f ms); against the exact read: mean |dh| %.1f, max %.1f, over 100 units %.1f%%, biome differs %.1f%%" % [ms, ms, tBuild / 1000.0, tBuild / float(ms * ms), tField / n, tField / 1000.0, sm2 / n, mx2, 100.0 * float(hi) / n, 100.0 * float(bd2) / n])
		print("   depth z   mean |dh|  max |dh|   biome differs")
		for di in range(depths.size()):
			var sm: float = 0.0
			var mx: float = 0.0
			var bd: int = 0
			for ci in range(nc):
				var i: int = di * nc + ci
				var d: float = absf(co.h[i] - ref[i])
				sm += d
				mx = maxf(mx, d)
				if co.b[i] != refb[i]:
					bd += 1
			print("  %8.0f  %8.1f  %8.1f   %4.1f%%" % [depths[di], sm / nc, mx, 100.0 * float(bd) / float(nc)])
	quit()
