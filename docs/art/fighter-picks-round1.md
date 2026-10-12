# Fighter picks, round 1: the Cyborg and the Empress

Owner: Art Director. 2026-10-12. Step 2 of `docs/art/fighter-design-workflow.md` (three silhouettes, the silhouette gate's number, one colour search across the four lanes) for the Demon Cyborg and the Empress, so Orb can pick both in one sitting. Concept art, working labels, **pending Legal review**. **Kept on this PC only: no in-progress character art goes on a public page or in the public repo (Orb, 2026-10-06).**

**Sheets (one per fighter, for Orb):** `art/concepts/picks/cyborg-picks.svg`, `art/concepts/picks/empress-picks.svg`. **Numbers:** `art/concepts/picks/picks-numbers.json`. Regenerate: `node art/concepts/picks/gen.mjs` (deterministic, no packages); the lanes alone: `node art/concepts/picks/lanes.mjs`.

## What Orb is choosing

| | Who he is in a fight | The silhouette | Gate | Dearest part |
|---|---|---|---|---|
| **Cyborg 1, the Press** | The grappler: slow to look at, then on you; catches you between his plates | The broadest body in the roster with one big lid slab raised behind it | clears (0.658, 0.656) | Nothing in the rig: 5 rigid parts, no bones; about 20 grab poses |
| **Cyborg 2, the Courier** | The fastest thing in the room; in, a strike, gone | The tallest and slimmest, a tower of strapped boxes above the head | clears (0.627, 0.703) | Camera headroom (about 12 percent); about 30 dash poses |
| **Cyborg 3, the Hopper** | The devourer: a funnel that is also a body, feeding as it fights | A top-heavy inverted triangle with a flat rim | short (0.576, 0.700) | A two-draw funnel (the head sits inside); arms need a clearance rule |
| **Empress 1, the Regent** | The patient duellist; the hem is her tail | A tall column with one long low sweep along the floor | clears (0.631, 0.670) | The chain solver (specified, not built); without it a rigid board |
| **Empress 2, the Bell** | The court in one body; she punishes what steps into the cloth | A wide, low triangle with the legs under cloth | short (0.547, 0.568) | The dearest: 1.7 times the Protagonist's screen area, cloth both sides, a cloth-over-legs rule |
| **Empress 3, the Tabard** | The counter; she wears her answer in front of her | A stiff panel hanging forward from the shoulder to the knee | just short (0.611, 0.647) | 3 hinged plates and a fold rule; the panel must stay below the elbow |

The three Cyborgs are three different answers to "generic", not variations: mass, speed, consuming. The three Empresses are three different places for the mantle: behind and low, wide, in front. The hem is her tail in all three (Orb's "bladed mantle").

## The gate's number

`distance = 1 - overlap` of two flat-black silhouettes, feet on one line, at the best horizontal alignment within 14 px and either way round, each fighter in his or her pose in play, at 46 and 86 px. **The launch pair are 0.620 apart** (the same at both sizes). A new fighter passes if he or she is at least 0.620 from both of them. It is a conservative number: a body inside a larger shape counts as overlap, so a cloth bell round a figure scores low even though it reads apart at a glance by mass. Read the three verdicts as "worth another look" (short, just short), not as a rejection.

Areas at 46 px (px²): Protagonist 434, Anti-hero 392; Press 602, Courier 420, Hopper 514, Regent 427, Bell 756, Tabard 456.

## The four lanes (one search)

The Protagonist's and Anti-hero's auras are fixed (`#8fd6ff`, `#9a80d8` and the presets). The search (`lanes.mjs`, a fixed grid) finds the Empress's and the Cyborg's against every other fighter, the wound and guard marks and the sky near the fighters. A margin of 1.00 is exactly on the rule (between fighters 25 default and 20 simulated; marks 20 and 14; sky 20 and 12).

| Look | Empress | Cyborg | Between them | Worst margin |
|---|---|---|---|---|
| default | `#3c7d1c` (moss green) | `#47d7a7` (terminal green) | 30.6 | 1.22, clears |
| protan | `#446b7e` | `#80cc33` | 48.9 | 0.86, short |
| deutan | `#1f7a7a` | `#a9d1bd` | 32.5 | 0.78, short |
| tritan | `#5c7a1f` | `#8bcb0b` | 24.9 | 1.04, clears |

**What the search found**
- **The old proposals fail.** The Empress's olive `#b8c96a` is 12 from "bruised" by default and 3 from "battered" under protan; the Cyborg's coral `#d8705f` is 16 from "broken" by default and 5 under tritan.
- **No colour makes four lanes work under protan or deutan vision.** Red and green collapse together, and every mid colour sits near a wound mark or a sky band. The best the search reaches is 0.78 to 0.86 of the rule, so for those two the **non-colour marks carry the fighter**: the ring, the slash, and now a chevron (the Empress's three-chevron sigil) and a bar (the Cyborg). They are different glyph families, as the rule in `marks.mjs` asks.
- **The Empress's ring is the dark one and the Cyborg's the light one in every preset**; lightness survives every simulation, hue does not.
- **Pink and crimson for the Cyborg were tried** and fail at 0.55 to 0.75 of the floor against "broken" and the night sky; a steel grey fails against "fresh" (UI's neutral). His body stays dark red (as the Anti-hero's is red under a violet ring), so the ring need not be.
- **The cost of the Cyborg's green:** it sits 31 from the Protagonist's pale cyan in the default look, inside the Protagonist's "cool, green to blue" family (hue 150 to 250). **Legal to say** whether that family is a lane or a range; if a lane, there is no good colour left outside it (pink and crimson fail against "broken"; the best out-of-family choice is a pale pink at 0.99 of the floor in the default look and 0.78 under deutan), so the answer would be a body-colour lane with the bar mark and no distinct ring colour.

## Questions for Orb (one sitting)
1. **Cyborg:** the Press, the Courier or the Hopper (or one hook from another)?
2. **Empress:** the Regent, the Bell or the Tabard (or a mix)?
3. **Colour:** is a green for the Cyborg all right (the body stays dark red), given red and pink cannot work as a ring?

## What goes to Legal
- With Orb's pick: the brief for each (step 1 of the workflow), the colour changes, and that **RL-045's old conditions on the Cyborg (scan bars, pips, a paler peach) are moot**: they were for the masked face, and masks are parked.
- Named: the Hopper's flat rim and the Regent's low collar flare against the horn and antenna rule; the Cyborg's feeding mechanics are a separate screen (RL-111).

## Limits of this round
- The figures are the kit's side-on concept models, not the game's bodies; the gate's number is the one in `measure.mjs`, not a Rendering measurement. A still from the build is step 8.
- Triangle counts, pose counts and rounds are estimates.
- The six are silhouettes and parts, not faces: the unmasked face set is step 4, after Orb's pick.
