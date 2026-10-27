#!/usr/bin/env node
// Per-part timers for a frame of the web build, for Performance's frame bench (docs/perf/tools/frame-bench.mjs reads them as
// pt_ms: per part, ms a frame, mean and percentiles). A scratch hook: it edits a scratch copy of the game (git archive into a
// folder of your own), never the repo. It extends Performance's hook-prof.mjs (docs/perf/tools/scratch-hooks/), whose pane
// anchors no longer fit main, with the parts Rendering's coast profile used (2026-10-27).
//
//   node docs/rendering/tools/prof-hook.mjs <scratch tree>
//
// Apply it after Performance's hook-perf.mjs (the frame bench's per-frame row; it publishes PaneWorld.PT_SUM there as "pt").
// For the gen 2 coast also hook-slice.mjs and hook-pbiome.mjs, as make-audit-sites.mjs's pb variant does; then import,
// export, and run frame-bench.mjs --scene pb --page-args "pgen=2&pbiome=coast&pplanet=7" --igpu --reduced --ticks 600.
// Each part is applied only where its line is found exactly once; the rest are skipped and listed, so the hook outlives
// small changes in the files it times (re-anchor a skipped part if you need it). Names, each a frame's sum of its calls:
//   main's frame:      host_advance (the ticks), hud_advance (UI), split_rig_frame and present (Camera), mv_* (the rest of
//                      main's view: far_land, ui_bridge, hud_key, sync_players, audio), mv_view_total (main's whole view)
//   a pane's render:   pane_setup, pan_haze, sky_drive, fore_low, view_cues, pane_pre, planet_update, planet_cull,
//                      fighters_update (the loop), fighter_view (its update), occlusion, cues_after, vfx_layer, beams, particles
//   the fighter view:  fv_anim_solve, fv_anim_apply (Animation), fv_damage, fv_pose_cue
//   the planet:        pv_ground, pv_flight_arrive, pv_refresh (the buildings, with the trees), pv_trees, pv_flight_step, pv_startle
//   a tick's fx:       fx_cam_step, fx_fxv, fx_impact, fx_audio_cues, fx_drained (the drain's listeners), fx_vfx,
//                      fx_flashes_due, fx_ask_beams, fx_ask_hits
//   the drain:         dr_split_rig_step (Camera), dr_planet_consume, dr_camera_roll, dr_anim_consume (Animation),
//                      dr_ui_consume, dr_haptics, dr_ui_feed
//   Animation's tick:  an_bake (AnimData.bake_pending, the incremental bake's slice), an_on_tick (the fighters' tick)
// The timers add about a tenth to the view. Time.get_ticks_usec on the web steps in 0.1 ms or finer, so read the means. A tick's
// part is summed over the frame's ticks (at x4 a frame often runs two or three). Node 24 built-ins only. No Godot, no browser.
// Owner: Rendering and Technical Art.
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const root = process.argv[2];
if (!root || !existsSync(join(root, 'project.godot'))) { console.error('usage: node docs/rendering/tools/prof-hook.mjs <scratch tree holding project.godot>'); process.exit(2); }
const applied = [], skipped = [];
const files = {};
const get = (f) => (files[f] ??= readFileSync(join(root, f), 'utf8'));
const once = (s, a) => s.split(a).length === 2;
// Replace anchor a with b in file f, as part `name`; required parts stop the hook when their anchor is missing.
function edit(f, name, a, b, required = false) {
  const s = get(f);
  if (!once(s, a)) {
    if (required) { console.error(`prof-hook: ${f}: the anchor for ${name} is missing or not once; nothing written`); process.exit(1); }
    skipped.push(name);
    return;
  }
  files[f] = s.replace(a, () => b);
  applied.push(name);
}
// Time one whole line (with its indent) as part `name`.
function wrap(f, name, line) {
  const ind = line.match(/^\t*/)[0];
  const v = '_q' + name.replace(/[^a-z0-9]/gi, '');
  edit(f, name, line + '\n', `${ind}var ${v}: int = Time.get_ticks_usec()\n${line}\n${ind}PaneWorld._pt("${name}", ${v})\n`);
}
// Close the stretch since the last mark (`_t0`) as part `name`, before line `line`.
const mark = (name) => `\t_pt("${name}", _t0)\n\t_t0 = Time.get_ticks_usec()\n`;

const PW = 'render/core/pane_world.gd', MAIN = 'render/core/main.gd', FC = 'render/tools/flash_capture.gd';
const FV = 'render/core/fighter_view.gd', PV = 'render/core/planet_view.gd', HOST = 'render/core/sim_host.gd', RA = 'render/anim/render_anim.gd';

// The core: the counters and the bench's row.
edit(PW, 'counters', 'static var _drawing: PaneWorld = null', 'static var PT: Dictionary = {}\nstatic var PT_SUM: Dictionary = {}\nstatic func _pt(k: String, t0: int) -> void:\n\tvar d: int = Time.get_ticks_usec() - t0\n\tPT[k] = int(PT.get(k, 0)) + d\n\tPT_SUM[k] = int(PT_SUM.get(k, 0)) + d\nstatic var _drawing: PaneWorld = null', true);
edit(FC, 'bench row', '"rgpu": RenderingServer.viewport_get_measured_render_time_gpu(rid), "tick": main.host.ticks,', '"rgpu": RenderingServer.viewport_get_measured_render_time_gpu(rid), "tick": main.host.ticks, "pt": PaneWorld.PT_SUM.duplicate(),', true);

// A pane's render, in stretches.
edit(PW, 'pane start', '\tvar S: SimState = host.S\n\tvar vp: Vector2 = get_viewport().get_visible_rect().size\n\tview_cam_x = cam_x\n', '\tvar _t0: int = Time.get_ticks_usec()\n\tvar S: SimState = host.S\n\tvar vp: Vector2 = get_viewport().get_visible_rect().size\n\tview_cam_x = cam_x\n', true);
edit(PW, 'pane_setup, pan_haze, sky_drive', '\t_pan_haze(host, a, cam_x, vp)\n\t_sky_drive(host, a, cam_x)\n', mark('pane_setup') + '\t_pan_haze(host, a, cam_x, vp)\n' + mark('pan_haze') + '\t_sky_drive(host, a, cam_x)\n' + mark('sky_drive'));
edit(PW, 'fore_low, view_cues', '\t_fore_low(host, a, cam_x, vp)\n\tplanet.set_calm(flash_calm)\n\t_view_cues(cam, vp)\n', '\t_fore_low(host, a, cam_x, vp)\n' + mark('fore_low') + '\tplanet.set_calm(flash_calm)\n\t_view_cues(cam, vp)\n' + mark('view_cues'));
edit(PW, 'pane_pre, planet_update', '\tplanet.update(S, cam_x, host.impact.heat, host.impact.heat_changed)\n\tplanet.cull_to(cam_rig, vis_plane)', mark('pane_pre') + '\tplanet.update(S, cam_x, host.impact.heat, host.impact.heat_changed)\n' + mark('planet_update') + '\tplanet.cull_to(cam_rig, vis_plane)');
edit(PW, 'planet_cull', '\tfor i in range(fighter_views.size()):\n\t\tvar v: FighterView = fighter_views[i]\n\t\tvar pose', mark('planet_cull') + '\tfor i in range(fighter_views.size()):\n\t\tvar v: FighterView = fighter_views[i]\n\t\tvar pose');
wrap(PW, 'fighter_view', '\t\tv.update(S, S.fighters[i], pose, vx, cam.z)');
edit(PW, 'fighters_update, occlusion, cues_after', '\t_occlusion(S, cam_x, vp)\n\t_lane_cues(host, a)\n\t_pair_mark(host, a)\n\t_sky_react(host, cam_x)\n\t_drawing = self', mark('fighters_update') + '\t_occlusion(S, cam_x, vp)\n' + mark('occlusion') + '\t_lane_cues(host, a)\n\t_pair_mark(host, a)\n\t_sky_react(host, cam_x)\n' + mark('cues_after') + '\t_drawing = self');
edit(PW, 'vfx_layer, beams', '\t_drawing = null\n\tbeams.update(S, cam_x, cam.z, host)\n', '\t_drawing = null\n' + mark('vfx_layer') + '\tbeams.update(S, cam_x, cam.z, host)\n' + mark('beams'));
edit(PW, 'particles', '\tparticles.update(host.fxv, host.impact, cam_x, cam.z, cam_rig.half_width(vp.x, RenderLook.Z_PARTICLES - focus_z), fighter_views)\n', '\tparticles.update(host.fxv, host.impact, cam_x, cam.z, cam_rig.half_width(vp.x, RenderLook.Z_PARTICLES - focus_z), fighter_views)\n\t_pt("particles", _t0)\n');

// Main's frame.
wrap(MAIN, 'hud_advance', '\tui_hud.advance(0.0 if host.paused else delta)');
wrap(MAIN, 'split_rig_frame', '\t\tsplit_frame = split_rig.frame(a)');
wrap(MAIN, 'present', '\t\tcompositor.present(split_frame)');
wrap(MAIN, 'host_advance', '\tvar n: int = host.advance(delta, vp.x, vp.y)');
wrap(MAIN, 'mv_far_land', '\t\tfar_land.step(RenderLook.FAR_MAP_STEP)');
wrap(MAIN, 'mv_ui_bridge', '\tUiSimBridge.patch(ui_hud, S, host.hub)   # the hub is read for the armed stance\'s badge (UI\'s bridge writes nothing to it)');
wrap(MAIN, 'mv_hud_key', '\tvar hk: Array = hud.redraw_key()');
wrap(MAIN, 'mv_sync_players', '\t_sync_players()');
edit(MAIN, 'mv_audio', '\tfor c in host.pending_cues:\n\t\taudio.play(c, view_cam_x, cam_rig.zoom)\n', '\tvar _qau: int = Time.get_ticks_usec()\n\tfor c in host.pending_cues:\n\t\taudio.play(c, view_cam_x, cam_rig.zoom)\n\tPaneWorld._pt("mv_audio", _qau)\n');
edit(MAIN, 'mv_view_total', '\tvar t2: int = Time.get_ticks_usec()\n', '\tvar t2: int = Time.get_ticks_usec()\n\tPaneWorld._pt("mv_view_total", t1)\n');
edit(MAIN, 'PROF lines (--frames runs)', '\tprint("gameplay hash at tick %d: %s" % [host.ticks, gh])', '\tfor k in PaneWorld.PT_SUM:\n\t\tprint("PROF %-18s mean %.3f ms/frame" % [k, float(PaneWorld.PT_SUM[k]) / 1000.0 / maxf(1.0, float(frames))])\n\tprint("gameplay hash at tick %d: %s" % [host.ticks, gh])');

// The fighter view.
wrap(FV, 'fv_anim_solve', '\t\tvar af: AnimFighter = RenderAnim.solve(S, f)');
wrap(FV, 'fv_anim_apply', '\t\t\tanim_body.apply(af.q, af.hips, af.curl, af.root_off)');
wrap(FV, 'fv_damage', '\t\t_damage(f, dt)');
wrap(FV, 'fv_pose_cue', '\t_pose_cue(T, m, th, front)');

// The planet's update.
wrap(PV, 'pv_ground', '\tground.update(S, heat, heat_changed)');
wrap(PV, 'pv_flight_arrive', '\tflight.arrive(S, _crowd)');
wrap(PV, 'pv_refresh', '\trefresh(S, false)');
wrap(PV, 'pv_flight_step', '\tflight.step(S, _crowd)');
wrap(PV, 'pv_startle', '\t_startle(S)');
wrap(PV, 'pv_trees', '\ttrees.update(S)   # the fellable trees\' states (tree_view.gd); the shader reads the ground under each foot');

// A tick's fx (SimHost.tick, after the sim's step).
wrap(HOST, 'fx_cam_step', '\tcam.camStep(S, S.dt, vw, vh)');
wrap(HOST, 'fx_fxv', '\tfxv.consume(S, vfx.reference_events(_without_fall_debris(S, S.out.fx) if vfx.enabled and vfx.destruction_enabled else S.out.fx))');
wrap(HOST, 'fx_impact', '\timpact.consume(S, S.out.fx)');
wrap(HOST, 'fx_audio_cues', '\tpending_cues.append_array(audio_cues.consume(S, S.out.fx))');
wrap(HOST, 'fx_drained', '\tdrained.emit(S.out.fx, lines)');
wrap(HOST, 'fx_vfx', '\tvfx.consume(S, S.out.fx)');
wrap(HOST, 'fx_flashes_due', '\tflashes_due.emit(S.out.fx)');
wrap(HOST, 'fx_ask_beams', '\t_ask_beams()');
wrap(HOST, 'fx_ask_hits', '\t_ask_hits()');

// The drain's listener (main._on_drained).
wrap(MAIN, 'dr_split_rig_step', '\t\tsplit_rig.step(host.S, vp.x, vp.y, events)');
wrap(MAIN, 'dr_planet_consume', '\tplanet.consume(events, host.S.T)');
wrap(MAIN, 'dr_camera_roll', '\t\tcamera_roll.consume(host.S, events, split_rig if compositor != null else null)   # the rig\'s story, once it has read the tick');
wrap(MAIN, 'dr_anim_consume', '\tRenderAnim.consume(host.S, events)');
wrap(MAIN, 'dr_ui_consume', '\tui_hud.consume_all(events)');
wrap(MAIN, 'dr_haptics', '\t_haptics_from_events(events)');
wrap(MAIN, 'dr_ui_feed', '\tUiSimBridge.feed(ui_hud, lines)');

// Animation's tick: the incremental bake's slice and the fighters' tick.
edit(RA, 'an_bake', '\t\t\t\tif AnimData.bake_pending() == 0:', '\t\t\t\tvar _qab: int = Time.get_ticks_usec()\n\t\t\t\tvar _bp: int = AnimData.bake_pending()\n\t\t\t\tPaneWorld._pt("an_bake", _qab)\n\t\t\t\tif _bp == 0:');
edit(RA, 'an_on_tick', '\t\t\t\tfor f in S.fighters:\n\t\t\t\t\tfighter(S, f).on_tick(float(e.dt), bool(e.frozen), S, f)\n', '\t\t\t\tvar _qat: int = Time.get_ticks_usec()\n\t\t\t\tfor f in S.fighters:\n\t\t\t\t\tfighter(S, f).on_tick(float(e.dt), bool(e.frozen), S, f)\n\t\t\t\tPaneWorld._pt("an_on_tick", _qat)\n');

for (const [f, s] of Object.entries(files)) writeFileSync(join(root, f), s);
console.log(`prof-hook: ${applied.length} parts applied to ${root}`);
if (skipped.length) console.log(`prof-hook: skipped (anchor missing or not once): ${skipped.join(', ')}`);
