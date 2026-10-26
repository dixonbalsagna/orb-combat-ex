extends SceneTree
## The campaign's determinism check (docs/architecture/campaign-core.md section 6): a seeded episode played across its
## five columns twice, headless, with the campaign switched on for the run. Prints each column's places, the place
## flown to, the stage's gameplay hash and the run state's hash, and exits 1 unless both plays are the same to the bit.
##   godot --headless --path . --script res://sim/core/tools/campaign_episode.gd -- [arc id, 16 hex] [kind] [--ticks=1800]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var arcId: String = args[0] if args.size() > 0 and not args[0].begins_with("--") else "c0ffee00c0ffee00"
	var kind: String = args[1] if args.size() > 1 and not args[1].begins_with("--") else "filler_arc"
	var ticks: int = 1800
	for a in args:
		if a.begins_with("--ticks="):
			ticks = int(a.substr(8))
	var t0: int = Time.get_ticks_msec()
	var a1: Dictionary = SimCampaignRun.play(arcId, kind, ticks, {"number": 12})
	var t1: int = Time.get_ticks_msec()
	var a2: Dictionary = SimCampaignRun.play(arcId, kind, ticks, {"number": 12})
	var t2: int = Time.get_ticks_msec()
	var arc: Dictionary = a1.arc
	print("arc %s (%s): villain %s, families %s, planet %d, episode seed %d; card '%s'" % [arcId, kind, arc.villain, str(arc.families), SimCampaign.arcPlanet(arcId), SimCampaign.episodeSeed(arcId, 0), SimCampaign.cardNumber(arc)])
	for st in a1.stages:
		print("  column %d: places %s, flown to %d; stage %s; run state %s" % [st.column, str(st.offered), st.place, str(st.stage).substr(0, 16), st.run])
	print("  done %s; side story %s; season after: %s" % [str(arc.done), str(arc.side), str(SimCampaign.seasonAfter(SimCampaign.newSeason(), a1.state))])
	var same: bool = JSON.stringify(a1.stages) == JSON.stringify(a2.stages) and a1.run == a2.run and JSON.stringify(a1.arc) == JSON.stringify(a2.arc)
	print("campaign_episode: %s (%d ticks a stage; %.1f s and %.1f s)" % ["the two plays are the same to the bit" if same else "FAILED: the two plays differ", ticks, (t1 - t0) / 1000.0, (t2 - t1) / 1000.0])
	quit(0 if same else 1)
