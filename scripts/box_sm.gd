extends "res://scripts/StateMachine.gd"

func _ready():
	add_state("idle")
	add_state("floating")
	call_deferred("set_state", states.idle)

func _state_logic(delta):
	parent._apply_gravity(delta)
	parent._apply_movement(delta)
	
func _get_transition(delta):
	return null

func _enter_state(new_state, old_state):
	pass