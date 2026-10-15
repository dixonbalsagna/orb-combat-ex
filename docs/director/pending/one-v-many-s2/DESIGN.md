# One versus many, stage 2: the partner and the ring (design, waiting for stage 1)

Owner: Encounter Systems Director. Date: 2026-10-15. Stage 2 of `docs/director/one-v-many.md` section 5. **Design only: it is built when Simulation's stage 1 lands** (`docs/architecture/pending/n-bodies/`, not there yet). It is written against the interface the paper assumes, listed in section 1, so Simulation can say where its park differs.

## 1. What stage 2 needs from stage 1

| Need | What I write against | If stage 1 differs |
| :--- | :--- | :--- |
| Bodies | `S.fighters` holds 2 to 5, slots 0 to 4, each with `f.act.dirI` | Any count; slots stable for a match |
| Sides | A side for each fighter: `f.side` 0 for the one, 1 for the many (or a match setup that says which slots are the many) | Any field or setup key that tells the one from the many |
| Input | `SimCore.step(S, intents)` with one intent (or null for the AI) for every slot | As stage 1 has it |
| The AI | `f.ai` for each AI body, as today | Same |
| Hash, replay, the golden | Stage 1's: every fighter hashed, every slot's input replayed; 1v1 byte-identical | Same |
| The default opponent | `SimRoster.opp` as stage 1 leaves it | The director stops calling it where it means "the one I fight now" (section 3) |

## 2. The roles, and where they live

A new module, `DirRing` (`sim/director/ring.gd`), with its own block of each fighter's director integers after the brawl's. Nothing of it runs with two bodies: `DirRing.on(S)` is false, nothing is resized, nothing is drawn, so every 1v1 match and golden is unchanged.

| Integer | On whom | What |
| :--- | :--- | :--- |
| `ROLE` | Everyone | 0 none (1v1), 1 the one, 2 the partner, 3 in the ring |
| `ROLE_AT` | Everyone | The live tick the role began |
| `PARTNER` | The one | His partner's slot plus 1 (0 none) |
| `TAG_AT` | The one | The live tick of the last tag |
| `GRANT_AT`, `GRANT` | The one | The live tick of the last interjection granted, and the slot plus 1 of the guard it was granted to while it is in flight (stage 3 uses them; stage 2 only refuses) |
| `THREAT_AT` | A ring guard | The live tick of his last feint, step or threat |

**The data** is a block of its own, `ring`, in `data/director/interrupts.json`. Every value is a first one: `enabled` true; `ringBh` [4.5, 6.5] (outside the brawl's break of 4.5 bh, inside the close band's edge of 12.5); `tagMinTicks` 30; `sliceS` 6; `threatEveryS` 3; `interject` {`everyS` 1.5, `clearTicks` 8, `kinds` ["light"]} for stage 3.

## 3. `DirBrawl.partner(S, f)`, and the call sites

`partner(S, f)` is the one fighter `f` fights now: with the ring off, `SimRoster.opp(S, f)` exactly as today; on, the one's partner for the one, and the one for every guard. The 47 sites the paper counts (26 `opp` calls and 21 "the other one" expressions) are read one by one:
- where they mean "the one I fight now" (a blow's target, the run, the bands' distance in a brawl, the AI's rival in a brawl): `partner`;
- where they mean "the other fighter of this exchange": unchanged. An exchange stays a pair, `A` and `D`;
- where they mean "anybody else" (a launch's obstacles, the camera's pair, a world rule): left for stages 4 and later, and listed.

## 4. The rules

**Who the one fights.** On every press of his, before the exchange is asked: the guard his stick points at within 45 degrees and within striking distance; else his partner; else the nearest guard in front of him. A choice of a new guard is a tag (below), and the press goes to the new partner as one blow.

**The tag.** A ring guard becomes the partner when the partner is sent (a launch, a knock-back, a wall slam), when the one picks him (above), or when the partner has held the one for `sliceS` with nothing decisive. The next partner is the ring guard nearest the one, in front of him first. At most one tag in `tagMinTicks`: a choice inside it waits, and the press still goes to the partner he has. On a tag, the outgoing partner's brawl integers are reset and he takes the ring role; the one's run carries or is reset by Game Design's word (the paper's open question; first build: reset).

**The ring.** A ring guard never asks for an exchange. The exchange's start refuses it (`press_ack`, `ring`), so an AI that tries costs nothing and is counted. Its AI holds the ring band around the one: on the plane it takes the side with fewer bodies; with depth on, the near or far line. At least every `threatEveryS` it makes a threat: a step in to the band's inner edge and out, a feint (a wind-up cue with no blow), or a guard raised at the one's back. So nobody stands idle.

**A press stays one blow.** The one's press is one blow at one guard. A guard's press counts only while he is the partner. The exchange stays the one and his partner, so `S.dirS.ex` stays one exchange.

## 5. The proof rows for stage 2

| Row | Bound |
| :--- | :--- |
| Every 1v1 golden | Byte-identical |
| A 3-body match (the one and two guards, the AI on all three) run twice | The same hashes to the last tick |
| Every press of the one puts exactly one blow on its way | Every one, in 3v1 and 4v1 |
| No press of the one is lost on a tag | None |
| A ring guard lands a blow | Never (stage 3 adds the granted one) |
| Tags | At most one in 30 ticks; at least one a minute of brawl (the fight moves round the ring) |
| A ring guard's threats | At least one every 3 s |
| The cost a tick at 3, 4 and 5 bodies | Measured, against the paper's estimates (0.77 ms and 0.92 ms on Orb's PC) |

## 6. What I build first when stage 1 lands

`DirRing` with `on`, the roles and `partner`, and the call sites. Then the exchange's refusal and the one's targeting, then the tag, then the ring's AI. Each piece keeps 1v1 byte-identical and is gated before the next. The probe that reads the rows above comes with the first piece.
