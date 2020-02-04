extends "res://scripts/StateMachine.gd"

func _ready():
	add_state("none")
	add_state("shoot")
	call_deferred("set_state", states.none)

func _enter_state(new_state, old_state):
	if new_state != states.shoot: return
	
	match parent.player_sm.state:
		parent.player_sm.states.idle:
			parent.play_anim("idle_weapon")
		parent.player_sm.states.run:
			parent.play_anim("run_weapon")
		parent.player_sm.states.jump:
			parent.play_anim("jump_weapon")
		parent.player_sm.states.fall:
			parent.play_anim("fall_weapon")
		parent.player_sm.states.wall_slide:
			parent.play_anim("wall_slide_weapon")
		parent.player_sm.states.wall_jump:
			parent.play_anim("fall_weapon")

func _on_timer_shoot_timeout():
	set_state(states.none)
	parent.update_state_label()
