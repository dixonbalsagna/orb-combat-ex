class_name VfxStageFeed
extends RefCounted
## The other fights' effects (2v2, `{"fights": 2}`; docs/vfx/other-fights.md). Simulation's fight swap (docs/architecture/fight-swap.md) keeps one fight in S between ticks (fight 0's after a step; a host may hold its own player's fight:
## `S.stage.cur`), and the host drains only its events. Rendering's host reads each other fight's events (`host.other_events()`, one fx list for each fight but the one in S, in order, behind
## `SimHost.draw_others`) and pushes them here: `VfxHub.consume_others`.
## This gives every other fight its own VfxHub, fed from its own events on its own clock, so its hits, sparks, dust, beams and shots are made as in a fight of their own.
##
## READ ONLY. It never swaps a fight into S and assigns nothing to S or to a fight's record. The state a fight's hub reads is Animation's one view of another fight, `RenderAnim.fight_view(S, k)` (docs/animation/fight-view.md):
## a SimState whose per-fight fields are fight k's record and whose every other field is S's own by reference. A pane that shows fight k draws its hub (`hubs[k]`) with that view as the state.
##
## ONE REGISTER (RL-249 (1); docs/vfx/shared-register.md): every other hub holds the main hub's flash register and asks it on its own channel, so the limits apply to the sum.
##
## Off by default (`VfxHub.other_fights_enabled`, `?otherfights=1` on a local page, `--otherfx` on a desktop run), and a hub only takes the push when the host has said it will (`VfxHub.host_pushes`).

var hubs: Array = []              # hubs[i] is fight i's hub (null for the fight in S, S.stage.cur: the main hub is that one's)
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


## The desktop switch: `--otherfx` (or `--otherfx=1`) on the command line of a desktop run, the private 2v2 LAN setup. Off by default; never read on the web, so no public page or pin can turn it on; with it on the hub locks
## Reduce flashing on (`VfxHub.reduced_flashing`) and the UI shows the warning (UI's). Orb alone sees the drawn effects until the clips pass (Legal RL-249 (6), (7)).
static var _dword: String = "?"


static func desktop_word() -> bool:
	if _dword != "?":
		return _dword == "1"
	_dword = ""
	if not OS.has_feature("web"):
		for a in OS.get_cmdline_user_args():
			if a == "--otherfx" or (a.begins_with("--otherfx=") and not a.ends_with("=0") and not a.ends_with("=false") and not a.ends_with("=")):
				_dword = "1"
	return _dword == "1"


func reset() -> void:
	hubs.clear()
	fed = 0
	events_fed = 0
	kinds = {}
	_sync_at = -1000


## Once per tick, after the host has handed the main hub the events of the fight in S: each other fight's events to its own hub, read through Animation's view of that fight. The host's
## lists are the fights other than the one in S (`S.stage.cur`), in order (`host.other_events()`), so the j-th list is the j-th of those fights: fight 0's when S holds fight 1 (the PC that
## plays fight 1, or after a trade). A fight now in S drops the hub it had as an other fight: the main hub draws it, and a hub it needs again later starts afresh.
func feed(S: SimState, main: VfxHub, lists: Array) -> void:
	if S.stage == null:
		return
	var n: int = S.stage.fights.size()
	var cur: int = int(S.stage.cur)
	if cur < 0 or cur >= n:
		return   # between ticks S always holds one fight; anything else is not a moment to read
	while hubs.size() < n:
		hubs.append(null)
	hubs[cur] = null
	var any: bool = false
	var do_sync: bool = S.tick - _sync_at >= 30
	var j: int = 0
	for i in range(n):
		if i == cur:
			continue
		if j >= lists.size():
			break
		var v: SimState = RenderAnim.fight_view(S, i)
		var hb: VfxHub = hubs[i]
		if hb == null:
			hb = VfxHub.new()
			hb.other_fights_enabled = false      # never feeds a third
			hb.is_other = true
			hb.shares_register = true      # reset leaves the register alone
			hb.reset(v, main.seed + 7919 * i)
			hb.adopt_register(main.flashes, i + 1)      # one register for the screen: this hub is a feeder on channel i + 1
			hubs[i] = hb
			do_sync = true
		if do_sync:
			_sync(main, hb)
		var ev: Array = (lists[j] as Array).duplicate()      # the host's list for this fight, copied: nothing here drains or clears it
		j += 1
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
