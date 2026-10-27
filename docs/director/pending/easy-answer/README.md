# Easy's answer share (parked 2026-10-27)

Owner: Encounter Systems Director. Game Design's `rulings-2026-10-26.md` §2j items 43 and 44, on d7647634 (Simulation's calm-k, with its grant into `calm.gd` and `interrupts.json`; `ai.json` is as on a05e12e5). The share is drawn only under launch anywhere (`DirBrawl._laAnswerPlan`, called inside `DirBrawl.anywhere()`), which is off on main, so the golden doesn't move. `rally.linkWorth` stays 0.8.

## To build it

On d7647634 or later: `node ea.cjs <root>` from this folder. `--check` reads every anchor and writes nothing.

| File | Owner | Change |
| :--- | :--- | :--- |
| `data/director/ai.json` | Encounter | `levels.easy.brawl.anywhere.answer` 0.2 to 0.25; the `_brawl` note gains a line on `anywhere.answer` and why easy's is 0.25 |

No schema change: the key and its type are as before. Medium (0.25) and hard (0.4) are unchanged.

## Why

- `anywhere.answer` is the chance the AI guesses, when a rival's blow lands clean on it, that a launcher follows, and times its guard to it. Easy never guesses at a player's first launcher of a match (item 19).
- The pop dose (items 42 and 43, f2d8a697) made more of the newcomer's late launchers into sends, and his wins against easy rose to 97.0% on 200 matches, over the 95% ceiling.
- QA's read (`docs/qa/rally-read-fa6f727a.md`, fifth addendum): at 0.25 the newcomer against easy reads **88.5%** on 200 matches (Wilson 83.3 to 92.2), inside item 44's 82 to 92. Against medium he reads 27.5%, unchanged. The first-launch rows hold at 100%, and the masher reads 99, 39 and 0 at easy, medium and hard. At 0.3 he read 71.5%, so by item 44's rule 0.25 lands with no further read.

## What it reads

No new reads: QA's fifth addendum is the evidence.

- **Switches off** (a scratch export of d7647634 with the park): the golden is main's, byte for byte. Import clean, validate 275 files 0 errors, self-test passes. All 35 of Encounter's gate runs exit 0: npm, parity, determinism (and `--intro`), seam, anim_check, the lead, joint and held scans, cue, reads, hud, brawl cases, World's five tools, QA's run-all, flash worst and count, mash, the nine input tests and the loader. So do Rendering's 16 headless checks (cue with `--profile=spaced`; outline and cull need a window), split_sweep and campaign_episode. `ai.json` is unchanged on main from d7647634 to f60d15cf.
