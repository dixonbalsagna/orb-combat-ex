# The surface memo: nothing to gain from a per-tick one (World, 2026-11-06)

The brief (from Performance's `docs/perf/impact-stutter.md`): "`_landTerms` -> `WorldContact.lookAt` -> `surfaceAt`, 0.9 ms a launch, 3.6 calls, 0.2 ms a lookup: memoize `surfaceAt` per column for the tick", as a hash-neutral change. **I measured it and built nothing, because a per-tick memo would save about 7 microseconds of the 900.**

**Measured** (scratch, planet 7 gen 3, microseconds a call, on a loaded PC so the ratios carry):

| A column's `surfaceAt` | us |
| :--- | ---: |
| first read of a column the match has never read | **41** (the field's cold node reads: stored biome 11, the town test 29 incl. the record scan, the fine biome 11) |
| the same column again, same tick | 2.0 |
| the same column on the next tick | 3.2 |
| `lookAt` repeated | 3.7 |

The table is already memoised: `_fcol` (`sim/world/contact.gd`) keeps each column's numbers until SimField's serial moves. So a warm lookup is 2 to 3 us, and 3.6 of them are under 12 us. The 0.2 ms in the profile is the cost of **columns the match has not read yet**: each launch's landing candidates fall in new columns (a haul of thousands of units), and a new column is a cold field read (about 40 us a column here, more where the records are thick or the node is cold: Performance's 0.25 ms). A per-tick memo cannot help a column that is read for the first time.

**Two things that would:**
1. **Read the columns ahead of the decision** (node warm, built: `WorldField.warmNear`, radius 10,000 from the fighters, `field.json warm.radius`). A landing 20,000 to 40,000 units away is outside it; the warm radius could grow with the launch's reach (a few thousand more nodes, off the launch tick) or the launch could ask for the landing columns' warm one tick earlier (Encounter: the swing offer precedes the launch by many ticks). Either is a decision about when the nodes are read, not a memo.
2. **Keep the biomes across the store's changes.** The memo is cleared whenever a record or a crater joins the store (`SimField.serialOf`), and the stored and fine biome of a column do not depend on the store. I built that split (`_bf`: the two biomes memoised on the frame alone) and checked it equal to a table laid from nothing at every tick of a match with craters digging (15 of 15 windows of 300 columns, one hash). **It saved nothing**: the field's own memos keep those reads warm across a store change, except right under the crater (which `field-place` already clears alone). So I took it out.

**Not changed, no park.** If Performance wants the first, the knob is `field.json warm.radius` (data) and a one-line call from the launch's planner, and I would measure the launch tick's cold reads before and after.
