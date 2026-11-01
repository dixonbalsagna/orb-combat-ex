# A combo builder for custom fighters: does it fit?

Owner: Game Design. 2026-11-01. **A page for Orb to read. It isn't a decision, and nothing here is built or played.** Orb's idea (`docs/ep/vision.md`, last entry): mashing should count as part of a combo. In a custom fighter's campaign, you beat Grist in training and he teaches you one of three two-part combos, such as "Hold Y then Mash X" or "Tap X then Hold B", from a pool of attacks with stats and effects, which you unlock, upgrade and replace over time.

**Short answer: yes, it fits well, and it gives custom fighters what they were missing. It needs one rule of yours to change, for the campaign only. And none of it needs to touch the first playable.**

## Why it fits

- **The game already knows tap, mash and hold apart,** on every button. So a part of a combo is simply a button and how you pressed it.
- **Each press is still a blow.** "Hold Y then Mash X" isn't a macro: you hold Y and it lands, then you mash X and those land. A combo changes which blows you get and what they do. It doesn't play itself.
- **No press has to wait.** A mash can't be recognised until about the third tap, so the first taps land as usual, and the combo's effect comes in when it's recognised. So the combo never costs you response.

**"Mashing counts as part of a combo" is worth having whatever you decide.** I'm asking Combat to let the phrases in the first playable (map row 1) include a mash and a hold as parts, for every fighter, if that's cheap. If it costs more than a small change, it follows the first playable.

## Learned combos and phrases

Three ways it could go:

| | What it means | My view |
| :--- | :--- | :--- |
| A learned combo replaces a phrase | Grist and the others could have theirs swapped | No. Grist's combos are what make Grist, and every player should meet the same Grist |
| Beside the phrases, on everyone | Roster fighters learn extras too | No. It's two lists to learn, and roster balance gets much harder |
| **Custom fighters use learned combos only (my pick)** | Roster fighters keep their phrases, fixed by seed. **A custom fighter's phrases are the ones they've chosen.** Any press outside a combo plays from the generic pool, so they're never empty | **Yes.** A learned combo is simply a phrase you chose rather than one the seed wrote, so it needs no second system |

So the custom fighter's whole identity is what you've picked. **That's the real gift of the idea:** a roster fighter has a style from their seed, and a custom fighter has had nothing like it until now.

## The right stick

- **A stick move can be a part,** such as "Flick up then Mash X", because it's the same kind of gesture.
- **Parts come one after the other, never together,** so a claw grip still gains nothing. The existing lockouts between the stick and the buttons simply become part of the combo's timing, and the claw bot checks every combo in the pool.
- **What each control means doesn't change.** A combo can't make the stick send someone, as B is what sends. A button can't fire a beam, since beams are the stick's.

## Stats and effects: the rule that has to bend

Today, a generated move can change how a press looks but never what it's worth, so no move is the best one. Your idea gives attacks stats. **Those can live together if each one is a trade rather than a gain:**

- **Every combo in the pool spends the same budget.** More damage but slower. Less damage but a longer stun. A shorter reach but it builds ki. One that carries toward a wall. QA checks each one stays inside a band.
- **"Upgrade" is the hard word.** An upgrade that's only stronger is what the rules forbid. So I'd keep real growth to the campaign (below), and make upgrades mostly add a choice: a second effect to pick between, or a third part.

## Arcade and versus

You've already said custom fighters can go into arcade and versus, so:

| Mode | What a custom fighter brings |
| :--- | :--- |
| **The campaign** | Everything you've earned, upgrades included. It's a fight against the game, so growth is the fun |
| **Arcade** | The same, in solo and co-op |
| **Versus and online** | **The combos at their base values, with the whole pool open to anyone.** Hours in the campaign must never beat a friend who just started. It's still a real choice: you pick your own build before a match |

The choice travels with the match's setup, so replays and online stay exact.

## What breaks

1. **Your own rule, from questionnaire 3: "Only cosmetics unlock; everything that changes play is open from the start"** (`unlocks.md`). This idea unlocks play. My suggestion keeps the rule everywhere but in the campaign and arcade, for custom fighters. **It's your call.**
2. **"Never a stat that carries past the run"** in the run mode. Learned combos would carry across a custom fighter's save, so that line needs rewording too.
3. **"Pick one of three" can't be a random roll,** since unlocks rule out random rewards. The three offers would be named and fixed by where you are in the story. **A combo you replace is never lost:** it stays on your list. Legal should look at this.
4. **Balance.** A pool of combos can't be tested in every pairing, so the budget band has to do that work. A bad one could still slip into versus until QA catches it.
5. **A hold-to-flurry assist has to count as a mash,** so players who can't mash aren't locked out of half the pool. The same goes for remapping and Simple mode.
6. **The animation pool costs real work.** A separate pool of attacks is new art. Most of the first ones can reuse existing pieces, and the generator can help.
7. **Teaching.** "Hold Y then Mash X" has to be shown on screen somewhere that isn't over the fighters: Grist's training scene and a list in the menu.

## The smallest test

**After the first playable, and only with phrases in:** one stand-in custom fighter, one fight against an AI Grist in training, and a pick of three combos before it: Hold Y then Mash X, Tap X then Hold B, and Flick up then Mash X. They use existing pieces, one effect each, with the buttons shown at the frame's edge. No save, no campaign, no upgrades. It's a data row on the phrase reader, so it should be small.

**What it answers:** by the second minute, are you using your combo on purpose? And afterwards, do you want to go back and try a different one? If so, the rest is worth building.

## One question for Orb

**Are you willing to let attacks unlock in the campaign and arcade for custom fighters, with versus staying fair by opening the whole pool?** That's the choice everything here hangs on. Research is looking at how other games keep this loop engaging, and UI is drawing mockups, so this needn't be answered until you've seen those.
