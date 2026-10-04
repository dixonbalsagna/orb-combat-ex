# Offline WAV to OGG encoding for music hand-backs (a proposal, nothing installed)

Owner: Tools and Pipeline. Date: 2026-10-04. Status: a proposal for the EP. Nothing is installed or vendored.

## The need

Audio's plan (`docs/audio/suno-direction.md` section 6): Suno hands back WAVs, Audio picks loop points and a gain, and the game ships **Ogg Vorbis at about quality 4** (about 128 kbps, about 2 MB for a 2-minute loop, about 20 MB for 12 cues). Godot imports Ogg Vorbis but cannot encode it, and ffmpeg is not installed on this machine. The raw WAVs stay out of git; the repo keeps the encoded files (`audio/music/ogg/`) and `audio/music/loops.json`.

## The route: `wasm-media-encoders` (a dev tool, offline, no budget)

The reference Ogg Vorbis encoder (Xiph's libogg and libvorbis) compiled to WebAssembly, used from a small Node script.

| | |
| :--- | :--- |
| Package | `wasm-media-encoders` 0.7.0 on npm (last release 2024-05), `github.com/arseneyr/wasm-media-encoders` |
| Licence of the package | MIT |
| Licence of what the Ogg path contains | libogg and libvorbis: BSD 3-clause (Xiph.Org Foundation). The package also ships a LAME MP3 build (LGPL); we never use `mp3.wasm`, and a dev dependency is not distributed with the game either way |
| Its one dependency | `@swc/helpers` (Apache-2.0), build helpers only |
| Size | about 3 MB unpacked, of which the Ogg WASM is about 158 KB minified |
| Interface | `createOggEncoder()`, then `configure({channels, sampleRate, vbrQuality})`, `encode(Float32Array[])`, `finalize()`. `vbrQuality` runs from -1 to 10; 4.0 is the quality 4 of the plan. 1 or 2 channels; no resampling (Suno's 44.1 or 48 kHz goes through as it is) |
| Runs on | Node 10 or later (we use 24), on any OS, no native build step |

**Why this and not the others**

| Option | Verdict |
| :--- | :--- |
| `libvorbis.js` (MIT, emscripten) and `vorbis-encoder-js` (ISC) | Older (2022), browser-first, limited API; the same libvorbis underneath. Fallbacks |
| `lamejs` and its forks | MP3 only, and LGPL-3.0. Lossy twice for the web build; not wanted |
| ffmpeg or `oggenc` | The usual route, but a native install on Orb's machine (and `oggenc`'s command-line tool is GPL). Free, but not zero-setup. If Orb installs ffmpeg anyway, `ffmpeg -i in.wav -c:a libvorbis -q:a 4 out.ogg` does the same job |
| Godot | Cannot encode Ogg |
| A browser's MediaRecorder | Opus or WebM, not Vorbis, and not sample-accurate |

## The step (to write once the first file is handed back)

`tools/music_encode.mjs`, Node standard library plus the encoder:

1. Read the WAV (PCM 16, 24 or 32 bit, or 32-bit float; stereo; our own small parser).
2. Apply `gain_db` from `audio/music/loops.json` as a gain only. If a sample would clip after the gain, stop and say so (Audio lowers the gain; nothing is limited), as the hand-back spec says.
3. Encode in one-second blocks at `vbrQuality` 4.0 (a flag), copying each returned block before the next call (the encoder owns the buffer).
4. Write `audio/music/ogg/<cue>_<slug>_t<take>.ogg`.
5. Round-trip check: decode the OGG headlessly in Godot (`AudioStreamOggVorbis`) and compare its length with the WAV's, so the loop points in samples hold. Vorbis keeps the sample count through the granule position, so they should; the check proves it once.

**Where it lives and CI.** In a folder of its own, `tools/music/` with its own `package.json` (the encoder as its only dependency), so the root install and CI stay dependency-free. CI never encodes: it only validates `loops.json` (the schema is in `tools/schemas/audio-loops.schema.json`).

**Origin log.** The OGGs are derived from Suno WAVs. The step can print the encoder name and version for Legal's origin log; Audio's sidecar text already holds the Suno side.

## What I need from the EP

- A yes to the route (or ffmpeg, if Orb prefers to install one program), and to a `tools/music/` folder. Then I install the dependency in that folder only (about 3 MB, from npm), and write the step when the first WAV lands.
- A vendored copy instead (copy `ogg.wasm`, the loader and the two licence texts into `tools/music/vendor/`) if the project wants no npm fetch at all. About 160 KB; the licences are named above.
