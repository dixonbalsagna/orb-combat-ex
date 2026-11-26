# Sound on the desktop builds (Audio and Music, 2026-11-25; A-AUDIO-04)

Describes main from `7bfbfe6a` (`friends-sound.md`). **Nobody has listened to any of it.**

## The settings

| Setting | Value | What it does |
| :--- | :--- | :--- |
| `project.godot` `audio/general/default_playback_type.web` | `0` (Stream) | **Web only.** Godot's web default is "Sample" playback, which read silent on this project's build and skips the bus effects. `0` mixes in the engine instead. |
| The same setting for desktop | not set | A desktop build already mixes in the engine (Stream). **Nothing to add.** |
| Driver, mix rate, latency | not set | Godot's defaults: 44.1 kHz; WASAPI on Windows; on Linux PulseAudio (which PipeWire serves, as on a Steam Deck) with ALSA as the fallback. **Nothing to set for Linux** on current evidence; a Deck is the first real test of that. |
| The page player (`audio/audio_web.gd`) | web only | The browser plays the one-shots itself. A desktop build never uses it: every sound goes through Godot's mixer, its buses and the master limiter. |
| Master limiter | `audio/data/mix.json` `master_limiter` | -6 / -1 dB (below). |

No change to `project.godot` is asked for.

## The overdrive, and the fix

Godot's old `AudioEffectLimiter`, as set up until now (threshold -6, ceiling -1), **lifted everything by 5 dB and then flattened whatever went over**. Test tone through it, headless:

| Tone in | Old: peak out, shape | New: peak out, shape |
| ---: | :--- | :--- |
| -18 dB | -13.0, clean | -13.0, clean |
| -6 dB | -1.0, slightly flattened | -1.0, clean |
| -1 dB | -1.0, badly flattened | -1.0, clean |
| +4 dB and over | -1.0, close to a square wave | -1.0, clean |

(`docs/audio/runs/friends-sound/limiter-old-vs-new.txt`.) So every loud moment on desktop (and in the web build's looped sounds) was distorted. In three seeded matches played through the real voices, the sum before the limiter peaked at +1.3, -1.7 and -4.7 dBFS, and 0.02 to 0.15% of the sounding samples were over -6 dB: the biggest hits, craters and beams (`pre-limiter-levels.txt`; the figures move a little run to run, as it plays in real time). **It is a likely cause of the crackle Orb heard on 9 November, not a proven one** (that build and machine are not recorded).

The fix: Godot's look-ahead limiter (`AudioEffectHardLimiter`) with the same two numbers. Everything under -6 dB comes out at **exactly the same level as before**; what is over is turned down smoothly instead of squared. No data shape changed.

## The proof that a build makes sound

`audio/audio_proof.gd` plays a fixed list (a light hit, a heavy hit, a crater, a blast, a grunt, a building hit, a collapse, a menu confirm, nine loud sounds at once, the wind) through the game's own voices and buses, records what the Master bus puts out, and checks: not silent, not clipped, under the ceiling, the expected length; and that the limiter keeps a tone's shape.

```
godot --headless --path . --script res://audio/audio_proof_main.gd     # from the project
orb-combat-ex.x86_64 --headless -- --audio-proof                       # the Linux program
orb-combat-ex.console.exe --headless -- --audio-proof                  # the Windows program
```

An official release program takes no `--script` and no scene path ("compiled without support for path overrides"), so the second form uses the `--audio-proof` argument in `render/core/boot_entry.gd`.

**Results (this PC):** a Windows release export passed all 14 lines (`docs/audio/runs/friends-sound/`). Linux was **not** run here; the CI step runs it.

**What it does not prove:** headless uses the engine's dummy audio driver. The program, its data and its mixer are proved; **that a given machine's speakers play it is not**. The nearest checks for that are Orb's listening pass (Windows) and the friends' Deck questions (`docs/audio/listening-sheet.md`).
