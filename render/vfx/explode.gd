class_name VfxExplode
extends RefCounted
## An energy blast going off (Orb, 2026-10-02: blasts "erupt into flame and smoke, explosive particles"). Used by shots.gd at a shot's

## it goes off:
##
##   ground   a flame burst (the cel flames: a pale core, orange, then the dark of the smoke), sparks, thrown chunks of the ground's own
##            earth, a flat ring running out along the ground, dark smoke rising, and a scorch that smoulders for a few seconds
##            (wisps of smoke and the odd ember at the point; the crater itself is World's `crater` event)
##   fighter  the same without the chunks and the ring, and shorter: a flame burst, sparks and a little smoke at the body; a guard
##            or a deflect gives sparks and smoke only
##   water    steam: pale puffs rising off the surface and a few sparks (the water plunge is the water effects')
##
## Everything goes into the shared debris pool (no draw call), with a fixed number of draws per call from the cosmetic streams
## (vfx.dust, vfx.shard), so nothing here depends on the quality level; quality only decides how many of the drawn bits are kept.
## Colours: the flames are the cel flame's own (an orange body, a lighter mid and a pale core: fire, not a body aura and not a flash on
## a body), the sparks Art's ember ramp, the smoke and the chunks the biome's own shades. Presentation only.

const DEFAULTS: Dictionary = {
	"explode": {"flames": 7.5, "sparks": 9.0, "chunks": 5.0, "smoke": 4.0, "ring_r0": 0.3, "ring_r1": 1.15, "ring_life": 0.42,
		"smoulder": 6.0, "smoulder_from": 0.5, "smoulder_to": 3.6, "steam": 5.0, "fighter_k": 0.75, "flame_cap": 48.0, "ref_bh": 1.5,
		# Orb, 2026-10-16: the small energy attacks' explosions "more explosive, flames and smoke". The scale of a small blast never falls under `scale_floor`; its flames go off in three waves
		# (`wave1_s`, `wave2_s` seconds after the first, `wave_split` the shares of the three) and grow in over a few ticks (shard_view), so no single frame is a flash; `calm` is the share
		# a blast the register refused keeps of its sparks.
		"scale_floor": 0.62, "wave1_s": 0.07, "wave2_s": 0.14, "wave_split": 0.45, "wave_split2": 0.3, "smoke_late": 2.0, "smoke_k": 1.35, "calm": 0.7, "lane_cinders": 0.0},
}

static var _data: Dictionary = {}
static var _loaded: bool = false


static func warm() -> void:
	if _loaded:
		return
	_loaded = true
	var path := "res://data/vfx/shots.json"
	if FileAccess.file_exists(path):
		var v = JSON.parse_string(FileAccess.get_file_as_string(path))
		if v is Dictionary:
			_data = v


static func p(key: String) -> float:
	warm()
	var g = _data.get("explode")
	if g is Dictionary and g.has(key):
		return float(g[key])
	return float(DEFAULTS["explode"][key])


## The blast radius in world units (agency-pass.md 15.1) for a kind of shot at a damage and the shooter's tier: a bolt or shard 0.5 bh,
## an arc 1 bh, a lob (or burst) 1.5 bh, a charged shot 1.5 bh tapped and 2 bh fully charged (damage 60 or more of its 66); times 1.25
## at tier 3 and 1.5 at tier 4.
static func radius_for(kind: String, dmg: float, tier: int) -> float:
	var bh: float
	match kind:
		"bolt", "shard":
			bh = 0.5
		"arc":
			bh = 1.0
		"lob":
			bh = 1.5
		"mine":
			bh = 2.0
		"charged":
			# 1.5 bh tapped (0.6 of the kind's damage) rising to 2 bh fully charged (all of it).
			bh = lerpf(1.5, 2.0, clampf((dmg / kind_dmg("charged") - 0.6) / 0.4, 0.0, 1.0))
		_:
			bh = 0.5
	var tf: float = 1.5 if tier >= 4 else (1.25 if tier == 3 else 1.0)
	return bh * VfxLook.BH * tf


## A kind's full damage (data/fight/shots.json, the sim's), for how charged a charged shot was.
static func kind_dmg(kind: String) -> float:
	if SimShots.kinds.has(kind):
		return maxf(float(SimShots.kinds[kind].dmg), 1.0)
	return {"bolt": 13.0, "shard": 5.2, "arc": 52.8, "charged": 82.5, "lob": 66.0, "mine": 52.8}.get(kind, 13.0)


## How long its smoke stays, seconds, for show (2 for the smallest, 5 for the largest).
static func smoke_s(radius: float) -> float:
	return clampf(1.0 + 2.0 * radius / VfxLook.BH, 2.0, 5.0)


## The share of the full effect a blast of this radius makes: 1 at 1.5 bh.
static func scale_for(radius: float) -> float:
	return clampf(radius / (p("ref_bh") * VfxLook.BH), p("scale_floor"), 2.4)


static func _q(d: VfxDebris) -> float:
	return VfxLook.QUALITY_SHARDS[clampi(d.quality, 0, 2)] * (0.5 if d.reduced else 1.0)


## Whether a burst on a body may put up smoke (Orb, 2026-10-18: the grey blobs beside the fighters read as blur): not while he is in the air, not in a beam struggle, and then one small puff.
## Smoke at a landing is for the ground it lands on; a clean contact in the air is flame, sparks and light.
static func fighter_smoke(S, x: float, y: float) -> bool:
	if S == null:
		return true
	if S.game.clash != null:
		return false
	return y - WorldTerrain.groundY(S, x) < 1.5 * VfxLook.BH


## radius: the blast radius (radius_for). surface: "ground", "fighter" (a body), "air" (a burst in the air: no ground), "wall" (against a
## building's face: concrete chips and dust, no ring) or "water". mode: "burst" (a flame burst, the default), "spark" (sparks and smoke only: a guard or a deflect).
## Returns how many bits it asked the pool for (the tests and the budget).
static func at(S: SimState, d: VfxDebris, x: float, y: float, z: float, radius: float, surface: String, mode: String = "burst", lane: Color = Color(0.0, 0.0, 0.0, 0.0)) -> int:
	var rd: SimRng = d._rd
	var q: float = _q(d)
	var s: float = scale_for(radius) * (p("fighter_k") if surface == "fighter" else (0.8 if surface == "air" else (0.75 if surface == "wall" else 1.0)))
	var smoke_life: float = smoke_s(radius)
	var biome: String = VfxPalette.biome_key(x)
	var asked: int = 0
	var on_body: bool = surface == "fighter"
	var smoke_ok: bool = (not on_body) or fighter_smoke(S, x, y)
	var edge: float = 38.0 if on_body else 0.0        # (Orb, 2026-10-22: the flame tongues at a landing stood over the fighter's body) on a body the flames spring from his two edges and stand behind his plane
	var zf: float = z - 14.0 if on_body else z
	var flame_cap: int = int(round(p("flame_cap") * (0.5 + 0.5 * q)))
	# Flames: a burst going up and out, the larger ones taller. In three waves (the first now, the others a few ticks on, as jobs) and each flame grows in over a few ticks (shard_view): so the
	# burst is never one frame's flash (Legal fx03: an explosion's fire grows over several ticks).
	var nf: int = 0 if (mode == "spark" or surface == "water") else clampi(int(round(p("flames") * s * (0.6 if surface == "wall" else 1.0))), 3 if surface != "wall" else 2, 11)
	if nf > 0:
		var n0: int = maxi(1, int(round(float(nf) * p("wave_split"))))
		var n1: int = maxi(1, int(round(float(nf) * p("wave_split2"))))
		var n2: int = maxi(0, nf - n0 - n1)
		asked += _flame_wave(d, rd, x, y, zf, s, n0, q, flame_cap, 0.0, edge)
		var wave_job := func(delay: float, n: int, spread: float) -> void:
			if n <= 0:
				return
			var j := VfxDebris.Job.new()
			j.at = d.now + delay
			j.kind = "xwave"
			j.a = {"x": x, "y": y, "z": zf, "edge": edge, "s": s, "n": n, "q": q, "cap": flame_cap, "spread": spread, "smoke": int(round(p("smoke_late"))) if (delay > p("wave1_s") and not on_body) else 0, "sm": smoke_life}
			d.jobs.append(j)
		wave_job.call(p("wave1_s"), n1, 1.25)
		wave_job.call(p("wave2_s"), n2, 1.5)
	# Sparks: bright cinders thrown out, stepped through Art's ember ramp by age.
	var nsp: int = clampi(int(round(p("sparks") * s * (p("calm") if mode == "calm" else 1.0))), 3, 18)
	for i in range(nsp):
		var ang: float = rd.range_(0.15, PI - 0.15)
		var spd: float = rd.range_(220.0, 520.0) * (0.6 + 0.4 * s)
		var life2: float = rd.range_(0.45, 1.05) * (0.7 if surface == "fighter" else 1.0)         # on a body the cinders are smaller and shorter-lived: a chip of char the size of a hand across a close fight read as debris
		var len: float = rd.range_(22.0, 48.0) * (0.7 + 0.3 * s) * (0.55 if surface == "fighter" else 1.0)
		var keep2: bool = rd.next() < q and d._ember_tick < VfxLook.EMBER_PER_TICK and d._ember_alive < VfxLook.EMBER_CAP
		if keep2:
			var b: VfxDebris.Bit = d._bit(VfxDebris.EMBER, x + rd.range_(-14.0, 14.0), y + 8.0, z + 10.0, cos(ang) * spd, sin(ang) * spd, 0.5, life2)
			b.col = VfxPalette.ember("hot")
			if lane.a > 0.0 and rd.next() < p("lane_cinders"):
				b.col = lane.lightened(0.25)            # a cinder of the shooter's own energy: the fighter's flavour in the blast (never white)
				b.col2 = Color(0.0, 0.0, 0.0, 0.0)      # off Art's ember ramp, so it keeps the lane colour
			b.sx = len
			b.sy = 8.0
			b.grav = 520.0
			b.spin = 0.0
			b.rot = ang
			d._ember_tick += 1
			d._ember_alive += 1
			d._add(b)
			asked += 1
	# Smoke: dark puffs rising off the burst.
	var nsm: int = (1 if smoke_ok else 0) if on_body else clampi(int(round(p("smoke") * s * p("smoke_k"))), 2, 9)
	for i in range(nsm):
		var sz2: float = rd.range_(44.0, 78.0) * (0.55 + 0.6 * s) * 1.15 * (0.5 if on_body else 1.0)
		var life3: float = rd.range_(0.6, 1.0) * smoke_life
		var dx: float = (signf(rd.range_(-1.0, 1.0)) * rd.range_(44.0, 70.0)) if on_body else rd.range_(-26.0, 26.0)       # on a body the puff stands clear of him, never over his sprite
		var keep3: bool = rd.next() < q
		if keep3 and not (d.reduced and i > 1):
			d.smoke(x + dx, y + 30.0 + rd.range_(0.0, 30.0), z - 2.0, sz2, life3)
			asked += 1
	if surface == "wall":
		# A building's face: chips of its own concrete thrown out and falling, and pale dust off it; nothing on the ground.
		var ctones: Array = VfxEarth.tones_for_col("#77808f", x)["t"]
		var nw: int = clampi(int(round(p("chunks") * s)), 2, 8)
		for i in range(nw):
			var vx3: float = rd.range_(-1.0, 1.0) * rd.range_(120.0, 380.0) * (0.6 + 0.4 * s)
			var vy3: float = rd.range_(150.0, 520.0) * (0.6 + 0.4 * s)
			var sz5: float = rd.range_(8.0, 17.0) * (0.7 + 0.4 * s)
			var life5: float = rd.range_(0.9, 1.6)
			var keep6: bool = rd.next() < q
			if keep6:
				d.chunk(x + rd.range_(-18.0, 18.0), y + rd.range_(-12.0, 12.0), z + 8.0, vx3, vy3, sz5, life5, ctones, 0, 7.0)
				asked += 1
		var ndu: int = clampi(int(round(3.0 * s)), 1, 5)
		for i in range(ndu):
			var sz6: float = rd.range_(34.0, 60.0) * (0.6 + 0.5 * s)
			var keep7: bool = rd.next() < q
			if keep7:
				d.dust_puff("city", x + rd.range_(-30.0, 30.0), y + rd.range_(-20.0, 20.0), z + rd.range_(0.0, 20.0), rd.range_(-40.0, 40.0), rd.range_(30.0, 90.0), sz6 * 0.6, sz6 * 1.7, rd.range_(1.0, 1.8), 2)
				asked += 1
	elif surface == "ground":
		# Chunks of the ground's own earth, thrown and falling.
		var tones: Array = VfxEarth.tones_for_surface("soil", x)
		var nc: int = clampi(int(round(p("chunks") * s)), 2, 10)
		for i in range(nc):
			var sx: float = rd.range_(-1.0, 1.0)
			var vx2: float = sx * rd.range_(160.0, 420.0) * (0.6 + 0.5 * s)
			var vy2: float = rd.range_(380.0, 860.0) * (0.6 + 0.5 * s)
			var sz3: float = rd.range_(9.0, 19.0) * (0.7 + 0.4 * s)
			var life4: float = rd.range_(1.0, 1.8)
			var keep4: bool = rd.next() < q
			if keep4:
				d.chunk(x + rd.range_(-24.0, 24.0), y + 8.0, z + 8.0, vx2, vy2, sz3, life4, tones, 2, 9.0)
				asked += 1
		# The flat ring along the ground.
		if not d.reduced:
			var r0: float = p("ring_r0") * radius
			var r1: float = p("ring_r1") * radius
			d._biome = biome
			d._ring(x, y + 14.0, z + 6.0, r0, (r1 - r0) / p("ring_life"), p("ring_life"), true)
			asked += 1
		# The scorch smoulders for a few seconds: a wisp of smoke and the odd ember at the point, one at a time.
		var nsc: int = clampi(int(round(p("smoulder") * s)), 0, 10)
		var t0: float = d.now
		for i in range(nsc):
			var j := VfxDebris.Job.new()
			j.at = t0 + lerpf(p("smoulder_from"), p("smoulder_to"), float(i) / maxf(float(nsc - 1), 1.0))
			j.kind = "smoulder"
			j.a = {"x": x, "y": y, "z": z, "w": 0.4 * radius, "ember": i % 3 == 1, "q": q, "life": smoke_life}
			d.jobs.append(j)
	elif surface == "water":
		# Steam: pale puffs off the surface, and a few sparks above (the plunge itself is the water effects').
		var nst: int = clampi(int(round(p("steam") * s)), 1, 8)
		for i in range(nst):
			var sz4: float = rd.range_(50.0, 90.0) * (0.55 + 0.6 * s)
			var keep5: bool = rd.next() < q
			if keep5:
				d.dust_puff("ocean", x + rd.range_(-40.0, 40.0), y + rd.range_(0.0, 20.0), z + rd.range_(0.0, 20.0), rd.range_(-30.0, 30.0), rd.range_(70.0, 150.0), sz4 * 0.6, sz4 * 1.8, rd.range_(1.2, 2.0), 2)
				asked += 1
	return asked


## One wave of flames: n tongues going up and out from (x, y), the first wave tight and the later ones spread wider (`spread`), at the blast's scale s. Returns how many it asked the pool for.
static func _flame_wave(d: VfxDebris, rd: SimRng, x: float, y: float, z: float, s: float, n: int, q: float, cap: int, spread: float, edge: float = 0.0) -> int:
	var asked: int = 0
	var k: float = 1.0 + spread
	for i in range(n):
		var side: float = -1.0 + 2.0 * (float(i) + 0.5) / float(maxi(n, 1))
		var vx: float = side * rd.range_(80.0, 220.0) * s * k + rd.range_(-30.0, 30.0)
		var vy: float = rd.range_(90.0, 200.0) * (0.6 + 0.4 * s) * (1.0 + 0.1 * spread) * (0.55 if edge > 0.0 else 1.0)       # local and in proportion: a flame tongue rises about its blast radius, never a pillar
		var sz: float = rd.range_(26.0, 52.0) * (0.55 + 0.6 * s) * (1.0 + 0.12 * spread) * (0.7 if edge > 0.0 else 1.0)
		var life: float = rd.range_(0.45, 0.85) * (0.7 + 0.3 * s)
		var keep: bool = rd.next() < q and d._flame_alive < cap
		if keep:
			var fx0: float = (x + signf(side + 0.0001) * (edge + rd.range_(0.0, 14.0))) if edge > 0.0 else (x + rd.range_(-30.0, 30.0) * s * k)       # on a body the tongues stand at his edges, never over him
			d.flame(fx0, y + rd.range_(0.0, 24.0), z + 6.0, vx, vy, sz, life)
			asked += 1
	return asked


## A job that came due: one wisp of the smouldering scorch, or a later wave of a blast's flames (`xwave`) with the smoke that rises with it.
static func run_job(d: VfxDebris, kind: String, a: Dictionary) -> void:
	if kind == "xwave":
		var rdw: SimRng = d._rd
		_flame_wave(d, rdw, a.x, a.y, a.z, a.s, int(a.n), float(a.q), int(a.cap), float(a.spread), float(a.get("edge", 0.0)))
		for i in range(int(a.smoke)):
			if rdw.next() < float(a.q) and not (d.reduced and i > 0):
				d.smoke(a.x + rdw.range_(-30.0, 30.0), a.y + 40.0 + rdw.range_(0.0, 40.0), a.z - 2.0, rdw.range_(54.0, 92.0) * (0.55 + 0.6 * float(a.s)), rdw.range_(0.7, 1.0) * float(a.sm))
		return
	if kind != "smoulder":
		return
	var rd: SimRng = d._rd
	var dx: float = rd.range_(-1.0, 1.0) * a.w
	var sz: float = rd.range_(30.0, 52.0)
	if rd.next() < a.q:
		d.smoke(a.x + dx, a.y + 10.0, a.z - 2.0, sz, rd.range_(0.55, 0.85) * a.life)
	if a.ember:
		var ang: float = rd.range_(1.0, 2.1)
		var spd: float = rd.range_(90.0, 200.0)
		var keep: bool = rd.next() < a.q and d._ember_tick < VfxLook.EMBER_PER_TICK and d._ember_alive < VfxLook.EMBER_CAP
		if keep:
			var b: VfxDebris.Bit = d._bit(VfxDebris.EMBER, a.x + dx, a.y + 8.0, a.z + 10.0, cos(ang) * spd, sin(ang) * spd, 0.5, rd.range_(0.6, 1.1))
			b.col = VfxPalette.ember("warm")
			b.sx = 36.0
			b.sy = 7.0
			b.grav = 200.0
			b.spin = 0.0
			b.rot = ang
			d._ember_tick += 1
			d._ember_alive += 1
			d._add(b)
