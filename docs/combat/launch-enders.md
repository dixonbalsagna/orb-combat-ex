# A launch from any blow: launch enders by piece family, aimed by the stick

Owner: Combat and Choreography. Date: 2026-10-17. Paper and a parked table (`pending/launch/enders.json`). Nothing is built.

**Orb** (homework 23, `docs/ep/vision.md`, d65c3439): "launchers should have an intuitive way to activate and aim at any point in a combo string", with no four-in-a-row gate and no cooldowns: "avoid strict caps on what a player can do in a fight".

**What is whose.** Game Design is redesigning the rules: when a launch may be asked for, and what pays for it. This is the moveset side. Whatever the trigger, it answers which blow launches and how the stick aims it, so that a string branches into a launch from wherever it stands.

## 1. What a launch ender is

- **A launch ender is a launch piece that continues the blow before it.** It is a heavy of his tier that reads on half the wind-up and lands on the trunk or the head, the same pieces the launcher draws on today. Its path follows from the last blow's path, so the string flows into the launch rather than stopping for it.
- **The stick aims it,** as the launcher's aim does today: up sends up, down sends down, toward sends across, away sends turned. With no stick the launch planner picks the send, as now.
- **A family is the last blow's limb group and its path.** Hands; legs (foot and knee); and close (elbow, shoulder, head). The paths are line, rise, drop, arc in, arc out and spin. A kick string prefers a kick launch, and a hand string a hand launch.
- **It always exists.** For every family and every send there is an ender, in five steps:

| Step | The ender | What it looks like |
| ---: | :--- | :--- |
| 1 | A launch piece whose path follows the last blow, and of the same family | The string flows straight into the launch: the jab's line into the straight heave |
| 2 | A launch piece whose path follows, of another family | The same flow, another limb: a hand string into a launching knee |
| 3 | His family, with a re-chamber | The tell made longer by the join, so it still reads: his body resets, then launches |
| 4 | Any launch piece, with a re-chamber | As step 3 |
| 5 | The step lower: a medium that sends that way | The launcher's fallback today (`launcher.bySendLower`) |

**The launch's own links.** A string's links (`parts.json` `strike.links`) say which path may follow which. A launch is allowed three more:
- the hook into the uppercut or the hammer;
- the spin into a rise or a fall;
- the outward arc into a rise.

It never allows a rise after a rise or a fall after a fall: those keep the re-chamber. The links are in the table's `launchLinks`, not in `parts.json`, so strings are untouched.

## 2. What the two fighters have

Their launch pieces with Animation's fourth patch:

| Send | The Protagonist | The Anti-hero |
| :--- | :--- | :--- |
| **Up** | The palm heave (hand, rise); the ball-of-foot heave (leg, rise) | The fist heave (hand, rise); the elbow heave (close, rise) |
| **Down** | The falling palm; the falling blade hand (both hands, drop) | The hammer fist (hand, drop); the falling heel (leg, drop) |
| **Across** | The blade to the jaw (hand, line); the stepping edge kick (leg, line) | The ram (hand, line); the knee (leg, line) |
| **Turned** | The unwinding edge kick (leg, arc out); the elbow to the jaw (close, arc in) | The plate swing and the hook (hand, arc in); the unwinding fist (hand, arc out) |

**Every send has at least two pieces with Animation's new pieces** (the parked split recipes). With no cap on launches, that keeps the next launch from repeating the last, which is the one variety rule a launch must keep. **On today's live recipes the Protagonist has one launch that sends down,** the falling palm: his falling blade hand comes with the split.

**Coverage, from the table** (18 family-and-path rows by 4 sends, so 72 cells for each fighter):
- **Steps 1 and 2** (the string flows straight into the launch) fill **63 of 72 for both fighters.**
- **Nine cells need the re-chamber,** for each fighter:
  - a rise after a rise (up);
  - a fall after a fall (down);
  - a turn after a fall (turned).
  These are the follow-ups that wouldn't read as one motion.
- **About 14% of the Protagonist's strings would end on a family that needs a re-chamber for the send asked, and 16% of the Anti-hero's.** That is weighted by how often his posed blows end on each family and path, a proxy for where strings end.
- **With a string's links alone,** 24 of 72 would need it. The launch's three extra links are what make "at any point" feel immediate.

**Optional pieces, to make step 1 (his own family) more common.** It already works through step 2.
- The Protagonist: a falling kick (a leg launch that sends down) and a turning palm launch (a hand launch that turns).
- The Anti-hero: a rising knee launch (a leg launch that sends up) and a turning kick.

Four in all, generated on request.

## 3. How the alchemist picks

The director already picks the launcher's piece by the send the stick wants (`pickWhere` with `want`). Extended to any blow of a string, it reads in order:
1. **The send.** The stick's quarter is a rule. With no stick, the planner's send: personality, care, a building in line, the height, as the launch planner scores it now.
2. **The step,** from the table: 1 before 2, before 3, before 4, before 5. The table is per fighter, so the director looks a row up rather than computing it.
3. **Within a step,** the alchemist's own terms:
   - **The world.** A building in the send's line favours the piece that sends into it, which makes a wall slam. Height favours down, and open sky favours up. These are the ender-by-kind terms of the tenth round.
   - **His identity.** The Protagonist leans up and turned, away from people; the Anti-hero across and down, into buildings and the ground (`fighter-pipeline.md` §8).
   - **Variety.** Never one of his last two launch pieces. The planner's repeat term already counts sends.
   - **The gut filter.** Never two blows running to the gut.
4. **The emergent branch.** When the last blow already has a step-1 ender for the send the stick holds, the launch reads as the string's natural end. The alchemist can show that moment (a cue on the blow), which is how a player learns where launches live without a gate. The cue is Encounter's and UI's, if the rules want one.

**What this asks of others.**
- **Encounter:** the hook reads the last piece and the table's row. Its rebuilt launch anywhere reads the table from its own file, `data/combat/enders.json` (section 5), not from a recipes block.
- **Animation:** the re-chamber is the join smoothing with a longer tell. Animation should say how many ticks reads as a reset and not a stall; I assume about 6.
- **Game Design:** the trigger, and its price in place of the cooldown.

## 4. The table

`pending/launch/enders.json` holds, for each fighter:
- the 18 family-and-path rows by 4 sends, each an ordered list of launch pieces with its step;
- the steps' meaning;
- the launch links;
- the cells that need a re-chamber.

Section 5 has the two files and what each is built on. Each is built from one recipes file, each fighter's launcher pool and its step lower, so it follows when that file changes.

## 5. As Encounter's data file, proven on its launch anywhere (2026-10-18)

**Encounter's rebuilt launch anywhere** (`docs/director/pending/launch-anywhere/`, behind `brawl.launcher.anywhere.enabled`) reads Combat's enders from `res://data/combat/enders.json`.
- **The lookup:** `fighters.<pool key>.enders["<family>.<path>"][send]`.
- **The pick:** the lowest step listed, a keyed draw within it.
- **The aim:** an aimed launcher only; with no stick the planner picks as before.

**Two files, parked in `pending/launch/`:**
- **`enders.json`** is built on the live recipes, so every piece it names is in today's pieces table and that fighter's launcher pool. **It can land now,** with launch anywhere.
- **`enders.next.json`** is built on `pending/split/recipes.split.json`, with Animation's new pieces. It lands with the split, in place of the first.
- **The training dummy is in both,** on his stand-ins and the common uppercut and rising knee.
- **Each piece counts under every send its row lists:** two of the dummy's spinning stand-ins send across or turned.

| Re-chamber cells, of 72 | The Protagonist | The Anti-hero | The dummy |
| :--- | ---: | ---: | ---: |
| `enders.json` (live) | 9 | 12 | 21 |
| `enders.next.json` | 9 | 9 | 21 |

Live, the Anti-hero has three more because his unwinding fist is in the split. The dummy's stand-ins cover few paths.

**Proven,** on a clean export of main fda9b426 with Encounter's `la.cjs` applied, the switch on and `enders.json` in place:
- **Tools' validator:** 0 errors. One warning: `data/combat/enders.json` has no schema yet. With my draft schema (`pending/launch/combat-enders.schema.json`) and a map row added in the scratch copy, it reads 0 errors and 0 warnings, and a step of 9 is refused.
- **A scripted player** throws lights, then every fourth press a B with the stick held one of the four ways in turn, against the medium AI, 240 s a match.

| | Aimed launchers | From the table's lowest step | Steps 1 / 2 / 3 / 4 | Flowed straight (1 or 2) |
| :--- | ---: | ---: | :--- | ---: |
| The Protagonist, 4 matches | 169 | **169** | 96 / 60 / 9 / 4 | 92% |
| The Anti-hero, 4 matches | 142 | **142** | 79 / 37 / 15 / 11 | 82% |
| The dummy, 3 matches | 119 | **119** | 67 / 25 / 12 / 15 | 77% |

- **No script error.**
- **The AI's launchers are all unaimed** (aim 0): 112 in six AI matches, at hard. So the AI never reaches the enders: its launches take the planner's send and the old pick. Whether the AI should aim, by its personality's send, so that its strings branch the same way, is Encounter's.
- **The re-chamber's longer tell isn't in Encounter's build:** a step-3 or step-4 piece is thrown on the launcher's usual wind-up. The file carries `rechamber` (from step 3, about 6 ticks) for Encounter to read if wanted.
- **The replay hash doesn't cover the file.** The director's data hash (`DirData.dataHash`, `sim/director/data.gd`) folds in the alchemy and recipes files, not `data/combat/enders.json`. With the switch on, the file picks the launcher's piece, and the piece feeds the next pick (Encounter's `LA_FP`). So a change to the file alone would leave a replay's data check passing while it desyncs. Before the file is relied on, Encounter or Simulation should add it to the data hash; the golden then moves once.
- **Variety is the director's draw within a step,** not "never one of his last two". The freshness by kind of send carries most of it.

**To land `enders.json`, from others, in the same commit:**
- **Tools:** the schema (my draft, `pending/launch/combat-enders.schema.json`), its row in `tools/schemas/map.json`, and at least three invalid cases in the fixtures, which the self-test's coverage asks of every schema. Its proposed cross-checks are in the schema's description: every strike a row of the recipes' pieces, every fighter a pool key, a step 1 to 4 strike in his launcher pool, a step 5 strike in his step lower.
- **Encounter or Simulation:** the file in the director's data hash, as above.
