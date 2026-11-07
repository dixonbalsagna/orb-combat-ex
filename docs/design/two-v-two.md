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

## Rulings for the build (2026-11-01)

Orb's order is versus on the globe with the structure tuned for LAN co-op, the two of you against computer fighters first. These replace anything above where they differ. **The half-size ring is being dropped if Simulation's number allows,** so this is written for the full globe. First values, unplayed.

**The clock.**
- **One fight's hit-stop doesn't freeze the other.** A hit-stop holds only the fighters in that exchange. The world, shots, mines and everyone else run on. That includes the signature's pause and a transformation's: they hold that pair and take from that pair's budget.
- **This is only for more than two fighters.** A 1v1 keeps today's whole-sim hold, byte for byte, so nothing in versus moves.
- **A blow that reaches someone held lands the tick he's free,** so a hold can't be broken into or dodged out of.
- **It's the same whether the pairs are close or far,** which is one rule rather than two. Each body's held ticks are hashed.

**Can a blow hit the other fight? Yes, every blow can reach any enemy, and never a partner.**
- **Blows:** one partner in your brawl, and any other enemy in reach takes **single blows on his openings,** one-versus-many's measured rule. All striking freely measured unplayable, so that limit stays. "One stun a string" counts across a team, so two fighters can't chain a lock.
- **Shots, lobs and bursts** hit any enemy they meet and pass through a partner. **A beam** hits the first enemy on its line, and a partner's safe.
- **A beam struggle stays two fighters.** A third's shots are eaten, and their beam does nothing to the point in the first version.
- **A sent body** passes through other fighters, unless a partner catches him with a blow (the pass).

**What brings the fights together on a full globe.** Distance isn't the problem: halfway round is 76,800 units, about 5 to 6 s flat out at the sim's real speed. **What's needed is a reason, not a shorter road.** All soft, and never a teleport:

| | The lever | First value |
| :--- | :--- | :--- |
| **The sends** | With the pairs apart for a while, a send scores the direction of the other fight, for everyone, computer fighters too. A few sends bring them together | After about 60 s apart, up to the sixth of a loop per send |
| **The brink** | A fighter on the brink calls: a voice line and the map. **It's the rescue's cue.** A computer fighter's partner comes too, so a rescue can be raced | On the brink's first moment |
| **Winning** | Whoever finishes first flies to the other fight, with no input needed for a computer fighter | At once |
| **A press** | Focus on the far enemy and a held press pursues, and the long strike (map row 3) pays for the arrival | |

**QA's rows:** all four within about 15,000 units for 25 to 50% of a match, and 2 to 4 rescue flights a match. If the fights never meet, this is two 1v1s, and that's the failure to watch for. **All on one line stays,** with swings resting while the pairs are apart, as above.

## Hits across fights (2026-11-02)

For Simulation's build of two fights on one globe, behind its switch. First values, unplayed. **A 1v1 doesn't change.**

**1. Who strikes across, and when.**
- **Your focus picks the target.** Focus works as above: whoever you last hit, else the nearest in front, and the stick toward someone moves it. If your focus is in a fight with your partner, your attack press is **a single blow from outside,** not a way into their brawl.
- **It lands only on an opening:** a stagger, a stun or daze, the open time after a whiff, the recovery after his own blow, or a beam's stuck time. If he's open as you arrive, it lands. If not, you hover in reach and it lands on his next opening inside 0.5 s. If none comes, it's a whiff, and you're open for 20 ticks like anyone. **Outside a brawl, that whiff is an opening to every enemy, not just a pause in your own line:** no guard for those 20 ticks, and any enemy's blow then counts as landing on an opening, including the one you swung at.
- **His guard works against everyone,** whoever's focus he is.
- **One blow from outside per opening, for your whole team.** So two partners can't both hit the same opening.

**2. What it does to the fight it lands in.**

| Lands on | What happens |
| :--- | :--- |
| **A fighter landing a finisher** | **It breaks the finisher.** His victim is free, still on the brink, and the finisher's lost. It's the best rescue there is, and it costs you whatever you were doing |
| **A fighter in the middle of a string** | **His string ends.** A blow he'd already thrown still lands, as the brawl's rule says. His run is gone, so your partner's free |
| **A fighter your partner is stringing** | Damage and a reel only. **It adds nothing to your partner's run or close** |
| **Anyone** | **No send, no knock-back,** and no stun of its own. A send from outside is the pass, and that's not in the first version |

- **One stun a string, across a team:** once he's stunned, nobody on your team can stun him again until he's been free of all your team's blows for a string's lapse (24 ticks). So partners can't take turns locking him.
- **The blow's own hit-stop** holds only the striker and the fighter struck, and their own exchange. The other fight runs on.

**3. Shots from outside.** As any shot: it hits the first enemy it meets and passes through a partner. **Guard, dodge and the deflect all work, whoever fired it.** It's still energy spent, and a shot that hits a brawler mid-blow lands, since he isn't guarding.

**4. A beam stops at the first enemy on its line,** even if he isn't who it was aimed at, and passes through the shooter's partner. **Whoever is first on the line when the front's coming gets the warning,** from the moment he's first. So diving onto the line (Cover your partner) gives you less time, and that's the price of the rescue. A beam struggle is still between two fighters: whoever fires back. **If that's an enemy from the other fight, the struggle moves him into the shooter's fight,** for its length, since the struggle is the game's big shot and the rescue earns it. The shooter's own foe is left free. No outside blow lands on either of the two while it runs. When it ends, the fights form again by focus, which usually means the two have swapped opponents.

## Encounter's three questions (2026-11-02)

1. **Should a human winner's focus move across by itself?** **Yes, once the finisher has played out and he's had his moment standing in the wreckage,** easing over about 12 ticks. A held press then pursues. The stick toward someone still overrides. Focus never needs a button, as ruled.
2. **A rejoined 1v1: where does wear start?** **Where it stood, for both,** as you'd keep it. The brink isn't reset.
3. **Do the sends pull while it's two on one?** **No,** as you say. The fights have already met.
4. **The winner between his KO and joining the other fight** (Simulation's `cross-end.md`): **he never waits with half a kit.** During his winner's moment, up to the 2.2 s, he can't act, and nothing from outside lands on him. After that he has everything back at once, forms, the last stand and the rally included, with nothing gated on a KO that's done. If he can be hit, he can answer.

## Ready for QA's read: the two on one (2026-11-02)

Encounter's two-match smoke: all four within 15,000 for 36% of a match (in the 25 to 50% band), 4 rescue flights a match (just over 2 to 4), **12 to 14 minutes a match, and 127 blows from outside in one.** No action until QA's 60. This is what I'll look at, and the levers I'd reach for.

**What I want from a two on one:** it's the endgame, and it should be frightening and short, with a real chance of a comeback.

| Row | First band |
| :--- | :--- |
| Time from the first KO to the end | Median at most 90 s |
| The lone fighter wins from two on one | 10 to 20% |
| Blows from outside while two on one | Read, no band yet |
| **A 2v2 match's length** | **8 to 12 minutes, with the time cap at 14:00.** It has two fights in it, so 1v1's 11:00 is too short. The ending's rungs apply to each fight, and the cap puts all four on the brink |

**If the lone fighter is simply overrun:**
1. **The last stand** (feature 23) is for this: he gets it when he's alone, if he hasn't already.
2. **Blows from outside on a lone fighter count half** for wear. The one opening each still stands.
3. **Never** a cap on blows, and never a pause.

**If two on one drags instead:** the lone fighter's brink comes sooner, and a finisher on him can come from either enemy.


Two PCs, two pads, two humans against two AI. The full globe if Simulation's number allows it, where a rescue's at most about 5 to 6 seconds away. All four on one line, with no swings while apart. Focus picks itself, with the D-pad as override. Rescue by flying in, per-pair hit-stop, the map and the plate. No assists, no revive, no pass at first, and no meteor.

**What it answers:** when your friend calls, do you drop your fight and fly? And is that the best moment of the match? If so, the rest is worth it.

**It doesn't touch the first playable,** and it should wait until the arena and the pad are in Orb's hands.

## Co-op calls (2026-11-07, on `docs/ep/proposals/co-op-2v2.md` §5 and §8)

**1. The arrival: the long strike across fights.** Flying to your partner's rescue is the best payoff flight has, and Orb asked for flying to pay off. So it's the long strike, not a plain blow from outside, with one exception to the outside rules.

| | Ruling |
| :--- | :--- |
| **What counts as an arrival** | The long strike as `rule-of-cool-map.md` row 3 has it: flat out with LT held toward an enemy of the other fight, then B or a right-stick flick. A press from outside that isn't flat out stays a plain blow from outside, as before |
| **Where it lands** | **Only on an opening,** as every outside blow does. The defender has seconds and a visible line to answer, which is the long strike's design |
| **What it does** | **It keeps its speed on arrival and sends up to ×1.25,** in the direction he was flying. **It's the only blow from outside that sends,** once a flight. Every other outside blow is still no send and no knock-back |
| **A miss** | The long strike's whiff: he carries about 1 s past, and he's open |
| **Afterwards** | Who's in which fight goes by `fight-swap.md`, unchanged. The arrival moves bodies, not the rules of pairs |
| **The flight is read at the press** | Stored in a `dirI` slot inside `takes()`, before `_toward()` zeroes it, as the proposal says. Both PCs play it through the striker's `arrival` cue |
| **The striker is held with his hit** | A send's pause is 12 to 14 ticks. A striker flying on through a frozen target is the weightless look Orb would spot first. So **the arrival needs the body clock, or that one case of it,** before Orb plays it (see 3) |

`playable-build.md`'s "from outside another fight" row now points here for the arrival. QA's rows: 2 to 4 rescue flights a match stands, and **at most half of arrivals miss.** If more miss, openings are too rare for it, and it comes back to me.

**2. The Unison line: the pick is still open, and it's Orb's.** `systems-sketch.md` §3 asked Orb "Tandem, Unison line, both, or something else?", and it was never answered. `modes.md` wrote both in as if they'd been picked, which I've corrected. **When it goes to Orb, I'd recommend Unison later, not in the first co-op builds.** It's the one beam two people fire together, which is co-op's showpiece. But it needs a struggle of three, re-rules the two-fighter struggle and the equal push, costs about 6.5M, and goes to Legal near fusion. The arrival and the relay are cheaper, and they test whether co-op is fun first. **Tandem's own question is now partly Orb's pride kit:** the Anti-hero's choice between pride and help may already live in his forms, so Orb's pick should cover whether Tandem survives it.

**3. A13: holds per fight, accepted for the first match.** The first match is there to find out whether co-op is fun. A body clock at about 2M before anyone has played is the wrong order. A plain outside blow's pause is 2 to 8 ticks, which is small enough for a first try. **But the body clock, or its one case of holding the arrival's striker with his hit, comes before the arrival is played** (1 above). If Orb notices outside blows feeling weightless in the first match, it comes sooner.

**The cradle and the brace** wait on Orb's word on friendly fire, which the EP is asking for. Nothing from me until then.
