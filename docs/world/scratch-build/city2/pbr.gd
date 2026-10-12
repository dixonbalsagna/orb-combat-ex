extends SceneTree
# the people by row and the buildings' heights: how many stand on each street side, tallest, downtown median, aspect
func _init() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false})
	var pr := {}
	var nr := {}
	var hs: Array = []
	var asp: Array = []
	var tall := 0.0
	for b in S.buildings:
		var r: int = int(b.row)
		pr[r] = pr.get(r, 0.0) + b.pop
		nr[r] = nr.get(r, 0) + 1
		tall = maxf(tall, b.h / 75.0)
		if b.kind == "tower":
			hs.append(b.h / 75.0)
			asp.append(b.h / maxf(minf(b.w, b.d), 1.0))
	hs.sort()
	asp.sort()
	var s := "PBR people by row (row 1 is the fight's sidewalk): "
	for r in [0, 1, 2, 3]:
		s += "row %d %d people in %d buildings; " % [r, int(pr.get(r, 0.0)), nr.get(r, 0)]
	s += "| towers %d: height bh median %.1f p90 %.1f max %.1f | aspect median %.1f p90 %.1f max %.1f | pop0 %.0f buildings %d" % [hs.size(), hs[hs.size() / 2], hs[int(hs.size() * 0.9)], tall, asp[asp.size() / 2], asp[int(asp.size() * 0.9)], asp[-1], S.world.pop0, S.buildings.size()]
	print(s)
	quit(0)
