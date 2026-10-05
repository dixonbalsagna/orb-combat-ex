class_name SimCamera
extends RefCounted
## View-layer camera follow: the one-view reference camera. The host calls camStep after each tick with S.dt; it reads
## S and never writes it. It began as the twin of view/camera.js; the JS core is frozen (ADR 0006) and does not follow it.
## Owner: Camera (docs/camera/split-screen.md section 22). It stays under the sim's gate: the goldens record the camera
## at every checkpoint, so a change here runs npm test --prefix sim.

## The widest the camera pulls out (pixels per unit): fighters launched across the world stay in the shot as dots.
const ZOOM_MIN: float = 0.006

var x: float = SimConst.START_X + 350.0
var y: float = 100.0
var z: float = 0.45


func reset() -> void:
	x = SimConst.START_X + 350.0
	y = 100.0
	z = 0.45


func camStep(S: SimState, dt: float, vw: float, vh: float) -> void:
	# A fighter held up in the sky before his fall is not on stage (the midpoint chased him 6,000 units up while the one
	# who had landed was off the bottom of the screen). While one falls the camera falls with him; with one held and
	# nobody falling it frames the other; any other state is the framing below.
	var held: Array = [false, false]
	var falling: int = -1
	for i in range(2):
		var f = S.fighters[i]
		if f.state == "intro" or f.state == "waiting":
			var g: float = WorldTerrain.groundY(S, f.x)
			if f.y >= g + SimIntro.fallHeight - 1.0:
				held[i] = true
			elif f.y > g + 4.0:
				falling = i
	if falling >= 0 or held[0] != held[1]:
		var k0: float = 1.0 - SimDetMath.pow(0.02, dt)
		var zs: float = SimMathx.jmin(SimMathx.jmin(vw / 700.0, (vh * 0.8) / 500.0), 1.15)
		z += (zs - z) * k0
		if falling >= 0:
			var fl = S.fighters[falling]
			x = fl.x
			y = SimMathx.jclamp(fl.y + 40.0, -180.0, SimConst.CEILING - 200.0)
		else:
			var on = S.fighters[1] if held[0] else S.fighters[0]
			x = SimWrap.wrap(x + SimWrap.sdx(x, on.x) * k0)
			y += (SimMathx.jclamp(on.y + 40.0, -180.0, SimConst.CEILING - 200.0) - y) * k0
		return
	var a = S.fighters[0]
	var b = S.fighters[1]
	var d: float = SimWrap.sdx(a.x, b.x)
	var mx: float = a.x + d / 2.0
	var my: float = (a.y + b.y) / 2.0
	var spanX: float = absf(d) + 700.0
	var spanY: float = absf(a.y - b.y) + 500.0
	var zz: float = SimMathx.jmin(SimMathx.jmin(vw / spanX, (vh * 0.8) / spanY), 1.15)
	zz *= 1.0 - 0.06 * (SimMathx.jmax(a.tier, b.tier) - 1.0)
	zz = SimMathx.jclamp(zz, ZOOM_MIN, 1.15)
	var k: float = 1.0 - SimDetMath.pow(0.02, dt)
	z += (zz - z) * k
	x = SimWrap.wrap(x + SimWrap.sdx(x, mx) * k)
	y += (SimMathx.jclamp(my + 40.0, -180.0, SimConst.CEILING - 200.0) - y) * k
