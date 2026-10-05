class_name VfxZip
extends RefCounted
## The LT zip on screen (Orb's approved reference docs/ep/prototypes/lt-zip-v4.html, 2026-10-05; docs/design/melee-press-feel.md section 2c): a fighter zips to the rival,
## strikes and zips out again, to any spot on a circle around him. "The character should zip back and forth in a stylistic blur, matching our visual cues we established
## for speed, tech and heavy." Behind the same flag as the press styles (hub.press_enabled); the strike's own marks are the press styles' (a `damage` event per blow).
##
##   the tell      a thin line along the ground toward the arrival point (the heavy also gets its charge ring, shrinking on the fighter)
##   speed         the travel: stacked soft filled ghosts along the path he really took and two streak bands (head and hip height)
##   tech          no travel: wire echoes along the straight path, popping off one at a time from the back to the front, and a thin line
##   heavy         the travel: stretched stacked ghosts and one wide band
##   the way out   the same, on the path out (a heavy goes out as a speed zip, as the prototype does)
##   counter       he is stopped on arrival: a hard bar across the path at the stop and the countering fighter's mark (a diamond for tech, a double ring for heavy)
##   caught        a late counter only catches him in reach: a squeezing ring and two brackets round him
##   guard broken  a heavy zip through a block: the shield line breaks into fragments and a flash ring
##
## Every travel effect is drawn between points, so it works in any direction (the exit can be above, below, behind or in front). The ghosts follow his real recorded
## positions (the last 24 ticks), so a curved path is a curved trail; the tech echoes lie on the straight line between his start and his arrival.
## Driven by cues (docs/vfx/zip.md has the shape): `lunge_light` or `lunge_heavy` (actor = the zipper, target, amount = wind-up ticks, n = move ticks: Encounter's B0 cue),
## with optional `style`, `hold` (ticks of striking), `out` (ticks to leave), `ex` and `ey` (the exit point), and the outcomes `lunge_counter`, `lunge_caught` and
## `lunge_guard_broken`. Presentation only: it reads cues and fighters, draws no random number.

const DEFAULTS: Dictionary = {
	"zip": {"ghosts": 5.0, "echoes": 4.0, "echo_pop": 2.0, "hold": 14.0, "hold_max": 60.0, "tell_alpha": 0.55, "band_w": 16.0, "band_w2": 10.0, "wide_w": 24.0,
		"counter_life": 12.0, "caught_life": 22.0, "gbreak_life": 14.0, "alpha": 0.9, "ground_line_w": 1.6, "min_gap": 6.0},
}

class Zip:
	var slot: int = 0
	var target: int = 1
	var style: String = "speed"     # speed, tech or heavy
	var heavy_kind: bool = false    # the cue was lunge_heavy
	var age: float = 0.0
	var wind: float = 6.0
	var mv: float = 6.0
	var hold: float = 14.0
	var out: float = 6.0
	var ox: float = 0.0             # where he started
	var oy: float = 0.0
	var px: float = 0.0             # where the tell says he will arrive (an estimate: the rival's place, short of him)
	var py: float = 0.0
	var ax: float = 0.0             # where he arrived (recorded when it happens)
	var ay: float = 0.0
	var have_a: bool = false
	var ex: float = 0.0             # where he leaves to
	var ey: float = 0.0
	var has_exit: bool = false
	var stopped: bool = false       # countered on arrival: the strike and the exit do not happen
	var col: Color = Color.WHITE

	func t1() -> float:
		return wind

	func t2() -> float:
		return wind + mv

	func t3() -> float:
		return wind + mv + hold

	func t4() -> float:
		return wind + mv + hold + out

class Mark:
	var kind: String = ""           # counter, caught or gbreak
	var slot: int = 0               # whose it is (the zipper for caught; the one who countered or whose guard broke)
	var x: float = 0.0
	var y: float = 0.0
	var dx: float = 1.0             # the zip's direction at the mark
	var dy: float = 0.0
	var style: String = "tech"
	var age: float = 0.0
	var life: float = 12.0
	var col: Color = Color.WHITE
	var col2: Color = Color.WHITE

var zips: Array = []                # Zip, oldest first
var marks: Array = []               # Mark
var made: Dictionary = {}           # counters by kind, for the tests
var shown: int = 0                  # effects drawn last frame (the tests)

static var _data: Dictionary = {}
static var _loaded: bool = false


static func warm() -> void:
	if _loaded:
		return
	_loaded = true
	var path := "res://data/vfx/zip.json"
	if FileAccess.file_exists(path):
		var v = JSON.parse_string(FileAccess.get_file_as_string(path))
		if v is Dictionary:
			_data = v


static func p(key: String) -> float:
	warm()
	var g = _data.get("zip")
	if g is Dictionary and g.has(key):
		return float(g[key])
	return float(DEFAULTS["zip"][key])


func reset() -> void:
	zips.clear()
	marks.clear()
	made = {}
	warm()


## The zip of a slot that is playing, or null.
func of(slot: int) -> Zip:
	for z: Zip in zips:
		if z.slot == slot:
			return z
	return null


func step(S: SimState, frozen: bool) -> void:
	if frozen:
		return
	var i: int = 0
	while i < zips.size():
		var z: Zip = zips[i]
		z.age += 1.0
		if z.age >= z.t2() and not z.have_a and z.slot < S.fighters.size():
			z.have_a = true
			z.ax = S.fighters[z.slot].x
			z.ay = S.fighters[z.slot].y
		if z.age >= z.t4() + 12.0 or (z.stopped and z.age > z.t2() + 40.0):
			zips.remove_at(i)
		else:
			i += 1
	i = 0
	while i < marks.size():
		var m: Mark = marks[i]
		m.age += 1.0
		if m.age >= m.life:
			marks.remove_at(i)
		else:
			i += 1


func on_events(S: SimState, events: Array, _reduced: bool) -> void:
	for e in events:
		if String(e.type) != "cue":
			continue
		var kind: String = String(e.kind)
		match kind:
			"lunge_light", "lunge_heavy":
				_start(S, e, kind)
			"lunge_counter", "lunge_caught", "lunge_guard_broken":
				_outcome(S, e, kind)


func _start(S: SimState, e, kind: String) -> void:
	var slot: int = int(e.actor)
	var tgt: int = int(VfxHub._g(e, "target", 1 - slot))
	if slot < 0 or slot > 1 or slot >= S.fighters.size() or tgt < 0 or tgt >= S.fighters.size() or tgt == slot:
		return
	var f = S.fighters[slot]
	var ft = S.fighters[tgt]
	var z := Zip.new()
	z.slot = slot
	z.target = tgt
	z.heavy_kind = kind == "lunge_heavy"
	var st: String = String(VfxHub._g(e, "style", ""))
	if st == "mash":
		st = "speed"
	elif st == "timed" or st == "rhythm":
		st = "tech"
	elif st == "held" or st == "hold":
		st = "heavy"
	if not ["speed", "tech", "heavy"].has(st):
		st = "heavy" if z.heavy_kind else VfxPress.read_style(S, slot)
	z.style = st
	z.wind = maxf(float(VfxHub._g(e, "amount", 6.0)), 1.0)
	z.mv = maxf(float(VfxHub._g(e, "n", 6.0)), 1.0)
	z.hold = clampf(float(VfxHub._g(e, "hold", p("hold"))), 1.0, p("hold_max"))
	z.out = maxf(float(VfxHub._g(e, "out", z.mv)), 1.0)
	z.ox = f.x
	z.oy = f.y
	var side: float = 1.0 if SimWrap.sdx(f.x, ft.x) >= 0.0 else -1.0
	z.px = SimWrap.wrap(ft.x - side * 30.0)
	z.py = ft.y
	if e.get("tx") != null:
		z.px = float(e.get("tx"))
		z.py = float(VfxHub._g(e, "ty", ft.y))
	if e.get("ex") != null:
		z.has_exit = true
		z.ex = float(e.get("ex"))
		z.ey = float(VfxHub._g(e, "ey", f.y))
	else:
		z.ex = f.x
		z.ey = f.y
	z.col = VfxPress.lane_of(S, slot)
	for k in range(zips.size() - 1, -1, -1):
		if zips[k].slot == slot:
			zips.remove_at(k)
	zips.append(z)
	made[z.style] = int(made.get(z.style, 0)) + 1
	made["zip"] = int(made.get("zip", 0)) + 1


## The outcomes. lunge_counter: actor = the fighter who countered, target = the zipper (he is stopped where he is); lunge_caught: actor = the fighter who caught him,
## target = the zipper; lunge_guard_broken: actor = the fighter whose guard broke, target = the zipper. An optional `style` (tech or heavy) names the counter's look.
func _outcome(S: SimState, e, kind: String) -> void:
	var who: int = int(e.actor)
	var zs: int = int(VfxHub._g(e, "target", 1 - who))
	if who < 0 or who > 1 or zs < 0 or zs > 1 or who >= S.fighters.size() or zs >= S.fighters.size():
		return
	var zf = S.fighters[zs]
	var wf = S.fighters[who]
	var m := Mark.new()
	m.slot = who
	m.style = String(VfxHub._g(e, "style", "tech"))
	if not ["tech", "heavy"].has(m.style):
		m.style = "tech"
	var z: Zip = of(zs)
	var d := Vector2(SimWrap.sdx(wf.x, zf.x), zf.y - wf.y)
	if z != null:
		d = Vector2(SimWrap.sdx(z.ox, zf.x), zf.y - z.oy)
		if d.length() < 1.0:
			d = Vector2(SimWrap.sdx(wf.x, zf.x), 0.0)
	if d.length() < 0.01:
		d = Vector2(1.0, 0.0)
	d = d.normalized()
	m.dx = d.x
	m.dy = d.y
	match kind:
		"lunge_counter":
			m.kind = "counter"
			m.x = zf.x
			m.y = zf.y + 50.0
			m.life = p("counter_life")
			m.col = VfxPress.lane_of(S, who)
			if z != null:
				z.stopped = true
		"lunge_caught":
			m.kind = "caught"
			m.slot = zs
			m.x = zf.x
			m.y = zf.y + 40.0
			m.life = p("caught_life")
			m.col = VfxPress.lane_of(S, who)
			if z != null:
				z.stopped = true
		_:
			m.kind = "gbreak"
			m.x = wf.x
			m.y = wf.y + 50.0
			m.life = p("gbreak_life")
			m.col = VfxPress.lane_of(S, who)
			m.dx = -signf(SimWrap.sdx(wf.x, zf.x)) if absf(SimWrap.sdx(wf.x, zf.x)) > 0.5 else 1.0
			m.dy = 0.0
	m.col2 = m.col.lightened(0.2)
	marks.append(m)
	made[m.kind] = int(made.get(m.kind, 0)) + 1
	while marks.size() > 12:
		marks.pop_front()
