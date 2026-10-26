# Henchmen in grades: the moveset side

Owner: Combat and Choreography. Date: 2026-10-23. Paper only: no data file, nothing built.

**Ruled by Game Design, 2026-10-25** (`docs/design/rulings-2026-10-25.md`), and folded in below:
- **Accepted as written:** the grades, the turns, lights hitting one body, the crowd caps, the return at most twice, and an elite with no brink.
- **The domino is raised:** a body sent by a medium dominoes up to 3, and one sent by a heavy, a throw or a launch up to 5.
- **The relay has no cap:** a body's toughness ends it.
- **The horde's damage is banded:** a medium player loses 10 to 30% of his health over a horde stage in columns 1 and 2, and 20 to 45% by column 4.
- **An elite's trick** is a type picked for each spawn: never kept, never named, with no memory (Legal mc01).
- **The holds are E102's one-body hold,** and in any stage with a second player or a horde, every hit-stop is a one-body hold (recommended until Orb says otherwise).
- **A downed henchman** pays a little ki and counts toward nothing else (recommended for Orb): fodder 2, grunt 4, veteran 8, elite 15.

**Orb** (co-op answers, `docs/ep/vision.md`): "there's got to be weaker grade opponents, ideally various grades of henchmen created with procedural body parts to create lots of variety". Homework 41 puts them in the campaign's *horde* stage: waves of graded henchmen.

**This builds on:**
- Research's sketch (`docs/research/co-op-brawler-part-2.md` §B and §C): the scuffle rule, the light body and the sim's blindness to parts.
- Encounter's partner and ring (`docs/director/one-v-many.md`, as ruled in `docs/design/empress-guards.md` §5).
- The guard kit row (`pending/roster/moveset.guard.json`, generator v21).
- The recoil exits and ricochets, which are built (`data/anim/recoil.json`).
- The grapple (`docs/design/grapple.md`), the throwables ruling (`docs/design/rule-of-cool.md`) and the launch enders (`launch-enders.md`).

**No new lore or names.** "Fodder", "grunt", "veteran" and "elite" are design labels, and so are the three grunt types (Orb's bruiser, marksman and speedster). A henchman has no name, no insignia and no story. His palette and kit come from the stage's boss, whose world is Orb's to write.

## 1. The grades at a glance

| | **0 Fodder** | **1 Grunt** | **2 Veteran** | **3 Elite** |
| :--- | :--- | :--- | :--- | :--- |
| **The sim's body** | The light body | The light body with a type | The light body with armour | The full fighter |
| **The rule** | Scuffle | Scuffle | Scuffle | A full brawl, as the partner |
| **His blow** | One lunging light | One blow by type | One armoured heavy | His generated kit, plus **one trick** |
| **What it does to a player** | A 6-tick flinch | A flinch, or a skip of 1 bh | A handspring of 2 bh | The brawl's rules |
| **Toughness**, in light blows | 1 | 4 | 8, with the first 2 lights shrugged | 40% of a roster fighter's health; wounds at half rate; no brink |
| **The turns he takes** (§3) | 1 | 1 | 2 | 2 (both) |
| **In a wave** | Many: the flow | Most: the texture | One or two: a wall to break | At most one at a time: the event |

**How this numbers against Research's table:**
- Fodder and grunt are Research's grades 0 and 1.
- **The veteran is new.** He is a scuffle body with armour, so a wave can have a wall to break without paying for a full fighter.
- My elite is Research's grade 2.
- Research's lieutenants and bosses sit above the horde, in the gauntlet and boss stages, and are unchanged.

**Why the elite has no brink:** a finisher and its struggle pause the whole sim. That would freeze the horde and the other player (Research's open question 3). Finishers stay with lieutenants and bosses. An elite falls at zero to an ordinary blow.

## 2. Each grade in a horde stage

Every tell is body language and sound, never a marker over a fighter (ADR 0010). Every henchman's blow can be guarded and perfect-blocked like any blow. Damage is in percent of the player's health. All numbers are first values for Game Design to rule.

### Fodder

- **His blow:** a lunging light from up to 1.5 bh, a common light from the guard kit's X cell. The wind-up is 14 ticks: a step and a cocked arm.
- **When it lands:** 1.5% damage and a 6-tick flinch. The flinch cancels the player's blow in flight but never holds his next press.
- **Guarded:** he rebounds for 4 ticks.
- **Perfect-blocked:** he drops.
- **When struck,** anything drops him:
  - a light drops him where he stands;
  - a medium sends him 1 bh and drops him;
  - a heavy sends him 3 bh;
  - a launcher sends him up, and he drops on landing.
- **No recoil exit.** He tumbles and is down.
- **In the wave:** many of him, so that clearing is pure flow (§4).

### Grunt: the three types

| | **Bruiser** | **Marksman** | **Speedster** |
| :--- | :--- | :--- | :--- |
| **His blow** | A body-blow medium from the guard kit's Y cell | The guard kit's bolt (`bm.guard_bolt`) from 6 to 10 bh | A dashing light from up to 4 bh: the zip into a common light |
| **His tell** | Both arms back, 18 ticks | The arm raised and held still, 16 ticks | A crouch and a lean, 12 ticks |
| **When it lands** | 3%; the player's skip (1 bh, 10 ticks) | 2%; a 6-tick flinch | 1.5%; an 8-tick flinch |
| **His defence** | Guards from the front. Lights to his front are blocked after the first. A medium, a throw, a blow from behind or the partner's blow breaks the guard | Backs off to keep 6 bh. When closed on he backs away; he never strikes in melee | Sidesteps the first light of a string, at most once in 2 s. The second blow, or any medium, catches him |
| **A perfect block of his blow** | Staggers him for 20 ticks | Deflects the bolt as any perfect block of a bolt does | Staggers him for 20 ticks, behind the player when the dash has passed |
| **Rate** | His turn | One shot in 4 s. On one player, the marksmen share a single turn | His turn |

**When a grunt is struck:**

| Blow | Reaction |
| :--- | :--- |
| Light | A flinch. The third light in a string staggers him |
| Medium | A stagger and a knock-back of 1 bh: the built `skip` |
| Heavy | Sent 3 bh: the built `tuck` |
| Launcher | Launched as a real body (§4) |

### Veteran

- **His blow:** one heavy, the guard pack's heavy (`guard1`).
- **The wind-up:** 24 ticks with the weight thrown back. He is armoured through it: lights don't stop it, while a medium or anything heavier staggers him and breaks the armour.
- **When it lands:** 6% and the player's handspring (2 bh, 18 ticks). **He never launches a player.**
- **Guarded:** it pushes the guard back 1 bh.
- **Perfect-blocked:** the armour breaks and he staggers for 30 ticks, a clear invitation.
- **His armour:** he shrugs off the first 2 lights in any 2 s with no flinch. A medium, a heavy, a throw or a perfect block breaks the armour for 3 s.
- **When struck,** with the armour broken:
  - a medium staggers him;
  - a heavy sends him 3 bh with the built `handspring`;
  - a launcher launches him.
- **In the wave:** one or two. He is the wall that teaches the player to use a heavy, a throw or a perfect block.

### Elite

- **His body and rule:** the full fighter in a full brawl, as the player's partner under Encounter's partner-and-ring rules. Every rule of the brawl applies: exits, clashes, the clinch, wounds at half rate.
- **His kit:** the guard row's generated kit (common lights and mediums, one heavy, a bolt). Later, a generator row per elite can draw his own kit from the same posed pieces by seed.
- **One trick each.** Every elite has exactly one trick, and his silhouette tells which (§5). **The trick is a type picked for each spawn:** never kept, never named, with no memory, so no elite is a generated individual with traits or a history (Game Design 2026-10-25 item 10; Legal mc01). Each trick is built from a piece we already have:

| Trick | What he does | His tell | The answer | What it is built from |
| :--- | :--- | :--- | :--- | :--- |
| **The counter-catch** | Perfect-blocks a light and turns it into a catch and an across throw (8 bh) | An open-handed guard held for its 20-tick window | A medium, a heavy or a throw. Lights into the open guard get caught | The grapple's catch and throws (Animation's clinch C0, C1 and the eight throws, on main) |
| **The wall return** | When sent at a surface, he plants and comes back with a rebound blow | The plant, 10 ticks | Perfect-block the rebound and he staggers | The ricochet with its counter (`choreography-feel.md` §2; built kind `ricochet_wall`) |
| **The meet** | He meets the player's heavy with his own: a B clash meet, both thrown into backflips. He strikes first out of his landing | He winds up only when the player winds up a heavy | Strings and throws; don't open with a heavy | The clash meet (`choreography-feel.md` §3) |
| **The thrown henchman** | Picks a fodder or a grunt out of the ring and throws him at the player | The light lift, 16 ticks | A perfect block catches the body, and the player can throw it back worth a quarter more | The throwables ruling: a henchman is mass 1. It waits on the throwables' lift poses |
| **The car** | Lifts a car (tier 1, mass 4 at most) and throws it | The heavy lift, 24 ticks or more | A perfect block catches it within the player's tier and swats it above | The throwables ruling. Only where cars stand; it waits on the lift poses |
| **The blitz** | When he becomes the partner, he opens by zipping in from up to 8 bh with his heavy | A 20-tick crouch, the aura flaring on his body | Guard the opener, or perfect-block it for a punish | The zip and his heavy. The ring never closes, so the blitz is his entrance as partner, not a ring blow |

- **In the wave:** at most one engaged at a time, since the sim has one exchange (Research §B). A second elite waits in the ring and holds no turn until the first falls or the ring's tag rule brings him in.

## 3. Attack turns: one or two at a time

**A henchman must hold one of a player's turns to wind up a blow at him.** The rest of the wave is the ring.

| Rule | Value |
| :--- | :--- |
| **Turns a player** | 2 at medium and hard; 1 at easy. Tells never shorten with the level, so that the crowd stays readable |
| **The weight of a turn** | Fodder and grunts 1, so two of them can strike together. A veteran or an elite takes both, so when he is on you nobody else strikes |
| **Spacing** | Two holders' contacts never fall within 8 ticks of each other. That is the hard row of one-versus-many: no player is hit by two bodies within 8 ticks. The second holder's wind-up starts late or holds its last ticks |
| **Who gets the turn** | From the henchmen in reach (or marksmen in line), in order: inside the player's view and in front of him; then whoever has waited longest; then the lower grade first, so fodder keep the pace and veterans come as events |
| **Never** | From outside the player's pane. From behind only with a wind-up of at least 20 ticks and its own sound (Audio) |
| **Losing the turn** | His contact (a hit, a guard or a miss); being struck (any flinch drops it); being sent; or holding it for 3 s without winding up |
| **The gap** | A released turn passes after 20 ticks: easy 30, hard 12. That is the crowd's rhythm |
| **The ring** | Holds 2 to 4 bh, circling, also in depth. One feint (a step in and back) every 1.5 s across the ring. Fodder posture. Marksmen keep 6 to 10 bh. No ring body strikes without a turn |
| **An elite as partner** | He holds both turns. The ring may add only Encounter's interjections: a light or a medium, never a heavy, a launcher or a grab, with a wind-up in sight for at least 8 ticks, at most one in 1.5 s, never within 8 ticks of his contact |
| **Co-op** | Turns are a player's own, and a henchman holds at most one player's turn. Two players side by side face at most four strikers, two each. A player who strikes a henchman holding his partner's turn frees that turn: the help is felt |

## 4. How a player's moves read against them

**Targeting.** This is Research's rule, with one addition: **the string travels.**
- A press goes to the nearest henchman in reach, or with the stick to the nearest one in the stick's direction.
- Out of reach, the press becomes a lunge or a zip (never out of range).
- **The addition:** when a struck body drops, the next press with no stick goes to the next body within 1.5 bh, in front first, with a short step to it. A light string through five fodder reads as one flowing sweep, without aiming.

**Each path reads differently against a crowd.** This uses the paths the launch enders use, so every blow a fighter already has gets a crowd reading:

| Path | Against a crowd |
| :--- | :--- |
| **Line** | The struck body is sent along the line and bowls over what stands behind it |
| **Rise** | Launches one, aimed by the stick through the launch enders. Where he lands, fodder within 1 bh are knocked down |
| **Drop** | Flattens one. The shock knocks down fodder within 1 bh |
| **Arc in, arc out** | Sweeps that side: every scuffle body in reach on that side, up to 3 |
| **Spin** | All round in reach, up to 4, each knocked back 1 bh |

- **Lights hit one body,** whatever their path. Lights stay one press, one body.
- **Mediums** read their path with a cap of 2.
- **Heavies and launchers** read it in full.

**Bodies meet bodies.**
- **The domino.** A sent body knocks down scuffle bodies of his grade or lower in his path: **up to 3 when a medium sent him, up to 5 when a heavy, a throw or a launch did** (Game Design 2026-10-25 item 5). A heavy through a packed line bowls the line. A higher grade stops him and is staggered.
- **The return.** A sent grunt or veteran below the wall slam's speed ricochets off a surface back toward the one who sent him, unarmed, landing in reach. The player can hit him again, at most twice in a row (the ricochet's limit). Fodder crumple at the wall. Above that speed it is a wall slam or the building chain, as ruled.
- **Power has weight.** A launched or sent henchman is a real body. He flies by the launch planner, ploughs into buildings by the brunt rules and craters the ground. A heavy through a line of grunts is collateral.
- **No friendly fire.** A body sent by one player never hurts a player.

**Each system of the brawl, against them:**

| | Fodder and grunts | Veteran | Elite |
| :--- | :--- | :--- | :--- |
| **The catch** (tap A) | Goes straight to a throw along the stick, with no clinch. The thrown body dominoes | The catch, 2 clinch pulses, then the throw. A throw beats his armour | The full clinch of `grapple.md` |
| **The carry** (held A) | The carried body knocks down what the carry meets; the carry's end slams him | As grunts | `grapple.md` |
| **Launch enders** | An aimed launch sends the body into a cluster, with the domino on landing | As grunts, once the armour is broken | As in any brawl |
| **In the air** | No pursuit exchange (there is no exchange). The player may zip to the airborne body and strike it once, which sends it again by that blow's path | As grunts | The pursuit, as in any brawl |
| **Thrown objects** | A car's path drops fodder and launches grunts | A car staggers him and breaks the armour | As in any brawl |
| **Bolts** | Drop fodder; flinch grunts | Chip, no flinch | As in any brawl |
| **The signature beam** | Drops every fodder and grunt on its path | Launches him | An elite's kit has no beam, so no struggle arises; one that ever has a beam struggles like anyone (item 14) |
| **Powering up on the ground** | The crater knocks down fodder within its radius | No effect | No effect |
| **The perfect block** | Drops fodder; staggers a grunt for 20 ticks | Breaks the armour; staggers him for 30 ticks | As in any brawl |

- **The co-op relay.** A body one player sent can be struck in flight by the other, which sends it again by his blow's path. **There is no cap** (item 8): the body's toughness ends a relay, and two players juggling a grunt between them pays for itself.
- **The weight of a hit, with no sim-wide hit-stop.**
  - The struck henchman alone holds, on his own timer, while everything else runs: 3 ticks for a light, 5 for a medium, 7 for a heavy. This is E102's one-body hold (`energy-overhaul.md`), one mechanism for both, and it doesn't count toward the freeze budget (item 11).
  - A sweep that hits three bodies holds each in turn, a tick apart, so that the blow reads as passing through them.
  - The striker does not hold in the sim. Rendering may hold his pose at contact for a frame or two, reading the sim's contact tick and writing nothing.
- **Downed bodies are never faded or dissolved** (Orb, ADR 0010).
  - A downed fodder ragdolls and lies there.
  - A downed grunt or veteran may instead get up and limp out of the fight.
  - A body is removed only out of view. When there are too many, the oldest out of view goes first, under Performance's cap.

**What "satisfying to clear" asks.** These are bands for QA to measure later:
- A wave of 12 fodder falls to one medium-skill player (the AI as player) in 10 to 20 s.
- **The horde's damage band** (item 2): a medium player loses 10 to 30% of his health over a horde stage in columns 1 and 2, and 20 to 45% by column 4. If it runs over, the levers are the turn's gap first, then the blow's damage.
- In a minute of a mixed wave, at least four kinds of body meeting happen: the domino, the sweep, the landing, the return, the relay and the throw.
- Two hard tests:
  - no player is hit by two bodies within 8 ticks;
  - no player is struck by more than his turns allow.

## 5. Bodies from parts: the data, silhouettes only

**The rules,** from Research §C, kept:
- **One shared rig (R1, 27 bones)** for every henchman, so that every posed piece works on him. **No new poses for henchmen:** every henchman blow above comes from a posed piece or a built kind.
- **Bone lengths are R1's, never changed.** Only the parts' girth and their shells vary, so that the shared poses, the reach table and the contact solve still land.
- **The size class** scales the whole body evenly: small 0.9, standard 1.0, large 1.15. The sim knows the class and scales reach and the hurt box with it.
- **The sim is blind to parts.** It reads a grade, a type, a size class and a trick, never the parts. The body seed is the spawn's id, read from the sim and never hashed, so a replay draws the same bodies and variety costs no determinism.
- **The dependency runs one way.** The grunt type and the elite's trick are sim data. The body generator reads them to place the part that tells them. Nothing in the sim reads a part.

**The sim's side** (Game Design's numbers; Encounter's build; a `data/combat/` file in an EP window). Its shape:

```json
{
  "schema": "combat.henchmen/1",
  "grades": {
    "fodder":  {"grade": 0, "body": "light", "rule": "scuffle", "turnWeight": 1, "tough": 1, "armour": 0,
                "sizes": ["small", "standard"],
                "blow": {"from": "guard.martial.x", "reachBh": 1.5, "windup": 14, "dmg": 1.5, "onPlayer": "flinch", "ticks": 6},
                "struck": {"light": "drop", "medium": "drop_sent_1", "heavy": "drop_sent_3", "launch": "launch_then_drop"},
                "perfect": "drop"},
    "grunt":   {"grade": 1, "body": "light", "rule": "scuffle", "turnWeight": 1, "tough": 4,
                "types": {
                  "bruiser":   {"blow": {"from": "guard.martial.y", "windup": 18, "dmg": 3, "onPlayer": "skip"}, "defence": "front_guard"},
                  "marksman":  {"blow": {"from": "bm.guard_bolt", "rangeBh": [6, 10], "windup": 16, "dmg": 2, "onPlayer": "flinch", "ticks": 6, "everyS": 4}, "defence": "keep_range"},
                  "speedster": {"blow": {"from": "zip+guard.martial.x", "reachBh": 4, "windup": 12, "dmg": 1.5, "onPlayer": "flinch", "ticks": 8}, "defence": "sidestep_first"}},
                "struck": {"light": "flinch", "lightThird": "stagger", "medium": "skip", "heavy": "tuck", "launch": "launch"},
                "perfect": {"stagger": 20}},
    "veteran": {"grade": 2, "body": "light", "rule": "scuffle", "turnWeight": 2, "tough": 8,
                "armour": {"shrugLights": 2, "inS": 2, "brokenS": 3, "breakers": ["medium", "heavy", "throw", "perfect"]},
                "sizes": ["large"],
                "blow": {"from": "guard1.heavy", "windup": 24, "armoured": true, "dmg": 6, "onPlayer": "handspring"},
                "struck": {"medium": "stagger", "heavy": "handspring", "launch": "launch"},
                "perfect": {"stagger": 30, "armour": "broken"}},
    "elite":   {"grade": 3, "body": "fighter", "rule": "brawl", "turnWeight": 2, "health": 0.4, "wounds": 0.5, "brink": false,
                "kit": "guard", "trickOne": ["counter_catch", "wall_return", "meet", "thrown_henchman", "car", "blitz"],
                "_trick": "a type picked for each spawn: never kept, never named, no memory (Game Design 2026-10-25 item 10; Legal mc01)"}
  },
  "turns": {"perPlayer": {"easy": 1, "medium": 2, "hard": 2}, "gapTicks": {"easy": 30, "medium": 20, "hard": 12},
            "spacingTicks": 8, "holdMaxS": 3, "behindWindupMin": 20,
            "order": ["in_view_front", "waited_longest", "lower_grade"]},
  "crowd": {"hop": {"bh": 1.5},
            "paths": {"line": "bowl", "rise": "launch_land_splash", "drop": "shock", "arc_in": "sweep", "arc_out": "sweep", "spin": "all_round"},
            "caps": {"light": 1, "medium": 2, "sweep": 3, "spin": 4, "splashBh": 1},
            "domino": {"capMedium": 3, "capHeavy": 5, "_heavy": "a heavy, a throw or a launch", "grades": "same_or_lower"}, "return": {"inARow": 2}, "relay": {"perBody": null, "_relay": "no cap: toughness ends it"}},
  "hold": {"light": 3, "medium": 5, "heavy": 7, "_hold": "E102's one-body hold; not counted toward the freeze budget"},
  "kiOnDown": {"fodder": 2, "grunt": 4, "veteran": 8, "elite": 15, "_ki": "recommended for Orb; no score, meter or other reward (c08, mc01)"},
  "qa": {"damageOverStage": {"columns1and2": [0.10, 0.30], "column4": [0.20, 0.45]}, "fodderWave12Sec": [10, 20]}
}
```

**The body's side** (render only, never hashed; Animation's and Art's to own). Each shape is a girth curve over R1's part row (`render/anim/anim_rig.gd` `_parts`), with an optional shell on the same bone. Silhouettes only, for now:

```json
{
  "schema": "anim.henchmen_parts/1",
  "rig": "R1",
  "rules": {"boneLengths": "R1", "girth": [0.8, 1.4], "size": {"small": 0.9, "standard": 1.0, "large": 1.15},
            "seed": "spawn id, read from the sim", "faceCover": false},
  "regions": {
    "head":      ["round", "flat_top", "crest", "hood", "cropped"],
    "torso":     ["barrel", "column", "tapered", "stooped"],
    "shoulders": ["bare", "pad", "high_pad", "yoke"],
    "arms":      ["lean", "thick", "long_forearm"],
    "hands":     ["bare", "wrapped", "big"],
    "legs":      ["lean", "thick", "long_shin"],
    "feet":      ["low", "boot", "heavy_boot"],
    "back":      ["none", "pack", "tall_pack"],
    "hang":      ["none", "sash", "tabard"]
  },
  "byGrade": {
    "fodder":  {"shells": 0, "girthMax": 1.0},
    "grunt":   {"shells": [0, 1]},
    "veteran": {"shells": [1, 2], "girthMin": 1.15},
    "elite":   {"shells": 2, "oneSided": true}
  },
  "telling": {
    "bruiser":   {"shoulders": ["pad", "yoke"], "arms": ["thick"]},
    "marksman":  {"arms": ["long_forearm"], "back": ["tall_pack"]},
    "speedster": {"legs": ["lean", "long_shin"], "torso": ["tapered"]},
    "trick.counter_catch":   {"hands": ["big"]},
    "trick.wall_return":     {"feet": ["heavy_boot"], "legs": ["long_shin"]},
    "trick.meet":            {"shoulders": ["high_pad"]},
    "trick.thrown_henchman": {"back": ["pack"], "torso": ["barrel"]},
    "trick.car":             {"shoulders": ["yoke"], "legs": ["thick"]},
    "trick.blitz":           {"legs": ["long_shin"], "back": ["none"]}
  },
  "palette": "the stage boss's kit, Art's",
  "variety": {"noTwins": ["head", "torso"], "windowSpawns": 6}
}
```

**Variety.** Nine regions give 5 × 4 × 4 × 3 × 3 × 3 × 3 × 3 × 3 = **58,320 bodies before girth, size and palette.** A grade's rules and the telling parts narrow that, by design.

**The silhouette rules:**
1. **The grade reads from the silhouette alone:**
   - fodder are small or standard, narrow and plain, with no shells;
   - grunts read by their type's telling part;
   - veterans are large and broad, top-heavy with shells;
   - an elite is standard or large, with **one one-sided telling part** (one big shoulder, one long arm) that names his trick.
2. **Henchmen don't share a roster fighter's shape language.** The four in `data/anim/shapes.json` are taken. Art picks a fifth for henchmen. The silhouette lint measures each generated body against the roster's, so the players' fighters always stand out.
3. **No masks or visors** (Art's direction: masks are parked for a future fighter). Faces are bare, or shaded by a hood's brim. No emblems or insignia.
4. **A review sheet per seed,** 64 bodies a grade, through the silhouette lint and Legal's screen.
5. **Neighbours differ.** No two bodies within six spawns share a head and a torso.
6. **Fodder stay cheap.** No shells and narrow girth keep their meshes light. That is Research's cheap path, and its cost is Performance's first measurement for the stage.

## 6. For others

- **Game Design:** ruled (2026-10-25), as above.
- **Encounter:** the scuffle bodies; the turns (its partner and ring, extended to many light bodies); the travelling string's hop; the crowd readings by path; the domino, the return and the relay.
- **Simulation:** the light body (position, health, a few timers, grade, type, size class, trick), hashed. The spawn id doubles as the body seed.
- **Animation:**
  - the scuffle reactions (flinch, stagger, drop, tumble) from existing pieces and the ragdoll;
  - whether the even size scale keeps the contact solve true;
  - the parts file in its own paths;
  - the lift poses that two of the tricks wait on.
- **Art:** the part shapes as silhouettes, the fifth shape language, palettes from the boss's kit, and the review sheet.
- **Legal:** the screen on the generated sheet. Generic soldier and henchman looks are the risk to watch.
- **Camera:** each pane frames its player and his turn holders.
- **Audio:** the sound of a wind-up from behind.
- **Performance:** the render cost of a wave (Research §C).
- **Orb** (with Game Design's recommendations, 2026-10-25):
  - an elite's brawl and the horde: every hit-stop a one-body hold in a stage with a second player or a horde, so nothing freezes the other player (item 12);
  - a downed henchman: a little ki (fodder 2, grunt 4, veteran 8, elite 15) and nothing else (item 13).
