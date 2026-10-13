# The lobby: how a tower lets a fight behind it be seen (2026-10-12)

Owner: Rendering and Technical Art. Built to Orb's ruling of 2026-10-12, shown a tower holed and a tower sunk to a stub and told of a third way: "'open floors' sounds like it would look the most natural, get that implemented". Reworked the same day: the first build stood a tower on a few thin posts, and Orb's standing word is that buildings must look structurally believable where floors are opened or cut ("gaps between floors without realistic looking supports will make players lose their suspension of disbelief", `docs/ep/vision.md`). Render only: it reads the sim and writes nothing to it. The gameplay hash is unchanged.

**It needs depth to be seen.** A fight stands behind a tower only when depth is on, and no match has depth on yet. It was built, checked and recorded against a scratch build whose match starts with depth on and whose scene moves the two fighters. With depth off nothing of it runs and the picture is as it was.

## The rule in one line

**The lobby is the building's and the patch is the fight's.** A tower with a fight at street level behind it opens its lobby. Whatever the lobby cannot show, the see-through patch shows, as on a low building.

## What it does

- **A tower standing between the camera and a street-level fight opens its lobby in that pane:** one storey at the ground, two floors tall, open through the building. The street behind shows under the tower. The tower above and the skyline stay.
- **A fighter above the lobby's ceiling is shown by the patch,** the same stippled window a low building gets, cut through the tower's wall round him. The lobby shuts when nobody is seen under its ceiling.
- **A damaged or breaking tower has no lobby.** It never opens one and does not keep one open: the patch alone. (A choice: see the table below.)
- **Behind two blocks, both lobbies open.**
- **It opens before the fight is hidden,** and shuts three quarters of a second after the fight is clear.

## What it is built to

Orb's requirement is real-looking supports. The particulars came from Legal's first screen of the stills (`docs/legal/city-and-open-floors-screen.md`). Legal has since withdrawn them as conditions (they rested on a rule Orb withdrew) and names three as Orb's own design requirement. The rest are kept here as design choices, and are Orb's to change.

| Asked | Whose | How |
|---|---|---|
| Sturdy columns in a regular row, each about a twelfth of the front's width | Orb's requirement | Four columns on every side, the two corners and two between, evenly. Each is a twelfth of its face wide (`OPEN_COL`): 56 units on a tower 675 wide, against the first build's 9 |
| A deep beam or slab edge visible above | Orb's requirement | A beam 26 units deep on the columns, all round (`OPEN_BEAM`), in the columns' stone, its foot in its own shade |
| A lit lobby, warm, not black | Orb's requirement | Seen from under it the lobby has a warm lit ceiling with a lamp panel a bay (`OPEN_CEIL`, `OPEN_LAMP`). The dark inside of the tower is no longer seen |
| One double-height storey rather than two floors | A design choice | The lobby is always one storey: two floors tall with no floor line across it. On a tower of ten floors or more whose floors are low it is as many floors as reach 280 units, at most four (`OPEN_LOBBY_*`) |
| A fade, never a pop | A design choice, and the flash budget's | It fades in and out by stipple: a growing share of the lobby's pixels is through. Never faster than 0.3 s (`OPEN_FADE_S`), and inside the patch's area budget |
| Not on a damaged or breaking tower | A design choice: **say if a damaged tower should keep its lobby** | A tower that is damaged (any stage), has a floor cleared, or is coming down has no lobby. One damaged while its lobby is open starts to shut on that tick, with no hold. The patch takes it. A clean lit lobby under a burnt-out frame did not look like one building |
| Shuts when the fight leaves | A design choice | 0.75 s after nothing asks for it (`OPEN_HOLD_S`) |

## One building, one kind

Fixed for the match by the building's shape and its floors as built.

| The building | In front of the fight | Never |
|---|---|---|
| **A tower:** 5 floors or more, with straight walls (a shaft, a slab, a block, a stepped tower, a crown, a spire; `OPEN_SHAPES`). In today's world 30 of 118 buildings | Opens its lobby. Takes its share of the patch when the fight is over the lobby's ceiling, or when it is damaged | Is sunk to a stub |
| **A tall building that is not a tower:** 5 floors or more of another shape (a stack, a lighthouse, a hall, a chapel). 5 of 118 | The patch | Has a lobby. Is sunk to a stub |
| **A low building:** fewer than 5 floors | The patch, and it sinks as the patch grows large | Has a lobby |

- **A stack on a colonnade is not a building anyone has seen,** so the tapered and the gabled tall buildings take the patch. In the first build they opened floors like the towers.
- **No tall building sinks in a match with depth on.** At a close brawl a building of 5 floors stands out of the top of the frame, and sinking it would change the whole screen.
- `open_check` asserts on every tick that no tall building sinks and no building without a lobby opens one.

**With depth on the patch works through every row.** In a match with depth on, the one patch opens every building in front of the fight that has no lobby, in any row: each of its ends lies at its own fighter's depth, so it cuts what stands in front of their line and nothing behind it. With depth off the rows behind keep the hole and the stubs.

## When a lobby opens, and when the patch takes a tower

- **The action is the patch's own capsule:** both fighters, the gap between them, and what is travelling (where each will be in 0.3 s, a beam's stretch, a shot).
- **A tower answers for the capsule's line, not for the room round it.** It answers when the line comes within 75 units of being hidden by it (`OPEN_SIDE`). A pair standing clear in an avenue opens neither corner tower.
- **The lobby opens** when the sight line to a fighter's feet passes under its ceiling at the tower.
- **The patch takes the tower** when the sight line to 30 units over his head passes over the ceiling (`OPEN_HEAD`). At a close brawl a pair on the ground behind a tower with floors of 154 units is seen at 128 units, and the ceiling is at 281: the lobby alone shows them, with room for a fighter to rise two heights.
- **The share.** A tower's share of the patch scales the patch's radius on that tower, from nothing to all of it. So the window grows out from the fighter, by area.
- **The holds.** A lobby shuts 0.75 s after it was last asked for. A tower gives its share of the patch up 0.75 s after (`PATCH_HOLD_S`).
- **The building a launched fighter is aimed at stays whole,** as under his own hole: its cut floors show him inside.
- **Camera's request is honoured as the patch honours it:** `request` false asks for nothing and what is open shuts; `only` makes the action one fighter's.

## How it looks, and why it is not damage

| | A lobby (the camera's) | A cleared floor (a brunt's damage) |
|---|---|---|
| Where | The ground storey, always | Any floor |
| Through it | The street, the crowd and the fight behind the building | The building's dark back wall |
| What stands in it | A regular row of columns on every side, a deep beam on them | Nothing |
| Over it | A warm lit ceiling | The dark inside |
| Round it | The facade as it was: lit panes, no soot | Windows out, soot, cracks, a sheared corner at the next stage |
| VFX | None: no glass, no debris, no dust | Glass and debris when it happens |
| When the fight leaves | It shuts | It stays |

- **Only the tower's shell carries the colonnade.** A stepped tower is boxes one inside the other, and the bell tower has a stair bump on its front. The widest box that stands on the ground is the shell; every other part is simply gone under the lobby's top. The first build stood a post at every box's corners: three a side on the ledger hall.
- **The columns and the beam are one stone:** half the wall's own colour and half a neutral pale (`OPEN_FRAME_COL`), so they read as a frame on a pale tower and on a dark glass one. No fighter's hue. The far side's stand in shade.
- **The ceiling lies flat over the lobby.** A box has no ceiling to draw, so each pixel's ray from the eye is met with the ceiling's height, and the lamps sit in rows in perspective. The lamps are 0.08 of relative luminance over the ceiling, inside the contrast budget, so a shaking camera does not flip rows of them.
- **Inside the patch a column is a ghost, not a gap.** Round the fight a column or the beam loses 72% of its pixels (`OPEN_GHOST`). The fight shows through it, and the row still reads as standing. At 55% a fighter standing right behind a column was veiled (the first take of the clip). The first build removed a post there, which with sturdy columns would leave a tower's middle on nothing.
- **So near the lens that it is in it, a column thins to a ghost too.** Between 600 and 300 units from the lens (Camera's near-clip distances) a column and the beam lose up to the same 72% of their pixels. With Camera's dolly the lens stands in the street in front of the tower, and a solid column there is a fifth of the screen wide: swept past by a travelling camera it is a large change every time it crosses. With today's camera nothing is that near.
- **In the middle of the lobby stands the core** (the frame batch, 2026-10-12): the lift and stair shafts that hold a tower up. A box 0.24 of the shell's width and 0.4 of its depth, from the floor to the ceiling, in the columns' stone a step darker, with three lift doors a face and a lit sign over each. It gives the opening a spine. There is no geometry for it: the eye's ray through an opened pixel of the wall is met with the box. Inside the patch it is thinned more than a column (85% of its pixels, `OPEN_CORE_GHOST`), since it stands in the middle and is the widest thing there.
- **Seen from above the ceiling is not seen:** a raised camera looks down through the lobby at the street.

## How fast it changes

- **By area, with the patch.** All the lobbies of a pane, the towers' shares of the patch and the patch itself never turn more than 16,000 pixels a tick at 1024 by 768 (`PATCH_AREA_TICK`; the frame analyser's area threshold is 21,824). The lobbies and shares take what the patch left of that this frame, shared by what each asks for.
- **And never faster than 0.3 s.** At a close brawl a tower's lobby is about a fifth of the screen.
- **Shutting is half as fast** (`OPEN_CLOSE`), and only after the hold.
- **Measured, headless** (`open_check`, 1280 by 720, where the budget is 18,750): a pair put behind a tower at once has its lobby in 18 ticks, at most 10,928 pixels a tick. It shuts in 23 ticks at 9,375 a tick. A pair lifted over the ceiling has the patch on the tower at 10,936 pixels a tick at most.
- **Measured, the frame analyser** (Tools' `analyse-frames.js` on the clip's scene at 1024 by 768, 1,120 ticks, Camera's dolly on): 1.5 flashes in the worst second on the primary reading, 1.5 with the area threshold 15% lower, 1.5 with the two-second memory. A pass. With the near columns solid the same scene read 2.0: the worst second was the camera travelling back along the street past them. The first build's clip read 0.5, with the camera standing far back.

## What VFX and Camera read of it

**VFX's clear query** (`docs/vfx/depth.md` section 4; `PaneWorld.clear_query`, set as `host.vfx.clear_query` in a match with depth on). Nothing a building throws (window glass, cladding, stage dust) is drawn in front of the fight inside a see-through region; the fight's own effects always are. For a world point it answers the share left to be seen:

| Where the point is | Answer |
|---|---|
| At the fight's depth there, behind it, or within 30 units in front of it (`CLEAR_GAP`) | 1: the fight's own |
| Nearer the camera than that, over an open lobby's face on this pane's screen (from when half of it is through) | 0 |
| Nearer the camera than that, inside the patch, when a building the patch cuts stands in front of a fighter (a building without a lobby, or a tower with more than half its share) | 0 in the patch's solid part, rising to 1 across its soft edge |
| Anywhere else | 1 |

- **Per pane.** The hub keeps one callable. It answers for the pane whose effects are being drawn. Asked outside a draw (a thing about to be thrown), it gives the most any pane would show, so glass thrown where one pane has a lobby open is still made for the other.
- **A patch that cuts nothing hides nothing.** With depth on the patch is worked out every frame, also for a pair in the open; its capsule counts only when a building it cuts is actually in front of a fighter.

**Camera's near-clip rule** (`docs/camera/city-in-depth.md` section 1; `RenderLook.NEAR_CLIP`), in a match with depth on:

- A low building whose face is nearer the lens than 600 units stands as its stub, whatever the action's size. Nearer than 300 it is not drawn: it sinks on from its stub to under its footing, at the same pace.
- **A tall building is not sunk by it.** A tower opens its lobby or takes the patch. So near the lens the lobby fills the frame: its ceiling across the top, and its near columns thinned to ghosts between the same two distances.
- **The crowd follows the same two distances:** a figure nearer the lens than 600 units shrinks, and is nothing nearer than 300. With Camera's dolly the camera stands in a street, and that street's crowd would be a row of heads across the bottom of the frame.
- With today's camera it changes nothing: at the close brawl the nearest block is 1,355 units from the lens, and the foreground row is empty in the data. It is for the dolly, and for the foreground row when it is switched on in a match with depth on.

**Camera's cut flag** (its section 3). A pane's request carries `cut` when Camera's frame says so in `clear[i].cut` (`PaneWorld.request`; `main` hands it over since the frame batch). On that frame the patch, the stubs, the lobbies and the towers' shares are at their targets: nothing fades across a cut. That is so in every match, with depth off too: a hole and a stub no longer ease across a cut. The rest of `clear[i]` is not read yet (`fighters-in-depth.md` section 8).

**The blocks' patch has the patch's soft edge.** With depth on the patch through the rows behind was drawn with the fighter's hole's hard edge: an oversight of the first batch, fixed.

## Checks

- `render/tools/open_check.gd` (headless, 21 checks; the last three added are a lobby floor cleared by a brunt, what holds a cleared floor up, and Camera's cut flag reaching a pane's request): depth off, a real match opens nothing and every part of every building says it never will; depth on, a building's kind is its shape and its floors as built, and no tall building is among those the patch may sink; in front of a tower nothing opens; behind it the lobby fades in, one storey from the ground, inside the area budget and over no less than 0.3 s, the tower takes no share of the patch and does not sink; VFX's clear query behind it; back in front it holds, then fades out at half the budget, and is shut; Camera's request off shuts it; Camera's cut flag; a pair moved 12,000 units between two ticks under a camera already there; a pair lifted over the ceiling hands the tower to the patch, and back; a tower damaged while its lobby is open shuts it with no hold, takes the patch and never opens again; a stepped tower's shell carries the colonnade and its other parts are marked as inside it; behind a low building the patch is handed to the blocks' material; the clear query there; the near-clip rule; on every tick no tall building sinks and no building without a lobby opens one.
- The gates and the flash clip are in the report that came with this batch.

## Limits

- **Orb has the reworked look to review** (the clip and the stills). It is built to Orb's word on supports as I read it.
- **A damaged tower's lobby is built and switched off** (`RenderLook.OPEN_DAMAGED`, false as committed in 60f82149: a damaged tower takes the patch). With it on a damaged tower opens its lobby and shows its stage in it: from "windows out" the lamps are out and the lift signs dark; from "a part gone" the stone is sooted and one front column is cracked; a shell has the bare frame's tone, no ceiling, and that column broken off above a stump, so it stands and reads as about to go. A tower with a lobby floor cleared by a brunt, or coming down, has no lobby either way. Orb has the question; the stills are `lobby-option-damaged-stage*.png`.
- **A brunt's cleared floor has its supports** since the frame batch: `building-stages.md`, "What holds a cleared floor up".
- **Ghosted columns are a call.** Round the fight a column is a stipple. Removing it reads as a tower on nothing; leaving it whole hides a fighter behind a column 56 units wide, and with Camera's dolly a column is wider than a fighter on screen. The share is one number.
- **Seen on** the bell tower, the stepped ledger hall and a glass shaft, from fight framing, from a raised camera and with Camera's dolly on; a pair over the ceiling; a tower at its third damage stage (the patch). Not seen: a crown tower's lobby, a tower with a brunt's tunnel in it (it has no lobby: the patch), a tall building in the foreground row, a split screen's two panes.
- **A tower the lens passes through** (measured 2026-10-12, `img/lanes/dolly-lens-through-tower.png`). With Camera's dolly on, a drift from the middle street to the back street takes the lens through the front block's tower. Its lobby is open round the lens, its near columns and its core thinned, and nothing is drawn inside out. The frame analyser reads 1.5 flashes in the worst second of the scene (760 ticks at 1024 by 768), and that second is the scratch scene's own start; the drift itself counts four changes over 68 ticks.
- **A rush with the dolly on passes with nothing to spare** (measured 2026-10-12). A pair rushing 1,800 units along the middle street at 1,800 units a second behind the front block's towers, Camera's dolly on (560 ticks at 1024 by 768): 2.5 flashes in the worst second, 2.5 with the area threshold 15% lower, 3 with the two-second memory. The worst second is the rush. Part of the way the pair is out of the frame and the screen is the face of a tower 340 units from the lens, with nothing behind it to open for (`img/lanes/dolly-rush-wall.png`). The camera's travel is Camera's; a tower so near the lens could open its lobby whether or not the fight is behind it, as a low building there is its stub. Not built: the near-clip distances are Camera's to move.
- **Nothing was seen with the game's own movement:** the scratch scene slides the pair along a path. A launch into the rows with depth on has not been seen.
- **Cost** (measured 2026-10-12). Tools' bench, the standard match of 1,200 frames, one run each on a machine at about 40% load, before the frame batch and after: unthrottled 6.8 and 6.4 ms a frame (95th percentile 7.6 and 7.0); CPU slowed four times 22.2 and 23.4 ms (30.4 and 32.3); software-rendered 226 and 227 ms (397 and 414). The same within the bench's own spread: the window texture's extra rows and the frame's tests cost nothing a standard match shows. **An open lobby's own cost is not measured:** the standard match has depth off and opens none, and a software-rendered run of a posed lobby closed the browser under Tools' wrapper. A tower with its lobby open draws its back faces and meets a ray with a box a pixel of the opening.
- **The ground behind a tower is drawn as it is on the plane.** With depth on the sim has its own rows of ground in depth, and the renderer does not read them yet (`fighters-in-depth.md`). A crater made in the middle street shows in the front street.
