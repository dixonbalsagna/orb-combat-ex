# 2v2: the director's plan

Encounter, 2026-11-02, for the EP's brief: what a finished fight does, the sends that bring the fights together, the brink's call, and the statics audit for two fights. **Plan only: nothing is built.** The rules are Game Design's `docs/design/two-v-two.md` ("Rulings for the build" and "Hits across fights"). They sit on Simulation's fight swap (`docs/architecture/fight-swap.md`) and cross-fight hits (`docs/architecture/cross-fights.md`), both built and off. The sizing behind it is `two-fights-sizing.md`.

## The order

Each step goes behind its own switch, and with it off a 1v1 is byte-identical.

| # | What | Whose | My sessions |
| :--- | :--- | :--- | ---: |
| 1 | **The statics audit**, with a second fight in a test | Mine | 1 |
| 2 | **Blows from outside:** who strikes across and when, and what it does to the fight it lands in. A beam that stops on someone else. `fireAt` for a focus across | Mine, on `SimCross` | 1.5 to 2 |
| 3 | **A finished fight:** the winner flies over; the team is out when both are out | Simulation's match end and rejoin; mine for the flight and the AI | 1, plus Simulation's |
| 4 | **The sends that bring them together** | Mine | 0.5 |
| 5 | **The brink's call,** and the computer partner's rescue | Mine, with Audio's line and UI's map | 0.5 |

**About 4.5 to 5 sessions of mine,** against the sizing's 2 for two fights stepping. Steps 2 to 5 are the new part, and they're what makes a rescue happen. Step 2 comes before 3 to 5 because the winner's arrival, the rescue and the joined fights all land as blows from outside.

## 1. The statics audit

`sim/director` has 116 `static var`s in 31 files. Under the swap, each fight's tick runs in turn on the same statics, so each one is one of:

| Kind | Under two fights | What to do |
| :--- | :--- | :--- |
| Data caches, tool switches (`_force`) | Shared, right | Nothing |
| Set and cleared inside one call or one tick (the brawl's frame `_frA`, `_inTick`, the new `_inHang`) | Safe: each fight's tick sets its own | A check that each is clear between fights |
| Following the line (`DirLocation`'s tables) | Shared, right: all four are on one line | Nothing |
| **Keyed by the tick** (`DirAlchemy`'s read cache) | **Wrong, not a desync:** fight 1 would read fight 0's values for the same tick | Key by fight and tick |
| Anything else kept across ticks | Per fight | Move it onto the fight's state, or key it by fight |

**First pass (2026-11-02), by reading.** Of the 116:

| Kind | How many | Verdict |
| :--- | ---: | :--- |
| Data caches (`_d`, `_cfg`, `_tpl` and the like), tool switches (`_force`, `forceBiome`, `everyPlace`, `aiBeat`) | about 75 | Fine |
| Slot-base memos (`_baseAt`, `_laBaseAt`): the chain's layout, the same in every fight | 9 | Fine |
| One call or one tick (the brawl's frame and `_inTick`, `holding`, `_enderStep`, `exchange.plan*`, `_meetShift`, swing's `_plan`, `_was` and `_posed`, `firing`, `_noDown`, `_inHang`) | about 25 | Fine, with a between-fights check |
| By the line or the world (`DirLocation`'s tables, swing's `_builtMemo`) | 7 | Fine: one line |
| `DirAI.level` | 1 | Per match. Fine unless the two fights get different levels |
| `DirAlchemy`'s read cache (`_rdS`, `_rdTick`, `_rdKey`, `_rdOut`) | 4 | **Fine, corrected on a closer read:** it's keyed by the whole press log as well as the tick, and the answer is a pure function of those, so two fights can't be given each other's. Under two fights it misses more often (about 170 µs a read) |

**Not statics, but the same kind of trap: match-level state kept on `S.fighters[0]`.** Under the swap that's each fight's first fighter, so it splits in two:
- **The swing director's memory** (`W_LAST`, `W_JOLT`, a town's sends and the rest) describes the one shared line, so it should be one copy. It needs an anchor that isn't a fight's first fighter: the match's first body, read through the stage (`st.fights[0].fighters[0]` while another fight is entered). That's mine, a read with nothing written, and a 1v1 doesn't change.
- **The arc's match counts** (`A_USED`, the planet-scale launches, and `A_METEORS`) are per match. The first version has no meteor, so this can wait.

**The proof:** `fights_check`'s pattern on my switches. Fight 0 is identical to a plain 1v1 with every switch of mine on, and fight 1 is identical whether fight 0 fights or idles, on 3 worlds and 2 seeds. Then `two_states_check --setups=fights` and the rollback.

## 2. Blows from outside

Simulation's `SimCross.enemiesNear` and `SimCross.strike` carry the blow. What's mine is when it's thrown and what it does when it lands, by Game Design's "Hits across fights":

- **Focus** picks the target: whoever you last hit, else the nearest in front, and the stick moves it. A focus in a fight with your partner makes your press a single blow from outside.
- **It lands only on an opening:** a stagger, a stun or a daze, a whiff's open time, his own blow's recovery, or a beam's stuck time. You hover in reach up to 0.5 s for the next one, or it's a whiff and you're open 20 ticks.
- **One blow from outside per opening, for a whole team.** One stun a string, counted across a team (24 ticks).
- **What it does:**
  - On a fighter landing a finisher, it breaks the finisher.
  - On one in a string, it ends his string.
  - On one your partner is stringing, it adds damage and a reel only.
  - Never a send or a knock-back.
- **A beam that stops on someone else:** its own target mustn't get the planned outcome, and its exchange ends. The warning cue for `b.first`, and the AI's answer to it.
- **`fireAt`** when the shooter's focus is across.

## 3. A finished fight

**The rule:** whoever finishes first flies to the other fight, with no input needed for a computer fighter. The team is out when both its fighters are out.

**How, with the swap.** Each fight stays one of each team, so the winner can't join the other fight as a third body. He stays in his own fight, now with no rival, flies over, and **fights from outside** by step 2's rules: two on one is a body striking on openings. When the other fight ends too, with one standing on each team in different fights, the two standing bodies become one fight's pair and fight on as a 1v1.

**Simulation's part:**
- The match ends when a team has nobody standing, not at the first KO.
- A fight with a KO keeps stepping its standing fighter as a free body. The fighter that's out is inert: no hits, no contact.
- The rejoin: the two KO'd bodies go to one fight and the two standing to the other, with that fight's KO state cleared. `trade` refuses a fight with a KO today.

**Mine:**
- The computer winner's flight. Its focus moves to the nearest enemy across, it flies, and it strikes on openings.
- The human's: focus moves across by itself, and a held press pursues, as Game Design's row says, with the long strike paying for the arrival.
- The new pair's director state starts fresh on the rejoin. A fighter's own slots travel with him.

## 4. The sends that bring them together

After the pairs have been apart about **60 s**, a send scores the direction of the other fight, for everyone, computer fighters too, **at most a sixth of a loop per send.**

- A term in the launch planner, next to the hero's town avoidance. Its weight grows with the time apart, and it's capped so no send flies further for it.
- The clock of the time apart is each fight's own, on its fighters' slots.
- The other fight's middle is read through Simulation's stage, with nothing written. I'd like a getter for it (`SimCross` or `SimStage`), a few lines of Simulation's.

## 5. The brink's call

- **On the brink's first moment,** the fighter calls: a cue `brink_call`, for Audio's voice line and UI's map.
- **A computer fighter's partner answers:** its focus moves to his rival, it flies, and it strikes from outside on an opening. The best one is breaking the finisher. So a human and a computer partner can race to the rescue.
- **Read:** QA's rows, all four within about 15,000 units for 25 to 50% of a match, and 2 to 4 rescue flights a match. If the fights never meet, it's two 1v1s, and that's the failure to watch for.

## When I can start

**Now, from step 1.** The only thing ahead of it in my queue is the chase-air report. Step 1 needs nothing from anyone. Step 2 needs only Simulation's `SimCross`, already built. Step 3 waits on Simulation's match end and rejoin, so that brief should go to Simulation by the time I'm through step 2.

## Game Design's rulings (2026-11-02, through the EP)

1. **The human winner:** his focus moves across by itself after the finisher's moment, easing over about 12 ticks. A held press pursues, and the stick overrides.
2. **A rejoined 1v1:** wear starts where it stood, and the brink isn't reset.
3. **The sends** don't pull while a team is two on one.
