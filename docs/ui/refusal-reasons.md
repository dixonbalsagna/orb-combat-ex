# Words for Encounter's refusal reasons (UI & UX, 2026-11-07; the EP's brief, from docs/director/pending/refusal-reasons)

Encounter's park (refusal-reasons) tells a person why a press could not start. The reasons ride the cues UI already reads: `stick_refused` (the reason in `source`) and `press_refused` (the reason in `source`), through `UiEventHub._refusal`, which says `prompt.refuse_<code>` in the legend's teaching row for 1.5 s, the first three times per reason per match, once per frame per word (hud-spec sections 84 and 85). So the new reasons need words, and nothing else: no code change.

| Code | Word | What holds him (Encounter's meaning) |
| :-- | :-- | :-- |
| `locked` | Locked in | in a planned exchange with no window of his |
| `launched` | In flight | sent flying |
| `down` | Knocked down | down or dropped |
| `stunned` | Stunned | stunned or reeling (the word was already there) |
| `queue_full` | Too many presses | he is free and the attack queue is full |
| `not_yours` | Their move | the first move of the exchange is his rival's |
| `recovering` | Recovering | a held flick, too old by the time he was free |
| `set_piece` | In a move | a finisher, the KO or another set piece (Controls suggested the word) |
| `chord` | One at a time | B with X or Y on one tick: Controls' chord pick drops the smaller press and tells it |
| `busy` | Busy | a state that cannot take the press |
| `not_ready` | Not ready | a transform with no form ready (Encounter's press-answers, sent as `press_refused`; before this word it was dropped and only counted as unread) |

All placeholder wording, plain words, Narrative's to change. `stun_limit` and `answered` are no longer sent (their words and the silent `answered` stay in the data, harmless). `not_yours` and `busy` were silent in Controls' `take_refusals()` list (hud-spec section 85's table); with a word they now speak from both feeds, and the once-per-frame-per-word rule keeps a press told twice from being said twice.

**Tests (`_refusal_reason_words_rules`, 2 checks in hud_check):** each code says its word through `stick_refused`; `queue_full` through `press_refused`; only the first three times; the computer is never told. Fails with a word removed (tried).
