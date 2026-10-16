# Between-stage story beats: a grammar that reads the run

Owner: Narrative and Fighter Identity. Version 1, 2026-10-16. Orb, 2026-10-16: "the brawler game-mode could be like a roguelike, with multiple stages across different slices of the planet, small dynamic storyline exposition between each stage. the cities would remain damaged between fights, until the final fight against the boss". Game Design is designing the run mode (`docs/design/run-mode.md`); I wrote in parallel, so the **state fields below are my proposal** and Game Design's decide. Everything is an option for Orb. The data is `pending/story_beats.json` (48 beats, 107 lines); a sample for Orb's marks is `voice-lab/homework/27-story-beats.md`. Every line passes the lint (`writing-quality.md` section 0: 4 to 12 words, plain, contractions, banned words, the ellipsis cap). Original; no franchise echoes.

## 1. The idea

A run is a chain of stages on one planet. **Between two stages the game says, in two to four short lines, what the last stage did to the world and where the story is going.** Not a cutscene and not a narrator: the lines are said by the people in the world (the hero, the rival, the boss, a civilian, an in-world radio broadcast), so the player stays the fighter. Which lines play is decided by **what actually happened in the run**: which cities fell and who caused it, who died, which branch the hero is on, how scary the rival has become, whether the last stage was a close loss or a comeback, and how near the boss is.

**Never more than two beats per gap** (one *aftermath*, one *ahead*), because Orb wants fights fast. The last stage before the boss gets the **final approach**, an eight-step set piece.

## 2. The run state the lines read

My proposal. Game Design's `run-mode.md` decides the real fields and bands.

| Field | Values | What it means | Who would supply it |
|---|---|---|---|
| `stage` | early, mid, late | Where in the run we are (early is stages 1 to 2; late is the stage before the boss approach) | Run mode |
| `cities` | none, some, many | How many cities have fallen this run | World (cities have a status that persists) |
| `city_cause` | hero, rival, boss, both | Who did most of the damage to cities | World and Simulation (damage attributed to a fighter) |
| `casualties` | none, some, many | People killed in the last stage (or the run so far: Game Design's window) | Simulation (casualties are already counted) |
| `casualty_cause` | hero, rival, boss | Whose blow or blast did it | Simulation (cause by fighter) |
| `branch` | none, witnessed, tested | The hero's branch (`anguish-branches.md`) | Game Design's anguish rules |
| `branch_event` | entered, carried, faded | The branch just began, continues, or just ended | Same |
| `menace` | low, mid, high | The rival's meter, banded | The rival's existing meter |
| `result` | won, won_close, lost_close, lost | The stage just finished | Run mode (closeness from the wound stages left) |
| `comeback` | brink, after_loss, streak | A win from the brink; the first win after a loss; a run of wins since a loss | Run mode |
| `boss_in` | 3, 2, 1, 0 | Stages until the boss; 0 is the final approach | Run mode |
| `boss` | empress, cyborg, any | Which boss | Run mode |
| `avoided_towns` | true | The hero kept the fight away from settlements | The hero's *care* value, measured |
| `rival_here` | true | The rival appears in this gap | Run mode |

## 3. The grammar

**A beat** is a small record: an id, a **slot**, the **state it needs**, two to four lines, a weight, and a flag `once_per_run`.

- **Slots:** `aftermath` (what just happened), `ahead` (what is coming), `set_piece` (the boss's final approach).
- **Needs:** a list of conditions on the state fields. A missing field means "don't care". A list means "any of". A condition on `rival_here` means the rival must be in the gap, because the line is a reply to him.
- **Lines:** each has a **speaker** (`hero`, `rival`, `boss`, `crowd`, `radio`) and text. The hero's lines are the Protagonist's voice for now (Orb's marks); another fighter in the hero's seat is re-voiced to his own rules later.

**Choosing the beats for a gap.**
1. Keep every beat whose slot fits and whose needs the state satisfies.
2. **Score** each: *specificity* (how many needs it names; a beat that names the cause as well as the count beats one that names only the count) times its weight times a *novelty* term (1 / (1 + times used in this run)).
3. Take the best `aftermath` beat and the best `ahead` beat. If none fits a slot, **play nothing** for it: silence is better than a line that doesn't apply.
4. In the final approach, play the eight set-piece steps in order; each step picks its variant by `boss` and `branch`.
5. A `once_per_run` beat never repeats in a run. A beat does not repeat in two gaps running.
6. **Deterministic:** ties and small jitter come from a seeded draw on the run seed and the stage number, in the presentation layer. The sim never reads it, and a replay of a run shows the same beats.

## 4. What the 48 beats cover

| Group | Beats | What it reads |
|---|---:|---|
| **Cities** | 8 | Untouched at the start; a clean streak; one street damaged by the hero; one by the rival (he is there to answer); the hero's fault, many; the rival's trail, many; both; a town spared on purpose |
| **Casualties** | 6 | None; some or many by the hero (grief, an angry crowd, no power-up); some or many by the rival (the setup for branch A); by the boss |
| **The hero's branch** | 6 | Branch A begins, goes on, fades; branch B begins, goes on, and looks toward the boss |
| **The rival's menace** | 5 | Bored; a tepid compliment; at full strength; a civilian afraid of him; his pride claiming the boss |
| **Results** | 3 | A close win; a close loss (the retry beat); a clear loss |
| **Comeback** | 3 | From the brink; after a loss; a run of wins |
| **The boss draws near** | 3 | Three, two and one stage out |
| **The final approach** (set piece) | 14 | Eight steps; steps 4, 5 and 7 have variants by boss or branch |

A few, as they will read (the file has all 48):

> **After the hero's blows damage a street, no one hurt.**
> Protagonist: "I broke that street. I know it."
> A civilian: "Look at the windows. All of them."
> Protagonist: "Next time I'm taking it somewhere empty."

> **After the rival's attacks kill many, the rival there.**
> Protagonist: "That's too many. I'm done being polite."
> Rival: "Finally. Now you look like you mean it."

> **Two stages out from the boss.**
> Radio: "Three more districts evacuated. The ground's shaking."
> A civilian: "Do you feel that? The whole street's humming."

## 5. The boss's final approach

Eight steps, one beat each (a few have a variant). They play in order in the gap before the last fight.

| Step | What happens | Who speaks |
|---|---|---|
| 1 | The sky changes: ash, black at noon | Radio, a civilian, the hero ("Everyone inside! Now! Move!") |
| 2 | The last evacuation | Radio, a civilian, the hero |
| 3 | The rival joins, on his own terms | Rival, hero ("Don't misunderstand. I just want the first hit.") |
| 4 | The boss arrives | The boss (generic, **Empress** or **Cyborg** variant), and a reply from the hero or rival |
| 5 | The hero's answer, by branch (A: "You hurt them. That ends now."; B: "Show me everything. I'll wait."; none) | Hero, boss |
| 6 | The two argue over the boss | Rival, hero ("Not a chance. We do this together.") |
| 7 | The boss's threat to the planet (generic, Empress, Cyborg) | Boss, hero ("Stop it! There are people down there!") |
| 8 | The first blow | Hero, rival, boss |

Orb's world-catastrophe fight (beams through the crust, a mushroom cloud, the exosphere) is the *fight*; these eight steps are the walk up to it, and the steps give the camera and the sound a clear order to hang on.

## 6. How it keeps to Orb's rules

- **Four to twelve words, plain, a person speaking.** No narrator. The radio is an in-world broadcast, not a voice addressing the player.
- **The hero acts on what he sees** (fascinated, concerned about people, wants the rival's best); **the rival is impatient and short** and never patient (Orb's marks).
- **Casualties by the hero do not power him up.** They shame and the crowd's anger; branch A fires only on the opponent's deaths (`anguish-branches.md`).
- **No promise gag:** the "I'll fix it after" line is retired as a default.
- **The boss keeps their established voice**: the Empress says "petitioners" and "we"; the Cyborg keeps the service script.

## 7. Data shape

`pending/story_beats.json` (parked: a new file in `data/` needs a schema). A beat:

```json
{ "id": "casualties_rival_many", "slot": "aftermath",
  "needs": { "casualties": ["many"], "casualty_cause": ["rival"], "rival_here": true },
  "lines": [ { "who": "hero",  "text": "That's too many. I'm done being polite." },
             { "who": "rival", "text": "Finally. Now you look like you mean it." } ],
  "weight": 1, "once_per_run": false }
```

## 8. What it needs

- **Game Design (run mode):** confirm or replace the state fields in section 2, set the bands (what counts as *some* or *many*, what a *close* result is), and say whether a loss ends a run (then `close_loss` is the end-of-run beat) or lets the player retry the stage.
- **World:** each city's status (whole, damaged, fallen) and **who caused it**. **Simulation:** casualties **by cause**, per fighter.
- **UI:** a beat screen: the lines one at a time, each with the speaker's face cut-in (a civilian or the radio gets none); a skip; no HUD.
- **Camera and Audio:** the final approach's eight steps want their own shots and a rising sound; between ordinary stages a held wide shot of the planet's slice and the damaged cities.
- **Encounter:** the rival's presence in a gap (`rival_here`), and the stage result's closeness.

## 9. Risks

- **Boss voices.** Only the Empress and Cyborg have established voices; a boss who is neither gets the generic lines, which are plain and will read thin.
- **The hero is voiced as the Protagonist.** If the player can choose the Anti-hero as the hero, every `hero` line needs his own version.
- **The rival is a recurring figure** in the beats, but a run may not always include him; `rival_here` guards that.
- **51 of the 107 lines are the hero's;** the rival has 26, the crowd 13, the boss 10 and the radio 7. Orb's marks will say whether the radio and the crowd earn their place.

## 10. Questions for Orb

1. Is an **in-world radio** voice right for the news, or should the news come from the characters only?
2. Should a **loss** end the run (a roguelike) or only repeat the stage?
3. Do you want the **rival to appear in most gaps** (a running relationship across the run), or only now and then?
4. How **short** should a gap feel: one beat or two?
5. Should the hero's **branch be named** in a line ("I'm not playing anymore" says it), or only felt?
