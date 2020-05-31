extends RigidBody2D

export var opened = true

func _ready():
	reset()

func reset():
	if opened:
		$sprite.frame = 0
		$collision.disabled = false
	else:
		$sprite.frame = 3
		$collision.disabled = true
		
func open():
	$anim.play("open")

func close():
	$anim.play("close")
	
func shake_camera():
	global.shake_camera()
