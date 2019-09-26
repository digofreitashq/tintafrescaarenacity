extends "res://scripts/StateMachine.gd"

func _ready():
	add_state("none")
	add_state("shoot")
	call_deferred("set_state", states.none)

func _input(event):
	if event.is_action_pressed("shoot"):
		parent.shoot()
		set_state(states.shoot)

func _enter_state(new_state, old_state):
	pass


func _on_timer_shoot_timeout():
	set_state(states.none)
	parent.update_state_label()

