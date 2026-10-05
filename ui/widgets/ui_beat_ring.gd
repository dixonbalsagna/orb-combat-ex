class_name UiBeatRing
## The beat ring (an option, off by default; Orb's questionnaires 17 and 18; docs/ui/hud-spec.md section 36). Every blow of the running exchange
## lands on a tick the sim already knows (the pending `strike` and `chainStrike` beats of the director's exchange). A ring on the fighter who is about to be
## struck closes on that tick, so a player can time a press, a parry, a step strike or a tech counter by it. It covers BOTH fighters' blows: a ring on
## the rival for the blows the player throws, a ring on the player's own fighter for the blows coming at him.
##   - the ring starts LEAD seconds before contact, wide and faint, and closes onto a fixed target ring and four notches at the contact tick;
##   - solid when the blow is a human's (yours), dashed when the AI throws it, so the two are told apart by shape, not colour;
##   - reduced motion: the ring does not close; a still ring with an arc that fills clockwise from the top to the notch at contact (no shrinking);
##   - it is only drawn while the option is on, and not in a sim pause or the intro. It reads the model's `beats`, nothing more: the HUD never writes the sim.
## `UiFighterModel.beats` is the seconds to contact of each pending blow on this fighter (UiSimBridge.beat_windows fills it).

const LEAD := 0.45        # seconds before contact that the ring appears
const MAX_RINGS := 2      # the nearest two blows per fighter (a chain's next blow is not drawn until it is near)


## The nearest pending contacts on this fighter, soonest first, at most MAX_RINGS.
static func nearest(beats: Array) -> Array:
	var out: Array = []
	for b in beats:
		var t: float = float(b)
		if t >= -0.02 and t <= LEAD:
			out.append(maxf(t, 0.0))
	out.sort()
	return out.slice(0, MAX_RINGS)


## The redraw key: each ring's progress in twentieths (so a ring redraws about 20 times a second while it closes), and who throws the blow.
static func sig(models: Array) -> Array:
	var out: Array = []
	for m in models:
		var ns: Array = nearest(m.beats)
		if ns.is_empty():
			continue
		var row: Array = [m.slot]
		for t in ns:
			row.append(int(float(t) / LEAD * 20.0))
		out.append(row)
	return out


## One fighter's rings at his anchor. `striker_human` is true when the blow comes from a human fighter (a solid ring), else dashed.
static func draw(ci: CanvasItem, m: UiFighterModel, centre: Vector2, radius: float, striker_human: bool, s: float, reduced: bool) -> void:
	var ns: Array = nearest(m.beats)
	if ns.is_empty():
		return
	var ink: Color = UiLook.col(UiLook.INK)
	var dark := Color(UiLook.col(UiLook.INK_DARK), 0.55)
	var lw: float = maxf(2.5, 3.0 * s)
	for k in range(ns.size()):
		var t: float = float(ns[k])
		var frac: float = clampf(t / LEAD, 0.0, 1.0)   # 1 far, 0 at contact
		var r_target: float = radius * 1.05
		var a: float = (1.0 - 0.45 * float(k)) * (0.45 + 0.55 * (1.0 - frac))
		if reduced:
			# Still: the target ring, and an arc that fills clockwise from the top; it is whole at contact.
			_ring(ci, centre, r_target * 1.35, 0.0, TAU, dark, lw + 2.0, striker_human, true)
			_ring(ci, centre, r_target * 1.35, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - frac), Color(ink, a), lw, striker_human, false)
		else:
			var r: float = r_target * (1.0 + 1.1 * frac)
			_ring(ci, centre, r, 0.0, TAU, dark, lw + 2.0, striker_human, true)
			_ring(ci, centre, r, 0.0, TAU, Color(ink, a), lw, striker_human, false)
	# The target and its four notches: where the ring ends. A notch is a short bar across the target ring at each quarter.
	var rt: float = radius * 1.05 * (1.35 if reduced else 1.0)
	ci.draw_arc(centre, rt, 0.0, TAU, 40, Color(ink, 0.35), maxf(1.5, 1.6 * s), true)
	for q in range(4):
		var d: Vector2 = Vector2.from_angle(float(q) * PI * 0.5)
		ci.draw_line(centre + d * (rt - 5.0 * s), centre + d * (rt + 6.0 * s), Color(ink, 0.9), maxf(2.0, 2.4 * s), true)


## A ring or an arc of it: solid, or dashed (eight dashes round a full circle) when the blow is the AI's. `shadow` draws the dark underlay.
static func _ring(ci: CanvasItem, c: Vector2, r: float, a0: float, a1: float, col: Color, w: float, solid: bool, shadow: bool) -> void:
	if solid:
		ci.draw_arc(c, r, a0, a1, 40, col, w, true)
		return
	var n: int = 12
	var span: float = (a1 - a0) / float(n)
	for i in range(n):
		var s0: float = a0 + span * float(i)
		ci.draw_arc(c, r, s0, s0 + span * 0.58, 4, col, w, true)
