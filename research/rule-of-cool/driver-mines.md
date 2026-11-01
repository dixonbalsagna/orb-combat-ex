# The Driver and big-ring mines: what the prototype found

Research & Prototyping, 2026-11-01, on Game Design's `docs/design/energy-overhaul.md` §21. **Play it:** `docs/ep/prototypes/driver-mines-v1.html`, with a pad. **Clips:** `research/rule-of-cool/clips/`, inputs at the frame's edge. **Reads:** `node research/rule-of-cool/driver-clips.mjs --check` and `--bots`.

**The Driver works as ruled, and its recoil is the weak part. Mines as ruled do almost nothing on the big ring, because three first values assume speeds far below flat out. One change to the fuse and one to the cold distance fix most of it.** Both are on switches, so Orb can try them either way.

**How far to trust this.** A side-on stand-in: two simple fighters on a ring 153,600 round, no collisions with towers, and a rival with only a few habits. The reads come from a bot against that rival, so they show what the rules allow, not what's fun. **Only a scripted pad has driven it,** and nobody has played it.

## The arithmetic behind it

Flat out is 10,240 u/s, or 2.3 body heights (bh) a tick. Everything below follows from that.

| Rule | First value | At flat out |
| :--- | ---: | :--- |
| Recoil at level 3 (E126) | 6 bh, 450 units | **0.04 s of flight.** It kicks the body, and it isn't movement unless he's near a standstill |
| Level 3's hold (E125) | 84 ticks at half speed | A chaser at flat out closes **95 bh** during it |
| A mine's flare (E74) | 6 ticks | He travels **14 bh** in it |
| Reach at tier 4 (E136) | 6 bh, so 12 across | **He's through it before the flare ends, every time** |
| Arming a blast mine (E73) | 20 ticks | 45 bh. A chaser closer than that passes it asleep |
| The longest throw (E135) | 30 bh, arming in 50 ticks | 13 ticks of flight to get there, and 114 bh in the time it arms |
| Goes cold (E138) | 120 bh | **Under a second** |

## What the bot read

Three minutes, 20 seeds, a bot that lays only with a chaser far enough back for a mine to wake. "Real work" means a mine that went off on him. QA's first read is at least 40% going off or answered, and 1 to 3 a match doing real work.

| Tier 4, the rival reads 35% | Went off | Answered | Went cold | Real work a bout |
| :--- | ---: | ---: | ---: | ---: |
| As ruled | 0% | 0% | 93% | **0.0** |
| The fuse leads him; cold at 120 | 0% | 0% | 93% | 0.0 |
| The fuse as ruled; cold at 600 | 1% | 14% | 0% | 0.2 |
| **The fuse leads him; cold at 600** | 9% | 5% | 0% | **2.4** |

**Real work lands inside QA's band with both changes, and the 40% doesn't:** only 14% go off or get answered. Most of the rest are the bot's own: it lays 26 a bout, and the limit of 4 fizzles the oldest. A person would lay fewer, and I can't tell how many from a bot. At tier 1 it's 2.1 a bout, and when the rival reads 75% it's 0.6, so reading matters.

## The two changes, on the page's buttons

1. **The fuse leads a fast flyer.** A mine starts its flare when he'll be inside its reach in 6 ticks, not when he's already there. He gets the same 6-tick window to dodge or brake, and at flat out it bursts on him rather than behind him. At low speed it's the same as E74. I'd make this the rule.
2. **Goes cold at 600 bh, not 120.** That's about 4 s of flat-out flight, and E76's 12 s and limit of 4 still clear the field, so Legal's "never survives its fight" holds. Mines can then wait for a chase to come back along the line.

## Open for Game Design

- **Recoil.** It reads well as a kick (clips D1 and D2), and at flat out it does nothing as movement. E128's getaway works in clip D2 because of the send it lands, not the 6 bh. If movement is the point, it could scale with what he's already doing, or be 30 bh or more at level 3. I left it as ruled.
- **Level 3 against a chaser** needs a start about 130 bh back, as clip D2 shows. Inside that, he's caught while gathering. A jab won't end it (E45's armour), a heavy will.
- **Level 3 landed 10% of the time** against this rival with no reads, 3% with 75%, fired blind by a bot at a mostly moving target. It flies to where he was at release (E124), so a flyer has already left. That suits "level 3 lands rarely on a reading opponent", though it may be too rare. A person chooses the moment, so read this one with people.
- **The throw (E135) can't cut off a flat-out runner:** he's past 30 bh in 13 ticks and far gone by the time it arms. Clip M2 shows it working at cruise speed. Its best use on this ring is clip M3's: throw it behind him, then send him into it.
- **Arming (E73)** means a mine laid in a chase needs the chaser 45 bh or more behind, so it won't help against someone already on you.
- **What's most fun, by my reading only: M3.** Laying a mine and driving him through it from range is the moment the two systems meet, and the send's score finds it without any new input. Orb's eye decides.

## What's in the page

- **The Driver:** RB + B, decision point 20, levels at 30, 54 and 84, half speed while gathering, armour from level 1, ×1.3, ×1.8, ×2.6, knock-back 6 and 10 bh, level 3 a full send on Game Design's curve, recoil 1.5, 3, 6 bh over 10 ticks with the stick still his.
- **The old beam,** on View or the button: the same hold, rooted, a line to him at range, for comparison.
- **Mines:** LB + RB + Y or X. A tap in flight drops one on the line behind him; a hold throws it along the stick to 30 bh, arming 1 tick later per bh; reach ×1, 1.5, 2, 3 by tier; at most 4; 12 s; the send's score counts armed mines on its line and the stick's vote wins.
- **Drawn to Legal's RL-225:** one firing hand with the other open and away, held at shoulder height or lower until it fires. The charge is a step of brightness at the heel of the palm and one thin open ring, in lane colour, never a ball. The shot is straight and narrow in lane colour, and level 3's size is length and weight. The recoil is the body kicked back along the line over 10 ticks, with no ring, aura or flash on the shooter. A hit throws straight chips, never a whole ring.
- **Four fighters at level 2** (clip D4; D-pad left and right in a try). Grist's short thick wedge with more knock-back; Loupe's needle, faster, through the first mine; Orza's ground line, which leaves a crack and rears up under him; Bolus's jagged slug of scrap, which ricochets once off the ground as one piece. **Orza's lane is darkened for the shot** to stay under the L* 86 cap, which is Art's to check.
- **No gold, white or red** in any shot, hand or body. Mines are small plain marks in the fighter's colour with no HUD. There are no dissolves or marks on the fighters. The inputs and the ring sit at the frame's edge.

**Left out:** X's and Y's other shots, B's trap, the snare, tower collisions, sound, people in a burst (E79), and the flash reading. **Flash matters here:** a string of flares needs the register's check (Legal's screen, item 6), which this page has not had. It's a private page.
