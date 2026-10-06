# Photosensitivity: what counts as adequate

Owner: Legal and IP Compliance. 2026-10-06. For the flash limit k05 and the energy-in-reach recording (`docs/vfx/reach.md`). **A screen, not legal advice and not a medical opinion.** Photosensitive seizures are a safety matter before they are a legal one. Read 2026-10-06; sources at the end.

## The standard to test against
**WCAG 2.2 success criterion 2.3.1, "three flashes or below threshold"** (W3C; primary). Content must not flash more than three times in any one second, **or** the flashes must be below the general-flash and red-flash thresholds.
- **A general flash** is a pair of opposing changes in relative luminance of 10% or more of the maximum, where the darker state is below 0.80 relative luminance.
- **The area test:** flashes together cover no more than about 25% of a 10-degree field of view; for a screen, a **341 x 256 pixel rectangle at 1024 x 768** is the stated estimate.
- **Red flash:** a stricter test for saturated red.
WCAG is written for web content, but it is the published, testable rule, and the Harding test used for broadcast and games follows the same science. Photosensitive seizures are usually triggered at about 5 to 25 flashes a second, some people at 3 to 60.

## What the recording shows (VFX, `docs/vfx/reach.md`)
Both fighters mashing at the design's rate: 9 full flashes in 3 seconds, never more than 3 in any 60 ticks; the largest frame-to-frame luminance change in a crop round the fighters 0.052, which is under the 10% threshold. The other landings give small sparks and a low-contrast rim at up to 20 landings a second, which is in the sensitive rate range but below the luminance threshold. **That is a good sign and not a pass:** the check is crude (one crop, not the standard's windows), staged at the design's rate rather than the sim's, and counts only this one effect.

## What I would call adequate

| Release | Adequate |
| :-- | :-- |
| **Orb's private playtest (friends)** | The 3-second recording and the counter are enough. Tell the testers in the invitation that the game has flashing effects and that they should not play if they are photosensitive. No further test |
| **Free public web build (itch.io, the public page)** | (1) A **shared flash registry** in the hub counting every full flash from every effect (energy, explosions, signatures, transformations, hit rings, beam clashes), with the cap applied across all of them. (2) **Our own automated check against the WCAG 2.3.1 algorithm** on recorded **worst-case** sequences (both fighters mashing in reach; a beam clash; a signature; the transformation; a building collapse), run on the real build at 1024 x 768 equivalent in 341 x 256 windows, counting luminance flashes and red flashes. The algorithm is public; a small script over the recorded frames is a task for Tools. (3) A **reduced-flash setting** (it exists for reduced motion) and a **plain notice** at first start and on the store page: "This game contains flashing effects." (4) The results recorded in `docs/` with the method |
| **A store release (Steam, consoles)** | The public-web items plus an **independent analyser report**: the **Harding Flash and Pattern Analyser** (the proprietary tool broadcasters and game publishers use; a test house runs it for a fee) or an equivalent recognised tool, on the same worst-case recordings. The free **PEAT** from the Trace Center is the older free option but is dated; a recognised tool or a documented test by a service is the standard. Each console maker has its own accessibility or photosensitivity expectations, **behind its agreement**; ask the platform when in the programme |
| **Never** | A person with photosensitive epilepsy as the test. Use tools, not people |

## Your three questions, answered
1. **The pieces drawn:** pass (in the report).
2. **The shared flash registry:** a condition, but earlier than "any store release". **It is a condition before the first public release of the web build (Stage 1b), not only before a store release**, because a public page reaches strangers, including children and people who do not know the game. It is **not** a condition for Orb's private playtest with friends, who are told in advance.
3. **Adequate evidence:** the table above. For a free web build: the registry, an automated WCAG 2.3.1 check on worst-case recordings, a reduced-flash setting, a notice. For a store release: add an independent Harding-style analyser report.

## Sources (read 2026-10-06)
- W3C, Understanding WCAG 2.2, "Three Flashes or Below Threshold" (primary): https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html
- Trace Research and Development Center, University of Maryland, on photosensitive seizure disorders and PEAT (secondary): https://trace.umd.edu/?p=772
- Reports on the Harding Flash and Pattern Analyser and its use for broadcast and games (secondary).
- Not read: the console makers' accessibility requirements (behind their agreements), and any national rule on flashing content. Ask a lawyer for any country where the game is sold.

## Addendum (2026-10-06): reading the standard for Tools' frame analyser
- **Area:** the **341 x 256 rectangle at 1024 x 768 is the estimate of the 10-degree field, and the threshold is 25% of that field** (about 0.006 steradians, roughly 21,800 pixels). The standard's words: "the combined area of flashes occurring concurrently occupies no more than a total of .006 steradians within any 10 degree visual field on the screen (25% of any 10 degree visual field)". The window is slid across the whole screen (any rectangle). Reading the rectangle as the threshold itself is four times too lenient.
- **General flash:** a pair of opposing changes in relative luminance of 10% or more of the maximum (1.0), the darker state below 0.80, with RGB gamma-decoded (sRGB) before the luminance is computed.
- **Red flash (WCAG 2.2):** a pair of opposing transitions where one state has R/(R+G+B) of 0.8 or more and the two states differ by more than 0.2 in the CIE 1976 u'v' chromaticity diagram. The older broadcast formula (BT.1702) uses (R-G-B) x 320 above 20 instead. Either is acceptable if stated. Counting every pixel that is not a saturated red as zero is not the standard's wording; it is plausibly conservative, but label it "conservative variant" in the doc and name the formula used.
- **Wording to use in public:** "An automated flash check based on WCAG 2.3.1 (general flash, red flash and area), run on recorded gameplay, found no failure." **Never** "safe", "seizure-safe", "tested for photosensitivity", "WCAG compliant" or "certified". Keep the in-game notice. The camera cut's whole-screen dip counts as a flash over the whole screen area: cap it before the public release.
