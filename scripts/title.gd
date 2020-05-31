extends Node

var timer_start = null
var pressed_start = false

func _ready():
	reset()

func reset():
	start_game() # PULA
	global.show_player_ui(false)
	$music.play(0)
	$anim.play("disclaimer")

func disclaimer_end():
	timer_start = $timer_start
	timer_start.connect("timeout", self, "start")
	timer_start.start()

func start():
	if (not pressed_start):
		var press_start = Input.is_action_pressed("shoot")
		
		if (press_start):
			pressed_start = true
			
			$disclaimer.visible = false
			
			$sound.stream = global.sound_graffiti
			$sound.play()

func start_game():
	get_tree().change_scene("res://scenes/stage.tscn")
	global.show_player_ui(true)

func _on_sound_finished():
	if pressed_start:
		$anim.play("fadeout")
		yield($anim, "animation_finished")
		start_game()
