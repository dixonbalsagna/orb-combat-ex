class_name UiTug
## The beam struggle as a tug of war (Game Design's eleventh round, docs/design/rule-of-cool.md section 2; Encounter's park docs/director/pending/beam-struggle). HUD's part:
## where the beams meet, the beat the players press on, and what each press did. Drawn between the two fighters' hands while a struggle is on, and only then.
##   - the track: a thin line from one fighter's hands to the other's, with the quarter nearest each fighter's hands thicker in his ring colour (the comeback's zone, where a surge is worth half again);
##   - the meeting point: a diamond on the track at `Clash.mid` (0 at the first fighter's hands, 1 at the second's), moved by the sim each tick;
##   - the beat: a thin ring round the point that closes over the 20 ticks between pulses (`beam_pulse`) and meets the point on the next one: press as it closes. Under Reduced motion or Reduce
##     flashing the ring does not move: it is a steady double ring, and a short bar beside the point is filled for the instant after each pulse;
##   - a surge (`beam_surge`): short rays at the point in the presser's colour, three for a surge and five for a sharp one; a stray (`beam_stray`): a small cross, grey, on the presser's side;
##   - the end (`beam_end`): the point and its ring stay a second where it ended.
## All strokes, no filled area that changes: under any block threshold, and nothing changes state more than three times a second (the pulse is every 20 ticks). Nothing here is read by the sim.

const PERIOD := 20.0 / 60.0    # seconds between pulses (data/director/interrupts.json beamStruggle.pulse, 20 ticks)
const RING_STEPS := 12         # the closing ring redraws in this many steps a pulse (36 a second), not every frame
const MIN_SPAN := 40.0


## The plan, or {} when there is no struggle or a fighter cannot be placed. `anchors` is the host's anchor_fn for the two slots ({pos, h, visible}); `steady` is Reduced motion or Reduce flashing.
static func plan(lay: UiLayout, tug: Dictionary, anchors: Array, s: float, steady: bool) -> Dictionary:
	if tug.is_empty() or anchors.size() < 2:
		return {}
	var aa: Dictionary = anchors[0]
	var ad: Dictionary = anchors[1]
	if aa.is_empty() or ad.is_empty():
		return {}
	var inset: float = 24.0 * s
	var box := Rect2(lay.safe.position + Vector2(inset, inset), lay.safe.size - Vector2(inset, inset) * 2.0)
	var pa: Vector2 = _clamp(aa["pos"], box)
	var pd: Vector2 = _clamp(ad["pos"], box)
	if pa.distance_to(pd) < MIN_SPAN * s:
		pd = pa + Vector2(MIN_SPAN * s, 0.0)
	var mid: float = clampf(float(tug.get("mid", 0.5)), 0.0, 1.0)
	var pm: Vector2 = pa.lerp(pd, mid)
	var h: float = maxf(float(aa.get("h", 80.0)), float(ad.get("h", 80.0)))
	var r1: float = clampf(h * 0.22, 14.0 * s, 40.0 * s)   # the ring's rest radius (the point's own)
	var pulse_t: float = float(tug.get("pulse_t", 99.0))
	var phase: float = clampf(pulse_t / PERIOD, 0.0, 1.0)   # 0 just after a pulse, 1 at the next
	var step: int = int(phase * float(RING_STEPS))
	var marks: Array = []
	for mk in tug.get("marks", []):
		marks.append({"slot": int(mk["slot"]), "kind": str(mk["kind"]), "age": float(mk["age"]), "side": 0 if int(mk["slot"]) == int(tug["a"]) else 1})
	return {"a": pa, "d": pd, "pm": pm, "mid": mid, "r1": r1, "phase": phase, "step": step, "steady": steady, "s": s, "slot_a": int(tug["a"]), "slot_d": int(tug["d"]),
		"marks": marks, "ended": str(tug.get("end", "")) != "", "beat": pulse_t < 0.12}


static func _clamp(p: Vector2, box: Rect2) -> Vector2:
	return Vector2(clampf(p.x, box.position.x, box.end.x), clampf(p.y, box.position.y, box.end.y))


## What the picture depends on: the point (a pixel), the ring's step, the marks' ages (to a fifth of their life), and whether the beat bar is up.
static func sig(p: Dictionary) -> Variant:
	if p.is_empty():
		return null
	var pm: Vector2 = p["pm"]
	var ms: Array = []
	for mk in p["marks"]:
		ms.append([int(mk["slot"]), str(mk["kind"]), int(float(mk["age"]) / UiEventHub.TUG_MARK_LIFE * 5.0)])
	var pa: Vector2 = p["a"]
	var pd: Vector2 = p["d"]
	return [int(pm.x), int(pm.y), int(pa.x), int(pa.y), int(pd.x), int(pd.y), 0 if bool(p["steady"]) else int(p["step"]), bool(p["steady"]), bool(p["beat"]), p["ended"], ms]


static func draw(ci: CanvasItem, hub: UiEventHub, p: Dictionary, o: Dictionary) -> void:
	if p.is_empty():
		return
	var a: float = float(o.get("plate_alpha", 1.0))
	var s: float = float(p["s"])
	var pa: Vector2 = p["a"]
	var pd: Vector2 = p["d"]
	var pm: Vector2 = p["pm"]
	var ink := Color(UiLook.col(UiLook.INK), 0.95 * a)
	var key := Color(0, 0, 0, 0.7 * a)
	var ma: UiFighterModel = hub.model(int(p["slot_a"]))
	var md: UiFighterModel = hub.model(int(p["slot_d"]))
	var ca: Color = Color(ma.aura, a) if ma != null else ink
	var cd: Color = Color(md.aura, a) if md != null else ink
	var w: float = maxf(2.0, 2.4 * s)
	# The track: a dark keyline under a light line; the quarter nearest each fighter's hands in his colour.
	ci.draw_line(pa, pd, key, w + 3.0, true)
	ci.draw_line(pa, pd, Color(ink, 0.55 * a), w, true)
	ci.draw_line(pa, pa.lerp(pd, 0.25), key, w + 5.0, true)
	ci.draw_line(pa, pa.lerp(pd, 0.25), ca, w + 2.0, true)
	ci.draw_line(pd, pd.lerp(pa, 0.25), key, w + 5.0, true)
	ci.draw_line(pd, pd.lerp(pa, 0.25), cd, w + 2.0, true)
	var hr: float = 7.0 * s
	ci.draw_arc(pa, hr, 0.0, TAU, 20, key, w + 3.0, true)
	ci.draw_arc(pa, hr, 0.0, TAU, 20, ca, w, true)
	ci.draw_arc(pd, hr, 0.0, TAU, 20, key, w + 3.0, true)
	ci.draw_arc(pd, hr, 0.0, TAU, 20, cd, w, true)
	# The beat: a ring closing on the point (or, steady, two rings and a bar that fills for an instant after each pulse).
	var r1: float = float(p["r1"])
	if bool(p["steady"]):
		for rr in [r1, r1 * 1.7]:
			ci.draw_arc(pm, float(rr), 0.0, TAU, 32, key, w + 2.0, true)
			ci.draw_arc(pm, float(rr), 0.0, TAU, 32, Color(ink, 0.8 * a), w, true)
		var bw: float = r1 * 1.4
		var br := Rect2(pm + Vector2(-bw * 0.5, -r1 * 2.5), Vector2(bw, maxf(4.0 * s, 4.0)))
		ci.draw_rect(br, Color(ink, 0.8 * a), false, 1.6)
		if bool(p["beat"]):
			ci.draw_rect(br, Color(ink, 0.9 * a))
	else:
		var rr2: float = r1 * (1.0 + 1.4 * (1.0 - float(p["step"]) / float(RING_STEPS)))   # wide just after a pulse, meeting the point at the next
		ci.draw_arc(pm, rr2, 0.0, TAU, 32, key, w + 2.0, true)
		ci.draw_arc(pm, rr2, 0.0, TAU, 32, Color(ink, 0.9 * a), w, true)
	# The point: a diamond.
	var dr: float = r1 * 0.55
	var dia := PackedVector2Array([pm + Vector2(0, -dr), pm + Vector2(dr, 0), pm + Vector2(0, dr), pm + Vector2(-dr, 0), pm + Vector2(0, -dr)])
	ci.draw_polyline(dia, key, w + 3.0, true)
	UiIcons.fill_poly(ci, PackedVector2Array([dia[0], dia[1], dia[2], dia[3]]), ink)
	# What the presses did.
	for mk in p["marks"]:
		var life: float = clampf(float(mk["age"]) / UiEventHub.TUG_MARK_LIFE, 0.0, 1.0)
		var col: Color = ca if int(mk["slot"]) == int(p["slot_a"]) else cd
		var side: float = -1.0 if int(mk["slot"]) == int(p["slot_a"]) else 1.0
		if str(mk["kind"]) == "stray":
			var cp: Vector2 = pm + (pd - pa).normalized() * (side * (r1 * 1.4 + 8.0 * s))
			var cr: float = r1 * 0.35
			var gc := Color(UiLook.col(UiLook.INK_DIM), (1.0 - life) * a)
			ci.draw_line(cp + Vector2(-cr, -cr), cp + Vector2(cr, cr), gc, w, true)
			ci.draw_line(cp + Vector2(-cr, cr), cp + Vector2(cr, -cr), gc, w, true)
		else:
			var rays: int = 5 if str(mk["kind"]) == "sharp" else 3
			var base: float = (pd - pa).angle() + (PI if side < 0.0 else 0.0)   # the rays fan toward the rival's side of the point
			for i in range(rays):
				var ang: float = base + (float(i) - float(rays - 1) * 0.5) * 0.42
				var dir := Vector2.from_angle(ang)
				var r_in: float = r1 * (0.9 + 0.8 * life)
				var r_out: float = r_in + r1 * (0.6 if rays == 3 else 0.9)
				ci.draw_line(pm + dir * r_in, pm + dir * r_out, Color(0, 0, 0, (1.0 - life) * 0.7 * a), w + 2.0, true)
				ci.draw_line(pm + dir * r_in, pm + dir * r_out, Color(col, (1.0 - life) * a), w, true)
