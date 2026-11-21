class_name UiModes
extends RefCounted
## The start menu's modes and fighters, read from data (docs/ui/menus-a1.md): ui/data/modes.json (the list, its states, whether a row is shown in the testers' package, whether two players may pick the same
## fighter) and data/fighters/roster.json (who can be picked; a fighter whose role is "reference", the practice dummy, cannot). No fighter and no mode is named in code: a row appears when its data does.

const PATH := "res://ui/data/modes.json"
const ROSTER := "res://data/fighters/roster.json"
const FIGHTERS := "res://data/fighters/"
static var _data: Dictionary = {}
static var _pick: Array = []


static func data() -> Dictionary:
	if _data.is_empty():
		_data = UiData._read(PATH)   # through the locale path, so the pseudo-locale build reads its own twin of the file
		if _data.is_empty():
			_data = {"modes": []}
	return _data


## The rows the list shows: every mode, except the ones the testers' package leaves out when features.json testers_package is on.
static func modes() -> Array:
	var out: Array = []
	var testers: bool = UiData.feature("testers_package")
	for m in data().get("modes", []):
		if m is Dictionary and not (testers and not bool((m as Dictionary).get("testers", true))):
			out.append(m)
	return out


static func mode(id: String) -> Dictionary:
	for m in data().get("modes", []):
		if m is Dictionary and str((m as Dictionary).get("id", "")) == id:
			return m
	return {}


## Whether a mode can be started now.
static func ready(id: String) -> bool:
	return str(mode(id).get("state", "coming")) == "ready"


## The number of people who play a mode (1 or 2).
static func players(id: String) -> int:
	return clampi(int(mode(id).get("players", 1)), 1, 2)


## The first ready mode whose number of people is `players`, or "" (a saved choice from before the list).
static func mode_for_players(n: int) -> String:
	for m in data().get("modes", []):
		if m is Dictionary and str((m as Dictionary).get("state", "")) == "ready" and int((m as Dictionary).get("players", 1)) == n:
			return str((m as Dictionary).get("id", ""))
	return ""


## Whether two players may pick the same fighter (data: mirror_pick).
static func mirror_ok() -> bool:
	return bool(data().get("mirror_pick", false))


## The roster ids a player can pick, in the roster's order.
static func fighters() -> Array:
	if _pick.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string(ROSTER))
		if j is Array:
			for id in j:
				var f = JSON.parse_string(FileAccess.get_file_as_string(FIGHTERS + str(id) + "/fighter.json"))
				var role: String = str(((f as Dictionary).get("identity", {}) as Dictionary).get("role", "")) if f is Dictionary else ""
				if role != "reference":
					_pick.append(str(id))
	return _pick


## A saved or sent fighter as one the roster has, else the roster's `slot`th pickable fighter (0 or 1).
static func fighter_of(v, slot: int) -> String:
	var fs: Array = fighters()
	if fs.is_empty():
		return ""
	return str(v) if fs.has(str(v)) else str(fs[mini(slot, fs.size() - 1)])


## The fighter after a step of d along the roster (held at the ends, or wrapping).
static func fighter_step(cur: String, d: int, wrap: bool) -> String:
	var fs: Array = fighters()
	if fs.is_empty():
		return cur
	var n: int = fs.size()
	var i: int = maxi(fs.find(cur), 0)
	return str(fs[posmod(i + d, n) if wrap else clampi(i + d, 0, n - 1)])


## A step of the pick of player `slot` (0 or 1) given the pair {a, b}: returns the new pair. Without mirror picks (data: mirror_pick) a step onto the fighter the other player holds gives that player the one just left, so the two
## always differ and a roster of two can still be picked from; with them the other keeps theirs.
static func pair_step(pair: Array, slot: int, d: int) -> Array:
	var out: Array = pair.duplicate()
	var old: String = str(out[slot])
	var nxt: String = fighter_step(old, d, true)
	out[slot] = nxt
	if not mirror_ok() and nxt == str(out[1 - slot]):
		out[1 - slot] = old
	return out


## The pair a first menu shows: the first two pickable fighters, or one twice when the roster has one.
static func default_pair() -> Array:
	var fs: Array = fighters()
	if fs.is_empty():
		return ["", ""]
	return [str(fs[0]), str(fs[mini(1, fs.size() - 1)])]
