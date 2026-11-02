# Orb's second play: the circle, knock-backs and combo control

Encounter, 2026-11-01, overnight. A read and proposals; nothing's built. The notes are in `docs/ep/vision.md`.

**How this was read:** Orb's match (`homework/Files/orb-first-play-20261101-2130.json`, private, read locally) replayed on main + `field-place` and its grant + the page's switches: **40 of 40 checkpoints, final hash c130250f9f984886, as the file says.** So every number here is what happened in that match, against the easy computer: one match, 6.8 minutes. That build had no charge armour.

## 1. "Fly around in a tight circle, then deliver an attack"

### What it is

**Mostly the `dodge` exchange template** (`data/combat/templates.json`; `DirMelee.opDodge`, `opDodgeLand`, `approachOver`). It's not an LT move at all. Two bodies really do go round each other:

1. His approach, a rush at the rival.
2. The rival, evading, steps over him and down behind (`dodge`, two straight legs, rising about a body height).
3. He turns and rushes after them (`finRush`).
4. His blow lands, or the rival counters.

**The fullest one, t14134, is the one that fits Orb's words best:** he swept 350° round the rival in 65 ticks, staying within about 150 units, because the stick was also down past 0.5. That's the arrival rule (`interrupts.json arrival`): he goes over the rival first too, so both halves of the circle show. It happened **once** in the match.

**A second thing, which LT really does cause: the step strike** (`DirStance`, the page's `stances`). LT + X, landing clean: he comes out 0.8 bh past the rival. At t5204 to t5290, with X held for the burst, it swept 900°. **But it isn't a circle:** he goes straight through the rival, back and forth along the line, at the same height.

| | Circles in the match | LT held at its start | What it looks like |
| :--- | ---: | ---: | :--- |
| `dodge` template | 13 exchanges, all begun by Orb | 4 of 13 | A real loop, 150 to 350° |
| Step strike | 14 steps, most of them in one run | Always | Through the rival, along a line |

**I think Orb means the first, from the words "fly around" and "then deliver". A clip of each would settle it:** t14134 and t5204.

### What triggers it, and why it's only sometimes

Three things have to be true, and **none of them is what Orb was pressing:**

1. **Not already in a brawl.** In a brawl a press is a blow on the line. Most of Orb's LT presses were there: of 215 Y presses with LT held, 206 were in reach, and LT + Y in reach does nothing different from Y.
2. **So LT matters indirectly.** LT with the stick away leaves a brawl (`dodge_cancel` 26 times, `brawl_end:left` 11). The next press then starts a planned exchange from outside. That's why it felt like an LT thing.
3. **The rival has to be evading right then.** All 13 had the rival's stance at 2. That's the computer's own draw when it answers an approach (`DirBands.aiAnswer`, `R_DODGE`). A rival that doesn't dodge gets a brawl. Against another player it would need their dodge tap in its window.

**And 5 of the 13 ended with no blow at all** (`DODGE — CLEAN`, its `nop`). So Orb got the attack in 8.

**Other things that held LT and looked different:** 3 zips (LT with a press from the mid band), with 5 refused for no ki and 4 refused otherwise.

### How to make it reliable

**Make it a move the player owns: LT + Y in reach is the circle.** That input is free today. He flies over the rival (under, with the stick down), lands on the far side, and the medium lands as he arrives. It doesn't need the rival to do anything.

| | First proposal, for Game Design |
| :--- | :--- |
| **Input** | LT + Y, in reach, in a brawl or starting one. LT + X stays the step strike. LT + Y from the mid band stays the zip heavy |
| **Motion** | `approachOver`'s two moves, about 24 ticks, with a bow (`Rush.arc`) so it's one curve rather than two straight legs |
| **Worth** | A medium's. The motion is the reward, so no more damage |
| **Answer** | Slower than a medium, so it can be seen. A heavy or a grab stops it, and a guard can turn to block it. It swaps sides, which the hero's stick reads from then on |
| **Price** | A little ki, so it isn't every blow |
| **The computer's dodge** | Stays as it is. It's still good, and it still surprises |

**Polish, once Orb has said which:** the bow, an Animation piece for the flip over, a streak from VFX, Camera holding both bodies, and a hit-stop on arrival. **The step strike needs its bow too,** as going through the rival's body is the weak part of it.

**To check with Combat:** whether the parked nine-cells work has plans for LT + Y.

## 2. "Getting knockbacks feels very arbitrary"

It is arbitrary, from where the player sits. **The same B can do five different things, by rules the player can't see,** and two different rule sets are in play.

| Situation | What decides it | Press B and you get |
| :--- | :--- | :--- |
| **In a brawl, tapped** | Did a flurry's stagger or a guard break just open the launcher (up to 24 ticks after)? Has it rested (`restS`, 30 s)? | The launcher's send, or a stagger, or a recoil |
| **In a brawl, held** | Charge 32 to 43 ticks, then 44 for full | Under 32: as tapped. Short of full: a knock-back. Full: a send |
| **Starting an exchange** | `earned`: held? 1 or more landed, **and flow 3 or more** (a count of on-beat presses, not shown)? Stick held, with 1 or fewer blows taken? | Earned: a send. Not earned: a knock-back |
| **A blast (RB)** | Your run at 2 or more | A knock-back as the ender, or a plain blow |

**Y sends too, only outside a brawl:** Y in a `dodge` exchange knocked back at t9927 and t14251. Y in a brawl never does.

**What happened to Orb's:** 16 sends in the match, 8 of them knock-backs.

| Where his 8 knock-backs came from | |
| :--- | ---: |
| Heavy in a planned exchange, not earned | 5 |
| B charged short of full | 2 |
| A blast as the ender | 1 |

**The charge itself, and this is the important one:**

| What he held and let go | Count | What happened |
| :--- | ---: | :--- |
| Released at the charge's start, 0% | 12 | No knock-back from any |
| Charged 25% to 83% | 4 | 2 knock-backs. **2 missed: the rival walked out of reach** |
| **Full charge** | **1** | **Missed: the rival walked out of reach** |

**`miss:gave_ground` happened 19 times in the match.** So a player who does the right thing, holds B to the flash, gets nothing. That one is the fault I'd fix first.

**"Hard to charge up an attack when every hit seems to interrupt":** that's mostly the stick. 39 stick strikes started and **7 landed.** The charge armour park addresses that, and Orb hasn't played it. B wasn't often stopped: of 125 B wind-ups, 108 reached the rival, 12 missed and 5 he cancelled himself.

### Proposal, for Game Design

**One rule, in every situation: how long you held B decides.**

| Held | Result | Everywhere |
| :--- | :--- | :--- |
| Tapped | A stagger | In a brawl or starting one |
| Past the first flash | **A knock-back** | Guaranteed if it lands |
| To the full flash | **A send** | Guaranteed if it lands |

1. **A charge can't be walked away from.** A released charge travels: its reach grows with the charge, so a full one always closes the gap if the rival isn't blocking or dodging on purpose. Stepping back shouldn't beat a charge unless it's a real dodge. *My first thing to change, and the smallest.*
2. **Drop `earned` for a held heavy's result.** It would leave flow, string counts and "blows taken" out of whether you get a knock-back. Those can still pay for something else, such as a longer send.
3. **Show it, on the body and the pad:** a flash at each step of the charge, with the rumble ladder Controls already has. The launcher's window (`launcher_open`, 10 times, 6 lapsed unused) wants to show on the fighter too. No marks over the fighters, though: it should be his own glow.
4. **Say why it failed:** a blow that missed or was stopped gets its own sound and rumble, as refused presses do.

**The catch:** this gives more knock-backs and sends. Launches per match, match length and the masher row all move, and tier 1's launch counts have been tuned with `earned` in mind. **It needs QA's read,** and the launcher's rest may need to apply to full charges as well.

## 3. "Better combo control"

### Who controls what, today

| The player | The director |
| :--- | :--- |
| Which strength: X, Y or B | Whether the press goes now, waits or lapses |
| When | How the two close to reach, and exchanges' timing |
| Held: X's burst, B's charge | Which animation piece plays |
| Stick strike direction and level | Whether a send is earned |
| LB and LT on a blow: check, push, step | Where a send goes: the planner picks it, and the stick leans it |
| Leaving a brawl | The whole `dodge`, `pursuit` and `clean hit` exchanges, once started |

### What Orb's presses did

| | X | Y | B | |
| :--- | ---: | ---: | ---: | :--- |
| Went on at once | 1 | 9 | 12 | |
| Waited in the line | 95 | 311 | 165 | |
| Queued outside a brawl | 12 | 46 | 18 | |
| **Lapsed: thrown away** | 16 | **86** | **59** | **161 of about 670, a quarter** |

**The largest thing I can find is that a quarter of his presses did nothing.** A press waits `heldPressTicks`, 10 ticks, for the line. A medium's wind-up is 12 and a heavy's is 28, so **a press made early in a blow always lapses**, however well it's meant. A player mashing Y then B doesn't know which of them counted.

Blows that did come were mostly the press he meant (290, with 44 another kind), and quickly (median 3 ticks after the press, 90% within 13).

**Also noticed:** RB + B was refused 51 times (`driver_refused`). 23 releases of the stick with RB gave 3 real beams. 9 of Combat's phrases finished, and nothing told him.

### What I'd change, in order

1. **A press waits for the blow in hand to finish,** one slot, newest wins, in place of a fixed 10 ticks. Every press then counts. It's about 3 lines plus the data, and I can read it the same night. **Risk:** the masher row, as a mash becomes a steadier string. QA's.
2. **Sends are aimed by the stick, always, when it's held.** The planner already mostly obeys: in Orb's match, sends with the stick held went that way. With it neutral the planner picks, which is fine. **Say this in the hint, rather than change it.**
3. **Show the string's state on the fighter:** the next blow's strength and whether B will send. It comes from the same cue as the launcher's window. UI's and VFX's, with no marker over him.
4. **Choosing the route:** let the second press decide what the first blow leads to, with Combat's phrases as the data, and tell the player when one lands. That's a bigger job, and I'd do it after 1 to 3. Game Design's and Combat's.

## What I need

- **From Orb, through the EP:** the two clips, to say which is the thing they loved. I haven't made them.
- **From Game Design:** rulings on the circle, on the one rule for B, and on the press wait.
- **From Combat:** LT + Y's plans, and phrases as the route.
- **From QA:** launches, length and the masher once any of this is built.

**Not read:** another player's dodge, since this is one match against the easy computer. How often the computer dodges at other levels.
