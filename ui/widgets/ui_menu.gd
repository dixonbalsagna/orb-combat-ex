class_name UiMenu
extends RefCounted
## The start menu (docs/ui/start-menu.md): the first thing a visitor sees, over a still dark background with no match playing: the flashing-effects notice at the top, radio
## buttons for how many play and on what, checkboxes for the settings that matter most, and one Start button. It is also the way back after a match. `plan` is pure geometry (so
## hud_check proves every control is a 48 dp target inside the card at every size), `hit` says what a point is on, `draw` paints from a plan. Every word is in terms.json
## (prompt.menu_*). Nothing here touches the sim: the HUD hands the choices to the host when Start is pressed.

const ROW_IDS: Array = ["players", "p1", "p2", "intros", "reduce_flashing", "shake", "captions", "guide", "start", "not_now", "back"]
const CHECKS: Array = ["intros", "reduce_flashing", "shake", "captions", "guide"]


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
	out.append_array(checks())
	out.append("start")
	if not_now:
		out.append("not_now")
	if mid_match:
		out.append("back")
	return out


static func plan(vp: Vector2, s: float, dp: float, touch: bool, st: Dictionary) -> Dictionary:
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
			for id0 in ["players", "p1", "p2"]:
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
			for id in ["players", "p1", "p2"]:
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
	var c: Rect2 = p["card"]
	var cfg: Dictionary = p["cfg"]
	return [int(c.size.x), int(c.size.y), int(c.position.x), int(c.position.y), int(p["focus"]), int(p["fs"]), int(cfg.get("players", 1)), str(cfg.get("p1", "")), str(cfg.get("p2", "")),
		bool(cfg.get("intros", true)), bool(cfg.get("reduce_flashing", true)), bool(cfg.get("shake", true)), bool(cfg.get("captions", true)), bool(cfg.get("guide", true)), str(p["note_text"]), bool(p["touch"])]


static func draw_backdrop(ci: CanvasItem) -> void:
	var vp: Vector2 = ci.size if ci is Control else Vector2(1920, 1080)
	ci.draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.03, 0.06, 1.0))
	# A still, calm ground line low on the screen, so it reads as a place and not an error.
	ci.draw_rect(Rect2(0.0, vp.y * 0.82, vp.x, vp.y * 0.18), Color(0.04, 0.06, 0.1, 1.0))
	ci.draw_line(Vector2(0.0, vp.y * 0.82), Vector2(vp.x, vp.y * 0.82), Color(0.12, 0.16, 0.24, 1.0), 2.0)


static func draw(ci: CanvasItem, p: Dictionary) -> void:
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
	var chosen := {"players": str(int(cfg.get("players", 1))), "p1": str(cfg.get("p1", "kb")), "p2": str(cfg.get("p2", "kb"))}
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
