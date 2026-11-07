# Beams on Orb's third play

Owner: Game Design. 2026-11-06, for Orb's notes on the third play (`docs/ep/vision.md`, last block): "sometimes felt like control was taken away from my character, was forced into switching sides with opponent and then they fired a beam at me. I couldn't figure out how to fire a beam at close range but the opponent seemed to be able to pull off charging beams in melee range", and "make sure it's obvious what to press to win beam clashes".

**How this was read:** Orb's saved match, replayed on a scratch copy of the build they played (10d8b8cf). **It reproduces exactly:** the final state matches the file's. So every number here is what happened in that match, against the easy computer, about 6 minutes. Counts only; the file stays private. Nothing is built.

## 1. What to press to win a beam clash

**The cause.** Winning a struggle means pressing X, Y or B **on the beat**, and A on the beat lets go. Mashing does nothing, and a press off the beat cancels your next good one. **Nothing on screen says any of that.** With the minimal HUD there's no bar and no prompt: only the meeting point moving and a beat in the sound and pad. Until this build there was no sound at all, so the beat couldn't be heard either.

**The change: show the beat and the buttons, at the edge of the screen, the first few times.**
- **In the small left panel,** during a struggle, X, Y and B light up together on each beat, with the words "Press on the beat". The first three struggles of a match, then it goes. Nothing over the fighters.
- **A press on the beat** gets a sharp sound and a short rumble. **One off the beat** gets a dull knock and, the first three times, the word "Off the beat" in the panel.
- **The meeting point** already throbs on each beat. VFX keeps that, so the beat can be seen with the eyes on the fight.

**Owners:** UI (the panel), with Audio and Controls for the sound and rumble. **The clip:** a struggle won on the beat beside one lost by mashing, **with the buttons and their timing drawn at the edge,** from Tools' clip kit.

## 2. Beams at close range: why Orb couldn't, and the computer could

**The cause. They were two different moves.** Orb's beam was the right stick's. The computer's was its signature, and the code treats them differently.

| | Orb's beam (RB + right stick) | The computer's (its signature) |
| :--- | :--- | :--- |
| **How often** | Started 36 times, 18 of them up close. **It fired 3 times, all as answers to the computer's beams.** None of Orb's own beams ever left their hand | Charged 6 times, **4 of them up close** |
| **In a brawl** | **A release did nothing at all**, with no sound or sign: 3 times, with plenty of energy | **The brawl gave way** and the charge started |
| **Just outside a brawl** | A release up close **turned into a heavy blow**, which the computer dodged and countered (and that's where 4 side swaps came from) | |
| **While holding** | **Lost to a blow 10 times**, mostly in the first fifth of a second, before the hold's protection starts | **Orb was locked** in the computer's exchange for the whole charge |
| **Far away** | **Refused 3 times by the signature's 15 s wait**, which the stick's beam shared by mistake. No sign of why | |

So the computer had a protected, locked-in charge that only its signature gets. Orb's beam went through the signature's request, which a brawl and the signature's own wait both block.

**The change: one rule for a beam, for everyone.**
- **A beam on the stick is its own move,** not a signature request. It costs its stage's price, has no signature wait, and fires at any range, including point blank, where the firing throws the other fighter back (`power-scale.md`).
- **At point blank it fires on release, and the brawl gives way only then,** not when the charge starts.
- **The hold is protected from light blows from its first tick.** A heavy blow, a grab or a beam still stops it, and so does a medium in the first half second, as already ruled.
- **The computer's beams use the same path,** its signature included, through RT + right stick. **Nobody is locked while someone charges:** you can still hit the charger, guard, dodge or answer.
- **A release that can't fire always says why,** with a knock on the pad and a word in the panel: "No energy", "Hit", or "Too close" if that ever applies.

**Owners:** Encounter (the beam's own path, and the computer firing through it), Controls (the knock), UI (the words). **The clip:** Orb's own close-range attempt, before and after, with the button strip.

## 3. Switched sides, then a beam

**The cause: the computer's signature at point blank, not a pass from outside or a pursuit.** Both times the computer charged within reach and the sides swapped, it happened 17 and 21 ticks into the charge, with the fighters one unit apart. **The signature's exchange locks the target, and its charge moves the shooter** (it rises over the target as it gathers), so at that gap he passes over and the sides flip. Then it fires. Orb was locked throughout, which is the "control taken away".

**There's a second source of "control taken away":** the dodge exchange. When the computer dodged one of Orb's attacks, Orb's fighter was locked and carried round after it. That happened in **16 of the match's 31 side swaps.** It's the loop Orb loved in the second play, but here Orb didn't choose it.

**Should it hand the foe a free beam? No.** A beam should never come from a swap the target didn't choose, or at a target who can't act.

**The changes:**
- **Covered by point 2:** the charge no longer locks the target, and the shooter stays still while charging (Orb's earlier ruling, `power-scale.md`), so nobody passes over anybody. Up close, the firing throws the target back the way he already faces, never through.
- **One new rule: a beam can't fire until its target has been free to act for at least 0.3 s.** The lit hand just holds a little longer. So nobody is fired on straight out of a lock, whatever caused it. It applies to players and the computer alike.
- **In the dodge exchange, you only go round after him if you're still pressing toward him.** If you've let go, you stay where you are and keep control. Orb's loop stays for anyone who asks for it.

**Owners:** Encounter (the 0.3 s rule and the dodge exchange's follow), Combat (the follow's pieces). **The clips:** the two swaps from the match (17 and 21 ticks into the computer's charge), and a dodge exchange followed and not followed, each with the button strip.

## What isn't covered

The stutter and crackle at high-speed impacts, and the fighter that kept attacking up a mountainside, are Performance's, Audio's and QA's, not part of this page. **It's one match against the easy computer,** so the counts show what happened there, not how often it happens in general.
