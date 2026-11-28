# Grab and charges: Combat's review

Combat, 2026-11-28, on the EP's wave 1 brief. **Paper only.** It reviews Game Design's ruling (`docs/design/grab-and-charges.md`, 876fe030) and the stand-in's directive §4 (`docs/ep/proposals/combat-overhaul-directive.md`) against my grapple paper (`grapple-hybrid.md`, `grapple-pitches.md`) and the movesets (`energy-movesets.md`, the four kits). Encounter is building it now, behind `grabCharge`.

**Overall: keep the ruling.** It keeps the grapple Orb chose and takes away only what made it a stall. Four things need fixing before it ships, and nine grapple moments must survive the build.

## The four questions

**Does the clinch at 45 still read as a grapple? Yes.** Game Design's finding is the key: the clinch already judges only two pulses (at 20 and 40), so 45 removes nothing a player can do, only the 15 dead ticks after. You still see the tie-up, two pummel contests, the vicious blows and a throw at the time.
- **Two things get shorter:**
  - **The carry,** at half speed: about 1.9 bh instead of 2.5. A carry into a wall, and so the pin, needs the wall closer. I accept that.
  - **The vicious blows:** fewer fit in 45 ticks than the four allowed.
- **One thing never happened at 60 either:** reaching two ahead and then throwing on the next pummel needs a third judged pulse, so every throw is the leader's throw at the time. That's the same at 45. If Game Design wants the earned throw back, it's a third pulse at about 60, and that's the opposite of the cut.

**Does a grab-proof full charge break a kit or the gauntlet? It breaks no kit as written, but it's a real risk to the gauntlet, and three rule texts disagree.**
- **The gauntlet:** QA already measured that a pad that only charges wins 60 of 60 against Easy and Medium on the 9 November build (A-AI-10, `docs/qa/readings/README.md`). Making full charges grab-proof and the computer grab less both help that pad. Game Design's §5 names this as the risk and orders the levers, and I agree with the order. **Read the charge-only pad first, before the clip goes to Orb.**
- **The rule texts:**
  - **`energy-overhaul.md` E45** says "a heavy, a grab or a launcher ends the charge at any level". The ruling's C3 says only a heavy or a beam, once full. Is a launcher a heavy here? Game Design should say, and E45 should be amended to match under the switch.
  - **The kits' energy grabs** (Harbour Net, Rank Ring, Banner Snare, Crane Hook) are thrown from range and were designed as an answer to the held Driver (E125: "a heavy or a grab ends it"). With C3 they don't stop a full charge. That's consistent, but E125 needs the same amendment, and each kit's answer list should read "a grab only before full".
  - **The right stick's hold** has stages, not a single "full". The ruling speaks only of the heavy's tick 44. Game Design should say what "full" means for a stick charge and for a beam's charge: I'd take the last stage the fighter can reach.

**Does reversing the 2026-11-21 hold-break bonus fit my no-spam rule? Yes, exactly.** My rule (`grapple-pitches.md`): every grab shares one lockout, and a thrown fighter can't be grabbed again for a while. The bonus skipped the regrab wait, which is the one thing that rule forbids. Worth 1.0 with the regrab wait restored puts it back. The longer lockout and regrab wait (180 and 240) and counting misses keep to the same rule.

**Which grapple moments must survive?** The list below.

## Ruling by ruling

| # | Verdict | Note |
| :--- | :--- | :--- |
| G1, reach read at the press | **Change: only where A means the catch** | Game Design's own ruling (`stick-lands.md`): near, A grabs; anywhere else, A taunts. Read at the press, an A from the middle or far band must stay the taunt, not a miss with an open window. And the kits' thrown energy grabs aren't the melee catch: G1 must never apply to them |
| G1, a miss starts the lockout | **Risk** | One stray A at a body height locks out the grab for three seconds and leaves him open 20 ticks. Against the computer that's the point. For a player it may feel like a dead button. Suggest a miss at the press costs the open window but not the full lockout, and that Orb judges it |
| G2, a full charge is grab-proof | **Keep** | It rewards committing, and drops the 10-tick guess. No counter-hit multiplier is right |
| G3, clinch 45 | **Keep** | As above |
| G4, it ends in motion | **Keep** | Every throw already sends |
| G5, lockout 180, regrab 240 | **Keep** | It keeps to my no-spam rule |
| G6, hold-break bonus reversed | **Keep** | As above |
| G7, the computer slips instead of grabbing | **Keep, with a risk** | My repetition read (`pending/repetition/README.md`) found that after a send, the dodge template is 41 to 50% of what follows: "he's knocked back, I go after him, he dodges". 65 in 100 slips makes the computer dodge even more. Split the non-grab answers between the slip, giving ground (C2) and the guard, so it isn't always the same |
| C1, slower mid-band lunge | **Keep** | It reads better, as Game Design says |
| C2, give ground 4 bh | **Risk, needs the timing table** | Two interactions. **The brawl lets go past 4.5 bh** (`breakBh`), so a defender who backs off a charge can end the brawl. **And Orb's one full charge in the 9 November match missed because the rival walked out of reach** (Encounter's `second-play-read.md`). At 5 bh a second the defender is about 3 bh back by full charge, against a charged reach of 1.5, or 2.0 on time. So an on-time full charge may still miss. Game Design's §5 timing table has to answer this before C2 goes on |
| C3, once full only a heavy or a beam | **Keep, after the texts agree** | The launcher question and E45 and E125, above |
| C4, the timed release reaches further | **Keep** | No new marker, which is right |
| F1 to F4, fleeing | **Outside this review** | Brief 5's. Nothing in them touches the grapple |

## What Encounter's build must not lose

These are the grapple's moments, from Game Design's `grapple.md` and my paper. Each should still happen with `grabCharge` on:

1. **The shape Orb chose:** catch, then a clinch, then a throw (homework 20: "hybrid between catch and clinch, rule in favor of clinch").
2. **Blows beat grabs:** a blow that lands in the 10-tick tell stops it.
3. **A grab beats a guard,** and a catch on a guard or a wind-up before full starts the clinch one ahead. With fewer computer grabs, this is still the triangle's answer to a turtle.
4. **The throws by stick:** down buries him 20 ticks, the opening that starts a chain, which is Orb's own reason for the grapple; up sends him 4 bh, open 16 ticks in the air; across sends him 8 bh, into a wall the slam and a 24-tick stagger, on open ground the thrower's first move.
5. **The reversal:** a sharp pummel from two behind throws instead, with his own stick.
6. **The tech** (A within 8 ticks of the landing) and **the perfect catch** (no tell, one ahead).
7. **A stray voids the next pummel,** so mashing A in the clinch does no better than not pressing.
8. **Each fighter's throws and clinch looks:** Grist's hurl, turn throw, drive down and lift; Loupe's sling, back throw, spike and jolt. The computer still picks by personality: the hero up or turning, away from people; the Anti-hero into a building or the ground.
9. **No silent press:** an A in the lockout says "refused".

**One more, not the grapple's:** whether a hard landing buries depends on the crater's dig (my answer to the EP on 2026-11-23). The down throw's bury is the grapple's own and doesn't dig, so it's safe.

## For the EP to route

- **Game Design:**
  - G1, read only where A is the catch.
  - The miss lockout, for Orb to judge.
  - The launcher in C3 against E45.
  - "Full" for stick and beam charges.
  - E45, E125 and the kits' answer lists, amended under the switch.
  - The non-grab answers split three ways.
- **QA:** the charge-only pad before Orb's clip; the C2 timing table with a backing defender.
- **Encounter:** the nine moments above in the build's check.
