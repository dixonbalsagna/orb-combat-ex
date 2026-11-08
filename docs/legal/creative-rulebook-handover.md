# Hand-over: the creative rulebook (audit CD-15, Orb's ruling of 2026-11-07)

Legal, 2026-11-07. Orb asked for "a solution moving forward to the overzealous policing that legal & IP has been performing." The audit found 74 pose, gesture and look rules filed as legal safety although they cite no law (false-alarms.md, item 1). Orb's ruling: those rules become a creative rulebook owned by **Art and Animation under Orb**. Legal's role is **names, the likeness of whole characters, trademarks and copied assets, plus genuine player-safety items such as flash, data and ratings.** This page is the hand-over. It is paper only: Legal edits nothing outside `docs/legal/`, so the EP routes it and Art and Animation decide where the rulebook lives (suggested: `docs/art/creative-rulebook.md`, with Animation's pose rows beside `docs/animation/`).

## What the rulebook is

- **Advice and taste, owned by Orb's creative leads.** A row says "we keep this look away from the genre's best-known shapes" or "this reads better". It is a margin for judgment, not a legal line. Art and Animation may change, drop or waive any row, and Orb has the last word.
- **It never blocks a gate or a release.** A lint may still fail a build for a row that Art or Animation chose to keep as a lint (`anim_check`, `pose_lint`, the held-pose lint, the movegen generator). That is a studio choice, owned by them.
- **No request to Legal is needed.** Nobody has to ask Legal about a hand shape, an arm angle, a glow's strength, an aura's colour or how many marks stack.

## What moves (the pose, gesture and look rows)

| Group | Rows | Was |
|---|---|---|
| Banned shapes and sequences | b01 to b14, s01 to s09 (`movegen-banned.json` banned, bannedSequences) | Wind-up and strike shapes and their sequences |
| Motion | m01 to m12 | Teleport-style steps, ghosts, zip chains (m05's ghost budget is also a code constant in `ghost_tally.gd`) |
| Energy poses and looks | e01 to e10, e12 to e16 | No ball in or above a hand, one firing hand, plain straight beams, kit poses |
| Grabs | g01 to g08 | Grab and throw shapes |
| Held poses | h01 to h10 | Hand depth, arm height, palm direction, beckons |
| Marks and stacking | k01 to k04 | How many marks may show, thin lane-colour auras, charge rings |
| Flurry | f01 to f05 | Flurry and echo shapes |
| Look rows | w03 (landmark looks), fx01 and fx02 (shine, cash-in), sg01 (barrage), mc04 and mc05 (rally sells, elite tricks), withdrawn w01 and w02 | Silhouettes, cues, signature staging |
| Screens | `glasses-rules.md`, `animation-data-rule.md`, `movegen-screen.md`, `stances-and-gestures-screen.md`, `zip-screen.md`, `brawl-screen.md`, `three-strengths-screen.md`, `super-heavy-screen.md`, `launcher-and-reach-screen.md`, `q3-screen.md`, `roster-sketches-screen.md`, `agency-pass-screen.md`, `energy-and-pieces-screen.md`, `sigvariants-screen.md` | The written reasoning behind the rows; Art and Animation may copy, rewrite or retire them |

The corresponding rows in `review-log.md` are tagged **Moved: creative rulebook (CD-15)** and no longer count as Open. In `movegen-banned.json` the rows stay in the file only because the generator and lints read that path (a top-level `_scope` note says so); Tools may re-point the lints to the new home, and Legal will not edit those rows again.

Two mixed rows are split rather than moved whole:
- **k03** (charge flash or ring): the colour and size advice is creative; "never white or red flash" is a flash-safety limit and stays with Legal under the register (k05).
- **e13 and e14** (mines, snares, trap pillars): the shapes are creative; a glow's rate (at or under 1 Hz, 6-tick fades) is a light limit and stays with Legal under k05 and k06.

## What Legal keeps

- **Names:** every name a player or the public sees (fighters, moves, places, planets, titles, the store name), the exact-phrase and sound-alike screens, e11 and n01 (franchise-shaped move words such as ball, disc, wave), w06 and w07 (place names), the title search (CD-06).
- **The likeness of whole characters:** the "would someone who knows the show say 'that's the one from the show'" test applies to a whole character, a named character's signature look as a package, or a fighter built to read as one. A single pose, gesture or hand shape is not a likeness and is not Legal's.
- **Trademarks and copied assets:** third-party fonts, libraries, audio and art with a licence row (`licence-register.md`), the origin log for AI-made assets (`asset-origins.md`), the Suno terms, franchise material that was copied or traced.
- **Player safety:** flash and light (the register, k05, k06, fx03 to fx10, w04 and w05, the nightly and the release gate), data and privacy (public pages, p01 to p04), ratings and stores (c09, p02, the questionnaires), harm to people (c08, c10, c11, the people lines ln01 to ln08, RL-247 and RL-257).

## Suggested way to run it

1. Art and Animation copy the table above into their rulebook and decide which rows stay as lints, which become taste notes, and which they drop.
2. Where a row's old Legal reasoning is useful, link `docs/legal/` pages instead of copying the legal framing; Legal does not hold a pose to a "GO, CONDITIONAL or NO-GO" any more.
3. If a pose, gesture or look ever points at a whole character, a name or a copied asset, Art or Animation sends it to Legal as a name or likeness question; everything else they decide themselves.
4. The charters (`docs/directors/legal.md`, `art.md`, `animation.md`) and `CLAUDE.md` say Legal screens "poses" and "designs": the EP changes those lines to match this scope (Legal does not own those files).
