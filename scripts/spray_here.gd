extends Area2D

export var ID = 0
export var force = 0

func _ready():
	reset()

func reset():
	$particles.emitting = false

func _on_body_enter( body ):
	if (force >= 1 and global.is_bullet(body)):
		force -= 1
		
		if force == 0:
			$anim.play("activated")
			global.update_graffiti(1)
			global.show_graffiti(ID)
			global.pause_bgm()
			$sound.stream = global.sound_success
			$sound.play(0)
		else:
			$sound.stream = global.sound_shake
			$sound.play(0)

func _on_sound_finished():
	global.play_bgm()
	queue_free()
