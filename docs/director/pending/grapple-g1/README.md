# The grapple, slice G1: the catch, the clinch and the throws (parked, 2026-10-17)

Owner: Encounter Systems Director. It builds steps 1 and 2 of `docs/director/grapple-director.md` section 8, plus the throws (part of step 5) and the AI's part of step 6. The rules are Game Design's (`docs/design/grapple.md`, re-ruled 2026-10-17) and the reads are Controls' (`docs/controls/grapple-input.md`, `SimPressRead.struggle_press`).
- **It sits behind a switch, `grapple.enabled`, which is false.** With it off, play is the same to the bit.
- **Built and read in scratch on main 15a833e5 (window 2 on it). Not applied.**

## To build it

`node gr.cjs <root>` from this folder (it copies the two new files and their `.uid` files), then the import, which registers the two classes.
- `--check` reads every anchor and writes nothing; any other option is refused.
- It stacks with the launcher window (`launch-anywhere/la.cjs`) and window 2 (`town-levers/`), in any order. Its anchors pass `--check` on both copies.
- With the switch off, the golden doesn't move, so it needs no new golden.

| File | Owner | Change |
| :--- | :--- | :--- |
| `sim/director/pulse.gd` | Encounter | New: `DirPulse`, the pulse rule for every timed contest. The beam struggle moves onto it when window 4 is re-based |
| `sim/director/grapple.gd` | Encounter | New: `DirGrapple`, the catch, the tech, the clinch, the throws, the exits, the lockout, the AI |
| `sim/director/brawl.gd` | Encounter | Seven hooks:<br>• X, Y and B in a tell or a clinch are spent<br>• the grapple's tick runs before the brawl's<br>• no boost-out and no walk-out in a clinch<br>• a blow landing in a tell stops it<br>• the brawl's end ends the clinch<br>• the AI's brawl input gives way to the grapple's |
| `sim/director/interrupt.gd` | Encounter | In a tell or a clinch a fighter has no guard press, context, reversal or dodge; only the burst breaks it. A in a brawl is the grapple's, not an empty press. The AI weighs no perfect block there |
| `data/director/interrupts.json` | Encounter | The `grapple` block: `enabled`, `catch`, `clinch`, `throw`, `lockout`, `noRegrab` (the keys G1 reads, Game Design's first values) |
| `data/director/ai.json` | Encounter | `brawl.grapple` by level: `catch`, `pummel`, `tech` |
| `tools/schemas/director-interrupts.schema.json`, `director-ai.schema.json` | **Tools** | The same keys |

## As built

**1. The catch.**
- **A tapped in a brawl, with his line free,** is the catch: a tell of 10 ticks from the press.
- **A blow that lands on him in the tell stops it.** Blows beat grabs.
- **At the landing:**
  - out of a light's reach, it misses, and he is open 20 ticks;
  - on a rival who is open (staggered, or open after a miss), it is **the throw at once**, by his stick;
  - on anyone else, it is **the clinch**: even, or one ahead for the catcher on a rival who guards, winds or charges. The wind-up is stopped, since armour doesn't stop a hand on the collar.
- **The tech:** the caught fighter's A within 8 ticks of the landing breaks it, and both part. An A of his during the tell is early and voids his tech, so mashing A doesn't tech.

**2. The clinch.**
- The grip runs from −2 to +2, in the catcher's favour. A pulse comes every 20 ticks from the tie-up; the clinch lasts at most 90 ticks.
- **Claiming a pulse.** A within 4 ticks of a pulse claims it, and within 2 is sharp (`DirPulse`).
- **Judging a pulse** happens when its window closes:
  - one fighter claimed it: he takes a step;
  - both claimed it: the sharper takes the step, and equal sharpness moves nothing.
- **A stray** (an A inside no window, or a second A in one) moves nothing and voids his next pummel. A voided pummel still claims its pulse, so a masher never steps.
- **The A press is Controls' `struggle_press` "letgo", on every layout.** On Simple that includes Guard, which matches Game Design's touch-Simple ruling: in a clinch, Guard is A.

**3. The exits.**

| Exit | When | What it does |
| :--- | :--- | :--- |
| **The throw** | His pummel at two ahead | **Down:** slammed to the ground and buried for 20 ticks, an opening (B is the launcher). From high in the air, he is thrown 4 bh down and is open for 16 ticks.<br>**Up:** 4 bh up and open for 16 ticks, an opening.<br>**Across** (toward, away or no stick): a knock-back of 8 bh, and the brawl ends.<br>A throw is never a launch, so it marks no freshness |
| **The reversal** | The one two behind lands a sharp pummel on the same pulse as the leader's throw | He throws instead, by his own stick |
| **The push-off** | A pummel with the stick away, from even or ahead | Both 3 bh apart, the brawl lets go, and the pusher has a 20-tick first move |
| **The time** | 90 ticks | Both part 1.5 bh, even, and the brawl goes on |
| **The tech** | As above | Both part 1.5 bh, even, and the brawl goes on |
| **A burst, or anything else that ends the brawl** | | Breaks it |

**The lockout:**
- 90 ticks from each attempt. For both fighters, it also follows a clinch that ends with nobody thrown.
- A thrown fighter can't be grabbed for 120 ticks.
- A press in either is refused, with the `grapple_refused` cue. A press while his line is busy is refused too.

**4. The AI.**
- **Its pummels** are drawn at the tie-up: on 40, 65 or 85% of pulses by level, 3 or 4 ticks off the pulse, so never sharp.
- **Its tech** is drawn as the tell begins, at 0.15, 0.3 or 0.45. It is pressed between its reaction time after the tell began and 8 ticks after the landing, never at the landing. At reaction 14 that is 4 to 8 ticks after it.
- **It catches** a rival who guards (once each 30 ticks of a guard), or who winds a heavy it has had its reaction time to see. The share is 0.02, 0.04 or 0.06 by level. **These are my first values; Game Design gave none.** At 0.2 the medium AI caught 8 times a minute.
- **At two ahead it throws down**, so the chain to its launcher can follow.

**5. The cues**, by the cue list's rules (`pending/return/cues.md`):

| Cue | `text` | Fields |
| :--- | :--- | :--- |
| `grapple_catch` | `tell` (`n` the landing tick), `stopped`, `miss`, `throw` (the throw at once) | |
| `grapple_clinch` | `start` | `k` the catcher's lead, `n` the tick |
| `grapple_pulse` | | `k` the pulse, `n` its tick, `amount` the catcher's grip |
| `grapple_pummel` | `step`, `sharp` or `void` | `k` his grip after, `amount` his ticks off the pulse |
| `grapple_stray` | none, or `early` (an A in the rival's tell) | `k` his grip |
| `grapple_end` | `thrown_down`, `thrown_up`, `throw_across`, `reversal`, `push_off`, `time`, `tech`, or the brawl's end reason (`burst`, `left`, ...) | |
| `grapple_refused` | `lockout`, `thrown` or `busy` | `n` the tick it ends |

- A press of X, Y or B in a tell or a clinch is a `press_ack` with the text `grapple`.
- The throws' openings send the ordinary `stagger` cue (`thrown_down`, `thrown_up`) and `launcher_open`.
- `DirGrapple.now(S, f)` gives UI and Animation the mode, the role, the grip, the last pulse and the tie-up tick.

**Not in G1 (G2 and later, in the paper's order):**
- vicious blows (X, Y and B in a clinch are spent for now);
- the brace and the automatic brace;
- the leader walking the pair, and the pin;
- the carry;
- the throws through the planner (the wall slam from a pin, a building's side);
- the AI's brace and its choice of throw by personality;
- the perfect catch;
- the catch out of a brawl;
- an interjection.

Two gaps on the build itself:
- A latched A's release isn't read as a press, because the sim can't see the latch. That is Controls' and Simulation's to route.
- Parting moves both fighters along the line without testing for a building's face.

## What it read

The probe is `probes/gp.gd`, with the switch turned on in memory. Ten full matches each, against medium; "AI v AI" is the default level on both sides.

| Row (Game Design's §7) | Bound | AI v AI | Notes |
| :--- | :--- | ---: | :--- |
| A stray moves the grip | never (hard) | **0** | in every arm, 963 clinches |
| A masher of A in the clinch, against a fighter who doesn't press | wins no more grip | **0 and 0** steps | **mash** against **idle**; the AI's steps a clinch were 1.60 against 1.66 |
| A thrown fighter grabbed again inside 120 ticks | never (hard) | **0** | 14 such presses refused |
| The AI's tech within its reaction time of the tell's start | never (hard) | **0** | |
| The clinch's length | median 40 to 70, at most 90 (hard) | median **85**, max 90 | **fails**: 64 of 135 end at the time |
| Throws a match, default arm | 1 to 4 | **3.2** | all thrown down: the AI's G1 choice |
| A throw's opening followed by a launch | 15 to 40% | **9.4%** | **fails on main**, where window 1's launcher rests 30 s after any launch, so most B presses there are the hammer. Read it again on top of launch anywhere, which retires the rest |
| A player who only taps A, against medium | wins 10 to 35% | **0 of 10** | **fails**: see below |

- **AI v AI's catches:** 152 tells in 90 minutes; 14 stopped by a blow, 2 thrown at once, 135 clinches. Of those, 41 teched, 32 thrown down and 64 timed out.
- **The control (A exactly on each pulse, so always sharp):**
  - its clinches have a median of 45 ticks;
  - it took 142 steps to the AI's 104;
  - it threw across in 118 of 171 clinches; the AI teched the other 53.

  So skill wins the grip.
- **The player who only taps A (every 8 ticks):**
  - 618 of his 964 catches were stopped by a blow;
  - in the clinch every tap is a stray or voided, since a tap every 8 ticks always leaves one outside a 9-tick window. He took 0 steps.
  - 6,765 presses were refused in the lockout.

  He never wins, by the stray rule itself. Game Design's 10 to 35% expects something the rules don't give him.
- **Why the clinches run long:**
  - The AI's pummels are never sharp, so when both AIs pummel a pulse nothing moves.
  - At medium both pummel on 42% of pulses, and the grip moves only when one pummels alone, on 45%.
  - So the time ends half the clinches.
- **Levers for Game Design:**
  - a lower AI pummel share;
  - a clinch of three pulses (60 ticks);
  - the time's exit as a parting with the grip's leader taking the first move.

**Gates (the switch off), on main 15a833e5 + gr.cjs:** the full list, 35 of 35. The golden is main's, byte for byte.
