# The Look Profile: player customization, starting with energy

- **Who:** Orb's stand-in, lead on customization by Orb's word of 2026-11-28 (`docs/ep/vision.md:1949`).
- **For:** the EP, to turn into an ADR and the directors' briefs.
- **Standing:** a design and architecture spec, second draft. Nothing is built. Every number is a first value. Items marked *to verify* are engine facts nobody has tried.
- **Base:** the energy toy Orb played and liked (`prototype/energy-toy/`, `docs/ep/vision.md:1945`), read against what the game does today. The first draft was then attacked by a review panel against the code; this draft carries what survived (see the end). The decisions are mine.

## The short version

1. **A look profile is a small file of ids and numbers.** Its first part is the energy style: the toy's recipe, tightened. Later parts (body, colours, face, hair, outfit, accessories, voice, poses) sit beside it, each with its own version, and an older game keeps what it does not understand.
2. **The look never reaches the simulation's state or any hash.** That takes care, because today a fighter's aura colour *is* simulation state and is hashed (`sim/core/hash.gd:6`, `:15`). Those fields stay exactly as they are; the look is laid over them on the drawing side only. One small simulation edit is wanted (an owner tag on five effect events, kept outside the hash); nothing here moves the golden record.
3. **The game owns the outline and each fighter's kit; the player owns the style.** How wide a beam is drawn, its shape and its way of struggling, how big an aura grows with power, the front of a beam, the flash of a hit: the game draws those. The player's layers dress them in texture, colour and movement.
4. **One shader program for every look,** so a new look never causes a stutter and is warmed once at start-up.
5. **The first version drops three things the toy has:** the whole-screen pass, the lingering trail buffer, and the two materials that bend or invert the picture behind them. Energy is drawn on small rectangles round each fighter, beam and blast. The trail is the biggest risk to the look Orb liked.
6. **Build one aura first.** Brief L3, one fighter and four looks, toy beside game, is the decision point. Nothing else large is spent until Orb has seen it.
7. **This is a new feature in the alpha plan and has no milestone row yet.** Section 9 sizes it at about 14M tokens and proposes where it goes. That is Orb's and the EP's to accept.
8. **Three questions for Orb** are at the end.

## 1. The rules

Numbered so briefs can cite them.

- **LP1. Drawing only.** A profile is never read by `sim/`, never written into a fighter's, beam's or effect's simulation fields, never put in the match setup, and never part of a state hash, the data hash, the golden record or the network match key.
- **LP2. The outline is the game's.** A profile cannot change how wide a beam is drawn, its length, where it leaves the body, a blast's size, or any timing. Drawn widths stay what each fighter's data sets them to (drawn between 0.4 and 1.6 of the reference, round a width that hits banded 0.7 to 1.3: ruling 20.1, `docs/design/energy-overhaul.md:449`).
- **LP3. Reserved signals.** The game draws these itself, through or over any style, and no profile can remove, restyle or re-time them:
  - power tier and form, and the form-ready flare;
  - how much energy a fighter has: the aura's size is the game's scale on the look's reach, and its steadiness is a flicker the game lays over any style when energy is low (today's `VfxReact.flicker` and `jitter`, `render/vfx/transform_view.gd:83-85`). A style can move things about; it cannot change their brightness by shaking them, so it cannot fake that flicker;
  - the charge steps at the hand, with their order, timing and rise (E42);
  - who owns a shot or a mine;
  - the front of a beam;
  - in a struggle: the clash point, its pulses, the flare on the fighter losing, and the losing beam bulging and never thinning (E96);
  - the six combat tells that are to replace the marks drawn on fighters (heavy coming, landed, counter or catch, launch open, perfect window, charge full: `docs/vfx/marks-on-fighters.md`), which are drawn in the fighter's own colour, never the look's;
  - the flash of a hit and the game's other information flashes.
- **LP4. One clock.** Every look moves on the simulation's clock, frozen when the simulation is, as beams do today (`render/vfx/shaders/beam_core.gdshaderinc:11`). A still, a replay and a side-by-side reproduce.
- **LP5. The limits are the game's.** Brightness, bright area, repetition, reach and cost limits live in a data file a profile cannot carry or override, and are applied after the profile.
- **LP6. A profile is data.** Ids and numbers. No code, no images, no typed text.
- **LP7. Forward-safe.** At run time, unknown parts and fields are kept by value and ignored, an unknown id draws its kind's default, and a profile from a newer game is used as far as it is understood and never written back in an older shape.
- **LP8. No compile per look.** One energy shader program, with the look in its inputs.
- **LP9. Corrected for viewing, never edited.** When a look would be hard to see, the game adjusts how it is shown on that screen. A saved look is always worn as saved. Locks decide what can be edited, never what is drawn, and nothing ever rewrites a stored look to fit a tier.
- **LP10. No interface marks.** No look adds a bar, badge, label, aim line or marker on, over or between the fighters (E6; `docs/ep/taste.md:11`). An aura sits behind its fighter.
- **LP11. The kit is the fighter's.** Each fighter's beam class (straight, wide, lance, twin), its width, its struggle look and where it fires from stay that fighter's (E80, E96, the kit sheet). "Each fighter's beam is unmistakable" (`docs/ep/taste.md:14`) is kept by the kit, whatever look is worn over it.

## 2. The data model

### The profile

```json
{
  "schema": "look.profile/1",
  "id": "lp_3f9a12c7",
  "label": ["swift", "comet"],
  "fighter": "*",
  "parts": {
    "energy": {
      "v": 1,
      "trail": 0.25,
      "layers": [
        {
          "shape": "sparks", "behaviour": "jump", "material": "glow", "palette": "azure",
          "seed": 3,
          "sliders": { "power": 0.95, "size": 0.8, "speed": 1.1, "density": 1, "reach": 1,
                       "erratic": 0.2, "vibrate": 0, "detail": 0.6, "form": 0.1, "spin": 0,
                       "hue": 0, "spread": 0.6, "cycle": 0, "twist": 0, "warp": 0 }
        }
      ]
    }
  }
}
```

| Field | Needed? | Rule |
| :--- | :--- | :--- |
| `schema` | Yes | The envelope's version, in the repo's own form (`fighter/1`). It changes only when the envelope changes |
| `id` | Yes | `lp_` and eight hex digits. A player's look gets one when first saved. A preset or a fighter's default has a fixed one written in its file, unique, so a reward can grant it and a setting can name it. Never sent to another player |
| `label` | No | Two word ids from the game's own lists (section 8). Not typed text. The lists only ever grow |
| `fighter` | No, default `"*"` | Any fighter, or one roster id |
| `parts` | Yes | One key per part, each with its own `v`. A reader takes the parts it knows, keeps the rest by value, and fills a missing part from the fighter's default |
| `parts.energy.layers` | Yes | 1 to 5 |
| `parts.energy.trail` | No, default 0 | 0 to 1. In version 1 it means how long streaks linger (section 6), not a frame buffer |
| A layer's `shape`, `behaviour`, `material`, `palette`, `seed` | Yes | Ids and a whole number |
| A layer's `sliders`, `colourMix` | No | Missing sliders take the catalogue default |

**Later parts** take these keys, reserved now: `body`, `colours`, `face`, `hair`, `outfit`, `accessories`, `voice`, `poses`. Art's cosmetics plan already names seven colour slots, two spare ones and fourteen attachment points on the rig (`docs/art/cosmetics-plan.md:53-58`); those become `colours` and `accessories`.

**Forms.** A transformation does not get its own profile. The game lays a step for each power tier over the player's style (more reach, more power, a step along the colour), from its own file (`data/look/energy-forms.json`, keyed by tier 1 to 4 as today's aura table is), so a look made for any fighter works on every fighter and the tiers still read as steps (LP3). A key `forms` inside the energy part is reserved for per-tier overrides later; version 1 ignores it. Anything richer per form waits on the open decision about a body change per form (decision 17).

### The energy part, version 1

The toy's recipe, with what the audit found fixed. **The toy changes with it in the same brief,** so the two never disagree.

| Rule | Was, in the toy | Now |
| :--- | :--- | :--- |
| Layers | 1 to 5; more were cut off on loading | 1 to 5 in the repo's own files. At run time a sixth or later layer is kept in the stored file and never drawn |
| Ids | Replaced silently when unknown, by whatever came first in the list | Strings matching `^[a-z][a-z0-9_]{1,31}$`, one namespace per kind. Resolved in this order: a live id; a retired id's named stand-in; the kind's `default`. The Style screen says when that happened |
| Shader numbers | In the catalogue | Still only there. Unique per kind and never reused |
| Seed | Any number; 0 became random on every load; the shader used it modulo 97 | A whole number from 1 to 65,535, used whole. Loading never changes it. A fraction is floored, a negative made positive, anything larger wrapped into range |
| Sliders | Any precision | Fifteen named sliders, kept to three decimal places and clamped to the catalogue's full range on load. An unknown slider is kept and ignored |
| Blended colour | Held in a field that was never saved, so a saved blend came back different | An optional `"colourMix": {"to": "<palette id>", "k": 0.42}`. `to` must be a known palette other than the layer's own; an unknown one is ignored |
| Hidden couplings | "Cling" forced vibrate up and "Erratic" forced erratic up, in code | Written in the catalogue entry (`minVibrate`, `minErratic`) |
| Name | Typed text, 60 characters | Gone. See `label` |

**The toy's saved files still load.** A file whose `format` is `orb-energy-recipe` becomes an energy part: missing `twist` and `warp` are 0, the name is dropped. Orb's first find (`prototype/energy-toy/recipes/orb-first-find-2026-11-27.json`) is the first test case. The honest promise is this: **the same look, not the same pixels.** Using the seed whole changes the exact pattern of every spark. The test is the changed toy and the game side by side on that file, judged by Orb as the same look.

### Two kinds of strictness

- **Files in the repo** (presets, fighters' defaults, the catalogue) are validated closed, like every other data family: an unknown key is an error, so a typo is caught. `parts` allows `energy` and the eight reserved keys only.
- **Files from outside** (a player's store, a replay, another player's look) are read by the tolerant loader of LP7.
- Both are tested on the same set of awkward profiles: an unknown id, an unknown part, a higher version, six layers, a bad `colourMix`.

### Versions and migration

- A part's `v` rises only when the meaning of an existing field changes. Adding an optional field, a slider or a catalogue entry does not raise it.
- Each rise comes with one function from the old shape to the new, run in order on loading.
- The store keeps one backup of itself the first time a newer game rewrites it.
- **A newer profile in the store is held untouched.** The store is one file of several looks, so saving any look rewrites the file. A look whose version the game does not know is kept as parsed and written back as it was, and that slot refuses edits.

### Ids that last

- An id, once shipped, means the same thing forever and is never reused. That holds for catalogue entries, presets, reward ids and label words alike.
- A removed entry or reward moves to a `retired` list naming what stands in for it, which must be live and grant at least as much.
- The words a player reads live apart, in `ui/data/look_names.json`, keyed by kind and id, as fighters' names do. A name can change after Legal's screen without touching one saved look.

## 3. Keeping it out of the simulation

### What is true today

| Fact | Where |
| :--- | :--- |
| A fighter's `col`, `aura` and `hair` and a beam's `col` are simulation fields and are hashed | `sim/core/hash.gd:6`, `:15` |
| Effect events carry the fighter's aura colour, and are hashed into the golden's digest and the network's | `sim/core/fx.gd:59`, `:91`; `sim/core/hash.gd:417-420` |
| The network match key is the seed, the computer settings, **the whole setup** and the data hash | `net/handshake.gd:112-114` |
| A name put in the setup reaches the hash through `fighter.name` | `sim/core/sim.gd:227-229` |
| A replay's player reads a fixed list of top-level fields and ignores any other | `sim/core/replay.gd:153-233` |
| A check pins the exact list of keys a replay's header has | `sim/core/tools/parity.gd:3561-3564` |
| The data hash folds a named list of files, not a folder | `sim/core/replay.gd:240-311` |
| Every energy colour on the drawing side passes through one function, **keyed by a colour, not by a player**: 18 call sites in 9 files | `render/vfx/aura.gd:116-119` |
| Several effects find their fighter by matching a colour | `render/vfx/ghost_tally.gd:77-90`; `render/vfx/shots_view.gd:254` |

### The rules that follow

1. **The hashed colour fields are frozen.** No look code writes `col`, `aura`, `hair`, a beam's `col` or an effect's `col`. They become the fallback colour and nothing more.
2. **Nothing about a look goes in the setup.** Not a profile, not its id, not a name. The menu remembers each player's chosen look in its own setting, which must not be merged into the setup the host builds (`render/core/sim_host.gd:90-106`).
3. **The drawing side looks a look up by player slot.** A new call, `look_color(slot, fallback)`, sits beside `lane_color`, and each of the 18 call sites that knows its owner moves to it. `lane_color` stays as the fallback path only.
4. **Effects that carry only a colour need an owner.** Afterimages, charge glows, and the rings, sparks and banners the simulation raises in a fighter's aura colour have no owner on them. They gain one, as a field for drawing only, kept outside the hashed field list, the way the launch event already carries one (`sim/core/fx.gd:714`). This is the one edit under `sim/`. It needs Simulation's hand, and the effects' hash must be shown unchanged. Until it lands, those five effects stay in the fighter's own colour.
5. **A look's colours skip the old colour swap.** `lane_color` replaces any fire-coloured or near-white colour with a purple (`render/vfx/aura.gd:111-124`). That swap stays on the fallback path only, or a player's gold would come out purple.
6. **No look code writes the effects view** the simulation side owns (`sim/core/view/fx.gd`) or the host's copy of it. A look is applied when something is drawn, never stored back.
7. **`data/look/` is not a match input.** No line may be added to the data hash's list for it.

### How a look travels

**The travelling form** is one shape for both a replay and the network, built by one function: the energy part only, with no `id` and no `label`. Ids stay as short strings, so two games with different catalogues still understand each other. Each layer's fifteen sliders are packed as two bytes each in a fixed order that only ever grows. That is about 120 bytes a layer.

| Where | How |
| :--- | :--- |
| **A replay** | An optional top-level field, `looks`, beside `setup` and never inside it: for each slot, the look and the tick it took effect. **It is added by the code that writes the file, after the simulation's header is built,** and only when some slot has a look, so a match with no looks writes a file identical to today's and the pinned key list holds. `sim/` never takes or reads a profile. Three writers change: `render/core/match_recorder.gd`, the LAN save in `net/lan.gd`, and Tools' `tools/preview/blackbox.mjs`. A report that carries a replay therefore carries the other player's look in the travelling form, and nothing more |
| **Playing a replay back** | The black box's playback hands `looks` to the resolver. The headless replay check ignores it |
| **A LAN match** | A handshake message, `look`, routed by `net/host.gd`, sent from the first frame alongside the pings and repeated until answered, as the hello is. It carries a version, the slot, a part number and count, and the look. It never touches the match key, an older game ignores it, and the protocol number need not rise. **The match never waits for it:** a late look takes effect when it arrives, at once and with no fade |
| **A watcher** | Out of scope until a networked relay exists |

- **LAN is not in the testers' package** (`net/lan.gd:3-4`, RL-204), so the LAN message is not alpha work (section 9).
- **Size.** One packet: the heaviest five-layer look, each layer with a blended colour, must fit under 1,000 bytes in the travelling form. Netcode measures it; the plain dictionary form does not fit (about 540 bytes a layer). The message carries part numbers from the start so a later, larger profile can travel in pieces.
- **On receipt.** Data only (`net/transport.gd:19-20`). At most five layers; every id a short string; every slider clamped; anything unknown dropped. Then the game's own limits apply again when it is drawn.
- **What is not checked.** Whether the other player has really unlocked what they are wearing. There is no server and nothing depends on it.
- **A setting,** "Show other players' looks", on by default. Off, everyone else is drawn in their fighter's default look.

### The proof

A check in CI that **runs through the drawing host with the look system on and the resolver live**, because a run of the simulation alone is equal by construction and proves nothing. One fight of two different fighters and one of the same fighter twice, each run with no looks and again with the heaviest look on every slot. Equal between the two runs: the state hash at every checkpoint; the effects view's hash; the data hash and the network key worked out from the setup the host actually used; that setup itself; the network digest every tick. Then: a replay recorded with looks is accepted and plays, straight and after a round trip through text; the pinned header check still passes. And a control: a name changed in the setup moves the state hash, so the check is known to be able to fail.

## 4. The catalogue and unlocks

### Files

| File | What | Schema |
| :--- | :--- | :--- |
| `data/look/energy-catalogue.json` | The tiers, the layer limit, and every shape, behaviour, material and palette (`id`, `code`, `tier`, `since`, `fallback`, `fighters`; `cost` for all but palettes; a palette's colour numbers; `minVibrate`, `minErratic`), each kind's `default`, each slider with its default, step and range per tier, and the whole-look sliders | `look-energy-catalogue.schema.json` |
| `data/look/energy-limits.json` | The game's limits (section 5) | `look-energy-limits.schema.json` |
| `data/look/energy-quality.json` | What each quality level draws (section 6) | `look-energy-quality.schema.json` |
| `data/look/energy-forms.json` | The step each power tier lays over a look | `look-energy-forms.schema.json` |
| `data/look/rewards.json` | What can be earned and what each reward grants | `look-rewards.schema.json` |
| `data/look/presets/*.json` | Ready-made looks | `look-profile.schema.json` |
| `data/look/fighters/<ID>.json` | Each fighter's default look | `look-profile.schema.json` |
| `ui/data/look_names.json` | The words for every entry, preset and label word | `ui-look-names.schema.json` |
| `ui/data/look_tabs.json` | The Style screen's tabs | `ui-look-tabs.schema.json` |

- Each gets a rule in `tools/schemas/map.json`, a policy line, at least three failing cases in `tools/fixtures/cases.json`, and a default look in each fixture fighter.
- Cross-file rules go in the validator's cross-reference step, since a schema cannot express them: ids unique per kind; `code` unique per kind; every `default`, `fallback` and retired stand-in names a live entry of the same kind, with no chains; preset and default ids unique; a default look's `fighter` is a real roster id.
- **Two meanings kept apart.** A kind's `default` is drawn for an id nobody knows. An entry's `fallback` is drawn when the quality level cannot afford that entry.
- **Fighters' defaults are not in `data/fighters/`.** That folder is simulation data and another director's.
- **Names.** "Style" and "look" are already used elsewhere: `data/fight/style.json` is simulation data, the option `energy_style` is hold-or-toggle for the energy button, and the animation system has a layer called `look`. Nothing here reuses those names for a file or a setting.

**The toy stays the workshop.** Its catalogue block is generated from three sources (the catalogue, the names, the presets), and the check is that generating it again changes nothing. The toy's own code changes once, to read the new fields.

### Tiers and rewards

- Four tiers, as in the toy. Which entry sits where is Game Design's to rule; the toy's are a first guess.
- **A reward grants things, not only a tier.** One entry, a wider range on one slider, a palette, a ready-made look, another layer to build with, or a whole tier. That gives "generous, many kinds, always something new" (`docs/ep/taste.md`) more room than four steps.
- **Layers can be earned.** A new player builds with two; rewards open the rest. Orb's first find was two layers. This limits what the Style screen lets a player add and what Random and Mutate make. It never limits what is drawn: a preset or a saved look with more layers is worn as it is.
- **The hook for the campaign,** which does not exist: `rewards.json` lists each reward with an id, what it grants and a `source` such as `campaign:<event>`. One function, `grant(reward id)`, safe to call twice, is all a campaign needs.
- **What the player owns** is its own file, `user://look_collection.json`: `{"schema": "look.collection/1", "rewards": [...], "progress": {"matches": 0}}`. The count rises at the end of a match, outside the simulation. What is unlocked is worked out from the rewards held and the reward table.
- The existing "Unlock all cosmetics" option (`ui/data/options.json:90`) widens what can be edited and never writes the collection, as its own words promise.
- **Never sold, never random for money** (`docs/legal/rewards-and-lock-screen.md`, section 2).

### Fighters

- **Each fighter's default look is a profile.** The computer and story fighters wear theirs. Weak enemies wear one fixed cheap look each. Twelve fighters is twelve files and no new code.
- **The hero and the rival** are meant to be "similar but inverted in theme, not just colour" (`docs/ep/taste.md:15`). The catalogue can say that directly: the same shapes with opposite behaviours. Art authors them.
- **No limit on what a player may wear** in the first version, because LP11 already keeps each fighter's beam their own. An entry may name the fighters it belongs to (`fighters`), so each can keep signature pieces that others earn late. Whether any are held back is Game Design's and Orb's (question 2).

## 5. Legibility and limits

### What exists

- **The only limit enforced while the game runs** is the shared limiter for bright bursts (`render/vfx/flash_registry.gd`). It sees bursts that ask it. It does not see steady brightness, the size of a glow, or a pattern that pulses. Its numbers stay in that file and are not copied here.
- **Pulse limits are scattered constants** in single effects.
- **Contrast is checked offline only,** by Art's generators, for four authored colour lanes against 15 biomes and 5 skies (`data/art/energy-lanes.json:5-8`). Nothing checks a colour a player picks, and some biomes already fail their own rule.
- **"Reduce flashing" is on by default** (`ui/data/options.json:45`). Under it the small-burst class is never granted, so a look's small bursts always draw their calm form. **The default look is the reduced one, and it is judged first** in every brief below.

### Limits no profile can exceed

All in `data/look/energy-limits.json`, applied after the profile.

| Limit | First value | From |
| :--- | :--- | :--- |
| One emitter's light is compressed, then capped | `L / (1 + L)`, 0.94 | The toy. Per emitter: see the note on overlap |
| A core's lightness | at most L* 86 | Today's beam rule (`render/vfx/beam_look.gd:7`) |
| Red, on every colour after hue, drift, blending and the tier step | red share under 0.78, and never a colour the shared limiter calls red | `data/art/energy-lanes.json:6`; `render/vfx/flash_registry.gd:150` |
| Travelling bands past one spot | 2 a second | Today's beam cap. The toy allowed 2.5 |
| Lightning re-drawn | 2 a second, always cross-faded | The toy, rounded down |
| A whole look's brightness swelling and settling | within 10% | Today's pulse rule |
| "Stop and go" steps | 1.5 a second, eased | The toy |
| Vibrate | at most 12 a second, by position only, never brightness | New. The toy shakes at about 50 a second |
| Colour drift | 0.05 turns a second | The toy |
| Reach beyond the outline | 1 body height for an aura; a beam's and blast's decoration within 1.5 times the game-drawn part | New |
| Decoration | at most 40% as bright as the game-drawn core, and the only part that may be soft | New |
| Darkening | at most 0.93, never over a fighter's body | The toy |
| Cost of one look | 120 units (section 6) | New |
| With "Reduced motion" on | vibrate 0; lightning, "stop and go" and colour drift held still; linger off | New. Today's setting removes flicker and shimmer (`ui/data/options.json:46`) |

**Overlap.** The toy compresses and caps the light of the whole picture at once. On rectangles, each emitter is capped alone, and two that overlap (a beam leaving a hand inside an aura, two beams at a clash, two auras in a brawl) add up past the cap. So each emitter also gets a share of brightness, and the door test below includes those three overlaps. Whether that is enough is *to verify* in L3.

**The white core.** Today's rule says a beam's core is never white; the toy's best looks have a white-hot centre. I have kept today's rule. It is one of Art's look rules under Orb, not a gate; the EP should note Legal has an interest in it for another reason (`docs/legal/energy-overhaul-screen.md:116`).

**How they are enforced:**
1. **In the shader,** as fixed arithmetic the profile's numbers pass through.
2. **At the door.** Every catalogue entry is admitted by a test: drawn alone at its extreme sliders, in the three overlaps, and in a set of random looks per tier, in both the reduced and the full look, and read by Tools' picture analyser. An entry that fails is tuned or left out.
3. **Through the shared limiter,** for the bursts a look makes. The game decides which kind of burst each is; a refused burst draws its calm form.

### Never hiding the fight

- **A fighter:** the aura is behind the body, by depth, as today (`render/vfx/transform_view.gd:14`), so dark materials stop at the body's edge by themselves.
- **A hit:** the game's hit flashes never take a look's colours.
- **Beams, shots and blasts:** the game draws a core and an edge band on each, crisp, and the look's softness is decoration only (the limit above). That keeps "soft, blurry blocks where a crisp beam should be" out (`docs/ep/taste.md:26`).
- **Against each biome and sky:** the promise is made by that game-drawn core and edge, not by the palette. The pass mark is Art's existing one: at least 20 on the colour-difference scale, 14 under each colour-vision setting, against the ground, rock, plant, water and sky tones behind it. Tools generates a table from the biome and sky data saying, for each, whether a dark edge (`#0a0d14`, Art's keyline) or a pale one (Art names it) reads better, and the game picks from it as the fight moves. Where a palette's core cannot pass, it is lightened on that screen (LP9). So any palette may be chosen, including the golds and blacks Orb asked for that fail as single colours.
- **Two players whose energy looks alike:** if two resolved looks are closer than 25 on that scale (20 under each colour-vision setting), the second is shifted on the viewer's screen. This is for energy only. **Picking the same fighter twice stays off** until Art's second body colour exists (`docs/ui/menus-a1.md:17`, decision 17). Art's cosmetics plan has a different rule for a clash, drawing the other player in their default (`docs/art/cosmetics-plan.md:31`); the EP or Art should pick one.
- **More than two fighters:** the resolver holds a look per slot for as many slots as the match has, not two.
- **Colour-vision settings:** today's setting swaps the two fighters' aura colours from a table keyed by colour. With looks on, that mapping moves into the resolver, per slot, and keeps the existing distances from the wound and guard marks and the sky.

### Older look rules this meets

| Rule | Standing |
| :--- | :--- |
| No dissolves, fades, slow wipes or full-screen blur (ADR 0010) | Held. The first version has no whole-screen effect |
| Nothing on, over or between the fighters (E6) | Held (LP10) |
| An aura shows only while charging or attacking, never at rest (Orb's rule, `render/vfx/aura.gd:3`) | Held. The Style screen previews it powered up. Game Design should note that the aura is also meant to show energy (`docs/design/energy-stamina-body.md:22`), which it cannot do at rest |
| Each fighter's beam is unmistakable (`docs/ep/taste.md:14`) | Held by LP11 |
| No soft, blurry beam (`docs/ep/taste.md:26`) | Held: the game's core and edge stay crisp |
| "A cosmetic adds no standing glow, aura or flash-like trail" (`docs/art/cosmetics-plan.md:28`) | **Superseded for energy** by Orb's ask. That page needs the line changed |
| No flame, lightning, gold or white aura (`docs/legal/rule-of-cool-screen.md:43`); no ring above the head, no twisting beam, no ball in the hand (`docs/legal/energy-overhaul-screen.md:8-14`) | **In question.** Since 2026-11-07 look rules are Orb's creative rules. Orb has already asked for a golden cloud above the head, black plasma and bolts. Question 1 asks about the rest. Legal should confirm in one line that the shape rows moved with the others |

## 6. The port to Godot

### What is there now

| Effect | Drawn by | Notes |
| :--- | :--- | :--- |
| Standing aura | One rectangle per fighter in a shared batch (`render/vfx/transform_view.gd:55-86`); size from a per-tier table (`data/vfx/transform.json`); colour from the fighter's `aura` | One shape, one colour. It also carries the losing-a-struggle flare and the low-energy flicker |
| The aura during a transformation | A second path: the standing aura is switched off and the transformation draws its own (`render/vfx/aura.gd:86-90`; `render/vfx/transform_view.gd:148-207`) | |
| Beam body | Three stacked tubes per beam, three draw calls (`render/core/beam_view.gd`, Rendering's); look and width from `data/vfx/energy.json`, per fighter | The drawn layers are fixed multiples of the width that hits |
| Beam fronts and blast heads | Two batches of 96 pieces (`render/vfx/energy_head.gd`, made in `shots_view.gd` and `beam_front.gd`). **Off by default** | |
| Shots | One batch of 380 pieces that also draws about ten other things, the charge at the hand among them (`render/vfx/shots_view.gd`) | |
| An older placeholder aura | `render/core/fighter_view.gd:139-148`, `:458-486`; hidden while head flashes are on | |

Everything is drawn once per split-screen pane, each pane its own world. There are no particle systems: every particle is a rectangle in a batch. One shader in the game reads the picture behind it (the clash), in two versions, and it costs a copy of the frame per pane.

### The shape of the port

**New, under `render/vfx/look/`** (VFX's own folder):

| File | Job |
| :--- | :--- |
| `look_profile.gd` | Load, check, migrate, pack for travel. No drawing |
| `look_resolve.gd` | Per slot: apply the limits, the quality level, the tier step, the two-player and colour-vision corrections. Output: plain packed numbers. Lives on the shared effects hub, so every pane reads the same thing. Runs at match start and again whenever the quality level changes, which it can mid-match |
| `energy_view.gd` | Per pane: the rectangles |
| `shaders/energy.gdshader`, `energy_core.gdshaderinc` | The one shader |

**The shader** is the toy's first pass with these changes:
1. **It is told what it is wrapped round** (body, beam or blast) instead of guessing from sizes.
2. **It gets its outline from the game.** A body is ten capsules taken from the fighter's skeleton each frame, joined softly as the toy's stand-in figure is. Animation owns the skeleton (`render/anim/anim_fighter.gd:27`, `:2343`) and VFX already reads joints from it (`render/vfx/press.gd:28`, `:561`). The capsules must go through what the body goes through on its way to the screen (the turn and mirror, the launch spin, the projection round the fighter's anchor, the planet's bend: `render/core/fighter_view.gd:404-412`, `:518-528`), and there is a plain outline for when animation is off.
3. **Light and darkness leave together** through one blend that can both add and darken. No shader in the game uses that blend yet. *To verify* on the web build.
4. **It takes the game's signals as inputs:** the tier step, the energy flicker, the struggle flare, and the transformation's gather, break and settle (`render/vfx/transform.gd`), so the transformation's own aura is the player's look growing a tier, not a different drawing.

**Each emitter is one rectangle** sized to its reach limit. Layers are worked out inside one pixel, never as stacked rectangles. A pixel outside the look's reach is dropped before the costly work.

| Emitter | Geometry | Draw calls per pane |
| :--- | :--- | :--- |
| Aura | One rectangle per fighter, its own material | 1 a fighter |
| Shots, and beam fronts and blast heads if they are switched on | Moved out of the shared batch into one new batch per player on the energy shader; each piece carries its seed and age | 1 or 2 a player |
| Beam | For the alpha: the three tubes kept, their colour and pattern taken from the look (`render/vfx/beam_look.gd`, VFX's; the geometry in Rendering's file is not touched). Later: one ribbon along the beam's segments | 3 now, then 1 |

**The crest, the crown and the drip** come across as in the toy.

**What the first version leaves out, said plainly:**
- **The lingering trail.** The toy carries last frame's light forward. In the game that needs a kept buffer per pane that survives the camera moving. The first version gives each look a "linger" that stretches its streaks inside the shader, and at the top quality level draws one earlier moment faintly behind the current one. **This is the largest risk to the look.** Two of Orb's three presets use trails; Orb's own first find does not.
- **Heat shimmer and "Negative".** Both read the picture behind them. In Godot that is a second shader program and a copy of the frame in every pane whenever one is on screen, and the copy does not contain beams or auras. Version 1 draws their fallbacks at every level. They come back only if measured and wanted.
- **The light on the figure's edge.** The toy lights its stand-in's rim from the aura. In the game the aura is behind a body that does not take that light. Named here so Orb judges a known loss.
- **The whole-picture brightness reader.** Replaced by the limits in section 5.

### Cost

No machine is a target (ADR 0013). The readings that mean something are Orb's PC, the second PC, and the web build on a modest built-in graphics chip at 720p, where the frame is bound by pixels (`docs/perf/quality-range.md:39-44`).

- **Budget, to be measured:** with both auras, two beams in a clash and four blasts on screen, at most 1.0 ms added at the middle and 1.5 ms at the slow end on that web reading; at most 4 draw calls added per pane; at most 0.1 ms of script a frame.
- **How:** `docs/perf/tools/frame-bench.mjs` on its clash scene, with a word in the page's address that puts a preset on a fighter (as the blast heads' own switch does), in a quiet window. Performance takes the reading.
- **Each catalogue entry carries a cost,** counted from the toy's code in units of one noise lookup: a shell 4; sparks and falling particles 18; lightning 12; cloud 12; smoky fluid 12; crackle, frost and shards 9; most others 1 or less. "Runs backward" doubles its layer. These are relative only until L3 turns one into milliseconds.
- **A look may cost 120 units.** The toy's worst case is about 320. The Style screen shows the cost as a small meter and will not add what does not fit.

**The quality ladder,** in `energy-quality.json`, on the three levels the game has today (`render/vfx/vfx_look.gd:170-172`):

| Level | Layers drawn | Noise detail | Earlier-moment trail |
| :--- | ---: | ---: | :--- |
| High | 5 | 4 | Yes |
| Medium | 4 | 3 | No |
| Low | 3 | 2 | No |
| Performance (when built) | 2 | 1 | No |

The first layers are the ones kept, so a player puts what matters first. A profile always stores all its layers. The game changes level by itself when the frame rate drops, so a layer can leave mid-fight; whether that reads as a pop is for Orb to judge in L3. Each level needs its own picture readings, in both looks (RL-208).

**Start-up.** `energy.gdshader` joins Rendering's warm-up list twice (it is drawn both as a single rectangle and as a batch) and its slowest-to-compile list, in the same change that adds it (`render/core/warmup.gd:18-38`; `render/core/boot.gd:23`).

### What is replaced, wrapped and left

| | Files |
| :--- | :--- |
| **Replaced** | The standing aura's drawing (`render/vfx/transform_view.gd:55-86`) and the transformation's own aura and gather streaks (`:148-207`). The *style* fields of the per-fighter beam rows in `data/vfx/energy.json` (colour shift, ripple, flow, pattern) and of the per-fighter rows in `data/vfx/clash.json`, for a fighter wearing a look |
| **Kept as the game's outline** | The aura's size by tier (`data/vfx/transform.json`); each fighter's beam width and its heel and wobble (`data/vfx/energy.json`); the transformation's timing |
| **Wrapped** | `render/vfx/aura.gd` (still decides when an aura shows and how strongly); all 18 callers of `lane_color`; `render/vfx/beam_look.gd`; `render/vfx/beam_front.gd`; `render/vfx/energy_head.gd`; `render/vfx/clash_look.gd`; `render/vfx/beam_struggle.gd` (still drives the bulge) |
| **Split** | `render/vfx/shots_view.gd`: the live shots move out. The charge at the hand stays the game's and takes only the look's colour. Impacts, mines and its other effects stay where they are |
| **Left alone** | `render/core/beam_view.gd`'s geometry, until the ribbon; `render/vfx/blast.gd` and the blast cloud; `render/vfx/palette.gd`; `render/vfx/glare.gd`; `render/vfx/flash_registry.gd`; the placeholder aura in `render/core/fighter_view.gd`, which retires with the head-flash switch, not here |

### With the combat directive

`docs/ep/proposals/combat-overhaul-directive.md` makes a beam a chain of segments that fly, and shots bodies that fly. **The look rides on those and never steers them.**
- The ribbon follows the simulation's segments exactly. A bent beam bends because its segments did.
- A blast is drawn where the simulation says its body is, pointed along its velocity.
- The clash point and the pulses in a struggle are reserved (LP3): drawn by the game in the look's colours. Each fighter's own struggle look stays theirs (LP11).
- **The ribbon (L9) waits for the directive's segment brief and its golden window.** The alpha's beam is the tubes with the look's colour and pattern (L4), which touches only VFX's file.

### With the marks on fighters

Orb has ruled that the 26 marks drawn on and round fighters are placeholders for effects that belong to the fight (`docs/vfx/marks-on-fighters.md:3`). Nineteen are to be replaced, several by the aura brightening or cresting, as a VFX row in A3 (A-RENDER-13). That work and this draw the same aura. **L3 goes first,** and builds the aura so those tells are layers the game draws inside it, in the fighter's own colour (LP3).

## 7. The Style screen

### What the menus do today

One step a press, no held repeat. A chooses; **B and Start both go back** (`ui/hud/ui_hud.gd:2061`, `:3059`). The d-pad and the left stick move. LB and RB change tabs in Options only. X is unused; Y is designed as "details, or reset this page" and not built (`docs/ui/menus-modern.md:52`). Every word is a key in `ui/data/terms.json`. No menu has a live picture of anything. Saved settings are one flat file with no version (`ui/core/ui_prefs.gd`).

### The first screen

- **Where:** a "Style" row on the main list, and "Player 1 look" and "Player 2 look" rows in the match setup that pick from saved looks. Behind a switch, `style_screen`, off on main and on in Orb's build. **Both switches stay off in the testers' package,** and its words stay out of that package's word sheet, until the EP says otherwise.
- **Layout:** the rail on the left; on the right, the live preview: the fighter powered up with their aura, firing a beam, and a blast hovering, in the game's own renderer.
- **Rows:** Preset; Layer 1 to 5 (A opens the layer); Trails; Random; Mutate; Back one step; Save; Back. A locked layer row says what earns it.
- **A layer's page:** Shape, Movement, Finish, Colours, then the sliders, then Remove. (The data says behaviour, material and palette; a player would say movement, finish and colours.) A locked choice is greyed with its tier in words. A slider shows its locked stretch greyed.
- **Trying it against the world:** one row cycles the preview's backdrop through the biomes and skies.
- **The preview obeys "Reduce flashing"** as a match does, so a player designs the look they and most others will see.

| Button | Does |
| :--- | :--- |
| D-pad or left stick, up and down | Move, wrapping |
| Left, right | Change the lit row by one step. Held, it repeats at 6 a second (designed in `docs/ui/menus-modern.md:67`, not built), after a short delay that is new here |
| LT or RT held | Left and right move ten steps |
| A | Open or choose |
| B, Start | Back, as everywhere. Asks "Keep changes?" only if there are any |
| X | Random |
| LB, RB | On a layer's page, the previous and next layer. Later, the previous and next tab |
| Y | Left for its designed use |

Save and Mutate are rows, not buttons. "Mutate" is the toy's word; it goes to Orb with the other words before it ships.

- **Saving:** eight looks in `user://looks.json` (`{"schema": "look.store/1", "profiles": [...]}`), its own file with its own version, so a damaged look file cannot wipe the settings.
- **Which look a player wears** is remembered as an id in a setting of its own. It resolves in this order: a look in the store; a preset; the fighter's default. A deleted look falls to the next.
- **Two players:** one look is edited at a time, from the main menu, by any controller. A limit of today's menus.
- **The preview** is the first live picture in any menu, and it moves more than the menus' own motion rule allows (`docs/ui/menus-modern.md:67`). UI should rule it an exception, as it shows the game's own drawing under the game's own limits. Rendering supplies it as one node fed a profile; UI places it. It needs L3. Where the rail does not fit, the preview is dropped and the rows stay.
- **The UI's own gates:** a line in the screen sweep; menu rules in the HUD check at every size including 1280 by 800; stills; a side-by-side; every word within the length budget and marked by Orb.

### Growing into the character creator

The tabs are data (`ui/data/look_tabs.json`): Energy first, then Body, Colours, Face, Hair, Outfit, Accessories, Voice, Poses, each "Coming" until its part exists. Each tab edits one part of the same profile, through the same preview, with the same Random, Mutate, Back and Save. Nothing about the store, the replay field or the travelling form has to change to add one.

## 8. Legal

Rows to open, from RL-282:

1. **Catalogue names and label words.** Screened as in-game labels (`docs/legal/name-screening.md:92`), in one batch. Because names are kept apart from ids, a rename costs nothing.
2. **Players naming looks.** Two words picked from the game's own lists. No typed text.
3. **Sharing and importing, later.** A shared look is the travelling form: ids and numbers. Import reads data only, clamps every value, and can never carry code, a picture or a name.
4. **Earned, never sold** (ln03).
5. **AI disclosure.** The looks are made by rules, not by a model while the game runs. The system, the catalogue and the presets were made with AI assistance and carry provenance rows as ADR 0007 asks.
6. **The picture checks** on the new shader, at each quality level and in both looks, before any build with it on reaches someone outside. Legal's and the EP's.
7. **"Show other players' looks"** as a setting, default on.
8. **One line confirming** that the shape rows of the energy screen moved to the creative rulebook with the other look rules.

The creative rulebook has no page yet (`docs/art/creative-rulebook.md` does not exist). Question 1 is its first entry.

## 9. Order of work

### Where this sits in the plan

- **It is not in any milestone.** Nothing in `docs/production/milestones.md` covers it, and the alpha plan's own rule is that something new waits for Orb's yes and something of the same size goes out. Orb has asked for this work to be led and started (`docs/ep/vision.md:1949`). I read that as a yes to designing it and to the spike, and **not** as a yes to the whole build.
- **Proposed:** L3 now, as a trial. The rest in A3, reaching the friends as their first update, if Orb keeps the trial.
- **Size:** about 14M tokens for the ten alpha briefs, by the audit's classes, plus a night of picture readings at each quality level and about 0.6M for each gate re-run. What goes out to make room, or whether the free reset pays for it, is the EP's and Orb's to say.
- **It competes for the same people as the testers' package.** Tools, VFX and Rendering are on that package's longest job (`docs/ep/reviews/A2-sprint.md:15`, `:57`). The look work takes none of their time that the package needs. L3 starts when the EP says VFX and Rendering have room, and its captures queue behind the package's.

One switch, `look_profiles`, off on main and on in Orb's build. With it off the game draws exactly as today and loads none of this.

| # | Brief | Director | Size | When | Acceptance |
| ---: | :--- | :--- | :--- | :--- | :--- |
| L3 | **The trial: one aura.** A minimal catalogue and loader, the shader, the resolver, the skeleton capsules, on one fighter: Orb's three presets and Orb's first find | VFX; Animation for the capsule read; Rendering for the warm-up and the body's transform | L (4M) | First | Switch off: pictures and draw calls unchanged. Switch on: toy beside game for the four looks, standing, through a transformation, and while losing a struggle; in the reduced look first, then the full one; no stutter on first use; state hash unchanged; picture readings in both looks. **One question to Orb: "Keep this, keep it only if the trails come back, or stop?"** Stop means nothing below is briefed |
| L13 | The cost reading for L3, in a quiet window, at three quality levels, on the web reading and both PCs | Performance | S | With L3 | Within the budget, or the number it missed by |
| L1 | The full catalogue, limits, quality, forms and reward files; schemas, map rules, cross-file rules and failing cases; the toy generated from them; the converter for toy files | VFX writes the data; Game Design rules tiers and rewards; Tools the schemas, the validator rules and CI; the EP names who edits the toy | M (1.2M) | After L3 is kept | The data job is green; generating the toy's block again changes nothing; Orb's first find converts and validates; the awkward profiles of section 2 load as it says, in both readers |
| L2 | The `looks` field in a replay; the owner tag on five effect events; the proof | Simulation (the tag, and reviewing the replay writers); VFX and Tools (the three writers); Tools (the CI job) | M (1.2M) | After L3 is kept | The proof of section 3 passes and its control fails; a file from a match with no looks is identical to today's; the effects' hash is unchanged by the tag |
| L4 | Shots through the shader, split out of the shared batch; the beam's colour and pattern from the look | VFX | M (1.2M) | After L1 | Each player's shots draw in that player's look; draw calls within budget; the game's core and edge are drawn under every preset in the reduced look; the charge at the hand is unchanged in shape and timing |
| L5 | The Style screen and the look store | UI; Rendering for the preview node; Narrative for the label words | L (4M) | After L3 is kept; the preview's beam and blast after L4 | The UI gates of section 7; a look saved, the game closed and reopened, the look still chosen; pad alone from the main menu to a saved look; a newer-version look in the store survives a save of another |
| L6 | Legal's rows 1, 2, 4, 5, 7, 8 | Legal | S | With L1 | Rows written; names passed or renamed |
| L7 | Default looks for the two fighters that exist; the creative rulebook's first page | Art and Animation | S | With L1 | Two files that validate; the hero's and the rival's read as a pair |
| L14 | The reduced-motion column; colour-vision settings through the resolver | Accessibility, with VFX | S | With L4 | Each setting changes what section 5 says and nothing else |
| L8 | A soak: 200 random looks through seeded matches | QA | M (1.2M) | After L4 | No error; the proof holds in every match; the cost budget held at each level; a sheet of stills, biome by sky by palette, in both looks, with any unreadable case named |

**After the alpha:**

| # | Brief | Waits on | Done when |
| ---: | :--- | :--- | :--- |
| L9 | The beam as one ribbon with the full shader | The directive's segment brief and its golden window | One draw call a beam; the ribbon on the simulation's segments to the pixel; one look gate with the readable beam |
| L10 | Trails that linger properly; shimmer and "Negative" | Orb finding the first version lacking | A kept buffer that follows the camera, within the cost budget, with its own readings |
| L11 | The `look` message on LAN | LAN reaching players | The heaviest look in one packet; a match that starts with no look from one side; a late look taking effect with no fade |
| L12 | Rewards from the campaign; per-tier overrides; sharing | A campaign; decision 17; Legal's row 3 | |
| L15 | The creator's next parts, colours first | Art's second body colour | Each as a new part, with no change to L1, L2 or L5 |

### What each brief needs from the shared PC

| Brief | Captures | Quiet window | Nights of picture readings |
| :--- | :--- | :--- | :--- |
| L3 | Toy-beside-game stills, one at a time | No | One |
| L13 | No | Yes, about an hour | No |
| L4 | Stills | No | One per quality level |
| L5 | The screen sweep | No | No |
| L8 | The stills sheet | No | No |

None of those nights is booked. The package's own readings come first.

## 10. The path to the alpha

What I would tell the EP, weighing the package plan (`docs/ep/reviews/A2-sprint.md`), Orb's notes on build 0.1.1, and this.

1. **Three lanes.** The package lane (the tester-safety readings, the packaging chain, Orb's sittings, the friends). The fight lane (the combat directive's first wave, which answers what Orb said about playing). The look lane (this spec).
2. **The look lane is the only one that cannot break a replay,** so it can land behind an off switch whenever it is ready. That is its one real advantage. It does not make it free: it uses the package lane's busiest people and its capture queue, and it must give way to them.
3. **The friends' first build should have neither the new looks nor the readable beam.** Both change the picture, and the readings that decide whether a build may go out are taken on a picture. They reach the friends as the first update, with every gate run again, which is what the alpha plan already expects of A3.
4. **Whether the grab and charge retune is in the friends' first build is a separate call.** It is the thing that stopped Orb wanting to play on Medium. But it is rules and computer behaviour behind its own switch (`docs/design/grab-and-charges.md:8`), it moves the game's fingerprint, and the package plan says nothing in it changes the fight. Putting it in costs a re-recording and a difficulty reading. That is Orb's choice and the EP's window, not this spec's.
5. **Why not wait and send the friends the better game?** Their first job is to say whether it installs and runs on a Deck, which nothing here improves, and the wait for them is the longest on the path.
6. **Orb's build runs ahead.** Every switch is on there. Orb judges the trial aura, the readable beam and the swing toward the city in play, well before any of it is in a package.
7. **Do the trial before the rest.** L3 is one brief. If the looks do not survive the move off the toy, that is learned for 4M tokens, not 14M.
8. **The free reset.** Spend it in the week the package's readings and the look's trial overlap, when the most directors can work without waiting on each other.
9. **What I would not start yet:** any creator part beyond energy; sharing; campaign rewards; the LAN message. Each has a place to go in this spec, and none is on the path to a first alpha.

**The most likely way this fails:** the trial is judged late, behind the package's queue, after other look work has been spent; or the trail's loss makes the look feel cheaper than the toy and nobody says so until the Style screen is built. The order above is there to prevent both.

## 11. Questions for Orb

1. **May looks do what the older look rules said no to?** You have already asked for a golden cloud above the head, black plasma and bolts, so those are in. The toy also makes a ring that circles you, a beam that twists, flame-like shapes and white-hot colours, which earlier rules also said no to. *I think you would say yes to all of them: the toy wins, and the limits that stay are the ones that keep a fight readable.*
2. **What stays the fighter's own?** Your look changes the texture, the colours and the movement of your energy, on any fighter. Each fighter keeps their own beam: its shape, its width and how it struggles. And everyone's energy grows with power the same way and shows the front of a beam and the flash of a hit the same way, so a fight can be read. *I think you would say yes. The other choice is that a look can change a fighter's beam shape too.*
3. **How should looks be earned before there is a campaign?** Start with the common choices and two layers. Earn the rest by playing: rarer choices after 3, 10 and 25 matches, and a third, fourth and fifth layer along the way. *I recommend this. The other choice is everything unlocked for the alpha, with the tiers only shown, which is less work.*

## 12. For the EP to rule, not Orb

- **Owners.** I have put the code in VFX's own folder and the data in a new `data/look/` that I propose VFX owns. The toy (`prototype/energy-toy/`) has no owner: I built it on Orb's word.
- **`docs/art/cosmetics-plan.md`:** its aura line (`:28`) needs changing; its never-created loadout folder should become `data/look/`; its rule for two players who look alike differs from section 5's.
- **The blast heads are off by default** (`render/vfx/vfx_look.gd:173`). L4 either ships them through the look or leaves them off. It should not leave two half-systems.
- **The resting aura.** Game Design's page says energy is shown by the aura; Orb's rule says there is no aura at rest. Game Design should say which signal carries energy between attacks.
- **The white core** (section 5): Art's rule under Orb.

## What is not known

- **Engine facts to try in L3:** the add-and-darken blend on the web build; ten capsules as shader inputs taken through the body's projection; whether the toy's colours match the game's once the engine converts them for the screen, so that toy beside game is a fair comparison; whether capping each emitter alone is enough where they overlap.
- **Cost.** Every figure in section 6 is counted from reading the toy's code, not measured.
- **The look itself.** Nobody has seen a toy look drawn on a rectangle round a moving fighter.
- **Not read by me:** most VFX shader bodies; `beam_view.gd` beyond its structure; the campaign design page; the stamina page past its first sections. I rely on the readers and reviewers for those, and they list their own gaps.

## How this was done

- **Eight Opus readers,** one per area (the energy rules; today's drawing; the frame budget; brightness and legibility; menus and saves; replay and network; data, fighters and Legal; an audit of the toy), about 1.1M tokens, read-only. I read the energy rules, the taste page and the roster page myself.
- **Five Opus reviewers** then attacked the first draft against the code (separation and network; the port; the data model; Orb's rules, legibility and the menu; the plan), and **five checkers** tried to refute every larger finding: about 1.5M tokens. 59 findings. Of the 42 larger ones: 27 confirmed, 15 lowered, none thrown out. I checked seven of the confirmed ones by hand and all held.
- **What the review changed:** how a look is found (by slot, not by colour, across 18 call sites); the owner tag on effect events; the replay field written outside the simulation; a travelling form that fits one packet; a proof that actually runs the look path; beam width and aura size kept as the game's; the transformation's own aura; shimmer and "Negative" cut from version 1; brightness capped per emitter; the skeleton's real owner; the shots batch split; closed schemas for the repo's files; the seed promise made honest; rewards that cannot strand a save; the pad map (Start is Back); same-fighter picks kept off; the fighter's kit kept the fighter's; the marks-to-auras work; owners corrected; and the plan stated as a proposal with a size, not as agreed alpha work.
- **Not done:** no second review of this draft. Nothing here was run.

## Orb's answers (2026-11-28, about 02:00; verbatim in docs/ep/vision.md)

1. **The toy wins.** Everything the toy makes is allowed, within the limits of section 5.
2. **The fighter keeps their beam's shape, width and struggle.** Looks change texture, colour and movement.
3. **Everything is unlocked for the alpha.** Tiers are only shown. The earn-by-playing rules (3, 10 and 25 matches) are not built for the alpha; the reward file's shape stays, so the campaign can use it later.
