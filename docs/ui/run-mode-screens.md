# The run mode's screens: the offers, the beats between stages, the results (UI, 2026-10-17)

Owner: UI & UX. **Paper and a scratch mock; nothing here is built in the game.** Against `docs/design/run-mode.md` (Game Design, 7022b7df), `docs/narrative/story-beats.md`, World's stored planet and its strips (`docs/world/planet-slice.md`), and Legal's c08 (`docs/legal/catastrophe-and-city-screen.md`). The mock is kept local (see below).

**The mock and its pictures are kept local** (Orb: HUD mock sheets stay private): `homework/mocks/ui/mock/run-screens.html` (one page, `?screen=offers|beats|approach|results|resultslost&w=&h=&page=`) and `homework/mocks/ui/run/`, fifteen pictures: the offers, the beat, the final approach and the results (and a lost run) at 1280x720, 844x390 (the results in two pages) and 390x844. They are not in the repo; this page says all that the pictures show.

## 0. The rules these screens keep

1. **Legal c08 binds every count.** Casualties are **a count and an environmental result**, in the same type as every other fact: no icon, no colour, no emphasis, **no counting up, no sound, no animation when it changes**, no bigger than its neighbours. **No score, bonus, achievement, trophy or unlock comes from a death**, and nothing here rewards a rising count. The menace meter stays a power meter and appears on none of these screens. No depicted bodies, no close-ups, no school, hospital or place of worship named or marked as a place, no children.
2. **Plain words.** A player says "fight", "next", "people lost", "rest". The screens never say stage, chapter, slice, touch-down, offer, ledger, Dread, tier or ki (the level names are the game's own: TREMOR, QUAKE, UPHEAVAL, CATACLYSM). Every string is in `terms.json`'s `prompt` group, lint-checked by `hud_words_check`, and Narrative owns the wording.
3. **A shape, never a hue,** carries each meaning (kinds, place states, the start mark). The biome blocks on the strip are scenery and say nothing by their colour.
4. **Steady.** Nothing on these screens flashes or blinks. The screens change by a cut or a dissolve of 0.5 s or more, never faster than one a second (Legal's rule for story beats, fades and wipes). The sky behind the final approach darkens in steps at least a second apart (c05). Under Reduced motion the dissolves are cuts.
5. **A phone gets the same screens,** 14 px text at the smallest, every control a 48 dp target, nothing under a notch or a touch button. A short screen drops what is optional and, for the results, splits into two pages. A screen that must scroll keeps its buttons fixed at the foot.
6. **Input is one set:** keyboard (arrows or WASD to move, Enter or Space to choose, Esc to go back where there is a back), a pad (the d-pad or stick, A to choose, B to go back) and touch (a tap chooses, a second tap confirms). Every control can be reached and read on all three.

## 1. Where to next? (the offers)

**What it is.** Before each fight the player picks one of three places. Game Design's three kinds are shown as three cards on **World's strip**, not a globe: each card carries the whole arena of that fight as the strip World already draws (diagram D of `planet-slice.md`): the circle the fight runs along, read as a bar of biome blocks with the places on it. The strip wraps, so it is the whole way round, and a mark says where the fight starts.

**A card, top to bottom** (full size; the phones drop the lines marked *):

| Part | What it says | Source |
| :-- | :-- | :-- |
| **Kind** | A shape and a word: a triangle RAMPAGE, a diamond PROVING GROUND, two arrows CROSSING (shape never colour) | Game Design |
| **Place name** | "Harbourgate", "Greywater Ridge" | World's name grammar (Narrative's) |
| **The strip** | Biome blocks as World draws them. **The places on it, as marks:** a tall mark for a city and a short one for a town. **State is the mark's shape:** untouched is solid, damaged is half-filled with a crack, fallen is hollow with a slash. A small triangle above the strip is where the fight starts | World: the slice's biome fractions, the places (position, kind) and their state, and the start column |
| **What it holds*** | "3 cities, 3 towns" | World |
| **The opponent** | "The Rival, already in the city" (Rampage); "The Rival, stronger than you: a level harder" (Proving ground); "The Rival" (Crossing) | Game Design |
| **How hard*** | "Starts at QUAKE, rises to UPHEAVAL" | Game Design (the stage's tier and its step) |
| **Reward** | One bold line: "People you save count double" (Rampage); "Pick two cards" (Proving ground; "Score 1,500" in a build without cards); "A rest: broken body parts heal a little" (Crossing) | Game Design |
| **One line*** | Narrative's, by kind and the place's state: "He got here first. People are still in the streets." | Narrative |

**Around the cards:** the title "Where to next?"; "Fight 2 of 4" with a pip for each fight (the boss counts); one line of the planet's state in places only ("10 of 12 cities standing, 3 damaged, 2 fallen"); a legend of the three place marks; one button, **Fight here**. A tap on a card selects it (a ring round it); the button confirms. On a pad the d-pad moves between cards and A confirms; Enter or Space on the keyboard.

**Layout.**
- **Desktop:** three cards side by side, the strip across each at 70 px, the button and the legend on the foot line.
- **Phone on its side (844x390):** three compact cards (kind, name, a 34 px strip, opponent, reward). *What it holds, How hard and the one line wait on a second tap (the selected card grows a "More" line, not shown in the mock).*
- **Phone upright:** three rows stacked, each a row of kind, name, a strip and one line for the reward and what it holds; the button is pinned at the foot.

**Rules from Game Design shown honestly:**
- A place that has fallen is never offered; a damaged place is marked as damaged on the card, so the player sees the planet remember (the Crossing's whole point).
- If the planet can only make two offers, the third card is simply not drawn (the cards recentre); never a greyed card.
- A good opponent (a hero) never makes a Rampage: the card is not drawn, nothing says why.
- **The boss is not offered.** Its screen is the same card, alone, headed "The last fight": the place named by the rule (the most populous city still standing), its strip, "The boss waits here", one button, **Fight here**. No choice is shown because there is none.
- The reward is shown as what the player gets, never as something earned by people dying. The Rampage's "people you save count double" is the one reward that mentions people: it is about saving them.

## 2. After the fight (the beats)

**What it is.** Two beats a gap at most, one *aftermath* and one *ahead* (Narrative's grammar), each two to four lines said by people in the world. It is a quiet panel, skippable at any time, that never decides an outcome.

**The panel (mock `beats`):**
- **Top line:** "After the fight" on the left, the place on the right.
- **The planet's places** as one row of twelve city marks (World's place states), the ones **this fight changed ringed with a dashed ring**: the planet remembering, in shapes. Under it, one line in words of what changed ("Harbourgate is damaged. Old Brasswick has fallen.") and one line with the count in the plain type of every other fact: "People lost this fight: 312 of 1,800". No icon, no colour, no emphasis, no animation: it is simply there.
- **The beat:** a card with each line under its speaker's tag (PROTAGONIST, THE RIVAL, THE BOSS, A CIVILIAN, THE RADIO), the speakers Narrative's (`hero`, `rival`, `boss`, `crowd`, `radio`). All the beat's lines show at once (no typewriter); "Beat 1 of 2" at the card's foot.
- **The foot:** "Press any button to skip" (a pad or keyboard; "Tap to skip" on touch) and **Next**. Next shows the second beat, then the next screen. Skipping from any point goes straight to the next screen and changes nothing in the run.
- **Phone on its side:** the places row thins to 38 px and the panel takes the rest; the three lines fit at 16 px. **Phone upright:** the panel fills the height, the buttons pinned at the foot.
- **If a slot has no beat** (Narrative's rule "play nothing"), the panel is simply not shown for it.

**The final approach (the last gap before the boss; mock `approach`).** Narrative's eight steps play in one panel with the same bones: the heading "The last night" and "Step 3 of 8" with eight pips, and no changed-places row (the planet is told by the lines). **The sky behind it darkens one step per beat,** as a plain backdrop change under the dissolve rules (never faster than one a second); it is a mood, and carries no information. The boss's step shows the boss's name tag in the same type as the others (no portrait art until Art has it, and none that is work in progress on a public page).

**Data it reads:** the last stage's place name; the places that changed with their new state (`fallen_name` and the ledger's wear list); the people lost in that fight and the people present at its start; the beats Narrative's picker chose (id, speaker, text), in order. All from the run's ledger. **The HUD draws the strings it is given; it never picks a beat.**

## 3. The run is over (the results)

**What it is.** After the boss, or after a loss with no chance left. Mock `results` and `resultslost`.

**Content, in order:**
1. **A heading and one ending line** (Narrative's, by the planet's state and the hero's branch history): "The boss is beaten" or "The run is over".
2. **Your route:** one row a fight: its number, the place, its kind in words, **Won** or **Lost**. Under it, "Chances used: 1 of 2", "Fight time: 41:08" (from ticks, never the wall clock) and "The hero's path: Witness 2, Trial 1".
3. **The planet,** as environmental results: the row of twelve city marks in their final state; "Cities: 9 standing, 2 damaged, 1 fallen"; "Towns: 24 standing, 5 damaged, 2 fallen"; **"People lost: 7,030 of 14,200 (49%)"**; "Sky: dark" or "clear". Each is a plain line of the same type. The count is shown whole and at once.
4. **The score in its parts,** and the total, from the actions that earn it: fights won, the boss, **people you saved**, chances used, style. **Nothing is added for a death.**
5. **Buttons:** New run, Same planet again (the seed, so a run can be raced or shared), Main menu.

**Layout.** Desktop: two columns (route on the left; the planet and the score on the right). **Phone on its side:** two pages ("Page 1 of 2": the planet; "Page 2 of 2": route and score), Next between, the three buttons on page 2. **Phone upright:** one scrolling column with the buttons pinned; the score shows its total and opens its parts on a tap.

## 4. Legal c08, line by line, and what I am flagging

| c08 says | On these screens |
| :-- | :-- |
| A count and an environmental result, not depicted bodies | Only text and place marks. Nothing depicts a person |
| No score, bonus, achievement, trophy or unlock for deaths | The score lists parts that are actions. No achievement, trophy or unlock is on any screen, and none is proposed. Unlocks stay cosmetic and come from finishing runs |
| No celebratory sound when the count rises | The count is drawn once, final, in plain type. No counting up, no sound, no flash |
| The menace meter is a power meter, not a score | It is on none of these screens. "Dread" (Game Design's hidden number) is never shown |
| Do not stage schools, hospitals or places of worship | The place marks are a city or a town, nothing else. Names come from Narrative's grammar, which must avoid such names |
| Steam achievements are public | None are proposed. If one is, it must be about saving or finishing, never about a count |

**Flags for the EP, Game Design and Legal:**
1. **The villain's run score (`run-mode.md` section 4.2) pays 20 points for each 1% of the planet's people lost.** That is a score for civilian deaths, which c08 forbids. **Proposal:** a villain's run scores on fights won, the boss and style, like the hero's, and shows people lost only as a count on the planet's results. (The hero's "people you saved" is the complement: it removes points for every death and gives none for one. I show it as "People you saved (51%)".)
2. **The results show the count but not who caused it** (the beats do read the cause, for story). A split such as "by you: 40%, by the Rival: 60%" would read as a tally and would give a villain's run a number to chase. I left it out.
3. **The atlas** (a record of planets, "cities saved and lost") is fine as places; it must not rank runs by people lost.
4. **The last-night sky** and the planet's final "Sky: dark" are mood and a result; they pass the c05 slew rule as stated above, to be checked with the flash clips.
5. **The ending line's wording** is Narrative's, and Legal should read it, because it is where a rising count could be made to sound like a result worth having.

## 5. Words (all `terms.json` prompt group; Narrative to own)

Where to next? | Fight {n} of {total} | The planet: {a} of {b} cities standing, {c} damaged, {d} fallen. | RAMPAGE | PROVING GROUND | CROSSING | The fight holds {a} cities, {b} towns | Opponent: {name}, {how} | Starts at {tier}, rises to {tier} | Reward | People you save count double | Pick two cards | A rest: broken body parts heal a little | Fight here | untouched | damaged | fallen | where the fight starts. The strip wraps: it is the whole way round. | The last fight | The boss waits here | After the fight | The last night | Step {n} of {total} | Changed this fight: {sentence} | People lost this fight: {n} of {total} | Beat {n} of {total} | Press any button to skip | Tap to skip | Next | The boss is beaten | The run is over | Your route | Won | Lost | Chances used: {n} of {total} | Fight time: {m}:{s} | The hero's path: Witness {n}, Trial {n} | The planet | Cities: {a} standing, {b} damaged, {c} fallen | Towns: ... | People lost: {n} of {total} ({p}%) | Sky: dark / clear | Score | Fights won | The boss | People you saved ({p}%) | Chances used | Style | Total | New run | Same planet again | Main menu | Page {n} of 2.

## 6. What it needs, and how it would be built (when asked)

- **New widgets, all static draws from a record the host passes** (the HUD reads, never writes the sim): `UiRunOffers`, `UiRunBeat`, `UiRunResults`, and one shared `UiRunStrip` that draws World's strip and its place marks. Behind a feature flag `run_mode` (off). They reuse the menu's focus, touch and pad rules (`UiMenu`) and the pause card's geometry tests.
- **The records:**
  - `offers`: `[{kind, name, strip: {biomes: [[biome, share]], places: [{at, kind, state}], start}, holds: {cities, towns, biomes}, opponent: {name, harder}, tiers: [from, to], reward, line}]`, with `fight` and `of`, and `planet: {cities: {standing, damaged, fallen}}`.
  - `beat`: `{place, changed: [{index, state}], names_line, lost: n, present: n, slot, of, lines: [{speaker, text}], approach_step}`.
  - `results`: `{won, ending, route: [{place, kind, won}], chances: [used, of], ticks, path: {witness, trial}, planet: {cities: [state x12], towns: {..}, lost, present, sky}, score: [{label, points}]}`.
- **Signals:** `run_offer_chosen(index)`, `run_beat_finished()`, `run_results_action(action)`.
- **Tests:** every screen fits and every control is a 48 dp target at the fifteen standard sizes (the offers cards, the beat panel, both results pages); every string is in the data and in `hud_words_check`; **a c08 lint** (no word in the results strings from a banned list: kills, body count, victims, points near casualties; no icon or emphasis drawn for the count: the count's draw call is the same as its neighbours'); no state change twice in a second as a block; the dissolves obey the rate.
- **From others:** World: the strip record per slice (the biome shares, the places with kind and state, the start column) and the planet's place states; Game Design: the offers' kind, opponent, tiers and reward as data, and the results' score parts; Narrative: names, each card's line, the beats, the ending line; Simulation: the run's ledger and its hash.

## 7. For the EP: questions

1. **The villain's-run score** (section 4, flag 1): will Game Design change it, or does Legal want to see it first?
2. **Offer cards on a short phone:** is it acceptable that the one line, "what it holds" and "how hard" wait on a second tap, or should a phone on its side get a two-page offers screen instead?
3. **Are cards in the first build?** The Proving ground's reward reads "Pick two cards" only with them; without them it is "Score 1,500", which is the one reward that is a number.

## 8. Built in scratch (2026-10-17)

The widgets are built and parked behind `features.json` `run_mode` (off): `docs/ui/pending/run-mode/` (README there): `UiRun` (the offers, the beats, the final approach, the results), the HUD's `show_run_offers`, `show_run_beat` and `show_run_results`, four signals, 57 plain strings and 17 checks. The records the host passes are in the header of `ui/widgets/ui_run.gd`. Questions 1 and 3 of section 7 are still open (the villain's-run score; plan cards in the first build); question 2 was answered as mocked (a phone on its side gets compact cards).

## 9. Game Design's answers and the reshaped run (2026-10-17)

- **The villain's run scores 500 per place taken, never deaths** (`run-mode.md` section 4.2, ruled): my flag 1 is closed. The results' score rows are drawn from the record, so no change to the widget; the villain's run's record carries "Places you took" as its part, and the people-lost line stays a count.
- **No plan cards in the MVP:** the Proving ground's reward reads "Two boons, one after the other" and the Crossing's "A rest: every part of you is healed" (the boons replaced the cards and the lives replaced the chances; section 1.4 and 4.1 of `run-mode.md`).
- **The boons screen** is new and built in scratch (`docs/ui/pending/run-boons/`): "Take a boon" (or "Take a boon (1 of 2)" after a Proving ground), three cards, each a shape (a double chevron for a form, a plus for an ability, a ring with a dot for a lifeline, three bars for a rest, an open diamond for a temptation), its name and in plain words what it gives; **a temptation's card says only that it will be remembered, never what it brings**; **Take this**, and **on a temptation's offer a second button, Walk on** ("Take none of these and gain a life"; on a phone on its side the words are in the button: "Walk on, gain a life"). Signals `run_boon_chosen(index)` and `run_boon_walked_on()`. The results say "Lives used: n".
