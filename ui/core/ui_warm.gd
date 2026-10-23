class_name UiWarm
extends Control
## The HUD's text warm-up at boot. The first time a font is asked for a glyph at a size (and, for an outline, at an outline width), the text server draws that glyph
## into the font's atlas and the renderer uploads the texture: on an integrated GPU that is a hitch of tens of milliseconds the first time a banner, a bark or a card
## reaches the screen (VFX's finding: tick 36 of the city beam scene, the first signature wind-up, where the banner's text is drawn at its size for the first time).
## So at boot, behind the flashing-effects notice, one line of the common glyphs is drawn once at every size and outline the HUD uses, in a node nobody sees
## (1% opaque for three frames), and the node frees itself. Presentation only: it reads no sim state, writes none, and draws nothing a player can read.
## Sizes are the HUD's own: the design sizes its widgets pass to UiText.px (the plates 24, 20 and 18, the legend, the cards, the barks, the hints, the toll), and the banner's
## own fit, each at the layout's scale. Outlines are the ones UiText.draw asks for (2 px for barks and card titles, and the banner's 9% of its size).

const DESIGN_SIZES: Array = [14.0, 15.0, 16.0, 18.0, 19.0, 20.0, 22.0, 23.0, 24.0, 28.0, 30.0, 34.0, 36.0, 38.0]
const GLYPHS := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:;!?'\"-+()/%[]&x*"
const FRAMES := 3
const OPACITY := 0.012

var pairs: Array = []        # [font size, outline px], what is drawn (for the checks)
var _frames: int = 0


## The sizes and outlines for a layout scale and viewport: pure, so the checks read the same list the draw uses.
static func plan(scale: float, vp: Vector2) -> Array:
	var out: Array = []
	var seen := {}
	for d in DESIGN_SIZES:
		var fs: int = UiText.px(float(d), scale)
		for ol in ([0, 2] if fs >= 16 else [0]):
			var key: String = "%d/%d" % [fs, ol]
			if not seen.has(key):
				seen[key] = true
				out.append([fs, ol])
	var bfs: int = UiText.px(clampf(vp.x * 0.03, 30.0, 46.0) / maxf(scale, 0.01), scale, 22.0)   # the banner's size, as UiCenter.draw_banner fits it
	var bol: int = int(ceil(maxf(2.0, float(bfs) * 0.09)))
	for pr in [[bfs, bol], [bfs, 0]]:
		var key2: String = "%d/%d" % [pr[0], pr[1]]
		if not seen.has(key2):
			seen[key2] = true
			out.append(pr)
	return out


func start(scale: float, vp: Vector2) -> void:
	pairs = plan(scale, vp)
	position = Vector2.ZERO
	size = vp
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = Color(1.0, 1.0, 1.0, OPACITY)
	queue_redraw()


func _process(_dt: float) -> void:
	_frames += 1
	queue_redraw()
	if _frames > FRAMES:
		queue_free()


func _draw() -> void:
	var fnt: Font = UiText.f()
	var col := Color(1.0, 1.0, 1.0, 1.0)
	var ol := Color(0.03, 0.04, 0.07, 1.0)
	var y: float = 24.0
	var x: float = 8.0
	for pr in pairs:
		var fs: int = int(pr[0])
		var w: float = fnt.get_string_size(GLYPHS, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		if y > size.y - float(fs):
			y = 24.0
			x += 16.0   # the rows past the bottom of the window are still drawn (the glyphs are made when the line is drawn); they just overlap
		if int(pr[1]) > 0:
			draw_string_outline(fnt, Vector2(x, y), GLYPHS, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(pr[1]), ol)
		draw_string(fnt, Vector2(x, y), GLYPHS, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		y += float(fs) * 1.25
		if w < 0.0:
			break
