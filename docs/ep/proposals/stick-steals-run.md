# Proposal: the stick steals his run

From Orb's stand-in, under Orb's grant of 2026-11-01 ("full authority to visualize a novel feature, structure it in pseudocode, and submit it to executive producer along with an in-depth briefing and purpose"). A proposal for the EP and Game Design. Nothing here is in `sim/` or `data/`, and nobody has played it in the game. The name is a placeholder.

**Try it:** `docs/ep/prototypes/stick-steals-run-v1.html`. Open it in a browser. It works with the pad (right stick, X) or the keyboard (arrow keys, J). Press T to switch the rule on and off.

## Purpose

Make the right stick the answer to mashing, through a rule you can feel, instead of more damage or a shorter wind-up.

The right stick is the idea this whole layout rests on, and today it loses. QA's arm, on the stack with the reel-and-run rule (`docs/qa/cloud-reports/2026-11-01-stack-read.md`):

| Bot | Against easy | Against medium |
| :--- | ---: | ---: |
| X mash | 93% | 23% |
| Stick-only | 20% | 0% |

QA gives the reason: "the stick bot builds no run, and the AI wins every trade break." Game Design has already ruled out the wind-up as the lever (`docs/design/stick-lands.md`), and closes on the stick player went up, not down.

Orb's standing words: "Mashing: fine for beginners; experts should beat it." Today the expert's tool is losing to the beginner's.

## The idea

**A flick that lands turns his run against him.** While he mashes, his run climbs. Land a flick in that moment and three things happen:

1. **His run becomes yours.** He drops to nothing, and you're suddenly close to the stagger that a run earns.
2. **He overreached.** He stumbles for a moment, longer the more he had going. His stream stops, so what you took survives long enough to use.
3. **His own swing carries him.** He goes where you aimed, further the more he had going.

Mash hard and you're handing a good player the fight. It reads like a fighter using an opponent's momentum: a flurry gets longer and wilder, then a single clean turn of the wrist sends him tumbling. Close fights could pass the run back and forth, which is the ping-pong Orb keeps asking for, from a plain rule.

**You have to take hits first.** A blocked light builds no run, so a safe LB + flick has little to steal. The big steal comes from standing in a flurry and picking your moment. That's the risk, and it needs no cooldown or cap, which Orb dislikes.

## The triangle it makes

| This | Beats | Why |
| :--- | :--- | :--- |
| Mash | Slow hands and charges caught early | Fast blows, a beginner's friend |
| Flick | Mash | Steals the run, and he stumbles |
| Guard | Flick | Stands today: a guard beats the stick (`stick-lands.md`) |
| B and Y's chip | Guard | Stands today |

A masher still has fun and still wins against someone who does nothing. He loses to someone who reads him, and he can see why.

## Pseudocode

```
# data/director/stick.json, off by default
steal: { enabled: false, max: 3, stumblePerPoint: 3, carryPerPoint: 0.5 }

on flick_lands(attacker, target, direction):
    # A guarded flick or a stunned target goes through today's rules, unchanged.
    if not steal.enabled or target blocked it:
        today's rule; return

    taken = min(target.run_points, steal.max)

    if taken == 0:
        today's rule   # reel 6, his run down 2, own run 0
        return

    target.run = 0
    attacker.run += taken                         # no bonus for the flick itself
    target.reel = max(target.reel, 6 + taken * steal.stumblePerPoint)
    carry = direction_carry(direction) * (1 + taken * steal.carryPerPoint)
    carry = min(carry, the 4 bh limit that keeps a brawl together)
    move_target(target, direction, carry)
    cue("run_stolen", attacker, target, k = taken)   # pose, sound and pad read this
```

**Small and safe by construction:**
- It uses the run the brawl already hashes, in `sim/director/brawl.gd`. It adds no new state or random draw. With the switch off, every match is byte-identical.
- It changes no lockout or timing, so the claw gate should hold. That gate is still a hard test.
- It lives inside one fight's pair, so it works unchanged in a 2v1 or a 2v2 and over LAN: only the fighter you hit loses a run. The stumble is an ordinary reel, so it doesn't touch the shared clock.

## What it looks like

- **The stolen moment:** his next pose overbalances past his own punch. The flick lands as a clean turn, with the carry reading as his own momentum. Combat and Animation own this.
- **Nothing over the fighters.** The cue reaches the body, the camera and the sound. The prototype's pips are only for the prototype.
- **Knowing when:** the flurry itself is the signal, by pace and by sound. Optionally, a soft pad tick when his run passes 2. Rumble works on Orb's pad, so it's a clear signal that costs no screen.

## What the toy says, honestly

The prototype can run bot fights. They use a flick every 16 to 24 ticks against a drifting mash, with no guards, dodges, positions or real AI, so this is the shape of the rule and not a balance result.

| Rule | Stick bot's wins, of 300 |
| :--- | ---: |
| Today's shape (reel, his run down 2) | 34 |
| Steal only, no stumble | 34 |
| Steal, stumble 1 tick a point | 68 |
| Steal, stumble 2 | 120 |
| **Steal, stumble 3 (first value)** | **168** |
| Steal, stumble 4 | 232 |
| Steal, stumble 6 or more | 300 |

**Two findings:**
- **Stealing alone does nothing.** His next lights take back what you stole before you can use it. The stumble is what makes the run yours, so it's the lever.
- **It climbs smoothly and then runs away.** That's good for tuning, and a warning: past about 4 ticks a point, the stick wins outright in the toy. Real guards and dodges will pull it back, by how much I can't say.

## How to test it

On a scratch stack with `steal.enabled` on. QA's arm is the first check:

| Row | Band |
| :--- | :--- |
| Stick-only against the AI, in wins | Within 10 points of the X mash, Game Design's band |
| Closes on a stick player, against one who isn't | Fewer |
| The masher against the AI, and the newcomer bot | Stays in its band: a mashing beginner shouldn't feel punished by the AI |
| Claw gate | Zero gain |
| Determinism, rollback, field worlds, golden with the switch off | Pass |
| **Orb's hands** | Does a good flick feel like a read? Does being on the wrong end feel fair? |

**If it's too strong,** in this order: stumble per point 3 to 2, `max` 3 to 2, then only steal at 2 or more. **If the AI is the problem:** it mashes steadily, so it may feed the stick too freely. Having it ease off at a high run would also make it look smarter. That's Encounter's call.

**What would kill this:** if a mashing newcomer feels punished by a computer that flicks, or if stick-only becomes the best way to play. In that case keep the AI from stealing first, and re-read it.

## Later, if the first slice is good

- **The pot:** each steal back and forth within a run's lapse raises the stakes, so the blow that finally cashes in sends him further into the scenery. That ties to Orb's note on "perfect responses back and forth escalating into an amplified knockback" and to the duel of perfects already designed. Not in the first slice.
- **Fighters' flavour:** the Protagonist's redirecting art in `docs/design/fighter-pipeline.md` fits this closely, so he could steal more and the rival could take it more brutally.

## Who it needs

Game Design (ruling, and how it sits against "a beginner's mash holds up" in `stick-lands.md`), Encounter (about 10 lines at the flick's contact), Combat and Animation (the overbalance), QA (the arm above), Audio and Controls (the cue, and the optional pad tick).

**For Orb:** it changes how a stick player beats a masher, and only their hands can say if it's fun. Nothing's decided until they've pressed it.
