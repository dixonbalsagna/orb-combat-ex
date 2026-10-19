# Faces, hair, forms and shoulders: the round after Orb's picks (2026-10-18)

Owner: Art Director. Orb's answers (relayed by the EP) to `PICK-hybrids.md`, `PICK-red-shade` and the forms sheet. **Concept art, working labels, pending Legal review. WIP character art: the sheets stay in `art/concepts/` (uncommitted); Orb's copies and his short homework file are `homework/fighters/PICK-faces-hair-forms.md`.** Prompt record: `art/prompts/ART-0022-faces-hair-forms-coat.md`.

| Orb said | What was drawn | Where (private) |
|---|---|---|
| The prototype faces "look kind of goofy ... distinct, recognizable, not try-hard but also cool"; the Anti-hero "kind of looks like a puppet" | A face-style study: three directions for each fighter, each at four expressions, at cut-in and fight-icon size and in grey | `art/concepts/faces2/faces-protagonist.svg`, `faces-anti-hero.svg` (`node art/concepts/faces2/gen-faces.mjs`) |
| "I want the hairstyle on protagonist revisited ... potential for cosmetic hairstyles that could be unlocked" | The default revisited and five cosmetic styles, in the portrait and in the game's profile and at fight size | `art/concepts/faces2/hair-protagonist.svg` (`gen-hair.mjs`) |
| Forms: "not distinctive enough, lets bulk up muscles, add distinctive upgrade" | Each step has a heavier frame (+3 to +20 percent) and one hallmark | `art/concepts/forms/hero-forms.svg` (`gen-hero.mjs`) |
| Anti-hero B, the Open Coat: shoulder pieces "a little distracting ... tightened up and become cosmetic unlocks" | The default is one fitted pauldron; three cosmetic swaps (Epaulette Strap, Ridge Guard, Layered Scales) | `art/concepts/looks/anti-hero-coat.svg` (`gen-coat.mjs`; the pieces are `SHOULDERS` in `hybrids.mjs`) |
| City tints: "fantastic, keep iterating ... more variety" | Ten tints per look and a fourth facade type; see `city-facades.md` | `art/concepts/city/city-palettes.svg`, `data/art/city-looks.json` |
| Aura and dummy ("I need to see these animated"; Lit Pads) | Not in this round: they need motion (VFX and Animation) and the dummy's lit pads follow with Rendering | |

## The faces
Why the old ones read wrong: the Protagonist is round dot-pupil eyes on a flat symmetric oval with a line mouth and no cheek, jaw or lip; the Anti-hero is a pale flat oval with a hinge-like jaw wedge and two long pale bars down the cheeks. The new faces are built from structure (a skull, a jaw, cheekbones, lids with a crease, a nose, lips with a seam, an ear, a neck) and each direction commits to one drawing idea: **Ink** (hard light, thick line), **Soft/Painted** (painted light, thin warm line) and **Cel** (bold shapes, thick even outline). The Protagonist's signature details are a strip of nose tape (Ink: a sparring partner, always taped), the heavy lid and angled brow (all), and a slit in the brow (Cel). The Anti-hero keeps frame C, the bare wedge, on the face with a thin arm to the ear and a pale glare wedge (never white; Legal RL-066). Art's picks: **Protagonist B (Soft)** for the warmth, **Anti-hero A (Hard Planes)** for the cold. The faces are a generator (`faces2/render.mjs`): a spec says what the face is, so a fourth direction is a new spec, not new code.

**Honest limits:** these are 3/4-view portraits, not the game's heads (the game's head is a side-on kit head and the cut-in engine's coordinates); the sheet shows the look to choose, and a chosen direction then needs the turnaround, the eight expressions and the damage stages redrawn (about two rounds, the way the approved set was done). Expressions are readable but mild: the hurt, shock and grief sets come after the pick.

## The hair
Default **Rolled Sweep**: the swept tuft that made him recognisable, but a lifted forelock, cut-apart strands and short sides so it reads as hair. Cosmetics: **Close Crop** (cheapest at 46 px), **Rolled Quiff** (adds about 3 head units of height), **Tied Back** (a short blunt tail that moves with him), **Side Braid** (swings when he turns), **Buzz with a Part**. All the same teal: Legal's rule (no hair-colour ladder, nothing rising or changing) holds. Costs (estimates, Rendering to confirm): the crop, quiff and buzz are one head part each; the tail and braid are one or two parts on the sash bones R1 already has (no new bones).

## The forms, round 2
See `hero-forms-look.md`, which is updated: bulk per step (tw and lw scaled 1.03 to 1.20, in the data later), one hallmark per step, the Ring at his back for the top form, and proposed lore hooks: plates are shelter (Witness), rings are the sparring circle (Trial). Silhouette distance from his base now runs 0.037 (step I) to 0.267 (step V); the Anti-hero stays 0.612 to 0.628 from every form.

## The Open Coat
Before: one large and one small plate that stood off the shoulder. After: one small fitted pauldron cut to the shoulder and a smaller one on the far side, both close to the coat. The silhouette changes by 0.02 (a change of read, not of reach). Four pieces: Fitted Pauldron (default), Epaulette Strap, Ridge Guard, Layered Scales; each keeps Legal's rule (one large and one small, asymmetric, never winged, no cape).

## What Rendering, Animation and Legal need after Orb picks
Narrative: the lore for the forms. Rendering: the face part (a soft gradient for B; a thick outline for A and C), the hair parts, the growth scale per form, the rings' emitter. Animation: the planted and leaning-in poses. Legal: the faces, the nose tape, the brow slit, the Ring at his back and the shoulder pieces.
