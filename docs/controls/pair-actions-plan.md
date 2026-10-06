# One-key pair actions: a plan (nothing built; Orb's item is still open)

Controls, 2026-10-06. Game Design ruled yes to four remappable one-key pair actions (`brawl-second-pass.md` section 6; `q19-input.md` section 2), "for keyboards and one-handed play". Orb has not picked keys. This is the plan so it can be built in one small slice when he does.

## What it is

Four actions, named as `SimPressRead.pair_read` names the pairs: **`pair_xy`, `pair_xa`, `pair_yb`, `pair_ab`** (the diamond's four edges: light + medium, light + body, medium + heavy, body + heavy). One key bound to one of them sends **exactly what two fingers would send**: the layout expands the press into both cells' presses **in the same build**, so the sim reads the same two edges in one tick (a gap of 0, which `pair_read` accepts at any window). Nothing is new to the sim: **no intent bit, no version, no golden.**

## How the layout does it

- A press of the macro key calls the same code a press of each of the two cell controls would: `_base_press` for the two base actions (X `light`, Y `heavy`, B `signature`, A `context`), so every rule that applies to a real press applies to it: the slow buttons' **latched charge** and **charges off**, the debounce, the held levels (`lightHeld`, `heavyHeld`, `sigHeld`, `contextHeld`) while the key is down, and the release of both when it goes up.
- **Under RT** (the charging stance) the macro presses the two **layer** cells (the two specials, or special and signature), as two fingers would. `pair_read` refuses a pair under RT (Game Design: none for now), so the director reads two presses; the macro is not silent and invents nothing.
- **Held:** a held macro is two held buttons. There is no charged pair (Game Design), so a hold is just the two buttons' own holds: the medium's charge and the heavy's charge both start. A player who wants a tap taps.
- **Never on the Simple layouts**, which have no diamond (the director throws the pairs for Simple).
- The pair itself is **not** decided in the layout; it is the director's read of two edges, with the freshness rule. A macro pressed 5 ticks after an X is a pair only if the freshness rule says so. The macro can never make a pair the rule would refuse.

## Where it lives

- **`data/input/actions.json`:** four rows, `{id: "pair_xy", kind: "press", fields: [light, heavy, lightHeld, heavyHeld]}` and the same for the others. Every field name already exists in the schema's enum, so **no schema change** for Tools. The cell table (which two base actions each id presses) is a small constant in `layout.gd`, not data, because it is the diamond's geometry and the same table as `pair_read`'s.
- **`data/input/layouts.json`:** the four rows are **unbound by default**. A binding is `{controls: ["kb:KeyT"], action: "pair_yb"}` as any other.
- **Remapping:** the remap screen lists the four as remappable actions (a row each, in a "Pairs" group), with the same conflict rules as any action (a key can be bound to one action in a layer). Because a pair is by action, a remapped X or Y moves the pair with it. UI should show "uses keys J and K" and warn when the two cell keys are not neighbours; that is what the macro is for.
- **Tests:** each macro gives both edges in one build, on the base layer and under RT; the levels while held and both released with it; the settings apply; a remap round-trips; no Simple preset accepts one; `pair_read` over a macro's two edges reads the pair at gap 0.
- **Cost:** about 40 lines in `layout.gd`, four rows of data, tests; one slice; no sim-tree file.

## Keys: nothing set until Orb picks

By the fingers (`q19-input.md`): the **solo keyboard** (J X, K Y, L B, I A under the right hand) has all four pairs on neighbouring fingers already, so it needs no default. The **shared keyboards** do not: on P1 (F, G, R, V, one hand's index reach) only X+Y and X+A are comfortable, and **Y+B (G+R) and A+B (V+R) are not**; on P2 (H, M, U, comma) the same shape. If Orb wants defaults they are worth testing on a real keyboard with the person who will use it. Candidates, to try and not to ship: P1 `T` for Y+B (above G and R) and `B` for A+B (below G and V); P2 has no obvious free key near its cluster and `P` and `;` are the only reach.

## One-handed, pad and touch

- **Pad:** all face buttons are one thumb, so the pad needs none; L3 is free (R3 is Escape) and could be a one-key **A+B (the seize)** for a player who cannot press two buttons at once. Optional, Orb's call.
- **Full touch:** the diamond's buttons are 83 dp apart, too close for four seam chips of 48 dp inside it. A pair-chip variant would need its own spread layout (a `touch-full` option for tablets). I would not do it now; two fingers work on a tablet, and the assist doubles the window to 6 ticks.

## Questions for Orb (when he picks)

1. Which keys, if any, on the shared keyboards? 2. A one-key seize on the pad's L3? 3. A touch pair chip layout for tablets, later?
