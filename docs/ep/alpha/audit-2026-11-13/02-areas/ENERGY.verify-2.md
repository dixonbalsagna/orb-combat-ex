# ENERGY: verifier 2 (commit 8901d351)

Read-only attempt to refute two findings from ENERGY.md.

| id | verdict | new severity | what I checked | note |
|---|---|---|---|---|
| F-ENERGY-09 | confirmed | unchanged (minor) | `ui/core/ui_sim_bridge.gd:85-87`, `:109`; `data/fight/ladder.json:10`; `ui/widgets/ui_plate.gd:377`; `ui/core/ui_fighter_model.gd:49`; `sim/core/fighter.gd:554`; `sim/core/fighter_data.gd:644-651`; grep of `ui/` for other writers of `momentum` | The bridge is the only live writer of `momentum` and hard-codes 25 per tier, while the sim reads `[35, 65, 100]` from data: the tier-1 pip is full at power 25 (ready at 35), tier 2 starts 40% full and fills at 50 (ready at 65), tier 3 starts 60% full and fills at 75 (ready at 100). The separate transform prompt reads `f.act.formReady` (`ui_sim_bridge.gd:113`), so only the pip misleads; minor holds. |
| F-ENERGY-14 | confirmed | unchanged (minor) | `render/core/look.gd:489-494`; `render/core/fighter_view.gd:98-107`, `:124`, `:137`, `:220`; `render/vfx/glare.gd:16`, `:23`, `:62-65`, `:84`; `data/fight/power.json:91-102`; `data/vfx/` (no `glare.json`); `data/fighters/*/fighter.json` role lines; grep for `kitFields` readers | Every cited line says what the finding says: outfit and seed keyed by roster id in a code const (with a default for unlisted ids), cape, hair and gear colour keyed on the role words, and `kitFields` keyed `protagonist` / `rival`. The glare's data override does not rescue it: `data/vfx/glare.json` does not exist, so the code list of names at `glare.gd:23` is what runs; and no `.gd` reads `kitFields`, so that row is content only. |

Notes that do not change a verdict:

- F-ENERGY-09: fighters with their own form steps (`data/fighters/<id>/forms.json`, `sim/core/fighter.gd:663`) use those steps in place of the ladder's thresholds; the bridge's 25 does not follow those either.
- F-ENERGY-14: `fighter_view.gd:124` and `:137` are in the placeholder body, which stays (hidden) under the animated one; `:220` is in the animated body's palette, so the role word reaches the shipped look.
