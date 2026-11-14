# Impact rumble: landed blows, closes, launches, landings, building breaks (Controls, 2026-11-06)

Orb's 2026-10-05 picks (docs/ep/vision.md, Q12): "every landed blow; closes, launches and landings; buildings breaking; beam struggles." The beam struggles were built in the first rumble round; this is the other five. Behind `switches.hapticImpact` (off; independent of the right-hand switch). The park is `docs/controls/pending/impact-haptics/`.

| Kind | The sim event | Who feels it | Scaled by | Pad shape (weak / strong) | Gap |
| :--- | :--- | :--- | :--- | :--- | ---: |
| `blow_land` | `damage`, kind light, medium, heavy, bolt, blast or guard | the attacker | strength: 0.3, 0.6, 1.0 (bolt 0.3, blast 0.7, a guarded blow 0.2) | 0.15 / 0.6, 30 ms | 90 ms |
| `hit_taken` | the same `damage` | the one hit | the same | 0.1 / 0.7, 40 ms | 90 ms |
| `close_surge` | `rush` (an attack carrying the fighter across the gap) | the one closing | none | 0.3 / 0.25, 40 ms | 200 ms |
| `launch_felt` | `launch` (actor is the one sent) | the one launched; the launcher keeps UI's `launch_open` | speed over 1,500, at least 0.3 | 0.2 / 0.8, 80 ms then 0 / 0.4, 60 ms at 100 | 300 ms |
| `landing_thud` | `land` | the one touching down | speed over 1,400, at least 0.25 | 0.1 / 0.65, 50 ms then 0 / 0.25, 30 ms at 70 | 200 ms |
| `building_break` | `building_fall` | both pads | height over 300, at least 0.3 | 0.2 / 0.6, 70 ms then 0 / 0.4, 70 ms at 90 | 600 ms |

**Soft and chunky** (the EP's word and Orb's taste for low, not tinny): every shape leans on the low motor (the high motor never above 0.3), none is brighter than a thud, each is over inside 160 ms like every kind, none is the motor on more than half the time even asked as fast as its gap allows, and a light blow is softer than a heavy one. Beams (`damage` kind `beam`), impacts and anything else rumble nothing here: the struggle has its own kinds and a landing has its own event.

**In a real fight.** Two AI matches of 90 seconds each (seed 3 and seed 11, 10,800 ticks) gave 1,217 landed blows (each a `blow_land` and a `hit_taken`), 28 closes, 10 launches and 11 landings through the mapping, every request on slot 0 or 1 with a scale from 0 to 1. A brawl is about 7 blows a second (1,217 in 180 s), so the 90 ms per-kind gap caps the pad at about 11 pulses a second and a mash of light blows stays soft by scale, not by silence; if a brawl feels like a constant buzz in Orb's hands, the gap is the number to raise. No building fell in those two matches: the mapping for it is tested on a fabricated event only.

**Wiring.** `SimHaptics.event_requests(e)` is a pure function of the event; the host calls it next to the existing mapper (`render/core/main.gd`, 2 lines in `_haptics_from_events`, Rendering's file: a grant). The host's own gap, the player's Vibration option and the pad target already apply (`_on_haptic`).
