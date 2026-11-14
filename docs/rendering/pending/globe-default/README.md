# The globe ground on by default (A-RENDER-01)

Parked by Rendering on 2026-11-14 for sprint A1, on Orb's decision 3 (the globe ground, the crater look without the black fill and the meteor trail as defaults). It lands in its turn in GW1a ("look", after the round planet and the camera). `globe_default.diff` (sha1 54b06089, 180 lines, cut on main f391fec4) touches `render/core/main.gd` and eleven render checks in `render/tools/`. Every figure is in `docs/rendering/runs/f391fec4/globe-default-park.txt`.

## The change

- **`render/core/main.gd`:**
  - `RenderTileGround.on` is on unless `--notiles` (`?notiles=1` on a local page) or a tool's new `main.strip_ground`.
  - The camera's block (`split_rig.*`) follows it, as it always has.
  - The old word `tiles` does nothing more.
  - `notiles` is in both URL lists.
- **The checks that only ever saw the old ground** pin it with `main.strip_ground = true`, so they test what they always tested: open, depth, shape, patch, ground, after, sky, seam, lake water, cover water, sweep.
- **The determinism tool's reference** starts from the setup the host really sends (`_as_host`: `RenderTileGround.setup_of`, which adds the planet's keys with the globe ground on).
- **The ground check's fresh field** gets the tile field, so a crater the store holds is the store's in both.

## Acceptance 1: what the render gates did with the globe ground on by default

`docs/rendering/runs/def3445a/globe-default-gates.txt` records the day-one run on a scratch tree with only the switch flipped:
- 10 of the 20 render gates and 4 of the 5 ground checks failed;
- **all 14 passed again with `--notiles`,** so each one only ever saw the old ground. All are Rendering's.

The four frame-rate runs of the determinism gate agreed with each other bit for bit; only the tool's reference was built from the old setup. The record lists, per check, what it assumed and what it needs on the globe. Two of them point at faults in the globe ground itself, both already in the 9 November build:
- **Street paint covers 16 districts of planet 7's 53** (and 24 avenues of 32). The fix is the nearest to the camera, chosen again as it moves.
- **After-images:** on 5 ticks, one VFX tallied isn't drawn round a fighter on the globe ground. Rendering to look.

## Proof

On main f391fec4 with this park: it imports clean, `golden.json` is byte-identical, the tile, lake water, cover water, sweep and ground checks pass, and the render gates pass 20 of 20.

## The look gate (uncommitted, show fighters)

`docs/rendering/img/lookgate/a1-globe-vs-nov9-*` and `a1-globe-vs-main-*`, stills and GIFs: one computer match (seed 12345, ticks 1 to 1,201 every 100), compared three ways:
- **this park with no word,** but `meteor=loud` standing in for VFX's grant;
- **the 9 November build at its page words** (`planet=7&meteor=loud&tiles=1`);
- **main as built,** the old ground.

The park's plain start shows the 9 November build's world, ground and night hillside. Main's plain start shows the old strip desert. The two matches play differently, since main's data isn't the 9 November build's yet (GW1a).

The flash readings, for the EP only, are in `docs/rendering/runs/fcd6706c/look-defaults-flash.txt` (Tools' pixel clips with no page word: main as built, with this park, and with A-RENDER-04 too).

## Owed

- **VFX's grant for the meteor trail:** `render/vfx/vfx_look.gd`'s `METEOR_DEFAULT`, and the loud profile Orb plays (`meteor=loud`). With the default on, `VfxMeteor.page_word()` isn't called, so its profile line must change too. VFX's lines.
- **The launch words to drop once this lands** (Tools and Netcode): `tiles` in `tools/preview/switches.mjs`, and `--tiles=1` in `net/tools/lan_kit.mjs:127`. The same goes for `craterlook` with A-RENDER-04, and `meteor` with VFX's grant.
- **The checks' globe versions,** one per row of the record: Rendering's, after A1's look lands.
