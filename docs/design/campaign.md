# The campaign: main-story and filler episodes and arcs, toured as planet runs, played solo or together

Owner: Game Design. Status: **the design, 2026-10-25,** revised the same day so that filler is one kind of episode and arc, not the frame for the whole campaign (§1). Paper only. Every number is a first value. It builds on what exists rather than replacing it: the run (`run-mode.md`), the run state (`docs/architecture/run-core.md`), Narrative's beat templates (`homework/done/co-op-campaign-pick/story-beat-samples.md`, data in `docs/narrative/pending/beat_templates.json`), World's rings and homes, and the one-versus-many rules (`empress-guards.md`, `grapple.md`).

**Orb's picks** (homework 41, `docs/ep/vision.md`, 2026-10-25):
- **The shape:** "The Macro Structure (Episodic Arc): Campaigns are framed as a self-contained 'Filler / Post-Season Arc' within the anime's ongoing broadcast. The Micro Structure (Planet Run Ring): Inside each Episode, players navigate a 5-stage planet tour using branching route maps." The Siege (C) is held for a later mode.
- **Filler is a kind, not the frame** (Orb, 2026-10-25): "just to clarify, filler episodes, filler arcs could be considered separate categories in the game, but not all missions will be filler episodes."
- **Co-op:** "Drop-in co-op works anywhere (character select, route maps, beat cards, or mid-brawl). No menu separation—players load onto the same planet ring and can physically sprint in opposite directions or converge in real time."
- **Length:** "as far as we can push procedurally generated dynamic storylines that remain interesting."
- **A lost run:** "think of whether its fun, cool, balanced to trigger a flat restart. determine and engineer some novel mechanic that encourages the player to start over if they lose rather than ending the run in frustration."

**Standing rules it keeps:** solo or co-op with an optional CPU partner; free roaming, with any enemy engageable and a second player joining an engaged fight without a break (Orb, 2026-10-11); no friendly fire; graded henchmen; a boss per planet; generated beats never add lore, because Orb writes the universe; Legal c08 and ln05 (no reward for deaths, and the beats read places and wear, never a toll); and Orb's minimal HUD.

## 1. The shape

**The campaign has two kinds of story: the main story, which Orb writes, and filler, which the game generates.** Each comes as single episodes and as arcs. An **episode** is one sitting: **a five-stage tour of a planet on a branching route,** with the anime's dramatic shape (a cold open, the rise, a twist, the climax and a cliffhanger) and the run's machinery (fights from the base form, boons, lives). An **arc** is three episodes on one planet. **The route is the planet itself:** the next stages are places on the ring the players are already flying, and they choose by flying there, together or apart. A lost episode isn't erased: it airs, and the next episode answers it (§5).

### 1.1 The four kinds

| | **Filler episode** | **Filler arc** | **Main-story episode** | **Main-story arc** |
| :--- | :--- | :--- | :--- | :--- |
| **What it is** | A one-shot: one episode that stands alone, a side story | Three generated episodes on one procedural planet, with the arc's own villain, threads and boss: a self-contained post-season arc | One chapter of the main story | A chapter run of the main story: its episodes in Orb's order, ending in its finale |
| **Who writes it** | Generated from Narrative's templates, filling slots and never adding lore | Generated, the same way | **Orb writes its spine and its key beats:** who, where, what happens and how it ends. The game generates the rest around them (the route's other places, hordes, branches, the in-between beats) | Orb's, in the season's order |
| **Its planet** | Any seed. Inside a main arc, a copy of that arc's planet (§1.2) | One new procedural planet a seed | **Orb's seeded planets,** with the places and homes Orb names | The same |
| **Its spine** | The five columns (§2.2), every one generated | The same, with the arc's finale replacing the last climax | **The five columns with some fixed:** at least the climax's opponent and place, and any stage Orb pins. The rest are generated | Orb's episodes in order, and Orb's finale |
| **What it changes** | Nothing beyond itself. It keeps its rewards (keepsakes, items, mastery) | Its own planet and threads, for the arc's length. Nothing in the main story | **It moves the main story:** a win opens the next main-story episode, and the planet's wounds carry into it | The season's story |
| **Replaying it** | Without end, on new seeds | Without end, on new seeds | Replayable: Orb's fixed beats repeat, and the generated parts vary | The same |
| **Its tone** | Free to be lighter: Narrative's filler families (a training day, a rivalry game, a tournament on a stage, a rescue), still in each fighter's voice | Narrative's arc shapes (a hunt, a betrayal, a defence) | Orb's voice and Orb's stakes | Orb's |
| **A loss** | The rescue (§5.1) applies. A lost one-shot simply ends, with its haul paid, and a new seed is one press away: a cheap start is what a one-shot is for | §5: the rescue, and "Previously on" between its episodes | §5. "Previously on" carries the loss into the next attempt at the same chapter | The same |

- **"Fighters never change" holds in every kind** (Legal mc01, §4). A main-story event that Orb writes can change a fighter, such as a form gained in the story or a side switched. That is Orb's script and the same for every player, and it never reads a player's own history. Legal confirmed this under **mc06** (`docs/legal/campaign-screen.md`, addendum): a main-story change triggers only by story position or an explicit authored choice, never by how a fighter fared against the player, and its numbers are authored per branch.
- **Generated content never adds lore in any kind.** A filler arc's villain is a roster fighter, never a new character, and its places come from the planet's names, which persist.

### 1.2 How they mix

- **A filler episode inside a main arc: yes.** It is the anime's breather between chapters, offered between two main-story episodes. It plays on a copy of the arc's planet as it stands, wounds and all. Its beats may read the arc's open threads as colour, **but it never resolves a main-story thread, and nothing it does carries back.** When the main story resumes, the planet is as the main story left it. That is filler's rule in the anime, and it keeps Orb's chapters exactly as written.
- **A standalone filler arc: yes.** It is the campaign's endless content, open from the start and played at any time.
- **A standalone filler episode: yes.** The quickest way in: one sitting, no commitment.
- **Main-story content inside filler: no.** Filler can't open, close or skip a main-story chapter.
- **Filler arcs between main arcs** are the season's post-season arcs, as homework 41 pictured: generated, and set anywhere in the season's run.

### 1.3 How a player picks them, or meets them

- **From the start screen,** three doors: **the main story** (its chapters open in order, and the next one is always marked), **a filler arc** (new or continued), and **a filler episode** (one sitting, on a new seed or the planet of an arc he has played).
- **In the world, between main-story episodes:** when a main-story episode ends, the ring sometimes shows one more place, **a side story** with its own beacon. Flying to it starts a filler episode there and then. Ignoring it, the cliffhanger's "next time" leads on. **Nothing is ever picked from a list in the middle of play.**
- **The title card says which it is.** A main-story episode carries the season's episode number. **A filler episode carries a half number, such as "Episode 12.5",** as the anime would number one. A filler arc's cards carry its own short title. Each is one line, at the edge, and never on the fighters.
- **Co-op joins any kind the same way** (§3). A partner who joins a main-story episode advances his own main story only if he has reached that chapter. Otherwise he plays it as a guest, keeping his rewards but not the chapter.

## 2. The structure

### 2.1 The three levels

| Level | What it is | How long | What it keeps |
| :--- | :--- | :--- | :--- |
| **The stage** | One fight or challenge on one place of the ring: a horde, a duel, a defence, a pursuit, a two-on-one, the boss | 3 to 7 minutes. Duels and the boss keep Orb's floor of five minutes or more | The match's own state |
| **The episode** | Five stages on a branching route, with beats between them. **It is a run, in `run-mode.md`'s terms:** fights from base, boons, the ceiling, lives | One sitting, about 40 to 50 minutes | Boons, the ceiling and lives last the episode, as a run's do |
| **The arc** | Three episodes on one planet: the pilot, the middle and the finale, then the arc's boss. A filler arc's are all generated; a main-story arc's are Orb's chapters (§1.1) | Three sittings, a save across days | The planet (its places, wear, craters and people), the cast's memory, open threads, the hero's anguish and the villain's Dread |

**A filler arc is three episodes** (§4 explains why). A main-story arc runs as many as Orb writes. A season is the main story's arcs in Orb's order, with filler arcs and episodes between them, each filler arc on a new planet, and the cast's memory carried across.

### 2.2 The episode's shape: a dramatic spine on a branching route

Each of the five stages is a column of the route, with **two or three places to choose from.** The column fixes the dramatic role, and the choice fills it: which fighter, which place, which kind of stage.

| Column | Its role (Episodes, B) | What its places offer | Narrative's families |
| :--- | :--- | :--- | :--- |
| **1. Cold open** | The pair arrive, and trouble is already there | A horde, a defence, or a pursuit | `arrival` |
| **2. Rise** | A grudge comes to a head | A duel with a roster fighter, or a horde led by a lieutenant | `grudge`, `rematch` |
| **3. Twist** | The episode turns | A third fighter arrives, an ally switches sides, or a lieutenant was the real threat: a two-on-one, a three-way, or a duel that changes hands | `third_party`, `ally_switches` |
| **4. Escalation** | The stakes rise: a home is threatened | A defence of a town, a gauntlet, or a pursuit across the ring | `home_threat` |
| **5. Climax** | The episode's opponent, on his home ground | The episode's boss: a duel or a two-on-one at his home | `boss_taunt` |
| **The cliffhanger** | A card, not a stage | "Next time": who is coming, and where | `cliffhanger` |

- **The arc's finale** replaces column 5 of its last episode with **the arc's boss** on its home ground, with tier 5 and the catastrophe (`run-mode.md` §3).
- **Branches cross:** a place not taken in column 2 can come back in column 4 as a consequence ("while you fought at the harbour, the Rival took the ridge"). This borrows the Siege's best idea, the fronts you didn't take, without its board.
- **Graded henchmen** fill the hordes by column: grades 0 and 1 in columns 1 and 2, up to 3 by column 4 (`docs/combat/henchmen-grades.md`). **Henchmen stay anonymous and have no memory** (Legal mc01).

### 2.3 The route is the ring: choosing by flying

**There is no map screen.** Between stages, the ring turns at the calm moment (World's shifting arena), so the next column's places lie along the ring the players are on. Each place shows itself in the world, as its threat would:
- smoke and fire over a town under attack;
- a fighter's aura on the horizon;
- a horde's dust;
- the boss's sky over his home.

**The edge HUD may carry one small beacon for each place** at the screen's edge, toward it, with its kind as an icon, and never on the fighters (`minimal-hud.md`).

- **Flying to a place starts its stage** when a player enters its ground. Its arrival beat plays as two or three lines over play, at the edge, skippable, and never stops the fight.
- **The places of a column sit 10 to 25 seconds of boosted flight apart,** so choosing is a real decision and never a long trip. The climax's home may be farther; that flight is the build-up, and its beat plays on the way.
- **A beat card** appears between columns, for two or three lines, while the ring turns. Orb named beat cards as a place to drop in, so they stay. They are skippable, and both players can keep flying during one.
- **Boons are taken in the world, not on a menu:** the finished stage leaves three marks on the ground (a form, an ability, a rest or lifeline), and flying through one takes it. In co-op, each player takes his own.

## 3. Drop-in co-op

### 3.1 Joining and leaving

| Where | What happens |
| :--- | :--- |
| **Character select** | Both pick, and the episode starts with both on the ring |
| **On the route** (flying between places) | Player two presses any button. His fighter arrives from over the horizon toward player one, inside 3 s, with an entrance, and is on the ring at once |
| **During a beat card** | The same arrival, played behind the card. The card then reads him in (`p2`) |
| **Mid-brawl** | Player two's fighter arrives as an **interjection:** he flies in, and his first blow lands on whoever player one is fighting, under the one-versus-many rules (one partner in the exchange, the ring's single blows on openings). The fight never stops (Orb, 2026-10-11: "the fight should seamlessly continue") |
| **Leaving** | His fighter flies off over the horizon, or, if the player who stays asked for one, the CPU partner takes him over. A beat reads it |

- **The CPU partner** is optional in solo, and fully its own mind with one order the player can give (stay close, or go ahead). It never splits from the player unless ordered.
- **No friendly fire.** Collateral and its costs are shared: a death on the ring is on whoever caused it, by the standing rules. **That is a count for the meters only:** no per-player casualty tally appears on any screen, results page, comparison, leaderboard or achievement, and menace and anguish stay power meters, not scores (Legal mc02, c08).

### 3.2 Splitting and converging on one ring

**Both players are always on the same ring, in real time.** Flying apart and flying together are both just flying.
- **Splitting:** if the players fly to two different places of a column, both stages run at once, on the same ring and in the same sim. The camera splits when they are far apart and joins as they close, eased as Camera's split already is.
- **Converging:** a player who finishes his stage first flies to the other's, and joins it as an interjection (§3.1). His partner's duel becomes a two-on-one, or the horde becomes a shared one. **This is the reason to finish fast,** and it makes splitting a real choice: two stages in the time of one, or one stage taken together.
- **The column ends** when every stage taken in it is done. Nobody waits in a menu: a player who finishes first can help, take a boon, or scout the next column's places.
- **What the route offers when split:** the build starts with **at most one fighter-grade fight at a time** (Research's study, homework 7: two full brawls at once costs the most). So in the first build, a column never offers two roster duels side by side. When one player is in a duel, the other's choices are a horde, a defence or a pursuit. Two full fights at once come later, behind a switch, once the director can run two brawls.
- **Rings wrap.** Two players who sprint in opposite directions meet on the far side, so the ring itself brings them back together (pillar 1).

### 3.3 Two on one, and losing in co-op

- **A duel with two players is a two-on-one** under the one-versus-many rules. The lone opponent gets the lone fighter's tools (moves that hit everyone in reach, the stick choosing his target), and **his health scales ×1.6** with two players. That is a first value for QA.
- **A partner knocked out in a stage is out until the next stage.** He is back at its start, as homework 41's shared parts say. **The stage is lost only when both are out,** or when its goal fails (a defence's town falls).
- **The hordes scale** in count, not in grade: ×1.5 for two players.

## 4. How long a campaign runs: as far as procedural stories stay interesting

**What a generated story can do, and where it runs out.** Narrative's rule is that beats fill slots in authored templates and never add lore. So **a generated story is only as interesting as the state its slots read, and as deep as the template pool.** It stays fresh while two things hold: the state keeps changing in ways a player cares about, and the same template doesn't come back too soon.

**The state that makes it interesting** (all in the run state, `run-core.md` §2 and §12):
- **The planet's wounds:** places damaged and fallen, craters, the scars of beams, flooded trenches. They persist across the arc, so episode three is fought on the ruins episode one made.
- **The cast's memory:** who beat whom, where, how close, and what was wrecked (`last`, `wrecked`). **A rival you humiliated comes back angrier, on the ground you wrecked last time.** "Angrier" is his lines and the beat's tone, and nothing else (mc01, below).
- **Open threads:** a debt, a grudge, a cliffhanger's promise (who is coming next), and an ally who switched sides and may switch back.
- **The two meters:** the hero's anguish and the villain's Dread, which shape the arc's end (`run-mode.md` §5.1, the final arcs).

**What memory may do, and what it may never do** (Legal mc01, `docs/legal/campaign-screen.md`, RL-182). The ledger chooses lines, grounds and beats, and nothing more.
- **No parameter of any non-player fighter ever changes because of what happened between him and the player:**
  - no rank, title, promotion or demotion;
  - no new ability, strength, weakness or fear;
  - no change of name or look;
  - no "stronger because he beat you", and no "weaker because you humiliated him".
- **No procedurally generated enemy individuals** with names, traits or histories. No ladder or chain of command among the cast, and no lieutenant who replaces a fallen boss.
- **A future feature that wants a fighter's behaviour, numbers or looks to depend on past meetings stops and asks Legal first.**

**How far generated stories go, by level.** This is the filler's reach. The main story's length is Orb's, and its episodes use the same machinery around Orb's fixed beats, so they stay fresh in their generated parts as filler does.

| Level | What is generated | How long it stays fresh, with the launch content (4 fighters, about 30 templates) |
| :--- | :--- | :--- |
| **An episode** | The route (places, kinds, opponents), the fills of the five roles, the twist, the beats | Every episode differs in route and fills. Templates start to repeat in about the third episode, and the picker's rarity score holds them off a little longer |
| **An arc** (three episodes) | The planet, its homes and places, the arc's villain and his claim, the threads | **Three episodes is the sweet spot:** long enough for the planet's wounds and the rivals' memory to pay off, short enough that the templates don't wear thin |
| **A season** (filler arcs between the main story's) | A new planet each filler arc. The cast's memory carries across arcs | About six arcs before the arc-level shape feels familiar with four fighters. With the roster of twelve and a library of about 90 templates, a season can run twelve arcs or more |
| **Beyond** | Reruns: an arc again on a new seed, under the challenge tiers (Pressure 1 to 10, `run-mode.md` §4.4) | Without end, as a challenge rather than a story |

**What pushes it further** (each one Narrative's or World's to grow):
- **Templates that read two threads at once** (a rematch at a fallen home);
- **arc-level shapes** that vary (a betrayal arc, a hunt arc, a defence arc);
- **the planet's own events** (a town rebuilt between episodes, a crater flooded into a lake);
- and Orb's universe, written in, which the slots can then use.

**For Simulation's run state:** an arc block beside the run.
- The planet persists across episodes, through the existing carry.
- The cast's memory is the ledger's stage records, kept across episodes.
- The threads are a small list of open promises, as whole numbers and ids.
- The episode seed is `H(arc, "episode", n)`, chained as stages are now.

Episodes are runs, so the run state needs no new kind of carry, only a longer life for its planet and ledger.

## 5. Losing: is a flat restart fun, cool or balanced?

**A flat restart is balanced.** The roguelite loop is honest: every run starts equal, and a win is earned. **It isn't cool or fun after forty minutes,** though. A loss that wipes the story makes the last episode's drama count for nothing, and that is when a player quits.

**So the ruling is: restart the power, never the story.** A lost episode resets what a run resets (boons, the ceiling, lives), which keeps the balance. Its story goes on, and the loss itself becomes something the next episode answers. Three mechanics do that. **Orb can pick, and the recommendation is the first two together.**

### 5.1 The rescue: a friend steps in (in an episode)

**When the player is knocked out in a stage, before any life is spent, an ally arrives:** another fighter from the arc's cast (an ally from an earlier twist, a rival who owes him, or a guest), flying in over the horizon. **The player takes control of the ally,** and the stage goes on from where it was. The opponent keeps his damage, and the ally starts fresh.
- **If the ally wins,** the hero is back next stage, and the arc owes the ally: a beat, and a chance that the ally joins a later stage as a partner place.
- **If the ally falls too,** the stage is lost, and a life is spent as `run-mode.md` §4.1 rules.
- **Once an episode.** In co-op the partner is the rescuer, and nothing new is needed.

**Why it works:** it is the anime's own move, the friend who steps in when the hero falls. It turns the worst moment into a twist, and it lets a player try another fighter in a real fight. It costs little: any roster fighter can be the ally, and the stage simply continues.

### 5.2 "Previously on": a lost episode airs, and the next one answers it

**When an episode is lost** (its lives are gone), **nothing is erased.** It ends on a "To be continued" card. The planet keeps what the loss did: the place falls, and the villain holds his claim. **"Fallen" is a wear state only:** no card, line or beacon says who or how many were lost there (mc02). The rival who won holds the high ground. **The next episode opens with the recap** and answers the loss:
- **A training stage replaces the cold open:** a short drill of 60 to 90 seconds, against what beat him. Lost to a beam? Its struggle. Lost to a rally? The air tech.
- **Clearing the drill gives a lesson,** a small, specific gain for that episode only: for example, against the one who beat him, his first tech window is 2 ticks wider. **It is never a stat that carries past the run** (`run-mode.md` §4.4).
- **The rise column always offers a rematch place,** with the one who beat him, on the ground that fell.

**Why it works:** a loss becomes the hook ("you know what beat you, and you can get him back"), so starting again is the next thing the player wants to do. It keeps the roguelite's flat restart of power, and it keeps the story.

### 5.3 The comeback bet (an option at a loss)

**At a stage's loss with lives left, the player may bet instead of retrying:** retry from the brink (he starts at the brink's health, with the brink's power, `spec-wounds.md`) for a doubled reward (a rare item, or a temptation boon, `run-mode.md` §1.4).
- **Win, and it is the episode's highlight:** a keepsake and a beat.
- **Lose, and the stage costs two lives.**

**Why it works:** Orb likes gambles (the taunt as a gamble), and comebacks are pillar 6. It turns a retry into a choice, but it is the smallest of the three, and the most likely to be skipped.

### 5.4 The recommendation

**The rescue inside an episode, and "Previously on" between episodes.** Lives stay as `run-mode.md` rules them (retries), with the rescue as the first answer to a fall. The comeback bet is held for later.
- A player who loses a stage gets a twist (a friend steps in).
- A player who loses an episode gets a reason to play the next one (a lesson and a rematch).
- Neither ever wipes the arc.

**Legal passed §4, §5 and §6 with conditions** (`docs/legal/campaign-screen.md`, RL-182: mc01 to mc03). "Rivals remember" stays a matter of beats that read the ledger, under mc01 (§4). The lesson is a gain on the player's side only. **Before the campaign ships or sells, a patent attorney reads the claims Legal names** (mc03, which is in Orb's homework).

## 6. The ledger's slots, under Legal ln05

The campaign's beats read these, and no others. Every one follows `docs/legal/beat-templates-screen.md`:
- "wrecked" comes only from structure and terrain events;
- fronts and homes read place and wear only;
- the Cyborg's `home_wear` reads only his own yard;
- no casualty count, toll or victim type is ever a slot (c08).

| Slot | What it reads |
| :--- | :--- |
| `last` | The last result between two fighters: won, lost, close, a draw |
| `wrecked` | What their last meeting brought down: a tower, the pier, a crater, a fire, or nothing |
| `home_wear` | A home's state: untouched, damaged or fallen |
| `place`, `prev_place`, `next` | Place names, and the next opponent and place, for a cliffhanger |
| `thread` | An open promise: a debt, a grudge, an ally who switched sides. **About fighters and places' wear only:** never a casualty, a toll, a victim, a promise to avenge anyone, or a debt to the dead (mc02) |
| `rescued_by` | The ally who stepped in (§5.1) |
| `lost_episode` | That the last episode was lost: where, and to whom (§5.2). Never what was lost in people (mc02) |
| `lesson` | What the training stage taught (§5.2) |
| `n_left` | Stages left before the climax |

`toll_band` stays as Narrative has it: coarse, never a score, and never read by a Cyborg line. **Saves across days stay local,** with no personal data. Cloud saves or online co-op would need the privacy line and the store answers changed first (mc02).

## 7. Who builds it, and the first slice

| Owner | What |
| :--- | :--- |
| Encounter | Stages as kinds (horde, duel, defence, pursuit, two-on-one, boss), the interjection join, the two-on-one scaling, two stages at once on one ring, the rescue |
| Simulation | The arc block in the run state, two stages in one sim, the episode seed |
| World | The places of each column along the ring, the ring turn between columns, the planet's wounds across episodes |
| Narrative | The families mapped to the columns, templates for the rescue, the recap, the lesson and the rematch, and the threads |
| Camera | The split and join for two players on one ring, and the arrival from the horizon |
| UI | The edge beacons, boons in the world, the beat card's edge form, "To be continued" |
| Controls | Drop-in from any pad at any moment, and the CPU partner's one order |
| QA | The rows below |
| Legal | Done: RL-182 (mc01 to mc03). The patent read (mc03) is due before the campaign ships |

**The first slice:**
1. One episode, solo, five stages on one planet, choosing by flying.
2. Then drop-in co-op converging on one fight.
3. Then the split (one duel and one horde at once).
4. Then the arc's carry across two episodes, with "Previously on".
5. Then the rescue.
6. Then the first main-story episode, on Orb's seeded planet with Orb's fixed climax, and the side-story place that opens a filler episode from inside it (§1.2, §1.3).

**QA's rows:**

| Row | Band |
| :--- | :--- |
| An episode's length | 40 to 50 minutes median |
| Flight between a column's places | 10 to 25 s |
| Stages won with a partner who joined mid-stage | Read only, to tune ×1.6 |
| Rescues won | 30 to 60% |
| Rematches won after "Previously on" | 50 to 75% (the lesson should help, not decide) |
| Templates repeated inside one episode | None. Inside an arc, at most 3 |

## 8. For Orb: the questions only Orb can answer

One at a time, for the EP to ask when it suits. Each has a recommendation.

1. **Losing:** "When you lose, which should happen? (a) A friend steps in to finish the fight, and a lost episode continues as 'Previously on…' with a training drill and a rematch (recommended). (b) Only 'Previously on…'. (c) The comeback bet: retry from the brink for a bigger prize."
2. **How you write the main story:** "For each main-story arc, will you write a spine of one line per episode (who, where, what happens and how it ends), with the game generating the rest around it (recommended)? Or a full script for each episode?"
3. **Filler inside the main story:** "Should a side-story episode played between two main-story episodes leave the planet as the main story left it, as anime filler does (recommended)? Or should its damage carry into the next main-story chapter?"
4. **What opens first:** "Should filler arcs and episodes be open from the start while the main story opens chapter by chapter (recommended)? Or should filler open only after the main story's first arc?"
