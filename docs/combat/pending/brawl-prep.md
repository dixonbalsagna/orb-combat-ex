# Combat's data for the brawl

Owner: Combat and Choreography. Date: 2026-10-04. Status: parked data, nothing in the tree is edited. For Encounter's `docs/director/brawl-plan.md` (what it asks of Combat, section 5). Built on the live `data/combat/recipes.json` at `d24c5c1`.

Two files: `recipes.brawl.json`, the next version of the live recipes, and `channel.rival.json`, On the Chin's beats. The generated cells (`../moveset-generator.md`) are held until Orb answers on the identity split, so everything here is made from the strikes that are posed today.

## 1. What runs on the live file, unchanged

**Slice B1 is not blocked.** It needs a light, a heavy and an ender, and all three are pools that are live today.

| The brawl's press | Pool, live today | Playable: the rival, the Protagonist | With a leg broken on the ground |
| :--- | :--- | ---: | ---: |
| A light, and a flurry blow | `combo.link` (every light) | 16, 20 | 10, 13 |
| The same with the stick toward | `blur.toward` | 4, 4 | 3, 3 |
| A heavy | `power` (every heavy) | 20, 23 | 13, 14 |
| The ender | `power.last` | 16, 19 | 11, 12 |

- The blur patterns, the `pieces` block (limb and target) and the rule of no piece twice in a string work for the brawl as they do for the blur.
- The beat point is 24 ticks for every piece until `beat` lands. B1 only stores it; B2 is the first slice that reads it.
- The forms' numbers (damage, press to contact, the reel) are Game Design's table and the cell's, the same for every piece. They belong in the director's brawl data, not here.

## 2. What is new, and which slice reads it

All of it is added to `recipes.json`; nothing that exists changes.

| New | What it is | Read from |
| :--- | :--- | :--- |
| `pieces[id].path` | the angle the limb travels: line, arc in, arc out, rise, drop or spin. On all 48 rows | B2 |
| `beat` | the beat point by path: 20 for a line, 24 for an arc or a rise, 26 for a drop, 28 for a spin; 24 by default | B2 |
| `brawl` | which pool each kind of press draws on: light, lightToward, flurry, skill, juggle, heavy, lift, break, ender | B1 could read it for the four live names; B2 and B3 for the rest |
| pool `brawl.flurry` | lights that can be a flurry blow: one hand, elbow, knee or the shoulder, on a line, an inward arc or a rise | B2 |
| pool `brawl.skill` | the other lights: the kicks, the backfist, the two-handed thrust, the drops. A skill strike and a juggle strike draw here, and a missed beat lapses to the flurry pool | B2, and B3 for the juggle |
| pool `brawl.lift` | heavies that land under the jaw or in the gut and do not drop: what a lone heavy plays when it lifts | B3 |
| pool `brawl.break` | heavies that drop, or come with both arms or the shoulder: what a heavy plays on a set guard | B3 |
| `pieces[id].sends`, on the 26 heavies | where it sends him as an ender (across, up, down, turned), so the piece matches the stick's aim | B3 |

**The new pools, playable today** (the rival, the Protagonist; in brackets, with a leg broken on the ground):

| Pool | The rival | The Protagonist |
| :--- | :--- | :--- |
| `brawl.flurry` | 9 (8): jab, cross, hook, palm heel, spear hand, short elbow, rising elbow, short knee, shoulder check | 10 (9): the same and the ridge hand |
| `brawl.skill` | 7 (2): backfist, twin spear, front kick, side kick, low kick, snap round, sweep | 10 (4): the same and the knife-hand chop, the hammer-fist, the hook kick |
| `brawl.lift` | 6 (4): uppercut, spinning elbow, rising knee, driving knee, headbutt, body hook | 8 (5): the same and the rising palm, the spinning back kick |
| `brawl.break` | 9 (7): hammer, overhand, dropping elbow, double palm, double hammer, cross-arm ram, axe kick, stomp, body ram | 9 (7): the same |

- **The thin spot** is the rival's skill pool with a leg broken on the ground: 2 pieces. So the `brawl` block carries a fallback: when the filters leave a new pool empty or used up, the draw falls back to `light` for flurry, skill and juggle, and to `heavy` for lift and break.
- The rival's four tail strikes are in the pools as waiting, as before.
- When the generated cells land, these pools are written by the generator from martial X and Y, and the names stay.

## 3. On the Chin's entry beat

`channel.rival.json`: the rival's held context action, as beats. Its target is a new `data/combat/channels.json`.

- **The entry beat is the plant:** 12 ticks, pose `rv.on_the_chin.plant`. It starts on the tick the 12-tick hold of the context button completes.
- **`chin_plant` is sent on the plant's first tick,** so the glare's 0.4 s covers the plant and is gone as the stance settles.
- The other beats follow it: the stance (up to 240 ticks), a hit absorbed (6), the acknowledgement (6), an absorb completed (18), a signature absorbed (90), letting go early (20), and being thrown out of it. Animation's `rv.on_the_chin` and `rv.chin_beam` sequences already have these lengths.
- The rules and their numbers (the hold, the 4 s, 3 hits or 1 signature, the reductions, the cooldown) are Game Design's and the director's. This file is the staging only.

## 4. Keys for Tools

**`combat-recipes.schema.json`:**

| Key | Shape |
| :--- | :--- |
| `pieces[id].path` | required on every row: line, arc_in, arc_out, rise, drop or spin |
| `pieces[id].sends` | optional: a list, without repeats, of across, up, down, turned |
| `beat` | optional object: `_` notes; `default` and any of the six paths, each an integer from 20 to 28 |
| `brawl` | optional object: `_` notes; any of light, lightToward, flurry, skill, juggle, heavy, lift, break, ender, each a pool name |

Cross-checks: every pool that `brawl` names exists for every fighter; every piece of `power.last` has `sends`; `beat` has a number for every path a piece uses, or a `default`. The four new pools need no schema change.

On a scratch copy of HEAD the validator rejects exactly these four keys (`beat`, `brawl`, 48 `path` and 26 `sends`) and nothing else.

**`combat-channels.schema.json`** (new, `combat.channels/1`), when On the Chin is staged: fighter to a channel or null. A channel has `id`; `entry` (`beat`, `ticks`, `cue`, `cueAt`, `sequence`, `pose`); `beats`, a list of `beat`, `ticks` (an integer, or a least and a most), and optionally `pose`, `sequence`, `cue`, `react`, `pause`; and `limits`, a list of strings.
