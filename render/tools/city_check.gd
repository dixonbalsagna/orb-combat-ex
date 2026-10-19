extends SceneTree
## City check (docs/rendering/city-variety.md): Art's city palettes and facade types as building.gdshader draws them
## (7c), against the contrast budget (RenderLook.PATTERN_BUDGET, 0.085 of relative luminance) between neighbouring
## elements as well as against the wall: Legal's w05 (RL-144). For each of Art's tints and each facade type, the tones
## the shader draws side by side (the wall, the dark and bright glass, the spandrel band, a fin and its sun side, the
## lobby storey's wall, its lintel and the crown's cornice; each first held to the wall, as the shader holds it) must
## differ by no more than the budget. Lit panes are not held to it (they are light, not facade). Reads the data whatever
## RenderLook.CITY_TINTS and CITY_FACADES say; with no data it checks nothing and says so.
##   godot --headless --path . --script res://render/tools/city_check.gd

var fails: int = 0


func _initialize() -> void:
	_run()
	quit(1 if fails > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print("%s %s" % ["ok   " if ok else "FAIL ", what])
	if not ok:
		fails += 1


## Relative luminance of an sRGB colour, in linear light (building.gdshader's lum).
static func _lum(c: Color) -> float:
	var l: Color = c.srgb_to_linear()
	return 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b


## A tone held to the wall's luminance by the budget (building.gdshader's toward, in luminance).
static func _held(wall: float, x: float) -> float:
	return clampf(x, wall - RenderLook.PATTERN_BUDGET, wall + RenderLook.PATTERN_BUDGET)


func _run() -> void:
	var c: Dictionary = RenderShapes.city_data()
	var tints: Array = RenderShapes.city_tints()
	if c.is_empty() or tints.is_empty():
		_expect(true, "no city data (data/art/city-looks.json): the towers draw in their looks; nothing to check")
		return
	_expect(tints.size() <= RenderShapes.CITY_SLOTS, "Art's %d tints fit building.gdshader's arrays (%d)" % [tints.size(), RenderShapes.CITY_SLOTS])
	var u: Dictionary = RenderShapes.city_uniforms()
	var budget: float = RenderLook.PATTERN_BUDGET
	var worst: Dictionary = {}     # a facade type (and the base and crown): [the widest step, between what, in which tint]
	for key in RenderShapes.FACADES + ["base", "crown"]:
		worst[key] = [0.0, "", ""]
	for i in range(mini(tints.size(), RenderShapes.CITY_SLOTS)):
		var t: Dictionary = tints[i][1]
		var name: String = "%s %s" % [tints[i][0], t.get("id", "")]
		var w: float = _lum(RenderLook.col(str(t["wall"]["shadow"])))
		var k: Vector4 = u["city_k"][i]
		var k2: Vector4 = u["city_k2"][i]
		var g: float = _held(w, _lum(u["city_glass"][i]))
		var gb: float = _held(w, _lum(u["city_hi"][i]))
		var tr: float = _held(w, _lum(u["city_trim"][i]))
		var tones: Dictionary = {
			"wall": w, "glass": g, "bright glass": gb, "cornice": tr,
			"ribbon spandrel": _held(w, w * k.x), "punched spandrel": _held(w, w * k.y),
			"fin": _held(w, w * k.z), "fin's sun side": _held(w, w * k.w),
			"lobby wall": _held(w, w * float((u["city_glass"][i] as Color).a)),
			"balcony spandrel": _held(w, w * k2.x), "balcony slab": _held(w, w * k2.y),
		}
		# What stands beside what on each (building.gdshader 7c): a pane beside the wall and the band under it, a fin
		# beside its other side, the wall and the glass; the lobby storey's wall beside its panes and the lintel, the
		# lintel beside the wall over it; the crown's bright panes beside the wall and the cornice line.
		var pairs: Dictionary = {
			"ribbon": [["glass", "wall"], ["bright glass", "wall"], ["glass", "ribbon spandrel"], ["bright glass", "ribbon spandrel"], ["ribbon spandrel", "wall"]],
			"punched": [["glass", "wall"], ["bright glass", "wall"], ["glass", "punched spandrel"], ["bright glass", "punched spandrel"], ["punched spandrel", "wall"]],
			"balconied": [["glass", "wall"], ["bright glass", "wall"], ["glass", "balcony spandrel"], ["bright glass", "balcony spandrel"], ["balcony spandrel", "wall"], ["balcony slab", "wall"]],
			"fins": [["glass", "wall"], ["bright glass", "wall"], ["glass", "fin"], ["glass", "fin's sun side"], ["bright glass", "fin"], ["bright glass", "fin's sun side"], ["fin", "fin's sun side"], ["fin", "wall"], ["fin's sun side", "wall"]],
			"base": [["lobby wall", "glass"], ["lobby wall", "bright glass"], ["lobby wall", "cornice"], ["cornice", "wall"]],
			"crown": [["bright glass", "wall"], ["cornice", "wall"], ["cornice", "bright glass"]],
		}
		for key in pairs:
			for p in pairs[key]:
				var d: float = absf(float(tones[p[0]]) - float(tones[p[1]]))
				if d > float(worst[key][0]):
					worst[key] = [d, "%s and %s" % [p[0], p[1]], name]
	for key in worst:
		var wst: Array = worst[key]
		_expect(float(wst[0]) <= budget + 1e-6, "%s: no two neighbouring tones differ by more than the budget (the widest step %.3f of relative luminance, %s, %s; the budget %.3f)" % [key, float(wst[0]), wst[1], wst[2], budget])
	# For comparison, the same fin on Art's mid tone as the data gives it (Art's sheet), before the render scales a facade
	# to the shadow tone it masses a tower in: the step Legal's w05 measured.
	var art_fin: float = 0.0
	var fin_scaled: float = 0.0
	for i in range(mini(tints.size(), RenderShapes.CITY_SLOTS)):
		var t: Dictionary = tints[i][1]
		var lm: float = _lum(RenderLook.col(str(t["wall"]["mid"])))
		var k: Vector4 = u["city_k"][i]
		var w: float = _lum(RenderLook.col(str(t["wall"]["shadow"])))
		art_fin = maxf(art_fin, (k.w - k.z) * lm)
		fin_scaled = maxf(fin_scaled, absf(_held(w, w * k.w) - _held(w, w * k.z)))
	print("      a fin's two sides on Art's mid tone, as the data gives them: %.3f; as drawn on the tower's mass tone: %.3f" % [art_fin, fin_scaled])
	print("      switches: CITY_TINTS %s, CITY_FACADES %s" % [str(RenderLook.CITY_TINTS), str(RenderLook.CITY_FACADES)])
