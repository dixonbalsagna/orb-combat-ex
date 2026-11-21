# Parked: my files name the exchange and the rival in one place (the two-fighter ratchet)

Encounter, 2026-11-02, the EP's landing blocker: `node tools/ratchet-two-fighter.mjs` read 417 against its baseline of 386 on the landing tree. My files had grown: `chase_tap.gd` 0 to 8, `stick.gd` 5 to 8, `beamplay.gd` 5 to 6. **A pure refactor: no answer changes, and the hash doesn't move.**

## What it does

Two helpers in `sim/director/brawl.gd`, the director's one place for each spelling:

```
static func exOf(S: SimState):          return S.dirS.ex
static func rivalOf(S: SimState, f):    return SimRoster.opp(S, f)
```

Every `S.dirS.ex` and `SimRoster.opp(` in `chase_tap.gd`, `stick.gd`, `beamplay.gd` and `swing.gd` goes through them (30 references). `swing.gd`'s two `S.fighters[0]` stay, because `../two-fights-swing/` replaces those lines with the anchor. For the 2v2 restructure, a change to who the rival is, or which exchange is running, is then one line.

| The ratchet's count | Before | After |
| :--- | ---: | ---: |
| My stack (main + my accepted parks) | 398 | **370** (16 under the baseline) |
| `chase_tap.gd`, `stick.gd`, `beamplay.gd`, `swing.gd` | 8, 8, 6, 10 | 0, 0, 0, 2 |
| `brawl.gd` | 32 | 34 (the two helpers) |

On the landing tree that's 28 off its 417, so 389. **`camera-swing-read.patch` takes Camera's `swing_read.gd` (from `docs/camera/pending/swing/swing-4-sim.patch`) through the same helper, for 2 more: 387.** The rest of the rise is in other owners' files.

## Apply

On the stack after `../chase-carry/`: `git -c core.autocrlf=false -c core.eol=lf apply ratchet-roster.diff`. It's cut with one line of context. If a hunk misses on Tools' tree, `python ratchet.py <tree>` does the same replacements on whatever version of the four files is there, and refuses if any of them assigns the exchange. Camera's: `git -c core.autocrlf=false -c core.eol=lf apply camera-swing-read.patch`, after Camera's swing-4-sim.

## Proof

On my stack, with my switches off and on: golden byte-identical, Orb's second match reproduces all 40 checkpoints and its final hash, and the director's checks are as before. The numbers are in the report.
