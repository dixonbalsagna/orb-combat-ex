class_name UiTouchControls
extends RefCounted
## The on-screen controls of touch Simple (docs/controls/touch-bridge.md, ADR 0008): ATTACK (tap a light, hold a heavy, swipe up the
## signature), GUARD (hold) and POWER (hold to charge), drawn from `SimTouch.layout()`, the same call with the same inputs as the
## host's touch_layout(), so what is drawn is what is hit. A floating stick appears where the left thumb lands. There is no context
## button in this build; its slot carries a TRANSFORM button when the fighter can transform (the host hit-tests it as "context" until
## Controls gives it a name). The HUD never takes a touch itself: Controls' SimTouch does, and UI's pause and feedback targets win.
##
## `state` comes from the host (UiHud.touch_state_fn): {attack: {down, hold 0..1}, guard: {down}, power: {down}, stick: {active, base,
## thumb, sprint}, transform: {down}}. Without it every button is drawn idle. For the first seconds of a match (or while prompts are
## on) each button carries its word and the gesture ("TAP  HOLD  SWIPE UP"); a pressed button fills, Attack's ring fills over its 12
## ticks (it becomes a heavy), Power shows a ring while it charges, and the stick draws its base ring and thumb.

const HOLD_TICKS := 12.0
const NAMES: Array = ["attack", "guard", "power"]
## The Full layout's buttons (Controls' SimTouch.layout with full = true), in the order they are drawn.
const FULL_NAMES: Array = ["light", "heavy", "signature", "context", "power", "mode", "transform", "dodge", "guard"]


## The circle {x, y, r} of a control, or {} (attack, guard, power, context).
static func circle(lay: UiLayout, name: String) -> Dictionary:
	return lay.touch_ctrl.get(name, {})


static func rect_of(c: Dictionary) -> Rect2:
	if c.is_empty():
		return Rect2()
	return Rect2(float(c.x) - float(c.r), float(c.y) - float(c.r), float(c.r) * 2.0, float(c.r) * 2.0)


## The redraw key: the pressed bits, the hold ring in twelfths, the stick (quantised to 2 px), the captions' alpha and Transform's state.
static func sig(lay: UiLayout, state: Dictionary, intro_a: float, transform_avail: bool, pulse_step: int = -1, extra: Dictionary = {}) -> Array:
	var bits := 0
	var i := 0
	for n in NAMES:
		if bool((state.get(n, {}) as Dictionary).get("down", false)):
			bits |= (1 << i)
		i += 1
	if bool((state.get("transform", {}) as Dictionary).get("down", false)):
		bits |= (1 << 3)
	if lay.touch_full:
		var fb := 0
		var fi := 0
		var full: Dictionary = state.get("full", {})
		var arm_sig: Array = []
		for n in FULL_NAMES:
			var fs_: Dictionary = full.get(n, {})
			if bool(fs_.get("down", false)):
				fb |= (1 << fi)
			if float(fs_.get("armed", 0.0)) > 0.0 or bool(fs_.get("latched", false)):
				arm_sig.append([fi, int(clampf(float(fs_.get("armed", 0.0)), 0.0, 1.0) * 12.0), bool(fs_.get("latched", false))])
			fi += 1
		bits |= fb << 4
		bits = bits * 31 + hash(arm_sig)
	var st: Dictionary = state.get("stick", {})
	var sk: Array = []
	if bool(st.get("active", false)):
		var b: Vector2 = st.get("base", Vector2.ZERO)
		var t: Vector2 = st.get("thumb", Vector2.ZERO)
		sk = [int(b.x * 0.5), int(b.y * 0.5), int(t.x * 0.5), int(t.y * 0.5), bool(st.get("sprint", false))]
	return [int(lay.vp.x), int(lay.vp.y), int(lay.dp * 100.0), lay.left_handed, lay.touch_full, bits, int(float((state.get("attack", {}) as Dictionary).get("hold", 0.0)) * HOLD_TICKS), int(float((state.get("attack", {}) as Dictionary).get("hold_ticks", 0.0))), int((state.get("attack", {}) as Dictionary).get("tier", 0)), sk, int(intro_a * 10.0), transform_avail, pulse_step, extra_key(extra)]


## The redraw key for what the HUD adds to the Full buttons: the greyed ones and the press mark in quarters of its life.
static func extra_key(extra: Dictionary) -> Array:
	var ack: Dictionary = extra.get("ack", {})
	var chg: Dictionary = extra.get("charge", {})
	return [(extra.get("dim", []) as Array).duplicate(), str(ack.get("name", "")), str(ack.get("kind", "")), int(float(ack.get("a", 0.0)) * 4.0), str(chg.get("name", "")), int(float(chg.get("frac", 0.0)) * 8.0), (extra.get("lit", []) as Array).duplicate(), str(extra.get("launcher", ""))]


## `pulse_step` is -1 for no pulse, else 0 to 7 round the cycle (the HUD steps it eight times a cycle while a form is ready and the fighter is free); under
## reduced motion it is 8, a steady bright ring.
static func draw(ci: CanvasItem, lay: UiLayout, s: float, state: Dictionary, intro_a: float, transform_avail: bool, pulse_step: int = -1, extra: Dictionary = {}) -> void:
	if lay.touch_ctrl.is_empty():
		return
	var ink := Color(UiLook.col(UiLook.INK))
	var dark := Color(UiLook.col(UiLook.INK_DARK))
	var edge := Color(UiLook.col(UiLook.EDGE))
	var scrim := Color(UiLook.col(UiLook.SCRIM))
	var line: float = maxf(2.0, 2.5 * s)
	UiText.no_outline = true
	# The floating stick, where the thumb landed.
	var st: Dictionary = state.get("stick", {})
	var rs: float = 56.0 * lay.dp
	if bool(st.get("active", false)):
		var b: Vector2 = st["base"]
		var th: Vector2 = st["thumb"]
		var off: Vector2 = th - b
		if off.length() > rs * 1.1:
			off = off.normalized() * rs * 1.1
		var sprint: bool = bool(st.get("sprint", false))
		ci.draw_circle(b, rs, Color(scrim, 0.35))
		ci.draw_arc(b, rs, 0.0, TAU, 40, Color(edge, 0.7 if sprint else 0.45), line * (2.0 if sprint else 1.0), true)
		ci.draw_circle(b + off, rs * 0.42, Color(ink, 0.55))
	elif intro_a > 0.01:
		# The first seconds: where the stick will be, and what a flick does.
		var z: Dictionary = lay.touch_ctrl.get("stick", {})
		if not z.is_empty():
			var zc := Vector2((float(z.x0) + float(z.x1)) * 0.5, float(z.y0) + (float(z.y1) - float(z.y0)) * 0.32)
			ci.draw_arc(zc, rs * 0.8, 0.0, TAU, 32, Color(edge, 0.3 * intro_a), line, true)
			var fs0: int = UiText.px(16.0, s)
			UiText.draw(ci, UiData.t("prompt.move"), Vector2(zc.x, zc.y - UiText.height(fs0) * 0.5 + UiText.ascent(fs0) - float(fs0) * 0.6), fs0, Color(ink, 0.8 * intro_a), 0)
			UiText.draw(ci, UiData.t("prompt.move_hint"), Vector2(zc.x, zc.y - UiText.height(fs0) * 0.5 + UiText.ascent(fs0) + float(fs0) * 0.6), fs0, Color(ink, 0.6 * intro_a), 0)
	if lay.touch_full:
		_draw_full(ci, lay, s, state, transform_avail, ink, dark, edge, scrim, line, pulse_step, extra)
		UiText.no_outline = false
		return
	# The three buttons.
	for n in NAMES:
		var c: Dictionary = lay.touch_ctrl.get(n, {})
		if c.is_empty():
			continue
		var bs: Dictionary = state.get(n, {})
		var down: bool = bool(bs.get("down", false))
		var p := Vector2(float(c.x), float(c.y))
		var r: float = float(c.r)
		ci.draw_circle(p, r, Color(ink, 0.88) if down else Color(scrim, 0.58))
		ci.draw_arc(p, r, 0.0, TAU, 40, Color(edge, 0.9), line, true)
		var icol: Color = dark if down else ink
		match n:
			"attack":
				UiIcons.star4(ci, p, r * 1.05, icol)
				var hold: float = clampf(float(bs.get("hold", 0.0)), 0.0, 1.0)
				if UiStance.three() and bs.has("hold_ticks"):
					_draw_attack_ring(ci, p, r, bs, down)   # one button, three strengths: the ring has a notch at each threshold
				elif down and hold > 0.0:
					ci.draw_arc(p, r * 1.14, -PI * 0.5, -PI * 0.5 + TAU * hold, 40, Color(UiLook.col(UiLook.WARN)), maxf(3.0, r * 0.1), true)
			"guard":
				UiIcons.stance5(ci, 1, p, r * 1.0, dark if down else UiStance.col(1))
			"power":
				UiIcons.caret_up(ci, p + Vector2(0.0, r * 0.1), r * 0.95, icol)
				if down:
					ci.draw_arc(p, r * 1.14, 0.0, TAU, 40, Color(UiLook.col(UiLook.CHARGE)), maxf(3.0, r * 0.1), true)
		if intro_a > 0.01:
			var fs: int = UiText.px(15.0, s)
			var lh: float = UiText.height(fs)
			var word: String = UiData.t("prompt." + n)
			var hint: String = UiData.t("prompt." + n + "_hint")
			if lay.portrait:
				# Portrait is tight: Power's word goes to its left, Attack's and Guard's below; only Attack keeps its gesture line.
				if n == "power":
					UiText.draw(ci, word, Vector2(p.x - r - 8.0 * lay.dp, p.y - lh * 0.5 + UiText.ascent(fs)), fs, Color(ink, 0.95 * intro_a), 1)
				else:
					var by: float = p.y + r + UiText.ascent(fs) + float(fs) * 0.1
					UiText.draw(ci, word, Vector2(p.x, by), fs, Color(ink, 0.95 * intro_a), 0)
					if n == "attack":
						UiText.draw(ci, hint, Vector2(p.x, by + lh), fs, Color(ink, 0.7 * intro_a), 0)
			else:
				# Landscape: Power's words go above it (Attack sits just under it); Attack's and Guard's go below.
				var top: float = (p.y - r - lh * 2.0 - 2.0) if n == "power" else (p.y + r + float(fs) * 0.1)
				var base: float = top + UiText.ascent(fs)
				UiText.draw(ci, word, Vector2(p.x, base), fs, Color(ink, 0.95 * intro_a), 0)
				UiText.draw(ci, hint, Vector2(p.x, base + lh), fs, Color(ink, 0.7 * intro_a), 0)
	# TRANSFORM, in the context button's slot, only while it can be used.
	if transform_avail:
		var tc: Dictionary = lay.touch_ctrl.get("context", {})
		if not tc.is_empty():
			var tp := Vector2(float(tc.x), float(tc.y))
			var tr: float = float(tc.r)
			var tdown: bool = bool((state.get("transform", {}) as Dictionary).get("down", false))
			ci.draw_circle(tp, tr, Color(ink, 0.88) if tdown else Color(scrim, 0.62))
			ci.draw_arc(tp, tr, 0.0, TAU, 40, Color(edge, 0.9), line, true)
			ci.draw_arc(tp, tr * 0.72, 0.0, TAU, 32, dark if tdown else Color(ink, 0.8), line, true)
			UiIcons.star4(ci, tp, tr * 0.8, dark if tdown else ink)
			if pulse_step >= 0 and not tdown:
				_form_pulse(ci, tp, tr, line, pulse_step)
			if intro_a > 0.01:
				var fs2: int = UiText.px(15.0, s)
				UiText.draw(ci, UiData.t("prompt.transform"), Vector2(tp.x, tp.y - tr - float(fs2) * 0.4), fs2, Color(ink, 0.95 * intro_a), 0)
	UiText.no_outline = false


## Simple under three strengths (Controls' display_state attack: hold_ticks, tier, medium_at, heavy_at, swipe): the ring fills over the hold to the heavy threshold (to the medium one
## when the heavy is a swipe up, `swipe`), with a notch at the medium and at the heavy threshold; the tier reached is lit (a thicker ring). A shape cue, no colour reliance.
static func _draw_attack_ring(ci: CanvasItem, p: Vector2, r: float, bs: Dictionary, down: bool) -> void:
	var med: float = maxf(float(bs.get("medium_at", 12)), 1.0)
	var hv: float = maxf(float(bs.get("heavy_at", 28)), med + 1.0)
	var swipe: bool = bool(bs.get("swipe", false))
	var span: float = med if swipe else hv
	var ht: float = float(bs.get("hold_ticks", 0.0))
	var tier: int = int(bs.get("tier", 0))
	var rr: float = r * 1.14
	var warn := Color(UiLook.col(UiLook.WARN))
	var ink := Color(UiLook.col(UiLook.INK))
	if down:
		ci.draw_arc(p, rr, 0.0, TAU, 40, Color(ink, 0.2), maxf(2.0, r * 0.06), true)
		var f: float = clampf(ht / span, 0.0, 1.0)
		if f > 0.0:
			ci.draw_arc(p, rr, -PI * 0.5, -PI * 0.5 + TAU * f, 40, warn, maxf(3.0, r * (0.1 + 0.05 * float(mini(tier, 2)))), true)
	# the notches: at the medium threshold, and at the heavy one (the end of the ring) unless the heavy is a swipe
	var marks: Array = [med / span]
	if not swipe:
		marks.append(1.0)
	for mk in marks:
		var ang: float = -PI * 0.5 + TAU * minf(float(mk), 0.999)
		var d := Vector2.from_angle(ang)
		ci.draw_line(p + d * rr * 0.9, p + d * rr * 1.2, Color(ink, 0.9 if down else 0.45), maxf(2.0, r * 0.07), true)


## The ready Transform button's pulse: a ring that swells off the button's edge and fades (a steady thick ring when `step` is 8, reduced motion).
static func _form_pulse(ci: CanvasItem, c: Vector2, r: float, line: float, step: int) -> void:
	var ink := Color(UiLook.col(UiLook.CHARGE_READY))
	if step >= 8:
		ci.draw_arc(c, r * 1.12, 0.0, TAU, 40, Color(ink, 1.0), line * 2.2, true)
		return
	var k: float = float(step) / 8.0
	ci.draw_arc(c, r * (1.06 + 0.22 * k), 0.0, TAU, 40, Color(ink, 1.0 - k), line * (2.4 - 1.2 * k), true)
	ci.draw_arc(c, r * 1.06, 0.0, TAU, 40, Color(ink, 0.55), line * 1.4, true)


## The Full layout: a diamond of Light, Heavy, Signature and Context, Power and Mode above it, Transform beside it (lit while a form is
## ready), Dodge and Guard stacked at the other edge. Each button carries its word; a held one fills.
static func _draw_full(ci: CanvasItem, lay: UiLayout, s: float, state: Dictionary, transform_avail: bool, ink: Color, dark: Color, edge: Color, scrim: Color, line: float, pulse_step: int = -1, extra: Dictionary = {}) -> void:
	var full: Dictionary = state.get("full", {})
	for n in FULL_NAMES:
		var c: Dictionary = lay.touch_ctrl.get(n, {})
		if c.is_empty():
			continue
		var down: bool = bool((full.get(n, {}) as Dictionary).get("down", false))
		var p := Vector2(float(c.x), float(c.y))
		var r: float = float(c.r)
		var dim: float = 0.55 if (n == "transform" and not transform_avail and not down) else 1.0
		var not_yet: bool = (extra.get("dim", []) as Array).has(n) and not down   # a button with no move in the stance held now: greyed, and says so
		if not_yet:
			dim = 0.45
		ci.draw_circle(p, r, Color(ink, 0.88) if down else Color(scrim, 0.58 * dim))
		ci.draw_arc(p, r, 0.0, TAU, 40, Color(edge, 0.9 * dim), line, true)
		if n == "transform" and transform_avail and not down:
			ci.draw_arc(p, r * 0.8, 0.0, TAU, 32, Color(UiLook.col(UiLook.CHARGE_READY)), line, true)
			if pulse_step >= 0:
				_form_pulse(ci, p, r, line, pulse_step)
		var word: String = UiData.t("prompt." + n) if (n == "power" or n == "guard") else UiData.t("prompt.full_" + n)
		if UiStance.three() and n == "heavy":
			word = UiData.t("prompt.three_full_heavy")        # the three strengths: Y is the medium and B the heavy (the ids stay)
		elif UiStance.three() and n == "signature":
			word = UiData.t("prompt.three_full_signature")
		var stance_word: String = UiStance.touch_word(n)   # a stance button is named for its stance once the stance is live
		if stance_word != "":
			word = stance_word
		# An armed stance (a tap: the next blow only, 90 ticks) shows a ring that runs down and the word NEXT; energy's latch a steady ring.
		var fstate: Dictionary = full.get(n, {})
		var armed: float = clampf(float(fstate.get("armed", 0.0)), 0.0, 1.0)
		if UiHints.HOLD_STANCES.has(n):
			var scol: Color = UiStance.col(int(UiHints.HOLD_STANCES[n]))
			if armed > 0.0:
				ci.draw_arc(p, r * 1.12, -PI * 0.5, -PI * 0.5 + TAU * armed, 40, scol, maxf(3.0, line * 2.0), true)
				word = UiStance.armed_word(true)
			elif bool(fstate.get("latched", false)):
				ci.draw_arc(p, r * 1.12, 0.0, TAU, 40, scol, maxf(3.0, line * 2.0), true)
		if not_yet:
			word = UiData.t("prompt.not_yet").to_upper()
		var fs: int = UiText.px(14.0, s)
		while fs > int(UiLook.text_floor) and UiText.width(word, fs) > r * 1.7:
			fs -= 1
		UiText.draw(ci, word, Vector2(p.x, p.y + UiText.ascent(fs) - UiText.height(fs) * 0.5), fs, Color(dark if down else ink, dim), 0)
		var chg: Dictionary = extra.get("charge", {})
		if not chg.is_empty() and str(chg.get("name", "")) == n:
			UiHints.draw_charge(ci, p, r * 1.1, float(chg["frac"]), bool(chg.get("armoured", false)), 1.0)
		if (extra.get("lit", []) as Array).has(n):
			UiHints.draw_lit(ci, p, r * 0.95, 1.0)
		var lmark: String = str(extra.get("launcher", ""))
		if lmark != "" and n == "signature":
			# The launcher's steady state on B: a filled mark while a launch is ready, a hollow dim one while it rests (no countdown).
			var lc: Vector2 = p + Vector2(-r * 0.62, -r * 0.62)
			var lr: float = r * 0.2
			var tri := PackedVector2Array([lc + Vector2(0.0, -lr), lc + Vector2(lr * 0.95, lr * 0.75), lc + Vector2(-lr * 0.95, lr * 0.75)])
			if lmark == "ready":
				UiIcons.fill_poly(ci, tri, ink)
			else:
				var cl: PackedVector2Array = tri.duplicate()
				cl.append(tri[0])
				ci.draw_polyline(cl, Color(ink, 0.55), maxf(2.0, lr * 0.4), true)
		# The press that did nothing: a short grey mark on the button (a shape: cross, dash, dot or ring).
		var ack: Dictionary = extra.get("ack", {})
		if not ack.is_empty() and str(ack.get("name", "")) == n and float(ack.get("a", 0.0)) > 0.0:
			UiHints.draw_ack(ci, str(ack["kind"]), p + Vector2(r * 0.55, -r * 0.55), r * 0.38, float(ack["a"]), Color(UiLook.col(UiLook.INK)))
