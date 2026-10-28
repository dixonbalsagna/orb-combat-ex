class_name UiMany
## The many-body markers (docs/camera/one-v-many.md section 9; docs/ui/hud-spec.md section 61). With more than two bodies in a fight (the Empress and her guards)
## the camera cannot keep every body in the frame; `SplitFrame.many_off` lists the ones it left out as [slot, side] (-1 left, +1 right, 0 above).
## UI draws one steady marker for each, at the edge of the fighters' space on that side: a hollow triangle pointing out, with the body's number (a guard is
## 1, 2, 3 ... : slot minus one) in his ring colour when the hub knows him and the plain ink when it does not. Hollow, so it cannot be mistaken for the
## rival's filled pointer. Up to four. Steady: a marker never blinks or pulses, and one that has gone stays for HOLD seconds so a body hovering at the
## frame's edge cannot make it flicker (no more than about two changes a second for a marker, and each is a small shape, never a block).
## On a phone in landscape and in portrait the marker is the compact one (the triangle and the number) and keeps clear of the touch buttons.
## Nothing here when the record has no `many_off` (Camera's many-body framing is off, or only two bodies).

const MAX_MARKS := 4
const HOLD := 0.5   # seconds a marker stays after the camera stops listing it


## The bodies the record says are off the frame: [{slot, side}], at most four, in slot order, de-duplicated. The two principals are never marked here (the ordinary pointer is theirs).
static func listed(sp: Dictionary) -> Array:
	var out: Array = []
	var arr = sp.get("many_off")
	if not (arr is Array):
		return out
	var seen := {}
	for e in (arr as Array):
		if not (e is Array) or (e as Array).size() < 2:
			continue
		var slot: int = int((e as Array)[0])
		var side: int = clampi(int((e as Array)[1]), -1, 1)
		if slot < 2 or seen.has(slot):
			continue
		seen[slot] = true
		out.append({"slot": slot, "side": side})
	out.sort_custom(func(a, b): return int(a["slot"]) < int(b["slot"]))
	return out.slice(0, MAX_MARKS)


## A marker's size: the small one on a phone (a short landscape screen or portrait), else the usual.
static func compact(lay: UiLayout) -> bool:
	return lay.portrait or lay.vp.y < 500.0


static func mark_size(lay: UiLayout) -> Vector2:
	var k: float = 0.82 if compact(lay) else 1.0
	return Vector2(maxf(46.0 * lay.s, 40.0), maxf(36.0 * lay.s, 32.0)) * k


## The markers to draw: [{slot, side, pos, size, dir, label}]. Left and right markers stack down the edge of the fighters' space from its middle, outward in turn
## (one above the middle, one below, ...); an above marker sits at the top of the space. Each is moved off the touch buttons (the layout's own rectangles) and off every other marker.
static func marks(lay: UiLayout, sp: Dictionary) -> Array:
	var out: Array = []
	var cz: Rect2 = lay.clear_zone
	if cz.size.x <= 0.0 or cz.size.y <= 0.0:
		return out   # no fighters' space on this screen
	if UiFast.on and listed(sp).is_empty():
		return out   # two bodies in the frame, the usual fight: nothing to place, and the touch buttons' boxes below are not worth building for it
	var sz: Vector2 = mark_size(lay)
	var gap: float = 6.0 * lay.s
	var boxes: Array = []
	for k in lay.touch_keys():
		if lay.touch_ctrl.has(k):
			boxes.append(UiTouchControls.rect_of(lay.touch_ctrl[k]).grow(2.0 * lay.s))
	var counts := {-1: 0, 0: 0, 1: 0}
	for e in listed(sp):
		var side: int = int(e["side"])
		var n: int = int(counts[side])
		counts[side] = n + 1
		var pos: Vector2
		var dir: Vector2
		if side == 0:
			# Above: along the top of the space, from the middle outward in turn.
			var off: float = (float((n + 1) / 2) * (sz.x + gap)) * (1.0 if n % 2 == 1 else -1.0)
			pos = Vector2(cz.get_center().x + off, cz.position.y + sz.y * 0.5 + gap)
			dir = Vector2(0.0, -1.0)
		else:
			var offy: float = (float((n + 1) / 2) * (sz.y + gap)) * (1.0 if n % 2 == 1 else -1.0)
			var ex: float = cz.end.x - sz.x * 0.5 - gap if side > 0 else cz.position.x + sz.x * 0.5 + gap
			pos = Vector2(ex, cz.get_center().y + offy)
			dir = Vector2(float(side), 0.0)
		pos = _free(pos, sz, cz, boxes, out, gap)
		if pos.x < -1e8:
			continue
		out.append({"slot": int(e["slot"]), "side": side, "pos": pos, "size": sz, "dir": dir, "label": str(int(e["slot"]) - 1)})
	return out


## `pos` if its rectangle is inside the space and clear of the touch buttons and the markers already placed; else the nearest place along the edge that is; else the off-screen sentinel.
static func _free(pos: Vector2, sz: Vector2, cz: Rect2, boxes: Array, placed: Array, gap: float) -> Vector2:
	var step: float = maxf(sz.y * 0.5, 8.0)
	var ok := func(c: Vector2) -> bool:
		var r := Rect2(c - sz * 0.5, sz)
		if not cz.grow(0.5).encloses(r):
			return false
		for b in boxes:
			if r.intersects(b):
				return false
		for m in placed:
			if r.grow(gap * 0.5).intersects(Rect2((m["pos"] as Vector2) - (m["size"] as Vector2) * 0.5, m["size"])):
				return false
		return true
	var c0 := Vector2(clampf(pos.x, cz.position.x + sz.x * 0.5, cz.end.x - sz.x * 0.5), clampf(pos.y, cz.position.y + sz.y * 0.5, cz.end.y - sz.y * 0.5))
	if ok.call(c0):
		return c0
	var along := Vector2(0.0, 1.0)
	var k := 1
	while float(k) * step <= maxf(cz.size.x, cz.size.y):
		for sgn in [1.0, -1.0]:
			for ax in [along, Vector2(1.0, 0.0)]:
				var c: Vector2 = c0 + (ax as Vector2) * (float(sgn) * float(k) * step)
				if ok.call(c):
					return c
		k += 1
	return Vector2(-1e9, -1e9)


## The markers with the vanished ones held: `keep` maps slot to {m, t}. Returns the markers to draw; `keep` is updated in place.
static func held(ms: Array, keep: Dictionary, now: float) -> Array:
	if UiFast.on and ms.is_empty() and keep.is_empty():
		return []
	var out: Array = []
	var now_slots := {}
	for m in ms:
		keep[int(m["slot"])] = {"m": m, "t": now}
		now_slots[int(m["slot"])] = true
		out.append(m)
	for k in keep.keys():
		if now_slots.has(k):
			continue
		if now - float((keep[k] as Dictionary)["t"]) < HOLD:
			out.append((keep[k] as Dictionary)["m"])
		else:
			keep.erase(k)
	out.sort_custom(func(a, b): return int(a["slot"]) < int(b["slot"]))
	return out.slice(0, MAX_MARKS)


## What the picture depends on: which bodies, on which side, and where (to a whole pixel), and each one's colour.
static func sig(ms: Array, hub: UiEventHub) -> Variant:
	if ms.is_empty():
		return null
	var out: Array = []
	for m in ms:
		var p: Vector2 = m["pos"]
		var mod: UiFighterModel = hub.model(int(m["slot"])) if hub != null else null
		out.append([int(m["slot"]), int(m["side"]), int(p.x), int(p.y), mod.aura.to_html(false) if mod != null else ""])
	return out


## The markers, drawn in a full-screen layer: a hollow triangle pointing out of the fighters' space, the number inside it.
static func draw(ci: CanvasItem, hub: UiEventHub, ms: Array, s: float, o: Dictionary) -> void:
	var a: float = float(o.get("plate_alpha", 1.0))
	var ink := Color(UiLook.col(UiLook.INK), 0.95 * a)
	UiText.no_outline = true
	for m in ms:
		var c: Vector2 = m["pos"]
		var sz: Vector2 = m["size"]
		var d: Vector2 = m["dir"]
		var perp := Vector2(-d.y, d.x)
		var mod: UiFighterModel = hub.model(int(m["slot"])) if hub != null else null
		var col: Color = Color(mod.aura, a) if mod != null else ink
		UiIcons.rrect(ci, Rect2(c - sz * 0.5, sz), sz.y * 0.4, Color(UiLook.col(UiLook.SCRIM), 0.7 * a), Color(UiLook.col(UiLook.EDGE), 0.4 * a), 1.2)
		# The triangle at the outward end, hollow, on a dark keyline.
		var hl: float = sz.y * 0.3
		var tc: Vector2 = c + d * (sz.x * 0.5 - sz.y * 0.5) if absf(d.x) > 0.5 else c + d * (sz.y * 0.5 - sz.y * 0.5)
		if absf(d.x) < 0.5:
			tc = c + Vector2(sz.x * 0.28, 0.0)   # above: the triangle points up, to the right of the number
		var tri := PackedVector2Array([tc + d * hl * 1.0, tc - d * hl * 0.6 + perp * hl * 0.9, tc - d * hl * 0.6 - perp * hl * 0.9, tc + d * hl * 1.0])
		ci.draw_polyline(tri, Color(0, 0, 0, 0.75 * a), maxf(3.4, sz.y * 0.1) + 1.6, true)
		ci.draw_polyline(tri, col, maxf(2.2, sz.y * 0.09), true)
		var fs: int = UiText.px(20.0 if sz.y >= 34.0 else 17.0, s)
		var lx: float = c.x - sz.x * 0.18 if absf(d.x) > 0.5 and d.x > 0.0 else (c.x + sz.x * 0.16 if absf(d.x) > 0.5 else c.x - sz.x * 0.2)
		UiText.draw(ci, str(m["label"]), Vector2(lx, c.y + float(fs) * 0.35), fs, ink, 0)
	UiText.no_outline = false
