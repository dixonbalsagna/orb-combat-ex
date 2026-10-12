# The beat, the nine cells and depth, by ear

Owner: Audio and Music. 2026-10-12. Answers the EP's brief on Orb's direction (`docs/design/brawl-second-pass.md` §15 the nine cells, §16 the perfect follow-up). Paper first; what needs no new cue is built and checked. Every number here is a first value, and each is data in `audio/data/beat_cues.json` (a file of its own, so `brawl_cues.json` keeps its schema until Tools adds one for this) or a recipe in `audio/data/impacts.json`.

**To hear it:** `audio/preview/perfect-chain.wav` (8.3 s, over the 180 BPM reference loop): a chain of three lights that closes with the ping and the launch; a chain that breaks and the string going on; a link (a medium, then a heavy that closes); and the opponent's chain heard from the player's side. It is made from staged events by the real mapper (`render_brawl_demo.gd --scene=perfect`). Encounter's pass 3 cues do not exist yet, so everything under 1 is **built and dormant**: it sounds the day the cues are sent.

## What is built, staged, or waits

| | State |
| :--- | :--- |
| Held X settling; the mashed Y's grind; the Y's charge hum and brighter full tick; launcher rest knock; the lite knock (earlier) | Built. Held X and the grind run on today's cues (`burst`, `blow`). The Y's charge and the rest are built against the shapes below |
| The perfect: tick, spark, note, close, link shimmer, droop, the opponent's colour | Built against **proposed** cue names (§5); dormant until Encounter sends them |
| Depth (§4) | Paper only |
| Checks | `brawl_check` groups 9 and 10, `beat_check` (the numbers below), `cue_sweep` (§3) |

## 1. The beat

### 1.1 The hit is the cue: what says "now", and how long it rings against the window

A window is 8, 10 or 12 ticks (133, 167, 200 ms) and **opens on the hit**, ending 5, 6 and 8 ticks after it (83, 100, 133 ms). What the ear uses as "now" is the **transient**: every impact starts with a 0.2 ms-attack noise burst that is the loudest 10 ms of the sound, followed by a body. The player taps on the transient; the body is the weight.

Measured (`beat_check`, mean of the four variants), the level still sounding at the moment its window closes, under the hit's loudest 10 ms:

| Hit | Window ends at | Still sounding then | Down 20 dB by |
| :--- | ---: | ---: | ---: |
| Light, and the lite knock | 83 ms | -36 dB, and gone | 54 ms and 28 ms |
| Medium (and its grind) | 100 ms | -13 dB | 134 ms |
| Heavy | 133 ms | **-7 dB** | 230 ms |
| Guard | 100 ms | -36 dB | 65 ms |

- **The light ends with its window.** That is the quickest hit with the tightest window, and the ear hears the knock stop as the chance goes.
- **The medium rings a little past its window and the heavy a good deal.** The heavy is the case to watch. Its tail is its weight, and every hit opens a window, so there is no "window-free" heavy to keep it for. I would **not** shorten it on paper. If playtests show late taps on heavies, the lever is data: the heavy's low tone `t60` down by a quarter (so it is -15 dB at its window's end). It costs weight, so it waits for a playtest.
- **Nothing marks the end of a window.** A closing sound is a buzzer in the making. The chain-broken droop (1.5) answers a miss, and only a chain that had something.

### 1.2 A plain light has no hit to tap on: a tick

A light lands 2 ticks after its press, sooner than a hand can press again, so its window opens as its pose lets go, 6 ticks later (§16). That is the one window with no sound on its start, so it gets a **tick**: a dry 13 ms click at 3.2 kHz, quiet (-20 dB peak), only for the attacker's side (the opponent's pose-release is not the player's to use). Cue: `window_open` with `k` 1.

### 1.3 The spark: the tap's confirmation

A perfect follow-up lands 6, 10 or 14 ticks after the tap, which is 100 to 230 ms: too long to wait for the answer to "did I get it?". So a **spark** sounds at the tap: a pitched 35 ms tick at the chain's next note, -20 dB peak, a bright "tsk" and no body.

**It has to wait for the hit's transient.** Measured, a spark played on the hit's own first millisecond is **4 dB under** the hit in its band; 17 ms later it is +5 dB over it, 33 ms later +17 dB. The best taps, the ones on the hit, would get the least confirmation. So the spark never starts inside the hit's first 2 ticks (33 ms): if the tap is on the hit it waits until the hit is 2 ticks old (the last hit that landed, or one due in the next 3 ticks), up to 6 ticks of wait. A tap 6 ticks after the hit sounds at once. This is mapper logic, not a new cue.

For the defender the spark is a **tell**: it comes 100 to 230 ms before the follow-up's hit. An AI's perfect is a spark the player can hear and answer with a perfect block (§16's "timing answers timing").

### 1.4 The note: on the follow-up's own hit, stepping up

On the follow-up's hit, riding on its impact (the hit itself is unchanged), **a note**:

| Count after this perfect (`k`) | Note | Why |
| ---: | :--- | :--- |
| 1 | G#6 (1652 Hz) | "so" |
| 2 | A#6 (+2 semitones) | "la" |
| 3 or more | **the close**: C#7 (2200 Hz) with C#5 and the fifth above, 0.3 s, a short sparkle | "do": it resolves, and it is the **octave of the launcher's ping** (1100 Hz) |

- **A resolved phrase to the ping.** The close sounds on the same tick as the opening's ping, which is C#6, and the chord omits its own C#6 so the ping is not doubled. The listener hears so-la-do, then the ping underneath: "go now". The intervals are relative to the ping, which is the one fixed sound of the brawl, so **nothing depends on the music's key or tempo**: the window follows hits, not bars.
- **Colour by the follow-up's strength:** a light is a bright pluck (0.10 s); a medium adds a body an octave down (0.13 s); a heavy adds two (0.17 s). All sit in the same register so the step is heard whatever the mix of strengths.
- **A link** (a follow-up of another strength than the blow that landed; the chain adds 2) adds a glassy shimmer (inharmonic partials at 2.76 and 3.69 times the note, 0.14 s). A link therefore steps two notes and says so in colour: the ear hears "that was a different move".
- **The close** is the third (or a link that brings the count to 3 or more).

Measured on the hits (`beat_check`): the notes sit 7 to 8 dB under the hit's peak (light 7, medium 7, heavy 8), so they colour a hit and never lead it. In their own band they are over the hit's energy from its first millisecond: +3, +6 and +5 dB (light, medium, heavy), rising to +6 to +13 dB at 17 ms and +9 to +37 dB at 50 ms as the impact decays. Over the first 60 ms as a whole the hit leads its note by 11 to 15 dB.

### 1.5 A broken chain: quiet, not a buzzer; the string goes on

When a window passes with no tap, or a blow stops a follow-up, or it is blocked, there is **one droop**: a 90 ms tone that slides down a minor third from the last note, **at least 17 dB under a light hit**. It is silent for a lapse after 90 ticks (nothing happened to him) and for a count of nothing (a masher has no chain to lose, so he is never punished by sound). The next plain light is an ordinary light: the string goes on.

### 1.6 The opponent's chain must not sound like mine

- **Colour:** the AI's perfect against a human is a **reed** (many upper harmonics, a detuned pair that beats): nasal and a little edgy beside the player's clean pluck.
- **Harmony:** it steps G#6, B6 (a minor third) and **closes on a diminished stack** (G#, B, D) that wants to resolve. The player's own chain resolves to C#. So one resolves and one threatens, whatever the timbre does through the speakers.
- **Who counts as the opponent:** the attacker is an AI and the victim is a human. Two humans share the player's colour (they are told apart by where they stand). Two AIs (a demo) share it too.
- **No tick for the opponent's window**, and the same spark, so its tell is as audible as the player's own.

### 1.7 Density, voices and masking

A perfect chain is a hit every 6 to 14 ticks. Per perfect the mapper adds at most: a spark (class cap 1), a note (cap 2), a link shimmer (cap 1), and on the close one chord (cap 1) beside the ping. A chain of three lights (hits 10 ticks apart) makes 7 information cues and 3 impacts in about half a second; all 7 got voices in the pool test, with the class caps (light 4, guard 3) unchanged. The worst case, mediums 6 ticks apart, stays under 10 of the 16 voices, and the information cues have priority 70 to 90 against the hits' 40 to 60, so they are never the ones dropped. They are on the `Alert` bus so the ping's duck takes neither them nor itself.

## 2. The nine cells by ear

| | Tapped | Mashed | Held |
| :--- | :--- | :--- | :--- |
| **X** | The tick for a plain light, the spark and notes for a perfect (1). The light is a short knock that ends with its window | **Climbs.** From the third blow in a second 2 dB down and +0.33 semitone a blow (to +3), from the fifth the lite knock: a rattle that builds toward the close, which is 3 dB louder. *Built* | **Settles.** The burst's gaps are 4, 4, 5, 6, 8, 11 ticks and then 10. The first blows are the lite rattle at the start's pitch; as the gap grows the full light takes over and the pitch **falls three semitones** (0.5 semitone for each tick over a 4-tick gap, to -3) and holds there at the floor pace. One move settling, opposite in direction to the mash's climb. It is the held X's *only* rule: if a held burst is replaced by another press it is a mash and climbs. *Built* |
| **Y** | A medium: a body of 0.3 s. A perfect medium has the stop's own bonus; its note has the medium colour. *Spark, note dormant* | **Grinds.** From the second medium in 48 ticks each is 1.5 dB down, 0.25 semitone lower (to -1.5) with a churning low layer under it (a 17 Hz wobble on a 260 Hz rumble). Mass, not speed: the sound of "the most damage a second". *Built* | **The charged medium.** A gather (the existing medium gather over its 16 ticks), then at the `charge` windup a **higher hum than the B's** (150 to 190 Hz, a faster tremolo), and at full a **brighter tick** (1760 Hz with an upper partial, no ring): "higher for Y than for B" as the plan said. The release cuts the hum. *Built on the B's shapes with source y; Encounter's pass 2 confirms* |
| **B** | The hammer: the heavy's gather, the launcher's ping when it is open. A perfect heavy has the deepest note | **The advance.** Heavy after heavy: each wind-up gather and its heavy hit; the class caps (heavy 3) keep it from piling. Armoured by lights, so the absorbed tick (a dull knock under the lights that do nothing) *is* the sound of walking through a masher. *Built* | **The big read.** The hum from tick 32 with a tremolo that speeds up, the lower click with a ring at 44, cut at the release, then the landing: a knock-back or a launch. *Built (C2)* |

**The launcher's rest.** The launcher rests for 40 s of fight time after a launch of him. The missing ping already says "not now"; a player who just heard a flurry close and **no ping** can think they missed it. So an opening that will not launch gets a **dull knock** where the ping would have been (180 to 120 Hz, 80 ms, -12 dB, no duck). A learner hears: ping, go; knock, wait. Cue: `launcher_rest` (proposed, §5). *Built, dormant.*

## 3. The staged-only cues, against real matches

`audio/tools/cue_sweep.gd` runs seeded matches through the real mapper and checks each rare cue's sound. 40 AI-vs-AI matches (seeds 100 to 139), then two presser runs (a human slot pressing every 8 ticks: light; every 12: heavy, against the AI):

| Cue | Seen | Result |
| :--- | ---: | :--- |
| `miss` (gave_ground, reach) | 28 in 40 AI matches, 4 in the Y masher's 16 | One `impact.whiff` for each, at the swinger: 32 of 32 |
| `double_hit` | 0 in 40 AI matches; **12 in 8 X-masher matches** (1.5 a match) | Each made one `double.charge` and **exactly one** `impact.double` at its landing: 12 of 12 (and 21 of 21 over 16 matches, counted by sound) |
| `energy_land` blast | 5 in 40 AI matches | One `energy.blast` each, its gather cut: 5 of 5 |
| `energy_reach` blast that never lands | 2 in the Y masher's matches (stopped) | Its 12-tick gather plays out and ends: harmless |
| `launcher_open` (12 ticks or more) | 115 in 40 AI matches; 201 and 439 in the pressers | One `ui.launcher` each: every one |
| `launcher_close` | 27 used, 86 lapsed in 40 matches | `used` cuts the ping, `lapsed` lets it ring |
| The Y's charge (`windup charge` source y, `charge_full` source y) | **0**: not in main yet | Built on the B's shape, so it waits for pass 2 |

Two things worth knowing. **Guard chips are the second most frequent cue** (about 110 a match, 4368 in the 40) and the lite knock is the commonest light in a mash (61%); neither crowds the mix (in the AI matches, light knocks ringing together: mean 1.2 to 1.3, never over 4). And **a mashed Y's mediums are 83% grind**, so the grind is the sound of that cell, as designed.

## 4. Depth, for information

**Should distance by depth change a sound? For the pair, no.** The camera dollies to the pair's depth, so whatever the fighters make is at the camera's own depth, and the existing rule (distance along the wrapped planet, by `sdx`) is all that is needed. Nothing in the pair's sounds changes when a fight drifts into the street behind. Events already carry `z` (`fight-lanes.md`), so the data is there if it is wanted.

What would change, **for sounds that are not the pair's**:

- **A building falling, a beam crossing the far street, a crowd, a crater two lanes back.** Distance in depth from the camera's focus (the pair's mean depth) should count as distance: a first value is **-1.5 dB for each body height past 3**, and a low-pass sliding from 8 kHz toward 3 kHz at 12 body heights, so a collapse in the back street is further away and duller than one in the street the fight is in. The planner would use `hypot(dx, dz)` where it uses `dx` now.
- **A launch down an avenue.** The launched body travels in depth for a second and more. Its whoosh should fall and darken as it recedes (about -7 dB and a low-pass over 1.2 s for a 10 body height flight) and its landing is a **distant thump**: 12 dB under the near equivalent, with the street's slap (below). Toward the camera is the reverse: louder and brighter, and the landing close. This is the one place depth does the work of a camera move.
- **Behind a tower.** When the sound is farther in depth than the pair and a standing building's box lies across the line (its footprint overlaps the sound's x, it is nearer to the camera, and it is taller than the sound's y), the sound is occluded: the existing muffled path (the `SfxMuffled` bus the water uses) at about -6 dB. The sim holds each building's `z`, `d` and footprint; it is a read.
- **A street is a canyon.** A big sound in a street (a heavy, a whump, a crater, a collapse) between two block rows has hard walls on both sides: a **slap-back** 60 to 90 ms later, -12 dB, high-passed. At a crossing (clear air) none, on the roofs none. World's `depthRoom` read says which.

None of this is built. It needs two reads (the camera's focus depth, and a building's footprint at depth) and nothing from the director. I would build it once the camera follows pairs in the streets so it can be heard in a real window, not before.

## 5. Cues I need from Encounter (pass 3), and what I use

| Cue | Fields I read | Notes |
| :--- | :--- | :--- |
| `window_open` | `actor` the hitter, `k` **1** for a plain light's pose-release window (the tick), 0 for a window on the hit | Everything else (text the landed blow's strength, `n` the close, `dur` the length) is welcome and unused. For an assist that widens windows I would add a tick before every window |
| `perfect` | `actor`; `text` the follow-up's strength (`light`, `medium`, `heavy`); `k` the chain's count with this perfect in it (a link adds 2); `n` the follow-up's landing tick; `source` **`link`** when it is another strength than the blow that landed | One cue per perfect, sent on the tap's tick |
| `chain_broken` | `actor`; `k` the count lost (1 to 4); `text` `missed`, `stopped`, `blocked`, `staggered` or `lapsed` | `lapsed` and `k` 0 are silent; `stopped` and `staggered` also cancel a note that is on its way |
| `launcher_rest` | `actor`, `target`, `text` the opening's kind | An opening of 12 ticks or more with no `launcher_open` because the launcher rests. Or `stagger` can carry `source` `rest`, if that is cheaper |
| `windup` text `charge` source `y`, `charge_full` source `y`, `blow` text `release` source `y` | As the B's | The charged medium (pass 2) |

What I do not need: a field for how early or late the tap was. If a later pass wants a "just" colour for a tap exactly on the hit, `perfect.amount` as the signed tick offset would carry it, and I would add a second sparkle.

On Simple and on phones, "the release is what is timed" changes nothing for sound: it keys off `perfect`, not a button.

## 6. Open

- The heavy's tail against its window (1.1) is the one number a playtest should judge.
- The notes are first values. The register (G#6 and above) was chosen over the octave below because the hit's body lives around 1.1 kHz and buried it; once Suno's music exists the notes should be listened to against it, and if the guitars sit there the whole set moves an octave.
- The perfect block's sound should answer in the same language (its windows are 8 and 10 today and are to align with these). I would let `chain_broken` `blocked` carry the droop and leave the block's own sound as it is.
- Pass 3b and 3c (the perfect medium's sure stop, the close and the broken guard) need nothing more from sound: the close is the same chord, a broken guard is the existing guard-break sound.
