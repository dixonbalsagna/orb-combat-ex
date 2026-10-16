extends SceneTree
const Lib = preload("res://sim/world/tools/planet_lib.gd")
func _init() -> void:
	var P = Lib.new()
	var rr := SimRng.new(99)
	var worst: float = 0.0
	for trial in range(200):
		var nA: Vector3 = P.randunit(rr)
		var nB: Vector3 = P.randunit(rr)
		var uA: Vector3 = nA.cross(P.randunit(rr)).normalized()
		var vA: Vector3 = nA.cross(uA).normalized()
		var uB: Vector3 = nB.cross(P.randunit(rr)).normalized()
		var vB: Vector3 = nB.cross(uB).normalized()
		var X: Vector3 = nA.cross(nB).normalized()
		var qa: Vector3 = P.rot(uA, vA, atan2(X.dot(vA), X.dot(uA)))
		var qb: Vector3 = P.rot(uB, vB, atan2(X.dot(vB), X.dot(uB)))
		worst = maxf(worst, absf(P.elev(qa) - P.elev(qb)))
	print("same point from two circles: largest elevation difference %.9f units over 200 crossings" % worst)
	quit()
