extends Node

var timer_start = null
var pressed_start = false

var sound_click = preload("res://sfx/sound_click.wav")
var sound_beep = preload("res://sfx/sound_beep.wav")

func _ready():
	#start_game() # PULA
	$music.play(0)
	$anim.play("disclaimer")

func anim_start():
	$anim_start.play("updown")

func disclaimer_end():
	timer_start = $timer_start
	timer_start.connect("timeout", self, "start")
	timer_start.start()

func start():
	if (not pressed_start):
		var press_start = Input.is_action_pressed("shoot")
		
		if (press_start):
			pressed_start = true
			$anim.play("fadeout")
			
			$sound.stream = sound_click
			$sound.play(0)

func start_game():
	get_tree().change_scene("res://scenes/stage.tscn")
