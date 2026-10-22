class_name VfxBeamScar
extends RefCounted
## The scar a beam leaves in the air (Orb, 2026-10-19: "it should look like it's burned a trail into the very space it passed through, some kind of lingering effect").
## As a beam's tail draws back along its line (BeamView.tail_at: from 0.4 s, reaching the far end as the beam's life ends), the line the tail has left is branded into the air: a thin dark
## cut with a bright lane-coloured rim, born at the tail as a pointed wedge, the rim hot at first and cooling in about a second. It stays where the beam was (anchored in the world, so a
## moving camera slides past it) and heals slowly: over `heal_s` seconds it thins, and its pieces drop out one by one with hard edges (never a fade: Orb's rule of 2026-10-18).
## Presentation only: it reads S.beams and S.T, keeps its own records, draws no random number, writes nothing. The look is shaders/beam_scar.gdshader, drawn by scar_view.gd.

class Scar:
	var ox: float = 0.0        # the beam's origin (wrapped x), direction and depth, as the sim has them
	var oy: float = 0.0
	var oz: float = 0.0
	var ux: float = 1.0
	var uy: float = 0.0
	var zs: float = 0.0
	var w: float = 30.0        # the beam's width
	var hex: String = ""       # its colour (the fighter's aura hex)
	var t_fire: float = 0.0    # the sim clock the beam was fired at
	var life: float = 0.95
	var len: float = 0.0       # the beam's full length (the tail's pace is len over life)
	var reach: float = 0.0     # how far the head has got
	var ended: bool = false
	var seed: float = 0.0
	var who = null             # the fighter whose beam it is
	var keep: float = 1.0      # the ring's turn: the share of its width kept (VfxHub._arena_turn)

var list: Array = []         # Scar, oldest first
var made: int = 0            # counters, for the tests
var clock: float = 0.0
var _by_id: Dictionary = {}

const DEFAULTS: Dictionary = {
	"heal_s": 3.6, "hw_k": 0.3, "hw_px": 3.0, "rim_px": 2.0, "alpha_core": 0.62, "alpha_rim": 0.92, "dark": 0.1, "cell": 110.0, "cool_s": 1.2, "grow_s": 0.14, "cap": 10.0,
}


static func p(key: String) -> float:
	VfxBeamLook.warm()
	var g = VfxBeamLook._data.get("scar")
	if g is Dictionary and g.has(key):
		return float(g[key])
	return float(DEFAULTS[key])


func reset() -> void:
	list.clear()
	_by_id.clear()
	made = 0
	clock = 0.0


## Every tick: note each beam in S.beams (the scar is made as the beam is first seen and extends as its head does), mark the beams that have gone, and drop a scar once it has healed all along.
func step(S: SimState) -> void:
	if S.T < clock - 0.5:
		reset()       # the match was restarted or rewound
	clock = S.T
	var seen: Dictionary = {}
	for b in S.beams:
		if float(b.len) < 1.0:
			continue
		var id: int = b.get_instance_id()
		seen[id] = true
		var sc: Scar = _by_id.get(id)
		if sc == null:
			sc = Scar.new()
			sc.ox = float(b.ox)
			sc.oy = float(b.oy)
			sc.oz = float(b.oz)
			sc.ux = float(b.ux)
			sc.uy = float(b.uy)
			sc.zs = float(b.zs)
			sc.w = float(b.w)
			sc.hex = String(b.col)
			sc.t_fire = S.T - float(b.t)
			sc.life = float(b.life)
			sc.len = float(b.len)
			sc.seed = fposmod(float(made) * 0.6180339 + 0.17, 1.0)
			sc.who = b.A
			_by_id[id] = sc
			list.append(sc)
			made += 1
		sc.reach = maxf(sc.reach, float(b.p) * float(b.len))
	for id in _by_id.keys():
		if not seen.has(id):
			_by_id[id].ended = true
			if not list.has(_by_id[id]):
				_by_id.erase(id)       # a scar the ring's turn dropped (or one already healed): its beam is gone, forget it
	# healed all along: the oldest point of a scar is its firer's end, the newest its far end
	var keep: Array = []
	for sc in list:
		if sc.ended and age_at(sc, sc.reach, clock) >= p("heal_s"):
			for id in _by_id.keys():
				if _by_id[id] == sc:
					_by_id.erase(id)
					break
			continue
		keep.append(sc)
	list = keep
	var cap: int = int(p("cap"))
	while list.size() > cap:
		var old: Scar = list[0]
		for id in _by_id.keys():
			if _by_id[id] == old:
				_by_id.erase(id)
				break
		list.remove_at(0)


## The sim clock at which the tail passes distance s along the scar's beam.
static func burn_time(sc: Scar, s: float) -> float:
	return sc.t_fire + 0.4 + clampf(s / maxf(sc.len, 1.0), 0.0, 1.0) * maxf(sc.life - 0.4, 0.05)


## How long (seconds) the point s along the scar has been burned at clock t; negative while the tail has not got there.
static func age_at(sc: Scar, s: float, t: float) -> float:
	return t - burn_time(sc, s)


## The half width of the scar at world scale: a share of the beam's width, with a floor of a few pixels at this pane's zoom (ppu: pixels per world unit).
static func half_width(sc: Scar, ppu: float) -> float:
	return maxf(sc.w * p("hw_k"), p("hw_px") / maxf(ppu, 0.05))


## How much of the scar is still there at age `age`, 0 to 1 (the shader's thinning). Hard to read as a fade: this is the width share, the alpha never moves with it.
static func width_left(age: float) -> float:
	var h: float = clampf(age / p("heal_s"), 0.0, 1.0)
	return 1.0 - 0.55 * smoothstep(0.15, 1.0, h)
