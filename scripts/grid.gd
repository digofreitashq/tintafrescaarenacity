extends RigidBody2D

export var opened = true

signal finished

func _ready():
	reset()

func reset():
	if opened:
		$sprite.frame = 0
		$collision.disabled = true
	else:
		$sprite.frame = 3
		$collision.disabled = false
		
func open():
	$anim.play("open")
	yield($anim, "animation_finished")
	emit_signal("finished")

func close():
	$anim.play("close")
	yield($anim, "animation_finished")
	emit_signal("finished")
	
func shake_camera():
	global.shake_camera()
