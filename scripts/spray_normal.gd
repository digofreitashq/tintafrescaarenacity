
extends Area2D

# Member variables
var taken = false
var player_class = preload("res://scripts/player.gd")

func _on_body_enter( body ):
	if (not taken and body is player_class):
		get_tree().get_current_scene().get_node("player").update_sprays(-1)
		get_node("anim").play("taken")
		get_node("sound").play(0)
		get_tree().get_current_scene().get_node("player").update_bullets(1)
		taken = true


func _on_spray_area_enter(area):
	pass # replace with function body


func _on_spray_area_enter_shape(area_id, area, area_shape, area_shape):
	pass # replace with function body


func _ready():
	get_tree().get_current_scene().get_node("player").update_sprays(1)
