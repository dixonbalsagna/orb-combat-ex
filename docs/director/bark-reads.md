# The bark reads

What `NarrativeBarks` reads for the three beats in Orb's mid-combat sheet that had no read. Off with the barks. A read
offers its beat only where the speaker has a line, so nothing changes until Narrative adds marked lines. The numbers are
in `data/narrative/live_barks.json`, under `reads`.

| Beat | Speaker | Read | Number |
| :--- | :--- | :--- | :--- |
| `low_health_swing` | the one who lands the blow | a light, medium or heavy blow lands while his core is at battered or worse, from `region_stage` | `region` core, `min_stage` 2 |
| `exchange_break` | either fighter, by the emitter's hash | cue `brawl_end` whose why is idle, break, apart or walk, after a long enough brawl | `min_ticks` 300 |
| `after_chain` | the one who lands the blow | his first landed blow after his `chain_end`, within the window | `within_ticks` 180 |

**Why these reads**
- **Not `hp`.** The sheet proposed reading the fighter's health from `S`. `hp` stopped being health with the wounds: it no
  longer ends a match, and it sits at or under 20% for 88 to 89% of the blows landed in the three seeded matches. The
  core is what the brink reads. `brink_enter` alone comes too late, between 4 and 179 blows a match.
- **Not `S` at all.** A frame can drain several ticks, so `S` at the drain is not `S` at the event. Every read here is
  from the events, so a bark stays a function of (seed, tick, events).
- **Not `trade_break`.** It marks a lead in a trade, and the brawl carries on. It's also not `exchange_end`, which any
  exchange sends. A brawl a launch or a signature ends isn't a fighter pulling back, so those whys are left out.
- **Why a window on `chain_end`.** `chain_end` goes out as the exchange ends, and the sheet's moment is the blow after it.
  That blow took 69 to 949 ticks to land in five seeded matches. In eight matches, 17 of 56 chains had it within 120
  ticks and 31 of 56 within 240. Silence past the window is the point: a line about a chain doesn't fit 10 seconds later.

**The one sim line.** `brawl_end` now names the other fighter in `target`, so either can speak. A cue's hash reads only
actor, kind, text and source, so the line moves no hash.

**The emitter's fix.** Its hash used an event's place in the drained batch, so a frame that drained several ticks said
different lines from one that drained one, contrary to the file's own note. It now numbers events within their tick.
Draining one tick at a time says what it said before.

**Numbers with placeholder lines** (`bark_reads_check`, seeds 12345, 777 and 31337, 32 minutes of AI against AI):
`low_health_swing` 19, `exchange_break` 5, `after_chain` 2. These are after the emitter's limits, and with one line pool
of six a fighter. `after_chain` is rare: `within_ticks` is the lever, and it's data.

**The check.** `sim/director/tools/bark_reads_check.gd` covers each read at and past its limit, the gameplay hash with the
emitter on, the same lines when draining 1, 7 and 60 ticks at a time, and every bark against the sim at its tick.
