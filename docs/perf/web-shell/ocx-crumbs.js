// Freeze breadcrumbs for the web export's page (a PARK, off until the EP lands it): window.__ocx.crumbs. Source of truth for the script that docs/perf/tools/web-head.mjs --crumbs folds
// into export_presets.cfg (web preset, html/head_include), after ocx-shell.js. Owner: Performance and Platform. Written 2026-10-26; re-cut 2026-10-26 to Legal's five limits (docs/legal/crumbs-screen.md, p04).
//
// What it does, and does not:
//  - LOCAL ONLY. It keeps ONE small record in this browser's localStorage (key ocx.crumbs.v1) and nothing else. No network, no cookie (nothing here touches one), no third-party script, nothing is sent anywhere.
//  - It records, for the visit: the stage the page was in (page_loaded, downloading, starting, running, and any stage the game names through __ocx.crumbs.stage('...')), a heartbeat, every stall of the page's
//    main thread of 3 s or more (found when the page wakes: a stall cannot be drawn on while it lasts), the long tasks, visibility changes, a lost WebGL context, shortened errors, and the device facts
//    a report needs (browser, screen, pixel ratio, memory, cores).
//  - Legal's limits (p04), and where each is kept:
//      1. The visitor sees the exact report before copying: the note's first button shows it as plain text (scrolling inside its own box, buttons above it) and Copy copies that text and nothing else.
//      2. The browser string and the graphics string stay; the graphics string is read only when the report is made (when the visitor asks to see it), never at boot.
//      3. No identifier, no clock time (every time is a number of milliseconds from the page's start, never a date), no page URL, query or hash. Error text is cut to 120 characters and any URL in it
//         (or in the browser string) is cut to host and path.
//      4. One record, replaced on every visit. A visit that reaches the running game with no long stall leaves NO record; the record is kept only while the start is under way, after a stall of 5 s
//         or more, or after a lost graphics context. Dismissing the note or copying the report removes it.
//      5. No cookie is set.
//  - On the NEXT load, if the last visit ended in a stall of 5 s or more, or was closed before the game was running, or lost its graphics context, a small dismissable note offers the report.
//  - The words the visitor reads are the PLACEHOLDERS in WORDS below until Community and Marketing's words pass Legal (docs/marketing/phone-freeze-words.md has the draft). {braces} are filled in.
//  - A frozen main thread cannot show a message: the only thing the page can do about the freeze itself is the one static line it puts up BEFORE the heavy start.
// Write for the folder script: single quotes only, a semicolon at the end of every statement, no regex literals, no backslashes, no double slashes inside a line, no template strings.
(function () {
  var w = window, d = document, KEY = 'ocx.crumbs.v1', STALL_MS = 3000, BEAT_MS = 500, FLUSH_MS = 2000, REPORT_STALL_MS = 5000, ERR_MAX = 120;
  var WORDS = {
    start_line: 'PLACEHOLDER start line. Stage: {stage}.',
    stage_page_loaded: 'starting',
    stage_downloading: 'downloading {dl}%',
    stage_starting: 'getting ready',
    note_stall: 'PLACEHOLDER note: froze for {s} seconds.',
    note_early: 'PLACEHOLDER note: stopped before it finished starting.',
    note_ctx: 'PLACEHOLDER note: the graphics were taken away.',
    btn_show: 'PLACEHOLDER copy a report',
    btn_dismiss: 'PLACEHOLDER dismiss',
    shown_above: 'PLACEHOLDER exactly what will be copied:',
    btn_copy: 'PLACEHOLDER copy',
    btn_close: 'PLACEHOLDER close',
    copied: 'PLACEHOLDER copied',
    copy_failed: 'PLACEHOLDER could not copy; press and hold the text to select it',
    report_open: 'PLACEHOLDER report opening line',
    ctx_message: 'PLACEHOLDER graphics lost message',
    ctx_button: 'PLACEHOLDER reload',
  };
  function fill(text, map) {
    var out = text;
    Object.keys(map).forEach(function (k) { out = out.split('{' + k + '}').join(String(map[k])); });
    return out;
  }
  // Milliseconds from the page's start. Never a clock time.
  function now() { return Math.round(w.performance.now()); }
  // A URL cut to host and path: scheme, query and hash go. The marker is built from character codes so this file holds no URL text.
  function stripUrls(text, max) {
    var s = String(text), mark = String.fromCharCode(58, 47, 47), i = s.indexOf(mark);
    function isLetter(ch) { return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z'); }
    while (i >= 0) {
      var a = i;
      while (a > 0 && isLetter(s.charAt(a - 1))) { a--; }
      var b = i + 3;
      while (b < s.length && s.charAt(b) > ' ' && s.charAt(b) !== ')' && s.charAt(b) !== ']' && s.charAt(b) !== '>') { b++; }
      var rest = s.slice(i + 3, b), q = rest.indexOf('?'), h = rest.indexOf('#'), cut = -1;
      if (q >= 0) { cut = q; }
      if (h >= 0 && (cut < 0 || h < cut)) { cut = h; }
      if (cut >= 0) { rest = rest.slice(0, cut); }
      s = s.slice(0, a) + rest + s.slice(b);
      i = s.indexOf(mark, a + rest.length);
    }
    return s.slice(0, max || ERR_MAX);
  }
  function store() { try { return w.localStorage; } catch (e) { return null; } }
  function load() { var s = store(); try { return s ? JSON.parse(s.getItem(KEY) || 'null') : null; } catch (e) { return null; } }
  function erase() { var s = store(); try { if (s) { s.removeItem(KEY); } } catch (e) { } }
  var prev = load();
  var c = { v: 1, ua: stripUrls(w.navigator.userAgent, 300), dpr: w.devicePixelRatio || 1, scr: [w.screen.width, w.screen.height], inner: [w.innerWidth, w.innerHeight], mem: w.navigator.deviceMemory || null, cores: w.navigator.hardwareConcurrency || null, stage: 'page_loaded', stageAt: 0, beatAt: 0, dl: 0, clean: false, stalls: [], long: [], vis: [], ctx: [], err: [] };
  function longStall(r) {
    var yes = false;
    r.stalls.forEach(function (s) { if (s[1] >= REPORT_STALL_MS) { yes = true; } });
    return yes;
  }
  function starting(r) { return r.stage === 'page_loaded' || r.stage === 'downloading' || r.stage === 'starting'; }
  // The one record: written only while it is worth keeping, removed the moment the visit is clean.
  function flush() {
    var s = store();
    c.beatAt = now();
    try {
      if (!s) { return; }
      if (starting(c) || longStall(c) || c.ctx.length > 0) { s.setItem(KEY, JSON.stringify(c)); } else { s.removeItem(KEY); }
    } catch (e) { }
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
    var running = !starting(c);
    lineEl.style.display = running ? 'none' : 'block';
    var plain = WORDS['stage_' + c.stage] || c.stage;
    lineEl.firstChild.nodeValue = fill(WORDS.start_line, { stage: fill(plain, { dl: c.dl }) });
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
  // The heartbeat: a gap far over BEAT_MS between two ticks is a stall, noted when the page wakes, with the stage it began in.
  var last = w.performance.now(), lastStage = c.stage;
  w.setInterval(function () {
    var t = w.performance.now(), gap = t - last;
    last = t;
    if (gap > STALL_MS) {
      c.stalls.push([Math.round(t - gap), Math.round(gap), lastStage]);
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
    box.appendChild(d.createTextNode(WORDS.ctx_message));
    var b = d.createElement('button');
    b.appendChild(d.createTextNode(WORDS.ctx_button));
    b.style.cssText = 'font:16px sans-serif;padding:10px 16px;border-radius:8px;border:1px solid #889;background:#334;color:#fff;';
    b.addEventListener('click', function () { w.location.reload(); });
    box.appendChild(b);
    d.body.appendChild(box);
  }, true);
  w.addEventListener('webglcontextrestored', function () { c.ctx.push([now(), 'restored', c.stage]); flush(); }, true);
  w.addEventListener('error', function (e) { c.err.push([now(), stripUrls(e.message)]); if (c.err.length > 6) { c.err.shift(); } });
  w.addEventListener('pagehide', function () { c.clean = !starting(c); flush(); });
  // The report: made only when the visitor asks to see it. The graphics string is read here and nowhere else.
  function gpu() {
    try {
      var cv = d.createElement('canvas'), gl = cv.getContext('webgl2') || cv.getContext('webgl');
      var ext = gl && gl.getExtension('WEBGL_debug_renderer_info');
      return ext ? stripUrls(gl.getParameter(ext.UNMASKED_RENDERER_WEBGL), ERR_MAX) + ' / ' + gl.getParameter(gl.MAX_TEXTURE_SIZE) : 'unknown';
    } catch (e) { return 'unavailable'; }
  }
  function reportText(r) {
    var rows = [WORDS.report_open, 'browser: ' + r.ua, 'screen: ' + r.scr.join('x') + ', window ' + r.inner.join('x') + ', pixel ratio ' + r.dpr, 'memory (GB, rounded by the browser): ' + r.mem + ', cores: ' + r.cores, 'graphics: ' + gpu(), 'last stage: ' + r.stage + ' at ' + Math.round(r.stageAt / 1000) + ' s from the page start, last heartbeat at ' + Math.round(r.beatAt / 1000) + ' s, download ' + r.dl + '%', 'ended cleanly: ' + r.clean, 'stalls (start ms, length ms, stage): ' + JSON.stringify(r.stalls), 'long tasks over 0.5 s (start ms, length ms, stage): ' + JSON.stringify(r.long), 'visibility (ms, state): ' + JSON.stringify(r.vis), 'graphics context (ms, event, stage): ' + JSON.stringify(r.ctx), 'errors (ms, text): ' + JSON.stringify(r.err)];
    return rows.join(String.fromCharCode(10));
  }
  function worth(r) {
    if (!r || r.v !== 1) { return false; }
    return longStall(r) || (!r.clean && starting(r)) || r.ctx.length > 0;
  }
  function copy(text, btn) {
    function done(ok) { btn.firstChild.nodeValue = ok ? WORDS.copied : WORDS.copy_failed; }
    function fallback() {
      var ta = d.createElement('textarea');
      ta.value = text; ta.style.cssText = 'position:fixed;left:0;top:0;width:90%;height:40%;z-index:8;';
      d.body.appendChild(ta); ta.focus(); ta.select();
      var ok = false;
      try { ok = d.execCommand('copy'); } catch (e) { }
      if (ok) { d.body.removeChild(ta); }
      done(ok);
    }
    try {
      if (w.navigator.clipboard && w.navigator.clipboard.writeText) { w.navigator.clipboard.writeText(text).then(function () { done(true); erase(); }, function () { fallback(); }); return; }
    } catch (e) { }
    fallback();
  }
  function note(r) {
    var box = d.createElement('div');
    box.id = 'ocx-crumbs-note';
    box.style.cssText = 'position:fixed;left:8px;right:8px;top:8px;max-height:70%;overflow:auto;background:#101418;color:#dde;border:1px solid #445;border-radius:8px;font:13px sans-serif;padding:8px 10px;z-index:6;display:flex;gap:8px;align-items:center;flex-wrap:wrap;';
    var worst = null;
    r.stalls.forEach(function (s) { if (!worst || s[1] > worst[1]) { worst = s; } });
    var what = r.ctx.length > 0 ? WORDS.note_ctx : (worst && worst[1] >= REPORT_STALL_MS ? fill(WORDS.note_stall, { s: Math.round(worst[1] / 1000), stage: worst[2] }) : WORDS.note_early);
    var msg = d.createElement('span');
    msg.appendChild(d.createTextNode(what));
    msg.style.cssText = 'flex:1 1 220px;';
    function btn(label, fn) {
      var b = d.createElement('button');
      b.appendChild(d.createTextNode(label));
      b.style.cssText = 'font:13px sans-serif;padding:6px 10px;border-radius:6px;border:1px solid #667;background:#223;color:#fff;';
      b.addEventListener('click', fn);
      return b;
    }
    function remove() { if (box.parentNode) { box.parentNode.removeChild(box); } erase(); prev = null; }
    var bShow = btn(WORDS.btn_show, function () {
      if (d.getElementById('ocx-crumbs-report')) { return; }
      var text = reportText(r);
      var wrap = d.createElement('div');
      wrap.style.cssText = 'flex:1 1 100%;display:flex;gap:8px;flex-wrap:wrap;align-items:center;';
      var lab = d.createElement('span');
      lab.appendChild(d.createTextNode(WORDS.shown_above));
      lab.style.cssText = 'flex:1 1 100%;';
      var bCopy = btn(WORDS.btn_copy, function () { copy(pre.firstChild.nodeValue, bCopy); });
      var bClose = btn(WORDS.btn_close, remove);
      var pre = d.createElement('pre');
      pre.id = 'ocx-crumbs-report';
      pre.style.cssText = 'flex:1 1 100%;margin:0;padding:6px;max-height:34vh;overflow:auto;background:#000;color:#cde;font:11px monospace;white-space:pre-wrap;word-break:break-all;border-radius:6px;';
      pre.appendChild(d.createTextNode(text));
      wrap.appendChild(lab); wrap.appendChild(bCopy); wrap.appendChild(bClose); wrap.appendChild(pre);
      box.appendChild(wrap);
      bShow.style.display = 'none';
    });
    var bDismiss = btn(WORDS.btn_dismiss, remove);
    box.appendChild(msg); box.appendChild(bShow); box.appendChild(bDismiss);
    d.body.appendChild(box);
  }
  function boot() {
    addLine();
    watch();
    if (worth(prev)) { note(prev); } else if (String(w.location.search).indexOf('ocxreport=1') >= 0) { note(c); }
    flush();
  }
  if (d.readyState === 'loading') { d.addEventListener('DOMContentLoaded', boot); } else { boot(); }
  var o = w.__ocx = w.__ocx || { v: 1 };
  // The game (or the shell) names a stage: o.crumbs.stage('first_frame'), 'card', 'intro', 'playing'. Anything else is kept as given.
  o.crumbs = { stage: stage, record: function () { return c; }, previous: function () { return prev; }, report: function () { return reportText(c); } };
}());
