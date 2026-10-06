class_name VfxPress
extends RefCounted
## The melee press styles on screen (Orb's approved reference docs/ep/prototypes/melee-trade-v2.html; Orb, 2026-10-04: timed blows instant with an after-image,
## mashed blows fast with a fluid blur, held blows the most fluid with warping and smears). Each blow gets the look of the way it was pressed:
##
##   speed (mashed)  a soft, filled, overlapping blur along the fist's path (soft discs, layered) and a small round contact ring
##   tech  (timed)   three sharp wireframe echoes of the body between the old pose and the strike, popping off one at a time from the back to the front,
##                   a thin straight speed line and a hard diamond contact mark
##   heavy (held)    a charge ring that shrinks on the wind-up (cue tell_heavy); on the release a filled crescent smear and stacked body ghosts, and a double
##                   contact ring; when the heavy is a string's ender (the sim's `knockback`) the target flies with ghosts behind him
##   block           a shield line and a block flash, never a knock-back
##
## Today's drivers (what exists): a `damage` event of kind light, heavy or guard names the blow (attacker, victim, region); the style comes from the beat's
## own `style` field when the director sends one (Encounter will), else from the attacker's press log (DirAlchemy.read, read only: the classifier's
## style rhythm = tech, mash or taps = speed, hold = heavy), else speed; kind heavy is heavy and kind guard is block. cue tell_heavy starts the wind-up.
## What it still estimates is listed in docs/vfx/press-styles.md: the old pose (the fighter's position some ticks ago stands in for it) and the limb path
## (the fist runs from his guard in front of the chest to the contact point). All of it is drawn by shots_view.gd; presentation only, no random number.

const DEFAULTS: Dictionary = {
	"press": {"hist": 64.0, "reach": 24.0, "lunge": 12.0, "echo_back": 24.0, "glint_life": 5.0, "glint_r": 14.0, "alpha": 0.9,
		"speed_life": 8.0, "speed_ring_life": 6.0, "speed_w": 7.0, "speed_ring_r": 20.0,
		"tech_life": 11.0, "echo_pop": 2.5, "line_life": 7.0, "diamond_life": 5.0, "diamond_r": 14.0,
		"wind_life": 26.0, "wind_r": 34.0, "heavy_life": 18.0, "ghost_life": 8.0, "crescent_life": 8.0, "ring_life": 12.0, "ring_r": 40.0, "fly_max": 40.0, "fly_ghosts": 3.0,
		"block_life": 12.0, "flash_life": 7.0, "shield_h": 40.0},
}
const STYLES: Array = ["speed", "tech", "heavy", "block"]
## The joints a pose is drawn from (Animation's rig names), in the order the view reads them.
const JOINTS: Array = ["head", "neck", "spine_2", "pelvis", "upper_arm_r", "forearm_r", "hand_r", "upper_arm_l", "forearm_l", "hand_l", "thigh_l", "shin_l", "foot_l", "thigh_r", "shin_r", "foot_r"]
## Tests set this to fake Animation's AnimFighter: Callable(S, slot) -> an object with press, press_ring, press_path, press_pose(k), vface; unset it reads RenderAnim.
static var anim_hook: Callable = Callable()
## A body's proportions in units (a fighter is about 75 tall, VfxLook.BH): hip, shoulder, neck and head centre above the feet, head radius, and the guard
## fist (forward of the chest and its height).
const HIP: float = 34.0
const SHOULDER: float = 54.0
const HEAD_Y: float = 68.0
const HEAD_R: float = 8.0
const GUARD: Vector2 = Vector2(20.0, 50.0)

class Fx:
	var style: String = ""
	var slot: int = 0               # the attacker (the defender for a block's shield)
	var vic: int = 0
	var dir: float = 1.0            # attacker toward victim: 1 right, -1 left
	var ax: float = 0.0             # anchor: the attacker's world x at the blow, y of his feet
	var ay: float = 0.0
	var lunge: float = 12.0         # how far the body went from the old pose to the strike (units, along dir)
	var cx: float = 0.0             # the contact point, as an offset from the anchor
	var cy: float = 0.0             # ... and its height above the feet
	var age: float = 0.0
	var life: float = 8.0
	var hand: int = 0               # which fist (speed alternates)
	var col: Color = Color.WHITE
	var col2: Color = Color.WHITE
	var small: bool = false         # reduced motion or a low-quality tick: the short form
	var real: bool = false          # Animation's hand-off was used: ja and jb are real poses, path the real fist path
	var ghosts: int = 0             # how many after-images Animation asks for (press.ghosts), 0: ours
	var ja: PackedVector2Array = PackedVector2Array()   # the old pose's joints (JOINTS order), offsets from its anchor, x turned to the world
	var jb: PackedVector2Array = PackedVector2Array()   # the strike pose's joints
	var old_dx: float = 0.0         # where the old pose's anchor was, along x, from the blow's anchor
	var path: PackedVector2Array = PackedVector2Array() # the striking limb's tip over the last solves, offsets from the anchor (feet), oldest first

class Wind:
	var on: bool = false
	var t: float = 0.0
	var ax: float = 0.0
	var ay: float = 0.0
	var dir: float = 1.0
	var col: Color = Color.WHITE

var fx: Array = []                  # Fx, oldest first
var wind: Array = [Wind.new(), Wind.new()]
var fly: Array = [0.0, 0.0]         # ticks of flight left per slot (a heavy ender's target)
var hist: Array = [[], []]          # per slot: Vector2 (world x, y) of the last ticks, newest last
var made: Dictionary = {}           # counters by style, for the tests
var shown: int = 0                  # effects drawn last frame (the tests)
var beat_glint: bool = false        # the beat option (UI's ring for every blow, the rival's too): a glint on the striking limb at the beat. hub.beat_glint_enabled sets it
var clock: int = 0

static var _data: Dictionary = {}
static var _loaded: bool = false


static func warm() -> void:
	if _loaded:
		return
	_loaded = true
	var path := "res://data/vfx/press.json"
	if FileAccess.file_exists(path):
		var v = JSON.parse_string(FileAccess.get_file_as_string(path))
		if v is Dictionary:
			_data = v


static func p(key: String) -> float:
	warm()
	var g = _data.get("press")
	if g is Dictionary and g.has(key):
		return float(g[key])
	return float(DEFAULTS["press"][key])


func reset() -> void:
	fx.clear()
	wind = [Wind.new(), Wind.new()]
	fly = [0.0, 0.0]
	hist = [[], []]
	made = {}
	clock = 0
	warm()


## What the director wrote on the strike beat that has just landed for this attacker (Encounter's B0, docs/director/brawl-b0.md: style, grade, k, n, closing, charge, hand
## and ender on its args), read only from the running exchange: the newest done strike or chain-strike beat of his. {} when there is none.
static func beat_args(S: SimState, attacker: int) -> Dictionary:
	var ex = S.dirS.ex
	if ex == null or attacker < 0 or attacker >= S.fighters.size():
		return {}
	var role: String = "A" if S.fighters[attacker] == ex.A else "D"
	var best = null
	for b in ex.beats:
		if not b.done or b.args == null or (b.op != "strike" and b.op != "chainStrike"):
			continue
		if String(b.args.get("a", "A")) != role or not b.args.has("style"):
			continue
		if best == null or float(b.t) >= float(best.t):
			best = b
	return best.args if best != null else {}


## The look of a blow. The beat's own `style` when the director sends it; else the press log's read, read only (never DirAlchemy's resizing).
static func style_of(S: SimState, e, attacker: int) -> String:
	var kind: String = String(e.kind)
	var forced: String = String(VfxHub._g(e, "style", ""))
	if forced == "mash":
		forced = "speed"
	elif forced == "timed" or forced == "rhythm":
		forced = "tech"
	elif forced == "held" or forced == "hold":
		forced = "heavy"
	if kind == "guard":
		return "block"
	if kind != "light" and kind != "heavy":
		return ""
	if STYLES.has(forced) and forced != "block":
		return forced
	if kind == "heavy":
		return "heavy"
	# The director's own word on this blow (its strike beat's `style`).
	var bst: String = String(beat_args(S, attacker).get("style", ""))
	if STYLES.has(bst) and bst != "block":
		return bst
	# Animation's own read of the blow that is playing (picture and body agree).
	var af = anim_of(S, attacker)
	if af != null and not af.press.is_empty() and STYLES.has(String(af.press.get("style", ""))) and String(af.press.style) != "block":
		return String(af.press.style)
	if attacker >= 0 and attacker < S.fighters.size():
		var f = S.fighters[attacker]
		if f.act != null and f.act.dirI.size() >= DirAlchemy.SIZE:
			var rd: Dictionary = DirAlchemy.read(S, f)
			match String(rd.get("style", "none")):
				"rhythm":
					return "tech"
				"hold":
					return "heavy"
	return "speed"


## Animation's AnimFighter for a slot while its press styles are on (RenderAnim.press_styles), or null. Read only.
static func anim_of(S: SimState, slot: int):
	if anim_hook.is_valid():
		return anim_hook.call(S, slot)
	if not RenderAnim.press_styles or not RenderAnim.is_enabled() or slot < 0 or slot >= S.fighters.size():
		return null
	return RenderAnim.fighter(S, S.fighters[slot])


## The style a fighter's next blow would have, read the way style_of reads it (Animation's playing blow, else his press log, else speed): for a zip's cue.
static func read_style(S: SimState, slot: int) -> String:
	var af = anim_of(S, slot)
	if af != null and not af.press.is_empty() and STYLES.has(String(af.press.get("style", ""))) and String(af.press.style) != "block":
		return String(af.press.style)
	if slot >= 0 and slot < S.fighters.size():
		var f = S.fighters[slot]
		if f.act != null and f.act.dirI.size() >= DirAlchemy.SIZE:
			match String(DirAlchemy.read(S, f).get("style", "none")):
				"rhythm":
					return "tech"
				"hold":
					return "heavy"
	return "speed"


static func lane_of(S: SimState, slot: int) -> Color:
	return VfxBeamPlay.lane_of(S, slot)


## Where on a body (above the feet) a region is.
static func region_y(region: String) -> float:
	match region:
		"head":
			return HEAD_Y - 4.0
		"legs":
			return 24.0
	return 50.0


func step(S: SimState, frozen: bool) -> void:
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
	clock += 1
	for s in range(mini(2, S.fighters.size())):
		var h: Array = hist[s]
		h.append(Vector2(S.fighters[s].x, S.fighters[s].y))
		while h.size() > int(p("hist")):
			h.pop_front()
		var w: Wind = wind[s]
		var af = anim_of(S, s)
		if af != null and not af.press.is_empty() and String(af.press.get("style", "")) == "heavy" and String(af.press.get("phase", "")) == "load":
			# Animation's own wind-up: the ring is as far in as the blow is loaded (its ticks to contact).
			w.on = true
			w.t = clampf(24.0 - float(af.press.get("ticks_to_contact", 24)), 0.0, 24.0)
			w.ax = S.fighters[s].x
			w.ay = S.fighters[s].y
			w.dir = _dir_to(S, s)
			w.col = lane_of(S, s)
		elif w.on:
			w.t += 1.0
			if w.t > p("wind_life"):
				w.on = false
		if float(fly[s]) > 0.0:
			fly[s] = float(fly[s]) - 1.0


## The position of a slot `k` ticks ago (the old pose's stand-in), or the newest if the history is shorter.
func back(S: SimState, slot: int, k: int) -> Vector2:
	var h: Array = hist[slot]
	if h.is_empty():
		return Vector2(S.fighters[slot].x, S.fighters[slot].y)
	return h[maxi(h.size() - 1 - k, 0)]


func on_events(S: SimState, events: Array, reduced: bool) -> void:
	for e in events:
		match String(e.type):
			"cue":
				if String(e.kind) == "riposte":
					_riposte(S, e)
					continue
				if String(e.kind) == "tell_heavy":
					var slot: int = int(e.actor)
					if slot < 0 or slot > 1 or slot >= S.fighters.size():
						continue
					var f = S.fighters[slot]
					var w: Wind = wind[slot]
					w.on = true
					w.t = 0.0
					w.ax = f.x
					w.ay = f.y
					w.dir = _dir_to(S, slot)
					w.col = lane_of(S, slot)
			"damage":
				_blow(S, e, reduced)
			"knockback":
				var v: int = int(e.victim)
				var by: int = int(e.attacker)
				if v < 0 or v > 1 or by < 0 or by > 1 or v >= S.fighters.size():
					continue
				fly[v] = minf(float(e.dur) * 60.0, p("fly_max"))
				made["fly"] = int(made.get("fly", 0)) + 1


## The blocker's riposte (Encounter's B1c: cue `riposte`, actor the blocker, target the rival, text light or heavy, n the contact tick, absolute). Its beat is in the exchange from the press to the
## contact and may carry `sure` (it cannot be blocked or dodged) and `reversal` (it came out of a sidestep). A sure blow is marked by a thin committed line along the limb's path for the last 6
## ticks before the contact (and brackets on the target at the contact, in `_blow`); a reversal leaves one wire echo on the line of the sidestep. docs/vfx/riposte-plan.md.
func _riposte(S: SimState, e) -> void:
	var slot: int = int(e.actor)
	var vic: int = int(VfxHub._g(e, "target", 1 - slot))
	if slot < 0 or slot > 1 or slot >= S.fighters.size() or vic < 0 or vic >= S.fighters.size() or vic == slot:
		return
	var sure: bool = false
	var rev: bool = false
	var ex = S.dirS.ex
	if ex != null:
		for b in ex.beats:
			if b.args != null and bool(b.args.get("riposte", false)):
				sure = sure or bool(b.args.get("sure", false))
				rev = rev or bool(b.args.get("reversal", false))
	var fa = S.fighters[slot]
	var fv = S.fighters[vic]
	var dir: float = 1.0 if SimWrap.sdx(fa.x, fv.x) >= 0.0 else -1.0
	var reach: float = minf(absf(SimWrap.sdx(fa.x, fv.x)) - 10.0, 200.0)
	if sure:
		var x := Fx.new()
		x.style = "sureline"
		x.slot = slot
		x.vic = vic
		x.dir = dir
		x.ax = fa.x
		x.ay = fa.y
		x.cx = dir * maxf(reach, 14.0)
		x.cy = region_y("core") + (fv.y - fa.y)
		x.col = lane_of(S, slot)
		x.life = 6.0
		x.age = -maxf(float(VfxHub._g(e, "n", S.tick)) - float(S.tick) - 6.0, 0.0)
		fx.append(x)
		made["sureline"] = int(made.get("sureline", 0)) + 1
	if rev:
		var o: Vector2 = back(S, slot, 6)
		var r := Fx.new()
		r.style = "revecho"
		r.slot = slot
		r.vic = vic
		r.dir = dir
		r.ax = o.x
		r.ay = o.y
		r.col = lane_of(S, slot)
		r.life = 3.0
		fx.append(r)
		made["revecho"] = int(made.get("revecho", 0)) + 1


func _dir_to(S: SimState, slot: int) -> float:
	var o: int = 1 - slot
	return 1.0 if SimWrap.sdx(S.fighters[slot].x, S.fighters[o].x) >= 0.0 else -1.0


func _blow(S: SimState, e, reduced: bool) -> void:
	var att: int = int(e.attacker)
	var vic: int = int(e.victim)
	if att < 0 or att > 1 or vic < 0 or vic > 1 or att >= S.fighters.size() or vic >= S.fighters.size() or att == vic:
		return
	var style: String = style_of(S, e, att)
	if style == "":
		return
	var fa = S.fighters[att]
	var fv = S.fighters[vic]
	var x := Fx.new()
	x.style = style
	x.slot = att
	x.vic = vic
	x.dir = 1.0 if SimWrap.sdx(fa.x, fv.x) >= 0.0 else -1.0
	x.ax = fa.x
	x.ay = fa.y
	# The contact point: the victim's front, at the height of the region hit.
	var reach: float = minf(absf(SimWrap.sdx(fa.x, fv.x)) - 10.0, 200.0)
	x.cx = x.dir * maxf(reach, 14.0)
	x.cy = region_y(String(VfxHub._g(e, "region", "core"))) + (fv.y - fa.y)
	# The same everywhere: a tech or heavy blow's echoes sit a fixed distance behind him, from idle, in a brawl or at the end of a zip (Orb: tech is the same
	# three things everywhere). The body's recent travel never enters it.
	x.lunge = p("echo_back")
	var ba: Dictionary = beat_args(S, att)
	x.hand = (1 if String(ba.get("hand", "r")) == "l" else 0) if ba.has("hand") else (int(made.get("speed", 0)) % 2 if style == "speed" else 0)
	x.ghosts = 3 if String(ba.get("grade", "")) == "perfect" else (2 if ba.has("grade") else 0)
	made["beat"] = int(made.get("beat", 0)) + (1 if ba.has("style") else 0)
	x.col = lane_of(S, att)
	x.col2 = lane_of(S, vic) if style == "block" else x.col.lightened(0.25)
	x.small = reduced
	match style:
		"speed":
			x.life = p("speed_life") * (0.5 if reduced else 1.0)
		"tech":
			x.life = p("tech_life") * (0.6 if reduced else 1.0)
		"heavy":
			x.life = p("heavy_life") * (0.6 if reduced else 1.0)
			wind[att].on = false
		"block":
			x.slot = vic              # the defender's shield
			x.vic = att
			x.dir = -x.dir            # his shield faces the attacker
			x.ax = fv.x
			x.ay = fv.y
			x.cx = x.dir * 26.0
			x.cy = region_y("core")
			x.col = lane_of(S, vic)
			x.life = p("block_life")
	_take_real(S, x, att, style)
	if bool(ba.get("sure", false)) and style != "block":
		var br := Fx.new()
		br.style = "brackets"
		br.slot = att
		br.vic = vic
		br.dir = x.dir
		br.ax = x.ax
		br.ay = x.ay
		br.cx = x.cx
		br.cy = x.cy
		br.col = x.col
		br.life = 6.0
		fx.append(br)
		made["brackets"] = int(made.get("brackets", 0)) + 1
	if bool(ba.get("ender", false)) and style == "heavy":
		fly[vic] = maxf(float(fly[vic]), p("fly_max"))
	fx.append(x)
	if beat_glint:
		var gl := Fx.new()
		gl.style = "glint"
		gl.slot = att
		gl.vic = vic
		gl.dir = x.dir
		gl.ax = x.ax
		gl.ay = x.ay
		gl.cx = x.cx
		gl.cy = x.cy
		gl.col = x.col
		gl.col2 = x.col.lightened(0.2)
		gl.life = p("glint_life")
		gl.path = x.path
		fx.append(gl)
		made["glint"] = int(made.get("glint", 0)) + 1
	while fx.size() > 24:
		fx.pop_front()
	made[style] = int(made.get(style, 0)) + 1


## Animation's hand-off for a blow: the old pose and the strike pose as joints (the rig's forward kinematics over press_pose), the fist's real path, and
## the ghosts it asks for. Nothing is kept by reference: the AnimFighter's ring moves on.
func _take_real(S: SimState, x: Fx, att: int, style: String) -> void:
	var af = anim_of(S, att)
	if af == null:
		return
	x.ghosts = int(af.press.get("ghosts", 0)) if not af.press.is_empty() else 0
	var sx: float = 1.0 if float(af.vface) >= 0.0 else -1.0
	var nr: int = af.press_ring.size()
	var fa = S.fighters[att]
	if nr >= 2 and (style == "tech" or style == "heavy"):
		var pn: Dictionary = af.press_pose(0)
		var span: float = 0.1 if style == "tech" else 0.4
		var po: Dictionary = pn
		for k in range(1, nr):
			var c: Dictionary = af.press_pose(k)
			if float(pn.T) - float(c.T) <= span + 0.001:
				po = c
		if po != pn:
			x.ja = joints_of(po, sx)
			x.jb = joints_of(pn, sx)
			var ago: int = clampi(roundi((float(pn.T) - float(po.T)) * 60.0), 1, maxi(hist[att].size() - 1, 1))
			x.old_dx = -x.dir * p("echo_back") * 0.75
			x.real = x.ja.size() >= 16 and x.jb.size() >= 16
	var np: int = af.press_path.size()
	if np >= 2:
		var pnew: float = float(af.press_path[np - 1].T)
		for k in range(np):
			var ent: Dictionary = af.press_path[k]
			var tip: Vector3 = ent.tip
			var ag: int = clampi(roundi((pnew - float(ent.T)) * 60.0), 0, maxi(hist[att].size() - 1, 0))
			var hp: Vector2 = back(S, att, ag)
			x.path.append(Vector2(SimWrap.sdx(fa.x, hp.x) + sx * tip.x, (hp.y - fa.y) + tip.y))
		# The fist ends where the real tip ends.
		if style != "block":
			var last: Vector2 = x.path[x.path.size() - 1]
			x.cx = last.x
			x.cy = last.y


## A pose's joints (JOINTS order) as offsets from the body's anchor, x turned by the facing sign (Animation: flip x by vface for the world).
static func joints_of(pose: Dictionary, sx: float) -> PackedVector2Array:
	AnimRig.setup()
	var gq: Array[Quaternion] = []
	gq.resize(AnimRig.N)
	var gp := PackedVector3Array()
	gp.resize(AnimRig.N)
	AnimPose.fk(pose.q, pose.hips, gq, gp)
	var ro: Vector3 = pose.root_off
	var out := PackedVector2Array()
	for nm in JOINTS:
		var v: Vector3 = gp[AnimRig.index[nm]] + ro
		out.append(Vector2(sx * v.x, v.y))
	return out
