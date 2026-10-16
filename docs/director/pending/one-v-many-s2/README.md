# One versus many, stage 2: the partner and the ring, parked (2026-10-15)

Owner: Encounter Systems Director. Stage 2 of `docs/director/one-v-many.md`, built as `DESIGN.md` in this folder describes it, on Simulation's stage 1 (`docs/architecture/pending/n-bodies/`). **Built, read and gated in scratch on main dfcb3ca1 with stage 1 applied. Not applied.**

## To build it

On main (stage 1 is on main since 06b0200e): `node s2.cjs <root>` (it stops unless stage 1 is in), then an import (`DirRing` is a new class).

| File | Change |
| :--- | :--- |
| `sim/director/ring.gd` | New: `DirRing` (this folder's `ring.gd`) |
| `sim/director/ai.gd` | A ring guard's stick is the ring's (`DirRing.aiInput`): 3 lines |
| `sim/director/exchange.gd` | A ring guard's press is refused (`press_ack` `ring`) and the one's press picks its guard first (`DirRing.mayPress`); the roles and the tags once a tick (`DirRing.tick`): 4 lines |
| `sim/director/*.gd` | The 26 calls of `SimRoster.opp` become `DirRing.partner`, which is `SimRoster.opp` exactly with two bodies |
| `data/director/interrupts.json` | `brawl.ring` |
| `tools/schemas/director-interrupts.schema.json` | `brawl.ring`, an optional key, for Tools |

## As built

- **Roles.** Slot 0 is the one, slot 1 his first partner, every other slot in the ring, as stage 1 places them. Nine integers a fighter after the zip's, written only with more than two bodies.
- **The tag** waits for a quiet moment: no exchange running and none on its way, the one free and not sent, and nothing of the outgoing partner's still to land (no shot in flight, no blast winding up). Then a partner who is sent hands over to the nearest ring guard, so does one who has held the one for `sliceS` (6 s), and so does one the one's stick turns from (a guard within 1.5 bh past striking distance and 45 degrees of the stick). At most one tag in `tagMinTicks` (30).
- **The ring** keeps the band `ringBh` (4.5 to 6.5 bh) round the one, on the side with fewer of the many, level with him, a body height further out for each ring guard on his side before him. Every `threatEveryS` (3 s) a guard steps in to the band's inner edge, for at most `stepInTicks` (45), and out again. He never presses.
- **The hit-stop** is stage 1's, one for the whole match.
- **Not built:** the interjection (stage 3); a sweep that hits several; a guard knocked out leaving the match (any KO still ends it, stage 5).

## Re-based on main 4db309ea (2026-10-16)

Stage 1 is on main as Simulation committed it, and `s2.cjs` applies to it as it is: nothing in this folder changed. On a fresh export of 4db309ea:

- **The 1v1 golden is main's, byte for byte.**
- Parity and determinism, plain and with intros, all pass. The validator passes.

The probes on the same seeds:

| Row | 3 bodies | 4 bodies | 5 bodies |
| :--- | ---: | ---: | ---: |
| Blows that land on the one, a second of brawl | 5.50 | 5.70 | 5.54 |
| The brawl's share in hit freeze | 25.7% | 26.4% | 25.8% |
| A blow from a ring guard lands on the one, in 20 minutes | 7 | 1 | 2 |
| The scripted one's blows a press | 0.764 | 0.713 | 0.709 |

- At 3 bodies the stray ring blows rose from 2 to 7, and five of the seven are landings (`impact`).
- Stage 3 closes every way a ring blow lands: it reads 0 at every count (`../one-v-many-s3/`). The two stages land together.

## What it read (on stage 1's park, 2026-10-15)

`probes/ring1.gd` (the AI on every body) and `probes/ring2.gd` (the one is a scripted player, X every 8 ticks, stick toward his partner), 4 and 3 matches of up to 5 minutes for each body count, seeds 1 to 4.

| Row | 3 bodies | 4 bodies | 5 bodies | Bound |
| :--- | ---: | ---: | ---: | :--- |
| The 1v1 golden | Byte-identical | | | Byte-identical |
| Parity (55 checks, stage 1's among them); determinism; the validator's self-test | Pass | | | Pass |
| A match played twice | The same state hash at its end | The same | The same | The same |
| Blows that land on the one, a second of brawl | 5.53 | 5.46 | 5.45 | About a 1v1's (5.76) |
| The brawl's share in hit freeze | 26.4% | 26.4% | 25.7% | Under 32% (a 1v1's is 26.6%) |
| A ring guard's press reaches an exchange | Never (0 refused: the ring's AI doesn't press) | Never | Never | Never |
| A blow from a ring guard lands on the one | 2 in 20 minutes | 1 | 1 | Never: see below |
| Tags a minute of brawl; the closest two | 7.7; 43 ticks | 18.3; 34 ticks | 20.2; 30 ticks | At least 1; at most one in 30 ticks |
| The longest a ring guard goes without a threat, standing free in the ring | 3.0 s | 3.0 s | 3.0 s | 3 s |
| The scripted one's blows a press (a 1v1: 0.788) | 0.788 | 0.678 | 0.702 | |
| The cost a tick, mean and 99th percentile (Orb's PC, other sessions at 28 to 57%) | 348 µs; 1.0 ms | 402 µs; 1.1 ms | 449 µs; 1.15 ms | The paper's estimates: 0.62, 0.77, 0.92 ms |

- **Two touch him at a time, and it shows.** He is hit as often as in a 1v1 and stands in freeze as long, at 3, 4 and 5 bodies.
- **The cost is well under the paper's estimate:** 4v1 costs 449 µs a tick on average, where the paper allowed 0.92 ms. On a machine three times slower that is about 1.35 ms mean and 3.5 ms at the 99th percentile. So 4v1 is within reach on the cost side, and the paper's reason to hold it back weakens. The fighting guard's AI is in these numbers; stage 3's interjection is not.
- **The stray blows went from 96 to 4.** The first build tagged at any moment without an exchange, and a partner's landing, approach, blast or shot then landed from the ring. The quiet-moment rule closed nearly all of it. The four left are three blasts and a light, from paths I haven't traced. Stage 3's grant has to own every blow from the ring anyway, and I trace them there.
- **The one's press is never refused by the ring and never split.** At 4 and 5 bodies a tenth fewer of his presses become blows, because after a tag his new partner stands 4.5 to 6.5 bh off and a press there is an approach, where a 1v1 rival is usually in reach. **For stage 3:** the new partner steps in to striking distance on the tag.

## For the window

Stage 1 first (Simulation's), then this, one regeneration of nothing: the 1v1 golden doesn't move. Its own golden match (3v1) comes with it if the EP wants one now. Gates as above, plus the full list.
