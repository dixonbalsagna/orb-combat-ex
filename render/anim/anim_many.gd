class_name AnimMany
extends RefCounted
## Many bodies on the one rig (nine-cells-look.md section 5; Encounter's one-versus-many model: a partner in the brawl and the others in a ring, one interjection at most every 1.5 s). The sim is two fighters
## long today, so a scene or a scan that wants three to five bodies puts stand-ins beside the pair for the length of one solve: `step` makes them (once), places them in a ring about the pair, ticks and solves
## them with the real pair, and `detach` takes them out of `S.fighters` before the sim next runs. RENDER-SIDE ONLY: nothing is written to the sim's state that the sim reads, because the stand-ins are
## never in `S.fighters` while it steps, and the real fighters' fields are only read. Used by `anim_check` (`_test_many_bodies`) and the scans' `--bodies=N`.

const RING: Array = [420.0, -520.0, 640.0]   # units from the pair's middle, a stand-in each (the third is far: the camera's marker case)


## The stand-ins for a match, made once (the same count every call).
static func make(S: SimState, count: int) -> Array:
	var out: Array = []
	var order: Array = FighterData.order()
	for i in range(count):
		var def: Dictionary = FighterData.def(order[i % order.size()])
		var st: SimState.Fighter = SimRoster.createFighter(def, S.fighters[0].x, "p2", false)
		out.append(st)
	return out


## Places the stand-ins about the real pair, adds them to `S.fighters`, ticks and solves everything once. Call after the sim's step and the real fighters' own render; call `detach` before the sim steps again.
static func step(S: SimState, stands: Array, dt: float) -> void:
	var real: Array = []
	for f in S.fighters:
		if not stands.has(f):
			real.append(f)
	if real.size() < 2:
		return
	var mid: float = real[0].x + SimWrap.sdx(real[0].x, real[1].x) * 0.5
	for i in range(stands.size()):
		var st = stands[i]
		var r: float = float(RING[i % RING.size()])
		var px: float = st.x
		st.x = SimWrap.wrap(mid + r)
		st.y = WorldTerrain.groundY(S, st.x, st.z)
		st.vx = SimWrap.sdx(px, st.x) / maxf(dt, 0.0001) if px != 0.0 else 0.0
		st.vy = 0.0
		st.state = "free"
		st.face = -1.0 if r > 0.0 else 1.0
		if not S.fighters.has(st):
			S.fighters.append(st)
	for st in stands:
		var af: AnimFighter = RenderAnim.fighter(S, st)
		af.on_tick(dt, false, S, st)
		RenderAnim.solve(S, st)


## Takes the stand-ins out of the match's list.
static func detach(S: SimState, stands: Array) -> void:
	for st in stands:
		S.fighters.erase(st)
