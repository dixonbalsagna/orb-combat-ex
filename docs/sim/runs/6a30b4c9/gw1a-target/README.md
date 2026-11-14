# GW1a's target golden: the 9 November build's own data

Simulation, 2026-11-14, sprint A1 (the EP's order 2; path, golden window GW1a). This is the record main must reproduce bit for bit once the switch groups land (A-CODE-01 closes then).

## The target

**`golden-target.json`**, sha256 `a2b9ed1c6f487c29dcfab5b43e4b1745a52209c7069bc64003934c857d2e971d`: 9 matches (184,833 ticks), 2 replays, 6 tick-0 states, 60 constants. Godot 4.7.2-stable (official). **Recorded twice on the same tree: byte-identical.**

`golden-kept-data-only.json`, sha256 `e861d898627df5d7c7cb38ce1d58a9279d5df3c82ce2ab07c6b41391d9bb36d8` (178,830 ticks), is the reference without the energy words (below).

## Exactly how it was made

1. **The source:** `homework/Files/builds/orb-first-play-6a30b4c9-6627cb9d/tree`, read only: copied, never written.
   - It holds the build's `sim`, its `data` (with the page's switch rows flipped), `net` and `project.godot`: 1,259 files.
   - Its sim is main's at 6a30b4c9, and main's sim and data haven't changed since. One input park (`sim/input/remap.gd`) touches the pad, not the sim.
2. **Copy to a scratch folder** and clear the read-only flag (`chmod -R u+w`). The kept folder's files are read-only, and the golden must write its file.
3. **Write the page's two energy words into the data,** because the page put them in every match's setup and they aren't in the kept data. In `data/fight/power.json`: top-level `"enabled": false` becomes `true`, and `"dash": {"enabled": false, ...}` becomes `true`. Nothing else is edited.
   - The page's 6a30b4c9 code (`tools/preview/switches.mjs`, read at that commit) sent `"power": true` (unless `?power=0`) and, with the model on, `"dash": true`.
   - Its sliders sent `"travel"` and `"flatOut"` from their first values, 2 and 5,000 (read from the kept `web/index.html`), which equal the data's `launchTravel` and `flight.flatOut`. So they need no edit.
   - A browser that had saved Orb's own slider values would have sent those; the shipped defaults are these.
4. **`godot --headless --path . --import`**, then **`godot --headless --path . --script res://sim/core/tools/golden.gd`**: the tree's own golden tool, which is main's (unchanged since 6a30b4c9). Below-normal priority, one Godot job at a time. The script is `gw1a_go.sh.txt`, with its logs.

## What main must hold to reproduce it

- **The kept build's data, every file,** plus `power.json` `enabled` true and `dash.enabled` true (A-ENERGY-04 and the dash word). The kept data already has the arrival, the kick, the slip, the hit-stop budget, the brake, the biome launch layer, the pad's switches and the rest flipped.
- **The same sim code and the same golden tool.** Anything that changes the sim between now and GW1a moves this record, which is what it's for.
- **Not in the record: the planet words.** The page also put `{"planet": 7, "touch": 3, "planetGen": 3}` in every match's setup (the `?planet=7` address and its `gen3` row). The golden's recipes name their own setups, and most name no planet, so they play the old arena here as on main. Two consequences:
  - If **A-WORLD-01** makes a match with no planet key play the round planet, main's default-arena matches move and can't reproduce this record.
  - Either the golden's recipes name their arena (so the default doesn't reach them), or A-WORLD-01 is its own step after A-CODE-01 closes.
  - That's the EP's and World's call.

## How much differs from main's golden today

Against main's golden (switches off): every match (9 of 9), both replays, the tick-0 states and values, the intro, the composed intro, the planet match, and the roster hash. Against the kept-data-only reference (t0), the energy words alone move every match, both replays, the tick-0 states, the intro and the planet match; the roster hash stays.

## Records

`summary.txt` (the run), `golden_t0.txt`, `golden_ta.txt`, `golden_ta_again.txt` (the second recording), `gw1a_go.sh.txt`. Paths scrubbed.
