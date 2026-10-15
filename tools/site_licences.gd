extends SceneTree
## Writes the engine's own licence and copyright text (Engine.get_license_text, get_license_info, get_copyright_info) as JSON, for the site's About page (tools/site-interim.mjs).
## The text is what the exporting engine itself carries, so it is the licence of the build that ships: run it again when the engine version changes.
##   godot --headless --path . --script res://tools/site_licences.gd -- --out=tools/site-licences.json
func _initialize() -> void:
	var out_path: String = "tools/site-licences.json"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_path = a.substr(6)
	var data: Dictionary = {
		"_about": "The licence and copyright text of the Godot engine the build ships with (written by tools/site_licences.gd from Engine.get_license_text, get_license_info and get_copyright_info). Not edited by hand.",
		"godot_version": str(Engine.get_version_info().get("string", "")),
		"license_text": Engine.get_license_text(),
		"licenses": Engine.get_license_info(),
		"copyright": Engine.get_copyright_info(),
	}
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		push_error("cannot write " + out_path)
		quit(1)
		return
	f.store_string(JSON.stringify(data, "  ") + "\n")
	f.close()
	print("written ", out_path, ": ", data["licenses"].size(), " licences, ", data["copyright"].size(), " components")
	quit()
