# Stance questionnaire: answers given by the EP on Orb's behalf (2026-10-04)

Orb, 2026-10-04: "I want you to answer this questionnaire in my stead. I had a conversation with controls & game feel and I feel you're suited to take over this task."

The questions are Controls' `docs/controls/stance-questionnaire.md`. What Orb confirmed to Controls directly, as Controls records it: RT dominates; the hybrids are LT+RB (evasive energy), LB+RB (defensive ki) and LT+LB (terrain while flying); the AI can do anything the player can; simplified and accessibility controls let a player hand stance choices to the choreographer at any granularity; B gives every fighter its own array of signatures; struggles affect all fighters.

These answers are the EP's, reasoned from Orb's recorded direction in `docs/ep/vision.md`. **Orb can overrule any of them.** "Default" means Controls' recommended default is accepted as written. Four answers differ from the default and are marked **DIFFERS**.

## A. Stances and shoulder combinations

1. LT+RT with no form ready: **default.** The transform chord only; a "not ready" cue otherwise.
2. RT dominates: **default.** Stance only. Holding RT ends a held guard because charging is exposed; the burst on an RT tap still fires from a guard.
3. Stance costs: **default.** Free to hold; moves cost ki; zone, shield and terrain effects have a duration.
4. Stance switching: **default.** Instant and free; a blow keeps the stance it was pressed in; a switch cancels nothing. Reason: Orb wants every blow to match a press, with no hidden cost on the hands.
5. LT's dodge on entry: **default, to be revisited after Orb plays it.** It is a dodge and pays the 15 ki dodge-cancel when threatened. If entering manoeuvre to pilot a lunge keeps causing unwanted dodges, the fix is a dodge on a tap only.
6. Stances while launched or stunned: **default.** LT (tech tap, brake hold) and Escape only. This is the air recovery Orb asked for.
7. Reading an opponent's stance: **default, yes.** One clear tell per stance and hybrid: the pose first, an aura second. No HUD glyph unless a setting turns it on. Reason: Orb asked for attacks that are "easier to spot when they're being used against you".
8. Hybrids on Simple and touch: **default.** Choreographer only on Simple; touch Full arms two stance buttons.

## B. B and the signature array

9. Signatures per fighter: **default as the target, staged.** One per stance and hybrid (up to eight), the default stance's B being the fighter's defining signature. This update ships the five base stances' signatures; the three hybrid signatures follow with the hybrids.
10. Cost and limits: **default, with a ceiling on the cooldown.** Tiered cost (cheap arts up to ultimates); no per-match cap; one shared cooldown of at most 3 seconds, there only to stop back-to-back spam. Ki is the real limit. Reason: Orb called the beam cooldown "a relic" and "too restrictive".
11. Where the beam lives: **default.** The energy stance holds the beam-type signature; the other stances hold melee, guard, charge and terrain signatures.
12. Pillar 7 against unique signatures: **default, yes.** The stance picks the signature; biome, altitude and the defender's stance pick the variant.
13. Authoring: **default.** A generated frame with hand-picked pieces for each fighter's defining signature. It uses Combat's moveset generator, as Orb asked for generated movesets.
14. The RT specials: **default.** Fixed per fighter; a loadout later.

## C. Struggles for everyone

15. What starts a struggle: **DIFFERS.** Not any two committed blows. A struggle starts only when two heavy commitments meet: signature against signature, a held heavy or a string's ender against the same, a beam against a shield that breaks (17). Light, flurry and skill blows that meet simply trade, with no struggle. Reason: Orb wants close brawls to "trade continuous strings of blows without interruption"; if every pair of meeting blows opened a struggle, a brawl where both press would stop every second.
16. Which button presses on the pulse: **default.** Any face button; the held stance modifies the score slightly (charging adds power, defensive adds endurance). Stray presses follow the finisher struggle's rule at Orb's chosen strictness (2 of 3).
17. Hybrids and struggles: **default.** A ki shield or zone absorbs up to a damage cap; a beam breaking it starts a short struggle.

## D. Choreographer and accessibility

18. Granularity: **default, yes.** A per-stance setting (Player, Choreographer, Off) for each of the five stances and three hybrids, with presets (Full, Assisted, Manual).
19. Assisted mode: **default.** Both, as two presets: one where the choreographer suggests and the player confirms, one where it acts.
20. Overrides: **default, yes.** Holding any stance button overrides the choreographer for that blow.
21. Fairness: **default.** Identical costs, cooldowns and timing; assisted players flagged in the replay header.
22. Feedback: **default.** A small badge showing the choreographer's stance, off in Manual.

## E. AI parity

23. **Default, yes.** The AI writes the same intent record, stances and hybrids included; difficulty changes only execution (reaction time, timing accuracy, switching rate), never abilities.
24. **Default, yes.** The same physical limits, with a level-based reaction time.

## F. Collateral and personality

25. LT+LB landscape effects: **default, yes to all three.** Hero and villain versions (barriers against collapse); they feed anguish and menace; collateral caps per tier, inside World's casualty window (hard test C1).
26. Zone and shield against the RT burst: **default, confirmed.** Zones persist; the burst is instant.

## G. Inputs and teaching

27. Keyboard hybrids: **default, yes.** Dedicated keys on the solo keyboard; a tap-to-arm latch on the shared one.
28. Retire the Brawler preset: **yes**, migrating a saved choice to Arena. Its attacks sit on RB and RT, which are now stance buttons.
29. Hold against latch: **default, yes.** Hold on pad and keyboard, a one-shot latch on touch, a per-player setting everywhere.
30. Learning the cells: **DIFFERS in order only.** Both, but the per-fighter move list ships first, generated from the moveset data so it costs almost nothing and can never be out of date. The practice mode comes after this update. The choreographer presets are the on-ramp.
31. Does the alchemist read stance: **default.** The stance of each of the last five presses is an ingredient; a stance switch never resets flow or the recipe window.

## H. Sequencing (zero budget)

32. What first: **DIFFERS slightly.**
    1. The stance field in the intent, built once as a 4-bit mask (one bit per shoulder button) and not as a single "stance held" number, so hybrids later need no second format change. Replays break once, not twice.
    2. The martial arts stance (nothing held) for both fighters on the new press-matched melee, since it is where most of a match is spent and it is Combat's proposed first slice of the generator.
    3. The other four base stances by four face buttons.
    4. Hybrids.
    5. The choreographer's per-stance settings.
    The Simple layout must keep working at every step: the choreographer already picks for it, and it is the on-ramp.
33. Deferred from the next update: the three hybrids and their signatures, the special loadout, the practice mode, and the per-stance granularity of the choreographer setting (the presets ship first). AI parity is not deferred: the AI uses whatever stances exist from the day they exist.

## What this asks of whom

- Controls: build the 4-bit stance mask when Game Design's matrix exists; retire Brawler with the migration.
- Game Design: the stance by button matrix against these answers; the struggle rule of answer 15; the tiered signature costs and the cooldown ceiling of answer 10.
- Combat: the generator's first slice is the martial arts stance; signatures as a generated frame with a hand-picked defining signature.
- Encounter: the AI writes stances in its intent; the choreographer picks for Simple.
- UI: the move list from the moveset data; the stance badge.
- Animation and VFX: one tell per stance.
