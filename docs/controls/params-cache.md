# The kept `params()` of the press reader and the aim helper

Controls, 2026-10-28, for Encounter's tick-skip report (NEEDS 1, `docs/director/cloud-reports/2026-10-28-tick-skip.md`).

## What changed

- `SimPressRead.params()` and `SimAim.params()` build their dictionary once and hand the same one back. Each build was about 35 data lookups.
- The copy is **read-only**. A write to it is a script error ("Invalid assignment on read-only value"), so a caller that changes a number cannot change what the next caller reads. Use `params().duplicate()` to get a writable copy (`brake_grapple_test.gd` does).
- `opts.get("p", params())` (which built the dictionary even when `p` was passed) is now `opts["p"] if opts.has("p") else params()` at all 7 sites; `SimAim.read` and `snap` do the same for `latchTicks` and `snapMax`.

## When a kept copy is thrown away

A copy is used only while all of these hold, and rebuilt the moment one does not:

1. `SimInputData.revision` is the one it was built at. `load_data()` (so `load_and_apply()`) bumps it, and so does the new `SimInputData.invalidate()`.
2. The data sections it reads are the same dictionaries (compared by reference with `is_same`): `read` and `tapHold` for the press reader, `aim` for the aim helper. A test or a tool that swaps a section (`timing["read"] = other`, or erases it) is seen with no help.

**The one change it cannot see:** editing a section **in place** (`timing["read"]["mashGap"] = 8`). Call `SimInputData.invalidate()` after it. Nothing in the game does this; `params_cache_test.gd` pins the limit down.

The copy holds only integers and floats, no sim or fighter, so it cannot keep a finished sim alive (the rollback check's leak count passes).

## The check

`sim/input/test/params_cache_test.gd` (36 checks): the same read-only dictionary twice; equal, key for key, to a fresh build from the data; **a `load_data()` of a file with other numbers is read at once** (written to `user://`, removed after) and the old copy is untouched; a replaced or erased section is read at once; `invalidate()`; `p` in opts is used as given; classify through the kept copy equals classify through a fresh build. **Negative control:** with the validity test removed (copy kept for ever) 9 of its checks fail, and `press_read_test.gd`'s "a changed mashGap in the data is the reader's" fails too.

## Numbers

Micro-bench on this machine (a 20-entry log, 2,000 calls): `SimPressRead.params()` 32 to 0.7 us; `SimAim.params()` 4.3 to 0.46 us; `SimPressRead.classify` 55 to 21 us.

`dir_prof.gd` (AI match, seed 1, 3,600 ticks, three runs each, alternated, base = HEAD 3ce146da), `control.request` per press: **272 / 275 / 281 us to 213 / 221 / 225 us (about -55 us, -20%)**, per tick 29.3 to 23.0-24.3 us. Whole tick: mean 301-311 us to 293-307 us, p99 910-939 to 828-862 us (-9%). The whole-tick mean moves by about 1.5%, inside this machine's run-to-run spread; the press line is the stable signal. About 220 us a press is left, outside `classify` (which now costs about 21 us, read twice at most): it is mostly the director's `logOf`, which builds up to 20 nine-key dictionaries from the packed log on every read (Encounter's file).
