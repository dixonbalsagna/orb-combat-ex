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
  '\tif OS.has_feature("web") and Engine.get_process_frames() != _bb_fr:   # once a frame: the tick the page is on, for its slow-frame marks',
  '\t\t_bb_fr = Engine.get_process_frames()',
  '\t\tJavaScriptBridge.eval("window.__bb_t=%d;" % int(_bb.ticks), true)',
  '\t_bb.ticks = int(_bb.ticks) + 1',
  '\tif int(_bb.ticks) % 600 == 0:',
  '\t\t_bb.checkpoints.append([int(_bb.ticks), SimHash.stateHash(S).gameplay])',
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

/** The page's own script: the questions and the save, after the match. Plain DOM, no network. */
export const PAGE_SCRIPT = String.raw`
(function () {
  var shown = '', K = 'orb-blackbox-last', seen = {};
  // Slow frames (render side only, nothing of the sim): the browser's own gaps between frames and the tick the game was on (the host sets window.__bb_t once a frame), for the match in play. A gap over 33 ms is a mark,
  // with its time; a gap over a second is the tab being away (hidden, a sleeping PC) and is only counted. So a bad match says whether it was the PC (marks all through, at any tick) or the game (marks at certain ticks).
  var F = {};
  function fReset() { F = { n: 0, over33: 0, over50: 0, over100: 0, away: 0, worst: 0, worstTick: 0, slow: [], last: 0, t0: performance.now(), rs: [], rsLast: false, rsPad: '' }; }
  fReset();
  window.__bbf_reset = fReset;
  window.__bbf_snap = function (lean) { return { threshold: 33.4, n: F.n, over33: F.over33, over50: F.over50, over100: F.over100, away: F.away, worst: Math.round(F.worst * 10) / 10, worstTick: F.worstTick, seconds: Math.round((performance.now() - F.t0) / 100) / 10, kept: F.slow.length, slow: F.slow.slice(), rsPad: F.rsPad, rs: lean ? undefined : F.rs.slice(), rsCount: F.rs.length }; };
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
  function onFrame(now) {
    readRightStick(now);
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
    var obj = { kind: 'orb-first-play', note: 'Recorded on this PC by the private page. Nothing was sent anywhere. The replay plays back through the game\'s own replay path. frames: the slow frames of that play (tick, ms, seconds in).', savedAt: new Date().toISOString(), pageSearch: String(location.search || ''), build: window.__build || null, matchOver: matchOver, answers: answers, frames: frames ? Object.assign({}, frames, { rs: undefined }) : null, rawRightStick: frames && frames.rs ? { pad: frames.rsPad, axes: 'the standard mapping, axes 2 and 3 (x, y)', note: 'a sample [tick, ms, x, y] each frame the stick was off centre, and the frame it came back; only read from the pad, nothing sent', samples: frames.rs } : null, replay: JSON.parse(replayText) };
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
    var qs = [], names = ['What did you try that did not work?', 'What felt best?', 'What would you change first?'], fields = [];
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
        if (seen[eid] === 1) continue;
        seen[eid] = 1;
        try { var L = JSON.parse(localStorage.getItem(K + '-list') || '[]'); L.push({ at: e.at, over: !!e.over, replay: e.replay, frames: e.frames ? Object.assign({}, e.frames, { rs: undefined }) : null }); while (L.length > 5) L.shift(); localStorage.setItem(K + '-list', JSON.stringify(L)); } catch (x) { /* storage full or private: the card still offers it */ }
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
export function injectPage(html, meta = null) {
  if (html.includes('orb-blackbox-last')) return html;
  const stamp = meta ? `<script>window.__build = ${JSON.stringify(meta).replace(/</g, '\u003c')};</script>` : '';
  const tag = `${stamp}<script>${PAGE_SCRIPT}</script>`;
  return html.includes('</body>') ? html.replace('</body>', () => `${tag}\n</body>`) : html + tag;
}

export const BB_FINGERPRINT = createHash('sha1').update(JSON.stringify([HOOKS, HOST_FUNCS, PAGE_SCRIPT])).digest('hex').slice(0, 6);
