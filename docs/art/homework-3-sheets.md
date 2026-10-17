# Homework 3 sheets: the aura, the glasses, the look pass

Owner: Art Director. 2026-10-15. Three sheets for Orb's answers to homework 3 (`docs/ep/vision.md`, "Orb answers homework 3, fighters"). **Concept art, working labels, pending Legal review. Kept on this PC only: no in-progress character art goes on a public page or in the public repo (Orb, 2026-10-06).** Regenerate from the repo root: `node art/concepts/looks/gen-aura.mjs`, `gen-glasses-damage.mjs`, `gen-looks.mjs` (deterministic, no packages). Prompt record: `art/prompts/ART-0020-homework-3-sheets.md`.

| Sheet | For | Question it asks Orb |
|---|---|---|
| `art/concepts/looks/aura-options.svg` | His aura ("Send me a sheet") | Which of five? |
| `art/concepts/looks/glasses-damage.svg` | His glasses (always on; lenses and frames can crack and bend) | Are these four states, and when they show, right? |
| `art/concepts/looks/look-pass.svg` | "More personality, style and distinction" for the two in the build | Which direction for each, or which one thing from which? |

## 1. The aura: five options

Legal's rule holds for all five (hue 260 to 320, never white, no red, orange, gold or yellow, no flame, no lightning; a thin outline and a few rings, only while charging or attacking). His forms are drawn the same on every row, so only the aura differs: Regalia (a collar and two forearm guards), Sovereign (adds a low crest and three floating plates), Apex (the guards fall away).

1. **Violet that warms, then cools** (Art's recommendation, in `data/art/auras.json` today): 266, 290, 272. Each form its own colour mass.
2. **One violet, three strengths**: hue 266; the form shows by the outline's thickness and the rings (1, 2, 3).
3. **Magenta forward**: 280, 300, 290. The most visible against the sky (24 to 28 from it).
4. **Cold violet**: 262, 268, 274, lighter and cooler. The quietest (16 to 19 from the sky); the sigil and the glasses carry the moment.
5. **Blades**: the colours of option 1, with the outline broken into slashes and the rings as two slanted blade arcs (his language).

The numbers are on the sheet. The rim keeps its dark keyline in every option. His lane colour today (`#9a80d8`, hue 258) is just under Legal's 260; any option corrects it. **What to check in motion** before choosing: how the outline looks on a bright sunset. Nothing is changed in data until Orb picks.

## 2. The glasses: four states

Frame C (the bare wedge, approved), always on. Four states: **clean**, **a cracked lens**, **a bent frame**, **both**.

| State | Looks like | When it shows (tied to what the sim has) |
|---|---|---|
| Clean | as approved | fresh or bruised head; act 1 |
| Cracked lens | one long diagonal crack on the near lens and a short branch that does not cross it; pale, never white, never red; the glare still comes and the crack throws a line through it | the head is battered, or the first hit that lands on his face (about the end of act 1: Pride below half) |
| Bent frame | the near lens drops and tilts about 12 degrees, the bridge pulls down, the far arm kinks; nothing breaks | an event: a launch that throws him head first, or a hit that knocks his head back hard. **Undoable**: he straightens them with a nudge |
| Cracked and bent | both | the head is broken (last wound stage) or the final form's break; they stay on to the end, and the results screen shows them as they ended |

**One finding:** at fight size (86 px) the lens is a 6 by 1 px sliver, so a crack or a tilt does not read there. They read in the close-up cut-ins, the results screen and **the nudge**, which is the gesture he already has (a nudge at the temple arm). The state changes what the nudge does: clean, he settles them; bent, he straightens them; cracked, he touches them and leaves them. That gives Narrative its beats (bragging about paying extra for the frames when clean; a short lament when cracked; "I will need a new pair" on the results screen). **Costs (estimates):** Art 1 round; Rendering one part with a crack decal and a lens tilt on the head bone (no new bones); Animation about 4 poses (two nudge variants); UI the cut-in and results portrait take the state. Legal: RL-066 stands, the crack throws only a pale line.

## 3. The look pass: three directions each

Orb: "two guys with different colored shirts wearing backpacks ... perfectly fine for a test environment, but more personality, style, and distinction would go a long way." The approved looks of 4 October are the base: the face, the tuft, the tail and the glasses stay. What each direction changes is what he wears, what he carries and how he stands, from his voice (`docs/narrative/voices/`). **The pack and knot behind the Protagonist, and the coat plates behind the Anti-hero (the "backpacks"), are replaced in every direction.**

**The Protagonist** (earnest, delighted, fascinated by technique, promises in the future tense):
1. **The Sparring Partner**: ivory training top, dark teal trousers, taped forearms, a towel; a row of wood **tags on the belt, one for each thing he has promised to fix**. Open hands, on the toes.
2. **The Fixer**: denim shirt, canvas bib apron with a folding rule and a pencil, knee pads, a sweatband; planted wide and low, a builder's stance.
3. **The Showman**: a boxer's robe worn open over bare shoulders, indigo with ivory trim, **one big ring on the back** (his mark, seen from behind); a bounce, guard high.

**The Anti-hero** (cold, formal, ranks everyone, the past tense, plays his hand close):
1. **The Long Coat**: knee-length buttoned coat with two flat tails and a stand collar, a pale lining flash at the hem; very upright, one hand behind the back.
2. **The Rank Sash**: one armoured shoulder, a diagonal sash with **five rank studs** (his ranking gag, worn), boots to the knee; weight back, arms folded high.
3. **The Long Gloves**: a sleeveless high-collar vest, narrow trousers, long pale gloves; the slimmest read and the cheapest; a duellist's side-on line.

**Narrative's read (added 2026-10-15, from `docs/narrative` identity pages; options for Orb to tick, not rules)**: the useful contrast is how they stand and what they carry, not their colours.
4. **The Worker** (Protagonist): bouncing on his toes, weight forward, always facing you; sleeves rolled, patched where he has fixed things, **a tool roll across the back instead of a backpack**, tape at the wrists above the plated fists; rolls his shoulders before a heavy and nods at a technique he likes. About +90 triangles, no bones; about 4 poses.
4. **The Pressed One** (Anti-hero): chin up and still, **one limb left out for a beat after each blow**; a coat he never lets crease (pressed edges, pale piping), plates polished until they shine even when filthy, buttoned cuffs; **the frames are the one expensive thing**; fixes a cuff before a heavy and a finger to the frames before he commits. About +130 triangles, no bones; about 4 poses and a pose hold.

Each is drawn at twice fight size and at fight size beside the other fighter as approved (so the pair has to read apart), then flat black at 86 and 46 px. **Costs** are in parts and are estimates: none needs a new skeleton; the cheapest is the Long Gloves (about +80 triangles, no bones); the dearest are the Fixer (6 rigid parts) and the Long Coat (5). The sash bones R1 already has can carry a towel, tags, a robe or coat tails. Legal's rules on hair and transformation looks hold: no hair-colour ladder, no pale-and-purple regal for the Anti-hero, no cape (Orb), no red or gold glow.

## Questions for Orb (one sitting)
1. **Aura:** which of the five (or a mix, say 3's colours with 5's shape)?
2. **Glasses:** the four states and the three triggers (head wound, a head throw, the final break), and the nudge that undoes a bend?
3. **Protagonist look:** the Sparring Partner, the Fixer, the Showman or the Worker (or a mix: the tags on the Fixer's apron, say)?
4. **Anti-hero look:** the Long Coat, the Rank Sash, the Long Gloves or the Pressed One?

## What goes to whom after Orb picks
Narrative writes the glasses' and the tags' lines; Rendering and Animation build them later (the costs above); Legal screens the picks before any build (the studs and the ring are marks, not a sigil, but Legal should see them); I redraw the turnarounds of the two picked looks and put the aura set into `data/art/auras.json` and `flashes.json` (Tools' schema unchanged).

## Limits of this round
- The figures are the kit's side-on concept models, not the game's bodies; the colours are not the game's lit colours (the world-light pass has not landed).
- The aura outline is a filter on the flat silhouette, which is how Rendering could build it too but is not proof it is cheap on the web build.
- The nudge gesture is not drawn on this sheet; the glasses sheet shows only the states.

## 4. The training dummy (added 2026-10-15)

`art/concepts/looks/training-dummy.svg`: the reference fighter goes in the roster as a training dummy; his look is "a sparring frame of our own on the shared mannequin" (`docs/design/fighter-pipeline.md` section 8). Three options on the shared mannequin: **The Frame** (matte grey, visible joints, a faceless dome head, one square target on the chest; +40 triangles), **The Pads** (canvas pads roped over the frame, a stuffed sack head; warm against the two hard fighters; +110), **The Rig** (a graphite frame with sensor plates that light in his ring colour; +90). None needs a bone. At 46 px all three are 0.61 to 0.62 from the Protagonist and 0.66 to 0.67 from the Anti-hero (the launch pair are 0.620 apart): about on the line, since the shared mannequin is a neutral build. Narrative names him.

**His ring: `#c6bade`**, the same under every vision. No neutral colour clears the whole rule against two fighters, the proposed Empress and Cyborg, the wound marks and every sky and ground (the best reaches 0.54 of it over the four visions); this one clears the ground at every biome and key and the sky by default, sits 16 from the nearest wound mark and 19 from the nearest ring by default (rule 20 and 25), so it is a lane in name only. He is told apart by what he is, a mark of his own (a short dotted ring, from the rule's cross-of-dots family) and the HUD. The row (`"reference": {"col": "#b9b9b9", "aura": "#c6bade"}` in the default and the three presets) is prepared in scratch and parked for the EP's commit with the roster.

## 5. Orb's picks, drawn as hybrids (2026-10-17)
Orb picked a hybrid for each (`docs/ep/vision.md`, "Orb picks the looks ..."). Sheets (WIP character art: `art/concepts/looks/` only, never committed, copies in `homework/fighters/`): `look-hybrids.svg` (the Protagonist's Sparring Partner and Showman as the Robe Over the Top, the Robe Tied at the Waist and the Towel Robe; the Anti-hero's Rank Sash and Pressed One as the Coat Over the Sash, the Open Coat and the Cropped Jacket), `aura-hybrid.svg` (70 percent option 1 and 30 percent option 5: blades at the tail, or dashes all round, on his three forms; Art's pick is blades at the tail) and `dummy-hybrid.svg` (Pads with Plates, Lit Pads, the Frame Showing). The glasses stand as planned. The choices are in `homework/fighters/PICK-hybrids.md`. Poses keep every elbow and knee bend under 150 degrees (the joint-limit rule); Animation runs its lint on the real poses.

**Legal's conditions on the hybrids (RL-146 to RL-152, `docs/legal/homework8-review-screen.md`), applied 2026-10-18:** the ring on the back is a plain annulus (no letter, star or orb-like sphere); no orange garment over blue; way B keeps its knot in front and the robe open; the rank studs are **round** (the first sheet drew diamonds, now redrawn); one large and one small shoulder plate, asymmetric, never winged guards with a cape; **"arms folded high" (the Coat Over the Sash) is a pose for the sheet and for a moment under 12 ticks, never the Anti-hero's idle, stand-off or intro pose** (h02, h09; a one-arm fold with the other hand free is allowed); his tail is never a grip point; the aura is one mark of the seven, warms and cools under 2 Hz and a 10 percent step, never strobes, and the blades and dashes are fixed to the outline; the dummy's lit squares are steady, or 1 Hz or slower, low in contrast, and his plates plain graphite. Legal saw only the Protagonist's panel as a picture; the Anti-hero, aura and dummy sheets (`homework/fighters/look-hybrids.svg`, `aura-hybrid.svg`, `dummy-hybrid.svg`) go to Legal through the EP, and the turnarounds of the picks go back to Legal before any build.
