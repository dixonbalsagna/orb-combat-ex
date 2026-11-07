# 2v2: a finished fight, the sim's part

Simulation, 2026-11-02, the EP's brief for 2v2's step 3. Encounter's plan is `docs/director/two-v-two-plan.md` (section 3), and the rules are Game Design's in `docs/design/two-v-two.md`. It's on the fight swap (`fight-swap.md`) and hits across fights (`cross-fights.md`), behind the same switch: `data/fight/cross.json`, off on main.

## The rules, as built

**A KO'd fighter is out for the match** (`Fighter.out`). He's inert:
- No shot meets him, no blow or beam reaches him, and nothing he sent across lands.
- His shots end where they are.

**His fight keeps its KO and keeps stepping:**
- The KO's slow motion runs, as in a 1v1. That's the winner's moment standing in the wreckage.
- The winner stays a free body, and the fight's director stays quiet: it has nobody to pair him with.
- He can still be reached from outside, and he fights from outside, by Encounter's step 2.

**The match ends when a team has nobody standing,** not at the first KO.
- `S.stage.over` names that team. `SimCore.ended(S)` is what a host asks.
- With this switch on, `S.game.ko` is only that fight's KO.
- A first KO's banner reads "K.O. *name* IS OUT". The last reads "K.O. *name* WINS", as ever. **The `ko` event says which, for UI:** `over`, and on the last KO `winners`, the winning team's starting slots.

**The rejoin.** Once both fights are finished with one fighter standing on each team, the two standing become one fight's pair, and the two who are out become the other's.
- **Where:** the pair goes into the fight the first of them is already in.
- **That fight:** its KO is cleared and it fights on as a 1v1.
- **Each body:**
  - Wear and the brink stay as they stood (Game Design).
  - His times move to his new fight's clock, as a trade's do.
  - Who last sent him is forgotten.
- **Shots:** the two slots that changed hands lose their shots in flight, because a shot names its owner by slot.
- **When:** it waits for the second KO's moment (`rejoinAfter`, 2.2 s of that fight's time), for any pause, and for any of the three bodies in a launch or a rush.

**Encounter's next steps can read the other fight's middle** with `SimCross.middleOf(S, i)`, the middle of fight i's standing bodies with nothing written.

## A bug it found: who sent a body outlasts his landing

`Fighter.launchBy` is cleared by some landings and not others. A computer match showed a standing fighter still naming his sender 6,000 ticks after he'd landed. `trade` refused any body with it set, as the first version of the rejoin did, so after such a landing both waited forever.
- **Both now read a launch from the body's state** (`launched`).
- **Both clear `launchBy` on the bodies they move,** since a sender from the old fight means nothing in the new one.

`trade` is on main, so this changes it with the switch off as well, but only by allowing trades it wrongly refused.

## Not mine

**Encounter's:**
- The winner's flight.
- His focus moving across.
- What a blow from outside does.
- **The new pair's director state:** it starts fresh on the rejoin, as their plan says. The director's state for the rejoined fight is the one that fight had, with no exchange running. If it needs a reset, Encounter sends the lines and I add the forward.
- Their step 2's forward from `SimCross._land`, when their lines come.

**While his fight is finished, the winner is under its KO,** so whatever the director gates on `S.game.ko` is off for him until the rejoin: a form, the last stand, a rally. That's Encounter's and Game Design's to rule on.

**Hosts:**
- Ask `SimCore.ended(S)`, not `S.game.ko`, with this switch on. Today that's `render/core/main.gd` (its result record), `net/ai_driver.gd` and NetLan.
- Netcode's `NetLan._follow` already follows a player whose body moves fight.

**Per-body holds** (`Fighter.stop`, Netcode's field name) aren't built. A finished fight's winner is alone in his fight, so a hold there holds only him. They're needed for step 2's blows when the striker still has his own rival.

## Proof

`sim/core/tools/cross_end_check.gd`, verdict `CROSSEND: n check(s) failed`, and `--negative-control`.
