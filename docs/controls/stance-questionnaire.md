# Stance questionnaire for Orb (Controls, 2026-10-04)

Context: Orb confirmed RT dominates, hybrids LT+RB (evasive energy), LB+RB (defensive ki) and LT+LB (terrain while flying), the AI able to do anything the player can, simplified and accessibility controls that let a player hand stance choices to the choreographer at any granularity, and B giving every fighter its own array of signatures with struggles affecting all fighters. Every question has a recommended default; answer "defaults for 1 to 8" or say where you differ. Input mechanics and the intent format are in `lunge-control.md`.

## A. Stances and shoulder combinations
1. LT+RT with no form ready: the transform chord's cue only, or something else? Default: transform only, otherwise a "not ready" cue.
2. RT dominates: does holding RT end a held guard, or only change what face buttons mean (the burst on an RT tap must still fire from a guard)? Default: stance only; the guard ends because charging is exposed.
3. Stance costs: free to hold with ki spent on moves, or do energy, LB+RB and LT+LB drain while held? Default: free to hold; moves cost ki; zone, shield and terrain effects have a duration.
4. Stance switching: instant, or a 1 to 3 tick cost; does a switch cancel a blow in its wind-up? Default: instant and free; a blow keeps the stance it was pressed in; a switch cancels nothing.
5. LT's dodge on entry: if threatened, does entering manoeuvre pay the 15 ki dodge-cancel? Default: yes.
6. Stances while launched or stunned: which are usable? Default: LT (tech tap, brake hold) and Escape only.
7. Reading an opponent's stance: a visible tell per stance and hybrid? Default: yes.
8. Hybrids on Simple and touch: choreographer only, or one manual hybrid (A+B)? Default: choreographer only on Simple; touch Full arms two stance buttons.

## B. B and the signature array
9. Signatures per fighter: one per stance and hybrid (up to 8), or a smaller set with variants? Default: one per stance and hybrid; the default stance's B is the defining signature.
10. Cost and limits: full 45 ki with a shared cooldown, or tiered (cheap arts up to ultimates)? Per-match cap? Default: tiered cost; one shared short cooldown; no hard cap.
11. Where the beam lives: energy stance only, or any stance's signature may be a beam variant? Default: energy holds the beam-type; other stances hold melee, guard, charge and terrain signatures.
12. Pillar 7 (signatures adapt) against unique signatures: do they still adapt by biome, altitude and defender stance? Default: yes; stance picks the signature, context picks the variant.
13. Authoring: hand-written per fighter or generated from parts? Default: a generated frame with hand-picked pieces for each fighter's defining signature.
14. The RT specials (X, Y, A): fixed per fighter or a three-slot loadout? Default: fixed per fighter, loadout later.

## C. Struggles for everyone
15. What starts a struggle: signature against signature only, or any two committed blows meeting? Default: any two committed blows meeting, decided on the pulse.
16. Which button presses on the pulse: any face button or the starting move's button? Does the held stance modify the score? Default: any face button; stance modifies slightly.
17. Hybrids and struggles: does a ki shield or zone absorb a beam, or start a struggle? Default: absorbs up to a cap; a beam breaking it starts a short struggle.

## D. Choreographer and accessibility
18. Granularity: a per-stance setting (Player, Choreographer, Off) for each of the five stances and three hybrids, with presets (Full, Assisted, Manual)? Default: yes.
19. Assisted mode: the choreographer suggests a stance for the player to confirm, or just acts? Default: both, as two presets.
20. Overrides: can a player take back one blow by holding a stance button? Default: yes.
21. Fairness: choreographer moves obey the same costs, cooldowns and timing; assisted players flagged in the replay header for a separate ladder later? Default: identical rules, flagged.
22. Feedback: a small badge showing the choreographer's stance, off in Manual? Default: yes.

## E. AI parity
23. The AI writes the same intent record, including stances and hybrids; difficulty changes only execution (reaction time, timing accuracy, switching rate), never abilities? Default: yes.
24. The AI obeys the same physical limits (no frame-perfect switching, a level-based reaction time)? Default: yes.

## F. Collateral and personality
25. LT+LB landscape effects: hero and villain versions (barriers against collapse), feeding anguish and menace, with collateral caps per tier? Default: yes to all three.
26. Zone and shield against the RT burst: zones persistent, burst instant? Default: confirmed.

## G. Inputs and teaching
27. Keyboard hybrids: dedicated keys for the three hybrids on the solo keyboard, a tap-to-arm latch on the shared one? Default: yes.
28. Retire the Brawler preset, migrating a saved choice to Arena? Default: yes.
29. Hold on pad and keyboard, one-shot latch on touch, a per-player setting everywhere? Default: yes.
30. Learning the cells: an in-game per-fighter move list, a practice mode, or both? Default: both; choreographer presets are the on-ramp.
31. Does the alchemist read stance (the last five presses' stances as ingredients), and does a stance switch reset flow or the recipe window? Default: stance is an ingredient and never resets flow.

## H. Sequencing (zero budget)
32. What first: the stance mask (4 bits), the five base stances by four faces for two fighters, then hybrids, then the choreographer settings? Or hybrids and the Simple choreographer earlier?
33. Anything to defer from the next update, for example hybrids while the five stances ship?
