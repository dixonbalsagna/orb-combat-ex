# Beams and explosions as drawn, Animation's eight pieces, the beam casts and UI's launch marks: screen

Owner: Legal and IP Compliance. 2026-10-16. Screens `docs/vfx/beam-look.md` (VFX, b2f5b290), `docs/animation/combat-pieces.md` (Animation, 03330fcc) and UI's launch marks (cf36d6cb), from the written documents (the sheets are on Tools' machine and not public). All parked; nothing here is applied. New rows: e10, fx04, fx05. A screen, not legal advice or a medical opinion. RL-141 to RL-143.

## (a) VFX: the beams and explosions
**Pass, with conditions; the set is re-run with them in before anything ships.**
- **The beam as drawn:** a straight prism with three layers (sheath, body, core), the core the lane colour lightened by a tenth at most and **never white** (L* 86), the ripple 2 Hz or slower at any point and under a 10% luminance step, the two tints alternating **along** the beam and never around it. That is the plain straight line, slow low-contrast shimmer and no spiral, drill or helix that fx03 asked for: **pass**.
- **Width, start and end:** the beam's start and end events weigh up to 1.6 times the area threshold in ai 39's window, and that window reads 2.5 on the primary reading (HEAD itself reads 2.5). Inside the limit, **not yet inside the margin rule**: re-run the full 56 clips both modes on the commit that carries it, apply the margin rule, and the beam's start and end flashes go through the registry as now.
- **The calm form** (every beam under Reduce flashing, the shipped default, is the full beam at 0.86 strength with a 0.3 s rise, never a thin line or a white core): **accepted** if the release set reads it at or under the primary limit in both modes (fx05).
- **The Anti-hero's short beam** (the thin needle, width 0.4): **pass**; a thin straight beam is fine, and it must never twist or drill (e07).
- **The beam struggle's marks and UI's tug ring** (3 Hz thin rings and lines, a 20-tick pulse): **pass with fx04**: they are at the limit, so steady or 1.5 Hz or slower under Reduce flashing and Reduced motion (UI's tug ring already is), strokes only, no brightness change, and listed in the rate lists.
- **The launch opening's ring on the chest** (steady after 4 ticks): **pass**.
- **The explosions** (three staggered waves, each flame growing in over 0.1 s, smoke, cinders; point-blank hits also burn): **pass.** No rubble ring, crack or lightning on a body; not a single-frame flash. **One caution (fx05):** the document gives the flame's ratio as 0.56 on gamma-encoded values, but the standard's red test uses linear values, where a cel orange can sit near 0.8. The analyser is the authority: it must read **red flashes 0** on the set with the explosions in.
- **Originality of the looks:** cyan to azure for the Protagonist and violet to magenta for the Anti-hero are Art's lane colours, and a blue beam is not protected. With no ball, no two-handed brace, no shouted name, no helix and no two-colour twist, the combination is distinct. Keep "each fighter's own flavour" in motion character (flowing against exact and cold), as drawn.

## (b) Animation's pieces
- **The beam casts (the open palm), RL-038: closed.** RL-038's condition was the stance of one arm out, palm forward, **with the other hand gripping the wrist**. The Protagonist's cast has no grip: the charge draws one arm back at shoulder height with the palm forward and the other hand open in guard a shoulder width away, and the fire throws the arm out with the heel of the palm leading and the other hand open and low at the rear. That is the ordinary energy-in-reach hand (R1), and the signature beam may use it. **e10:** the free hand never grips, braces or cups the wrist or forearm and stays at least shoulder width away; never both palms; no ball or glow in either hand; no scream; the charge pose keeps h05. No swap to a heel-of-fist is needed. The Anti-hero's fist cast is within the rule. Animation's own note that the Protagonist's charge reads as the arm held out rather than drawn back is a design point, not a legal one.
- **The launch opening's 7-tick snap** (head snapped back, arms flung open with the palms open, then the open arms coming in): **pass.** It is a 7-tick reaction (asserted) and nowhere near a held pose (h02, h07); it is also not the rival's On the Chin stance, which is a chosen, held, arms-slightly-forward pose. Keep it a reaction: never held and never after a taunt.
- **The eight pieces:**
| Piece | Verdict |
| :-- | :-- |
| `pv.su_blade_fall` (the Protagonist's falling blade hand to the chest) | **Pass** (L3, D5: one hand drops, the free hand 24 apart in guard, both feet keep the ground) |
| `pv.su_palm_arm` (stepping palm to the arm) | **Pass** (L2, D1: one hand, open, not at the hip) |
| `pv.palm_turn` (turning palm-heel to the chest) | **Pass** (L2: open hand, not at the hip, the palm leading) |
| `rq.jab_fist`, `rq.cross_fist`, `rq.spear_fist` (fist hand-state swaps) | **Pass** (L4: a straight blow never passes through the body) |
| `rq.su_fist_unwind` (unwinding fist to the jaw) | **Pass** (D3: one arm crosses; the free hand moved to a low guard 24 apart) |
| `gd.su_sole_fall` (the guards' falling sole to the chest) | **Pass** (a stomp on a standing opponent is clear under s09; the standing foot keeps its place, no leap) |
- **The guards' measured bolt** (an open palm thrust, planted, palm drawn back to the shoulder first): **pass** (R1, e06, e09: one hand, open, flat, shoulder height).
- **`common` for the dummy and the guards:** no legal issue; "a fighter's own is never lent" is a design line.

## (c) UI's launch marks
**Pass; list both as moving marks (fx04).** The recharging ring steps once a second (1 Hz). The beam struggle's tug ring closes on the 20-tick pulse (3 Hz): strokes only, steady under Reduced motion and Reduce flashing. Both go in the HUD and effects rate lists that hud_check and the flash set read; neither may exceed 3 a second (k06).

## What to run before any of this ships
The full required set (56 clips, both modes) on the commit that carries the beam look, the explosions, the marks and the casts; the margin rule; **red flashes 0**; the beam-heavy and explosion-heavy scenes added to the set (a beam clash, a signature in the city, a mashed blast on the dummy); and the rate lists updated.
