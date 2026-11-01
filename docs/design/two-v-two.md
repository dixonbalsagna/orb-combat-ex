# 2v2 over LAN: what would make it fun

Owner: Game Design. 2026-11-01. **A design note for Netcode's feasibility check, and for Orb. It isn't a decision, and nothing here is built or played.** Orb's idea: "a 2v2 co-op versus over LAN for my PC and the older PC on the network, both have controllers", with each player having their own "record" for the planet and which opponent they're focused on, and the D-pad as a candidate for switching focus.

**Short answer: it's worth doing, because a planet makes 2v2 unlike any other fighting game's. Start with the two of you against two AI, on a smaller planet. The hard part isn't the buttons: one hit-stop freezes the whole sim today, and the world has one line.**

## What makes it fun here

In order of how much they're worth:

1. **The rescue.** Your friend's in trouble on the other side of the world, and you fly there. It's the best reason yet to fly flat out. You see their fight coming over the horizon and arrive with a blow.
2. **The pass.** You send your opponent across the planet, into your friend's fight. It's a launch with somebody waiting at the other end, and your friend can hit him as he arrives.
3. **"I'll take him."** Swapping opponents mid-fight, because yours has your number or theirs is nearly done.
4. **Two on one.** For a while, one fight is won and that pair turns on the last enemy. It's frightening from the other side, and the last stand (feature 23) is there for it.

## Who plays

| Order | Who | Why |
| ---: | :--- | :--- |
| **First** | **Two humans against two AI** | It's what your two PCs and two pads give you. It's friendly, it tests all the netcode, and the AI only has to fight, not cooperate. Nobody loses to a teammate's lag |
| Second | A human and an AI against a human and an AI | The same code, but the AI needs to be a teammate, with the campaign's one order: stay close or go ahead |
| Later | Four humans | It needs four machines or a split screen, so it's for later |

## Focus

**Focus is who you're fighting. It should almost never need a button.**

- **It picks itself:** whoever you last hit, otherwise whoever's nearest in front of you. **A blow with the stick toward someone goes to them,** as one-versus-many already rules. Being hit by someone new doesn't change it, so nobody can steal your camera.
- **What it decides:** who your attacks close on from far away, who your camera frames, and who your brawl's magnet holds. It never decides your guard, which works against everyone.
- **What the rest of the time looks like:** one partner in your brawl, and anyone else lands single blows on your openings. Stages 2 and 3 of one-versus-many are built and parked, and that rule's already been measured, so this doesn't start from nothing.

**The button.** A press moves focus to the next enemy, and it can go to your partner's opponent on the far side of the world, which is how you start a rescue.

**The D-pad and its mirror.** By rule R32 the D-pad mirrors the right stick, but **that's a setting, off by default,** and on by itself only for a pad with no right stick. So:

| | Switch focus on |
| :--- | :--- |
| **Mirror off, nearly everyone** | **D-pad left and right.** D-pad up is a free "I need you" call, a voice line and a mark on the map |
| **Mirror on** | **The Back button,** since the D-pad's taken and such a pad may have no stick to click. Hints move to the pause menu in 2v2 |
| **Keyboard and remapping** | A key of its own, and swappable, as with everything |

**The claw law applies.** A D-pad press takes a normal left thumb off the stick, and a claw grip doesn't lose that. So a focus press must be worth little in the moment: focus eases over about 12 ticks rather than snapping, and it gives no blow. The claw bot checks it. Since focus picks itself, the press should be rare anyway.

## When the pairs split up

**Does your friend's fight stay readable? Not in detail, and it shouldn't try to.** On two PCs, each player has their own screen, which is a big help: no split. Your screen shows your fight. Your friend's reaches you through what the world already does:

- **The map** (`game-design.md` §11), with all four as points and their trails. It's the one thing on screen.
- **Your friend's plate at the edge:** health and tier, small, and clear of the fighters.
- **Sound and rumble:** their landings as a delayed boom (feature 6), and a line of voice when they're on the brink.
- **The world itself:** their flight line and a meteor's trail, which are real and visible from afar. If a meteor goes up behind your fight, you see it.
- **Your camera is never taken from you.** No cut-aways, no inset forced open, and no marker over anyone. When all four are close enough, the one picture holds them, and it splits back as they part.

## Assists, rescue, swaps and finishers

| | First version | Why |
| :--- | :--- | :--- |
| **Rescue** | Arrive with a blow, as the campaign's interjection: it lands on whoever your friend's fighting, and the brawl goes on | Already designed and parked |
| **The pass** | A send's score gains a small term for your partner's position, and the stick's vote wins as usual. Your partner's hit as he arrives counts as a normal blow | Cheap, and it reads no person |
| **Swapping** | Just focus and flying. No special move | Keep it simple until it's been played |
| **Assists** | None at first | A called-in assist is a different game, and rescue is the better version of it |
| **A finisher** | It stays between those two, and the other two fight on. **A partner's blow can break it,** at the cost of whatever they were doing | The best rescue there is |
| **Out** | A KO'd fighter's out for the match, and the team loses when both are. No revive at first | The campaign's rule is close. It keeps the first version honest |
| **Shared limits** | Each pair has its own "one big set piece every 20 s". Three planet-scale launches a match, per team | Otherwise one fight's show blocks the other's |
| **Toll** | Shared, with no per-player count on any screen (Legal mc02). Anguish stays the hero's cost | As ruled |

## What it takes from the pillars

- **Pillar 1, the planet is the arena: it gives up the turntable while the pairs are apart.** The world has one line, and a swing turns it round the pair. Two fights can't each turn it. **So in the first version all four stay on one line. Swings and nudges rest while the pairs are apart, and run again when everyone's together.** You can still fly either way and loop the planet. Each pair having its own line is what Orb's "own record" would really need, and it's the big prize, but that's a Simulation question, not a first step. This is the biggest thing lost.
- **Pillar 2, the player's stance and the director's choreography: it gives up some certainty.** A third fighter's blow can break your string, so a phrase you've learned isn't guaranteed, and the director has to choreograph what's really happening. It also has two brawls to run at once. Timing and worth don't change.

## What it needs that isn't there

For Netcode and Simulation's check, in order of how worrying they are:

1. **Hit-stop.** Today, **every hit-stop freezes the whole sim** (`feel-core.md`). With two fights on two screens, each would stutter on the other's blows. **It has to become per pair when the pairs are apart.** It's the one change without which this isn't playable, and it touches a lot.
2. **Two full brawls at once.** Research's old study found that's the costliest thing, and the campaign's first build avoids it. The older PC is the budget.
3. **Rollback with four bodies,** across two PCs, with the same lag for both.
4. **Lots of far buildings** (`places-everywhere.md`), if a far pair is breaking a town the other screen can't see.
5. **The signature's pause and a finisher's camera:** they can't hold up the other pair.

## The smallest version worth playing

Two PCs, two pads, two humans against two AI. **A Half ring,** so a rescue's about 4 to 8 seconds away. All four on one line, with no swings while apart. Focus picks itself, with the D-pad as override. Rescue by flying in, per-pair hit-stop, the map and the plate. No assists, no revive, no pass at first, and no meteor.

**What it answers:** when your friend calls, do you drop your fight and fly? And is that the best moment of the match? If so, the rest is worth it.

**It doesn't touch the first playable,** and it should wait until the arena and the pad are in Orb's hands.
