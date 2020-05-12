extends "res://scripts/StateMachine.gd"

func _ready():
	add_state("idle")
	add_state("floating")
	call_deferred("set_state", states.idle)
	
func _get_transition(delta):
	return null

func _enter_state(new_state, old_state):
	match state:
		states.floating:
			parent.anim.play("floating")
			parent.play_sound(global.sound_splash, true)
		states.idle:
			parent.anim.play("idle")
