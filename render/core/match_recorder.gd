class_name MatchRecorder
extends RefCounted
## The match as a replay, on a plain desktop build (register rows A-UI-02 and A-CODE-03, Tools, 2026-11-14). It was the black box of the private page (tools/preview/blackbox.mjs): a few lines of the
## page's scratch copy of sim_host.gd. On a desktop build nothing recorded a solo or a couch match, so the one-press report and "Save this match" had nothing to save.
##
## It only READS what the host already has: the intents the host built for the tick, the seed, the AI flags, the setup, the AI toggles. It keeps them in SimReplay's own format ("meridian-replay", v4: the
## inputs only where a slot's intent changed) and writes nothing to the sim, draws no random number and changes no tick: the sim is stepped by the very same SimCore.step with the very same inputs, and the
## three hooks in SimHost sit beside the lines they read (arm after the setup is kept, before_step before SimCore.step, toggle before toggleAI). No hash is taken while the match runs (the final one is
## taken when the file is saved), so it costs one pass over two or three intents a tick.
##
## save() writes one file for the player's own PC (user://reports/, nothing is sent anywhere): {kind "orb-solo-match", pc, slot, mode, build, reason, savedAt, tick, marks, replay}, the shape of a LAN save
## (net/lan.gd) so the same report tools read it. The replay in it plays back with SimReplay.play, headless, to the last tick (tools/preview/blackbox-verify.mjs reads the file too).

const KIND: String = "orb-solo-match"
const DIR: String = "user://reports"
static var test_dir: String = ""         # a test's own folder (match_recorder_check sets it, nothing in the game does): while it is set a save with no folder goes there and never to the player's DIR or into its prune
const KEEP: int = 20                  # the newest AUTOMATIC files kept in the folder (reports, over, quit): the player's disk is not the game's to fill. A file the player chose to keep (reason save) is never counted and never pruned
const MAX_TICKS: int = 60 * 60 * 30   # half an hour of match: a longer one stops being recorded (its replay is still valid as far as it goes)

var armed: bool = false
var done: bool = false                # the match is over (a KO) or its record is full: nothing more is recorded
var replay: Dictionary = {}
var marks: Array = []                 # [{tick, kind, tag, note, at}], one per report
var _seed: int = 0
var _su: Dictionary = {}
var _last: Array = []                 # the last packed intent per slot (-1 for none), as SimReplay keeps it
var _last2: Array = []                # the last second word per slot; always 0 with switches.rightStick off


## A match starts (SimHost.start_match, after it keeps the setup): a match left before its end is dropped, the new one starts its own record.
func arm(seed_: int, _ai: Dictionary, su_: Dictionary) -> void:
	_seed = seed_
	_su = su_.duplicate(true)
	armed = true
	done = false
	replay = {}
	marks = []


## The record's header, from the state the match was started in (read before any toggle of this match, as SimReplay.recorder does).
func _begin(S: SimState) -> void:
	if S.stage != null:   # a match of two fights (four bodies): this recorder keeps the first two only, so it records nothing and a save answers "" (the EP's note, 2026-11-14; a LAN save records every confirmed input)
		armed = false
		return
	var ai: Dictionary = {}
	for k in range(S.fighters.size()):
		ai["p%d" % (k + 1)] = S.fighters[k].ai != null
	# The header is SimReplay.header's, the one every replay writer uses (A-NET-05, B1: the recorder, the LAN save, the black box and this hook cannot drift): format, versions, the setup's data hash, seed, setup,
	# AI flags, and the build that made it when this build is stamped. Asked by name so this file compiles and plays before AND after Simulation's replay-build park lands, whichever lands first.
	var sr := SimReplay.new()
	if sr.has_method("header"):
		replay = sr.call("header", _seed, _su, ai)
	else:
		replay = {"format": SimReplay.FORMAT, "v": SimReplay.V, "intent": SimIntent.VERSION, "data": SimReplay.dataHash(_su), "seed": _seed, "setup": _su.duplicate(true), "ai": ai,
			"ticks": 0, "inputs": [], "toggles": [], "checkpoints": [], "final": ""}
		# a tree with buildId and no header (the first cut of replay-build) still names its build, as its recorder does; a tree with neither writes no field, exactly as before
		if sr.has_method("buildId"):
			var bid: String = str(sr.call("buildId"))
			if bid != "":
				replay["build"] = bid
	_last = []
	_last2 = []
	for _k in range(S.fighters.size()):
		_last.append(-1)
		_last2.append(0)


## An AI toggle (SimHost.toggle_ai), before it is made.
func toggle(S: SimState, idx: int) -> void:
	if not armed or done:
		return
	if replay.is_empty():
		_begin(S)
		if not armed:   # a match of two fights is not recorded (_begin said so): nothing was started, so there is no header to read below
			return
	replay.toggles.append([int(replay.ticks), idx])


## The tick's intents, just before SimCore.step(S, inputs). Read only.
func before_step(S: SimState, inputs: Array) -> void:
	if not armed or done:
		return
	if replay.is_empty():
		_begin(S)
		if not armed:   # a match of two fights is not recorded (_begin said so): nothing was started, so there is no header to read below
			return
	if S.game.ko != null or int(replay.ticks) >= MAX_TICKS:   # the state now is the state after the last recorded tick: that is the match's final one
		replay.final = SimHash.stateHash(S).gameplay
		done = true
		return
	var word2: bool = SimInputData.right_stick_on()
	for k in range(S.fighters.size()):
		var i = inputs[k] if k < inputs.size() else null
		var p: int = SimIntent.pack(i) if i != null else -1
		var w: int = SimIntent.pack2(i) if word2 and i != null else 0
		if p != _last[k] or w != _last2[k]:
			_last[k] = p
			_last2[k] = w
			var entry: Array = [int(replay.ticks), k] + SimReplay.split(p)
			if w != 0:
				entry.append(w)
			replay.inputs.append(entry)
	replay.ticks = int(replay.ticks) + 1


## The replay as it stands (a copy), with the final hash of the state after its last tick. Call it between ticks: the state is then the one after the last recorded step.
func snapshot(S: SimState) -> Dictionary:
	var rp: Dictionary = replay.duplicate(true)
	if not done and not rp.is_empty():
		rp.final = SimHash.stateHash(S).gameplay
	return rp


## The mode word of a match, from who holds the first two bodies now: one person against the computer ("solo"), two people ("couch"), or the computer alone ("solo", nobody to report for).
static func mode_of(S: SimState) -> String:
	var humans: int = 0
	for k in range(mini(2, S.fighters.size())):
		if S.fighters[k].ai == null:
			humans += 1
	return "couch" if humans >= 2 else "solo"


## The match as a file in user://reports/. reason: report, save, over, quit. Returns the file's name ("" when there is nothing to save or the file could not be written).
## `build` is res://build_info.json's content ({} when the build has none).
func save(S: SimState, reason: String, tag: String, note: String, build: Dictionary, dir: String = "") -> String:
	if not armed or replay.is_empty():
		return ""
	if reason == "report":
		marks.append({"tick": int(replay.ticks), "kind": "report", "tag": tag.left(80), "note": note.left(2000), "at": Time.get_datetime_string_from_system()})
	var where: String = dir if dir != "" else (test_dir if test_dir != "" else DIR)   # the folder asked for, else a test's, else the player's
	var rp: Dictionary = snapshot(S)
	var commit: String = str(build.get("commit", "unknown")).left(8)
	var dt: Dictionary = Time.get_datetime_dict_from_system()
	var fname: String = "solo-%s-main-%04d%02d%02d-%02d%02d%02d-%s.json" % [commit, int(dt.year), int(dt.month), int(dt.day), int(dt.hour), int(dt.minute), int(dt.second), reason]
	if DirAccess.make_dir_recursive_absolute(where) != OK:
		return ""
	var doc := {"kind": KIND, "pc": "main", "slot": 0, "mode": mode_of(S), "build": build, "reason": reason, "savedAt": Time.get_datetime_string_from_system(), "tick": int(rp.get("ticks", 0)), "marks": marks.duplicate(true), "replay": rp}
	var f := FileAccess.open(where.path_join(fname), FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(JSON.stringify(doc))
	f.close()
	_prune(where)
	return fname


## The newest KEEP automatic files stay; older ones of this kind go (only files this class writes: the "solo-" ones). A "Save this match" file (its name ends -save.json) is never counted and never deleted: silently deleting what a player chose to keep is data loss (the EP, 2026-11-21).
static func _prune(dir: String) -> void:
	var names: Array = []
	for n in DirAccess.get_files_at(dir):
		if n.begins_with("solo-") and n.ends_with(".json") and not n.ends_with("-save.json"):
			names.append(n)
	names.sort()   # the name carries the commit, then the time: sorted by time within a build
	var by_time: Array = names.duplicate()
	by_time.sort_custom(func(a, b): return a.substr(a.find("-main-") + 6) < b.substr(b.find("-main-") + 6))
	while by_time.size() > KEEP:
		DirAccess.remove_absolute(dir.path_join(by_time.pop_front()))
