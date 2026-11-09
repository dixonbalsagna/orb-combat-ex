class_name UiPause
extends RefCounted
## The pause menu (docs/ui/hud-spec.md section 28): a card with Resume, How to play, Settings, Send feedback, About (How to play on its About page) and New match, opened by the
## host's pause key or button, with a focus ring so a keyboard or a pad can reach every entry. New match asks first (Start it, or Keep
## playing). `plan` is pure geometry (so hud_check proves every button is a 48 dp target inside the card at every size, one column when the
## height allows and two when it does not), `hit` says what a point is on, `draw` paints from a plan. Every word is in terms.json (prompt.pause_*).

const ENTRIES: Array = ["resume", "howto", "settings", "feedback", "about", "menu", "new"]
## While two people play, player two can be handed back to the AI from here.
const ENTRIES_TWO: Array = ["resume", "howto", "settings", "feedback", "about", "p2_leave", "menu", "new"]
## The card that opens a few seconds after a match ends.
const ENTRIES_OVER: Array = ["again", "menu", "feedback"]
## The same with "Save this match" (features.json save_match): a small file of this match, in plain words.
const ENTRIES_OVER_SAVE: Array = ["again", "save", "menu", "feedback"]
const CONFIRM: Array = ["new_yes", "new_no"]
const KEYS: Dictionary = {"resume": "pause_resume_key", "howto": "pause_howto_key", "new": "pause_new_key"}


static func ids(confirm: bool, two: bool = false, over: bool = false) -> Array:
	if over and not confirm:
		return ENTRIES_OVER_SAVE if UiData.feature("save_match") else ENTRIES_OVER
	return CONFIRM if confirm else (ENTRIES_TWO if two else ENTRIES)


static func label(id: String) -> String:
	return UiData.t("prompt.pause_" + id)


## The geometry for a viewport. `st` is {focus: index into ids(confirm, two), confirm: bool, two: bool (two people play: the hand-back entry),
## join: bool (player two is the AI and may join: a line under the buttons says how)}. Returns {card, title, title_pos, items[{id, label, key, rect}],
## cols, tm, fs_body, fs_title, fs_small, fits, bw}.
static func plan(vp: Vector2, s: float, dp: float, touch: bool, st: Dictionary) -> Dictionary:
	if UiRail.usable(vp, touch):
		var rp: Dictionary = rail_plan(vp, s, dp, st)
		if bool(rp["fits"]):
			return rp   # the Rail (docs/ui/menus-rail.md); where it does not fit, the card below is laid out as before
	var confirm: bool = bool(st.get("confirm", false))
	var over: bool = bool(st.get("over", false))
	var list: Array = ids(confirm, bool(st.get("two", false)), over)
	var status: String = str(st.get("status", "")) if not confirm else ""   # a short line under the buttons (Save this match says what happened); it takes the join line's place for its moment
	var where_text: String = str(st.get("where", "")) if not confirm else ""   # where saved reports go (a LAN build)
	var p2_join: bool = bool(st.get("join", false)) and not confirm and status == ""
	var join: bool = (p2_join or status != "" or where_text != "") and not confirm
	var tm: float = maxf(48.0 * dp, 44.0)
	var margin: float = maxf(vp.x * 0.03, 12.0)
	var my: float = maxf(vp.y * 0.04, 10.0)
	var cs: float = maxf(s, 0.3)
	var pad: float = maxf(20.0 * cs, 10.0)
	var fs_title: int = UiText.px(34.0, cs)
	var fs_body: int = UiText.px(22.0, cs)
	var fs_small: int = UiText.px(18.0, cs)
	var gap: float = maxf(10.0 * cs, 6.0)
	var title: String = UiData.t("prompt.pause_new_ask") if confirm else (UiData.t("prompt.pause_over_title") if over else UiData.t("prompt.pause_title"))
	var title_h: float = UiText.height(fs_title) * 1.15 + gap
	var avail_w: float = vp.x - 2.0 * margin - 2.0 * pad
	var avail_h: float = vp.y - 2.0 * my - 2.0 * pad
	var widest: float = UiText.width(title, fs_title) - tm * 0.9
	var facts: Array = st.get("facts", []) if (over or bool(st.get("facts_always", false))) else []   # facts_always: minimal_hud puts the damage counts on the pause screen too
	for ft in facts:
		widest = maxf(widest, UiText.width(str(ft), fs_small) + tm * 0.9)   # a line of facts may widen the card (up to the screen)
	for id in list:
		var w: float = UiText.width(label(id), fs_body) + (UiText.width(UiData.t("prompt." + str(KEYS[id])) , fs_small) + pad if (not touch and KEYS.has(id)) else 0.0)
		widest = maxf(widest, w)
	var bw0: float = maxf(maxf(300.0 * cs, tm * 4.0), widest + tm * 0.9)
	var foot_texts: Array = []
	if status != "":
		foot_texts.append(status)
	elif p2_join:
		foot_texts.append(UiData.t("prompt.pause_p2_join"))
	if where_text != "":
		foot_texts.append(where_text)
	for ft3 in foot_texts:
		for w3 in str(ft3).split(" "):
			bw0 = maxf(bw0, UiText.width(w3, fs_small) + tm * 0.9)   # a saved file's name is one long word: the card is as wide as it needs (the screen still caps it)
	var lh_small: float = UiText.height(fs_small) * 1.15
	var facts_lines := PackedStringArray()
	for ft in facts:
		for wl in UiText.wrap(str(ft), fs_small, avail_w):
			facts_lines.append(wl)
	var facts_h: float = (float(facts_lines.size()) * lh_small + gap) if facts_lines.size() > 0 else 0.0
	title_h += facts_h   # the buttons start below the facts
	var cols: int = 1
	var join_h1: float = (lh_small * 2.0 * float(foot_texts.size()) + gap) if join else 0.0
	if title_h + float(list.size()) * (tm + gap) - gap + join_h1 > avail_h:
		cols = 2
	var rows_n: int = int(ceil(float(list.size()) / float(cols)))
	var bw: float = minf(bw0, (avail_w - float(cols - 1) * gap) / float(cols))
	var cw: float = float(cols) * bw + float(cols - 1) * gap + 2.0 * pad
	var join_lines := PackedStringArray()
	if join:
		for ft2 in foot_texts:
			join_lines.append_array(UiText.wrap(str(ft2), fs_small, cw - 2.0 * pad))
	var join_h: float = (float(join_lines.size()) * lh_small + gap) if join else 0.0
	var chh: float = pad * 2.0 + title_h + float(rows_n) * (tm + gap) - gap + join_h
	var card := Rect2((vp.x - cw) * 0.5, (vp.y - chh) * 0.5, cw, chh)
	var items: Array = []
	for i in range(list.size()):
		var col: int = i % cols
		var row: int = i / cols
		var r := Rect2(card.position.x + pad + float(col) * (bw + gap), card.position.y + pad + title_h + float(row) * (tm + gap), bw, tm)
		var id: String = str(list[i])
		items.append({"id": id, "label": label(id), "key": UiData.t("prompt." + str(KEYS[id])) if (KEYS.has(id) and not touch) else "", "rect": r})
	var fits: bool = Rect2(Vector2.ZERO, vp).encloses(card) and UiText.width(title, fs_title) <= cw - 2.0 * pad
	for jl in join_lines:
		if UiText.width(str(jl), fs_small) > cw - 2.0 * pad + 0.5:
			fits = false   # a foot line (a file name too long for the card) would spill over its edge
	for it in items:
		var need: float = UiText.width(str(it["label"]), fs_body) + (UiText.width(str(it["key"]), fs_small) + gap * 2.0 if str(it["key"]) != "" else 0.0) + 16.0
		if need > bw or not card.encloses(it["rect"]) or (it["rect"] as Rect2).size.y < tm - 0.01:
			fits = false
	var join_pos := Vector2(card.position.x + pad, card.end.y - pad - float(join_lines.size()) * lh_small + UiText.ascent(fs_small))
	return {"join_lines": join_lines, "join_pos": join_pos, "lh_small": lh_small, "card": card, "title": title, "title_pos": Vector2(card.position.x + pad, card.position.y + pad + UiText.ascent(fs_title)), "items": items, "cols": cols, "tm": tm,
		"fs_body": fs_body, "fs_title": fs_title, "fs_small": fs_small, "fits": fits, "bw": bw, "focus": int(st.get("focus", 0)), "confirm": confirm, "two": bool(st.get("two", false)), "join": join, "touch": touch, "cs": cs, "pad": pad, "gap": gap,
		"facts_lines": facts_lines, "facts_pos": Vector2(card.position.x + pad, card.position.y + pad + UiText.height(fs_title) * 1.15 + gap * 0.5 + UiText.ascent(fs_small))}


## The id of the button a point is on, or "".
static func hit(p: Dictionary, pos: Vector2) -> String:
	for it in p["items"]:
		if (it["rect"] as Rect2).has_point(pos):
			return str(it["id"])
	return ""


## The focus after a move: dx and dy are -1, 0 or 1 (a grid of `cols` columns); it stays put at an edge.
static func moved(p: Dictionary, focus: int, dx: int, dy: int) -> int:
	var n: int = (p["items"] as Array).size()
	var cols: int = int(p["cols"])
	var f: int = clampi(focus, 0, n - 1)
	if dx != 0:
		var nf: int = f + dx
		if nf >= 0 and nf < n and (nf / cols) == (f / cols):
			f = nf
		elif cols == 1:
			f = clampi(nf, 0, n - 1)
	if dy != 0:
		var nf2: int = f + dy * cols
		if nf2 >= 0 and nf2 < n:
			f = nf2
	return f


static func sig(p: Dictionary) -> Array:
	if p.has("rail"):
		return ["rail", str(p["title"]), int((p["card"] as Rect2).size.x), int(p["vp_y"]), int(float(p["cs"]) * 100.0), int(p["focus"]), p["confirm"], p["two"], p["join"], str(p["facts_lines"]), str(p["join_lines"]), p["device"], p["style"], int(float(p["slide"]) * 40.0), int(float(p["bar_t"]) * 40.0), int(float(p["bar_y"]))]
	return [int((p["card"] as Rect2).size.x), int((p["card"] as Rect2).size.y), int(p["cs"] * 100.0), p["touch"], int(p["focus"]), p["confirm"], p["two"], p["join"], str(p["facts_lines"]), str(p["join_lines"])]


static func draw(ci: CanvasItem, p: Dictionary) -> void:
	if p.has("rail"):
		draw_rail(ci, p)
		return
	var vp: Vector2 = ci.size if ci is Control else Vector2(1920, 1080)
	var ink := Color(UiLook.col(UiLook.INK))
	var dim := Color(UiLook.col(UiLook.INK_DIM))
	var dark := Color(UiLook.col(UiLook.INK_DARK))
	var edge := Color(UiLook.col(UiLook.EDGE), 0.55)
	var scrim := Color(UiLook.col(UiLook.SCRIM))
	var card: Rect2 = p["card"]
	var fs_body: int = p["fs_body"]
	var focus: int = int(p["focus"])
	var touch: bool = p["touch"]
	UiText.no_outline = true
	ci.draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.03, 0.06, 0.62))
	UiIcons.rrect(ci, card, 18.0 * float(p["cs"]), Color(scrim, 0.97), edge, 2.0)
	UiText.draw(ci, str(p["title"]), p["title_pos"], int(p["fs_title"]), ink, -1)
	var fp: Vector2 = p["facts_pos"]
	for fl in p["facts_lines"]:
		UiText.draw(ci, str(fl), fp, int(p["fs_small"]), Color(ink, 0.95), -1)
		fp.y += float(p["lh_small"])
	var items: Array = p["items"]
	for i in range(items.size()):
		var it: Dictionary = items[i]
		var r: Rect2 = it["rect"]
		# The focused button is the filled one (a touch screen has no focus to show: Resume, the first, is the filled one).
		var on: bool = (i == focus) if not touch else (i == 0)
		UiIcons.rrect(ci, r, r.size.y * 0.3, Color(ink, 0.92) if on else Color(scrim, 0.8), Color(UiLook.col(UiLook.EDGE), 0.8), 1.8)
		var col: Color = dark if on else ink
		UiText.draw(ci, str(it["label"]), Vector2(r.position.x + r.size.y * 0.4, r.get_center().y + float(fs_body) * 0.35), fs_body, col, -1)
		if str(it["key"]) != "":
			UiText.draw(ci, str(it["key"]), Vector2(r.end.x - r.size.y * 0.4, r.get_center().y + float(p["fs_small"]) * 0.35), int(p["fs_small"]), Color(dark if on else dim, 0.8), 1)
	var jp: Vector2 = p["join_pos"]
	for ln in p["join_lines"]:
		UiText.draw(ci, ln, jp, int(p["fs_small"]), Color(dim, 0.9), -1)
		jp.y += float(p["lh_small"])
	UiText.no_outline = false


# --- The Rail layout (docs/ui/menus-rail.md) -----------------------------------------------------------------------------------

## The Rail's geometry: the rail down the left edge with the title block and the rows, a detail card on the right (the match's facts, what a save did, where saved reports go), a chip for the join line, and the hint strip for the
## player's device at the foot of the rail. `st` is as for `plan`, plus {device: "kbd"|"pad", style: the glyph style, since: seconds since the screen opened, prev: the row the lit bar came from (-1 for none), bar_since: seconds since the
## focus moved, reduced: Reduce motion, win: the result line}. The plan has every key `plan` returns (the rows are `items`, one column, each at least `tm` tall, inside `card`, which here is the rail) so input and tests work on either
## layout, and "rail": true. `fits` is false when the rail cannot hold the title, the rows and the hints, and `plan` then lays the old card out instead.
static func rail_plan(vp: Vector2, s: float, dp: float, st: Dictionary) -> Dictionary:
	var m: Dictionary = UiRail.metrics(vp, s, dp)
	var cs: float = float(m["cs"])
	var confirm: bool = bool(st.get("confirm", false))
	var over: bool = bool(st.get("over", false))
	var two: bool = bool(st.get("two", false))
	var list: Array = ids(confirm, two, over)
	var device: String = str(st.get("device", "kbd"))
	var style: String = str(st.get("style", "neutral"))
	var reduced: bool = bool(st.get("reduced", false))
	var status: String = str(st.get("status", "")) if not confirm else ""
	var where_text: String = str(st.get("where", "")) if not confirm else ""
	var p2_join: bool = bool(st.get("join", false)) and not confirm and status == ""
	var x0: float = float(m["x0"])
	var rw: float = float(m["rw"])
	var rail := Rect2(0.0, 0.0, rw, vp.y)
	var fs_title: int = int(m["fs_title"])
	var fs_kicker: int = int(m["fs_kicker"])
	var fs_small: int = int(m["fs_small"])
	var fs_row: int = int(m["fs_row"])
	var rh: float = float(m["rh"])
	var gap: float = float(m["gap"])
	var tm: float = float(m["tm"])
	var rx: float = x0 * 0.55
	var row_w: float = rw - rx * 2.0
	# The title block: a small line over the screen's name (the result, on the match-over card).
	var win: String = str(st.get("win", ""))
	var kicker: String = UiData.t("prompt.rail_over") if (over and not confirm and win != "") else UiData.t("prompt.rail_kicker")
	var title: String = UiData.t("prompt.pause_new_ask") if confirm else (win if (over and win != "") else (UiData.t("prompt.rail_over") if over else UiData.t("prompt.rail_paused")))
	var title_lines: PackedStringArray = UiText.wrap(title, fs_title, rw - x0 * 2.0)
	var top: float = maxf(vp.y * 0.07, 28.0 * cs)
	var lh_title: float = UiText.height(fs_title) * 1.1
	var y: float = top + UiText.height(fs_kicker) * 1.3
	var title_pos := Vector2(x0, y + UiText.ascent(fs_title))
	y += lh_title * float(title_lines.size()) + gap * 3.0
	# Rows: the largest type that holds the widest label and key, down to four fifths of the usual size.
	var labels: Array = []
	var keys: Array = []
	for id in list:
		labels.append(UiData.t("prompt.rail_p2_leave") if str(id) == "p2_leave" else label(str(id)))
		keys.append(UiData.t("prompt." + str(KEYS[id])) if (KEYS.has(id) and device == "kbd" and not over) else "")
	var fs_r: int = fs_row
	var lo: int = maxi(int(floor(float(fs_row) * 0.8)), 12)
	var rows_fit: bool = false
	while fs_r >= lo:
		rows_fit = true
		for i in range(list.size()):
			if UiText.width(str(labels[i]), fs_r) + (UiText.width(str(keys[i]), fs_small) + 24.0 * cs if str(keys[i]) != "" else 0.0) + maxf(rh * 0.8, 28.0) > row_w:
				rows_fit = false
		if rows_fit:
			break
		fs_r -= 1
	fs_r = maxi(fs_r, lo)
	var items: Array = []
	var row_ys: Array = []
	var first_y: float = y
	for i in range(list.size()):
		var r := Rect2(rx, first_y + float(i) * (rh + gap), row_w, rh)
		row_ys.append(r.position.y)
		items.append({"id": str(list[i]), "label": str(labels[i]), "key": str(keys[i]), "rect": r})
	var rows_end: float = first_y + float(list.size()) * (rh + gap) - gap
	# The hint strip: what the player's own device presses, wrapped inside the rail.
	var hint_gh: float = maxf(26.0 * cs, 22.0)
	var hint_fs: int = fs_small
	var back_word: String = UiData.t("prompt.rail_hint_keep") if confirm else (UiData.t("prompt.rail_hint_again") if (over and UiData.feature("versus_flow")) else UiData.t("prompt.rail_hint_resume"))
	var pairs: Array = [["move", UiData.t("prompt.rail_hint_choose")], ["accept", UiData.t("prompt.rail_hint_select")], ["back", back_word]]
	var entries: Array = UiRail.hint_entries(device, style, pairs, hint_gh, hint_fs)
	var hint_lines: Array = []   # each [first entry, one past the last] on one line
	var line_w: float = 0.0
	var from_i: int = 0
	for i in range(entries.size()):
		var w: float = float(entries[i]["w"])
		if i > from_i and line_w + gap * 3.0 + w > rw - x0 * 2.0:
			hint_lines.append([from_i, i])
			from_i = i
			line_w = 0.0
		line_w += (gap * 3.0 if i > from_i else 0.0) + w
	hint_lines.append([from_i, entries.size()])
	var hint_lh: float = hint_gh * 1.5
	var hint_top: float = vp.y - maxf(vp.y * 0.04, 12.0) - hint_lh * float(hint_lines.size())
	# The detail card on the right: the facts, then what a save did and where saved reports go (quieter).
	var facts: Array = []
	for ft in st.get("facts", []):
		if not (over and str(ft) == win):
			facts.append(str(ft))
	var margin: float = maxf(vp.x * 0.03, 16.0)
	var cpad: float = maxf(24.0 * cs, 14.0)
	var foot_texts: Array = []
	if status != "":
		foot_texts.append(status)
	if where_text != "":
		foot_texts.append(where_text)
	var widest_word: float = 0.0
	for ft3 in foot_texts:
		for w3 in str(ft3).split(" "):
			widest_word = maxf(widest_word, UiText.width(w3, fs_small))   # a saved file's name is one long word: the card is as wide as it needs (the screen still caps it)
	var cw: float = minf(maxf(clampf(vp.x * 0.27, 260.0 * cs, 420.0 * maxf(cs, 1.0)), widest_word + cpad * 2.0 + 2.0), vp.x - rw - margin * 2.0)
	var inner: float = cw - cpad * 2.0
	var detail: Array = []   # each {t, dim}
	for ft2 in facts:
		for wl in UiText.wrap(str(ft2), fs_small, inner):
			detail.append({"t": str(wl), "dim": false})
	for ft3 in foot_texts:
		for wl2 in UiText.wrap(str(ft3), fs_small, inner):
			detail.append({"t": str(wl2), "dim": true})
	var lh_small: float = UiText.height(fs_small) * 1.2
	var has_card: bool = not detail.is_empty()
	var card_h: float = cpad * 2.0 + UiText.height(fs_kicker) * 1.5 + lh_small * float(detail.size())
	var card_top: float = maxf(vp.y * 0.34, 150.0 * cs)   # the middle of the right edge: clear of the player plates at the top corners and the legend at the foot
	var card := Rect2(vp.x - margin - cw, card_top, cw, card_h) if has_card else Rect2(vp.x - margin, card_top, 0.0, 0.0)
	# The join line as a chip above the card.
	var chip_text: String = UiData.t("prompt.pause_p2_join") if p2_join else ""
	var chip_w: float = (UiText.width(chip_text, fs_small) + 32.0 * cs) if chip_text != "" else 0.0
	var chip_h: float = maxf(UiText.height(fs_small) * 1.5, 34.0) if chip_text != "" else 0.0
	var chip := Rect2(vp.x - margin - chip_w, card_top - chip_h - gap * 2.0, chip_w, chip_h) if chip_text != "" else Rect2()
	# Fit: the rows and the title above the hints, the card and chip on the screen and clear of the rail and of each other.
	var fits: bool = rows_fit and rows_end + gap <= hint_top and title_lines.size() <= 3
	for tl in title_lines:
		if UiText.width(str(tl), fs_title) > rw - x0 * 1.5:
			fits = false
	if has_card:
		fits = fits and Rect2(Vector2.ZERO, vp).encloses(card) and card.position.x >= rw + gap and widest_word <= inner + 0.5
	if chip_text != "":
		fits = fits and chip.position.x >= rw + gap and Rect2(Vector2.ZERO, vp).encloses(chip) and (not has_card or chip.end.y + gap <= card.position.y)
	fits = fits and hints_fit(entries, hint_lines, gap * 3.0, rw - x0 * 2.0)
	for it in items:
		if (it["rect"] as Rect2).size.y < tm - 0.01 or not rail.encloses(it["rect"]):
			fits = false
	var focus: int = clampi(int(st.get("focus", 0)), 0, maxi(list.size() - 1, 0))
	var bar_since: float = float(st.get("bar_since", 99.0))
	var prev: int = int(st.get("prev", -1))
	var join_lines := PackedStringArray()
	if chip_text != "":
		join_lines.append(chip_text)
	var facts_lines := PackedStringArray()
	for d in detail:
		facts_lines.append(str((d as Dictionary)["t"]))
	return {"rail": true, "card": rail, "title": title, "title_lines": title_lines, "title_pos": title_pos, "kicker": kicker, "kicker_pos": Vector2(x0, top + UiText.ascent(fs_kicker)), "lh_title": lh_title,
		"items": items, "row_ys": row_ys, "cols": 1, "tm": tm, "fs_body": fs_r, "fs_title": fs_title, "fs_small": fs_small, "fs_kicker": fs_kicker, "fits": fits, "bw": row_w, "focus": focus, "confirm": confirm, "two": two,
		"join": p2_join or status != "" or where_text != "", "touch": false, "cs": cs, "pad": cpad, "gap": gap, "lh_small": lh_small, "x0": x0, "detail": detail, "detail_card": card, "has_card": has_card,
		"card_kicker": UiData.t("prompt.rail_this_match") if has_card else "", "chip": chip, "chip_text": chip_text, "join_lines": join_lines, "join_pos": Vector2.ZERO, "facts_lines": facts_lines, "facts_pos": Vector2.ZERO,
		"hints": entries, "hint_lines": hint_lines, "hint_gh": hint_gh, "hint_fs": hint_fs, "hint_top": hint_top, "hint_lh": hint_lh, "device": device, "style": style, "vp_y": vp.y,
		"slide": UiRail.slide(float(st.get("since", 99.0)), reduced), "bar_t": 1.0 if (reduced or prev < 0) else clampf(bar_since / UiRail.BAR_SECS, 0.0, 1.0), "bar_y": UiRail.bar_y(row_ys, focus, prev, bar_since, reduced)}


## Whether every hint line fits `width` (entries side by side with `gap` between).
static func hints_fit(entries: Array, lines: Array, gap: float, width: float) -> bool:
	for ln in lines:
		var w: float = 0.0
		for i in range(int(ln[0]), int(ln[1])):
			w += float(entries[i]["w"]) + (gap if i > int(ln[0]) else 0.0)
		if w > width + 0.5:
			return false
	return true


static func draw_rail(ci: CanvasItem, p: Dictionary) -> void:
	var vp: Vector2 = ci.size if ci is Control else Vector2(1920, 1080)
	var cs: float = float(p["cs"])
	var rail: Rect2 = p["card"]
	var sl: float = float(p["slide"])
	var off: float = -(1.0 - sl) * rail.size.x   # the rail slides in from its own edge, the detail from the right edge
	var coff: float = (1.0 - sl) * (vp.x - rail.size.x)
	var shift := Vector2(off, 0.0)
	UiText.no_outline = true
	ci.draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.03, 0.06, 0.4))
	UiRail.draw_panel(ci, rail, off)
	var ink := Color(UiLook.col(UiLook.INK))
	var dim := Color(UiLook.col(UiLook.INK_DIM))
	UiText.draw(ci, str(p["kicker"]).to_upper(), (p["kicker_pos"] as Vector2) + shift, int(p["fs_kicker"]), Color(dim, 0.9), -1)
	var tp: Vector2 = (p["title_pos"] as Vector2) + shift
	for tl in p["title_lines"]:
		UiText.draw(ci, str(tl), tp, int(p["fs_title"]), ink, -1)
		tp.y += float(p["lh_title"])
	var items: Array = p["items"]
	var by: float = float(p["bar_y"])
	if not items.is_empty():
		var r0: Rect2 = (items[0] as Dictionary)["rect"]
		UiRail.draw_bar(ci, Rect2(Vector2(r0.position.x + off, by), r0.size), cs)
	for it in items:
		var r: Rect2 = (it as Dictionary)["rect"]
		var lit: bool = absf(r.position.y - by) < r.size.y * 0.5
		UiRail.draw_row_text(ci, Rect2(r.position + shift, r.size), str(it["label"]), str(it["key"]), lit, int(p["fs_body"]), int(p["fs_small"]))
	var entries: Array = p["hints"]
	var hy: float = float(p["hint_top"]) + float(p["hint_lh"]) * 0.5
	for ln in p["hint_lines"]:
		UiRail.draw_hints(ci, entries.slice(int(ln[0]), int(ln[1])), float(p["x0"]) + off, hy, float(p["hint_gh"]), int(p["hint_fs"]), float(p["gap"]) * 3.0, 1.0)
		hy += float(p["hint_lh"])
	if bool(p["has_card"]):
		var c: Rect2 = p["detail_card"]
		UiRail.draw_card(ci, Rect2(c.position + Vector2(coff, 0.0), c.size), str(p["card_kicker"]), p["detail"], int(p["fs_kicker"]), int(p["fs_small"]), cs)
	if str(p["chip_text"]) != "":
		var ch: Rect2 = p["chip"]
		var cr := Rect2(ch.position + Vector2(coff, 0.0), ch.size)
		UiIcons.rrect(ci, cr, cr.size.y * 0.5, Color(UiLook.col(UiLook.SCRIM), 0.95), Color(UiLook.col(UiLook.EDGE), 0.6), 1.5)
		UiText.draw(ci, str(p["chip_text"]), Vector2(cr.get_center().x, cr.get_center().y + float(p["fs_small"]) * 0.35), int(p["fs_small"]), Color(ink, 0.95), 0)
	UiText.no_outline = false
