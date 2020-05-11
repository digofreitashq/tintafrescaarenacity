extends RigidBody2D

var player = null

const DAMAGE = 2

func _ready():
	reset()

func reset():
	$anim.play("loop")

func _on_Area2D_body_entered(body):
	if global.is_player(body):
		player = body
		player.got_damage(DAMAGE,true)
		$timer.start()

func _on_Area2D_body_exited(body):
	if global.is_player(body):
		player = body
		$timer.stop()

func check_player():
	if player in $Area2D.get_overlapping_bodies():
		player.got_damage(DAMAGE,true)
	else:
		$timer.stop()
