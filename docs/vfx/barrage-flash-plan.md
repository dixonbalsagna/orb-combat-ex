# The barrage signature: the flash plan (2026-10-12)

Owner: VFX. Paper, half a page, no build. For Legal's condition sg01 (`docs/legal/movegen-banned.json`, RL-135) on Combat's `docs/combat/barrage-signature.md`. The rules it must meet: **at most one full flash (the last volley's) and two lesser ones in any second, counted over the whole screen with everything else** (k05 and the release margin), each small (a thin edge or short cone), none red, no whole-screen flash, a rim on the rival on a landing; the hand lit as a thin edge, never a ball (e06); no aura, no crouch, no charge pose in the walk.

**The schedule is inside one second.** Volleys at 12, 36 and 60 ticks: 48 ticks first to last, so all three and everything they cause sit in one 60-tick register window. The register's own limits there: a sum of weights of 2.5 (1.0 reduced), at most 6 flashes of any weight, 3 of weight 0.5 or more, 1.5 of low-priority weight, none low-priority in reduced.

| Volley | The hand | What it lands with | Register | Weight |
| :-- | :-- | :-- | :-- | ---: |
| 1, the sweep (five shards) | A thin lit edge along the blade hand, 4 ticks before release: `energy` source, half the usual length, alpha 0.6 | A rim on the rival (a thin outline at his edge, not a flash) and the shards' own small dust: **no flash disc on any shard** (five in one tick would be five asks) | One lesser ask | about 0.05 |
| 2, the thrust (three in a line) | The same edge, one knuckle length, 4 ticks before release | A rim, one ring at the first landing of the three | One lesser ask | about 0.05 |
| 3, the flick (one that splits) | The edge at its fullest and a short cone at the release (not a ball): the one full flash | A rim, and the split's landing flash at its usual small size (`k` 1 from Encounter: the one blow in 20 ticks that may take the full flash) | One full ask: weight at most 0.5 (a disc of 11,000 px² at the close framing), `energy` or `signature` source, step 0.2 | at most 0.5 |
| Close by hand | A heavy from his own pool: today's heavy look (the release stack of body ghosts, 3 of the fighter's 5) | A contact ring | The register's own `body_hit`, under its low-priority share | 0.17 |

- **What is counted in the worst second:** one full (at most 0.5) and two lesser (about 0.1 together): 0.6 of the 2.5, three asks of the six. That leaves 1.9 and three asks for the bodies' hits and everything else in the same second. No volley can consume the budget.
- **How the pace rule helps:** `flash_every` (20 ticks between full flashes, across both fighters) already refuses a second full flash within 20 ticks; the volleys are 24 apart. The first two ask with `k` 0 (no full flash; the `k` field on Encounter's `energy_land` cue is what marks the one that may).
- **Reduced motion or reduced flashing:** the last volley loses its flash entirely (none is granted to the low-priority source at 1.0) and keeps the edge, the rim and the ring: the barrage reads by its three shapes, as the sketch says it should.
- **Not a flash source on camera travel:** the shards are 2 to 9 px lines and the rim is a 2 px outline; the area budgets for puffs and embers already hold the rest.
- **What would break it:** a flash disc per shard; the hand edge drawn as a ball; the three volleys at under 20 ticks apart; a rim as a filled band. Each is refused by a test I will add with the build (a barrage at 24 ticks, seeds 12345 and 1: worst second at most 3 asks and 0.6 weight).
- **Ghosts (m12).** None: the walk is slow and unhurried, so Rendering draws no after-images; the heavy at the close is one stack of three.
