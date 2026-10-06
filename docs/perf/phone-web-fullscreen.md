# Phones: full screen, Home Screen install and landscape for the web build

Owner: Performance and Platform. 2026-10-06, for the EP. Trigger: a friend's report that landscape on an iPhone in Safari is "kind bad because of Safari's chrome" (the game gets about 600 by 280 pixels). Orb's ruling: on phones the game is landscape only. Nothing was tested on a real phone; section 7 says what was and was not.

Source tags: **[T]** read from caniuse or MDN compat data, the Godot 4.7.2 export template, WebKit's blog or web.dev on 2026-10-06; **[S]** secondary (an issue thread or search excerpt); **[V]** verified by me in headless Chrome's device emulation; **[P]** needs a real phone.

## 1. The short answer

| | iPhone, Safari tab | iPhone, Home Screen app | Android, Chrome tab | Android, installed |
|---|---|---|---|---|
| Browser bars | Stay. The page cannot hide them | **Gone** (standalone) | Hidden by full screen from a tap | **Gone** (fullscreen) |
| Full screen from our code | **No.** The Fullscreen API is iPad-only on iOS [T] | n/a | **Yes**, from a tap [T] | n/a |
| Landscape lock from our code | No (`screen.orientation.lock` unsupported on iOS Safari [T]) | The manifest's `orientation` is honoured on iOS installs [S, one tablet issue; **[P]** on a phone] | Yes, while in full screen [T] | Yes, from the manifest |
| What the player does | Add to Home Screen (iOS 26 opens every Home Screen site as a web app by default [T]) | Launch from the icon | One tap on "I understand, start" | Install, or the same tap |

**For iOS the answer is Add to Home Screen.** There is no code route to hide Safari's bars on an iPhone. For Android, one tap on the gate's own button goes full screen and locks landscape. The rest of this note is how, what it costs, and what could still go wrong.

## 2. What is built, and where it lives

| Piece | File | Status |
|---|---|---|
| Viewport lock, black page, no bounce, no tap flash, `theme-color`, the two "web app capable" tags | `export_presets.cfg`, Web preset, `html/head_include` (the block between `<!--ocx:begin-->` and `<!--ocx:end-->`; Tools' key guard and long-press block are untouched) | **Written** in the working tree. Tested in a scratch export |
| `window.__ocx`: phone state and the full-screen, orientation-lock and wake-lock calls (passive: runs nothing by itself) | source `docs/perf/web-shell/ocx-shell.js`, folded in by `node docs/perf/tools/web-head.mjs --write` (`--check` for CI) | **Written** |
| Web app manifest (`display: fullscreen`, `orientation: landscape`, relative `start_url`, black colours) | `docs/perf/web-shell/manifest.webmanifest` | **Written; not shipped until the patch below lands** |
| Placeholder icons (192 and 512) | `docs/perf/web-shell/icons/`, made by `docs/perf/tools/make-placeholder-icons.mjs` | **Placeholders; Art replaces them** |
| Copy the manifest and icons into `/play/`, drop the manifest link from `/bench/` | `docs/perf/web-shell/build-site.patch` against `tools/build-site.mjs` (Tools' file) | **Proposed.** `git apply --check` passes on today's file |
| Phone-shaped checks in headless Chrome | `docs/perf/tools/phone-emu-check.mjs` | **Written, run** (section 7) |

**The head_include now links `manifest.webmanifest`. Commit it together with `build-site.patch`;** until the patch lands the link is a harmless 404. To turn the link off: `node docs/perf/tools/web-head.mjs --write --no-manifest`.

## 3. Full screen (brief item 1)

- **Android Chrome:** `requestFullscreen` works from a tap; a swipe from the screen edge shows the system bars briefly without leaving full screen, and the back gesture leaves it [T, general behaviour; **[P]**]. **[V]** In emulation the call returned "pending", then "on", with the canvas as the full-screen element.
- **iPhone Safari:** the element Fullscreen API exists only on iPad, and it shows an overlay button there that cannot be turned off [T, caniuse note]. `document.fullscreenEnabled` is therefore false on an iPhone, and `__ocx.enterFullscreen()` returns `'unsupported'` and does nothing. **[V]** with the API removed before load, to mimic iPhone Safari (a simulation, not Safari).
- **The Godot shell today** (read from the 4.7.2 template [T]): viewport meta `width=device-width, user-scalable=no, initial-scale=1.0`; no `viewport-fit`; the canvas is sized by Godot from the window's inner size (project setting "adaptive"), not from CSS `vh`. So `100vh` against `100dvh` does not matter for the canvas: it follows `innerHeight`, which on iOS already excludes the bars. **[V]** the canvas equals the inner size in every emulated size.
- **`viewport-fit=cover` and safe-area insets: not added.** Without it iOS keeps the page inside the safe area, so a notch cannot cover the HUD (**[P]**: I could not see a notch). With it, the HUD would need `env(safe-area-inset-*)` margins passed to UI. That is a UI task for after the first real-phone report, not a shell change.
- **`minimal-ui`:** gone in practice; iOS never honoured it and it is not offered here.
- **Safari's bars cannot be hidden by scrolling** on a locked page [S]; do not chase that.

## 4. Add to Home Screen (item 2)

- **iOS:** since Safari 26 every site added to the Home Screen opens as a web app by default; the user can turn that off per site [T, WebKit blog]. The manifest's `display: fullscreen` is not honoured on iOS and falls back to standalone [S]. Standalone hides the address and tab bars, which is what the friend needs. The status bar and Home indicator remain the system's [S].
- **Android Chrome:** installable with a manifest that has a name, 192 and 512 icons, `start_url` and a `display` of fullscreen, standalone or minimal-ui, over HTTPS [T, web.dev]. The install prompt also wants a tap and 30 seconds on the page [T]. **[V]** Chrome's own `getInstallabilityErrors` returns none for the scratch site and the manifest parses with no errors. A service worker is **not** listed in the criteria I read; the page does not say either way, so treat "no service worker needed" as **[P]** until an Android phone installs it.
- **What it costs us:** one static file and two icons (about 4 KB), no service worker, no cache. **I recommend against Godot's own "Progressive Web App" export option** (`progressive_web_app/enabled`): it adds a service worker and an offline cache, and a cache that outlives a deploy would serve old builds to players while the game changes daily. If offline play is ever wanted it needs its own decision.
- **GitHub Pages:** serves `.webmanifest` as `application/manifest+json` (checked live with `curl -I` on another Pages site) and caches files for 10 minutes. Nothing server-side is needed.
- **Icons:** the live Home Screen and tab icon is **Godot's robot**, because `project.godot` has no `config/icon` and `html/export_icon` is on (checked: the live `index.apple-touch-icon.png`). That is wrong for a store-bound game. **A project icon is needed from Art, set in `project.godot` (Simulation or Tools).** Mine are placeholders for the manifest only.
- **How the player installs:** iPhone: Share, Add to Home Screen. Android: the browser menu's Install app, or Add to Home screen. We cannot make the browser offer it. A one-line hint on the gate or the pause menu ("On iPhone: Share, then Add to Home Screen, for full screen") is UI's call.

## 5. Orientation (item 3)

- **Android:** after full screen, `__ocx.lockLandscape()` asks for landscape. It works only in full screen [T], and the screen turns even if the phone is held upright. **[V]** the call is made and rejection is handled; the lock itself is **[P]** (desktop Chrome in emulation rejects it).
- **iPhone Safari tab:** no lock exists. A "turn your phone" card is the only answer. In an installed iPhone app the manifest asks for landscape ([S], **[P]**).
- **Detecting portrait reliably:** compare `innerWidth` and `innerHeight` on `resize`, with the rule the UI layout already uses (`vp.y > vp.x * 1.05`, `ui_layout.gd`). `__ocx.portrait` holds exactly that, updated on `resize`, `orientationchange` and `fullscreenchange`. Do not use the deprecated `window.orientation`, and do not trust `screen.orientation.type` alone: it can disagree with the window while the browser is mid-rotation. **UI does not need the shell for this**: `UiLayout.portrait` is the same value; use `__ocx.phone` only to avoid showing the card on a tablet or a desktop window that is taller than wide.
- **`__ocx.phone`:** a touch device whose short screen side is under 600 CSS pixels (iPhones 375 to 440, iPads from 744).

## 6. The gate (item 4)

The flashing-effects notice (`ui/widgets/ui_notice.gd`, raised by `UiHud.setup`) is in the game, so it is the first thing shown on every launch: a fresh page, a Home Screen launch and a full-screen re-entry all start a new session, and "nothing is remembered across sessions". **Nothing I built can show anything before it:**
- The shell block is passive. `__ocx` runs no request, no prompt and no full-screen call by itself, and a browser needs a tap for full screen anyway.
- No install prompt of ours exists (`beforeinstallprompt` is not used). A browser's own install menu is outside the page and does not skip the gate.
- **UI wires one call:** the "I understand, start" press runs `JavaScriptBridge.eval("window.__ocx && window.__ocx.phone && window.__ocx.enterFullscreen()")`, guarded by `OS.has_feature("web")`. That is the one tap (Chrome keeps the tap valid for about five seconds, so a call a frame after the press works; Godot's docs say the call must come from an input callback [T]). It runs only after the gate is dismissed, never before.
- **Order I suggest:** gate, then (if phone and portrait) the "turn your phone" card, then How to play. The notice is readable in portrait; the card must not come first.

**Four findings for UI and the EP (not my files):**
1. **The gate card does not fit a short landscape screen. [V] This can lock a player out.** At 844 by 390 (a home-screen app) and 667 by 375 it fits. At **750 by 330 the title is clipped and "Open Settings" is cut off; at 664 by 270 (the friend's Safari) the heading and body are clipped and "I understand, start" is below the bottom edge.** Screenshots: `docs/perf/img/` (see section 7). Safari's bars leave roughly 270 to 340 pixels of height in landscape on iPhones, so on that browser the gate may not be passable. UI needs a card that shrinks or scrolls, and a fallback that a tap or key on a visible area reaches the start button.
2. **The gate is skipped by a substring test on the URL query** (`notice_skipped_by_args`: "bench", "frames", "shot", "nonotice", "flashcap", "study" anywhere in `location.search`). A shared link with a query such as `?utm_content=screenshot` would skip the flashing notice. Add Home Screen: iOS may save the current URL including its query, and a saved `?nonotice` would skip the gate on every launch. The manifest's `start_url` is `./` for Android; iOS behaviour is **[P]**. Suggest UI match these as whole parameter names, not substrings.
3. The `/bench/` page legitimately skips the gate; it is not linked and has `noindex`.
4. The Home Screen icon is Godot's (section 4).

## 7. Other phone-browser problems (item 5)

| Problem | What is done or proposed | Status |
|---|---|---|
| Scroll bounce, pull-to-refresh | `html,body{position:fixed;overflow:hidden;overscroll-behavior:none}` | **[V]** no scroll in any emulated size; **[P]** the bounce itself |
| Pinch zoom | `touch-action:none` on html, body and canvas; `gesturestart` cancelled (iOS ignores `user-scalable=no`) | **[V]** touch-action, scale stays 1; **[P]** a real pinch |
| Double-tap zoom | `touch-action:none` | **[P]** |
| Long-press menu, text selection | Already blocked by Tools' earlier lines | **[P]** |
| Bars reappearing on an edge swipe (Android full screen) | Cannot be prevented; the page sees a `fullscreenchange` when the player leaves full screen, so `__ocx.fullscreen` goes false. Suggest a small "full screen" button in the pause menu that calls `enterFullscreen()` again | **[P]** |
| Audio needs a gesture | The gate is the gesture; Godot resumes audio on the first tap [T, Godot docs]. The iOS silent switch may mute web audio: unchecked, **[P]** | **[P]** |
| Screen sleeping | `__ocx.keepAwake()` (screen wake lock; iOS 16.4+ and Chrome support it [T]). Touch already resets the timer; this matters for a pad-only or long demo. UI calls it after the gate | **[V]** acquires in Chrome; **[P]** on a phone |
| Tab hidden or phone locked | The browser throttles the page; the sim holds on focus loss already [G: platform plan §4] | **[P]** |
| A phone's memory and speed | Unmeasured; Tools' `/bench/` page on a real phone is the first number | **[P]** |

**Verified in headless Chrome's device emulation** (`node docs/perf/tools/phone-emu-check.mjs --site <built site> --shots <dir>`, run on a scratch HEAD export with the new head and the patch): the game boots in every size; the canvas fills the inner size exactly; the page cannot scroll; touch-action is none; the manifest parses with no errors and Chrome lists no installability errors; the full-screen call returns "unsupported" with the API removed, and "on" with the API present; a call with no tap is refused quietly ("denied", no exception); the wake lock acquires. **Not verifiable there:** Safari itself, a notch, browser bars, a real Home Screen install, the system's edge gestures, real touch, audio on iOS, the orientation lock, and anything about speed on a phone. Emulated sizes: 390x844, 664x270, 667x375, 750x330, 844x390, 915x412 and a 1280x720 desktop. The scratch export was imported and exported headless with Godot 4.7.2; no Godot window opened.

## 8. Checklist for Orb or the friend (a real phone; five minutes each)

Use the live link once the commit is deployed. Write "ok" or what you saw.

**iPhone (Safari)**
1. Open the game in Safari, landscape. Can you press "I understand, start"? If not, how much of the card shows? *(finding 1)*
2. Share, Add to Home Screen. Is the icon Godot's robot or ours?
3. Open it from the icon. Are the address and tab bars gone? Does the game fill the screen? Is any part under the notch or the Home bar?
4. Hold the phone upright, then turn it. Does the app rotate? Does it stay in portrait if you turn it back?
5. Pinch and double-tap on the game. Does anything zoom? Pull down from the top: does the page bounce?
6. Is there sound? Flip the silent switch and try again.
7. Leave it alone for the screen-sleep time during a fight with no touching. Does the screen dim?

**Android (Chrome)**
1. Open the game, landscape. Press "I understand, start". Do the bars disappear? (Needs UI's one-line call; until then use the browser menu's full-screen or install instead.)
2. Menu, Install app (or Add to Home screen). Open the icon: full screen? Landscape lock even when held upright?
3. Swipe from an edge in full screen: do the bars come back, and can you return to full screen?
4. Pinch, double-tap, pull down: any zoom or refresh?
5. Sound on. Sleep timer as above.

Send back the phone model, the OS and browser version and, if possible, a screenshot per step.

## 9. What needs whom

- **Tools:** apply `docs/perf/web-shell/build-site.patch` with the head_include commit; later a CI step `node docs/perf/tools/web-head.mjs --check` so the block cannot drift (a proposal, not wired).
- **UI:** the gate card for short screens; the one-line full-screen call after the gate; the turn-phone card (shell state: `__ocx.phone`, `__ocx.portrait`); a pause-menu "full screen" button; an install hint line; the substring skip rule.
- **Art or Simulation (project.godot):** a real project icon; replace the placeholders in `docs/perf/web-shell/icons/`.
- **Legal:** the gate's wording is unchanged; the title in the manifest is "Orb Combat EX" (same as the page title); confirm it with the title decision.
- **Orb or a friend:** the checklist above.

## 10. Sources (read 2026-10-06)

- caniuse data: Fullscreen API (iOS Safari: partial, iPad only, with an overlay button; Chrome Android supported), Screen Orientation, CSS touch-action, Screen Wake Lock, viewport units, `env()` (github.com/Fyrd/caniuse)
- MDN compat data: ScreenOrientation.lock (Safari iOS: not supported; Chrome Android 38); MDN ScreenOrientation.lock page ("typically only enabled on mobile devices, and when the browser context is full screen")
- WebKit blog, "News from WWDC25: Web technology coming in Safari 26 beta" (Home Screen web apps open as web apps by default)
- web.dev, "What does it take to be installable?" (Chrome installability)
- Godot 4.7.2 export template `web_nothreads_release.zip`, `godot.html` and `godot.service.worker.js` (the default shell and the PWA service worker); Godot docs, "Exporting for the Web" (fullscreen and audio need a user event; PWA options)
- [S] GitHub issue threads on iOS installed web apps and the manifest (display fullscreen falls back to standalone; manifest orientation honoured on an installed tablet app), found by search
- GitHub Pages response headers (`.webmanifest` as `application/manifest+json`), checked with `curl -I`
- In the repo: `export_presets.cfg`, `ui/hud/ui_hud.gd`, `ui/widgets/ui_notice.gd`, `ui/core/ui_layout.gd`, `docs/controls/platform-plan.md`, `docs/tools/README.md`, `tools/build-site.mjs`
