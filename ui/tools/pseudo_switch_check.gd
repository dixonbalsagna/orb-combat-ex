extends SceneTree
## The pseudo-locale switch (UiData._locale_path; docs/accessibility/l10n-plan.md), end to end. Run it twice:
##   godot --headless --path . --script res://ui/tools/pseudo_switch_check.gd                       the default build reads ui/data
##   godot --headless --path . --script res://ui/tools/pseudo_switch_check.gd -- --pseudo-locale    the pseudo build reads localization/pseudo
## A term and the Settings title are compared with the two files on disk; exit 1 on a mismatch.


func _initialize() -> void:
	var on: bool = OS.get_cmdline_user_args().has("--pseudo-locale")
	var plain_terms = JSON.parse_string(FileAccess.get_file_as_string("res://ui/data/terms.json"))
	var pseudo_terms = JSON.parse_string(FileAccess.get_file_as_string("res://localization/pseudo/ui/data/terms.json"))
	var plain_set = JSON.parse_string(FileAccess.get_file_as_string("res://ui/data/settings.json"))
	var pseudo_set = JSON.parse_string(FileAccess.get_file_as_string("res://localization/pseudo/ui/data/settings.json"))
	var term: String = "stance.press"
	var want_term: String = str((pseudo_terms if on else plain_terms)["stance"]["press"])
	var other_term: String = str((plain_terms if on else pseudo_terms)["stance"]["press"])
	var got_term: String = UiData.t(term)
	var got_title: String = str(UiData.settings().get("title", ""))
	var want_title: String = str((pseudo_set if on else plain_set)["title"])
	var ok: bool = UiData.pseudo_locale == (1 if on else 0) and got_term == want_term and got_term != other_term and got_title == want_title
	print("pseudo switch check (%s): %s = %s, settings title = %s" % ["pseudo" if on else "default", term, got_term, got_title])
	print("pseudo switch check %s: the %s build reads %s" % ["passed" if ok else "FAILED", "pseudo" if on else "default", "localization/pseudo" if on else "ui/data"])
	quit(0 if ok else 1)
