class_name UiNotice
extends RefCounted
## The flashing-effects gate (docs/ui/hud-spec.md section 51; Legal's docs/legal/photosensitivity-note.md, RL-119): the first thing in a session. A plain opaque card
## and nothing else moves until the player presses "I understand, start": no demo, no intro, no match, no tick. A second button opens Settings (the gate stays up behind it).
## There is no timeout, nothing starts by itself, and no key but the two buttons' own dismisses it (Esc, Start, a stray tap outside do nothing). The words are Legal's, data
## (terms.json prompt.photo_*), and the README carries the same text. From Settings the same text can be read again (`gate` false): one Close button, Esc and B close it.
## Nothing in it moves, so it is the same under Reduced motion. `plan` is pure geometry, `hit` says which button a point is on, `draw` paints.

const GATE_IDS: Array = ["start", "settings"]
const READ_IDS: Array = ["close"]


static func ids(gate: bool) -> Array:
	return GATE_IDS if gate else READ_IDS


static func title() -> String:
	return UiData.t("prompt.photo_title")


## The body: Legal's text after its first sentence. The sentence about the settings has its own place (`photo_settings_line`, and `photo_settings_line_rf` for when the
## reduce_flashing flag is on: it is reworded with Legal then; today both read the same).
static func body() -> String:
	var rf: bool = UiData.feature("reduce_flashing")
	return " ".join(PackedStringArray([UiData.t("prompt.photo_body_a"), UiData.t("prompt.photo_settings_line_rf" if rf else "prompt.photo_settings_line"), UiData.t("prompt.photo_body_b")]))


## The whole text, in order (what README.md says, word for word).
static func sentence() -> String:
	return title() + " " + body()


static func label(id: String) -> String:
	return UiData.t("prompt.photo_" + id)


## The geometry for a viewport. `st` is {focus: -1 (none), 0 or 1, gate: bool, scroll: pixels, safe: Rect2 (optional, the area clear of a notch and the bars)}.
## The two buttons are pinned at the card's foot and are always on screen and 48 dp; the card takes the biggest type that lets the whole text fit above them (down to the
## legibility floor), and when even that does not fit the text scrolls inside `view` (`can_scroll`, with a cue drawn). Returns {card, view, lines[], items[{id, label, rect}], cols, tm,
## scroll, max_scroll, can_scroll, fits, ...}.
static func plan(vp: Vector2, s: float, dp: float, touch: bool, st: Dictionary) -> Dictionary:
	var gate: bool = bool(st.get("gate", true))
	var list: Array = ids(gate)
	var tm: float = maxf(48.0 * dp, 44.0)
	var area := Rect2(Vector2.ZERO, vp)
	var sf = st.get("safe", Rect2())
	if sf is Rect2 and (sf as Rect2).size.x > 1.0 and (sf as Rect2).size.y > 1.0:
		area = (sf as Rect2).intersection(area)
	var margin: float = maxf(area.size.x * 0.04, 12.0)
	var margin_y: float = maxf(area.size.y * 0.03, 6.0 * dp)
	var cs: float = maxf(s, 0.3)
	var pad: float = maxf(minf(24.0 * cs, area.size.y * 0.04), 8.0)
	var gap: float = maxf(minf(12.0 * cs, area.size.y * 0.03), 6.0)
	var cw: float = minf(area.size.x - 2.0 * margin, maxf(880.0 * cs, 520.0))
	var tw: float = cw - 2.0 * pad
	var avail_h: float = area.size.y - 2.0 * margin_y
	var floor_px: int = int(UiLook.text_floor)
	var fs0: int = UiText.px(22.0, cs)
	var best: Dictionary = {}
	for fs_body in range(fs0, floor_px - 1, -1):
		var fs_title: int = maxi(int(round(float(fs_body) * 30.0 / 22.0)), floor_px)
		var title_lines: PackedStringArray = UiText.wrap(title(), fs_title, tw)
		var body_lines: PackedStringArray = UiText.wrap(body(), fs_body, tw)
		var lh_t: float = UiText.height(fs_title) * 1.15
		var lh_b: float = UiText.height(fs_body) * 1.2
		var widest: float = 0.0
		for id in list:
			widest = maxf(widest, UiText.width(label(str(id)), fs_body))
		var bw: float = maxf(tm * 3.0, widest + tm * 0.9)
		var cols: int = 2 if (float(list.size()) * bw + gap * float(list.size() - 1)) <= tw else 1
		if cols == 1:
			bw = minf(bw, tw)
		else:
			bw = (tw - gap * float(list.size() - 1)) / float(list.size())
		var text_h: float = float(title_lines.size()) * lh_t + gap + float(body_lines.size()) * lh_b
		var rows: int = 1 if cols == 2 else list.size()
		var btn_h: float = float(rows) * tm + float(rows - 1) * gap
		best = {"fs_title": fs_title, "fs_body": fs_body, "title_lines": title_lines, "body_lines": body_lines, "lh_t": lh_t, "lh_b": lh_b, "bw": bw, "cols": cols, "text_h": text_h, "btn_h": btn_h}
		if pad * 2.0 + text_h + gap * 1.5 + btn_h <= avail_h:
			break
	var text_h2: float = best["text_h"]
	var btn_h2: float = best["btn_h"]
	var chh: float = minf(pad * 2.0 + text_h2 + gap * 1.5 + btn_h2, avail_h)
	var card := Rect2(area.position.x + (area.size.x - cw) * 0.5, area.position.y + (area.size.y - chh) * 0.5, cw, chh)
	var view_h: float = maxf(chh - pad * 2.0 - gap * 1.5 - btn_h2, 0.0)
	# When the text must scroll, a band under it (one line high) holds the cue that there is more, so the cue never prints over a line.
	var cue_h: float = float(best["lh_b"]) if text_h2 > view_h + 0.5 else 0.0
	var view := Rect2(card.position.x + pad, card.position.y + pad, tw, minf(maxf(view_h - cue_h, float(best["lh_b"]) * 2.0), text_h2))
	var max_scroll: float = maxf(text_h2 - view.size.y, 0.0)
	var scroll: float = clampf(float(st.get("scroll", 0.0)), 0.0, max_scroll)
	var y0: float = card.end.y - pad - btn_h2
	var cols2: int = best["cols"]
	var bw2: float = best["bw"]
	var items: Array = []
	for i in range(list.size()):
		var r: Rect2
		if cols2 == 2:
			r = Rect2(card.position.x + pad + float(i) * (bw2 + gap), y0, bw2, tm)
		else:
			r = Rect2(card.position.x + pad, y0 + float(i) * (tm + gap), bw2, tm)
		items.append({"id": list[i], "label": label(str(list[i])), "rect": r})
	# The text as lines at their offsets in the scrolling content (the title, a gap, the body).
	var lines: Array = []
	var yy := 0.0
	for ln in best["title_lines"]:
		lines.append({"text": str(ln), "y": yy, "h": float(best["lh_t"]), "fs": int(best["fs_title"]), "title": true})
		yy += float(best["lh_t"])
	yy += gap
	for ln in best["body_lines"]:
		lines.append({"text": str(ln), "y": yy, "h": float(best["lh_b"]), "fs": int(best["fs_body"]), "title": false})
		yy += float(best["lh_b"])
	var fs_b: int = best["fs_body"]
	var fits: bool = Rect2(Vector2.ZERO, vp).encloses(card) and area.encloses(card)
	for it in items:
		if not card.encloses(it["rect"]) or (it["rect"] as Rect2).size.y < tm - 0.01 or UiText.width(str(it["label"]), fs_b) + 16.0 > (it["rect"] as Rect2).size.x:
			fits = false
	return {"card": card, "view": view, "lines": lines, "title_lines": best["title_lines"], "body_lines": best["body_lines"], "items": items, "cols": cols2, "tm": tm, "fs_title": best["fs_title"], "fs_body": fs_b,
		"lh_t": best["lh_t"], "lh_b": best["lh_b"], "pad": pad, "gap": gap, "text_h": text_h2, "fits": fits, "focus": clampi(int(st.get("focus", -1)), -1, list.size() - 1), "touch": touch, "cs": cs, "gate": gate,
		"scroll": scroll, "max_scroll": max_scroll, "can_scroll": max_scroll > 0.5}


## The id of the button a point is on, or "".
static func hit(p: Dictionary, pos: Vector2) -> String:
	for it in p["items"]:
		if (it["rect"] as Rect2).has_point(pos):
			return str(it["id"])
	return ""


## The focus after a move: from no focus a move lands on the first button; otherwise -1 or +1 along the buttons, staying put at the ends.
static func moved(focus: int, d: int, count: int = 2) -> int:
	if focus < 0:
		return 0
	return clampi(focus + d, 0, count - 1)


static func sig(p: Dictionary) -> Array:
	var c: Rect2 = p["card"]
	return [int(c.size.x), int(c.size.y), int(c.position.x), int(c.position.y), int(p["cs"] * 100.0), int(p["focus"]), bool(p["touch"]), bool(p["gate"]), int(p["fs_body"]), int(float(p["scroll"]))]


## The opaque backdrop of the gate: the match under it is not shown at all (nothing of it may move on screen).
static func draw_backdrop(ci: CanvasItem) -> void:
	var vp: Vector2 = ci.size if ci is Control else Vector2(1920, 1080)
	ci.draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.03, 0.06, 1.0))


static func draw(ci: CanvasItem, p: Dictionary) -> void:
	var vp: Vector2 = ci.size if ci is Control else Vector2(1920, 1080)
	var ink := Color(UiLook.col(UiLook.INK))
	var dim := Color(UiLook.col(UiLook.INK_DIM))
	var dark := Color(UiLook.col(UiLook.INK_DARK))
	var edge := Color(UiLook.col(UiLook.EDGE), 0.55)
	var scrim := Color(UiLook.col(UiLook.SCRIM))
	var card: Rect2 = p["card"]
	var pad: float = p["pad"]
	var fs_t: int = p["fs_title"]
	var fs_b: int = p["fs_body"]
	UiText.no_outline = true
	if bool(p["gate"]):
		draw_backdrop(ci)
	else:
		ci.draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.03, 0.06, 0.88))
	UiIcons.rrect(ci, card, 18.0 * float(p["cs"]), Color(scrim, 0.98), edge, 2.0)
	# The text, inside its view: a line that is cut by the view's edge fades by how much of it shows; a cue says there is more.
	var view: Rect2 = p["view"]
	var scroll: float = p["scroll"]
	for ln in p["lines"]:
		var top: float = view.position.y + float(ln["y"]) - scroll
		var vis: float = clampf((minf(top + float(ln["h"]), view.end.y) - maxf(top, view.position.y)) / float(ln["h"]), 0.0, 1.0)
		if vis <= 0.05:
			continue
		var fs_l: int = ln["fs"]
		UiText.draw(ci, str(ln["text"]), Vector2(view.position.x, top + UiText.ascent(fs_l)), fs_l, Color(ink if bool(ln["title"]) else dim, vis), -1)
	if bool(p["can_scroll"]):
		var track := Rect2(card.end.x - pad * 0.55, view.position.y, maxf(3.0, pad * 0.2), view.size.y)
		ci.draw_rect(track, Color(ink, 0.15))
		var th: float = maxf(track.size.y * view.size.y / (view.size.y + float(p["max_scroll"])), 12.0)
		var ty: float = track.position.y + (track.size.y - th) * (scroll / float(p["max_scroll"]))
		ci.draw_rect(Rect2(track.position.x, ty, track.size.x, th), Color(ink, 0.7))
		var cue_s: float = maxf(float(fs_b) * 0.5, 6.0)
		var band_y: float = view.end.y + (float(p["lh_b"]) - UiText.height(fs_b)) * 0.5
		if scroll < float(p["max_scroll"]) - 0.5:
			var cx: float = view.end.x - cue_s * 1.5
			var cy: float = view.end.y + float(p["lh_b"]) * 0.5
			UiIcons.fill_poly(ci, PackedVector2Array([Vector2(cx - cue_s, cy - cue_s * 0.5), Vector2(cx + cue_s, cy - cue_s * 0.5), Vector2(cx, cy + cue_s * 0.6)]), Color(ink, 0.95))
			UiText.draw(ci, UiData.t("prompt.photo_more"), Vector2(cx - cue_s * 1.6, band_y + UiText.ascent(fs_b)), fs_b, Color(ink, 0.95), 1)
		if scroll > 0.5:
			var cx2: float = view.position.x + cue_s * 1.5
			var cy2: float = view.end.y + float(p["lh_b"]) * 0.5
			UiIcons.fill_poly(ci, PackedVector2Array([Vector2(cx2 - cue_s, cy2 + cue_s * 0.5), Vector2(cx2 + cue_s, cy2 + cue_s * 0.5), Vector2(cx2, cy2 - cue_s * 0.6)]), Color(ink, 0.95))
	var focus: int = int(p["focus"])
	var touch: bool = p["touch"]
	var items: Array = p["items"]
	for i in range(items.size()):
		var r: Rect2 = items[i]["rect"]
		# A keyboard or pad focus fills the button; with none yet (a stray press must not start the game) both are outlined. A touch screen has no focus: the first button is the filled one.
		var on: bool = (i == focus) if not touch else (i == 0)
		UiIcons.rrect(ci, r, r.size.y * 0.3, Color(ink, 0.92) if on else Color(scrim, 0.8), Color(UiLook.col(UiLook.EDGE), 0.8), 1.8)
		UiText.draw(ci, str(items[i]["label"]), Vector2(r.get_center().x, r.get_center().y - UiText.height(fs_b) * 0.5 + UiText.ascent(fs_b)), fs_b, dark if on else ink, 0)
	UiText.no_outline = false
