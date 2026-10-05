# Go-to-market plan: told straight

Status: draft for Orb and the EP, not reviewed by Legal. Nothing here has been posted, registered, bought or sent to anyone. Written 2026-10-05 by Marketing. Not legal or financial advice.

Built inside Legal's `docs/legal/go-to-market.md` (RL-088). Where the two differ, Legal's wins. The draft store copy, tags and keywords, capsule art and trailer plan, planned testimonials and the full claims list are in `docs/marketing/store-copy-draft.md`.

Every number has a source link in section 15, or says "estimate". An estimate is my judgement, not a measurement, and no number here is a promise of results. Wording you may later show the public is marked **[proposal]** and goes to Legal before use. "[Title]" stands for the game's public title, because the current one is conditional (section 3).

## 1. One-page summary

**The straight answer.** A paid Steam release by one person with no budget usually earns very little. About 20,000 games came out on Steam in 2025. An outside estimate puts about two in three at under $1,000 in lifetime revenue, with a median near $250. Your game also starts with two real handicaps: it is AI-made (and you are telling people so, which is right), and it has two fighters today. The most likely result of a Steam launch done today is a few hundred dollars, which is less than Steam's $100 fee plus your time is worth. A good result is a few thousand dollars. A great result is luck, not a plan.

**What is worth doing anyway.** Your game is free to try in a browser tab, and that is a real advantage most Steam games lack. The honest goal is to find out cheaply whether strangers play it, come back and tell friends. If they do, selling becomes a sensible next step. If they don't, you have lost a little time and no money.

**The plan, in five stages.** Each stage ends with a number to hit before you go on, and a stop line that tells you to hold.

| Stage | What | Needs to be true first | Hours a week (estimate) | Number to hit before moving on (estimate) |
|---|---|---|---|---|
| 1a. Friends | Private play and feedback | Nothing new | 2 to 3 | 10 people played, 5 came back on another day |
| 1b. Public browser build and itch.io page | Free, public, with an honest "how it's made" | Title settled, licence settled, AI wording read by Legal, placeholder names gone | 3 to 4 | 500 plays, 50 followers, 20 comments from strangers in about 8 weeks |
| 2. Steam page and wishlists | The page, a trailer, wishlists | Stage 1b number hit, at least 4 fighters, Steam build working, your decision to spend $100 | 4 to 5 | 1,000 wishlists after about 12 weeks |
| 3. Demo and one Steam Next Fest | A demo and a week of attention | Stage 2 number hit | 6 to 8 for about 3 weeks | 2,000 wishlists before launch |
| 4. Launch | Selling, if the numbers say so | Stage 3 number hit, Legal review of every public claim | 15 to 20 in launch week | First-week sales at or above 0.10 times wishlists |
| 5. After | Updates, roster, later consoles | A launch behind you | 2 to 4 | Your call |

**What the realistic range looks like (section 9).** Using published ratios, 300 wishlists at launch gives roughly $300 to $700 to you in year one at a $5 price. 2,000 wishlists gives roughly $1,800 to $4,700. 10,000 wishlists gives roughly $9,000 to $23,000. Getting 10,000 wishlists with no budget is rare.

**What is blocked today, and by what.**
- **The title clash** (the small OrbCombat project, same name, same engine) blocks every public page that carries the title: itch.io, Steam, social handles, domains, a trailer.
- **The licence** blocks making the repo public, any "open source" wording, taking tips or sales, and the Steam page. Legal recommends MIT code with art, music, dialogue, data and the name reserved, plus a plain permission to play, mod, stream and make fan work (its shape A).
- **Placeholder names in the live build** (the hero is still KAI, a NO-GO name, review-log RL-002) block public clips and promotion of that URL.
- **AI-disclosure wording** blocks every public page until the final text is the same everywhere. Legal's text is in `docs/legal/go-to-market.md` section 1 and is used as written (section 4 below). Steam and itch.io both require the disclosure, and itch.io leaves untagged AI projects off its browse pages.
- None of these blocks Stage 1a, which is friends playing and talking.

**What I would do this week.** Nothing public. Send the live link to five friends, ask each to play two matches, and ask three questions (section 11). That is two to three hours.

**Decisions only you can make** are in section 14, one question each.

## 2. What you are up against

| Fact | Number | Source and caveat |
|---|---|---|
| Games released on Steam in 2025 | about 19,000 to 21,000, which is about 55 a day | SteamDB, via PC Gamer; GamesRadar counts 20,282. Counts differ by method |
| Of those, games with fewer than 10 reviews | almost half | SteamDB, via PC Gamer |
| Games earning under $1,000 lifetime | about 66% | Gamalytic-derived estimate, not audited Valve data |
| Games that never reached the $100 Steam fee | about 40% | Same estimate |
| Median lifetime revenue of a 2025 game | about $250 | Secondary report of the same data. Treat as "very small", not as an exact figure |
| Gamers with a negative view of generative AI in games | 85%, 63% choosing the most negative option | Quantic Foundry, Oct to Dec 2025. N = 1,799, self-selected, leans young, core and PC. It is a warning, not a census |
| Effect of an AI disclosure on Steam reviews | about 53% fewer reviews, and a lower median rating (84.6% against 88.3% positive) | One analyst's study, via PC Gamer. It measured reviews, not sales |
| Share of 2025 Steam releases that disclosed AI | about one in five | Reported figure, press coverage of the same analysis; the share is rising |

What this means for you:
- **Discovery is the problem, not quality.** Most games are not bad, they are unseen.
- **Disclosure has a real cost, and you are paying it on purpose.** You decided "upfront disclosure is the only ethical path". This plan never softens it. It also means you should expect fewer reviews and a cooler first reaction from some audiences, and plan for that.
- **Free is your edge.** A browser tab asks nothing of a stranger. That is how you get plays, and plays are how you find out if anyone cares.

## 3. Positioning

**Two sentences [proposal].** [Title] is a free, in-browser energy brawler where every button press is a blow and a fight leaves the world wrecked: buildings break in stages and the planet has no edges. It is made by one person, Orb, working with AI tools, and its characters, names and world are all its own. [homage line: Legal proposes, Orb decides]

**Three hooks, true on the live build as of this draft (verify each one on the build before it is used):**
1. **A planet with no edges.** Fly one way and you come back round. Evidence: `docs/design/pillars.md` pillar 1; the seam tests in `qa/`.
2. **Buildings break in stages.** Windows out, cracked, a stripped shell, fallen. Evidence: the stage looks in `docs/rendering/building-stages.md`; the 2026-10-05 morning summary in `docs/ep/orb-review-list.md`.
3. **Every press is a blow.** Brawl slice B1 is committed (`5a0d527`). I could not confirm from here that it is on the live page, so check before you claim it. Evidence: `docs/design/melee-press-feel.md`.

The call to action is always the same: **play it free in your browser, no install.** That is a delivery fact, not a hook.

**What I will not say:**
- Not "spiritual successor", not any franchise or fan-game name, and no franchise words in tags, keywords, repo topics or hashtags (`docs/legal/originality-rules.md`, "Words we use in public"). Describe the genre in plain words: energy brawler, flying fighter, side-on fighter.
- Not "handcrafted", "hand-drawn", "human-made", "composed by", "AI-free", "no AI", or "created by Orb" for anything a tool made. Say "directed by Orb". Nothing is called human-made unless the asset log and the store text say so.
- No implied endorsement by Valve, itch.io, Sony, Microsoft, Nintendo, Godot, Anthropic or Suno. Platform logos only as their brand rules allow. "Steam Deck Verified" only after the badge is awarded.
- Not "open source" for the whole project. At most "open-source code", and only under Legal's shape A or C.
- Not "clone", "tribute" or "parody" in store text, and no "like", "inspired by" or "for fans of" followed by a franchise or character name, in text, tags or keywords.
- Not anything not yet in the build: online play, twelve fighters, consoles, a story mode. The roster of twelve is a plan, not a feature.
- Not balance numbers as promises.

**Claims check.** Each claim carries Legal status "unreviewed" until Legal says otherwise.

| Claim | Evidence | Phase | Legal status |
|---|---|---|---|
| Free to play in a browser | live build URL | live now | unreviewed |
| World wraps, no edges | pillars.md, seam tests | live now (verify) | unreviewed |
| Buildings break in four stages | building-stages.md | live now (verify) | unreviewed |
| Every press is a blow | melee-press-feel.md | live now? (verify) | unreviewed |
| Two fighters today | live build | live now | unreviewed |
| Five stances | ui/data/stances.json, live HUD | live now (verify) | unreviewed |
| Made by one person, Orb, working with AI tools (Legal's statement, as written) | docs/legal/go-to-market.md section 1; asset-origins.md | live now | wording is Legal's, to confirm facts |
| Four fighters, music, controller play | roadmap P4 and P5 | not yet | do not claim |
| Online play, consoles, a campaign | open-questions.md Q9, Q10 | not yet | do not claim |

## 4. AI disclosure: wording and where it appears

The wording is Legal's, from `docs/legal/go-to-market.md` section 1. I use it **as written**, with no shortening or rewording, and the same text everywhere. Brackets are facts for Orb to confirm. If a tool is added later, every place changes the same day. Never write "no AI".

- **Store page short form** (Steam "About This Game", the itch.io description, video descriptions, devlog footers, creator messages):
  > **How this game was made.** Orb Combat EX is made by one person, Orb, working with AI tools. AI tools wrote the game's code and drafted its art, animation data, dialogue, UI text and design documents. The music was generated with Suno. [There is no voice acting.] Nothing in the game is generated by AI while you play. Orb directs the project, makes the creative decisions, edits the dialogue by hand, and tests and plays the game. No part of this game is described as human-made unless this page says so.
- **README and credits, long form:** Legal's "Made with AI" paragraph, copied from its section 1.
- **Credits roll, one line each:** "Direction and editing: Orb. Code, art data, dialogue drafts and design documents: Claude (Anthropic). Music: generated with Suno."
- **The title inside the text** follows the title decision. Until then the draft keeps "[Title]".

The facts must match `docs/legal/asset-origins.md` on the day of publishing, and the music line needs Suno's paid-plan records (Legal section 5).

**Where it appears:**
1. The first lines of the itch.io description, plus itch.io's generative-AI field, ticked Yes for graphics, sound, text and dialogue, and code.
2. Steam's content survey (pre-generated AI content: yes; live-generated: no), plus the first paragraph of the Steam "About" text.
3. In the game: an About or Credits screen reachable from the title screen (UI to confirm it exists; the live build I viewed shows no such line).
4. The README, and the first screen of the repo.
5. The footer of every devlog, and the description and pinned comment of every video.
6. Every message to a creator or reviewer, in its first lines.
7. The trailer's end card.

## 5. Audience and where they are

Community rules change and I have not verified any community's current rules. **Check each community's rules and its self-promotion limits right before posting.** Some restrict AI-made work, some limit self-promotion (for example to a weekly thread or a post-to-comment ratio), and some require flair.

| Segment | What they want | Where they are | Stage | Notes |
|---|---|---|---|---|
| Your friends, including friends with PlayStations | A game to try together | In person, messages | 1a | Browser and phone play work; a PlayStation release is a later, paid decision (section 12) |
| Two-player and couch-versus fans | Chaos with a friend, no setup | itch.io, local-multiplayer communities, Steam Deck groups | 1b to 4 | The best fit for "every press is a blow". Needs controller play |
| Energy-brawler and anime-style fighter fans | Big beams, big destruction | itch.io tags, fighting-game and indie-game subreddits, YouTube | 1b to 4 | Fighting-game purists expect frame data and rollback. This is a stance-based brawler, so say that early to avoid a mismatch |
| Browser-game and jam players | A fun five minutes | itch.io, web-game subreddits, game-jam communities | 1b | Cheapest plays you will get |
| Godot and indie-dev watchers | Devlogs, tech | Godot communities, indie-dev subreddits and servers | 1b to 3 | Good for feedback and followers, poor for buyers. They also notice AI use first |
| Small streamers and YouTubers | A game that makes a good clip | YouTube, Twitch | 2 to 4 | Creators with under a few thousand followers answer. Check each one's stance on AI-made games first and skip those who refuse it |

Channel choices (a Discord server, YouTube, Bluesky or X, Reddit, GitHub Discussions) belong to the channels decision in section 14. My default is **itch.io comments and devlog as the hub** and no Discord until you have 50 followers, because a server needs two to three hours a week of moderation.

## 6. Stage gates

Numbers are estimates unless a source is given. They are set so that hitting one means "strangers are interested enough that the next step is worth your hours". Missing a number is a result, not a failure.

### Stage 1a. Friends (private, now)
- **Game first:** nothing new. The live build as it is.
- **Paperwork first:** none. Playing with friends is not publishing. See the risk in section 13 about the build being reachable by anyone with the link.
- **Do:** five friends play two matches each, ideally two of them together. Ask the three questions in section 11. Note what confuses people.
- **Hours:** 2 to 3 a week for 3 to 4 weeks.
- **Move on when:** 10 different people have played, at least 5 played again on a different day without being nagged, and at least 3 two-player sessions happened.
- **Stop line:** if nobody wants a second match, fix the game, not the marketing.

### Stage 1b. Public browser build and itch.io page
- **Game first:**
  - the placeholder names are gone (the hero rename is queued);
  - an About or Credits screen with the AI line and the Godot licence text;
  - How to play works for a first-time player on keyboard, controller and touch;
  - it runs on an old laptop (`/bench/` on the live site) and in three browsers.
- **Paperwork first (each blocks this stage):**
  - the title clash with OrbCombat settled (contact the author, add a word, or pick another title);
  - the licence settled;
  - the name on the account decided;
  - Legal's review of the page text, screenshots and AI wording;
  - Legal's answer on whether public clips may start (RL-014, public-readiness M7).
- **Do:** one itch.io page with the live game embedded, the one-line disclosure first, one short clip, a devlog post a month and replies to every comment. Post to one or two communities after reading their rules.
- **Hours:** 3 to 4 a week.
- **Move on when (about 8 weeks after going public):** 500 plays, 50 followers, 20 written comments from people you do not know, and no repeated "broken" or "not fun" theme.
- **Stop line:** under 150 plays after 8 weeks means the hook is not landing. Stay here, change the pitch or the first minute of play, and do not open Steam.

### Stage 2. Steam page and wishlists
- **Game first:**
  - at least 4 playable fighters, because a two-fighter game at a paid price will collect "not enough content" reviews (my recommendation; the launch roster is Game Design's and your call);
  - music;
  - controller support;
  - a Windows and Linux build that runs in Steam, with Steam Deck checked (Platform's piece);
  - a 30 to 60 second trailer made from real captures (Legal reviews it).
- **Paperwork first:**
  - **your decision to spend Steam's $100 fee** (the only spend this plan assumes, and not before the Stage 1b number is hit);
  - the verified identity and tax details Steam requires (`docs/legal/pre-store-checklist.md` section 5);
  - the AI survey answered;
  - counsel's read of the store text (`licence-recommendation.md` section 9).
- **Facts:** Steam's page review takes about 3 to 5 business days (ask for 7; Legal read 1 to 5). A new game must show a public Coming Soon page for at least 2 weeks before release, and **there are 30 days between paying the fee and being allowed to release** (Legal section 6). Identity, tax and bank setup is free and can start earlier. Paying the fee starts the 30-day clock, so no demo, Next Fest or launch date can be earlier than 30 days after payment.
- **Do:** open the page early, add the free-browser link and a "Play now in your browser" line, and send itch followers to the wishlist button.
- **Hours:** 4 to 5 a week.
- **Move on when (about 12 weeks after the page opens):** 1,000 wishlists. For scale, a commonly cited "healthy launch" is 7,000 to 10,000 wishlists, which you are unlikely to reach.
- **Stop line:** under 300 wishlists after 12 weeks means selling is not working. Stay free on itch.io and treat Steam as optional.

### Stage 3. Demo and one Steam Next Fest
- **Facts:**
  - The October 2026 Next Fest (19 to 26 October) closed for registration on 31 August 2026.
  - The next is 22 February to 1 March 2027, with a registration deadline of 10 January 2027. That is too soon for these gates.
  - The one after that (around mid-2027) has no dates I could confirm. Check Steamworks' upcoming-events page.
  - Entry needs a public store page and a live demo that is not a repackaged existing demo.
- **Why wait:** the best predictor of a Next Fest result is the wishlists you already have (correlation 0.825 in the 2026 survey). With under 1,000 wishlists the median gain is 322. With 1,000 to 9,999 it is about 1,006. A Next Fest with no audience gets you little.
- **Game first:** a demo that is a good first hour (Game Design owns what is in it) and a game that holds up without you present.
- **Hours:** 6 to 8 a week for about 3 weeks around the event.
- **Move on when:** 2,000 wishlists in total before you set a launch date.
- **Stop line:** under 1,000 wishlists after the fest means delay the launch or release it free.

### Stage 4. Launch
- **Game first:** the full game as the page describes it, a patch plan for day one, and nothing on the page that is not in the build.
- **Paperwork first:** Legal has reviewed every public claim; price decided (section 8); build submitted for review at least 7 business days ahead.
- **Do:** one launch-week devlog, a message to the creators who played the demo, replies to everything. Do not buy reviews, do not give keys in exchange for positive coverage, and do not use fake accounts.
- **Hours:** 15 to 20 in launch week, then about 5.
- **Measure:** first-week sales divided by wishlists. Published medians are about 0.10 to 0.15 (0.15 for games with more than 25,000 wishlists, 0.10 for games over $10).
- **Stop line:** under 0.05 means the page or the game is not converting. Do not spend more; learn from it.

### Stage 5. After
- Patches, the roster, a sale event when Steam runs one, and later consoles (section 12). Hours: 2 to 4 a week.
- Go on only while the hours feel good. Many games earn most of their money in the first year, so a quiet year two is normal.

## 7. Content calendar you can sustain

The rhythm is by week since you started a stage, not by date. Real dates start when the gates are cleared. The **baseline is about 3 to 4 hours a week**; a thin version is 2 hours (one clip, one round of replies).

| Task | Frequency | Time (estimate) | Stage |
|---|---|---|---|
| Capture and post one short clip (15 to 30 seconds) | weekly | 60 min | 1b onward |
| Reply to comments and messages | weekly | 30 to 60 min | 1a onward |
| One playtest session with 2 or 3 people, then read the answers | weekly | 60 min | 1a to 3 |
| A devlog post (what changed, one picture, the disclosure footer) | monthly | 90 min | 1b onward |
| A one-paragraph numbers note to the EP (plays, followers, wishlists) | weekly | 15 min | 1b onward |
| Creator outreach, 5 messages | weekly | 60 min | 2 to 4 |
| Discord moderation, if you open one | weekly | 2 to 3 hours | not before 50 followers |

**What to post, all true today:**
- A building going down in four stages (hook 2).
- A short fight with the opening explained: "the same two fighters never open a fight the same way" (the composed intros are in the build).
- A two-player moment from a friend's session, with their permission.
- "How it's made", an honest series: what the AI wrote, what you decided, what you threw away. This is your most distinctive content and the one that earns trust.
- A plain patch-notes post.
- A number that people can check, such as "this build has been fought 8,000 times by two AIs". Never as a balance promise.

**Capture checklist (before anything is posted):**
1. No franchise names, imagery or sounds, in the clip or the caption.
2. No placeholder names showing (the KAI hold, RL-014, until Legal lifts it).
3. Legal's AI statement (short form, unchanged) is in the caption, description or pinned comment.
4. No unreleased feature is implied.
5. Legal has seen the template at least once; after that each clip follows the template.
6. Nothing is posted in a community whose rules you have not read that day.

## 8. Pricing options

Selling an open-source game has a catch, and Legal has named it (`docs/legal/go-to-market.md` section 3). The current plan (MIT code, CC BY 4.0 content) lets **anyone sell the game's art, dialogue and data** with a credit, which defeats paid builds. Legal recommends **shape A**: MIT code, with art, music, dialogue, data and the name reserved, plus a plain permission to play, mod, stream and make fan work, and the official builds sold as the convenient, supported version. Its fallback is shape B (source-available, so not "open source"). Under any shape, AI-made parts may have no copyright, so a copy of them cannot always be stopped. The real protection is the name (trademark), being the official build, updates and the community. Do not call the game "open source" in store text; at most "open-source code" under shape A or C.

| Option | What it means | Likely money (estimate) | Trade-offs |
|---|---|---|---|
| A. Free everywhere, optional tips on itch.io | Browser and downloads free; itch.io "name your own price" with a $0 minimum | Press coverage of free itch games suggests 1 to 3% of downloaders tip, about $3 each. 5,000 downloads would be about $150 to $450 before fees (secondary source, treat as rough) | Honest, simple, fits an open-source game, no Steam fee. Little money. Accepting any money needs Legal and probably a lawyer first (`licence-recommendation.md` section 9, item 6) |
| B. Paid on itch.io only ($3 to $8), free browser build kept | Pay for the downloadable build, updates and support | itch.io takes 10% by default (you can set 0 to 100%) plus about 2.9% and $0.30 a payment. Most small paid titles earn little | Cheap and no $100. The free browser build competes with your own paid one, so the paid version must give a clear reason to buy (more fighters, controller play, updates) |
| C. Paid on Steam ($5 to $10), browser build stays free | The route most of this plan prepares | See section 9 | Steam takes 30% up to $10 million. $100 fee comes back only after $1,000 in sales. Needs identity and tax checks, an AI disclosure on the page, and a real roster to defend the price |
| D. Free on Steam | Free listing, no sales | Nothing, apart from the wishlists and reach | Still costs the $100 fee and still shows the AI disclosure. Only worth it as a front door to a free game |

**My recommendation:** run Stages 1a and 1b on option A, with no money taken until Legal clears it. Decide between B, C and staying on A when you reach the Stage 2 decision, with real plays and follower numbers in hand. Do not choose a price today.

## 9. Three sales scenarios

**Method.** Wishlists at launch times a first-week ratio of 0.10 to 0.15 gives first-week sales. First-year sales are the first week times 2.6 to 4.5 (the published range for the median game; some viral games go far higher). Money is the list price times units, less Steam's 30%. **Before** tax, refunds, regional pricing and discounts, which all lower it. The $100 fee is returned only if gross revenue reaches $1,000.

| | Quiet | Modest | Good (rare) |
|---|---|---|---|
| Wishlists at launch (assumption) | 300 | 2,000 | 10,000 |
| Why that number | A first-time hobbyist with a small audience. For scale, a game with under 1,000 wishlists gains a median 322 from Next Fest | Stage 3 number hit | Needs a creator breakout or genuine word of mouth |
| First-week units | 30 to 45 | 200 to 300 | 1,000 to 1,500 |
| First-year units | about 80 to 200 | about 520 to 1,350 | about 2,600 to 6,750 |
| To you at $5, year one | $280 to $700 | $1,800 to $4,700 | $9,100 to $23,600 |
| To you at $10, year one | $560 to $1,400 | $3,600 to $9,400 | $18,200 to $47,300 |
| $100 fee back? | At $5, no. At $10, probably | Yes | Yes |

**Do not read the right column as a forecast.** Roughly two in three Steam games earn under $1,000 in their lifetime. The "Quiet" column is a good outcome by that standard. If wishlists end under 300, expect the first-year figure to fall below the "Quiet" range, and if nobody comes at all you are out the $100.

Your time: Stages 1 to 4 total roughly 250 hours by my estimate (about 40 weeks at 3 to 8 hours a week, with a heavy launch week). At the Modest scenario's $5 price that is about $7 to $19 an hour before tax. That is a hobby wage, not a salary.

## 10. When I would advise against selling

Stay free if any of these is true when you reach the Stage 2 decision:
1. The title clash or the licence is not settled.
2. The Stage 1b number was missed (under 150 plays, or the same "not fun" comment keeps coming).
3. You want the game free for everyone, and a price would feel like a betrayal of that.
4. You cannot give about 4 hours a week for several months.
5. A $300 result would make you regret the work.
6. The roster is still two fighters, and you would charge for it.
7. Legal says the licence lets others sell identical copies and you are not comfortable with that.
8. You would not enjoy handling the backlash that follows an AI disclosure on a paid page (section 13).

## 11. Friends and first players: playtesters and reviewers, honestly

**The ladder.** A friend plays, answers three questions, joins a list if they want to hear more, joins a free playtest, and at launch tells people what they honestly think. Every step is optional, and none is rewarded with anything for a good opinion.

**Three questions** (anonymous by default; collect no personal data until Legal's privacy review, and send the answers somewhere that is not your personal email):
1. In one sentence, what is this game?
2. Did you want another match? Why or why not?
3. What confused you?

Add one for two-player sessions: "Did you and the other player both feel in control?"

**What to say to friends:** "Tell me what you really think. I am not asking for stars or for you to post anything. If you do post a review anywhere, say you know me." Never ask for a positive review, never trade keys, gifts or favours for one, and never use fake or friend accounts to inflate numbers.

**Testimonials (Legal section 7; the US FTC reviews rule):**
1. Real quotes only, from people who really played it, and not only the flattering ones.
2. A friend's quote may appear in marketing only if the connection is stated ("a friend of the developer"). It is never presented as an independent review.
3. Get permission, quote exactly, keep the message.
4. A review written from a free key is fine if the reviewer says so and was told nothing about what to write. Steam labels keyed reviews.
5. Word of mouth is not a quote. "Friends are excited" never becomes "players love it".

No testimonials are planned today. The log in `store-copy-draft.md` stays empty until real quotes exist.

**Free tools worth using:** Steam Playtest (a free Steamworks feature using a separate test app, which needs a store page) and Steam keys for creators.

**Creators:** send a short, honest message with the disclosure line first and the link, ask nothing in return, and skip anyone who says they do not cover AI-made games. Five messages a week is plenty.

## 12. Consoles and the friends with PlayStations

Consoles are later and cost money, and Platform's companion piece owns the facts. What I can say for the plan:
- Your friends can try the browser build now on a phone or a PC, and the build has touch controls (the phone checklist is `docs/controls/phone-test-checklist.md`; I have not seen it tested on many phones).
- A PlayStation release is a Stage 5 question, not a promise. Do not tell anyone it is coming.
- If those friends would buy it on a console, that is useful evidence, but it is not the same as buying it. Ask them what they would pay and where they would play.

## 13. Risks

| Risk | What could happen | Response |
|---|---|---|
| **Hostility to AI-made games** | Negative comments, review bombing, being blocked or muted in some communities, fewer reviews | See "Responding without arguing" below. Plan for a lower reach, and keep the disclosure first and plain |
| **Title clash** | A rename after an audience exists wastes the promotion | Settle it before any public page; do not buy a domain or handle until then |
| **Licence** | The current CC BY 4.0 content licence lets others sell the assets; "open source" wording can become false | Settle first (Legal's shape A); no money until Legal clears it; no "open source" in store text |
| **The live build is reachable now** | The GitHub Pages URL shows KAI and VORR to anyone who finds it, against Legal's public-readiness item M7 | EP to ask Legal and Orb whether the URL should be unlisted until the rename lands |
| **Franchise comparisons** | Commenters will use franchise names | Never use them yourself, do not argue comparisons, and keep every public line to our own words (`originality-rules.md`) |
| **Content depth** | Two fighters reads as thin at a price | The Stage 2 game condition |
| **Expectation mismatch** | Fighting-game purists expect frame data and rollback netcode | Say "stance-based brawler" early |
| **One person, finite hours** | Burnout | The hour estimates and the stop lines; drop recurring tasks before dropping sleep |
| **Money admin** | Steam needs a verified person or entity, tax forms and a waiting period | Section 14 question 3; counsel for the pseudonym |
| **Privacy** | A younger audience, signups and feedback forms | Anonymous by default, nothing collected before Legal's privacy review |
| **Stale numbers** | Steam rules, itch tags and survey figures change | Re-check the sources before each stage |
| **Cloning** | A copy with a new name appears on a store | Trademark, being the original and the updates; counsel for takedowns |

**Responding to AI hostility without arguing.**
- **Get ahead of it:** the disclosure is the first line everywhere, and a short "How it's made" page answers the obvious questions. Nobody can say you hid it.
- **Reply once, calmly, and stop.** Thank them, state a fact, link the page. Do not debate ethics or copyright, do not be sarcastic, and do not call critics names.
- **Do not delete civil criticism.** Remove only harassment and spam, and report threats.
- **Honour community rules.** If a community bans AI-made work, do not post there.
- **Wait a day** before answering anything heated.
- **Do not hide, wash or rename.** Never say "no AI" or "AI-assisted" if it understates what happened.

Three replies you can adapt:
- "Fair to be wary. It's all in the first line of the page, and the full 'how it's made' is here: [link]. Thanks for trying it either way."
- "I'm one person with no budget, and AI is how this got built. I'm telling you up front so you can decide. No hard feelings if it's not for you."
- "Thanks for the feedback on the controls. I'll look at that."

## 14. Open decisions for Orb

One question each. My recommendation follows.

1. **The title clash:** do you contact the OrbCombat author, add a distinguishing word, or choose another title? (Blocks every public page. Recommend: decide this first; it is the cheapest to settle before an audience exists.)
2. **The licence:** do you take Legal's shape A (MIT code; art, music, dialogue, data and the name reserved, with a plain permission to play, mod, stream and make fan work)? (Blocks the repo, tips, sales and Steam. Legal's fallback is shape B, source-available.)
3. **Who is named on the stores and in the licence files:** your legal name, "Orb", or a project name? (Steam and itch.io payouts need a real person or entity either way.)
4. **Are you willing to spend Steam's $100 fee, but only after the Stage 1b number is hit?**
5. **How many hours a week can you honestly give: 2, 4 or 6?** (This sets how many channels we use.)
6. **Do you want a Discord server, or itch.io comments and devlogs only for now?** (Recommend the second until 50 followers.)
7. **Do you stay free by default, or try a paid release if the gates are met?** (Recommend: decide at Stage 2, not now.)
8. **Is a four-fighter minimum the right bar before opening a Steam page?** (Game Design's launch roster is also open.)

## 15. Sources and verification notes (checked 2026-10-05)

**Steam and the market**
- Release counts: [PC Gamer on SteamDB's 2025 count](https://www.pcgamer.com/gaming-industry/more-than-19-000-games-launched-on-steam-this-year-but-almost-half-have-fewer-than-10-reviews/); [GamesRadar, 20,282](https://www.gamesradar.com/games/a-terrifying-20-282-games-were-released-on-steam-in-2025-and-just-608-managed-to-get-1-000-reviews-expert-finds-we-might-be-in-a-bit-of-an-indie-golden-age/).
- Revenue distribution (third-party estimates): [game-developers.org, Gamalytic-derived](https://game-developers.org/2025-steam-game-revenue-distribution).
- Wishlist conversion, 0.15 and 0.10: [games.gg, from GameDiscoverCo, Sept 2024 to Sept 2025](https://games.gg/news/what-the-data-says-about-wishlist-conversion/).
- First week to first year, 2.6 to 4.5: [Steam Page Analyzer](https://www.steampageanalyzer.com/blog/steam-first-week-sales) (secondary), citing [Game Developer](https://www.gamedeveloper.com/business/can-week-one-steam-sales-predict-first-year-sales-) and GameDiscoverCo.
- Next Fest wishlist gains and the 0.825 correlation: [How To Market A Game, February 2026 survey, 182 responses](https://howtomarketagame.com/2025/03/26/benchmarks-how-many-wishlists-can-i-get-from-steam-next-fest/). Self-reported by developers.
- Next Fest dates: [Steamworks, October 2026](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/2026october) and [February 2027](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/feb_2027).
- Wishlist benchmarks of 7,000 and 10,000: [Presskit.gg](https://presskit.gg/field-guides/how-many-wishlists-to-launch) (secondary, a rule of thumb).
- Coming Soon and review times: [Steamworks Coming Soon](https://partner.steamgames.com/doc/store/coming_soon). Steam Playtest: [Steamworks](https://partner.steamgames.com/doc/features/playtest). AI disclosure: [Steamworks content survey](https://partner.steamgames.com/doc/gettingstarted/contentsurvey).
- Steam's cut and fee: [Steam Page Analyzer on the revenue share](https://www.steampageanalyzer.com/blog/steam-revenue-share-explained) (secondary); Legal's `licence-recommendation.md` section 7 cites Valve's [app fee page](https://partner.steamgames.com/doc/gettingstarted/appfee).

**itch.io**
- [Open revenue sharing](https://itch.io/updates/introducing-open-revenue-sharing) and [payments](https://itch.io/docs/creators/payments). The "2.9% plus $0.30" processing figure and the "1 to 3% of downloaders tip" figure come from a secondary guide ([Generalist Programmer](https://generalistprogrammer.com/tutorials/how-to-make-money-on-itchio-indie-game-guide)). Check itch.io's own page before relying on either.

**AI sentiment**
- [Quantic Foundry, December 2025](https://quanticfoundry.com/2025/12/18/gen-ai/). I could not open the page directly (it returned an access error); the sample size and percentages come from search-result summaries of it.
- [PC Gamer on the AI-disclosure review study](https://www.pcgamer.com/software/ai/data-analyst-finds-ai-stigma-on-steam-can-reduce-the-number-of-reviews-a-game-gets-by-around-53-percent-and-the-reviews-it-does-get-are-more-negative/). It measured reviews, not sales.

**Legal's companion piece:** `docs/legal/go-to-market.md` (RL-088), sections 1, 3, 4, 6 and 7, which this plan follows. Its sources are listed there, with how well each could be read.

**Project files** (all read 2026-10-05): `CLAUDE.md`, `docs/ep/vision.md` (section "going to market"), `docs/ep/orb-review-list.md`, `docs/legal/pre-store-checklist.md`, `licence-recommendation.md`, `originality-rules.md`, `review-log.md`, `name-screening.md`, `public-readiness-edits.md`, `asset-origins.md`, `docs/design/open-questions.md`, `docs/decisions/0005-lean-team-and-token-discipline.md`, and the live build at https://dixonbalsagna.github.io/orb-combat-ex/play/ (viewed in the browser pane: a side-on fight with five-stance HUD; fighters still named KAI and VORR; no AI line visible on the first screen).

**Not verified:** any community's current rules, any June 2027 Next Fest date, whether brawl slice B1 is deployed to the live page, and whether the build has an About or Credits screen.

**Things I need from others** are in my report to the EP: Legal (disclosure wording, the hold on public clips, privacy, money and licence effects) and Platform (Steam builds, Steam Deck, browser and phone support, consoles).
