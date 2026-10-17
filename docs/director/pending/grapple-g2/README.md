# The grapple, slice G2: the tie-break, the time's first move, the AI's throws (parked, 2026-10-17)

Owner: Encounter Systems Director. Game Design's re-ruling of G1's reads (`docs/design/grapple.md` §9 and §6, ff68e994), on top of G1 (`../grapple-g1/`).
- **It sits behind G1's switch, `grapple.enabled`, which is false.** With it off, play is the same to the bit.
- **Built and read in scratch. Not applied.**

## To build it

`node g2.cjs <root>` from this folder, after G1's `gr.cjs` (or on main once G1 is in).
- `--check` reads every anchor and writes nothing; any other option is refused.
- It refuses without G1, and a second time.
- No new golden.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/grapple.gd` | Encounter | The tie-break by the tick; the time's first move; `_aiThrowQ` |
| `data/director/interrupts.json` | Encounter | `grapple.clinch.timeFirstMove` (20); `grapple.throw.ai` (down 1.0, up 0.7, across 0.7, careW 1.5, popR 3) |
| `tools/schemas/director-interrupts.schema.json` | **Tools** | The same keys |

## As built

**1. The tie-break.**
- When both pummel one pulse, the one nearer the pulse by the tick takes the step.
- The same number of ticks off moves nothing. (G1 compared sharp against not sharp.)
- The AI presses 3 or 4 ticks off, so half its tied pulses now move.

**2. The time.**
- At 90 ticks both part 1.5 bh.
- **The grip's leader takes a 20-tick first move**, and the brawl lets go. The other can't start an approach for 20 ticks (`MOVE_AT`).
- The lockout starts for both, since nobody was thrown.
- At even, nobody has the first move, and the brawl goes on, as in G1.
- The cue is `grapple_end`, with the text `time_lead`.

**3. The AI's throw** varies by what each throw hands it and by its care (§6). It is drawn by weights:
- **Down** (the bury) and **up** (open in the air) both hand it a launch, so they weigh half while it lacks the launcher's ki.
- **Across** sends him along the line and ends the brawl. Its weight is scaled by 1 + (−care) × 1.5 × the people within 3 bh of where he would land (over `WorldStructures.popNearRef`). So the hero sends him away from people and the Anti-hero towards them.
- The draw is keyed by the tie-up, the pulse and the slot.

**Not in G2:**
- vicious blows;
- the brace and the auto-brace (1e06319b);
- the leader walking the pair, and the pin;
- the carry;
- the throws through the planner;
- the AI's brace;
- the perfect catch;
- an interjection.

## What it read

In scratch on main b0542bae + G1 + this + launch anywhere + the forms holds. The probe is `probes/gp.gd`, with the grapple on in memory and launch anywhere on in the data. Ten full matches an arm, against medium.

**Gates, every switch off:** 35 of 35, and the golden is main's, byte for byte.

| Row (Game Design's §7) | Bound | Read |
| :--- | :--- | ---: |
| A stray moves the grip | never (hard) | **0** ✓ |
| A masher of A in the clinch, against a fighter who doesn't press | wins no more grip | **0 and 0** steps ✓ |
| A thrown fighter grabbed again inside 120 ticks | never (hard) | **0** ✓ |
| The AI's tech within its reaction time of the tell's start | never (hard) | **0** ✓ |
| The clinch's length, AI v AI | median 40 to 70, at most 90 | **65**, 90 ✓ (G1: 85) |
| Throws a match, AI v AI | 1 to 4 | **3.6** ✓: across 13, down 10, up 13 (G1: down only) |
| A throw's opening followed by a launch | 15 to 40% | **26%** ✓ (on launch anywhere; G1 on main: 9.4%) |
| Catch tells a minute, AI v AI | 1 to 3 | **1.2** ✓ |
| A player who uses only A, as it is meant | wins 10 to 35% | **0 of 10** ✗ |

- **AI v AI's ends:** 44 teched, 33 timed out with a leader (the first move), 24 timed out even, 36 throws.
- **The player who uses only A** wins the grip (275 steps to the AI's 175) and throws 19.6 times a match, all across, since his stick is neutral. But throws do almost no damage, and he never strikes, so he never wins a match. The band wants damage from grapples that the rules don't give, or a script that strikes too. Game Design's call.
- **The control** (A sharp on each pulse) has a median of 45 and throws 11.6 a match.
