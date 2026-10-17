// SCRATCH HOOK (applied only to a scratch export made by docs/perf/tools/make-audit-sites.mjs; never to the repo): publishes per-frame cost to window.__flashcap.perf from the flash capture's poll().
import { readFileSync, writeFileSync } from 'node:fs';
const p = process.argv[2] + '/render/tools/flash_capture.gd';
let s = readFileSync(p, 'utf8');
const a = "\t\tJavaScriptBridge.eval(\"window.__flashcap._shown(%d, %d);\" % [host.ticks, host.vfx.flashes.in_window()], true)\n";
if (!s.includes(a)) throw new Error('anchor missing');
s = s.replace(a, "\t\tJavaScriptBridge.eval(\"window.__flashcap.perf = %s;\" % _perf_json(), true)\n" + a);
s = s.replace("func poll() -> void:\n", "func poll() -> void:\n\tif _frames == 0:\n\t\tRenderingServer.viewport_set_measure_render_time(main.get_viewport().get_viewport_rid(), true)\n");
s += `

## SCRATCH (docs/perf audit): the last frame's cost, for a driver that reads window.__flashcap.perf.
func _perf_json() -> String:
	var r: Array = main._ring
	var rid: RID = main.get_viewport().get_viewport_rid()
	var last := func(a): return a[a.size() - 1] if a.size() > 0 else 0.0
	return JSON.stringify({
		"frame_ms": last.call(r[0]), "tick_ms": last.call(r[1]), "fx_ms": last.call(r[2]), "view_ms": last.call(r[3]),
		"draws": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"objects": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		"prims": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		"vmem": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED), "tmem": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
		"smem": Performance.get_monitor(Performance.MEMORY_STATIC), "parts": main.particles.count,
		"rcpu": RenderingServer.viewport_get_measured_render_time_cpu(rid) + RenderingServer.get_frame_setup_time_cpu(),
		"rgpu": RenderingServer.viewport_get_measured_render_time_gpu(rid), "tick": main.host.ticks,
	})
`;
// AUTO mode: with window.__flashcap.auto = true the hook runs one tick on every animation frame by itself (as the game does at 60 Hz), instead of one tick per step() call.
// step() ran a tick on every OTHER frame (the promise resolved after poll() had looked for the next request), so a step took two animation frames, the second only repeating the picture.
const e1 = 'pending: fc._want - fc._done }';
if (!s.includes(e1)) throw new Error('anchor auto 1');
s = s.replace(e1, 'pending: fc._want - fc._done, auto: !!fc.auto }');
const e2 = '\tif int(st.get("pending", 0)) > 0:\n\t\tstep()';
if (!s.includes(e2)) throw new Error('anchor auto 2');
s = s.replace(e2, '\tif int(st.get("pending", 0)) > 0 or (bool(st.get("auto", false)) and scenario != ""):\n\t\tstep()');
writeFileSync(p, s);
console.log('hook applied');
