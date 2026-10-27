# The live demo froze on a friend's Android phone: what the boot does, and how to catch it next time (2026-10-26)

Owner: Performance and Platform, for the EP. Trigger: the live site (pin 257a766c, the owner interim, click-through and Reduce flashing locked on) froze "during the intro" on a friend's Android phone; Orb could not reproduce it; no device details yet. **No cause is proven for that phone. What is proven: the page's first start is one main-thread block of 22 s on this PC (the fastest CPU in the house) and 56 s on a CPU six times slower, with nothing on screen but the loading splash; that is the most likely thing to be called "frozen".** The tools here find the next case.

## Method

A clean `git archive` export of 257a766c (`make-audit-sites.mjs --rev 257a766c --only plain`, and `bootprof`, the same with time marks in `main._ready`), served to headless Chrome through Tools' launcher (`tools/machine/browser.mjs`: below-normal priority, a time limit, a session-named profile). Android-like conditions: mobile emulation with touch, a Pixel-like user agent, 915 by 412 CSS pixels at a pixel ratio of 2.625 (a 2402 by 1082 canvas), a 4 and 6 times CPU throttle, and software GL (SwiftShader). A script injected before the page loads (nothing in the export changes) records long tasks, a frame heartbeat, the AudioContext, WebGL context events and visibility. Taps go through CDP touch events on the notice card's "I understand, start" and the How to play card's close. The tool is `docs/perf/tools/freeze-probe.mjs` (options `--throttle --dpr --swiftshader --taps --after-bp --rotate --hide --trace --reload-at --prime --lose-context-at`).

## 1. Every long main-thread task in the boot and the intro

The whole boot is **one synchronous call into the wasm** (a trace shows a single `v8.callFunction` of 22.5 s starting 0.3 s after the page begins), so the page cannot paint, scroll or answer a tap until it ends. Marks inside it (seconds; the CPU's throttle in the header; the card is the notice with "I understand, start"):

| Stage | x1 (this PC) | x4 CPU | x6 CPU (a phone's CPU, estimate) | SwiftShader (software GL), x1 |
|---|---|---|---|---|
| Engine start: the wasm, the pck, the scripts, up to `main._ready` | 3.6 | 9.2 | 15.9 | 1.9 |
| `_ready`: the panes and the HUD, the rest | 0.5 | 1.9 | 2.9 | 0.5 |
| `_ready`: **the audio bank warm-up** (`bank.warm()`, every sound rendered at boot) | 2.0 | **9.7** | **14.4** | 2.2 |
| `_ready`: `start_match` | 1.1 | 4.8 | 7.9 | 1.1 |
| **The first frame** (the shader compile of everything drawn first, and the boot warm-up) | **15.6** | **15.2** | **15.9** | 1.5 |
| **The card is on screen at** | **22.8** | **40.9** | **57.0** | 7.1 |
| The one long task | 22.5 | 40.3 | 56.3 | 6.9 |
| The intro (card closed): tasks over 250 ms | 0.66, 0.27 | 0.30, 0.81, 0.30 | 0.68, 0.94, 0.37, 0.43 | every frame 0.4 to 0.8 s |

- **The CPU parts scale with the CPU (3.6, 9.2, 15.9 s for the engine; 2.0, 9.7, 14.4 s for the audio bank; 1.1, 4.8, 7.9 s for the match start); the first frame does not (15 to 16 s at every throttle): it is the graphics driver compiling shaders, not our CPU.** On this PC the driver is ANGLE over Direct3D, a slow compiler; a phone's driver is a different compiler (often faster per shader, sometimes much slower on a mid Mali). The 15 s is therefore a measurement of this PC's driver, not a forecast.
- **A mid-range phone's CPU is plausibly 5 to 8 times slower than this one**, so the x6 column (57 s with a frozen splash) is the middle estimate and 1.5 to 2.5 minutes is possible on a low-end phone. Nothing is drawn after the splash's last paint until the card appears; Android may offer "page unresponsive" or the player gives up.
- **The intro itself is short** here: after the card the stalls are 0.3 to 0.9 s even at x6 (the first draw of the fighters and the match). It is not the long block; "froze during the intro" is most likely the player calling the splash and the long start "the intro".
- **A weak GPU makes it look frozen in play too.** Under software GL (a phone Chrome has put on the software fallback, which it does for old or blocklisted GPUs) the game runs at 0.4 to 0.8 s a frame (about 2 fps) after a 7 s boot. And fill rate: on the integrated Radeon the AI match costs 5.0 ms at 915 by 412 pixels, 6.2 ms at a pixel ratio of 1.5 and **10.8 ms at the phone's 2.6** (the project has no stretch setting, so the canvas is the device's own pixels: 2.6 megapixels against 0.9 on a laptop); a phone GPU a third as fast as that Radeon would take about 30 ms of fill alone.

## 2. The web-build risks checked

| Risk | Finding |
|---|---|
| Threaded export, SharedArrayBuffer, COOP and COEP, a service-worker reload loop | **Not a risk.** `thread_support=false`; no cross-origin-isolation headers needed (`ensureCrossOriginIsolationHeaders` false, `GODOT_THREADS_ENABLED` false); `progressive_web_app/enabled=false`, so no service worker is registered and the template's reload path cannot run. `Engine.getMissingFeatures` only checks WebGL 2 and WebAssembly; a phone without WebGL 2 sees a plain error text, not a freeze. |
| Wasm memory on 32-bit Android Chrome | **Cannot be measured here.** The renderer process sits at about 520 MB after boot and the GPU process at about 350 MB (budgets.md: 450 MB target, 600 MB limit), 1.0 to 1.1 GB for the whole browser. On a 3 to 4 GB phone with other tabs that is at the edge, and a tab killed for memory reloads and starts the 1 minute boot again, which looks like a freeze. The JS heap is stable (30 to 55 MB over 400 s: no leak). Needs a real device. |
| A lost WebGL context that is never restored | **A real hazard.** The engine's own glue handles it with `alert("WebGL context lost, please reload the page")` and never restores the context (the string is in `index.js`). On Android a modal alert in a background-resumed page can be hidden or missed and the game stays dead. Tested: losing the context (the `WEBGL_lose_context` extension) with the park below shows a page notice with a reload button instead. |
| An audio unlock that waits on a gesture that never comes | **Not a block.** The AudioContext is created suspended at boot and goes to running 0.8 s after the first tap (the notice's button). Without a tap the page is only silent; nothing waits on it. The audio bank's boot warm-up (2.0 s at x1, 14.4 s at x6) is CPU work, separate from the unlock. |
| Rotation, backgrounding mid-intro | **Recovered.** A portrait rotation for 3 s and a frozen lifecycle (background) for 6 s mid-intro: no stall beyond the intro's own, the heartbeat resumed, no context loss. (Headless: a real phone may drop the context on a long background.) |
| A phone opening the link in an app's own browser (chat apps' web views) | Not tested; a likely source of surprises (limited WebGL, memory, no fullscreen). Worth asking the friend how the link was opened. |

## 3. The smallest fixes, and who owns them (ordered by what they remove from the one block)

1. **A visible start state, today, in the shell** (Performance; part of the park below): a plain line under the splash from the first paint, "Starting. First start takes longer on a phone ... it is still working", and the download percentage. Removes none of the time; stops it from reading as a freeze. A public change: look gate (ADR 0010) and Communications for the words.
2. **Spread the audio bank's boot warm-up** (Audio): `bank.warm()` renders every sound inside `_ready`: 2.0 s at x1, 9.7 s at x4, 14.4 s at x6. Time-slice it (a few sounds a frame behind a progress line), or render a sound on its first play with a short cap. Takes about a quarter of the block away on a phone.
3. **Spread the first frame's compile** (Rendering, with the boot warm-up they own): draw the boot scene's materials a few at a time over several frames behind a progress line, so no single block is more than a second or two: 15 s on this PC's driver is one block today.
4. **The match start** (Simulation, World): 1.1 s at x1, 7.9 s at x6; the planet generation already steps in `SimRun.beginGround`; a match start that does the same keeps the block under a second a frame.
5. **The engine start, 3.6 to 15.9 s** (Tools): the wasm is 38 MB (gzip about a quarter of that on the wire) and the pck 9 MB; a custom export template without the modules the game does not use (and size optimisation) shortens the parse and compile. Not measured; the share of the 3.6 s that is the wasm compile against the scripts' load is not known.
5. **Lost context** (the park): replace the engine's alert with a page notice and a reload button.
6. **Resolution** (Rendering, Camera): on phones render at 0.5 to 0.75 of the pixel ratio and let the browser scale: the Radeon's 5.0 ms at 0.4 megapixels against 10.8 ms at 2.6 megapixels is half of the frame.

## 4. The park: freeze breadcrumbs, local only

`docs/perf/web-shell/ocx-crumbs.js` (a park: **off**, nothing in the repo's export preset changes until the EP lands it; `node docs/perf/tools/web-head.mjs --write --crumbs` folds it into the Web preset's `head_include`, `--check` still passes without the flag). It writes one record to this browser's localStorage and nothing else: no network, no cookie, no third-party script, nothing sent. Tested on the live pin's export (scratch, `make-audit-sites.mjs --only crumbs`, which folds it into a scratch export preset):

- **What it records**: the stage (page loaded, downloading NN%, starting, running, and any stage the game names through `__ocx.crumbs.stage('...')`), a heartbeat, every main-thread stall of 3 s or more with the stage it started in (a stall of 22 s was recorded at the boot's start), long tasks over 0.5 s, visibility changes, a lost graphics context, errors, and the device facts a report needs (browser, screen, pixel ratio, memory, cores).
- **The static line** (item 1 above) is put up before the heavy start; a frozen main thread cannot paint anything, so this is the only way to say anything during the block. The watchdog's "still loading: stage X" cannot be drawn while the stall lasts; it can only be there before it and be accurate after it.
- **On the next load**, if the last visit had a stall of 5 s or more, or was closed before the game was running, or lost its graphics context, a small dismissable note says "Last time the page stopped responding for 22 s while it was at stage ... If it froze for you, copy a report; it stays on this device" with a Copy a report button. The report is plain text (browser, screen, pixel ratio, memory, cores, the graphics renderer string (read only when the report is made), the last stage and heartbeat, the stalls, long tasks, visibility, context events, errors). Tested: an abandoned-mid-boot record (primed into storage) shows the note; the report reads as expected; `?ocxreport=1` shows it any time.
- **The context-loss notice** replaces the engine's alert (tested with `WEBGL_lose_context`).
- **Game-side stage names (not applied; the owners are UI and Rendering, main.gd)**: `if OS.has_feature("web"): JavaScriptBridge.eval("window.__ocx && __ocx.crumbs && __ocx.crumbs.stage('first_frame')")` at the end of `_ready`, and the same with `'card'` when the first-run card shows, `'intro'` when the intro starts, `'playing'` when it ends; without them the record has the shell's stages only (starting, running).
- **Limits**: a freeze that ends in the tab being killed leaves the stage and the last heartbeat but not how long it lasted (nothing can run to record it); a freeze that ends normally is recorded in full. Nothing here can show a message during a frozen block.

**Re-cut to Legal's limits (p04, docs/legal/crumbs-screen.md; 2026-10-26).** The visitor sees the exact report as plain text (scrolling in its own box, Copy and Close above it) before anything is copied, and Copy copies that text; the graphics string is read only when the report is made (a test counts the reads: 0 at boot); no clock time anywhere (every time is milliseconds from the page's start; the record has no `t0` and no `page`), no page address, query or hash, error text cut to 120 characters and any web address in it or in the browser string cut to host and path; one record, replaced every visit, written only while the start is under way, after a stall of 5 s or more, or after a lost graphics context (a visit that reaches the running game with no long stall leaves **no** record), removed when the note is dismissed or the report copied, after which that visit writes none; no cookie. All visible words are PLACEHOLDERS in one table (`WORDS`) until Marketing's words pass Legal; Tools' interim check refuses the switch while they remain. Tests: `docs/perf/tools/crumbs-test.mjs` (34 checks on a stub page in the guarded browser) and a real-game run of the live HEAD with the park folded in (stall, record, note on reload). One behaviour for the EP: a phone whose every start stalls 5 s or more is offered the note on alternate visits (dismissing clears that visit's record, so the next visit has none, and the one after has one again).

## 5. What to ask the friend, and what would settle it

Model, Chrome or an app's web view, how the link was opened, whether the splash bar was full when it stopped, whether it ever came back (and after how long), sound, memory pressure (other apps), and whether it happens every time. If it comes back after a minute, it is the boot; if the card never comes, a context loss or a kill is next; if the card comes and play is a slideshow, it is the pixel count and the GPU. With the park landed, one visit and one tap on "Copy a report" settles the stage and the stall length.

## Not done

A real phone; a GPU driver's shader compile time on any phone GPU (the 15 s is this PC's); the wasm's share of the engine start; a memory ceiling forced on the page (Chrome offers none in headless); the in-app browsers.

## Files

`docs/perf/tools/freeze-probe.mjs`; `make-audit-sites.mjs` variants `plain`, `bootprof`, `crumbs`; `scratch-hooks/hook-bootprof.mjs` (marks in `main._ready` for the pin), `hook-crumbs.mjs`; `docs/perf/web-shell/ocx-crumbs.js` (the park); `web-head.mjs --crumbs`; `frame-bench.mjs --dpr`. Raw runs are in my scratch folder.
