# Move names: a vocabulary for generated moves (draft)

Owner: Narrative and Fighter Identity. Version 1, 2026-10-06. Orb chose "Narrative drafts, I edit in the voice lab" (`docs/ep/vision.md`, questionnaire 18). **Everything here is a draft for Orb's edit**, and it is kept **outside** `docs/narrative/voice-lab/` until Orb pulls it in. **The file Orb pulls into the voice lab is `docs/narrative/move-names-draft.csv`** (60 rows, the voice lab's eight columns, UTF-8 with a BOM). Nothing is wired: the names are not in any data file, and Combat's parked generator (`docs/combat/pending/movegen/`) is not changed.

Built from the real sheet: `parts.json` (limb, tip, path, target, weight, forms) and `review-sheet.md` (46 moves a fighter: 30 lights and 16 heavies, for the Protagonist and the rival). Every name below belongs to a move on that sheet.

## 1. What a name is for

- A **generated move** is one of the 46 a fighter has in the martial arts stance, built from a shape (limb, tip, path, target, weight). It has an id (`mv.rival.martial.x.07`) and needs a **name a player can read** wherever the move is shown: the recipe display (a setting), the training sandbox, the move list, and the debug feed.
- **It is never shouted.** Only a **signature** and a **finisher** are shouted (`rule-of-cool-narrative.md` section 2); generated moves are named, not called. So a generated name has no syllable rules and can be plain.
- **Player-facing text treats the player as the fighter**: the names say what the fighter does ("Jaw Hook"), never what a system did.

## 2. The pattern

**A name is a place and a tool: `Place Tool`**, in two words where it can be, and three where it must be. It reads like a gym floor, not a manual: concrete, a little dry, and the same voice for every fighter.

| Part | What it gives | Example |
|---|---|---|
| **Place** (the target) | Where it lands | Jaw, Gut, Rib, Head |
| **Tool** (the tip, with the path) | What lands, and how | Hook, Riser, Slab, Scoop, Round Kick |

*Jaw Scoop*, *Gut Riser*, *Arm Chop*, *Rib Slab*, *Head Sweep*. A tool already made of two words (a kick, an elbow, a knee) stands **alone**: *Short Elbow*, *Driving Knee*, *Side Kick*.

**Rules, in order:**

1. **Two words if it is unique** in that fighter's 46 moves: `Place Tool` (a hand tool with one word), or the tool alone (a compound tool).
2. **If it collides,** the next **synonym** of the tool is tried (the second is each fighter's own flavour; section 4).
3. **If it still collides,** the compound tool gains a place in front (*Leg Round Kick*, *Rib Short Elbow*), or the place takes its second word (*Belly*, *Crown*, *Thigh*).
4. **Last resort,** an adjective from the fighter's list (section 4). It was not needed on the real sheet.
5. **At most three words,** and about 18 characters, so it fits a recipe line.
6. **Unique within a fighter.** Two fighters may share a name only if they share the move and no flavour word splits it.
7. **The weight is not in the name.** Lights and heavies live in different cells, and a heavy takes its own, heavier tool word (*Hoist*, *Cleaver*, *Sledge*, *Anvil*, *Uppercut*).

## 3. The vocabulary, by part

### 3.1 Place (the target)

| Target | Words (the first is the default) |
|---|---|
| head | Head, Crown |
| jaw | Jaw, Chin |
| chest | Rib, Chest |
| gut | Gut, Belly |
| arm | Arm, Wing |
| legs | Leg, Thigh |
| shins | Shin, Shank |

(Never a throat, hair or tail: Legal's grab rules, row b07.)

### 3.2 Tool (the tip and the path)

One word for a hand tool, two for a kick, elbow, knee or shoulder. The first word is the light; a heavy has its own list where one is given.

| Tip | Path | Light | Heavy |
|---|---|---|---|
| fist | line | Straight, Drive | Ram, Pile |
| fist | arc in | Hook, Swing | Haymaker, Wallop |
| fist | arc out | Backfist, Swat | |
| fist | rise | Lift, Riser | Uppercut, Heave |
| fist | drop | Hammer, Maul | Sledge, Maul |
| blade | line | Dart, Spear | |
| blade | arc in | Sweep, Slice | Cleave, Scythe |
| blade | arc out | Fan, Flick | |
| blade | drop | Chop, Axe | Cleaver, Axe |
| palm | line | Push, Press | Shove, Slam |
| palm | rise | Scoop, Heave | Hoist, Heave |
| hand heel | drop | Mallet, Heel Hammer | |
| hand heel | arc out | Backhand, Flick | Smash, Backswing |
| plate | arc in | Plate Swing, Plate Hook | |
| plate | drop | Plate Slam, Slab | Anvil, Slab |
| foot ball | line | Front Kick, Toe Thrust | |
| foot ball | rise | Toe Lift, Toe Kick | |
| foot heel | line | Heel Push, Heel Drive | |
| foot heel | drop | Axe Kick, Heel Drop | Axe Kick, Heel Drop |
| foot heel | arc out | Hook Kick, Heel Hook | |
| foot heel | spin | Wheel Kick, Spin Heel | Wheel Kick, Spin Heel |
| foot instep | arc in | Round Kick, Snap Kick | Roundhouse, Round Kick |
| foot edge | line | Side Kick, Edge Thrust | |
| foot edge | arc out | Crescent, Edge Sweep | Crescent, Edge Sweep |
| foot sole | line | Shove, Boot | Shove, Boot |
| foot sole | drop | Stomp, Stamp | Stomp, Stamp |
| elbow | arc in | Short Elbow, Elbow Hook | |
| elbow | rise | Rising Elbow, Elbow Lift | |
| elbow | drop | Dropping Elbow, Elbow Fall | |
| elbow | spin | Spinning Elbow, Elbow Wheel | |
| knee | rise | Rising Knee, Knee Lift | |
| knee | line | Driving Knee, Knee Drive | |
| knee | arc in | Looping Knee, Knee Swing | |
| shoulder | line | Shoulder Check, Shoulder Ram | |
| head (brow) | line | Headbutt, Brow Ram | |

### 3.3 Weight and form

The sheet's forms are light, flurry, skill, juggle (lights) and heavy, held, ender, lift, break (heavies). **None of them is spelled in a name**: the cell says it. A heavy's weight shows in its heavier tool word, and *lift* and *break* show where the path says it (a rising heavy is a *Hoist* or an *Uppercut*, a dropping one a *Cleaver*, an *Anvil* or a *Stomp*). If Orb wants the form shown, a **prefix** would do it (*Full* or *Hard* for a plain heavy, *Breaker* for a guard break). I have not used one, because it lengthens every heavy.

### 3.4 Words that are never used

| Words | Why |
|---|---|
| *Final*, *Special*, *Spirit*, *Big Bang*, *Cannon* | Legal's banned patterns for names. |
| *Dragon*, *Thunder*, *Claw*, *Grip*, *Beckon*, *Blink*, *Vanish*, *Orb*, *Ball*, *Glow* | The shapes and franchise echoes Legal's rows b02 to b13 rule out; and *Ball* is the energy-ball ban, so a foot's ball is a *Toe*. |
| *Throat*, *Hair*, *Tail* | Banned targets (b07). |
| *Lance*, *Barrage*, *Keeper*, *Verdict*, *Wave*, *Display*, *Orders*, *Blow*, *Everything*, *Skyward* | Words already in a signature or a finisher (`finishers.md`, `rule-of-cool-narrative.md`). A generated move never borrows one. |

All 92 names generated for the two fighters (46 each) were checked against this list; none hits it, and every name is unique within its fighter.

## 4. Per-fighter flavour (the launch pair)

The two fighters share 20 of 46 shapes (43%). To keep one shape from getting one name in both mouths, **each fighter reads the synonyms from a different end**: the Protagonist takes the first word of a tool's list (a warmer, rounder word) and the rival takes the second (a harder, flatter one). Each of the 20 shapes the two fighters share gets a different name in each mouth, for instance *Short Elbow* and *Elbow Hook* (elbow point, arc in, to the jaw); *Driving Knee* and *Knee Drive* (knee cap, line, to the gut); *Rising Elbow* and *Elbow Lift* (elbow point, rise, to the jaw); *Shoulder Check* and *Shoulder Ram* (shoulder plate, line, to the chest). None keeps the same name.

| | The Protagonist | The rival |
|---|---|---|
| **Identity** | Palms, blade hands, arcs | Fists, plates, straight lines |
| **Voice of the names** | Open and easy: things that sweep, scoop, fan and push | Flat and heavy: things that ram, pile, stamp and slab |
| **Words he leans on** | Scoop, Sweep, Fan, Push, Dart, Backhand, Mallet, Hoist, Cleaver, Crescent | Riser, Slab, Maul, Ram, Pile, Stamp, Swat, Spear, Wallop, Boot |
| **His tips** | Palm, blade, heel of the hand | Fist, plate, blade on the lights |
| **Adjectives (last resort)** | Easy, Open, Wide, Short | Flat, Dead, Square, Hard |
| **Never** | Plate words (he has no plate) | Palm words (his split has no palm strike) |

The flavour sets are small on purpose, and meant for Orb to rework: a few words each way change every name.

## 5. Thirty names a fighter, from the real sheet

Twenty lights and ten heavies for each, taken evenly through the sheet so every limb, path and target shows. The rest of each fighter's 46 follow from the same rules, and can be generated on request. The "plain words" column is for Orb's reading; the `[...]` says whether Animation already has a pose.

### The Protagonist

| # | Move | Name | In plain words |
| ---: | :--- | :--- | :--- |
| 1 | `martial.x.01` | **Short Elbow** | A light: an elbow, swinging in, to the jaw (a flurry blow) [a pose exists] |
| 2 | `martial.x.02` | **Driving Knee** | A light: a knee, straight in, to the gut (a flurry blow) [a pose exists] |
| 3 | `martial.x.04` | **Shoulder Check** | A light: a shoulder, straight in, to the ribs (a flurry blow) [a pose exists] |
| 4 | `martial.x.05` | **Looping Knee** | A light: a knee, swinging in, to the leg (a flurry blow) [needs a new pose] |
| 5 | `martial.x.07` | **Round Kick** | A light: the instep, swinging in, to the shin (a skill strike) [a pose exists] |
| 6 | `martial.x.08` | **Leg Round Kick** | A light: the instep, swinging in, to the leg (a skill strike) [a pose exists] |
| 7 | `martial.x.10` | **Gut Hook Kick** | A light: the heel, swinging out, to the gut (a skill strike) [bent from a pose] |
| 8 | `martial.x.11` | **Head Backhand** | A light: the heel of the hand, swinging out, to the head (a skill strike) [a pose exists] |
| 9 | `martial.x.13` | **Head Dart** | A light: a blade hand, straight in, to the head (a flurry blow) [a pose exists] |
| 10 | `martial.x.14` | **Rib Push** | A light: an open palm, straight in, to the ribs (a flurry blow) [a pose exists] |
| 11 | `martial.x.16` | **Arm Chop** | A light: a blade hand, dropping, to the arm (a skill strike) [a pose exists] |
| 12 | `martial.x.17` | **Head Mallet** | A light: the heel of the hand, dropping, to the head (a skill strike) [a pose exists] |
| 13 | `martial.x.19` | **Jaw Scoop** | A light: an open palm, rising, to the jaw (a flurry blow) [needs a new pose] |
| 14 | `martial.x.20` | **Rib Round Kick** | A light: the instep, swinging in, to the ribs (a skill strike) [a pose exists] |
| 15 | `martial.x.22` | **Rib Chop** | A light: a blade hand, dropping, to the ribs (a skill strike) [bent from a pose] |
| 16 | `martial.x.23` | **Jaw Backhand** | A light: the heel of the hand, swinging out, to the jaw (a skill strike) [bent from a pose] |
| 17 | `martial.x.25` | **Arm Push** | A light: an open palm, straight in, to the arm (a flurry blow) [bent from a pose] |
| 18 | `martial.x.26` | **Jaw Sweep** | A light: a blade hand, swinging in, to the jaw (a flurry blow) [bent from a pose] |
| 19 | `martial.x.28` | **Arm Hammer** | A light: a closed fist, dropping, to the arm (a skill strike) [needs a new pose] |
| 20 | `martial.x.29` | **Rib Scoop** | A light: an open palm, rising, to the ribs (a flurry blow) [needs a new pose] |
| 21 | `martial.y.01` | **Jaw Hoist** | A heavy: an open palm, rising, to the jaw (lifts) [a pose exists] |
| 22 | `martial.y.02` | **Rising Knee** | A heavy: a knee, rising, to the gut (lifts) [a pose exists] |
| 23 | `martial.y.04` | **Head Cleaver** | A heavy: a blade hand, dropping, to the head (breaks guard) [a pose exists] |
| 24 | `martial.y.05` | **Axe Kick** | A heavy: the heel, dropping, to the ribs (breaks guard) [a pose exists] |
| 25 | `martial.y.07` | **Rib Shove** | A heavy: an open palm, straight in, to the ribs [a pose exists] |
| 26 | `martial.y.09` | **Chest Shove** | A heavy: the sole, straight in, to the ribs [a pose exists] |
| 27 | `martial.y.10` | **Head Cleave** | A heavy: a blade hand, swinging in, to the head [a pose exists] |
| 28 | `martial.y.12` | **Gut Cleave** | A heavy: a blade hand, swinging in, to the gut (lifts) [a pose exists] |
| 29 | `martial.y.13` | **Rib Short Elbow** | A heavy: an elbow, swinging in, to the ribs (breaks guard) [a pose exists] |
| 30 | `martial.y.15` | **Belly Crescent** | A heavy: the edge of the foot, swinging out, to the gut (lifts) [bent from a pose] |

### The rival

| # | Move | Name | In plain words |
| ---: | :--- | :--- | :--- |
| 1 | `martial.x.01` | **Knee Drive** | A light: a knee, straight in, to the gut (a flurry blow) [a pose exists] |
| 2 | `martial.x.02` | **Elbow Lift** | A light: an elbow, rising, to the jaw (a flurry blow) [a pose exists] |
| 3 | `martial.x.04` | **Elbow Hook** | A light: an elbow, swinging in, to the jaw (a flurry blow) [a pose exists] |
| 4 | `martial.x.05` | **Elbow Fall** | A light: an elbow, dropping, to the ribs (a skill strike) [needs a new pose] |
| 5 | `martial.x.07` | **Snap Kick** | A light: the instep, swinging in, to the shin (a skill strike) [a pose exists] |
| 6 | `martial.x.08` | **Edge Thrust** | A light: the edge of the foot, straight in, to the ribs (a skill strike) [a pose exists] |
| 7 | `martial.x.10` | **Rib Snap Kick** | A light: the instep, swinging in, to the ribs (a skill strike) [a pose exists] |
| 8 | `martial.x.11` | **Head Spear** | A light: a blade hand, straight in, to the head (a flurry blow) [a pose exists] |
| 9 | `martial.x.13` | **Gut Spear** | A light: a blade hand, straight in, to the gut (a flurry blow) [a pose exists] |
| 10 | `martial.x.14` | **Plate Swing** | A light: a forearm plate, swinging in, to the head (a flurry blow) [a pose exists] |
| 11 | `martial.x.16` | **Arm Slab** | A light: a forearm plate, dropping, to the arm (a skill strike) [needs a new pose] |
| 12 | `martial.x.17` | **Head Maul** | A light: a closed fist, dropping, to the head (a skill strike) [needs a new pose] |
| 13 | `martial.x.19` | **Rib Spear** | A light: a blade hand, straight in, to the ribs (a flurry blow) [a pose exists] |
| 14 | `martial.x.20` | **Jaw Flick** | A light: the heel of the hand, swinging out, to the jaw (a skill strike) [bent from a pose] |
| 15 | `martial.x.22` | **Arm Axe** | A light: a blade hand, dropping, to the arm (a skill strike) [needs a new pose] |
| 16 | `martial.x.23` | **Jaw Plate Swing** | A light: a forearm plate, swinging in, to the jaw (a flurry blow) [bent from a pose] |
| 17 | `martial.x.25` | **Arm Swat** | A light: a closed fist, swinging out, to the arm (a skill strike) [needs a new pose] |
| 18 | `martial.x.26` | **Rib Slab** | A light: a forearm plate, dropping, to the ribs (a skill strike) [needs a new pose] |
| 19 | `martial.x.28` | **Gut Riser** | A light: a closed fist, rising, to the gut (a flurry blow) [needs a new pose] |
| 20 | `martial.x.29` | **Head Slab** | A light: a forearm plate, dropping, to the head (a skill strike) [needs a new pose] |
| 21 | `martial.y.01` | **Jaw Heave** | A heavy: a closed fist, rising, to the jaw (lifts) [a pose exists] |
| 22 | `martial.y.02` | **Gut Knee Lift** | A heavy: a knee, rising, to the gut (lifts) [a pose exists] |
| 23 | `martial.y.04` | **Crown Slab** | A heavy: a forearm plate, dropping, to the head (breaks guard) [a pose exists] |
| 24 | `martial.y.05` | **Rib Elbow Fall** | A heavy: an elbow, dropping, to the ribs (breaks guard) [a pose exists] |
| 25 | `martial.y.07` | **Rib Pile** | A heavy: a closed fist, straight in, to the ribs [bent from a pose] |
| 26 | `martial.y.09` | **Brow Ram** | A heavy: the brow, straight in, to the jaw (lifts) [a pose exists] |
| 27 | `martial.y.10` | **Head Wallop** | A heavy: a closed fist, swinging in, to the head [bent from a pose] |
| 28 | `martial.y.12` | **Rib Elbow Hook** | A heavy: an elbow, swinging in, to the ribs (breaks guard) [a pose exists] |
| 29 | `martial.y.13` | **Rib Boot** | A heavy: the sole, straight in, to the ribs [a pose exists] |
| 30 | `martial.y.15` | **Arm Backswing** | A heavy: the heel of the hand, swinging out, to the arm [needs a new pose] |

## 6. A signature's name

A **signature is not generated.** Its name is **hand-picked by Orb**. The rules a hand-picked name keeps:

1. **Shouted, so short.** The fighter shouts it as one clipped burst (`no_stretch`, no syllable longer than about 0.25 s), so a name works in two or three syllables and has no long vowel to drag out.
2. **Not the pattern.** A signature does not read as `Place Tool`, or players would take it for a move on the sheet. It is a proper name (*Keeper's Lance* today).
3. **No borrowed words.** A generated move never uses a signature's or finisher's words (the reserved list in 3.4), and a signature never uses the generator's tool words.
4. **Legal's patterns apply:** no *Final ___*, *Big Bang ___*, *Spirit ___* or *Special ___ Cannon*, and an exact-phrase search on every hand-picked name before it ships.
5. **Distinct per fighter and per move:** the signature, a special and a finisher each have their own name. The placeholders today are *Keeper's Lance*, *The Barrage*, *Decree Line*, *Portal Blitz* (signatures) and *Finishing Blow*, *Skyward Lance*, *The Display*, *Everything*, *The Verdict*, *Clean Cut*, *Last Orders* (finishers).
6. **A finisher's name may be a line** ("Last Orders") and not a noun, because it is a set piece.

## 7. How Orb edits it

The file is `docs/narrative/move-names-draft.csv`, 60 rows, the voice lab's columns:

| Column | |
|---|---|
| `id` | The move's id on the sheet (`mv.rival.martial.x.07`). **Do not change it.** |
| `fighter`, `kind` | Who, and `move name`. |
| `situation` | The move, in plain words. |
| `line` | **The drafted name.** |
| `Orb's edit` | Your name, or a word to change. |
| `note` | A reason, or a rule ("Riser is too clunky everywhere"). |
| `keep / cut / rewrite` | As in the voice lab. |

**A rule beats a rename.** If you change a **word** (say, *Riser* to *Lifter*), say so in the note and I change the lexicon, so every move that uses it follows. If you rename a **single move**, I record it as an override. The 16 moves a fighter not in the sample get their names from the final lexicon.

## 8. What it needs

- **Combat:** a `name` field on each move in the moveset JSON, filled from the lexicon, and a `lexicon` file next to `identity.json` (the words in section 3, per fighter). I can ship the lexicon as a data file on request.
- **UI:** the recipe display shows `name`; a long form ("Jaw Hook, to the head") is available for a tooltip.
- **Tools:** a schema for the lexicon, and a check that names are unique per fighter and avoid the reserved words.
- **Legal:** a pass on the words list in 3.4 and an exact-phrase search once Orb's names are in.

## 9. Questions for Orb

1. Are plain **gym-floor names** ("Jaw Hook", "Gut Riser") the right voice, or do you want the moves to sound more like attacks with names of their own?
2. Should a **heavy** show its weight in its name (a prefix such as *Full* or *Hard*), or is the heavier tool word enough?
3. Do you want the rival's names to carry his **rank joke** (the ranks "Fourth" and "Fifth"), or stay flat and hard?
4. Should the **two fighters share names** for the moves they share, as the sheet does, or always differ?
