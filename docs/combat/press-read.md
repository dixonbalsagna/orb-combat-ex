# "Better combo control": what a press does

Combat, 2026-11-01. Orb's second play: "better combo control", near the top; "getting knockbacks feels very arbitrary. hard to charge up an attack when every hit seems to interrupt"; and the LT circle that "felt cool when it happened". **My read of what's missing, from Orb's own presses.**

## What this is, and how far to trust it

`repetition/orb_presses.gd`, on Orb's saved match. Counts only; the log stays private.

**This is Orb's actual match.** Tools rebuilt the exact tree, and on a copy of it every checkpoint and the final hash reproduce, so these are the real results, all 6:49 of it. It's one match, by one player, against the easy AI.

An earlier version of this page used a different tree, where the match parted from Orb's early on. **The re-run moved some numbers a lot and withdrew one of my picks,** and Encounter's event-by-event read corrected two more.

## What Orb's hands did

| Pressed | Count |
| :--- | ---: |
| Y | **823** |
| B | **390** |
| X | 256 |
| Dodge | 110 |
| RB + B, RB + Y, RB + X | 87, 52, 51 |
| Stick: plain, with RB | 22, 31 |
| Guard press; A | 47; 20 |

- **Orb plays Y and B, not X.** Everything we've tuned for "the mash" is about X. 54% of Orb's Y presses (446 of 822) came under 12 ticks after the last, which is shorter than Y's own 12-tick wind-up.
- **Orb barely charges.** Of 378 holds of B, 356 were let go before 28 ticks, B's wind-up. 6 reached 44 ticks, the full charge.

## What's missing

**Encounter's `docs/director/second-play-read.md` read the same match event by event, and where we differ, it's right.** This page is corrected to it, and it has the detail. What this page adds is what Orb's hands did, above.

### 1. The press should decide the send
This is "very arbitrary". **The same B can do five different things, by rules the player can't see:** whether the launcher's window just opened, how long it was held, and, starting an exchange, `earned`: held, or a landed string with flow 3 or more (a count nobody's shown), or a stick direction with at most 1 blow taken.

| 130 B blows thrown, in the 30 ticks after | |
| :--- | ---: |
| No send, no stagger (includes the misses) | 106 |
| Staggered him | 18 |
| Launched him | 4 |
| Perfect-blocked | 2 |

- My window isn't a full count of knock-backs. By Encounter's count, **Orb sent the rival 16 times in the match, 8 of them knock-backs:** 5 heavies with no launch earned, 2 charges short of full, 1 blast ender.
- **Orb's one full charge missed, because the rival walked out of reach.** So did 2 of the 4 part-charges. `miss:gave_ground` happened 19 times. Doing the right thing got nothing.
- The launcher lit 10 times, and 6 lapsed.

**I'd take Encounter's rule over my first pick.** Mine made every tapped B a knock-back, which is too many. How long you held B decides, everywhere:

| Press | Always |
| :--- | :--- |
| B tapped | A stagger |
| B tapped on a lit link | The launcher, share 0.25 |
| B past the first flash | A knock-back |
| B to the full flash | A send, share 1 |
| Left stick | Where it goes |
| The planner | Only which place, among those in reach |

**A full charge can't be walked away from,** and that's the first and smallest change. `earned` stops deciding a held heavy's result. It needs QA's read. Launch anywhere's lit link still fits this, on its own switch.

### 2. The circle Orb liked isn't an LT move
"Holding LT and attacking my guy would fly around in a tight circle then deliver an attack." **I had this wrong.** I took it for the step strike and the zip, and it's mostly the `dodge` exchange template: 13 exchanges in the match, with LT held at the start of only 4. It needs the computer to be evading at that moment, and 5 of the 13 ended with no blow at all. The step strike (14) goes straight through him, back and forth, so it isn't a circle. Zips: 5.

**LT was still held on 239 attack presses,** and 215 of them were Y. **206 of those were in reach, where LT + Y does nothing different from Y.** So Orb was asking for something, and that input is free.

**I agree with Encounter's proposal: LT + Y in reach is the circle, a move the player owns.** He goes over the rival, lands on the far side, and the medium lands as he arrives. LT + X stays the step strike, and LT + Y from the middle band stays the zip heavy.

**Combat's part, when it's ruled:** the arrival wants a blow that comes from above and past him, so a small pool of dropping and turning mediums for each fighter, not the cell's usual draw. The moveset generator's plan for this cell is only "a heavy on the move", with no pieces parked, so nothing's in the way. It gives a brawl its missing change of texture (`repetition/README.md`).

### 3. A press isn't a blow
| Pressed | Blows thrown | Blows a press | Pressed while his own blow was going |
| :--- | ---: | ---: | ---: |
| Y, 823 | 250 | 1 in 3.3 | 38% |
| B, 390 | 130 | 1 in 3 | **50%** |
| X, 256 | 100 | 1 in 2.6 | 22% |

**161 presses lapsed:** 86 Y, 59 B, 16 X. A press waits 10 ticks for the line, and a medium's wind-up is 12 and a heavy's 28, so a press made early in a blow always lapses. That's a quarter of the presses that had to wait, and nothing tells the player.

**I'd take Encounter's fix over my pick of speeding the next blow:** a press waits for the blow in hand to finish, one slot, newest wins. It's smaller, and every press then counts. It'll make a mash steadier, so QA reads the masher row.

**After that, phrases as the route:** 9 of the parked phrases finished in this match, and nothing told Orb. Letting the second press decide where the string goes, and showing when one lands, is the real "combo control", and that's Combat's and Game Design's next.

### 4. "Every hit seems to interrupt": mostly the stick
**I withdraw "a charge keeps half when it's hit".** Orb's holds weren't being hit:

| Held 8 ticks or more | Holds | Hit during the hold |
| :--- | ---: | ---: |
| B | 218 | **5** |
| Y | 225 | 11 |

**It's mostly the right stick:** 39 strikes started and 7 landed. The charge armour (`power-scale.md` §2) addresses that, and Orb hasn't played it. Of 125 B wind-ups, 108 reached the rival, 12 missed and 5 he cancelled himself.

Two smaller things:
- **Stuns:** only 4.4% of the match, but 173 attack presses landed in them, 26% of X. Those do nothing, and they may read as interruption.
- **94% of B holds were let go before the wind-up ended,** hit or not. Showing the charge's steps on the body and pad helps, and RT + B's power blow answers the rest.

### 5. Presses into nothing
Besides the stuns, 67 presses (5%) came while the rival was flying. Controls' refusal cue covers saying so, and `far-follow` and the chase rulings cover doing something. Also, RB + B was refused 51 times, and Orb had 23 stick releases with RB for 3 real beams: `power-scale.md`'s teaching section is on that.

## In order

1. **How long you held B decides,** and a full charge can't be walked away from.
2. **A press waits for the blow in hand.** Every press counts.
3. **LT + Y in reach is the circle.** It's the move a brawl lacks.
4. **Phrases as the route,** and tell the player when one lands.

## Hit weight

Orb: "I can see that theres some difference, but its imperceptible and I have no preference either way... always looking for hybrid approaches."

**Two reasons it was imperceptible:** there was **no sound at all** in that build, and heavy hits are half sound. And the difference was spread evenly over every blow, so nothing stood out from anything.

**My pick, a hybrid: small blows stay as today, and only what you paid for stops the clock.** It's `data/fight/hitstop.json`, on:

| Weight | Today | Its table now | **My pick** |
| :--- | ---: | ---: | ---: |
| Light in a mash | 2 | 0 to 2 | **0 to 2,** as the table |
| Light | 2 | 3 | **2** |
| Medium | 2 | 5 | **3** |
| Heavy | 6 | 8 | **8** |
| Launch; full launch | Today's | 12; 14 | **12; 14** |
| Decisive; KO | Today's | 20; 24 | **20; 24** |

**Why:** Orb plays Y most of all, and "every hit seems to interrupt". A 5-tick stop on every medium is the wrong place to add weight. Three ticks keeps a difference from X, and the heavy and up carry the feel. The 18% freeze budget stays.

**It needs Game Design's yes,** as it's their table, and a re-read once the sound works, since that may change everything here.

## Not checked

Anything against a person's hands, and whether the changes above are balanced. It's one match. The landed-B window of 30 ticks is mine, and sends that come from an exchange's own template aren't counted as a landed B's. The picks are proposals for Game Design.
