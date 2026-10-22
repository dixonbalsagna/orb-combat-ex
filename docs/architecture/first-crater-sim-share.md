# The sim's share of the first crater's host tick (2026-10-23)

Owner: Simulation and Engine, on the EP's brief from Rendering's map (`docs/rendering/geometry-and-warmup.md`, "The first crater on an old laptop"). Measured natively, headless, on 1605d73a, with scratch-only timers. Nothing in the tree changed.

## The scene

The perf hook's `ai` scene (`render/tools/flash_capture.gd`):
- seed 12345, both slots AI;
- its own setup (no intro);
- the main scene, one tick a frame.

The first crater lands at `host.ticks` 239, which is Rendering's frame "238". It is the first beam's strike crater: the beam is fired and makes its first sample on that tick. There were three runs in one process: the first cold, the other two warm.

## The split (µs; the median tick, then the crater tick, in three runs)

| Section | Owner | Median tick | Tick 239 | Over the median |
| :--- | :--- | :--- | :--- | :--- |
| **The sim step** (`SimCore.step`) | | 295 to 336 | 540 to 580 | **+210 to +250** |
| ... the strike crater (`WorldCrater.dig`, with its `crater` event) | World | 0 | 122 to 129 | +125 |
| ... the beam's scorch along the ground | World | 0 | 49 to 61 | +55 |
| ... the beam's structure damage (`WorldStructures.damageArea`) | World | 0 | 26 to 27 | +27 |
| ... the beam's dust and spark events (`SimFx`) | Simulation | 0 | 21 to 23 | +22 |
| ... the director's beat that fires the beam (`DirBeam.fireBeam` 26 to 35 of it) | Encounter | 121 to 129 | 188 to 210 | +70 |
| **The host's consumers** (everything after the step) | | 366 to 376 | 1,476 to 1,736 | **+1,100 to +1,370** |
| ... VFX's consume | VFX | 136 to 144 | 962 to 1,108 | +830 to +960 |
| ... the `drained` listeners (the HUD and the rest) | UI and others | 122 to 126 | 260 to 395 | +140 to +270 |
| ... Rendering's impact effects | Rendering | 4 | 95 to 195 | +90 to +190 |
| ... Audio's cues | Audio | 10 | 49 to 75 | +40 to +65 |
| ... the reference fx consumer (`SimFxView`) | Simulation | 30 to 32 | 46 to 47 | +16 |
| ... the reference camera (`SimCamera`) | Simulation | 8 | 8 | 0 |

- **The sim is about a sixth of the host tick's rise** (+0.21 to +0.25 ms of +1.35 to +1.65 ms). VFX's consume is about two thirds of it.
- **My own code** (the `SimFx` events in the beam, `SimFxView`, `SimCamera`) adds about 40 µs.
- **Nothing in the sim is built lazily on the first crater.** The cold run's tick 239 costs the same as the warm runs', section by section. The strike crater costs the same as later strike craters in the match (a median of 122 to 129 µs a dig). The cost is the crater's own work, done once per crater, not a first use.
- **Nothing to pre-build, so nothing changed.** The golden is untouched.

## Scaled to the old laptop (an estimate)

Rendering read the host's tick at +9 to +13 ms over its median on the web at x4, against +1.35 to +1.65 ms natively here, a factor of about 6 to 8. At that factor the sim's share is about 1.5 to 2 ms, about 0.9 of it the strike crater, and my own code about 0.3.

This assumes every section scales alike, which the web may not do. WebAssembly compiles some engine code on its first call, so a first-use cost could exist on the web that native runs can't show. Two of the sim's sections can answer that: the first beam's dig and scorch against a later beam's, at x4 on Performance's web repro.

## Recipe (scratch)

`git archive HEAD` into a scratch folder, then add timers:
- `SimProf.lap` between the phases of `SimCore.step`;
- the same between the consumers in `SimHost.tick`;
- the same inside `DirBeam.sampleBeam`, `planBeam` and `fireBeam`.

The probe is a SceneTree script: the main scene in a SubViewport, `main.start_match(12345, {"p1": true, "p2": true}, {})`, then `main.frame(1/60)` for 400 ticks, three runs. It prints each section's median, ticks 238 to 242, and the slowest ticks. Run it headless at below-normal priority, one job.
