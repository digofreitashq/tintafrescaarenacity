extends RigidBody2D

func _physics_process(delta):
	rotation_degrees = 0
	if linear_velocity.y < 0: linear_velocity.y = 0
