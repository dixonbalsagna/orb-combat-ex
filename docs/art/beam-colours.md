# Beam colours: Art's answer on VFX's families (2026-10-16)

Owner: Art Director. For VFX's `docs/vfx/beam-look.md` (parked patch `docs/vfx/pending/energy-and-choreo`). A beam's colour is the fighter's lane colour (`data/art/colour-vision.json`, so the presets follow), and its second tint is that colour's hue turned by `hue_shift` at the same luminance (the patch's `shifted`, in HSV, found by bisection). I computed the second tints as the patch does, for the default look and each preset, and checked them against the wound and guard marks, the sky, Legal's hue families and each other.

## Confirmed: the Protagonist, cyan to azure, +30 degrees
Default `#8fd6ff` (hue 202) gives `#c0c8fa` (232): a pale periwinkle at the same luminance (0.79), inside his family (150 to 250). Protan `#30a6a6` gives `#4499ed` (210) and deutan `#35b6ab` gives `#46aaf0` (205): both azure, inside the family.
**One exception: the tritan preset takes -30, not +30.** His tritan lane is `#9c90d5` (250), and +30 lands on a violet (`#b689cb`, 281), which is the Anti-hero's family. -30 gives `#8498c3` (221), a steel blue.

## Correct the sign: the Rival, violet to magenta, +34 degrees (the patch has -34)
-34 turns the hue the wrong way: `#9a80d8` (258) becomes `#768cc8` (224), a **blue**, outside Legal's range for him (260 to 320) and **in the Protagonist's azure**, so the two beams would share a colour. It is also only 11 from his lane colour (3 to 5 under the presets), so the shimmer would barely show. +34 gives `#be77c9` (292), orchid-magenta, inside the range and 24 from the sky.
Presets: protan `#6b0bcb` gives `#8d0884` (304); deutan `#5b0bcb` gives `#810783` (299); tritan `#6b0bcb` gives `#8d0884` (304). **Cap it:** the shift must keep the second tint at 320 or less (Legal's upper edge): `min(34, 320 - hue)`, which matters only if Orb picks the magenta-forward aura (hues 280 to 300).

## The dummy (REFERENCE): quiet and neutral, +12 degrees
His lane colour is `#c6bade` (260); +12 gives `#ccb9dc` (273), 1 to 4 from it: effectively one colour, as asked.

## Luminance and the flash register
The second tint matches the first to three decimals in every case (for example 0.792 and 0.792 for the Protagonist, 0.549 and 0.548 for the Rival), so the shimmer carries no luminance step. Under protan and deutan vision the shimmer between two tints is small for the Rival (the dark preset lanes), so it is a texture there, not a signal: the lane colour carries the beam.

## Marks and sky
The second tints are not lanes, so the marks and sky rules are not required of them; for the record: the Protagonist's default second tint is 14 from UI's "fresh" mark (it is a pale periwinkle, near that neutral); the Rival's is 20 from the nearest mark and 24 from the sky near the fighters. Both are VFX layers with the lane colour in the core.
