# Authoring deep pools of martial arts moves

Research & Prototyping, 2026-11-01, on Orb's ask (end of `docs/ep/vision.md`): deep pools of unique moves, tied to a damage type, swappable, with lore-driven significance, following rule of cool, and graded on several levels including knockback force and the ratio of ki to physical force.

**My recommendation: write families and rules by hand, and let the generator fill them. Start with about 50 moves, not hundreds.** Each move gets six grades that must add up to zero, so every strength is paid for and no fresh fighter is behind. Each also gets a ki-to-force ratio that changes what the move *does* rather than how strong it is, and one rule-breaking twist, which is where the rule of cool lives. How this fits the hybrid and versus is Game Design's, and the budget here is meant to serve it.

**How far to trust this.** The sources were reviews, guides, forums, two short studies and book listings. They show patterns and don't prove anything, and searches on some topics came back thin. The pool sizes and day counts are my estimates. Nobody has played this.

## 1. How large move sets are organised

**Real martial arts sort moves more than one way at once.** Judo splits its throws into families by the part of the body doing the work (hand, hip, foot) and by method (a sacrifice throw, say), and groups pins and chokes apart. So a move has an address, which makes hundreds learnable. Karate teaches basics, then set forms, then sparring, and one school sorts its forms by fighting distance. **So families can be crossed: what it uses, what it does, how far away.**

**Games do it in four main ways:**

| What the game does | What it teaches us |
| :--- | :--- |
| A martial arts game with three starting schools: each move starts and ends in a stance, and you can learn moves from other schools by surviving them | Schools give you an identity to start from and to stray from. Where a move ends matters as much as what it does |
| A kung fu game built on one real style: the team chose a list of moves, then filmed and hand-keyed a performer's reading of each | Few moves, and each one rich |
| A big action RPG where a weapon's special skill is swappable, and a swap can add a damage type and shift what the weapon scales with | Swapping *what it does* separately from *what it is* multiplies variety cheaply |
| Loot games with random stats. Players of one complained that items with too many stats were confusing and dull, and that random stats on special items made them stop feeling special | Random numbers don't make things unique. A special thing has to stay fixed to what makes it special |

**What makes a move unique rather than a reskin.** Not its numbers or its colour. A move is new if it changes **what happens next**: where he ends up, what you can do now, what the place does. **My test: can a player say when they'd pick it without quoting a number?** "Good for knocking him into a wall" passes, and "8% more damage" fails.

**The structure I'd use: three levels.**
- **School:** a way of fighting, with a lean toward ki or body. It's where lore attaches.
- **Job:** what the move is for: send, stun, break guard, move him, launch, linger. Six jobs at most.
- **Move:** a body shape from the generator, grades, and one twist.

**Damage type: four, kept simple.** Each decides what the hit does to him and the world, and none is a rock-paper-scissors chart that a player has to learn:

| Type (working words) | What it does |
| :--- | :--- |
| **Impact** | Moves him. Breaks structures |
| **Pierce** | Gets through a guard. Moves him little |
| **Shock** | Stuns him and wears the limb it hits |
| **Burn** | Lingers on him or the place, and reacts to trees and water |

## 2. The grading sheet

| Grade | Felt by players? | How |
| :--- | :--- | :--- |
| **Knockback force** | **Yes, the most** | How far he flies, and how hard he hits what's there |
| **Speed** (wind-up) | **Yes** | Whether it lands first |
| **Reach** | **Yes** | Whether it lands at all |
| **Stun** | **Yes** | What you can do next |
| **Guard damage** | **Yes** | Whether blocking is safe |
| **Worth** (damage) | Partly | Only big differences, and over a match |
| **Ki-to-force ratio** | **Only if it's drawn and does something** | See below |
| **Launch angle** | **Yes,** it's visible at once | Up, across or down |
| **Place reaction** | **Yes,** and it's the most memorable | Water, trees, a wall, ice |
| Hit-stop, sound, camera | **Yes, without knowing why** | One small study found these shape how hard a hit feels. Set by family, never shown |
| Recovery, ki cost, wear on buildings, region hit | Experts | In the data, shown in training |
| Legal's flags, flash weight, animation cost | No | The builder's use only |

**The ki-to-force ratio.** One number: how much of a blow is ki. To be worth grading it has to change something you can see and use, and not be another damage number:
- **Mostly force:** dust, ground cracks and a deep thud. More knockback, more wear on buildings, and it's stopped by a guard.
- **Mostly ki:** the limb lit in the fighter's own colour, a higher sound. Less knockback, but gets through guards more, costs more ki, and reacts more to the place.

**Six grades trade against each other,** each from -2 to +2, and **each move's must add up to 0.** That's Game Design's "every combo spends the same budget", made checkable by a machine. It's what lets a fresh custom fighter face a roster fighter with minimal disadvantage: nobody's move is simply better. The ratio, angle, type, job and place are outside the budget, because they're differences and not strengths.

**How many is too many.** Players should see **five grades as a simple bar, plus one sentence and a four-second clip.** I'd keep about twelve in the data and never show more than five at once. Past that, it's the "confusing and dull" problem from section 1.

**"Graded on multiple levels".** I read that as the many grades above. An upgrade should add a choice, as Game Design says, rather than raise a grade, or the budget stops holding. In the campaign alone, real growth is fine.

## 3. Authoring at scale with no budget

**How many are needed.** A player holds three combos at a time, and in the combo paper is offered about one set of three per planet. So one player might see 30 to 50 options across a long campaign. My estimate:

| Size | Enough for |
| :--- | :--- |
| **About 50 moves** (3 schools x 6 jobs x about 3) | A first release that feels deep. Two-part combos multiply this into hundreds of possible pairs |
| About 100 | Several long campaigns without repeats |
| 300 or more | Collectors only. Past that they blur together, and each needs testing |

**We start from a strong place.** There are already 135 posed strike key sets, covering 95 different strikes, and the generator knows 193 body shapes. When it was first measured, changing just a hand's shape or a move's aim nearly doubled what was reachable from existing poses (35 to 69 for one fighter, 37 to 73 for the other). The generator also already refuses shapes Legal has banned and checks its output.

**The method.**
1. **By hand:** the schools, the jobs, and the rules of each (what a Shock move in this school tends to be).
2. **By hand:** about a fifth of the moves, the showpieces, each with new poses.
3. **By generator:** the rest, from existing poses, with hand shapes and aims changed, and numbers from the budget. Ask it for about three times what you need.
4. **By machine:** the budget, Legal's rules, and no two moves too alike.
5. **By a person:** five minutes each on a clip. Keep the ones that pass the section 1 test, and give each a twist and a name.

**What feels hand-made is the twist, the name, the sound and the place reaction.** None of them needs new poses. Sound and effects belong to a family, so one good sound serves ten moves.

**What one move costs, my estimate:**

| Part | Reused body | New body |
| :--- | :--- | :--- |
| Animation | None, or a re-aim | Three poses. About a third to half a day, going by Animation's own estimate of 6 to 8 key sets in 2 to 3 days |
| Data | A generated row | The same |
| Legal's pose rules | Automatic against the banned list | **A screen of each new pose. It's the slowest part** |
| Flash | **Tested by family, not by move,** which is the big saving. A new effect needs its own reading | The same |
| A person's time | Five minutes, plus the name and twist | About the same, plus a look on a clip |

So 50 moves with 10 showpieces is **about one to two weeks of Animation's time** plus Legal's screen, and few other costs. New limbs will cost more: elbows, knees and shoulders are thin in today's poses, and every family needs some.

## 4. How lore attaches, with templates only

**Orb writes the universe, so these are empty forms.** Nothing below is lore. Bracketed parts are Orb's to fill, or to throw away.

**A school:**
> [School] was founded by [who], in [place]. It believes ki is [a belief], so it fights by [a habit]. It forbids [one thing], because [what once happened].

**A move:**
> [Move] was first used to [an event]. [Teacher] teaches it only to those who [a condition].

**How that becomes play,** without inventing any facts:
- **A teacher offers it.** The form above is the line they say.
- **The school's home is a place on the planet.** A school's moves can react more strongly there. A planet's fixed places are already data, so one can be named.
- **Keeping to a school** could give a small named effect once all three combos match, as a reason to stay. **Straying** should be just as valid.
- **Rivals notice it:** "You fight like [school]." One line, from a slot.
- **Rule of cool:** a forbidden move can be a little wilder, and costs something visible.

Names go through Legal's list and Narrative. Nothing should claim to be a real martial art or a real school.

## 5. What fails, and the guard

| What fails | How it shows up | The guard |
| :--- | :--- | :--- |
| **A dominant move** | Everyone picks it | The zero-sum budget; the pick and win tracking from the combo paper; rivals who learn your favourite |
| **A useless grade** | Speed is everything, so a -2 in speed is never picked | The numbers behind a grade are tuned on real fights. A -2 must never be a trap |
| **Unreadable stats** | Players pick by the pretty clip, or they look it up | Five bars at most; one sentence; a clip |
| **Grade inflation** | New moves are always a bit better, so old ones die | Zero-sum forever. A new move can only be *different.* Any "rare" tier is about rule-breaking, never strength |
| **Reskins** | Fifty moves that play as five | The section 1 test. Cut hard, and ask for three times what you need |
| **A numbers chart to memorise** | Type against type | No chart. Types do different things, and none is "strong against" another |
| **Too wild** | One twist breaks the fight | One twist a move. Each runs through the same automatic tests |
| **Lore that binds the game** | A good move can't exist because the story forbids it | Lore is written after the move works |

## A worked example: five moves

**All placeholders.** The names are working labels, not proposed names, and the numbers are examples. None of the bodies has been through Legal or been drawn, and [School A] to [School C] are blanks.

| | Shoulder Door | Thin Palm | Long Reap | Banked Knuckle | Rising Elbow |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Job** | Send | Break guard | Move him | Linger | Launch |
| **School** | [A] | [B] | [A] | [C] | [C] |
| **Type** | Impact | Pierce | Impact | Burn | Impact |
| **Ki share** | 10% | 70% | 0% | 50% | 30% |
| **Knockback force** | +2 | -2 | 0 | -1 | +1 |
| **Speed** | -1 | +1 | -1 | +1 | -2 |
| **Reach** | -1 | 0 | +2 | -1 | -1 |
| **Stun** | -1 | 0 | +1 | -1 | 0 |
| **Guard damage** | +1 | +2 | -1 | +1 | +1 |
| **Worth** | 0 | -1 | -1 | +1 | +1 |
| **Adds up to** | 0 | 0 | 0 | 0 | 0 |
| **Launch angle** | Flat | None | Low, toward you | None | Steep |
| **Place** | Into a wall, he sticks for a beat | Over water, a mark runs across the surface | On ice or marsh, he slides twice as far | In trees they catch; over water, steam | Under a bridge or ledge, he ricochets back down |
| **Twist** | Goes through a thin wall | Passes a guard's first block | Pulls him toward you, not away | Your next blow within half a second bites harder | Hold longer to pick a steeper angle |
| **Body** | Shoulder, line, chest | Blade hand, line, gut | Shin, low arc, legs | Fist, line, chest | Elbow, rising, chest |
| **Poses** | 3 new | Reused | Reused | Reused, new light | 3 new |
| **When you'd pick it** | To put him through something | When he won't stop blocking | To drag him where you want him | To reward a fast follow-up | To start something in the air |

**One thing this example shows:** the two moves with new poses are the two that most need a body of their own, which is how the one-in-five showpieces should be chosen.

**Sources.** Reviews, guides, forums, two studies and book listings found on the web, 2026-11-01. The list went to the EP separately, so no game names appear here.
