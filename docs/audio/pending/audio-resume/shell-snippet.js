// Audio and Music: keep the page's AudioContext running (docs/audio/pending/audio-resume/README.md). Goes in the web shell's <head>, in its own
// <script>, BEFORE the engine script, so it sees the context the engine makes. It changes nothing but this: it keeps a reference to each
// AudioContext the page makes, asks each one that is not running to run on every trusted press of a mouse button, a key or a touch, on
// a press of a pad's button or stick (read with navigator.getGamepads: the engine listens to none of these but the first three, and
// only once), and when the tab becomes visible again, and answers `__audioShell.state()` for the game's audio log. A page with no Web
// Audio, or a second copy of this, does nothing.
(function () {
  try {
    var Orig = window.AudioContext || window.webkitAudioContext;
    if (!Orig || window.__audioShell) { return; }
    var list = [];
    var shell = { contexts: list, resumes: 0, last: '', pad: { seen: 0, asks: 0, woke: 0, last: '' } };
    window.__audioShell = shell;
    function ask(c, viaPad) {
      if (c.state === 'running' || c.state === 'closed') { return; }
      shell.resumes++;
      if (viaPad) {
        shell.pad.asks++;
        setTimeout(function () { if (c.state === 'running') { shell.pad.woke++; } else { shell.pad.last = 'a pad press did not start a context (state ' + c.state + ')'; } }, 400);
      }
      try {
        var p = c.resume();
        if (p && p.catch) { p.catch(function (err) { shell.last = String(err && err.name || err); }); }
      } catch (x) { shell.last = String(x); }
    }
    var wrapped = new Proxy(Orig, {
      construct: function (target, args) {
        var c = Reflect.construct(target, args, target);
        list.push(c);
        try { c.addEventListener('statechange', padWatch); } catch (x) { /* none */ }
        // a page the player has already pressed or clicked in may start sound with no new gesture
        try { if (navigator.userActivation && navigator.userActivation.hasBeenActive && c.state === 'suspended') { setTimeout(function () { ask(c, false); }, 0); } } catch (x) { /* none */ }
        padWatch();
        return c;
      }
    });
    window.AudioContext = wrapped;
    if (window.webkitAudioContext) { window.webkitAudioContext = wrapped; }
    function wake(e) {
      if (e && e.isTrusted === false) { return; }
      for (var i = 0; i < list.length; i++) { ask(list[i], false); }
    }
    ['pointerdown', 'pointerup', 'mousedown', 'mouseup', 'keydown', 'keyup', 'touchend', 'click'].forEach(function (ev) { window.addEventListener(ev, wake, true); });
    document.addEventListener('visibilitychange', function () { if (!document.hidden) { wake(null); } });
    // A pad press: polled only while some context is not running.
    var padTimer = 0, padDown = false, padAt = -1e9;
    function padPressed() {
      var gp = null, i, j, g;
      try { gp = navigator.getGamepads ? navigator.getGamepads() : null; } catch (x) { return false; }
      if (!gp) { return false; }
      for (i = 0; i < gp.length; i++) {
        g = gp[i];
        if (!g || g.connected === false) { continue; }
        for (j = 0; j < g.buttons.length; j++) { if (g.buttons[j].pressed || g.buttons[j].value > 0.5) { return true; } }
        for (j = 0; j < g.axes.length; j++) { if (Math.abs(g.axes[j]) > 0.6) { return true; } }
      }
      return false;
    }
    function padAskAll() { padAt = performance.now(); for (var i = 0; i < list.length; i++) { ask(list[i], true); } }
    function padTick() {
      var d = padPressed();
      if (d) { shell.pad.seen++; }
      if (d && (!padDown || performance.now() - padAt > 1500)) { padAskAll(); }
      padDown = d;
    }
    function padWatch() {
      var need = false;
      for (var i = 0; i < list.length; i++) { if (list[i].state !== 'running' && list[i].state !== 'closed') { need = true; } }
      if (!need) { if (padTimer) { clearInterval(padTimer); padTimer = 0; } return; }
      if (!padTimer) { padTimer = setInterval(padTick, 80); }
    }
    window.addEventListener('gamepadconnected', padAskAll);
    shell.state = function () {
      if (!list.length) { return 'no AudioContext made yet'; }
      return list.map(function (c) {
        return c.state + ' t=' + c.currentTime.toFixed(2) + ' ' + c.sampleRate + ' Hz out ' + (c.outputLatency || 0).toFixed(3) + ' s';
      }).join('; ') + ' | resumes asked ' + shell.resumes + ' | pad seen ' + shell.pad.seen + ' asked ' + shell.pad.asks + ' woke ' + shell.pad.woke + (shell.pad.last ? ' (' + shell.pad.last + ')' : '') + (shell.last ? ' last refused: ' + shell.last : '');
    };
  } catch (e) { /* the page's audio must never break because of this */ }
})();
