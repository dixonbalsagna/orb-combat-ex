# The planet map: how it fits the HUD (UI & UX, 2026-10-31)

Paper only; no code until the arena route is chosen. The brief: Orb liked proto v2's minimap with its trail (`research/ring-any-angle/proto-v2.html`; Orb's words in `docs/ep/vision.md`). Its rules are GD's section 11 (`docs/world/ring-any-angle/game-design.md`) and `docs/design/minimal-hud.md` section 3: a small globe at the edge with the trail, the pair and faint cities; no destination, labels, numbers or icons; under the flash area threshold; on by default with an off switch; the whole trail on the results screen; it replaces the planet strip.

## 1. Where the strip stands today
With `minimal_hud` on (it is), **the strip is not drawn in play** (`ui_hud.gd` line 737), and neither is the toll chip. The ring map (`ring_map`) is off, cut after Orb's grey-circle note (2026-10-18). So the globe is the first map in play since then, and it is allowed as GD's exception, not as a loosening. The strip's code and its layout rect stay for the flag-off path.

## 2. Where it goes, and how big
**The strip's slot: bottom centre, between the two bark lanes, below Camera's clear zone.** Not a corner: every corner already holds a plate, the wound cards, the legend, a bark lane or (on touch) the buttons. The band under the clear zone is where the strip and the ring already sit, and no fighter is drawn there, so it is never on, over or between them. In a split the divider already stops above the strip and ring (`UiLayout.divider_band`); it will stop above the globe, so there is one globe per screen and it never crosses the divider. Hidden in an intro, a finisher and a KO by the existing `_lb < 0.5` gate.

**Size: the lane block's height** (bark lane, gap and strip row), measured from `UiLayout.compute`, as a disc, capped at 0.16 of the screen height so a larger text step cannot grow it (the lane grows with text):

| Screen | Disc | Room between the lanes | Share of the frame |
| :-- | --: | --: | --: |
| 1280x720 and 1280x800 (Steam Deck) | 107 px | 377 px | 0.98% / 0.88% |
| 1366x768 | 111 px | 403 px | 0.92% |
| 1024x768 | 94 px | 302 px | 0.88% |
| 1920x1080 and 2560x1080 | 154 px | 566 px / 1,075 px | 0.90% / 0.67% |
| 2560x1440 | 205 px | 754 px | 0.90% |
| 3840x2160 | 308 px | 1,131 px | 0.90% |

The worst case, the disc's bounding square at 1280x720, is 1.24%. **That is under the 2.8% threshold by more than two times**, so the globe's turning, whatever its colours, cannot count as a general flash. No pulse, no fade, no flashing mark; the trail is a still line that grows. Phone and portrait layouts stay parked (ADR 0011).

## 3. What it draws, and what each of the strip's jobs becomes
| The strip's job | The globe |
| :-- | :-- |
| Where each fighter is (circle for the left, diamond for the right) | **Kept, shape-coded**; one point when together (GD), two when apart. Never colour alone |
| The camera's box | **Dropped.** The globe turns to keep the pair on the near side, so the present is always the middle |
| Biome colours along the loop | **The planet's own land**, colour only, muted so the trail reads against it (the trail at least 3:1 on the land) |
| Ticks for fallen buildings | **Not carried.** A mark per loss is the toll picture Legal has not seen. The cities are faint specks, standing or not, until Legal rules |
| The toll's tint | **Does not move** until Legal has seen it. There is no tint in the code today (the strip never had one); the toll stays on the pause screen and the results as a count |
| The "Place names" option (the place under the camera) | **Retire it with the strip.** It is dead in play today (nothing draws the strip), and GD allows no label on the map. Say if Narrative wants a place caption elsewhere; it would be a new job |
| Hidden marker and ping | Gone (hiding is off; the stealth fighter gets its own work) |
| Hiding in a cinematic | Kept (`_lb`) |
| Its rectangle's other roles: the bark lanes' bottom, the face dock, the divider band, the edge chips' foot | `UiLayout.strip` and `ring` become one `map` rect with those roles |
| The ring map's wrap read and pane arcs | Dropped with it; the trail is the sense of crossing |

## 4. What it costs (estimates; measured when built)
- **Draw:** one quad with a small sphere shader (the disc's pixels, at most 95k at 4K), two texture reads a pixel. One layer replaces four (strip base, strip marks, ring base, ring). It works in the Compatibility renderer, so on the web build.
- **CPU:** a few uniforms a frame (the turn, the pair) and one trail point every 15 ticks, about 0.05 ms when it happens, otherwise about 0.02 ms. Target at most 0.1 ms, set against the old strip's 16 us walk of 118 buildings that it no longer does.
- **Memory:** about 0.2 MB for the land (Rendering's far map is already a 192 square with mips; the globe reads the same texture), 8 KB for the trail mask, about 30 KB for the match's trail points (1,200 to 2,400 points, decimated when full so the whole match is always kept).
- **Sim:** reads only. The trail is sampled by tick (every 15th) from the sim's frame, never written to it; a rollback rewrites a point by its tick index.

## 5. Settings and the results screen
- **Setting:** `planet_map` in `options.json`, display group, default on, label "Planet map", help "A small globe at the bottom edge with the fight's trail round the planet." It takes the row `region_label` leaves. A `features.json` flag `planet_map` (off until built) carries the build, as `ring_map` did.
- **Results:** there is no match results screen yet (`hud-spec.md` lists results as not built; the run mode's results are designed in `run-mode-screens.md`). The trail is kept for the whole match so a results screen can draw it at full size when it is built.

## 6. Depends on, and what it replaces in the docs
- **The route.** If the arena stays a one-dimensional ring, a globe adds nothing the existing ring map does not, and UI turns the ring map (coded, off) into this with the trail: same slot, same option. The globe pays only if the ring can swing.
- **From Rendering and World** (host glue, as `strip_fn` is today): a `planet_map_fn` giving the land texture, city positions, and the pair's position as a planet direction; UI owns the node, the shader and the trail in `ui/`.
- **Pages to update when built:** `hud-spec.md` section 10 and the strip rows of its tables, `minimal-hud.md` section 3, `strings.md` and the pseudo copy for the option, the `hud_check` rect lists (strip and ring become map), and a look-gate side-by-side over real fighters (Orb should see it).

## 7. The stand-in (2026-10-31)
Built behind the feature `planet_map` (off) as `UiPlanetMap`, in the ring map's slot, reading `planet_map_fn` (the sim's planet direction when its API is out) or, until then, the planet strip's data: docs/ui/hud-spec.md section 71. The bigger `map` rect, the sphere shader, the cities and the ring map's retirement wait on the arena route.
