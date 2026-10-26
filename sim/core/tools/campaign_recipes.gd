class_name SimCampaignRun
extends RefCounted
## A seeded campaign episode played headless (docs/architecture/campaign-core.md section 6). At each of the five
## columns:
##   - World's column job is stepped a ring a call, as a host steps it over the beats;
##   - a site is chosen from the column's (the test's flight: a seeded choice);
##   - its stage is played as an AI match on the ring the pair fly, re-centred on the site, with the run's wear laid on it;
##   - the stage's end is read from the match (its wear by World's wearOf), and the route advances.
## With the same arc it gives the same columns, sites, matches, wear and run states, to the bit
## (sim/core/tools/campaign_episode.gd plays it twice; parity's "the campaign's arc and episode" with short stages).
## The stage is scored won (the test walks the whole route).


## Plays episode 0 of arc arcId of the given kind, each stage `ticks` long. opts: number (a main-story episode's).
static func play(arcId: String, kind: String, ticks: int, opts: Dictionary = {}) -> Dictionary:
	var was: bool = SimCampaign.enabled()
	SimCampaign.on_ = true   # the test turns the campaign on for its run, as the host would (the one switch)
	var arc: Dictionary = SimCampaign.newArc(arcId, kind, opts)
	var ld: SimPlanetLoad.Job = SimCampaign.beginLoad(arcId)   # the arc's planet first, a slice a step, as the host loads it while the pair are picked
	while not ld.step(SimRun.planetUnitsPerRead):
		pass
	var P: WorldPlanet.Planet = WorldPlanet.make(SimCampaign.arcPlanet(arcId))
	var s: Dictionary = SimCampaign.newEpisode(arc, 0, P, {"people": 100000})
	var es: int = SimCampaign.episodeSeed(arcId, 0)
	var stages: Array = []
	for c in range(SimCampaign.columns):
		var job: WorldCampaign.ColumnJob = SimCampaign.beginColumn(s, P)
		var calls: int = 1
		while not job.step(1):
			calls += 1
		s = SimCampaign.columnDone(s, job.result)
		var sites: Array = s.arc.columns[c]
		if sites.is_empty():
			stages.append({"column": c + 1, "sites": [], "error": "World offered no site: %s" % str(job.result.get("notes", []))})
			break
		var site: Dictionary = sites[SimCampaign.mix(es, "choose", c, 0) % sites.size()]
		var opp: String = String(s.arc.villain) if String(s.arc.villain) != "" else "RIVAL"
		var su: Dictionary = SimCampaign.stageSetup(s, site, [String(s.player.fighter), opp], P)
		var rl: SimPlanetLoad.Job = SimPlanetLoad.beginFor(su)   # the stage's ring, read over the flight to the site as the host reads it
		while not rl.step(SimRun.planetUnitsPerRead):
			pass
		var S := SimCore.createSim()
		SimCore.newMatch(S, SimRun.stageSeed(String(s.run), c + 1, 0), {}, su)
		var cols: int = S.arenaCols
		for t in range(ticks):
			SimCore.step(S)
		var h: String = SimHash.stateHash(S).gameplay
		var end: Dictionary = endOf(S, int(site.id), opp, su.arena)
		SimCore.dispose(S)
		s = SimCampaign.advance(s, end, P)
		stages.append({"column": c + 1, "calls": calls, "turn": s.arc.turns[c], "cols": cols, "sites": sites, "site": int(site.id), "place": int(site.place),
			"stageWear": end.wear, "stage": h, "run": SimRun.stateHash(s)})
	SimCampaign.on_ = was
	return {"arc": s.arc, "run": SimRun.stateHash(s), "stages": stages, "state": s, "campaign": SimCampaign.qaRecord(s)}


## The stage's end from a match's final state: the place state (World's wearOf: bands from fallen buildings, never
## people), the player's wounds, and the site fought at.
static func endOf(S: SimState, site: int, opp: String, arena: Dictionary) -> Dictionary:
	var f0 = S.fighters[0]
	var w: Array = []
	for r in range(4):
		w.append(int(f0.stage[r]))
	return {"result": "won", "opponent": opp, "villain": String(FighterData.def(opp).get("role", "")) == "villain", "offer": "", "ticks": int(S.tick), "how": "test",
		"site": site, "arena": arena, "wear": WorldCampaign.wearOf(S), "wounds": w, "fills": {"witness": 0, "trial": 0}, "branches": [], "ash": 0, "places": {}}
