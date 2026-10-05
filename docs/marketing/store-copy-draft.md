# Store copy draft: copy, tags, art and trailer plan, testimonials, claims

Status: draft, private. Screened by Legal as "clear with six edits" (`docs/legal/store-copy-screen.md`, 2026-10-05); the edits are applied here. Not a clearance, and nothing here is published, posted or sent. Written 2026-10-05 by Marketing. Companion to `go-to-market-plan.md`.

Rules this draft follows (Legal: `docs/legal/go-to-market.md` sections 1, 7 and 10, and `store-copy-screen.md`):
- The AI statement is Legal's text, as amended, and the same everywhere. Never "human-made", "handcrafted", "hand-drawn", "made by hand", "composed by", "no AI" or "AI-free".
- No implied endorsement by Valve, itch.io, platform holders, Godot, Anthropic or Suno. No "powered by", "in partnership with" or "approved by".
- No franchise comparisons in text, tags or keywords. No "clone", "tribute" or "parody". Genre words are free: "anime energy brawler", "fighting game".
- No "open source" for the project. At most "open-source code", and only if Orb picks Legal's shape A or C.
- "[Title]" stands for the public title. It is not decided (OrbCombat clash). **No store page until Orb decides to contact the OrbCombat author or change the title.**
- Square brackets are facts to confirm on the day. Anything in brackets is not published until it is true and checked.
- The opponent is "a computer-controlled opponent" (or "CPU opponent"), never "an AI opponent", so it is not read as a generative-AI claim.

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
> - Fight a computer-controlled opponent, or a friend on one keyboard [or two controllers].
> - Five stances that change how your presses play out.
> - Two fighters with different personalities.
> - A different opening to each fight.
>
> **What it is not yet.** This is an early build. There are two fighters, no online play, and [music is still being made]. Controls for [keyboard, controller and touch] are in; tell us where they let you down.
>
> **How this game was made.** [Legal's short form, exactly as in `docs/legal/go-to-market.md` section 1, including the line that the procedural systems are ordinary code, not AI models.]
>
> **Privacy.** This game collects and sends no personal data. The web version is hosted on GitHub Pages, which keeps its own server logs. The feedback button opens a public GitHub issue page only when you click it. It is not made for children under 13. (Legal's 9.1 line, verbatim, plus the age line.)
>
> **Feedback.** [A private feedback target, not Orb's personal email: open question, `docs/ep/orb-review-list.md`.]

**Fields:** generative-AI field: tick **graphics, text and dialogue, and code** now. Tick **sound** when the Suno music ships, because today's sound effects are synthesised by code (the statement says so). Tags in section B.

### A2. Steam page (Stage 2; a skeleton, because most of it depends on what exists by then)

**Short description** (check Steam's length limit; about 200 characters here): Play a side-on energy brawler where every press is a blow. Choose a stance, break buildings in four stages and fight across a planet with no edges. [For one or two players.]

**About This Game (skeleton):**

> [One paragraph: the same pitch as A1.]
>
> **Features** (only what is in the build on release day)
> - [N] fighters [each with a different relationship to the destruction around them: only if the live build shows how the two fighters differ, else drop it; see C27].
> - Five stances, and a fight director that choreographs the exchange you choose.
> - A world that wraps all the way round, with buildings that break in stages.
> - [Versus on one screen] [Versus against a computer-controlled opponent] [Training]. Modes only if they exist.
> - [Controller support] [Steam Deck: only after the badge is awarded].
>
> **How this game was made.** [Legal's short form, exactly.]
>
> [Content note matching the Content Survey: cartoon violence, destruction, civilian casualties.]
>
> [Only once the title is settled and in use: "[Title]" with the ™ mark. Then, once the holder line is decided: "[Title] and its logo are trademarks of [holder]." Never ® or "registered" until a registration exists.] [System requirements: Platform.]

**Steam Content Survey:** pre-generated AI content, yes (art, animation data, dialogue, UI text, and music once it ships); live-generated, no. Cover the AI-assisted marketing assets (capsule art, trailer) as well as the game. Answer the violence section including civilian deaths and destruction.

## B. Tags and keywords

Steam tags (check the maximum and the exact tag names in Steamworks). Legal's verdicts are in the last column.

| Tag | Condition | Legal |
|---|---|---|
| Fighting, Action | true today | clear |
| Anime | **conditional**: only if the final art reads as anime-styled, never next to a franchise word | conditional |
| Local Multiplayer, PvP | only if one-screen versus is in the build | clear |
| 2.5D | **conditional**: Art confirms the word is true of what a player sees | conditional |
| Destruction | true today | clear |
| Indie, Singleplayer | true | clear |
| Controller | **on hold** until controller play is tested on the build | hold |
| Fast-Paced | a judgement; fine if playtests agree | clear |
| Flight, Physics | **conditional**: only if a player would call them true | conditional |
| Free to Play | **conditional**: only if the Steam release is free (no upfront price); drop if paid or if tips are taken | conditional |

itch.io tags (check its limit): fighting, action, local-multiplayer, anime (conditional as above), destruction, godot, plus its browser classification. "godot" names the engine factually: no Godot logo unless its brand rules allow, and no wording that implies Godot's endorsement. The AI tag comes from the AI field, not from us.

Hashtags and search phrases that are fine (genre and tool words only): #fightinggame, #indiegame, #indiedev, #gamedev, #godotengine, #madewithgodot, #anime (conditional), "energy brawler", "side-on fighter", "local versus", "destructible".

**Never in text, tags, keywords, hashtags, handles or alt text.** The exact words are kept in one place, `docs/legal/never-use-words.md` (Legal's single source), so they do not sit in a Marketing file. The categories:
- any franchise, character, move or place name, and the franchise's signature words, including near-spellings and puns;
- the project's working codename and the placeholder names shown in earlier builds, and the names of the fan games and of other projects the title could be confused with;
- positioning phrases: "spiritual successor", "tribute", "parody", "clone", and "like", "inspired by" or "for fans of" followed by a franchise or character;
- "open source" for the whole project; "human-made", "handcrafted", "hand-drawn", "made by hand", "composed by", "no AI", "AI-free", and "built by one person" without the AI clause;
- "official", "licensed" or "exclusive" for the music; "first" and "best" claims; anything implying endorsement.

## C. Capsule art and trailer plan: where each asset comes from

Every asset gets a row in `docs/legal/asset-origins.md` (tool, model, date, prompt location) before it goes on a page; Legal adds it on receipt. Image sizes are taken from Steamworks' graphical-assets page on the day, not from here.

| Asset | Made from | Made with | Origin record | AI disclosure | Hours (estimate) |
|---|---|---|---|---|---|
| Screenshots (5 to 8 for Steam, a few for itch.io) | Real captures of the build at a recorded version, in the moments listed below | The game, plus a screen or headless-browser capture tool (a tool, not content) | Capture date, build commit and scene | Covered by the page statement | 2 |
| Capsule art (header, small, main, vertical), library hero and logo | One real capture, plus a **plain wordmark in a licensed font** | Orb picks the font; one row in `licence-register.md`. If an AI-made logo is used instead, it needs its own look-alike screen | Font: a register row. Any AI-made lettering: tool, model, date, prompt location, what Orb changed | Store-page statement covers it, and **Steam's survey must also cover AI-assisted marketing assets** (capsule, trailer), not only the game | 3 to 4 |
| itch.io cover and GIFs | Real captures | As screenshots | As screenshots | As above | 1 |
| Trailer (30 to 60 seconds) | Real captures only. No concept art, no mock-ups, no stock footage | A free editor (tool recorded). A Suno track only under Legal's conditions, below | Footage: build version and scene list. Music: the Suno record | The end card carries the statement. No voiceover | 4 to 6 |

**Screenshot and trailer moments** (each must be true of the build on the day):
1. The opening: two fighters arrive, the world behind them.
2. A stance exchange with the HUD showing the five stances.
3. A building going down through its four stages.
4. A beam or heavy blow leaving a crater. (Check the single frame against the stacking rule below.)
5. A two-player moment, with the other player's permission.
6. The world wrapping: a fighter leaves one edge and returns round the other side.
7. End card: the wordmark, "Play free in your browser" [if so], Legal's statement. No platform or engine logo unless its brand rules allow, never as an endorsement, and no "official" in the title.

**Conditions from Legal (`store-copy-screen.md` section 4):**
- **Wordmark:** plain, in a licensed font. No chrome-bevelled or gold-and-orange 3D letters, no star or dragon motif, no letters that echo a franchise logo.
- **Key art and thumbnails:** the stacking rule applies to any single frame or thumbnail: at most two of the seven marks (no body flame aura plus a scream, no rubble ring with cracks and lightning together), no hero holding a sphere aloft, no hair colour change.
- **No frame shows** the placeholder names, the codename or the working title in the HUD, intros, results, captions or the window title, until the names are neutral. No browser chrome or personal data in frame. Another player's face, name or voice only with permission.
- **Capture hold:** not lifted until UI's name switch is live and Legal confirms that no player-visible text shows those names. Then capturing and storing privately may start. **Publishing** waits for the title decision and for these edits.
- **Trailer music (Suno):** allowed only if all of these hold: generated on a paid plan and downloaded through the approved download; the untouched original and its record kept; the end card or description says the music is Suno-generated and nothing calls it composed by Orb; no Content ID or exclusive registration; the track passed the listen-and-recognise check. A trailer edit (gain, cut, fade) is ordinary processing.
- **Trailer rules:** no franchise reference in captions, no on-screen claim that is not in section E, no balance numbers, no fake reaction clips, no "coming soon" features, no quotes unless they are in section D. No link from any asset or post to `docs/ep/vision.md` or Legal's screening notes. The statement also goes on any tip page; tips only after the licence, the title and Suno's paid plan are settled, never with perks.
- Keep descriptions specific: "real captures" and "a licensed font Orb picked" are accurate; never "real art" or "crafted". The game's Suno track is "generated with Suno", never "our composer".

## D. Planned testimonials

None are planned today. Word of mouth from friends ("friends are excited") is not a quote and is never turned into one.

If real quotes arrive, each gets a row before use:

| Quote (exact) | Who | Connection to Orb (stated beside the quote) | Permission and date | Message kept | Legal status |
|---|---|---|---|---|---|
| (empty) | | | | | |

Rules: real people who really played; connection stated, for example "a friend of the developer"; never presented as an independent review; no one asked for a positive review; no keys, gifts or favours traded for reviews; a keyed review stays labelled by Steam.

## E. Every claim the copy makes

Verify each on the day it is published against the live build. Legal status is from `store-copy-screen.md` section 6 (2026-10-05, from the written draft; the live build was not played by Legal).

| ID | Claim (as in the copy) | Used in | Evidence | Verify | Legal status |
|---|---|---|---|---|---|
| C1 | Free to play in your browser, no install | A1, trailer end card | live build URL | open it in three browsers. Do not add "runs on any device" | clear |
| C2 | A side-on energy brawler | A1, A2 | live build | none | clear |
| C3 | For one or two players | A1, A2 | docs/design/modes.md; live build | two-player on one screen works | clear |
| C4 | Every press is a blow | A1, A2 | docs/design/melee-press-feel.md; brawl slice B1 deployed (live page at e6f51bd or later, EP 2026-10-05) | play a fight. Never "balanced" or "fair": five balance faults are being repaired | clear |
| C5 | Buildings break in four stages | A1, A2, trailer | docs/rendering/building-stages.md | play a fight and watch one building | clear |
| C6 | Craters stay where they land | A1 | pillars.md, pillar 4 | check in the build | clear |
| C7 | The planet has no edges; you come back round | A1, A2, trailer | pillars.md, pillar 1; qa seam tests | fly across the seam in the build | clear |
| C8 | Five stances | A1, A2 | ui/data/stances.json; HUD | count them on the HUD | clear |
| C9 | Two fighters with different personalities | A1 | docs/narrative; pillar 5 | play both | clear |
| C10 | A different opening to each fight | A1 | docs/narrative/dynamic-intros.md | play several fights | clear |
| C11 | Early build: two fighters, no online play | A1 | live build; open-questions Q9 | none | clear |
| C12 | [Controller or touch controls] | A1, A2 | docs/controls | test each device | **hold** until tested on each device |
| C13 | [N] fighters | A2 | roster at release | count them | do not claim until true |
| C14 | [Versus, computer-controlled opponent, Training modes] | A2 | modes.md; build | only modes that exist | do not claim until true |
| C15 | How this game was made (Legal's statement as amended, with the procedural-code sentence). The Suno sentence only once music ships | A1, A2, README, credits, descriptions, tip and social pages | docs/legal/go-to-market.md sections 1 and 10.1; asset-origins.md | facts match the origin log; Suno paid-plan records when music ships | clear (Legal's own text) |
| C16 | [There is no voice acting. Character vocal sounds are synthesised by code.] | A1, A2 statement | AUD-GEN-002 (grunt generator); Orb to confirm | Orb confirms | **hold for Orb** |
| C17 | Nothing is generated by AI while you play: the procedural systems are ordinary code, not AI models | A1, A2 statement | design: no live generation | Orb confirms | **hold for Orb**, then clear |
| C18 | This game collects and sends no personal data. The web version is hosted on GitHub Pages, which keeps its own server logs. The feedback button opens a public GitHub issue page only when you click it | A1, README | docs/legal/go-to-market.md 9.1 (verbatim) | re-check against the build the day of publishing | replaced by Legal's 9.1 line |
| C19 | Not made for children under 13 | A1 | Legal section 6 | Orb's audience answer | clear |
| C20 | [Title]™ / "[Title] and its logo are trademarks of [holder]" | A2 | after the title is settled and in use; holder line decided | never ® or "registered" without a registration | do not claim until true |
| C21 | "Open-source code" | README | licence decision | only under shape A or C | do not claim until true |
| C22 | Steam Deck Verified | none today | Valve's badge | only after it is awarded | do not claim until true |
| C23 | Directed by one person, Orb, and built with AI tools | pitch | docs/legal/go-to-market.md 10.1 | same as C15 | clear |
| C24 | Original characters and world (not "story", not "all names") | A1, A2, pitch | docs/legal/go-to-market.md 10.2 | none | clear |
| C25 | A computer-controlled opponent | A1, A2 | live build: a fighter plays itself in the demo and when a player takes one side | play against the opponent | clear |
| C26 | A fight director that choreographs the exchange you choose | A2 | docs/design/pillars.md pillar 2; docs/combat/exchange-templates.md | the fight feed or the HUD shows the exchange | clear (a game term) |
| C27 | Each fighter has a different relationship to the destruction around them | A2 | pillars.md pillar 5; the live HUD shows a MENACE bar on one fighter's plate and an ANGUISH bar on the other's (seen 2026-10-05) | play both fighters and watch the two bars react to civilians lost; if they do not visibly differ, drop the claim | clear if verified |

## Open questions

1. What is the public title? (Blocks every page. Orb decides: contact the OrbCombat author, or change it.)
2. Which licence shape? (Blocks C21, the repo, any money.)
3. Is there any voice acting, and will anything ever be generated while the game runs? (C16, C17; Legal's questions 5 and 6.)
4. Where does feedback go? A private target, not Orb's personal email. Until Orb answers, Orb collects it in person or in a private chat. If a form is used, Legal's 10.5 conditions apply: anonymous, a two-line notice, "do not put personal details", "for people 16 and over", a form tool with its own privacy statement, deleted after write-up; no signup list at Stages 1a or 1b.
5. When is UI's name switch live, so Legal can confirm the capture hold? (Capturing privately may then start; publishing waits for the title.)
6. Which logo route: a plain wordmark in a licensed font (Legal's safest and cheapest), or an AI-made logo that needs its own look-alike screen?
