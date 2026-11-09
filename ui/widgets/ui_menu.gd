class_name UiMenu
extends RefCounted
## The start menu (docs/ui/start-menu.md): the first thing a visitor sees, over a still dark background with no match playing: the flashing-effects notice at the top, radio
## buttons for how many play and on what, checkboxes for the settings that matter most, and one Start button. It is also the way back after a match. `plan` is pure geometry (so
## hud_check proves every control is a 48 dp target inside the card at every size), `hit` says what a point is on, `draw` paints from a plan. Every word is in terms.json
## (prompt.menu_*). Nothing here touches the sim: the HUD hands the choices to the host when Start is pressed.

const ROW_IDS: Array = ["players", "p1", "p2", "ai", "intros", "reduce_flashing", "shake", "captions", "guide", "start", "not_now", "back"]
const CHECKS: Array = ["intros", "reduce_flashing", "shake", "captions", "guide"]
## The computer's level: the choices are the levels of data/director/ai.json (Encounter's), the default is the level that file runs a match at. Saved with the menu choices as `ai_level`;
## the host passes it to the sim in the match setup (`aiLevel`) and the sim applies it. The row is shown only when the computer plays a side (one player).
const DEFAULT_LEVEL := "medium"
const AI_PATH := "res://data/director/ai.json"
static var _levels: Array = []
static var _default_level: String = ""


static func levels() -> Array:
	if _levels.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string(AI_PATH))
		if j is Dictionary and (j as Dictionary).get("levels") is Dictionary:
			for k in (j["levels"] as Dictionary).keys():
				if not str(k).begins_with("_"):
					_levels.append(str(k))
			_default_level = str(j.get("level", DEFAULT_LEVEL))
		if _levels.is_empty():
			_levels = ["easy", "medium", "hard"]
		if not _levels.has(_default_level):
			_default_level = DEFAULT_LEVEL if _levels.has(DEFAULT_LEVEL) else str(_levels[0])
	return _levels


## A saved or pressed value as a level the data has, else the default.
static func level_of(v) -> String:
	var lv: Array = levels()
	return str(v) if lv.has(str(v)) else _default_level


## The level after a step of d along the levels: held at the ends, or wrapping (Enter on the row).
static func level_step(cur: String, d: int, wrap: bool) -> String:
	var lv: Array = levels()
	var i: int = maxi(lv.find(level_of(cur)), 0) + d
	return str(lv[posmod(i, lv.size()) if wrap else clampi(i, 0, lv.size() - 1)])


static func word(key: String) -> String:
	return UiData.t("prompt.menu_" + key)


## The boxes the menu shows: all five, or four while Reduce flashing is locked on (Legal's addendum 10: the box is not offered).
static func checks() -> Array:
	var out: Array = []
	for c in CHECKS:
		if c == "reduce_flashing" and UiData.rf_locked():
			continue
		out.append(c)
	return out


## The notice: Legal's words (RL-136), exactly, from data (prompt.menu_notice). It does not change with the boxes; the small line under the button says what Reduce flashing does.
static func notice(_cfg: Dictionary = {}) -> String:
	return word("notice")


## The small line under the button: Reduce flashing's state, in Legal's words. Locked on, it is the RL-136 line alone (there is nothing to turn off); with the box shown, "on"
## carries Legal's sentence from addendum 10 and "off" says plainly that full effects are on.
static func rf_line(cfg: Dictionary) -> String:
	if UiData.rf_locked():
		return word("rf_locked")
	return word("rf_on" if bool(cfg.get("reduce_flashing", true)) else "rf_off")


## The focusable rows, in order, for a state: player two's row only with two players, Back only mid-match.
static func rows(cfg: Dictionary, mid_match: bool, not_now: bool = false) -> Array:
	var out: Array = ["players", "p1"]
	if int(cfg.get("players", 1)) == 2:
		out.append("p2")
	else:
		out.append("ai")   # the computer plays player two: its level is a choice
	out.append_array(checks())
	out.append("start")
	if not_now:
		out.append("not_now")
	if mid_match:
		out.append("back")
	return out


static func plan(vp: Vector2, s: float, dp: float, touch: bool, st: Dictionary) -> Dictionary:
	if UiRail.usable(vp, touch):
		var rp: Dictionary = rail_plan(vp, s, dp, st)
		if bool(rp["fits"]):
			return rp   # the Rail (docs/ui/menus-rail.md); where it does not fit, the card below is laid out as before
	var cfg: Dictionary = st.get("cfg", {})
	var mid: bool = bool(st.get("mid_match", false))
	var not_now: bool = bool(st.get("not_now", false))
	var list: Array = rows(cfg, mid, not_now)
	var cks: Array = checks()
	var cs: float = maxf(s, 0.3)
	var tm: float = maxf(48.0 * dp, 44.0)
	var margin: float = maxf(vp.x * 0.025, 8.0)
	var my: float = maxf(vp.y * 0.03, 6.0)
	var pad: float = maxf(minf(18.0 * cs, vp.y * 0.03), 8.0)
	var gap: float = maxf(minf(10.0 * cs, vp.y * 0.02), 5.0)
	var floor_px: int = int(UiLook.text_floor)
	var area := Rect2(Vector2(margin, my), Vector2(vp.x - 2.0 * margin, vp.y - 2.0 * my))
	var sf = st.get("safe", Rect2())
	if sf is Rect2 and (sf as Rect2).size.x > 1.0 and (sf as Rect2).size.y > 1.0:
		area = (sf as Rect2).intersection(area)
	var cw: float = minf(area.size.x, maxf(900.0 * cs, 760.0 * maxf(dp, 1.0)))   # wide enough that a radio row is its label and its two options on one line
	var card_x: float = area.position.x + (area.size.x - cw) * 0.5
	var inner_w: float = cw - 2.0 * pad
	var pad0: float = pad
	var gap0: float = gap
	var best: Dictionary = {}
	var fs0: int = UiText.px(22.0, cs)
	# A short screen with a long notice: if the floor font still does not fit, the padding and gaps are halved and the search runs again.
	for squeeze in [1.0, 0.5]:
		pad = maxf(pad0 * squeeze, 6.0)
		gap = maxf(gap0 * squeeze, 3.0)
		inner_w = cw - 2.0 * pad
		for fs in range(fs0, floor_px - 1, -1):
			var fs_s: int = maxi(int(round(float(fs) * 0.82)), floor_px)
			var back_w: float = UiText.width(word("back"), fs) + tm * 0.9   # Back (mid-match) sits at the top right, on the notice's line
			# Mid-match the notice is not repeated (the visitor read it before the first fight): the Back button has the top line to itself.
			var nn_w0: float = minf(UiText.width(word("not_now"), fs) + tm * 1.2, inner_w * 0.34) if not_now else 0.0   # Not now sits at the top right, as Back does mid-match
			var lines: PackedStringArray = PackedStringArray() if mid else UiText.wrap(notice(cfg), fs, inner_w - (nn_w0 + gap if not_now else 0.0))
			var lh: float = UiText.height(fs) * 1.2
			var notice_h: float = maxf(float(lines.size()) * lh, tm if (mid or not_now) else 0.0)
			var colw: float = (inner_w - gap * 2.0) * 0.5
			# A narrow card (a phone upright): if a radio row's two options cannot sit side by side in half the card, the boxes go under the radios and the radios have the full width.
			var need_w: float = 0.0
			for id0 in ["players", "p1", "p2", "ai"]:
				if not list.has(id0):
					continue
				var ow: float = 0.0
				for o0 in _options(id0):
					ow += 30.0 * maxf(dp, 1.0) * 0.8 + UiText.width(str(o0[1]), fs) + gap
				need_w = maxf(need_w, ow)
			var stack: bool = need_w > colw
			if stack:
				colw = inner_w
			# Left column: the radio rows, one line each: the label, then its options side by side; a row that does not fit inline puts its options under the label.
			var left_h: float = 0.0
			var radio_rows: Array = []
			for id in ["players", "p1", "p2", "ai"]:
				if not list.has(id):
					continue
				var opts: Array = _options(id)
				var lab: String = word("players") if id == "players" else word(id)
				var label_w: float = UiText.width(lab, fs) + gap
				var opt_ws: Array = []
				var total: float = label_w
				for o in opts:
					var w: float = 30.0 * maxf(dp, 1.0) * 0.8 + UiText.width(str(o[1]), fs) + gap
					opt_ws.append(w)
					total += w
				var inline: bool = total <= colw
				radio_rows.append({"id": id, "label": lab, "inline": inline, "opt_ws": opt_ws, "h": tm if inline else (tm * 2.0 + gap * 0.5)})
				left_h += float(radio_rows[radio_rows.size() - 1]["h"]) + gap
			var note_h: float = 0.0
			var note_text: String = ""
			if int(cfg.get("players", 1)) == 1:
				note_text = word("one_note")
			elif str(cfg.get("p1", "kb")) == "kb" and str(cfg.get("p2", "kb")) == "kb":
				note_text = word("both_kb")
			elif bool(st.get("pad_missing", false)):
				note_text = word("no_pad")
			if note_text != "":
				var note_lines: PackedStringArray = UiText.wrap(note_text, fs_s, colw)
				note_h = float(note_lines.size()) * UiText.height(fs_s) * 1.2 + gap * 0.5
			var left_h_note: float = left_h + note_h
			left_h = left_h_note
			# Right column: the checkboxes, in one or two sub-columns by what fits.
			var cws: float = 0.0
			for c in cks:
				cws = maxf(cws, UiText.width(word(c), fs) + tm * 0.55 + gap)
			var subcols: int = 1 if cws * 2.0 + gap > colw else 2
			var check_rows: int = int(ceil(float(cks.size()) / float(subcols)))
			var right_h: float = float(check_rows) * (tm + gap * 0.5)
			var btn_h: float = tm
			var sub_lines: PackedStringArray = UiText.wrap(rf_line(cfg), fs_s, inner_w)
			var sub_h: float = float(sub_lines.size()) * UiText.height(fs_s) * 1.2 + gap * 0.5   # the small line under the button
			var total_h: float = pad * 2.0 + notice_h + gap * 1.5 + ((left_h + gap + right_h) if stack else maxf(left_h, right_h)) + gap + btn_h + sub_h
			if total_h > area.size.y and note_h > 0.0:
				# Too tall with its one line of help: the line goes (it is a courtesy), and the layout is tried again without it.
				left_h -= note_h
				note_h = 0.0
				note_text = ""
				total_h = pad * 2.0 + notice_h + gap * 1.5 + ((left_h + gap + right_h) if stack else maxf(left_h, right_h)) + gap + btn_h + sub_h
			# A short screen: Start takes the empty cell of the boxes (the five boxes in two columns leave one) and Back sits under the left column.
			# Start can take the empty cell of the boxes (five in two columns leave one); with the grid full (four boxes, Reduce flashing locked) it takes a row under them, which is free when the left column is the taller.
			var grid_full: bool = subcols == 2 and cks.size() == subcols * check_rows and not stack
			var corner: bool = subcols == 2 and (cks.size() < subcols * check_rows or (grid_full and left_h >= right_h + tm + gap * 0.5))
			var right_a: float = right_h + (tm + gap * 0.5 if grid_full else 0.0)
			var total_a: float = pad * 2.0 + notice_h + gap * 1.5 + ((left_h + gap + right_h) if stack else maxf(left_h, right_a)) + sub_h
			var use_corner: bool = corner and total_h > area.size.y
			if use_corner:
				total_h = total_a
			best = {"fs": fs, "fs_s": fs_s, "lines": lines, "lh": lh, "notice_h": notice_h, "colw": colw, "radio_rows": radio_rows, "left_h": left_h, "note_text": note_text, "note_h": note_h,
				"subcols": subcols, "check_rows": check_rows, "right_h": right_h, "cws": cws, "total_h": total_h, "corner": use_corner, "back_w": back_w, "sub_h": sub_h, "sub_lines": sub_lines, "stack": stack}
			if total_h <= area.size.y:
				break
		if float(best["total_h"]) <= area.size.y + 0.5:
			break
	var ch: float = minf(float(best["total_h"]), area.size.y)
	var card := Rect2(card_x, area.position.y + (area.size.y - ch) * 0.5, cw, ch)
	var items: Array = []   # every control that takes a press: {row, kind, value, rect}
	var y: float = card.position.y + pad
	var x0: float = card.position.x + pad
	var notice_pos := Vector2(x0, y)
	y += float(best["notice_h"]) + gap * 1.5
	var colw2: float = float(best["colw"])
	var yl: float = y
	var row_boxes: Dictionary = {}
	for rr in best["radio_rows"]:
		var id: String = str(rr["id"])
		var h: float = float(rr["h"])
		var box := Rect2(x0, yl, colw2, h)
		row_boxes[id] = box
		var opts: Array = _options(id)
		var lab_w: float = UiText.width(str(rr["label"]), int(best["fs"])) + gap
		var ox: float = x0 + lab_w if bool(rr["inline"]) else x0
		var oy: float = yl if bool(rr["inline"]) else yl + tm * 0.5 + gap * 0.5
		var opt_ws: Array = rr["opt_ws"]
		for i in range(opts.size()):
			var w: float = float(opt_ws[i])
			var r := Rect2(ox, oy, minf(w - 2.0, x0 + colw2 - ox), tm if bool(rr["inline"]) else tm * 1.5)
			items.append({"row": id, "kind": "radio", "value": str(opts[i][0]), "label": str(opts[i][1]), "rect": r})
			ox += w
		yl += h + gap
	var note_pos := Vector2(x0, yl)
	var note_extra: float = float(best["note_h"])
	var stacked: bool = bool(best["stack"])
	var xr: float = x0 if stacked else x0 + colw2 + gap * 2.0
	var cy: float = (yl + note_extra + gap) if stacked else y   # stacked: the boxes sit under the radios and their line
	var cwid: float = (colw2 - gap * float(int(best["subcols"]) - 1)) / float(best["subcols"])
	for i in range(cks.size()):
		var col: int = i / int(best["check_rows"])
		var rowi: int = i % int(best["check_rows"])
		var r := Rect2(xr + float(col) * (cwid + gap), cy + float(rowi) * (tm + gap * 0.5), cwid, tm)
		items.append({"row": cks[i], "kind": "check", "value": "", "label": word(cks[i]), "rect": r})
		row_boxes[cks[i]] = r
	var by: float = card.end.y - pad - float(best["sub_h"]) - tm
	var nn_w: float = minf(UiText.width(word("not_now"), int(best["fs"])) + tm * 1.2, inner_w * 0.34) if not_now else 0.0
	var start := Rect2(x0, by, inner_w, tm)
	var not_now_r := Rect2(card.end.x - pad - nn_w, card.position.y + pad, nn_w, tm)
	var back := Rect2(card.end.x - pad - float(best["back_w"]), card.position.y + pad, float(best["back_w"]), tm)
	if bool(best["corner"]):
		if cks.size() == int(best["subcols"]) * int(best["check_rows"]):
			start = Rect2(xr, cy + float(best["check_rows"]) * (tm + gap * 0.5), colw2, tm)   # the grid is full: Start takes a row under the boxes, the column's width
		else:
			var crow: int = int(best["check_rows"]) - 1
			start = Rect2(xr + (cwid + gap) * float(int(best["subcols"]) - 1), cy + float(crow) * (tm + gap * 0.5), cwid, tm)
	items.append({"row": "start", "kind": "button", "value": "", "label": word("start"), "rect": start})
	row_boxes["start"] = start
	if not_now:
		items.append({"row": "not_now", "kind": "button", "value": "", "label": word("not_now"), "rect": not_now_r})
		row_boxes["not_now"] = not_now_r
	if mid:
		items.append({"row": "back", "kind": "button", "value": "", "label": word("back"), "rect": back})
		row_boxes["back"] = back
	var fits: bool = Rect2(Vector2.ZERO, vp).encloses(card)
	for it in items:
		var r: Rect2 = it["rect"]
		if not card.encloses(r) or r.size.y < tm - 0.01:
			fits = false
	# No two controls overlap.
	for i in range(items.size()):
		for j in range(i + 1, items.size()):
			if (items[i]["rect"] as Rect2).intersects(items[j]["rect"]):
				fits = false
	if float(best["total_h"]) > area.size.y + 0.5:
		fits = false
	return {"sub_lines": best["sub_lines"], "sub_pos": Vector2(x0, card.end.y - pad - float(best["sub_h"]) + gap * 0.25), "card": card, "notice_lines": best["lines"], "notice_pos": notice_pos, "lh": best["lh"], "fs": best["fs"], "fs_s": best["fs_s"], "items": items, "rows": list, "row_boxes": row_boxes,
		"stack": best["stack"], "total_h": best["total_h"], "area_h": area.size.y, "radio_rows": best["radio_rows"], "note_text": best["note_text"], "note_pos": note_pos, "note_w": colw2, "tm": tm, "pad": pad, "gap": gap, "cs": cs, "fits": fits,
		"focus": clampi(int(st.get("focus", 0)), 0, list.size() - 1), "touch": touch, "cfg": cfg}


static func _options(id: String) -> Array:
	match id:
		"players":
			return [["1", word("one")], ["2", word("two")]]
		"ai":
			var out: Array = []
			for lv in levels():
				out.append([str(lv), word("ai_" + str(lv))])
			return out
		_:
			return [["kb", word("kb")], ["pad", word("pad")]]


## What a point is on: {row, kind, value} of the control, or {}.
static func hit(p: Dictionary, pos: Vector2) -> Dictionary:
	for it in p["items"]:
		if (it["rect"] as Rect2).has_point(pos):
			return {"row": it["row"], "kind": it["kind"], "value": it["value"]}
	return {}


## The focus after a move along the rows (up and down), staying put at the ends.
static func moved(focus: int, d: int, count: int) -> int:
	return clampi(focus + d, 0, count - 1)


static func sig(p: Dictionary) -> Array:
	if p.has("rail"):
		var rc: Dictionary = p["cfg"]
		return ["rail", int((p["rail_rect"] as Rect2).size.x), int(p["vp_y"]), int(float(p["cs"]) * 100.0), int(p["focus"]), int(p["fs"]), int(rc.get("players", 1)), str(rc.get("p1", "")), str(rc.get("p2", "")), str(rc.get("ai_level", "")),
			bool(rc.get("intros", true)), bool(rc.get("reduce_flashing", true)), bool(rc.get("shake", true)), bool(rc.get("captions", true)), bool(rc.get("guide", true)), str(p["note_text"]), p["device"], p["style"],
			int(float(p["slide"]) * 40.0), int(float(p["bar_t"]) * 40.0), int(float(p["bar_y"])), bool(p["bar_vis"])]
	var c: Rect2 = p["card"]
	var cfg: Dictionary = p["cfg"]
	return [int(c.size.x), int(c.size.y), int(c.position.x), int(c.position.y), int(p["focus"]), int(p["fs"]), int(cfg.get("players", 1)), str(cfg.get("p1", "")), str(cfg.get("p2", "")), str(cfg.get("ai_level", "")),
		bool(cfg.get("intros", true)), bool(cfg.get("reduce_flashing", true)), bool(cfg.get("shake", true)), bool(cfg.get("captions", true)), bool(cfg.get("guide", true)), str(p["note_text"]), bool(p["touch"])]


static func draw_backdrop(ci: CanvasItem) -> void:
	var vp: Vector2 = ci.size if ci is Control else Vector2(1920, 1080)
	ci.draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.03, 0.06, 1.0))
	# A still, calm ground line low on the screen, so it reads as a place and not an error.
	ci.draw_rect(Rect2(0.0, vp.y * 0.82, vp.x, vp.y * 0.18), Color(0.04, 0.06, 0.1, 1.0))
	ci.draw_line(Vector2(0.0, vp.y * 0.82), Vector2(vp.x, vp.y * 0.82), Color(0.12, 0.16, 0.24, 1.0), 2.0)


static func draw(ci: CanvasItem, p: Dictionary) -> void:
	if p.has("rail"):
		draw_rail(ci, p)
		return
	var ink := Color(UiLook.col(UiLook.INK))
	var dim := Color(UiLook.col(UiLook.INK_DIM))
	var dark := Color(UiLook.col(UiLook.INK_DARK))
	var edge := Color(UiLook.col(UiLook.EDGE))
	var scrim := Color(UiLook.col(UiLook.SCRIM))
	var cfg: Dictionary = p["cfg"]
	var fs: int = p["fs"]
	var fs_s: int = p["fs_s"]
	var tm: float = p["tm"]
	var cs: float = p["cs"]
	UiText.no_outline = true
	draw_backdrop(ci)
	var card: Rect2 = p["card"]
	UiIcons.rrect(ci, card, 16.0 * cs, Color(scrim, 0.98), Color(edge, 0.55), 2.0)
	# The notice, at the top.
	var y: float = (p["notice_pos"] as Vector2).y
	for ln in p["notice_lines"]:
		UiText.draw(ci, str(ln), Vector2((p["notice_pos"] as Vector2).x, y + UiText.ascent(fs)), fs, ink, -1)
		y += float(p["lh"])
	var rows: Array = p["rows"]
	var focus_id: String = str(rows[int(p["focus"])])
	# Radio rows: the label, then each option as a ring with a dot when it is the one.
	var boxes: Dictionary = p["row_boxes"]
	for rr in p["radio_rows"]:
		var id: String = str(rr["id"])
		var box: Rect2 = boxes[id]
		var lab_y: float = box.position.y + tm * 0.5 - UiText.height(fs) * 0.5 + UiText.ascent(fs) if bool(rr["inline"]) else box.position.y + (tm * 0.5) - UiText.height(fs) * 0.5 + UiText.ascent(fs)
		UiText.draw(ci, str(rr["label"]), Vector2(box.position.x, lab_y), fs, dim, -1)
		if focus_id == id:
			UiIcons.rrect(ci, box.grow(2.0), 10.0 * cs, Color(0, 0, 0, 0), Color(ink, 0.9), 2.5)
	var chosen := {"players": str(int(cfg.get("players", 1))), "p1": str(cfg.get("p1", "kb")), "p2": str(cfg.get("p2", "kb")), "ai": level_of(cfg.get("ai_level", DEFAULT_LEVEL))}
	for it in p["items"]:
		var r: Rect2 = it["rect"]
		var kind: String = it["kind"]
		var row: String = it["row"]
		var cy: float = r.get_center().y
		if kind == "radio":
			var on: bool = str(chosen.get(row, "")) == str(it["value"])
			var rad: float = minf(tm * 0.2, 12.0 * cs + 4.0)
			var c := Vector2(r.position.x + rad + 4.0, cy)
			ci.draw_arc(c, rad, 0.0, TAU, 24, Color(ink, 0.95), 2.5, true)
			if on:
				ci.draw_circle(c, rad * 0.52, ink)
			UiText.draw(ci, str(it["label"]), Vector2(c.x + rad + 8.0 * cs, cy - UiText.height(fs) * 0.5 + UiText.ascent(fs)), fs, ink if on else dim, -1)
		elif kind == "check":
			var on2: bool = bool(cfg.get(row, true))
			var side: float = minf(tm * 0.46, 26.0 * cs + 8.0)
			var br := Rect2(r.position.x + 2.0, cy - side * 0.5, side, side)
			UiIcons.rrect(ci, br, 4.0 * cs, Color(ink, 0.92) if on2 else Color(0, 0, 0, 0), Color(ink, 0.95), 2.5)
			if on2:
				ci.draw_polyline(PackedVector2Array([Vector2(br.position.x + side * 0.2, cy), Vector2(br.position.x + side * 0.43, cy + side * 0.24), Vector2(br.position.x + side * 0.8, cy - side * 0.26)]), dark, maxf(2.5, side * 0.14), true)
			UiText.draw(ci, str(it["label"]), Vector2(br.end.x + 8.0 * cs, cy - UiText.height(fs) * 0.5 + UiText.ascent(fs)), fs, ink, -1)
			if focus_id == row:
				UiIcons.rrect(ci, r.grow(1.0), 10.0 * cs, Color(0, 0, 0, 0), Color(ink, 0.9), 2.5)
		else:
			var primary: bool = row == "start"
			var quiet: bool = row == "not_now"   # a quieter control: no fill, a thin edge, the dim ink
			UiIcons.rrect(ci, r, r.size.y * 0.3, Color(ink, 0.95) if primary else (Color(0, 0, 0, 0) if quiet else Color(scrim, 0.85)), Color(edge, 0.45 if quiet else 0.9), 1.5 if quiet else 2.0)
			UiText.draw(ci, str(it["label"]), Vector2(r.get_center().x, cy - UiText.height(fs) * 0.5 + UiText.ascent(fs)), fs, dark if primary else (dim if quiet else ink), 0)
			if focus_id == row:
				UiIcons.rrect(ci, r.grow(3.0), r.size.y * 0.34, Color(0, 0, 0, 0), Color(ink if not primary else Color(1.0, 0.85, 0.35), 1.0), 3.0)
	var sy: float = (p["sub_pos"] as Vector2).y
	for sl in p["sub_lines"]:
		UiText.draw(ci, str(sl), Vector2((p["sub_pos"] as Vector2).x, sy + UiText.ascent(fs_s)), fs_s, dim, -1)
		sy += UiText.height(fs_s) * 1.2
	if str(p["note_text"]) != "":
		var nl: PackedStringArray = UiText.wrap(str(p["note_text"]), fs_s, float(p["note_w"]))
		var ny: float = (p["note_pos"] as Vector2).y
		for ln2 in nl:
			UiText.draw(ci, str(ln2), Vector2((p["note_pos"] as Vector2).x, ny + UiText.ascent(fs_s)), fs_s, dim, -1)
			ny += UiText.height(fs_s) * 1.2
	UiText.no_outline = false


# --- The Rail layout (docs/ui/menus-rail.md) -----------------------------------------------------------------------------------

## The Rail's geometry for the start menu: the rail down the left edge with the choices (a row each; the ways to play side by side on the row, the comfort switches as toggles), and on the right Legal's notice in its own card (not mid-match),
## a card saying what the choices make, Reduce flashing's one line, and the buttons (Start in gold, Not now or Back quiet). `st` is as for `plan`, plus {device, style, since, prev, bar_since, reduced} as for UiPause.rail_plan.
## Same keys as `plan` (items, rows, row_boxes, focus, fits ...) with "rail": true; `card` is the whole screen here, because the buttons sit outside the rail. `fits` is false when it cannot hold everything; `plan` then lays the old card out.
static func rail_plan(vp: Vector2, s: float, dp: float, st: Dictionary) -> Dictionary:
	var cfg: Dictionary = st.get("cfg", {})
	var mid: bool = bool(st.get("mid_match", false))
	var not_now: bool = bool(st.get("not_now", false))
	var list: Array = rows(cfg, mid, not_now)
	var m: Dictionary = UiRail.metrics(vp, s, dp)
	var cs: float = float(m["cs"])
	var tm: float = float(m["tm"])
	var x0: float = float(m["x0"])
	var gap: float = float(m["gap"])
	var rw: float = maxf(float(m["rw"]), clampf(vp.x * 0.34, 340.0, 520.0 * maxf(cs, 1.0)))
	var rail := Rect2(0.0, 0.0, rw, vp.y)
	var rx: float = x0 * 0.55
	var row_w: float = rw - rx * 2.0
	var device: String = str(st.get("device", "kbd"))
	var style: String = str(st.get("style", "neutral"))
	var reduced: bool = bool(st.get("reduced", false))
	var fs_kicker: int = int(m["fs_kicker"])
	var fs_title: int = int(m["fs_title"])
	var fs_row: int = int(m["fs_row"])
	var fs_val: int = int(m["fs_val"])
	var fs_small: int = int(m["fs_small"])
	var floor_px: int = int(UiLook.text_floor)
	# The title block.
	var top: float = maxf(vp.y * 0.07, 28.0 * cs)
	var title: String = UiData.t("prompt.rail_start_title")
	var title_lines: PackedStringArray = UiText.wrap(title, fs_title, rw - x0 * 2.0)
	var lh_title: float = UiText.height(fs_title) * 1.1
	var y: float = top + UiText.height(fs_kicker) * 1.3
	var title_pos := Vector2(x0, y + UiText.ascent(fs_title))
	y += lh_title * float(title_lines.size()) + gap * 3.0
	# The rail's rows: every focusable row before the buttons.
	var rail_ids: Array = []
	for id0 in list:
		if str(id0) in ["start", "not_now", "back"]:
			break
		rail_ids.append(str(id0))
	var rh: float = float(m["rh"])
	var rh_sub: float = maxf(44.0 * cs, tm)
	var opt_pad: float = maxf(10.0 * cs, 8.0)
	var tog_w: float = maxf(46.0 * cs, 38.0)
	var tog_h: float = maxf(26.0 * cs, 22.0)
	var fs_r: int = fs_row
	var lo: int = maxi(int(floor(float(fs_row) * 0.8)), maxi(floor_px, 12))
	var rows_fit: bool = false
	while fs_r >= lo:
		rows_fit = true
		var fs_o: int = maxi(int(round(float(fs_val) * float(fs_r) / float(fs_row))), 11)
		for id1 in rail_ids:
			var need: float = UiText.width(word(id1), fs_r) + maxf(rh * 0.7, 24.0)
			if _is_radio(id1):
				for o in _options(id1):
					need += UiText.width(str(o[1]), fs_o) + opt_pad * 2.0 + gap
				need += 16.0 * cs
			else:
				need += tog_w + 16.0 * cs
			if need > row_w:
				rows_fit = false
		if rows_fit:
			break
		fs_r -= 1
	fs_r = maxi(fs_r, lo)
	var fs_o2: int = maxi(int(round(float(fs_val) * float(fs_r) / float(fs_row))), 11)
	var items: Array = []
	var row_boxes: Dictionary = {}
	var row_ys: Array = []
	var radio_rows: Array = []
	var yy: float = y
	for id2 in rail_ids:
		var h: float = rh if _is_radio(id2) else rh_sub
		var r := Rect2(rx, yy, row_w, h)
		row_boxes[id2] = r
		row_ys.append(yy)
		if _is_radio(id2):
			var opts: Array = _options(id2)
			var ex: float = r.end.x - maxf(h * 0.25, 10.0)
			var rects: Array = []
			for i in range(opts.size() - 1, -1, -1):
				var w: float = UiText.width(str(opts[i][1]), fs_o2) + opt_pad * 2.0
				rects.push_front(Rect2(ex - w, r.position.y, w, h))
				ex -= w + gap
			for i in range(opts.size()):
				items.append({"row": id2, "kind": "radio", "value": str(opts[i][0]), "label": str(opts[i][1]), "rect": rects[i]})
			radio_rows.append({"id": id2, "label": word(id2), "inline": true, "opt_ws": [], "h": h})
		else:
			items.append({"row": id2, "kind": "check", "value": "", "label": word(id2), "rect": r})
		yy += h + gap
	var rows_end: float = yy - gap
	# The hint strip at the foot of the rail.
	var hint_gh: float = maxf(26.0 * cs, 22.0)
	var back_word: String = UiData.t("prompt.rail_hint_not_now") if not_now else (word("back") if mid else "")
	var pairs: Array = [["move", UiData.t("prompt.rail_hint_choose")], ["accept", UiData.t("prompt.rail_hint_select")]]
	if back_word != "":
		pairs.append(["back", back_word])
	var entries: Array = UiRail.hint_entries(device, style, pairs, hint_gh, fs_small)
	var hint_lines: Array = []
	var line_w: float = 0.0
	var from_i: int = 0
	for i in range(entries.size()):
		var w2: float = float(entries[i]["w"])
		if i > from_i and line_w + gap * 3.0 + w2 > rw - x0 * 2.0:
			hint_lines.append([from_i, i])
			from_i = i
			line_w = 0.0
		line_w += (gap * 3.0 if i > from_i else 0.0) + w2
	hint_lines.append([from_i, entries.size()])
	var hint_lh: float = hint_gh * 1.5
	var hint_top: float = vp.y - maxf(vp.y * 0.04, 12.0) - hint_lh * float(hint_lines.size())
	# The right side: the notice card, the "this match" card, Reduce flashing's line, the buttons.
	var margin: float = maxf(vp.x * 0.04, 24.0)
	var cw: float = minf(vp.x - rw - margin * 2.0, 780.0 * maxf(cs, 1.0))
	var cx: float = vp.x - margin - cw
	var cp: float = maxf(24.0 * cs, 14.0)
	var inner: float = cw - cp * 2.0
	var bh: float = maxf(tm, 60.0 * cs)
	var by: float = vp.y - maxf(vp.y * 0.06, 24.0) - bh
	var fs_n: int = UiText.px(21.0, cs)
	var kv: Array = []
	var you_val: String = word("pad" if str(cfg.get("p1", "kb")) == "pad" else "kb") + ", " + word("p1")
	var against_val: String = ""
	if int(cfg.get("players", 1)) == 2:
		against_val = word("pad" if str(cfg.get("p2", "kb")) == "pad" else "kb") + ", " + word("p2")
	else:
		against_val = UiData.t("prompt.rail_the_computer") + ", " + word("ai_" + level_of(cfg.get("ai_level", DEFAULT_LEVEL)))
	kv.append([UiData.t("prompt.rail_you"), you_val])
	kv.append([UiData.t("prompt.rail_against"), against_val])
	var note_text: String = ""
	if int(cfg.get("players", 1)) == 1:
		note_text = word("one_note")
	elif str(cfg.get("p1", "kb")) == "kb" and str(cfg.get("p2", "kb")) == "kb":
		note_text = word("both_kb")
	elif bool(st.get("pad_missing", false)):
		note_text = word("no_pad")
	var sub_lines: PackedStringArray = UiText.wrap(rf_line(cfg), fs_small, cw)
	var lh_s: float = UiText.height(fs_small) * 1.2
	var fs_n_used: int = fs_n
	var cards_fit: bool = false
	var notice_lines := PackedStringArray()
	var note_lines := PackedStringArray()
	var notice_h: float = 0.0
	var sum_h: float = 0.0
	var lh_n: float = 0.0
	var kv_lh: float = 0.0
	for fs_try in range(fs_n, floor_px - 1, -1):
		fs_n_used = fs_try
		lh_n = UiText.height(fs_try) * 1.25
		kv_lh = UiText.height(fs_try) * 1.7
		notice_lines = PackedStringArray() if mid else UiText.wrap(notice(cfg), fs_try, inner)
		notice_h = 0.0 if mid else (cp * 2.0 + UiText.height(fs_kicker) * 1.5 + lh_n * float(notice_lines.size()))
		note_lines = UiText.wrap(note_text, fs_small, inner) if note_text != "" else PackedStringArray()
		sum_h = cp * 2.0 + UiText.height(fs_kicker) * 1.5 + kv_lh * float(kv.size()) + (lh_s * float(note_lines.size()) + gap if note_text != "" else 0.0)
		var total: float = top + (0.0 if mid else notice_h + gap * 2.0) + sum_h + gap * 1.5 + lh_s * float(sub_lines.size())
		if total <= by - gap:
			cards_fit = true
			break
	var notice_card := Rect2() if mid else Rect2(cx, top, cw, notice_h)
	var sum_top: float = top + (0.0 if mid else notice_h + gap * 2.0)
	var sum_card := Rect2(cx, sum_top, cw, sum_h)
	var sub_pos := Vector2(cx, sum_top + sum_h + gap * 1.5 + UiText.ascent(fs_small))
	# The buttons: Start in gold at the right end, the quiet ones to its left.
	var fs_b: int = maxi(fs_r, floor_px)
	var bpad: float = maxf(28.0 * cs, 16.0)
	var start_w: float = UiText.width(word("start"), fs_b) + bpad * 2.0
	var start_r := Rect2(vp.x - margin - start_w, by, start_w, bh)
	var bx: float = start_r.position.x - gap * 2.0
	var buttons: Array = [{"row": "start", "kind": "button", "value": "", "label": word("start"), "rect": start_r}]
	for bid in ["not_now", "back"]:
		if list.has(bid):
			var bw2: float = UiText.width(word(bid), fs_b) + bpad * 1.6
			buttons.append({"row": bid, "kind": "button", "value": "", "label": word(bid), "rect": Rect2(bx - bw2, by, bw2, bh)})
			bx -= bw2 + gap * 2.0
	for b in buttons:
		items.append(b)
		row_boxes[str(b["row"])] = b["rect"]
	# Fit.
	var fits: bool = rows_fit and cards_fit and rows_end + gap <= hint_top and title_lines.size() <= 2
	for tl in title_lines:
		if UiText.width(str(tl), fs_title) > rw - x0 * 1.5:
			fits = false
	fits = fits and cw >= 300.0 * minf(cs, 1.0) and bx + gap * 2.0 >= rw + gap
	for kvp in kv:
		if UiText.width(str(kvp[0]), fs_n_used) + UiText.width(str(kvp[1]), fs_n_used) + gap * 3.0 > inner:
			fits = false
	fits = fits and UiPause.hints_fit(entries, hint_lines, gap * 3.0, rw - x0 * 2.0)
	var screen := Rect2(Vector2.ZERO, vp)
	for it in items:
		var rr: Rect2 = it["rect"]
		if not screen.encloses(rr) or rr.size.y < tm - 0.01:
			fits = false
	for i in range(items.size()):
		for j in range(i + 1, items.size()):
			if (items[i]["rect"] as Rect2).intersects(items[j]["rect"]):
				fits = false
	var focus: int = clampi(int(st.get("focus", 0)), 0, list.size() - 1)
	var bar_since: float = float(st.get("bar_since", 99.0))
	var prev: int = int(st.get("prev", -1))
	var bar_vis: bool = focus < rail_ids.size()
	return {"rail": true, "card": screen, "rail_rect": rail, "title": title, "title_lines": title_lines, "title_pos": title_pos, "kicker": UiData.t("prompt.rail_kicker"), "kicker_pos": Vector2(x0, top + UiText.ascent(fs_kicker)), "lh_title": lh_title,
		"items": items, "rows": list, "row_boxes": row_boxes, "row_ys": row_ys, "rail_ids": rail_ids, "radio_rows": radio_rows, "fs": fs_r, "fs_o": fs_o2, "fs_s": fs_small, "fs_kicker": fs_kicker, "fs_title": fs_title, "fs_val": fs_val, "fs_n": fs_n_used, "fs_b": fs_b,
		"fits": fits, "tm": tm, "pad": cp, "gap": gap, "cs": cs, "focus": focus, "touch": false, "cfg": cfg, "stack": false, "total_h": vp.y, "area_h": vp.y, "x0": x0, "tog": Vector2(tog_w, tog_h),
		"notice_card": notice_card, "notice_lines": notice_lines, "notice_pos": notice_card.position, "lh": lh_n, "mid": mid, "sum_card": sum_card, "kv": kv, "kv_lh": kv_lh, "note_text": note_text, "note_lines": note_lines, "note_pos": Vector2(), "note_w": inner, "lh_s": lh_s,
		"sub_lines": sub_lines, "sub_pos": sub_pos, "hints": entries, "hint_lines": hint_lines, "hint_gh": hint_gh, "hint_fs": fs_small, "hint_top": hint_top, "hint_lh": hint_lh, "device": device, "style": style, "vp_y": vp.y,
		"slide": UiRail.slide(float(st.get("since", 99.0)), reduced), "bar_t": 1.0 if (reduced or prev < 0) else clampf(bar_since / UiRail.BAR_SECS, 0.0, 1.0),
		"bar_y": UiRail.bar_y(row_ys, focus, prev, bar_since, reduced) if bar_vis else 0.0, "bar_vis": bar_vis}


static func _is_radio(id: String) -> bool:
	return id in ["players", "p1", "p2", "ai"]


static func draw_rail(ci: CanvasItem, p: Dictionary) -> void:
	var vp: Vector2 = ci.size if ci is Control else Vector2(1920, 1080)
	var cs: float = float(p["cs"])
	var cfg: Dictionary = p["cfg"]
	var rail: Rect2 = p["rail_rect"]
	var sl: float = float(p["slide"])
	var off: float = -(1.0 - sl) * rail.size.x   # the rail slides in from its own edge, the right side from the right edge
	var coff: float = (1.0 - sl) * (vp.x - rail.size.x)
	var shift := Vector2(off, 0.0)
	var cshift := Vector2(coff, 0.0)
	var ink := Color(UiLook.col(UiLook.INK))
	var dim := Color(UiLook.col(UiLook.INK_DIM))
	var dark := Color(UiLook.col(UiLook.INK_DARK))
	var focus_id: String = str((p["rows"] as Array)[int(p["focus"])])
	UiText.no_outline = true
	ci.draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.03, 0.06, 1.0))   # a plain dark ground: the Rail is the frame, so no ground line behind it
	UiRail.draw_panel(ci, rail, off)
	UiText.draw(ci, str(p["kicker"]).to_upper(), (p["kicker_pos"] as Vector2) + shift, int(p["fs_kicker"]), Color(dim, 0.9), -1)
	var tp: Vector2 = (p["title_pos"] as Vector2) + shift
	for tl in p["title_lines"]:
		UiText.draw(ci, str(tl), tp, int(p["fs_title"]), ink, -1)
		tp.y += float(p["lh_title"])
	var boxes: Dictionary = p["row_boxes"]
	var by: float = float(p["bar_y"])
	var fs: int = int(p["fs"])
	var fs_o: int = int(p["fs_o"])
	var rail_ids: Array = p["rail_ids"]
	if bool(p["bar_vis"]) and not rail_ids.is_empty():
		var r0: Rect2 = boxes[rail_ids[0]]
		UiRail.draw_bar(ci, Rect2(Vector2(r0.position.x + off, by), r0.size), cs)
	for id in rail_ids:
		var r: Rect2 = boxes[id]
		var rs := Rect2(r.position + shift, r.size)
		var lit: bool = bool(p["bar_vis"]) and absf(r.position.y - by) < r.size.y * 0.5
		UiRail.draw_row_text(ci, rs, word(id), "", lit, fs, int(p["fs_val"]))
		if _is_radio(id):
			var chosen: String = str(int(cfg.get("players", 1))) if id == "players" else (level_of(cfg.get("ai_level", DEFAULT_LEVEL)) if id == "ai" else str(cfg.get(id, "kb")))
			for it in p["items"]:
				if str(it["row"]) != id or str(it["kind"]) != "radio":
					continue
				var orc: Rect2 = it["rect"]
				var o_r := Rect2(orc.position + shift, orc.size)
				var on: bool = str(it["value"]) == chosen
				if on:
					var inset: float = maxf(o_r.size.y * 0.16, 4.0)
					UiIcons.rrect(ci, o_r.grow_individual(0.0, -inset, 0.0, -inset), o_r.size.y * 0.3, UiRail.GOLD if lit else Color(ink, 0.16), Color(0, 0, 0, 0) if lit else Color(ink, 0.7), 1.5)
				var tcol: Color = (dark if on else Color(dark, 0.65)) if lit else (ink if on else Color(dim, 0.9))
				UiText.draw(ci, str(it["label"]), Vector2(o_r.get_center().x, o_r.get_center().y + float(fs_o) * 0.35), fs_o, tcol, 0)
		else:
			var tg: Vector2 = p["tog"]
			var on2: bool = bool(cfg.get(id, true))
			var tr := Rect2(rs.end.x - maxf(rs.size.y * 0.3, 12.0) - tg.x, rs.get_center().y - tg.y * 0.5, tg.x, tg.y)
			var track: Color = (dark if on2 else Color(dark, 0.3)) if lit else (Color(ink, 0.92) if on2 else Color(ink, 0.18))
			UiIcons.rrect(ci, tr, tg.y * 0.5, track, Color(dark, 0.7) if lit else Color(ink, 0.6), 1.5)
			var kx: float = tr.end.x - tg.y * 0.5 if on2 else tr.position.x + tg.y * 0.5
			var knob: Color = (ink if on2 else Color(dark, 0.8)) if lit else (dark if on2 else Color(dim, 0.95))
			ci.draw_circle(Vector2(kx, tr.get_center().y), tg.y * 0.34, knob)
	# The hint strip.
	var entries: Array = p["hints"]
	var hy: float = float(p["hint_top"]) + float(p["hint_lh"]) * 0.5
	for ln in p["hint_lines"]:
		UiRail.draw_hints(ci, entries.slice(int(ln[0]), int(ln[1])), float(p["x0"]) + off, hy, float(p["hint_gh"]), int(p["hint_fs"]), float(p["gap"]) * 3.0, 1.0)
		hy += float(p["hint_lh"])
	# The right side: the notice, what the choices make, Reduce flashing's line, the buttons.
	var fs_n: int = int(p["fs_n"])
	if not bool(p["mid"]):
		var nc: Rect2 = p["notice_card"]
		var lines: Array = []
		for nl0 in p["notice_lines"]:
			lines.append({"t": str(nl0), "dim": false})
		UiRail.draw_card(ci, Rect2(nc.position + cshift, nc.size), UiData.t("prompt.rail_read_first"), lines, int(p["fs_kicker"]), fs_n, cs)
	var sc: Rect2 = p["sum_card"]
	var src := Rect2(sc.position + cshift, sc.size)
	UiRail.draw_card(ci, src, UiData.t("prompt.rail_this_match"), [], int(p["fs_kicker"]), fs_n, cs)
	var cp: float = float(p["pad"])
	var ky: float = src.position.y + cp + UiText.height(int(p["fs_kicker"])) * 1.5
	for kvp in p["kv"]:
		var base: float = ky + float(p["kv_lh"]) * 0.5 + float(fs_n) * 0.35
		UiText.draw(ci, str(kvp[0]), Vector2(src.position.x + cp, base), fs_n, Color(dim, 0.95), -1)
		UiText.draw(ci, str(kvp[1]), Vector2(src.end.x - cp, base), fs_n, ink, 1)
		ky += float(p["kv_lh"])
	if str(p["note_text"]) != "":
		var ny: float = ky + 2.0
		for nl in p["note_lines"]:
			UiText.draw(ci, str(nl), Vector2(src.position.x + cp, ny + UiText.ascent(int(p["fs_s"]))), int(p["fs_s"]), Color(dim, 0.95), -1)
			ny += float(p["lh_s"])
	var sy: float = (p["sub_pos"] as Vector2).y
	for sln in p["sub_lines"]:
		UiText.draw(ci, str(sln), Vector2((p["sub_pos"] as Vector2).x + coff, sy), int(p["fs_s"]), Color(dim, 0.95), -1)
		sy += float(p["lh_s"])
	for it2 in p["items"]:
		if str(it2["kind"]) != "button":
			continue
		var br: Rect2 = it2["rect"]
		var brs := Rect2(br.position + cshift, br.size)
		var primary: bool = str(it2["row"]) == "start"
		UiIcons.rrect(ci, brs, brs.size.y * 0.25, UiRail.GOLD if primary else Color(0, 0, 0, 0), Color(0, 0, 0, 0) if primary else Color(ink, 0.9), 1.8)
		UiText.draw(ci, str(it2["label"]), Vector2(brs.get_center().x, brs.get_center().y + float(p["fs_b"]) * 0.35), int(p["fs_b"]), Color(0.09, 0.07, 0.04) if primary else ink, 0)
		if focus_id == str(it2["row"]):
			UiIcons.rrect(ci, brs.grow(4.0 * cs), brs.size.y * 0.3, Color(0, 0, 0, 0), ink, 3.0)
	UiText.no_outline = false
