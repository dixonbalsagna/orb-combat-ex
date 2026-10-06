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


## The geometry for a viewport. `st` is {focus: -1 (none), 0 or 1, gate: bool}. Returns {card, title_lines, body_lines, items[{id, label, rect}], cols, tm, fits, ...}.
static func plan(vp: Vector2, s: float, dp: float, touch: bool, st: Dictionary) -> Dictionary:
	var gate: bool = bool(st.get("gate", true))
	var list: Array = ids(gate)
	var tm: float = maxf(48.0 * dp, 44.0)
	var margin: float = maxf(vp.x * 0.04, 12.0)
	var cs: float = maxf(s, 0.3)
	var pad: float = maxf(24.0 * cs, 12.0)
	var gap: float = maxf(12.0 * cs, 8.0)
	var fs_title: int = UiText.px(30.0, cs)
	var fs_body: int = UiText.px(22.0, cs)
	var cw: float = minf(vp.x - 2.0 * margin, maxf(880.0 * cs, 520.0))
	var tw: float = cw - 2.0 * pad
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
	var chh: float = pad * 2.0 + text_h + gap * 1.5 + float(rows) * tm + float(rows - 1) * gap
	var card := Rect2((vp.x - cw) * 0.5, (vp.y - chh) * 0.5, cw, chh)
	var y0: float = card.position.y + pad + text_h + gap * 1.5
	var items: Array = []
	for i in range(list.size()):
		var r: Rect2
		if cols == 2:
			r = Rect2(card.position.x + pad + float(i) * (bw + gap), y0, bw, tm)
		else:
			r = Rect2(card.position.x + pad, y0 + float(i) * (tm + gap), bw, tm)
		items.append({"id": list[i], "label": label(str(list[i])), "rect": r})
	var fits: bool = Rect2(Vector2.ZERO, vp).encloses(card)
	for it in items:
		if not card.encloses(it["rect"]) or (it["rect"] as Rect2).size.y < tm - 0.01 or UiText.width(str(it["label"]), fs_body) + 16.0 > (it["rect"] as Rect2).size.x:
			fits = false
	return {"card": card, "title_lines": title_lines, "body_lines": body_lines, "items": items, "cols": cols, "tm": tm, "fs_title": fs_title, "fs_body": fs_body, "lh_t": lh_t, "lh_b": lh_b,
		"pad": pad, "gap": gap, "text_h": text_h, "fits": fits, "focus": clampi(int(st.get("focus", -1)), -1, list.size() - 1), "touch": touch, "cs": cs, "gate": gate}


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
	return [int(c.size.x), int(c.size.y), int(p["cs"] * 100.0), int(p["focus"]), bool(p["touch"]), bool(p["gate"])]


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
		# A keyboard or pad focus fills the button; with none yet (a stray press must not start the game) both are outlined. A touch screen has no focus: the first button is the filled one.
		var on: bool = (i == focus) if not touch else (i == 0)
		UiIcons.rrect(ci, r, r.size.y * 0.3, Color(ink, 0.92) if on else Color(scrim, 0.8), Color(UiLook.col(UiLook.EDGE), 0.8), 1.8)
		UiText.draw(ci, str(items[i]["label"]), Vector2(r.get_center().x, r.get_center().y - UiText.height(fs_b) * 0.5 + UiText.ascent(fs_b)), fs_b, dark if on else ink, 0)
	UiText.no_outline = false
