extends Area2D

export var ID = 0
export var force = 0

onready var sound_shake = preload("res://sfx/sound_shake.wav")
onready var sound_success = preload("res://sfx/sound_success.wav")

func _ready():
	$particles.emitting = false

func _on_body_enter( body ):
	if (force >= 1 and global.is_bullet(body)):
		force -= 1
		
		if force == 0:
			$anim.play("activated")
			global.get_player().update_grafitti(1)
			global.show_grafitti(ID)
			global.pause_bgm()
			$sound.stream = sound_success
			$sound.play(0)
		else:
			$sound.stream = sound_shake
			$sound.play(0)

func _on_sound_finished():
	global.play_bgm()
	queue_free()
