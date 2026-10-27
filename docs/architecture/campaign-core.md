# The campaign's sim foundation (first slice, step 1)

Owner: Simulation and Engine. 2026-10-25 and 26, on the EP's brief: Game Design's `docs/design/campaign.md` §1.1 to §1.4, §2 and §7, under Legal's mc01 to mc03 and mc06 (`docs/legal/campaign-screen.md`). On World's route (`WorldCampaign`, `docs/world/campaign-route.md`). The first slice, on stand-ins for World's calls, was applied in 622a0465; slice 1b, on World's real calls as this page describes, in 223ffdcc; and slice 1c, the cross-back, in c9bd20d1. The arc's planet loaded first (§3 item 0) was applied in b2793a1e.

**Step 1 of the first slice:** one solo episode, five stages on one planet, choosing by flying. Behind `data/fight/campaign.json`'s `enabled` (off), **the campaign's one switch**. With it off nothing moves.

## 1. An episode is a run with an arc block

An episode is a run (`run-mode.md`; the run state, `run-core.md` §12): fights from base, boons, the ceiling and lives. `SimCampaign.newEpisode(arc, e, P, opts)` builds its run state with three changes:
- the run seed is the episode's own (`episodeRun`), so its stages' seeds are its own;
- the planet is the arc's, one for all of its episodes (`arcPlanet`);
- the state has an **arc block** (`state.arc`).

| Field | What |
| :--- | :--- |
| `id`, `kind` | The arc's id (16 hex digits, its seed), and its kind: `filler_episode`, `filler_arc`, `main_episode` or `main_arc` (§1.1) |
| `villain`, `player` | `arc_villain`: a roster or bench fighter whose role is villain or rival, never the player, drawn by the arc's seed or fixed by the main story; and the player's fighter |
| `episode`, `episodes`, `number`, `follows` | The episode's index and the arc's length; a main-story episode's number in the season; a side story's main episode (the card reads n.5) |
| `families` | A filler arc's first two episodes' families (two different ones), or a filler episode's one |
| `column`, `columns`, `taken`, `done`, `back` | The column in play (0 to 4). Each column's sites as World offered them, kept as whole numbers and short strings: `{id, kind, place, arc, entry, dir, preferred}`. The site flown to in each, whether the episode is over, and the place the cross-back asked at column 4 (-1: none) |
| `ring`, `pc`, `resize`, `turns`, `rings` | The ring the pair fly (a setup's `arena`, JSON-safe), their column on it, whether the next stage needs a match of another length (the climax's whole circle), each column's turn in degrees, and each column's ring length |
| `wear`, `used` | **The run's place state**, World's bands (`{place id as text: 0 to 3}`, from fallen buildings, never people: mc02), and the places the episode has used |
| `side` | `{offered, place, family, ring, how, turn}`: the side story a main-story episode won may offer (§1.4), with World's `how` (band, widened or turned) and the end's turn in whole degrees (0: none) |
| `threads` | Open threads, ids only (mc02) |

`SimRun.checkState` checks an arc block when a state has one (`SimCampaign.checkArc`: the kind, the id, the lists, the threads as ids, the sites' fields).

## 2. The seeds

- **The episode seed** `H(arc, "episode", e)` is World's `epSeed`. Every draw of the route comes from it or from the arc's own: World's column draws, the episode's first bearing, and the test's choice.
- **The episode's run seed** is two words of the arc's hash. The stages' match seeds come from it.
- **The arc's planet** is `H(arc, "planet")`, and **the arc's seed** for World's side story is `H(arc, "arc")`.
- **Pinned in parity:** arc c0ffee00c0ffee00 has episode seed 2515801561, run seed 95f415d9fb019b1a, planet 2172332729 and arc seed 1643510628.

## 3. The route, a column at a time

0. **The arc's planet is loaded first** (`beginLoad(arcId)`, `planet-load.md`): the host steps it a slice a frame from the moment the arc is known, while the pair are picked, then `WorldPlanet.make` finds it made for `newEpisode` and the columns. With `SimPlanetLoad.strict` on, `beginColumn` refuses a gen 2 planet that isn't made. Each stage's ring can be read the same way over the flight to its site (`SimPlanetLoad.beginFor(stageSetup)`).
1. **The first ring** is `ringCols` (2,400, a Half ring, which a column's band of 322 to 806 columns each way fits: `rulings-2026-10-26.md` item 1) round the player's home, on a bearing from the episode seed. The pair start at its middle.
2. **`beginColumn(state, P)`** begins World's column job (`WorldCampaign.beginColumn`) for the current column. It passes the ring, the pair's column, the used places, the wear and the climax's pin (the villain's home). **The host steps it a ring's read a frame over the beats before the column** (nine reads, about 11 ms each; 500 ms at once on a gen 2 planet).
3. **`columnDone(state, job.result)`** keeps the column's sites, and makes World's `start` the ring the pair fly (after any turn, its touch-down at the pair), with their column on it.
4. **`stageSetup(state, site, slots, P)`** is the setup of the stage at a site: the planet, the ring re-centred on the site (World's `rebased`, so the stage is fought where the pair flew to), the run's wear (World lays it on the stage's buildings at the start) and the slots.
5. **`advance(state, end, P)`** is `SimRun.carry` plus the route. A stage won at one of the column's sites:
   - takes the site;
   - adds its place to the used;
   - merges the stage's wear (`end.wear`, World's `wearOf` of its final state) by the worse band;
   - moves the pair's column to the site;
   - steps the column.
   A site that is not one of the column's is refused, and the state is left as it was. After the fifth column the episode is done, and a main-story episode may offer a side story.
6. **The cross-back** (§2.2, slice 1c, `data/fight/campaign.json` `crossBack` 2 to 4): at column 4, `beginColumn` asks World again for the first named place column 2 offered and the pair didn't take (`crossBackPlace`, World's `prefer`). World offers it, leading the sites and marked `preferred`, when it stands in the band of a ring; otherwise the column is as it would be. The arc block keeps the place asked (`back`) and each site's `preferred`.
   - **Measured over 40 seeded filler arcs:** column 2 left a named place untaken in 11; World offered it again at column 4 in 5 of those, and the test's seeded flight took it in 3.

## 4. The one switch, and what World needs

- **The campaign's one switch is `data/fight/campaign.json`'s `enabled`.** The campaign's host builds episodes, asks World for columns and keeps the season record only while it is on.
- **World's `data/biomes/campaign.json` `enabled` is read by World's tools only.** So a match must not read a second switch. **World's one line** (`grant_world.py`): `WorldPlanetWorld.gen` lays a setup's `wear` whenever the setup has it, in place of only while World's switch is on. The setup is the match's input: the host gives a stage `wear` only while the campaign is on, and a replay lays the same wear whatever either file says. The same grant turns one line of World's `campaign_check`, which held the reverse, so that it holds this.
- **The replay knows the wear's rules:** `SimReplay.dataHash` takes World's campaign data (`WorldCampaign.dataHash`) for a setup with `wear`.

## 5. The season record, the side story, threads

- **The season record** (`newSeason`, `seasonAfter`, `checkSeason`) is `{format: "meridian-season", v: 1, lastMain}`: the number of the last main-story episode won. Whole numbers only, no personal data (mc02), and any other key is refused.
- **The side story** (§1.4): my draw `H(arc, "side", n)` offers one on `sideShare` (half) of the main-story episodes won. Then World places it (`WorldCampaign.side`, `rulings-2026-10-26.md` item 2): a named city or town in the band, else anywhere on the ring, else on the ring turned at the episode's end. It comes with its Close ring, and the arc block keeps World's `how` and the turn for the host to play at the calm moment. If World finds none, none is offered and the draw is spent.
  - On World's 630dcbad, before the widening, only 6 of 12 climax rings had a place in reach. World's w16 measures 32 of 32 test rings placed (21 in the band, 6 widened, 5 turned).
  - `openSide(main, P)` makes its filler episode (card n.5) on the main arc's planet as it stands (a copy of its wear and places), on the side story's ring. Nothing carries back.
- **Threads** are ids only (a roster id, a place id or a short tag), and filler can't close a `main:` thread (§1.2).
- **The card's number** (`cardNumber`): a main-story episode's number, a side story's n.5, or "" (SIDE STORY).
- **QA's record** (`qaRecord(state)`, the `campaign` object of `docs/qa/rally-campaign-rows.md`), from the run state:
  - `episodeSec`: the fights' seconds from the ledger's ticks (the flights, the beats and the retried fights join when the host times them);
  - `arc`, and each column's `n`, `ring` (World's size name: Close, Half or Whole), `turned` and its places' `fromPair`: signed columns to the place's near edge, which is World's band measure (0 inside a place; a city's centre can lie past 806);
  - `rescues`, `rematches`, `partner`, `templates` and `arcTemplates` are zero or empty until those steps exist.
  `campaign_episode.gd --record=<file>` writes it as `{"campaign": ...}`.

## 6. No fighter reads it (mc01, mc06)

- The arc block lives in the run state. A stage's setup carries the planet, the ring, the wear and the slots, and no fighter's parameter reads any of them: the wear is place state.
- Parity scans every file of `sim/core`, `sim/director` and `sim/input` (bar `campaign.gd` and `run.gd`) for `SimCampaign`, `state.arc` and `arc_villain`.
- The arc's villain is chosen by the arc's seed, never by how he fared against the player.

## 7. The checks

- **Parity, "the campaign's arc and episode":**
  - the data ships off, and the seeds are pinned;
  - a filler arc has two families and the Rival;
  - a whole episode on World's columns, played twice, is the same to the bit;
  - each site flown to is one of its column's;
  - the climax is the villain's home on the whole circle, and no place is used twice;
  - the state is the same through JSON;
  - a site not of its column is refused;
  - the wear is merged by the worse band and handed to the next stage's setup;
  - the cross-back: none asked when column 2 left no named place, and a seeded arc's (0bac000000017334, place 12) asked and leading column 4;
  - threads;
  - QA's record (the ledger's seconds, the rings, turns and places), the same through JSON;
  - a main-story episode's card and season record, and a side story's n.5 on the planet as it stands;
  - the mc01 scan.
- **`sim/core/tools/campaign_episode.gd`:** an episode on World's route at full stage length, twice, with QA's record; it exits 1 unless the two are identical and the episode is whole.

## 8. Not in step 1

Drop-in co-op, two stages at once, the arc's carry across episodes and "Previously on", the rescue, and the main story's fixed beats. Also boons in the world, beat cards, the edge beacons, the families mapped to columns, and Encounter's stage kinds. The test plays each stage as an AI duel at the site, scored won.

**In a running sim:** the ring turn between columns is World's `askCampaign`, the host's to call.
