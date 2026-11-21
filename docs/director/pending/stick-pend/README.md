# Parked: a stick strike follows its request, a swept hold becomes the charge, and a flick builds a run

Encounter, 2026-11-02, from QA's meteor bot and QA's stick-only read on the kept build, with Game Design's rulings of the same day (`docs/design/stick-lands.md`). **Two switches, both off:** `data/director/stick.json` `pendFollow.enabled` and `flickRun.enabled`.

**Apply after `../chase-air/`, on the stack with the six press-decides parks:** `git -c core.autocrlf=false -c core.eol=lf apply stick-pend.diff`. Its `stick.json` hunk is cut on Tools' layout (charge-armour's and stick-steal's blocks after `chargeRecover`), and the whole diff was checked there.

## 1. pendFollow: the stick strike follows its request

A stick press asks for a heavy, and only a brawl blow can become the stick strike. Anything else, and the stick's own 9-tick timer (`pendTicks`) dropped it with "late". In 19 traced tries on QA's meteor arm (3 matches, medium AI, the kept build's page switches): 9 started, 4 were taken by a planned exchange the AI answered with (dodge-and-read or counter), 1 was queued, 1 refused (the first move was the rival's), 1 replaced. The 6 that went neither way all said "late".

| | Off (today) | On |
| :--- | :--- | :--- |
| Queued | Lapses after 9 ticks as late | **Waits with its request,** up to `maxTicks` 90 |
| Answered by a planned exchange | Late, 9 ticks after the press | **Told at once:** `stick_refused`, source `answered` |
| ... with the stick still held | Lost | **Becomes the charge on his first free tick, counting from then, nothing banked** (Game Design). Only that strike is marked to count from its own request. Every other hold keeps the stick's own level, which counts through hit-stops |
| Refused | Late, 9 ticks after the press | **Told at once:** source `refused` |

**One refusal a press (re-cut 2026-11-02, from Tools' film).** The first cut buzzed: 27 `stick_refused` in a row while the stick was held. A planned exchange with a window doesn't count as "can't act", so the swept hold went again at once, was answered again on the same tick, and was swept again. Now a swept hold waits until no planned exchange holds him, and its go is quiet. If it's refused or answered again, nothing more is said: its press was told once already. The check holds a swept stick 90 ticks: 0 refusals, 1 press acknowledgement.

## 2. flickRun: a landed flick counts in its striker's run

QA's stick-only arm loses every trade break to the AI: a flick that lands with no stun built no run of its own (stick-lands.md's earlier rule), so at each break the player's run was 0 against the AI's 2 or 3. Game Design ruled a light's point first, and a medium's 3 if stick-only still lost every break. The landed flick also keeps his string going, as a light's landing does; without that, the string's lapse spent the point.

**Read** (QA's stick arm with trade breaks logged, easy AI, 2 matches each, the kept build's page switches):

| `points` | Breaks to the AI | Breaks to the stick player |
| ---: | ---: | ---: |
| off (0) | 48 | 0 |
| 1 | 48 | 0 |
| 1.5 | 13 | 32 |
| 2 | 0 | 45 |
| **3, shipped as ruled** | 0 | 45 |

At 1 the AI's replies take the point back before any break. From 2 the stick-only player wins every break. **It's a cliff, and the level point is near 1.5: Game Design's to set.** The masher and newcomer rows weren't read with it on.

## Read

- `press_decides_check`:
  - a refused flick says `refused` on its own tick with pendFollow on, `late` 10 ticks later with it off;
  - a swept hold goes on his first free tick (19, after a 20-tick stun) and releases at level 1, not the 3 the stick's own count gave;
  - a landed flick adds `points` to his run, and nothing with flickRun off.
- **QA's meteor arm with pendFollow on** (3 matches, 15 tries): no "late" at all: 3 answered, 1 refused, 1 replaced, 8 started.
- **The same with charge armour on too** (18 tries): **3 level 3s landed clean**, against 0 before.

## What it doesn't fix

**The meteor still didn't fire.** After a clean level 3, the bot's B waited out the strike's charged recovery (`chargeRecover` 16) in the press slot and went as a plain heavy, too late for the 40-tick stun. That's the ignition's timing, Game Design's numbers.

## Grants

| Whose | What |
| :--- | :--- |
| Tools' | two switches: `{ id: 'stickPend', file: 'data/director/stick.json', path: ['pendFollow', 'enabled'], from: false, to: true, needs: [], optional: true }` and `{ id: 'flickRun', file: 'data/director/stick.json', path: ['flickRun', 'enabled'], from: false, to: true, needs: [], optional: true }` |
| QA's | the stick-only, masher and newcomer rows with flickRun on, at the points Game Design picks |
