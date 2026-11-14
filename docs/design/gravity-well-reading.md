# The gravity well: Game Design's reading

Owner: Game Design. 2026-11-08, on the stand-in's packet (`docs/ep/proposals/gravity-well.html`, committed) and Orb's order of 21:52 (`docs/ep/vision.md`). **The packet's diagnosis holds.** Its plan fits the rulings, and its rules for control are the right shape. Below: Orb's question 2, the seven calls the packet asks of me, and the numbers that make it true. First values, as data.

## Orb's question 2: should your stick move just your own fighter, and can you walk away alone?

**I support it. Put it to Orb with this shape: yes to your stick moving just you, and yes to leaving alone, at a walk.**

| | Today (Orb's 10-06 rule) | Proposed |
| :--- | :--- | :--- |
| **The left stick in a brawl** | Moves the pair's centre at 0.4 of flight speed, carrying the rival along | **Moves your own fighter, at your own walking speed.** The brawl's magnet keeps him at striking distance only within Rule 2's cap (a quarter of flight speed), and **never against his held stick.** If you both push the same way the brawl moves; if you oppose, it's a tug and nobody wades |
| **Walking out** | Only when both sticks push apart; alone you pay the escape's 15 ki | **Alone, at a walk, for no energy.** You back out at your walking speed with his draw on you. **His blows still land while you're in reach,** so leaving mid-string costs you the hits you take on the way out, and he can follow flat out with LT. **The escape** (LT + away, 15 ki) **stays the fast, safe exit** |

- **Why:** in Orb's Sunday match, there were 32 brawl starts, and among their endings one paid exit ("left") and one idle ending, with no free walk-outs (corrected 2026-11-14 from "27 brawls, 0 walk-outs"; `docs/qa/runs/1931a0f8/`), and "we weren't in control of our fighter". Moving both bodies at 0.4 makes every step feel like wading. Your stick should move you.
- **What it keeps:** the magnet, because brawls still hold together while both want them to, and a pressing player can't be walked away from for nothing. Leaving costs **exposure, not a cap:** soft costs over caps, and pillar 3's gamble, since he can chase.
- **What it changes:** `brawl-second-pass.md` §1 (the centre) and my withdrawn one-sided walk-out. Both are reversed only if Orb says yes.
- **QA's rows:** brawl press-to-motion at most 2 ticks; walk-outs a match 1 to 4 with a human; the leaver takes at least one blow on the way out in at least half of walk-outs against a pressing rival, so leaving is never free of risk.

## The seven calls

| # | The packet asks | Ruling |
| ---: | :--- | :--- |
| 1 | **The first values** | **Accepted, with two changes:** <br>- the edge pulse comes **at most once every 2 s** a pair, so a fight on an edge doesn't buzz; <br>- **the snap flies at flat out for his level,** the same as LT, and keeps the cell's own contact timing once there. <br>Everything else stands: well 12.5 bh, edge 3 bh, tier step 0.1, heft exponent 0.5, charge +25%, cap 20 bh, floor 4.5 bh, draw cap 0.25 of flight speed, half draw on a leaver. Numbers below |
| 2 | **The LT option** (×1.35 and full by tick 6 inside a well) | **Build it behind its switch, off.** Ruling (c) fixes the cause Orb named. Orb plays (c) first, and tries the option only if close-range LT still feels slow. It also turns on the kick's overspeed, which Orb asked to keep off |
| 3 | **Flight strikes' fixed time** (10 to 18 ticks at any gap) | **Leave the time.** The tell is the move's identity and the counter's read. Up close the brawl's 2-tick lights are the fast option. **One change: the tell no longer zeroes his velocity.** A fighter sprinting into a flight strike carries his speed through the tell, toward the target, and the path starts where the tell ends. "Stops dead" is exactly the loss of control Orb felt. The 4-tick travel floor stays, as a rule of readability (formerly RL-076, now the creative rulebook's) |
| 4 | **A cap on held presses,** once increment 0 has measured | **The rule now, the number after measuring:** a held press waits **for the blow in hand plus 20 ticks** (the face queue's 20), so one behind his own B's 28-tick wind-up waits up to 48. Past that, it's refused with a word. **Held flicks keep their own rule** (90 ticks through stuns and his planned exchanges, 20 after a knock-back; `gauntlet-plan.md` §5). The 600-tick backstop goes. If increment 0 shows deliberate presses waiting longer than this, Encounter brings me the rows |
| 5 | **Close presses against stance 2 or 3** | **Yes: they're brawl blows.** The defender's stance shapes the brawl's answer: defensive guards more, evasive slips and gives ground inside the brawl. **It's never a locked set piece.** A set piece comes only from a press of the defender's own (a parry, a dodge he pressed) or from one the attacker chose. That's the "Locked" at the top of Orb's ledger, gone |
| 6 | **X and Y in a held sprint** | **They stay the band's press.** Past the take-back's 4 ticks, a face press is its own blow (ruled). Inside his well it snaps in, and outside it's the far tap (a taunt, or a charge on a hold). **B or a flick at flat out is the long strike** (row 3) |
| 7 | **The defender's stick in a rival's set piece,** outside hit-stop | **Live, except where he's held.** He moves at his own speed: that's how he gets out of a flight strike's path. **Not live** while he's held (a grapple's catch, where his stick feeds the tech instead), in a finisher, or in a knock-back or launch, where the air brake is his control |

## The numbers that make it true

| | Value | How it relates |
| :--- | :--- | :--- |
| **Well radius** | `12.5 bh × √(heft/100) × (1 + 0.1 × (tier − 1)) × (1 + 0.25 × charge)`, held between **4.5 and 20 bh** | 12.5 bh (about 940 units) is today's middle band's edge. 4.5 is the brawl's `breakBh`. 20 bh (1,500) is today's `BOOST_NEAR`, which closes the dead zone between 12.5 and 20 |
| **Edge band** | 3 bh past his well | A tap snaps, a hold charges, and flat out + B or a flick is the long strike |
| **The draw** | At most **0.25 of free flight speed** (about 107 a second at base), falling off toward the edge (about 43 at 10 bh). Half on a fighter holding away. **Never against a held stick** past the cap | Gentle on purpose. What you see "drawn together" is the snap |
| **The magnet** (the brawl, within 4.5 bh) | Holds striking distance at up to 0.5 bh a second (as today), now **inside Rule 2's cap** and never against a held stick. With question 2 yes, it holds you to him; it doesn't drive him | Brawls stay magnetic. The stick still wins |
| **The snap** | The attacker flies in **flat out for his level** (5,000 a second at base, 11,525 at maximum), then the cell's contact tick. The defender is drawn to meet it only within the draw's cap, and not at all while he holds away or guards | Today's middle-band lunge is 4,000. The snap matches LT, so pressing in and flying in feel like one speed |
| **Flight strikes** | **Range: to the edge of the defender's well** (12.5 bh at base, up to 20), **not a fixed 12.5.** The distance price rises from 3 bh to that edge | Inside his well, LT + a face button is the flight strike. Outside it, flat out + B or a flick is the long strike. No dead band between them |
| **The stick** | A full hold sends anywhere (`slam-and-pace.md`). A quick flick inside his well snaps in and lands as a light (the range flick's 8.6). In the brawl it's the stick's own medium (21.4) | As ruled. The well only decides whether the flick snaps |
| **LT** | Flat out at any range, ruling (c). The packet's model meets it: 0.25, 0.65 and 1.25 s from 1,000, 3,000 and 6,000 | The option (call 2) stays off |
| **`apartReach`** (4,000 units, `swing.json`) | **Unchanged and unrelated.** It's the camera's two-fights-on-one-line rest. A well (at most 1,500) always sits inside it | In 2v2, wells are read per rival (the deepest one), draws sum under one cap, and teammates don't draw each other |

## Orb's other two questions, my view for the EP

- **Question 3, a transformed well pulling an untransformed fighter into snap range:** **support.** It's the rule of cool: the big one's presence reaches further. The small one isn't carried, only able to snap in from further off. The big one keeps the long game.
- **Question 4, showing the well in the world:** **not first.** The edge pulse and sound go first. If Orb's play says the edge is an invisible cliff (the packet's one open risk), VFX tries dust drawn along the ground toward a big well, never on fighters, behind the look gate.

## What can run tonight

- **Increment 0 (measure), increment 1 (LT, ruling (c)) and increment 2 (control):** yes, with calls 3, 4 and 5 above folded into increment 2.
- **The own-body stick and the lone walk-out** wait for Orb's yes on question 2. They ride behind their own switch in increment 2, so the answer only turns them on.

## Spike S2's five rulings (2026-11-14, on the stand-in's `docs/ep/proposals/gravity-well-trial-design.html` §2)

Orb's standing words govern all five: "KEEP WORKSHOPPING, PLAYER AGENCY MUST BE RESPECTED".

| # | The trial proposes | Ruling | Reason |
| ---: | :--- | :--- | :--- |
| 1 | **The snap flies at the faster of today's lunge (4,000) and flat out for the level** | **Yes.** It replaces call 1's "flat out for his level" | A snap must never be slower than the lunge it replaces. At tier 1 it's exactly today's lunge, so nothing changes in feel at base, and it rises with tier (about 4,640, 6,090 and 8,070), so power has weight. The 3 bh a tick ceiling stays |
| 2 | **The draw acts only in silence:** stick at rest, hands off, and never after a knock-back until the fighter's own next input | **Yes, as the default and my recommendation.** My capped draw stays as the trial's comparison arm, and the trial carries both | A draw that acts while you hold the stick, however gentle, is a force you didn't choose. That's Orb's "weren't in control" and "confused as to why their character just started turning on their own". In silence it can never fight the player. The knock-back clause is Orb's own 10-05 answer: the re-close is always a player's move |
| 3 | **Walking out alone against a pressing rival:** clear on the third blow that reaches a fighter holding away | **Yes, 3 as a first value.** Blows landed or guarded count. **A stun or stagger pauses the walk without resetting the count,** and letting go of away resets it | That's "exposure, not a cap" with a number: the leaver pays in hits, and lights can never hold someone who wants out forever (Orb, 10-02: a way out of any situation at some risk). "One stun a string" already stops a stick player from pinning him with stuns. **Lever:** 2 or 4, on QA's rows and Orb's feel. The energy-paid escape stays the fast, clean exit |
| 4 | **Bodies are solid in the new mode:** walking into the rival stops you, and nobody's stick moves the other player | **Yes** | "Nobody's stick moves the other player" is the agency rule in plain form. Shoving with your stick would be the old centre-nudge coming back another way. **Pressing the fight into the city** (Orb, 11-06) stays the job of blows: each blow steps its thrower in, the stick's strikes carry 1 to 4 bh, and there's the wall push. Not leaning |
| 5 | **A swollen well only helps the rival reach you; `chargeGrow` can be 0** | **Keep 0.25 for the trial, with 0 as the lever** | It's the dare Orb read ("power up at your peril" inside a well), and it matches Orb's picture that charges belong outside the well: charging close in needs more distance. The edge moves only when a charge starts or stops, so it can be seen. **A beam's gather has its own armour against lights,** so the dare mostly bites the plain power-up. **QA reads** charges started a minute and the share interrupted. If charging falls below half today's rate, `chargeGrow` goes to 0 |

**For the trial's report:** these five come with Orb's question on whose stick moves whom (`workshop-six.md` item 6), asked after S2's clip.
