// SCRATCH HOOK (scratch export only): time marks through the game's boot (render/core/main.gd _ready and the first frames), as window.__bp = [[name, performance.now() ms], ...] in the page's clock, so a
// freeze probe can say which part of the first, synchronous call into the wasm takes how long. Written for the pin 257a766c (the live site, 2026-10-26); each anchor is checked.
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/core/main.gd';
let s = readFileSync(p, 'utf8');
function after(anchor, name) { if (!s.includes(anchor)) throw new Error('anchor: ' + anchor.slice(0, 60)); s = s.replace(anchor, anchor + '\n\t_bp("' + name + '")'); }
function before(anchor, name) { if (!s.includes(anchor)) throw new Error('anchor: ' + anchor.slice(0, 60)); s = s.replace(anchor, '\t_bp("' + name + '")\n' + anchor); }
before('\targs = parse_args()', 'ready_begin');
after('\tpane = PaneWorld.new()\n\tadd_child(pane)', 'pane_world_made');
after('\t\twarm.start(pane.get_world_3d())', 'render_warmup_started');
before('\thost = SimHost.new()', 'host_new_begin');
after('\thost = SimHost.new()', 'host_new_end');
after('\t$HUD.move_child(ui_hud, 0)    # under the greybox overlay, which keeps the take-over prompt and the perf readout', 'ui_hud_instantiated');
before('\taudio = AudioVoices.new(host.audio_cues.bank)', 'audio_begin');
after('\thost.audio_cues.bank.warm()   # render every sound now, so none renders in the middle of a fight (headless too: a tool times first plays as the game has them)', 'audio_bank_warm_end');
after('\tstart_match(int(args["seed"]) if args.has("seed") else fresh_seed())', 'start_match_end');
before('\t_sky_args()', 'split_view_and_howto_end');
before('\tRenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)', 'ready_end');
s = s.replace('func _process(delta: float) -> void:\n', 'func _process(delta: float) -> void:\n\tif frames < 6:\n\t\t_bp("process_frame_%d" % frames)\n');
s += `

func _bp(n: String) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(window.__bp = window.__bp || []).push(['%s', performance.now()]);" % n, true)
`;
writeFileSync(p, s); console.log('bootprof hook applied');
