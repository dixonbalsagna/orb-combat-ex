# The beam answer alert (UI & UX, draft, 2026-11-01)

Orb: "engineer some way to non-intrusively alert the player on the receiving end that there is a window to fire back their own beam attack or dodge, this UI / UX element should have granular display options available to the player." Game Design is ruling the window itself. This page is the player-facing part, with a clickable mock: `docs/ui/mockups/beam-answer-alert.html` (open it in a browser; every settings row changes the scene as you press it). Paper and a mock only; nothing is built.

## In one paragraph
When the rival fires a beam at you, there is a short moment to answer: fire your own beam back, or dodge. Today nothing says so except the finisher chip (for a finishing beam only) and what you can see in the fighters. The alert is a small, steady mark that says **FIRE BACK or DODGE** with the two buttons, for exactly as long as the chance lasts, and then goes. It appears and it disappears, with no fade, no flash and no pulsing. It never goes over a fighter. Every part of it can be turned on or off, made bigger or smaller, softer or stronger, and moved.

## The four alerts (all on by default except where marked)
| # | What the player sees or feels | Where | Built from |
| :-- | :-- | :-- | :-- |
| 1. **Edge mark** | A tag on the screen's edge on the side the beam comes from: an arrow pointing at the rival, the words FIRE BACK or DODGE, the two buttons, and a bar that runs down as the chance runs out | The screen's edge, level with the rival, nudged off any fighter (the distance chips' rule) | The edge-chip code the split screen already has |
| 2. **Plate tag** | The same words and buttons, under your own name plate | Your plate's corner; never moves | The plate's chip row |
| 3. **Glint** | A bright four-point sparkle on the beam, a little way out from the rival's hands, never on a body, steady while the chance lasts | In the scene | Rendering and VFX draw it; UI only says when and how big |
| 4. **Sound and buzz** | Two quick rising notes, and two short buzzes on a controller | Nothing on screen | Audio's sound; Controls' rumble (a ninth kind, `answer_window`) |

The finisher chip stays as it is; a finishing beam shows it too, and the edge mark stays quiet while it is up so the two never say the same thing twice.

## Rules it keeps
- **Nothing over the fighters.** The edge mark and the plate tag live in the HUD's own places; the edge mark uses the same "off bodies" test as the distance chips and the plate tag is on the plate. The glint is placed by the world, off the bodies, and is small.
- **No fades, no flash, no pulse.** Each mark is drawn or it is not. The only thing that moves is the bar shortening, and under Reduced motion it steps in quarters. Nothing changes in brightness over time, so it cannot count in the flash check; the biggest mark is about 1% of the frame against a 2.8% limit.
- **Never colour alone.** Every mark has a shape (the arrow, the bar, the star), the words, and the button's own mark. The colours follow the player's colour-vision setting like the rest of the HUD. The mock can preview the scene as three kinds of colour-blind view.
- **Plain words.** FIRE BACK, DODGE, YOUR CHANCE. No numbers, no chance of success (the same rule as the finisher chip).
- **Not a hint about the future.** It shows the chance while it is open. It never shows it early.
- **Text size.** The words follow the Text size setting; the tag grows, then wraps, and never hides.

## The settings page (a card, "Answer alert", under Controls)
| Row | Choices | Default | Why |
| :-- | :-- | :-- | :-- |
| Edge mark | on, off | on | the main alert |
| Plate tag | on, off | on | for players who check their plate |
| Glint in the world | on, off | on (off until VFX has drawn it) | for players who watch only the fighters |
| Sound | on, off | on | |
| Buzz | on, off | on for a controller, off on the web (browsers disagree) | |
| Size | small, medium, large | medium | the marks stay a small part of the screen at every size |
| Strength | subtle, normal, strong | normal | how loud, how hard, how bright, how heavy the outline |
| Where the edge mark sits | toward the rival, bottom corner, beside my plate | toward the rival | for players who want one fixed place |
| How long it stays up | until the chance ends, a little longer | until it ends | a little longer keeps it up half a second more so you can see it ended; it never changes your chance |
| Colour-blind safe | follows the Colour-blind mode setting | | the alerts do not rely on colour; the mock previews the views |
| Strong outline | on, off | off | a white line round every mark |
| Wider chance | off, a little, more | not offered | a gameplay change, below |

Each row has a player-two copy when two people play (the same way the hold and toggle rows do). With nothing on, a player gets no alert at all; the page says so in its footer. A row that can do nothing is hidden (no Buzz row on a keyboard).

## What I need from others (through the EP)
1. **Game Design:** the window: when it opens and ends, whether the receiver can answer with a beam, a dodge or both, and whether a beam in a clash still counts. The alert says only "FIRE BACK" or "DODGE" or both, from the ruling.
2. **Encounter or Simulation:** one event for it: a cue `beam_window` with the receiver, the shooter, which answers are open (beam, dodge) and the length, and a matching end, the way `beam_struggle` already starts and ends. UI reads it and draws; nothing is written to the sim.
3. **Rendering and VFX:** the glint on the beam, placed off the bodies, with a size and strength the HUD passes. A host feed `answer_alert_fn()` in the way `planet_map_fn` is.
4. **Controls:** a rumble pattern `answer_window` (two short buzzes) and where the host reads the setting.
5. **Audio:** the two notes, with a volume the strength row sets.
6. **Accessibility, through the EP:** the review of the whole page; in particular whether "a little longer" and the strong outline are enough, and whether a wider chance is wanted.

## A choice that is not UI's: "Wider chance"
Accessibility has said before that a longer window changes how a fight plays out, so it is a gameplay assist: Game Design and Orb decide if it exists, if it is allowed in ranked or online play, and it would be recorded in the match settings. The mock shows the row greyed, so you can see where it would go. Everything else on the page changes only what the player sees and hears.

## What it costs and how it is built
One small layer drawn only while the chance is open (it redraws only when the bar steps), no cost otherwise; ten settings, each with a player-two copy; one feature flag (`answer_alert`, off until the event exists). Tests: each row on and off, the edge mark never meeting a body at six sizes and two layouts, no fade (the mark is drawn or not on every frame), and the words fit at every Text size. The mock is the picture for Orb; I will build it as a park once Game Design has ruled the window and the event exists.

## Questions for Orb (plain)
1. Should the edge mark and the plate tag both be on by default, or just the edge mark?
2. Do you want the glint in the world? It needs VFX to draw it.
3. Should "a wider chance" exist at all, for players who need more time? It would change how fights play.
