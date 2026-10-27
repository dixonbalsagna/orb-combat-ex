// Freeze breadcrumbs for the web export's page (a PARK, off until the EP lands it): window.__ocx.crumbs. Source of truth for the script that docs/perf/tools/web-head.mjs --crumbs folds
// into export_presets.cfg (web preset, html/head_include), after ocx-shell.js. Owner: Performance and Platform. Written 2026-10-26 after a friend's Android phone froze on the live demo.
//
// What it does, and does not:
//  - LOCAL ONLY. It writes one small record to this browser's localStorage (key ocx.crumbs.v1) and nothing else. No network, no cookie, no third-party script, nothing is sent anywhere.
//  - It records, for the visit: the stage the page was in (page_loaded, downloading, starting, running, and any stage the game names through __ocx.crumbs.stage('...')), a heartbeat, every stall of
//    the page's main thread of 3 s or more (found when the page wakes: a stall cannot be drawn on while it lasts), the long tasks, visibility changes, a lost WebGL context, errors,
//    and the device facts a report needs (browser, screen, pixel ratio, memory, cores).
//  - On the NEXT load, if the last visit ended in a stall of 5 s or more, or was closed before the game was running, a small dismissable note offers a plain-text report to copy.
//    The GPU renderer string is read only when the report is made.
//  - A frozen main thread cannot show a message: the only thing the page can do about the freeze itself is the one static line it puts up BEFORE the heavy start (NOTE below).
// Write for the folder script: single quotes only, a semicolon at the end of every statement, no regex literals, no backslashes, no double slashes inside a line, no template strings.
(function () {
  var w = window, d = document, KEY = 'ocx.crumbs.v1', STALL_MS = 3000, BEAT_MS = 500, FLUSH_MS = 2000, REPORT_STALL_MS = 5000;
  var NOTE = 'First start takes longer on a phone: the graphics are prepared once. The page may look stuck for a minute; it is still working.';
  var t0 = Date.now();
  function now() { return Date.now() - t0; }
  function store() { try { return w.localStorage; } catch (e) { return null; } }
  function load() { var s = store(); try { return s ? JSON.parse(s.getItem(KEY) || 'null') : null; } catch (e) { return null; } }
  var prev = load();
  var c = { v: 1, t0: t0, ua: w.navigator.userAgent, dpr: w.devicePixelRatio || 1, scr: [w.screen.width, w.screen.height], inner: [w.innerWidth, w.innerHeight], mem: w.navigator.deviceMemory || null, cores: w.navigator.hardwareConcurrency || null, stage: 'page_loaded', stageAt: 0, beatAt: 0, dl: 0, clean: false, stalls: [], long: [], vis: [], ctx: [], err: [], page: String(w.location.pathname) };
  function flush() {
    var s = store();
    c.beatAt = now();
    try { if (s) { s.setItem(KEY, JSON.stringify(c)); } } catch (e) { }
  }
  function stage(name) {
    if (c.stage === name) { return; }
    c.stage = name; c.stageAt = now();
    flush();
    line();
  }
  // The static line: shown from the first moment, until the game is running. It is HTML text, so it is already on screen when the main thread blocks.
  var lineEl = null;
  function line() {
    if (!lineEl || !lineEl.parentNode) { return; }
    var running = c.stage === 'running' || c.stage === 'first_frame' || c.stage === 'playing' || c.stage === 'card' || c.stage === 'intro';
    lineEl.style.display = running ? 'none' : 'block';
    var names = { page_loaded: 'Starting', downloading: 'Downloading ' + c.dl + '%', starting: 'Preparing the game and its graphics' };
    lineEl.firstChild.nodeValue = (names[c.stage] || c.stage) + '. ' + NOTE;
  }
  function addLine() {
    if (lineEl || !d.body) { return; }
    lineEl = d.createElement('div');
    lineEl.id = 'ocx-stage-line';
    lineEl.style.cssText = 'position:fixed;left:0;right:0;bottom:6px;text-align:center;font:12px sans-serif;color:#9aa;pointer-events:none;z-index:2;padding:0 12px;';
    lineEl.appendChild(d.createTextNode(''));
    d.body.appendChild(lineEl);
    line();
  }
  // Stages from the shell page itself: the progress bar is the download, the removal of #status is the engine running (the template removes it when startGame() resolves).
  function watch() {
    var p = d.getElementById('status-progress'), st = d.getElementById('status');
    if (p && w.MutationObserver) {
      new w.MutationObserver(function () {
        if (p.max > 0 && p.value >= p.max) { c.dl = 100; stage('starting'); } else if (p.max > 0) { c.dl = Math.round(100 * p.value / p.max); stage('downloading'); line(); }
      }).observe(p, { attributes: true });
    }
    if (st && w.MutationObserver && d.body) {
      new w.MutationObserver(function () { if (!d.getElementById('status')) { stage('running'); } }).observe(d.body, { childList: true });
    }
  }
  // The heartbeat: a gap far over BEAT_MS between two ticks is a stall, noted when the page wakes.
  var last = Date.now(), lastStage = c.stage;
  w.setInterval(function () {
    var t = Date.now(), gap = t - last;
    last = t;
    if (gap > STALL_MS) {
      c.stalls.push([now() - gap, gap, lastStage]);
      if (c.stalls.length > 20) { c.stalls.shift(); }
      flush();
    }
    lastStage = c.stage;
  }, BEAT_MS);
  w.setInterval(flush, FLUSH_MS);
  try {
    new w.PerformanceObserver(function (l) {
      l.getEntries().forEach(function (e) {
        if (e.duration >= 500) { c.long.push([Math.round(e.startTime), Math.round(e.duration), c.stage]); if (c.long.length > 12) { c.long.shift(); } }
      });
    }).observe({ type: 'longtask', buffered: true });
  } catch (e) { }
  d.addEventListener('visibilitychange', function () { c.vis.push([now(), d.visibilityState]); if (c.vis.length > 20) { c.vis.shift(); } flush(); });
  // A lost graphics context. The engine's own glue answers it with a modal alert and never restores the context (Godot 4 cannot), so the game is dead from there: say so on the page and offer a reload,
  // instead of an alert that a phone may hide. stopImmediatePropagation keeps the engine's alert from showing; the event is still defaulted-prevented so the browser may restore the context for the page's own use.
  w.addEventListener('webglcontextlost', function (e) {
    c.ctx.push([now(), 'lost', c.stage]); flush();
    try { e.stopImmediatePropagation(); e.preventDefault(); } catch (x) { }
    if (d.getElementById('ocx-ctx-lost') || !d.body) { return; }
    var box = d.createElement('div');
    box.id = 'ocx-ctx-lost';
    box.style.cssText = 'position:fixed;left:0;right:0;top:0;bottom:0;background:#000d;color:#eef;font:16px sans-serif;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:12px;z-index:9;text-align:center;padding:16px;';
    box.appendChild(d.createTextNode('The phone took the graphics away from the page (usually after it was in the background or ran short of memory). The game cannot continue from here.'));
    var b = d.createElement('button');
    b.appendChild(d.createTextNode('Reload the game'));
    b.style.cssText = 'font:16px sans-serif;padding:10px 16px;border-radius:8px;border:1px solid #889;background:#334;color:#fff;';
    b.addEventListener('click', function () { w.location.reload(); });
    box.appendChild(b);
    d.body.appendChild(box);
  }, true);
  w.addEventListener('webglcontextrestored', function () { c.ctx.push([now(), 'restored', c.stage]); flush(); }, true);
  w.addEventListener('error', function (e) { c.err.push([now(), String(e.message).slice(0, 120)]); if (c.err.length > 6) { c.err.shift(); } });
  w.addEventListener('pagehide', function () { c.clean = c.stage === 'playing' || c.stage === 'intro' || c.stage === 'card' || c.stage === 'running'; flush(); });
  // The note on the next load.
  function gpu() {
    try {
      var cv = d.createElement('canvas'), gl = cv.getContext('webgl2') || cv.getContext('webgl');
      var ext = gl && gl.getExtension('WEBGL_debug_renderer_info');
      return ext ? gl.getParameter(ext.UNMASKED_RENDERER_WEBGL) + ' / ' + gl.getParameter(gl.MAX_TEXTURE_SIZE) : 'unknown';
    } catch (e) { return 'unavailable'; }
  }
  function reportText(r) {
    var rows = ['Orb Combat EX freeze report (stays on this device unless you paste it somewhere)', 'browser: ' + r.ua, 'screen: ' + r.scr.join('x') + ', window ' + r.inner.join('x') + ', pixel ratio ' + r.dpr, 'memory (GB, rounded by the browser): ' + r.mem + ', cores: ' + r.cores, 'graphics: ' + gpu(), 'last stage: ' + r.stage + ' at ' + Math.round(r.stageAt / 1000) + ' s, last heartbeat at ' + Math.round(r.beatAt / 1000) + ' s, download ' + r.dl + '%', 'ended cleanly: ' + r.clean, 'stalls (start ms, length ms, stage): ' + JSON.stringify(r.stalls), 'long tasks over 0.5 s: ' + JSON.stringify(r.long), 'visibility: ' + JSON.stringify(r.vis), 'graphics context: ' + JSON.stringify(r.ctx), 'errors: ' + JSON.stringify(r.err)];
    return rows.join(String.fromCharCode(10));
  }
  function worth(r) {
    if (!r || r.v !== 1) { return false; }
    var long = false;
    r.stalls.forEach(function (s) { if (s[1] >= REPORT_STALL_MS) { long = true; } });
    var early = !r.clean && (r.stage === 'page_loaded' || r.stage === 'downloading' || r.stage === 'starting');
    return long || early || r.ctx.length > 0;
  }
  function copy(text, btn) {
    function done(ok) { btn.firstChild.nodeValue = ok ? 'Copied' : 'Press and hold to select'; }
    try {
      if (w.navigator.clipboard && w.navigator.clipboard.writeText) { w.navigator.clipboard.writeText(text).then(function () { done(true); }, function () { fallback(); }); return; }
    } catch (e) { }
    fallback();
    function fallback() {
      var ta = d.createElement('textarea');
      ta.value = text; ta.style.cssText = 'position:fixed;left:0;top:0;width:90%;height:40%;z-index:5;';
      d.body.appendChild(ta); ta.focus(); ta.select();
      var ok = false;
      try { ok = d.execCommand('copy'); } catch (e) { }
      if (ok) { d.body.removeChild(ta); }
      done(ok);
    }
  }
  function note(r) {
    var box = d.createElement('div');
    box.id = 'ocx-crumbs-note';
    box.style.cssText = 'position:fixed;left:8px;right:8px;top:8px;background:#101418;color:#dde;border:1px solid #445;border-radius:8px;font:13px sans-serif;padding:8px 10px;z-index:6;display:flex;gap:8px;align-items:center;flex-wrap:wrap;';
    var msg = d.createElement('span');
    var worst = null;
    r.stalls.forEach(function (s) { if (!worst || s[1] > worst[1]) { worst = s; } });
    var what = worst && worst[1] >= REPORT_STALL_MS ? 'Last time the page stopped responding for ' + Math.round(worst[1] / 1000) + ' s while it was at stage ' + worst[2] + '.' : 'Last time the game seemed to stop at stage ' + r.stage + '.';
    msg.appendChild(d.createTextNode(what + ' If it froze for you, copy a report; it stays on this device.'));
    msg.style.cssText = 'flex:1 1 220px;';
    function btn(label, fn) {
      var b = d.createElement('button');
      b.appendChild(d.createTextNode(label));
      b.style.cssText = 'font:13px sans-serif;padding:6px 10px;border-radius:6px;border:1px solid #667;background:#223;color:#fff;';
      b.addEventListener('click', fn);
      return b;
    }
    var b1 = btn('Copy a report', function () { copy(reportText(r), b1); });
    var b2 = btn('Dismiss', function () { if (box.parentNode) { box.parentNode.removeChild(box); } });
    box.appendChild(msg); box.appendChild(b1); box.appendChild(b2);
    d.body.appendChild(box);
  }
  function boot() {
    addLine();
    watch();
    if (worth(prev) || String(w.location.search).indexOf('ocxreport=1') >= 0) { note(prev || c); }
    flush();
  }
  if (d.readyState === 'loading') { d.addEventListener('DOMContentLoaded', boot); } else { boot(); }
  var o = w.__ocx = w.__ocx || { v: 1 };
  // The game (or the shell) names a stage: o.crumbs.stage('first_frame'), 'card', 'intro', 'playing'. Anything else is kept as given.
  o.crumbs = { stage: stage, record: function () { return c; }, previous: function () { return prev; }, report: function () { return reportText(c); } };
}());
