# Horde: the design for the first trial

From Orb's stand-in, 2026-11-14, for the EP, then Game Design (who owns the horde's page and rules on every number), Encounter (who builds the trial: the path's "spike S3", a throwaway build on a scratch copy), Simulation, Camera, UI, Tools, QA and Performance.

**Design only.** Nothing here is built or decided by me. Every number is a first value kept in one data file. Code references are to main at 711baa67, checked again at 201bd3d2 for this cut; `git diff 6a30b4c9 HEAD` over `sim/core`, `sim/director` and `sim/input` shows one added tool file and nothing else, so the fight code is the code of the 9 November build Orb played and the line numbers hold for both. Three readers mapped the code and the records (on Opus); I opened every file a decision rests on, and section 12 lists what I could not confirm. The tables of run lengths and blows taken come from a small paper model (`horde-model2.cjs`, in my scratch folder), not from a Godot run. I ran no Godot and no browser.

**This is the second cut.** Two reviewers attacked the first, and four of their findings were blockers. The largest changes: weak fighters now refill fast enough that two or three really are on a player; the hidden attack-again time on each weak fighter is gone, and the limit that replaces it is named as a departure; every way an exchange could still start is guarded; and the numbers were re-run on a model whose pads press at a person's speed. The last section, "Checks", lists every finding and what changed.

What Orb asked for (quoted from `docs/ep/vision.md`, with line numbers):

> "if we could have a one or two player co-op horde mode where respawning weak enemies can swarm you I'd be happy" (Orb, 2026-11-09, line 1727)

Horde's first size, three weak enemies at a time: "GO" (Orb, 2026-11-13, line 1798. The question's words are the audit's; the answer is Orb's.)

> "[x] All three, if they are in reach - [x] Your call. The lone fighter should be able to dynamically alternate attacks between opponents to keep combat free-flowing, I want to avoid the cliche of enemies standing around waiting for their turn, but I also want it to be cool rather than unfair and overwhelming for the solo fighter. though it should be a little risky for the solo fighter, there should be payoffs like being able to launch an opponent, grab the other one, fly with them at great speed, then launch them at a collision angle with the first opponent sent flying. as long as there are opportunities for the solo fighter to show off and to cause great damage in outnumbered fights it will feel more rewarding rather than punishing." (Orb, line 1844: the answer to "how many of three hit at once" on the homework page about one fighter against three full fighters, copied into vision.md by the EP's backfill of 2026-11-13. The answer's own date is not in vision.md.)

> "KEEP WORKSHOPPING, PLAYER AGENCY MUST BE RESPECTED" (Orb, 2026-11-13, line 1800)

> "scoring a knockback on the opponent, zipping around them at higher speed than they fly, then knocking them back in another direction is the feature I want explored and enhanced and continued work on" (Orb, 2026-11-14, line 1881)

**What the first version gives the lone player from that list, and what it does not.**
- **It gives:** moving freely between opponents (each press picks its own target, and a string of taps travels along them); all three allowed to swing at you if they are in reach; B sending one through a building; a well-timed guard that drops a weak fighter with its own swing.
- **It does not give yet:** launching one, grabbing another, flying with them and throwing them into the first; hitting a weak fighter that is already flying; weak fighters knocked into each other. Orb named those as what makes being outnumbered rewarding rather than punishing, so I think Orb would want them treated as the second half of the mode and not as an extra. They are the second step (section 8.2, step 12; question 5).

## 1. In plain words

- **You pick Horde, alone or with a second controller.** Weak fighters fly in and close on you. By my paper model two or three of them are on you nearly all the time, and all three a little over half the time. Knock one out and the next streaks in within a third of a second, until that wave has run out of them.
- **The buttons are the ones you know.** X, Y and B hit whoever is nearest, or whoever your left stick points at. If they are out of arm's reach, your fighter lunges to them first, and a dodge or a guard press calls your own lunge off. One light hit drops the weakest kind; the tougher kinds take about four. Keep tapping with the stick at rest and your hits carry on to the next one along. B is slow to throw, as it is now, and sends one flying through buildings.
- **They all close in, and none of them stands still.** They circle you. Each one winds up where you can see it (a step and a cocked arm) before it swings, and two swings never land on you in the same instant. Hit one first and its swing is gone. Guard or dodge the rest. **With the first numbers a swing comes at you about every second and a half, and each weak fighter swings about once in four seconds.** That is slower than I would like, and it is the part of this page I trust least. Section 3.11 says why I could not make it busier and still fair on paper. The trial is where it gets settled, and question 8 is Orb's say on it.
- **Nothing they do takes the controller from you.** A weak hit makes your fighter flinch and spoils the blow you were throwing. Your next press still works. Nothing in Horde stops the whole screen for a beat; only the one who was hit stops. A weak fighter can never block your way: you can always fly through them.
- **Each weak hit is small, and there are a lot of them.** It takes about 360 of the weakest hits to put a fresh fighter down.
- **Eight waves, each bigger and tougher, with ten seconds to breathe between them.** By the paper model a middling player finishes in about eight minutes. No person has played it yet. The number of weak fighters in each wave is the dial that sets the length.
- **You can lose.** Every hit wears your fighter down and nothing gives it back. There is no bar. In the trial nothing shows how worn your fighter is, except a warning when one more hit will put you down. Showing it on the fighter (how they stand, how they breathe, marks on the body) is work listed in section 8. When there is nothing left, the next hit that lands puts you down: your fighter drops where they are. Alone, that ends the run. With two, the one who is down gets back up when the other finishes the wave. If both are down, the run ends. By the model a middling player finishes with about three fifths of their strength left, and a slow player can go down near the end.
- **A second controller can join in the middle of a run** by pressing any button: the second fighter appears at the edge of the fight and is theirs to fly in. Your hits and blasts never hurt each other. Leaving and coming back does not heal you or get you up.
- **It ends on a result screen:** waves cleared, your time, and what the fight did to the town. Whether it also shows how many you knocked out is question 7. Then Play again or Menu.
- **Not in the first version:** grabs and throws on the weak ones, hitting one that is already flying, weak ones who shoot, the big beam through a crowd, and weak fighters knocked into each other. Those are the second step. They are most of what makes being outnumbered feel good, so the first version is the base of the mode and not the whole of it. More than three at a time means lifting a limit in the game's engine, and section 3.12 says what that would cost.

## 2. Where things stand

| Piece | State | Where |
| :--- | :--- | :--- |
| A fight of up to five bodies | **Exists** on main, reachable only from a match's setup. No menu or host asks for more than two | `sim/core/roster.gd:40` (`MAX_BODIES` 5), `:53-59`; `sim/core/sim.gd:202-222` |
| What bodies three to five do | They stand, or (with their computer on) they press and the press dies in its queue after 36 ticks: only the first two slots' requests are ever started | `sim/director/exchange.gd:30`, `:197-226`, `:231-251`; `sim/director/ai.gd:50-51` |
| Knocking out a body that is not one of the first two | **Missing.** Hit points end nothing, such a body has no brink, and the knock-out returns at once for it. The "leaves and comes back after a cooldown" is a comment, never built | `sim/core/wounds.gd:38`, `:217`; `sim/core/damage.gd:136-140` |
| Adding, removing or bringing back a body in a match | **Missing.** The list of bodies is set at the match's start. The slot number is the body's identity in the hash, the shots, the replay and the views | `sim/core/sim.gd:216-222`; `sim/core/hash.gd:50`; `sim/core/replay.gd:143-147` |
| An inert body | **Exists** for 2v2 only: `Fighter.out`. Shots already pass it in any match | `sim/core/state.gd:1137`; `sim/core/shots.gd:430`, `:709`, `:737`; `sim/core/cross.gd:443-446` |
| Sides inside one fight | **Missing.** The first slot's opponent is the second, everyone else's is the first, and a shot meets every body but its shooter | `sim/core/roster.gd:62-65`; `sim/core/shots.gd:731-737` |
| A blow that lands outside the exchange | **Exists** for 2v2 (off in data): go to the body, land through the ordinary hit with no exchange | `sim/director/outside.gd:67-83`, `:220-229`, `:307-316`; `sim/core/cross.gd:254` |
| One exchange at a time | **Exists, and is the wall.** While one runs, every other request waits | `sim/director/exchange.gd:197-199`, `:256-258` |
| One hit pause for the whole fight | **Exists.** Every hit holds everyone. A per-body version is a parked prototype, "not for landing" | `sim/core/clock.gd:8-9`; `sim/core/sim.gd:403-410`; `docs/architecture/pending/clock-by-body/README.md` |
| A second pad joining and leaving the second slot mid-match | **Exists** | `sim/input/hub.gd:8-16`; `render/core/sim_host.gd:558-564`; `sim/core/sim.gd:466-468` |
| The host's inputs | **Exist** for the first two slots only | `render/core/sim_host.gd:424-433` |
| A camera frame for more than two bodies | **Exists, off,** switched on only by tests; weights for five bodies | `render/camera/split_rig.gd:2992-2994`, `:3092`, `:3460-3467`; `render/camera/split_view.gd:177` |
| The match-over card | **Exists:** Play again, Save, Menu, Send feedback; the winner, structures and craters. It opens on a knock-out or on the "no contest" cue | `ui/widgets/ui_pause.gd:11-13`; `ui/hud/ui_hud.gd:2095-2105`; `ui/core/ui_event_hub.gd:403`, `:499` |
| A list of modes with a Horde row | **Parked** by UI, the row reads "Coming" | `docs/ui/pending/a1-start-flow/README.md`; `start-flow.patch:124` |
| The one-against-many ring (a partner and guards who interject) | **Parked,** last rebuilt 2026-10-16. Encounter's dry run today: 19 of 23 anchors apply, half a day to re-cut. One thing the dry run does not list: the ring keeps its per-fighter integers from `DirZip.END`, which the grapple now uses too | `docs/director/pending/one-v-many-s3/`; `docs/director/one-v-many-dryrun-2026-11-14.md` (not committed); `one-v-many-s3/ring.gd:8`; `sim/director/grapple.gd:36` |
| Henchmen in grades | **Paper,** ruled by Game Design on 2026-10-25 | `docs/combat/henchmen-grades.md:3`; `docs/design/rulings-2026-10-25.md` |
| A horde page, horde data, waves, respawn, a weak fighter, result lines for a run | **Missing** | `data/fighters/bench.json` is `[]`; no `horde` or `henchm` in `sim/`, `data/`, `ui/`, `render/`, `net/` |
| QA's bands and scripts for a horde | **Missing** (gap row A-QA-06) | `docs/ep/alpha/audit-2026-11-13/03-gap-register.md` |
| The cost of five bodies in today's build | **Missing.** The only readings are October's | `docs/architecture/one-v-many-core.md:113-122`; `docs/director/pending/one-v-many-s3/README.md` |

**New in the last two days that this page builds on.**
- Orb's twelve answers of 13 November (vision.md lines 1791 to 1802): no campaign at Alpha (7), three at a time (8), agency (10), and marks on fighters as stand-ins for glows, with non-intrusive UI (12).
- Orb on 14 November. Line 1881: the knock-back chain in the air "is the feature I want explored and enhanced and continued work on". Line 1887: "I'm okay with recommendation on all of them" for my gravity well questions, with "extra weight against "the fight moves" choice"; the EP's reading there is that the close fight goes to the new system, where your stick moves only you.
- Game Design's `energy-stamina-body.md` (the body is the old hidden health number, 1,600, and never refills in a match; the brink comes when the core breaks or the body runs out; a hit on a sound part takes nothing from the body), `flight-3500.md` (flat-out flight is 3,500 a second) and `workshop-six.md`.
- Game Design's three rulings pages of 14 November on my trial pages: `gravity-well-reading.md` (the snap flies at the faster of the lunge and flat out for the level; bodies are solid in the new close fight; nobody's stick moves the other player), `beam-physics.md` (a beam passes through a body that cannot act; a launched body takes one beam touch a launch; a beam has a reach) and `move-table-shares.md` (held A in reach is the snatch throw).
- Encounter's dry run of the parked ring, above.
- My own pages: the gravity well trial (the lunge it reshapes is the lunge a Horde press uses), the beam in space trial (a beam that hits only what it touches works on a crowd; the pass-through rule above is applied to the pack in section 3.4), and the energy build spec (its `S.vitalsOn` and `f.vit` follow the same pattern as the state below).

## 3. The design

Words used below: a **seat** is a player's slot (slots 0 and 1). A **place** is one of the three slots a weak fighter can stand in (slots 2, 3 and 4). The **pack** is whoever is in the places now. A **pack blow** is a blow thrown at, or by, a pack body. A body's **mark** is the one body it is fighting now. bh is a body height, 75 units (`sim/director/bands.gd:20`). A tick is a sixtieth of a second.

### 3.1 The shape: five slots, always the same five

| Slot | Who | With one player | With two |
| :--- | :--- | :--- | :--- |
| 0 | The first seat | The player | Player one |
| 1 | The second seat | **Away:** inert, not drawn, not framed, not stepped, waiting for a second pad | Player two |
| 2, 3, 4 | The three places | Weak fighters, or away between one falling and the next arriving | The same |

- **This is how "three at a time inside the five-body limit" works for one player or two** without touching `MAX_BODIES`. The audit's phrase assumed two players and three enemies in one fight; the sim could not do that, because inside one fight the first two slots are each other's opponents (`roster.gd:62-65`). Rules 3.2 and 3.3 are what make it possible.
- **The players stay in slots 0 and 1** because everything a player touches already reads those two: the pads (`sim_host.gd:424-433`), the join and leave (`hub.gd:8-16`), the two corner plates (`ui/hud/ui_hud.gd:319-341`) and the camera's pair.
- **A match never grows or shrinks.** A weak fighter that falls leaves its place **away**, and the next one is the same slot made fresh. No slot is ever taken out of the list, so the hash's slot numbers, shot owners, replay inputs and views all stay put.
- **Away** is the 2v2 flag `Fighter.out` set to true, plus this page's own phase. Shots already pass an `out` body (`shots.gd:430`, `:737`). Nothing else does today, so three guarded lines make an away body truly inert in a Horde match (sections 3.6 and 6.3).
- **Down is not away.** A player who has gone down stays in the list, drawn where they dropped, in a phase of their own (section 3.8). Only an empty seat and an empty place are away.
- **One layout for one and two players** means a second pad can join mid-run through the join that exists. I think Orb would want that: "Drop-in co-op works anywhere (character select, route maps, beat cards, or mid-brawl)" (vision.md:1512, said of the campaign).

### 3.2 The rule that makes it work: the pack is fought outside the exchange

**In a Horde match no exchange ever starts.** Every attack press, and every weak fighter's blow, is a **pack blow**: go to the body, land one blow through the ordinary hit (`SimDamage.hit` with no exchange, the call 2v2 already makes at `cross.gd:254`), and be free again.

That sentence is only true if it is enforced where an exchange is made, not only where a press is first read. The first cut guarded the press alone, and the right stick's beam and a held press went round it. Section 6.5 puts the guard at each of the three places an exchange is created, and reading 19 counts exchanges started in a Horde match with a hard line of none.

Why this and not the exchange:
- The sim runs one exchange at a time. With two players in one fight, the second player's press would wait for the first player's exchange to end, and a brawl is an exchange that lasts as long as the brawl. That would hold a player's fighter with nothing they did. It fails Orb's agency rule outright.
- It is what Game Design already ruled for the three low grades: "Scuffle", with "there is no exchange" (`henchmen-grades.md:30`, `:165`; rulings item 1).
- It leaves the two-fighter code alone. A pack body is never in the exchange, the bands, the brawl, the zip or the launch planner's pair logic, so the count of two-fighter spellings does not rise, and adding more pack bodies later is mostly a frame-cost question (section 3.12).

What the parked ring is for: the Empress's guards in versus, where slot 0 is the lone fighter and every other slot is against them. It cannot seat a second player, and its rule is that the rest wait in a ring. **The trial does not re-cut it.** Three of its rules are kept: no two blows on one fighter within 8 ticks, a guard never launches or knocks back the one it fights, and a player is never held (section 3.5).

### 3.3 Who is fighting whom: the mark

- Each body has one **mark**, a slot number, kept in the run's state. A seat's mark is a place. A place's mark is a seat. It always names a real slot, so nothing reads a missing body.
- **`SimRoster.opp` returns the mark while the switch is on** (one guarded line, section 6). So every existing read of "my rival" outside the exchange follows the mark with no rename: the dash's ease into striking distance (`bands.gd:109-131`, through `DirBrawl.rivalOf`, `brawl.gd:220-221`), a blast's aim, the weak fighter's own target. With the switch off the line returns what it returns today. The horde's own director code reads the mark through `DirBrawl.rivalOf`, the director's one place for a fighter's rival, so it adds none of the counted two-fighter spellings.
- **A seat's mark** is set by a press: the nearest pack body in the fight on the side the stick points (the stick as held, `Fighter.heldMx`, kept by `wounds.gd:277`); with the stick at rest, the nearest. Only a body inside the lunge's reach can be picked (section 3.4). A body still flying in can be picked once it is inside that reach: meeting an arrival is allowed and is its own small reward. A body already sent flying cannot be picked in the first version. With nobody to pick, the press is a swing at the air and the mark stays. Between presses the mark stays, and moves to the nearest body in the fight only when its body falls.
- **A place's mark** is set when its body arrives: the seated player with fewer pack bodies on them, then the nearer. It changes only when that player goes down, leaves, or flies further than 30 bh away. A body never changes its mark during its own wind-up.
- **Sides are by kind, not by slot parity:** seats are one side, places the other. A shot passes a body of its shooter's side (one line in `shots.gd`, section 6). Orb: "No friendly fire on partners, leaving possibility open of an illusion technique or mind-control that can be an exception" (vision.md:875).
- **A pack body is never solid to a seat.** A player can always fly through the pack, so three weak fighters can never pen a player in. Game Design's ruling 4 of 14 November makes bodies solid in the new close fight between two fighters (`gravity-well-reading.md:64`); for the pack this page proposes the opposite, on the same agency rule (departure 30).

### 3.4 A player's blows on the pack

What you press is what you press today. The blow's worth, damage and wind-up are the brawl's own, already in data, so no new number is introduced for the player's side.

| Press | Blow | Worth against toughness | Damage | Lands, in reach | What the struck body does | Lives in |
| :--- | :--- | ---: | ---: | ---: | :--- | :--- |
| X | Light | 1 | 26 | 2 ticks after the press | Fodder falls where it stands. A grunt holds 3 ticks and reels 10 | `interrupts.json` `brawl.light.damage`, `contactTicks`; `horde.json` `blow.worth.light`, `hold.light`, `play.reelTicks` |
| Y | Medium | 2.5 | 26 × 2.5 = 65 (worth times the brawl's unit, as `brawl.gd:591`) | 12 ticks | Fodder is sent 1 bh and falls. A grunt holds 5 and reels | `brawl.medium.worth`, `windupTicks`; `blow.sendBh.medium` |
| B | Heavy | 6 | 26 × 6 = 156 (as `brawl.gd:1783`) | 28 ticks | Whoever it fells is launched as a real body: through buildings, cratering, by the launch that exists (`damage.gd:156-157` shows the call). A grunt has 4, so one heavy fells it | `brawl.heavy.worth`, `windupTicks`; `blow.sendBh.heavy` |
| X held | The hold's edge makes the kept blow a heavier one, as a hold does today | | | | | `exchange.gd:231-239` (the edge is asked of the horde first, section 6.5) |
| The right stick's strike | A pack blow at the nearest body on the stick's side. The stick asks for the same two requests X and Y make (the light from lunge range, otherwise Y's), so it lands as X's or Y's blow | | | | | `stick.gd:498-504` |
| RB with X or Y | A blast, as today: the press goes to the blast's own press and starts no exchange | By the shot's power | The shot's | | A shot that meets a pack body lands as a pack blow of its weight | `exchange.gd:84`; `data/fight/shots.json`; `blow.shot` |
| RB with B | The charged shot gathers and fires as today. It is a shot, so the row above applies. That it does nothing else between two bodies is **not verified** (`driver.gd:1-7` is all I read) | | | | | `exchange.gd:55-56` |
| The signature, and the right stick's beam | **The trial refuses both,** with the refusal sound and mark that exist and the reason `horde_sig`. The Alpha build takes the beam in space (A3), which hits whatever it touches | | | | | `exchange.gd:114` (`refused`); `beam_move.gd:284-285` |
| A (the grab) | **Not in the first version: refused, with the reason `horde_grab`.** Game Design's rule for it is ready (straight to a throw, `henchmen-grades.md:162`; held A in reach is the snatch throw, `move-table-shares.md:29`). Where a grab starts in the code I did not trace: **not verified** | | | | | `sim/director/grapple.gd` |

- **In reach** (the contact distance the game uses, `DirData.contact().offset`) the blow lands after its own weight's wind-up: 2 ticks for X, 12 for Y, 28 for B. B is a commitment in a crowd: a weak hit that lands first spoils it. (In a brawl a winding heavy has armour against lights, `brawl.heavy.armour`. Whether a winding B should shrug off a fodder's blow in Horde is a number for Game Design; in the first version it does not.)
- **Out of reach, the lunge that exists:** its wind-up (6 ticks for X, 10 for Y and B, `interrupts.json` `bands.lunge.windupTicks`), then a flight to the body for 3 to 20 ticks at the faster of the lunge's 4,000 a second and flat out for the fighter's level (Game Design's ruling 1 of 14 November, `gravity-well-reading.md:61`). At base that reaches 1,333 units, 17.8 bh. Whether the weight's own wind-up then runs again on arrival is as today's lunge does it, which I did not trace.
- **Past the lunge's reach a press is a swing at the air, said.** It never becomes a long flight you did not ask for: the travel that 2v2's blow from outside uses goes at the tap chase's 20,000 a second over any distance (`outside.gd:219-226`; `interrupts.json` `chase.tap.maxSpeed`), nearly six times flat-out flight, and with it every X press would steer the fighter to the next body wherever it was. Flight and the dash close a long gap; the press closes a short one (departure 24).
- **Your own lunge can be called off.** A dodge tap or a guard press during it ends it at once, at no cost, as calling off your own approach costs nothing today (`interrupt.gd:440`).
- **The string travels** (Game Design's item 3): when a struck body falls, the next press with the stick at rest goes to the next pack body within 1.5 bh, with a 3-tick step. It follows a press and only a press. Nothing steps your fighter when you press nothing.
- **Every blow strikes one body** in the first version. Game Design's crowd caps (a medium reads 2 bodies, a sweep 3, a spin 4) and the strike on a body in the air come with the second step (departures 25 and 26).
- **A press while your blow is on its way** is kept, one deep, and thrown when the first lands. A second one replaces it.
- **The beam, when A3's beam in space is on:** Game Design's ruling 2 of 14 November applies to the pack as written. A beam passes through a body that cannot act, and a launched body takes one beam touch a launch (`beam-physics.md:108`). Whether a reeling pack body, or one that arrived less than 18 ticks ago, counts as "cannot act" is Game Design's to say with the horde's page.
- **Stamina, when the A3 loop is on:** a pack blow is a plain blow, so it refills stamina by the model's own rule (`energy-stamina-body.md` §2). Nothing extra is added here.
- **Energy for a fall** is Game Design's item 13, "recommended for Orb" and never answered: 2 for fodder, 4 for a grunt. It is in the data as written, behind its own key, off until Orb answers (section 11).

### 3.5 The pack's play: what a weak fighter's computer does

A weak fighter does not use the opponent's computer (`DirAI`). That code plays a full fighter, draws from the match's random stream, goes for slot 0 only, and has one level for the whole match. The pack has its own small play, with keyed draws only.

| Phase | What you see | How long | Ends when |
| :--- | :--- | :--- | :--- |
| **Arrive** | It streaks in from 40 bh away (3,000 units), straight at its mark, at the entrance's own speed: 11,200 a second, 3.2 times flat-out flight (`respawn.speedMul`). Every kind arrives at that speed | 16 ticks | It is within 4 bh of its mark |
| **Crowd** | It circles its mark between 2 and 4 bh, each place a third of a turn apart, never standing still, at its own flying speed: fodder 2,800 a second, a bruiser 2,450, a speedster 3,500 (`pack.<kind>.speedMul` of flat-out) | 30 ticks at least after arriving | It may wind up (below) |
| **Wind up** | The tell: a step in and a cocked arm, the same pose the lunge already has, with a sound | Fodder 14 ticks, bruiser 18, speedster 12; from behind never less than 20 | Its blow's tick comes, or any blow strikes it first |
| **Open** | It has swung: it hangs there, an opening | 24 ticks; 4 more if it was guarded | Back to the crowd, free to wind up again at once if a lane is free |
| **Reel** | It was struck and did not fall | The blow's hold (3, 5 or 7 ticks) plus 10 | Back to the crowd |
| **Sent** | Launched by a heavy that felled it: a real body in flight. It cannot be struck again in the first version | The launch | It lands: its place goes away |

**When it may wind up.** All of these, every tick:

| Rule | First value | Lives in |
| :--- | :--- | :--- |
| It has been in the fight a moment since it arrived | 30 ticks, once | `play.settleTicks` |
| Its mark is within sight of the fight | 8 bh | `play.seenBh` |
| One of that player's **lanes** is free. A player has as many lanes as bodies allowed to wind up at them together. A wind-up takes a lane, and the lane is free again a gap after that blow came due or was spoiled | 3 lanes (easy 2), which is the whole pack. The gap: 240 ticks (easy 360, hard 144) | `play.perPlayer`, `play.gapTicks` |

- **There is no attack-again time on a body.** The earlier cut of this page had one (150 ticks in wave 1 falling to 60); it is gone. A body back from its swing may wind up again at once if a lane is free.
- **The lane's gap is Game Design's own lever** ("A released turn passes after 20 ticks", `henchmen-grades.md:126`), each lane counted on its own as each turn is, so two or three bodies can wind up together. **But at 240 ticks it does the work of an attack-again time,** about four seconds a lane, and the rule over the whole ruling says the horde's limits are "never as cooldowns" (`rulings-2026-10-25.md:5`). Departure 20 names it, and section 3.11 shows why the ruled 20 could not stand on paper once the field is full.

**When its blow lands.** At the wind-up's last tick, or later if another pack blow is due on the same player: two pack blows never land on one player within 8 ticks (`play.spacingTicks`; Game Design's hard row, `henchmen-grades.md:122`). The later body holds its last pose until its tick. Then:

| The player | What happens | Lives in |
| :--- | :--- | :--- |
| Is down or away, or has moved out of reach (1.5 bh; a speedster 4 bh) | A miss. The body is open | `pack.<kind>.blow.reachBh` |
| Tapped the dodge inside the game's own dodge window (12 ticks, `SimAct.dodgeWindow`, `act.gd:21`), as a clean tap: no other dodge tap in the 30 ticks before it | A miss. The body is open | `play.dodgeAgainTicks`; `ActState.dodgeTick` |
| Raised the guard inside the game's own window for a blow of this class (8 ticks, `interrupts.json` `perfectBlock.windows.blow`) and is not inside the block's lockout (20 ticks; `interrupt.gd:16`, `:270-288`; `data/input/timing.json` `antiMashLockout`) | The strong block: fodder falls, a grunt reels 20 ticks | `play.perfectReelTicks`; `ActState.guardSince`; the director's own lockout |
| Is holding the guard | The ordinary hit's guard rule: damage × 0.38 (`damage.gd:5`), so 1.5 from a fodder and 3 from a bruiser. The body rebounds and is open 4 ticks longer | `pack.<kind>.guarded.reboundTicks` |
| Otherwise | It lands, through the ordinary hit and its stance rule (`damage.gd:5`, `:76-84`). The data's 4 (fodder, speedster) or 8 (bruiser) becomes 4.5 or 9.0 on a fighter at rest (× 1.12), 5 or 10 on one sprinting away (× 1.25), 5.4 or 10.8 on one charging (× 1.35). The player flinches: the blow they were throwing is spoiled. Their stick and their next press are untouched | `pack.<kind>.blow.damage` |

- **The flinch is not a stun.** It sets nothing that gates input (`wounds.gd:272-290` is not used). This is Game Design's rule made exact: the flinch cancels the player's blow in flight and never holds their next press (`henchmen-grades.md:52`).
- **The guard and the dodge cannot be tapped through.** The dodge's tick is stamped on every tap, with no gap between taps outside an exchange (`act.gd:66-67`), so a dodge tapped without stopping would beat every blow. Hence the clean-tap rule above, which is new (departure 29); its 30 ticks are the length of the free gap between dodges the game already has (`interrupts.json` `dodgeCancel.freeGapTicks`). The strong block needs no new rule: the director already locks out a guard pressed twice inside 20 ticks, in or out of an exchange (`interrupt.gd:353-362` runs it for every player each live tick), and the horde reads that lockout.
- **Breaking away has a price.** A fighter sprinting away takes a quarter more from each blow that catches them. That is the game's rule, not a new one.
- **What you see between swings.** There is no queue and no ring: every body in the fight circles its mark, and any of them may wind up when a lane is free. By the model, at a lone medium pad, 43 wind-ups start a minute (one every 1.4 seconds), and about 3 of those start while another is already in flight. While three bodies are on the player, all three are only circling 45% of the time. So "all three may swing together" is true of the rule and uncommon on the screen at the first values. That is the cost of the long gap, and it is the place this page sits furthest from Orb's "standing around waiting for their turn" (section 3.11, question 8).
- **The level** is the match's one level (`ai.gd:392`), read for `gapTicks` and `perPlayer` only. Tells never shorten with the level (Game Design's rule). The per-body level the audit asks for (A-AI-09) is not needed for the first version.
- **Nothing a pack body does moves a player** except its blow landing. A pack body never grabs, launches or knocks a player back in the first version.

### 3.6 Falling and coming back

- **A pack body falls when its toughness is spent:** fodder 1, bruiser 4, speedster 4, counted in the worth of the blows that land (`pack.<kind>.worth`; Game Design's "1 light" and "4 lights").
- **The fall is seen and never faded.** A light drops it where it stands. A medium sends it 1 bh. A heavy launches it for real.
- **Its place goes away the moment it is down** (after the launch, when it lands). The body that lies there afterwards is a picture only: Animation's render-side stand-in (`render/anim/anim_many.gd`, "never in `S.fighters`"), which Rendering takes away once it is out of view. The sim cannot read the camera, so the sim does not wait for "out of view"; the picture does. This keeps "Downed bodies are never faded or dissolved" (`henchmen-grades.md:177`) without holding a slot.
- **An away body is truly inert.** Today the `out` flag is read only by shots, by the 2v2 code, by the knock-out line and by the one-on-one ending; every body is still stepped each tick (`sim.gd:430-431`), fills its power and can step up a tier (`fighter.gd:650-678`), and the ordinary hit has no check for it (`damage.gd:46`). So in a Horde match an away body is not stepped, cannot be hit, and is parked straight up, 400 bh above where it went away (`respawn.parkBh`), clear of beams and thrown bodies. Three guarded lines (section 6.3) and a hard reading (20). Whether anything reads a body at that height is **not verified.**
- **The place refills 2 ticks later** (`respawn.ticks`), while the wave has bodies left to send. The slot is **made fresh in place:** every field of the body is set to what a new match would give it, then its kind, toughness and mark are set, and it starts 40 bh from its mark, on the side a keyed draw picks. It is in the fight 16 ticks after that: 18 ticks, a third of a second, from a fall to its replacement.
- **Why that fast.** Three slots hold the whole pack, so a place that is empty is a body missing from the fight. In the model's wave 1 a medium pad fells a fodder about every 27 ticks (56 in 25 seconds), so a place that stays empty longer than that is empty most of the time. With the earlier cut's 57 ticks from a fall to its replacement, the model gives 1.56 in the fight for a medium pad and 1.00 for a fast one (section 3.11, row E). With 18 ticks it gives 2.50.
- **How it gets there that fast is the trial's look question,** and there are three ways. (a) From 40 bh at an entrance speed of 11,200 a second: the first value, because it needs nothing new in the sim. It is 3.2 times the flat-out flight Orb chose, for a quarter of a second, by a fighter that then flies slower than the player (departure 23). (b) From about 12 bh at flat-out flight: the same 16 ticks, but 12 bh is certainly inside the view, so the body would appear from nowhere. (c) From behind the fight, in depth. I did not check what the sim's depth can carry. Whether 3,000 units is outside the camera's widest view is **not verified**; reading 13 decides.
- **Respawn fits the five-body limit** by construction: three places, re-used. Encounter's dry run reached the same answer (`one-v-many-dryrun-2026-11-14.md:40`). A run sends 621 bodies through three slots.

### 3.7 Waves and the run

- **A run is eight waves.** A wave has a count of bodies by kind. A fallen body's place is refilled until the count is spent. The wave is cleared when the last one falls.
- **Between waves, ten seconds** in which nothing arrives (`rest.ticks` 600). Nothing is paused and nobody is held: you can fly, charge, or stand.
- **Later waves are bigger and tougher.** The refill and the rhythm are the same in every wave. The tougher kinds live long enough to swing more than once, and that is what makes a later wave harder.

| Wave | Fodder | Bruisers | Speedsters | Bodies | Model: seconds for the medium pad, one seed |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 56 | 0 | 0 | 56 | 25 |
| 2 | 56 | 6 | 0 | 62 | 31 |
| 3 | 56 | 8 | 3 | 67 | 38 |
| 4 | 56 | 11 | 6 | 73 | 45 |
| 5 | 58 | 14 | 8 | 80 | 53 |
| 6 | 58 | 17 | 11 | 86 | 61 |
| 7 | 62 | 20 | 14 | 96 | 70 |
| 8 | 62 | 22 | 17 | 101 | 75 |
| **All** | 464 | 98 | 59 | **621** | 398, plus 70 of rest: **7:48** (over 40 seeds, 7:52) |

- **Which kind comes next** is a keyed draw over what the wave has left (`SimRng.keyed`, key `horde.kind`, counted by bodies sent, so no two draws share a key).
- **With two players:** counts × 1.5 (Game Design's own rule, `campaign.md:133`), about 930 bodies. Still three at a time. Nothing else changes: the refill is already as short as it can be.
- **The run's clock** is counted for the result screen. It is not drawn during the fight (Orb's answer 12: "UI/UX ELEMENTS MUST BE NON-INTRUSIVE", vision.md:1802). UI may show "Wave 3 of 8" by the corner plate for two seconds as a wave starts, behind the look gate.
- **A backstop:** a run that reaches 12:00 ends there, as a result of its own (`cap.seconds` 720).
- **The one-on-one rules that must not run here:** the idle and last-event rules (`ending.gd:100-117` would open one player's brink to the other player) and the 11:00 time cap (`exchange.gd:721-723`). Each gets one guard (section 6.5).

### 3.8 Going down, the end and the result screen

- **The clock a player runs down is the body:** the hidden health number, 1,600, which every hit already lowers and nothing refills (`damage.gd:25-26`). At rest it takes 357 fodder blows or 179 bruiser blows to spend it (4.48 and 8.96 a blow); a held guard lets a little through each time.
- **That is today's code, not the rule Alpha will run.** In the loop the path recommends for Alpha, which Orb's "Go with recommendation on all" took (vision.md:1804; the list at line 1811 is the EP's reading), a hit takes damage × severity × a share from the body, and the share for a sound part is nothing (0.05 for a sound core) (`energy-stamina-body.md` §2, §3 rule 4). A weak blow leaves parts sound (section 12), so under that rule a Horde run could not be lost. This page proposes that in a Horde match a pack blow that lands takes its damage from the body in full, whatever the struck part's stage (`down.bodyShare` 1.0; departure 22). Every figure in section 3.11 assumes that key.
- **A fighter is on their last legs** when the body is spent, or the core is broken (the brink that exists, `wounds.gd:213-216`). This is Game Design's rule: "The brink comes when the core breaks or when the body runs out" (`energy-stamina-body.md` §4). It is said with a cue of its own, so sound, pad and the fighter's look can show it.
- **How worn a fighter is has to be readable before that.** Today the only read of that number in the picture or the UI is the old bar (`render/core/hud.gd:219`), and a weak blow leaves no wound to show. The trial shows nothing but the last-legs cue. The build adds a read in stages, on the fighter and never as a bar: at a half and at a quarter of the body left, the stance, the breath, marks on the torso and a pad pulse (Game Design's planned signs for the body are the way a fighter gets up, the voice and damage on the torso; the first never happens in a Horde match). Owners in section 8.2, step 6; reading 23.
- **On their last legs, the next pack blow that lands puts them down.** A guarded blow does not. There is no finisher and nothing pauses.
- **Down:** the fighter drops where they are and stays there, drawn. The blow does not launch them: nothing a pack body does throws a player. A downed fighter reads no input, cannot be hit, and is nobody's mark. They are not away: down is a phase of its own (section 6.1). How a fighter with no input gets from the air to the ground outside an exchange is **not verified** (the state `down` is set by the landing code, `fighter.gd:84`); if nothing can be called for it, the first version leaves them slumped where they were struck and the look gate decides.
  - **Alone:** the run ends.
  - **With two:** they get up when the wave is cleared, with 400 of the body back (`down.backBody`), and a broken core eased to just under broken. If both are down at once, the run ends.
- **The run ends** on the last wave cleared, on every player down, or at the 12:00 backstop. One cue carries which (`horde_over`, as the "no contest" cue is carried today, `ending.gd:173`), and `SimCore.ended` reads the run's state.
- **The result screen is the match-over card that exists,** with its lines changed for this mode:

| Line | Example | From |
| :--- | :--- | :--- |
| The result | "All eight waves cleared", "Down in wave 6", "Time" | The end cue |
| Time | "7:42" | The run's ticks |
| Knocked out (question 7; departure 28) | "621" | The run's count |
| Hits taken | "101" (each player's own, with two) | The run's count |
| The town | Structures and craters, as today | `ui_hud.gd:2095-2105` |
| Buttons | Play again, Save this match, Menu, Send feedback | `ui_pause.gd:11-13` |

  Nothing on it counts bystanders. The knock-out count is of fighters and never of deaths. The card's own rule is Legal's row on death counts (`ui_hud.gd:2095`; `docs/legal/outside-tester-gates.md:19`), so whether a knock-out tally and its wording sit inside it is Legal's to say, not mine.

### 3.9 A second player: joining and leaving

- **Joining** is the join that exists: a pad that drives nothing takes slot 1 when its computer flag is on (`hub.gd:12-13`), and the host flips the flag (`sim_host.gd:559-561`). In a Horde match the horde reads that flip. **The first time a seat is taken in a run** it is made fresh 40 bh from the first player, and it is the joining player's from that tick. Nothing flies it in for them; the camera's pair frame, which already holds two fighters however far apart, brings them into view. How that first appearance looks is behind the look gate. The wave's remaining count moves to the two-player value from that tick.
- **Leaving** is the pause menu's entry that exists (`ui_pause.gd:10`, `p2_leave`) or the pad unplugged. The seat goes away; the pack re-marks the one who stays.
- **Coming back** gives the seat as it was left: the same body, the same core, and down if it was down. A downed seat stays down until the wave is cleared, whoever holds the pad. So leaving and rejoining never heals and never lifts a downed fighter (reading 15).
- **The join and the leave are in a replay already** as toggles (`replay.gd:16`), so a run with a late second player replays.
- **A computer partner** in the second seat (Orb: "solo or co-op, CPU partner optional", vision.md:870) is not in this design. It is the same seat with a computer that fights the pack, and the pack blow gives it a simple thing to press. It waits on the partner work the audit lists (A-AI-08).

### 3.10 What a weak fighter is, in the first version

- **Two grades, three kinds:** fodder, and the grunt as a bruiser or a speedster. That is "the lowest two grades" the audit's smallest version names (`MODES.md:47`). The marksman waits on the shot's side rule being proven; the veteran and the elite wait until after Alpha, as the path says.
- **In the sim it is a full fighter** in a re-used slot, with a small horde state beside it. No lighter body exists, and three at a time does not need one.
- **In data it is a fighter on the bench** (`data/fighters/bench.json`, which exists for exactly this: loads, can be named in a setup, is not on the select screen). The trial uses the training fighter (`REFERENCE`) for all three places.
- **How it looks** is Art's: the A4 brief asks for "one cheap weak-enemy body as data, or a written statement that Alpha's enemies reuse an existing body with a palette" (`05-directives/A4/art.md:46`). It has no name, no emblem and no story (`henchmen-grades.md:23`).
- **In the fight it flies slower than you:** fodder at 0.8 of flat-out, a bruiser 0.7, a speedster 1.0 (`pack.<kind>.speedMul`). You can always outrun the pack, which is what makes breaking away a real choice. Only its entrance is faster (`respawn.speedMul`, section 3.6).
- **Its power stays at nothing.** A full fighter's power fills with time and with hits, and a higher tier multiplies its blows (`fighter.gd:661`; `damage.gd:49`, `:91-92`). A pack body is made fresh often, but a bruiser in a slow run could climb. The horde holds a place's power at zero (reading 20).

### 3.11 What the paper model says

The model is `horde-model2.cjs` with `horde-first2.json` (the data block of section 5, parsed), 40 seeds a row, output in `model-out2.txt`; the comparison rows are `arms2.cjs` and `arms-out2.txt`, 20 seeds a row. All are in my scratch folder. It is three places, the wave table above and a scripted pad. **It is not the game.** It has no positions, so no blow ever misses because a player moved, nobody spends time flying between bodies, and reach is never tested. Its pad presses X only. How much a pad defends is a dial I set, not a skill anyone measured. It brackets the first values; it does not prove them. The earlier cut's model (`horde-model.cjs`, `model-out.txt`) is kept beside it; its pads pressed 5 to 7.5 times a second and never missed, and its field was mostly empty, which the review found.

**The pads, by what they do.**

| Pad | Presses a second; goes wide | Defends | Alone: run | Body lost | Went down | Bodies in the fight: mean; none; all three | With two: run | Body lost (player one) | Went down |
| :--- | :--- | :--- | :--- | ---: | :--- | :--- | :--- | ---: | :--- |
| Does nothing | 0 | Nothing | Wave 1 never ends; down at 8:25 | all | 40 of 40 | 3.00; 0%; 100% | Both down by 8:25 | all | 40 of 40 |
| Only taps guard, every 12 ticks | 0 | Every press after the first is locked out, so no strong block; an ordinary guard a third of the time | Fells nobody; down at 10:46 | all | 40 of 40 | 3.00; 0%; 100% | Down by 10:54 | all | 40 of 40 |
| Only taps dodge, every 12 ticks | 0 | Never a clean tap, so nothing | Fells nobody; down at 8:25, as the idle pad | all | 40 of 40 | 3.00; 0%; 100% | As the idle pad | all | 40 of 40 |
| Mashes X | 6; 1 in 10 | Nothing | 6:16 | 53% | 0 | 2.36; 1%; 45% | 5:28 | 19% | 0 |
| Slow | 3; 1 in 5 | A quarter of the blows that come due, by holding the guard | 8:53 | 70% | 0 | 2.56; 1%; 59% | 7:33 | 53% | 0 |
| **Medium** | 4; 1 in 10 | Half: of those, 6 in 10 a held guard, 2 a strong block, 2 a dodge. Goes for a wind-up it has seen for 12 ticks | **7:52** | **39%** | 0 of 40 | **2.50; 1%; 54%** | 6:43 | 20% | 0 |
| Good | 5; 1 in 20 | 8 in 10 | 6:36 | 17% | 0 | 2.40; 1%; 47% | 5:50 | 6% | 0 |
| The earlier cut's "medium" | 7.5; never | Half | 5:20 | 21% | 0 | 2.23; 1%; 37% | 5:06 | 6% | 0 |

**The medium pad at other pressing speeds** (everything else the same).

| Presses a second | Alone: run | Body lost | Went down | With two: run | Body lost |
| ---: | :--- | ---: | :--- | :--- | ---: |
| 2 | 11:21 | 71% | 0 | 9:15 | 51% |
| 3 | 8:04 | 49% | 0 | 6:29 | 29% |
| 4 | 7:52 | 39% | 0 | 6:43 | 20% |
| 5 | 6:50 | 34% | 0 | 5:56 | 13% |
| 6 | 6:08 | 31% | 0 | 5:27 | 11% |
| 7.5 | 5:35 | 23% | 0 | 5:15 | 8% |

**The medium pad, wave by wave** (alone, then with two): bodies in the fight, mean, 2.26 2.37 2.43 2.48 2.51 2.54 2.56 2.58, with two or three in the fight 95% to 98% of each wave and nobody in it 1% or less. With two players: 1.81 1.97 2.06 2.13 2.17 2.23 2.25 2.27, with two or three in the fight 68% of wave 1 rising to 88% of wave 8.

**Who goes down.** At medium level, of the pads that attack, none of the rows above. A slow pad at 2 presses a second goes down in 17 of 40 runs, near 11:11; at 1.5 a second in 40 of 40, near 10:19 in wave 6 or 7. On hard (the gap 144) the slow pad at 3 a second goes down in 40 of 40, in wave 8 near 7:27, and the medium pad loses 64%. On easy (2 lanes, the gap 360) the medium pad loses 17%.

**Other first values, for Game Design** (the medium pad alone unless said).

| Row | The values | What the model says |
| :--- | :--- | :--- |
| A | **The ruled values as they stand,** with the field full: 2 turns a player, the gap 20, blows of 1.5% and 3% (24 and 48) | The medium pad is down in 20 of 20, near 0:59, in wave 2. The good pad is down in 20 of 20 near 2:00. A pad at 7.5 presses a second that never misses is down in 20 of 20 near 1:50. 170 wind-ups start a minute |
| B | This page's 3 lanes and its blows (4 and 8), with the ruled gap of 20 | 211 wind-ups a minute. The medium pad is down in 20 of 20 near 4:15. The good pad loses 97% and goes down in 9 of 20 |
| C | The ruled blows (24 and 48) with this page's gap of 240, nothing given back | The medium pad is down in 20 of 20 near 3:40. The good pad goes down in 7 of 20 |
| D | **The ruled blows, the gap 240, and the whole body given back in each breather** | The medium pad is never down and loses 2.4 bodies over the run, about 30% of one in a wave. The slow pad goes down in 3 of 20. A run can then be lost only inside one wave |
| E | This page's values with the earlier cut's arrival (a refill of 6 ticks, 51 ticks to arrive) | Bodies in the fight: 1.56 for the medium pad (nobody 10% of the time), 1.00 for the pad at 7.5 a second (nobody 26%). With two medium pads 1.03 (nobody 25%) |
| F | This page's values with 2 lanes at medium, the ruled count | The medium pad loses 26% alone and 13% with two. 29 wind-ups a minute |
| G | Twice as busy and half as heavy: the gap 113, blows of 2 and 4 | The medium pad loses 40% alone and 18% with two. 85 wind-ups a minute |

What I take from it:
- **A full field and the ruled numbers cannot both hold, by this model.** With two or more weak fighters on a player nearly all the time and nothing limiting how often each swings, the pack starts about three wind-ups a second, and no pad survives blows of 1.5% (row A). Lengthening the gap alone, or shrinking the blow alone, is not enough (rows B and C). The first values move both: the gap from 20 ticks to 240, and the blow from 1.5% of the body to 0.25%.
- **Why the ruled numbers do not carry over.** They were set for a horde stage in a campaign, with a band of 10 to 30% of health over a stage. A run is 621 bodies with nothing given back: about eight stages in a row on one body. Row D is the other honest answer: keep the ruled blow and give the body back in each breather, so each wave is its own stage. It departs from "Never, in a match" instead of from the blow's size. Game Design chooses. The data carries both (`pack.<kind>.blow.damage`, `rest.backBody`), and the trial should run both.
- **At the first values the medium pad sits in Game Design's band alone:** 39% of the body lost, against 20 to 45% (rulings item 2, as departure 19 reads it for a run). It stays inside from 4 to 7.5 presses a second (39% down to 23%). At 3 a second it is just outside (49%), and at 2 well outside (71%), though neither goes down.
- **The field is full for one player and thinner for two.** Alone, two or three are in the fight 95% or more of every wave. With two players the mean is under 2 in the first two waves, because two pads fell them twice as fast. Three at a time is thin for two; question 4.
- **The rhythm is the weak point.** 43 wind-ups a minute at a lone player, 3 of them overlapping. Row G shows the same fairness at twice the pace with blows half the size, and row F shows what the ruled 2 lanes would give. Which of these feels like a horde is not something a model can say.
- **A first run is rarely lost at medium level.** Of the pads that attack, only the slow pad at 2 presses a second or fewer goes down. If Game Design wants more risk, the gap is the lever (hard, at 144, puts the slow pad down in wave 8).
- **A fighter who does nothing lasts 8:25,** because each blow is small. The earlier cut's 1:11 came mostly from blows six times the size. If standing still should end sooner, that is a rule of its own, and I have not proposed one.
- **Tapping through does not work,** by the rules of section 3.5: a pad that only taps guard or only taps dodge fells nobody and goes down as the idle pad does.
- **Wave 1's twelve-fodder check fails on the fast side:** the medium pad fells 56 fodder in 25 seconds, which is 12 in 5.4 seconds against Combat's band of 10 to 20 (`henchmen-grades.md:183`). The model has no flying between bodies, so a real pad should be slower; whether it is, and by how much, is reading 11's to find.
- **Two players.** The earlier cut swung from 12% to 70% of the body on one step of one dial. This cut does not (20% at the first values, 13% with two lanes, 18% in row G), but it is still a model with no positions, and with two pads the question of whether each has enough to fight is about where bodies are. Question 4 stays for after the clip.
- **Run length:** 7:52 alone and 6:43 with two for the medium pad, inside the exit criterion's 5 to 10 minutes (X-10) and at the path's "last eight minutes" alone. The count per wave is the dial.

### 3.12 Lifting the five-body limit: what it would cost

Not proposed for the trial or for Alpha. The path asks for an estimate.

**What the limit is.** `MAX_BODIES` is a check in two places (`roster.gd:54`; `sim.gd:203-207`). The cost of raising it is everything sized or packed for five. The counts of places that assume two fighters are the project's own counter's (`node tools/ratchet-two-fighter.mjs --list`: 365 in all), broken down by folder with a small script of mine (`byfolder.cjs`, scratch).

| Where | What assumes five, or two | To lift it |
| :--- | :--- | :--- |
| `sim/core/roster.gd:40` | The constant | One line, and the tests that try six slots as "too many" |
| `render/camera/split_rig.gd:3461`, `:3463`, `:3092` | Weight arrays five wide; `mini(..., 5)` | Size by the body count. Camera's |
| `ui/widgets/ui_many.gd:11` | Four edge markers | Raise, or keep four and mark the nearest. UI's |
| `sim/core/pause.gd:177`; `sim/core/wounds.gd:397`, `:407` | Four bits a slot in one integer. Stage 1's page says "room for eight" (`one-v-many-core.md:55-56`). In the 53 whole bits of a hashed float there is room for 13 by my arithmetic; which holds is **not verified** | Check the type end to end before eight; widen before thirteen |
| `sim/director/brawl.gd:2332` and a dozen of the same shape in that file | Keyed draws built as `tick * 2 + slot`: slot 2 this tick is slot 0 next tick | Harmless while a brawl is two bodies. A pack body never brawls, so the horde does not meet it |
| `sim/core/intro.gd:506-510` | The entrance is the pair's | Pack bodies take no entrance. No change |
| `render/core/sim_host.gd:424-433`; `sim/input/hub.gd` | Two human slots | No change: more pack bodies are not more players |
| The one exchange: 153 reads across shipped code (director 116, of them 16 in `exchange.gd`; core 9; picture and UI 28) | One exchange | **No change, because of rule 3.2.** In a Horde match there is none, so each read sees "no exchange", as between exchanges today. This is the part that would be large for any design that puts weak fighters in the exchange |
| A fighter's rival, `SimRoster.opp`: 72 calls in shipped code (director 49, core 16, world 6, animation 1) | A pair | **No change in the count:** each follows the mark (section 3.3). Which of them run in a Horde match, and whether the mark is right for each, is found by the trial (section 12) |
| The first two slots named by number: 140 places (camera 37, audio 18, the host and old HUD 13, VFX 12, animation 6, net 3; director 28, core 23) | Slots 0 and 1 are the fight's two fighters | **More bodies do not add to these, but the Horde itself meets them, at five bodies, and none was walked.** In a Horde match they read two partners as the pair, and with one player they read an away second seat. The camera's 37 come first: an away seat must count for nothing in the frame. Owners in section 7; the picture and sound sizes in section 10 are guesses until this walk is done |
| `sim/core/replay.gd:9`, `:44-47` | "Up to five slots" in a comment; the header names every body | The comment |

**What each body costs.** Arithmetic on recorded figures (`cost.cjs` in my scratch folder); none of it is a new measurement, and every recorded figure is from October or from a loaded machine.

| Bodies | A snapshot (memory, for rollback only) | Sim tick, mean, Orb's PC | The picture, extra a frame | On a machine three times slower: tick; picture |
| ---: | ---: | ---: | ---: | ---: |
| 2 (today) | 155 to 165 KB | 0.57 ms | 0 | 1.7 ms; 0 |
| **5 (this design)** | 182 to 198 KB | 0.75 to 1.02 ms | +0.6 to +0.8 ms | 2.3 to 3.1 ms; +1.8 to +2.3 ms |
| 6 | 191 to 209 KB | 0.81 to 1.17 ms | +0.8 to +1.0 ms | 2.4 to 3.5 ms; +2.4 to +3.0 ms |
| 8 | 209 to 231 KB | 0.93 to 1.47 ms | +1.2 to +1.5 ms | 2.8 to 4.4 ms; +3.6 to +4.5 ms |
| 12 | 245 to 275 KB | 1.17 to 2.07 ms | +2.0 to +2.5 ms | 3.5 to 6.2 ms; +6.0 to +7.5 ms |

- Sources: a snapshot is 155 to 165 KB with two bodies (`docs/net/rollback.md:63`) and a body is about 9 to 11 KB (the map's count of the state, an estimate). The two-body tick is 0.57 ms (`docs/perf/two-fights-kit-2026-11-07.md:17`, marked indicative). A fighting extra body cost 60 to 70 µs with the ring in October (`one-v-many-s3/README.md`), against the director's paper worst case of 150 µs (`docs/director/one-v-many.md:82`). The picture costs about 0.2 to 0.25 ms a body (`docs/perf/audit-2026-10-16.md:245`).
- **The hash** grows in step with the bodies: one block a body (`hash.gd:150-225`), computed at checkpoints, not every tick.
- **The frame is 16.7 ms at 60.** On Orb's PC eight bodies look affordable by this arithmetic. On a Steam Deck nobody has measured anything, and the path already calls that the top risk (`04-path-to-alpha.md:338`).

**My estimate.** With rule 3.2 in place:
- **Six to eight pack bodies** is a constant, the camera's arrays, the markers, the bit-packing check, new readings on the PC and the Deck, and a re-tune of every number in section 3.7. About one director's build window each for Simulation, Camera and Performance, and QA's re-read: **about 3M to 5M tokens, my guess.**
- **Twelve** needs the cheaper body Game Design's page calls "the light body" (`henchmen-grades.md:29`) so that a weak fighter is not a full fighter's step and a full fighter's picture, plus a look that reads at that size. **About 8M to 12M more, my guess,** and it should follow a Deck reading, not precede it.
- **Without rule 3.2** (weak fighters in the exchange), any number past five means reworking the director's pair logic. Encounter's guess says the same (`one-v-many-dryrun-2026-11-14.md:50`).

## 4. Departures

Each row is a proposal for Game Design to rule on. "Kept" rows are listed where a reader might expect a change. Rows 1 to 19 are the first cut's, corrected; rows 20 to 31 were added after the review.

| # | The record says | This page says | Why |
| ---: | :--- | :--- | :--- |
| 1 | A weak fighter must hold one of a player's turns to wind up; 2 turns a player at medium and hard, 1 at easy; "No ring body strikes without a turn" (`henchmen-grades.md:116-127`; rulings item 6) | No turns and no ring. Each player has lanes instead: 3 at medium and hard, which is the whole pack, and 2 at easy. Every body in the fight may wind up when a lane is free. **Kept:** 8 ticks between landings, tells that never shorten, 20 ticks from behind. The gap is row 20 | Orb, vision.md:1844: "All three, if they are in reach". Row F of section 3.11 shows the ruled count of 2 |
| 2 | "All three striking freely measured unplayable", so one partner in the exchange and single blows on openings (the EP's call at vision.md:1389; `one-v-many.md:7`: "no more than two bodies touch the one at a time") | All three may wind up at a player | That was measured with three full fighters in full exchanges. A pack blow is one weak blow with a tell. Reading 9 has to show it holds |
| 3 | The low grades are "the light body" (`henchmen-grades.md:29`) | A full fighter in a re-used slot | No light body exists. Three at a time does not need one. It is needed past eight (section 3.12) |
| 4 | Slot 0 is the lone fighter and the opponent of every other body (`roster.gd:36-39`, `:62-65`; `one-v-many-core.md`) | In a Horde match a body's opponent is its mark, and both players are on one side | Without it a second player is the first player's opponent. Only while the switch is on |
| 5 | "Only a finisher ends a match" (`energy-stamina-body.md` §4; `wounds.gd:37-38`) | In Horde, a fighter on their last legs is put down by any pack blow that lands, with no finisher | A finisher and its struggle pause the whole sim. Game Design gave the same reason for the elite (`henchmen-grades.md:43`) |
| 6 | The body refills "Never, in a match" (`energy-stamina-body.md` §1) | A partner who gets back up has 400 of it | Coming back with none would put them down again on the first hit |
| 7 | "A partner knocked out in a stage is out until the next stage" (`campaign.md:132`) | Out until the wave is cleared | In a stand-alone run the wave is the stage. Out for the run would leave one player watching for minutes |
| 8 | Hordes scale "in count, not in grade: x1.5 for two players" (`campaign.md:133`) | **Kept:** × 1.5 and nothing else | The earlier cut also shortened refills and attack times for two; with the refill at 2 ticks and no attack-again time there is nothing left to shorten |
| 9 | In a stage with a second player or a horde, every hit pause is a one-body hold, E102's mechanism, "recommended until Orb says otherwise" (rulings items 11 and 12) | The same outcome by a simpler road: no whole-fight pause is written in a Horde match, and a struck pack body's hold is its own reel timer | No per-body clock has to be built for the first version (the parked prototype is "about 2 sessions" more). It still waits on Orb (question 3) |
| 10 | A weak fighter never winds up "from outside the player's pane" (`henchmen-grades.md:124`) | A sim distance stands in: within 8 bh of its mark. Camera's frame is asked to hold a winding body | Rendering never writes the sim, so the sim cannot know a pane. Reading 13 checks the picture |
| 11 | "A body is removed only out of view" (`henchmen-grades.md:180`) | The sim's place is freed at once. The fallen body stays as a picture, and the picture is removed out of view | The same thing on screen, with no slot held and no sim read of the camera |
| 12 | The domino is capped at 3 and 5 (rulings item 5; `henchmen-grades.md:153`). The path puts the domino after Alpha (`04-path-to-alpha.md:338`) | No cap when it is built: until the speed runs out. Proposed as the first addition after the first version | Orb, vision.md:1752: "go with your recommendation" (the EP's note there says the recommendation was until the speed runs out), and line 1767: "sounds cool, having slight advantages through tactical sells like this makes it engaging to be outnumbered". The henchmen page is not yet updated |
| 13 | A wave of 12 fodder falls in 10 to 20 s (`henchmen-grades.md:183`) | Kept as a reading, taken through three places: 12 falls in a row. The model says 5.4 s, so I expect it to fail on the fast side (section 3.11) | Twelve cannot stand on the field at once. If the trial agrees with the model, the band or the fodder's toughness needs a ruling |
| 14 | The marksman is one of the three grunt types (`henchmen-grades.md:65-72`) | Waits for the second step | A weak fighter's shot needs the side rule proven first |
| 15 | The mode's card reads "You and a friend against waves of weaker fighters." (UI's park, `start-flow.patch:124`) | "Alone or with a friend, against waves of weaker fighters." | One or two players (vision.md:1727) |
| 16 | The trial re-cuts the parked ring (the path's S3 asks whether it still applies) | It still applies, with half a day and one clash to fix (section 2). The horde does not use it, so the trial spends nothing on it | The ring is for one fighter against many; it cannot seat a second player and its others wait |
| 17 | Research: build two players against one strong opponent first, and do not start with grunts (`docs/research/co-op-brawler.md:9`, `:82`) | The horde first | Orb's Alpha answer (vision.md:1727) came after the study |
| 18 | Each grade has its own reactions: a struck grunt skips or tucks, a third light staggers it, a bruiser guards its front and its blow skips a player 1 bh, a speedster sidesteps the first light (`henchmen-grades.md:65-81`) | First version: a struck body that does not fall holds and reels; a pack blow on a player is a flinch and nothing else | The smallest thing that plays. The finer reactions are built pieces that have only ever been called from a brawl; they come with the second step |
| 19 | The horde's damage band is by campaign column: 10 to 30% of health over a stage in columns 1 and 2, 20 to 45% by column 4 (rulings item 2) | A stand-alone run of eight waves uses 20 to 45% for the whole run (reading 9) | There are no columns without a campaign, and a run is longer than one stage. Row D of section 3.11 is the other reading: the band a wave |
| 20 | The gap after a released turn is 20 ticks, easy 30, hard 12 (`henchmen-grades.md:126`; rulings item 6). Over the whole ruling: the horde's limits "exist for reading and frame rate, never as cooldowns" (`rulings-2026-10-25.md:5`) | A lane's gap of 240 ticks, easy 360, hard 144. It is a limit for fairness, and it works as an attack-again time of about four seconds a lane. (The first cut had a plain attack-again time on each body, 150 ticks falling to 60, and did not list it. That is gone; this stands in its place and is named) | With the field full, the ruled gap puts the medium pad down in under a minute at the ruled blows and near 4:15 at this page's (section 3.11, rows A and B). The gap is the first lever the ruling itself names. Row G is a shorter gap with smaller blows |
| 21 | A fodder's blow is 1.5% of the player's health, a bruiser's 3%, a speedster's 1.5% (`henchmen-grades.md:52`, `:69`): 24, 48 and 24 | 4, 8 and 4: 0.25% and 0.5%, before the ordinary hit's stance rule | The ruled blows were set for a stage. A run is 621 bodies and nothing is given back (section 3.11, rows A and C). The blow's damage is the second lever the ruling names. The other answer is row D: the ruled blows, with the body back in each breather (`rest.backBody`) |
| 22 | A hit takes damage × severity × a share from the body, and a hit on a sound part takes nothing, 0.05 on a sound core (`energy-stamina-body.md` §2, §3 rule 4). That loop is the path's recommendation for Alpha, which Orb's "Go with recommendation on all" took (vision.md:1804; the list at line 1811 is the EP's reading) | In a Horde match a pack blow that lands takes its damage from the body in full (`down.bodyShare` 1.0) | A weak blow leaves parts sound, so under the shared rule a Horde run could not be lost. The trial reads the clock the Alpha will run only with this key. Simulation's work when A3's loop lands |
| 23 | Flat-out flight is 3,500 a second in every mode (`flight-3500.md`, on Orb's decision) | A weak fighter's entrance is 11,200 a second for 16 ticks (`respawn.speedMul` 3.2). In the fight it flies at 0.7 to 1.0 of flat-out | A place has to refill within about a third of a second or the field empties (section 3.6). Orb's decision is about how fast a fighter flies. I think Orb would want to see an entrance that fast before it stands, so it is in the clip, and the other two ways in are in section 3.6 |
| 24 | Pillar 3: attacks always close the gap. 2v2's blow from outside travels any distance at the tap chase's speed (`outside.gd:219-226`) | A press reaches as far as the lunge does, 17.8 bh at base, at the faster of the lunge's speed and flat out for the level. Past that it is a swing at the air, said | At 20,000 a second over any distance, every X press would steer the fighter to the next body: mashing X would fly the fighter for the player. Game Design's beam ruling of 14 November already reads pillar 3 as "the snap, the long strike, LT flat out" closing the gap |
| 25 | The crowd caps: a medium reads 2 bodies, a sweep 3, a spin 4 (rulings item 4, accepted) | Every blow strikes one body in the first version | The smallest thing that plays. It comes with the second step |
| 26 | "The player may zip to the airborne body and strike it once" (`henchmen-grades.md:165`); the co-op relay has no cap (rulings item 8) | A body sent flying cannot be struck again in the first version | It needs a second send and a rule against counting one fall twice. It belongs with the second step, and Orb's line 1881 (the knock-back chain "explored and enhanced") says that step matters |
| 27 | QA's bands include "at least four kinds of body meeting happen in a minute of a mixed wave" and that no player is struck by more than the turns allow (rulings item 15) | The first has nothing to count in the first version: bodies do not meet. The second is read as lanes (readings 5 and 6) | Bodies meeting is the second step |
| 28 | A downed weak fighter "pays a little ki and counts toward nothing else", "No score" (rulings item 13, recommended for Orb, not answered) | The result screen shows how many were knocked out | A run needs something to beat. It is the other half of the question Orb has not been asked, so it is question 7, and the line has a data key so that "no" costs nothing |
| 29 | "Every henchman's blow can be guarded and perfect-blocked like any blow" (`henchmen-grades.md:47`) | The guard and the strong block are the game's own, window and lockout unchanged. **New:** a dodge beats a pack blow only as a clean tap, with no other dodge tap in the 30 ticks before it | Outside an exchange nothing spaces dodge taps (`act.gd:66-67`), so a dodge tapped without stopping would beat every blow |
| 30 | Bodies are solid in the new close fight: "walking into the rival stops you" (`gravity-well-reading.md:64`, ruling 4) | A pack body is never solid to a seat | Three solid bodies could pen a player in, which the same agency rule forbids. The ruling was made for two fighters |
| 31 | A grab on a weak fighter goes straight to a throw (`henchmen-grades.md:162`), and nothing in the record refuses a beam in a horde | The trial refuses the signature, the right stick's beam and the grab, each with a said reason | Each starts an exchange or a hold between two bodies, which rule 3.2 forbids. The beam returns with A3's beam in space, the grab with the second step |

## 5. Data

**One new file, `data/fight/horde.json`,** beside the other switch-gated systems (`data/fight/kick.json` is the pattern). Its schema is a new `tools/schemas/fight-horde.schema.json` with its entry in `tools/schemas/map.json`, in the same commit. This block is the file the model reads (`horde-first2.json` is this block, parsed). The model uses the pack's worth, wind-up and damage, the lanes, the gap, the spacing, the settle, open and reel numbers, the again-time of the dodge, the refill and arrival, the waves, the rest and what it gives back, the two-player count and the backstop; the other keys are for the build. The body, 1,600, is the fighter's own `maxhp` and is not a horde key. The strong block's window (8) and lockout (20), the dodge window (12) and the lunge are the game's own and are read from where they live.

```json
{
  "schema": "fight.horde/1",
  "enabled": false,
  "_enabled": "the one switch. SimCore.newMatch copies it into S.hordeOn unless the match's setup has its own \"horde\". Off: no horde state exists or is hashed, no event is sent, and this file is not in a replay's data hash",
  "seats": 2,
  "places": 3,
  "pack": {
    "fodder":    {"fighter": "REFERENCE", "worth": 1, "speedMul": 0.8,
                  "blow": {"reachBh": 1.5, "windup": 14, "damage": 4, "flinchTicks": 6}, "guarded": {"reboundTicks": 4}},
    "bruiser":   {"fighter": "REFERENCE", "worth": 4, "speedMul": 0.7,
                  "blow": {"reachBh": 1.5, "windup": 18, "damage": 8, "flinchTicks": 10}, "guarded": {"reboundTicks": 4}},
    "speedster": {"fighter": "REFERENCE", "worth": 4, "speedMul": 1.0,
                  "blow": {"reachBh": 4.0, "windup": 12, "damage": 4, "flinchTicks": 8}, "guarded": {"reboundTicks": 4}}
  },
  "_pack": "fighter: a bench or roster id (the trial: the training fighter for all). worth: toughness, in the worth of the blows that land. speedMul: of flat-out flight, in the fight. damage: before the ordinary hit's stance rule; Game Design's blows of 2026-10-25 are 24, 48 and 24 (departure 21). flinchTicks: how long the flinch's picture plays; it gates nothing. Wind-ups and reach are Game Design's",
  "play": {
    "perPlayer": {"easy": 2, "medium": 3, "hard": 3},
    "gapTicks": {"easy": 360, "medium": 240, "hard": 144},
    "_gapTicks": "perPlayer: lanes a player. A wind-up takes a lane; the lane is free again gapTicks after that blow came due or was spoiled. The ruled gap is 30, 20 and 12 (departure 20)",
    "spacingTicks": 8,
    "settleTicks": 30,
    "openTicks": 24,
    "reelTicks": 10,
    "behindWindupMin": 20,
    "seenBh": 8.0,
    "leashBh": 30.0,
    "crowdBh": [2.0, 4.0],
    "dodgeAgainTicks": 30,
    "perfectReelTicks": 20
  },
  "blow": {
    "worth": {"light": 1, "medium": 2.5, "heavy": 6},
    "_worth": "the brawl's own (interrupts.json brawl.medium.worth, brawl.heavy.worth); damage is brawl.light.damage x worth; the wind-ups are the brawl's and the lunge's",
    "hopBh": 1.5, "hopTicks": 3, "whiffTicks": 20,
    "sendBh": {"medium": 1, "heavy": 3},
    "shot": {"light": 1, "heavy": 2.5}
  },
  "hold": {"light": 3, "medium": 5, "heavy": 7, "wholeFight": false},
  "_hold": "the struck pack body alone holds this many ticks. wholeFight true: every hit holds everyone, as one-on-one (for the trial's side-by-side, question 3)",
  "respawn": {"ticks": 2, "spawnBh": 40, "speedMul": 3.2, "staggerTicks": 20, "parkBh": 400},
  "_respawn": "ticks: from a fall to its replacement starting in. speedMul: the entrance's speed, of flat-out flight, for every kind (departure 23). staggerTicks: between the three places at a wave's start. parkBh: how far straight up an away body is kept",
  "waves": [
    {"fodder": 56, "bruiser": 0,  "speedster": 0},
    {"fodder": 56, "bruiser": 6,  "speedster": 0},
    {"fodder": 56, "bruiser": 8,  "speedster": 3},
    {"fodder": 56, "bruiser": 11, "speedster": 6},
    {"fodder": 58, "bruiser": 14, "speedster": 8},
    {"fodder": 58, "bruiser": 17, "speedster": 11},
    {"fodder": 62, "bruiser": 20, "speedster": 14},
    {"fodder": 62, "bruiser": 22, "speedster": 17}
  ],
  "rest": {"ticks": 600, "backBody": 0},
  "_rest": "backBody: body given back in each breather to a player who is still up. 0: nothing refills, the record. 1600 with the ruled blows is the trial's other arm (section 3.11, row D)",
  "down": {"onLastBlow": true, "backAtWaveEnd": true, "backBody": 400, "bodyShare": 1.0},
  "_down": "backBody: what a partner gets up with. bodyShare: when A3's body rule is on, the share of a pack blow's damage that reaches the body whatever the struck part's stage (departure 22)",
  "two": {"countMul": 1.5, "respawnMul": 1.0},
  "energyOnFall": {"enabled": false, "fodder": 2, "grunt": 4, "_": "Game Design's item 13, recommended for Orb, not answered"},
  "result": {"felled": true, "_": "the knocked-out line on the result screen (question 7)"},
  "cap": {"seconds": 720}
}
```

**Other data.**
- `data/fighters/bench.json` and one folder a weak fighter (`data/fighters/<id>/fighter.json`, schema `tools/schemas/fighter.schema.json`, unchanged): after the trial, when Art has a body. The trial adds none.
- `ui/data/modes.json` (UI's park): the Horde row becomes `"state": "ready"` with its players. `ui/data/terms.json`: the result lines and "Wave {n} of {m}". Both with UI's schemas, in UI's commit.
- `tools/preview/switches.mjs`: a `horde` row, so the switch list of a build names it.
- **No change** to `data/fight/wounds.json`, `data/director/interrupts.json`, `data/input/timing.json` or `data/director/ai.json`. The pack reads the brawl's numbers, the lunge, the block's window and its lockout, and writes none.
- Controls' refusal table (`docs/controls/refusals.md`): two new reasons, `horde_sig` and `horde_grab`.

## 6. Pseudocode and hooks

GDScript-shaped. Every line number is one I opened. No file in the sim's core names a director class. The count of two-fighter spellings (`tools/ratchet-two-fighter.mjs`) is at 365 against a baseline of 365, with no slack, and it counts comments. The first cut spelled one of the four counted names three times in the director's new file; this cut reads the mark through `DirBrawl.rivalOf` instead, and by my reading none of the code below adds a counted spelling. The count has not been run on it, because nothing is built (reading 16).

### 6.1 State (Simulation; `sim/core/state.gd`)

```gdscript
# beside kickOn (state.gd:91)
var hordeOn: bool = false             # the horde (sim/core/horde.gd): data/fight/horde.json's switch, or the setup's "horde"
var horde = null                      # HordeRun while S.hordeOn, null otherwise

## The run, while S.hordeOn.
class HordeRun:
	var wave: int = 0                 # the wave now, from 1; 0 before the first
	var up: int = 0                   # bodies of this wave not yet down (sent or still to come)
	var mix: PackedInt32Array         # bodies of this wave still to send: fodder, bruiser, speedster
	var rest: int = 0                 # ticks left of the breather; 0 while a wave is on
	var t: int = 0                    # live ticks of the run
	var over: int = 0                 # 0 running, 1 every wave cleared, 2 every player down, 3 the backstop
	var sent: int = 0                 # bodies sent in so far: the keyed draws' counter
	var felled: int = 0               # for the result
	var mark: PackedInt32Array        # for each slot, the slot it is fighting now
	var lane: PackedInt32Array        # for each seat, `places` lanes: the tick the lane is free from; -1 while a wind-up holds it

## A body's part in the run, while S.hordeOn; null otherwise, as f.kik is.
class HordeBody:
	var kind: int = 0                 # 0 a seat, 1 fodder, 2 bruiser, 3 speedster
	var phase: int = 0                # 0 away, 1 arriving, 2 in the fight, 3 winding up, 4 open, 5 reeling, 6 sent, 7 down (a seat only)
	var t: int = 0                    # the tick this phase ends, or the tick a place refills; 0 none
	var worth: float = 0.0            # toughness left
	var at: int = 0                   # the tick this body's own pack blow lands; 0 none
	var w: int = 0                    # that blow's weight: 1 light, 2 medium, 3 heavy
	var buf: int = 0                  # a seat: one kept press's weight; 0 none
	var ready: int = 0                # a place: the tick from which it may wind up (its arrival plus the settle, then the end of each open or reel)
	var ln: int = -1                  # a place: the lane it holds at its mark while it winds up; -1 none
	var due: int = -100000            # a seat: the latest tick a pack blow is due to land on them
	var dg: int = -100000             # a seat: the last dodge tap seen
	var dgOk: int = 0                 # a seat: 1 when that tap was clean (no other tap inside the again-time before it)
	var was: int = 0                  # a seat: 1 once a pad has taken it in this run (a seat is made fresh only the first time)
	var taken: int = 0                # a seat: pack blows that landed, for the result
	var downs: int = 0                # a seat: times down

# on Fighter, beside kik (state.gd:1112)
	var hd = null                     # the horde: HordeBody while S.hordeOn (sim/core/horde.gd), null otherwise
```

**Where it is hashed, and why the hash is unchanged with the switch off.** `S.hordeOn` is false, `S.horde` and every `f.hd` are null, and each line below is behind `if S.hordeOn`, as the kick's are. No existing value moves and nothing is appended.

```gdscript
# sim/core/hash.gd, in the per-fighter walk, beside the kick's lines (:201-203)
		if S.hordeOn:   # the horde: only when on, so a match without it hashes as before
			_obj(out, f.hd, SimHorde.HASHED_BODY)
			out.append(f.out)             # (hashed today only through SimCross.collect, in a two-fight match)
# ... and once after the walk, before the world's line (:226)
	if S.hordeOn:
		_obj(out, S.horde, SimHorde.HASHED_RUN)
		for v in S.horde.mix: out.append(float(v))
		for v in S.horde.mark: out.append(float(v))
		for v in S.horde.lane: out.append(float(v))

# net/desync.gd, beside the kick's (:105-107): everything SimHash reads above, so a mark or a lane that differs is named and not only seen in the hash
	if S.hordeOn:
		for f in S.fighters:
			_fields(v, md, f.hd, SimHorde.HASHED_BODY)
			v.append(1.0 if f.out else 0.0)
		_fields(v, md, S.horde, SimHorde.HASHED_RUN)
		for x in S.horde.mix: v.append(float(x))
		for x in S.horde.mark: v.append(float(x))
		for x in S.horde.lane: v.append(float(x))

# sim/core/replay.gd, in dataHash(setup), beside the kick's (:195-196)
	if setup.get("horde", SimHorde.enabled()) == true:
		h.text(SimHorde.dataHash())
```

A snapshot copies the state by reflection, so the new classes need nothing there: the code reviewer confirmed that `net/snapshot.gd:163-173` builds its copier from `SimState`'s own script constants. I did not open it myself. How the desync tool labels a value appended outside `_fields` (its `md` argument) I did not open either.

### 6.2 The core's side (Simulation; new `sim/core/horde.gd`, class `SimHorde`)

It loads the file as `SimKick._ensure` does (`kick.gd:39-71`), with `enabled()`, `dataHash()` and `errors()` in the same shape, and names no director class.

```gdscript
const HASHED_BODY: Array = ["kind", "phase", "t", "worth", "at", "w", "buf", "ready", "ln", "due", "dg", "dgOk", "was", "taken", "downs"]
const HASHED_RUN: Array = ["wave", "up", "rest", "t", "over", "sent", "felled"]

## A horde match's five slots from the setup's one or two fighters: the seats, then the places (SimCore._mFighters, sim.gd:202).
static func slots(setup: Dictionary) -> Array:
	var s: Array = setup.get("slots", FighterData.order().slice(0, 2)).slice(0, 2)
	for k in range(places):
		s.append(packFighter[0])          # the fodder's fighter id: a place's first body
	return s

## Each body's part for a new match (SimCore._mSetupsA, beside SimKick.setup at sim.gd:266-267).
static func setup(S: SimState, setup_: Dictionary) -> void:
	S.horde = SimState.HordeRun.new() if S.hordeOn else null
	for k in range(S.fighters.size()):
		var f = S.fighters[k]
		f.hd = SimState.HordeBody.new() if S.hordeOn else null
		if f.hd == null:
			continue
		f.hd.kind = 0 if k < seats else 1
		if k >= seats or f.ai != null:    # every place, and a seat with nobody on it, starts away, parked
			f.out = true
			park(f)                       # straight up by respawn.parkBh, clear of the fight (the core keeps the height in units: it may not name the director's body-height constant)
		else:
			f.hd.phase = 2
			f.hd.was = 1
	if S.hordeOn:
		S.horde.mix = PackedInt32Array([0, 0, 0])
		S.horde.lane.resize(seats * places)   # every lane free from tick 0
		S.horde.mark.resize(S.fighters.size())
		for k in range(S.fighters.size()):
			S.horde.mark[k] = seats if k < seats else 0   # a seat marks the first place; a place marks the first seat
		S.horde.rest = staggerTicks       # the first wave starts after a beat

## Slot k made fresh, in place: every field as a new match would give it, the same object, the same keys.
static func fresh(S: SimState, k: int, id: String, x: float, y: float) -> void:
	var f = S.fighters[k]
	var hd = f.hd
	var n = SimRoster.createFighter(FighterData.def(id), x, f.keys, f.ai != null)   # roster.gd:7
	for p in n.get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			f.set(p.name, n.get(p.name))  # (as SimStage._copy walks a record, stage.gd:106-120)
	f.y = y
	f.hd = hd
	_bodySetups(S, f)                     # act, brake, power, kick, forms, flight, style: each set-up's one-body form (below)

## The side a body is on: 0 a seat, 1 a place.
static func side(S: SimState, k: int) -> int:
	return 0 if S.fighters[k].hd.kind == 0 else 1
```

- **`_bodySetups` is the real work in this file.** A new match gives every body its action state, brake, power, kick, form, flight and style in loops over all the bodies (`sim.gd:257-305`; for instance `SimKick.setup` at `kick.gd:95-98` walks everyone). Each needs a form that sets up one body without touching the others. That is seven small refactors, all hash-neutral for a match that never calls them.
- **One check guards it:** a body made fresh at tick T must equal, field for field, a body of the same fighter in a new match (reading 3). A set-up added later that forgets its one-body form fails that check, not a play test.

### 6.3 The core's guarded lines (Simulation)

```gdscript
# sim/core/sim.gd, _mFighters, the slots' line (:202)
	var horde: bool = setup.get("horde", SimHorde.enabled()) == true
	var slots: Array = SimHorde.slots(setup) if horde else setup.get("slots", ...)   # the rest of the line as it is
# ... and the bodies past the pair (:219-222): in a horde match their computer flag is on
	S.fighters.append(SimRoster.createFighter(FighterData.def(slots[k]), gx, key, horde or ai.get(key, fights == 2) == true))

# sim/core/sim.gd, _mSetupsA, beside the kick's two lines (:266-267)
	S.hordeOn = setup.get("horde", SimHorde.enabled()) == true
	SimHorde.setup(S, setup)

# sim/core/sim.gd, ended (:460-463), first line
	if S.hordeOn:
		return S.horde.over != 0

# sim/core/roster.gd, opp (:64-65), first line
	if S.hordeOn:
		return S.fighters[S.horde.mark[S.fighters.find(f)]]

# sim/core/clock.gd, hold (:8-9), first line
	if S.hordeOn and not SimHorde.wholeFight:
		return                            # in a horde match nothing holds the whole fight; a struck pack body's hold is its own timer

# sim/core/shots.gd, the body loop (:731-737), after the shooter's own line (:732-733)
				if S.hordeOn and sh.owner >= 0 and not sh.wild and SimHorde.side(S, k) == SimHorde.side(S, sh.owner):
					continue              # a shot passes a body of its shooter's side

# sim/input/control.gd (Controls' file), after the intent is cleared (:8)
	if S.hordeOn and (f.out or f.hd.phase == 7):
		return                            # away or down: no input is read

# sim/core/sim.gd, the fighters' step (:430-431)
	for f in S.fighters:
		if S.hordeOn and f.out:
			continue                      # away: not stepped, so no power fills, no tier rises and no pause is raised by an empty slot
		SimFighter.stepFighter(S, f, dt)

# sim/core/damage.gd, hit (:46), first line
	if S.hordeOn and (D.out or D.hd.phase == 7):
		return 0.0                        # away or down: nothing lands on them, whatever threw it
```

- **The last three are what make "away" and "down" inert.** Without them an empty seat or place still steps every tick, fills its power and can step up a tier (`fighter.gd:650-678`), and can be hit by anything that goes through the ordinary hit, which has no check for `out` (`damage.gd:46-130`). A downed player is still stepped, so that they can come to rest; they read no input and take no hit.
- **A beam's own sampling and a thrown body's contact are not guarded separately.** An away body is parked 400 bh up, out of their way, and the guard in the ordinary hit is the backstop. Reading 20 is the check.
- `wounds.gd` is not changed, and `damage.gd` gains that one line. A pack body is never knocked out by the knock-out code: its fall is the horde's own.
- When A3's body rule is on, the share of a pack blow that reaches the body (`down.bodyShare`) is read where that rule computes a hit's share; that file does not exist yet.

### 6.4 The director's side (Encounter; new `sim/director/horde.gd`, class `DirHorde`)

No draw from the match's stream. Keyed draws only, each with a key no other draw shares: the count of bodies sent, or the run's tick and the place. A fighter's mark is read through `DirBrawl.rivalOf` (`brawl.gd:220-221`), never by the counted spelling.

```gdscript
static func on(S: SimState) -> bool:
	return S.hordeOn

## DirExchange._request, after the Driver's line (exchange.gd:55-56) and before the blow from outside (:57):
##	if DirHorde.takes(S, A, kind):
##		return
static func takes(S: SimState, A, kind: String) -> bool:
	if not S.hordeOn:
		return false
	var h = A.hd
	if h.kind != 0:
		return true                       # a pack body never asks for an exchange
	var big: bool = DirBrawl.isB(A, kind) # B with no stance held arrives as "sig" and is the heavy (exchange.gd:59, :75-78; brawl.gd:3177-3180)
	if kind != "sig" and A.act.mode == 1:
		if not DirBlast.press(S, A, DirExchange.KIND.find(kind)):   # RB with X or Y: the blast's own press, the call exchange.gd:84 makes; it starts no exchange
			DirExchange.refused(S, A, DirExchange.cantWhy(S, A))
		return true
	if kind == "sig" and not big:
		DirExchange.refused(S, A, "horde_sig")   # exchange.gd:114: said, never silent (the trial; A3's beam replaces this)
		return true
	if A.state != "free":
		DirExchange.refused(S, A, DirExchange.cantWhy(S, A))   # exchange.gd:100
		return true
	var w: int = 3 if big else (2 if kind == "heavy" else 1)   # X is "light"; Y, the request kind "heavy", is the brawl's medium; B is the heavy
	if h.at != 0:
		h.buf = w                         # a blow is on its way: this press is kept, one deep
		return true
	_throw(S, A, w)
	return true

static func _throw(S: SimState, A, w: int) -> void:
	var k: int = _pick(S, A)
	if k < 0:                             # nobody inside the lunge's reach: a swing at the air, said
		SimFx.cue(S, A, "horde_blow", "air", "")   # fx.gd:664
		return
	S.horde.mark[S.fighters.find(A)] = k
	var M = S.fighters[k]
	var d: float = DirBands.dist(A, M)    # bands.gd:49
	var lead: int = LEAD[w]               # in reach, the weight's own wind-up: 2, 12, 28 (brawl.light.contactTicks, medium.windupTicks, heavy.windupTicks)
	if d > float(DirData.contact().offset) * 1.5:
		lead = LUNGE_WIND[w] + _lunge(S, A, M, d)   # the lunge's wind-up (6, 10, 10), then a rush at the body built as DirOutside._toward builds one (outside.gd:220-229)
		                                  # but at the faster of bands.lunge.speed and flat out for the fighter's level, never the tap chase's; returns its ticks, 3 to 20
	A.hd.at = S.tick + lead
	A.hd.w = w
	SimFx.cue(S, A, "horde_blow", "start", String(M.keys))

## The nearest body of the pack inside the lunge's reach, on the stick's side when the stick is held (SimWrap.sdx(a, b) is b minus a).
static func _pick(S: SimState, A) -> int:
	var best: int = -1
	var bd: float = INF
	var r: float = lungeReach(S, A)       # the lunge's most ticks at its speed for this fighter: 1,333 units at base
	for k in range(S.fighters.size()):
		var M = S.fighters[k]
		if M.hd.kind == 0 or M.out or M.hd.phase == 6:
			continue                      # a seat, an away place, or a body already sent flying
		var d: float = DirBands.dist(A, M)
		if d > r:
			continue                      # (an arriving body is picked once it is inside the reach)
		if absf(A.heldMx) > 0.5 and SimWrap.sdx(A.x, M.x) * A.heldMx < 0.0:
			d += farSide                  # behind the stick: only when nobody is on the stick's side
		if d < bd:
			bd = d
			best = k
	return best

## Once a live tick, from DirExchange.dirUpdate, beside DirOutside.tick (exchange.gd:716).
static func tick(S: SimState, dt: float) -> void:
	if dt <= 0.0 or not S.hordeOn or S.horde.over != 0:
		return
	_run(S)                               # the run's clock, the wave, the refills, the end
	_marks(S)                             # every mark names a body in the fight, or the first slot of the other side
	for k in range(S.fighters.size()):
		var f = S.fighters[k]
		var h = f.hd
		if f.out or h.phase == 7:
			continue
		if h.kind == 0:
			if f.act.dodgeTick != h.dg:   # a new dodge tap: clean when no other tap came in the again-time before it
				h.dgOk = 1 if f.act.dodgeTick - h.dg > dodgeAgainTicks else 0
				h.dg = f.act.dodgeTick
			if h.at != 0 and f.rush != null and (f.input.dodge or f.input.guardPress):
				h.at = 0                  # the player's own lunge, called off by a dodge or a guard press: at once, at no cost
				h.buf = 0
				f.rush = null
				SimFx.cue(S, f, "horde_blow", "off", "")
				continue
		else:
			f.power = 0.0                 # a pack body's power stays at nothing: no tier, no form, no stronger blow
		if h.at != 0 and S.tick >= h.at:
			if h.kind == 0:
				_land(S, f)               # a player's pack blow
			else:
				_strike(S, f)             # a pack body's
		elif h.kind != 0 and h.phase == 6 and f.state != "launched":
			_away(S, k)                   # a sent body has landed: its place goes away
		elif h.kind != 0 and (h.phase == 4 or h.phase == 5) and S.tick >= h.t:
			h.phase = 2                   # open or reeling, over: back to the crowd, free to wind up when a lane is
			h.ready = S.tick

## A player's pack blow lands.
static func _land(S: SimState, A) -> void:
	var h = A.hd
	var M = DirBrawl.rivalOf(S, A)        # the mark
	var w: int = h.w
	h.at = 0
	A.rush = null
	if M.out or M.hd.phase == 6 or DirBands.dist(A, M) > reach:
		SimFx.cue(S, A, "horde_blow", "whiff", "")
	else:
		A.face = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(A.x, M.x)), A.face)   # as outside.gd:312
		SimDamage.hit(S, null, A, M, lightDamage * WORTH[w], {"kind": WEIGHT[w], "weight": WEIGHT[w], "region": "core"})   # damage.gd:46; WEIGHT is light, medium, heavy; a named region draws nothing
		_spoil(S, M)                      # any blow spoils its wind-up, and frees its lane after the gap
		M.hd.worth -= WORTH[w]
		if M.hd.worth <= 0.0:
			_fell(S, A, M, w)
		else:
			M.hd.phase = 5
			M.hd.t = S.tick + HOLD[w] + reelTicks
			M.vx = 0.0
			M.vy = 0.0
	if h.buf != 0:                        # the kept press: the string's next
		var nw: int = h.buf
		h.buf = 0
		_throw(S, A, nw)

## A lane at seat P that is free now, or -1 (S.horde.lane holds, for each seat, `places` ticks: the tick a lane is free from, -1 while a wind-up holds it).
static func _lane(S: SimState, P) -> int:
	var b: int = S.fighters.find(P) * SimHorde.places
	for i in range(perPlayer()):
		if S.horde.lane[b + i] >= 0 and S.horde.lane[b + i] <= S.tick:
			return i
	return -1

## A winding body's blow is over (it came due, or was spoiled): its lane is free again after the gap.
static func _spoil(S: SimState, f) -> void:
	if f.hd.ln >= 0:
		S.horde.lane[S.horde.mark[S.fighters.find(f)] * SimHorde.places + f.hd.ln] = S.tick + gapTicks()
		f.hd.ln = -1
	f.hd.at = 0

## A pack body's blow comes due.
static func _strike(S: SimState, f) -> void:
	var P = DirBrawl.rivalOf(S, f)        # its mark: a seat
	_spoil(S, f)
	f.hd.phase = 4
	f.hd.t = S.tick + openTicks
	var c: Dictionary = packCfg(f.hd.kind)
	var dodged: bool = S.tick - P.act.dodgeTick < SimAct.dodgeWindow and P.hd.dgOk == 1   # act.gd:21; a clean tap only
	if P.out or P.hd.phase != 2 or DirBands.dist(f, P) > float(c.blow.reachBh) * DirBands.BH or dodged:
		SimFx.cue(S, f, "horde_pack", "miss", String(P.keys))
		return
	var guard: bool = P.act.guardSince >= 0           # state.gd:321
	if guard and S.tick - P.act.guardSince <= blockTicks() and S.tick >= DirInterrupt.gi(P, DirInterrupt.PB_LOCK):   # the game's window for a blow (interrupts.json perfectBlock.windows.blow) and its lockout (interrupt.gd:16)
		SimFx.cue(S, P, "horde_pack", "blocked", String(f.keys))
		_blocked(S, P, f)                 # fodder falls; a grunt reels perfectReelTicks
		return
	var last: bool = P.hp <= 0.0 or P.brink           # on their last legs before this blow
	var key: int = S.horde.t * SimHorde.places + (S.fighters.find(f) - SimHorde.seats)   # one blow a place a tick at most, so no two draws share a key
	var region: String = SimWounds.REGIONS[int(SimRng.keyed(int(S.game.seed), "horde.region", key) * 4.0) % 4]   # rng.gd:55; a named region draws nothing from the stream
	SimDamage.hit(S, null, f, P, float(c.blow.damage), {"kind": "light", "weight": "light", "region": region})   # the ordinary hit, stance rule and all
	if guard:
		f.hd.t += int(c.guarded.reboundTicks)
		return
	P.hd.taken += 1
	P.hd.at = 0                           # the flinch: the blow the player was throwing is spoiled. No stun, no gate
	P.hd.buf = 0
	P.rush = null
	SimFx.cue(S, P, "horde_pack", "hit", String(f.keys))
	if last:
		_down(S, P)

## DirAI.aiInput's first question (ai.gd:58, before DirOutside's at :59):
##	if DirHorde.aiInput(S, f, i):
##		return
static func aiInput(S: SimState, f, i) -> bool:
	if not S.hordeOn:
		return false
	var h = f.hd
	if f.out or h.kind == 0 or h.phase >= 4 or S.horde.over != 0:
		return true                       # away, an empty seat, open, reeling or sent, or the run is over: nothing is pressed (the intent is already clear, control.gd:8)
	var P = DirBrawl.rivalOf(S, f)
	var dx: float = SimWrap.sdx(f.x, P.x)
	var d: float = DirBands.dist(f, P)
	if h.phase == 1 or h.phase == 3:      # arriving, or winding up: straight at the mark
		i.mx = SimMathx.jsign(dx)
		i.my = clampf((P.y - f.y) / 400.0, -1.0, 1.0)   # as outside.gd:190 steers
		i.dash = h.phase == 1
		if h.phase == 1 and d <= crowdOuter:
			h.phase = 2
			h.ready = S.tick + settleTicks
		return true
	# in the fight: circle the mark, a third of a turn apart by place, as the opponent's computer circles (ai.gd:203-208)
	var ph: float = S.T * circleRate + 6.283185307179586 * float(S.fighters.find(f)) / float(places)
	var cx: float = SimWrap.sdx(f.x, P.x + crowdR * SimDetMath.sin(ph))
	var cy: float = P.y + crowdY * SimDetMath.cos(ph) - f.y
	i.mx = SimMathx.jsign(cx) if absf(cx) > 20.0 else 0.0
	i.my = SimMathx.jsign(cy) if absf(cy) > 20.0 else 0.0
	var ln: int = _lane(S, P) if _mayWind(S, f, P, d) else -1
	if ln >= 0:
		h.phase = 3
		h.ln = ln
		S.horde.lane[S.fighters.find(P) * SimHorde.places + ln] = -1   # the lane is taken until this blow is over
		var behind: bool = dx * P.face > 0.0          # the mark faces away from this body
		var wu: int = maxi(int(packCfg(h.kind).blow.windup), behindWindupMin if behind else 0)
		h.at = maxi(S.tick + wu, P.hd.due + spacingTicks)   # never within the spacing of another pack blow on this player
		P.hd.due = h.at
		SimFx.cue(S, f, "horde_wind", String(P.keys), "behind" if behind else "")
	return true

static func _mayWind(S: SimState, f, P, d: float) -> bool:
	return not P.out and P.hd.phase == 2 and S.tick >= f.hd.ready and d <= seenBh * DirBands.BH
```

The run (`_run`), in words, because it is bookkeeping:
- Count the tick; at the backstop, end as "time".
- In a breather, count it down. At zero start the next wave: set `mix` from the wave's row (× the two-player count when both seats are in), `up` to its sum, and send `horde_wave`. With `rest.backBody` above 0, each seat that is up gets that much of the body back when the breather starts, never past its full body.
- In a wave, a place that is away and whose refill tick has come, with `mix` not empty, is refilled: pick the kind by `SimRng.keyed(seed, "horde.kind", sent)` over what `mix` has left, the side by `SimRng.keyed(seed, "horde.side", sent)`, its mark as in 3.3; call `SimHorde.fresh`; set `f.out` false, its kind, worth, speed and phase 1; count `sent`.
- `_fell`: count `felled` and `up`, once a body; by the blow's weight drop it (`_away`), or send it (phase 6) with the launch the knock-out's fallback uses (`SimDir.doLaunch(S, A, M, {"ux": A.face * 0.9, "uy": 0.5}, SimPower.sendForce(S, A, 1800.0, <key>))`, as `damage.gd:156-157`). A sent body is skipped by `_pick` and by `_land`, so its fall is never counted twice.
- `_away`: `_spoil`, then `f.out = true`, phase 0, `t` the refill tick, the body parked `respawn.parkBh` straight up, and the cue `horde_fall` with where and how it fell, for the picture that stays.
- When `up` reaches zero: the last wave ends the run as "cleared"; any other starts the breather and gets a downed partner up (phase 2, `down.backBody` of the body, the core eased).
- `_down`: the seat's phase is 7, down. It is counted, its own blow and kept press are dropped, every wind-up at it is spoiled, and the cue `horde_down` is sent. The fighter is not launched and not `out`. If no seat with a person on it is still up, end as "down".
- The end: `S.horde.over` is set and `SimFx.cue(S, null, "horde_over", <which>, "")` is sent, the way `ending.gd:173` sends "no_contest".
- A seat whose computer flag has just gone off (a pad joined): if `was` is 0, `SimHorde.fresh` at 40 bh from the other seat, `out` false, phase 2, `was` 1. If `was` is 1, the seat as it was left: `out` false, and the phase it had (in the fight, or down). It is the player's from that tick: nothing flies it in for them. A seat whose flag has just come on: `out` true, its phase and body kept.
- The last-legs cue, `horde_last`, is sent on the tick a seat's body is first spent or its core first breaks. The two earlier stages of the body's read (a half and a quarter left) are sent as `horde_worn` with the stage.
- A shot that lands on a pack body counts as a pack blow of `blow.shot` worth, read from the tick's damage events of kind `blast` (as `SimMood.tick` reads a tick's events, `sim.gd:436`). Which director function lands a shot's hit I did not trace.

### 6.5 The director's guarded lines (Encounter)

**The guard that makes "no exchange ever starts" true sits where every exchange is made.** An exchange is created in exactly three places (`S.dirS.ex = ex` at `exchange.gd:182`, `:366` and `:904`), and `DirHorde.takes` alone does not cover them: the right stick's beam calls `startBeam` and so `_start` directly (`beam_move.gd:284-285`; `exchange.gd:431-432`), and a hold's edge pushes a request and drains the queue (`exchange.gd:238-239`, `:251`).

```gdscript
# sim/director/exchange.gd, _start (:256-258), first line
	if DirHorde.on(S):
		return DROPPED                    # in a horde match nothing starts an exchange: the request is spent

# sim/director/exchange.gd, startZip (:170) and _shotFinisher (:888), first line of each
	if DirHorde.on(S):
		return                            # (startZip returns null: it is reached only through DirZip.takes, after DirHorde.takes; belt and braces)

# sim/director/exchange.gd, _queues, the hold's edge (:233-234): the horde is asked first, as the brawl is
		if up > 0 and (DirHorde.takes(S, f, "heavy" if up == 1 else "sig") or DirBrawl.takes(S, f, "heavy" if up == 1 else "sig")):
			continue

# sim/director/stick.gd, _go, after the request (:504-505)
	if DirHorde.on(S):
		_s(f, ST_PEND, 0)                 # the horde took the press as a pack blow: nothing is pending, so no late refusal is said (:779-784)

# sim/director/beam_move.gd: where the right stick's beam begins its charge, in a horde match it is refused with "horde_sig" and no charge starts.
#   I did not trace which function begins the charge; the guard in _start is the backstop (tryFire then returns false at :286-287).

# sim/director/grapple.gd: where a grab starts, in a horde match it is refused with "horde_grab". Not traced.

# sim/director/ending.gd, tick (:101)
	if not on() or S.game.ko != null or DirHorde.on(S):
		return                            # the one-on-one ending would open one player's brink to the other

# sim/director/exchange.gd, dirUpdate's time-cap lines (:721-723): not in a horde match
# sim/director/bands.gd, _bandTick (:157-162): in a horde match each seat's band is to its mark, a place's to its own
```

None of these lines adds a counted two-fighter spelling. What the hold's second edge (`up` of 2) means on the pad I did not trace; it arrives here as "sig" and is refused, said.

## 7. What breaks

| What | Why | Who |
| :--- | :--- | :--- |
| **Any check that reads "the first two slots are opponents" in a five-slot match** | In a Horde match they are partners | Simulation's stage 1 checks run with the switch off and are unchanged; new checks cover on |
| **The one-on-one ending and time cap** | Section 6.5: guarded off in a Horde match. `ending_check` gets a row for it | Encounter |
| **Everything that starts an exchange** | The right stick's beam, a held press's edge and a shot's finisher each reach the exchange without passing the first press's guard. Section 6.5 guards the three places an exchange is made. The right stick, its beam and the charged shot on RB are all on in the build the trial starts from | Encounter; reading 19 |
| **The right stick's strike** | It sets a pending word before it asks for its blow (`stick.gd:498-504`). When the horde takes the blow, the word must be cleared, or it gives a "late" refusal when its wait runs out (`stick.gd:779-784`) | Encounter: one line (section 6.5) |
| **The grab, the kick, the bands' approach and the far-band presses** | Each acts between two bodies without an exchange, and I did not walk what each does in a Horde match. The grab is refused in the first version | Encounter, Controls; reading 19 is the net |
| **An away body** | The `out` flag is read only by shots, the 2v2 code, the knock-out line and the one-on-one ending. An away seat or place would still step, fill its power, step up a tier and take hits | Simulation: three guarded lines and the park (section 6.3); reading 20 |
| **A pack body's own power** | It fills with time and with every hit, and a higher tier multiplies its blows (`fighter.gd:661`; `damage.gd:49`) | Encounter holds it at nothing (section 6.4) |
| **The intro** | The entrance brings in the pair (`intro.gd:506-510`): an empty second seat would fall in and dig a crater. The trial starts with the intro skipped; the build needs "an away seat takes no entrance" | Simulation |
| **The hit's picture** | With no whole-fight pause, the damage event's `stop` field reads 0 (`damage.gd:124-126`), and the fighter's contact shiver reads the fight's pause (the clock-by-body page lists `anim_fighter.gd`). The blow's read has to come from its weight | Animation, Rendering |
| **The freeze budget** | `SimHitstop` still counts while `SimClock.hold` writes nothing. Harmless, but its readings mean nothing in a Horde match | Simulation: skip its set-up when the horde is on |
| **A transformation's pause** | It is a run of frozen ticks for the whole fight (`sim.gd:398-402`; `pause.gd:142-148`), so with two players one player's transformation stops the other for its length. The clock-by-body page records a ruling that it should hold only the fighters involved; that is not built. The first version either accepts it or skips the pause in a Horde match | Game Design rules; Simulation |
| **Power from hitting the pack** | Every hit feeds both fighters' power (`damage.gd:91-92`), so a player reaches forms faster against 621 weak bodies than in a duel. Whether a weak body's hit should feed less is a number for Game Design | Game Design |
| **The mood and the acts** | They read the principals' stances and wounds (`mood.gd:277`, `:291`), now two partners. The fight's music mood will follow the players only. Whether a wave should drive it is Audio's and Game Design's | Audio, Game Design |
| **The camera** | The pair's frame holds both seats; with one player the second seat is away and must count for nothing, and the many-body frame is off by default with no shipped switch (`split_rig.gd:3460`). An arriving body and a winding body need weight. The split's own rules read the pair only | Camera |
| **The edge markers** | They are hollow triangles at the frame's edge, for bodies the frame left out (`ui_many.gd`). Not on or between the fighters, but new on Orb's screen: behind the look gate, and off in the trial's clip unless Camera asks | UI |
| **The corner plates** | Two plates for the two seats work as they are. With one player the second plate must hide, or show the "press any button to join" note that exists (`ui/widgets/ui_join.gd`) | UI |
| **The match-over card and the hub** | It opens on a knock-out or "no contest" (`ui_event_hub.gd:403`, `:499`). It needs a `horde_over` branch, the new lines, and a rule for the Rail covering the left side (A-UI-05) | UI |
| **Refusal reasons** | Two new codes, `horde_sig` and `horde_grab`, in Controls' table (`docs/controls/refusals.md`) | Controls |
| **New cues** | `horde_wave`, `horde_wind`, `horde_pack`, `horde_blow`, `horde_fall`, `horde_worn`, `horde_last`, `horde_down`, `horde_over`. Each needs a sound and a pad read or it is silent. A wind-up from behind needs its own sound (Game Design's rule) | Audio, Controls, Animation |
| **How worn a fighter is** | Nothing built shows the body on a fighter; the only read of it in the picture is the old bar (`render/core/hud.gd:219`). A run that can be lost needs it shown, in stages, on the fighter | Animation, Audio, Controls, behind the look gate (section 8.2, step 6); reading 23 |
| **The result's wording** | A count of fighters knocked out sits beside a card whose rule is that nothing on it counts people | Legal reads it; UI; Orb's question 7 |
| **The opponent's computer** | Not used by the pack. A second seat with its computer on is away, never the full computer | Encounter: one line (section 6.4) |
| **Saved matches and replays** | A horde replay carries `"horde": true` and five slots in its setup, and the file's hash. Older replays are untouched. A Deck tester's run leaves no match file today (MIS-04): unchanged by this | Tools |
| **Collateral** | A weak fighter launched through a building is real damage, so a Horde run wrecks more of the town than a duel. The result card says so. The old meters are zeroed (decision 6), so nothing feeds on it | QA reads it; World |
| **The two-fighter count** | At 365 against 365, with no slack. Unchanged only if the new files avoid the four spellings in code and in comments: the director's file reads the mark through `DirBrawl.rivalOf`, and `SimRoster.opp` gains a branch, not a call | Tools' ratchet; reading 16 |
| **The 140 places that name the first two slots by number** | In a Horde match they read two partners as the pair, and with one player an away second seat (section 3.12). Camera 37, audio 18, the host and old HUD 13, VFX 12, animation 6, net 3, director 28, core 23. None was walked | Each owner reads their own: Camera first, then Audio, Rendering, VFX, Animation, Netcode; Encounter and Simulation for the sim's |
| **The load-split gate** | `sim/core/horde.gd` names no director class; `sim/input/control.gd`'s new line reads state only | Simulation: `sim/core/tools/load_split.gd` |
| **LAN** | Not in this design. The shape is LAN one-on-one's (two people in slots 0 and 1), so it should be small, but I did not open `net/lan.gd`'s slot handling | Netcode, later |
| **The stamina loop (A3)** | A body made fresh needs a fresh stamina state too: one more one-body set-up | Simulation |

## 8. Build order and owners

### 8.1 The trial (Encounter, on a scratch copy, thrown away; nothing lands)

Start from a scratch copy of HEAD with the switches of the build Orb plays (`docs/tools/runs/6a30b4c9/switch-list.txt`), the energy model, dash, slip and kick on by setup, and flat-out flight at 3,500. In that list the right stick, its beam, the charged shot on RB and the grab are all on, so the guards of section 6.5 are part of T3 and not an extra.

| Step | What | Needs first | Done when |
| ---: | :--- | :--- | :--- |
| T1 | The state, the data file's loader, the five slots, `ended`, the hash lines. Places stand as dummies | Nothing | Switch off: the golden record is byte-identical. Switch on: two runs give one hash |
| T2 | Falling, the place going away and being inert, `fresh`, the wave table, the end. A scripted "fell this slot" stands in for blows | T1 | Readings 3, 4 and 20 |
| T3 | The mark, the player's pack blow with each weight's own wind-up and the lunge, the side rule for shots, and the guards that keep every exchange from starting | T2 | A scripted pad clears wave 1; readings 14 and 19 |
| T4 | The pack's play: arrive, crowd, the lanes and their gap, wind up, strike, the spacing, the strong block and the clean dodge | T3 | Readings 5, 6, 7, 21 and 22 |
| T5 | Going down and getting up; the second seat joining, leaving and coming back | T4 | Reading 15 |
| T6 | The probe: runs to the end with the idle, guard-tapping, dodge-tapping, mashing, slow and medium pads, alone and two, 10 seeds each. Then the medium pad on two other sets of numbers: Game Design's blows with the body back in each breather (row D), and twice as busy with blows half the size (row G) | T5 | Readings 8, 9, 10, 11 |
| T7 | The tick's cost at two and at five bodies, in a quiet window the EP gives | T4 | Reading 12, sim half |
| T8 | The picture: Tools' film variant of the capture hook starts a Horde match, turns the many-body frame on and hides away bodies. One capture at a time, through Tools' launcher only | T5; Tools | The clip (section 9) |

- **If the budget runs short,** T8 goes last and T5's join may be dropped: the run alone, the readings and the cost answer the path's four questions. The clip is what Orb's questions need. T6's two extra sets are data changes, not code.
- **The trial answers the path's S3** like this: the ring still applies but is not the horde's base (section 2); five bodies' cost is T7; respawn fits (T2); lifting the limit is section 3.12, re-read against T7.
- **What the trial is most needed for** is what the paper could not settle: how busy the pack should be (question 8), whether the entrance reads at its speed (reading 13), and whether two players have enough to fight (question 4).

### 8.2 The build for Alpha (A4), if Game Design takes the design

A change to hashed state lands only in a golden window. All of this is behind one switch that is off, so no golden moves, but `hash.gd`, `desync.gd` and `replay.gd` are touched: it lands in A4's window (the path's GW3), after A3's beam and stamina work.

| Step | What | Owner (paths) | Needs first | Window |
| ---: | :--- | :--- | :--- | :--- |
| 1 | Game Design's page from this one, with its rulings on section 4 (rows 20, 21 and 22 first: the gap, the blow's size and the body's share decide every other number); QA's bands from section 9 | Game Design (`docs/design/`); QA (`docs/qa/`, `qa/`) | The trial's readings; Orb's answers 1 to 3 | Paper |
| 2 | The state, `sim/core/horde.gd`, the one-body set-ups, the guarded lines of 6.3 (the away body's three among them), the body's share once A3's loop is on, the checks | Simulation (`sim/core/`); Controls for the line in `sim/input/control.gd` | 1 | GW3 |
| 3 | `sim/director/horde.gd`, the guarded lines of 6.5 (the exchange's three, the hold's edge, the stick, the beam, the grab), the probes | Encounter (`sim/director/`) | 2 | GW3 |
| 4 | `data/fight/horde.json` and its schema; the switch list row | Game Design's numbers; Tools (`tools/schemas/`, `tools/preview/`) | 1 | GW3, with 2 |
| 5 | The frame: both seats, an away seat counting for nothing, arrivals and wind-ups in the frame | Camera (`render/camera/`) | 3 on a scratch copy | After GW3, look gate |
| 6 | An away body not drawn; a downed player drawn; the fallen picture that stays and goes out of view; the entrance's streak; the body's read on the fighter in stages (a half left, a quarter left, last legs): stance, breath, marks on the torso, a pad pulse. No bar | Rendering, Animation, VFX (`render/`); Audio for the breath; Controls for the pulse | 3 | After GW3, look gate |
| 7 | The weak fighter's body: one, or an existing body in another colour, then Legal's look | Art (`art/`), Legal | Nothing | Before 9 |
| 8 | The sounds and pad reads for the cues | Audio (`audio/`), Controls (`sim/input/`) | 3 | After GW3 |
| 9 | The mode row made ready, the setup's start, the result lines (the knocked-out line only if Orb says yes, and its wording read by Legal), the wave line, the join note | UI (`ui/`); Rendering for the host's start in `render/core/main.gd:1337-1348`; Legal | 3, 7 | After GW3, look gate |
| 10 | The mode smoke plays a Horde run to its result and back (X-05); the frame record at wave 8 (X-10) | Tools, Performance | 9 | A4's exit |
| 11 | QA's run-length and fairness readings, alone and two; the Deck's bench file | QA, Performance | 10 | A4 first reading, A5 pass |
| 12 | Second step, if Orb says so: bodies knocked into each other, the grab's throw and the carry, the strike on a body in the air, a blow that reads through two or more, the marksman | Encounter, Combat, Animation | 11 plays well | After 11 |

The EP's safety readings on the largest wave's clip (the path's X-02) sit beside step 10 and are the EP's.

## 9. Readings

First pass lines; Game Design and QA own the final ones. **The medium pad** in these lines is defined, so that two people measure the same thing: 4 presses a second, 1 press in 10 going wide, defending half the pack blows that come due (of those, 6 in 10 by a held guard, 2 by a strong block, 2 by a dodge), and going for a wind-up it has seen for 12 ticks. QA's scripted player at medium (`qa/godot/players.gd` has the kind) needs a Horde variant written to that. "Model" is what the paper model gives at the first values; it is a guess at the reading, not the reading.

| # | Reading | First pass line | How it is measured |
| ---: | :--- | :--- | :--- |
| 1 | The switch off is off | Golden record byte-identical; parity and determinism pass | Exists: `sim/core/tools/golden.gd`, `parity.gd` |
| 2 | The switch on is deterministic | One run twice: one hash. A replay reproduces. A rollback re-run across a refill: 0 ticks differ | To write: `sim/core/tools/horde_check.gd`, on the pattern of `kick_check.gd` and `fork_check.gd` |
| 3 | A body made fresh is fresh | 0 fields differ from a new match's body of that fighter (position, keys and horde state aside), over 200 refills | `horde_check.gd` |
| 4 | Three at a time, five in all | Never more than 3 places in the fight; the list is always 5 | `horde_check.gd` |
| 5 | Spacing (hard) | 0 pairs of pack blows landing on one player within 8 ticks. Never more wind-ups in flight at a player than that player's lanes | To write: `sim/director/tools/horde_probe.gd`, on the pattern of the parked `ring3.gd` |
| 6 | The pack keeps swinging | At one medium pad: at least 30 wind-ups start a minute, and at least 2 a minute start while another is in flight at that player. With three bodies within reach of their mark, all three are only circling for at most 60% of those ticks. (Model: 43, 3 and 45%.) It fails if the pack is seen to wait | `horde_probe.gd` |
| 7 | Agency (hard) | 0 ticks in which a seat's fighter moves against a held stick, other than in a lunge that seat pressed. Every such lunge ends within 30 ticks, or on the tick of a dodge or a guard press. 0 presses in the 6 ticks after a pack blow lands that give neither a blow nor a said refusal. 0 ticks in which a pack body stops a seat's flight | `horde_probe.gd`, reading the intent, the positions and the cues |
| 8 | Run length | Medium pad, 10 seeds: 7:00 to 9:00 alone, 6:00 to 8:00 with two. (Model: 7:52 and 6:43. X-10's own line is 5 to 10 minutes, a first reading at A4 and a pass at A5.) The count per wave is the key that moves | `horde_probe.gd` |
| 9 | Fair, alone | Medium pad loses 20 to 45% of the body and goes down in 0 of 10 runs (model: 39%). At 3 presses a second it loses 30 to 60% (model: 49%). A pad that mashes and never guards finishes (model: 53% lost). A slow pad at 2 presses a second reaches wave 6. For information, with no line yet: how long the idle pad lasts (model: 8:25) | `horde_probe.gd` |
| 10 | Two players have enough to fight | Each medium pad loses 10 to 35% (model: 20%). A seated player has no pack body within lunge reach for at most 35% of a wave (the model has no positions and cannot say) | `horde_probe.gd` |
| 11 | Twelve fodder in a row | 10 to 20 seconds for the medium pad (Combat's band). The model says 5.4, so this is expected to fail on the fast side; the reading says by how much, and Game Design rules on the band or the fodder | `horde_probe.gd`, wave 1 |
| 12 | Cost | Sim tick at five bodies in wave 8's thickest minute: mean at most 1.0 ms, 99th percentile at most 2.5 ms on Orb's PC, quiet machine. The desktop build holds 60 frames a second at wave 8 | Exists: `sim/core/tools/tick_prof.gd` (needs a Horde setup flag). The frame record is Performance's bench from A1 and A2 |
| 13 | The picture | At most 5% of arrivals first drawn inside the view. 0 wind-ups at a player that begin outside that player's frame (hard). The entrance reads as a body flying in at its first speed; if it does not, the other two ways in (section 3.6) are tried | To write: Camera's frame record joined to the sim's positions. Camera's `many_probe.gd` is the start. The last part is the look gate's |
| 14 | No hurting your own side | 0 hits of one seat on the other. 0 hits of a pack body on a pack body | `horde_probe.gd` |
| 15 | Joining and leaving | A second pad's fighter is in the list and reading its pad on the tick after the join. A leave gives no error. A replay with both reproduces. Leaving and coming back never raises a seat's body and never lifts a downed seat (hard) | `horde_check.gd`; exists: `sim/core/tools/rec_check.gd` for the replay half |
| 16 | The two-fighter count | 365 or lower. The pseudocode here adds none of the counted spellings by my reading; the count was not run on it, because nothing is built | Exists: `node tools/ratchet-two-fighter.mjs` |
| 17 | The core does not load the director | Passes | Exists: `sim/core/tools/load_split.gd` |
| 18 | The look | Anything a one-on-one match shows is unchanged against the 9 November build. Every new picture passes the look gate (ADR 0010) | Exists: the look gate's side-by-side |
| 19 | No exchange in a Horde match (hard) | 0 exchanges started in a run, with every button, the right stick, a held press and RB tried. 0 ticks with a seat in the state "locked". 0 late refusals from the right stick | `horde_probe.gd`, a pad that presses everything |
| 20 | Away and down are inert (hard) | 0 hits on an away body or a downed player. 0 power gained and 0 pauses raised by an away body. 0 tier rises by a pack body | `horde_check.gd` |
| 21 | The field is full | One medium pad: at least two pack bodies are in the fight for at least 60% of each wave, and none for at most 10%. (Model: 95% or more, and 1%.) With two medium pads, for information: the model gives 68% in wave 1 rising to 88% | `horde_probe.gd` |
| 22 | It cannot be tapped through | A pad that only taps guard every 12 ticks, and one that only taps dodge every 12 ticks, each fell 0 bodies in wave 1 and neither lasts more than a third longer than the idle pad (model: the dodge-tapper lasts exactly as long, the guard-tapper 28% longer) | `horde_probe.gd` |
| 23 | You can tell how worn you are | A tester stopped at three points of a run and asked "how close are you to going down?" is right to within one stage (plenty left, half, a quarter, last legs) at least 2 times in 3 | A play test with the build of step 6; QA and UI. Not a trial reading |

**What the clip for Orb shows** (about 75 seconds, with the buttons pressed drawn at the edge as in other clips):
1. One player, wave 1: weak fighters streak in and circle; a string of X runs through them; each one's replacement streaks in.
2. Wave 4: tougher ones among them. One wind-up beaten by hitting first, one guarded, one dropped by a guard raised at the last moment, one that lands: the flinch, and the next press working.
3. B: one sent through a building.
4. A second controller joins: the second fighter appears at the edge and flies in under its own pad. A blast passes the partner and hits a weak fighter.
5. One player goes down; the other finishes the wave; the first gets up.
6. The result screen.

A second, short clip for question 3: the same ten seconds of wave 4 with two players, once with only the struck fighter stopping for a beat, once with the whole screen stopping as it does one-on-one.

A third, for question 8, if the budget allows a third capture: the same fifteen seconds of wave 4 at the first numbers, then twice as busy with hits half the size. If it does not, the EP chooses which of questions 3 and 8 gets the second clip.

## 10. Size

An honest guess. The path carries the horde at 16M tokens and asks S3 to say 12M or 20M. A size of M here is one director's build window, as in Game Design's pages.

| Piece | Guess |
| :--- | ---: |
| The trial (section 8.1) | about 2M, the path's figure, counted by the path among the spikes and not in the horde's 16M (`04-path-to-alpha.md:38`, `:90`). T1 to T7 fit if the picture (T8) is kept to one capture; the guards of T3 and the two extra sets of T6 make it tight |
| Game Design's page and QA's bands | 1M |
| Simulation: state, the one-body set-ups, guarded lines, the away body, the body's share, checks | 2.5M to 3.5M |
| Encounter: the pack, the run, the guards, the probes | 4M to 5M |
| Camera | 1.5M |
| Rendering, Animation, VFX, with the body's read in stages | 2.5M |
| UI, and the host's start | 1M to 1.5M |
| Audio, Controls, Art, Legal, Tools, Performance | 2M to 2.5M together |
| The EP's gates and landing | 1M |
| **The first version for Alpha, without the trial** | **15.5M to 18.5M** |

- **So: at or a little over the path's 16M. Not 12M, and under 20M** unless the second step is counted.
- **It falls toward 12M** if the join mid-run, the result card's extra lines, the body's read in stages and the weak fighter's own body are cut to the least (start with two or one, three lines, the last-legs cue only, an existing body in another colour). I would not cut the body's read: without it a player cannot tell they are losing.
- **It rises past 20M** if the second step (bodies into bodies, the throw and carry, the strike in the air, the marksman) is counted in Alpha, or if more than three at a time is wanted (section 3.12 adds 3M to 5M for eight). Orb's own words put the second step close to the heart of the mode, so the EP should expect to be asked for it.
- **What it depends on most:** whether making a body fresh in place is as clean as section 6.2 hopes (reading 3); how much Camera has to do for one seat away; and the picture and sound lines, which are guesses until the 118 two-fighter reads outside the sim are walked (section 3.12).

## 11. For Orb

Draft questions for the EP to put, one at a time. Questions 1 to 3 can be asked now. Questions 4 to 8 are better asked with the trial's clip.

**1. What is a Horde run?**
- **Eight waves you can beat.** Each wave is bigger and tougher. Clear the eighth and you have won. We are aiming at about eight minutes and will set the length from the trial.
- **Endless.** The waves keep growing until you fall. There is no win, and the result is how long you lasted.
- I think Orb would want the eight waves first: it has an end to reach, it is the right length for a friend trying the game, and an endless row can be added to the menu later from the same pieces.

**2. With two players, what happens when one of you goes down?**
- **You get up when your partner finishes the wave.** A short wait, never more than a wave.
- **You are out for the rest of the run.** It makes going down matter more, and one player may watch for several minutes.
- **Your partner can get you up** by staying beside you for a moment while the weak fighters keep coming. A risk your partner chooses. It needs new work and is not in the first version.
- I think Orb would want the first for now, with the third workshopped for later.

**3. When a hit lands in Horde, what stops for a beat?**
- **Only the fighter who was hit.** Everything else keeps moving. With two players, your fighter never stops because of your partner's hit.
- **The whole screen, as in a one-on-one fight.** Every hit has the weight you know. With two players, your fighter stops for a beat each time your partner lands a hit, and each time a weak fighter is struck.
- I think Orb would want only the fighter who was hit, because nothing should stop your fighter that you did not do. Game Design has recommended the same since October and is waiting for Orb's word. The second clip shows both.

**4. With two players, is three weak fighters at a time enough?** (After the clip.)
- **Keep three.** With two of you they fall twice as fast, so each of you will sometimes have nobody to hit for a moment. It is what the game can do today.
- **Four or five when two are playing.** More to fight for each of you. It means lifting a limit in the game's engine: more work for four of the teams, and the frame rate on a Steam Deck becomes the thing to watch.
- I think Orb would want to see the clip before choosing. My lean is three for Alpha, because Orb said go on three and the bigger number is safer after a Deck has run the smaller one.

**5. Throwing weak fighters into each other: with the first Horde, or after Alpha?**
- **Straight after the first version plays well,** before Alpha if it fits. Send one weak fighter into another and both go down, and it carries on until the speed runs out. Grab one, fly with them, and throw them into the rest. Hit one again while it is still in the air.
- **After Alpha,** as the plan has it today.
- I think Orb would want it straight after. Orb named exactly these as what makes being outnumbered rewarding ("launch an opponent, grab the other one, fly with them at great speed, then launch them at a collision angle", vision.md:1844), and said of weak fighters knocked into each other: "sounds cool, having slight advantages through tactical sells like this makes it engaging to be outnumbered, as long as its choreographed dynamically, feels emergent" (vision.md:1767).

**6. Does knocking a weak fighter out give you a little energy?**
- **Yes, a little:** more for a tougher one. Clearing a wave tops you up for something big.
- **No.** Landing hits already gives your stamina back in the new rules; a knock-out adds nothing on top.
- I think Orb would want yes, a little. Game Design recommended it in October and it has not been asked yet.

**7. Does the result screen show how many you knocked out?**
- **Yes.** A number to beat next time, beside your time.
- **No.** Only the waves you cleared, your time, and what the fight did to the town. Game Design's October recommendation was that a weak fighter you knock out counts toward nothing but a little energy.
- I think Orb would want yes, because a run needs something to beat. It is a count of fighters knocked out, never anything else, and Legal reads the wording first.

**8. How busy should the weak fighters be?** (After the clip.)
- **As in the clip.** A swing comes at you about every second and a half, each one small. All of them are on you and circling; each waits about four seconds between its own swings.
- **Busier, and smaller still.** Swings come twice as often and each takes half as much.
- **Busier, with your strength back between waves.** Swings hit as hard as Game Design first set them, and each ten-second breather gives your strength back. You can then only lose inside a single wave.
- I think Orb would want to feel it before choosing. It is the place where "nobody stands around waiting" and "not overwhelming" pull against each other, and I could not settle it on paper.

## 12. Risks, unknowns and what was not verified

**Risks.**
- **The rhythm may read as waiting.** At the first values each lane's gap is four seconds, and with three on a player all three are only circling 45% of the time by the model. Orb's line is against "standing around waiting for their turn", and Game Design's rule is against limits as cooldowns. This page names the departure (row 20) and gives two other sets of numbers (rows D and G), but it does not solve it. The trial and question 8 do.
- **The model is not the game.** It has no positions, its pad presses X only, and how much a pad defends is a dial I set. The first cut's model had the same limits and its conclusions did not survive review. Every "model" figure on this page is a guess at a reading.
- **`SimRoster.opp` following the mark is one line with 72 callers in shipped code** (the project's own counter). Most never run in a Horde match, because no exchange starts. The ones that do (the dash's ease, a blast's aim) are what the line is for. Any other that runs is found by the trial, not by reading. This is the design's widest unknown.
- **Other things that act between two bodies without an exchange.** The guards of section 6.5 cover the three places an exchange is made, the hold's edge, the right stick's strike, its beam and the grab. I did not walk the kick, the charged shot's hit, the bands' approach or the far-band presses for what they do in a Horde match. Reading 19 (a seat never "locked") is the net.
- **Making a body fresh in place** depends on every per-fighter set-up having a one-body form. Reading 3 is the guard. A leak is a behaviour bug, not a desync: the state is still deterministic.
- **A guarded hit draws once from the match's stream** (`damage.gd:32` reaches `wounds.gd:79-94` when the family is "guard"). That is existing code, seeded, and inside a Horde match only; the horde's own code draws nothing from the stream. Named because the house rule is keyed draws only.
- **Two players with three at a time may be thin** (section 3.11). The paper model cannot settle it.
- **A weak blow cannot wound.** Out of an exchange, wear below "battered" fades every tick (`wounds.gd:171-198`), and a Horde match has no exchange. So the body is the only clock that runs down, and limbs mostly stay sound. I think that suits "pressure, not attrition", but it is a consequence nobody chose.
- **When A3's body rule lands, the clock changes.** In that model a hit on a sound part takes nothing from the body (`energy-stamina-body.md` §3, rule 4). Weak blows on a healthy fighter would then spend almost none of it, and a run could not be lost. Departure 22 and the key `down.bodyShare` are this page's answer; they are a proposal until Game Design rules, and until then every fairness figure here describes today's code only.
- **The player cannot yet see the clock.** Nothing built shows the body on a fighter. If the read in stages (section 3.8) is cut or late, a run of eight minutes ends without warning for anyone who was not counting.
- **Run length is set by how fast a person fells a weak fighter,** which the model overstates (twelve fodder in 5.4 seconds). If the first reading is far off eight minutes, the counts move, and readings 9 and 10 move with them.
- **621 bodies in a run are all the same fighter in the trial.** Whether that reads as a horde or as one fighter copied is a look question for Art and Orb.
- **A fallen body's picture is not a body.** A blow at a fallen one meets nothing. If that reads wrong, the place has to stay a little longer before it goes away, and the field thins by that much.
- **The entrance.** A weak fighter arriving at more than three times flat-out flight may read as wrong, or may not be visible at all in 16 ticks. The other two ways in each have their own cost (section 3.6).
- **The path's order.** The horde is in A4 after the beam and stamina work of A3. If it is pulled forward, the signature's refusal (section 3.4) ships as it is.

**Not verified.**
- That 3,000 units is outside the camera's widest view (`split_rig.gd:4907-4908` shows the view can widen a long way). Reading 13 decides.
- How a body is drawn while `out` in a one-fight match, and how a fighter's view takes a body moved 3,000 units, or parked 400 bh up, in one tick. I did not open `render/core/pane_world.gd` or the fighter view. Whether anything in the sim or the camera reads a body parked that high.
- How a downed fighter with no input comes to rest outside an exchange (section 3.8).
- How the rollback's memory grows with five bodies. (That `net/snapshot.gd` copies new state classes with no change was confirmed by the code reviewer at `snapshot.gd:163-173`; I did not open it myself.)
- How `net/desync.gd` names a value appended outside `_fields` (its `md` argument); the block in 6.1 shows what must be there, not how it is labelled.
- How `SimPower.sendForce` treats a key it does not know (`power.gd:231`), and what `DirLaunch.knock` and `knockBack` do to a body outside an exchange (`launch.gd:1205`, `:1381`): I read the signatures, not the bodies. The pseudocode uses only the launch call that `damage.gd:156-157` already makes.
- That Y reaches the director as the request kind "heavy" and is the brawl's medium, as section 6.4's `takes` assumes. I read it from `control.gd:26-31`, `exchange.gd:59` and `:75-78`, and `brawl.gd:591`; I did not trace the pad's mapping. What the hold's second edge is on the pad.
- That the blast's own press (`DirBlast.press`, `blast.gd:45`) and the charged shot on RB do nothing between two bodies beyond firing a shot. I read the call and the file's head, not the bodies.
- Where the right stick's beam begins its charge, and where a grab starts (section 6.5). That clearing the stick's pending word after the request leaves the rest of `DirStick._go` sound.
- Whether today's lunge runs the weight's own wind-up again on arrival (section 3.4).
- That reading the dodge's tick, the guard's tick and the director's lockout from the horde's own code gives the dodge and the strong block the feel they have inside an exchange. I read `act.gd:55-70`, `interrupt.gd:270-288` and `:353-362`; nothing was run. The clean-tap rule for the dodge and its 30 ticks are mine, not a ruling.
- The bit-packing ceiling (eight slots or thirteen), section 3.12.
- Which of the 118 two-fighter reads outside the sim run in a Horde match and what each shows with the second seat away (section 3.12). I counted them by folder with the project's counter; I did not walk them.
- Every cost in section 3.12 and every size in section 10. They are arithmetic on old or indicative figures, and guesses.
- The parked ring was not run by me. Its state is from Encounter's dry-run page (not yet committed) and the map; I opened `ring.gd:8` and `grapple.gd:36` for the shared base.
- The A4 Performance brief still asks for six, eight and twelve bodies (`05-directives/A4/performance-platform.md:9`) while the A1 amendments say up to five. Not mine to fix; the EP should.
- The model: `horde-model2.cjs`, `horde-first2.json`, `model-out2.txt`, `arms2.cjs`, `arms-out2.txt` and `cost.cjs`, and the first cut's `horde-model.cjs`, `horde-first.json` and `model-out.txt`, are in my scratch folder (`...\scratchpad\s3h\`), which a reboot can clear. If Game Design wants the model kept, it should be copied to a path of theirs.

## Checks

Two independent reviewers attacked the draft, one reading it against the code and one against the design record and Orb's words; each blocker they raised was then given to a checker whose job was to refute it, and all four held. The other nineteen findings were not sent to a checker: the fixer checked each against the files or by arithmetic before using it, re-ran the paper model where a number moved, and re-read the finished page.

| Finding (plain words) | Verdict | What changed |
| :--- | :--- | :--- |
| **Blocker.** "No exchange ever starts" was not true: the right stick's beam and a held press reach the exchange's start without passing the horde's guard, and a right-stick strike would give a late refusal | Fixed, with the checker's corrections (the pend is set at `stick.gd:498`; the computer's answer is a follow-on, not a third way in) | Section 6.5: a guard at each of the three places an exchange is made, the hold's edge, the stick and the beam. Section 3.4 says what each press does. Reading 19, hard. T3 carries the guards |
| **Blocker.** The pseudocode spelled a counted two-fighter name three times in a shipped file, which would break a count that has no slack | Fixed | The mark is read through `DirBrawl.rivalOf`. Sections 3.3, 6, 6.4, 7 and reading 16 now agree |
| **Blocker.** At the first values the field was nearly empty (under one weak fighter in the fight on average), so the page did not deliver "three at a time", and its fairness held only because the field was empty | Fixed, with the checker's point that a slower pad made it worse, not better | A fall to its replacement goes from 57 ticks or more to 18. New first values throughout sections 3.5 to 3.8 and 5. Section 3.11 rewritten on a second model with how full the field is. Reading 21. Section 1 says what the model shows |
| **Blocker.** A hidden attack-again time on each body went against Game Design's rule that the horde's limits are never cooldowns, was not in the departures, and made the pack look more like a queue than the ruling it departed from | Fixed in the checker's wider form: the gap is counted a lane, as the ruling counts it a turn, and the limit that remains is named | The attack-again time is gone. Lanes and their gap in 3.5 and 6.4. Departure 20 names the gap as doing a cooldown's work, with the model's reason. Reading 6 can now fail. Question 8 puts it to Orb. The reviewer's other option (no limit at all) is row B of 3.11: it does not survive on paper |
| An energy press and RB with B were swallowed by the horde's guard and became melee blows | Fixed | `takes` sends an energy press to the blast's own press and sits after the charged shot's line. Section 3.4 rows |
| An "away" body was not inert: it was still stepped, filled its power, and could be hit; a downed player could still be hit | Fixed; beams are covered by the one guard in the ordinary hit and by parking, not by a guard in the beam's own sampling | Three guarded lines in 6.3, the park, the pack's power held at nothing, reading 20, a row in section 7 |
| The stance rule was left out of the damage arithmetic (and the same point from the design reviewer) | Fixed: the ordinary hit's rule is kept and stated | Sections 3.5 and 3.8 give each stance's figure; the model applies × 1.12 and the guard's × 0.38 |
| Y and B landed as fast as X, and the far travel was the tap chase's 20,000 a second where the text said the lunge | Fixed | Each weight's own wind-up; the lunge at the faster of its speed and flat out; nothing past its reach (3.4, 6.4, departure 24) |
| The fairness claims rested on a pad pressing 7.5 times a second that never missed; the first values failed the page's own run-length line; "about eight minutes" had nothing behind it | Fixed | Pads by presses a second with a miss rate; a table from 2 to 7.5 a second; the medium pad defined in section 9; counts raised so the model gives 7:52; question 1 reworded |
| The way to lose was built on a body rule that Alpha will not have | Kept as a risk and made a departure | Departure 22, the key `down.bodyShare`, section 3.8, section 12 |
| "It shows on the fighter" was not true: nothing shows the body | Fixed in the text; the work is listed | Section 1 says so plainly. The body's read in stages in 3.8, 8.2 step 6, section 10; reading 23 |
| Mashing X would fly the fighter to any body at any distance, with no way to call it off | Fixed | The lunge's reach is the limit; an arriving body can be met inside it; a dodge or guard calls the lunge off; reading 7 |
| The strong block and the dodge could be tapped without limit | Fixed | The game's own block window and lockout are read; a clean-tap rule for the dodge (departure 29); two tapping pads in 3.11; reading 22 |
| "Down" and "away" were one flag with three different accounts, and leaving and rejoining healed a player | Fixed | Down is its own phase; one account in 3.8; the rejoin rule in 3.9 and 6.4; reading 15 |
| Orb's line was quoted for its first half only, and several accepted rulings were cut without a row | Fixed | The full quote and what the first version does and does not give; departures 25 to 27; question 5 widened; a sent body is not struck twice |
| The result screen counted knock-outs against Game Design's recommendation, without a row, under a line about Legal's rule | Fixed; the count is kept as a proposal | Departure 28, question 7, the data key, Legal named in 3.8 and step 9 |
| The cost of lifting the limit answered "every place that assumes two fighters" with one row and wrong counts | Fixed for the counts and the list; the walk itself is kept as not verified | Section 3.12's rows by folder, a row in section 7, sections 10 and 12 |
| Minors: arrival time by kind; mislabelled counts; the desync block and the missing field declaration; the list of what changed in two days, solid bodies and the beam's pass-through; quotes, line numbers and the size sum | Fixed. One count differs from a reviewer's: `exchange.gd` reads the one exchange 16 times by the counter's own pattern, not 15 | One entrance speed for every kind (16 ticks); 3.12 and section 12; 6.1; section 2, 3.3 and 3.4; the opening quotes, section 2 and section 10 |
