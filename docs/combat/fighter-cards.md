# A fighter's card, and the pool builder for any number of fighters

Owner: Combat and Choreography. Date: 2026-10-12. Status: the tools are in scratch. The finding of section 2 was ruled on by the EP the same day, and the rebuilt light pools are in the parked `recipes.brawl.json`. Step 6 of Game Design's `docs/design/fighter-pipeline.md`.

## 1. The card

One page a fighter for Orb's yes or no, in place of the 805-line review sheet. It has no ids.
- Who he is in a fight, in two lines.
- What each press throws: the fifteen cells of the brawl, each with how many pieces it draws on, how many are his alone, and three of them by plain name, his own first.
- Where his launcher sends you, by the stick.
- What only he has, what he never does, and three things that set him apart from the rest of the roster, counted on his generated strikes.
- How much of him is drawn.

The two that exist are in `pending/cards/`: `protagonist.md` and `rival.md` (the Anti-hero). Each is about 900 words.

**What is generated and what is written by hand.** Everything is read from the generated movesets, `identity.json`, the recipes and Animation's packs, except two things: the two lines of who he is, and one plain line for each of his bans. The generator refuses to run when a fighter's bans and his plain lines differ in number, so a ban cannot be added without its line. A piece's name is made from what it is (a spear hand, a crescent kick, a forearm drop), never from an id. Pronouns come from the text file, so a card can be hers.

**"The pieces a player will see most" has no answer.** Within a press the game draws evenly. So a line shows three of the press's pieces with his own first, says how many of the pool are his alone, and the card says a player sees them all.

## 2. What the cards found: the lights were still the shared ones

The cards were made first from the frozen `recipes.brawl.json`, and they showed this:

| | The Anti-hero | The Protagonist |
| :--- | :--- | :--- |
| X tapped | 16 pieces, none his alone | 20, 4 his alone |
| X tapped, stick toward | 4, none | 4, none |
| X mashed, the flurry | 9, none | 10, 1 |

- **It is my gap, from step 2.** The mediums, the heavies, the burst and the energy pieces were built from each fighter's generated cells. The tapped light and the flurry were left on the old pools, which were made before the generated movesets were allowed. I wrote "unchanged" and "as committed" in `pending/nine-cells.md` and did not say what it meant.
- **Those three presses are most of a fight.** In the four measured matches, 82% of the Anti-hero's blows were a tapped or mashed light.
- **The old pools also break his own ban.** The Anti-hero never strikes with an open palm, and his tapped light and his flurry both hold the palm heel.

**The same pools built from each fighter's generated lights.** `light` draws on a new `brawl.light`, `lightToward` on a new `brawl.light.toward`, and `brawl.flurry` and `brawl.skill` are rebuilt. Nothing else in the file changes but the burst's samples and the fallback's counts. No piece row, no key of `brawl` and nothing in Tools' schema changes, and the hook reads pool names from the file.

**The EP ruled yes on 2026-10-12, and the parked file was rewritten that day.** Measured on a fresh copy of main (`6581ede7`), four seeds:

| | Today's pools | The rewritten file, today's picker | With the hook's gut filter |
| :--- | ---: | ---: | ---: |
| Brawl blows; match seconds | 7,238; 1,177.1 | 7,238; 1,177.1 | 7,238; 1,177.1 |
| The Anti-hero's blows that are a piece only he has | 13 of 3,671 | 33% | 33% |
| The Protagonist's | 24% | 37% | 37% |
| Two running to the gut | 0 | 7 | 0 |
| Three running to one place | 235 | 56 | 54 |
| A rise after a rise, at any height | 0 | 437 | 440 |

| The pools, pieces and his alone | As first frozen | Rewritten |
| :--- | ---: | ---: |
| X tapped | 16, 0 and 20, 4 | 27, 11 and 24, 9 |
| X tapped, stick toward | 4, 0 and 4, 0 | 7, 2 and 5, 0 |
| The flurry | 9, 0 and 10, 1 | 12, 3 and 11, 3 |
| A piece his own bans refuse, in a pool a cell names | the Anti-hero's palm heel, in two | none |

- **The fight is the same** in every run. Main's own fight moved between my first measure and this one (7,298 blows then), so the totals differ from `pending/nine-cells.md` section 3's first table.
- **On the first frozen file** the shares were 12% and 24% (measured on the earlier copy).
- **The gut rule needs the hook's filter, and the EP has made it a must.** The new flurry pools hold more blows to the gut (the Anti-hero's: 4 of 12, where it was 2 of 9), so today's picker gives up more often: 6 times here. With a stand-in for part 5 of `brawl-hook.md` (ask the pool for a piece that is not to the gut, in place of giving up) the count is 0.
- **The rises.** The new pools hold more rising blows: the Anti-hero's uppercuts and the Protagonist's rising palms. Legal's s05 binds only while he is airborne, and `brawl.gd` has no such state, so nothing here breaks it. It is the next rule the pick has to keep, when a juggle exists.
- **Joints:** Animation's strict scan passes on the rewritten file with the filter in (896 poses, 122 sequences, 24,000 live fighter-frames, none past a limit).
- **The generator's check passes,** and Tools' parked script fits the file (`pending/nine-cells.md` section 3).
- **The cards in `pending/cards/` are made from the rewritten file.**

## 3. Any number of fighters

Proved in scratch on a roster of three: the two in the tree and a third made from a sketch row (the Cyborg's Courier), who reads every pack that exists and has none of his own.

| Tool | What it takes now | Proof |
| :--- | :--- | :--- |
| The generator | It needed no change | 127 moves for the third fighter: 86 posed, 27 borrowed from a nearby pose, 14 waiting. The other two's rows did not move. `--check` passes on the three |
| The pool builder (`pools_n.py`) | Every fighter in `identity.json`. A fighter the recipes do not have gets every pool by rule from his cells. It never writes the tree unless told | For the two fighters it rebuilds the frozen file byte for byte. For the third: 24 pools, none empty, no piece his bans refuse |
| The probe | The two seats' fighters as arguments | The seats swapped: 900 blows, none without a piece. A grey copy of a fighter under a new id with the third fighter's pools: his 826 blows all came from his own pools |
| The card | Every fighter the recipes have | A third card, with the roster's wording ("the most in the roster; next is...") |

Two checks the builder gained: no pool that a cell names may be empty, and no piece in it may be a shape the fighter's own bans refuse.

**Sharing heavies by Game Design's rule: built in scratch first, and since then in the generator itself** (version 15; `roster-rows.md` has it as built, with the pairwise cap and the lender's own share, and the rows for the Cyborg and the Empress). What follows is the first scratch trial.
- **The rule as data,** on the heavy cell: `"share": {"own": {"1": 2, "2": 4}, "maxWithOne": 0.5}`. A fighter says his tier in his identity (`tier`, 1 when it is not said) and which packs are another fighter's (`borrows`).
- **His alone** is a piece from a pack of his own, or a new shape that no other fighter's cell holds. A new shape waits for Animation, so the rule is also his list of what to pose.
- **The cap** counts what he takes from one other fighter's packs, and stops at half the cell.
- **A launcher for every send** became four quotas of the cell, filled first. The check already held every tier to it; without the quotas, a fighter who borrows under a cap could end with none that sends down, and the generator refused to write.
- **`--check` fails** when a cell with the rule has too few of his own or too many from one fighter.

| The third fighter's ten heavies | With no rule | Tier 1 | Tier 2 |
| :--- | ---: | ---: | ---: |
| His alone (new, waiting) | 0 | 2 | 4 |
| From the Anti-hero's tier | 7 | 5 | 4 |
| From the Protagonist's tier | 3 | 3 | 2 |
| A launcher for every send | yes | yes | yes |

At tier 1 his two are a stepping knee to the legs and a turning elbow to the chest: his own weights picked them. The other two fighters' moves do not change, and `--check` passes on the three. When this goes into the tree, the two parked movesets change by their inputs line and by a count in the heavy cell.

## 4. The Cyborg's three silhouettes, as rows

Two lines each, on today's systems. The Courier's is the row that ran in section 3.

- **The Press, a grappler.** Forearm plates, hammer fists, the shoulder and crossed forearms, on drops and rams, to the chest and the arms. Never a blade hand, a spin, or a kick above the gut; his launchers send down and across, and his burst ends on a drop.
  What he needs that nobody has: clamps and throws. Two kinds of grab are named in the data and none is generated, so he is the most new work of the three.
- **The Courier, the fastest.** Elbows, knees and straight fists on short lines and rises. Never a spin, never a kick above the chest; more of his lights fit the burst's quick gaps, his launchers drive across and up, and his burst ends on a straight.
  He is the cheapest: weights and bans only. With no pose of his own he already leads the roster in knees and in blows to the legs. The pool has 6 elbows and 5 knees, so about 8 new ones are what stop him repeating (estimate).
- **The Hopper, a devourer.** He comes down on you: stomps, the axe kick, the hammer fist and the dropping elbow, with rising knees to carry him up, to the head and the chest. Never a blade hand; his launchers send down and up, and his burst ends on a drop.
  Legal comes first with him: a rising blow that leaps may not go to the jaw or the head, nothing bites, and a stomp on a rival who is down is a rating question. The mouth is his mechanic, at tier 2.

## 5. Where the tools are

In Combat's session scratch (`dyn/`), not in the tree: `fighter_card.py` with `card_text.json`; `make_pools_n.py`, which writes `pools_n.py` from the step 2 builder; `gen_at.py`, which runs the generator on a copy of its inputs; `roster3_setup.py` and `roster_scratch_setup.py` for the scratch roster and the probe; `share_quota.py`, which writes the generator's copy with the sharing rule. When the card is accepted it belongs beside the generator, and its hand-kept lines in `identity.json`.
