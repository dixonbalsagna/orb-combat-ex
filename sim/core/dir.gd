class_name SimDir
## The director's functions that the core's and the world's scripts call (docs/architecture/load-split.md). They are
## reached by the director script's path, not its class name, so that loading the core and the world does not compile
## the director: Rendering's boot entry loads the director's scripts in a frame of their own (2026-10-27). Each is the
## director's own function, called with the same arguments. A script is loaded the first time it is called and kept;
## in a match it is loaded already, since SimCore's step names the director's classes (the step, the intro, the replay
## and the controls are outside the core's graph and still name them). A new call from the core or the world into the
## director goes here: tools/load_split.gd fails if the core's load compiles any of the director, and checks that every
## function named here is in its script.

const _DIR: String = "res://sim/director/"
static var _got: Dictionary = {}   # a director script's file: the script, loaded once


static func _d(file: String):
	var s = _got.get(file)
	if s == null:
		s = load(_DIR + file)
		_got[file] = s
	return s


## DirExchange.endEx: the running exchange ends (a K.O. inside one).
static func endEx(S: SimState, ex) -> void:
	_d("exchange.gd").endEx(S, ex)


## DirExchange.transformSource: what a form's ready tell names as its source.
static func transformSource(f) -> String:
	return _d("exchange.gd").transformSource(f)


## DirExchange.formBreak: the rival in reach is pushed back at a form's break.
static func formBreak(S: SimState, f) -> void:
	_d("exchange.gd").formBreak(S, f)


## DirLaunch.doLaunch: a launch (the K.O.'s).
static func doLaunch(S: SimState, att, tgt, plan: Dictionary, force: float, special: bool = false) -> void:
	_d("launch.gd").doLaunch(S, att, tgt, plan, force, special)


## DirLaunch.flightHook: World's read of f's launch plan for the flight hooks ({} when f's launch carries none).
static func flightHook(S: SimState, f) -> Dictionary:
	return _d("launch.gd").flightHook(S, f)


## DirLaunch.brokenProps: the columns of the props broken in this match, for World's prop query.
static func brokenProps(S: SimState) -> PackedInt32Array:
	return _d("launch.gd").brokenProps(S)


## DirLaunch.propBroke: World's flight broke f's PROP SMASH prop (the director keeps it broken).
static func propBroke(S: SimState, f) -> void:
	_d("launch.gd").propBroke(S, f)


## DirBands.who: the fighter a band holds, or -1.
static func bandsWho(S: SimState) -> int:
	return _d("bands.gd").who(S)


## DirBlast.rules: the director's blast rules are on.
static func blastRules(S: SimState) -> bool:
	return _d("blast.gd").rules(S)


## DirBlast.hit: a shot meets a fighter under the director's blast rules.
static func blastHit(S: SimState, sh, f) -> bool:
	return _d("blast.gd").hit(S, sh, f)


## DirCalm.atReady: a form's ready tell, for the calm turn's warm.
static func calmAtReady(S: SimState, f) -> void:
	_d("calm.gd").atReady(S, f)


## DirBrawl.payMul: what a launcher's send pays in a wall or ground contact.
static func brawlPayMul(f) -> float:
	return _d("brawl.gd").payMul(f)


## DirWallKick.atWall: an armed wall kick takes the face.
static func wallKickAt(S: SimState, f, b, edge: float, dir: float, spN: float) -> bool:
	return _d("wallkick.gd").atWall(S, f, b, edge, dir, spN)


## DirWallKick.damageMul: a wall kick's slam, as a share of a slam.
static func wallKickMul() -> float:
	return _d("wallkick.gd").damageMul()
