# The four signatures on the stick, and making Loupe memorable

Combat, 2026-11-01, for Game Design's beam workshop and Orb's marks (`docs/ep/vision.md`, "Beam answers, Orb's marks"). **Paper only: nothing here is built, drawn or played.** Names beyond Keeper's Lance and The Barrage are descriptions, for Narrative. All of it goes to Legal when built.

## The idea: one input, four verbs

`beam-answers.md` puts every signature on RT + right stick and leaves direction meaning nothing. Orb: "each character's signature becomes accessible on the stick, I want to work on this more."

**My proposal: the press is the same for all, and what the stick *does* during it is the fighter's.** The stick is the character:

| Fighter | Their verb | A player's hands |
| :--- | :--- | :--- |
| **Grist,** Keeper's Lance | **Holds** | Hold the stick to charge, let go to fire. Direction picks where it carries him |
| **Loupe,** The Barrage | **Flicks** | One flick, one volley. Direction picks the volley's shape |
| **Orza,** Hem Sweep's top form | **Draws** | The line fires at him, then the stick drags it across the world |
| **Bolus,** Furnace Vent's top form | **Stokes** | Pump the stick to build pressure, and let go at the top |

So all four are 45 ki, one cooldown, RT + stick, and there's still nothing to learn but "RT and the stick". You'd know whose signature it is with your eyes shut, from your thumb.

**Orb's stages fit all of them.** Orb: base two stages of charge, maximum six. By the model's level: `stages = 2 + round(4 × level)`, so 2 at base, 3 at tier 2 at 35%, 5 at tier 3 at 65%, 6 at the top. A stage means something different to each:

| | A stage is | Base, 2 stages | Top, 6 stages |
| :--- | :--- | :--- | :--- |
| **Grist** | A step up in force | A short, plain lance | A column that holds its width to the horizon |
| **Loupe** | **One more volley** | Two volleys | Six, and the walk in |
| **Orza** | More of the sweep | A short cut | A line across the whole frame |
| **Bolus** | A slat open | A sputter | A full surge |

## Each one

### Grist: Keeper's Lance
- **The move:** his low, side-on stance, as his beam's charge. Let go, and it fires at him along the line, as ruled. It can't miss by aim.
- **The stick's direction is where the hit puts him,** read at the release. This obeys "the stick puts him where you aimed", and it needs little new: `beam.gd` already takes a direction at the end of a hit, and `sigafter`'s `under` and `wall` twists are this kind of thing.
  - Toward: carried off along the line. Up: thrown skyward at the end. Down: pinned and driven into the ground. Away: dropped at his feet, in reach, for a follow-up.
- **By place:** the variants by biome stand.
- **Spectacular? Yes,** and it's the plain reference the others are read against.

### Loupe: The Barrage
- **The move:** RT held, then each flick throws a volley, one hand in one motion, as he walks forward. It's already the shape of his finisher, and Combat drew it in `barrage-signature.md`. **Now the player throws it.**
- **The direction picks the volley:** up, the fan of shards; toward, the line of three; down, the shot that splits. All three exist as shot kinds. Flick the same way twice and you waste it: the second is the lesser, as his third quick strike is.
- **The close:** if most land, he arrives for one heavy from his own pool. If they don't, he's left in recovery, in the open. He can be hit between volleys: he's walking, not braced. That's what the price buys the rival.
- **Why it's best for "better combo control":** a signature that's a phrase you play, not a button you press. Three flicks and a blow, in your rhythm.
- **Limits:** Legal's e05 and e06 (no two palms in turn, no pumping hand), and the flash rule: three volleys inside a second is over, so one full flash and the rest lesser, or wider spacing. At six stages it needs that reading most.
- **Spectacular? The most, if volleys read at the fight's zoom.** It isn't a beam, so it can't start a struggle, and that needs Game Design's eye: answers have to work volley by volley.

### Orza: Hem Sweep's top form
- **The move:** her arm swing from the shoulder, and the thinnest line in the game fires at him. Then the stick drags it, the whole straight line, at her 38° a second.
- **It's the only one that aims,** so it's the skilled one: it starts on him, and if he slips it, she can chase him, or give up on him and write across the landscape. A scored hairline stays, cooling for 60 ticks.
- **Limits:** never bent, whipped or curved, as RL-231 and the beam screen say, and it doesn't part round a body. Aimed by the player, with no assist toward a town.
- **Form-tied:** she only has it from revision 9, and "Final Approved" is her form signature. Her jokes before that are the joke.
- **Spectacular? Yes,** on a landscape. Against a target in open sky it's a thin line, so it needs the world behind it.

### Bolus: Furnace Vent's top form
- **The move:** RT, then push the stick back and forth to stoke. Each pump opens a pair of slats, a click and a rumble tick. Let go at the top for a full surge. Let it sit, and it sputters back a slat.
- **Direction on the last pump:** toward, the column; down, it vents into the ground and comes up under him, using the `under` twist.
- **Why it's his:** he's the only one you work at, like a machine, and it's the only signature with a rhythm that goes wrong. Orb wanted "timing the release".
- **Limits:** "a pumping hand" is a Legal bar on volleys (e06): here it's a chest grille with no hand motion, so Legal should read that it stays clear. His wobble stays in the edge and width, not brightness (fx09). Nothing opens or eats.
- **Spectacular? Probably,** but it's the riskiest to play: a stick pumped hard is hard on thumbs and pads, and Controls should say whether it fights the claw law. **If it does,** it's a plain hold with a sputter you time.

## Making Loupe memorable

Orb: "lets make Loupe a memorable character, but these might be too cool to only have on one character." **I'd give the moves to everyone and keep the attitude for him.** What makes him memorable is what he refuses to do.

**His rule: Loupe goes forward.** Everyone else flies, and he walks. Everyone else answers a beam, and he takes it personally.

| Idea | What you'd see | Cost |
| :--- | :--- | :--- |
| **He never backs up** | His dodge is a step past you, and his knock-backs land him upright, walking in again | A look, and one dodge variant |
| **Plates are the price** | His spine and forearm plates are the ammunition. Each volley spends one, and they stay gone for the round, on top of the cracks Art already planned. A long fight shows on him | Art, and a look only |
| **The Barrage is a walk** | He only ever walks through his signature, however far away you are | In the move above |
| **He calls it** | Before a big one he raises one fist and points his chin at you, and if that blow lands, he gets the most Pride a blow can give. It can be hit | A close taunt he already has, given a payoff |

**The Challenger is a good title for this.** I'd give Narrative the walk and the plates.

## What becomes universal

**Orb's own idea decides this.** "Charging up and timing the release on the charge right as the beam hits." That's one rule for everyone, and it's better than a list of special moves:

**Hold the right stick as the beam comes. Let go as its front arrives.** The direction you let go in is what you do with it.

| Let go toward | Everyone | Loupe's difference |
| :--- | :--- | :--- |
| **Up, down, away** | The swat | |
| **Toward: Punch up the beam, for everyone** | You fly up the beam and arrive with your charged blow: half the beam's damage, and a miss takes all of it | **His lands fist first and lands full,** with no half. Grist's arrives shoulder first. Bolus's bulldozes, slower and armoured. Orza's is a thrust along the line, never through it |

| Move | My call | Why |
| :--- | :--- | :--- |
| **Punch up the beam** | **Universal,** as the toward direction of the timed release | It's the answer Orb's walking and swat notes both reach for, and it's the most exciting thing here. It also solves the walk, since it needs no long beam. |
| **Catch it** | **Universal** | Orb: "i want this". |
| **On the Chin** | **Loupe's alone** | It's made of Pride, his meter, and standing there is his whole character. On anyone else it's just a worse block. |
| **Bolus's plate; Grist's Stand in front** | **Their own,** as looks and small trades | The same idea in each fighter's voice |

**On the Chin needs one thing fixed:** the drawn poses (`chin.plant`, in `launch-pair-movesets.md`) have open palms and open arms, and RL-231 now rules closed fists and never arms wide. Animation has to redo them before it's usable. RT is also the Charge button, and "a fresh RT press" for this will need Controls' read beside the signature's RT + stick.

## Which only read well on paper

- **Orza against a target in open sky.** A thin line needs something to cut.
- **Bolus's stoke,** until a thumb has tried it.
- **Six volleys,** until the flash read and a person's eye have both had it.

**What I'd prove first:** Loupe's flicks. It's the one with the most character and the most control, and the shot kinds exist.
