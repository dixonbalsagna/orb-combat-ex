# The four voice bibles, after the Gemini review

Owner: Narrative and Fighter Identity. Version 2, 2026-10-16 (night; adds Orb's ruling on flag a and Legal's conditions, RL-153 to RL-155). Orb ran homework 11 through Google's Gemini and called the result "very successful"; the marks are Orb's direction (`docs/ep/vision.md`, "Orb's homework 11 ... reviewed through Gemini"; the marked file is `homework/done/11-lines-the-brawl.md`). **Provenance:** the archetypes, the table below and the 26 rewritten lines are Gemini's, at Orb's direction, and are recorded as such (`pending/provenance_hw11.json`). Everything I wrote from them (the re-cuts, the lint, this page) is Claude's. All lines remain drafts until Orb marks them.

Where this page disagrees with `voices/*.md`, **this page wins**. The old bibles are kept for their lists of reactions and situations; their lines are not to be used.

## 1. The three global rules

1. **Single breath: 4 to 12 words.** Fragments, imperatives, contractions. (Unchanged: `writing-quality.md` section 0.)
2. **Strict direct address.** In a 1v1 every line is aimed at the opponent's throat. Never at an object ("Sorry, shop!"), a building, or an off-screen minion ("Guard, write that down"). *The Protagonist's concern for people still shows, but as something he says to the opponent* ("That tower's full of people! Fight me over here!"). Catching or shouting at a civilian who is on screen is allowed and kept rare.
3. **Visceral, tactile words.** Prefer the body and the material over filler: ribs, teeth, knuckles, frame, silk, rubble, dirt, marrow, steel, pulse, shoulder, elbows, bone, bricks. Cut "okay", "I barely felt that", "I'm stuck".

## 2. Sharper insults

"Pathetic" is retired. The rival and the Empress use specific venom: **amateur, eyesore, dead weight, third-rate, insect, clown, warm-up, scrap, rat, fluke.** The Protagonist does not insult; he grades.

## 3. The four archetypes

| Fighter | Archetype | Core | Uses often | Never (banned tropes) | Pain and damage |
|---|---|---|---|---|---|
| **Protagonist** | The Adrenaline-Junkie Martial Artist | A combat naturalist and sensory junkie; a brawl is a puzzle he plays with his own skeleton. High fight IQ. | weight, timing, rhythm, shoulder, teeth, loose, faster, clean, heavy | superhero apologies mid-fight (see flag a), confusion ("Wait, how'd you..."), righteous speeches, anger | Grins, grades the impact, works out how he was hit |
| **Rival** (the Anti-hero) | The Proud Precision Elite | Surgical disdain plus a bruised ego; he ranks his opponent aloud, live. | third-rate, amateur, frames, fluke, rubble, earn, trade, sloppy, rank, "barely top ten" | tired complaints ("chasing you all day"), playground dares ("I dare you"), admitting respect openly, "Pathetic" | Denies the skill ("Lucky swing!") and answers with cold, surgical fury |
| **Empress** | The Sadistic Sovereign | Mock-polite imperial sadism with booming, theatrical swagger. The royal "we" with lethal authority. | we/our, bleed, glass, crawl, silk, rat, mess, limb, insect, clown | calling guards for help in a 1v1, whining about her outfit, dry bureaucratic jokes ("approve that wall"), "petitioner" in most lines | Laughs ("Hahaha!", "Gahaha!"), then hits back with a larger blow |
| **Cyborg** | The Ravenous Bio-Mech | A demon stomach bolted into a military-grade machine; his telemetry is hijacked by hunger. A limiter chip holds the appetite back. | protein, calories, chassis, limiter, tenderize, crunchy, snack, sensors, meaty, steel | **the waiter, chef and restaurant gimmick entirely** ("sir", "madam", menu, table, tip, kitchen, order, customer, "thank you for your patience"), timid begging | Complains about dented metal against bruised meat; panics or gloats when the limiter chip cracks |

## 4. The title budget

- **"Petitioner"**: the Empress, once or twice a match, when she is looking down her nose at someone. The lint caps it at two per block. Other contempt words carry the rest: rat, insect, clown, scrap.
- **"Sir"**: gone for the Cyborg, and gone for him as a form of address to anyone. His name for an opponent is snack, scrap, lunch (see the Legal flag), or nothing.
- **The rival's rank gag** returns, but as live trash talk with contractions ("You're third-rate", "Barely top ten"), not stiff prose, and not in every line.

## 5. What changed for the guards

The Empress's guard is a 3v1 character. In a 1v1 she is alone and talks only to the opponent. In a 3v1 she commands them ("Guards, hold the line!"). The lint takes a `3v1` heading as the exemption; in data a line carries `mode: "1v1" | "3v1"` (proposed, so the director can choose).

## 6. Where the old material stands

| Material | Status |
|---|---|
| `voices/protagonist.md`, `anti-hero.md`, `empress.md`, `cyborg.md` | Lines retired; reaction lists kept; a note at the top of each points here |
| `voice-lab/*.csv` (the draft sheets) | Superseded for the Cyborg (all waiter lines), and for any Empress line that calls a guard |
| `taunts.draft.json` | The Cyborg's waiter lines and the Empress's guard lines are listed for re-cutting in the report (NEXT) |
| Homework 12 to 16 and 21 | Re-cut in `voice-lab/homework/` (same file names) |
| Beats, run lines, intro lines, waiting-game lines | Re-cut (`story_beats.json` v4, `run_lines.json` v2, `intro_lines.json`, `waiting-game-lines.md`) |

## 7. The lint

`python docs/narrative/line-lint.py FILE.md` now also fails, per speaker block (a `## ` heading naming the fighter): the Cyborg's waiter words, the Empress's guard words (unless the heading says 3v1), the rival's "Pathetic" and old dares, the Protagonist's apologies (unless the heading says "after the fight"), and more than two "petitioner" in an Empress block. The lists are `gemini_review_2026_10_16` in `line-lint.json`.

## 8. Flags for Orb (through the EP)

**(a) Ruled by Orb: the Protagonist apologises for damage AFTER the fight, never during it.** The promise tags stay; during a fight he is the adrenaline brawler. So the after-the-bell apology is the rule, not a proposal: in the fight he is a grinning brawler with no apologies, and damage shows as silence (the witnessed branch); when the match ends he says it ("Sorry about the street, everyone. I'll help rebuild.") and the tag is tied. The lint allows an apology only under an "after the fight" heading. His grief for people in the run's casualty beats ("I'm sorry. I should've been faster.") is not an apology for property and stays.

**(b) "No lines to off-screen minions" is a 1v1 rule.** In a 3v1 the Empress commands her guards. Done as section 5 above; four 3v1 lines are in homework 13 and 16.

**(c) Lines to screen with Legal.** From Gemini's 26 (Orb's pick): "Look at you bleed" (17), "you die first" (15), "glass the whole street" (19), "Level this whole block" (23), "I'll eat the arena" (26), and the Cyborg eating fighters ("protein", "lunch", "tenderize", "crunchy", 24, 28 and 29). From my re-cuts: the Cyborg's hunger for fighters across homework 12 to 16 ("snack", "protein", "crunchy", "dinner's running right at me"), "We'll char your knuckles", "lose a hand", "We'll snap them", "I could eat this whole planet" (a planet-scale line, c06) and "You chewed our last envoy" (16, the Empress on the Cyborg). **I kept the Cyborg's civilians off the menu** (he is hungry for fighters only; "Stay inside. I'm only hungry for him." is the civilian line).

**One more, which is not mine to settle:** line 19 of Gemini's set uses "Dance", which is on **Orb's own** banned list (the lint fails it). The alternate is "Scatter, little rat!".

## 9. Legal's conditions (RL-153 to RL-155, `docs/legal/gemini-lines-screen.md`)

1. **Provenance, ai01.** Recorded in `pending/provenance_hw11.json` (tool Google Gemini, model "Argon" as Orb named it, date 2026-10-16, homework 11; what came back: 26 rewrites, voice rules and a Godot audio guide; the human part is Orb's marks, choices and direction plus Narrative's edits), and every line there carries `provenance: "ai01"`. The headers of the six re-cut homework files say the same. The public statement names categories (text and dialogue), never vendors, and never claims a line as human-written unless the record shows it.
2. **"Glass" is in the lint's review tier** (c10): a human reads any line using it. For Gemini's line 19 I offer Orb two swaps: **"Scatter, little rat! We'll burn the whole street!"** or **"... flatten the whole street!"** (which also removes the banned word "dance").
3. **"Level this whole block"** (Gemini 23) fires **only on its chimney trigger** (the Empress wedged in a chimney), never in reaction to civilian deaths or casualties. It is recorded as `trigger: {only_on: empress_wedged_in_chimney, never_after: [civilian_casualties]}`. I also changed the Empress's taunt for a heavily damaged city to "Pretty ruins, rat. Mind your step!" so no Empress line gloats over a toll.
4. **The Cyborg's hunger stays on fighters (comic) and wreckage,** never on civilians or children, and nothing has him absorb a fighter's power or form (the genre's glutton signature). His taunt for a wrecked street is now about steel ("Good steel in there!"), not food. No depicted biting or swallowing until the rating decision.
5. **No "Demon Cyborg" in public text.** The internal title in `identity.md` ("Demon Cyborg") is a working data field; it should not appear on a page, a store listing or in a trailer. Public copy says "the Cyborg".

6. **Legal ln07 (RL-181, 2026-10-23): "snack" as an address stays.** ln02 covers depicted eating, not dialogue, so the Cyborg's spoken "snack" for an opponent stays in Orb's approved lines, aimed at **fighters only** (never a bystander, civilian or child) and never played over an on-screen bite. Mouth words (spit, snack, bite, chew, jaw, teeth and the like) stay out of **move names and flavour text**, anything an artist reads; the energy names already follow that.

## 10. Questions for Orb

1. (Ruled.) The after-the-bell apology stands.
2. Should the Cyborg's **hunger for fighters** stay (Legal may soften it), or should he be hungry for *anything* and have the humour come from his chassis?
3. Do you want the **Empress to laugh** in most lines, or in about one in three?
