# The daze, the sell and the rally (parked 2026-10-25, re-cut 2026-10-26)

Owner: Encounter Systems Director. Game Design's `rulings-2026-10-23d.md` with its §8 (each fighter's own links) and the reads' rulings (`rulings-2026-10-26.md` §2a items 7 to 12, §2c, §2e items 22 to 26), Combat's choreographer scoring (`docs/combat/pending/rally/`), and Controls' read of the stick (`docs/controls/palm-turn-overtake-read.md`); Orb's answer to the early B ("moments where a fighter gets stunned, then sells some big powerful hits from the attacker, who then continues to bounce him around with elaborate flight attacks"). Behind `data/director/interrupts.json` `rally.enabled` (false), so the golden doesn't move. With it on, the chase, the recoil flips and the wall kick are on too: they are the rally's links and answers.

## To build it

On main (launch-spike is in) after World's rivers, surfacing and w16, `../launch-answer/` and `../water-surface/` (drops only), in that order (`DirRally`'s slots follow `DirWater`'s; the dazed B is read before the pop and the spike): `node rl.cjs <root>` from this folder. `--check` reads every anchor and writes nothing.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/rally.gd` (new, `DirRally`) | Encounter | The daze, the sell (and the AI's, `aiSell`), the rally's state (its kinds, its destinations), the attacker freed after each send (`_release`) and a link press that waits for it (`queues`), its links' techs and the world's links (`worldLink`), the stick's read at the commit, the own links' lines, the turn, the ends, the opening's no-down pick (`openNoDown`), no Escape in a rally (`noEscape`), the choreographer's scoring. 27 slots after the water's |
| `sim/director/brawl.gd` | Encounter | The daze's sources: a guard broken by a charged blow or a tapped heavy outside a string (`breakDazes`), a perfect block that turns a charged blow or an ender (`pbDazes`), a clean full charge, a heavy's whiff punished by a tapped heavy or a perfect follow-up (`_miss` notes it, `contact` dazes). The sell's hit-stop weight. B at a dazed fighter is the launcher, sure, at full power, a decisive send that opens the rally (`_send` takes extra args). The turn, at a landed blow. The AI's sell before B (`aiInput`) |
| `sim/director/chase.gd` | Encounter | On with the rally. The spike link (B from above him, `_spikePress`; no zip price). A waited link press's start (`startQueued`). The AI's reaction in a rally runs from the send. A rally's chase always arrives: at him before his landing, with no time-out. The stick read at the commit (`_begin`). At the catch: the link's kind, the defender's tech, the overtake's line (back the way he came, the chaser passing him), the spike's (straight down), the Palm Turn's (across), Plate Chase's exact line (no planner), and the link counted |
| `sim/director/recoil.gd` | Encounter | On with the rally. A spent counter-rush is noted for the turn |
| `sim/director/wallkick.gd` | Encounter | On with the rally. A wall slam (a face met and not kicked off) dazes him once he is up. A face met in a rally's flight is a world link |
| `sim/director/ai.gd` | Encounter | No Escape stance for a rally's attacker or its sent body |
| `sim/director/interrupt.gd` | Encounter | The burst: none in a daze's first 12 ticks; allowed in flight after a link's first 12; it breaks the daze and ends the rally's flight |
| `sim/director/launch.gd` | Encounter | The choreographer's variety term in a rally |
| `sim/director/melee.gd` | Encounter | A full send opens a rally (`DirRally.onSend`); a decisive send holds the decisive hit-stop; the planner's pick for a send that opens one (`openNoDown`, `clearNoDown`) |
| `sim/director/exchange.gd` | Encounter | `DirRally.tick` in `dirUpdate`; `DirRally.queues` in `_request`, before the brawl's |
| `data/director/interrupts.json` | Encounter | `rally` {`enabled` false, `daze` {40, 3, 6, 12}, `waryTicks` 120, `sell` {weight launch, bLeftTicks 8}, `tech` {fresh 4, earlier 6, repeat 8, autoAt 3}, `read` {leanMin 0.6, sectorDeg 45}, `own` {palm_turn: PROTAGONIST over overtake, plate_chase: RIVAL over chase}, `endTicks` 20, `queueTicks` 12, `turnTicks` 60, `airBh` 1, `spikeAboveBh` 0.5} |
| `data/director/rally.json` (new) | Encounter (Combat's numbers) | Combat's choreographer scoring, `director.rally/1`, as parked in `docs/combat/pending/rally/rally.scoring.json` |
| `data/director/ai.json` | Encounter | Each level's `rally` {link, sells, tech, techEarlier, techRepeat, dazeMash, dazeBurst, airBurst} |
| `tools/schemas/director-interrupts.schema.json`, `director-ai.schema.json`, `director-rally.schema.json` (Combat's draft), `map.json` (its row) | **Tools** | `rally` |
| `tools/fixtures/virtual/data/director/rally.json` (a copy of the data), `tools/fixtures/cases.json` (five `director-rally` cases: one valid, three invalid, one underscore key) | **Tools** | The self-test reads `data/director/` from its virtual folder and wants three invalid cases for each mapped schema |

## The rules as built

- **The daze (1 to 3; item 1 as amended by 10-26 items 8, 23 to 25):** 40 ticks of stun, from four of the six sources: a guard broken by a charged blow or a tapped heavy outside a string (worn through, or broken by a launcher, the newcomer's B among them, it is the plain stagger or the launcher's own result); a perfect block that turns a charged blow or a string's ender (a heavy after other blows of his string); a perfect block of a light, a medium, a plain heavy or a launcher is the plain reversal, and a turned launcher keeps the stagger and the sure counter-launch, whose send may open the AI's own rally unsold; a clean fully charged heavy (in place of its launch); a heavy's whiff punished by a tapped heavy or a perfect follow-up (10-26 item 23's next step, dazes having read 8.1: never a light, a medium or a launcher, so mashing alone never dazes); and a wall slam (once he is up). He can't strike or guard. Each press of his (any face button, guard, dodge or A) takes 3 ticks off, at most one every 6, so the fastest thumb cuts it by about a third (10-26 item 17); RT's burst breaks it after 12, at the burst's price. A fighter a rally ended on is wary for 2 s: a daze source on him is the plain stagger then. The AI mashes and bursts at its level's shares.
- **The sell (4, 5; 10-26 §2c):** a landed **medium** at a dazed fighter holds the launch's hit-stop (12) and sends a `sell` cue (Camera's push, Animation's larger reaction). Its damage is its own; lights aren't sold. **B at a dazed fighter is the launcher whatever the string,** the heaviest blow of the sell: sure, at full power (never a pop), a send with the decisive hit-stop (20), the planner's candidates and freshness, and it opens the rally, sold. **The AI sells first (10-26 item 10):** its level's `rally.sells` mediums (easy 0, medium 2, hard 2), one at a time while one more still leaves B its press with `sell.bLeftTicks` (8) of the daze left; then B.
- **The rally (6, 7):** any full send opens one (power 0.8 or more, or a launch with no launcher's power), **except a special launch** (a signature, a finisher or a template exchange's break launch): the chase can't follow one (7c), so it could have no link (10-26 item 26, confirming my reading: 16 of 62 openings were special and none could link). **A rally's opening send is never down on a neutral stick** (item 22b): the planner picks across or up for it; a stick held down still wins. Its links, each the attacker's own press while the body flies, and the world's:
  - **the world's link** (item 22a): a send of the rally carried into a building (World's `building_hit` on him), across water (a skim beside him) or against a face (a cliff's or a building's, at the wall kick's meeting) is a link with no press, one a send, kind `world`. Vents aren't in the sim yet;
  - **the chase strike:** LT with X or Y, the zip at its price, as built;
  - **the overtake:** the same chase with the stick held back against his flight (the AI at its share): the chaser passes him and the send goes back the way he came;
  - **the spike:** B from above him (half a body height or more), no zip price: the send goes straight down;
  - **the Protagonist's Palm Turn** (§8, his own kind): the chase with the stick across his flight; the body is turned 90° by the stick (the AI: up);
  - **the Rival's Plate Chase** (§8 item 19, his own kind): the chase with Y; the body goes exactly along the stick's eight-way line with no bend from the planner (with no stick, straight on along his flight).
  - **The stick's read** (Controls): read once at the chase's commit, never per tick, and only on a deliberate lean of 0.60 or more; back is within 45° of the reverse of his flight, across within 45° of either perpendicular. No dead band yet.
  - **The attacker is free after each send (10-26 item 7):** on the first live tick after a rally's send (its hit-stop over), the exchange that still holds him ends, a finisher and a beam aside. The first read's zero links were this: a template exchange's chain window (`window`, `chainStrike`) kept him locked after his send. A player's link press made while he is still held waits (`queues`) and starts on his first free tick, within `queueTicks` (12). Each link's send frees him the same way. The AI's chase reaction in a rally runs from the send, not from when it was free.
  - **A rally's chase always arrives** (item 22e): drawn travel to the body, timed to catch him before his landing, with no time-out. His answer is the tech at its arrival, the brake or the burst.
  - **The AI's chase in its own rally** draws at its level's `rally.link` share, 60, 75 or 90% by level (item 22c), in place of `chaseShare` (0.1, 0.25, 0.4), which still holds outside a rally. **No Escape stance** for the attacker while his rally runs, nor for the body while he is sent (item 22d).
  - **The AI's link** is chosen by the choreographer's kind terms (below) plus noise, among the kinds open to it (the spike only from above, the own links only its fighter's).
  - Each link's send carries power 1 for its journey's pay, so the rally's last landing pays by 9a.
- **Repetition (8, 17):** at each link's arrival he techs with a guard press within 4 live ticks for a kind new to the rally, 6 for a kind used before but not last, 8 for the same as the last; the third link of one kind in a rally is teched by itself. Each own link is its own kind. The AI techs at its level's share for each step (fresh, earlier, repeat: easy 0.08, 0.2, 0.4; medium 0.15, 0.3, 0.55; hard 0.2, 0.45, 0.7), tuned toward 10-26 item 9's 15 to 20% of links teched by a medium defender. A teched link ends his journey in the air and gives him the recoil flip's counter-rush.
- **The turn (10):** his counter-rush, landing on the chaser in the air (over 1 bh up, within 60 ticks of its press), is a full send of the chaser, and the rally is his, with its turns counted.
- **The ends (11):** he lands and no link follows within 20 ticks; a teched link isn't turned within the counter-rush's 20 ticks; his burst in flight (after a link's first 12 ticks); a KO. The victim is then wary for 2 s.
- **The choreographer (13, Combat's `data/director/rally.json`):** in a rally, each of the planner's candidates scores its destination (new to the rally +12, the last link's −12, the one before −6) and, as a world candidate (a building, the sea, a cliff), +18 and its place (+6, +6, +4). The AI's choice of link scores the kind terms (new +20, last −20, earlier −10, a third −1,000, an own link +8) with up to 6 of noise. The stick still wins (`stickWins` 200).

## Not built in this slice

- **The bank** (the attacker's kick off a face) and **the energy links** (the energy overhaul isn't built).
- **Ten of the twelve own links** (Combat's kits): the four grabs in flight (Net Haul, Ring Hold, Banner Drop, Crane Reel) wait for the energy grab; the traps (Pillar Lift, Rope Return) for the traps; Slag Catch for the lob; Wreck Toss for the throwables (two presses, an empty wreck within 2 bh: §8 item 20); Stair Spike for its three stepped impacts; Mantle Wall (her braced mantle, a ricochet counting toward two in a row) and all of the Empress's and the Cyborg's links for those fighters, who aren't in the sim yet. The kinds and the scoring take them as they come: each is a name in `DirRally.OWN` and a fighter in `rally.own`.
- **The spike's glance** off hard ground (Combat's plant and glance, not built): the rally spike ends in a landing.
- **Two of the six daze sources:** the bury (its safety window lets no exchange start on him, so a daze there couldn't be sold; Game Design to rule how they meet), and a struggle lost by overwhelm (the beam struggle window isn't built).
- **The meets** (both arriving together): Combat's clash meets, parked.
- **The sell's step back and pull-in:** the cue only; the body's push is Animation's reaction.
- **Each fighter's own links** (item 12): Combat's.

**A name to watch:** `Fighter.rally` (the wounds' brink comeback rule: second wind, spite, reboot, encore) is another system that shares the word. Nothing collides (its events are `brink_close`, these are cues), but Narrative may want one of them renamed.

## Cues (for Animation, Camera and QA)

Camera's names and fields (`docs/camera/pending/rally/README.md` §1): `sell`, `rally_link`, `rally_turn`, `rally_end`; the daze's and the tech's are this build's own. Each is a `cue` fx; `actor` is the fighter named first.

| Kind, text | When | Fields |
| :--- | :--- | :--- |
| `daze`, `start` (source: the why) | he is dazed (actor him) | `target` the one who dazed him, `n` the tick it ends |
| `daze`, `shave` / `end` (source: time or burst) | a press shaves it / it ends | |
| `sell`, `medium` or `heavy` | a sold blow lands (actor the attacker) | `target` the dazed, `amount` 1 a medium, 2 a heavy |
| `rally_link`, `send` (source: `sold` or empty) | the full send that opens a rally, or the turn's send (actor the attacker) | `target` the body, `n` 0, `k` 1 sold |
| `rally_link`, the base kind (chase, overtake, spike; source: the own link, `palm_turn` or `plate_chase`, else empty) | a link lands | `target` the body, `n` the links so far |
| `rally_turn` | the turn: the counter-rush landed on the chaser (actor the new attacker; a `rally_link` `send` follows at the same tick) | `target` the new body, `n` turns |
| `rally_tech`, the base kind (source: the own link) | he techs a link (actor him) | `target` the attacker, `k` 1 by itself (repetition) |
| `rally_end`, the reason (landed, teched, burst, turned, ko, resent) | it ends (actor the attacker) | `target` the body, `n` links, `k` turns, `dur` its live ticks |

The own links' base kinds are data: `rally.own.<link>.base` (palm_turn: overtake, plate_chase: chase).

## The final read (2026-10-26: items 22 to 26 and the whiff step)

On c3ca82e9, in scratch: HEAD + `../launch-answer/` (items 19 to 21) + `../water-surface/` (drops) + this; 269 files, 0 errors, self-test 9,154 of 9,154; the import is clean. With `rally.enabled`, launch anywhere, the answer and the water on. After a read with items 22 to 26 (dazes 8.1, just over the band), the whiff source was trimmed as item 23 rules (a tapped heavy or a perfect follow-up only), and the stack read again:

| Row (QA's runner, 40 matches) | Read | Band | |
| :--- | :--- | :--- | :--- |
| Match length: median, p10, p90 | 375.3, **276.9**, 538.6 s | 360 to 480; p10 at least 300; p90 at most 600 | ✗ (p10) |
| Dazes a match | **5.38** (perfect block 119, charged heavy 52, guard break 35, wall slam 9 in 40 matches) | 2 to 8 | ✓ |
| Rallies a match | 5.30 | 3 to 10 | ✓ |
| Links a rally, median | **1** | 2 to 4 | ✗ |
| Two links of one kind in a row (QA, by the own kind since 3b341393) | 0% | at most 25% | ✓ |
| Rallies ended by repetition | 0% | at most 20% | ✓ |
| Rallies that turn at least once | **4.2%** | 15 to 40% | ✗ |
| Rally time | 4.8% | at most 25% | ✓ |
| Sells a daze | 1.50 | reported | |
| Full launches, a rally once | 6.90 | 6 to 12 | ✓ |

Also: civilians lost 17.9%, flips 2.02 a minute, no faults. `probes/rallyt.gd` (10 matches): 4.9 rallies and 5.1 dazes a match, links median 1 (55 links in 49 rallies, 11 of them the world's), 9 of 54 link arrivals teched (17%), 5 chases too late of 59.

**QA's masher stage** (100 seeds, the stack): the lit-B newcomer against medium 12 of 100 ✓ (10 to 50), against easy 85 of 100 ✓ (50 to 95; item 20's 85 to 90); his first launcher thrown inside 60 s, landed inside 120 s and any launch inside 60 s: 100% at both levels ✓; the banded masher 47% ✓ (35 to 50).

**Why links stay at a median of 1:** a link survives at about its level's link share times the chance he doesn't tech it: 0.75 × (1 − 0.17) ≈ 0.62 at medium, with Game Design's 75% (item 22c) and its 15 to 20% tech (item 9). A median of 2 links needs about 0.71. The world's links add some (11 of 55), and a chase now always arrives (5 too late of 59, from 15 of 96). **The turn** needs a teched link whose counter-rush lands on the chaser: 9 techs gave no turn in this read.

**Golden and gates** (the stack, switches off): the golden is HEAD's, byte for byte; 35 of 35 at 0.

## What the first re-cut read (2026-10-26)

On 00607309, in scratch: HEAD (launch-spike and World's rivers, surfacing and w16 on it) + `../launch-answer/` (as first parked, before items 19 to 21) + `../water-surface/` (drops) + this; 269 files, 0 errors, self-test 9,153 of 9,153 (the Tools fixtures in); the import is clean. With `rally.enabled`, launch anywhere, the answer and the water on.

**QA's rows** (QA's runner, 40 matches, AI v AI; QA reads the rally from these cues since ad39c32b):

| Row | First read | **Re-cut** | Band | |
| :--- | :--- | :--- | :--- | :--- |
| Match length: median, p10, p90 | 456.6, 345.9, 571.5 s | **376.9, 304.7, 471.6 s** | 360 to 480; p10 at least 300; p90 at most 600 | ✓ |
| Dazes a match | 24.5 | **11.7** (perfect block 162, guard break 162, whiff punished 82, charged heavy 51, wall slam 12 in 40 matches) | 2 to 8 | ✗ |
| Rallies a match | 14.0 | **5.75** | 3 to 10 | ✓ |
| Links a rally, median | 0 | **1** | 2 to 4 | ✗ |
| Two links of one kind in a row | 0% (by own kinds) | **30.4%** (QA, by base kinds) | at most 25% | ✗ (see below) |
| Rallies ended by repetition | 0% | 0% | at most 20% | ✓ |
| Rallies that turn at least once | 3.6% | **7.8%** | 15 to 40% (10 to 40 if links and turns conflict) | ✗ |
| Rally time | 7.5% | 3.8% | at most 25% | ✓ |
| Sells a daze | 0.02 | **1.39** (650 for 469) | reported | |
| Full launches, a rally once (10-26 item 11) | 15.4 | **7.85** | 6 to 12 | ✓ |

Also: civilians lost 19.5% (at most 30), flips 1.96 a minute, no faults. `probes/rallyt.gd` (10 matches) agrees: 4.6 rallies a match, links median 1, 15 of 86 link arrivals teched (17%: item 9's 15 to 20), turns 6.5%, 191 sells.

**The repetition row:** QA counts by `rally_link`'s text, the base kind, so a Palm Turn after an overtake (or a Plate Chase after a chase) reads as a repeat. Game Design's item 17 makes each own link its own kind (the cue's `source`); by own kinds it reads 0%. QA's reading is for QA and Game Design.

**QA's masher stage** (100 seeds, the stack): the lit-B newcomer against medium **29 of 100** (✓, 10 to 50), against easy 100 of 100 (✗); his first launch inside 60 s at medium 73% (✗); the banded masher 53% (✗). Items 19 to 21 (the answer park's re-cut) are for these three.

**The newcomer split** (10 against medium, the stack, with the rally's cues counted): he wins 2. The AI dazes him **480 times by perfect block**: its timed answer turns his launchers, and a perfect block that turns a heavy dazes under item 8. He dazes the AI by guard break 135 times: **his line (mash, then B) reaches a daze**, the B into a guard (item 12's question). He opens 57 rallies (33 sold), the AI 31 (10 sold).

**What the re-cut traced** (scratch probes on the same stack):
- **The attacker was held by a template exchange, not the brawl:** after a send in the classic exchanges (kind heavy, branch read, clean or countered), its chain window's beats (`window`, `chainStrike`) kept him locked. With the release in, he is free within 10 live ticks after 53 of 55 sends; the other 2 were finishers, which stay held.
- **16 of 62 openings were special launches** (a template exchange's break launch, a finisher), which the chase can't follow (7c): none could link. A special launch now opens no rally (my reading; for Game Design).
- **What still keeps links low:** of 64 rallies, 35 had no link; in 20 of those no chase started (the AI's draw missed in about 9, the AI was in Escape in a few, the send landed at once in 5) and 13 were downward sends; 15 chased and missed (6 too late, 6 teched, 3 stopped). Rallies with a link ran 1 to 5.

**Golden and gates** (the stack, switches off): the golden is HEAD's, byte for byte; 35 of 35 at 0 (the gate run covers all three parks).

## What the first build read (2026-10-25)

On 4dc06456 (2026-10-25), in scratch with launch-spike and water-surface: `rl.cjs` applied, 265 files, 0 errors; the import is clean and made `files/sim/director/rally.gd.uid` (`uid://crt06cmqieura`). With `rally.enabled` and launch anywhere on (which turns the chase, the flips and the wall kick on with it).

**Game Design's §7 rows** (`probes/rallyt.gd`, AI v AI medium, 10 matches to the KO, 100 minutes):

| Row | Read | Band | |
| :--- | :--- | :--- | :--- |
| Match length (QA's runner, 40 matches) | median 456.6 s, p10 345.9, p90 571.5 | median 360 to 480, p10 at least 300 | ✓ |
| Dazes a match | **24.5** (perfect block 156, guard break 48, whiff punished 20, charged heavy 14, wall slam 7) | 2 to 8 | ✗ |
| Rallies a match | **14.0** | 3 to 10 | ✗ |
| Links a rally | **median 0** (147 links in 140 rallies; 91 rallies with none) | median 2 to 4 | ✗ |
| Two links of one kind in a row | 0% | at most 25% | ✓ |
| Rallies ended by repetition | 0% | at most 20% | ✓ |
| Rallies that turn at least once | **3.6%** (5) | 15 to 40% | ✗ |
| Rally time | 7.5% of match time | at most 25% | ✓ |
| The lit-B newcomer against medium (L17) | **88 of 100** (95 without the rally) | 10 to 50% | ✗ |
| The banded masher | 44% (53% without the rally) | 35 to 50% | ✓ |

Also from QA's runner: civilians lost 25.8% (at most 30), flips 1.46 a minute (1.2 to 6), **full launches 15.4 a match** (6 to 12, 14 at the top): the count takes each link's send as a launch. No faults. Links by kind: plate chase 54, palm turn 35, overtake 27, chase 25, spike 6. Chases: 196 started, 156 caught, 17 teched, 15 too late, 8 stopped. Sells: 5 in 245 dazes.

**Why most rallies have no link** (a scratch trace on the same copy and seeds): of the 91 rallies with none, **74 never started a chase**. In 47 of them the attacker was still held in the exchange after its own send (not free), so the body landed before it could zip. In 24 the send was downward and landed at once. The 49 rallies with a link ran 1 to 7 links (median 2). So the AI's link share isn't what holds it: a player is held after a send the same way (`DirChase.takes` needs him free and no exchange running).

**Inferred, not traced:**
- **Sells are rare** because the daze opens the sure-launcher window, so the AI presses B at once and sends.
- **The turn is rare** because it needs a tech, and the AI's tech shares were set low so that links can hold (a link survives at about share × catch × (1 − tech)).

**Golden and gates** (switches off): the golden is HEAD's, byte for byte; 34 of 35 at 0. The self-test failed on coverage: the new schema had no virtual document and no invalid cases. With the two Tools fixtures above added, the self-test passes on a fresh copy (9,095 of 9,095). The fixtures touch no sim code.
