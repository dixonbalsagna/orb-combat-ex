# Grab and charges: brief 1 of the combat overhaul, ruled

Owner: Game Design. 2026-11-28, on the EP's wave 1 brief after Orb's restart. Source: the stand-in's directive (`docs/ep/proposals/combat-overhaul-directive.md` §3, §4, §6). Orb's words, after playing 0.1.1 on Easy (`docs/ep/vision.md`, 2026-11-27):
- "the computer spams it when I'm trying to charge up attacks ... there needs to be a grapple, but at the moment its a way too easy way to stall the match";
- "charging up a heavy or a right stick attack was way too easy to interrupt. these interruptions need rebalancing so spacing and timing becomes more important";
- "there's a lot of room in the current system for a player to simply flee combat constantly".

**Everything here sits behind one switch, `grabCharge`, off on main and on in Orb's private build** (§4). The flee rules (§3) are brief 5's: they get their own switch, `flee`, so Orb judges one change at a time.

**What the code says today** (read for this page, beyond the directive):
- **The clinch judges only two pulses.** Pulses come every 20 ticks and a pulse is judged on the tick after its 4-tick window closes. So with `clinch.max` 60, the third pulse (closing at tick 65) is never judged. Today's clinch is two pummel contests followed by 15 dead ticks.
- **The computer's "fly-in" is a walk.** Its close-in step against a hold is the giving-ground step (5 bh a second), so it closes at most about 1.5 bh before the charge's first flash. The stall Orb felt is mainly the hold answer's grab in reach (Easy: 30 in 100 on a second hold, 65 on a third), plus the clinch's length and the 90-tick lockout.
- **A lunge lands at its crouch, plus its travel, plus the blow's own wind-up** (a heavy's 28). So the lunge's speed moves a charge's safety by only a few ticks. Removing the grab as the main answer is what protects a charge.

## 1. Grab (directive §4, "Grab")

| # | The number | Ruling | Why |
| ---: | :--- | :--- | :--- |
| G1 | **Reach 0.6 bh** (a light's) | **Kept, and read at the press as well.** A press of A out of reach starts no tell: it misses at once, leaving him open its 20 ticks (`catch.whiffOpen`), and the lockout starts | Equal to a light's reach keeps "blows beat grabs": anything that can grab you can be hit first. Reading it at the press is the directive's "no flying grab", for players and the computer alike. A grab is the one move that doesn't close the gap; it's the close-range answer, and pillar 3's other attacks still always arrive |
| G2 | **The full charge against the grab's tell** (directive: released during the tell, the charge lands as a counter-hit) | **Changed: a full charge is grab-proof.** A catch that lands on a fighter whose charge is full fails as a miss: the catcher is open 20 ticks and the charge goes on. Released inside the tell, the charge stops the grab as any landing blow does (already the rule). **No counter-hit multiplier** | A 10-tick tell is shorter than a human's reaction, so "release in the tell" rewards a guess, not a read. Grab-proof rewards the commitment of reaching full, which is what Orb asked for. The open catcher is the payoff. A new damage multiplier would be one more number to balance on every attack. Before full, a grab still stops the wind-up, as today |
| G3 | **The clinch: 60 ticks at most** (directive: 36) | **Changed: 45.** Both pulses are still judged (at 20 and 40), and the 15 dead ticks go. At the time, the leader throws (`timeThrows`), and at even both part 1.5 bh, as today | 36 leaves one pulse, which turns the clinch Orb chose ("rule in favor of clinch") into a coin flip. 45 is today's contest with nothing cut but the idle tail: a quarter shorter and still a contest |
| G4 | **It ends in motion** | **Accepted as today's rule.** Every throw already sends (across 8 bh, up 4 bh and open, down buried 20 ticks), and the even part separates the pair | Nothing to add. The bury is the opening that starts a chain (Orb: "a way to set up combo chains") |
| G5 | **The gap between grabs: lockout 90, noRegrab 120** | **Accepted: 180 and 240.** The lockout counts from every attempt, misses included | Three seconds between attempts is still plenty for a grab that sets up chains, and it ends the loop Orb saw |
| G6 | **The hold-break: worth 1.5 throws, and no noRegrab** (my ruling of 2026-11-21) | **Reversed under the switch: worth 1.0, and noRegrab starts,** as for any throw | That bonus made the grab the computer's main answer to a held charge (X-06), and Orb's play shows that answer is the stall. A catch on a wind-up already starts the clinch one ahead, so the bonus paid twice |
| G7 | **The computer's answer to a held charge** (directive: Easy 15 and 40 in 100, Medium 30 and 60, and never a grab answering two holds running) | **Accepted, plus three rules.** (a) **No close-in step:** it grabs only from inside reach. (b) **Of the answers drawn in reach and before full, 35 in 100 are grabs and the rest slip the release and punish.** (c) **Never a grab answering two holds running,** counting its other grab-on-a-heavy path (`grapple.catch`) too. **Hard keeps 0.95**, under the same three rules | Orb's "the computer spams it when I'm trying to charge". The slip is a timing answer: the charge meets nothing and the charger is punished, without freezing the match. Hard waits for a human read, as before |

## 2. Charges: spacing and timing (directive §4, "Charges")

| # | The number | Ruling | Why |
| ---: | :--- | :--- | :--- |
| C1 | **The mid-band lunge: 4,000 units a second, at least 3 ticks** | **Accepted: 2,600 and 8.** From the mid band's edge to where an approach ends (2.5 bh out), travel goes from about 12 ticks to about 18, before the crouch | It makes every mid-band approach readable, which serves Orb's "players never feel lost" as much as the charge. **Said plainly:** against a charge it buys only a few ticks, because the blow's own wind-up dominates. G2 and G7 do the protecting |
| C2 | **The leash: the defender gives ground 2.4 bh** | **Accepted: 4.** Only against a wind-up or a charge, as today | It's the defender's spacing answer instead of a grab: step back out of a charge's reach. It only bites on a charge held past full, since 4 bh takes about 0.8 s at 5 bh a second. So holding to fish costs distance, and releasing on time doesn't |
| C3 | **Once full, only a heavy or a beam stops it** | **Accepted, for every stop:** not a grab (G2), not a quick stick strike's stun, not two quick lights, not a bolt or a blast below a beam. They still hit for their damage through the armour | Spacing and timing: a heavy needs 28 ticks of wind-up, so it only stops a full charge held too long. A beam costs 45 energy. Everything cheap stops a charge only before it's full, as today (a medium before tick 20; a grab before full) |
| C4 | **The timed release: within 6 ticks of full, half a body height further** | **Accepted: `sweetTicks` 6, `sweetReachBh` 0.5** (reach 1.5 → 2.0). The cue is the full flash that's already there: **no new marker** | It rewards releasing on time and pairs with C2: on time it reaches; fished, the defender has stepped away |

**Together:** a charge started with room is safe from everything cheap once it's full. One started at arm's length can still be grabbed or out-timed before it's full. That's the spacing Orb asked for, and pillar 3 still holds.

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
    "bands.lunge.minTicks": 8,
    "brawl.give.leashBh": 4
  },
  "grab": { "reachAtPress": true, "fullChargeProof": true },
  "charge": { "fullStoppedBy": ["heavy", "beam"], "sweetTicks": 6, "sweetReachBh": 0.5 }
}
```

**`ai.json` `grabCharge`** (read by the same switch):
```json
"grabCharge": {
  "set": {
    "levels.easy.brawl.holdAnswer": { "windowTicks": 420, "byCount": [0, 0.15, 0.4] },
    "levels.medium.brawl.holdAnswer": { "windowTicks": 300, "byCount": [0, 0.3, 0.6] }
  },
  "holdGrab": { "closeIn": false, "share": 0.35, "notTwiceRunning": true }
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

**First, a timing table** (Encounter or QA, before the batch; the directive's numbers were never played). For a heavy charge begun at 1, 2, 4 and 8 bh: the tick each answer lands, set against full at 44. The answers: the computer's grab, a medium, a heavy, a quick stick strike, and a mid-band heavy lunge.

**Then the directive's acceptance, with G3's 45:**
- a full charge is never stopped by a grab;
- no grab begins from outside 0.6 bh (a check row over 200 computer matches);
- no two grabs by one fighter inside 180 ticks;
- on Easy, three heavies held in a row are grabbed fewer than 15 times in 100;
- a charge begun at 8 bh completes against a lunge begun on the same tick, and one begun at 2 bh does not;
- match length on Easy and Medium stays in QA's band.

**Two more:**
- **The stall:** clinch ticks per minute at Easy and Medium, at least halved.
- **X-06's one-note bands** (`gauntlet-plan.md`): the charge-only pad at most 80% at Easy and at most 55% at Medium.
  - **This is the risk.** A grab-proof full charge and fewer answers both help a pad that only charges.
  - **If it fails, the levers in order:** first, the slip's share at the third hold (byCount's last entry back toward 0.65 and 0.9, all slips once a grab was used); then `holdGrab.share`. **Never** the grab's reach, and never the grab-proof rule.

**Orb's clip:** the directive's thirty seconds twice, with the buttons drawn. One question: "Does charging feel earned now?"
