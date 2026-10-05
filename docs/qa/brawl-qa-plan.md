# QA for the brawl: the scripts, the three new rows and what QA needs from the build

Owner: QA & Balance. Date: 2026-10-05. Status: a note, nothing built, nothing run. Read: `docs/director/brawl-plan.md` (sections 4 to 6), `docs/design/melee-press-feel.md` (sections 1 to 9, 11), `docs/qa/timing-edge-plan.md`.

## 1. What carries over from today's harness

| Today | In the brawl |
| :--- | :--- |
| `players.gd` scripted players (masher, holder, tapper, mixes), the `waited` patch, the director's own beat read (`DirAlchemy` BEAT0), `follow` of chain links, the struggle presses | Kept. The tapper's oracle (steps to my own pending blow, as `DirAlchemy._blows` counts) has to be re-pointed at the brawl's own beat point (below) |
| `masher.js` pairs and rows (masher by level, bolt-only, blasters, blur locks, lights-only mirror) | The standing rows every slice holds (plan section 4): masher vs medium 35 to 50%, timed vs plain 62 to 82%, bolt-only 20 to 40%, blasts 10 to 25%, median to 480 s. The blur-lock rows retire when the blur does (B1) |
| `records.gd` per-match records and `bands.js` rows | New fields for the three rows (section 3); the chain, exchange-ending and launch-share rows are re-read as "per string" once strings replace exchanges |
| Timing-edge T, E, F and mirror plans | T1 to T10 are the brawl's B2 rows. The flow plan (F) is the one that matters for the skill strike: it is the plan that can see whether the flow gate binds |

## 2. Scripts that brawl

All are specs of `players.gd` (`kind:key=value`), seeded and deterministic, run through the real input path as a v2 human slot like the others. Each is one small block in `decide()` and `_match()`; none touches sim/.

| Script | Spec | What it does | What it measures |
| :--- | :--- | :--- | :--- |
| **Tapper at a rate** | `masher:rate=5..10` (taps a second; today's `gap` in ticks, 6 to 12, with `rate` as an alias) | A light every 60/rate live ticks, held through a freeze with `waited` | Flurry blows a second against taps a second (within 10%, 5 to 10 taps); flurry damage a second across rates (within 10%); press to contact for a mash blow (2 ticks, 95% inside 4); presses that become a blow in 10 ticks (95%) |
| **Beat player** | `tapper:acc=..:win=..` (exists) with `beat=own` | Presses on the fighter's own beat point (the spec's 20 to 28 tick point of the blow he is throwing), with an accuracy and a window; off the beat on a draw | Skill press to contact (6 ticks, 95% inside 8); timed vs plain (62 to 82% from B2); the lapse into the flurry on a miss |
| **Guard-sitter** | `guard:hold=20..60:rest=..` | Holds guard (the guard intent) for 20 to 60 live ticks at a time, then rests, and answers a heavy's wind-up with a press of guard at the last ticks when `perfect=1` | A heavy on a set guard breaks it, 95%; a blocker knocked back by a blow, never (hard test); a masher against a guard-sitter is not a stalemate; the AI's guard share |
| **Heavy-only player** | `masher:kind=H:gap=..` (a heavy every gap ticks) and `holder` (hold to the flash and past 46 ticks) | A tapped heavy, and a held-to-full heavy | A lone heavy lifts (a tap), launches at full hold only with the stick (at most 10% of launches); an ender stopped by three clean blows in its wind-up (at most 40%) |
| **Juggler** | `juggler:acc=..:win=..` | When the rival is lifted (state `lifted` or the juggle flag), presses skill strikes on his beat points; bursts out when it is the one lifted (a press of the dodge/burst input at a set tick of the juggle) | Skill hits per juggle (a mean of 2 to 3.5, five at most); a full juggle's damage against two four-hit timed strings (75 to 90%); juggles ended by a burst (20 to 40%) |
| **Zipper** | `zipper:band=mid` (later, with the zip) | Starts a mid lunge on a draw and takes the follow-up | The zip table (clean 35 to 55%, countered 10 to 25%, zipper caught 20 to 35%, ki share at most 25%) |

The masher, timed, holder, blaster and mirror scripts stay as they are so every slice is read against the same ones.

## 3. The three new rows, and how each is measured

### Seconds a minute with nothing running

**Definition (needed from Game Design or Encounter):** a tick is "running" when either fighter is in a blow (wind-up to recovery, both lines), a blast or a charge, a lunge or a zip, or a taunt; a flight after a launch counts as running. `maxPlayGap` today reads a gap in events (no strike, blast, charge or taunt from either fighter) and reports a share of matches under 10 s; it does not give seconds a minute. **QA measures it from state, once a tick,** so it does not depend on which events exist: `busy = DirBrawl.busy(S, f0) or DirBrawl.busy(S, f1) or ...` (a function the build provides, see section 4), accumulating idle seconds per fight minute, and split by the band the fighters were in (close band, 3 bh or less). Rows: seconds a minute overall (B1: toward 12; B5: at most 12), inside the close band (B5: at most 6; spec section 9: at most 6 inside a brawl), per match as a median and 90th percentile.
**Before:** B0 has to run it on today's build so the later slices have a before; I can do that with today's `S.dirS.ex`, fighter states and shot windows, as an approximation, and refine it when `DirBrawl.busy` exists.

### A brawl's median length

From `S.dirS.ex.kind == "brawl"`: start and end live ticks and the blows each fighter threw. Rows (B1: toward 6 to 12 s; B5: median 6 to 12 s, at least 10 blows), the share of fight time in a brawl (45 to 60%), the median string length and the juggle length. Needs `brawl_start` and `brawl_end` events (with the end kind: knock-back, launch, ender, finisher, guard-break, separated) or the exchange fields at the end.

### Press to contact

Per press, in **real ticks and live ticks** (the plan's own risk: hit-stop eats the brawl): the tick the press was consumed (the scripts know it: the step it went through, less `waited`) to the tick of the blow's contact (the first damage or contact event of that blow by the presser). Rows by kind: mash blow 2 ticks, 95% inside 4; skill strike 6, 95% inside 8; heavy 34; held heavy 8 after the release; presses that become a blow within 10 ticks, at least 95% (a press that cannot be honoured is reported by its state: held, reeling, knocked back). Needs a `blow` event per blow: actor, kind (mash, skill, heavy), the press tick, the contact tick (or `blow_start` and `blow_contact`), and for a press that is not a blow, a `press_ack` with the reason.

## 4. What QA needs from the build (a list for the EP to route; none of it is QA's to write)

| From | What |
| :--- | :--- |
| Encounter / Simulation | **Events** (all optional extras to the plan's section 2.7): `brawl_start {n, A, D, dist}`, `brawl_end {n, kind, blows: [a, d], ticks}`, `blow {actor, kind, press_tick, contact_tick, dur}`, `press_ack {actor, why}` for a press that is held or refused, `juggle_start`, `juggle_hit {n}`, `juggle_end {kind: ender, burst, drop}`, `guard_break`, `stagger`. **A read for state:** `DirBrawl.busy(S, f)` and `DirBrawl.beatAt(S, f)` (the live tick of the fighter's own beat point for the blow in flight, or -1), so the beat player presses against the director's own count, as the combo and blur scripts do against `_blows`. **A press log** (`BEAT0` today) that records the brawl's own beat distance |
| Game Design | The definition of "nothing running" (above). Which presses count in "became a blow within 10 ticks" (a press in a freeze, a press while knocked back). Whether press to contact counts hit-stop |
| Controls | `waited` confirmed for presses that arrive through hit-stop at ten blows a second (the plan's own risk) |
| Tools | Schemas for the brawl's data block and the new events, so `selftest` and the records read them |

## 5. How each slice is measured (one change list per slice, as now)

1. **B0** (before anything changes): the three rows on today's build (idle seconds a minute, close-band share, exchange length as the brawl's stand-in, press to contact for mash and skill presses by the scripts), by the same eight arms and the player rows, so every later slice has its before. No scripts needed beyond today's masher at a rate, which is already `gap`.
2. **B1** (first brawl): the standing rows first (masher vs medium 35 to 50%, length to 480 s, blasts 10 to 25%, bolt-only 20 to 40%); then the rate sweep (5 to 10 taps: blows a second and damage a second within 10%), the mash press to contact, the 95% in 10 ticks, nothing-running, the brawl's median length. The masher is where the plan's own risk sits (63 of 100 with a shorter cooldown and an AI that stayed in), so the masher against all three levels at 100 is read before anything else.
3. **B2** (skill strikes): the beat player and timed vs plain (62 to 82 on the brawl's rules); skill press to contact; the lapse into the flurry (a miss is a flurry blow within a set number of ticks). T1 to T10 and F1 to F6 re-read: the F plan's "launches wait on the flow" question is answered by the brawl's own rules.
4. **B3** (heavy): the heavy-only and guard-sitter scripts; a heavy on a set guard 95%; a blocker never knocked back (hard test); the juggler's rows; lone heavy lifts, a held heavy launches only with the stick (at most 10% of launches; the launch share stays in 25 to 40%, now at 40.6% on 9fcdf87, so this one needs a before).
5. **B4 to B6:** the struggle rows (one in 20 s, never started by a light, flurry blow or skill strike: a hard test), Blow for Blow, the AI's rows (share of fight time in a brawl, median, nothing running), the stances' rows from section 10 to 13, signatures, the zip table.

## 6. Standing items the brawl changes

- **Goldens and the harness.** Every slice from B1 regenerates the goldens; QA's rows are read on a clean export of the slice's commit as now (`QA_GODOT_ROOT`, `QA_SIM_COMMIT`).
- **The scripts' own oracle.** The tapper's timing today is the director's contact ticks (`_steps_to`); the brawl has no beat list for ordinary blows (plan section 2.1), so the beat player needs `DirBrawl.beatAt` or the plan's per-blow beat fields; without it the script presses against a guess and its on-beat share drifts again (it was 56% before the oracle, 85 to 100% after).
- **The lights-only mirror, the blind masher and the metronome rows.** The blur's cadence and lock disappear in B1; the rows that count blur locks (section 20) retire with them, and the mirror and masher rows re-base to the brawl's bands (`agency-pass.md` section 13 and 23, and this spec's section 9).
- **The sample sizes.** Timing rows are 40 matches and carry an interval of about 15 points; the mirror rows at 200 showed it. The brawl rows are per-blow or per-minute counts and are tight from 100 matches; the player rows stay at 100.
- **Machine.** Scripts at most 3 jobs, headless, as now; the rate sweep (6 rates) and the guard, heavy and juggler pairs are about 12 pairs of 100 matches, about 90 minutes at 3 jobs.

## 7. The timed script under the brawl (planned; not built: Encounter's B1 code has not landed in a report)

**What broke.** The tapper plans every press from `S.dirS.ex.beats` (a strike beat's contact tick, as `DirAlchemy._blows` counts it) and refuses to press during an exchange when it has no planned blow (`decide()` presses at idle only when `S.dirS.ex == null`). Inside a brawl the exchange object has no strike beats of its own for ordinary blows (brawl-plan section 2.1: "no beat list of its own except for set pieces"), so `blows` is empty, the tapper presses nothing for as long as the brawl holds, and "timed against plain" reads 0 of 40: a blind script, not a result. (A timed player who presses nothing loses to a masher.)

**What it should key on instead of the beat list** (in this order; the first that exists is used):
1. **The director's own read of the fighter's beat point,** `DirBrawl.beatAt(S, f)`: the live tick of the beat point for the blow he is throwing (the spec's 20 to 28 ticks after the blow starts, set by the piece), or -1 when there is none. The script presses at `beatAt + offset` with the accuracy and window it has today, as it presses against `_steps_to` now. This is the same oracle as today's (the director's own count), so the on-beat share keeps its meaning (85 to 100% from acc 80 to 100) and is read from the same place (the press's graded beat in the director's log). It needs the read from Encounter (requested in section 4).
2. **The fighter's own `blow` events** if the read does not exist yet: the script remembers the tick its own last blow started (`blow {actor, kind, press_tick, contact_tick, dur}`) and presses at that tick plus the beat point in ticks. The beat point is data (Combat's piece, 20 to 28), so it is read from the piece named in the event, not guessed. A drift check follows: the share of presses the director graded on the beat (`BEAT0`, as `directorOnBeat4` does today) has to be at least 70% at acc 80, or the row is reported as "oracle off".
3. **Never silent.** With neither, the script falls back to a plain mash at its idle rate and the row is marked "not a reading" (a script that cannot see the beat reads as plain, which is what it is). The harness already refuses to report a win share for a scripted player that pressed fewer than 100 times a match (`SCRIPT BLIND` in `timing-edge.js`, added now), so a script that loses its beat source can no longer produce a quiet 0 of 40.

**Roles go away.** The script's `mine = "A" or "D"` (which side of the exchange) has no meaning when both fighters have a line. It keys on its own slot: the blows it throws (`blow.actor == slot`), the presses it makes, and, for the defender's side of a timed answer (perfect block, tech), the rival's blows (`blow.actor != slot`) with their `contact_tick`, so a guard-sitter and a timed answer press against the incoming blow's contact.

**The struggle presses** (`_struggle_press`) key on the contest beat's `sOpen` and the struggle's `beatTicks`, which are on the set-piece beats the brawl keeps; they do not change.

**Verification before it is trusted:** run it at acc 100, win 0, jit 0 (the contact script) against the medium AI: on the beat 100% by the director's grade, blur locks 100% while the blur exists (B0); under B1 the skill strike's lock is the row; if the contact script is not at 100% on the beat the oracle is wrong and nothing built on it is read.

## 8. Hard caps: a run cannot hang (added with this note)

A mirror under B1's first close rule ran to the 900 s cap in every match and hung the harness for 97 minutes. Every Godot runner now ends itself, and the Node side kills what does not:
- `--capsec` (sim seconds a match may run, 900 by default) was already there in `players.gd`, `masher.gd` and `records.gd`; `downtime.gd` is fixed at 900.
- **`--wall=<real seconds>`** (default 300) ends a match as a timeout after that much real time (`wallCapped` in the JSON of `players.gd` and `masher.gd`, `rec.wallCapped` in the records, and the same 300 s in `downtime.gd`).
- **`--budget=<real seconds>`** (default 3,600; 5,400 for `records.gd`) stops starting matches after that long; `players.gd` and `masher.gd` report `n` (run), `requested` and `budgetStopped`, and `records.gd` writes the short list and the runner (`runRecords`) rejects a batch that comes back short.
- `qa/godot/godot.js` `guard()` kills a child and its engine process by PID after `QA_PROC_MS` (default 100 minutes) and says so; it wraps every spawn in `godot.js`, `masher.js`, `timing-edge.js` and `feel.js`.
Checked with a 6-match masher mirror at `--wall=4 --budget=15` (one match capped, all six run), the masher at `--wall=3 --budget=10` (four of six run, budgetStopped) and `records.gd` at `--budget=4` (two of five records, both wall-capped).

## 9. Built (2026-10-05, on e6f51bd; see docs/qa/brawl-rebase.md)

Section 7's plan is built: the tapper presses inside a brawl against `DirBrawl.beatAt` (loaded dynamically; outside a brawl the old oracle stays), with a `mingap` of 14 ticks and the same accuracy and window; B2 turns `beatAt` into the beat point and the same code reads it. The brawl events are read by `players.gd` and `records.gd`; the rows are in `masher.js` (the mirrors) and `bands.js` (the re-based rows).
