extends "res://scripts/StateMachine.gd"

func _ready():
	add_state("idle")
	add_state("over_box")
	add_state("floating")
	call_deferred("set_state", states.idle)

func _state_logic(delta):
	parent._apply_gravity(delta)
	parent._apply_movement(delta)
	
func _get_transition(delta):
	return null

func _enter_state(new_state, old_state):
	match state:
		states.floating:
			parent.anim.play("floating")
		states.idle:
			parent.anim.play("idle")
		states.over_box:
			parent.anim.play("idle")
		
