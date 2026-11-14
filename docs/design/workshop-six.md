# Orb's six open "workshop this" fight questions

Owner: Game Design. 2026-11-13, sprint A1 row A-COMBAT-15. Six of Orb's "workshop this" items have no decision. Each is below in plain words, with a recommendation, a size, and whether it changes the sim's fingerprint (the state hash). **The path's recommendations are the starting point** (`docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md`, decisions 12 and 14). The EP puts them to Orb one question at a time and records the answers word for word.

**Sizes:** S is a page or a small data change; M is one director's build window; L is several directors and a golden window.

| # | The item, in plain words | Orb's last word | Recommendation | Size | Hash |
| ---: | :--- | :--- | :--- | :--- | :--- |
| 1 | **Beam stages:** how many steps of charge a beam can build and hold, growing with your form and power (2 at base, up to 6 at your strongest) | "I'm not sure, workshop it" (2026-11-09) | **Decide after spike S1** (option A's beam in space), and **build it only if it fits inside the beam rework** (A3). The stages already exist as numbers. Option A gives each stage a visible front speed and width (`beam-physics.md`), which is where stages earn their keep | M | Yes |
| 2 | **The timed swat:** releasing a charge just as a beam reaches you, to bat it away. A risk: early or late, and it hits you | "it felt like it could be on track" | **After Alpha.** The deflect you have today (a perfect block, its look by your stick) covers the moment for Alpha. The timed swat waits until beams fly in space (A3), because its timing should read off the visible front | M | Yes |
| 3 | **The catch:** standing against a beam and taking it, pushed back, the ground cratering or trenching under your feet, still standing | "I want this ... workshop this in" (2026-11-01) | **After Alpha,** and it should follow option A naturally: a guard held against a column pushes you back along its line, carving the ground under you. It needs the beam in space and the terrain carve first | L | Yes |
| 4 | **What RT held does:** today it charges your energy. Orb spitballed a "High Intensity" switch that upgrades everything, possibly different for each fighter | "Keep workshopping ... I want to 'workshop how the ki charging ability' ... functions" | **RT held stays the energy charge for Alpha** (the path's decision 12). High Intensity is a per-fighter mechanic, so it's workshopped after Alpha, once the roster of four exists to differ by. In the meantime, the stamina model makes charging read your wind (charging while rested is faster: `energy-stamina-body.md` §3) | S for Alpha (nothing changes); L later | No for Alpha |
| 5 | **The taunt before a signature:** holding the stick for a signature plays a taunt (a voice line and a pose), then a powered-up signature. It's a risk, since he can hit you during it | Spitball, in the signatures answer (2026-11-09) | **After Alpha** (decision 14). The signature's inputs come first (RT + RB + flick for the energy signature, RT + flick for the martial one: A-COMBAT-02 in GW2). The taunt is then an add-on to the hold: **interruptible, never a pause, never slowed time** (Orb: "no time manipulation") | M | Yes |
| 6 | **Whose stick moves whom up close:** in a close fight, should your stick move only your own fighter, and can you walk away alone? | "KEEP WORKSHOPPING, PLAYER AGENCY MUST BE RESPECTED" (decision 10) | **Decided with the gravity well:** asked after spike S2's clip, before the A3 build. My recommendation stands (`gravity-well-reading.md`): **your stick moves just you**, the pull that holds a brawl together never beats a stick he's holding, and you can **walk away alone at a walking pace**, still open to his blows, while the energy-paid escape stays the fast exit | M | Yes |

## What reaches Orb, and when

- **Now:** nothing new. 4 is already answered by the path ("RT held stays the charge"), and 1 and 6 wait on their spikes.
- **After spike S1's clip:** question 1, "Should beams build stages of charge, as in the clip, inside the beam rework?" Recommendation: yes, if S1 shows the stages read on screen.
- **After spike S2's clip:** question 6, "In a close fight, should your stick move only you, with a walk-away that leaves you open?" Recommendation: yes.
- **After Alpha:** 2, 3, 4's High Intensity, and 5, each with a toy first, one at a time.

## How they fit the high-speed fight

Every recommendation keeps to Orb's rule that whatever comes back must complement high-speed combat. Nothing slows the clock. Nothing takes the fighter out of the player's hands except a move he chose. Every risk (the swat's timing, the catch's push, the taunt's opening) is one the player takes on purpose.
