# Store copy draft: originality and claims screen

Owner: Legal and IP Compliance. 2026-10-05. Screens `docs/marketing/store-copy-draft.md` (sections A to E, 22 claims), against `go-to-market.md` sections 1, 7 and 10. From the written draft; the live build was not played. A screen, not legal advice. Nothing here lifts the promotion hold: that is a separate ruling when UI's name switch is live.

## Verdicts

| # | Item | Verdict |
| :-- | :-- | :-- |
| 1 | Copy A1 (itch.io) and A2 (Steam skeleton) | **Clear with six edits** (below) |
| 2 | Tags and keywords | **Clear**, four conditional |
| 3 | Never-use list | **Clear, move the franchise words out of the Marketing file** |
| 4 | Capsule art and trailer plan | **Clear with conditions** |
| 5 | A trailer may carry a Suno track | **Yes, conditional** |
| 6 | The 22 claims, plus three the copy makes that are not listed | **Per claim, below** |
| 7 | Reads as human-made, or as an endorsement | **Nothing as a claim; two phrases to fix** |

## 1. Edits to the copy

1. **"Fight an AI opponent"** (A1) reads as a generative-AI claim next to an AI-disclosure paragraph, and a skimming reader may take the fight director for an AI model. Say **"a computer-controlled opponent"** (or "CPU opponent") everywhere. And add one plain sentence to the statement's last lines: **"The game's procedural systems (planets, fight choreography, the opponent) are ordinary code, not AI models running while you play."** (This is a clarity edit to my statement; use it everywhere with the rest, unchanged.) Keep "fight director" if it reads as a game term.
2. **"[There is no voice acting]"**: the game has **synthesised vocal sounds** (the grunt generator, AUD-GEN-002). The true sentence is: **"There is no voice acting. Character vocal sounds are synthesised by code."** Keep it bracketed until Orb confirms.
3. **"Original characters, world and story"** (my 10.2): drop "story" until a story ships, so it does not imply a campaign. Use **"original characters and world"** (C24 and the pitch). I amended 10.2 to match.
4. **Privacy paragraph** ("This game collects no personal data"): replace with the line from `go-to-market.md` 9.1, verbatim: "This game collects and sends no personal data. The web version is hosted on GitHub Pages, which keeps its own server logs. The feedback button opens a public GitHub issue page only when you click it." "Not made for children under 13" stays.
5. **"[Title] is a trademark of [holder]"** (A2): use "™" only once the title is settled and in use, and **never "®" or "registered"** until a registration exists (a false ® is a deceptive mark). Say "[Title] and its logo are trademarks of [holder]" only when the holder line is decided.
6. **itch.io AI field:** tick graphics, text and dialogue, and code now. Tick **sound** when the Suno music ships, since today's sound effects are code-synthesised (and the page says so). Steam's survey adds music then too.

## 2. Tags and keywords

| Tag | Verdict | Condition |
| :-- | :-- | :-- |
| Fighting, Action | Clear | |
| Anime | **Clear, conditional** | A genre word. Use it only if the final art reads as anime-styled; never next to a franchise word |
| Local Multiplayer, PvP | Clear | Only if one-screen versus is in the build |
| 2.5D | **Conditional** | Art to confirm the word is true of what a player sees |
| Destruction | Clear | |
| Indie, Singleplayer | Clear | |
| Controller | **Hold** | After controller play is tested on the build |
| Fast-Paced | Clear | A judgement; fine if playtests agree |
| Flight, Physics | **Conditional** | Only if a player would call them true |
| Free to Play | **Conditional** | Only if the Steam release is free |
| itch.io: fighting, action, local-multiplayer, anime, destruction, godot | Clear | "godot" names the engine factually: no Godot logo unless its brand rules allow, and no wording that implies Godot's endorsement |
| Hashtags (#fightinggame, #indiegame, #indiedev, #gamedev, #godotengine, #madewithgodot, #anime and the search phrases) | Clear | Genre and tool words only |
| The AI tag | n/a | Comes from the AI field, not from us |

## 3. The never-use list

The list is right and complete in substance, with two notes. **It names franchise words inside a public repository file**, which is the thing the list exists to prevent, and puts them next to the marketing copy. Keep the categories in `store-copy-draft.md` ("any franchise, character, move or place name, and the franchise's signature words") and the exact words in **`docs/legal/never-use-words.md`** (I created it today as the single source). "Ki" is already replaced by CHARGE in the interface, so the player-facing ban holds.

## 4. Capsule art and trailer plan

Clear, with these conditions (all in addition to the plan's own rules):
- **Logo and lettering:** if the logo is AI-made it has no copyright, and a trademark does not need one, but a logo needs its own screen against look-alikes: **no chrome-bevelled or gold-and-orange 3D letters, no star or dragon motif, no letters that echo a franchise logo.** A plain wordmark in a licensed font (one row in `licence-register.md`) is the safest and cheapest.
- **Key art and thumbnails:** the stacking rule applies to **any single frame or thumbnail**: at most two of the seven marks (no body flame aura plus a scream, no rubble ring with cracks and lightning together), no hero holding a sphere aloft, no hair colour change. Check moment 4 (a crater) and any beam frame.
- **Screenshots and clips:** no frame shows KAI, VORR, "Meridian" or the working title in the HUD, intros, results, captions or the window title, until the names are neutral (the hold). No browser chrome or personal data in frame; another player's face, name or voice only with permission.
- **Trailer end card:** carries the statement (as amended). No platform or engine logo unless its brand rules allow, and never as an endorsement. No "official" in the title.
- **Origin rows:** every asset gets its `asset-origins.md` row before it goes on a page (the plan says so; I add them on receipt).

## 5. May the trailer carry a Suno track?

**Yes, conditional.** Under the paid-plan terms (suno.com/terms, effective 2026-09-03, re-read 2026-10-05) commercial use is allowed for a track you downloaded through an approved channel on a paid plan, and a trailer advertising the game is a commercial use of the game's own track. Conditions:
1. The track was **generated on a paid plan** (Pro or Premier) and **downloaded** through the approved download, within the plan's cap.
2. The **untouched original and its record** are kept (`suno-music.md`). A trailer edit (gain, cut, fade) is ordinary processing under the metadata rule.
3. The **end card or description says the music is Suno-generated**, consistent with the statement, and nothing calls it composed by Orb.
4. **No Content ID or distributor registration as exclusive.** Suno can give similar tracks to other users, and a platform's automatic match can flag a trailer; if that happens, dispute with the original download and the record.
5. The track passed the **listen-and-recognise check** (`suno-music.md` item 5), since the training-data lawsuits are live.
6. Uploading to Steam, itch.io or a video site is distribution of the game's own marketing, within the same terms; I found nothing in the terms that bars it.

## 6. The claims

| ID | Claim | Verdict | Condition |
| :-- | :-- | :-- | :-- |
| C1 | Free to play in your browser, no install | **Clear** | Verify in three browsers. Do not add "runs on any device" |
| C2 | A side-on energy brawler | **Clear** | |
| C3 | For one or two players | **Clear** | Verify two-player |
| C4 | Every press is a blow | **Clear** | Verified live (B1). Never "balanced" or "fair" |
| C5 | Buildings break in four stages | **Clear** | Verify |
| C6 | Craters stay where they land | **Clear** | Verify |
| C7 | The planet has no edges | **Clear** | Verify across the seam |
| C8 | Five stances | **Clear** | Count on the HUD |
| C9 | Two fighters with different personalities | **Clear** | |
| C10 | A different opening to each fight | **Clear** | Verify |
| C11 | Early build: two fighters, no online play | **Clear** | |
| C12 | Controller or touch controls | **Hold** | Until tested on each device |
| C13 | [N] fighters | **Do not claim until true** | |
| C14 | Modes | **Do not claim until true** | |
| C15 | The AI statement | **Clear** | With edits 1, 2 and the Suno sentence only when music ships |
| C16 | "There is no voice acting" | **Hold** | Replace with "There is no voice acting. Character vocal sounds are synthesised by code", after Orb confirms |
| C17 | Nothing is generated by AI while you play | **Hold, then clear** | Orb confirms, and add the procedural-code clarifier (edit 1) |
| C18 | Collects no personal data | **Replace** | With the 9.1 line (edit 4) |
| C19 | Not made for children under 13 | **Clear** | |
| C20 | [Title] is a trademark of [holder] | **Do not claim until true** | Edit 5 |
| C21 | Open-source code | **Do not claim until true** | Shape A or C only |
| C22 | Steam Deck Verified | **Do not claim until true** | After the badge |
| C23 | Directed by one person, Orb, and built with AI tools | **Clear** | |
| C24 | Original characters and world | **Clear** | Not "story", not "all names" |
| **Missing from the list** | | | |
| C25 | "A computer-controlled opponent" (was "an AI opponent") | **Clear** | Edit 1 |
| C26 | "A fight director that choreographs the exchange you choose" | **Clear** | A game term; add it to the list with its evidence (`docs/design/`) |
| C27 | "Each with a different relationship to the destruction around them" (A2) | **Clear if verified** | Verify the two fighters behave differently on the live build; otherwise drop |

## 7. Human-made and endorsement reads

- **Human-made:** nothing in the copy claims it. Two phrases to watch: **"real captures"** and **"Orb picks a licensed font"** are accurate (real footage, a human choice) and must stay specific, never "real art" or "crafted". And **"the game's own Suno track"** is fine and must never become "our composer".
- **Endorsement:** none implied. Naming tools factually is fine (Claude by Anthropic, Suno, Godot, Steam). Not allowed: any logo used without its brand rules, "in partnership with", "powered by" or "approved by" any of them, and Steam Deck Verified before the badge.
- **One more read:** "Free to Play" as a Steam tag has a specific meaning on that store (no upfront price). If the Steam release is paid or has tips, drop it.

## 8. The capture hold (Marketing's open question 6)

Not lifted by this screen. It lifts when UI's name switch is live and I have seen that **no player-visible text, caption or intro shows KAI, VORR, "Meridian" or the working title**. Then: **capturing and storing screenshots and clips privately may start**; **publishing** any of them waits for the title decision (an end card, a logo or a page needs a title) and for this screen's edits. Tell me when the switch is live.
