class_name UiHints
extends RefCounted
## On-screen control hints during play, and the YOU labels that say which fighter is the player's (friends could not tell). For each
## human fighter, a small legend in their column under the prompt row: the glyph of each action on their own device and one word
## ("[WASD] Fly", "[Space] Dash", ...). It shows for the first 12 seconds of every match (the last two fade), and all the time while
## prompts are on (training, the first matches) or the control_hints option is "always"; "off" hides it. A YOU pill with a small
## pointer rides over the human's fighter while the hints show, and the human's plate carries a YOU (or P1 and P2) tag. The rows are
## a scheme in ui/data/hints.json (option control_scheme, default "today"), so Controls' new layouts (ADR 0008) are data. Nothing
## here is drawn for an AI fighter, for the touch layout (its controls are on screen already) or in portrait.

static func data() -> Dictionary:
	return UiData.hints()


## The label for a fighter: YOU for the one human, P1 and P2 for two, "" for an AI (or when nobody plays).
static func you_label(models: Array, m: UiFighterModel) -> String:
	if m.ai:
		return ""
	var humans := 0
	for x in models:
		if not x.ai:
			humans += 1
	var d: Dictionary = data().get("you", {})
	if humans >= 2:
		var pair: Array = d.get("pair", ["P1", "P2"])
		return str(pair[clampi(m.slot, 0, pair.size() - 1)])
	return str(d.get("single", "YOU"))


## How strongly the hints show, 0 to 1: `mode` is the control_hints option (auto, always or off), `t` the match clock in seconds.
static func visible_alpha(m: UiFighterModel, mode: String, prompts_on: bool, t: float) -> float:
	if m.ai or mode == "off":
		return 0.0
	if mode == "always" or prompts_on:
		return 1.0
	var intro: float = float(data().get("intro_seconds", 12))
	if t < intro - 2.0:
		return 1.0
	return clampf((intro - t) / 2.0, 0.0, 1.0)


## How strongly the legend shows: the usual alpha, and full for 3 s after the held stance changes (the last half second fades), so the first time a
## stance button is held the answer to "what do these do now" is on the screen even after the 12 s are over; and for a moment after a press that did nothing
## (refused, energy, empty), so the mark on its button is seen. Not when the legend is off.
static func legend_alpha(m: UiFighterModel, mode: String, prompts_on: bool, t: float) -> float:
	var base: float = visible_alpha(m, mode, prompts_on, t)
	if m.ai or mode == "off":
		return base
	var pop: float = clampf((3.0 - m.stance_kind_t) / 0.5, 0.0, 1.0)
	if POP_ACKS.has(m.press_ack_kind):
		pop = maxf(pop, clampf((ACK_POP - m.press_ack_t) / 0.3, 0.0, 1.0))
	if m.charge_on or m.launcher_open:
		pop = 1.0   # a wind-up on Y or B, or the launch window on B: the legend is up while it lasts
	return maxf(base, pop)


## A press that did nothing: its mark lasts this long (a quick tick), and the legend is held up for ACK_POP when the press was refused, spent by the energy family or empty
## (a held press is the ordinary flow of a brawl and does not raise the legend).
const ACK_SECONDS := 0.5
const ACK_POP := 1.3
const POP_ACKS: Array = ["refused", "energy", "empty"]


## How far the wind-up has come, 0 to 1 (a quarter at a time under reduced motion), or -1 when none is running.
static func charge_frac(m: UiFighterModel, reduced: bool) -> float:
	if not m.charge_on or m.charge_dur <= 0.0:
		return -1.0
	var f: float = clampf(m.charge_t / m.charge_dur, 0.0, 1.0)
	return floorf(f * 4.0 + 0.001) / 4.0 if reduced else f


## A wind-up ring round a button's glyph: a faint full track and an arc that fills clockwise from the top; B's (the armoured heavy) has a second, thin outer ring, a shape and not a colour.
static func draw_charge(ci: CanvasItem, c: Vector2, r: float, frac: float, armoured: bool, alpha: float) -> void:
	if alpha <= 0.01 or frac < 0.0:
		return
	var ink := Color(UiLook.col(UiLook.INK))
	var w: float = maxf(2.5, r * 0.2)
	ci.draw_arc(c, r, 0.0, TAU, 28, Color(ink, 0.25 * alpha), w, true)
	if frac > 0.0:
		ci.draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * frac, 28, Color(ink, alpha), w, true)
	if armoured:
		ci.draw_arc(c, r * 1.3, 0.0, TAU, 32, Color(ink, 0.7 * alpha), maxf(1.5, w * 0.45), true)


## The launch window on B: a bright ring round the glyph with four short ticks (a shape, not only a colour).
static func draw_lit(ci: CanvasItem, c: Vector2, r: float, alpha: float) -> void:
	if alpha <= 0.01:
		return
	var warn := Color(UiLook.col(UiLook.WARN))
	var w: float = maxf(3.0, r * 0.28)
	ci.draw_arc(c, r * 1.1, 0.0, TAU, 28, Color(warn, alpha), w, true)
	for i in range(4):
		var d := Vector2.from_angle(float(i) * PI * 0.5 + PI * 0.25)
		ci.draw_line(c + d * r * 1.45, c + d * r * 1.85, Color(warn, alpha), maxf(2.0, w * 0.6), true)


## How strong the press mark is now, 0 to 1: a quick fade (Orb: cool answers, flash 4 of 10, subtle); under reduced motion a static mark for the same time.
static func ack_alpha(m: UiFighterModel, reduced: bool) -> float:
	if m.press_ack_kind == "" or m.press_ack_t >= ACK_SECONDS:
		return 0.0
	return 0.9 if reduced else 0.9 * (1.0 - m.press_ack_t / ACK_SECONDS)


## A small grey mark by the pressed button's glyph, by kind (a shape, not only a colour): a cross for a refused press or one the energy family spent, a dash for a cell
## with no move, a dot for a press kept for his line and a ring for one that lapsed.
static func draw_ack(ci: CanvasItem, kind: String, c: Vector2, size: float, alpha: float, col: Color = Color(UiLook.col(UiLook.INK_DIM))) -> void:
	if alpha <= 0.01:
		return
	var k := Color(col, alpha)
	var w: float = maxf(2.0, size * 0.18)
	ci.draw_circle(c, size * 0.95, Color(UiLook.col(UiLook.SCRIM), 0.8 * alpha))   # a small dark disc so the grey mark reads over a glyph or a button
	match kind:
		"refused", "energy":
			ci.draw_line(c + Vector2(-size, -size) * 0.5, c + Vector2(size, size) * 0.5, k, w, true)
			ci.draw_line(c + Vector2(-size, size) * 0.5, c + Vector2(size, -size) * 0.5, k, w, true)
		"empty":
			ci.draw_line(c + Vector2(-size * 0.6, 0.0), c + Vector2(size * 0.6, 0.0), k, w, true)
		"held":
			ci.draw_circle(c, size * 0.32, k)
		"lapsed":
			ci.draw_arc(c, size * 0.42, 0.0, TAU, 20, k, w, true)


## The layout id this fighter plays on: touch-simple on touch; on a keyboard kb-solo, or kb-shared-p1 and kb-shared-p2 when two humans
## share it; on a pad the pad_preset option (arena or simple-pad). `o["control_scheme"]` overrides it (a test, or a preview).
static func preset_id(m: UiFighterModel, o: Dictionary) -> String:
	var forced: String = str(o.get("control_scheme", ""))
	if forced != "":
		return forced
	var sp: Dictionary = o.get("slot_presets", {})
	if sp.has(m.slot):
		return str(sp[m.slot])   # the host named this player's layout (Controls' per-slot preset)
	if bool(o.get("touch", false)):
		return "touch-simple"
	if m.device == "" or m.device == "kbd":
		# The shared-keyboard halves only when both people are on the keyboard; one on the keyboard and one on a pad is the solo layout.
		if int(o.get("kbd_humans", o.get("humans", 1))) >= 2:
			return "kb-shared-p%d" % (clampi(m.slot, 0, 1) + 1)
		return "kb-solo"
	if m.slot == 1 and o.has("pad_preset_p2"):
		return str(o["pad_preset_p2"])
	return str(o.get("pad_preset", "arena"))


## The rows to show now, from the layout's scheme (falling back to "today"): an action or group and a word. A row for an action the
## layout does not bind is skipped, and a row marked only_when_avail appears only while the fighter can use that action.
## The Specials row (Power then the three specials) stays in a stance layout's legend until the charging stance is live (`UiStance.specials_row`): then the
## face rows name the specials while the power button is held (Game Design: the power layer and the charging stance are the same thing).
## The legend's face rows read by stance: the action of each face button, and the cell (x quick, y strong, a context, b signature) of the held stance.
const FACE_CELLS := {"light": "x", "heavy": "y", "context": "a", "signature": "b"}
## The four stance buttons: the action that holds each, and the stance it holds (UiStance kinds).
const HOLD_STANCES := {"guard": 1, "mode": 2, "power": 3, "dodge": 4}


## The legend's own word for an action in a layout's scheme (hints.json): what the button does today, for a stance that is not live.
static func old_label(scheme: String, action: String) -> String:
	var schemes: Dictionary = data().get("schemes", {})
	var sc: Dictionary = schemes.get(scheme, schemes.get("today", {}))
	for r in sc.get("rows", []):
		if r.has("action") and str(r["action"]) == action:
			return str(r.get("label", ""))
	return ""


## True for a layout with the stance buttons (it binds a mode and a power button): its legend reads by stance. Simple does not, and keeps its rows as written.
static func stance_layout(scheme: String, slot: int) -> bool:
	return UiGlyphs.bound(scheme, "mode", slot) and UiGlyphs.bound(scheme, "power", slot)


static func rows(m: UiFighterModel, scheme: String, energy: String = "hold") -> Array:
	var schemes: Dictionary = data().get("schemes", {})
	var sc: Dictionary = schemes.get(scheme, schemes.get("today", {}))
	var out: Array = []
	var by_stance: bool = stance_layout(scheme, m.slot)
	for r in sc.get("rows", []):
		var acts: Array = r["actions"] if r.has("actions") else [r.get("action", "")]
		if not UiGlyphs.bound(scheme, str(acts[0]), m.slot):
			continue
		if bool(r.get("only_when_avail", false)):
			var a: String = str(r.get("action", ""))
			if not (m.avail.has(a) and bool(m.avail[a])):
				continue
			if a == "transform" and m.form_shown:
				continue   # the form-ready chip above the legend already says it
		var label: String = str(r.get("label", ""))
		var held := false
		var dim := false
		var row_cell := ""
		var aid: String = str(acts[0])
		if r.has("action") and FACE_CELLS.has(aid):
			row_cell = str(FACE_CELLS[aid])
		if by_stance and r.has("action") and FACE_CELLS.has(aid):
			var cell: String = UiStance.cell(m.stance_kind, str(FACE_CELLS[aid]))
			if cell != "" and UiStance.live(m.stance_kind):
				label = cell   # what this face button does in the stance held now (only for a stance whose names are true on the live build)
			dim = not UiStance.cell_works(m.stance_kind, str(FACE_CELLS[aid]))   # a button with no move in the stance held now reads as not yet, greyed
			if UiStance.three() and not UiStance.live(m.stance_kind):
				# The three strengths: the action ids are the same, the words are Light, Medium, Heavy (and under the power button, the signature held with B).
				var tw: String = UiStance.three_word(aid)
				if tw != "":
					label = tw
				if m.stance_kind == UiStance.CHARGING and aid == "signature":
					label = UiData.t("prompt.three_sig_chord")
		elif UiStance.three() and r.has("action") and aid == "light":
			label = UiData.t("prompt.three_attack")   # Simple: one button, light or medium by how long it is held
		elif by_stance and r.has("action") and HOLD_STANCES.has(aid):
			var kind: int = int(HOLD_STANCES[aid])
			if UiStance.live(kind):
				label = UiStance.legend(kind, kind == UiStance.ENERGY and energy == "toggle")   # Defensive (hold), Energy (hold or toggle), ...
			elif kind == UiStance.ENERGY:
				label = UiData.t("prompt.mode_toggle" if energy == "toggle" else "prompt.mode_hold")
			held = m.stance_kind == kind
		elif aid == "mode":
			label = UiData.t("prompt.mode_toggle" if energy == "toggle" else "prompt.mode_hold")
		if by_stance and r.has("actions"):
			if not UiStance.specials_row():
				continue
			dim = true   # the Specials row stays until the charging stance is live, and its moves do not exist yet
		var row_note: String = UiData.t("prompt.not_yet") if dim else ""
		if UiStance.three() and m.launcher_known and aid == "signature" and by_stance and m.stance_kind != UiStance.CHARGING and not dim:
			row_note = UiData.t("state.launcher_note_ready" if m.launcher_ready else "state.launcher_note_rest")   # the heavy row says whether a launch is ready (steady words, no countdown)
		out.append({"acts": acts, "label": label, "held": held, "dim": dim, "note": row_note, "cell": row_cell})
	if UiStance.three():
		if by_stance and m.stance_kind != UiStance.CHARGING:
			# The signature is on the power button held with B: a chord row after the heavy row.
			var at: int = out.size()
			for i in range(out.size()):
				if str((out[i]["acts"] as Array)[0]) == "signature":
					at = i + 1
					break
			out.insert(at, {"acts": ["power", "signature"], "label": UiData.t("prompt.three_sig_chord"), "held": false, "dim": false, "note": "", "cell": ""})
		elif not by_stance and UiGlyphs.bound(scheme, "heavy", m.slot):
			var has_heavy := false
			var li := -1
			for i in range(out.size()):
				if str((out[i]["acts"] as Array)[0]) == "heavy":
					has_heavy = true
				if str((out[i]["acts"] as Array)[0]) == "light":
					li = i
			if not has_heavy and li >= 0:
				out.insert(li + 1, {"acts": ["heavy"], "label": UiData.t("prompt.three_heavy"), "held": false, "dim": false, "note": "", "cell": "y"})   # Simple: Y is labelled Heavy
	return out


## The player's own energy style ("hold" or "toggle"): player one's option, or player two's.
static func energy_style(m: UiFighterModel, o: Dictionary) -> String:
	return str(o.get("energy_style_p2" if m.slot == 1 else "energy_style", "hold"))


## The glyph specs of one row, flat: each action's binding in the layout, a power group (Power then its face buttons) joined by a plus.
static func row_specs(m: UiFighterModel, acts: Array, preset: String, style: String) -> Array:
	var fam: String = m.device if m.device != "" else "kbd"
	return UiGlyphs.group_specs(acts, fam, m.slot, style, preset)


static func _row_width(specs: Array, gh: float, gap: float) -> float:
	var w := 0.0
	for sp in specs:
		w += UiGlyphs.width_spec(sp, gh) + gap * 0.4
	return w


## The layout of the legend in `rect`: as many rows as fit, in order. Returns {rows: [{specs, label, y}], label_x, gh, fs, row_h, box}.
static func plan(m: UiFighterModel, rect: Rect2, s: float, o: Dictionary) -> Dictionary:
	var out := {"rows": [], "label_x": 0.0, "gh": 0.0, "fs": 0, "row_h": 0.0, "box": Rect2()}
	if rect.size.y <= 0.0 or rect.size.x <= 0.0:
		return out
	var preset: String = preset_id(m, o)
	var style: String = str(o.get("glyph_style", "neutral"))
	var fs: int = UiText.px(18.0, s)
	var gh: float = maxf(24.0 * s, 20.0)
	var row_h: float = maxf(gh, float(fs) * 1.4) + 4.0 * s
	var pad: float = maxf(8.0 * s, 5.0)
	var cap: int = int(floor((rect.size.y - pad * 2.0) / row_h))
	var all: Array = rows(m, preset, energy_style(m, o))
	var shown: Array = all.slice(0, maxi(cap, 0))
	if shown.is_empty():
		return out
	var gap: float = maxf(8.0 * s, 5.0)
	var maxw: float = 0.0
	var full: Array = []
	for r in shown:
		var specs: Array = row_specs(m, r["acts"], preset, style)
		full.append(specs)
		maxw = maxf(maxw, _row_width(specs, gh, gap))
	# A row too wide for the column (a long chord) would crowd the words: cap the glyph block at 60% of the column.
	maxw = minf(maxw, rect.size.x * 0.6)
	var y: float = rect.position.y + pad
	var placed: Array = []
	for i in range(shown.size()):
		placed.append({"specs": full[i], "label": shown[i]["label"], "held": bool(shown[i].get("held", false)), "dim": bool(shown[i].get("dim", false)), "note": str(shown[i].get("note", "")), "cell": str(shown[i].get("cell", "")), "y": y + row_h * 0.5})
		y += row_h
	out["rows"] = placed
	out["label_x"] = rect.position.x + pad + maxw + gap
	out["gh"] = gh
	out["fs"] = fs
	out["row_h"] = row_h
	out["gap"] = gap
	out["pad"] = pad
	out["preset"] = preset
	out["box"] = Rect2(rect.position, Vector2(minf(rect.size.x, (out["label_x"] as float) - rect.position.x + _widest_label(placed, fs) + pad), float(placed.size()) * row_h + pad * 2.0))
	return out


static func _widest_label(placed: Array, fs: int) -> float:
	var w := 0.0
	for r in placed:
		var text: String = str(r["label"]) + (("  " + str(r["note"])) if str(r.get("note", "")) != "" else "")
		w = maxf(w, UiText.width(text, fs))
	return w


static func sig(m: UiFighterModel, alpha: float, preset: String, energy: String = "hold", reduced: bool = false) -> Array:
	var ack_step: int = 0 if m.press_ack_kind == "" or m.press_ack_t >= ACK_SECONDS else (1 if reduced else 1 + int(m.press_ack_t / ACK_SECONDS * 6.0))
	var cf: float = charge_frac(m, reduced)
	return [m.device, m.slot, int(alpha * 10.0), preset, m.avail["transform"], m.left_side, m.form_shown, energy, m.stance_kind, m.press_ack_kind, m.press_ack_cell, ack_step,
		int(cf * 8.0) if cf >= 0.0 else -1, m.charge_cell if m.charge_on else "", m.launcher_open, UiStance.three()]


static func draw(ci: CanvasItem, m: UiFighterModel, rect: Rect2, s: float, o: Dictionary, alpha: float) -> void:
	var p: Dictionary = plan(m, rect, s, o)
	if p["rows"].is_empty() or alpha <= 0.01:
		return
	var style: String = str(o.get("glyph_style", "neutral"))
	var gh: float = p["gh"]
	var fs: int = p["fs"]
	var gap: float = p["gap"]
	var left: bool = m.left_side
	var box: Rect2 = p["box"]
	var ack_a: float = ack_alpha(m, bool(o.get("reduced_motion", false)))
	UiText.no_outline = true
	var bx: float = box.position.x if left else rect.end.x - box.size.x
	var shift: float = bx - box.position.x
	UiIcons.rrect(ci, Rect2(bx, box.position.y, box.size.x, box.size.y), 8.0 * s, Color(UiLook.col(UiLook.SCRIM), 0.5 * alpha), Color(UiLook.col(UiLook.EDGE), 0.25 * alpha), 1.2)
	for r in p["rows"]:
		var x: float = rect.position.x + float(p["pad"]) + shift
		if bool(r.get("held", false)):
			# The stance held now: a bar on the box's edge by its row (a shape, not a colour).
			var hb: float = float(p["row_h"]) * 0.7
			ci.draw_rect(Rect2(bx + 1.0, float(r["y"]) - hb * 0.5, maxf(3.0, 3.0 * s), hb), Color(UiLook.col(UiLook.INK), alpha))
		for sp in r["specs"]:
			var w: float = UiGlyphs.draw_spec(ci, sp, Vector2(x, float(r["y"])), gh, alpha, true)
			x += w + gap * 0.4
		var dim_row: bool = bool(r.get("dim", false))
		var ra: float = alpha * (0.45 if dim_row else 1.0)   # a row for a button with no move yet is greyed
		var lx: float = float(p["label_x"]) + shift
		var ly: float = float(r["y"]) - UiText.height(fs) * 0.5 + UiText.ascent(fs)
		var lw: float = UiText.draw(ci, str(r["label"]), Vector2(lx, ly), fs, Color(UiLook.col(UiLook.INK), ra), -1)
		if str(r.get("note", "")) != "":
			UiText.draw(ci, str(r["note"]), Vector2(lx + lw + gap, ly), fs, Color(UiLook.col(UiLook.INK_DIM), maxf(ra, 0.5 * alpha)), -1)
		# The press that did nothing: a short grey mark on this button's glyph.
		if ack_a > 0.0 and str(r.get("cell", "")) == m.press_ack_cell and m.press_ack_kind != "":
			var gx: float = rect.position.x + float(p["pad"]) + shift
			draw_ack(ci, m.press_ack_kind, Vector2(gx + gh * 0.5, float(r["y"])), gh * 0.5, ack_a * alpha)
		if str(r.get("cell", "")) != "":
			var gc := Vector2(rect.position.x + float(p["pad"]) + shift + gh * 0.5, float(r["y"]))
			if m.charge_on and str(r["cell"]) == m.charge_cell:
				draw_charge(ci, gc, gh * 0.62, charge_frac(m, bool(o.get("reduced_motion", false))), m.charge_cell == "b", alpha)
			if m.launcher_open and str(r["cell"]) == "b":
				draw_lit(ci, gc, gh * 0.52, alpha)
	UiText.no_outline = false


## The YOU marker over a fighter: a small pill with the label and a pointer toward the head, kept inside `safe`.
static func draw_you(ci: CanvasItem, label: String, anchor: Dictionary, s: float, alpha: float, safe: Rect2) -> void:
	if label == "" or anchor.is_empty() or not bool(anchor.get("visible", true)) or alpha <= 0.01:
		return
	var c: Vector2 = anchor["pos"]
	var R: float = UiCrown.radius(float(anchor.get("h", 90.0)), s)
	var fs: int = UiText.px(22.0, s)
	var tw: float = UiText.width(label, fs)
	var pw: float = tw + 22.0 * s
	var ph: float = float(fs) + 10.0 * s
	var cx: float = clampf(c.x, safe.position.x + pw * 0.5, safe.end.x - pw * 0.5)
	var top: float = clampf(c.y - R * 1.3 - ph - 22.0 * s, safe.position.y, safe.end.y - ph - 12.0 * s)
	var r := Rect2(cx - pw * 0.5, top, pw, ph)
	UiText.no_outline = true
	UiIcons.rrect(ci, r, ph * 0.5, Color(UiLook.col(UiLook.INK), 0.92 * alpha), Color(UiLook.col(UiLook.INK_DARK), 0.7 * alpha), 1.5)
	UiText.draw(ci, label, Vector2(r.get_center().x, r.get_center().y - UiText.height(fs) * 0.5 + UiText.ascent(fs)), fs, Color(UiLook.col(UiLook.INK_DARK), alpha), 0)
	# The pointer: a small triangle under the pill, toward the head.
	var tip := Vector2(clampf(c.x, r.position.x + ph * 0.5, r.end.x - ph * 0.5), r.end.y + 12.0 * s)
	UiIcons.fill_poly(ci, PackedVector2Array([tip, tip + Vector2(-8.0 * s, -12.0 * s), tip + Vector2(8.0 * s, -12.0 * s)]), Color(UiLook.col(UiLook.INK), 0.92 * alpha))
	UiText.no_outline = false
