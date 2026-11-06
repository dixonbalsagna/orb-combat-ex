class_name VfxClashWave
extends RefCounted
## The beam clash's shockwave at the meeting point (docs/vfx/clash-shockwave.md; Orb: "the center where the beams collide would have the biggest shockwave, possibly causing a crater underneath"; Legal RL-246: go with limits).
## Two beats, both rings and dust on the ground, never a light and never on a fighter:
##   * GROWTH while the struggle runs: a thin flat ring in the pair's mix colour on the ground beneath the point, at most one in `ring_gap_s` (2 s), its radius following the struggle's slow swell (`knot_s`), with a low dust skirt.
##     NOTHING is drawn per pulse: a struggle pulses 15 times in 5 s, and none of those pulses has a ring or a light of its own (RL-246).
##   * THE RELEASE at the struggle's end (Encounter's cue `beam_clash_end`, docs/director/pending/clash-end/): ONE wave, once: a wide flat ring (and a softer second) running out to the radius of the crater World digs under the point
##     (data release_r by the pair's mean tier, times the root of the ending's share f_end), over `release_s` (at least 0.3 s: a rise, never a flash), and a local low dust dome. It starts `release_delay` ticks after the cue so it is never in the
##     same tick as the winner's beam, its blast and the crater (one envelope). In the air (the point above `height_reach`) it is an air burst: a half-size ring and no dome.
## No white, gold or red (the mix colour is a hue average), no screen read, no light: the combined step with the blast is measured by the flash clips, not here. Presentation only: it reads the cue, S.game.clash, the fighters and the
## ground, and draws no random number of its own (the pool's cosmetic stream does the dust).

const DEFAULTS: Dictionary = {
	"grow_r0": 70.0, "grow_r1": 300.0, "ring_gap_s": 2.0, "knot_s": 1.8, "ring_life_s": 1.0, "ring_alpha": 0.55, "skirt_puffs": 3.0,
	"release_r": [1136.0, 1821.0, 2466.0, 3096.0], "height_reach": 1600.0, "air_k": 0.5,
	"release_delay": 12.0, "release_s": 0.45, "second_k": 0.7, "second_delay": 8.0, "release_alpha": 0.7,
	"dome_k": 0.35, "dome_max": 800.0, "dome_puffs": 14.0, "back": 60.0,
}
const F_END: Dictionary = {"win": 0.6, "break": 0.5, "draw": 1.0}

class Release:
	var x: float = 0.0
	var y: float = 0.0               # the ground under the point
	var z: float = 0.0
	var R: float = 1000.0
	var air: bool = false
	var t: float = 0.0               # ticks since the cue
	var col: Color = Color.WHITE

var releases: Array = []
var made: Dictionary = {}            # counters by kind, for the tests
var _ring_t: float = -100.0
var last_z: float = 0.0              # the depth of the last growth ring, for the tests
var _last_end_tick: int = -1000

static var _data: Dictionary = {}
static var _loaded: bool = false


static func warm() -> void:
	if _loaded:
		return
	_loaded = true
	var path := "res://data/vfx/clash.json"
	if FileAccess.file_exists(path):
		var v = JSON.parse_string(FileAccess.get_file_as_string(path))
		if v is Dictionary and v.get("shockwave") is Dictionary:
			_data = v["shockwave"]


static func p(key: String) -> float:
	warm()
	if _data.has(key) and not (_data[key] is Array):
		return float(_data[key])
	return float(DEFAULTS[key])


static func pa(key: String) -> Array:
	warm()
	if _data.has(key) and _data[key] is Array:
		return _data[key]
	return DEFAULTS[key]


static func f_end(how: String) -> float:
	warm()
	var fe = _data.get("f_end")
	if fe is Dictionary and fe.has(how):
		return float(fe[how])
	return float(F_END.get(how, 0.6))


## The release's radius: World's meeting crater by the pair's mean tier (1 to 4: 1,136 to 3,096 units), times the root of the ending's share (docs/world/struggle-meeting-point.md).
static func release_radius(mean_tier: float, how: String) -> float:
	var tb: Array = pa("release_r")
	var t: float = clampf(mean_tier - 1.0, 0.0, float(tb.size() - 1))
	var lo: int = int(floor(t))
	var hi: int = mini(lo + 1, tb.size() - 1)
	return lerpf(float(tb[lo]), float(tb[hi]), t - float(lo)) * sqrt(f_end(how))


func reset() -> void:
	releases.clear()
	made = {}
	_ring_t = -100.0
	_last_end_tick = -1000


## One tick's events: the struggle's end.
func on_events(S: SimState, events: Array) -> void:
	for e in events:
		if e.type != "cue" or String(e.kind) != "beam_clash_end":
			continue
		if S.tick == _last_end_tick:
			continue                       # one release a tick, never two
		_last_end_tick = S.tick
		var x: float = float(e.x)
		var how: String = String(e.text)
		var gy: float = WorldTerrain.groundY(S, x)
		var actor: int = int(e.actor)
		var ta: float = float(S.fighters[actor].tier) if actor >= 0 and actor < S.fighters.size() else 1.0
		var tb: float = float(S.fighters[1 - actor].tier) if actor >= 0 and actor < 2 and S.fighters.size() > 1 else ta
		var r := Release.new()
		r.x = x
		r.y = gy
		r.z = float(VfxHub._g(e, "z", 0.0)) - p("back")      # behind the fighters in depth: nothing is drawn over a body
		r.R = release_radius(0.5 * (ta + tb), how)
		r.air = float(e.y) - gy > p("height_reach")
		if r.air:
			r.R *= p("air_k")
		r.col = _mix(S)
		releases.append(r)
		made["end"] = int(made.get("end", 0)) + 1


## The pair's mix colour (the clash look's: the two lane colours averaged in hue, never white), at the release's alpha.
static func _mix(S: SimState) -> Color:
	var a: Color = VfxAura.lane_color(String(S.fighters[0].aura))
	var b: Color = VfxAura.lane_color(String(S.fighters[1].aura)) if S.fighters.size() > 1 else a
	return VfxClashLook.mix_tint(a, b)


## Once per unfrozen tick: the growth rings while a struggle runs, and a release that is due.
func step(S: SimState, frozen: bool, debris: VfxDebris, quality: int, reduced: bool) -> void:
	if frozen or debris == null:
		return
	var q: float = VfxLook.QUALITY_SHARDS[clampi(quality, 0, 2)] * (0.5 if reduced else 1.0)
	var i: int = 0
	while i < releases.size():
		var r: Release = releases[i]
		r.t += 1.0
		if r.t >= p("release_delay"):
			_release(S, r, debris, q, reduced)
			releases.remove_at(i)
		else:
			i += 1
	var c = S.game.clash
	if c == null or S.fighters.size() < 2:
		return
	if S.T - _ring_t < p("ring_gap_s"):
		return
	var ax: float = c.A.x
	var dx: float = SimWrap.sdx(ax, c.D.x)
	var mid: float = c.mid if c.mid >= 0.0 else 0.5
	var px: float = SimWrap.wrap(ax + dx * mid)
	var py: float = c.A.y + (c.D.y - c.A.y) * mid + 38.0
	var gy: float = WorldTerrain.groundY(S, px)
	if py - gy > p("height_reach"):
		return                              # too high above the ground for a ring on it
	_ring_t = S.T
	var knot: float = smoothstep(0.0, p("knot_s"), S.T - float(c.t0))
	var r1: float = lerpf(p("grow_r0"), p("grow_r1"), knot)
	var col: Color = _mix(S)
	col.a = p("ring_alpha")
	var z: float = float(c.A.z) + (float(c.D.z) - float(c.A.z)) * mid - p("back")
	last_z = z
	debris.ring_tint(px, gy + 6.0, z, r1 * 0.4, r1, p("ring_life_s"), col)
	made["grow"] = int(made.get("grow", 0)) + 1
	var biome: String = VfxPalette.biome_key(px)
	var rd: SimRng = debris._rd
	for k in range(maxi(int(round(p("skirt_puffs") * q)), 1)):
		var side: float = 1.0 if k % 2 == 0 else -1.0
		debris.dust_puff(biome, px + side * rd.range_(0.3, 1.0) * r1, gy + 8.0, z - rd.range_(0.0, 16.0), side * rd.range_(40.0, 140.0), rd.range_(10.0, 40.0), 18.0, 40.0, rd.range_(0.6, 1.0), k % 3)


## The release: one wave, once (a wide ring, a softer second), and a local low dust dome (none in the air).
func _release(S: SimState, r: Release, debris: VfxDebris, q: float, reduced: bool) -> void:
	var col: Color = r.col
	col.a = p("release_alpha")
	var life: float = p("release_s")
	debris.ring_tint(r.x, r.y + 6.0, r.z, r.R * 0.15, r.R, life, col)
	made["ring"] = int(made.get("ring", 0)) + 1
	if not reduced:
		var col2: Color = r.col
		col2.a = p("release_alpha") * 0.6
		debris.ring_tint(r.x, r.y + 6.0, r.z, r.R * 0.1, r.R * p("second_k"), life * 1.3, col2)
		made["ring"] = int(made.get("ring", 0)) + 1
	if r.air:
		return
	var biome: String = VfxPalette.biome_key(r.x)
	var rd: SimRng = debris._rd
	var dr: float = minf(r.R * p("dome_k"), p("dome_max"))
	for k in range(maxi(int(round(p("dome_puffs") * q)), 2)):
		var ang: float = rd.range_(-1.0, 1.0)
		debris.dust_puff(biome, r.x + ang * dr, r.y + 8.0, r.z - rd.range_(0.0, 24.0), ang * rd.range_(120.0, 380.0), rd.range_(30.0, 120.0), 40.0, 110.0, rd.range_(1.0, 1.8), k % 3)
		made["dust"] = int(made.get("dust", 0)) + 1
