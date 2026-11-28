# Cosmetics plan: a vast unlock set, by data

Owner: Art Director. 2026-09-30. A plan for Orb's "a vast assortment of cosmetics players unlock through play" (`docs/ep/vision.md`, last section). Draft for the EP, Orb, Animation, Rendering, Tools and Legal. Nothing here is built.

**Updated 2026-11-28 for the Look Profile** (`docs/ep/proposals/look-profile-spec.md`, "the spec"; Orb's answers at its end). The spec is the rule for **energy** looks (aura, beam, blast, trails, tints); this plan stays the rule for the later parts (`body`, `colours`, `face`, `hair`, `outfit`, `accessories`, `voice`, `poses`: spec section 2). Where the two differ, the spec wins for energy. The creative rules for looks are in `creative-rulebook.md`.

**The rule above all rules: cosmetics are render-only** (spec LP1). They are ids in a look profile that only the drawing side reads. The sim never reads them, so the gameplay hash is the same with any loadout (fairness online, and `cue_check` style hash checks prove it). In an online match each player sends only ids; a peer that lacks an id draws the default. Originality rules (`originality-rules.md`, `q3-screen.md`, `style-guide.md` 3.4) apply to every item, and each pack gets a Legal screen and an origin row.

## 1. Categories that fit our style

| Category | What changes | How it is made |
|---|---|---|
| **Palettes** | Body, gear and accent colours | Three palette slots (data). The same mesh takes any set |
| **Mask finishes** | The mask's surface: polished, matte, glazed, cracked glaze, stamped pattern, inked edge. The sigil's own tone inside its lane | Shader parameters on the mask slot. Mask shape and tone class are fixed |
| **Outfit and regalia parts** | Belt, sash, wraps or guards, back piece (knot, plates, mantle hem, backpack cover), boots trim, collar | Small swappable meshes inside a fixed envelope, plus a pattern id |
| **Patterns** | Stripes, bands, chevrons, scales, weave on cloth and plating | A procedural pattern in the shader, chosen by id (no textures, `style-guide.md` section 1) |
| **Accessories** | Charms, pins, badges, cords, a small scarf, a belt pouch | The rig's attachment sockets (section 4). Never above the silhouette |
| **Energy looks** (trails, aura, beam, blast) | Shapes, movements, finishes, palettes and sliders, in layers; the beam keeps the fighter's shape, width and struggle (spec LP11) | The look profile's `energy` part and the catalogue in `data/look/` (spec sections 2 and 4) |
| **Flash tints** | The emotion flashes' accent. Never the info flashes | `data/art/flashes.json` accents, per profile |
| **Poses and taunts** | Taunt gestures, victory poses, knockout reactions, showcase poses | Rows in the animation rig, blended as today |
| **Victory scenes** | A short post-win staging: a camera move, a backdrop tint in the biome's own range, one prop | Camera and a data preset. No new models |
| **Marks and banners** (UI) | Titles, portrait frames, nameplates, the HUD crown's arc style | UI owns the drawing, Art the palette roles |
| **Original extras** | Weather-worn variants (wear tints), a tier-glow sigil colour, footstep dust tints | Data on existing systems |

## 2. What keeps each fighter readable

A cosmetic is accepted only if it keeps all of these. Tools' validator checks the data ones; Art reviews the mesh ones.

1. **Silhouette lock.** Each fighter's one shape feature stays: the Protagonist's round, forward lean and the belt knot; the Anti-hero's spine plates and tail; the Empress's mantle and topknot; the Cyborg's boxy head and backpack. A part variant must fit its **slot envelope** (a hull per slot, about plus or minus 10 percent of the body's width or height). Nothing rises above the head. No horns, antennae, goggles, wings, halos or spikes (Legal's lists).
2. **Identity marks never change.** The mask tone class (pale or dark), the sigil's shape and place (an open arc, a leaning slash, three chevrons, a stair of squares), the fighter's shape family (circles, blades, wedges, steps), and the head flashes' shapes, pulses and keep-out zone.
3. **The colour-blind-safe flash language never changes.** Info flashes (danger, hazard, the finisher tells, found, searching) keep their pale core and thin keyline, so a palette can tint the keyline only inside the lane. Emotion flashes may take the loadout's accent, with the Protagonist's rim-over-hair rule. An energy look may carry an aura, glow or linger within the spec's limits (spec section 5): the aura still shows only while charging or attacking, never at rest; a non-energy cosmetic adds no standing glow, aura or flash-like trail. *(Replaced 2026-11-28: the old line barred any cosmetic glow, aura or trail.)*
4. **Value rule and lanes.** Body lightness L* 30 or less, gear 80 or more, the accent never a mid-value block on more than 10 percent of the figure. Accent hue stays within the fighter's lane (teal, orchid, moss, coral, plus about 20 degrees), never red, orange, yellow or gold for the Protagonist and the Anti-hero, and never fire's colours as a mass or a flash. Hair never gold and never changes with power.
5. **Colour-blind check on every palette.** This rule is for **body** palettes. Energy palettes are not rejected: the player may pick any, and the game corrects how they are shown on each screen (spec LP9 and section 5, "Against each biome and sky"). A body palette passes only if its body, gear and accent separate in greyscale and in deutan, protan and tritan simulation (the method in `effects.json` `deutan_check`), and if the fighter reads against the grass, sea and sky backdrops by value (the rim rule). Tools can run this as a validator.
6. **Match-up clash.** **Energy:** if two resolved looks are closer than 25 on the colour-difference scale (20 under each colour-vision setting), the second is shifted on the viewer's screen (spec section 5, "Two players whose energy looks alike"). This replaces my old rule for energy, which drew the opponent in its default palette: a shift keeps their choice visible. **Body colours** (a later part): until a second body colour exists, picking the same fighter twice stays off (spec section 5), and two recolours of different fighters that come out close are drawn in the opponent's default palette on the viewer's screen. Either way it is render-side only and never touches the sim.
7. **Fairness tells stay default.** Anything a player uses to read the other player (stance chips, the crown, the flashes, the sigil) is not a cosmetic.

## 3. A rough count that gets to "vast" cheaply

Per fighter, rough first targets. Only the mesh and animation rows cost real work; the rest is data.

| Category | Items per fighter | Cost |
|---|---:|---|
| Palettes | 40 | Data: Art hand-makes 8 and a generator fills 32 inside the lane rules, all validator-checked |
| Mask finishes | 12 | Shader presets |
| Outfit and regalia parts | 32 (4 slots of 8) | Small meshes of 40 to 120 triangles (250 at most), shared palette and patterns |
| Patterns | 10 | Shader presets, shared across all fighters |
| Accessories | 12 | Small meshes on the rig's sockets |
| Trails, beam tints, flash tints | 30 (10 + 12 + 8) | Data on VFX's and the flashes' lanes |
| Taunts, victory poses, KO reactions | 18 (8 + 6 + 4) | Animation rows |
| Victory scenes | 6 | Camera and data presets |

About 160 items per fighter, 640 across four, with the worth of a real game in the **combinations**: 40 palettes x 12 finishes x 8 parts in each of 4 slots is over 1.9 million looks per fighter. Of the 640 items, about 250 need a mesh or an animation row (128 parts, 48 accessories and 72 pose rows), and the rest are numbers in a file. UI's titles, frames and nameplates (about 40 per account) sit on top.

## 4. What the fighter mesh needs from day one (reconciled with Animation's rig plan, `docs/animation/pose-pipeline.md` section 2.8)

Agreed numbers, which are Animation's: **14 attachment sockets** (the rig's call), a budget of **4 cosmetic chain bones a fighter** at once, **at most 500 triangles of cosmetics at near LOD** (a piece 250 at most, none at far LOD) on a body of about 2,000, the cap of **32 bones**, and **12 draw calls a fighter**. Art owns silhouette and readability; the rig owns the sockets. This plan no longer states its own socket and chain numbers.

- **Sockets.** The rig's 14 `att_*` points: head top, brow and back, neck, shoulders, upper and lower back, chest, belt, wrists and ankles. They are fixed offsets per build profile, so a part fits every build by name. **Art's readability rule sits on top:** nothing worn at `att_head_top` may rise above the silhouette envelope (no horns, antennae, spikes or halos), and head sockets only take a flat cap, a band, a circlet that stays within the head's width, or a small badge. `att_head_brow` never covers the sigil. The neck, brow and top sockets are the ones Legal reads first.
- **Named swappable slots**, each bound rigidly to existing bones: `mask` (shape fixed, finish by material), `hair`, `outfit` (torso), `belt`, `arm_gear` (near forearm), `back_piece`, `boots_trim`, `collar`. The Anti-hero's plates and the Empress's mantle are back pieces with an intact and a broken variant.
- **How a part is drawn** (the rig's two ways). The default is **merge at equip**: the body and every worn part are built into one outlined mesh, cached by the loadout key, so any number of parts is still 2 draw calls. A part that must toggle or animate on its own (a damage variant, a glowing piece) is a **separate mesh at +2 draw calls**, and there are few of those: the regalia with broken variants, and at most two more.
- **Materials without extra draws.** The body already carries seven vertex-colour palette slots (body, legs, arms, skin, gear, accent, hair) plus the emissive mask; a cosmetic takes a slot or uses up to two more (`cosmetic_a`, `cosmetic_b`) in the same vertex-colour data. A `pattern_id` and a `finish_id` are shader parameters on that one material. No texture and no extra material per cosmetic.
- **Triangles.** A worn set must stay within 500 triangles of cosmetics at near LOD, so the parts in section 3 average about 125 and never exceed 250. Only the four slots plus a few accessories are worn at once.
- **Chain bones.** A cloth or long part (mantle hem, sash tails, scarf, tassels) draws on the fighter's spare bones: at most 4 cosmetic chain bones at once. The Empress's mantle and the Protagonist's sash tails are the cost to watch, so a loadout that adds a second long cloth part must drop one.
- **Mirroring.** A part on one side flips with the fighter. Asymmetric parts are allowed only if they are flip-safe: no letters, no numbers, nothing whose meaning depends on the side (a left-only badge becomes right-only when the fighter faces left, which is fine for a charm and not for an emblem).
- **Clearance.** Each part declares a clearance volume so the pose lint can flag a clash (a tall collar and an uppercut). The silhouette envelope per slot ships as data for the validator and the modeller.
- **Smoothed outline normals** on every part (`style-guide.md` 5.1), so a swapped part never cracks the hull outline.
- **Look data** lives in `data/look/` (VFX owns it; spec section 4), with the schemas Tools adds when the files exist. Energy entries, tiers and rewards are in the spec's catalogue and reward files; the later parts will add their entries there the same way: item id, category, fighter or shared, slot or socket, palette or mesh reference, clearance, tier and unlock track (Game Design owns tracks), Legal screen status. The sim never reads this folder and it is not a match input (spec section 3, rule 7). **A palette is just data**, so player-made palettes stay possible later: the checks in section 2 are what would make body palettes safe. *(Replaced 2026-11-28: this plan named a folder `data/art/cosmetics/` that was never created.)*

## Decided

1. **Unlock tracks** belong to Game Design. For the alpha everything is unlocked and tiers are only shown (Orb, 2026-11-28; spec, "Orb's answers" 3).
2. **Sharing:** patterns, trails, beam tints and victory scenes are shared across fighters.
3. **Player-made palettes** go to Orb as an optional later feature; the data leaves room for them.
