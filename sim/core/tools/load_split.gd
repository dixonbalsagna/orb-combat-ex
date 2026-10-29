extends SceneTree
## The sim's script loads, in the order Rendering's boot entry makes them (docs/architecture/load-split.md). In a fresh
## process each step's load() compiles its script graph less what the steps before it loaded. This prints each step's
## time and how many of the director's scripts are loaded after it, and fails if the first step (the core and the
## world) loads any of them: a director class named in a script the core's graph reaches pulls the whole director back
## into that load. It also checks that every director function SimDir (sim/core/dir.gd) calls is in its script, since
## those calls are found by name only when they run, and that the core, the world and the input reach the director only
## by SimDir's named forwards (each SimDir.name( they call is defined there; none calls SimDir._d itself). This script
## names no sim class, so it compiles nothing itself.
##   godot --headless --path . --script res://sim/core/tools/load_split.gd [-- --steps=res://a.gd,res://b.gd]
## --negative-control: three breaks, on copies of the sources in memory (no file changes), must each be caught: a forward
## naming a function its director script lacks, a forward the world calls that SimDir no longer defines, and a world call
## by SimDir._d.

## The load order for the boot entry (render/core/boot_entry.gd), one load a frame.
const STEPS: Array = [
	"res://sim/core/act.gd",           # the core and the world
	"res://sim/core/shots.gd",         # the shots (the director's, not the core's)
	"res://sim/input/press_read.gd",   # the input's reading (the director's AI and presses)
	"res://sim/input/aim.gd",
	"res://sim/director/exchange.gd",  # the director, on its own
	"res://sim/core/campaign.gd",      # SimCore's step, the campaign, the run, the intro and the replay
	"res://sim/input/hub.gd",          # the input layer
]
const DIR_GD: String = "res://sim/core/dir.gd"
const CONTACT: String = "res://sim/world/contact.gd"


func _init() -> void:
	var steps: Array = STEPS
	var neg: bool = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--steps="):
			steps = Array(a.substr(8).split(","))
		elif a == "--negative-control":
			neg = true
	if neg:
		quit(0 if _negative() else 1)
		return
	var dir: Array = _scripts("res://sim/director/")
	var sim: Array = []
	for d in ["res://sim/core/", "res://sim/world/", "res://sim/director/", "res://sim/input/"]:
		sim.append_array(_scripts(d))
	var bad: bool = false
	var total: float = 0.0
	for i in range(steps.size()):
		var t0: int = Time.get_ticks_usec()
		var s = load(steps[i])
		var ms: float = float(Time.get_ticks_usec() - t0) / 1000.0
		total += ms
		var nd: int = _cached(dir)
		print("%-34s %8.1f ms   sim scripts loaded %3d of %d, the director's %2d of %d%s" % [steps[i], ms, _cached(sim), sim.size(), nd, dir.size(), "" if s != null else "   (NOT LOADED)"])
		if s == null:
			bad = true
		if i == 0 and nd > 0:
			print("FAIL: the core's load compiles the director")
			bad = true
	print("total %.1f ms" % total)
	var dirSrc: String = FileAccess.get_file_as_string(DIR_GD)
	if not _calls(dirSrc):
		bad = true
	if not _uses(dirSrc, _callers()):
		bad = true
	print("FAIL" if bad else "ok: the director is a load of its own, SimDir's calls are all in their scripts, and the core and the world call it by name")
	quit(1 if bad else 0)


## The negative control: the unbroken sources pass, then each break must fail its check.
func _negative() -> bool:
	var dirSrc: String = FileAccess.get_file_as_string(DIR_GD)
	var callers: Dictionary = _callers()
	if not (_calls(dirSrc) and _uses(dirSrc, callers)):
		print("FAIL: the unbroken sources do not pass, so the breaks prove nothing")
		return false
	var caught: int = 0
	print("-- break 1: SimDir.flightHook calls DirLaunch.flightHookGone")
	if not _calls(dirSrc.replace("_d(\"launch.gd\").flightHook(", "_d(\"launch.gd\").flightHookGone(")):
		caught += 1
	print("-- break 2: SimDir defines no propBroke (WorldContact._smashProp calls it)")
	if not _uses(dirSrc.replace("static func propBroke(", "static func propBrokeGone("), callers):
		caught += 1
	print("-- break 3: WorldContact.hookOf calls DirLaunch.flightHook by SimDir._d")
	var c3: Dictionary = callers.duplicate()
	c3[CONTACT] = String(c3[CONTACT]).replace("SimDir.flightHook(S, f)", "SimDir._d(\"launch.gd\").flightHook(S, f)")
	if not _uses(dirSrc, c3):
		caught += 1
	print("%s  negative control: %d of 3 breaks caught" % ["PASS" if caught == 3 else "FAIL", caught])
	return caught == 3


## Every `_d("file").name(` in SimDir's source names a function of that director script that takes that many arguments.
func _calls(src: String) -> bool:
	var re := RegEx.new()
	re.compile("_d\\(\"([\\w.]+)\"\\)\\.(\\w+)\\(([^)]*)\\)")
	var ok: bool = true
	var n: int = 0
	for m in re.search_all(src):
		var s = load("res://sim/director/" + m.get_string(1))
		var argc: int = 0 if m.get_string(3).strip_edges() == "" else m.get_string(3).split(",").size()
		var found: bool = false
		if s != null:
			for f in s.get_script_method_list():
				if f.name == m.get_string(2):
					var na: int = f.args.size()
					var nd: int = f.default_args.size()
					found = argc <= na and argc >= na - nd and (f.flags & METHOD_FLAG_STATIC) != 0
		n += 1
		if not found:
			print("FAIL: SimDir calls %s in %s with %d arguments, which is not a static function of it that takes them" % [m.get_string(2), m.get_string(1), argc])
			ok = false
	print("SimDir's calls: %d, %s" % [n, "all found" if ok else "not all found"])
	return ok and n > 0


## Every `SimDir.name(` in the callers' code is a static function SimDir defines, and none is `SimDir._d(`: a call from
## the core or the world into the director is a named forward, so _calls checks it.
func _uses(dirSrc: String, callers: Dictionary) -> bool:
	var defs: Dictionary = {}
	var rd := RegEx.new()
	rd.compile("(?m)^static func (\\w+)\\(")
	for m in rd.search_all(dirSrc):
		defs[m.get_string(1)] = true
	var re := RegEx.new()
	re.compile("SimDir\\.(\\w+)\\(")
	var ok: bool = true
	var used: Dictionary = {}
	for p in callers:
		for m in re.search_all(_code(String(callers[p]))):
			var nm: String = m.get_string(1)
			if nm == "_d":
				print("FAIL: %s calls the director by SimDir._d: give the call a named forward in %s" % [p, DIR_GD])
				ok = false
			elif not defs.has(nm):
				print("FAIL: %s calls SimDir.%s, which %s does not define" % [p, nm, DIR_GD])
				ok = false
			else:
				used[nm] = true
	var names: Array = used.keys()
	names.sort()
	print("SimDir's forwards the core and the world call: %d (%s), %s" % [names.size(), ", ".join(PackedStringArray(names)), "all defined" if ok else "not all defined"])
	return ok and names.size() > 0


## The core's, the world's and the input's scripts other than SimDir's own: path to source.
func _callers() -> Dictionary:
	var out: Dictionary = {}
	for d in ["res://sim/core/", "res://sim/world/", "res://sim/input/"]:
		for p in _scripts(d):
			if p != DIR_GD:
				out[p] = FileAccess.get_file_as_string(p)
	return out


## A script's lines that name SimDir, without their comments and string literals (a forward named in a comment is no call).
func _code(src: String) -> String:
	var out := PackedStringArray()
	for line in src.split("\n"):
		if line.find("SimDir.") < 0:
			continue
		var s: String = ""
		var q: String = ""
		for i in range(line.length()):
			var c: String = line[i]
			if q != "":
				if c == q:
					q = ""
			elif c == "\"" or c == "'":
				q = c
			elif c == "#":
				break
			else:
				s += c
		out.append(s)
	return "\n".join(out)


## The .gd scripts under a folder, not its tools/ and test/ (which the game never loads).
func _scripts(root: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(root)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(root + f)
	for sub in d.get_directories():
		if sub != "tools" and sub != "test":
			out.append_array(_scripts(root + sub + "/"))
	return out


func _cached(paths: Array) -> int:
	var n: int = 0
	for p in paths:
		if ResourceLoader.has_cached(p):
			n += 1
	return n
