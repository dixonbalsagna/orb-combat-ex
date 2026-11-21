# Parked: the swing director's memory is the line's, one copy (2v2 step 1)

Encounter, 2026-11-02, the first fix of the statics audit in `../../two-v-two-plan.md`. **No switch:** it acts only in a match of two fights (`S.stage`); in every 1v1 the stage is null and nothing changes.

**Apply on the stack after `../ratchet-roster/`:** `git -c core.autocrlf=false -c core.eol=lf apply two-fights-swing.diff`. It touches only `DirSwing._g`, `_s` and a new `_anchor` in `sim/director/swing.gd`.

## What it does

The swing director keeps its memory on `S.fighters[0]`: the last big swing, the last jolt, a town's sends, the waiting launch's ask and the rest. Under Simulation's fight swap, `S.fighters` is the pair of the fight being stepped, so each fight kept its own copy of a memory that describes the one shared line. Now it's kept on the match's first body. That's `S.fighters[0]` when fight 0 is entered or during the line's own tick, and `S.stage.fights[0].fighters[0]` otherwise. It's a read through the stage, with nothing of Simulation's written.

## Read, and a finding that isn't mine

`sim/core/tools/fights_check.gd` on my stack:

| Data | Result |
| :--- | :--- |
| Main's, my switches off | **0 failed** |
| The page's switches and every switch of mine | 4 failed: fight 0 differs from the plain 1v1 while apart, on the field worlds (planets 7 and 12), from ticks 146 to 363 |
| The page's switches only, mine off | **The same 4** |
| The page's switches with the swing off | **0 failed** |
| The page's switches, the stack without this park | **The same 4** |

The differences start in fighter 0's height, at 1e-9 units, and grow to half a unit. So **with the swing on, fight 0 of a two-fight match isn't the plain 1v1 even while the fights are apart,** with or without this park. It looks like the line's: its tick sees all four bodies, and its anchor moves with them. That's Simulation's to read, since `fights_check`'s own "the same with the swing switch on" row ran on main's data with the swing off.

## Not done

- **A check of its own,** that a two-fight match with the fights together writes the swing memory only on the first body. That waits on the line being the same as a 1v1 while apart, as above.
- The arc's match counts (`A_USED`, `A_METEORS`) are on each fight's first fighter too; the first version has no meteor.
