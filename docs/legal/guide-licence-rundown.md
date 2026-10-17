# The licence rundown: one page for Orb

Owner: Legal and IP Compliance. 2026-10-16. General information, not legal advice. Have a lawyer read the final files once before the first sale (about an hour). Longer notes: `licence-recommendation.md`.

## The question
You want the game to be open and friendly, and you may sell it later. A licence is the permission slip you give everyone else. It cannot take back what you keep, so pick the one that matches what you want to keep.

## The five choices

| Choice | What anyone may do with it | Can you still sell your own copies? | Fits an open project you may sell? |
| :-- | :-- | :-- | :-- |
| **MIT** (code) | Use, change, copy, sell, even close it up, if they keep your copyright notice | Yes. So can everyone else | **Yes**, for code. Short, famous, and the engine (Godot) uses it |
| **Apache 2.0** (code) | The same as MIT, plus an explicit patent permission and a rule that they say what they changed | Yes. So can everyone else | **Yes**, for code. Longer; useful if patents ever matter |
| **CC BY 4.0** (art, text, music, data) | Use, change, copy and **sell** your art, with a credit | You can, but so can anyone, with your own art | **No, for the art you want to sell the game on.** A competitor could sell your game's assets with a credit |
| **Non-commercial or source-available** (for example CC BY-NC, or a licence like the Functional Source License) | Read, change, run; **not** sell it or compete with it (for a time, in some). They are **not "open source"**, and you may not call them that | Yes, and others may not | A fit if you want the code visible but yours to sell. Costs the "open source" label and some goodwill |
| **All rights reserved** (no licence) | Look and play only. Nothing else without asking | Yes, only you | **Yes for the art, music, writing and name.** It is not "open" |

## What I recommend (the shape I called A)
1. **Code: MIT** (or Apache 2.0 if you want the patent wording). Say "the code is open source".
2. **Art, music, writing, data, and the name and logo: all rights reserved,** with a short plain permission: free to play, mod, stream and make fan work; no reselling or reuploading the assets on their own.
3. **The music (Suno) is never under the open licence.** It has its own notice and Suno's terms.
4. **Sell the official builds** (itch.io, Steam, later consoles). Your protection is the name, being the official version and the updates, not the licence.
5. **Contributors:** ask outside contributors to sign off their work (the DCO), so you can ship their code in paid builds.
6. **Avoid the GPL** for anything you want on Steam or consoles: Steam's rules and console kits clash with it. Never copy GPL code into the game.

## One honest limit
Where AI wrote the code or art, **copyright may not exist** (US law, March 2026 Supreme Court refusal to hear the leading case), and a licence cannot restrict what copyright does not cover. The licence still matters for what you wrote by hand, for how the parts are put together, and as a clear signal. Your real brakes on a copycat are the name (a trademark), being first and official, and the store's own rules.

## What to do now
1. Tell me "A" and I will put the files in place: `LICENSE` (MIT), an assets notice, the music notice, a short contributor note. Today the repository has **no licence**, which means all rights reserved by default.
2. Choose the copyright holder line (your legal name or a company, see the company guide).
3. When you plan to sell, a lawyer reads the files once.

**Ask a professional when:** you want a custom assets licence, outside contributors join, a console or publisher asks you to warrant you own everything, or you change the choice after people have used the code (a licence you have already given cannot be withdrawn from copies already out).
