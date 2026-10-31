# Bolus: the predator ruling (RL-220)

Owner: Legal and IP Compliance. 2026-10-31. Decision by Orb (owner), after a direct discussion with Legal; sent to the EP at Orb's request. A screen, not legal advice: the real answers come from the rating questionnaires on the real build.

## Three questions, kept apart
1. **IP.** Nothing here conflicts. Copyright protects expression, not the idea of a monster that eats strong fighters. The food-conversion mechanic is cut, which removed the one concrete overlap. The residual IP risk is design-level (look, molt forms, move names, catchphrases) and is screened on the sheets, not here.
2. **Rating and storefront.** Items 1 to 4 below are not AO or store-ban triggers. What moves a rating is what the screen shows, not the dialogue and not the lore label (a demon organism and a humanoid fighter on screen read the same to a board).
3. **AI-model preference.** Not a ground for any ruling in this file.

## The ruling
| Element | Verdict | Limit |
| :-- | :-- | :-- |
| In-match bite or clamp on an opposing fighter's torso, limbs or guard, in a grab or finisher | **Clear** | Brief cartoon impact with sparks or a bruise. The jaw or clamp is a machine part of his chassis. No chewing or swallowing shown or heard, no exposed flesh, blood or gore, no dismemberment or eaten limb, no lingering close-up of a bite to a face or neck. A depicted eating finisher in those forms stays on the stomp treatment (rare, optional, never in public trailers or pages, distant, injury not depicted, no reward). |
| Predator and metabolic dialogue at an opposing fighter (snack, lunch, protein, marrow, calories, tenderized and kin) | **Clear** | Aimed at fighters or wreckage only. Never at a bystander, civilian or child. Grab call-outs keep ln06. |
| Implied, off-screen consumption of defeated heavyweight fighters at his yard, as fuel for his portal | **Clear** | Implied only: words, an empty arena, the portal's glow. No body, silhouette or sound of the act. He never gains a defeated fighter's moves, forms or looks and no absorption visual is drawn. |
| Beam collateral framed as evacuation and shock | **Clear** | No scored body count, no reward (c08, RL-213 to RL-217). |

## Locked in the data (movegen-banned.json)
- **ln02 and ln07 narrowed** as above. Move names for the cleared bite may use bite, clamp or jaw for the machine part, but not maw, devour, swallow, chew or gnaw; no maw in the torso, no belly-as-mouth, no pink plump silhouette.
- **ln08, the lore lock:** Bolus has zero interest in civilians ("empty calories") as a fact of the data and notes, never as a spoken or printed line. He never reacts to toll bands: no line, meter, AI choice or picker reads toll_band, a count or a casualty event. His hunger meter takes fighters' output and objects only (RL-216).
- **ln09, Orb's creative rule, not a legal finding:** no service-industry vocabulary in any Bolus line (sir, madam, menu, tip, chef, table, order, seconds, waiter, restaurant and kin, in the service sense). He is a predator and a furnace, never a waiter. Existing waiter and menu lines (for example in data/narrative/combat_barks.json, live_barks.json, opponent_grounds.json and the narrative docs) need Narrative to rewrite them. 'Order', 'table', 'tip' and 'seconds' are common words, so the lint sends those hits to a human; the unambiguous service words block.

## Predicted tiers for the bite-and-clamp version (baseline)
For this version on its own (brief machine-jaw bites on fighting opponents with sparks and bruising, predator dialogue, off-screen implied consumption, no blood or chewing), the predicted classifications are: **ESRB** Teen with violence descriptors (blood and gore not triggered); **PEGI** 12, at most 16 if a reviewer reads the bite as sustained or realistic, and not 18 (no gross violence, no defenceless victim); **USK** 12 to 16; and **Steam and IARC** no adult-only or sexual-content flag, with the questionnaire answers generating ESRB, PEGI, USK, ClassInd and ACB tiers in that same range. This is the bite on its own: the whole build's tier is driven more by mass destruction and the tracked civilian toll, and c09's working assumption of a Mature target stands for the build. The questionnaires are answered from the real build with these elements in, and a copy of the answers is kept. If any board answers above this paragraph, the bite's close-up and finisher forms are the first things to change, not the dialogue. Ask a professional before relying on a tier in Germany, Australia or a console programme.
