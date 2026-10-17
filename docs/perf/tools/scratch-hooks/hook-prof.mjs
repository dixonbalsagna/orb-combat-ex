// Scratch profiling instrumentation: times the named pieces of a frame (PaneWorld.PT per frame, PT_SUM per run).
import { readFileSync, writeFileSync } from 'node:fs';
const root = process.argv[2];
function edit(file, f) { const p = root + '/' + file; let s = readFileSync(p, 'utf8'); s = f(s); writeFileSync(p, s); }
function rep(s, from, to) { if (!s.includes(from)) throw new Error('anchor missing: ' + from.slice(0, 60)); return s.replace(from, () => to); }
edit('render/core/pane_world.gd', (s) => {
  s = rep(s, 'static var _drawing: PaneWorld = null', 'static var PT: Dictionary = {}\nstatic var PT_SUM: Dictionary = {}\nstatic func _pt(k: String, t0: int) -> void:\n\tvar d: int = Time.get_ticks_usec() - t0\n\tPT[k] = int(PT.get(k, 0)) + d\n\tPT_SUM[k] = int(PT_SUM.get(k, 0)) + d\nstatic var _drawing: PaneWorld = null');
  s = rep(s, '\tvar S: SimState = host.S\n\tvar vp: Vector2 = get_viewport().get_visible_rect().size\n\tview_cam_x = cam_x\n', '\tvar _t0: int = Time.get_ticks_usec()\n\tvar S: SimState = host.S\n\tvar vp: Vector2 = get_viewport().get_visible_rect().size\n\tview_cam_x = cam_x\n');
  s = rep(s, '\tplanet.update(S, cam_x, host.impact.heat, host.impact.heat_changed)\n\tfor i in range(fighter_views.size()):', '\t_pt("pane_pre", _t0)\n\tvar _t1: int = Time.get_ticks_usec()\n\tplanet.update(S, cam_x, host.impact.heat, host.impact.heat_changed)\n\t_pt("planet_update", _t1)\n\tvar _tf: int = Time.get_ticks_usec()\n\tfor i in range(fighter_views.size()):');
  s = rep(s, '\t_occlusion(S, cam_x, vp)\n\t_lane_cues(host, a)\n\t_pair_mark(host, a)\n\t_sky_react(host, cam_x)\n\t_drawing = self   # VFX\'s clear query is this pane\'s while its effects are drawn\n\tvfx_layer.update(host, a, cam_x, cam.z, vp.x)\n\t_drawing = null\n\tbeams.update(S, cam_x, cam.z, host)\n', '\t_pt("fighters_update", _tf)\n\tvar _t2: int = Time.get_ticks_usec()\n\t_occlusion(S, cam_x, vp)\n\t_pt("occlusion", _t2)\n\t_lane_cues(host, a)\n\t_pair_mark(host, a)\n\t_sky_react(host, cam_x)\n\t_drawing = self\n\tvar _t3: int = Time.get_ticks_usec()\n\tvfx_layer.update(host, a, cam_x, cam.z, vp.x)\n\t_pt("vfx_layer", _t3)\n\t_drawing = null\n\tvar _t4: int = Time.get_ticks_usec()\n\tbeams.update(S, cam_x, cam.z, host)\n\t_pt("beams", _t4)\n\tvar _t5: int = Time.get_ticks_usec()\n');
  s = rep(s, '\tparticles.update(host.fxv, host.impact, cam_x, cam.z, cam_rig.half_width(vp.x, RenderLook.Z_PARTICLES - focus_z), fighter_views)\n', '\tparticles.update(host.fxv, host.impact, cam_x, cam.z, cam_rig.half_width(vp.x, RenderLook.Z_PARTICLES - focus_z), fighter_views)\n\t_pt("particles", _t5)\n');
  return s;
});
edit('render/core/main.gd', (s) => {
  s = rep(s, '\tui_hud.advance(0.0 if host.paused else delta)\n', '\tvar _th: int = Time.get_ticks_usec()\n\tui_hud.advance(0.0 if host.paused else delta)\n\tPaneWorld._pt("hud_advance", _th)\n');
  s = rep(s, '\t\tsplit_frame = split_rig.frame(a)\n', '\t\tvar _ts: int = Time.get_ticks_usec()\n\t\tsplit_frame = split_rig.frame(a)\n\t\tPaneWorld._pt("split_rig_frame", _ts)\n');
  s = rep(s, '\t\tcompositor.present(split_frame)\n', '\t\tvar _tp: int = Time.get_ticks_usec()\n\t\tcompositor.present(split_frame)\n\t\tPaneWorld._pt("present", _tp)\n');
  s = rep(s, '\tvar n: int = host.advance(delta, vp.x, vp.y)\n', '\tvar _tn: int = Time.get_ticks_usec()\n\tvar n: int = host.advance(delta, vp.x, vp.y)\n\tPaneWorld._pt("host_advance", _tn)\n');
  s = rep(s, '\tprint("gameplay hash at tick %d: %s" % [host.ticks, gh])', '\tfor k in PaneWorld.PT_SUM:\n\t\tprint("PROF %-18s mean %.3f ms/frame" % [k, float(PaneWorld.PT_SUM[k]) / 1000.0 / maxf(1.0, float(frames))])\n\tprint("gameplay hash at tick %d: %s" % [host.ticks, gh])');
  return s;
});
edit('render/tools/flash_capture.gd', (s) => {
  s = rep(s, '"rgpu": RenderingServer.viewport_get_measured_render_time_gpu(rid), "tick": main.host.ticks,', '"rgpu": RenderingServer.viewport_get_measured_render_time_gpu(rid), "tick": main.host.ticks, "pt": PaneWorld.PT.duplicate(),');
  s = rep(s, '\tvar r: Array = main._ring\n\tvar rid: RID', '\tvar r: Array = main._ring\n\tvar _snap: Dictionary = PaneWorld.PT.duplicate()\n\tvar rid: RID');
  return s;
});
console.log('profiling hook applied to', root);
