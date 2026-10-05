# Hold to flurry: an accessibility option for the mash (a question for Orb; nothing is built)

Controls, 2026-10-05, answering Game Design's question on `melee-press-feel.md` section 3. Under that rule a flurry follows the player's taps, 6 to 12 ticks apart (10 to 5 blows a second), a blow's damage is its interval divided by 10, a faster tapper's run climbs faster and he wins a trade, and a 6-tick floor caps even a turbo pad at ten blows a second. A player who cannot tap fast, or for long, is at the slow end of that. Can the game let them hold the button instead?

## The short answer

**Yes, it is workable, and it is cheap if it is the director's job and not the layout's.** I would set it at **a blow every 10 ticks (6 a second)**, on a single per-player switch in Accessibility (default off). It costs the player who uses it the initiative against anyone tapping faster than six a second, and nothing else in damage.

## Why 10 ticks

1. **10 ticks is the rule's own reference.** Section 3 scales a blow's damage as interval ÷ 10: ×1.0 at 10. At that rate the assisted player's light is exactly a "brawl light", neither weakened (6 ticks, ×0.6) nor padded (12 ticks, ×1.2). Damage a second is the same at every speed, so nobody is paid or charged for the choice in damage.
2. **It is not the fastest, so it is not a turbo.** At 6 ticks an assist would beat every human tapper and match a turbo pad; the option would be an advantage, not an accommodation. At 8 ticks (7.5 a second) it would still out-run an ordinary masher, who sustains about 6 a second for several seconds, and so win the close in most casual trades.
3. **It is not the slowest, so the player is not the permanent loser.** At 12 ticks (5 a second) the assisted player would lose the run to nearly any tapper, every trade.
4. **Six a second is a rate most people can hold for a whole trade** (a trade is at most 90 ticks, then it closes), and the AI's casual difficulties already tap near it.

I would keep it **one fixed rate**, not a slider. A slider lets the assist be tuned to 6 ticks, which is the turbo problem again, and a rate that is "the player's own" is just their tapping.

## What it costs the player who uses it against one who taps

- **No cost in damage a second.** Same as any rate (section 3).
- **They lose the trade to a faster tapper, as they should.** A tapper at 8 ticks or less climbs his run faster and closes; at 6 ticks he closes most trades. Against an equal tapper (6 a second) the trade is level, so it falls to blows landed and then the seeded draw. Against a slower tapper they win it.
- **No bursts.** A tapper can hurry up at the moment a heavy's wind-up needs interrupting (speed buys that sooner); the assist is a metronome and cannot.
- **No free skill strikes.** The repeated presses must **not** be graded as timed ones: a metronome will land on or off a blow's beat for the whole flurry, and "on" would hand over a ×1.25 skill strike and flow every blow. The assisted blows are plain flurry blows; if they want a skill strike they tap on the beat as anyone does. Timing still beats mashing.
- **The held light reading is not available on that button while it repeats.** Today X held for 8 ticks reads as the set light, the guard strike or the volley (`press_read.gd`, holdLight 8). With the option on, a held X is the flurry. Y's heavy is unchanged, and so is the tap. This is the one real loss of reach, and the reason for the options below.

## Three ways to build it

| | How | Cost | Note |
| :--- | :--- | :--- | :--- |
| **A. The director throws the flurry** (recommended) | The input layer changes nothing: `lightHeld` is already in the intent. With the option on, the brawl director throws a light every 10 ticks while `lightHeld` stays true, the way it throws the AI's blows, and marks them as not timed itself | A per-player option the sim needs to know, so it goes in the match setup and the replay header (like difficulty), **no intent change, no replay break**; Encounter owns the rule | The AI already does exactly this, so "the AI can do anything the player can" holds. Fits Simple, where the attack button's hold is already the heavy upgrade and there is no other hold to give |
| **B. The layout repeats the press** | While the light control is down, the layout makes a press edge every 10 ticks. The intent sees ordinary lights, so any replay is right with no setup | **A new intent bit** (one of the 10 spare, `autoPress`, version 5) is needed so the sim can leave the repeats un-timed and apart from the hold reading: another replay break and a golden regeneration, the same size as version 4. Without the bit the metronome exploit above is real | Cleanest for replays, dearest in change. Not usable on Simple's attack button (its hold is the heavy) |
| **C. A dedicated Flurry control** | A button that repeats at 10 ticks, so X keeps its tap, its hold and its readings: L3 on the pad, a key, a Full touch widget | The same intent bit as B, and a control to find room for (Full touch is full; Simple has none to spare) | Keeps every reading, so it loses nothing; asks the player to find one more button, which is the thing the option exists to avoid |

**Recommendation: A, at 10 ticks, one switch per player in Accessibility, default off.** It is the only one that does not touch the intent or the golden, it works on Simple, and it matches what the AI does. If Encounter would rather the sim not carry a per-slot option, B is the fallback, with the one-bit change planned as a version 5 window; C only if Orb wants to keep the held light reading for assisted players.

## The question for Orb

*A player who cannot mash quickly could switch on "hold to flurry": holding the light button throws a steady six blows a second for them. They would do the same damage a second as anyone, but a quick tapper would still win a head-to-head mash, and the held light reading (the set light and the volley) would not be on that button while it is on. Do you want this option, at six a second, and are you happy for it to give up the held reading?*

## For the other directors

- **Encounter:** option A is a rule in the brawl director (a light every `flurry.assistTicks` = 10 while `lightHeld` and the option is on; floor 6 as always; not graded as timed; counts toward the run like any flurry blow). New data key under `flurry`, Tools' schema first.
- **Simulation:** the per-slot option in the match setup and the replay header, if A.
- **UI:** one Accessibility switch per player and a line in the legend ("Hold X: flurry") when it is on.
- **QA:** the assisted player at 10 against a tapper at 6, 8, 10 and 12 for the close rate and the trade length; the assist must not beat a 6-tick tapper and must not lose to a 12-tick one.
