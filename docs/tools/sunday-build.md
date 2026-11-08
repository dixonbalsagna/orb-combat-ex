# The kept build, step by step (Tools, 2026-11-07; for Sunday's checked build and every one after)

The order Tools follows when the EP says "build". Every result that is a figure goes to `docs/tools/runs/<sha>/` as small text (CD-22); a figure with no saved output is "unverified". One Godot job and one browser capture at a time unless a step says three.

## 0. Before the word

- `node tools/preview/stack.mjs --list`: the manifest (`tools/preview/stack.json`) holds only what is not on main: Art's biomes overlay and the parks that are not ready. A park that has landed is removed; one that has not is added (its patch path in `docs/<owner>/pending/`). `--manifest <file>` builds a stack from another list.
- The switch table (`tools/preview/switches.mjs`): rows with `held` stay OFF with their reason (today: the four city rows and aimCuts; refusedCue was held until 2026-11-08 and is ON now). `flightStrikes` and `stickLungeLight` are ON by default and **wait**, naming the key, until the park that adds the key has landed; a row that waits is not an error. `--on <row>` turns a held row on, `--off <row>` turns any row off (both now really change the data, not just the list).
- `node tools/preview/preview-selftest.mjs` and `node tools/preview/pck-verify-selftest.mjs` pass.

## 1. Build

```
MERIDIAN_SESSION=tools-stack node tools/preview/stack-preview.mjs --rev <the commit the EP names> --no-serve
```

It unpacks the commit into a scratch tree, applies the parks, flips the active rows, injects Audio's shell snippet and the black box, imports and exports the Web build (below-normal priority), and then:

1. **Pack verify (new).** Every data row's key is read out of the built `index.pck` and compared with the list: an ON row must hold its value, any other row its old value or no key. A mismatch prints `PROBLEM (pack)` and fails the build. The full reading is `pck-verify.txt` beside the build. This is the check that would have caught the 2026-11-07 held rows.
2. The smoke check (boot, play 20 s).
3. `switch-list.txt`: every row, ON, WAITING or OFF with its reason and data key. Read it: the rows you expected on are on, the held ones are off with their reason, and what waits is waiting for a key that really is not in main.

A cached build means the key did not change. The key covers the commit, the parks, the active rows and the tools code (`switches`, `blackbox`, `preview`, `stack`); a change to any other tool file needs `--rebuild`.

## 2. The checks (one capture at a time)

With `W=<the build's web folder>` and `OUT=docs/tools/img/<name>`:

- Moving minute: `node tools/preview/reel.mjs --dir "$W" --out "$OUT-moving" --sticks3 --query "meteor=loud&tiles=1&audiolog=1" --cap 3600 --swings 99 --launches 99 --wall-check --limit 900`. Read: walls (drawn) under 180 ticks, flat face, page errors none, the sound log.
- A struggle: `--sticks7 --until-clash --keep-all`; the banner, the clash rows and the ring in the stills.
- Refusal words: `--sticks10 --after-words "Too close,Hit" --after-refused 60 --png` (a lossless still on every tick for 60 ticks after a word), on a plain build and one with UI's patch for a side-by-side.
- Sound, the pad wake (2026-11-07, after Orb's 1229 play: the contexts sat suspended for 178 s of pad play): `node tools/preview/playtest.mjs --dir "$W" --query "planet=7&go=1&blackbox=1&audiolog=1&preview=1" --out "$OUT-wake" --script tools/preview/wake-steps.json --probe`. It connects a scripted pad, taps A with nothing else pressed, then presses a key, and logs the audio state after each (`audio-before-any-pad.json`, `-after-pad`, `-after-key`). What it can prove in headless Chrome: the page's audio counters (pad seen, asked, woke) and that a key wakes both contexts; a scripted pad press is not a browser activation, so "pad woke" with no earlier key is only provable on a real pad (Orb's next file: the counters in the audio status line). Headless Chrome reads silent at the output; only a real audio device proves sound itself.
- The page's settings (the power page): `node tools/preview/power-page-check.mjs --dir "$W" --out docs/tools/runs/<sha>/power-page-check.txt` (six addresses, about 20 minutes, one browser at a time). Run it last of the page checks.

## 3. Hand over

```
node tools/preview/handover.mjs --dir "$W"                      # copies into homework/Files/builds/orb-first-play-<commit8>-<key8>, byte-checked, read-only, with its replay tree
node tools/preview/pck-verify.mjs --web homework/Files/builds/orb-first-play-<commit8>-<key8>/web   # the copy, read again
node tools/preview/make-shortcuts.mjs --kept orb-first-play-<commit8>-<key8> --port <a free port> --label "<name>"
```

Never `sed -i` a `.cmd`: it drops the carriage returns; the tool writes them. The shortcut opens the page on its own port; a port that is already listening is named in a note (Orb's older server windows are Orb's: never closed from here). Send the folder, the switch list and the check results to the EP (and to the stand-in and the other directors the EP names).

## 4. After the build, on a quiet machine

- `node tools/feel/gauntlet.mjs --n 10 --seed 1 --jobs 3 --tree homework/Files/builds/<kept>/tree` (add `--arms stick,orbs` for the thumb-paced pad), below-normal, at most 3 jobs; write `docs/tools/gauntlet-<build>.md` with the table.
- `node tools/feel/ledger.mjs <Orb's play file> --tree homework/Files/builds/<kept>/tree --json <out> --out <txt>`: silent and refused presses by kind and reason; a replay that does not reproduce says so in its header.
- `node tools/player-watch.mjs`: what the live site serves (the daily workflow runs it too).

## 5. Leave nothing behind

Delete my own scratch (`%TEMP%\meridian-feel`, `meridian-stack*`, `cap-tools-*`, `clipkit-*`, my scratchpad's big folders) and stop my own PIDs, never by image name; Orb's server windows stay. The EP commits; Tools never changes git state.

## Sunday 2026-11-08: two builds (the EP's plan after the stand-in's review, docs/ep/proposals/sunday-build-review.md)

- **Build 1, at "build" (about 04:15):** the full sequence above. It is the fallback if the fix batch misses. Shortcut with the travel lever: `node tools/preview/make-shortcuts.mjs --kept <folder> --port <free> --label "Sunday build" --words "travel=1.5"` (Game Design's first lever; at x2 a tier-4 full send passes the camera's 10,000 a second; Orb can still slide it).
- **refusedCue is ON in both builds** (the EP, 2026-11-08: Encounter confirms it is safe, stun_limit is gone, so nothing knocks on a landed hit): its row no longer has `held`, so the same tools produce both builds with no flag. For the play page: a masher pressing into a full queue gets a knock on every press past the three queued; `press.refusedBurstTicks` is the lever if that feels buzzy.
- **The gauntlet and the ledger** run after build 1's handover, below-normal, and must not overlap build 2: if they are still running at 07:00, stop them by PID (the gauntlet's cells are independent; resume with `--arms` for what is left) and resume after build 2.
- **Build 2 (after the fix batch, about 07:00):** the kept build, pack verify, smoke, the stills; the six-address check only for its default address unless there is time (`power-page-check.mjs --only "no power word"`). The LAN folder (Netcode) comes from build 2 if it is ready by about 07:40, otherwise from build 1.
