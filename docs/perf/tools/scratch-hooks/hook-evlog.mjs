// Scratch: the fx event types of the last tick (window.__flashcap.perf.ev), so a driver can say what the sim did at a hitching tick. Apply after hook-perf.mjs.
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/tools/flash_capture.gd';
let s = readFileSync(p, 'utf8');
const a = '\tmain.started = true';
if (!s.includes(a)) throw new Error('anchor started');
s = s.replace(a, '\thost.drained.connect(_ev_drained)\n' + a);
if (!s.includes('"tick": main.host.ticks,')) throw new Error('anchor perf json');
s = s.replace('"tick": main.host.ticks,', '"tick": main.host.ticks, "ev": _ev_last,');
s += `

var _ev_last: String = ""


func _ev_drained(events: Array, _lines: Array) -> void:
	var seen := {}
	for e in events:
		var t: String = str(e.type)
		if t != "tick":
			seen[t] = int(seen.get(t, 0)) + 1
	var parts: PackedStringArray = []
	for k in seen:
		parts.append("%s*%d" % [k, seen[k]])
	_ev_last = " ".join(parts)
`;
writeFileSync(p, s); console.log('evlog hook applied');
