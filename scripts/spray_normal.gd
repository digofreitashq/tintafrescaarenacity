
extends Area2D

# Member variables
var taken = false
var player_class = preload("res://scripts/player.gd")

func _ready():
	reset()

func reset():
	global.update_sprays(1)

func _on_body_enter( body ):
	if (not taken and body is player_class):
		global.update_sprays(-1)
		$anim.play("taken")
		$sound.play(0)
		global.update_bullets(1)
		yield($anim, "animation_finished")
		taken = true
		queue_free()
