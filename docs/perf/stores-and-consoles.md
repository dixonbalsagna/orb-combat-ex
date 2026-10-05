# Where this game can be listed, consoles included

Owner: Performance and Platform. Written 2026-10-05 for Orb, through the EP. Docs only: nothing was registered, installed, built or contacted. Every external fact below was read on 2026-10-05 from the pages named in section 9. Anything I could not read or confirm is marked **UNCONFIRMED**, and section 8 lists them all.

Source quality is marked in section 9: **[O]** official page read today, **[S]** secondary (press, forum, search-result excerpt, not an official page), **[G]** repo document. Treat every price as "as of 2026-10-05" and re-check before paying.

## 1. One-page summary

**Straight answer.** PC and browser are open to Orb today for about $100. Every console needs a gate that the PC does not: a platform holder's approval, plus a paid porting layer (Godot has no built-in console export). Xbox and Switch say individuals may apply. PlayStation says a legal entity (a company), with sole traders accepted in Europe only. Whether Orb qualifies depends on where Orb lives and whether they have or will form a company. I do not know either, so I have not guessed.

**Recommended order, with the cost of each step**

| # | Step | Money | Work for one person (estimate, with the agents) | Calendar gate |
|---|---|---|---|---|
| 1 | **Web build, as it is**, on GitHub Pages (live now) | $0 | none | none |
| 2 | **itch.io page** (web build, plus Windows/Linux zips) | $0 to list. 10% default share only if the game is ever paid [O] | 0.5 to 1 day | none |
| 3 | **Steam, Windows and Linux** (macOS later) | **$100 per game**, not refundable unless it earns $1,000, so sunk for a free game [O] | 3 to 6 days (account, store page art, build upload, AI disclosure, age questionnaire) | Tax check 10 to 15 business days; 21 to 30 days between paying and release; 2 weeks of "coming soon" [O] |
| 4 | **Steam Deck Verified** (rides on step 3) | $0 to submit. A Deck to test on is not priced here (**UNCONFIRMED**) | 1 to 2 weeks (glyph rule, text size, 30 fps check) | Valve's review, length **UNCONFIRMED** |
| 5 | **Android**: APK on itch.io first, Google Play second | APK $0. Play $25 one time [O] | 1 to 2 weeks (touch controls are planned for P5, so this may be larger) | New personal accounts: closed test with 12 testers for 14 days [O] |
| 6 | **Xbox** (ID@Xbox plus a porting layer) | Join $0 [S]. Dev kit $0 if the concept is approved, else about $2,000 [S]. W4 Consoles **$800 per year** for one platform [O] | 4 to 8 weeks of work after approval | Application, NDA, concept approval: **UNCONFIRMED** length |
| 7 | **Nintendo Switch** | Portal registration $0 [O]. Fees and dev hardware **UNCONFIRMED**. W4 $800 per year [O] | 4 to 8 weeks, plus performance risk on the weakest target | Separate Switch access application after registration [O] |
| 8 | **PlayStation 5** | **First cost: a legal entity, if Orb has none** (price depends on country, not researched). Then W4 $800 per year [O]. Sony's own fees **UNCONFIRMED** | 6 to 10 weeks of work plus long waits | Sony reviews the studio and the concept, "typically within a few weeks" [S] |
| 9 | **iOS** | $99 per year, and a Mac with Xcode [O] | 2 to 3 weeks | Apple review |

Why this order: steps 1 to 4 cost about $100 in total, run on the machine Orb already has, and reach the handheld (Steam Deck) and a controller on PC. They also produce what every console application asks for: a live game, traction numbers and a store page. Consoles come after, Xbox first because its stated rules are the most open to a solo developer, PlayStation last because its entry rule is the strictest.

**What PlayStation-owning friends can do today** (details in section 2): plug a DualSense into any PC or laptop by USB and play the web build or the Windows build; or play the web build on a phone or tablet. PS Remote Play does not help: it streams a PS5 to other screens, not our game onto the PS5. A PS5 release is not possible today.

**What is unmeasured** (section 6): the real game on a real old laptop, a phone and a Steam Deck. No store page can state honest minimum specs until those exist.

## 2. What PlayStation-owning friends can do today

| Option | Real today? | Notes |
|---|---|---|
| **DualSense on a Windows PC or laptop, USB or Bluetooth, playing the web build or the Windows build** | Yes, in principle. **Not yet verified by us** | The game reads pads through Godot's SDL mapping database (Windows) or the browser Gamepad API (web) [G: `docs/controls/platform-plan.md` §2, §4]. Pad code is in `render/core/main.gd`. The plan says a manual pad pass on each browser is still owed, with the log file `docs/controls/pad-test-log.md`, which does not exist yet. Steam has supported the DualSense since 2020 [S]. |
| **The web build in a browser on a Mac, Chromebook, phone or tablet** | Yes for keyboard. Touch controls are a P5 plan | A friend with any laptop can open the link. |
| **Our game on the PS5 through its own browser** | **No, do not promise it** | Sony said the PS5 would have no web browser. A hidden one was found in 2020 through a social-account link, "for now" [S]. Not an official feature, not tested by us, and not something to put in marketing. |
| **PS Remote Play** | No, wrong direction | It streams a PS4 or PS5 console to a PC, phone or Portal [O]. It does not run PC or browser games on the console. A PC game cannot be added to it. |
| **PlayStation Portal** | No | Remote-player device for PS5 games only [O]. |
| **Xbox Series X|S browser** (for any Xbox friends) | Maybe | The console has the Edge browser, and itch.io lists web games with Xbox-pad support [S]. Untested by us. |
| **Steam Link or cloud streaming from a PC to a TV** | Probably, **UNCONFIRMED** | Not researched. Mention only after a test. |

## 3. What a PS5 release would actually take, step by step

All of this is for a **listing on the PlayStation Store**, not for friends playing. Official Sony pages were not fully readable on 2026-10-05 (one returned 403, one had no body text), so the entry rules come from press coverage and search-result excerpts of Sony's pages [S]. **Confirm every step on the PlayStation Partners site before acting.**

1. **Can Orb apply at all?** Applicants must be a legal entity such as a corporation, company or partnership. Sole traders are accepted in Europe, if over 18 [S]. Orb's country and legal status are unknown to me. **Costs money first if Orb has no company**: forming one is the first paid step, and its price depends on the country (not researched).
2. **Gather the documents** [S]: company details; a corporate-domain email containing part or all of the name (so a registered domain, which costs a few dollars a year, price not researched); a static or VPN IP address; a short project plan (the pitch); proof of legal status identifying directors and officers (certificate of incorporation, latest annual return or financial statement, commercial register entry; passport for sole traders).
3. **Register with PlayStation Partners and wait for approval.** Sony reviews the studio and the concept, typically within a few weeks [S]. It can decline. A free, hobby, AI-disclosed game may or may not suit them (**UNCONFIRMED**, ask Sony's pitch form, not guessable).
4. **Sign the Global Developer and Publisher Agreement** (GDPA) [S]. This unlocks the tools, documentation and the NDA-protected SDK. The fee, if any, is **UNCONFIRMED**.
5. **Get development hardware.** Sony has run a programme loaning one PS5 dev kit and one test kit to newly licensed partners for free, returned within two years [S, 2022 news; may have changed]. Retail price of a kit: **UNCONFIRMED**.
6. **Buy the port: W4 Consoles, PS5 is active, $800 per year for one platform** on the Starter tier (under $300k revenue) [O]. It is "approved middleware" with source access, achievements, trophies and cloud saves, but "Developers must obtain platform-specific approval and dev kits from respective platform holders" [O], so steps 1 to 5 come first. The alternative is a porting studio, price **UNCONFIRMED**. W4's page says porting houses cannot publish unless they own majority IP [O].
7. **Do the port work**: PlayStation input and glyph rules, trophies, save data and sign-in, suspend and resume, memory and frame-rate targets (section 5). Estimate 6 to 10 weeks of work for one person with the agents. This is my estimate, not a measurement.
8. **Age ratings** for each region (ESRB, PEGI and others) [O: Godot docs]. Cost and route **UNCONFIRMED**. The game shows civilian casualties, which may raise the rating.
9. **Sony certification and review**, then release. Fees and timing **UNCONFIRMED**.

**The first step that costs money is step 1 (a legal entity) if Orb has none, and the first fixed price is W4 at $800 a year.** Everything before that is free but needs a company, documents and Sony's approval.

## 4. Store by store

Columns: who may publish, fees and hardware, what Godot 4.7 needs and from whom, certification and ratings, what in this game changes, effort for one person.

### 4.1 itch.io
- **Who and fees.** Anyone with an account. Creators choose the platform share from 0 to 100%, default 10%; PayPal or Stripe fees are $0.30 plus 2.9% per sale; payouts have a $5 minimum. A tax interview is required, 30% US withholding applies to non-US entities unless a treaty reduces it, and a one-time $3 identity-verification fee is mentioned [O]. Whether the $3 and the tax interview apply to a free-only page is **UNCONFIRMED**. Legal's checklist says a free account is enough for free games [G: `docs/legal/pre-store-checklist.md` §5].
- **Web limits.** 1,000 files, 500 MB extracted, 200 MB per file; mobile always opens click-to-launch fullscreen [O]. Our Godot web build is 39.5 MB of wasm (10.1 MB gzipped) plus an 88 KB pack [G: `research/engine-spike/RESULT.md`], inside every limit. Our build is single-threaded and needs no cross-origin isolation [G: `docs/tools/README.md`], which matters because the itch page does not address it.
- **Rating and disclosure.** Fill itch's AI field honestly [G: Legal].
- **Effort.** Half a day to a day. `tools/build-site.mjs` already assembles the site.

### 4.2 The web build, as it is
- Live on GitHub Pages at `dixonbalsagna.github.io/orb-combat-ex/play/` [G]. Free.
- **Limits** [O]: 1 GB site size and a **soft 100 GB a month of bandwidth**. At about 10 MB gzipped per first load, that is roughly **10,000 cold loads a month**. Browser caching helps, but a spike of attention (a streamer, a social post) could cross it. GitHub also says Pages is not for running a business or e-commerce, which fits a free game and does not fit selling one.
- **Effort.** None now. Add an itch.io mirror (4.1) as the overflow route.

### 4.3 Steam (Windows, Linux, macOS)
- **Who and fees.** Individuals and companies both [O]. $100 per product, non-refundable, "recoupable" after $1,000 of adjusted gross revenue [O]. A free game will not recoup it. Identity, tax and bank details; the bank account holder name must match the legal ID; tax review takes 10 to 15 business days [O]. The two pages I read disagree on the wait between paying and release (21 days on the onboarding page, 30 on the Steam Direct page): plan for 30. Two weeks of "coming soon" are required, and the build and store page review takes 1 to 5 days [O].
- **Share.** 30% on a first $10 million, then 25% and 20% [S]. Not stated on the pages I read: **UNCONFIRMED** from Valve.
- **Godot needs.** Our `export_presets.cfg` has only Web and Windows Desktop today. Linux and macOS exports exist in Godot 4.7 [G: engine-spike]; they are not set up or tested here. Steam features (achievements, cloud saves) need a Steamworks plugin such as GodotSteam. Licence and redistribution terms for the Steamworks SDK in a public repo are **UNCONFIRMED**; Legal should read them [G: `docs/legal/pre-store-checklist.md`].
- **Ratings and disclosure.** Valve's AI-content disclosure applies to anything shipped or on the store page [G: Legal checklist]. The age-rating questionnaire is not described on the pages I read (**UNCONFIRMED**).
- **Game changes.** Steam Input glyph images, if the neutral glyph rule (Legal RL-037) allows [G: `docs/controls/prompt-glyphs.md` §1.7]. Save data already goes to `user://`. Add Steam cloud saves later.
- **Effort.** 3 to 6 days of work; the calendar is set by the waits.

### 4.4 Steam Deck
- **Verified requires** [O]: all content reachable with the default controller layout; on-screen glyphs that match the inputs in use, with no keyboard glyphs shown for controller input; text entry through the Steam keyboard or in-game controller entry; a supported resolution; the smallest text at least 9 pixels tall at 1280 by 800, readable at 30 cm; **30 fps at 800p** in the default configuration; no warnings about unsupported hardware; any launcher fully controller-navigable.
- **Where we stand.** Pad support exists [G]; the neutral glyph set is our own, which Legal wants, but "glyphs must match the inputs" may conflict with a position-diamond set. **UNCONFIRMED** whether Valve accepts it, so plan the Steam Input glyph switch the Legal doc already describes. Text size at 800p has not been audited. Frame rate on a Deck has not been measured.
- **Without Verified.** The game can still be "Playable" or untested and run on a Deck.
- **Effort.** 1 to 2 weeks plus a real Deck. A Deck is not priced here (**UNCONFIRMED**).

### 4.5 Xbox (ID@Xbox)
- **Who.** At least 18, sign an NDA, live in a country Microsoft can do business in; "you don't need to be an established studio" [O]. Joining costs nothing, and there are no fees to submit to certification, publish or update [S]. The game concept is approved before the GDK (the Xbox SDK) is released [S].
- **Hardware.** Approved ID@Xbox teams get dev kits free [S]; outside the programme a kit is reported at $2,000 [S, 2025]. A retail console can run builds in developer mode [S]. Neither is confirmed on an official page I could read.
- **Godot.** No built-in export. Route: **W4 Consoles, Xbox Series X|S active, $800 per year** (one platform; $2,000 for all) [O]. Alternatives are the porting studios the Godot docs list (Lone Wolf Technology, Pineapple Works, Olde Sküül, Sickhead Games), though the list I read mostly names Switch work [O: Godot 4.4 docs; the stable-version URL returned 404].
- **Certification.** Microsoft's requirements list is not public on the pages I read (**UNCONFIRMED**). An older UWP route for a separate "Creators" section of the store exists in 2017-era coverage; I could not confirm it still exists, so I am not recommending it.
- **Game changes.** Xbox sign-in and profile, save data through the platform, achievements, suspend and resume, controller-only menus, accessibility. The neutral glyph rule has to be agreed with the platform.
- **Effort.** 4 to 8 weeks of work after approval.

### 4.6 Nintendo Switch and its successor
- **Who.** "You can register even if you are an individual and do not represent a company" [O]. But "Access to Nintendo Switch information requires a separate application after registration", then NDA and terms, a publishing agreement, an age rating, and Nintendo's review [O].
- **Hardware and fees.** Not on the pages I read. A 2017 report put the Switch dev kit near $450 [S, stale]. Today's price and Switch 2 kit terms: **UNCONFIRMED**.
- **Godot.** W4 Consoles: Switch active, **Switch 2 in beta** [O], $800 per year. Porting studios listed by Godot [O].
- **Rating.** Nintendo requires an age rating [O].
- **Game changes.** Switch is the weakest target we would meet, and nothing we have measured says the worst-case scene fits (see section 6). Handheld-size text, touch not required, save data through the platform.
- **Effort.** 4 to 8 weeks, with a performance risk I cannot size.

### 4.7 PlayStation 5
Full steps in section 3. Summary: legal entity (EU sole traders accepted) [S], documents and a pitch, Sony approval, the GDPA, a dev kit (a free loan programme was announced in 2022 [S]), W4 PS5 port $800 a year [O], ratings, Sony certification. PlayStation is the hardest of the three, as the EP said, mainly because of the entry rule.

### 4.8 Android
- **Who and fees.** $25 one-time Google Play registration, identity checked with a government ID and card [O]. New **personal** accounts (created after 13 November 2023) need a closed test with at least 12 testers opted in for the preceding 14 days before applying for production access [O]. An organisation account avoids that rule; its terms were not read. The APK on itch.io has no gate at all.
- **Godot needs.** Android export is built in, via the Android SDK and a signing key. I did not re-read the Godot Android page for this document.
- **Game changes.** The touch schemes are P5 plans [G: `docs/controls/platform-plan.md` §7]. The 30 fps target with reduced effects is accepted for phones [G: `docs/ep/vision.md`]. Mobile frame time is unmeasured.
- **Effort.** 1 to 2 weeks for a first APK, much more for touch and performance work.

### 4.9 iOS
- **Who and fees.** $99 per year; the free account cannot publish [O]. Godot says export needs "a computer running macOS with Xcode" and an Apple developer account [O]. Orb has a Windows PC, so a Mac is needed (cost not researched). C# is experimental there; we use GDScript.
- **Effort.** 2 to 3 weeks and a Mac. Lowest priority.

### 4.10 Others, one line each
- **Epic Games Store.** Reported $100 per game; 100% of the first $1 million per product, then 88/12 [S]. It is curated; whether it would take a free hobby game is **UNCONFIRMED**.
- **Microsoft Store (Windows PC).** Individual registration is free since 2025, $99 for companies [S, Microsoft Windows blog and docs in search results]. Optional.
- **GOG, Game Jolt, Newgrounds, Humble.** Not checked. Say nothing about them until someone does.

## 5. What in this game would have to change

| Area | Today | For stores and consoles |
|---|---|---|
| **Input** | Keyboard, pad and touch code paths exist in `render/core/main.gd`; Godot's SDL database covers Xbox, PlayStation and Switch pads [G] | Pad test pass per browser and per pad; touch schemes at P5; console input layers belong to the port |
| **Glyphs** | One neutral set of our own, by Legal rule RL-037 [G] | Steam Deck Verified and console holders may want their own glyph sets; Legal rules, per platform |
| **Save data** | `user://` JSON, browser storage on the web [G: `docs/ui/hud-spec.md`] | Console save APIs sit behind W4's port; Steam cloud later |
| **Achievements and trophies** | None | Consoles generally require them; Steam wants them. Needs a Game Design list |
| **Performance on the weakest target** | Measured on a fast PC only (section 6) | Real hardware tests are the largest unknown |
| **Text size** | Not audited | Deck: 9 px at 1280 by 800; Switch handheld similar |
| **Content ratings** | Not rated | Fighting, destruction and civilian casualties; Legal and Marketing to assess |
| **Open repo against private platform code** | Public MIT repo is the plan [G: licence docs] | Platform SDKs, NDA'd console code and W4's port source must live in a **private** repo or overlay. W4 gives "full source code" through a private repository [O]. Whether console agreements allow the game's open licence to stay as is, **UNCONFIRMED**: Legal. Orb is reconsidering MIT, so this has to be decided first |
| **AI-content disclosure** | Upfront, everywhere [G] | Each store has its own form; fill each one the same way |

## 6. Minimum and recommended specs for a store page

**What I can state from measurements** (all from the engine spike, a stand-in scene, not the real game [G: `research/engine-spike/RESULT.md`]):

- Spike worst-case scene at 1920 by 1080, vsync off: Godot Compatibility 0.25 ms average (RTX 5070 Ti); Godot web in Chrome 0.79 ms on the RTX 5070 Ti and 3.09 ms average on the integrated Radeon (2 compute units) in the 9800X3D, p95 3.46 ms. The 60 fps budget is 16.7 ms.
- GDScript sim tick on the spike's stand-in: 0.020 ms in game. Projection for the real sim: 0.13 to 0.20 ms on desktop and 0.25 to 0.38 ms in a browser on an old laptop CPU (a projection, not a measurement).
- Downloads: Windows exe 109 MB; web 10.1 MB gzipped.

**What a store page may honestly say today:** "Tested on" one high-end PC and its integrated GPU. Not a minimum spec.

**Provisional placeholders, to be replaced after the section 7 tests** (do not publish):
- Minimum: 64-bit Windows 10, Linux or macOS; a CPU of about 2015; any GPU that supports OpenGL 3.3 or WebGL2 (the Compatibility renderer's target [G: ADR 0001]), integrated is fine; 4 GB RAM; about 500 MB disk. Memory use is unmeasured, so the RAM figure is a guess.
- Recommended: a 2020-era four-core CPU, a discrete or recent integrated GPU, 8 GB RAM, 1080p at 60 fps.

**Unmeasured, and needed first:**
1. The real game (not the spike scene) on the canonical worst-case scene from my wave-1 brief. **That brief is still open**: `docs/perf/budgets.md` and the timing scripts were never written, because my session stopped at the usage limit.
2. A real old laptop (the spike's integrated Radeon is the 9800X3D's own 2-CU graphics, far newer than "old").
3. A phone (Android and iPhone), single-threaded web build included.
4. A Steam Deck at 800p.
5. Peak memory (CPU RAM and VRAM), which every console and mobile target caps.
6. Anything on Switch or PS5 hardware.

## 7. What each platform would test, and who does it

| Target | Test | Who owns it | Needs |
|---|---|---|---|
| Old laptop | Worst-case scene, 30 s after warm-up, p50/p95/p99 | Performance, on borrowed hardware | A real machine (Orb's friends?) |
| Phone | Same scene, web build in Chrome and Safari | Performance | A real phone |
| Steam Deck | Same scene at 800p, native Linux build and Proton | Performance | A Deck, and a Linux export preset |
| Console | After a dev kit exists | Port | Platform approval first |

## 8. Unconfirmed items

1. W4 Consoles: whether it can be bought before platform approval, and whether it needs a registered company (the pricing page lists size tiers, not entity requirements).
2. PlayStation: current entry rules, fees, dev kit terms, certification, AI-content policy, whether the loan programme still runs. The official page could not be read.
3. Xbox: fees for certification, dev kit price and terms, retail dev mode, certification requirements. Read from secondary sources only.
4. Switch: fees, dev hardware, Switch 2 terms, approval timing.
5. Steam: revenue-share tiers (secondary), the age-rating questionnaire, how Valve treats a neutral glyph set, the Steamworks SDK licence in a public repo, the 21 versus 30 day wait.
6. itch.io: whether the $3 verification and the tax interview apply to a free-only page.
7. Epic, GOG and others: acceptance of a free hobby game.
8. Costs of a legal entity, a registered domain, a Mac and a Deck.
9. Orb's country, age and legal status, which decide Xbox, Switch and PlayStation eligibility.
10. Whether console agreements allow the game's chosen open licence.
11. A DualSense on our game: not yet tested by us.

## 9. Sources, all read 2026-10-05

[O] official page, [S] secondary.
- itch.io payments: https://itch.io/docs/creators/payments [O]; HTML5 limits: https://itch.io/docs/creators/html5 [O]
- Steam Direct: https://partner.steamgames.com/steamdirect [O]; Steamworks onboarding: https://partner.steamgames.com/doc/gettingstarted/onboarding [O]; Steam Deck compatibility: https://partner.steamgames.com/doc/steamdeck/compat [O]
- GitHub Pages limits: https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits [O]
- W4 Consoles pricing and status: https://www.w4games.com/w4consoles [O]
- Godot console docs (4.4): https://docs.godotengine.org/en/4.4/tutorials/platform/consoles.html [O]; iOS export: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html [O]
- ID@Xbox: https://developer.microsoft.com/en-US/games/publish and https://developer.microsoft.com/en-US/games/publish/id/welcome [O]; dev kit and ID@Xbox terms: PureXbox and TweakTown reports (2025) [S]; Xbox browser and HTML5 games: thexboxhub.com [S]
- Nintendo Developer Portal: https://developer.nintendo.com/ and https://developer.nintendo.com/the-process [O]; Switch dev kit price: Nintendo Insider (2017) [S]
- PlayStation Partners: https://partners.playstation.net/ (no body text) and https://www.playstation.com/en-us/develop/.1/ (403); entry rules from Game World Observer (2022), 80.lv and search-result excerpts of Sony's pages [S]; Remote Play: https://www.playstation.com/en-us/remote-play/ [O]; hidden PS5 browser: Screen Rant (2020) [S]
- Apple Developer Program: https://developer.apple.com/programs/ [O]; Google Play registration and testing rule: https://support.google.com/googleplay/android-developer/answer/6112435 and https://support.google.com/googleplay/android-developer/answer/14151465 [O]
- Steam revenue share: Game Informer (2018) and others [S]; Epic Games Store terms: Epic's news post and press [S]; Microsoft Store individual fee: Microsoft Windows developer blog, 2025-09-10 [S]
- In-repo: `CLAUDE.md`, `docs/ep/vision.md`, `docs/decisions/0001-engine-choice.md`, `docs/decisions/0005-lean-team-and-token-discipline.md`, `docs/controls/platform-plan.md`, `docs/controls/prompt-glyphs.md`, `docs/legal/pre-store-checklist.md`, `docs/tools/README.md`, `research/engine-spike/RESULT.md`, `research/engine-spike/results/final/summary.md`.

## 10. Added 2026-10-05 after Legal's go-to-market piece (`docs/legal/go-to-market.md`, RL-088)

Legal's facts that touch this document and agree with it: platform code stays in a **private** repo whichever licence shape Orb picks; Godot cannot publish console templates; Steam Direct is $100 a product, 30 days from fee to release, a public Coming Soon page for two weeks, review 1 to 5 days, tax interview, bank and identity check; age ratings come through Steam's content survey and IARC on Xbox, Nintendo and Google Play; Legal found no public AI rule for the console stores. The two Steam waits in section 4.3 (21 versus 30 days) resolve to Legal's 30.

### 10.1 The stores and their order
Section 1's table is the order: web build, itch.io, Steam (Windows, Linux), Steam Deck Verified, Android, then Xbox, Switch, PlayStation 5, iOS last. Nothing past Steam starts until Orb answers Legal's open question 9 (a private platform repo and a porting firm) and the entity question below.

### 10.2 Whose account holds the Steam listing: a question for Orb
Valve accepts an individual or a company; the bank account holder name must match the legal ID [O: Steam Direct, Steamworks onboarding]. Legal's wording: an individual with "Orb" as the public name, or a company later. **Question for Orb: should the Steam listing be held by you as an individual, or by a company you form?** Why it matters beyond Steam: PlayStation needs a legal entity (EU sole traders excepted), so choosing "individual" for Steam does not carry over to PlayStation. No personal details belong in this repo, and I have asked for none.

### 10.3 Build pipeline: public repo plus private platform repo
Today (read from the repo, 2026-10-05): one public repo. `.github/workflows/ci.yml` runs on free GitHub runners with no secrets: QA regression suite, frozen JS core record, data jobs, then `site` (Godot web export, `tools/build-site.mjs`) and `deploy` to GitHub Pages [G: `docs/tools/README.md`]. Export presets exist for Web and Windows Desktop only.

Proposed (for Tools and Legal; not a change):
1. **Public repo** keeps game code, data, art, QA, and the web and plain desktop export presets. Nothing from any SDK, platform agreement, W4 source or signing key enters it (Legal's rule).
2. **Private platform repo**, a private GitHub repo owned by Orb and outside this folder, holds: the Steamworks plugin and its configuration, console port source from W4 or a porting firm, signing keys and store credentials, and per-platform export presets. It consumes the public repo as a git submodule or a pinned tag, never the other way round.
3. Store uploads run from the private repo's CI or by hand with `steamcmd`. The public CI keeps its no-secrets rule.
4. A release is a tag of the public repo plus a tag of the private repo, so any store build is reproducible. The determinism golden hashes, already checked in the public CI, are the gate before any store build.
5. Steam Deck and desktop Linux need a Linux export preset in the private repo's list; it does not exist yet.

### 10.4 Does any build collect data today?
I searched `render/`, `sim/`, `ui/`, `audio/`, `tools/`, `data/`, `export_presets.cfg` and `project.godot` on 2026-10-05 for network and telemetry calls (`HTTPRequest`, WebSocket, `fetch`, analytics, crash upload, beacons) and read the web export's header include. **Result: no analytics, accounts, crash upload or network requests in the game, and no third-party scripts, fonts or CDN links in the web shell.** Details:
- **Feedback panel** (`ui/widgets/ui_feedback.gd`): on the player's click it opens a GitHub "new issue" page in their own browser with a pre-filled body they can read first. The game sends nothing. Legal should still read it against "no data collection": it is a user-initiated link to a third party, not collection by us.
- **Web build reads** the browser's user-agent string and display scale (`ui_feedback.gd`, `ui_hud.gd`) to lay out the interface and fill the issue text. Both stay on the device unless the player submits an issue.
- **Hosting:** GitHub Pages logs visitors' IP addresses on its own servers (Legal's privacy note). We cannot turn that off on Pages.
- **Steam later** gives us the Steam ID only if we use a Steamworks feature; no build does yet.
- **Limit of this check:** a text search of the repo, not a network capture. Before any store build, Tools or QA should load the built site with network logging on and confirm zero requests beyond the site's own files.

### 10.5 The Steam Deck plan
1. **Build.** Add a Linux export preset (native) and keep the Windows build as a Proton fallback. Neither is tested.
2. **Controls and glyphs.** Pad support exists. The neutral glyph set (RL-037) has to meet Valve's "glyphs must match the inputs in use" rule [O]. Plan the Steam Input glyph switch Legal already described, behind the same lookup in `docs/controls/prompt-glyphs.md`, once Legal has read the terms for Steam's glyph images.
3. **Text.** Audit the smallest text at 1280 by 800 against Valve's 9-pixel rule [O].
4. **Performance.** Valve's bar is 30 fps at 800p in the default configuration [O]. We have no Deck number. Until a Deck is borrowed, the best proxy is the CPU-throttled web bench (10.6).
5. **Submit.** Valve reviews once the Steam page is live. Timing **UNCONFIRMED**.
6. **Fallback.** If it is not Verified, the game still runs as Playable or untested, and the store page says what was tested.

### 10.6 Correction to section 6: an old-laptop proxy already exists
Section 6 says nothing measures an old laptop. Tools has built a bench page and a script: `https://dixonbalsagna.github.io/orb-combat-ex/bench/` runs the web build with fixed 60 Hz steps and a fixed seed and reports frame times, and `node tools/bench-web.mjs --dir build/site --cpu-throttle 4,6 --floor` runs it under Chrome's CPU throttle [G: `docs/tools/README.md`, "The bench page and the old-laptop range"]. It is a range, not a measurement: the throttle models a slower CPU, not a weak GPU, memory or a hot laptop, and I have not run it. The one-click page on a friend's real old laptop or phone is the cheapest real number, and the first thing to ask Marketing's friends for. The wave-1 brief remains the plan for the canonical worst-case scene.

## 11. Needed from Marketing and Legal (through the EP)

- **Legal:** do console agreements and the Steamworks SDK terms allow the game's open licence; the private-repo rule for platform code; ratings exposure from civilian casualties; platform AI-content policies; whether a neutral glyph set passes Steam Deck Verified; the entity question.
- **Marketing:** the audience and the store-page text; which of Orb's friends can lend a Deck, an old laptop or a phone; sales expectations that the cost table here should be set against.
- **Orb (via the EP):** country and whether Orb is 18 or over (Xbox needs it); whether Orb has or will form a company; whether Orb has a Mac.
