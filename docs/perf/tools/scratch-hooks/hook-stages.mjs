// SCRATCH HOOK (applied only to a scratch tree made by docs/perf/tools/make-stage-tree.mjs; never to the repo): per-stage timers for a whole frame, one CSV row per frame.
//   node hook-stages.mjs <tree>
// Adds render/core/perf_t.gd (PerfT: stage microseconds, counters, gauges, a per-frame row) and wraps single statements with Time.get_ticks_usec() pairs: the sim's sub-steps (s_*), the host's event consumers (h_*),
// main's frame and render_view (f_*, r_*), PaneWorld.render (r_*), PlanetView.update and refresh (p_*), GroundField (g_*). A timer is INCLUSIVE of what its statement calls (s_dig holds s_relax, s_fillopen ...).
// main.gd gets _perf_flush (the gauges: craters, water windows, fastest fighter, launched bodies, camera speed, buildings swept) and, with --perfout=<file>, writes the rows as CSV when the run ends.
import { readFileSync, writeFileSync } from 'node:fs';

const root = process.argv[2];
if (!root) throw new Error('usage: node hook-stages.mjs <tree>');
let uid = 0;
const files = new Map();
const text = (f) => { if (!files.has(f)) files.set(f, readFileSync(`${root}/${f}`, 'utf8')); return files.get(f); };
const put = (f, s) => files.set(f, s);
const count = (s, sub) => s.split(sub).length - 1;

/** Wraps the single line whose text (after its tabs) starts with `start`: a timer pair around it. `exact` (tabs and all) picks one of several. */
function wrap(f, start, key, exact = false) {
  const s = text(f);
  const lines = s.split('\n');
  const at = [];
  lines.forEach((l, i) => { if (exact ? l.startsWith(start) : l.trimStart().startsWith(start)) at.push(i); });
  if (at.length !== 1) throw new Error(`${f}: "${start.replace(/\t/g, '\\t').slice(0, 70)}" found ${at.length} times, wanted 1`);
  const i = at[0];
  const ind = lines[i].match(/^\t*/)[0];
  const v = `_pt${++uid}`;
  lines.splice(i, 1, `${ind}var ${v}: int = Time.get_ticks_usec()`, lines[i], `${ind}PerfT.t("${key}", ${v})`);
  put(f, lines.join('\n'));
}

/** A function renamed to NAME_i with a timed wrapper of the same name and signature in front of it. */
function wrapFunc(f, name, params, ret, call, key, inst = false) {
  const s = text(f);
  const pre = inst ? '' : 'static ';
  const def = `${pre}func ${name}(${params})${ret ? ` -> ${ret}` : ''}:`;
  if (count(s, def) !== 1) throw new Error(`${f}: ${def.slice(0, 80)} found ${count(s, def)} times`);
  const isVoid = ret === 'void';
  const wrapper = `${def}\n\tvar _pt: int = Time.get_ticks_usec()\n\t${isVoid ? '' : 'var _r = '}${name}_i(${call})\n\tPerfT.t("${key}", _pt)\n\tPerfT.n("n_${key}")\n${isVoid ? '' : '\treturn _r\n'}\n\n`;
  put(f, s.replace(def, () => wrapper + def.replace(`func ${name}(`, `func ${name}_i(`)));
}

function sub(f, from, to) {
  const s = text(f);
  if (count(s, from) !== 1) throw new Error(`${f}: anchor found ${count(s, from)} times: ${from.slice(0, 70)}`);
  put(f, s.replace(from, () => to));
}

// ---- the sim ----
const SIM = 'sim/core/sim.gd';
wrap(SIM, 'SimControl.control(S, S.fighters[k]', 's_control');
wrap(SIM, 'SimFighter.stepFighter(S, f, dt)', 's_fighters');
wrap(SIM, 'DirExchange.dirUpdate(S, dt)', 's_director');
wrap(SIM, 'DirBeam.beamStep(S, dt)', 's_beam');
wrap(SIM, 'SimShots.step(S, dt)', 's_shots');
wrap(SIM, 'WorldWater.step(S)', 's_water');
wrap(SIM, 'SimMood.tick(S)', 's_mood');
wrap(SIM, 'WorldCollateral.tick(S)', 's_collateral');
const WAT = 'sim/world/water.gd';
wrap(WAT, 'WorldAfter.step(S)', 's_after');
wrap(WAT, 'WorldFire.step(S)', 's_fire');
wrap(WAT, 'WorldLakes.refill(S, c0, cols)', 's_lakerefill');
wrap(WAT, 'WorldFill.open(S, c0, cols)', 's_fillopen');
wrapFunc('sim/world/fill.gd', 'stepWindow', 'S: SimState, w: Array', 'bool', 'S, w', 's_fillwin');
const CR = 'sim/world/crater.gd';
wrapFunc(CR, 'dig', 'S: SimState, x: float, energy: float, cause, kind: String, dirx: float = 0.0, vert: float = 1.0, special: bool = false, z: float = NAN, shape: PackedFloat64Array = PackedFloat64Array()', '',
  'S, x, energy, cause, kind, dirx, vert, special, z, shape', 's_dig');
wrapFunc(CR, 'relax', 'S: SimState, c0: int, half: int, freezeFrom: int = 0, freezeDir: int = 0', 'float', 'S, c0, half, freezeFrom, freezeDir', 's_relax');
wrap(CR, '_digNeighbours(S, rec, k,', 's_dignbr');

// ---- the host's tick ----
const HOST = 'render/core/sim_host.gd';
wrap(HOST, 'cam.camStep(S, S.dt, vw, vh)', 'h_camstep');
wrap(HOST, 'fxv.consume(S, vfx.reference_events(', 'h_fxv');
wrap(HOST, 'impact.consume(S, S.out.fx)', 'h_impact');
wrap(HOST, 'pending_cues.append_array(audio_cues.consume(S, S.out.fx))', 'h_audiocues');
wrap(HOST, 'drained.emit(S.out.fx, lines)', 'h_drained');
wrap(HOST, 'vfx.consume(S, S.out.fx)', 'h_vfx');
wrap(HOST, 'flashes_due.emit(S.out.fx)', 'h_flashes');
wrap(HOST, '_ask_beams()', 'h_flashask_b');
wrap(HOST, '_ask_hits()', 'h_flashask_h');
wrap(HOST, 'hub.on_events(S.out.fx)', 'h_hub');
sub(HOST, '\tS.out.fx.clear()\n\tif fxv.shake > 0.5:', '\tPerfT.n("n_fx", S.out.fx.size())\n\tS.out.fx.clear()\n\tif fxv.shake > 0.5:');

// ---- main: drained consumers, the frame, render_view ----
const MAIN = 'render/core/main.gd';
wrap(MAIN, 'split_rig.step(host.S, vp.x, vp.y, events)', 'd_splitrig');
wrap(MAIN, 'planet.consume(events, host.S.T)', 'd_planet');
wrap(MAIN, 'camera_roll.consume(host.S, events,', 'd_roll');
wrap(MAIN, 'RenderAnim.consume(host.S, events)', 'd_anim');
wrap(MAIN, 'ui_hud.consume_all(events)', 'd_ui');
wrap(MAIN, 'ui_hud.consume_all(barks.step(host.S, events))', 'd_barks');
wrap(MAIN, '_haptics_from_events(events)', 'd_haptics');
wrap(MAIN, 'UiSimBridge.feed(ui_hud, lines)', 'd_feed');
wrap(MAIN, 'var n: int = host.advance(delta, vp.x, vp.y)', 'f_advance');
sub(MAIN, '\t_sync_players()\n\trender_view(host.alpha())\n', '\t_sync_players()\n\tvar _ptrv: int = Time.get_ticks_usec()\n\trender_view(host.alpha())\n\tPerfT.t("f_render", _ptrv)\n');
wrap(MAIN, 'ui_hud.advance(0.0 if host.paused else delta)', 'f_uihud');
wrap(MAIN, 'audio.play(c, view_cam_x, cam_rig.zoom)', 'f_audioplay');
wrap(MAIN, 'far_land.step(RenderLook.FAR_MAP_STEP)', 'r_farmap');
wrap(MAIN, 'split_frame = split_rig.frame(a)', 'r_splitrig');
wrap(MAIN, 'panes[i].render(host, a, split_frame.cam_x[i]', 'r_panes');
wrap(MAIN, 'pane.render(host, a, host.camera_x(a)', 'r_panes');
wrap(MAIN, 'compositor.present(split_frame)', 'r_present');
wrap(MAIN, 'UiSimBridge.patch(ui_hud, S, host.hub)', 'r_uibridge');
sub(MAIN, '\t_record(wall, n, (t1 - t0) / 1000.0, (t2 - t1) / 1000.0)\n', '\t_record(wall, n, (t1 - t0) / 1000.0, (t2 - t1) / 1000.0)\n\t_perf_flush(wall, n)\n');
sub(MAIN, 'func _ready() -> void:\n\targs = parse_args()\n', 'func _ready() -> void:\n\targs = parse_args()\n\tif args.has("vpw"):\n\t\tget_window().size = Vector2i(int(args["vpw"]), int(args.get("vph", 720)))   # headless keeps a 64x64 window otherwise\n');
sub(MAIN, 'func _finish() -> void:\n','func _finish() -> void:\n\tif args.has("perfout"):\n\t\tPerfT.write(String(args["perfout"]))\n');
put(MAIN, text(MAIN).replace(/\s*$/, '') + `


## SCRATCH (docs/perf stage timers): the frame's gauges, then the row.
var _pf_cam: float = 0.0


func _perf_flush(wall: float, n: int) -> void:
	var S: SimState = host.S
	PerfT.g("wall_ms", wall)
	PerfT.g("ticks", n)
	PerfT.g("tick_us", host.tick_usec if n > 0 else 0)
	PerfT.g("fx_us", host.fx_usec if n > 0 else 0)
	PerfT.g("craters", S.craters.size())
	PerfT.g("fillwin", S.waterWin.size())
	var vmax: float = 0.0
	var nl: int = 0
	for f in S.fighters:
		vmax = maxf(vmax, sqrt(f.vx * f.vx + f.vy * f.vy))
		if f.state == "launched":
			nl += 1
	PerfT.g("vmax", vmax)
	PerfT.g("launched", nl)
	var dx: float = SimWrap.sdx(_pf_cam, view_cam_x)
	_pf_cam = view_cam_x
	PerfT.g("cam_dx", dx)
	PerfT.g("swept", pane.planet.swept)
	PerfT.g("g_full", pane.planet.ground.full_rebuilds)
	PerfT.g("parts", particles.count)
	PerfT.g("tick", host.ticks)
	PerfT.g("ring", 0.0 if S.planetRing.is_empty() else 1.0)
	PerfT.g("nc", SimConst.NC)
	PerfT.g("tier", maxf(S.fighters[0].tier, S.fighters[1].tier))
	PerfT.g("draws", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	PerfT.g("rcpu", RenderingServer.viewport_get_measured_render_time_cpu(get_viewport().get_viewport_rid()) + RenderingServer.get_frame_setup_time_cpu())
	PerfT.g("rgpu", RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()))
	PerfT.flush()
`);

// ---- PaneWorld.render ----
const PW = 'render/core/pane_world.gd';
wrap(PW, 'cam_rig.frame(cam.y, cam.z, jitter, vp.y, pitch, focus_z)', 'r_camrig');
wrap(PW, '_pan_haze(host, a, cam_x, vp)', 'r_panhaze');
wrap(PW, '_sky_drive(host, a, cam_x)', 'r_skydrive');
wrap(PW, '_fore_low(host, a, cam_x, vp)', 'r_forelow');
wrap(PW, '_view_cues(cam, vp)', 'r_viewcues');
wrap(PW, 'var sp: PackedFloat64Array = src.view_span(cam_rig, cam_x, planet)', 'r_viewspan');
wrap(PW, 'planet.see(sp)', 'r_see');
wrap(PW, 'src.see_more(S, sp)', 'r_see');
wrap(PW, 'planet.update(S, cam_x, host.impact.heat, host.impact.heat_changed)', 'r_planetupdate');
wrap(PW, 'planet.cull_to(cam_rig, vis_plane)', 'r_cull');
wrap(PW, 'v.update(S, S.fighters[i], pose, vx, cam.z)', 'r_fighters');
wrap(PW, '_occlusion(S, cam_x, vp)', 'r_occlusion');
wrap(PW, 'vfx_layer.update(host, a, cam_x, cam.z, vp.x)', 'r_vfxlayer');
wrap(PW, 'beams.update(S, cam_x, cam.z, host)', 'r_beams');
wrap(PW, 'particles.update(host.fxv, host.impact, cam_x, cam.z,', 'r_particles');

// ---- PlanetView.update and refresh ----
const PV = 'render/core/planet_view.gd';
wrap(PV, 'ground.update(S, heat, heat_changed)', 'p_ground');
wrap(PV, `\tflight.arrive(S, _crowd)`, 'p_flightarr', true);
wrap(PV, 'refresh(S, false)', 'p_refresh');
wrap(PV, `\tflight.step(S, _crowd)`, 'p_flightstep', true);
wrap(PV, '_startle(S)', 'p_startle');
wrap(PV, '_water_show(S)', 'p_watershow', false);
wrap(PV, 'wf.apply(_water_mat)', 'p_wfapply');
wrap(PV, '_visit(S, bi, dirty, dchg, force)', 'p_visit');
wrap(PV, '_visit(S, bi, dirty, dchg, false)', 'p_visit');
wrap(PV, 'var list: PackedInt32Array = _visit_list(S, dirty, dchg)', 'p_visitlist');
sub(PV, `\t_grow_pass(S)\n\ttrees.update(S)`, `\tvar _ptg: int = Time.get_ticks_usec()\n\t_grow_pass(S)\n\tPerfT.t("p_grow", _ptg)\n\ttrees.update(S)`);
wrap(PV, 'trees.update(S)', 'p_trees');
wrap(PV, 'props.update(S)', 'p_props');
sub(PV, `\t_upload_cuts()\n\tif dchg:`, `\tvar _ptc: int = Time.get_ticks_usec()\n\t_upload_cuts()\n\tPerfT.t("p_cuts", _ptc)\n\tif dchg:`);

// ---- GroundField ----
const GF = 'render/core/ground_field.gd';
wrap(GF, '\t\t\t\t\t_g_col(S, i)', 'g_gcol', true);
wrap(GF, '\t\t_shore_near(S, moved)', 'g_shore', true);
wrap(GF, '\t\t_upload(S, cchg)', 'g_upload', true);
wrap(GF, '\t\t_upload_hot(S)', 'g_uphot', true);
wrap(GF, '\t\t_rubble_depths(S)', 'g_rubble', true);
wrap(GF, 'var bytes: PackedByteArray = S.base.to_byte_array()', 'g_concat');
wrap(GF, 'img.set_data(tw, ROWS * rpl, false, Image.FORMAT_RF, bytes)', 'g_setdata');
wrap(GF, '\ttex.update(img)', 'g_texupdate', true);
wrapFunc(GF, 'rebuild', 'S: SimState', 'void', 'S', 'g_rebuild', true);

// ---- PerfT ----
writeFileSync(`${root}/render/core/perf_t.gd`, `class_name PerfT
extends RefCounted
## SCRATCH (docs/perf stage timers; never in the repo): this frame's stage microseconds, counters and gauges, one row a frame.

static var cur: Dictionary = {}
static var rows: Array = []


static func t(k: String, t0: int) -> void:
	cur[k] = int(cur.get(k, 0)) + Time.get_ticks_usec() - t0


static func n(k: String, v: float = 1.0) -> void:
	cur[k] = float(cur.get(k, 0.0)) + v


static func g(k: String, v: float) -> void:
	cur[k] = v


static func flush() -> void:
	rows.append(cur)
	cur = {}


static func write(path: String) -> void:
	var keys: Dictionary = {}
	for r in rows:
		for k in r:
			keys[k] = true
	var ks: Array = keys.keys()
	ks.sort()
	var out: PackedStringArray = PackedStringArray(["frame," + ",".join(PackedStringArray(ks))])
	for i in range(rows.size()):
		var parts: PackedStringArray = PackedStringArray([str(i)])
		for k in ks:
			parts.append(str(rows[i].get(k, 0)))
		out.append(",".join(parts))
	var text: String = "\\n".join(out) + "\\n"
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__perfcsv = " + JSON.stringify(text) + ";", true)   # the driver reads it
		return
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
`);
for (const [f, s] of files) writeFileSync(`${root}/${f}`, s);
console.log('stage hook applied to', root, '(', uid, 'timers )');
