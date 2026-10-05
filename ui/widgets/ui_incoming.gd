class_name UiIncoming
## The incoming marker of the split screen (docs/ui/hud-spec.md section 34; Camera's data is `incoming` in the split record,
## docs/camera/split-screen.md section 21d). In a split each pane shows when the OTHER fighter is off that pane and coming at its fighter fast:
## where from, how far and when he arrives. One chip per pane, on the edge of the pane the attacker comes from, pointing along `screen_dir`:
##   - the arrival: a countdown in seconds from `eta` (one decimal under ten);
##   - the distance in fighter heights, as the ordinary pointer chip says it;
##   - AIMED (a sim rush is on at him: `eta` is exact) is a solid chip with a target ring round the arrow, the word RUSH and an exact number;
##     NOT AIMED (he is closing fast: `eta` is an estimate) is a dashed chip with open chevrons, the word CLOSING and a number with a "~".
##     Shape, line and word tell them apart, never colour. An aimed arrival under 0.6 s turns the chip solid light with dark words.
## It replaces the ordinary pointer chip for that pane while it shows (never two chips for one rival) and is drawn only while the panes are open:
## nothing in a single view. The record's `shown` is true while the attacker is ON the pane's screen (see the note in section 34): then
## the player sees him and there is no chip. The chip is not animated (the number is the movement), so reduced motion changes nothing about it.

const URGENT_ETA := 0.6          # seconds: an aimed rush this close to arriving is drawn with the inverted, solid look
const FULL := Vector2(212.0, 58.0)      # the chip's design size, px at scale 1
const COMPACT := Vector2(94.0, 46.0)    # the small-pane chip: the arrow and the countdown only


## The record's incoming read for this pane when a chip is wanted: active and the attacker not on the pane. {} otherwise.
static func data(sp: Dictionary, slot: int) -> Dictionary:
	var arr = sp.get("incoming")
	if not (arr is Array) or slot < 0 or slot >= (arr as Array).size():
		return {}
	var d = (arr as Array)[slot]
	if not (d is Dictionary):
		return {}
	if not bool(d.get("active", false)) or bool(d.get("shown", false)) or float(d.get("eta", -1.0)) < 0.0:
		return {}
	return d


static func size(s: float, compact: bool = false) -> Vector2:
	var base: Vector2 = COMPACT if compact else FULL
	return Vector2(maxf(base.x * s, base.x * 0.8), maxf(base.y * s, base.y * 0.8))


## The countdown as text: one decimal under ten seconds, whole seconds above; "~" in front when the arrival is an estimate.
static func eta_text(eta: float, aimed: bool) -> String:
	var t: String = ("%.1f" % snappedf(eta, 0.1)) if eta < 10.0 else str(int(round(eta)))
	return t if aimed else "~" + t


## Where the chip goes for this pane, or {}: the ray from the pane's own fighter along `screen_dir` to the edge of the pane's clear zone (the
## pane's half of the screen, inside the safe area and the divider's margin, between the plates and the strip), the chip's rectangle held inside
## it (and the layout's clear zone, so never over the columns) and a fighter height clear of the fighter. Tries the full chip, then the compact one; {} when neither has room (the ordinary pointer then
## stands in). The returned entry is a pointer chip of kind "incoming" for UiSplit.pointers.
static func entry(lay: UiLayout, sp: Dictionary, inc: Dictionary, anchor: Dictionary, slot: int, s: float, dist_text: String) -> Dictionary:
	if inc.has("dist_bh"):
		dist_text = UiSplit.dist_text(float(inc["dist_bh"]))   # the attacker's own distance, not the held one
	if anchor.is_empty() or not sp.has("c") or not sp.has("n"):
		return {}
	var zone: PackedVector2Array = lay.pane_zone(slot == 1, sp["c"], sp["n"])
	# The fighters' space only: not the columns of plates, cards and legend either side (the layout's clear zone).
	var cz: Rect2 = lay.clear_zone
	if cz.size.x <= 0.0 or cz.size.y <= 0.0:
		return {}   # a window too small to have fighters' space: no chip
	zone = UiIcons.clip_half_plane(zone, cz.position, Vector2(1.0, 0.0))
	zone = UiIcons.clip_half_plane(zone, cz.end, Vector2(-1.0, 0.0))
	zone = UiIcons.clip_half_plane(zone, cz.position, Vector2(0.0, 1.0))
	zone = UiIcons.clip_half_plane(zone, cz.end, Vector2(0.0, -1.0))
	if zone.size() < 3:
		return {}
	var side: float = 1.0 if int(inc.get("side", 1)) >= 0 else -1.0
	var dir: Vector2 = Vector2(side, 0.0)
	var sd = inc.get("screen_dir")
	if sd is Vector2 and (sd as Vector2).length() > 0.01:
		dir = (sd as Vector2).normalized()
	var p: Vector2 = anchor["pos"]
	var h: float = float(anchor.get("h", 0.0))
	var eta: float = float(inc.get("eta", 0.0))
	var aimed: bool = bool(inc.get("aimed", false))
	for compact in [false, true]:
		var sz: Vector2 = size(s, compact)
		var pos: Vector2 = _on_edge(zone, p, dir, sz, s)
		if pos.x < -1e8:
			continue
		pos = _clear_of(pos, dir, sz, p, h, zone)
		if pos.x < -1e8:
			continue
		return {"slot": slot, "kind": "incoming", "pos": pos, "dir": dir, "text": dist_text, "size": sz, "compact": compact, "aimed": aimed,
			"eta": eta, "eta_text": eta_text(eta, aimed), "urgent": aimed and eta < URGENT_ETA, "dist_bh": float(inc.get("dist_bh", 0.0))}
	return {}


## The chip's centre on the zone's edge along the ray from `p`, its rectangle inside the zone's bounds; off-screen sentinel if the zone is smaller than the chip.
static func _on_edge(zone: PackedVector2Array, p: Vector2, dir: Vector2, sz: Vector2, s: float) -> Vector2:
	var bb := Rect2(zone[0], Vector2.ZERO)
	var cen := Vector2.ZERO
	for q in zone:
		bb = bb.expand(q)
		cen += q
	cen /= float(zone.size())
	if bb.size.x < sz.x or bb.size.y < sz.y:
		return Vector2(-1e9, -1e9)
	var t_exit: float = 1e9
	for k in range(zone.size()):
		var a: Vector2 = zone[k]
		var b: Vector2 = zone[(k + 1) % zone.size()]
		var e: Vector2 = b - a
		if e.length() < 0.001:
			continue
		var nrm := Vector2(e.y, -e.x).normalized()
		if (cen - a).dot(nrm) > 0.0:
			nrm = -nrm   # outward
		var dn: float = dir.dot(nrm)
		if dn > 1e-6:
			t_exit = minf(t_exit, (a - p).dot(nrm) / dn)
	if t_exit >= 1e8:
		t_exit = 0.0
	var reach: float = absf(dir.x) * sz.x * 0.5 + absf(dir.y) * sz.y * 0.5
	var t: float = maxf(t_exit - reach - 2.0 * s, 0.0)
	var pos: Vector2 = p + dir * t
	pos.x = clampf(pos.x, bb.position.x + sz.x * 0.5, bb.end.x - sz.x * 0.5)
	pos.y = clampf(pos.y, bb.position.y + sz.y * 0.5, bb.end.y - sz.y * 0.5)
	return pos


## Keep the chip a fighter height from its own fighter: slide it along the edge (perpendicular to the ray) to the nearest clear spot inside the zone.
static func _clear_of(pos: Vector2, dir: Vector2, sz: Vector2, p: Vector2, h: float, zone: PackedVector2Array) -> Vector2:
	var bb := Rect2(zone[0], Vector2.ZERO)
	for q in zone:
		bb = bb.expand(q)
	var ok := func(c: Vector2) -> bool:
		var r := Rect2(c - sz * 0.5, sz)
		var d := Vector2(maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x), maxf(maxf(r.position.y - p.y, 0.0), p.y - r.end.y))
		return d.length() >= h
	if ok.call(pos):
		return pos
	var along := Vector2(-dir.y, dir.x)
	var step: float = maxf(sz.y * 0.25, 4.0)
	var k := 1
	while float(k) * step <= maxf(h * 2.5 + sz.y, sz.y * 2.0):
		for sgn in [1.0, -1.0]:
			var c: Vector2 = pos + along * (float(sgn) * float(k) * step)
			c.x = clampf(c.x, bb.position.x + sz.x * 0.5, bb.end.x - sz.x * 0.5)
			c.y = clampf(c.y, bb.position.y + sz.y * 0.5, bb.end.y - sz.y * 0.5)
			if ok.call(c):
				return c
		k += 1
	return Vector2(-1e9, -1e9)


## What the picture depends on (the chip is a node the HUD moves, so following the fighter costs no redraw): the arrow turns about 5 degrees,
## the countdown text, the distance, which kind it is, whether it is urgent and which size.
static func sig(ch: Dictionary) -> Array:
	var dir: Vector2 = ch["dir"]
	return [int(ch["slot"]), int(dir.x * 12.0), int(dir.y * 12.0), str(ch["eta_text"]), str(ch["text"]), bool(ch["aimed"]), bool(ch["urgent"]), bool(ch["compact"])]


## One chip, drawn in `ci` (a node of the chip's size).
static func draw(ci: Control, hub: UiEventHub, ch: Dictionary, s: float, o: Dictionary) -> void:
	var a: float = float(o.get("plate_alpha", 1.0))
	var sz: Vector2 = ci.size
	var aimed: bool = bool(ch["aimed"])
	var urgent: bool = bool(ch["urgent"])
	var compact: bool = bool(ch["compact"])
	var dir: Vector2 = ch["dir"]
	var ink := Color(UiLook.col(UiLook.INK), a)
	var dark := Color(UiLook.col(UiLook.INK_DARK), a)
	var fill: Color = Color(ink, 0.95 * a) if urgent else Color(UiLook.col(UiLook.SCRIM), (0.92 if aimed else 0.78) * a)
	var fg: Color = dark if urgent else ink
	var rad: float = sz.y * 0.28
	var r := Rect2(Vector2.ZERO, sz)
	UiText.no_outline = true
	if aimed:
		UiIcons.rrect(ci, r, rad, fill, ink, maxf(3.0, 3.0 * s))
	else:
		# Dashed: the estimate. A plain fill, then the edge in dashes along the straight sides.
		UiIcons.rrect(ci, r, rad, fill, Color(0, 0, 0, 0), 0.0)
		var w: float = maxf(2.0, 2.0 * s)
		var dl: float = maxf(7.0 * s, 5.0)
		var inset: float = w * 0.5
		UiIcons.dashed_line(ci, Vector2(rad, inset), Vector2(sz.x - rad, inset), dl, dl * 0.7, w, fg)
		UiIcons.dashed_line(ci, Vector2(rad, sz.y - inset), Vector2(sz.x - rad, sz.y - inset), dl, dl * 0.7, w, fg)
		UiIcons.dashed_line(ci, Vector2(inset, rad), Vector2(inset, sz.y - rad), dl * 0.7, dl * 0.7, w, fg)
		UiIcons.dashed_line(ci, Vector2(sz.x - inset, rad), Vector2(sz.x - inset, sz.y - rad), dl * 0.7, dl * 0.7, w, fg)
	# The arrow, in a square at the chip's left, along `dir`.
	var ic := Vector2(sz.y * 0.55, sz.y * 0.5)
	var ir: float = sz.y * 0.36
	var perp := Vector2(-dir.y, dir.x)
	var lw: float = maxf(2.0, ir * 0.22)
	if aimed:
		# A target ring round a solid arrow: it is aimed at you.
		ci.draw_arc(ic, ir, 0.0, TAU, 28, fg, lw, true)
		UiIcons.fill_poly(ci, PackedVector2Array([ic + dir * ir * 0.62, ic - dir * ir * 0.38 + perp * ir * 0.5, ic - dir * ir * 0.38 - perp * ir * 0.5]), fg)
	else:
		# Two open chevrons: he is closing.
		for k in range(2):
			var tip: Vector2 = ic + dir * ir * (0.55 - 0.7 * float(k))
			ci.draw_polyline(PackedVector2Array([tip - dir * ir * 0.5 + perp * ir * 0.6, tip, tip - dir * ir * 0.5 - perp * ir * 0.6]), fg, lw, true)
	# The countdown, with its unit; the word and the distance under it (the full chip only).
	var tx: float = sz.y * 1.05
	var fs1: int = UiText.px(30.0 if not compact else 25.0, s)
	var fs2: int = UiText.px(16.0, s)
	var eta_t: String = str(ch["eta_text"])
	var tw: float = UiText.width(eta_t, fs1)
	var y1: float = sz.y * (0.4 if not compact else 0.5)
	UiText.draw(ci, eta_t, Vector2(tx, y1 + float(fs1) * 0.35), fs1, fg, -1)
	UiText.draw(ci, "s", Vector2(tx + tw + 3.0 * s, y1 + float(fs1) * 0.35), fs2, Color(fg, 0.9), -1)
	if not compact:
		var word: String = UiData.t("prompt.inc_rush" if aimed else "prompt.inc_closing")
		var y2: float = sz.y * 0.8
		UiText.draw(ci, word, Vector2(tx, y2 + float(fs2) * 0.35), fs2, Color(fg, 0.95), -1)
		var ww: float = UiText.width(word, fs2)
		var dx: float = tx + ww + 8.0 * s
		var dist_t: String = str(ch["text"])
		UiText.draw(ci, dist_t, Vector2(dx, y2 + float(fs2) * 0.35), fs2, fg, -1)
		var hx: float = dx + UiText.width(dist_t, fs2) + 5.0 * s
		var hh: float = float(fs2) * 0.36
		ci.draw_multiline(PackedVector2Array([Vector2(hx, y2 - hh), Vector2(hx, y2 + hh), Vector2(hx - 2.5 * s, y2 - hh), Vector2(hx + 2.5 * s, y2 - hh), Vector2(hx - 2.5 * s, y2 + hh), Vector2(hx + 2.5 * s, y2 + hh)]), Color(fg, 0.8), 1.5)
	UiText.no_outline = false
