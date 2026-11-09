class_name UiRail
extends RefCounted
## The Rail menu frame (docs/ui/menus-rail.md; Orb picked it on 2026-11-09 from docs/ui/mockups/menus-modern/a-rail.html). One frame for the start menu, the pause menu and the match-over card, and a Rail skin for Settings:
## a dark rail down the left edge with the screen's name and its rows, the lit row a solid bar with a gold notch (a shape, not only a colour), the detail on the right, and the buttons for the player's own device along the
## the bottom. Everything here is geometry and drawing from a plan (the screens' own plans call it, and keep their old layout wherever the Rail does not fit). Switch: features.json `menus_rail` (off).
##
## Motion (ADR 0010: no fades, wipes or blur): the rail slides in from its own edge in 180 ms with an ease-out, and the lit bar slides between rows in 140 ms; both are cuts under Reduce motion. Nothing here pulses.

const GOLD := Color(0.95, 0.76, 0.31)
const SLIDE_SECS := 0.18
const BAR_SECS := 0.14
const MIN_W := 1000.0
const MIN_H := 600.0


## Whether the Rail lays this screen out: the switch is on, it is not a touch screen (phone work is parked, ADR 0011), and the screen is wide and tall enough for the rail and its detail. Anything else keeps the old layout.
static func usable(vp: Vector2, touch: bool) -> bool:
	return UiData.feature("menus_rail") and not touch and vp.x >= MIN_W and vp.y >= MIN_H and vp.x >= vp.y * 1.3


static func ease_out(k: float) -> float:
	var c: float = clampf(k, 0.0, 1.0)
	return 1.0 - pow(1.0 - c, 3.0)


## How far the rail has slid in, 0 to 1, `since` seconds after the screen opened.
static func slide(since: float, reduced: bool) -> float:
	return 1.0 if reduced else ease_out(since / SLIDE_SECS)


## Where the lit bar's top is: between the previous row's top and this row's top while it slides.
static func bar_y(row_ys: Array, focus: int, prev: int, since: float, reduced: bool) -> float:
	if row_ys.is_empty():
		return 0.0
	var to_y: float = float(row_ys[clampi(focus, 0, row_ys.size() - 1)])
	if reduced or prev < 0 or prev >= row_ys.size() or since >= BAR_SECS:
		return to_y
	return lerpf(float(row_ys[prev]), to_y, ease_out(since / BAR_SECS))


## The sizes every Rail screen shares, for a viewport and the HUD's scale.
static func metrics(vp: Vector2, s: float, dp: float) -> Dictionary:
	var cs: float = maxf(s, 0.3)
	return {"cs": cs, "x0": maxf(34.0 * cs, 20.0), "rw": clampf(vp.x * 0.30, 300.0, 480.0 * maxf(cs, 1.0)), "tm": maxf(48.0 * dp, 44.0), "rh": maxf(52.0 * cs, maxf(48.0 * dp, 44.0)), "gap": maxf(6.0 * cs, 4.0),
		"fs_kicker": UiText.px(15.0, cs), "fs_title": UiText.px(40.0, cs), "fs_row": UiText.px(25.0, cs), "fs_val": UiText.px(19.0, cs), "fs_small": UiText.px(17.0, cs), "hint_h": maxf(56.0 * cs, 44.0)}


# --- The buttons for the player's own device -------------------------------------------------------------------------------

## The hint strip's entries as glyph specs: ids are "accept", "back", "start", "move", "change" and "tabs"; `device` is "kbd" or "pad", `style` the player's glyph style. A pad shows the pad's marks, a keyboard its caps, never both.
static func hint_specs(device: String, id: String, style: String) -> Array:
	var pad: bool = device != "kbd"
	match id:
		"accept":
			return [UiGlyphs.spec_control("pad:south", "xbox", style)] if pad else [{"kind": "key", "label": "Enter"}]
		"back":
			return [UiGlyphs.spec_control("pad:east", "xbox", style)] if pad else [{"kind": "key", "label": "Esc"}]
		"start":
			return [UiGlyphs.spec_control("pad:start", "xbox", style)] if pad else [{"kind": "key", "label": "P"}]
		"move", "change":
			return [{"kind": "dpad", "dir": "all", "label": ""}] if pad else [{"kind": "key", "label": "Arrows"}]
		"tabs":
			return [UiGlyphs.spec_control("pad:lb", "xbox", style), UiGlyphs.spec_control("pad:rb", "xbox", style)] if pad else [{"kind": "key", "label": "Q"}, {"kind": "key", "label": "E"}]
	return []


## Pairs [[id, word], ...] as entries {specs, word, w}, each as wide as its glyphs and word at these sizes.
static func hint_entries(device: String, style: String, pairs: Array, gh: float, fs: int) -> Array:
	var out: Array = []
	for pr in pairs:
		var specs: Array = hint_specs(device, str(pr[0]), style)
		var gw: float = 0.0
		for sp in specs:
			gw += UiGlyphs.width_spec(sp, gh) + gh * 0.12
		out.append({"specs": specs, "word": str(pr[1]), "gw": gw, "w": gw + gh * 0.3 + UiText.width(str(pr[1]), fs)})
	return out


static func hints_width(entries: Array, gap: float) -> float:
	var w: float = 0.0
	for e in entries:
		w += float(e["w"]) + gap
	return maxf(w - gap, 0.0)


## Draw the strip from its left end, vertically centred on `cy`; returns the right end.
static func draw_hints(ci: CanvasItem, entries: Array, x: float, cy: float, gh: float, fs: int, gap: float, alpha: float) -> float:
	var dim := Color(UiLook.col(UiLook.INK_DIM), alpha)
	for e in entries:
		var gx: float = x
		for sp in e["specs"]:
			gx += UiGlyphs.draw_spec(ci, sp, Vector2(gx, cy), gh, alpha, true) + gh * 0.12
		UiText.draw(ci, str(e["word"]), Vector2(x + float(e["gw"]) + gh * 0.3, cy + float(fs) * 0.35), fs, dim, -1)
		x += float(e["w"]) + gap
	return x


# --- Drawing -------------------------------------------------------------------------------------------------------------

## The dark rail panel and its edge line, `off` pixels left of its place (the slide), with the title block: a small kicker line over the big title.
static func draw_panel(ci: CanvasItem, rail: Rect2, off: float) -> void:
	var scrim := Color(UiLook.col(UiLook.SCRIM), 0.96)
	ci.draw_rect(Rect2(rail.position + Vector2(off, 0.0), rail.size), scrim)
	ci.draw_line(Vector2(rail.end.x + off, rail.position.y), Vector2(rail.end.x + off, rail.end.y), Color(UiLook.col(UiLook.EDGE), 0.28), 1.5)


## The lit bar: a solid ink bar the row's width with the gold notch at its left edge.
static func draw_bar(ci: CanvasItem, r: Rect2, cs: float) -> void:
	UiIcons.rrect(ci, r, minf(12.0 * cs, r.size.y * 0.3), Color(UiLook.col(UiLook.INK), 0.95))
	var nh: float = maxf(r.size.y - 24.0 * cs, r.size.y * 0.4)
	UiIcons.rrect(ci, Rect2(r.position.x + maxf(5.0 * cs, 3.0), r.get_center().y - nh * 0.5, maxf(5.0 * cs, 3.0), nh), 2.0, GOLD)


## A row's words: the label at the left, the value (and a small chevron when it can change) at the right, in the dark ink over the lit bar and the light ink over the rail.
static func draw_row_text(ci: CanvasItem, r: Rect2, label: String, value: String, lit: bool, fs: int, fs_val: int, enabled: bool = true) -> void:
	var ink := Color(UiLook.col(UiLook.INK_DARK)) if lit else Color(UiLook.col(UiLook.INK), 1.0 if enabled else 0.45)
	var dim := Color(UiLook.col(UiLook.INK_DARK), 0.7) if lit else Color(UiLook.col(UiLook.INK_DIM), 1.0 if enabled else 0.45)
	var px: float = r.position.x + maxf(r.size.y * 0.4, 14.0)
	UiText.draw(ci, label, Vector2(px, r.get_center().y + float(fs) * 0.35), fs, ink, -1)
	if value != "":
		UiText.draw(ci, value, Vector2(r.end.x - maxf(r.size.y * 0.3, 12.0), r.get_center().y + float(fs_val) * 0.35), fs_val, dim, 1)


## A detail card: a rounded dark panel with a small kicker and its lines (each {t: the text, dim: a quieter line}).
static func draw_card(ci: CanvasItem, r: Rect2, kicker: String, lines: Array, fs_kicker: int, fs: int, cs: float) -> void:
	UiIcons.rrect(ci, r, 16.0 * cs, Color(UiLook.col(UiLook.SCRIM), 0.95), Color(UiLook.col(UiLook.EDGE), 0.28), 1.5)
	var x: float = r.position.x + maxf(24.0 * cs, 14.0)
	var y: float = r.position.y + maxf(20.0 * cs, 12.0)
	if kicker != "":
		UiText.draw(ci, kicker.to_upper(), Vector2(x, y + UiText.ascent(fs_kicker)), fs_kicker, Color(UiLook.col(UiLook.INK_DIM), 0.9), -1)
		y += UiText.height(fs_kicker) * 1.5
	for ln in lines:
		var dim: bool = bool((ln as Dictionary).get("dim", false))
		var txt: String = str((ln as Dictionary)["t"])
		UiText.draw(ci, txt,Vector2(x, y + UiText.ascent(fs)), fs, Color(UiLook.col(UiLook.INK_DIM) if dim else UiLook.col(UiLook.INK), 0.95), -1)
		y += UiText.height(fs) * 1.2
