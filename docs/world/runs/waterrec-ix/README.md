# How big WorldWaterRec._ix really is (World, 2026-11-26; the EP's question from QA's soak memory hunt)

**It is about 4 MiB at the very most, not 136 MiB. Nothing is parked.** The soak census (`qa/soak/soak_census.gd`) counts an object once, but not a Dictionary or an Array: it walks every reference again. `_ix` holds, for each grid box read, a list of references to record dictionaries (`merged`), and a lake record carries a dictionary of its lake nodes (6,641 nodes between six lakes). Each list that names a lake counts those nodes again.

`ix_probe.txt` (`ix_probe.gd.txt`; headless, the default planet 7, generation 3, the stack as landed in GW1c for this file; static memory read before and after clearing parts of the index):

| State | Boxes in `merged` | Census of `_ix` (its own method) | Real memory |
| :--- | ---: | ---: | ---: |
| 5 ticks in | 33 | 6.3 MB, 139 thousand elements | |
| 40 s of a match | 431 | 22.9 MB, 412 thousand | 1.93 MiB freed by clearing the index |
| Every box on the sphere read (the worst case) | 10,084 | 156 MB, 2.70 million | **4.10 MiB** (grid 1.82, merged 2.28) |
| QA's soak (arm C) | | 143 MB, 2.48 million | not measured; it sits beside the worst-case row |

A deep copy of the records themselves (`S.fieldRecs`, 1,460 of them) costs 3.12 MiB.

- **Smaller?** The grid is already packed (21,819 ints in `PackedInt32Array`s). A coarser grid would save under 2 MiB and make every ground read walk more records.
- **Kept across matches?** The records are planned anew for each match, so the index would have to be keyed on the planet and not on the array, and the records kept with it. It would save a rebuild of a few MiB a match. Not worth the risk to the sim's reads.
- **For the census (QA's):** count each Dictionary and Array once, or other stores that share records will read inflated too.
