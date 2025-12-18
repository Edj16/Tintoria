extends Area2D

var orb_color: Color = Color.RED
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Knight":
		get_tree().get_root().get_node("Main").update_bar()  # progress bar
		var bg = get_tree().get_root().get_node("Main/Bg").get_child(0) as BgParallax
		if bg:
			bg.reveal_next_layer()

		queue_free()
