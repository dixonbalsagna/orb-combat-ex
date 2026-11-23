# A building's inside reads as rooms on the tile ground, not black blocks

Parked by Rendering, 2026-11-02, the EP's brief after Camera's beam-clash GIFs. `inside_rooms.diff` stacks on `2026-11-02e-ratchet-list/ratchet.diff` and does not touch what `2026-11-02f-draw-others` does (it applies on Tools' stack with f in it too). Only with the tile ground's switch on (`globe_r > 0`); today's ground keeps its look.

**The fault.** Buildings a beam carves show black, blocky insides. Everything a building shows of its inside (the faces seen through a beam's cut, a blown-out window, a broken core) was drawn in one colour, `inside`, a near-black (#12131a). On a glass tower whose windows are out, each cell was a black square.

**The change**, `building.gdshader`, `look.gd`, `planet_view.gd`:
- On the tile ground the inside is a dark charcoal (`BUILDING_INSIDE_TILE` #24252c, `inside_c()`), in every place the near-black was.
- What a cut or a blown-out window shows is a stack of rooms (`room_at`): at each floor its slab at the foot (the charcoal, 14 percent of the floor), the room's wall lit (`ROOM_LIT` #6b6157), and the shadow under its ceiling (`ROOM_SHADE` #4a4540, 20 percent), in hard steps by the building's own floor height. A face with no floors keeps the charcoal.

**Seen:** `docs/rendering/img/lookgate/inside-rooms/`, the city signature scene on a copy of Tools' kept tree (2b9dfe14), ticks 91 and 231 with the GIF, left the stack as parked (to 11-02c's charcoal walls), right with this, and the burnt tower at 231 enlarged twice. The blown-out cells show lit rooms with their ceiling's shadow behind the frames; the falling chunk at 91 shows rooms, not a black block. The fighter in front of the tower still reads against it. A charcoal inside alone (tried first) left dark squares.

**Gates**, with 10-31a to 11-02e stacked on 8ea982c5's render, sim and data: golden byte-identical; tile, lake water, cover water and sweep checks pass; the 20 render gates exit 0; off 13 stills 0 differ. The chain (10-31a to 11-02e and this) applies on main 02e56136, and this applies on Tools' stack with draw-others in it, apply check only.
