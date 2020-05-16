extends RigidBody2D

var disabled = false

onready var sprite = $sprite
onready var collision = $Area2D/collision_check
onready var timer_wait = $timer_wait
onready var timer_disable = $timer_disable

func _ready():
	reset()

func reset():
	sprite.visible = true
	timer_disable.start()
	
	if (global.bullet_type == global.BULLET_NORMAL):
		$anim.play("normal")
	elif (global.bullet_type == global.BULLET_TRIPLE):
		$anim.play("triple")

func disable():
	if (disabled):
		return
	disabled = true
	sprite.visible = false
	queue_free()

func _on_bullet_body_entered(body):
	if not global.is_bullet(body):
		disable()
