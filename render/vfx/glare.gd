class_name VfxGlare
extends RefCounted
## The rival's glasses glare (Orb's pick, 2026-10-04: frame C, the bare wedge lens; the glare hides his eyes completely). Rules: docs/legal/glasses-rules.md
## (RL-066): one hard-edged pale-violet wedge, in his own violet (never pure white, gold, orange or red), short (an attack of a few ticks and a hold of
## 0.4 s at most), at key moments only, never at a transformation break, and not beside a crouch-and-scream charge or a rubble ring (it may sit beside one
## other mark, never two). Face-local and brief, so in this tint it counts as no mark.
##
## This is the state and the envelope; shots_view.gd draws it at the head. Triggers, today (all are events that exist; no beat is added for it):
##   cue taunt_start      (the taunter)  a full glare: the lens goes opaque
##   attack kind sig      (the attacker) a glint at the start of a signature's wind-up only: a slash across the lens, the lens half-opaque
## and by cue when the director sends them (accepted now, nothing sends them yet; listed in docs/vfx/glare.md):
##   cue chin_plant       On the Chin's plant: a full glare
##   cue pride_threshold  a Pride threshold: a full glare
##   cue seal_break       the seal breaks: a full glare with a crack across the lens (it ignores the cooldown)
##   cue glare            a full glare, for any other key moment Game Design names
## It runs only for a wearer (data/vfx/glare.json `wearers`: fighter names), only while he is not in a transformation or a charge or inside a rubble ring,
## and a wearer's own glares are at least `cooldown` ticks apart. Presentation only: it reads cues and fighters, and draws no random number.

const DEFAULTS: Dictionary = {
	"glare": {"attack": 3.0, "hold": 16.0, "hold_glint": 8.0, "release": 6.0, "cooldown": 200.0, "hold_max": 24.0, "rocks_max": 0.25,
		"w": 26.0, "h": 15.0, "up": 2.0, "fwd": 6.0, "alpha": 0.96, "glint_fill": 0.45},
}
const WEARERS: Array = ["VORR", "antihero", "rival"]   # roster ids and names: the Anti-hero replaces VORR, and the roster may rename him
const CUES_FULL: Array = ["taunt_start", "chin_plant", "pride_threshold", "seal_break", "glare"]

class State:
	var t: float = -1.0           # ticks since it started (-1: none)
	var kind: String = ""         # full or glint
	var why: String = ""          # the cue that asked for it
	var hold: float = 16.0
	var cool: float = 0.0         # ticks until the next may start
	var crack: bool = false       # a seal break: a crack across the lens

var st: Array = [State.new(), State.new()]
var made: Dictionary = {}         # counters by reason, for the tests
var shown: int = 0                # glares drawn (the tests)
var blocked: Dictionary = {}      # counters by what blocked it (transform, charge, rocks, cooldown)

static var _data: Dictionary = {}
static var _loaded: bool = false


static func warm() -> void:
	if _loaded:
		return
	_loaded = true
	var path := "res://data/vfx/glare.json"
	if FileAccess.file_exists(path):
		var v = JSON.parse_string(FileAccess.get_file_as_string(path))
		if v is Dictionary:
			_data = v


static func p(key: String) -> float:
	warm()
	var g = _data.get("glare")
	if g is Dictionary and g.has(key):
		return float(g[key])
	return float(DEFAULTS["glare"][key])


static func wearers() -> Array:
	warm()
	var w = _data.get("wearers")
	return w if w is Array else WEARERS


## The colours are Art's (art/concepts/refine/glasses.mjs): a pale violet lens, a lighter violet wedge, a deeper violet halo. None is white.
static func col(key: String) -> Color:
	warm()
	var c = _data.get("colours")
	var defaults: Dictionary = {"lens": "#c0a0ee", "wedge": "#d8c2f8", "halo": "#a47ee8", "crack": "#4a3a86"}
	return Color(String(c.get(key, defaults[key])) if c is Dictionary else String(defaults[key]))


func reset() -> void:
	st = [State.new(), State.new()]
	made = {}
	blocked = {}
	warm()


static func is_wearer(S: SimState, slot: int) -> bool:
	return slot >= 0 and slot < S.fighters.size() and (wearers().has(String(S.fighters[slot].name)) or wearers().has(String(S.fighters[slot].id)))


## One unfrozen tick (hit-stop and pause hold it, like the rest of the effects clock).
func step(S: SimState, frozen: bool) -> void:
	if frozen:
		return
	for s in st:
		if s.cool > 0.0:
			s.cool -= 1.0
		if s.t >= 0.0:
			s.t += 1.0
			if s.t >= total(s):
				s.t = -1.0


func total(s: State) -> float:
	return p("attack") + minf(s.hold, p("hold_max")) + p("release")


## Cues and attacks that ask for a glare. `forms` is the transformation's per-slot Form list and `rocks_level` the rubble rings' level per slot.
func on_events(S: SimState, events: Array, forms: Array, rocks_level) -> void:
	for e in events:
		var kind: String = ""
		var why: String = ""
		var slot: int = -1
		if e.type == "cue" and CUES_FULL.has(String(e.kind)):
			kind = "full"
			why = String(e.kind)
			slot = int(e.actor)
		elif e.type == "attack" and String(e.kind) == "sig":
			kind = "glint"
			why = "sig"
			slot = int(e.actor)
		if kind == "" or not is_wearer(S, slot) or slot > 1:
			continue
		var s: State = st[slot]
		var f = S.fighters[slot]
		if forms.size() > 0 and _has_form(forms, slot):
			blocked["transform"] = int(blocked.get("transform", 0)) + 1
			continue
		if String(f.state) == "charging":
			blocked["charge"] = int(blocked.get("charge", 0)) + 1
			continue
		if rocks_level != null and slot < rocks_level.size() and float(rocks_level[slot]) > p("rocks_max"):
			blocked["rocks"] = int(blocked.get("rocks", 0)) + 1
			continue
		if s.cool > 0.0 and why != "seal_break":
			blocked["cooldown"] = int(blocked.get("cooldown", 0)) + 1
			continue
		s.t = 0.0
		s.kind = kind
		s.why = why
		s.hold = p("hold") if kind == "full" else p("hold_glint")
		s.crack = why == "seal_break"
		s.cool = p("cooldown")
		made[why] = int(made.get(why, 0)) + 1


static func _has_form(forms: Array, slot: int) -> bool:
	for f in forms:
		if f != null and int(f.slot) == slot:
			return true
	return false


## The glare's level, 0 to 1, at a frame (a is the share of the tick that has passed): a quick attack, the hold, a short release. Reduced motion has
## no ramp: it is on for the hold and off.
func level(slot: int, a: float, reduced: bool) -> float:
	var s: State = st[slot]
	if s.t < 0.0:
		return 0.0
	var t: float = s.t + a - 1.0
	t = maxf(t, 0.0)
	var att: float = p("attack")
	var hold: float = minf(s.hold, p("hold_max"))
	var rel: float = p("release")
	if reduced:
		return 1.0 if t < att + hold else 0.0
	if t < att:
		return t / maxf(att, 1.0)
	if t < att + hold:
		return 1.0
	return clampf(1.0 - (t - att - hold) / maxf(rel, 1.0), 0.0, 1.0)


## How far through its hold the glint's slash has swept, 0 to 1 (the sweeping glint crosses the lens once).
func sweep(slot: int, a: float) -> float:
	var s: State = st[slot]
	if s.t < 0.0:
		return 0.0
	var t: float = maxf(s.t + a - 1.0, 0.0)
	return clampf((t - p("attack") * 0.5) / maxf(minf(s.hold, p("hold_max")) + p("attack"), 1.0), 0.0, 1.0)
