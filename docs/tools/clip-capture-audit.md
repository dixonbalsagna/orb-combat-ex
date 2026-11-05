# Capturing clips and GIFs: audit and plan (EP, 2026-11-04)

Orb wants development snippets on hand for marketing and a possible "how I'm making this game" video, made with as few tokens as possible.

## What exists

| Piece | Where | Committed? | What it does |
|---|---|---|---|
| Guarded browser launcher | `tools/machine/capture.mjs`, `browser.mjs` | yes | `still` and `frames`: a built page stepped one tick at a time, a picture per step |
| Capture hook with scenes | `render/tools/flash_capture.gd` (`?flashcap=1`) | yes, 18 scenes | `clash`, `signature`, `signaturecity`, `collapse`, `transform`, `launchai`, `clashcity`, `ai` and more, each seeded and repeatable |
| Reel of a real AI match | `tools/preview/reel.mjs` | yes | Stills around swings and launches, plus a record of every event |
| Replay of Orb's own match | `tools/preview/blackbox-clip.mjs` | yes | Plays a saved match back through the game and films it, with `--from` and `--to` ticks |
| Film-only scenes `chase`, `chargehold`, `towers`, `chapel`, and the `nohud` word that hides the HUD | Tools' scratch hook | **no** | Used for Orb's eight GIFs |
| Camera's `beamduel` scene and film camera | Camera's scratch | **no** | Used for the three beam-clash GIFs |
| GIF encoder: one palette, size limit, crop, fps | `docs/tools/pending/preview-stack-v6/scratch-tools/` (`mkgif.py`, `gifcut.py`, `gifs.py`, `sheet.py`, `globes.py`) | **parked, not on main** | Turns a folder of stills into a GIF under a size limit |
| Video output (MP4 or WebM) | none | | ffmpeg isn't installed |

## Where the tokens went

1. **Rebuilding a page for each batch.** Tools and Camera each made their own export, with their own scratch scenes.
2. **Looking at pictures to choose moments.** Contact sheets and stills are read as images, at roughly 1,000 to 2,000 tokens each.
3. **Staging by hand.** A new scene was written for each ask, then thrown away, so it couldn't be reused.
4. **Re-encoding by trial.** Each clip was cut, sized and re-cut.

## The plan: one clip kit, committed

1. **Keep the scenes.** Move `chase`, `chargehold`, `towers`, `chapel`, `beamduel`, the film camera moves and `nohud` into the committed hook, as film-only words that don't affect the game. Clips can then be remade on any future build.
2. **A recipe file.** `tools/clips/clips.json` names each clip: build, scene, seed, page words, tick window, crop, fps, size and output (GIF, PNG sequence or WebM). The sim is deterministic, so a recipe gives the same clip every time, and moves to a new build with no one looking.
3. **One command.** `node tools/clips/make.mjs <name|all> [--build <kept folder>]` exports or serves, captures through the guarded launcher, and encodes. It writes into `homework/Files/clips/<build>/` and reads no pictures back into a session.
4. **Find moments from events, not pictures.** Pick tick windows from the sim's own cues: launch, crater, `beam_clash_end`, a building falling, a catch. "The first beam struggle in seed 12345" becomes a window with no contact sheets.
5. **Real play.** `blackbox-clip.mjs` plus the encoder turns any match Orb saves into clips of what actually happened, which suits a devlog.
6. **Video for YouTube.** Chrome's recorder can write WebM with nothing to install. ffmpeg would add MP4 and better quality, but it's a download and needs Orb's go.

**Rough cost to build:** one Tools session of about 0.5 to 0.8 million tokens, with a small part from Camera. **After that:** a batch of clips costs tens of thousands of tokens, mostly the command and its report.

## Drafted additions (EP, 2026-11-04, for Orb's go)

1. **Clip button in the game.** One button press while playing (proposed: View plus RB on the pad, F9 on the keyboard) marks "the last 15 seconds" in the match's black box. Nothing is recorded as video: the black box already keeps the seed and every input, a few hundred KB a match. The kit renders each mark later from the replay, at full quality, with the HUD on or off. The game also bookmarks moments by itself: a launch, a crater, the end of a beam struggle, a building falling, a KO.
2. **Replay viewer and photo mode.** Open a saved match, scrub to any tick, frame a shot with an eased free camera, hide the HUD, and save the shot as a recipe line. The kit renders it, so nobody stages scenes by hand.
3. **Automatic highlights and before/after.** The kit scores a saved match's events (biggest crater, longest launch, a beam struggle won, a comeback) and renders the top few as clips with a one-page index. It can also play the same seed on two builds side by side, for "how it changed" segments.

**Video straight from the page (optional):** the browser's own recorder (canvas capture plus MediaRecorder) can save a WebM of what's on screen. It's a fallback for a quick share. The replay path gives better quality at no cost while playing.

**Browser extension: not recommended.** The page can already take hotkeys, save files and record video. An extension adds upkeep, only works in one browser, and needs its own privacy read. For raw screen recording with a voice-over, Windows' Game Bar (Win+Alt+G, Win+Alt+R) is built in and free.
