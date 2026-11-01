# The water family and anim_check: wrong setup, not lost animation (Animation, 2026-10-31)

Owner: Animation. The EP's question (Tools' bisect: 13 failures of `anim_check` with the preview's water family on, `surface`, `interrupts` and `floor`): are the checks reading the wrong setup, or is body animation really lost with the family on, as Orb plays? **Answer: the checks read the wrong setup. No body animation is lost by the family.** Evidence, on a tree of HEAD with the preview's switches on (the same file flips as `tools/preview/switches.mjs`), every run one Godot job.

## What the 13 are

| Failing checks | Cause | Shown by |
| :--- | :--- | :--- |
| flight locomotion (the hover's breath), ground locomotion by surface (landing sinks 0.00, kick-off 0.00), air recovery (0.00), secondary motion, the pop | The tests stage a body at `WorldTerrain.groundY`, the bed. With the floor on, a free fighter's floor in the ring's own water is the surface less his feet, so a body at the bed is 2,600 units under his floor and every ground and air layer reads him as submerged and does nothing (so the on-against-off differences are exactly 0.00). The sim never leaves a free fighter there. | Staged at `WorldWater.floorAt` (which is `groundY` with the floor off): all five pass with the family on. |
| zip view down: "dropped 21 ticks (the sim's 24)" | The director's water half (`interrupts.json` `water.enabled`): a knock-down that ends in water is brought up and counts as landed, so the sim's drop can be shorter than `knockdownTicks`. The render follows the sim's own state; the check compared it with the config. | `interrupts` alone gives exactly this one failure; nothing else. |
| zip view down: "the state locked" at the end | The window of the check ends 28 ticks after the drop and with the family on the AI's next zip has begun by then (the states: free 11, locked 12, free 2, dropped 24, free 28, locked 10; with it off: free 38 to the end). The window reads a different match. | The state run above. |
| press-tick anticipation (0.43 of 1.2), the lunge's crouch (0.35 of 2.5), styles (1.53 of 2.5), medium wind, energy reach (three) | **Not the family.** These tests stage `y = 0` at x = 500 to 1900, and the match is a planet whose sea there has its bed 2,633 units under 0: with the floor off the body has always hovered far above his ground, and the checks were set on that hovering body. With the floor on the same `y = 0` is the sea's own floor and the body stands. A hovering body (idle pose: the head 4 units ahead of the pelvis, the pelvis at 36.6) and a standing one (11.0 and 32.3: leaning, already low) differ, and the lunge crouch and the press-tick lean add little to a stance that is already crouched. | With the family **off** and the bodies staged on the ground (`groundY`), the same seven fail with the same numbers (0.43, 0.35, 1.52, 23.8, 16.7, 17.4); no single render flag (ground feet, ground and flight locomotion, secondary motion, pop, air recovery, lead-in, free-arm slew, limits, ease, hit variants) removes it. |

## What changed (render/anim/tools/anim_check.gd only; `water-checks.patch`)

- The 22 stagings at `WorldTerrain.groundY(S, x, z)` are at `WorldWater.floorAt(S, x, z)`: the same number with the floor off (`floorAt` returns `groundY`), the sim's own floor with it on. The full check passes unchanged with the family off.
- The zip drop check asks what it meant to: the drop is the sim's (`knockdownTicks` long, or shorter only when `water.enabled` is on and the drop ended in water), and the body draws it as long as it lasts (`drawn_drop` within two ticks of the sim's `dropped`).

Result: with the family off the check passes as before; with it on **13 failures become 8**: the five and the zip drop count are gone.

## What is left, and why I did not touch it

The seven checks that stage at `y = 0` and the zip window's second zip. They fail with the family on because `y = 0` there is a standing body, and they fail the same way with the family off for any body that stands: they are not a loss the family causes, and a change to them is a decision about the bodies' height. I tried a fixed hover height (+100 above the floor): with the family off it broke another check ("tech consistency" 0.229 against 0.15), so the checks are sensitive to how high the body is; a lift that keeps each body the same distance above his floor with the family on as off (its lift over the bed added) passes with the family off and gave four different failures with it on (the window's hand height, energy reach, tech consistency, the zip state). So the staging height is a free parameter the checks never named. The decision needed: **stage the checks on a hovering body at a height the checks name (and re-set their thresholds on it), or on a standing one (and re-set them on that)**. It is Animation's to do and not urgent: nothing Orb sees is missing.

## One thing the grounded numbers say about play

On a standing fighter the lunge crouch adds 0.35 units over his stance and the press-tick anticipation 0.43 (the checks want 2.5 and 1.2): small against a stance that is already low and leaning. They are the same with the water family off. If Orb wants those two beats to show on a standing fighter, that is a tuning of their poses and it would change every grounded match, family or not.
