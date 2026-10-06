class_name VfxReach
extends RefCounted
## Energy arts in reach (docs/design/brawl-second-pass.md Â§5b, Orb's fourth test: "do energy attacks look cool as part of close-range combos?") and the launcher's two marks (Â§3).
## With RB held in reach X is the point-blank bolt (contact at 2 ticks) and Y the blast (12-tick wind-up, knock-back 4 bh); a tap of B on a staggered rival is the launcher.
## Presentation only: it reads cues and fighters, draws no random number, never writes the sim. Drawn by shots_view.gd `_reach`, behind the press flag.
##
##   lit hand      a bolt's palm comes up with the blow: a small hollow ring and two short streaks forward, never a filled disc and never held (it is gone at the contact)
##   gather        the blast's wind-up: a thin ring closing onto the palm over the last 10 ticks and three short streaks converging on it (a charge ring, not a ball)
##   landing       at the contact: a hard crack (two crossed thin lines), a hollow ring and, when the flash limit allows, one soft flash of 3 ticks; otherwise sparks at the hand
##   rim           for 3 ticks the near side of each fighter takes the shot's colour as a thin edge line beside the body: never a flash over the body
##   spill         what does not stop in him flies on along the stick's lean: 2 to 3 bh of spark streaks for a bolt, a cone of 6 bh for the blast; a scorch where it meets the ground
##   carry         the blast carries him: the shot's colour trails off his chest for 10 ticks along his real path, then smoke
##   B now         a staggered rival who can be launched (a stagger of 12 ticks or more) carries two rising chevrons in the attacker's colour: no words, no flash
##   send-off      the launch: a trail along his real path, a flat ring on the ground where he left it and three short streaks lifting off
##
## Flash limit (Â§5b point 8): at most one FULL flash (the soft disc at the contact) in each `flash_every` ticks across both fighters, so three in a second at most however fast the
## bolts are mashed; the rest get sparks. Reduced motion draws no full flash at all.
## Names assumed for Encounter (docs/vfx/reach.md): cues `energy_reach` (actor, target, text bolt|blast, amount = wind-up ticks, n = the contact tick, absolute, x and y = the stick's lean)
## and `energy_land` (actor, target, text bolt|blast, source = hit|guard|armour|miss, x and y = the lean); the existing cue `stagger` (actor the staggered fighter, target the attacker, text the
## cause, n the ticks) and event `launch` (actor the launched fighter, target the attacker).

const DEFAULTS: Dictionary = {
	"reach": {"flash_every": 20.0, "gather_ticks": 10.0, "gather_r": 30.0, "palm_x": 26.0, "palm_y": 50.0,
		"rim_life": 3.0, "rim_alpha": 0.6, "flash_life": 3.0, "land_life": 9.0,
		"spill_bolt_bh": 2.5, "spill_blast_bh": 6.0, "spill_life": 8.0, "scorch_life": 150.0, "scorch_max": 6.0,
		"carry_life": 10.0, "smoke_every": 3.0, "smoke_ticks": 24.0, "stagger_min": 12.0, "chev_period": 12.0, "send_life": 12.0, "alpha": 0.9},
}

class Fx:
	var style: String = ""          # lit, gather, land, rim, spill, scorch, carry, stagger, send
	var slot: int = 0               # the one who fired (the attacker); a rim's lit fighter is `vic`
	var vic: int = 0
	var dir: float = 1.0            # attacker toward victim
	var x: float = 0.0              # a world point (the contact, or a scorch's place)
	var y: float = 0.0
	var lean: Vector2 = Vector2(1.0, 0.0)
	var age: float = 0.0
	var life: float = 8.0
	var col: Color = Color.WHITE
	var blast: bool = false
	var big: bool = false           # this landing got the full flash
	var guard: bool = false         # it met a guard: a shot on arms, smaller
	var small: bool = false         # reduced motion

var fx: Array = []
var made: Dictionary = {}
var full_ticks: Array = []          # the ticks a full flash was given (the tests check the rate)
var last_full: int = -1000
var registry: VfxFlashRegistry = null   # the screen's flash register (flash_registry.gd): a full flash asks it before it is drawn
var shown: int = 0                  # quads drawn last frame
var smoke_jobs: Array = []          # {slot, left, every}: smoke off a carried fighter after a blast

static var _data: Dictionary = {}
static var _loaded: bool = false


static func warm() -> void:
	if _loaded:
		return
	_loaded = true
	var path := "res://data/vfx/reach.json"
	if FileAccess.file_exists(path):
		var v = JSON.parse_string(FileAccess.get_file_as_string(path))
		if v is Dictionary:
			_data = v


static func p(key: String) -> float:
	warm()
	var g = _data.get("reach")
	if g is Dictionary and g.has(key):
		return float(g[key])
	return float(DEFAULTS["reach"][key])


func reset() -> void:
	fx.clear()
	made.clear()
	full_ticks.clear()
	last_full = -1000
	shown = 0
	smoke_jobs.clear()


## The flash limit (§5b point 8 and Legal's k05): true when a full flash may be drawn on this tick, and then it takes the slot. Two rules: at least `flash_every` ticks since the
## last one across both fighters (the design's pace), and the screen's register (three a second across every effect, fewer for low-priority sources, none in reduced motion).
func allow_full(S: SimState, col: Color = Color.WHITE) -> bool:
	if S.tick - last_full < int(p("flash_every")):
		return false
	if registry != null and not registry.ask("energy", col, S.tick):
		return false
	last_full = S.tick
	full_ticks.append(S.tick)
	while full_ticks.size() > 40:
		full_ticks.pop_front()
	return true


func step(S: SimState, frozen: bool, debris, press: VfxPress) -> void:
	var i: int = 0
	while i < fx.size():
		var e: Fx = fx[i]
		if not frozen:
			e.age += 1.0
		if e.age >= e.life:
			fx.remove_at(i)
		else:
			i += 1
	if frozen:
		return
	var j: int = 0
	while j < smoke_jobs.size():
		var jb: Dictionary = smoke_jobs[j]
		jb["left"] = int(jb["left"]) - 1
		if int(jb["left"]) % int(jb["every"]) == 0 and debris != null and int(debris.quality) > 0:
			var v = S.fighters[int(jb["slot"])]
			debris.smoke(v.x, v.y + 44.0, 0.0, 26.0, 0.75)
			made["smoke"] = int(made.get("smoke", 0)) + 1
		if int(jb["left"]) <= 0:
			smoke_jobs.remove_at(j)
		else:
			j += 1


func on_events(S: SimState, events: Array, reduced: bool, debris, press: VfxPress) -> void:
	for e in events:
		var t: String = String(e.type)
		if t == "launch":
			_send(S, e, reduced)
		elif t == "cue":
			match String(e.kind):
				"energy_reach":
					_reach(S, e, reduced)
				"energy_land":
					_land(S, e, reduced, debris)
				"stagger":
					_stagger(S, e)


func _pair(S: SimState, e) -> Vector2i:
	var slot: int = int(e.actor)
	var vic: int = int(VfxHub._g(e, "target", 1 - slot))
	if slot < 0 or slot > 1 or slot >= S.fighters.size() or vic < 0 or vic >= S.fighters.size() or vic == slot:
		return Vector2i(-1, -1)
	return Vector2i(slot, vic)


static func _lean_of(e, dir: float) -> Vector2:
	var l := Vector2(float(VfxHub._g(e, "x", 0.0)), float(VfxHub._g(e, "y", 0.0)))
	if l.length() < 0.2:
		return Vector2(dir, 0.0)
	return l.normalized()


## The press: a bolt lights the palm for its 2 ticks, the blast gathers into it over its wind-up.
func _reach(S: SimState, e, reduced: bool) -> void:
	var pr: Vector2i = _pair(S, e)
	if pr.x < 0:
		return
	var blast: bool = String(e.text) == "blast"
	var f = S.fighters[pr.x]
	var o := Fx.new()
	o.style = "gather" if blast else "lit"
	o.slot = pr.x
	o.vic = pr.y
	o.dir = 1.0 if SimWrap.sdx(f.x, S.fighters[pr.y].x) >= 0.0 else -1.0
	o.blast = blast
	o.small = reduced
	o.col = VfxPress.lane_of(S, pr.x)
	o.life = maxf(float(VfxHub._g(e, "amount", 12.0 if blast else 2.0)), 1.0) + (0.0 if blast else 1.0)
	fx.append(o)
	made[o.style] = int(made.get(o.style, 0)) + 1


## The contact: the crack, the ring, the flash (when allowed), the rim on both, the spill and, for a blast, the carry.
func _land(S: SimState, e, reduced: bool, debris) -> void:
	var pr: Vector2i = _pair(S, e)
	if pr.x < 0:
		return
	var slot: int = pr.x
	var vic: int = pr.y
	var fa = S.fighters[slot]
	var fv = S.fighters[vic]
	var blast: bool = String(e.text) == "blast"
	var why: String = String(VfxHub._g(e, "source", "hit"))
	var dir: float = 1.0 if SimWrap.sdx(fa.x, fv.x) >= 0.0 else -1.0
	var lean: Vector2 = _lean_of(e, dir)
	var col: Color = VfxPress.lane_of(S, slot)
	# Remove this fighter's gather or lit marks: the contact is the end of them.
	var k: int = fx.size() - 1
	while k >= 0:
		var q: Fx = fx[k]
		if q.slot == slot and (q.style == "gather" or q.style == "lit"):
			fx.remove_at(k)
		k -= 1
	var guard: bool = why == "guard"
	if why != "miss":
		var l := Fx.new()
		l.style = "land"
		l.slot = slot
		l.vic = vic
		l.dir = dir
		l.x = fv.x - dir * 14.0
		l.y = fv.y + 50.0
		l.lean = lean
		l.col = col
		l.blast = blast
		l.guard = guard
		l.small = reduced
		l.life = p("land_life")
		l.big = (not reduced) and (not guard or blast) and allow_full(S, col.lightened(0.3))
		fx.append(l)
		made["land"] = int(made.get("land", 0)) + 1
		if l.big:
			made["full_flash"] = int(made.get("full_flash", 0)) + 1
		# The rim: the near side of each fighter, 3 ticks.
		for who in [slot, vic]:
			var r := Fx.new()
			r.style = "rim"
			r.slot = slot
			r.vic = int(who)
			r.dir = dir if int(who) == slot else -dir
			r.col = col
			r.life = p("rim_life")
			r.small = reduced
			fx.append(r)
		made["rim"] = int(made.get("rim", 0)) + 2
	# The spill: what does not stop in him flies on (a guard soaks the blast's cone, so a bolt on a guard spills nothing).
	if not guard:
		var sp := Fx.new()
		sp.style = "spill"
		sp.slot = slot
		sp.vic = vic
		sp.dir = dir
		sp.x = fv.x
		sp.y = fv.y + 50.0
		sp.lean = lean
		sp.col = col
		sp.blast = blast
		sp.small = reduced
		sp.life = p("spill_life")
		fx.append(sp)
		made["spill"] = int(made.get("spill", 0)) + 1
		_scorch(S, sp, blast, reduced)
	if blast and why != "miss" and not guard:
		var c := Fx.new()
		c.style = "carry"
		c.slot = slot
		c.vic = vic
		c.dir = dir
		c.col = col
		c.small = reduced
		c.life = p("carry_life")
		fx.append(c)
		made["carry"] = int(made.get("carry", 0)) + 1
		smoke_jobs.append({"slot": vic, "left": int(p("smoke_ticks")) + int(p("carry_life")), "every": int(p("smoke_every")) * (2 if reduced else 1)})


## A scorch where the spill meets the ground: found by walking the ray; drawn, never simulated, and at most `scorch_max` at once.
func _scorch(S: SimState, sp: Fx, blast: bool, reduced: bool) -> void:
	var reach: float = (p("spill_blast_bh") if blast else p("spill_bolt_bh")) * VfxLook.BH
	var steps: int = int(ceil(reach / 10.0))
	for i in range(1, steps + 1):
		var px: float = sp.x + sp.lean.x * 10.0 * float(i)
		var py: float = sp.y + sp.lean.y * 10.0 * float(i)
		var g: float = WorldTerrain.groundY(S, SimWrap.wrap(px))
		if py <= g + 2.0:
			var sc := Fx.new()
			sc.style = "scorch"
			sc.x = SimWrap.wrap(px)
			sc.y = g
			sc.blast = blast
			sc.small = reduced
			sc.life = p("scorch_life")
			sc.slot = sp.slot
			var alive: int = 0
			for q in fx:
				if q.style == "scorch":
					alive += 1
			if alive >= int(p("scorch_max")):
				for q2 in range(fx.size()):
					if fx[q2].style == "scorch":
						fx.remove_at(q2)
						break
			fx.append(sc)
			made["scorch"] = int(made.get("scorch", 0)) + 1
			return


## A stagger long enough to be launched from (the launcher takes any stagger of `stagger_min` ticks or more; a shove's 8 do not): two rising chevrons for as long as it lasts.
func _stagger(S: SimState, e) -> void:
	var vic: int = int(e.actor)
	var slot: int = int(VfxHub._g(e, "target", 1 - vic))
	if vic < 0 or vic > 1 or vic >= S.fighters.size() or slot < 0 or slot > 1 or slot == vic:
		return
	var n: float = float(VfxHub._g(e, "n", 0.0))
	if n < p("stagger_min"):
		return
	for k in range(fx.size() - 1, -1, -1):
		if fx[k].style == "stagger" and fx[k].vic == vic:
			fx.remove_at(k)
	var o := Fx.new()
	o.style = "stagger"
	o.slot = slot
	o.vic = vic
	o.col = VfxPress.lane_of(S, slot)
	o.life = n
	fx.append(o)
	made["stagger"] = int(made.get("stagger", 0)) + 1


## The launch's send-off. The staggered mark is over the moment he is launched.
func _send(S: SimState, e, reduced: bool) -> void:
	var vic: int = int(e.actor)
	var slot: int = int(VfxHub._g(e, "target", 1 - vic))
	if vic < 0 or vic > 1 or vic >= S.fighters.size() or slot < 0 or slot > 1 or slot == vic:
		return
	for k in range(fx.size() - 1, -1, -1):
		if fx[k].style == "stagger" and fx[k].vic == vic:
			fx.remove_at(k)
	var f = S.fighters[vic]
	var o := Fx.new()
	o.style = "send"
	o.slot = slot
	o.vic = vic
	o.x = f.x
	o.y = f.y
	o.lean = Vector2(float(VfxHub._g(e, "ux", 0.0)), float(VfxHub._g(e, "uy", 1.0)))
	if o.lean.length() < 0.1:
		o.lean = Vector2(0.0, 1.0)
	o.lean = o.lean.normalized()
	o.col = VfxPress.lane_of(S, slot)
	o.small = reduced
	o.life = p("send_life")
	fx.append(o)
	made["send"] = int(made.get("send", 0)) + 1
