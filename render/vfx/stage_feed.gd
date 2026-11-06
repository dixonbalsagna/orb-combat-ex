class_name VfxStageFeed
extends RefCounted
## The other fights' effects (2v2, `{"fights": 2}`; docs/vfx/other-fights.md). Simulation's fight swap (docs/architecture/fight-swap.md) keeps one fight in S between ticks, fight 0's, and the host drains only
## its events. Rendering's host reads each other fight's events (`host.other_events()`, one fx list for each fight past the first, behind `SimHost.draw_others`) and pushes them here: `VfxHub.consume_others`.
## This gives every other fight its own VfxHub, fed from its own events on its own clock, so its hits, sparks, dust, beams and shots are made as in a fight of their own.
##
## READ ONLY. It never swaps a fight into S and assigns nothing to S or to a fight's record. The state a fight's hub reads is Animation's one view of another fight, `RenderAnim.fight_view(S, k)` (docs/animation/fight-view.md):
## a SimState whose per-fight fields are fight k's record and whose every other field is S's own by reference. A pane that shows fight k draws its hub (`hubs[k]`) with that view as the state.
##
## Off by default (`VfxHub.other_fights_enabled`, `?otherfights=1` on a local page), and a hub only takes the push when the host has said it will (`VfxHub.host_pushes`).

var hubs: Array = []              # hubs[i] is fight i's hub (null for 0: the main hub is that)
var fed: int = 0                  # calls that fed at least one other fight (for the tests)
var events_fed: int = 0           # events handed to the other hubs
var kinds: Dictionary = {}        # event type -> count, for the tests
var _sync_at: int = -1000

static var _word: String = "?"


## The preview's page word: `?otherfights=1` turns the other fights' effects on. Only where UI honours its own bypass words (a local page); off the web and anywhere the bypass is not allowed it reads nothing.
static func page_word() -> bool:
	if _word != "?":
		return _word == "1"
	_word = ""
	if OS.has_feature("web") and UiHud.bypass_allowed():
		var q: String = str(JavaScriptBridge.eval("location.search", true))
		for pair in q.trim_prefix("?").split("&", false):
			var kv: PackedStringArray = pair.split("=", true, 1)
			if kv[0] == "otherfights" and kv.size() > 1 and kv[1] != "" and kv[1] != "0" and kv[1] != "false":
				_word = "1"
	return _word == "1"


func reset() -> void:
	hubs.clear()
	fed = 0
	events_fed = 0
	kinds = {}
	_sync_at = -1000


## Once per tick, after the host has handed the main hub fight 0's events: each other fight's events (`lists[i - 1]`, as the host read them) to its own hub, read through Animation's view of that fight.
func feed(S: SimState, main: VfxHub, lists: Array) -> void:
	if S.stage == null:
		return
	var n: int = S.stage.fights.size()
	while hubs.size() < n:
		hubs.append(null)
	var any: bool = false
	var do_sync: bool = S.tick - _sync_at >= 30
	for i in range(1, n):
		if i - 1 >= lists.size():
			break
		var v: SimState = RenderAnim.fight_view(S, i)
		var hb: VfxHub = hubs[i]
		if hb == null:
			hb = VfxHub.new()
			hb.other_fights_enabled = false      # never feeds a third
			hb.is_other = true
			hb.reset(v, main.seed + 7919 * i)
			hubs[i] = hb
			do_sync = true
		if do_sync:
			_sync(main, hb)
		var ev: Array = (lists[i - 1] as Array).duplicate()      # the host's list for this fight, copied: nothing here drains or clears it
		for e in ev:
			var tp: String = String(e.type)
			kinds[tp] = int(kinds.get(tp, 0)) + 1
		events_fed += ev.size()
		hb.consume(v, ev)
		any = true
	if do_sync:
		_sync_at = S.tick
	if any:
		fed += 1


## The main hub's switches and screen numbers, copied to an other fight's hub (every `*_enabled`, and what the host sets each frame).
static func _sync(main: VfxHub, hb: VfxHub) -> void:
	for p in main.get_property_list():
		var nm: String = String(p["name"])
		if not (int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if nm == "other_fights_enabled":
			continue
		if nm.ends_with("_enabled") or nm in ["enabled", "quality", "reduced_motion", "reduced_flashing", "force_reduced", "px_per_unit", "cam_dist", "perf_level", "clear_query"]:
			hb.set(nm, main.get(nm))
