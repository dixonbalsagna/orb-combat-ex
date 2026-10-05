# Store copy draft: copy, tags, art and trailer plan, testimonials, claims

Status: draft, private, not reviewed by Legal. Nothing here is published, posted or sent. Written 2026-10-05 by Marketing, for Legal's review as asked in `docs/legal/go-to-market.md` ("Needs from Marketing"). Companion to `go-to-market-plan.md`.

Rules this draft follows (Legal, `docs/legal/go-to-market.md` sections 1 and 7):
- The AI statement is Legal's text, as written, and the same everywhere. Never "human-made", "handcrafted", "hand-drawn", "composed by", "no AI" or "AI-free".
- No implied endorsement by Valve, itch.io, platform holders, Godot, Anthropic or Suno.
- No franchise comparisons in text, tags or keywords. No "clone", "tribute" or "parody". Genre words are free: "anime energy brawler", "fighting game".
- No "open source" for the project. At most "open-source code", and only if Orb picks Legal's shape A or C.
- "[Title]" stands for the public title. It is not decided (OrbCombat clash). **No store page until Orb decides to contact the OrbCombat author or change the title.**
- Square brackets are facts to confirm on the day. Anything in brackets is not to be published until it is true and checked.

Open questions are at the end.

## A. Draft store copy

### A1. itch.io page (Stage 1b; written to be true of the live build today)

**Title:** [Title]

**Short description** (check itch.io's length limit): Play free in your browser: a side-on energy brawler where every press is a blow and buildings break in stages.

**Body:**

> **Play free in your browser. No install.**
>
> [Title] is a side-on energy brawler for one or two players. Pick a stance, press to strike, and watch the world pay for it: buildings break in four stages, craters stay where they land, and the planet has no edges. Fly one way and you come back round.
>
> **What you can try today**
> - Fight an AI opponent, or a friend on one keyboard [or two controllers].
> - Five stances that change how your presses play out.
> - Two fighters with different personalities.
> - A different opening to each fight.
>
> **What it is not yet.** This is an early build. There are two fighters, no online play, and [music is still being made]. Controls for [keyboard, controller and touch] are in; tell us where they let you down.
>
> **How this game was made.** [Legal's short form, exactly as in `docs/legal/go-to-market.md` section 1.]
>
> **Privacy.** This game collects no personal data. It is not made for children under 13. [Confirm for the browser host's server logs: Platform.]
>
> **Feedback.** [A private feedback target, not Orb's personal email: open question, `docs/ep/orb-review-list.md`.]

**Fields:** generative-AI field Yes for graphics, sound, text and dialogue, and code. Tags in section B.

### A2. Steam page (Stage 2; a skeleton, because most of it depends on what exists by then)

**Short description** (check Steam's length limit; about 200 characters here): Play a side-on energy brawler where every press is a blow. Choose a stance, break buildings in four stages and fight across a planet with no edges. [For one or two players.]

**About This Game (skeleton):**

> [One paragraph: the same pitch as A1.]
>
> **Features** (only what is in the build on release day)
> - [N] fighters, each with a different relationship to the destruction around them.
> - Five stances, and a fight director that choreographs the exchange you choose.
> - A world that wraps all the way round, with buildings that break in stages.
> - [Versus on one screen] [Versus against the AI] [Training]. Modes only if they exist.
> - [Controller support] [Steam Deck: only after the badge is awarded].
>
> **How this game was made.** [Legal's short form, exactly.]
>
> [Content note matching the Content Survey: cartoon violence, destruction, civilian casualties.]
>
> [Title] is a trademark of [holder: Orb's decision]. [System requirements: Platform.]

**Steam Content Survey:** pre-generated AI content, yes (art, animation data, dialogue, UI text, music); live-generated, no. Answer the violence section including civilian deaths and destruction.

## B. Tags and keywords

Steam tags (check the maximum and the exact tag names in Steamworks; each one only if true on release day):

| Tag | Condition |
|---|---|
| Fighting, Action | true today |
| Anime | allowed as a genre word (Legal, section 7) |
| Local Multiplayer, PvP | true if one-screen versus is in the build |
| 2.5D | true today (side-on presentation); Art to confirm the word |
| Destruction | true today |
| Indie, Singleplayer | true |
| Controller | only after controller play is tested |
| Fast-Paced | judgement; check in playtests |
| Flight, Physics | only if a player would call them true; verify |
| Free to Play | only if the Steam release is free |

itch.io tags (check its limit): fighting, action, local-multiplayer, anime, destruction, godot, plus its browser classification. The AI tag comes from the AI field, not from us.

Hashtags and search phrases that are fine: #fightinggame, #indiegame, #indiedev, #gamedev, #godotengine, #madewithgodot, #anime, "energy brawler", "side-on fighter", "local versus", "destructible".

**Never in text, tags, keywords, hashtags, handles or alt text:**
- any franchise, character, move or place name, "Z", "Super ___", "Saiyan", "Dragon", "Ball", "Kai", "ki" as a player-facing word, "power level", "scouter", "Final ___";
- "Breakers", "Meridian", "KAI", "Lemming Ball Z", "OrbCombat", "Madness Combat";
- "spiritual successor", "tribute", "parody", "clone", and "like", "inspired by" or "for fans of" followed by a franchise or character;
- "open source" for the whole project; "human-made", "handcrafted", "hand-drawn", "composed by", "no AI", "AI-free";
- "official", "licensed" or "exclusive" for the music; "first" and "best" claims; anything implying endorsement.

## C. Capsule art and trailer plan: where each asset comes from

Every asset gets a row in `docs/legal/asset-origins.md` (tool, model, date, prompt location) before it goes on a page. Legal reviews each against the claims list in section E. Image sizes are taken from Steamworks' graphical-assets page on the day, not from here.

| Asset | Made from | Made with | Origin record | AI disclosure | Hours (estimate) |
|---|---|---|---|---|---|
| Screenshots (5 to 8 for Steam, a few for itch.io) | Real captures of the build at a recorded version, in the moments listed below | The game, plus a screen or headless-browser capture tool (a tool, not content) | Capture date, build commit and scene | Covered by the page statement | 2 |
| Capsule art (header, small, main, vertical) and library hero and logo | One real capture, plus the title lettering | Art creates the logo and lettering with AI tools, or Orb picks a licensed font from the register | Logo: tool, model, date, prompt location, what Orb changed. Font: a `licence-register.md` row | Store-page statement covers it. Say "AI-made" in the origin log | 3 to 4 |
| itch.io cover and GIFs | Real captures | As screenshots | As screenshots | As above | 1 |
| Trailer (30 to 60 seconds) | Real captures only. No concept art, no mock-ups, no stock footage | A free editor (tool recorded). The music is the game's own Suno track, from the track log (paid-plan date and kept originals) | Footage: build version and scene list. Music: the Suno record (Legal section 5; Legal to confirm trailer use is within Suno's terms) | End card carries the statement. No voiceover, so "[There is no voice acting]" stays true | 4 to 6 |

**Screenshot and trailer moments** (each must be true of the build on the day):
1. The opening: two fighters arrive, the world behind them.
2. A stance exchange with the HUD showing the five stances.
3. A building going down through its four stages.
4. A beam or heavy blow leaving a crater.
5. A two-player moment, with the other player's permission.
6. The world wrapping: a fighter leaves one edge and returns round the other side.
7. End card: title, "Play free in your browser" [if so], Legal's statement.

**Trailer rules:** no franchise reference in captions, no on-screen claim that is not in section E, no balance numbers, no fake reaction clips, no "coming soon" features, no quotes unless they are in section D. Placeholder names (KAI, VORR) must not appear: the capture hold (RL-002, RL-014, public-readiness M7) applies until Legal lifts it.

## D. Planned testimonials

None are planned today. Word of mouth from friends ("friends are excited") is not a quote and is never turned into one.

If real quotes arrive, each gets a row before use:

| Quote (exact) | Who | Connection to Orb (stated beside the quote) | Permission and date | Message kept | Legal status |
|---|---|---|---|---|---|
| (empty) | | | | | |

Rules: real people who really played; connection stated, for example "a friend of the developer"; never presented as an independent review; no one asked for a positive review; no keys, gifts or favours traded for reviews; a keyed review stays labelled by Steam.

## E. Every claim the copy makes

Verify each on the day it is published against the live build, then Legal marks it.

| ID | Claim (as in the copy) | Used in | Evidence | Verify | Legal status |
|---|---|---|---|---|---|
| C1 | Free to play in your browser, no install | A1, trailer end card | live build URL | open it in three browsers | unreviewed |
| C2 | A side-on energy brawler | A1, A2 | live build | none | unreviewed |
| C3 | For one or two players | A1, A2 | docs/design/modes.md; live build | two-player on one screen works | unreviewed |
| C4 | Every press is a blow | A1, A2 | docs/design/melee-press-feel.md; commit 5a0d527 | confirm the brawl slice is deployed | unreviewed |
| C5 | Buildings break in four stages | A1, A2, trailer | docs/rendering/building-stages.md | play a fight and watch one building | unreviewed |
| C6 | Craters stay where they land | A1 | pillars.md, pillar 4 | check in the build | unreviewed |
| C7 | The planet has no edges; you come back round | A1, A2, trailer | pillars.md, pillar 1; qa seam tests | fly across the seam in the build | unreviewed |
| C8 | Five stances | A1, A2 | ui/data/stances.json; HUD | count them on the HUD | unreviewed |
| C9 | Two fighters with different personalities | A1 | docs/narrative; pillar 5 | play both | unreviewed |
| C10 | A different opening to each fight | A1 | docs/narrative/dynamic-intros.md | play several fights | unreviewed |
| C11 | Early build: two fighters, no online play | A1 | live build; open-questions Q9 | none | unreviewed |
| C12 | [Controller or touch controls] | A1, A2 | docs/controls | test each device | unreviewed |
| C13 | [N] fighters | A2 | roster at release | count them | do not claim until true |
| C14 | [Versus, AI, Training modes] | A2 | modes.md; build | only modes that exist | do not claim until true |
| C15 | How this game was made (Legal's statement) | A1, A2, README, credits, descriptions | docs/legal/go-to-market.md section 1; asset-origins.md | facts match the origin log; Suno paid-plan records | Legal's own text |
| C16 | [There is no voice acting] | A1 statement | Orb to confirm | confirm | unreviewed |
| C17 | Nothing is generated by AI while you play | A1 statement | design: no live generation | confirm with Orb | unreviewed |
| C18 | This game collects no personal data | A1, README | Legal section 6; Platform to confirm | no analytics; host logs | unreviewed |
| C19 | Not made for children under 13 | A1 | Legal section 6 | Orb's audience answer | unreviewed |
| C20 | [Title] is a trademark of [holder] | A2 | after the title decision | only if the holder line is decided | do not claim until true |
| C21 | "Open-source code" | README | licence decision | only under shape A or C | do not claim until true |
| C22 | Steam Deck Verified | none today | Valve's badge | only after it is awarded | do not claim until true |

## Open questions

1. What is the public title? (Blocks every page. Orb decides: contact the OrbCombat author, or change it.)
2. Which licence shape? (Blocks C21, the repo, any money.)
3. Is there any voice acting, and will anything ever be generated while the game runs? (C16, C17; Legal's questions 5 and 6.)
4. Where does feedback go? A private target, not Orb's personal email.
5. Is the browser build's host free of third-party scripts and logs only what is needed? (C18; Platform.)
6. When does Legal lift the capture hold so real screenshots and clips can be made?
