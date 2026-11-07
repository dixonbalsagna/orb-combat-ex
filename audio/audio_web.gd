class_name AudioWeb
extends RefCounted
## Browser-direct one-shots (docs/audio/crackle.md). In the web build without threads the game mixes its sound on the main thread
## and hands it to the browser's audio worklet through a small ring: a frame over about 40 ms starves it and the worklet throws away
## whole blocks of sound, which is a click (docs/perf/impact-stutter.md). A sound the BROWSER plays itself is not in that ring: once
## started it plays on the audio thread whatever the page does. So the web build plays every short one-shot cue (the hits, the
## grunts, the pings and ticks) as a plain Web Audio AudioBufferSource in a small graph of our own, and keeps the Godot players for
## what loops or is moved after it starts (the beam struggle's beds, the coil, the ambience beds).
##
## Godot's own Sample playback mode is not used: it plays through the engine's bus graph, reads silent at the destination on this
## project's build in headless Chrome and Opera GX (docs/tools/preview.md, "Sound modes"), and skips the bus effects (the muffle, the
## limiter). Here the effects are in the graph: a low-pass for the muffled buses, the buses' gains with the player's trims and the
## ducks, a limiter and a soft clip at the end.
##
## Only on the web, only with the page's JavaScript bridge, and off with `?webvoices=0` in the address (the old path, for comparing).
## Everywhere else this class does nothing and AudioVoices plays as it always did.

## The page-side player (plain Web Audio, ES5). Installed once by `install()` as `window.__aweb`; the check
## (audio/tools/web_voices_check.mjs) runs this same text in a real browser through Tools' launcher.
const JS_SOURCE := """
(function () {
  if (window.__aweb) { return; }
  var AC = window.AudioContext || window.webkitAudioContext;
  var W = window.__aweb = { ready: false, running: false, started: 0, refused: 0, notrunning: 0, missing: 0, uploads: 0, last: '', rec: null, mono: false, starts: [] };
  if (!AC) { return; }
  var ctx, bufs = {}, buses = {}, voices = [], master, comp, clip;
  try {
    ctx = new AC({ latencyHint: 'interactive' });
  } catch (e) { W.last = 'no context: ' + e; return; }
  W.ctx = ctx;
  master = ctx.createGain();
  comp = ctx.createDynamicsCompressor();
  comp.threshold.value = -6; comp.knee.value = 3; comp.ratio.value = 10; comp.attack.value = 0.001; comp.release.value = 0.12;
  // a soft clip behind the compressor for what its 1 ms attack lets through: the shaper reads -1..1, so the signal is halved first and the curve spans -2..2
  var pre = ctx.createGain(); pre.gain.value = 0.5;
  clip = ctx.createWaveShaper();
  var curve = new Float32Array(4097), i, x;
  for (i = 0; i < curve.length; i++) {
    x = ((i / 2048) - 1) * 2;
    curve[i] = (Math.abs(x) <= 0.8) ? x : (x < 0 ? -1 : 1) * (0.8 + 0.17 * Math.tanh((Math.abs(x) - 0.8) / 0.17));
  }
  clip.curve = curve;
  master.connect(comp); comp.connect(pre); pre.connect(clip); clip.connect(ctx.destination);
  function wake(e) {
    if (e && e.isTrusted === false) { return; }
    if (ctx.state !== 'running' && ctx.state !== 'closed') { try { var p = ctx.resume(); if (p && p.catch) { p.catch(function (err) { W.last = 'resume refused: ' + (err && err.name || err); }); } } catch (x) { W.last = String(x); } }
  }
  ['pointerdown', 'mousedown', 'keydown', 'touchend', 'click'].forEach(function (ev) { window.addEventListener(ev, wake, true); });
  document.addEventListener('visibilitychange', function () { if (!document.hidden) { wake(null); } });
  ctx.addEventListener('statechange', function () { W.running = ctx.state === 'running'; });
  W.running = ctx.state === 'running';
  W.ready = true;
  W.bus = function (name, lin) {
    var g = buses[name];
    if (!g) { g = buses[name] = ctx.createGain(); g.connect(master); }
    g.gain.setTargetAtTime(lin, ctx.currentTime, 0.004);
  };
  W.master = function (lin) { master.gain.setTargetAtTime(lin, ctx.currentTime, 0.004); };
  W.setMono = function (on) { W.mono = !!on; };
  W.put = function (key, data, rate) {
    var ab = data && data.buffer && data.buffer instanceof ArrayBuffer ? data.buffer : data;
    var bo = data && data.byteOffset ? data.byteOffset : 0;
    var n = (data && data.byteLength !== undefined ? data.byteLength : ab.byteLength) >> 1;
    var s = new Int16Array(ab, bo, n);
    var b = ctx.createBuffer(1, n, rate), f = b.getChannelData(0), k;
    for (k = 0; k < n; k++) { f[k] = s[k] / 32768; }
    bufs[key] = b; W.uploads++;
  };
  W.putB64 = function (key, s, rate) {
    var bin = atob(s), n = bin.length >> 1, b = ctx.createBuffer(1, n, rate), f = b.getChannelData(0), k, v;
    for (k = 0; k < n; k++) { v = bin.charCodeAt(2 * k) | (bin.charCodeAt(2 * k + 1) << 8); if (v > 32767) { v -= 65536; } f[k] = v / 32768; }
    bufs[key] = b; W.uploads++;
  };
  W.has = function (key) { return !!bufs[key]; };
  function kill(slot, fade) {
    var v = voices[slot];
    if (!v) { return; }
    voices[slot] = null;
    try {
      if (fade > 0) { v.g.gain.cancelScheduledValues(ctx.currentTime); v.g.gain.setTargetAtTime(0, ctx.currentTime, fade / 3000); v.src.stop(ctx.currentTime + fade / 1000 + 0.01); }
      else { v.src.stop(); }
    } catch (e) { /* already ended */ }
  }
  W.play = function (slot, key, gain, pan, rate, bus, lp, group) {
    if (!ctx || ctx.state !== 'running') { W.notrunning++; return 0; }
    var b = bufs[key];
    if (!b) { W.missing++; return 0; }
    kill(slot, 0.004 * 1000);
    var src = ctx.createBufferSource(), node = src, g = ctx.createGain(), out;
    src.buffer = b; src.playbackRate.value = rate;
    if (lp > 0) { var f = ctx.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = lp; f.Q.value = 0.7; src.connect(f); node = f; }
    g.gain.value = gain;
    node.connect(g);
    out = g;
    if (ctx.createStereoPanner) { var p = ctx.createStereoPanner(); p.pan.value = W.mono ? 0 : pan; g.connect(p); out = p; }
    var busNode = buses[bus] || master;
    out.connect(busNode);
    var v = { src: src, g: g, group: group };
    voices[slot] = v;
    src.onended = function () { if (voices[slot] === v) { voices[slot] = null; } try { src.disconnect(); g.disconnect(); if (node !== src) { node.disconnect(); } if (out !== g) { out.disconnect(); } } catch (e) { /* gone */ } };
    src.start();
    W.started++;
    if (W.starts.length < 600) { W.starts.push(performance.now()); }
    return 1;
  };
  W.stopSlot = function (slot, fadeMs) { kill(slot, fadeMs); };
  W.stopGroup = function (group, fadeMs) {
    var n = 0, s;
    for (s = 0; s < voices.length; s++) { if (voices[s] && voices[s].group === group) { kill(s, fadeMs); n++; } }
    return n;
  };
  W.status = function () {
    return ctx.state + ' t=' + ctx.currentTime.toFixed(2) + ' ' + ctx.sampleRate + ' Hz out ' + (ctx.outputLatency || 0).toFixed(3) + ' s | web voices started ' + W.started + ' not running ' + W.notrunning + ' missing ' + W.missing + ' buffers ' + W.uploads + (W.last ? ' | ' + W.last : '');
  };
  // Tests only: record the end of the graph on the audio thread (an AudioWorklet), so a stalled page does not make a hole in the recording.
  W.record = function () {
    if (!ctx.audioWorklet) { return Promise.resolve(false); }
    if (W.rec && W.rec.node) { try { W.rec.node.disconnect(); } catch (e) { /* gone */ } }
    var rec = W.rec = { L: [], R: [], rate: ctx.sampleRate, node: null };
    var load = W.recModule;
    if (!load) {
      var code = "class R extends AudioWorkletProcessor { process(i) { var c = i[0]; if (c && c[0]) { this.port.postMessage([c[0].slice(), (c[1] || c[0]).slice()]); } return true; } } registerProcessor('aweb-rec', R);";
      load = W.recModule = ctx.audioWorklet.addModule(URL.createObjectURL(new Blob([code], { type: 'text/javascript' })));
    }
    return load.then(function () {
      var n = new AudioWorkletNode(ctx, 'aweb-rec', { numberOfInputs: 1, numberOfOutputs: 1, outputChannelCount: [2] });
      n.port.onmessage = function (e) { rec.L.push(e.data[0]); rec.R.push(e.data[1]); };
      clip.connect(n);
      var z = ctx.createGain(); z.gain.value = 0; n.connect(z); z.connect(ctx.destination);
      rec.node = n;
      return true;
    });
  };
})();
"""

var ok: bool = false             # installed and the page's player is there
var _js = null                   # the page's window.__aweb (a JavaScriptObject; untyped so its methods are called by name)
var _sent: Dictionary = {}       # "sound#variant" -> true once the page has the samples
var started: int = 0
var refused: int = 0
var _running_at: int = -1000000


## Install the page-side player. False off the web, with ?webvoices=0, or without the JavaScript bridge.
func install() -> bool:
	if not OS.has_feature("web"):
		return false
	var off = JavaScriptBridge.eval("(function(){try{return new URLSearchParams(location.search).get('webvoices')==='0'}catch(e){return false}})()", true)
	if off:
		return false
	JavaScriptBridge.eval(JS_SOURCE, true)
	_js = JavaScriptBridge.get_interface("__aweb")
	ok = _js != null and bool(_js.ready)
	return ok


## True when a one-shot cue may be played by the page now: the player is there and its context is running (a suspended context
## would queue the sound and dump it at the first click).
func running() -> bool:
	return ok and bool(_js.running)


## Make sure the page has this stream's samples (16-bit mono PCM, as the bank's AudioStreamWAV holds them), once. They go as a base64 string:
## the JavaScript bridge passes numbers, strings and objects, not byte arrays.
func ensure(key: String, stream: AudioStreamWAV) -> void:
	if _sent.has(key):
		return
	_sent[key] = true
	_js.putB64(key, Marshalls.raw_to_base64(stream.data), stream.mix_rate)


func play(slot: int, key: String, gain: float, pan: float, rate: float, bus: String, lowpass_hz: float, group: String) -> bool:
	var r = _js.play(slot, key, gain, pan, rate, bus, lowpass_hz, group)
	if int(r) == 1:
		started += 1
		return true
	refused += 1
	return false


func stop_slot(slot: int, fade_ms: int = 4) -> void:
	if ok:
		_js.stopSlot(slot, fade_ms)


func stop_group(group: String, fade_ms: int) -> void:
	if ok:
		_js.stopGroup(group, fade_ms)


func set_bus(name: String, linear: float) -> void:
	if ok:
		_js.bus(name, linear)


func set_master(linear: float) -> void:
	if ok:
		_js.master(linear)


func set_mono(on: bool) -> void:
	if ok:
		_js.setMono(on)


## One line for the page's audio log (AudioVoices.status_line).
func status() -> String:
	if not ok:
		return "web voices off"
	return str(_js.status())
