# Suno music: ruling note for Orb

Owner: Legal and IP Compliance. 2026-10-04. Answers the questions in `docs/audio/suno-direction.md` section 9. A screen, not legal advice. Have counsel read it before the game is sold or the repo goes public with the music in it.

## What I verified, and what I could not

**Verified (2026-10-04, from Suno's terms page, effective 2026-09-03, read through page summaries):**
- On paid plans Suno "assigns" to the user its rights in outputs that Suno owns. On free plans, outputs are for personal, non-commercial use only.
- Commercial use is allowed only for outputs obtained through an approved **download**, within the plan's monthly allowance, and "solely to the extent" the terms of access and use are followed. Rights attach to the download, not to the generation.
- You may not remove, alter or hide any fingerprint, watermark or metadata. Light editing and format conversion are allowed. You may not claim an output is human-made, or use outputs to build a competing product.
- Suno keeps a broad, perpetual, sublicensable licence over outputs **and uploads**, including to improve its models, and it can show that a track was made with Suno. Outputs can also be given to other users: yours is not exclusive.
- I found **no clause limiting public distribution or open-licence sharing** of downloaded outputs.
- Download caps (from a trade report, not Suno's page): free 7 in total, Pro 20 a month, Premier 60 a month.

**Could not verify:** the exact wording of every clause (I read summaries, not the page itself), the separate "Conditions of Access and Use" document, the pricing page, and what Suno's current plan limits count as a download. Orb or Audio should read the terms themselves before generating a lot, because they changed on 2026-09-03.

## Verdict per question

| # | Question | Verdict |
|---|---|---|
| 1 | Public repo and a free open-source game | **Conditional** |
| 2 | What we can claim | **Clear** (modest claim) |
| 3 | Does Orb's direction help, and a human melody | **Clear**: helps, not required |
| 4 | Disclosure on Steam and itch.io | **Required** on Steam, advised on itch.io |
| 5 | Training-data risk | **Conditional** (live litigation) |
| 6 | Uploading our procedural reference clips | **Clear** |
| 7 | Origin record per file | **Clear**, with extra fields |

**1. Public repo and shipping.** Yes, on conditions: (a) generate and download on a **paid plan**, and download every take you keep; (b) keep each file **as downloaded, with its metadata untouched**. Store the original and make any normalised or converted copy from it; (c) stay inside the plan's download cap, which limits how many cues you can keep each month; (d) do not claim the music is human-made.
**Licence statement:** do **not** put `audio/music/` under the project's open licence (MIT or CC BY). We can only pass on what we hold, Suno's terms have conditions that flow down (the metadata rule, no competing training), and the project licence is still undecided. Use a short separate notice (draft below). A plain statement also stays true whichever licence Orb picks.

**2. What we can claim.** Honestly: "We hold the rights Suno assigns to us and a commercial-use licence under its terms." We cannot honestly claim that copyright exists in the audio (the US position is that AI-only output is not protected, and Suno gives no copyright warranty) or that it is exclusive. It matters little for a free game. It matters for two things: others may copy the tracks, and **do not register them in Content ID or a distributor as exclusive**, because the same or similar tracks can be given to other Suno users and a false claim can hit someone else.

**3. Direction, selection and editing.** ADR 0007 says no human author is required, so this is optional. It does help: your selection, arrangement and edits are human contributions, and a **melody Orb sings, hums or plays and uploads as the audio input** is a human-authored composition the track builds on. A hook written by an AI session does not add that. For the main theme, a human melody is the cheap way to get a protectable core.

**4. Disclosure.** Steam: music that ships is AI-made content that must be disclosed (the survey asks for the tool). itch.io: tick the generative-AI field and the Sound option when you list the game, and tag any separate soundtrack. Suno's terms do not require disclosure, but they forbid claiming it is human-made.

**5. Training data.** Suno settled with one major label in November 2025, but in September 2026 two other major labels sued again over its newest model, alleging it still rests on unlicensed songs. That is Suno's dispute, but it means the outputs come from a contested model, and a track could resemble an existing recording. Mitigations: keep the rule that prompts name no artist, band, song or lyric; do not use "in the style of"; **listen to each final** (two people if possible) and run it through a music-recognition app, and reject any that match a known song; keep the prompt with the file; and re-check the litigation before a store launch. Under a consumer plan the infringement risk sits with us, as with other AI tools (`licence-recommendation.md` section 8).

**6. Uploading our reference clips.** Fine, because they are procedural and ours, and you warrant you own what you upload. Two notes: upload only clips with no third-party sample in them, and remember Suno then holds a perpetual licence to them, including for model improvement. These are simple procedural sounds, so that is acceptable.

**7. Origin record.** Audio's sidecar `.txt` is right. Add: model version, plan tier and download date, the song link or ID, the prompt, the names of the uploaded reference clips, who chose the take and what was edited, a checksum of the original, "metadata kept: yes", and the result of the listen and recognition check. Legal adds one row per file or pack in `asset-origins.md`.

## What Orb must do
1. **Generate and download on the paid plan,** keep every original download untouched, and stay inside the monthly cap.
2. **Add the audio notice** (below) instead of putting the music under the project licence, and do not register the tracks in Content ID.
3. **Disclose** the music as AI-made on Steam and itch.io, and never call it human-made. Optionally, supply a human melody for the main theme.

## Draft audio notice (for `audio/music/NOTICE.txt`)
> The music in this folder was generated with Suno and is used under Suno's terms of service (paid plan, downloaded files). It is included to build and play this game. It is not licensed under this project's open licence. Do not remove the embedded metadata. If you want to reuse a track elsewhere, check Suno's current terms first. Copyright may not subsist in AI-generated audio.
