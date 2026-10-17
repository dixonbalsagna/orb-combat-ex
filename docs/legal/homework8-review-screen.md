# Homework 8 reviews: run endings, two rival lines, the lint's sensitive words, the place names, the grapple held poses and the hybrid picks

Owner: Legal and IP Compliance. 2026-10-16. Screens Narrative's `docs/narrative/run-lines.md` §3, `story-beats.md` §6, `line-lint.json` and `place-names.md`; Combat's `docs/combat/grapple-hybrid.md`; and Art's hybrid picks (`homework/fighters/PICK-hybrids.md`, local only). A screen, not legal advice. RL-146 to RL-152; new rows g06 to g08, h09, w06, c10.

## 1. The run endings (run-lines.md §3): **Pass**
Seven short ending beats (three planet states, three branch histories, a darkened sky).
- **c08 is met.** The toll is a count and the planet's state ("Half the planet's people are gone"), never bodies or a close-up; no line scores it, cheers it or jokes about it; the most-alive ending names who is safe. No school, hospital or place of worship; no child as a victim.
- **c07 is met.** "The ash is slow to fall" is plain; no "nuclear", "atomic", "bomb", "radiation", no real city or event, no siren or countdown.
- **Tone, not law:** quiet and sorry is the right register for a Mature-rated game that tallies civilian deaths; boards treat a grim, un-rewarded tone as a point in the game's favour. Answer Narrative's question 1 as you like.

## 2. The two rival lines (story-beats.md §6)
"Good. That's the look I wanted." (`witnessed_enter`) and "Finally. Now you look like you mean it." (`casualties_rival_many`).
- **Not a legal block.** A villain who is cold about deaths is within a Mature game, and neither line names a death, a victim or a score. c08's concern is the *game* rewarding or celebrating civilian deaths, not a character being callous.
- **But Narrative's worry is right, as a caution rather than a rule.** Both lines land straight after deaths, and "Good" and "Finally" read as pleased with the result. A board or a reviewer quoting them out of context would write "the villain is pleased the civilians died", which is the one headline c08 exists to avoid.
- **Recommendation: use the alternates** ("There it is. Now fight me." and "Now you look like you mean it."). They keep the rival's impatience and point at the fight, not at the look the deaths produced. If Orb marked the originals in homework 27 and likes them, keeping them is allowed; they are a writing choice, not a legal condition (`writing-note.md`).

## 3. The lint's sensitive words: **Pass with additions**
The listed words (nuclear, atomic, bomb, siren, countdown, radiation, school, hospital, church) cover c07 and c08. Suggested additions, in two tiers so the lint does not choke on ordinary words:
- **Block (always a fail):** "A-bomb", "H-bomb", "mushroom cloud" (c07 says call it a blast cloud), "fallout", the names of real events and places of mass harm (for example Hiroshima, Nagasaki, Chernobyl, Fukushima, 9/11, "ground zero"), "holocaust", "genocide".
- **Review (a human reads the line):** other places of worship (mosque, synagogue, chapel, cathedral; "temple" is review only, since it is also an ordinary word), "kindergarten", "nursery", "orphanage", and "child", "children", "kid" near a casualty word (died, dead, gone, lost, killed, victims); "meltdown".
- **Whole-word matches** (so "bombardment", a c04 term, is not caught by "bomb").
- The same list guards place names and every generated line. Row c10.

## 4. The place-name table
I rebuilt the names from the banks in `pending/place_names.json` (biome stems, city stems, suffixes) and checked each against the GeoNames list of every town and city over 15,000 people.
- **The count:** the banks generate **1,569 distinct names** (532 city, 477 town, 560 landmark), not 1,680. If the table file lists 1,680, about 111 are duplicates or come from a bank I did not read; Narrative should re-run the check on the table's own list.
- **No vulgar, slur, worship or school substring** in any name (the c07/c08 list included).
- **Eleven are real towns:** bellhaven, larkfield, longfield, stonebridge, stonegate, sunrise, wakefield, whitefield, whiteford, whitehaven, whiterock.
- **Verdict: Pass; remove the eleven (w06).** A name is not protected and a clash with a small real town is harmless in itself. The reason to drop them is **c07's "no real city"**: the game destroys its cities, and a destroyed "Wakefield" or "Whitehaven" reads as a real place being wiped out. Add the eleven to `blocklist_start`. Smaller real towns under 15,000 will also collide by chance; that is unavoidable, harmless and not a reason to act.
- **Keep the rule going forward:** any name added later is run through the same list before it ships; do not name a destroyed place after a recognisable real city (the ones that appear in news).

## 5. Combat's grapple held poses (tied, pinned, carried): **Pass with conditions, before they are drawn**
The grab rows already in force (g01 to g05, h01, h04, s08) cover the hold points, no locked hands, nothing glowing, the whole-body carry and the vicious blows. The held poses add three things those rows do not say:
- **g06 (the tied pose):** the collar-and-elbow or waist hold (g05); the holder's hands never lock or lace with the held fighter's; the held fighter's hands stay **free**, never drawn limp, bound or pinned behind the back; both fighters upright and their heads and torsos apart by at least a forearm's length (the grapple is a fight hold, not an embrace).
- **g07 (the pin):** the pin is **vertical against a surface** (a wall, a building, a cliff), at the shoulder, collar or upper arm; **no forearm or hand across the throat or the face** (g01), no choke; **no ground pin, mount or straddle** of a downed fighter (a downed opponent is also s09's defenceless case); hips apart; the pinned fighter's feet bear weight and he is shown **struggling or bracing**, since the held fighter always has a way out (§3 of the grapple document), which is also the best defence against "defenceless victim".
- **g08 (the carry):** over the shoulder or by the collar and waist; **never by the head, neck, hair or tail**; the carried body is drawn **whole and in view every tick** (g03, g04), face and chest never hidden or pressed to the holder; no sparks or glow at the hands (g02); the throw at the end is a launch through the planner, never a vanish.
- **Held-pose lint:** these are class hold (h04), so the pair test and the emitter test apply to every tick; the tied and pinned poses last up to 90 ticks, so the lint runs on all of them. No taunt pose rides on a hold (h07).
- **Vicious blows inside a hold** stay on s08. **The 90-tick limit and the lockouts** are Combat's, and a good legal control too (nobody is held indefinitely).
- **Closed:** the headbutt (already screened, RL-070 line) and the zip's carried poses (RL-079).

## 6. Art's hybrid picks: **Pass with conditions; seen in part**
I read the pick file and rendered the **Protagonist's part of `look-hybrids.svg`** only. A browser capture of the larger sheet timed out, and I did not see the Anti-hero's panels, the aura sheet or the dummy sheet as pictures. The verdicts below are from the written descriptions and must be confirmed on the turnarounds before any build.

### The Protagonist: A (robe over the top), B (robe tied at waist), C (towel robe)
**All three pass.** Conditions for whichever is picked:
- **The ring on the back** is a plain annulus: no letter, no kanji, no star, no sphere or disc that reads as an orb (the Protagonist owns no orb artefacts), and not a copy of any known emblem.
- **No orange garment with blue under it** (the famous uniform); the top is ivory, the cloth indigo, the robe any other colour. Nothing else about the three ways touches a rule: a robe, a knot and a cloth are generic.
- **Way B** (robe tied at the waist, sleeves knotted) is the closest to a wrap-and-belt uniform: keep the knot in front and the garment open, not a wrap jacket with a belt.

### The Anti-hero: A (coat over the sash), B (open coat), C (cropped jacket)
**All three pass, with two conditions.**
- **h09, A's "arms folded high":** folded arms are a held crossed-forearms pose, which h02 forbids at 12 ticks or more. It is fine on a sheet and as a moment under 12 ticks, but **must not become his idle, stand-off or intro pose**. A one-arm fold (a single forearm across the body, the other hand free or at the chin) is allowed.
- **The shoulder plates and studs:** the studs are round, never stars (the star-marking rule); the shoulder plate is one large and one small (an asymmetric pair), which keeps it clear of the symmetric winged-armour-with-tail silhouette of a famous alien villain; a **tail plus symmetrical winged shoulder guards plus a short cape** would not be, so keep to the drawn asymmetry. The tail is approved (RL-070); it is never a grip point (g01).
- **Option C** (cropped jacket) is the clearest silhouette of the three; this is a design point, not a legal one.

### The aura (A blades at the tail, B dashes all round)
**Both pass** if: it is one mark of the seven (the stacking cap, k01: at most two marks in any moment, so the aura plus one other); the violet warms and cools at **under 2 Hz** and under a 10% step, steadier under Reduce flashing; the blades along the tail and back **do not strobe or alternate** (slow, local change only), and for **B** the dashes are fixed to the outline and do not crawl or alternate (a regular moving pattern around a body is its own pattern test). A: the better read and no flicker risk; B: the dashes are a fault-in-the-line risk at small size.

### His glasses
Unchanged and approved (the crack, the bend, the finger nudge); the glasses rules stand (no star, no ball, no lit lens).

### The dummy (A, B, C)
**All pass.** The lit squares are **steady or 1 Hz or slower** and low in contrast, not a blink (k06, fx04); the plates are plain graphite, no star or emblem. The dummy being hit hard is within the game's rating, a training rig and not a person.

## 7. The four guides
`guide-licence-rundown.md`, `guide-selling-your-first-game.md`, `guide-company-or-individual-oregon.md` and `guide-stomp-and-ratings.md`. All are general information, not legal or tax advice. **Their figures are not all verified:** Steam and itch.io facts come from the platforms' own pages read today; Oregon fees, local taxes and IRS rules are from memory and secondary sources (sos.oregon.gov was unreachable today). The EP should copy them to Orb's homework with that caveat in the first line, and Orb should have a business lawyer and an accountant confirm the company steps before paying.

## What I need next
Narrative: the eleven names off the table, the extended lint list, and the rival-line choice (Orb's). Combat: g06 to g08 when the held poses are drawn, with the lint running on every tick. Art: h09, the ring and stud conditions, and the Anti-hero and dummy turnarounds back to me before a build.
