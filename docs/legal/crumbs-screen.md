# The freeze breadcrumbs: privacy words, the start line and the report note

Owner: Legal and IP Compliance. 2026-10-26. Screens Performance's park `docs/perf/web-shell/ocx-crumbs.js` and `docs/perf/phone-freeze-2026-10-26.md` (section 4), and Tools' switch (`tools/site.json` "crumbs", off; `docs/tools/site-interim.md`, 6c2f01b1). Read: the report, the head of the script, and the script's lines that touch storage, the user agent and the graphics string. A screen, not legal advice. RL-188; new row p04.

## Verdict: **Pass, with new privacy words and five limits.** A local-only record that is never sent is a light touch, and the design (a switch that is off, a check that fails the page on any network call, a report only on the visitor's tap) is the right one. Two things need care: the privacy sentence must stay true, and the start line and the report need small edits.

## 1. Does "collects and sends no personal data" still fit? **It needs new words.**
The page would keep, on the visitor's own device, a technical record that includes the user agent, screen size, pixel ratio, memory and cores. Taken alone that is not personal data and none of it leaves the device, so "sends no personal data" stays true. But **"collects"** is now arguable (the page does gather and store device facts, even locally), and in the EU and UK, **storing information on a visitor's device is itself regulated, whatever the purpose,** unless it is strictly necessary for the service the visitor asked for (general information; I have not checked the current rules today). A freeze diagnostic is a helpful aid, not strictly necessary, and it is low-risk, but it should be disclosed plainly, which also keeps the sentence true.

**New words for the About page and the page's privacy line, used only while the switch is on:**
> This game sends no personal data and does not use trackers. To help with freezes, the page keeps one small technical record in your browser's storage on this device: the stage it reached, how long it stopped, and basic facts about your browser and screen. The game sends nothing. If it froze and you choose "Copy a report", the text goes only where you paste it. The web version is hosted on GitHub Pages, which keeps its own server logs. The feedback button copies a report to your clipboard for you to paste to Orb; nothing is sent by the game. Clearing this site's data in your browser removes the record.

(American spelling; one sentence about GitHub Pages stays as before. The existing "This game collects and sends no personal data..." line stays exactly as it is **while the switch is off.** Tools' word-for-word check keeps both, keyed to the switch.)
"Does not use trackers" is true of the script as built (no network, no cookies, no third-party script; Tools' check fails the page on any network call). I did not verify that nothing else on the page sets a cookie; Tools should confirm before the sentence is printed.

## 2. The start line (b) and the report note (c) under the owner interim
**No RL number or waiver is needed:** they are not part of the flashing waiver (RL-172) and change no flashing behaviour. What they must not do:
- **The click-through stays the gate.** The line and the note are plain text; neither can start the game, skip the notice or cover its buttons, and on a small phone the notice and its buttons still fit and are reachable with the line and the note showing. The page with the switch on passes Tools' interim check (gate present, lock flag true, no network), and the kill switch and the offline page still work with it.
- **The words are true.** The start line says, "First start takes longer on a phone: the graphics are prepared once. The page may look stuck for a minute; it is still working." Two claims in it need to come out: **"prepared once"** (the shader and audio work runs on every start; a browser may cache some of it, but nothing promises "once") and **"it is still working"** (a real hang looks the same, and Perf could not prove the cause for the friend's phone). Suggested: **"Starting. The first start can take a minute or more on a phone, and the page may look stuck while it loads."** The percentage line ("Downloading 40%") is fine.
- The report note ("Last time the page stopped responding for 22 s while it was at stage X. If it froze for you, copy a report; it stays on this device") is fine: dismissable, shown only after a stall, offered not pushed. American spelling (analyzer, color, gray) and never "safe", "tested" or "compliant".
- **No pin question:** the game code is unchanged, so the pin and the nightly rule are unaffected by the shell script alone. If the freeze fix also changes game code or audio or rendering, that is a pin change under the nightly rule.

## 3. Limits on the report's contents (p04)
The report goes only where the visitor pastes it (to Orb), by the visitor's choice. Inside that:
1. **The visitor sees exactly what will be copied** (the report is shown as plain text in the note, not copied blind), so the choice is informed.
2. **Keep the user agent and the GPU renderer string; they are the useful facts for a graphics freeze.** The GPU string is read **only when the report is made**, as designed. The combination of user agent, screen, pixel ratio, memory, cores and GPU string is a strong device fingerprint, so **it never leaves the device by any route but the visitor's paste, and no copy of it is ever sent by the game** (any future automatic sending stops for me first: it would need consent, a retention rule and a privacy policy).
3. **No identifiers:** no random or persistent ID, no timestamp of the clock (relative times only), no page URL with its query or hash. **Error messages and stack text are shortened and have URLs stripped to the host and path** so a pasted report cannot carry a query string.
4. **One record, replaced each visit.** It is cleared once the visitor has dismissed the note or copied the report, and a clean visit does not leave a stall record behind.
5. **Orb treats the pasted reports as private:** not published, not posted on the page or in the repository, and deleted after use. They contain device facts the visitor sent in good faith.

## 4. The rest
- Children may play a violent free demo; a local-only record with device facts is no profile of a child, and nothing leaves the device. Fine.
- The record sits in localStorage, not a cookie, and needs no banner under the interim's no-promotion, limited-link setting; **if the demo is ever promoted to the EU or UK, ask counsel once** whether a diagnostic record needs a consent prompt.
- Look gate (ADR 0010): the start line is a public page change, so it gets the side-by-side, as Perf says. The words come from Community and Marketing and come back to me.

## Rows
`p04` is in `movegen-banned.json`.
