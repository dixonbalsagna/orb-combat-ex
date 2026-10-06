class_name UiHowto
extends RefCounted
## The How to play card (docs/ui/hud-spec.md section 17): three short pages, shown on the first run and from the pause menu.
##   1. What you control                 (the core idea and the four held states: press, guard, dodge, escape)
##   2. Controls                         (the keys, pad glyphs or touch controls of the player's own device)
##   3. Reading the fight                (the few HUD reads: crown, cards, brink, windows, finisher rings, toll, strip)
## Every word is data (ui/data/howto.json). `plan` is pure geometry, so hud_check can prove that every page fits at every size and
## that every button is a real touch target; `draw` paints from a plan. The card scales with the screen and its density (text is at
## least the HUD's floor, 12 dp on a phone) and shrinks its type until a page fits, rather than clipping.

const PAGE_PAD := 24.0
const FIRST_PAGE := 0


## The pages that are reference, not gameplay: the first run's card leaves them out (the player finds them from the pause menu's About entry).
const REFERENCE_PAGES: Array = ["about", "about_more", "licences"]


## The pages the card shows: all of them, or for the first run only the gameplay pages (they come first, so the page indexes are the same).
static func pages_for(first_run: bool) -> Array:
	var pages: Array = UiData.howto().get("pages", [])
	if not first_run:
		return pages
	var out: Array = []
	for pg in pages:
		if not REFERENCE_PAGES.has(str((pg as Dictionary).get("id", ""))):
			out.append(pg)
	return out


static func page_count(first_run: bool = false) -> int:
	return pages_for(first_run).size()


## Whether an About-page sentence named by its icon is shown: the privacy line for the feedback target in use (none, github, or a private mailto or form),
## and any other `about_` item while its flag in features.json is on.
static func about_shown(icon_name: String) -> bool:
	if icon_name.begins_with("about_privacy_"):
		return icon_name == "about_privacy_" + privacy_kind()
	return UiData.feature(icon_name)


## Which privacy line is true: the feedback button's target (send.json `_target`, with the address it needs) as none, github or private.
static func privacy_kind() -> String:
	match UiFeedback.send_target():
		"github":
			return "github"
		"mailto", "form":
			return "private"
	return "none"


## The index of the page with this id (the About page is "about"), or -1.
static func page_index(id: String) -> int:
	var pages: Array = UiData.howto().get("pages", [])
	for i in range(pages.size()):
		if str((pages[i] as Dictionary).get("id", "")) == id:
			return i
	return -1


## The geometry of page `page_i` for a viewport: {card, title, close, back, next, dots, items[], cs, fits, tm, ...}. `device` is the
## glyph family ("kbd", "xbox", ...), `slot` the player's slot (P1 or P2 keys), `touch` true for the touch controls page.
static func plan(vp: Vector2, s: float, dp: float, touch: bool, page_i: int, device: String = "kbd", slot: int = 0, preset: String = "", style: String = "neutral", extra: Dictionary = {}) -> Dictionary:
	var data: Dictionary = UiData.howto()
	var pages: Array = pages_for(bool(extra.get("first_run", false)))
	var n: int = pages.size()
	var pi: int = clampi(page_i, 0, maxi(n - 1, 0))
	var page: Dictionary = pages[pi] if n > 0 else {}
	var tm: float = maxf(48.0 * dp, 44.0)
	var margin: float = maxf(vp.x * 0.03, 12.0)
	var my: float = maxf(vp.y * 0.04, 10.0)
	var cw: float = minf(vp.x - 2.0 * margin, maxf(1500.0 * s, 560.0))
	var ch: float = vp.y - 2.0 * my   # as tall as the screen allows: the card then takes only the height its tallest page needs
	var card := Rect2((vp.x - cw) * 0.5, (vp.y - ch) * 0.5, cw, ch)
	var cs: float = maxf(s, 0.3)
	var cs_min: float = UiLook.text_floor / 24.0
	var need_h: float = 0.0
	var all_fit: bool = true
	# Lay every page out at one scale so the card keeps one size across pages; shrink the type until all of them fit. At the smallest type a page that
	# still does not fit is laid out tight (rows and gaps closer together) before the card gives up: the shared keyboard's Controls page, with its extra note,
	# needed that on a phone and at density 2.
	var tight := false
	var ex: Dictionary = extra.duplicate()
	while true:
		ex["tight"] = tight
		need_h = 0.0
		all_fit = true
		for k in range(n):
			var r: Dictionary = _layout(card, cs, tm, touch, pages[k], k, n, device, slot, data, preset, style, ex)
			need_h = maxf(need_h, float(r["need_h"]))
			all_fit = all_fit and bool(r["fits"])
		if all_fit or (cs <= cs_min + 0.001 and tight):
			break
		if cs <= cs_min + 0.001:
			tight = true
			continue
		cs = maxf(cs_min, cs - 0.04)
	# The card is as tall as its tallest page needs (centred), not the whole screen.
	var h2: float = minf(ch, maxf(need_h, 240.0 * cs))
	card = Rect2(card.position.x, (vp.y - h2) * 0.5, cw, h2)
	var ex_final: Dictionary = ex.duplicate()
	ex_final["final"] = true   # only the shown page wraps the licence text (about 90,000 characters)
	var out: Dictionary = _layout(card, cs, tm, touch, page, pi, n, device, slot, data, preset, style, ex_final)
	out["fits"] = all_fit
	out["tight"] = tight
	out["page"] = pi
	out["pages"] = n
	out["tm"] = tm
	return out


static func _layout(card: Rect2, cs: float, tm: float, touch: bool, page: Dictionary, pi: int, n: int, device: String, slot: int, data: Dictionary, preset: String = "", style: String = "neutral", extra: Dictionary = {}) -> Dictionary:
	var pad: float = maxf(PAGE_PAD * cs, 10.0)
	var fs_title: int = UiText.px(36.0, cs)
	var fs_body: int = UiText.px(24.0, cs)
	var fs_small: int = UiText.px(19.0, cs)
	var lh: float = UiText.height(fs_body) * 1.12
	var btn_h: float = maxf(tm, 44.0 * cs)
	var inner := Rect2(card.position + Vector2(pad, pad), card.size - Vector2(pad, pad) * 2.0)
	# Header: the page title, the close button at the right.
	var close_sz: float = maxf(tm, 40.0 * cs)
	var close := Rect2(card.end.x - pad - close_sz, card.position.y + pad * 0.6, close_sz, close_sz)
	var title_h: float = maxf(UiText.height(fs_small) * 1.1 + UiText.height(fs_title), close_sz)
	var body_top: float = inner.position.y + title_h + pad * 0.9
	var footer := Rect2(inner.position.x, card.end.y - pad - btn_h, inner.size.x, btn_h)
	var body := Rect2(inner.position.x, body_top, inner.size.x, footer.position.y - pad * 0.6 - body_top)
	var back_w: float = maxf(tm * 2.0, 120.0 * cs)
	var next_w: float = maxf(tm * 2.0, 140.0 * cs)
	var back := Rect2(footer.position.x, footer.position.y, back_w, btn_h)
	var nxt := Rect2(footer.end.x - next_w, footer.position.y, next_w, btn_h)
	var dots: Array = []
	var dot_r: float = clampf(btn_h * 0.08, 4.0, 14.0)
	var dot_gap: float = dot_r * 3.4
	for i in range(n):
		dots.append(Vector2(footer.position.x + footer.size.x * 0.5 + (float(i) - float(n - 1) * 0.5) * dot_gap, footer.position.y + btn_h * 0.5))
	# The items, in columns. Two columns when the body is wide; items carry their own column in the data (col 0 or 1).
	var items: Array = page.get("items", [])
	if touch and page.has("touch_items"):
		items = page["touch_items"]
	var stances_page: bool = str(page.get("id", "")) == "stances"   # its items are the page's notes; the table is laid out below
	if stances_page:
		items = []
	var cols: int = 2 if body.size.x >= float(fs_body) * 38.0 else 1
	var gap: float = maxf(pad * 0.7, 8.0)
	var colw: float = (body.size.x - gap * float(cols - 1)) / float(cols)
	var heights: Array = [0.0, 0.0]
	var placed: Array = []
	var tight: bool = bool(extra.get("tight", false))
	var isz: float = maxf(34.0 * cs, float(fs_body) * (1.35 if tight else 1.7))
	var item_gap: float = maxf(10.0 * cs, 5.0) * (0.55 if tight else 1.0)
	# Stance rows put the stance's name and its line side by side; the names share one column width.
	var name_w: float = 0.0
	for it0 in items:
		if str(it0.get("stance", "")) != "":
			name_w = maxf(name_w, UiText.width(UiData.t("stance." + str(it0["stance"])), fs_body))
	name_w += gap
	for it in items:
		var col: int = mini(int(it.get("col", 0)), cols - 1) if cols == 2 else 0
		if it.has("note") and str(it["note"]) == "kbd_p2" and not preset.begins_with("kb-shared"):
			continue
		if (it.has("action") or it.has("actions")) and not touch:
			# A row for an action the player's layout does not bind is left out.
			var first: String = str((it["actions"] as Array)[0]) if it.has("actions") else str(it["action"])
			if not UiGlyphs.bound(preset, first, slot):
				continue
		var icon_name: String = str(it.get("icon", ""))
		if icon_name.begins_with("three_") and not UiStance.three():
			continue   # a line that is true only under the three strengths (features.json)
		if icon_name.begins_with("first_run_") and not bool(extra.get("first_run", false)):
			continue   # a line only the first run's card carries (where to find About)
		if icon_name.begins_with("about_") and not about_shown(icon_name):
			continue   # a sentence of the About pages that is true only while its flag is on (features.json), or for the feedback target in use (send.json)
		var x: float = body.position.x + float(col) * (colw + gap)
		var y: float = body.position.y + float(heights[col])
		var rec: Dictionary = {"item": it, "col": col, "fs": fs_body, "fs_small": fs_small}
		var text: String = str(it.get("text", ""))
		if it.has("action") and UiStance.three() and ["heavy", "signature"].has(str(it["action"])):
			text = UiData.t("prompt.three_howto_" + str(it["action"]))   # Y is the medium and B the heavy; the signature is the power button held with B
		if it.has("action") and UiHints.HOLD_STANCES.has(str(it["action"])):
			var hw: String = UiStance.howto_word(int(UiHints.HOLD_STANCES[str(it["action"])]))   # the stance button's row, named for its stance once the stance is live
			if hw != "":
				text = hw
		if it.has("heading"):
			if float(heights[col]) > 0.0:
				heights[col] = float(heights[col]) + item_gap * 1.5
				y = body.position.y + float(heights[col])
			var hh: float = UiText.height(fs_body) * 1.25
			rec["rect"] = Rect2(x, y, colw, hh)
			rec["kind"] = "heading"
			rec["lines"] = PackedStringArray([str(it["heading"])])
			heights[col] = float(heights[col]) + hh + item_gap * 0.5
		elif it.has("note"):
			var ntext: String = str(data.get("reopen", "")) if str(it["note"]) == "reopen" else text
			var lines_n: PackedStringArray = UiText.wrap(ntext, fs_small, colw)
			var hn: float = float(lines_n.size()) * UiText.height(fs_small) * 1.12 + 2.0
			rec["rect"] = Rect2(x, y, colw, hn)
			rec["kind"] = "note"
			rec["lines"] = lines_n
			heights[col] = float(heights[col]) + hn + item_gap
		elif it.has("action") or it.has("actions"):
			var acts: Array = it["actions"] if it.has("actions") else [it["action"]]
			var gh: float = isz
			var specs: Array = UiGlyphs.group_specs(acts, device, slot, style, preset)
			var gw_total: float = 0.0
			for sp in specs:
				gw_total += UiGlyphs.width_spec(sp, gh) + gh * 0.08
			var label_x: float = x + maxf(gw_total, isz * 2.2) + gap
			var lines_a: PackedStringArray = UiText.wrap(text, fs_body, maxf(colw - (label_x - x), 20.0))
			var ha: float = maxf(isz, float(lines_a.size()) * lh) + 2.0
			rec["rect"] = Rect2(x, y, colw, ha)
			rec["kind"] = "action"
			rec["acts"] = acts
			rec["specs"] = specs
			rec["gh"] = gh
			rec["label_x"] = label_x
			rec["lines"] = lines_a
			heights[col] = float(heights[col]) + ha + item_gap
		else:
			var plain: bool = icon_name == "" or icon_name.begins_with("about_") or icon_name.begins_with("first_run_") or icon_name.begins_with("three_")   # a text-only paragraph (the About page): no icon, the whole column
			var tx: float = x if plain else x + isz + gap * 0.8
			var st: String = str(it.get("stance", ""))
			var lines_i: PackedStringArray = UiText.wrap(text, fs_body, maxf(colw - (tx - x) - (name_w if st != "" else 0.0), 20.0))
			var hi: float = (float(lines_i.size()) * lh if plain else maxf(isz, float(lines_i.size()) * lh)) + 2.0
			rec["rect"] = Rect2(x, y, colw, hi)
			rec["kind"] = "icon"
			rec["plain"] = plain
			rec["icon_c"] = Vector2(x + isz * 0.5, y + isz * 0.5)
			rec["isz"] = isz
			rec["text_x"] = tx
			rec["name_w"] = name_w if st != "" else 0.0
			rec["lines"] = lines_i
			rec["stance"] = st
			heights[col] = float(heights[col]) + hi + item_gap
		placed.append(rec)
	var tallest: float = maxf(float(heights[0]), float(heights[1]))
	var st: Dictionary = {}
	if stances_page:
		st = _stances_block(page, body, tm, touch, device, slot, preset, style, extra, fs_body, fs_small, gap * (0.6 if tight else 1.0), isz * (0.85 if tight else 1.0))
		tallest = float(st["tallest"]) + item_gap
	# The fit: the tallest column is inside the body, every line is inside its column, and the title clears the close button.
	var lic: Dictionary = {}
	if str(page.get("id", "")) == "licences":
		lic = _licences_block(body, float(heights[0]), item_gap, fs_small, cs, bool(extra.get("final", false)), int(extra.get("scroll", 0)))
		tallest = float(lic["tallest"]) + item_gap
	var fits: bool = tallest - item_gap <= body.size.y + 0.5 and (st.is_empty() or bool(st["fits"])) and (lic.is_empty() or bool(lic["fits"]))
	var title_text: String = str(page.get("title", ""))
	var dl: Dictionary = page.get("device_label", {})
	if not dl.is_empty():
		title_text += ": " + str(dl.get("touch" if touch else device, ""))
	var kicker: String = str(data.get("title", ""))
	var title_w: float = UiText.width(title_text, fs_title)
	if inner.position.x + title_w > close.position.x - pad * 0.5:
		fits = false
	# What the card needs in height for this page: the header, the tallest column, the footer and the paddings.
	var need_h: float = (body_top - card.position.y) + tallest - item_gap + pad * 0.6 + btn_h + pad
	return {"need_h": need_h, "card": card, "inner": inner, "body": body, "close": close, "back": back, "next": nxt, "dots": dots, "dot_r": dot_r, "items": placed, "cs": cs, "fits": fits,
		"fs_title": fs_title, "fs_body": fs_body, "fs_small": fs_small, "lh": lh, "btn_h": btn_h, "pad": pad, "title_text": title_text, "kicker": kicker,
		"title_h": title_h, "tallest": tallest, "is_last": pi >= n - 1, "is_first": pi <= 0, "cols": cols, "stances": st, "licences": lic}


## The scrolling area of the third-party licences page, under its intro line: {rect, rows, lh, fits, tallest, total, top, max, lines, bar, thumb, fs}.
## `lines` (the visible window, from line `top`) are filled only for the shown page (`final`): wrapping the engine's licence texts is not done in the fit passes.
static func _licences_block(body: Rect2, used_h: float, item_gap: float, fs_small: int, cs: float, final: bool, scroll: int) -> Dictionary:
	var lhs: float = UiText.height(fs_small) * 1.15
	var top: float = body.position.y + used_h + item_gap
	var bar_w: float = maxf(6.0 * cs, 5.0)
	var area := Rect2(body.position.x, top, body.size.x, maxf(body.end.y - top, 0.0))
	var rows: int = int(area.size.y / lhs)
	var min_rows := 4
	var out := {"rect": area, "rows": rows, "lh": lhs, "fits": rows >= min_rows, "tallest": used_h + item_gap + float(min_rows) * lhs, "total": 0, "top": 0, "max": 0, "lines": [], "bar": Rect2(), "thumb": Rect2(), "fs": fs_small}
	if not final or rows < 1:
		return out
	var lines: Array = UiLicences.lines(area.size.x - bar_w - 8.0 * cs, fs_small)
	var total: int = lines.size()
	var mx: int = maxi(0, total - rows)
	var t: int = clampi(scroll, 0, mx)
	out["total"] = total
	out["max"] = mx
	out["top"] = t
	out["lines"] = lines.slice(t, mini(total, t + rows))
	var track := Rect2(area.end.x - bar_w, area.position.y, bar_w, float(rows) * lhs)
	var th: float = maxf(track.size.y * float(rows) / float(maxi(total, 1)), minf(track.size.y, 24.0 * cs))
	var ty: float = track.position.y + (track.size.y - th) * (float(t) / float(mx) if mx > 0 else 0.0)
	out["bar"] = track
	out["thumb"] = Rect2(track.position.x, ty, bar_w, th)
	return out


const FACE_ACTIONS: Array = ["light", "heavy", "context", "signature"]   # X, Y, A, B as the layout binds them
const FACE_KEYS: Array = ["x", "y", "a", "b"]


## The words under a stance's face button: the stance's own name for it once the stance is live, what the button really does today (the legend's old
## word for that layout) otherwise. The page promises nothing the game does not have, and a column fills in when its flag flips.
static func _cell_text(kind: int, row: int, preset: String) -> String:
	if UiStance.live(kind):
		var c: String = UiStance.cell(kind, FACE_KEYS[row])
		if c != "":
			return c
	return UiHints.old_label(preset, FACE_ACTIONS[row])


## The stances page (docs/ui/key-help-plan.md step C): five stances across and the four face buttons down, with the player's own glyphs on both axes; on a
## narrow screen one stance at a time with five tabs. Simple and Simple touch get one line and no table (the game picks the stance). Pure geometry.
static func _stances_block(page: Dictionary, body: Rect2, tm: float, touch: bool, device: String, slot: int, preset: String, style: String, extra: Dictionary, fs_body: int, fs_small: int, gap: float, isz: float) -> Dictionary:
	var notes := {}
	for it in page.get("items", []):
		notes[str(it.get("icon", ""))] = str(it.get("text", ""))   # the page's lines are icon-row items whose `icon` names the line (the howto schema allows any icon name)
	var full_touch: bool = bool(extra.get("full_touch", false))
	var simple: bool = preset == "simple-pad" or (touch and not full_touch)
	var held: int = clampi(int(extra.get("held", 0)), 0, 4)
	var sel: int = clampi(int(extra.get("tab", -1)), -1, 4)
	if sel < 0:
		sel = held
	var out := {"mode": "none", "tallest": 0.0, "fits": true, "heads": [], "cells": [], "rowheads": [], "tabs": [], "tab_w": 0.0, "notes": [], "held": held, "sel": sel, "title": null}
	var lh_s: float = UiText.height(fs_small) * 1.12
	var lh_b: float = UiText.height(fs_body) * 1.12
	var note_fs: int = fs_small
	var note_texts: Array = []
	if simple:
		note_texts = [str(notes.get("stances_simple", ""))]
	else:
		if touch:
			note_texts = [str(notes.get("stances_table_touch", ""))]
		else:
			# The line names the player's own inputs: {defensive}, {energy}, {charging} and {manoeuvre} become the keys or buttons that hold them in the layout.
			var line: String = str(notes.get("stances_table", ""))
			for k in range(1, 5):
				var parts := PackedStringArray()
				for sp in UiGlyphs.specs_for(UiPrompts.STANCE_ACTIONS[k], device, slot, style, preset):
					parts.append(str(sp.get("label", "")))
				line = line.replace("{%s}" % UiStance.id(k), " ".join(parts))
			note_texts = [line]
		if full_touch:
			note_texts.append(str(notes.get("stances_full", "")))
	var gh: float = float(fs_small) * 1.5
	# The row heads: the layout's own glyphs for X, Y, A and B (the words on Full touch's buttons on a touch screen).
	var head_w := 0.0
	var head_specs: Array = []
	for a in FACE_ACTIONS:
		var specs: Array = []
		var w := 0.0
		if touch:
			var word: String = UiData.t("prompt.full_" + a)
			w = UiText.width(word, fs_small)
			specs = [{"word": word}]
		else:
			specs = UiGlyphs.group_specs([a], device, slot, style, preset)
			for sp in specs:
				w += UiGlyphs.width_spec(sp, gh) + gh * 0.08
		head_specs.append(specs)
		head_w = maxf(head_w, w)
	head_w += gap
	var y: float = body.position.y
	if not simple:
		var col_w: float = (body.size.x - head_w - gap * 5.0) / 5.0
		var need: float = UiText.width("Utility special", fs_small) * 0.62 + gap
		var names_w := 0.0
		for k in range(5):
			names_w = maxf(names_w, UiText.width(UiStance.word(k), fs_small))
		var wide: bool = col_w >= maxf(need, names_w + gap)
		if wide:
			out["mode"] = "table"
			var ih: float = isz * 0.8
			var hold_h: float = gh
			var head_h: float = ih + float(fs_small) * 1.3 + (0.0 if touch else hold_h) + gap
			for k in range(5):
				var cx: float = body.position.x + head_w + gap * 0.5 + float(k) * (col_w + gap)
				var hspecs: Array = []
				if not touch and UiPrompts.STANCE_ACTIONS[k] != "":
					hspecs = UiGlyphs.specs_for(UiPrompts.STANCE_ACTIONS[k], device, slot, style, preset)
				(out["heads"] as Array).append({"kind": k, "rect": Rect2(cx, y, col_w, head_h), "icon_c": Vector2(cx + col_w * 0.5, y + ih * 0.5), "icon_sz": ih, "name_y": y + ih + float(fs_small) * 0.95,
					"specs": hspecs, "hold_y": y + ih + float(fs_small) * 1.3 + hold_h * 0.5, "enter": str(UiData.stances().get("stances", {}).get(UiStance.id(k), {}).get("enter", "")) if (UiPrompts.STANCE_ACTIONS[k] == "" and not touch) else ""})
			y += head_h
			for r in range(4):
				var lines_max := 1
				var cell_lines: Array = []
				for k in range(5):
					var ls: PackedStringArray = UiText.wrap(_cell_text(k, r, preset), fs_small, maxf(col_w - gap, 20.0))
					cell_lines.append(ls)
					lines_max = maxi(lines_max, ls.size())
				var rh: float = maxf(gh, float(lines_max) * lh_s) + gap * 0.6
				(out["rowheads"] as Array).append({"rect": Rect2(body.position.x, y, head_w, rh), "specs": head_specs[r], "y": y + rh * 0.5 - gap * 0.3, "gh": gh})
				for k in range(5):
					var cx2: float = body.position.x + head_w + gap * 0.5 + float(k) * (col_w + gap)
					(out["cells"] as Array).append({"kind": k, "row": r, "rect": Rect2(cx2, y, col_w, rh), "lines": cell_lines[k], "fs": fs_small, "lh": lh_s})
				y += rh
		else:
			out["mode"] = "tabs"
			var tab_w: float = body.size.x / 5.0
			out["tab_w"] = tab_w
			out["fits"] = tab_w >= tm - 0.5   # each tab is a touch target
			var tab_h: float = tm
			for k in range(5):
				(out["tabs"] as Array).append({"kind": k, "rect": Rect2(body.position.x + float(k) * tab_w, y, tab_w, tab_h), "named": tab_w >= UiText.width(UiStance.word(k), fs_small) + isz * 0.7 + gap * 2.0})
			y += tab_h + gap
			# The selected stance: its icon, full name and the button that holds it; then its one line (only if live), then the four rows.
			var ih2: float = isz * 0.9
			var sh_h: float = maxf(ih2, gh) + gap * 0.5
			var hspec: Array = []
			if not touch and UiPrompts.STANCE_ACTIONS[sel] != "":
				hspec = UiGlyphs.specs_for(UiPrompts.STANCE_ACTIONS[sel], device, slot, style, preset)
			out["title"] = {"kind": sel, "icon_c": Vector2(body.position.x + ih2 * 0.5, y + sh_h * 0.5), "icon_sz": ih2, "text_x": body.position.x + ih2 + gap, "text_y": y + sh_h * 0.5 + float(fs_body) * 0.35, "specs": hspec, "gh": gh, "right": body.end.x,
				"text": UiStance.title(sel)}
			y += sh_h
			var blurb: String = UiStance.blurb(sel)
			if blurb != "":
				var bl: PackedStringArray = UiText.wrap(blurb, fs_small, body.size.x)
				(out["notes"] as Array).append({"lines": bl, "y": y, "fs": fs_small, "dim": true})
				y += float(bl.size()) * lh_s + gap * 0.4
			for r in range(4):
				var ls2: PackedStringArray = UiText.wrap(_cell_text(sel, r, preset), fs_body, maxf(body.size.x - head_w - gap, 20.0))
				var rh2: float = maxf(gh, float(ls2.size()) * lh_b) + gap * 0.5
				(out["rowheads"] as Array).append({"rect": Rect2(body.position.x, y, head_w, rh2), "specs": head_specs[r], "y": y + rh2 * 0.5 - gap * 0.25, "gh": gh})
				(out["cells"] as Array).append({"kind": sel, "row": r, "rect": Rect2(body.position.x + head_w + gap, y, body.size.x - head_w - gap, rh2), "lines": ls2, "fs": fs_body, "lh": lh_b})
				y += rh2
		y += gap * 0.6
	for nt in note_texts:
		var nl: PackedStringArray = UiText.wrap(str(nt), note_fs, body.size.x)
		(out["notes"] as Array).append({"lines": nl, "y": y, "fs": note_fs, "dim": false})
		y += float(nl.size()) * lh_s + gap * 0.4
	out["tallest"] = y - body.position.y
	out["fits"] = bool(out["fits"]) and (y - body.position.y) <= body.size.y + 0.5
	return out


## The redraw key: changes only with the page, the size, the device and the touch mode.
static func sig(vp: Vector2, page_i: int, device: String, slot: int, touch: bool, dp: float, s: float, preset: String = "") -> Array:
	return [int(vp.x), int(vp.y), page_i, device, slot, touch, int(dp * 100.0), int(s * 100.0), preset]


# --- Drawing -------------------------------------------------------------------------------------------------------------------

static func draw(ci: CanvasItem, p: Dictionary, device: String, slot: int, style: String, touch: bool) -> void:
	var data: Dictionary = UiData.howto()
	var vp: Vector2 = ci.size if ci is Control else Vector2(1920, 1080)
	var card: Rect2 = p["card"]
	var fs_body: int = p["fs_body"]
	var fs_small: int = p["fs_small"]
	var fs_title: int = p["fs_title"]
	var ink := Color(UiLook.col(UiLook.INK))
	var dim := Color(UiLook.col(UiLook.INK_DIM))
	var edge := Color(UiLook.col(UiLook.EDGE), 0.55)
	UiText.no_outline = true
	# The scrim over the whole HUD, then the card.
	ci.draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.03, 0.06, 0.78))
	UiIcons.rrect(ci, card, 18.0 * float(p["cs"]), Color(UiLook.col(UiLook.SCRIM), 0.97), edge, 2.0)
	var inner: Rect2 = p["inner"]
	var close: Rect2 = p["close"]
	# The heading: a small kicker, then the page's title.
	var kick_h: float = UiText.height(fs_small) * 1.1
	UiText.draw(ci, str(p["kicker"]), Vector2(inner.position.x, inner.position.y + UiText.ascent(fs_small)), fs_small, dim, -1)
	UiText.draw(ci, str(p["title_text"]), Vector2(inner.position.x, inner.position.y + kick_h + UiText.ascent(fs_title)), fs_title, ink, -1)
	if not touch and close.size.x > 0.0:
		var hint: String = str(data.get("hint", ""))
		var hw: float = UiText.width(hint, fs_small)
		if close.position.x - hw - 12.0 > inner.position.x + UiText.width(str(p["title_text"]), fs_title) + 20.0:
			UiText.draw(ci, hint, Vector2(close.position.x - 12.0, close.get_center().y + float(fs_small) * 0.35), fs_small, dim, 1)
	# The close button: a cross in a square target.
	UiIcons.rrect(ci, close, close.size.y * 0.25, Color(UiLook.col(UiLook.SCRIM), 0.8), edge, 1.6)
	var cc: Vector2 = close.get_center()
	var cr: float = close.size.x * 0.22
	UiIcons.line(ci, cc + Vector2(-cr, -cr), cc + Vector2(cr, cr), maxf(2.0, close.size.x * 0.06), ink)
	UiIcons.line(ci, cc + Vector2(-cr, cr), cc + Vector2(cr, -cr), maxf(2.0, close.size.x * 0.06), ink)
	# The items.
	var lh: float = p["lh"]
	for rec in p["items"]:
		var r: Rect2 = rec["rect"]
		var it: Dictionary = rec["item"]
		match rec["kind"]:
			"heading":
				UiText.draw(ci, str(rec["lines"][0]), Vector2(r.position.x, r.position.y + float(fs_body) * 0.9), fs_body, dim, -1)
			"note":
				var ny: float = r.position.y + float(fs_small) * 0.9
				for ln in rec["lines"]:
					UiText.draw(ci, ln, Vector2(r.position.x, ny), fs_small, dim, -1)
					ny += UiText.height(fs_small) * 1.12
			"action":
				var gh: float = rec["gh"]
				var gx: float = r.position.x
				for sp in rec["specs"]:
					var w: float = UiGlyphs.draw_spec(ci, sp, Vector2(gx, r.position.y + gh * 0.5), gh, 1.0, true)
					gx += w + gh * 0.08
				var ly: float = r.position.y + maxf(0.0, (r.size.y - float(rec["lines"].size()) * lh) * 0.5) + UiText.ascent(fs_body) + (lh - UiText.height(fs_body)) * 0.5
				for ln in rec["lines"]:
					UiText.draw(ci, ln, Vector2(rec["label_x"], ly), fs_body, ink, -1)
					ly += lh
			_:
				if not bool(rec.get("plain", false)):
					_icon(ci, str(it.get("icon", "")), rec["icon_c"], rec["isz"], float(p["cs"]))
				var ty: float = r.position.y + UiText.ascent(fs_body) + (lh - UiText.height(fs_body)) * 0.5
				if rec["stance"] != "":
					# The stance's name in its own words (terms.json), beside its line.
					var idx: int = int(str(it.get("icon", "stance_0")).get_slice("_", 1))
					UiText.draw(ci, UiData.t("stance." + str(rec["stance"])), Vector2(rec["text_x"], ty), fs_body, UiLook.stance_col(idx), -1)
				for ln in rec["lines"]:
					UiText.draw(ci, ln, Vector2(float(rec["text_x"]) + float(rec["name_w"]), ty), fs_body, ink, -1)
					ty += lh
	if not (p["stances"] as Dictionary).is_empty():
		_draw_stances(ci, p)
	var lic: Dictionary = p["licences"]
	if not lic.is_empty() and (lic["lines"] as Array).size() > 0:
		var lhs: float = lic["lh"]
		var lfs: int = lic["fs"]
		var area: Rect2 = lic["rect"]
		var ly2: float = area.position.y + UiText.ascent(lfs) + (lhs - UiText.height(lfs)) * 0.5
		for ln in lic["lines"]:
			var kind: int = int(ln[0])
			if kind != 2:
				UiText.draw(ci, str(ln[1]), Vector2(area.position.x, ly2), lfs, ink if kind == 1 else Color(ink, 0.82), -1)
			ly2 += lhs
		ci.draw_rect(lic["bar"], Color(dim, 0.18))
		ci.draw_rect(lic["thumb"], Color(ink, 0.7))
	# The footer: back, the page dots, next (or got it).
	var b: Dictionary = data.get("buttons", {})
	var back: Rect2 = p["back"]
	var nxt: Rect2 = p["next"]
	if not p["is_first"]:
		_button(ci, back, str(b.get("back", "BACK")), fs_body, false)
	_button(ci, nxt, str(b.get("done", "GOT IT")) if p["is_last"] else str(b.get("next", "NEXT")), fs_body, true)
	var dots: Array = p["dots"]
	for i in range(dots.size()):
		var on: bool = i == int(p["page"])
		ci.draw_circle(dots[i], float(p["dot_r"]) * (1.3 if on else 1.0), ink if on else Color(dim, 0.5))
	UiText.no_outline = false


static func _draw_stances(ci: CanvasItem, p: Dictionary) -> void:
	var st: Dictionary = p["stances"]
	var ink := Color(UiLook.col(UiLook.INK))
	var dim := Color(UiLook.col(UiLook.INK_DIM))
	var fs_small: int = p["fs_small"]
	var held: int = int(st["held"])
	var sel: int = int(st["sel"])
	var mode: String = str(st["mode"])
	# The held stance's column (or the selected tab) is tinted in its colour.
	if mode == "table":
		for hd in st["heads"]:
			var k: int = int(hd["kind"])
			var col: Color = UiStance.col(k)
			var top: Rect2 = hd["rect"]
			var bottom: float = top.end.y
			for c in st["cells"]:
				if int(c["kind"]) == k:
					bottom = maxf(bottom, (c["rect"] as Rect2).end.y)
			if k == held:
				UiIcons.rrect(ci, Rect2(top.position, Vector2(top.size.x, bottom - top.position.y)), 8.0, Color(col, 0.13), Color(col, 0.7), 1.6)
			UiIcons.stance5(ci, k, hd["icon_c"], float(hd["icon_sz"]), col)
			UiText.draw(ci, UiStance.word(k), Vector2(top.get_center().x, float(hd["name_y"])), fs_small, ink, 0)
			var specs: Array = hd["specs"]
			if not specs.is_empty():
				var w := 0.0
				var gh: float = float(fs_small) * 1.5
				for sp in specs:
					w += UiGlyphs.width_spec(sp, gh) + gh * 0.08
				var gx: float = top.get_center().x - w * 0.5
				for sp in specs:
					gx += UiGlyphs.draw_spec(ci, sp, Vector2(gx, float(hd["hold_y"])), gh, 1.0, true) + gh * 0.08
			elif str(hd["enter"]) != "":
				UiText.draw(ci, str(hd["enter"]), Vector2(top.get_center().x, float(hd["hold_y"]) + float(fs_small) * 0.3), int(float(fs_small) * 0.9), dim, 0)
	elif mode == "tabs":
		for tb in st["tabs"]:
			var k2: int = int(tb["kind"])
			var r: Rect2 = tb["rect"]
			var on: bool = k2 == sel
			var col2: Color = UiStance.col(k2)
			UiIcons.rrect(ci, r.grow(-2.0), r.size.y * 0.22, Color(col2, 0.18) if on else Color(UiLook.col(UiLook.SCRIM), 0.6), Color(col2, 0.95 if on else 0.4), 2.4 if on else 1.2)
			var icon_sz: float = r.size.y * 0.5
			if bool(tb["named"]):
				UiIcons.stance5(ci, k2, Vector2(r.position.x + r.size.y * 0.55, r.get_center().y), icon_sz, col2)
				UiText.draw(ci, UiStance.word(k2), Vector2(r.position.x + r.size.y * 0.95, r.get_center().y + float(fs_small) * 0.35), fs_small, ink, -1)
			else:
				UiIcons.stance5(ci, k2, r.get_center(), icon_sz, col2)
			if k2 == held and not on:
				ci.draw_circle(Vector2(r.end.x - 7.0, r.position.y + 7.0), 3.0, col2)   # the stance held now
		var tt = st["title"]
		if tt is Dictionary:
			var kk: int = int(tt["kind"])
			UiIcons.stance5(ci, kk, tt["icon_c"], float(tt["icon_sz"]), UiStance.col(kk))
			UiText.draw(ci, str(tt["text"]), Vector2(float(tt["text_x"]), float(tt["text_y"])), int(p["fs_body"]), ink, -1)
			var tspecs: Array = tt["specs"]
			if not tspecs.is_empty():
				var tw := 0.0
				for sp in tspecs:
					tw += UiGlyphs.width_spec(sp, float(tt["gh"])) + float(tt["gh"]) * 0.08
				var tx: float = float(tt["right"]) - tw
				for sp in tspecs:
					tx += UiGlyphs.draw_spec(ci, sp, Vector2(tx, (tt["icon_c"] as Vector2).y), float(tt["gh"]), 1.0, true) + float(tt["gh"]) * 0.08
	# The row heads and the cells.
	for rh in st["rowheads"]:
		var rr: Rect2 = rh["rect"]
		var gx2: float = rr.position.x
		for sp in rh["specs"]:
			if sp.has("word"):
				UiText.draw(ci, str(sp["word"]), Vector2(gx2, float(rh["y"]) + float(fs_small) * 0.35), fs_small, ink, -1)
				gx2 += UiText.width(str(sp["word"]), fs_small)
			else:
				gx2 += UiGlyphs.draw_spec(ci, sp, Vector2(gx2, float(rh["y"])), float(rh["gh"]), 1.0, true) + float(rh["gh"]) * 0.08
	for c in st["cells"]:
		var cr: Rect2 = c["rect"]
		var fs: int = int(c["fs"])
		var lh: float = float(c["lh"])
		var ty: float = cr.position.y + (cr.size.y - float(c["lines"].size()) * lh) * 0.5 + UiText.ascent(fs) - 1.0
		var centred: bool = mode == "table"
		for ln in c["lines"]:
			UiText.draw(ci, ln, Vector2(cr.get_center().x if centred else cr.position.x, ty), fs, ink, 0 if centred else -1)
			ty += lh
	for nt in st["notes"]:
		var ny: float = float(nt["y"]) + UiText.ascent(int(nt["fs"]))
		for ln in nt["lines"]:
			UiText.draw(ci, ln, Vector2((p["body"] as Rect2).position.x, ny), int(nt["fs"]), dim if bool(nt["dim"]) else Color(dim, 1.0), -1)
			ny += UiText.height(int(nt["fs"])) * 1.12


static func _button(ci: CanvasItem, r: Rect2, label: String, fs: int, primary: bool) -> void:
	var ink := Color(UiLook.col(UiLook.INK))
	UiIcons.rrect(ci, r, r.size.y * 0.3, Color(ink, 0.92) if primary else Color(UiLook.col(UiLook.SCRIM), 0.8), Color(UiLook.col(UiLook.EDGE), 0.7), 1.8)
	UiText.draw(ci, label, Vector2(r.get_center().x, r.get_center().y + float(fs) * 0.35), fs, Color(UiLook.col(UiLook.INK_DARK)) if primary else ink, 0)


## The little pictures. Each is a few shapes in a square of side `sz` centred at `c`, in the HUD's own neutral colours.
static func _icon(ci: CanvasItem, name: String, c: Vector2, sz: float, cs: float) -> void:
	var ink := Color(UiLook.col(UiLook.INK))
	var dim := Color(UiLook.col(UiLook.INK_DIM), 0.7)
	var w: float = maxf(2.0, sz * 0.07)
	var r: float = sz * 0.42
	if name.begins_with("stance5_"):
		var k5: int = int(name.get_slice("_", 1))
		UiIcons.stance5(ci, k5, c, sz * 0.85, UiStance.col(k5))
		return
	if name.begins_with("stance_"):
		var i: int = int(name.get_slice("_", 1))
		UiIcons.stance(ci, i, c, sz * 0.85, UiLook.stance_col(i))
		return
	match name:
		"plan":
			# A crosshair: you choose where.
			ci.draw_arc(c, r * 0.62, 0.0, TAU, 24, ink, w, true)
			for k in range(4):
				var d: Vector2 = Vector2.from_angle(float(k) * PI * 0.5)
				ci.draw_line(c + d * r * 0.4, c + d * r * 1.05, ink, w)
			ci.draw_circle(c, sz * 0.07, ink)
		"auto":
			# Three chevrons in a row: it plays out on its own.
			for k in range(3):
				UiIcons.chevron(ci, c + Vector2((float(k) - 1.0) * sz * 0.26, 0.0), sz * 0.3, 1.0, w, ink)
		"form":
			# Three rising chevrons: a form is ready, take it.
			for k in range(3):
				var cy: float = c.y + (float(k) - 1.0) * sz * 0.2 + sz * 0.05
				ci.draw_polyline(PackedVector2Array([Vector2(c.x - sz * 0.22, cy + sz * 0.1), Vector2(c.x, cy - sz * 0.1), Vector2(c.x + sz * 0.22, cy + sz * 0.1)]), Color(ink, 1.0 - 0.25 * float(2 - k)), w, true)
		"body":
			var cols: Array = [UiLook.STAGE_FRESH, UiLook.STAGE_BRUISED, UiLook.STAGE_BATTERED, UiLook.STAGE_BROKEN]
			for k in range(4):
				ci.draw_circle(c + Vector2((float(k) - 1.5) * sz * 0.26, 0.0), sz * 0.11, Color(UiLook.col(cols[k])))
		"finisher":
			UiIcons.star4(ci, c, sz * 0.8, ink)
			ci.draw_arc(c, r, 0.0, TAU, 28, dim, w, true)
		"wrap":
			ci.draw_arc(c, r, -PI * 0.15, PI * 1.55, 24, ink, w, true)
			UiIcons.chevron(ci, c + Vector2(r * 0.85, -r * 0.45), sz * 0.22, PI * 0.15, w, ink)
		"crown":
			for k in range(8):
				var a0: float = float(k) * TAU / 8.0
				ci.draw_arc(c, r, a0, a0 + TAU / 8.0 * 0.6, 6, Color(UiLook.col(UiLook.CROWN_FRESH)), w * 1.3, true)
		"card":
			var cr := Rect2(c - Vector2(r * 1.15, r * 0.55), Vector2(r * 2.3, r * 1.1))
			UiIcons.rrect(ci, cr, r * 0.2, Color(UiLook.col(UiLook.SCRIM), 0.9), Color(UiLook.col(UiLook.STAGE_BROKEN)), w)
			ci.draw_line(cr.position + Vector2(r * 0.3, r * 0.55), cr.end - Vector2(r * 0.3, r * 0.55), ink, w)
		"brink":
			UiIcons.brink(ci, c, sz * 0.8, ink)
			ci.draw_arc(c, r, 0.0, TAU, 28, Color(ink, 0.35), w * 0.8, true)
		"reads":
			# Their stance and their weight: a stance chip over a heavy barbell.
			UiIcons.stance(ci, 1, c + Vector2(0.0, -r * 0.5), sz * 0.55, UiLook.stance_col(1))
			UiReads.weight_mark(ci, c + Vector2(0.0, r * 0.55), sz * 0.7, true, ink)
		"struggle":
			ci.draw_arc(c, r * 0.45, 0.0, TAU, 20, ink, w, true)
			ci.draw_arc(c, r * 0.75, 0.0, TAU, 24, dim, w, true)
			ci.draw_arc(c, r, 0.0, TAU, 28, Color(dim, 0.45), w, true)
		"toll":
			var tr := Rect2(c - Vector2(r * 1.2, r * 0.55), Vector2(r * 2.4, r * 1.1))
			UiIcons.rrect(ci, tr, r * 0.25, Color(UiLook.col(UiLook.SCRIM), 0.9), Color(UiLook.col(UiLook.EDGE), 0.7), w * 0.8)
			ci.draw_line(tr.position + Vector2(r * 0.3, r * 0.4), tr.position + Vector2(r * 1.6, r * 0.4), dim, w)
			ci.draw_line(tr.position + Vector2(r * 0.3, r * 0.75), tr.position + Vector2(r * 2.0, r * 0.75), dim, w)
		"strip":
			ci.draw_line(c + Vector2(-r * 1.2, 0), c + Vector2(r * 1.2, 0), dim, w * 1.4)
			ci.draw_circle(c + Vector2(-r * 0.55, 0), sz * 0.12, Color(UiLook.col(UiLook.STAGE_FRESH)))
			UiIcons.fill_poly(ci, PackedVector2Array([c + Vector2(r * 0.6, -sz * 0.14), c + Vector2(r * 0.6 + sz * 0.14, 0), c + Vector2(r * 0.6, sz * 0.14), c + Vector2(r * 0.6 - sz * 0.14, 0)]), ink)
		"touch_move":
			ci.draw_arc(c, r, 0.0, TAU, 24, dim, w, true)
			ci.draw_circle(c + Vector2(r * 0.25, -r * 0.2), sz * 0.14, ink)
		"touch_attack":
			for k in range(3):
				ci.draw_circle(c + Vector2.from_angle(PI * (1.05 + 0.4 * float(k))) * r * 0.75 + Vector2(r * 0.4, r * 0.5), sz * 0.13, ink)
		"touch_hold":
			ci.draw_arc(c, r, 0.0, TAU, 24, dim, w, true)
			ci.draw_arc(c, r, -PI * 0.5, PI * 0.6, 16, ink, w * 1.6, true)
		"touch_pause":
			ci.draw_rect(Rect2(c.x - sz * 0.2, c.y - sz * 0.25, sz * 0.14, sz * 0.5), ink)
			ci.draw_rect(Rect2(c.x + sz * 0.06, c.y - sz * 0.25, sz * 0.14, sz * 0.5), ink)
