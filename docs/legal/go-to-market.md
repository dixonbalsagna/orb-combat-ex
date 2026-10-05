# Going to market: what Orb must settle and disclose

Owner: Legal and IP Compliance. 2026-10-05. For Orb's plan: PC first (itch.io, the browser build, Steam including Steam Deck), consoles later. **A screen, not legal advice.** Policies were read on 2026-10-05 and each claim says where it came from and how good the source is. Where a real lawyer or accountant is needed it says so. Franchise names stay out of store text (section 7).

Orb's standing rule (docs/ep/vision.md, 2026-10-05): the project discloses its AI-made content upfront, everywhere it is presented or sold, and nothing is described as human-made that is not. Everything below keeps to that.

## The short version

| # | Topic | Verdict | The one thing Orb must do |
| :-- | :-- | :-- | :-- |
| 1 | AI disclosure | **Required on Steam and itch.io; no public rule found for consoles** | Tick the AI boxes honestly and use the statement in section 1 |
| 2 | Ownership | **Weak for AI-made parts; real for what Orb writes and for the name** | Keep records of Orb's own work; plan around copying |
| 3 | Selling an open-source game | **Conditional**: the current MIT plus CC BY 4.0 plan does not fit paid builds | Pick shape A (recommended) and drop CC BY 4.0 for content |
| 4 | The title | **Conditional**: OrbCombat clash still live | Decide: contact the OrbCombat author, or change the title, before any store page |
| 5 | Suno on a sold product | **Conditional**: paid plan, approved downloads, records | Subscribe to Pro or Premier before generating the tracks you will ship |
| 6 | Money, paperwork, ratings, privacy | **Clear, with deadlines** | Start the Steam seller account early: it has a 30-day clock |
| 7 | Marketing claims | **Clear, with limits** | No "human-made", no franchise comparisons, disclose friends' connections |

**Where a real lawyer is needed** (cheap, one sitting, before the first sale): a trademark clearance for the title; the licence texts (especially any custom assets licence); what the platform agreements make you warrant about AI-made content; whether to register copyright and how to describe the AI parts; tax, VAT and business status for your country; a privacy policy if the game collects anything.

## 1. AI disclosure

### What I read

| Store | Rule | Source, read 2026-10-05 |
| :-- | :-- | :-- |
| **Steam** | The Content Survey has two AI sections. **Pre-generated**: any content (art, code, sound and so on) made with the help of AI tools during development. **Live-generated**: content made with AI tools while the game runs. Since 2026-01-16 Valve narrowed it: disclosure is for AI content **players actually see or hear** (art, audio, dialogue and text, localisation, marketing, and the store page itself). Coding assistants and other tools that only speed up the developer are exempt. Live-generated content also needs a description of guardrails. Disclosures show publicly under "About This Game". Valve puts copyright and safety liability on the developer. | **Secondary**: a law-firm summary (legalmoveslawfirm.com, dated 2026-01-17), news reports of Valve's update (Outlook Respawn, 2026-01-18; VGC; cgpress). I could not read Valve's own Content Survey page (the fetch returned nothing). Orb or Platform should read it in Steamworks when filling the survey. |
| **itch.io** | A "generative AI disclosure" field on the project page. "Yes" lets you say which parts: graphics, sound, text and dialogue, code; it adds an "AI Generated" tag. "No" adds a "No AI" tag. Untagged projects that use generative AI are not indexed on browse pages. Launched 2024-11-21 for asset creators; press reports say it now covers games too. | **Secondary**: 80.lv and games-trade reports. I did not read itch.io's own page. Tick it either way. |
| **PlayStation, Xbox, Nintendo, Epic** | **No public, Steam-style AI disclosure rule found.** Reports say Sony has delisted hundreds of low-effort, AI-heavy games without requiring labels, and that Xbox's policy makes developers disclose AI-generated user content that other players see online and take responsibility for it. Console agreements still make you warrant rights to everything you ship. | **Weak**: trade press only (Notebookcheck, Otakukart, tech-insider, 2026). The agreements themselves are behind NDAs. Treat as "unknown until you are in the programme", and ask a lawyer about the rights warranty for AI-made music and art. |
| **EU AI Act, Article 50** | Transparency duties for AI systems and AI-generated content apply from 2026-08-02, with a short grace period for machine-readable marking on systems already on the market. They fall mainly on the **providers** of the AI tools and on people publishing deepfakes or public-interest text, not on a game that uses AI-made art. Low relevance here. | **Secondary**: Cooley, Baker McKenzie, artificialintelligenceact.eu summaries (2026). Ask counsel to confirm in one line. |

### Verdict for this project
- **Steam: required.** The game ships AI-made art and animation data, AI-written dialogue and UI text, and Suno music, and the store page and capsule art will be AI-assisted. Every one of those is "content players see or hear". There is **no live-generated AI** in the game as it stands (confirm with Orb: section 8, question 6).
- **Code:** Steam exempts coding assistants, but Orb's rule is full disclosure, so say it anyway on the store page, the README and the credits.
- **itch.io:** tick Yes for graphics, sound, text and dialogue, and code.
- **Consoles:** disclose in the store text anyway; expect to be asked in the agreement process.

### The statement (true of the project as I know it; brackets are facts for Orb to confirm)

**Store page, short form (put in "About This Game" and the itch.io description):**
> **How this game was made.** Orb Combat EX is made by one person, Orb, working with AI tools. AI tools wrote the game's code and drafted its art, animation data, dialogue, UI text and design documents. The music was generated with Suno. [There is no voice acting.] Nothing in the game is generated by AI while you play. Orb directs the project, makes the creative decisions, edits the dialogue by hand, and tests and plays the game. No part of this game is described as human-made unless this page says so.

**README and credits, long form:**
> **Made with AI.** This project is directed by Orb (a pseudonym). The tools: Anthropic's Claude (through Claude Code) wrote the code, the data files, the art and animation data, the dialogue and UI text drafts, and the design and planning documents. The music was generated with Suno on a paid plan and used under Suno's terms. [List any other tool, such as an image or voice generator.] Orb sets the direction, reviews and edits the output (including the dialogue, line by line), and playtests. All characters, names and designs are our own. Parts of this work may not be protected by copyright, because they were made by AI. The game does not use generative AI while it runs.

**Credits roll (one line each):** "Direction and editing: Orb. Code, art data, dialogue drafts and design documents: Claude (Anthropic). Music: generated with Suno."

Rules for using it: copy the same text everywhere (Steam, itch.io, README, credits, console pages, trailer description). Do not write "no AI" anywhere. If a tool is added later, update every place the same day.

## 2. Ownership: what protection AI-made work has

### What I read
- **US Copyright Office, AI report Part 2 (2025-01-29, primary):** the mere provision of prompts is not authorship. A human-authored work that can be seen in the output, or a human's creative selection, arrangement or modification of AI output, can be protected. Copyright covers the human contribution, not the machine's.
- **Thaler v. Perlmutter:** the DC Circuit held (2025-03-18) that a work must be authored in the first instance by a human; the Supreme Court denied review on 2026-03-02 (secondary: Mayer Brown, Baker Donelson, Reed Smith). So wholly AI-made output is, in the US today, not protected.
- **Not re-checked today:** the Ninth Circuit's Doe v. GitHub decision of 2026-09-16 on AI-written code (noted in my earlier work), and every country but the US. The UK, EU, Japan and others differ, and some give limited protection to computer-generated work. **Country-dependent: ask a lawyer where Orb lives and where the game sells.**

### What it means here
| | Result |
| :-- | :-- |
| **AI-made code, art, animation data, music** | Probably **unprotected** in the US. Anyone can copy those files without infringing, whatever licence they sit under. A licence cannot restrict what copyright does not cover. |
| **Someone copying the whole game** | Cannot be stopped on the AI-only parts. Can be pursued on: the **name** (trademark), Orb's **hand-written or hand-edited material**, the **selection and arrangement** of the whole (how it all fits together), and a **platform's own rules** (store takedowns for impersonation, trademark and rule-breaking). |
| **Code under MIT** | MIT is a permission, not a lock. It adds little where no copyright exists. |
| **Orb's own work** | **Protectable:** the dialogue Orb edits line by line (the voice lab diffs are the proof), anything Orb writes, draws or composes by hand, a melody Orb hums or plays into Suno (the track builds on a human-authored composition), and the creative choices in selecting and arranging the game's parts. |
| **The name** | Protectable as a trademark by using it and, better, by registering it. That is the strongest practical protection against a clone, and it depends on a clean title (section 4). |

### What Orb should do
1. **Keep the human-contribution record:** git history, the voice-lab diffs, Orb's notes in docs/ep/vision.md, any hand-made file with a dated origin. It is the evidence of authorship.
2. **Put Orb's hand-authored text (dialogue, lore, the manual) under the reserved content licence** (section 3), since that is where copyright really sits.
3. **Register the trademark, not copyright,** first. If Orb registers a copyright later, the application must describe the AI-made parts and disclaim them; a lawyer should file it.
4. **Plan for clones as a fact of life:** the defence is the name, the community, updates and being the official build, not the licence.

## 3. Selling an open-source game

### The problem with the current plan
The recommendation in `licence-recommendation.md` (MIT for code, **CC BY 4.0 for content**, DCO for contributors) is built for giving things away. **CC BY 4.0 on the art, dialogue and data lets anyone sell the game's assets, with a credit.** That defeats paid builds and is the part Orb is right to reconsider. The Suno music can never go under an open licence anyway (RL-071: separate audio notice). The licence files are currently out of the repo root while Orb decides.

### Three workable shapes

| | **A. Permissive code, content reserved** | **B. Source-available** | **C. Fully open, paid convenience builds** |
| :-- | :-- | :-- | :-- |
| **Code** | MIT (or Apache-2.0) | Functional Source License (FSL) or similar: free to read, change and use for anything except a **competing commercial product**; each release turns into MIT or Apache after 2 years. Alternatives: PolyForm Noncommercial, BUSL | MIT |
| **Art, dialogue, data** | **All rights reserved** with a short plain-words permission: free to play, mod, stream and make fan work; no reselling or redistributing the content on its own | Same as A, or under the same licence as the code | CC BY 4.0 (as drafted) |
| **Music** | Suno notice, separate (as RL-071) | Same | Same (cannot be open) |
| **A third party can** | Fork the code, sell a game built from it **only with their own content**, learn from it, port it | Read, learn, modify, run, contribute; **not** sell a competing game from the code for 2 years | Do anything with the code and content, including sell the same game under a new name |
| **Calling it "open source"** | Code yes, project partly (say "open-source code") | **No.** Source-available is not open source; saying it is would be false | Yes |
| **Steam and itch.io** | Fine | Fine; I found no Steam rule against it (not read in Steamworks), but never describe the game as open source | Fine; expect clones |
| **Console port** | **Works.** The permissive code allows a closed fork. The platform code (SDK headers, certification layer, which the console agreements forbid publishing) lives in a **private repo** or comes from a porting firm | **Works.** Orb holds the copyright, so Orb can add private platform code. Contributors need a licence that lets Orb relicense (a CLA, not only a DCO) | Works the same as A; the private platform layer is Orb's own |
| **Protection against a clone** | The name, the reserved content (where copyright subsists) and the store; code can be copied | The licence adds a contractual ban on competing sales, but it is only as strong as the copyright under it, and AI-written code may have none | Only the name |
| **Cost to Orb** | Low. One custom content notice to draft | Medium. Contributors, "open source" wording, community goodwill | Lowest, but the weakest "commercial control" |

Godot (the engine) is MIT, so all three shapes work with it. It cannot ship console export templates publicly (console makers' NDAs); console ports of Godot come from third-party firms or W4 Games (secondary: Godot's own console documentation, 2026). That is true whichever shape Orb picks.

### Recommendation for a hobbyist who wants some sales
**Shape A.** Release the code under MIT, put **all** art, music, dialogue, data and the name and logo under "all rights reserved" with a plain-words permission to play, mod, stream and make fan work, and sell the official builds (Steam, itch.io, later consoles) as the convenience and the support. It keeps Orb's goodwill and the open-source label for the code, it works with every store and with a console port, and it removes the CC BY 4.0 problem. Be honest about its limit: it does not stop a copy of the AI-made code. Nothing can, so the real protection is the name and being the official build. **Fallback:** shape B (FSL) if Orb wants a written ban on competing sales of the code and accepts losing the open-source label and needing a CLA from contributors.

A lawyer should draft the content notice and read the contributor terms. The drafts in `docs/legal/drafts/` need updating to match whichever shape Orb picks; I will do that once Orb chooses.

## 4. The title

**State today (re-checked 2026-10-05):**
- **OrbCombat is still live.** GitHub: Cascachu/OrbCombat (GDScript, GPL-3.0, "a mobile game for simulating fights between orbs with different weapons or powers"), created 2026-04-13, last pushed 2026-06-16, plus a web-page repo (primary: GitHub API).
- Steam search for "orb combat": one result, **Orbital Combat** (a different title). App Store search: no app of that name (primary: store search APIs). Google Play, EUIPO, UK and Japan registers, and an exact-phrase USPTO search: **not run** (see `name-screening.md`).
- The project is called "Orb" by its pseudonymous creator, and a title that starts with "Orb" also echoes a famous franchise's gathered-orb device, which our fighters avoid.

**Must happen before a store page:**
1. Orb decides: **contact the OrbCombat author** (a friendly note, since both are hobby projects) or **change the title.** Do not buy a domain, a Steam page or a logo before this.
2. A person or counsel runs the formal search for the final title in the US, EU, UK and Japan, classes 9, 28 and 41.
3. Check the store names on Steam, itch.io, Google Play and the App Store on the day.
4. Record who holds the title (the copyright-holder line and the pseudonym question).

**Fallback:** if the clash or the search is bad, take a title from the screened list in `name-screening.md` (the screened candidates were Sky Arsonists, then Redline Sky, with Sunburners last because of near-identical live games), or run the stage 1 to 3 screen on any three new candidates. I can do that in an hour. Whatever the title, keep "Meridian" off any public page: it is only the working codename and is taken by older games.

## 5. Suno on a sold product

**Re-checked 2026-10-05 against Suno's own pages (primary: suno.com/terms, effective 2026-09-03; suno.com/pricing).**

| Point | What the page says |
| :-- | :-- |
| **Plans** | Free: no downloads, "no commercial rights". **Pro $8 a month ($64 a year): 20 song downloads a month, commercial use rights.** **Premier $24 a month ($192 a year): 60 downloads a month, commercial use rights.** |
| **Ownership** | On paid plans Suno assigns to you its rights in outputs it owns; free plans are personal and non-commercial only. Suno gives **no assurance that copyright will vest** in any output. |
| **Commercial use** | You may not commercially exploit an output you have not downloaded through an approved channel, and you must follow Suno's conditions of access and use. |
| **Metadata** | You may not remove, alter, obscure or circumvent a watermark or metadata **for the purpose of concealing or misrepresenting** the output's origin, plan or status (this is the clause that allows ordinary normalising and OGG conversion; see RL-071 follow-up). |
| **Claims** | You may not present an output as human-made or say Suno endorses it. |
| **Risk** | Provided "as is"; no warranty about third-party rights; **you** indemnify Suno for IP breaches. |

**Verdict: Conditional.** Subscribe to **Pro (enough for about 20 kept tracks a month)** or Premier **before** generating any track you will ship, and keep a dated screenshot or receipt of the plan. Suno has long said tracks made on the free tier stay non-commercial after you upgrade; I did not find that sentence in the current text, so treat it as true and **regenerate any shipped track made on the free plan.** Then: download each track you keep, keep the untouched original and its sidecar record (`asset-origins.md`), ship the separate audio notice, never call the music human-made, and do not register the tracks in Content ID or a distributor as exclusive. The music is disclosed on the store page as Suno-generated (section 1).

**Lawyer:** platform agreements may ask you to warrant that you own or have the right to use all content. With AI music you hold an assignment of whatever Suno owns plus a licence, not a copyright you can prove. Ask counsel how to answer that warranty, and re-read the terms and the label lawsuits (RL-071: UMG and Sony sued Suno again in September 2026; not re-checked today) before the first sale.

## 6. Money and paperwork at the smallest scale

### Steam (primary: partner.steamgames.com/steamdirect, read 2026-10-05)
- **$100 per product**, non-refundable, recouped once the game has at least $1,000 of adjusted gross revenue.
- **A tax interview** (a short questionnaire, done in the account setup): US people use W-9 information, people in countries with a US tax treaty use W-8BEN information.
- **Bank details** (routing and account numbers and the bank address). **The account holder name must match the name on your legal ID.**
- **Identity verification.**
- **Two waits:** 30 days between paying the fee and being allowed to release, and a public "Coming Soon" page that must be up at least two weeks before release; Valve's review takes 1 to 5 days.
- You can register as an **individual**; a company needs a business bank account.
- **Country-dependent, not for me to ask about:** which tax form, withholding rate, VAT or sales tax on your own sales, whether the income counts as a hobby or a business, and whether the seller name on the page must be a trade name. **Ask an accountant.** The pseudonym "Orb" can be the public name; Valve and the bank get the legal name.
- **Steam Deck:** a compatibility review, not a legal step.

### itch.io
Pay-what-you-want and paid projects are open to individuals; payout and tax details are set in the account. I did not read itch.io's payout and tax pages: country-dependent, check them when setting up.

### Consoles (later)
- **ID@Xbox (secondary, 2026):** open to a registered legal entity or an individual depending on the region, no fee to apply or certify. **PlayStation Partners:** register as a partner and apply with a project plan; being accepted is not guaranteed. **Nintendo Developer Portal:** not verified. Each needs agreements, certification and age ratings, and each treats its SDK as NDA material (section 3).

### Age ratings
- **Steam:** fill in the Content Survey truthfully; Valve uses it to issue its own ratings. Since 2024-11-15 a game with no valid rating is hidden in Germany, and Valve's survey-based rating counts (secondary: GamingOnLinux; Steamworks Germany page not read).
- **Console and mobile stores** (Nintendo eShop, Microsoft Store and Xbox, Google Play) rate through the free IARC questionnaire, which gives ESRB, PEGI and others from one set of answers (secondary: IARC and ESRB, older press releases). PlayStation: not verified.
- **itch.io:** no rating needed; use its content declarations. Not checked in detail.
- **Content:** the game is cartoon fighting with civilian casualties (collateral damage is a design pillar). Answer the questionnaire exactly as the game behaves, including the civilian deaths and the destruction.

### Privacy
- **The game as built collects nothing** beyond what the store passes to you (on Steam, the player's Steam ID). Keep it that way at launch: **no analytics, no crash upload, no accounts.** Then no privacy policy is required by the stores; a one-line "This game collects no personal data" in the README is enough.
- **When it changes** (rollback online play with IP addresses, accounts, crash reports, chat, cloud saves, analytics, a browser build with cookies or trackers), it becomes personal data. Then you need a privacy policy, a legal basis, and a way to delete data; **GDPR and UK GDPR apply to players in those places even to a one-person studio,** and US states have their own laws. Ask a lawyer when online play is added.
- **Children:** the game is not made for under-13s; say so in the privacy line. If a store rates it for young players, children's privacy rules (COPPA and its equivalents) apply to any data collection.
- **Browser build:** the host's server logs hold IP addresses. Choose a host with a privacy statement and add no third-party scripts.

## 7. Marketing claims

**May say:** "made by one person with AI tools" (the section 1 text), "original characters, world and story", "open-source code" (only if shape A or C), "free to play" or the real price, true gameplay facts ("a world that wraps all the way round"), real quotes, and "Steam Deck Verified" only after the badge is awarded.

**May not say:**
- **"Human-made", "handcrafted", "hand-drawn", "composed by", "no AI", "AI-free"**, or anything that implies a person made what a tool made. Say "directed by Orb" and "drawn as data by AI tools", never "created by Orb" for AI-made work.
- **"Open source" for the whole project** unless shape C, and **never** for a source-available licence.
- **Anything implying endorsement** by Valve, itch.io, Sony, Microsoft, Nintendo, Godot, Anthropic or Suno. Use platform logos only as their brand rules allow. Suno forbids saying it endorses an output.
- **Franchise comparisons in store text, tags or keywords:** no "like", "inspired by", "for fans of" followed by a franchise or character name, and no franchise terms hidden in the tags or the page's metadata. The genre words are free ("anime energy brawler", "fighting game"). Do not call the game a clone, a tribute or a parody in store text either (`tribute-vs-parody.md`).
- **"Official", "licensed", "exclusive" music**, or "first" and "best" claims you cannot prove.
- **Claims about the AI** that are false or too neat ("the AI wrote everything and Orb did nothing"; "Orb made all of it").

**Testimonials from friends (the US FTC rule on consumer reviews and testimonials, in force since 2024-10-21, primary summary via law firms; civil penalties up to $51,744 per violation, secondary):**
1. Reviews and testimonials must be **real** and from people who really played it. Never write, buy or trade for reviews, and never gather only the positive ones.
2. The rule's "insider" reviews cover people tied to the seller, such as employees, agents and immediate family, and the FTC's wider endorsement guidance says any **material connection** (friendship, a free key, a favour) must be disclosed. So a friend's quote is allowed in marketing only if you state the connection ("a friend of the developer"). Do not present it as an independent review.
3. **Do not ask friends to post positive Steam reviews,** and do not give keys, gifts or favours in exchange for them. A review from a free key is fine if the reviewer says so, honestly, with no instruction on what to say. Steam's own review rules also apply (Valve labels keyed reviews).
4. Get permission before quoting anyone, quote them exactly, and keep the message.
5. Other countries have similar or stricter rules (not checked): ask a lawyer if the marketing targets them.

## 8. Checklists and decisions

### Before a Steam page goes up
- [ ] Title decided; OrbCombat resolved; formal trademark search done (section 4)
- [ ] Licence shape decided and the repo files, content notice and README match it (section 3)
- [ ] Copyright-holder line decided (Orb's legal name, or a business)
- [ ] The AI statement final and the same everywhere; Steam Content Survey AI sections filled; itch.io AI field ticked
- [ ] Capsule art, screenshots and trailer: origin recorded in `asset-origins.md`, AI use disclosed, shown from the real game
- [ ] Third-party notices current: Godot (MIT), fonts (OFL), Suno audio notice (`licence-register.md`)
- [ ] Suno: paid plan active when the shipped tracks were generated; originals and records kept
- [ ] Store text, tags and keywords checked against section 7; no franchise names
- [ ] Content Survey answered truthfully, including the civilian deaths
- [ ] Privacy line written (collects nothing), or a policy if it does
- [ ] Steam Direct account started: fee, tax interview, bank, identity (30-day clock)
- [ ] My pre-store review (`pre-store-checklist.md`) run on the final page and builds

### Before the first sale (the above, plus)
- [ ] Tax interview accepted and bank verified; accountant asked about your country
- [ ] The paid build's licence terms match the shape chosen; the content notice is in the build
- [ ] Name search clear and, ideally, a trademark application filed
- [ ] Lawyer's one-sitting review done (list at the top)
- [ ] Suno terms and the label lawsuits re-read within a week of launch
- [ ] Contributor terms (DCO, or a CLA for shape B) in place if anyone else has contributed
- [ ] No testimonials or reviews arranged without disclosure

### Before a console port
- [ ] Platform agreement read by a lawyer, especially the rights warranty for AI-made content and music
- [ ] Private platform repo, so no SDK code is ever in the public repo
- [ ] Age rating through the platform's route (IARC where used)
- [ ] An accountant's view of selling through the platform in your country

### Open decisions for Orb (one question each)
1. **Licence:** shape A (recommended): MIT code, all content and the name reserved, paid official builds?
2. **Title:** keep "Orb Combat EX" and write to the OrbCombat author, or pick a new title now?
3. **Who sells:** an individual (legal name to Valve, "Orb" as the public name), or a company later?
4. **Copyright holder line:** your legal name, the pseudonym "Orb" with a legal-name note, or a business?
5. **AI facts:** is the tool list in the statement complete (Claude, Suno, any image or voice tool)?
6. **Voice and live AI:** is there any voice acting, and will anything ever be generated by AI while the game runs?
7. **Suno:** are you on Pro or Premier now, and were all shipped tracks made on a paid plan?
8. **Audience:** is the game for teens and adults only (so privacy for under-13s is not in scope)?
9. **Consoles:** are you happy to keep a private platform repo, and to use a porting firm?

### Needs from Marketing, Platform and the others
- **Marketing:** the draft store copy, tags and keywords; the capsule art and trailer, with origin records; the list of planned testimonials and who they are; the claims they plan to make.
- **Platform:** which stores and in what order; whose account holds the Steam listing; the build pipeline (public repo, private platform repo); whether the browser build or any store build collects anything; the Steam Deck plan.
- **Audio:** Suno plan status and per-track dates; confirmation that no shipped track was made on the free plan.
- **Art and Narrative:** any image or voice tools used, and which text Orb hand-edits (for the human-contribution record).

## Sources and how well I could read them (all read 2026-10-05)
- **Primary:** [Steam Direct](https://partner.steamgames.com/steamdirect) (fee, tax, bank, identity, waits); [Suno terms](https://suno.com/terms) (effective 2026-09-03) and [Suno pricing](https://suno.com/pricing); [US Copyright Office, AI report Part 2 notice](https://copyright.gov/newsnet/2025/1060.html) (2025-01-29); GitHub and store search APIs for OrbCombat and the title.
- **Secondary (summaries, news, law-firm notes):** [Steam AI policy summary](https://legalmoveslawfirm.com/steam-ai-policy/) (2026-01-17); [Valve update report](https://respawn.outlookindia.com/amp/story/gaming/gaming-news/valve-clarifies-steam-ai-policy-focus-shifts-to-content-consumed) (2026-01-18); [itch.io disclosure](https://80.lv/articles/asset-creators-on-itch-io-now-have-to-disclose-the-use-of-generative-ai/) (2024-11-21); [Thaler cert denial](https://www.mayerbrown.com/en/insights/publications/2026/03/supreme-court-denies-review-in-ai-authorship-case) (2026-03); [EU AI Act Article 50 guide](https://artificialintelligenceact.eu/transparency-rules-article-50/); [FTC reviews rule summary](https://www.morganlewis.com/pubs/2024/08/ftc-issues-final-rule-on-consumer-reviews-and-testimonials); [Godot console support](https://docs.godotengine.org/en/3.6/tutorials/platform/consoles.html); [FSL](https://blog.sentry.io/introducing-the-functional-source-license-freedom-without-free-riding/); [IARC](https://www.globalratings.com/milestones); [Steam Germany ratings](https://partner.steamgames.com/doc/gettingstarted/contentsurvey/germany); [ID@Xbox](https://developer.microsoft.com/games/publish); console AI-policy trade press (Notebookcheck, Otakukart, 2026).
- **Not read:** Valve's own Content Survey page, itch.io's own policy and payout pages, the PlayStation and Nintendo programme terms, the console agreements (NDA), any non-US copyright or privacy law, the Doe v. GitHub decision text. Re-read the store pages themselves when filling in the forms, since policies change.
