# Park: a match's opening craters are held by the store (Rendering, 2026-11-26)

## The file

| File | What |
|---|---|
| `held_recheck.diff` (sha1 ea8dcb51f4ce, 58 lines) | Changes only `render/core/ground_field.gd`. It applies strict on main (checked on 4db9917b and 3c95f5af), and after `../ground-link/ground_link.diff`. |

## What it does

On the tile ground, a crater that World's store also records is drawn by the store's bowl, not by the rows. `GroundField.held[idx]` marks those entries. `_store_holds` sets it when an entry is added, and it can only hold an entry once the tile ground is attached and the sim's frame is set.

That check ran too early, and only once:
- **A match's first build runs twice.** The second rebuild runs before the tile ground and the frame are ready. So the opening's two craters (r 196, t 0) were added with held 0.
- **Nothing looked again,** so the rows and the store's bowl both drew them for the whole match.
- **The same happened to a crater whose entry came before its store record** (the frame saw the dig before the store took it).

Now `update()` looks again whenever the store's length changes, or whenever the hold becomes possible (the tile field and the frame are set). If an unheld entry has an unclaimed store record with the same time and radius (`_held_late`), it rebuilds once. `rebuild()` records what it matched with, so a build that ran before the hold was possible gets looked at again.

- **Cost:** one rebuild per change, and only when `_held_late` finds an entry. The scan is entries times store records, both a handful.
- **The sim:** nothing is written to it.

## Proof

All of this is on main 4db9917b, without (h0) and with (h1) the park. The record is `docs/rendering/runs/4db9917b/tick0-craters.txt`.

**A scratch probe of `held`:**
- On h0, the opening's two craters are held 0 at ticks 2 and 60.
- On h1, they are held 1 from tick 2.

**Gates on h1:**
- export clean;
- golden byte-identical to h0;
- the five ground checks and drawn_check pass;
- the render gates: 20 of 20.

**Medium's collapse, worst of 4 readings, both modes:** normal 1 before and after, reduced 1.5 before and after.

**The look gate.** On the reel (reduced, 960x540, every frame to tick 300), the frames differ at ticks 1, 3 to 12, 35 to 47 and 159 to 240. The largest change is at ticks 186 to 217.

The side-by-sides are git-ignored, in `docs/rendering/img/sizes/tick0-craters/`:
- **`craters` (ticks 180 to 222) and `craters-zoom-t190-203-214.png`.** At tick 203, in the second pane's lower right: before, the ground rides over a house's ground floor and only its top edge shows. After, the house stands on the ground, with its wall and door showing. Ticks 190 and 214 look the same before and after.
- **`opening` (tick 1).** A small shift of the ground under the mesa in the second pane.

The joint proof with GB-010 on the current main is in `docs/rendering/runs/<HEAD>/ground-link.txt` (see `../ground-link/README.md`).

## Landing

Land it with `ground-link`, or after it. The two parks touch different files and apply in either order.

Without the GB-010 fix, a match built with the split attached has no tile field on its ground, so no crater is held at all there and this park changes nothing. On the first match without the split, it works alone.
