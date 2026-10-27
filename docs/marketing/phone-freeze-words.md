# Phone freeze: the words for the demo's start line, note and report

Status: draft, private. Version 2, 2026-10-26, after Legal's screen (`docs/legal/crumbs-screen.md`, RL-188). Not yet re-read by Legal. Written by Community and Marketing for the EP. Nothing here is in the page. Sources: `docs/perf/phone-freeze-2026-10-26.md`, the strings in `docs/perf/web-shell/ocx-crumbs.js`, and Legal's screen. American spelling.

Rules these lines follow: honest, calm and short; at most 15 words a line where it can be done; no hype; no apology spiral; no promise of a fix, a date or progress; no animation; written as if nothing is sent, because nothing is; never "safe", "tested" or "compliant"; and, from Legal, **plain text that never covers the click-through's buttons on a small phone**.

## What changed in version 2

- The start line no longer says "prepared once" or "it is still working": Legal struck both ("the work runs on every start"; "a real hang looks the same"). Legal's own suggested line is now option 1A.
- The note is shorter, because it must leave the notice and its buttons clear on a small phone (see "Space on a small phone").
- New strings for Legal's first limit: the visitor sees exactly what will be copied.
- I withdrew my suggestion to add a date to the report: Legal's third limit bars any clock timestamp.

## 1. The start line, shown before the heavy start

The script shows the stage name, a period, then this text: "Starting. ", "Downloading 40%. " or "Preparing the game and its graphics. ". It stays on screen while the page is frozen, so it cannot say anything about progress, and it must stay true if nothing ever changes.

| | Text | Words per sentence |
|---|---|---|
| **1A (Legal's wording)** | The first start can take a minute or more on a phone, and the page may look stuck while it loads. | 20 (one sentence) |
| 1B (shorter) | First start can take a minute or more on a phone. The page may look stuck while it loads. | 11, 8 |

1A is already Legal's suggestion, so it needs no further clearance, but it is 20 words in one sentence. 1B says the same in two short sentences, under the 15-word guide, and uses Legal's phrase "may look stuck while it loads". My pick is 1B, if Legal agrees; 1A otherwise.

**Optional last sentence for either:** "Reloading starts the wait over." (5 words). It is true and it tells the player the one useful thing. Legal has not seen it, so it is not in either option.

"A minute or more" is what Performance measured: 22 to 57 seconds on this PC and a throttled CPU, and 1.5 to 2.5 minutes possible on a low-end phone.

## 2. The next-load note, with its two buttons

The note shows on the next visit if the last one stalled for 5 seconds or more, closed before the game was running, or lost its graphics context. Fill in the seconds; the stage in plain words is optional (mapping below). Legal found the current note fine and asked only for American spelling and the banned words.

### Space on a small phone

The note is fixed at the top and wraps. At 13 pixels on a 360-pixel-wide phone, about 35 words runs to five or six lines, plus buttons that can wrap to a seventh. In landscape (844 by 390) that is a fifth of the height, on top of Legal's long flash notice. So the short options below are the recommended ones, and Tools' interim check (the notice and its buttons still reachable with the note showing) should be run at the smallest sizes.

| | A stall of known length | The game stopped early | The phone took the graphics away |
|---|---|---|---|
| **2A (recommended, short, about 19 words)** | Last time the game froze for 22 seconds. A copied report stays on your device until you paste it somewhere. | Last time the game stopped before it finished starting. A copied report stays on your device until you paste it somewhere. | Last time your phone took the graphics away from the game. A copied report stays on your device until you paste it somewhere. |
| 2B (fuller, about 34 words) | Last time the game stopped responding for 22 seconds while getting ready. If it froze for you, you can copy a report. It stays on your device until you choose to paste it somewhere. | Last time the game stopped before it finished starting. If it froze for you, you can copy a report. It stays on your device until you choose to paste it somewhere. | Last time your phone took the graphics away from the game. If that happened to you, you can copy a report. It stays on your device until you choose to paste it somewhere. |

Sentence lengths: 2A is 8 and 13 words in the first case (9 and 13, 11 and 13 in the others); 2B is 12, 10 and 13. Both say the report stays on the device until the visitor pastes it, in the words the EP asked for, and neither says "sent", "upload" or "share".

**Buttons:**

| | Main button | Other button | After the main button |
|---|---|---|---|
| **2A** | Copy a report | Dismiss | Copied |
| 2B | Copy report | Not now | Copied to your clipboard |

If the browser blocks the copy: **"Couldn't copy. Press and hold the text to select it."** (9 words).

### Showing the visitor what will be copied (Legal's limit 1)

Legal asks that the report is shown as plain text in the note, not copied blind. Proposed strings for that step:

| Where | Text |
|---|---|
| Above the shown report | This is exactly what will be copied: |
| Buttons under it | Copy / Close |
| After Copy | Copied. Paste it where you want to send it. |

On a small phone the shown report should scroll inside its own box, with the buttons above it, so they stay reachable.

## 3. The report's opening line

Whoever receives the pasted text should know at once what it is, who made it and what it holds. The report holds the browser string, screen, pixel ratio, memory, cores, the graphics name, the last stage, stall lengths, visibility changes, context events and shortened error messages. It holds no name, account, location, contact details, clock time or page address, so the line says "device details, timings and errors", not "no personal data".

| | Text | Words per sentence |
|---|---|---|
| **3A (recommended)** | Orb Combat EX freeze report, made on this device. It lists device details, timings and errors. The game sent nothing. | 9, 7, 4 |
| 3B | Orb Combat EX freeze report: what this device recorded when the game stopped responding. It lists device details, timings and errors, with no name or account. | 14, 12 |

3A works for a stranger, for Orb and for a friend. 3B says more about when it was made, at the cost of length.

## Notes for Performance (not copy)

- **Plain stage names.** The note prints the raw stage id ("page_loaded", "starting"). In plain words: `page_loaded` is "starting up", `downloading` is "downloading", `starting` is "getting ready", anything later is "playing". Raw ids belong only in the report body. The 2A options do not need the stage at all.
- **Build in the report.** The report does not say which build froze. One line with the build's commit would make every report usable. A date and time would be a clock timestamp, which Legal's limit 3 bars; relative times only.
- **The third case.** The code covers a lost graphics context only through its fallback sentence ("seemed to stop at stage ..."), which is wrong for that case. The third column above is the text for it.
- **Nothing needs new code beyond swapping strings**, plus the "shown before copying" step from Legal's limit 1.

## Checks

| Check | 1A / 1B | 2A / 2B | 3A / 3B |
|---|---|---|---|
| At most 15 words a line | 1A: no (20, Legal's own); 1B: yes | yes | yes |
| No "prepared once", no "still working", no promise of progress, a fix or a date | yes | yes | yes |
| Honest if the page never recovers | yes | yes | yes |
| Says or implies nothing is sent | n/a | the report stays on the device until pasted | "The game sent nothing" |
| Plain words, no internal terms | yes | yes | yes |
| No "safe", "tested" or "compliant"; American spelling | yes | yes | yes |
| No apology spiral, no hype | yes | yes | yes |
| Short enough to leave the click-through's buttons clear on a small phone | yes (static, one line or two) | 2A yes; 2B borderline | n/a (not on screen) |

## Open questions

1. **Legal:** 1B in place of 1A, and the optional "Reloading starts the wait over."; the privacy wording in 2A, 2B and 3A (some phones sync the clipboard, which the game cannot control, so the wording claims only that the game sends nothing); the strings for showing the report before copying.
2. **Performance and Tools:** the stage mapping, the build line, the third case, and the layout check at the smallest sizes with the note showing.
3. **EP:** this file is in `docs/community/` because your brief named it. That is outside my owned path, `docs/marketing/`. Please either add `docs/community/` to my paths or tell me to move it.
