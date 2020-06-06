extends RigidBody2D

var disabled = false

onready var sprite = $sprite
onready var collision = $Area2D/collision_check

func _ready():
	reset()

func reset():
	sprite.visible = true
	$anim.play("normal")

func disable():
	if (disabled):
		return
	disabled = true
	sprite.visible = false
	queue_free()

func _on_bullet_body_entered(body):
	if not global.is_bullet(body):
		disable()
