# Campaign templates: the rescue, "Previously on", training, rematch, threads and cliffhangers

Owner: Narrative and Fighter Identity. Version 1, 2026-10-25. Game Design's campaign (`docs/design/campaign.md`, Orb's hybrid of the Planet Run and Episodes) needs story-beat templates for the parts it added to my earlier library (`beat-templates.md`, 30 templates and 45 samples). This page adds **26 templates in six families**, one filled sample each, and maps **all fifteen families** onto the five columns. **Templates only, slots only, no new lore and no new names: Orb writes the universe.** The data is `pending/campaign_templates.json`; the marking sheet is `homework/voice-story-names/LATER - story - campaign templates.md`. Every sample line passes the lint, and `beat-check.py` (extended to this file) passes. Nothing is marked by Orb, and Legal has not screened the campaign (it is screening §4 and §5.2).

## 1. The new slots

The campaign reads the ledger slots of its §6 (`last`, `wrecked`, `home_wear`, `place`, `prev_place`, `next`, `thread`, `rescued_by`, `lost_episode`, `lesson`, `n_left`) on top of my earlier set. The earlier slots stand; these are new:

| Slot | What it is |
|---|---|
| `episode` | Which episode of the arc: 1, 2 or 3 (the pilot, the middle, the finale). |
| `arc_boss` | The arc's boss fighter (a roster id) whose home ground ends the arc. |
| `thread` | An open promise carried across episodes: a debt, a grudge, an ally who switched sides, a promised return. A kind and the fighter it names; whole numbers and ids only. |
| `rescued_by` | The ally from the arc's cast who flew in when the player fell (campaign.md 5.1). |
| `lost_episode` | That the last episode was lost, where (a place name) and to whom (a fighter id). |
| `lesson` | What the training stage taught, as a drill name: the beam struggle, the air game, breaking a grab, the guard. |

**There is no toll slot.** `toll_band` stays as it was (coarse, never a score, never read by a Cyborg line), and none of the new templates reads it. That follows campaign.md §6, Legal c08 and ln05.

## 2. The rules every template here follows

- **Slots only:** no new lore, no new names. Place names in the samples (the harbour, the ridge, Rankhold) are placeholders.
- **A beat is one to three lines, skippable, over play or on a card.** It never decides an outcome.
- **A recap or a card is in-world:** two lines from the radio, never a narrator speaking to the player.
- **Places and wear only** for any ruined ground, any front and any home: damaged or fallen is a state, never a count and never a person (ln05).
- **The Cyborg** reads wear and a thing wrecked only. `home_wear` is valid for him **only for his own breaking yard**, never a claimed town; the three templates that read it carry that rule and `beat-check.py` checks it (`usable()` is the picker's filter). No Cyborg line names people, a toll or a casualty.
- **"Rivals remember" is beats reading the ledger.** It is not a hierarchy or a promotion system of enemies: nothing here ranks or promotes an enemy, and the rival's memory is only `last`, `wrecked`, `thread` and `lost_episode`.
- **The training lesson is for that episode only** and never carries past the run (run-mode §4.4); the Rival's lesson lines stay grudging, never open respect.
- **Voices** follow the bibles: the Protagonist apologises or promises to mend only after a fight, the Empress's guards speak only in a 3v1 (none of these does), "petitioner" is rare.

## 3. The nine families, and the six new ones, on the five columns

| Column | Its role | Earlier families | Added by this page |
|---|---|---|---|
| **1. Cold open** | The pair arrive; trouble is already there | `arrival` | previously_on (recap, if the last episode was won); training (replaces the cold open after a lost episode); threads (a grudge or debt carried in) |
| **2. Rise** | A grudge comes to a head | `grudge`, `rematch` | rematch_fallen (always offered after a lost episode); threads (debt opens) |
| **3. Twist** | The episode turns | `third_party`, `ally_switches` | rescue (any column, once an episode); threads (an ally switches back) |
| **4. Escalation** | The stakes rise: a home is threatened | `home_threat` | threads (a grudge or debt pays); rematch_fallen if the ground fell |
| **5. Climax** | The episode's opponent on his home ground | `boss_taunt` | threads (a promised return keeps its promise) |
| **Cliffhanger card** | Next time | `cliffhanger` | cliff_cards (to be continued, next episode, the finale, an open thread) |
| **The arc's finale** | Replaces column 5 of the last episode | `boss_taunt` | cliff_finale (the card before it, at the end of episode 2); previously_on (the recap that opens episode 3) |

The finale (episode 3) swaps column 5 for the arc's boss on his home ground. The recap that opens it reads `previously_on`; the card before it is `cliff_finale`. A **rescue** can fire in any column, once an episode.

## 4. The templates
### The rescue: an ally from the arc's cast flies in

campaign.md 5.1. When the player is knocked out before a life is spent, an ally from the arc's cast arrives and the player takes them over. The beats are short and sit over play.

| Id | Column | Reads | When | Notes |
|---|---|---|---|---|
| `resc_arrives` | any | `rescued_by`, `opp`, `place` | The player is knocked out before a life is spent; once an episode | The player then plays the ally (campaign.md 5.1). |
| `resc_opp_reacts` | any | `opp`, `rescued_by` | Directly after resc_arrives |  |
| `resc_won_debt` | next beat gap | `rescued_by`, `thread` | The ally won the stage | Opens a debt thread. |
| `resc_partner_later` | 2 to 4 | `rescued_by`, `episode` | A later stage offers the ally as a partner place |  |

**Samples** (placeholder names):

*resc_arrives* (rescued_by=RIVAL, opp=EMPRESS)
> **Rival:** "Get up, amateur. I'll take it from here."
> **Protagonist:** "You came! Thanks! Hit her hard!"

*resc_opp_reacts* (opp=EMPRESS, rescued_by=RIVAL)
> **Empress:** "Another rat? Gahaha! The more, the merrier!"

*resc_won_debt* (rescued_by=RIVAL, thread=debt)
> **Protagonist:** "I owe you one. Don't say it."
> **Rival:** "Don't thank me. Pay me back."

*resc_partner_later* (rescued_by=EMPRESS, episode=2)
> **Empress:** "Hahaha! We saved you, rat. Remember it!"
> **Protagonist:** "I remember! Fight beside me?"

### "Previously on": a lost episode airs, and the next one answers it

campaign.md 5.2. A recap is two in-world radio lines, never a narrator speaking to the player, and it reads places and wear only.

| Id | Column | Reads | When | Notes |
|---|---|---|---|---|
| `prev_cold` | 1 (cold open) | `last`, `place`, `home_wear` | Start of an episode after a WON episode | A recap is two radio lines, never a toll. |
| `prev_lost_card` | end of a lost episode | `lost_episode`, `place`, `home_wear` | The episode's lives are gone | Place and wear only (ln05). |
| `prev_stakes` | 1 (cold open) | `lost_episode`, `place`, `home_wear`, `opp` | Start of the next episode | The Cyborg's version reads wear and a thing wrecked only; home_wear only for his own yard; never a toll (ln04, ln05). |
| `prev_winner` | 1 (cold open) | `opp`, `last` | The fighter who won the lost episode opens the next |  |
| `prev_hook` | 1 (cold open) | `lost_episode`, `lesson` | Before the training stage |  |

**Samples** (placeholder names):

*prev_cold* (last=won, place=the harbour, home_wear=damaged)
> **Radio:** "Last time, the Rival took the ridge."
> **Radio:** "The harbour still stands. For now."

*prev_lost_card* (lost_episode=(the harbour, RIVAL))
> **Radio:** "To be continued. The harbour took heavy damage."

*prev_stakes* (lost_episode=(the ridge, RIVAL), home_wear=fallen)
> **Radio:** "Rankhold holds the high ground. The ridge fell."
> **Rival:** "I kept the ground. Come and take it."

*prev_winner* (opp=RIVAL, last=won)
> **Rival:** "Last time, I ranked you low. Climb."

*prev_hook* (lost_episode=(the harbour, RIVAL), lesson=the beam struggle)
> **Protagonist:** "Okay. I know what beat me. Again!"

### The training lesson

campaign.md 5.2. A 60 to 90 second drill replaces the cold open after a lost episode. The one who beat the player sets it, grudgingly. The lesson lasts that episode only.

| Id | Column | Reads | When | Notes |
|---|---|---|---|---|
| `train_open` | 1 (replaces the cold open) | `opp`, `lesson` | Start of the next episode after a lost one; a 60 to 90 second drill | The drill is against what beat the player. |
| `train_frame` | 1 (replaces the cold open) | `lesson` | The drill starts |  |
| `train_clear` | 1 (replaces the cold open) | `lesson`, `opp` | The drill is cleared | The lesson is for this episode only (campaign.md 5.2). |
| `train_retry` | 1 (replaces the cold open) | `lesson`, `opp` | The drill is failed |  |

**Samples** (placeholder names):

*train_open* (opp=RIVAL, lesson=the beam struggle)
> **Rival:** "Stand there. Block it, if you can."
> **Protagonist:** "Okay, teach me! I'm listening!"

*train_frame* (lesson=the beam struggle)
> **Radio:** "Today's lesson: beating the beam."

*train_clear* (lesson=the air game, opp=RIVAL)
> **Rival:** "Fine. You learned something. Don't waste it."
> **Radio:** "Lesson learned: the air game."

*train_retry* (lesson=breaking a grab, opp=RIVAL)
> **Rival:** "Again. Your feet were wrong."
> **Protagonist:** "Again! One more try!"

### The guaranteed rematch on fallen ground

campaign.md 5.2. The rise column always offers a rematch with the one who won, on the ground that fell. The ground is a place with a wear state, nothing more.

| Id | Column | Reads | When | Notes |
|---|---|---|---|---|
| `refall_offer` | 2 (rise) | `opp`, `place`, `home_wear` | After a lost episode, the rise column always offers a rematch with the one who won, on the ground that fell | Place and wear only. |
| `refall_claim` | 2 (rise) | `opp`, `place`, `claim` | On arrival at the ruined ground |  |
| `refall_wreck_cyborg` | 2 (rise) | `opp`, `wrecked`, `place` | The Cyborg's version of the above | The Cyborg's version reads wear and a thing wrecked only; home_wear only for his own yard; never a toll (ln04, ln05). |
| `refall_clear` | after the stage | `place`, `home_wear` | After the rematch is won | After the fight only (Orb's ruling). |

**Samples** (placeholder names):

*refall_offer* (opp=RIVAL, place=the harbour, home_wear=fallen)
> **Radio:** "The harbour fell last time. The Rival waits there."
> **Protagonist:** "Back to the harbour. Let's finish it!"

*refall_claim* (opp=RIVAL, place=the harbour, claim=the high ground)
> **Rival:** "Same ruins. Same result, amateur."

*refall_wreck_cyborg* (opp=CYBORG, wrecked=a tower, place=the ridge)
> **Cyborg:** "Good wreckage here. I saved some!"

*refall_clear* (place=the harbour, home_wear=damaged)
> **Protagonist:** "Quiet again. We'll rebuild it, promise."
> **A civilian:** "Please don't break it again."

### Threads that carry across episodes

campaign.md section 4. A thread is a small open promise (a debt, a grudge, a switched ally, a promised return) held as ids and whole numbers.

| Id | Column | Reads | When | Notes |
|---|---|---|---|---|
| `thr_debt_open` | 2 or 3 | `thread`, `opp` | A debt thread opens |  |
| `thr_debt_paid` | 4 or 5 | `thread`, `opp` | A debt thread is paid |  |
| `thr_grudge_carry` | 2 to 4 | `thread`, `opp`, `last` | A grudge thread carries into a new episode |  |
| `thr_switch_back` | 3 (twist) | `thread`, `opp` | An ally who switched sides switches again |  |
| `thr_promise_kept` | 5 (climax) | `thread`, `next` | A promised return keeps its promise |  |

**Samples** (placeholder names):

*thr_debt_open* (thread=debt, opp=EMPRESS)
> **Empress:** "You owe us a favour, rat."

*thr_debt_paid* (thread=debt, opp=RIVAL)
> **Protagonist:** "Debt's paid. We're even now!"
> **Rival:** "Even? Don't get cosy."

*thr_grudge_carry* (thread=grudge, opp=RIVAL, last=lost)
> **Rival:** "I haven't forgotten last time. Have you?"

*thr_switch_back* (thread=ally switched, opp=EMPRESS)
> **Empress:** "Hahaha! We switched sides again. Surprise!"

*thr_promise_kept* (thread=promised return, opp=CYBORG)
> **Cyborg:** "I said I'd come back. Hungrier!"

### The cliffhanger cards

The card that ends an episode: to be continued, next episode, the finale, or a thread left open.

| Id | Column | Reads | When | Notes |
|---|---|---|---|---|
| `cliff_tbc` | cliffhanger | `lost_episode`, `place` | The lost episode's last card |  |
| `cliff_next_ep` | cliffhanger | `next`, `episode` | The end of an episode that was won |  |
| `cliff_finale` | cliffhanger (episode 2) | `arc_boss`, `episode` | The end of the middle episode |  |
| `cliff_thread` | cliffhanger | `thread` | An open thread is left hanging |  |

**Samples** (placeholder names):

*cliff_tbc* (lost_episode=(the harbour, RIVAL))
> **Radio:** "To be continued. Next episode answers this."

*cliff_next_ep* (next=EMPRESS on the plains, episode=2)
> **Radio:** "Next episode: the Empress, on the open plains."

*cliff_finale* (arc_boss=EMPRESS, episode=2)
> **Radio:** "Next: the finale, at the boss's home."
> **Empress:** "We will see you at the throne, rat."

*cliff_thread* (thread=debt)
> **Radio:** "Still open: the debt. Who collects?"

## 5. What it needs

- **Game Design:** the ledger fills `thread`, `rescued_by`, `lost_episode`, `lesson`, `episode` and `arc_boss`, as whole numbers and ids (campaign.md §4 and §6). Whether a recap line may also name the episode's number.
- **Simulation:** the arc block in the run state holds the threads and the lost episode's record.
- **UI and Camera:** the recap and cliffhanger cards (a card of two radio lines; no narrator voice); a partner's face for the rescuer.
- **Legal:** the campaign's §4 memory and §5.2 rematch, which it is screening; and the Cyborg's two samples (a wreckage line on the ruined ground, and a promised return).
- **Tools:** a schema for `campaign_templates` once Orb has marked the samples (it stays in `pending/`).

## 6. Questions for Orb

1. Should a **recap** be spoken by the radio only, or may a fighter open it ("Last time, I ranked you low.")? Both are in the samples.
2. Is the **rescuer** best a rival who owes the hero, or someone from an earlier twist? The samples use the Rival and the Empress.
3. Which **threads** should the arc carry: debts, grudges, a switched ally, a promised return? They imply history, which Orb writes.
