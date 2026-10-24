# Energy colour lanes

Owner: Art Director. 2026-10-24. **Generated** by `art/concepts/energy/gen.mjs` (`node art/concepts/energy/gen.mjs`); the data is `data/art/energy-lanes.json`, the one-sheet `art/concepts/energy/energy-lanes.svg`. The brief: each fighter's colour lane for bolts, lobs, beams, grabs and traps (the energy overhaul; Combat's kits are in `docs/combat/pending/energy/`). Proposal; the EP, Combat, VFX and Legal decide.

## 1. The four lanes

Each kind has a **core** (the bright centre), a **main** (the colour a player names it by) and an **edge** (the dark rim), inside the keyline (#0a0d14). Flat colours, no gradients, no blur, no fades. Energy is never dimmed by the world light.

### The Protagonist: cyan to azure

| Kind | Core | Main | Edge |
|---|---|---|---|
| Bolt | #f2fdff | #10c2ea | #0b7fb8 |
| Lob | #ecfaff | #1eb0f4 | #0e6cc4 |
| Beam | #f4faff | #2e90f2 | #0d58c4 |
| Grab | #ecfcff | #1ca6f4 | #0c78c0 |
| Trap | #e8f5ff | #2a9cf4 | #0f62bc |

### The Rival: violet to magenta

| Kind | Core | Main | Edge |
|---|---|---|---|
| Bolt | #f0e6ff | #4420c4 | #2e0c78 |
| Lob | #f6e6ff | #5c1ca8 | #3c0c6c |
| Beam | #ffe8fb | #80127e | #5a0c64 |
| Grab | #f4e6ff | #521ab4 | #340c78 |
| Trap | #eee4ff | #4c20ac | #300c70 |

### The Demon Cyborg: molten slag oranges, with scrap-metal grey (wreckage and metal only)

| Kind | Core | Main | Edge |
|---|---|---|---|
| Bolt | #ffe9b0 | #f58a22 | #4a2e20 |
| Lob | #ffe0a0 | #e8821e | #47291d |
| Beam | #fff4cc | #fa9a2e | #4a2e20 |
| Grab | #ffe4a8 | #ec8a24 | #46291c |
| Trap | #ffdc98 | #e07c1e | #40261a |

### The Empress: ivory with a deep gold rim (lines, not balls)

| Kind | Core | Main | Edge |
|---|---|---|---|
| Bolt | #ffffff | #fffefa | #6b4c0e |
| Lob | #ffffff | #fffbee | #6b4c0e |
| Beam | #ffffff | #ffffff | #7a560e |
| Grab | #ffffff | #fffaf0 | #5e420c |
| Trap | #ffffff | #fff7e6 | #6b4c0e |

- **Protagonist.** Cyan on the bolt, sliding to azure on the beam (the hue moves with the kind's size, so the family reads at a glance). The old placeholder (#22d3ee) is the cyan of the bolt, made slightly deeper (#10c2ea).
- **Rival.** Deep violet on the bolt, magenta on the beam. Darker than the placeholder (#8a3cff) on purpose: against the Protagonist's pale cyan it is the lightness gap that survives deutan and protan sight.
- **Demon Cyborg.** Molten slag oranges with a near-black iron edge and a hot pale core. Orange only, never a red: the placeholder #ff6a1a is 0.87 red share on linear values and would count as saturated red in the strict flash check; these are all 0.77 or less. The scrap-metal greys (`metal`) are for the wreckage the glow sits on. Wreckage and metal only (Legal).
- **Empress.** **Ivory with a deep gold rim.** The crimson placeholder (#d81f3c) is out (saturated red, Legal's count is 0). Why ivory and not deep gold or dark rose: gold sits on the Cyborg's orange (13 apart, and 1.4 under protan), a dark rose sits on the Rival's magenta, and ivory is the one lane that is nearly colourless, so it is distinct from all three and regal by being the light itself, edged in gold. Lines, not balls (Legal): a thin blade, a tumbling block, a thin line, a loop, two ropes.

## 2. The checks

**Saturated red.** R/(R+G+B) under 0.78 on stored and linear values for every colour in every lane (the limit is 0.8). Maximums: protagonist linear 0.316, stored 0.326; rival linear 0.501, stored 0.471; cyborg linear 0.777, stored 0.593; empress linear 0.666, stored 0.55.

**Readability on the 15 biomes** (every ground, rock, vegetation, subsoil and water tone, at every sky key with the world-light tint; energy is not tinted). The aura rule is 20 CIEDE2000 and 14 under each colour-vision simulation. The whole sprite (core, main, edge) passes in every lane; the keyline adds margin. The main colour alone does not pass everywhere (below).

| Lane | Sprite default | protan | deutan | tritan | Main alone default (worst biome) | protan | deutan | tritan |
|---|---|---|---|---|---|---|---|---|
| protagonist | 31.4 | 21.2 | 27 | 20.7 | 8.7 (ocean) | 10.4 | 9.3 | 6.6 |
| rival | 34.4 | 29.8 | 30.3 | 30.3 | 13.4 (tundra) | 3 | 1.7 | 9.2 |
| cyborg | 29.7 | 28.7 | 28.7 | 27.6 | 5.8 (desert) | 1.9 | 3.7 | 4.7 |
| empress | 28.1 | 28.2 | 26.8 | 26.9 | 4.2 (ice_sheet) | 4.3 | 4.2 | 3.6 |

**Why the main colour alone cannot always pass.** A search over every hue (`art/concepts/energy/search.mjs`) shows only light cyan to light violet (hues about 200 to 330, lightness 0.7 or more) clears 20 against all 15 biomes with one colour; oranges and golds top out at about 8 to 9 against the desert, savanna and beach ground at the golden hours, and ivory at about 6 against snow and ice. The Rival's deep violet (lightness about 0.4 to 0.5) misses against dark water and dark ground on purpose: a light violet sat 15.6 from the Protagonist's cyan under deutan sight (need 20), and the lightness gap is what keeps them apart. All four lanes are therefore judged as a whole: the hot pale core separates from dark ground, the dark edge from pale or warm ground. A small or fast sprite (a thin Empress line, a Cyborg slag shard) is the risk: VFX should keep the dark edge at least 2 px at fight size, and not drop the keyline.

**Lanes apart** (smallest gap between any two mains over every kind pair; need 25 default and 20 simulated, docs/art/colour-vision.md rule 2):

| Pair | default | protan | deutan | tritan |
|---|---|---|---|---|
| protagonist / rival | 35.7 | 27.2 | 24.1 | 31.4 |
| protagonist / cyborg | 50.3 | 47.6 | 51.6 | 54 |
| protagonist / empress | 28.7 | 22.2 | 28.1 | 28.8 |
| rival / cyborg | 56.8 | 60.2 | 58.7 | 31.7 |
| rival / empress | 62.7 | 57.3 | 57 | 56.2 |
| cyborg / empress | 29.1 | 29.5 | 25.8 | 28.7 |

Smallest: default 28.7, protan 22.2, deutan 24.1, tritan 28.7.

## 3. For other directors

- **Combat:** the four `light.colour` values in `energy.*.json` become the `light_colour` of each lane (the bolt main): protagonist #10c2ea, rival #4420c4, cyborg #f58a22, empress #fffefa. The Empress's `/colour` (#d81f3c) goes to the ivory main of her bolt. Per kind colours are in `data/art/energy-lanes.json` (`lanes.<id>.kinds.<bolt|lob|beam|grab|trap>.{core,main,edge}`).
- **VFX:** flat fills in this order, edge then main then core, inside a keyline of at least 1 px; never dim by the world light; burst frames above 3 a second use the main and the edge only, peak frames use the core (Legal fx09: peak frames white-hot below the red ratio, which the cores are).
- **Legal:** please check the lanes against fx09 and e15 and the saturated-red rule; the numbers are in the data.
- **Tools:** a draft schema is in `docs/art/pending/art-energy-lanes.schema.json` (the file warns "no schema" until it is adopted). Underscore keys are free-form.
- **Rendering:** nothing; the lanes are colours for VFX and Combat's light.
