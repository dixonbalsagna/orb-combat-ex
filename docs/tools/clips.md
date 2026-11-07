# Making clips (Tools, 2026-11-06)

**The one command, from the project folder:**

```
node tools/clips/make.mjs all
```

That makes the eleven clips Orb sent his friends (GIFs, 480 pixels wide, a few seconds, each under 600 KB) from the newest kept build, and puts them in `homework/Files/clips/<that build's folder>/`, with `index.txt` beside them: one line a clip, with its size, how long it is, and whether the flash check passed. Nothing is shown on screen while it works, and nobody has to look at pictures to choose a moment.

## What you can ask for

| You want | You run |
|---|---|
| One clip | `node tools/clips/make.mjs chase` (the names are in `node tools/clips/make.mjs --list`) |
| Another format | add `--format webm` (a video; the browser's own recorder makes it, nothing to install) or `--format png` (a numbered picture sequence) |
| Another build | add `--build orb-first-play-18852c72-72c49cb5` (a kept folder, or part of its name) |
| Clips of a match you played | `node tools/clips/make.mjs --from-match <your saved match file>` |
| What a recipe would do, without doing it | add `--dry` |

A clip takes about one to three minutes (the game's page has to load, and each clip is played tick by tick). The kit starts its own browser through Tools' guarded launcher, at low priority, with a time limit, and stops it when it is done. Run one at a time.

## The clip button, while you play

In the private pages with the black box:

- **F9** on the keyboard, or **View and RB together** on a pad, marks **the last 15 seconds**. A small note, "Clip marked", shows in the bottom-left corner of the page for a second and a half. Nothing is drawn over the game.
- The game also bookmarks **by itself**: every launch, crater, the end of a beam struggle (when that is on), a building falling and a KO.
- Marks and bookmarks are saved with the match when you save the match file ("Save my match file"). Nothing is recorded as video while you play: the black box already keeps the seed and every press, a few hundred KB a match.
- Later, `node tools/clips/make.mjs --from-match <that file>` plays the match back once and cuts a clip for each mark and bookmark: a GIF for each bookmark, a WebM for each 15-second mark. The match is played on the build it was recorded on (the kit finds that kept folder by the key in the file; a different build refuses the replay and the kit says so). The kit also says whether the replay was exactly the match you played.

## How a clip is described

`tools/clips/clips.json` has one recipe a clip. A recipe says:

- **the scene:** one of the capture hook's scenes (`clash`, `collapse`, `signaturedummy`, and the film scenes `chase`, `chargehold`, `towers` and Camera's `beamduel`) or a mockup script;
- **the seed and the page words,** so the same recipe makes the same clip every time (the game is deterministic). `nohud=1` hides the HUD; `power=1&peak=1` start the match at top power on a build that has it; Camera's `bdshot`, `bdgap`, `bdalt` set the beam duel's camera and distance;
- **the window:** `from` (the first tick), `frames` and `step` (ticks between pictures; 3 is every 20th of a second), **or an event:** `"event": { "name": "launch", "nth": 1, "before": 60, "after": 90 }`. The kit finds the event from the game's own record of what happened (launch, crater, building_fall, ko, catch, beam_clash_end, tier_up and more), so "the first launch" needs no looking at pictures;
- **the crop** of the 960 by 540 picture, the frame rate, the width and the size limit.

To make a new clip: copy a recipe, change the scene, seed, words and window, and run it. To move every clip to a newer build, just run `all` again with `--build`.

The encoder keeps one palette for a whole clip (so colours do not shimmer) and takes the palette down (64, 48, 40, 32, 24, 20, 16 colours) until the file fits. Every GIF goes through the flash check (`tools/flash/analyse-gif.mjs`) and its verdict is in `index.txt`; a clip that fails is replaced by another moment, not sent.

## The button strip, and the slots for the moves still to come

Every GIF and WebM has a **strip under the picture** (never over it, nothing covers a fighter): the left stick, LT, LB, X, Y, B, A, RB, RT and the right stick, each lit while the pad had it down (or had pressed it since the last picture), with a word under a lit one: **tap**, **hold** (12 ticks or more) or **mash** (three presses in 30 ticks). The right stick shows its direction and charge level. It is drawn from what the game was fed each tick (the hook's pad log), so it is what was pressed, not a guess. `--no-strip` leaves it off; a recipe sets `"strip": false` for a scene the computer plays, and `"stripSlot"` for the pad's slot (default 0). A build older than the pad log makes the clip without a strip. For a clip of a saved match (`--from-match`) the strip shows the pad of that match.

**Slots.** `clips.json` has a recipe slot for each flight strike (`flight-zip`, `flight-line`, `flight-arc`, `flight-parting-shot`) and each beam answer (`beam-answer-fire-back`, `-dodge`, `-powerful-block`, `-catch`, `-swat`, `-walk-in`), marked `"pending": true` with what each waits for. `all` skips them and naming one says what it waits for. When a move lands: give the slot a `scene` (a hook scene that presses it), its `words`, a `from` and `frames`, and remove `pending`; `node tools/clips/make.mjs --list` shows which are still open.

## Good to know

- **Which builds:** the film scenes and the event log are in the capture hook from 2026-11-06; a kept build made before then has the older scenes only (`clash`, `collapse`, `signaturedummy` and the other 15). Asking such a build for a film scene or an event window gives a plain message saying so. `selftest` uses an old scene on purpose, so it runs on any kept build.
- **The mockups** (`planet-today-vs-plates`, `megastructures-pan`) are made from pictures in the project (World's planet maps, Art's sheet), not from the game, and say so in their recipes. The globes are drawn by the kit from the flat maps, so the shading is simple.
- **Camera's three beam-clash clips** need Camera's park (`docs/camera/pending/clip-scenes`, its `main.gd` and `sim_host.gd` hunks) in the build, as well as the hook.
- **A clip is only fit to send** when it is a moment of the game as it plays: no concept sheets of fighters, no dissolves or fades, and no launch-swing or meteor wide shots (those pan fast).

## The self-test

`node tools/clips/clips-selftest.mjs` checks the recipes, the event names, the encoder (frames made on the spot) and then makes the `selftest` clip end to end on the kept build `orb-first-play-10d8b8cf-68ee07cc`. It skips that last step, and says so, if that folder is not on the PC (`--no-e2e` skips it too).

## For sessions (token note)

Run the command and read `index.txt`; do not open the pictures. A batch of clips costs the command and its report. Only Pillow (`python`, already on this PC) is needed besides Node; nothing else was installed.
