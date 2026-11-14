extends SceneTree
## The data hash a tree reads (A-AI-04, EP brief 2026-11-13): prints SimReplay.dataHash for a setup, so a saved reading names the packed data it ran on. With a black box file as the argument, the setup is the file's own and the line also
## says whether the hash equals the file's `data`, which shows the tree is the build's.
##   godot --headless --path <tree> --script res://qa/godot/data_hash.gd -- [<file.json>]
## Prints one line: DATAHASH <hash> [file <hash>, match|DIFFERENT]. Read-only.
func _init() -> void:
	SimInputData.load_and_apply()
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var setup: Dictionary = {}
	var file_hash: String = ""
	if args.size() > 0 and FileAccess.file_exists(args[0]):
		var rp = JSON.parse_string(FileAccess.open(args[0], FileAccess.READ).get_as_text())
		if rp.has("replay"):
			rp = rp.replay
		setup = rp.get("setup", {})
		file_hash = str(rp.get("data", ""))
	var h: String = str(SimReplay.dataHash(setup))
	print("DATAHASH %s%s" % [h, (" file %s %s" % [file_hash, "match" if file_hash == h else "DIFFERENT"]) if file_hash != "" else ""])
	quit()
