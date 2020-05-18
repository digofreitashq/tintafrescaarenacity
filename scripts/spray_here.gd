extends Area2D

export var ID = 0
export (int, 1, 4) var initial_force = 1

var force = 0

func _ready():
	reset()

func reset():
	force = initial_force
	$sprite.texture = load("res://sprites/spray_here_%s.png" % force)
	$anim.play("idle")

func _on_body_enter( body ):
	if (force >= 1 and global.is_bullet(body)):
		force -= 1
		
		$anim.play("spin")
		
		if force == 0:
			global.update_graffiti(1)
			global.show_graffiti(ID)
			global.pause_bgm()
			$anim.play("hide")
			$sound.stream = global.sound_success
			$sound.play(0)
		else:
			$sound.stream = global.sound_coin
			$sound.play(0)
			$timer_spin.start()

func _on_sound_finished():
	if force == 0:
		global.play_bgm()
		queue_free()

func _on_timer_spin_timeout():
	$sprite.texture = load("res://sprites/spray_here_%s.png" % force)
	$sprite.update()
	$anim.play("idle")
