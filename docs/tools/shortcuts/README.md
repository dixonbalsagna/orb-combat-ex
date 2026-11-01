# Shortcuts for the private page (Tools, 2026-11-01)

`Open - full power.cmd`: the same as `homework/1 Urgent/Open - playable.cmd` (the flashing warning stays) but the address ends in `&peak=1`, so both fighters start at tier 4 (Encounter's `startTier`: tier 4 takes about six minutes of AI fighting to reach). For the EP to place beside `Open - playable.cmd`: it finds the page at 127.0.0.1:8766 and opens it; if the page is not running it builds it (the same fallback) and asks for `&peak=1` to be added by hand, because the build's `--open` opens the plain address.


## The kept build (the EP, 2026-11-01: the shortcuts at the handover)

`Open - playable.cmd` and `Open - full power.cmd` here are the corrected copies for `homework/1 Urgent/`. They no longer build anything: if nothing answers on 127.0.0.1:8766 they start the KEPT copy's own server (`serve.cmd` in the kept folder: a window that stays open and says so) and open the page in the default browser (`start ""`; Orb's is Opera GX). The kept copy is made by `node tools/preview/handover.mjs --dir <built web folder> --out <a folder outside the repository>`: a read-only, byte-checked copy named `orb-first-play-<commit8>-<key8>`, with its own `serve.mjs` and `serve.cmd` (node only, no repository file). **Before they are placed, the `set "KEPT=..."` line at the top of each is filled in with that folder** (Tools does it at the final copy). Both carry the Opera GX limiter line.
