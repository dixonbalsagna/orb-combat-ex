# Parked: a body on the ground digs or stops

Encounter, 2026-11-01, for Orb's first play: "I bounced against an outcrop of ground maybe six or seven times ... I would have rather seen my fighter leave a crater or a trench." **Behind its own switch, off:** `data/biomes/contact.json` `settle.enabled`. The file and `sim/world/contact.gd` are World's, so this is a grant.

**A plain patch on:** `../beam-still/`.

**Apply in a scratch export:** `git -c core.autocrlf=false -c core.eol=lf apply ground-settle.diff`. Then copy.

## What it was

**The case isn't in Orb's file.** That file is the later match, and neither fighter bounces like that in it. So I looked for it in computer fights on the page's switches, and found the same thing: `land:tumble` again and again about every 15 ticks, up to 8 contacts in one flight, as the tumble comes off bumps in the ground and lands again.

## What it does

| | Today | With it on |
| :--- | :--- | :--- |
| Ground bounces by tier | 1, 2, 3, 3 | 0, 0, 1, 1 |
| Contacts before he just stops | 8 | 3 |

## Read

8 computer fights, 4 minutes each, page's switches. `rattle_read.gd` repeats it:

| | Off | On |
| :--- | :--- | :--- |
| Flights | 62 | 50 |
| Flights with 4 or more ground contacts | 11 | **0** |
| The most in one flight | 8 | 3 |
| Craters | 59 | 55 |

The first hard contact still digs, as before: a steep one is a slam and a crater, and a shallow one is a skid with its furrow.

## Also in here: the meteor's blast

**A fault of mine on the page:** with `everywhere` on, 20 of the 52 buildings inside a bowl stayed standing, because `WorldStructures.near` only knows those on the fight's own line. `DirArc._blast` now walks them all, once a match. Two of `arc_check`'s rows read the page's switches and failed there, and they're fixed too.

## Not done

- **Water:** skims still skip, as a stone does, but the 3-contact limit now applies to them too, so at most 3 where it was 6. Skims aren't what Orb described, so World may want them apart.
- **A trench isn't any deeper for this.** It's the skid's existing furrow. "At the power it has" is the wider retune Orb asked for, on launches and terrain.
- **Nobody's looked at it.** Fewer contacts also changes where a body ends up, and what it breaks on the way.
