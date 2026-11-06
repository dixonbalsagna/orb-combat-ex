# Drawing the other fight's bodies (Animation, 2026-11-02)

Rendering is drawing the second fight of a 2v2 stage (Simulation's `docs/architecture/fight-swap.md` and `cross-fights.md`; the cross-fights patch is parked). S holds one fight at a time, fight 0 between ticks; the others sit in `S.stage.fights[k]`. `anim_fighter.gd` reads the exchange from `S.dirS.ex` (16 places), the pair from `S.fighters` (6), and the clock, the beams, the clash and the world from the S it is given.

## The change: a read-only view, not a change in 22 places

Every layer already reads everything from the `S` it is handed, so the bodies of fight k are drawn by handing them **a view of S whose swapped fields are fight k's own record**:

- `RenderAnim.fight_view(S, k)` returns a `SimState` whose `fighters, dirS, T, dt, rng, game, world, beams, shots, shotSeq, mood, pause, hs, cata, epoch, popHist, waterWin, waterTick, aftermathJobs, out` are `S.stage.fights[k]`'s (the same list `SimStage._swap` exchanges) and whose every other field is S's own (the planet, the buildings, the water, the tick). It is the same object every frame, refreshed each ask. It is S itself for the fight S holds and for a match with no stage.
- **Read only.** Nothing is swapped in S (`SimStage.enter` is never called), `S.stage.cur` stays what it was, and the view copies references, never writes the sim. The test hashes the state before and after.
- `RenderAnim.solve(view, view.fighters[i])` and `RenderAnim.consume(view, events_of_fight_k)` are then the ordinary calls: the body's exchange, opponent, clash, clock and slot come from fight k. The body cache is keyed by body, and `_sync` sees through a view to its match, so a view never resets fight 0's bodies.
- `AnimFighter.gslot` is a body's place among all the match's bodies (`fight * 2 + slot`), for anything the host reads per input slot (Controls' `strike_pre(slot)`: with a stage the host should publish four slots and the pre layer read `gslot`).

## What Rendering does (through the EP)

Per frame, for each other fight k: `var V = RenderAnim.fight_view(S, k)`, `RenderAnim.consume(V, <that fight's events>)` (its `S.stage.fights[k].out`), then draw each `V.fighters[i]` with `RenderAnim.solve(V, ...)` exactly as fight 0's. Off by Rendering's own switch; with a single-fight match nothing changes, so this adds nothing there.

## Checks

`_test_fight_view`: a real `fights: 2` match for 240 ticks, then
- the view's swapped fields are fight 1's record, and it is S for fight 0;
- the pose of each body of fight 1 through the view equals the pose of the same body with the fight swapped into S by the sim's own `SimStage.enter`, within the jitter two solves of one state have between themselves (0.0024 rad: the springs read the wall clock);
- the same bodies solved against fight 0's state, what drawing them without a view would do, are 0.155 rad (9 degrees) off, so the check can tell a view from none;
- the state hash, `S.stage.cur` and `S.fighters` are unchanged afterwards;
- a match with no stage gets S back.

Not covered: what the other fight's events look like (Rendering's feed), and fight 1's cross-fight reads (`SimCross`: a beam drawn to `b.stopAt`, a shot owned by -1): the first is Rendering's, and the second changes only what the sim says, which these layers read as before.
