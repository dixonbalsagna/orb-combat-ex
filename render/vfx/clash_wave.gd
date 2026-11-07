class_name VfxClashWave
extends RefCounted
## The beam clash's shockwave at the meeting point (docs/vfx/clash-shockwave.md; Orb: "the center where the beams collide would have the biggest shockwave, possibly causing a crater underneath"; Legal RL-246: go with
## limits). World's struggle-meet (docs/world/struggle-meet.md) is the sim side and sends the cues; this draws them. Rings and dust on the ground, a burn in the air for an air burst, never a light and never on a fighter:
##   * GROWTH: the cue `struggle_ring` (x, y, z, `amount` the ring's radius in units, `n` its size in body heights x 100): a thin flat ring in the pair's mix colour on the ground beneath the point, growing 1 to 3 body heights
##     through the struggle as the sim sends it, at most one in `ring_gap_s` (2 s) whatever arrives, rising over at least `ring_rise_s` (6 ticks). No ring and no light per pulse (a struggle pulses 15 times in 5 s): a pulse has no cue here.
##   * THE RELEASE: the cue `beam_clash_end` with `r` (the crater's radius, 0 for none), `rGlass` (the radius before the height cut), `dug` (the energy dug) and the ground's shape (`ground`: bowl, scorch or air; when the cue has
##     none it is read from `r` and `dug`). ONE wave, once: one rise of at least `rise_s` (0.3 s) and one fall of at least `fall_s` (1 s), in a ring that runs out to the crater's radius (a bowl) or, with no bowl, a thin ring at
##     `rGlass` with the burn drawn in the air at the point (a few smoke puffs; scorch also a small local dust); strength by `dug`. A local dust dome at most 6 body heights across. It starts `release_delay` ticks after the cue so
##     it is never in the tick of the winner's beam, its blast and the crater (one envelope, RL-246 4). A cue without the fields reads World's crater by the pair's tier and the ending, as before (the fallback).
## No white, gold or red (the mix colour is a hue average), no screen read, no light: the combined step with the blast is measured by the flash clips, not here. Presentation only: it reads the cues, the fighters and the ground, and draws
## no random number of its own (the pool's cosmetic stream does the dust and smoke).

const DEFAULTS: Dictionary = {
	"grow_r0": 75.0, "grow_r1": 225.0, "ring_gap_s": 2.0, "ring_life_s": 1.2, "ring_alpha": 0.55, "ring_rise_s": 0.1, "skirt_puffs": 3.0,
	"release_r": [1136.0, 1821.0, 2466.0, 3096.0], "height_reach": 1600.0, "air_k": 0.5,
	"release_delay": 12.0, "rise_s": 0.3, "fall_s": 1.1, "second_k": 0.7, "release_alpha": 0.7, "thin_k": 0.6,
	"dug_ref": 400.0, "dug_min_k": 0.5, "dome_k": 0.35, "dome_max": 225.0, "dome_puffs": 14.0, "smoke_puffs": 4.0, "back": 60.0,
}
const F_END: Dictionary = {"win": 0.6, "break": 0.5, "draw": 1.0}

class Release:
	var x: float = 0.0
	var y: float = 0.0               # the ground under the point
	var py: float = 0.0              # the point's own height (the burn in the air)
	var z: float = 0.0
	var R: float = 1000.0
	var shape: String = "bowl"       # bowl, scorch or air
	var k: float = 1.0               # strength by the energy dug
	var t: float = 0.0               # ticks since the cue
	var col: Color = Color.WHITE

var releases: Array = []
var made: Dictionary = {}            # counters by kind, for the tests
var _ring_t: float = -100.0
var last_z: float = 0.0              # the depth of the last growth ring, for the tests
var last_r: float = 0.0              # its radius
var last_dome: float = 0.0           # the last dust dome's radius
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


## The fallback radius, for a cue without World's fields: World's meeting crater by the pair's mean tier (1 to 4: 1,136 to 3,096 units), times the root of the ending's share (docs/world/struggle-meeting-point.md).
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


## One tick's events: a struggle's ring, and its end.
func on_events(S: SimState, events: Array, debris: VfxDebris = null, quality: int = 2, reduced: bool = false) -> void:
	for e in events:
		if e.type != "cue":
			continue
		var kind: String = String(e.kind)
		if kind == "struggle_ring":
			_ring(S, e, debris, quality, reduced)
		elif kind == "beam_clash_end":
			_end(S, e)


## One growth ring: where the sim put it, as wide as it says, at most one in `ring_gap_s` whatever arrives.
func _ring(S: SimState, e, debris: VfxDebris, quality: int, reduced: bool) -> void:
	if debris == null or S.fighters.size() < 2:
		return
	if S.T - _ring_t < p("ring_gap_s") - 0.05:
		made["ring_skipped"] = int(made.get("ring_skipped", 0)) + 1
		return
	var px: float = float(e.x)
	var gy: float = WorldTerrain.groundY(S, px)
	if float(e.y) - gy > p("height_reach"):
		return                              # too high above the ground for a ring on it
	_ring_t = S.T
	var r1: float = float(VfxHub._g(e, "amount", p("grow_r1")))
	var z: float = float(VfxHub._g(e, "z", 0.0)) - p("back")
	last_z = z
	last_r = r1
	var col: Color = _mix(S)
	col.a = p("ring_alpha")
	debris.ring_tint(px, gy + 6.0, z, r1 * 0.4, r1, p("ring_life_s"), col, p("ring_rise_s"))
	made["grow"] = int(made.get("grow", 0)) + 1
	var q: float = VfxLook.QUALITY_SHARDS[clampi(quality, 0, 2)] * (0.5 if reduced else 1.0)
	var biome: String = VfxPalette.biome_key(px)
	var rd: SimRng = debris._rd
	for k in range(maxi(int(round(p("skirt_puffs") * q)), 1)):
		var side: float = 1.0 if k % 2 == 0 else -1.0
		debris.dust_puff(biome, px + side * rd.range_(0.3, 1.0) * r1, gy + 8.0, z - rd.range_(0.0, 16.0), side * rd.range_(40.0, 140.0), rd.range_(10.0, 40.0), 18.0, 40.0, rd.range_(0.6, 1.0), k % 3)


## The struggle's end: one release, once, late by `release_delay` ticks.
func _end(S: SimState, e) -> void:
	if S.tick == _last_end_tick:
		return                             # one release a tick, never two
	_last_end_tick = S.tick
	var x: float = float(e.x)
	var gy: float = WorldTerrain.groundY(S, x)
	var r := Release.new()
	r.x = x
	r.y = gy
	r.py = float(e.y)
	r.z = float(VfxHub._g(e, "z", 0.0)) - p("back")      # behind the fighters in depth: nothing is drawn over a body
	var bowl: float = float(VfxHub._g(e, "r", 0.0))      # the event's own `r` is the crater's bowl radius (0 for none)
	var glass_v = e.get("rGlass")                         # World's fields: absent on a cue from before them
	var glass: float = float(glass_v) if glass_v != null else -1.0
	var dug: float = float(VfxHub._g(e, "dug", -1.0))
	var gv = e.get("ground")                              # the ground's shape as a word (bowl, scorch, air); an event's own `ground` is a number, so only a string counts
	var shape: String = String(gv) if gv is String else ""
	if glass_v == null:
		# a cue from before World's fields: the crater by tier and ending, a half-size ring in the air
		var how: String = String(e.text)
		var actor: int = int(e.actor)
		var ta: float = float(S.fighters[actor].tier) if actor >= 0 and actor < S.fighters.size() else 1.0
		var tb: float = float(S.fighters[1 - actor].tier) if actor >= 0 and actor < 2 and S.fighters.size() > 1 else ta
		r.R = release_radius(0.5 * (ta + tb), how)
		r.shape = "air" if float(e.y) - gy > p("height_reach") else "bowl"
		if r.shape == "air":
			r.R *= p("air_k")
		dug = -1.0
	else:
		if shape == "":
			shape = "bowl" if bowl > 0.0 else ("scorch" if dug > 0.0 else "air")
		r.shape = shape
		r.R = bowl if (shape == "bowl" and bowl > 0.0) else maxf(glass, bowl)
	r.k = 1.0 if dug < 0.0 else lerpf(p("dug_min_k"), 1.0, smoothstep(0.0, p("dug_ref"), dug))
	r.col = _mix(S)
	releases.append(r)
	made["end"] = int(made.get("end", 0)) + 1


## The pair's mix colour (the clash look's: the two lane colours averaged in hue, never white), at the release's alpha.
static func _mix(S: SimState) -> Color:
	var a: Color = VfxAura.lane_color(String(S.fighters[0].aura))
	var b: Color = VfxAura.lane_color(String(S.fighters[1].aura)) if S.fighters.size() > 1 else a
	return VfxClashLook.mix_tint(a, b)


## Once per unfrozen tick: a release that is due.
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


## The release: one wave, once. One rise (`rise_s`) and one fall (`fall_s`) in a ring out to the crater (a softer second inside it); with no bowl, a thin ring at the glass radius and the burn in the air; a local low dust dome.
func _release(S: SimState, r: Release, debris: VfxDebris, q: float, reduced: bool) -> void:
	var col: Color = r.col
	var thin: bool = r.shape != "bowl"
	col.a = p("release_alpha") * r.k * (p("thin_k") if thin else 1.0)
	var rise: float = p("rise_s")
	var life: float = rise + p("fall_s")
	debris.ring_tint(r.x, r.y + 6.0, r.z, r.R * 0.15, r.R, life, col, rise)
	made["ring"] = int(made.get("ring", 0)) + 1
	if not reduced and not thin:
		var col2: Color = r.col
		col2.a = p("release_alpha") * r.k * 0.6
		debris.ring_tint(r.x, r.y + 6.0, r.z, r.R * 0.1, r.R * p("second_k"), life * 1.1, col2, rise)
		made["ring"] = int(made.get("ring", 0)) + 1
	var biome: String = VfxPalette.biome_key(r.x)
	var rd: SimRng = debris._rd
	if thin:
		# the burn in the air: smoke at the point (the sim digs and scorches nothing for an air burst)
		for k in range(maxi(int(round(p("smoke_puffs") * q)), 1)):
			debris.smoke(r.x + rd.range_(-1.0, 1.0) * 60.0, r.py + rd.range_(-1.0, 1.0) * 40.0, r.z, rd.range_(50.0, 90.0), rd.range_(1.0, 1.8))
			made["smoke"] = int(made.get("smoke", 0)) + 1
		if r.shape == "air":
			return
	var dr: float = minf(r.R * p("dome_k"), p("dome_max"))
	last_dome = dr
	var n: int = maxi(int(round(p("dome_puffs") * q * r.k * (0.4 if thin else 1.0))), 2)
	for k in range(n):
		var ang: float = rd.range_(-1.0, 1.0)
		debris.dust_puff(biome, r.x + ang * dr, r.y + 8.0, r.z - rd.range_(0.0, 24.0), ang * rd.range_(120.0, 380.0), rd.range_(30.0, 120.0), 40.0, 110.0, rd.range_(1.0, 1.8), k % 3)
		made["dust"] = int(made.get("dust", 0)) + 1
