# Brawl slice B1: the first brawl

Owner: Encounter Systems Director. Date: 2026-10-05. Status: applied to the tree on HEAD 3c4f9c7, measured in a scratch copy of that commit, waiting for the EP's commit. Parked sources: `docs/director/pending/brawl-b1/`. Plan: `docs/director/brawl-plan.md` section 4. Spec: `docs/design/melee-press-feel.md` sections 1 to 3 and 5 to 7. QA's plan: `docs/qa/brawl-qa-plan.md`.

## 1. What it does

In the close band, a light or a heavy against a rival who stands or guards starts a **brawl** in place of a planned exchange. Both fighters are in it. Each has his own strike line, and every attack press of either is one blow.

| Thing | Rule in B1 | Number (data) |
| :--- | :--- | :--- |
| **A light** | Lands 2 ticks after the press. It is worth one brawl light: the data's light times the brawl's scale. The scale is 0.30, so that is 7.8 today | `light.contactTicks`, `damageMul` |
| **A flurry** | Lights tapped 6 to 12 ticks apart. A blow lasts one tap gap and is worth a brawl light times its gap over 10: ×0.6 at 6 ticks, ×1.2 at 12 | `flurry.minGap`, `maxGap`, `mul` |
| **The run** (the spec's section 3) | Each fighter has a run against the rival. It goes up 1 for each light or flurry blow he lands and down 1, never below 0, for each that lands on him. A heavy on him clears it, and so do 24 ticks without landing. A blocked blow changes nothing | `flurry.replyTakes`, `runLapseTicks` |
| **The close** | At a run of 4 his next landed light staggers the rival 12 ticks in place. It is decisive, at a quarter of a set-up. His run is spent, the rival's is cleared, and his string is closed | `flurry.runToClose`, `staggerTicks`; `launch.json setup.weight.blurPlain` |
| **The trade** | It is on while both have landed a light in the last 24 ticks. It can't pass 120 ticks without a close: at the limit it breaks for the fighter with the higher run, then the one who has landed more blows in this trade, then a seeded draw at even odds. His next landed blow is the close. The clock starts again after a close, a stagger or a heavy that lands | `flurry.tradeMaxTicks` |
| **A reel** | A landed light reels the rival 4 ticks. A press in a reel is held and thrown as it ends. A blow already on its way lands on time | `flurry.reelTicks` |
| **A heavy** | 26 ticks of wind-up and 8 to land, 4 ki. It is worth about 5 brawl lights: the data's heavy times the scale times 2, 39.6 today. Held past its wind-up it waits for the release and lands 8 ticks after it; fully charged at 46 ticks of hold it is worth ×1.25 | `heavy.*`, `heavyMul`, `heldMul` |
| **After a heavy** | His line is free 10 ticks after one that lands, breaks a guard or ends his string. Its 42 ticks of follow-through are animation. After a light, a heavy can follow 4 ticks after the light's contact | `heavy.recover`, `recoverWhiff`, `light.recover` |
| **Two lights that meet** | Landing within 2 ticks of each other, they are a trade: both land. Each beat carries `trade` and the other's piece, and a `trade` cue goes out | `tradeTicks` |
| **The ender** | A heavy thrown after 2 or more landed blows of his string. It knocks back, and the brawl ends. It launches when a launch is earned: held to full, or flow 3 | `enderAfter`, `heavy.force` |
| **A lone heavy** | Staggers him 12 ticks in place (the lift is B3). Held to full with the stick, it launches | `heavy.staggerTicks` |
| **A heavy on a guard** | Staggers the blocker 12 ticks in place. Nothing moves a blocker. The set guard and its 40 ticks down are B3 | `heavy.staggerTicks` |
| **A guard** | Today's held guard: it chips. A fighter with a blow of his own on its way isn't guarding, whatever he holds | |
| **A press he can't throw at once** | Held for 10 ticks, the latest only, and thrown as his line frees | `heldPressTicks` |
| **A press with the energy family held** | Not a brawl blow: B1 is the martial stance. It is spent, with a `press_ack` of `energy`, as it was no blow inside an exchange before. What the energy stance does in reach comes with the stances | |
| **A string** | His blows from his first until he is staggered, his flurry closes, his ender lands, or 30 ticks pass with nothing of his thrown or landed. Each string takes a new exchange number | `stringLapseTicks` |
| **Magnetism** | Both are stopped as the brawl begins, whatever speed they had. They are pulled to striking distance and to one height at up to 0.5 bh a second. A blow leans its target and doesn't move him. Past 4.5 bh it lets go | `pullBhPerSec`, `breakBh`, `recoil` |
| **Reach** | The first blow steps its thrower in. Every blow places its striker at contact distance, as a strike does today. A blow thrown from past the strike's placement limit (204 units) meets nothing; a heavy that does is recovered from in 30 ticks | `stepInTicks`, `heavy.recoverWhiff`; `templates.json` contact |
| **What ends it** | A knock-back or a launch. Leaving: a dodge or a boost with the stick away, at the dodge-cancel's price and rules. A burst. A perfect block or a reversal, which play as today. 60 ticks with no attack from either. A set piece taking it over: a limb break, a finisher, a signature | `idleTicks`, `interrupts` |
| **The pause after it** | None, except after a launch or a set piece | |
| **Flow** | A press inside a brawl neither earns nor loses flow. The beat point is B2 | |

**What keeps its template.** An attack against a rival in the dodge or the escape stance, an opening (riposte, reversal, punish), a charge's arrival, the meeting after a taunt, the follow-up on a buried rival, an attack on a rival who is charging or down, and every signature.

**A blow outside a brawl is worth its form too** (Game Design, the spec's section 9b). While the brawl is on, the strikes of a planned exchange are re-valued when they land (`DirBrawl.worth`):

| The blow | Worth |
| :--- | :--- |
| A light-class strike of a template | Its damage times the brawl's scale |
| A heavy-class strike: the class `heavy`, or the data heavy's damage. This covers a riposte with a heavy and the reversal's heavy | Its damage times the scale times `heavyMul`: 39.6 for the data's 66 |
| A chain link's blow | One brawl light, 7.8 |
| The first damaging blow of a riposte with a light, of a dodge template whatever its button, and of a light charge's arrival | A skill strike's worth, `skillMul` brawl lights. For a light that is its number today |
| The first blow of a heavy charge's arrival | A heavy held to full: ×`heldMul` of a brawl heavy |
| Signatures, finishers, the blow on a buried rival, shots, landings | Unchanged |

**Clocks.** A fighter's taps, his line, his string and the AI's choices count `S.tick`, which runs through hit-stop, so a flurry keeps the rate of the taps. A blow's wind-up, a reel and a hold count live ticks, as every beat does.

## 2. How it is built

- **`sim/director/brawl.gd` (new, `DirBrawl`).** The brawl is one exchange in `S.dirS.ex` whose template id is `brawl`. Its kind is the weight of the blow that is landing, light or heavy, because the core and QA's records read the kind that way.
- **A blow is one `strike` beat,** scheduled when it is thrown, so the renderers read it as a strike. Its args carry `brawl`, the beat fields of slice B0 (`style`, `grade`, `k`, `n`, `closing`, `charge`, `hand`, `ender`) and the piece.
- **State:** 32 integers a fighter, after the alchemy's, in the fighter's director integers. Nothing shared, so B1 does not need a new field in the core. The exchange's beat list is cleared of landed blows each time a string starts.
- **Data.** `interrupts.json` gains the `brawl` block and `perfectBlock.windows.blow`. Each level of `ai.json` gains a `brawl` block. `launch.json setup.weight.blurPlain` goes from 0.5 to 0.25. `flurry.closeAfter` is the first build's name for `runToClose`: it isn't read, and it stays only because the parked schema still requires it.
- **Pieces.** A light draws from the fighter's `blur.base` pool (`blur.toward` with the stick toward), a heavy from `combo.accent`, an ender from `power.last`. Combat's sequence rules that the pieces' data can say are hard rules: never one of his last two pieces, so never three of one running; and no two blows running to the gut.
- **The hooks** in `exchange.gd`: a press goes to the brawl; a brawl's strike beat is its contact; the brawl's tick runs before the beats; the exchange stays alive while the brawl holds; the pause after it. In `interrupt.gd`: the perfect block and the reversal for whoever is struck, the dodge-cancel only with the stick away, and each takeover tells the brawl why it ended. In `launch.gd`: each blow notes its own press for the launch's earners. In `alchemy.gd`: flow is kept. In `bands.gd`: a charge's arrival is marked. In `ai.gd`: the AI's brawl play.

## 3. The AI in a brawl

It chooses when its last choice has played out, not on the stance timer.

| Choice | Rule | Per level (`ai.json`, the level's `brawl`) |
| :--- | :--- | :--- |
| **A string** | Lights tapped on its cadence, as a player taps, so its string is a flurry at its tap gap. Then a heavy to close it if two landed | `tapGap`, `string`, `enderShare` |
| **A heavy into a running flurry** | The flurry's close would stop it, so it is a mistake, made at a rate | `rashHeavy` |
| **A guard** | Held 20 to 60 ticks. After it, it must attack | `guardShare`, `guardTicks` |
| **Its answer to a paced string** (the spec's section 9c). **Built, not switched on** | By a set landed blow of a rival's string that isn't a flurry, after its reaction time, it drops what it was doing and guards, then it must attack. It runs when a level sets the keys. They aren't set: see the findings in section 5 | `answerBy`, `guardMaxTicks`, `reactTicks` (existing) |
| **Its own string into a gap.** Built, not switched on | While it guards, when the rival has thrown nothing for a set time its guard comes down and it attacks | `attackIntoGap` |
| **A heavy on a guarding rival** | At the level's guard-break rate | `breakGuard` (existing) |
| **A perfect block** | Weighed against a light at most once in 30 ticks, and against every heavy | `perfectMul`, `aiPerfectEveryTicks` |
| **A reversal** | Weighed on a block at most once in 120 ticks | `aiReversalEveryTicks` |
| **The signature** | As outside, at its pick rate; the brawl gives way to it | `sigPick` (existing) |

It doesn't leave a brawl, sidestep, or burst in B1. Those are B5's.

## 4. For QA

**Events** (each is a `cue` event whose `kind` is the name):

| Event | Fields |
| :--- | :--- |
| `brawl_start` | `actor` the starter, `target` the rival, `n` the exchange number, `amount` the distance |
| `brawl_end` | `text` why (`knockback`, `launch`, `left`, `burst`, `perfect_block`, `reversal`, `idle`, `apart`, `break`, `finisher`, `signature`, `ko`), `n`, `amount` its live ticks, `x` and `y` the blows the starter and the rival threw |
| `blow` | `actor`, `target`, `text` its kind (`light`, `flurry`, `heavy`; `release` when a held heavy is let go), `amount` the press's own tick, `n` the tick it is due to land, `dur` the ticks to contact |
| `press_ack` | `actor`, `text` why (`held`, `lapsed`, `refused` for a signature that can't start, `energy`), `n` the press's tick |
| `stagger` | `actor` who staggers, `target` who did it, `text` (`flurry`, `heavy`), `n` its ticks |
| `guard_break` | `actor` the blocker, `target` the striker, `n` the stagger's ticks |
| `trade` | `actor` who threw the second blow of the pair, `target` the other, `n` the tick it is due to land |
| `trade_break` | A trade reached its limit. `actor` the fighter whose next landed blow closes it, `target` the other, `n` the trade's ticks |

**Reads:** `DirBrawl.inBrawl(S, f)`, `DirBrawl.busy(S, f)` (a blow on his line, or his line not free yet) and `DirBrawl.beatAt(S, f)` (the `S.tick` his blow on its way lands, or -1; B2 adds the beat point). A brawl is `S.dirS.ex.tpl == "brawl"`, not the exchange's kind.

**What a brawl's pending blow looks like in `ex.beats`** (for UI's beat ring, Animation and VFX, which read the pending `strike` beats):

| Field | In a brawl |
| :--- | :--- |
| The beat | `op` is `strike`, `done` false, `t` its contact on the exchange's clock. There are no `chainStrike` beats in a brawl |
| When it appears | On the tick the blow is thrown. A light is on the list for 2 ticks before it lands. A heavy for 34. So a ring that closes on a pending strike has 2 ticks for a light |
| `args.a`, `args.d` | Who throws and who takes it, `A` or `D`. Either fighter can be `a`: both have blows on the list at once |
| `args.brawl`, `args.bk` | `true`, and the kind: 0 a light, 1 a flurry blow, 2 a heavy |
| The beat fields | `style` (`speed` or `heavy`; `tech` comes with B2), `grade` (`none` until B2), `k` its place in his string, `n` the same, `closing` true when it will be the close if it lands, `charge` 0 to 1 once a held heavy is let go, `hand`, `ender`, `piece` |
| `args.trade`, `args.tradeWith` | Set on both beats when two lights will land within 2 ticks of each other |
| A held heavy | While he holds it past its wind-up, its beat stays pending with `t` an hour ahead. On the release `t` becomes 8 ticks ahead. A reader should treat a strike more than 60 ticks ahead as "held, no contact time yet" |
| The list itself | Landed blows are dropped from it each time either fighter starts a string, so it stays short. An index into it doesn't survive that; `ex.n` changes on the same tick |

There is no beat point to show until B2: in B1 the only time a ring can close on is the contact itself.

**What QA's scripts need to know.**
- The flurry counts `S.tick`. A script that taps every N live ticks taps slower than N on that clock, so rate rows are counted against `S.tick`.
- A press while staggered never reaches the director (the core's gate drops it), so it has no `press_ack`.
- `players.gd` keeps an index into the exchange's beat list. The list is now cleared of landed blows when a string starts, so the tapper's oracle has to be re-pointed at `beatAt`, as QA's plan says.

## 5. Rows

Measured on a scratch copy of HEAD 3c4f9c7 with B1 applied. The tree's files are byte for byte that copy's. QA's harness is `node qa/run-godot.js`, four arms, 100 matches an arm, 3 jobs. "Before" is slice B0 (`brawl-b0.md`) where a number is given.

**The standing rows.**

| Row | Before | With B1 | Band |
| :--- | ---: | ---: | :--- |
| Match length, median | 486.9 s | 455.3 s | 360 to 480 s |
| Match length, 10th and 90th percentile | | 362.3 s and 562.0 s | at least 300 s; at most 600 s |
| KAI over both slots | 53.5% | 49.5% (50.0% from P1, 49.0% from P2) | 45 to 55% |
| Masher against the easy, medium and hard AI | 100, 42, 0 of 100 | 87, 45, 2 of 100 | at least 60%; 35 to 50%; at most 15% |
| Bolt-only against the medium AI | 32 of 100 | 36 of 100 | 20 to 40% |
| Blasts' share of damage | 10.8% | 10.1% | 10 to 25% |
| Launches of the exchanges that separate | 39.2% | 31.1% | 25 to 40% |
| First brink, median | 404.9 s | 366.1 s | 270 to 420 s |
| Brink to KO, median | 84.0 s | 68.9 s | 45 to 90 s |
| Finisher survival | 31.5% | 33.8% | 25 to 40% |
| Front-row structures lost | 54.7% | 36.4% | 25 to 50% |
| Melee strikes within 68 units of reach (hard test) | | 0 of 339,323 beyond | all |
| Timed against plain (QA's F6) | 29 of 40 | 0 of 40 | 62 to 82% |

91 bands pass, 24 fail, 21 pending. Slice B0 read 98, 17 and 21.

**Timed against plain is not a reading.** QA's timed script keeps an index into the exchange's beat list and loses it inside a brawl, so it throws about 7 blows a match. There is no beat point until B2 in any case.

**Outside their bands with B1.**

| Row | Reads | Band | Why |
| :--- | ---: | :--- | :--- |
| Perfect blocks per 100 melee exchanges | 17.9 | 5 to 15 | A brawl is one exchange with many blows. The medium AI's share inside a brawl is already down to 0.15 of its rate outside (0.3 read 20.5) |
| Mixed blaster against the medium AI | 77 of 100 | 30 to 50% | Shots keep their damage while melee is at the brawl's scale. `blast.heavy.tapShare` at 0.25 reads 59; it is Game Design's number, so it stays at 0.4 |
| Blast-heavy and slow blaster against the rush-heavy timed script | 77.5% and 75% | 40 to 60% | The same, and the rush script is the timed script that is blind in a brawl |
| Mood: Calm and Frenzied shares of match time | 4.2% and 63.4% | 30 to 55%; 5 to 20% | The mood counts blows, and blows now come six a second. Act 2 starts at 77.8 s against 90 to 150 s |
| Arms' share of limb breaks (acceptance test W5) | 90.9% | 35 to 65% | A blocked blow wears the arms, and the AI blocks far more blows than it did |
| Exchanges started a minute | 14.0 | 15 to 28 | A brawl is one exchange |
| Knock-backs, and "the brawl continues", of launch decisions | 44.7% and 35.2% | 25 to 35%; 40 to 50% | Only an ender reaches a launch decision in a brawl, and an ender knocks back |
| Brunts a minute; launches that end halted; flights off terrain a minute | 0.15; 34.8%; 0.88 | 0.3 to 1.0; 40 to 60%; 1.5 to 5 | Fewer launches: flow doesn't build in a brawl until B2, so an ender launches only when held to full |
| Median lock-break; second breath's share | 1.3 s; 29.7% | 2 to 3 s; at most 25% | Not traced |

**The brawl's own rows** (my probe, `sim/director/tools/brawl_probe.gd`; a player who flies at the rival and taps a light every 8 ticks of `S.tick`).

| Row | Before | With B1 | Target |
| :--- | ---: | ---: | :--- |
| Presses in a brawl thrown as a blow inside 10 ticks, against the medium AI | 15.4% of all presses | 99.1% | at least 95% |
| Press to contact against a rival who lands nothing | | median 2 ticks, 95th percentile 2; 99.4 to 99.8% inside 4 | 2 ticks; 95% inside 4 |
| Press to contact against the medium AI | median 65 live ticks | live: median 2, 95th percentile 2. On `S.tick`: median 3, 95th percentile 8; 64.1% inside 4 | |
| Blows a second against taps a second, 5 to 10 taps | | 5.02 against 5.00, up to 10.00 against 10.01 | within 10% |
| A flurry's damage a second across tap rates | | 49.8 to 49.9 at every rate | within 10% |
| Nothing running, pressing player against the medium AI | 13.4 s a minute | 5.6 s a minute | toward 12 |
| Nothing running, AI against AI | 20.9 and 21.5 s a minute on two sets of seeds | 18.1 s a minute | toward 12 |
| A brawl's median length and blows, pressing player | an exchange of 2.3 blows | 3.7 s and 64 blows | toward 6 to 12 s; 10 blows or more |
| A brawl's median length and blows, AI against AI | | 1.8 s and 15 blows | the same, by B5 |
| Share of live time in a brawl | | 53.9% pressing player; 18.7% AI against AI | 45 to 60%, by B5 |

- Against the medium AI 36% of his presses arrive while he reels, and are held for the reel. That is why 64% and not 95% make contact inside 4 ticks.
- 40% of the blows in those matches were thrown while the rival's own blow was due within 2 ticks of theirs: a trade, and both land.

**The run and the trade** (Game Design's rows; QA's lights-only mirror, and my scratch probe of two mashers who fly in and tap on the same ticks).

| Row | Reads | Band |
| :--- | ---: | :--- |
| The lights-only mirror finishes | 60 of 60 (QA's); 20 of 20 (mine) | at least 95% |
| Lights-only mirror, brink to KO | 34.2 s (QA's); 33.0 s (mine) | 30 to 55 s |
| The brink fighter's share of closes, while only one is on the brink | 43.1% of 51 closes | 35 to 65% |
| The longest trade | 132 ticks on the director's clock, with the limit at 120: at the limit it breaks, and the close comes with the chosen fighter's next blow that lands | none past the limit |
| Set-up progress when the fighter on the brink wins a close | It is wiped, as for any decisive win of his (`DirExchange._winCloses`). It happened once in 136 closes by a fighter on the brink | |

How the two levers were set, in Game Design's order: the trade's limit at 90 ticks read 23.4 s brink to KO; at 120 ticks, 26.7 s; then the close's set-up weight at 0.34 read 28.8 s; at 0.25, 34.2 s.

**Three findings.**
- **In an even mash the closes aren't shared.** The first lead persists: a close's stagger gives the closer one or two free blows, and each even exchange of blows leaves the lead where it was. My two mashers gave 943 closes to one and 41 to the other over 20 matches, and the same slot won 16 of them. QA's mirror, where both stand and tap on live ticks, splits its matches 36 to 24.
- **The faster tapper closes, so a real-clock presser beats the medium AI.** My probe's player taps every 8 ticks and the medium AI every 10: all 1000 closes were his, and he won 16 of 20. Before B1 he won 7 to 12 of 20. QA's masher stands still and taps on live ticks, which is slower on `S.tick`, and reads 45 of 100. The medium AI's tap gap is the lever Game Design named: at 9 the masher read 31 and 33 of 100.
- **Section 9c's answer rule is built and not switched on.** With it on, the hard AI guards every time two paced blows land, and without the parry a guard only costs it: QA's masher against hard read 15 and 17 of 100 against 1 without it, and AI matches ran 30 to 90 s longer. T8 can't be read until B2.

**Gates.**

| Gate | Result |
| :--- | :--- |
| Goldens | Regenerated once. B1 changes how every AI match plays, and the data hash changes |
| `render/tools/determinism.gd`, `loader_check -- 200 1`, `seam_sweep`, `cue_check`, `anim_check`, Controls' four input tests, `mash_probe` | Pass |
| Validate, with Tools' `apply-brawl1.cjs` applied in scratch | 157 files, 0 errors, 0 warnings. Self-test 4161 of 4161, exit 0 |
| `npm test --prefix sim`, in the tree | **4 of 5.** The Godot stage fails on two checks of `sim/core/tools/parity.gd`, which is Simulation's. Its matches and its human-input replays reproduce |
| The same with the three-line change below, in scratch | 5 of 5 |

**The two checks.** Both assume how one seeded AI match unfolds.
- "None in a default match" steps seed 5 for 600 ticks and expects no shot in flight. The AI does fire in that match: at step 2297 on HEAD, after the window, and at step 411 with B1.
- "The new fields travel" holds the stance mask on fighter 0 for 240 ticks of seed 31 and expects it on his input on every tick. With B1 the AI's flurry closes on him at tick 99, and Simulation's own rule that a stun ends the held stance states clears them for 24 ticks.

The proposed change is parked as `docs/director/pending/brawl-b1/parity-patch.cjs`: the first check runs a match where nobody presses, and the second skips the ticks on which he was stunned as the step began. It isn't applied: the file isn't mine.

## 6. Not in B1

Skill strikes and the beat point (B2). The set guard, the lift and the juggle, and three blows stopping a wind-up (B3). Struggles, and two heavies meeting (B4). The AI leaving, sidestepping and bursting, and the bands for brawl share and length (B5). The stick's damped walk. A form is taken when the brawl ends, as it waits for an exchange's end today.
