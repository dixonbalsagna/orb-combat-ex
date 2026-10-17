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
		"carry_life": 10.0, "smoke_every": 3.0, "smoke_ticks": 24.0, "stagger_min": 12.0, "heavy_ticks": 28.0, "chev_period": 12.0, "send_life": 12.0, "alpha": 0.9},
	# Multi-fight and choreography (docs/vfx/multi-fight-plan.md): the duel of perfects, the cash-in, the chase, the shine, the barrage's hand, the ring's tells.
	"multi": {"duel_life": 10.0, "duel_len0": 22.0, "duel_len_per": 5.0, "duel_len_max": 70.0, "duel_r0": 8.0, "duel_r_per": 2.5, "wave_min_level": 3.0, "wave_life": 12.0, "wave_bh": 4.0, "wave_alpha": 0.55,
		"amp_life": 16.0, "amp_ring0": 42.0, "amp_ring_per": 8.0, "cash_tell": 3.0, "cash_life": 10.0, "chase_max": 90.0, "arrive_life": 8.0, "shine_max": 40.0,
		"edge_ticks": 4.0, "edge_life": 5.0, "sweep_len": 9.0, "thrust_len": 8.0, "flick_len": 18.0, "bring_life": 6.0, "bring_flash_r": 38.0,
		"interject_tell": 8.0, "interject_line": 6.0, "alpha": 1.0,
		"calm_mark_gap": 40.0, "struggle_open_life": 10.0, "pulse_period": 20.0, "pulse_life": 8.0, "surge_life": 12.0, "stray_life": 8.0, "end_life": 18.0, "detonate_bh": 2.0},
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
	var kind: String = ""           # a whiff's cause (gave_ground, reach, dodge); a wind-up's cell
	var k: int = 0                  # how a wind-up ended: 2 stopped by a blow, 3 lost
	var strong: bool = false        # a heavy's wind-up (B): the long ring and the committed line
	var fired: bool = false         # a double hit's dust has been thrown

var fx: Array = []
var struggle_on: bool = false              # a beam struggle is on (the cues `beam_struggle` to `beam_end`)
var _last_mark: int = -1000                # the tick of the last surge or stray mark (calm mode keeps them 40 ticks apart)
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


## One number of the multi-fight group.
static func pm(key: String) -> float:
	warm()
	var g = _data.get("multi")
	if g is Dictionary and g.has(key):
		return float(g[key])
	return float(DEFAULTS["multi"][key])


func reset() -> void:
	struggle_on = false
	_last_mark = -1000
	fx.clear()
	made.clear()
	full_ticks.clear()
	last_full = -1000
	shown = 0
	smoke_jobs.clear()


## The flash limit (§5b point 8 and Legal's k05): true when a full flash may be drawn on this tick, and then it takes the slot. Two rules: at least `flash_every` ticks since the
## last one across both fighters (the design's pace), and the screen's register (three a second across every effect, fewer for low-priority sources, none in reduced motion).
func allow_full(S: SimState, col: Color = Color.WHITE, pace: bool = true, radius: float = 19.0, z: float = 0.0) -> bool:
	if pace and S.tick - last_full < int(p("flash_every")):
		return false
	if registry != null and not registry.ask("energy", col, S.tick, VfxFlashRegistry.disc_px(radius, registry.ppu_at(z)), 0.2):
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
		if e.style == "double" and e.age >= 0.0 and not e.fired:
			e.fired = true
			_double_dust(S, e, debris)
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
				"windup":
					_windup(S, e, reduced)
				"charge_full":
					_charge_full(S, e, reduced)
				"launcher_open":
					_launcher_open(S, e)
				"launcher_close":
					_launcher_close(S, e)
				"double_hit":
					_double(S, e, reduced)
				"miss":
					_miss(S, e, reduced, debris)
				"duel":
					_duel(S, e, reduced)
				"duel_end":
					_duel_end(S, e, reduced, debris)
				"cash_in":
					_cash_in(S, e, reduced, debris)
				"chase":
					_chase(S, e, reduced)
				"perfect_window":
					_perfect_window(S, e, reduced)
				"barrage_hand":
					_barrage_hand(S, e, reduced)
				"barrage_land":
					_barrage_land(S, e, reduced)
				"guard_volley":
					_guard_volley(S, e, reduced)
				"beam_struggle":
					_beam_struggle(S, e, reduced)
				"beam_pulse":
					_beam_pulse(S, e, reduced)
				"beam_surge":
					_beam_surge(S, e, reduced)
				"beam_stray":
					_beam_stray(S, e, reduced)
				"beam_end":
					_beam_end(S, e, reduced, debris)
				"perfect_made", "perfect_broken":
					_perfect_end(S, e)
				"tech":
					_tech(S, e, reduced)
				"return":
					_return(S, e, reduced)


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
		# Encounter's `k` on the cue is 1 on the one blow in 20 ticks that may take the full flash; the register still decides. Without it, the 1-in-20 pace is ours.
		var kk: float = float(VfxHub._g(e, "k", -1.0))
		l.big = (not reduced) and (not guard or blast) and (kk < 0.0 or kk >= 1.0) and allow_full(S, col.lightened(0.3), kk < 0.0, 28.0 if blast else 19.0, fv.z)
		fx.append(l)
		made["land"] = int(made.get("land", 0)) + 1
		if l.big:
			made["full_flash"] = int(made.get("full_flash", 0)) + 1
		# Orb, 2026-10-16: the small energy attacks' explosions "more explosive, flames and smoke". A point-blank bolt or blast goes off at the contact as the ranged ones do (VfxExplode on the
		# body: a few flame tongues in waves, growing in, cinders in the shooter's colour, smoke; a guard's is sparks and smoke only). Never a flash: the register's ask above is the only one.
		if debris != null and int(debris.quality) > 0:
			var rad: float = VfxExplode.radius_for("lob" if blast else "bolt", 0.0, 1)
			made["boom"] = int(made.get("boom", 0)) + VfxExplode.at(S, debris, l.x, l.y, fv.z, rad, "fighter", "spark" if guard else "calm", col)
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


## "B now": Encounter's cue `launcher_open` (actor the fighter who may launch, target the staggered one, n the tick the stagger ends (absolute), text the stagger's kind) puts a rising
## chevron on each side of the staggered fighter in the launcher's colour until `launcher_close`, or until the stagger ends.
func _launcher_open(S: SimState, e) -> void:
	var slot: int = int(e.actor)
	var vic: int = int(VfxHub._g(e, "target", 1 - slot))
	if slot < 0 or slot > 1 or slot >= S.fighters.size() or vic < 0 or vic > 1 or vic >= S.fighters.size() or vic == slot:
		return
	for k in range(fx.size() - 1, -1, -1):
		if fx[k].style == "stagger" and fx[k].vic == vic:
			fx.remove_at(k)
	var o := Fx.new()
	o.style = "stagger"
	o.slot = slot
	o.vic = vic
	o.kind = String(e.text)
	o.col = VfxPress.lane_of(S, slot)
	o.life = maxf(float(VfxHub._g(e, "n", float(S.tick) + 20.0)) - float(S.tick), 1.0)
	fx.append(o)
	made["stagger"] = int(made.get("stagger", 0)) + 1
	# The opening's look (Game Design's eleventh round item 1: "the rival's head snaps back and his arms fly open, a ring shows on his chest"; the head and the arms are Animation's): a thin hollow
	# ring on his chest in the launcher's colour, closing in over 4 ticks and then standing steady until the opening ends. Never a flash, never filled; the same in reduced motion.
	for k2 in range(fx.size() - 1, -1, -1):
		if fx[k2].style == "opening" and fx[k2].vic == vic:
			fx.remove_at(k2)
	var ring := Fx.new()
	ring.style = "opening"
	ring.slot = slot
	ring.vic = vic
	ring.col = o.col
	ring.life = o.life
	fx.append(ring)
	made["opening"] = int(made.get("opening", 0)) + 1


func _launcher_close(S: SimState, e) -> void:
	var vic: int = int(VfxHub._g(e, "target", -1))
	var slot: int = int(e.actor)
	for k in range(fx.size() - 1, -1, -1):
		if (fx[k].style == "stagger" or fx[k].style == "opening") and (fx[k].vic == vic or (vic < 0 and fx[k].slot == slot)):
			fx.remove_at(k)
	made["launcher_close"] = int(made.get("launcher_close", 0)) + 1


## A medium's or a heavy's wind-up (cue `windup`, text start: actor, target, source the cell, dur the seconds, n the landing tick, absolute; text end: k 1 thrown, 2 stopped by a blow,
## 3 lost, 4 a miss). A ring on the lead hand closes over the last 10 ticks of a medium's 12 (Y), and over a heavy's whole 28 (B) with the limb's committed line in its last 6: hollow, thin,
## shrinking, lane colour (Legal k01 and k03: one mark, nothing on the body; the heavy's armour is not drawn). It is not a flash and asks nothing. Thrown or a miss: the blow's own looks
## take over; stopped: four fragments fly off the ring; lost: the ring fades. docs/vfx/brawl-three-strength-plan.md section 1.
func _windup(S: SimState, e, reduced: bool) -> void:
	if String(e.text) == "end":
		_windup_end(S, e)
		return
	if String(e.text) == "interject":
		_interject(S, e, reduced)      # a ring guard's grant: the chevrons over his head, not the hand's ring (Encounter's agreed list: the tell is a `windup` with text `interject`)
		return
	var pr: Vector2i = _pair(S, e)
	if pr.x < 0:
		return
	var slot: int = pr.x
	for k in range(fx.size() - 1, -1, -1):
		if fx[k].slot == slot and (fx[k].style == "windup" or fx[k].style == "windup_end"):
			fx.remove_at(k)
	var f = S.fighters[slot]
	var o := Fx.new()
	o.style = "windup"
	o.slot = slot
	o.vic = pr.y
	o.dir = 1.0 if SimWrap.sdx(f.x, S.fighters[pr.y].x) >= 0.0 else -1.0
	o.kind = String(VfxHub._g(e, "source", ""))
	o.col = VfxPress.lane_of(S, slot)
	o.small = reduced
	# Y from B by the cell (`source`), never by `dur` (its unit is not settled); the length is the landing tick (`n`, absolute) minus now, which needs no unit.
	var land: float = float(VfxHub._g(e, "n", -1.0))
	var remaining: float = maxf(land - float(S.tick), 0.0) if land > 0.0 else -1.0
	var src: String = o.kind.to_lower()
	o.strong = src == "b" or src.begins_with("b_") or src.find("heavy") >= 0 or (src == "" and remaining >= 20.0)
	if o.strong:
		# The heavy's ring is there from the press and holds, small and steady, for as long as the charge is held, until the `windup` end cue: so it does not expire.
		o.life = 300.0
		if remaining >= 0.0:
			o.age = clampf(p("heavy_ticks") - remaining, 0.0, p("heavy_ticks"))
	else:
		o.life = maxf(remaining, 2.0)
	fx.append(o)
	var mk: String = "windup_b" if o.strong else "windup_y"
	made[mk] = int(made.get(mk, 0)) + 1


func _windup_end(S: SimState, e) -> void:
	var slot: int = int(e.actor)
	var kk: int = int(float(VfxHub._g(e, "k", 1.0)))
	for i in range(fx.size() - 1, -1, -1):
		var w: Fx = fx[i]
		if w.slot == slot and w.style == "windup":
			fx.remove_at(i)
			if kk == 2 or kk == 3:
				var o := Fx.new()
				o.style = "windup_end"
				o.slot = slot
				o.vic = w.vic
				o.dir = w.dir
				o.col = w.col
				o.k = kk
				o.small = w.small
				o.life = 6.0 if kk == 2 else 4.0
				fx.append(o)
			var mk: String = "windup_end_%d" % kk
			made[mk] = int(made.get(mk, 0)) + 1
			return


## The heavy's charge is full (cue `charge_full`: actor, the cell b): one thin ring leaves the charging hand, 8 units out to 24 over 4 ticks, with three short ticks beside it, in his lane colour:
## a thin edge flash on the hand, never a ball, never body-wide, never gold, white or red (Legal's k03). It asks the register as `charge_full` (a skill moment: not a low source); refused, the held
## ring simply goes on. Reduced motion: the ring stands at 14 units for its 4 ticks and does not widen. The ring that holds from the press is not a flash and asks nothing.
func _charge_full(S: SimState, e, reduced: bool) -> void:
	var slot: int = int(e.actor)
	if slot < 0 or slot > 1 or slot >= S.fighters.size():
		return
	var other: int = int(VfxHub._g(e, "target", 1 - slot))
	if other < 0 or other > 1 or other == slot:
		other = 1 - slot
	var f = S.fighters[slot]
	var o := Fx.new()
	o.style = "chargeflash"
	o.slot = slot
	o.vic = other
	o.dir = 1.0 if SimWrap.sdx(f.x, S.fighters[other].x) >= 0.0 else -1.0
	o.col = VfxPress.lane_of(S, slot)
	o.small = reduced
	o.life = 4.0
	o.big = registry == null or registry.ask("charge_full", o.col.lightened(0.3), S.tick, VfxFlashRegistry.ring_px(24.0, 2.2, registry.ppu_at(S.fighters[slot].z)), 0.15)
	fx.append(o)
	made["charge_full"] = int(made.get("charge_full", 0)) + 1
	if o.big:
		made["charge_flash"] = int(made.get("charge_flash", 0)) + 1


## The double hit (cue `double_hit`, 8 ticks ahead: actor and target the two slots, n the landing tick, absolute): at the landing two contact looks at the same instant, mirrored, one on
## each face line: a crossed crack, sparks and a hollow ring each, in each fighter's own colour, and one small flash for the pair if the register grants it (`double_hit`, a big moment);
## then dust along the ground under each as they are thrown apart. Legal's k04: sparks at the contact only, no rubble ring with cracks and wind, no lightning, no body-wide aura, no gold,
## white or red.
func _double(S: SimState, e, reduced: bool) -> void:
	var pr: Vector2i = _pair(S, e)
	if pr.x < 0:
		return
	var o := Fx.new()
	o.style = "double"
	o.slot = pr.x
	o.vic = pr.y
	o.dir = 1.0 if SimWrap.sdx(S.fighters[pr.x].x, S.fighters[pr.y].x) >= 0.0 else -1.0
	o.col = VfxPress.lane_of(S, pr.x)
	o.small = reduced
	o.life = 12.0
	var land: float = float(VfxHub._g(e, "n", float(S.tick) + 8.0))
	o.age = -maxf(land - float(S.tick), 0.0)
	o.big = (not reduced) and registry != null and registry.ask("double_hit", o.col.lightened(0.3), S.tick, VfxFlashRegistry.disc_px(22.0, registry.ppu_at(S.fighters[pr.x].z)), 0.2)
	fx.append(o)
	made["double"] = int(made.get("double", 0)) + 1


## A whiff (cue `miss`: actor the one who missed, target the rival, text gave_ground, reach or dodge): the blow's arc cuts the air and ends in nothing, a thin line in his colour for 8
## ticks, and a little dust at the feet of whoever moved (the rival who gave ground or slipped, or the attacker whose blow fell short). A wound blow that misses leaves him open for 20
## ticks; this is only the picture of it.
func _miss(S: SimState, e, reduced: bool, debris) -> void:
	var pr: Vector2i = _pair(S, e)
	if pr.x < 0:
		return
	var f = S.fighters[pr.x]
	var o := Fx.new()
	o.style = "whiff"
	o.slot = pr.x
	o.vic = pr.y
	o.dir = 1.0 if SimWrap.sdx(f.x, S.fighters[pr.y].x) >= 0.0 else -1.0
	o.kind = String(e.text)
	o.x = f.x
	o.y = f.y
	o.lean = Vector2(36.0 if o.kind == "reach" else clampf(absf(SimWrap.sdx(f.x, S.fighters[pr.y].x)) - 8.0, 20.0, 80.0), 0.0)   # how far the empty arc reaches
	o.col = VfxPress.lane_of(S, pr.x)
	o.small = reduced
	o.life = 8.0
	fx.append(o)
	made["whiff"] = int(made.get("whiff", 0)) + 1
	var mk: String = "whiff_" + o.kind
	made[mk] = int(made.get(mk, 0)) + 1
	if debris != null and int(debris.quality) > 0:
		var mover = S.fighters[pr.y] if o.kind != "reach" else f
		var away: float = o.dir if o.kind != "reach" else -o.dir
		var puffs: int = 1 if reduced else 3
		for k in range(puffs):
			debris.dust_puff(VfxPalette.biome_key(mover.x), mover.x + away * (6.0 + 8.0 * float(k)), mover.y + 4.0, 0.0, away * (30.0 + 20.0 * float(k)), 18.0, 14.0, 34.0, 0.5, 0)
		made["whiff_dust"] = int(made.get("whiff_dust", 0)) + puffs


## The dust a double hit throws, at the landing: along the ground under each fighter, away from the other.
func _double_dust(S: SimState, e: Fx, debris) -> void:
	if debris == null or int(debris.quality) <= 0:
		return
	for who in [e.slot, e.vic]:
		var f = S.fighters[int(who)]
		var away: float = e.dir if int(who) == e.vic else -e.dir       # the first is thrown against dir, the second along it
		for k in range(2 if e.small else 4):
			debris.dust_puff(VfxPalette.biome_key(f.x), f.x - away * (4.0 + 7.0 * float(k)), f.y + 4.0, 0.0, away * (50.0 + 24.0 * float(k)), 16.0, 20.0, 52.0, 0.55, 0)
	made["double_dust"] = int(made.get("double_dust", 0)) + 1


## The launch's send-off. The staggered mark is over the moment he is launched.
func _send(S: SimState, e, reduced: bool) -> void:
	var vic: int = int(e.actor)
	var slot: int = int(VfxHub._g(e, "target", 1 - vic))
	if vic < 0 or vic > 1 or vic >= S.fighters.size() or slot < 0 or slot > 1 or slot == vic:
		return
	for k in range(fx.size() - 1, -1, -1):
		if (fx[k].style == "stagger" or fx[k].style == "opening") and fx[k].vic == vic:
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


# ---------------------------------------------------------------------------------------------------- multi-fight and choreography
# Cue names proposed to Encounter (docs/vfx/multi-fight-plan.md). Every one is a hollow ring, a thin line or a short streak in a lane colour; none is a flash disc, and the only register ask
# is the barrage's last landing (`energy`, a disc of at most 0.4 of the threshold, none in reduced motion). Slots may be any body (a guard is slot 2 or more): `_pair_any` takes every
# slot the state holds.

func _pair_any(S: SimState, e) -> Vector2i:
	var slot: int = int(e.actor)
	var n: int = S.fighters.size()
	var vic: int = int(VfxHub._g(e, "target", (1 - slot) if (slot == 0 or slot == 1) else -1))
	if slot < 0 or slot >= n or vic < 0 or vic >= n or vic == slot:
		return Vector2i(-1, -1)
	return Vector2i(slot, vic)


func _dir_between(S: SimState, a: int, b: int) -> float:
	return 1.0 if SimWrap.sdx(S.fighters[a].x, S.fighters[b].x) >= 0.0 else -1.0


func _drop(style: String, slot: int = -1) -> void:
	for i in range(fx.size() - 1, -1, -1):
		if fx[i].style == style and (slot < 0 or fx[i].slot == slot):
			fx.remove_at(i)


## The duel of perfects (cue `duel`: actor the fighter who has just perfect-blocked and answers, target the rival, k the level 1 to 8): at the middle of the pair a crossed crack, a hollow
## ring and sparks that grow with the level, one limb of the cross in each fighter's colour; from level 3 a thin shockwave ring runs out along the ground (the glass and the cracked ground
## are the hub's, `VfxHub._duel_wave`). One mark at a time: a new level replaces the last. No disc, no flash, nothing on the body.
func _duel(S: SimState, e, reduced: bool) -> void:
	var pr: Vector2i = _pair_any(S, e)
	if pr.x < 0:
		return
	var lvl: int = clampi(int(float(VfxHub._g(e, "k", 1.0))), 1, 8)
	_drop("duel")
	var fa = S.fighters[pr.x]
	var fv = S.fighters[pr.y]
	var d: float = SimWrap.sdx(fa.x, fv.x)
	var o := Fx.new()
	o.style = "duel"
	o.slot = pr.x
	o.vic = pr.y
	o.dir = 1.0 if d >= 0.0 else -1.0
	o.x = SimWrap.wrap(fa.x + d * 0.5)
	o.y = (fa.y + fv.y) * 0.5 + 50.0
	o.k = lvl
	o.col = VfxPress.lane_of(S, pr.x)
	o.small = reduced
	o.life = pm("duel_life")
	fx.append(o)
	made["duel"] = int(made.get("duel", 0)) + 1
	if lvl >= int(pm("wave_min_level")):
		var w := Fx.new()
		w.style = "wave"
		w.slot = pr.x
		w.vic = pr.y
		w.x = o.x
		w.y = WorldTerrain.groundY(S, o.x)
		w.k = lvl
		w.col = o.col
		w.small = reduced
		w.life = pm("wave_life")
		fx.append(w)
		made["wave"] = int(made.get("wave", 0)) + 1


## The end of a duel, or the cash-in's send (cue `duel_end`: actor the one whose blow lands, target the one sent, k the level, text amplified, cash_in or apart; x and y the stick's lean):
## the send-off drawn wider by the level, a ground ring, rims, dust along the ground under the one sent; `apart` (level 8) sends both. Never a flash: the amplified send is a moment of weight.
func _duel_end(S: SimState, e, reduced: bool, debris) -> void:
	var pr: Vector2i = _pair_any(S, e)
	if pr.x < 0:
		return
	var lvl: int = clampi(int(float(VfxHub._g(e, "k", 1.0))), 1, 8)
	var how: String = String(e.text)
	_drop("duel")
	var dir: float = _dir_between(S, pr.x, pr.y)
	var whom: Array = [[pr.x, pr.y, dir]]
	if how == "apart":
		whom.append([pr.y, pr.x, -dir])
	for w in whom:
		var snd: int = int(w[0])
		var rcv: int = int(w[1])
		var wd: float = float(w[2])
		var fr = S.fighters[rcv]
		var o := Fx.new()
		o.style = "amped"
		o.slot = snd
		o.vic = rcv
		o.dir = wd
		o.x = fr.x
		o.y = fr.y
		o.k = lvl
		o.kind = how
		o.lean = _lean_of(e, wd)
		o.col = VfxPress.lane_of(S, snd)
		o.small = reduced
		o.life = pm("amp_life")
		fx.append(o)
		for who in [snd, rcv]:
			var r := Fx.new()
			r.style = "rim"
			r.slot = snd
			r.vic = int(who)
			r.dir = wd if int(who) == snd else -wd
			r.col = o.col
			r.life = p("rim_life")
			r.small = reduced
			fx.append(r)
		if debris != null and int(debris.quality) > 0:
			var puffs: int = 1 if reduced else 2 + lvl / 2
			for k in range(puffs):
				debris.dust_puff(VfxPalette.biome_key(fr.x), fr.x - wd * (4.0 + 7.0 * float(k)), fr.y + 4.0, 0.0, wd * (50.0 + 24.0 * float(k)), 16.0, 20.0, 52.0, 0.55, 0)
	made["amped"] = int(made.get("amped", 0)) + whom.size()
	made["rim"] = int(made.get("rim", 0)) + 2 * whom.size()


## The cash-in (cue `cash_in`: actor, target, n the contact tick, absolute; the heavy lands 2 ticks after the press): the sure blow's tell, drawn in 2 or 3 ticks (a thin committed line
## from the hand to the chest and four corner brackets closing on it: nothing to block), then at the contact a double ring, a crossed crack and one thin vertical cut through the chest.
## No disc and no register ask. The heavy's own looks (the press styles) come with the blow as always.
func _cash_in(S: SimState, e, reduced: bool, debris) -> void:
	var pr: Vector2i = _pair_any(S, e)
	if pr.x < 0:
		return
	var land: float = float(VfxHub._g(e, "n", float(S.tick) + 2.0))
	var remaining: float = maxf(land - float(S.tick), 1.0)
	var dir: float = _dir_between(S, pr.x, pr.y)
	var t := Fx.new()
	t.style = "cash_tell"
	t.slot = pr.x
	t.vic = pr.y
	t.dir = dir
	t.col = VfxPress.lane_of(S, pr.x)
	t.small = reduced
	t.life = maxf(remaining, pm("cash_tell"))
	fx.append(t)
	var h := Fx.new()
	h.style = "cash_hit"
	h.slot = pr.x
	h.vic = pr.y
	h.dir = dir
	h.col = t.col
	h.small = reduced
	h.life = pm("cash_life")
	h.age = -remaining
	fx.append(h)
	made["cash_in"] = int(made.get("cash_in", 0)) + 1
	if debris != null and int(debris.quality) > 0 and not reduced:
		var fv = S.fighters[pr.y]
		for k in range(2):
			debris.dust_puff(VfxPalette.biome_key(fv.x), fv.x - dir * (4.0 + 8.0 * float(k)), fv.y + 4.0, 0.0, dir * (40.0 + 20.0 * float(k)), 14.0, 16.0, 40.0, 0.5, 0)
		made["cash_dust"] = int(made.get("cash_dust", 0)) + 2


## The chase (cue `chase`: actor the chaser, target the rival; text start, blow, arrive or end): while he follows the flying body a thin lane-colour trail runs behind the chaser along his real
## path (the drawn travel, never a jump); each blow of it and the arrival put four corner brackets and a flat ring on the rival's chest. Ends on `end`, or after 90 ticks.
func _chase(S: SimState, e, reduced: bool) -> void:
	var pr: Vector2i = _pair_any(S, e)
	if pr.x < 0:
		return
	var how: String = String(e.text)
	if how == "end":
		_drop("chase", pr.x)
		made["chase_end"] = int(made.get("chase_end", 0)) + 1
		return
	if how == "start" or how == "":
		_drop("chase", pr.x)
		var c := Fx.new()
		c.style = "chase"
		c.slot = pr.x
		c.vic = pr.y
		c.dir = _dir_between(S, pr.x, pr.y)
		c.col = VfxPress.lane_of(S, pr.x)
		c.small = reduced
		c.life = pm("chase_max")
		fx.append(c)
		made["chase"] = int(made.get("chase", 0)) + 1
		return
	var a := Fx.new()
	a.style = "arrive"
	a.slot = pr.x
	a.vic = pr.y
	a.dir = _dir_between(S, pr.x, pr.y)
	a.col = VfxPress.lane_of(S, pr.x)
	a.small = reduced
	a.kind = how
	a.life = pm("arrive_life")
	fx.append(a)
	made["arrive"] = int(made.get("arrive", 0)) + 1


## The striking hand that shines while a perfect window is open on a light (Encounter's agreed cue `perfect_window`: actor the attacker whose hit landed, target the defender, text the landed hit's strength
## light, medium or heavy, n the tick it closes, absolute): two thin edge lines along the fist and a small hollow ring on it, steady (no pulse: nothing flickers), in his lane colour lightened. Only a light's
## window shines (Game Design's eleventh round item 1: "the striking hand takes a small shine while the window is open"; a medium's or a heavy's has no hold). It ends at `n`, or earlier on `perfect_made`
## or `perfect_broken`. Reduced motion draws the same: it is still. Legal fx01.
func _perfect_window(S: SimState, e, reduced: bool) -> void:
	var pr: Vector2i = _pair_any(S, e)
	if pr.x < 0:
		return
	_drop("shine", pr.x)
	if String(e.text) != "light":
		return
	var o := Fx.new()
	o.style = "shine"
	o.slot = pr.x
	o.vic = pr.y
	o.dir = _dir_between(S, pr.x, pr.y)
	o.col = VfxPress.lane_of(S, pr.x)
	o.small = reduced
	var close: float = float(VfxHub._g(e, "n", float(S.tick) + 6.0))
	o.life = clampf(close - float(S.tick), 2.0, pm("shine_max"))
	fx.append(o)
	made["shine"] = int(made.get("shine", 0)) + 1


## `perfect_made` (the follow-up is thrown) and `perfect_broken` (the window was lost) end the shine on the attacker (actor).
func _perfect_end(S: SimState, e) -> void:
	var slot: int = int(e.actor)
	_drop("shine", slot)
	made["shine_close"] = int(made.get("shine_close", 0)) + 1


## The rival's tech (cue `tech`: actor the rival who techs, target the chaser): the chase breaks. The chaser's trail goes, and a thin ring and two short streaks show where they part, in the techer's colour.
func _tech(S: SimState, e, reduced: bool) -> void:
	var pr: Vector2i = _pair_any(S, e)
	if pr.x < 0:
		return
	_drop("chase", pr.y)
	var a := Fx.new()
	a.style = "arrive"
	a.slot = pr.x
	a.vic = pr.x
	a.dir = _dir_between(S, pr.x, pr.y)
	a.col = VfxPress.lane_of(S, pr.x)
	a.small = reduced
	a.kind = "tech"
	a.life = pm("arrive_life")
	fx.append(a)
	made["tech"] = int(made.get("tech", 0)) + 1


## The return from a send (cue `return`: actor the fighter back from a send, target the defender, text charge, lunge or far, n the approach's length in ticks, amount its crouch): a thin trail behind him along
## his real path for the length of the approach, as a chase has (the approach is drawn travel, never a jump). The wind-up of his first blow back is the existing `windup` ring (text `return`).
func _return(S: SimState, e, reduced: bool) -> void:
	var pr: Vector2i = _pair_any(S, e)
	if pr.x < 0:
		return
	_drop("chase", pr.x)
	var c := Fx.new()
	c.style = "chase"
	c.slot = pr.x
	c.vic = pr.y
	c.dir = _dir_between(S, pr.x, pr.y)
	c.col = VfxPress.lane_of(S, pr.x)
	c.small = reduced
	c.life = clampf(float(VfxHub._g(e, "n", 20.0)), 4.0, pm("chase_max"))
	fx.append(c)
	made["return"] = int(made.get("return", 0)) + 1


## The Anti-hero's barrage, the hand (cue `barrage_hand`: actor, target, k the volley 1 to 3, text sweep, thrust or flick, n the release tick, absolute): a thin lit edge along the hand for the
## 4 ticks before the release (never a ball, Legal e06): half the usual length for the sweep, one knuckle for the thrust, the fullest for the flick, which also fans a short cone of three
## streaks at the release. docs/vfx/barrage-flash-plan.md.
func _barrage_hand(S: SimState, e, reduced: bool) -> void:
	var pr: Vector2i = _pair_any(S, e)
	if pr.x < 0:
		return
	var rel: float = float(VfxHub._g(e, "n", float(S.tick) + 4.0))
	var wait: float = maxf(rel - float(S.tick) - pm("edge_ticks"), 0.0)
	var o := Fx.new()
	o.style = "edge"
	o.slot = pr.x
	o.vic = pr.y
	o.dir = _dir_between(S, pr.x, pr.y)
	o.kind = String(e.text)
	o.k = clampi(int(float(VfxHub._g(e, "k", 1.0))), 1, 3)
	o.col = VfxPress.lane_of(S, pr.x)
	o.small = reduced
	o.life = pm("edge_life")
	o.age = -wait
	fx.append(o)
	made["edge"] = int(made.get("edge", 0)) + 1


## The barrage's landing (cue `barrage_land`: actor, target, k the volley 1 to 3, text hit, guard or miss; x and y the lean): a rim on the rival (a thin edge, never a flash over the body), a
## ring on the second and third volleys, and on the third, if it hit and the register grants it (`energy`, a disc of at most 0.4 of the threshold, none in reduced motion), the one full flash.
func _barrage_land(S: SimState, e, reduced: bool) -> void:
	var pr: Vector2i = _pair_any(S, e)
	if pr.x < 0:
		return
	var vol: int = clampi(int(float(VfxHub._g(e, "k", 1.0))), 1, 3)
	var why: String = String(e.text)
	if why == "miss":
		return
	var dir: float = _dir_between(S, pr.x, pr.y)
	var col: Color = VfxPress.lane_of(S, pr.x)
	var r := Fx.new()
	r.style = "rim"
	r.slot = pr.x
	r.vic = pr.y
	r.dir = dir
	r.col = col
	r.life = p("rim_life")
	r.small = reduced
	fx.append(r)
	made["rim"] = int(made.get("rim", 0)) + 1
	if vol >= 2:
		var b := Fx.new()
		b.style = "bring"
		b.slot = pr.x
		b.vic = pr.y
		b.dir = dir
		b.col = col
		b.small = reduced
		b.life = pm("bring_life")
		b.guard = why == "guard"
		if vol == 3 and why == "hit" and not reduced:
			b.big = allow_full(S, col.lightened(0.3), true, pm("bring_flash_r"), S.fighters[pr.y].z)
		fx.append(b)
		made["bring"] = int(made.get("bring", 0)) + 1
		if b.big:
			made["full_flash"] = int(made.get("full_flash", 0)) + 1


## A guard's bolt (cue `guard_volley`: actor the guard, target the one, k the bolt 1 to 3, n the release tick, absolute): the bolt's palm comes up on the guard's hand as it does on any
## fighter's (the `lit` look: a small hollow ring and two streaks, gone at the release), in the guard's own lane colour, so the ring blow reads as his and not as a new effect.
func _guard_volley(S: SimState, e, reduced: bool) -> void:
	var pr: Vector2i = _pair_any(S, e)
	if pr.x < 0:
		return
	var rel: float = float(VfxHub._g(e, "n", float(S.tick) + 4.0))
	var o := Fx.new()
	o.style = "lit"
	o.slot = pr.x
	o.vic = pr.y
	o.dir = _dir_between(S, pr.x, pr.y)
	o.col = VfxPress.lane_of(S, pr.x)
	o.small = reduced
	o.life = maxf(rel - float(S.tick), 1.0) + 1.0
	fx.append(o)
	made["guard_volley"] = int(made.get("guard_volley", 0)) + 1


## An interjection's tell (Encounter's agreed cue is `windup` with text `interject`, routed here: actor the ring guard, target the one, source x, y or bolt, n the contact tick, absolute; in sight for 8 ticks or more): two small hollow
## chevrons over the guard's head that point at the one and close up over the tell, and in its last 6 ticks the blow's committed line from his hand to the one's chest: thin, lane colour,
## nothing on the body, no flash. A bolt keeps the chevrons only (its palm is the `lit` look of `guard_volley`).
func _interject(S: SimState, e, reduced: bool) -> void:
	var pr: Vector2i = _pair_any(S, e)
	if pr.x < 0:
		return
	_drop("interject", pr.x)
	var land: float = float(VfxHub._g(e, "n", float(S.tick) + pm("interject_tell")))
	var o := Fx.new()
	o.style = "interject"
	o.slot = pr.x
	o.vic = pr.y
	o.dir = _dir_between(S, pr.x, pr.y)
	o.kind = String(VfxHub._g(e, "source", "x"))
	o.col = VfxPress.lane_of(S, pr.x)
	o.small = reduced
	o.life = maxf(land - float(S.tick), 2.0)
	fx.append(o)
	made["interject"] = int(made.get("interject", 0)) + 1


# --------------------------------------------------------------------------------------------------------------------------------- the beam struggle
# Encounter's tug of war on the pulse (docs/director/pending/beam-struggle/README.md; Game Design's rule-of-cool §2): `S.game.clash.mid` is the meeting point, 0 at A's hands to 1 at D's, -1 (or absent) for a clash with
# no struggle; the cues are `beam_struggle` (text start, n the tick it ends by at the latest), `beam_pulse` (k the pulse 1 to 15, n its tick), `beam_surge` (actor who pressed, text surge or sharp),
# `beam_stray` (actor) and `beam_end` (text overwhelmed, detonate or time; x the point). What a player sees (the design: "each surge bulges the meeting point toward the rival and pushes his beam back; a stray
# flickers his own; the pulse is a beat the player can follow"): every mark is a thin hollow ring or line in a lane colour, none is a flash, and none changes the beams' brightness.
#   beat      a thin ring contracts onto the meeting point over the 10 ticks before each pulse and, on it, one thin ring leaves: so the beat can be followed before it comes (the next pulse is shown the moment this one is)
#   surge     a thin ring rides his beam from his hand to the point, and a thin ring bulges at the point toward the rival (a sharp one is bigger)
#   stray     a short broken line across his own beam near his hand, a hiccup: shape only, nothing flickers
#   end       overwhelmed: three thin rings run down the winner's beam from the point to the loser; detonate: two rings and a fire at the point (the flames in waves, as any blast's); time: one ring

func _beam_struggle(S: SimState, e, reduced: bool) -> void:
	if String(e.text) != "start":
		return
	_drop("spulse")
	_drop("sopen")
	var o := Fx.new()
	o.style = "sopen"
	o.slot = int(e.actor)
	o.small = reduced
	o.life = pm("struggle_open_life")
	fx.append(o)
	made["struggle"] = int(made.get("struggle", 0)) + 1
	struggle_on = true


## Calm mode (Legal's fx04, RL-141 to RL-143): under Reduce flashing (the shipped default) or Reduced motion the struggle's marks are held to **1.5 Hz or slower**, strokes only, no brightness change. The register's
## `reduced` is true for either setting (the hub sets it every tick), so it is the one test. Calm: the beat's rings are drawn for every second pulse only (a 40-tick beat, 1.5 Hz: the pulses are still every 20 ticks,
## and the player keeps the half-beat's rhythm), and a surge's or a stray's mark is not made within 40 ticks of the last one (the meeting point's own movement still shows each press). The rates are in
## `data/vfx/energy.json` "rates" (the list the flash set and `effects_check` read).
func _calm(reduced: bool) -> bool:
	return reduced or (registry != null and registry.reduced)


## A pulse: the ring that contracts onto the point and the one that leaves it, and the next pulse's contraction, shown at once.
func _beam_pulse(S: SimState, e, reduced: bool) -> void:
	_drop("spulse")
	var k: int = int(float(VfxHub._g(e, "k", 1.0)))
	var n_at: float = float(VfxHub._g(e, "n", float(S.tick)))
	var calm: bool = _calm(reduced)
	for j in range(2):
		if j == 1 and k >= 15:
			break
		if calm and (k + j) % 2 == 0:
			continue       # fx04: every second pulse's rings only
		var o := Fx.new()
		o.style = "spulse"
		o.small = reduced
		o.k = k + j
		o.age = -(maxf(n_at - float(S.tick), 0.0) + float(j) * pm("pulse_period"))
		o.life = pm("pulse_life")
		fx.append(o)
	made["pulse"] = int(made.get("pulse", 0)) + 1


## A surge (actor the one who pressed on the beat, text surge, or sharp for the 1-tick one).
func _beam_surge(S: SimState, e, reduced: bool) -> void:
	var slot: int = int(e.actor)
	if slot < 0 or slot >= S.fighters.size():
		return
	if _calm(reduced):
		if S.tick - _last_mark < int(pm("calm_mark_gap")):
			return
		_last_mark = S.tick
	var o := Fx.new()
	o.style = "ssurge"
	o.slot = slot
	o.col = VfxPress.lane_of(S, slot)
	o.small = reduced
	o.big = String(e.text) == "sharp"
	o.life = pm("surge_life")
	fx.append(o)
	made["surge"] = int(made.get("surge", 0)) + 1
	if o.big:
		made["surge_sharp"] = int(made.get("surge_sharp", 0)) + 1


## A stray (actor the one who pressed off the beat): a hiccup in his own beam.
func _beam_stray(S: SimState, e, reduced: bool) -> void:
	var slot: int = int(e.actor)
	if slot < 0 or slot >= S.fighters.size():
		return
	if _calm(reduced):
		if S.tick - _last_mark < int(pm("calm_mark_gap")):
			return
		_last_mark = S.tick
	var o := Fx.new()
	o.style = "sstray"
	o.slot = slot
	o.col = VfxPress.lane_of(S, slot)
	o.small = reduced
	o.life = pm("stray_life")
	fx.append(o)
	made["stray"] = int(made.get("stray", 0)) + 1


## The end (text overwhelmed, detonate or time; x the point 0 to 1): where the point was is kept, because the clash is over a tick later.
func _beam_end(S: SimState, e, reduced: bool, debris) -> void:
	_drop("spulse")
	struggle_on = false
	var how: String = String(e.text)
	var pt: float = float(VfxHub._g(e, "x", 0.5))
	var c = S.game.clash
	var o := Fx.new()
	o.style = "send_" + how
	o.k = 0
	o.lean = Vector2(pt, 0.0)
	o.small = reduced
	o.life = pm("end_life")
	if c != null:
		var fa: int = S.fighters.find(c.A)
		var fd: int = S.fighters.find(c.D)
		o.slot = fa
		o.vic = fd
		var d: float = SimWrap.sdx(c.A.x, c.D.x)
		o.x = SimWrap.wrap(c.A.x + d * pt)
		o.y = c.A.y + 38.0 + (c.D.y - c.A.y) * pt
		o.dir = 1.0 if d >= 0.0 else -1.0
		o.col = VfxPress.lane_of(S, fa if pt >= 0.5 else fd)       # the winner's colour: the loser is the side the point reached
	else:
		o.x = float(VfxHub._g(e, "x", 0.0))
		o.y = 0.0
		o.slot = int(e.actor)
		o.vic = int(VfxHub._g(e, "target", 1 - o.slot))
		o.col = Color(0.7, 0.8, 1.0)
	fx.append(o)
	made["struggle_end_" + how] = int(made.get("struggle_end_" + how, 0)) + 1
	if how == "detonate" and debris != null and int(debris.quality) > 0:
		var lane: Color = Color(0.0, 0.0, 0.0, 0.0)
		VfxExplode.at(S, debris, o.x, o.y, 0.0, pm("detonate_bh") * VfxLook.BH, "air", "calm", lane)
		made["struggle_boom"] = int(made.get("struggle_boom", 0)) + 1
