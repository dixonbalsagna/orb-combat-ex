# Park: keep the page's audio running (Audio and Music, 2026-11-01, overnight; re-cut after Tools' test)

**Not proven to be the cause** of Orb's silence: it is the robust thing a page can do about the browser's autoplay gate. The first cut asked from inside the game (`GodotAudio.ctx` through `JavaScriptBridge`); Tools found `GodotAudio` is not a global of the page, so that cut could not work and is withdrawn. This is the re-cut: a snippet for the **web shell** (`<head>` of the exported page), which is Tools' file, so it needs Tools' grant.

## The problem it guards against

A browser starts a page's `AudioContext` suspended until the page has had a user gesture (a mouse button, a key, a touch; **a pad is never one**). The engine resumes it only from its own mouse, key and touch callbacks, once, in the event. A context that misses that one chance (a pad-first start, a first press on something that is not the canvas, a browser that wanted a second try) stays silent in both playback modes while the pad rumbles as usual.

## What the snippet does (`shell-snippet.js`)

Put it in its own `<script>` in the shell's `<head>`, **before** the engine script (`index.js`), so it sees the context the engine makes. It wraps the `AudioContext` constructor with a Proxy (the engine does `new (window.AudioContext||window.webkitAudioContext)(opts)` when it starts, so it gets the wrapped one; `instanceof` and every option still work), keeps a reference to each context, and on every **trusted** `pointerdown`, `mousedown`, `keydown`, `touchend` and `click` (captured before the engine's own handler, inside the gesture), and when the tab becomes visible again, calls `resume()` on any context that is not running or closed. A refusal is remembered, never thrown. It also answers `window.__audioShell.state()` (state, clock, rate, output latency, how many resumes it asked and the last refusal), which the game's `AudioVoices.status_line()` prints on the web (the status-line park). With no Web Audio, or a second copy of the snippet, it does nothing. Everything is in a try/catch: the page's audio never breaks because of it.

Off the web there is no page, so nothing of this runs there.

## 2026-11-07 re-cut: the pad (see docs/audio/pad-start.md)

Orb's morning file: both contexts suspended for 178 s of pad play and running 120 ms after the first key. The snippet now also polls the pad's buttons and sticks (80 ms, only while a context is not running) and asks every kept context on a new press, listens to `pointerup`, `mouseup` and `keyup` too, runs a context made after the page was already pressed in, and its `state()` ends with `pad seen N asked N woke N`. `shell_check.mjs` is 39 checks; the real-browser proof is `audio/tools/pad_start_check.mjs`. **It must be in the head of every web build (the public site too), not only the black-box builds.**

## Proof

`node docs/audio/pending/audio-resume/shell_check.mjs` (no browser, no Godot): 22 checks against a mock browser: the context is still a context (`instanceof`, options), is kept, an untrusted press is ignored, a trusted press (each of the five kinds) runs a suspended context, a running one is not asked again, a context that falls back to suspended is asked again, a refusal is remembered, the tab coming back asks (and not while hidden), a closed context is left alone, `state()` reads, a webkit-only browser is wrapped, a second copy does nothing. **The real thing is Tools' activation test on real clicks.**

## For Tools

1. Add `shell-snippet.js` as the first `<script>` in the shell's head (inline, before `index.js`). It does not conflict with the `?audiolog` tap, which wraps `AudioNode.prototype.connect`; if blackbox.mjs also wraps the constructor, this one wraps whatever is there.
2. The status-line park's `AudioVoices.status_line()` reads `window.__audioShell.state()`; with no hook it says "no shell hook".

## Risks

- A `resume()` with no activation is refused quietly (at most one per press); nothing breaks.
- It cannot help if the context runs and the browser or device does not output; the sound log says which.
