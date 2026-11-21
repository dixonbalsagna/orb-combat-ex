# A sure blow keeps to contact.reach (Encounter, 2026-10-30)

QA's hard test `10.reach` failed with the lake floor on: 2 strikes of 427,048 beyond 68 units, the longest 78.8
(`docs/qa/cloud-reports/2026-10-30-lake-floor.md`). QA's guess was a body lifted in water. It isn't: **the floor doesn't
cause this.** The floor-off arm drew none on its own seeds, and it could have.

## What the two were

| Seed | Tick | Where | Distance before the step, after it | Height off the ground |
| ---: | ---: | :--- | :--- | ---: |
| 59 | 17829 | Low over the ground | 104.6, 70.8 | about 80 to 120 |
| 99 | 14493 | High in the air | 118.4, 78.8 | about 2840 |

Both are a launcher inside the stagger, which is a sure blow (`brawl.gd`: "a launcher inside the stagger always lands").
Both came just after a recoil flip carried the rival off. A sure blow skips the check that stops any other blow landing from
beyond `contact.reach`, and the attacker's closing step is capped at about 40 units a tick, so it landed from where the step
left him.

The mirror-villain arm, which QA's row doesn't read, had four more before the fix (84.0, 84.0, 100.6, 101.6), two of them
light blows.

## The change

`DirBrawl.sureWaits`, called by `DirExchange.runBeat` before a brawl's blow lands. A sure blow still beyond `contact.reach`
takes its step and comes a tick later, for at most `give.sureWaitTicks` (6). If it's still out of reach then, it meets nothing,
as any other blow from there does. In reach, nothing runs. A double hit's and a zip's blows keep their own rules.

A blow waits a tick or so, which can't be seen, and the promise that it lands stays. Set `sureWaitTicks` to 0 for the old
behaviour.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/brawl.gd` | Encounter | `sureWaits`; `contact` takes a step already made, and misses a waited blow still out of reach |
| `sim/director/exchange.gd` | Encounter | The call |
| `sim/director/tools/sure_reach_check.gd` | Encounter | The check, with a negative control. Add it to CI's list |
| `data/director/interrupts.json` | Encounter | `brawl.give.sureWaitTicks` |
| `tools/schemas/director-interrupts.schema.json` | **Tools** (grant) | The key, not in `required`: the self-test's frozen fixtures don't carry it |

## Reads

QA's overlay at 7f5d14ab, 200 matches an arm, seeds 1 to 200, floor on.

| Arm | Before | After |
| :--- | ---: | ---: |
| default (QA's row) | 2 of 427,048, longest 78.8 | **0 of 427,410, longest 67.9** |
| mirror-villain | 4 of 420,442, longest 101.6 | **0 of 420,770, longest 67.97** |

In the default arm only seeds 41, 59 and 99 change at all. Seed 41 wasn't one of the two, so it is most likely a sure medium
blow, which QA's record doesn't count; I didn't trace it.

## Gates

On a6637f35 (a copy with this diff, before the schema's `required` line came out): golden byte-identical to main's, twin same,
parity, load_split, determinism plain and `--intro`, rollback and `--ai`, `brawl_cases`, `reads_check`, `bark_reads_check`,
depth, flight, hud 5870/0, anim, lint. On 2cf3801a, with the final diff: validate 283/0, self-test 9801/9801.

Stacked with `beam-struggle`: both apply, the golden with the switch on is the same as the struggle's own, and with the switch
off byte-identical to main's. Not run here: `enet_check` (CI only).

Floor stays off. Nothing on screen changes that a side-by-side could show: it's one tick on 2 blows in about 427,000.
