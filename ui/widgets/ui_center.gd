class_name UiCenter
## The top-centre pieces: the world toll chip (civilians lost, structures lost, craters) and the event banner.
## The banner sits under the toll chip, at the top, not mid-screen as in the prototype, so it never covers the fight.
## Banner words are renamed to the glossary's wording by UiData.banner() when the event arrives.

## The toll's type size: 20 design px, shrunk toward the text floor until the longest line fits the chip with a small margin. The
## population is whole people and can be four digits ("CIVILIANS LOST 1800 / 1800"), so a phone's narrow chip needs this.
static func toll_fs(lay: UiLayout, s: float, l1: String, l2: String) -> int:
	var fs: int = UiText.px(20.0, s)
	var room: float = lay.toll.size.x - 8.0
	var longest: String = l1 if lay.portrait or UiText.width(l1, fs) >= UiText.width(l2, fs) else l2
	while UiText.width(longest, fs) > room and fs > int(UiLook.text_floor):
		fs -= 1
		longest = l1 if lay.portrait or UiText.width(l1, fs) >= UiText.width(l2, fs) else l2
	return fs


## The share of the city's people lost, 0 to 1, in whole percents (so the bar steps at most a hundred times in a match and never creeps).
static func civilian_share(hub: UiEventHub) -> float:
	var pop: float = float(hub.toll["pop0"])
	if pop <= 0.0:
		return 0.0
	return floorf(clampf(float(hub.toll["civilians"]) / pop, 0.0, 1.0) * 100.0) / 100.0


## The bar's constant opacity: steady, it does not dim at rest or brighten when it grows (no flash, no blink).
const BAR_ALPHA := 0.85


static func draw_toll(ci: CanvasItem, hub: UiEventHub, lay: UiLayout, s: float, o: Dictionary) -> void:
	if UiData.feature("civilian_bar"):
		_draw_toll_bar(ci, hub, lay, s, o)
		return
	# The chip dims at rest and brightens for a moment after the toll changes: nothing sits bright over the fight.
	var a: float = float(o.get("plate_alpha", 1.0)) * lerpf(UiLook.TOLL_REST_ALPHA, 1.0, clampf(1.0 - hub.toll_age / UiLook.TOLL_SHOW, 0.0, 1.0))
	var r: Rect2 = lay.toll
	UiText.no_outline = true
	UiText.defer = true
	UiIcons.rrect(ci, r, 8.0 * s, Color(UiLook.col(UiLook.SCRIM), UiLook.SCRIM_ALPHA * a), Color(UiLook.col(UiLook.EDGE), 0.3 * a), 1.2)
	var l1: String = "%s %d / %d" % [UiData.t("toll.civilians"), int(hub.toll["civilians"]), int(hub.toll["pop0"])]
	var l2: String = "%s %d    %s %d" % [UiData.t("toll.structures"), int(hub.toll["structures"]), UiData.t("toll.craters"), int(hub.toll["craters"])]
	var fs: int = toll_fs(lay, s, l1, l2)
	var y1: float = r.position.y + (8.0 if not lay.portrait else 5.0) + UiText.ascent(fs)
	UiText.draw(ci, l1, Vector2(r.get_center().x, y1), fs, Color(UiLook.col(UiLook.INK), a), 0, 1.5)
	if not lay.portrait:
		# Portrait keeps the civilians line only: the phone's fight window is too small for a second line.
		UiText.draw(ci, l2, Vector2(r.get_center().x, y1 + float(fs) + 3.0), fs, Color(UiLook.col(UiLook.INK_DIM), a), 0, 1.5)
	UiText.flush(ci)
	UiText.no_outline = false


## Where the words and the bar sit in the chip: {fs, x0, lw, y1 (the words' baseline), track (the bar's outline)}. The words and the bar are centred as one row.
static func bar_plan(lay: UiLayout, s: float) -> Dictionary:
	var r: Rect2 = lay.toll
	var label: String = UiData.t("toll.civilians")
	var l2: String = "%s %d    %s %d" % [UiData.t("toll.structures"), 0, UiData.t("toll.craters"), 0]
	var fs: int = toll_fs(lay, s, label + "  MMMMMMMM", l2)   # room for the words and a bar of at least eight letters' width
	var lw: float = UiText.width(label, fs)
	var gap: float = 10.0 * s
	var bar_w: float = clampf(r.size.x - lw - gap - 24.0 * s, 56.0 * s, 170.0 * s)
	var x0: float = r.get_center().x - (lw + gap + bar_w) * 0.5
	var y1: float = r.position.y + (8.0 if not lay.portrait else 5.0) + UiText.ascent(fs)
	var bh: float = maxf(8.0 * s, 7.0)
	var track := Rect2(x0 + lw + gap, y1 - UiText.ascent(fs) * 0.5 - bh * 0.5 + float(fs) * 0.18, bar_w, bh)
	return {"fs": fs, "x0": x0, "lw": lw, "y1": y1, "track": track}


## The chip with the bar: the words CIVILIANS LOST and, beside them, a thin outlined bar filled to the share lost (quarter marks on it), no number. The structures and craters line
## stays but, like the bar, holds one opacity. The bar is a shape, never a hue: the fill is ink.
static func _draw_toll_bar(ci: CanvasItem, hub: UiEventHub, lay: UiLayout, s: float, o: Dictionary) -> void:
	var a: float = float(o.get("plate_alpha", 1.0)) * BAR_ALPHA
	var r: Rect2 = lay.toll
	UiText.no_outline = true
	UiText.defer = true
	UiIcons.rrect(ci, r, 8.0 * s, Color(UiLook.col(UiLook.SCRIM), UiLook.SCRIM_ALPHA * a), Color(UiLook.col(UiLook.EDGE), 0.3 * a), 1.2)
	var label: String = UiData.t("toll.civilians")
	var l2: String = "%s %d    %s %d" % [UiData.t("toll.structures"), int(hub.toll["structures"]), UiData.t("toll.craters"), int(hub.toll["craters"])]
	var bp: Dictionary = bar_plan(lay, s)
	var fs: int = int(bp["fs"])
	var y1: float = float(bp["y1"])
	UiText.draw(ci, label, Vector2(float(bp["x0"]), y1), fs, Color(UiLook.col(UiLook.INK), a), -1, 1.5)
	var track: Rect2 = bp["track"]
	var bh: float = track.size.y
	UiIcons.rrect(ci, track, bh * 0.4, Color(0, 0, 0, 0.35 * a), Color(UiLook.col(UiLook.INK), 0.85 * a), 1.6)
	var share: float = civilian_share(hub)
	if share > 0.0:
		var inner := track.grow(-2.0)
		ci.draw_rect(Rect2(inner.position, Vector2(maxf(inner.size.x * share, 2.0), inner.size.y)), Color(UiLook.col(UiLook.INK), a))
	for q in [0.25, 0.5, 0.75]:
		var qx: float = track.position.x + track.size.x * float(q)
		ci.draw_line(Vector2(qx, track.position.y - 2.0), Vector2(qx, track.position.y + bh + 2.0), Color(UiLook.col(UiLook.INK), 0.55 * a), 1.2)
	if not lay.portrait:
		UiText.draw(ci, l2, Vector2(r.get_center().x, y1 + float(fs) + 3.0), fs, Color(UiLook.col(UiLook.INK_DIM), a), 0, 1.5)
	UiText.flush(ci)
	UiText.no_outline = false


static func draw_banner(ci: CanvasItem, hub: UiEventHub, lay: UiLayout, s: float, o: Dictionary) -> void:
	if hub.banner.is_empty() or hub.world_card != null or not hub.telegraph.is_empty():
		return   # a world card (the fold) takes the banner's slot; the banner waits (its clock is paused, see the hub)
	var b: Dictionary = hub.banner
	var age: float = float(b["age"])
	var dur: float = float(b["dur"])
	var k: float = 1.0
	if age < 0.12:
		k = age / 0.12
	elif age > dur - 0.3:
		k = maxf(0.0, (dur - age) / 0.3)
	var reduced: bool = bool(o.get("reduced_motion", false))
	var fs: int = UiText.px(clampf(lay.vp.x * 0.03, 30.0, 46.0) / maxf(s, 0.01), s, 22.0)
	var c: Color = UiLook.col(str(b["col"]))
	var rise: float = 0.0 if reduced else (1.0 - k) * 8.0
	var pos: Vector2 = lay.banner_c + Vector2(0.0, rise + float(fs) * 0.35)
	UiText.draw(ci, str(b["text"]), pos, fs, Color(c.r, c.g, c.b, k), 0, maxf(2.0, float(fs) * 0.09))
