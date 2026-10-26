# The right thumb: no grip beats the standard grip (paper)

Controls, 2026-10-25, for Orb's concern (`docs/ep/vision.md`, "Orb's homework answers of 2026-10-25": the right stick could give fluid slips, strikes and dodges, but the thumb that presses the attack buttons is on the stick, so "some kind of claw grip becomes necessary to compete"). Game Design rules the game side after this. **Paper only.** Every timing below that is a thumb's is **modelled from the pad's geometry and is an assumption until the capture tool measures it** (section 3).

## 1. The answer in short

A claw (or back paddles, or a keyboard) wins only where a command's payoff depends on a stick input and a face button arriving close together. So the fix is not to ban the stick from the fight; it is **to make every stick-and-button pair give the same result whatever the gap between them**, and to make every stick command **commit for at least as long as the fastest standard thumb needs to move**. Do that and a claw is only more comfortable, never faster. Concretely, adopt directions **(1), (2), (3) and (5)** as one design, and leave **(4)** out for now:

- **The law (1):** four testable rules, with a "claw bot" gate that fails the build if a zero-transfer player ever out-performs a standard-transfer one (section 4).
- **Reactive defence on the left hand (2):** LT's dodge tap stays the one dodge against blows, and LT or LB plus the **left** stick's direction picks the slip. Standard grip, no conflict. Game Design's step-1 ruling 3 already puts blow defence on LT.
- **The right stick as set-and-release reads (3):** a flick sets something that persists (an aim line, a read, a step in neutral) and the thumb goes back to the buttons. Gap-invariant by construction, and GD's latched aim line (R16) is already one.
- **Mirrors (5):** every stick command also has a button-and-left-stick form with the same cost and **the same tick** as the stick's (GD ruled exact parity, 2026-10-26: a faster mirror is a device advantage), which is also the keyboard, touch and accessibility form.

## 2. Where the advantage actually lives

A claw's edge is the **transfer time T**: the time a standard thumb needs to go from a face button to the stick (or back). With the stick near the face buttons that is roughly 5 to 13 ticks (80 to 220 ms). A claw player has T near 0. So a claw wins in three situations only:

| Situation | Why a claw wins it | The fix |
| :--- | :--- | :--- |
| **Simultaneous pairs** | a command that needs stick and button together (a slip then a counter inside one beat) can be done by a claw and not by a standard thumb | no command is defined that way (rule 1, 2) |
| **Chaining** | a claw issues stick, button, stick, button in less time than a standard thumb can | every stick command **commits** for at least the fast standard thumb's transfer (rule 3) |
| **Holding** | a stick **hold** (the dash, the orbit) keeps the standard thumb off the buttons; a claw presses through it | a press made during a hold waits for its release plus a lockout (rule 3) |

Keyboards and touch are the same problem in a different shape: a keyboard has separate fingers for arrows and attack keys, so it is a permanent claw. **Because the rules live in the sim and not in a device, they equalise keyboards too.**

## 3. The thumb's transfer time (model; the capture tool measures it)

Fitts-style estimate for a thumb moving between a face button and the right stick's top, using the common pad geometries (centre-to-centre distance 3 to 4.5 cm, targets 1.2 and 1.8 cm), with a settle time; **assumed, ticks at 60 a second**:

| Standard-grip transfer, stick to button | p10 (fast) | p50 | p90 (slow) |
| :--- | ---: | ---: | ---: |
| Xbox or Switch Pro layout | 5 | 8 | 12 |
| DualSense (the stick is farther) | 6 | 9 | 13 |
| Steam Deck | 5 | 8 | 12 |
| **Used below** | **6 ticks (100 ms)** | **8 ticks** | **13 ticks (217 ms)** |

Button to stick (the thumb arrives at the stick and crosses the flick threshold) is similar: **p10 6 ticks to the stick's onset**, p50 8, p90 13; a round trip is about 16 ticks at the median. **Three numbers do the work:**

- **The lockout `L` = p10 = 6 ticks.** A stick command's commitment, and the wait after a stick hold. Set at the *fast* end of the standard grip, so a claw gains nothing over the fastest standard thumb (and a slower standard thumb is only ever later than the lockout, never held back).
- **The reverse lockout `R` = button-to-stick onset p10 + the flick's settle = 6 + 2 = 8 ticks** (data `rightThumb.reverseLockout`). It is longer than `L` because the stick reads its direction **2 ticks after it crosses** (`flickSettle`): the fastest standard thumb reaches the stick and crosses at press + 6 and its flick therefore acts at press + 8, while a claw thumb already on the stick would have its flick settled and acting at press + 6. At `R = 8` both act on tick press + 8. (This corrects the first version of ruling 16's number: the wait is 8, not 6; the flick still acts on the tick its wait ends, with no extra tick.)
- **The window `W` = p90 plus margin = 36 ticks.** How long a stick-set state persists for a button to meet it. Long enough that a slow standard thumb is never punished, and (with rule 2) the result is the same wherever in the window the button arrives.

The capture page (Tools, `tools/capture/right-stick.html`) needs one more block to replace the assumption: **"transfer"**: press a face button, flick the stick up, press the face button again, 10 times per face button, per pad and per grip (standard, and claw or paddles for comparison). It records button-up to stick-onset and stick-return to button-down, per person, so `L`, `R` and `W` are read from real thumbs, standard and claw: `L` from stick-return to button-down (p10), and `R` from button-up to stick-onset (p10) plus the 2-tick settle.

## 4. The law, as four testable rules

1. **No pairing in a beat.** No command needs a right-stick input and a face button inside the same window. A stick input never changes a beat that is already running (a blow in flight, a wind-up). Right-stick commands act in neutral, in Aim (latched), or as a director rush that is its own beat.
2. **Gap-invariance.** For any stick command followed by a face button within `W`, the **result** (what the pair makes) is identical for every gap from 0 to `W`. The stick sets a state and the button acts on it; only the button's own timing says when the blow starts.
3. **Commitment and lockout, symmetric** (GD's rulings 13 to 16 of 2026-10-26). Every stick command commits the fighter for at least `L` ticks, **and a face press commits the stick for `L` in the same way**: without that, a claw alternating press and stick gains `L` ticks a step. A face press made during a stick commitment, or during a stick hold, **queues** (the existing 3-deep, 36-tick request queue) and **starts at the commitment's end, or at the hold's release plus `L`**. A stick input made during a face press's commitment **waits** and **acts on the tick the wait ends**, exactly as a queued press does (no extra tick). **The reverse commitment is longer than the forward one: `R = L_b + settle = 8` ticks** (below): a face press commits the stick until tick `press + 8`, so a stick input at gap `g` acts at `max(g + 2, 8)` after the press. A claw's early input and a standard thumb's later input take effect on the same tick.
   - **The newest input wins, and nothing is silent.** At most one stick command waits: a later face press, or a later flick, replaces it, and the dropped one gets a **lapsed ack** (a flicker in the hand), as a swallowed press does (`energy-overhaul.md` E3).
4. **Mirror parity: the same tick.** Every stick command has a button-and-left-stick form (or the D-pad, a key, a swipe) with the same ki, the same commitment and **the same tick** as the stick form's. The stick's flick waits 2 ticks after it crosses to settle its direction, so **the D-pad's command waits the same 2 ticks**: neither form is ever faster.

**The gate (a "claw bot").** A pure-input test, written once Game Design fixes the command list: scripted intents drive the same command pairs with a transfer of 0 (claw) and with `L` (standard fast), over every pair and gap in `0..W`, and assert **the same outcome (state hash on the pair's effect, blow kind, damage, ki) on the same tick**; plus a mirror check (stick form against button form) and an AI-against-AI fight in which one side uses claw timing, which must not win more than a seeded fair-coin margin. It fails the build.

## 5. The five directions, scored

Score: claw advantage (zero is the bar), fluidity, misreads, learnability, touch and keyboard parity, and Orb's rules (control first, press feel, no right-stick launch calls).

| | Claw advantage | Fluidity | Misreads | Learnability | Touch and keyboard | Orb's rules | Verdict |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **(1) The law** | **zero by construction** and testable | neutral: a lockout of 6 ticks is below a standard thumb's own transfer | none | invisible to the player | applies to every device | clean | **Adopt; it is the base** |
| **(2) Defence on the left** (LT tap, LT or LB plus the left stick's direction) | zero: the standard grip already does it | high: the slip is a trigger tap and a lean, no thumb travel | the left stick is also movement, so direction is read only at the dodge edge | high: one dodge | keyboard (Space plus WASD), touch (flick, already the dodge) | clean | **Adopt; the main reactive defence** (the dodge-cancel in a brawl already reads the stick away) |
| **(3) Reads** (a flick sets a read that persists and fires when the rival attacks into it) | zero if `W >= 36` and the read acts on the rival's attack, not on a press | high: the fighter flows by itself (Orb's "fluid slips") | four-way flicks read 99%; a stale read must expire and cost ki | medium: "lean, then forget" | arrow tap, swipe | fits pillar 2; nothing beat-timed | **Adopt; GD's latched aim line is its first case** |
| **(4) Stick-strike with a held trigger** | zero only if the buttons are inert in the mode (else a claw mixes both) | high for a boxing-game player | direction as the blow: 4-way fine, 8-way not | a whole second language | strikes by swipe or arrow | the **press-feel rule** says each press is a blow and GD set this pitch aside; no trigger is free (LB, RB, RT, LT are stances) | **Not now.** If Orb wants it later, in a hybrid stance only, with the buttons inert in it |
| **(5) Mirrors** | zero: the claw can only be more comfortable | neutral | none | medium: two ways | this IS the keyboard, touch and accessibility form | clean | **Adopt as rule 4** |

**Added by me.**
6. **Commitment as the equaliser (rule 3).** The queue already exists; a claw's press and a standard thumb's later press start on the same tick. This is the part that turns "the thumb is busy" into "the thumb is never penalised".
7. **No device detection, ever.** Nothing in the game tries to tell a claw from a standard grip; the rules are device-agnostic, so there is nothing to evade and nothing unfair to accuse a player of.
8. **D-pad as the pad's mirror for the stick's neutral-time commands** (aim presets, steps): the left thumb can reach it while the right thumb stays on the buttons; this is rule 4's pad form for aim and steps, acting on the same tick as the stick's.

## 6. What this changes in Game Design's step 1

| Step-1 item | Under the law |
| :--- | :--- |
| Flight flicks (step in, step back, hop, drop, lunge) | **commit `L = 6` ticks** (a press queues and starts after); the lunge and the cross-up are already director rushes of their own length |
| Flight holds (dash, orbit, wall run, skim) | the release has a lockout `L`; presses made during the hold queue; **GD's "short settle" becomes `L`** |
| Energy aim (a latched line) | already gap-invariant; keep it latched until RB is let go; **the D-pad is its pad mirror** |
| Lay aim (a flick sets where the lay goes, up to 3 bh) | latched, read when the lay lands; gap-invariant |
| Slip frames from a step (shots only) | unchanged; **blow defence is LT only** (ruling 3). The left-stick direction at LT's dodge picks the slip side |
| Patterns (step 2) | each stroke is a flick; completion is a state; nothing beat-timed |
| Beam sweep by either stick | both thumbs are free during a beam (he is rooted); no pairing |

## 7. What it costs, and risks

- **A stick input just after a face press now waits too** (the reverse commitment, rule 3): a flick made within `R = 8` ticks of a press acts at press + 8. A standard thumb that moves to the stick is not held back (its flick onset is at press + 6 at the fastest, and it settles 2 ticks later, so it acts at press + 8 anyway); only a claw, whose flick would otherwise act at press + 6, waits the extra 2.
- **Latency for a fast standard thumb is zero** (lockout at their p10); for a claw it removes an advantage, which is the point. A player who mashes a face button right after a flick sees the blow start 6 ticks after the flick, not at once: **visible, and it must be explained by the director's choreography** (the step's own animation) so it does not read as lag.
- **The transfer numbers are assumptions.** If real thumbs are faster than the model, `L` rises; if slower, `W` rises. The capture block decides before any command ships.
- **A "read" that fires automatically can feel like the game plays for you.** Costs (ki), expiry and a cap of one read at a time keep it a choice; this is Game Design's to tune.
- **Device-agnostic rules also cap a keyboard player's natural speed.** That is intended: it is how a keyboard and a pad stay equal (Orb's rule).

## 8. For the other directors

- **Game Design:** fix the command list with each stick command as a read, a neutral-time step or an Aim state; set each commitment at `L` and each persistence at `W`; draw the left-hand slip (LT or LB plus the left stick's direction); say which, if any, commands truly need a beat-timed stick input (I think none).
- **Encounter:** the post-hold lockout and the stick-command commitment on the existing request queue; the left-stick-direction slip at the dodge edge.
- **Controls (me):** the claw-bot gate and the mirror forms once the commands are fixed; the D-pad mirror.
- **Tools:** the capture page's "transfer" block.
- **QA:** run the transfer block with standard-grip and claw players on at least four pads.
