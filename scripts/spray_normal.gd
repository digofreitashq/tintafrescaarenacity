
extends Area2D

# Member variables
var taken = false
var player_class = preload("res://scripts/player.gd")

func _on_body_enter( body ):
	if (not taken and body is player_class):
		global.get_player().update_sprays(-1)
		$anim.play("taken")
		$sound.play(0)
		global.get_player().update_bullets(1)
		taken = true

func _ready():
	global.get_player().update_sprays(1)
