# A5: Orb

Leads: none
Supports: A-QA-01, A-TEXT-01, A-AI-02, A-UI-05, A-AUDIO-02, A-TEXT-04, A-RENDER-06, A-MARKET-05, A-MARKET-08

This page is not a brief. It is the short list of what only you can do or decide in this milestone. Each question has one recommendation; a plain "yes" takes it.

## What you do

1. **Be the tester.** On the second PC, open the real itch.io page, use a real key, and follow the tester guide and nothing else: install, start, read the notice, pick a mode, a fighter and a planet, play a match, rematch, change one control and the picture quality, close the game, open it again and check both held, then make a report with one press. Mark every place you had to guess. Your second player does the same. (A-QA-01)
2. **Mark about 150 lines of text.** The team gives you one list of the words a tester meets (the notice, the start menu, How to play, the match-over card, the report panel, a few settings). For each line write keep, rewrite or cut. Rewrites come back to you once more before they go in. (A-TEXT-01)
3. **Upload the build, once.** The itch.io account is yours. The team hands you the exact command and watches the result with you: put the A5 build up, apply it as an update, go back to the previous build, come forward again. One sitting.
4. **Listen for a minute.** In the A5 build: the quiet background sound, a building coming down, and the menu. Say yes or say what is wrong. (A-AUDIO-02)
5. **Play one match at each difficulty** after the last numbers change and say whether Easy feels winnable and a match feels the right length.

## What you decide before the milestone starts

1. **How hard should Easy be for someone playing your way (right stick to attack, LB to guard)?** Recommendation: a player like that wins about 7 matches in 10 on Easy. (A-AI-02)
2. **When a match ends, where should the result panel sit?** Today it covers the left third of the screen, where your own fighter's corner is. Recommendation: keep it off the winner's corner; when you play alone, off your own. (A-UI-05)
3. **Is a fight with no music acceptable for Alpha?** Recommendation: yes. Add one quiet background sound, sounds for buildings being damaged and falling, and menu sounds; leave bystanders, the gravity well and music for after Alpha. (A-AUDIO-02; decision 21)
4. **Should the Alpha build show "(working title)" beside the name?** Recommendation: yes, on the start menu and on the tester note, until the title search is done. (A-TEXT-04)
5. **Picture quality: three levels for Alpha, or the full range?** Recommendation: three that really work (low, a Steam Deck default, a PC default); the rest of the range after Alpha. (A-RENDER-06)
6. **Will you mark the short list of text, do the fighters speak their approved lines, and is English only fine?** Recommendation: yes to marking; yes to spoken lines if they come from the lines you already approved; yes to English only, and the guide says so. (decision 22)
7. **Is one checklist per tester, ticked and posted to your Discord with the report file, the sign-off you want from each friend?** Recommendation: yes. (A-QA-01)
8. **The campaign at Alpha.** Recommendation: none; the decision and its reason are written down. (decision 18)
9. **The frame-rate targets.** Recommendation: 60 on your PC; for the Steam Deck, 30 held with 40 as the aim, confirmed from your friends' real readings. The Deck's starting picture quality is built to that figure. (decision 19)

## What can wait

- **May Tools ask you to install a free video encoder?** Recommendation: not now. The team keeps full-size picture sequences of every shot until Beta is in sight. (A-MARKET-05)
- **What should "Beta in sight" mean, the point where the waiting period Steam sets before a page can go live starts?** Recommendation: four fighters playable on the Windows and Linux builds, and the Alpha testers' reports folded in. This can wait until after Alpha. (A-MARKET-08)

## What you will notice in the A5 build

No rules have changed since the last build. Numbers have: Easy is easier for someone playing your way, a player who uses only the right stick can win, and matches run 6 to 8 minutes. Because the numbers moved, saved replays from the last build stop playing back, for the last time. How to play describes what is actually on screen. Craters and trenches are drawn where you stand. After this build, nothing in the fight changes before your friends play.

## Amendments after the adversarial review

These override the text above where they differ. The ids in brackets are the review's criticisms (`06-adversarial.md`).

- After the safety checks are green on this build, send it to your friends and ask each for the five-minute speed test. You are asked to name this build as the new look that later changes are compared against. (ORD-09, COS-11)
