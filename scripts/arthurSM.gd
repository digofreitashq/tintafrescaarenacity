extends "res://scripts/StateMachine.gd"

func _ready():
	add_state("idle")
	add_state("run")
	add_state("fall")
	add_state("eating")
	call_deferred("set_state", states.idle)

func _state_logic(delta):
	parent.onair_time += delta
	
	parent._handle_move_input()
	parent._apply_gravity(delta)
	parent._apply_movement(delta)
	
func _get_transition(delta):
	match state:
		states.idle:
			if not parent.on_floor:
				if round(parent.linear_vel.y) > 0:
					return states.fall
			elif round(parent.linear_vel.x) != 0:
				return states.run
		
		states.run:
			if not parent.on_floor:
				if round(parent.linear_vel.y) > 0:
					return states.fall
			elif round(parent.linear_vel.x) == 0:
				return states.idle
		
		states.fall:
			if parent.is_on_floor():
				return states.idle
		
		states.eating:
			if not parent.on_floor:
				if round(parent.linear_vel.y) > 0:
					return states.fall
			elif round(parent.linear_vel.x) != 0:
				return states.run
	
	return null

func _enter_state(new_state, old_state):
	match new_state:
		states.idle:
			parent.play_anim("idle")
		states.run:
			parent.play_anim("walk")
		states.fall:
			parent.play_anim("fall")
		states.eating:
			parent.play_anim("eating")
