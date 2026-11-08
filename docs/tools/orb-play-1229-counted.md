# Orb's 1229 play again, counted as presses (Tools, 2026-11-07)

The EP's two rules for the ledger (tools/feel/feel.gd, ledger mode), applied to the same match on the same tree (e80b8e3d; it reproduces exactly: final hash 0ba7d303c755c467). Rows: `orb-play-1229-ledger-counted.txt` and `.json`. The first count is `orb-play-1229-report.md`.

1. **A press is counted once across a hit-stop.** A press of one kind on consecutive ticks is the same press, offered again each tick of the freeze and answered on the first live tick (Encounter, refusal-reasons). 399 such repeats are no longer counted as presses; the ledger header says so. A real mash cannot press on consecutive ticks (a tap lasts several ticks), so the rule does not hide one.
2. **A held guard or an open dodge is honoured.** A guard press is honoured when the fighter's guard is up after it (27 presses); a dodge press when a dodge is open (41 presses). Neither makes a cue of its own, which is why both read as silent before.

| | Presses | Honoured | Silent | Refused | Partly | Not honoured |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| First count (a row per recorded tick) | 1,159 | 737 | 363 | 44 | 15 | 422 (36%) |
| Counted once, guard and dodge read | 760 | 644 | 61 | 41 | 14 | 116 (15%) |

By kind after the rules (presses: honoured / silent / refused / partly): heavy 296: 250 / 23 / 21 / 2; sig 226: 192 / 16 / 16 / 2; light 69: 65 / 2 / 1 / 1; dodge 56: 51 / 5 / 0 / 0; guardPress 32: 30 / 2 / 0 / 0; right-stick starts 69: 55 / 2 / 3 / 9; powerPress 8: 1 / 7 / 0 / 0; transform 3: 0 / 3 / 0 / 0; context 1: 0 / 1.

What is left silent (61): 44 in locked exchanges, 11 free, 5 launched, 1 down. By kind: heavy 23, sig 16, powerPress 7 (6 of the 8 power presses), transform 3 (all of them), dodge 5, light 2, right stick 2, guard 2, context 1. The refusals are as before: press_stunned y 17 and b 10, stick/late 6, stick/0 4, driver_refused 5.

The right stick after the rule: away 41 (0 silent), down 19 (1 silent, 4 partly, 1 refused), up 4 (1 silent), toward 5 (0). The down flick, Orb's "slam" try, was 34 rows and is 19 presses.

Reading it: the 36% was mostly one press counted once per tick of a freeze. The press that is still not answered is the power press and the transform (nothing in the ledger answers them), then heavies and signatures in locked exchanges. Not a measure of whether a press did what Orb meant: a press that works without a cue of its own and is not a guard or dodge still reads silent.

## The counting rule beside the 15% figure (2026-11-08, for the build after Encounter's press-answers)

The 15% (116 of 760) was read on e80b8e3d, which has no power or transform answers: a power press had no cue to answer it and a transform with no form said nothing, so those presses could only be silent. The ledger now counts Encounter's press-answers (docs/director/pending/press-answers) as answers: the cues `power_start` (a charge began) and `power_burst` (a burst fired), the `transform` event (he took the form), and `press_refused` with the reason `not_ready` (a transform with no form: a refusal with its reason, which is not silent; its verdict stays "refused" unless the EP rules it honoured). Each row now carries `pa` (how many of its answers were these) and `paOnly` (answered only by them), and the ledger's header prints, for a build with the cues, the number answered only by them and the not-honoured percentage both ways: with them counted, and with those presses taken as not answered (the old rule), so the before and after can be compared like for like. On e80b8e3d the same rule reads 0 such presses, and the figure is unchanged: 116 of 760, 15%.
