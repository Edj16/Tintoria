extends Node
var captured_bg_image: Image = null
var bg_captured: bool = false
var capture_display: TextureRect = null
var capture_label: Label = null

@onready var retry_button = $HUD/Retry_Button
@onready var sound_on_button = $HUD/On_Button
@onready var sound_off_button = $HUD/Off_Button


#game
var SceneManager = preload("res://resources/scenes/scene_manager.gd")
@onready var lose_timer: Timer = $LoseTimer  
const LOSE_DURATION := 2.0 
var can_change_scenery := false

#scenery
var current_scenery: String = "forest"
var obstacles : Array
var platforms : Array
var last_platform_x : float = 0
var last_object_x : float = 0
var layers_total := 0
var amount_per_orb := 0.0

#Player
const KNIGHT_POS := Vector2i(104, 536)
const CAM_START_POS := Vector2i(576, 324)
var difficulty
const MAX_DIFFICULTY: int = 2
var score : int
const SCORE_MODIFIER : int = 10
const LOSE_DISTANCE := 50

var speed : float
const START_SPEED : float = 6.0
const SPEED_MODIFIER : int = 5000
const MAX_SPEED : int = 25
var screen_size : Vector2i
var ground_height : int
var game_running : bool
var knight_blocked: bool = false  

#Progress Bar
var run_progress : float = 0
var run_required : float = 200  # starting requirement
var progress_growth : float = 1.25  # how much harder each level becomes

var life : int

#obstacle generator
var BIRD = preload("res://resources/scenes/bird.tscn")

var bird_heights := [200, 390]
var last_obs

const MIN_X_DIST : float = 200
const MAX_X_DIST : float = 400
const MIN_Y : float = 200
const MAX_Y : float = 500


func _ready():
	screen_size = get_window().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	
	retry_button.hide()
	retry_button.pressed.connect(restart_game) 
	retry_button.process_mode = Node.PROCESS_MODE_ALWAYS
	
	sound_on_button.show()
	sound_off_button.hide()
	
	sound_on_button.pressed.connect(toggle_music_off)
	sound_off_button.pressed.connect(toggle_music_on)
	
	sound_off_button.process_mode = Node.PROCESS_MODE_INHERIT
	sound_on_button.process_mode = Node.PROCESS_MODE_ALWAYS

	new_game()
	fade_in_out_game_start()
	  
func new_game():
	#reset score
	score = 0
	difficulty = 0
	life = 3
	game_running = false
	BgMusic.play_music()

	$Knight.position = KNIGHT_POS
	$Knight.velocity = Vector2i(0, 0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0,0)
	
	#reset HUd and gameOver scene 
	retry_button.hide()
	
	$HUD.get_node("ScoreLabel").hide()
	$HUD.get_node("LifeLabel").hide()
	$HUD.get_node("StartLabel").show()
	$HUD.get_node("LifeLabel").text = "LIVES: " + str(life)
	$HUD.get_node("HomepageBackground").show()
	$HUD.get_node("PlayButton").show()
	$HUD.get_node("Homepage-Title").show()
	
	
	$HUD.get_node("Collect_Button").hide()
	$HUD.get_node("Continue_Button").hide()
	$GameOver.hide()
	$Win.hide()
	
	current_scenery = SceneManager.get_random_scenery()
	load_background(current_scenery)
	
	obstacles = []
	platforms = []
	last_object_x = 0
	last_platform_x = 0
	
func _process(delta):
	if game_running:
		
		speed = START_SPEED + score/SPEED_MODIFIER
		if speed > MAX_SPEED:
			speed = MAX_SPEED
		adjust_difficulty()
		
		#generate 
		generate_objects()
		
		#moving knight and camera
		$Knight.position.x += speed
		$Camera2D.position.x += speed
		
		#update score
		score += speed
		show_score()
		
		#update ground position
		if $Camera2D.position.x - $Ground.position.x > screen_size.x * 1.5 :
			$Ground.position.x += screen_size.x
			
		#remove obstacles from mmemory
		for obs in obstacles:
			if obs.position.x < ($Camera2D.position.x - screen_size.x):
				remove_obj(obs)
		for plat in platforms:
			if plat.position.x < ($Camera2D.position.x - screen_size.x):
				remove_obj(plat)
				
		var camera_rect = Rect2($Camera2D.global_position - Vector2(screen_size.x, screen_size.y) / 2, Vector2(screen_size.x, screen_size.y))
		if not camera_rect.has_point($Knight.global_position):
			if not lose_timer.is_stopped():
				pass  # already running
			else:
				lose_timer.start(LOSE_DURATION)
		else:
			# Knight is visible, stop the timer
			lose_timer.stop()
		
		if can_change_scenery and Input.is_action_just_pressed("interact_c"):
			change_scenery()
			
		if can_change_scenery and not bg_captured and Input.is_action_just_pressed("capture"):
				captured_bg_image = get_viewport().get_texture().get_image()
				captured_bg_image.flip_y()  # textures are flipped vertically
				bg_captured = true
							
				print("Background captured!")
				show_captured_bg()
				
				game_win()
	else:
		if Input.is_action_pressed("ui_accept"):
			game_running = true
			retry_button.show()
			$HUD.get_node("StartLabel").hide()			
			$HUD.get_node("ScoreLabel").show()
			$HUD.get_node("LifeLabel").show()
			$HUD.get_node("LifeLabel").text = "LIVES: " + str(life)
			$HUD.get_node("PlayButton").hide()
			$HUD.get_node("Homepage-Title").hide()
			$HUD.get_node("HomepageBackground").hide()
			BgMusic.play_bird()
   		 

func set_required_progress(amount: int):
	run_required = amount
	run_progress = 0  # reset progress

	# Update the UI
	var pb = get_tree().get_first_node_in_group("progress_bar")
	if pb:
		pb.max_value = run_required
		pb.value = run_progress
		
func update_bar(amount: float = 10):
	var pb = get_tree().get_first_node_in_group("progress_bar")
	BgMusic.play_splat()
	
	pb.value += amount_per_orb
		
	if pb.value >= pb.max_value:
		$HUD.get_node("Collect_Button").show()
		$HUD.get_node("Continue_Button").show()
		can_change_scenery = true
		print("Can change")
		BgMusic.paint_completed()


#Generate Objects
func generate_objects():
	# Randomly choose to spawn either a platform or obstacle
	if randi() % 2 == 0:
		generate_obs()
	else:
		generate_platforms()
		
#obstacle generator
func generate_obs():
	if obstacles.is_empty() or last_object_x <= score + randi_range(300, 500):
		var obs_type = SceneManager.get_random_obstacles(current_scenery)
		var obs
		var max_obs = difficulty + 1
		for i in range(randi() % max_obs + 1):
			obs = obs_type.instantiate()
			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
			var obs_x : int = screen_size.x + score + 100 + (i * 100)
			var obs_y : int = screen_size.y - ground_height - (obs_height * obs_scale.y)
			last_object_x = obs_x
			add_obj(obs, obs_x, obs_y)
		
		#generate bird
		if difficulty == MAX_DIFFICULTY:
			if(randi() % 2 == 0):
				var bird_scene = SceneManager.get_bird(current_scenery)
				obs = bird_scene.instantiate()
				BgMusic.play_bird()
				var obs_x : int = screen_size.x + score + 100
				var obs_y : int = bird_heights[randi() % bird_heights.size()]
				add_obj(obs, obs_x, obs_y)

#platform generator
func generate_platforms():
	# Only generate if there are no platforms or last platform is far enough
	if platforms == null:
		platforms = []
	
	if platforms.is_empty() or last_platform_x <= score + randi_range(300, 500):
		var platform = SceneManager.get_random_platform(current_scenery)
		var plat_x : int = screen_size.x + score + 100 + (100)
		var plat_y = randi_range(MIN_Y, MAX_Y)
		last_platform_x = plat_x
		add_obj(platform, plat_x, plat_y)
		
		if randi() % 2 == 0:
			generate_color_orbs(plat_x, plat_y - 40) 

func generate_color_orbs(pos_x, pos_y):
	var color = SceneManager.get_random_color(current_scenery)
	var shape_instance = SceneManager.generate_circle(color)
	#var shape_instance = shape.instantiate()
	
	shape_instance.position = Vector2(pos_x, pos_y)
	shape_instance.orb_color = color
	add_child(shape_instance)
	
	#var front = shape_instance.get_node("front")
	#var back = shape_instance.get_node("back")
	
	#if front:
	#	front.modulate = color # solid color
	#if back:
	#	back.modulate = color.lightened(0.5) # lighter version

func add_obj(obj: Node2D, x: float, y: float):
	obj.position = Vector2(x, y)
	add_child(obj)
	if obj.name.to_lower().find("platform") != -1:
		platforms.append(obj)
		last_platform_x = x
	else:
		obstacles.append(obj)
		last_object_x = x

func remove_obj(obj: Node2D):
	obj.queue_free()
	if platforms.has(obj):
		platforms.erase(obj)
	if obstacles.has(obj):
		obstacles.erase(obj)

func load_background(scenery: String):
	# remove old background if exists
	if $Bg.get_child_count() > 0:
		for c in $Bg.get_children():
			c.queue_free()

	current_scenery = SceneManager.get_random_scenery()
	
	# load new parallax
	var bg_scene = SceneManager.get_background(current_scenery)
	var bg_instance = bg_scene.instantiate()

	$Bg.add_child(bg_instance)
	
	var bg_parallax = bg_instance as BgParallax
	if bg_parallax:
		bg_parallax.setup(scenery)
		
func show_score():
	$HUD.get_node("ScoreLabel").text = "SCORE: " + str(score/SCORE_MODIFIER)
	
func adjust_difficulty():
	difficulty = score / SPEED_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY

func change_scenery():
	$HUD.get_node("Collect_Button").hide()
	$HUD.get_node("Continue_Button").hide()
	can_change_scenery = false
	$HUD/ProgressBar.value = 0  # reset bar
	
	current_scenery = SceneManager.get_random_scenery()
	load_background(current_scenery)

	print("Loaded new scenery:", current_scenery)
	
func set_layers(count: int):
	layers_total = count
	amount_per_orb = 100.0 / layers_total
	
	var pb = get_tree().get_first_node_in_group("progress_bar")
	pb.min_value = 0
	pb.max_value = 100
	pb.value = 0
	
func update_life():
	life -= 1
	$HUD.get_node("LifeLabel").text = "Lives: " + str(life)
	if(life <= 0):
		game_over()


func _on_lose_timer_timeout():
	game_running = false
	game_over()
	
func game_over():
	retry_button.show()
	get_tree().paused = true
	BgMusic.play_game_over()
	$GameOver.show()


func game_win():
	$Win.show()
	BgMusic.play_win_over()
	get_tree().paused = true

func show_captured_bg():
	if not bg_captured or captured_bg_image == null:
		return
	
	# Pause the game
	game_running = false
	
	get_tree().paused = true
	
	# Create a TextureRect to show the captured image
	if capture_display == null:
		capture_display = TextureRect.new()
		capture_display.anchor_left = 0
		capture_display.anchor_top = 0
		capture_display.anchor_right = 1
		capture_display.anchor_bottom = 1
		capture_display.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(capture_display)
	
	# Convert Image to ImageTexture
	var tex = ImageTexture.new()
	tex.create_from_image(captured_bg_image)
	capture_display.texture = tex
	
	# Create a label
	if capture_label == null:
		capture_label = Label.new()
		capture_label.text = "Captured Picture"
		capture_label.anchor_left = 0.5
		capture_label.anchor_top = 0
		capture_label.anchor_right = 0.5
		capture_label.anchor_bottom = 0
		capture_label.position = Vector2(screen_size.x / 2, 20)
		capture_label.add_theme_font_size_override("font_size", 36)
		add_child(capture_label)
	
	print("Captured background displayed")

func fade_in_out_game_start():
	var fade_rect = $FadeRect
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0  # start fully black
	
	# Fade out to reveal start menu
	for i in range(20):
		fade_rect.modulate.a = 1.0 - i * 0.05
		await get_tree().process_frame
	fade_rect.modulate.a = 0.0
	
	# Wait for player input
	while not Input.is_action_just_pressed("ui_accept"):
		await get_tree().process_frame
	
	# Fade to black before starting game
	for i in range(20):
		fade_rect.modulate.a = i * 0.05
		await get_tree().process_frame
	fade_rect.modulate.a = 1.0
	
	# Hide HUD start elements and start game
	$HUD.get_node("StartLabel").hide()
	$HUD.get_node("PlayButton").hide()
	$HUD.get_node("Homepage-Title").hide()
	$HUD.get_node("HomepageBackground").hide()
	game_running = true
	
	# Fade back to reveal game
	for i in range(20):
		fade_rect.modulate.a = 1.0 - i * 0.05
		await get_tree().process_frame
	fade_rect.modulate.a = 0.0

func restart_game():
	retry_button.hide()
	BgMusic.stop_music() 
	get_tree().paused = false
	get_tree().reload_current_scene()

func toggle_music_on():
	print("Toggling music ON")
	sound_on_button.hide()
	sound_off_button.show()
	BgMusic.play_music()

func toggle_music_off():
	sound_on_button.show()
	sound_off_button.hide()
	BgMusic.stop_music()
