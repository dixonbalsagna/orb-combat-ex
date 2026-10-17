# Between-stage story beats: a grammar that reads the run

Owner: Narrative and Fighter Identity. Version 3, 2026-10-16 (version 2 aligned with Game Design's `docs/design/run-mode.md` sections 2 and 10 and with Legal's c07 and c08; version 3 adds Orb's reshaped run, section 12). Orb, 2026-10-16: "the brawler game-mode could be like a roguelike, with multiple stages across different slices of the planet, small dynamic storyline exposition between each stage. the cities would remain damaged between fights, until the final fight against the boss". The data is `pending/story_beats.json` (**98 beats, 212 lines**); a sample for Orb's marks is `voice-lab/homework/27-story-beats.md`. Every line passes the lint (`writing-quality.md` section 0: 4 to 12 words, plain, contractions, banned words, the ellipsis cap). Everything is an option for Orb. Original; no franchise echoes.

**What changed in version 2.** The state fields now use run-mode's bands and add its four (`revisit`, `fallen_name`, `wound_carried`, `sky`). `boss` gains `rival` (the MVP's boss is the rival at his worst). A loss no longer means a retry: **with a chance left the place falls and the run goes on; with none left the run ends; only the boss is replayed, once.** The beats for those cases are new. The final approach has rival-as-boss variants. Legal's c07 and c08 are applied (section 6). Still to come, in `place-names.md` and `run-lines.md`: the place-name grammar, offer-card lines, boss lines and the endings.

## 1. The idea

A run is a chain of stages on one planet. **Between two stages the game says, in two to four short lines, what the last stage did to the world and where the story is going.** Not a cutscene and not a narrator: the lines are said by people in the world (the hero, the rival, the boss, a civilian, an in-world radio broadcast), so the player stays the fighter. Which lines play is decided by **what actually happened**: which cities fell and who caused it, who died, which branch the hero is on, how scary the rival has become, a loss that took a place, a comeback, and how near the boss is.

**At most two beats a gap** (one *aftermath*, one *ahead*), because Orb wants fights fast. The last gap before the boss gets the **final approach**, an eight-step set piece.

## 2. The run state the lines read

These are run-mode's fields and bands (its section 2), plus three I ask for.

| Field | Values and bands |
|---|---|
| `stage` | early (stages 1 and 2), mid, late (the stage before the boss) |
| `cities` | cities fallen in the run: none (0), some (1 or 2), many (3 or more) |
| `city_cause` | whoever did 60% or more of the run's building damage to cities; otherwise both |
| `casualties` | people killed in the last stage as a share of the people present at its start: none (under 1%), some (1 to 10%), many (over 10%) |
| `casualty_cause` | whoever caused 60% or more; otherwise both |
| `branch`, `branch_event` | none, witnessed, tested; entered, carried, faded |
| `menace` | the villain's menace at the stage's end: low (under 30), mid (30 to 69), high (70 or more) |
| `result` | won, won_close (from the brink, or two or more regions broken), lost_close (the opponent was on the brink, or had two broken), lost |
| `comeback` | brink, after_loss, streak (three wins since the last loss) |
| `boss_in`, `boss` | 3, 2, 1, 0 (0 is the final approach); **rival**, empress, cyborg, any |
| `avoided_towns` | the hero spent under 20% of the stage within 1,500 units of a building, and killed under 1% of the people present |
| `rival_here` | the rival appears in this gap (he was the last stage's opponent, or every second gap otherwise) |
| **`revisit`** (run-mode) | the next stage crosses a place the run has hurt: damaged, or fallen. Its name is `{place}` |
| **`fallen_name`** (run-mode) | a place fell in the last stage. Its name is `{place}` |
| **`wound_carried`** (run-mode) | the hero goes in with a region broken |
| **`sky`** (run-mode) | the sky has darkened (the boss fight only) |
| `chances` (**asked for**) | left or none, after a loss: a chance left means the place falls and the run goes on |
| `retry` (**asked for**) | true when the stage will be replayed: the boss, once, or the "Retry stages" assist |
| `step` | 1 to 8, for a set piece |

## 3. The grammar

**A beat** is a record: an id, a **slot**, the **state it needs**, two to four lines, a weight and a flag `once_per_run`.

- **Slots:** `aftermath` (what just happened), `ahead` (what is coming), `set_piece` (the boss's final approach).
- **Needs:** conditions on the fields above. A missing field means "don't care". A list means "any of". A condition on `rival_here` means the rival is in the gap, because the line is a reply to him.
- **Lines:** each has a **speaker** (`hero`, `rival`, `boss`, `crowd`, `radio`) and text. A line may contain `{place}`, filled with the place's name from the name grammar (`place-names.md`). The hero's lines are the Protagonist's voice for now (Orb's marks).

**Choosing the beats for a gap.**
1. Keep every beat whose slot fits and whose needs the state satisfies.
2. **Score** each: *specificity* (how many needs it names) times its weight times a *novelty* term (1 / (1 + times used in this run)).
3. Take the best `aftermath` and the best `ahead`. If none fits a slot, **play nothing** for it.
4. In the final approach, play the eight steps in order; each picks its variant by `boss` and `branch`.
5. A `once_per_run` beat never repeats. No beat plays in two gaps running.
6. **Deterministic:** ties come from a seeded draw on the run seed and the stage number, in the presentation layer. The sim never reads it; a replay shows the same beats.

**Failing forward** (run-mode 4.1). A loss with a chance left is not a retry: **the place falls, its people flee for good, and the run goes on.** The beats read it as `result: lost` or `lost_close` with `fallen_name` and `chances: left`: the radio names the place, the hero is curious or sorry, and the rival (if he's there) needles. A loss with **no chance left** plays the end-of-run beat. **Only the boss is replayed**, once, with its own beat (`boss_replay`); the old "retry" beat (`close_loss`) now serves the boss's replay and the "Retry stages" assist.

## 4. What the 67 beats cover

| Group | Beats | What it reads |
|---|---:|---|
| **Cities** | 8 | Untouched at the start; a clean streak; a street damaged by the hero (one or two cities); by the rival, with him there; three or more cities by the hero; three or more by the rival; both; a town spared on purpose |
| **Casualties** | 7 | None; some or many by the hero (grief, an angry crowd, no power-up); some or many by the rival (the setup for branch A); by the boss; by both |
| **The hero's branch** | 6 | Branch A begins, goes on, fades; branch B begins, goes on, and looks toward the boss |
| **The rival's menace** | 5 | Bored; a tepid compliment; at full strength; a civilian afraid of him; his pride claiming the boss |
| **Results** | 9 | A close win; **the place falls** after a close or a clear loss (each with and without the rival); **the end of the run**; the boss replayed; a retry |
| **Comeback** | 3 | From the brink; after a loss; a run of wins |
| **The boss draws near** | 5 | Three, two and one stage out; three and one stage out when the rival is the boss |
| **The added fields** | 6 | Revisiting a damaged place; crossing a fallen one; a place lost in a stage that was won; going in wounded (alone and with the rival); the sky darkened |
| **The final approach** | 18 | Eight steps, with variants by boss and branch |

As they will read:

> **A loss with a chance left, a close one.**
> Protagonist: "One more hit. I was that close."
> Radio: "{place} has fallen. The people got out."

> **The next stage crosses a damaged place.**
> Protagonist: "Back in {place}. It still hasn't recovered."
> A civilian: "Half the street is still rubble."
> Protagonist: "Let's not make it worse."

> **The end of the run.**
> A civilian: "Where do we go now?"
> Protagonist: "I'm sorry. I did everything I could."

## 5. The boss's final approach

Eight steps, one beat each (some with variants), in order. **The MVP's boss is the rival**, so he has his own variants of steps 3, 4, 6 and 7; the other bosses keep the rival beside the hero (steps 3 and 6), which is a later option.

| Step | What happens | Variants |
|---|---|---|
| 1 | The sky changes: ash, black at noon | one |
| 2 | The last evacuation | one |
| 3 | **The rival joins on his own terms** (Empress, Cyborg, any) / **the rival waits for the hero** (rival as boss) | 2 |
| 4 | The boss arrives | rival, Empress, Cyborg, any |
| 5 | The hero's answer, by branch: A ("You hurt them. That ends now."), B ("Show me everything. I'll wait."), none | 3 |
| 6 | **The two argue over the boss** (Empress, Cyborg, any) / **the rival asks for everything** (rival as boss) | 2 |
| 7 | The boss's threat to the planet | rival, Empress, Cyborg, any |
| 8 | The first blow | one |

Orb's world-catastrophe fight (a beam into the crust, a blast cloud, the exosphere) is the *fight*; these eight steps are the walk up to it. Boss lines inside the fight are in `run-lines.md`.

## 6. Legal's c07 and c08, applied to the beats

- **c07 (the blast cloud):** the words are *blast cloud*. No *nuclear*, *atomic*, *bomb*, *radiation*, no real city, date or event, and **no siren or countdown** or any line that evokes a real alert. The lint's sensitive-word check in `run-lines.md` catches the words; the final approach uses "evacuation order", not an alert.
- **c08 (the toll):** a count and the planet's state, never bodies or close-ups; **no line cheers a death, and a rising count never sounds worth having.** Casualties the hero causes shame him and turn the crowd; casualties the rival causes feed branch A; neither is ever good news. No school, hospital or place of worship is named or staged, and no child is a victim.
- **Two lines for Legal to read** (the rival's replies after deaths): "Good. That's the look I wanted." (`witnessed_enter`) and "Finally. Now you look like you mean it." (`casualties_rival_many`). They are about the hero's resolve and not about the dead, but "Good" and "Finally" could read as pleased. They are in homework 27, which Orb may be marking, so I have **not** changed them. Alternates if Legal wants: "There it is. Now fight me." and "Now you look like you mean it."

## 7. Voice, unchanged

The hero acts on what he sees (Orb's marks: fascinated, concerned for people, wants the rival's best); the rival is impatient and short, never patient. Casualties by the hero never power him up. The "I'll fix it after" promise stays out. The boss keeps their established voice.

## 8. Data shape

`pending/story_beats.json` (parked: a new file in `data/` needs a schema). A beat:

```json
{ "id": "loss_fall_close", "slot": "aftermath",
  "needs": { "result": ["lost_close"], "chances": ["left"], "fallen_name": true },
  "lines": [ { "who": "hero",  "text": "One more hit. I was that close." },
             { "who": "radio", "text": "{place} has fallen. The people got out." } ],
  "weight": 1, "once_per_run": false }
```

## 9. What is still needed

- **Game Design:** confirm `chances` and `retry` as fields on the ledger (run-mode has the rules; I need them as values), and the window for `casualties` (this stage's gap, as run-mode says).
- **World:** a place's name from the name grammar, at the place's creation.
- **UI:** a beat screen: the lines one at a time, each with the speaker's face cut-in (a civilian or the radio gets none); a skip; no HUD.
- **Camera and Audio:** the final approach's eight steps want their own shots and a rising sound.
- **Legal:** read section 6, and the endings (`run-lines.md`), before Orb sees them.

## 10. Risks

- The generic boss lines are plain and read thin; only the rival, the Empress and the Cyborg have voices.
- Every hero line is the Protagonist's; a run played as the Anti-hero needs its own set.
- **Two lines** wait for Legal's read (section 6).
- None of the 212 lines has been marked by Orb.

## 11. Questions for Orb

1. Is an **in-world radio** voice right for the news, or should the news come from the characters only?
2. Do you want the **rival to appear in most gaps** (a running relationship), or only now and then?
3. How **short** should a gap feel: one beat or two?
4. Should the hero's **branch be named** in a line ("I'm not playing anymore" says it), or only felt?

## 12. The reshaped run: lives, the buff, and the two boss paths (version 3)

Orb, 2026-10-16 (homework 26): "every fight starts from the base form", and "maybe one time the fifth fight sees the rival steps in between you and the boss to let the boss get away. maybe another fight you opted for a more enticing buff between the second and third fight, then you go on to defeat the empress on the fifth fight and the demo-borg appears, having one transformation left before his final form in the final fight." Game Design's reshaped run is five fights and a boss, with extra lives, and the final boss changes with the story. Their document is not written yet, so the **new fields are my proposal**; the 31 new beats (63 lines) are in `pending/story_beats.json`, every line linted and passing the c10 tiers.

**New state fields.** `fight` (1 to 5); `lives` (many, two, last) and `life_event` (spent, gained), which **supersede `chances`**; `buff` (offered, enticing_taken, modest_taken, refused) and `buff_age` (fresh, carried); `boss_path` (default, rival_escape, empress_down); `motive` (pride, appetite, silent: which reason the rival gives).

| Group | Beats | What they read |
|---|---:|---|
| **Lives** | 5 | A loss with lives to spare (he shrugs it off); with two left (the rival needles); the last life (alone, and with the rival there); a life gained |
| **The buff** | 8 | The offer between fights 2 and 3 (a crowd voice, the hero's doubt, the rival's push); what the hero says after taking the big buff (with and without the rival), the modest one, or neither; echoes in fights 4 and 5; the Empress noticing "borrowed strength" |
| **The rival steps in** (`rival_escape`) | 13 | Fight 5 in four steps (the boss is cornered; the rival steps between; the boss leaves, one version each for the Empress, the Cyborg and any boss; the hero and the rival, in three motives); the aftermath; the boss returns in the final approach (three versions); the rival stands aside |
| **The Empress falls** (`empress_down`) | 5 | Fight 5 ends; the Cyborg appears; the final approach has him say one configuration remains (with and without the rival); the extra form starts |

As they will read:

> **The rival steps in (step 2, fight 5).**
> Rival: "That's far enough. Back off."
> Protagonist: "What are you doing? Move!"
> Rival: "I said back off. Not him. Not now."

> **The rival's reason, one of three (Orb picks).**
> Protagonist: "Why did you do that?"
> Rival: "He's mine to beat. Not yours." *(pride)*
> Rival: "You'll get a bigger fight later. Be grateful." *(appetite)*
> Rival: "Don't ask me that." *(silent)*

> **The Cyborg, with one form left.**
> Cyborg: "One form left behind my limiter. Push me."
> Rival: "Watch it. He's got one more form."

> **The enticing buff.**
> Crowd: "Two to choose from. The big one's tempting."
> Protagonist: "Too good to be free. What's the catch?"
> Rival: "Take it. Quit being so careful."

**What I did not decide, and why.** (1) *What the buff is or costs.* The beats say it is tempting and that the hero notices it; they never say what it is, so Game Design can make it a cost, a gift, or a trap. (2) *Where the escaped boss goes.* After `rival_escape` the same boss returns in the final approach, but the rival could instead be the final boss; the three "returns" beats are written for the first. (3) *Who sent the buff.* The Empress's line, "Borrowed strength, insect. We can smell it.", works whether or not she sent it. (4) *The Cyborg has no minions* (Orb, homework 19): he is alone in every beat here.

**The rival's voice.** The new rival lines follow the voice rules (short, impatient, contractions); I did not touch the homework 27 lines (Orb decides those in homework 29).

**For Game Design (NEEDS).** Confirm `fight`, `lives`, `life_event`, `buff`, `buff_age`, `boss_path` and `motive` as run-state values (or tell me their names), and which fight each boss sits in; confirm that `chances` can be replaced by `lives`; say whether `empress_down` and `rival_escape` can happen in the same run (I assumed they are alternatives for fight 5).
