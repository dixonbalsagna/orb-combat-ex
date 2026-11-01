# Answering a beam

Owner: Game Design. 2026-11-01, with Combat's notes (`docs/combat/beam-answers-moves.md`) and Controls' fit check (`docs/controls/beam-answers-input.md`) folded in. For Orb's order: "there should be a brief window where the second player can dodge, powerful block, or fire a beam of their own. In addition, walking into the beam, swatting the beam away, anything else cool we can do." **Paper only. Nothing here is played, and every number is a first value.**

**In short.** Every beam now comes from the right stick, and so does firing back. Everything else is your left hand: tap LT to dodge, or press LB as the beam arrives, and the left stick decides what that press does. Still, you block. Up, down or back, you swat it there. Toward, you walk into it. It's one press and one timing to learn. Only firing back leads to a beam struggle, and only a won struggle can send the other fighter flying, which is why people will keep choosing it.

## Where the buttons go

| | Ruling |
| :--- | :--- |
| **The signature beam** | **RT + right stick.** Hold RT, then flick or hold the stick, and it charges for 0.8 s and fires at him, always. Direction doesn't aim it, because it can't miss by aim. 45 ki, as now. With too little ki, the pad tells you. A flick is needed, so nobody fires it just by charging when a beam arrives. This replaces the one exception I'd left for RT + B |
| **Every other beam** | RB + right stick, unchanged. Flick for a quick shot, hold for three levels, let go to fire |
| **RT + B, my pick: the power blow** | **Pay energy instead of waiting.** B's big charged blow reaches its flash in 0.4 s instead of 0.73 s, for 15 ki. B stays what you've asked for: heavy, focused and hitting one thing. Every fighter has it from day one, with no new moves to make |
| **RT + B, the other choice** | A fourth special move for each fighter, always a heavy blow. It's more character, but it's content, so it can't come first |
| **In the first playable** | RT + B is the plain B, with no hint, like the other specials, until you've picked |

## The window

The beam leaves his hand, and you have until its front reaches you. A signature gives 0.8 s of charge you can see, then at least 0.6 s of travel, and at most 1 s from anywhere on the planet. Levels 1 to 3 give 0.17 to 0.3 s of travel at close range: those are reads off his charge, not reactions, which is fair for smaller beams. **Beams are short:** levels 1, 2 and 3 last 0.33, 0.6 and 0.9 s once they arrive.

| Time before the front arrives | What counts |
| :--- | :--- |
| All of it, and during the signature's charge | Fire back. Start the charge during his lit hand and you can even reach level 3 |
| Last 0.3 s, up to a moment after | Dodge |
| Last 0.2 s | LB's press: block, swat, or the timed walk |
| Any time | Holding LB takes guard damage. Holding LB and pushing toward him is the plain walk |

**None of them work while you're stunned or thrown.** A beam at a stunned fighter is a good read by the shooter. **The quick beam** (a flick with RB) can't start a struggle: dodge it or guard it, and a charged beam cuts straight through it. **A right-stick flick with no shoulder stays a strike,** beam or no beam, so it never means two things.

## The first set, for everyone

**Fire back, dodge, block and swat,** as Combat recommends. **Walk comes straight after,** because it needs beams that run longer.

### 1. Fire back
- **Press:** RB + right stick toward him (level 1, at once, and any charge you've got adds to it), or RT + right stick for your signature. You can't guard and fire back at once.
- **See:** your beam leaves your hands, the two fronts meet between you, and the struggle starts where they meet. Answer late and they meet near your own hands, up to 30% past the middle, and your own ground gets scoured.
- **Pays:** 40 ki, or 45 for the signature, which starts slightly ahead. The struggle itself costs nothing.
- **Risk:** you can lose it: the whole of his beam and half of yours, and you're thrown. No ki means no answer, and the pad tells you.
- **Beaten by:** keeping the beat better. Mashing doesn't help.
- **Point blank:** he kicks back about 9 body heights while charging, so there's a real gap and a real meeting.
- **Across the planet:** the fronts could meet far from both of you. **Camera has to say if it can hold that.**

### 2. Dodge
- **Press:** LT tap, with the left stick for direction. It has to go up or into depth, since a step along the line can't clear it. Keep LT held and it becomes the sprint at him.
- **See:** you're off the line, and the beam goes past and carves on behind you, so **everything behind you pays.**
- **Pays:** the dodge's usual cost.
- **Risk:** too early and it hits you. And you've let it through to whatever's behind you.
- **Prize:** he's stuck for the rest of the beam. **Fly at him and hit him.** Your blow closes the gap at its usual price, so "slip and close" needs no rule of its own. It's worth most against level 3 and a signature.
- **Beaten by:** his sweep, once beams can be steered, or cutting it short with LT.
- **Point blank:** you can land at once. **Across the planet:** you get away clean, but you can't reach him in time, so it's only safety.

### 3. Powerful block
- **Press:** a fresh LB press in the last 0.2 s, with the left stick still. (A toggled guard counts too, so that style can play it.)
- **See:** you stop the front on one plated forearm or a shoulder, and plough backward on both feet. It parts around you for as long as it lasts (Hem Sweep doesn't: see the table). **Behind you, a clean wedge is left untouched, with scars either side.** A hero in front of a town with the town unburnt in his shadow is the picture.
- **Pays:** no ki and no damage. The scars are the cost.
- **Risk:** low. Miss it with LB still down and you take guard damage.
- **Prize:** when it ends, he's stuck for another 0.2 s. It's a small opening.
- **Beaten by:** nothing he does, except making you guess when it'll arrive.
- **Point blank and across the planet:** the same, and a longer flight is easier to time.

### 4. Swat it
- **Press:** the same LB press, with the left stick **up, down or away.** The stick is read as the beam reaches you. **You aim it,** with no assist, lock-on or highlight toward a town. The AI swats by a fixed rule that reads terrain and standing buildings, never people. This replaces my right-stick swat and the old rule where the game picked: see below.
- **See:** you knock the beam aside. **Up:** into the sky, the free one. **Away:** over your shoulder, and it carves whatever's there. **Down:** it hits the ground at your feet. **On the ground, down is where the ground answers** (below).
- **Pays:** 10 ki, because it's worth more than a block.
- **Risk:** the same timing as the block. A miss with LB down is guard damage, and you've spent nothing. What it carves is on your account, and it earns nothing a beam wouldn't.
- **Prize:** his beam ends at once, and he's stuck for 0.5 s.
- **Beaten by:** your own timing, and by a wide beam: against Breakwater, you only knock the middle away and the edges run past you.
- **Point blank:** down makes a crater between you. **Across the planet:** the same, but the prize is out of reach.
- **In 2v2,** a swat hits any enemy on its line, so you can swat it into your partner's fight.

**No "swat it back" at him.** Toward is the walk, so there's no return. That also stays clear of what you ruled out.

**Why I changed from the right stick.** A right-stick swat would have made a plain flick mean something else for a fraction of a second, an early one would have lunged you into the beam, and a miss would have been a full hit. On the left hand, it's one press, the claw grip gains nothing, and the left hand alone can play every answer except firing back. **The price is that it's less of a gamble, so it's priced in ki instead.** It's on your list below, as the EP's packet showed it the other way.

### 5. Walk into it (straight after the first set)

**Yes, a beam being walked into runs longer.** Without that, a real walk covers a body height or two before the beam ends, and the old rule, a cut straight to the arrival, isn't the picture you asked for.

- **Press:** hold LB and push the left stick toward him. Or make it a fresh LB press in the last 0.2 s, for the same walk free of damage.
- **See:** head down, heavy steps, the guard shaking, the beam breaking on him, his shadow moving up it and a furrow behind him. You arrive in front of him.
- **Pays:** guard damage all the way, at most 1.5 times a guarded beam's worth. **He's stuck for as long as you walk,** which is what you're betting on.
- **Runs:** a signature or level 3 holds until you arrive, up to **2.5 s.** Levels 1 and 2 don't extend: you lean in and gain a step or two, with no prize.
- **Prize:** he's stuck for 0.33 s when you arrive, and your blow lands first.
- **Risk and beaten by:** **he can cut the beam with LT at any moment,** and he's then free. So the whole walk is a contest over when he lets go. Cut too soon and you've closed the gap for nothing; too late and you're on him.
- **Point blank:** 9 body heights in about 2.5 s, the walk as you pictured it. **Across the planet:** past about 20 body heights you can't arrive. It's just a guard with a lean, and the beam ends as normal.

## New ideas

| Idea | Press | See | Who pays | Risk, and what beats it | Point blank / across the planet | Goes to |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **The ground answers** (Combat's) | **The swat down, on or near the ground** | A hand driven into the floor, and the ground heaves up in front of you. The beam bursts on it. Sand in the desert, water and steam at sea, paving in a street. In the air, it's just the swat down | The swat's 10 ki, and your own ground: a trench at your feet and debris both ways | As the swat. Only as good as what's there | The same | **Everyone, soon.** It starts as a look with a set strength. A real raised strip is World's call |
| **The hose** (Combat's) | **After a dodge, while he's stuck: RB + A,** your fighter's grab, on his firing arm | For the rest of the beam it goes where you drag it, at his own sweep speed. A wild line across the landscape. It's still his beam, so no button fires one. The grab binds arms and torso only | The grab's price, and what it carves is on your account | The grab takes up to 0.5 s, so it's really for level 3 and the signature. He can still cut it with LT. No assist toward a town, and the AI drags by a fixed rule | Point blank is the real one. Across the planet, you can't get there | **Everyone, after beams can be steered.** Four versions already exist on paper |
| **Knock his aim** | Hit him during a signature's charge with something heavy: a charged flick, B, or the Driver's shot. A light does nothing | He's rocked, and the beam goes off wild, **into the sky only,** in a direction set by a rule | He loses the 45 ki and his cooldown | You've spent your window on a blow that may miss | He kicks back, so you chase. Across the planet, only the Driver gets there in time | **Everyone, later** |
| **Catch it** | The block, keeping LB down | You hold the front on one plated forearm or a shoulder, no higher than the shoulder, and slide back for up to 0.5 s, or until it ends. Then push the left stick to throw it (the swat), RB + stick to fire into it from one hand, or let go and it parts | The swat's ki if you throw. The trench is the other cost | He recovers while you choose, so a throw gets less of a prize | The same | **Everyone, next.** Kind to someone who's learned the block but can't yet choose in time |
| **Punch up the beam** | Hold the right stick toward him and let go as the front arrives | A charged blow goes straight up the beam, and he arrives fist first | Half the beam's damage, and the charge's ki | Mistime it and he takes the lot. If the shooter cuts and guards, he's flown into a blocked blow | Instant / no arrival from too far | **Loupe only** |
| **Put something in the way** | Nothing new: fly behind a ridge, a tower or a mine | The beam has to bore through. The front slows by the mass it's cutting, the same for a ridge, a tower or a town. Schools, hospitals and places of worship give no cover | The world does, and what's lost behind you is on your account | The cover goes, and buildings fall on you. Higher levels go through faster. The AI only ever looks for terrain, and nothing in the game teaches a town as a shield | Rarely room up close. Best across the planet | **Everyone, once fronts cut terrain** |
| **Cover your partner** | Fly onto the line and answer. A beam hits the first enemy it meets, so it's yours | Your friend's about to take it and you arrive first | Whatever your answer costs | Arriving late | Same as your answer | **Everyone, in 2v2.** Nearly free, and maybe the best moment in co-op |

## From the EP's list

| Idea | Ruling |
| :--- | :--- |
| **Split it** | Folded in. A block already parts it |
| **Slip and close** | Folded in, as the dodge's prize |
| **Blast the front** | **Cut,** as Combat says: a small pop on a huge beam isn't a picture. The ground answering does its job better |
| **Eat it** | **Loupe keeps On the Chin,** which you already picked: a fresh RT press plants his feet, chin down and fists closed, he takes 30% of the damage and builds Pride, not energy. The beam ends at him. **Combat's Bolus version is out,** by Legal: his chest doesn't open and the beam doesn't go in. Nothing in the game gets called eating or feeding |

## Each fighter

**Their beams,** from Combat. These are looks, and yours to judge:

| Beam | Dodge | Block | Swat |
| :--- | :--- | :--- | :--- |
| **Breakwater** (Grist) | The hardest to clear: you have to go up | A slab that piles up and fans out, the biggest | The middle goes, and the edges run past |
| **Lance Sheaf** (Loupe) | He stands among the missed lances, smouldering in the ground | Forks straight | The bundle scatters and stands where it lands. The best fit |
| **Hem Sweep** (Orza) | She can chase you with it: the best contest | **Never splits round a body.** It stops at a small hot point on the plate, with sparks | The whole thin straight line is re-aimed, never bent, and she can sweep it back |
| **Furnace Vent** (Bolus) | The slowest, so the easiest, and he's open longest | Splashes, with embers falling | A spray of slag, not a line |

**Their own answers:** Loupe gets Punch up the beam and On the Chin. **Grist:** Stand in front, for 15 ki a wider wedge behind him, my idea for Combat. **Bolus:** Legal allows him to take it on his plate, with scars, steam and sparks, for no ki, health or move. Combat can decide if that's worth having. **Orza and Bolus** have no melee moves yet, so anything they do with a body is new work.

**Everyone blocks the same way:** a plated forearm or the shoulder, one arm, no higher than the shoulder. Orza's hem swept up is fine as cloth, and so is Bolus's shoulder in with the grille shut. Grist's flat palm is out.

## What it does to the struggle

You asked for the struggle to be the game's shot, so it can't be starved. **The target stays: 30 to 60% of signature beams end in one.** These are guesses until read.

| Answer | Struggle's share |
| :--- | :--- |
| Fire back | The only way in |
| Dodge, block, swat | Each takes some, and they cost less, so **skilled players will drift to them.** This is the main risk |
| Walk | Takes a little, and it's slow |
| Catch | Gives some back, since it can turn into a struggle |
| The ground, knock his aim, in the way | Take a little, and they can buy time for firing back |

**Why anyone would still fire back:** every other answer only avoids it, or wins a small opening. **Only a won struggle sends him across the world.** If the share falls under 30%: first, LB's timing tightens from 0.2 to 0.13 s, and it can't go under 0.1 s on a pad. Then firing back costs 30 ki. Never a rule forcing a struggle. The AI's choice of answers is a number we set, and QA reads it.

## Checks

- **The claw grip gains nothing:** no answer pairs a face button with the stick except the hose's separate press. Controls' gate gets a row for each, and for RT + stick.
- **Mirrors and swaps:** every answer is one stick and one shoulder, so a swapped pad works, and the D-pad mirrors the stick's. **One hand:** the left alone can dodge, block, swat and walk.
- **Nothing goes on or over the fighters,** and all of it goes through the look gate. A refused answer knocks on the pad, so it never fails silently.

## Build order

1. **First playable:** the signature moves to RT + right stick. Fire back and dodge are already there.
2. **The one new picture: a beam that bends or parts at a body.** Rendering and VFX. Without it, the block, the swat and the walk all look like a guard, so it comes first, as Combat says. Hem Sweep stays straight. The carve follows the bent path later.
3. **LB's press moved to the front's arrival,** with block and swat. Already built on the old timing.
4. **Walk,** with the beam that runs longer.
5. **Then:** the ground's look, Catch, Cover your partner when 2v2 lands, the clean wedge (the carve needs to leave a gap), Put something in the way.
6. **After steering:** the hose. **Later:** Knock his aim. **With each kit:** their own.

## Legal's read (RL-231, `docs/legal/review-log.md`)

**The page above follows it. Everything stays open until it's built and through the look gate, the flash rules and the held-pose check.** The full limits are in RL-231, and these are the ones a builder could miss:
- **Aim:** no assist, lock-on, highlight or prompt toward a town, and none toward a school, hospital or place of worship. A swat earns nothing a beam wouldn't.
- **Poses:** one arm, plated forearm or shoulder, at or below shoulder height, at every tick of a block or catch. No open palm, both hands, arms wide or crossed arms, and no shouted line or named technique.
- **The hose:** no head, neck or throat. No joint past its limit, no snap sound or shown injury, and no taunt or zoom over a bound fighter. Bolus's hook is a hook and winch, never jaws.
- **On the Chin:** closed fists, no arms wide, and not held past the beam. Any glow is thin, in his own colour. The beam doesn't stream into him.
- **If a wild beam from Knock his aim ever crosses land,** that goes back to Legal.
- **QA reads** the AI's use of buildings as cover: at or near zero.

**Not ruled, and they go back to Legal when built:** walking into it, the ground answering, Punch up the beam, Cover your partner.

**For Combat:** RL-231 and the earlier screen bar an open palm and a casual backhand, so the swat's candidate pieces `palm_turn` and `heel_backhand` need another look. `fist_drop` and `plate_hammer` stay out of the ground's bodies.

## Orb's calls

1. **RT + B:** the power blow (my pick), or a fourth special?
2. **Where the swat lives:** the left stick on LB's press (my pick and Combat's), or a right-stick flick as the packet showed. The flick is showier and riskier, the left stick is simpler. This is the biggest choice here.
3. **How long a walk should take:** 2.5 s is my guess at what you pictured.
4. **The signature on RT + stick:** you may prefer direction to matter, such as up to fire from above. I've left it plain to start.
5. **The looks:** of the block, swat and walk, from clips.
6. **Which of the new ideas you want:** my favourites are the ground answering and Cover your partner.
