class_name WorldPin
extends RefCounted
## Tests only (GW1a, A1): pins World's data in memory to the values main shipped before the golden window "Main is the game" (GW1a), so a check written for the old defaults keeps testing the old path while the data
## plays the new ones. The values are the 9 November build's differences from the old main (docs/world/world-default.md): climate.json gen 1, water v2 off (enabled, surface, floor, flowWarm 0), contact settle off,
## field plans everywhere off, the arena's calm turn off (rings.json turn.on 0, interrupts calmTurn and water off), and the energy model and the dash off (power.json). A check that tests the new default does not
## call it; one that tests the old path calls it first. It changes this process's memory only, never a file.
##   WorldPin.shipped()


static var _on0 = null     # the model's and the dash's switches as the data has them, kept at the first call (a check that runs both ways calls shipped twice)
static var _dash0 = null


## power false: the energy model and the dash off, as main shipped them before GW1a. power true: they stay as the data has them (Orb's real path); a check that runs a body both ways calls shipped(false) then shipped(true).
static func shipped(power: bool = false) -> void:
	# each module's data is loaded first (a module that loads on its first call would write the file's values over these)
	var fw = WorldFill.data().get("flowWarm", null)
	SimPower._ensure()
	if _on0 == null:
		_on0 = SimPower.on_
		_dash0 = SimPower.dashOn_
	WorldClimate.data()["gen"] = 1
	WorldClimate.useGen(0)
	WorldFill.K_ON = false
	WorldFill.K_SURF_ON = false
	WorldFill.K_FLOOR_ON = false
	if fw is Dictionary:
		fw["cols"] = 0
	WorldContact.K_PERTIER = WorldContact.data().bounce.perTier
	WorldContact.K_MAXC = 8
	WorldPlan.everywhereOverride = 0
	var tn = WorldRingPick.cfg().get("turn", null)
	if tn is Dictionary:
		tn["on"] = 0
	var di: Dictionary = DirInterrupt.data()
	if di.get("calmTurn") is Dictionary:
		di["calmTurn"]["enabled"] = false
	if di.get("water") is Dictionary:
		di["water"]["enabled"] = false
	SimPower.on_ = bool(_on0) if power else false
	SimPower.dashOn_ = bool(_dash0) if power else false
	DirLaunch.forceBiome = 0   # the planner does not read the ground (launch_biome.json biome.enabled)


## Tests only (GW1b): the launch's travel as it was before GW1b's energy addendum (data/fight/power.json launchTravel 2.0, now 1.5). A check that stages a send at a tower 3,000 units away was written for it: at 1.5 the aim finds no plan and the check reads no hit at all. Memory only.
static func launchTravelOld() -> void:
	SimPower._ensure()
	SimPower.launchTravel = 2.0


## Tests only (GW1b): a setup that names no planet plays the hand-made arena, as it did before the default world moved to the round planet (data/biomes/world.json mode). For a check that tests the arena or a default world.
static func arena() -> void:
	WorldDefault.setForTest("arena", false)
