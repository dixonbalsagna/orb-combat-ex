# ADR 0010: The look gate. How the game plays comes before what a test measures

- Status: accepted (Orb, 2026-10-18)
- Context: in the week of 2026-10-14 a set of changes made to pass the automated flash count went live. They were the cut dissolve, slow strip wipes, a calm hazy look, a soft beam layer and steady rings round the beam struggle. Each passed the gates (determinism, parity, render checks, flash count), and none was looked at in play or shown to Orb. Orb played the re-published demo and found it worse than the build they had liked: fading, blur, a grey circle, a strange-looking screen and frame drops. The cut dissolve also read the whole frame back from the GPU on every cut. Orb: "it would look cheap on a powerpoint presentation... if I had any idea what was cooking up with the dissolve nonsense I would have stopped it right away."

## Decision

1. **A visible change needs a picture before it is committed.** Any change that alters what a player sees on screen (camera, rendering, VFX, UI, animation, art in the build) ships only with a side-by-side: the same scene at the same ticks on the reference build and on the change (`node tools/flash/side-by-side.mjs`; stills plus a short GIF). The EP looks at it before committing. If it looks worse, it goes back, whatever the gates say.
2. **The reference build** is the last build Orb played and liked, recorded in `docs/ep/taste.md`. It moves only on Orb's word.
3. **No metric overrides the look.** A change made to satisfy a test (flash, performance, a band) that also changes the look is a creative decision. It goes to Orb as a short visual question (clips, not numbers) before it ships, or it doesn't ship. Safety concerns are met with warnings and settings, not by degrading the default look.
4. **The taste list** in `docs/ep/taste.md` names what Orb has rejected and what Orb wants. Briefs and reviews check against it. Banned outright: screen dissolves and cross-fades between shots, slow slide-style wipes, fade-to-black transitions in play, full-screen blur or haze, persistent rings or markers drawn over the fighters, and anything that costs frame rate for presentation.
5. **Cost check for visuals.** A visual effect that reads back from the GPU, copies the frame or adds full-screen passes needs Performance's timing on the web build before it is committed.
6. **A preview Orb can open.** Before each re-pin of the public demo, Orb gets the link and a 30-second clip of what changed. A re-pin that changes the look waits for Orb's word or a day's notice.

## Consequences

- Reviews take a little longer, and visual changes arrive with pictures.
- The flash work is paused (Orb, 2026-10-18). The warning, the Reduce flashing lock and the nightly seeds stay as safeguards.
- Director charters for Camera, Rendering, VFX, UI and Animation carry the look gate as a standing rule.
