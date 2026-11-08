class_name UiCenter
## The top-centre pieces: the world damage chip (structures lost, craters) and the event banner.
## The banner sits under the damage chip, at the top, not mid-screen as in the prototype, so it never covers the fight.
## Banner words are renamed to the glossary's wording by UiData.banner() when the event arrives.

## The damage chip's type size: 20 design px, shrunk toward the text floor until its line fits the chip with a small margin (four-digit counts on a phone's narrow chip).
static func chip_fs(lay: UiLayout, s: float, line: String) -> int:
	var fs: int = UiText.px(20.0, s)
	var room: float = lay.damage_chip.size.x - 8.0
	while UiText.width(line, fs) > room and fs > int(UiLook.text_floor):
		fs -= 1
	return fs


## The chip's constant opacity under damage_facts: steady, it does not dim at rest or brighten when it grows (no flash, no blink).
const STEADY_ALPHA := 0.85


## The chip's one line: what the fight has done to the world's buildings and ground. Nothing here counts or names people (RL-257, lint c11).
static func chip_line(hub: UiEventHub) -> String:
	return "%s %d    %s %d" % [UiData.t("damage.structures"), int(hub.damage["structures"]), UiData.t("damage.craters"), int(hub.damage["craters"])]


static func draw_chip(ci: CanvasItem, hub: UiEventHub, lay: UiLayout, s: float, o: Dictionary) -> void:
	var a: float = float(o.get("plate_alpha", 1.0))
	if UiData.feature("damage_facts"):
		a *= STEADY_ALPHA
	else:
		# The chip dims at rest and brightens for a moment after the damage changes: nothing sits bright over the fight.
		a *= lerpf(UiLook.DAMAGE_REST_ALPHA, 1.0, clampf(1.0 - hub.damage_age / UiLook.DAMAGE_SHOW, 0.0, 1.0))
	var r: Rect2 = lay.damage_chip
	UiText.no_outline = true
	UiText.defer = true
	UiIcons.rrect(ci, r, 8.0 * s, Color(UiLook.col(UiLook.SCRIM), UiLook.SCRIM_ALPHA * a), Color(UiLook.col(UiLook.EDGE), 0.3 * a), 1.2)
	var line: String = chip_line(hub)
	var fs: int = chip_fs(lay, s, line)
	var y1: float = r.get_center().y - UiText.height(fs) * 0.5 + UiText.ascent(fs)
	UiText.draw(ci, line, Vector2(r.get_center().x, y1), fs, Color(UiLook.col(UiLook.INK), a), 0, 1.5)
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
