# The campaign: the cast's memory, the rematch and the ledger slots

Owner: Legal and IP Compliance. 2026-10-25. Screens `docs/design/campaign.md` (Game Design, committed): section 4 (the cast's memory), section 5 (losing: the rescue, "Previously on" and its rematch, the comeback bet), and section 6 (the ledger's slots) against ln05, c08 and the patent question GD raised. Paper only. **A screen, not legal advice and not a patent clearance:** I could not read the patent's claims in full and I am not a patent attorney. RL-182; new rows mc01 to mc03.

## Verdict: **Pass with conditions.** The design as written (authored fighters who stay the same, beats that read a ledger, no ranks and no promotion) is the safe side of the protected mechanic, and the conditions keep it there.

## 1. "Rivals remember" and the protected mechanic
**What is protected (checked today, secondary sources).** Warner Bros holds US patent 10,926,179, "Nemesis characters, nemesis forts, social vendettas and followers in computer games" (filed 2016-03-25, granted 2021-02-23; Google Patents lists it as active with an adjusted expiry of 2036-08-11, a status the page itself marks as an assumption). From the summaries I could read, it covers a **computer-controlled character whose parameters (rank, promotion, status, strengths, names, appearance) change because of what happens between it and the player's avatar, including a ranked hierarchy of such characters.** I could not read the claim text itself. The famous game that uses it generates enemy individuals with traits, ranks them in a hierarchy, and promotes or powers up the ones who beat the player.

**What the campaign does, and why it sits on the safe side.**
- The cast is **authored roster fighters** (four, growing to twelve), not generated enemy individuals. Their stats, moves and looks are the same every time.
- The memory is **a ledger of results** (`last`, `wrecked`, `home_wear`, `thread`) that **picks which authored line plays and which authored ground the stage uses.** Nothing about a fighter changes.
- **No hierarchy, no ranks, no promotion** of enemies, as GD already states. The "high ground" a rival holds and the "claim" a villain keeps are places on a ring, not positions in a ladder.
- The only adaptation is **on the player's side** (the lesson: a slightly wider tech window for one episode against the one who beat him), which changes no non-player character's parameter.

**Conditions (mc01).**
1. **No parameter of any non-player fighter changes because of what happened between him and the player's avatar:** no rank or title earned, no promotion or demotion, no new ability, strength, weakness or fear, no change of name or appearance, no "stronger because he beat you" and no "weaker because you humiliated him". "Angrier" and "he wants a rematch" are **line choices and beat tone only.**
2. **No procedurally generated enemy individuals** with names, traits or histories, and no ladder or chain of command among the cast (lieutenants who replace fallen bosses, war chiefs, a ranked list that shifts). Henchmen stay graded by column and anonymous, with no memory.
3. **Keep the ledger's job to selecting lines, grounds and beats.** If a future feature wants a fighter's behaviour, stats or looks to depend on past meetings with the player, stop and ask me first.
4. **A patent attorney reads claim 1 of US 10,926,179 and its continuations before the campaign ships or sells** (one hour). Until then the conditions above are my working line. Cost is small next to the risk: a patent is infringed by what a game does, whether or not the code was copied, and the original ideas rule does not protect us from one.

## 2. Section 5.2: "Previously on", the lesson and the guaranteed rematch: **Pass**
- **"Previously on" and "To be continued"** are ordinary television phrases; fine as card text.
- **The training stage and the lesson:** a drill against what beat him, and a gain for that episode only, never carried past the run: fine (player-side only, mc01).
- **The rematch on the ground that fell:** a stage placed by the place's **wear state** (damaged or fallen), with the fighter who beat him. Allowed under ln05 because it reads a place's state and a fighter, never a person lost. **"Fallen" is a wear state only: no card, line or beacon about who or how many were lost there.**
- **The rival "who won holds the high ground" and "the villain holds his claim":** colour on the ring; no ranks.
- **5.1 (the rescue):** a friend takes over when he falls; the ally is a roster fighter under the player's control. Fine. If the ally wins, a beat and a chance he returns as a partner place: that is a thread, not a promotion.
- **5.3 (the comeback bet):** held back; if built, it is a retry for a keepsake or boon with no real money: **ln03 holds** (nothing sold, nothing paid, no hidden random reward for money).

## 3. Section 6: the ledger's slots against ln05
`last`, `wrecked`, `home_wear`, `place`, `prev_place`, `next`, `n_left`, `rescued_by`, `lost_episode` and `lesson` all read results, places, wear and fighters: **pass.** `toll_band` stays coarse, never a score and never read by a Cyborg line: **pass.** Conditions (mc02):
1. **`thread`** (a debt, a grudge, an ally who switched sides) is about **fighters and places' wear only.** No thread is a casualty, a toll, a victim, a promise to avenge anyone, or a debt owed to the dead.
2. **`lost_episode`** reads the place (where) and the fighter (to whom). It never reads what was lost in people.
3. **`wrecked` stays structure and terrain only** (a tower, a pier, a crater, a fire), never derived from a casualty event; the Cyborg's `home_wear` reads only his own yard; fronts and homes read place and wear only. (As ln05.)
4. **Co-op blame:** "a death on the ring is on whoever caused it" is a count for the meters only. **No per-player casualty tally appears on any screen, results page, comparison, leaderboard or achievement,** and the menace and anguish meters stay power meters, not scores (c08).
5. **Saves across days are local:** no personal data. If cloud saves or online co-op come later, the privacy line and the store answers must change first.

## 4. Anything else in the campaign
Nothing else in the design raises a legal point: drop-in co-op, the ring as route, the boons in the world and the edge beacons are ordinary design; the arc boss's catastrophe falls under c01 to c09; the beat library is already screened (RL-173).

## Rows
`mc01` (no change to a fighter from what happens to the player), `mc02` (the ledger's slots and the co-op tally) and `mc03` (the patent read) are in `movegen-banned.json` under a new "mechanics" list.
