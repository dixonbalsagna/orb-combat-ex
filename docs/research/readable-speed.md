# Readable speed: high-speed combat with nothing over the fighters

Research & Prototyping, 2026-10-18, for Orb's request: "research serious ways to address the high speed combat without cluttering useless pieces of icons and garbage over the fighters." It is bound by `docs/ep/taste.md` and ADR 0010: **nothing on, over or between the fighters, ever.** A paper only; nothing was built. Numbers in brackets are the sources at the end.

## 1. How fast action games stay readable with little or no HUD

**The interface taxonomy.** The standard taxonomy sorts interface elements by two questions [1]:
- Is it part of the fiction?
- Is it placed in the game space?

Orb's rule removes the "spatial, not in the fiction" quadrant: rings, bars and markers drawn in the fighters' space. What remains:
- **diegetic** cues, the world and the bodies themselves;
- **meta** cues, effects on the whole screen such as hit-stop or camera shake;
- a thin **non-diegetic** HUD at the edges.

Fast action games put almost all live information in the first two [1, 2, 3].

**Camera grammar.**
- **Track and lead.** A good dynamic camera keeps the subject where the next action will be. It leads in the direction of motion and respects what the player is trying to see [5].
- **Frame for the hit.** On a heavy blow the frame tightens toward the contact, then follows what was hit.
- **Hit-stop.** A freeze of a few frames on contact, scaled by the blow's weight, tells the eye "this landed, and this hard" with no text. A longer "big moment" stop marks decisive hits [4].
- **Shake, and hard cuts.** Directional screen shake, opposite to the force, adds weight [3]. Smash cuts, hard and never dissolved, are kept for set pieces.
- **Speed through the world.** Parallax, streaks, dust and debris thrown by passing bodies show speed better than an indicator [2, 3].

**Animation tells, silhouettes and anticipation.**
- The few frames of wind-up are the opponent's only honest warning, and the stronger the blow, the clearer the pose must be [9, 13].
- Poses must read as silhouettes, with no colour and no detail [8]. Effects must never cover the silhouette mid-attack [9].
- **Smear frames** stretch or multiply the striking limb along its path for a frame or two. Fast motion then reads as motion instead of a jump between poses. Smearing only the striking hand is often enough [6].
- The anime tradition adds the **impact frame**: one or two stylised, high-contrast drawings at the instant of a hit [7]. For us it is a flash risk: allowed only small, on the bodies, and through the flash register.

**Effects that carry state on the body or the beam.**
- Charge, guard, power tier and the winner of a struggle can all be encoded in the aura and the beam: size, turbulence, colour temperature, how far up the body the light has filled, and which beam is thicker and pushing.
- Impact feel studies find that players read **hits against misses against blocks** from distinct effects and sounds [10].

**Sound and rumble as information.**
- A blocked blow sounds dull; a perfect block rings.
- A wind-up has a rising whoosh whose peak is the moment to react [11]. Audio telegraphs carry timing better than pictures do.
- An incoming rush is a Doppler whoosh panned to the side it comes from.
- Rumble works when it is sparse and matched to the event's weight, and it must never fight the audio [12].

**Edge-of-screen minimalism.** What must stay non-diegetic goes to the corners, small and steady:
- names, tier pips, a meter, a planet strip;
- one pointer at the very edge of the screen for a fighter off it.

Everything else is shown by the fight itself.

## 2. Recommendations for our game

"Replaces" names what our HUD draws in the fighters' space today (`docs/ui/hud-spec.md` sections 3, 15, 22, 34, 36 and 62). Costs are estimates, in slices.

| # | Recommendation | Owner | Replaces | In the beam struggle, instead of the bar | Cost |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | **Hit-stop by weight.** Light 2 to 3 ticks, medium 4 to 5, heavy 6 to 8, launch or close 10 or more ("big moment"), plus a 1 to 2 % camera push. The hit-stop setting stays as accessibility | Game Design, Simulation, Camera | The hit-confirm marks; any need for damage text | 2 ticks on every surge; a long stop when the struggle breaks | 1 (tuning; the stop exists) |
| 2 | **Frame for impact, cut only hard.** Lead the motion; on a heavy, tighten toward the contact, then follow the sent body. Cuts only for set pieces, never a dissolve | Camera | The incoming chip in a single view; the launch's teaching marks over the fighter | Frame square to the beam line, centred on the meeting point, pushing in as it nears a fighter | 2 |
| 3 | **Speed through motion.** Smears on striking limbs; after-images on dash and zip; the ground, water, glass and dust reacting under passing bodies | Animation, VFX | Rush and incoming markers inside the fighters' space | Dust and water blown back along the beam line; the ground under the meeting point scoured | 2 to 3 |
| 4 | **The wind-up pose is the window.** The parry or chain window is the anticipation pose, plus a short registered glint on the striking hand, plus the wind-up's rising whoosh | Animation, VFX, Audio | The closing rings of the parry and chain windows; the beat ring option | The beat is a slow swell of the meeting point, never a flash, with a pulse in the sound | 2 |
| 5 | **Guard on the body.** The guard pose; the aura hardening into a shimmer held inside the silhouette; deflected sparks flying the way the blow came | VFX, Animation | The guard arc | The guarding side's beam narrows and steadies; deflected energy sprays off the meeting point | 2 |
| 6 | **Wear on the body.** The damage marks (they exist), posture (a guarded arm, a limp), heavier breathing, an aura that thins and stutters slowly at the brink | Animation, Rendering, VFX | The aura crown around the fighter; head flashes as markers | The tiring side's stance slides back, its beam frays near the hands, and its aura thins | 3 |
| 7 | **Power in the aura.** Tier is aura size and turbulence; a charge fills the aura from feet to head; ready is a steady full aura (`docs/vfx/power-language.md`) | VFX | Any tier or charge mark beside the fighter; the form-ready prompt over him | Each beam's thickness and brightness carry its owner's push. The winner's beam swells and the meeting point slides | 2 |
| 8 | **The beam struggle carries itself.** The meeting point is the tug of war: the sim already holds it (`Clash.mid`, 0 at one fighter's hands to 1 at the other's). An on-beat press sends a surge wave down the presser's beam into the meeting point. The comeback zone is the losing fighter digging in: his feet carve the ground and his aura flares | VFX, Audio, Camera, Game Design | **The tug track, its diamond and its closing ring** | This row is the answer itself | 3 |
| 9 | **Sound families as information.** Distinct sounds for light, medium and heavy, blocked, perfect block, wind-up, rush (panned, Doppler), the struggle's beat, and a brink breath. Stereo placed by screen position | Audio | The incoming chip in a single view; the press marks | A pulse on the beat that rises in pitch as the meeting point nears the player's hands | 2 to 3 |
| 10 | **Rumble that informs, sparingly.** Keep Orb's picks (landed blows, closes, launches, landings, buildings, struggles; not on the beat). Scale the struggle's rumble with who is pushing | Controls, Audio | Nothing on screen; it backs up rows 1, 8 and 9 | A low, steady rumble that grows as the player loses ground | 1 |
| 11 | **An edge-only HUD.** Corner plates (name, stance badge, tier pips, meter), the planet strip, the toll at the edge. An off-screen pointer only at the screen or pane edge. No label over a fighter (the YOU label goes) | UI | Everything listed above that is drawn in the fighters' space | An optional, off-by-default edge meter for accessibility, never between the fighters | 1 to 2 (mostly removal) |
| 12 | **A silhouette budget.** Effects never cover a fighter's silhouette: they go behind it, or thin out over it. A rim light in the fighter's colour keeps the silhouette clear against busy ground. One player tells his fighter by that colour, not by a label | Rendering, VFX, Art | The readability cap's HUD thinning; the YOU label | The two beams' colours stay distinct to the meeting point | 2 |

**Rules for every row:**
- **The flash register.** Any glint, surge, swell or impact frame asks the flash register. Reduce flashing turns rows 1, 4, 7 and 8 to slower and steadier versions.
- **The look gate.** Each change goes through ADR 0010's side-by-side against the reference build.
- **Accessibility.** For players who need it, an off-by-default edge meter can mirror the struggle (row 11), and the sound and rumble rows carry what colour cannot.

## 3. Where to start

1. **Row 8, the beam struggle.** It is the screenshot Orb circled. The data it needs already exists (`Clash.mid`).
2. **Rows 11 and 12.** Strip the fighters' space, and make sure what remains reads.
3. **Rows 1, 4 and 9.** Hits, windows and timing carried by the stop, the pose and the sound.

Then 5, 6 and 7 (the body carries guard, wear and power), and 2 and 3 with Camera's own iteration on Orb's reference build.

**Risks.**
- Diegetic cues only work if they are strong. A faint glint reads worse than the ring it replaced, which is why each row passes the side-by-side.
- New sound families and rumble patterns cost Audio's time.
- Impact frames and surges are flash risks, so they go through the register and pass Tools' clips before they ship.

## Sources

1. E. Fagerholt and M. Lorentzon, *Beyond the HUD: User Interfaces for Increased Player Immersion in FPS Games*, MSc thesis, Chalmers, 2009. https://hdl.handle.net/20.500.12380/111921
2. M. Jonasson and P. Purho, "Juice It or Lose It", GDC Europe 2012. https://www.gdcvault.com/play/1016487/Juice-It-or-Lose
3. J. W. Nijman, "The Art of Screenshake", INDIGO Classes 2013. https://www.youtube.com/watch?v=AJdEqssNZ-U
4. M. Sakurai, "Stop for Big Moments!" (on hit-stop), *Masahiro Sakurai on Creating Games*. https://www.youtube.com/watch?v=OdVkEOzdCPw
5. J. Nesky, "50 Game Camera Mistakes", GDC 2014. https://www.youtube.com/watch?v=C7307qRmlMI
6. C. Lendenfeld, *Smearframes in Video Games*, MA thesis, FH Hagenberg, 2018. https://theses.fh-hagenberg.at/system/files/pdf/Lendenfeld18.pdf
7. Sakuga Blog, glossary: "Impact Frames". https://blog.sakugabooru.com/glossary/impact-frames/
8. D. Fornace, "Fighting Game Design: The Power of Silhouettes". https://fornace.medium.com/fighting-game-design-with-dan-fornace-the-power-of-silhouettes-915fde48318f
9. Rivals Workshop guide, "Anticipation, Action, Recovery". https://www.rivalslib.com/workshop_guide/art/anticipation_action_recovery.html
10. "What Features Influence Impact Feel? A Study of Impact Feedback in Action Games", arXiv:2208.06155. https://arxiv.org/pdf/2208.06155
11. "Enemy Attacks and Telegraphing", Game Developer. https://www.gamedeveloper.com/design/enemy-attacks-and-telegraphing
12. "Stop the Buzz, Start the Symphony: A Guide to Responsible Controller Vibration", Wayline. https://www.wayline.io/blog/responsible-controller-vibration
13. F. Thomas and O. Johnston, *The Illusion of Life: Disney Animation*, 1981 (the anticipation principle).
