# The right stick: pitches for Orb

Owner: Game Design. Status: **pitches, 2026-10-23,** reconciled with Controls' input side in §10 and §11, which rule where they differ. §11 holds step 1's command set, §12 rules it against today's director, and §13 reworks it for one thumb (the claw-grip law). Paper only. Every number is a first value, and Controls is writing the input side (`docs/controls/right-stick.md`). Orb can pick one pitch or mix them, and §9 recommends one.

**Orb's ask** (`docs/ep/vision.md`, "The right stick", 2026-10-23): the right stick as an attack, a mobility tool, or a hybrid that changes with what is held (defensive, energy and so on), with the hybrid preferred for agency. A quick flick and a steady hold should do different things. Free-form patterns such as zig-zags should work the way some skateboarding games do their tricks. "Another method of commanding your fighter."

**What Orb set aside before, and how these pitches differ.** On 2026-10-05 Orb didn't pick "the right stick calling the launch", and ruled that "the player nudges, the director stages it" (`docs/ep/vision.md`, questionnaire 19). In homework 5 Orb chose depth that follows from pushing and pulling, not depth steered on the right stick. **None of these pitches calls a launch, calls a set piece or steers depth.** The launch stays B with the left stick's nudge, and depth stays emergent. The right stick here commands the fighter's own body (where he goes, where he aims, how he defends and how he shows off), never the director's staging.

## 1. What any right stick keeps

- **R1. One thumb.** The right thumb plays both the face buttons and the right stick, so it can do one at a time. The shoulders are index fingers, so a held shoulder plus the stick is comfortable, and a face button plus the stick is not. Every pitch is built around that.
- **R2. The left stick stays as it is:** movement, the nudge on launches and throws, and the lean that aims.
- **R3. One gesture, one action.** A flick is one action, a pattern is one action, and a hold is one sustained action, as the held flurry is. This is the press-feel rule carried to the stick.
- **R4. A hold is its flick, continued.** Every hold starts as the flick in its direction, so the stick acts at once and a slow thumb never misfires. This is the X stream's rule (`energy-overhaul.md` E23).
- **R5. A pattern upgrades the flicks it is made of.** Each flick in a zig-zag acts as it is drawn, and when the pattern completes, the game turns the run into the pattern's move. An unfinished pattern is just its flicks. This is how the brawl reads a mash: presses it recognises.
- **R6. Nothing essential lives only on the stick.** Everything the fight needs stays on the buttons. The stick adds options and takes none away, so Simple, touch and one-handed play lose no core action.
- **R7. The pillars hold.** Never out of range (every pitch has a move that closes the gap from any distance). Control first: no stick move takes his hands for longer than 16 ticks, and none locks the camera. Nothing goes on, over or between the fighters.
- **R8. Soft costs, no cooldowns.** Ki and freshness pay for repeats. The third trick of a kind inside 3 s loses its slip frames, as freshness wears a repeated kind.
- **R9. Deterministic.** The stick reaches the sim as intent fields stepped each tick. Gestures are read from that recorded history, so replays reproduce them (Controls and Simulation decide where the reader lives).
- **R10. R3 stays the transform,** held to confirm. No gesture needs a click.

## 2. The reads, shared by every pitch

| Gesture | How it is read (first values, Controls' to set) | Its job |
| :--- | :--- | :--- |
| **Flick** | Out past 80% and back inside the dead zone within 8 ticks. Its direction is the angle at its peak, in 8 ways. It acts at the peak, with no waiting for the return | A quick, one-off command |
| **Hold** | Out past 50% for 10 ticks or more. Angle and depth stay live while held | A sustained command, analogue |
| **Release** | Back inside the dead zone | Ends a hold |
| **Pump** | Two flicks the same way within 18 ticks | A stronger version of the flick |
| **Zig-zag** | Three or more reversals across one line within 30 ticks | A weave, a flurry, a scatter |
| **Half-circle** | A sweep through 180° (±30°) within 20 ticks, read by where it ends | A turn, a vault, a curve |
| **Circle** | A sweep through 330° or more within 30 ticks | A roll, a ring, a spin |

Five patterns and no more, so the set fits in a thumb's memory. Directions are read relative to him: toward, away, up and down, and the diagonals between them.

## 3. Pitch A: the flight stick (mobility)

**The idea:** the left stick drifts him, and the right stick bursts. His footwork, his angles and his escapes go into the player's hands.

| Gesture | What he does |
| :--- | :--- |
| **Flick** | A burst that way: 2 bh in 8 ticks, in any of the 8 directions. **Toward him from beyond reach,** it becomes a lunge that closes the gap (never out of range). Up or down beside him, it is a hop over a low blow or a duck under a high one, with slip frames against the blow it clears |
| **Hold** | The burst, continued. Toward or away, a dash. **Up or down beside him, the orbit:** he arcs over or under the rival at the same distance, facing him, and comes out on his other side, a cross-up. Into a wall, a cliff or a building's face, he runs along it. Down near the ground, he skims the surface |
| **Zig-zag** | **The weave:** every reversal is a slip with frames against shots, so a weave through a stream or a barrage is the answer to rapid fire |
| **Circle** | **The corkscrew:** a barrel roll that turns light shots aside and ends facing him. In reach, it rolls him around the rival's blow to his back |
| **Half-circle** | **The vault,** over or under him, which ends on his other side |
| **Pump** | Toward: the lunge at full reach. Away: the backflip escape, which is the escape stance's gamble done by hand (pillar 3) |
| **Off a wall run** | A flick away is the wall kick, in `fight-feel.md`'s ±4-tick window |

- **What it adds:** the approach angle, the side he is on and how he evades are his. He can hold his ground with the left stick and still burst. The weave and the corkscrew answer the energy overhaul's rapid fire and mines with skill, not only a guard.
- **The rules:** one flick is one move, every move ends inside 16 ticks, and he can guard or dodge out of it after its first 6. Tricks cost 2 to 5 ki, and repeats lose their slip frames (R8).
- **The director composes around it:** the angle he arrives from is a term in the exchange's choice (from above, a slam is a candidate; from under, a lift), never forced. A cross-up gives the rival his turn by `fight-feel.md`'s turn rules. The debug feed names each trick.
- **Risks:** two movement inputs (and LT's dodge and boost) can feel like three ways to do one thing. Slip frames invite spam, which freshness answers. Each move takes the thumb off the face buttons, which is the price: move or hit.

## 4. Pitch B: the strike stick (attack)

**The idea:** a second way to attack, where the direction is the command: where the blow lands, or where the shot goes.

| Gesture | In reach | At range |
| :--- | :--- | :--- |
| **Flick** | A directional blow with a light's weight. **The direction picks where it lands:** up the head, down the legs, toward the body, and away a spinning back-blow that swaps sides with him. It counts in the string as a light, and its region goes to the wounds (`spec-wounds.md`) | An aimed bolt that way. Within 30° of him, it seeks him |
| **Hold** | Winds a directional heavy. Letting the stick back to centre throws it: hold to charge, release to fire, as the buttons do | Charges an aimed blast |
| **Zig-zag** | A flurry: each reversal is a blow, at most one every 6 ticks (the rapid fire) | A fanned scatter of shots |
| **Half-circle** | A sweeping ender: a knock-back along the arc's last direction | A shot that curves around his guard |
| **Circle** | The whirl: an ender that breaks a clinch and hits on every side | A ring of bolts around him |
| **Pump** | A double strike | A piercing shot |

- **Its blows never launch.** B with the left stick's nudge stays the launcher, so this is not the launch call Orb set aside. The stick picks where a blow lands, and the director still picks how it is staged.
- **What it adds:** called shots. Where blows land matters to wounds and broken limbs, and he can strike while the left stick moves him freely, backing away and hitting at once.
- **The director composes around it:** the region feeds the wound and the reaction, and the director keeps the blow's animation and the rival's answer.
- **Risks, and they are the largest:**
  - It doubles the face buttons. Two ways to do the brawl means the nine cells' balance has to hold for both.
  - Because of R1, it replaces the buttons in the moment rather than adding to them.
  - A charge read on the release waits for the stick to come back, which is slower than a button.
  - It is the closest of the four to the directional calls Orb set aside, and the most to learn.

## 5. Pitch C: the family stick (the hybrid)

**The idea:** the shoulder he already holds picks what the stick does, and the thumb draws. Each family follows what its shoulder already means: guard defends, energy shoots, power shows his style, and manoeuvre moves farther. The reads (§2) are the same in every family, so the gestures are learned once.

| Held | Family | Flick | Hold | Patterns |
| :--- | :--- | :--- | :--- | :--- |
| **Nothing** | **Flight** (pitch A) | A burst, or the lunge from range | The dash, the orbit, the wall run, the skim | The weave, the corkscrew, the vault, the backflip |
| **LB** | **Guard** | **A slip:** he sways off the line that way. Toward an incoming blow, it is today's deflect, aimed | **The guard's angle:** high, low or turned. It soaks blows from that side in full and leaks the others. Held toward a shot, it turns the shot back along the stick | Half-circle: **the roll-around counter,** around the blow to his back, leaving the rival open for 12 ticks. Circle: **the spin-off,** which breaks a clinch or an energy grab's catch. Pump toward: **the shove-off,** a guard push that makes space |
| **RB** | **Energy: fire on the move** | **An aimed bolt** where the stick points. Within 30° of him, it seeks him | **The aimed stream:** it fires along the stick while held. The left stick moves him and the right stick aims, which is Orb's "fire on the move" (control idea 10, wanted on 2026-10-05) | Circle: **a ring of bolts** around him, which sets off mines and meets a volley. Zig-zag: **a fanned scatter.** Pump toward: **a piercing bolt** that goes through bolts. Half-circle: **a curving shot** over a ridge or around his guard. Each fighter's own shapes are Combat's |
| **RT** | **Power: his style** | **An aura flare** that way: a short ki push that knocks small shots and debris aside, 1 bh | **Channel on the move:** he charges ki while drifting along the stick, at half the standing rate | **His own style moves,** two or three per fighter, Combat's and named by Narrative. Templates: a rising aura burst, a plated charge, a ground-splitting stamp |
| **LT** | **Manoeuvre** | **A zip that way,** the flight burst's long form, at the zip's price | The boost, steered by the right stick | The flight patterns at zip speed |

- **Under mask 3** (LB + RB, mines and traps), a flick sets where the next lay goes, up to 6 bh (`energy-overhaul.md` E71). It is a small extra, and the lay itself stays on the buttons.
- **During his own beam** (RB + B released), the thumb is free, so the right stick steers the beam's sweep. The trade is that it can't press pulses at the same time (R1): steer, or pump.
- **What it adds:** the most agency per thing learned. A shoulder he already holds for a reason gains a direction. It answers both of Orb's earlier wants: fire on the move (idea 10) and a hybrid that changes with what is held.
- **The director composes around it:** each family's gesture is an intent the director reads, such as the angle of arrival, the guard's angle or the aim. That is a term in the exchange's choice, the camera's framing and the rival's answer, and every one is listed in the debug feed.
- **Risks:**
  - The most to learn (four families) and the most input testing. The build order in §9 answers it.
  - Thumb fatigue from circles over a five-minute match. Patterns stay optional (R6), and holds do most of the work.
  - Misreads between flick and hold, and between a half-circle and a circle. R4 and R5 make every misread a smaller version of what was meant, never a different move.

## 6. Pitch D: style that pays (the skateboarding layer)

**The idea:** patterns drawn in the open, with no blow on him and no struggle running, are tricks, and a trick earns a little. It mixes with A or with C's flight family, and it is a layer, not a whole stick.

- **The payoff is small and subtle** (Orb's Q7, keep it subtle): varied tricks build his flow, a small ki gain and the timing bonuses' damage edge. Repeats earn less (freshness), and tricks linked within 20 ticks count as a line and earn more. There are no numbers on screen: his aura brightens, and the director's voice lines react.
- **A trick hit halfway is a bail:** he tumbles and is open, at Orb's "3 of 10" for a failed flashy option (questionnaire 19, Q11). It is the taunt's gamble (wanted, idea 7) widened into a vocabulary.
- **What it adds:** risk and reward in the lulls, personal expression, and a way to get ki back while the rival recovers.
- **Risks:** a grind of tricks for ki, which the small gain, freshness and the bail answer. Slower fights, which the gain only paying out for variety answers. It is flavour more than command.

## 7. Considered and set aside

- **The tactics stick.** A flick tells the director an intent (press, guard, evade, escape), and patterns call set pieces. It is today's optional stance radial and the launch call under another name, both of which Orb has set aside.
- **The depth stick.** Steering the fight's depth by hand. Orb chose emergent depth (homework 5).
- **The camera stick.** The camera is directed and eased (Orb, 2026-10-22). A free camera stays in replays.

## 8. Side by side

| | A: flight | B: strike | C: family | D: style |
| :--- | :--- | :--- | :--- | :--- |
| What it commands | Where he goes | Where blows and shots land | What his held stance does, by direction | Expression, for a little ki |
| New to learn | 3 reads, 5 patterns | 3 reads, 5 patterns, twice (reach and range) | 3 reads and 5 patterns, in 4 families | 5 patterns |
| Overlap with today | LT and the left stick | The face buttons | Little: each family extends its shoulder | The taunt |
| Orb's earlier calls | Clear of them | Closest to the launch call | Answers fire on the move (idea 10) | Widens the taunt (idea 7) |
| Phone and Simple | Swipes map well. On Simple the director performs it | Weak: it duplicates Attack | Swipes per family. On Simple the director picks the family | Swipes map well |
| Build (rough) | Medium | Large (balance twice) | Large, in steps | Small, on top of A or C |

## 9. The recommendation

**C, the family stick, built in three steps, with D held until Orb has played it.**
1. **Flight and Energy first,** with flicks and holds only. The burst, the dash, the orbit and the wall run, and the aimed bolt and the aimed stream. That is the biggest new agency for the least to learn, and it delivers fire on the move.
2. **The patterns for both, then Guard:** the weave, the corkscrew, the vault, the ring, the scatter, the curve, the slip, the guard's angle, the roll-around counter.
3. **Power's style moves per fighter** (Combat and Narrative), and then D's small payoff if Orb wants tricks to pay.

**Not B:** it doubles the buttons, the one thumb makes it a replacement rather than an extra, and it sits nearest the launch call Orb set aside. Its best idea, called shots on the wounds, could come later as Guard's or Power's pattern.

**The question for Orb**, for the EP to ask when it suits: "The right stick: the family stick, where the shoulder you hold picks what the stick does (recommended)? Or only the flight stick, or only the strike stick?" A second question, after Orb has played step 1: "Should tricks pay a little (D)?"

## 10. Reconciled with Controls' input side

Controls wrote the input side in parallel (`docs/controls/right-stick.md`, with a model of casual and practised thumbs). Where it differs from §1 to §9, this section rules. **The recommendation stands: C, in three steps,** and the input side makes B weaker still, since a four-way stick that is set and then let go is a poor attack stick.

- **R11. Flicks are four-way:** toward, away, up and down, relative to him. Eight ways read right only about 3 times in 4 for a casual thumb, and four ways about 99 times in 100. Eight directions and analogue belong to holds and aim, so §3's bursts are four-way, and a diagonal comes from a hold.
- **R12. The thresholds are Controls',** and they replace §2's first values: a dead zone of 0.25, hysteresis of 0.60 out and 0.35 back, a flick's rise within 3 ticks with its direction read 2 ticks after the crossing, a hold at 10 ticks, and a pattern committed about 5 ticks after the stick settles. All are data, with Controls' sensitivity options.
- **R13. Patterns are garnish.** A casual thumb gets them 45 to 72% of the time (zig-zags 46%, pumps 53%), and they commit too late for a reflex. **So whatever protects him belongs to the flicks and holds a pattern is made of** (R5), and the pattern adds its look and a small bonus. A step-flick slips shots for its first 4 ticks, so the weave's protection is its steps' own; the weave chains them faster and gives the flowing look. The corkscrew is a roll to look at, with no deflect of its own.
- **R14. A pattern never does damage, and a wrong match costs only a harmless command.** Patterns trigger movement, looks, guard shapes and style. So Power's style moves are flourishes (D's tricks), not attacks. Guard's half-circle counter and circle spin-off wait for the real-thumb capture (R20) before anything rides on them. Guard starts with the pump's shove-off (Controls' brace) as its only pattern.
- **R15. Patterns are off wherever the stick aims:** the Energy family and the lay (mask 3). A sloppy aim sweep fires a false pattern about 5 to 6% of a second. The Energy family's four pattern shots (the ring, the scatter, the piercing bolt and the curve) leave the stick. Combat may give any of them to a fighter's kit as a shape (`energy-overhaul.md` §14).
- **R16. Set, then let go: the energy aim latches.** The thumb can't hold the stick and press a face button at once. So in the Energy family a flick latches an aim line, and it stays.
  - **Toward** clears it: straight at him.
  - **Up or down** leads above or below him: a lead, or the ground under him.
  - **Away** aims behind himself: a shot down his trail, or a mine at his back.
  - **A hold** sweeps the line in analogue for fine aim, and letting go keeps it.

  The line is an angle off the line to him, so it follows him as both of them move. Within 30° of him a shot still seeks him (E7). It clears when RB is let go. X, Y and B fire along it, so "fire on the move" is the left stick moving him while the latched line aims what he throws. While his beam is out the thumb is free, and a hold sweeps the beam.
- **R17. One reading per family** (Controls' rule, so the thumb never has to guess). Flight, Guard, Manoeuvre and Power are **Step** (flick, hold, patterns on). Energy and the lay are **Aim** (a latched line, patterns off).
- **R18. Parity.** Every command has a keyboard form: the arrow keys on the solo keyboard, where patterns are exact key sequences, and single rebindable keys on the shared keyboards. It has a touch form: a gesture pad on phones, where drawing is natural. And it has a button equivalent on every device, as Orb's parity rule requires. On Simple, the director still performs it for the player.
- **R19. Intent version 5.** The stick needs a second packed word in the intent (Controls and Simulation). Step 1 can't ship without it. With the stick switched off, nothing changes.
- **R20. The capture comes first.** Before any pattern ships, Controls' real-thumb capture (Research or QA on real pads) measures the read rates again. Step 2's patterns wait for it.

**The families as they will be built** (this replaces §5's table for building; §5 stays as the pitch):

| Held | Reading | Flick (four-way) | Hold | Patterns (garnish) | Step |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Nothing** | Step | A step that way, slipping shots for its first 4 ticks. Toward him from beyond reach, the lunge | Drift or orbit around him, the cross-up, the wall run, the skim | Zig-zag: the weave. Half-circle: the vault. Circle: a flourish. Pump away: the backflip | 1 for flicks and holds, 2 for patterns |
| **LB** | Step | A slip. Toward an incoming blow, the aimed deflect | The guard's facing | Pump: the shove-off | 2 |
| **RB** | Aim | Latches the aim line | Sweeps the line, and his beam | Off | 1 |
| **LB + RB** | Aim | Sets where the next lay goes | E71's drift | Off | 1, with the lays |
| **RT** | Step | An aura flare: it pushes small shots and debris aside 1 bh, with no damage | Channel on the move | His style flourishes (D) | 3 |
| **LT** | Step | A burst of boost that way | The boost's direction, apart from the left stick | Circle: a roll | 2 |

## 11. Reconciled with Controls' §10, and step 1's command set

Controls' own §10 crossed with this page's §10. Where they differ, this section rules, and it replaces §2's reads and R10.

- **R21. A flick is read by how fast it starts:** from rest to 0.60 in 3 ticks or fewer. §2's "back inside the dead zone within 8 ticks" is dropped, since it would reject a flick that stays out, and a hold is its flick continued (R4).
- **R22. The pattern windows are the model's,** and they replace §2's:

| Pattern | Read |
| :--- | :--- |
| Pump | Two flicks the same way within 18 ticks. It commits at once |
| Zig-zag | Two reversals (three strokes) inside 48 ticks, each stroke at least 0.6 of the radius |
| Half-circle | 140° to 250° inside 36 ticks |
| Circle | 300° or more inside 48 ticks |

- **R23. The family is fixed at the first deflection** and held until the stick rests. A shoulder pressed or let go in the middle of a gesture doesn't change what that gesture does, and the next gesture reads the new family. A latched aim line still clears when RB is let go (R16): that is the line, not the gesture.
- **R24. R10 is replaced.** R3 keeps its job (Escape, today; the transform is LT + RT). Controls ignores an R3 click while the stick is past 0.9, or within 6 ticks of being there, so a hard flick never clicks by accident.
- **R25. Either stick sweeps a beam.** While his beam is out he is rooted (E48), so the left stick has nothing else to do and sweeps it on every layout, as E17 says. With the right stick on, its hold sweeps it too. If both are out of their dead zones, the right stick wins. A beam's sweep stays where a stick lets it go.
- **R26. Under an energy hold, the aim line points where the stick points,** on Controls' 32-way aim, with no turning rate, so the aim is as quick as the thumb. A beam is different: it turns toward the stick at his fighter's sweep rate (E48 and E81), because the sweep is the beam's own weight.
- **R27. The words:** a **pump** is a double flick the same way within 18 ticks. Up-and-down strokes are a **zig-zag** like any other, a vertical one.

**Step 1's command set, for Controls to fix thresholds.** Patterns are off in every family in step 1, and come in step 2 after the capture (R20). Directions are relative to him.

| Family (fixed at the first deflection) | Gesture | Command | Cost |
| :--- | :--- | :--- | :--- |
| **Nothing held: Flight (Step)** | Flick toward, from beyond reach | **The lunge:** he closes to reach | 10 ki |
| | Flick toward, in reach | A step in, 1 bh | Free |
| | Flick away | A step back, 2 bh in 8 ticks, slipping shots for its first 4 ticks | Free |
| | Flick up or down | A hop up or a drop down, 2 bh, slipping shots and the blow it clears for its first 4 ticks | Free |
| | Hold toward or away | **The dash,** the step continued while held | Free for 12 ticks, then the boost's 12 ki a second |
| | Hold up or down, in reach or the mid band | **The orbit:** he arcs over or under him at the same distance, facing him. Held through, it is the cross-up onto his other side | Free |
| | Hold into a wall, a cliff or a building's face | **The wall run** along it | Free |
| | Hold down near the ground | **The skim** along the surface | Free |
| | Release | Ends it, with a short settle | |
| **RB: Energy (Aim)** | Flick toward | Clears the aim line: straight at him | |
| | Flick up or down | Latches the line 45° above or below him: a lead, or the ground under him. That is outside the 30° in which shots seek, so they fly straight | |
| | Flick away | Latches the line behind himself | |
| | Hold | Sweeps the line in analogue, latched where it is let go | |
| | Hold while his beam is out | Sweeps the beam (R25) | |
| **LB + RB: the lay (Aim)** | Flick | Sets where the next lay goes: up to 3 bh that way (E71) | |
| | Hold | Points the way a held lay drifts (E71) | |
| **LB, RT or LT held** | Any | Nothing in step 1. Guard and Manoeuvre come in step 2, and Power in step 3 | |

Repeats follow R8: the third step or hop inside 3 s keeps its movement and loses its slip frames.

## 12. Step 1 against today's director (Encounter's notes)

Encounter read step 1 against the director (`docs/director/right-stick-step1-notes.md`): no inputs clash, and six meanings overlap. Each is ruled here, and where it differs from §11's table, this section rules.

| # | The overlap | The ruling |
| :--- | :--- | :--- |
| 1 | **The lunge.** An attack press from the mid band already lunges with its blow | **The press wins.** If both arrive in one tick, the press's lunge runs, and the flick is spent into it at no ki. **The stick's lunge reuses the press's rush** (`DirBands.begin`) with no blow at its end: the mid band's rush from the mid band, and the far charge's approach from the far band, each for 10 ki. He arrives in reach free and even, with no first move: he can guard, grab or press. The ki is the price of arriving uncommitted, between the free press lunge (with a blow he is committed to) and the zip strike (20 ki, quicker, with a blow) |
| 2 | **Steps inside a brawl** | **Inside a brawl, a stick step is a director rush,** as the recoil flip is, so the brawl's pull rests for it. **A step back is giving ground: one move, not two.** A flick away gives ground by up to `give.leashBh` in one rush. A flick toward takes the ground back at once, to striking distance. If he has given none, nothing happens. Outside a brawl, steps are free movement, as §11 has them |
| 3 | **Slip frames** against today's dodge | **A stick step is never a dodge.** Its slip is a flag of its own, for shots only, for its first 4 ticks. It never sets stance 2, no exchange template reads it, and it never fires the recoil flip or the pop's tech. **Hops and drops slip shots only:** "and the blow it clears" is withdrawn from §11. Against blows, LT's dodge tap stays the one dodge |
| 4 | **The dash on a hold away** | **Movement only.** It never sets `sprint` and is never the Escape stance, which keeps its own input (R24), its pursuit templates and its rules. Outside a brawl, it is free flight at the dash's speed. Inside a brawl, holding away gives ground to the leash and holds it there while held, with the pull resting. It never parts the brawl: parting is Escape's, or a knock-back's |
| 5 | **The orbit and the cross-up inside a brawl** | **The brawl learns a side swap.** Outside a brawl the orbit is free flight. Inside one, a hold up or down is the cross-up: a director rush of 16 ticks in which he arcs over or under the rival and lands on his other side, and the brawl goes on with the sides swapped. While he arcs he can't strike, and he has no slip. **A blow that lands on him in the arc lands clean** and leaves him where he was hit. It is the fighting-game cross-up, which needs the brawl. Parting the brawl instead would lose it |
| 6 | **The skim against a dive** | **Confirmed: the skim.** Over water, a hold down near the surface skims along it. The stick never takes him under, since the base game has no hiding (`rulings-2026-10-23b.md` row 13). A dive to hide is designed with a future fighter who can hide (`canHide`), and not before |

**Two small fits, confirmed.**
- **When beams lock in a struggle,** the aim line and either stick's beam sweep stop. The struggle's own rules hold, as built: the left stick leans him in, and up or down aims the overwhelm (`rule-of-cool.md`).
- **R8's repeat count is per fighter and per kind:** two director slots, one for steps and one for hops and drops.

## 13. Step 1, reworked for one thumb (Orb's claw-grip concern)

**Orb** (homework, 2026-10-25): "the thumb that is normally pressing attack buttons is occupied by the right stick. if there is too great a synergy between these two systems that are both occupying the right thumb, then my concern is that some kind of 'claw grip' becomes necessary to compete." Controls answered with the law (`docs/controls/right-thumb.md`). This section adopts it and redraws step 1 to fit it. Where it differs from §11 and §12, it rules.

**For Orb, in short.**
- The right stick never asks the thumb to be in two places at once. It **sets things that stay set:** where you aim, how you move between exchanges, and what you expect your opponent to do. Then the thumb goes back to the buttons with no hurry.
- **Quick defence moves to the left hand.** The dodge trigger picks its direction from the left stick.
- **A claw grip, back paddles or a keyboard can be more comfortable, but never faster.** A test in the build fails if one ever wins.

### 13.1 The law, adopted

- **R28. No pairing in a beat.** No command needs the right stick and a face button inside one window. A stick input never changes a beat that is already running: a blow in flight, a wind-up, a rush. Every right-stick command is one of four kinds:
  - **a step** in neutral;
  - **a rush,** which is a director rush and its own beat;
  - **an aim,** which is latched;
  - **a read,** which persists.
- **R29. Gap-invariance.** Whatever the stick sets lasts at least `W` = 36 ticks. A face button that meets it gives the same result for every gap from 0 to `W`. The stick sets a state, the button acts on it, and only the button's own timing says when the blow starts.
- **R30. Commitment.** Every stick command commits the fighter for `L` = 6 ticks, the fast standard thumb's own transfer (Controls' model, until the capture measures it). A stick hold's release locks out `L` too, and **§11's "short settle" becomes `L`.** A face press made inside the commitment or during a hold **queues** on the existing request queue, and starts at its end. So a claw's early press and a standard thumb's later press start on the same tick.
- **R31. The step carries the blow.** A press queued behind a step is staged as one move: the step's last 6 ticks flow into the blow, a step-strike, so the 6-tick start reads as intent and never as lag (Encounter and Animation).
- **R32. Mirrors at the same cost.** Every stick command has a form on the D-pad (the pad's mirror, reachable by the left thumb), a key and a swipe. Each costs the same ki, commits the same `L` and starts no later than the stick form.
- **R33. No device detection, ever.** The rules live in the sim, so a keyboard, a claw and paddles are all held to them, and nothing tries to tell one grip from another.

### 13.2 Quick defence on the left hand

- **R34. The slip is LT's dodge with the left stick's direction.** LT's tap stays **the one dodge against blows** (§12 ruling 3). At the tap's edge, the left stick's direction picks how he slips:

| Left stick at the tap | The slip | What the exchange reads |
| :--- | :--- | :--- |
| Neutral | Today's dodge | The dodge, as now |
| Away | A slip back off the line | Dodge and read |
| Toward | A slip in, past the blow to his side | Dodge and counter |
| Up | A sway up, over a low blow | The dodge, cleared over |
| Down | A duck under a high blow | The dodge, cleared under |

  It is the same dodge in every case (stance 2, read by the exchange templates), with a direction added. The recoil flip and the pop's tech stay LT's in their own moments, and use the direction as the flip's. **No right-stick input is ever part of a reactive defence.**
- **R35. The guard keeps its own lean** on the left stick (`nudge.guard`), as today. §5's guard family on the right stick (the slip, the guard's angle, the counters) is retired: the left hand does reactive defence, and the right stick's guard job is the read (§13.3).

### 13.3 The read: fluid slips without timing

Orb asked for fluid slips. Fast slips belong to the left hand (R34). **The right stick offers the other kind: a read, a guess about his next move that you set ahead of time and the director plays out.** It is pillar 2, the stance that chooses intent, back in a modern form.

- **R36. With LB held, a right-stick flick sets a read.** It lasts until it fires or for 90 ticks, whichever comes first, and only one is set at a time: a new flick replaces it. It costs 3 ki to set. It applies only to his attacks that **start after** it is set, so a read is a prediction and never a reaction.

| Flick | The read | When he does it, the director plays |
| :--- | :--- | :--- |
| Up | **His heavy** (a heavy or a charged blow) | A slip under it at the contact, and he is open: a stagger, which is a plain opening. A perfect block stays the bigger reward (a reversal, which dazes, `rulings-2026-10-23d.md`) |
| Down | **His flurry** | The flurry's first blow is slipped by a duck, and his run is broken |
| Toward | **His grab** (the clinch, the tackle, the energy grab) | The catch is broken as it closes, both are pushed apart, and the grab lockout runs for him |
| Away | **His shot** | A sidestep with slip frames for that shot |

- **R37. A read can be seen.** His stance shifts with it, a small lean or a hand set, so the rival can read the read and throw something else. A read that doesn't fire costs its 3 ki and nothing more: a wrong guess is a small loss. That follows Orb's "3 of 10" for a failed flashy option.
- **R38. Mirrors:** LB with the D-pad, the guard key with the arrows, or the guard with a swipe. **On Simple,** the director sets reads for the player at a modest rate, as it throws the pairs.

### 13.4 Step 1, redrawn

Every command, with its kind, how long what it sets lasts, and its commitment. Patterns stay in step 2. Directions are relative to him.

| Family | Command | Kind | How long it lasts | Commitment |
| :--- | :--- | :--- | :--- | :--- |
| **Nothing held** | Flick toward from beyond reach: **the lunge** (10 ki) | Rush | The rush. A press in the same tick wins (§12 ruling 1) | The rush's length |
| | Flick toward in reach: **a step in,** taking back ground given | Step, or a rush in a brawl | | `L` |
| | Flick away: **a step back,** which in a brawl is giving ground | Step, or a rush in a brawl | Shot slip for its first 4 ticks | `L` |
| | Flick up or down: **a hop or a drop** | Step | Shot slip for its first 4 ticks | `L` |
| | Hold toward or away: **the dash** | Hold | While held | Release + `L` |
| | Hold up or down: **the orbit,** and in a brawl **the cross-up** (§12 ruling 5) | Hold, or a 16-tick rush in a brawl | While held | Release + `L`, or the rush |
| | Hold into a face: **the wall run.** Hold down near the ground: **the skim** | Hold | While held | Release + `L` |
| **RB** | Flick: **latch the aim line** (toward clears it, up or down 45°, away behind) | Aim | Until RB is let go | `L` |
| | Hold: **sweep the line** (32-way, direct) | Aim | Latched where it is let go | Release + `L` |
| | Hold while his beam is out: **sweep the beam** | Aim | While held | None: he is rooted and both thumbs are free |
| **LB + RB** | Flick: **where the next lay goes** (up to 3 bh) | Aim | Until the lay, or a shoulder is let go | `L` |
| **LB** | Flick: **a read** (§13.3) | Read | Until it fires, or 90 ticks | `L` |
| **LT, RT** | Nothing in step 1 | | | |

- **The D-pad mirrors every row.** Flicks are D-pad taps, holds are D-pad holds, and analogue sweeps are the D-pad's 8 ways, stepped.
- **Repeats** follow R8 per kind (§12): the third step or hop inside 3 s keeps its movement and loses its slip.

### 13.5 Does any command need a beat-timed stick input?

**None,** as Controls thought. Every timed input in the game is a button:
- the struggle's surges (X, Y or B on the pulse, A to let go);
- the perfect block (LB);
- the wall kick and the bank (LT);
- the recoil flip and the tech (LT);
- the rally's air tech (a guard press, `rulings-2026-10-23d.md`);
- the escape from a catch (presses).

The stick leans and aims in all of them, untimed. Patterns in step 2 are states built from flicks, each under R30, and nothing waits on a beat. **So step 1 can ship with the claw-bot gate green on every row.**
