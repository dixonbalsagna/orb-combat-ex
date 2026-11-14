# The two signatures: the build spec for the third milestone

From Orb's stand-in, 2026-11-14, for the EP, then Game Design, Controls, Encounter and Combat. **Design only: nothing here is built or decided.** Every number is a first value kept in data, and Game Design rules on numbers. Code references are to main at 781a82ac; main's fight code is the code of the 9 November build Orb played, and only data switches differ (noted wherever "today" differs between the two). The tables come from a small model (`sigmodel.js`, re-run after the review as `sigmodel2.js`, in the stand-in's scratch folder), not from a Godot run. Where this page departs from a recorded ruling, the place is in section 4. How the page was reviewed, and what changed, is in the last section.

It builds on, and does not repeat: Game Design's rulings on the beam trial (`docs/design/beam-physics.md:101-115`, 2026-11-14), the stand-in's beam page (`docs/ep/proposals/beam-in-space-trial-design.html`), Game Design's energy, stamina and body page (`docs/design/energy-stamina-body.md`), the six workshop items (`docs/design/workshop-six.md`), the gravity well's rulings (`docs/design/gravity-well-reading.md:55-67`) and flight at 3,500 (`docs/design/flight-3500.md`).

**Is there a ruling on the signature in space?** One line: "The signature joins the beam in space at its top stage, with the inputs Orb named (RT + RB + a flick for the energy signature). It goes in A-COMBAT-02 (GW2), so it isn't the one beam that still finds you" (`beam-physics.md:115`). Nothing is ruled on its tell, cost, limit, aim, damage, or on the martial signature at all. Each of those is designed here to the stand-in's beam page and listed as an open ruling in section 3.12.

---

## 1. In plain words

> "RT + RB  + 'Flick Right Stick' is the signature energy move, RT + 'Flick Right Stick' is the signature martial move" (Orb, 2026-11-09, `docs/ep/vision.md:1710`)

- **Hold RT and flick the right stick: your martial signature.** Your fighter coils for half a second with their aura flaring, then rushes the rival at the speed of a dash, and if the rush touches them it plays a short string of blows that ends by sending them flying. At base the rush is a little faster than anyone can fly; at higher forms it is exactly as fast as a rival of the same form can fly. Either way, a rival who flies off the moment you coil gets away, and one who waits too long is caught.
- **Hold RT and RB and flick the right stick: your energy signature.** Your fighter stands still and gathers for half a second, then fires your biggest beam along the line you flicked. It is a real beam in the world: it can miss, and the rival can fly out of its way. Let the stick go and the line is set where you flicked; keep the stick pushed out and it keeps aiming until it fires.
- **RB can land a split second after the flick** and it is still the energy signature. The price of that grace: the martial signature starts a split second after its flick.
- **RT held still charges your energy.** A flick while you charge throws the signature straight out of the charge. If you cannot pay for it, the pad knocks, a word says "No energy", and your charge carries on.
- **B never fires a signature or a beam again,** with any shoulder button. RT + B from the last build is gone. (The beam that fired after you pressed face buttons was a different fault: a beam you had let go that waited and fired late. Its fix is separate and lands before this.)
- **A signature never grabs the rival from a distance.** They keep their own stick the whole time you gather and rush. They can fly away, dodge through it, block it, or hit you first. The string of blows holds them only once your rush has touched them.
- **You are the one who is committed.** You cannot move or press anything else while you gather, a heavy blow or a grab stops you, and a miss leaves you open.
- **Each signature costs 45 energy, and 30 stamina once stamina is in the game.** Plain face-button blows earn the stamina back. Out of stamina, it costs more energy instead, up to 90.
- **No "recharging" refusal.** Throw a second signature within 15 seconds of your last and it takes longer to gather and hits for less, so it is easier to punish. It is never refused for a timer. (Until the new beam is in the game, the energy signature is still today's beam and keeps today's 15-second wait.)
- **The computer throws both the same way you do,** with the same warning, and it can miss.

---

## 2. Where things stand

| Thing | State | Where |
| :--- | :--- | :--- |
| RT + a flick, RT + RB + a flick | **Cannot be pressed.** With RT held the stance mask is 4, 4 is in `strike.inertMasks`, and the stick reader goes straight to "ignored" | `sim/input/layout.gd:1050`, `:1263`; `sim/input/strike_read.gd:173-174` |
| Telling the two chords apart | **Missing.** RT wins the stance and RB's `mode` is forced to 0, so both chords are the same intent | `sim/input/stance.gd:31-33`; `layout.gd:1008` |
| RT held | The energy charge after 12 builds; a locked fighter never charges; +30 energy a second is a number in code | `layout.gd:927`, `:1027`; `sim/core/fighter.gd:730`, `:758-769` |
| RT's burst | Fires on RT's press when the fighter is threatened, or on a tap released inside 12 builds | `sim/director/interrupt.gd:393-395`; `sim/core/act.gd:89-95`; `layout.gd:719-720` |
| The signature today | One per fighter, and it is a beam: every `sig` request is planned as a beam. In Orb's build it comes from RT + B only | `sim/director/exchange.gd:401-402`; `data/combat/templates.json:964`; `sim/director/brawl.gd:3178` |
| What it does to the rival today | Both fighters are set to "locked" at the press, before any tell. The rival moves only by their own stick in the tell, to a leash | `exchange.gd:363-364`; `brawl.gd:4260-4299` |
| The RT + B bug | **Still in main's code.** The keep-RT clause reads `f.state != "charging"`, so a fighter locked in a brawl fires the signature from RT + B at any time | `brawl.gd:3178`; found by QA, `docs/qa/runs/6a30b4c9/README.md:21-23` |
| Its 12-tick fix | **Parked, not in `sim/`.** It becomes moot when RT + B goes (section 3.2) | `docs/director/pending/stray-beams/README.md` |
| The other stray beam (the one Orb felt as "face buttons, no right stick") | **A different fault, and not fixed by removing RT + B.** A stick beam let go and held back fired 33 ticks later into a brawl, with RT not down. Its fix (`ownMove.dropOnPress`) is in the same park and is listed for an earlier window (GW1b). Even with it, a waiting release with nothing pressed still fires up to 90 ticks later, by design | `docs/qa/runs/6a30b4c9/README.md:17-19`, `:27`; the park's README, section 1; `docs/ep/sprints/A1-sprint.md:26` |
| A stale stick aim sending a signature wide | **Parked fix** | `docs/director/pending/beam-aim-throw/README.md` |
| The live limit | 15 s and damage x 0.6, marked provisional. It overrides each fighter's 120 s whenever the perfect block exists, which is always | `data/director/interrupts.json:225-228`; `sim/director/beam.gd:53-60`; `data/fighters/PROTAGONIST/fighter.json:14` |
| The price | 45, written as a literal in code in three places; `signatureKi` 45 exists in the input data but the director does not read it | `exchange.gd:281`, `:348`; `beam.gd:129-134`; `data/input/timing.json:28` |
| A martial signature | **Does not exist,** for either fighter. No request kind, no plan, no data, no cue | `exchange.gd:31` (`KIND`); the audit's row A-COMBAT-02 |
| The beam in space | **Not built.** A trial is running on a scratch copy. `DirBeamSpace`, the beam's `sv`, `hw` and `stage` fields and `beamPlays.space` are proposals from the stand-in's beam page | `beam-in-space-trial-design.html` sections 12 and 13 |
| The stamina loop | **Not built.** Paper, for the same golden window; switched on only after QA's comeback reading | `energy-stamina-body.md:10-13` |
| The gravity well and its snap | **Not built.** Paper, with Game Design's five rulings | `gravity-well-reading.md:55-67` |
| Pieces that exist for a martial signature | A rush that homes at a capped speed, re-aimed each tick (the chase). A blow that lands on a launched body and sends it on. Beat lists as data (`finRush`, `strike`, `launch`, `cue`). An exchange made with no template. The stick hold's armour hooks | `sim/director/chase.gd:228-265`, `:326`; `data/combat/finishers.json`; `sim/director/data.gd:442-448`; `exchange.gd:170-191`; `brawl.gd:1368-1373`, `:1451` |
| The computer's signature | `i.sig = true; i.stanceMask |= 4`, a B press no player has. With the hold-and-release switch on (`ownMove.ai`: off on main, on in the builds Orb played, by the review's reading of the kept build's data) it is a stick hold instead, and `aiStart` returns true every time the stick is idle | `sim/director/ai.gd:262-263`, `:276-277`; `brawl.gd:4121-4122`; `sim/director/beam_move.gd:143-158`; `data/director/interrupts.json:294`, `:303` |
| Names | One name key per fighter, `<ID>.SIG`; display names are placeholders. The rival's is a volley's name on a beam | `ui/data/fighter_names.json:5-6` |

---

## 3. The design

### 3.1 The input read

**Rule 1. The build on which the stick crosses decides,** as for every other grip (`strike_read.gd:171-178`), with one grace for RB (below). RT and RB count only if they are **physically down** on that build: `on_now` (`layout.gd:969`: down, or pressed this build), read before the two-build release grace (`:977-981`) and the one-shot stances (`:982-987`) are added to the mask. The resolved stance must also be 4, which is what keeps a pending transform chord out.

| On the crossing build | The strike's layer (`rsMask`) | It is |
| :--- | ---: | :--- |
| RT in, RB not in | 4 | the martial signature |
| RT in, RB in | 6 | the energy signature |
| RT not in | as today (0, 1, 2, 8 and the hybrids) | a plain strike, a beam, as today |

- **The stance itself does not change.** `stanceMask` stays 4 and `mode` stays 0 under RT, so the Driver, `isB`, the computer and every other reader of the stance are untouched. Only the strike's own layer carries the difference. `rsMask` already has four bits on the wire and accepts 4 and 6 today (`sim/input/intent.gd` `pack2`, `unpack2`), so **the packed intent, its version and the replay format do not change.**
- **Order.** RT must be down at the crossing. RT and the crossing on the same build count as RT (the shoulders are sampled first). A stick that crossed before RT went down is a plain strike (or, with RB, a beam's flick) and RT does not cancel it.
- **RB may arrive late** (a proposal; open ruling 16). Which signature is thrown is otherwise decided on one build, and three controls pressed "together" by a person land within a few builds of each other in any order; Controls already called this grip hard (`docs/controls/right-hand-attacks.md:74`). So: if RT is down and RB is not on the crossing build, the input layer holds the start back up to `strike.sigRbTicks` builds (first value 4, never more than `tapHold.chordWindow` 6). RB going down inside that time makes the layer 6 and the start goes out on that build. With no RB the start goes out as 4 when the time is up.
  - It uses what the reader already has: "the earliest tick the request may start", which the reverse lockout passes in (`floor_tick`, `strike_read.gd:153`, `:257-258`; the reader's waiting phase is "waiting for the settle (and for the law's floor)", `:25`), and the reader's `layer` field (`:37`). Read, not run.
  - **The cost, named:** every martial signature starts `sigRbTicks` builds after the stick crosses (4 builds, where the quick read starts every strike 1 build after today: 3 builds more, 50 thousandths of a second), while an energy signature with RB already down starts on the usual build. The gather is not shortened, so the rival's warning is the same 30 ticks. The other way to pay (take the wait out of the martial gather, so flick to rush is unchanged and the seen warning is 26 ticks) is the ruling's second arm.
  - **The release grace never makes or unmakes a signature.** RB let go a build before the crossing is not RB; RT let go a build before the crossing is not RT, and the stick is then inert and knocks "Charging" as today, because the stance mask still reads 4 for those two builds.
- **What already keeps it apart from other chords,** with no new code: a pending transform chord (LT + RT inside 6 builds) leaves RT's bit out of the mask (`layout.gd:989`), so the resolved stance is not 4 and LT + RT + a flick is never a signature. LB + RB with no RT stays the inert ward. A face press under RT drops RT's hold (`layout.gd:522-528`), so RT + X then a flick is a plain strike.
- **Known edges, named:**
  - **RT tapped, then a flick with RT up.** With the one-shot stance option on, a tapped RT arms the charging stance for 90 ticks (`layout.gd:726-734`; `timing.json:36`). Reading the button physically means that flick is not a signature. It stays inert, as today.
  - **The D-pad** is bound as the stick's mirror (`data/input/layouts.json:126-134`), so RT + the D-pad is RT + a flick. The audit's X-17 names "the right stick" and "the signature inputs Orb named" (`docs/ep/alpha/alpha-audit-specification.md:184`), and Orb named the stick. Whether the D-pad (and a keyboard's strike keys) may throw a signature is open ruling 17. First answer: yes, as for every other strike, and the count lists them apart.
  - **A flick up to `sigRbTicks` builds before a blow lands on the thrower** has not started yet. The blow lands on a fighter with no armour, and the start that follows is refused or taken as the state then allows.

**Rule 2. The flick is the start edge.** The signature starts on `rsStart`, one build after the crossing with the quick read on (`strike_read.gd:257-272`). The reader's hold still runs underneath (dwell 12), so **holding the stick is reserved** for the taunt Orb spitballed, which Game Design places after Alpha (`workshop-six.md:13`). For Alpha a held stick fires the same signature at the same time. The one difference is the energy signature's aim: a stick still out keeps aiming until the fire, and a stick let go has fixed the line at the flick (section 3.3, and open ruling 11). The gather is never shorter than 30 ticks, so a later taunt can read "flick or hold" inside the gather with no extra wait.

**Rule 3. RT held stays the charge, and a refused flick does not stop it.**

| Piece | Rule | Where |
| :--- | :--- | :--- |
| The tap | A chord's crossing voids RT's tap, so letting go of RT after a signature never bursts | input layer: a new `_tap_voided` beside `_power_voided` (`layout.gd:719`) |
| The channel | **Not voided by the input layer.** The director suspends the charge only while a signature of that fighter's is live. So a flick with too little energy knocks "No energy" and the charge carries on | one line in `fighter.gd:730` through `SimDir` (section 6) |
| A flick during the channel | **Counts,** first value. `strike.sigChordTicks` 0 means any time RT is held; 12 would mean only inside 12 builds of RT's press, the rule Game Design set for RT + B. Outside the window the stick is inert and knocks "Charging", as today. **The cost of 0:** a player who is charging and flicks the stick to hit a rival closing in throws a signature, where today that flick does nothing and knocks. In Game Design's own model the stick is "the right hand's plain blow" (`energy-stamina-body.md:30`), and Orb has reported a beam they did not mean (`vision.md:1683`). Game Design's earlier line for RT + the stick had no window ("Hold RT, then flick or hold the stick", `docs/design/beam-answers.md:13`). Open ruling 3, reading 15 and question 2 | `data/input/timing.json` |

**Rule 4. The burst waits for the chord.** Today RT pressed while threatened bursts on the press tick, before any flick can be read (`interrupt.gd:393-395`), which would spend 30 energy and shove the rival every time a pressed defender reached for a signature. With the switch on, a threatened press-burst waits `burstWaitTicks`. The director sees only the start edge, never the crossing, so the wait has to cover the latest start edge of a chord begun in time: the pad's own "are these one chord" number (`tapHold.chordWindow` 6) for the crossing, then the RB grace (4), which contains the reader's quick settle (1). **First value 10 ticks.** A signature's start inside the wait cancels the burst. With no start it fires at the end of the wait, or at once on RT's release, which is how a tapped burst already fires. An unthreatened RT press never burst on the press, so nothing changes there. If the RB grace is ruled out the wait is 7 (the draft's 6 left out the settle).

**Rule 5. What is refused, and with what cue.** No press is silent. Each refusal is the existing `stick_refused` cue (the pad's two dull knocks and a row for UI's word at the screen's edge), with a reason code that already exists.

| Case | Cue reason | UI's word today |
| :--- | :--- | :--- |
| Not enough energy | `ki` | "No energy" |
| Launched, down, stunned, or held by an exchange | `DirExchange.cantWhy`'s code (`exchange.gd:100-110`) | "In flight", "Knocked down", "Stunned", "Locked in"; "Busy" for anything else (`ui/data/terms.json:94`) |
| A second flick while your own signature is live; a finisher, a knockout or a struggle is playing | `set_piece` | "In a move" |
| **Any other press while your own signature gathers, rushes or pours** (a face button, the burst, a new stick strike) | `set_piece` | "In a move" |
| **On the interim path only** (section 3.3): a second energy signature inside the provisional 15 s | `cooling`, as today (`exchange.gd:288-293`) | "Cooling" |
| A flick outside `sigChordTicks`, when it is not 0; a flick in the two builds after RT is let go | `charging` (input layer, as today) | "Charging" |
| Switch off | as today: nothing on main, "Charging" in Orb's build | |

A signature that starts sends `stick_start`, so the hub's "No answer" knock does not fire (`sim/input/hub.gd:452`).

### 3.2 Only the intended inputs fire (the audit's X-17), and RT + B goes

- **RT + B is removed in the same build that turns the chords on,** as Game Design ruled (`docs/design/overnight-2026-11-08.md:36`). It is two data lines: `bNoBeam` true and `bNoBeamKeepRt` false. `isB` then returns true for every player's B (`brawl.gd:3178`), so RT + B is B's own heavy, and it drops the charge as RT + X does. The keep-RT clause and its known bug are deleted in the same change; the parked 12-tick fix is no longer needed.
- **The switch named `signatureRtOnly` means RT + B, not RT + the stick** (`tools/preview/switches.mjs:44`). It stays on: it is what turns B with any other shoulder into that stance's heavy.
- **After this, the only things that start a beam or a signature are:** RB + a right-stick hold let go (a beam); RB + a flick toward an incoming beam (the fire-back); RT + a flick; RT + RB + a flick. Beams spawned by a powerful block's split or swat, and a finisher's own beam, are not started by an input and are counted separately.
- **A beam that fires late is its own line in the count.** On the old path a released RB beam can wait for its target and fire up to `ownMove.maxWaitTicks` (90) later. That is the fault behind the beam Orb felt at tick 5220, and removing RT + B does not touch it. Its fix, `dropOnPress`, is the stray-beams park's and must land first (build step 2 needs it). Even then a waiting release with nothing pressed still fires late by design, so the check matches a beam to its thrower's release up to 90 ticks back and lists it as "fired late" with its delay, not as a stray. The beam in space has no wait at all (the beam page: "then it fires, never later").
- **The computer too.** Its `i.sig` press (`ai.gd:262-263`, `:276-277`; `brawl.gd:4121-4122`) is replaced by the same second-word fields a pad sends (section 3.9). One check then counts both (section 7).

### 3.3 The energy signature, as a beam in space

It is the beam of the stand-in's beam page, fired from a flick. **No exchange runs and nobody is held:** the rival is free from the flick to the end.

| | Rule | First value | Lives in |
| :--- | :--- | :--- | :--- |
| **Stage** | The fighter's own top stage right now: 2 at base, 6 at full power (`DirBeamMove.stageCount(f)`, `beam_move.gd:71-72`), taken at the flick | 2 to 6 | built |
| **Tell** | A fixed gather in place of the hold it skips, the same at every range: half that stage's hold, never under 30 ticks | 30, 30, 30, 33, 45, 60 | `signature.energy.gatherTicks` |
| **Speed, width, reach** | That stage's, as Game Design ruled them | 8,400 a second, hits within 110 units, reach 72 body heights at base; 18,000, 210 and 136 at the top | `beamPlays.space` (the beam page's block, with 6,000 + 2,400 a stage) |
| **Aim** | The flick's direction. **A stick let go fixes the line at the flick** (the stick's steadied sector at the release). **A stick still pushed out keeps aiming until the fire.** On the fire tick the line is snapped onto the rival only if they are then within the beam's assist angle of it, and it does not move after that | 15 degrees | `beamPlays.space.assistDeg` |
| **Damage** | The stage's own, but never less than today's signature. Worked out where the beam touches, from the beam's own stage and signature mark (section 6.2) | 138 a hit, 120 guarded, up to stage 3; then 161, 184, 207 | `signature.energy.minDamage` 230 (x 0.6) |
| **The shooter** | Planted from the flick: no movement, and every other press is refused with a knock ("In a move"), through the gather and then the stage's "stays lit" time counted from the fire. That is the beam page's own plant for an ordinary beam. At range the beam itself lives longer than the plant (its travel, then its lit time), so the shooter can be free while the far end still pours | 1.1 s at base, 2.5 s at the top; 1.4 s and 2.8 s when stale | computed: gather + `ownMove.lastsSec` |
| **Armour while gathering** | Lights never stop it and do `lightMul` of their damage; **mediums do not stop it, which departs from the recorded rule for a beam's hold** (section 4, row 18). A heavy, a grab, a beam, a launch or a stun stops it, and the gather is lost with nothing paid | from tick 0 | `signature.armour` |
| **Carving** | As a beam in space: along its real line, stopped by the ground, at its stage's carve. **There is no signature multiplier on a carve today.** The x 9 in data is for the point where two beams meet in a struggle (`struggleMeet`, off on main), and it will read the beam's new signature mark (section 3.8). Whether a signature's own carve gets a multiplier is open ruling 7 | none | `data/biomes/craters.json:27-30`; `sim/world/struggle_meet.gd:87-89` |

**How it differs from an ordinary full beam** (base fighter, model):

| | Full hold on RB (stage 2) | Energy signature (stage 2) |
| :--- | :--- | :--- |
| Input | hold 28 ticks, let go | a flick |
| Warning before the fire | 28 + 6 = 34 ticks | 30 ticks |
| Stopped by a medium | yes, in its first 28 ticks | no |
| Damage on a hit | 92 | 138 |
| Price | 20 energy | 45 energy and 30 stamina |
| Ground damage | the stage ladder | the same, at its stage |
| Speed, width, reach | the same | the same |
| Time planted | 70 ticks | 66 ticks |

So the signature is the same beam made quicker to throw, armoured against a medium and heavier, at more than twice the price. At the top stage it halves the warning (60 ticks against 126) for a price just under the full hold's 50.

**Who gets out** (model, `sigmodel2.js`). The rival is on the flick's line at the flick and moves straight across it. "Miss" means further off the line than the beam hits when its front arrives. A degree figure is how far off the flick's line the rival is at the fire: past 15 the line is not snapped onto them.

*A. The thrower flicked and let the stick go (the line was fixed at the flick):*

| Range | Stage 2 (gather 30): rival flies across at plain speed from the gather's start | Stage 2: dashes across from the gather's 14th tick | Stage 6 (gather 60): plain speed | Stage 6: dashes from the 14th tick |
| :--- | :--- | :--- | :--- | :--- |
| 10 body heights | miss (16 degrees: on the edge, reported, not judged) | miss (50) | miss (30) | miss (74) |
| 20 | hit (8) | miss (30) | miss (16: on the edge) | miss (60) |
| 40 | miss (snapped, then out-flown) | miss (16: on the edge) | hit | miss (41) |
| 60 | miss | miss | hit | miss (30) |
| 100 | out of reach | out of reach | hit | miss (19) |

*B. The thrower kept the stick out and on the rival until the fire (the line is snapped at the fire, so only movement after it counts):*

| Range | Stage 2: plain speed | Stage 2: dashing | Stage 6: plain speed | Stage 6: dashing |
| :--- | :--- | :--- | :--- | :--- |
| 10 body heights | hit | miss | hit | hit |
| 20 | hit | miss | hit | miss |
| 40 | miss | miss | hit | miss |
| 60 | miss | miss | hit | miss |
| 100 | out of reach | out of reach | hit | miss |

- **A flicked energy signature misses anyone who moves on the gather.** The gather gives 30 ticks before the fire and a person reacts in about 14, so a rival who sees the gather can be dashing before the beam leaves, and a dash from the 14th tick misses at every range in table A: it is outside the 15 degrees at the fire, or it out-flies the beam after the snap. Against a rival drifting across at plain speed a flick lands only in the middle: a base one at about 20 body heights, a top-stage one from about 40 out.
- **To land one on a moving rival the thrower holds the stick out and tracks** (table B). Even then a dash beats it everywhere except a full-power signature at 10 body heights. **The answer to a signature is to move on the gather, not on the beam.**
- **This is the page's largest open design question (ruling 11).** Fixed at the flick is honest to the aimed beam that Orb said "A sounds good" to (`vision.md:1693`, where the description of option A is the EP's; `beam-physics.md:103`; ruling 5 at `:111` turns down a wider assist as "option B (aimed for you) by the back door"), but it makes the input Orb named, a flick, the weaker way to throw it. The other arm is that the gather keeps the line on the rival while they stay inside the 15 degrees and stops following once they leave it; that makes a flick behave like table B and sits closer to "aimed for you".
- A rival who stands through the gather and only reacts to the fire itself is hit inside about 29 body heights by a base signature, and inside about 72 by a full one, either way of throwing it. (The draft said 40 for the base figure; the re-run gives 29.)
- **Up close the gather is the whole warning.** Unlike an ordinary beam's hold, which a medium stops in its first 28 ticks (`beam-physics.md:107`), a light or a medium does not stop a signature's gather. The answers up close are a slip, a block, a grab, a heavy already winding, or leaving.
- **The other answers at contact are the beam page's, unchanged:** a dodge tapped in the 12 ticks before contact passes through it; a fresh guard press stops it; a held guard takes guard damage and a push along the line; a beam fired back down the line starts the struggle where the fronts meet. A body that cannot act is passed through, and a launched body takes one touch a launch (`beam-physics.md:108`).

**Biome variants.** Orb put signature variants by biome on the back burner (`vision.md:1735`; the bracketed list inside that quote is the EP's insertion). Nothing new is authored. The seven rows as built keep choosing how the signature's groove looks, picked from the ground under the beam's first strike as the beam page proposes. The aftermath twists that need a named, held defender (`under`, `wall`, `skate`: `beam.gd:153-175`) do not run for a beam in space.

**Until the beam in space lands** (build step 5), RT + RB + a flick asks for today's signature through today's path. That keeps the input, the count of other inputs and the removal of RT + B testable early. It is an interim, and on that path nothing about today's signature changes:

- **the rival is still held from the press** (`exchange.gd:363-364`), so the agency reading (section 9, reading 3) fails on it by design;
- **the provisional limit acts exactly as today:** a second one inside 15 s is refused with the "Cooling" knock (`exchange.gd:288-293` stays as it is, and `DirSig.start` refuses first with the same reason so no start cue goes out). The stale rule of section 3.5 replaces the refusal only for signatures `DirSig` runs itself: the martial signature, and the energy signature once `energy.space` is on. Without this the interim would be today's rival-holding beam with no limit but its 45 energy;
- it pays 45 energy at the press, as today, and has no stale cost.

If the beam in space slips, the interim is what Orb and testers would play.

### 3.4 The martial signature

It does not exist today. It is built from pieces that do.

| Phase | What happens | First value | Built from |
| :--- | :--- | :--- | :--- |
| **1. Gather** | The fighter is planted and armoured as in 3.3, and their other presses are refused. The rival is free | 30 ticks | new director state; the stick's plant (`stick.gd:248-253`) and armour hooks (`brawl.gd:1368-1373`, `:1451`) |
| **2. Rush** | The price is paid. The fighter flies at the rival at the gravity well's snap speed, re-aimed every tick, and no faster. A brawl they were in gives way; a brawl the rival's press starts under the rush is ended at the touch. The rival is free and unmoved | the faster of 4,000 a second and flat out for the level; at most 36 ticks | the chase's capped, re-aimed rush (`chase.gd:228-265`); `DirBrawl.end` (`brawl.gd:492`) |
| **3. Touch** | Within reach of the rival, what they are doing decides (table below) | 1.2 body heights | `DirBands.dist`; `act.dodgeTick`, `act.guardSince` (both hashed today) |
| **4. String** | An exchange starts at the touch and both are held for it: the fighter's authored blows, then a launcher that sends the rival through the launch planner | at most 54 ticks | an exchange with no template (`exchange.gd:170-191`); a beat list as the finishers have (`data.gd:442-448`); `launch` beat (`exchange.gd:485-486`) |
| **5. After** | The rival is launched; the air brake is theirs. The fighter is free when the exchange ends | | as any launch |

**The rush's speed is the snap's,** by Game Design's ruling: "the faster of today's lunge (4,000) and flat out for the level" (`gravity-well-reading.md:61`): 4,000 at base, and by Game Design's figures about 4,640, 6,090 and 8,070 above it (flat out at the top is 3,500 x 2.305 = 8,068, `flight-3500.md`). It is read from the level directly (`SimPower.level`, `S.powerFlat`), never from the stick's flight speed. This page uses Game Design's four figures throughout.

**The rush has a margin over a same-form rival only at base.** At base it is 4,000 against a flat-out 3,500. Above base "flat out for the level" is the rival's own flat-out speed when they are the same form, so the closing speed is nothing: a same-form rival who holds LT away is not caught from beyond touch reach (about 2 to 3 body heights).

**What the rush catches** (model, `sigmodel2.js`; the gap is when the rush leaves; the touch test is the code's in section 6.2, 1.2 body heights plus the rival's own movement in one tick, so a rival fleeing at 3,500 is touched from 148 units, not 90):

*Base against base (rush 4,000, flat-out flight 3,500):*

| Gap when the rush leaves | Rival stands | Walks away | Flies away flat out at once | Flies away 14 ticks late |
| :--- | :--- | :--- | :--- | :--- |
| 4.5 body heights (a brawl) | touch in 4 ticks | 5 | touch at 23 | 4 |
| 12.5 (the well's edge) | 13 | 15 | **gets away** | 13 |
| 20 | 22 | 24 | gets away | gets away |
| 30 | 33 | **falls short** | gets away | gets away |

*Same form against same form, by form (rush = the rival's flat-out speed above base):*

| Form (rush speed) | From 4.5: flies away at once | From 4.5: 14 ticks late | From 12.5: at once | From 12.5: 14 ticks late | From 20: 14 ticks late | From 30: stands |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Base (4,000 against 3,500) | 23 | 4 | gets away | 13 | gets away | 33 |
| Second (4,640) | **gets away** | 4 | gets away | 11 | gets away | 28 |
| Third (6,090) | **gets away** | 3 | gets away | 9 | 14 | 22 |
| Full power (8,068) | **gets away** | 2 | gets away | 7 | 11 | 17 |

*A rival who flies off flat out on the gather's 14th tick* (a person's reaction) has 16 ticks of flight before the rush leaves, 12.4 body heights at base. From a brawl they are 17 body heights away when the rush starts and are not caught at any form (at base the rush would need 135 ticks and has 36). The escape costs them about 7 stamina at Game Design's 6 a second; the thrower has paid 45 energy and 30 stamina and is open 30 ticks.

- **Its reach in 36 ticks is 32 body heights at base** (about a screen and a half), then 37, 49 and 64 by form. It is never refused for range.
- **It falls short of a rival who simply stands beyond about 33 body heights at base, after the price is paid,** and of one who walks away from beyond about 30. The draft said "you cannot walk away from it"; that is true only inside about 30 body heights. A reach on a melee move departs from pillar 3 and from Game Design's ruling 3, and is named in section 4, row 17, with the other arm (a rush that runs until it touches or stops gaining) as open ruling 19.
- **You can out-fly it** if you leave on the gather, which costs stamina and gives up ground. Leaving late is caught: 14 ticks into the rush, from a brawl or the well's edge, at every form.
- **Power has weight:** a full-power fighter's rush (8,068) catches a base fighter flying flat out from 20 body heights in 18 ticks.
- This is the same choice the stand-in's gravity well page listed as its comparison arm for the snap (fly at its own speed and be outrun). It is taken here, for the signature only, because a signature that always arrives would hold the rival to an outcome they could not move out of. Whether a zero margin in every same-form fight above base is too little is open ruling 14.

**At the touch:**

| The rival is | What happens | Variant |
| :--- | :--- | :--- |
| Standing, moving, or winding a blow of their own | The string plays in full, and their wind-up is cut | `ground` |
| Dodging (LT tapped in the last 12 ticks) | The rush passes through. The fighter overshoots and is open | miss, open 30 ticks |
| Guarding since less than 12 ticks (a fresh press: the powerful block) | Turned. The fighter staggers in place | stun 40 ticks |
| Holding a guard | The short string: chip on the guard, then a knock-back, not a launch | `guard` |
| Launched | One blow, then a send in a new direction by the fighter's stick. **Once in a launch:** a second martial touch on the same launch is a miss | `air` (the chase's blow for the damage, `chase.gd:326`; the send is the launch planner's, as the chase's catch calls it, `chase.gd:284-313`) |
| Down or dropped | The rush passes over. A miss | miss |
| **Rushing with a martial signature of their own** | Neither string plays. First value: both are turned and stagger. Decided before either touch, so the player in the first slot does not win it by order | both stun 40 ticks; open ruling 18 |
| **In a brawl with the fighter** (the rival's press started one under the rush) | The brawl is ended, then the row above that fits | as that row |
| **In any other exchange, or a set piece** | The rush passes. A miss | miss |
| Out of reach when the 36 ticks end | Falls short | miss, open 30 ticks |

- **"An attacking defender":** a rival's light or medium that lands during the gather or the rush meets the armour and does not stop it. A heavy, a grab or a beam that lands stops it, before the touch. On reaction a heavy takes about 14 + 28 = 42 ticks, so it does not stop a fresh 30-tick gather but does stop a stale 48-tick one; a grab (14 + 10) stops either.
- **Inside a brawl this makes RT + a flick an armoured half-second reversal** against anyone pressing lights and mediums. That is the same departure as the energy gather's (section 4, row 18) and reading 9 counts it.
- **Two martial signatures.** Game Design's recorded frame says another signature "makes a struggle" (`docs/design/melee-press-feel.md:1179`). No struggle between two rushes exists. The first value here is that both are turned, and the struggle is left to ruling 18 (section 4, row 19).
- **During the string the rival is held,** because it has touched them. First value: their burst (RT, 30 energy) stays live between blows, so the string is never a guaranteed 138.
- **The `air` variant is Orb's in-air chain:** "scoring a knockback on the opponent, zipping around them at higher speed than they fly, then knocking them back in another direction is the feature I want explored and enhanced" (`vision.md:1881`).

**What Combat must author,** as data, one row for each of the two launch fighters:

| Piece | Shape | Limit |
| :--- | :--- | :--- |
| Three variants: `ground`, `guard`, `air` | A beat list in the finishers' form (`tick`, `op`, `args`), roles W and L | `ground` at most 54 ticks and 5 blows; `guard` at most 30; `air` one blow |
| Damage | First values: `ground` 18, 18, 18, 24 then a 60 launcher, 138 in all, the energy signature's worth; `guard` chips at a quarter and knocks back; `air` is the chase's heavy as built (132 times the link's worth, `chase.gd:326-328`) until Combat gives it a number of its own | Game Design's |
| The `ground` launcher | Its `launch` beat carries `"forced": true` and `"why": "signature"`. The earned-launch gate is on in data (`data/director/launch.json:164-165`), and without `forced` the beat can land as a knock-back or a stagger (`sim/director/melee.gd:420-432`) | always a launch |
| The strikes' options | `noParry` true (the answers were before the touch); **not** `ignoreStance` on the `guard` variant | |
| Pieces and poses | From each fighter's own strikes on paper: the Protagonist's round kicks and open hands to a rising palm; the rival's cross and short elbow to a dropping elbow (`docs/combat/moveset-generator.md:168-178`) | each fighter's distinct from the other's and from their energy signature |
| A name each | Screened by Legal through the EP; none is proposed here | |
| The gather pose and the rush pose | Animation, from Combat's page | the tell is the pose, the aura and the sound |

Game Design's frame for a martial signature (a lunge, four lights and a launcher, three variants by the rival's situation; `moveset-generator.md:166`) is kept in shape. Its cells file does not exist, so the content is authored as a beat list.

### 3.5 Costs

| | Rule | Value | Lives in |
| :--- | :--- | :--- | :--- |
| Energy | Each signature, either kind | 45 | `signature.ki`, read by the director in place of its three literals |
| Stamina | 0.7 of the energy, at most 30 a move (`energy-stamina-body.md:30`; Orb: "Yes, both", `vision.md:1788`). Only while the stamina loop's switch is on | 30 | `data/fight/vitals.json` `ofEnergy`, `moveCap` (Game Design's block) |
| When | **At the fire or the rush's first tick,** not at the flick. A gather that is stopped costs nothing but the opening. Energy drained during the gather (a guarded blow, the armour's chip) can leave too little at the fire: the gather then ends unpaid with the cue `sig_lost` `ki` | | |
| Short of stamina | **Never refused for stamina,** as the model rules ("No press is ever refused for stamina", `energy-stamina-body.md:34`): each missing point is 2 energy, with the model's own sound and pad pulse (`:37`). Unchecked, that fall-through makes a signature at no stamina cost 45 + 2 x 30 = 105 energy, over the cap of 100 (`sim/core/fighter.gd:711`), so below 2.5 stamina it could never be thrown. **First answer (open ruling 15): the whole price never passes `signature.maxPrice`.** A fighter with too little energy for that price is refused for energy, with "No energy" | 45 at 30 stamina or more; 65 at 20; 85 at 10; 90 at 7.5 or less | `signature.stick.maxPrice` 90 |
| Refills | A signature refills nothing. The martial string's blows are part of an energy move and do not refill stamina either | 0 | |
| The last stand | Unchanged: free, for either signature, and never stale (`SimFighter.sigFree`) | | built |

**The limit the code calls provisional.** Today a signature is refused with "SIGNATURE RECHARGING" for 15 s after the last (`exchange.gd:288-293`). The record on it, in order:

- The EP's summary of Orb's questionnaire of 2026-10-02 (the EP's words, not Orb's): "the slider says 15 s between signatures (was 120)" (`vision.md:509`). Game Design's page says the same: "Orb disliked the 120 s cooldown and set the slider to 15 s" (`docs/design/agency-pass.md:260`). So the 15 is a number Orb chose, in place of two minutes.
- Orb, the same day: "I just didn't like the cooldown, I want the energy combat system to be implemented before I make any more decisions on energy beams" (`vision.md:523`).
- Game Design, 2026-10-04: the 15 s limit is replaced on paper by "One shared cooldown" over all of a fighter's signatures, "180 ticks (3 s) after a signature or an ultimate ... It is there only to stop two in a row", with "No cap per match" (`agency-pass.md:258`; `docs/design/melee-press-feel.md:1168-1170`). That frame is paper; the code still runs the 15 s.
- Orb, 2026-10-16: "I'm not a fan of "cooldowns" and "recharging" exccept in limited circumstances, so try to balance it in a way that avoids strict caps on what a player can do in a fight" (`vision.md:1412`).
- Game Design's "soft costs, no cooldowns" (`docs/design/energy-overhaul.md:32`), and the model page, which has no signature limit at all.

**Proposed: stale, never refused.** A signature thrown inside `staleSec` of that fighter's last one, of either kind, is stale: its gather is `staleGatherTicks` longer and it does `staleDamageMul` of its damage. Nothing is refused for a timer, and that includes the 3 seconds after one ends: a second signature can start then, stale. This applies to the signatures `DirSig` runs itself. On the interim path (section 3.3) today's refusal stays.

| | Fresh | Stale |
| :--- | :--- | :--- |
| Gather at base | 30 ticks | 48 |
| Damage | 138 | 103.5 |
| A heavy thrown on reaction (42 ticks) | does not stop it | stops it |

- It reuses the one stamp that exists and is hashed (`f.sigReadyT`, `sim/core/hash.gd:191`): written as now plus `staleSec`, read as "stale while now is before it". No new state, and the computer's pacing, which reads that stamp (`ai.gd:408-419`), keeps working.
- **Why costs alone are not enough** (arithmetic): with nobody pressing, charging refills 45 energy in 1.2 to 2 s and resting refills 30 stamina in about 2.1 s, so a fighter left alone could throw one about every 2.6 s. The stale rule makes that slower and weaker each time; what really stops it is the rival, who is free to act through every gather.
- The provisional damage factor 0.6 stays as it is (it is what makes 230 into 138).

### 3.6 What the defender can do, and what holds them

| Moment | Energy signature | Martial signature |
| :--- | :--- | :--- |
| The gather | Free. Fly off the line, close in and hit, gather a beam of their own | Free. Fly away, hit, grab, set a guard |
| In flight | Free until the front touches them | Free until the rush touches them |
| At contact | Dodge, guard, powerful block, or be hit and launched along the beam's line | Dodge, guard, powerful block, or the string |
| After contact | Launched: the air brake is theirs | Held for the string (at most 54 ticks, burst live), then launched |

**Ticks a rival is held or moved by a signature before it touches them: 0.** That is the reading that proves the agency rule (section 9). Today the number is the whole tell and travel: 48 ticks and more.

### 3.7 The shooter's commitment, in one table

| | Energy | Martial |
| :--- | :--- | :--- |
| Can it be cancelled by its thrower | No. Guard and dodge do not end it, and every other press is refused with a knock | No |
| Planted | Gather + lit time from the fire: 66 ticks at base, 150 at the top; stale, 84 and 168 (2.8 s). The beam's far end can outlast the plant | Gather: 30 ticks (48 stale); then the rush moves them |
| Stopped by | A heavy, a grab, a beam, a launch, a stun: lost, unpaid. Too little energy left at the fire: lost, unpaid. Stopped during the pour, the beam is cut at its front | The same, in the gather or the rush; once the rush has started it is paid |
| A miss | Still planted for the lit time; a rival who sidestepped is free to come in | Overshoots and is open 30 ticks |

### 3.8 The struggle

Unchanged from the beam page: two beams struggle when each would have hit the other's shooter and their fronts meet. A signature is a beam, so it meets like one. The meeting-point energy x 9 "if either is a signature" (`craters.json:30`, `sigMulIf`; the `struggleMeet` block is off on main) reads the beam's new `sig` mark. A martial rush that runs into a beam's front is touched by it like any body, and a beam stops the rush.

**Two martial rushes that meet do not struggle.** First value: both are turned (section 3.4). The struggle Game Design's frame names for a martial signature against another signature is not designed here (open ruling 18).

### 3.9 The computer

| | Rule | First value |
| :--- | :--- | :--- |
| **Its input** | It writes the same second-word fields a pad sends: `rsStart`, `rsRelease`, `rsMask` 4 or 6, `rsDir`, `rsAim`, with `stanceMask` 4. The director reads the computer and a player through one door. **With `DirSig` on, the three places the computer chooses its signature call `DirSig.aiStart` and nothing else.** The beam's hold-and-release (`DirBeamMove.aiStart`) is not asked first: in the builds Orb plays it returns true every time, and the computer would never throw either signature (section 6.3) | replaces `i.sig` at `ai.gd:262-263`, `:276-277`, `brawl.gd:4121-4122` |
| **When** | Its pacing is unchanged: the same first-signature time, gap and chance (`sigDue`, `sigPickFor`, `ai.gd:413-427`), reading the same stamp | `ai.json` `vsHuman`, as built |
| **Which** | Energy when the rival is beyond 20 body heights and inside its beam's reach. Martial when the rival is inside 0.8 of its rush's reach and is standing, recovering, guarding or winding. Otherwise it waits for its next beat | `signature.ai.martialWithinBh` 20, `reachShare` 0.8 |
| **Never** | Past its own reach, for either (Game Design's rule for beams, `beam-physics.md:109`) | |
| **Its aim** | The stick sector nearest the line to its rival, with the beam page's chance by level of pointing two sectors off. **As written it flicks** (start and release together), so its line is fixed at the flick and it misses a player who moves on the gather (table A of 3.3). Whether it should hold its stick out and track, at its own reaction time, follows open ruling 11 and is not specified here | `beamPlays.space.ai.aimSlip` |
| **Against a signature** | It reacts to the gather's cue, after its reaction time, never to the fire tick. Against energy: the beam page's sidestep. Against martial: by level, a keyed draw picks fly away (only beyond 12 body heights), dodge at arrival, guard, or nothing | `signature.ai.answer` |
| **Draws** | Keyed only: `SimRng.keyed(int(S.game.seed), "sig.ai.<what>", n)` with n the start's live tick times 2 plus the slot. No draw from the old stream | |

Its pacing was set for signatures that always land (about three a match). It needs a new reading once both can miss.

**The computer's ordinary beam.** Today the computer's only way into a beam's hold is its signature moment (the three callers of `DirBeamMove.aiStart`: `ai.gd:261`, `:275`, `brawl.gd:4120`): with the hold-and-release switch on, that moment becomes a stick hold, which the code's own comment calls "The computer's beams, its signature included" (`beam_move.gd:141`). Once `DirSig` takes those moments, the hold never stands in for a signature again, and nothing else starts the computer's ordinary beam until the beam page's shot choice for the computer is built. **Until then a computer with `DirSig` on throws signatures and no ordinary beams.** Build step 7 depends on that shot choice.

### 3.10 Cues, and what the player sees

Nothing is drawn on, over or between the fighters. The tell is the thrower's own body: pose, aura and sound. Any new effect goes through the look gate with its side-by-side.

| Cue (all through `SimFx.cue`) | When | For |
| :--- | :--- | :--- |
| `stick_start` | the flick is taken | the hub (no "No answer" knock) |
| `sig_gather` (text `energy` or `martial`, n the gather's ticks, target the rival) | the gather starts | Animation's pose, VFX's aura flare, Audio's rise, the rival's pad, the computer's reaction |
| `beam_charge` (the beam page's cue) | with an energy gather, to every enemy inside that stage's reach | UI's line at the screen's edge for a shooter off screen |
| `sig_go` | the beam fires or the rush leaves; the price is paid here | Camera, Audio |
| `beam_fire`, `beam_warn`, `beam_outcome` | as the beam page | as built and as the beam page |
| `sig_touch` (text the variant) | the rush touches | Animation's string, Camera |
| `sig_miss` (text `dodged`, `short`, `passed`) | the rush ends with no touch | Animation's overshoot, UI's word |
| `sig_turned` (text `block` or `met`) | a powerful block turned it; or two martial rushes met | as a turned blow |
| `sig_lost` (text `hit` or `ki`) | the gather or rush was stopped; or too little energy was left at the fire | UI's "Hit" and "No energy" (both words exist, `ui/data/terms.json:94`), the pad |
| `stick_refused` | a refusal (3.1) | the pad's knock, UI's word |

- **Seen, energy:** the hand's glow and VFX's stage pulses (required for the beam trial by Game Design's ruling 1), a front that travels, the groove it carves.
- **Seen, martial:** a coil and an aura flare, a rush with the dash's own trail, the string, the launch.
- **The name banner:** UI already drops a banner that is only a move's name (`ui/core/ui_event_hub.gd:118`). The "NEED 45 KI" and "SIGNATURE RECHARGING" banners stop being sent.
- **Stale:** the longer gather is itself the sign. No word is needed.

### 3.11 Hash discipline and the golden window

| New thing | Hashed how | Why the hash is unchanged with the switch off |
| :--- | :--- | :--- |
| `rsMask` 4 or 6 in the second intent word | already hashed with the right stick on (`hash.gd:98`, `:180`) and kept by `net/desync.gd:77` | the input layer never produces 4 or 6 with `sigStick` off |
| Seven director integers per fighter (section 6) | inside `f.act.dirI`, whose size and every value are hashed (`hash.gd:212`) | sized only on the first write, and nothing writes with the switch off |
| The beam's `sig` mark (0, 1 fresh, 2 stale) | appended only for a beam in space, with the beam page's `sv`, `hw`, `stage` | no beam has a speed with the beam's switch off |
| `f.sigReadyT` | hashed today (`hash.gd:191`) | same writes at the same moments on the old path |
| The charge's suspension, the burst's wait, the refused presses | no state of their own beyond the seven integers | every hook returns at once with the switch off |
| The RB grace (`sigRbTicks`) and the physical read | input-layer state, not sim state. A replay carries only the start edge and its layer | the input layer never holds a start back with `sigStick` off |
| The data blocks | `interrupts.json` and `templates.json` are in every replay's data key by their text (`data.gd:41-58`) | **they are not:** any edit to those files moves the key, so the blocks land in the golden window |
| The input switch | `timing.json`'s switches are not in the data key today, except `rightStick` (`sim/core/replay.gd:226-227`) | add the text `sigStick` to the key only while it is on, as `rightStick` is |

- **No draw from the old stream** anywhere in the new code; the old beam path's draws stay where they are until that path goes.
- **Float64, `SimDetMath` and `SimMathx`, `SimWrap.sdx(a, b)` is b minus a, no `Vector2`** in the director's new file. (The input layer's reader already uses `Vector2` for the stick; that is not sim state.)
- **The two-fighter count** has no slack and counts comments: the new file reaches the running exchange and the rival only through `DirBrawl.exOf(S)` and `DirBrawl.rivalOf(S, f)` (`brawl.gd:216-221`), and no comment spells the four counted names.
- **The load split:** the two new calls from the core go through `SimDir` (`sim/core/dir.gd:7-9`); no core file names `DirSig`.
- **Window:** everything lands in GW2, "the fight's rules", with the beam in space, the gravity well and the stamina loop, so the reference matches are re-recorded once.

### 3.12 Open rulings for Game Design

| # | The question | This page's first answer |
| ---: | :--- | :--- |
| 1 | "At its top stage": the fighter's own top stage now, or the ladder's sixth | The fighter's own (2 at base) |
| 2 | The gather: a fixed tell in place of the hold, and its numbers | Half the hold, never under 30 ticks |
| 3 | Does a flick during the RT channel fire. The cost of yes: a flick meant as a plain blow at a rival closing in throws a signature | Yes (`sigChordTicks` 0), with reading 15 as the guard |
| 4 | The burst waiting for the chord: 10 ticks with the RB grace, 7 without | Yes |
| 5 | The limit. The record holds three answers: the 15 s Orb's slider gave, Game Design's 3 s shared cooldown "only to stop two in a row", and no limit in the model | Stale, never refused, for the signatures `DirSig` runs; the interim keeps today's refusal |
| 6 | A held guard against the martial signature | Chip and a knock-back, not a launch |
| 7 | Does a signature beam's own carve get a multiplier. None exists today; the x 9 is only for the point where two beams meet | No new multiplier |
| 8 | The gather's armour: does a medium stop it. The recorded rule for a beam's hold is that it does, in the first 28 ticks | No (a departure, row 18). The other arm: `armour.medium` false, or a `mediumUntilTicks` of its own |
| 9 | Can guard or dodge cancel your own gather. And does a guard held by a planted fighter count against other blows | No; and not specified (section 12) |
| 10 | The martial touch on a launched body | One blow and a send, once in a launch |
| 11 | **The energy signature's line.** Fixed at the flick (a flick then misses anyone who moves on the gather, table A of 3.3, and only a held stick tracks), or kept on the rival through the gather while they stay inside the 15 degrees (a flick then behaves like table B, closer to "aimed for you") | Fixed at the flick, with a held stick tracking. Then the angle: 15, with Controls reading releases two sectors off, then 20, as ruling 5 says |
| 12 | The rival's burst inside the string | Live |
| 13 | The price paid at the fire, not at the flick | At the fire |
| 14 | **The rush's margin over a same-form rival's flat-out flight.** As written it is 500 a second at base and nothing above base | None, as written. The other arm: a share over the thrower's own flat-out speed (a first value of x 1.15 still does not catch a base rival who leaves the well's edge at once: it needs 91 ticks) |
| 15 | A winded fighter's signature: the model's fall-through prices it at up to 105 energy, over the cap | The whole price is capped at `maxPrice` 90; never refused for stamina |
| 16 | RB arriving late: the grace, its length, and who pays (a late martial start, or a shorter seen gather). With Controls | 4 builds; the martial signature starts 4 builds after the crossing (3 later than today's quick read) and its gather stays 30 |
| 17 | Read RT and RB physically (no release grace, no one-shot); and may the D-pad or a keyboard's strike keys throw a signature. With Controls | Physically; yes, counted apart |
| 18 | Two martial signatures that meet: both turned, or the struggle Game Design's frame names | Both turned |
| 19 | The rush's 36-tick end. It gives a melee signature a reach, and a standing rival past it is not reached after the price is paid. The other arm: the rush runs until it touches or has stopped gaining for some ticks, with a long safety ceiling | 36 ticks (a departure, row 17) |
| 20 | More than two bodies (section 3.13) | Only the two principals throw one; the rush is at the rival, never at a nearer body |

### 3.13 More than two bodies

The page above is written for two fighters. A fight can hold five bodies (`sim/core/roster.gd:40`), and Orb said "GO" to a horde's first size of three weak enemies at a time (`vision.md:1798`). First rules, for Game Design and the horde's own design:

- **Only the two principals throw a signature at Alpha** (`SimRoster.isPrincipal`, `roster.gd:47`). A weak enemy never gathers, and the computer's `aiStart` is not called for one.
- **The martial rush is at the rival** (`DirBrawl.rivalOf`), as every other blow is today. With more than two bodies the code's rival is fixed by slot (`roster.gd:62-65`), so a nearer body is not chosen and the rush flies past it. The string holds only the body it touched.
- **The energy signature touches whatever enemy body its front meets first,** as the beam page's `touch` does. The gather's warning cue goes to every enemy inside the stage's reach.
- **In a 2v2** each pair swapped into the state is its own fight and a signature does not cross between them, beyond what the beam page already says about a beam crossing into the other fight.
- **Not designed here:** which body a principal's signature should choose in a horde, and what a string does when a third body stands in the rush's path. Those belong to the horde's window.

---

## 4. Departures

Each is a proposal for Game Design.

| # | Recorded | This page | Why |
| ---: | :--- | :--- | :--- |
| 1 | "RB + RT ... Reject. One index finger, two triggers" (`docs/controls/right-hand-attacks.md:74`) | RT + RB at the flick is the energy signature | Orb named the chord afterwards (`vision.md:1710`). Whether one hand reaches both is a reading (section 9) |
| 2 | RT + B fires "never once RT's hold is the channel" (`overnight-2026-11-08.md:35`), ruled for B | A flick during the channel fires the signature | B is mashed while powering up; a flick under RT has no other use today (it is inert). Game Design's earlier line for RT + the stick had no window ("Hold RT, then flick or hold the stick", `docs/design/beam-answers.md:13`). Charging to 45 and then flicking is the natural use. **The cost is real:** a flick meant as a plain blow at a rival closing in becomes a signature (section 3.1, rule 3). The window is one data number if Game Design wants the old rule |
| 3 | A power press while threatened bursts "at once" (`sim/core/act.gd:89-91`) | It waits up to 10 ticks for a signature's start (7 without the RB grace) | Otherwise a pressed fighter's signature always costs a burst first, which nobody asked for. A tapped burst still fires on RT's release |
| 4 | The provisional 15 s limit and its refusal (`interrupts.json:225-228`), which the EP's record says is Orb's own slider answer in place of 120 s (`vision.md:509`; `agency-pass.md:260`); "A 120 s signature cooldown per fighter" (`docs/design/balance-targets.md:471`); all signatures share 120 s (`docs/design/moveset-rules.md:36`); Game Design's later "One shared cooldown ... 180 ticks (3 s) after a signature or an ultimate ... only to stop two in a row", with no cap per match (`melee-press-feel.md:1168-1170`) | No refusal and no wait at all, not even the 3 s; a repeat inside 15 s is slower and weaker. The interim energy path keeps today's refusal | Orb's words on cooldowns (`vision.md:523`, `:1412`); Game Design's "soft costs, no cooldowns"; the model page has no limit. Orb's "exccept in limited circumstances" leaves room for the other answer, which is why it is a question for Orb (section 11) |
| 5 | "No longer tell up close" (`beam-physics.md:107`); the stand-in's own "its own longer tell" (beam page, section 14) | A fixed gather at every range, in place of the hold | Not longer up close, so within the ruling's reason. Without it a flick would fire a full beam with no warning at all. The stand-in's earlier phrase is withdrawn |
| 6 | "The signature is aimed at him, always" (`interrupts.json:309-310`; the beam-aim-throw park) | Aimed by the flick, with the beam's assist | Game Design's line 115: it must not be "the one beam that still finds you" |
| 7 | A stage's damage is the ladder's (`interrupts.json` `ownMove.dmgMul`) | Never less than today's 138 | At base the ladder would cut the signature from 138 to 92 |
| 8 | The price and the limit are taken at the start (`exchange.gd:344-349`) | At the fire or the rush's first tick | The rival can now stop the gather; paying 45 and 30 for nothing would make it unusable under pressure |
| 9 | The rival "isn't frozen" in a signature's tell but moves only at the rate of giving ground, to a leash (`brawl.gd:4255-4259`, Game Design, 2026-10-06) | The rival is wholly free | "PLAYER AGENCY MUST BE RESPECTED" (Orb, `vision.md:1800`); the beam page's rule |
| 10 | A request waits while the rival is launched (`exchange.gd:279-280`) | The martial rush touches a launched body once | Orb's in-air chain (`vision.md:1881`); Game Design's one touch a launch for beams |
| 11 | The snap "cannot be outrun" as built, and the stand-in's gravity well page kept "outrun" as a comparison arm only, citing pillar 3 | The signature's rush flies at its own speed and can be out-flown. At base its margin is 500 a second; above base, against a rival of the same form, it has none | A signature that always arrives decides the outcome for the rival. It still closes on anyone who stands, walks or leaves late inside its reach. It does not close on a same-form rival who flies off on the gather (open ruling 14) |
| 12 | Game Design's martial frame draws its blows from the fighter's X and Y cells (`moveset-generator.md:166`) | An authored beat list | The cells file does not exist |
| 13 | "the Anti-hero's signature is a barrage of shots" (proposed; Orb ticked "Your call", `vision.md:1275-1280`); the rival's display name | Both fighters fire the one beam at the third milestone | Line 115 rules one form. The volley stays on Combat's paper (`docs/combat/barrage-signature.md`) for after |
| 14 | The aftermath twists by biome (`beam.gd:153-175`) | Do not run for a beam in space | They need a held, named defender. Orb put biome variants on the back burner |
| 15 | The stand-in's beam page said no tick of a guard press is kept | `act.guardSince` is kept and hashed (`sim/core/state.gd:321`; `hash.gd:198`) | A correction to the earlier page; the powerful block can read it with no new state |
| 16 | The reviewers' map proposed taking 4 out of `strike.inertMasks` | The list stays; the switch overrides it | With the list edited and the switch off, RT + a flick would become a plain strike |
| 17 | Pillar 3, "Never out of range ... Attacks always close the gap" (`CLAUDE.md`); Game Design's ruling 3, "A beam is the one attack that doesn't close the gap, so it has a reach" (`beam-physics.md:109`) | The martial signature's rush ends after 36 ticks. It falls short of a rival standing beyond about 33 body heights at base (walking away, about 30), after the price is paid | A rush with no end is a fighter flown across the map for seconds on one flick, and one that always arrives. The 36 ticks are a first value. This makes a second attack with a reach, so it is Game Design's to allow; the other arm is open ruling 19 |
| 18 | "Up close you answer on the charge, by snapping in (a medium stops a charge in its first 28 ticks), slipping or blocking" (`beam-physics.md:107`; `data/director/stick.json:41`; `stick.gd:242-243`) | A medium never stops a signature's gather, energy or martial. On reaction the blows that stop a fresh one are a grab, or a heavy already winding | The signature is the committed, paid-for move, and its gather is its only warning. If a medium stopped it for 28 of its 30 ticks it could not be thrown inside a brawl at all. The price is an armoured half-second reversal against lights and mediums (reading 9). Open ruling 8 |
| 19 | Game Design's frame for a martial signature's answers: "Another signature, which makes a struggle" (`melee-press-feel.md:1179`) | Two martial rushes that meet are both turned; no struggle | No struggle between two rushes exists to build from. Open ruling 18 |
| 20 | The stance mask keeps a button for two builds after it is let go, "so a flutter does not flicker the stance", and a tapped stance can be armed for 90 ticks (`layout.gd:977-987`) | A signature reads RT and RB only while physically down | A flick after RT is let go, or after an RT tap, should not spend 45 energy. Open ruling 17 |
| 21 | "No press is ever refused for stamina" and the fall-through at 2 energy a point (`energy-stamina-body.md:34-37`) | Kept, with a cap the model does not have: the whole price never passes 90 | Without a cap the model prices a winded signature at 105 energy, over the 100 cap, which is a refusal for stamina in all but name. Open ruling 15 |

---

## 5. Data

All off by default. Each schema changes in the same commit as its data.

**`data/input/timing.json`** (the chord is an input rule; schema `tools/schemas/input-timing.schema.json`). Controls' file by grant.

As it lands on main (nothing changes: `bNoBeam` is false on main today, `timing.json:57`):

```json
"switches": { "sigStick": false, "bNoBeam": false, "bNoBeamKeepRt": false },
"strike":   { "sigChordTicks": 0, "sigRbTicks": 4 }
```

In the build that turns `sigStick` on, and only there:

```json
"switches": { "sigStick": true, "bNoBeam": true, "bNoBeamKeepRt": false }
```

- `sigStick` false is today. The two B switches change only in the build that turns `sigStick` on; landing `bNoBeam` true on main ahead of that would make every player's B the heavy there and move the hash. Orb's builds carry `bNoBeamKeepRt` true until then.
- `sigChordTicks` 0: any time RT is held. Above 0: only that many builds from RT's press.
- `sigRbTicks` 4: how long a start read with RT alone waits for RB. 0 turns the grace off (the crossing build alone decides).

**`data/director/interrupts.json`**, the existing `signature` block, extended (the director's numbers; schema `tools/schemas/director-interrupts.schema.json`). Encounter's file.

```json
"signature": {
  "provisional": true, "cooldownSec": 15, "damageMul": 0.6,
  "stick": {
    "enabled": false,
    "ki": 45,
    "maxPrice": 90,
    "burstWaitTicks": 10,
    "stale": { "enabled": true, "sec": 15, "gatherTicks": 18, "damageMul": 0.75 },
    "armour": { "light": true, "medium": true },
    "energy": { "gatherTicks": [30, 30, 30, 33, 45, 60], "minDamage": 230, "space": true },
    "martial": {
      "gatherTicks": 30,
      "rush": { "floorSpeed": 4000, "maxTicks": 36, "maxStepBh": 3 },
      "touchBh": 1.2, "dodgeTicks": 12, "perfectTicks": 12,
      "missOpenTicks": 30, "turnedStunTicks": 40, "stringMaxTicks": 54
    },
    "ai": {
      "martialWithinBh": 20, "reachShare": 0.8,
      "answer": { "easy":   { "flee": 0.0, "dodge": 0.1, "guard": 0.4 },
                  "medium": { "flee": 0.2, "dodge": 0.25, "guard": 0.4 },
                  "hard":   { "flee": 0.3, "dodge": 0.4, "guard": 0.25 } }
    }
  }
}
```

- `stick.enabled` is the director's own switch; it needs `switches.sigStick` and `rightStick` too. Director switches have no setup key: a page build flips the data.
- `stale.enabled` true with `stick.enabled` on replaces the refusal **for the signatures `DirSig` runs itself** (the martial signature, and the energy signature with `energy.space` on). Those never pass through the old path's refusal. On the interim energy path, and with `stick.enabled` off, the provisional limit acts exactly as today.
- `maxPrice` 90: the most a signature costs in energy when stamina is short (open ruling 15). It is not read until the stamina loop exists.
- `burstWaitTicks` 10 is `chordWindow` 6 + `sigRbTicks` 4 (section 3.1, rule 4); with the grace off it is 6 + the quick settle 1 = 7. Controls keeps the two in step.
- `armour.medium` true is the departure of section 4, row 18; false gives the recorded rule.
- `energy.space` true asks for the beam in space; it needs `beamPlays.space.enabled` (the beam page's block). False, or with that block off, the energy signature takes today's path.
- `minDamage` 230 is the number `damageMul` already scales.
- `rush.floorSpeed` and `maxStepBh` repeat the gravity well's `snap` values on purpose; when `data/fight/well.json` exists they are read from it and removed here.
- The beat list below is a shape, with the roles W and L as the finishers use them (`data.gd:511-522`). A `launch` beat needs `rev` (`exchange.gd:485-486`), as every template's has. The `ground` variant's launch beat also carries `forced` and `why`, or the earned-launch gate (on in `data/director/launch.json:164-165`) can turn it into a knock-back or a stagger (`melee.gd:420-432`). The `air` variant's `force` 1600 is the chase's own send (`chase.gd:284`).

**`data/combat/templates.json`**, a new top-level key beside `beam` (Combat's content, by grant; schema `tools/schemas/combat-templates.schema.json`). Shape only; the beats are Combat's to author.

```json
"sigMartial": {
  "PROTAGONIST": {
    "id": "sig_martial.protagonist",
    "interrupts": ["burst"],
    "variants": {
      "ground": { "beats": [
        { "tick": 3,  "op": "strike", "args": { "a": "W", "d": "L", "dmg": 18, "o": { "noParry": true } } },
        { "tick": 12, "op": "strike", "args": { "a": "W", "d": "L", "dmg": 18, "o": { "noParry": true } } },
        { "tick": 21, "op": "strike", "args": { "a": "W", "d": "L", "dmg": 18, "o": { "noParry": true } } },
        { "tick": 30, "op": "strike", "args": { "a": "W", "d": "L", "dmg": 24, "o": { "noParry": true, "stop": 0.12 } } },
        { "tick": 42, "op": "strike", "args": { "a": "W", "d": "L", "dmg": 60, "o": { "noParry": true, "big": true, "stop": 0.16, "shake": 14 } } },
        { "tick": 44, "op": "launch", "args": { "force": 2600, "rev": false, "forced": true, "why": "signature", "share": "sigMartial.launcher" } },
        { "tick": 54, "op": "nop" } ] },
      "guard":  { "beats": [] },
      "air":    { "blow": "heavy", "force": 1600, "share": "sigMartial.air" }
    }
  },
  "RIVAL": { "id": "sig_martial.rival", "interrupts": ["burst"], "variants": {} }
}
```

**`data/fight/power.json`** `share` (Simulation's file): three new keys, or every martial send reads `unlisted` and logs an error (`sim/core/power.gd:202-210`).

```json
"sigMartial": { "launcher": 1.0, "guarded": 0.25, "air": 1.0 }
```

**`ui/data/fighter_names.json`** (UI's; schema `ui-fighter-names.schema.json`): a second name key per fighter for the martial signature, once Legal has screened Combat's names.

**Stamina:** no new block. The signature reads `ofEnergy` and `moveCap` from Game Design's `data/fight/vitals.json` when that file and its switch exist.

---

## 6. Pseudocode and hooks

GDScript-shaped. **"exists"** marks a function or field confirmed in the file at that line. **"new"** is this page's. **"beam page"** is a proposal from the stand-in's beam page that is not built.

### 6.1 The input layer (`sim/input/layout.gd`, `sim/input/input_data.gd`; Controls)

```gdscript
# input_data.gd, beside b_no_beam() (exists, :202)                                   -- new
static func sig_stick_on() -> bool:
	return right_stick_on() and bool(t(["switches", "sigStick"], false))

# layout.gd:1010 (exists): `_right_hand(i, mask)` gains the buttons physically down    -- changed call
	_right_hand(i, mask, on_now)       # on_now exists (:969): down or pressed this build, before the release grace (:977-981) and the one-shots (:982-987)

# layout.gd:1222, _right_hand(i: SimIntent, mask: int) (exists) becomes
func _right_hand(i: SimIntent, mask: int, on_now: int) -> void:
	...
	# before the step at :1263. The crossing build decides; _power_t0 (exists, :665) is RT's press build.
	# `mask == CHARGING` keeps a pending transform chord out: its bits were stripped from the mask at :989.
	var sig_layer: int = 0
	if sig_stick and (on_now & SimStance.CHARGING) != 0 and mask == SimStance.CHARGING \
			and (sig_chord_ticks <= 0 or tick - _power_t0 <= sig_chord_ticks):
		sig_layer = SimStance.CHARGING | (on_now & SimStance.ENERGY)               # 4, or 6 with RB down
	# RB may arrive late: a start read as 4 is held back by the reader's own floor until RB comes or the time is up.
	var floor_t: int = 0 if push_live else _law.floor_tick()                        # exists, as passed at :1263
	if _sig_wait_until > 0:                                                         # new field: 0, or the build a waiting start may go out
		if _strike.phase != SimStrikeRead.CROSSED:
			_sig_wait_until = 0                                                     # it started, or the reader let go of it
		elif (on_now & SimStance.ENERGY) != 0:
			_strike.layer = SimStance.CHARGING | SimStance.ENERGY                   # RB came: the energy signature, started this build
			_sig_wait_until = 0
		elif tick < _sig_wait_until:
			floor_t = maxi(floor_t, _sig_wait_until)                                # not yet
		else:
			_sig_wait_until = 0                                                     # the time is up: it goes out as 4
	var inert: bool = (in_struggle and not push_live) or (not push_live and ((_inert_masks.has(mask) and sig_layer == 0) or b_hold))
	var was_phase: int = _strike.phase
	_strike.step(sv[0].x, sv[0].y, sig_layer if sig_layer != 0 else mask, tick, live, floor_t, sv[1], inert)
	if sig_layer != 0 and was_phase == SimStrikeRead.IDLE and _strike.phase != SimStrikeRead.IDLE:
		_tap_voided = true                                                          # new field; cleared in _base_press("power") beside _power_voided (:666)
		if sig_layer == SimStance.CHARGING and sig_rb_ticks > 0:
			_sig_wait_until = tick + sig_rb_ticks                                   # RT alone at the crossing: wait for RB

# layout.gd:719 (exists), RT's release: the tap also needs `and not _tap_voided`.
```

- `SimStrikeRead.step(x, y, mask, tick, live, floor_tick, pressed, inert)` exists (`strike_read.gd:153`); it stores `layer = mask` on the crossing (`:178`). **Nothing in the reader changes.** The grace uses two things it already has: `floor_tick`, "the earliest tick the request may start", which `_try_start` obeys while the reader waits in its crossed phase (`:25`, `:183-187`, `:257-258`), and the public `layer` field (`:37`). `is_beam_layer` is already true for 4 and 6 (`:146-148`), which only picks the level ladder and is not read by the signature.
- With the grace on, a start read with RT alone goes out 4 builds after the crossing, where the quick read sends it 1 build after today.
- `i.rsMask = _strike.layer` exists (`layout.gd:1277`).
- `_note_inert` (`:1174-1178`) is unchanged: it only speaks when the reader went to "ignored", which a chord no longer does.
- The inert test is read only on the crossing (`strike_read.gd:173-174`), so a start that is waiting is not dropped if RT is let go meanwhile: the crossing decided.
- **Not hashed:** the layout's fields are input state, not sim state. A replay carries the result in the second word.
- **Not run:** that the reader holds a crossed flick behind a floor for 4 builds after the stick is back at rest. It does so for the reverse lockout, by its own comments.

### 6.2 The director's new file (`sim/director/sig.gd`, `class_name DirSig`; Encounter)

```gdscript
## State: seven integers on f.act.dirI after the last slot in use. On main that is DirBands' slip hold (bands.gd:76, _hb() + AH_N);
## the stray-beams park adds one after it. Encounter confirms the last slot when it builds: a clash of slots is silent.
const SG_ON: int = 0     # 0 none, 1 martial gather, 2 martial rush, 3 energy gather, 4 energy pour, 5 open after a miss
const SG_AT: int = 1     # the live tick it began, plus 1
const SG_END: int = 2    # the live tick this phase ends, plus 1
const SG_AIM: int = 3    # the flick's sector, plus 1
const SG_ST: int = 4     # the stage taken at the flick; plus STALE
const SG_RT: int = 5     # a threatened RT press waiting for the chord: its live tick, plus 1
const SG_AIR: int = 6    # the launch number a martial touch last left a body on, plus 1: one touch a launch
const SG_N: int = 7
const STALE: int = 64

static func cfg() -> Dictionary:
	return DirInterrupt.data().get("signature", {}).get("stick", {})                # DirInterrupt.data() exists (interrupt.gd:96)

static func on() -> bool:
	return DirStick.on() and SimInputData.sig_stick_on() and bool(cfg().get("enabled", false))

static func _g(f, k) / _s(f, k, v)      # as DirBeamMove._g and _s (exist, beam_move.gd:52-62): DirPlane._size(f), then resize on the first write

static func live(f) -> bool:            # read by SimDir: the charge and the refill are suspended
	return on() and _g(f, SG_ON) != 0 and _g(f, SG_ON) != 5

static func planted(f) -> bool:
	var s: int = _g(f, SG_ON)
	return on() and (s == 1 or s == 3 or s == 4)

static func busy(f) -> bool:            # gathering, rushing or pouring: the fighter's other presses are refused, and their own
	var s: int = _g(f, SG_ON)           #   guard and dodge do not count at a signature's touch (6.3)
	return on() and s >= 1 and s <= 4

## DirStick._start hands it over (6.3). i is the fighter's intent; mask is 4 or 6.
static func start(S: SimState, f, i, mask: int) -> void:
	var dir: int = DirStick.relative(S, f, int(i.rsDir))                            # exists, stick.gd:115
	var energy: bool = (mask & DirStick.RB) != 0
	var interim: bool = energy and not _space()                                     # 3.3: today's signature, today's path
	var why: String = ""
	if S.game.ko != null or _g(f, SG_ON) != 0 or DirStick._showing(S, f):           # _showing exists, stick.gd:594
		why = "set_piece"
	elif DirStick._cant(S, f):                                                      # exists, stick.gd:561
		why = DirExchange.cantWhy(S, f)                                             # exists, exchange.gd:100
	elif not SimFighter.sigFree(f) and f.ki < _price(S, f, interim):                # sigFree exists (used at exchange.gd:281)
		why = "ki"
	elif interim and S.T < f.sigReadyT and not SimFighter.sigFree(f):
		why = "cooling"                                                             # the interim keeps today's limit. exchange.gd:288-293 would refuse the
		                                                                            #   same request; this says it first, so no start cue goes out
	if why != "":
		SimFx.cue(S, f, "stick_refused", DirStick.NAMES[dir], why)                  # SimFx.cue(S, f, name, cam, bark) exists, fx.gd:664
		return
	if interim:
		SimFx.cue(S, f, "stick_start", DirStick.NAMES[dir], str(mask))
		DirStick.firing = true                                                      # exists, stick.gd:835: marks a request that is not a press of B
		DirExchange.requestAttack(S, f, "sig")                                      # exists, exchange.gd:43. It pays 45 and stamps the 15 s, as today (:344-349)
		DirStick.firing = false
		return
	if f.state == "charging":
		f.state = "free"                                                            # the charge gives way; SimDir keeps it from coming back (6.4)
	var stale: bool = bool(cfg().stale.enabled) and S.T < f.sigReadyT and not SimFighter.sigFree(f)
	var st: int = DirBeamMove.stageCount(f) if energy else 0                        # exists, beam_move.gd:71
	var g: int = (int(cfg().energy.gatherTicks[st - 1]) if energy else int(cfg().martial.gatherTicks)) + (int(cfg().stale.gatherTicks) if stale else 0)
	var now: int = DirBrawl._now(S)                                                 # exists, brawl.gd:202: the live clock, which stops in a hit-stop
	_s(f, SG_ON, 3 if energy else 1)
	_s(f, SG_AT, now + 1)
	_s(f, SG_END, now + g + 1)
	_s(f, SG_AIM, _sector(i) + 1)
	_s(f, SG_ST, st | (STALE if stale else 0))
	_s(f, SG_RT, 0)                                                                 # the chord came: the waiting burst is dropped
	if energy:
		f.beamCharge = S.T                                                          # exists: the hand's glow is drawn from it
	SimFx.cue(S, f, "stick_start", DirStick.NAMES[dir], str(mask))
	var e = DirBrawl._ev(S, f, "sig_gather", "energy" if energy else "martial", str(st))   # _ev exists, brawl.gd:252
	e.target = float(S.fighters.find(DirBrawl.rivalOf(S, f)))
	e.n = g

static func _price(S, f, interim: bool = false) -> float:
	# 45 on the interim (what the old path pays). Otherwise 45, plus 2 energy for each point of the 30 stamina the fighter
	# lacks, never more than cfg().maxPrice, once Game Design's vitals exist.
static func _sector(i) -> int:          # i.rsAim when it is not 0, else from i.rsDir: RIGHT 0, UP 8, LEFT 16, DOWN 24
static func _space() -> bool:           # cfg().energy.space and DirBeamSpace.spaceOn()                                  -- beam page

## Once a live tick, from DirStick.tick's first lines (stick.gd:759-762, exists), before the per-fighter loop.
static func tick(S: SimState, dt: float) -> void:
	if dt <= 0.0 or not on():
		return
	var now: int = DirBrawl._now(S)
	_meet(S, now)                                                                   # two rushes about to touch each other: settled before either
	for f in S.fighters:                                                            #   touch, so the slot order decides nothing
		if not SimRoster.isPrincipal(S, f):                                         # exists, roster.gd:47: only the two principals throw one (3.13)
			continue
		_burstWait(S, f, now)
		var s: int = _g(f, SG_ON)
		if s == 0:
			continue
		if s == 5:
			if now + 1 >= _g(f, SG_END): _s(f, SG_ON, 0)
			continue
		if f.state == "launched" or f.state == "down" or f.state == "dropped" or f.stunTicks > 0 or _taken(S, f):
			_lost(S, f, "hit"); continue                                            # something took the fighter: nothing was paid in a gather
		if s == 3 and (f.input.rsHeld or f.input.rsRelease):
			_s(f, SG_AIM, _sector(f.input) + 1)                                     # a stick still out aims until the fire; one let go fixed the line at the flick
		match s:
			1: if now + 1 >= _g(f, SG_END): _go(S, f, now)
			2: _rush(S, f, now)
			3: if now + 1 >= _g(f, SG_END): _fire(S, f, now)
			4: if now + 1 >= _g(f, SG_END): _s(f, SG_ON, 0)                         # the plant is over: free again (the beam may still be alight)

static func _taken(S, f) -> bool:       # a planned exchange or a set piece holds f: the running exchange is not a brawl, or DirBrawl._setPiece(ex) (exists, brawl.gd:519).
                                        #   A plain brawl does not take a signature: its blows meet the armour (contact, 6.3)

static func _pay(S: SimState, f) -> bool:
	if SimFighter.sigFree(f):
		SimFighter.lastStandUse(S, f)                                               # exists (used at exchange.gd:346)
	elif f.ki < _price(S, f):
		_lost(S, f, "ki"); return false                                             # energy was drained during the gather: lost, unpaid
	else:
		f.ki -= _price(S, f)                                                        # and the stamina, by Game Design's vitals, when they exist
	f.sigReadyT = S.T + float(cfg().stale.sec)                                      # the one stamp, hashed today (hash.gd:191)
	return true

static func _lost(S, f, why: String) -> void:
	if _g(f, SG_ON) == 4:
		DirBeamSpace.cut(S, f)                                                      # new, in the beam page's file: the fighter's live signature beam stops at
		                                                                            #   its front (stopAt), as that page rules for a shooter who is taken mid-pour
	_s(f, SG_ON, 0); f.beamCharge = null; f.rush = null
	SimFx.cue(S, f, "sig_lost", "", why)

## ---- energy
static func _fire(S: SimState, f, now: int) -> void:
	var ex = DirBrawl.exOf(S)                                                       # exists, brawl.gd:216
	if ex != null and DirBrawl.isBrawl(ex) and (ex.A == f or ex.D == f):
		DirBrawl.end(S, ex, "signature")                                            # exists, brawl.gd:492: the brawl gives way, as it does today (brawl.gd:717)
	if not _pay(S, f):
		return
	var st: int = _g(f, SG_ST) & (STALE - 1)
	f.beamCharge = null
	DirBeamSpace.fireSig(S, f, st, _g(f, SG_AIM) - 1, (_g(f, SG_ST) & STALE) != 0)  # new, in the beam page's file: fire() with five differences, below
	_s(f, SG_ON, 4)
	_s(f, SG_END, now + int(round(float(DirBeamMove.cfg().lastsSec[st - 1]) * DirData.TICKS_PER_SEC)) + 1)   # the plant: the stage's lit time from
	SimFx.cue(S, f, "sig_go", "energy", str(st))                                                              #   the fire, as the beam page plants an ordinary shooter

# DirBeamSpace.fireSig = the beam page's fire(S, A, st), except:
#   1. the line is the sector given (not DirBeamAim's throw slot), snapped onto the rival on this tick only if they are within the assist angle of it;
#   2. the variant is DirData.sigRow(DirData.sigKeyAt(x)).name for the ground under its first strike
#      (both exist: defined at data.gd:603 and :616, used today in the beam's plan at :556-557);
#   3. b.sig = 1, or 2 when stale;
#   4. b.life = b.len / b.sv * SimConst.DT + lastsSec[st - 1], read from the data directly. The beam page's fire() takes the lit time from
#      DirBeamMove.lasts(A), which reads the M_FIRED slot (beam_move.gd:311-326). Only the hold's own fire writes that slot, so for a
#      signature lasts() is -1. fireSig never writes M_FIRED;
#   5. the hit is not worked out in fire() at all. The beam page's _contact computes it with DirBeamMove.hitDamage(A, ...), which also
#      reads M_FIRED and would give the base. _contact gains a branch on the beam's own mark:
#        if b.sig != 0:
#            var hit: float = maxf(float(cfg().energy.minDamage), dmgUnit * dmgMul[b.stage - 1]) * DirBeam.sigDamageMul()   # exists, beam.gd:58
#            if b.sig == 2: hit *= float(cfg().stale.damageMul)
#            dmg = hit * (200.0 / 230.0 if guard else 1.0)                                                                   # 138 and 120 up to stage 3
# struggle_meet reads b.sig for the meeting point's x 9 (sim/world/struggle_meet.gd:89-91 takes a `sig` flag today). A signature's own
# carve has no multiplier (3.3).
# The beam page's touch() also gains `and not DirSig.busy(f)` on its dodge test: a planted fighter's own dodge press does not count.

## ---- martial
static func _go(S: SimState, f, now: int) -> void:
	var ex = DirBrawl.exOf(S)
	if ex != null and DirBrawl.isBrawl(ex) and (ex.A == f or ex.D == f):
		DirBrawl.end(S, ex, "signature")
	if not _pay(S, f):
		return
	_s(f, SG_ON, 2)
	_s(f, SG_END, now + int(cfg().martial.rush.maxTicks) + 1)
	SimFx.cue(S, f, "sig_go", "martial", "")

static func _speed(S: SimState, f) -> float:                                        # the snap's rule (gravity-well-reading.md:61)
	var v: float = maxf(float(cfg().martial.rush.floorSpeed), S.powerFlat * SimDetMath.pow(SimPower.flatGrowth, SimPower.level(f)))
	return minf(v, float(cfg().martial.rush.maxStepBh) * DirInterrupt.BH / SimConst.DT)   # S.powerFlat, SimPower.level, flatGrowth exist (state.gd:87; power.gd:20, :182)

static func _reach(D) -> float:                                                     # the chase's own reach test (chase.gd:232): the touch distance plus
	return float(cfg().martial.touchBh) * DirInterrupt.BH + SimDetMath.hypot(D.vx, D.vy) * SimConst.DT   #   the rival's movement in one tick. The tables of 3.4 use it

## Two martial rushes about to touch each other: neither string plays (3.4). First value: both are turned.
static func _meet(S: SimState, now: int) -> void:
	for f in S.fighters:
		if not SimRoster.isPrincipal(S, f) or _g(f, SG_ON) != 2:
			continue
		var D = DirBrawl.rivalOf(S, f)
		if _g(D, SG_ON) != 2 or DirBands.dist(f, D) > float(cfg().martial.touchBh) * DirInterrupt.BH + (_speed(S, f) + _speed(S, D)) * SimConst.DT:
			continue                                                                # (a rusher's own velocity is zeroed; its step is _speed)
		for g in [f, D]:
			g.rush = null
			g.stunTicks = maxi(g.stunTicks, int(cfg().martial.turnedStunTicks))
			_s(g, SG_ON, 0)
			SimFx.cue(S, g, "sig_turned", "", "met")
		return

static func _rush(S: SimState, f, now: int) -> void:
	var D = DirBrawl.rivalOf(S, f)                                                  # exists, brawl.gd:220
	var d: float = DirBands.dist(f, D)                                              # exists (used at chase.gd:228)
	if d <= _reach(D):
		_touch(S, f, D, now); return
	if now + 1 >= _g(f, SG_END):
		_miss(S, f, "short", now); return
	if DirBrawl.exOf(S) != null:
		return                                                                      # only a plain brawl reaches here (_taken took the rest): the rival's press
		                                                                            #   began one under the rush. No rush step is written over its lock. The
		                                                                            #   touch test still runs each tick, the armour holds, and the 36 ticks end it
	var r := SimState.Rush.new()                                                    # exists, state.gd:1195. The chase's pattern (chase.gd:235-265):
	r.tgt = D                                                                       # aimed at the rival afresh each tick, at a capped speed,
	r.off = 0.0                                                                     # so it never speeds up to arrive
	r.end = S.T + float(maxi(1, int(ceil(d / (_speed(S, f) * SimConst.DT))))) * SimConst.DT
	f.rush = r
	f.vx = 0.0; f.vy = 0.0

static func _touch(S: SimState, f, D, now: int) -> void:
	f.rush = null
	var m: Dictionary = cfg().martial
	var row: Dictionary = DirData.sigMartial(f.id)                                  # new reader of templates.json's sigMartial, by roster id
	var ex0 = DirBrawl.exOf(S)                                                      # startZip writes the running exchange without looking
	if ex0 != null:                                                                 #   (exchange.gd:170-182), so look first
		if DirBrawl.isBrawl(ex0) and not DirBrawl._setPiece(ex0) and ((ex0.A == f and ex0.D == D) or (ex0.A == D and ex0.D == f)):
			DirBrawl.end(S, ex0, "signature")                                       # a plain brawl between these two gives way to the touch
		else:
			_miss(S, f, "passed", now); return                                      # any other exchange, or a set piece: the rush passes
	if D.state == "down" or D.state == "dropped":
		_miss(S, f, "passed", now); return
	if D.state == "launched":
		if _g(f, SG_AIR) == D.launchN + 1:                                          # Fighter.launchN exists (state.gd:1173)
			_miss(S, f, "passed", now); return                                      # one martial touch a launch, and never the launch it made
		DirChase.blow(S, f, D, true)                                                # exists, chase.gd:326: the zip heavy's damage (132 x the link's worth)
		                                                                            #   and nothing else. It does not send.
		if D.state == "launched":                                                   # the send, as the chase's catch makes it (chase.gd:284-313), without
			var force: float = SimPower.sendForce(S, f, float(row.variants.air.force), "sigMartial.air")   # the rally's and the tap's hooks. exists, power.gd:231
			var r: Dictionary = DirLaunch.chooseLaunch(S, f, D, force, false, "", DirChase._tilt(f), true)   # exist: launch.gd:183; chase.gd:336. The
			DirLaunch.doLaunch(S, f, D, r.best, force)                              #   thrower's stick is the tilt; noKnock, so never a knock-back. doLaunch: launch.gd:980
		_s(f, SG_AIR, D.launchN + 1)                                                # read after the send: the launch it made is the one already touched
		_s(f, SG_ON, 0); SimFx.cue(S, f, "sig_touch", "air", ""); return
	if not busy(D) and S.tick - D.act.dodgeTick < int(m.dodgeTicks):                # exists and hashed (state.gd:322; hash.gd:198)
		_miss(S, f, "dodged", now); return
	if not busy(D) and D.act.guardSince >= 0 and S.tick - D.act.guardSince <= int(m.perfectTicks):   # exists and hashed (state.gd:321)
		f.stunTicks = maxi(f.stunTicks, int(m.turnedStunTicks))
		_s(f, SG_ON, 0); SimFx.cue(S, f, "sig_turned", "", "block"); return
	var variant: String = "guard" if (D.stance == 1.0 and not busy(D)) else "ground"
	var ex = DirExchange.startZip(S, f, D, "heavy")                                 # exists, exchange.gd:170: an exchange with no template; it sets both "locked".
	ex.tpl = "sig_martial"                                                          #   Never kind "sig": every `kind == "sig"` test in the director means the beam
	ex.branch = variant
	DirData._scheduleList(ex, row.variants[variant].beats, {"heavy": false}, ex.t, "A")   # exists, data.gd:442
	_s(f, SG_ON, 0)
	SimFx.cue(S, f, "sig_touch", variant, "")
# The exchange ends by itself when its beats are done (exchange.gd:794-800, exists), and frees both (endEx, :660-665).
# DirData.allows(ex, name) (exists, data.gd:747) gains one branch: for ex.tpl "sig_martial" it reads the row's `interrupts`.
# A rival whose own signature was gathering when the string took them loses it through _taken ("hit"), unpaid.

static func _miss(S, f, why: String, now: int) -> void:
	f.rush = null
	_s(f, SG_ON, 5); _s(f, SG_END, now + int(cfg().martial.missOpenTicks) + 1)
	DirBrawl._s(f, DirBrawl.OPEN_UNTIL, now + int(cfg().martial.missOpenTicks))     # exists: how a missed charged strike is left open (stick.gd:270-274)
	SimFx.cue(S, f, "sig_miss", why, "")

## ---- armour: the stick hold's two hooks in DirBrawl.contact
static func armoured(f) -> bool:        # SG_ON 1, 2 or 3
static func mediumHolds() -> bool:      # cfg().armour.medium
static func hit(S, f) -> void:          # a blow the armour did not take landed: _lost(S, f, "hit")

## ---- the burst waits for the chord (3.1, rule 4)
static func holdsBurst(S: SimState, f) -> bool:                                     # asked by DirInterrupt before a threatened press-burst
	if not on() or f.ai != null or not f.input.powerPress:
		return false
	_s(f, SG_RT, DirBrawl._now(S) + 1)
	return true

static func _burstWait(S: SimState, f, now: int) -> void:
	var t: int = _g(f, SG_RT)
	if t == 0:
		return
	if not f.input.power or now - (t - 1) >= int(cfg().burstWaitTicks):             # RT let go, or the wait is over, with no start
		_s(f, SG_RT, 0)
		DirInterrupt.burstNow(S, f)                                                 # new: _canBurst (exists, interrupt.gd:491), then burst(S, f) (exists, :501),
		                                                                            #   and f.act.burstFired = true so the tap on the same release does not ask twice
```

### 6.3 Hooks in existing director files (Encounter)

| File and line (exists) | Change |
| :--- | :--- |
| `stick.gd:449-450`, in `_start`, after `var mask` and **before** `if (mask & RB) != 0:` | `if DirSig.on():` then two lines. `if DirSig.busy(f):` cue `stick_refused` `set_piece` and return (a new stick strike while the fighter's own signature is live). `if (mask & 4) != 0: DirSig.start(S, f, i, mask); return`. Without the second a layer of 6 is read as an RB beam, because 6 & RB is not 0 |
| `stick.gd:759-762`, `tick` | `DirSig.tick(S, dt)` after `DirBeamMove.stamp(S)` |
| `stick.gd:248-253`, `holdMove` | first line: `if DirSig.planted(f): return 0.0`. This scales flight speed only (`sim/core/fighter.gd:608-612`); the comment there says a held beam has no dash |
| `exchange.gd:50`, `_request`, first lines | `if DirSig.busy(A) and not DirStick.firing:` cue `stick_refused` `set_piece` for a player, and return. The press is spent, never queued: a planted or rushing fighter's face press asks for nothing. Without this a press outside a brawl would start a planned exchange and `_taken` would end the fighter's own gather |
| `brawl.gd:725`, `press` | first line: the same refusal while `DirSig.busy(f)`. Inside a brawl every press is a blow, so without this a gathering fighter keeps brawling under their own signature |
| `interrupt.gd:491`, `_canBurst` | `if DirSig.busy(f): return false` |
| `brawl.gd:1368-1373`, `contact` | beside `DirStick.armoured(S, o)`: the same branch for `DirSig.armoured(o)`, with `DirSig.mediumHolds()` |
| `brawl.gd:1451`, `contact` | beside `DirStick.holdHit(S, o)`: `DirSig.hit(S, o)` |
| `brawl.gd:3177-3180`, `isB` | the keep-RT clause is deleted; with `bNoBeam` on, every player's `sig` press that is not the stick's own is B's heavy |
| `interrupt.gd:393-395` | `threatened` becomes `threatened and not DirSig.holdsBurst(S, f)` for the press case only; the tap case is unchanged |
| `exchange.gd:281`, `:348`; `beam.gd:129-134` | the literal 45 reads `signature.stick.ki` (the audit's supporting row: numbers from data). **The refusal at `:288-293` is not touched.** It is the old path's, and the interim goes through it. A signature `DirSig` runs itself never reaches `_start` as kind `sig`, so it is never refused there; that is how `stale` replaces the refusal |
| `ai.gd:261-263`, `:275-277`; `brawl.gd:4120-4122` | each becomes: `if DirSig.on(): DirSig.aiStart(S, f, o, i)` (false means no press: the beat is kept), `elif not DirBeamMove.aiStart(S, f, i): i.sig = true; i.stanceMask |= 4` (today's two lines, unchanged). `DirBeamMove.aiStart` must not be asked first: with its switch on it returns true whenever the stick is idle (`beam_move.gd:149-158`), and `DirSig.aiStart` would never run |
| `data.gd:747-757`, `allows` | the `sig_martial` branch |

**The thrower's own guard and dodge while planted.** The dodge stamp is written in the core (`sim/core/act.gd:66-67`) and is left alone. The two touches that read it for a signature (the beam page's `touch` and `DirSig._touch`) ignore the stamp, the fresh guard and the guard stance of a body whose own signature is live. Whether a planted fighter's held guard still counts against every other blow is not specified here (open ruling 9): the stance is read inside `SimDamage.hit`, which this page does not touch.

```gdscript
## The computer's signature, through the fields a pad sends (as DirBeamMove._aiStick does for a beam, beam_move.gd:183-188, exists).
static func aiStart(S: SimState, f, o, i) -> bool:
	var energy: bool = _aiPick(S, f, o)                # 3.9; false when neither is in reach: no press, the beat is kept
	...
	i.stanceMask |= 4
	i.rsStart = true
	i.rsRelease = true                                 # a flick: it starts and throws together, as the reader reports one (strike_read.gd:271-272).
	                                                   #   So its line is fixed at the flick (3.9)
	i.rsMask = 6 if energy else 4
	i.rsDir = SimStrikeRead.RIGHT if SimWrap.sdx(f.x, o.x) >= 0.0 else SimStrikeRead.LEFT
	i.rsAim = _aiSector(S, f, o)                       # the sector nearest the line to the rival, with the level's keyed slip
	return true
```

### 6.4 The core (`sim/core/dir.gd`, `sim/core/fighter.gd`; Simulation, by grant)

```gdscript
# dir.gd, beside refillHeld (exists, :51-52)                                         -- new
static func sigLive(f) -> bool:
	return _d("sig.gd").live(f)

# dir.gd:51-52, refillHeld (exists): energy does not refill while a signature is live
	return _d("beam_move.gd").refillHeld(f) or _d("sig.gd").live(f)

# fighter.gd:730 (exists): `if i.charge:` becomes
		if i.charge and not SimDir.sigLive(f):
```

- `tools/load_split.gd` checks that every function named in `dir.gd` is in its script, so `live` must exist in `sig.gd` in the same change.
- With the switch off `live` returns false at once: the same branch is taken and no bit moves.
- `sim/core/replay.gd:226-227`: beside the `rightStick` line, `if SimInputData.sig_stick_on(): h.text("sigStick")`.
- `sim/core/state.gd`, class `Beam`: `var sig: int = 0`, hashed and kept by `net/desync.gd` only inside the beam page's "beam in space" group.

---

## 7. What breaks

| Thing | What happens to it |
| :--- | :--- |
| `strike_gate_test.gd` `_row_inert` ("inert: RT held, the stick starts no strike", `:603-624`) | Holds with the switch off. Needs its twin with the switch on |
| `inert_knock_test.gd` (11 checks) | The "charging" rows hold only off, or outside `sigChordTicks` |
| `b_no_beam_test.gd`, `b_no_beam_layouts_test.gd` ("RT + B on the pad is still the signature", `:42`) | Reversed: RT + B is the heavy. Rewritten in the same change |
| `stray_beam_check.gd` (parked): its RT + B rows at 0, 12, 13, 26 ticks | All four become "the heavy". The dropped-release rows are unaffected |
| `aim_throw_check.gd` (parked): "the signature fires at him" | Holds on the old path. In space the signature has its own aim and never reads the throw slot |
| `beam_move_check.gd:337` ("off, the stick's beam is the signature's request: 45 and its wait") | Holds with the director's switch off, and on the interim, where the old path's wait stays |
| `beam_front_check.gd`, `beam_ai_check.gd` | Their signature rows press `sig` directly (a B). They keep passing as tests of the old path; each needs a row through the chord. None runs in CI today except as the audit asks for `beam_ai_check` |
| `DirBrawl.tellTick`, `DirBeamPlay.lateTick`, the arrival windows, the shove, the travel row `front.rows.signature` | Not used once the energy signature is in space. They stay for the interim |
| The aftermath twists, `DirSigAfter.under`, `wall`, `skate` | Go quiet for a beam in space (departure 14) |
| Banners "NEED 45 KI", "SIGNATURE RECHARGING" | Stop. UI's refusal word takes over |
| `beam_window`, `beam_late`, `beam_arrive`, `beam_shove` cues | As the beam page: gone or replaced, for the signature too once in space |
| Animation: `attack` with kind `sig` plays beam poses | The martial signature sends no `attack` of kind `sig`. It needs poses keyed to `sig_gather`, `sig_go`, `sig_touch`, `sig_miss`, `sig_turned` |
| Audio, Camera, VFX, UI, Controls' haptics | One reader each for the new cues. `sig_gather` with a target is the rival's warning: the pad and UI's edge line read it |
| UI's how-to and legend ("Signature: RT + B") | New words, shown to Orb before use |
| QA's beam trace | Gains the source of every beam and signature (below) |
| The computer's pacing bands ("2 to 5 a match", `balance-targets.md:270`) | Need a new reading with two signatures that can miss |
| The computer's ordinary beam | With `DirSig` on, nothing starts it until the beam page's shot choice is built (section 3.9) |
| A released RB beam that fires late on the old path | Still possible until `dropOnPress` lands and the beam in space replaces the wait; the source check lists it apart (section 3.2) |
| The JS parity core | Has no second intent word (`sim/input/intent.js`), so it cannot play either chord. Named as a gap, not fixed here |

**Checks to write.**

| Check | Owner | What it asserts |
| :--- | :--- | :--- |
| `sig_chord_test.gd` (input) | Controls | The table of 3.1 over scripted pads: RT then flick; RB, RT then flick; flick then RT; same build; **RB 1, 2, 4 and 5 builds after the crossing (energy, energy, energy, martial); RB let go 1 and 2 builds before it (martial); RT let go 1 and 2 builds before it (inert, "Charging"); RT tapped with the one-shot option on, then a flick with RT up (inert);** LT + RT + flick; RT + X then flick; LB + RB + flick; the D-pad mirror, counted apart; `sigChordTicks` 0 and 12; `sigRbTicks` 0 and 4; the build the start goes out on, for each. With a refusal count per input |
| `sig_source_check.gd` (director) | Encounter | **The count for X-17.** Every beam appended to `S.beams`, every exchange of kind `sig` and every `sig_gather` is matched to a second-word edge of its thrower: `rsMask` 4 or 6 on that tick or inside the gather for a signature; an RB layer's release for a beam, on that tick, **or up to `ownMove.maxWaitTicks` earlier on the old path provided no other press of theirs came between, and then it is listed apart as "fired late" with its delay.** Anything unmatched is counted by source. Spawned beams (split, swat) and a finisher's beam are listed apart; so are signatures from the D-pad. **Negative rows, each must fire 0:** B alone; B with LB, RB, LT; RT + B at 0, 6, 12, 13, 26 ticks, free and locked in a brawl; RT + X, Y, A; RT tapped; RT held 5 s; a plain flick; LT + RT + a flick; a flick 1 and 2 builds after RT is let go. **Interim row:** a second RT + RB + flick inside 15 s is refused, cue `stick_refused` `cooling`, and starts nothing. Run for a player and for the computer at each level, with the computer's hold-and-release switch on and off (on, it must still throw both signatures) |
| `sig_energy_check.gd` | Encounter | The gather by stage; planted; armour rows (light, medium, heavy, grab); **a face press, an RT burst and a new stick strike during the gather and the pour: each refused with `set_piece`, none starts anything, the gather goes on; LT held or tapped does not move the fighter, and its dodge does not count when a signature touches them;** nothing paid when stopped; paid at the fire; `sig_lost` `ki` when energy is drained below the price during the gather; stale after a first; the hit's damage by stage, guarded and not, fresh and stale (138, 120, 103.5 at base); the beam's lit time by stage (it must not be the -1 of a beam with no stage slot); the shooter taken mid-pour cuts the beam at its front; **aim: a flick let go keeps the flick's line, a stick held out follows to the fire, and the snap happens only inside 15 degrees at the fire;** the cells of tables A and B of 3.3 |
| `sig_martial_check.gd` | Encounter | The rush's speed by tier; each cell of the two "what the rush catches" tables within 2 ticks, with the code's own reach test; a rival who leaves on the gather's 14th tick; each row of the touch table; **the `ground` variant always ends in a launch, never a knock-back or a stagger; a second martial touch in one launch is a miss; a brawl the rival starts under the rush is ended at the touch and never left running under the string; any other exchange at the touch is a miss; two rushes meeting turn both, with the slots swapped and the same result;** a face press during the gather and the rush is refused; the string's length; the burst inside it |
| `sig_agency_check.gd` | Encounter | Over both signatures: ticks the rival's state was not their own, and units they were moved, before the first touch: 0 and 0. The same for a third body standing on the beam's line and in the rush's path. On the interim energy path the reading is today's and is reported, not passed |
| `sig_off_check` (the golden) | Simulation | The switch off: the golden record byte for byte. On: two runs identical; a replay made on refuses to play off ("data") |
| The data job | Tools | The three schemas |

---

## 8. Build order and owners

Every step is behind its switch and lands only through the EP's gate. Steps 1 to 4 need nothing from the beam trial.

| # | Step | Owner (path) | Needs first | Window |
| ---: | :--- | :--- | :--- | :--- |
| 0 | Game Design rules the 20 open points and the 21 departures; the EP asks Orb section 11 | Game Design; EP; Controls on rulings 16 and 17 | this page | paper |
| 1 | **The read.** `sigStick`, the strike's layer 4 and 6 from the buttons physically down, the RB grace, the voided tap, `sig_chord_test` | Controls (`sim/input/`); `data/input/timing.json` and its schema by grant | step 0's rulings 3, 16 and 17 | parked now; lands in GW2 |
| 2 | **The door.** `DirSig` with `start`, the refusals (the planted fighter's other presses among them), the interim energy path with today's limit kept, the hook in `DirStick._start`; `isB` without the keep-RT clause; `bNoBeamKeepRt` off; `sig_source_check` with every negative row | Encounter (`sim/director/`, `data/director/`) | step 1; **the stray-beams park's `dropOnPress` landed (listed for GW1b), or the count of reading 1 cannot be 0** | GW2 |
| 3 | **The core's two lines** and the replay key | Simulation (`sim/core/`) | step 2's `live` | GW2 |
| 4 | **The martial signature with one stand-in row:** gather, armour, rush, touch (with the running exchange looked at first), the meeting of two rushes, the miss and the turn, the string from a placeholder beat list shared by both fighters; `sig_martial_check`, `sig_agency_check` | Encounter | step 3; `power.json` share keys (Simulation) | GW2 |
| 5 | **The energy signature in space:** `fireSig` and the cut, the beam's `sig` mark, the signature branch in the beam's contact, the gather, stale; `sig_energy_check` | Encounter; Simulation for the `Beam` field and its hash | the beam in space landed behind its switch (the audit's row A-COMBAT-01) | GW2, after the beam |
| 6 | **The burst's wait** | Encounter | Game Design's rulings 4 and 16 | GW2 |
| 7 | **The computer:** `aiStart` in place of the beam hold at its three signature moments, its pick, its answers; the source check run for it | Encounter (`ai.gd`, `data/director/ai.json`) | steps 4 and 5; **the beam page's shot choice for the computer, or it fires no ordinary beam** | GW2 |
| 8 | **Content:** each fighter's three variants, pieces and a name; the pages for Orb | Combat (`docs/combat/`; `templates.json` by grant); Animation's poses; Legal on names through the EP | step 4's shape frozen | GW2 for the data; poses behind the look gate |
| 9 | **Readers:** cues in Audio, Camera, VFX, UI (words, the how-to), Controls' haptics | each director's own path | step 2's cue list frozen | no hash; the look gate |
| 10 | **Costs from the model:** the stamina line, the fall-through and its cap | Encounter with Simulation | Game Design's vitals built; ruling 15 | GW2 |
| 11 | **Readings** (section 9) and the clip for Orb with the pad's inputs drawn at the bottom | QA; Tools | steps 4 and 5 | after GW2 |
| 12 | **Retire** the old signature path, the interim, `provisional`'s refusal and the `sigStick` switch | Encounter | Orb has played both; the look gate | a later window |

---

## 9. Readings

| # | Reading | First pass line | Measured with |
| ---: | :--- | :--- | :--- |
| 1 | Beams and signatures started by any input but the four intended ones, player and computer. Beams that fired late from a waiting release, and signatures from the D-pad, are listed apart | **0** strays; the late and D-pad counts reported | `sig_source_check` on the scripted set, and QA's beam trace on play files saved on this build (tool to extend) |
| 2 | Signatures from RT + B, at any gap, free or in a brawl | 0 | the same; Orb's tick 6617 re-staged |
| 3 | Ticks a rival was held, and units moved, by a signature before it touched them | 0 and 0 | `sig_agency_check`; today's baseline from the same probe on the old path |
| 4 | Chord attempts on a scripted pad that became something else, per input | 0 for every row of 3.1 | `sig_chord_test`'s refusal count |
| 5 | A person's chords: of Orb's signature attempts on the next play file, the share that fired; **how many came out as the other signature;** the gap from RT's press to the crossing, and from the crossing to RB | reported; the gaps set `burstWaitTicks`, `sigChordTicks` and `sigRbTicks` | Controls, from the saved match (the pad lab exists) |
| 6 | Bursts fired within 12 ticks before a signature's gather by the same fighter | 0 | the cue stream |
| 7 | Energy signature, scripted rival and scripted thrower: the thrower flicks and lets go, or holds the stick on the rival to the fire; the rival stands, flies across from the gather's start, or dashes from its 14th tick; at 10, 20, 40, 60 body heights, stages 2 and 6 | each cell as tables A and B in 3.3; a cell within 15 units of the width or 1 degree of the cone is reported, not judged | QA's escape probe (exists for beams) with a gather and a scripted stick |
| 8 | Martial rush: each cell of the two tables in 3.4, the same-form cells at every form among them, and the rival who leaves on the gather's 14th tick | within 2 ticks | `sig_martial_check` |
| 9 | Gathers stopped, by what; the share of signatures that were stale; **the share of gathers started inside a brawl, and how those ended** | reported; if over half of all gathers are stopped against the computer on medium, the armour or the gather is wrong; if nearly every gather inside a brawl gets through, the medium armour is too much | the cue stream over QA's matches |
| 10 | Signatures a match, and their share of all damage | reported first. The recorded band is 2 to 5 a match (`balance-targets.md:270`), written for one signature a fighter under a cooldown; Game Design sets the new band after the first reading. At most 30% of damage (the band already on the provisional limit) | QA's batch |
| 11 | The longest time a player is planted or held by their own or a rival's signature | at most 2.8 s (a stale top-stage gather and its pour: 78 + 90 ticks) | the cue stream |
| 12 | Hash: switch off against the golden; two runs on; an on-replay played off | identical; identical; refused as "data" | `sig_off_check` |
| 13 | Refused signature flicks with no cue | 0 | the hub's ledger (`tools/feel/ledger.mjs`) |
| 14 | A person's check: on the play page, "did a signature fire that you did not mean?" | no | Orb's answer |
| 15 | **Signatures thrown from the charge:** those whose flick came more than 12 builds after RT's press, split by whether the rival was inside striking range at the flick and by what happened next (touched, missed, stopped) | reported from every saved match; Controls reads Orb's. Many thrown with the rival in striking range and then stopped is the sign of flicks meant as plain blows | the cue stream and the saved inputs |
| 16 | The computer with its beam hold switched on: signatures of each kind a match | more than 0 of each | QA's batch |

---

## 10. Size

**Extra-large by the audit's scale: about 6.5M to 9.5M tokens across directors, not counting the beam in space.** The audit sized this row large (`docs/ep/alpha/audit-2026-11-13/03-gap-register.md:12`), and its large is about 4M, 2M to 6M (`04-path-to-alpha.md:46`; `alpha-audit-specification.md:568`). So this page says the row has grown by 2.5M to 5.5M. The reasons: the martial signature is a new system with its own state, checks and content, and five directors read new cues. The third milestone's 53M would rise by the same amount, in the milestone the path already calls "most likely to overrun" (`04-path-to-alpha.md:216`). The EP should have this before the row is briefed.

| Piece | Size | It depends on |
| :--- | :--- | :--- |
| The read, with the RB grace (step 1) | S | The reader holding a start behind its floor, as read (not run) |
| The door, the removal of RT + B, the refused presses, the source check (2, 3) | M | The slot chain being confirmed; `dropOnPress` landed first |
| The martial signature's rules (4) | M to L | Whether the no-template exchange, the chase's blow and the launch planner's send can be called from here unchanged (not verified) |
| The energy signature in space (5) | S, once the beam exists | **The beam in space.** If that slips, the interim stands, with today's hold and today's 15 s refusal, and the milestone's "not the one beam that still finds you" does not |
| The computer (7) | M | The beam page's aim and shot choice landing first |
| Content (8) | M | Combat's pieces and Animation's poses for two fighters; names through Legal |
| Readers (9) | M, spread over five directors | The cue list not changing after step 2 |
| What could be cut to stay at large | | The burst's wait (step 6); the computer's answers by level (part of step 7); the `guard` and `air` variants, with one `ground` variant each at first; the RB grace, if Controls' reading of Orb's file shows it is not needed |
| What would double it | | A ruling that the martial signature is a fourth request kind through the queue; or a per-direction signature (four flicks, four moves) |

The sizes are classes, not quotes: S about 0.25M, M about 1.2M, L about 4M. The pieces add to 6.5M at the low end and 9.3M at the high end before the two new checks' rows and the RB grace.

---

## 11. For Orb

Drafts for the EP to ask, one at a time, under a clip of both signatures with the pad's buttons drawn along the bottom. The stand-in decides nothing here.

**1. What should the martial signature be?**
- **A rush and a string.** Your fighter coils, rushes the rival, and if the rush touches them plays four quick blows and a launcher. About a second and a half from the flick to the launch.
- **One huge blow.** Your fighter coils for longer, rushes, and lands a single hit that sends the rival flying. Shorter, simpler, and all or nothing.

I think Orb would want the rush and the string: it shows off each fighter's own style, and its last blow uses the launches the game already has.

**2. You are holding RT to charge your energy, and you flick the right stick. What happens?**
- **The signature fires,** any time RT is held. You can charge up and let it go in one motion. The catch: if a rival comes at you while you charge and you flick the stick to hit them, you throw your signature instead of a plain blow.
- **Only just after you press RT.** Once you have been charging for a fifth of a second the flick does nothing and the pad knocks. Safer against firing one by accident; you would let go of RT and press it again to throw one.

I think Orb would want the first: it is the chord as you named it, and charging up into a signature is the moment the charge is for. If signatures start firing when you did not mean them, the second is one number away.

**3. Throwing signatures back to back.** Today the game refuses a second signature for 15 seconds and says "recharging". The 15 seconds is the number from your slider answer of 2 October, in place of two minutes.
- **Never refuse.** A second one inside 15 seconds takes about a third of a second longer to gather and hits for a quarter less, so the rival has an easier time stopping it.
- **Keep a wait,** as today.

I think Orb would want the first, from "I just didn't like the cooldown" and from your note that you are not a fan of cooldowns and recharging "exccept in limited circumstances". If a signature is one of those circumstances, the second choice is yours.

**4. You flick for the energy signature and let the stick go. The rival moves while your fighter gathers. Where does the beam go?**
- **Where you flicked.** The beam is yours to aim. To follow a moving rival you keep the stick pushed toward them until it fires. A flick you let go of will miss anyone who moves.
- **It follows the rival while they stay close to your line.** The gather keeps the beam on them unless they get well off to one side. A flick is enough, and the game is doing some of the aiming for you.

I think Orb would want the first, because you said "A sounds good" to a beam in space that is aimed with the stick. It is the least sure of the four: the first choice makes a quick flick the weaker way to throw the move you named as a flick.

(For the EP, not for Orb's page: Orb's words above are at `docs/ep/vision.md:523`, `:1412` and `:1693`; at `:1693` only "A sounds good" is Orb's, and the description of the beam beside it is the EP's. The slider answer is the EP's own summary at `:509`. The fourth question is open ruling 11.)

---

## 12. Risks, unknowns and what was not verified

- **The energy signature in space rests on code that does not exist yet.** `DirBeamSpace`, the beam's speed and width fields and `beamPlays.space` are the stand-in's proposals. If the trial changes them, section 6.2's `_fire` changes with them. The signature also needs two things inside that code that the beam page does not have: its own lit time and its own damage branch at the touch.
- **If the beam in space slips, the interim is what gets played:** today's beam on the new input, with the rival held from the press and the 15 s refusal. Only the input and the removal of RT + B would be new.
- **A flicked energy signature misses anyone who moves on the gather.** By the model, a flick let go lands only on a rival who stands, or who drifts at range. A held stick tracks. This is the largest open design question on the page (ruling 11, question 4), and the computer as written always flicks.
- **A stray signature by another name.** With a flick during the charge allowed, a player who is charging and flicks to strike an approaching rival throws a 45-energy signature and is planted half a second. X-17 will not count it, because the input is the intended one. Reading 15 counts it, and reading 14 and question 2 are Orb's own check. The window is one data number.
- **One finger, two triggers.** Controls rejected RT + RB as a grip. Orb named it. Whether it can be held and flicked comfortably on a pad is unmeasured (reading 5). The RB grace is there because three controls do not land on one build; if it is too short, players get the martial signature when they wanted the beam, paid in full and with no cancel. If it is too long, the martial signature feels late.
- **The burst waits 10 ticks** when RT is pressed and held under threat (7 without the RB grace). A tapped burst is unchanged. That is a sixth of a second on the escape a pressed fighter reaches for; Game Design's ruling 4.
- **The gather may be too safe or too exposed.** A fresh 30-tick gather cannot be stopped by a medium at all, or by a heavy thrown on reaction; only a grab or a heavy already winding stops it. Inside a brawl that is an armoured half-second reversal against lights and mediums, and it departs from the recorded rule for a beam's hold (section 4, row 18). A stale one can be stopped by a heavy. Reading 9 decides.
- **A planned exchange that takes a gathering fighter ends the gather with no blow landed.** Against a standing fighter in the close band a rival's press starts a brawl, whose blows meet the armour (`brawl.gd:267-271`, read, not run). From outside the close band, or with an opening to spend, it is a planned exchange, and the gather is lost. How often that happens is not measured.
- **The martial string holds the rival for up to 0.9 s.** It is held only after the touch, which is the rule Orb's words allow, and the burst is live. It is still the longest hold a player can put on another outside a finisher.
- **The rush can be out-flown, and above base it has no margin at all.** A same-form rival who flies off on the gather gets away at every form; above base, one who flies off the moment the rush leaves gets away from a brawl's distance. The escape costs the rival about 7 stamina and the thrower 45 energy, 30 stamina and half a second open. If that makes the martial signature useless against a rival who simply flies off on every gather, the levers are the rush's margin (ruling 14) and the gather's length.
- **The rush has a reach.** A rival standing beyond about 33 body heights at base is not reached, after the price is paid. That departs from pillar 3 (section 4, row 17).
- **A winded fighter's signature costs up to 90 energy** under the cap proposed here, and under the model alone it could not be thrown at all below 2.5 stamina. Either may read as "the button stopped working" to a winded player with less than a full line. The refusal says "No energy", with the model's own sound for stamina paid from energy.
- **The computer.** Its pacing was tuned for signatures that always land. With `DirSig` on it fires no ordinary beam until the beam page's shot choice is built. As written it flicks, so its energy signature's line is fixed at the flick.
- **A released RB beam can still fire late on the old path** (up to 90 ticks) until `dropOnPress` lands and the beam in space replaces the wait. It is the fault Orb felt, and this page does not fix it.
- **More than two bodies are not designed** beyond the first rules of 3.13.
- **The rival's energy signature is a beam with a volley's name.** Named for Combat and UI; not fixed here.
- **The slot chain.** The seven new integers go "after the last slot". On main that reads as DirBands' slip hold, and a parked fix adds one more. Slots are positional and a clash is silent: Encounter must confirm at build time.
- **The size has grown** past the audit's class for this row (section 10).
- **Not verified by me:**
  - that `DirExchange.startZip` can be called for an exchange that is not a zip without `DirZip` or `DirBrawl.quiet` treating it as one;
  - that ending a brawl with `DirBrawl.end` and calling `startZip` on the same tick is clean (`brawl.gd:492-506` read: it ends the exchange and marks its beats done; not run);
  - that `DirChase.blow` and `DirChase._tilt` can be called outside a chase, that `DirLaunch.chooseLaunch` and `doLaunch` behave for this caller without the catch's rally, swing, calm and camera hooks, and that `doLaunch` is where a body's launch number moves;
  - that `DirBrawl.press` and `DirExchange._request` are the only two doors for a planted fighter's face press (`pressInStun` and `pressedOut` exist beside `press` and were not read);
  - that the slip and the dash do not move a fighter whose `holdMove` is 0.0 (`flightSpeed` scales the flight speed by it, `fighter.gd:608-612`; the slip's own movement was not read);
  - where a planted fighter's held guard is read for blows other than a signature's touch;
  - that the input reader holds a crossed flick behind its floor for 4 builds after the stick is back at rest;
  - how `requestAttack` queues a request that has to wait on the interim path, and so whether an interim signature can start some ticks after its flick;
  - the kept build's own data for the computer's beam hold (`ownMove.enabled` and `ownMove.ai` true): read by the review's checker in the build's folder, not by me; main's are both false (`interrupts.json:294`, `:303`);
  - a Legal row the review named on how long a signature's hold lasts (RL-239), written for an earlier paper design: not opened. Whether it bears on a 30-tick gather is the EP's to route;
  - that the `launch` beat marks the exchange decisive as a template's does, and so can start a finisher against a rival on the brink;
  - the order of the fighters' step and the director's update inside a tick, so whether the gather's first tick is the flick's tick or the next, and whether a rush's last step can come before its touch test;
  - whether the hub's "No answer" timer treats `stick_start` from this new caller as it does the stick's own;
  - the keyboard presets: whether a key bound as the strike works with the power key held;
  - how VFX, Animation and Audio read `attack` of kind `sig` today, beyond the reviewers' list of files;
  - Game Design's tier figures for the snap (about 4,640, 6,090, 8,070), which this page now uses throughout, against what `_speed` would give from the level with no power banked (the first model read the tier share only: 4,373, 5,464, 6,827); the rule is the same and the level is read directly;
  - every number in the tables: they are from the model, not from the game. The model moves a rival straight across or straight away at a fixed speed, with no turn, no terrain and no depth.

---

## Checks

Two independent reviewers attacked the draft, one reading it against the code and one against the design record, and each blocker they raised was then given to a checker whose job was to refute it. Their other findings were not sent to a checker: the fixer checked each one against the files or by arithmetic (`sigmodel2.js` in the stand-in's scratch folder) before using it.

| Finding (plain words) | Verdict | What changed |
| :--- | :--- | :--- |
| **Blocker.** The martial touch started its string over an exchange that was already running, without ending it | **Fixed.** The checker could not refute it, and added that the armour reader is called in more places than the finding said and that the rival's path opens only on a rush's last step | The touch now looks first: a plain brawl between the two is ended, any other exchange is a miss. The rush writes no step over a brawl. The thrower's own presses are refused while their signature is live. New rows in the martial check (3.4, 6.2, 6.3, 7) |
| **Blocker.** With the computer's beam hold switched on, as in the builds Orb plays, the computer would never throw either signature | **Fixed, with the checker's corrected order.** The reviewer's own fix would have broken "it waits for its next beat" | With the new signatures on, the computer's three signature moments ask only the new code. A consequence is named: it fires no ordinary beam until its shot choice is built (3.9, 6.3, 7, 8, 12) |
| **Blocker.** The interim energy signature had no 15-second limit and no stale cost | **Fixed, using the checker's corrected statement.** The checker found the finding overstated: the 45 energy and the one-exchange rule still limited it, and today's beam can be dodged, guarded or clashed | The interim keeps today's refusal, said first by the new code with the "Cooling" knock. Stale replaces the refusal only for signatures the new code runs itself. A check row and a risk line (3.1, 3.3, 3.5, 5, 6.2, 6.3, 7, 12) |
| The string's last blow could land as a knock-back or a stagger, not a launch | Fixed (the gate is on in data; the beat needed `forced`) | The launch beat carries `forced` and `why`; a check row (3.4, 5, 7) |
| The blow used on a launched rival deals damage only and sends nobody; nothing stopped a second touch in one launch | Fixed | The send is the launch planner's, as the chase's catch calls it. A seventh state slot holds the launch already touched. A check row (3.4, 3.11, 6.2) |
| The signature beam's lit time and damage were read from a slot the signature never sets, so the 138 would never appear and the lit time would be -1 | Fixed | `fireSig` sets the beam's life from data. The damage is a branch on the beam's own mark where it touches. Listed as differences 4 and 5 (3.3, 6.2, 7) |
| The "x 9 ground damage for a signature" is the struggle meeting point's number, in a block that is off, not a carve multiplier | Fixed (a record error in the draft) | The carving row, the comparison table and ruling 7 rewritten (3.3, 3.8, 3.12) |
| The data block labelled "all off" would have made B the heavy on main | Fixed | Two snippets: main as it is, and the build that turns the chord on (5) |
| "Planted, no other action" had no mechanism: the thrower's face presses, burst and new strikes still worked | Fixed, by refusing them. The thrower's held guard against other blows is left open and named | `busy`, four new hooks, refusal rows and check rows. The thrower's own dodge and guard do not count at a signature's touch (3.1, 3.7, 6.2, 6.3, 7, ruling 9) |
| The rush table used a shorter touch distance than the code | Fixed, by keeping the code's test and recomputing | "touch at 30" is 23; the full-power example is 18 ticks, not 19 (3.4) |
| The rush has no speed margin over a same-form rival above base, and the page mixed two sets of speeds | Fixed in the words and tables; **the rule itself is kept and is a risk** | Section 1 no longer says "faster than flat-out flight". Game Design's figures are used throughout (the reach at full power is 64 body heights, not 55). Same-form tables by form, the rival who leaves on the gather, ruling 14 made concrete (1, 3.4, 4, 9, 12) |
| The 36-tick end gives a melee signature a reach, and the page said both "falls short" and "you cannot walk away" | **Kept as a risk and named.** The reviewer's other arm (a rush that runs until it stops gaining) was not used: at base it would always arrive, which undoes the reason for letting the rush be out-flown, and that choice is Game Design's | Departure 17, ruling 19, the contradiction removed, "Pillar 3 still holds" deleted (3.4, 4, 12) |
| The escape table assumed the beam's line snaps onto the rival at the fire, but a flick fixes the line 30 to 60 ticks earlier | Fixed in the table; **the rule is left open** as the page's largest design question | Two tables (flicked and let go; stick held out). Rule 2, the aim row, ruling 11, the computer's aim, reading 7 and a fourth draft question for Orb. The base "stands and reacts" figure corrected from 40 body heights to 29 (1, 3.1, 3.3, 3.9, 3.12, 9, 11, 12) |
| A signature can be thrown by accident from the charge, the count cannot see it, and the question to Orb hid the cost | Fixed in part; **the first value (any time RT is held) is kept and is a risk** | RT and RB are read physically, so the release grace and a tapped RT no longer throw one. The D-pad became an open ruling. Reading 15. The cost is in the question's first choice. Departure 2 cites the earlier RT + stick line (3.1, 4, 9, 11, 12) |
| No window for RB: a player a build late with RB got the wrong signature, paid in full | Fixed, as a proposal | `sigRbTicks` 4, using the reader's own floor. Its cost is named (a later martial start) and the reviewer's way of paying (a shorter gather) is the ruling's other arm, not used because it changes the rival's warning. The burst's wait became 10 ticks to cover it (3.1, 5, 6.1, 7, 9, ruling 16) |
| Two martial signatures meeting were decided by slot order; Game Design's frame says they struggle | Fixed for the order; the struggle is left open | Both are turned, settled before either touch. Departure 19, ruling 18, a check row with the slots swapped (3.4, 3.8, 6.2) |
| The record on the signature limit was incomplete: the 15 s is Orb's own slider answer, Orb has a more direct sentence on it, and Game Design later ruled a 3 s shared cooldown | Fixed | The record in order in 3.5; departure 4; question 3 says where the 15 came from and quotes both of Orb's lines |
| A medium not stopping the gather departs from the ruling's own answer up close, and was not in the departures | **The proposal is kept; the departure is named** | The "up close" line corrected, departure 18, ruling 8 with its other arm, reading 9 counts gathers inside a brawl (3.3, 3.4, 4, 9, 12) |
| "Never refused for stamina" and then a refusal caused by stamina | Fixed | The whole price is capped at `maxPrice` 90, ruling 15, departure 21. The reviewer's extra (make a winded signature stale too) was not used: one cost is enough for a first value (3.5, 5, 6.2) |
| The size line misread the audit's classes | Fixed | Extra-large, 6.5M to 9.5M, what it adds to the milestone and what could be cut (10) |
| Removing RT + B does not fix the beam Orb felt after pressing face buttons | Fixed | Section 1's words, a row in section 2, the source check's "fired late" line, step 2 now needs the earlier fix landed first (1, 2, 3.2, 7, 8) |
| The page was silent on more than two bodies | Fixed, as first rules | Section 3.13, ruling 20, a row in the agency check |
| The shooter's plant ends before the beam does at range, and a shooter taken mid-pour did not cut the beam | Fixed | Stated in 3.3 and 3.7; `_lost` cuts the beam (6.2) |
| Minors: two functions cited where they are used, not defined; UI's refusal words; the 2.5 s pass line beaten by the stale rule; the "2 to 6 a match" band with no source; `sig_lost` with only one reason | Fixed | Line references; "In flight", "Knocked down", "Locked in"; 2.8 s; the recorded 2 to 5 with a note; `hit` or `ki` (3.1, 3.5, 3.7, 3.10, 6.2, 9) |
| Found by the fixer on the way | Fixed | The burst's wait of 6 left out the reader's settle; the chase's send is at `chase.gd:284-313`; the computer's ordinary beam has no other door (3.1, 3.9, 6.2) |
