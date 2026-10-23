# Web parity: the sim bit for bit on the native and the web build

Owner: Simulation and Engine. 2026-10-23, on the EP's brief: online rollback and shared replays both need the sim to give the same bits on every build, and until now only native determinism was proven.

## The answer

**Yes, for everything measured.** The native build and the web (WebAssembly) build of HEAD 5cca07df give the same sim to the bit, and so does 89ead43a through the one-command check below:
- **All 45 keys of `golden.json`** are identical, natively and on the web. That covers 184,300 ticks of AI matches, both human-input replays and the planet keys.
- **6 extra keys** cover what ships switched off: every fight switch on, the calm turn, and the run's stage rings. They are identical native and web.

Builds measured: Godot 4.7.2's Windows x64 build and its web export (Compatibility renderer, single-threaded). The web build ran in headless Chrome 155 on Windows x64, through Tools' launcher.

| Part | What it holds | Native | Web |
| :--- | :--- | :--- | :--- |
| **Our math** | 60 constants as bit patterns; sin and cos, pow, exp and log, keyed draws, wrap; 8 RNG seeds; 4 × 9 stream seeds | identical | identical |
| **Tick 0** | 6 seeds' state hashes, and 12,474 values of seed 1's state | identical | identical |
| **Modules and data** | rally, cripple, mood, wounds, the intro and the composed intro; the fight and roster data hashes | identical | identical |
| **9 AI matches** | 8 of 18,000 ticks and one of 40,300. Every tick folds the fighters, the feed and the effects into a light digest, and every 120 ticks a checkpoint holds the state, view and camera hashes | identical | identical |
| **2 human-input replays** | 3,000 and 2,400 ticks: the scripted inputs and the run | identical | identical |
| **The planet** | 3 slices, 3 tick-0 states, a 3,600-tick planet match | identical | identical |
| **Extras** | 2 AI matches of 6,000 ticks with every fight switch on (depth, the air brake, forms, the launch's curve, hit-stop by weight, the ricochet); a 6,000-tick planet match with the calm turn on; 3 sample runs' stage rings (12 picks: the ring's bits, the score) with each stage played 600 ticks | (no golden value) | identical to native |

**The check works.** As a negative control I changed one character in the web results: one checkpoint's view hash in match 3, and the sin and cos hash. The comparison reported both, with the checkpoint's tick (9,240) and which hash.

## Why it holds

The four causes the EP listed, as the code stands:
- **Float printing.** No hash reads a printed float. `SimHash.Hasher.num` takes the double's 64 bits, and the golden's numbers are hex strings and whole numbers.
- **A built-in's rounding.** The sim's trig, exp and log are our own (`SimDetMath`), and so are JavaScript's rounding rules (`SimMathx`). Arithmetic is IEEE-754 binary64 on both: x64 builds use SSE2, never the x87, and WebAssembly's float operations are specified as IEEE-754. `sqrt` is correctly rounded on both. Tools' determinism lint keeps the engine's trig, PI and TAU, random numbers and clock out of the sim.
- **Dictionary order.** A GDScript Dictionary keeps insertion order on every platform. Key order in JSON is not a value: Godot's `JSON.stringify` sorts keys unless told not to, so the check compares keys, not text.
- **Our own math.** It is the same GDScript on both, and the constants come from bit patterns (`SimMathx.f64`), never from long literals.

## What this does not cover

- **Other browsers.** Firefox isn't installed on Orb's PC, and Safari (JavaScriptCore) was not run. WebAssembly specifies float results except NaN bit patterns, and the sim hashes no NaN, so they should agree, but they are unmeasured.
- **ARM builds** (phones, Apple silicon), which is the real risk for cross-device rollback. A C++ compiler may fuse `a * b + c` into one rounding on ARM. GDScript itself runs one operation at a time, but the engine's C++ built-ins that the sim calls (vector operations, `lerp`, `fposmod`, `snappedf`) could round differently. Run this check on the first ARM build. The Steam Deck is x86-64, like this PC.
- **The web build with threads**: the preset has thread support off, and the sim is single-threaded either way.
- **Another Godot version.** The engine is pinned at 4.7.2. A new version needs this check again.
- **The views** (render, VFX, audio) are not the sim. A difference there changes a picture, not a match.

## The check (CI-able)

`node sim/core/tools/web_parity.mjs [--godot <exe>] [--work <dir>] [--time-limit 3000] [--keep]` (parked at `pending/web-parity/`):

1. A copy of the project (`git archive HEAD`), whose main scene becomes the probe (`sim/core/tools/web_parity.tscn`).
2. Import. The probe runs natively (headless) and writes its results.
3. The web export, with the project's own "Web" preset.
4. The export runs in headless Chrome through Tools' launcher (`tools/machine/browser.mjs`: a time limit, below-normal priority, a CPU cap, a session-named profile). The probe publishes each result in `window.__wp`, read over the DevTools protocol.
5. Native and web are compared with `sim/core/test/golden.json` key by key, and the extras native against web. For a difference it reports the first checkpoint that differs and which hash. It exits 1 on any difference.

**Cost on Orb's PC:** about 5 minutes in all: import 11 s, the probe natively 126 s, the export 9 s, the browser's start and the web run 142 s. Native and web compute at nearly the same speed: the golden keys took 108 s natively and 125 s in Chrome. The 9 matches took 9.5 to 9.8 s each natively and 10.5 to 11.2 s on the web.

**For CI (Tools'):** the Ubuntu runners already have Godot 4.7.2 with its web templates (`.github/actions/setup-godot`) and headless Chrome (the pixel pipeline's self-test uses it). A job that runs `node sim/core/tools/web_parity.mjs --godot "$GODOT"` on changes to `sim/`, `data/` or the engine pin would hold the line.

## Traps met

- **Key order.** `JSON.stringify` in Godot sorts keys by default, and `golden.json` is written unsorted, so compare parsed values, not text.
- **The export's folder.** `--export-release` fails if its target folder doesn't exist.
- **The export filter's `tools/*`** only matches the top-level `tools/` folder. `sim/core/tools` (`SimGolden`, the parity and golden tools) ships in the web pack. It's small, and the game never runs it.
- **A frame that computes a whole match** (10 to 25 s on the web) holds the page, so a DevTools call waits until the frame ends. The probe does one key a frame, and the driver polls.
