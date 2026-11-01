# Move-pool sizing (Animation, 2026-11-01)

A sizing note, not a plan. Asked by the EP for the combo builder (`docs/design/combo-builder.md`; last entry of `docs/ep/vision.md`: deep pools of swappable martial arts moves). Nothing is built. Figures are estimates from what the stick class cost (18 pieces, 4 beam poses, a charge stance, Legal's stills and clips: most of one long session) and what the library holds today (143 posed strikes in 13 manifests, 149 key sets).

## 1. What one new move costs today

A move is one key set: a chamber, a contact and a follow sketch, a spec row (`render/anim/tools/waves/*.mjs`: tip, path, offset, step, legal tags), an entry in `tip_path.mjs`, then `wave_gen`, `pose_lint`, the FK sheet, `joint_scan`, the `anim_check` coverage rows, and Legal's lint for anything held or open-handed.

| Step | What it needs | Where it goes wrong |
| :--- | :--- | :--- |
| Three sketches | a hand placed in the body's own space; a free hand 10 or more units out of the shoulder's blind spot; poles for elbows and knees | a hand out of reach is clamped by `pose_lint`; elbows over 150 degrees need a note |
| Solve | the contact is solved onto the target's socket inside the limb's reach (`reach.json`) | the 30-degree last-pass pull; a different distance changes it |
| Joint limits | `joints.json` per shape; `joint_scan` is gated in `anim_check` | each piece is cheap; a new body needs its own limits |
| Legal's lint | no hand above 76 in a held chamber; palms open with feet down for the heaves; no open hand on the Rival; no piece aims at the head; heads at least 18 apart (e09) | the rules are per piece but the review is by a look, so each held or open piece needs a still |
| A look | the FK sheet, then the clip | this is where the time goes: roughly one in three sets is redrawn once |

Cost, drawn from nothing: about 15 to 25 minutes of work and roughly 10 to 20 thousand tokens a piece, with the sheet and one redraw. Composed from a path template (the generator's section 5.1, about 20 templates by limb and path) and judged on the sheet: about half of that. Recombined (hand-state swap, re-aim to a neighbour socket, link order): no new keys, a few minutes for a batch, and a look at each.

## 2. What one session makes well

One session is one context window, the length of the night's stick-class stretch.

- Drawn, with Legal's stills: **15 to 25** pieces.
- Composed from templates, each judged on the sheet: **40 to 60**.
- Recombined only: any number, but see section 3.

Past those numbers the sheet looks stop being real looks.

## 3. How far recombining gets before it reads as a reskin

The generator's count (`docs/combat/moveset-generator.md` 5.1): the posed strikes reach about **1.7 times** as many shapes with a hand-state swap and a re-aim (the rival 36 to 69, the Protagonist 43 to 73). My read, from the clips: a swapped hand and a re-aimed contact read as the same move after three uses; the silhouette, the hip travel and the path are what a player remembers. So count a derived move as a variant, not a new move: **at most 0.7 of a move each**, and no more than one variant of a key set in a pool.

The grammar itself caps near **175 to 180 shapes a fighter**. Past that the tables run out of limbs and paths; further depth needs new kinds (grapples, throws, two-limb strings), and those are their own systems, not key sets.

## 4. What a custom fighter's different body breaks

Everything is placed in a body's own space: reach 98, offset 58, a pelvis at 32.3 standing, `upright` and `crouched` families, a shoulder blind spot, hit heights 38 to 62 for the bolts. A different body breaks, in order of cost:

1. **Reach and offset** per piece (`reach.json` cover, `step_max`): every piece is re-checked on the `pulled` scan.
2. **Joint limits** (`shape_key` in `joints.json`): a new shape needs its own limits and the whole `joint_scan`.
3. **Target heights and head gap**: the energy pieces, Legal e09 and the contact heights move with height and lean. This is what the standing body did to five checks last night.
4. **Profiles and hand states**: a fighter is derived from another by a profile (the rival from the Protagonist); a very different body needs its own profile and its own look on every piece.
5. **Held and open-hand rules**: Legal's per-body stills.
6. **Load**: more key sets means a longer first bake (the bake-pace table) and a longer `anim_check`.

A body within about 10 percent of an existing one derives cheaply: a profile and a re-check. A very different body is a new wave: treat as 0.5 to 1 session per body just to re-fit and re-check a shared pool, before any new move.

## 5. Numbers for 50, 150 and 300 moves

Assume a pool for one body close to an existing one, derived moves counted at 0.7 and at most one variant per key set, so a pool of N moves needs about N / 1.7 key sets. About 70 of the existing key sets are usable by a given fighter (the identity filter).

| Pool | Key sets needed | New key sets | Sessions (animation) | Notes |
| ---: | ---: | ---: | ---: | :--- |
| **50** | about 30 | **0 to 10** | **under 1** | existing pieces cover it: a generator pass and a look at each. It reads as varied because the library is already wider than the pool |
| **150** | about 90 | **20 to 40** | **1 to 2** | about one session of templates plus one of drawn pieces, with Legal screening and clips. Roughly 1 new key set in 3 is a drawn piece |
| **300** | about 175 | **105 or more** | **5 to 7** | the grammar runs out near 175 shapes a fighter: this is new limbs, paths and kinds, not recombining, and it multiplies the held-chamber stills for Legal. Not a size to promise without a first 150 played |

Add to every row: **0.5 to 1 session per genuinely different body**, and the `anim_check` and bake costs above. Sessions here are Animation's alone; Combat's parts and identity, Legal's screening and Tools' schemas are separate lines.

## 6. What I would do first

Do not size the pool by count. Build 50 from the existing library for one custom body, read it on the sheet with Orb, and measure how many Orb calls a reskin. That reading, not the count, tells whether 150 is worth five sessions.
