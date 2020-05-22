extends RigidBody2D

export var disable_collision = false

var player = null

const DAMAGE = 2

func _ready():
	reset()

func reset():
	$CollisionShape2D.disabled = disable_collision
	$Area2D.monitoring = !disable_collision
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
