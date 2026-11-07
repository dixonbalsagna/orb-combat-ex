# Fighting together: the 2v2 co-op packet

Orb's stand-in, 2026-11-07, overnight. **A proposal for the EP to route. It isn't a decision, no team move in it is built, and every number is a first guess.** It answers Orb's order from the crunch: "aggressively tune toward co-op over LAN (2v2)".

**Version 4.** Each version was checked against the code, the rulings and Legal before the next was written:

| Version | Checked by | What it fixed |
| :--- | :--- | :--- |
| 1 | One checker, 14 findings | Most of 2v2 was already on main, not missing. The team moves reached into the other fight |
| 2 | Five checkers: rulings, sim and rollback, physics and balance, facts, completeness | The together shortcuts as asked broke Legal's RL-241. About ten things a human needs were missing. Two near-term moves couldn't work as written. Nine rulings changed without being listed |
| 3 | Two checkers, on what changed | Legal's RL-249 (01:37) wasn't carried. There's no switch per setup for blows from outside. A long pause ends a LAN match. The other fight's effects feed the wrong fight on the second PC. The arrival misread Game Design's long strike. 3.4's maths could create energy |

**Sources:**
- Game Design: `docs/design/two-v-two.md` and `playable-build.md`. Their rulings stand, except the changes section 5 asks for.
- Legal: `docs/legal/review-log.md`, RL-230, RL-241 and **RL-249**.
- Simulation: `sim/core/cross.gd`, `stage.gd`, `docs/architecture/cross-fights.md` and `fight-swap.md`.
- Encounter: `sim/director/outside.gd`.
- Netcode: `net/lan.gd`, `net/session.gd`, `docs/net/rollback.md` §4.
- VFX and Rendering: `render/vfx/vfx_hub.gd`, `stage_feed.gd` and `render/core/sim_host.gd`.
- The physics packet, and the beam move.

Nothing here touches civilians or RL-247. Every piece goes behind its own switch, and a 1v1 stays byte-identical.

## The short version

1. **The rules half of 2v2 is on main, switched off. What a human needs to play it as co-op mostly isn't.**
   - You'd never hear your partner call.
   - You'd get no warning of a beam from the other fight, though the computer dodges it in code.
   - Your partner's fight would be silent.
   - A long pause on one PC ends the match.
2. **The first together try is small, and Legal has cleared it (RL-249).** Hits across fights are on, and your partner's fight isn't drawn. Legal's three conditions:
   - the beam warning follows RL-227;
   - the WHO PLAYS line gains one sentence;
   - check rows cover the setup.

   It needs a switch per setup for blows from outside, which doesn't exist yet. With what else a human needs, that's about 5.5M tokens (section 1).
3. **Drawing your partner's fight is cleared to build and try privately, under RL-249's ten conditions.** The main one: one flash register per screen across both fights. It opens to nobody but Orb until the clips pass. About 4.5M tokens.
4. **The team moves come after,** each as its own Legal row (RL-249 (5)).
   - The arrival is Game Design's to define: the long strike across fights.
   - The tag, the pass, the cradle, the brace and the Unison line are each corrected.
   - Two need Orb's word on friendly fire.
5. **Everything costs about 37M tokens, roughly a third of a week,** not counting the physics model and flight strikes (section 7).

## 1. A first co-op match: what it really needs

Read on main on 2026-11-07, at 3c9005ac and after.

**On main, all off:**
- **The rules for hitting across fights:** `SimCross` and `DirOutside`. They cover blows from outside on openings, shots, mines and beams across, finisher breaks, and the team re-stun.
- **What pulls the fights together:** the sends (`joinScore`), the winner flying over and the computer's rescue (`aiRescue`), and the brink's call as a sim cue (`_call`).
- **The rest of the plumbing:** the rejoin and the partner trade (`SimStage`), and NetLan's view of a partner's fight (`viewSlot`).
- **Drawing the other fight's bodies and beams:** `SimHost.draw_others`, through `--others`.

### The first together try (cleared by RL-249: hits across fights on, partner's fight not drawn)

| # | Piece | Acceptance | Who | Tokens |
| ---: | :--- | :--- | :--- | ---: |
| A1 | **Together shortcuts.** `NetLan.SETUP2` gains `"cross": true`. **Blows from outside need a switch per setup, which doesn't exist:** `DirOutside.on()` reads the data's global `outside.enabled` (`outside.gd:32-33`), and `landed()` reads it directly (`outside.gd:313-314`). Carry a setup key into the state the way `stage.cross` is (`stage.gd:70`), read by both `on()` and `landed()` | A Host and Join pair with it on, and the plain pair kept. **RL-249's WHO PLAYS sentence** (fighters in the other fight can hit you; your partner's fight isn't shown) in `lan_words.txt`, **and a `lan_kit.mjs` check for it**, since today's check only looks for RL-230's line (`lan_kit.mjs:156`). `lan_check` and `rollback_check` rows, plus a negative control that the key is off in 1v1 | Netcode, Encounter, Simulation | 1.5M |
| A2 | **Hear the call.** `brink_call` is a sim cue that nothing plays. It needs a voice line, a mark on the ring map and a rumble, read from both fights' events on each PC | A QA row: the call is heard and seen on the partner's PC | UI, Audio, Narrative, Controls | 1M |
| A3 | **A human's warnings and acknowledgements.** Put `beam_warn` on the beam alert's edge line, sound and rumble. Give a blow from outside's `start`, `whiff` and `hit` cues a press acknowledgement or a refusal word, because an attack press becomes a blow from outside whenever an enemy of the other fight is nearer than your own rival | **The `beam_warn` edge alert follows RL-227:** steady, thin, a 6-tick ramp, Reduce flashing limits (RL-249). A QA row compares humans and the computer answering a beam from the other fight | UI, Audio, Controls | 1M |
| A5 | **Pause on a LAN.** Start stops that PC's ticks, and with them `net.frame`, which is where ENet is serviced (`lan.gd:91`, `enet_transport.gd:102`). The other PC stalls 20 ticks later (`maxAhead`), and **past ENet's timeout the link drops and the match ends** ("The other PC has gone") | While paused, both PCs keep calling `net.frame` without advancing the session, and the other PC says "The other player paused". Or Start is off in the LAN setup. A `lan_check` row for a pause of 60 s or more | Netcode, UI | 0.5M |
| A6 | **The 2v2 length.** Game Design ruled 8 to 12 minutes with a cap at 14:00, and "the cap puts all four on the brink". Each fight has its own `timeCapAt` 660, shared with 1v1, read on that fight's own clock, so the two fights reach it at different moments | A 2v2-only key, and one shared stage clock for the cap and `DirEnding`'s `lastAt`. 1v1 byte-identical | Simulation, Encounter, QA | 1M |
| A7 | **Two fights on the old PC:** a frame read with A1's switches on | Performance's quiet-window rule | Performance | 0.5M |

**First together try: about 5.5M.**

### Then

| # | Piece | Who | Tokens |
| ---: | :--- | :--- | ---: |
| A8 | **Moving focus on purpose:** D-pad left and right, D-pad up for the call, and their teaching lines ("Your partner calls", "Hold attack to go") under the once-only hint rules. Netcode has the bits (3 of 6 spare), and Controls' claw check applies | Controls, Netcode, UI | 1.5M |
| A9 | **Your partner on the plate and the ring map.** RL-249 (9) passes it while it stays on the plate and never over a fighter | UI, Camera | 1M |
| A10 | **Your partner's fight in sound and rumble,** quieter and later with distance along the planet. Sound and rumble aren't light events (RL-249 (4)) | Audio, Controls | 1M |
| A12 | **A second person on the other PC.** RL-249 (10): still not covered until they're named to Legal. Netcode then changes the kit's words to what Legal rules | Orb, Legal, Netcode | 0.3M |
| A13 | **Game Design accepts holds per fight for the first match.** Game Design ruled a clock per body: a hit-stop holds only that exchange's fighters, and a blow from outside also holds its striker. On main a hold is the fight's, the striker isn't held, and a held fight's own shots and mines wait too. Simulation's body clock is a prototype, at about 2 sessions | Game Design | 0.2M |

**Then: about 4M.**

### Drawing your partner's fight (cleared to build and try privately under RL-249)

| # | Piece | Acceptance (RL-249) | Who | Tokens |
| ---: | :--- | :--- | :--- | ---: |
| A11 | **Draw the other fight with its effects.** Four parts:<br>1. **one flash register per screen,** summing every light event on screen from either fight and the shared world;<br>2. a desktop switch for VFX's other-fight effects, which only `?otherfights=1` on a local page can turn on today;<br>3. Rendering drawing the other fights' effect hubs;<br>4. **a fix in the stage feed:** it loops fights from 1 and assumes S holds fight 0 (`stage_feed.gd:52-66`). On the PC whose player is in fight 1, and after any trade, a hub gets fight 0's events while reading fight 1's state, so it has to be keyed by the real fight index relative to `S.stage.cur`. The hubs are fed only when `--others` and `other_fights_enabled` are both on | RL-249 (1) to (7):<br>- one register, limits on the sum, with catastrophe-class events taken across both fights together;<br>- calm is no exemption;<br>- the other fight gives way, never by a dissolve, fade, blur or marker;<br>- only what's on screen counts;<br>- the switch is private-LAN only, with Reduce flashing locked on and the warning shown;<br>- the 2v2 flash clips with both fights drawn, in both modes, day and night, including the two worst cases RL-249 names, through Tools' guarded launcher;<br>- QA's civilian band per fight and for both together (RL-249 (8)). Tested on the fight-1 PC and after a trade. Orb alone sees it first | Rendering, VFX, QA, Legal | 3M |
| A4 | **Who's who, once both fights are drawn.** Each fight is always one Protagonist and one Rival, so your partner and your partner's foe never look alike. But once both fights are drawn, you can't tell yourself from your partner, or your rival from theirs. **A second palette for the second copy of each fighter** | RL-249 (9): body colour only, auras and trails in lane colour, no ring, arrow, name or marker over anyone, and stills to Legal for an originality look. Then Orb's look | Art, Rendering, Legal, Orb | 1.5M |

**Drawing: about 4.5M. First co-op match total: about 14M.**

## 2. How a team move has to work here

### Partners are always in different fights

With hits across fights on, each fight is one of each team (`SimStage.trade` refuses a trade between teams). **There are two bridges between fights:**

1. **Mail.** A blow, a mine's blast or a beam's hit goes through `SimCross.send`, waits in `S.stage.mail`, and lands at the start of the receiving fight's **next live tick**.
   - That's at least one tick, and longer while that fight is held or paused. Fights are held 13 to 23% of ticks.
   - A read across from the sender's fight is 0 or 1 tick stale, by fight order.
2. **Direct insertion, for shots only.** There are two paths: `SimCross.fireAt`, and `_over` for a shot that meets an enemy of the other fight in flight. Both write into the other fight's shots, guarded by `sh.inT`.

**What a team move needs from the sim that isn't there:**
- **A per-kind dispatch in `SimCross._land`.** Today every letter lands through `SimDamage.hit`, so a kind that only moves a body would land as a hit first.
- **A resolver for collisions between bodies of different fights,** run between ticks in one place, as `trade` and the rejoin are. Both halves come from the same velocities before the collision, and each contact is latched once. That way neither fight sees the other's stale speed and collides again, and a KO can't cut a collision in half: at a KO, `fallen()` strips every letter to or from the fallen body before `_land` sees it. **Simulation owns this resolver, about 1.5M, shared by 3.5 and 3.6.**
- **Keys, for the right reasons.** Mail names bodies by keys (`"p1"` to `"p4"`) because a key follows a body through a trade and keeps the hash and the replay stable. Snapshots keep object identity inside the state. Only references a host holds from outside the state go stale on a rollback.
- **Float64 only.** Sim maths uses float64 scalars, `SimWrap.sdx` for every x difference and `SimDetMath.hypot` for lengths. Never `Vector2`, which is 32-bit. The parity and determinism lints apply.

### Direction and timing, never force

- **A team move can redirect a body, catch it, brace against it or combine two paid charges.** It never adds force that nobody paid for. Where two pushes meet one body, the energies add with no gain.
- **Every team move costs the team something:** one answer for the enemy instead of two, your own fight left alone, or both of you committed.
- **The team limits stay, all of them:**
  - one blow from outside per opening, per team;
  - one stun a string, across a team;
  - each pair's one big set piece every 20 s;
  - three planet-scale launches a match, per team;
  - one meeting per flight (new, in 3.4).
- **Legal sees each team move as its own row,** the Unison line first, near fusion (RL-249 (5)).

## 3. The team moves

Each move gives what you see and press, what changes, a sketch (GDScript-shaped, float64, names not on main marked *(new)* or *(physics packet)*), and the cost. Costs assume about 1M per session, including gates.

### 3.1 The arrival: Game Design's to define (after A1)

**What Game Design ruled:** "Focus on the far enemy and a held press pursues, and **the long strike** (map row 3) pays for the arrival." The long strike is "flat out (hold LT) toward the rival, then B or a right-stick flick". It keeps the speed on arrival, sends up to ×1.25, and a whiff carries him about 1 s past.

**What happens today:** a press at an enemy of the other fight is a plain blow from outside. `DirOutside.takes()` only takes a light or heavy within `reachBh` 3. Game Design's flight-strike rules say flight strikes are read only up to 12.5 bh, that past that LT plus a face button is today's long strike, and that a press from outside another fight is a blow from outside (`playable-build.md`).

**So the arrival is a Game Design question:** make the long strike work across fights, or leave the arrival as a plain blow from outside.

**A long strike across fights changes these rulings:**
- the speed it keeps;
- a send of up to ×1.25 from outside, where today's is no send;
- its whiff carry;
- `playable-build.md`'s line that a press from outside is a blow from outside.

**I think Orb would want the long strike across fights.** He asked for flying to have a payoff, and the rescue is the best one there is. The first value would be a send from outside capped at the long strike's ×1.25, and still landing only on an opening.

**Two fixes either way:**
- **Read the flight at the press.** `takes()` calls `_toward()`, which zeroes `vx` and `vy` and starts a rush. So whatever the arrival needs from the flight is stored in a `dirI` slot inside `takes()`, before `_toward()`.
- **Both PCs feel it.** The hit lands in the struck fighter's fight, whose events the striker's PC doesn't play. So the striker's fight also emits an `arrival` cue, which Rendering, Audio and Camera play there.

**Cost:** about 1.5M once Game Design rules: Encounter 0.5, plus Rendering, Audio and Camera 1.

### 3.2 The relay send (after A1)

**What you see:** you launch your rival, and he lands near your friend's fight. Your friend hits him as he's up, with an ordinary blow from outside on an opening.

**The rule:** a second, smaller term beside `joinScore` in `DirLaunch.chooseLaunch` scores a landing within `relayReach` of your partner. It's off while it's two on one, exactly as `joinScore` is (`outside.gd:100-115`). The stick's vote still wins.

```gdscript
static func relayScore(S, A, D, lx: float) -> float:          # (new)
    if not on(S) or not cfgRelay().enabled or S.game.ko != null or _anyFightKo(S):
        return 0.0                                             # same rule as joinScore: no pull while two on one
    var P = partnerOf(S, A)
    if P == null or P.out:
        return 0.0
    var d: float = absf(SimWrap.sdx(lx, P.x))
    return float(cfgRelay().w) * clampf(1.0 - d / float(cfgRelay().reach), 0.0, 1.0)
```

**Rulings:** none. The assist table's first-version column has "a send's score gains a small term for your partner's position". **Cost:** about 1M.

### 3.3 The tag (later: needs Simulation's trade, and a ruling)

**What you see:** you and your friend fly past each other and swing into each other's opponent.

**What blocks a trade today** (`stage.gd:230-248`):
- with cross on, two bodies of different teams;
- either fight having an exchange, a clash, a beam, a shot, a pause or a KO;
- either of the two swapping bodies being in a launch.

So one bolt or one laid mine (a shot that lives 1,200 ticks) vetoes a tag.

**What the tag needs:**
1. **Simulation: deal with the swapping slots' shots.** Either end them, which is the real precedent (the rejoin's `_endShots` ends shots, it doesn't carry them), or build a real carry that remaps each shot's owner **and** target slot. Shots name both by slot, so a rival's homing shot would otherwise chase whoever now holds the slot.
2. **Simulation:** refuse while either body has a rush or an `O_KEY` (a blow from outside on its way), or mail addressed to it.
3. **Encounter: the wind-down.**
   - It holds blasts, beams and launches as well as exchanges.
   - Winding clears whenever the offer clears.
   - A team cooldown follows a lapsed offer.
   - **It never winds a fight whose exchange is a finisher, or whose partner is on the brink.**
4. **Controls:** the claw check.

**Rulings to change:** "Swapping: Just focus and flying. No special move," and the claw law's "a focus press must be worth little". **Cost:** about 3M.

### 3.4 Meeting a sent body: the pass (physics model, rulings)

**What you see:** you send your rival toward your friend, and your friend meets him. On along a line they choose, or head-on, stopping him dead so he drops into a crater below.

**What you press:** your partner presses attack as he arrives, and **the left stick sets the line he leaves on.**

**The rule, corrected again:**
- The meeting redirects his flight and adds no speed.
- The stick is normalised (the sim's stick is two axes, so a diagonal is longer than 1), and the cosine is clamped to [−1, 1].
- **A neutral stick means "along his line":** a plain catch-and-carry, with no stop.
- The energy kept is `E · (1 + cos θ) / 2`: all of it along, half at a right angle, none head-on.
- The stop is worked in the physics packet's units, turned into damage by its rule, and **capped in data.**
- **A head-on stop in mid-air leaves him launched at zero speed,** so he falls from there, and the crater is where he lands.
- One meeting per flight, cleared on landing. A redirect isn't a send.

```gdscript
# In the flying body's fight, _land's new per-kind dispatch, kind "redirect"; float64 throughout.
func land_redirect(S, body, o) -> void:
    if body.state != "launched" or _g(body, M_MET) == 1:
        return
    _s(body, M_MET, 1)                                        # cleared when he lands
    var sp: float = SimDetMath.hypot(body.vx, body.vy)
    if sp <= 0.0:
        return
    var ix: float = body.vx / sp
    var iy: float = body.vy / sp
    var sl: float = SimDetMath.hypot(float(o.sx), float(o.sy))
    var ux: float = ix if sl < STICK_DEAD else float(o.sx) / sl   # neutral stick: along his line
    var uy: float = iy if sl < STICK_DEAD else float(o.sy) / sl
    var cosT: float = clampf(ix * ux + iy * uy, -1.0, 1.0)
    var E: float = 0.5 * body.heft * sp * sp                  # (physics packet) heft and its energy unit
    var kept: float = E * (1.0 + cosT) * 0.5                  # never more than E
    sudden_stop(S, body, minf(E - kept, cfgMeet().stopCap))   # (physics packet) capped
    var v: float = sqrt(2.0 * kept / body.heft)
    body.vx = ux * v
    body.vy = uy * v                                          # zero head-on: he falls from here
    publish_flight_plan(S, body)                              # (physics packet)
```

**Rulings to change:**
- "It lands only on an opening".
- "No send, no knock-back" from outside.
- "No pass at first".
- The pass "counts as a normal blow".

**Cost:** about 3.5M after the physics model (Simulation 1.5 with the dispatch, Encounter 1, QA 1).

### 3.5 The cradle (physics model; Orb's word on friendly fire first)

**What you see:** you launch your rival into his own partner, mid-fight with your friend. Like the steel balls of a desk toy, your rival nearly stops and his partner flies off along the line. Your friend gets a free moment.

**Orb's question first.** It's one enemy partner's body moving the other. Orb's co-op answer was "no friendly fire on partners", with illusion or mind control as the exceptions. **Does a body sent into its own partner count?** If it does, the cradle is dropped.

**If Orb allows it:**
- Only for a send that drew a trail, tier 3 and up.
- Resolved between ticks by Simulation's resolver (section 2), along the line between them, with `SimWrap.sdx` for x.
- **Restitution `e` is 0.9, so the desk-toy picture holds.** The collision loses ½ · μ · (1 − e²) · (closing speed)², where μ is the reduced heft m1·m2/(m1+m2). That's about a tenth of the sent body's energy at equal heft, taken as a jolt split by heft. With equal heft and his partner still, the sent body keeps about 5% of his speed and falls, launched, from where they met.
- **It counts as one of the team's three planet-scale launches and as the receiving pair's set piece.**
- The struck partner is given the launched state, so he can slam. If he's the defender in your friend's exchange, the cradle waits until that exchange is free, so your friend's string or finisher is never broken by it.

**Rulings to change:**
- "A sent body passes through other fighters".
- "No send, no knock-back".
- "It lands only on an opening".
- Orb's friendly-fire rule.

**Cost:** about 2.5M after the physics model and Orb's word. Simulation's resolver is costed in section 7.

### 3.6 The brace, against a wall (physics model; Orb's word on friendly fire)

**What you see:** you block a huge blow and plough backward toward a cliff or a megastructure's foot. Your friend lands between you and it, shoulder to back. The slide stops on the two of you instead of crushing you alone into the wall, and you share the jolt.

**The rule, as the physics packet has it.**
- Your partner's heft adds to your footing once they're touching.
- **Against a wall,** the force left when the slide stops is a sudden stop, split between you by heft, so each of you takes less than one body alone would.
- The partner counts as at rest, so their own flight adds nothing.
- Each body's jolt is worked out in its own fight from the shared result, by Simulation's resolver, and latched once per contact.
- **On open ground** a free slide has no jolt, so the brace only shortens the trench. The picture is the wall case.

**Orb's question, narrowed:** against a wall, your partner takes part of a jolt that would otherwise all be yours. Does that count as friendly fire?

**Rulings to change:** Orb's friendly-fire rule, for contact against a wall, and "a sent body passes through other fighters", for bodies in contact. **Cost:** about 2M after the physics model's guard slide.

### 3.7 The Unison line (Game Design: is the pick still open?)

`modes.md` already writes "two players can fire the Unison line" into team-2v2. Tandem is the Protagonist's offer of help to the Anti-hero only, and Orb's pride kit now overlaps it. **The first question is Game Design's: is the pick still open?**

**If it's built:**
1. **A beam aimed across fights travels the shooter's own line first.** `SimCross.beamAt` *(new)* follows `fireAt`'s pattern, and the beam still stops at the first enemy on its line in the shooter's own fight. So the first-on-the-line rule and Cover your partner still work.
2. **The braid joins in the fight that holds the beam.** If that's your own fight, it joins at once. If not, it goes by a letter to that fight.
   - **Your price is taken only when the braid lands.**
   - If the letter finds no live beam, **you fire your own instead.**
   - The window reads the sender's fight clock.
3. **The struggle of three, on today's pulse model.**
   - Each pulse resolves when its window closes, for both sides.
   - Each pusher has their own claim and their own void, so a partner's press is never a stray that cancels the shooter's surge.
   - The team's landed surges are summed against the lone fighter's surge times **a fixed weight**, first value 1.6.
   - The partner's press reaches the struggle by a read across in fixed fight order, and the window allows for 0 or 1 tick of staleness.
   - While either fight is held, the pulse waits.
4. **Answers to a braid stay Game Design's rules, with no flat bans.** The swat is already measured against the beam's energy, so a braid's combined energy already makes a clean swat hard. Holding LB against a braid stays a block. Walking into the beam, knocking it back and punching up the beam are listed for Game Design.
   - **The carve is the larger beam's,** so the toll doesn't change, and it's drawn bigger.
   - **The braid's edge over two separate beams is the energy swat table,** plus one answer for the enemy. Game Design decides whether that's enough to pick it.

**Rulings to change:**
- "A beam struggle stays two fighters".
- `playable-build.md` §3's equal push.
- The swat, catch, walk-in and knock-back rows of `beam-answers-2.md`, as they apply to a braid.

**Legal first, near fusion.**

**Cost:** about 6.5M (Simulation 3.5 for `beamAt` and the struggle of three, Encounter 1.5, UI and QA 1.5).

### 3.8 The duet finisher (later: needs a fight of three)

A fight is always a pair, "one fight of three is Encounter's side" (`fight-swap.md`), and a finisher "stays between those two". A duet needs a fight of three, which would also change two-on-one and the rescue, so it should be its own design. It's not costed.

## 4. Netcode: team moments and rollback

**Already ruled** in `docs/net/rollback.md` §4: big one-shot events play when their tick is confirmed, or are keyed so a re-run doesn't play them twice.

**The gap: a moment that a re-run undoes or adds.**
1. **NetSession has to hand the host each re-run tick's events from every fight,** plus the restore point `s`, before it clears them. Today `NetSession._run` clears a re-run tick's events right after `SimCore.step`, and `onRollback` and `afterRestore` are for tests only. **This changes `net/session.gd`**, so it's Netcode's.
2. **The host's ledger drops only the moments the re-run covers:** those with a tick after `s`, in the sim's tick stamps. A moment held from before that was predicted right and still plays. The key includes the fight index.

```gdscript
# Host side, per PC; never in the sim.
var held := {}                                   # key (fight, tick, exchange n, beat, kind) -> cue
func on_cue(cue) -> void:
    if cue.big and cue.tick > session.confirmedFrontier():
        held[keyOf(cue)] = cue
    else:
        play(cue)
func after_rollback(s: int, rerun_cues: Array) -> void:   # (new hook from NetSession)
    for k in held.keys():
        if held[k].tick > s:
            held.erase(k)                         # only the ticks the re-run covered
    for c in rerun_cues:
        if c.big:
            held[keyOf(c)] = c
func each_frame() -> void:
    for k in held.keys():
        if held[k].tick <= session.confirmedFrontier():
            play(held[k])
            held.erase(k)
```

`rollback_check` should cover a big cue on the tick just before a snapshot boundary. **Cost:** about 1.5M (Netcode 1, Rendering 0.5). It helps 1v1's set pieces too.

## 5. Rulings Game Design (or Orb) would need to change

| For | Ruling | Asked |
| :--- | :--- | :--- |
| First match (A13) | A clock per body; a blow from outside holds its striker | Accept holds per fight for the first match, or build the body clock |
| 3.1 the arrival | "A press from outside another fight is a blow from outside" (`playable-build.md`); "no send, no knock-back" from outside | The long strike across fights, keeping its speed, its ×1.25 send and its whiff carry; or leave the arrival a plain blow from outside |
| 3.3 the tag | "Swapping: Just focus and flying. No special move"; the claw law | A tag both partners offer, with no button beyond focus, and claw-checked |
| 3.4 meeting | "Lands only on an opening"; "No send, no knock-back"; "no pass at first"; the pass "counts as a normal blow" | A once-a-flight redirect of a body your partner sent, with its stop capped |
| 3.5 the cradle | "A sent body passes through other fighters"; "No send, no knock-back"; "lands only on an opening"; **Orb's "no friendly fire on partners"** | Orb first |
| 3.6 the brace | **Orb's friendly-fire rule,** for contact against a wall | Orb first |
| 3.7 Unison | Whether the pick is still open; "A beam struggle stays two fighters"; `playable-build.md` §3's equal push; `beam-answers-2.md`'s swat, catch, walk-in and knock-back rows for a braid | Game Design first, then Legal |
| 3.8 duet | "A finisher stays between those two" | Only with a fight of three |

3.2 changes nothing: it's in the first-version column already.

## 6. QA's rows for co-op

| Row | First band |
| :--- | :--- |
| The call is heard and seen on the partner's PC (A2) | Every call |
| Humans against the computer answering a beam from the other fight (A3) | Within 15 points of each other |
| A pause of 60 s or more on a LAN (A5) | The match resumes |
| A 2v2 match's length (A6) | 8 to 12 minutes, cap 14:00 on one clock |
| Tags offered that complete, including with shots or mines live (3.3) | Above 50% |
| Meetings a match (3.4) | 1 to 4 |
| Braids against separate beams (3.7) | Both happen; neither over 80% |
| The lone fighter wins the match from two on one (ruled) | 10 to 20% |
| All four within 15,000 units (ruled) | 25 to 50% of a match |
| The civilian band, per fight and for both together (RL-249 (8)) | Reported as a trend to Legal, never a target |

## 7. Order, owners and token costs

At about 1M per session, including gates:

| Group | Pieces | Tokens |
| :--- | :--- | ---: |
| **Orb's first together try** | A1 1.5M, A2 1M, A3 1M, A5 0.5M, A6 1M, A7 0.5M | 5.5M |
| **Then** | A8 1.5M, A9 1M, A10 1M, A12 0.3M, A13 0.2M | 4M |
| **Drawing your partner's fight** | A11 3M, A4 1.5M | 4.5M |
| **First co-op match** | | **about 14M** |
| Team moves, near | 3.1 arrival (once Game Design rules) 1.5M, 3.2 relay 1M, section 4 ledger 1.5M | 4M |
| Team moves, later | 3.3 tag 3M, 3.4 meeting 3.5M, 3.5 cradle 2.5M, 3.6 brace 2M, the collision resolver 1.5M, 3.7 Unison 6.5M | 19M |
| **Team moves** | | **about 23M** |
| **All costed** | | **about 37M, roughly a third of a ~110M week** |

**Not costed here:**
- **The physics model's own build,** which 3.4 to 3.6 wait for. That's the physics packet's work, and it waits for Orb's go.
- **Flight strikes,** 5 to 7M in the controller plan. Not a prerequisite now that 3.1 is the long strike, but part of the same LT family.
- **The fight of three** (3.8).
- **The body clock,** about 2M, if A13 says build it.

**What this packet cost:** about 3.5M tokens. The first checker took 0.17M, the five-lens check 0.9M, the second check 0.4M, and my own reading and writing about 2M.

## 8. What only Orb, Game Design or Legal can decide

1. **Orb: does a body sent into its own partner (3.5), or a partner sharing a jolt against a wall (3.6), count as friendly fire?**
2. **Game Design: the arrival.** The long strike across fights, or a plain blow from outside?
3. **Game Design: is the Unison pick still open?** Then Legal, near fusion.
4. **Legal: each team move as its own row** (RL-249 (5)).
5. **Orb, then Legal: a second person on the other PC** (A12, RL-249 (10)).
6. **Orb: the go on the physics model,** which 3.4 to 3.6 wait for.
7. **Orb: the second palette's look** (A4) and the drawn effects' look (A11), each in the side-by-side.
8. **Orb: the firewall click and the first match between the two PCs** (homework "LAN - first match between your PCs").
