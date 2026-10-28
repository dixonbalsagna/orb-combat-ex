# Biomes W6: the launch candidates' flight hooks, and the prop query the sim owns

World, 2026-10-28 (cloud). Brief: `docs/ep/cloud-briefs/world-w6-flight-hooks.md`. Design: `docs/combat/biomes.md` section 3. Everything here runs only with Combat's `biome.enabled` (`data/combat/launch_biome.json`), which stays **off**.

## 1. Where the plan's fields live during a flight

The director's plan is a Dictionary that lives for one launch beat, so its fields have to be kept somewhere hashed and snapshotted for the length of the flight. World can't add a field to the fighter or the state (both are the core's files). So `DirLaunch.doLaunch` writes a **record** into the fighter's own director integers (`f.act.dirI`), in a block after the rally's (`DirLaunch._hkBase()`). These are Encounter's lines, under the brief's grant.
- The block is sized only when `biome.enabled` is on, so with it off the hashed count never moves.
- A record belongs to one launch: it carries the launch number `WorldBrunt.arm` gave it, and a later launch whose plan has no biome field writes none, so a stale record never plays.
- Fields, as integers: the kind (MARSH SWALLOW, TREE LINE, PROP SMASH, ICE SKID, or none for a soft landing only), `embed` and `treeBrake` × 10⁶, the prop's x × 1000 and its column, `soft` × 10⁶, and a ring of the last four props the fighter broke.

World's flight (`WorldContact.stepFighter`) reads the record once a tick through `DirLaunch.flightHook`. It reaches the director by its script's path (`SimDir._d("launch.gd")`), as SimDir's own calls do, so the world's load still compiles none of the director.

## 2. The hooks

| Candidate | Where | What it does |
| :--- | :--- | :--- |
| MARSH SWALLOW | `_land`, `_contact`, `_swallow` | The first landing is a slam whatever its angle, and it never hops. The slam always embeds, whatever the bowl's depth or the embed's cool-down. The embed event's depth is `embed` (1.8) times what a plain embed sits at. The 60-tick down state is unchanged. |
| TREE LINE | `_hookPath`, `_snapTrees` | In the air or on the ground, each standing trunk whose column he crosses in a tick, with him lower than its top, snaps (`alive` false, debris). Each takes `treeBrake` (12%) off his speed: vx and vy in the air, the skid's speed on the ground. Every trunk on the path snaps, not only the ones the planner counted. |
| PROP SMASH | `_hookPath`, `_smashProp` | When he reaches the plan's prop and it still stands (the prop query still lays it, and he is lower than its top), it breaks. The director keeps it broken (`DirLaunch.propBroke`). He stops a body's radius (30 units) short of it, with the stop's light brunt (`bump`, a heap's: no dent). In the air his across speed goes and he drops from there. On the ground the journey ends as a stop. |
| soft landing | `_pay` | Every bit of the journey's wear (the slam, the touch-down's share, the skid's speed lost, a wall's stop) is multiplied by the plan's `soft`, and the journey's cap with it. So the whole journey hurts `soft` times as much. |
| ICE SKID | `stepFighter` | Ruling 12's hand-over (`_skateCheck`) runs for this launch even with `skate.json` off. When the skid begins, a reference run on the surface's own braking is made (sea ice's surface is rock, so that is rock's 0.8). Control returns at that tick, and the rest is the skate on the real ice brake (`stepSkate`). When the journey ends first (he slides off the floe into a lead, or tumbles to a stop), nothing changes. |

The hooks are the runtime's only. The planner's journey predictor (`journey`) does not see them, so a TREE LINE's predicted travel is still the unbraked one.

## 3. The prop query: `WorldGround.matchProps(S, x0, x1, broken)`

This is the one function for the props in a match, for the director and for the renderer.
- **The props:** `propsIn`'s, keyed by the planet's seed (`S.planetRing.seed`) with the ring's trees and lakes. These are the same arguments W5 gave Rendering, so what the sim reads is what is drawn.
- **Rows:** every row is laid, vents included. The provisional rows (bergs, lone trees) are laid only with `provisionalProps` on.
- **Span:** the span is taken by columns and split at the seam.
- **Broken props:** a broken column loses its **biggest smashable prop**, and only that one (`WorldGround.smashIn`): a scrub or a snow drift beside a boulder stays, and PROP SMASH breaks the boulder, not the last prop laid in the column. The smashable kinds are `ground.json` `smash` (lone_tree, boulder, berg, lichen_rock, lava_rock: Game Design's rulings-2026-10-28 item 3, outcrop out), which `ground_props_check` holds equal to `launch_biome.json`'s PROP SMASH props. The director's list is `DirLaunch.brokenProps(S)`.

  *Why:* the probe's "prop: ...left it out" line failed once in ten on HEAD (a highland column holding a boulder and a scrub: the hook took the scrub, the query dropped both). The list alone was not the cause.

The director's `_propsNear` (VENT LIFT, PROP SMASH, ICE SKID's berg) now calls it. `_propSeed`, the FNV hash of the fine biome map, is gone. With the switch on, the director's props are now the drawn ones: the planet's seed, and lone trees clear of the ring's trees and lakes.

## 4. The probe

`sim/world/tools/flighthooks_probe.gd` searches 24 gen 2 seeds for spots where each candidate is offered, then plays real launches there:
- the director's launch beat when it picks the candidate;
- otherwise `doLaunch` with the planner's own candidate.

Each hook is measured against a twin: the same launch with the record's kind or soft cleared right after it. With the switch off, the same plans launch with no record and no hook.
