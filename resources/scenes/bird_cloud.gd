extends Area2D

func _ready():
	pass
	
func _process(delta):
	position.x -= get_parent().speed / 2


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Knight":
		get_tree().get_root().get_node("Main").update_life()
		body.hurt()
		print("touched knight")
