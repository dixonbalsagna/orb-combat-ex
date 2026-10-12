extends SceneTree
func _init() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false})
	var ix: Array = WorldLanes.intersections(S, 46599.0, 3000.0)
	var c0: Array = ix[0]
	var st: Array = WorldLanes.streets()
	var z0: float = (st[0][0] + st[0][1]) * 0.5
	var a: Array = WorldLanes.crossingAlong(S, c0[0], z0, -1.0)
	var b: Array = WorldLanes.crossingAlong(S, c0[0], a[1], -1.0)
	var c: Array = WorldLanes.crossingAlong(S, c0[0], b[1], -1.0)
	var d: Array = WorldLanes.crossingAlong(S, c0[0], b[1], 1.0)
	print("CA from the front street deeper: ", a, " then ", b, " then ", c, " back toward the camera from the back street: ", d)
	print("CA no avenue in reach: ", WorldLanes.crossingAlong(S, c0[0] + 450.0 * 0.5 + 900.0, z0, -1.0, 100.0))
	quit()
