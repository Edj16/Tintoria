extends Node

@export var mute : bool = false

func _ready():
	if not mute:
		play_music()

func play_music():
	if not mute:
		$Music.play()
		
func play_jump():
	if not mute:
		$Jump.play()

func play_game_over():
	if not mute:
		$GameOver.play()

func play_win_over():
	if not mute:
		$Win.play()

func play_bird():
	if not mute:
		$bird.play()
		
func play_hit():
	if not mute:
		$hit.play()
				
func play_splat():
	if not mute:
		$splat.play()

func paint_completed():
	if not mute:
		$paint_created.play()

func stop_music():
	$Music.stop()
