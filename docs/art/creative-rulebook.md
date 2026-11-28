# The creative rulebook

Owners: Art and Animation. Orb's creative direction, kept here. It never blocks a gate (Orb, 2026-11-07; RL-258): Legal screens names, whole characters' likeness, trademarks, copied assets and player safety; the look, pose and gesture rules below are ours to keep or change on Orb's word. "The spec" is `docs/ep/proposals/look-profile-spec.md`; section numbers are its own.

## Page 1: looks (energy)

### What Orb said (2026-11-28; spec, "Orb's answers")

1. **The toy wins.** Everything the energy toy makes is allowed, within the limits of section 5. That includes rings, twisting texture, flame-like shapes and white-hot colours that older rules said no to.
2. **The fighter keeps their beam's shape, width and struggle** (LP11). A look changes texture, colour and movement only: a "twist" slider turns the texture on the beam, it never turns the beam into a helix.
3. **Everything is unlocked for the alpha.** Tiers are only shown.

*Still open:* Legal's one-line confirmation that the older shape rows (no ring above the head, no twisting beam, no ball in the hand) moved to this page with the other look rules (spec section 8, item 8).

### Rules that stay for every look

- **Nothing on, over or between the fighters** (LP10, E6). An aura sits behind its fighter.
- **No dissolves, fades, slow wipes or full-screen blur** (ADR 0010).
- **The game's signals are never the player's** (LP3): form and tier, energy level, charge steps, ownership of shots and mines, the beam's front, the clash point and pulses, the losing flare and bulge, the six combat tells, hit and information flashes.
- **Originality:** no look copies a known character's or franchise's energy (a named transformation's colour-and-shape set, a signature move's shape). Legal screens whole-character likeness and names.
- **The limits** of section 5 (brightness cap, red share, repetition, reach, cost), applied after the profile. These are game limits, not taste.

### The white core (Art's rule under Orb; spec section 5)

Orb wants white-hot looks. The rule keeps one thing: **a hit must stay readable, so the game keeps what makes it readable and the player gets everything else.**

1. **Every beam and blast carries the game's own core and edge band**, crisp, over the player's style. A look cannot remove, soften, restyle or re-time them. A look's softness is decoration only.
2. **The core may be near-white, up to L\* 86**, so a look can read white-hot. It is never `#ffffff` and never above L\* 86.
3. **Pure white belongs to the game.** Above L\* 86, up to full white, is only for hit flashes, the beam's front, and the clash point and its pulses. The gap between 86 and 100 is what makes a hit stand out from a white-hot beam.
4. **The core is narrow enough that the colour still reads:** on a beam no wider than about 40 percent of the body band (today's core 0.9 against body 2.2), with the look's colour band around it; on a blast no wider than 40 percent of the head.
5. **The core's brightness is steady.** Only the game's energy flicker and struggle signals move it.
6. **Over a pale sky or snow** the core carries the dark edge (`#0a0d14`) or the pale one the contrast table picks (spec section 5), so a near-white core never vanishes.
7. **Decoration stays under the core:** at most 40 percent as bright (section 5), so it can never take the core's or the hit's place.

*Fixed 2026-11-28:* the cores in `data/art/energy-lanes.json` (and its source, `art/concepts/energy/lanes.mjs`) are now all at L\* 86 or under.

*Still open:* the Empress's **main** colours are near-white (`#fffefa`, beam `#ffffff`), so her beam's body is brighter than its own core and uses the white that rule 3 keeps for the game. Her lane needs an ivory body under L\* 86 before her beam is drawn from it.

### The hero and the rival: a pair (brief L7, first part)

Orb: "similar but inverted in theme, not just colour" (`docs/ep/taste.md`). The catalogue lets the pair say that directly (spec section 4): **the same shapes with opposite movements.** The default files (`data/look/fighters/<ID>.json`) come after L1; this is the design they will carry.

**The idea: Grist pushes out, Loupe draws in.** Both wear two layers, a spark layer and a skin layer, in the same sizes and amounts, so they read as one family. What differs is the way the energy moves, so the pair reads apart in greyscale and at the fighter's size.

| | Grist (the hero) | Loupe (the rival) | Why |
|---|---|---|---|
| Layer 1 shape | Sparks | Sparks | Same family |
| Layer 1 movement | **Jump off the body** (outward) | **Inverted: pulled inward** | The main tell: giving out against drawing in |
| Layer 1 finish | Soft glow | Neon outline | Open and soft against tight and cut |
| Layer 2 shape | Shell | Shell | Same family |
| Layer 2 movement | Breathe in and out | Cling and vibrate | Calm and open against held and tense |
| Palette | Azure | Violet | Their own lanes (blue and violet); Loupe's also darker by value |
| Speed | 1.0 | 0.6 | Loupe is slower: control |
| Reach | 1.0 | 0.8 | Loupe keeps it close to the body |
| Erratic | 0.2 | 0 | Grist is loose, Loupe exact |

**To try them now in the toy** (save a block as a `.json` file and open it with the toy's file picker; these are not data files and not final):

```json
{"format":"orb-energy-recipe","version":1,"name":"Grist default","trail":0.2,"layers":[
 {"shape":"sparks","behaviour":"jump","material":"glow","palette":"azure","seed":3,"sliders":{"power":0.9,"size":1,"speed":1,"density":0.9,"reach":1,"erratic":0.2,"vibrate":0,"detail":0.6,"form":0.1,"spin":0,"hue":0,"spread":0.4,"cycle":0}},
 {"shape":"shell","behaviour":"breathe","material":"glow","palette":"azure","seed":8,"sliders":{"power":0.35,"size":0.8,"speed":0.5,"density":0.8,"reach":0.8,"erratic":0,"vibrate":0,"detail":0.5,"form":0.1,"spin":0,"hue":0,"spread":0.2,"cycle":0}}]}
```

```json
{"format":"orb-energy-recipe","version":1,"name":"Loupe default","trail":0.2,"layers":[
 {"shape":"sparks","behaviour":"implode","material":"neon","palette":"violet","seed":3,"sliders":{"power":0.8,"size":1,"speed":0.6,"density":0.9,"reach":0.8,"erratic":0,"vibrate":0,"detail":0.6,"form":0.1,"spin":0,"hue":0,"spread":0.4,"cycle":0}},
 {"shape":"shell","behaviour":"hug","material":"neon","palette":"violet","seed":8,"sliders":{"power":0.35,"size":0.8,"speed":0.5,"density":0.8,"reach":0.8,"erratic":0,"vibrate":0.1,"detail":0.5,"form":0.1,"spin":0,"hue":0,"spread":0.2,"cycle":0}}]}
```

**Not yet seen by anyone.** These are chosen from the catalogue's ids, not tried on a fighter. Judge them in the toy, then in the game once L3 draws them, in the reduced look first (it is the default, section 5).
