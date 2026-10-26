# Right-stick prototype tools

Research & Prototyping, 2026-10-23, reworked 2026-10-25. The prototype `docs/ep/prototypes/right-stick-v2.html` is step 1 of Game Design's pitch C, the family stick, reworked for one thumb by `docs/design/right-stick-pitches.md` §13 (Controls' law, `docs/controls/right-thumb.md`). The command set is §11's with §12's rulings, and the reads use Controls' fixed thresholds (`docs/controls/right-stick.md` §11). v1 (`right-stick-v1.html`, §11 and §12 only) stays as it was committed.

| File | What |
| :--- | :--- |
| `work/sim.js` | The recognizer, the sim and the drawing, with no DOM, between the "STICK SIM" and "PAGE" markers |
| `work/page.html` | The page: buttons, the gamepad (standard mapping) and keyboard, the step list and sound. Its `/*SIM*/` slot takes `sim.js` |
| `build.mjs` | Writes `right-stick-v2.html` from the two |
| `tools/` | The review harnesses: the claw-bot gate, the press and stick sweeps, chains, one-thumb play, the fuzz and the cliff sweeps, held to the law. `node tools/all.js` before and after any timing change; see `tools/README.md` |
| `gif.mjs` | Runs the sim in node with a scanline rasteriser, the bitmap font and a GIF encoder (copied from `research/energy-proto/gif.mjs`). Makes the clips, the stills, a sheet per clip and its block of the homework README (between markers, merged, never replacing the EP's text). `--check` prints every note per lane and each lane's ticks; `--frames` saves chosen ticks |

**The clips.** S1 to S4 are §13's: the step-strike queue, the four left-hand slips, the four reads and the D-pad mirror. They render by default into `homework/combat-and-controls/NOW - right stick, reworked/`. R1 to R7 are step 1's commands, now played under §13; `R` as the second argument renders them into a folder named on the command line (their homework is answered and filed in `homework/done/right-stick-step1-first-version/`). S1 and S4 are split takes: two worlds on one clock (`takeSplit`, `run.w2`), drawn side by side through a fixed camera per take, with a tick strip and a small input panel under each lane, at half speed (`slow: 2`).

**Section 13 in the sim** (`LAW`):

- **The commitment (R30).** Every stick command commits him for `L` = 6 ticks, and a hold's release locks out `L` (a beam sweep's release locks nothing, and the brawl cross-up's commitment is its rush). Steps and hops take exactly `L`.
- **The commitment the other way.** A face press commits the right stick and the D-pad for `L`. It counts from the press. A press made inside a stick commitment counts from that commitment's end instead. A press made with the stick still out counts from the stick's release or next act + `L`, or from its start if the stick is still held then. A held B counts from its last tick down. A press still waiting in the queue counts too, once the stick is free. A flick made inside the commitment waits and acts on the tick it ends, press + `R` = 8 (the thumb's 6 to the stick plus the flick's 2-tick settle), from the stick or the pad (GD's rulings 13 and 16, `docs/design/rulings-2026-10-26.md`; Controls' `right-thumb.md` rule 3 and claw-bot gate G). At most one stick command waits, and the newest input wins: a face press made after it, or a newer flick, cancels it ("FLICK DROPPED", "FLICK REPLACED", ruling 14). A hold counts its 10 ticks from that point + `L`, plus the flick's 3-tick rise when the gesture left rest inside it. So a claw's press-then-stick chain is no faster than one thumb's.
- **The queue.** Every face press (X, the RB bolt, Y, B's charge, the LB+RB mine) made inside a commitment, a hold, a press under way, the cross-up's arc or a slip waits, 3 deep, for up to `W` = 36 ticks, and starts when nothing holds him. A bolt keeps its 6-tick gap. Something other than the stick that ends a hold (a slip, a read) locks out `L` as a release would, and the stick still held is spent until it is let go.
- **The step-strike (R31, R29).** A press within `W` of a step in, a take-back, a hop or a drop, measured from where the step ends, is the blow at once. A press queued behind one draws his arm back during it.
- **R28.** Stick input never changes a press, a rush, a blow, the arc, a charge or a slip already running.
- **The D-pad (R32, ruling 15).** A tap is a flick that acts 2 ticks after its onset, the tick the stick's flick reads, so neither form is ever faster; a hold reads 8 ways after 10 ticks, as the stick's does.
- **No input is silent (E3, ruling 14).** A press the queue swallows (full, lapsed, or no longer possible when it starts), a press refused because a charge or a beam runs or the bolt's gap isn't over, and a cancelled waiting flick all flicker in his hand for 6 ticks with the not-ready cue, and spend nothing.
- **The slip (R34).** LT's tap is the one dodge against blows, and the left stick at the tap picks it: neutral dodges, away slips back, toward slips in (at most 1.1 bh), up sways over a low blow, down ducks under a high one. There is no slip in the cross-up's arc.
- **The read (R36 to R38).** With LB held a flick sets a read for 90 ticks at 3 ki: up his heavy, down his flurry, toward his grab, away his shot. It fires only on his attacks that start after it and reach him, and it shows in the stance. A wrong read costs the ki.

**The recognizer** (`readStick`) reads the right stick (`readRight`) and its D-pad mirror (`readDpad`) side by side every tick, so neither leaves the other stale, and acts on one flick a tick. Each event keeps its source. The stick takes one sample a tick and runs these stages in order:

1. **Dead zone:** 0.25 radial, rescaled and quantised to 1/16.
2. **Hysteresis:** the stick counts as out at 0.60 and back in at 0.35.
3. **Flick:**
   - It is a flick when the stick goes from rest (0.2) to 0.60 in 3 ticks or fewer.
   - Its direction is read four ways, 2 ticks after the crossing, with a tie going to the vertical. A flick let go sooner still acts on that tick, never earlier (ruling 15).
4. **Hold:**
   - A hold starts after 10 ticks out.
   - Its angle is read 32 ways.
   - Flight reads it four ways, with 8 degrees of hysteresis at the diagonals.
5. **Family:** whatever shoulder is held at the first deflection locks the family until the stick rests (none: Flight; RB: the aim; LB+RB: the lay; LB: the read).

**Patterns** are only named in the panel, as step 2's: a circle (300 degrees or more), a half-circle (140 to 250), a zig-zag (two reversals on one line), a pump (two flicks the same way within 18 ticks).

**Directions** are relative to the rival.

**Simplified in the prototype:**

- The brawl is a small stand-in for `sim/director/brawl.gd` on the data's numbers: bands, striking distance, the leash, the pull, the break and the idle. It has no damage and no blocks.
- The cliff is a rectangle: no move passes through it. A step that would cut the rock goes by the corner at its own length (below the top it stops at the face), and after a detour the next steps keep the move's own speed; a move held back that way finishes at its own speed, unless its end is inside the rock. A strike spot the face would put inside the rock keeps striking distance along the face, or on the top.
- The rival is a scripted stand-in: blows at three heights, a heavy (28-tick wind-up), a four-blow flurry, an energy grab (a loop that closes in 24 ticks) and bolts. In Play it throws them in turn.
- Under a hold the aim line points where the stick points, read 32 ways (GD's R26). A beam turns toward the stick at the fighter's own sweep rate.

```
node research/right-stick-proto/build.mjs
node research/right-stick-proto/gif.mjs --check S1,S2
node research/right-stick-proto/gif.mjs                                   # S1 to S4 into the NOW folder, about 10 s
node research/right-stick-proto/gif.mjs <scratch folder> R             # the step-1 set
node research/right-stick-proto/gif.mjs --frames S1 76,82 out.png
```
