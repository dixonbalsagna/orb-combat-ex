# PARKED BUILD (Simulation): a fighter's depth outside a flight, part (a) of docs/architecture/pending/depth-core.md.
# With depth off (the committed switch) every match, replay and checkpoint is the same to the bit: every new line that
# computes anything sits under `if S.depthOn`, and the new state is hashed only when depth is on.
#   new   sim/core/depth.gd (SimDepth), data/combat/depth.json
#   edits sim/core/fighter.gd, state.gd, hash.gd, sim.gd, replay.gd, view/camera.gd
# The parity checks are depth_a_checks.py. Needs an import after applying (a new class name).
# Usage: python depth_a.py <repo root>      (run from anywhere; it reads src/ beside itself)
import os, shutil, sys
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(sys.argv[1])
def edit(p, pairs):
    s=open(p,encoding='utf-8').read()
    for a,b in pairs:
        assert s.count(a)==1,(p,a[:80],s.count(a))
        s=s.replace(a,b)
    open(p,'w',encoding='utf-8',newline='\n').write(s)
def between(p, start, end, new):
    s=open(p,encoding='utf-8').read()
    assert s.count(start)==1 and s.count(end)==1,(p,start[:60],s.count(start),s.count(end))
    i=s.index(start); j=s.index(end)
    assert i<j
    open(p,'w',encoding='utf-8',newline='\n').write(s[:i]+new+s[j:])

os.makedirs('data/combat', exist_ok=True)
shutil.copyfile(os.path.join(HERE,'src','depth.json'), 'data/combat/depth.json')
shutil.copyfile(os.path.join(HERE,'src','depth.gd'), 'sim/core/depth.gd')

# ---------------------------------------------------------------- state
edit('sim/core/state.gd', [
('''	var zT: float = 0.0              # L0: the home depth a free fighter eases to (where a flight left him, or the director's choice)
''','''	var zT: float = 0.0              # L0: the home depth a free fighter eases to (where a flight left him, or the director's choice)
	var vz: float = 0.0              # D1: his velocity in depth that the cap holds (the director's drift: a push, the carry, the ease home), units a second. Hashed only with depth on
	var vzX: float = 0.0             # D1: his velocity in depth that the cap does not hold (depth.json capExempt: a shove, a sidestep; a drop). Hashed only with depth on
'''),
('''	var pz: float = 0.0      # L0: a point rush's depth (a fighter rush homes to its target's z)
''','''	var pz: float = 0.0      # L0: a point rush's depth (a fighter rush homes to its target's z)
	var offZ: float = 0.0    # D1: a fighter rush ends this far in depth from its target, as off is along the street, so he arrives a little to one side. Hashed only with depth on
'''),
('''	var craterT: PackedFloat64Array = PackedFloat64Array()   # Encounter's slice (a) (granted line): the director owns it
''','''	var craterT: PackedFloat64Array = PackedFloat64Array()   # Encounter's slice (a) (granted line): the director owns it
	# D1, fighters in depth: the director's own, read and written only by it, hashed only with depth on (SimHash.collect)
	var lineSin: float = 0.0   # the sine of the angle of the brawl's line to the street
	var lineSide: int = 0      # which way the line is turned (+1 or -1; 0 none)
	var carryZ: float = 0.0    # the carry's depth part, units a second
	var homeWait: int = 0      # ticks with no stick held, before the ease home
	var sideT: int = 0         # ticks left of a sidestep
	var sideWay: int = 0       # the sidestep's way (+1 toward the camera, -1 away; 0 none)
'''),
])

# ---------------------------------------------------------------- hash: the new state, only when depth is on
edit('sim/core/hash.gd', [
('''				for i in nzr:
					out.append(float(i)); out.append(row[i])
''','''				for i in nzr:
					out.append(float(i)); out.append(row[i])
		# D1: the depth step's own state, only when depth is on: each fighter's two velocities in depth and his rush's
		# offset, then the director's line, carry, wait and sidestep
		for f in fs:
			out.append(f.vz); out.append(f.vzX); out.append(f.rush.offZ if f.rush != null else 0.0)
		_obj(out, d, ["lineSin", "lineSide", "carryZ", "homeWait", "sideT", "sideWay"])
'''),
])

# ---------------------------------------------------------------- the match setup: the switch from the data
edit('sim/core/sim.gd', [
('''	S.dirS.craterT = PackedFloat64Array()   # Encounter's slice (a) (granted line)
''','''	S.dirS.craterT = PackedFloat64Array()   # Encounter's slice (a) (granted line)
	S.dirS.lineSin = 0.0   # D1: the director's line, carry, wait and sidestep belong to a match
	S.dirS.lineSide = 0
	S.dirS.carryZ = 0.0
	S.dirS.homeWait = 0
	S.dirS.sideT = 0
	S.dirS.sideWay = 0
'''),
('''	S.depthOn = setup.get("depth", false) == true   # fight lanes: off until the director's switch-on (L4); a setup may force it for probes''',
 '''	S.depthOn = setup.get("depth", SimDepth.enabled()) == true   # fighters in depth: the data's switch (data/combat/depth.json), or the setup's own for this match'''),
])
edit('sim/core/replay.gd', [
('''	h.text(WorldStructures.stagesHash())   # World's building stages: data/biomes/stages.json
''','''	h.text(WorldStructures.stagesHash())   # World's building stages: data/biomes/stages.json
	if SimDepth.enabled():   # fighters in depth: data/combat/depth.json, once its switch is on (a match with depth off reads none of it)
		h.text(SimDepth.dataHash())
'''),
])

# ---------------------------------------------------------------- the camera's start (Camera's file; the EP's ruling)
edit('sim/core/view/camera.gd', [
('''func reset() -> void:
	x = SimConst.START_X + 350.0
''','''## S, when given, is the match just set up: the camera starts on the pair's middle less 100. For the default start that
## is START_X + 350 to the bit; for a start elsewhere (the crossing) it is where the fighters are.
func reset(S: SimState = null) -> void:
	x = SimConst.START_X + 350.0
	if S != null and S.fighters.size() >= 2:
		x = SimWrap.wrap(S.fighters[0].x + SimWrap.sdx(S.fighters[0].x, S.fighters[1].x) * 0.5 - 100.0)
'''),
])

# ---------------------------------------------------------------- the fighter
F='sim/core/fighter.gd'
edit(F, [
# tierUp: the ground at his depth
('''	var g: float = WorldTerrain.groundY(S, f.x)
	SimFx.ring(S, f.x, f.y + 34.0, 1300.0, f.aura, 0.8, 20.0, f.z)''','''	var g: float = WorldTerrain.groundY(S, f.x, f.z)   # at his depth (the plane's when depth is off)
	SimFx.ring(S, f.x, f.y + 34.0, 1300.0, f.aura, 0.8, 20.0, f.z)'''),
# a drop may carry a depth part
('''static func drop(S: SimState, f, ticks: int, vx: float = 0.0, vy: float = 0.0) -> bool:''','''static func drop(S: SimState, f, ticks: int, vx: float = 0.0, vy: float = 0.0, vz: float = 0.0) -> bool:'''),
('''	f.vx = vx
	f.vy = vy
	SimFx.dropStart(S, f, ticks)
''','''	f.vx = vx
	f.vy = vy
	if S.depthOn:   # a drop's depth part is one motion: the cap does not hold it
		f.vz = 0.0
		f.vzX = vz
	SimFx.dropStart(S, f, ticks)
'''),
('''	f.dropT = 0
	f.vx = 0.0
	f.vy = 0.0
	SimFx.dropEnd(S, f, how)
''','''	f.dropT = 0
	f.vx = 0.0
	f.vy = 0.0
	f.vz = 0.0
	f.vzX = 0.0
	SimFx.dropEnd(S, f, how)
'''),
# a bowed rush is held by the ground at his depth
('''		y = SimMathx.jclamp(y, WorldTerrain.groundY(S, x), SimConst.CEILING)
	return PackedFloat64Array([SimWrap.wrap(x), y])''','''		y = SimMathx.jclamp(y, WorldTerrain.groundY(S, x, f.z), SimConst.CEILING)
	return PackedFloat64Array([SimWrap.wrap(x), y])'''),
# the rush: its end may sit to one side in depth; the band is World's
('''	var tz: float = r.tgt.z if r.tgt != null else r.pz   # L2: the rush's depth (used only when S.depthOn)
	if rem <= dt:
		f.x = SimWrap.wrap(tx)
		f.y = SimMathx.jmax(ty, WorldTerrain.groundY(S, tx))
		if S.depthOn:
			f.z = clampf(tz, SimConst.Z_BACK, SimConst.Z_FRONT)
			f.zT = f.z   # he stays where the rush took him
''','''	var tz: float = (r.tgt.z + r.offZ) if r.tgt != null else r.pz   # L2: the rush's depth (used only when S.depthOn); offZ puts him a little to one side of his target
	if rem <= dt:
		f.x = SimWrap.wrap(tx)
		f.y = SimMathx.jmax(ty, WorldTerrain.groundY(S, tx))
		if S.depthOn:
			f.z = clampf(tz, SimDepth.zBack, SimDepth.zFront)
			f.zT = f.z   # he stays where the rush took him
			f.vz = 0.0
			f.vzX = 0.0
			f.y = SimMathx.jmax(ty, WorldTerrain.groundY(S, tx, f.z))   # on the ground at his depth
'''),
('''	if S.depthOn:
		f.z = clampf(f.z + (tz - f.z) * k, SimConst.Z_BACK, SimConst.Z_FRONT)
''','''	if S.depthOn:
		f.z = clampf(f.z + (tz - f.z) * k, SimDepth.zBack, SimDepth.zFront)
'''),
# the step: where the tick found him
('''static func stepFighter(S: SimState, f, dt: float) -> void:
	var o = SimRoster.opp(S, f)
''','''static func stepFighter(S: SimState, f, dt: float) -> void:
	var o = SimRoster.opp(S, f)
	var x0: float = f.x   # where the tick found him: with depth on, the contact rule sweeps his step from here
	var y0: float = f.y
	var z0: float = f.z
	var rushed: bool = f.rush != null
'''),
# free
('''			f.vy += (i.my * sp * 0.85 - f.vy) * k
			f.x = SimWrap.wrap(f.x + f.vx * dt)
			f.y += f.vy * dt
			var g: float = WorldTerrain.groundY(S, f.x)
''','''			f.vy += (i.my * sp * 0.85 - f.vy) * k
			if S.depthOn:   # no stick steers depth: a velocity in depth dies away as his own does with the stick at rest
				f.vz += (0.0 - f.vz) * k
				f.vzX += (0.0 - f.vzX) * k
			f.x = SimWrap.wrap(f.x + f.vx * dt)
			f.y += f.vy * dt
			var g: float = WorldTerrain.groundY(S, f.x, f.z)   # at his depth (the plane's when depth is off)
'''),
# charging
('''			f.vx *= 0.85
			f.vy *= 0.85
''','''			f.vx *= 0.85
			f.vy *= 0.85
			if S.depthOn:
				f.vz *= 0.85
				f.vzX *= 0.85
'''),
('''			SimFx.chargeFx(S, f, WorldTerrain.groundY(S, f.x))   # the aura's sparks and dust are cosmetic: the consumer rolls them''',
 '''			SimFx.chargeFx(S, f, WorldTerrain.groundY(S, f.x, f.z))   # the aura's sparks and dust are cosmetic: the consumer rolls them'''),
# down
('''		f.y = WorldTerrain.groundY(S, f.x)
		if f.stateT > 0.75:
''','''		if S.depthOn:   # the surface under him at his depth: the ground there, or the roof he lies on
			f.y = WorldStructures.standingAt(S, f.x, f.y, f.z).y
		else:
			f.y = WorldTerrain.groundY(S, f.x)
		if f.stateT > 0.75:
'''),
# dropped
('''		var gd0: float = WorldTerrain.groundY(S, f.x)
		var above: bool = f.y > gd0
		f.stateT += dt
		f.vy -= DROP_GRAV * dt
		f.vx *= SimDetMath.pow(0.55, dt)
		f.x = SimWrap.wrap(f.x + f.vx * dt)
		f.y = SimMathx.jmin(f.y + f.vy * dt, SimConst.CEILING)
		var gd: float = WorldTerrain.groundY(S, f.x)
		if f.y <= gd:
			f.y = gd
			f.vx = 0.0
			f.vy = 0.0
''','''		var gd0: float = WorldTerrain.groundY(S, f.x, f.z)
		var above: bool = f.y > gd0
		f.stateT += dt
		f.vy -= DROP_GRAV * dt
		f.vx *= SimDetMath.pow(0.55, dt)
		if S.depthOn:
			var dk: float = SimDetMath.pow(0.55, dt)
			f.vz *= dk
			f.vzX *= dk
		f.x = SimWrap.wrap(f.x + f.vx * dt)
		f.y = SimMathx.jmin(f.y + f.vy * dt, SimConst.CEILING)
		var gd: float = WorldTerrain.groundY(S, f.x, f.z)
		if f.y <= gd:
			f.y = gd
			f.vx = 0.0
			f.vy = 0.0
			f.vz = 0.0
			f.vzX = 0.0
'''),
# locked, and the end of the step
('''		var keep: float = lockedKeep(dt)
		f.vx *= keep
		f.vy *= keep
		f.x = SimWrap.wrap(f.x + f.vx * dt)
		f.y = SimMathx.jmax(WorldTerrain.groundY(S, f.x), f.y + f.vy * dt)
	if S.depthOn:
		stepDepth(S, f, dt)   # L2: off until the director's switch-on
''','''		var keep: float = lockedKeep(dt)
		f.vx *= keep
		f.vy *= keep
		if S.depthOn:   # the director's velocity in depth, damped as the other two are: a push along the line keeps its angle
			f.vz *= keep
			f.vzX *= keep
		f.x = SimWrap.wrap(f.x + f.vx * dt)
		f.y = SimMathx.jmax(WorldTerrain.groundY(S, f.x, f.z), f.y + f.vy * dt)
	if S.depthOn:
		stepDepth(S, f, dt)   # his depth: the director's velocity, his home, the band
		if not rushed and f.state != "launched" and f.state != "down":
			contact(S, f, x0, y0, z0)   # and the buildings: he stops at a face, and the rest of his step slides
			var gz: float = WorldTerrain.groundY(S, f.x, f.z)   # the ground at the depth he has come to
			if f.y < gz:
				f.y = gz
'''),
])

between(F, '''## Fight lanes (L2; docs/architecture/fight-lanes.md), only when S.depthOn: a fighter's depth outside a rush. The player''',
'''## Body rotation, in one place''',
'''## A fighter's depth, only when S.depthOn (docs/architecture/depth-core.md). No stick steers it.
##   a flight      World's waypoint moves z (WorldBrunt.stepZ), and he stays where it leaves him
##   a rush        homes in depth (stepRush), and he stays where it takes him
##   otherwise     the director's velocity moves him: vz, held to the cap (depth.json maxBhPerSec), and vzX, which the cap
##                 does not hold. The branches of stepFighter damp both as they damp vx.
##   a free fighter also eases to his home depth zT, at the cap at most. The director moves the home; a velocity carries
##                 it along, so a shove leaves him where it sent him. A locked fighter has no home of his own.
## The band (World's lane table: SimDepth.zBack to zFront) holds him and his home. The buildings are contact()'s.
static func stepDepth(S: SimState, f, dt: float) -> void:
	if f.state == "launched":
		f.z = clampf(f.z, SimDepth.zBack, SimDepth.zFront)
		f.zT = f.z
		f.vz = 0.0
		f.vzX = 0.0
		return
	if f.rush != null:
		f.zT = f.z
		return
	if f.state == "down":
		f.vz = 0.0
		f.vzX = 0.0
	var step: float = (clampf(f.vz, -SimDepth.cap, SimDepth.cap) + f.vzX) * dt
	f.z += step
	if f.state == "locked":
		f.zT = f.z
	else:
		f.zT = clampf(f.zT + step, SimDepth.zBack, SimDepth.zFront)
		var d: float = f.zT - f.z
		if d != 0.0:
			var m: float = SimDepth.cap * dt
			f.z += clampf(d, -m, m)
	if f.z > SimDepth.zFront:
		f.z = SimDepth.zFront
		f.vz = minf(f.vz, 0.0)
		f.vzX = minf(f.vzX, 0.0)
	elif f.z < SimDepth.zBack:
		f.z = SimDepth.zBack
		f.vz = maxf(f.vz, 0.0)
		f.vzX = maxf(f.vzX, 0.0)
	if f.state == "locked":
		f.zT = f.z


## The contact rule for a fighter outside a flight, only when S.depthOn (Game Design, docs/design/depth.md section 2: a
## face stops the part of the motion that runs into it, and the rest slides on). His step this tick, from (x0, y0, z0)
## to where he now is, is swept against the standing buildings along it (World's sweep). At a face he is put there, the
## part of his velocity into it ends, and the rest of the step is swept again: three times at most, once an axis, so a
## corner stops him. In a street the depth part stops at a block's face and the part along the street goes on; at a
## crossing nothing is met; in an avenue the part along the street stops at a block's end and he slides down the avenue;
## on a roof he stands. A wreck is not a standing building. A body that starts inside one is put out by its nearest face.
## His centre keeps SimDepth.rx and rz (the body's half extents, and the data's margin at least) from a face. In a street
## lane, where World builds nothing, no sweep is made.
static func contact(S: SimState, f, x0: float, y0: float, z0: float) -> void:
	if SimDepth.clearStreet(z0, f.z):
		return
	var rx: float = SimDepth.rx
	var ry: float = SimDepth.ry
	var rz: float = SimDepth.rz
	var list: Array = WorldStructures.along(S, x0, f.x, rx)
	if list.is_empty():
		return
	var px: float = x0
	var py: float = y0
	var pz: float = z0
	var tx: float = f.x
	var ty: float = f.y
	var tz: float = f.z
	var clear: bool = false
	var hitZ: bool = false
	for pass_ in range(3):
		# the sweep takes the body's centre: his feet are f.y, half his height under it
		var h: Dictionary = WorldStructures.sweep(S, list, px, py + ry, pz, tx, ty + ry, tz, rx, ry, rz)
		if not h.hit:
			clear = true
			break
		var b = S.buildings[h.b]
		px = h.x
		py = h.y - ry
		pz = h.z
		if h.face == "end":
			px = SimWrap.wrap(b.x + h.nx * (b.w * 0.5 + rx + SimDepth.SKIN))
			tx = px
			if f.vx * h.nx < 0.0:
				f.vx = 0.0
		elif h.face == "front" or h.face == "back":
			pz = b.z + h.nz * (b.d * 0.5 + rz + SimDepth.SKIN)
			tz = pz
			hitZ = true
			if f.vz * h.nz < 0.0:
				f.vz = 0.0
			if f.vzX * h.nz < 0.0:
				f.vzX = 0.0
		elif h.face == "top":
			py = WorldStructures.baseY(S, b) + WorldStructures.curH(b) + SimDepth.SKIN
			ty = py
			if f.vy < 0.0:
				f.vy = 0.0
		else:   # the underside: a building stands on the ground, so nothing comes up into it; he stays where they met
			tx = px
			ty = py
			tz = pz
	if not clear:
		tx = px
		ty = py
		tz = pz
	f.x = tx
	f.y = ty
	f.z = tz
	if hitZ or f.state == "locked":
		f.zT = f.z   # a face stopped him in depth: his home is where he is until the director moves it


## The director's own step for a fighter this tick: a blow's closing step, a placement. He is moved from where he is to
## (x, y, z) through the contact rule, with no cap: it is an attack closing, as a rush is. He stays where it puts him.
## Returns true when no face stopped him short. With depth off it is the plain assignment the director made before
## (x wrapped, y as given), and z is left alone.
static func stepTo(S: SimState, f, x: float, y: float, z: float) -> bool:
	if not S.depthOn:
		f.x = SimWrap.wrap(x)
		f.y = y
		return true
	var x0: float = f.x
	var y0: float = f.y
	var z0: float = f.z
	var wx: float = SimWrap.wrap(x)
	var wz: float = clampf(z, SimDepth.zBack, SimDepth.zFront)
	f.x = wx
	f.z = wz
	f.y = SimMathx.jmax(y, WorldTerrain.groundY(S, wx, wz))
	contact(S, f, x0, y0, z0)
	f.zT = f.z
	return f.x == wx and f.z == wz


## One cause's velocity in depth for f, units a second, added to the velocity the cap holds (vz) or, when the data lists
## the cause under capExempt, to the one it does not (vzX). The causes are SimDepth.CAUSES. The director may also write
## the two fields itself, where it writes vx and vy.
static func addDepth(f, cause: String, v: float) -> void:
	if not SimDepth.CAUSES.has(cause):
		push_error("SimFighter.addDepth: unknown cause " + cause)
	if SimDepth.isExempt(cause):
		f.vzX += v
	else:
		f.vz += v


''')
print("part (a): a fighter's depth outside a flight is in")
