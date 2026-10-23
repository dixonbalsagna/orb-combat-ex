extends Node
## Web parity probe (docs/architecture/web-parity.md; run by sim/core/tools/web_parity.mjs, which makes this scene a
## copy's main scene): SimGolden.build()'s keys, computed one a frame in build()'s order (so the statics a key leaves
## behind are the ones the next met natively), then extras for what ships switched off (keys "x.": every fight switch
## on, the calm turn, the run's stage rings). On the web each result is published as JSON in window.__wp.res[key], and
## window.__wp.i counts the keys done; natively the whole result is written to the path after "--" and the process
## quits. The same script on both sides, so what differs is the platform.

var jobs: Array = []
var out: Dictionary = {}
var i: int = 0
var web: bool = false
var outPath: String = "user://webparity.json"
var only: String = ""


func _ready() -> void:
	web = OS.has_feature("web")
	var a: PackedStringArray = OS.get_cmdline_user_args()
	if a.size() > 0:
		outPath = a[0]
	if a.size() > 1:
		only = a[1]   # natively: one key's prefix only (a quick control)
	_add("godot", func(): return Engine.get_version_info().string)
	_add("constants", func(): return SimGolden.constants())
	for s in SimGolden.STREAM_SEEDS:
		_add("streamSeeds." + str(s), func(): return SimGolden.streamSeeds(s))
	for s in SimGolden.RNG_SEEDS:
		_add("rng." + str(s), func(): return SimGolden.rngHash(s))
	_add("wrap", func(): return SimGolden.wrapHash())
	_add("sincos", func(): return SimGolden.sincosHash())
	_add("powexplog", func(): return SimGolden.powHash())
	for s in SimGolden.TICK0_SEEDS:
		_add("tick0." + str(s), func(): return SimGolden.tick0Hash(s))
	_add("tick0Values", func(): return SimGolden.tick0Values(1))
	_add("rally", func(): return SimGolden.rallyHash())
	_add("cripple", func(): return SimGolden.crippleHash())
	_add("mood", func(): return SimGolden.moodHash())
	_add("fightHash", func(): return SimMood.dataHash() + SimPause.dataHash() + SimIntro.dataHash() + SimShots.dataHash())
	_add("intro", func(): return SimGolden.introHash())
	_add("introComposed", func(): return SimGolden.introComposedHash())
	_add("wounds", func(): return SimGolden.woundsHash())
	_add("rosterHash", func(): return FighterData.dataHash())
	_add("keyed", func(): return SimGolden.keyedHash())
	for k in range(SimGolden.MATCHES.size()):
		var m: Array = SimGolden.MATCHES[k]
		_add("matches." + str(k), func(): return SimGolden.goldenRun(m[0], m[1], null, m[2] if m.size() > 2 else SimGolden.CAP))
	var rps: Array = [[11, 3000, false, [1500, 2100]], [12, 2400, true, []]]
	for k in range(rps.size()):
		var p: Array = rps[k]
		_add("replays." + str(k), func(): return _replay(p))
	_add("planet", func(): return SimGolden.planetGolden())
	# extras, after the golden's keys (so those run as build() runs them): what ships switched off today
	var on: Dictionary = {"depth": true, "brake": true, "forms": true, "flight": true, "hitstop": true, "ricochet": true}
	for sd in [3, 5]:
		_add("x.switches." + str(sd), func(): return SimGolden.goldenRun("default", sd, null, 6000, on.duplicate(true)))
	_add("x.calmTurn", func(): return SimGolden.goldenRun("default", 1, null, 6000, {"planet": 7, "touch": 3, "arena": {"cols": 2400, "turn": true}}))
	for rs in ["00c0ffee0badf00d", "5eed0000decade42", "0123456789abcdef"]:
		_add("x.runGround." + rs, func(): return _runGround(rs))
	if only != "":
		jobs = jobs.filter(func(j): return String(j[0]).begins_with(only))
	if web:
		JavaScriptBridge.eval("window.__wp = {n: %d, i: 0, res: {}, ms: {}, keys: %s};" % [jobs.size(), JSON.stringify(jobs.map(func(j): return j[0]))], true)


## A sample run's grounds (SimRun, on main since 07876704): each stage's setup and a short match on it.
func _runGround(run: String) -> Array:
	var outv: Array = []
	var used: Array = []
	var opps: Array = ["RIVAL", "EMPRESS", "CYBORG", "RIVAL"]
	for k in range(opps.size()):
		var g: SimRun.GroundJob = SimRun.beginGround(run, k + 1, opps[k], {"used": used.duplicate()})
		g.finishNow()
		var su: Dictionary = g.setup()
		used.append(su.arena)
		var r: Dictionary = SimGolden.goldenRun("default", g.matchSeed(), null, 600, su)
		outv.append({"setup": su, "score": SimMathx.bits(float(g.result.score)), "ok": g.result.ok, "light": r.light, "final": r.final})
	return outv


## build()'s replay entry: the scripted replay and its run.
func _replay(p: Array) -> Dictionary:
	var rp: Dictionary = SimGolden.scriptedReplay(p[0], p[1], p[2], p[3])
	return {"replay": rp, "run": SimGolden.goldenRun("default", rp.seed, rp)}


func _add(key: String, f: Callable) -> void:
	jobs.append([key, f])


func _process(_d: float) -> void:
	if i >= jobs.size():
		return
	var j: Array = jobs[i]
	var t0: int = Time.get_ticks_msec()
	var v = j[1].call()
	var ms: int = Time.get_ticks_msec() - t0
	out[j[0]] = v
	i += 1
	if web:
		JavaScriptBridge.eval("window.__wp.res[%s] = %s; window.__wp.ms[%s] = %d; window.__wp.i = %d;" % [JSON.stringify(j[0]), JSON.stringify(JSON.stringify(v, "", false)), JSON.stringify(j[0]), ms, i], true)
	else:
		print("%s %d ms" % [j[0], ms])
		if i >= jobs.size():
			var f := FileAccess.open(outPath, FileAccess.WRITE)
			f.store_string(JSON.stringify(out, "", false))
			f.close()
			print("webparity: %d keys written to %s" % [jobs.size(), outPath])
			get_tree().quit(0)
