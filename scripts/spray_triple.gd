
extends Area2D

# Member variables
var taken = false
var player_class = preload("res://scripts/player.gd")

func _on_body_enter( body ):
	if (not taken and body extends player_class):
		get_node("anim").play("taken")
		get_tree().get_current_scene().get_node("player").update_bullets(1)
		taken = true
		
		if (global.bullet_type != global.BULLET_TRIPLE):
			get_tree().get_current_scene().get_node("player").update_bullet_type(global.BULLET_TRIPLE)
			

func _on_spray_area_enter(area):
	pass # replace with function body


func _on_spray_area_enter_shape(area_id, area, area_shape, area_shape):
	pass # replace with function body
