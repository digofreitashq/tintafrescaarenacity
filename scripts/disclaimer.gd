extends Node2D

func _ready():
	if global.finished:
		$label1.visible = false
		$label2.visible = true
	else:
		$label1.visible = true
		$label2.visible = false
		
func _process(delta):
	if Input.is_action_pressed("shoot"):
		get_tree().change_scene("res://scenes/title.tscn")
		global.show_player_ui(false)

