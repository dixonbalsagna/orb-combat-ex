# Phone freeze: the words for three lines on the web demo

Status: draft, private, not reviewed by Legal (Legal is reviewing the privacy side). Written 2026-10-26 by Community and Marketing for the EP. Nothing here is in the page. Source: `docs/perf/phone-freeze-2026-10-26.md` and the strings in `docs/perf/web-shell/ocx-crumbs.js`. American spelling.

The rules these lines follow: honest, calm and short; at most 15 words a line (every line below is under it); no hype; no apology spiral (one plain fact, no "sorry"); no promise of a fix, a date or progress; no animation; written as if nothing is sent, because nothing is.

## 1. The static line before the heavy start

How it reads today: `crumbs.js` shows the stage name, a period, then a sentence. So the line is "Starting. " or "Downloading 40%. " or "Preparing the game and its graphics. ", followed by this text. Each option below is written to follow one of those. The line stays on screen while the page is frozen, so it cannot say anything about progress, and it must stay true if nothing ever changes.

| | Text | Words per sentence |
|---|---|---|
| **1A (recommended)** | First start can take a minute or more on a phone. The page may not respond. Reloading starts the wait over. | 11, 5, 5 |
| 1B | A first start on a phone can take a minute or more. The page may not respond. | 12, 5 |

Why 1A: it explains the freeze before the player sees it, and it gives the one useful fact: reloading restarts the wait. It never says "still working" (a frozen tab cannot promise that), never says "once" (I do not know that a second start is faster), and never says it will finish.

"A minute or more" is what Performance measured: 22 to 57 seconds on this PC and a throttled CPU, with 1.5 to 2.5 minutes possible on a low-end phone.

## 2. The next-load note after a stall, with its two buttons

The note shows on the next visit if the last one stalled for 5 seconds or more, closed before the game was running, or lost its graphics context. Its message has three cases. Fill the seconds and the stage in plain words (the mapping is in the notes below).

| | A stall of known length | The game stopped early, no stall length | The phone took the graphics away |
|---|---|---|---|
| **2A (recommended)** | Last time the game stopped responding for 22 seconds while getting ready. If it froze for you, you can copy a report. It stays on your device until you choose to paste it somewhere. | Last time the game stopped before it finished starting. If it froze for you, you can copy a report. It stays on your device until you choose to paste it somewhere. | Last time your phone took the graphics away from the game. If that happened to you, you can copy a report. It stays on your device until you choose to paste it somewhere. |
| 2B | The game froze for 22 seconds last time. Copy a report if you like. It stays on your device unless you choose to paste it somewhere. | The game stopped before it finished starting last time. Copy a report if you like. It stays on your device unless you choose to paste it somewhere. | Your phone took the graphics away from the game last time. Copy a report if you like. It stays on your device unless you choose to paste it somewhere. |

Sentence lengths: 2A is 12, 10 and 12 words in the first case (9 to 11 in the others); 2B is 8, 6 and 12.

**Buttons:**

| | Main button | Other button | After the main button |
|---|---|---|---|
| **2A** | Copy a report | Dismiss | Copied |
| 2B | Copy report | Not now | Copied to your clipboard |

If the browser blocks the copy, the shell now says "Press and hold to select". Plainer, with the same meaning: **"Couldn't copy. Press and hold the text to select it."** (9 words).

Why 2A: it says what happened, says copying is optional, and says in the words the EP asked for that the report stays on the device until the player chooses to paste it somewhere. It does not say "sent", "upload" or "share". It also never blames the phone or the player.

## 3. The report's opening line

Whoever receives the pasted text should know at once what it is, who made it, and what it holds. The report holds the browser string, screen, pixel ratio, memory, cores, the graphics name, the last stage, stall lengths, visibility changes, context events and any error messages. It holds no name, account, location or contact details, so the line says "device details, timings and errors", not "no personal data".

| | Text | Words per sentence |
|---|---|---|
| **3A (recommended)** | Orb Combat EX freeze report, made on this device. It lists device details, timings and errors. The game sent nothing. | 9, 7, 4 |
| 3B | Orb Combat EX freeze report: what this device recorded when the game stopped responding. It lists device details, timings and errors, with no name or account. | 14, 12 |

Why 3A: it works for a stranger, for Orb and for a friend. It says what the file is, that it came from one device, what is in it and that the game sent nothing. 3B says more about when it was made, at the cost of length.

## Notes for Performance (not copy; the owner is Performance and Platform)

- **Plain stage names.** The note prints the raw stage id ("page_loaded", "starting"). In plain words for the first line of 2A: `page_loaded` is "starting up", `downloading` is "downloading", `starting` is "getting ready", anything later is "playing". Raw ids belong only in the report body.
- **Build and date in the report.** The report has no build version or date, so whoever reads it cannot tell which build froze. Adding one line each (the build's commit, and the date and time it was made) would make every report usable.
- **The third case.** The note's code covers a lost graphics context only through its fallback sentence ("seemed to stop at stage ..."), which is wrong for that case. The third column above is the text for it.
- **Nothing here needs new code beyond swapping strings** (the NOTE constant, the note's sentences and button labels, the report's first row, and the stage names).

## Checks

| Check | 1A | 2A | 3A |
|---|---|---|---|
| At most 15 words a line | yes | yes | yes |
| No promise of progress, a fix or a date | yes | yes | yes |
| Says nothing is sent or implies it | n/a | the report stays on the device until pasted | "The game sent nothing" |
| Honest if the page never recovers | yes | yes | yes |
| Plain words, no internal terms (stage ids, stall, heartbeat) | yes | yes, with the stage mapping | yes |
| No apology spiral, no hype | yes | yes | yes |
| No animation | yes: static text | yes | n/a |

## Open questions

1. **Legal:** the privacy wording in 2A and 3A ("stays on your device until you choose to paste it somewhere", "The game sent nothing", "device details, timings and errors"). One caution: some phones sync the clipboard, which the game cannot control. The wording says the game sends nothing, which stays true.
2. **Performance:** the stage mapping, the build and date line, and the third case.
3. **EP:** this file is in `docs/community/` because your brief named it. That is outside my owned path `docs/marketing/`. Please either add `docs/community/` to my owned paths or tell me to move the file.
