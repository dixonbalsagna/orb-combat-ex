# Shooting extreme velocity: launches and high-stakes moments

Owner: Camera & Cinematography, 2026-11-01, on Orb's ask: "an intensive research into cinematography techniques to portray the launches correctly, keep refining our camera director so any high stakes, high velocity situation is handled smoothly". Part 1 is the techniques, part 2 the shot list. Part 3, the build, is in `docs/camera/launch-director.md`.

**How far to trust this.** Two passes of searching, with sources at the end. Each row marks where it comes from: *sourced* means a named practitioner or trade source says it, *weak* means a general guide or a still-photography source, and *craft* means standard practice as I know it, not checked. **The gaps are real:** I found no operator's own account of following a launch beat by beat, no cinematographer's first-hand account of shooting fast jets, and little on sports lead room at speed. Two sources for chase work disagree on lens. The rig columns come from our code and readings. **Nobody has judged any of this on a real launch except where a clip is named.**

## The findings that change what we build

1. **Speed is read from what's around the subject, not the subject.** Motorsport photographers say so plainly: the surroundings carry the speed, and a frozen frame kills it. So a launch at a fixed screen place needs something passing behind him. Over sky there's nothing, so he reads as still.
2. **Rocket coverage is our meteor.** The one concrete account has a camera opening wide as the vehicle lifts, then following it to a pin-prick. The camera doesn't race it, and it accepts the subject getting tiny. That's our peak shot, and it's in the real world's vocabulary.
3. **The cut belongs where the exit is inevitable, not after it.** An editor's rule: cut when it's certain the subject will leave, not when he has. That's a better trigger than our "out of frame", and our sim knows the send on its first tick.
4. **A heavy follow loses a fast subject for good.** Game-camera practice: damping that feels good at walking pace never catches up with an accelerating target, so damping has to fall as speed rises. Look-ahead shouldn't snap to zero when the target stops, either. Our `MASS_*` and lead logic should be read against both.
5. **A single unbroken shot can replace many cuts, if it can keep pace.** Live winter-sports coverage now uses one chase drone in place of dozens of cuts on a sliding track, matched to the athlete's pace: its pilots say the failure is outrunning them or missing the moment. A wide hover shot gives context, and the chase gives immersion. That's our two shots: width, and the ride.
6. **Ski jump coverage is a launch.** The drone follows down the in-run and into take-off, then pulls away in flight to show the body's shape. Ride, release, pull wide. That's our launch shot in real broadcast.
7. **Passing a still camera makes the subject faster.** A working cinematographer's list says so outright, and that a pan on a long lens drops parallax, so the background moves only as fast as the pan. So stillness is a speed tool, not only a flash fallback, and our far land in a swing is that long-lens pan.
8. **A talk on game camera mistakes names what we've measured:** ease a response to a sudden event, decelerate into a limit rather than hold speed until it stops, keep fast repositioning as a cut rather than a rush, don't change the field of view quickly, rank rules that push the camera by what they control, let the player's input win, and always offer shake off. It also says that in the air players want to see where they'll land.
9. **The eye has limits we've already measured:** it tracks to about 0.6 widths a second, with a ceiling near 1.9 (`director.md` section 5). Median launches run at 8.9 widths a second at fight size. **So most launches can't be followed by the eye at fight size at all,** and only three things help: go wider, let him leave, or let him come back.

## Part 1: the techniques

**Flash, for now (the EP, on Orb's word, 2026-11-01):** the backburner, and Tools is testing whether the numbers are above their margin of error. So the flash column is a note for a **public check later,** and it doesn't veto a technique for private work. What we read so far: moving hard tone edges close to the lens are what count, not rate (`swing-view.md` section 8). **Motion** is the motion setting (`world_turning`, Reduced motion): a plain cut or a still, no roll, no tilt.

### Framing the flier

| Technique | What it does | When | What it needs from our rig | Flash | Motion setting |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Lead room** (*sports guides; craft*): more frame ahead than behind, about a third behind him | The eye can see where he's going, and the frame looks balanced at speed | Every follow. Most when he's fast and readable | Exists: `LAUNCH_TRAIL` 0.35. Pane leads exist. **Missing: it doesn't ease with speed on a launch's first ticks** | Neutral | Keep: it isn't a move |
| **Trailing room, the opposite** (*craft*): more frame behind him | He's fleeing or being left behind, and what he left is the story | A body sent away from the launcher, when the launcher or the crater matters | New: a sign on the lead. Cheap | Neutral | Keep |
| **Riding him, a fixed screen place** (*sourced: winter-sports chase pilots match pace; a game camera talk keeps the character centred while running*) | He's still and the world pours past. Reads as speed only if something's passing | Launches the follow can match, flat-out flight | Exists (launch follow). Needs near ground or parallax to read | **Risky low over tall places**: the frame moves fast over hard edges. The governor's job | Keep at a capped rate, or a cut plus a held wide |
| **Panning from a fixed place** (*sourced: rocket tracking mounts; a cinematographer on long-lens pans; weak: motorsport stills*): the camera stays and only turns, so he shrinks into distance. No parallax: the background moves only as fast as the pan | Scale and distance: the watcher's place in the world stays | **The peak launch.** A launch seen from the launcher | Our camera has no yaw, and I wouldn't add one (`camera.md` section 1). **Stand-in:** width and crane about the launcher. That's what the peak shot does | Fine: a zoom's edges are slow far from the centre. The meteor reads 1 to 1.5 | A cut to wide, held |
| **Wide against long lens** (*sources disagree:* one cinematographer says a long-lens pan always gives speed, a chase-car guide says a long lens flattens it): long flattens and stacks, wide stretches depth and speed | Long makes speed feel dense; wide makes near things fly | Long for a chase seen from far; wide for a skim over ground | **Not available:** the lens is 30°, and the near cap, the bend and the rig's distance all rest on it. Width is distance only. Keep it so | | |
| **Let him get tiny, with a mark in the world** (*rocket coverage*) | The pin-prick is the point. Scale reads because the planet's there | Peak only: Orb's "even if the fighter is only a few pixels" | Exists behind `peak_launch`. Needs VFX's trail | The trail is a flash source: read it | Same, held |
| **Width by height, with a margin** (*craft; Research's proto*) | He stays inside the frame as he climbs and falls | Any launch upward | Exists at 2.2 × height + margin. **Research asks for 1.25 on the descent:** part 2 | Fine | Fixed wide |

### Handing the eye over

| Technique | What it does | When | What it needs | Flash | Motion |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Three-beat focus: launcher, flier, landing** (*craft*) | The eye is told what matters next before it arrives. At each change the new subject starts near where the eye already is | Every send over a screen long | **The main gap.** Today it's launch follow, or a held frame and one cut at the landing (`LH_*`). There's no eased pass of focus along the path | Fine | Cut at the send, cut at the landing |
| **Hold a still frame and let him leave** (*sourced: a cinematographer's list; editing*) | A still frame makes an exit violent, and the crater and the launcher stay in shot | Fast, low launches over bright places, where a follow is what flashes. Today's `launch_hold` under Reduce flashing | Exists as `LH_*`. **Worth trying in normal mode for one launch in a while:** the stillness is a beat, and variety is what the director lacks | Built for flash, and it helps on most clips; on one city landing (ai 12345) it read worse than the follow. Read per place | Native |
| **Cut when the exit's inevitable** (*sourced: an editor's own account*) | The cut lands on energy, not after a blank frame | When the frame will lose him and a chase can't work | `cam_intent.launch` knows at the send. Today's cut comes later, at the landing. **Needs a reason logged** | One whole-frame change: counted, but alone it isn't a flash | Native |
| **Enter the next frame the same way** (*continuity*): left-moving stays left-moving | The viewer keeps their map | Every cut in a chase, every split | Exists by `sigma`, and the swing keeps it. The check: it fails if a cut flips his screen direction | | |
| **Arrive first, wait for him** (*craft: the lead shot*) | The landing is seen coming, and he slams into a frame that's ready | Known destinations with a long send | **Rejected on 10-22:** the lead whip broke QA's in-frame rule. It holds for a pane that shows one fighter. In one pane, as a **late pass** of focus on the descent, it's Research's change | Fine | A cut at the landing |
| **A long unbroken ride, not many cuts** (*sourced: winter-sports coverage*) | Keeps the viewer's map and the energy | A chase, a long flight | Exists as the follow; it depends on the catch being soft | Risky low over hard edges | Cuts |
| **Ride, release, pull wide** (*sourced: ski jump coverage*) | Follow into the take-off, then widen to show the flight's shape | Any launch up | The peak shot does this. **Tiers 2 and 3 now do too** | Fine | Cut to wide |
| **Show where he'll land** (*sourced: a talk on game camera mistakes*) | A player in the air wants the landing | The descent; a human who's been sent | The descent's pass of focus. **A pitch down for a human flier is open** | Fine | Hold |
| **Cross-cut, two places at once** (*editing*) | Launcher here, flier there | A long flight with something happening at both ends | **The split already does this** | Divider has its own rules | Holds |

### Scale

| Technique | What it does | When | Needs | Flash | Motion |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Scale reveal: low, wide, low** (*craft*) | The world's size lands because the shot before it was tight | Flights of 3 s or more; peak launches; a new biome | Designed in `camera.md` section 3, **not built** for ordinary flights. Needs the globe | Slow, far edges: fine, so far | A still, or skip |
| **Contrast of size** (*craft*): very tight just before very wide | Each makes the other larger | Before every wide | Exists: blow push, then the pull | Fine | No push |
| **Hold at the crest** (*craft; rocket: the staging moment*) | Time to see it. The move has a rest in it | Top of a high arc | Peak shot's hang. Its width settles as he slows | Fine | Native |
| **Foreground for depth** (*sourced: a cinematographer: close obstacles, narrow spaces, a low camera*) | Something near sells speed and the size of the far | A flight down a street or low over ground | Tile foreground is one tone now, so nothing passes in front of the plane. Towers and rows behind the plane can pass. **Fly the street's behind-the-plane row, don't add near things** | **Public check later:** hard edges near the lens are where the readings were. **For Orb's eye: try it,** the facets back in front against one tone, on a low flight | |

### Speed cues

| Technique | What it does | When | Needs | Flash | Motion |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Parallax by rows** (*sourced: multiplane practice; a cinematographer*) | Near moves faster than far: depth and speed together | Low flight | Exists on real terrain behind the plane. Stay under 0.6 of the height off the ground | Rows behind the plane are safe. In front isn't | Reduced by the capped rate |
| **Light and shade passing over him** (*sourced: a cinematographer*) | Speed by patches of light | | | **Public check later:** it's a flash by definition, so it needs a reading before anything public. Nothing builds it yet | |
| **Low angle** (*sourced: a cinematographer, weak: motorsport stills*) | Emphasises speed and power | Launch, swing | Exists: -4° swing | Fine | **None under the setting** |
| **Streaks, thin, in the world** (*weak: animation guides on speed lines and dry-brush streaks*) | Stand in for motion blur: the surroundings are what blurs | Over sky, when nothing's passing | VFX's trail and streaks exist. **Not on the fighter, not full-screen** (ADR 0010) | Thin and low contrast only | Keep, thin |
| **Smear, one frame** (*sourced: animators' guides*) | One stretched in-between sells the fastest move. Use it rarely | The launch's first frames | Animation's and VFX's, not the camera's. Worth asking for | Small area | Keep |
| **Motion blur on the frame** | | | **Rejected** (Orb, 2026-10-18) | | |
| **Wider lens at speed** (*craft: a game habit*) | | | **Rejected:** lens stays (`camera.md`), and a game camera talk warns that a quick change of field of view disorients | | |

### The camera's own timing

| Technique | What it does | When | Needs | Flash | Motion |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Stillness before the blow** | Everything after is measured against it | Every hit-stop | Exists: hit-stop holds | Good | Native |
| **Anticipation on the camera** (*craft*) | A slight tighten and lean before contact | Heavy or launch beats | Exists: `ANT_*`, 18 ticks | Fine | None |
| **Decelerate into a limit, ease the reaction to a sudden event** (*sourced: a talk on game camera mistakes*) | No move starts or stops at full rate | Every limit in the rig | **`launch_director`'s zoom ease.** The check found zoom starting at the cap | Fine | |
| **Rank what pushes the camera** (*sourced: the same talk*) | Rules that fight make shake | Every shot | Today's rig layers shots by hand; this is a design note for the director | | |
| **Follow-through, the camera overshoots and settles** (*craft*) | Weight: a move that lands soft | Stop of a whip, end of a chase, an impact | Partly: soft landings are built, overshoot isn't. **Small, under 2% of the width** | Fine | None |
| **Damping that falls with speed** (*weak: engine docs and forums*) | He can't outrun the camera, and slow moves stay soft | Every follow | `MASS_ACC` is a fixed limit, released on launches. **To be measured by part 3's test** | | |
| **Look-ahead that doesn't snap to zero** (*weak: a forum thread*) | No lurch when he stops dead | Landings, brakes, catches | `_plead` and `LAUNCH_LEAD`: **to be measured** | | |
| **Dead zone** (*weak: engine docs*) | Small moves don't shake the frame | Brawls | Exists in effect (`GOV`, focus filters) | | |
| **Whip as a transition** (*weak: a sports recording playbook; the game camera talk prefers a cut for fast repositioning*) | Moves the eye across space with energy, hiding a change of place | A catch-up over a screen | Exists: 12 frames, up to 3 widths | **A known flash source in cities** | A cut |
| **Directional shake on impact** (*craft; the talk: always offer it off*) | Force has a direction | Landings | Exists, with its setting | Bounded | Off |
| **Impact frame** (*animation*) | One frame that stops the world | Heaviest impacts | The hit-stop is ours today. A real impact frame is VFX's, **for Orb's eye** | Public check later | |
| **Roll, bank** (*craft*) | A curve should lean | Curving flight | Off by default, clip 7 owed | Fine | **Never** (Accessibility) |

## Part 2: the shot list

**Rule for every row:** every move eases. A cut names its reason in `CUT_REASONS`, as in `director.md` section 11. "Lost" is the shot's subject outside the frame for longer than the row allows. **Rates and times are first values.**

### Launches, by the lower tier

| Tier | Send | Beats | Width | Focus | A cut? |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1** (to 700 high) | About 1,400 u/s, or today's spread | Hit-stop still; blow push; he leaves; camera rides at fight size; arrival hold | Fight's, floor as today | Launcher and flier both in frame, or follow him | None. **Never wide at base power** (Orb) |
| **2** (to 2,500) | About 2,600 | The same, with a lean on his side | To 8,000 at the crest | Pair, then him | None |
| **3** (to 5,000) | About 3,700 | The reveal starts here: wide at the crest, eased back | To 16,000 | Pair to the crest, then passes to the landing | None |
| **4, not a meteor** (to 9,900) | About 5,100 | Launch, hang, descent, in one frame | To 32,000 | The same | None |
| **Fast and flat, any tier** (over 5,000 sideways, low) | Today's median is 10,800 | **Hold a still frame and let him leave,** or ride at the floor. Pick by what's there: a lit city holds | Fight's | Launcher, then landing | One at the landing if he's far: **reason, a change of space** |

### The meteor (`meteor-arc.md`)

| Beat | Camera | Check |
| :--- | :--- | :--- |
| Wind-up, hit-stop | Tight, still, the longest hit-stop | Dead still |
| 0 to 0.3 s | No whip. Width starts over 6 ticks | No jolt |
| Climb, 3 s | Width by height, up to `peakRate`. Launcher to 0.85, cranes to 0.6 over the last second | Foe in frame from 0.6 s on |
| Crest, 1.2 s | Width settles at 53,000 | Planet fills the lower 40% |
| **Descent, 2 s** | **Research's two changes** (below) | Foe in frame at least 90% |
| Impact, hold 0.5 s | Eases to 8,000 | Blast whole |
| Return, 1.3 s | To the fight's framing | No jolt, split may open |

**Research's two changes, checked against the rig. I take both, with one amendment:**

1. **Focus passes smoothly to just short of the landing, as the width stops holding both.** Yes: my peak shot does the same only by a clamp (`half` in `_peak_outputs`), which starts dead when he reaches 0.45 of the width and is the lurch Research found. **Build:** a weight, `share = smoothstep(both_fit_w × 0.8, both_fit_w × 1.2, width)`, inverted, moving the frame's centre from the pair's middle to a point 15% short of his landing on the line. **It needs the landing's `x`,** which the curve gives at the send. Until then, his own `x` plus his velocity for 1 s stands in.
2. **Width follows height with a margin of 1.25 on the descent.** Yes: 94% in frame with 7 ticks lost is at the top of the frame, and he's arriving at about 21,700 u/s, against 13,600 leaving. **Amendment:** the arc is 25,436 long now, not 13,200, and arrives at 74° rather than straight down. So the width must also hold his sideways lead. Take the larger of `1.25 × height fit` and `2.2 × (his distance from the centre)`.

**The trigger has to change too.** My shot predicts the apex from `vy`, which the curve doesn't use (it evaluates a closed form). It should read the curve's `H` when the flight's on it. That's the first thing to ask Simulation for: `f.arcH` or the like.

### A body through a tower

| Beat | Camera | Check |
| :--- | :--- | :--- |
| Before | Follow as launch. **Anticipate by `cam_intent` if he's aimed at it** | |
| Contact | The rig has `building_hit`'s push. **No cut, no zoom in** (RL-213 (2) and (4): structure, not people) | Fighter's not hidden over 8 ticks: Rendering's hole |
| Through | The tower's hole opens. Hold the size, keep following, debris carries the force | Lost at most 8 ticks |
| Out the far side | Follow-through: the width eases out 5% and back | No jolt |
| Fall behind him | The damage inset, if it's on, shows it. Otherwise never look back | |

### Flat-out chase across the planet

| Beat | Camera | Check |
| :--- | :--- | :--- |
| Start | Width to about 3,700 by the governor, lead 0.35 | Eased |
| 3 s and up | **Reveal in the middle:** crane up, pitch -6°, to 8,000 over 1 s, 0.5 s held, 1 s back. Only if there's something to see: a biome change or a landmark. Nudge turns may run | Size floor lifts only at peak tiers |
| Horizon | Turns at `v / R` on the globe, by the frame | Rendering |
| Biome crossing | Passes in view, no shot of its own | Landscape shot stands down |
| Arrival | The destination over the curve 1.5 s out, low, with a landing hold | Eased |
| Two in the air | Split panes in one direction, same trail | Same sky both sides |

### Beam struggle start

| Beat | Camera | Check |
| :--- | :--- | :--- |
| Tell, 33 ticks | A running swing rests. A slow push on both | Rest by the fire |
| Fire and meet | Width to hold both and the meeting point. **No cut.** Today's opening uses the push's shape | Both in frame or a named split |
| Hold | Slow build (`STRUGGLE_BUILD`), lean toward the loser | Exists |
| Brink, release | Exists | |

### Impacts

| Impact | Camera | Check |
| :--- | :--- | :--- |
| Light, medium | Nothing or a small push | No move for a light |
| Heavy, launch | Blow push: fast in, soft out | Exists |
| Landing | Land hold and push, shake with a direction, **a small overshoot at the width's stop** | New |
| Crater over the frame's width | Width eases to take it in, then back | Limit 1.3 times |
| Into water | Splash, same | Flash on the splash is VFX's |

### A swing during any of these

| Moment | Rule | Check |
| :--- | :--- | :--- |
| Launch, under peak width | Swing's angle and lean, follow as usual | Exists. Passes `swing_fight_check` |
| Peak shot | No swing: a running one rests by the climb | Encounter's rule |
| Through a tower | Rate's sim's. Rendering's near-line rule for towers. **No camera change** | Lost at most 8 ticks |
| Chase | Horizon gives way to the swing | Rendering |
| Beam tell | Rests in the tell | Exists |
| Impact | At rest by contact | Exists |
| Under the setting | Cut or still, as `swing-view.md` | Tested |

## What I'd build first, for part 3

1. **The test.** Every staged shot above, run through the real rig: it fails on a jolt, a lost subject or a cut with no named reason. Without it the rest is opinion, and its first run says what's actually wrong.
2. **Every cut names its reason.** Each `_cut_now = true` site records one.
3. **Research's two descent changes.**
4. **The three-beat focus for high launches:** pair, then flier, then landing, eased.
5. **Hold a still frame and let him leave, in normal mode,** as a chosen shot for fast, flat launches over bright places.
6. **Follow-through at a stop**, if the test shows the stops are hard.
7. **The reveal in flight,** on the globe.

## Sources

Chase and lens: [a cinematographer on making chases look fast](https://neiloseman.com/how-to-make-chase-scenes-look-fast/), [chase car notes](https://www.screenweaver.ai/film-techniques/camera-movement/chase-car-shot), [dynamic chases](https://www.videomaker.com/article/f5/13484-dynamic-chase-scenes/).
Live chase coverage: [chase drones at the winter games](https://www.sportsvideo.org/2026/02/09/how-obs-uses-fpv-drones-360-degree-replay-to-enhance-storytelling/), [the pilots on pace](https://www.theglobeandmail.com/sports/olympics/article-winter-olympics-2026-first-person-view-drones-unique-visuals-games/), [a pilot on reading athletes](https://www.powder.com/news/best-fpv-drone-pilot-ski-kocher).
Game cameras: [notes on the talk "50 Game Camera Mistakes"](https://2bdenny.github.io/blogs/2023/10/20/50-camera-mistakes.html), [the talk](https://www.youtube.com/watch?v=C7307qRmlMI).
Air to air, thin: [gimbals on camera jets](https://www.aerialfilmaustralia.com.au/jetshot), [aerial trends](https://www.avbuyer.com/articles/ga-buyer-europe/aerial-cinematography-today-trends-challengers-the-new-language-of-visual-storytelling-114296).
Parallax: [multiplane technique](https://www.researchgate.net/publication/342381311_The_Multiplane_Camera_Multiplanar_Technique_in_Animation_Production).
Rocket tracking: [filming a launch](https://www.digitaltrends.com/space/its-not-easy-filming-a-rocket-launch-heres-how-its-done/), [launch imagery fact sheet](https://www3.nasa.gov/centers/kennedy/pdf/167722main_LaunchImagery06.pdf), [drone footage of an ascent](https://www.redsharknews.com/technology/item/1166-the-most-exciting-space-rocket-shots-ever-taken-from-an-hd-drone), [how close-up launch footage is shot](https://petapixel.com/2018/02/23/spacex-shoots-amazing-footage-rockets), [media at a launch](https://news.medill.northwestern.edu/chicago/innovation-on-the-launch-pad-how-media-capture-a-nasa-rocket-launch/), [tracking mounts](https://www.cfpublic.org/2018-02-09/tracking-rockets).
Speed in motorsport: [panning technique](https://www.digitalcameraworld.com/uk/tutorials/how-to-capture-perfect-panning-shots-in-motorsport-photography), [panning and tracking](https://www.cliftoncameras.co.uk/Blog/How-to-Shoot-Motorsports-Panning-and-Tracking), [speed and low angles](https://www.photographytalk.com/motorsport-photography-how-to-capture-speed-and-panning-shots/).
Sports and the line: [a recording playbook](https://mz.unic.ac.cy/wp-content/uploads/2021/09/Sports-games-recording-playbook.pdf), [crossing the line](https://www.tvtechnology.com/miscellaneous/crossing-the-line-to-onscreen-confusion), [line of action](https://www.shootfirst.art/line-of-action).
Editing: [cutting on action](https://en.wikipedia.org/wiki/Cutting_on_action), [Walter Murch on the cut](https://www.provideocoalition.com/aotc-murch-books/).
Game cameras: [follow cameras in practice](https://uhiyama-lab.com/en/notes/unity/unity-cinemachine-camera-guide/), [damping at speed](https://discussions.unity.com/t/cant-look-up-with-free-look-camera-while-object-its-following-is-falling-or-moving-fast/799271), [look-ahead](https://forum.unity.com/threads/look-ahead-woes.659302/).
Animation: [smear frames](https://www.bloopanimation.com/the-art-of-smear-frames/), [more on smears](https://blog.cg-wire.com/smear-frames/).
Our own: `docs/research/cuts-and-eases.md`, `docs/camera/director.md` sections 4, 5, 11, `docs/camera/swing-view.md`, `docs/world/ring-any-angle/camera.md`, `meteor-arc.md`.
