import sys
R = sys.argv[1]
def sub(path, a, b):
    s = open(R + "/" + path, encoding="utf-8", newline="").read()
    assert s.count(a) == 1, (path, a[:60])
    open(R + "/" + path, "w", encoding="utf-8", newline="").write(s.replace(a, b))
sw = "sim/core/swing.gd"
sub(sw, "static var incr: bool = false", "static var incr: bool = false\nstatic var planetMode: bool = false\nstatic var rl := PackedInt32Array()\nstatic var rlKey: int = -1\nstatic var rlBuilt: int = 0")
sub(sw, "WorldStructures.near(S, px, POSE_REACH)", "_reachList(S, px)")
s = open(R + "/" + sw, encoding="utf-8", newline="").read()
s += """

## Which buildings a swing tick poses. The strip test (WorldStructures.near) asks the stored x, which is stale for a building outside the reach, so a building swinging in is never fetched. The planet test cannot go stale: a turn about the pivot keeps every building's
## great-circle distance from it, so the set within POSE_REACH of the pivot is the same all swing long (laid again when the pivot has moved a bucket, 500 units, or a swing is asked).
static func _reachList(S: SimState, px: float):
	if not planetMode:
		return WorldStructures.near(S, px, POSE_REACH)
	var key: int = S.swing.n * 100000 + int(floor(SimWrap.wrap(px) / 500.0))
	if key != rlKey:
		rlKey = key
		rlBuilt += 1
		SimField.pointAt(S, px)
		var c: float = SimDetMath.cos(POSE_REACH / SimField.R)
		var qx: float = SimField.ox
		var qy: float = SimField.oy
		var qz: float = SimField.oz
		rl = PackedInt32Array()
		for i in range(S.bX.size()):
			if S.bQ[i * 3] * qx + S.bQ[i * 3 + 1] * qy + S.bQ[i * 3 + 2] * qz >= c:
				rl.append(i)
	return rl
"""
open(R + "/" + sw, "w", encoding="utf-8", newline="").write(s)
print("ok")
