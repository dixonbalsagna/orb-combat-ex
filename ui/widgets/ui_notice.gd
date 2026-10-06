class_name UiNotice
extends RefCounted
## The photosensitivity notice (docs/ui/hud-spec.md section 49; Legal's docs/legal/photosensitivity-note.md): a plain card shown before the first match of a
## session, and again from Settings on request. "This game contains flashing effects." and one line each on what Reduced motion does, and that the game has
## not yet been tested with a photosensitivity analyser; two buttons: CONTINUE, and OPEN SETTINGS at the Reduced motion row. The words are data (terms.json
## prompt.photo_*). Nothing in it moves, so it is the same under Reduced motion. `plan` is pure geometry, `hit` says which button a point is on, `draw` paints.

const IDS: Array = ["continue", "settings"]


static func title() -> String:
	return UiData.t("prompt.photo_title")


## The lines of the notice, in order: the sentence that opens it, then the two that follow.
static func lines() -> PackedStringArray:
	return PackedStringArray([UiData.t("prompt.photo_title"), UiData.t("prompt.photo_line1"), UiData.t("prompt.photo_line2")])


## The whole notice as one sentence group (what README.md says, word for word).
static func sentence() -> String:
	return " ".join(lines())


static func label(id: String) -> String:
	return UiData.t("prompt.photo_" + id)


## The geometry for a viewport. `st` is {focus: 0 or 1}. Returns {card, title_lines, body_lines, items[{id, label, rect}], cols, tm, fs_title, fs_body, fits, ...}.
static func plan(vp: Vector2, s: float, dp: float, touch: bool, st: Dictionary) -> Dictionary:
	var tm: float = maxf(48.0 * dp, 44.0)
	var margin: float = maxf(vp.x * 0.04, 12.0)
	var cs: float = maxf(s, 0.3)
	var pad: float = maxf(24.0 * cs, 12.0)
	var gap: float = maxf(12.0 * cs, 8.0)
	var fs_title: int = UiText.px(30.0, cs)
	var fs_body: int = UiText.px(22.0, cs)
	var cw: float = minf(vp.x - 2.0 * margin, maxf(880.0 * cs, 520.0))
	var tw: float = cw - 2.0 * pad
	var ls: PackedStringArray = lines()
	var title_lines: PackedStringArray = UiText.wrap(ls[0], fs_title, tw)
	var body_lines := PackedStringArray()
	for i in range(1, ls.size()):
		body_lines.append_array(UiText.wrap(ls[i], fs_body, tw))
	var lh_t: float = UiText.height(fs_title) * 1.15
	var lh_b: float = UiText.height(fs_body) * 1.2
	var widest: float = 0.0
	for id in IDS:
		widest = maxf(widest, UiText.width(label(id), fs_body))
	var bw: float = maxf(tm * 3.0, widest + tm * 0.9)
	var cols: int = 2 if (2.0 * bw + gap) <= tw else 1
	if cols == 1:
		bw = minf(bw, tw)
	else:
		bw = (tw - gap) * 0.5
	var text_h: float = float(title_lines.size()) * lh_t + gap + float(body_lines.size()) * lh_b
	var rows: int = 1 if cols == 2 else 2
	var chh: float = pad * 2.0 + text_h + gap * 1.5 + float(rows) * tm + float(rows - 1) * gap
	var card := Rect2((vp.x - cw) * 0.5, (vp.y - chh) * 0.5, cw, chh)
	var y0: float = card.position.y + pad + text_h + gap * 1.5
	var items: Array = []
	for i in range(IDS.size()):
		var r: Rect2
		if cols == 2:
			r = Rect2(card.position.x + pad + float(i) * (bw + gap), y0, bw, tm)
		else:
			r = Rect2(card.position.x + pad, y0 + float(i) * (tm + gap), bw, tm)
		items.append({"id": IDS[i], "label": label(str(IDS[i])), "rect": r})
	var fits: bool = Rect2(Vector2.ZERO, vp).encloses(card)
	for it in items:
		if not card.encloses(it["rect"]) or (it["rect"] as Rect2).size.y < tm - 0.01 or UiText.width(str(it["label"]), fs_body) + 16.0 > (it["rect"] as Rect2).size.x:
			fits = false
	return {"card": card, "title_lines": title_lines, "body_lines": body_lines, "items": items, "cols": cols, "tm": tm, "fs_title": fs_title, "fs_body": fs_body, "lh_t": lh_t, "lh_b": lh_b,
		"pad": pad, "gap": gap, "text_h": text_h, "fits": fits, "focus": clampi(int(st.get("focus", 0)), 0, IDS.size() - 1), "touch": touch, "cs": cs}


## The id of the button a point is on, or "".
static func hit(p: Dictionary, pos: Vector2) -> String:
	for it in p["items"]:
		if (it["rect"] as Rect2).has_point(pos):
			return str(it["id"])
	return ""


## The focus after a move: -1 or +1 along the buttons; it stays put at the ends.
static func moved(focus: int, d: int) -> int:
	return clampi(focus + d, 0, IDS.size() - 1)


static func sig(p: Dictionary) -> Array:
	var c: Rect2 = p["card"]
	return [int(c.size.x), int(c.size.y), int(p["cs"] * 100.0), int(p["focus"]), bool(p["touch"])]


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
	ci.draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.03, 0.06, 0.88))   # the match is dimmed under it: nothing plays behind the notice
	UiIcons.rrect(ci, card, 18.0 * float(p["cs"]), Color(scrim, 0.98), edge, 2.0)
	var y: float = card.position.y + pad
	for ln in p["title_lines"]:
		UiText.draw(ci, str(ln), Vector2(card.position.x + pad, y + UiText.ascent(fs_t)), fs_t, ink, -1)
		y += float(p["lh_t"])
	y += float(p["gap"])
	for ln in p["body_lines"]:
		UiText.draw(ci, str(ln), Vector2(card.position.x + pad, y + UiText.ascent(fs_b)), fs_b, dim, -1)
		y += float(p["lh_b"])
	var focus: int = int(p["focus"])
	var touch: bool = p["touch"]
	var items: Array = p["items"]
	for i in range(items.size()):
		var r: Rect2 = items[i]["rect"]
		var on: bool = (i == focus) if not touch else (i == 0)   # a touch screen has no focus: Continue is the filled one
		UiIcons.rrect(ci, r, r.size.y * 0.3, Color(ink, 0.92) if on else Color(scrim, 0.8), Color(UiLook.col(UiLook.EDGE), 0.8), 1.8)
		UiText.draw(ci, str(items[i]["label"]), Vector2(r.get_center().x, r.get_center().y - UiText.height(fs_b) * 0.5 + UiText.ascent(fs_b)), fs_b, dark if on else ink, 0)
	UiText.no_outline = false
