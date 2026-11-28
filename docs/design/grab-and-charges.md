# Grab and charges: brief 1 of the combat overhaul, ruled

Owner: Game Design. 2026-11-28, on the EP's wave 1 brief after Orb's restart. Source: the stand-in's directive (`docs/ep/proposals/combat-overhaul-directive.md` §3, §4, §6). Orb's words, after playing 0.1.1 on Easy (`docs/ep/vision.md`, 2026-11-27):
- "the computer spams it when I'm trying to charge up attacks ... there needs to be a grapple, but at the moment its a way too easy way to stall the match";
- "charging up a heavy or a right stick attack was way too easy to interrupt. these interruptions need rebalancing so spacing and timing becomes more important";
- "there's a lot of room in the current system for a player to simply flee combat constantly".

**Everything here sits behind one switch, `grabCharge`, off on main and on in Orb's private build** (§4). The flee rules (§3) are brief 5's: they get their own switch, `flee`, so Orb judges one change at a time.

**Amended the same day on Combat's review** (`docs/combat/grab-and-charges-review.md`), which kept the ruling with four fixes:
- G1 applies only where A is the catch, and its miss starts no lockout.
- G7's non-grab answers are split three ways.
- C3 counts the launcher as a heavy and says what "full" means for staged charges.
- E45 and E125 are amended under the switch.
- **C2 waits for the timing table and is not in the first trial.**

**What the code says today** (read for this page, beyond the directive):
- **The clinch judges only two pulses.** Pulses come every 20 ticks and a pulse is judged on the tick after its 4-tick window closes. So with `clinch.max` 60, the third pulse (closing at tick 65) is never judged. Today's clinch is two pummel contests followed by 15 dead ticks.
- **The computer's "fly-in" is a walk.** Its close-in step against a hold is the giving-ground step (5 bh a second), so it closes at most about 1.5 bh before the charge's first flash. The stall Orb felt is mainly the hold answer's grab in reach (Easy: 30 in 100 on a second hold, 65 on a third), plus the clinch's length and the 90-tick lockout.
- **A lunge lands at its crouch, plus its travel, plus the blow's own wind-up** (a heavy's 28). So the lunge's speed moves a charge's safety by only a few ticks. Removing the grab as the main answer is what protects a charge.

## 1. Grab (directive §4, "Grab")

| # | The number | Ruling | Why |
| ---: | :--- | :--- | :--- |
| G1 | **Reach 0.6 bh** (a light's) | **Kept, and read at the press as well, only where A is the catch:** in a brawl, and in the close band where A starts one (`stick-lands.md`, "near, A grabs"). There, an A out of reach starts no tell: it misses at once and leaves him open its 20 ticks (`catch.whiffOpen`). **That miss starts no lockout** (amended): only a catch whose tell began is an attempt. **In the middle and far bands A stays the taunt,** untouched. **The kits' thrown energy grabs** (Harbour Net, Rank Ring, Banner Snare, Crane Hook) aren't the catch, and G1 never applies to them | Equal to a light's reach keeps "blows beat grabs": anything that can grab you can be hit first. Reading it at the press is the directive's "no flying grab". The computer never presses out of reach (G7), so the lockout on a miss would only ever have hit players: one stray A would have locked the button for 3 s on top of the open window, which already pays for the miss. The lockout is there against grab loops, and a miss isn't one. Orb sees it in play like everything here, but I'm not unsure about it |
| G2 | **The full charge against the grab's tell** (directive: released during the tell, the charge lands as a counter-hit) | **Changed: a full charge is grab-proof.** A catch that lands on a fighter whose charge is full fails as a miss: the catcher is open 20 ticks and the charge goes on. Released inside the tell, the charge stops the grab as any landing blow does (already the rule). **No counter-hit multiplier** | A 10-tick tell is shorter than a human's reaction, so "release in the tell" rewards a guess, not a read. Grab-proof rewards the commitment of reaching full, which is what Orb asked for. The open catcher is the payoff. A new damage multiplier would be one more number to balance on every attack. Before full, a grab still stops the wind-up, as today |
| G3 | **The clinch: 60 ticks at most** (directive: 36) | **Changed: 45.** Both pulses are still judged (at 20 and 40), and the 15 dead ticks go. At the time, the leader throws (`timeThrows`), and at even both part 1.5 bh, as today | 36 leaves one pulse, which turns the clinch Orb chose ("rule in favor of clinch") into a coin flip. 45 is today's contest with nothing cut but the idle tail: a quarter shorter and still a contest |
| G4 | **It ends in motion** | **Accepted as today's rule.** Every throw already sends (across 8 bh, up 4 bh and open, down buried 20 ticks), and the even part separates the pair | Nothing to add. The bury is the opening that starts a chain (Orb: "a way to set up combo chains") |
| G5 | **The gap between grabs: lockout 90, noRegrab 120** | **Accepted: 180 and 240.** The lockout counts from every attempt, misses included | Three seconds between attempts is still plenty for a grab that sets up chains, and it ends the loop Orb saw |
| G6 | **The hold-break: worth 1.5 throws, and no noRegrab** (my ruling of 2026-11-21) | **Reversed under the switch: worth 1.0, and noRegrab starts,** as for any throw | That bonus made the grab the computer's main answer to a held charge (X-06), and Orb's play shows that answer is the stall. A catch on a wind-up already starts the clinch one ahead, so the bonus paid twice |
| G7 | **The computer's answer to a held charge** (directive: Easy 15 and 40 in 100, Medium 30 and 60, and never a grab answering two holds running) | **Accepted, plus three rules.** (a) **No close-in step:** it grabs only from inside reach. (b) **Of the answers drawn in reach and before full, 35 in 100 are grabs.** (c) **Never a grab answering two holds running,** counting its other grab-on-a-heavy path (`grapple.catch`) too. (d) **Every answer that isn't a grab is split three ways** (amended): **slip** the release and punish, **give ground** (its existing step back), or **guard**. Easy 0.5 / 0.3 / 0.2, Medium 0.55 / 0.3 / 0.15, Hard 0.6 / 0.3 / 0.1. **Hard keeps 0.95**, under the same rules | Orb's "the computer spams it when I'm trying to charge". The slip is a timing answer: the charge meets nothing and the charger is punished, without freezing the match. **The split is Combat's point:** after a send, the dodge is already 41 to 50% of what follows, so all slips would make the computer one-note. A guard against a charge loses to it (B beats the guard), and that's on purpose: it shows the triangle, mostly on Easy. This replaces 2026-11-21's "never guard, never step out" under the switch. Hard waits for a human read, as before |

## 2. Charges: spacing and timing (directive §4, "Charges")

| # | The number | Ruling | Why |
| ---: | :--- | :--- | :--- |
| C1 | **The mid-band lunge: 4,000 units a second, at least 3 ticks** | **Accepted: 2,600 and 8.** From the mid band's edge to where an approach ends (2.5 bh out), travel goes from about 12 ticks to about 18, before the crouch | It makes every mid-band approach readable, which serves Orb's "players never feel lost" as much as the charge. **Said plainly:** against a charge it buys only a few ticks, because the blow's own wind-up dominates. G2 and G7 do the protecting |
| C2 | **The leash: the defender gives ground 2.4 bh** | **Waits (amended): not in the first trial; the leash stays 2.4.** The target holds: **an on-time full charge lands on a defender who backs off from his reaction time, and a charge held 20 ticks past full doesn't.** The timing table (§5) sets the leash from that. **If an on-time charge misses even at 2.4, the lever is the timed release's reach (C4), not the leash** | Combat's arithmetic: backing at 5 bh a second, a defender is about 3 bh away by full, against a charged reach of 1.5 (2.0 on time). Orb's one full charge on 9 November missed because the rival walked out of reach. And the brawl lets go past `breakBh` 4.5, raw distance, so a leash of 4 past striking distance could end the brawl. Nobody has measured it, so it doesn't go to Orb untested |
| C3 | **Once full, only a heavy or a beam stops it** | **Accepted, for every stop:** not a grab (G2), not a quick stick strike's stun, not two quick lights, not a bolt or a blast below a beam. They still hit for their damage through the armour. **A launcher counts as a heavy** (amended): it's a B, the stagger's and launch-anywhere's alike, so it stops a full charge. **"Full" for a staged charge** (the stick's hold, the Driver's levels, a lob's or a beam's charge) **is the last stage he can reach at that moment,** by his energy and form. Before it, each charge keeps its own stop rules | Spacing and timing: a heavy needs 28 ticks of wind-up, so it only stops a full charge held too long. A beam costs 45 energy. Everything cheap stops a charge only before it's full, as today (a medium before tick 20; a grab before full). "The last stage he can reach" is Combat's suggestion: a fighter who can't afford the top stage is full at the one he can, so the rule doesn't depend on a stage he'll never get to |
| C4 | **The timed release: within 6 ticks of full, half a body height further** | **Accepted: `sweetTicks` 6, `sweetReachBh` 0.5** (reach 1.5 → 2.0). The cue is the full flash that's already there: **no new marker** | It rewards releasing on time and pairs with C2: on time it reaches; fished, the defender has stepped away |

**Rule texts brought into line under the switch:**
- **`energy-overhaul.md` E45 and E125** are amended there.
- **The kits' answer lists** (`energy-movesets.md` and the four kit pages, Combat's) should read **"a grab only before full"** for the energy grabs' answer to a held charge.
- **A thrown energy grab that meets a full charge** (2026-11-28, Combat's question): it breaks on him as it does on a dodge (E62). There's no catch and nothing is staged, and the charge goes on.
  - **The thrower isn't opened** beyond the throw's own frames: from range, the grab's energy and its frames are its price, and an open window there does nothing the charger could reach.
  - **Thrown from inside a light's reach, it's G2's miss: open 20 ticks,** so the energy grab is never the safe way to test a full charge up close.
  - **Waiting (§2c, b):** the sim has no thrown energy grab and no charged lob yet, so this rule has nothing to attach to until they're built.
- **Combat's note on the throw at the time:** from even, every throw is the leader's at the time, at 60 as at 45. From one ahead (a guard or a wind-up caught), the earned throw still comes on the second pulse. A third pulse for the earned throw from even isn't in this brief.

### 2b. The charge at range: hold to charge in place (2026-11-28, Encounter's probe; EP's option 1)

**Encounter's finding:** there was no charge at range. B held at 8 bh was a heavy lunge that then charged at arm's length. A heavy's wind-up ran during its lunge, so a rival's heavy landed at press + 32 from 2 bh and from 8 bh alike. Distance bought nothing against a heavy.

**Ruling: yes, option 1, under `grabCharge`.**

| # | Rule | Numbers | Why |
| ---: | :--- | :--- | :--- |
| R1 | **In the mid band, B still held when the lunge's crouch ends stays and charges where he stands.** A tap lunges as now. **The stick's hold does the same** by its own stages, and a quick flick lunges | The crouch: B's 10 ticks, the stick's 6 (`bands.lunge.windupTicks`). No new wait: the crouch runs either way, and the button is read at its end | E2 holds: a tap is one blow, a hold is one attack. Melee press feel holds: every press is a blow. The far band already works this way (a hold is a charge) |
| R2 | **The charge keeps its clock from the press:** first flash at 32, full at 44, released by itself at 70 | Unchanged | The 70-tick release is the melee heavy's own rule (`press-decides.md`). It stops a charge held in place from becoming a stall. E47's "never fired by itself" is the energy family's, not this |
| R3 | **While charging in place he moves at half speed** on the left stick. A dodge tap or a guard press drops it for nothing. His armour is as in a brawl | E45's half speed, E46's drop | It matches every other charge in the game (E45 and E46). Backing off while charging is spacing, which is the point. Control first (E1): it can always be dropped |
| R4 | **Released at full (or at 70), it flies to him and lands** | Its own keys, `charge.inPlace.fullFlight`: reach **12.5 bh** (the mid band's edge) over at most **14 ticks**, so at most about 4,000 units a second (the old lunge's speed, inside Camera's whip line). The brawl's `chargeClose` (3 and 6 bh over 12 ticks) is untouched | Pillar 3: the full charge closes the gap. As `chargeClose` already says, stepping back doesn't beat it; a dodge, a guard or a perfect block does, so the release is the tell |
| R5 | **Released before full, it lunges in at the lunge's speed** (2,600, no second crouch) and lands as the stage it reached | Uses C1's lunge | One press, one attack, and it still arrives. An early release from range is slow and readable, so it can be answered |
| R6 | **If he has backed into the far band by the release,** it flies as the far band's heavy charge does | `bands.charge.heavy` (3,000 a second, 30 to 84 ticks) | Attacks always arrive; from that far it's a long flight anyone can read |
| R7 | **A heavy pressed from the mid band starts its 28-tick wind-up when its lunge arrives,** not during it. Lights and mediums are unchanged | `heavyWindOnArrival` | This is what makes room buy time. From 2 bh (close band, no lunge) a reacted heavy lands at about 42, just before full at 44. From the mid band it lands at least 10 + travel ticks later, after full. So room beats a heavy and arm's length doesn't. The cost: every heavy from range is slower by its travel, about 0.15 to 0.3 s. That fits the heavy's character (slow, committed), and QA's match-length band is the check |

**What a mid-band charge still loses to:** a beam (always); a rival who closes to the close band himself and grabs or hits before full; a slip, a dodge or a perfect block timed to the release. A guard loses to it (B beats the guard).

**On the pad:** tap B and he lunges and hits. Hold B and he crouches, plants and glows with the existing flashes. Let go and he flies in. **No new marker.** Orb judges it in the clip; it's a control change.

**For the timing table (§5):** `chargeClose` already carries a full release up to 6 bh. So Combat's C2 arithmetic (a defender about 3 bh back by full) may already be answered; the table shows it.

**Together:** a charge started with room is safe from everything cheap once it's full. One started at arm's length can still be grabbed or out-timed before it's full. That's the spacing Orb asked for, and pillar 3 still holds.

### 2c. Encounter's build and QA's baseline: five answers (2026-11-28)

From Encounter's brief 1 report (`docs/director/pending/grab-charge/README.md`, "Not built") and QA's baseline (`docs/qa/readings/combat-baseline.md`, d0d08177).

**C5. A brawl's end doesn't end a charge (new, under `grabCharge`).**
- **What QA found:**
  - On Medium, the kit player lost 458 of 619 interrupted heavies with the brawl, not to a blow or a grab.
  - In a four-match diagnostic, 17 of 19 such losses were the brawl ending, 15 of them with the computer starting a flight strike on that tick.
  - Encounter's (d) is the same rule: every brawl ending clears a charge today (the rival's burst, boost-away, flight strike, Driver or signature start, or the pair walking apart past `breakBh`).
- **Ruled on the charger's state, not the computer's choice.**
  - A rule in the computer would leave the same hole for a human rival, who can end a brawl with a flight strike on purpose.
  - A brawl ending isn't a blow. It shouldn't do what C3 lets only a heavy, a launcher or a beam do.
- **When the brawl ends while he holds the charge, the charge goes on:**
  - on the same clock (full at 44, released by itself at 70), with the price already paid;
  - at half speed (R3), with its armour (E45 before full, C3 at full).
  - If a brawl starts again, it takes the charge back on the same clock (the existing hand-over).
- **Where it started decides its release.**
  - A brawl's charge keeps the brawl's release wherever he is: `chargeClose`, 3 bh at the first flash and 6 at full, over at most 12 ticks.
  - One started in place (R1) keeps R4 to R6.
  - Room is what buys the long flight. C2's target stays meaningful too: a defender who walked out escapes a charge held too long.
- **What still ends it:**
  - a blow, by its weight (E45 before full, C3 at full);
  - a beam's touch;
  - a send or set piece that takes him (a launch, a throw, a slam, a struggle);
  - anything he does himself other than moving and holding (a dodge, a guard press, a burst, a flight strike, a signature, a Driver);
  - a KO.
- **The flight strike, then: the computer keeps its choice.** Its blow meets the charge like any other blow:
  - a light goes through for its damage;
  - a medium stops it only before tick 20;
  - a heavy stops it.
  - A flight strike that loops away leaves the charger free to release into it if it's in reach.
- **The cost:** charging gets stronger again, on top of G2 and G7. QA's X-06 read (§5) covers it, with the same levers.

**(a) The Driver: later, a step of its own (D1).**
- Today any exchange start drops it (`driver.gd:89-91`), and E125's "armoured against lights from level 1" was never built.
- Making it live inside an exchange touches every exchange start, so it isn't in this trial. The trial judges the heavy, where Orb's complaint and QA's numbers are.
- **In the trial the Driver keeps today's rules,** and Orb's clip doesn't use it.
- **D1, briefed after Orb's verdict on the trial:**
  - an exchange that starts while he holds the Driver doesn't drop it;
  - it builds E125 as written, with C3 at full ("full" is the last level he can pay for) and C5's brawl endings.

**(b) The thrown energy grab: waiting.** The sim has no thrown energy grab and no charged lob (`rally.gd:33-35`). The rule in §2 stands, and it's attached when they're built. Nothing changes in the trial.

**(c) R5 for B lands as a tapped heavy: accepted for the trial on one condition.**
- **No price is kept for a stage that doesn't land.** A B let go between the first flash (32) and full (44) either lands at the stage it reached, as the stick's does, or gives back the first flash's price. Encounter picks the smaller change.
- R5 as written (it lands at its stage) is what gets adopted with the switch.
- A release before 32 is a tapped heavy either way, which is right.

**(d) Brawl endings clearing a charge: no.** C5 replaces it.

## 3. Fleeing (directive §3): ruled now, built in brief 5

| # | The rule | Ruling | Why |
| ---: | :--- | :--- | :--- |
| F1 | **Running is paid in wind:** LT empties a full meter in about 17 s, and winded flight is 20% slower | **Already ruled** (`energy-stamina-body.md` §2: 6 a second; winded `flightMul` 0.8). **One change to row 13:** flat-out flight costs stamina within 60 bh of the nearest rival, **or at any distance while it is opening the gap** | Row 13 made crossing a big planet free. As written, though, it also made fleeing free once past 4,500 units, which at 3,500 a second is about a second and a third from contact. Flying toward a rival, or travelling with no one to flee from, stays free |
| F2 | **Wind comes back when you stand your ground, not when you get away** (the spec's "only away from the fight") | **Accepted: the wording is changed.** Resting refills only when he is out of the running exchange (row 4), spending nothing, **and not opening the gap by his own flight** | The directive is right: "away from the fight" read as distance pays the runner. Row 4's real job was "not inside the exchange", so guarding tires. Breaking away and then standing, circling or closing still rests, so §7's comeback valve stays. Running doesn't |
| F3 | **No energy back for a turned back:** beyond 12.5 bh, while opening the gap by his own flight | **Accepted.** Energy's 5 a second stops; nothing else changes | A soft cost, not a refusal. Inside mid range, backing off to make room for a charge is never touched |
| F4 | **A turned back is open:** after 90 ticks of opening the gap, the next blow or shot that reaches him can't be guarded, as a counter-hit worth 1.25 | **Accepted without the 1.25.** The guard doesn't hold while he has been opening the gap for 90 ticks or more, **and for 12 ticks after he stops** (turning round takes time). The blow lands as an ordinary unguarded blow | Running flat out isn't a guard, and the 90 ticks spare every short back-step. The multiplier goes for G2's reason: no counter-hit system exists, and the unguarded blow is already the price |

**"Opening the gap by his own flight"** is one test for all four: while he is free and under his own control, the part of his velocity along the shortest arc away from the rival is at least `minOpenSpeed` 600 units a second. That's above giving ground (375), so a brawl's step back never counts. Sends, knock-backs, throws and bursts never count.

## 4. The data (one switch per brief; Encounter's files, so they're listed under NEEDS FROM EP)

**Brief 1: `interrupts.json` `grabCharge`.** While `enabled`, each dotted path replaces the value it names; off, nothing changes.
```json
"grabCharge": {
  "enabled": false,
  "_note": "Game Design, docs/design/grab-and-charges.md (2026-11-28): brief 1 of the combat overhaul. While enabled, each dotted path below replaces the value it names, in this file and in ai.json's grabCharge block; off, nothing changes",
  "set": {
    "grapple.clinch.max": 45,
    "grapple.lockout": 180,
    "grapple.noRegrab": 240,
    "grapple.throw.holdBreak": {},
    "bands.lunge.speed": 2600,
    "bands.lunge.minTicks": 8
  },
  "grab": { "reachAtPress": "catchOnly", "missLockout": false, "fullChargeProof": true },
  "charge": {
    "full": "lastReachableStage", "fullStoppedBy": ["heavy", "launcher", "beam"], "sweetTicks": 6, "sweetReachBh": 0.5,
    "inPlace": { "bands": ["mid"], "holdPastCrouch": true, "moveMul": 0.5, "fullFlight": { "reachBh": 12.5, "maxTicks": 14 }, "beforeFull": "lunge", "pastBand": "farCharge" },
    "heavyWindOnArrival": true,
    "outlivesBrawl": true
  }
}
```
- `outlivesBrawl` (C5): a brawl ending doesn't clear a held charge. It runs on with its clock, price, half speed and armour, and where it started decides its release (a brawl's keeps `brawl.chargeClose`; an in-place one keeps `inPlace`).
- `inPlace` (§2b): in the mid band, B or the stick still held when the lunge's crouch ends charges where he stands.
  - `moveMul` 0.5 is his speed meanwhile.
  - `fullFlight` is the full (or 70-tick) release's flight to him.
  - `beforeFull` `"lunge"`: an earlier release lunges at `bands.lunge.speed`, with no second crouch.
  - `pastBand` `"farCharge"`: if he's in the far band by the release, it flies as `bands.charge.heavy`.
- `heavyWindOnArrival`: a heavy pressed from the mid band starts its wind-up when its lunge arrives.
- `reachAtPress` `"catchOnly"`: read only where A is the catch (a brawl, or the close band where A starts one). The middle and far bands' taunt and the kits' energy grabs never read it.
- `missLockout` false: a miss at the press costs `catch.whiffOpen` only. A tell that began is an attempt and starts `grapple.lockout`, as today.
- **C2's `"brawl.give.leashBh"` isn't in the set** until the timing table names its value.

**`ai.json` `grabCharge`** (read by the same switch):
```json
"grabCharge": {
  "set": {
    "levels.easy.brawl.holdAnswer": { "windowTicks": 420, "byCount": [0, 0.15, 0.4] },
    "levels.medium.brawl.holdAnswer": { "windowTicks": 300, "byCount": [0, 0.3, 0.6] }
  },
  "holdGrab": { "closeIn": false, "share": 0.35, "notTwiceRunning": true },
  "holdOther": {
    "_note": "the hold answers that aren't a grab: [slip, giveGround, guard], one keyed draw an answer. giveGround is its existing step back; guard is held until the blow lands",
    "easy": [0.5, 0.3, 0.2], "medium": [0.55, 0.3, 0.15], "hard": [0.6, 0.3, 0.1]
  }
}
```
`grapple.throw.holdBreak` set to `{}` is "absent" by its own note: a hold-break is any other throw.

**Brief 5: `vitals.json` `flee`** (Simulation's file once the stamina loop is built; rules F3 and F4 don't need stamina):
```json
"flee": {
  "enabled": false,
  "minOpenSpeed": 600,
  "flatOutWhenOpening": true,
  "restWhenOpening": false,
  "energy": { "beyondBh": 12.5, "regenWhenOpening": 0 },
  "turnedBack": { "afterTicks": 90, "turnTicks": 12 }
}
```

## 5. What QA reads with `grabCharge` on, against off, on the same seeds

**First, a timing table** (Encounter or QA, before the batch; the directive's numbers were never played).
- **The answers:** for a heavy charge begun at 1, 2, 4 and 8 bh, the tick each answer lands, set against full at 44. The answers are the computer's grab, a medium, a heavy, a launcher, a quick stick strike, and a mid-band heavy lunge.
- **The backing defender (C2):** he gives ground from his reaction time, straight away at 5 bh a second.
  - Read it with the leash at 2.4 and at 4, and with the charger following and not following.
  - **For each, does the release land?** On time (within 6 ticks of full), and 20 ticks past full.
  - Report the raw distance against `breakBh` 4.5 too.
  - **C2 goes on at the largest leash** where the on-time release lands and the late one doesn't. If none does, the lever is C4's reach.

**Then the directive's acceptance, with G3's 45:**
- a full charge is never stopped by a grab;
- no grab begins from outside 0.6 bh (a check row over 200 computer matches);
- no two grabs by one fighter inside 180 ticks;
- on Easy, three heavies held in a row are grabbed fewer than 15 times in 100;
- a charge begun at 8 bh completes against a lunge begun on the same tick, and one begun at 2 bh does not;
- match length on Easy and Medium stays in QA's band.

**The "before" for every row is QA's baseline** (`docs/qa/readings/combat-baseline.md`, d0d08177). For example: every computer grab try there (5,230) began while the player was winding or charging a heavy, and on Easy a charge-only player had 72.5% of three-heavy runs grabbed.

**Three more:**
- **C5:** on Medium, the kit player's heavies "lost with the brawl" (458 of 619 on the baseline) fall to the KO and set-piece cases only. Every flight strike blow that stops a charge is a heavy, or a medium before tick 20.
- **The stall:** clinch ticks per minute at Easy and Medium, at least halved.
- **X-06's one-note bands** (`gauntlet-plan.md`): the charge-only pad at most 80% at Easy and at most 55% at Medium.
  - **This is the risk.** A grab-proof full charge and fewer answers both help a pad that only charges.
  - **QA reads the charge-only pad first, before the clip goes to Orb** (Combat: it already won 60 of 60 on the 9 November build, A-AI-10).
  - **If it fails, the levers in order:**
    1. `holdOther`'s guard share down to 0, since the guard is the gift;
    2. byCount's last entry back toward 0.65 and 0.9;
    3. `holdGrab.share`.
  - **Never** the grab's reach, and never the grab-proof rule.

**Encounter's build check keeps Combat's nine grapple moments** (`grab-and-charges-review.md`, "What Encounter's build must not lose"): catch, clinch, throw; blows beat grabs in the tell; a grab beats a guard, one ahead on a guard or a wind-up before full; the throws by stick; the reversal; the tech and the perfect catch; a stray voids the next pummel; each fighter's throws and looks, picked by personality; and "refused" on an A in the lockout.

**Orb's clip:** the directive's thirty seconds twice, with the buttons drawn. One question: "Does charging feel earned now?"
