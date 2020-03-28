extends RigidBody2D

var disabled = false

onready var sprite = $sprite
onready var particles = $particles
onready var collision = $Area2D/collision_check
onready var timer_wait = $timer_wait

func _ready():
	sprite.visible = true
	particles.emitting = true
	$timer_disable.start()
	
	if (global.bullet_type == global.BULLET_NORMAL):
		$anim.play("normal")
	elif (global.bullet_type == global.BULLET_TRIPLE):
		$anim.play("triple")

func disable():
	if (disabled):
		return
	disabled = true
	sprite.visible = false
	particles.emitting = false
	queue_free()

func _on_bullet_body_entered(body):
	if not global.is_bullet(body):
		disable()
