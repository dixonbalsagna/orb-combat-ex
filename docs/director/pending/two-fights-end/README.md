# Parked: a finished fight's winner goes to the other one, and the brink's call (2v2 steps 3 and 5)

Encounter, 2026-11-02, on Game Design's `docs/design/two-v-two.md` ("What brings the fights together", and the rulings of the same day), built on Simulation's `docs/architecture/pending/cross-end/` (step 3's sim side: `Fighter.out`, the KO'd fight stepping, the rejoin). **Behind `outside.enabled`,** and only in a two-fight match with cross on.

**Apply after `../two-fights-join/`, on Simulation's cross-fights 228a and cross-end:** `git -c core.autocrlf=false -c core.eol=lf apply two-fights-end.diff`. **With it, a grant in Controls' file:** `grant-controls-winner-input.patch`, 2 lines in `sim/input/control.gd`, below.

## What it does

| | |
| :--- | :--- |
| **The brink's call** (step 5) | On a fighter's brink's first moment, the cue `brink_call`, once a brink, for Audio's voice line and UI's map. It's the rescue's cue |
| **A computer partner comes** (step 5) | A computer fighter whose partner in the other fight is on the brink drops its own fight and flies flat out at the one who has him there. In reach and on an opening, its press is a blow from outside. So a human and a computer partner can race the rescue |
| **A computer winner** (step 3) | Whoever finishes first goes to the other fight, with no input needed: its press pursues the nearest enemy across, however far, and lands on an opening |
| **A human winner** (step 3) | His focus is across once his fight is finished: a press pursues the nearest enemy across, however far (a rush, then the usual wait for an opening). The 12-tick ease of his focus is the picture's (UI and Camera), not the sim's |
| **The rejoin** | Needs no forward. Simulation's rejoin waits until no body is in a launch or a rush, and the brawl ended at the KO. A blow from outside waiting on someone who's since come into this fight is dropped |

## The grant: a standing winner's input under his fight's KO

`SimControl.control` returns at once while the fight has a KO, so under cross-end the winner sits still until the rejoin: no input, and no AI. Game Design's "whoever finishes first flies to the other fight" needs him to move. The line (Controls' file):

```
	if S.game.ko != null and not (S.stage != null and SimCross.on(S) and not f.out):
		return   # (2v2: his fight is finished and he's standing: he goes on, to the other fight)
```

In a 1v1 there's no stage, so nothing changes. **Everything else gated on `S.game.ko` stays off for him** (forms, last stand, the rally), as the EP noted: Game Design rules if that's wrong.

## Read

`outside_check`:

| | Read |
| :--- | :--- |
| His partner on the brink 6,000 off (a computer fighter) | The call once; he came from 6,124 to 58 and struck from outside (28 taken) |
| A computer winner | From 8,531 to 131 of the other fight; it struck (28) |
| A human winner, one press | From 9,100 to 171; it struck (28) |

## Not done

- **Who counts as "the other fight's" when there are more than two:** the nearest enemy across, today.
- **QA's rows:** 2 to 4 rescue flights a match, and all four within about 15,000 units for 25 to 50% of it. They need a two-fight soak with the computer fighters.
- **Nobody's looked at it.** A body rushes most of the way round the planet: Camera's split is where it shows.
