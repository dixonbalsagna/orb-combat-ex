// SCRATCH HOOK (scratch export only): the input-latency scene `lat`. Player one is a keyboard human (the first key press claims the slot), player two the idle training dummy, set
// down 250 units apart. In this scene the hook does NOT step ticks: poll() runs the game's own frame (main.frame(delta) with the real elapsed time, so the sim runs the ticks a frame's
// time allows and the view is drawn at the interpolation point, as in play), optionally paced to 60 Hz (page flag lat60=1: a busy wait to the next 16.667 ms boundary, a stand-in for
// vsync, since headless Chrome runs animation frames unlocked). It records, for the driver (window.__latcmd = "dump" publishes window.__latdump):
//   keys   [t_ms, frame, ticks_before_frame, code, down]     when the game's _unhandled_input received the key (main.gd patch -> flashcap.on_key)
//   ticks  [tick, t_ms, frame, state, rush, queue, guardSince, dodgeTick, vx, ack_events]    one per sim tick, from SimHost.drained, player one's action state after the tick
//   frames [frame, t_ms_start, ticks_after, ticks_run, alpha, px]  one per drawn frame; px = how much the picture drawn in the PREVIOUS frame differs from the one before it
//          (a 80 x 45 grid of the root viewport's last rendered image, mean absolute difference over R, G, B)
// Apply after hook-perf.mjs (any other hook is fine).
import { readFileSync, writeFileSync } from 'node:fs';
const root = process.argv[2];
const p = root + '/render/tools/flash_capture.gd';
let s = readFileSync(p, 'utf8');

// 1. the scenario
s = s.replace('"mashdummy", "ring"', '"lat", "mashdummy", "ring"');
s = s.replace('"mashdummy": [false, true]', '"lat": [false, false], "mashdummy": [false, true]');
const a1 = '\t\t"ai":           # the real AI match, forms readied at 300 and 1500, a tier raised at 900';
if (!s.includes(a1)) throw new Error('anchor ai scenario');
s = s.replace(a1, '\t\t"lat":\n\t\t\tif t == 0:\n\t\t\t\t_lat_place(S)\n' + a1);

// 2. poll(): the lat scene runs the game's own frame
const a2 = '\tif int(st.get("pending", 0)) > 0';   // (hook-perf.mjs widens this line: "... or (auto and scenario != "")")
if (!s.includes(a2)) throw new Error('anchor poll');
s = s.replace(a2, '\tif scenario == "lat":\n\t\t_lat_frame()\n\t\treturn\n' + a2);

// 3. begin(): reset the records, listen to the ticks, read the pacing flag
const a3 = '\tmain.started = true';
if (!s.includes(a3)) throw new Error('anchor started');
s = s.replace(a3, '\tif scenario == "lat":\n\t\t_lat_begin()\n' + a3);

s += `

# ------------------------------------------------------------------ the latency scene (docs/perf/tools/latency-bench.mjs)
var _lat_keys: Array = []
var _lat_ticks: Array = []
var _lat_frames: Array = []
var _lat_fi: int = 0
var _lat_last_usec: int = 0
var _lat_pace: bool = false
var _lat_prev: PackedByteArray = PackedByteArray()
var _lat_placed: bool = false
var _lat_off: float = 0.0   # page clock (performance.now) minus Time.get_ticks_usec()/1000, ms


func _lat_begin() -> void:
	_lat_keys.clear()
	_lat_ticks.clear()
	_lat_frames.clear()
	_lat_fi = 0
	_lat_prev = PackedByteArray()
	_lat_last_usec = Time.get_ticks_usec()
	_lat_pace = _page_flag("lat60")
	_lat_off = float(JavaScriptBridge.eval("performance.now()", true)) - Time.get_ticks_usec() / 1000.0
	_lat_placed = false
	var host: SimHost = main.host
	if not host.drained.is_connected(_lat_tick):
		host.drained.connect(_lat_tick)


func _lat_place(S: SimState) -> void:
	var a = S.fighters[0]
	var b = S.fighters[1]
	b.x = SimWrap.wrap(a.x + (float(_page_kv("latd")) if _page_kv("latd") != "" else 250.0))
	for f in [a, b]:
		f.y = WorldTerrain.groundY(S, f.x) + 10.0
		f.vx = 0.0
		f.vy = 0.0


## main.gd's _unhandled_input hands every key here (scratch patch).
func on_key(code: String, down: bool) -> void:
	_lat_keys.append([Time.get_ticks_usec() / 1000.0, _lat_fi, main.host.ticks, code, down])


func _lat_tick(events: Array, _lines: Array) -> void:
	var host: SimHost = main.host
	var f = host.S.fighters[0]
	var acks: PackedStringArray = []
	for e in events:
		if str(e.type) == "press_ack":
			acks.append("ack")
	var ex = host.S.dirS.ex
	var exs: String = "" if ex == null else "%s/%s/%.3f/%d" % [ex.tpl, ex.kind, ex.t, ex.beats.size()]
	_lat_ticks.append([host.ticks, Time.get_ticks_usec() / 1000.0, _lat_fi, str(f.state), f.rush != null, f.act.queue.size(), f.act.guardSince, f.act.dodgeTick, snappedf(f.vx, 1.0), ",".join(acks), exs])


func _lat_frame() -> void:
	var host: SimHost = main.host
	if not _lat_placed:
		_lat_placed = true
	# pacing: start the frame on the next 16.667 ms boundary after the last frame's start
	if _lat_pace:
		var target: int = _lat_last_usec + 16667
		while Time.get_ticks_usec() < target:
			pass
	var t0: int = Time.get_ticks_usec()
	var delta: float = minf(float(t0 - _lat_last_usec) / 1000000.0, 0.25) if _lat_last_usec > 0 else SimConst.DT
	_lat_last_usec = t0 if not _lat_pace else maxi(t0, _lat_last_usec + 16667)
	# how much did the picture drawn in the previous frame differ from the one before it
	var px: float = -1.0
	var tex := main.get_viewport().get_texture()
	if tex != null and _lat_fi > 0:
		var img: Image = tex.get_image()
		if img != null:
			img.convert(Image.FORMAT_RGB8)
			for _k in range(3):
				img.shrink_x2()    # area-averaged: 1280 x 720 -> 160 x 90
			var d: PackedByteArray = img.get_data()
			var w: int = img.get_width()
			var hh: int = img.get_height()
			if _lat_prev.size() == d.size():
				# the middle of the picture, where the pair and the ground are: columns 25 to 75 percent, rows 25 to 85 percent
				var sum: int = 0
				var n: int = 0
				for yy in range(hh * 25 / 100, hh * 85 / 100):
					var i: int = (yy * w + w * 25 / 100) * 3
					for _xx in range(w * 25 / 100, w * 75 / 100):
						sum += absi(int(d[i]) - int(_lat_prev[i])) + absi(int(d[i + 1]) - int(_lat_prev[i + 1])) + absi(int(d[i + 2]) - int(_lat_prev[i + 2]))
						n += 3
						i += 3
				px = float(sum) / float(maxi(n, 1))
			_lat_prev = d
	if _lat_frames.size() > 0:
		_lat_frames[_lat_frames.size() - 1].append(px)   # the previous frame's own picture: its change
	_lat_fi += 1
	if scenario != "":
		drive(scenario, host.ticks, host.S)
	var before: int = host.ticks
	main.frame(delta)
	_lat_frames.append([_lat_fi, t0 / 1000.0, host.ticks, host.ticks - before, snappedf(host.alpha(), 0.001)])
	var cmd: String = str(JavaScriptBridge.eval("(() => { const c = window.__latcmd || ''; window.__latcmd = ''; return c; })()", true))
	if cmd == "dump":
		JavaScriptBridge.eval("window.__latdump = %s;" % JSON.stringify({"keys": _lat_keys, "ticks": _lat_ticks, "frames": _lat_frames, "off": _lat_off}), true)
		_lat_keys.clear()
		_lat_ticks.clear()
		_lat_frames.clear()
`;
writeFileSync(p, s);

// 4. main.gd: hand every key event to the hook
const m = root + '/render/core/main.gd';
let t = readFileSync(m, 'utf8');
const k = '\t\tvar code: String = RenderKeys.code(e)\n\t\tget_viewport().set_input_as_handled()';
if (!t.includes(k)) throw new Error('anchor main _unhandled_input');
t = t.replace(k, '\t\tvar code: String = RenderKeys.code(e)\n\t\tif flashcap != null and not e.echo:\n\t\t\tflashcap.on_key(code, e.pressed)\n\t\tget_viewport().set_input_as_handled()');
writeFileSync(m, t);
console.log('latency hook applied');
