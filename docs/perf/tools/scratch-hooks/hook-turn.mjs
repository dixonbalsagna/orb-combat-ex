// SCRATCH HOOK (scratch export only): two AI-against-AI scenes on a Half planet arena (planet 7, touch 3, 2,400 columns): `turn`, where the hook stages the director's ask and pick at tick 10
// (WorldEpoch.ask, then WorldEpoch.choose with the largest bearing; k and the fallback from the page: turnk=16&turnfb=2.5 is a landing, turnk=32&turnfb=0 a form step; default k 32, fallback 2.5), and `turnoff`, the same match with World's turn off. The director's own
// switch (data/director/interrupts.json calmTurn.enabled) stays off, as shipped: then DirCalm.hold holds nothing back and World's own calm decides when the swap happens, so the turn
// happens at the first calm tick after both rings are read. The tick of every `arena_turn` event goes to window.__turns (frame-bench.mjs reads it into turnWindows); window.__pick and
// window.__dbg say what the staging did. Needs a build with World's window 3 on main. Apply after hook-perf.mjs.
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/tools/flash_capture.gd';
let s = readFileSync(p, 'utf8');
s = s.replace('"mashdummy", "ring"', '"turn", "turnoff", "mashdummy", "ring"');
s = s.replace('"mashdummy": [false, true]', '"turn": [true, true], "turnoff": [true, true], "mashdummy": [false, true]');
const a1 = '\t\t"ai":           # the real AI match, forms readied at 300 and 1500, a tier raised at 900';
if (!s.includes(a1)) throw new Error('anchor ai scenario');
s = s.replace(a1, '\t\t"turn", "turnoff":\n\t\t\tif sc == "turn" and t == 10:\n\t\t\t\t_turn_pick(S)\n' + a1);
const a2 = '\tmain.start_match(seed if seed != 0 else SEED, ai_set, {} if slots.size() < 2 else {"slots": slots})';
if (!s.includes(a2)) throw new Error('anchor start_match');
s = s.replace(a2, '\tvar su_t: Dictionary = {} if slots.size() < 2 else {"slots": slots}\n\tif sc == "turn" or sc == "turnoff":\n\t\tsu_t = {"planet": 7, "touch": 3, "arena": {"cols": 2400, "turn": sc == "turn"}}\n\t\tJavaScriptBridge.eval("window.__turns = [];", true)\n\t\tif not host.drained.is_connected(_turn_drained):\n\t\t\thost.drained.connect(_turn_drained)\n\tmain.start_match(seed if seed != 0 else SEED, ai_set, su_t)\n\tif sc == "turn" or sc == "turnoff":\n\t\t_turn_dbg()');
s += `

func _turn_pick(S: SimState) -> void:
	# a staged decision, as the director's ask and pick would make it
	if S.epoch == null:
		return
	var a = S.fighters[0]
	var b = S.fighters[1]
	var dx: float = SimWrap.sdx(a.x, b.x)
	var pivot: float = SimWrap.wrap(a.x + 0.5 * dx)
	var side: int = 1 if dx >= 0.0 else -1
	S.epoch.lastT = -1.0e9   # staging: the 60 s gap between turns is not what is measured
	var c: Array = WorldEpoch.ask(S, "perf", pivot, side, S.tick + 80)
	if not c.is_empty():
		var kk: int = int(_page_kv("turnk")) if _page_kv("turnk") != "" else 32
		var fbd: float = float(_page_kv("turnfb")) if _page_kv("turnfb") != "" else 2.5
		WorldEpoch.choose(S, c.size() - 1, kk, fbd)
	JavaScriptBridge.eval("window.__pick = %s;" % JSON.stringify({"tick": S.tick, "cands": c.size()}), true)


func _turn_dbg() -> void:
	var S = main.host.S
	JavaScriptBridge.eval("window.__dbg = %s; window.__asks = [];" % JSON.stringify({"epoch": S.epoch != null, "on": DirCalm.on(S), "enabled": bool(DirInterrupt.data().get("calmTurn", {}).get("enabled", false)), "cols": SimConst.NC}), true)


func _turn_drained(events: Array, _lines: Array) -> void:
	for e in events:
		if str(e.type) == "cue" and str(e.kind) == "calm_turn":
			JavaScriptBridge.eval("(window.__asks = window.__asks || []).push([%d, '%s']);" % [main.host.ticks, str(e.text)], true)
		if str(e.type) == "arena_turn":
			JavaScriptBridge.eval("(window.__turns = window.__turns || []).push(%d);" % main.host.ticks, true)
`;
writeFileSync(p, s);
console.log('turn hook applied');
