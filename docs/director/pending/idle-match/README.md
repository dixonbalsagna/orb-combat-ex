# Parked: a foe who doesn't fight back

Encounter, 2026-11-01, for Orb's first play. The ruling is `docs/design/power-scale.md` section 3. **It acts with `ending.enabled`,** which is off on main and on for the page.

**A plain patch on HEAD.**

**Apply in a scratch export:** `git -c core.autocrlf=false -c core.eol=lf apply idle-match.diff`. Then copy.

## What it does

| | Was | Now |
| :--- | ---: | ---: |
| No input before wear goes up | 10 s | **60 s** |
| Wear while idle | ×3 | **×2** |
| The push for the finisher, on the brink | From 10 s | **From 90 s** (`ending.pushSec`) |

Any input ends it at once, as before. If both players are idle nobody's pushed, and the computer is never idle.

## Power-up: not in this patch

**`chargePerSec` 0.5 to 2 is a live number** in `data/fight/ladder.json`, read in every match and in the parity tool, and it isn't mine. Changing it there moves the golden and every replay's data hash. So I'd put it on the page's switches until QA has read the tier pace:

`{ id: 'powerPace', file: 'data/fight/ladder.json', path: ['chargePerSec'], from: 0.5, to: 2, needs: [], optional: true }`

**The EP decides:** that line, or the data itself with the regen.

## Proof

- `ending_check`: 0 failed, off and with the page's switches. New rows: on the brink for the wear's time he isn't pushed yet, and at the push's time he's open. Both idle stays unpushed past the push's time.
- As part of the stack: golden byte-identical, validate, self-test 9,977, determinism, rollback, `two_states`.

## Not done

- **I haven't read whether this is what ended Orb's match.** Game Design says Tools can read it from the replay.
- **A pad that hasn't joined** is Controls' and UI's: the ruling says it should be the computer. Nothing here does that.
