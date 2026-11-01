# Beam answer alert: accessibility review (2026-11-01)

Accessibility & Localization, for the EP. Reviewed: `docs/ui/beam-answer-alert.md`, the mock `docs/ui/mockups/beam-answer-alert.html` (settings and structure only), and the window it serves, `docs/design/rule-of-cool-map.md` rows 40 and 41 (§1 to §3). Paper only; nobody has played the window, so every number is a first value.

## Short answers

- **Is "a little longer" plus a strong outline enough? No.** Both are good and cheap, and neither helps with the real problem. The window is 6 to 60 ticks (0.1 to 1 s) from the beam leaving the hand, and for a snap beam or a close one it is shorter than a person can see a cue and press a button. Keeping the mark up half a second *after* the window closes only shows that it ended. The outline helps a mark be found, not read. What helps the player respond is **an earlier warning**, and that can be view-only.
- **Should a wider chance exist? Yes, in two forms:** a view-only **early warning** for everyone, and a gameplay **late-answer grace** as an assist. How each is marked is below.
- **The settings page is too much by default.** Twelve rows is the right amount of *choice* and the wrong amount of *first contact*. Put three presets on top and keep the rows under "Custom".

## What is missing

### Low vision
| Gap | Fix | Owner |
| :-- | :-- | :-- |
| The strong outline is "a white line round every mark". On a bright sky or a fire it vanishes, and a thin outline alone does not make small text readable | Every mark sits on a **solid backing plate** (dark, with a light edge), so its contrast does not depend on the scene. Words and glyphs must reach 4.5:1 against the plate, checked on the brightest and the darkest biome. The strong outline is the *plate's edge* made thicker, not a replacement | UI, Art |
| Sizes small, medium, large, "a small part of the screen at every size" | The **largest size must be clearly larger**, and the words must follow Text size up to its top step (1.5 times). Give a minimum height for the words in pixels at 720p and test it. The cap on screen area is a flash and clutter rule; it should not stop Large from being large | UI |
| The edge mark tracks the rival along the screen edge. For tunnel vision or a magnifier the edge is the worst place | Add a fixed place **near the player's own plate** (the plate tag has this) and a **bottom-centre** place under the fight. Never over a fighter | UI |
| A mark that slides with the rival is harder to find | Let the edge mark **snap to three slots** (upper, middle, lower) instead of sliding | UI |

### Hearing
| Gap | Fix | Owner |
| :-- | :-- | :-- |
| One "Strength" row sets how loud, how hard, how bright and how heavy the outline are. A person who needs a louder sound should not get a brighter flash | **Split it:** Visual strength, Sound volume, Buzz strength | UI, Audio |
| Two rising notes can sit where a hearing loss is | Keep the notes in a **mid band** (suggest 300 to 1,000 Hz fundamentals) with a clear attack, distinct from the finisher chip's sound, and test them under the mono setting | Audio |
| The sound has no caption | Add it to the Captions option as a short line ("Answer chance"), as every other sound that carries information needs | Audio, UI |
| Web and keyboard have no buzz, so a deaf player there relies on the visual alone | Fine, and the default must not be "buzz only" anywhere. The visual alert must always be able to stand without sound, and the sound without the visual | UI |

### Cognitive load
| Gap | Fix | Owner |
| :-- | :-- | :-- |
| Four alerts on at once, in three places, for a reaction of a tenth of a second | Presets: **Calm** (plate tag only, fixed place), **Standard** (edge mark and plate tag, sound), **Full** (everything). Default Standard. The rows sit under Custom | UI |
| **The mark says FIRE BACK or DODGE for the whole window, but a dodge only works in its last 14 ticks, and an early dodge gets followed** (`rule-of-cool-map.md` §1, §2). The alert would teach the wrong timing | The bar carries a **notch for the dodge zone**, and DODGE reads as available only inside it (a steady change of word, not a flash). The bar must match the real window, for the real beam | UI, Game Design, Encounter |
| Words cannot be read in 6 ticks | **Icon and button glyph first, words second.** Show only the answers that are open now | UI |
| Not knowing what the alert is for | A practice case in Training: a slow beam and the bar, once, with the window drawn out | UI, Game Design |
| The glyphs must show the *live* binding, including a swapped layout, a D-pad strike, a one-stick form and a remap | "Fire back" is a two-part input (RB and a direction toward him). Draw both parts from the player's own bindings (prompt-glyphs rule 2) | UI, Controls |

## The wider chance

1. **Early warning (view only).** An optional mark from when the rival **starts to charge a beam**, reading "Beam charging" and turning into the answer alert when the beam leaves. It shows what the lit hand already shows, so it gives away nothing the other player could not see, and it never changes the sim, so it is fair in every mode, ranked included. The existing rule "not a hint about the future" is kept: it appears at the charge, never before. **This is the option I would build first.** It buys a slow-reacting player the most time of anything on the page. Default off; on in the Calm preset.
2. **Late-answer grace (gameplay assist).** Rows: off, a little, more. First values: **+6 and +12 ticks**, counted as extra ticks *after the front arrives* in which the receiver's answer still counts (a grace on the receiver's input, as the controls' lockouts are on input), **not** a slower beam, because that would change the shooter's fight. It changes outcomes, so it follows the assist rules from the first brief: deterministic, recorded in the match settings and the replay header, never the sim clock. Offered in solo, co-op and training. In versus: **Orb decides**, with Game Design. My recommendation is that it is allowed in versus only when the match setup says so, and off in ranked.
3. **How it is marked.**
   - On screen the extra time is drawn as a **hatched tail on the bar** with the word "Assist", so it is not colour alone and it is not mistaken for the real window or the dodge notch.
   - The pre-match setup and the results list the assist for the player who uses it, by name, and the replay header carries it. No player is told in the fight, and nothing is drawn over a fighter.
   - A player who turns it on sees their own tail; the other player sees only the setup line. Nothing is hidden: the setting is in the header for anyone who reads it.

## Smaller points

- **Localization.** FIRE BACK, DODGE and YOUR CHANCE go in the string table with a context note, and the marks must still fit at 40% longer text (the pseudo-locale checks this). The glyphs carry the meaning when a word wraps.
- **Flash.** Small, steady, no pulse is right. Repeated alerts in a trading of beams can still come two or three a second, so the analyser should read a clip of that, in both flash modes. The early-warning mark appearing and then switching to the alert should be one continuous mark, not an appear-disappear-appear.
- **Two players, one screen.** Each pane draws its own receiver's mark; no pane shows the other player's.
- **Per player.** Every row has a player-two copy, as the UI page says. The presets are per player too.
- **Mobile** is parked; nothing here adds phone work.

## Questions

- **Orb:** is the early warning wanted (I say yes), and is the late-answer grace allowed in versus, in ranked, or only by setup (I say by setup, not ranked)?
- **Game Design:** the dodge notch needs the dodge zone exactly (last 14 ticks before arrival, up to 6 after, as the data has it). Is that final?
- **Audio:** the notes' band, and whether a second quiet tone marks the dodge zone opening for players who rely on sound.

## Next

When the event (`beam_window`) exists, I audit the built alert against this page and add the rows to the P5 checklist.
