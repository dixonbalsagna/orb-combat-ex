# The ghost budget (RL-122, RL-125; movegen-banned.json f01, m05, m12)

Owner: VFX. 2026-10-11. Code: `render/vfx/ghost_tally.gd` (`hub.ghosts`), read by `shots_view.gd`.

## The rule it enforces

- **Limb ghosts (f01):** at most 2 of one limb and 4 in all. A speed blow's smear is one; a tech blow's echoes are one each while alive.
- **Whole-figure ghosts (m12):** at most **5 round one fighter, all sources together** (10 on screen). Every ghost keeps m05 (a flat lane tint at 0.35 or less, behind him, fainter the older, on his own path).

## Who draws what

| Source | Drawn by | Kind | Most it asks for |
| :-- | :-- | :-- | ---: |
| Tech echoes of a blow (staggered: two alive at most) | VFX | whole wire figure, also a limb ghost | 2 |
| Tech echoes of a zip leg (staggered since 2026-10-11: they were three alive for the leg's first 2 ticks) | VFX | same | 2 |
| Heavy release stack | VFX | whole figure, filled tint | 5 |
| A heavy ender's flying target | VFX | whole figure | 3 |
| A zip's speed or heavy smear | VFX | whole figure | 2 |
| After-images of a rush (one a tick), a dodge, an escape | **Rendering** (`ParticleView`, from the sim's `after` events) | thin figure outline, shown only 24 to 60 units off him, for 6 ticks | 6 |
| Animation | nothing: it hands `press_pose(k)` and `press.ghosts` to VFX and draws only the lab's path dots | | 0 |

## What VFX does

Rendering's after-images are read first (from the same `after` events, counting the ones shown: 24 units or more off the fighter). Then, per fighter, what is left of the five goes in this order: tech echoes, the heavy stack, the flying target, the zip's smear. Each is cut to what is left, never more than it asked for (`echo_n`, `body_n`, `fly_n`, `zip_n`, `zecho_n`). Off (`hub.ghosts.enforce = false`) it counts only.

## What the real matches showed (hash_check, seeds 12345, 4, 7, 3,600 ticks each, quality high, plus low and reduced, `--press-styles`)

- Most limb ghosts at once 4, of one limb 2; zero ticks over f01.
- **Before the budget:** up to **11** whole-figure ghosts on one fighter. After: **6**, all of it Rendering's alone. VFX's own sources are never over; every tick over five is a tick where Rendering's shown after-images are six by themselves (2,268 ticks in the three seeds' runs, all in rushes).
- The worst tick: seed 7, `ai` scenario, tick 307, the rival (slot 1) tumbling after a launch. Six after-images of Rendering's, ages 0 to 5, opacity 0.50, 0.42, 0.33, 0.25, 0.17, 0.08, standing 60, 122, 184, 248, 314 and 380 units behind him along his own path (about 65 apart). VFX asked for 3 flying-target ghosts and 2 zip-smear ghosts on top (11); the budget gave them 0.
- **A spread, not an overlapped smear**: the six are one chain along his own recent path, one a tick, each a full figure length apart, so they do not overlap each other; they never stand round the target or in a ring.

## What is not VFX's

Rendering's after-images alone can reach 6 in a rush (`AFTER_LIFE` 0.1 s is 6 ticks, one a tick). To meet five Rendering would have to cap them (`RenderLook.AFTER_LIFE` of 5 ticks, or skip the oldest) or Legal revise the five on this evidence: six outlines, opacity at most 0.5 and fading, in one line along his own path, none under 24 units off him.

## Tests

`effects_check` groups "the combined ghost count" (a perfect blow tick by tick, Rendering's after-images alone, with an echo asked for, six alone above the budget, one under his feet not shown, a zip leg swept in twentieths of a tick) and `hash_check` (the real matches' peaks, the worst tick's breakdown, and a gate on limb ghosts and on VFX's own share).
