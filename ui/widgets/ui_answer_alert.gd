class_name UiAnswerAlert
extends RefCounted
## The beam answer alert (docs/ui/beam-answer-alert.md; Game Design's ruling, docs/design/rule-of-cool-map.md section 5, rows 40 and 41). When a beam leaves a hand there is a window to answer, fire back or
## dodge, until the front arrives; the gathering before it is a warning. UI draws two of the alert families, both for the target only and both view only (the hash never sees them):
##   the SCREEN EDGE LINE: a thin steady line of the shooter's colour at the screen's edge on his side, with a small mark pointing inward (a shape as well as a colour);
##   the CAPTION: BEAM INCOMING (or BEAM CHARGING), the answers that are open as the player's own buttons and words, and a bar that runs down to arrival with a notch where the dodge opens.
## The shooter's glint, the air and light, the sound and the rumble are VFX's, Audio's and Controls'; this file also says what the player chose for them (`effective`).
## Nothing here fades, pulses or moves: a mark is drawn or it is not, and nothing is drawn over a fighter (a mark that would meet a body is not drawn).

const FAMILIES := ["alert_preset", "alert_edge", "alert_edge_width", "alert_caption", "alert_caption_size", "alert_caption_pos", "alert_early", "alert_which", "alert_glint", "alert_air", "alert_sound", "alert_sound_volume", "alert_rumble", "alert_rumble_strength"]

## The three sets. A row the player changes afterwards turns the set to Custom.
const PRESETS := {
	"calm": {"alert_edge": "off", "alert_edge_width": "medium", "alert_caption": true, "alert_caption_size": "medium", "alert_caption_pos": "bottom", "alert_early": true, "alert_which": "all", "alert_glint": "normal", "alert_air": "off", "alert_sound": true, "alert_sound_volume": "low", "alert_rumble": true, "alert_rumble_strength": "low"},
	"standard": {"alert_edge": "offscreen", "alert_edge_width": "medium", "alert_caption": false, "alert_caption_size": "medium", "alert_caption_pos": "side", "alert_early": false, "alert_which": "all", "alert_glint": "normal", "alert_air": "subtle", "alert_sound": true, "alert_sound_volume": "normal", "alert_rumble": true, "alert_rumble_strength": "medium"},
	"full": {"alert_edge": "always", "alert_edge_width": "thick", "alert_caption": true, "alert_caption_size": "medium", "alert_caption_pos": "side", "alert_early": true, "alert_which": "all", "alert_glint": "bright", "alert_air": "strong", "alert_sound": true, "alert_sound_volume": "loud", "alert_rumble": true, "alert_rumble_strength": "high"},
}
const WIDTH_PX := {"thin": 3.0, "medium": 6.0, "thick": 10.0}
const CAPTION_SCALE := {"small": 0.9, "medium": 1.15, "large": 1.7}   # Large is clearly larger (Accessibility): the words still follow Text size, and never go under the text floor
const MIN_LEVEL := {"all": 0, "charged": 1, "signature": 4}


static func suffix(slot: int) -> String:
	return "_p2" if slot == 1 else ""


## What a player chose, one value per family, with Reduce flashing's limit applied: the strong air, the bright glint, the thick line and the loudest, hardest answers come down a step.
## The host (VFX, Audio, Controls) reads this through UiHud.alert_for(slot); UI reads it for the line and the caption.
static func effective(opts: Dictionary, slot: int) -> Dictionary:
	var sfx: String = suffix(slot)
	var out := {}
	for k in FAMILIES:
		out[k.trim_prefix("alert_")] = opts.get(k + sfx, null)
	if bool(opts.get("reduce_flashing", true)):
		if out["air"] == "strong":
			out["air"] = "subtle"
		if out["glint"] == "bright":
			out["glint"] = "normal"
		if out["edge_width"] == "thick":
			out["edge_width"] = "medium"
	return out


## Whether this window or gathering is one the player asked to be told of: its level against Which beams warn, and a gathering only with Early warning.
static func wanted(alert: Dictionary, eff: Dictionary) -> bool:
	if alert.is_empty():
		return false
	if str(alert["phase"]) == "warn":
		return str(eff.get("edge", "off")) != "off" or bool(eff.get("caption", false))   # a beam from the other fight: its level is not known, so Which beams does not filter it
	if str(alert["phase"]) == "charge" and not bool(eff.get("early", false)):
		return false
	return int(alert.get("level", 1)) >= int(MIN_LEVEL.get(str(eff.get("which", "all")), 0))


## RL-227: the edge line is never white, gold or red. A shooter whose colour is one of those gets a blue-violet line instead (the line says where he is by its place and its arrow; the colour is only a help).
static func safe_colour(c: Color) -> Color:
	var h: float = c.h
	var red: bool = (h < 0.045 or h > 0.945) and c.s > 0.45
	var gold: bool = h >= 0.08 and h <= 0.18 and c.s > 0.45
	var white: bool = c.s < 0.18 and c.v > 0.75
	if red or gold or white:
		return Color.from_hsv(0.66, 0.55, 0.95)
	return c


## The edge line's strength, 0 to 1: it ramps in over 6 ticks when the alert starts and out over the same when it ends (RL-227: never blinks, never faster than 6 ticks). Steady between.
static func line_alpha(alert: Dictionary) -> float:
	var ramp: float = 6.0 / 60.0
	var a_in: float = clampf(float(alert.get("age", 0.0)) / ramp, 0.0, 1.0)
	var a_out: float = 1.0
	if alert.has("end_t"):
		a_out = 1.0 - clampf(float(alert["end_t"]) / ramp, 0.0, 1.0)
	return minf(a_in, a_out)


## The line's colour for a beam from the other fight, whose shooter has no colour here: the blue-violet RL-227 falls back to (never white, gold or red).
static func outside_col() -> Color:
	return Color.from_hsv(0.66, 0.55, 0.95)


## Where a beam from the other fight comes from: "left" or "right" when the sim says it (dir -1 or +1), else 0 for both edges. The shooter is in the other fight, so he is taken to be off this screen.
static func side_hint(hint: String, an_t: Dictionary, vp: Vector2) -> Dictionary:
	var t_pos: Vector2 = an_t.get("pos", Vector2.ZERO)
	return {"dir": -1 if hint == "left" else (1 if hint == "right" else 0), "off": true, "y": t_pos.y if t_pos != Vector2.ZERO else vp.y * 0.5}


## Where the shooter is on this player's screen: +1 for the right edge, -1 for the left, and whether he is off screen. `an_t` and `an_s` are the target's and the shooter's anchors.
static func side(an_t: Dictionary, an_s: Dictionary, vp: Vector2, shooter_left: bool) -> Dictionary:
	var s_pos: Vector2 = an_s.get("pos", Vector2.ZERO)
	var t_pos: Vector2 = an_t.get("pos", Vector2.ZERO)
	var known: bool = s_pos != Vector2.ZERO and t_pos != Vector2.ZERO
	var off: bool = not known or not bool(an_s.get("visible", true)) or not Rect2(Vector2.ZERO, vp).has_point(s_pos)
	var dir: int = (1 if s_pos.x >= t_pos.x else -1) if known else (-1 if shooter_left else 1)
	return {"dir": dir, "off": off, "y": (t_pos.y if t_pos != Vector2.ZERO else vp.y * 0.5)}


## The line's rectangle at the screen's edge, level with the target and held inside the middle of the screen's height.
static func line_rect(lay: UiLayout, dir: int, y: float, eff: Dictionary) -> Rect2:
	var w: float = float(WIDTH_PX.get(str(eff.get("edge_width", "medium")), 6.0)) * maxf(lay.s, 0.75)
	var h: float = lay.vp.y * 0.34
	var cy: float = clampf(y, lay.vp.y * 0.28, lay.vp.y * 0.72)
	return Rect2(0.0 if dir < 0 else lay.vp.x - w, cy - h * 0.5, w, h)


## The caption's rectangle: on the shooter's edge, just inside the line, as wide as its words need; height one row of words and one of bar.
static func caption_rect(lay: UiLayout, dir: int, y: float, eff: Dictionary, label_w: float, glyph_row_w: float) -> Rect2:
	var sc: float = float(CAPTION_SCALE.get(str(eff.get("caption_size", "medium")), 1.0))
	var fs: int = UiText.px(18.0 * sc, lay.s)
	var w: float = maxf(label_w, glyph_row_w) + 24.0 * lay.s * sc
	var h: float = float(fs) * 2.0 + 44.0 * lay.s * sc
	if str(eff.get("caption_pos", "side")) == "bottom":
		# One fixed place, under the fight: centred, above the planet map's slot (or the strip, or the foot of the safe area).
		var floor_y: float = lay.ring.position.y if lay.ring.size.y > 0.0 else (lay.strip.position.y if lay.strip.size.y > 0.0 else lay.safe.end.y)
		return Rect2(lay.vp.x * 0.5 - w * 0.5, minf(floor_y, lay.safe.end.y) - 8.0 * lay.s - h, w, h)
	var line_w: float = float(WIDTH_PX.get(str(eff.get("edge_width", "medium")), 6.0)) * maxf(lay.s, 0.75)
	var cy: float = clampf(y, lay.safe.position.y + h * 0.5, lay.safe.end.y - h * 0.5)
	var x: float = lay.safe.position.x + line_w + 6.0 * lay.s if dir < 0 else lay.safe.end.x - line_w - 6.0 * lay.s - w
	return Rect2(x, cy - h * 0.5, w, h)


## How far the window has run, 0 to 1 of the way to arrival (the bar is 1 - this). A quarter at a time under reduced motion.
static func run_frac(alert: Dictionary, reduced: bool) -> float:
	var f: float = clampf(float(alert["age"]) / maxf(float(alert["dur"]), 0.001), 0.0, 1.0)
	if str(alert["phase"]) != "window":
		return 0.0
	return floorf(f * 4.0) / 4.0 if reduced else f


## Whether the dodge is open now: the last `dodge_from` ticks before arrival.
static func dodge_open(alert: Dictionary) -> bool:
	if str(alert["phase"]) != "window":
		return false
	var left_ticks: float = (float(alert["dur"]) - float(alert["age"])) * 60.0
	return left_ticks <= float(alert["dodge_from"])


## The caption's pieces: the title, and the answers that are open as [{word, action, open}]. A gathering has no answers yet.
static func pieces(alert: Dictionary) -> Dictionary:
	if str(alert["phase"]) == "warn":
		return {"title": UiData.t("prompt.alert_outside"), "answers": [{"word": UiData.t("prompt.alert_dodge"), "action": "dodge", "open": true}]}
	var charging: bool = str(alert["phase"]) == "charge"
	var answers: Array = []
	if not charging:
		answers.append({"word": UiData.t("prompt.alert_fire_back"), "action": "mode", "aim": "strike", "open": true})   # a beam is the energy button and the stick toward him: both from the player's own layout
		answers.append({"word": UiData.t("prompt.alert_dodge"), "action": "dodge", "open": dodge_open(alert)})
	return {"title": UiData.t("prompt.alert_charging" if charging else "prompt.alert_incoming"), "answers": answers}


## The redraw key: the side, the bar in 5% steps, the dodge zone, the phase and what is shown.
static func sig(alert: Dictionary, eff: Dictionary, d: Dictionary, reduced: bool) -> Array:
	return [str(alert["phase"]), int(d["dir"]), int(run_frac(alert, reduced) * 20.0), dodge_open(alert), bool(d["off"]), str(eff.get("edge")), str(eff.get("edge_width")), bool(eff.get("caption")), str(eff.get("caption_size")), str(eff.get("caption_pos")), int(float(d["y"]) / 4.0), reduced, int(line_alpha(alert) * 6.0), alert.has("end_t")]


## Draw the line and the caption for a target. `bodies` are the fighters' torso boxes (UiHints.body_box): a mark that would meet one is not drawn.
static func draw(ci: CanvasItem, lay: UiLayout, alert: Dictionary, eff: Dictionary, d: Dictionary, shooter_col: Color, bodies: Array, reduced: bool, preset: String, slot: int, device: String) -> void:
	var dir: int = int(d["dir"])
	var edge_mode: String = str(eff.get("edge", "offscreen"))
	var show_line: bool = edge_mode == "always" or (edge_mode == "offscreen" and bool(d["off"]))
	var la: float = line_alpha(alert)
	if show_line and la > 0.0:
		shooter_col = Color(safe_colour(shooter_col), la)
		for dd in ([-1, 1] if dir == 0 else [dir]):   # dir 0 (a beam from the other fight with no side said): the line on both edges, and no arrow
			var lr: Rect2 = line_rect(lay, dd, float(d["y"]), eff)
			if _meets(lr, bodies):
				continue
			var back := Color(0.04, 0.05, 0.08, 0.9 * la)
			var wpx: float = lr.size.x
			ci.draw_rect(Rect2(lr.position - Vector2(2.0, 2.0), lr.size + Vector2(4.0, 4.0)), back)
			ci.draw_rect(lr, shooter_col)
			if dir == 0:
				continue
			# A small mark pointing inward, level with the middle of the line: the direction is a shape as well as a place.
			var tip: float = wpx * 2.2 + 8.0 * lay.s
			var mid: Vector2 = lr.get_center()
			var base_x: float = lr.end.x if dd < 0 else lr.position.x
			var sgn: float = 1.0 if dd < 0 else -1.0
			var tri := PackedVector2Array([Vector2(base_x, mid.y - tip * 0.6), Vector2(base_x + sgn * tip, mid.y), Vector2(base_x, mid.y + tip * 0.6)])
			ci.draw_colored_polygon(tri, shooter_col)
			ci.draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2]]), back, 2.0, true)
	if not bool(eff.get("caption", false)) or alert.has("end_t"):
		return   # the caption goes the moment the window ends; only the line ramps out
	var p: Dictionary = pieces(alert)
	var sc: float = float(CAPTION_SCALE.get(str(eff.get("caption_size", "medium")), 1.0))
	var fs: int = UiText.px(18.0 * sc, lay.s)
	var gh: float = maxf(20.0 * lay.s * sc, 16.0)
	var title: String = str(p["title"])
	var title_w: float = UiText.width(title, fs)
	var row_w: float = 0.0
	var rows: Array = []
	for a in p["answers"]:
		var fam: String = device if device != "" else "kbd"
		var specs: Array = UiGlyphs.specs_for(str(a["action"]), fam, slot, "neutral", preset)
		if a.has("aim") and UiData.feature("right_hand") and UiGlyphs.bound(preset, str(a["aim"]), slot):
			specs = specs + [{"kind": "plus", "label": "+"}] + UiGlyphs.specs_for(str(a["aim"]), fam, slot, "neutral", preset)
		var sw := 0.0
		for sp in specs:
			sw += UiGlyphs.width_spec(sp, gh) + gh * 0.08
		rows.append({"a": a, "specs": specs, "sw": sw})
		row_w += sw + UiText.width(str(a["word"]), fs) + 14.0 * lay.s * sc
	var cr: Rect2 = caption_rect(lay, dir, float(d["y"]), eff, title_w, row_w)
	if _meets(cr, bodies):
		return
	var pad: float = 10.0 * lay.s * sc
	UiIcons.rrect(ci, cr, 8.0 * lay.s, Color(UiLook.col(UiLook.SCRIM), 0.92), Color(UiLook.col(UiLook.EDGE), 0.9), 2.0)   # a solid backing plate, so it reads on any sky
	UiText.draw(ci, title, Vector2(cr.position.x + pad, cr.position.y + pad + UiText.ascent(fs)), fs, Color(UiLook.col(UiLook.INK)), -1)
	var x: float = cr.position.x + pad
	var y: float = cr.position.y + pad + float(fs) * 1.3 + gh * 0.5
	for r in rows:
		var open: bool = bool(r["a"]["open"])
		var al: float = 1.0 if open else 0.45   # the dodge reads as not yet until its zone (a steady change, not a flash)
		var gx: float = x
		for sp in r["specs"]:
			gx += UiGlyphs.draw_spec(ci, sp, Vector2(gx, y), gh, al, true) + gh * 0.08
		UiText.draw(ci, str(r["a"]["word"]), Vector2(gx + 4.0 * lay.s, y - UiText.height(fs) * 0.5 + UiText.ascent(fs)), fs, Color(UiLook.col(UiLook.INK), al), -1)
		x += float(r["sw"]) + UiText.width(str(r["a"]["word"]), fs) + 14.0 * lay.s * sc
	# The bar: what is left of the window, with a notch where the dodge opens.
	if str(alert["phase"]) == "window":
		var bar := Rect2(cr.position.x + pad, cr.end.y - pad - 7.0 * lay.s * sc, cr.size.x - pad * 2.0, 7.0 * lay.s * sc)
		ci.draw_rect(bar, Color(1, 1, 1, 0.18))
		var left: float = 1.0 - run_frac(alert, reduced)
		ci.draw_rect(Rect2(bar.position, Vector2(bar.size.x * left, bar.size.y)), Color(UiLook.col(UiLook.INK)))
		var zone: float = clampf(float(alert["dodge_from"]) / 60.0 / maxf(float(alert["dur"]), 0.001), 0.0, 1.0)
		var nx: float = bar.position.x + bar.size.x * zone
		ci.draw_line(Vector2(nx, bar.position.y - 4.0 * lay.s), Vector2(nx, bar.end.y + 4.0 * lay.s), Color(UiLook.col(UiLook.EDGE)), 2.0)


static func _meets(r: Rect2, bodies: Array) -> bool:
	for b in bodies:
		if r.intersects(b):
			return true
	return false
