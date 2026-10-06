class_name UiStance
## The five stances of Orb's stance layout, as the HUD reads them (docs/ui/hud-spec.md section 36; the words are ui/data/stances.json).
## A fighter's stance is what he holds: nothing is martial arts (kind 0), LB defensive (1), RB energy arts (2), RT charging (3), LT manoeuvre (4).
## The sim's intent carries it as `stanceMask` (LB 1, RB 2, RT 4, LT 8), resolved by the layout to one bit until hybrids exist; a mask
## with more than one bit (a hybrid not switched on) reads as the newer button, which is the one the sim reads, so the badge is never a lie.

const MARTIAL := 0
const DEFENSIVE := 1
const ENERGY := 2
const CHARGING := 3
const MANOEUVRE := 4
const IDS: Array = ["martial", "defensive", "energy", "charging", "manoeuvre"]
const MASKS: Array = [0, 1, 2, 4, 8]


## The stance kind for a held-button mask. RT dominates, then LT, then LB, then RB when several bits are set.
static func kind_of_mask(mask: int) -> int:
	if mask & 4:
		return CHARGING
	if mask & 8:
		return MANOEUVRE
	if mask & 1:
		return DEFENSIVE
	if mask & 2:
		return ENERGY
	return MARTIAL


static func id(kind: int) -> String:
	return str(IDS[clampi(kind, 0, 4)])


static func _row(kind: int) -> Dictionary:
	return (UiData.stances().get("stances", {}) as Dictionary).get(id(kind), {})


## The badge's word (MARTIAL, DEFENSIVE, ENERGY, CHARGING, MANOEUVRE).
static func word(kind: int) -> String:
	return str(_row(kind).get("name", id(kind).to_upper()))


## The full name (Martial arts, Defensive, ...).
static func title(kind: int) -> String:
	return str(_row(kind).get("title", id(kind).capitalize()))


## The legend's word for the button that holds the stance ("Defensive (hold)"), or for an energy button set to toggle ("Energy (toggle)").
static func legend(kind: int, toggle: bool = false) -> String:
	var row: Dictionary = _row(kind)
	if toggle and row.has("_legend_toggle"):
		return str(row["_legend_toggle"])
	return str(row.get("_legend", title(kind) + " (hold)"))


## Whether the stance's four cell names are true on the live build (stances.json `_live`): the legend shows them only then, and keeps its old words otherwise.
static func live(kind: int) -> bool:
	var row: Dictionary = _row(kind)
	return bool(row.get("live", row.get("_live", false)))


## Whether the three-strength layout is on (features.json `three_strengths`): X light, Y medium, B heavy, and the signature on the power button held with B.
static func three() -> bool:
	return UiData.feature("three_strengths")


## The word for a martial face button's action under the three strengths: the action ids stay light, heavy, context and signature (the sim, Controls and the
## remap data use them), so a row whose id says `signature` reads Heavy and `heavy` reads Medium. "" when the flag is off or the action is not one of the four.
static func three_word(action: String) -> String:
	if not three():
		return ""
	match action:
		"light":
			return UiData.t("prompt.three_light")
		"heavy":
			return UiData.t("prompt.three_medium")
		"signature":
			return UiData.t("prompt.three_heavy")
		"context":
			return UiData.t("prompt.three_context")
	return ""


## Whether a face button (x, y, a or b) has a move in the stance on the live build: once the stance is live every cell does; until then the cells that do nothing
## are listed in stances.json `_works` (false for them; the rest default to true). The martial A, the charging stance's X, Y and A (the sim never reads `special`) and
## the manoeuvre stance's A do nothing today; RT plus B is the plain signature, A with guard held the deflect and A in the energy stance a mine, so those are not listed.
static func cell_works(kind: int, button: String) -> bool:
	if live(kind):
		return true
	return bool(((_row(kind).get("_works", {}) as Dictionary)).get(button, true))


## Whether the legend keeps the Specials row: yes until the charging stance is live (its cells then name the specials).
static func specials_row() -> bool:
	return not live(CHARGING)


## The badge's word for an armed stance ("NEXT BLOW"), or the touch button's short one ("NEXT").
static func armed_word(short: bool = false) -> String:
	return str(UiData.stances().get("_armed_short" if short else "_armed_word", "NEXT BLOW"))


## The Full touch button's word for the stance it holds (its name) once the stance is live; "" keeps the old word (GUARD, POWER, DODGE).
static func touch_word(action: String) -> String:
	if not UiHints.HOLD_STANCES.has(action):
		return ""
	var kind: int = int(UiHints.HOLD_STANCES[action])
	return word(kind) if live(kind) else ""


## A small number that changes when any stance's live flag does (for a redraw key).
static func live_bits() -> int:
	var n := 0
	for k in range(5):
		if live(k):
			n |= 1 << k
	return n


## The one-line description of the stance (stances.json `_blurb`), only while the stance is live (otherwise "": it would describe moves that are not in the game).
static func blurb(kind: int) -> String:
	return str(_row(kind).get("_blurb", "")) if live(kind) else ""


## The controls page's row for the button that holds the stance (stances.json `_howto`), only while it is live; "" keeps the data's own words.
static func howto_word(kind: int) -> String:
	return str(_row(kind).get("_howto", "")) if live(kind) else ""


## The Remap screen's {label, help} for the action that holds a stance (guard, mode, power, dodge), only while that stance is live; {} keeps the old words.
static func remap_words(action: String) -> Dictionary:
	if not UiHints.HOLD_STANCES.has(action):
		return {}
	var kind: int = int(UiHints.HOLD_STANCES[action])
	if not live(kind):
		return {}
	var row: Dictionary = _row(kind)
	if not row.has("_remap"):
		return {}
	return {"label": str(row["_remap"]), "help": str(row.get("_remap_help", ""))}


## What a face button does in the stance: button is "x", "y", "a" or "b".
static func cell(kind: int, button: String) -> String:
	return str((_row(kind).get("cells", {}) as Dictionary).get(button, ""))


## The stance's colour on the badge (never the only cue: each has its own icon and word).
static func col(kind: int) -> Color:
	match kind:
		MARTIAL:
			return UiLook.stance_col(0)
		DEFENSIVE:
			return UiLook.stance_col(1)
		MANOEUVRE:
			return UiLook.stance_col(2)
		CHARGING:
			return UiLook.stance_col(3)
		_:
			return UiLook.col(UiLook.WARN)
