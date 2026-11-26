extends SceneTree
## The sound proof (audio/audio_proof.gd) from the project, with no game:
##   godot --headless --path . --script res://audio/audio_proof_main.gd


func _initialize() -> void:
	_add.call_deferred()


func _add() -> void:
	root.add_child(load("res://audio/audio_proof.gd").new())
