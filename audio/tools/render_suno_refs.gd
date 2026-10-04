extends SceneTree
## Render the Suno reference clips (docs/audio/suno-direction.md): the town-band hook as a speed-metal riff at the tempos in
## data/metal_ref.json. From the repo root:
##   godot --headless --path . --script res://audio/tools/render_suno_refs.gd [-- --out=DIR]
## DIR defaults to audio/preview/suno-reference. Mono 16-bit at 22.05 kHz. Prints each clip's length and the level of each bar.

func _init() -> void:
	var out_dir: String = ProjectSettings.globalize_path("res://audio/preview/suno-reference")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var spec: Dictionary = AudioBank.load_json("res://audio/data/metal_ref.json")
	var rate: int = int(spec.rate)
	for bpm in spec.tempos:
		var t0: int = Time.get_ticks_usec()
		var buf: PackedFloat32Array = MetalSketch.render(spec, float(bpm))
		var ms: float = (Time.get_ticks_usec() - t0) / 1000.0
		var path: String = "%s/suno-ref-riff-%dbpm-E.wav" % [out_dir, int(bpm)]
		if AudioDsp.to_wav(buf, rate).save_to_wav(path) != OK:
			push_error("write failed: " + path)
			quit(1)
			return
		var bar_n: int = int(240.0 / float(bpm) * float(rate))
		var row: PackedStringArray = []
		for b in range(spec.bars.size()):
			var seg: PackedFloat32Array = buf.slice(b * bar_n, mini((b + 1) * bar_n, buf.size()))
			row.append("%5.1f" % (20.0 * log(maxf(AudioDsp.rms(seg), 1e-9)) / log(10.0)))
		print("%d BPM: %.2f s, peak %.1f dB, %.0f ms to render" % [int(bpm), float(buf.size()) / rate, 20.0 * log(AudioDsp.peak(buf)) / log(10.0), ms])
		print("   RMS dB per bar: " + " ".join(row))
	quit(0)
