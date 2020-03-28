extends Area2D

# Member variables
var activated = false

func _on_body_enter( body ):
	if (not activated and global.is_bullet(body)):
		global.get_player().update_sprays(-1)
		$anim.play("taken")
		$sound.play(0)
		global.get_player().update_bullets(1)
		activated = true

func _ready():
	global.get_player().update_sprays(1)
