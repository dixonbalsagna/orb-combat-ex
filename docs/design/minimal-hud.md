# What the player must know, with nothing on the fighters

Owner: Game Design. Date: 2026-10-18. **Paper only.** Orb's ruling is in `docs/ep/taste.md`: "A minimalist UI. Nothing on, over or between the fighters, ever". Orb circled the beam struggle's tug bar as "absolutely awful". This page rules, for each mechanic, the least the player must know at that moment, and where it comes from instead. It is aligned with Research's paper on readable high-speed combat with little HUD when that lands. Routed by owner in §4.

## 1. The three places information may come from

| Place | What it is | Its rule |
| :--- | :--- | :--- |
| **The fight itself** | Animation (poses and their timing), VFX on the bodies and the world (impacts, auras, the beams' meeting point), the camera (framing, punch-ins, holds) | The first choice, always. It must read at fight size, in both flash modes, and never hide a tell |
| **Sound and rumble** | A cue's sound, the music's beat, the pad's rumble (Controls' patterns) | Second. Every cue the player must act on has a sound. Rumble doubles the ones that need timing |
| **The edge HUD** | Small and sparse, at the screen's edges only: the two plates, the button legend, the one-line hint | Last, and only for what the fight can't carry: resources that change slowly, and a press the player must find. Never on, over or between the fighters |

**What is withdrawn everywhere:** every ring, bar, track, pip, diamond, badge, marker, icon or label drawn on, over or between the fighters during play (`taste.md`'s list).

## 2. Mechanic by mechanic

| Mechanic | What the player must know, at that moment | Where it comes from | Dropped |
| :--- | :--- | :--- | :--- |
| **The beam struggle** (`rule-of-cool.md` §2) | When to press (the pulse); which way it is going; that it is nearly over | **The fight:** the beams' meeting point is the gauge, already in the world. A surge bulges it and pushes his beam back. A stray flickers his own (inside the flash rules). The camera tightens as the point nears a side. **Sound and rumble:** the pulse is a beat, in the music and on the pad. A surge cracks, a sharp one cracks brighter, and the sound rises as the point nears either fighter | **The tug bar,** and any pulse marker drawn on the screen |
| **The clinch and the grapple** (`grapple.md`) | That he is caught or holding; who is ahead in the grip; when to pummel; that a throw is coming | **The fight:** the grip is in the bodies. The leader's arm is over, the other's shoulder dips, and at two ahead the leader sets his hips for the throw: a pose, one step a stage, five stages. The catch's 10-tick tell is the reach. **Sound and rumble:** the pulse is a creak of the grip and a pad pulse. A pummel thuds, a stray is silent, and a press in the lockout gets a short dull refusal | **The grip's five steps drawn between them** (`grapple.md` §2), and the refused cue as a sign. The touch-Simple button's label "PUMMEL / BRACE" stays: it is on the button at the screen's edge |
| **Launcher openings** (`launch-anywhere.md`) | That he is open now (a sure launcher), and that B launches | **The fight:** the opening's stagger, with his head snapping back and his arms flying open. **Sound and rumble:** the ping, which both players hear, and a pad pulse. **The edge HUD:** the B in the legend lights LAUNCH while a B would launch, solid when it is sure. The first-time hint is one line at the edge, once | **The ring on his chest** (the eleventh round), **the run's pips** (there is no gate any more), **the power pips**, **the rose of four arrows**, and the rest's ring. A launch's power shows in the send itself |
| **Perfect-block and perfect follow-up windows** | That a press landed perfect, and that a chain is going | **The fight:** a perfect has its own impact (a sharper spark, a held pose of a few ticks, a small camera punch). A chain's blows grow: each link a little bigger in spark and sound. **Sound and rumble:** a perfect has its own sound, and the pitch climbs with the chain's links | **Any window drawn on the hit,** and any chain counter. **In training only,** the dummy's readout (early or late by how many ticks) is a strip at the screen's edge (`fighter-pipeline.md` §8) |
| **The charge** (held Y and B) | How far the charge has come, and when it is full | **The fight:** the wind-up pose deepens and the aura gathers at the striking limb. At full, one bright beat through the flash register. **Sound and rumble:** a rising tone, and a pad pulse at full | Any charge meter |
| **Forms and the coil** (`hero-forms.md`) | That a form is ready; that he is holding it; that the hold has built (small, long, biggest) | **The fight:** a ready form shows in the aura, which brightens and then steadies. A hold coils it: the aura tightens and pulls in, its pulse slowing as the coil grows. **Sound and rumble:** a ready sting, and a low hum under the music that rises with the coil. **The edge HUD:** the power bar on his plate, with the ready step marked at its end | **The two branch fills by the power bar** (`hero-forms.md` §8). The branch shows when he takes it, in the form itself, and in the line he says |
| **The air brake** (`buildings.md` §7.2) | That he can brake now, and that he is braking | **The fight:** the midair skid's pose and its trail, whose length shows his speed. **Sound and rumble:** a short rumble tick when the brake becomes available, and the skid's rising and falling sound | Any brake prompt |
| **Collateral** | That people are near and in danger; that he has just cost lives | **The fight:** the crowds, fleeing and sheltering, and the buildings' warnings. **Sound:** the crowd, the evacuation barks, and the hero's own voice and posture when his kills cost him | **The share-lost bar during the fight.** The toll is shown at the pause and on the results screen, as a count and the planet's state (Legal c08) |

## 3. What the edge HUD keeps, in all

- **The two plates,** at the top corners: the name, the wounds' readout as the damage model has it, ki, and the power bar with the ready step at its end.
- **The button legend,** at the bottom edge: the B lit LAUNCH while a B would launch.
- **The one-line hint,** at the bottom edge, once per lesson, and only with Control hints on.
- **The rival pointer** at the screen's edge while he is off it (`docs/ui/hud-spec.md` §60).
- **Nothing else during play.** Pause, results, the run's screens and training may show more, since nobody is fighting then.

## 4. Who does what

| Owner | The change |
| :--- | :--- |
| **UI** | Remove every mark on, over or between the fighters: the beam struggle's tug bar and pulse marker, the grip's steps, the chest ring, the run pips, the power pips, the rose, the rest's ring, any chain counter, the share-lost bar during play. Keep §3's edge HUD. Move training's readout to an edge strip |
| **VFX** | The beams' meeting point as the struggle's gauge (bulge, flicker, push); a perfect's own impact, and a chain's growing sparks; the charge gathering at the limb and its full beat; the form's ready aura and the coil's tightening; the skid's trail. All of it through the flash register |
| **Animation** | The opening's stagger pose; the five grip stages and the leader's set before a throw; the charge's deepening wind-up; a perfect's held pose; the skid |
| **Audio** | The struggle's beat, the surge's cracks and the rising tone; the clinch's creak, the pummel's thud and the refusal; the ping; a perfect's sound with the chain's climbing pitch; the charge's rising tone; the ready sting and the coil's hum; the skid's sound |
| **Controls** | Rumble for the struggle's pulse, the clinch's pulse, the opening, the charge at full, and the brake becoming available |
| **Camera** | The struggle's tightening, a perfect's small punch-in, and holding the clinch's bodies clear |
| **Narrative** | The hero's lines when his kills cost him, and when he takes a branch |
| **Legal** | The flash register for every visual cue above |
| **QA** | The teaching rows read with nothing on the fighters: the newcomer's first launch inside 60 s (90%), and a first-time player's beam struggle won by pressing on the beat |

## 5. Pages this changes

- `rule-of-cool.md` §2: the struggle's look, with no bar.
- `grapple.md` §2: the grip in the bodies, not drawn.
- `launch-anywhere.md` §9: the lit B only, no pips and no rose.
- `brawl-second-pass.md` §14's eleventh round: no chest ring and no pips.
- `hero-forms.md` §8: no branch fills on the HUD.
- The EP's homework-5 decision of a small bar for the share of people lost (`docs/ep/vision.md`): it moves to the pause and the results screen, as a count and the planet's state.
