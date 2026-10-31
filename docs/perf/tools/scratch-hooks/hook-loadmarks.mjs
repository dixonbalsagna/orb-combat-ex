// SCRATCH HOOK (a scratch stack tree only, never the repo): where the boot's "loading" phase goes (Performance and Platform, 2026-10-31). Run on a tree made by tools/preview/stack-preview.mjs --keep-tree.
//   node hook-loadmarks.mjs <tree>
// window.__bp = [[name, performance.now()], ...] in the page's clock (same as load-probe.mjs's page marks), and window.__bpd = { name: [calls, total ms, longest call ms] } from main.gd:
//   sim_<phase>: each phase of the sim's planet load (host.load_step, a slice a frame); the match's own pieces ("match");
//   the pane build's steps by method name (_bs_materials, _bs_meshes, _bs_fighter, _mb_picture ...): main._step_build, a few a frame, each call timed;
//   marks: ready_begin, step_load_first, build_queue_made, build_done (the compile starts), boot_done.
import { readFileSync, writeFileSync } from 'node:fs';

const root = process.argv[2];
if (!root) throw new Error('usage: node hook-loadmarks.mjs <tree>');
const p = `${root}/render/core/main.gd`;
let s = readFileSync(p, 'utf8');
const swap = (from, to, once = true) => { const n = s.split(from).length - 1; if (n !== 1 && once) throw new Error(`"${from.slice(0, 60)}" found ${n} times`); s = s.split(from).join(to); };

swap('\tvar phase: String = host.load_phase()\n\tif host.load_step():\n', '\tvar phase: String = host.load_phase()\n\t_bp_once("step_load_first")\n\tvar _bt0: int = Time.get_ticks_usec()\n\tvar _bld: bool = host.load_step()\n\t_bpd("sim_" + phase, Time.get_ticks_usec() - _bt0)\n\tif _bld:\n');
swap('\t\t\t_build_queue = _match_built_steps()\n', '\t\t\t_build_queue = _match_built_steps()\n\t\t\t_bp("build_queue_made")\n');
swap('\t\tif (_build_queue[0] as Callable).call():\n\t\t\t_build_queue.pop_front()\n', '\t\tvar _bc: Callable = _build_queue[0]\n\t\tvar _bt: int = Time.get_ticks_usec()\n\t\tvar _bdone: bool = _bc.call()\n\t\t_bpd(String(_bc.get_method()), Time.get_ticks_usec() - _bt)\n\t\tif _bdone:\n\t\t\t_build_queue.pop_front()\n');
swap('\tui_hud.hide_loading()\n\tif boot != null:\n\t\tboot.compile(all_panes(), pane.get_world_3d())\n', '\tui_hud.hide_loading()\n\t_bp("build_done")\n\tif boot != null:\n\t\tboot.compile(all_panes(), pane.get_world_3d())\n');
swap('\t\t\t_step_boot(delta)\n\t\t\treturn\n\t\tboot = null\n', '\t\t\t_bp_once("step_boot_first")\n\t\t\t_step_boot(delta)\n\t\t\treturn\n\t\tboot = null\n\t\t_bp("boot_done")\n\t\t_bpd_dump()\n');
swap('func _ready() -> void:\n', 'func _ready() -> void:\n\t_bp("ready_begin")\n');
s += `

var _bp_seen: Dictionary = {}
var _bpd_acc: Dictionary = {}


func _bp(n: String) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(window.__bp = window.__bp || []).push(['%s', performance.now()]);" % n, true)


func _bp_once(n: String) -> void:
	if not _bp_seen.has(n):
		_bp_seen[n] = true
		_bp(n)


func _bpd(n: String, us: int) -> void:
	var a: Array = _bpd_acc.get(n, [0, 0.0, 0.0])
	a[0] += 1
	a[1] += us / 1000.0
	a[2] = maxf(a[2], us / 1000.0)
	_bpd_acc[n] = a


func _bpd_dump() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__bpd = " + JSON.stringify(_bpd_acc) + ";", true)
`;
writeFileSync(p, s);
writeFileSync(`${root}/bp_early.gd`, `extends Node
# SCRATCH: the engine is up (settings, servers and the autoloads are made).
func _init() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(window.__bp = window.__bp || []).push(['autoload_init', performance.now()]);", true)
`);
let pg = readFileSync(`${root}/project.godot`, 'utf8');
if (/^\[autoload\]/m.test(pg)) pg = pg.replace(/^\[autoload\]\s*\n/m, '[autoload]\n\nBpEarly="*res://bp_early.gd"\n');
else pg += '\n[autoload]\n\nBpEarly="*res://bp_early.gd"\n';
writeFileSync(`${root}/project.godot`, pg);
console.log('hook-loadmarks applied to', root);
