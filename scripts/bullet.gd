extends RigidBody2D

var disabled = false

func _ready():
	$Timer.start()
	
	if (global.bullet_type == global.BULLET_NORMAL):
		$anim.play("normal")
	elif (global.bullet_type == global.BULLET_TRIPLE):
		$anim.play("triple")


func _on_bullet_body_enter( body ):
	if body.has_method("hit_by_bullet"):
		body.call("hit_by_bullet")

func _on_Timer_timeout():
	disable()

func disable():
	if (disabled):
		return
	disabled = true
	get_node("anim").play("shutdown")