// SCRATCH HOOK (scratch export only): how much of the run is a split view, and how many ground/water items 22l's culling leaves out per pane, as window.__cull = [ticks, ticks_split, culled_pane0_sum, culled_pane1_sum]
// (published every 30 ticks). Safe on a build without 22l (the sums stay 0). Apply after hook-perf.mjs.
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/tools/flash_capture.gd';
let s = readFileSync(p, 'utf8');
const a = '\tsteps += 1\n';
if (!s.includes(a)) throw new Error('anchor steps');
s = s.replace(a, a + '\t_cull_tick()\n');
s += `

var _cu_n: int = 0
var _cu_sp: int = 0
var _cu_0: int = 0
var _cu_1: int = 0


func _cull_tick() -> void:
	_cu_n += 1
	var sf = main.split_frame
	if sf != null and main.panes.size() > 1 and sf.shows(1):
		_cu_sp += 1
	for i in range(mini(2, main.panes.size())):
		var pl = main.panes[i].planet
		if "culled" in pl:
			if i == 0:
				_cu_0 += int(pl.culled)
			else:
				_cu_1 += int(pl.culled)
	if _cu_n % 30 == 0:
		JavaScriptBridge.eval("window.__cull = %s;" % JSON.stringify([_cu_n, _cu_sp, _cu_0, _cu_1]), true)
`;
writeFileSync(p, s); console.log('cullstat hook applied');
