class_name VfxPanes
extends RefCounted
## Where a building's panes are, as Rendering draws them (building.gdshader section 7, shapes.gd's looks): the glass VFX throws starts from a pane, not from a spot on the wall.
## A district look gives the column pitch (a column every `pitch` units along the wall: ncol = floor(width / pitch)), the pane's span across its cell and the share of cells that have
## one, the pane's span up its row and the strips a row; a floor taller than RenderShapes.ROW_H carries more than one row (RenderShapes.rows). The numbers are read from
## RenderShapes and the sim's lane table at the moment, never copied, so a look Art changes moves the glass with it. The shader decides which cells have a pane by a hash of the
## drawn part's instance, which VFX cannot read: the glass is thrown from the pane positions of the look and is right to the cell, not to the hash.
## Presentation only: reads the sim and RenderShapes, writes nothing.


## The pane grid of building b ({} for a building with no windows): x0 the wall's left edge, cw a cell's width, ncol, cx the pane's centre across its cell (0 to 1), pw its width,
## base the wall's foot (world y), fh a floor's height, rows rows a floor, strips strips a row, cy the pane's centre up a strip (0 to 1), ph its height, share the cells that have one.
static func grid(S: SimState, b) -> Dictionary:
	var floors: int = maxi(int(b.floors), 1)
	var fh: float = float(b.h) / float(floors)
	if fh <= 1.0 or float(b.w) <= 1.0:
		return {}
	var lk: Dictionary = RenderShapes.look(RenderShapes.look_of(RenderLanes.table(S), b))
	var win: Array = lk.get("win", [])
	var pane: Array = lk.get("pane", [])
	if win.size() < 4 or pane.size() < 3:
		return {}
	var pitch: float = maxf(float(win[0]), 1.0)
	var ncol: int = maxi(1, int(floor(float(b.w) / pitch)))
	var rows: int = RenderShapes.rows(fh)
	var strips: int = 2 if float(pane[2]) > 1.5 else 1
	var cw: float = float(b.w) / float(ncol)
	# The drawn silhouette: the shapes that narrow toward the top (stepped, crown, spire, gable) are narrower than the sim's box up there (docs/rendering/lanes-look.md), so glass and
	# cladding thrown from the box's width up there would start in the air beside the wall. Each part: [x offset from the centre, width, bottom, top, top's width share], heights above the foot.
	var sil: Array = []
	for p in RenderShapes.parts(b, lk):
		sil.append([float(p[RenderShapes.X]), float(p[RenderShapes.W]), float(p[RenderShapes.Y0]), float(p[RenderShapes.Y1]), float(p[RenderShapes.TX])])
	return {
		"x0": float(b.x) - float(b.w) * 0.5, "cw": cw, "ncol": ncol, "cx": 0.5 * (float(win[1]) + float(win[2])), "pw": maxf((float(win[2]) - float(win[1])) * cw, 2.0),
		"base": WorldStructures.baseY(S, b), "fh": fh, "rows": rows, "strips": strips, "cy": 0.5 * (float(pane[0]) + float(pane[1])),
		"ph": maxf((float(pane[1]) - float(pane[0])) * fh / float(rows * strips), 2.0), "share": float(win[3]), "floors": floors,
		"cxb": float(b.x), "top": float(b.h), "sil": sil,
	}


## A point (px, py) on the building's wall pulled inside the drawn silhouette: where a narrowing part is thinner than the box, x goes in to its edge; above the highest part, y goes
## down to its top. The point itself when the grid has no silhouette or it is inside.
static func clamp_point(g: Dictionary, px: float, py: float) -> Vector2:
	if g.is_empty() or not g.has("sil") or (g["sil"] as Array).is_empty():
		return Vector2(px, py)
	var yy: float = py - float(g["base"])
	var best_in: bool = false
	var lo: float = 0.0
	var hi: float = 0.0
	var top: float = 0.0
	var dx: float = SimWrap.sdx(float(g["cxb"]), px)
	for pt in g["sil"]:
		top = maxf(top, float(pt[3]))
		if yy >= float(pt[2]) and yy <= float(pt[3]):
			var t: float = clampf((yy - float(pt[2])) / maxf(float(pt[3]) - float(pt[2]), 1.0), 0.0, 1.0)
			var wd: float = float(pt[1]) * lerpf(1.0, float(pt[4]), t)
			var a: float = float(pt[0]) - wd * 0.5
			var c: float = float(pt[0]) + wd * 0.5
			if not best_in:
				lo = a
				hi = c
				best_in = true
			else:
				lo = minf(lo, a)
				hi = maxf(hi, c)
	if not best_in:
		return Vector2(px, float(g["base"]) + minf(yy, top))
	return Vector2(SimWrap.wrap(float(g["cxb"]) + clampf(dx, lo, hi)), py)


## The centre of the nearest pane to a world point (px, py) on that wall, and its size, as Vector4(x, y, width, height); the point itself with no grid.
static func nearest(g: Dictionary, px: float, py: float) -> Vector4:
	if g.is_empty():
		return Vector4(px, py, 0.0, 0.0)
	var cp: Vector2 = clamp_point(g, px, py)
	px = cp.x
	py = cp.y
	var col: int = clampi(int(floor((px - float(g["x0"])) / float(g["cw"]))), 0, int(g["ncol"]) - 1)
	var x: float = float(g["x0"]) + (float(col) + float(g["cx"])) * float(g["cw"])
	var fy: float = clampf((py - float(g["base"])) / float(g["fh"]), 0.0, float(g["floors"]) - 0.001)
	var fl: float = floor(fy)
	var fr: float = (fy - fl) * float(g["rows"])
	var row: float = floor(fr)
	var ry: float = fr - row
	var strips: int = int(g["strips"])
	var yfrac: float = float(g["cy"])
	if strips == 2:
		var s: float = 0.0 if ry < 0.5 else 1.0
		yfrac = (s + float(g["cy"])) * 0.5
	var y: float = float(g["base"]) + (fl + (row + yfrac) / float(g["rows"])) * float(g["fh"])
	var inside: Vector2 = clamp_point(g, x, y)      # a pane's centre on a narrowing part may fall outside it: the glass starts at the part's edge then
	return Vector4(inside.x, inside.y, float(g["pw"]), float(g["ph"]))
