# Fighters at sea read clearly

Parked by Rendering, 2026-11-01. `sea.diff` applies on its own, on a plain main, with or without the tile ground.

**The fault (Camera's reel, ticks 1710 and 1830).** A fighter below the sea's top looked blue and half transparent. With the water sheet on, one well under it was hidden completely.

**The cause.**
- `GroundField.under_level` decides when a fighter is drawn again over the water. It only read `S.water`, and the open sea isn't in `S.water`, so at sea it never fired. The water drew over him and nothing drew him back.
- Under a lake it did fire, with 55% of the water's colour on his body and his outline, which reads as a ghost.

**The change.**
- `under_level` also takes the open sea: base under `RESERVOIR_BASE`, level `SEA_LEVEL`, from the first depth step.
- `RenderLook.UNDER_BODY` is 0.22: that share of the water's colour on his body. His outline takes none, so his shape stays whole.
- `lake_water_check` gains a row for the open sea.

**Where it applies.** Planets of gen 2 and up, on tiles and on today's ground. The hand-made world and gen 1 are unchanged: they take none of the under-water redraw, by the existing check's rule, so a fighter under their sea still looks washed out.

**Picture.** `docs/rendering/img/lookgate/fighters-at-sea.png`. Top: on the sea bed, before (not visible) and after. Bottom: chest deep, before and after. All on the tile ground with the water sheet.

**No switch.** Once landed, this is live on every planet of gen 2 and up. A match on the default world isn't one (`data/biomes/climate.json` has gen 1), and the capture hook's plain run there doesn't touch this. Any page or menu that sets a gen 2+ planet does, so it needs flash clips before such a page goes public.

**Not checked.** No flash clips yet. Today's ground on a gen 2+ planet has no stills yet: the checks cover the rule, not the picture.

**The trade.** With so little tint, a fighter below the surface reads less as being in the water. A clear read comes first, by the EP's order.
