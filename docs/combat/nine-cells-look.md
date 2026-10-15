# The nine cells: what each looks like, and what would make it its own

Owner: Combat and Choreography. Date: 2026-10-14. Paper only: no data changes. Orb's bar is that each of the three styles, on each face button, should feel "responsive, useful, and visually engaging each in their own way" (`docs/ep/vision.md`, last section). This paper covers the look from the pieces' side: which blows play, and how they're styled. Animation's audit covers the motion.

**How this was read.** From the chain on main (3198301f), not from footage:
- Which pool each cell draws on, from `data/combat/recipes.json` and the hook in `sim/director/brawl.gd`.
- Which style row the renderer gives a brawl blow, from `render/anim/anim_fighter.gd` `_press_style`. A brawl blow carries no style of its own (only zips and double hits do), so a light plays the speed row, a medium the medium row, a heavy the super row, and a held X's burst blows the burst row.

Counts are given as Anti-hero / Protagonist.

## The audit

| Cell | Today: the pieces | Today: the look | Its own look |
| :--- | :--- | :--- | :--- |
| **X tapped:** the beat | Any light: 27 / 24, kicks and drops included. 7 / 5 when the stick points toward him | The speed row. The beat isn't built, so a tap never plays the tech row | **The tech row on the beat:** a pinned pose, three ghosts and the skill pool (15 / 13, already in the data), as the perfect follow-up (§16) is built. Off the beat it stays the one X that throws kicks, drops and backhands. The flurry never throws those 15 / 13 pieces |
| **X mashed:** the pressure | The flurry: 12 / 11, hands, elbows, knees and a shoulder. Every one is also a tapped piece | The speed row, plus the staged double hit (tech) in 68% of matches. Already apart from the tap: never a kick, and quicker | **Its own today.** The blur of hands Orb liked. Nothing to add |
| **X held:** the easy pressure | **The burst (blows 2 to 8):** quick hands, then elbows and knees, then any light, by the gap before each. **Then the floor pace:** any light, the tapped pool exactly | **The burst** plays its own row: a gap that narrows, then grows, plus a set pose. **The floor** plays the speed row from the tapped pool. After the first second, a held X looks like a slow tapped X | **The floor in the burst row,** at its 8-tick gap. **Its pool from the mid class** (13 / 12: elbows, knees, short hands), which is the burst's own class for a gap of 8. Then a held X never throws a kick, and keeps the steady grind its ring shows |
| **Y tapped:** the stop | The mediums: 10 / 10 | The medium row | **Lines and rises only:** a short check straight in or straight up. That is 5 / 4 pieces: uppercut, rising knee, rising fist, driving knee, headbutt; for the Protagonist, rising palm, rising knee, uppercut, push |
| **Y mashed:** the grind | **The same 10 as the tap** | **The same row as the tap.** The pace is the only difference | **Drops and arcs:** full blows from above and around, which is the drum roll. That is 5 / 6: dropping elbow, stomp, hammer fist, backhand, roundhouse; for the Protagonist, overhand, axe kick, stomp, haymaker, crescent, body hook |
| **Y held:** the patient close | **The same 10 as the tap.** The charged medium is Encounter's pass 2 (in scratch), so on main a held Y is still a medium that goes by itself. The 4 long wind-ups in `brawl.medium.held` are never asked for | The tap's row. Animation's load pose for a held Y is drawn, but nothing on main reaches it | **The four long wind-ups only,** once the charge is built: double hammer, spinning elbow, crossed-arm ram, drop kick; for the Protagonist, crossed-arm ram, drop kick, spinning back kick, spinning heel. It becomes the only Y that turns or leaves the ground, after the load pose |
| **B tapped:** the hammer | Any heavy: 10 / 10. **In an opening,** the launcher (8 / 7), sent by the stick, or the hammer while the launcher rests | The super row. In an opening, its own: a launch, or a hammer that staggers him in place. **Cold,** the same as the mash | **Keep all ten.** The hammer needs every send, and its look is the launch |
| **B mashed:** the advance | **The same 10 as the tap** | **The same row as the tap** | **Lines and drops:** each heavy steps or falls in, so the walk forward is the picture. That is 6 / 4: ram, falling heel, knee, hammer fist, low edge kick, plate to the arm; for the Protagonist, falling palm, stepping edge kick, blade to the jaw, hammer to the arm |
| **B held:** the big read | **The same 10 as the tap.** The hook already asks for the held cell at the charge, but it points at the same pool | The super row, plus its own load pose and the flash at full: the only B with a picture of its own | **Turns, arcs and rises:** the blow wound up in plain sight. That is 4 / 6: plate swing, hook, elbow heave, fist heave; for the Protagonist, turning palm, unwinding edge kick, palm heave, ball-of-foot heave, knee to the legs, elbow to the jaw |

**In one line.** Today three cells look like their own: the mashed X, the burst part of a held X and the held B. The tapped B does too, but only in an opening. All three Ys look alike, and so do the tapped and the mashed B.

**The splits go by the piece's path,** which every piece already carries:

| Button | Tapped | Mashed | Held |
| :--- | :--- | :--- | :--- |
| Y | Line or rise | Drop or arc | A long wind-up |
| B | All ten | Line or drop | Arc, rise or spin |

So the pool builder can make them for any fighter from his moveset, and the roster rows split the same way. Every pool above keeps at least 4 pieces, enough for "never one of his last two" and "never two running to the gut".

## What it takes

| What | Whose | Size |
| :--- | :--- | :--- |
| Held B's pool: a new `brawl.heavy.held` that `heavyHeld` points to | Mine, in a data window | Data only: the hook already asks for it |
| Held Y's pool: `brawl.medium.held` cut to the four long wind-ups | Mine, in a data window | Data only, but it shows only once the charged medium asks for it (Encounter's pass 2) |
| Floor pace from the mid class: `burstFloor` to `burst.mid` | Mine, in a data window, on Game Design's word | One line. The `_about` text says the floor is the slow class, which I wrote |
| A key for a mashed medium and a mashed heavy | Encounter's hook | Small. The press already knows it is in a flurry. With no key in the recipes it falls back to the tap's pool, so today's data still works |
| The floor's blows in the burst row | Animation's renderer | The blow already carries `floor` |
| The tech row on the beat | Encounter (§16), then Animation | Waits on the perfect follow-up |
| The splits in the pool builder, by path, for any number of fighters | Mine, in scratch | Small |

## Pieces to add

1. **The Protagonist: one more medium on a line or a rise.** His stop has 4 pieces, which is the thinnest pool here.
2. **The Protagonist: one more heavy that steps or falls in.** His advance has 4.
3. **The Anti-hero: one more heavy that turns or heaves.** His big read has 4.
4. **Nothing for the X cells.** The skill pool and the mid class are filled already.

Each is one row in the moveset generator and one key set for Animation. The generator picks the exact shape under Legal's lists and each fighter's identity, and never takes another fighter's own blow.

## Not done here

- **No footage.** Animation's audit is the one that has looked.
- **The four roster sketches aren't split yet.** The rule above applies to them, but their counts aren't checked.
- **Whether each split cell is still useful** is read on Game Design's proof rows and alone rows, after it is built.
