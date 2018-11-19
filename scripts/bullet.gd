
extends RigidBody2D

# Member variables
var disabled = false

func disable():
	if (disabled):
		return
	disabled = true
	get_node("anim").play("shutdown")

func _integrate_forces(s):
	var p = get_global_pos()
	var distance = p.distance_to(get_tree().get_current_scene().get_node("player").get_global_pos())
	
	if (distance > 500):
		disable()
	
	else:
		for body in get_node("collision_check").get_overlapping_bodies():
			if (not "bullet" in body.get_name()):
				disable()

func _ready():
	get_node("Timer").start()
	
	if (global.bullet_type == global.BULLET_NORMAL):
		get_node("anim").play("normal")
	elif (global.bullet_type == global.BULLET_TRIPLE):
		get_node("anim").play("triple")