# World's wall slam, breaches and failing state: what VFX needs and what it costs (2026-10-12)

Owner: VFX. Paper. Reads `docs/world/destruction-windows-bc.md` (sections 3 and 7). Nothing here is built except the `wall` outcome (section 0). Measured with a scratch probe against today's `debris.pancake` (33 floors, a 675-unit tower, events sent every 15 ticks), at three framings; the register is asked by none of it today.

## 0. Built now: `building_hit.outcome` "wall"

`VfxDebris.stays_in(outcome)` is true for `crack` and `wall`: `burst_through` makes no exit-side glass, steel, chunks, puffs or ring for either, and `_on_building_hit` adds no exit hole (a `collapse` has neither hole as before). A wall hit has the entry burst and one ring, as a crack. Tested (`effects_check` "the wall outcome": one ring for wall and crack, two for a heavy hit, and fewer bits). Inert until World applies W.

## 1. What each event needs

| Event | What VFX does with it | Needs | Cost |
| :-- | :-- | :-- | :-- |
| `lodge` {actor, b, x, y, z, hold, n} | **Dust in the breach for `hold` seconds**: a slow vent at (x, y, z), one puff about every 8 ticks, 90 to 180 units, drifting up, and 2 chips a second falling from the lip. It ends when the body is out. Nothing bright: no flash, no ghosts, no ring | `hold` is the tier's lodge seconds; Camera holds the frame | At 2 s: about 15 puffs (the pool refuses what the budget cannot hold) and 4 chips. 0 register asks |
| `building_failing` {b, x, y, w, h, t_warn, t_fall, n, kind} | **The warning**, for `t_warn` (1.5 s, 0.6 over a hold): a thin curtain of dust sheds from the top third of the facade, 6 to 8 chips and a few glass slivers a second, growing as it nears the fall. `n` (the tip: -1, 0, 1) biases the drift. A shiver of the facade itself is Rendering's (it reads the state). The groan is Audio's | `n`, `t_warn`; a read of which floors are standing (`failK`, from state) so the shed stays on standing floors | 12 bits a second for 1.5 s, about 18 in all. 0 register asks |
| `floor_hit` x0, x1 | **The breach**: the glass, dust and ring come from [x0, x1] on the lowest floor hit and the window row blows out *toward* it (full strength inside, a third beyond), in place of the fighter's entry x plus 15% of the width | x0, x1 in world x (0, 0 for a crack or a dent: the old rule) | The same bit count; they are placed, not added |
| `floors_fall`, one per landed floor | **A landing**: a puff (sized to the floor, section 2), 5 glass, 2 steel and a thin ground ring; the last landing of a tower keeps today's bigger dust | `from == to`, `n` 1, `w`, `x` as sent | Section 2 |
| `building_stage`, `building_fall` | Unchanged. The fall at the end is "implode" | | |

## 2. What the per-floor falls cost

Measured, one 33-floor tower failing a floor every 15 ticks, against today's single pancake of the same tower (the pancake draws at most its top 14 floors):

| Framing (px a unit) | Events | Bits made | Puffs refused | Alive at the worst | Rings alive at once |
| :-- | ---: | ---: | ---: | ---: | ---: |
| Close (1.3), per floor | 33 | 264 | 66 | 58 | 3 |
| Close, today's one pancake | 1 | 99 | 28 | 99 | 1 |
| Mid (0.6), per floor | 33 | 266 | 64 | 58 | 2 |
| Wide (0.3), per floor | 33 | 272 | 58 | 60 | 2 |

A match with 131 landed floors makes about 1,050 bits over ten towers' 3.3 s falls. The pool (460) is never close: **per-floor is lighter alive than the pancake** (58 against 99) because it is spread over time. It asks the flash register nothing, and has no ghosts (a fall makes none; the fighters it hurts are launched by the sim, and Rendering's after-images are budgeted separately).

**What is wrong with it, and is mine to fix before it lands:**

1. **The puffs are screen-filling and so refused.** A landing's puff is sized for a whole pancake (`clamp(w/2, 150, 600)`, up to 566 units across at its widest): 424,000 px² at the close framing, nineteen times the register's area threshold. The puff budget refuses every one of them (66 of 66 here), so a landing today would show glass, steel and a ring and **no dust**. For a floor the puff should be sized by the floor and the width: `clamp(w/4, 80, 200)`, 90 to 230 px at the close framing, which fits the budget (a puff of that size is 5,000 to 31,000 units squared against a close cap of 19,000).
2. **The ring is a flash.** `pring` is a ring drawn face-on whose band is 10 to 18% of its radius (it thins as it fades) at 0.6 alpha from its first tick: at w = 675 it grows to 1,350 units across with a band of 70 to 120 units. Four landings a second draw four of them. The analyser's window is 341 by 256 px; a band of 140 px through it is 48,000 px², more than twice the threshold, and it starts at full alpha. A ring for a floor must be **thin: a band of at most 20 px at 1024 by 768** (a window holds at most 6,800 px² of it, under a third), alpha at most 0.35 and fading in over 3 ticks, and only **every fourth landing** (and the last) draws one.
3. **A big puff appears in 4 ticks.** A puff fades in over 0.06 s whatever its size. For puffs wider than 150 units that is a step of 0.1 and over on a large area in four frames. A fade-in of `0.06 + size / 2500` seconds (0.29 s at 566 units, 0.076 s at 40) keeps small puffs as they are.

These three are one small batch (the landing's dust, the ring's band and rate, the fade-in), inert until a `floors_fall` with `n` 1 comes. I will build them when World applies C, and check the collapse clip with them.

## 3. Against the budgets

- **Flash register.** Nothing here is a full flash. The landings' dust, glass and rings are pixels the analyser sees and the register does not. The rule above (thin ring, every fourth, slow fade-in, puff within the area budget) is what keeps them under the threshold; the register cannot help. If World's falls land at four a second for a tower, a landing is 8 bits and a ring every second landing under the rule: about 2 px of band each and under 1,000 px² of ring in any window.
- **Ghost budget (m12).** None of this makes a whole-figure ghost. The new states that do: a launched fighter (his own after-images, Rendering's, capped at five) and the heavy's release stack of a blow that follows. A fall hurts a fighter under it, so one launch may land in a seconds-long landing; the budget counts it as any other.
- **collapse-normal, 3.5 on camera travel.** The camera's travel is the amplifier of every pale thing in the frame. Per-floor falls spread the same dust over 3.3 s instead of one second, which is better for the analyser than one burst; with the three fixes above the landings add no counted change of their own. I will say so only after the clip is run with C applied.
