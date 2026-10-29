class_name NetDesync
extends RefCounted
## Desync detection and reporting (docs/net/rollback.md section 7). Peers exchange a cheap digest of a confirmed state
## every NetSession.checkEvery ticks; a mismatch makes both keep the replay and their snapshot of that tick and write a
## report (writeReport): the tick, both digests, and the first differing fields a field walk finds.
##
## digest(S) is the cheap hash: the fields a divergence reaches first (the clock, the RNG, every fighter's hashed
## fields, the director's counters, the mood and the pause, each building's and tree's damage, the shots) and the
## terrain's per-column arrays (deform, water, scorch, rubble, crack, aftermath), through the engine's MD5, which reads
## a packed array as one block. A divergence in a field outside it is caught once it reaches
## one inside, which in this sim is the next tick or two (most state feeds the fighters or the RNG). SimHash.stateHash
## stays the full check (tests, and the replay's checkpoints).
## The digest lives in net/, not the sim: it is a network check. Its MD5 is the engine's (HashingContext), which the
## web build has too. It is not a security hash and needs not be: a peer that lies can lie about anything.
##
## The field walk (firstDiffs) compares two state graphs field by field, in property-list order, and names the paths
## that differ: "S.fighters[1].x", "S.deform[2311]". A peer can walk its own snapshot against the state its replay
## re-simulates (replayState): if they differ, this peer diverged from its own inputs (a sim bug, or memory gone bad);
## if they agree, the other peer or the platform did. Walking one peer's state against the other's needs the other's
## snapshot; the loopback has both (net/tools/desync_check.gd).

const FORMAT: String = "meridian-desync"
const V: int = 1
const TERRAIN: Array = ["deform", "water", "scorch", "rubble", "crack", "aftermath", "aftermathT"]
## SimState fields the walk skips: S.out (output), and worldId, which names the world this process built (a process
## counter, the same on both peers only by chance; not hashed).
const WALK_SKIP: Array = ["out", "worldId"]


## The cheap confirmed-state digest (32 hex digits): every value goes into one PackedFloat64Array, strings into the
## hash as UTF-8, and the engine's MD5 reads the array and the terrain's packed arrays as blocks, so the GDScript cost is
## one append per value. Byte order is little-endian on every platform the game ships on.
static func digest(S: SimState) -> String:
	var v := PackedFloat64Array()
	var md := HashingContext.new()
	md.start(HashingContext.HASH_MD5)
	v.append(S.T); v.append(S.tick); v.append(S.rng.a); v.append(S.waterTick); v.append(S.shotSeq)
	var g := S.game
	v.append(_idx(S.fighters, g.ko)); v.append(g.koT); v.append(g.ts)
	var d := S.dirS
	v.append(d.exN); v.append(d.cool); v.append(d.stop)
	_text(md, d.lastLaunch)
	var m := S.mood
	v.append(m.t); v.append(m.v); v.append(m.band); v.append(m.act); v.append(m.beats); v.append(m.casGiven); v.append(m.lastCombo)
	var p := S.pause
	v.append(p.left); v.append(p.bank); v.append(p.acc); v.append(p.total); v.append(p.count)
	v.append(S.fighters.size())
	for f in S.fighters:
		for k in SimHash.FIGHTER:
			var x = f.get(k)
			match typeof(x):
				TYPE_FLOAT, TYPE_INT:
					v.append(x)
				TYPE_BOOL:
					v.append(1.0 if x else 0.0)
				TYPE_STRING:
					_text(md, x)
				TYPE_NIL:
					v.append(-1.0)
				_:
					v.append(-2.0)   # an object or a container: its presence only (the field walk reads it)
	v.append(S.buildings.size())
	if S.bound():   # the per-tick fields from the state's arrays, as SimHash reads them: a snapshot's records read the live state's (docs/architecture/packed-structures.md)
		for i in range(S.buildings.size()):
			v.append(S.bHp[i]); v.append(S.bFmask[i]); v.append(S.bPopAlive[i]); v.append(S.bFled[i]); v.append(S.bWear[i]); v.append(float(S.bAlive[i]))
	else:
		for b in S.buildings:
			v.append(b.hp); v.append(b.fmask); v.append(b.popAlive); v.append(b.fled); v.append(b.wear); v.append(1.0 if b.alive else 0.0)
	v.append(S.trees.size())
	if S.bound():
		for i in range(S.trees.size()):
			v.append(S.tBurn[i]); v.append(float(S.tAlive[i]))
	else:
		for t in S.trees:
			v.append(t.burn); v.append(1.0 if t.alive else 0.0)
	v.append(S.shots.size())
	for s in S.shots:
		v.append(s.x); v.append(s.y); v.append(s.left)
	v.append(S.beams.size()); v.append(S.craters.size()); v.append(S.slides.size())
	md.update(v.to_byte_array())
	for k in TERRAIN:
		var a = S.get(k)
		var bytes: PackedByteArray = a if a is PackedByteArray else a.to_byte_array()
		if bytes.size() > 0:
			md.update(bytes)
	return md.finish().hex_encode()


static func _text(md: HashingContext, s: String) -> void:
	var b: PackedByteArray = s.to_utf8_buffer()
	b.append(0)   # a terminator, so "ab" + "" and "a" + "b" differ
	md.update(b)


static func _idx(fs: Array, f) -> float:
	return -1.0 if f == null else float(fs.find(f))


## A replay of a session's confirmed inputs below `upto`, in SimReplay's format (v4), with no checkpoints and no final
## hash: SimReplay.play runs it, and replayState stops it at a tick. info is the match: {seed, setup, ai}.
static func replayOf(sess: NetSession, info: Dictionary, upto: int) -> Dictionary:
	var setup: Dictionary = info.get("setup", {})
	var rp := {"format": SimReplay.FORMAT, "v": SimReplay.V, "intent": SimIntent.VERSION, "data": SimReplay.dataHash(setup),
		"seed": int(info.get("seed", 1)), "setup": setup.duplicate(true), "ai": info.get("ai", {"p1": false, "p2": false}).duplicate(),
		"ticks": upto, "inputs": [], "toggles": [], "checkpoints": [], "final": ""}
	var log: Array = sess.confirmedLog(upto)
	log.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	for e in log:
		rp.inputs.append([e[0], e[1]] + SimReplay.split(e[2]))
	return rp


## The state after `ticks` ticks of a replay (the caller disposes it with SimCore.dispose), or null if it does not run
## here (another format or other data).
static func replayState(rp: Dictionary, ticks: int) -> SimState:
	if rp.get("format", "") != SimReplay.FORMAT or int(rp.get("v", 0)) != SimReplay.V or rp.get("data", "") != SimReplay.dataHash(rp.get("setup", {})):
		return null
	var S := SimCore.createSim()
	SimCore.newMatch(S, int(rp.seed), rp.ai, rp.get("setup", {}))
	var cur: Array = []
	cur.resize(S.fighters.size())
	var ii: int = 0
	for t in range(ticks):
		while ii < rp.inputs.size() and int(rp.inputs[ii][0]) == t:
			var p: int = SimReplay.join(rp.inputs[ii][2], rp.inputs[ii][3])
			cur[int(rp.inputs[ii][1])] = SimIntent.unpack(p) if p >= 0 else null
			ii += 1
		SimCore.step(S, cur)
		S.out.fx.clear()
		S.out.feed.clear()
	return S


## The field walk: up to `limit` paths where two states differ, each {path, a, b} with the values as text. Empty when
## they are the same. It goes breadth first, in property-list order, so an object is named by its shortest path (the
## second fighter is S.fighters[1], not S.fighters[0].launchBy) and the shallowest differences come first. S.out and
## worldId are skipped (WALK_SKIP); shared data definitions are compared by identity.
static func firstDiffs(a: SimState, b: SimState, limit: int = 8) -> Array:
	var found: Array = []
	var seen: Dictionary = {}
	var queue: Array = [[a, b, "S"]]
	seen["%d:%d" % [a.get_instance_id(), b.get_instance_id()]] = true
	var qi: int = 0
	while qi < queue.size() and found.size() < limit:
		var e: Array = queue[qi]
		qi += 1
		var x = e[0]
		var y = e[1]
		var path: String = e[2]
		var kids: Array = []   # [x, y, path] to compare
		match typeof(x):
			TYPE_OBJECT:
				for k in NetSnapshot.props(x):
					if path == "S" and WALK_SKIP.has(k):
						continue
					kids.append([x.get(k), y.get(k), path + "." + k])
			TYPE_ARRAY:
				for i in range(x.size()):
					kids.append([x[i], y[i], "%s[%d]" % [path, i]])
			TYPE_DICTIONARY:
				var ks: Array = x.keys()
				ks.sort()
				for k in ks:
					kids.append([x[k], y[k], "%s[%s]" % [path, str(k)]])
		for c in kids:
			if found.size() >= limit:
				break
			var deeper: bool = _compare(c[0], c[1], c[2], found, limit)
			if not deeper:
				continue
			if typeof(c[0]) == TYPE_OBJECT:
				var key: String = "%d:%d" % [c[0].get_instance_id(), c[1].get_instance_id()]
				if seen.has(key):
					continue
				seen[key] = true
			queue.append(c)
	return found


## Compare two values. Leaves are compared here (a difference goes into found); returns true for a pair of objects or
## containers of the same shape, whose contents the walk visits next.
static func _compare(x, y, path: String, found: Array, limit: int) -> bool:
	var tx: int = typeof(x)
	var ty: int = typeof(y)
	if tx != ty:
		found.append({"path": path, "a": _fmt(x), "b": _fmt(y)})
		return false
	match tx:
		TYPE_OBJECT:
			if x == null or y == null:
				if x != y:
					found.append({"path": path, "a": str(x), "b": str(y)})
				return false
			if x.get_script() != y.get_script():
				found.append({"path": path, "a": str(x.get_script()), "b": str(y.get_script())})
				return false
			return not (NetSnapshot.shared(x) or NetSnapshot.shared(y))
		TYPE_ARRAY:
			if x.size() != y.size():
				found.append({"path": path + ".size()", "a": str(x.size()), "b": str(y.size())})
				return false
			return true
		TYPE_DICTIONARY:
			var kx: Array = x.keys()
			var ky: Array = y.keys()
			kx.sort()
			ky.sort()
			if kx != ky:
				found.append({"path": path + ".keys()", "a": str(kx), "b": str(ky)})
				return false
			return true
		TYPE_FLOAT, TYPE_INT:
			if not _same(float(x), float(y)):
				found.append({"path": path, "a": _fmt(x), "b": _fmt(y)})
		TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_BYTE_ARRAY:
			if x.size() != y.size():
				found.append({"path": path + ".size()", "a": str(x.size()), "b": str(y.size())})
				return false
			var bx: PackedByteArray = x if x is PackedByteArray else x.to_byte_array()
			var by: PackedByteArray = y if y is PackedByteArray else y.to_byte_array()
			if bx == by:
				return false
			for i in range(x.size()):
				if not _same(float(x[i]), float(y[i])):
					found.append({"path": "%s[%d]" % [path, i], "a": _fmt(x[i]), "b": _fmt(y[i])})
					if found.size() >= limit:
						break
		_:
			if x != y:
				found.append({"path": path, "a": str(x), "b": str(y)})
	return false


## A value as text; a float whose shortest text does not give back its bits also shows them.
static func _fmt(v) -> String:
	if typeof(v) != TYPE_FLOAT:
		return str(v)
	var t: String = str(v)
	if _same(float(t), v):
		return t
	_bx.resize(8)
	_bx.encode_double(0, v)
	return "%s (bits %08x%08x)" % [t, _bx.decode_u32(4), _bx.decode_u32(0)]


static var _bx := PackedByteArray()
static var _by := PackedByteArray()


## Bit equality (so -0.0 differs from 0.0, as the hash says, and a NaN equals the same NaN).
static func _same(p: float, q: float) -> bool:
	if _bx.size() != 8:
		_bx.resize(8)
		_by.resize(8)
	_bx.encode_double(0, p)
	_by.encode_double(0, q)
	return _bx == _by


## The report for a session's desync (NetSession.desync), as a Dictionary that JSON.stringify writes: the tick, both
## digests, the last tick both agreed on, the replay, and two field walks: this peer's snapshot of the tick against its
## replay's re-simulation ("vsReplay": empty when they agree), and, when the other peer's snapshot of the same tick is to
## hand (the loopback), against that ("vsPeer").
static func report(sess: NetSession, peerSnap: NetSnapshot = null, limit: int = 8) -> Dictionary:
	var d: Dictionary = sess.desync
	if d.is_empty():
		return {}
	var out := {"format": FORMAT, "v": V, "slot": sess.local, "tick": d.tick, "local": d.local, "remote": d.remote,
		"lastAgreed": d.lastAgreed, "frame": d.frame, "replay": d.replay, "vsReplay": [], "vsPeer": [], "replayRuns": false}
	var snap: NetSnapshot = d.snap
	var ref := replayState(d.replay, int(d.tick))
	if ref != null:
		out.replayRuns = true
		out.vsReplay = firstDiffs(ref, snap.root, limit)
		out["replayDigest"] = digest(ref)
		SimCore.dispose(ref)
	if peerSnap != null:
		out.vsPeer = firstDiffs(snap.root, peerSnap.root, limit)
	return out


## Write a report as JSON. Returns the error code (OK is 0).
static func writeReport(rep: Dictionary, path: String) -> int:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(rep, " "))
	f.close()
	return OK
