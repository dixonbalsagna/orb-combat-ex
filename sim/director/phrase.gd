class_name DirPhrase
extends RefCounted
## Phrases (docs/design/rule-of-cool-map.md row 1; docs/combat/pending/phrases/README.md's reader's rules): a press inside a phrase of
## his takes its next piece in place of the pool's draw, and one outside falls back to the pool. Worth and timing are the cell's. No
## press waits to decide: a mash's first two presses throw from the pool. Anything else, or gapTicks from his last blow, breaks it for
## free. The last blow reads the place once, takes that class's ender, and finishes. Off, the file isn't opened and no slot is sized.

const PATH: String = "res://data/combat/phrases.json"
const P_ALIVE: int = 0  # the phrases still alive, a bit each, in the low 12; which have reached a mash or a hold's blows, in the next 12
const P_K: int = 1      # the part each has reached, 2 bits each
const P_N: int = 2      # blows taken from the part in turn
const P_RUN: int = 3    # presses of one button in a run, x 4, plus the button (0 X, 1 Y, 2 the stick)
const P_LAST: int = 4   # the live tick of his last press, plus 1
const P_BLOW: int = 5   # the live tick of his last blow on the phrase, plus 1; 0 none
const P_DONE: int = 6   # phrases finished: QA's row
const P_N_SLOTS: int = 7
const MASH_GAP: int = 20   # README 5: SimPressRead's reading, about the third press inside this
const MASH_AT: int = 3

static var _d = null
static var _text: String = ""
static var _force: int = -1   # tools: -1 the data's switch, 0 off, 1 on


static func setForce(v: int) -> void:
	_force = v


static func _ensure() -> void:
	if _d == null:
		_text = FileAccess.get_file_as_string(PATH) if FileAccess.file_exists(PATH) else ""
		_d = JSON.parse_string(_text) if _text != "" else {}
		if not (_d is Dictionary):
			_d = {}


static func cfg() -> Dictionary:
	_ensure()
	return _d


static func dataText() -> String:
	_ensure()
	return _text


static func on() -> bool:
	return (bool(cfg().get("enabled", false)) if _force < 0 else _force == 1) and not cfg().is_empty()


static func _b() -> int:
	return DirStance._b() + DirStance.S_N


static func _g(f, k: int) -> int:
	var d: PackedInt32Array = f.act.dirI
	var i: int = _b() + k
	return d[i] if i < d.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirPlane._size(f)
	if f.act.dirI.size() < _b() + P_N_SLOTS:
		f.act.dirI.resize(_b() + P_N_SLOTS)
	f.act.dirI[_b() + k] = v


static func _list(f) -> Array:
	var e = cfg().fighters.get(DirRecipe.poolKey(f))
	return e.phrases if e is Dictionary else []


static func _reset(f, n: int) -> void:
	_s(f, P_ALIVE, (1 << n) - 1)
	_s(f, P_K, 0)
	_s(f, P_N, 0)


static func _kOf(kk: int, i: int) -> int:
	return (kk >> (i * 2)) & 3


static func _setK(kk: int, i: int, v: int) -> int:
	return (kk & ~(3 << (i * 2))) | (v << (i * 2))


## The class of place the last blow lands in, read once (the README's eight). Standing buildings, the ground, the height: never who's there.
static func placeClass(S: SimState, f, o) -> String:
	var alt: float = float(o.y) - WorldTerrain.groundY(S, o.x)
	if alt > 900.0:
		return "highAir"
	if alt > 200.0:
		return "lowAir"
	if WorldTerrain.seaAt(S, o.x):
		return "water"
	for bi in WorldStructures.near(S, o.x, 300.0):
		var b = S.buildings[bi]
		if b.alive and absf(SimWrap.sdx(o.x, b.x)) - b.w * 0.5 <= 300.0 and absf(float(b.z) - float(o.z)) - b.d * 0.5 <= 300.0:
			return "face"
	var look: String = WorldContact.lookAt(S, o.x)
	if look == "ice" or look == "wet" or look == "slick":
		return "slick"
	var bio: String = WorldBiomes.biomeAt(o.x)
	if bio == "forest":
		return "trees"
	if bio == "city" or bio == "village":
		return "street"
	return "open"


## One blow's part: b "X", "Y" or "stick"; g "tap", "hold", "flick"; dir for the stick. Returns the piece to throw, or "" for the pool's.
static func read(S: SimState, f, o, b: String, g: String, dir: String = "") -> String:
	if not on():
		return ""
	var list: Array = _list(f)
	if list.is_empty():
		return ""
	var now: int = DirBrawl._now(S)
	if _g(f, P_BLOW) == 0 or now - (_g(f, P_BLOW) - 1) > int(cfg().gapTicks):
		_reset(f, list.size())
	var btn: int = 0 if b == "X" else (1 if b == "Y" else 2)
	var run: int = 1
	var was: int = _g(f, P_RUN)
	if g == "tap" and (was & 3) == btn and was != 0 and now - (_g(f, P_LAST) - 1) <= MASH_GAP:
		run = (was >> 2) + 1
	if g == "tap":
		_s(f, P_RUN, (run << 2) | btn)
		_s(f, P_LAST, now + 1)
	var piece: String = _walk(S, f, o, list, b, g, dir, run)
	_s(f, P_BLOW, now + 1)
	return piece


static func _walk(S: SimState, f, o, list: Array, b: String, g: String, dir: String, run: int, again: bool = false) -> String:
	var alive: int = _g(f, P_ALIVE)
	var reached: int = alive >> 12
	alive = alive & 0xfff
	var kk: int = _g(f, P_K)
	var n: int = _g(f, P_N)
	var outAlive: int = 0
	var outReached: int = 0
	var piece: String = ""
	var turn: bool = false
	var done: int = -1
	for i in range(list.size()):
		if (alive & (1 << i)) == 0:
			continue
		var parts: Array = list[i].parts
		var k: int = _kOf(kk, i)
		var inPart: bool = (reached & (1 << i)) != 0
		var p: Dictionary = parts[k]
		if inPart:
			if String(p.b) == b and (g == "tap" or g == "burst"):
				# a mash or a burst goes on: its blows in turn
				var ps: Array = p.pieces
				if piece == "":
					piece = String(ps[n % ps.size()])
				turn = true
				if k == parts.size() - 1 and n + 1 >= ps.size():
					done = i if done < 0 else done
				outAlive |= 1 << i
				outReached |= 1 << i
				continue
			if k + 1 >= parts.size():
				continue
			k += 1   # another button: the part's over, and this blow is the next one's
			kk = _setK(kk, i, k)
			p = parts[k]
		if String(p.b) != b:
			continue
		if b == "stick" and String(p.get("dir", "")) != dir:
			continue
		var pg: String = String(p.g)
		if pg == g:
			if p.has("pieces"):
				if piece == "":
					piece = String(p.pieces[0])
				outAlive |= 1 << i
				outReached |= 1 << i
				continue
			if piece == "" and p.has("piece"):
				piece = String(p.piece)
			if k + 1 >= parts.size():
				done = i if done < 0 else done
				continue
			kk = _setK(kk, i, k + 1)
			outAlive |= 1 << i
		elif pg == "mash" and g == "tap":
			if run >= MASH_AT:
				if piece == "":
					piece = String(p.pieces[0])
				outReached |= 1 << i
			outAlive |= 1 << i
		elif pg == "hold" and g == "tap":
			outAlive |= 1 << i   # it may yet be held: this press throws from the pool
	if done >= 0:
		var cls: String = placeClass(S, f, o)
		var ender: String = String(list[done].enders.get(cls, ""))
		_reset(f, list.size())
		_s(f, P_DONE, _g(f, P_DONE) + 1)
		SimFx.cue(S, f, "phrase_done", String(list[done].id), cls)
		return ender if ender != "" else piece
	if outAlive == 0:
		_reset(f, list.size())
		if not again:
			return _walk(S, f, o, list, b, g, dir, 1, true)   # broken, for free: this blow can start a new one
		return ""
	_s(f, P_ALIVE, outAlive | (outReached << 12))
	_s(f, P_K, kk)
	_s(f, P_N, (n + 1) if turn else (1 if outReached != 0 and reached == 0 else n))
	return piece


## Combat's piece into the pool's memory, under the same rules as a drawn one: no two blows running to the gut, or the pool draws.
static func take(f, id: String) -> String:
	if id == "":
		return ""
	var was: int = DirBrawl._g(f, DirBrawl.GUT) & 1
	if was == 1 and DirRecipe.toGut(id):
		return ""
	DirRecipe.took(f, id)
	DirBrawl._s(f, DirBrawl.GUT, (1 if DirRecipe.toGut(id) else 0) | (was << 1))
	return id


## His wound blow still held past its wind-up: a Y hold. The blow's piece is the part's, if a phrase is on one.
static func heldY(S: SimState, ex, f, o) -> void:
	if not on():
		return
	var id: String = take(f, read(S, f, o, "Y", "hold"))
	if id == "":
		return
	var role: String = "A" if f == ex.A else "D"
	for b in ex.beats:
		if not b.done and b.op == "strike" and b.args != null and b.args.get("brawl", false) and String(b.args.a) == role:
			b.args["piece"] = id
			return
