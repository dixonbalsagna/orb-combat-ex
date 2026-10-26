extends SceneTree
## The campaign's determinism check (docs/architecture/campaign-core.md section 7): a seeded episode played across its
## five columns twice, headless, with the campaign switched on for the run (World's columns, the ring and its turns,
## the wear laid on each stage). Prints each column's sites, the site flown to, the stage's gameplay hash and the run
## state's hash, and QA's campaign record (docs/qa/rally-campaign-rows.md; --record=<file> writes it as {"campaign": ...}),
## and exits 1 unless both plays are the same to the bit.
##   godot --headless --path . --script res://sim/core/tools/campaign_episode.gd -- [arc id, 16 hex] [kind] [--ticks=1800] [--record=<file>]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var arcId: String = args[0] if args.size() > 0 and not args[0].begins_with("--") else "c0ffee00c0ffee00"
	var kind: String = args[1] if args.size() > 1 and not args[1].begins_with("--") else "filler_arc"
	var ticks: int = 1800
	var recordTo: String = ""
	for a in args:
		if a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--record="):
			recordTo = a.substr(9)
	var t0: int = Time.get_ticks_msec()
	var a1: Dictionary = SimCampaignRun.play(arcId, kind, ticks, {"number": 12})
	var t1: int = Time.get_ticks_msec()
	var a2: Dictionary = SimCampaignRun.play(arcId, kind, ticks, {"number": 12})
	var t2: int = Time.get_ticks_msec()
	var arc: Dictionary = a1.arc
	print("arc %s (%s): villain %s, families %s, planet %d, episode seed %d; card '%s'" % [arcId, kind, arc.villain, str(arc.families), SimCampaign.arcPlanet(arcId), SimCampaign.episodeSeed(arcId, 0), SimCampaign.cardNumber(arc)])
	for st in a1.stages:
		if st.has("error"):
			print("  column %d: %s" % [st.column, st.error])
			continue
		var ss: PackedStringArray = []
		for x in st.sites:
			ss.append("%d:%s%s@%+d" % [x.id, x.kind, "" if int(x.place) < 0 else "#" + str(x.place), x.arc])
		print("  column %d (%d calls, turn %d, a %d-column ring): sites %s; flown to %d; its wear %s; stage %s; run %s" % [st.column, st.calls, st.turn, st.cols, ", ".join(ss), st.site, str(st.stageWear), str(st.stage).substr(0, 16), st.run])
	print("  done %s; wear %s; used %s; side story %s; season after: %s" % [str(arc.done), str(arc.wear), str(arc.used), str(arc.side.offered) + " " + str(arc.side.place) + " " + String(arc.side.how) + " " + str(arc.side.turn), str(SimCampaign.seasonAfter(SimCampaign.newSeason(), a1.state))])
	print("  QA's record: %s" % JSON.stringify(a1.campaign, "", false))
	if recordTo != "":
		var f := FileAccess.open(recordTo, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify({"campaign": a1.campaign}, "", false) + "\n")
			f.close()
	var same: bool = JSON.stringify(a1.stages) == JSON.stringify(a2.stages) and a1.run == a2.run and JSON.stringify(a1.arc) == JSON.stringify(a2.arc) and JSON.stringify(a1.campaign) == JSON.stringify(a2.campaign)
	var whole: bool = a1.arc.done and a1.stages.size() == SimCampaign.columns
	print("campaign_episode: %s (%d ticks a stage; %.1f s and %.1f s)" % [("the two plays are the same to the bit" if whole else "FAILED: the episode stopped short") if same else "FAILED: the two plays differ", ticks, (t1 - t0) / 1000.0, (t2 - t1) / 1000.0])
	quit(0 if same and whole else 1)
