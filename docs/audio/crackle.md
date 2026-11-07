# The web crackle: one-shots played by the browser (Audio and Music, 2026-11-06)

Answers the EP's brief on Performance's `docs/perf/impact-stutter.md`: no crackle on high-speed impacts in the web build, even when a frame stalls. **Built, proved in a real browser by recording what reaches the speakers, parked** (`docs/audio/pending/crackle/`). **Nobody has listened to it**: the recordings below are for Orb's ear.

## What was wrong, and the fix in one paragraph

The no-threads web build mixes sound on the main thread and feeds the audio worklet through a ring that holds about 15 ms of sound (not the 50 ms `output_latency.web` suggests). A frame over about 40 ms drains it and the worklet writes silence for whole 2.7 ms blocks: a hole in the middle of a hit, a click at each edge. The fix is not to ask the main thread for the sound at all once it has started: **every short one-shot cue (hits, grunts, pings, ticks) is now played by the browser itself** as a plain Web Audio buffer source in a small graph of our own (`audio/audio_web.gd`), where it runs on the audio thread whatever the page does. Godot's players keep what loops or is moved after it starts (the beam struggle's beds, the coil, the ambience).

## The measurement (the page, Tools' capture hook, the browser's audio running; a scratch export of main 3c9005ac with the park; real GPU)

`docs/audio/tools/crackle-ab.mjs`: step an AI match (seed 7) to a tick that starts three cues, let them start, hold the main thread for L ms, and **record what each AudioContext sends to the speakers on the audio thread** (an AudioWorklet, so the stalled page cannot make holes in the recording). A hole is 1 ms or more of exact silence with sound within 8 ms on both sides. Same four ticks (1264, 1543, 1808, 2075) in every run.

| Stall | Before (main as it is; valid run, load 53 and 38%) | After (the page player) | A longer ring instead (`output_latency.web` 150, Stream) |
| ---: | :--- | :--- | :--- |
| none | 0 holes | 0 holes | 0 holes |
| 40 ms | 1 block skipped, 0 holes | 0 holes | 0 holes |
| 100 ms | 25 blocks skipped, **a 66.7 ms hole** | 25 skipped (silent Godot mixer), **0 holes** | 0 skipped, 0 holes |
| 150 ms | 40 blocks skipped, **a 106.7 ms hole** | 43 skipped (silent Godot mixer), **0 holes** | 0 skipped, 0 holes |

(A first "before" run on a quiet machine, load 10 to 12%, gave the same shape: 58.7 ms at 100 ms and 117.3 ms at 150 ms. The 150 ms run is marked INVALID by the 60% rule (load 42 to 86% while other sessions ran), but its numbers repeated in two runs.)

**Cost, the time from the call that steps the tick (where the cues start) to the first sound in the recording:** before 54 to 80 ms; after **18 to 29 ms, about 40 ms sooner**; the longer ring 190 to 200 ms, 125 ms later than today. The ring's lateness is the price Performance named; the page player has none: it plays sooner than the Stream path because it skips the ring.

Independent of the game, `audio/tools/web_voices_check.mjs` plays a steady 600 ms tone in the page player and stalls the page for 0, 40, 100, 150 and 300 ms: the tone is 600 ms long with no hole at any of them (longest silence 0.02 ms, a zero crossing).

## The options, and why this one

- **(a) A longer ring** (`output_latency.web` 150): stops the holes up to 150 ms and costs 125 ms of lateness on every sound, hits included; a longer stall still breaks it. Not chosen for hits. It is still a sensible companion for the sounds that stay on Godot's players (the beds and drones, where lateness does not matter) if Orb ever hears them click: one line in `project.godot` (Tools' file), not in this park.
- **(b) Godot's Sample playback mode:** not used. It plays through the engine's bus graph, reads silent at the destination on this project's build in headless Chrome and Opera GX (`docs/tools/preview.md`, "Sound modes"; the cause was never found), and skips the bus effects (the muffle, the limiter). I did not test it again.
- **(c) What I built:** the page plays the one-shot itself, in a graph where the effects are real: a low-pass for the muffled buses (900 and 1400 Hz from `mix.json`), a gain per bus that follows what the mixer holds (mix.json's levels, the player's trims, the launcher's duck), a compressor and a soft clip at the end. Godot's own context keeps running for the loops.

## The limiter and the distortion Performance asked about

**Yes, stacked impacts exceed the limiter.** Rendering each seeded match's cues into a mono sum before any limiter (`distance` and gain as the voices apply them; the worst case, centred): peaks of **+1.1 to +9.3 dBFS**, **0.3 to 2.3% of the active samples above the limiter's -6 dB threshold and up to 0.4% above 0 dBFS** (6 matches, 3 normal and 3 at tier 4). So Godot's soft-clipping limiter (threshold -6, ceiling -1) is working on about 1 in 50 samples of a busy fight and squeezing up to 9 dB at its worst: that is distortion on its own, separate from the stalls. In the recordings the "before" output at tick 1808 sits flat at exactly 0.891, the limiter's ceiling. I did not measure the distortion itself (harmonic content), only how often and how far the sum goes over.

In the page player the same fights are handled by the compressor (threshold -6 dB, 10:1, 1 ms attack) and a soft clip behind it that only shapes what the attack lets through (the recording at the same tick peaks at 0.84 with no flat top). The page's level is calibrated to Godot's: **with no trim the page's one-shots were 5.5 to 6 dB louder than the same cues through Godot's mixer** (I did not trace why: the page's StereoPanner is equal-power and Godot's 2D pan law plays the centre lower), so the park uses `WEB_TRIM_DB = -3`, which puts them within about 1 dB. The Master is still a limiter for the Godot players that remain. If the hits still sound squashed after listening, the next lever is the Sfx bus down 3 dB for both paths (`mix.json`), not more compression.

## What changes

- `audio/audio_web.gd` (new, `AudioWeb`): installs a page-side player (`window.__aweb`, its source is the `JS_SOURCE` string in that file: ES5 Web Audio), uploads each sound's samples once (16-bit PCM as base64: the JavaScript bridge passes strings and numbers, not byte arrays), and plays, stops and updates it. **Web only**, only with the JavaScript bridge, and `?webvoices=0` in the address gives the old path for comparing. Everywhere else it does nothing.
- `audio/audio_voices.gd`: a cue that is not a loop, not an ambience bed and not an update goes to the page when its context is running; the voices' rules (slots, groups, class caps, priority, the duck, the player's trims) are unchanged and apply to page voices through a `_busy(slot)` check; the buses' levels and the Master are sent to the page when they move; `stop_group` stops the page voice; `set_mono` reaches the page; `status_line()` gains the page player's counters. **Off the web the file plays as before** (host_check's cue logs are identical).
- A page voice does not start while the page's context is suspended (it would queue and dump at the first click): the Godot player takes the cue then, as before.
- `audio/tools/web_voices_check.mjs` (a real browser, through Tools' launcher) and `audio/tools/web_policy_check.gd` (the voices' rules against a stand-in for the page player). `docs/audio/tools/crackle-ab.mjs` is the A/B harness above.
- No project setting, export preset or shell file is touched: the player installs itself from the game (`JavaScriptBridge.eval`) and makes its own AudioContext, with its own resume on a press or a key (the engine's own context and the shell's resume are separate).

## Recordings for Orb's ear (`docs/audio/img/crackle/`, 48 kHz stereo 16-bit, 1.6 to 1.7 s each; the output of the page, recorded at the speakers' end of the graph)

- `crackle-before-stall100.wav` / `crackle-after-stall100.wav`: one impact burst (tick 1808) with the page stalled 100 ms right after it starts. Before: a 66.7 ms hole in the middle of it (a click at each edge). After: whole.
- `crackle-before-stall150.wav` / `crackle-after-stall150.wav`: the same at 150 ms (tick 2075): a 106.7 ms hole against none.
- `crackle-before-nostall.wav` / `crackle-after-nostall.wav`: a burst with no stall (tick 1264), to hear the level and the tone, which should match within about 1 dB. (They are not the same take: each run plays the cues a few milliseconds apart.)
- `ab-*.json`: the numbers behind the table.

## Risks and limits

- **Not heard, and the level is a calibration of one fight, not a mix.** Pan is approximated (a cue's offset from the camera over half the viewport, clamped), the muffle is a Web Audio low-pass against Godot's, and the page's graph has its own compressor.
- **Two AudioContexts** now exist (the engine's, and the page player's). Both need the browser's gesture; the page player resumes its own on a press, a key or a touch. A pad-only start leaves both suspended (the engine's existing problem, the audio-resume work) and the game is silent as it was.
- **Tested in Chrome** (the launcher's browser; Opera GX is Chromium). Edge and Firefox use the same Web Audio calls (`StereoPannerNode`, `DynamicsCompressorNode`, `WaveShaperNode`); I have not run them. The recording tool uses an `AudioWorklet`, tests only.
- The Godot players that remain (loops and moved sounds) can still skip blocks at a stall: the beam struggle's two drones, the coil, the ambience. Measured: the engine skips 25 blocks at a 100 ms stall, of silence when no loop is sounding.
- The first play of each sound sends its samples to the page (a base64 string, about 0.2 ms for a hit) once; 11 of them were sent in the first 1,200 ticks of the test match.
- The recorded hole metric is exact silence of 1 ms or more between sounds within 8 ms; a gap in a sound that is also quiet there would show as a hole, and a click from a cut at a non-zero value without a gap would not. It matches what the engine's skip counter says.

## Running it

```
node audio/tools/web_voices_check.mjs                                   # the page player in a real browser: stalls to 300 ms, the limiter, the muffle, a bus, stopGroup
godot --headless --path . --script res://audio/tools/web_policy_check.gd # the voices' rules against a stand-in
node docs/audio/tools/crackle-ab.mjs --dir <a web build's folder> --out <folder> [--query "webvoices=0"] --ticks 1264,1543,1808,2075 --stalls 0,40,100,150
```
