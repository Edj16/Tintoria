extends CharacterBody2D

const GRAVITY : float = 4200
const JUMP_SPEED : float = -1200
const MOVE_SPEED : float = 200
const MAX_JUMPS : int = 1  

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
var jumps_left : int = MAX_JUMPS
var is_hurt : bool = false

var hit_timer : float = 0.3  # 0.3 seconds
var hit_elapsed : float = 0.0

func _physics_process(delta):
	# Apply gravity
	velocity.y += GRAVITY * delta

	# Horizontal movement
	var input_dir : float = 0
	if Input.is_action_pressed("ui_right"):
		input_dir += 1
		anim.flip_h = false
	if Input.is_action_pressed("ui_left"):
		anim.flip_h = true
		input_dir -= 2

	velocity.x = input_dir * MOVE_SPEED

	# Jump
	if Input.is_action_just_pressed("ui_accept") and jumps_left > 0:
		BgMusic.play_jump()
		velocity.y = JUMP_SPEED
		jumps_left -= 1
		

	# Reset jumps when on floor
	if is_on_floor():
		jumps_left = MAX_JUMPS

	# Move the character
	move_and_slide()  # Godot 4 style

	# Animation logic
	if is_hurt:
		anim.play("hit")
		hit_elapsed = hit_timer
		is_hurt = false  # reset the flag
	elif hit_elapsed > 0:
		# Continue playing hit animation while timer > 0
		hit_elapsed -= delta
		
		anim.play("hit")
		
	else:
		# Normal animations
		if is_on_floor():
			if get_parent().game_running:
				anim.play("run")
			else:
					anim.play("idle")
		else:
				# Play jump animations
			if jumps_left == MAX_JUMPS - 1:
				anim.play("d_jump")  # first jump
				
			else:
				anim.play("jump")    # second jump
				
				
	
func hurt():
	is_hurt = true
	BgMusic.play_hit()
	print("play hurt")
