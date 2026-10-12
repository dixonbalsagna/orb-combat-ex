extends SceneTree
func _init() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false})
	var t: PackedFloat32Array = S.lanes
	var nd: int = int(t[3])
	var oD: int = int(t[12])
	var tot: float = 0.0
	var parts: Array = []
	for i in range(nd):
		var x0: float = t[oD + 6 * i]
		var x1: float = t[oD + 6 * i + 1]
		tot += x1 - x0
		parts.append("%.0f-%.0f" % [x0, x1])
	print("SP districts total %.0f units of %.0f (%.1f%%): %s" % [tot, SimConst.W, 100.0 * tot / SimConst.W, ", ".join(parts)])
	var xs: Array = []
	for b in S.buildings:
		if int(b.row) == 1:
			xs.append(b.x)
	xs.sort()
	print("SP row 1 buildings %d from x %.0f to %.0f; start x %.0f" % [xs.size(), xs[0], xs[-1], SimConst.START_X])
	quit()
