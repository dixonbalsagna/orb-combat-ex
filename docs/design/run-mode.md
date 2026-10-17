# Run mode: a roguelike run across one planet

Owner: Game Design. Date: 2026-10-16. **Paper only.** Nothing here is built or run by me, and **every number is a first value.** It builds on World's stored planet (`docs/world/planet-slice.md`), on `hero-forms.md` and `buildings.md` §6, and it answers Narrative's run state (`docs/narrative/story-beats.md` §2 and §8). It meets Legal's RL-145 (`docs/legal/catastrophe-and-city-screen.md`, c01 to c09). Co-op is not designed here (it is held). The working mode id is `run`.

**Reshaped by Orb's answers to homework 26** (2026-10-16 evening, `docs/ep/vision.md`): every fight starts from the base form, and higher forms become reachable through boons and unlocked abilities; five fights and a boss; a lost fight is retried or ends the run, with extra lives; bosses vary by the run's story; between runs, looks and harder challenges, with a reward economy to shower players with. Rule of cool takes precedence everywhere.

**Orb** (2026-10-16, `docs/ep/vision.md`, "Orb on the stored planet"): "the brawler game-mode could be like a roguelike, with multiple stages across different slices of the planet, small dynamic storyline exposition between each stage. the cities would remain damaged between fights, until the final fight against the boss, where world-catastrophe level variants of abilities can cause large scale destruction".

## 0. The run in one paragraph

**A run is one planet seed, one fighter, and a chain of fights.** Each fight is a full match on its own slice of that planet, and the player picks it from three offers on the globe. Between fights, two short story beats read what happened, and **the player takes a boon:** a form unlocked, an ability, a lifeline, or now and then a temptation that changes the story. The planet keeps every wound: craters, fallen towers and the people lost. **Every fight starts from the base form,** and the boons decide how high the player can climb in it. It ends in a boss fight that opens a fifth tier, the catastrophe tier, where beams reach the magma, a blast cloud darkens the sky, and the fight can rise into the exosphere.

**Where the run's growth lives.** In the boons: how high the player can transform, and the abilities he has gathered. Opponents climb by the chapter whatever the player picked, so a run that skips form unlocks for something else is a real gamble. The fighters' balance is still versus's, since every boon is a run-only gain and nothing carries past the run but looks (§4.4).

## 1. The run's shape

### 1.1 Fights, forms and length

| | Fight 1 | Fight 2 | Fight 3 | Fight 4 | Fight 5 | The boss |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **The full run** (Orb's pick) | Base, up to the forms unlocked | The same | The same | The same | The same | Base, up to the forms unlocked, then tier 5 at the tremor |
| **What the opponent can reach** | Tier 2 | 2 | 3 | 3 | 4 | The boss's arc decides its start (§5.1); tier 5 at the tremor |
| **The MVP run** (§8) | Three fights and the boss, the opponent reaching 2, 3 and 4 | | | | | |

- **A stage and a fight are the same thing here.**
- **Every fight starts from the base form,** with power at 0, and climbs its ladder as a match does. **How high the player can go is the run's ceiling:** at the run's start, the first step (tier 2). Each form boon (§1.4) raises it one tier, to 4 at most.
- **A fight is a full match in its rules.** It has the brawl, the wounds, the brink and the finisher, and Orb's floor of five minutes or more holds for each one (the 10th percentile at 300 s or more). Target: 5 to 7 minutes.
- **The slingshot** (`hero-forms.md` §4b) is the Protagonist's answer to an opponent who climbs higher than his ceiling allows him yet: he banks and coils.
- **Lengths:** the full run is six fights, about 50 minutes with the beats and the boons. The MVP is about 30.

### 1.2 Choosing each stage: three offers on the globe

Before each stage the globe turns, and **three touch-downs are offered**, each a card on the map with the route drawn to it as a great-circle arc. Each offer is one of World's slices: a touch-down T and its great circle, from the slice picker (`planet-slice.md`), drawn from the run's offer stream (§7).

| Kind (working names) | What it is | What it does to the hero's branches | Its reward |
| :--- | :--- | :--- | :--- |
| **Rampage** | A populated place, and the opponent has touched down first. The stage opens 15 s after his arrival, with him already in the streets | Witness fills: he is feeding where the hero can see | People saved count double in the score |
| **Proving ground** | A sparse place: mountains, desert, ice or open sea with a town. The opponent starts one tier above the run's tier (at most 4), at one AI level harder (at most hard) | Trial fills: the opponent has risen first | Two boons to pick from, one after the other, where other fights give one |
| **Crossing** | A plain stage. From the second chapter it touches down by, or crosses, a place damaged earlier in the run | Either | **A rest:** after the fight, every region healed to fresh |

- **One of each kind** when the planet allows it. A good opponent (a hero, §5.3) never makes a Rampage offer.
- **An offer card shows:** the place's name and kind, what the slice holds (cities, towns, biomes), each place's state (fresh, damaged, fallen), the opponent, the stage's tier, the reward, and one line (Narrative's).
- **Rules for the offers:**
  - While any fresh city stands, at least one offer touches down at one.
  - From the second chapter, one offer (the Crossing) revisits damage, so the player sees the planet remember.
  - No offer touches down in a fallen place. Ruins are crossed, not fought in.
  - **No school, hospital or place of worship is ever a staged target** (Legal c08). No offer, beat or card names one, World's landmarks leave them out as kinds, and the AI's planner never seeks one.
  - The minimum counts only standing places: at least 2 cities that haven't fallen, 3 towns and 3 biomes. In late runs it may relax to World's fallback, 1 standing city and 4 towns.
- **The boss's place is fixed by the rule, not offered:** the most populous city still standing. The boss goes where there is most left to lose.
- **The landing dial** (Orb, homework 22: "truly random, with a dial"). World's touch-down is drawn anywhere on the planet at one end of the dial, and always within sight of a place at the other. The run's offers sit at the place end, since a fight needs cities. In versus the dial is a match setup option. **Story mode** (later; it is the co-operative mode, which is held) picks its set pieces dynamically, nearly anywhere.

### 1.3 What persists, and what resets

| Thing | Between stages | Notes |
| :--- | :--- | :--- |
| **A place's buildings** | **Persist.** Each building keeps its state: intact, marked (and how many marks), breached, cracked at the core, or down. Craters keep their place and size, and lava has cooled to rock | World's wear list per place, read back when a later slice crosses it (`planet-slice.md`: a few KB). Craters in open country are kept as points on the sphere |
| **A place's people** | **Persist.** The dead stay dead, by cause. The people who fled a standing place come home before the next stage. The people who fled a fallen place are gone for good | So a revisited city has its start, less its dead |
| **A place's status** | **Persists.** Fresh, damaged (5% or more of its buildings or its people lost) or fallen (under 40% of its buildings standing, or of its people present) | Fallen is for the beats and the offers. A fallen place still stands in the slice as ruins |
| **The sky** | Persists from the boss's first blast cloud to the end (§3) | |
| **The player's form** | **Resets:** every fight starts from base (Orb) | The run's **ceiling** persists: the forms unlocked so far |
| **Boons** | **Persist** for the run (§1.4) | None carries past the run |
| **Lives** | **Persist** (§4.1) | |
| **The hero's two fills** (Witness, Trial) | **Carry at half.** The story leans, and each fight earns its own | Spent at each step, as in `hero-forms.md` |
| **The player's wounds** | **Every region heals one stage:** broken to battered, battered to bruised, bruised to fresh | A rest (a Crossing's reward) heals everything to fresh |
| **The player's ki** | Resets to 60 | As survival's rule |
| **The opponent** | **Arrives fresh,** at base, and can climb to his chapter's tier (one above at a Proving ground, at most 4) | Only the player carries wounds: the run is his attrition |
| **The villain's menace** | Starts each stage at 100 × the run's **Dread** (§5.2) | Within a stage it rises and decays as now |
| **Cosmetic wear on fighters** | Persists as a look: a cracked lens stays cracked | No rule effect |
| **The score and the ledger** | Persist (§4, §2) | |
| **Everything else** | **Resets:** the mood, hit-stop, signature cooldowns, the hero's cost meter, the brawl's state, every in-match timer | |

### 1.4 Boons: what the player takes between fights

After each won fight the player picks **one boon of three** (two in a row after a Proving ground). The offer is drawn from the run's seed, and is the same for the same history.

| Kind | What it gives | Rules |
| :--- | :--- | :--- |
| **A form** | The run's ceiling rises one tier: the next form becomes reachable in every fight from now on | **Every offer holds one while a form is still locked,** so the player can always climb. Turning it down is a choice |
| **An ability** | A run-only power: a plan card from the plan's pool (`upgrade-plan.md` §2: Might, Tempo, Short Fuse and the rest), or a fighter's run boon (a signature variant, a world change, a stronger slingshot) | The plan's limits hold: at most +10% of a stat, and no stacking. At most five |
| **A lifeline** | One more life (§4.1) | At most three lives held |
| **A rest** | Every region healed to fresh | Also a Crossing's reward |
| **A temptation** | A strong gain with a story price: a form at once **and** an ability, or an ability past the plan's limits. **It changes the run's final arc** (§5.1) | Offered once a run, between fights 2 and 3, on a seeded share of runs (a half). Its card says it will be remembered, never what it brings. **On its offer the player may also walk on:** he takes none of the three and gains a life for the restraint (at most three). The beats call that refusing |

- **Choices with weight, never traps:** each card says what it gives in plain words. A temptation is always optional, and its price is a harder ending, never a lost run.
- **The AI's opponents** don't take boons. They climb by the chapter.

## 2. Story beats between stages

**Narrative's grammar is taken** (`docs/narrative/story-beats.md`): two beats a gap at most, one *aftermath* and one *ahead*. The last gap before the boss is the final approach, an eight-step set piece. Beats are lines said by people in the world, skippable, and they never decide an outcome.

**The run's ledger** is what the beats read. It is sim state, written at each stage's end and hashed with the run. The beat picker is a pure function of the ledger and the run seed, in the presentation layer, so a replay shows the same beats. These are the fields and bands that answer Narrative's proposal:

| Field | Values and bands |
| :--- | :--- |
| `stage` | early (stages 1 and 2), mid, late (the stage before the boss) |
| `cities` | Cities fallen in the run: none (0), some (1 or 2), many (3 or more) |
| `city_cause` | Whoever did 60% or more of the run's building damage to cities, by the cause's fighter. Otherwise `both` |
| `casualties` | People killed in the last stage, as a share of the people present on its slice at its start: none (under 1%), some (1 to 10%), many (over 10%) |
| `casualty_cause` | Whoever caused 60% or more of them. Otherwise `both` |
| `branch` | The branch of the hero's last form. Before his first step, the fuller fill if it is 10 or more, otherwise none |
| `branch_event` | entered (this stage's step took a branch he wasn't on), carried (the same as before), faded (he crossed away from it) |
| `menace` | The villain's menace at the stage's end: low (under 30), mid (30 to 69), high (70 or more) |
| `result` | won, won_close (he won from the brink, or with two or more regions broken), lost_close (the opponent was on the brink, or had two broken), lost |
| `comeback` | brink (a win from the brink), after_loss (the first win after a loss), streak (three wins since the last loss) |
| `boss_in` | Stages until the boss: 3, 2, 1, 0 |
| `boss` | The run's boss (§5.1) |
| `avoided_towns` | The hero spent under 20% of the stage within 1,500 units of a building, and killed under 1% of the people present |
| `rival_here` | The rival appears in this gap if he was the last stage's opponent, or every second gap otherwise (Narrative's question 3 to Orb can change it) |

**Added for the run** (new fields, which Narrative may write for):
- `revisit`: the next stage crosses a place the run has damaged, with its name and its state;
- `fallen_name`: the place that fell in the last stage;
- `wound_carried`: the hero goes in with a region broken;
- `sky`: the sky has darkened (boss only);
- **Narrative's fields for the reshaped run** (confirmed 2026-10-17, `docs/narrative/story-beats.md` §12; `lives` supersedes `chances`):
  - `fight`: 1 to 5, and `boss_in` as before;
  - `lives`: the retries left, as many (3), two (2), one (1) or last (0, when the next loss ends the run). `life_event`: spent or gained;
  - `buff`: offered, enticing_taken (the temptation), modest_taken (another boon from that offer) or refused (he walked on, §1.4). `buff_age`: fresh in the fight just after it, carried in later ones;
  - `boss_path`: default (the court), rival_escape (the rival's debt), empress_down (the hidden hand) or mvp (§5.1). **One a run:** the paths are alternatives, never both;
  - `motive`, the reason the rival gives when he steps in. It is pride if the hero has beaten him in three or more fights; appetite if he ended most of his fights with his menace at 70 or more; otherwise silent.

**What Narrative supplies:**
- the beats for the added fields;
- a name grammar for the planet's places (12 cities, about 31 towns, landmarks), generated from each place's seed, original and Legal-screened;
- each offer card's one line, by kind and the place's state;
- the boss's lines by boss;
- the ending: one beat each for the planet's state (§4.3) and the hero's branch history.

**What the ledger keeps:**
- for each place: its dead, by cause (player, opponent, other), its people who fled, its buildings lost by cause, its status, and the stage that changed it;
- for each stage: the offer kind, the opponent, the result, how it ended, the finisher;
- for the player: the forms taken and their branches, the wounds carried, the boons;
- for the run: Dread, lives spent, the boss path, and the planet's share of its people lost.

**How the toll is shown** (Legal c08): as a count and as the planet's state, never as bodies or close-ups and never as points, with no celebratory sound or show when it rises. No child is shown as a victim of graphic violence.

## 3. Escalation, and the boss's catastrophe tier

**Across the run:**
- **The tiers the fighters can reach** rise by chapter for the opponent and by boons for the player (§1.1, §1.4). So the collateral budget rises with them, by tier (`balance-targets.md` §4b: 2, 4, 8 and 15% of the people a minute, and ceilings of 10, 30, 60 and 90%). Early fights dent a city, and late ones can level one.
- **The AI's level** rises by chapter. Story: easy, easy, medium, and the boss at medium. Standard: medium, medium, hard, and the boss at hard. A Proving ground is one level up.
- **The villain's starting menace** rises with Dread.
- **The planet's state** worsens, and later slices cross what earlier ones broke.

### 3.1 The catastrophe tier (tier 5, boss only)

- **It exists only in the boss fight.** Everywhere else the ladder ends at 4.
- **The boss fight has two phases.**
  - **Phase 1** is fought on the ladder, from base. The player climbs to his ceiling, and the boss starts where its arc puts it (§5.1). Power fills half again as fast in a boss fight, so the climb fits inside it.
  - **The tremor.** When the boss's first region breaks, or after 150 s of fight time if that comes first, the ground answers: a quake runs through the slice, with dust, heaving ground and swaying towers (a live set piece, no pause). It is never glowing fissures across the planet, and never a ring leaving it (Legal c06). Both fighters' tier-5 form becomes ready, taken by holding Transform. The boss takes his at once.
  - **Phase 2** is fought at tier 5.
- **Tier 5 in numbers.**
  - The ladder's per-tier gains carry on: speed +0.1, damage +0.09 and launch force +0.16 a tier.
  - Structure reach is 2.4.
  - The collateral budget is 25% of the people present a minute, with a ceiling of 95%. Set pieces may borrow.
  - The planet's own ceiling holds above all of these (§6).
- **The tier-5 form** wears the branch of the hero's top form. For a first version it is the top form with a planet-scale aura, which is VFX's.

### 3.2 The three catastrophe moves

Each needs tier 5. Each is credited to the fighter who started it, so the people it kills cost the hero (his own kills, `hero-forms.md` §7) and feed the villain.

| | **The crust breach** | **The blast cloud** | **The exosphere** |
| :--- | :--- | :--- | :--- |
| **Earned by** | A tier-5 signature beam fired with the stick down, at the ground | A tier-5 detonation: a beam struggle that ends in a detonation, a tier-5 overwhelm's landing, or a tier-5 blast at full charge into the ground | A tier-5 power send (`buildings.md` §6.1) with the stick straight up. The sender follows, and the fight goes up |
| **What it does: sim** | The beam is swept along a cut and bores down to the crust's floor, **and no further: it never pierces the planet or leaves its far side** (Legal c06). The columns it sweeps sink, and magma rises in them toward a head below the old surface, flows along the cut and cools into rock (Research's model, `docs/research/world-catastrophe.md` §1). Magma's effect on fighters and people is §10.1. Towers in its sweep crack at the core and fall, with `buildings.md` §6.2's warning. The rock persists for the run | A blast of 3,000 units: both fighters inside take a quarter of the stronger of the two beams or blasts, the detonator too. A tier-5 crater forms, and every tower inside it cracks at the core and falls, with the warning. The world's `ash` goes up by 0.6 (at most 1) **over at least 120 s, under the sky's slew limit** (Legal c05), and stays to the run's end. **Ash has no other rule effect, by design:** it never hides a tell, a cue or the HUD | Above a set height, gravity is off and the brawl goes on in free flight. **The new rule: every energy shot that misses falls to the surface.** It lands about 90 ticks later on the column below its line, as a tier-5 impact: a crater, buildings and people, on the firer's account. **Impacts are spaced** (Legal c04): within any 6,000 units of ground, at most one lands in 30 ticks, and a shot due sooner merges into the next impact there, which grows. The fight comes down when a power send is aimed down (the meteor: the sent fighter lands as the largest impact in the game, and the sender's stick aims where), or after 60 s |
| **What it costs** | The signature's ki and its cooldown, and a 30-tick wind-up open to a charge interrupt. Magma hurts both. **A defender in the beam's line can interpose** (DEFENSIVE near people, `economy.md` §4.3): he takes it at guard strength, and the breach doesn't happen. At most 2 a fight | The detonator is hurt too, and the people inside are on his account. The first raises the sky to half dark, a second to full. At most 2 a fight, 30 s apart | A tier-5 launch (an opening and its 5 ki). Every miss is paid for by the planet, so the hero must aim, and the villain needn't. **In the exosphere there is no ground:** no breach, and a detonation there harms nobody below. Once a fight, at most 60 s |
| **What it means in play** | **Area denial and a threat.** The villain bores toward a city to flood it. The hero stands in the line to take it, or bores open ground to wall the villain off from the town | **The fight's loudest moment,** and the sky stays dark to say so. The ending reads it | **The hero's gamble.** Taking the fight up saves the planet from the breach and the blast, but in the sky every one of the villain's shots is a bombardment. The hero brings it down with the meteor, aimed at empty ground |
| **Spectacle (Rendering, VFX, Camera, Audio)** | The cut's lit notch from the side, heat on its walls, steam, slow crust plates on the magma | The fireball rising into a stem and a cap, the ground's shockwave, the planet's light dimming over minutes, ash falling | The planet's curve and its night line, the glow of a shot falling, a small flash far below a moment later, and Orb's live picture-in-picture of a city hit. The sound is muffled up there |
| **Light and flash (Legal c01 to c05)** | **Magma (c03):** amber-orange, slowly changing, never a saturated red (red share under 0.8, as Research built it). Its bubbling is a low-contrast change (under a 10% step), at 2 Hz or slower, irregular and unsynchronised, and never a regular pattern of spots or stripes over a large area. The beam's light and the breach's glow are catastrophe light events | **The blast's light is one catastrophe light event.** The darkening is minutes long, under the sky's slew limit, and the fighters keep their lane-colour contrast in the darkest sky (c05) | **The bombardment (c04):** each impact small on the screen, or at most two a second within any one screen window (the picture-in-picture is a window), never in step with each other. The fighters' glow up there is a steady edge |
| **The echoes to avoid (Legal c06)** | No single beam through the planet, and nothing leaves its far side. No glowing fissures spreading across the planet | No perfect hemisphere of light swallowing a city. No ring-shaped shockwave leaving the planet. **It is our own blast cloud (c07):** no radiation sign, none of the words nuclear, atomic, A-bomb or H-bomb, no real city, date or event, and no siren or countdown that evokes a real alert. In copy it is "a blast cloud" | No planet cracking into a fireball, and no ring shockwave off the planet's edge seen from above. **The boss never charges a sphere above his head** with raised arms (our own rule too). Every catastrophe move is a fighter's own beam, blast or launch at world scale, never another fighter's named attack |

- **For each of the three** (Legal c01 and c02): its own worst-case clips in both modes, in the required flash set, on the commit that carries it (c01). **At most one catastrophe light event every 2 s, counted across everything on the screen** (the registry), **rising over at least 0.3 s and falling over at least 1 s,** with a calm form under Reduce flashing: a lower peak, a slower rise, no repeats (c02). **The boss fight is measured in the darkened sky,** where the same glow is a larger step. Red flashes 0
- **What is sim and what is spectacle.** The "sim" row is all the rules there are: terrain, magma, hazard wear, the blast, collapses, people, ash as a number, the exosphere's height band, its falling shots and their spacing. Everything else only reads the sim, and none of it may hide a tell.
- **Legal's screen is RL-145** (`docs/legal/catastrophe-and-city-screen.md`, c01 to c09). Legal sees storyboards of the effects at their worst frame, the calm forms, the boss's ability names and silhouettes against c06, and the casualty presentation, before any of it ships.

## 4. Failure, replay, scoring and variety

### 4.1 Losing a fight: retries and lives

- **A lost fight spends a life and is retried from its start:** the same slice, the same seed and the run state it began with. The planet is as it was when that fight began.
- **With no life left, a loss ends the run.** The haul is still paid (§4.4).
- **Lives** (Orb: "a mechanic that gives you extra lives"):
  - the start: two on Story, one on Standard, none on Hard;
  - **a clean win** (no region broken at the end) earns one;
  - a lifeline boon gives one;
  - at most three are held.
- **The boss** is retried like any fight.
- **An assist, "Endless retries,"** is a setting at the run's start. The score is then marked assisted, and isn't ranked.
- **The beats** read a retry (`lives`) and a run that ended (`result`: lost).

### 4.2 Scoring

| Part | Points |
| :--- | ---: |
| Each stage won | 1,000 |
| The boss | 3,000 |
| A hero's run: each 1% of the planet's people alive at the end | 20 |
| A villain's run: each place taken (a stage he won there) | 500 |
| Each life spent | −300 |
| Style: each chain through two or more buildings, each duel of perfects won, the boss's finisher | 100 each, at most 1,000 |

Fight time breaks ties: less is better, counted in ticks, never the wall clock.

**No part of any score counts deaths** (Legal c08). The hero's term counts the people alive, and the villain's the places he took. No achievement, trophy, unlock or challenge counts deaths either.

### 4.3 Variety from the seed

- **One run seed gives the planet**: its land, its biomes and ice caps, its 12 cities, about 31 towns and its landmarks. It also gives the offer stream, each stage's seed and the opponents.
- **The player's choices give the route.** The same seed and the same choices give the same offers, so a seed can be shared and a run raced.
- **The ending** reads the planet: most of its people alive, half lost, or most lost. It also reads the sky and the hero's branch history (all Witness, all Trial, or crossing).

### 4.4 Between runs: looks, titles, styles and challenges

Orb: "find an approachable, fun, exhilarating game loop for this type of episodic brawler. Ideally I'd like to be able to give players tons of customization options, so lets find out what kinds of rewards we can shower them with for playing." **Nothing that makes a fighter stronger carries past a run.** It is the same balance as versus, and `unlocks.md`'s rules hold: earned through play only, no purchases, no random rolls, nothing missable, and nothing earned by a death (Legal c08).

**The loop: something after every fight, and a haul at the end.**

| When | What the player gets |
| :--- | :--- |
| **After every fight won** | Mastery points for his fighter (`unlocks.md` §3), half again a match's, and **a keepsake:** a small trophy of what just happened (a brick from the tower he went through, the rival's cracked lens, a scorched banner). Keepsakes are shown in the haul and on a shelf in the menu |
| **At the run's end, win or lose** | **The haul:** mastery points by fights won and styles shown, every feat met, the run's keepsakes. A won run adds a pick of three items from his fighter's pool |
| **The first clear of each final arc** (§5.1) | A showpiece: an outfit set, a victory scene or a finisher style |
| **Styles in a run** | Every kind of launch used, a chain through three towers, an inside chain, a slingshot from a full coil, a duel of perfects won, a run with no life spent, a city defended to the end. Each one gives an item, and ten of them give a title |
| **Challenge tiers** | Pressure 1 to 10 (below). Each tier cleared gives a border and an aura tint step; tier 10 gives a showpiece |
| **The atlas** | A stamp for every place defended, every planet played, every arc seen. Protecting goals are fine; none counts the dead |
| **The seed of the day** | A run on a shared seed, from the date, offline. A small item for each week played. Leaderboards come with online play, later |

**The kinds of reward,** with Art's pool of about 122 items a fighter and 38 shared (`unlocks.md` §3), plus these run kinds:
- **titles,** about 40, shown on the fighter-select card and in the beats' cut-ins (Narrative words them);
- **finisher styles:** for each finisher, three variants of its camera, colour and closing pose. A style never changes a finisher's rules;
- **intro variants** for the dynamic introductions Orb asked for;
- **keepsakes;**
- **HUD frames** and **victory scenes.**

**Pacing.** A first run of about 30 minutes gives at least five things the player can see. A full run gives eight to ten. Early on, a mastery level comes every one or two fights.

**Challenge tiers** (Pressure 1 to 10). Each adds one burden, and they stack:
1. the AI one level harder;
2. one life fewer;
3. the villain starting with Dread 0.3;
4. no rests offered;
5. offers of two boons, not three;
6. opponents reach one tier higher;
7. no temptation;
8. clean wins earn no life;
9. the boss arriving at tier 5;
10. all nine together.

**What never counts:** deaths, purchases, random rolls, and anything missable.

### 4.5 Endless (the old `survival`)

Fights until a run would end, with no boss: the opponent reaching tier 4 from fight 3, and boons as in a run. It ends when the planet runs out of standing cities (§6). The score is stages won and people saved.

## 5. The branches, menace and the cast across a run

### 5.1 The cast, and the final arcs

- **The player's fighter:** any fighter. The MVP is the Protagonist.
- **The rival:** the recurring opponent, and the fights' usual face.
- **The boss varies with the run's story** (Orb: "there should be different story beats allowing for different final bosses"). which **final arc** plays is decided by the run's state, deterministically, and the ledger keeps it as `boss_path`:

| Arc | When it plays | Fight 5 | The boss |
| :--- | :--- | :--- | :--- |
| **The hidden hand** (`empress_down`) | A temptation was taken between fights 2 and 3 | The Empress, with her guards. She falls | **The Demon Cyborg appears,** one transformation short of his final form. The tremor gives it to him |
| **The rival's debt** (`rival_escape`) | No temptation, and the player has beaten the rival in two or more fights | The boss. At its brink, **the rival steps between them and lets it get away,** a set piece. The fight goes on against the rival, from where it stood | The boss, recovered, in the city it fled to |
| **The court** (`default`) | Otherwise | The rival, or one of the boss's own | The Empress at the catastrophe tier |
| **The MVP** (`mvp`) | While only the two fighters exist | The rival | **The rival at his worst** |

- **The escaped boss returns** in the final fight, recovered, in the most populous standing city other than fight 5's. The rival stands aside, and Narrative's three "returns" beats play in the final approach.
- **The arcs are content to come,** since the Empress and the Cyborg aren't built. Narrative writes each arc's beats and the final approach's variants. New arcs are data.
- **The rival beside the hero at the boss** (Narrative's final approach) stays a later option, as an AI partner under the one-v-many rules. It is not co-op: co-op stays held.
- **A villain's run:** the player plays the villain, and the boss is the planet's last defender. It is designed here and comes after hero runs.

### 5.2 A run that keeps pressing the hero

- **His fills carry, at half.** The run's offers let him steer. A Rampage fills Witness and a Proving ground fills Trial, and the map says which is which. The route he takes is his branch.
- **His own kills keep costing him,** as now (`hero-forms.md` §7). The ledger keeps them, and the beats grow heavier with them (`casualty_cause`: hero). They never power him.
- **Dread** is the share of the planet's people the villains have killed in the run, divided by 0.4, at most 1.
  - It sets the villain's starting menace each stage (100 × Dread).
  - It sets the boss's tier-5 damage: up to +10% at a Dread of 1.
  - **It is a power meter, never a score** (Legal c08). If the HUD shows it at all, it shows the boss's strength.
  - **So a hero who defends early meets a weaker boss,** and a run that let a city burn pays at the end. That is pillar 5 across a whole run.
- **A Rampage is a choice with weight.** It shows the villain feeding, and fills Witness, but people die before the hero lands, and Dread rises with them.

### 5.3 Good against good

- **A stage against another hero** (a mirror, or a hero fighter later) is a trial. Escalation needs no deaths there: the ladder carries it, and the first to step up fills the other's Trial (`hero-forms.md` §5). Such an opponent makes no Rampage offers.
- **A run's boss is always a threat to the planet:** a villain, or in a villain's run the planet's defender. The catastrophe tier is what the boss threatens.

## 6. The planet's capacity

World's numbers (`planet-slice.md`):
- 12 cities and about 31 towns;
- an arena of 153,600 units;
- an accepted slice holds about 2.9 cities, 3.5 towns and 4 biomes;
- a city spans 13,000 units (its radius is 6,500), about 8.5% of the arena's length.

My estimates for a run, for World and QA to measure:

| | Cities that fall | Damaged, still standing |
| :--- | ---: | :--- |
| A stage at tier 2 at most | about 0 | 1 city, 1 or 2 towns |
| ... at tier 3 at most | about 0.5 | 1 or 2 cities |
| ... at tier 4 | about 1 | 1 or 2 cities |
| The boss, at tier 5 | 1 or 2 | the rest of its slice |
| **The MVP run** | **about 3 of 12** | most of what its four slices crossed |
| **The full run** | **about 5 of 12** | |

- **How long the planet lasts.**
  - Any two standing cities lie on one great circle, so a slice through two standing cities exists as long as two stand.
  - Three different offers need about four standing cities, which give six pairs.
  - **So a planet can take about 8 fallen cities before the offers run dry.** A full run stays inside that. Endless mode ends when fewer than four cities stand.
- **Towns** fall more easily, at about one a stage, about 6 of 31 in a full run.
- **People.**
  - The planet's people are the sum of its places, normalised as World does, so a slice at full has the 1,800 of today's arena. A slice through ruins has fewer, and the meters read what is really there: a villain can't feed in ruins.
  - **The planet's own ceiling: before the boss, at most 40% of the planet's people can die. By the end, at most 70%.** Past it, the rest shelter, as in a match. So there is always something to save at the boss, and a dead planet takes the catastrophe tier.
- **World's measures, asked:** slices meeting the minimum with 0 to 10 cities fallen; how many cities and towns a stage really damages and fells at each tier ceiling; whether three distinct offers can be found in under 1 s with eight cities fallen.

## 7. Determinism

- **One run seed (64 bits).** The planet seed, the offer stream and every stage's seed come from it:
  - stage seed = H(run seed, chapter, the chosen offer's index);
  - the offers for a chapter = f(run seed, chapter, run state). They depend on what has fallen, and are still the same for the same history.
- **The run state** is what passes from stage to stage:
  - each place's wear list, its people and its status;
  - the ledger;
  - the player's carry: the ceiling and the boons, the fills (at half), branch history, wear by region, lives;
  - Dread, the arc and the score parts.

  It is a pure function of the state before and the stage's end. It is hashed, and it is a few KB.
- **A stage replays on its own:** its header holds the stage seed, the slice (T and bearing), the run state's hash and the run state itself, plus the input log. Bit-identical, like any match (ADR 0004).
- **A retry** starts again from the fight's own header: the same seed and the same run state in.
- **A run replays** as its seed, the choices and each stage's inputs, in order. Each stage's end state is checked against the next one's header.
- **The beats and the offer cards' lines** are drawn in the presentation layer from the ledger and the run seed (Narrative's rule 6). The sim never reads them.
- **No wall clock** anywhere: time is ticks. Float64 and our own trig, as World's planet function already is.
- **QA's golden:** a scripted MVP run on a fixed seed with recorded inputs, whose final ledger hash is pinned.

## 8. The MVP, and what to build first

**The MVP cut:**
- the Protagonist against the rival;
- three stages and the boss, with three offers a chapter, shown as cards with World's strip diagram rather than a globe;
- every fight from base; boons (forms, a few plan cards, a lifeline, rests); lives and retries;
- the wear list, the ledger and Narrative's beats;
- tier 5 with the tremor;
- **the crust breach and the blast cloud;**
- the score.

**Not in the MVP:** the exosphere, temptations and the other arcs, the globe map, villain runs, the rival as a partner, challenge tiers past 3, endless.

**The order:**

| # | What | Who |
| ---: | :--- | :--- |
| 1 | The planet, the slices and the touch-down: World's windows 1 to 4 (`planet-slice.md`) | World |
| 2 | **A city stays damaged:** the wear list per place, written at a stage's end and read back into a later slice. This is the run's heart, and it is testable alone: two scripted matches on crossing slices | World |
| 3 | The run state, its hash, the carry (the ceiling, boons, fills at half, wounds, lives), fight seeds, the run log, retries and the replay | Simulation, Tools |
| 4 | The offers and the run screens: cards, the stage, the beats, the results | UI, with Narrative |
| 5 | The ledger's fields, wired to Narrative's beats, and the new ones | Simulation, Narrative |
| 6 | Tier 5, the tremor and the crust breach, with the catastrophe allowance and its blast flag (§10.1). Research's smallest first build starts it: the breach and its magma model in one boss scene | Simulation, World, Encounter, VFX |
| 7 | The blast cloud's rules, and the sky (`ash`) | Simulation, Rendering, VFX |
| 8 | Boons, lives and retries, the score and the haul | Simulation, UI |
| After | The exosphere (a height band, falling shots, a camera that can hold the planet); temptations and the arcs; the globe map; the full run; villain runs | Many |

**The MVP's QA rows:**

| Row | Bound |
| :--- | :--- |
| A building marked, breached or downed in a stage is in the same state when a later slice crosses it | Every time (hard) |
| A stage replays bit-identical from its header alone | Every time (hard) |
| A retry starts from the same run state as the fight it retries | Every time (hard) |
| Every boon offer holds a form while one is still locked | Every time (hard) |
| The run state at a stage's start is the one the last stage ended with | Every time (hard) |
| No offer touches down in a fallen place, and no stage starts with a fighter in a crater or under water | Never (hard) |
| Each stage's length | 10th percentile 300 s or more, median 5 to 7 min |
| The MVP run's length | Median 25 to 35 min |
| A first-time player finishes the MVP on Story | Within three runs |
| Cities fallen in an MVP run | 2 to 4 of 12 |
| The boss fight reaches the tremor | In at least 90% of boss fights |
| A crust breach or a blast cloud in a boss fight | In at least 60% of the boss fights that reach tier 5 |
| The planet's ceiling: people lost before the boss, and by the end | At most 40%; at most 70% (hard) |
| Each catastrophe effect's worst-case clips, both modes, in the darkened sky | Pass the flash check, with red flashes 0 (hard, Legal c01 to c03) |
| Catastrophe light events, across everything on the screen | At most one every 2 s, rising over 0.3 s or more and falling over 1 s or more (hard, c02) |
| A score, achievement, unlock or challenge that counts a death | None (hard, c08) |

## 9. Orb's answers (homework 26), and what is asked next

- **Losing:** a retry of the same fight, or the run ends, with extra lives (§4.1).
- **Power between fights:** every fight starts from base, and boons make the higher forms reachable (§1.1, §1.4).
- **Length:** five fights and a boss.
- **The boss:** different final arcs by the run's story (§5.1).
- **Between runs:** looks and harder challenges, and a reward economy to shower players with (§4.4).

The next questions are in `homework/30-run-and-launch.md`.

## 10. Answers to Research, Simulation and Narrative (2026-10-16)

### 10.1 Research: what magma does, and where the catastrophe unlocks

**Magma is in the sim,** as Research recommends: fighters meet it, and its rock persists across the run.

| | To a fighter | To people and buildings |
| :--- | :--- | :--- |
| **In it** | Lava's wear, as ruled (`living-destruction-numbers.md` §6): legs 4, core 2 and arms 1 a second while he stands or wades in it | It flows slowly (Research's model), so people ahead of it flee: it evacuates first. Deaths come only inside the catastrophe allowance (below), on the account of whoever breached |
| **Landing in it** | Core 15, once, and he is **thrown clear** to the nearer rim of the cut. It never holds him, since control comes first | Buildings it reaches catch fire under the fire rules. A tower it reaches that is cracked at the core falls, with the warning |
| **Above it** | Heat: half those rates while he flies lower than 3 fighter heights over its surface | |
| **Its limits** | **It never finishes anyone.** A fighter on the brink in magma is thrown clear, and only a finisher ends a fight. In the boss fight, hazard wear (magma, fire, falling stacks) is at most 25% of all wear, where a match's band is 15% | The toll is shown as a count and as the environment, never as bodies (Legal c08) |
| **Afterwards** | | It cools into rock, which raises the ground and stays for the run |

**Where the catastrophe set piece unlocks.** It is the allowance in `WorldCollateral.EVENT_ALLOW`, plus a blast flag that lets a catastrophe finish buildings past `leaveFrac`.
- **In a run:** only in the boss fight, at tier 5, after the tremor (§3.1).
- **In story mode:** only in an encounter whose data allows it (Orb's ruling of 2026-10-11): a chapter's boss encounter (`encounter.catastrophe: true`), and there too only at tier 5.
- **In versus: off.** Versus has no tier 5, and its collateral bands stay as tuned. Whether versus gets a catastrophe switch is Orb's call, later.
- **The allowance:**
  - Each catastrophe event (a breach, a blast cloud, a meteor's landing) may borrow up to 20% of the people present at once. The window then refills before another can overdraw it.
  - The tier-5 window is 25% a minute and its ceiling 95% (§3.1). The planet's ceiling caps everything (§6).
  - At most 3 catastrophe events a fight: 2 breaches, 2 blast clouds and 1 meteor, at most 3 in all.
  - **The fifth entries for `data/fight/tier5.json`** (World's `collateral-run.md` §5), as shares of the people present:
    - the budget, 0.25 a rolling 60 s, and the ceiling, 0.95;
    - the set pieces' allowances at tier 5: slide 0.15, chain 0.25, landslide 0.15, quake 0.15, and **catastrophe 0.20**.
    - Tiers 1 to 4 keep the catastrophe at 0.
- **The blast flag is tier 5 only.** `buildings.md` §6.1's tier-4 crater brings towers down by cracking their cores, which is the falling stack, not the blast flag. So versus at tier 4 is unchanged.
- **The big digs** are spread over a few ticks, as Research asks. The camera never flies past a mass collapse (Research §4).

### 10.2 Simulation: people, carry and the planet's marks

- **Damaged places have fewer people.**
  - A stage's `pop0` is its slice's people at the run's start, normalised as World does, so a fresh slice has 1,800.
  - **The people present at a stage's start** are `pop0`, less the dead, less the people who fled a fallen place for good.
  - The collateral budget and the ceilings (`balance-targets.md` §4b) are shares of the people present at the stage's start.
  - The meters' gains per person stay normalised by 425 / `pop0`, the run-start figure. So a person counts the same everywhere in the run, and a villain feeds less in ruins because fewer people are there.
  - **For World's question** (`docs/world/collateral-run.md` §3), ruled 2026-10-17: the meters are by `pop0`. By `present`, a death in a half-ruined slice would count double, and a villain would feed as well on ruins as on a whole city, which is the opposite of the rule. The budgets and ceilings are by `present`; the meters' gains per person are by `pop0`.
- **What carries between stages** (§1.3):
  - the ceiling (the forms unlocked), with every fight starting from base;
  - Witness and Trial, at half;
  - the wear, every region healed one stage;
  - the boons and the lives;
  - the villain's feeding meter, which starts each stage at 100 × Dread (menace now, and Pride by the same rule when it lands).

  Reset: ki to 60, the hero's cost meter, the mood, the cooldowns and the timers.
- **The planet's own marks:**
  - each place's wear list (buildings, craters, magma rock);
  - craters in open country as points on the sphere;
  - the world's `ash` (one number, raised only by a blast cloud, so only in the boss fight);
  - the run's Dread and ledger.

  All of it is run state, hashed and carried in each stage's header (§7).

### 10.3 Narrative: the beats' fields, and a loss

- **The fields are aligned in §2:** Narrative's fourteen with their bands, and four more: `revisit`, `fallen_name`, `wound_carried` and `sky`.
- **`boss` gains `rival`,** since the MVP's boss is the rival at his worst.
- **A loss is retried while a life is left** (§4.1, re-ruled by Orb's homework 26). So `lost_close` leads into the retry beat, as Narrative first wrote it, and a loss with no life left ends the run and plays the end-of-run beat.
- **Legal's c07 and c08 apply to the beats:** no siren or countdown that evokes a real alert in the final approach, no real city, date or event, and no line that cheers a death.

### 10.4 Simulation's three, from `docs/architecture/run-core.md` §9

- **A Rampage's 15 s head start is played,** as part of the match and its replay. The opponent lands at tick 0 and the player's fighter arrives from the sky above the slice. **The player steers his descent from tick 0:** where along the slice he comes down, and how fast. A dive lands him as soon as 6 s; otherwise he lands at 15 s. A fast landing is an impact like a ground power-up, and its people are on his account. Witness counts what the opponent does within 3,000 units of him while he comes down. Laid-on wear would give the player nothing to see and Witness nothing to count. The head start's casualties stay inside the stage's budget at its floor tier.
- **The roundings to thousandths are accepted,** at the hand-over only and never inside a stage, by one rule everywhere: to the nearest, half away from zero. Fills run to 100, so a thousandth is far below anything a band reads. Dread's thousandth moves the boss's damage by a hundredth of a percent.
- **A fight that ends before its step:** nothing steps between fights any more, since every fight starts from base (Orb's homework 26). The run's ceiling rises only by a form boon.
- **One correction for the core:** since Legal's c05 the ash rises over at least 120 s (§3.2), not 20 s.
