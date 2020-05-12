extends RigidBody2D

func _ready():
	pass

func _integrate_forces(state):
	self.angular_velocity = 0.0
