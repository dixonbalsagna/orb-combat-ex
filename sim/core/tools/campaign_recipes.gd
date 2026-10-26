class_name SimCampaignRun
extends RefCounted
## A seeded campaign episode played headless (docs/architecture/campaign-core.md section 6): the arc and its first
## episode, and at each of the five columns a place chosen from the column's (the test's flight: a seeded choice),
## its stage played as an AI match on a ring round that place, the stage's end read from the match, and the column
## advanced. With the same arc it gives the same places, matches and run states, to the bit (sim/core/tools/
## campaign_episode.gd plays it twice; parity's "the campaign's arc and episode" with short stages).
## The stage's end is a stand-in for World's extraction (campaign-core.md section 4): the stage is scored won (the test
## walks the whole route), and the place's buildings, people, the fallen and the fled are the match's world's.


## Plays episode 0 of arc arcId of the given kind, each stage `ticks` long. opts: number (a main-story episode's).
static func play(arcId: String, kind: String, ticks: int, opts: Dictionary = {}) -> Dictionary:
	var was: bool = SimCampaign.enabled()
	SimCampaign.on_ = true   # the test turns the campaign on for its run, as the host would
	var arc: Dictionary = SimCampaign.newArc(arcId, kind, opts)
	var P: WorldPlanet.Planet = WorldPlanet.make(SimCampaign.arcPlanet(arcId))
	var s: Dictionary = SimCampaign.newEpisode(arc, 0, P, {"people": 100000})
	var es: int = SimCampaign.episodeSeed(arcId, 0)
	var stages: Array = []
	for c in range(SimCampaign.columns):
		var col: Array = s.arc.columns[c]
		var place: int = int(col[SimCampaign.mix(es, "choose", c, 0) % col.size()])
		var opp: String = String(s.arc.villain) if String(s.arc.villain) != "" else "RIVAL"
		var phi: float = float(SimCampaign.mix(es, "bearing", c, 0)) / 4294967296.0 * SimMathx.TAU
		var su: Dictionary = {"planet": int(s.planet.seed), "arena": WorldRingPick.arenaOf(WorldRingPick.roundSpec(WorldRingPick.placePoint(P, place), SimCampaign.stageCols, phi)),
			"slots": [String(s.player.fighter), opp]}
		var S := SimCore.createSim()
		SimCore.newMatch(S, SimRun.stageSeed(String(s.run), c + 1, 0), {}, su)
		for t in range(ticks):
			SimCore.step(S)
		var h: String = SimHash.stateHash(S).gameplay
		var end: Dictionary = endOf(S, place, opp, su.arena)
		SimCore.dispose(S)
		s = SimCampaign.advance(s, end, P)
		stages.append({"column": c + 1, "offered": col, "place": place, "stage": h, "run": SimRun.stateHash(s)})
	SimCampaign.on_ = was
	return {"arc": s.arc, "run": SimRun.stateHash(s), "stages": stages, "state": s}


## The stage's end from a match's final state: the stand-in for World's extraction (campaign-core.md section 4).
static func endOf(S: SimState, place: int, opp: String, arena: Dictionary) -> Dictionary:
	var f0 = S.fighters[0]
	var down: int = 0
	for b in S.buildings:
		if not b.alive:
			down += 1
	var w: Array = []
	for r in range(4):
		w.append(int(f0.stage[r]))
	return {"result": "won", "opponent": opp, "villain": String(FighterData.def(opp).get("role", "")) == "villain", "offer": "", "ticks": int(S.tick), "how": "test",
		"place": place, "arena": arena, "wounds": w, "fills": {"witness": 0, "trial": 0}, "branches": [], "ash": 0,
		"places": {str(place): {"buildings": S.buildings.size(), "people": int(S.world.pop0), "down": down,
			"dead": {"player": 0, "opponent": 0, "other": int(S.world.casualties)}, "fled": int(S.world.evacuated)}}}
