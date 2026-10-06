// Phone helpers for the web export's page: window.__ocx. Source of truth for the script that docs/perf/tools/web-head.mjs
// folds into export_presets.cfg (web preset, html/head_include). Owner: Performance and Platform.
//
// Rules this file keeps:
//  - PASSIVE. Nothing here runs a request, a prompt or a fullscreen call on its own. The game (UI's notice button) calls
//    __ocx.enterFullscreen() from a tap, so full screen can only ever come after the flashing-effects gate.
//  - No data leaves the device: no network, no storage, no third-party script.
//  - Write for the folder script: single quotes only, a semicolon at the end of every statement, no regex literals, no
//    backslashes, no double slashes inside a line, no template strings. The script strips comment lines and joins lines.
(function () {
  var w = window, d = document, s = w.screen, o = { v: 1, fs: 'off', locked: false, awake: false };
  function mm(q) { try { return w.matchMedia(q).matches; } catch (e) { return false; } }
  o.touch = mm('(pointer: coarse)') || ('ontouchstart' in w);
  // A phone, not a tablet: the short side of the screen is under 600 CSS pixels (iPhones are 375 to 440, iPads 744 and up).
  o.phone = o.touch && Math.min(s.width, s.height) < 600;
  o.canFullscreen = !!(d.fullscreenEnabled && d.documentElement.requestFullscreen);
  function update() {
    o.w = w.innerWidth; o.h = w.innerHeight;
    // The same rule the UI layout uses for its portrait layout (ui_layout.gd: vp.y > vp.x * 1.05), so the card and the layout never disagree.
    o.portrait = o.h > o.w * 1.05;
    o.standalone = w.navigator.standalone === true || mm('(display-mode: standalone)') || mm('(display-mode: fullscreen)');
    o.fullscreen = !!d.fullscreenElement;
    if (!o.fullscreen && o.fs === 'on') { o.fs = 'off'; o.locked = false; }
  }
  update();
  ['resize', 'orientationchange', 'fullscreenchange'].forEach(function (ev) { w.addEventListener(ev, update); });
  // Pinch zoom on iOS Safari (user-scalable=no is ignored there).
  w.addEventListener('gesturestart', function (e) { e.preventDefault(); }, { passive: false });
  // Full screen, from a tap. Returns 'unsupported' (iPhone Safari), 'pending' or 'denied'. o.fs settles to 'on' or 'denied'.
  o.enterFullscreen = function () {
    if (!o.canFullscreen) { o.fs = 'unsupported'; return o.fs; }
    if (o.fullscreen) { return 'on'; }
    var c = d.getElementById('canvas') || d.documentElement;
    try {
      o.fs = 'pending';
      Promise.resolve(c.requestFullscreen({ navigationUI: 'hide' })).then(function () {
        o.fs = 'on'; o.fullscreen = true; o.lockLandscape();
      }, function () { o.fs = 'denied'; });
    } catch (e) { o.fs = 'denied'; }
    return o.fs;
  };
  // Android Chrome allows the lock only while full screen. Elsewhere it rejects, and the portrait card is the answer.
  o.lockLandscape = function () {
    try {
      var so = s.orientation;
      if (so && so.lock) { so.lock('landscape').then(function () { o.locked = true; }, function () { o.locked = false; }); }
    } catch (e) { o.locked = false; }
  };
  o.exitFullscreen = function () {
    try { if (s.orientation && s.orientation.unlock) { s.orientation.unlock(); } } catch (e) { }
    o.locked = false;
    try { if (d.fullscreenElement) { d.exitFullscreen(); } } catch (e) { }
  };
  // Keep the screen from sleeping during a pad-only demo or a long clinch (touch already resets the timer). Needs the tab visible.
  var lock = null;
  function grab() {
    try {
      if (!w.navigator.wakeLock || d.visibilityState !== 'visible') { return; }
      w.navigator.wakeLock.request('screen').then(function (l) { lock = l; o.awake = true; l.addEventListener('release', function () { lock = null; o.awake = false; }); }, function () { o.awake = false; });
    } catch (e) { o.awake = false; }
  }
  o.keepAwake = function () { o.wantAwake = true; grab(); };
  d.addEventListener('visibilitychange', function () { if (o.wantAwake && !lock) { grab(); } });
  w.__ocx = o;
}());
