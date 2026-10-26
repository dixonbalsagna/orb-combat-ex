extends SceneTree
## The host's planet load (docs/ui/planet-load.md), headless: with SimPlanetLoad.strict on (the game's main sets it; a tool leaves it off), SimHost.new_match for a setup whose gen 2 planet is not made
## waits and the host loads it a slice a frame (load_step), reading load_phase and load_progress for the screen; then the match starts exactly as new_match would have started it.
## A gen 1 match, a setup with no planet and a planet already made start at once. Run from the repo root (import once first):
##   godot --headless --path . --script res://ui/tools/load_check.gd
## Exits 0 when every check passes.

var fails: int = 0
var checks: int = 0


func _ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("FAIL  ", what)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var was: bool = SimPlanetLoad.strict
	var refused0: int = SimPlanetLoad.refused
	SimPlanetLoad.strict = true
	var host := SimHost.new()

	# Nothing to wait for: no planet, a gen 1 planet.
	host.new_match(5, {"p1": true, "p2": true}, {"intro": false})
	_ok(not host.loading() and host.S.game != null, "no planet: the match starts at once")
	host.new_match(6, {"p1": true, "p2": true}, {"intro": false, "planet": 6, "planetGen": 1})
	_ok(not host.loading() and host.S.planetGen == 1, "a gen 1 planet: the match starts at once, no screen")

	# A cold gen 2 planet: the match waits.
	var seed: int = 31337
	var setup := {"intro": false, "planet": seed, "planetGen": 2, "arena": {"cols": 2400}}
	var h_before = SimHash.stateHash(host.S).gameplay
	host.new_match(seed, {"p1": true, "p2": true}, setup)
	_ok(host.loading(), "a cold gen 2 planet: new_match waits for it")
	_ok(SimHash.stateHash(host.S).gameplay == h_before, "waiting: the sim is not touched (the last match is as it was)")
	_ok(host.load_phase() in UiLoading.PHASES and host.load_progress() >= 0.0 and host.load_progress() < 1.0, "waiting: a phase the screen has words for (%s) and progress under 1" % host.load_phase())
	var seen: Array = []
	var last: float = -1.0
	var mono := true
	var frames := 0
	var started := false
	while frames < 6000:
		var ph: String = host.load_phase()
		if seen.is_empty() or seen[-1] != ph:
			seen.append(ph)
		var pg: float = host.load_progress()
		mono = mono and pg >= last
		last = pg
		if host.load_step():
			started = true
			break
		frames += 1
	_ok(started and not host.loading(), "the load finishes in %d frames and the match starts" % frames)
	_ok(mono, "progress never goes back")
	var order: Array = UiLoading.PHASES
	var ordered := true
	var at := -1
	for ph in seen:
		var i: int = order.find(ph)
		ordered = ordered and i >= at and i >= 0
		at = i
	_ok(ordered, "the phases come in order (%s)" % str(seen))
	_ok(host.S.planetGen == 2 and SimPlanetLoad.refused == refused0, "the match plays on the gen 2 planet and the sim refused nothing")
	_ok(host.load_phase() == "done" and host.load_progress() == 1.0, "no load: done, 1")
	_ok(SimPlanetLoad.strict, "the host puts strict back as it was after the start")

	# The same match, started as a tool starts it (strict off), is the same match.
	var h_host = SimHash.stateHash(host.S).gameplay
	SimPlanetLoad.strict = false
	var tool_host := SimHost.new()
	tool_host.new_match(seed, {"p1": true, "p2": true}, setup)
	_ok(not tool_host.loading() and SimHash.stateHash(tool_host.S).gameplay == h_host, "the same setup started with strict off (a tool's way) is the same match at its first tick")
	for i in range(120):
		host.tick(1280.0, 720.0)
		tool_host.tick(1280.0, 720.0)
	_ok(SimHash.stateHash(host.S).gameplay == SimHash.stateHash(tool_host.S).gameplay, "and the same 120 ticks later")

	# The planet made ahead, while the player chooses (prefetch): the same choice keeps the work, another starts over, the match takes up what is left, a finished one is not waited for.
	SimPlanetLoad.strict = true
	var cold := {"intro": false, "planet": 4242, "planetGen": 2, "arena": {"cols": 2400}}
	var pre := SimHost.new()
	pre.prefetch(cold)
	var first: SimPlanetLoad.Job = pre.pre_job
	_ok(first != null and SimHost.planet_key(cold) != "", "prefetch: a cold gen 2 planet starts making ahead")
	for i in range(8):
		pre.prefetch_step()
	var part: float = pre.pre_job.progress() if pre.pre_job != null else 1.0
	pre.prefetch(cold)
	_ok(pre.pre_job == first and part > 0.0, "prefetch: the same choice again leaves the work as it is (%.2f made)" % part)
	var other := {"intro": false, "planet": 4243, "planetGen": 2, "arena": {"cols": 2400}}
	pre.prefetch(other)
	_ok(pre.pre_job != null and pre.pre_job != first and pre.pre_job.seed == 4243, "prefetch: another planet starts over")
	pre.prefetch(cold)
	_ok(pre.pre_job != null and pre.pre_job.seed == 4242 and pre.pre_job != first, "prefetch: and back to the first starts over again")
	for i in range(6):
		pre.prefetch_step()
	var carried: float = pre.pre_job.progress()
	var taken: SimPlanetLoad.Job = pre.pre_job
	pre.new_match(4242, {"p1": true, "p2": true}, cold)
	_ok(pre.loading() and pre.load_job == taken and pre.pre_job == null and pre.load_progress() >= carried, "prefetch: Start takes up what is left of the work (%.2f already made), not a second load" % carried)
	var done_in := 0
	while not pre.load_step() and done_in < 6000:
		done_in += 1
	_ok(not pre.loading() and pre.S.planetGen == 2, "prefetch: the load finishes and the match starts")
	var fin := {"intro": false, "planet": 4244, "planetGen": 2, "arena": {"cols": 2400}}
	pre.prefetch(fin)
	var spun := 0
	while pre.pre_job != null and spun < 6000:
		pre.prefetch_step()
		spun += 1
	pre.prefetch(fin)
	_ok(pre.pre_job == null, "prefetch: a planet made ahead is not started again for the same choice")
	pre.new_match(4244, {"p1": true, "p2": true}, fin)
	_ok(not pre.loading(), "prefetch: made before Start means no screen at all")
	var base := {"intro": false, "planet": 4245, "planetGen": 2, "arena": {"cols": 2400}}
	pre.prefetch(base)
	pre.prefetch_step()
	pre.prefetch({})
	_ok(pre.pre_job == null, "prefetch: no planet in the choices drops the work")
	pre.prefetch(base)
	pre.new_match(4245, {"p1": true, "p2": true}, base)
	_ok(pre.loading(), "back: a load is under way")
	pre.cancel_load()
	_ok(not pre.loading() and pre.pre_job == null and pre.load_phase() == "done", "back: cancelled, nothing is kept (no load, no work ahead)")
	pre.prefetch(base)
	_ok(pre.pre_job != null, "back: and the same choice made again starts the work afresh")
	pre.cancel_load()
	SimPlanetLoad.strict = false
	var tool_pre := SimHost.new()
	tool_pre.prefetch({"intro": false, "planet": 4246, "planetGen": 2, "arena": {"cols": 2400}})
	_ok(tool_pre.pre_job == null, "a tool (strict off) never prefetches")
	SimPlanetLoad.strict = true
	var gen1 := SimHost.new()
	gen1.prefetch({"intro": false, "planet": 4247, "planetGen": 1})
	_ok(gen1.pre_job == null, "a gen 1 planet is not made ahead (nothing to wait for)")

	# Made already: a rematch on the same planet does not wait.
	SimPlanetLoad.strict = true
	host.new_match(seed, {"p1": true, "p2": true}, setup)
	_ok(not host.loading(), "a planet already made: no screen")

	SimPlanetLoad.strict = was
	print("load_check: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)
