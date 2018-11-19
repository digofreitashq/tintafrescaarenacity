extends Node

var timer_start = null
var pressed_start = false

func _ready():
	start_game() # PULA
	get_node("anim").play("disclaimer")

func disclaimer_end():
	get_node("music").play(0)
	timer_start = get_node("timer_start")
	timer_start.connect("timeout", self, "start")
	timer_start.start()

func start():
	if (not pressed_start):
		var press_start = Input.is_action_pressed("shoot")
		
		if (press_start):
			pressed_start = true
			get_node("anim").play("fadeout")
			get_node("sound").play("click")

func start_game():
	get_tree().change_scene("res://scenes/stage.tscn")
