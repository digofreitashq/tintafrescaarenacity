extends Node

var timer_start = null
var shoot = null

func _ready():
	reset()

func reset():
	#start_game() # PULA
	$bg.visible = false
	$disclaimer.visible = false
	global.show_player_ui(false)
	$music.play(0)
	$anim.play("disclaimer")

func disclaimer_end():
	$timer_start.start()

func start_game():
	$disclaimer.visible = false
	$sound.stream = global.sound_graffiti
	$sound.play()
	yield($sound, "finished")
	$anim.play("fadeout")
	yield($anim, "animation_finished")
	start_game()
	get_tree().change_scene("res://scenes/stage.tscn")
	global.show_player_ui(true)

func _on_timer_start_timeout():
	if not shoot:
		shoot = Input.is_action_pressed("shoot")
		
		if shoot:
			$timer_start.stop()
			start_game()
