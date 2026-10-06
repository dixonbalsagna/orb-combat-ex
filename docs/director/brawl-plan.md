# The brawl: a build plan for the director

Owner: Encounter Systems Director. Date: 2026-10-04. Status: plan only, nothing built. Spec: `docs/design/melee-press-feel.md` (Game Design, 9a1624c). Also read: `docs/ep/stance-answers-2026-10-04.md`, `docs/controls/lunge-control.md`, `docs/combat/moveset-generator.md`, `docs/vfx/glare.md`.

Every number below is the spec's unless it says otherwise. Sizes and slice costs are estimates until a slice is measured.

## 1. What survives and what the brawl replaces

| Today's director | In the brawl plan |
| :--- | :--- |
| **`requestAttack` plans a whole exchange** in the close band (the template by attack against stance: trade blows, pressure, clean hit, dodge and read) | **Replaced** in the close band. A press is one blow on the presser's own line. The templates' close-band branches stop being planned once the brawl covers them |
| **The chain window and its links** (five blows, four link presses, the blur's free ender) | **Replaced.** A string is as long as the presses and is closed by a heavy |
| **The cooldown** after every exchange | **Gone inside a brawl.** Kept after a brawl ends in a launch, and at range. None after a knock-back |
| **The defender locked and watching** | **Replaced.** Both fighters have a line and both press |
| **Styles from the last five presses** (blur, combo, power) | **Replaced by the press's own kind:** a mash blow, a skill strike, a heavy. The window is still logged for the feed |
| **The blur's cadence of 7 to 10** | **Replaced** by the flurry's tap rate (6 to 12 ticks) and the 24-tick beat point |
| **The press log, the beat grade, the freeze rule** (`DirAlchemy`) | **Kept.** It is what tells a skill strike from a flurry blow. A beat is now the fighter's own beat point |
| **Flow** | **Kept.** +1 for a skill strike, 0 on a missed beat, the 90-tick lapse, flow 3 for a launch, the damage and contest bonuses |
| **Pieces and patterns** (`DirRecipe`, `DirBlur.piece`) | **Kept and extended:** every blow still draws its piece by a keyed draw, with the pattern, the broken-limb filter and no repeat in a string. The source becomes Combat's generated cells |
| **Launches** (`DirLaunch`: the planner, `knock`, `doLaunch`, the stick's aim) | **Kept.** The earners change (§2.5) |
| **Decisive wins, set-ups, the brink chapter, finishers and their contest** | **Kept.** The unit "a later exchange" becomes "a later string" |
| **Set pieces:** heavy clash, guard break, charge interrupt, crippling blows, Blow for Blow | **Kept as set pieces** the brawl hands over to and takes back from |
| **Beams, beam plays, blasts, mines, the buried fighter, the far band's taunt and charges, the roam** | **Unchanged.** A lunge or a charge that arrives starts a brawl |
| **The AI's stance re-pick on a timer** | **Replaced inside a brawl** by a choice at each of its beats (§3). Kept outside |

## 2. The brawl's state and loop

### 2.1 The container

A brawl is **one exchange of a new kind,** `brawl`, held in `S.dirS.ex` as exchanges are today. That keeps everything that asks "is an exchange running" working: damage attribution, the wounds' crippling moment, the finisher taking over, blasts that wait for a fighter to be up. It has no beat list of its own except for set pieces and the blows announced to the renderer (§2.7).

- **It starts** when the fighters are within 3 bh and either presses attack, or when a lunge or a charge arrives.
- **Each string takes a new exchange number.** The keyed draws and the brink chapter's "a later exchange" then keep their meaning inside one long brawl.
- Both fighters are held by the director, as in an exchange today. Magnetism and footwork are the director's moves (§2.6), so the first slice needs no new fighter state in the core.

### 2.2 Two strike lines

Each fighter has a line: at most one blow in progress and one held press. Nothing is queued, so the state has a fixed size.

| Per fighter (integers) | Meaning |
| :--- | :--- |
| Line state | idle, winding up, landing, recovering, reeling, guarding, staggered, lifted |
| Blow kind, start tick, contact tick, end tick | The blow on his line |
| Held press and its tick | The latest press he could not throw at once; it lives 10 ticks |
| Tap gap | The time between his last two taps, held to 6 to 12 ticks: the flurry's speed and its damage scale |
| Beat point | The tick of his next beat (24 ticks after his last light or skill strike landed, 20 to 28 by the piece) |
| String count, flurry run, reply count | Landed blows of his string; flurry blows landed in a row; blows landed on him in reply |
| Charge | Ticks his heavy has been held |
| Reel, stagger and lift ticks; juggle count | When each ends; skill strikes landed on a lifted rival (three at most) |
| Guard up since, guard down since, guard broken until | For the set guard (30 ticks), the perfect block's 20 ticks down, the 40-tick break |
| Clean blows taken in his wind-up | Three stop his heavy |
| Pattern, step, used pieces | As the blur holds them today |

| Shared (integers) | Meaning |
| :--- | :--- |
| Brawl on, its start tick, its string number | |
| Last attack tick | 60 ticks with no attack from either breaks it |
| Magnet state and its tick | holding, sliding after a knock-back, the 30-tick re-close window |
| Last struggle tick | One struggle in 20 s |

**Size in hashed state:** about 26 integers a fighter and 8 shared, near 60 in all (240 bytes). No list grows with the brawl's length. The per-fighter integers go in the director's block of the fighter's state, as the alchemy's do. The shared ones need a home (§5, Simulation).

### 2.3 The loop, once a live tick

1. **Read the presses.** For each fighter, his new attack press this tick:

| The press | Becomes |
| :--- | :--- |
| A light, the first of a string | A light: contact within 2 ticks |
| A light within 4 ticks of his beat point | A skill strike: contact in 6 ticks, ×1.25, reels the rival 8 ticks, flow +1 |
| A light before that window | A flurry blow at once, at his tap gap; the flow goes to 0 |
| A light after it | A fresh light; the beat starts again |
| A heavy tapped | 26 ticks of wind-up and 8 to land |
| A heavy held | Charges to 46 ticks; contact 8 ticks after the release |
| Any of these while his line is busy or he reels | Held for up to 10 ticks, the latest only, and thrown as the line frees |
| Taps faster than blows can be thrown | Not queued: they set the tap gap |
| A press while knocked back, launched or lifted | Not a strike |

2. **Advance each line.** A blow that reaches its contact tick is resolved against the rival's state:

| The rival is | A light, flurry blow or skill strike | A heavy |
| :--- | :--- | :--- |
| Open | Lands. He reels 4 ticks (8 for a skill strike) | Lone: lifts him for 30 ticks (45 fully charged). After two or more landed blows of the string: the ender (§2.5) |
| Guarding | Chips | Breaks the guard for 40 ticks and staggers him 12, if the guard is set or was not down 20 ticks first |
| Perfect-blocking | Ends the attacker's string, staggers him, gives the riposte | The same, when the guard was down 20 ticks first |
| Lifted | A skill strike on the beat re-lifts him, three at most; anything else drops him | The juggle's ender |

3. **Settle the meetings** (the spec's §7): blows more than 2 ticks apart both land in order; a skill strike voids a flurry blow inside 2 ticks; like kinds trade; three clean blows stop a wind-up; two tapped heavies inside 2 ticks both land and both stagger; two heavy commitments inside 6 ticks go to §2.8.
4. **Close what closes** (§2.5), move the fighters (§2.6), and check what breaks the brawl.

Hit-stop is 2 ticks for a flurry blow, 4 for a skill strike and 6 for a heavy, for both fighters. The director already passes a blow's hit-stop with its damage.

### 2.4 Guard, parry and push

- **Guard** in the first slices is today's held guard: it chips, a blocker is never knocked back by a blow, and a perfect block is unchanged.
- **Check, parry, push and the step strike** need the stance mask (defensive A and X, manoeuvre X). They come with the stance slice (§4, B6), each as one more row in the tables above.

### 2.5 Strings, enders, the juggle

| Thing | How the director recognises it |
| :--- | :--- |
| **A string** | His landed blows in a row. It ends when he is staggered, perfect-blocked, lifted or knocked back, when his ender lands, or after 30 ticks with no blow of his landing |
| **The flurry's close** | Four flurry blows landed in a row with nothing landed in reply: his next blow staggers the rival 12 ticks. Decisive, at half a set-up. The brawl stays together |
| **The ender** | A heavy that lands after two or more landed blows of his string. It knocks back. It launches when his flow is 3 or more, or it was held to a full charge, or it ends a juggle of three; the stick aims it. A blocker is not moved |
| **The lift** | A lone heavy landing clean. The rival hangs in place, still in the brawl |
| **The juggle** | While he hangs, each skill strike on the beat re-lifts him for one more beat, three at most. An early or late press drops him. His way out is a burst |

### 2.6 Magnetism

- On inside 3 bh; off beyond 4.5 bh.
- Recoil leans a fighter and does not move him. Drift is pulled back toward striking distance at up to 0.5 bh a second. Walking with the stick is damped to 0.4.
- **Breaks:** a launch, a dodge with the stick away, a boost away, 60 ticks with no attack from either.
- **Bends:** a knock-back lets go for the slide. If either fighter holds toward or presses attack within 30 ticks of its end, both are drawn back by a lunge of 12 to 20 ticks and the brawl goes on with no cooldown.
- A sidestep, a guard, a stagger and a lift do not break it.

### 2.7 What each blow tells Animation and VFX

Each blow is announced as one beat when its wind-up starts, with its contact tick, and carries: `style` (speed, tech, heavy), `grade`, `k` and `n` (its place in the string and the string's length so far), `closing`, `charge`, `hand`, `ender`, and the piece. Today's `strike` and `chainStrike` beats get the same fields first (slice B0), so the renderers can be built before the brawl.

**One conflict to settle:** a speed blow from idle lands within 2 ticks of the press, and Animation asks for 3 ticks of notice. Inside a running flurry the next blow is known a whole tap gap ahead; only the first blow from idle is short. Either its contact is 3 ticks, or Animation takes 2.

### 2.8 The struggle trigger

Two heavy commitments (a held heavy or an ender each) landing within 6 ticks. If a struggle is allowed (one in 20 s), the brawl hands over to the fist clash on the pulse and takes the winner's result back as a clash won. If not, both slide back half the distance at half the damage. Two full charges released on the flash are Blow for Blow. Lights, flurry blows and skill strikes never start one.

The fist clash on the pulse is a set piece that does not exist yet. Until it does (B4), every such meeting is the double slide.

## 3. The AI inside a brawl

The AI writes the same intent record as a player: a press on the tick it means, a held guard, a dodge tap, the stick. Its timing is then read by the same log and grade. The draw that marks an AI press "timed" today goes.

| Commitment (the spec's §2b) | How |
| :--- | :--- |
| **It chooses at its beats,** not on a timer | When its blow, its guard or its reel ends, one weighted pick: attack, guard, sidestep, leave |
| **Once it attacks, it stays a whole string** | No leave or guard pick until its string ends |
| **A guard lasts 20 to 60 ticks,** then it must attack, parry or push | A drawn length; until the stance slice, "attack" is the only follow-up |
| **Leaving is a slip,** one in a row and three a minute at most | Counted in its state |
| **No circle and no bob** | They do not run in a brawl; footwork in place is the renderer's |
| **At range,** guard for no more than 45 ticks unless a shot or a charge is coming | Then it closes, fires or taunts |

**What a level sets** (`ai.json`, per level): its tap gap in a flurry; the share of its lights it places on the beat (today's `timedPress`); how often it throws a heavy, holds it, and closes a string with it; the share of a brawl it guards (the spec's first lever for the masher); how often it mashes into a rival's heavy wind-up; how many juggle strikes it tries; its burst out of a lift.

## 4. Slices

Each slice is built in scratch, measured, gated, applied and reported by itself. **Rows every slice holds:** the masher against the medium AI 35 to 50%; timed against plain 62 to 82%; bolt-only 20 to 40%; blasts' share 10 to 25%; match median to 480 s. **Goldens:** from B1 on every slice changes how AI matches play, so the goldens are regenerated each time.

| Slice | What Orb can feel | New rows it must meet | Goldens |
| :--- | :--- | :--- | :--- |
| **B0. Groundwork** (no change in play except the lunge) | The mid lunge winds up for 6 ticks (light) or 10 (heavy) with a cue at its start | A probe for "nothing running" a minute and press-to-contact, so later slices have a before. Folded in: the struggle's stray press at −0.10; the beat fields on today's strikes; the cooldown and the AI's weights moved from code to data | Regenerated: the lunge changes timing, the data hash changes |
| **B1. The first brawl,** martial stance, today's light and heavy | Every light is a blow at once, for both fighters; no cooldown; they stay together; faster taps are a faster flurry; the flurry's stagger; a heavy after two landed blows knocks back | Presses that become a blow within 10 ticks: at least 95%. Mash press to contact 2 ticks, 95% inside 4. Flurry blows a second within 10% of taps a second from 5 to 10. A flurry's damage a second within 10% across tap rates. Nothing running: toward 12 s a minute. A brawl's median length: toward 6 to 12 s | Regenerated |
| **B2. Skill strikes** | A light on the beat is a clean skill strike; a miss lapses into the flurry | Skill press to contact 6 ticks, 95% inside 8. Timed against plain 62 to 82% on the brawl's rules | Regenerated |
| **B3. The heavy** | It breaks a set guard; three clean blows stop its wind-up; a lone heavy lifts; the juggle of three; the ender launches at flow 3, at full charge or after a juggle | A heavy on a set guard breaks it at least 95%. A blocker knocked back by a blow: never. Skill hits a juggle: a mean of 1.5 to 2.5. Juggles ended by a burst: 20 to 40% | Regenerated |
| **B4. Heavy meets heavy** | The fist clash on the pulse; Blow for Blow; the double slide when a struggle is not allowed | One struggle in 20 s; a brawl of lights never stops for one | Regenerated |
| **B5. The AI and the bands** | The AI brawls by its level and holds the spec's commitments, in a brawl and at range | Nothing running: at most 12 s a minute, at most 6 in the close band. Share of fight time in a brawl 45 to 60%. A brawl's median 6 to 12 s, 10 blows or more | Regenerated |
| **B6. The stances** (after Controls' mask, intent version 4) | Check, parry, push, the step strike; each press plays a move of its cell | The rows the spec's §10 to §13 give | Regenerated, with Simulation's for the intent |
| **S. The splitting shot** (when `SimShots.split` exists; independent of the brawl) | The rival's second press splits his shot | Bolt-only, the mixed blaster, blasts' share | Regenerated |

**Why B1 is this size.** It is the smallest thing that removes what Orb named: the cooldown, the waiting defender and the drift apart. It needs only the light and the heavy, the two lines, magnetism and the simplest AI (attack a string, guard 20 to 60 ticks, attack again). The AI's fuller play is B5, but each slice re-tunes what it must to hold the masher's band.

**The glare cues** (`docs/vfx/glare.md`): `chin_plant` is sent with On the Chin's entry beat, in whichever slice stages it; `pride_threshold` and `seal_break` are a meter's and a seal's events, and need an owner (§5).

## 5. What the plan needs from others

| Who | What |
| :--- | :--- |
| **Simulation** | A home for the brawl's shared integers in the director's state (hashed). The fighter's step leaving a brawling fighter to the director, as it does a locked one. Later: `SimShots.split` with children that carry a group and their own kind or a flag; the stance in the intent |
| **Controls** | The stance mask (intent version 4) before B6. Confirmation that a press held through a hit-stop is graded as the hit-stop fix leaves it, since blows now land up to ten a second. The lunge's wind-up shown to the defender |
| **Combat** | The martial stance's cells for the light and the heavy first (12 to 14 lights, 12 heavies), each piece with its beat point (20 to 28 ticks) and its forms' numbers; the lift, ender and guard-break pieces; the struggle's stray press value, which is its file. On the Chin's entry beat for `chin_plant` |
| **Animation and VFX** | The beat fields in §2.7 read from the new blow beat as from a strike; the answer on 2 or 3 ticks of notice for a speed blow; the lift's hang, the set guard, the stagger in place, the lunge's crouch |
| **Game Design** | The Orb questions in the spec's §14 that change the build: the lone heavy lifting in place of launching, and the string of two before an ender |
| **Tools** | Schemas for the brawl's data block, the AI's brawl keys and the moved constants; a check that every cell the brawl draws from has enough pieces with one limb broken |
| **QA** | Scripts that brawl: a tapper at 5 to 10 taps a second, a beat player with an accuracy, a guard-sitter, a heavy-only player, a juggler; the rows for nothing running, brawl length, press to contact; its masher and timed scripts re-read against the brawl |
| **An owner for two cues** | `pride_threshold` and `seal_break`: whoever holds his Pride and the seal sends them, or tells the director where to read them |

## 6. Risks

| Risk | Why | What holds it |
| :--- | :--- | :--- |
| **Match length falls under its band** | A brawl deals damage without the cooldown's pauses; ten blows a second where there were two or three | The flurry's damage scale keeps damage a second flat across tap rates. If the median still drops, the wear rate is Simulation's and QA's to re-tune, slice by slice |
| **The masher leaves his band** | With a shorter cooldown and an AI that stayed in, he rose to 63 of 100 | A mashed blow is weaker the faster it is thrown; the AI guards, and from B3 a heavy stops him. The first lever is the share of a brawl the medium AI guards. Measured in every slice |
| **Blasts fall under 10%** | Melee does more of a match's damage | The AI's firing share, one step at a time |
| **Timed against plain cannot be read** until B2 | B1 has no skill strike | B1 reports the row as it stands and does not tune to it |
| **Hit-stop eats the brawl** | 2 to 6 frozen ticks a blow at ten blows a second is a large share of real time, and inputs are not read in a freeze | Press-to-contact is measured in real ticks as well as live ones in B1; the numbers go back to Game Design if a press waits on freezes |
| **Systems that assume an attacker and a defender** | The brink chapter, the plan check, the loser of an exchange, staleness | Each string takes its own exchange number and its own attacker; the plan check is retired for the brawl kind with Simulation |
| **The AI's presses become real presses** | Its timing is no longer a draw | Its on-beat share is set by when it presses; the rows for its levels are re-measured in B5 |
| **Goldens churn** | Every slice from B1 changes AI matches | One regeneration a slice, each gated on a clean copy as now |
| **The exchange templates left behind** | Close-band branches go unused as slices land | They stay as data until B5, then Combat retires them |

## 7. The zip slice (Z)

Orb approved the zip prototype (`docs/ep/prototypes/lt-zip-v4.html`) and said to start building it. Rules: `docs/design/melee-press-feel.md` §2c, "The zip". Camera: `docs/camera/lunge-framing.md` §8 and §9. This section is a plan; nothing is built.

### 7.1 Can it come before B1, and on which intent?

**Before B1: yes. On today's intent: no (the EP's ruling, from Controls' `lunge-control.md` B6).** The zip needs intent version 4: the stance mask's LT bit, `contextHeld` and a new `sigHeld`. So the order after B0 is Controls' version 4, World's staged destruction, Simulation's dynamic intros, then Z.

| Zip | What it reads | State |
| :--- | :--- | :--- |
| **LT + X, the zip strike** | The mask's LT bit, `light`, `lightHeld` for the held reading, the latched stick | With version 4 |
| **LT + Y, the zip heavy** | The same with `heavy` and `heavyHeld` | With version 4 |
| **LT + B, the signature zip** | `sig` and `sigHeld`. B is the beam until a stance's own signature is authored | With version 4 and the signatures (the spec's §11) |
| **LT + A held, the zip tackle** | `contextHeld`. The tackle is not in the sim today, so there is nothing to reuse | With version 4 and the tackle itself |

- **It does not depend on the brawl.** A zip is an approach, one blow and an exit. Where the spec says "a brawl starts" (he is caught or countered), Z starts today's exchange with the defender as its attacker; B1 later points that at the brawl.
- **The dodge that becomes a zip** (Controls): an LT press is a dodge at once. When a face press follows within 8 ticks and he was not threatened, the director turns it into the zip: the dodge's move is cut and the tell starts from where he is. It reads the mask's LT bit, `act.dodgeTick` and the threatened flag. This is Z's to build.

### 7.2 What it reuses

| From today | Used for |
| :--- | :--- |
| `DirBands.begin` and its wind-up (B0) | The tell: 6 ticks for a strike, 10 for a heavy, then the way in. The arrival point is fixed at the tell, on his own side |
| The `rush` event and the start cue (B0, `_startCue`) | The tell's announcement |
| A point rush (the rush already has a point form) | The way out: back to where he started, to the rival's far side, or to the exit point the stick names |
| The blast rules against a charge (`DirBlast.hit`) | On the way in any shot stops a zip strike; a zip heavy shrugs off bolts but not a charged shot |
| The press log and its grade | The reading (tapped, timed, held) and the defender's counter timing |
| `DirLaunch.knock`, `decisive` | The held zip heavy's knock-back, and the heavy counter's |

New: the zip itself, a small director module (`sim/director/zip.gd`), which holds the phases and resolves the one blow. It is not an exchange with a beat list.

### 7.3 The phases and their outcomes

Phases, in ticks from the table in the spec: the tell; the way in; in reach before the blow; the blow; in reach after it; the way out.

| What happens | When | Outcome |
| :--- | :--- | :--- |
| **A shot meets him** | On the way in | A zip strike is stopped; a zip heavy shrugs off a bolt and is stopped by a charged shot. The ki stays spent |
| **Outrun** | The rival has left the mid band by the end of the longest way in | It ends short. No blow |
| **Countered by a tech strike** | The defender's tech press from 4 ticks before the arrival until the blow lands | The zip's blow is cancelled. He staggers 12 ticks in reach, and an exchange starts with the defender attacking. The counter is a skill strike |
| **Countered by a heavy** | The defender's heavy lands (its wind-up ends or its hold is let go) from 6 ticks before the arrival until the blow lands | The blow is cancelled. The heavy lands in full and knocks him back: decisive |
| **Blocked** | The defender holds guard against a zip strike | It chips. A perfect block on a fresh press staggers him in reach |
| **Dodged** | A dodge on the arrival, 15 ki | It misses |
| **Lands** | Otherwise | The blow in its reading: a light at ×1.0 (reel 4), timed ×1.25 (reel 8, flow +1), held ×1.25 (reel 12); a heavy at ×1.0 (stagger 12, a set guard breaks, no lift), timed ×1.25 (stagger 20, flow +1), held ×1.25 and a knock-back |
| **Caught** | Any blow of the defender's lands on him while he is in reach (6 ticks after a zip strike, 10 after a zip heavy). He has no guard there | The way out is lost. An exchange starts with the defender attacking |
| **Out** | After the in-reach ticks | The exit point by the stick (below). No strike reaches him on the way out; a shot that hits him there knocks him down |

**Hard rules:** the price is paid at the press and never returned; a zip never starts an exchange unless he is caught or countered; it is not decisive apart from a knock-back; it never starts a struggle. No zip starts while he reels, is staggered, lifted, launched, guard-broken, exhausted or in the middle of a blow.

**Where a zip ends** (Game Design, the spec's §2c):

| Part | Rule | In the director |
| :--- | :--- | :--- |
| **The stick** | Controls' aim latch, read on the tick his blow lands: 16 sectors of 22.5 degrees, a 0.35 dead zone, held 3 of the last 12 ticks | `SimAim`, which the alchemy log already feeds each tick |
| **No stick** | Back to his start point | A point rush to the start point |
| **The bearing** | The stick's own direction from the rival: up is above him, down below, any angle | The sector's centre |
| **The distance** | His start distance plus 6 bh × (1 − the angle between the stick and straight away, over 90 degrees); never less than the start distance, never more than 12.5 bh. Straight toward is the far side at the start distance | Computed with the shortest-arc wrap |
| **The way out** | 10 ticks (12 for a zip heavy), plus 1 for each 2 bh of path beyond 8 bh, 20 at most | The point rush's length |
| **An exit point inside ground or a building** | It slides round the circle in 15 degree steps toward his start bearing, to the first point clear by 1 bh; else his start point. Water is no obstacle | World's ground and structure reads at each step: at most 24 probes, once a zip |

**Is 16 sectors too coarse?** For the bearing, no: a stick cannot be aimed finer in the ticks a zip gives. For the distance it needs two tolerances written down. The line to the rival is at any angle and the sectors are fixed to the screen, so the stick is up to 11.25 degrees off what the player meant: the distance is then up to 0.75 bh off, which is fine. But "straight toward" and "straight away" would almost never be exact. So: toward is the sector nearest the line to the rival (the far side at the start distance), and the zip away's "within 45 degrees of straight away" is read on the sector's centre with half a sector of grace (56.25 degrees). The obstacle rule's 15 degree steps are finer than the input, which is harmless.

**The zip away** (from inside the close band, the stick within 45 degrees of straight away): 20 or 30 ki; a tell of 10 or 14 ticks in reach; the blow always thrown 4 or 12 ticks later; 6 or 10 ticks more in reach; the exit 3 to 6 bh further out; then 8 ticks where he can move but not attack, guard or zip. A tech or heavy strike from the start of the tell until his blow lands counters it, and any hit in reach cancels the exit. A second one inside 5 s costs 10 ki more. It breaks magnetism, so in B1 it is one of the ways out of a brawl, and for the AI it counts as a slip.

### 7.4 The cues

| Cue | When | Fields |
| :--- | :--- | :--- |
| `zip_light`, `zip_heavy` | The tell starts | As B0's start cue: `actor`, `target`, `text` the kind (`zip`), `amount` the tell's ticks, `n` the way in; and `dur` the whole zip's ticks for the default exit |
| `zip_out` | His blow lands (the exit is read there) | `text` the exit (`back`, `far`, `point`, or `away` for the zip away), `x` and `y` the exit point after the obstacle rule, `n` the ticks of the way out |
| `zip_end` | He is at the exit point, or the zip ended early | `text` why: `home`, `far`, `point`, `stopped`, `outrun`, `countered`, `caught`. This is Camera's return marker |

**One conflict for Camera.** Camera wants the exit side at the tell. Game Design reads the stick on the tick the blow lands. So the tell can only promise the default, and `zip_out` gives the real exit point 10 to 20 ticks before he gets there.

### 7.5 The AI

| | Easy | Medium | Hard |
| :--- | :--- | :--- | :--- |
| **Uses a zip** (in the mid band, with the ki, on an attack beat) | Rarely | Sometimes, more against a rival who guards at range or channels | Often, and picks the timed reading at its timed share |
| **Its exit** | Back | Back; the far side against a cornered-looking guard | Any |
| **Answers one** (one draw at its reaction time, as for a lunge today) | Guards a zip strike | Guards, or dodges on the arrival; counters at a low rate | Counters with a timed press or a held heavy at its level's rate; fires during the tell |
| **Punishes him in reach** | Seldom | At its punish rate | Nearly always |

Per level in `ai.json`: `zipShare`, `zipHeavyShare`, `zipCounter`, `zipDodge`, and its punish rate reused for "caught". It writes real presses with LT held, as a player does.

### 7.6 Hashed state

Per fighter, about 12 integers: the phase and its ticks left; the kind and the reading; the price paid; the start point and the exit point (as fixed-point integers); the rapid-zip count; the tick of his last zip away; the defender's counter mark; the 8 ticks after a zip away. Nothing shared.

### 7.7 What Z must hold, and its new rows

- **Kept:** the masher 35 to 50%, timed against plain 62 to 82%, bolt-only 20 to 40%, blasts' share 10 to 25%, match median to 480 s.
- **New (the spec's):** a zip's cost and its ticks in reach exactly the table (a hard test); zip strikes that land clean against an opponent who answers 35 to 55%; zips countered 10 to 25%; zips that end with the zipper caught 20 to 35%; ki spent on zips at most 25% of all ki spent; a zip that starts an exchange without a catch or a counter: never (a hard test).
- **Also reported:** zips a minute and ki a minute by level; what the AI's zips do to the masher, who never zips.
- **Goldens:** regenerated; AI matches change as soon as the AI zips.

### 7.8 What Z needs from others

| Who | What |
| :--- | :--- |
| **Game Design** | The two stick tolerances in §7.3 (toward, and the zip away's 45 degrees). What "the rival's own blow" is for the timed reading when no exchange is running: today only his arriving lunge or charge has a known contact. Whether an empty bar's 2 s of exhaustion exists yet: nothing in the sim is named for it |
| **Controls** | Intent version 4 first: the mask's LT bit, `contextHeld`, `sigHeld`; the latched stick read at the contact tick; the threatened flag for the dodge that becomes a zip |
| **Simulation** | To confirm: the point rush can carry the way out, and no strike reaches a fighter on it. A knock-down from a shot on the way out. The tackle, when the zip tackle is wanted |
| **World** | A read that says whether a point is inside ground or a building with 1 bh to spare, for the exit's obstacle rule (it may exist already) |
| **Animation** | The zip in and out, the strike in its three readings from a zip, the stagger in reach, the caught and countered reactions |
| **VFX** | The streak both ways, the engage ring, the counter's flash |
| **Camera** | The cue fields in §7.4; `zip_end` is its return marker |
| **Tools** | The schema for a `zip` block in `interrupts.json` (the table's ticks and prices, the multipliers, the counter windows) and the AI's four keys |
| **QA** | A zipper script (each reading, each exit), a counter script (timed tech, held heavy), a puncher who hits him in reach; the rows in §7.7 |

### 7.9 Order

Z1: the zip strike and the zip heavy with the three readings, the exit rule, the counters, caught, the dodge that becomes a zip, the AI, the cues. Z2: the zip away. Later, with their inputs: the zip tackle (`contextHeld`, the tackle) and the signature zip (the stance signatures). B1 follows Z1 unchanged, except that a caught or countered zipper then starts a brawl.

### 7.10 Review after B1c (2026-10-05)

This section was written before the brawl existed. The brawl is in (B1, B1b, B1c), the rulings it waited for are made, and the pieces it asked others for are built. Where this subsection and 7.1 to 7.9 disagree, this one holds. Nothing of the zip is built yet.

**What is ruled now** (`docs/design/melee-press-feel.md` section 2c):

| Point | Ruling | Data |
| :--- | :--- | :--- |
| **The stick** | Read in 16 directions, 22.5 degrees apart. Under the layout's dead zone it is no stick | `zip.exitSteps` 16 |
| **Toward and away** | Within 45 degrees of straight toward the rival, and within 45 degrees of straight away. This replaces the two tolerances 7.3 asked for | `zip.towardDeg` 45, `zip.awayDeg` 45 |
| **A shot on the way out** | A drop and nothing more. The shot does its own damage. He falls where he was hit and is out of control for 24 ticks, and he can tech out of it. No landing damage, no wear, not a launch, not decisive | `zip.knockdownTicks` 24 |
| **Caught or countered** | A brawl starts on the tick of the blow that caught him, with the defender as its starter and no planned exchange between. A tech counter leaves him staggered in it. A heavy counter knocks him back, so there is no brawl | |
| **The far-side exit** | It goes over or round the rival, with the rival in view. He is never simply behind the rival on the tick the strike lands | |
| **Travel** | Each way takes at least max(4, the distance in bh over 3, rounded up) ticks, and the body is drawn on every one (Legal RL-076) | |

**What is built for it, and where:**

| From | Piece | Use |
| :--- | :--- | :--- |
| **Simulation** (`docs/architecture/zip-core.md`, 3bd86be) | `Rush.arc`: how far the path bows off the straight line at its middle, signed by the direction of travel. `SimFighter.rushAt(S, f, u)` and `rushU(S, f)` | The way out. A far-side exit bows over the rival. `rushAt` samples the path for the obstacle rule |
| | `SimFighter.drop(S, f, ticks, vx, vy)` and `dropEnd(S, f, how)`; the state `dropped`; events `drop_start`, `drop_land`, `drop_end` | The knock-down by a shot on the way out |
| **World** (`docs/world/point-clear.md`, 873d270) | `WorldStructures.blockedAt(S, x, y, z, margin)` | The exit point's obstacle rule (24 probes at most), and the samples along the way out |
| **Controls** | Intent version 4: the mask's LT bit, `contextHeld`, `sigHeld`, the latched stick | As 7.1 |
| **This director** (B1, B1c) | The brawl; a stagger in place; a blow that can't be blocked or dodged (`sure`) | Caught and countered start a brawl. The tech counter's stagger is the brawl's own |

**The contract with Animation** (`docs/animation/zip.md` sections 9 and 12). The read is the truth and the cues are edges. This replaces the cue table in 7.4.

- **`DirZip.read(S, f)`** is empty when `f` isn't zipping. Otherwise it gives: `reading` (speed, tech, heavy), `btn` (x, y), `phase` (tell, in, reach, out, settle), `n` (the live ticks since the phase began) and `len`; the plan `tell`, `in`, `hits`, `hd`, `out`, `lift`; `blow`; `via` (back or run), `pass` (over, round or empty), `entry_in`, `entry_out`; `dist_bh`; and `exit` (home, far, point, away; empty until the blow lands) with `x`, `y` from then.
- `hits` is 1 in Z1 and `hd` is the ticks in reach. `settle` exists only for the zip away's 8 ticks.
- `pass` is `over` when the way out bows over the rival, which is a real bow in the sim. It is `round` when he passes the rival at his height: the sim's path is straight there and the depth of the pass is the body's.
- **`zip_light`, `zip_heavy`:** the tell starts. `amount` the tell's ticks, `n` the way in, `dur` the whole zip with the default exit.
- **`zip_out`:** on the tick the blow lands, which is 6 or 10 ticks before the out begins. `text` the exit kind, `x` and `y` the exit point, `n` the out's ticks.
- **`zip_end`:** on every zip, because it is Camera's return marker. `text` is `done` for a zip that reached its exit. The early ends are `stopped`, `outrun`, `countered`, `caught`, `shot` (a shot stopped a zip strike on the way in) and `down` (the drop on the way out). It is sent on the damage event's tick or before it.
- The out begins only after the ticks in reach that follow the blow, so no strike tick falls under the way out (Legal).

**What changes in 7.1 to 7.9:**
- 7.1 and 7.3: "an exchange starts with the defender attacking" is now "a brawl starts with the defender as its starter".
- 7.2: the way out is a point rush with `Rush.arc` where it has to clear the rival or the ground. The straight point rush stays for the exit back to his start.
- 7.3: the knock-down is `SimFighter.drop` for `zip.knockdownTicks`. It is not a launch.
- 7.6: the zip's integers go after the brawl's, which now end at `DirBrawl.END` (37 a fighter).
- 7.7: the kept bands are the ones in force after section 9f: the masher 35 to 50%, the mixing presser's brawls, bolt-only 20 to 40%, the mixed blaster 30 to 50%, the medians 360 to 480 s. New for the zip: the AI's share of fight time in a brawl at 30% or more.
- 7.8: Simulation's, World's and Animation's rows are answered above. Still open: Tools' schema for the `zip` block and the AI's four keys; QA's zipper, counter and puncher scripts; VFX's streak and ring; Camera's use of `zip_end`.
- 7.9: the order stands. Z1 is the zip strike and the zip heavy; Z2 the zip away, which is also the AI's way out of a brawl it is losing (the last brawl slice).

### 7.11 Z1 as built (2026-10-05)

Z1 is built: `zip-z1.md` has the rules, the cues, the read and the rows. Where the build departs from 7.1 to 7.10:

- **It is an exchange in reach after all.** 7.2 said the zip is "not an exchange with a beat list". The tell and the way in run with no exchange, but the ticks in reach run on the brawl's lines with no brawl announced (`DirBrawl.beginQuiet`). That gave the guard, the perfect block and its riposte, the catch, the damage and the strike beat Animation reads for nothing, and a caught or countered zipper is already in the brawl that starts.
- **The outrun** is measured from where the zip began: the rival more than 12.5 bh from that point before the arrival. The rush itself always arrives.
- **The bow** is `zip.bowBh` at the middle of the way out, and a way out passes the rival when its straight line comes within 1.5 bh of him at any angle.
- **The rival's answers are pressed where he stands** and kept for the arrival. The heavy counter is timed by the end of its wind-up. A heavy held and let go on the arrival isn't modelled before he arrives.
- **The AI has six keys a level,** not four: `zipPunish` and `zipExit` were added. It doesn't zip at a rival who is pressing.
- **Medium's `brawl.rashHeavy`** went from 0.33 to 0.3, for the masher's band on Simulation's retune (07f5652).
- **The order from here** is the second pass's (`docs/design/brawl-second-pass.md` section 10, after Orb's play notes): C1, control and the even mash (section 9 below); C2; Orb plays; C3, which is the skill strike as cut in section 8; C5; C4a and C6a; C4b; then Z2 (the zip away, the AI leaving a brawl it is losing, the chase of a launch, the rushed zip heavy, the signature zip, piloted charges) and H1.

## 8. B2, the skill strike: the cut (2026-10-05)

Spec: `docs/design/melee-press-feel.md` section 4, and the four deliverables in section 9d. Nothing here is built.

**On hold** (the EP, after Orb's play notes). It is C3 in the second pass's order, after C1 and C2 and after Orb has played them, and it is widened there to Y on the beat (`docs/design/brawl-second-pass.md` section 9). The cut below is as the EP accepted it, with Game Design's and Controls' rulings. Three things in it are stale and are re-cut with C3: "a heavy after two landed blows is the ender" is withdrawn, so "an ender at flow 3 launches" needs a new home; the banded row's masher is the X masher of the second pass; and the tapped Y is a quick heavy by then.

### 8.1 What B2 includes

| Thing | Rule | Number (data, the `brawl` block) |
| :--- | :--- | :--- |
| **The beat point** | Every light or skill strike of his that lands sets it: 24 ticks after contact, on `S.tick`, as his taps are counted. A reel doesn't move it. Every piece is 24 until Combat's rows carry their own | `skill.beatTicks` |
| **On the beat** | A press within 4 ticks of it, either side, inclusive. The grade is taken at the press's own tick (`S.tick` less `waited`), so a press in the window is on the beat even when a reel holds the blow. The window is Controls': 5 on touch, doubled by the accessibility factor, and its centre moves by the player's device offset | Controls' `read.beatHalf`, `touchBeatHalf` |
| **Perfect and good** | Perfect is within 2 ticks of the beat point, good is at 3 to 4. Perfect counts toward the perfect streak. The damage is the same | Controls' `read.blurBeatHalf` |
| **The skill strike** | Contact 6 ticks after the press. Worth 4 brawl lights. It reels the rival 8 ticks, clears his run and adds 1 to the flow. Hit-stop 4 | `skill.contactTicks`, `skillMul` (existing), `skill.reelTicks`, `skill.flow`, `hitstop.skill` |
| **A shared beat** | A skill strike and a flurry blow that land within 2 ticks: the skill strike wins and the flurry blow is voided | `tradeTicks` (existing) |
| **Early** | A press between his contact and the window is a flurry blow at once, and a missed beat: the flow goes to 0. So a masher never holds flow | |
| **Late** | A press after the window is a plain light. It adds 1 to his run, doesn't clear the rival's and doesn't touch the flow. The rhythm starts from it | |
| **The flow** | Earned and lost in a brawl from here. It is lost by an early press, or by 90 ticks with no press. Letting a beat pass is not a miss. An ender at flow 3 launches | The flow's own data |
| **Skill strikes that exist in worth already** | The riposte's light, the zip's tech counter and the zip strike become skill strikes in kind: the 8-tick reel, the 4-tick hit-stop, the tech look | |
| **The AI** | It puts a share of its lights on the beat. That share is the first lever for the masher's band, ahead of the tap gap and the reversals | Each level's `timedPress`, starting at 0.15, 0.45 and 0.8 |

Not in B2: the juggle and the lift (B3); the set light, the parry and the stuff (the stances); the section 9c answers.

### 8.2 Cues, fields and reads

- The `blow` cue gains the text `skill`. Its strike beat carries `bk` 3, `style` `tech`, `grade` `perfect` or `good` (Controls' split), and `beat`: the ticks from its contact to its beat point.
- A new cue `beat`, sent as a light or a skill strike lands: `actor`, and `n` the beat point's `S.tick`. It is the mark for the limb's set, the glint, the tick sound and the optional ring.
- `DirBrawl.beatAt(S, f)` returns his beat point. A second read gives the window's two ends.
- `press_ack` gains `early` and `late`.

**Animation's two questions.**
- **The clock.** The beat point is on `S.tick`, because the player's rhythm and Controls' grade are. So the strike beat's `beat` field is in `S.tick`s, and the `beat` cue's `n` is the beat point as an absolute `S.tick`. The body should key on that tick and not count live ticks from the contact: its own hit-stop is inside the 24, and so is every freeze the rival's blows add, which nobody knows at the contact.
- **What the beat point is on the body** (Game Design's ruling, section 4). The limb is pinned at the contact pose until 10 ticks before the beat point, returns over exactly the last 10 ticks and sets on the beat with the glint. A press in the last 4 ticks of the return throws the skill strike out of the return. After the window the limb stays set. To the sim the beat point is only a tick: his line is free from the contact on, so an early press cuts whatever the limb is doing.

### 8.3 What it needs from others

| Who | What |
| :--- | :--- |
| **Controls** | Answered (`docs/controls/skill-strike-input.md`): the window and the split above; a press inside a hit-stop is graded at its own tick, which is live; no change to the intent. One limit: two light presses inside one long freeze (4 to 9 ticks) merge into one. If a timed presser's second press goes missing in the probe, Controls fixes it in the layout. A Simple layout's tap is 3 to 6 ticks late, and the offset and the assist absorb it |
| **Combat** | A beat of 20 to 28 by the piece, when its rows carry one |
| **Animation** | The tech pose on the contact tick in a brawl, and the limb's set at the beat point, from the `beat` cue |
| **VFX, Audio** | The glint at the beat point, the hard diamond contact mark, the wire echoes; the tick at the beat point |
| **UI** | The beat ring option, off by default, reading `beatAt` for both fighters |
| **QA** | Its timed script reading `DirBrawl.beatAt` |
| **Simulation** | `mood.json` `impulses.skillStrike` 50 (Game Design's value), in B2's commit by the EP's grant |
| **Tools** | The `skill` block and `hitstop.skill` |

### 8.4 What it is measured on

- **The banded row:** a timed presser against the same presser mashing at an 8-tick gap wins 62 to 82%.
- **Reported beside it:** each of them against the medium AI. The timed presser's target there is 70 to 90%, and it is expected to read over until the parry exists.
- Skill press to contact: 6 ticks, 95% inside 8. The share of a timed presser's presses graded on the beat while a masher is hitting him.
- The masher's three bands; the mixing presser's brawls; the medians on both arms; the mood.
- With flow earned in a brawl: the launch share of the exchanges that separate (25 to 40%), and of brawl endings that separate, knock-backs 60 to 75% and launches 25 to 40%.

## 9. C1, control and the even mash: the cut (2026-10-05)

Spec: `docs/design/brawl-second-pass.md` sections 1 and 7, with Controls' `docs/controls/q19-input.md` and Animation's `docs/animation/brawl-second-pass-view.md`. Nothing here is built, and it isn't started until Z1 is committed.

### 9.1 What C1 includes

| Thing | Rule | Number (data, the `brawl` block) |
| :--- | :--- | :--- |
| **The centre** | The point midway between the two. Each live tick it moves by the two sticks added together, and both fighters move with it | |
| **A stick's rate** | His stick, by how far it is pushed, × 0.4 of his own free-flight speed. Two who agree add up to 0.8, and two who oppose cancel | `nudgeMul` |
| **It ramps** | From the tick a direction is first held, to full over 8 ticks. A stick at full deflection from its first tick, which is a keyboard or a D-pad, starts at 0.4 of its rate and reaches all of it over 12 | `nudgeRampTicks`, `nudgeDigital` |
| **It is capped** | The centre never moves more than 0.3 bh in a tick | `maxStepBh` |
| **By his state** | Striking, charging or reeling from a light: full. Guarding: 0.6. Staggered: none, since the core has cleared his stick | `nudge.guard` |
| **The carried speed** | The centre starts with the mean of the two velocities as they meet, which is half the closing speed when one of them stood. It fades to nothing over 20 ticks | `carryShare`, `carryTicks` |
| **The attraction** | As now, on the pair's gap only: each is held at striking distance from the centre and at one height. It no longer has a point to pin them to, because the centre moves | `pullBhPerSec` (existing) |
| **The ground and buildings** | The centre slides along the ground and stops at a building's face. My default; a brawl that breaks through a wall is a set piece for later | |
| **Walking out** | Both sticks away from the rival, within 45 degrees of straight away, for 12 ticks running. The brawl ends `walk`: free, nobody decisive, no wait after it. A blow thrown by either starts the count again. A boost held with the stick away is still the escape, at its price | `partTicks`, `partDeg` |
| **A lead in the trade** | At 120 ticks a lead of 2 takes the close, as now. After that a lead of 2 takes it on the tick it appears | `flurry.tradeMaxTicks`, `levelWithin` (existing) |
| **The double hit** | A trade still level at 240 ticks. Both lines are cleared and each throws one blow, landing 8 ticks later on the same tick. Each takes 4 brawl lights to the head. Both are thrown back 6 bh from the centre, opposite ways. Nobody is decisive. The brawl ends `double` | `flurry.doubleTicks`, `double.windupTicks`, `skillMul` (existing), `double.throwBh` |
| **Withdrawn** | The seeded draw, `flurry.momentum` and the last closer's slot | |
| **The AI** | It holds a nudge at a share of its ticks in a brawl: the Protagonist away from people and the rival toward them, by the launch planner's own personality term. It answers a rival's away stick with its own at a share, more when it is behind | Each level's `nudgeShare` and `walkOut` |

Not in C1: the picture-in-picture and the two poses of the double hit (the rule doesn't wait for them); anything on Y, A or B.

### 9.2 Cues and reads

- `brawl_end` gains the texts `walk` and `double`.
- A new cue `double_hit`, sent as the two blows are thrown: `n` the tick they land, `x` and `y` the centre. It is 8 ticks ahead, for Camera, Audio and VFX. The two strike beats carry `double` true.
- `trade_break` keeps the text `lead` and loses `draw` and its `k`.
- `DirBrawl.centre(S, ex)` returns the centre's `x`, `y`, `vx` and `vy`, and the ticks both have held away (0 to 12), for Camera, Animation and UI.
- The fighters' own `vx` and `vy` are the drift (9.3), so anything that already reads a fighter's velocity sees it.

### 9.3 Where the movement sits, and what C1 needs

**The movement can sit in the director.** The core already steps a locked fighter by his own velocity, with a damping (`sim/core/fighter.gd`, the `locked` branch), and the brawl's attraction already writes both positions. C1 sets both fighters' `vx` and `vy` to the centre's velocity each live tick and lets the core move them.

| Who | What |
| :--- | :--- |
| **Simulation** | 1. The free-flight speed as one read (it is a formula inside `stepFighter`: the fighter's speed, his tier, his legs, his stance), so the 0.4 is of the number the core flies him at. A refactor with no change to the goldens. 2. Its yes to the director setting a locked fighter's `vx` and `vy` each tick, and whether the locked branch's damping should stand: it takes about 6% off each tick's step. 3. How the director asks for the clash's mood impulse (480) on a double hit: the director makes no mood calls today |
| **Controls** | One question. The intent doesn't say which device a stick is, and a pad pushed to its edge reads the same as a key. So the digital ramp would be applied to any stick at full deflection from its first tick. If that is wrong, the pure helper Controls offered (`q19-input.md`) is the fix |
| **Animation** | Nothing to author, by its own page. It reads the fighters' `vx` and `vy`, which are the drift. Its test of a tug of war decides whether a blow's reach is read again on its contact tick. The double hit plays with two existing straight blows until its poses exist |
| **Camera** | A pair whose centre moves at up to 0.3 bh a tick and can cross the seam; `DirBrawl.centre` for the frame; `double_hit` 8 ticks ahead for the inset, when it has one |
| **QA** | The rows of the second pass's section 11 that C1 owns: the centre moves within 2 ticks of a stick (a hard test); bh a second for a held stick against none; double hits a match; every trade level at 240 ticks ends in one (a hard test); the even lights-only mirror retired and the 8-against-10 mirror added |
| **Tools** | The keys above, and `flurry.momentum` removed |
| **Game Design** | The building default above. Whether a walk-out's 12 ticks count while one of them is guarding |

### 9.4 Its size and its risks

- **Size:** the attraction's block in `tick`, the carry in `begin`, `_tradeTick` rewritten, a double-hit path (two blows by `blowAt`, their contact, the two slides, the end), the AI's nudge and walk-out, and the probe's rows. About 250 lines in `brawl.gd` and one chain.
- **The masher's bands will move.** A level trade against the medium AI was settled by a draw at 120 ticks. Now it runs to 240 and costs both of them 4 lights. The masher's three rows and the match's length are re-read, with the AI's tap gap as the first lever.
- **Zips into a moving brawl.** A zip's end point follows the rival already. A caught zipper joins a brawl whose centre has a velocity; the carry is taken from the two as they are then.

### 9.5 How large C2 is in my code

C2 is the largest brawl slice so far: the second pass's sections 2 and 3, with the shove from section 4.

| Part | What it touches |
| :--- | :--- |
| **One tap-and-hold rule** | `takes`, `press` and `_throw`: every press throws its button's quick move on time, and a button still held at its hold point charges the move that follows. The 26-tick heavy, its wind-up and `_hold` go |
| **A flurry on Y, and the mix-up** | `_throw`, `_flurryMul` and `contact`: the gap, rate, contact, ki, reel and guard chip by button; a quick heavy adds to the run. `_piece` and the repeat rules across both buttons (Legal) |
| **The ender is withdrawn** | `_piece`, `contact`, `_heavyLanded`, the launch gate's ender, `enderShare`, and B1c's heavy riposte, which is "a heavy or an ender" today |
| **The charges** | Two new line states. The armour in two steps, in `contact`, on the fighter being hit. What ends a charge. The whiff. The just release. The launch at a full charge |
| **The fresh guard** | `interrupt.gd`: a guard raised in the last 30 ticks against a set one, for the charged heavy only |
| **The shove** | A new reading of A in reach, beside the reversal's A with guard held: an 8-tick wind-up, 3 bh, the brawl lets go, a charge ended with a stagger, the lockout |
| **The AI** | `aiInput` and `_aiHeavy` rewritten: the Y flurry, the mix-up, a charge into a gap, the shove against a charge. `rashHeavy`, `enderShare` and the closing heavy go |
| **The zip** | The heavy counter is timed by the end of a wind-up that no longer exists, and a zip heavy is worth "a brawl heavy". Both need Game Design's line |
| **The rows** | Every masher, mirror and mixing-presser row is re-read; the mixing presser's script, which closes with an ender, is replaced by the Y masher and the alternator |

About half of `brawl.gd`'s 1,170 lines change. I would build it as two chains: **C2a,** the tap rule on Y with the heavy flurry, the mix-up and the ender withdrawn, about the size of B1b; then **C2b,** the charges with the armour, the fresh guard, the just release and the shove, about the size of B1c and the zip's answers together. C2a can be committed alone. Orb plays after C2b, since the shove is the charge's answer.
