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
> **How this game was made.** Orb Combat EX is a one-person project: Orb directs it and builds it with AI tools. AI tools wrote the game's code and drafted its art, animation data, dialogue, UI text and design documents. [Include only once music ships:] The music was generated with Suno. [There is no voice acting.] Nothing in the game is generated by AI while you play. Orb directs the project, makes the creative decisions, edits the dialogue by hand, and tests and plays the game. No part of this game is described as human-made unless this page says so.

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
| **Steam and itch.io** | Fine | Fine. Valve's open-source note (read 2026-10-05) lists MIT, BSD, Apache 2.0 and WTFPL as fine with the Steamworks SDK and copyleft such as GPL as a problem; never describe the game as open source | Fine; expect clones |
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

## 9. Addendum (2026-10-05): after Platform's companion piece

Platform's `docs/perf/stores-and-consoles.md` section 10 agrees with the points above (a private platform repo, Steam's 30 days). Four additions.

### 9.1 "Collects nothing at launch": the two things Platform found
Platform read the code (no analytics, accounts, crash upload or network calls) and measured the live play page on load (4 requests, all to its own origin, no cookie, nothing in local storage; the feedback panel and a full match not exercised). Read against my line, both are fine, with wording:
- **The feedback panel** opens a prefilled GitHub "new issue" page in the player's own browser **when they click**, with a body they can read first. The game sends nothing. This is a user-initiated link to a third party, not collection by us. **Conditions:** the prefill holds no personal data (the user-agent and display scale are device facts, not identity); the panel says plainly that **a GitHub issue is public** and to leave out personal details; GitHub's own privacy policy applies from that click.
- **The web build reads the user-agent and display scale locally** to lay out the interface and fill the issue text. They stay on the device unless the player submits the issue. Fine.
- **Hosting:** GitHub Pages logs visitors' IP addresses on its own servers and we cannot turn that off. That is the host's collection.
- **The line to publish (README and store page):** "This game collects and sends no personal data. The web version is hosted on GitHub Pages, which keeps its own server logs. The feedback button opens a public GitHub issue page only when you click it." Use "collects and sends nothing" for the game, never "no data is collected anywhere". Re-check with a network log before each store build, as Platform proposes. If an analytics tool, an account, a crash upload or online play is added, section 6's privacy rules apply.

### 9.2 Console and Steamworks SDK terms against shape A (and B)
| | Finding | Source and grade |
| :-- | :-- | :-- |
| **Steamworks SDK and open source** | Valve says permissive licences (MIT, BSD, Apache 2.0, WTFPL) work with the SDK; **copyleft such as GPL is "problematic"**, and if an app contains open-source code that cannot be combined with the SDK it must not be distributed on Steam. Valve offers no review: the developer warrants having the rights. So **shape A (MIT) and shape C fit**. **Shape B fits too**, because Orb holds the copyright to its own code. | Primary: Valve's open-source page, read 2026-10-05 |
| **What may be public** | The SDK Access Agreement lets you distribute only the contents of its `redistributable_bin` folder with the game. The rest of the SDK must not be republished, so it stays out of the public repo (Platform's private repo plan is right). The agreement also bars reverse-engineering the SDK or replacing its function. The page itself says it holds Valve confidential information, so **do not copy its text into the repo.** I found no limit on open-source-licensing the game. | Primary, but the page is marked confidential: treat details as NDA-class |
| **Never** | Copy code from the **OrbCombat repo (GPL-3.0)** or any GPL or AGPL project into the game: it would conflict with Steam's rule and with shape A. Third-party add-ons (a Steam plugin for Godot) need their licence read first; GodotSteam is MIT as far as I know (not checked today). | Primary and general |
| **Console SDK terms** | **Behind NDA; I cannot read them.** What is known publicly: console SDKs, headers and documentation are confidential and cannot be in a public repo or shipped as Godot export templates; platform agreements make you warrant your rights in the content; GPL-style licences generally clash with console SDKs. Shape A fits the first two. A lawyer reads the actual agreement before signing. | Public Godot console documentation; the rest general and **unverified** |

### 9.3 Steam Deck Verified and the neutral glyph set (RL-037)
- **The rule (primary: Valve's Steam Deck compatibility page, read 2026-10-05):** on-screen glyphs must match the inputs being used, whether Deck, Steam Controller or Xbox glyphs, and keyboard and mouse glyphs must not show when they are not the active input.
- **Verdict on the neutral position diamond: it will probably fail** the literal reading, because it is none of those glyph families. It was right for non-Steam builds, where it avoided the console makers' symbols (RL-037 stands there).
- **Route 1 (best on Steam): Steam Input's own glyph images**, supplied by Valve's API at run time and updated when the player remaps (secondary: Steamworks API guides; I could not read the terms for the images, so confirm in Steamworks that they are free to use in a Steam build). Never commit the images to the public repo or use them in non-Steam builds.
- **Route 2 (works without the API): our own plain lettered glyphs** for Deck and Xbox-family pads only: a plain white circle with A, B, X or Y, and LB, RB, LT, RT as plain labels, no colours, no console shapes. Deck and Xbox use those letter names, so they match; a plain letter in a circle is generic. Keep the neutral diamond for all other pads, because Nintendo swaps A with B and X with Y, and show no PlayStation symbols (circle, cross, triangle, square), which are the PlayStation maker's marks.
- **Consoles:** each maker's glyph and symbol rules are in its guidelines, **behind NDA**; follow them at that point, and do not use their symbols before.

### 9.4 Ratings exposure from civilian casualties
**I cannot predict a rating; the questionnaire does.** Public criteria (secondary: PEGI and ESRB descriptions): PEGI 12 allows non-realistic violence toward human-like characters and fantasy violence; PEGI 16 starts when violence looks as it would in real life. ESRB's Teen band allows violence and minimal blood, with descriptors such as Cartoon Violence and Fantasy Violence; blood and gore and intense violence push upward. Expect **Teen or PEGI 12 or 16** for a stylised side-on fighter, with these as the escalators to watch:
1. **Blood, gore or dismemberment** (the wounds and broken-limb rules): keep any blood stylised or absent, and no severed parts.
2. **Realism of the casualties:** small stylised civilian figures that are knocked out of the scene or fade are safer than visible deaths up close.
3. **Children, hospitals, schools** among the civilians: avoid them, since "violence against innocents" reads worse.
4. **Frequency and focus:** collateral damage is a design pillar, so answer "yes" to violence toward non-combatants honestly.

**What to do:** run the free IARC questionnaire early (Google Play Console and Microsoft's partner programme host it) and the Steam Content Survey with the real build, read the outcome, and decide whether to soften the casualty staging **before** the store page. Do not promise a rating in marketing. Orb should decide how graphic the casualties are meant to be.

## 10. Reconciliation with Marketing's plan (2026-10-05)

Read: `docs/marketing/go-to-market-plan.md` (committed ac8dfd1), its claims table (its section 3), its AI wording (section 4), its risks table (section 13) and its friends-and-feedback rules (section 11). **The "store-copy-draft.md" it points to does not exist in the repository,** so there is no store-page text to screen yet; send it when it exists. A screen, not legal advice.

### 10.1 One wording for the AI statement
Marketing uses my section 1 text as written, which is right. One change to my own text, applied above: "made by one person" read as human-made. The first sentence is now **"Orb Combat EX is a one-person project: Orb directs it and builds it with AI tools."** The rest stands. Everywhere that says "made by one person, Orb, working with AI tools" (Marketing's two-sentence pitch and its claims table) takes the new sentence: **"directed by one person, Orb, and built with AI tools."**
- **Music sentence:** "The music was generated with Suno" goes on a page only **when music ships.** Marketing's plan says there is no music yet, so leave it out until there is, and then use it as written.
- **The seven places** are right. Add: (8) **the repository README, today**: it is public and says nothing about AI-made content; the long form must go at its top **now** (see 10.7); (9) the **tip or sponsor page**, and any social profile that promotes the game (the short form, or at least "built with AI tools"); (10) **the Steam survey must also cover marketing assets** (capsule art, trailer) if they are AI-assisted, not only the game. Steam's survey answers: pre-generated yes; live-generated no (once Orb confirms question 6).
- **In the game:** the About or Credits screen carries the long form, the Godot notice, the font notice and, once music ships, the Suno audio notice.

### 10.2 Claims table, verdict per claim
| Claim | Verdict | Condition |
| :-- | :-- | :-- |
| Free to play in a browser | **Clear** | True while the build is free |
| World wraps, no edges | **Clear** | Only if the visitor sees it on the live build |
| Buildings break in four stages | **Clear** | Same: verify on the live build the day of publishing |
| Every press is a blow | **Clear, hold until live** | Marketing could not confirm brawl slice B1 is on the page; do not use until it is |
| Two fighters today | **Clear** | True. The fighters' names shown must not be KAI (10.4) |
| Five stances | **Clear** | Verify on the live HUD |
| "Made by one person, Orb, working with AI tools" | **Clear with the new wording** | Use "directed by one person, Orb, and built with AI tools" (10.1) |
| "Characters, names and world are all its own" | **Clear as "original characters, world and story"** | The title is under a name clash (section 4), so say "original characters", not "all names" until it settles |
| Positioning hook: "no edges", "wrecked world" | **Clear** | Genre words only; no franchise names |
| README line "inspired by the classic anime energy-brawlers" | **Clear** | Genre inspiration, once, in the README; not in the store pitch, tags or keywords |
| Four fighters, music, controller play | **Do not claim** (agree) | Claim only what a visitor can do today. Pad support exists, but Marketing's point holds until it is tested and shown |
| Online play, consoles, a campaign, twelve fighters | **Do not claim** (agree) | |
| "Will not say" list | **Agree** | Add "made by hand" and "built by one person" without the AI clause |

Marketing's risks row on the licence says the "current CC BY 4.0 content licence lets others sell the assets". **That is not in force.** No licence is chosen and the draft files are not in the repo. The right row: "no licence today (all rights reserved); the draft CC BY 4.0 would let others sell the assets, so it is withdrawn."

### 10.3 What may be called human-made (voice-lab edits)
**Nothing wholesale.** `asset-origins.md` records every shipped class as AI-assisted or procedural, with no human author. So never "human-made", "handwritten" or "hand-drawn" for the game, an asset class or a file. Where Orb's hand is real, say exactly that and no more:
- **"Edited by Orb"** for dialogue Orb altered line by line in the voice lab, supported by the voice-lab diffs.
- **"Written by Orb"** only for a **specific line Orb wrote** (not approved), where the diff or git history shows Orb's wording.
- **"Melody by Orb"** only if Orb hums, sings or plays one into Suno as the audio input and keeps the file.
- **"Directed by Orb"** for the project as a whole.
The record is the proof: before any such claim, the diff or file is named in `asset-origins.md`. I added class-level rows there today (its backlog since 2026-09-29) with a "human contribution" column; Narrative and the EP supply the voice-lab references.

### 10.4 Public clips while the live build shows KAI and VORR (RL-014, M7)
**The hold stands for promotion, not for the page itself.** Facts: the GitHub Pages build and the repository are already public, so M7's "do not host" cannot be met any more. KAI is a NO-GO name (RL-002); VORR is a placeholder not cleared. A free, unlinked hobby page is a low risk. A **promoted** page, clip, post, creator message or thumbnail carrying those names is not: it fixes the names in the public eye just before a rename.
- **Allowed now:** friends play it (Stage 1a), private feedback, no clips, no posts, no links on social media or in communities, no creator outreach.
- **Hold until:** the names a player **sees** are neutral (HUD, intros, results, captions, any screenshot). The code rename can follow. If the full rename stays queued behind two sim slices, a **display-name-only change** in the interface data is enough to lift the hold. Source files and test names still carrying KAI are a Should (S4), not a blocker.
- **Meanwhile:** ask Platform to add a `noindex` meta tag and a `robots.txt` to the site shell so search engines skip the page until the rename lands. It does not hide anything from someone with the link, and it is cheap.
- **The title "Orb Combat EX (working title)"** is also conditional (section 4): no promoted page carries it before the OrbCombat decision.

### 10.5 Privacy review of the feedback form and any signup list
**The three questions (Marketing section 11): clear, as an anonymous form.** Conditions:
1. **Anonymous by default:** no name, email, age or account asked. The free-text boxes can hold personal data a friend types, so say so: "Please do not put personal details in your answers."
2. **A two-line notice at the top:** who runs it (Orb, the project), why (to improve the game), where answers go (the form tool only, not shared), how to ask for deletion (reply to the invitation). Keep it truthful: answers are kept in the form tool and read only by Orb.
3. **Age:** write "for people 16 and over" in the invitation instead of collecting ages (children's privacy rules and the EU age-of-consent rules apply to under-16s; this keeps it out of scope without collecting data).
4. **Where answers go:** a form tool with a privacy statement, not Orb's personal inbox and not a public GitHub issue (issues are public; the in-game feedback panel's public issue is a separate thing and is labelled as public).
5. **Delete** the answers once the findings are written up, and do not quote a friend by name without asking (section 7's testimonial rules).
**A signup list (email addresses): not at Stage 1a or 1b.** An email address is personal data and a list brings duties: explicit opt-in (an unticked box, a plain purpose: "updates about this game, nothing else"), a working unsubscribe, a named sender, and, for US commercial email, a valid postal address in each message; EU and UK rules require consent for marketing email (general rules, not re-read today). **Use platform lists instead:** itch.io follows and devlogs, and Steam wishlists, where the platform holds the data. If a list is still wanted, use a mailing tool that handles the unsubscribe and the address, and ask a lawyer to read the consent text.

### 10.6 Accepting tips
Tips are legal for a hobby project; they bring a few conditions. **Not before** the licence is chosen, the title clash is settled and the music (if any) is on the paid Suno plan, because money makes it commercial use.
1. **Pick one route and read its terms:** itch.io's pay-what-you-want, GitHub Sponsors, Ko-fi or similar. Each needs your **legal name, bank and tax details** with that service and is subject to its region rules (I did not read their terms; country-dependent: ask an accountant).
2. **A tip is a gift, with nothing promised for it.** If a supporter gets a perk (early access, a key, a name in the credits, a vote), it becomes a sale with consumer-law and tax duties and a promise you must keep. Do not offer perks at the start.
3. **The AI statement goes on the tip page** (section 10.1, item 9), and the page makes no claim that tips "support human artists" or the like.
4. **Income is taxable income** in most places: keep records (country-dependent).
5. **No sponsored-content deals** without a disclosure ("sponsored") in the same place as the claim.
6. **Words:** "support the project", not "buy" or "pay for". A free game stays free.

### 10.7 The pseudonym against the name a store shows
- **What the stores see:** Steam and the bank get your **legal name** (the bank account holder name must match your legal ID; the tax interview and identity check use it). The **public developer or publisher name** on the page is a field you type, and "Orb" can go there. Console agreements need a legal entity or, in some regions, a named individual (not read).
- **Copyright notices:** a notice such as "Copyright 2026 Orb" is workable for a pseudonym in the US (it allows the name by which the owner is generally known; not re-read today). It does **not** identify the owner if you ever need to prove ownership or enforce.
- **Enforcement shows the legal name:** a takedown notice is signed under penalty of perjury and is passed on to the other side, so a legal name appears when you enforce. A trade name or a company shields it; a pseudonym alone does not.
- **Trademark:** a mark can be a pseudonym or a title; the applicant must be a real person or entity.
- **The GitHub account name** is public in the repository address and on every commit. If that handle is your legal name, the pseudonym is not separating anything. That is Orb's call, and the one thing to check before deciding the rest.
- **Recommendation:** use "Orb" as the public name everywhere, put the legal name only in the store and bank forms, and ask a lawyer whether a small business entity is worth forming before the first sale (it also helps for console agreements).

### 10.8 How the licence shape changes "free and open source"
| Shape | The wording that is true | The wording that is false |
| :-- | :-- | :-- |
| **A (recommended)** | "Free to play. The code is open source (MIT). The art, music, dialogue, data and the name are not open source: all rights reserved, with permission to play, mod, stream and make fan work." | "Free and open source" for the project; "open-source game" |
| **B** | "Free to play. The source code is available to read and use under the Functional Source License." | "Open source" in any form |
| **C** | "Free and open source" (music excluded: see the audio notice) | |
**Where it appears today:** `CLAUDE.md` line 3 says "Free and open source". It is public, so fix it once the shape is chosen. The README says only "free" and "Licence: not chosen yet, so all rights are reserved for now", which is correct today.

### 10.9 The repository is already public, with no licence
Confirmed 2026-10-05 from GitHub: `dixonbalsagna/orb-combat-ex`, public, no licence, no description or topics, 1,106 commits, 2,961 tracked files, an issues tab, and a Pages site.
**What a visitor may do today.**
- **Play the hosted build** (it is offered), **read the files** and **fork or view them on GitHub**, because GitHub's terms give every user the right to view and fork a public repository within GitHub.
- **Open an issue.**
**What a visitor may not do.** With no licence, copyright reserves everything: they may not copy the code or assets out of GitHub, modify and redistribute them, put them in their own game, sell them, or publish builds. No licence is not a free-for-all.
**Two honest limits.**
1. **It binds only where copyright exists.** AI-written code, art and data may have no copyright in the US, so nothing stops someone reusing those parts. The notice protects Orb's own hand-authored material, the selection and arrangement, and the name. The README says "all rights reserved for now", which is accurate; do not say more than that.
2. **Outside contributions** arrive with no licence, so Orb cannot safely merge them. There is no CONTRIBUTING file or pull-request template in the repo.
**What to change before deciding the licence.** None of this is urgent, and none of it requires choosing the shape:
1. **Add the AI disclosure to the top of the README now** (the long form from section 1). The project's rule is disclosure everywhere it is presented, and the repo is public. (EP or Orb: Legal does not edit the README.)
2. **Add one line to the README:** "Please do not copy or redistribute this code or content until a licence is added. You may play the hosted build." It sets the expectation.
3. **Do not merge outside pull requests** until the contributor terms (DCO or CLA) are in place; add a short CONTRIBUTING note saying so (`contributor-rules.md` has the text).
4. **Keep the repository description and topics free of franchise words** (they are empty now: good).
5. **No tips, sales or promotion** from the repo until the licence, the title and the names are settled.
6. **Know what is public:** every committed document is public, including Orb's verbatim notes in `docs/ep/vision.md`, the director charters, and my screening notes that name franchises as analysis (public-readiness items S3 and S5, which I advised keeping). Orb's private notes are in the git-ignored `.private/` and are not in the repo. Counts today outside `docs/legal`: franchise names in 4 files, a fan game's name in 5, a web series' name in 2, with 0 hits for the old repo name. Marketing should not link to those documents from a devlog. The history is public too, so the "fresh history" option in `public-readiness-edits.md` no longer applies.

## Sources and how well I could read them (all read 2026-10-05)
- **Primary:** [Steam Direct](https://partner.steamgames.com/steamdirect) (fee, tax, bank, identity, waits); [Suno terms](https://suno.com/terms) (effective 2026-09-03) and [Suno pricing](https://suno.com/pricing); [US Copyright Office, AI report Part 2 notice](https://copyright.gov/newsnet/2025/1060.html) (2025-01-29); GitHub and store search APIs for OrbCombat and the title.
- **Secondary (summaries, news, law-firm notes):** [Steam AI policy summary](https://legalmoveslawfirm.com/steam-ai-policy/) (2026-01-17); [Valve update report](https://respawn.outlookindia.com/amp/story/gaming/gaming-news/valve-clarifies-steam-ai-policy-focus-shifts-to-content-consumed) (2026-01-18); [itch.io disclosure](https://80.lv/articles/asset-creators-on-itch-io-now-have-to-disclose-the-use-of-generative-ai/) (2024-11-21); [Thaler cert denial](https://www.mayerbrown.com/en/insights/publications/2026/03/supreme-court-denies-review-in-ai-authorship-case) (2026-03); [EU AI Act Article 50 guide](https://artificialintelligenceact.eu/transparency-rules-article-50/); [FTC reviews rule summary](https://www.morganlewis.com/pubs/2024/08/ftc-issues-final-rule-on-consumer-reviews-and-testimonials); [Godot console support](https://docs.godotengine.org/en/3.6/tutorials/platform/consoles.html); [FSL](https://blog.sentry.io/introducing-the-functional-source-license-freedom-without-free-riding/); [IARC](https://www.globalratings.com/milestones); [Steam Germany ratings](https://partner.steamgames.com/doc/gettingstarted/contentsurvey/germany); [ID@Xbox](https://developer.microsoft.com/games/publish); console AI-policy trade press (Notebookcheck, Otakukart, 2026).
- **Not read:** Valve's own Content Survey page, itch.io's own policy and payout pages, the PlayStation and Nintendo programme terms, the console agreements (NDA), any non-US copyright or privacy law, the Doe v. GitHub decision text. Re-read the store pages themselves when filling in the forms, since policies change.
