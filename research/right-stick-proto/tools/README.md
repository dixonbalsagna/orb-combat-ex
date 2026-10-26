# Right-stick v2: the review harnesses

Research's review checks for the right-stick prototype, moved from the review scratch into the repo (2026-10-26) so the Godot port can run the same checks against its own sim. They hold the sim to the no-claw law: `docs/design/rulings-2026-10-26.md` §2b items 13 to 16, `docs/design/right-stick-pitches.md` §13 (R28 to R32b), Controls' `docs/controls/right-thumb.md` rule 3 and the claw-bot gate (`docs/controls/claw-bot-gate.md`), and `docs/design/energy-overhaul.md` E3. Plain node, no dependencies, CommonJS.

## The sim they load

Every script finds the repo from its own folder and loads `docs/ep/prototypes/right-stick-v2.html` between its `// ==== STICK SIM (no DOM) ====` and `// ==== PAGE (DOM) ====` markers. Point them at another copy with `RS_SIM`:

```
RS_SIM=path/to/copy.html node research/right-stick-proto/tools/all.js     # a copy with the markers
RS_SIM=path/to/export.js node research/right-stick-proto/tools/gate.js     # a .js that ends by defining S
```

The timing checkers patch nothing. They read the sim the way a player's debug view does, so a port's JS export can be checked unchanged if it keeps:

- **The API:** `S.CLIPS`, `S.newRun`, `S.stepRun`, `S.draw`, `S.clipLen`, and a clip whose take's `setup(w)` and `input(w)` drive both fighters.
- **The debug feed:** `w.rd.log` with the prototype's note texts (`FLICK UP: LATCH HIGH`, `X QUEUED`, `QUEUED X STARTS`, `FLICK DROPPED`, and the rest).
- **The fighter's fields:** `P.cmd`, `P.pend`, `P.bchg`, `P.beam`, `P.seq`, `P.blow`, `P.cross`, `P.commit`, `P.dodgeT`, `P.caught`, `P.q`, and the timeline marks `P.tl`.
- **The flicker in his hand:** an `ack` entry in `w.fx`.
- **The recognizer's state:** `w.rd.on` and `w.rd.dpOn`, and the fighter's event sources `P.evSrc`, `P.holdSrc` and `P.relSrc` (`'stick'` or `'pad'`).

`fuzz.js`, `cliff.js` and `settle.js` also patch the source (`CLIFF_HOOKS` in `harness.js`). The patch exposes the internals and logs every `rock()` and `bound()` call. A hook that is missing stops the run and names its anchor.

## The reference model

**A standard one-thumb player.**
- The right thumb is on the face buttons or on the right stick. It takes `L` = 6 ticks to move either way, counted from the press's last tick down or from the tick the stick is back at rest.
- The left thumb has the left stick and the D-pad, and can use them at any time.

**What follows for every grip.**
- **Stick, then press.** A press made inside a stick command's commitment starts at the commitment's end. A flick commits for `L` from its act, a lunge for its rush, a hold until release + `L`, and the brawl's cross-up for its arc. A beam sweep commits nothing.
- **Press, then stick.** A stick input made inside a face press's commitment waits and acts on the tick the commitment ends (items 13 and 16). That end is press + `R` = 8 (Controls' rule 3 and gate G): the fastest standard thumb reaches the stick at press + 6 and its flick settles 2 ticks later. The same goes for a D-pad tap, which the left thumb can make at any time. So press + 8 is the floor for every grip: a claw and a fast one-thumb both act on it. A hold still counts its 10 ticks from press + `L`.
- **Holds.** A hold counts its 10 ticks from the commitment's end, plus 3 when a slow gesture left rest inside it.
- **Reads.** The D-pad acts 2 ticks after its onset. The stick's flick acts 2 ticks after it crosses (item 15).

**Where the law is silent, the prototype's own README rules apply.**
- A held B counts from its last tick down, or from the tick it fires if RB's release fires it with B still down. A queued B follows its own press: a later B press is not its hold. A charge a catch drops keeps the thumb on B until B comes up.
- A press queued inside a right-stick commitment counts from that commitment's end. One queued inside a D-pad command's commitment counts from its press: the D-pad is the left thumb's.
- A press queued with the right stick out counts from the stick's next act or release + `L`, or from its own start if it starts first. The D-pad held down is never "the stick out".
- The sim tells the stick from the pad by its events' source (`P.evSrc` for a flick that acts, `P.holdSrc` for a hold, `P.relSrc` for a release; a waiting flick keeps `P.pend.src`). A port's export must keep these too.

**Expected outcomes, not losses.**
- `FLICK DROPPED` and `FLICK REPLACED`, when the newest input wins with a flicker.
- A queued press that lapses after `W` = 36 ticks.
- Refusals by R28: a press under way, a charge, or a beam that roots him.

**What counts as a breach.**
- A result earlier than the law allows, for any grip.
- A one-thumb input that is lost, or acts later than the law says.
- Anything silent: a dropped or cancelled input with no flicker, or a press that does nothing.

The law's numbers live in `harness.js` (`LAW`), taken from the law's documents rather than the sim. A sim that changed `L` would fail the gate, not move it.

## The scripts

The times below were measured on Orb's PC at below-normal priority, against the 2026-10-26 build. Every script lowers its own priority, as the rule for long runs asks.

| Script | What it checks | Run | Time |
| :--- | :--- | :--- | ---: |
| `all.js` | The fast set: the gate, the three sweeps at their quick size, 1000 chains, 1000 one-thumb runs and a short fuzz. Exits 1 on any breach. `--cliff` adds the cliff and settle sweeps | `node tools/all.js` | 27 s |
| `gate.js` | The claw-bot gate's named cases, each against the law's own tick: A (stick then press), C (a press during a hold), G and I (press then stick, with the stick and the D-pad at once), H (newest wins, nothing silent), F (the stick against its D-pad mirror), M (the stick and the D-pad a tick or three apart), and the earlier rs-gate cases | `node tools/gate.js [-v]` | 1 s |
| `press-stick.js` | A press of every kind, then a stick or D-pad command of every family, gesture and direction, its onset swept across the press's commitment (EARLY, LATE, LOST; from sweep3b) | `node tools/press-stick.js [--quick]` | 15 s (10 s) |
| `stick-press.js` | A stick or D-pad command, then a press of every kind at gaps -3 to 8 after the thumb leaves the stick. The commitments are read from the run's own stick events (EARLY, LATE, SILENT; from sweep4) | `node tools/stick-press.js [--quick]` | 11 s (6 s) |
| `queued.js` | A press that waits in the queue, then a stick or D-pad gesture. It checks the queued press's own commitment on the stick, and that the press still waits out the stick's (from sweep5) | `node tools/queued.js [--quick]` | 11 s (6 s) |
| `chains.js` | Random chains of three or four inputs at tight claw gaps, against a rival who may strike or grab, held to `lawCheck` (from chain5b) | `node tools/chains.js [count] [seed]` | 1 s for 3000 |
| `one-thumb.js` | Random legal one-thumb play, looking for what one thumb loses: `lawCheck`, DEFERRED (a right-stick flick that waits, which one thumb never should), WAIT OVER (a D-pad tap that waits past the commitment's end), NOT DROPPED, and LOST (a flick or tap that leaves nothing, with its likely cause) (from ot.js) | `node tools/one-thumb.js [count] [seed]` | 1 s for 2000 |
| `fuzz.js` | The Play-mode fuzzer. 16 input mixes (from fuzz2 and fuzz5) against the rival's Play script or a rival driven at the cliff. Every tick is drawn through a checking stub, and it checks invariants, the cliff's steps, determinism, and the law's acks and waits. It also plays and draws every clip (from fuzz6 and rs-fuzz2) | `node tools/fuzz.js [mix\|all] [seeds] [ticks] [seed0]` | 92 s for all 20 4000; the default 50 4000 is about 4 min |
| `cliff.js` | The cliff sweep: every command family near the face and the top, each step against its own move's step (from csweep). The cliff's geometry, not the law | `node tools/cliff.js [stride]` | 22 s (stride 1) |
| `settle.js` | The settle after an orbit by the cliff: no fling over 15 px. Geometry, not the law | `node tools/settle.js` | 3 s |
| `harness.js` | The shared part: the loader, `run()` (a scripted take, read back as events), the input builders, `commitments`, `faceRefs` and `lawCheck` (the law's checks over any run), and the checking stub renderer | | |

Commands are shown from `research/right-stick-proto`; the scripts find the repo from their own folder, so any working directory will do. Run `all.js` before and after any change to the prototype's timing. Run the full sweeps and `fuzz.js all 20 4000` before a review report. The port's parity run is `RS_SIM=<its JS export> node tools/all.js`.

## Reading the output

Each checker prints one line per class of finding: the count, then the class, then up to two examples on the lines below it. It closes with `<name>: <cases> cases, <n> breaches`, and `all.js` ends with a summary table. Classes marked `info`, `ROOTED`, `refused`, `slow claw` or `SLOW` are counted but are not breaches. In `cliff.js`, the "tween ends short" and "close ends near" lines are notes.

The examples end with the run's event line, for example `20P:BOLT 22W 26S:FLICK_UP:_LATCH_HIGH(waited)`. Each event is a tick followed by its code:

| Code | Event |
| :--- | :--- |
| `S` | A stick or D-pad command acts. `(waited)` means it came off a wait |
| `S-` | A flick is read and refused (press under way, charging, nothing in step 1) |
| `H` | A hold starts (its command) |
| `Z` | A release; `Z-` is a release with no command running |
| `K` | A hold ended by something else |
| `P` | A press starts (its kind) |
| `Q` | A press is queued |
| `R` | A held B is let go and fires |
| `W` | A flick begins to wait |
| `D` | A waiting flick is dropped or replaced (with its flicker) |
| `C` | A waiting flick is cleared with no flicker |
| `LT` | A slip |
| `U` | A beam pulse |

The scenario before the event line gives the positions as `P x,y V x,y` and the inputs as `kind@tick`. That is enough to rebuild the case with `harness.run`.

**How we know the checks bite.** Seven deliberate regressions of the sim were each run through `all.js` with `RS_SIM`: no reverse commitment, an extra tick on the wait, the D-pad 2 ticks early, a commitment of 2 ticks, no `FLICK DROPPED`, a silent `FLICK REPLACED`, and no lockout after a hold. Each one raised the gate's count above the build's own 21 (to 275, 273, 286, 67, 23, 22 and 45), and the sweeps rose with them.

## Red on the 2026-10-26 build

These are the breach classes that are real and reported to the EP, so a port knows which red is expected:

- **The stick's quick flick.** A 1-tick flick reads 1 tick after it crosses, one tick ahead of the D-pad and of item 15 (gate F).
- **The stick and the D-pad together.** Within about 3 ticks of a D-pad tap or hold, a right-stick flick is lost, because the recognizer reads one device at a time (gate M, `one-thumb` LOST).
- **One tick of rest.** A flick made after a single tick of rest keeps the family of the gesture before it (`one-thumb` LOST).
- **The shoulder let go.** A waiting read or aim flick whose shoulder is let go before it acts is cleared with no flicker. So is a slip that cancels a waiting flick (gate H, `chains` and `fuzz` SILENT).
- **A press that queues.** It does not drop the waiting flick; the flick acts and holds the press back (gate H, `one-thumb` NOT DROPPED).
- **A ranged X on the act's tick.** It wins over a flick that is not toward; the flick waits and is refused (gate A, same tick).
- **The arc's last tick.** An energy press made on the cross-up arc's last tick fires on that tick, one tick before a queued press would (`stick-press`, `chains` EARLY PRESS).
- **A held B let go in the queue.** It counts from its press, not its last tick down (`queued`, `chains` and `one-thumb` EARLY STICK).
- **A press counted from a later tick.** The README's counting rules also fire on the left thumb's D-pad, and on stick acts made after the press, so one thumb's next stick or D-pad input waits up to about 10 ticks past press + `L` (`one-thumb` DEFERRED and WAIT OVER).
- **The cliff.** The wall run's start still snaps him up to 16.6 px to the face with no `rock()` call (`cliff`, `fuzz`), as the earlier sweep found.
