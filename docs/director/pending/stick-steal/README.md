# Parked: the stick steals his run (a scratch switch, for QA's arm)

Encounter, 2026-11-02, on Game Design's narrower shape in `docs/design/stick-lands.md` from line 85. **Behind its own switch, off:** `data/director/stick.json` `steal.enabled`. It's for QA's arm, not the page.

**Apply last of the six, after `../stance-circle/`:** `git -c core.autocrlf=false -c core.eol=lf apply stick-steal.diff`. Its `stick.json` hunk goes after charge-armour's `armour` block, as charge-armour's re-cut lays it (right after `chargeRecover`), so Tools needs no bridge. Re-cut 2026-11-02 and checked on that layout with the other five applied.

## What it does

A quick flick of the right stick, with no stance held, that lands clean on a rival with a run going:

| | |
| :--- | :--- |
| His run | Goes to 0 |
| Yours | Rises by what was taken, at most `max` 3 |
| He | Reels `reelBase` 6 + `reelPer` 2 ticks for each point |
| Cue | `stick_steal`, with the points taken |
| The AI | Never steals, so a beginner mashing against the computer is never stolen from |

It runs before the hit's stun, which would otherwise break his run first. A steal takes the whole run, so he's only stolen from once a run.

## Read

`press_decides_check`, a rival with a 3-point run and a trade going: the flick took 3, his run went to 0, mine to 12 quarters (3 points).

## Grants

| Whose | What |
| :--- | :--- |
| QA's | the arm: on, against off, with a player script that flicks during the AI's runs |
| Tools' | none: no page switch |
