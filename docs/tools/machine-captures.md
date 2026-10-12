# Capturing pictures without taking the machine (2026-10-12)

Owner: Tools and Pipeline. The rule (CLAUDE.md, "Machine discipline"): **headless Chrome is started only through the project's launcher, never by a director's own script.** Every capture has a time limit, runs at below-normal priority, carries its session's name in its profile folder, and one software-rendered capture runs at a time per session.

Why: on 2026-10-12 from 07:20 to about 10:15 two software-rendered captures (`stepcap-*`, `--use-angle=swiftshader`) whose launcher was gone each took about 7.5 of the machine's 16 cores. A recent Chrome on Windows starts with a launcher process that exits at once and leaves the browser running under another PID, so a script that kills "its child" kills nothing; and SwiftShader takes every core it is given.

## The three commands

```
node tools/machine/capture.mjs still  --dir <built site> --path /index.html --out shot.png --session <you> [--wait-js "window.__ready"] [--init-js "window.__cap = 1"] [--after-js "..."]
node tools/machine/capture.mjs frames --dir <built site> --out <folder> --count 600 --step-js "window.__adv = {n}" --tick-js "window.__tick" --session <you> [--info-js "window.__scn"] [--format jpeg]
node tools/machine/captures.mjs                  # who has a capture browser open, how old, how much CPU, whether its launcher is alive, whether it is past its deadline
```

- `still` loads the page, waits (a pause, or until `--wait-js` is true), runs `--after-js`, saves one picture. `eval --js "expr"` is the same without a picture (a probe).
- `frames` steps a page that offers a hook, one tick a picture: it runs `--step-js` with `{n}` replaced by the frame number, waits until `--tick-js` reads at least `n`, saves frame `n`. That is a posed scene with a scratch hook, a study stepped a tick at a time (what `stepcap.mjs` did), a motion clip. `--init-js` runs before the page's own scripts, so a scratch hook is switched on by a global.
- The flash check's clips are `tools/flash/capture-web.mjs` and `run-pixels.mjs` (unchanged to use): they start their browser the same way.
- `--session <name>` (or `MERIDIAN_SESSION` in the environment) is the owner tag in the profile folder `cap-<session>-<purpose>-<id>`; use your own title's slug. `--time-limit <seconds>` is the hard limit (default 3600 for the wrapper; the flash capture's is its page timeout plus 5 minutes); the log states it and the time it ends. `--cpu-cap <percent>` (default 25).
- **A software-rendered capture (`--software`) is one at a time per session.** Hardware rendering (the default) is light; software rendering is what starved the machine.
- Need something the wrapper does not do? Import `launchBrowser` and `Cdp` from `tools/machine/browser.mjs` in your script (see its header): you keep your own logic and still get every guard. Do not call `spawn` on Chrome.

## What the launcher guarantees (and how it was checked on this PC)

| Guard | How | Check |
|---|---|---|
| a hard time limit | the job helper (`tools/machine/capture-job.ps1`) polls a deadline and ends the browser tree; the limit and its end time are in the log | `tools/machine/selftest.mjs` check 2 |
| cannot outlive its launcher | the browser tree is in a Windows **Job Object with kill-on-close**, held by the helper, which also polls the launching process and ends the job when it is gone; elsewhere a detached watchdog shell polls the parent and the deadline and kills by the profile folder | check 3 (launcher killed mid-run) |
| the launcher's own deadline | a timer in the launching process ends the browser **and the process** (exit code 124) at the hard end, even when it is stuck awaiting a page | check 3b |
| an idle capture is ended | every protocol call is a heartbeat; the helper ends the browser after 15 minutes (`idleS`) of silence while the launcher is still alive: the capture is done, or stuck, and a page left open keeps rendering | check 3c |
| no call waits for ever | a protocol call fails after 10 minutes, and at once when the connection closes (the browser is gone); before 2026-10-12 a capture whose browser was stopped by hand waited 15 hours | (in `Cdp`) |
| below-normal priority | the job's priority class | (set in the job) |
| a CPU cap | the job's **affinity mask: the highest-numbered 25% of the logical processors** (4 of 16) however many threads SwiftShader starts, the same cores for every capture, so all captures together stay inside it (a hard CPU-rate cap was tried first and starved the browser's start-up on a busy machine). The flash set's `run-pixels.mjs` uses 40% for its whole set (`--cpu-cap`) | check 4: a page that keeps every core busy |
| an owner you can read | profile folder `cap-<session>-<purpose>-<id>` in the temp folder, and a registry entry in `<temp>/meridian-captures/` (launcher pid, deadline, limits) | `captures.mjs` |

No install: Windows PowerShell 5.1 and its .NET (the helper compiles a few P/Invoke lines at start; about a second on an idle machine, much more on a busy one), and Node 24's built-ins.

`node tools/machine/selftest.mjs` runs the four checks on real browsers (about a minute; `--quick` skips the CPU check).

## Looking and reaping

`node tools/machine/captures.mjs` prints one row per capture browser: owner (`session/purpose`), processes, age, CPU seconds, whether its launcher is alive, its deadline and a state (`running`, `ORPHAN (guard ends it)`, `PAST DEADLINE, ORPHAN`). `--json` gives the same as data. `--reap` ends **only** those that are past their deadline **and** whose launcher is gone, by process tree, removes their profile folder and prints what it did; `--reap --dry` says what it would do. Old-style browsers (profile folders `flash-cap-*` and `stepcap-*`, no registry entry) have no deadline and a launcher pid that cannot be known; they are listed, and reaped only with `--legacy-minutes <n>` (an age, and no capture script of an earlier start still running). Registry entries and profile folders nothing runs on any more are removed by `--reap` after 10 and 15 minutes.

## Older launchers

`tools/bench-web.mjs`, `docs/perf/tools/phone-emu-check.mjs` and `research/engine-spike/tools/bench-browser.mjs` still start Chrome themselves (their owners decide when to move them onto `launchBrowser`). Scratch scripts such as `stepcap.mjs` (Animation's, in a session scratchpad) are replaced by `capture.mjs frames`.
