extends SceneTree
# prints one line per sound: id#variant sha256-of-the-buffer-bytes (sync API); args: --out=FILE
func _initialize() -> void:
	var out_path: String = ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_path = a.substr(6)
	if out_path == "":
		push_error("warm_hashes: no output file; run with -- --out=FILE")
		quit(1)
		return
	var bank := AudioBank.new()
	bank.world["enabled"] = true
	var ids: Array = []
	ids.append_array(bank.ids())
	ids.append_array(bank.extra_ids())
	for k in bank.world.get("beds", {}):
		ids.append("amb." + k)
	for k in bank.drones:
		var did: String = "drone." + String(k)
		if not ids.has(did):
			ids.append(did)
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		push_error("warm_hashes: cannot open %s" % out_path)
		quit(1)
		return
	for id in ids:
		for v in range(bank.variants(id)):
			var b: PackedFloat32Array = bank.buffer(id, v)
			f.store_line("%s#%d %s %d" % [id, v, b.to_byte_array().hex_encode().sha256_text().substr(0, 16), b.size()])
	f.close()
	quit(0)
