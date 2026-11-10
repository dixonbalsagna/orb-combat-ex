# mms-tweaks (Tools, 2026-11-10): SCRATCH ONLY, never for main

`mms-tweaks.patch` is what the three MMS clips were filmed with, applied to a scratch tree of 6a30b4c9 by `tools/preview/stack-preview.mjs --manifest <a manifest with this park> --off bNoBeam,bNoBeamKeepRt`. It is kept so the clips can be remade. Do not apply it to the repository and do not put it in a kept build.

- `data/fight/ricochet.json`: enabled, maxInRow 8, keep 0.85, minSlope 12 (the ricochet system is off as shipped).
- `render/tools/flash_capture.gd` (the capture hook): a scene `mmsky`; a follow camera for the film scenes (word `mmcam=1`, with `mmzmin`, `mmzmax`, `mmfit`, `mmv`, `mmpitch`); a zoom word `bdz` and a shake word `bdshake` for Camera's beam-duel shots.
- The two rows `bNoBeam` and `bNoBeamKeepRt` are switched OFF in that scratch build (B fires the beam again), so the beam duel scene can be filmed.

Clip kit changes that ARE for main (Tools' own, `tools/clips/`): `make.mjs` takes `--recipes <file>`, exports `openPage` and `runScene`, and hides the private page's fixed overlays when `CLIPS_HIDE_OVERLAYS=1`; `mms-scan.mjs` lists a scene's events per seed with no pictures. Recipes and screen results: `docs/tools/runs/mms-2026-11-10/`.
