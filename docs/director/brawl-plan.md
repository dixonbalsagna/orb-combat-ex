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
