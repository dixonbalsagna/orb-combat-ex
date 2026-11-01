# A combo builder for the custom fighter campaign

Research & Prototyping, 2026-11-01, on Orb's idea (end of `docs/ep/vision.md`): win a first training fight against Grist, and he teaches you one of three two-part combos, such as "Hold Y then Mash X" or "Tap X then Hold B". You unlock, upgrade and replace combos over time. This is a spitball and nothing here is decided.

**My recommendation: the combos you learn are yours for good, three at a time, and each run adds upgrades that last only for that run.** So your fighter becomes more *yours* with every run, without becoming stronger than anyone else's. That is loop 1 below. It's a small build, because the fight already has most of the plumbing: a "phrase" system is on the feature map for the first playable, where a short pattern of presses swaps in chosen moves without changing their damage or timing.

**How far to trust this.** I read reviews, guides, player forums and one talk summary, not studies, so these are patterns other games show, not proven results. Some of the sources were weak. I also can't confirm which console brawler Orb remembers: the closest I found lets you buy moves and set your chain in the pause menu. Nobody has played any of this.

## What other games teach

| What the game does | What happened | What we take |
| :--- | :--- | :--- |
| A console brawler with a custom combo builder: you buy or find moves and set your chain in a menu | Reviewers named it as what set the game apart | Orb's memory holds up. The chain is the character |
| An online martial arts game: each attack starts and ends in a stance, so you build chains that flow. You learn a move by defending against it | Reviewers found it deeply engaging and also "overwhelming at first" | Learning from a fight feels great. A blank builder at the start doesn't |
| An action roguelite: pick one of three god-given upgrades per room, for that run only. Special combined upgrades appear only once you hold the right two | Choices keep shaping the run all the way through | Run-only power keeps runs fresh. Hidden pairings give "I found something" moments |
| A deckbuilding roguelite: pick one of three cards, or skip | Its makers aimed to give every card a place, not to make all cards equal, and tracked how often picks and skips won | Always allow "no thanks". Measure every option |
| An action roguelite: each unlock joins the pool of things you might find | Guides warn against unlocking too much, because your favourites get rarer. Players ask to remove items | More unlocks must never make your game worse. The player controls the pool |
| A martial arts roguelite: buy a skill five times and it's yours forever | A clear goal that makes lost runs still count | Permanent things should be earned by repeated use |
| Stylish action games: repeating the same attack lowers your style score | It pushes variety, but players can ignore it, and it stops mattering once you hit the top rank | A score alone won't change habits. The fight itself has to answer |
| A fighting game with custom move sets: at first ranked play allowed only pre-built sets, because custom ones were too hard to balance. Customs came later with some moves banned, and sets locked before going online | Custom sets did reach ranked play in the end, with those limits | Plan the fair version from day one |
| A platform fighter's custom moves were kept out of competition, partly because they were so tedious to collect | Competitive players went without them | Never make versus depend on a long grind |

## The questions

**How fast to unlock.** One combo after the first fight, a second by the end of the first planet, and a third in that first hour. After that about one offer per planet. New things come as story moments, from a teacher, never from a shop screen. The list should stay small enough to learn by heart.

**Upgrade or replace.** Both, doing different jobs. **An upgrade changes how a combo works:** a third hit, a stun, a longer send. **Replacing changes who you are.** An upgrade should tempt you to keep a combo, and a new offer should tempt you to swap it, so that's the real decision. A replaced combo goes in your book and can come back between runs, so there's never a bad swap to regret.

**Per run or permanent.** The campaign already has a rule that no stat carries past a run. So **what you know is permanent, and how strong it is resets.** This matches Orb's "save file per custom fighter": your fighter keeps their style, and each run still starts fair.

**Keeping three options meaningful.** Three options differ by *job*, not by strength:
- one that fits what you already use;
- one that fills what you lack (you have no way to break a guard; here's one);
- one wild card you wouldn't have thought of.

Show each as a four-second clip with the buttons drawn at the edge, not a stat sheet. Always offer "keep what I have", with a small reward. **Each one should also feel different in the hands:** a mash, a hold, a tap.

**What makes players try new combos.**
- **Rivals learn your favourite.** A boss who has seen your most-used combo starts guarding it, and says so in a line. I'd expect this to break habits better than any score, and it's a fun story beat.
- **Teachers ask you to show them.** "Land it three times" earns the upgrade, so using a new one pays right away.
- **The place finishes it.** Already on the map: the same combo ends differently on water, in a city or on a cliff, so old combos stay surprising.
- **A hidden pair.** Two combos used back to back sometimes unlock a third. Finding one is worth telling a friend about.

**What kills these systems, and the guard against each.**

| Killer | Guard |
| :--- | :--- |
| One best build | All combos share a damage budget. A move's look and effect change, and its worth stays in a narrow band. Track how often each is picked and how often it wins, then tune the outliers |
| Menu fatigue | One screen between stages, under 30 seconds, and never mid-fight. Built from clips, not numbers. Skipping is fine, and a sensible default fills your slots |
| Too many inputs | Three slots. Two parts each. Only tap, hold or mash on X, Y or B. No new buttons. **If you don't use a combo at all, every press still works as normal,** so no player is punished for forgetting |
| A diluted pool | Your book is yours to curate, and you can switch off anything you don't want offered |
| Hands that hurt | Mashing and holding must work with the game's assist settings, so a mash can be a toggle. Orb wants mashing to count, so this one is needed from the start |

**Arcade and versus fairness.** Orb wants custom fighters in both.
- **Arcade:** anything goes. Run upgrades may apply.
- **Versus:** three combos and no run upgrades or stats. Since a combo changes moves and effects within the damage budget, everyone's equal in strength.
- **Everything is available in versus from day one,** or nearly, so nobody has to grind to compete. A friend who hasn't played the campaign can still pick from the full list. Campaign unlocks are your story, not your ticket in.
- **Both players see each other's three combos** on the loading screen. That removes the "what was that?" problem custom fighters cause.
- **Online:** set before the match and sent as part of the match setup, so both machines agree. Moves stay readable by keeping to the same pool of animations.

## Three loops

### 1. The belt and the run (recommended)

Three combos on your belt, kept for good. Teachers offer one of three after big moments. Within a run, upgrades pile on and reset at the end. After a won run, you keep one upgrade as a permanent alternate version, different rather than stronger.

**The first hour.** You make your fighter and meet Grist for a training fight, which you win. He shows three clips: Hold Y then Mash X, a slow gathering blow into a flurry; Tap X then Hold B, a quick jab into a heavy send; Mash X then Tap Y, a flurry capped by a stagger. You like the send, and pick it. On the first planet you land it on a brute, and it throws him into a building. A chime plays, and you start looking for it. After the first boss, Grist offers an upgrade: a third hit that drags him back in. Later a stranger on the road offers a guard breaker, and your belt gets its second combo. You lose to the planet's boss, who starts blocking your send the second time. The run's upgrades are gone, and your two combos aren't. You start the next run already knowing what you want.

**Why this one.** It's Orb's picture almost exactly, fits the rule that no stat carries past a run, is fair in versus by design, and needs the least new work. **Its risk:** three slots may feel small after 20 hours. A fourth slot can be a late-game reward if so.

### 2. Snap-together

You learn first halves and second halves separately. Any opener joins any finisher. Five of each is 25 combos from ten things to learn, and openers set something up (a stun, a lift, a pull) that certain finishers pay off.

**The first hour.** Grist teaches you one opener of three, Hold Y, a gathering blow that stuns, and you already have a basic finisher. After the first fight a teacher offers a finisher, Mash X, a flurry that hits harder on a stunned foe. You join them and it clicks. By the end of the planet you have two of each, and you spend a minute in training trying all four. One of them, Tap X into Hold B, turns out to be much better against flyers. You feel clever, and you go looking for more.

**Strongest for discovery, and it's the most fun to talk about.** But it needs far more balance work, since every pair has to be fine, and players may just look up the best pair online. It's a good later upgrade to loop 1 if the belt feels small.

### 3. The pure run

You start every run with only Grist's first combo. Every stage offers one of three, and you build a full set from nothing each time. A win adds a new option to the pool.

**The first hour.** You pick a combo from Grist, then another after each stage, until by the fourth stage you have five, and you're using two. You lose at the boss. You start again with one combo, and a different fighter's worth of offers. By the third run you've seen a dozen combos, and you've stopped trying to remember them.

**The most varied, and the wrong fit.** A character who forgets their moves each run works against Orb's custom fighter, whose save file is their identity. Five or more combos a run also means no time to learn any of them by hand. I'd only use it as a separate challenge mode later.

## What this needs, and what's open

- **The fight's part is close to the phrase system on the feature map.** It would need holds and mashes as parts of a pattern, since phrases are written as presses today, and a way to take a phrase from the player rather than from the fighter's seed. Combat and Encounter should cost it.
- **The pool of moves.** Orb pictures a pool kept separate from the generic one. Custom fighters have no moves of their own yet, and every combo needs animations that pass Legal's rules on moves. That's the largest unknown cost, and Animation should size it.
- **Damage against Orb's "stats".** Orb mentioned stats and effects on each move. I've kept damage in a narrow band for fairness and let effects carry the differences. If Orb wants real strength differences, they can be campaign-only.
- **Only people can answer whether it's fun.** A paper prototype of the three-clip choice, or a one-page playable, would test the hardest question first: do players care about the choice in the first minute?

**Sources.** Reviews, guides, forum threads and a talk summary found on the web, 2026-11-01. The list went to the EP separately, so no game names appear here.
