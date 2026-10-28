extends SceneTree
## The sim's script loads, in the order Rendering's boot entry makes them (docs/architecture/load-split.md). In a fresh
## process each step's load() compiles its script graph less what the steps before it loaded. This prints each step's
## time and how many of the director's scripts are loaded after it, and fails if the first step (the core and the
## world) loads any of them: a director class named in a script the core's graph reaches pulls the whole director back
## into that load. It also checks that every director function SimDir (sim/core/dir.gd) calls is in its script, since
## those calls are found by name only when they run. This script names no sim class, so it compiles nothing itself.
##   godot --headless --path . --script res://sim/core/tools/load_split.gd [-- --steps=res://a.gd,res://b.gd]

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


func _init() -> void:
	var steps: Array = STEPS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--steps="):
			steps = Array(a.substr(8).split(","))
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
	if not _calls():
		bad = true
	print("FAIL" if bad else "ok: the director is a load of its own, and SimDir's calls are all in their scripts")
	quit(1 if bad else 0)


## Every `_d("file").name(` in SimDir's source names a function of that director script that takes that many arguments.
func _calls() -> bool:
	var src: String = FileAccess.get_file_as_string("res://sim/core/dir.gd")
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
