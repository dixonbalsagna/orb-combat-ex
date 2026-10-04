# audio/music/: where the finished music goes

Owner: Audio and Music. 2026-10-04. The plan is in `docs/audio/suno-direction.md` (the sound, the hand-back spec and the decisions) and `docs/audio/suno-prompts.md` (the 12 prompts). Suno makes the music from our prompts and reference clips; Orb downloads the files and puts them here.

## Orb: how to hand files back

1. Download the **WAV** of each take you like from Suno (not an MP3), and the stems if your plan has them.
2. Put the files in **`incoming/`**. Name them `M02_fight-1_t01_180bpm_E.wav`: the cue id and slug from the prompt block, `t` and the take number, the tempo you aimed for, and the key. Stems add `_stem-drums`, `_stem-bass`, `_stem-guitars`, `_stem-lead` or `_stem-brass`.
3. Next to each file, save a text file with the same name and `.txt` (`M02_fight-1_t01.txt`) holding the exact Style text, Exclude text, structure tags, slider settings, the model (v6), the date, your Suno plan and the song's link. We need it for the origin log.
4. Do not edit the audio. Tell the EP, who tells Audio.

`incoming/` has a `.gdignore`, so Godot ignores the raw files. **Raw WAVs are large (a 3-minute stereo file is about 30 MB) and should not be committed to git.** The EP decides how they are kept (see the report). What the repo keeps is the encoded game files and the loop data below.

## What Audio does with them

```
node audio/tools/music_check.mjs incoming/M02_fight-1_t01_180bpm_E.wav --bars 32
```

It prints the format, the integrated loudness (LUFS) and the gain to the target of -16 LUFS, an approximate true peak, the tempo (and whether it drifts) and the best bar-aligned loop points. A take within about 2 BPM of its target and without drift goes on.

Planned layout once files exist (nothing here yet):

| Path | What |
| :--- | :--- |
| `incoming/` | Raw Suno downloads and their sidecar text files (not for git) |
| `ogg/` | The encoded game files, one per cue and take, loudness-normalised to -16 LUFS |
| `loops.json` | For each cue: file, tempo, loop start and end in samples, bars, gain. Needs a schema from Tools before the first file is added |

## What a music file must be (the short version)

- WAV, stereo, 44.1 or 48 kHz, as Suno delivers it. No fade-out at the end.
- Steady tempo (no more than about 2% drift), so a loop and a crossfade on the bar line work.
- The fight cues M02 to M05 share **180 BPM and the key of E**; the fold (M07) is 90 BPM; the last stand (M06) is half-time at 180.
- Instrumental, no sound effects inside, and no names of real artists, bands or songs in any file name, tag or note.
