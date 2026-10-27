// SCRATCH HOOK (scratch export only): finer boot marks than hook-bootprof2 (which it replaces; use one of them): an autoload (res://bp_early.gd) marks the moment the engine has started and times the main scene's own load
// (ResourceLoader.load of res://render/main.tscn: its scripts, scenes and preloads), and main._ready is cut into its parts. Each mark goes before or after the line that starts with the given text; a line that is not there is
// skipped with a note. window.__bp = [[name, performance.now() ms], ...] in the page's clock (the probe's page-script marks wasm_instantiate_* and pck/wasm response ends use the same clock).
import { readFileSync, writeFileSync, appendFileSync } from 'node:fs';
const root = process.argv[2];
const NATIVE = process.argv.includes('--native');   // a desktop export: each mark is a printed line `BP <name> <engine ms>` on the console build's stdout, not a page mark
const WEB_BP = '\tif OS.has_feature("web"):\n\t\tJavaScriptBridge.eval("(window.__bp = window.__bp || []).push([\'%s\', performance.now()]);" % n, true)\n';
const fixBp = (t) => (NATIVE ? t.split(WEB_BP).join('\tprint("BP %s %d" % [n, Time.get_ticks_msec()])\n') : t);
const p = root + '/render/core/main.gd';
let lines = readFileSync(p, 'utf8').split('\n');
const notes = [];
function mark(needle, name, where) {
  const i = lines.findIndex((l) => l.trim().startsWith(needle));
  if (i < 0) { notes.push('missing: ' + needle.slice(0, 50)); return; }
  const indent = lines[i].match(/^\t*/)[0];
  const m = indent + '_bp("' + name + '")';
  if (where === 'before') lines.splice(i, 0, m); else lines.splice(i + 1, 0, m);
}
mark('args = parse_args()', 'ready_begin', 'before');
mark('pane = PaneWorld.new()', 'r1_args_and_study_done', 'before');
mark('add_child(pane)', 'r2_pane_made', 'before');
mark('SimInputData.load_and_apply()', 'r3_pane_added', 'before');
mark('host = SimHost.new()', 'r4_input_data_and_flags', 'before');
mark('host.vfx.cracks_enabled = true', 'r5_host_new', 'before');
mark('hud.main = self', 'r6_host_setup', 'before');
mark('$HUD.add_child(ui_hud)', 'r7_ui_hud_instantiated', 'before');
mark('ui_hud.anchor_fn = _hud_anchor', 'r8_ui_hud_added', 'before');
mark('ui_hud.set_option("pad_preset", host.hub.pad_preset)', 'r9_hud_connects', 'before');
mark('if not manual and not args.has("bench") and not args.has("frames") and not args.has("shot"):', 'r10_hud_options_set', 'before');
mark('_on_option_changed("pad_preset", ui_hud.opts["pad_preset"])', 'r11_saved_options_loaded', 'before');
mark('host.drained.connect(_on_drained)', 'r12_options_applied', 'before');
mark('audio = AudioVoices.new(host.audio_cues.bank)', 'audio_begin', 'before');
mark('host.audio_cues.bank.warm()', 'audio_made', 'before');
mark('host.audio_cues.bank.warm()', 'audio_bank_warm_end', 'after');
mark('start_match(int(args["seed"])', 'start_match_end', 'after');
mark('roll_on = RenderLook.CAMERA_ROLL_ON', 'r13_after_start_match', 'before');
mark('split_view = SplitView.new()', 'r14_flags', 'before');
mark('var warm := RenderWarmup.new()', 'r15_split_view', 'before');
mark('warm.start(pane.get_world_3d())', 'render_warmup_started', 'after');
mark('ui_hud.show_howto(true)', 'howto_shown', 'after');
mark('_sky_args()', 'ready_almost_end', 'before');
mark('RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)', 'ready_end', 'before');
// the staged boot (3d276d57 and later): when the match's pieces and the panes' build first run, when the shader compile steps first run, and when the boot ends (the first ordinary frame follows)
mark('_step_load()   #', 'step_load_first', 'before');
mark('_step_boot(delta)', 'step_boot_first', 'before');
mark('boot = null', 'boot_done', 'after');
for (const n of ['step_load_first', 'step_boot_first']) { const i = lines.findIndex((l) => l.includes('_bp("' + n + '")')); if (i >= 0) lines[i] = lines[i].replace('_bp(', '_bp_once('); }
let s = lines.join('\n');
s = s.replace('func _process(delta: float) -> void:\n', 'func _process(delta: float) -> void:\n\tif frames < 6:\n\t\t_bp("process_frame_%d" % frames)\n');
s += `

func _bp(n: String) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(window.__bp = window.__bp || []).push(['%s', performance.now()]);" % n, true)


var _bp_seen: Dictionary = {}


func _bp_once(n: String) -> void:
	if not _bp_seen.has(n):
		_bp_seen[n] = true
		_bp(n)
`;
writeFileSync(p, fixBp(s));
writeFileSync(root + '/bp_early.gd', fixBp(`extends Node
# SCRATCH: the engine is up (the project's settings, servers and the autoloads are made); then the main scene's own load is timed.
func _bp(n: String) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(window.__bp = window.__bp || []).push(['%s', performance.now()]);" % n, true)
func _init() -> void:
	_bp("autoload_init")
	# the main scene's load cut by owner: each entry script or scene is loaded in turn (a script compiles the scripts it names, so the first to need a shared one carries it), then the scene itself
	var keep: Array = []
	for e in [["sim_host", "res://render/core/sim_host.gd"], ["audio_voices", "res://audio/audio_voices.gd"], ["ui_hud", "res://ui/hud/ui_hud.tscn"], ["fighter_view", "res://render/core/fighter_view.gd"], ["render_anim", "res://render/anim/render_anim.gd"], ["planet_view", "res://render/core/planet_view.gd"], ["pane_world", "res://render/core/pane_world.gd"], ["split_view", "res://render/camera/split_view.gd"], ["vfx_look", "res://render/vfx/vfx_look.gd"], ["boot", "res://render/core/boot.gd"]]:
		keep.append(ResourceLoader.load(e[1]))
		_bp("load_" + e[0])
	keep.append(ResourceLoader.load("res://render/main.tscn"))
	_bp("main_scene_loaded")
	keep = []
`));
let pg = readFileSync(root + '/project.godot', 'utf8');
if (/^\[autoload\]/m.test(pg)) throw new Error('project.godot already has [autoload]; edit the hook');
pg += '\n[autoload]\n\nBpEarly="*res://bp_early.gd"\n';
writeFileSync(root + '/project.godot', pg);
console.log('bootprof3 applied; ' + (notes.join('; ') || 'every anchor found'));
