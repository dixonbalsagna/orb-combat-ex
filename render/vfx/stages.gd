class_name VfxStages
extends RefCounted
## Building stages on screen (World's staged destruction, docs/world/staged-destruction.md sections 2, 6 and 10; the plan is docs/vfx/building-stages-plan.md). The sim sends
## one `building_stage` event on a change of stage: {b, from, to, x, y, z, w, h, kind, cx, owner, n} (stages 0 intact, 1 windows out, 2 a part gone, 3 a shell, 4 rubble).
## A jump crosses several steps, so what is drawn is the UNION of the steps it crosses:
##   crosses 1  (from < 1 <= to)  a glass shower from the facade, away from the blast
##   crosses 2  (from < 2 <= to)  a dust skirt and a small shed of cladding panels (skipped when the same tick has this building's floor_hit or floors_fall: the floors' own
##                                burst stands; and subsumed by the big shed when the jump reaches 3)
##   crosses 3  (from < 3 <= to)  the cladding stripped: a big shed, a low dust skirt, a smoke belch, and the building starts to smoke (below)
##   to 4                         nothing (building_fall and floors_fall carry the collapse)
## The whole tick's events are read before anything is drawn: floor_hit comes before building_stage in the same tick, and a tick can carry dozens of stage events (up to 69 in a
## blast that steps a street), so they are drawn nearest-fighter first at full strength for 6, 40% for the next 14, 12% for the rest, and a token chip and puff each once the per-tick
## budget of bits is spent (past 1.6 times it, none).
## A shell keeps smoking by STATE, not event: every 10 ticks the nearest few shells within reach of a fighter read WorldStructures.stage(b) and let a thin grey puff rise from
## their highest standing point (12 puffs a second at most, none at quality low or in reduced motion), so a seek or a late join still looks wrecked.
## Presentation only: the cosmetic streams (vfx.shard, vfx.dust) draw the randomness; S.rng and the sim are never touched.

const DEFAULTS: Dictionary = {
	"stages": {"glass_min": 5.0, "glass_max": 10.0, "shed_small": 3.0, "shed_big": 6.0, "skirt_small": 4.0, "skirt_big": 5.0, "belch": 3.0, "full_n": 2.0, "half_n": 6.0,
		"slab_base": 0.75, "slab_per_width": 0.12, "stagger_ticks": 12.0, "budget": 160.0, "plume_every": 30.0, "plume_cap": 12.0, "plume_window": 150.0, "plume_shells": 4.0, "plume_reach": 3500.0, "scan_every": 10.0},
}

var made: Dictionary = {}               # counters, for the tests: glass, shed, skirt, belch, plume, skipped, events
var plume_ticks: Array = []             # the ticks of the plume puffs still alive
var _later: Array = []                  # [due clock, plan]: stage changes whose debris waits its turn (on_events)
var _next_puff: Dictionary = {}         # building index -> the tick of its next puff
var _clock: int = 0

static var _data: Dictionary = {}
static var _loaded: bool = false


static func warm() -> void:
	if _loaded:
		return
	_loaded = true
	var path := "res://data/vfx/stages.json"
	if FileAccess.file_exists(path):
		var v = JSON.parse_string(FileAccess.get_file_as_string(path))
		if v is Dictionary:
			_data = v


static func p(key: String) -> float:
	warm()
	var g = _data.get("stages")
	if g is Dictionary and g.has(key):
		return float(g[key])
	return float(DEFAULTS["stages"][key])


func reset() -> void:
	made = {}
	_later.clear()
	plume_ticks.clear()
	_next_puff.clear()
	_clock = 0
	warm()


## The steps a jump crosses: which of 1, 2, 3 it passes.
static func crosses(from_s: int, to_s: int, step: int) -> bool:
	return from_s < step and to_s >= step and to_s < 4


## This tick's events. `front` is a Callable(building) -> the facade's z (the hub's front_z).
func on_events(S: SimState, events: Array, debris: VfxDebris, front: Callable, quality: int, reduced: bool) -> void:
	var stage_evs: Array = []
	var floored: Dictionary = {}
	for e in events:
		match String(e.type):
			"building_stage":
				stage_evs.append(e)
			"floor_hit", "floors_fall":
				floored[int(VfxHub._g(e, "b", -1))] = true
	if stage_evs.is_empty():
		return
	made["events"] = int(made.get("events", 0)) + stage_evs.size()
	# Nearest a fighter first: the ones he can see are drawn at full strength, the far ones thinned (or dropped when the budget is spent).
	var near := func(e) -> float:
		var d: float = 1e9
		for f in S.fighters:
			d = minf(d, absf(SimWrap.sdx(f.x, float(e.x))))
		return d
	stage_evs.sort_custom(func(a, b): return near.call(a) < near.call(b))
	var q: float = VfxLook.QUALITY_SHARDS[clampi(quality, 0, 2)] * (0.5 if reduced else 1.0)
	var budget: int = int(p("budget"))
	var spent: int = 0
	var stagger: int = int(p("stagger_ticks"))
	for r in range(stage_evs.size()):
		var e = stage_evs[r]
		var from_s: int = int(VfxHub._g(e, "from", 0))
		var to_s: int = int(VfxHub._g(e, "to", 0))
		if to_s >= 4 or to_s <= from_s:
			continue
		if spent >= int(float(budget) * 1.6):
			made["skipped"] = int(made.get("skipped", 0)) + 1
			continue
		var strength: float = 1.0 if r < int(p("full_n")) else (0.4 if r < int(p("half_n")) else 0.12)
		if spent >= budget:
			strength = 0.06           # the budget is spent: the far ones draw a chip and a puff each
		var bi: int = int(VfxHub._g(e, "b", -1))
		var plan := {"e": e, "from": from_s, "to": to_s, "strength": strength, "floored": floored.has(bi), "bi": bi}
		spent += _counts(plan, q)
		# A blast that changes five towers at once does not draw five towers' debris in one tick: the nearest draw now and the rest follow, two ticks apart, up to `stagger_ticks`
		# (Camera's list for the collapse clip: no more than one bright, whole-area change in a tick).
		var delay: int = clampi(r * 2, 0, stagger)
		if delay <= 0:
			_draw(S, plan, debris, front, q)
		else:
			_later.append([_clock + delay, plan])


## What a plan will draw, in bits (for the budget): the same counts _draw makes.
func _counts(plan: Dictionary, q: float) -> int:
	var e = plan["e"]
	var k: float = q * float(plan["strength"])
	var w: float = maxf(float(VfxHub._g(e, "w", 200.0)), 60.0)
	var width_k: float = clampf(w / 240.0, 0.6, 2.0)
	var c1: bool = crosses(int(plan["from"]), int(plan["to"]), 1)
	var c2: bool = crosses(int(plan["from"]), int(plan["to"]), 2)
	var c3: bool = crosses(int(plan["from"]), int(plan["to"]), 3)
	var n: int = 0
	if c1:
		n += maxi(1, int(round(lerpf(p("glass_min"), p("glass_max"), clampf(width_k - 0.6, 0.0, 1.0)) * k)))
	if c3:
		n += maxi(1, int(round(p("shed_big") * width_k * k))) + int(p("skirt_big") * k) + int(p("belch") * k)
	elif c2 and not bool(plan["floored"]):
		n += maxi(1, int(round(p("shed_small") * width_k * k))) + int(p("skirt_small") * k)
	return n


## One building's stage change, drawn: glass at stage 1, cladding, a skirt and a belch at 3, a smaller shed at 2.
func _draw(S: SimState, plan: Dictionary, debris: VfxDebris, front: Callable, q: float) -> void:
	var e = plan["e"]
	var from_s: int = int(plan["from"])
	var to_s: int = int(plan["to"])
	var bi: int = int(plan["bi"])
	var k: float = q * float(plan["strength"])
	var bx: float = float(e.x)
	var w: float = maxf(float(VfxHub._g(e, "w", 200.0)), 60.0)
	var h: float = maxf(float(VfxHub._g(e, "h", 300.0)), 60.0)
	var g: float = float(VfxHub._g(e, "y", 0.0))
	var cx: float = float(VfxHub._g(e, "cx", bx))
	var dirx: float = signf(SimWrap.sdx(cx, bx)) if absf(SimWrap.sdx(cx, bx)) > 1.0 else (1.0 if bi % 2 == 0 else -1.0)
	var fz: float = float(VfxHub._g(e, "z", 0.0))
	if bi >= 0 and bi < S.buildings.size() and front.is_valid():
		fz = float(front.call(S.buildings[bi]))
	var width_k: float = clampf(w / 240.0, 0.6, 2.0)
	var slab: float = p("slab_base") + p("slab_per_width") * width_k       # a cladding slab's scale: the panel of a facade, not a boulder
	var c1: bool = crosses(from_s, to_s, 1)
	var c2: bool = crosses(from_s, to_s, 2)
	var c3: bool = crosses(from_s, to_s, 3)
	if c1:
		var n1: int = maxi(1, int(round(lerpf(p("glass_min"), p("glass_max"), clampf(width_k - 0.6, 0.0, 1.0)) * k)))
		if bi >= 0 and bi < S.buildings.size():
			debris.pane = VfxPanes.grid(S, S.buildings[bi])
		debris.stage_glass(bx, w, g + h * 0.15, g + h, fz, dirx, n1)
		debris.pane = {}
		made["glass"] = int(made.get("glass", 0)) + 1
	if c3:
		var n3: int = maxi(1, int(round(p("shed_big") * width_k * k)))
		if bi >= 0 and bi < S.buildings.size():
			debris.pane = VfxPanes.grid(S, S.buildings[bi])
		debris.stage_shed(bx, w, g + h * 0.1, g + h, fz, dirx, n3, slab)
		debris.pane = {}
		debris.stage_skirt(S, bx, w, h, fz, maxi(1, int(round(p("skirt_big") * k))))
		debris.stage_smoke(bx, g + h, fz, maxi(1, int(round(p("belch") * k))), 0.0)
		made["shed"] = int(made.get("shed", 0)) + 1
		made["skirt"] = int(made.get("skirt", 0)) + 1
		made["belch"] = int(made.get("belch", 0)) + 1
	elif c2:
		if bool(plan["floored"]):
			made["deduped"] = int(made.get("deduped", 0)) + 1
		else:
			var n2: int = maxi(1, int(round(p("shed_small") * width_k * k)))
			if bi >= 0 and bi < S.buildings.size():
				debris.pane = VfxPanes.grid(S, S.buildings[bi])
			debris.stage_shed(bx, w, g + h * 0.4, g + h, fz, dirx, n2, 0.85 * slab)
			debris.pane = {}
			debris.stage_skirt(S, bx, w, h, fz, maxi(1, int(round(p("skirt_small") * k))))
			made["shed"] = int(made.get("shed", 0)) + 1
			made["skirt"] = int(made.get("skirt", 0)) + 1


## Once per tick (unfrozen): a shell keeps smoking. Every `scan_every` ticks the nearest few shells within reach of a fighter read the stage query and let a thin grey puff rise.
func step(S: SimState, frozen: bool, debris: VfxDebris, front: Callable, quality: int, reduced: bool) -> void:
	if frozen:
		return
	_clock += 1
	var q_now: float = VfxLook.QUALITY_SHARDS[clampi(quality, 0, 2)] * (0.5 if reduced else 1.0)
	var li: int = 0
	while li < _later.size():
		if _clock >= int(_later[li][0]):
			var plan: Dictionary = _later[li][1]
			_later.remove_at(li)
			_draw(S, plan, debris, front, q_now)
		else:
			li += 1
	var win: int = int(p("plume_window"))
	while not plume_ticks.is_empty() and _clock - int(plume_ticks[0]) > win:
		plume_ticks.pop_front()
	if quality <= 0 or reduced or _clock % int(p("scan_every")) != 0:
		return
	var shells: Array = []
	for i in range(S.buildings.size()):
		var b = S.buildings[i]
		if not b.alive or WorldStructures.stage(b) != 3:
			continue
		var d: float = 1e9
		for f in S.fighters:
			d = minf(d, absf(SimWrap.sdx(f.x, b.x)))
		if d <= p("plume_reach"):
			shells.append([d, i])
	shells.sort_custom(func(a, b): return a[0] < b[0])
	for k in range(mini(shells.size(), int(p("plume_shells")))):
		var bi: int = int(shells[k][1])
		if plume_ticks.size() >= int(p("plume_cap")):
			return
		if _clock < int(_next_puff.get(bi, 0)):
			continue
		_next_puff[bi] = _clock + int(p("plume_every"))
		var b = S.buildings[bi]
		var top: float = WorldStructures.baseY(S, b) + WorldStructures.curH(b)
		var fz: float = float(front.call(b)) if front.is_valid() else float(b.z)
		debris.stage_smoke(b.x, top, fz, 1, 1.0)
		plume_ticks.append(_clock)
		made["plume"] = int(made.get("plume", 0)) + 1
