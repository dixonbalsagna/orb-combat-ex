# The licence rundown, version 2: what to pick, and why

Owner: Legal and IP Compliance. 2026-11-09, for Orb and for the weekend Alpha audit. General information, not legal advice. It replaces the 2026-10-16 version. Longer notes: `licence-recommendation.md`. **The code stays all rights reserved until Orb picks.**

## What a licence is, in four lines

A licence is the permission slip you give everyone else. With no slip, **all rights are reserved**: people may play your game but may not copy, change, sell or repost it. That is where the project is today. A slip you hand out can be **loosened later but never taken back from copies already out there**, so the safe order is to start closed and open up when you are sure.

## Three kinds of thing, treated separately

| Part | What is in it | Today | The catch |
|---|---|---|---|
| **The code** | The game's rules, the fight director, the tools | All rights reserved, no licence file | Some of it was written by AI under your direction (see "One honest limit") |
| **The art, writing, data and name** | Drawings, animation, dialogue, design documents, the fighters' and moves' names, the title | All rights reserved | The **name** is protected by trademark rules, not by a licence, and the title still needs a proper search before any store page (the small OrbCombat project) |
| **The sound** | Sound effects and grunts: made by our own code, no recordings. Music: none shipped yet; Suno is the plan | Sound effects follow the code. Music has its own rules | Suno's terms apply to any music: paid plan, files kept exactly as downloaded, and the music never goes under the code's licence |

Whatever you pick for the code, the other two stay separate. Mixing them is how projects accidentally give their art away.

## The options, from closed to open

| Option | In plain words | A free game on itch.io now | Steam later | Keeping commercial control | Friends and future contributors |
|---|---|---|---|---|---|
| **1. All rights reserved** (today) | You keep everything. Players can play and nothing else | Fine. itch.io lets you restrict a page and give keys to testers | Fine. Steam does not ask for any licence | **Highest.** Nobody may copy or sell your work | Friends can play and tell you what they think. They cannot reuse anything. A contributor needs a short note giving you the right to use their work |
| **2. All rights reserved + a plain permission page** | The same, with a friendly paragraph: free to play, stream, record and make fan work; no reselling or reuploading | Fine, and it reads as welcoming | Fine | **Very high.** It lets fans in without handing anything over | Friends and fans know where they stand. Same contributor note |
| **3. Source-available** (for example the Functional Source License, or PolyForm Noncommercial) | People can read and run the code; they may not sell it or compete with it. It is **not "open source" and you may not call it that** | Fine | Fine. Steam does not care whether source is visible | **High.** Code is visible, but nobody can sell a clone. Some licences (FSL) turn into MIT after two years | Friends and contributors can read, learn and help. Contributors need the same note, and you need it to relicense |
| **4. Permissive open** (MIT or Apache 2.0 for code, CC BY 4.0 for art) | Anyone may use, change, sell and even close it up, with a credit | Fine | Fine | **Low.** Anyone may sell your code. CC BY lets a rival sell your art with a credit | Friends and contributors are fully free. Contributors keep the same licence by default, so you cannot later close their part |
| **5. Copyleft** (GPL, CC BY-SA) | Anyone may use it if they share their changes the same way | Fine | **Avoid.** Valve calls GPL with Steam's SDK "problematic", and console kits clash with it | **Low and awkward** | Strongest sharing, hardest for a paid game |

## True whatever you pick

1. **Godot's notices must ship.** The engine is MIT licensed and Open Sans (its default font) is OFL licensed. Both notices appear in a credits and licences screen and on the public About page; every build must keep them.
2. **A licence changes who may copy, not who made it.** Credits for you and any contributors are a courtesy you write down; they are not a licence term.
3. **The name and the originality rules stand.** Every name, whole character and asset must be ours, and the title still needs a professional search before a store page (RL-024, the CD-06 audit item).
4. **The music is separate.** Suno's terms attach to each downloaded file. Never put music under the code's licence.

## One honest limit

Where AI wrote the code or drew the art, **copyright may not exist** in the US (work with no human author is not protected; the Copyright Office's guidance says directing, choosing, arranging and editing a work counts as human authorship, but a bare AI output does not). A licence cannot restrict what copyright does not cover. I last checked this in October and have not re-checked it since; a lawyer should confirm before the first sale. The licence still matters for what you wrote by hand, for how the parts are put together, and as a clear signal. Your real brakes on a copycat are the **name** (a trademark), being the first and official version, and the store's own rules.

## My recommendation

**Keep everything all rights reserved through Alpha (option 1, with the plain permission page of option 2), and make the public-code decision at Beta, with a lawyer's one-hour read. If you then want the code visible, use a source-available licence (option 3) for the code only, and keep the art, writing, sound and name all rights reserved. Do not use MIT or CC BY.**

Why:
1. **You told us you want to keep more commercial control.** Options 1 to 3 do; option 4 does not, and a licence you give cannot be taken back.
2. **Nothing forces the decision now.** Alpha is private, with named friends on an itch.io page with keys. They only need to play, and the permission page gives them everything they need.
3. **Closed is the one direction you can reverse.** Opening later is easy. Closing after people hold copies is not.
4. **Steam and itch.io do not care.** Neither needs any licence, and options 1 to 3 all work on both.
5. **Because AI wrote part of the code and art, a licence protects less than it seems,** so the name, the polish and being the official version matter more. That is another reason not to give away rights now for a goodwill gesture.
6. **Beta is the right moment.** That is when the Steam demo, the title search and the lawyer's hour all happen, so one decision covers them.

## What I need from you, and what I will do

- **From you, one line:** "keep all rights reserved through Alpha." No files change.
- **I will write on request:** the plain permission page (a paragraph for the README and About page), and a short contributor note (when someone outside sends code or art, they agree that you may use and relicense it, and they keep their credit).
- **Ask a professional when:** you pick option 3 or 4 (the exact licence text and version), outside contributors send code, a store or publisher asks you to promise you own everything, or you change your mind after people have copies.
