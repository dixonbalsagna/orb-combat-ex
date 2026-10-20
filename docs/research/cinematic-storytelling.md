# Cinematic storytelling: a camera director that is always spot on, even at high speed

Research & Prototyping, 2026-10-19, for Orb's request: "do a big research pass on effective cinematic storytelling techniques so the camera work is always spot on, even in high speed combat situations". Orb wants "a dynamic, directed, emergent cinematic storyteller that works with the combat choreographer so every camera movement feels purposeful and not distracting".

This is the reference Camera builds the camera director from. It distils five parallel research sweeps:
- film fight grammar;
- the anime action tradition;
- game camera systems;
- high-speed perception;
- emergent directing systems.

About 200 sources were read; the 73 cited are listed at the end and cited by number. Techniques are described by mechanism, with no franchise characters. **Bound by:**
- `docs/ep/taste.md` and ADR 0010: no dissolves, fades, slow wipes or full-screen blur, nothing over the fighters, and the look gate against the reference build;
- the flash register, with "Reduce flashing" on by default;
- the sim's determinism: the camera reads the sim and never writes it.

Numbers marked *(est.)* are our own estimates. Every other number is a source's.

## The short answer

The best fight cameras in film, animation and games share ten habits. Section 5 turns them into 19 testable rules and a shot vocabulary.

1. **Default to a steady, wide two-shot** with the attack and the reaction in one frame. Every closer shot is punctuation that returns to it [3, 11].
2. **Fights breathe:** a pause, a burst, a pause. The camera settles in the pauses and moves only on the bursts [3, 14, 25].
3. **Cut, or change framing hard, only at a motion onset or in a pause,** never while a move is travelling. Keep the subject where the eye already is [1, 6, 5].
4. **Keep screen direction sacred.** In our side-on wrapped world east is screen-right forever, which is a gift. The dangers are passes and the shortest-arc flip [16, 34].
5. **Know the exchange before it happens.** Film choreographs for the lens and previsualises. Our choreographer already knows every contact tick, so it should hand the camera its plan [12, 15, 38].
6. **Pace with an intensity curve, not dice.** Holds shorten into a climax and rest after it. Shot lengths vary in correlated runs [8, 9, 52].
7. **The eye tracks smoothly only up to about 30 degrees a second** (about 0.6 screen widths a second on a desk monitor). Our launches cross the screen several times faster. So the camera rides with the fast body, and the background carries the speed [57, 58, 66, 28].
8. **Anticipation is a gift to the eye.** A tell at least 100 ms before a fast move lets pursuit start on time [57, 59, 71].
9. **Hit-stop, freezes and slow motion make weight and intent.** They are scaled by blow weight and spent on story beats [68, 67].
10. **Variety comes from context and memory:** the most specific rule wins, recent shots are penalised, and a repeat is a deliberate callback. Never randomness [49, 51].

## 1. Film and animation grammar for fights

**Legibility comes from the frame, not the cutting rate.**
- **Cutting rates.** Modern action averages about 2 to 3 s per shot, and peak set pieces go under 1 s. Films cut faster than that can still read [1, 2].
- **What causes confusion** is cuts that interrupt camera moves before they settle, and framings that fail to contain the action. Bodies then "exist in an architectural vacuum" [1].
- **The "chaos cinema" critique.** It names the cluster of over-fast cutting, shaky framing and tight lenses that overwhelms the viewer [4]. Live-action fights often lean on those tools to hide doubles and wires. A game has nothing to hide, so it has no excuse.
- **The opposite school.** Classic Hong Kong action and one stunt-comedy tradition use steady, wide framings with action and reaction in one frame. They let the audience "feel the rhythm", and an expensive impact is shown twice ("two good hits make one great hit") [3, 11].

**Shot sizes have jobs** [17, 18]:

| Size | Job |
| :--- | :--- |
| Extreme wide | Geography and scale |
| Wide or full | Re-establishing at each phase of a fight |
| Cowboy or medium | Exchanges: body language and action together |
| Close-up | Anticipation faces and reactions |
| Insert | A single percussive impact [3] |

Long shots keep viewers oriented to the phases of a fight. After a run of close framings, a fight re-establishes wide [3, 14].

**The line and screen direction.**
- **The rule.** Keep the camera on one side of the axis between the subjects. Cross it only with a visible move, a neutral on-axis beat, a cutaway, or a subject seen crossing [16].
- **Eyelines.** A look or charge toward off-screen space promises that the next view reveals that space on the same side [7].
- **In our world**, a side-on camera never orbits across the fighters' plane, so the screen direction of travel never changes: east is right all the way round the planet. That is stronger than film's rule. The real risks are:
  - **passes**, where the two fighters' left-right order swaps. Keep both in frame through the pass and do not change the view during it, because the audience accepts a crossing it sees;
  - **the shortest-arc flip** at half the planet, which Camera's rig already guards with hysteresis;
  - **depth lanes**, where a fighter at depth must still sit on the side his x says.

**Anticipation, impact, follow-through.** Frame the anticipation wide enough to read the set-up. Land tight and still on contact for a few frames. Widen for the follow-through and the damage it causes [3, 71]. Bordwell's rule from a celebrated fight: "never cut before a punch or kick completes", and let the arc rest "if only for a couple of frames" [3].

**Cutting on action works because the eye is busy.**
- **Edit blindness.** Viewers miss about 25% of cuts within a scene, and about 33% when the cut coincides with a sudden onset of motion [6].
- **Why.** Continuity cuts (match on action, the 180-degree rule, eyelines) are ways of managing attention [7].
- **Eye-trace.** Murch's eye-trace criterion: end a shot with the viewer's attention where the next shot's action appears [5].
- **Recovery after a cut.** Eye positions begin to converge about 0.2 s after a cut and settle by 0.5 to 0.8 s. Re-finding the point of interest takes about 0.75 s on average [61]. The first looks after a cut go to whatever moves or stands out [62], so the subject should be the thing that moves.

**Murch's rule of six ranks what a cut must keep:** emotion (51%), story, rhythm, eye-trace, the 2D screen plane, then 3D space last [5]. Break geography for emotion, never the reverse.

**Rhythm and pacing.**
- **Pause, burst, pause.** Martial-arts staging alternates bursts of blows with near-freezes of a fraction of a second, often on a block. The stillness makes the bursts read faster and lets the motion "echo" in the viewer's body [3, 14]. Grappling has no pauses, so it needs an attack, defence and counter unit, with framing that shows every step [14].
- **Correlated shot lengths.** In successful films, a shot's length correlates with its neighbours': runs of short shots, then runs of long ones, approaching a 1/f pattern. Action films come closest [8].
- **The arc of a film.** Pace follows its phase: shots shorten and motion rises into a climax, then both relax [9].
- **Rest after a climax.** Story craft shortens scenes into a climax and lowers the intensity after it, so the audience can recover [10].

**Choreography and camera are designed together.**
- **The Hong Kong method.** Plan each attack as a phrase of about three movements in one shot, with a fourth movement bridging the cut into the next phrase. Choose angles with the choreographer, never as blanket coverage [12, 13].
- **Previs.** Modern fight teams shoot and cut a previs of every fight before the shoot, and the camera crew rehearses the moves [15].
- **For us.** The director layer is the choreographer, and it already holds the plan. The camera director should receive that plan when an exchange starts and shoot it like previs, not react frame by frame.

## 2. The anime energy-brawler tradition

These techniques come from fast, aerial, energy-heavy action animation, described here by mechanism.

- **Hold, then move the camera.**
  - Limited animation turned budget into style: hold the drawing, move the camera, the layers or the framing [21, 23].
  - Weight and suddenness come from changing the drawing rate inside one action. Holds on 3s or 4s, then the release on 1s; a giant on 3s and 4s, a small hero on 1s and 2s [20].
  - A hold with a push-in is the cheapest drama there is.
- **Ma, the meaningful pause.** Action with no breathing space is "busyness", and constant tension numbs [25].
  - One analysed fight timeline at 24 fps: a 5.5 s lead-up; an 18-frame (0.75 s) burst; strikes at about 8 frames each, 3 a second; reaction holds of 39 to 84 frames [26].
  - Stretch the lead-up and the aftermath, and compress the strike.
- **Speed lines go on the background, and the fighter stays sharp.** The anime convention moves the world past a sharp subject, so the viewer travels with him [29].
  - Streaks really do shape the brain's motion judgement ("speedlines" bias perceived direction) [66].
  - The tradition's sense of travel is lateral: layers sliding past at different rates, the view from a train's side window rather than its front [21, 22]. Our side-on camera is exactly that.
- **The velocity-matched chase.** A classic aerial-swarm shot puts the camera inside the action at the pursuer's speed, so the fast objects seem to hang while the world streams past [28]. A leading action animator describes camera work "attached to the movements", with pans that drag the frame along with the action [24].
- **Impact frames, smears and multiples.**
  - **Impact frames** are single stylised, often monochrome drawings at the moment of contact, lasting a fraction of a second [19]. For us they are flashes: allowed only small, on the bodies, through the register, and off under Reduce flashing.
  - **Smears** (a limb stretched along its path for 1 to 2 frames) and **multiples** carry speed cheaply. A burst of looping multiples can stand in for a flurry [27].
- **Whip pans** are motivated transitions: accelerate into the blur, keep it short, decelerate to a sharp landing, and match the direction to the motion. No expert source gave a duration; 4 to 8 frames at 24 fps is an estimate [30 (secondary)].
- **Launches, flights and arrivals** combine the above in three parts:
  1. a snap out of a held wind-up;
  2. a velocity-matched flight, the body large and steady while the background streams;
  3. an arrival impact, with chunky low-detail debris [20] and a short near-freeze.

  This is a synthesis, not one documented recipe [28, 29, 20].
- **Beam clashes.**
  - The meeting point is the subject: two beams push it back and forth, and it ends one of three ways. One beam overpowers and carries on, a fighter collapses from the strain, or the beams detonate at the junction [29].
  - Stage it with one main mover at a time [23]: alternate emphasis between the two strained faces and the junction.
- **Power-ups.** They are told through the environment:
  - the ground cracks in a ring wider than the feet;
  - chunks lift and orbit;
  - the aura grows;
  - a contracted pose is held, then released on one sharp beat [29].

  Long transformation sequences are reused, and shortened on later uses [29].
- **Angle carries mood.**
  - Low and high angles make a threat overwhelming. A canted (dutch) angle adds tension. A return to level framing signals that the danger has passed [31].
  - "Anime perspective" exaggerates near limbs beyond a real lens, and that can look more natural to viewers [30].
  - Above all, never break the space: a broken layout pulls viewers out more than a weak drawing does [31].
- **Two modes.** One 3D anime-style fighter limits its models to stepped, sprite-like timing in play, and lifts the limits inside cinematic supers [33]. The equivalent for us is a tight, readable camera in free play and a freer, choreographed camera inside set pieces.

## 3. Directed and procedural cameras in games

- **Three layers** [35]:
  - **Editing** decides which shot and when to cut.
  - **Placement** decides where the camera stands for that shot.
  - **Motion** decides how it gets there.

  Most research solves one layer. A game needs all three, plus occlusion handling. Our rig already has placement and motion: the lag bound, panes, springs and lead. The missing piece is an editing layer that reads intent.
- **Idioms.**
  - The classic real-time cinematographer is a hierarchy of small state machines ("idioms"), one per situation. Their states are shots, their transitions are cuts, and exception paths let urgent events end a shot early. They sit on shared camera modules that place the camera [34].
  - A cut must clearly change the shot size or the angle (about 30 degrees or more); otherwise it is a jump cut [34, 36].
  - Intent-driven planners go further: they keep coherence across a sequence of shots, not just neighbouring ones, and they record why each shot was chosen [38].
- **Pacing as a cost.**
  - An edit can be scored as shot quality plus cut cost plus rhythm cost, with shot lengths drawn from a log-normal around a target average shot length [36].
  - Changing that target average gives fast or slow styles from the same footage.
- **Coherence beats perfection.**
  - A camera that satisfies its framing goals perfectly every frame jitters, so trade constraint satisfaction against frame coherence on purpose [39].
  - Frame in screen space (where each subject sits, how big it appears); interpolation then never drops a subject [37].
- **Side-scroller craft** [40]:
  - camera windows and dead zones;
  - lead room about 25% of the width ahead of travel, switching sides only past a threshold (hysteresis);
  - snapping vertically only on landing;
  - critically damped springs with a half-life: frame-rate independent, never overshooting, and their lag can be cancelled with lead [42].
- **Fighting games.**
  - A super's freeze stops both fighters and buffers both players' inputs. Fairness depends on the startup frames left after the freeze [45].
  - Long cinematic finishers play only after a confirming hit, with a non-cinematic version of similar value [47].
  - Close-up "special" and "finish" zooms are gated per move or by a predicted decisive outcome. They are suppressed in the last seconds and whenever they would hide a threat [46].
- **Pacing directors.** A shipped co-op shooter's AI director tracks each player's stress and cycles build-up, sustained peak, peak fade and relax, holding back new threats while players relax [52]. Drama managers in interactive stories pick the next authored beat to follow an intended tension arc [53, 54]. Our pacing machine (5.1) borrows the first idea; the intent event borrows the second.
- **Broadcast and observer directors.**
  - An automatic observer that switches to whatever its detector finds most interesting switches too often and too abruptly. A two-level design does better: a scorer proposes and a committing tracker follows. It wins on stability and viewer preference [48].
  - A working replay director scores subjects by event weight plus a decaying freshness bonus, minus a variety and overexposure penalty with a floor. It enforces minimum and maximum shot times and cuts ahead of predicted events [49].
  - Engines ship the plumbing: animation-state-driven cameras with a wait (skip short states) and a minimum hold, quality-scored shot choice, and impulse signals [50].
- **How cameras lose the player** [41, 44]:
  - disorientation from cuts that break direction or remap controls;
  - broken line of sight;
  - fast reorientation;
  - lag and overshoot;
  - simulation sickness.

  The fixes are rules: keep direction, see the subject, hand control back in the gameplay framing. One major action game went to the extreme of a single continuous camera with no cuts between play and story [56].
- **Comfort.**
  - Model shake as a decaying "trauma" value from 0 to 1, with shake = trauma squared, through smooth noise and with caps [43].
  - Xbox Accessibility Guideline 117 asks that shake, bob, blur and automatic camera moves can be turned off [55]. WCAG 2.3.3 asks the same of motion triggered by interaction [70].
  - Visually induced motion sickness peaks for slow oscillation at 0.2 to 0.4 Hz [69]. Zoom "breathing" belongs exactly there, so avoid it.

## 4. High speed

**What the eye can do.**
- **Latency.** Smooth pursuit starts about 100 ms after motion begins, and its first 100 ms run blind on the initial motion [57].
- **Gain.** It stays near one-to-one only at moderate speeds. Above about 30 degrees a second, catch-up saccades become the rule, and vision is briefly suppressed at each [57, 72].
- **The ceiling** is about 90 to 100 degrees a second, and only for predictable motion [57, 72].
- **The saccade trigger.** The eye stays smooth while its predicted crossing time with the target is 40 to 180 ms. A sudden jump in speed pushes it outside that window, and a saccade fires about 125 ms later [58].
- **Prediction.** Pursuit anticipates: cues and recent motion let the eye start before the target [59].
- **Occlusion.** A tracked target that vanishes briefly is followed at about 70% of its speed [60].

**On our screens** (geometry from viewing distances [73]):

| Screen | Horizontal angle | 30 deg/s comfort | 100 deg/s ceiling |
| :--- | :--- | :--- | :--- |
| Desk monitor at 60 cm | about 50 degrees | **about 0.6 widths/s** | about 1.9 widths/s |
| TV | 30 to 40 degrees | about 0.75 to 1.0 widths/s | about 2.5 to 3.3 widths/s |
| Phone | 22 to 25 degrees | about 1.2 widths/s | about 4 widths/s |

**Our launches exceed all of these.** A launched body that goes from 7 to 144 units a tick scrolls 0.074 of the width a tick at the zoom it starts at (`docs/camera/whip-pan.md`). That is **4.4 widths a second, about 230 degrees a second on a desk monitor: more than twice the pursuit ceiling.** So:
- the camera must ride with the body, keeping it nearly still on screen;
- the sense of speed must come from the background, parallax and streaks;
- a body that does move across the screen must be telegraphed and must ramp.

**When the camera locks onto a fighter, he looks slower than he is.** A pursued object reads slower (Aubert-Fleischl), so speed must be sold by the background [66].

**Sample-and-hold displays smear whatever the eye tracks** by about 1 px per ms of frame time per 1,000 px/s [64]. At 60 fps a body crossing at 3,600 px/s smears about 60 px. Frame rate keeps improving perceived smoothness far past where it stops helping performance [65], so 60 fps is the floor.

**Background panning.** Film's judder rule is at most one frame width in 7 s at 24 fps [63]. At equal steps per frame that becomes about 2.8 s a width (0.36 widths/s) at 60 fps *(est.)*. The middle band, between that and a full whip with streaks, judders worst. So a static background either scrolls gently or streaks.

**Easing helps the eye.** Timing principles say:
- no in-betweens reads as a huge force;
- a few read as a heavy blow;
- many read as thought [32, 71].

A launch should therefore:
1. snap out of the impact;
2. ease its flight so the eye can lock on;
3. hold briefly at the apex or the arrival;
4. return firmly to full speed.

Slow motion should be brief and snap back [68]. It also changes meaning: viewers judge a slowed action as more intended (in one study, "intended to kill" rose from 77% to 86%), so slow motion belongs to decisive blows [67].

**Hit-stop values** [68]:
- Published values cluster around 6 to 15 frames at 60 fps (100 to 250 ms), growing with damage or attack level, with a cap of 20 to 30 frames. One platform fighter uses about 12 frames at 10% damage and 19 at 20%, capped at 30.
- The good practices:
  - both bodies freeze for the same time;
  - the struck body shakes more than the attacker, horizontally on the ground and vertically in the air, with the shake decaying and scaled to camera distance;
  - there is a final-blow "big moment" stop.
- Ours today: 0.06 to 0.35 s of sim-owned hit-stop. Camera's blow push is held for the stop, at most 12 ticks (`docs/camera/feel.md`).

## 5. Applying it to us: the camera director

### 5.1 The shape of it

| Layer | Owner | What it does |
| :--- | :--- | :--- |
| **Intent** | Encounter, with Simulation for the event fields | At each exchange start, publishes the plan as one `cam_intent` event: beats with their contact ticks, each beat's kind and weight, pause points, do-not-cut spans (grapples, multi-hit strings), the launch vector and predicted landing, set-piece flags, and a **story weight** (first blood, reversal, crippling moment, comeback, decisive, finisher) |
| **Pacing** | Camera, with Game Design's targets | A four-state machine (relax, build, peak, fade) driven by the sim's mood band and act (they exist) and by exchange density, with minimum dwell times and hysteresis. Each state sets the target hold lengths, the shot palette and the strength of pushes |
| **Editing** | Camera | Idioms (small state machines, one per exchange template and per set piece) pick shots from the vocabulary below. A scorer adds story weight and freshness and subtracts variety and overexposure penalties. A committing tracker holds each shot for its minimum time unless a higher-weight beat pre-empts it |
| **Placement and motion** | Camera (largely built) | The existing rig: the lag bound (soft 0.06, hard 0.20 of the width), panes and split, springs, lead (up to 0.12 of the width), the blow push, the launch chase |

All of it is render-side and stepped on the fixed tick, so a replay reproduces the camera exactly. It never writes the sim.

### 5.2 Shot vocabulary

| Shot | Framing | Trigger (intent) | Length | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Two-shot** (default) | Both full-body; action and reaction in one frame | None: the anchor | Any | Everything returns here within 1.5 s |
| **Lead two-shot** | As above, room ahead of shared travel | Pair moving together | While moving | Built (feel step 4) |
| **Exchange medium** | Cowboy framing on the pair | A planned exchange in build or peak | ≤ 1.5 s per hold | Changes only on a bridging beat between phrases |
| **Impact push** | +0.8 to 2% toward the contact | A landed blow by weight | The hit-stop | Built (feel step 2) |
| **Chase** | The launched body near a fixed anchor, lead room ahead | `launch` | The flight | Background carries the speed |
| **Arrival hold** | Wide enough to see the damage | Landing, `building_hit`, `lodge` | 0.3 to 0.6 s *(est.)* | Then re-establish |
| **Building smash** | A low wide on the facade | First link of a chain into a tower | The sim's 0.35 s hold | Built |
| **Beam two-shot** | Square to the beams, the junction centred | `game.clash` | The clash | Pushes as the junction moves; a close-up on the final pulse; one resolution shot per ending |
| **Power-up low angle** | Low, slight cant, the ground ring in frame | Charge to a tier, gather | The gather | Full version first, then short |
| **Transformation** | Face, then body, then a wide reveal | `cinematic_start` | The sim's `dur` | Built; full first, then short |
| **Crippling close-up** | The broken region's fighter | `limb_break` | 0.7 s | Built |
| **Finisher** | Wind-up close, a low push on contact, the aftermath wide | `finisher_start` | The sim's `dur` | Built |
| **Re-establish** | Extreme wide: the planet, the city, the scars | After a set piece, or on a phase change | 1 to 2 s *(est.)* | The rest beat |
| **Pane shot** | One fighter per pane | The split | | Built |
| **Cut-in panel** | An inset on a decisive beat | Story weight high | Short | Built; at most 6 a minute, 6 s cooldown |
| **Whip transition** | Accelerate, blur, land sharply, direction matched | Only when motivated by a launch or a flight | 4 to 8 frames *(est.)* | Never a dissolve |
| **Orbital** | The curved planet, the fighters as lights | Exosphere phase | The phase | Planned (`docs/camera/exosphere.md`) |

### 5.3 The variety rule

1. **No two consecutive expensive shots of the same type** (cut-ins, close-ups, the beam close-up, whips), unless the beat continues the last one.
2. **A cooldown per type:**
   - the same cut-in type at least 20 s apart *(est.)*;
   - the same angle family (low, high, canted) at most twice a minute;
   - cut-ins keep their budget of 6 a minute.
3. **The score subtracts an overexposure penalty** for recent use, with a floor so that a high-weight beat can still be shown. It adds a freshness bonus that decays over about 20 s [49].
4. **Context picks the variant.** Biome, altitude, stance pair, tier, template and beat role select the shot's variant, and the most specific rule wins [51].
5. **A repeat is allowed only as a callback**, on decisive beats: the same angle as an earlier turning point.
6. **No unseeded randomness.** Ties break on the render's seeded stream, so replays and side-by-sides match.

### 5.4 Nineteen recommendations

| # | Recommendation | Owner | Test |
| :--- | :--- | :--- | :--- |
| 1 | **Publish the exchange plan.** One `cam_intent` event at exchange start with contact ticks, kinds, weights, pauses, do-not-cut spans, the launch vector, the predicted landing and the story weight | Encounter, Simulation | In 100 AI matches, every strike and launch has its intent at least 8 ticks before contact |
| 2 | **The two-shot is home.** Both fighters full-body, action and reaction in one frame. Every tighter shot returns within 1.5 s outside set pieces | Camera | Time at the default at least 60% *(est.)*; no tight hold over 1.5 s outside set pieces |
| 3 | **Pause, burst, pause.** Settle during hit-stop and exchange pauses; never reframe mid-burst | Camera, Encounter (pause points) | Camera acceleration during bursts under a cap; at least 90% of reframes start in a pause or on a motion onset |
| 4 | **Cut only on a motion onset or in a pause, never mid-move.** Keep the subject where the eye is: same screen position, or the centre | Camera | In the cut log, 100% of cuts at an onset or pause; post-cut subject shift under 0.15 of the width or inside the central 30% |
| 5 | **Screen direction law.** East is right, always. A pass keeps both in frame with no cut. An off-screen charge reveals space on the side faced. No cut ever mirrors the pair | Camera | Seam and split sweeps plus a new no-mirror assertion; both fighters in frame on 100% of pass frames |
| 6 | **Pacing machine.** Relax, build, peak, fade, driven by mood band, act and exchange density, with dwell times and hysteresis. Holds from a log-normal around each state's target; consecutive holds correlated | Camera, Game Design (targets), Encounter (signals) | Per-state hold histograms on target; lag-1 correlation of hold lengths above 0.3 *(est.)* |
| 7 | **The variety rule (5.3)** | Camera | No forbidden repeat in 100 matches; per-type shares inside bands |
| 8 | **Launch in three parts:** snap with hit-stop, a velocity-matched chase with the background carrying the speed, an arrival hold | Camera, VFX | Launched body's screen speed at or under 0.6 widths/s on at least 80% of flight frames *(est.)*; never outside the picture (existing metric) |
| 9 | **Ease launch and approach speeds in the sim:** no one-tick jump to full speed (ramp over 4 to 6 ticks *(est.)*); a short apex or arrival ease on big launches; the AI's free-flight approach capped near the whip limit unless the camera rides with it. Behind a switch, since goldens move | Simulation, Game Design, Encounter | Largest per-tick speed change of a tracked body; screen-speed metrics before and after |
| 10 | **A hit-stop table by weight and story.** Light 4 to 6 ticks, medium 7 to 9, heavy 10 to 13, launch or close 14 to 18, decisive up to 24 to 30 cap *(est., from [68])*. Both bodies freeze; the struck body shakes more | Game Design, Simulation, Animation | The `stop` field per class matches the table; total stop time a minute inside Game Design's band |
| 11 | **Anticipation before speed.** Every fast move gets a readable tell at least 100 ms ahead: pose and sound. The camera's lead starts at the tell | Animation, Audio, Encounter, Camera | From intent to motion onset at least 6 ticks for rushes and launches |
| 12 | **Background carries speed, fighters stay sharp.** Speed lines and parallax on the background and debris, never over a fighter. Smears on limbs for 1 to 2 frames only | VFX, Animation | ADR 0010 side-by-side; web frame cost (Performance) |
| 13 | **The beam idiom.** The junction is the subject: square framing, pushes as `Clash.mid` moves, a close-up on the final pulse, and one resolution shot for each of the three endings | Camera, VFX, Encounter (ending cues) | Junction inside the central 40% of the width through the clash; the right resolution shot per ending |
| 14 | **The power-up idiom.** A low angle and a long hold, with the environment telling it (ground ring, lifting debris, aura), released on one sharp beat. Full first, short after | Camera, VFX, Animation | Later uses at least 50% shorter; the ring and the debris in frame |
| 15 | **Angle as mood.** Cant and vertical angle follow menace, anguish and act, limited to about 5 to 8 degrees of cant *(est.)*, levelled on resolution | Camera, Game Design | Cant correlates with menace; level within 1 s of a KO or resolution |
| 16 | **Spend by story weight.** Cut-ins, close-ups, slow motion and repeats go to high-weight beats | Camera, Encounter | At least 80% of expensive shots on high-weight beats |
| 17 | **Two good hits** (later): inside a sim-owned decisive pause, replay the last 0.3 to 0.5 s of the blow from a second angle, from a render-side history buffer | Camera, Rendering, Game Design | Only on decisive beats; at most one a minute |
| 18 | **Comfort.** Shake as trauma squared with the player's slider; no sustained zoom or position oscillation at 0.1 to 0.5 Hz; a reduced-motion version of every shot; impact frames only through the flash register | Camera, Accessibility | Zoom reversals a minute under a cap (`clip_digest` SMOOTH already counts them); a spectral check of zoom and position |
| 19 | **Measure purpose.** Seeded clip sets. `clip_digest` metrics plus the new ones above. One-rule-off side-by-sides judged against the reference build | Camera, QA, Tools | A dashboard per build; Orb's and the EP's ratings recorded per side-by-side |

### 5.5 Order and risks

**Order.** Each step is a camera change with a side-by-side against the reference build.
1. 1 and 4: the intent event, and cutting only at onsets or pauses. They make everything else possible.
2. 2, 3 and 8: home, breathing, and launches.
3. 6 and 7: pacing and variety.
4. 13 and 14: the beam and power-up idioms.
5. 9 and 10: the sim's speeds and the hit-stop table. They move goldens, so they sit behind switches.
6. 15 to 17: mood, story weight and the repeat.

**Risks.**
- **A director that is too clever reads as distracting.** The default two-shot must win most of the time. Rule 2's share is the guard.
- **Event latency.** If the intent arrives late, the camera reacts instead of anticipating. Rule 1's 8-tick lead is the test.
- **Sim speed changes** alter feel and balance, so Game Design must rule on them.
- **The flash budget** with more cuts and impact frames. The register and Tools' clips gate it.
- **Phones.** A small screen tolerates faster motion in widths per second, but a small fighter reads worse. The pane floor already guards this.

## Sources

Read on 2026-10-19. Sources marked (unverified) did not load during the sweep and rest on abstracts or secondary summaries.

1. D. Bordwell, "Unsteadicam chronicles" (2007). https://www.davidbordwell.net/blog/2007/08/17/unsteadicam-chronicles/
2. D. Bordwell, "Intensified continuity revisited" (2007). https://www.davidbordwell.net/blog/2007/05/27/intensified-continuity-revisited/
3. D. Bordwell, "A glance at blows" (2008). https://www.davidbordwell.net/blog/2008/12/28/a-glance-at-blows/
4. M. Stork, "Chaos Cinema" part 1 (2011). https://scalar.usc.edu/works/film-studies-in-motion/chaos-cinema-part-1-by-matthias-stork
5. No Film School, "6 'Rules' for Good Cutting According to Walter Murch" (2016). https://nofilmschool.com/2016/11/6-rules-good-cutting-according-oscar-winning-editor-walter-murch
6. T. J. Smith, J. M. Henderson, "Edit Blindness", Journal of Eye Movement Research (2008). https://bop.unibe.ch/JEMR/article/view/2264
7. T. J. Smith, "The Attentional Theory of Cinematic Continuity", Projections 6(1) (2012). https://ualresearchonline.arts.ac.uk/id/eprint/21187/
8. J. Cutting, J. DeLong, C. Nothelfer, Psychological Science (2010), reported by ScienceDaily. https://www.sciencedaily.com/releases/2010/02/100223121435.htm
9. Psychonomic Society, "Gone with the Rosebud" (2016), on J. Cutting's study of pace. https://featuredcontent.psychonomic.org/gone-with-the-rosebud-what-movies-are-really-like/
10. R. McKee, *Story* (1997), on rhythm and tempo.
11. No Film School on T. Zhou's video essay, "Jackie Chan's 9 Principles of Action Comedy" (2014). https://nofilmschool.com/2014/12/jackie-chans-9-principles-action-comedy
12. No Film School, "Tarantino Breaks Down Hong Kong vs. American Fight Scene Styles". https://nofilmschool.com/tarantino-explains-hong-kong-way
13. E. Jacobus, "Ed Kahana on the 'Hong Kong way' of action" (2011). https://ericjacobus.com/2011/11/30/ed-kahana-on-the-hong-kong-way-of-action-versus-the-korean-way/
14. K. Barrowman, "Action Aesthetics: Realism and Martial Arts Cinema, Part 2", Offscreen (2014). https://offscreen.com/view/action-aesthetics-pt2
15. Motion Picture Association, fight coordinator J. Eusebio interview (2024). https://www.motionpictures.org/2024/07/the-fall-guy-fight-coordinator-jonathan-eusebio-on-that-insane-spinning-garbage-truck-chase/
16. StudioBinder, "What is the 180 Degree Rule". https://www.studiobinder.com/blog/what-is-the-180-degree-rule/
17. StudioBinder, "Types of Camera Shots and Sizes". https://www.studiobinder.com/blog/types-of-camera-shots-sizes-in-film/
18. S. Katz, *Film Directing Shot by Shot* (1991).
19. Sakuga Blog, glossary: "Impact Frames". https://blog.sakugabooru.com/glossary/impact-frames/
20. Animetudes (M. Watzky), "The Kanada style in context" (2021) and "The Kanada style now" (2021). https://animetudes.com/2021/03/06/the-kanada-style-in-context/
21. Animetudes, "On animetism" (2020). https://animetudes.com/2020/04/08/on-animetism-or-the-importance-of-sakuga-to-theory/
22. T. Lamarre, *The Anime Machine* (2009); review in Mechademia (2012). https://www.mechademia.net/2012/08/22/book-review-the-anime-machine/
23. Wave Motion Cannon, "Animation Principles: Staging" (2017). https://wavemotioncannon.com/2017/05/27/animation-principles-staging/
24. Interview with action animator Y. Nakamura (2003, translated 2016). https://wavemotioncannon.com/2016/11/02/interview-yutaka-nakamura-web-anime-style-7192003-part-2/
25. Final Draft, "Hayao Miyazaki says ma is an essential storytelling tool". https://www.finaldraft.com/blog/hayao-miyazaki-says-ma-is-an-essential-storytelling-tool
26. T. Maloney, "Timing Example #1 – Anime", Naked Rabbit (2009). https://www.nakedrabbit.com/timing-example-1-anime/
27. "Smear frame" (Wikipedia); C. Avender, history of smear terminology, Cartoon Research (2025); "Whip pan" (Wikipedia). https://en.wikipedia.org/wiki/Smear_frame
28. J. Clements, "Entering the Itano Circus" (2010), on the velocity-matched aerial-swarm shot. https://www.goodreads.com/author_blog_posts/773828-entering-the-itano-circus
29. All The Tropes: "Beam-O-War", "Chunky Updraft", "Battle Aura", "Transformation Sequence", "Speed Stripes" (genre conventions). https://allthetropes.org/wiki/Beam-O-War
30. Y. Katsura, K. Anjyo, "Anime perspective", SIGGRAPH 2007 sketch. https://history.siggraph.org/?p=141604
31. Sakuga Blog, "The Layout Crisis" (2022), and production notes on angle and mood (2019). https://blog.sakugabooru.com/2022/08/05/the-layout-crisis-the-collapse-of-animes-traditional-immersion-and-the-attempts-to-build-it-back/
32. R. Williams, *The Animator's Survival Kit* (2001).
33. Kotaku (M. Fahey), on stepped animation in a 3D anime-style fighter (2014). https://kotaku.com/the-new-guilty-gear-is-breathtaking-at-60-frames-per-se-1669244644
34. L. He, M. Cohen, D. Salesin, "The Virtual Cinematographer", SIGGRAPH (1996). https://www.microsoft.com/en-us/research/?p=150986
35. M. Christie, P. Olivier, J.-M. Normand, "Camera Control in Computer Graphics", CGF 27(8) (2008). https://people.irisa.fr/Marc.Christie/Publications/2008/CON08.html
36. Q. Galvane, R. Ronfard, C. Lino, M. Christie, "Continuity Editing for 3D Animation", AAAI (2015). https://ojs.aaai.org/index.php/AAAI/article/view/9288
37. C. Lino, M. Christie, "Intuitive and efficient camera control with the toric space", ACM TOG 34(4) (2015). https://doi.org/10.1145/2766965
38. A. Jhala, R. M. Young, "A Discourse Planning Approach to Cinematic Camera Control", AAAI (2005). https://mlanthology.org/aaai/2005/jhala2005aaai-discourse
39. N. Halper, R. Helbing, T. Strothotte, "A Camera Engine for Computer Games", CGF (2001) (unverified). https://diglib.eg.org/handle/10.2312/8862
40. I. Keren, "Scroll Back: The Theory and Practice of Cameras in Side-Scrollers" (2015). https://www.gamedeveloper.com/design/scroll-back-the-theory-and-practice-of-cameras-in-side-scrollers
41. J. Nesky, "50 Camera Mistakes", GDC 2014. https://gdcvault.com/play/1021262/50-Camera
42. D. Holden, "Spring-It-On: The Game Developer's Spring-Roll-Call" (2021). https://theorangeduck.com/page/spring-roll-call
43. S. Eiserloh, "Juicing Your Cameras With Math", GDC 2016. https://www.gdcvault.com/play/1023557/Math-for-Game-Programmers-Juicing
44. M. Haigh-Hutchinson, *Real-Time Cameras* (2009).
45. Dustloop wiki, frame-data esoterica on super freezes and hitstop. https://dustloop.com/w/GGST/Esoterica
46. SmashWiki, "Finish Zoom" and "Hitlag". https://www.ssbwiki.com/Finish_Zoom
47. EventHubs, on supers that play without their cinematic (2023). https://eventhubs.com/news/2023/jun/09/sf6-critical-arts-no-camera
48. H.-T. Joo et al., hierarchical scene detection and tracking for esports viewing, Scientific Reports (2025). https://scholar.gist.ac.kr/handle/local/8995
49. iRacingReplayDirector, an open-source replay director (GitHub). https://github.com/rockavoldy/iRacingReplayDirector
50. Unity Cinemachine documentation: State-Driven Camera, ClearShot, Impulse. https://docs.unity3d.com/Packages/com.unity.cinemachine@3.1/manual/CinemachineStateDrivenCamera.html
51. E. Ruskin, "AI-driven Dynamic Dialog through Fuzzy Pattern Matching", GDC 2012. https://www.gdcvault.com/play/1015528/AI-driven-Dynamic-Dialog-through
52. M. Booth, "The AI Systems of Left 4 Dead", AIIDE 2009 keynote (the adaptive pacing director). https://cdn.fastly.steamstatic.com/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf
53. M. Mateas, A. Stern, "Structuring Content in the Façade Interactive Drama Architecture", AIIDE (2005). https://cdn.aaai.org/AIIDE/2005/AIIDE05-016.pdf
54. M. Riedl, V. Bulitko, "Interactive Narrative: An Intelligent Systems Approach", AI Magazine 34(1) (2013). http://ojs.aaai.org/aimagazine/index.php/aimagazine/article/view/2449
55. Microsoft, Xbox Accessibility Guideline 117. https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117
56. GameAnim, summary of D. Arazi's GDC 2019 talk on a no-cut camera (2021). https://www.gameanim.com/2021/08/17/creating-a-deeper-emotional-connection-the-cinematography-of-god-of-war/
57. S. G. Lisberger, "Visual guidance of smooth-pursuit eye movements" (2010). https://pmc.ncbi.nlm.nih.gov/articles/PMC2887486
58. S. de Brouwer et al., "What triggers catch-up saccades during visual tracking?", J Neurophysiol 87 (2002). https://research.dial.uclouvain.be/handle/2078.5/239245
59. E. Kowler et al., "Predictive Smooth Pursuit Eye Movements", Annual Review of Vision Science 5 (2019). https://researchwith.njit.edu/en/publications/predictive-smooth-pursuit-eye-movements/
60. A. Montagnini, L. Perrinet, G. Masson, "Visual motion processing and human tracking behavior" (2015). https://ar5iv.labs.arxiv.org/html/1611.07831
61. H. X. Wang, J. Freeman, E. Merriam, U. Hasson, D. Heeger, "Temporal eye movement strategies during naturalistic viewing", J Vision 12(1) (2012). https://pmc.ncbi.nlm.nih.gov/articles/PMC3273487
62. R. Carmi, L. Itti, "The Role of Memory in Guiding Attention during Natural Vision", J Vision 6(9) (2006). https://ilab.usc.edu/publications/Carmi_Itti06jov.html
63. RED Digital Cinema, "Camera Panning Speed". https://www.reddigitalcinema.com/red-101/camera-panning-speed
64. Blur Busters, "Blur Busters Law" (TestUFO). https://testufo.com/blurbusterslaw
65. S. Tokey et al., frame rate benefits up to 500 Hz (2025). https://web.cs.wpi.edu/~claypool/papers/fps-500-25/
66. D. Burr, J. Ross, "Direct evidence that 'speedlines' influence motion mechanisms", J Neurosci 22 (2002). https://data.cnr.it/data/http:/www.cnr.it/ontology/cnr/individuo/prodotto/ID37408
67. E. Caruso, Z. Burns, B. Converse, "Slow motion increases perceived intent", PNAS 113 (2016). https://pmc.ncbi.nlm.nih.gov/articles/PMC4995977
68. M. Sakurai on hitstop: Famitsu column vol. 490 (fan translation, 2015) and a 2022 summary of his eight hit-stop techniques. https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/ and https://nintendowire.com/news/2022/12/12/this-week-in-sakurai-12-5-12-11-fine-tuning-hit-stop-and-cheating-the-camera/
69. C. Diels, P. Howarth, "Frequency Characteristics of Visually Induced Motion Sickness", Human Factors 55(3) (2013). https://pureportal.coventry.ac.uk/en/publications/frequency-characteristics-of-visually-induced-motion-sickness
70. W3C, "Understanding SC 2.3.3: Animation from Interactions". https://www.w3.org/WAI/WCAG21/Understanding/animation-from-interactions
71. J. Lasseter, "Principles of Traditional Animation Applied to 3D Computer Animation" (1987), SIGGRAPH HyperGraph summaries (timing, anticipation). https://education.siggraph.org/static/HyperGraph/animation/character_animation/principles/timing.htm
72. "Smooth pursuit" (Wikipedia), for the 30 degrees per second figure (secondary). https://en.wikipedia.org/wiki/Smooth_pursuit
73. OSHA, "Computer Workstations eTool: Monitors" (viewing distance). https://www.osha.gov/etools/computer-workstations/components/monitors
