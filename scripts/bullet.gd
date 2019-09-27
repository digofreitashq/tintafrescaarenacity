extends RigidBody2D

const FLOOR_NORMAL = Vector2(0, -2)
const SLOPE_SLIDE_STOP = 25.0

var disabled = false

onready var sprite = $sprite
onready var particles = $particles
onready var collision = $Area2D/collision_check

func _ready():
	sprite.visible = true
	particles.emitting = true
	$Timer.start()
	
	if (global.bullet_type == global.BULLET_NORMAL):
		$anim.play("normal")
	elif (global.bullet_type == global.BULLET_TRIPLE):
		$anim.play("triple")

func _on_Timer_timeout():
	disable()

func disable():
	if (disabled):
		return
	disabled = true
	sprite.visible = false
	particles.emitting = false
	queue_free()

func _on_bullet_body_entered(body):
	if (not "bullet" in body.get_name()):
		disable()
