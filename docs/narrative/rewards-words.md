# Titles, keepsakes and the run, boons and haul wording

Owner: Narrative and Fighter Identity. Version 2, 2026-10-18 (Legal's renames RL-158; Game Design's 6a to 6c: titles confirmed, four keepsake triggers swapped, two boon names changed). Asked by Game Design's reward economy (`docs/design/run-mode.md` section 4.4; `docs/design/unlocks.md`): "about 40 titles ... (Narrative words them)", the keepsake names, and wording for UI's run and boons screens. The data is `pending/titles.json`, `pending/keepsakes.json` and `pending/run_screens.json`; **nothing is marked by Orb, so none is final and none has moved to `data/`**. Lines follow the voice bibles (`voice-bibles.md`) and the lint. Claude-written. Original; no franchise echoes.

## 1. The forty titles

A title is a name, two to three words, shown on the fighter-select card and in the beats' cut-ins. It is read in the fighter's own voice but is never a line. **No title is earned by a death or a toll** (Legal c08), and none uses the words kill, dead or victim; "Demon" stays out of every title (Legal).

**Twenty-four style-label titles** (4 fighters x 6 labels, earned at 10 finishes with that label):

| Label (10 finishes) | Protagonist | Rival | Empress | Cyborg |
|---|---|---|---|---|
| turtle | Human Wall | Cold Guard | Walled Throne | Armoured Gut |
| rusher | Front Foot | Hard Press | Crown Rush | Starving Charge |
| runner | Quick Feet | Out of Reach | Slips the Court | Light Chassis |
| charger | Slow Burn | Tight Spring | Building a Revision | Stoking Up |
| sniper | Clean Shot | Surgical | By Decree | Picky Eater |
| mixer | Whole Toolbox | Top of the List | Many Hands | Omnivore |

**Four mastery-60 nameplates:** Protagonist: **Still Grinning**, Rival: **First Place**, Empress: **Her Own Empire**, Cyborg: **Bottomless**.

**Ten run-style titles, one for Pressure 10 and one for the atlas** (the conditions are mine, matched to Game Design's list of run styles; Game Design confirms which ten it wants):

| Title | Earned by |
|---|---|
| **Every Direction** | In one run, use every kind of launch. |
| **Tower Hopper** | Chain a launch through three towers. |
| **Inside Job** | Land an inside chain. |
| **Worth the Wait** | Release a slingshot from a full coil. |
| **Spot On** | Win a duel of perfect blocks. |
| **First Try** | Finish a run without spending a life. |
| **The City Stood** | Defend a city to the end of its fight. |
| **Walked On** | Finish a run having turned down the temptation. |
| **Quiet Road** | Win a run taking only Crossings. |
| **Well Equipped** | Take one boon of every kind in a single run. |
| **Ten Deep** | Clear Pressure 10. |
| **Well Travelled** | Stamp every planet in the atlas. |

That is 24 + 4 + 10 + 2 = 40.

## 2. The thirty keepsakes

A keepsake is a small trophy of what happened in a fight just won, shown in the haul and on the menu shelf (run-mode section 4.4). **None comes from a death or a toll.** The trigger names an event the fight log has or Game Design adds. `{place}` is the fight's place name.

| Keepsake | Its line | Trigger |
|---|---|---|
| Tower Brick | Still warm. From the tower in the fight. | `tower_fell` |
| Bridge Bolt | One bolt from {place}'s bridge. Heavier than it looks. | `bridge_fell` |
| Cracked Lens | The rival's lens. He'd like it back. | `rival_head_battered` |
| Bent Frame | Custom, he said. It still is. | `rival_head_broken` |
| Scorched Banner | A banner from {place}, singed at one corner. | `fire_started` |
| Blast Sand Chip | A chip of sand the blast turned hard. | `crater_big` |
| Clash Ribbon | Scorched ribbon from a beam struggle you won. | `clash_won` |
| Singed Sleeve | A sleeve that lost the beam struggle. | `clash_lost` |
| Torn Knuckle Wrap | Torn on the first blow. Worth it. | `first_blow` |
| Chalked Hand | Chalk, left on the ground where you got up. | `comeback` |
| Coil Spring | Wound tight, then let go. It still hums. | `coil_release` |
| Salt Stone | A pebble that came out of the sea with you. | `biome_ocean` |
| Hot Sand Jar | Sand from {place}. Warm even at night. | `biome_desert` |
| Slate Chip | A flat chip of slate from the ridge. | `biome_mountains` |
| Split Branch | A branch that took a hit meant for you. | `biome_forest` |
| Frost Shard | A sliver of ice that never melts. | `biome_ice` |
| Whole Window | One window, still unbroken, in a battered street. | `clean_win` |
| Thank-You Note | From someone you got out. No name, just thanks. | `city_stood` |
| Splint Tape | Held your arm together for the finish. | `won_wounded` |
| Patched Glove | Stitched twice. It still fits. | `won_after_life` |
| Ranking Slip | His notes on you. You rank higher than he admits. | `rival_defeated` |
| Dropped Cuff Link | A cuff link he left behind when he stepped in. | `rival_escape_arc` |
| Too-Bright Token | Shinier than it should be. You kept it. | `temptation_taken` |
| Plain Coin | You walked on. It's the only thing you kept. | `walked_on` |
| Silk Scrap | A scrap of her silk. It cuts like paper. | `empress_defeated` |
| Cold Limiter | His limiter chip, cracked and finally quiet. | `cyborg_defeated` |
| Sky Jar | A jar of the dark sky, sealed before it settled. | `boss_beaten` |
| Streetlamp Glass | A lens from a lamp that kept burning. | `night_fight` |
| Worn Stopwatch | Stopped at the end of the longest fight. | `long_fight` |
| Unused Bandage | You didn't need it. Keep it anyway. | `short_fight` |

## 3. The boons screen

Plain words, never a rule or a number the player has to do sums on. UI's `terms.json` has the screen's strings already; I have kept them and suggest two small changes (section 3.3). The boon names and "gives" lines are for Game Design's pool: `{n}` is read from the plan's data, `{form}` is the form's name on the player's branch (the branch names wait for Orb's pick). **A temptation's card shows only one of its lines, never what it brings.**

### 3.1 The boons

| Kind | Name | What it gives (the card's line) |
|---|---|---|
| form | **Reach Higher** | From now on, you can reach {form} in every fight. |
| form | **Higher Still** | From now on, you can reach {form}, the top step. |
| ability | **Heavier Hands** | Your blows hit {n}% harder. |
| ability | **Deeper Tank** | Your energy tank holds {n} more. |
| ability | **Steady Flow** | You gain {n} more energy each second. |
| ability | **Thick Skin** | A held guard takes {n}% less damage. |
| ability | **Iron Core** | Your core wears {n}% slower. |
| ability | **Early Breath** | Your second breath starts {n} second sooner. |
| ability | **Quick Feet** | You move {n}% faster. |
| ability | **Slippery** | Your dodge-cancel recovers in {n} seconds. |
| ability | **Quick Break** | Your burst recovers in {n} seconds. |
| ability | **Afterburn** | Your sprint is {n}% faster. |
| ability | **Closer** | A rush closes the gap {n}% faster. |
| ability | **Planted Feet** | Knockback slides you {n}% less. |
| ability | **Fourth Slot** | A fourth special joins your moves for this run. |
| ability | **Short Fuse** | Your signature recovers in {n} seconds. |
| ability | **Cheap Burst** | A burst costs {n} energy. |
| ability | **Grudge** | After surviving a finisher, hit {n}% harder for 15 seconds. |
| ability | **Sharp Read** | Your counter window after a perfect block is longer. |
| ability | **Another Finish** | A new version of your signature joins your moves. |
| ability | **Shape the Ground** | A move that changes the land joins your set for this run. |
| ability | **Heavier Spring** | Waiting before a transformation pays off more. |
| lifeline | **One More Go** | You get one more life. |
| rest | **A Breather** | Every part of you is healed. |
| temptation | **Something Is Offered** | This will be remembered. |

**Temptation lines** (one is drawn per offer, by the seed): "This will be remembered." / "It looks too good. It will be remembered." / "You can take it. It won't forget you." / "Nothing is free. This will be remembered." / "Everyone will remember who took this."

### 3.2 What the fighters say when a boon is taken

These are one-liners for the boon screen's cut-in, and they are skippable. The hero is the Protagonist (adrenaline brawler: warm and tactile); the rival speaks only when he is in the gap.

**The Protagonist**
> take form: "Higher? Yes! I can feel the next step!"
> take ability: "Nice. That'll help my timing."
> take lifeline: "One more go? I'll take it!"
> take rest: "Ahh. My ribs say thanks."
> take temptation: "Too shiny. But I'll take it."
> walk on: "No, thanks. I'd rather earn it."

**The rival**
> take form: "About time. Climb faster, amateur."
> take ability: "A little help? Typical third-rate."
> take temptation: "Take it. Quit being so careful."
> walk on: "Free power, and you refuse? Fool."
> take rest: "Resting already? Fine. I'll wait."

### 3.3 Changes to UI's strings

- "Walk on" stays. Its hint changes from "Take none of these and gain a life" to **"Say no to all three and gain a life"** (the original reads as an instruction to the screen). The compact button "Walk on, gain a life" stays.
- "Chances used" becomes "Lives used" everywhere (UI already did this on the boons patch; the results page should too).

## 4. The haul

| Key | Text |
|---|---|
| `run_boon_title` | Take a boon |
| `run_boon_title_n` | Take a boon ({n} of {total}) |
| `run_boon_take` | Take this |
| `run_boon_walk` | Walk on |
| `run_boon_walk_hint` | Say no to all three and gain a life |
| `run_boon_walk_life` | Walk on, gain a life |
| `run_boon_sub` | Lives left: {lives}. Highest form you can reach: {tier}. |
| `run_bk_form` | FORM |
| `run_bk_ability` | ABILITY |
| `run_bk_lifeline` | LIFELINE |
| `run_bk_rest` | REST |
| `run_bk_temptation` | TEMPTATION |
| `run_lives_used` | Lives used: {n} |
| `haul_title` | The haul |
| `haul_points` | Mastery points: {n} |
| `haul_keepsakes` | Keepsakes from this run |
| `haul_none` | No keepsakes this time |
| `haul_feats` | Moments you met: {n} |
| `haul_styles` | Styles you showed: {n} |
| `haul_title_new` | New title: {name} |
| `haul_pick` | Pick one reward |
| `haul_pick_n` | Pick one of three |
| `keepsake_new` | New keepsake: {name} |
| `shelf_title` | Your shelf |
| `shelf_empty` | Nothing here yet. Win a fight. |

Nothing on the haul counts the dead as a result. The people-lost line stays a count, drawn like its neighbours (Legal c08).

## 5. Audio's two reel lines (the Empress's "Gahaha!" and the Cyborg's hunger)

**I cannot play audio, so I have judged the written lines only, not how they sound.** (I also opened `audio/preview/ab/ANSWERS.md` while looking for the lines, which spoils the blind order; I did not use it to judge anything.) The sound itself needs Orb's ears.

- **The Empress:** "Ohoho. Cute. Cute! ...Filed under Cute." and "Gahaha! Bring me their roof, my petitioners. We are not amused." The booming "Gahaha!" fits the new bible. The rest does not: "Filed under Cute" is the dry bureaucratic joke the bible retires, "my petitioners" and "We are not amused" put petitioner and the royal "we" in every breath, and "me" against "we" mixes the two. Suggested reel lines in the new voice: **"Hahaha! Look at you crawl, rat!"** and **"Gahaha! Bring us their roof, insect!"**
- **The Cyborg:** "Sensors say crunchy. Tenderising now." and "Protein. More protein! I can smell the marrow in your chassis." The hunger fits the bible well (protein, sensors, crunchy). Two cautions: "marrow in your chassis" mixes meat and steel in one noun, where the bible wants the two split ("steel arm, meaty arm"); and "tenderising" is on Legal's list of Cyborg lines (RL-153). Suggested: **"Sensors say crunchy. Hold still, snack!"** and **"Protein! More protein! I can smell your marrow."**
- Also, the rival's reel line "You were adequate. That is the highest thing I say." has no contraction and admits respect, both retired by Orb's marks. Suggested: **"Barely top ten. Don't let it go to your head."**

## 6. What it needs

- **Game Design:** confirm the ten run-style titles; which events exist in the fight log for the 30 keepsake triggers; the boon pool (names and `{n}` values come from the plan).
- **UI:** the two string changes in 3.3 and the haul keys in section 4.
- **Tools:** schemas for `titles`, `keepsakes` and `run_screens` when Orb has marked the wording; they stay in `pending/` until then.
- **Legal:** read the keepsakes (the Plain Coin and the Thank-You Note touch on the people saved) and the temptation lines.
