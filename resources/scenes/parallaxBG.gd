extends ParallaxBackground

class_name BgParallax

var SceneManager = preload("res://resources/scenes/scene_manager.gd")

var original_colors: Dictionary = {}
var layer_colors: Array = []
var revealed: Array = []
var parallax_layer_count: int = 0
		
# Setup the background for a specific scenery
func setup(scenery: String):
	print("Setting up background for:", scenery)

	parallax_layer_count = _count_parallax_layers()
	print("Number of parallax layers:", parallax_layer_count)
	send_layer_count_to_main()

	# Get the intended colors for each layer
	layer_colors = SceneManager.sceneries[scenery]["colors"]

	# Initialize revealed flags
	revealed.resize(layer_colors.size())
	revealed.fill(false)

	# Store original colors and hide all layers
	for layer in get_children():
		if layer is ParallaxLayer:
			_store_and_hide(layer)
			
func send_layer_count_to_main():
	var layer_count = _count_parallax_layers()

	# Get Main (unique instance)
	var main = get_tree().get_first_node_in_group("main_node")
	if main:
		main.set_layers(layer_count)
		
# Store original modulate and set all sprites + layer alpha to 0
func _store_and_hide(layer: ParallaxLayer):
	for node in layer.get_children():
		_process_node_recursive(node)

	# Hide the layer itself
	layer.modulate = Color(1, 1, 1, 0)


# Recursively store original modulate and hide sprites
func _process_node_recursive(node: Node):
	if node is Sprite2D:
		original_colors[node] = node.modulate
		node.modulate = Color(node.modulate.r, node.modulate.g, node.modulate.b, 0)

	for child in node.get_children():
		_process_node_recursive(child)


# Reveal a layer by its index
func reveal_layer(index: int):
	if index < 0 or index >= layer_colors.size():
		return
	if revealed[index]:
		return  # already revealed

	revealed[index] = true
	var layer = get_child(index)
	if layer and layer is ParallaxLayer:
		_reveal_recursive(layer)


# Reveal a layer by its associated color
func reveal_color(color: Color):
	for i in range(layer_colors.size()):
		if layer_colors[i] == color:
			reveal_layer(i)
			return

# Recursive fade-in helper
func _reveal_recursive(node: Node):
	if node is Sprite2D and original_colors.has(node):
		var target_color = original_colors[node]
		var tween = create_tween()
		tween.tween_property(node, "modulate", target_color, 0.4)
		
	for child in node.get_children():
		_reveal_recursive(child)


# Optional: Reveal all layers at once
func reveal_all():
	for i in range(layer_colors.size()):
		reveal_layer(i)
		
func reveal_next_layer():
	for i in range(get_child_count()):
		var layer = get_child(i)
		if layer is ParallaxLayer and layer.modulate.a < 1:
			# Reveal this layer fully
			_reveal_layer_direct(layer)
			return  # reveal only one layer per orb
			
func _reveal_layer_direct(node: Node):
	if node is Sprite2D:
		node.modulate = Color(1, 1, 1, 1)  # full opacity

	for child in node.get_children():
		_reveal_layer_direct(child)

	# Also set the ParallaxLayer itself if it's a layer
	if node is ParallaxLayer:
		node.modulate = Color(1, 1, 1, 1)

func _count_parallax_layers() -> int:
	var count := 0
	for child in get_children():
		if child is ParallaxLayer:
			count += 1
	return count
	
