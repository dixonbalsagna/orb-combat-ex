# The building sweep goes by what the camera can see on the tile ground

Parked by Rendering, 2026-11-01. `viewcap.diff` stacks on `2026-11-01y-crowd-run-ground/crowdrun.diff`. Only with the tile ground's switch on; today's ground keeps the span it had.

**The fault.** The planet view's update cost about 2.4 ms every frame in Orb's second match. Most of it was the building sweep: about 1,100 buildings visited a frame, nearly all finding nothing changed. The sweep took every building whose x lay in the view's span, at any depth, and on the tile ground places stand everywhere on the planet.

**A second fault, found on the way.** The span looked buildings up in an index sorted by x when the sweep was built. A swing moves a building's x, and the index was never re-sorted, so after a swing the span visited the wrong buildings. On Orb's second match it left out 1,697 on-screen buildings over 1,832 pane-frames (about 33 on screen each). Those waited for the slice (up to about 4 s) or an event to be brought up to date.

**The change.** On the tile ground each pane hands its refresh the camera's place on the planet, and the sweep visits the buildings the tile ground's own test (`_walk`) says can draw there. That's the same reach and width of view that picks the ground tiles, padded by a building's own reach and 640 units (`SWEEP_TILE_PAD`). The buildings are found through a table of level 1 tiles, made once per ground from where each building is drawn (`b.g`, which a swing doesn't move). This frame's events, falls, drops, people owed, the evacuation zone, dirty ground and the slice of 16 are all visited as before. A test turn (`--tilerate`) keeps the span.

**Proof.** A scratch readout placed every building's corners as the shader does (`globe_place`, `globe_m`) and put them through each pane's real camera:

| | Pane-frames | On screen, each | Left out by this test | Left out by the old span |
| :--- | ---: | ---: | ---: | ---: |
| Orb's second match | 1,832 | 32.6 | 0 | 1,697 |
| ... in a swing | 162 | 13.0 | 0 | 7 |
| Reel, seed 12345, to tick 3000 | 805 | 5.0 | 0 | 0 |

**Result, perf-run on Orb's second match to tick 8000, with y and z, back to back with x alone, both valid (load 57/49 and 46/49), ms a frame.** Whole-match median, then the mean in each stretch:

| Ticks | Frame before / after | View before / after | Planet view update before / after |
| :--- | ---: | ---: | ---: |
| Whole match | 24.4 / 22.3 | 8.2 / 6.5 | 2.4 / 0.8 |
| 185-219 | 32.0 / 25.1 | 9.5 / 6.5 | 2.8 / 0.8 |
| 3425-3475 | 27.3 / 26.5 | 10.0 / 8.6 | 2.6 / 1.1 |
| 3570-3705 | 33.3 / 31.1 | 11.8 / 9.8 | 4.8 / 2.5 |
| 5643-5711 | 29.7 / 30.7 | 9.9 / 8.5 | 2.4 / 0.7 |
| 7501-7574 | 24.4 / 24.0 | 8.0 / 6.4 | 2.4 / 0.4 |

Buildings visited a frame went from about 1,100 to 240 (80 to 350 by stretch). In 3570 to 3705 the rest of the planet update is the runners (y halves it). The harness's frames are slower than Orb's, so ratios carry and absolutes don't.

**What it costs.** Nothing on screen, by the proof above. The table costs one pass over the buildings when a ground is made.

**Gates**, with a to z stacked on 8ea982c5's render, sim and data: golden byte-identical; tile, lake water, cover water and sweep checks pass; the 20 render gates exit 0 (without the tile word, so they prove the off path); off 13 stills 0 differ. The chain applies on main 04aa9228, apply check only.
