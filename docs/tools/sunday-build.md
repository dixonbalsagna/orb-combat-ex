# The kept build, step by step (Tools, 2026-11-07; for Sunday's checked build and every one after)

The order Tools follows when the EP says "build". Every result that is a figure goes to `docs/tools/runs/<sha>/` as small text (CD-22); a figure with no saved output is "unverified". One Godot job and one browser capture at a time unless a step says three.

## 0. Before the word

- `node tools/preview/stack.mjs --list`: the manifest (`tools/preview/stack.json`) holds only what is not on main: Art's biomes overlay and the parks that are not ready. A park that has landed is removed; one that has not is added (its patch path in `docs/<owner>/pending/`). `--manifest <file>` builds a stack from another list.
- The switch table (`tools/preview/switches.mjs`): rows with `held` stay OFF with their reason (today: refusedCue, the four city rows, aimCuts). `flightStrikes` and `stickLungeLight` are ON by default and **wait**, naming the key, until the park that adds the key has landed; a row that waits is not an error. `--on <row>` turns a held row on, `--off <row>` turns any row off (both now really change the data, not just the list).
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
- Sound: headless Chrome reads silent at the output; only a real audio device proves it. The play file's audio record says when the contexts woke.

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
