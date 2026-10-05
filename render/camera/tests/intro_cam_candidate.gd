class_name IntroCamCandidate
extends SimCamera
## The candidate fix for the sim's reference camera (sim/core/view/camera.gd is Simulation's file: this is a copy with the
## change, for the intro test; the exact lines for Simulation are in docs/camera/split-screen.md section 22).
##
## The fault: during a composed intro the reference camera frames the midpoint of both fighters, and the one who has not
## started to fall is held 6,000 units up (state "intro", y at the top of the fall). The camera chased him: from tick 24 to
## 295 of the Latecomer it sat 4,600 units up at zoom 0.09 and the fighter who had landed was off the bottom of the screen.
##
## The change: a fighter held up before his fall is not on stage. While one falls, the camera falls with him (his x and y
## exactly, so he stays in the frame; the zoom eases to the one-fighter size). With one fighter held and nobody falling,
## the camera frames the other. In any other state (both landed, both held for the one tick before the first fall, no
## intro) the framing is the reference camera's, unchanged.

const HELD_SLACK: float = 1.0      # units: a fighter within this of the top of the fall is still held up
const LANDED_SLACK: float = 4.0    # units: a fighter within this of the ground has landed


func camStep(S: SimState, dt: float, vw: float, vh: float) -> void:
	var held: Array = [false, false]
	var falling: int = -1
	for i in range(2):
		var f = S.fighters[i]
		if f.state == "intro" or f.state == "waiting":
			var g: float = WorldTerrain.groundY(S, f.x)
			if f.y >= g + SimIntro.fallHeight - HELD_SLACK:
				held[i] = true
			elif f.y > g + LANDED_SLACK:
				falling = i
	if falling >= 0 or held[0] != held[1]:
		var k: float = 1.0 - SimDetMath.pow(0.02, dt)
		var zs: float = SimMathx.jmin(SimMathx.jmin(vw / 700.0, (vh * 0.8) / 500.0), 1.15)
		z += (zs - z) * k
		if falling >= 0:
			var fl = S.fighters[falling]
			x = fl.x
			y = SimMathx.jclamp(fl.y + 40.0, -180.0, SimConst.CEILING - 200.0)
		else:
			var on = S.fighters[1] if held[0] else S.fighters[0]
			x = SimWrap.wrap(x + SimWrap.sdx(x, on.x) * k)
			y += (SimMathx.jclamp(on.y + 40.0, -180.0, SimConst.CEILING - 200.0) - y) * k
		return
	super.camStep(S, dt, vw, vh)
