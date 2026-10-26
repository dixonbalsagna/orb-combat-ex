# The rally: each fighter's own links, his sell, and the choreographer's variety scoring (parked)

Combat and Choreography, 2026-10-25. **The frame is Game Design's** (`docs/design/rulings-2026-10-23d.md`): a daze earned from six sources, the sell of two or three big blows, and B's send opening **the rally**, a chain of flight attacks. Each link is the attacker's own press. Variety holds a rally together, and repetition ends it (item 8). All of it sits behind `rally.enabled`.

**Orb:** "if the knockbacks are varied and entertaining enough, there should be nothing stopping two players from knocking each other all around the planet. if it gets too repetitive, it will violate the rule of cool."

Paper and parked data; nothing is built. The names are working labels for Narrative.

## 1. The files

| File | What it is |
| :--- | :--- |
| `protagonist.md`, `rival.md`, `empress.md`, `cyborg.md` | One page per fighter: his own links and his sell |
| `rally.<fighter>.json` | The same as data, `combat.rally/1` (target `data/combat/rally/<fighter>.json`), with its draft schema `combat-rally.schema.json` |
| `rally.scoring.json` | The choreographer's variety scoring, `director.rally/1` (target `data/director/rally.json`, Encounter's), with its draft schema `director-rally.schema.json` |

## 2. Each fighter's own links

Each own link is a variant of one of Game Design's link kinds (item 6), on the same buttons, so nothing new is learned. Each counts as **its own kind** for item 8's repetition and for the scoring. That is proposed, and Game Design is asked to confirm it.

| Fighter, identity | Link 1 | Link 2 | Link 3 |
| :--- | :--- | :--- | :--- |
| **The Protagonist,** control | **Palm Turn** (an overtake): the stick held across the flight. An open palm turns the body 90°, up or down by the stick, and up and away from people with no stick | **Net Haul** (the grab in flight): the yank hauls the body to him mid-air, and his next press sends it on with no zip to pay | **Pillar Lift** (a world link): a send across his own Trip Pillar throws the body up and away from people (TRAP LANDING) |
| **The Rival,** precision | **Plate Chase** (the chase with Y): sent exactly along the stick's line, snapped to eight directions, with no bend | **Ring Hold** (the grab in flight): the bind holds the body still in the air, struggling, and his next shot lands as a normal hit on an open fighter | **Stair Spike** (a spike): one press, three stepped plate impacts straight down, the third the crater |
| **The Empress,** dominion | **Rope Return** (a world link): Velvet Rope laid across his coming path. Crossing it fires her level-1 beam and knocks him back across her line | **Banner Drop** (the grab in flight): the staves slam him down into the ground from any height, landing him on one knee | **Mantle Wall** (a bank): the body rebounds off her braced mantle, which never wraps or grabs. Game Design may rule the design |
| **The Demon Cyborg,** appetite | **Crane Reel** (the grab in flight): the hook reels the body back, turns it once at body height (never overhead) and flings it 6 bh along the stick, reversing the flight | **Wreck Toss** (a world link): an empty wreck, with nothing living near, hurled at the flying body sends it on (the throwables' rules) | **Slag Catch** (a lob): level-2 slag led to his landing pops him 3 bh back up, even on soft ground |

**Distinct by design.** The cross-check holds that no two fighters share a link of the same kind and destination.
- **The four grabs in flight are the four payoffs:** the yank pulls in, the bind holds still, the slam drives down and the throw reverses.
- **The two trap links throw opposite ways:** the pillar throws up, and the rope throws back.
- Each set reads as its identity: the Protagonist decides the line, the Rival keeps it exact, the Empress rules the space, and the Cyborg uses the scrapyard.

**Prices are the base links'.** The zip pays 20 or 30, the grab 10 or 14, a level-2 lob 12, and a trap 12 when it is laid. A world link costs nothing at the time. Nothing in a fighter's links changes the ki table, and every tech window is item 8's.

## 3. The sell: a size larger, by fighter

In the daze, each landed medium or heavy takes the launch's hit-stop (12), a camera push and a bigger reaction (item 4). **The sell is the look, never the number.** Each fighter sells in character:

| Fighter | A sold heavy | Its recovery | The send |
| :--- | :--- | :--- | :--- |
| **The Protagonist** | Folds over the blow, breath forced out in a visible gust, driven back a step | A short laugh and a nod: he grades it | Launched arms wide, still grinning, turning to watch who sent him |
| **The Rival** | Barely folds; his glare comes back before his body; a long skid (stepBh 1.3) | A sneer, and a plate straightened on his forearm | Launched rigid, arms in, refusing to flail until the flight turns him |
| **The Empress** | Rocked back on one heel, the mantle billowing; she laughs through it | A booming laugh and a royal straightening; she never calls her guards | Launched with the mantle streaming like a banner, laughing |
| **The Cyborg** | Folds at the waist joint, the grille rattling, sparks from the neck seams (one burst) | A whirr as the limiter resets; the flesh steams and closes | Launched in a shower of loose rivets and wire, limbs swinging on their joints |

**Shared rules for the sell:**
- The body is never limp, and nothing slows down beyond the hit-stop.
- No taunt plays over a dazed fighter, and each sold blow is one flash event at most (fx08).
- The Cyborg's light stutters stay under a 10% step and 2 Hz (fx09), and his hunger lives in his voice, never in a mouth (ln02).

## 4. The choreographer's variety scoring (Game Design 23d item 13)

The scoring is for the AI's choice of link, for Simple's choice, and for the planner's send candidates inside a rally. Each candidate gets these terms in the planner's points, on top of the planner's own:

| Term | Points | Why |
| :--- | ---: | :--- |
| A kind not used yet in this rally | **+20** | Fresh kinds score highest. Item 8 gives a fresh kind the tightest tech (4 ticks) |
| The same kind as the last link | −20 | Item 8's 8-tick tech |
| The same kind as the link before that | −10 | |
| A third of one kind | −1,000 | It is teched by itself (item 8), so it is never chosen |
| A destination new to this rally | +12 | Where the link sends him, by the same rule |
| The same destination as the last link | −12 | The one before that scores −6 |
| **A world link** (no press: the send carries him into the place) | **+18** | Plus its place: the parted sea +8, a building or water +6, a cliff or a vent +4, ice or trees +3, a slope +2 |
| A fighter's own link | +8 | It shows who he is, under the fresh-kind rule |
| Noise | 0 to 6 | |

- **Where the scores land:** the best possible variety total is 72 (+20 fresh kind, +12 fresh destination, +18 world link, +8 parted sea, +8 own link, +6 noise). It ranks a fresh world link through the parted sea first. A repeat sinks, and a third of a kind is never chosen.
- **The stick still wins.** A held stick keeps only the candidates inside its cone (the planner's `TILT_CONE`) and adds `stickWins` (200) to the stick's side, so variety (72 at most) never overrides the player.
- **Internal only.** The points are never shown to a player and never read casualties (Legal RL-183).
- **Personality** is the planner's care term at the landing: the hero sends away from people, and a villain toward them. With no stick, the highest score is taken: spectacle by variety.
- **What QA reads** (23d §7): two links of one kind in a row at most 25% of links, rallies ended by repetition at most 20%, and a median of 2 to 4 links a rally. The scoring is built to land inside those bands.

## 5. Legal's rules, as they apply

- **Grabs in flight** (e12, ln06):
  - every bind takes arms or torso, and the held fighter struggles;
  - one call-out per grab, on the throw or in the catch's first 10 ticks;
  - nothing is said, slowed, zoomed or finished over a fighter held in the air.
- **The Empress's staves** are never joined by light into a box, a barrier or a dome, and the kneel is the slam's landing only (e16).
- **The Rival's ring** is a thin loop, never a disc (e12), and its link is named Ring Hold, never "hang" (RL-183): he struggles and never dangles, and the shot on him is a normal hit. **The pillar** is a solid slab (e14).
- **The Crane Reel's swing** is a short turn at body height, never overhead (RL-183).
- **Flash across the whole rally** (mc04): 3 counted bursts a second at most, and a link that would pass it draws as dust, trail and ember. **The Stair Spike's three impacts** merge into one glow that brightens only at the last, to be proven in a clip.
- **The Cyborg's set** is wreckage and metal only (ln04). A wreck is always empty, and one with anyone living near it is never a candidate (RL-183).

## 6. Proof

Tools' validator in a scratch root, with both drafts and their map rows added:
- the four kits and the scoring read 0 errors and 0 warnings;
- four refusals fail at their pointer: a fourth link, an unknown base kind, a sell step past its band, and noise past its band.

**Cross-checks:**
- link ids and names are unique and carry their fighter;
- no two fighters share a link of the same kind and destination;
- every world place is a destination;
- the scores keep their order (a fresh world link above a fresh kind, above nothing, above a repeat, above a third);
- variety at its largest (72) stays below `stickWins` (200).

## 7. Open questions

- **Game Design:**
  - do a fighter's own links count as their own kinds for item 8 and the scoring?
  - the Empress's Mantle Wall (Narrative's rename from Guard's Wall: the bank is her braced mantle, so `empress-guards.md` §4 is met);
  - is Plate Chase's exact line, with no planner bend, allowed?
  - does the Cyborg's Wreck Toss meet the throwables' pick-up rule mid-rally?
- **Encounter:** the rally memory the scoring reads (the last two kinds and destinations of the current rally).
- **Narrative:** the twelve link names (Legal renamed Ring Hang to Ring Hold; Narrative renamed Guard's Wall to Mantle Wall and Plated Ram to Plate Chase).
