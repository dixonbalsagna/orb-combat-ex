# Sound after a start with the pad alone (Audio and Music, 2026-11-07)

Orb's morning play (`orb-first-play-20261107-1229.json`, build e80b8e3d, Opera GX): "sound effects weren't audible until I paused the game the first time".

## What the file says

- Two AudioContexts: the engine's (made at 520 ms) and the page player's (`AudioWeb`, 2,978 ms). **Both `suspended` from creation.**
- The first trusted input the page saw was a `keydown` at 178,422 ms. **Both contexts were `running` 121 and 122 ms later**, and the first sound reached the output at 178,572 ms. Before that the pad had been played for three minutes (`rawPad` frames, 400 rumble requests) and nothing was audible. "resumes asked 2" is the shell's two asks on that one key.
- After it, everything worked: 1,133 page-player sounds started, none refused, peak 0.89.

So nothing was broken in the sound itself. The browser holds an AudioContext suspended until the page has had a user activation, and **nothing in the page asked the contexts to run on a pad press**: the engine resumes only from its own mouse, key and touch handlers, the page player's `wake` listened to pointer, mouse, key, touch and click, and the shell snippet the same. A pad-only start never gave any of them an event.

## What a browser allows (measured, real Chrome, the real autoplay policy)

`audio/tools/pad_start_check.mjs`, through Tools' launcher, with no `--autoplay-policy` flag:

| Situation | Result |
| :--- | :--- |
| A fresh page, nothing pressed | both contexts `suspended`; `navigator.userActivation.hasBeenActive` is false |
| A scripted pad press with no activation (both players ask) | **both stay suspended**: a script's `resume()` is refused without an activation |
| A key (CDP trusted key event) | both run at once |
| A mouse click | both run at once |
| A key first, then a context made | runs with no further press |
| One activation earlier, both suspended again, then **a pad press alone** | **both run** (shell woke 2, player woke 1) |

So the code can always ask on a pad press, and the ask works **whenever the page has had any activation before**. Whether a *real* pad press counts as an activation in Opera GX or Chrome is not something headless Chrome can answer (a scripted pad is not a pad). Orb's file can't either: nobody asked on a pad press then. The next recorded play answers it, from three counters now in the audio status line: `pad seen N asked N woke N` (seen: presses read; asked: resumes requested; woke: contexts that were running 0.4 s later). `woke 0` with `asked` above 0 and sound still off after pad-only play means the browser does not count a pad.

## What changed (my files; presentation only)

1. **`audio/audio_web.gd`** (the page player's JavaScript): the listener list gains `pointerup`, `mouseup` and `keyup`, and **while the context is not running, the pad's buttons and sticks are polled (80 ms; a button, or a stick past 0.6) and a new press asks the context to run** (again after 1.5 s if the button is held and nothing started; the `gamepadconnected` event asks too). When the context runs, the poll stops (no cost in play). Counters `W.pad` {seen, asked, woke, last} and the status line carries them.
2. **`docs/audio/pending/audio-resume/shell-snippet.js`** (the shell hook for the engine's own context; Tools' file to land): the same pad poll for every context it keeps, the same extra events, a context made after the page has already been pressed in is asked at once (`navigator.userActivation.hasBeenActive`), and `state()` carries the pad counters. `shell_check.mjs`: 39 checks on a mock (the pad cases included).
3. **`audio/audio_voices.gd`**: `web_blocked()`, a read-only getter: true on the web while the player's context is not running, or (asked twice a second) one of the shell's contexts is suspended. For UI's start notice (below). Nothing reads it yet.
4. **`audio/tools/pad_start_check.mjs`** (new): the real-browser proof above, 15 checks.

Gates: `pad_start_check` 15 ok, `shell_check` 39 ok, `web_voices_check` passes (real Chrome), `status_check` and `web_policy_check` pass on a scratch export of HEAD.

## What this does not fix, and what does

If a real pad press is **not** an activation, no page code can start the sound: only a key, a click or a touch does. Then a pad-only player must be told once. That is **UI's start card** (the first-start card or the start menu): on the web, while `audio.web_blocked()` is true, one plain line on the card: "Sound starts when you press a key or click" (the card's pad button would not do it). I have not built it: it is on screen, so it is UI's and the look gate's. The getter is there for it.

The engine's own context (beds, music, ambience) is reachable only by the shell snippet, which today is injected only into the black-box builds. **Tools: the snippet goes into the head of every web build, the public site's too.** Without it the player's sound effects are fixed by (1) but the engine's loops and music still depend on a key or click.

## Risks

- The pad poll reads `navigator.getGamepads()` every 80 ms while sound is off; it stops at once when the context runs. An Opera GX / Chrome that refuses a pad press costs one `resume()` per press and one counter.
- A wrong guess in either direction is visible in the next play file (`pad woke`).
- Nothing was heard or seen; the look gate does not apply (no pixels).
