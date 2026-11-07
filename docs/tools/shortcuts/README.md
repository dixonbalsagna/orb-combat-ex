# Shortcuts for the private page (Tools, 2026-11-01)

`Open - full power.cmd`: the same as `homework/1 Urgent/Open - playable.cmd` (the flashing warning stays) but the address ends in `&peak=1`, so both fighters start at tier 4 (Encounter's `startTier`: tier 4 takes about six minutes of AI fighting to reach). For the EP to place beside `Open - playable.cmd`: it finds the page at 127.0.0.1:8766 and opens it; if the page is not running it builds it (the same fallback) and asks for `&peak=1` to be added by hand, because the build's `--open` opens the plain address.


## Where the kept copies are (Orb, 2026-11-01: everything for the project stays inside its folder)

The kept copies live in the repository, in **`homework/Files/builds/`** (git-ignored; `homework/.gdignore` keeps Godot out): `orb-first-play-<commit8>-<build hash 8>/` with `web/` (read-only, byte-checked), `serve.mjs`, `serve.cmd` and `README.txt`. `node tools/preview/handover.mjs --dir <built web folder>` makes one there by default (it is the only place inside the repository it allows).

The three shortcuts here are for `homework/<a folder>/` (the EP places them, for example `homework/1 Urgent/`). Each names its kept copy **relative to its own folder** (`set "KEPT=%~dp0..\Files\builds\orb-first-play-..."`, then `for %%I in ("%KEPT%") do set "KEPT=%%~fI"`), so renaming or moving the project folder breaks nothing; they only need to sit one folder below `homework/`, beside `Files/`. `Open - playable.cmd` and `Open - full power.cmd` point at the main copy (Stream sound, port 8766); if nothing answers there they start the copy's own `serve.cmd` in a window that stays open and says so. Both carry the Opera GX limiter line.

## The two sound modes (the EP, 2026-11-01)

The main build and `Open - playable.cmd` play the web sound as a **Stream** (`audio/general/default_playback_type.web=0`, a one-line park in the manifest, `sound-stream-mode`; in the build only, not in the repository). Headless Chrome and Opera GX read no sound at all from the engine's default, **Sample**, on a plain HEAD build too (checked three ways: the connect tap, a stage bisect, and a destination getter that no wrap can fool); with Stream they read real sound at the output (peak 0.891, the engine's bus meters alive). Stream runs the bus effects Sample skips and may come a little late.

`Open - playable (other sound mode).cmd` is the third shortcut: the same final set with Sample, the second kept folder, served by its own `serve.mjs` on **port 8767** (so it never meets the main build on 8766; its own address, its own browser storage). Its wording to Orb: the same game with the sound played the other way: lower delay, but it may be silent. The main kept folder is the Stream build; the second is the Sample build; both are read-only handover copies, byte-checked. The shortcut fills `set "KEPT2=..."` at the handover, like the others.
