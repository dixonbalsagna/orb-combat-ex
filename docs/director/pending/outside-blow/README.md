# Parked: a blow from outside, and a beam that stops on someone else (2v2 steps 2a and 2b)

Encounter, 2026-11-02, on Game Design's "Hits across fights" 1 and 2 (`docs/design/two-v-two.md`), built on Simulation's cross-fights (`docs/architecture/pending/cross-fights/`). **Behind `data/director/interrupts.json` `outside.enabled`, off,** and it only acts in a match of two fights with cross on. In every other match, nothing here runs.

**Apply after Simulation's `cross-fights.patch`, on my stack after `../ratchet-roster/` and `../two-fights-swing/` (it uses `DirStanceCost`'s slots, from `../stance-circle/`, and the roster helpers):** `git -c core.autocrlf=false -c core.eol=lf apply outside-blow.diff`. **Simulation's grant comes with it:** `grant-simulation-forward.patch`, 2 lines in `sim/core/cross.gd` (`_land` calls the forward for a blow) and the forward in `sim/core/dir.gd`.

## What it does

| | |
| :--- | :--- |
| **When a press is a blow from outside** | No exchange of his own is running, and an enemy of the other fight is within `reachBh` 3 and nearer than his own rival, or his own fight is over |
| **It lands only on an opening** | A stun, a stagger or a daze, or the recovery after a blow of his own or a whiff. He goes to him at the tap chase's speed |
| **Not open?** | He hovers in reach up to `waitSec` 0.5 s for the next opening. If none comes it's a whiff, and he's open for `whiffTicks` 20 |
| **One an opening** | A second press in the same opening lands nothing. The opening has to shut for a tick first |
| **How it lands** | `SimCross.strike`: in his fight on its next live tick, through `SimDamage.hit`, so his guard answers it. The light's or the heavy's damage, by the press. No send, no knock-back, no stun |
| **In the fight it lands in** (`landed`, via the forward) | **On someone landing a finisher: it breaks the finisher,** and the exchange ends with his victim free, still on the brink. **On someone in a string: it ends his string, his run with it.** A blow he'd already thrown still lands. Otherwise it's the damage and the hold, and the exchange runs on |
| **Cues** | `outside` start, hit or whiff on the striker, with the target's keys; `outside_hit` on the one struck (`finisher` when it broke one) |
| **A beam that stops on someone else** (2b) | When SimCross stops a beam of this fight's exchange on an enemy of the other fight (`b.stopAt`), the exchange ends at once. Its own target takes no planned outcome, and the one it stopped on takes SimCross's hit in his own fight. Cue `beam_stopped` |
| **The warning** (2b) | Whoever is first on a beam's line from the other fight (`SimCross.warned`) gets the cue `beam_warn`, once, from that moment |
| **The AI's answer** (2b) | A warned AI draws once against `aiDodge` (easy 0.3, medium 0.6, hard 0.85). If it answers, it holds a dodge while warned, and the beam passes it, as SimCross's dodge rule says |

## Read

`outside_check` (verdict `OUTSIDE: n check(s) failed`), four bodies in two fights, an enemy across 140 units away and his own rival 2,400 away:

| | Read |
| :--- | :--- |
| The enemy across, stunned | Lands: 28 taken |
| Not open, then open 12 ticks in | He hovers, and it lands on that opening |
| Never open | A whiff, nothing lands, he's open |
| A second press in the same stun | Nothing more |
| His own rival at 60 | His own fight's press, no blow from outside |
| The enemy across in a trade of his own | It lands, and ends his string (his run went from 8 to 0; a blow he'd thrown then landed and made it 4) |
| Off | Nothing crosses |
| A level beam at his rival 1,600 off, an enemy across at 700 on its line | He's warned, it stops on him (219 taken), **his rival takes nothing** and the exchange is over |

## Not done (2c, and what 2b leaves)

- **Focus** is a first rule only: the nearest enemy across, if he's nearer than your own rival. Game Design's focus (whoever you last hit, the stick moving it, the winner's ease across over about 12 ticks) comes with the finished fight, step 3.
- **The finisher break isn't checked on its own.** Staging a finisher in the other fight is for 2b's check.
- **One stun a string across a team: done (2c).** A blow from outside stamps the one it lands on. For `teamRestunTicks` 24 after it, a new string of the partner's in that fight doesn't reset the stick's one-stun-a-string mark, so partners can't take turns locking him. It's a hook in `DirBrawl` at a string's start. In the check, the stun is held as the blow lands and free again 26 ticks on.
- **`fireAt` from focus: done.** A blast press whose focus is across (the nearest enemy of the other fight within `shotReachBh` 40, nearer than his own rival) fires at him through `SimCross.fireAt`, made in his fight. It pays the ki as any shot does, and the cap there spends the press. In the check, a bolt at an enemy 1,500 off is made in his fight and lands there (14 taken).
- **The struggle when the one it stopped on fires back:** a beam struggle lives in one fight's clash, and his beam is of the other fight. It's a design of its own.
- **The AI's dodge is held** for the whole warning: it isn't timed to the front's arrival yet.
- **A whiff's "open"** sets his line's recovery (`FREE_AT`) only, which is what a brawl reads. What a whiff leaves open outside a brawl is Game Design's to say.
- **Nobody's looked at it.** He rushes across to another fight's man and back to nothing: the look needs Camera's split.
