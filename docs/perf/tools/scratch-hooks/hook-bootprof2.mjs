// SCRATCH HOOK (scratch export only): time marks through the game's boot, for a HEAD newer than 257a766c (hook-bootprof.mjs was written for that pin's exact lines): each mark goes after or before the line
// that starts with the given text, and a line that is not there is skipped with a note, not an error. window.__bp = [[name, performance.now() ms], ...] in the page's clock.
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/core/main.gd';
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
mark('pane = PaneWorld.new()', 'pane_world_made_after_add', 'after');
mark('host = SimHost.new()', 'host_new_end', 'after');
mark('$HUD.move_child(ui_hud, 0)', 'ui_hud_instantiated', 'after');
mark('audio = AudioVoices.new(host.audio_cues.bank)', 'audio_begin', 'before');
mark('host.audio_cues.bank.warm()', 'audio_bank_warm_end', 'after');
mark('start_match(int(args["seed"])', 'start_match_end', 'after');
mark('warm.start(pane.get_world_3d())', 'render_warmup_started', 'after');
mark('_sky_args()', 'ready_almost_end', 'before');
mark('RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)', 'ready_end', 'before');
let s = lines.join('\n');
s = s.replace('func _process(delta: float) -> void:\n', 'func _process(delta: float) -> void:\n\tif frames < 6:\n\t\t_bp("process_frame_%d" % frames)\n');
s += `

func _bp(n: String) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(window.__bp = window.__bp || []).push(['%s', performance.now()]);" % n, true)
`;
writeFileSync(p, s); console.log('bootprof2 applied; ' + (notes.join('; ') || 'every anchor found'));
