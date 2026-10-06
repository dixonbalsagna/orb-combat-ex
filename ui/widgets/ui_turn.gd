class_name UiTurn
extends RefCounted
## The "turn your phone" card (docs/ui/hud-spec.md section 56): Orb ruled phones landscape only, so a phone held upright (a touch screen under 600 dp on its short side, in portrait)
## shows an opaque card with a phone drawn turning sideways and the words, and the match waits (the HUD holds it the way an overlay does). One small button, "Play upright anyway",
## is the way out for a phone whose rotation is locked or held in a mount: the web cannot unlock the rotation of an iPhone. `plan` is geometry, `hit` says whether the button was
## pressed, `draw` paints. Nothing in it moves.

const PHONE_DP := 600.0   # a touch screen whose short side is under this many dp is a phone


## Whether this screen is a phone held upright.
static func wanted(vp: Vector2, dp: float, touch: bool) -> bool:
	return touch and vp.y > vp.x * 1.05 and minf(vp.x, vp.y) / maxf(dp, 1.0) < PHONE_DP


static func plan(vp: Vector2, s: float, dp: float) -> Dictionary:
	var cs: float = maxf(s, 0.3)
	var tm: float = maxf(48.0 * dp, 44.0)
	var margin: float = maxf(vp.x * 0.06, 12.0)
	var pad: float = maxf(24.0 * cs, 12.0)
	var gap: float = maxf(14.0 * cs, 8.0)
	var cw: float = vp.x - 2.0 * margin
	var tw: float = cw - 2.0 * pad
	var fs_t: int = UiText.px(34.0, cs)
	var fs_b: int = UiText.px(22.0, cs)
	var title: String = UiData.t("prompt.turn_title")
	var body: String = UiData.t("prompt.turn_body")
	var title_lines: PackedStringArray = UiText.wrap(title, fs_t, tw)
	var body_lines: PackedStringArray = UiText.wrap(body, fs_b, tw)
	var lh_t: float = UiText.height(fs_t) * 1.15
	var lh_b: float = UiText.height(fs_b) * 1.2
	var icon_h: float = clampf(cw * 0.32, 64.0, 220.0)
	var label: String = UiData.t("prompt.turn_anyway")
	var bw: float = minf(tw, maxf(tm * 3.5, UiText.width(label, fs_b) + tm * 0.9))
	var total: float = pad * 2.0 + icon_h + gap + float(title_lines.size()) * lh_t + gap * 0.6 + float(body_lines.size()) * lh_b + gap * 1.6 + tm
	var card := Rect2(margin, maxf((vp.y - total) * 0.5, 4.0), cw, minf(total, vp.y - 8.0))
	var y: float = card.position.y + pad
	var icon := Rect2(card.get_center().x - icon_h * 1.3, y, icon_h * 2.6, icon_h)
	y += icon_h + gap
	var ty: float = y
	y += float(title_lines.size()) * lh_t + gap * 0.6
	var by: float = y
	var btn := Rect2(card.get_center().x - bw * 0.5, card.end.y - pad - tm, bw, tm)
	return {"card": card, "icon": icon, "title_lines": title_lines, "body_lines": body_lines, "title_y": ty, "body_y": by, "lh_t": lh_t, "lh_b": lh_b, "fs_t": fs_t, "fs_b": fs_b,
		"button": btn, "label": label, "pad": pad, "cs": cs, "tm": tm, "fits": Rect2(Vector2.ZERO, vp).encloses(card) and card.encloses(btn) and by + float(body_lines.size()) * lh_b <= btn.position.y}


static func hit(p: Dictionary, pos: Vector2) -> bool:
	return (p["button"] as Rect2).has_point(pos)


static func sig(p: Dictionary) -> Array:
	var c: Rect2 = p["card"]
	return [int(c.size.x), int(c.size.y), int(c.position.y), int(p["cs"] * 100.0)]


static func draw(ci: CanvasItem, p: Dictionary) -> void:
	var vp: Vector2 = ci.size if ci is Control else Vector2(1080, 1920)
	var ink := Color(UiLook.col(UiLook.INK))
	var dim := Color(UiLook.col(UiLook.INK_DIM))
	var scrim := Color(UiLook.col(UiLook.SCRIM))
	var edge := Color(UiLook.col(UiLook.EDGE))
	var cs: float = p["cs"]
	UiText.no_outline = true
	ci.draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.03, 0.06, 1.0))
	var card: Rect2 = p["card"]
	UiIcons.rrect(ci, card, 18.0 * cs, Color(scrim, 0.98), Color(edge, 0.55), 2.0)
	# A phone upright, an arrow turning, and a phone on its side: shapes only, no colour carries it.
	var ic: Rect2 = p["icon"]
	var h: float = ic.size.y
	var up := Rect2(ic.position.x + ic.size.x * 0.12, ic.position.y, h * 0.56, h)
	var side := Rect2(ic.end.x - ic.size.x * 0.12 - h, ic.position.y + h * 0.22, h, h * 0.56)
	var lw: float = maxf(3.0, h * 0.045)
	UiIcons.rrect(ci, up, h * 0.1, Color(ink, 0.08), Color(dim, 0.9), lw)
	UiIcons.rrect(ci, Rect2(up.position.x + up.size.x * 0.3, up.end.y - h * 0.09, up.size.x * 0.4, h * 0.03), 2.0, Color(dim, 0.9), Color(dim, 0.0), 0.0)
	UiIcons.rrect(ci, side, h * 0.1, Color(ink, 0.18), Color(ink, 1.0), lw)
	UiIcons.rrect(ci, Rect2(side.end.x - h * 0.09, side.position.y + side.size.y * 0.3, h * 0.03, side.size.y * 0.4), 2.0, Color(ink, 1.0), Color(ink, 0.0), 0.0)
	var c0 := Vector2(ic.get_center().x, ic.position.y + h * 0.78)
	ci.draw_arc(c0, h * 0.42, PI * 1.12, PI * 1.88, 24, Color(ink, 0.95), lw, true)
	var tip: Vector2 = c0 + Vector2.from_angle(PI * 1.88) * h * 0.42
	UiIcons.fill_poly(ci, PackedVector2Array([tip + Vector2(h * 0.07, -h * 0.02), tip + Vector2(-h * 0.07, -h * 0.06), tip + Vector2(0.0, h * 0.09)]), Color(ink, 0.95))
	var fs_t: int = p["fs_t"]
	var fs_b: int = p["fs_b"]
	var cx: float = card.get_center().x
	var y: float = p["title_y"]
	for ln in p["title_lines"]:
		UiText.draw(ci, str(ln), Vector2(cx, y + UiText.ascent(fs_t)), fs_t, ink, 0)
		y += float(p["lh_t"])
	y = p["body_y"]
	for ln in p["body_lines"]:
		UiText.draw(ci, str(ln), Vector2(cx, y + UiText.ascent(fs_b)), fs_b, dim, 0)
		y += float(p["lh_b"])
	var b: Rect2 = p["button"]
	UiIcons.rrect(ci, b, b.size.y * 0.3, Color(scrim, 0.8), Color(edge, 0.8), 1.8)
	UiText.draw(ci, str(p["label"]), Vector2(b.get_center().x, b.get_center().y - UiText.height(fs_b) * 0.5 + UiText.ascent(fs_b)), fs_b, ink, 0)
	UiText.no_outline = false
