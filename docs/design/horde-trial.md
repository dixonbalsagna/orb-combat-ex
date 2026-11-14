# Horde: rulings for the first trial (spike S3)

Owner: Game Design. 2026-11-15, on the stand-in's `docs/ep/proposals/horde-trial-design.md`: its 31 departures (§4) and its paper model (§3.11). Orb: "a one or two player co-op horde mode where respawning weak enemies can swarm you", and a first size of three weak enemies at a time ("GO").

**The paper model's warning holds.** With the ruled numbers (a gap of 20, blows of 24 and 48) and a full field, a medium player goes down in about a minute (row A). Those numbers were set for a campaign stage, at 10 to 30% of health over one stage. A run is eight waves, about 621 bodies, on one body. **So the trial runs on new first values, and the old ones are retired for the stand-alone run.**

## 1. The three first

| # | Ruling | Reason |
| ---: | :--- | :--- |
| **1. The gap between a lane's blows** | **113 ticks at medium** (easy 170, hard 68), the model's row G, as the trial's default. **The page's 240 (easy 360, hard 144) is the comparison arm** | A swarm should feel busy. Row G is "twice as busy and half as heavy": about 85 wind-ups a minute against 43, at the same fairness (the medium pad loses 40% of the body alone and 18% with two, against the page's 39% and 20%). The gap is a pacing limit on the pack, one wind-up a lane at a time. It's never a cooldown on the player (`rulings-2026-10-25.md`: the horde's limits are for reading, frame rate and fairness) |
| **2. The weak fighters' blow damage** | **2, 4 and 2** (fodder, bruiser, speedster) with the 113 gap. **4, 8 and 4 with the 240 arm.** The ruled 24, 48 and 24 are retired for the stand-alone run | Weak enemies that swarm hit often and lightly. The threat is many small hits, not a few big ones. A third arm, if the trial has room, is the model's row D: the ruled blows, the 240 gap, **and the whole body given back in each breather.** That makes each wave its own stage. I don't recommend it, because it breaks "the body never refills in a match" and a run could then only be lost inside one wave |
| **3. Does a weak blow reach the deep health in full?** | **Yes, in Horde:** a pack blow that lands takes its damage from the body in full (`down.bodyShare` **1.0**). Parts wear as usual, for the signals | Under the shared loop a hit on a sound part reaches the body for nothing, and weak blows leave parts sound, so a run could never be lost. **Horde's threat is attrition by many small hits,** which is exactly what the body is: the attrition clock (`energy-stamina-body.md` §1). The core's gate is for duels, where parts matter. Simulation adds the key when A3's loop lands. Until then the trial reads the body as the old hit points directly |

**What it should read:**
- the medium pad loses **20 to 45% of the body over the run** (departure 19's band);
- the run is **5 to 10 minutes** (X-10);
- **two or three weak fighters are in the fight most of each wave** alone.

If the arms feel alike, the busier one wins: it's a horde.

## 2. The rest

| # | Ruling |
| ---: | :--- |
| 1 | **Accepted for the trial:** lanes in place of turns (3 at medium and hard, 2 at easy), with 8 ticks between landings, tells that never shorten, and 20 ticks from behind. Orb: "All three, if they are in reach" |
| 2 | **Accepted for the trial:** all three may wind up at a player. Reading 9 has to show it holds |
| 3 | **Accepted:** a full fighter in a re-used slot. A light body is only needed past eight |
| 4 | **Accepted:** in Horde, a body's opponent is its mark, and the players are on one side |
| 5 | **Accepted:** a fighter on their last legs is put down by any pack blow, with no finisher, because a finisher pauses the whole sim (the elite's reason) |
| 6 | **Accepted:** a partner back on their feet has 400 of the body, a quarter |
| 7 | **Accepted:** a downed partner is out until the wave is cleared |
| 8 | **Accepted:** ×1.5 bodies for two players, and nothing else |
| 9 | **Accepted for the trial:** no whole-fight pause in Horde, and a struck pack body holds on its own reel timer. The per-body hit pause stays Orb's question |
| 10 | **Accepted:** within 8 bh of its mark stands in for "in the player's pane". Camera holds a winding body in frame, and reading 13 checks the picture |
| 11 | **Accepted:** the sim frees the place at once, and the fallen picture is removed out of view |
| 12 | **Accepted, after the first version:** the domino, uncapped, until the speed runs out (Orb: "go with your recommendation", "sounds cool"). The henchmen page is updated when it's built |
| 13 | **Kept as a reading:** a wave of 12 fodder falls in 10 to 20 s. **If the trial agrees with the model** (5.4 s, too fast), the fodder's toughness goes up first, after the trial |
| 14 | **After the trial:** the marksman waits for the second step |
| 15 | **Accepted:** the card reads "Alone or with a friend, against waves of weaker fighters." (UI's words) |
| 16 | **Accepted:** the parked ring still applies and isn't used here |
| 17 | **Accepted:** the horde first, since Orb's Alpha answer came after the study |
| 18 | **Accepted for the first version:** a struck body that doesn't fall holds and reels, and a pack blow on a player is a flinch. The grades' own reactions come with the second step |
| 19 | **Accepted:** 20 to 45% of the body over the whole run (§1) |
| 20, 21, 22 | §1 |
| 23 | **Accepted for the trial, and shown in the clip:** a weak fighter's entrance at 3.2 × flat out (11,200) for 16 ticks, under the 3 bh a tick ceiling. It's an arrival from off the fight, not how a fighter flies. **If it reads as popping in,** one of the page's other two ways in |
| 24 | **Accepted:** a press reaches as far as the lunge (17.8 bh at base), at the faster of the lunge and flat out. Past that it's a swing at the air, said. That's pillar 3 as ruled: the gap-closers close within reach, and mashing X never flies the fighter round the field for the player |
| 25 | **Accepted for the first version:** every blow strikes one body. Crowd caps come with the second step |
| 26 | **After the trial:** striking a body that's been sent flying again comes with the second step. **That's the in-air chain Orb asked to explore and enhance, so it's the first thing the second step builds** |
| 27 | **Accepted:** nothing to count for bodies meeting in the first version, and the turns are read as lanes |
| 28 | **Data key accepted; Orb's question later:** the result screen shows how many were knocked out. My recommendation is **yes**: a run needs something to beat. **The words are "knocked out", never a kill count** (RL-257's retired words cover people; this keeps the same tone for fighters) |
| 29 | **Accepted:** a dodge beats a pack blow only as a clean tap, with no other dodge tap in the 30 ticks before it, so tapping through doesn't work |
| 30 | **Accepted:** a pack body is never solid to a player. Three solid bodies could pen a player in, which the agency rule forbids. Solid bodies were ruled for two fighters |
| 31 | **Accepted for the trial:** the signature, the right stick's beam and the grab are refused, each with a said reason. The beam returns with A3's beam in space, and the grab with the second step |

## 3. For the EP

- **Questions for Orb:** not mine to ask. Orb gets two Horde questions now and the rest after the trial's clip, as the EP said. Row 28 (the count) and row 9 (the per-body pause) belong in that later set.
- **The trial's arms, in order:** row G (113, with blows of 2 and 4) by default; the page's (240, with blows of 4 and 8); row D if there's room.
