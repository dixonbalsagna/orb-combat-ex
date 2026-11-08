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
	if UiData.feature("legend_clear"):
		return 1.0 if t < intro else 0.0   # Orb's rule against fades: the legend is up for the intro and then it is not (a clean cut)
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
	if UiData.feature("legend_clear"):
		pop = 1.0 if m.stance_kind_t < 3.0 or (POP_ACKS.has(m.press_ack_kind) and m.press_ack_t < ACK_POP) else 0.0   # the same pops, cut rather than faded
	if UiData.feature("legend_beam"):
		var stance_pop: float = 1.0 if (m.stance_kind != 0 or m.stance_kind_t < 0.5) else 0.0   # up for as long as a stance button is held, and 0.5 s after it is let go (a cut)
		var ack_pop: float = 1.0 if (POP_ACKS.has(m.press_ack_kind) and m.press_ack_t < ACK_POP) else 0.0
		pop = maxf(stance_pop, ack_pop)
	if UiData.feature("beam_teach") and m.teach_left > 0.0:
		pop = 1.0   # a line is teaching: the panel is up for it
	if not m.beat_rows.is_empty():
		pop = 1.0   # one of the first beam struggles: the panel says what to press on the beat
	if m.charge_on or lit_b(m) or (UiStance.three() and m.punish_left > 0.0):
		pop = 1.0   # a wind-up on Y or B, or the launch window on B: the legend is up while it lasts
	return maxf(base, pop)


## A press that did nothing: its mark lasts this long (a quick tick), and the legend is held up for ACK_POP when the press was refused, spent by the energy family or empty
## (a held press is the ordinary flow of a brawl and does not raise the legend).
const ACK_SECONDS := 0.5
const ACK_POP := 1.3
const BEAT_TICKS := 6   # the beat ring has six short ticks round it: a shape of its own (the launcher's lit ring has four, the open window's three), so it reads without its colour
const POP_ACKS: Array = ["refused", "energy", "empty", "stunned"]


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
	if frac >= 0.999:
		ci.draw_line(c + Vector2(0.0, -r * 1.12), c + Vector2(0.0, -r * 1.7), Color(ink, alpha), maxf(2.0, w * 0.8), true)   # full: a steady notch at the top of the ring (a shape; Legal's RL-239: no flash)


## The launch window on B: a bright ring round the glyph with four short ticks (a shape, not only a colour).
## A ring of ten dots round X's glyph, one lit per flurry blow: the burst lights them fast, the pace one at a time (a shape, a count of lit dots).
static func draw_dots(ci: CanvasItem, c: Vector2, r: float, lit: int, alpha: float) -> void:
	if alpha <= 0.01 or lit <= 0:
		return
	var ink := Color(UiLook.col(UiLook.INK))
	var dr: float = maxf(1.8, r * 0.13)
	for i in range(10):
		var a: float = -PI * 0.5 + float(i) * TAU / 10.0
		var p: Vector2 = c + Vector2.from_angle(a) * r * 1.4
		if i < lit:
			ci.draw_circle(p, dr, Color(ink, alpha))
		else:
			ci.draw_arc(p, dr, 0.0, TAU, 10, Color(ink, alpha * 0.7), maxf(1.2, dr * 0.45), true)


## The charge stage on the strike stick's glyph: a small digit in a dark disc at the glyph's top corner, changed by a cut at each stage and never animated; at the top stage the disc is solid with a ring round it
## (a shape, not only a colour; RL-239: nothing flashes). In the legend, at the screen's edge; never over a body.
static func draw_stage(ci: CanvasItem, c: Vector2, gh: float, k: int, n: int, fs: int, alpha: float) -> void:
	if alpha <= 0.01 or k <= 0:
		return
	var r: float = maxf(gh * 0.3, 7.0)
	var at: Vector2 = c + Vector2(gh * 0.42, -gh * 0.42)
	var ink := Color(UiLook.col(UiLook.INK))
	var dark := Color(UiLook.col(UiLook.INK_DARK))
	var top: bool = k >= n
	ci.draw_circle(at, r + 1.5, Color(dark, 0.9 * alpha))
	if top:
		ci.draw_circle(at, r, Color(ink, alpha))
		ci.draw_arc(at, r + 3.0, 0.0, TAU, 20, Color(ink, alpha), 1.5, true)
	var fsd: int = maxi(int(float(fs) * 0.8), 9)
	UiText.draw(ci, str(k), Vector2(at.x, at.y - UiText.height(fsd) * 0.5 + UiText.ascent(fsd)), fsd, Color(dark if top else ink, alpha), 0)


## The clash teaching's ring on a legend glyph at the beat (RL-248): a ring with six ticks, in its own colour (UiLook.BEAT), inside the legend and nowhere else.
static func draw_beat(ci: CanvasItem, c: Vector2, r: float, alpha: float) -> void:
	if alpha <= 0.01:
		return
	var col := Color(UiLook.col(UiLook.BEAT))
	var w: float = maxf(3.0, r * 0.28)
	ci.draw_arc(c, r * 1.1, 0.0, TAU, 28, Color(col, alpha), w, true)
	for i in range(BEAT_TICKS):
		var d := Vector2.from_angle(float(i) * TAU / float(BEAT_TICKS) - PI * 0.5)
		ci.draw_line(c + d * r * 1.45, c + d * r * 1.85, Color(col, alpha), maxf(2.0, w * 0.6), true)


static func draw_lit(ci: CanvasItem, c: Vector2, r: float, alpha: float, ticks: int = 4) -> void:
	if alpha <= 0.01:
		return
	var warn := Color(UiLook.col(UiLook.WARN))
	var w: float = maxf(3.0, r * 0.28)
	ci.draw_arc(c, r * 1.1, 0.0, TAU, 28, Color(warn, alpha), w, true)
	for i in range(ticks):
		var d := Vector2.from_angle(float(i) * TAU / float(ticks) + (PI * 0.25 if ticks == 4 else -PI * 0.5))
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
		"refused", "energy", "stunned":
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


## Whether a legend row or a How to play line is for a press that works in this build (Game Design, docs/design/pad-first-press.md: a button that cannot pass leaves the hints). The Transform
## row waits for `forms_live`, the Specials row for `specials_live` and the Brace for `brace_live` (features.json): each is switched on by whoever makes that press real.
static func press_live(acts: Array) -> bool:
	var first: String = str(acts[0]) if not acts.is_empty() else ""
	if acts.has("transform") and not UiData.feature("forms_live"):
		return false
	if (acts.has("special1") or first == "specials") and not UiData.feature("specials_live"):
		return false
	if first == "brace_key" and not UiData.feature("brace_live"):
		return false
	return true


## The rows to show now, from the layout's scheme (falling back to "today"): an action or group and a word. A row for an action the
## layout does not bind is skipped, and a row marked only_when_avail appears only while the fighter can use that action.
## The Specials row (Power then the three specials) stays in a stance layout's legend until the charging stance is live (`UiStance.specials_row`): then the
## face rows name the specials while the power button is held (Game Design: the power layer and the charging stance are the same thing).
## The legend's face rows read by stance: the action of each face button, and the cell (x quick, y strong, a context, b signature) of the held stance.
const FACE_CELLS := {"light": "x", "heavy": "y", "context": "a", "signature": "b"}
## The four stance buttons: the action that holds each, and the stance it holds (UiStance kinds).
const HOLD_STANCES := {"guard": 1, "mode": 2, "power": 3, "dodge": 4}


## The scheme (the rows) of a layout id. A swapped layout (`arena-swapped`) reads its standard layout's rows: the actions are the same, the glyphs are its own. Else "today".
static func scheme_of(scheme: String) -> Dictionary:
	var schemes: Dictionary = data().get("schemes", {})
	if not schemes.has(scheme) and scheme.ends_with("-swapped"):
		scheme = scheme.trim_suffix("-swapped")
	return schemes.get(scheme, schemes.get("today", {}))


## The legend's own word for an action in a layout's scheme (hints.json): what the button does today, for a stance that is not live.
static func old_label(scheme: String, action: String) -> String:
	var sc: Dictionary = scheme_of(scheme)
	for r in sc.get("rows", []):
		if r.has("action") and str(r["action"]) == action:
			return str(r.get("label", ""))
	return ""


## True for a layout with the stance buttons (it binds a mode and a power button): its legend reads by stance. Simple does not, and keeps its rows as written.
static func stance_layout(scheme: String, slot: int) -> bool:
	return UiGlyphs.bound(scheme, "mode", slot) and UiGlyphs.bound(scheme, "power", slot)


## Under minimal_hud the legend is the full list only at the start of the first match, on pause and with Control hints always; otherwise only the rows that matter now: the held stance,
## the lit B, a charge running, a press that did nothing, the medium that stops him, the dots of a flurry.
static func compact_rows(m: UiFighterModel, all_rows: Array) -> Array:
	var out: Array = []
	for r in all_rows:
		var cell: String = str(r.get("cell", ""))
		var keep: bool = bool(r.get("held", false))
		if cell != "":
			keep = keep or (lit_b(m) and cell == "b") or (m.charge_on and cell == m.charge_cell) or (m.press_ack_kind != "" and m.press_ack_t < ACK_POP and cell == m.press_ack_cell) \
				or (UiStance.three() and m.punish_left > 0.0 and cell == "y") or (UiStance.three() and m.flurry_dots > 0 and cell == "x")
		if not keep and m.cstage > 0 and ["strike", "strike_mirror"].has(_act0(r)) and not bool(r.get("teach", false)):
			keep = true   # a stick charge is at a stage: the strike stick's rows stay, with the digit on the glyph
		if bool(r.get("teach", false)):
			keep = true   # a teaching line (a refusal word, a beam line, the clash rows) is the legend's reason to be up for its moment: the compact legend drops the buttons that do not matter, never the line that is being said (the refusal words were cut here from the second match, and after the opening 12 s, on every build with minimal_hud)
		if keep:
			out.append(r)
	return out


## The hold-or-toggle options (Controls' hold_style, and energy_style) by the action they set; player two's carry `_p2`. UI reads them as the player chose them and never writes them.
const RIGHT_HAND_ACTIONS := ["strike", "strike_mirror", "strike_key", "brace_key"]   # rows and lines that exist only while Controls' right-hand attacks are on
const STYLE_OPTION := {"guard": "guard_style", "dodge": "manoeuvre_style", "power": "charge_style", "transform": "transform_style", "mode": "energy_style"}


## One player's style for each action: {"guard": "hold" or "toggle", ...}, from the options `o`.
static func styles(m: UiFighterModel, o: Dictionary) -> Dictionary:
	var out := {}
	for a in STYLE_OPTION:
		out[a] = str(o.get(str(STYLE_OPTION[a]) + ("_p2" if m.slot == 1 else ""), "hold"))
	if UiData.feature("right_hand"):   # the right-hand attacks' styles, read only while Controls' switch is on: strike style, and whether this player strikes with the D-pad (dpad_mirror, or a pad with no second stick)
		var sfx: String = "_p2" if m.slot == 1 else ""
		out["strike"] = str(o.get("strike_style" + sfx, "hold"))
		var mir: String = str(o.get("dpad_mirror" + sfx, "auto"))
		var on_pad: bool = m.device != "" and m.device != "kbd"   # the D-pad mirror is for a controller
		out["_mirror"] = "on" if on_pad and (mir == "on" or (mir == "auto" and not bool(o.get("pad_right_stick" + sfx, true)))) else "off"
	return out


static func rows(m: UiFighterModel, scheme: String, energy: String = "hold", styles: Dictionary = {}) -> Array:
	var sc: Dictionary = scheme_of(scheme)
	var out: Array = []
	var by_stance: bool = stance_layout(scheme, m.slot)
	var mirror_on: bool = str(styles.get("_mirror", "off")) == "on"
	for r in sc.get("rows", []):
		var acts: Array = r["actions"] if r.has("actions") else [r.get("action", "")]
		if RIGHT_HAND_ACTIONS.has(str(acts[0])) and not UiData.feature("right_hand"):
			continue
		if not press_live(acts):
			continue
		if not UiGlyphs.bound(scheme, str(acts[0]), m.slot):
			continue
		if (str(acts[0]) == "strike_mirror" and not mirror_on) or (str(acts[0]) == "strike" and mirror_on and UiGlyphs.bound(scheme, "strike_mirror", m.slot)):
			continue   # the D-pad's strike row only while the D-pad strikes, the stick's only while the stick does
		if bool(r.get("only_when_avail", false)):
			var a: String = str(r.get("action", ""))
			if not (m.avail.has(a) and bool(m.avail[a])):
				continue
			if a == "transform" and m.form_shown:
				continue   # the form-ready chip above the legend already says it
		var label: String = str(r.get("label", ""))
		if r.has("label_toggle") and r.has("action") and str(styles.get("strike" if str(r["action"]).begins_with("strike") else str(r["action"]), "hold")) == "toggle":
			label = str(r["label_toggle"])   # this player's guard, power or manoeuvre is a toggle: the word says so
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
				label = UiStance.legend(kind, (energy == "toggle") if kind == UiStance.ENERGY else str(styles.get(aid, "hold")) == "toggle")   # Defensive (hold), Energy (hold or toggle), ...
			elif kind == UiStance.ENERGY:
				label = UiData.t("prompt.mode_toggle" if energy == "toggle" else "prompt.mode_hold")
			held = m.stance_kind == kind
		elif aid == "mode":
			label = UiData.t("prompt.mode_toggle" if energy == "toggle" else "prompt.mode_hold")
		if by_stance and r.has("actions"):
			if not UiStance.specials_row():
				continue
			dim = true   # the Specials row stays until the charging stance is live, and its moves do not exist yet
		if dim and UiData.feature("legend_quiet"):
			continue   # a press that does nothing is not listed (no "not yet" rows)
		var row_note: String = UiData.t("prompt.not_yet") if dim else ""
		if UiStance.launch_marks() and m.launcher_known and row_cell == "b" and by_stance and m.stance_kind != UiStance.CHARGING and not dim:
			if m.launcher_ready:
				row_note = UiData.t("state.launcher_note_ready")   # the heavy row says a launch is ready (steady words, no countdown)
			elif not UiData.feature("quiet_hints"):
				row_note = UiData.t("state.launcher_note_rest")   # quiet_hints: "recharging" is nothing a player can act on, so the row does not say it
		if UiStance.launch_marks() and m.gauge_full and row_cell == "b" and not dim:
			row_note = UiData.t("state.launcher_ready")   # the word LAUNCH beside the lit B
		if UiData.feature("legend_beam") and (str(acts[0]) == "strike" or str(acts[0]) == "strike_mirror") and by_stance:
			# The strike stick's layer: with Energy held the stick fires the beam (held out to charge) and a flick is a blast; with Power held it is inert and has no row.
			if m.stance_kind == UiStance.CHARGING:
				continue
			if m.stance_kind == UiStance.ENERGY:
				var toggle_beam: bool = str(styles.get("strike", "hold")) == "toggle"
				var beam_line: String = UiData.t("prompt.legend_beam_toggle") if toggle_beam else (UiData.t("prompt.teach_beam") if (UiData.feature("beam_teach") and m.device != "" and m.device != "kbd") else (UiData.t("prompt.teach_beam_keys") if UiData.feature("beam_teach") else UiData.t("prompt.legend_beam")))   # Game Design's words (power-scale.md section 5), for a controller or for keys
				out.append({"acts": acts, "label": beam_line, "held": false, "dim": false, "note": "", "cell": "", "wrap": true})
				out.append({"acts": acts, "label": UiData.t("prompt.legend_blast"), "held": false, "dim": false, "note": "", "cell": ""})
				continue
		out.append({"acts": acts, "label": label, "held": held, "dim": dim, "note": row_note, "cell": row_cell})
	if UiData.feature("beam_teach") and m.teach != "" and not (m.stance_kind == UiStance.ENERGY and m.teach == UiData.t("prompt.teach_beam")):
		out.append({"acts": m.teach_acts, "label": m.teach, "held": false, "dim": false, "note": "", "cell": "", "teach": true})   # the teaching line, in its own row with the glyphs of the buttons it names
	for br in m.beat_rows:
		out.append({"acts": br["acts"], "label": br["label"], "held": false, "dim": false, "note": "", "cell": "", "teach": true, "beat": true})   # struggle_teach: what to press on the beat (its glyphs are ringed at each beat)
	if UiStance.three():
		if by_stance and m.stance_kind != UiStance.CHARGING:
			# The signature is on the power button held with B: a chord row after the heavy row.
			var at: int = out.size()
			for i in range(out.size()):
				if _act0(out[i]) == "signature":
					at = i + 1
					break
			out.insert(at, {"acts": ["power", "signature"], "label": UiData.t("prompt.three_sig_chord"), "held": false, "dim": false, "note": "", "cell": ""})
		elif not by_stance and UiGlyphs.bound(scheme, "heavy", m.slot):
			var has_heavy := false
			var li := -1
			for i in range(out.size()):
				if _act0(out[i]) == "heavy":
					has_heavy = true
				if _act0(out[i]) == "light":
					li = i
			if not has_heavy and li >= 0:
				out.insert(li + 1, {"acts": ["heavy"], "label": UiData.t("prompt.three_heavy"), "held": false, "dim": false, "note": "", "cell": "y"})   # Simple: Y is labelled Heavy
	return out


## A row's first action ("" for a line of words with no buttons, like the You're out line).
static func _act0(r: Dictionary) -> String:
	var a: Array = r["acts"]
	return str(a[0]) if not a.is_empty() else ""


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


## A teaching line (beam_teach) is a sentence, longer than a column: it wraps to the column's width, its glyphs on the first line and the words of the next lines under the first's. A line that
## teaches for a moment with nothing held leaves only itself and Guard's row; held, it goes first; the beam row (held Energy) wraps where it stands. The other rows keep their order.
static func _wrap_teach(m: UiFighterModel, all: Array, avail: float, fs: int, gh: float, gap: float, preset: String, style: String) -> Array:
	var first: Array = []
	var rest: Array = []
	if m.stance_kind == 0:
		var only: Array = all.filter(func(r): return bool(r.get("teach", false)) or ((r["acts"] as Array).has("guard") and not m.out))   # a fighter who is out has no guard to find: only the line
		if only.any(func(r): return bool(r.get("teach", false))):
			all = only   # nothing is held and a line teaches: the legend is that line and Guard's row for its moment (a player being hit must still see where guard is), the other rows hidden
	var block := 0.0   # the glyph block is as wide as the widest row's (plan() aligns every label after it, at most 60% of the column)
	for r in all:
		block = maxf(block, _row_width(row_specs(m, r["acts"], preset, style), gh, gap))
	block = minf(block, avail * 0.6)
	for r in all:
		var teach: bool = bool(r.get("teach", false))
		if not teach and not bool(r.get("wrap", false)):
			rest.append(r)
			continue
		var into: Array = first if teach else rest
		var lines: PackedStringArray = UiText.wrap(str(r["label"]), fs, maxf(avail - block - gap, 40.0))
		if lines.size() <= 1:
			into.append(r)
			continue
		for i in range(lines.size()):
			var rr: Dictionary = (r as Dictionary).duplicate()
			rr["label"] = lines[i]
			if i > 0:
				rr["acts"] = []
			into.append(rr)
	return first + rest


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
	var all: Array = rows(m, preset, energy_style(m, o), styles(m, o))
	if bool(o.get("legend_compact", false)):
		all = compact_rows(m, all)
	all = _wrap_teach(m, all, rect.size.x - pad * 2.0, fs, gh, maxf(8.0 * s, 5.0), preset, style)
	# A larger Text size steps the words down, never below what Normal draws, until the legend's rows all fit its column, so a bigger setting hides as few controls as it can (Normal is as it was).
	var fs_normal: int = maxi(int(round(18.0 * s)), int(UiLook.text_floor))
	while UiText.size_mult > 1.0 and cap < all.size() and fs > fs_normal:
		fs -= 1
		row_h = maxf(gh, float(fs) * 1.4) + 4.0 * s
		cap = int(floor((rect.size.y - pad * 2.0) / row_h))
	# A teaching sentence is never cut: its wrapped lines (and Guard's row, kept beside it) are all shown even when the column is short, so the box grows down past the rect for its moment.
	var must := 0
	for r in all:
		if bool(r.get("teach", false)):
			must += 1
	if must > 0:
		for r in all:
			if (r["acts"] as Array).has("guard"):
				must += 1
		cap = maxi(cap, must)
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
		placed.append({"specs": full[i], "label": shown[i]["label"], "held": bool(shown[i].get("held", false)), "dim": bool(shown[i].get("dim", false)), "note": str(shown[i].get("note", "")), "cell": str(shown[i].get("cell", "")), "beat": bool(shown[i].get("beat", false)), "stick": ["strike", "strike_mirror"].has(_act0(shown[i])) and not bool(shown[i].get("teach", false)), "y": y + row_h * 0.5})
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


## B is lit: the launch window is open (the `launcher_open` cue), or the rival's gauge is full and the launcher is ready, so the next opening can be launched (the launch marks).
static func lit_b(m: UiFighterModel) -> bool:
	return m.launcher_open or (UiStance.launch_marks() and m.gauge_full)


static func sig(m: UiFighterModel, alpha: float, preset: String, energy: String = "hold", reduced: bool = false, compact: bool = false, styles: Dictionary = {}) -> Array:
	var ack_step: int = 0 if m.press_ack_kind == "" or m.press_ack_t >= ACK_SECONDS else (1 if reduced else 1 + int(m.press_ack_t / ACK_SECONDS * 6.0))
	var cf: float = charge_frac(m, reduced)
	return [m.teach, m.teach_acts.size(), m.beat_rows.size(), int(m.beat_ring * 10.0), m.out, m.cstage, m.device, m.slot, int(alpha * 10.0), preset, m.avail["transform"], m.left_side, m.form_shown, energy, m.stance_kind, m.press_ack_kind, m.press_ack_cell, ack_step,
		int(cf * 8.0) if cf >= 0.0 else -1, m.charge_cell if m.charge_on else "", lit_b(m), UiStance.three(), m.punish_left > 0.0, m.flurry_dots, UiStance.launch_marks() and m.gauge_full, compact, str(styles.get("guard", "hold")) + str(styles.get("dodge", "hold")) + str(styles.get("power", "hold")) + str(styles.get("strike", "")) + str(styles.get("_mirror", ""))]


## Where the legend's box is on the screen when it is drawn in `rect` (empty when it draws nothing): the box of the plan, on its own side of the rect.
static func screen_box(m: UiFighterModel, rect: Rect2, s: float, o: Dictionary) -> Rect2:
	var p: Dictionary = plan(m, rect, s, o)
	if (p["rows"] as Array).is_empty():
		return Rect2()
	var box: Rect2 = p["box"]
	var bx: float = box.position.x if m.left_side else rect.end.x - box.size.x
	return Rect2(bx, box.position.y, box.size.x, box.size.y)


## A fighter's torso on the screen (an anchor's drawn height by about one wide, as UiSplit.chips_off_bodies reads it), or an empty rect when the anchor says nothing usable.
static func body_box(an: Dictionary, vp: Vector2) -> Rect2:
	if an.is_empty() or not an.has("pos"):
		return Rect2()
	var q: Vector2 = an["pos"]
	var h: float = float(an.get("h", 0.0))
	if q == Vector2.ZERO or h <= 0.0 or not Rect2(Vector2.ZERO, vp).grow(h).has_point(q):
		return Rect2()
	return Rect2(q - Vector2(h * 0.5, h * 0.6), Vector2(h, h * 1.2))


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
	var stage_done := false
	var bx: float = box.position.x if left else rect.end.x - box.size.x
	var shift: float = bx - box.position.x
	UiIcons.rrect(ci, Rect2(bx, box.position.y, box.size.x, box.size.y), 8.0 * s, Color(UiLook.col(UiLook.SCRIM), 0.5 * alpha), Color(UiLook.col(UiLook.EDGE), 0.25 * alpha), 1.2)
	for r in p["rows"]:
		var x: float = rect.position.x + float(p["pad"]) + shift
		if bool(r.get("held", false)):
			# The stance held now: a bar on the box's edge by its row (a shape, not a colour).
			var hb: float = float(p["row_h"]) * 0.7
			ci.draw_rect(Rect2(bx + 1.0, float(r["y"]) - hb * 0.5, maxf(3.0, 3.0 * s), hb), Color(UiLook.col(UiLook.INK), alpha))
		var beat_a: float = m.beat_ring if bool(r.get("beat", false)) else 0.0
		var last_c := Vector2.ZERO
		for sp in r["specs"]:
			var w: float = UiGlyphs.draw_spec(ci, sp, Vector2(x, float(r["y"])), gh, alpha, true)
			last_c = Vector2(x + w * 0.5, float(r["y"]))
			if beat_a > 0.01:
				draw_beat(ci, Vector2(x + w * 0.5, float(r["y"])), gh * 0.52, alpha * beat_a)   # the beat: a ring on each pressed glyph (RL-248)
			x += w + gap * 0.4
		if m.cstage > 0 and bool(r.get("stick", false)) and not stage_done:
			stage_done = true
			draw_stage(ci, last_c, gh, m.cstage, m.cstage_of, fs, alpha)   # the charge stage: a steady digit on the strike stick's glyph (docs/ui/charge-stages.md section 8)
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
			if lit_b(m) and str(r["cell"]) == "b":
				draw_lit(ci, gc, gh * 0.52, alpha)
			if UiStance.three() and m.punish_left > 0.0 and str(r["cell"]) == "y":
				draw_lit(ci, gc, gh * 0.52, alpha, 3)   # he missed and is open: the medium (Y) stops him, a lit ring with three ticks (B's launcher has four)
			if UiStance.three() and m.flurry_dots > 0 and str(r["cell"]) == "x":
				draw_dots(ci, gc, gh * 0.5, m.flurry_dots, alpha)
	UiText.no_outline = false


## The YOU marker over a fighter: a small pill with the label and a pointer toward the head, kept inside `safe`, edged and pointed in the fighter's lane colour (the colour of its plate).
## `compact` (after the opening seconds) is just the pointer, with the label only for P1 and P2: a steady, small mark that never goes away.
static func draw_you(ci: CanvasItem, label: String, anchor: Dictionary, s: float, alpha: float, safe: Rect2, lane: Color = Color(0.96, 0.95, 0.92), compact: bool = false) -> void:
	if label == "" or anchor.is_empty() or not bool(anchor.get("visible", true)) or alpha <= 0.01:
		return
	var c: Vector2 = anchor["pos"]
	if not safe.has_point(c):
		return   # off screen: the edge arrow (draw_you_edge) points to it instead
	var R: float = UiCrown.radius(float(anchor.get("h", 90.0)), s)
	var dark := Color(UiLook.col(UiLook.INK_DARK))
	UiText.no_outline = true
	if compact:
		var tw0: float = 9.0 * s
		var tip0 := Vector2(clampf(c.x, safe.position.x + tw0 * 2.0, safe.end.x - tw0 * 2.0), maxf(c.y - R * 1.3 - 6.0 * s, safe.position.y + 16.0 * s))
		var tri0 := PackedVector2Array([tip0, tip0 + Vector2(-tw0, -tw0 * 1.5), tip0 + Vector2(tw0, -tw0 * 1.5)])
		UiIcons.fill_poly(ci, tri0, Color(dark, 0.85 * alpha))
		var inner := PackedVector2Array([tip0 + Vector2(0.0, -1.6 * s), tip0 + Vector2(-tw0 * 0.62, -tw0 * 1.38), tip0 + Vector2(tw0 * 0.62, -tw0 * 1.38)])
		UiIcons.fill_poly(ci, inner, Color(lane, alpha))
		if label != "YOU":
			var fs0: int = UiText.px(15.0, s)
			UiText.draw(ci, label, Vector2(tip0.x, tip0.y - tw0 * 1.5 - 3.0 * s - UiText.height(fs0) + UiText.ascent(fs0)), fs0, Color(UiLook.col(UiLook.INK), alpha), 0)
		UiText.no_outline = false
		return
	var fs: int = UiText.px(22.0, s)
	var tw: float = UiText.width(label, fs)
	var pw: float = tw + 22.0 * s
	var ph: float = float(fs) + 10.0 * s
	var cx: float = clampf(c.x, safe.position.x + pw * 0.5, safe.end.x - pw * 0.5)
	var top: float = clampf(c.y - R * 1.3 - ph - 22.0 * s, safe.position.y, safe.end.y - ph - 12.0 * s)
	var r := Rect2(cx - pw * 0.5, top, pw, ph)
	UiIcons.rrect(ci, r, ph * 0.5, Color(UiLook.col(UiLook.INK), 0.92 * alpha), Color(lane, alpha), maxf(3.0, 3.5 * s))
	UiText.draw(ci, label, Vector2(r.get_center().x, r.get_center().y - UiText.height(fs) * 0.5 + UiText.ascent(fs)), fs, Color(dark, alpha), 0)
	# The pointer: a small triangle under the pill, toward the head, in the lane colour on a dark keyline.
	var tip := Vector2(clampf(c.x, r.position.x + ph * 0.5, r.end.x - ph * 0.5), r.end.y + 12.0 * s)
	UiIcons.fill_poly(ci, PackedVector2Array([tip + Vector2(0.0, 2.0 * s), tip + Vector2(-10.0 * s, -14.0 * s), tip + Vector2(10.0 * s, -14.0 * s)]), Color(dark, 0.85 * alpha))
	UiIcons.fill_poly(ci, PackedVector2Array([tip, tip + Vector2(-8.0 * s, -12.0 * s), tip + Vector2(8.0 * s, -12.0 * s)]), Color(lane, alpha))
	UiText.no_outline = false


## Where the edge arrow for an off-screen fighter sits and which way it points: {pos, dir} on `safe`'s border, or {} when the fighter is on screen (or has no anchor).
static func edge_arrow(anchor: Dictionary, safe: Rect2, s: float) -> Dictionary:
	if anchor.is_empty() or not bool(anchor.get("visible", true)):
		return {}
	var c: Vector2 = anchor["pos"]
	if safe.has_point(c):
		return {}
	var inset: float = 22.0 * s
	var inner := Rect2(safe.position + Vector2(inset, inset), safe.size - Vector2(inset, inset) * 2.0)
	var mid: Vector2 = safe.get_center()
	var dir: Vector2 = (c - mid).normalized()
	var pos := Vector2(clampf(c.x, inner.position.x, inner.end.x), clampf(c.y, inner.position.y, inner.end.y))
	return {"pos": pos, "dir": dir}


## The edge arrow: a triangle on the screen's border pointing toward the off-screen fighter, in its lane colour on a dark keyline, with the label under it.
static func draw_you_edge(ci: CanvasItem, label: String, arrow: Dictionary, s: float, alpha: float, lane: Color) -> void:
	if arrow.is_empty() or label == "" or alpha <= 0.01:
		return
	var p: Vector2 = arrow["pos"]
	var d: Vector2 = arrow["dir"]
	var n := Vector2(-d.y, d.x)
	var L: float = 16.0 * s
	var W: float = 12.0 * s
	var dark := Color(UiLook.col(UiLook.INK_DARK))
	UiText.no_outline = true
	UiIcons.fill_poly(ci, PackedVector2Array([p + d * (L + 3.0 * s), p - d * (L * 0.5 + 3.0 * s) + n * (W + 3.0 * s), p - d * (L * 0.5 + 3.0 * s) - n * (W + 3.0 * s)]), Color(dark, 0.85 * alpha))
	UiIcons.fill_poly(ci, PackedVector2Array([p + d * L, p - d * L * 0.5 + n * W, p - d * L * 0.5 - n * W]), Color(lane, alpha))
	var fs: int = UiText.px(15.0, s)
	UiText.draw(ci, label, Vector2(p.x, p.y + (L + 8.0 * s if d.y <= 0.0 else -L - 8.0 * s - UiText.height(fs)) + UiText.ascent(fs)), fs, Color(UiLook.col(UiLook.INK), alpha), 0)
	UiText.no_outline = false
