// The black box for Orb's first play (the EP, 2026-11-01): it records the presses and the seed on this PC, and after the match offers three optional questions and a file to save. Read-only, no network, nothing leaves the PC, and it cannot
// affect the sim. Two parts, both for the PRIVATE preview page only (a local page, `?blackbox=1`, on by default there):
//
//   1. sim_host.gd (scratch tree only): three one-line hooks and some appended functions. They READ the intents the host already built, the seed, the setup and the AI toggles into a dictionary in the project's own replay format
//      (SimReplay, "meridian-replay"), and publish its JSON text to `window.__bb_replay`. The sim is stepped by the very same `SimCore.step(S, inputs)` with the very same `inputs`; nothing here writes to the sim state, draws a
//      random number or changes a tick; with `bb_on` false (no word) every hook falls straight through.
//   2. the page's index.html: a small script that, when the match is over, shows a card with three optional questions and a "Save my match file" button (a download to the player's own Downloads folder, nothing is sent). A copy of
//      the last match also sits in the browser's own localStorage so a closed tab can still offer it next time. No fetch, no XHR, no beacon, no socket.
//
// The saved file plays back through the existing replay path: `node tools/preview/blackbox-verify.mjs <file> --tree <stack tree>` re-runs it headless (SimReplay.play) and says whether it reproduces to the last tick.
import { createHash } from 'node:crypto';

const HOOKS = [
  { name: 'the match start (the seed, the AI flags and the setup it was started with)', from: '\tsetup_used = su.duplicate(true)\n', to: '\tsetup_used = su.duplicate(true)\n\t_bb_arm(seed, ai, su)\n' },
  { name: 'the tick\'s one step', from: '\tif SimCore.step(S, inputs):\n', to: '\tif _bb_step(inputs):\n' },
  { name: 'an AI toggle', from: '\tSimCore.toggleAI(S, idx)\n', to: '\t_bb_toggle(idx)\n\tSimCore.toggleAI(S, idx)\n' },
];

export const HOST_FUNCS = [
  '',
  '',
  '## Scratch (tools/preview): the black box (?blackbox=1, a local page only; see tools/preview/blackbox.mjs). It only READS what the host already has and keeps it in a replay dictionary (SimReplay\'s format);',
  '## the sim is stepped by the same SimCore.step with the same inputs. Off (bb_on false) every hook falls through.',
  'var bb_on: bool = false',
  'var _bb: Dictionary = {}',
  'var _bb_last: Array = []',
  'var _bb_last2: Array = []',
  'var _bb_seed: int = 0',
  'var _bb_ai: Dictionary = {}',
  'var _bb_su: Dictionary = {}',
  'var _bb_armed: bool = false',
  'var _bb_done: bool = false',
  'var _bb_fr: int = -1',
  '',
  '',
  'func _bb_arm(seed_: int, ai_: Dictionary, su_: Dictionary) -> void:',
  '\tif not bb_on:',
  '\t\treturn',
  '\tif not _bb.is_empty() and not _bb_done and int(_bb.ticks) > 0:   # a match left before its KO: the record is published as it stands, then the new match starts its own',
  '\t\t_bb_publish(false, true)',
  '\t_bb_seed = seed_',
  '\t_bb_ai = ai_.duplicate(true)',
  '\t_bb_su = su_.duplicate(true)',
  '\t_bb_armed = true',
  '\t_bb_done = false',
  '\t_bb = {}',
  '',
  '',
  'func _bb_begin() -> void:',
  '\tvar ai: Dictionary = {}',
  '\tfor k in range(S.fighters.size()):',
  '\t\tai["p%d" % (k + 1)] = S.fighters[k].ai != null   # as SimReplay.recorder does: the state the match was started in (read before any toggle of this match)',
  '\t_bb = {"format": SimReplay.FORMAT, "v": SimReplay.V, "intent": SimIntent.VERSION, "data": SimReplay.dataHash(_bb_su), "seed": _bb_seed, "setup": _bb_su.duplicate(true), "ai": ai,',
  '\t\t"ticks": 0, "inputs": [], "toggles": [], "checkpoints": [], "final": ""}',
  '\t_bb_last = []',
  '\t_bb_last2 = []',
  '\tif OS.has_feature("web"):   # the page counts this match\'s slow frames from here (render side: it measures the browser\'s frame gaps, it reads nothing of the sim)',
  '\t\tJavaScriptBridge.eval("window.__bbf_reset && window.__bbf_reset();", true)',
  '\tfor _k in range(S.fighters.size()):',
  '\t\t_bb_last.append(-1)',
  '\t\t_bb_last2.append(0)',
  '',
  '',
  'func _bb_toggle(idx: int) -> void:',
  '\tif not bb_on or not _bb_armed or _bb_done:',
  '\t\treturn',
  '\tif _bb.is_empty():',
  '\t\t_bb_begin()',
  '\t_bb.toggles.append([int(_bb.ticks), idx])',
  '',
  '',
  '## Playback: the same match from a saved replay, stepped with the recorded intents exactly as SimReplay.play does (the capture driver sets window.__replay and the page word replay=1).',
  'var _bb_pb: Dictionary = {}',
  'var _bb_pb_packed: Array = []',
  'var _bb_pb_cur: Array = []',
  'var _bb_pb_t: int = 0',
  'var _bb_pb_ii: int = 0',
  'var _bb_pb_ti: int = 0',
  '',
  '',
  'func bb_play_start(rp: Dictionary) -> bool:',
  '\tif rp.get(\"format\", \"\") != SimReplay.FORMAT or int(rp.get(\"v\", 0)) != SimReplay.V or int(rp.get(\"intent\", 0)) != SimIntent.VERSION:',
  '\t\treturn false',
  '\tbb_on = false   # a playback is not recorded',
  '\t_bb_pb_packed = []',
  '\tfor inp in rp.get(\"inputs\", []):',
  '\t\tvar p: int = SimReplay.join(inp[2], inp[3])',
  '\t\tvar it = null',
  '\t\tif p != -1:',
  '\t\t\tit = SimIntent.unpack(p) if p >= 0 else null',
  '\t\tif it != null and inp.size() == 5:',
  '\t\t\tSimIntent.unpack2(int(inp[4]), it)',
  '\t\t_bb_pb_packed.append(it)',
  '\t_bb_pb = rp',
  '\t_bb_pb_t = 0',
  '\t_bb_pb_ii = 0',
  '\t_bb_pb_ti = 0',
  '\tfor k in range(S.fighters.size()):   # the match the hook started has its own AI flags: they are put as the recording began',
  '\t\tvar want_ai: bool = bool(rp.get(\"ai\", {}).get(\"p%d\" % (k + 1), true))',
  '\t\tif (S.fighters[k].ai != null) != want_ai:',
  '\t\t\tSimCore.toggleAI(S, k)',
  '\t_bb_pb_cur = []',
  '\t_bb_pb_cur.resize(S.fighters.size())',
  '\treturn true',
  '',
  '',
  'func _bb_pb_step() -> bool:',
  '\tif _bb_pb_t == 0:   # the recorded match exactly as SimReplay.play starts it, with no hub setup merged in',
  '\t\tseed = int(_bb_pb.get("seed", 0)) & 0xFFFFFFFF',
  '\t\tSimCore.newMatch(S, seed, _bb_pb.get("ai", {}), _bb_pb.get("setup", {}))',
  '\t\t_started(_bb_pb.get("setup", {}), false)',
  '\t\tfor k in range(S.fighters.size()):',
  '\t\t\tvar want_ai0: bool = bool(_bb_pb.get("ai", {}).get("p%d" % (k + 1), true))',
  '\t\t\tif (S.fighters[k].ai != null) != want_ai0:',
  '\t\t\t\tSimCore.toggleAI(S, k)',
  '\twhile _bb_pb_ti < _bb_pb.toggles.size() and int(_bb_pb.toggles[_bb_pb_ti][0]) == _bb_pb_t:',
  '\t\tSimCore.toggleAI(S, int(_bb_pb.toggles[_bb_pb_ti][1]))',
  '\t\t_bb_pb_ti += 1',
  '\twhile _bb_pb_ii < _bb_pb.inputs.size() and int(_bb_pb.inputs[_bb_pb_ii][0]) == _bb_pb_t:',
  '\t\t_bb_pb_cur[int(_bb_pb.inputs[_bb_pb_ii][1])] = _bb_pb_packed[_bb_pb_ii]',
  '\t\t_bb_pb_ii += 1',
  '\tvar r: bool = SimCore.step(S, _bb_pb_cur)',
  '\t_bb_pb_t += 1',
  '\tif _bb_pb_t % 600 == 0 and OS.has_feature("web"):   # the recorded checkpoints, compared by the driver',
  '\t\tJavaScriptBridge.eval("(window.__pr_cp = window.__pr_cp || []).push([%d, \'%s\']);" % [_bb_pb_t, SimHash.stateHash(S).gameplay], true)',
  '\treturn r',
  '',
  '',
  'func _bb_step(inputs: Array) -> bool:',
  '\tif not _bb_pb.is_empty():   # a playback: the recorded intents, not the hub\'s',
  '\t\treturn _bb_pb_step()',
  '\tif not bb_on or not _bb_armed or _bb_done:',
  '\t\treturn SimCore.step(S, inputs)',
  '\tif _bb.is_empty():',
  '\t\t_bb_begin()',
  '\tvar word2: bool = SimInputData.right_stick_on()',
  '\tfor k in range(S.fighters.size()):',
  '\t\tvar i = inputs[k] if k < inputs.size() else null',
  '\t\tvar p: int = SimIntent.pack(i) if i != null else -1',
  '\t\tvar w: int = SimIntent.pack2(i) if word2 and i != null else 0',
  '\t\tif p != _bb_last[k] or w != _bb_last2[k]:',
  '\t\t\t_bb_last[k] = p',
  '\t\t\t_bb_last2[k] = w',
  '\t\t\tvar entry: Array = [int(_bb.ticks), k] + SimReplay.split(p)',
  '\t\t\tif w != 0:',
  '\t\t\t\tentry.append(w)',
  '\t\t\t_bb.inputs.append(entry)',
  '\tvar r: bool = SimCore.step(S, inputs)',
  '\tif OS.has_feature("web"):   # clip kit: the moments a clip can be cut around, told to the page, which keeps them with the match\'s marks (read only: the events are looked at, nothing is written)',
  '\t\tfor ev in S.out.fx:',
  '\t\t\tvar bk: String = ""',
  '\t\t\tif ev.type == "launch" or ev.type == "crater" or ev.type == "building_fall" or ev.type == "ko":',
  '\t\t\t\tbk = ev.type',
  '\t\t\telif ev.type == "cue" and str(ev.kind) == "beam_clash_end":',
  '\t\t\t\tbk = "beam_clash_end"',
  '\t\t\tif bk != "":',
  '\t\t\t\tJavaScriptBridge.eval("window.__bbm && window.__bbm(%d, \'%s\')" % [int(_bb.ticks), bk], true)',
  '\tif OS.has_feature("web") and Engine.get_process_frames() != _bb_fr:   # once a frame: the tick the page is on, for its slow-frame marks',
  '\t\t_bb_fr = Engine.get_process_frames()',
  '\t\tJavaScriptBridge.eval("window.__bb_t=%d;" % int(_bb.ticks), true)',
  '\t_bb.ticks = int(_bb.ticks) + 1',
  '\tvar over_now: bool = S.game.ko != null',
  '\tif not over_now:   # a no-contest (Encounter\'s match ending) is a cue and no KO: it ends the match too',
  '\t\tfor e in S.out.fx:',
  '\t\t\tif str(e.type) == "cue" and str(e.kind) == "no_contest":',
  '\t\t\t\tover_now = true',
  '\t\t\t\tbreak',
  '\tif over_now:',
  '\t\t_bb.final = SimHash.stateHash(S).gameplay',
  '\t\t_bb_done = true',
  '\t\t_bb_publish(true)',
  '\telif int(_bb.ticks) % 120 == 0:',
  '\t\t_bb_publish(false)',
  '\treturn r',
  '',
  '',
  'func _bb_publish(over: bool, ended: bool = false) -> void:',
  '\tif not OS.has_feature("web"):',
  '\t\treturn',
  '\tvar txt: String = JSON.stringify(_bb)',
  '\tif over or ended:   # a KO, or a match left for a new one: queued, so the next periodic copy cannot overwrite it before the page has seen it',
  '\t\tJavaScriptBridge.eval("(window.__bb_q = window.__bb_q || []).push({over: %s, ended: %s, ticks: %d, seed: %d, at: Date.now(), frames: (window.__bbf_snap ? window.__bbf_snap() : null), replay: %s});" % ["true" if over else "false", "true" if ended else "false", int(_bb.ticks), _bb_seed, JSON.stringify(txt)], true)',
  '\tJavaScriptBridge.eval("window.__bb_replay = %s; window.__bb_state = {over: %s, ended: %s, ticks: %d, seed: %d, at: Date.now()};" % [JSON.stringify(txt), "true" if over else "false", "true" if ended else "false", int(_bb.ticks), _bb_seed], true)',
  '',
].join('\n');

/** sim_host.gd with the black box's hooks and functions. Throws, naming the hook, when the file has moved (the preview must then be updated). Keeps the file's line endings. */
export function patchHost(text) {
  const crlf = text.includes('\r\n');
  const nl = (s) => (crlf ? s.replace(/\n/g, '\r\n') : s);
  let out = text;
  for (const h of HOOKS) {
    const from = nl(h.from);
    const n = out.split(from).length - 1;
    if (n !== 1) throw new Error(`render/core/sim_host.gd: ${h.name}: expected the line once, found it ${n} times (tools/preview/blackbox.mjs HOOKS is out of date)`);
    out = out.replace(from, () => nl(h.to));
  }
  return out.replace(/\s*$/, '') + nl(HOST_FUNCS);
}


/** audio/audio_voices.gd with the cue log: AudioVoices.play becomes a wrapper that asks the real one, then tells the page (window.__audcue) the cue and whether a voice took it. Read only; the real function is unchanged. */
export function patchAudio(text) {
  const crlf = text.includes('\r\n');
  const from = 'func play(cue: AudioCues.Cue, cam_x: float, zoom: float = 1.0) -> bool:\n';
  const fromN = crlf ? from.replace(/\n/g, '\r\n') : from;
  const n = text.split(fromN).length - 1;
  if (n !== 1) throw new Error('audio/audio_voices.gd: AudioVoices.play: expected the signature once, found it ' + n + ' times (tools/preview/blackbox.mjs patchAudio is out of date)');
  const to = [
    'func play(cue: AudioCues.Cue, cam_x: float, zoom: float = 1.0) -> bool:',
    '\tvar ok_pv: bool = _play_real(cue, cam_x, zoom)',
    '\t_pv_audlog(cue, ok_pv)',
    '\treturn ok_pv',
    '',
    '',
    '## Scratch (tools/preview): the cue log for ?audiolog=1 on a local page (read only).',
    'var _pv_aud_on: int = -1',
    'func _pv_audlog(cue: AudioCues.Cue, ok: bool) -> void:',
    '\tif _pv_aud_on < 0:',
    '\t\t_pv_aud_on = 1 if (OS.has_feature("web") and bool(JavaScriptBridge.eval("!!window.__audlog", true))) else 0',
    '\tif _pv_aud_on == 1:',
    '\t\tJavaScriptBridge.eval("window.__audcue && window.__audcue(%s, %s, %s, %.1f, %s)" % [JSON.stringify(cue.sound), JSON.stringify(cue.kind), JSON.stringify(cue.bus), cue.gain_db, "true" if ok else "false"], true)',
    '',
    '',
    'func _play_real(cue: AudioCues.Cue, cam_x: float, zoom: float = 1.0) -> bool:',
    '',
  ].join('\n');
  return text.replace(fromN, () => (crlf ? to.replace(/\n/g, '\r\n') : to));
}

/** render/core/main.gd with the rumble log: every step the host asks of a pad or a handheld is told to the page (window.__vibreq) before it is asked. Read only. */
export function patchHaptics(text) {
  const crlf = text.includes('\r\n');
  const nl = (s) => (crlf ? s.replace(/\n/g, '\r\n') : s);
  const from = nl('func _play_haptic_step(plan: Dictionary, s: Dictionary) -> void:\n');
  const n = text.split(from).length - 1;
  if (n !== 1) throw new Error('render/core/main.gd: _play_haptic_step: expected the signature once, found it ' + n + ' times (tools/preview/blackbox.mjs patchHaptics is out of date)');
  const to = nl('func _play_haptic_step(plan: Dictionary, s: Dictionary) -> void:\n\t_pv_vib(plan, s)\n');
  const fn = nl([
    '',
    '',
    '## Scratch (tools/preview): the rumble log for ?audiolog=1 on a local page (read only).',
    'func _pv_vib(plan: Dictionary, s: Dictionary) -> void:',
    '\tif OS.has_feature("web") and bool(JavaScriptBridge.eval("!!window.__audlog", true)):',
    '\t\tJavaScriptBridge.eval("window.__vibreq && window.__vibreq(%s, %s)" % [JSON.stringify(str(plan["via"])), JSON.stringify(s)], true)',
    '',
  ].join('\n'));
  return text.replace(from, () => to).replace(/\s*$/, '') + fn;
}

/** The page's own script: the questions and the save, after the match. Plain DOM, no network. */
export const PAGE_SCRIPT = String.raw`
(function () {
  var shown = '', K = 'orb-blackbox-last', seen = {};
  // Slow frames (render side only, nothing of the sim): the browser's own gaps between frames and the tick the game was on (the host sets window.__bb_t once a frame), for the match in play. A gap over 33 ms is a mark,
  // with its time; a gap over a second is the tab being away (hidden, a sleeping PC) and is only counted. So a bad match says whether it was the PC (marks all through, at any tick) or the game (marks at certain ticks).
  var F = {};
  // Clip kit (tools/clips/clips.md): F9 on the keyboard, or View + RB on a pad, marks "the last 15 seconds" of the match in play; the game's own launch, crater, beam clash end, building fall and KO bookmark themselves (the host calls __bbm).
  // The marks are kept with the match and saved in its file as 'marks' ([{tick, kind}]); tools/clips/make.mjs --from-match renders each one through the replay. A small text note in the page's corner for 1.5 s: nothing is drawn on the game, and nothing of the sim is read or written.
  var M = [], noteEl = null, noteT = 0, lastBm = {}, lastBmTick = 0, padHeld = false;
  window.__bb_marks = M;
  function note(txt) { try { if (!noteEl) { noteEl = document.createElement('div'); noteEl.style.cssText = 'position:fixed;left:6px;bottom:30px;z-index:2147483645;font:12px/1.3 monospace;color:#fff;background:rgba(0,0,0,.6);padding:2px 8px;border-radius:3px;pointer-events:none;display:none'; document.body.appendChild(noteEl); } noteEl.textContent = txt; noteEl.style.display = 'block'; clearTimeout(noteT); noteT = setTimeout(function () { noteEl.style.display = 'none'; }, 1500); } catch (e) { /* none */ } }
  function markNow() { if (M.length < 600) M.push({ tick: window.__bb_t || 0, kind: 'clip', before: 900 }); note('Clip marked'); }
  window.__bbm = function (tick, kind) { if (lastBmTick > tick + 5) lastBm = {}; lastBmTick = tick; if (lastBm[kind] !== undefined && tick - lastBm[kind] < 60) return; lastBm[kind] = tick; if (M.length < 600) M.push({ tick: tick, kind: kind }); };
  window.addEventListener('keydown', function (e) { if (e.isTrusted && e.key === 'F9' && !e.repeat) { e.preventDefault(); markNow(); } }, true);
  setInterval(function () { try { var g = navigator.getGamepads ? navigator.getGamepads() : [], on = false; for (var i = 0; i < g.length; i++) { var q = g[i]; if (q && q.buttons && q.buttons[8] && q.buttons[5] && q.buttons[8].pressed && q.buttons[5].pressed) on = true; } if (on && !padHeld) markNow(); padHeld = on; } catch (e) { /* none */ } }, 80);
  function fReset() { F = { n: 0, over33: 0, over50: 0, over100: 0, away: 0, worst: 0, worstTick: 0, slow: [], last: 0, t0: performance.now(), rs: [], rsLast: false, rsPad: '', rb: [], rbLast: {}, rt: [], rtLast: {}, ls: [], lsLast: {}, rsa: [], rsaLast: {}, pads: {} }; }
  fReset();
  window.__bbf_reset = fReset;
  window.__bbf_snap = function (lean) { return { threshold: 33.4, n: F.n, over33: F.over33, over50: F.over50, over100: F.over100, away: F.away, worst: Math.round(F.worst * 10) / 10, worstTick: F.worstTick, seconds: Math.round((performance.now() - F.t0) / 100) / 10, kept: F.slow.length, slow: F.slow.slice(), rsPad: F.rsPad, rs: lean ? undefined : F.rs.slice(), rsCount: F.rs.length, rb: lean ? undefined : F.rb.slice(), rbCount: F.rb.length, rt: lean ? undefined : F.rt.slice(), rtCount: F.rt.length, ls: lean ? undefined : F.ls.slice(), lsCount: F.ls.length, rsa: lean ? undefined : F.rsa.slice(), rsaCount: F.rsa.length, pads: lean ? undefined : JSON.parse(JSON.stringify(F.pads)) }; };
  // The raw right stick (the EP's stand-in, 2026-11-01): the first connected pad's axes 2 and 3 (the standard mapping's right stick) as the browser hands them over, a sample each frame while the stick is off centre
  // and the frame it comes back: [tick, ms, x, y]. It only READS the pad; it is saved in the same local file so a flick that did nothing can be told apart: the thumb not reading, or the rules refusing. Nothing leaves the PC.
  function readRightStick(now) {
    try {
      var pads = navigator.getGamepads ? navigator.getGamepads() : [], gp = null;
      for (var i = 0; i < pads.length; i++) if (pads[i] && pads[i].connected && pads[i].axes && pads[i].axes.length >= 4) { gp = pads[i]; break; }
      if (!gp) return;
      if (!F.rsPad) F.rsPad = String(gp.id || '').slice(0, 80);
      var x = gp.axes[2] || 0, y = gp.axes[3] || 0, act = Math.abs(x) > 0.02 || Math.abs(y) > 0.02;
      if ((act || F.rsLast) && F.rs.length < 40000) F.rs.push([window.__bb_t || 0, Math.round(now), Math.round(x * 100) / 100, Math.round(y * 100) / 100]);
      F.rsLast = act;
    } catch (e) { /* the box must never break the page */ }
  }
  // The rest of the raw pad (Controls, 2026-11-06), recorded the way the right stick is: only READ from every connected pad (up to four, each row says which), only changes, saved in the same local file as rawPad.
  // So "I let go but it kept attacking" can be told apart: a stuck button, a trigger that does not come back or a noisy stick (in the record) against the game (a clean record), and a phantom or second pad is seen.
  //   buttons: [tick, ms, pad, mask] when that pad's set of pressed buttons changes, one bit per standard-mapping button (bit 0 A, 1 B, 2 X, 3 Y, 4 LB, 5 RB, 6 LT, 7 RT, 8 Back, 9 Start, 10 L3, 11 R3, 12 to 15 the D-pad up, down, left, right, 16 Home); a pad's first frame is always recorded
  //   triggers: [tick, ms, pad, lt, rt] (0 to 1, two places) when either moves by 0.04 or more or leaves or returns to zero; a pad's first frame is always recorded
  //   leftStick and rightStick: [tick, ms, pad, x, y] each frame it is off centre (over 0.02) and the frame it comes back, like rawRightStick but for every pad
  //   pads: every pad the browser showed (index, id, mapping, button and axis counts, the tick it was first seen)
  function readRawPad(now) {
    try {
      var pads = navigator.getGamepads ? navigator.getGamepads() : [], t = window.__bb_t || 0, ms = Math.round(now), n = 0;
      for (var i = 0; i < pads.length && n < 4; i++) {
        var p = pads[i];
        if (!p || !p.connected) continue;
        n++;
        if (!F.pads[i] && Object.keys(F.pads).length < 8) F.pads[i] = { id: String(p.id || "").slice(0, 80), mapping: String(p.mapping || ""), buttons: p.buttons ? p.buttons.length : 0, axes: p.axes ? p.axes.length : 0, firstTick: t };
        var b = p.buttons || [], mask = 0, k;
        for (k = 0; k < b.length && k < 31; k++) if (b[k] && b[k].pressed) mask |= (1 << k);
        if (mask !== F.rbLast[i] && F.rb.length < 20000) { F.rb.push([t, ms, i, mask]); F.rbLast[i] = mask; }
        var lt = b[6] ? Math.round((b[6].value || 0) * 100) / 100 : 0, rt = b[7] ? Math.round((b[7].value || 0) * 100) / 100 : 0, tl = F.rtLast[i];
        if (!tl || Math.abs(lt - tl[0]) >= 0.04 || Math.abs(rt - tl[1]) >= 0.04 || (lt === 0) !== (tl[0] === 0) || (rt === 0) !== (tl[1] === 0)) { if (F.rt.length < 20000) { F.rt.push([t, ms, i, lt, rt]); F.rtLast[i] = [lt, rt]; } }
        var a = p.axes || [], x = a[0] || 0, y = a[1] || 0, act = Math.abs(x) > 0.02 || Math.abs(y) > 0.02;
        if ((act || F.lsLast[i]) && F.ls.length < 40000) F.ls.push([t, ms, i, Math.round(x * 100) / 100, Math.round(y * 100) / 100]);
        F.lsLast[i] = act;
        var x2 = a[2] || 0, y2 = a[3] || 0, act2 = Math.abs(x2) > 0.02 || Math.abs(y2) > 0.02;   // the right stick of every pad, so a phantom listed first cannot hide the real one (rawRightStick reads the first only)
        if ((act2 || F.rsaLast[i]) && F.rsa.length < 40000) F.rsa.push([t, ms, i, Math.round(x2 * 100) / 100, Math.round(y2 * 100) / 100]);
        F.rsaLast[i] = act2;
      }
    } catch (e) { /* the box must never break the page */ }
  }
  function onFrame(now) {
    readRightStick(now);
    readRawPad(now);
    if (F.last && !document.hidden) {
      var d = now - F.last;
      if (d > 1000) F.away++;
      else {
        F.n++;
        if (d > 33.4) {
          F.over33++; if (d > 50) F.over50++; if (d > 100) F.over100++;
          if (d > F.worst) { F.worst = d; F.worstTick = window.__bb_t || 0; }
          if (F.slow.length < 400) F.slow.push([window.__bb_t || 0, Math.round(d * 10) / 10, Math.round((now - F.t0) / 100) / 10]);
        }
      }
    }
    F.last = document.hidden ? 0 : now;
    requestAnimationFrame(onFrame);
  }
  requestAnimationFrame(onFrame);
  function slowLine(fr) { return fr && fr.n ? (fr.over33 + ' of ' + fr.n + ' frames took over 33 ms' + (fr.over33 ? ' (worst ' + Math.round(fr.worst) + ' ms)' : '') + '.') : ''; }
  function css(el, o) { for (var k in o) el.style[k] = o[k]; return el; }
  function stamp() { var d = new Date(), p = function (n) { return (n < 10 ? '0' : '') + n; }; return d.getFullYear() + p(d.getMonth() + 1) + p(d.getDate()) + '-' + p(d.getHours()) + p(d.getMinutes()); }
  function save(replayText, answers, matchOver, frames) {
    var obj = { kind: 'orb-first-play', marks: (window.__bb_lastMarks || M).slice(0, 600), note: 'Recorded on this PC by the private page. Nothing was sent anywhere. The replay plays back through the game\'s own replay path. frames: the slow frames of that play (tick, ms, seconds in).', savedAt: new Date().toISOString(), pageSearch: String(location.search || ''), build: window.__build || null, audio: window.__audio_snap ? window.__audio_snap(true) : null, matchOver: matchOver, answers: answers, frames: frames ? Object.assign({}, frames, { rs: undefined, rb: undefined, rt: undefined, ls: undefined, rsa: undefined, pads: undefined }) : null, rawPad: frames && frames.rb ? { pad: frames.rsPad, mapping: 'the standard mapping', note: 'read from the pad, only changes, nothing sent. buttons: [tick, ms, pad, mask] on a change (bit 0 A, 1 B, 2 X, 3 Y, 4 LB, 5 RB, 6 LT, 7 RT, 8 Back, 9 Start, 10 L3, 11 R3, 12 to 15 the D-pad up, down, left, right, 16 Home); triggers: [tick, ms, pad, lt, rt] when either moves by 0.04 or leaves or returns to zero; leftStick and rightStick: [tick, ms, pad, x, y] each frame off centre and the frame it came back, for every pad (y down is positive; rightStick is the right stick of every pad, where rawRightStick is the first pad only); pad is the browser pad index; pads: every pad the browser showed', pads: frames.pads || {}, buttons: frames.rb, triggers: frames.rt, leftStick: frames.ls, rightStick: frames.rsa || [] } : null, rawRightStick: frames && frames.rs ? { pad: frames.rsPad, axes: 'the standard mapping, axes 2 and 3 (x, y)', note: 'a sample [tick, ms, x, y] each frame the stick was off centre, and the frame it came back; only read from the pad, nothing sent', samples: frames.rs } : null, replay: JSON.parse(replayText) };
    var blob = new Blob([JSON.stringify(obj)], { type: 'application/json' });
    var a = document.createElement('a');
    a.href = URL.createObjectURL(blob); a.download = 'orb-first-play-' + stamp() + '.json';
    document.body.appendChild(a); a.click(); setTimeout(function () { URL.revokeObjectURL(a.href); a.remove(); }, 1000);
  }
  function card(title, intro, withQuestions, replayText, matchOver, frames) {
    var sl = slowLine(frames); if (sl) intro = intro + ' ' + sl;
    var box = css(document.createElement('div'), { position: 'fixed', left: '50%', top: '50%', transform: 'translate(-50%,-50%)', zIndex: 99999, width: 'min(560px, 92vw)', background: '#0b0d12', color: '#e8e8e0', border: '2px solid #8c8a80', borderRadius: '14px', padding: '18px 20px', font: '16px/1.4 sans-serif', boxShadow: '0 0 0 9999px rgba(0,0,0,0.55)' });
    var h = css(document.createElement('div'), { fontWeight: 'bold', fontSize: '20px', marginBottom: '8px' }); h.textContent = title; box.appendChild(h);
    var p = document.createElement('div'); p.textContent = intro; css(p, { marginBottom: '10px', color: '#c8c8c0' }); box.appendChild(p);
    var qs = [], names = ['What did you try that did not work?', 'What felt best?', 'What would you change first?', 'Did the hits sound right?'], fields = [];
    if (withQuestions) names.forEach(function (q) {
      var l = document.createElement('label'); l.textContent = q + ' (optional)'; css(l, { display: 'block', margin: '8px 0 2px' });
      var t = css(document.createElement('textarea'), { width: '100%', height: '46px', background: '#14171e', color: '#e8e8e0', border: '1px solid #55534b', borderRadius: '6px', font: '15px sans-serif', boxSizing: 'border-box' });
      box.appendChild(l); box.appendChild(t); fields.push([q, t]);
    });
    var row = css(document.createElement('div'), { display: 'flex', gap: '10px', marginTop: '14px' });
    function btn(label, main, fn) { var b = css(document.createElement('button'), { flex: '1', padding: '10px', font: 'bold 16px sans-serif', borderRadius: '8px', border: '2px solid #8c8a80', cursor: 'pointer', background: main ? '#e8e6dc' : '#14171e', color: main ? '#111' : '#e8e8e0' }); b.textContent = label; b.onclick = fn; row.appendChild(b); }
    btn('Save my match file', true, function () { var ans = {}; fields.forEach(function (f) { ans[f[0]] = f[1].value; }); save(replayText, ans, matchOver, frames); box.remove(); });
    btn('Not now', false, function () { box.remove(); });
    box.appendChild(row);
    var foot = css(document.createElement('div'), { marginTop: '10px', fontSize: '13px', color: '#9a988e' }); foot.textContent = 'Nothing leaves this PC: the file goes to your own Downloads folder and you choose whether to send it.'; box.appendChild(foot);
    document.body.appendChild(box);
  }
  setInterval(function () {
    try {
      var q = window.__bb_q;
      while (q && q.length) {
        var e = q.shift(), eid = e.seed + ':' + e.ticks;
        window.__bb_lastMarks = M.splice(0);   // the match that ended keeps its marks; the next one starts with none
        if (seen[eid] === 1) continue;
        seen[eid] = 1;
        try { var L = JSON.parse(localStorage.getItem(K + '-list') || '[]'); L.push({ at: e.at, over: !!e.over, replay: e.replay, frames: e.frames ? Object.assign({}, e.frames, { rs: undefined, rb: undefined, rt: undefined, ls: undefined, rsa: undefined, pads: undefined }) : null }); while (L.length > 5) L.shift(); localStorage.setItem(K + '-list', JSON.stringify(L)); } catch (x) { /* storage full or private: the card still offers it */ }
        card(e.over ? 'That match was recorded' : 'The match you left was recorded', 'Your presses and the match\'s seed were saved on this PC. Three questions, if you feel like answering, then save the file to send.', true, e.replay, !!e.over, e.frames || null);
      }
      var s = window.__bb_state, r = window.__bb_replay;
      if (!s || !r) return;
      if (typeof s.at === 'number') { try { localStorage.setItem(K, r); localStorage.setItem(K + '-frames', JSON.stringify(window.__bbf_snap(true))); } catch (e) { /* private window or full: fine */ } }
    } catch (e) { /* the box must never break the page */ }
  }, 1000);
  window.addEventListener('load', function () {
    try { var last = localStorage.getItem(K); if (last && !window.__bb_state) setTimeout(function () { if (!window.__bb_state) card('Last time\'s match was recorded', 'The page was closed before the match ended. You can still save what was recorded.', false, last, false, JSON.parse(localStorage.getItem(K + '-frames') || 'null')); }, 4000); } catch (e) { /* nothing stored */ }
  });
})();
`;

/** index.html with the page script added before </body>. */
/** meta: what this build is made of (the commit, the stack's key and parks, the switches), stamped into the page as window.__build and into every saved file as `build`, so a recording says which build it was played on. */
export function injectPage(html, meta = null, shellSnippet = '') {
  if (html.includes('orb-blackbox-last')) return html;
  const stamp = meta ? `<script>window.__build = ${JSON.stringify(meta).replace(/</g, '\u003c')};</script>` : '';
  const shell = shellSnippet ? `<script data-orb-shell>
${shellSnippet.split('</script').join('<\\/script')}
</script>
` : '';   // Audio's web shell snippet (docs/audio/pending/audio-resume): first, before the engine script
  const head = `${shell}<script>${AUDIO_HEAD}</script>`;
  const tag = `${stamp}<script>${PAGE_SCRIPT}</script>`;
  let out = html.includes('<head>') ? html.replace('<head>', () => `<head>\n${head}`) : head + html;
  return out.includes('</body>') ? out.replace('</body>', () => `${tag}\n</body>`) : out + tag;
}


/** The first script in the page (before the engine): the audio and rumble taps, read only. window.__audlog is true on ?audiolog=1 and with the black box (?blackbox=1; Orb file of 2026-11-01 had the log off because only audiolog turned it on) (the game-side wrappers ask for it); window.__audio_snap() reads what was seen. */
export const AUDIO_HEAD = String.raw`
(function () {
  var A = { on: /[?&](audiolog|blackbox)(=|&|$)/.test(location.search), t0: performance.now(), ctxs: [], gesture: null, firstSoundMs: null, peak: 0, windows: 0, loud: 0, rmsSum: 0, cues: 0, cuesTaken: 0, cuesDropped: 0, by: {}, vib: [], vibReq: [], navVibrate: 0, playEffect: 0, pulse: 0, rms: [], recentPeak: 0, srcs: {}, loudAt: [], cueT: [] };
  window.__audlog = A.on;
  window.__audHeadCopies = (window.__audHeadCopies || 0) + 1;   // more than 1: this head ran twice in the page (two taps would split the counters)
  A.tl = []; A.snap5 = null;
  if (/[?&]audiolog(=|&|$)/.test(location.search)) {   // the line on the page: only with the word, off otherwise
    document.addEventListener('DOMContentLoaded', function () {
      var el = document.createElement('div');
      el.style.cssText = 'position:fixed;left:6px;bottom:6px;z-index:2147483647;font:11px/1.3 monospace;color:#9fe;background:rgba(0,0,0,.55);padding:2px 6px;pointer-events:none;white-space:pre-wrap;max-width:96vw';
      document.body.appendChild(el);
      setInterval(function () {
        var c = A.ctxs.length ? A.ctxs[0].ctx : null;
        el.textContent = 'sound ' + (c ? c.state + ' t=' + c.currentTime.toFixed(1) : 'no context yet') + '  played ' + A.cuesTaken + ' dropped ' + A.cuesDropped + '  out peak ' + A.recentPeak.toFixed(2) + (A.status ? '\n' + A.status : '');
        A.recentPeak *= 0.5;
      }, 500);
    });
  }
  function now() { return Math.round(performance.now() - A.t0); }
  ['pointerdown', 'mousedown', 'keydown', 'touchstart'].forEach(function (ev) { window.addEventListener(ev, function (e) { if (e.isTrusted) { if (A.gesture === null) A.gesture = { at: now(), kind: ev }; A.ctxs.forEach(function (r) { try { if (r.ctx && r.ctx.state === 'suspended') r.ctx.resume(); } catch (x) { /* none */ } }); } }, true); });
  try {
    var Orig = window.AudioContext || window.webkitAudioContext;
    if (Orig && A.on) {
      var oc = AudioNode.prototype.connect;
      AudioNode.prototype.connect = function (dest) {
        try {
          if (dest && window.AudioDestinationNode && dest instanceof AudioDestinationNode) {
            var ctx = dest.context; A.srcs[(this.constructor && this.constructor.name) || '?'] = (A.srcs[(this.constructor && this.constructor.name) || '?'] || 0) + 1;
            if (!ctx.__tap) {
              var an = ctx.createAnalyser(); an.fftSize = 2048;
              var g0 = ctx.createGain(); g0.gain.value = 0;
              oc.call(an, g0); oc.call(g0, dest);
              ctx.__tap = an; ctx.__buf = new Float32Array(an.fftSize);
              var rec = { created: now(), states: [{ at: now(), state: ctx.state }], sampleRate: ctx.sampleRate, ctx: ctx };
              A.ctxs.push(rec);
              ctx.addEventListener('statechange', function () { rec.states.push({ at: now(), state: ctx.state }); });
              setInterval(function () {
                if (ctx.state !== 'running') return;
                ctx.__tap.getFloatTimeDomainData(ctx.__buf);
                var s = 0, p = 0; for (var i = 0; i < ctx.__buf.length; i++) { var v = ctx.__buf[i]; s += v * v; if (Math.abs(v) > p) p = Math.abs(v); }
                var rms = Math.sqrt(s / ctx.__buf.length);
                A.windows++; A.rmsSum += rms; if (p > A.peak) A.peak = p; if (p > A.recentPeak) A.recentPeak = p;
                if (rms > 0.0005) { A.loud++; if (A.firstSoundMs === null) A.firstSoundMs = now(); if (A.loudAt.length < 4000) A.loudAt.push(now()); }
                if (A.windows % 5 === 0 && A.rms.length < 1200) A.rms.push([now(), Math.round(rms * 10000) / 10000, Math.round(p * 1000) / 1000]);
              }, 40);
            }
            oc.call(this, ctx.__tap);
          }
        } catch (e) { /* a tap must never break the page */ }
        return oc.apply(this, arguments);
      };
    }
  } catch (e) { /* no Web Audio */ }
  try { var nv = navigator.vibrate; if (nv) navigator.vibrate = function (p) { A.navVibrate++; if (A.vib.length < 400) A.vib.push({ at: now(), api: 'navigator.vibrate', arg: p }); return nv.apply(navigator, arguments); }; } catch (e) { /* none */ }
  try {
    if (window.GamepadHapticActuator) {
      var pe = GamepadHapticActuator.prototype.playEffect, pu = GamepadHapticActuator.prototype.pulse;
      if (pe) GamepadHapticActuator.prototype.playEffect = function (t, p) { A.playEffect++; if (A.vib.length < 400) A.vib.push({ at: now(), api: 'playEffect', arg: t, params: p }); return pe.apply(this, arguments); };
      if (pu) GamepadHapticActuator.prototype.pulse = function (v, d) { A.pulse++; if (A.vib.length < 400) A.vib.push({ at: now(), api: 'pulse', v: v, d: d }); return pu.apply(this, arguments); };
    }
  } catch (e) { /* none */ }
  window.__audeng = function (o) { A.eng = o; A.engCalls = (A.engCalls || 0) + 1; };
  if (/[?&]power(=(?!0|off)[^&]*|&|$)/.test(location.search)) {   // Orb's slider for the base of flat-out flight (Simulation's flatOut, 3,500 to 7,000): read at the start of the next match
    var K = 'orb_flatout', v0 = 5000; try { var sv = parseFloat(localStorage.getItem(K)); if (sv >= 3500 && sv <= 7000) v0 = sv; } catch (e) { /* none */ }
    window.__flatout = v0;
    document.addEventListener('DOMContentLoaded', function () {
      var box = document.createElement('div');
      box.style.cssText = 'position:fixed;right:8px;bottom:8px;z-index:2147483646;font:12px/1.3 sans-serif;color:#fff;background:rgba(0,0,0,.6);padding:4px 8px;border-radius:4px';
      var lab = document.createElement('span'), sl = document.createElement('input');
      sl.type = 'range'; sl.min = '3500'; sl.max = '7000'; sl.step = '100'; sl.value = String(v0); sl.style.cssText = 'vertical-align:middle;width:160px';
      function show() { lab.textContent = 'flat-out flight base speed ' + sl.value + ' (applies at the next match) '; }
      sl.addEventListener('input', function () { window.__flatout = parseFloat(sl.value); try { localStorage.setItem(K, sl.value); } catch (e) { /* none */ } show(); });
      ['keydown', 'keyup'].forEach(function (ev) { sl.addEventListener(ev, function (e) { e.stopPropagation(); }); });
      show(); box.appendChild(lab); box.appendChild(sl); document.body.appendChild(box);
    });
  }
  window.__audstatus = function (s) { A.status = String(s); A.statusCalls = (A.statusCalls || 0) + 1; };
  window.__audcue = function (sound, kind, bus, gain, ok) { A.cues++; if (A.cueT.length < 400) A.cueT.push([now(), sound, ok ? 1 : 0]); if (ok) A.cuesTaken++; else A.cuesDropped++; var k = (kind || '?') + ':' + sound; A.by[k] = (A.by[k] || 0) + 1; };
  window.__vibreq = function (via, step) { if (A.vibReq.length < 400) A.vibReq.push({ at: now(), via: via, step: step }); };
  function snapOf(lean) {
    var ctxs = A.ctxs.map(function (c) { return { created: c.created, sampleRate: c.sampleRate, states: c.states.slice(-12) }; });
    var by = Object.keys(A.by).sort(function (a, b) { return A.by[b] - A.by[a]; }).slice(0, 60).map(function (k) { return [k, A.by[k]]; });
    return { on: A.on, gesture: A.gesture, ctxs: ctxs, firstSoundMs: A.firstSoundMs, peak: Math.round(A.peak * 1000) / 1000, windows: A.windows, loudWindows: A.loud, meanRms: A.windows ? Math.round(A.rmsSum / A.windows * 10000) / 10000 : 0,
      cues: A.cues, cuesTaken: A.cuesTaken, cuesDropped: A.cuesDropped, cuesBySound: by, engineMixer: A.eng || null, audioStatus: A.status || null, sourcesConnectedToTheOutput: A.srcs, navigatorVibrateCalls: A.navVibrate, playEffectCalls: A.playEffect, pulseCalls: A.pulse, vibrationRequestsFromTheGame: A.vibReq.length, cueTimes: lean ? undefined : A.cueT, loudAtMs: lean ? undefined : A.loudAt,
      vibrationRequests: lean ? undefined : A.vibReq.slice(0, 60), browserVibrationCalls: lean ? undefined : A.vib.slice(0, 60), rmsSeries: lean ? undefined : A.rms.slice(-240) };
  }
  // Audio's read of Orb's 68ee save (2026-11-02: the record said suspended and every counter 0 for 194 s while Orb heard sound): the snapshot now also reads the live state of each context, the tab's visibility and focus,
  // counts the engine's and the status line's calls separately, says how many copies of this head ran, keeps a one-second timeline, and keeps a snapshot taken 5 s into the match (tick 300) beside the one at the save
  function live() {
    var o = { visibility: document.visibilityState, focus: document.hasFocus(), headCopies: window.__audHeadCopies || 0, engCalls: A.engCalls || 0, statusCalls: A.statusCalls || 0, cueCalls: A.cues, bridgeAlive: typeof window.__audcue === 'function' };
    o.liveCtxs = A.ctxs.map(function (c) { var x = c.ctx; return { state: x ? x.state : '?', currentTime: x ? Math.round(x.currentTime * 100) / 100 : null, baseLatency: x && x.baseLatency != null ? Math.round(x.baseLatency * 1000) / 1000 : null }; });
    return o;
  }
  window.__audio_snap = function (lean) {
    var r = snapOf(lean), l = live();
    for (var k in l) r[k] = l[k];
    r.timeline = A.tl.slice(-120);
    r.atFiveSeconds = A.snap5;
    return r;
  };
  setInterval(function () {
    var l = live(), c0 = l.liveCtxs[0] || {};
    var bbt = window.__bb_t || 0;
    A.tl.push([now(), c0.state || 'none', c0.currentTime == null ? null : c0.currentTime, l.visibility === 'visible' ? 1 : 0, l.focus ? 1 : 0, bbt, A.cues, A.engCalls || 0, A.statusCalls || 0]);
    if (A.tl.length > 400) A.tl.shift();
    if (!A.snap5 && bbt >= 300) { var s5 = snapOf(true), ll = live(); for (var k2 in ll) s5[k2] = ll[k2]; s5.takenAtMs = now(); s5.tick = bbt; A.snap5 = s5; }
  }, 1000);
})();
`;

export const BB_FINGERPRINT = createHash('sha1').update(JSON.stringify([HOOKS, HOST_FUNCS, PAGE_SCRIPT, AUDIO_HEAD, patchAudio.toString(), patchHaptics.toString()])).digest('hex').slice(0, 6);
