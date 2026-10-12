# The parity checks for part (a): the old depth check brought to the new rules, and a new one for the depth step and
# the contact rule. Usage: python depth_a_checks.py <repo root>
import os, sys
os.chdir(sys.argv[1])
def edit(p, pairs):
    s=open(p,encoding='utf-8').read()
    for a,b in pairs:
        assert s.count(a)==1,(p,a[:80],s.count(a))
        s=s.replace(a,b)
    open(p,'w',encoding='utf-8',newline='\n').write(s)

edit('sim/core/tools/parity.gd', [
('''	check("depth in the core", _depth())
''','''	check("depth in the core", _depth())
	check("a fighter's depth outside a flight, and the contact rule", _depthStep())
'''),
# ---- the old check, on the new rules
('''## default match keeps every home depth at 0. With it on (a forced setup): a free fighter eases to his home depth; a rush
## homes in depth and leaves him there; a fighter in an exchange takes its depth; a flight's end is the new home; and
## nothing leaves the band.''','''## default match keeps every home depth at 0. With it on (a forced setup): a free fighter eases to his home depth, at the
## cap at most; a rush homes in depth and leaves him there; an exchange's depth is the director's and moves nobody's home;
## a flight's end is the new home; and nothing leaves the band, which is World's lane table.'''),
('''	# the free ease, and the band
	a.z = 300.0
	a.zT = -600.0
	var last: float = a.z
	for t in range(240):
		SimFighter.stepDepth(S, a, dt)
		if a.z > last:
			return "the free ease moved away from the home depth"
		last = a.z
	if a.z != -600.0:
		return "a free fighter did not reach his home depth (%s)" % str(a.z)
	a.zT = -99999.0
	for t in range(600):
		SimFighter.stepDepth(S, a, dt)
	if a.z != SimConst.Z_BACK or a.zT != SimConst.Z_BACK:
		return "the band did not hold the back edge (z %s, home %s)" % [str(a.z), str(a.zT)]
	a.z = 99999.0
	SimFighter.stepDepth(S, a, dt)
	if a.z > SimConst.Z_FRONT:
		return "the band did not hold the front edge"
''','''	# the free ease, at the cap at most, and the band
	var lim: Array = WorldLanes.limits()
	if SimDepth.zFront != float(lim[0]) or SimDepth.zBack != float(lim[1]) or SimDepth.zFront <= SimDepth.zBack:
		return "the band is not World's lane table (%s to %s)" % [str(SimDepth.zFront), str(SimDepth.zBack)]
	a.z = 150.0
	a.zT = -600.0
	var last: float = a.z
	for t in range(520):
		SimFighter.stepDepth(S, a, dt)
		if a.z > last or last - a.z > SimDepth.cap * dt + 0.000000001:
			return "the free ease moved %s in a tick (the cap gives %s)" % [str(last - a.z), str(SimDepth.cap * dt)]
		last = a.z
	if a.z != -600.0:
		return "a free fighter did not reach his home depth (%s)" % str(a.z)
	a.zT = -99999.0
	for t in range(1200):
		SimFighter.stepDepth(S, a, dt)
	if a.z != SimDepth.zBack or a.zT != SimDepth.zBack:
		return "the band did not hold the back edge (z %s, home %s)" % [str(a.z), str(a.zT)]
	a.z = 99999.0
	SimFighter.stepDepth(S, a, dt)
	if a.z > SimDepth.zFront:
		return "the band did not hold the front edge"
'''),
('''	# an exchange's depth is the home of both fighters
	var ex := SimState.Exchange.new()
	ex.A = a
	ex.D = b
	ex.z = -450.0
	S.dirS.ex = ex
	SimFighter.stepDepth(S, a, dt)
	SimFighter.stepDepth(S, b, dt)
	if a.zT != -450.0 or b.zT != -450.0:
		return "an exchange's depth did not become the fighters' home (%s, %s)" % [str(a.zT), str(b.zT)]
	S.dirS.ex = null
''','''	# a fighter rush may end a little to one side of its target
	var r3 := SimState.Rush.new()
	r3.tgt = b
	r3.off = -60.0
	r3.offZ = 24.0
	r3.end = S.T + 0.3
	a.rush = r3
	steps = 0
	while a.rush != null and steps < 200:
		SimFighter.stepRush(S, a, dt)
		SimFighter.stepDepth(S, a, dt)
		S.T += dt
		steps += 1
	if a.z != b.z + 24.0 or a.zT != a.z:
		return "a rush with a depth offset ended at %s (its target is at %s)" % [str(a.z), str(b.z)]
	# an exchange's depth is the director's: it moves nobody's home
	var ex := SimState.Exchange.new()
	ex.A = a
	ex.D = b
	ex.z = -450.0
	S.dirS.ex = ex
	var za: float = a.z
	var zb: float = b.z
	SimFighter.stepDepth(S, a, dt)
	SimFighter.stepDepth(S, b, dt)
	if a.zT != za or b.zT != zb or a.z != za or b.z != zb:
		return "an exchange's depth moved a fighter or his home (%s, %s)" % [str(a.zT), str(b.zT)]
	S.dirS.ex = null
'''),
# ---- the new check
('''## The second breath (spec-wounds.md section 1c): a battered region fades once the fighter has had quiet for the wait''','''## A fighter's depth outside a flight (docs/architecture/depth-core.md, part a). The data loads and its switch is off;
## the camera's start. With depth on, in the city at a crossing: a locked fighter's velocity in depth is damped and moves
## him as his vx does, so a push along the line keeps its angle; the cap holds vz and not vzX, and the data says which
## cause goes where; in a street the depth part stops at a block's face and the part along the street goes on; at a
## crossing he passes the kerb line; in an avenue the part along the street stops at a block's end and the depth part
## goes on; a roof holds him; a body inside a standing building is put out; a seeded walk never leaves him inside one or
## outside the band; the director's own step goes through the same rule; the new state is in the hash only with depth on;
## and a match with depth on replays to the same hash.
func _depthStep() -> String:
	if not SimDepth.errors().is_empty():
		return "data/combat/depth.json: " + str(SimDepth.errors()[0])
	if SimDepth.enabled():
		return "the depth switch is on in the data: this check, and every golden, is for a tree with it off"
	if absf(SimDepth.cap - 1.2 * 75.0) > 0.000001 or SimDepth.margin <= 0.0 or SimDepth.rx < SimDepth.margin or SimDepth.rz < SimDepth.margin or SimDepth.lanes.is_empty():
		return "the depth numbers read: cap %s, margin %s, half extents %s and %s, %d streets" % [str(SimDepth.cap), str(SimDepth.margin), str(SimDepth.rx), str(SimDepth.rz), SimDepth.lanes.size()]
	var dt: float = SimConst.DT
	var keep: float = SimFighter.lockedKeep(dt)
	# the camera's start: the default start is today's number to the bit, flipped or not; a start elsewhere is where the pair is
	for flip in [false, true]:
		var C := SimCore.createSim()
		SimCore.newMatch(C, 5, {}, {"flip": true} if flip else {})
		var cam := SimCamera.new()
		cam.x = 0.0
		cam.reset(C)
		if cam.x != SimConst.START_X + 350.0 or C.depthOn:
			return "the camera's start for the default match reads %s, or depth is on" % str(cam.x)
		SimCore.dispose(C)
	var S := SimCore.createSim()
	SimCore.newMatch(S, 3, {"p1": false, "p2": false}, {"intro": false, "depth": true, "start": "crossing"})
	if not S.depthOn:
		return "the setup's depth did not reach the sim"
	var f = S.fighters[0]
	var o = S.fighters[1]
	var mid: float = SimWrap.wrap(f.x + SimWrap.sdx(f.x, o.x) * 0.5)
	var cam2 := SimCamera.new()
	cam2.reset(S)
	if absf(SimWrap.sdx(cam2.x, mid) - 100.0) > 0.000001 or absf(SimWrap.sdx(SimConst.START_X, mid)) < 5000.0:
		return "the camera's start at a crossing reads %s for a pair at %s" % [str(cam2.x), str(mid)]
	var isect: Array = WorldLanes.intersections(S, mid, 600.0)
	if isect.is_empty():
		return "the crossing start is not at a crossing"
	var cx: float = float(isect[0][0])
	var rx: float = SimDepth.rx
	var ry: float = SimDepth.ry
	var rz: float = SimDepth.rz
	var body: Array = WorldLanes.body()
	var lane0: Array = SimDepth.lanes[0]
	# World builds nothing in a street lane: the contact rule makes no sweep there
	for b in S.buildings:
		if not b.alive:
			continue
		for l in SimDepth.lanes:
			if b.z + b.d * 0.5 > float(l[1]) + 0.01 and b.z - b.d * 0.5 < float(l[0]) - 0.01:
				return "a building at x %s stands in a street lane (depth %s, %s deep)" % [str(b.x), str(b.z), str(b.d)]
	# the two buildings the cases stand by: one fronting the front street, wide enough to walk along; one at the avenue's end
	var front = null
	var endB = null
	var bestF: float = 1.0e30
	var bestE: float = 1.0e30
	for b in S.buildings:
		var face: float = b.z + b.d * 0.5
		if not b.alive or face > float(lane0[1]) + 0.5 or face < float(lane0[1]) - 150.0:
			continue
		var dx: float = SimWrap.sdx(cx, b.x)
		if b.w >= 4.0 * rx + 120.0 and absf(dx) < bestF and WorldStructures.curH(b) > 3.0 * ry:
			bestF = absf(dx)
			front = b
		var gap: float = dx - b.w * 0.5
		if dx > 0.0 and gap > rx and gap < bestE and b.d > 4.0 * rz and WorldStructures.curH(b) > 3.0 * ry:
			bestE = gap
			endB = b
	if front == null or endB == null:
		return "no building fronts the front street by the crossing (the cases need one, and one at the avenue's end)"
	var place := func(x: float, y: float, z: float) -> void:
		f.state = "locked"
		f.rush = null
		f.x = SimWrap.wrap(x)
		f.y = y
		f.z = z
		f.zT = z
		f.vx = 0.0
		f.vy = 0.0
		f.vz = 0.0
		f.vzX = 0.0
		f.stunTicks = 0
	var inside := func() -> bool:
		return WorldStructures.blocked(S, f.x, f.y + ry, f.z, float(body[0]), float(body[1]), float(body[2])) >= 0
	var gz: float = WorldTerrain.groundY(S, cx, 0.0)
	# 1. at the crossing, a push along a line: vz is damped and integrated as vx is
	place.call(cx, gz + 20.0, 0.0)
	f.vx = 120.0
	f.vz = 60.0
	var xa: float = f.x
	for t in range(60):
		SimFighter.stepFighter(S, f, dt)
		if f.vx == 0.0 or absf(f.vz / f.vx - 0.5) > 0.000000001 or f.zT != f.z:
			return "tick %d: a locked fighter's vz and vx read %s and %s, home %s at depth %s" % [t, str(f.vz), str(f.vx), str(f.zT), str(f.z)]
	var gone: float = SimWrap.sdx(xa, f.x)
	if gone < 20.0 or absf(f.z / gone - 0.5) > 0.000001:
		return "a push along a line of one in two went %s along and %s deep" % [str(gone), str(f.z)]
	# 2. the cap holds vz and not vzX; the data says which cause goes where
	place.call(cx, gz + 20.0, 0.0)
	f.vz = 5000.0
	SimFighter.stepFighter(S, f, dt)
	if absf(f.z - SimDepth.cap * dt) > 0.000000001:
		return "a drift of 5000 a second moved him %s in a tick (the cap gives %s)" % [str(f.z), str(SimDepth.cap * dt)]
	place.call(cx, gz + 20.0, 0.0)
	f.vzX = 600.0
	SimFighter.stepFighter(S, f, dt)
	if absf(f.z - 600.0 * keep * dt) > 0.000000001:
		return "an exempt velocity of 600 moved him %s in a tick" % str(f.z)
	place.call(cx, gz + 20.0, 0.0)
	SimFighter.addDepth(f, "push", 30.0)
	SimFighter.addDepth(f, "carry", 10.0)
	SimFighter.addDepth(f, "shove", -200.0)
	if f.vz != 40.0 or f.vzX != -200.0 or not SimDepth.isExempt("shove") or SimDepth.isExempt("push"):
		return "the causes went to vz %s and vzX %s" % [str(f.vz), str(f.vzX)]
	# 3. in the street, beside a building: the depth part stops at its face and the part along the street goes on
	var stopZ: float = front.z + (front.d * 0.5 + rz + SimDepth.SKIN)   # as the contact rule works it out, to the bit
	var xs: float = SimWrap.wrap(front.x - front.w * 0.5 + rx + 30.0)
	place.call(xs, WorldTerrain.groundY(S, xs, 0.0) + 20.0, stopZ + 30.0)
	var stopped: int = 0
	var room: float = front.w - 2.0 * rx - 60.0
	var t3: int = 0
	while SimWrap.sdx(xs, f.x) < room - 6.0 and t3 < 2000:
		var xb: float = f.x
		f.vx = 150.0
		f.vz = -80.0
		SimFighter.stepFighter(S, f, dt)
		t3 += 1
		if f.z < stopZ:
			return "in the street he went past the face: depth %s, and he stops at %s" % [str(f.z), str(stopZ)]
		if SimWrap.sdx(xb, f.x) <= 0.0:
			return "in the street his step along it stopped (tick %d at depth %s)" % [t3, str(f.z)]
		if f.z == stopZ:
			stopped += 1
			if f.vz != 0.0 or f.zT != f.z:
				return "stopped at the face he kept a depth velocity of %s, or a home of %s" % [str(f.vz), str(f.zT)]
	if stopped < 10:
		return "in the street he never came to the face (depth %s after %d ticks; the face stops him at %s)" % [str(f.z), t3, str(stopZ)]
	# 4. at the crossing he passes the kerb line into the avenue
	place.call(cx, gz + 20.0, float(lane0[1]) + rz + 20.0)
	for t in range(240):
		f.vz = -80.0
		SimFighter.stepFighter(S, f, dt)
	if f.z > float(lane0[1]) - 100.0:
		return "at the crossing he did not pass the kerb line (depth %s; the kerb is at %s)" % [str(f.z), str(lane0[1])]
	# 5. in the avenue, at the block's depth: the part along the street stops at the block's end, and the depth part goes on
	var endX: float = SimWrap.wrap(endB.x - (endB.w * 0.5 + rx + SimDepth.SKIN))
	place.call(cx, WorldTerrain.groundY(S, cx, endB.z) + 20.0, endB.z + endB.d * 0.5 - rz - 40.0)
	if inside.call():
		return "the avenue is not clear at the block's depth"
	var held: int = 0
	for t in range(400):
		var zb: float = f.z
		f.vx = 200.0
		f.vz = -30.0
		SimFighter.stepFighter(S, f, dt)
		if SimWrap.sdx(f.x, endX) < 0.0:
			return "in the avenue he went past the block's end (x %s; it stops him at %s)" % [str(f.x), str(endX)]
		if f.z >= zb:
			return "in the avenue his depth part stopped (tick %d)" % t
		if f.x == endX:
			held += 1
			if f.vx != 0.0:
				return "stopped at the block's end he kept a vx of %s" % str(f.vx)
			if held >= 20:
				break
	if held < 20:
		return "in the avenue he never came to the block's end (x %s; it stops him at %s)" % [str(f.x), str(endX)]
	# 6. a roof holds him, and he walks on it; a body inside a standing building is put out
	var top: float = WorldStructures.baseY(S, front) + WorldStructures.curH(front)
	place.call(front.x - 20.0, top + 60.0, front.z)
	var onRoof: int = 0
	for t in range(80):
		var xr: float = f.x
		f.vx = 60.0
		f.vy = -300.0
		SimFighter.stepFighter(S, f, dt)
		if f.y < top:
			return "he went through the roof (height %s; the roof is at %s)" % [str(f.y), str(top)]
		if f.y == top + SimDepth.SKIN:
			onRoof += 1
			if f.vy != 0.0 or SimWrap.sdx(xr, f.x) <= 0.0:
				return "on the roof he kept falling, or did not walk"
	if onRoof < 20 or WorldStructures.standingAt(S, f.x, f.y, f.z).kind != "roof":
		return "the roof did not hold him (height %s; the roof is at %s)" % [str(f.y), str(top)]
	place.call(front.x, WorldStructures.baseY(S, front) + 10.0, front.z + front.d * 0.5 - 30.0)
	if not inside.call():
		return "the staging did not put him inside the building"
	SimFighter.stepFighter(S, f, dt)
	if inside.call():
		return "a body inside a standing building was not put out"
	# 7. a seeded walk through the city: never inside a standing building below its roof, never outside the band
	var R := SimRng.new(SimRng.deriveSeed(3, "parity.depth.walk"))
	place.call(cx, gz + 20.0, 0.0)
	var wx: float = 0.0
	var wy: float = 0.0
	var wz: float = 0.0
	for t in range(2000):
		if t % 25 == 0:
			wx = R.range_(-420.0, 420.0)
			wy = R.range_(-220.0, 220.0)
			wz = R.range_(-260.0, 260.0)
			if absf(SimWrap.sdx(cx, f.x)) > 2400.0:
				wx = -420.0 if SimWrap.sdx(cx, f.x) > 0.0 else 420.0
		f.vx = wx
		f.vy = wy
		f.vzX = wz
		SimFighter.stepFighter(S, f, dt)
		if inside.call():
			return "tick %d of the walk: he is inside a standing building at (%s, %s, %s)" % [t, str(f.x), str(f.y), str(f.z)]
		if f.z > SimDepth.zFront or f.z < SimDepth.zBack or f.y < WorldTerrain.groundY(S, f.x, f.z) - 0.000001:
			return "tick %d of the walk: he left the band or the ground (%s, %s)" % [t, str(f.y), str(f.z)]
	# 8. the director's own step goes through the same rule
	place.call(cx, gz + 20.0, 0.0)
	if not SimFighter.stepTo(S, f, cx + 30.0, gz + 25.0, -40.0) or f.x != SimWrap.wrap(cx + 30.0) or f.y != gz + 25.0 or f.z != -40.0 or f.zT != -40.0:
		return "a clear step to a place did not put him there (%s, %s, %s)" % [str(f.x), str(f.y), str(f.z)]
	place.call(xs + 40.0, WorldTerrain.groundY(S, xs, 0.0) + 20.0, stopZ + 10.0)
	if SimFighter.stepTo(S, f, f.x + 12.0, f.y, stopZ - 30.0) or f.z != stopZ or f.zT != stopZ or absf(SimWrap.sdx(xs + 40.0, f.x) - 12.0) > 0.000001:
		return "a step into a face ended at depth %s (the face stops him at %s)" % [str(f.z), str(stopZ)]
	var P := SimCore.createSim()
	SimCore.newMatch(P, 5, {"p1": false, "p2": false}, {"intro": false})
	var pf = P.fighters[0]
	var px: float = pf.x
	if not SimFighter.stepTo(P, pf, px + 9.0, pf.y + 3.0, -300.0) or pf.x != SimWrap.wrap(px + 9.0) or pf.z != 0.0:
		return "with depth off a step to a place moved his depth, or missed the place"
	# 9. the new state is in the hash only with depth on
	var h0: String = SimHash.stateHash(P).gameplay
	pf.vz = 12.0
	pf.vzX = -7.0
	P.dirS.lineSin = 0.3
	P.dirS.sideT = 4
	if SimHash.stateHash(P).gameplay != h0:
		return "with depth off the depth step's state changed the hash"
	SimCore.dispose(P)
	place.call(cx, gz + 20.0, 0.0)
	var h1: String = SimHash.stateHash(S).gameplay
	for k in range(4):
		if k == 0: f.vz = 3.0
		elif k == 1: f.vzX = 3.0
		elif k == 2: S.dirS.lineSin = 0.25
		else: S.dirS.homeWait = 9
		var h2: String = SimHash.stateHash(S).gameplay
		if h2 == h1:
			return "with depth on, field %d of the depth step's state is not in the hash" % k
		h1 = h2
	SimCore.dispose(S)
	# 10. a match with depth on replays to the same hash
	for seed in [3, 5, 12345]:
		var hs: Array = []
		for run in range(2):
			var M := SimCore.createSim()
			SimCore.newMatch(M, seed, {}, {"depth": true})
			for t in range(1500):
				SimCore.step(M)
				M.out.fx.clear()
				M.out.feed.clear()
				for mf in M.fighters:
					if mf.z > SimDepth.zFront or mf.z < SimDepth.zBack or mf.z != mf.z:
						return "seed %d, tick %d: a fighter's depth reads %s" % [seed, t, str(mf.z)]
			hs.append(SimHash.stateHash(M).gameplay)
			SimCore.dispose(M)
		if hs[0] != hs[1]:
			return "seed %d with depth on did not replay to the same hash" % seed
	return ""


## The second breath (spec-wounds.md section 1c): a battered region fades once the fighter has had quiet for the wait'''),
])
if 'y its feet' in open('sim/world/structures.gd',encoding='utf-8').read():   # World's feet window: blocked takes his feet
    edit('sim/core/tools/parity.gd', [
    ('WorldStructures.blocked(S, f.x, f.y + ry, f.z, float(body[0]), float(body[1]), float(body[2])) >= 0',
     'WorldStructures.blocked(S, f.x, f.y, f.z, float(body[0]), float(body[1]), float(body[2])) >= 0'),
    ])
print("part (a): the checks are in")
