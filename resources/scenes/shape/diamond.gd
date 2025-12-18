extends Area2D

@onready var sfx: AudioStreamPlayer2D = $sfx

func _on_body_entered(body: Node) -> void:
	if body.name == "Knight":
		$sfx.play()
		get_tree().get_root().get_node("Main").update_bar()
		queue_free()
