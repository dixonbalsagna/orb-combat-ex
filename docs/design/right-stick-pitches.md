# The right stick: pitches for Orb

Owner: Game Design. Status: **pitches, 2026-10-23.** Paper only. Every number is a first value, and Controls is writing the input side (`docs/controls/right-stick.md`). Orb can pick one pitch or mix them, and §9 recommends one.

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
