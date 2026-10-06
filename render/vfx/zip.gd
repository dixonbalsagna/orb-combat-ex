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
	"zip": {"ghosts": 2.0, "echoes": 3.0, "echo_pop": 2.5, "hold": 14.0, "hold_max": 60.0, "tell_alpha": 0.8, "band_w": 16.0, "band_w2": 10.0, "wide_w": 24.0,
		"counter_life": 12.0, "caught_life": 22.0, "gbreak_life": 14.0, "alpha": 0.9, "ground_line_w": 2.2, "min_gap": 6.0,
		"ghost_gap": 16.0, "ghost_alpha": 0.35, "ring_ticks": 10.0, "mark_h": 54.0, "mark_r": 26.0, "min_travel": 4.0, "bh_per_tick": 3.0},
}

class Zip:
	var slot: int = 0
	var target: int = 1
	var style: String = "speed"     # speed, tech or heavy
	var heavy_kind: bool = false    # the cue was lunge_heavy or charge_heavy
	var one_way: bool = false       # a charge: a one-way flight, there is no strike hold and no way out
	var real: bool = false          # the director's own zip (zip_light, zip_heavy): its phases come from DirZip.read, the truth, each tick
	var zip_heavy: bool = false     # the zip heavy (LT and Y), not the zip strike (LT and X)
	var phase: String = ""         # a real zip's phase now: tell, in, reach, out
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
	var noflash: bool = false       # the flash register refused a guard break's flash ring
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
var flashes = null                  # the screen's flash register (set by the hub): a guard break's flash ring asks it
var violations: Dictionary = {}     # cues that break Legal's travel minimum (m02), by kind, for QA and the tests: the sim sets the ticks, so this only counts

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
	violations = {}
	warm()


## Legal's minimum for a zip's way in and its way out (m02): at least 4 ticks, and never more than 3 body heights between consecutive drawn positions.
static func min_ticks(distance_bh: float) -> int:
	return maxi(int(p("min_travel")), int(ceil(distance_bh / p("bh_per_tick"))))


## An echo's window on a zip's leg, in ticks since the leg began (the press's rule, VfxPress.echo_window: the back echoes pop one at a time, each living `echo_pop` ticks longer than the one
## behind it, and the third comes as the first pops), so never more than two are alive at any instant (Legal's f01 counts tech echoes too).
static func echo_window(g: int) -> Vector2:
	var pop: float = p("echo_pop")
	return Vector2(maxf(float(g - 1), 0.0) * pop, 2.0 + float(g) * pop)


## How many of a leg's `ne` echoes are alive `tt` ticks after it began.
static func echoes_alive(tt: float, ne: int) -> int:
	var k: int = 0
	for g in range(ne):
		var w: Vector2 = echo_window(g)
		if tt >= w.x and tt < w.y:
			k += 1
	return k


## Where the wire echoes stand on a leg from p0 to the body p1: evenly spaced and always short of the body (never ahead of it, never at the arrival point before he gets there).
static func echo_points(p0: Vector2, p1: Vector2, count: int) -> Array:
	var out: Array = []
	for g in range(count):
		out.append(p0.lerp(p1, float(g + 1) / float(count + 1)))
	return out


## The ghosts' places: up to `count` points on the body's real recent path (the position history, oldest first), each `spacing` along it from the newest,
## so with a spacing of two thirds of the body's width each overlaps the next by about a third. A stationary body has none.
static func trail_points(hist: Array, spacing: float, count: int) -> Array:
	var out: Array = []
	if hist.size() < 2 or count <= 0:
		return out
	var need: float = spacing
	var acc: float = 0.0
	var i: int = hist.size() - 1
	while i > 0 and out.size() < count:
		var a: Vector2 = hist[i]
		var b: Vector2 = hist[i - 1]
		var seg := Vector2(SimWrap.sdx(a.x, b.x), b.y - a.y)
		var l: float = seg.length()
		while l > 0.0001 and acc + l >= need and out.size() < count:
			var t: float = (need - acc) / l
			out.append(Vector2(SimWrap.wrap(a.x + seg.x * t), a.y + seg.y * t))
			need += spacing
		acc += l
		i -= 1
	return out


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
		if z.real:
			if not _read_into(S, z):
				zips.remove_at(i)
				continue
		else:
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
			"lunge_light", "lunge_heavy", "charge_light", "charge_heavy":
				_start(S, e, kind)
			"lunge_counter", "lunge_caught", "lunge_guard_broken":
				_outcome(S, e, kind)
			"zip_light", "zip_heavy":
				_start_real(S, e, kind)
			"zip_out":
				_zip_blow(S, e)
			"zip_end":
				_zip_end(S, e)


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
	z.heavy_kind = kind.ends_with("_heavy")
	z.one_way = kind.begins_with("charge")
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
	if z.one_way:
		z.hold = 1.0
		z.out = 1.0
	# Legal m02: the way in and the way out last at least max(4, ceil(distance in body heights / 3)) ticks. The sim sets them; count the cues that do not.
	var dist_bh: float = Vector2(SimWrap.sdx(f.x, ft.x), ft.y - f.y).length() / VfxLook.BH
	if z.mv < float(min_ticks(dist_bh)):
		violations["short_in"] = int(violations.get("short_in", 0)) + 1
	if z.out < float(min_ticks(dist_bh)) and not z.one_way:
		violations["short_out"] = int(violations.get("short_out", 0)) + 1
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


## A zip of the director's own (Encounter's Z1, docs/director/zip-z1.md): zip_light or zip_heavy as the tell starts, with `target`, `amount` the tell's ticks and `n` the way in. From here its
## phases are read, not counted: DirZip.read(S, f) (read only) says the phase (tell, in, reach, out), the ticks into it, the reading and the planned ticks; it is empty when the zip is over.
func _start_real(S: SimState, e, kind: String) -> void:
	var slot: int = int(e.actor)
	var tgt: int = int(VfxHub._g(e, "target", 1 - slot))
	if slot < 0 or slot > 1 or slot >= S.fighters.size() or tgt < 0 or tgt >= S.fighters.size() or tgt == slot:
		return
	var f = S.fighters[slot]
	var ft = S.fighters[tgt]
	var z := Zip.new()
	z.real = true
	z.slot = slot
	z.target = tgt
	z.zip_heavy = kind == "zip_heavy"
	z.heavy_kind = z.zip_heavy
	z.style = "heavy" if z.zip_heavy else "speed"
	z.wind = maxf(float(VfxHub._g(e, "amount", 6.0)), 1.0)
	z.mv = maxf(float(VfxHub._g(e, "n", 6.0)), 1.0)
	z.hold = maxf(float(VfxHub._g(e, "x", 4.0)) + float(VfxHub._g(e, "y", 6.0)), 1.0)
	z.out = maxf(z.mv, 1.0)
	z.ox = f.x
	z.oy = f.y
	var side: float = 1.0 if SimWrap.sdx(f.x, ft.x) >= 0.0 else -1.0
	var ct: Dictionary = DirData.contact()
	z.px = SimWrap.wrap(ft.x - side * maxf(float(ct.get("offset", 45.0)), float(ct.get("minSeparation", 45.0))))   # where the rush ends (DirZip._arrive's offset)
	z.py = ft.y
	z.ex = f.x
	z.ey = f.y
	z.col = VfxPress.lane_of(S, slot)
	for k in range(zips.size() - 1, -1, -1):
		if zips[k].slot == slot:
			zips.remove_at(k)
	zips.append(z)
	_read_into(S, z)
	made["zip"] = int(made.get("zip", 0)) + 1
	made[kind] = int(made.get(kind, 0)) + 1


## Takes the real zip's state from the director's read: false when the zip is over (nothing to draw). The age is the tick count along tell, way in, reach and way out, so the
## drawing treats it like any other zip.
func _read_into(S: SimState, z: Zip) -> bool:
	var r: Dictionary = DirZip.read(S, S.fighters[z.slot])
	if r.is_empty():
		return false
	z.wind = maxf(float(r["tell"]), 1.0)
	z.mv = maxf(float(r["in"]), 1.0)
	z.hold = maxf(float(r["hd"]), 1.0)
	z.out = maxf(float(r["out"]), 1.0)
	z.style = String(r["reading"])
	z.phase = String(r["phase"])
	var n: float = float(r["n"])
	match z.phase:
		"tell":
			z.age = n
		"in":
			z.age = z.wind + n
		"reach":
			z.age = z.wind + z.mv + n
			if not z.have_a:
				z.have_a = true
				z.ax = S.fighters[z.slot].x
				z.ay = S.fighters[z.slot].y
		_:
			z.age = z.wind + z.mv + z.hold + n
			if not z.have_a:
				z.have_a = true
	return true


## His blow lands (zip_out: text the exit kind, k the reading): a mark at the contact that is a strike's or a heavy's own. The press styles draw the blow's look from its damage event;
## this one is the zip's: a hard bar across the line of his approach for the zip strike, two bars for the zip heavy.
func _zip_blow(S: SimState, e) -> void:
	var slot: int = int(e.actor)
	var tgt: int = int(VfxHub._g(e, "target", 1 - slot))
	if slot < 0 or slot > 1 or slot >= S.fighters.size() or tgt < 0 or tgt >= S.fighters.size() or tgt == slot:
		return
	var z: Zip = of(slot)
	var f = S.fighters[slot]
	var ft = S.fighters[tgt]
	var m := Mark.new()
	m.kind = "zipblow"
	m.slot = slot
	var rd: Dictionary = DirZip.read(S, f)
	m.style = "heavy" if (String(rd.get("btn", "")) == "y" or (rd.is_empty() and z != null and z.zip_heavy)) else "strike"
	var side: float = 1.0 if SimWrap.sdx(f.x, ft.x) >= 0.0 else -1.0
	m.x = SimWrap.wrap(ft.x - side * 14.0)
	m.y = ft.y + 32.0
	m.dx = side
	m.dy = 0.0
	m.life = 8.0
	m.col = VfxPress.lane_of(S, slot)
	m.col2 = m.col.lightened(0.2)
	marks.append(m)
	made["zipblow"] = int(made.get("zipblow", 0)) + 1


## The zip is over (zip_end, `text` why, `actor` the zipper, `target` the rival): countered, caught, shot (stopped on the way in), down (dropped on the way out) get their mark where the zipper
## is; done, outrun and stopped by the rules need none.
func _zip_end(S: SimState, e) -> void:
	var slot: int = int(e.actor)
	if slot < 0 or slot > 1 or slot >= S.fighters.size():
		return
	var why: String = String(e.text)
	var tgt: int = int(VfxHub._g(e, "target", 1 - slot))
	if tgt < 0 or tgt >= S.fighters.size() or tgt == slot:
		tgt = 1 - slot
	var z: Zip = of(slot)
	var style: String = "heavy" if (z != null and z.style == "heavy") else "tech"
	match why:
		"countered":
			_mark(S, tgt, slot, "lunge_counter", style)
		"caught":
			_mark(S, tgt, slot, "lunge_caught", style)
		"shot", "stopped":
			_mark(S, tgt, slot, "zip_shot", style)
		"down":
			_mark(S, tgt, slot, "zip_down", style)
	made["end_" + why] = int(made.get("end_" + why, 0)) + 1
	if z != null:
		zips.erase(z)


## The outcomes. lunge_counter: actor = the fighter who countered, target = the zipper (he is stopped where he is); lunge_caught: actor = the fighter who caught him,
## target = the zipper; lunge_guard_broken: actor = the fighter whose guard broke, target = the zipper. An optional `style` (tech or heavy) names the counter's look.
func _outcome(S: SimState, e, kind: String) -> void:
	_mark(S, int(e.actor), int(VfxHub._g(e, "target", 1 - int(e.actor))), kind, String(VfxHub._g(e, "style", "tech")))


## One outcome mark: who (the fighter who countered, caught, shot or broke the guard) and zs (the zipper), the kind of cue, and the counter's look.
func _mark(S: SimState, who: int, zs: int, kind: String, style: String) -> void:
	if who < 0 or who > 1 or zs < 0 or zs > 1 or who >= S.fighters.size() or zs >= S.fighters.size():
		return
	var zf = S.fighters[zs]
	var wf = S.fighters[who]
	var m := Mark.new()
	m.slot = who
	m.style = style
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
			m.y = zf.y + 34.0
			m.life = p("counter_life")
			m.col = VfxPress.lane_of(S, who)
			if z != null:
				z.stopped = true
		"lunge_caught":
			m.kind = "caught"
			m.slot = zs
			m.x = zf.x
			m.y = zf.y + 30.0
			m.life = p("caught_life")
			m.col = VfxPress.lane_of(S, who)
			if z != null:
				z.stopped = true
		"zip_shot":
			m.kind = "shot"
			m.x = zf.x
			m.y = zf.y + 30.0
			m.life = 10.0
			m.col = VfxPress.lane_of(S, who)
			if z != null:
				z.stopped = true
		"zip_down":
			m.kind = "down"
			m.slot = zs
			m.x = zf.x
			m.y = zf.y + 4.0
			m.life = 14.0
			m.col = VfxPress.lane_of(S, who)
		_:
			m.kind = "gbreak"
			m.noflash = flashes != null and not flashes.ask("zip_break", VfxPress.lane_of(S, who), S.tick, VfxFlashRegistry.ring_px(22.0, 4.0, flashes.ppu), 0.15)
			m.x = wf.x
			m.y = wf.y + 34.0
			m.life = p("gbreak_life")
			m.col = VfxPress.lane_of(S, who)
			m.dx = -signf(SimWrap.sdx(wf.x, zf.x)) if absf(SimWrap.sdx(wf.x, zf.x)) > 0.5 else 1.0
			m.dy = 0.0
	m.col2 = m.col.lightened(0.2)
	marks.append(m)
	made[m.kind] = int(made.get(m.kind, 0)) + 1
	while marks.size() > 12:
		marks.pop_front()
