extends Node

static var sceneries = {
	"forest": {
		"platforms": [preload("res://resources/scenes/platform/platform_2.tscn"), preload("res://resources/scenes/platform/platform_3.tscn"), preload("res://resources/scenes/platform/platform_4.tscn")],
		"obstacles": [preload("res://resources/scenes/obstacle/mushroom.tscn"), preload("res://resources/scenes/obstacle/rock.tscn"), preload("res://resources/scenes/obstacle/stump.tscn")],
		"colors": [Color.RED, Color.BLUE, Color.YELLOW],
		"bg_parallax":preload("res://resources/scenes/bg_parallax/mountain.tscn")
	},
	"candy":{
		"platforms": [preload("res://resources/scenes/platform/platform_2.tscn"), preload("res://resources/scenes/platform/platform_3.tscn"), preload("res://resources/scenes/platform/platform_4.tscn")],
		"obstacles": [preload("res://resources/scenes/obstacle/mushroom.tscn"), preload("res://resources/scenes/obstacle/rock.tscn"), preload("res://resources/scenes/obstacle/stump.tscn")],
		"colors": [Color.RED, Color.BLUE, Color.YELLOW],
		"bg_parallax":preload("res://resources/scenes/bg_parallax/candy.tscn")
	},
	"clouds":{
		"platforms": [preload("res://resources/scenes/platform/platform_2.tscn"), preload("res://resources/scenes/platform/platform_3.tscn"), preload("res://resources/scenes/platform/platform_4.tscn")],
		"obstacles": [preload("res://resources/scenes/obstacle/mushroom.tscn"), preload("res://resources/scenes/obstacle/rock.tscn"), preload("res://resources/scenes/obstacle/stump.tscn")],
		"colors": [Color.RED, Color.BLUE, Color.YELLOW],
		"bg_parallax": preload("res://resources/scenes/bg_parallax/clouds.tscn")
	},
	"castle":{
		"platforms": [preload("res://resources/scenes/platform/platform_2.tscn"), preload("res://resources/scenes/platform/platform_3.tscn"), preload("res://resources/scenes/platform/platform_4.tscn")],
		"obstacles": [preload("res://resources/scenes/obstacle/mushroom.tscn"), preload("res://resources/scenes/obstacle/rock.tscn"), preload("res://resources/scenes/obstacle/stump.tscn")],
		"colors": [Color.RED, Color.BLUE, Color.YELLOW],
		"bg_parallax": preload("res://resources/scenes/bg_parallax/castle.tscn")
	}
	#"waterfall": {
	#	"platforms" : [],
	#	"obstacles" : [],
	#	"colors" : [],
	#	"bg_parallax":[]
	#},
	#"desert": {
	#	"platforms" : [],
	#	"obstacles" : [],
	#	"colors" : [],
	#	"bg_parallax":[]
	#}
}

#static var square = preload("res://resources/scenes/shape/square.tscn")
#static var circle = preload("res://resources/scenes/shape/circle.tscn")
#static var diamond = preload("res://resources/scenes/shape/diamond.tscn")
#static var triangle = preload("res://resources/scenes/shape/triangle.tscn")
#static var shapes = [square, circle, diamond, triangle]

static var birds_forest = preload("res://resources/scenes/castle_bird.tscn")
static var birds_cloud = preload("res://resources/scenes/bird_cloud.tscn")
static var birds_castle = preload("res://resources/scenes/castle_bird.tscn")
static var birds_candy = preload("res://resources/scenes/bird_candy.tscn")

static func get_bird(scenery: String) -> PackedScene:
	match scenery:
		"forest":
			return birds_forest
		"candy":
			return birds_candy
		"clouds":
			return birds_cloud
		"castle":
			return birds_castle
		_:
			return birds_forest
		
static func get_random_scenery() -> String:
	var keys = sceneries.keys()
	return keys[randi() % keys.size()]
	
# Example: get a platform color
static func get_random_platform(scenery_name: String):
	var platforms = sceneries[scenery_name]["platforms"]
	return platforms[randi() % platforms.size()].instantiate()
	
# Example: get a obstacle color
static func get_random_obstacles(scenery_name: String):
	var obs = sceneries[scenery_name]["obstacles"]
	return obs[randi() % obs.size()]

# Example: get a random color
static func get_random_color(scenery_name: String):
	var colors = sceneries[scenery_name]["colors"]
	return colors[randi() % colors.size()]

#static func generate_shape():
#	var shape = [square, circle, diamond, triangle]
#	return shapes[randi() % shapes.size()]

static func generate_circle (color: Color):
	var circle_orbs = preload("res://resources/scenes/color.tscn")
	var orb = circle_orbs.instantiate()
	orb.modulate = color
	return orb

static func get_background(scenery: String) -> PackedScene:
	return sceneries[scenery]["bg_parallax"]
