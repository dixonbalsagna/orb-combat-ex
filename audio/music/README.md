# audio/music/: where the finished music goes

Owner: Audio and Music. 2026-10-04. The plan is in `docs/audio/suno-direction.md` (the sound, the hand-back spec and the decisions) and `docs/audio/suno-prompts.md` (the 12 prompts). Suno makes the music from our prompts and reference clips; Orb downloads the files and puts them here.

## Orb: how to hand files back

1. Download the **WAV** of each take you like from Suno (not an MP3), and the stems if your plan has them.
2. Put the files in **`incoming/`**. Name them `M02_fight-1_t01_180bpm_E.wav`: the cue id and slug from the prompt block, `t` and the take number, the tempo you aimed for, and the key. Stems add `_stem-drums`, `_stem-bass`, `_stem-guitars`, `_stem-lead` or `_stem-brass`.
3. Next to each file, save a text file with the same name and `.txt` (`M02_fight-1_t01.txt`), made from `sidecar-template.txt`: the model version, your plan, the download date, the song link or id, the exact prompt and sliders, the names of the clips you uploaded, who chose the take and what was edited, and the result of your listen and a music-recognition check. Legal needs all of it (`docs/legal/suno-music.md`).
4. **Do not edit the audio, and keep every original download exactly as downloaded** (Suno's terms forbid removing or altering its metadata). Tell the EP, who tells Audio.

Generate and download on the **paid plan**, within the monthly download cap. Never describe the music as human-made, and do not register it in a music-ID or distribution service.

`incoming/` has a `.gdignore`, so Godot ignores the raw files. **Raw WAVs and MP3s are large (a 3-minute stereo file is about 30 MB) and are git-ignored** (root `.gitignore`); Orb keeps them on disk here. Every original stays untouched in `incoming/`, and only a processed copy is shipped. What the repo keeps is the encoded chosen takes, the sidecar records and the loop data below.

## What Audio does with them

**Legal's conditions for shipping a processed copy** (`docs/legal/suno-music.md`; the hold is lifted once these are in the pipeline): (1) no concealing purpose, and no watermark-removal or detection-evasion tool or setting, ever; (2) keep the untouched original and the sidecar record for every shipped file; (3) the notice and the store disclosures say the music is AI-made with Suno; (4) processing stays ordinary: gain, a cut, an encode, with no re-synthesis, pitch or time tricks and no restoration tools; (5) the original's metadata is copied into the sidecar, because the shipped copy may not carry it.

```
node audio/tools/music_check.mjs incoming/M02_fight-1_t01_180bpm_E.wav --bars 32 --write-sidecar
```

`--write-sidecar` adds the original's SHA-256 checksum, its chunk list, a copy of its metadata (LIST/INFO tags, id3 and any other chunk) and a "metadata kept" line to the sidecar text file (it never writes to the audio). It prints the format, the integrated loudness (LUFS) and the gain to the target of -16 LUFS, an approximate true peak, the tempo (and whether it drifts) and the best bar-aligned loop points. A take within about 2 BPM of its target and without drift goes on.

Planned layout once files exist (nothing here yet):

| Path | What |
| :--- | :--- |
| `incoming/` | Raw Suno downloads and their sidecar text files (not for git) |
| `ogg/` | The encoded game files, one per cue and take, loudness-normalised to -16 LUFS |
| `NOTICE.txt` | Legal's audio notice: the music is not under the project licence, was made with Suno, and its metadata must be kept |
| `sidecar-template.txt` | The record to fill in for each file |
| `loops.json` | For each cue: file, tempo, loop start and end in samples, bars, gain. Needs a schema from Tools before the first file is added |

## What a music file must be (the short version)

- WAV, stereo, 44.1 or 48 kHz, as Suno delivers it. No fade-out at the end.
- Steady tempo (no more than about 2% drift), so a loop and a crossfade on the bar line work.
- The fight cues M02 to M05 share **180 BPM and the key of E**; the fold (M07) is 90 BPM; the last stand (M06) is half-time at 180.
- Instrumental, no sound effects inside, and no names of real artists, bands or songs in any file name, tag or note.
