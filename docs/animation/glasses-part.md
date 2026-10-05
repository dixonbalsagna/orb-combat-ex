# The rival's glasses: the part, planned with Rendering (2026-10-05)

Owner: Animation (the attachment and the motion), with Rendering (the part and its draw) and Art (the geometry: `art/concepts/refine/approved-rival-turnaround.svg`, frame C, the bare wedge). Orb (questionnaire 17): the glasses are **always on**. Nothing here is built; this is what each side needs from the other.

## Decision (from the press-styles plan, section 7)

`att_head_brow` with an offset, no 15th socket. Art's callout: the part is a child of the head bone, its origin the nose bridge on the front surface of the face, which is the brow socket moved **1.0 down and 0.5 forward** in Art's head units (the head is about 16.6 high and 11 wide in them, the body 100).

## What Animation provides

| What | How |
| :--- | :--- |
| The brow socket `att_head_brow` | a point on the `head` bone: on the front surface of the face at the brow line. The rig's greybox head (`anim_rig.gd`: the head bone's origin at the base of the head, 12 units up, 12 wide) puts it at about 5.2 forward and 8.0 up in bone-local units; a final-art head has its own number, set per build profile as the cosmetics plan says (`docs/art/cosmetics-plan.md`: the 14 `att_*` points are fixed offsets on a bone). I will add it as an `attach` block in `data/anim/sockets.json` (it needs a Tools schema line, the same patch as the other `sockets.json` keys) when Rendering starts the part |
| The glasses offset | in the glasses part's own data, in head fractions so it holds on any head: 0.03 of the head's height down, 0.03 of its depth forward (Art's 1.0 and 0.5 over 16.6 and 11 head units) |
| A second point, `att_glasses_hinge` | the temple hinge, the outer corner of the lens (Art's point 3), for a nudge gesture: a hand can reach it. No nudge exists; if Orb or Narrative asks for one I add a taunt pose that targets it |
| Reading it | `AnimFighter.attach_point(name) -> Vector3` (model space, the head chain only, no full FK), the same way `socket()` reads a bone, so VFX's lens glare and Rendering's part read one number |

## What Animation needs from Rendering and Art

1. **The part rigid on the head bone,** through the same skinned mesh as the body (one more rigid-skinned part, `rigid` to `head`, no weights), so it adds no draw call; if it must be its own mesh, one `MeshInstance3D` per fighter on a `BoneAttachment3D` at `att_head_brow`. Rendering's call; the budget is Art's: the frame and arms at most 40 triangles, the lenses 2 quads, one material slot with one scalar `glare` from 0 to 1.
2. **The lens is always in front of the eye:** 0.5 in front of the face, 6.2 wide and 3.0 high a lens, so the head's pitch range in the wave poses (negative 14 to positive 20 degrees; the press-style heavy adds a forward lean of 0.07 rad on the spine and nothing on the head) never shows the eye over or under the rim. Rendering checks this on the rival's build profile with the pose sheet (`pose_sheet.gd`) at the three extremes: the uppercut's chin-up pose, the hammer's chin-down, the spinning blows' head yaw.
3. **The arms do not clip the hair or the tail's crown:** Art's point 4 (the ear end of the arm at head-local (-3.6, 9.2)) ends over the ear. The hair mesh is Art's; the check is a side view at the head yaw extremes (30 degrees).
4. **No secondary motion:** the glasses are rigid with the head. They do not slip, bounce or fall off in a knock-back, a ragdoll or a KO (Orb: always on); the spring chain the tail uses is not used for them.
5. **The look gestures stay clear:** the rival's own taunts (`rw.taunt_head_tilt`, `rw.taunt_stillness`, `rw.taunt_dust_plate`, `rw.drop_the_act`) never take them off. `drop_the_act` is a change of stance and face, not of the glasses; Narrative may want the glare to flare on it, and `glare` is the scalar for that (VFX's `render/vfx/glare.gd` already sizes its flash to the lens).
6. **The mirror:** the rival's body flips with the visual facing (`vface`); the glasses are symmetric across the centre line, so the part needs no mirror, only its hinge arms on both sides.
7. **The cost line:** Rendering reports the glasses' draw call and triangle cost against the rival's budget in the same place the body is counted (`rendering/README.md`).

## Questions only Art or Orb can answer

- Whether the lens tint (`glare` 0, a dark violet at alpha 0.46) is read against the dark coat in the web build's low quality, or the part needs an outline: Rendering's outline pass already runs on the body; does it run on the part.
- Whether the Protagonist ever wears a pair: nothing in Orb's answers says so; this plan is the rival's only.

## What I will do when Rendering says go

Add the `attach` block to `sockets.json` (with Tools' schema line), add `attach_point` to `AnimFighter`, and check the head poses of every rival wave against the lens with the sheet. About an hour of my side; the part is Rendering's and Art's.
