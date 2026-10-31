# Orb's vision (questionnaire 1, 2026-09-28)

Orb's answers to the first scope-and-vision questionnaire, summarised by the EP. Every director reads this before working on anything it touches. Orb's full notes on the fighters are kept locally in .private/orb-answers-2026-09-28.md. They name franchise inspirations, so never quote them into a committed file.

## Tone and feel

**Tone.** All four tones at once: mature violence and destruction on a planetary scale, a humorous voice, and a sincere, respectful homage to the source anime's aesthetics. Orb's line is "staples yes, signatures no".

**Match feel.** A match is the finale of a bitter rivalry after a whole season of build-up, compressed into an epic showdown of seven minutes or more. It has one-liners, carnage, destruction and high stakes, like a full-throttle reimagining of a lost high-octane flash game. It is never two fighters trading aimless jabs from opposite corners. Combat looks choreographed, seamless and exhilarating, and it expresses each fighter's identity at every moment.

**Carried over from the fan-game predecessors:** comedy, free flight, huge arenas, beam struggles, transformations, destruction, playing with friends, and a modding scene.

## The four fighters

These are archetypes. Legal is checking them against "staples yes, signatures no" in docs/legal/fighter-concepts-review.md (pending). Design mechanics so they survive re-skinning.

1. **The Protagonist.** An earnest martial artist with a handful of epic transformations that unlock along parallel tracks. He powers up when a challenger gives everything they have. He fights to protect his loved ones, but his fixation on the fight itself causes massive collateral damage. He has a huge hand-to-hand repertoire, strategic teleports mid-attack, and ends fights with an all-out energy finisher. His unique ability: he gathers scattered artefacts to move the fight somewhere no one else can get hurt. Once there, he reveals his final form.
2. **The Anti-hero.** A brooding rival whose sense of justice comes second to his ego and pride. He has a few epic transformations that boost both his power and his self-importance. His style is brutal and showy: he drags fights out to enforce his own sense of hierarchy, bombards the foe with elaborate energy barrages until they submit, then finishes them by hand. The player chooses whether he wins on his own strength or accepts a fusion item thrown by the Protagonist. Fusing creates a stronger combined fighter with its own visuals and abilities.
3. **The Galactic Tyrant.** He starts by watching from behind two or three autonomous minions, who take turns fighting. Once they fall, he transforms through a comically long chain of stages (ten or more), each with a subtly different moveset, up to a full-power form with its own abilities. He torments foes with precise cutting beams from range and uses tail attacks and dominant power attacks. His personality: confident, leering, boastful and quick to anger.
4. **The Demon Cyborg.** He consumes civilians to power up, each one adding a small multiplicative bonus. He then molts into a form that can turn nearby civilians into sandwiches, which grant further bonuses. His final form requires hunting down and eating his small demon companion, which is hidden somewhere on the planet. In that form he is the fastest fighter of all, blitzing through portals that spew monstrous sandwiches, a light-hearted parody. His body is dark red, wrapped in mechanical wiring and chainmail-like electrical parts. His true vital point is a stylised quantum microchip in a translucent orb; the rest of his flesh regenerates.

More characters must be addable after launch (see the Modding and Extensibility charter).

## Answers

| Topic | Answer |
|---|---|
| Roster at 1.0 | 4 fighters |
| Civilians | Keep casualties |
| Controls | Keep stances and the fight director |
| Modes at 1.0 | Local 1v1, versus AI, arcade or survival, training sandbox, 2v2 or free-for-all |
| Online | After launch |
| Match length | 5+ minutes (the feel above says 7+) |
| Planets | Procedural |
| Presentation | 2.5D side-on |
| Art style | Cel-shaded and low-poly; Art to pitch |
| Asset creation | Procedural; AI-generated assets allowed |
| Music | Audio to pitch |
| Platforms | Windows, Linux, macOS, browser, Steam Deck. Mobile is parked until after the PC launch (Orb, 2026-10-28; ADR 0011) |
| Minimum hardware | Old laptops |
| Input | Keyboard and gamepad equally |
| Distribution | itch.io, Steam (free), GitHub releases |
| Licence | As Legal recommends: MIT for code, CC BY 4.0 for assets, DCO for contributors |
| Going public | Now, once the prerequisites are done (licence files, repo name, Legal's wording pass) |
| Timeline | No deadline, hobby pace |
| Reporting | A weekly one-pager |
| Budget | Zero; Pro plan only (ADR 0005) |
| Director effort | Opus at xhigh, Sonnet at high |
| Extra directors | Rendering and Technical Art; Modding and Extensibility |
| Name | An evocative title, pitched by Narrative |

## Questionnaire 2 (2026-09-29)

| Topic | Answer |
|---|---|
| Transformation triggers | Character dependent |
| Protagonist and anti-hero stages | 6 or more |
| Tyrant's forms | Jokes first, then a few real forms |
| Minions | AI only |
| Fusion | A unique final-form mechanic; could be reworked as another ability |
| Relocation | A barren proving ground; artefacts scattered on the planet, found mid-fight |
| Cyborg's companion hunt | A quick detour, under a minute |
| Violence | Graphic, including the Cyborg's consumption. Rating target: Mature |
| Signature replacements | Discuss each with Orb before choosing |
| 2v2 | All four fighters on the field at once |
| Arcade | Both a rival ladder and endless survival |
| Match shape | One continuous fight |
| Endings | KO, or the planet is destroyed |
| Procedural planets | Vary in size, biomes and settlements; seeds are shareable. The planet can be destroyed at top tiers |
| Mobile controls | Both virtual stick and simplified tap, player's choice |
| Copyright holder | Curtis A |
| Repo | Renamed to wraparound-fighter, then to orb-combat-ex when the title was picked |
| Token plan | Approved (ADR 0005) |
| Lemming Ball Z provenance | Unknown; nothing carries over |
| Feel reference | A well-known series of flash action animations (named in .private/) for its choreography and brutality |
| Title (final) | **Orb Combat EX**, picked 2026-09-29. Legal: conditional; resolve the OrbCombat GitHub project before any store page |
| Title history | Orb dislikes "Skyburden" and liked the direction of "Skyburners" (screened out: a Destiny faction). Round 2 sounded machine-made to Orb; round 3 aims for names a person would pick |
| Engine | Godot 4.7 with GDScript (ADR 0001, confirmed 2026-09-29) |
| README line | "A free, open-source fighting game about wrecking a planet. No combo lists: pick a stance and the game choreographs the exchange. Inspired by the classic anime energy-brawlers." (Orb's blend; final wording waits on the licence) |
| Repo visibility | Stays public so Orb can share the prototype with friends |
| Licence | Undecided: Orb may want to keep commercial rights. LICENSE and LICENSE-ASSETS were removed from the repo root on 2026-09-29 (all rights reserved by default until Orb decides; the drafts stay in docs/legal/drafts/). Options in the EP's 2026-09-29 chat: open code with protected art; everything non-commercial; or MIT plus CC BY as now |

## Questionnaire 3 (2026-09-29): gameplay and features

Orb had played the Godot greybox before answering.

| Topic | Answer |
|---|---|
| Greybox pace | Too fast |
| Next priorities | Better fighting feel, the first real fighter, bigger destruction |
| Health | **No health meters.** Location-based damage, where each fighter handles incoming damage slightly differently. Tension and dramatic build-up without traditional bars |
| Finisher | Always: the last blow is a fighter-specific finisher |
| Planet destruction | Pinned. Explore large-scale destruction (molten lava spewing from the mantle) short of full destruction, zero-g combat in space if the planet does go, and how stage transitions work |
| One-liners | Both: barks during play and short pauses at set pieces |
| Cinematics | Yes, and longer than 3 s is fine |
| Ego meters | Yes, visible (Respect, Pride, Wrath, Hunger) |
| Hit while transforming | Long transformations can be interrupted; the Tyrant's quick revisions are safe |
| Transform timing | Per fighter |
| Form duration | Permanent, except drain states |
| Transformations | Power-ups and transformations are genre staples, and Orb wants the space explored further. The beast stage was only an example |
| Multiplier stage | Pitch a replacement |
| Artefacts | Orb wants orbs: find a non-infringing way to include them. A heavy hit scatters one |
| Teleport tell | A ripple in the air |
| Anti-hero fusion | A true merge with an original trigger and look (Legal screens it) |
| Tyrant appendage | Keep a tail, redesigned so it doesn't read as the franchise's |
| Tyrant forms | The numbered "revision" joke |
| Human Tyrant during the goon phase | Snipes support shots and taunts |
| Goons | Three: bruiser, marksman, speedster |
| Cyborg food mechanic | Pitch it |
| Cyborg companion | A backup drive that runs around; he catches and docks it |
| Cyborg weak point | Pitch it |
| Asymmetric roster | Yes, with win rates still 45 to 55% |
| Planets | Earth-like and alien biomes; day and night plus weather; bigger for 2v2 |
| 2v2 revive | Yes, with a risky beat next to the fallen teammate |
| Mirror matches | Yes in 1v1, not on the same team |
| Unlocks | Everything unlocked from the start |

**Greybox notes (Orb's words):** "destructible terrain should look more like craters than canyons, water should have a simple fluid simulation, fighters seem to always fight in the ocean underwater, civilians seem too tiny, more attacks launching each other across the map, make the scale of the map seem more like a full planet"

**Anything else (Orb's words):** "I want procedural systems to create near limitless sets of attacks. Voice lines don't have to be voice-acted, if each character has distinct grunts and growls and laughs those could be used to evoke emotionality of lines that appear on the screen. I want one liners and taunts and reactions that depend on all kinds of variables, so there should be a very large set of lines that can potentially be seen accounting for every situation. the combat director I'm envisioning needs to be able to create extremely vast movesets for each character, with some unique special abilities for each character, but each fight should feel unique, with dynamic combos and attacks that gives the player the sense they're not going to see the same exact series of attacks twice."
**Craters and beams (Orb, confirmed 2026-09-29).** Ground impacts make round bowls with raised rims and ejecta, sized by impact energy. They're localised in depth, not slots through the whole ground strip. Beams scorch and leave trails of destruction, and the results scale up with the beam's power: stronger beams are more intense and more destructive.

**Damage model (Orb, 2026-09-29).** Variant A, Wounds (docs/design/damage-model.md). Game Design pitches: the optional wear readout; Rally rules per fighter (Orb: 'I'm thinking per-fighter'); and the downtime between exchanges. For downtime, the player flies freely, with dynamic set pieces and quick verbal exchanges. Pitch ideas that keep it engaging.

**Signature picks (Orb, 2026-09-29).**
- Cyborg food: Press.
- Cyborg weak point: Rail chip.
- Tyrant's tail: Bladed mantle, a cape with blade hems used like a tail.
- Protagonist power stage: Overcommit, made recognisable but non-infringing (Narrative round 2).
- Orbs: recognisable but non-infringing (Narrative round 2, within Legal's q3-screen §a).
- Fusion: may be replaced by a unique Anti-hero power-up; keep 'sacrifice pride for power'.
- Wear readout: a combination of the aura crown with wound cards and the silhouette, per fighter (Game Design pitches).
- Rally: Game Design's four per-fighter Rallies approved, with looser limits.

**Round 3 answers (Orb, 2026-09-29).**
- Power stage: 'something like his blood goes from heated to simmering to boiling, causing internal damage that adds up but gives big temporary boosts.'
- Anti-hero power-up: keep working. Orb wants it 'recognizable but non-infringing' and asks whether fair-use and parody rules can protect a good-faith tribute (Legal to explain).
- Voices: 'good start, let's work on this further.'
- The orb-payoff question was unclear; the EP is re-asking it plainly.

**Round 4 answers (Orb, 2026-09-29).**
- Hot Blood: the mechanic, cards, look and sound are liked. Names are **pinned**: Orb will think up names later, and they must not sound LLM-generated. Treat all current names as placeholders.
- Anti-hero: Orb likes Drop the Act (1v1) and Humbled. Keep pitching ideas in that theme.
- The orb payoff (the fold to the proving ground): **space folds inward** toward the Protagonist and the planet vanishes around them. It needs an in-world reason, with the hero saying something like 'we can't hurt anyone innocent here'.

**Focus and matchups (Orb, 2026-09-29).**
- **1v1 first.** 2v2 questions (the fold in 2v2, team rules) are deferred.
- Lines change with the matchup: who is facing whom, and what is at stake. The Protagonist is lighter against a sparring rival and more serious against someone threatening to end the world.
- Work the matchups out case by case with Orb.

**Matchup feedback (Orb, 2026-09-29).** 'These are a great start. I want as many possibilities.' Likes: the Tyrant's revision numbers, and the Cyborg asking for a manager. Tone fix for the Protagonist: the fight comes first and the repairs after. Not 'That was a home. I'll fix it. Then I'll deal with you.', but more like 'I'll help fix it once I'm done with you.' Orb read the Anti-hero's 'Fifth.' as a typo for 'Filth'.

**The Tyrant becomes an Empress (Orb, 2026-09-29).** The Galactic Tyrant is now a galactic empress (she/her). Everything else carries over (the revision joke, three goons, the bladed mantle, the surveyor line), and Narrative pitches how she's rewritten. Legal's revision 9 to 12 silhouette and palette rule still applies.

**The Empress, picks (Orb, 2026-09-29).**
- Who she is: 'very image focused, hates to have to change appearances, so has settled on their base form to keep paperwork tidy. Since the fight pushes them to transform, they need to update their paperwork to keep their legal status current. Bureaucratic and confusing on purpose. Let's work on this theme.'
- Goons: Guard of honour.
- Voice: approved (revision numbers, a royal 'we' that slips to 'I' when hurt, opponents are 'petitioner').

**Transformations are respected (Orb, 2026-09-29; this overrides questionnaire 3's 'long ones interruptible').** 'With few exceptions, I think the transformations should be cinematic and uninterruptible. The gauge or some mechanic must fill or otherwise complete, which can be stopped, but once the transformation happens it should be respected the way anime characters seem to traditionally allow their opponent to transform.' Also: the Empress's backdated-filing comeback, Orb is unsure ('I don't know about this'), so pitch alternatives. The rule that her filings don't register in the fold is dropped: her filings work everywhere.

**Empress paperwork is diegetic only (Orb, 2026-09-29).** 'I don't like the idea of visible paperwork or stamps. She could have voice lines about how frustrating it will be to go through the mountain of paperwork later, or some other diegetic clues as to what's going on.' No stamp cards and no visible forms. The paperwork lives in her lines and in in-world clues. The Appeal is not approved: pitch her comeback again without visible paperwork. The fold becomes a respected cinematic (yes, same rule).

**Empress comeback, round 2 (Orb, 2026-09-29).** None of Off the record, Close ranks or Recess approved: 'pitch more ideas. I like a straightforward brawl that must defeat the guards before getting to the empress, damage transference isn't exactly how I imagined the character.' The retinue rule is rejected: fallen guards leave, and the gestures come from her remaining guard or from her.

**Empress comeback: Encore (Orb, 2026-09-29).** On the brink, all three guard return for a short, harder second goon phase while she withdraws, snipes and taunts. If they hold, one region mends; if they fall first, she is on the brink and in reach. Once per match.

**First real fighter: the Anti-hero (Orb, 2026-09-29).** Built after the Wounds slices and roster-as-data (docs/architecture/wounds-plan.md).

**Rims and buildings (Orb, 2026-09-29).**
- Crater rim height depends on how hard the impact is: harder hits throw up taller rims.
- Buildings exist in both the foreground and the background (depth layers). Normal movement never collides with them, and neither do most launches. The director chooses when a launched fighter crashes destructively into a building, and it should often pick an individual building to take the brunt of an impact. This is part of stage design.

**Building impacts (Orb, 2026-09-29).**
- No rooftop cover.
- Targeting is a mix of personality and drama, weighted toward personality: the villain seeks tall, occupied towers and the hero avoids occupied ones.
- One impact can go through several buildings: 'a classic villain trope is to send the hero careening through multiple skyscrapers in one attack.'
- Anguish weight: Game Design's default (no extra multiplier) stands unless Orb says otherwise.

**Life-size scale (Orb, 2026-09-29).** 'Right now everything looks very small compared to the fighters. I'd like to see a much larger world with buildings and civilians scaled up to be life-size compared to the fighters.' World is drafting docs/world/scale.md, to land before building-depth slice B1.

**Scale answers (Orb, 2026-09-29).**
- Planet size between small and medium ('between 1 and 2', maybe larger after it's felt). Fighters should launch each other through the landscape and into different biomes several times per fight.
- A flat-out dash around the planet takes 10 to 20 s: anime-fast.
- Destruction: 'as the fighters power up, the destructiveness should keep scaling. Implement novel ways to keep this interesting so the players don't just see it as map painting, but rather interfering and actively engaging with a real landscape.'

**Living destruction picks (Orb, 2026-09-29).** From docs/world/living-destruction.md: fire and smoke cover (with cover made and taken), landslides, and the top-tier set: lava, quakes and rifts. Build order: LD1 fire and smoke, then LD2 landslides, then the tier-4 lava, quakes and rifts, leading toward the pinned planet-destruction finale.

**Blast-levelled buildings (Orb, 2026-09-29).** When an impact or ground blast craters a city, the buildings it levels collapse into their own footprint like a controlled demolition, and leave rubble behind.

**Knockback slide (Orb, 2026-09-29, after playing the craters build).** Orb likes the craters build. Against ground, a launched fighter shouldn't bounce and leave several craters. Impacts should be weighted toward a **knockback slide**: 'a character is hit with immense force or is braking from high-speed movement, dragging their feet or hands along the ground to stay upright, which leaves a deep trench, shatters concrete, and kicks up massive clouds of dust.' On water, a shallow incline skips the fighter across the surface (bouncing is good there). Orb also noted 'some visual peculiarities we can touch up'.

**Audio picks (Orb, 2026-09-29).** Grunts are synthesised first, and Orb may record laughs and the munch later. AI-generated audio is allowed once Legal clears the specific tool's terms. Wear and heat audio is on by default, with a slider. The music direction will be picked by ear from Audio's three 30-second sketches.

**Anti-hero look, round 1 (Orb, 2026-09-29).** None of Art's three silhouettes (Column, Bell, Standard) picked yet: pitch more. No cape. Shed Regalia: pitch it later. The music pick is pending until Orb listens.

**HUD clutter (Orb, 2026-09-29).** The aura crown rings should pop up for a moment when something happens (a hit, a stage change), then fade back. No persistent clutter in the way of the fight choreography. 'Let's revise this because it looks like a good start.'

**Character art direction (Orb, 2026-09-29).** F, the Coil, is 'a good start' for the Anti-hero. Orb isn't happy with the character designs yet and wants them **striking and recognizable**, with more style passes. Faceless or blank heads could be a style choice if the style is distinct enough. Art proposes several overall character art directions. Legal's note stands: nothing borrowed from Madness Combat's look.

**Character art direction, round 2 (Orb, 2026-09-29).** Blank is the closest and a good starting point. Pitch more styles and mock-ups building from it. Faces: pitch it, Orb wants a unique style. Poster: disliked ('the color scheme is too jarring'), and its use for key art is undecided.

**Staging the fighters: cheat out (Orb, 2026-09-29).** No strict side profile. Fighters turn slightly toward the camera, three-quarter, as stage actors 'cheat out', so stances, chest designs, limbs and demeanour read. Three techniques, as in modern 2.5D fighters:
1. Rotate the torso, hips and head toward the camera.
2. A hybrid projection: the background keeps perspective, and the fighters get an orthographic-style correction so they don't warp at the screen edges.
3. Mirroring when fighters switch sides, so the front always faces the camera and the back is never shown.
Orb also referenced 'downstage' stage power: being nearer the camera reads as commanding.

**Character style: Marked plus Aura (Orb, 2026-09-29).** Combine Marked (a mask with a bold sigil per fighter that bends with emotion and grows with form) and Aura: 'make sure the aura is there to exaggerate or convey appropriately.' Mask tone is per fighter (pale or dark). Orb wants mock-ups in the new style that follow the blocking rules (cheat out to camera).

**Mask tones and transient aura (Orb, 2026-09-29).** Mask tones approved: Protagonist and Empress pale, Anti-hero and Cyborg dark. The aura, like the HUD graphics around the fighters, seems distracting as a constant presence. It should convey emotion briefly and then disappear. Orb is unsure about blades or column from screenshots alone and wants to judge it in motion.

**Head flashes (Orb, 2026-09-29).** The transient aura should work like a brief flash around the head, in the spirit of a superhero's danger-sense flash, or a stealth game's '!' and '?' marks over an enemy's head. These are short, iconic state and emotion pops (comics call them emanata). Staples yes, signatures no: nothing that copies a specific franchise's squiggle design or alert sound.

**Head flashes, answers (Orb, 2026-09-29).** The flash set: pitch changes (Orb wants options before settling on twelve). Info flashes (danger sense, found, searching) are a setting, on by default.

**Flash set (Orb, 2026-09-29).** Add Hazard (info), Primed (info) and Respect (emotion). Cuts were left to the EP ('keep it dynamic and engaging'). EP ruling: cut Brink (the crown's brink ring covers it); keep Resolve as the Rally's emotional beat, firing after the crown's wear pop fades; keep Pride separate from Triumph. That makes 14 flashes, 5 of them info. Winded, Smug and Bored are held until the prototype proves the core set.

**Dynamic split screen (Orb, 2026-09-29).**
- Split only when zooming out further would make the fighters too small to read.
- A dynamic angled divider that tilts toward the other fighter.
- Panes always point toward each other along the shortest way round, and swap with a smooth slide when the shortest way flips, with hysteresis so it never flickers.
- Merge: a dissolve when flying back together; the divider slams shut when charging in to attack.
- Solo against the AI: the player chooses in settings.
- Hiding: the hunter's pane shows only a search view, and the hider's pane is normal.
- A small ring map of the planet shows both fighters.
- Launches: follow the launched fighter in a short cinematic, then split if they land far away.
- Orb questions whether hiding earns its place ('maybe it could be something for a character we introduce down the line'). The EP pitches it; see the next entry.

**Hiding saved for a future fighter (Orb, 2026-09-29).** Hiding is removed from the base game and becomes the signature of a later stealth-specialist character. Cover stays as line-of-sight only (smoke, rubble and terrain can break lock-on). The ambush bonus, the Primed flash and hide-based recovery go with it and are held for that fighter.

**Playtest feedback (Orb, 2026-09-29, night, on the live build).**
- Bug: a fighter often hits the ground hard with no crater, bounces, and the second, lighter impact leaves a large crater. Some deformation on existing craters looks strange.
- Crater size: tune it way down for most impacts. Save the largest craters for special attacks and highly telegraphed, obviously extra-powerful knockbacks.
- Head flashes are too large and visible (the surge's blue gas cloud and the giant purple lines obstruct the view). They should quickly pulse two or three times to signal a thought or reaction, then disappear.
- Split screen is good, but it's hard to follow when a fighter picks up a lot of speed. Use simple stylised motion trails, sparingly and effectively, to ground the viewer.
- A friend's feedback: "Love when they carve a trench, some real [genre] stuff. I did like how it zoomed out and showed them flying around the world before though. Maybe set that threshold a bit higher before it automatically splits?"
- Combat feels slower than the prototype: fighters lock together and do nothing for moments before launching attacks. "Let's really nail down the engaging, dynamic feel of combat the prototype had."
- Destruction must be impressive: cracked and split ground, a fighter crashing into a skyscraper and bursting out the other side with glass and steel shrapnel, buildings collapsing.
**Playtest 2 (Orb, 2026-09-30).**
- The skyscraper debris, the building collapse and the particles are a good start.
- Strange geometry:
  - weird ripples and arcs from impacts;
  - the water level against the shoreline looks strange;
  - buildings (often in villages) appear underwater.
  - Ctrl+F6 (embers) showed no visible change.
- Rampage-style skyscrapers: each has floors and windows. A fighter blasted through a building affects individual floors, and enough damage may or may not bring the whole building down.
- Cities should be more varied, expansive and busy-looking.
- A friend's feedback: on mobile, make every touch target and all text responsive. "Not sure what I'm supposed to do in the game… some kind of tutorial or a card explaining how to play would be good."
- **Direction (a core principle):** the player is in charge of macro strategy, pacing and positioning. The fight director is in charge of combos, tactics, blitzing and voice lines.
- **Voice lines, Banjo-Kazooie style:** each character has a distinct voice of grunts, laughs and chattering noises while the captions appear. Lines are chosen automatically from each fighter's stance, position, current or recent actions and anything special that happened. A procedural system sets the mood of the fight and chooses back-and-forth one-liners, reactions, thoughts and taunts that progress over the battle.
- **One battle is a whole set:** a ranked Tekken set takes 7-8 minutes, and one battle here should feel like a whole set of rounds, without health bars, rounds or other fighting-game fixtures.
- **Freshness:** generative, procedural systems should give fresh interactions between fighters again and again, so that across many fights a player still sees lines that are new to them.
- Orb asked for another questionnaire on these systems.
**Questionnaire 4 (Orb, 2026-09-30): fight systems.**
- **The player directly controls:** stance (intent), movement and positioning, attack weight (light, heavy, signature), charging and power-ups, when to transform, and fighter specials (Hot Blood, Drop the Act, Press…).
- **Left to the director:** *when* to attack, and timing presses (parry, the finisher struggle).
- Skill balance: 2 out of 10, so strategy far outweighs execution. Dialogue density: 6 out of 10.
- Set structure: invisible acts, where the director escalates chapter by chapter at body-part breaks and transformations.
- Inner thoughts: yes, often.
- Lines: mostly fresh, plus a few recurring signature lines per fighter.
- The fight's mood drives crowd behaviour and director aggression (more blitzes when heated).
- Move names on screen: only specials, signatures and finishers.
- Skyscraper floors: people on each floor evacuate or are lost; otherwise mostly visual spectacle.
- Cities: a huge skyline, busy life (crowds, traffic, lights), and bigger cities covering more of the planet. **Two big cities.**
- Onboarding: a How-to-play card and a guided first match.
- Mobile: after the first real fighter.
- Music: not picked yet.
- Orb's words: "I want to see threats, boasts, one-liners, banter. It should give my imagination the impression that there are real stakes invested in the battle at hand, and the fighter's personalities should match up with how the player's fighting style is influencing the fight. A player holding defensive patterns all game might see their character think 'Only a little longer...', and a player who plays aggressively then sees his opponent start picking evasive maneuvers could see his character start boasting about their training regimen."
- "I liked the faster fight pace. Now I want to see cleaner combos, more teleport clashing, stylistic flying combat, heavy ground combat, energy blasts, more varied beam struggles."
- Orb will relay friends' feedback as it trickles in.
## Player-facing wording (2026-09-30)
- The player is the fighter. The controls just differ from a traditional fighting game: there are no combos to learn.
- "Strategist" and "the fight director" are internal terms only. Player-facing text states bluntly what the player controls (fly, dash, stance, light or heavy, charge, signature, specials, transform) and that blows and combos play out automatically from those choices.
- Why: it shapes what testers look for and expect.

## Questionnaire 5 (2026-09-30): balance and gameplay
- Match length: 6 to 8 minutes (keep the current target).
- At the time cap: a story event. The planet or a third party intervenes to force an ending (no draw or judges' decision).
- Matchup: even overall, but each fighter wins in different situations (terrain and power tier swing it).
- Momentum: comebacks are common. The trailing fighter gets help.
- Broken limbs: a dramatic swing during the match, not especially common, but a real consideration when playing. Orb asked for a pitch.
- Holding the defensive stance: punished more the longer it is held.
- Escape stance: its odds depend on terrain and distance.
- Signature beams: 2 to 4 a match, each an event.
- Transformations: a big swing that the opponent must respond to.
- Computer opponent: adapts to how the player is doing.
- The choices that should decide who wins: stance reads, charge and energy management, and transformation timing.
- Surprise vs player choice: 6 of 10 (a fair amount of director surprise).
- Anguish: 3 of 10 (mostly emotional, a light handicap).
- Orb only briefly played the latest build; more feedback later.

## Questionnaire 6 (2026-09-30): moveset breadth
- Ambition: hundreds to thousands of basic martial-arts attacks per fighter, dozens to hundreds of specials (energy blasts, advanced footwork, anything unique), dozens of signatures (flashy energy attacks, hidden weapons, secret abilities, ancient knowledge, world-changing abilities), plus a unique transformation mechanic per fighter.
- Building it: a hybrid. Hand-made showcase moves plus a composed fill from a smaller set of hand-made pieces.
- What makes basic attacks different: the limb or body part, reacting to the situation (air, ground, wall, water), the impact and reaction, and the rhythm and speed.
- Recognisability: 3 of 10. Exchanges should mostly look new, not trademark combos.
- Style: a fighter's style shifts during the match with mood, injury and form.
- Specials: a loadout of a few, each with contextual variants.
- Signatures: the place decides (biome, altitude, stance), some are revealed by story moments mid-fight, and some are tied to the transformation stage.
- World-changing abilities: reshape the land, change the sky, move water, and alter the planet itself. Permanent for the rest of the match, at most once per match.
- Hidden weapons and secret abilities: only certain fighters have them.
- Transformation kinds Orb likes: a ladder of forms, a meter-fed state that drains, and shedding power to go faster. Each fighter's mechanic is different.
- Animation: hand-made key poses with procedural in-betweens.
- Priority: the move-building system first, content after.

## Fighter mechanics picks (2026-09-30)
- Broken limbs: pitch A, "the crippling moment" (docs/design/pitches.md §5).
- Time cap: A, the planet gives way.
- World-changing ability owners: revisit, with more ideas pitched first.
- Transformation mechanics per fighter: close, a good start; iterate on the proposals.
- Hidden weapons: only the Cyborg, for now. His final form is what lets him generate his hidden weapons. His technology isn't fully online until he reaches his final form, and those weapons are what give him his distinct power-up.

## World changes and transformations, second pass picks (2026-09-30)
- World changes Orb liked:
  - Protagonist: Heat Wave, Proving Ground.
  - Anti-hero: Storm Crown, Scorched Plain.
  - Empress: Blockade, Golden Hour.
  - Cyborg: Wired World, Harvest.
- Transformations:
  - Empress: the main version, escalating revisions, each adding a signature.
  - Protagonist: the main version, pushing past his limits (heat).
  - Anti-hero: the alternative, pride ascension, with forms lost when Pride crashes.
  - Cyborg: the alternative, assimilation, feeding on wreckage. It keeps the earlier note that his final form brings his technology online and generates his hidden weapons.
- Orb: "take these and pitch more. this is heading in a good direction, I want more ideas to work with."

## Third-pass picks and animation feel (2026-09-30)
- World changes Orb picked from the third pass:
  - Protagonist: Beacon.
  - Anti-hero: Salted Earth.
  - Empress: Grand Avenue.
  - Cyborg: The Stockpot.
- Transformations: keep iterating.
- Motion feel: a mix. Orb: "snappy looks really good, would work well in attack rushes. fluid looks really good, would work well with power strikes."
- Showcase pose author: not decided; keep them as drafts. Orb questioned the hours: the game is meant to be 90% or more vibe-coded.

## Moveset scope and cosmetics (2026-09-30)
- Moveset: start the first fighter at Lean (3 specials, 4 signatures, 6 showcases) to test, then grow by data.
- Cosmetics: leave room for player cosmetic customisation. With four fighters at launch, Orb wants a vast assortment of cosmetics that players unlock through play.

## Unlocks and roster (2026-09-30)
- Yes to an "unlock all cosmetics" setting (off by default). Player-made palettes come later.
- Open, to be decided by Orb within a couple of days: with only four fighters planned, the unlock structure needs serious thought. Orb may expand the launch roster so there can be an arcade mode and a worthy online versus feature. Keep this in mind; don't start roster work until Orb decides.

## Questionnaire 7 (2026-09-30): open questions
- First real fighter (the Lean moveset proof): the Anti-hero.
- Transformations, next round: a bigger visual change per form, and clearer triggers for when you can transform.
- Title clash with the small OrbCombat project: decide later, before the store page.
- Licence: still thinking. Orb wants a full plain-language rundown of every option later, and asked to be reminded along the way.
- Pose review: contact sheets of 12, plus a motion reel per showcase.
- Release: free prototype builds for friends, for now.
- Friends' playtests: yes to an in-game feedback button that copies a report with the match seed.
- Orb asked where the project stands legally when a transformation or motif comes close to existing works, and how far public-domain folklore can be used. Orb wants originality, as a love letter to the genre, not a copy of any series.

## Questionnaire 8 (2026-09-30 evening): answering friends' playtest feedback
- Auto defence: counters only when the defender's stance calls for it, and never automatic beams.
- Manual defence: a block button, a dodge button, and parrying while keeping momentum, with a risk of being stopped.
- Cancel: yes, into a dash or stance change, for an energy cost.
- Beams: fewer beams, more ordinary energy blasts.
- Mashing: fine for beginners; experts should beat it.
- Transform: a working transform in the next build, even a placeholder.
- Ego mechanic (the Anti-hero): later, after his first moveset.
- In-match upgrade draft (pick one of three): pitch options first.
- Mobile touch controls: next build, top priority.
- Onboarding: on-screen control hints during play; shorter How to play cards, fixed for phones.
- Controller support: after the agency fixes.
- Feedback form: Send opens a prefilled GitHub issue.
- Orb's notes:
  - terrain deformation shows weird unexpected behaviour;
  - motion trails curve behind a fighter even when flying straight;
  - large mountains should be background decoration, and fighters should careen through small hills, mesas, rock formations, large trees and other natural formations;
  - idea: one big ocean with small islands and small villages, with locals on bikes and in cars if the scale allows;
  - a proposed Xbox-layout control scheme: four shoulder buttons and four face buttons.
    - LT: tap for an emergency dodge or lunge; hold to sprint, or take off in high-speed flight.
    - LB: hold for the defensive stance; a well-timed tap is a perfect block.
    - RB: tap to toggle between energy and physical combat.
    - RT: tap for a 360-degree energy burst; hold to channel qi or power, depending on the fighter.
    - LT and RT held together: the most powerful specials and signatures.
    - X light attack, Y heavy attack, B signature, A situational (protect, extract from or make an example of civilians; pick up a boulder, tree or makeshift weapon; grab and throw).
    - Every input combination should feed the director for intelligent, dynamic, fast-paced combat.
    - Orb asked for an analysis of the complications, the effect on the procedural move ceiling, and simplifications.

## Fight lanes and the camera (2026-10-01)
- Depth is handled entirely by the choreographer (ADR 0009). No depth nudge in the control scheme.
- Smashes, launches and throws all get a slight variation of angle, so back-and-forth fights zigzag slightly. Bigger deviations from the lane happen only when a building or another dynamic blocker is targeted.
- Orb on the prototypes: "it looked fantastic". Believable city blocks, cars, bikes and foot traffic follow from this; even the bare prototype looked more organic.
- Camera: "I really want the camera and cinematography to sell the impacts." Fighters seem a little too small, especially in the faster parts of a fight where the zoom extends out. Character cosmetics will look much better up close.

## Questionnaire 9 (2026-10-01): camera
- Fighter size on screen: 7 of 10 (clearly larger than today).
- Far apart or fast: zoom out, but never below a minimum fighter size.
- Selling impacts: a fast push-in to the point of contact, camera shake, and a chase camera behind the launched fighter.
- Cuts to another angle: big set pieces (finishers, transformations, world changes), plus crippling moments, building smashes and beam struggles.
- Camera angle in the lanes: not sure; show both (side-on and three-quarter) in the real game.
- A building between camera and fighter: a circular cut-away around the fighter.
- Player control: a zoom preference in settings (closer or wider).
- Shake and slow-motion intensity: 2 of 10 (subtle by default).
- Close-ups: the match intro, transformations, finishers and the knockout.
- Orb's notes: the camera sometimes doesn't catch up to the fighter; fighters are often launched out of the visible area faster than the camera follows; the camera often follows the launched fighter, so after knocking the opponent away Orb can't tell what their own character is doing.
- Not answered (options to pitch): what happens to control during a cinematic moment.

## Camera picks (2026-10-01)
- Cinematic moments: short ones run live; long set pieces pause the fight for both players. Orb wants ideas for the set pieces and the conditions that trigger a pause.
- Following a launch: the hybrid. The camera stays with the player's fighter when they launch the opponent, cuts briefly to the impact and returns; it chases when the player is the one launched; two players on one screen use the split.

## Questionnaire 10 (2026-10-01): remaining issues
- Set pieces that pause the fight for both players: transformation, a world-changing ability, and the planet giving way at 11:00. The others (finisher, knockout, crippling moment, beam struggle start, revealed signature, smash chains, landmarks) run live.
- Pause budget: about 2 seconds a minute.
- Transformation pace: fewer and later, about 3 a match, the first around 1:30.
- Upgrade draft: C, a pre-match plan that switches on by stage.
- Second city: 12% of the planet.
- Harbour and industrial districts: few civilians, mostly workers who evacuate fast.
- Mountains: a visible far row that beams can scar but fighters can't reach.
- Old laptops and phones: 30 frames a second with reduced effects is fine.
- Feedback reports: prefer a private route (email or a private form), not public issues.
- Babble voices: close, needs tweaks (Orb to say which).
- Priorities after the controls work: the agency fixes (counters on request, dodge-cancel, burst, perfect block), then combat variety (blasts, teleports, beam struggles).
- Speed blitzes: Orb wants "ping pong" blitzes to look great and "teleport spam" as a system, with efficient but non-direct flight paths. Example: a fighter knocks the opponent away at high speed, then blasts off even faster to arrive ahead and knock them back; the path there arcs like a golden-ratio spiral, not a straight line that would clip through the other fighter.
- Animation problems Orb saw: fighters sometimes face backwards; elbows bend the wrong way or arms stick straight out behind the body; in close exchanges one fighter passes through the other and both face opposite directions for a while. Orb wants more precision in selling punches: full contact on every hit.

## Teleports, transformation counts and the rival's balance (2026-10-01)
- Teleporting is on hold until there is a good reason to introduce it. Rule of cool may be reason enough, but Orb hasn't decided whether teleport should belong to one specific character as their signature ability. Blitzes use flight paths only for now.
- Transformations: about three per fighter is reasonable for a typical fighter. The Empress is the outlier: her excessive transformations are what make her unique and appealing.
- Balance picture, subject to a balance pitch and revisions: the Protagonist and the rival (the Anti-hero) are both solid all-rounders. The rival is skewed: his final transformation is the largest swing in power in the roster, but his unique ego mechanic may give him massive debuffs, or grant the opponent massive buffs, in the mid to late game.

## Questionnaire 11: rule of cool (2026-10-01)

Orb's picks.

- **Planet-scale launches:** orbit and re-entry; through the mountain; the ping-pong rally. Not picked: the round-the-world hit, the sea parted to the floor, dragged across the city.
- **Clashes beyond the beam struggle:** a fist clash shockwave; a blur exchange across the sky; a grapple lock in mid-air. Not picked: an aura standoff, catching a punch.
- **Answers to an incoming beam or blast:** swat it into the scenery; walk through it; split it around the body. Not picked: catch and throw it back, fly up the beam.
- **The world reacting as power rises:** clouds part and the sky changes; rubble floats upward; ground cracks spread when standing; windows blow out for blocks. Not picked: the sea pulling back, a storm.
- **Impacts at the biggest moments:** speed lines and panel cut-ins. Not picked: impact frames, slow motion.
- **Battle damage on fighters:** all five (torn clothing, scuffs and bruises, a broken limb hangs or drags, the aura flickers when worn, heavy breathing and stagger).
- **Story beats:** a crater-landing entrance; a staredown before the first blow; a mid-fight taunt that can be punished; the winner stands in the wreckage. Not picked: a last stand at the brink, a double knockout.
- **Bystanders and the world:** crowds watch and flee; throwable vehicles and ships. Not picked: a news helicopter, a useless military, the hero catching debris.
- **Top-tier finisher scale:** 7 of 10 (1 wrecks a block, 10 scars the planet).
- **How often the big spectacle happens:** 4 of 10 (1 rare and earned, 10 constant fireworks).
- **The aura after a transformation:** on only when charging or attacking.
- **Orb's note:** "quips, one liners, banter, taunts should all include a cut-in of the talking character's face on the side of the screen."

## Questionnaire 12: rule of cool, follow-up (2026-10-01)

- **Round-the-world hit:** yes after all, at the top power tiers only.
- **Orbit launch:** the game picks the most dramatic landing spot.
- **Scars:** land scars stay all match; water closes in seconds.
- **Clash input:** timed presses (hit the pulse to surge).
- **Answering a beam (swat, walk through, split):** costs tight timing only.
- **Battle damage on a transformation:** it stays and keeps building.
- **Move names:** the fighter shouts it; no name card.
- **Sound:** silence just before a huge hit; a fighter's theme kicks in on transformation; a delayed boom from far-off impacts.
- **Match end:** a highlight reel of the best moments.
- **The world reacts from:** tier 3.
- **Bystander tone:** 6 of 10 (1 grim, 10 comic relief).
- **Pitches requested:** which hits earn the big impact treatment; what a last stand at the brink gives the fighter; what a completed taunt does ("depends on fighter").

## Rule-of-cool pitch picks and the stacking rule (2026-10-01)

- **Impact treatment:** option B, two levels. Speed lines alone on every launch and landed heavy (a brief streak, no cut); the panel cut-in for the peaks (signatures, finishers, crippling blows, the KO) and for hits the player earned, sharing one panel per 12 s.
- **Last stand at the brink:** option B, one last signature: free and ready at once for 20 s, the first time a fighter reaches the brink, once per fighter per match.
- **Taunts:** "taunts should just feed meters" (option A, meter only), with the shared rules (punishable, the face cut-in).
- **Legal's stacking rule:** accepted. No single moment shows more than two of the seven power-up marks; the charging aura is a thin outline in our own shapes.

## Orb's direction, 2026-10-01 (before a four to five hour absence)

- **Top priority:** controller support and local two-player versus, testable on the live build when Orb returns.
- **Animation is no longer "lean".** Orb: "When we selected the 'lean' minimal options for character animations and movesets I was beset by some doubts that have since been rectified. I want you to work towards an optimistic overhaul of the current animation system: try to maximize the dynamic animations, overhaul our ragdolls, fine tune the physics model." Extra polish work goes to animation.
- **Faces:** "loop on the art style to create stylized closeups of the fighters' faces so the on-screen closeups can be memorable and recognizable."
- **Voice:** "get the voice line packet ready for me to edit so we can start working on the tone and style standards for our characters going forward."
- Orb asked for an ETA on the depth axis (fight lanes) work.
- The EP is to keep working through the absence with the permissions it has.

## Orb's direction on return, 2026-10-01 (evening)

- **Art direction.** "the mask aesthetic, broken masks should be part of an upcoming character, not the game's overall art style." The masks are parked as a seed for a future fighter. Orb likes the fighters' faces, and the silhouettes "kind of grew on me"; both are to be refined. The Cyborg is "the least compelling of the launch fighters", so the refinement starts with him. Orb wants to dig into this on return.
- **Animation and rigging.** "in many of the stills and gifs of the fighters, I see lots of limbs bent unnaturally, knees bending the wrong way during kicks, elbows turning inward." If it would carry over to the launch fighters "it needs to be quashed immediately". Animation's brief: joint limits enforced at the root, a lint over every pose and live matches, and a rule for new rigs (docs/animation/joint-limits.md).
- **Pause.** Orb is reviewing the backlog; work is brought to a resting place. The list of everything waiting for Orb is docs/ep/orb-review-list.md. Orb wants to revisit the sound profiles.

## Orb's first two-player playtest, 2026-10-02

Two local matches with a second player. "good first impressions". Direction, in Orb's words where quoted:

1. **Control against the director.** "lets continue to tune the amount of control the director grants the player. the worst is how pressing a single attack key at any distance essentially locks both fighters from performing actions as the attacker flies in and performs the attack." Orb wants a list of solutions. Orb's own idea: attack buttons act as taunts from range; one press plays a taunt, holding the attack through the taunt ends it by taking off at max speed to attack.
2. **Brawls against launches.** Only one knockback slide in two fights; "every brawl seems to end in a launch". Combo trading should be more represented and flashy; air juggling and pinballing slightly less common but with higher payoff and spectacle.
3. **Air recovery.** "Players need a way to air recover from knockbacks."
4. **Craters and terrain destruction from slides and tumbling** are to be "a central feature of the game". Craters and bounce-and-crater impacts "look great". To consult on: an impact hard enough for an extremely large crater should leave the fighter in it, with no bounce out.
5. **Mountain tumbles** were "kind of funny but also just a little off": too much momentum gained from a seemingly low-impact glancing bounce.
6. **RB.** Perhaps hold RB to fire energy attacks, in place of the toggle.
7. **Beams.** The cooldown "felt too restrictive, feels like a relic from the prototype". Bring energy combat into fights, more ways to beam struggle, more forgiving timing to dodge and block beams. Looking forward to walking through beams and beams splitting.
8. **The combo system: a "fight alchemist".** Orb likes the choreographer but does not want agency removed. Tilting the stick during a fight or a juggle controls the relative screen direction the opponent is launched. Button presses are ingredients in the ongoing string, not a queue: the alchemist reads the last few presses of both fighters (three, as an example), compares each player's running mix of attack types with their latest presses, and builds a choreographed sequence the player would expect. It must be "clear and standardized": light-heavy play gives a rapid blur of strikes; kiting is dodges, a few heavy blows to knock away, and energy blasts from range. Holding, mashing and tapping in time with the blows on screen should each give different results.
9. **LT and escape.** Escape tied to a direction and holding the trigger "was a little strange". Players should fly at high speed at will, with a mechanic to stop the other escaping and a way for the escaper to exit any situation at some risk.
10. **Split-screen camera.** It jolted left and right in some cases, such as when a player was knocked away. A pass on the camera.

Orb asked for all directors to be briefed, iteration to start, and a questionnaire to nail down direction (questionnaire 14).

### Questionnaire 14: player agency (Orb, 2026-10-02)

- **Ranged press:** Other. "pitch some hybrid systems, give control to players but avoid a nightmare scenario of two fighters standing in opposite corners whiffing jabs in the air with zero purpose. standing far apart and spamming taunts is the minimum acceptable, especially if there are reactive voice-lines, bonus points if those lines keep feeling fresh even if they spent all day." (EP pitches hybrids.)
- **Ranged taunt effects:** a voice line with a face cut-in (the only one picked; not "punishable", not "held launch hits harder", not "cancel with a dodge"; "feeds meters" was not picked here, though the earlier ruling was "taunts should just feed meters").
- **Alchemist input reading:** Other. "pitch me some hybrids between 'three clear styles' and 'timing is the skill'". (EP pitches.)
- **Alchemist window:** 5 presses.
- **Recipe display:** an option in settings.
- **Launch direction:** the stick picks, the director snaps to the most dramatic nearby target.
- **Launch share:** 30% of brawls end in a launch.
- **What earns a launch:** a charged or held heavy; the ender of a full string; heavy plus a stick direction; winning a clash. (Not a guard break or riposte; not spending meter.)
- **Air recovery:** hold to brake, costs ki; harder hits take longer.
- **Energy input:** hold RB; the attack buttons become blasts and beams.
- **Beam limit:** the pills were left blank; the slider says 15 s between signatures (was 120).
- **Beam plays wanted:** all eight: both fire at once; fire late into an incoming beam; block then push back; walk through on guard; split the beam; swat it away; blast volleys that trade; feeding a struggle with a second charge.
- **Beam defence forgiveness:** 3 of 5.
- **Flight:** hold LT to boost in any direction, draining ki.
- **Escape:** the pursuer boosts and strikes to catch; blasts from behind knock the escaper down; intercept by appearing ahead, at a ki cost; empty ki leaves the escaper exhausted. (Not picked: extra damage from behind; paying to break out of a brawl.)
- **Hard impacts:** yes, the fighter is buried in the huge crater, and the attacker gets a free follow-up.
- **Slide and tumble destruction:** 4 of 5.
- **Notes:** "the fights are cool, the craters blowing up from transformations and beam explosions look really cool, fighters almost get a little too fast when max transformation is reached".

### Orb's picks after the pitches (2026-10-02)

1. **Ranged press:** the EP's mix. Three range bands (close strikes, mid is a short lunge decided at the wind-up, far is tap to taunt and hold to charge); the taunt is a challenge the opponent can answer by pressing attack, so both rush and meet in a clash or blur; the button picks the charge (a held light is fast and can be feinted, a held heavy is slower, shrugs off blasts and can earn a launch). A strike never exists at range.
2. **Reading presses:** timing upgrades each style (a steady mash becomes a perfect blur, a hold released on the flash breaks guard, taps in time land clean), and timing earns the ending. Orb's reference is a well-known scene of two fighters trading stomach punches in turn: two players both hitting the timing on their power attacks should produce that. "lets run balance tests on your recommendation, consistent timing should give the fighter a substantial edge".
3. **Taunts feed meters,** probably ("not 100% sure but i think it would be a good thing"); voice lines and face cut-ins "at the very least". Working ruling: they feed, with a guard against farming; revisit in play.
4. **Beams:** no final calls yet. "I just didn't like the cooldown, I want the energy combat system to be implemented before I make any more decisions on energy beams, I want to personally experience how the expansion of ranged blasts change the gameplay". Build energy and ranged combat first; the signature limit stays provisional.
5. **Escape control:** "I need to feel how this works in game... lets get something that works now and then work on it when we have more combat systems in place". Build a provisional version.
6. **Top-tier speed:** no yes or no. Instead: "think of how many more ways there are to visually communicate more intense powers and higher strength levels. rocks levitating around a powered-up individual look cool".

### Orb on the energy blasts, 2026-10-02 (after watching AI matches)

"i like the new energy blasts". Wanted: blasts "erupt into flame and smoke, explosive particles"; "deflecting energy attacks shouldn't reflect back at the opponent but deflect them off in a random direction with a payoff of seeing it hit the ground elsewhere and explode." Orb asked for a mock-up animation before anything goes into the build; the EP showed one in chat. Not briefed for building until Orb confirms the mock-up.

Orb, after the mock-up (2026-10-02): "charged shots should have the capability of damaging, possibly leveling a building. with enough of a barrage smaller shots should eventually do damage. rapidly spamming small energy blasts should lose some accuracy, but follow rule of cool logic and make sure the energy blasts are sprayed in a cone at the enemy fighter. lets get a variety of energy attacks that are possible, like leaving a hovering energy blast mine that the enemy could walk into, with enough ki a fighter could leave a minefield either on the ground or in the air". The EP takes the flame-and-smoke eruptions and the random-direction deflect as wanted (Orb built on the mock-up without objecting); explosion size per shot kind is still Orb's to tune in play. This overrides Game Design's §14.6 line that bolts never damage structures.

## The next big update, and a pause (Orb, 2026-10-02)

"I want the next big update to include the expanded energy blasts, two fighters (protagonist and rival, I will have names for these two and the vocabulary text work you need me to do soon) and the framework for the combat alchemy layer tied into the fight choreographer. I want some peace and quiet for gaming, so please bring all ongoing work to a pause and we'll get ready for the big update soon."

Scope of the next update: (1) expanded energy blasts (agency-pass sections 15 and 16: wild deflects, the spray cone, shots against buildings, mines, more kinds); (2) two fighters, the Protagonist and the rival (the Anti-hero), replacing the KAI and VORR placeholders; Orb supplies their names and edits the voice packet; (3) the framework of the combat alchemy layer in the director (the press window, styles, timing grades, flow). All sessions pause until Orb says go.

Orb, 2026-10-02: "the rival character should have glasses, i want him to be our resident 'scary shiny glasses' trope character". The rival (the Anti-hero) wears glasses whose lenses go opaque with glare at key moments.

## Orb, 2026-10-04: intros, backstory, music

Verbatim:

> I thought the intros looked pretty good, if we can script a system that creates dynamic intros and mixes and matches different scenarios between characters I'd like to see it. I'm thinking about a document defining the backstory so we can flesh out the power system a little more thoroughly. I listened to the music, I feel like they were al a little bit too "spooky" or almost like a "halloween" atmosphere; sketch-a-town-band had the most interesting hook. I have a premium Suno Account, so if you include a Suno 6.0-ready prompt along with the sound samples to direct the Suno model we can really zero in on a coherent sound. I want to lean a little more into a tongue-in-cheek riff-heavy speed metal version of what you gave me already. Direct "Audio & Music" to work with the expectation that Suno will create the final product, and I can feed the final music files back to you.

What follows from it:

- Intros: Orb likes them and wants a system that composes them from mix-and-match scenarios per pair of fighters (Narrative: docs/narrative/dynamic-intros.md; Encounter owns the intro phase).
- Backstory: a document defining the backstory, so the power system can be fleshed out (Narrative drafts a skeleton of options; Orb fills it).
- Music: the previews read too spooky; sketch-a-town-band has the best hook; the direction is tongue-in-cheek, riff-heavy speed metal. Suno (Orb's premium account) makes the final music from our prompts and reference samples, and Orb feeds the files back (Audio: docs/audio/suno-direction.md).

## Orb, 2026-10-04: questionnaire 15 (pending decisions)

Answers as given:

- Front-row buildings: Other: "hybrid of 2 + 3, pavement should crack and shatter differently from dirt, can windows shatter + multiple levels of dynamic destruction per building" (2 = cut top-tier reach into buildings, 3 = soften landing blasts).
- Extra blast kinds: Splitting shot (rival) only. Rain hits its thrower: No (rain is not in this update).
- Glasses frame: C, the bare wedge. Glare hides his eyes: yes, fully hidden.
- Protagonist look: approve. Rival look: approve.
- Deflected shot's landing ring: make the landing a surprise.
- Split-screen rush jolt: this update.
- Beat-pace loophole in the perfect blur: build the fix.
- Finisher struggle strictness: 2 of 3 (between lenient and the strict rule that was live).
- Backstory: "Interview me with a questionnaire".
- Not answered: how hard medium should be against good timing; the fighters' names; whether to run the split on neutral ids.

Notes, verbatim:

> timing should land clean, instant-looking blows with an after-image, mashing should fire attacks, impact landing on-trigger so they look fast and leave a fluid afterimage blur, holding should be the most fluid looking and account for power hits, use warping or smear effects to illustrate the speed and power of these attacks, right now my feeling on combat is that there is a lot of small downtime breaks, I just played (about ten minutes ago) against Vorr and it seems like they will trade around three to five blows, the AI will slip away in some kind of looping pattern, then I'll catch up to him, and repeat. sometimes it will end up in a launch which looks cool, the speed and acceleration of launches can be tuned to accommodate the viewer,  the 'combat lunges' should be a bit more controllable and easier to spot when they're being used against you, right now an opponent flying from very far away at max speed is very hard to judge, the split screen needs tuning so it is easier to track combat.
>
> I would like a prototype animation of the three melee types, mashing, timed and holding, so I know we're on the same page.

## Orb, 2026-10-04: the melee feel (after the second prototype)

The approved reference is docs/ep/prototypes/melee-trade-v2.html (open it in a browser). Orb asked for it to let both fighters be set to speed, tech, heavy, combo or block and trade blows at once; a heavy knocks back only as a combo ender; a combo is 3, 4 or 5 hits where only the last is a heavy; a blocker is never knocked back; the tech after-image differs from the speed blur.

Verbatim:

> that second prototype looks a lot like what I want the combat to feel like. close up brawls should make fighters slightly 'magnetic' so they can trade continuous strings of blows without interruption. both players should feel like their attacks actually match a button press. mashers should see their fighter landing faster flurries the quicker they tap the attack, a player trying to tech timing combos should see his character landing flashy skill attacks that lapse into high speed flurries when they miss their timing, and the heavy attack should be reliable against a heavy guard opponent, or to set up chains of skillful juggle attacks.

What follows from it:

- Close brawls are slightly magnetic: fighters stay in range and trade continuous strings without the fight breaking apart.
- Every attack on screen matches a button press, for both players.
- Mashing: the faster the taps, the faster the flurry.
- Timing: on-beat presses give flashy skill attacks; a missed beat lapses into a high-speed flurry, not a dead press.
- Heavy: reliable against a heavily guarding opponent, and the set-up for chains of skilful juggle attacks.
- This moves melee from "the director composes the exchange" toward "each press is a blow"; the director still owns the choreography of what each blow is.

## Orb, 2026-10-04: stances stay, and every stance has a moveset

Verbatim:

> stances will still be involved, the default represents the characters' martial arts stance, LB represents defensive stance, RB is Energy arts stance, RT is the charging stance, LT is maneuver stance. All face buttons should have an appropriately broad moveset for each stance. Lets work out a way to generatively work all these stances into vast and varied movesets for each character.

What follows from it:

- Five stances, chosen by what is held: none = the fighter's martial arts stance; LB = defensive; RB = energy arts; RT = charging; LT = manoeuvre.
- Every face button does something in every stance, with a broad moveset per stance.
- The movesets are to be generated: a system that composes large, varied movesets for each character from parts, not hand-written lists.
- Pillar 2 ("stances, not combos") keeps its stances; what a press does inside a stance is now a blow or an action of that stance.

## Orb, 2026-10-04: stance questionnaire delegated to the EP

Verbatim: "I want you to answer this questionnaire in my stead. I had a conversation with controls & game feel and I feel you're suited to take over this task."

What Orb confirmed to Controls directly (as Controls records it in docs/controls/stance-questionnaire.md): RT dominates; hybrids LT+RB (evasive energy), LB+RB (defensive ki) and LT+LB (terrain while flying); the AI can do anything the player can; simplified and accessibility controls let a player hand stance choices to the choreographer at any granularity; B gives every fighter its own array of signatures; struggles affect all fighters.

The EP's answers, which Orb can overrule: docs/ep/stance-answers-2026-10-04.md.

## Orb, 2026-10-05: questionnaire 17 (melee and stances)

Answers as given:

- A lone heavy: "A fully held heavy may also launch" (so the string's ender and a fully held heavy both launch; a tapped lone heavy does not).
- A mashed string closes with a stagger in place, so the brawl stays together.
- After a knock-back the re-close is always the player's own move (no automatic pull).
- The beat is shown on the body, plus an optional beat ring in settings.
- The five signature kinds: "I'd like to hear more on this, it looks good I just want some quick charts and alternatives before this is finalized".
- The 75 ki ultimate: only in the last two acts.
- New small actions: all three (check with a parry when timed after a block, push, step strike).
- The stick leans which limb he strikes with: yes.
- Identity split (Protagonist: palms, blade hands, arcs; rival: fists, plates, straight lines): yes.
- The rival's hands: a mix, fists on heavies and blade hands on lights.
- The rival's glasses: always on.
- A juggle: up to 5 skill strikes.
- Go-aheads ticked: build the dynamic intros first cut (three scenarios); a far charge becomes a slower visible pursuit, not a taunt-only ceiling. Not ticked: the audio encoder install; the fighter split on neutral ids.

Notes, verbatim:

> just played the latest update. we've got some work to do but the combat is getting to a good place. we're aiming for snappy combos, attack trades that look pre-planned, variety of attacks. I like the thought that holding LT creates mid-range lunging attacks, these can be utilized at great cost to stamina, can I see a version of the latest combo prototype specifically showcasing the face buttons combined with LT? I want to see the lunging behavior. in the game I would expect every stance to be able to connect blows against a player using this, but the character should zip back and forth in a stylistic blur, matching our visual cues we established for speed, tech and heavy.

## Orb, 2026-10-05: modifiers on every button, and the LT zip

Verbatim:

> in all states X, Y, B all should have speed, tech, heavy modifiers. A should have a press and a hold, no grab spamming. LT plus an attack should cause the fighter to zip to the opponent to land the strike and zip back by default. LT plus an attack plus the movement stick pushed towards the opponent should zip to the opponent, land the strike, then zip the fighter on the other side of the opponent. please update a new prototype animation so we can see different permutations of this playing out. well timed heavy and tech strikes should be able to counter this,

What follows from it:

- In every stance X, Y and B each read three ways: speed (mashed), tech (timed), heavy (held).
- A has a press and a hold. Grabs cannot be spammed.
- LT + an attack: zip to the opponent, land the strike, zip back. That is the default.
- LT + an attack + the stick toward the opponent: zip in, land the strike, then zip through to the opponent's other side.
- A well-timed heavy or tech strike from the defender counters a zip.

## Orb, 2026-10-05: build the zip; any spot around the enemy

The approved reference is docs/ep/prototypes/lt-zip-v4.html.

Verbatim:

> the zip prototype looks right, start building it. consider how players should be able to use it to end up in any spot in a 360 degree around the enemy, and if they use it and are holding a direction away from the opponent, they end further from where they started and this is a useful way to escape from a brawl you aren't ready to commit to.

What follows from it:

- The zip is approved for building.
- The stick chooses where he ends up: any spot on a full circle around the enemy (above, below, behind, in front), not only "back" or "the far side".
- Holding away from the opponent ends him further out than where he started: the zip is also a way to leave a brawl he is not ready to commit to.

## Orb, 2026-10-05: leave headroom on building destruction

Verbatim:

> we're still adding energy blasts and more special moves, so if we're underperforming on building destruction now, that's a good thing, because potentially we'll be seeing more vast swathes of destructive abilities when more energy specials and signatures are created

What follows from it: building loss should sit below its ceiling for now, leaving room for the signatures, specials and blast kinds still to come. The EP's ruling: apply both the hybrid (less top-tier reach, slightly softer landings) and the stage cap (a blast leaves a wreck), which World measured at about 38 to 40% of the front row lost, inside the 25 to 50 band.

## Orb, 2026-10-05: a roster of twelve; "an imaginary anime's fourth season"

Verbatim:

> I plan to finish the lists you wanted me working on by this time tomorrow. I'm going to sleep so I want you working full steam on this project. I want some generic templates to consider for fighter niches we haven't touched yet so I can start working on the full roster of characters I want to see. I want to lay the groundwork for a full roster of twelve, so classify the roles and subroles we've already established with our first four in our roster, then give me notes and proposals for fighters who can fill out the rest. ((Spitballing: rough ideas ahead but hopefully, with the list of taunts, quotes etc that I hand back tomorrow evening, we'll be able to fully flesh out an implied history , backstories, previous adventures etc. to create the feeling of a game based on an imaginary anime's fourth season. I am currently working on a distinct original universe that will justify the abilities these characters have.))

What follows from it:

- The roster target is twelve fighters (it was four). The first four are the Protagonist, the rival (the Anti-hero), the Empress and the Cyborg.
- Wanted now: the roles and subroles the first four establish, generic templates for niches not yet touched, and notes and proposals for the other eight.
- The framing for the fiction: the game should feel like it is based on an imaginary anime's fourth season, with an implied history, backstories and earlier adventures. Orb is writing an original universe that justifies the fighters' abilities, and hands back the taunt and quote lists on the evening of 2026-10-06.
- Orb is asleep for the night and wants work to continue at full pace.

## Orb, 2026-10-05: questionnaire 18 (overnight)

Answers as given:

- Roster niches to explore: stealth or ambush, heavy or giant, speedster, terrain shaper.
- Alignment split: hero-heavy, an ensemble of allies.
- Body variety: 2 of 5 (close to all humanoid; small departures such as tails or size).
- Signatures: the defensive (LB) and manoeuvre (LT) signatures differ per fighter.
- The tech zip as a fast drawn dash: accepted.
- Zip strike price: 20 ki.
- Zip away: a reliable escape at a higher ki price.
- Medium AI against a well-timed player: toughen medium against combos.
- Intros: allow the longer ones; who lands first: random each match.
- HUD: the rival's stance badge always shown; a beat ring for the rival's blows too. (Not chosen: an in-fight move legend; a marker when the player's own fighter leaves the pane.)
- Move names: Narrative drafts, Orb edits in the voice lab.
- Overnight machine use approved: QA's long measurement batches; the fighter rename on neutral ids (Protagonist, Rival). Not approved: the audio encoder install.
- Next priority when the queue is done: the other four stances' movesets.

Notes, verbatim:

> "Legal wants the tech zip drawn as a very fast dash (4 to 5 ticks) and not a true blink. Accept?"
>
> how can we keep the mechanics on the tech zip consistent with our other tech hits across the board? go with your best judgment
>
> "Dynamic intros: the Latecomer and the Long Look run 7 to 7.6 seconds (today's is 5, all skippable). And who lands first?"
>
> P1 then P2 is pretty standard, as long as the dynamic intros can create many distinct implied plotlines between each character I'd like to see these handled as generatively as possible.

The EP's judgment on the tech question, as delegated: "tech" means the same three things everywhere. The strike pose lands on the contact tick with no in-between; the after-image is sharp wire echoes that trail the body and pop off back to front; the contact mark is the hard diamond. Travel is never part of it: a tech zip crosses as the fastest drawn dash the rules allow and then lands its strike exactly like any other tech hit.

## 2026-10-05, morning: ideas for special attacks

Orb: "give me the morning summary. ove the next few days I want to start spitballing ideas for special attacks, energy blasts etc. so get a template ready so I can put my ideas in"

The EP's sheet for it: docs/ep/ideas/special-moves.md. It is Orb's file; nobody else edits it.

## 2026-10-05: going to market

Orb asked for "a consult on advertising, where I can get this game listed, and realistic sales expectations. this is a hobby vibe-coded game with a shoestring budget, so I don't expect a miracle, give it to me straight about what I'm up against." Orb wants to "temper my expectations and coordinate a plan to get engagement that translates into real sales", asks "What console stores can I realistically get listed on?", and notes: "by word of mouth a lot of my friends who have Playstations show excitement for this project."

After the EP's consult, Orb: "go, brief Marketing, Legal and Platform for the written plan. upfront AI disclosure is the only ethical path to take for this project."

Standing rule from this: the project discloses its AI-made content upfront, everywhere it is presented or sold. Nothing is ever described as human-made that is not.

## Orb, 2026-10-05 (late evening): questionnaire 19, rule of cool and the control scheme, with play notes

Orb played the live build at about 10:30pm on 2026-10-05 (the brawl with press styles on, before or around the retune).

**Answers.**
- Control ideas wanted: 3 zip chains; 4 chase your own launch; 5 a visible spark-lock; 6 just release on the heavy; 7 the taunt as a gamble; 9 haptics; 10 the fire-on-the-move hybrid. Not picked: 1 stance switch flourishes; 2 the right stick calling the launch; 8 a playable intro attitude.
- Q3, the player's say over a launch: the player nudges, the director stages it.
- Q4, zip chains: until ki runs out.
- Q5, an even mash: both thrown back, nobody wins.
- Q6, how flashy an ordinary exchange of lights looks: 4 of 10.
- Q7, a perfect timed string's payoff: keep it subtle.
- Q8, damaged buildings: throw the rival through a shell to finish it; otherwise nothing new, just scenery.
- Q9, intros: keep them watch-only.
- Q10, stance switch flourishes: none.
- Q11, how hard a failed flashy option hurts: 3 of 10.
- Q12, rumble: every landed blow; closes, launches and landings; buildings breaking; beam struggles. (Not picked: the player's beat.)
- Q13, Simple controls: yes, all of the spectacle, chosen for them.

**Q14, in Orb's words:** "I just played around with it at roughly 10:30pm 10/5/2026. It feels closer to where I want it to be. The flurry should be across all attacks, not just light. light mashing, heavy mashing should both have the rapid attack pattern. holding a button should charge up an attack. so a charged heavy should have benefits that a charged light attack doesn't, while charging a light attack is less powerful and doesn't knockback but faster to charge. mashing X and Y alternating should give you a rapid attack mixup made up of heavy and light attacks. movement during combos should not feel "locked", i was trying to move while exchanging blows and the "magnetic" attraction was too strong, each player should be able to nudge the center of attraction between the fighters during an exchange. players should always feel like they are able to control their character, with few exceptions like during knockbacks. just hitting B and getting locked into what feels like a beam-attack cutscene doesn't feel right, B needs a recast and its own unique moveset. [[I'm trying to think how A functions, just spitballing here: tapping A should be a shove, mashing A should function like your fighter getting into a clinch then some kind of "trip-attack" (combat mostly takes place midair so think how a flying combatant would take control) that turns into a throw, and holding A should charge up a tackle that hits at high speed and can crater both fighters, causing no damage to the tackler.]] I didn't get to test getting knocked back and regaining control. I didn't get to test building destruction."

**Feedback from another player, an earlier session (as Orb relays it):** "Holding RT and then hitting any face button didn't give the special attack i was expecting. context button didn't seem to do anything. the finisher attack zoomed in and looked really cool."

**More combat feedback (Orb):** "Y just feels really underpowered right now. an opponent flurrying on me should get punished if they don't block correctly when I charge a full Y attack. I suddenly realized a staple of modern fighting games are the two-button combined power attacks: A+B (grab-related) / X+A / Y+B / X+Y . I don't want to add combinations that cross the pad, like Y+X / X+B unless you make a really good pitch as to how that will benefit the control scheme. Please consider folding these into our combat mechanics."

EP's note: on a standard pad the adjacent pairs are A+B, X+A, Y+B and X+Y, and the two that cross the pad are X+B and Y+A. Orb's "Y+X" in the cross-pad list is read as Y+A, to be confirmed with Orb.

## Orb, 2026-10-06 (early): the brawl second pass's questions

Answers to Game Design's questions on docs/design/brawl-second-pass.md:
- Q2, what ends a string: a held Y ends it; X+Y is the lift.
- Q5, the even mash's double throw-back: both take a hit.
- Q6: yes, Y+A and X+B are the pairs to avoid.
- Q1, Q3 and Q4 were answered in Orb's notes, verbatim:

"1: if both players move their sticks in the opposite direction they should be able to walk out.

3: I like the body blows suggestion, but it should read more as a new axis to the 'light / heavy' paradigm, I'm thinking 'vicious' or something similar, depending on the character it might be but not limited to headbutts, bites, clawing, gouging. please pitch some more alternatives.

4: I'm going to defer to you, i don't know how much reduction the armor gives but you should determine the best fit.

5: double knockbacks should be slightly uncommon, but exciting developments when they happen. Potential for dynamic closeup PiP  of, for instance, both characters punching each in the face, sending each flying in opposite directions."

EP's ruling on Q4, which Orb deferred: a charging Y is armoured from its first tick against light and flurry-light blows (they do not interrupt it, and he takes half their damage); quick heavies and heavy-flurry blows interrupt it until it is half charged, and from half charge it is armoured against those too. A shove, a grab, a charged blow and a perfect block always end it. Numbers are Game Design's; the first playtest of the slice decides whether it holds.

## Three strengths on three buttons (Orb, 2026-10-05, late)

Asked whether reading on release would help tell a flurry from a timed or charged attack, then, on the tap-and-hold rule (a quick move, then the charged one from the same press):

> I don't like the idea of one button press equalling two attacks, lets fix heavy and vicious this way. Proposal X=light, Y=med, B=heavy. turn whatever heavy strikes into medium, and invent new super-heavy looking attacks. give me consult on this and valid alternatives

Standing from this: one press is one attack. The EP's consult and Orb's pick follow in the review list.

Later the same night, after the consult:

> X Light Hold should give a high speed burst of low damage attacks that quickly slows down on a curve; I'm excited to see Y and B flurries, I want to see how this looks visually

The EP reads this as Orb going ahead with three strengths (X light, Y medium, B heavy). It also answers the open hold-to-flurry question for X: a held X is a burst that slows on a curve, not a charge. Where vicious lives is still Orb's to pick.

## Vicious, the flurries, and what Orb will test next (2026-10-06)

> vicious inside the clinch is good, go with that. the flurries looked good to me, nothing stood out in particular, you have the call. Things I'll be looking for next time I test-run: "can I move my character around during active combat?" "can I move my character when the opponent is charging up an attack?" "can I reliably launch my opponent?" "do energy attacks look cool as part of close-range combos?"
>
> I'm making a push to finish the work I took on.  I'm certain I'll hand that off today.

Standing from this: vicious lives inside the clinch (confirmed). The EP's call on B, given to it by Orb: the new super-heavy tier is built (16 key sets first), with today's heavies as stand-ins until it is posed. Orb's four questions are the acceptance test for the next playable build. "The work I took on" is the voice lab's taunt and quote lists.

## A friend's feedback from the mobile build, and Orb's stance on it (2026-10-06)

Orb passed on a friend's notes from playing on a phone (Safari, landscape), with a screenshot. The friend's notes, as Orb pasted them:

> Oh wow the models are so detailed now, looks really good
> It would be nice if the player and cpu were more visually distinct and the colors tied back to the HUD elements
> Still hard to tell which one I'm controlling when the game starts
> Also I wonder if the HUDs should swap position when the player is on the right VS the left, so it's always showing it above the player
> I think it could help the user know where to focus if it's moving fast
> Also do you want to force people to use landscape or portrait, or support both? Right now it supports both but if you want a more consistent/predictable experience you could limit it to landscape
> I saw you have the controls only on the right side, I think it's fine if it's on right and left even if the player is only one one side. If you're holding the phone landscape you have thumbs on each side.
> I wonder if there's a way to make the controls more immediate, like with fighting games you press the kick button and see the player kick immediately. They feel a little disconnected right now, like I'm queuing-up moves instead of seeing them execute immediately. OR if you are queuing-up moves, they could rise up as a list of incoming moves and then cross off and erase when they are executed
> At least something immediate when you press the button, whether it's seeing the player react immediately or seeing the move being added to the queue
> Hmm landscape is kind bad because of Safari's chrome
> Haven't figured out how to lay a mine
> When I move around with the joystick (which I just figured out you can do), sometimes the player flies back to the enemy
> I got to some buildings and city area, that was cool

Orb's own words on it:

> he mentions changing the game's color pallette, I'm not so sure about this, I would like some accessibility options for colorblind, but changing the feel of the game with stylistic color changes doesn't sound like my vision for the game. I do want the sky to be dynamic and color changing though.
>
> again all the feedback is welcome, I acknowledged his concerns about the movement, I understand we're working on a combat overhaul that should at least mostly address these control issues. I havent tried mobile support at all myself so I'm taking his word for the issues facing chrome.

Standing from this: no stylistic palette change; colour-blind accessibility options are wanted; the sky should be dynamic and change colour. Telling the player's fighter apart and tying it to the HUD is to be solved inside the existing look.

Orb's answers to the EP's three questions on it (2026-10-06):
- What should drive the sky's colour changes: "Where you are on the planet", "The fight's mood and damage", "Time passing" (not the match's acts).
- Should the fighter panels swap sides: "It was pretty intuitive for me, but again I wasn't looking at it on mobile. lets find a compromise, perhaps in UI options in the settings menu"
- On phones: "Landscape only".

On Art's dynamic-sky direction (keys by place, a slow drift, mood and damage; 2026-10-06): "the art direction on the sky looks great, lets keep iterating these systems." Approved to build.

## The public page is taken down (2026-10-06)

Asked what was left before the next big update, and with the EP's advice to take the playable build down until the flash check passes, Orb said:

> go ahead and remove the page for now, make sure to leave a message with short notes about what to expect when it comes back up.

Standing from this: the public site serves no playable build until Orb says it returns. It comes back when the flash check passes on the required set and the gate's faults are fixed, on Orb's word.

## The holding page's wording (Orb, 2026-10-06)

> can you improve the wording on the static WIP page and make it sound a little less dumb? "Planned: a brawl you can move with the stick, and more control of your fighter in general." internally I know what that means, but to someone who just got the link and hasnt played yet it might sound like the developer is an idiot who forgot to let you move your character around during the brawl. like, obviously you and I know we're talking about the shift from an auto-battler style that didn't really work to a more fluid, dynamic combat style more in line with a traditional fighting game. i want some cool-sounding ad copy that really showboats what we're trying to do here: we're doing things procedurally right? dynamic combos and real-time anime brawling? try to make the upcoming features sound like we're really working on my dream game here, and not some slapped together thing where I suddenly went "oh yeah I forgot you need to move around with the stick"
>
> pick a handful of cool screenshots and at least one combat gif from our files and put some cool sounding captions under them please!

Standing from this: the holding page sells the vision (procedural, dynamic combos, real-time anime brawling), with screenshots and at least one combat clip; it must not read as a list of basic fixes. Orb's description of the change, for all copy: "the shift from an auto-battler style that didn't really work to a more fluid, dynamic combat style more in line with a traditional fighting game."

## No in-progress character art in public; a hold to save usage (Orb, 2026-10-06)

On the draft holding page, which used a strip of Art's sky concept sheet showing the fighters' new designs:

> pick a different set of landscape screenshots or create eye-catching brand new ones in a test environment, I don't want any in-progress character art to be out. the fighters in past builds are fine but not in-progress stuff please.
>
> and finally, I just looked at my usage and I'm at 88% for the week! I'd like to save on tokens because I have one other little project I'm working on, so please let everything finish up and put a hold on.

Standing from this: no in-progress character art on any public page; fighters as they appeared in past builds are fine. Pictures for the holding page are to be landscape screenshots, re-chosen or newly staged, when work resumes. All directors are on hold after their current step until Orb says to resume.

## The title stays (Orb, 2026-10-08)

> The "orbcombat" user has no public email, no way to contact them, and they live on the other side of the planet from me. short of rudely committing a push to their repository, which is considered spam and not a professional way to reach them at all, I don't know how to politely contact them about the name conflict. Let's continue with Orb Combat EX as planned.

Standing from this: the title is Orb Combat EX. Legal's note stands that the clash should be looked at again before any store page.

## Resume, and research into a co-op mode (Orb, 2026-10-11)

> lets get this project back on track

> I want research into a co-op brawler mode. Look into how the systems could be adapted to make the versus mode, as we have it today, part of a bigger game with 2 player co-operative fights against AI opponents

Standing from this: the hold of 2026-10-06 is lifted. The co-op mode is a research question only (Research & Prototyping writes docs/research/co-op-brawler.md); nothing is built or scoped until Orb has read it.

## Co-op: Orb's answers to the study's eight questions (2026-10-11)

Answering docs/research/co-op-brawler.md, in Orb's words:

> 1) solo or co-op, CPU partner optional
> 2) multi-fighter combat sounds really cool, if the director system is capable of dynamically integrating choreographed multi-fighter fights we're going to go for that; I see two players able to fly around the planet as they are able to in the system we already have, then choose to engage any enemy they see. if player2 is already engaged, the fight should seamlessly continue if player1 starts attacking the same opponent.
> 3) there's got to be weaker grade opponents, ideally various grades of henchmen created with procedural body parts to create lots of variety
> 4) Multiple planet runs, each planet has a boss
> 5) Planet destruction should be rebalanced in such a way that in versus mode it is achievable, in story mode it becomes unlocked in certain situations.
> 6) No friendly fire on partners, leaving possibility open of an illusion technique or mind-control that can be an exception
> 7) online versus
> 8) I'm still concerned about the feasibility of the phone control scheme

> keep work going, I want to see the reworked arenas when they are ready

Standing from this: co-op is wanted, as free roaming for both players with any enemy engageable and a second player joining an engaged fight without a break (so more than "lead and wing" if the director can carry it); graded henchmen from procedural body parts; several planet runs, a boss per planet; planet destruction achievable in versus and unlocked by situation in story; no friendly fire, with a possible illusion or mind-control exception; online versus comes before online co-op; the phone control scheme is still an open worry. Still research and paper rules; nothing is scoped into a build yet.

Asked what "the reworked arenas" are, Orb said (2026-10-11):

> the band that the fighters travel, extra Z-axis space for engaging and believable building layouts and dectruction

Standing from this: Orb wants to see World's fight lanes, buildings in depth and district layouts with destruction reading in depth, as soon as there is something to look at.

## The web build comes back when the build is upgraded (Orb, 2026-10-11, evening)

> when the build is playable and appreciably upgraded from where we had it, please be sure to get the web browser version working again so I can share my progress and get fresh eyes on it. at a minimum I want the updated Z axis to stand out as a new feature.

Standing from this: Orb wants the browser build back online to share once it is playable and clearly better than the build taken down, with the city's depth standing out as a new feature. The flash conditions for the site's return (Legal RL-119/121/123) still have to be met or Orb has to rule on them.

Orb's rulings the same evening, on the reworked city and the site's return:
- City scale: "Shorter and broader": downtown 20 to 40 fighter heights with wider buildings and two or three taller landmarks.
- Crowd: "Thin and mute it": fewer figures on the fight's sidewalk, smaller and greyer so the fighters stand out.
- Foreground row: not ruled; Orb asked: "I remember there being a blotch-pattern that would render the buildings in the foreground see-thru, is that still what we're going with?"
- The site's return: "Wait for the pass": the site stays down until the whole flash set passes on the published commit.
- Foreground row, ruled after seeing the see-through patch and the stubs side by side:

> try option 1, the larger see-through patch first, as the patch needs to become bigger to accomodate more missing action allow a hybrid approach where the building also shrinks, I'd need to see it in motion to appreciate though

Standing from this: the foreground opens by a larger see-through patch that follows the fight; as it must grow, the building also shrinks. Orb judges it from a motion clip before it is settled.

## The brawl drifts in depth (Orb, 2026-10-11, night)

> keep going, let me know when the motion clip is ready. In one of the prototypes for the depth axis I really liked how the brawl could get dragged gradually forwards and backwards relative to the camera. ideally, assuming a neighborhood with streets making up a perfect 4x4 grid the same depth as the Z axis, the fight could occur over any intersection. the way you described it a few days ago made a lot of sense, and the prototypes all looked like they were leading in the right direction. I'm going to sleep for the night, keep busy for at least the next five hours.

Standing from this: the fighters are to travel the depth band, not only fight in front of a city drawn in depth: a brawl can be dragged gradually toward and away from the camera, and in a neighbourhood whose streets form a grid as deep as the band, a fight can happen over any intersection. The depth prototypes (research/band-proto and World's lanes plan, L3, T, L4) are the direction.

## How a tower opens when the fight is behind it (Orb, 2026-10-12)

Shown the see-through patch and the stub for a fight in the middle street, and told of a third way (only the tower's lowest floors cut away across its width, the tower and skyline staying):

> "open floors" sounds like it would look the most natural, get that implemented

Standing from this: tall buildings in front of a fight open by their lowest floors. The see-through patch with the shrinking hybrid stays the rule for the low foreground row until Orb has judged the motion clip.

## The next public build is a big step; every attack useful held, tapped or mashed (Orb, 2026-10-12)

> I want the next playable version on the site to be a huge step from what was offered before. take your time and get it right. I still like the way the held light-attack flurries, lets make sure every attack has some meaningful way to be utilized either help, tapped, mashed rapidly

("help" read as "held".)

Standing from this:
- The site does not come back at the first flash pass. It comes back when the build is a large step beyond the one taken down: the three-strength brawl tuned, the reworked city, and fighters travelling the depth band, with the whole flash set passing on that build. No date is set; quality over speed.
- The held light attack's flurry stays as Orb designed it and likes it.
- A design rule: each of the three attacks (light, medium, heavy) has a meaningful use in each of three ways of pressing: held, tapped, and mashed rapidly. None of the nine is a trap or a flourish.

## Well-timed taps are rewarded (Orb, 2026-10-12)

Asked whether rewarding well-timed taps is the direction for the tapped column of the nine-cell table:

> yes, reward well-timed taps, if the player taps at the moment they land a hit they get a perfect followup --- please brainstorm if this could be improved

Standing from this: the timing anchor is the moment the player's own hit lands; a tap on it earns a perfect follow-up. The details are open to improvement, to be proposed to Orb.

## Four fighters soon; destruction is a priority; the "sensitivity" remark was sarcasm (Orb, 2026-10-12)

> just clarifying: right now we're building a moveset and calibrating balance on two generic stand-in characters, once we start introducing actual fighters intended for the release version how will the balance be affected? how much retooling will need to happen? Ideally each character should have their own 'flavor' of attack animations and movesets, with a large common pool of attacks to pull from.
>
> Can we establish a workflow for the characters so I can get at least four into the playable build soon?
>
> footnote: I was being sarcastic about the "sensitivity" ruling that legal seems to be taking at face value. now I'm in a weird spot because you took my ruling seriously and legal seems to be making calls based on it. it really was just an extraordinarily out-of-place piece of writing "take the towers down" or whatever, but I will resolve to be careful in the future about saying things that may be taken overly literally or affect future rulings. realistic building destruction is absolutely a priority, gaps between floors without realistic looking supports will make players lose their suspension of disbelief, so lets get some kind of compromise in there so smashing opponents through multiple buildings is climactic, catastrophic, visually appealing, and part of the gameplay hook. I just get frustrated that the quality of writing I'm presented with for forward facing things like web-pages and in-game dialogue seems so rushed and bizarre.

Standing from this:
- **Withdrawn:** the rule of 2026-10-06 against showing or describing buildings falling, breaking or being brought down. It was the EP's over-literal reading of a sarcastic remark about one bad line of copy. Every ruling built on it is to be re-made without it.
- **Building destruction is a priority and a hook:** smashing an opponent through several buildings is to be climactic, catastrophic and good to look at, and part of how the game is played. Buildings must look structurally believable, including where floors are opened or cut: real-looking supports.
- **Fighters:** each has his own flavour of attack animations and moveset, drawn from a large common pool. A workflow is wanted that gets at least four fighters into the playable build soon. The four of the vision: the Protagonist, the Anti-hero, the Galactic Tyrant, the Demon Cyborg.
- **Writing:** Orb finds the forward-facing writing shown so far (web pages, in-game dialogue) rushed and bizarre. Forward-facing text is to be written with care and seen by Orb before it is used.

## Three styles on every button, grappling on A, and the Empress's guards (Orb, 2026-10-14)

Verbatim:

> go ahead and start. I want the three face-button striking styles (mash, timed, hold) across each face button feeling responsive, useful, and visually engaging each in their own way. I still want to work on how the grappling could work on the fourth face-button.
>
> spitball mode: additionally, populate the homework folder with as many assignments as necessary to guide the game mechanics into incorporating the "pet class" that I want incorporated in the Empress as a character. Her base form should be able to summon elite troopers to fight alongside her, turning fights into multi-fighter brawls. there should be a compromise of losing certain energy attacks, grabs et cetera, in order to give commands to the semi-autonomous elite guards. What's the upper limit we can realistically push the fight-choreographer to accept? Ideally I want multi-brawls to work as one versus many -- -- that is to say, a 2v2 fight will only ever be two 1v1s, or a 2v1, 2v2 always breaks off into two 1v1s. The most I would like to see is a 4v1, as long as the fight choreographer can meaningfully keep the battle looking exciting and feeling responsive. I want the empress to, at most, be able to have two elite guards at once, meaning the empress can, with minimal setup, fight 3v1 in her base form in versus mode.

Answers to the EP's questions the same evening:
- How the Empress gives orders to her guards: "Your call" (Game Design and Controls propose; Orb marks it in homework).
- A guard knocked out: "Resummon on a cooldown".
- Scope: "Versus only, co-op held". The one-versus-many choreographer is built for the Empress's guards in versus; co-op stays unbuilt.
- Grappling on A: "Let the team pitch it" (Combat, Game Design and Animation pitch ways in a homework file before anything is built).

What follows from it:
- Every face button's tapped (timed), mashed and held use must feel responsive, useful and visually distinct.
- The fight choreographer learns one-versus-many: at most 4v1; a 2v2 always splits into two 1v1s; a 2v1 is allowed. The Empress has at most two elite guards at once, so 3v1 in her base form.
- Commanding the guards costs the Empress some of her energy attacks and grabs.

## The browser demo comes back, with a menu (Orb, 2026-10-14, night)

Verbatim:

> keep going, I'm heading to bed. can we put a playable browser demo back up, with a disclaimer for the photosensitive if necessary? can we have a simple menu with basic controller options (1p, 2p, controller/keyboard, presented in radio buttons?) to set before beginning the fight? give some checkmark options to turn on/off settings like intros. if this is feasible to have done by 7am, lets get it done. I'm going to sleep.

What follows from it:
- Orb's word to bring the playable web build back (the site has been offline since 2026-10-06), with a photosensitivity notice. It replaces "wait for the pass" for this return; Legal's interim terms apply (a click-through first screen, no autoplay, "Reduce flashing" on by default, the finding stated truthfully, no promotion while clips fail).
- A simple pre-fight menu: radio buttons for one or two players and for controller or keyboard; checkboxes for settings such as intros.
- Target: by 7am on 2026-10-15.

## Whip-pan haze or a pan cap (Orb, 2026-10-15, morning)

Asked whether to clear the signature-in-the-city flash failure by melting buildings into the background during a whip pan (a stronger form of the pan haze Orb turned off on 2026-10-06) or by Camera capping whip-pan speed, Orb chose "Camera's cap first". The haze is held as the fallback, used only if the cap does not clear the scene.

## Sky, fog and mountains, tightened (Orb, 2026-10-15, morning)

Verbatim:

> I want all elements of distance fog, background mountains, skies to all look fantastic and not overlapping in a strange way, in the original demo the sky and stars would appear as a close fog that obstructed view of the mountains, I want all the visuals to get tightened so the lighting can be fully appreciated when flying around the planet

What follows from it: a visual pass on the layering of sky, stars, distance fog and background mountains, so each sits at its own depth (no sky or stars drawn as a near fog in front of the mountains) and the lighting reads when flying around the planet.

## Orb marks the first ten lines (2026-10-15)

Orb rewrote all ten and wrote the rules below. Verbatim from homework/1-ten-lines.md:

## The Protagonist

**1. He lands a clean hit.**
> "That one was harder than I meant."
"I didn't mean to hit you that hard..."
- [ ] keep  - [ ] cut  - [x] rewrite:
- Why: less passivity

**2. He takes a hit.**
> "Okay, that one counted."
"You're really strong!"
- [ ] keep  - [ ] cut  - [x] rewrite:
- Why: protagonist should show interest in his opponents technique, he is fascinated by martial arts

**3. His swing misses.**
> "I was showing off. I missed."
"Hey, you're fast!"
- [ ] keep  - [ ] cut  - [x] rewrite:
- Why: respectful banter, minimal chattiness

**4. He launches the rival.**
> "Mind the roofs!"
"I want to see your new technique..."
"Everyone, get to safety!"
- [ ] keep  - [ ] cut  - [x] rewrite:
- Why: always wants rival to fight without restraint to test his own abilities; if he launches any opponent towards a crowd he should seem concerned

**5. He makes a perfect block.**
> "Your shoulder dropped. I saw it."
"Try not to rotate your shoulder like that..."
- [ ] keep  - [ ] cut  - [x] rewrite:
- Why: playful, puts other fighter's ability into question (disrespectful by accident)

## The rival (the Anti-hero)

**6. He lands a hit.**
> "You blinked before it landed."
"This is the fight you wanted, right?"
- [ ] keep  - [ ] cut  - [x] rewrite:
- Why: Ego, mocking

**7. He takes a hit.**
> "I allowed that one."
"You're not holding back, are you?"
- [ ] keep  - [ ] cut  - [x] rewrite:
- Why: probing opponent for hidden strength

**8. His blow misses.**
> "That was aimed where you should have been."
"You're agile, I'll give you that."
- [ ] keep  - [ ] cut  - [x] rewrite:
- Why: tepid, ego-driven compliments; rival is capable of recognizing worthiness but 'plays his hand close to his chest' 

**9. He launches the Protagonist.**
> "Take your time coming back."
"Are we here to play games?"
- [ ] keep  - [ ] cut  - [x] rewrite:
- Why: Rival shouldn't sound too patient.

**10. He makes a perfect block.**
> "I watched the whole wind-up."
"I'm not impressed."
- [ ] keep  - [ ] cut  - [x] rewrite:
- Why: short, simple, ego-driven

---

## Anything about the voices in general?

(For example: too wordy, not funny enough, too modern, wrong for this fighter.)

Your notes: just strange, lame, wording, most reeked of LLM generated nonsense and hardly felt believable for something anyone would say in a real animated shonen fight. quips should be pithy, punchy, passable.

The following is twenty lines I received from gemini, specifically for battles between protagonist and rival, not necessarily intended to be used between any other fighters. They're almost all just a little wordy for my taste, but with one or two exceptions they all sound miles better than what I've received. If future voice lines I receive sound like these, but just trimmed down and punchier, I'll be exceptionally pleased.

**20 Shonen Rivalry Battle Lines**

**The Protagonist (The Battle-Hungry Brawler)**

1. "Now we’re talking! Don't hold back on me now!"
2. "Man, I really felt that last one. My turn!"
3. "You’ve gotten way faster. Guess I gotta step it up too!"
4. "Come on, is that all that big pride of yours gets you?"
5. "I’ve been waiting all day to see that look on your face!"
6. "Take a breather if you need it—I want you at your best."
7. "Haha! You almost took my head off with that one!"
8. "Quit overthinking it and just hit me!"
9. "Everything hurts... man, I haven't had this much fun in years!"
10. "Alright, warm-up's over. Let’s see if you can keep up with this!"

**The Rival (The Proud Elite)**
11. "Wipe that stupid grin off your face and fight me!"
12. "Don't you dare hold back on me, you idiot!"
13. "You call that a punch? You’re insulting us both!"
14. "Stay down! Actually—get up so I can put you in the dirt again!"
15. "I didn't train through hell just to watch you pace yourself!"
16. "Keep laughing. Let's see you smile with broken ribs."
17. "You're always one step ahead... and it makes me sick!"
18. "Shut up and take this at full power!"
19. "I’m the one who finishes you today. Nobody else!"
20. "Drop the act! Show me the power you're hiding!"

---

**Why LLMs Fail at Shonen Banter (And How to Fix It)**

When LLMs write fight dialogue without strict guardrails, they default to "Silver Age comic book villain" or purple prose. They use ornate metaphors (*"We dance upon the edge of oblivion!"*), overly formal grammar, and multi-clause sentences that no human could actually yell while throwing a punch. Good shonen localization sounds like a mix of high-level locker-room trash talk and bar-fight adrenaline.

**Expanded Prompt Instructions (Copy & Paste for Future LLM Sessions)**

> **Voice & Dialogue Directives for Shonen Combat Banter:**
> * **The "Mid-Punch" Brevity Rule:** Every line must be between 4 and 12 words. If a voice actor cannot scream the line in a single breath while throwing a haymaker or spitting blood, cut it in half. Use sentence fragments, interruptions, and contractions (*don't, gonna, gotta, you're*).
> * **Ban "LLM Thesaurus" Words:** Strictly avoid theatrical, archaic, or overly literary vocabulary. Do NOT use words like: *commence, futile, demise, symphony, dance, crescendo, reckon, mere, behold, destiny, abyss, limit, surpass,* or *eternal*.
> * **Use Physical, Blue-Collar Verbs & Nouns:** Anchor the dialogue in immediate physical reality. Use words like *dirt, teeth, ribs, breath, warm-up, hit, drop, bleed, grin, pace,* and *choke*.
> * **Write for the English Dub, Not a Philosophy Essay:** Characters should never explain their dynamic out loud (e.g., *"As your rival, I will prove my superiority!"*). Instead, have them react to immediate physical triggers: the speed of that last kick, the other guy smiling after taking a hit, heavy breathing, or the suspicion that the opponent is holding back.
> * **Lock in the Dynamic:**
> * **The Protagonist** sounds like an excited athlete in a heavy sparring match. He is casual, disrespectful by accident, grinning through pain, and only cares about drawing out the Rival's top gear.
> * **The Rival** sounds impatient, abrasive, and insulted. He hates being pitied, hates when the Protagonist smiles, and treats anything less than a 100% lethal effort from the Protagonist as a personal humiliation.

## The ellipsis, and keep refining for multi-fighting (Orb, 2026-10-15)

Verbatim:

> I think the ellipsis can be used to signify hesitation, regret, perhaps performative exhaustion among others, they should be used sparingly but in context it's a good literary device for what we're trying to do.
>
> keep working, I want the depth and breadth of animations and mechanics continually refined and enhanced in preparation for multi-fighting and improvements to the dynamic fight choreography

## Orb answers homework 2, the brawl feel (2026-10-15)

Verbatim from homework/2-brawl-feel.md (questions, ticked boxes and notes):

## The perfect follow-up

**1. The quick light lands too soon to tap on the hit.**
It lands two ticks after its press, faster than a hand can press again. The current answer: the light's striking hand stays planted on the opponent for a moment, and your window opens as it lets go.

- [ ] Yes, a chain can start from a light that way
- [ ] No, a chain should have to start from a medium or a heavy
- [x] Your call
- Notes: whatever works in favor of "rule of cool" without negatively impacting player agency

**2. How quick is "perfect"?**
The current rule gives the follow-up a shortened wind-up: a perfect light lands 10 ticks after your tap, a medium 6, a heavy 14. (Sixty ticks is one second.) With no wind-up at all it could not be tapped again, and an instant heavy would be a sure thing.

- [ ] Shortened wind-up, as written
- [ ] It should be instant
- [x] Your call
- Notes: the term 'instant heavy' sounds like an exploit, but if it's a functional mechanic that high-level players could explain use cases for then it could be worth investigating. 

**3. Can a perfect block answer a perfect follow-up?**
Game Design says yes: a chain needs an answer in its own language.

- [ ] Yes
- [ ] No, a perfect follow-up cannot be perfect-blocked
- [x] Your call
- Notes: the idea of perfect responses back and forth escalating into an amplified knockback with potentially higher levels of destruction to the environment sounds fun to me, please explore this

**4. Should mixing strengths close the chain sooner?**
As written, a follow-up of a different strength counts double. Light, medium, heavy opens the opponent in three blows; three lights need four.

- [ ] Yes, reward mixing
- [ ] No, three perfects is three perfects
- [x] Your call
- Notes: I don't necessarily like the idea of an 'upper limit' to chained combos though I can understand how they could be necessary. Give the choreographer leeway to dynamically decide combo enders and chains based on the environment and other factors.

**5. Does a perfect follow-up cost Charge?**
As written: a perfect light is free; a medium and a heavy cost their normal Charge.

- [ ] As written
- [ ] All perfect follow-ups are free
- [ ] All cost their normal Charge
- [x] Your call
- Notes: I think pulling off perfects should reward the player by, at the very least, not expending energy

---

## The nine ways to press

Light, medium and heavy, each tapped, mashed or held. The table is in `docs/design/brawl-second-pass.md`, section 15.

**6. Holding medium becomes a "charged medium":** lights cannot stop it, and at full charge it staggers the opponent. Is that the move you want on a held medium?

- [ ] Yes
- [ ] No. What I want instead:
- [x] Your call

**7. Anything in the nine you would change?**

Your notes:

---

## Three on-screen hints

Each would show once, ever, the first time it applies.

**8.** "Tap as your hit lands."

- [x] keep  - [ ] cut  - [x] rewrite:
its good, revisit if the mechanic changes or is enhanced
**9.** "Held to the click: a knock-back."

- [ ] keep  - [ ] cut  - [x] rewrite:
i don't even know what this means
**10.** "He missed. Medium stops him."

- [ ] keep  - [ ] cut  - [x] rewrite:
i don't even know what this means
**11. Controller rumble on a perfect: on by default?**

- [x] On by default
- [ ] Off by default
- [ ] Your call

---

**New (12 October). Holding X when the fighters get knocked apart.**
You hold X and your fighter flurries. Then the two are knocked apart. Game Design's ruling is that he waits for you to press again, because every attack on screen should match a press. In testing, a held X that does not carry back in wins almost nothing.

- [ ] He waits for me to press again (the ruling)
- [ ] He flies back in and keeps attacking by himself
- [ ] Only as an accessibility setting, off by default
- [x] Your call
- Notes: err on the side of player agency, but the fights move so fast that the ability to 'chase' a knocked back opponent and continue a beatdown in midair might fulfill 'rule of cool' and add to player agency at the same time. lets work on this and get it feeling really good in playtests.

## Orb answers homework 3, fighters (2026-10-15)

Verbatim from homework/3-fighters.md (questions, ticked boxes and notes):

---

**1. Do all fighters share one clock?**
Under this rule a heavy-handed fighter's heavy takes exactly as long as anyone else's. Fighters differ in what they throw, how it looks, where it lands, their toughness and their signature, but not in timing. This is what lets the balance work done so far carry over to every new fighter.

- [x] Yes, one clock for everyone, at least until all four are in
- [ ] No, fighters should have their own speeds. (This means re-balancing per fighter.)
- [ ] Your call
- Notes:

**2. The Cyborg and the Empress without their special mechanics yet?**
A first version of each could be playable soon with their own look, voice and moveset, but without minions, stages, consumption or the companion hunt. Those would follow one at a time.

- [ ] Yes, show them early without their mechanics
- [x] No, hold each back until their mechanic exists
- [ ] Yes for one of them: ____________
- Notes:

**3. The order.**
Proposed: the Anti-hero first (he is nearest to done), the Protagonist alongside, then the Cyborg (the cheapest new body), then the Empress (her mantle needs the most rig work).

- [x] That order
- [ ] A different order:
- Notes:

**4. Which fighter's one-page brief do you want to write or mark first?**
Narrative has pre-filled a page for each from your notes; marking one takes about fifteen minutes.

- [x] Protagonist  - [x] Anti-hero  - [ ] Demon Cyborg  - [ ] Empress
- Notes:

**5. A plain "reference" fighter.**
Game Design wants a plain fighter with base stats as a measuring stick: new fighters are compared against it, which shows whether a problem is the fighter or the game.

- [ ] Keep it out of sight, a testing tool only
- [x] Put it in the roster as a training dummy
- [ ] Your call

---

**5b. Borrowed heavies at first?**
A new fighter would draw most of his heaviest blows from the shared pool at first, each thrown in his own style, with two that are his alone. More of his own come later.

- [ ] Fine
- [ ] Each fighter needs his own heavies from the start
- [x] Your call

**5c. Signatures for the two in the build.**
Proposed: the Anti-hero's signature is a barrage of shots; the Protagonist keeps the beam.

- [ ] Yes
- [ ] No. What I want:
- [x] Your call

**5d. Choosing a fighter.**
There is no fighter-select screen yet: a match starts as the Protagonist against the Anti-hero. One will be needed for the third fighter. When should it appear?

- [ ] Once, when the game starts
- [ ] Before every new match
- [x] Your call

---

## The Anti-hero: two small things Art is waiting on

**6. His aura.** Art has a set of options and needs your pick. Do you want a sheet to choose from, or to describe what you want?

- [x] Send me a sheet
- [ ] I'll describe it:

**7. His glasses: always on?**

- [x] Always on {{spitballing: lenses, frames can crack, bend, some dialogue could reference this briefly like bragging about paying extra for the best frames, or lamenting needing to buy a new pair when the match is over}}
- [ ] They come off (when?):
- [ ] Your call

---

## Do the two in the build feel like themselves yet?

You called them "generic stand-ins". They wear the approved looks, but right now they both fight with the same borrowed moves, which is being fixed. Is there anything else that makes them feel generic to you?

Your notes: two guys with different colored shirts wearing backpacks. perfectly fine for a test environment, but more personality, style, and distinction would go a long way.

## Orb plays the live demo against the computer (2026-10-16)

Verbatim:

> I played a match against CPU opponent. in a lot of ways its in a good spot. I couldn't quite figure out how to launch my opponent, I did successfully maybe once or twice. when I did manage to launch them, the split screen didn't really catch up with them, and I felt like I had no idea what they were doing until they rushed back at me at full speed and got some cheap hits. the game is really fast paced so losing track of your opponent can be a little disruptive. the beam struggles need to feel more dynamic, it felt like the winner of the beam struggle was determined as soon as the beams were fired and that nothing I pressed during it could affect the outcome. the beams are too thin right now. it would be cool if a particular beam attack for one fighter in the roster was thin, but for all of them to be tiny doesn't look right. I really want the beams and energy attacks to have cool, rippling, glowing, fluid-looking shaders, each character should have their own flavor of energy attack. the explosions from the small energy attacks should be more explosive, flames and smoke. I did manage to bring the fight to a small town and the building destruction looked cool. it felt like the CPU opponent was able to easily perfect block every charged attack I used.

What follows from it:
1. Launching is not discoverable: the player could launch only once or twice.
2. After a launch the split view did not keep the opponent in view; the opponent returned at full speed for cheap hits. Losing track of the opponent is disruptive.
3. The beam struggle must be decided by what the players press during it, not when the beams fire.
4. Beams are too thin; each fighter's energy has its own flavour, with rippling, glowing, fluid shaders (a thin beam can be one fighter's particular move).
5. Small energy attacks' explosions need flames and smoke.
6. Town destruction looked good.
7. The computer perfect-blocks charged attacks too easily.

## Orb answers homework 4, watch and listen (2026-10-16)

Orb's marks, in short (their words quoted where they matter):

- **See-through patch on low foreground houses:** the window is the right size and the sinking is good: "looks cool, felt natural". Wants more dynamic damage patches on the nearby buildings.
- **The lobby under a tower:** close, needs changes. The ghosted columns are distracting and the see-through is not strong enough: "fighters are still obscured partly, would be better to see all the way thru the inner lobby pieces". The core: thinner still. A damaged tower keeps its lobby (the built, switched-off damaged stages). Cleared floors are believable. The hit mark is good. The glass tower near black at its first stage is fine. A blast's speed is right. If blasts need more flash margin from lit windows or the crater's glow: "show me first".
- **The perfect follow-up's sound:** the rising note is too much. The opponent's chain needn't sound different. "needed to sound 'chuckier' [read: chunkier], kind of sounds metallic and high pitched".
- **The brawl's sounds:** "a little too high pitched, hits sounded a little 'tinny'".
- **The city:** the crossing looks good; Orb wants to see it in motion in their own play. The skyline "looks great"; up close the buildings need more detail so players don't "just see a bunch of dark grid lines". The crowd is good but still too busy, "a little too clustered"; cars on the roads for realism.
- **The HUD's teaching sheet:** needs editing and plainer language ("the bolt's land" and "ink on the dark scrim" read as nonsense).
- **The three styles on each button:** not distinct enough yet; "arms still seem to bend in weird, unnatural ways".
- **Each fighter moving his own way:** yes, they move like different people. In cue-tech the legs fold up and look strange.
- **The flight round the planet:** the direction is right; the distant mountains and the sky colour look right. The fighters flew underwater around dusk, so the evening light was mostly dark ocean: show it again over land.
- **Clarified the same day:** "thinner still" for the core meant the depth of the see-through effect, not the core's size. Orb likes the core's size as it is; some variety in size per building is welcome. Orb wants more city variety: the skyscrapers' "black and grey grid" look should get more visual appeal.

## Orb answers homework 5, the city and depth (2026-10-16)

- **Depth:** no direct steering; depth follows from pushing, pulling and sidestepping, as built.
- **The street grid:** see three streets with fighters moving first. "the four-by-four was just illustrative, whatever we can do to make immersive city environments that are fully destructible and reactive is okay by me."
- **The crown tower:** Orb's call to us. EP decision: Legal's recommendation, short stubs in the tower's own tone.
- **The civilian count:** shown another way; our call. EP decision: no running number during the fight (a small bar for the share lost); the exact count on the results screen. UI to propose the bar.
- **Where fights happen (verbatim):**

  > a big issue with this is the spawn-in location just seems to be very far away from the city. ideally fighters should touch down in a random spot on the world, or a spot pre-determined by the level once we get to story mode. I want the planet to be procedurally built every time, just spitballing here: if the entire planet could be stored somehow, and then the shape the fight takes is a random slice going along the entire diameter of the planet, so the same cities and towns and landmarks can be seen from fight to fight, but different ones might pop up. please return some early prototype diagrams of how this could work to me so I can see if we're on the right track. Ideally I want a fight to have at least two cities, multiple towns, and a few different biomes spread across the length of the arena.

- **Towers and power:** yes, a tower holds early and going through towers is earned. "early in the fight a well-earned power hit could send an opponent through the side of a skyscraper and they recover inside, but later in the fight at max power the same hit could launch the fighter through three skyscrapers, causing them to pancake-collapse, then propelling into a crater that levels nearby skyscrapers."
- **Buildings that matter:** all three: the wall slam, cover from a beam at lower power, and the falling stack. Plus: "dodging a beam that hits a skyscraper behind you should give a live picture-in-picture view of the damage, depending on how significant it is".
- **A falling building hurts:** only the fighter it was aimed at.
- **A fighter lodged in a building:** wait until Orb plays it. Orb wants fights fast; holding only the lodged fighter is good if it gives the attacker openings (heavier energy barrages), an incentive for knock-back attacks.
- **The hero and buildings (anguish), verbatim:**

  > the anguish mechanic might need to be reworked somehow, lets keep working on this because building up anguish by intentionally killing civilians is a perverse incentive for the protagonist, and a fight against another "good guy" once there are more fighters might be lame and boring if neither can power up because they're avoiding civilian deaths. we could solve this potentially with Protagonist having multiple branching forms, one branch achieved by witnessing civilian deaths at the hands of his opponent, perhaps one achieved by allowing his opponent to power up first and testing himself against a higher form

- **A staredown before the clock:** wait until Orb plays it. "I want dynamic fighter introductions, I want them to play out different every time based on who is fighting, where they spawn in at, any other variables we can think of."
- **The city overall:** "its looking great". The high-altitude skyline impressed Orb: taller high-rises clustered in a denser centre, smaller buildings on the outskirts. Today's stills lessened the worry that the towers were too packed and the black-and-grey grid confusing up close.

## Orb on the stored planet: a run across slices, and ice caps (2026-10-16)

Orb looked at World's picture A (the planet stored) and is "very pleased". Verbatim:

> ideally if the destruction could be stored across a run, spitballing here: the brawler game-mode could be like a roguelike, with multiple stages across different slices of the planet, small dynamic storyline exposition between each stage. the cities would remain damaged between fights, until the final fight against the boss, where world-catastrophe level variants of abilities can cause large scale destruction; beam damage that goes through the crust and magma bubbles up from the mantle; giant mushroom cloud explosions throw smoke into the upper atmosphere that darkens the entire planet sky; fighters take to the upper exosphere and throw energy blasts that cause visible glow and enormous explosions to the planet surface far below them.
>
> I want icecaps on the northern and southern poles, inspired by our real-life poles, a big icy landmass south, broken up icebergs, floes, sea ice on the north. show me a new prototype that iterates on the one I just looked at.

What follows from it:
1. Damage persists across a run (homework 22's third question, answered for a run).
2. A spitball, recorded, not yet briefed: a roguelike brawler mode, stages on different slices of one planet, short story beats between stages, cities staying damaged until a boss fight with world-catastrophe variants (beams through the crust to magma, a mushroom cloud that darkens the planet's sky, an exosphere fight bombarding the surface).
3. Asked now: a new planet prototype iterating on picture A with polar ice. South: a big icy landmass. North: sea ice broken into icebergs and floes.

## Orb picks the looks, the grapple and the one-versus-many rules (2026-10-16)

**The fighters' looks** (homework fighters/PICK-looks-aura-glasses):
- The Protagonist: a hybrid of the Sparring Partner (ivory top, wooden promise tags on the belt) and the Showman (an open boxer's robe with a big ring on the back).
- The Anti-hero: a hybrid of the Rank Sash (one armoured shoulder, a sash with five rank studs, arms folded high) and the Pressed One (a closed coat with pressed edges, small polished shoulder plates, buttoned cuffs).
- His aura: "hybrid, let me see something that is 70% (1) and 30% (5)": violet that warms then cools, with some of the blades' broken outline.
- His glasses: Art's plan (a cracked lens when battered, crack and bend when broken, a bend when a hit throws his head, the finger nudge straightens it).
- The training dummy: "hybrid all three, pads is strongest, I like the rig a lot, the frame seems practical".

**Grappling on A** (homework 20): "hybrid between catch and clinch, rule in favor of clinch". Orb's note: "fantastic ideas, I see it as a way to set up combo chains and create varied combat scenarios".

**One versus many** (homework 19):
- Yes to the plan: three on one first (the Empress), four on one behind a switch once three on one plays well, no five on one, two-on-two unbuilt.
- How many hit at once: Orb ticked "all three, if they are in reach" and "your call". EP's call: all three may land blows on the lone fighter, but through the measured rule (one partner in the exchange, the ring's single blows on openings), because all three striking freely measured unplayable.
- Who the lone fighter's attack goes to: our call. EP: whoever his stick points at, else the nearest.
- Moves that hit everyone in reach: yes, some.
- Where a 2v2's second fight goes, and whether finished fights merge: our call. EP: the winner of one joins the other (a 2v1); placement waits for co-op.
- If four on one looks messy: wait to see it.
- Who else fights one versus many: "I don't want the cyborg to have minions. A future fighter may indeed have some partners. A story boss would be great. A brawler co-op with two partners engaging in their own 4v1s simultaneously could be extremely entertaining, or confusing and too overwhelming."

## Orb answers homework 8, housekeeping (2026-10-16)

- About page: dropping "edits the dialogue by hand" until Orb has marked the first batch is fine.
- Public pictures: city diagrams and stills without fighters may be public; stills of the two fighters as they are in the build may be public; **HUD mock sheets stay private**. (In-progress character art stays private as before.)
- The public page when the build returns: three short versions to choose from. "these need to be high quality before you show me, don't be afraid to iterate on it until it reads perfectly."
- A store home: not yet, our call, meaning "I'd like honest recommendations, steps to follow, all written for a beginner to this type of business. I've never sold a game before so I need guidance in order that I don't spin my wheels, so to speak."
- The licence: Orb wants Legal's one-page rundown.
- Individual or company: not yet; "give recommendations for starting a company for the purposes of selling the game more effectively, state of oregon, USA".
- A stomp on a downed opponent's head: our call, but "I kind of understand that there are contexts, like a brutal curb stomp versus over-the-top crashing down from the sky should be judged differently, definitely give me more context on this before it affects any rulings."

## Orb answers homework 22, 22b, 23 and 26 (2026-10-16 evening)

**Launching and caps (homework 23).** The hint: C, "He's open! Press B and send him flying!" (our call too). Verbatim:

> I don't know how I feel about limiting this to 4 hits in a row, there should be mechanics to chain together attacks dynamically and emergently; launchers should have an intuitive way to activate and aim at any point in a combo string.

> I'm not a fan of "cooldowns" and "recharging" exccept in limited circumstances, so try to balance it in a way that avoids strict caps on what a player can do in a fight.

**The hero's branches.** The witnessed branch as a cold quiet (our call too). Names: "please pitch these". Two good fighters: "I don't understand, but i'm happy if there is more flavor text for more situations." The forms tree: "Yes, build toward this", with notes:

> rule of cool always applies, the more dynamic situations a player can achieve through unexpected means the better. As long as each fighter's transformations are exciting and feel like an achievement rather than a burden or an obstacle we should keep building on these ideas. Protagonist should be unique in that he has a variety of transformations that give him modest all-arounder buffs; theory-craft protagonist's 'sling-shot'-type of transformation, where he stays in his base form and allows the opponent to grow, when he finally transforms he can get a bigger boost based on how long he waited and the damage traded before transforming.

**Buildings: "Sounds right"**, with notes:

> entertaining ragdoll physics-based combat should be a goal, rule-of-cool always takes precedence, player agency should always be respected but when rule-of-cool demands it, the fight choreographer should determine the direction the fight takes. players should always feel like they were able to mid-air recover in a reasonable amount of time, they should expect bigger blows to send them flying backwards, 'skidding in midair' to regain fighter control should be a thing to demonstrate velocity. If a fighter is launched at such a vector that they impact into the side of a building, hit the floor inside the building (collapsing it), they might bouce up and off the ceiling (also collapsing it), then downward once more to crash into the next floor below. the fight choreographer should always be aware of cool scenarios as the fight progresses and use the combat alchemy system to choose emergent combat situations.

**The planet (homework 22).** Arena length, our call:

> if the slice bisects the center of the sphere it will be the largest arena. could the slice be along a smaller area, making the arena smaller and appear to circle around a center point? please provide prototype illustrations for this idea so we are on the same page. also research if this slice can dynamically shift through the course of a combat, rather than being determined and built at the start of the fight. Is there a procedural system we can use to achieve an arena like this? please push against this if it will create too much impact or break our current systems.

- Where fighters land: both (truly random, with a dial). "versus mode should have this optional, the co-operative story mode should dynamically pick set pieces for emergent storylines that can happen nearly anywhere."
- Damage: kept across a story campaign; "starting a new story should begin everything anew."
- Cars: scenery cars, and throwable cars too.
- "lets work towards crafting a representative fictional planet with consistent names and landmarks. I'm not sure if the story mode should have randomly generated planets for each run, or to keep the world consistent and recognizable for the protagonists."

**Ice (22b).** A few small outposts: "I like the idea of a remote research station". Cap size: "Hard to say, lets balance it further and see what it feels like in the game."

**The run (homework 26).**
- Losing: retry the same fight, or the run ends (our call): "I think there should be a mechanic that gives you extra lives".
- Power between fights: every fight starts from the base form: "depends on the story beats, each fight should start from base and depending on upgrades and unlocked abilities the higher level transformations should become achievable."
- Length: five fights and a boss.
- The boss: "combination of all of the above, there should be different story beats allowing for different final bosses. maybe one time the fifth fight sees the rival steps in between you and the boss to let the boss get away. maybe another fight you opted for a more enticing buff between the second and third fight, then you go on to defeat the empress on the fifth fight and the demo-borg appears, having one transformation left before his final form in the final fight."
- Between runs: new looks and harder challenges (our call too): "let's really dig into this and find an approachable, fun, exhilarating game loop for this type of episodic brawler. Ideally I'd like to be able to give players tons of customization options, so lets find out what kinds of rewards we can shower them with for playing."

## Orb's homework 11 (the brawl's lines), reviewed through Gemini (2026-10-16 night)

Orb ran homework 11 through Google's Gemini (the "Argon" model) and returned its marks, rewrites, voice bibles and a Godot mumble-speech guide, with: "please consider this output as very successful." The marked file is homework/done/11-lines-the-brawl.md. Provenance: the rewrites are AI-generated by Gemini at Orb's direction, and are recorded as such under Orb's disclosure rule.

Direction adopted from it (Orb-approved):
- **The rival** keeps contractions and gets back his ranking habit, as live trash talk ("third-rate", "barely top ten"). His archetype: the proud precision elite: surgical disdain plus bruised-ego pride; he denies his opponent's skill ("Lucky swing!").
- **Titles:** the Empress says "petitioner" now and then (once or twice a match). **The Cyborg drops "sir" and the whole waiter/chef gimmick.** He becomes a ravenous bio-mech: a demon stomach bolted into a robot chassis, with humour from hunger (protein, calories, tenderising), sensors and a limiter chip.
- **Insults sharper and specific:** amateur, eyesore, dead weight, third-rate, insect, clown, warm-up, scrap (not "Pathetic").
- **The Protagonist:** an adrenaline-junkie martial artist with high fight IQ; he grins through a hit, grades the impact and reads how he was beaten. "Never sound like a polite superhero apologizing for property damage."
- **The Empress:** a sadistic, booming sovereign; a royal "We"; she laughs through pain and never calls her guards for help mid-fight.
- **Rules added:** strict direct address in a 1v1 (no lines to objects or off-screen minions); visceral, tactile vocabulary (ribs, teeth, knuckles, frame, silk, rubble, steel).
- 4 of the 30 lines kept; 26 rewritten (the file has each).

Audio: Gemini's guide (syllables every 2 to 3 characters, punctuation pitch, AudioStreamRandomizer sample pools, a per-fighter Audio Bus with compressor, EQ, chorus, reverb or bitcrush) is a suggestion to compare with ours. Orb: "ideally I'd like a lightweight hybrid, whatever approach works in our system should be chosen by 'rule-of-cool'".
- **Orb rules (same night):** the Protagonist apologises for damage after the fight, never during it. On Gemini: "I'm paying for gemini so I'm assuming they allow me some degree of commercial rights." (Legal, RL-153: Google's Gemini API terms claim no ownership of output; the paid consumer app's terms were not confirmed; AI-only text is likely not protected by copyright either way.)

## Orb's answers of 2026-10-18 (homework 28, 30, 36, the forms pick, the hybrids pick)

**The demo and the flashing (homework 36, and in chat):** "You handle this, I have no idea what the technical implications are, I just want beams and energy attacks to have distinct, visually appealing, robust shader effects. Flickering and flashing was not an issue I ran into in any human testing, so the disclaimer should be enough for the limited number of people I'm sharing the link with." "I really want you to stop spinning your wheels on this flickering issue, absolutely try to fix it and leave safeguards in place, and it very well may be something to tackle vigilantly before release but I want the public page back up with a disclaimer." In chat: "Just put the game up with a disclaimer... If it's really this big issue then make it a code-red homework assignment that has images, .gif files, recordings, whatever it takes to get this solved. otherwise, keep working on it until it gets solved, and leave a disclaimer up." The EP decides the signature close-up (kept closed under Reduce flashing). Legal recorded the return as Orb's decision (addendum 11, RL-161).

**The public page (28):** Version A (plain); American spelling; cut "Slam your rival into a building and the building pays for it." On "director": "if we can accurately call a system we have a 'fight director' then why not? any honest selling points are welcome. the goal was to have a fighting game where the combos are spectacular and look choreographed, but are in the hands of the player and real-time."

**The launcher and the run (30):** repeated launches: "it's expected that each time you launch an opponent against something, the more destroyed it will be. I don't necessarily think a handicap should be applied just for repetition, though I could be convinced either way." Slingshot: waiting only makes the next single form stronger, and "lets delve into the universe lore before we finalize anything on transformations, right track though". Lives: our call. Forms: each fight starts from base and boons unlock how high you go; "possibility of unlocking rarer boons that could potentially set your base form to a transformation?" Rewards after every fight and a big haul at the end: "rewards should feel generous, there should be tons of different rewards so players feel like there's always something new".

**Forms and rewards pick:** the Anti-hero's coat in brick (#6f342c; body unchanged). The hero's forms: "all around not distinctive enough, lets bulk up muscles, add distinctive upgrade, lets get lore of the universe settled so we can explain reasoning behind transformations." Keepsakes good: collectibles for bragging rights, upgrades or cosmetic trades. Finisher styles: "I would like to see these in action before making a judgement." City tints: "These look fantastic, keep iterating on this for more variety, great direction."

**The hybrids pick:** the Protagonist a mix leaning Showman: "these prototype faces look kind of goofy. I want a better facial style for the final character models, it needs to be distinct, recognizable, not try-hard but also cool. I want the hairstyle on protagonist revisited. I want to see potential for cosmetic hairstyles that could be unlocked." The Anti-hero: B, the Open Coat; "the shoulder pieces are a little distracting... could be tightened up and become cosmetic unlocks. the face is a little distracting because he kind of looks like a puppet." The aura: "I need to see these animated. I'd like cool, pulsating, 3d visual auras that can shimmer, froth, undulate etc. based on whose aura. ideally protagonist and rival have similar but inverted themes on their auras, not just color. keep going along these lines and develop a unique aura style to convey each characters power foundation." The dummy: B, Lit Pads; "hopefully the pads can light up and make a 'dummy aura' with an in-universe explanation that it simulates a real fighter's aura using the latest technology."

**After playing the re-published demo (2026-10-18 night):** "briefly played, the ui is very strange and the 'blur effects' were really strange and distracting, the split screen is a lot worse than I remember. the framerate seems to tank during combat, the weird gray circle visible between the two fighters has got to be cut. the worst part was the constant fading, it seemed like there was some weird fading in and out that I dont remember from the last time I played." Then: "the dissolve is terrible. just dreadful looking and awful. I really hated everything about it, especially if you're telling me it dropped the framerate. I really liked the smooth camera movement and split screen from before, please iterate on that, don't dissolve the screen. do what it takes to get camera & cinematography on track with what works with regard to elegantly capturing speed and dynamically tracking the combat."

**The UI over the fighters (2026-10-18 night, with a screenshot circling the beam struggle's bar and diamond):** "I want a much more minimalist UI. thank you for addressing the grey rings but the UI should not be obscuring the fighters in any way. Please research serious ways to address the high speed combat without cluttering useless pieces of icons and garbage over the fighters. that bar between them is still the problem I'm talking about."

## Orb's answers of 2026-10-19 (homework 31 and 6) and the camera push

**The camera (in chat):** "I gave camera & cinematography the Opus model in order to really nail down the camera system. I want you to pour resources into the camera system so we have a dynamic, directed, emergent cinematic storyteller that works with the combat choreographer so every camera movement feels purposeful and not distracting. rebalancing the speed on launches may be a way to handle it. do a big research pass on effective cinematic storytelling techniques so the camera work is always spot on, even in high speed combat situations." Homework 6: "work closely with camera & cinematography to create a smooth camera system that doesn't disrupt the players. consider different forms of whip panning, creative use of angles, engineer a robust and dynamic camera system that doesn't lose track of fighters." The browser runs on the RTX 5070 Ti (opera://gpu, 240 Hz display).

**Arenas (31):** smaller arenas: "lets try to incorporate this in a meaningful way. every player might not like every fight to take place along the entire planet." The shifting arena: "the 'red loop' illustrated in 31-k1-small-circles-planet.svg can be thought of as a plane bisecting the sphere. the edges along the sphere at all perpendicular points is the ground the fighters can touch down on. if that plane shifts throughout the fight, the points they are fighting along will be different. Can you illustrate this to me so I know we are on the same page?" The planet: "I think a new planet should be generated every run, perhaps with the same name. I want to workshop more planet name ideas." Names: "Lets workshop this." Outposts: "rule of cool. consider that this may be a set piece for a new fighter. let's build the world with the idea in mind that each fighter at launch should have their own starting area on the planet, somewhere thematic and unique in the world."

**Looks and defaults (6):** Reduce flashing default: our call. The beam's tail: "it should look like its burned a trail into the very space it passed through, some kind of lingering effect." Transformation look: wait until Orb plays. The launcher's rest: "more back and forth, impacts, dynamic clashing. both fighters should be backflipping out of strikes, ricocheting off of enviornmental elements." Phones: "I want the base PC experience put first and foremost." Touch options and the world's light: later. Hints: full charge "Full! Let go to knock him back."; first miss "He's open. Hit the lit button."

**The shifting arena approved (2026-10-19):** "I can see this being used to programmatically assign stages to opponents in the story mode. '31b-shifting-arena.svg' illustrated exactly what I was envisioning. I want this approach to work, if we are looking at something that can feasibly be done, please begin work on engineering this system." World leads, building its feasible version: the ring turns about the fighters at calm moments, with a slow drift of the far land and sky between.

## Camera smoothness and the beam struggle's push (Orb, 2026-10-22)

After the progress clips (homework/progress-2026-10-22/), in Orb's words:

> "the camera looks like it snaps too fast, all dynamic camera movement should be smooth, no instant movement unless well justified by real cinematography theory"

> "i like how the beam struggles are looking; instead of thinning out, when the losing beam is being pushed closer the beam should bulge and quiver like its buckling under energetic pressure"

Standing from this: every dynamic camera move eases; an instant change (a cut, a snap) must be justified by named cinematography practice (a cut on action, a scene change such as the arena turn) and written down per cut. In the beam struggle the losing beam bulges and quivers as if buckling under pressure as it is pushed back, instead of thinning.

## Energy attacks overhaul (Orb, 2026-10-23, verbatim)

"lets find a way to separate out the energy attacks per fighter along the lines of our light/medium/heavy/grab combinations; I'm spitballing this: broadly speaking, in energy attack terms, light should rapid fire small energy projectiles, medium should lob more substantial explosive energy blasts, heavy should let loose the most potentially devastating techniques. energy grab should be some kind of technique each fighter treats a bit differently, some unique mechanic or some variation should exist between most if not all fighters, maybe someone has an energy net, someone has an energy ring. these should all be combinable with the defensive button, I'm thinking using defensive blocks while hitting energy attacks would leave energy mines or traps nearby. there also needs to be a way to choose whther to fire beam attacks or lob individual blasts, the paradigm we're in now where we have one big beam shared across fighters must be overhauled to give more player agency, the beam attacks need to have able to be charged before firing. with both beams and projectiles, find a way to carry over the rapid-fire that martial light attacks feature. please draw up and compile some prototype animations and step by step details of these features and how they will look after being implemented so I know we're on the same page."

## Water (Orb, 2026-10-23, verbatim)

"make sure we run a pass on physics, I want to be briefed on enhancing the state of the water to at least have some minor water physics; I don't want to lose the "pebble skip" we have when fighters get knocked across the surface of a body of water, but I also want it to appear like water fills in gaps dynamically when the environment changes. trenches, holes, any empty spaces bored out by fighters' energy blasts and other impacts should be filled with water when necessary. engineer a solution for this that doesn't degrade performance, water should be treated as cosmetic backdrop to fights wherever necessary and any proposed enhancements to water physics should complement the rule-of-cool rather than chasing a detailed fluid simulation."

## The right stick (Orb, 2026-10-23, verbatim)

"I was also considering implementing the right stick, i wasn't sure whether to implement it as an attack, a mobility tool, or a hybrid based on which inputs are held (defensive, energy, etc.) ideally a hybrid approach would give more player agency; please pitch ways to implement this, include accounting for a quick flick versus steadily holding one direction; also consider different ways to integrate free-form movement patterns, like for instance in some modern skateboarding games the player's tricks are performed by doing zig zags and other patterns with the right stick. lets find some system to engineer into the combat so this becomes another method of commanding your fighter"

## Orb's homework answers of 2026-10-25 (verbatim)

**Early B (pop or send):** "find a balance between the two. I want moments where a fighter gets stunned, then sells some big powerful hits from the attacker, who then continues to bounce him around with elaborate flight attacks. if the knockbacks are varied and entertaining enough, there should be nothing stopping two players from knocking each other all around the planet.if it gets too repetetive, it will violete the rule of cool."

**Ragdoll:** out-of-plane joints: turn them on. The skid in the air: "close, but...". Each launch flailing its own way: can't tell. Weight: no difference I can see. The skid's lean: about right. Notes: "all of these look like they would look better if I saw them in game, more variety is better, follow rule of cool."

**Co-op campaign:** "episodic solo/co-op campaign. synthesize and engineer a hybrid approach of both A. The Planet Run (a route map, like a roguelite) and B. Episodes (an anime season you play) as the macro structure. I agree with your assessment to hold C for a later mode."
- Which pitch: "The Macro Structure (Episodic Arc): Campaigns are framed as a self-contained "Filler / Post-Season Arc" within the anime's ongoing broadcast. The Micro Structure (Planet Run Ring): Inside each Episode, players navigate a 5-stage planet tour using branching route maps."
- Split across stages: "Drop-in co-op works anywhere (character select, route maps, beat cards, or mid-brawl). No menu separation—players load onto the same planet ring and can physically sprint in opposite directions or converge in real time."
- Run length: "Pitch this, as far as we can push procedurally generated dynamic storylines thta remain interesting"
- A lost run: "Lets think of whether its fun, cool, balanced to trigger a flat restart. determine and engineer some nonel mechanic that encourages the player to start over if they lose rather than ending the run in frustration."

**Right stick:** "something about this whole system feels just slightly wrong, like theres a good idea bubbling under the surface. with more responsiveness in the release version I'm sure the stick will feel more responsive. but I'm thinking about how a player would be using the same thumb to control the right stick that they would be using to press attack buttons. if the stick is for encouraging attack slips, then the only players at an advantage are holding their controller in a "claw" or some unorthodox method. please help me brainstorm more ways of bringing this functionality into the current control scheme."
In chat the same day: "the right stick homework really made me think. I couldn't put into words how I felt about the control scheme; it doesn't feel right, but if we get it right it feels like we're onto something big. the right stick could potentially give the player fluid slips, strikes, dodges, you name it. the thing is that your thumb that is normally pressing attack buttons is occupied by the right stick. if there is too great a synergy between these two systems that are both occupying the right thumb, then my concern is that some kind of "claw grip" becomes necessary to compete. please tackle this problem and engineer a solution for my concerns."

**Character models (in chat):** "I'd also like to consult on the best method moving forward as far as character models. Would a Blender workflow suit our purposes, or can we more reliably generate character 3d models the way we've been doing? I want higher quality character models than what we've been using, but I also want responsive, latency-free gameplay."

**Campaign, filler (in chat, later the same day):** "just to clarify, filler episodes, filler arcs could be considered separate categories in the game, but not all missions will be filler episodes."

## The first four names (Orb, 2026-10-30)

Orb locked the canonical names from a naming session run through Gemini: **Grist** (Protagonist), **Loupe** (Rival), **Empress Orza** (Empress), **Bolus** (Cyborg). Orb: "I prefer Empress Orza, wherever necessary a fighter's titles should be exempt from the limit, the limit should serve as a guideline rather than a strict hard-stop." Legal cleared them as in-game names (RL-211): proper nouns only, no line plays on a name's meaning, and none may become a title or product name without a formal search. Supporting cast and place names are still being workshopped.

**Orb's rule on Gemini (same day):** Gemini is used for creative writing only. Its descriptions of gameplay, mechanics or systems are not Orb's sign-off unless Orb names the one they like. This applies retroactively.

## The beam struggle's look (Orb, 2026-10-30)

"ideally I'd like to see that solid white glowing flare replaced with visually distinctive procedural shaders, the air should look like its rippling and glowing with pressure and energy, dynamic distortions and color changes and patterns should erupt out based on the composition and power behind each of the beams of each fighter, composition should be determined by the fighter's energy fighting style, their current form, any other unique situations future fighters may possess or cause when we increase the roster"

## Right hand attacks: Orb's picks (2026-10-30)

1. **Pitch 4a:** stick strikes are their own class of moves, not the team's recommended 4c.
2. **Pillar 2's wording is reopened entirely.** Orb doesn't want to alienate players who like predetermined combos in mainstream fighting games, and does want to appeal to fans of platform brawlers and of generative, procedural content. Orb's own question, in Orb's words: "why don't fighting games take this approach to the combos that their fighters use during a match?", meaning the way procedural-universe games generate vast numbers of plants, animals and landscapes.
3. **"accessibility settings and customizable controls should be assumed, including left-handed folks who may want to swap their controller around".**

## The fight's bearing on the planet (Orb, 2026-10-30)

"with the intersection on the global region map changing throughout a fight the fighters should always be on the same relative band." Then: "push this idea to the limit, the angle the fighters fight along the surface of the planet should be ready to dynamically adjust and change determined by the fight choreographer and any other necessary game system. run a big research pass to determine a route to make this feasible."

**Orb's pick after trying the prototype (2026-10-31):** "I tried the prototype here and as far as I can tell the turntable approach in E and E2 seems to be closest to my vision. Lets work exclusively on this arena situation for now." So the world visibly swings round the fighters, rather than the fight heading somewhere new past the camera's edge.

**Orb after playing proto v2 (2026-10-31):** "I played with many tunings of the camera swing speed, the swing size, the zoom, and I felt pretty comfortable at every speed up to 240. of course it was a little too extreme when paired with the maximum swing angle size, but a swing speed of 240 could routinely be used for minimal swing adjustments without any disorientation. i set a small swing rate and a small swing size and just flew some circles around the planet for fun, you can see an irregular orbital pattern around the sphere on the minimap in the top left corner". (Their still shows 8 laps flown, on the 1024² map.)

**Orb, retrying with the sweep limit off (2026-10-31):** "the swings look fine, I tried them with the limit off"

**Orb's answers on proto v2 (2026-10-31):**

- On the swing and performance: "you're overthinking this whole 30fps deal, it looks great. lets focus on making granular performance settings so folks with laptops can enjoy the game, but even at 30 fps there was gameplay, there was camera motion, it looked fine. i tried the 170 planet map, lets find other ways to solve this without tying the entire game down to old laptops. research methods to effectively scale this from a performance mode all the way up to a maximum graphics version."
- On when it fires: "there should definitely be variety, the dynamic elements of the fight should all collectively be used to inform the combat choreographer and the camera control to decide the best time for the swing to occur."
- On what makes the planet feel crossed: "all of the above. I would like to mention that subtle flattening looks good at closer zoom levels, zooming out while subtly returning to 100% globe could give an illusion of extra scale to the fighter's speed and altitude, just something I noticed while playing with the sliders. the minimap with the trail showing the path around the planet was a nice detail and definitely helped with the sense of crossing the planet."

**Orb on flattening and near towers, after the swing test (2026-10-31):** "the flattening effect actually looks pretty weird, especially around buildings it looks very distorted from what I saw in that test. my personal preference would be a hybrid between Q and W, maybe a hybrid of W and E. keep the world 100% globe, unless we run another test with globe reduced to 95% at the closest zoom. the coarse mode looked fine". This withdraws their earlier flattening idea.

**Orb on zoom, power and the meteor launch, after the level selector (2026-10-31):** "i played around with a bunch of the settings, its looking impressive and its going the direction I imagined. the features are a little exaggerated in the screenshot but I was enjoying thinking about how a view like this could be part of the gameplay. at base levels of power in the beginning of the match, the camera would never zoom out this far, it would stay close in and follow the combat up close. when both players are fully powered up and their fighters are at their peak, giving it 100% with multiple transformations and powerups achieved, I could imagine a fully charged launch attack landing on a stunned or weakened foe that knocks them  diagonally up at high speed, the camera dynamically zooms out and the knocked back character leaves a burning trail through the atmosphere as they shoot skyward, even if the fighter is only a few pixels at this zoom level if there is a visual cue like a meteor-trail left behind it would be a stunning show of power". (Their still: view width 53,070, the planet's curve filling the frame, the bars a few pixels on the horizon.)

**Orb on the goal (same night):** "I'm eager to know if fighting across a full planet is achievable. the strict definition of flying a full 360 degree loop around the equator of the planet isn't the end-all goal, but to effectively communicate to the player the experience of speed and power that comes with being a martial artist who is capable of making such a trip through the sheer power of will."
