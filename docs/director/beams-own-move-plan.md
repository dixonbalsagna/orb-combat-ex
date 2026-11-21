# Beams as their own move: Encounter's build plan (2026-11-06)

The EP's queue item 1, from `docs/design/playable-build.md` sections 2 and 3, `docs/design/beams-third-play.md` section 2, `docs/design/beam-answers-2.md` section 1, and the controller vision (`docs/ep/proposals/controller-vision.md` sections 3 and 8). All committed. Each step below is its own park with its tests. Golden moves only where intended; Simulation regenerates it.

## The rulings, with their numbers

| Ruling | Number | Source |
| :--- | :--- | :--- |
| The stick beam is its own move, not `requestAttack("sig")`: no signature wait, its stage's price, fires at any range | | beams-third-play §2 |
| A free charge: nobody is locked while someone charges (you can hit, guard, dodge or answer the charger); the shooter stays still | | beams-third-play §2, §3 |
| Armour from tick 0 for a beam's hold; a plain strike's hold keeps 0.2 s | `armour.beamFromTicks` 0, `fromTicks` 12 | playable-build §2 |
| A medium stops the charge until stage 2 | `armour.mediumUntilTicks` 30 → 28 | playable-build §2 |
| A heavy, a grab or a beam stops it; your own guard or dodge press ends it | | beam-answers-2 UI q3 |
| No self-release, for beams and stick holds: `autoGoTicks` goes | | playable-build §2 |
| Holding past the top stage costs energy, stepping down a stage when it can't pay | 4/s for a beam, 2/s for a stick strike | playable-build §2 |
| Stages 2 to 6 by power: count `2 + round(4 × level)`, taken when the charge starts | reached on 12, 28, 46, 66, 90, 120 ticks | playable-build §2, beam-answers-2 §1 |
| A beam's price by stage, paid on release; the stage stops rising at what you can afford | 12, 20, 32, 38, 44, 50 | beam-answers-2 §1 |
| A beam's damage and how long it lasts by stage | ×1, 1.6, 2.4, 2.8, 3.2, 3.6; 0.33 to 1.5 s | beam-answers-2 §1 |
| At point blank it fires on release, and only then does the brawl give way | | beams-third-play §2 |
| The point-blank throw-back: no damage, no stun, the way he already faces, never through you, stops at a wall | out to 9 bh over 15 ticks | playable-build §2 |
| A beam can't fire until its target has been free to act for 0.3 s; the lit hand just holds a little longer | 18 ticks | beams-third-play §3 |
| The computer fires through the same move, its signature included (RT + right stick) | | beams-third-play §2 |
| A release that can't fire says why | "No energy", "Hit" | beams-third-play §2 |
| `struggle.pushMode` per player: `stick` by default, `face` as an option, the third value reserved; equal strength | window 4 ticks (sharp 2), push 0.1 (sharp 0.15) | playable-build §3 |

## What's there on main (the map)

- `DirStick._start`: RB with the stick sets `ST_ON` 3 (a beam's hold), and with `beamPlays.front.stationary` sets `f.beamCharge`. `tick` releases it on the stick's release (`_beamGo`), and loses it if he's launched, down or stunned (`_holdLost`).
- `_beamGo`: level 0 is `DirBlast.press(S, f, SimAct.SIG)` (the RB flick bug, queue item 3). Otherwise it's `requestAttack(S, f, "sig")`, then `DirBeamPlay.fromStick` pulls the fire beat in to `max(releaseTell, tell - held)`.
- `requestAttack("sig")` runs into `DirBrawl.takes` in a brawl (refused, or B's heavy), `moveLocked`, then `_start`'s 45 ki check and `sigReadyT`. `_start` locks both fighters for the whole exchange, and `DirBeam.opBeamCharge` charges (with `stationary`, no rise).
- From the fire on, `DirBeamPlay` (the front, the window, the answers, the shove at point blank via `standoffX`) and `DirBeam` (the clash and the struggle) do the rest. They key off `ex.kind == "sig"`.
- No stage system on main: the stick reader's ladder has 4 levels (`stick.json levels`). The power core (the energy model's power) isn't on main.

## Steps (one park each)

1. **beam-move:** the stick beam's own path, behind `beamPlays.ownMove.enabled` (off):
   - The release calls `DirBeamMove.release(S, f, stage)`, never `requestAttack`. It checks the price, then the free-target gate. If the gate is shut, the lit hand holds and fires on the first tick the gate opens.
   - A brawl he's in gives way at the release (`DirBrawl.end(S, ex, "beam")`). The beam exchange then starts at the fire: no 45 ki, no `sigReadyT`, no charge beat. It locks for the flight only (`releaseTell`, then the front), and the target's answers are as today.
   - Armour from tick 0 on a beam's hold.
   - Refusals: the cue `stick_refused` with `ki` or `hit` (Controls maps them).
   - The free-to-act stamp per fighter is a `dirI` slot.
2. **charge-stages:** the stage ladder for every right-stick hold:
   - The count comes from the level, taken when the charge starts. Until the power core lands, level = (tier − 1) / 3, which gives 2, 3, 5 and 6 at tiers 1 to 4.
   - The clock is 12 to 120 ticks. The beam's price, damage and length come by stage.
   - Holding at the top drains (4/s beam, 2/s strike) and steps down when broke. No `autoGoTicks`.
   - A plain strike's damage and stun stop growing at stage 3.
   - The cue `stick_stage` (k the stage, n the count) for UI's pips.
3. **beam-ai:** the computer's signature and its beams go through the same hold:
   - The AI picks a stage, holds, and releases under the same gate.
   - Nobody is locked by its charge.
   - The old `requestAttack("sig")` path stays for the Simple layout's B and for switches off.
4. **push-mode:** `struggle.pushMode` per slot, from the match setup (`setup.pushMode` per slot, default `stick`):
   - In stick mode a flick toward on the beat pushes, a flick away lets go, and face buttons do nothing.
   - In face mode it's X, Y and B, as today.
   - Same window and push. The computer is unaffected.

## Needs (for the reports)

- **Simulation:** the power core's level, for the stage count, when it lands.
- **Controls:** `stick_refused` texts `ki` and `hit`, mapped (they are).
- **UI:** the pips from `stick_stage`, the words.
- **Tools:** a page switch for `ownMove`.
