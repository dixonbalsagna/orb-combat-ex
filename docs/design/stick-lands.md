# Making the stick land

Owner: Game Design. 2026-11-01. Rules Combat's read (`docs/combat/pending/stick-directions/README.md`): flicks land 5% of the time against the AI. Amends `right-hand-attacks-rulings.md` §2 and replaces `pad-first-press.md`'s LB + flick where they differ. **Unplayed, and first values.** It's a blind bot, so the rows below are for direction, not verdicts.

## The ruling

**Keep the wind-up at 7. Change what a light does to a quick flick: it takes the stun, not the blow. And give LB + flick a way through.**

**Why not the wind-up.** It's the wrong lever, on three counts:
- **It tops out too low.** Lights land 2 ticks after the press, so against steady lights 12 ticks apart, a wind-up of 7 is clean 42% of the time, 4 is 67% and 2 is 83%. Combat measured 5%, 17% and 28%. At every value, at least two flicks in three fail for some other reason. This is rough arithmetic, but even no wind-up would leave most flicks failing.
- **Where the rest go:** Controls found 46% of requests never start a strike at all (`docs/controls/responsiveness.md` §8). Guards and dodges take more, and those are fair: the player can see them.
- **It feeds the danger I already named:** at 2, it's about as fast as a light, with a stun.

**The real fault is in my rule.** A light doesn't end Y's wind-up or B's. **The stick is the only blow that a light cancels,** and lights are 75% of all blows. So the press makes no blow at all, against Orb's "one press, one attack". Soft costs beat hard stops here too.

## The rules

| | Rule | First value |
| :--- | :--- | :--- |
| **1. A light on a quick flick** | The flick still lands. He takes the light as normal. **It loses the stun and some worth, and keeps its direction,** so the player always sees the stick do what they aimed | Worth 2.5 to 1.7, no stun, full carry |
| **2. Y or B on a quick flick** | Ends it, as they end a Y. Unchanged | |
| **3. A charged flick** | **Re-ruled on Orb's first play:** a hold past the quick flick has B's armour, so a light never stops it (`power-scale.md`) | |
| **4. LB held + flick** | **The guard stays up through the wind-up,** so lights are blocked and can't touch the stun. It drops for the recovery. Y's double chip and B's guard break are the answers, and B ends the wind-up | Stun 14, against 20. Same worth, ki and commitment |
| **5. LT held + flick** | No change. It keeps its move lane and its pieces | |
| **6. A flick that can't start** | **Encounter:** a request is honoured on the first free tick inside 9 ticks. It never turns into some other blow (109 of 795 did). If it's dropped, the pad gets the refusal cue | The 90-tick note goes |

**What a player feels** (corrected after Combat's read, below). Flick in a brawl and something always happens, in the direction you aimed, and it breaks his rhythm. Flick as he winds up a Y or B, or when his lights stop, and he's stunned as well. Hold guard, flick through his lights, and you land a smaller stun, once a string. That's "the left hand survives, the right hand hurts" as a move.

**Beats, now:**
- **A steady mash of lights** (6 or 7 ticks apart) still can't be stunned by a plain flick. It takes the reduced blow and a shove instead. So a beginner's mash holds up, and it no longer shuts the stick out.
- **Guard + flick** beats a mash, loses to Y's chip and B, and is blocked by his guard like any blow.
- **The triangle stands:** a guard beats the stick, the stick beats B, B beats the guard.

**The claw law.** No lockout, tick or commitment moves, and LB + right thumb is an ordinary grip. The claw gate re-runs anyway, as a hard test.

**On a switch:** `stick.lightStops`, in `data/director/stick.json`. True is today's rule, so Orb can feel both.

## Rows for the re-run

Combat's beat bot and whole-pad bot, read loosely:

| Row | Band |
| :--- | :--- |
| Flicks that land at all, reduced or clean | At least 40% |
| Flicks that land clean, with the stun | **Withdrawn, see below** |
| LB + flick landing, on a foe who isn't guarding | At least 60% |
| Stick-only against buttons-only (rulings §7) | Within 10 points |
| The stick's share of blows, and Y's and B's beside it (rulings §7) | 10 to 30%, and Y isn't pushed out |
| The masher, and L17 (rulings §7) | 35 to 50%; as ruled |
| Claw gate | Zero gain |

**If the stick dominates,** in this order: reduced worth 1.7 to 1.25, then the stun 20 to 16, as already ruled, then LB + flick's stun 14 to 10. **If it still rarely lands,** then the wind-up goes 7 to 5, and only then.

## After Combat's read (2026-11-01)

Combat's bots (`docs/combat/pending/stick-directions/README.md`): land at all 66 to 71%, LB + flick 77 to 88%, both met. Clean 0 to 2% on the beat and 6% with the whole pad, against my 10 to 25%. A light took the stun on 88% of hits. A wind-up of 5 doesn't change it.

**The clean band was the wrong target, and it's withdrawn.**
- **It contradicts my own rule.** I ruled that a steady stream of lights can't be stunned by a plain flick, then asked for a share of flicks that does it, against an AI that throws a steady stream. A person mashing does the same, so it isn't only a bot's habit, and the rule stays.
- **Its denominator is wrong.** With one stun a string, a share of flicks falls the more someone flicks. That's also why LB + flick reads 2 to 7%. The bot flicks far more than a person would. Both caps stay.
- **The stun is a read's reward.** A blind bot shouldn't find it. About 2 a minute did turn up (131 in the two arms' 60 minutes), and that seems about right for something that opens a string.

**So yes, against a stream the flick's chief reward is its carry, and today that isn't enough.** A flick returns before the brawl's run and reel (`brawl.gd` contact). So a flick with no stun doesn't reel him, and his run keeps climbing. He shrugs it off and closes on you anyway. **That's the fix, and the only one:**

| | Rule | First value |
| :--- | :--- | :--- |
| **Any flick that lands with no stun** | **It's a blow he feels.** He reels and loses some of his run. Yours doesn't grow, so a flick stops his string without building yours. Y stays the blow that does both | Reel 6, as Y's. His run down 2. Own run 0 |

**How that plays.** Reel 6 against the flick's recovery of 7, plus the gap his next blow has to close, comes out about level. So a flick into a stream hands back an even game, and it's neither a punish nor a free win. Against lights 8 ticks apart he gains about 2 run per flick and loses 2, so stick-only holds a masher off but doesn't beat him. It's in the data, in `data/director/stick.json`, and no lockout moves.

**The new rows,** in place of the clean band:

| Row | Band |
| :--- | :--- |
| A bot that flicks only as his Y or B winds up, or with no light of his on the way: clean | At least 50% |
| A bot using the stick freely: stuns a minute | At least 1 |
| LB + flick, the first of a string, on a foe who isn't guarding: stuns | At least 60% |
| Stick-only against a mash of X: QA's arm, in wins | Level, within 10 points. Over that: run down 2 to 1, then reel 6 to 4 |
| Closes on a player using the stick, against one who isn't | Fewer |

**The wind-up stays at 7.** The "wind-up 5, last" lever is withdrawn too, as Combat's read shows it does nothing for this.

**Not a lever yet: giving the AI pauses.** A more varied AI would make the stun easier to reach and the brawl richer, but people's hands should come first.

## The stick steals his run (the stand-in's proposal, 2026-11-01)

`docs/ep/proposals/stick-steals-run.md`. **Yes to a scratch QA run, in a narrower shape.** My reel-and-run rule held a masher off on paper, and QA's read since has stick-only far behind X mash. A steal rewards reading a flurry, which is the right promise. Unplayed.

**It barely touches "a beginner's mash holds up":** QA says the AI doesn't use the stick, so a beginner mashing against the computer is never stolen from. It only applies between people. **Keep it that way for this run:** the AI doesn't steal.

| | The shape for the run | Why |
| :--- | :--- | :--- |
| **Which flicks** | **A quick flick that isn't guarded, from no stance.** Not LB + flick, and not a charged hold | LB + flick is already safe from lights, and a hold now has armour. Armour plus a steal would simply win |
| **The steal** | His run goes to 0, and yours rises by what you took, at most 3. It's still no close from the flick itself | A close needs 4, so it takes a blow of yours to finish, within the run's usual lapse |
| **The stumble: first value 2 ticks a point** | Reel `6 + 2 × taken`. Also run 3 a point as a second arm | The flick's recovery is 7, and X needs 2. So at 2 a point, a steal of 2 or 3 leaves time for X and a steal of 1 doesn't: he has to really be mashing. At 3, every steal does, and the toy runs away soon above that |
| **Carry** | **No bonus for the first run** | The toy's bonus throws him up to 3 body heights away, and the gap eats the time the stumble just bought |
| **Worth** | Unchanged: 1.7 if a light took the stun, 2.5 if not | |

**The limits that are already there:** his next close is barred for 1.5 s after one lands, and he's only stolen from once a run. Stumbling blocks him from building another. So it can't lock him, by my arithmetic. **With a clean flick,** the stun already covers the stumble.

**The rows.**

| Row | Band |
| :--- | :--- |
| **A bot that mashes X and flicks when his run is 2 or more, against X mash and against the medium AI** | **At least 10 points above X mash.** This is the expert's promise, and the row that matters most |
| Stick-only against the AI | Within 10 points of X mash, as ruled, and no higher than it |
| Y's share of blows, for a free-choice bot | Doesn't fall under what it is today. A steal competes with Y against a flurry |
| Closes on a stick player | Fewer |
| The masher and the newcomer against the AI | Unchanged, as the AI doesn't steal |
| Claw gate | Zero gain |

**If it's too strong:** `max` 3 to 2, then steal only at 2 or more. **What would kill it:** Orb's hands, if being stolen from feels random, or stick-only becoming the best way to play.

## The Driver seeks

Encounter's park seeks, where E124 and E126 say straight. **Fine for the first press.** It's the player's alone, and the AI doesn't use it, so nobody's being hit by something they can't step off. **Conditions:**
- **Straight is first on the Driver's next pass,** since it's the biggest gap from the rule and what separates B from Y.
- **Orb is told it seeks for now,** with no look of its own yet, when they judge it, because "straight" is part of what they'd be picking.
- **What to watch:** level 3 is a full send from any range, through a guard, at 24 ki, and only the dodge window answers it. Against the AI that may be close to free. If holding it at range turns out to be the best way to play, raise level 3 to 30 ki before anything else.

## The direction table

Combat's table, with three changes. Same worth in all four. "Free" is the ticks left in the stun once the attacker's commitment ends: stun less 7. Y needs 12, X needs 2, and closing a gap adds to both.

| Direction | Quick stun | Free | He goes (quick) | What it sets up | Charged stun | Charged carry |
| :--- | ---: | ---: | :--- | :--- | ---: | :--- |
| **Up** | 24 | 17 | Up 1.25 bh | Y after closing the gap, or B's launcher. The string's best opening | ×1.2 | ×1.5 |
| **Down** | **22** | 15 | To the floor; in the air, down 2.5 bh | Y at no distance | ×1.3 | ×1 |
| **Toward** | 16 | 9 | Back 1.25 bh | X only, after closing. It buys room, and it's what you use on someone crowding you | ×0.8 | ×1.5 |
| **Away** | 20 | 13 | **Past you,** reach ×1.6 | Y only just, and the sides swap | ×1 | ×1, reach ×1.3 |

**The three changes.**
1. **Down on the floor is 22, not 28.** Combat's page says 22, but its data gives ×1.4. With no gap to close, 28 would make it the best direction outright. ×1.1 in both places.
2. **Carry stops at 4 bh.** ×1.5 at level 3 makes 6 bh, past `breakBh` 4.5, which ends the brawl. The stick "never sends him". So ×1.5 is for levels 1 and 2, and level 3 stays at 4. **Encounter checks 4 holds the brawl,** with the gap added, on all four directions.
3. **Down on flat ground bounces,** about 0.5 bh and back to the floor, as a look only. No crater: a flick at tier 1 shouldn't dent the planet. If it isn't cheap, ship without it.

**Away doesn't meet the ruling yet.** It's the one row that isn't right: Encounter's `DirStick._carry` has to let go of the attacker. Until then it's a different feel, not "past".

**"No direction wins" can't be read** until flicks land, so that row goes after the re-run.

## A

**Widen both. The rule becomes: near, A grabs. Anywhere else, A taunts.** The empty-button cue is left for when he can't act.

| Where | Today | Now |
| :--- | :--- | :--- |
| **In a brawl** | The catch | The same |
| **Close band, no brawl** | Empty cue | **Starts a brawl with the catch as its first blow,** the way X starts one with a blow. Same tell, 10 ticks, and same whiff |
| **Middle band** | Empty cue | **The taunt,** the far band's own, with the same paying ladder. At this range a lunge reaches him in a few ticks, so it's a real bet |
| **Far band** | The taunt | The same |
| **A + guard, A + energy** | Reversal, mine | The same |

**A held in the middle band** isn't a charge: tap and hold are the same taunt.

Three in four grabs are stopped by the AI's blows, and that stays. Blows beat grabs, and a person picks moments better than Combat's bot. A close A against a guard is where it should earn its keep, since the clinch leads against a guard.

## For Orb

No decision needed. **Tell them:** a light used to cancel a flick in the version they played, and now it only takes the stun. Their hands judge it, and the switch puts it back.
