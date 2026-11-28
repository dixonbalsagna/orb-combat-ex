# The Look Profile: Legal's section (spec section 8; brief L6)

Legal, 2026-11-28, against 0f08eb9a. Screens `docs/ep/proposals/look-profile-spec.md` and the catalogue block in `prototype/energy-toy/index.html`. Paper only; nothing is built. A screen, not legal advice. Rows RL-282 to RL-289.

**In one line:** the design is clear. Every catalogue name passes as an in-game label; three slider names and one heading take American spelling. The one thing to fix is not in the design: a small piece of third-party shader code is in the toy and in two game shaders with no credit.

## 1. Catalogue names (RL-282)

Screened as in-game labels (`name-screening.md`, "Labels are screened more lightly"). No searches were run: labels are not screened against registers. "Brand word" below means a word someone else also uses as a brand, allowed for a label and recorded here as the rule asks.

| Kind | Names | Verdict |
|---|---|---|
| Shapes (14) | Glints, Sparks, Waves and rings, Cloud, Falling particles, Lightning arcs, Little forms, Filaments, Ghost lattice, Twin helix, Shards | Pass |
| | Chevrons, Honeycomb, Shell | Pass (brand words) |
| Movements (15) | Breathe in and out, Spiral arms, Swarm that circles you, Stop and go, Jump off the body, Ripple out, Float above the head, Rain down, Cling and vibrate, Arc between points, Orbit, Erratic, the three "Inverted:" names | Pass |
| Finishes (13) | Ember, Frost, Neon outline, Starry void, Soft glow, Smoky fluid, Crackle, Plasma, Inked, Dark energy, Prism, Heat shimmer, Negative | Pass |
| Colors (18) | Coral, Glacier, Molten, Aurora, Eclipse, Ember, Gold, Rose, Moonlight, Dusk, Anomaly | Pass |
| | Venom, Azure, Viridian, Violet, Riptide, Spectrum, Blacklight | Pass (brand or franchise words used as ordinary color words) |
| Sliders (15) and Trails | Power, Size, Speed, Amount, Reach, Erratic, Vibrate, Detail, Form, Spin, Twist, Warp, Trails | Pass |
| | Colour shift, Colour range, Colour drift | **Rename: Color shift, Color range, Color drift** (public strings are American) |
| Screen headings | Colours | **Rename: Colors** |
| Presets (10) | Blue jump-sparks, "Golden cloud, green atom rain", Corona, Backward helix, Ghost lattice, Frost crown, Neon honeycomb, Void swarm | Pass |
| | Black plasma waves | Pass: it describes a motion Orb asked for. It is never shouted or shown as a move's name |
| | Halo script | Pass (brand word) |
| Tiers (4) | common, rare, exotic, mythic | Pass while nothing is ever sold (section 4) |
| Buttons | Random, Mutate, Back, Save | Pass |

**Conditions.**
1. In-game labels only: never a title, store text, tag, fighter name, signature or call-out.
2. A new entry or preset comes back in a batch before it ships. Ids never change; the words can.
3. **The "glyphs" form** draws at most three short strokes inside a ring, from chance. That cannot make a hooked cross. Keep the limit: more strokes, real letters or a set alphabet comes back to Legal.
4. **The two label words** (`label`, for naming a look) are not written yet. When they are, send both lists together, because pairs matter: no real people or franchises, and no word that could pair into an insult (body, race, religion, nationality, sex, age or illness words, or violence done to a person).

## 2. Naming looks (RL-283)

Pass. Two words picked from the game's own lists, no typed text anywhere. The toy's typed name box is dropped on conversion, as the spec says.

## 3. A profile is data, never code (RL-284)

Pass, with these as acceptance rows for L1, L5 and L11:
1. **Read as JSON only.** A look from outside the game is never loaded as an engine resource or scene (`.tres`, `.res`, `.tscn`) and no text in it is evaluated or turned into an object: those can carry scripts.
2. **Only ids and numbers are used.** An id is matched against the catalogue and never used to build a file path, a node name or a shader line. Every number is clamped; not-a-number and infinity become the default.
3. **Bounded.** A size limit on the file and on a network message, five drawn layers, and a cap on the unknown content kept by value.
4. **Nothing else travels.** The travelling form has no id and no label, so a replay or a report carries no personal data.
5. A bad file is refused with a plain line; it never stops the game or damages the settings.

Pictures, sounds or text from players are a different thing and are not covered: they would come back to Legal first.

## 4. Earned, never sold (RL-285)

Pass (ln03). Nothing is bought, and no look comes from chance for money. All unlocked in the alpha (Orb). The campaign's rewards may grant looks. Any sale, paid pack, currency or paid random reward stops here first: store rules and the law in several countries treat paid random rewards as gambling-like. "Unlock all cosmetics" stays free.

## 5. AI disclosure for generated looks (RL-286)

Pass; **the fixed AI line does not change.** The looks a player gets from Random or Mutate are made by ordinary rules from a fixed catalogue, so "Nothing in the game is generated by AI while you play" stays true.
- Keep it true: no model at run time, in the game or its menus.
- Never call Random or Mutate "AI" or "generative" in any word a player reads.
- The catalogue, the presets and the shader were made with AI assistance: provenance row added (`asset-origins.md`), as ADR 0007 asks.
- A look a tester sends back is "something you send": the permission page already covers it.

## 6. "Show other players' looks" (RL-287)

Pass, default on. Looks hold no text or pictures, so there is nothing to moderate. Condition: the viewer's own Reduce flashing, Reduced motion and the game's limits apply to every look on their screen, whatever its owner's settings.

## 7. The shape rows have moved (RL-288)

Confirmed in one line: the shape, pose and look rows of `energy-overhaul-screen.md` section 1, and the flame, gold and white aura rows of `rule-of-cool-screen.md`, are creative rules under Orb (RL-258), and Orb has answered that the toy wins.

Legal keeps: names and call-outs, likeness of a **whole character**, trademarks, copied assets, and player safety (flash and brightness, including a white-hot core, through the spec's door test). A single piece is never a likeness problem. What Legal screens is a **shipped** preset or fighter default as a whole (L7: send the two defaults). A player's own mix is theirs. Hair and body parts (L15) come back when designed.

## 8. Copied code: credit it (RL-289). Not in the spec; found in this screen

- **Where:** the hash functions in the toy (`h11`, `h21`, `h22`) and the same constants in `render/shaders/building.gdshader` (`win_hash`) and `render/shaders/fighter_body.gdshaderinc` (`hash31`) match David Hoskins' "Hash without Sine", published under the MIT license. The toy's capsule distance and smooth minimum match functions Inigo Quilez publishes under the MIT license.
- **Confidence:** Quilez's MIT statement was checked today on iquilezles.org (search). Hoskins' license is from Legal's own knowledge; the search did not reach the original page, so check its header at the source.
- **What it asks:** MIT lets us use it, sell it and change it, if the copyright and permission notice goes with it.
- **Fix (small):** a comment with the notice at each of the three places; the two notices in NOTICES.txt and the in-game licenses screen; or write our own functions instead.
- **When:** before any package leaves Orb's PC. The public repository holds the code today.
- **Ask Rendering and VFX** for any other snippet taken from a published source, so it is listed once.

## 9. Still open

Spec section 8, row 6, the picture checks on the new shader at each quality level and in both looks, is a gate matter (G4, G21) and is not closed by this page. A build with `look_profiles` on reaches nobody outside until its own readings pass.
