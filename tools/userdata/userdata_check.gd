extends SceneTree
## A run from the project (this one) must keep its data away from the player's folder (Tools, 2026-11-28; tools/userdata-guard-check.mjs holds the lines in project.godot).
##   godot --headless --path . --script res://tools/userdata/userdata_check.gd

const DEV := "Orb Combat EX dev"


func _init() -> void:
	var dir: String = OS.get_user_data_dir()
	var ok: bool = OS.has_feature("editor") and dir.get_file() == DEV
	if ok:
		print("userdata_check PASSED: a run from the project keeps its data in \"%s\"" % DEV)
	else:
		print("userdata_check FAILED: a run from the project must use \"%s\", not \"%s\"" % [DEV, dir.get_file()])
	print("USERDATA CHECK: %d check(s) failed" % (0 if ok else 1))   # the verdict line tools/gate.mjs --verdict reads
	quit(0 if ok else 1)
