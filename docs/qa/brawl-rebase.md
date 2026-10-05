# Rows counted per exchange, re-based for the brawl, and the brawl harness (QA, 2026-10-05)

Status: built and smoke-tested on an export of e6f51bd (a few matches each, to show every row reads; not a baseline). The bands below are QA's proposals for Game Design to confirm. Read: `docs/director/brawl-b1.md`, `docs/design/melee-press-feel.md` sections 3, 9 and 9d.

## 1. The rows that counted exchanges

A brawl is one exchange of many blows, so a row per exchange reads a different unit than it was banded on. B1 reads 14.0 exchanges a minute (band 15 to 28), 17.9 perfect blocks per 100 melee exchanges (5 to 15), and 44.7% knock-backs and 35.2% "continues" of launch decisions (25 to 35 and 40 to 50). They stay in the baseline as they are, for the comparison with every earlier one, and these are reported beside them (`bands.js`, rows `7.pb.perblow`, `10.brawl.perMin`, `10.brawl.len`, `10.brawl.ends`; from `records.gd`'s `rec.brawl`, built from the brawl's `blow`, `stagger`, `trade_break` and `brawl_end` cues).

| Old row | Old band | Proposed basis | Proposed band (to confirm) | Why |
| :--- | :--- | :--- | :--- | :--- |
| Perfect blocks per 100 melee exchanges, easy / medium / hard | 3-8, 5-15, 12-20 | **Perfect blocks per 100 blows thrown** (brawl blows plus the strikes of planned exchanges) | The old band divided by the exchange's old length, 2.3 blows: about 1.3-3.5, 2.2-6.5 and 5.2-8.7 | The old band meant "a perfect block per so many melee contacts", and an exchange had 2.3 of them. A smoke run reads 2.46 per 100 blows for the medium AI on B1 |
| Exchanges started a minute | 15 to 28 | **Brawls a minute, and blows a minute** (reported); the brawl's own bands replace it: share of fight time in a brawl 45 to 60%, median brawl 6 to 12 s, 10 blows or more (B5) | Retire the old row when the planned exchange is gone (B5); until then report | A brawl has no set length, so a count of them says nothing about tempo; the blows a minute (about 100 on B1) and the time share do |
| Exchanges that end in a knock-back, of launch decisions | 25 to 35% | **Shares of brawl endings** (`brawl_end` text: knockback, launch, reversal, perfect_block, signature, break, apart, idle, ...) | Knock-back share of the endings that separate the fighters (knock-back plus launch) 55 to 75%, launch 25 to 40% (the launch share of separations keeps its band) | Only an ender reaches a launch decision in a brawl, and an ender knocks back, so the old denominator is the wrong set |
| Exchanges after which the brawl continues (STAY), of launch decisions | 40 to 50% | **Retired in a brawl:** a brawl continues until it ends | Replaced by the brawl's median length and blows (above) | "Continues" has no meaning when the brawl is the unit; the old row stays for the planned exchanges that remain |
| Chains per 100 melee exchanges | 10 to 30 | Strings per brawl, and closes a minute (reported) | Reported until Game Design sets a band | The chain window and its links are gone (B1) |

## 2. Game Design's new rows (sections 9 and 9d), where each is read

| Row | Band | Where | Built as |
| :--- | :--- | :--- | :--- |
| The lights-only mirror finishes | at least 95% | `masher.mirror`, `masher.mirror.tick` | `players.gd`, two mashers |
| Brink to KO, median | 30 to 55 s | `masher.brink`, `masher.brink.tick` | |
| Share of closes made by the fighter on the brink, while only one is on it | 10 to 40% | `masher.brinkcloses.tick` | closes are `stagger` cues of text flurry, the closer is the cue's target; the brink is tracked from `brink_enter` and `brink_exit`; PENDING under 20 closes in the count |
| Matches won from the first slot | 40 to 60% | `masher.firstslot.tick` | the winner's slot (0), over decided matches; the interval at 60 matches is about +-13 points |
| An even mash: level trades that change who has the momentum | 5 to 15% | `masher.momentum.tick` | an approximation: counts every trade break after a first close whose breaker is not the last closer. **A lead of 2 also takes the close, so this is not only level trades. Encounter to add the two runs to `trade_break` (`x` and `y`) and the row becomes exact** |
| A trade breaks on the tick of its limit | every break (a hard test) | `masher.tradelimit.tick` | `trade_break.n` against `flurry.tradeMaxTicks` (read from the build's data). A trade that runs past the limit without a break event is not seen |
| From a trade's break to its close or the brawl's end | at most 24 ticks (a hard test) | `masher.breakclose.tick` | counted on `S.tick` |
| A masher tapping every 8 ticks of `S.tick` against the medium AI | 35 to 50% | `masher.medium` (the banded row now taps on `S.tick`; `--clock=live` is the old script) | `masher.gd` |
| The same at 6 and 10 ticks | reported | `masher.medium.g6`, `masher.medium.g10` | |
| A faster masher against a slower one (6 against 12): closes a minute | reported | `masher.fastslow` | `players.gd` `masher:clock=tick:gap=6` against `:gap=12` |
| Two mirrors | | the live-tick mirror (as every earlier baseline) and the S.tick mirror | Game Design's rows are read on the S.tick mirror, the real tap rate; the live-tick one is reported beside it |

What a 10-match smoke on B1 (e6f51bd) shows, to prove the rows read and that they see B1's known problems: the S.tick mirror finishes 10 of 10, brink to KO 32.8 s, every close while one fighter is on the brink made by the brink fighter (29 of 29; band 10 to 40), the first slot won 0 of 10 (band 40 to 60), no trade break changed hands (0 of 413; band 5 to 15), every trade broke on the limit (444 of 444) and none took more than 24 ticks to its close. A 6-tick tapper against a 12-tick tapper: 79.5 closes a minute against 0, and the faster tapper wins 10 of 10. These are the ruled repairs of section 9d (momentum, staggered blows adding nothing), not yet built.

## 3. The timed script under the brawl (built)

`players.gd`'s tapper now presses inside a brawl against `DirBrawl.beatAt(S, f)` (the `S.tick` its blow on its way lands, and in B2 its beat point): a new blow in flight plans the next press at that tick plus the script's offset (the same `acc`, `win`, `jit`), never sooner than `mingap` ticks (default 14: a rhythm player throws one blow at a time, taps slower than 12 ticks are not a flurry) after its last press; with the line free it starts the next blow after `idle` ticks (default 24). `DirBrawl` is loaded dynamically, so the script still runs on a build without it. It presses 296 times a match against 750 for a masher (the timed script is no longer blind; `SCRIPT BLIND` fires under 100), and reads 0 of 10 against a masher on B1: a rhythm player at one blow every 14 to 24 ticks loses to an 8-tick flurry until the skill strike (B2) pays for the beat. The director's on-beat read (the press's graded beat in the director's own log) is 17% on B1: the beat is the contact itself until B2 adds the beat point, so the on-beat share is not a measure of the script until then.

## 4. The masher on `S.tick`

`masher.gd` takes `--clock=tick` (the default) or `--clock=live`: the tap is due when `S.tick % gap == 0`, and a press the freeze holds keeps `waited`. The banded row is the 8-tick script; 6 and 10 are reported (`masher.medium.g6`, `.g10`). A 20-match smoke on B1: 8 ticks 10 of 20 against the medium AI; 6 ticks 10 of 10 in 10.
`players.gd`'s `masher` takes `clock=tick` too (`masher:forms=1:clock=tick:gap=6`).
