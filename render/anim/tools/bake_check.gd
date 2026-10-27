extends SceneTree
## The incremental bake (docs/animation/incremental-bake.md): what the match start costs and whether the baked poses are the same. Run once with --eager-bake and once with --lazy-bake and compare the line it prints:
## `godot --headless --path . -s res://render/anim/tools/bake_check.gd -- --lazy-bake`. The hash covers every pose's rotations and hips, in id order, after everything is baked.
func _initialize() -> void:
	var t0: int = Time.get_ticks_usec()
	AnimData.load_all()
	var t1: int = Time.get_ticks_usec()
	AnimData.ensure_fighter("PROTAGONIST")
	AnimData.ensure_fighter("RIVAL")
	var t2: int = Time.get_ticks_usec()
	var rd_first: int = AnimData.read_usec
	var big: Array = AnimData.read_biggest.keys()
	big.sort_custom(func(a, b): return AnimData.read_biggest[a] > AnimData.read_biggest[b])
	print("READS %d files %.1f ms; biggest: %s" % [AnimData.read_n, float(rd_first) / 1000.0, ", ".join(PackedStringArray(big.slice(0, 8).map(func(k): return "%s %.1f" % [k, float(AnimData.read_biggest[k]) / 1000.0])))])
	# the match-start frame: what is asked for at once, then the queue drained a tick at a time
	var first: float = float(t2 - t0) / 1000.0
	var slices: int = 0
	var worst: int = 0
	var left: int = AnimData._pend.size()
	while left > 0:
		var s0: int = Time.get_ticks_usec()
		left = AnimData.bake_pending()
		worst = maxi(worst, Time.get_ticks_usec() - s0)
		slices += 1
	var ids: Array = AnimData.poses.keys()
	ids.sort()
	var h: int = 0
	for id in ids:
		var p: AnimPose = AnimData.poses[id]
		for qq in p.q:
			for v in [qq.x, qq.y, qq.z, qq.w]:
				h = (h * 31 + int(round(v * 100000.0))) & 0x7fffffff
		for v in [p.hips.x, p.hips.y, p.hips.z]:
			h = (h * 31 + int(round(v * 100000.0))) & 0x7fffffff
	print("BAKECHECK lazy=%s hash=%d poses=%d first_frame_ms=%.1f (load_all %.1f, both fighters %.1f) deferred=%d slices=%d worst_slice_ms=%.2f worst_single_ms=%.2f" % [str(AnimData.lazy), h, ids.size(), first, float(t1 - t0) / 1000.0, float(t2 - t1) / 1000.0, AnimData.bake_deferred, slices, float(worst) / 1000.0, float(AnimData.bake_worst_us) / 1000.0])
	quit()
