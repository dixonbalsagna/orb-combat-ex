class_name UiLoading
extends RefCounted
## The planet's loading screen (docs/architecture/planet-load.md; docs/ui/planet-load.md). Simulation's `SimPlanetLoad` makes a gen 2 planet in slices before a match; while it does the host shows this:
## a calm dark ground, ONE short line saying what is being made (`phase`: plates, climate, rivers, places, ring) and a thin bar under it that fills with `progress` (0 to 1).
## Under the bar a Back button (Back to the menu, nothing kept: the host drops the load and the menu opens; Esc, a pad's B or a click or tap on it), there from the first frame, so no press goes unanswered.
## Nothing else: no title, no number, no tip, nothing that moves but the bar's end. No fade, no wipe, no blur, no flashing (Orb, ADR 0010): the screen is there while the planet loads and gone when it is
## ready, and the bar only ever grows (it redraws at most a hundred times, once a whole percent). It is the same dark ground as the start menu's. Words are data (prompt.load_*). `plan` is pure geometry
## so hud_check proves the line and the bar are on screen at every size; the HUD draws the plan in a layer of its own, over everything, and nothing here reads or writes the sim.

const PHASES: Array = ["plates", "climate", "rivers", "places", "ring"]


## The line for a phase (from the data); a phase this build does not know says the first one's general words.
static func line(phase: String) -> String:
	var key: String = "prompt.load_" + phase
	var t: String = UiData.t(key)
	return t if t != key else UiData.t("prompt.load_plates")


## {line, fs, line_pos (the baseline's start, centred), track, fill, progress, back (the button's rect, at least the menu's touch size), back_text, back_pos, fits}: the line over a thin bar over the Back button, centred in the safe area.
static func plan(vp: Vector2, s: float, dp: float, safe: Rect2, st: Dictionary) -> Dictionary:
	var progress: float = floorf(clampf(float(st.get("progress", 0.0)), 0.0, 1.0) * 100.0) / 100.0   # whole percents: the bar never creeps
	var txt: String = line(str(st.get("phase", "plates")))
	var area: Rect2 = vp_rect(vp, safe)
	var fs: int = UiText.px(22.0, s)
	var tw: float = UiText.width(txt, fs)
	var bar_w: float = clampf(area.size.x * 0.34, 200.0 * maxf(dp, 1.0), 440.0 * maxf(s, 1.0))
	bar_w = minf(bar_w, area.size.x - 32.0)
	var bar_h: float = maxf(6.0 * s, 5.0)
	var gap: float = float(fs) * 0.9
	var tm: float = maxf(48.0 * maxf(dp, 1.0), 44.0)   # the menu's own button height
	var back_text: String = UiData.t("prompt.load_back")
	var bfs: int = UiText.px(18.0, s)
	var btn_w: float = minf(maxf(UiText.width(back_text, bfs) + 2.0 * tm * 0.5, 2.0 * tm), area.size.x - 32.0)
	var gap2: float = float(fs) * 1.4
	var block_h: float = UiText.height(fs) + gap + bar_h + gap2 + tm
	var top: float = area.position.y + (area.size.y - block_h) * 0.5
	var cx: float = area.position.x + area.size.x * 0.5
	var base: float = top + UiText.ascent(fs)
	var track := Rect2(cx - bar_w * 0.5, top + UiText.height(fs) + gap, bar_w, bar_h)
	var fill := Rect2(track.position, Vector2(track.size.x * progress, track.size.y))
	var back := Rect2(cx - btn_w * 0.5, track.end.y + gap2, btn_w, tm)
	var back_pos := Vector2(cx, back.position.y + (tm + UiText.ascent(bfs) - (UiText.height(bfs) - UiText.ascent(bfs))) * 0.5)
	var fits: bool = tw <= area.size.x - 32.0 and area.encloses(track) and area.encloses(back) and area.encloses(Rect2(cx - tw * 0.5, top, tw, UiText.height(fs))) and UiText.width(back_text, bfs) <= btn_w
	return {"line": txt, "fs": fs, "line_pos": Vector2(cx, base), "track": track, "fill": fill, "progress": progress, "back": back, "back_text": back_text, "back_fs": bfs, "back_pos": back_pos, "fits": fits}


## Whether a point is on the Back button.
static func hit_back(p: Dictionary, pos: Vector2) -> bool:
	return (p["back"] as Rect2).has_point(pos)


static func vp_rect(vp: Vector2, safe: Rect2) -> Rect2:
	var r := Rect2(Vector2.ZERO, vp)
	if safe.size.x > 1.0 and safe.size.y > 1.0:
		r = safe.intersection(r)
	return r


## What the picture depends on: the line, the percent and where the bar and button are.
static func sig(p: Dictionary) -> Array:
	return [str(p["line"]), int(float(p["progress"]) * 100.0), int((p["track"] as Rect2).position.x), int((p["track"] as Rect2).position.y), int((p["track"] as Rect2).size.x), int((p["back"] as Rect2).position.y), int((p["back"] as Rect2).size.x)]


## The screen: the menu's dark ground, the line in the dim ink, the track in a thin edge and the fill in ink, and the Back button in the same edge and ink. Steady shapes only.
static func draw(ci: CanvasItem, p: Dictionary) -> void:
	UiMenu.draw_backdrop(ci)
	UiText.no_outline = true
	var track: Rect2 = p["track"]
	UiText.draw(ci, str(p["line"]), p["line_pos"], int(p["fs"]), Color(UiLook.col(UiLook.INK_DIM)), 0)
	var rr: float = track.size.y * 0.5
	UiIcons.rrect(ci, track, rr, Color(UiLook.col(UiLook.SCRIM), 0.9), Color(UiLook.col(UiLook.EDGE), 0.5), 1.5)
	var fill: Rect2 = p["fill"]
	if fill.size.x > 1.0:
		UiIcons.rrect(ci, fill.grow_individual(-1.0, -1.0, -1.0, -1.0) if fill.size.x > 3.0 else fill, rr * 0.8, Color(UiLook.col(UiLook.INK), 0.95), Color(0, 0, 0, 0), 0.0)
	var back: Rect2 = p["back"]
	UiIcons.rrect(ci, back, minf(back.size.y * 0.3, 14.0), Color(UiLook.col(UiLook.SCRIM), 0.9), Color(UiLook.col(UiLook.EDGE), 0.55), 1.5)
	UiText.draw(ci, str(p["back_text"]), p["back_pos"], int(p["back_fs"]), Color(UiLook.col(UiLook.INK)), 0)
	UiText.no_outline = false
